# Parsing, tokenization and validation.

#' Parse SQL into an abstract syntax tree
#'
#' @inheritParams sql_transpile
#' @param dialect Dialect used for parsing.
#' @return A `polyglot_ast` object: a list with elements
#'   * `statements` — a list with one nested-list AST per statement;
#'   * `sql` — the input SQL;
#'   * `dialect` — the dialect used.
#'
#'   Each AST node is a named list; the name of the outer element gives the
#'   node kind (e.g. `"select"`). The structure follows the upstream
#'   `polyglot-sql` JSON AST format and round-trips through [sql_generate()].
#' @examples
#' ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
#' ast
#' names(ast$statements[[1]])
#' @export
sql_parse <- function(sql, dialect = "generic") {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(ffi_parse, sql, dialect, context = "parse")
  structure(
    list(statements = value, sql = sql, dialect = dialect),
    class = "polyglot_ast"
  )
}

#' Tokenize SQL
#'
#' Splits SQL into lexical tokens using the tokenizer of the given dialect.
#'
#' @inheritParams sql_parse
#' @return A data frame with class `polyglot_tokens` and one row per token:
#'   `type` (token type, e.g. `"Select"`, `"Identifier"`, `"Number"`),
#'   `text` (raw token text), `line` and `column` (1-based position),
#'   `start` and `end` (byte offsets, end exclusive).
#' @examples
#' sql_tokenize("SELECT a FROM t")
#' @export
sql_tokenize <- function(sql, dialect = "generic") {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(ffi_tokenize, sql, dialect, context = "parse", simplify = TRUE)
  out <- data.frame(
    type = as.character(value$type),
    text = as.character(value$text),
    line = as.integer(value$line),
    column = as.integer(value$column),
    start = as.integer(value$start),
    end = as.integer(value$end),
    stringsAsFactors = FALSE
  )
  class(out) <- c("polyglot_tokens", "data.frame")
  out
}

#' Validate SQL
#'
#' Checks that SQL parses in the given dialect and, optionally, applies
#' stricter syntax rules, semantic lint warnings, and schema-aware checks.
#'
#' @inheritParams sql_parse
#' @param ... Additional validation options:
#'   * `strict_syntax` — reject non-canonical syntax the parser would accept
#'     for compatibility (e.g. trailing commas before `FROM`); default `FALSE`.
#'   * `semantic` — report query-quality warnings (`W001`–`W004`, e.g.
#'     `SELECT *` mixed with explicit columns); default `FALSE`.
#'   * `schema` — a schema specification (see [as_polyglot_schema()]);
#'     enables unknown-table/column, type and reference checks.
#'   * `error` — if `TRUE`, raise a `polyglot_validation_error` instead of
#'     returning an invalid result; default `FALSE`.
#' @return A `polyglot_validation` object: a list with `valid` (logical) and
#'   `errors` (data frame with columns `severity`, `code`, `message`, `line`,
#'   `column`).
#' @examples
#' sql_validate("SELECT a FROM t")
#' sql_validate("SELECT FROM WHERE")
#' v <- sql_validate("SELECT a, FROM t", strict_syntax = TRUE)
#' v$valid
#' @export
sql_validate <- function(sql, dialect = "generic", ...) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  opts <- list(...)
  allowed <- c("strict_syntax", "semantic", "schema", "error")
  unknown <- setdiff(names(opts), allowed)
  if (length(unknown) || (length(opts) && is.null(names(opts)))) {
    stop_polyglot(
      sprintf(
        "Unknown validation option(s): %s. Supported: %s.",
        paste(sQuote(if (length(unknown)) unknown else "<unnamed>"), collapse = ", "),
        paste(allowed, collapse = ", ")
      ),
      class = "polyglot_argument_error"
    )
  }
  strict_syntax <- check_flag(opts$strict_syntax %||% FALSE, "strict_syntax")
  semantic <- check_flag(opts$semantic %||% FALSE, "semantic")
  error <- check_flag(opts$error %||% FALSE, "error")
  schema_json <- as_polyglot_schema(opts$schema)

  value <- ffi_call(
    ffi_validate, sql, dialect, strict_syntax, semantic, schema_json,
    context = "validate"
  )

  errors <- value$errors %||% list()
  errors_df <- data.frame(
    severity = vapply(errors, function(e) tolower(e$severity %||% "error"), character(1)),
    code = vapply(errors, function(e) e$code %||% "", character(1)),
    message = vapply(errors, function(e) e$message %||% "", character(1)),
    line = vapply(errors, function(e) as.integer(e$line %||% NA_integer_), integer(1)),
    column = vapply(errors, function(e) as.integer(e$column %||% NA_integer_), integer(1)),
    stringsAsFactors = FALSE
  )
  result <- structure(
    list(valid = isTRUE(value$valid), errors = errors_df, sql = sql, dialect = dialect),
    class = "polyglot_validation"
  )
  if (error && !result$valid) {
    stop_polyglot(
      sprintf(
        "Invalid SQL (%s): %s",
        dialect,
        paste(sprintf("[%s] %s", errors_df$code, errors_df$message), collapse = "; ")
      ),
      class = "polyglot_validation_error",
      data = list(result = result)
    )
  }
  result
}
