# Optimize SQL

Applies the upstream optimizer rule set (predicate pushdown, join
reordering, CTE and subquery elimination, expression simplification,
etc.) and returns the rewritten SQL.

## Usage

``` r
sql_optimize(sql, dialect = "generic", schema = NULL)
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing.

- schema:

  Optional schema specification (see
  [`as_polyglot_schema()`](https://milkway.github.io/polyglot-sql-r/reference/as_polyglot_schema.md));
  improves resolution of unqualified or ambiguous columns.

## Value

A character vector with one optimized statement per input statement.

## Examples

``` r
sql_optimize("SELECT * FROM (SELECT a FROM t) AS sub WHERE sub.a > 1")
#> [1] "WITH _cte AS (SELECT a FROM t) SELECT * FROM _cte AS sub WHERE sub.a > 1"
```
