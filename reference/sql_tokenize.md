# Tokenize SQL

Splits SQL into lexical tokens using the tokenizer of the given dialect.

## Usage

``` r
sql_tokenize(sql, dialect = "generic")
```

## Arguments

- sql:

  A single character string with one or more SQL statements (separated
  by `;`).

- dialect:

  Dialect used for parsing.

## Value

A data frame with class `polyglot_tokens` and one row per token: `type`
(token type, e.g. `"Select"`, `"Identifier"`, `"Number"`), `text` (raw
token text), `line` and `column` (1-based position), `start` and `end`
(byte offsets, end exclusive).

## Examples

``` r
sql_tokenize("SELECT a FROM t")
#> <polyglot_tokens> 4 tokens
#>     type   text line column start end
#> 1 Select SELECT    1      7     0   6
#> 2    Var      a    1      9     7   8
#> 3   From   FROM    1     14     9  13
#> 4    Var      t    1     16    14  15
```
