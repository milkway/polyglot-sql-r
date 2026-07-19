# Conversion of R schema specifications into the JSON shape expected by the
# upstream `ValidationSchema` type.

#' Specify a table schema for schema-aware operations
#'
#' Several polyglotSQL functions ([sql_validate()], [sql_lineage()],
#' [sql_analyze()], [sql_optimize()], [sql_annotate_types()],
#' [sql_openlineage()]) accept an optional `schema` argument describing the
#' tables referenced by the query. A schema enables column qualification,
#' type inference, and existence checks.
#'
#' A schema is a named list with one entry per table. Each entry is either:
#'
#' * a *named* character vector mapping column names to SQL types, e.g.
#'   `c(id = "INT", name = "TEXT")`;
#' * an *unnamed* character vector of column names (types unknown), e.g.
#'   `c("id", "name")`.
#'
#' @param schema A schema specification (named list as described above), or
#'   `NULL` for no schema.
#' @return A JSON string in the upstream `ValidationSchema` format, or `""`
#'   when `schema` is `NULL`. Mostly used internally; exported for advanced
#'   users who want to inspect the generated payload.
#' @examples
#' as_polyglot_schema(list(
#'   orders = c(o_id = "INT", o_total = "DECIMAL(10,2)"),
#'   users = c("id", "name")
#' ))
#' @export
as_polyglot_schema <- function(schema) {
  if (is.null(schema)) {
    return("")
  }
  if (is.character(schema) && length(schema) == 1L && !is.na(schema) &&
      startsWith(trimws(schema), "{")) {
    # Already a JSON payload; pass through.
    return(schema)
  }
  if (!is.list(schema) || is.null(names(schema)) || any(!nzchar(names(schema)))) {
    stop_polyglot(
      "`schema` must be a named list with one entry per table.",
      class = "polyglot_argument_error"
    )
  }
  tables <- lapply(names(schema), function(table_name) {
    spec <- schema[[table_name]]
    if (!is.character(spec) || length(spec) == 0L || anyNA(spec)) {
      stop_polyglot(
        sprintf(
          "Schema entry for table '%s' must be a character vector of columns.",
          table_name
        ),
        class = "polyglot_argument_error"
      )
    }
    columns <- if (is.null(names(spec))) {
      lapply(unname(spec), function(col) list(name = col, type = ""))
    } else {
      if (any(!nzchar(names(spec)))) {
        stop_polyglot(
          sprintf(
            "Schema entry for table '%s' mixes named and unnamed columns.",
            table_name
          ),
          class = "polyglot_argument_error"
        )
      }
      mapply(
        function(col, type) list(name = col, type = type),
        names(spec), unname(spec),
        SIMPLIFY = FALSE, USE.NAMES = FALSE
      )
    }
    list(name = table_name, columns = columns)
  })
  as.character(jsonlite::toJSON(list(tables = tables), auto_unbox = TRUE))
}
