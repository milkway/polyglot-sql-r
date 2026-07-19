# Version and dialect discovery.

# Cached dialect registry (name, aliases, description), populated on first use.
the <- new.env(parent = emptyenv())

dialect_registry <- function() {
  if (is.null(the$dialects)) {
    value <- ffi_call(ffi_dialects)
    the$dialects <- list(
      name = vapply(value, function(d) d$name, character(1)),
      aliases = lapply(value, function(d) as.character(unlist(d$aliases))),
      description = vapply(value, function(d) d$description, character(1))
    )
  }
  the$dialects
}

#' Versions of polyglotSQL and its embedded Rust engine
#'
#' @return A named character vector with elements `polyglotSQL` (the R package
#'   version) and `polyglot_sql` (the version of the vendored
#'   [polyglot-sql](https://github.com/tobilg/polyglot) Rust crate the package
#'   was compiled against).
#' @examples
#' polyglot_version()
#' @export
polyglot_version <- function() {
  value <- ffi_call(ffi_version)
  c(
    polyglotSQL = as.character(utils::packageVersion("polyglotSQL")),
    polyglot_sql = value$polyglot_sql
  )
}

#' List supported SQL dialects
#'
#' @param full If `FALSE` (default), return a character vector of canonical
#'   dialect names. If `TRUE`, return a data frame with columns `name`,
#'   `aliases` (comma-separated accepted aliases) and `description`.
#' @return A character vector, or a data frame when `full = TRUE`.
#' @details Every function that takes a `dialect`, `from` or `to` argument
#'   accepts both the canonical names and the aliases (e.g. `"postgresql"`
#'   for `"postgres"`, `"mssql"` or `"sqlserver"` for `"tsql"`).
#' @examples
#' sql_dialects()
#' head(sql_dialects(full = TRUE))
#' @export
sql_dialects <- function(full = FALSE) {
  check_flag(full, "full")
  reg <- dialect_registry()
  if (!full) {
    return(reg$name)
  }
  data.frame(
    name = reg$name,
    aliases = vapply(reg$aliases, paste, character(1), collapse = ", "),
    description = reg$description,
    stringsAsFactors = FALSE
  )
}
