# OpenLineage column-lineage facet

Produces an [OpenLineage](https://openlineage.io/)-compatible
`columnLineage` facet plus inferred input/output datasets for a SQL
statement, for integration with data catalogs and lineage backends.

## Usage

``` r
sql_openlineage(
  sql,
  dialect = "generic",
  schema = NULL,
  namespace = NULL,
  job_name = NULL
)
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

- namespace:

  Optional dataset namespace applied to inferred datasets.

- job_name:

  Optional job name recorded in the facet.

## Value

A list with elements `facet` (the OpenLineage `columnLineage` facet),
`inputs`, `outputs` (dataset descriptors) and `warnings`.

## Examples

``` r
ol <- sql_openlineage(
  "INSERT INTO reports SELECT id, total FROM sales",
  namespace = "warehouse"
)
names(ol)
#> [1] "facet"    "inputs"   "outputs"  "warnings"
```
