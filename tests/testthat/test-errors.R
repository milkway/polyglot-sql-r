test_that("invalid SQL raises a catchable polyglot_parse_error", {
  err <- tryCatch(
    sql_parse("SELECT ((( FROM"),
    polyglot_parse_error = function(e) e
  )
  expect_s3_class(err, "polyglot_parse_error")
  expect_s3_class(err, "polyglot_error")
  # and the session is fully usable afterwards
  expect_identical(sql_transpile("SELECT 1", from = "generic", to = "generic"), "SELECT 1")
})

test_that("unknown dialects raise polyglot_dialect_error from every entry point", {
  expect_error(sql_parse("SELECT 1", dialect = "klingon"), class = "polyglot_dialect_error")
  expect_error(
    sql_transpile("SELECT 1", from = "klingon", to = "postgres"),
    class = "polyglot_dialect_error"
  )
  expect_error(
    sql_transpile("SELECT 1", from = "postgres", to = "klingon"),
    class = "polyglot_dialect_error"
  )
  expect_error(sql_format("SELECT 1", dialect = "klingon"), class = "polyglot_dialect_error")
})

test_that("dialect errors suggest close matches", {
  err <- tryCatch(
    sql_parse("SELECT 1", dialect = "postgress"),
    polyglot_dialect_error = function(e) e
  )
  expect_match(conditionMessage(err), "postgres")
})

test_that("empty and NA SQL are rejected with polyglot_argument_error", {
  for (bad in list("", "   ", NA_character_, character(0), c("a", "b"), 42, NULL)) {
    expect_error(sql_parse(bad), class = "polyglot_argument_error")
    expect_error(
      sql_transpile(bad, from = "mysql", to = "postgres"),
      class = "polyglot_argument_error"
    )
    expect_error(sql_validate(bad), class = "polyglot_argument_error")
  }
})

test_that("errors are ordinary R conditions and never kill the session", {
  # a batch of hostile inputs: all must raise catchable conditions
  hostile <- c(
    "SELECT '" ,
    ")))))",
    "WITH WITH WITH",
    paste(rep("(", 500), collapse = ""),
    "/* unterminated", "--", "\u00e9\u00e7\u00e3o"
  )
  for (sql in hostile) {
    res <- tryCatch(sql_parse(sql), error = function(e) "caught")
    expect_true(identical(res, "caught") || inherits(res, "polyglot_ast"))
  }
  # session still alive and correct
  expect_identical(sql_source_tables("SELECT 1 FROM ok"), "ok")
})

test_that("deeply nested SQL hits complexity guards instead of crashing", {
  deep <- paste0(
    paste(rep("SELECT * FROM (", 200), collapse = ""),
    "SELECT 1",
    paste(rep(") AS q", 200), collapse = "")
  )
  res <- tryCatch(sql_parse(deep), error = function(e) e)
  # Either it parses (stacker feature grows the stack) or errors cleanly --
  # both acceptable; a crash is not.
  expect_true(inherits(res, "polyglot_ast") || inherits(res, "condition"))
  expect_identical(sql_transpile("SELECT 2", from = "generic", to = "generic"), "SELECT 2")
})

test_that("schema argument is validated", {
  expect_error(
    sql_validate("SELECT 1", schema = list(1, 2)),
    class = "polyglot_argument_error"
  )
  expect_error(
    sql_analyze("SELECT 1", schema = list(t = list(1))),
    class = "polyglot_argument_error"
  )
})
