test_that("valid SQL validates cleanly", {
  v <- sql_validate("SELECT a FROM t")
  expect_s3_class(v, "polyglot_validation")
  expect_true(v$valid)
  expect_identical(nrow(v$errors), 0L)
})

test_that("invalid SQL reports coded errors with locations", {
  v <- sql_validate("SELECT FROM WHERE")
  expect_false(v$valid)
  expect_gt(nrow(v$errors), 0)
  expect_true(all(grepl("^E[0-9]+", v$errors$code)))
})

test_that("strict_syntax rejects trailing commas", {
  permissive <- sql_validate("SELECT name, FROM employees")
  expect_true(permissive$valid)
  strict <- sql_validate("SELECT name, FROM employees", strict_syntax = TRUE)
  expect_false(strict$valid)
  expect_true("E005" %in% strict$errors$code)
})

test_that("semantic = TRUE surfaces quality warnings without invalidating", {
  v <- sql_validate(
    "SELECT *, category, COUNT(*) FROM products LIMIT 10",
    semantic = TRUE
  )
  expect_true(v$valid)
  expect_true(any(grepl("^W", v$errors$code)))
  expect_true(all(v$errors$severity == "warning"))
})

test_that("schema-aware validation flags unknown columns", {
  v <- sql_validate(
    "SELECT nonexistent FROM t",
    schema = list(t = c(id = "INT", name = "TEXT"))
  )
  expect_false(v$valid)
})

test_that("error = TRUE raises a polyglot_validation_error", {
  expect_error(
    sql_validate("SELECT FROM WHERE", error = TRUE),
    class = "polyglot_validation_error"
  )
  err <- tryCatch(
    sql_validate("SELECT FROM WHERE", error = TRUE),
    polyglot_validation_error = function(e) e
  )
  expect_s3_class(err$result, "polyglot_validation")
})

test_that("unknown validation options are rejected", {
  expect_error(
    sql_validate("SELECT 1", strictness = "max"),
    class = "polyglot_argument_error"
  )
})
