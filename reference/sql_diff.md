# Structural diff between two SQL statements

Compares the ASTs of two statements and reports inserted, removed, moved
and updated nodes.

## Usage

``` r
sql_diff(sql_from, sql_to, dialect = "generic", delta_only = TRUE)
```

## Arguments

- sql_from, sql_to:

  Single SQL statements to compare.

- dialect:

  Dialect used for parsing.

- delta_only:

  If `TRUE` (default), omit unchanged (`"keep"`) nodes.

## Value

A data frame with columns `op` (`"insert"`, `"remove"`, `"move"`,
`"update"`, `"keep"`), `expression` (SQL of the affected node) and
`target` (for updates, the new SQL).

## Examples

``` r
sql_diff("SELECT a FROM t", "SELECT a, b FROM t WHERE a > 1")
#>       op expression target
#> 1 insert          a   <NA>
#> 2 insert          b   <NA>
#> 3 insert      a > 1   <NA>
#> 4 insert          1   <NA>
#> 5   move          a   <NA>
```
