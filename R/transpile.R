# Transpilation, formatting and SQL generation.

#' Translate SQL between dialects
#'
#' Parses `sql` with the `from` dialect and regenerates it in the `to`
#' dialect, rewriting functions, quoting, and constructs as needed
#' (e.g. MySQL `IFNULL()` becomes PostgreSQL `COALESCE()`).
#'
#' @param sql A single character string with one or more SQL statements
#'   (separated by `;`).
#' @param from Source dialect name (see [sql_dialects()]).
#' @param to Target dialect name (see [sql_dialects()]).
#' @param pretty If `TRUE`, pretty-print the output.
#' @param unsupported How to handle constructs that cannot be represented in
#'   the target dialect: `"raise"` (default) throws a
#'   `polyglot_transpile_error`; `"warn"` and `"ignore"` continue and return
#'   the closest supported translation (with `"warn"`, upstream collects
#'   diagnostics but still returns a result).
#' @return A character vector with one element per input statement.
#' @section Semantic limitations:
#' Transpilation is syntactic and best-effort: identical syntax can still
#' behave differently across engines (implicit casts, collations, `NULL`
#' ordering, integer division, time zone handling...). Always test the
#' translated SQL against the target database before using it in production.
#' @examples
#' sql_transpile("SELECT IFNULL(a, b) FROM t", from = "mysql", to = "postgres")
#' sql_transpile(
#'   "SELECT DATE_TRUNC('month', created_at) FROM events",
#'   from = "postgres", to = "duckdb"
#' )
#' @seealso [sql_format()], [sql_parse()], [sql_validate()]
#' @export
sql_transpile <- function(sql, from, to, pretty = FALSE,
                          unsupported = c("raise", "warn", "ignore")) {
  check_sql(sql)
  from <- check_dialect(from, "from")
  to <- check_dialect(to, "to")
  check_flag(pretty, "pretty")
  choices <- c("raise", "warn", "ignore")
  if (identical(unsupported, choices)) {
    unsupported <- "raise"
  }
  if (!is.character(unsupported) || length(unsupported) != 1L ||
      !unsupported %in% choices) {
    stop_polyglot(
      "`unsupported` must be one of \"raise\", \"warn\" or \"ignore\".",
      class = "polyglot_argument_error"
    )
  }
  value <- ffi_call(
    ffi_transpile, sql, from, to, pretty, unsupported,
    context = "transpile", simplify = TRUE
  )
  as.character(value)
}

#' Format (pretty-print) SQL
#'
#' Parses and re-renders SQL as canonically indented statements. Complexity
#' guards protect against pathological inputs; exceeding a guard raises a
#' `polyglot_guard_error`.
#'
#' @inheritParams sql_transpile
#' @param dialect Dialect used for parsing and rendering.
#' @param max_input_bytes,max_tokens,max_ast_nodes,max_set_op_chain Complexity
#'   guard limits. `NULL` (default) uses the upstream defaults (16 MiB input,
#'   1e6 tokens, 1e6 AST nodes, 256 chained set operations); `Inf` disables a
#'   guard; a positive number sets an explicit limit.
#' @return A character vector with one formatted statement per input statement.
#' @examples
#' cat(sql_format("select a,b from t where x=1 and y=2"))
#' @export
sql_format <- function(sql, dialect = "generic", max_input_bytes = NULL,
                       max_tokens = NULL, max_ast_nodes = NULL,
                       max_set_op_chain = NULL) {
  check_sql(sql)
  dialect <- check_dialect(dialect)
  value <- ffi_call(
    ffi_format, sql, dialect,
    check_guard_limit(max_input_bytes, "max_input_bytes"),
    check_guard_limit(max_tokens, "max_tokens"),
    check_guard_limit(max_ast_nodes, "max_ast_nodes"),
    check_guard_limit(max_set_op_chain, "max_set_op_chain"),
    context = "format", simplify = TRUE
  )
  as.character(value)
}

#' Generate SQL from a parsed AST
#'
#' Renders a [sql_parse()] result back into SQL text using the target
#' dialect's syntax rules (keywords, quoting, literals). Note this is plain
#' *generation*: unlike [sql_transpile()], it does not apply cross-dialect
#' function rewrites (e.g. `IFNULL` is not converted to `COALESCE`). Use it
#' to render programmatically-built or modified ASTs; use [sql_transpile()]
#' for full dialect translation.
#'
#' @param ast A `polyglot_ast` object from [sql_parse()] (or
#'   [sql_annotate_types()]).
#' @param dialect Target dialect for rendering.
#' @return A character vector with one element per statement in the AST.
#' @examples
#' ast <- sql_parse("SELECT a, b FROM t WHERE x = 1")
#' sql_generate(ast, dialect = "postgres")
#' @export
sql_generate <- function(ast, dialect = "generic") {
  if (!inherits(ast, "polyglot_ast")) {
    stop_polyglot(
      "`ast` must be a 'polyglot_ast' object created by sql_parse().",
      class = "polyglot_argument_error"
    )
  }
  dialect <- check_dialect(dialect)
  ast_json <- as.character(
    jsonlite::toJSON(ast$statements, auto_unbox = TRUE, digits = NA, null = "null")
  )
  value <- ffi_call(
    ffi_generate, ast_json, dialect,
    context = "generate", simplify = TRUE
  )
  as.character(value)
}
