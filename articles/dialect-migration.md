# Migrating SQL between dialects

``` r

library(polyglotSQL)
```

This vignette walks through a realistic migration: a small collection of
queries written for one engine that must run on another.

## Typical rewrites

Function names, quoting and syntax differ per engine. polyglotSQL
rewrites them structurally:

``` r

# MySQL constructs -> PostgreSQL
sql_transpile(
  "SELECT IFNULL(a, b), DATE_FORMAT(d, '%Y-%m-%d') FROM t LIMIT 5",
  from = "mysql", to = "postgres"
)
#> [1] "SELECT COALESCE(a, b), TO_CHAR(d, '%Y-%m-%d') FROM t LIMIT 5"

# T-SQL pagination and date functions -> PostgreSQL
sql_transpile(
  "SELECT TOP 10 name, GETDATE() AS now FROM users ORDER BY name",
  from = "tsql", to = "postgres"
)
#> [1] "SELECT name, CURRENT_TIMESTAMP AS now FROM users ORDER BY name NULLS FIRST LIMIT 10"

# BigQuery -> Snowflake: quoting and safe casts
sql_transpile(
  "SELECT `user id`, SAFE_CAST(x AS INT64) FROM `proj.dataset.tbl`",
  from = "bigquery", to = "snowflake"
)
#> [1] "SELECT \"user id\", CAST(x AS BIGINT) FROM \"proj.dataset.tbl\""
```

## Migrating a batch of queries

Because inputs and outputs are plain character vectors, migrating a
whole directory is a [`vapply()`](https://rdrr.io/r/base/lapply.html):

``` r

queries <- c(
  orders  = "SELECT IFNULL(status, 'unknown') AS status FROM orders",
  daily   = "SELECT DATE(created_at) AS d, COUNT(*) FROM events GROUP BY DATE(created_at)",
  users   = "SELECT id, CONCAT(first, ' ', last) AS full_name FROM users"
)

vapply(queries, sql_transpile, character(1),
       from = "mysql", to = "duckdb")
#>                                                                                         orders 
#>                                     "SELECT COALESCE(status, 'unknown') AS status FROM orders" 
#>                                                                                          daily 
#> "SELECT CAST(created_at AS DATE) AS d, COUNT(*) FROM events GROUP BY CAST(created_at AS DATE)" 
#>                                                                                          users 
#>                                  "SELECT id, CONCAT(first, ' ', last) AS full_name FROM users"
```

## Handling unsupported constructs

With the default `unsupported = "raise"`, polyglotSQL refuses to emit
SQL when the target dialect cannot express a construct, raising a
`polyglot_transpile_error`. For an inventory pass you may prefer to
collect failures:

``` r

migrate <- function(sql, from, to) {
  tryCatch(
    list(ok = TRUE, sql = sql_transpile(sql, from = from, to = to)),
    polyglot_error = function(e) list(ok = FALSE, error = conditionMessage(e))
  )
}
migrate("SELECT IFNULL(a, b) FROM t", "mysql", "postgres")
#> $ok
#> [1] TRUE
#> 
#> $sql
#> [1] "SELECT COALESCE(a, b) FROM t"
```

`unsupported = "warn"` or `"ignore"` instead return the closest
supported translation — useful for a first draft that a human reviews.

## Verifying the migration structurally

[`sql_diff()`](https://milkway.github.io/polyglot-sql-r/reference/sql_diff.md)
shows what actually changed between two statements, which is handy when
reviewing rewrites:

``` r

sql_diff(
  "SELECT a FROM t",
  "SELECT a, b FROM t WHERE a > 1"
)
#>       op expression target
#> 1 insert          a   <NA>
#> 2 insert          b   <NA>
#> 3 insert      a > 1   <NA>
#> 4 insert          1   <NA>
#> 5   move          a   <NA>
```

And
[`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md)
confirms the output parses in the target dialect:

``` r

out <- sql_transpile("SELECT IFNULL(a, b) FROM t", from = "mysql", to = "postgres")
sql_validate(out, dialect = "postgres")$valid
#> [1] TRUE
```

## What transpilation cannot do

Transpilation operates on *syntax*. It cannot:

- emulate engine-specific semantics (collations, implicit casts, `NULL`
  ordering, integer vs. float division, timezone behavior);
- create missing functions on the target engine;
- guarantee identical performance characteristics.

**Run the translated queries against the target database — ideally with
result comparisons — before trusting them in production.**
