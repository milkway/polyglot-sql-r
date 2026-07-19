//! FFI layer between R and the `polyglot-sql` crate.
//!
//! Every exported function returns a JSON "envelope" string:
//!
//! * `{"ok": true,  "value": <payload>}` on success;
//! * `{"ok": false, "error": {"kind": ..., "message": ..., ...}}` on failure.
//!
//! The R side (`R/ffi.R`) parses the envelope with jsonlite and raises classed
//! R conditions for errors. Upstream errors are always converted into `Err`
//! values here — they never panic — and if a panic did occur (e.g. a bug in a
//! dependency), extendr catches it at the FFI boundary and converts it into a
//! regular R error, so the R session is never terminated.

use extendr_api::prelude::*;
use polyglot_sql as pg;
use polyglot_sql::validation::{SchemaValidationOptions, ValidationSchema};
use serde_json::{json, Value};

// ---------------------------------------------------------------------------
// Envelope helpers
// ---------------------------------------------------------------------------

fn envelope_ok(value: Value) -> String {
    json!({ "ok": true, "value": value }).to_string()
}

fn envelope_err(error: Value) -> String {
    json!({ "ok": false, "error": error }).to_string()
}

/// Convert an upstream error into a structured JSON error object.
fn error_value(e: &pg::Error) -> Value {
    match e {
        pg::Error::Tokenize {
            message,
            line,
            column,
            start,
            end,
        } => location_error("tokenize", message, *line, *column, *start, *end),
        pg::Error::Parse {
            message,
            line,
            column,
            start,
            end,
        } => location_error("parse", message, *line, *column, *start, *end),
        pg::Error::Syntax {
            message,
            line,
            column,
            start,
            end,
        } => location_error("syntax", message, *line, *column, *start, *end),
        pg::Error::Generate(message) => {
            let kind = if message.starts_with("E_GUARD") {
                "guard"
            } else {
                "generate"
            };
            json!({ "kind": kind, "message": message })
        }
        pg::Error::Unsupported { feature, dialect } => json!({
            "kind": "unsupported",
            "message": format!("{feature} is not supported in {dialect}"),
            "feature": feature,
            "dialect": dialect,
        }),
        pg::Error::Internal(message) => json!({ "kind": "internal", "message": message }),
    }
}

fn location_error(
    kind: &str,
    message: &str,
    line: usize,
    column: usize,
    start: usize,
    end: usize,
) -> Value {
    json!({
        "kind": kind,
        "message": message,
        "line": line,
        "column": column,
        "start": start,
        "end": end,
    })
}

fn simple_err(kind: &str, message: impl Into<String>) -> String {
    envelope_err(json!({ "kind": kind, "message": message.into() }))
}

// ---------------------------------------------------------------------------
// Argument helpers
// ---------------------------------------------------------------------------

fn resolve_dialect(name: &str) -> std::result::Result<pg::DialectType, String> {
    name.parse::<pg::DialectType>()
        .map_err(|_| format!("Unknown SQL dialect: '{name}'"))
}

/// Parse the optional schema JSON produced by the R side.
/// An empty string means "no schema".
fn parse_schema(schema_json: &str) -> std::result::Result<Option<ValidationSchema>, String> {
    if schema_json.is_empty() {
        return Ok(None);
    }
    serde_json::from_str::<ValidationSchema>(schema_json)
        .map(Some)
        .map_err(|e| format!("Invalid schema specification: {e}"))
}

/// Decode a guard limit passed from R: -1 => upstream default, 0 => disabled
/// (no limit), positive => that limit.
fn guard_limit(raw: f64, default: Option<usize>) -> Option<usize> {
    if raw < 0.0 {
        default
    } else if raw == 0.0 {
        None
    } else {
        Some(raw as usize)
    }
}

// ---------------------------------------------------------------------------
// Metadata
// ---------------------------------------------------------------------------

/// Version of the linked polyglot-sql crate (extracted from Cargo.lock at
/// build time; see build.rs).
/// @noRd
#[extendr]
fn ffi_version() -> String {
    envelope_ok(json!({
        "polyglot_sql": env!("POLYGLOT_SQL_VERSION"),
    }))
}

