# Internal plumbing between the public R API and the Rust FFI layer.
#
# Every Rust function returns a JSON envelope:
#   {"ok": true,  "value": <payload>}
#   {"ok": false, "error": {"kind": "...", "message": "...", ...}}
# This file parses envelopes and raises classed R conditions on failure.

# Raise a classed polyglot condition. `class` is prepended to the base
# "polyglot_error" class so callers can use tryCatch(..., polyglot_parse_error = ...).
stop_polyglot <- function(message, class = character(), data = list(),
                          call = sys.call(-1)) {
  cond <- structure(
    class = c(class, "polyglot_error", "error", "condition"),
    c(list(message = message, call = call), data)
  )
  stop(cond)
}

# Map an FFI error object to condition classes, given the calling context.
ffi_error_class <- function(kind, context) {
  switch(kind,
    tokenize = ,
    parse = ,
    syntax = "polyglot_parse_error",
    unsupported = ,
    generate = if (identical(context, "transpile")) {
      "polyglot_transpile_error"
    } else {
      "polyglot_generate_error"
    },
    guard = "polyglot_guard_error",
    unknown_dialect = "polyglot_dialect_error",
    bad_argument = "polyglot_argument_error",
    character()
  )
}

format_ffi_error <- function(err) {
  msg <- err$message %||% "unknown error"
  if (!is.null(err$line) && !is.null(err$column) && err$line > 0) {
    msg <- sprintf("%s (line %d, column %d)", msg, err$line, err$column)
  }
  msg
}

# Call a Rust FFI function and unwrap its JSON envelope.
# `simplify` controls jsonlite simplification of the value payload.
ffi_call <- function(fun, ..., context = "polyglot", simplify = FALSE) {
  raw <- fun(...)
  env <- jsonlite::fromJSON(raw, simplifyVector = simplify,
                            simplifyDataFrame = FALSE, simplifyMatrix = FALSE)
  if (isTRUE(env$ok)) {
    return(env$value)
  }
  err <- env$error
  stop_polyglot(
    format_ffi_error(err),
    class = ffi_error_class(err$kind %||% "", context),
    data = list(
      kind = err$kind,
      line = err$line,
      column = err$column,
      start = err$start,
      end = err$end
    ),
    call = sys.call(-1)
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# --- Argument validation ----------------------------------------------------

check_sql <- function(sql, arg = "sql") {
  if (!is.character(sql) || length(sql) != 1L || is.na(sql)) {
    stop_polyglot(
      sprintf("`%s` must be a single non-NA character string.", arg),
      class = "polyglot_argument_error"
    )
  }
  if (!nzchar(trimws(sql))) {
    stop_polyglot(
      sprintf("`%s` must be a non-empty SQL string.", arg),
      class = "polyglot_argument_error"
    )
  }
  invisible(sql)
}

check_dialect <- function(dialect, arg = "dialect") {
  if (!is.character(dialect) || length(dialect) != 1L || is.na(dialect) ||
      !nzchar(dialect)) {
    stop_polyglot(
      sprintf("`%s` must be a single non-empty character string.", arg),
      class = "polyglot_argument_error"
    )
  }
  dialect <- tolower(trimws(dialect))
  known <- dialect_registry()
  all_names <- c(known$name, unlist(known$aliases, use.names = FALSE))
  if (!dialect %in% all_names) {
    suggestion <- agrep(dialect, all_names, max.distance = 2L, value = TRUE)
    hint <- if (length(suggestion)) {
      sprintf(" Did you mean %s?", paste(sQuote(utils::head(suggestion, 3L)), collapse = ", "))
    } else {
      ""
    }
    stop_polyglot(
      sprintf(
        "Unknown SQL dialect: '%s'.%s See sql_dialects() for supported dialects.",
        dialect, hint
      ),
      class = "polyglot_dialect_error"
    )
  }
  dialect
}

check_flag <- function(x, arg) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    stop_polyglot(
      sprintf("`%s` must be TRUE or FALSE.", arg),
      class = "polyglot_argument_error"
    )
  }
  x
}

# Guard limits: NULL => upstream default (-1), Inf => disabled (0),
# positive number => that limit.
check_guard_limit <- function(x, arg) {
  if (is.null(x)) {
    return(-1)
  }
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 0) {
    stop_polyglot(
      sprintf("`%s` must be NULL, Inf, or a single positive number.", arg),
      class = "polyglot_argument_error"
    )
  }
  if (is.infinite(x)) {
    return(0)
  }
  as.double(x)
}
