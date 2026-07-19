# List supported SQL dialects

List supported SQL dialects

## Usage

``` r
sql_dialects(full = FALSE)
```

## Arguments

- full:

  If `FALSE` (default), return a character vector of canonical dialect
  names. If `TRUE`, return a data frame with columns `name`, `aliases`
  (comma-separated accepted aliases) and `description`.

## Value

A character vector, or a data frame when `full = TRUE`.

## Details

Every function that takes a `dialect`, `from` or `to` argument accepts
both the canonical names and the aliases (e.g. `"postgresql"` for
`"postgres"`, `"mssql"` or `"sqlserver"` for `"tsql"`).

## Examples

``` r
sql_dialects()
#>  [1] "generic"     "postgresql"  "mysql"       "bigquery"    "snowflake"  
#>  [6] "duckdb"      "sqlite"      "hive"        "spark"       "trino"      
#> [11] "presto"      "redshift"    "tsql"        "oracle"      "clickhouse" 
#> [16] "databricks"  "athena"      "teradata"    "doris"       "starrocks"  
#> [21] "materialize" "risingwave"  "singlestore" "cockroachdb" "tidb"       
#> [26] "druid"       "solr"        "tableau"     "dune"        "fabric"     
#> [31] "drill"       "dremio"      "exasol"      "datafusion" 
head(sql_dialects(full = TRUE))
#>         name  aliases                                    description
#> 1    generic          Standard SQL with no dialect-specific behavior
#> 2 postgresql postgres                                     PostgreSQL
#> 3      mysql                                                   MySQL
#> 4   bigquery                                         Google BigQuery
#> 5  snowflake                                               Snowflake
#> 6     duckdb                                                  DuckDB
```
