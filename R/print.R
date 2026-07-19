# Compact print methods for polyglotSQL S3 classes.

#' @export
print.polyglot_ast <- function(x, ...) {
  n <- length(x$statements)
  kinds <- vapply(
    x$statements,
    function(s) if (is.list(s) && length(names(s))) names(s)[[1]] else "?",
    character(1)
  )
  cli::cli_text("{.cls polyglot_ast} {n} statement{?s} ({x$dialect})")
  for (i in seq_len(n)) {
    cli::cli_text("  [{i}] {.strong {kinds[[i]]}}")
  }
  invisible(x)
}

#' @export
print.polyglot_tokens <- function(x, ...) {
  cli::cli_text("{.cls polyglot_tokens} {nrow(x)} token{?s}")
  print.data.frame(x, ...)
  invisible(x)
}

#' @export
print.polyglot_validation <- function(x, ...) {
  status <- if (x$valid) {
    cli::col_green("valid")
  } else {
    cli::col_red("invalid")
  }
  cli::cli_text("{.cls polyglot_validation} {status} ({x$dialect})")
  if (nrow(x$errors)) {
    for (i in seq_len(nrow(x$errors))) {
      e <- x$errors[i, ]
      loc <- if (!is.na(e$line)) sprintf(" at %d:%d", e$line, e$column) else ""
      tag <- if (identical(e$severity, "warning")) {
        cli::col_yellow(paste0("[", e$code, "]"))
      } else {
        cli::col_red(paste0("[", e$code, "]"))
      }
      cli::cli_text("  {tag} {e$message}{loc}")
    }
  }
  invisible(x)
}

#' @export
print.polyglot_lineage <- function(x, ...) {
  n <- length(x$columns)
  cli::cli_text("{.cls polyglot_lineage} {n} column{?s} ({x$dialect})")
  for (col in x$columns) {
    sources <- unlist(col$sources)
    src <- if (length(sources)) paste(sources, collapse = ", ") else "(no source table)"
    cli::cli_text("  {.strong {col$column}} \u2190 {src}")
  }
  invisible(x)
}

#' @export
print.polyglot_analysis <- function(x, ...) {
  cli::cli_text("{.cls polyglot_analysis} shape: {.strong {x$shape}} ({x$dialect})")
  projections <- vapply(
    x$projections,
    function(p) p$name %||% "(unnamed)",
    character(1)
  )
  relations <- vapply(
    x$relations,
    function(r) r$name %||% "(unnamed)",
    character(1)
  )
  ctes <- unlist(x$ctes)
  if (length(projections)) {
    cli::cli_text("  projections: {paste(projections, collapse = ', ')}")
  }
  if (length(relations)) {
    cli::cli_text("  relations: {paste(relations, collapse = ', ')}")
  }
  if (length(ctes)) {
    cli::cli_text("  ctes: {paste(ctes, collapse = ', ')}")
  }
  invisible(x)
}
