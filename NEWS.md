# polyglotSQL 0.1.0

Initial release, wrapping the `polyglot-sql` Rust crate 0.6.2.

* Core: `polyglot_version()`, `sql_dialects()` (34 dialects with aliases).
* Transpilation and formatting: `sql_transpile()`, `sql_format()`,
  `sql_generate()` with complexity guards and configurable handling of
  unsupported constructs.
* Parsing and validation: `sql_parse()`, `sql_tokenize()`, `sql_validate()`
  (strict syntax, semantic warnings, schema-aware checks).
* Analysis and lineage: `sql_source_tables()`, `sql_lineage()`,
  `sql_analyze()`, `sql_optimize()`, `sql_diff()`, `sql_annotate_types()`,
  `sql_openlineage()`.
* Classed error conditions (`polyglot_error`, `polyglot_parse_error`,
  `polyglot_transpile_error`, `polyglot_validation_error`,
  `polyglot_guard_error`, ...); Rust failures never crash the R session.
* Fully offline source builds via vendored crates (`cargo vendor`).
