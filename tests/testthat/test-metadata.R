test_that("polyglot_version() reports package and crate versions", {
  v <- polyglot_version()
  expect_type(v, "character")
  expect_named(v, c("polyglotSQL", "polyglot_sql"))
  expect_identical(v[["polyglotSQL"]], as.character(packageVersion("polyglotSQL")))
  # crate version must be a proper semver, never the "unknown" fallback
  expect_match(v[["polyglot_sql"]], "^[0-9]+\\.[0-9]+\\.[0-9]+$")
})

test_that("linked crate version matches the version declared in DESCRIPTION", {
  v <- polyglot_version()
  declared <- utils::packageDescription("polyglotSQL")[["Config/polyglotSQL/upstream"]]
  expect_false(is.null(declared))
  expect_identical(v[["polyglot_sql"]], trimws(declared))
})

test_that("sql_dialects() returns all canonical dialects", {
  d <- sql_dialects()
  expect_type(d, "character")
  expect_true(length(d) >= 34)
  expect_true(all(c(
    "generic", "postgresql", "mysql", "bigquery", "snowflake", "duckdb",
    "sqlite", "tsql", "oracle", "clickhouse", "trino", "databricks"
  ) %in% d))
  expect_false(anyDuplicated(d) > 0)
})

test_that("sql_dialects(full = TRUE) returns metadata", {
  d <- sql_dialects(full = TRUE)
  expect_s3_class(d, "data.frame")
  expect_named(d, c("name", "aliases", "description"))
  tsql <- d[d$name == "tsql", ]
  expect_match(tsql$aliases, "mssql")
  expect_match(tsql$aliases, "sqlserver")
})

test_that("dialect registry is in sync with upstream (self-check)", {
  problems <- polyglotSQL:::ffi_call(polyglotSQL:::ffi_dialects_selfcheck, simplify = TRUE)
  expect_length(problems, 0)
})
