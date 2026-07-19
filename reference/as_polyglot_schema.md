# Specify a table schema for schema-aware operations

Several polyglotSQL functions
([`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md),
[`sql_lineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_lineage.md),
[`sql_analyze()`](https://milkway.github.io/polyglot-sql-r/reference/sql_analyze.md),
[`sql_optimize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_optimize.md),
[`sql_annotate_types()`](https://milkway.github.io/polyglot-sql-r/reference/sql_annotate_types.md),
[`sql_openlineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_openlineage.md))
accept an optional `schema` argument describing the tables referenced by
the query. A schema enables column qualification, type inference, and
existence checks.

## Usage

``` r
as_polyglot_schema(schema)
```

## Arguments

- schema:

  A schema specification (named list as described above), or `NULL` for
  no schema.

## Value

A JSON string in the upstream `ValidationSchema` format, or `""` when
`schema` is `NULL`. Mostly used internally; exported for advanced users
who want to inspect the generated payload.

## Details

A schema is a named list with one entry per table. Each entry is either:

- a *named* character vector mapping column names to SQL types, e.g.
  `c(id = "INT", name = "TEXT")`;

- an *unnamed* character vector of column names (types unknown), e.g.
  `c("id", "name")`.

## Examples

``` r
as_polyglot_schema(list(
  orders = c(o_id = "INT", o_total = "DECIMAL(10,2)"),
  users = c("id", "name")
))
#> [1] "{\"tables\":[{\"name\":\"orders\",\"columns\":[{\"name\":\"o_id\",\"type\":\"INT\"},{\"name\":\"o_total\",\"type\":\"DECIMAL(10,2)\"}]},{\"name\":\"users\",\"columns\":[{\"name\":\"id\",\"type\":\"\"},{\"name\":\"name\",\"type\":\"\"}]}]}"
```
