# polyglotSQL: SQL Parsing, Analysis and Dialect Translation

Parse, tokenize, validate, format, analyze and translate SQL between
more than 30 dialects ('PostgreSQL', 'MySQL', 'BigQuery', 'Snowflake',
'DuckDB', 'T-SQL', and others) using the 'polyglot-sql' Rust crate
<https://github.com/tobilg/polyglot>, a Rust port of the 'SQLGlot'
'Python' library. All processing happens locally in the R session; no
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

- <https://github.com/StrategicProjects/polyglot-sql-r>

- <https://strategicprojects.github.io/polyglot-sql-r/>

- Report bugs at
  <https://github.com/StrategicProjects/polyglot-sql-r/issues>

## Author

**Maintainer**: Andre Leite <leite@castlab.org>
([ORCID](https://orcid.org/0000-0002-4718-9766))

Authors:

- Andre Leite <leite@castlab.org>
  ([ORCID](https://orcid.org/0000-0002-4718-9766))

- Marcos Wasiliew <marcos.wasilew@gmail.com>

- Hugo Vasconcelos <hugo.vasconcelos@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6249-0920))

- Carlos Amorim <carlos.agaf@ufpe.br>
  ([ORCID](https://orcid.org/0000-0001-6315-8305))

- Diogo Bezerra <diogo.bezerra@ufpe.br>
  ([ORCID](https://orcid.org/0000-0002-1216-8674))

Other contributors:

- Tobias Müller <github@tobilg.com> (Author of the bundled
  'polyglot-sql' Rust crate (Polyglot project)) \[copyright holder\]

- Toby Mao (Author of SQLGlot, from which Polyglot is derived)
  \[copyright holder\]

- The authors of the vendored Rust dependencies (see inst/COPYRIGHTS)
  \[copyright holder\]
