test_that("sql_format pretty-prints SQL", {
  out <- sql_format("select a,b from t where x=1")
  expect_length(out, 1)
  expect_match(out, "\n", fixed = TRUE)
  expect_match(out, "SELECT", fixed = TRUE)
  expect_match(out, "FROM", fixed = TRUE)
})

test_that("sql_format handles multiple statements", {
  out <- sql_format("select 1; select 2")
  expect_length(out, 2)
})

test_that("complexity guards can be tightened and raise polyglot_guard_error", {
  long_sql <- paste0(
    "SELECT ", paste(sprintf("col_%d", 1:50), collapse = ", "), " FROM t"
  )
  expect_error(
    sql_format(long_sql, max_tokens = 10),
    class = "polyglot_guard_error"
  )
  expect_error(
    sql_format(long_sql, max_input_bytes = 5),
    class = "polyglot_guard_error"
  )
  # relaxing the guard makes it pass again
  expect_no_error(sql_format(long_sql, max_tokens = Inf))
})

test_that("set-operation chain guard is enforced", {
  chain <- paste(rep("SELECT 1", 6), collapse = " UNION ALL ")
  expect_error(
    sql_format(chain, max_set_op_chain = 2),
    class = "polyglot_guard_error"
  )
  expect_no_error(sql_format(chain))
})

test_that("guard arguments are validated on the R side", {
  expect_error(
    sql_format("SELECT 1", max_tokens = -5),
    class = "polyglot_argument_error"
  )
  expect_error(
    sql_format("SELECT 1", max_tokens = "many"),
    class = "polyglot_argument_error"
  )
})