/// All built-in dialects: canonical name, accepted aliases, description.
/// The canonical names match `DialectType`'s `Display` implementation and the
/// aliases match its `FromStr` implementation; `ffi_dialects_selfcheck` in the
/// test suite asserts both stay in sync with upstream.
const DIALECTS: &[(&str, &[&str], &str)] = &[
    (
        "generic",
        &[],
        "Standard SQL with no dialect-specific behavior",
    ),
    ("postgresql", &["postgres"], "PostgreSQL"),
    ("mysql", &[], "MySQL"),
    ("bigquery", &[], "Google BigQuery"),
    ("snowflake", &[], "Snowflake"),
    ("duckdb", &[], "DuckDB"),
    ("sqlite", &[], "SQLite"),
    ("hive", &[], "Apache Hive"),
    ("spark", &["spark2"], "Apache Spark SQL"),
    ("trino", &[], "Trino (formerly PrestoSQL)"),
    ("presto", &[], "PrestoDB"),
    ("redshift", &[], "Amazon Redshift"),
    (
        "tsql",
        &["mssql", "sqlserver"],
        "Transact-SQL (Microsoft SQL Server, Azure SQL)",
    ),
    ("oracle", &[], "Oracle Database"),
    ("clickhouse", &[], "ClickHouse"),
    ("databricks", &[], "Databricks SQL"),
    ("athena", &[], "Amazon Athena"),
    ("teradata", &[], "Teradata"),
    ("doris", &[], "Apache Doris"),
    ("starrocks", &[], "StarRocks"),
    ("materialize", &[], "Materialize"),
    ("risingwave", &[], "RisingWave"),
    ("singlestore", &["memsql"], "SingleStore (formerly MemSQL)"),
    ("cockroachdb", &["cockroach"], "CockroachDB"),
    ("tidb", &[], "TiDB"),
    ("druid", &[], "Apache Druid"),
    ("solr", &[], "Apache Solr SQL"),
    ("tableau", &[], "Tableau"),
    ("dune", &[], "Dune Analytics"),
    ("fabric", &[], "Microsoft Fabric"),
    ("drill", &[], "Apache Drill"),
    ("dremio", &[], "Dremio"),
    ("exasol", &[], "Exasol"),
    (
        "datafusion",
        &["arrow-datafusion", "arrow_datafusion"],
        "Apache DataFusion",
    ),
];

/// List built-in dialect names, aliases and descriptions.
/// @noRd
#[extendr]
fn ffi_dialects() -> String {
    let dialects: Vec<Value> = DIALECTS
        .iter()
        .map(|(name, aliases, description)| {
            json!({ "name": name, "aliases": aliases, "description": description })
        })
        .collect();
    envelope_ok(Value::Array(dialects))
}

/// Assert the static DIALECTS table matches upstream name resolution.
/// Returns problems as a JSON array (empty when in sync). Used by tests.
/// @noRd
#[extendr]
fn ffi_dialects_selfcheck() -> String {
    let mut problems: Vec<String> = Vec::new();
    for (name, aliases, _) in DIALECTS {
        match name.parse::<pg::DialectType>() {
            Ok(dt) => {
                if dt.to_string() != *name {
                    problems.push(format!(
                        "'{name}' is not canonical (upstream canonical name: '{dt}')"
                    ));
                }
            }
            Err(_) => problems.push(format!("'{name}' is not accepted by upstream")),
        }
        for alias in *aliases {
            if alias.parse::<pg::DialectType>().is_err() {
                problems.push(format!("alias '{alias}' of '{name}' is not accepted"));
            }
        }
    }
    envelope_ok(json!(problems))
}

// ---------------------------------------------------------------------------
// Transpile / format / generate
// ---------------------------------------------------------------------------

