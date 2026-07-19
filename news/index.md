# Changelog

## polyglotSQL 0.1.0

Initial release, wrapping the `polyglot-sql` Rust crate 0.6.2.

- Core:
  [`polyglot_version()`](https://milkway.github.io/polyglot-sql-r/reference/polyglot_version.md),
  [`sql_dialects()`](https://milkway.github.io/polyglot-sql-r/reference/sql_dialects.md)
  (34 dialects with aliases).
- Transpilation and formatting:
  [`sql_transpile()`](https://milkway.github.io/polyglot-sql-r/reference/sql_transpile.md),
  [`sql_format()`](https://milkway.github.io/polyglot-sql-r/reference/sql_format.md),
  [`sql_generate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_generate.md)
  with complexity guards and configurable handling of unsupported
  constructs.
- Parsing and validation:
  [`sql_parse()`](https://milkway.github.io/polyglot-sql-r/reference/sql_parse.md),
  [`sql_tokenize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_tokenize.md),
  [`sql_validate()`](https://milkway.github.io/polyglot-sql-r/reference/sql_validate.md)
  (strict syntax, semantic warnings, schema-aware checks).
- Analysis and lineage:
  [`sql_source_tables()`](https://milkway.github.io/polyglot-sql-r/reference/sql_source_tables.md),
  [`sql_lineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_lineage.md),
  [`sql_analyze()`](https://milkway.github.io/polyglot-sql-r/reference/sql_analyze.md),
  [`sql_optimize()`](https://milkway.github.io/polyglot-sql-r/reference/sql_optimize.md),
  [`sql_diff()`](https://milkway.github.io/polyglot-sql-r/reference/sql_diff.md),
  [`sql_annotate_types()`](https://milkway.github.io/polyglot-sql-r/reference/sql_annotate_types.md),
  [`sql_openlineage()`](https://milkway.github.io/polyglot-sql-r/reference/sql_openlineage.md).
- Classed error conditions (`polyglot_error`, `polyglot_parse_error`,
  `polyglot_transpile_error`, `polyglot_validation_error`,
  `polyglot_guard_error`, …); Rust failures never crash the R session.
- Fully offline source builds via vendored crates (`cargo vendor`).
