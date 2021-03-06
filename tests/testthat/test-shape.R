context("test-shape")

int <- function(...) {
  array(NA_integer_, c(...))
}

# common shape ------------------------------------------------------------

test_that("recycling rules applied", {
  expect_equal(vec_shape2(int(1, 5, 5), int(1)),       c(0L, 5L, 5L))
  expect_equal(vec_shape2(int(1),       int(1, 5, 5)), c(0L, 5L, 5L))
  expect_equal(vec_shape2(int(1, 1),    int(1, 5, 5)), c(0L, 5L, 5L))
  expect_equal(vec_shape2(int(1, 1, 1), int(1, 5, 5)), c(0L, 5L, 5L))

  expect_equal(vec_shape2(int(1, 1, 5), int(1, 5, 1)), c(0L, 5L, 5L))
  expect_equal(vec_shape2(int(1, 5, 1), int(1, 1, 5)), c(0L, 5L, 5L))
  expect_equal(vec_shape2(int(1, 1, 1), int(1, 5, 5)), c(0L, 5L, 5L))

  expect_equal(vec_shape2(int(1, 0, 5), int(1, 1, 1)), c(0L, 0L, 5L))
})

test_that("incompatible shapes throw errors", {
  verify_errors({
    expect_error(vec_shape2(int(1, 0, 5), int(1, 5, 1)), class = "vctrs_error_incompatible_type")
    expect_error(vec_shape2(int(1, 5, 0), int(1, 1, 5)), class = "vctrs_error_incompatible_type")
  })
})

test_that("can override error args", {
  verify_errors({
    expect_error(
      vec_shape2(int(1, 0, 5), int(1, 5, 1), x_arg = "foo", y_arg = "bar"),
      class = "vctrs_error_incompatible_type"
    )
  })
})

# broadcasting -------------------------------------------------------------

test_that("can broadcast to higher dimension, but not lower", {
  expect_identical(shape_broadcast(1, NULL), 1)
  expect_null(shape_broadcast(NULL, 1))

  expect_equal(
    shape_broadcast(1, int(0, 4)),
    array(1, c(1, 4))
  )
  expect_error(
    shape_broadcast(int(1, 1, 1), int(4, 4)),
    class = "vctrs_error_incompatible_type"
  )
  expect_error(
    shape_broadcast(int(3, 2), int(3, 3)),
    class = "vctrs_error_incompatible_type"
  )
})

test_that("recycling rules applied", {
  expect_equal(
    shape_broadcast(array(1:4, c(1, 1, 4)), int(0, 4, 4))[1, , ],
    matrix(1:4, 4, 4, byrow = TRUE)
  )

  expect_equal(
    shape_broadcast(array(1:4, c(1, 4, 1)), int(0, 4, 4))[1, , ],
    matrix(1:4, 4, 4)
  )

  expect_equal(
    shape_broadcast(array(1L, c(1, 1)), int(1, 0)),
    matrix(integer(), nrow = 1)
  )

  expect_error(
    shape_broadcast(array(1L, c(1, 2)), int(1, 0)),
    "Non-recyclable dimensions",
    class = "vctrs_error_incompatible_type"
  )

  expect_error(
    shape_broadcast(array(1L, c(1, 0)), int(1, 1)),
    "Non-recyclable dimensions",
    class = "vctrs_error_incompatible_type"
  )
})

# --------------------------------------------------------------------------

test_that("shape errors have informative output", {
  verify_output(test_path("error", "test-shape.txt"), {
    "# incompatible shapes throw errors"
    vec_shape2(int(1, 0, 5), int(1, 5, 1))
    vec_shape2(int(1, 5, 0), int(1, 1, 5))

    "# can override error args"
    vec_shape2(int(1, 0, 5), int(1, 5, 1), x_arg = "foo", y_arg = "bar")
  })
})
