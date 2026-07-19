# Validate SQL

Checks that SQL parses in the given dialect and, optionally, applies
stricter syntax rules, semantic lint warnings, and schema-aware checks.

## Usage

``` r
sql_validate(sql, dialect = "generic", ...)
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing.

- ...:

  Additional validation options:

  - `strict_syntax` — reject non-canonical syntax the parser would
    accept for compatibility (e.g. trailing commas before `FROM`);
    default `FALSE`.

  - `semantic` — report query-quality warnings (`W001`–`W004`, e.g.
    `SELECT *` mixed with explicit columns); default `FALSE`.

  - `schema` — a schema specification (see
    [`as_polyglot_schema()`](https://milkway.github.io/polyglot-sql-r/reference/as_polyglot_schema.md));
    enables unknown-table/column, type and reference checks.

  - `error` — if `TRUE`, raise a `polyglot_validation_error` instead of
    returning an invalid result; default `FALSE`.

## Value

A `polyglot_validation` object: a list with `valid` (logical) and
`errors` (data frame with columns `severity`, `code`, `message`, `line`,
`column`).

## Examples

``` r
sql_validate("SELECT a FROM t")
#> <polyglot_validation> valid (generic)
sql_validate("SELECT FROM WHERE")
#> <polyglot_validation> invalid (generic)
#> [E003] Expected table name or subquery, got Where at 1:18
v <- sql_validate("SELECT a, FROM t", strict_syntax = TRUE)
v$valid
#> [1] FALSE
```
