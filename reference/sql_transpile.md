# Translate SQL between dialects

Parses `sql` with the `from` dialect and regenerates it in the `to`
dialect, rewriting functions, quoting, and constructs as needed (e.g.
MySQL `IFNULL()` becomes PostgreSQL `COALESCE()`).

## Usage

``` r
sql_transpile(
  sql,
  from,
  to,
  pretty = FALSE,
  unsupported = c("raise", "warn", "ignore")
)
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- from:

  Source dialect name (see
  [`sql_dialects()`](https://milkway.github.io/polyglot-sql-r/reference/sql_dialects.md)).

- to:

  Target dialect name (see
  [`sql_dialects()`](https://milkway.github.io/polyglot-sql-r/reference/sql_dialects.md)).

- pretty:

  If `TRUE`, pretty-print the output.

- unsupported:

  How to handle constructs that cannot be represented in the target
  dialect: `"raise"` (default) throws a `polyglot_transpile_error`;
  `"warn"` and `"ignore"` continue and return the closest supported
  translation (with `"warn"`, upstream collects diagnostics but still
  returns a result).

## Value

A character vector with one element per input statement.

## Semantic limitations

Transpilation is syntactic and best-effort: identical syntax can still
behave differently across engines (implicit casts, collations, `NULL`
ordering, integer division, time zone handling...). Always test the
translated SQL against the target database before using it in
production.

## See also

[`sql_format()`](https://milkway.github.io/polyglot-sql-r/reference/sql_format.md),
[`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md),
[`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md)

## Examples

``` r
sql_transpile("SELECT IFNULL(a, b) FROM t", from = "mysql", to = "postgres")
#> [1] "SELECT COALESCE(a, b) FROM t"
sql_transpile(
  "SELECT DATE_TRUNC('month', created_at) FROM events",
  from = "postgres", to = "duckdb"
)
#> [1] "SELECT DATE_TRUNC('month', created_at) FROM events"
```
