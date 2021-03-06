#' Factor/ordered factor S3 class
#'
#' A [factor] is an integer with attribute `levels`, a character vector. There
#' should be one level for each integer between 1 and `max(x)`.
#' An [ordered] factor has the same properties as a factor, but possesses
#' an extra class that marks levels as having a total ordering.
#'
#' These functions help the base factor and ordered factor classes fit in to
#' the vctrs type system by providing constructors, coercion functions,
#' and casting functions. `new_factor()` and `new_ordered()` are low-level
#' constructors - they only check that types, but not values, are valid, so
#' are for expert use only.
#'
#' @param x Integer values which index in to `levels`.
#' @param levels Character vector of labels.
#' @param ...,class Used to for subclasses.
#' @keywords internal
#' @export
new_factor <- function(x = integer(), levels = character(), ..., class = character()) {
  stopifnot(is.integer(x))
  stopifnot(is.character(levels))

  structure(
    x,
    levels = levels,
    ...,
    class = c(class, "factor")
  )
}

#' @export
#' @rdname new_factor
new_ordered <- function(x = integer(), levels = character()) {
  new_factor(x = x, levels = levels, class = "ordered")
}

#' @export
vec_proxy.factor <- function(x, ...) {
  x
}

#' @export
vec_proxy.ordered <- function(x, ...) {
  x
}

#' @export
vec_restore.factor <- function(x, to, ...) {
  NextMethod()
}

#' @export
vec_restore.ordered <- function(x, to, ...) {
  NextMethod()
}

# Print -------------------------------------------------------------------

#' @export
vec_ptype_full.factor <- function(x, ...) {
  paste0("factor<", hash_label(levels(x)), ">")
}

#' @export
vec_ptype_abbr.factor <- function(x, ...) {
  "fct"
}

#' @export
vec_ptype_full.ordered <- function(x, ...) {
  paste0("ordered<", hash_label(levels(x)), ">")
}

#' @export
vec_ptype_abbr.ordered <- function(x, ...) {
  "ord"
}

# Coerce ------------------------------------------------------------------

#' @rdname new_factor
#' @export vec_ptype2.factor
#' @method vec_ptype2 factor
#' @export
vec_ptype2.factor <- function(x, y, ...) UseMethod("vec_ptype2.factor")
#' @method vec_ptype2.character factor
#' @export
vec_ptype2.character.factor <- function(x, y, ...) character()
#' @method vec_ptype2.factor character
#' @export
vec_ptype2.factor.character <- function(x, y, ...) character()
#' @method vec_ptype2.factor factor
#' @export
vec_ptype2.factor.factor <- function(x, y, ...) new_factor(levels = levels_union(x, y))

#' @rdname new_factor
#' @export vec_ptype2.ordered
#' @method vec_ptype2 ordered
#' @export
vec_ptype2.ordered <- function(x, y, ...) UseMethod("vec_ptype2.ordered")
#' @method vec_ptype2.ordered character
#' @export
vec_ptype2.ordered.character <- function(x, y, ...) character()
#' @method vec_ptype2.character ordered
#' @export
vec_ptype2.character.ordered <- function(x, y, ...) character()
#' @method vec_ptype2.ordered factor
#' @export
vec_ptype2.ordered.factor <- function(x, y, ..., x_arg = "", y_arg = "") {
  stop_incompatible_type(x, y, x_arg = x_arg, y_arg = y_arg)
}
#' @method vec_ptype2.factor ordered
#' @export
vec_ptype2.factor.ordered <- function(x, y, ..., x_arg = "", y_arg = "") {
  stop_incompatible_type(x, y, x_arg = x_arg, y_arg = y_arg)
}
#' @method vec_ptype2.ordered ordered
#' @export
vec_ptype2.ordered.ordered <- function(x, y, ...) new_ordered(levels = levels_union(x, y))

# Cast --------------------------------------------------------------------

#' @rdname new_factor
#' @export vec_cast.factor
#' @method vec_cast factor
#' @export
vec_cast.factor <- function(x, to, ...) {
  UseMethod("vec_cast.factor")
}

fct_cast <- function(x, to, ..., x_arg = "", to_arg = "") {
  fct_cast_impl(x, to, ..., x_arg = x_arg, to_arg = to_arg, ordered = FALSE)
}

fct_cast_impl <- function(x, to, ..., x_arg = "", to_arg = "", ordered = FALSE) {
  if (length(levels(to)) == 0L) {
    levels <- levels(x)
    if (is.null(levels)) {
      exclude <- NA
      levels <- unique(x)
    } else {
      exclude <- NULL
    }
    factor(as.character(x), levels = levels, ordered = ordered, exclude = exclude)
  } else {
    lossy <- !(x %in% levels(to) | is.na(x))
    out <- factor(x, levels = levels(to), ordered = ordered, exclude = NULL)
    maybe_lossy_cast(out, x, to, lossy, x_arg = x_arg, to_arg = to_arg)
  }
}

#' @export
#' @method vec_cast.factor factor
vec_cast.factor.factor <- function(x, to, ...) {
  fct_cast(x, to, ...)
}
#' @export
#' @method vec_cast.factor ordered
vec_cast.factor.ordered <- function(x, to, ...) {
  fct_cast(x, to, ...)
}
#' @export
#' @method vec_cast.factor character
vec_cast.factor.character <-function(x, to, ...) {
  fct_cast(x, to, ...)
}
#' @export
#' @method vec_cast.character factor
vec_cast.character.factor <- function(x, to, ...) {
  stop_native_implementation("vec_cast.character.factor")
}

#' @rdname new_factor
#' @export vec_cast.ordered
#' @method vec_cast ordered
#' @export
vec_cast.ordered <- function(x, to, ...) {
  UseMethod("vec_cast.ordered")
}

ord_cast <- function(x, to, ..., x_arg = "", to_arg = "") {
  fct_cast_impl(x, to, ..., x_arg = x_arg, to_arg = to_arg, ordered = TRUE)
}

#' @export
#' @method vec_cast.ordered ordered
vec_cast.ordered.ordered <- function(x, to, ...) {
  ord_cast(x, to, ...)
}
#' @export
#' @method vec_cast.ordered factor
vec_cast.ordered.factor <- function(x, to, ...) {
  ord_cast(x, to, ...)
}
#' @export
#' @method vec_cast.ordered character
vec_cast.ordered.character <-function(x, to, ...) {
  ord_cast(x, to, ...)
}
#' @export
#' @method vec_cast.character ordered
vec_cast.character.ordered <- function(x, to, ...) {
  stop_native_implementation("vec_cast.character.ordered")
}

# Math and arithmetic -----------------------------------------------------

#' @export
vec_math.factor <- function(.fn, .x, ...) {
  stop_unsupported(.x, .fn)
}

#' @export
vec_arith.factor <- function(op, x, y, ...) {
  stop_unsupported(x, op)
}

# Helpers -----------------------------------------------------------------

hash_label <- function(x, length = 5) {
  if (length(x) == 0) {
    ""
  } else {
    # Can't use hash() currently because it hashes the string pointers
    # for performance, so the values in the test change each time
    substr(digest::digest(x), 1, length)
  }
}

levels_union <- function(x, y) {
  union(levels(x), levels(y))
}
