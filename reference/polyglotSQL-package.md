# polyglotSQL: SQL Parsing, Analysis and Dialect Translation

Parse, tokenize, validate, format, analyze and translate SQL between
more than 30 dialects ('PostgreSQL', 'MySQL', 'BigQuery', 'Snowflake',
'DuckDB', 'T-SQL', and others) using the 'polyglot-sql' Rust crate
<https://github.com/tobilg/polyglot>, a Rust port of the 'SQLGlot'
'Python' library. All processing happens natively in process; no
database connection, 'Python' runtime or external service is required.
Includes column-level lineage, structural query analysis, query
optimization, 'AST' diffing and 'OpenLineage' facet generation.

## Acknowledgements

polyglotSQL embeds the
[polyglot-sql](https://github.com/tobilg/polyglot) Rust crate by Tobias
Müller (MIT), which is a Rust port of
[SQLGlot](https://github.com/tobymao/sqlglot) by Toby Mao (MIT). See
`inst/COPYRIGHTS` for the licenses of all vendored Rust dependencies.

## See also

Useful links:

- <https://github.com/milkway/polyglot-sql-r>

- <https://milkway.github.io/polyglot-sql-r/>

- Report bugs at <https://github.com/milkway/polyglot-sql-r/issues>

## Author

**Maintainer**: André Leite <leite@de.ufpe.br>

Authors:

- André Leite <leite@de.ufpe.br>

- Tobias Müller <github@tobilg.com> (Author of the bundled
  'polyglot-sql' Rust crate (Polyglot project)) \[copyright holder\]

- Toby Mao (Author of SQLGlot, from which Polyglot is derived)
  \[copyright holder\]

Other contributors:

- The authors of the vendored Rust dependencies (see inst/COPYRIGHTS)
  \[copyright holder\]
