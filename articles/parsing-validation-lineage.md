# Parsing, validation and lineage

``` r

library(polyglotSQL)
```

## The AST

[`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md)
returns the full abstract syntax tree as nested R lists, following the
upstream JSON AST format:

``` r

ast <- sql_parse("SELECT a, SUM(b) AS total FROM t GROUP BY a")
ast
#> <polyglot_ast> 1 statement (generic)
#> [1] select
str(ast$statements[[1]], max.level = 3, list.len = 4)
#> List of 1
#>  $ select:List of 26
#>   ..$ cluster_by      : NULL
#>   ..$ connect         : NULL
#>   ..$ distinct        : logi FALSE
#>   ..$ distinct_on     : NULL
#>   .. [list output truncated]
```

The AST round-trips:
[`sql_generate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_generate.md)
renders it back to SQL in any dialect.

## Tokens

For lower-level tooling (syntax highlighting, linters),
[`sql_tokenize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_tokenize.md)
exposes the token stream with exact positions:

``` r

sql_tokenize("SELECT a FROM t WHERE x = 'hé'")
#> <polyglot_tokens> 8 tokens
#>     type   text line column start end
#> 1 Select SELECT    1      7     0   6
#> 2    Var      a    1      9     7   8
#> 3   From   FROM    1     14     9  13
#> 4    Var      t    1     16    14  15
#> 5  Where  WHERE    1     22    16  21
#> 6    Var      x    1     24    22  23
#> 7     Eq      =    1     26    24  25
#> 8 String     hé    1     31    26  30
```

## Validation

Three layers of checking are available:

``` r

# 1. Syntax only (default)
sql_validate("SELECT FROM WHERE")
#> <polyglot_validation> invalid (generic)
#> [E003] Expected table name or subquery, got Where at 1:18

# 2. Strict syntax + semantic lint warnings
sql_validate("SELECT name, FROM employees", strict_syntax = TRUE)
#> <polyglot_validation> invalid (generic)
#> [E005] Trailing comma before FROM is not allowed in strict syntax mode at 1:13
sql_validate("SELECT *, category FROM products LIMIT 10", semantic = TRUE)
#> <polyglot_validation> valid (generic)
#> [W001] SELECT * is discouraged; specify columns explicitly for better
#> performance and maintainability
#> [W004] LIMIT without ORDER BY produces non-deterministic results
```

The third layer is **schema-aware** validation. Describe your tables as
a named list — names are tables, values are (optionally named) column
vectors:

``` r

schema <- list(
  orders = c(o_id = "INT", o_user = "INT", o_total = "DECIMAL(10,2)"),
  users  = c(id = "INT", name = "TEXT")
)

sql_validate("SELECT o_missing FROM orders", schema = schema)
#> <polyglot_validation> invalid (generic)
#> [E201] Unknown column 'o_missing' in table 'orders'
```

Use `error = TRUE` to turn an invalid result into a
`polyglot_validation_error` condition — convenient in pipelines.

## Source tables

``` r

sql_source_tables(
  "WITH cte AS (SELECT id FROM base)
   SELECT * FROM cte JOIN other USING (id)"
)
#> [1] "other" "base"
```

Note the CTE itself is not listed — only physical sources are.

## Column-level lineage

[`sql_lineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_lineage.md)
traces every output column through CTEs, subqueries and expressions down
to source tables:

``` r

lin <- sql_lineage(
  "WITH base AS (SELECT id, amount FROM payments)
   SELECT id, amount * 2 AS doubled FROM base"
)
lin
#> <polyglot_lineage> 2 columns (generic)
#> id ← payments
#> doubled ← payments
```

Each entry carries the full lineage tree:

``` r

str(lin$columns[[2]]$tree, max.level = 2)
#> List of 5
#>  $ downstream :List of 1
#>   ..$ :List of 5
#>  $ expression : chr "amount * 2 AS doubled"
#>  $ name       : chr "doubled"
#>  $ source_kind: chr "Root"
#>  $ source_name: chr ""
```

A schema improves resolution of unqualified or ambiguous columns, and
`column =` restricts lineage to one output column.

## Structural analysis

[`sql_analyze()`](https://milkway.github.io/polyglot-sql-r/reference/sql_analyze.md)
condenses a query into facts — shape, projections, relations, CTEs, set
operations:

``` r

a <- sql_analyze(
  "WITH x AS (SELECT id FROM t)
   SELECT x.id, UPPER(name) AS shout FROM x JOIN u ON x.id = u.id"
)
a
#> <polyglot_analysis> shape: select (generic)
#> projections: id, shout
#> relations: u, x
#> ctes: x
vapply(a$projections, function(p) p$transformKind, character(1))
#> [1] "direct"     "expression"
```

## OpenLineage export

For data catalogs that speak [OpenLineage](https://openlineage.io/),
[`sql_openlineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_openlineage.md)
emits a `columnLineage` facet with inferred input/output datasets:

``` r

ol <- sql_openlineage(
  "INSERT INTO reports SELECT id, total FROM sales",
  namespace = "warehouse"
)
names(ol)
#> [1] "facet"    "inputs"   "outputs"  "warnings"
```
