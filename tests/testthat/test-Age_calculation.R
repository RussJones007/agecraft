# test-calculate_ageulation.r
#
# Tests for the age calculation and categorization functions
# Created April 26, 2023
# R. Jones

test_that(
  desc = "Age calculation using calc_age that returns a units object",
  code = {
    # set up variables to test
    ages <- 82:0 |>
      set_units("year")

    birth_dates <- seq(lubridate::mdy("04-14-1960"), lubridate::mdy("04-14-2042"), by =  "year")
    end_dates   <- (max(birth_dates) + 1) |> as.Date()
    end_date_days_add <- c(1,3,5,7,9) |>
      set_units("day")
    end_dates_days <- birth_dates[1:length(end_date_days_add)] + as.integer(end_date_days_add)
    expect_message(age_calc(start = birth_dates, end_dates, unit = "day"), regexp = "^The age_calc")
    day_ages <- calculate_age(start = birth_dates, end_dates, unit = "day")
    expect_s3_class(day_ages, "units")
    expect_equal(units(day_ages)$numerator, "d")
    expect_error(calculate_age("04-14-1960"), "is.Date")
    expect_equal(units(calculate_age(as.Date("1960-04-14")))[["numerator"]], "year")
    #expect_equal(age.calc(.start = birth_dates, .end = end_dates), ages)
    expect_equal(calculate_age(birth_dates, end_dates), ages)
    expect_length(calculate_age(birth_dates, end_dates), length(birth_dates))
    expect_type(calculate_age(birth_dates, end_dates), "double")
    expect_equal(object = attr(calculate_age(birth_dates[1:5], unit = "day"), which = "units")$numerator,
                 expected = "d")
    expect_equal(calculate_age(birth_dates[1:length(end_date_days_add)],
                          end_dates_days, unit = "day"), end_date_days_add)
  }
)


test_that(
  desc = "Age categorization of an age object",
  {
    ages <- 82:0 |>
      set_units("year")
    expect_no_error(ann_cat    <- age_cat(ages = ages, by = age.groups$Annual))
    ann_table  <- ann_cat |> table()
    expect_no_error(ann_cat2   <- age_cat(ages = ages, by = 10))
    expect_true(has_attr(ann_cat, "units"))

    expect_equal(levels(ann_cat) |> length(), 5)
    expect_equal(attr(ann_cat, "units"), "year")
    expect_equal(ann_table |> as.numeric(), c(15, 10, 20, 20, 18))
    expect_equal((ann_table |> dimnames())[[1]], c("0-14", "15-24", "25-44", "45-64", "65 +"))
  }
)

test_that(
  desc = "Age categorization from an integer and double",
  {
    set.seed(041460)
    ints <- sample(0:102, size = 25, replace = TRUE)
    expect_no_error(int_cats <-  age_cat(ints, by = age.groups$Yr.5))
    expect_s3_class(int_cats, "ordered")
    expect_length(int_cats, length(ints))

    set.seed(041460)
    doubles <- runif(25, min = 0, max = 102)
    expect_no_error(dbl_cats <-  age_cat(doubles, by = age.groups$Yr.5))
    expect_s3_class(dbl_cats, "ordered")
    expect_length(dbl_cats, length(doubles))
   })


test_that(
  desc = "Minimal age unit and age",
  {
    dob_d  <- as.Date("1975-04-14")
    dob_ct <- as.POSIXct(dob_d)
    events <- c(dob_d + 30,dob_d + 20, dob_d + 90, dob_d + 1200)
    ages   <- age_auto_unit(dob_d, events)
    expect_length(ages, 4)
    expect_true(is.numeric(ages))
    expect_in(ages, c(30, 20, 2 ,3))
    expect_named(ages, c("Day", "Day", "Month", "Year"))

    # repeat with POSIXct
    ages   <- age_auto_unit(dob_ct, events)
    expect_length(ages, 4)
    expect_true(is.numeric(ages))
    expect_in(ages, c(30, 20, 2 ,3))
    expect_named(ages, c("Day", "Day", "Month", "Year"))

  }
)


