test_that("sql_source_tables discovers tables across joins and statements", {
  expect_identical(
    sql_source_tables("SELECT * FROM a JOIN b ON a.id = b.id"),
    c("a", "b")
  )
  expect_identical(
    sql_source_tables("SELECT 1 FROM x; DELETE FROM y"),
    c("x", "y")
  )
})

test_that("CTE names are not reported as source tables", {
  tables <- sql_source_tables(
    "WITH cte AS (SELECT id FROM base) SELECT * FROM cte JOIN other USING (id)"
  )
  expect_true("base" %in% tables)
  expect_true("other" %in% tables)
  expect_false("cte" %in% tables)
})

test_that("simple lineage traces a computed column to its table", {
  lin <- sql_lineage("SELECT a + b AS total FROM t")
  expect_s3_class(lin, "polyglot_lineage")
  expect_length(lin$columns, 1)
  col <- lin$columns[[1]]
  expect_identical(col$column, "total")
  expect_true("t" %in% unlist(col$sources))
  expect_type(col$tree, "list")
  expect_true(all(c("name", "source_kind", "downstream") %in% names(col$tree)))
})

test_that("lineage follows CTEs to the underlying tables", {
  lin <- sql_lineage(
    "WITH base AS (SELECT id, amount FROM payments)
     SELECT id, amount * 2 AS doubled FROM base"
  )
  expect_length(lin$columns, 2)
  cols <- vapply(lin$columns, function(c) c$column, character(1))
  expect_setequal(cols, c("id", "doubled"))
  doubled <- lin$columns[[which(cols == "doubled")]]
  expect_true("payments" %in% unlist(doubled$sources))
})

test_that("lineage accepts an explicit column and a schema", {
  lin <- sql_lineage(
    "SELECT id, name FROM users",
    schema = list(users = c(id = "INT", name = "TEXT")),
    column = "name"
  )
  expect_length(lin$columns, 1)
  expect_identical(lin$columns[[1]]$column, "name")
  expect_true("users" %in% unlist(lin$columns[[1]]$sources))
})
