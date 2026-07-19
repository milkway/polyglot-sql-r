# Column-level lineage

Traces each output column of a query back to the tables and expressions
it is derived from, following CTEs, subqueries and set operations.

## Usage

``` r
sql_lineage(sql, dialect = "generic", schema = NULL, column = NULL)
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

- column:

  Optional single column name. By default, lineage is computed for every
  output column of the query.

## Value

A `polyglot_lineage` object: a list with one entry per column, each
containing

- `column` — the output column name;

- `sources` — character vector of source tables feeding this column;

- `tree` — the lineage graph as nested lists with fields `name`,
  `source_name`, `source_kind` (`"Table"`, `"Cte"`, `"DerivedTable"`,
  ...), `expression` (the SQL of the node's expression) and
  `downstream`.

## Examples

``` r
sql_lineage("SELECT a + b AS total FROM t")
#> <polyglot_lineage> 1 column (generic)
#> total ← t
sql_lineage(
  "WITH base AS (SELECT id, amount FROM payments)
   SELECT id, amount * 2 AS doubled FROM base"
)
#> <polyglot_lineage> 2 columns (generic)
#> id ← payments
#> doubled ← payments
```
