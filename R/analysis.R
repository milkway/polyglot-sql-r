# Table discovery, lineage, structural analysis, optimization, diff,
# type annotation and OpenLineage export.

#' List source tables referenced by SQL
#'
#' Returns the physical tables a query reads from, across all statements.
#' CTE names are not included (they are intermediate results, not sources).
#'
#' @inheritParams sql_parse
#' @return A character vector of table names, in order of first appearance.
#' @examples
#' sql_source_tables("SELECT * FROM a JOIN b ON a.id = b.id")
#' sql_source_tables("WITH x AS (SELECT 1 FROM t) SELECT * FROM x")
#' @export
sql_source_tables <- function(sql, dialect = "generic") {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(ffi_source_tables, sql, dialect, context = "parse", simplify = TRUE)
  as.character(value)
}

#' Column-level lineage
#'
#' Traces each output column of a query back to the tables and expressions it
#' is derived from, following CTEs, subqueries and set operations.
#'
#' @inheritParams sql_parse
#' @param schema Optional schema specification (see [as_polyglot_schema()]);
#'   improves resolution of unqualified or ambiguous columns.
#' @param column Optional single column name. By default, lineage is computed
#'   for every output column of the query.
#' @return A `polyglot_lineage` object: a list with one entry per column, each
#'   containing
#'   * `column` — the output column name;
#'   * `sources` — character vector of source tables feeding this column;
#'   * `tree` — the lineage graph as nested lists with fields `name`,
#'     `source_name`, `source_kind` (`"Table"`, `"Cte"`, `"DerivedTable"`,
#'     ...), `expression` (the SQL of the node's expression) and `downstream`.
#' @examples
#' sql_lineage("SELECT a + b AS total FROM t")
#' sql_lineage(
#'   "WITH base AS (SELECT id, amount FROM payments)
#'    SELECT id, amount * 2 AS doubled FROM base"
#' )
#' @export
sql_lineage <- function(sql, dialect = "generic", schema = NULL, column = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  if (!is.null(column)) {
    if (!is.character(column) || length(column) != 1L || is.na(column) ||
        !nzchar(column)) {
      stop_polyglot(
        "`column` must be NULL or a single non-empty character string.",
        class = "polyglot_argument_error"
      )
    }
  }
  value <- ffi_call(
    ffi_lineage, sql, dialect, column %||% "", as_polyglot_schema(schema),
    context = "parse"
  )
  structure(
    list(columns = value, sql = sql, dialect = dialect),
    class = "polyglot_lineage"
  )
}

#' Structural query analysis
#'
#' Extracts compact facts about a query: its shape, output projections,
#' referenced relations, CTEs, set operations and star-projections.
#'
#' @inheritParams sql_lineage
#' @return A `polyglot_analysis` object — a list with (among others):
#'   * `shape` — query shape (e.g. `"select"`, `"setOperation"`);
#'   * `projections` — list of per-output-column facts (name, transform kind,
#'     upstream column references, type hints when a `schema` is given);
#'   * `relations` — list of referenced relations with kind and alias;
#'   * `ctes`, `cteFacts` — CTE names and per-CTE facts;
#'   * `setOperations`, `starProjections` — when present.
#' @examples
#' a <- sql_analyze("WITH x AS (SELECT id FROM t) SELECT x.id, 2 AS two FROM x")
#' a$shape
#' vapply(a$projections, function(p) p$name, character(1))
#' @export
sql_analyze <- function(sql, dialect = "generic", schema = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(
    ffi_analyze, sql, dialect, as_polyglot_schema(schema),
    context = "parse"
  )
  structure(
    c(value, list(sql = sql, dialect = dialect)),
    class = "polyglot_analysis"
  )
}

#' Optimize SQL
#'
#' Applies the upstream optimizer rule set (predicate pushdown, join
#' reordering, CTE and subquery elimination, expression simplification,
#' etc.) and returns the rewritten SQL.
#'
#' @inheritParams sql_lineage
#' @return A character vector with one optimized statement per input
#'   statement.
#' @examples
#' sql_optimize("SELECT * FROM (SELECT a FROM t) AS sub WHERE sub.a > 1")
#' @export
sql_optimize <- function(sql, dialect = "generic", schema = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(
    ffi_optimize, sql, dialect, as_polyglot_schema(schema),
    context = "generate", simplify = TRUE
  )
  as.character(value)
}

