# Getting started with polyglotSQL

polyglotSQL gives R a native SQL compiler front-end: parse, tokenize,
validate, format, analyze and translate SQL between more than 30
dialects. All the heavy lifting happens in the embedded
[polyglot-sql](https://github.com/tobilg/polyglot) Rust crate —
in-process, with no external services.

``` r

library(polyglotSQL)
polyglot_version()
#>  polyglotSQL polyglot_sql 
#>      "0.1.0"      "0.6.2"
```

## Your first translation

The flagship feature is dialect translation. SQL is parsed with the
source dialect into an abstract syntax tree (AST) and regenerated with
the target dialect’s rules:

``` r

sql_transpile(
  "SELECT IFNULL(a, b) FROM t",
  from = "mysql",
  to = "postgres"
)
#> [1] "SELECT COALESCE(a, b) FROM t"
```

Multiple statements are supported; the result has one element per
statement:

``` r

sql_transpile(
  "SELECT 1; SELECT IFNULL(a, b) FROM t;",
  from = "mysql",
  to = "postgres"
)
#> [1] "SELECT 1"                     "SELECT COALESCE(a, b) FROM t"
```

Set `pretty = TRUE` for indented output, and control what happens when a
construct has no equivalent in the target dialect with `unsupported`
(`"raise"` — the default — errors; `"warn"`/`"ignore"` return
best-effort SQL):

``` r

cat(sql_transpile(
  "SELECT id, COUNT(*) AS n FROM logs GROUP BY id HAVING COUNT(*) > 10",
  from = "generic", to = "snowflake", pretty = TRUE
))
#> SELECT
#>   id,
#>   COUNT(*) AS n
#> FROM logs
#> GROUP BY
#>   id
#> HAVING
#>   COUNT(*) > 10
```

## Which dialects?

``` r

head(sql_dialects(full = TRUE), 10)
#>          name  aliases                                    description
#> 1     generic          Standard SQL with no dialect-specific behavior
#> 2  postgresql postgres                                     PostgreSQL
#> 3       mysql                                                   MySQL
#> 4    bigquery                                         Google BigQuery
#> 5   snowflake                                               Snowflake
#> 6      duckdb                                                  DuckDB
#> 7      sqlite                                                  SQLite
#> 8        hive                                             Apache Hive
#> 9       spark   spark2                               Apache Spark SQL
#> 10      trino                              Trino (formerly PrestoSQL)
```

Any function accepting a dialect also accepts the listed aliases —
`"mssql"` and `"sqlserver"` both mean `"tsql"`, `"postgresql"` means
`"postgres"`.

## Formatting

``` r

cat(sql_format("select id,sum(x) total from t where y=1 group by id"))
#> SELECT
#>   id,
#>   SUM(x) AS total
#> FROM t
#> WHERE
#>   y = 1
#> GROUP BY
#>   id
```

## Validating

[`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md)
returns a structured result instead of throwing:

``` r

sql_validate("SELECT FROM WHERE")
#> <polyglot_validation> invalid (generic)
#> [E003] Expected table name or subquery, got Where at 1:18
```

## Parsing and round-tripping

``` r

ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
ast
#> <polyglot_ast> 1 statement (generic)
#> [1] select
```

The AST is a plain nested list following the upstream JSON format, and
can be rendered back to SQL with any dialect’s syntax rules (for full
translation with function rewrites, use
[`sql_transpile()`](https://milkway.github.io/polyglot-sql-r/reference/sql_transpile.md)):

``` r

sql_generate(sql_parse("SELECT `col name` FROM t", dialect = "mysql"),
             dialect = "postgres")
#> [1] "SELECT \"col name\" FROM t"
```

## Errors are classed conditions

All failures raise ordinary R conditions with useful classes
(`polyglot_parse_error`, `polyglot_transpile_error`,
`polyglot_validation_error`, `polyglot_guard_error`, all inheriting from
`polyglot_error`), so you can handle them precisely:

``` r

tryCatch(
  sql_parse("SELECT ((( FROM"),
  polyglot_parse_error = function(e) conditionMessage(e)
)
#> [1] "Expected table name or subquery, got From (line 1, column 16)"
```

A parse failure — even a bug-triggered panic inside Rust — never
terminates your R session.

## Where to next?

- [`vignette("dialect-migration")`](https://milkway.github.io/polyglot-sql-r/articles/dialect-migration.md)
  — migrating a query base between engines.
- [`vignette("parsing-validation-lineage")`](https://milkway.github.io/polyglot-sql-r/articles/parsing-validation-lineage.md)
  — ASTs, schemas, lineage and analysis.
- [`vignette("installation-and-troubleshooting")`](https://milkway.github.io/polyglot-sql-r/articles/installation-and-troubleshooting.md)
  — Rust toolchain, offline builds, common problems.
