test_that("sql_optimize rewrites and qualifies", {
  # with a schema, columns get qualified and aliased
  out <- sql_optimize(
    "SELECT a FROM t WHERE a > 2",
    schema = list(t = c(a = "INT"))
  )
  expect_length(out, 1)
  expect_match(out, "t.a", fixed = TRUE)

  # structural rewrites (subquery -> CTE) still produce valid SQL
  out2 <- sql_optimize("SELECT * FROM (SELECT a FROM t) AS sub WHERE sub.a > 1")
  expect_true(sql_validate(out2)$valid)
  expect_true(nzchar(out2))
})

test_that("sql_diff reports structural edits", {
  d <- sql_diff("SELECT a FROM t", "SELECT a, b FROM t")
  expect_s3_class(d, "data.frame")
  expect_named(d, c("op", "expression", "target"))
  expect_true("insert" %in% d$op)
  expect_true(any(d$expression == "b" & d$op == "insert"))
})

test_that("sql_diff with delta_only = FALSE includes kept nodes", {
  d <- sql_diff("SELECT a FROM t", "SELECT a FROM t", delta_only = FALSE)
  expect_true(all(d$op == "keep"))
})

test_that("sql_annotate_types infers types from a schema", {
  ast <- sql_annotate_types(
    "SELECT id + 1 AS next_id FROM t",
    schema = list(t = c(id = "INT"))
  )
  expect_s3_class(ast, "polyglot_ast")
  json <- jsonlite::toJSON(ast$statements, auto_unbox = TRUE)
  expect_match(as.character(json), "inferred_type", fixed = TRUE)
})

test_that("sql_openlineage produces a columnLineage facet", {
  ol <- sql_openlineage(
    "INSERT INTO reports SELECT id, total FROM sales",
    namespace = "warehouse"
  )
  expect_type(ol, "list")
  expect_true(all(c("facet", "inputs", "outputs") %in% names(ol)))
  inputs <- vapply(ol$inputs, function(d) d$name %||% "", character(1))
  expect_true(any(grepl("sales", inputs, fixed = TRUE)))
})

test_that("print methods produce compact output", {
  # cli output bypasses expect_output()'s sink; snapshots capture it reliably
  expect_snapshot(print(sql_parse("SELECT 1")))
  expect_snapshot(print(sql_validate("SELECT 1")))
  expect_snapshot(print(sql_validate("SELECT FROM WHERE")))
  expect_snapshot(print(sql_lineage("SELECT a FROM t")))
  expect_snapshot(print(sql_analyze("SELECT a FROM t")))
  expect_snapshot(print(sql_tokenize("SELECT 1")))
})

`%||%` <- function(x, y) if (is.null(x)) y else x
