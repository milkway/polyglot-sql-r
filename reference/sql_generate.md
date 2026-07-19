# Generate SQL from a parsed AST

Renders a
[`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md)
result back into SQL text using the target dialect's syntax rules
(keywords, quoting, literals). Note this is plain *generation*: unlike
[`sql_transpile()`](https://milkway.github.io/polyglot-sql-r/reference/sql_transpile.md),
it does not apply cross-dialect function rewrites (e.g. `IFNULL` is not
converted to `COALESCE`). Use it to render programmatically-built or
modified ASTs; use
[`sql_transpile()`](https://milkway.github.io/polyglot-sql-r/reference/sql_transpile.md)
for full dialect translation.

## Usage

``` r
sql_generate(ast, dialect = "generic")
```

## Arguments

- ast:

  A `polyglot_ast` object from
  [`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md)
  (or
  [`sql_annotate_types()`](https://milkway.github.io/polyglot-sql-r/reference/sql_annotate_types.md)).

- dialect:

  Target dialect for rendering.

## Value

A character vector with one element per statement in the AST.

## Examples

``` r
ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
sql_generate(ast, dialect = "postgres")
#> [1] "SELECT a, b FROM t WHERE x = 1"
```
