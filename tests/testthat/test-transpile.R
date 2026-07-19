test_that("MySQL -> PostgreSQL rewrites IFNULL to COALESCE", {
  out <- sql_transpile("SELECT IFNULL(a, b) FROM t", from = "mysql", to = "postgres")
  expect_identical(out, "SELECT COALESCE(a, b) FROM t")
})

test_that("PostgreSQL -> DuckDB translates core constructs", {
  out <- sql_transpile(
    "SELECT id::text, DATE_TRUNC('month', created_at) FROM events",
    from = "postgres", to = "duckdb"
  )
  expect_length(out, 1)
  expect_match(out, "DATE_TRUNC", fixed = TRUE)
  expect_match(out, "CAST|::", perl = TRUE)
})

test_that("BigQuery -> Snowflake handles backtick quoting", {
  out <- sql_transpile(
    "SELECT `user id`, SAFE_CAST(x AS INT64) FROM `proj.dataset.tbl`",
    from = "bigquery", to = "snowflake"
  )
  expect_length(out, 1)
  expect_false(grepl("`", out, fixed = TRUE))
  expect_match(out, "\"user id\"", fixed = TRUE)
  expect_match(out, "CAST", fixed = TRUE)
  expect_false(grepl("INT64", out, fixed = TRUE))
})

test_that("T-SQL -> PostgreSQL rewrites TOP and functions", {
  out <- sql_transpile(
    "SELECT TOP 5 name, GETDATE() AS now FROM users",
    from = "tsql", to = "postgres"
  )
  expect_length(out, 1)
  expect_match(out, "LIMIT 5", fixed = TRUE)
  expect_false(grepl("GETDATE", out, fixed = TRUE))
})

test_that("multiple statements produce one element each", {
  out <- sql_transpile(
    "SELECT 1; SELECT IFNULL(a, b) FROM t;",
    from = "mysql", to = "postgres"
  )
  expect_length(out, 2)
  expect_identical(out[[2]], "SELECT COALESCE(a, b) FROM t")
})

test_that("pretty = TRUE produces multi-line output", {
  out <- sql_transpile(
    "SELECT a, b FROM t WHERE x = 1", from = "generic", to = "postgres",
    pretty = TRUE
  )
  expect_match(out, "\n", fixed = TRUE)
})

test_that("identity transpilation preserves simple SQL", {
  sql <- "SELECT a, b FROM t WHERE a > 1"
  expect_identical(
    sql_transpile(sql, from = "postgres", to = "postgres"),
    sql
  )
})

test_that("unsupported argument is validated", {
  expect_error(
    sql_transpile("SELECT 1", from = "mysql", to = "postgres", unsupported = "explode"),
    class = "polyglot_error"
  )
})
