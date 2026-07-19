test_that("sql_parse returns a structured AST", {
  ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
  expect_s3_class(ast, "polyglot_ast")
  expect_length(ast$statements, 1)
  stmt <- ast$statements[[1]]
  expect_type(stmt, "list")
  expect_identical(names(stmt)[[1]], "select")
  expect_identical(ast$dialect, "generic")
})

test_that("sql_parse handles multiple statements", {
  ast <- sql_parse("SELECT 1; SELECT 2")
  expect_length(ast$statements, 2)
})

test_that("parse -> generate round-trips", {
  ast <- sql_parse("SELECT IFNULL(a, b) FROM t", dialect = "mysql")
  expect_identical(
    sql_generate(ast, dialect = "mysql"),
    "SELECT IFNULL(a, b) FROM t"
  )
  # generation applies target-dialect syntax (quoting), not function rewrites
  ast2 <- sql_parse("SELECT `col name` FROM t", dialect = "mysql")
  out <- sql_generate(ast2, dialect = "postgres")
  expect_false(grepl("`", out, fixed = TRUE))
  expect_match(out, "\"col name\"", fixed = TRUE)
})

test_that("sql_tokenize returns a token data frame", {
  tokens <- sql_tokenize("SELECT a FROM t")
  expect_s3_class(tokens, "data.frame")
  expect_named(tokens, c("type", "text", "line", "column", "start", "end"))
  expect_true("Select" %in% tokens$type)
  expect_true("a" %in% tokens$text)
  expect_true(all(tokens$end >= tokens$start))
  expect_true(all(tokens$line >= 1L))
})

test_that("tokenizer respects dialect quoting rules", {
  tokens <- sql_tokenize("SELECT `weird name` FROM t", dialect = "mysql")
  expect_true(any(grepl("weird name", tokens$text, fixed = TRUE)))
})

test_that("Unicode SQL survives parse, tokenize, transpile and format", {
  sql <- "SELECT nome, cidade FROM funcionários WHERE país = 'Brasil' AND emoji = '🎉'"
  ast <- sql_parse(sql)
  expect_length(ast$statements, 1)

  tokens <- sql_tokenize(sql)
  expect_true(any(grepl("funcionários", tokens$text, fixed = TRUE)))
  expect_true(any(grepl("🎉", tokens$text, fixed = TRUE)))

  out <- sql_transpile(sql, from = "generic", to = "postgres")
  expect_match(out, "funcionários", fixed = TRUE)
  expect_match(out, "🎉", fixed = TRUE)

  expect_match(paste(sql_format(sql), collapse = "\n"), "país", fixed = TRUE)
})
