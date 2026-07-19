# Annotate a query with inferred data types

Runs upstream type inference over the AST. With a `schema`, column
references resolve to their declared types; without one, only types that
can be inferred from literals, casts and function signatures are filled.

## Usage

``` r
sql_annotate_types(sql, dialect = "generic", schema = NULL)
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

A `polyglot_ast` object whose nodes carry an `inferred_type` field where
a type could be determined. Pass it to
[`sql_generate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_generate.md)
to render, or inspect `$statements` directly.

## Examples

``` r
ast <- sql_annotate_types(
  "SELECT id + 1 AS next_id FROM t",
  schema = list(t = c(id = "INT"))
)
# the Add node now carries inferred_type INT
```
