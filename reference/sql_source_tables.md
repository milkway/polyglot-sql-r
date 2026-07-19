# List source tables referenced by SQL

Returns the physical tables a query reads from, across all statements.
CTE names are not included (they are intermediate results, not sources).

## Usage

``` r
sql_source_tables(sql, dialect = "generic")
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing.

## Value

A character vector of table names, in order of first appearance.

## Examples

``` r
sql_source_tables("SELECT * FROM a JOIN b ON a.id = b.id")
#> [1] "a" "b"
sql_source_tables("WITH x AS (SELECT 1 FROM t) SELECT * FROM x")
#> [1] "t"
```
