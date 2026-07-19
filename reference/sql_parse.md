# Parse SQL into an abstract syntax tree

Parse SQL into an abstract syntax tree

## Usage

``` r
sql_parse(sql, dialect = "generic")
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing.

## Value

A `polyglot_ast` object: a list with elements

- `statements` — a list with one nested-list AST per statement;

- `sql` — the input SQL;

- `dialect` — the dialect used.

Each AST node is a named list; the name of the outer element gives the
node kind (e.g. `"select"`). The structure follows the upstream
`polyglot-sql` JSON AST format and round-trips through
[`sql_generate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_generate.md).

## Examples

``` r
ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
ast
#> <polyglot_ast> 1 statement (generic)
#> [1] select
names(ast$statements[[1]])
#> [1] "select"
```
