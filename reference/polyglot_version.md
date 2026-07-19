# Versions of polyglotSQL and its embedded Rust engine

Versions of polyglotSQL and its embedded Rust engine

## Usage

``` r
polyglot_version()
```

## Value

A named character vector with elements `polyglotSQL` (the R package
version) and `polyglot_sql` (the version of the vendored
[polyglot-sql](https://github.com/tobilg/polyglot) Rust crate the
package was compiled against).

## Examples

``` r
polyglot_version()
#>  polyglotSQL polyglot_sql 
#>      "0.1.0"      "0.6.2" 
```