/// Transpile SQL between dialects.
/// @noRd
#[extendr]
fn ffi_transpile(sql: &str, from: &str, to: &str, pretty: bool, unsupported: &str) -> String {
    let (read, write) = match (resolve_dialect(from), resolve_dialect(to)) {
        (Ok(r), Ok(w)) => (r, w),
        (Err(m), _) | (_, Err(m)) => return simple_err("unknown_dialect", m),
    };

    let unsupported_level = match unsupported {
        "raise" => pg::UnsupportedLevel::Raise,
        "warn" => pg::UnsupportedLevel::Warn,
        "ignore" => pg::UnsupportedLevel::Ignore,
        other => {
            return simple_err(
                "bad_argument",
                format!("Invalid 'unsupported' value: '{other}'"),
            )
        }
    };

    // TranspileOptions is #[non_exhaustive]; build via Default and assign.
    let mut options = pg::TranspileOptions::default();
    options.pretty = pretty;
    options.unsupported_level = unsupported_level;

    match pg::transpile_with_by_name(sql, &read.to_string(), &write.to_string(), &options) {
        Ok(statements) => envelope_ok(json!(statements)),
        Err(e) => envelope_err(error_value(&e)),
    }
}

/// Pretty-format SQL with configurable complexity guards.
/// @noRd
#[extendr]
fn ffi_format(
    sql: &str,
    dialect: &str,
    max_input_bytes: f64,
    max_tokens: f64,
    max_ast_nodes: f64,
    max_set_op_chain: f64,
) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let defaults = pg::FormatGuardOptions::default();
    let options = pg::FormatGuardOptions {
        max_input_bytes: guard_limit(max_input_bytes, defaults.max_input_bytes),
        max_tokens: guard_limit(max_tokens, defaults.max_tokens),
        max_ast_nodes: guard_limit(max_ast_nodes, defaults.max_ast_nodes),
        max_set_op_chain: guard_limit(max_set_op_chain, defaults.max_set_op_chain),
    };

    match pg::format_with_options(sql, dt, &options) {
        Ok(statements) => envelope_ok(json!(statements)),
        Err(e) => envelope_err(error_value(&e)),
    }
}

/// Generate SQL from an AST (JSON produced by `ffi_parse`).
/// @noRd
#[extendr]
fn ffi_generate(ast_json: &str, dialect: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let value: Value = match serde_json::from_str(ast_json) {
        Ok(v) => v,
        Err(e) => return simple_err("bad_argument", format!("Invalid AST JSON: {e}")),
    };
    let expressions = match pg::ast_json::expressions_from_value(value) {
        Ok(exprs) => exprs,
        Err(e) => return simple_err("bad_argument", format!("Invalid AST: {e}")),
    };

    let mut statements = Vec::with_capacity(expressions.len());
    for expr in &expressions {
        match pg::generate(expr, dt) {
            Ok(sql) => statements.push(sql),
            Err(e) => return envelope_err(error_value(&e)),
        }
    }
    envelope_ok(json!(statements))
}

// ---------------------------------------------------------------------------
// Parse / tokenize / validate
// ---------------------------------------------------------------------------

/// Parse SQL into an AST, serialized as JSON.
/// @noRd
#[extendr]
fn ffi_parse(sql: &str, dialect: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let expressions = match pg::parse(sql, dt) {
        Ok(exprs) => exprs,
        Err(e) => return envelope_err(error_value(&e)),
    };

    let mut values = Vec::with_capacity(expressions.len());
    for expr in &expressions {
        match pg::ast_json::expression_to_value(expr) {
            Ok(v) => values.push(v),
            Err(e) => return simple_err("internal", format!("AST serialization failed: {e}")),
        }
    }
    envelope_ok(Value::Array(values))
}

/// Tokenize SQL. Returns parallel arrays for cheap data.frame construction.
/// @noRd
#[extendr]
fn ffi_tokenize(sql: &str, dialect: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let tokens = match pg::Dialect::get(dt).tokenize(sql) {
        Ok(tokens) => tokens,
        Err(e) => return envelope_err(error_value(&e)),
    };

    let n = tokens.len();
    let mut types = Vec::with_capacity(n);
    let mut texts = Vec::with_capacity(n);
    let mut lines = Vec::with_capacity(n);
    let mut columns = Vec::with_capacity(n);
    let mut starts = Vec::with_capacity(n);
    let mut ends = Vec::with_capacity(n);
    for token in &tokens {
        types.push(format!("{:?}", token.token_type));
        texts.push(token.text.clone());
        lines.push(token.span.line);
        columns.push(token.span.column);
        starts.push(token.span.start);
        ends.push(token.span.end);
    }

    envelope_ok(json!({
        "type": types,
        "text": texts,
        "line": lines,
        "column": columns,
        "start": starts,
        "end": ends,
    }))
}