#' Structural diff between two SQL statements
#'
#' Compares the ASTs of two statements and reports inserted, removed, moved
#' and updated nodes.
#'
#' @param sql_from,sql_to Single SQL statements to compare.
#' @inheritParams sql_parse
#' @param delta_only If `TRUE` (default), omit unchanged (`"keep"`) nodes.
#' @return A data frame with columns `op` (`"insert"`, `"remove"`, `"move"`,
#'   `"update"`, `"keep"`), `expression` (SQL of the affected node) and
#'   `target` (for updates, the new SQL).
#' @examples
#' sql_diff("SELECT a FROM t", "SELECT a, b FROM t WHERE a > 1")
#' @export
sql_diff <- function(sql_from, sql_to, dialect = "generic", delta_only = TRUE) {
  check_sql(sql_from, "sql_from")
  check_sql(sql_to, "sql_to")
  dialect <- check_dialect(dialect)
  check_flag(delta_only, "delta_only")
  value <- ffi_call(
    ffi_diff, sql_from, sql_to, dialect, delta_only,
    context = "parse"
  )
  data.frame(
    op = vapply(value, function(e) e$op, character(1)),
    expression = vapply(value, function(e) e$expression %||% "", character(1)),
    target = vapply(value, function(e) e$target %||% NA_character_, character(1)),
    stringsAsFactors = FALSE
  )
}

#' Annotate a query with inferred data types
#'
#' Runs upstream type inference over the AST. With a `schema`, column
#' references resolve to their declared types; without one, only types that
#' can be inferred from literals, casts and function signatures are filled.
#'
#' @inheritParams sql_lineage
#' @return A `polyglot_ast` object whose nodes carry an `inferred_type` field
#'   where a type could be determined. Pass it to [sql_generate()] to render,
#'   or inspect `$statements` directly.
#' @examples
#' ast <- sql_annotate_types(
#'   "SELECT id + 1 AS next_id FROM t",
#'   schema = list(t = c(id = "INT"))
#' )
#' # the Add node now carries inferred_type INT
#' @export
sql_annotate_types <- function(sql, dialect = "generic", schema = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(
    ffi_annotate_types, sql, dialect, as_polyglot_schema(schema),
    context = "parse"
  )
  structure(
    list(statements = list(value$ast), sql = sql, dialect = dialect),
    class = "polyglot_ast"
  )
}

#' OpenLineage column-lineage facet
#'
#' Produces an [OpenLineage](https://openlineage.io/)-compatible
#' `columnLineage` facet plus inferred input/output datasets for a SQL
#' statement, for integration with data catalogs and lineage backends.
#'
#' @inheritParams sql_lineage
#' @param namespace Optional dataset namespace applied to inferred datasets.
#' @param job_name Optional job name recorded in the facet.
#' @return A list with elements `facet` (the OpenLineage `columnLineage`
#'   facet), `inputs`, `outputs` (dataset descriptors) and `warnings`.
#' @examples
#' ol <- sql_openlineage(
#'   "INSERT INTO reports SELECT id, total FROM sales",
#'   namespace = "warehouse"
#' )
#' names(ol)
#' @export
sql_openlineage <- function(sql, dialect = "generic", schema = NULL,
                            namespace = NULL, job_name = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  for (nm in c("namespace", "job_name")) {
    val <- get(nm)
    if (!is.null(val) && (!is.character(val) || length(val) != 1L || is.na(val))) {
      stop_polyglot(
        sprintf("`%s` must be NULL or a single character string.", nm),
        class = "polyglot_argument_error"
      )
    }
  }
  ffi_call(
    ffi_openlineage, sql, dialect, namespace %||% "", job_name %||% "",
    as_polyglot_schema(schema),
    context = "parse"
  )
}
