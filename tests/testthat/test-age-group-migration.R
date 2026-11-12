legacy_interval <- function() {
  readRDS(test_path("fixtures", "age-class-naming", "baseline.rds"))$intervals
}

test_that("phase-two assignments match the committed phase-one results", {
  old <- readRDS(test_path("fixtures", "age-class-naming", "phase1.rds"))
  x <- categorize_age(old$ages, by = old$scheme)
  expect_identical(class(x), c("age_group", "ordered", "factor"))
  expect_true(is_age_group(x))
  expect_false(is_age_interval(x))
  expect_identical(as.character(x), old$labels)
  expect_identical(as.integer(x), old$codes)
  expect_identical(levels(x), old$levels)
  expect_identical(names(x), old$names)
  expect_identical(attr(x, "units"), old$units)
  expect_identical(group_intervals(x), old$intervals)
  expect_identical(categorize_age(old$ages, by = old$scheme, output = "interval"), old$matched)
  expect_identical(classify_age_scheme(old$ages, old$scheme), old$memberships)
  expect_identical(group_intervals(x[0]), old$intervals)
  expect_identical(group_intervals(droplevels(x)), old$intervals[1:3])
  expect_identical(as.character(c(x, x)), rep(old$labels, 2))
  expect_identical(as.character(vctrs::vec_c(x, x)), rep(old$labels, 2))
  # Unclass only for comparison: production objects must use constructors.
  expected <- old$assignments
  attr(expected, "class") <- c("age_group", "ordered", "factor")
  expect_identical(x, expected)
  expected_exports <- sort(sub("category_intervals", "group_intervals",
    gsub("age_category", "age_group", old$exports, fixed = TRUE), fixed = TRUE))
  expect_identical(sort(getNamespaceExports("agecraft")), expected_exports)
})

test_that("legacy interval records are not identified as assignments", {
  old <- legacy_interval()
  g <- age_interval(0, 5)
  x <- age_group("0-4", g)
  expect_false(is_age_group(old))
  expect_false(is_age_group(g))
  expect_false(is_age_group(factor("0-4", ordered = TRUE)))
  expect_true(is_age_group(x))
  expect_true(is_age_group(x[0]))
  expect_true(is_age_group(x[NA_integer_]))
  expect_false(is_age_interval(old))
  expect_identical(class(g), c("age_interval", "ivs_iv", "vctrs_rcrd", "vctrs_vctr"))
})

test_that("factor operations reject old intervals with migration guidance", {
  old <- legacy_interval()
  original <- serialize(old, NULL)
  x <- age_group("0-4", age_interval(0, 5))
  operations <- list(
    print = function() print(old),
    format = function() format(old),
    character = function() as.character(old),
    integer = function() as.integer(old),
    factor = function() generics::as.factor(old),
    ordered = function() generics::as.ordered(old),
    constructor = function() age_group(old, age_interval(0, 5)),
    definitions = function() group_intervals(old),
    subset = function() old[1],
    element = function() old[[1]],
    repetition = function() rep(old, 0),
    empty_subset = function() old[FALSE],
    drop = function() droplevels(old),
    concatenate = function() c(old, old),
    mixed_concatenate = function() c(x, old),
    comparison_left = function() old == x,
    comparison_right = function() x == old,
    proxy = function() vctrs::vec_proxy(old),
    ptype = function() vctrs::vec_ptype2(old, x),
    reverse_ptype = function() vctrs::vec_ptype2(x, old),
    cast = function() vctrs::vec_cast(old, x),
    reverse_cast = function() vctrs::vec_cast(x, old),
    mixed_factor = function() vctrs::vec_ptype2(old, factor("a")),
    type_full = function() vctrs::vec_ptype_full(old),
    type_abbr = function() vctrs::vec_ptype_abbr(old),
    reorder = function() stats::reorder(old, 1:3),
    relevel = function() stats::relevel(old, "a"),
    replace = function() { y <- old; y[1] <- "0-4" },
    replace_element = function() { y <- old; y[[1]] <- "0-4" },
    replace_levels = function() { y <- old; levels(y) <- c("a", "b", "c") }
  )
  for (op in names(operations)) {
    expect_error(operations[[op]](), "Legacy age_group interval object: rebuild it with age_interval", info = op)
  }
  expect_identical(serialize(old, NULL), original)
})

test_that("guarded coercion and formatting preserve ordinary factor results", {
  x <- age_group(c(first = "5+", second = NA, third = "0-4"),
                 age_interval(c(0, 5), c(5, Inf)))
  ordinary <- generics::as.ordered(x)
  expect_identical(as.character(x), as.character(ordinary))
  expect_identical(as.integer(x), as.integer(ordinary))
  expect_identical(format(x), format(ordinary))
  expect_identical(format(x, justify = "right"), format(ordinary, justify = "right"))
  expect_identical(group_intervals(vctrs::vec_slice(x, 2:1)), group_intervals(x))
  bound <- vctrs::vec_rbind(data.frame(x = x), data.frame(x = x))$x
  expect_identical(as.character(bound), rep(as.character(x), 2))
  expect_identical(ivs::iv_start(group_intervals(bound)), ivs::iv_start(group_intervals(x)))
  expect_identical(ivs::iv_end(group_intervals(bound)), ivs::iv_end(group_intervals(x)))
  expect_identical(names(group_intervals(bound)), levels(x))
})