/// Validate SQL syntax (optionally schema-aware).
/// @noRd
#[extendr]
fn ffi_validate(
    sql: &str,
    dialect: &str,
    strict_syntax: bool,
    semantic: bool,
    schema_json: &str,
) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };

    let result = match schema {
        Some(schema) => {
            let options = SchemaValidationOptions {
                check_types: true,
                check_references: true,
                strict: None,
                semantic,
                strict_syntax,
                ..Default::default()
            };
            pg::validation::validate_with_schema(sql, dt, &schema, &options)
        }
        None => {
            let options = pg::ValidationOptions {
                strict_syntax,
                semantic,
            };
            pg::validate_with_options(sql, dt, &options)
        }
    };

    match serde_json::to_value(&result) {
        Ok(v) => envelope_ok(v),
        Err(e) => simple_err("internal", format!("Serialization failed: {e}")),
    }
}

// ---------------------------------------------------------------------------
// Tables / lineage / analysis
// ---------------------------------------------------------------------------

/// Source (physical) tables referenced by the SQL, across all statements.
/// @noRd
#[extendr]
fn ffi_source_tables(sql: &str, dialect: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let expressions = match pg::parse(sql, dt) {
        Ok(exprs) => exprs,
        Err(e) => return envelope_err(error_value(&e)),
    };

    // Preserve first-appearance order while deduplicating.
    let mut seen = std::collections::HashSet::new();
    let mut tables = Vec::new();
    for expr in &expressions {
        for table in pg::get_table_names(expr) {
            if seen.insert(table.clone()) {
                tables.push(table);
            }
        }
    }
    envelope_ok(json!(tables))
}

/// Slim recursive projection of a lineage node for the R side.
fn lineage_node_value(node: &pg::lineage::LineageNode, dialect: pg::DialectType) -> Value {
    let expression_sql = pg::generate(&node.expression, dialect).unwrap_or_default();
    let downstream: Vec<Value> = node
        .downstream
        .iter()
        .map(|d| lineage_node_value(d, dialect))
        .collect();
    json!({
        "name": node.name,
        "source_name": node.source_name,
        "source_kind": format!("{:?}", node.source_kind),
        "expression": expression_sql,
        "downstream": downstream,
    })
}

/// Column-level lineage. `column == ""` means "all output columns".
/// @noRd
#[extendr]
fn ffi_lineage(sql: &str, dialect: &str, column: &str, schema_json: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };

    let expression = match pg::parse_one(sql, dt) {
        Ok(expr) => expr,
        Err(e) => return envelope_err(error_value(&e)),
    };

    let columns: Vec<String> = if column.is_empty() {
        pg::get_output_column_names(&expression)
    } else {
        vec![column.to_string()]
    };
    if columns.is_empty() {
        return simple_err(
            "bad_argument",
            "Could not determine output columns; pass an explicit 'column'",
        );
    }

    let mapping_schema = schema
        .as_ref()
        .map(pg::validation::mapping_schema_from_validation_schema);

    let mut nodes = Vec::with_capacity(columns.len());
    for col in &columns {
        let result = match mapping_schema.as_ref() {
            Some(ms) => {
                pg::lineage::lineage_with_schema(col, &expression, Some(ms), Some(dt), false)
            }
            None => pg::lineage::lineage(col, &expression, Some(dt), false),
        };
        match result {
            Ok(node) => {
                let mut sources: Vec<String> =
                    pg::lineage::get_source_tables(&node).into_iter().collect();
                sources.sort();
                nodes.push(json!({
                    "column": col,
                    "sources": sources,
                    "tree": lineage_node_value(&node, dt),
                }));
            }
            Err(e) => return envelope_err(error_value(&e)),
        }
    }
    envelope_ok(Value::Array(nodes))
}

