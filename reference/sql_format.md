# Format (pretty-print) SQL

Parses and re-renders SQL as canonically indented statements. Complexity
guards protect against pathological inputs; exceeding a guard raises a
`polyglot_guard_error`.

## Usage

``` r
sql_format(
  sql,
  dialect = "generic",
  max_input_bytes = NULL,
  max_tokens = NULL,
  max_ast_nodes = NULL,
  max_set_op_chain = NULL
)
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing and rendering.

- max_input_bytes, max_tokens, max_ast_nodes, max_set_op_chain:

  Complexity guard limits. `NULL` (default) uses the upstream defaults
  (16 MiB input, 1e6 tokens, 1e6 AST nodes, 256 chained set operations);
  `Inf` disables a guard; a positive number sets an explicit limit.

## Value

A character vector with one formatted statement per input statement.

## Examples

``` r
cat(sql_format("select a,b from t where x=1 and y=2"))
#> SELECT
#>   a,
#>   b
#> FROM t
#> WHERE
#>   x = 1 AND y = 2
```
