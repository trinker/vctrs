#' Data frame class
#'
#' A `data.frame` [data.frame()] is a list with "row.names" attribute. Each
#' element of the list must be named, and of the same length. These functions
#' help the base data.frame classes fit in to the vctrs type system by
#' providing constructors, coercion functions, and casting functions.
#'
#' @param x A named list of equal-length vectors. The lengths are not
#'   checked; it is responsibility of the caller to make sure they are
#'   equal.
#' @param n Number of rows. If `NULL`, will be computed from the length of
#'   the first element of `x`.
#' @param ...,class Additional arguments for creating subclasses.
#'   The `"names"` and `"row.names"` attributes override input in `x` and `n`,
#'   respectively:
#'
#'   - `"names"` is used if provided, overriding existing names in `x`
#'   - `"row.names"` is used if provided, if `n` is provided it must be
#'     consistent.
#'
#' @export
#' @keywords internal
#' @examples
#' new_data_frame(list(x = 1:10, y = 10:1))
new_data_frame <- function(x = list(), n = NULL, ..., class = NULL) {
  .External(vctrs_new_data_frame, x, n, class, ...)
}
new_data_frame <- fn_inline_formals(new_data_frame, "x")


# Light weight constructor used for tests - avoids having to repeatedly do
# stringsAsFactors = FALSE etc. Should not be used in internal code as is
# not a real helper as it lacks value checks.
data_frame <- function(...) {
  cols <- list(...)
  new_data_frame(cols)
}

#' @export
vec_ptype_full.data.frame <- function(x, ...) {
  if (length(x) == 0) {
    return(paste0(class(x)[[1]], "<>"))
  } else if (length(x) == 1) {
    return(paste0(class(x)[[1]], "<", names(x), ":", vec_ptype_full(x[[1]]), ">"))
  }

  # Needs to handle recursion with indenting
  types <- map_chr(x, vec_ptype_full)
  needs_indent <- grepl("\n", types)
  types[needs_indent] <- map(types[needs_indent], function(x) indent(paste0("\n", x), 4))

  names <- paste0("  ", format(names(x)))

  paste0(
    class(x)[[1]], "<\n",
    paste0(names, ": ", types, collapse = "\n"),
    "\n>"
  )
}

#' @export
vec_ptype_abbr.data.frame <- function(x, ...) {
  paste0("df", vec_ptype_shape(x))
}

#' @export
vec_proxy_compare.data.frame <- function(x, ..., relax = FALSE) {
  out <- lapply(as.list(x), vec_proxy_compare, relax = TRUE)
  new_data_frame(out, nrow(x))
}


# Coercion ----------------------------------------------------------------

#' @rdname new_data_frame
#' @export vec_ptype2.data.frame
#' @method vec_ptype2 data.frame
#' @export
vec_ptype2.data.frame <- function(x, y, ...) {
  UseMethod("vec_ptype2.data.frame")
}
#' @method vec_ptype2.data.frame data.frame
#' @export
vec_ptype2.data.frame.data.frame <- function(x, y, ...) {
  df_ptype2(x, y, ...)
}
# Returns a `data.frame` no matter the input classes
df_ptype2 <- function(x, y, ..., x_arg = "", y_arg = "") {
  .Call(vctrs_df_ptype2, x, y, x_arg, y_arg)
}

# Fallback for data frame subclasses (#981)
vec_ptype2_df_fallback <- function(x, y, x_arg = "", y_arg = "") {
  ptype <- vec_ptype2(
    new_data_frame(x),
    new_data_frame(y)
  )

  classes <- NULL
  if (is_df_fallback(x)) {
    classes <- c(classes, known_classes(x))
    x_class <- "data.frame"
    x_abbr <- "df"
  } else {
    x_class <- class(x)[[1]]
    x_abbr <- class(x)[[1]]
  }
  if (is_df_fallback(y)) {
    classes <- c(classes, known_classes(y))
    y_class <- "data.frame"
    y_abbr <- "df"
  } else {
    y_class <- class(y)[[1]]
    y_abbr <- class(y)[[1]]
  }

  if (!all(c(x_class, y_class) %in% classes)) {
    msg <- cnd_type_message(x, y, x_arg, y_arg, NULL, "combine", NULL, types = c(x_abbr, y_abbr))
    warn(c(
      msg,
      i = "Convert all inputs to the same class to avoid this warning.",
      i = "Falling back to <data.frame>."
    ))
  }

  # Return a fallback class so we don't warn multiple times. This
  # fallback class is stripped in `vec_ptype_finalise()`.
  new_fallback_df(
    ptype,
    known_classes = unique(c(classes, x_class, y_class))
  )
}

is_df_subclass <- function(x) {
  inherits(x, "data.frame") && !identical(class(x), "data.frame")
}
is_df_fallback <- function(x) {
  inherits(x, "vctrs:::df_fallback")
}
new_fallback_df <- function(x, known_classes, n = nrow(x)) {
  new_data_frame(
    x,
    n = n,
    known_classes = known_classes,
    class = "vctrs:::df_fallback"
  )
}

known_classes <- function(x) {
  if (is_df_fallback(x)) {
    attr(x, "known_classes")
  }
}


# Cast --------------------------------------------------------------------

#' @rdname new_data_frame
#' @export vec_cast.data.frame
#' @method vec_cast data.frame
#' @export
vec_cast.data.frame <- function(x, to, ...) {
  UseMethod("vec_cast.data.frame")
}
#' @export
#' @method vec_cast.data.frame data.frame
vec_cast.data.frame.data.frame <- function(x, to, ..., x_arg = "", to_arg = "") {
  df_cast(x, to, x_arg = x_arg, to_arg = to_arg)
}
df_cast <- function(x, to, ..., x_arg = "", to_arg = "") {
  .Call(vctrs_df_cast, x, to, x_arg, to_arg)
}

#' @export
vec_restore.data.frame <- function(x, to, ..., n = NULL) {
  .Call(vctrs_bare_df_restore, x, to, n)
}

# Helpers -----------------------------------------------------------------

df_size <- function(x) {
  .Call(vctrs_df_size, x)
}

df_lossy_cast <- function(out, x, to) {
  extra <- setdiff(names(x), names(to))

  maybe_lossy_cast(
    result = out,
    x = x,
    to = to,
    lossy = length(extra) > 0,
    locations = int(),
    details = inline_list("Dropped variables: ", extra, quote = "`"),
    class = "vctrs_error_cast_lossy_dropped"
  )
}