/// Structured query analysis (shape, projections, relations, CTEs...).
/// @noRd
#[extendr]
fn ffi_analyze(sql: &str, dialect: &str, schema_json: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };

    let options = pg::AnalyzeQueryOptions {
        dialect: dt,
        schema,
    };
    match pg::analyze_query(sql, options) {
        Ok(analysis) => match serde_json::to_value(&analysis) {
            Ok(v) => envelope_ok(v),
            Err(e) => simple_err("internal", format!("Serialization failed: {e}")),
        },
        Err(e) => envelope_err(error_value(&e)),
    }
}

// ---------------------------------------------------------------------------
// Optimizer / types / diff / OpenLineage
// ---------------------------------------------------------------------------

/// Optimize SQL and return the rewritten statement(s).
/// @noRd
#[extendr]
fn ffi_optimize(sql: &str, dialect: &str, schema_json: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };
    let mapping_schema = schema
        .as_ref()
        .map(pg::validation::mapping_schema_from_validation_schema);

    let expressions = match pg::parse(sql, dt) {
        Ok(exprs) => exprs,
        Err(e) => return envelope_err(error_value(&e)),
    };

    let config = pg::optimizer::OptimizerConfig {
        schema: mapping_schema.as_ref().map(|ms| ms as &dyn pg::Schema),
        dialect: Some(dt),
        ..Default::default()
    };

    let mut statements = Vec::with_capacity(expressions.len());
    for expr in expressions {
        let optimized = pg::optimizer::optimize(expr, &config);
        match pg::generate(&optimized, dt) {
            Ok(sql) => statements.push(sql),
            Err(e) => return envelope_err(error_value(&e)),
        }
    }
    envelope_ok(json!(statements))
}

/// Annotate a query's AST with inferred data types.
/// @noRd
#[extendr]
fn ffi_annotate_types(sql: &str, dialect: &str, schema_json: &str) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };
    let mapping_schema = schema
        .as_ref()
        .map(pg::validation::mapping_schema_from_validation_schema);

    let mut expression = match pg::parse_one(sql, dt) {
        Ok(expr) => expr,
        Err(e) => return envelope_err(error_value(&e)),
    };

    pg::annotate_types(
        &mut expression,
        mapping_schema.as_ref().map(|ms| ms as &dyn pg::Schema),
        Some(dt),
    );

    let ast = match pg::ast_json::expression_to_value(&expression) {
        Ok(v) => v,
        Err(e) => return simple_err("internal", format!("AST serialization failed: {e}")),
    };

    // Also surface a compact per-projection type summary when the query is a
    // SELECT-like statement.
    let columns = pg::get_output_column_names(&expression);
    let types: Vec<Value> = columns.iter().map(|name| json!({ "name": name })).collect();

    envelope_ok(json!({ "ast": ast, "columns": types }))
}

/// Structural diff between two SQL statements.
/// @noRd
#[extendr]
fn ffi_diff(sql_from: &str, sql_to: &str, dialect: &str, delta_only: bool) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };

    let source = match pg::parse_one(sql_from, dt) {
        Ok(expr) => expr,
        Err(e) => return envelope_err(error_value(&e)),
    };
    let target = match pg::parse_one(sql_to, dt) {
        Ok(expr) => expr,
        Err(e) => return envelope_err(error_value(&e)),
    };

    let edits = pg::diff::diff(&source, &target, delta_only);
    let mut values = Vec::with_capacity(edits.len());
    for edit in &edits {
        // Render a compact, SQL-oriented view of each edit instead of the
        // full serialized AST nodes.
        let value = match edit {
            pg::diff::Edit::Insert { expression } => json!({
                "op": "insert",
                "expression": pg::generate(expression, dt).unwrap_or_default(),
            }),
            pg::diff::Edit::Remove { expression } => json!({
                "op": "remove",
                "expression": pg::generate(expression, dt).unwrap_or_default(),
            }),
            pg::diff::Edit::Move { source, .. } => json!({
                "op": "move",
                "expression": pg::generate(source, dt).unwrap_or_default(),
            }),
            pg::diff::Edit::Update { source, target } => json!({
                "op": "update",
                "expression": pg::generate(source, dt).unwrap_or_default(),
                "target": pg::generate(target, dt).unwrap_or_default(),
            }),
            pg::diff::Edit::Keep { source, .. } => json!({
                "op": "keep",
                "expression": pg::generate(source, dt).unwrap_or_default(),
            }),
        };
        values.push(value);
    }
    envelope_ok(Value::Array(values))
}

