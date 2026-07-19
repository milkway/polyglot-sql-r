# Structural query analysis

Extracts compact facts about a query: its shape, output projections,
referenced relations, CTEs, set operations and star-projections.

## Usage

``` r
sql_analyze(sql, dialect = "generic", schema = NULL)
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

A `polyglot_analysis` object — a list with (among others):

- `shape` — query shape (e.g. `"select"`, `"setOperation"`);

- `projections` — list of per-output-column facts (name, transform kind,
  upstream column references, type hints when a `schema` is given);

- `relations` — list of referenced relations with kind and alias;

- `ctes`, `cteFacts` — CTE names and per-CTE facts;

- `setOperations`, `starProjections` — when present.

## Examples

``` r
a <- sql_analyze("WITH x AS (SELECT id FROM t) SELECT x.id, 2 AS two FROM x")
a$shape
#> [1] "select"
vapply(a$projections, function(p) p$name, character(1))
#> [1] "id"  "two"
```
