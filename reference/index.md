# Package index

## Core

Package and engine metadata.

- [`polyglotSQL`](https://milkway.github.io/polyglot-sql-r/reference/polyglotSQL-package.md)
  [`polyglotSQL-package`](https://milkway.github.io/polyglot-sql-r/reference/polyglotSQL-package.md)
  : polyglotSQL: SQL Parsing, Analysis and Dialect Translation
- [`polyglot_version()`](https://milkway.github.io/polyglot-sql-r/reference/polyglot_version.md)
  : Versions of polyglotSQL and its embedded Rust engine

## Transpilation and Formatting

Translate SQL between dialects and pretty-print it.

- [`sql_transpile()`](https://milkway.github.io/polyglot-sql-r/reference/sql_transpile.md)
  : Translate SQL between dialects
- [`sql_format()`](https://milkway.github.io/polyglot-sql-r/reference/sql_format.md)
  : Format (pretty-print) SQL
- [`sql_generate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_generate.md)
  : Generate SQL from a parsed AST

## Parsing and Validation

ASTs, tokens and multi-level validation.

- [`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md)
  : Parse SQL into an abstract syntax tree
- [`sql_tokenize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_tokenize.md)
  : Tokenize SQL
- [`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md)
  : Validate SQL

## Analysis and Lineage

Structural facts, column lineage, optimization and diffing.

- [`sql_source_tables()`](https://milkway.github.io/polyglot-sql-r/reference/sql_source_tables.md)
  : List source tables referenced by SQL
- [`sql_lineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_lineage.md)
  : Column-level lineage
- [`sql_analyze()`](https://milkway.github.io/polyglot-sql-r/reference/sql_analyze.md)
  : Structural query analysis
- [`sql_optimize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_optimize.md)
  : Optimize SQL
- [`sql_diff()`](https://milkway.github.io/polyglot-sql-r/reference/sql_diff.md)
  : Structural diff between two SQL statements
- [`sql_annotate_types()`](https://milkway.github.io/polyglot-sql-r/reference/sql_annotate_types.md)
  : Annotate a query with inferred data types
- [`sql_openlineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_openlineage.md)
  : OpenLineage column-lineage facet

## Metadata

Dialect discovery and schema helpers.

- [`sql_dialects()`](https://milkway.github.io/polyglot-sql-r/reference/sql_dialects.md)
  : List supported SQL dialects
- [`as_polyglot_schema()`](https://milkway.github.io/polyglot-sql-r/reference/as_polyglot_schema.md)
  : Specify a table schema for schema-aware operations