/// OpenLineage columnLineage facet for a SQL statement.
/// @noRd
#[extendr]
fn ffi_openlineage(
    sql: &str,
    dialect: &str,
    namespace: &str,
    job_name: &str,
    schema_json: &str,
) -> String {
    let dt = match resolve_dialect(dialect) {
        Ok(d) => d,
        Err(m) => return simple_err("unknown_dialect", m),
    };
    let schema = match parse_schema(schema_json) {
        Ok(s) => s,
        Err(m) => return simple_err("bad_argument", m),
    };

    let options = pg::openlineage::OpenLineageOptions {
        dialect: dt,
        producer: format!("polyglotSQL-R/{}", env!("CARGO_PKG_VERSION")),
        dataset_namespace: if namespace.is_empty() {
            None
        } else {
            Some(namespace.to_string())
        },
        dataset_mappings: Default::default(),
        output_dataset: None,
        schema,
        job_namespace: None,
        job_name: if job_name.is_empty() {
            None
        } else {
            Some(job_name.to_string())
        },
        event_time: None,
        run_id: None,
        event_type: None,
    };

    match pg::openlineage::openlineage_column_lineage(sql, &options) {
        Ok(result) => match serde_json::to_value(&result) {
            Ok(v) => envelope_ok(v),
            Err(e) => simple_err("internal", format!("Serialization failed: {e}")),
        },
        Err(e) => envelope_err(error_value(&e)),
    }
}

// Macro to generate exports.
// This ensures exported functions are registered with R.
// See corresponding C code in `entrypoint.c`.
extendr_module! {
    mod polyglotSQL;
    fn ffi_version;
    fn ffi_dialects;
    fn ffi_dialects_selfcheck;
    fn ffi_transpile;
    fn ffi_format;
    fn ffi_generate;
    fn ffi_parse;
    fn ffi_tokenize;
    fn ffi_validate;
    fn ffi_source_tables;
    fn ffi_lineage;
    fn ffi_analyze;
    fn ffi_optimize;
    fn ffi_annotate_types;
    fn ffi_diff;
    fn ffi_openlineage;
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn guard_limit_decodes_sentinels() {
        assert_eq!(guard_limit(-1.0, Some(42)), Some(42));
        assert_eq!(guard_limit(0.0, Some(42)), None);
        assert_eq!(guard_limit(10.0, Some(42)), Some(10));
    }

    #[test]
    fn dialect_table_matches_upstream() {
        for (name, aliases, _) in DIALECTS {
            let dt = name
                .parse::<pg::DialectType>()
                .unwrap_or_else(|_| panic!("{name} rejected by upstream"));
            assert_eq!(dt.to_string(), *name, "{name} is not canonical");
            for alias in *aliases {
                assert!(
                    alias.parse::<pg::DialectType>().is_ok(),
                    "alias {alias} rejected"
                );
            }
        }
    }

    #[test]
    fn error_values_carry_kind_and_location() {
        let err = pg::Error::parse("boom", 3, 7, 10, 14);
        let v = error_value(&err);
        assert_eq!(v["kind"], "parse");
        assert_eq!(v["line"], 3);
        assert_eq!(v["column"], 7);
    }

    #[test]
    fn schema_json_round_trips() {
        let schema =
            parse_schema(r#"{"tables":[{"name":"t","columns":[{"name":"id","type":"INT"}]}]}"#)
                .expect("valid schema")
                .expect("non-empty");
        assert_eq!(schema.tables.len(), 1);
        assert_eq!(schema.tables[0].columns[0].name, "id");
        assert!(parse_schema("").unwrap().is_none());
        assert!(parse_schema("{nonsense").is_err());
    }
}
