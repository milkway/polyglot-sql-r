test_that("sql_analyze reports shape, projections and relations", {
  a <- sql_analyze("SELECT id, UPPER(name) AS shout FROM users u")
  expect_s3_class(a, "polyglot_analysis")
  expect_type(a$shape, "character")
  projections <- vapply(a$projections, function(p) p$name %||% "", character(1))
  expect_setequal(projections, c("id", "shout"))
  relations <- vapply(a$relations, function(r) r$name %||% "", character(1))
  expect_true("users" %in% relations)
})

test_that("sql_analyze surfaces CTE facts", {
  a <- sql_analyze(
    "WITH x AS (SELECT id FROM t), y AS (SELECT id FROM x)
     SELECT y.id, 2 AS two FROM y"
  )
  expect_setequal(unlist(a$ctes), c("x", "y"))
  expect_length(a$cteFacts, 2)
  projections <- vapply(a$projections, function(p) p$name %||% "", character(1))
  expect_setequal(projections, c("id", "two"))
})

test_that("sql_analyze uses a schema for richer projection facts", {
  a <- sql_analyze(
    "SELECT id FROM t",
    schema = list(t = c(id = "INT"))
  )
  expect_length(a$projections, 1)
  upstream <- a$projections[[1]]$upstream
  expect_true(length(upstream) >= 1)
})

test_that("sql_analyze detects set operations", {
  a <- sql_analyze("SELECT a FROM t UNION ALL SELECT a FROM u")
  expect_match(a$shape, "set", ignore.case = TRUE)
})

`%||%` <- function(x, y) if (is.null(x)) y else x
