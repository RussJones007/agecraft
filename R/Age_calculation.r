# Age_calculation.r
#
# Functions for calculating and categorizing  ages.

# ==== Function calculate_age ======
#' Calculate Age and Age Groups
#'
#' @description Functions to calculate age and age groups. The calculate_age() function returns the age from start to
#'   end dates. The age is calculated in years by default, though other time units can be specified. If the end date is
#'   chronologically before the start date, the returned age is negative. The start and end date vector should be either
#'   the same length or the end date have a length of one in which case it is recycled to the same size as the start
#'   date.
#'
#'  The categorize_age() function categorizes ages into age groups as an ordered and labeled factor.
#'
#' @details
#'   The [units::units] package is used to set time units for ages. A different unit can be set on the returned vector
#'   from calculate_age() by using the [units::set_units()] or the assignment form of the [units::units()] functions.  This
#'   results in conversion of the vector values to the new time unit. You should exercise caution when converting time
#'   units. While seconds, days, and weeks can be accurately converted, months and year are approximated. The best
#'   practice is to use this function with the time unit that will be needed in subsequent analysis and avoid converting
#'   to or from months and years.
#'
#' @param start A Date or POSIXct object e.g., date of birth
#' @param end   A Date or POSIXct of the the end date to calculate age.  The default is [lubridate::now()].
#' @param unit  A character string of the age unit to use like: year (default), month, week, day, hour, min, or
#'   second.
#'
#' @return for calculate_age(), the age as an "units" vector matching the unit parameter (e.g."year")
#' @seealso [age.groups] for a pre-defined list of age groups that are often used.
#' @export
#' @examples
#'  # create 10 random birth dates
#'  begin <- as.Date("1990-01-01")
#'  last  <- as.Date("1998-12-31")
#'
#'  set.seed(123)
#'  birth_days <- seq(begin, last, by = "week") |>
#'       sample(size = 10, replace = FALSE)
#'  birth_days
#'
#'  # Age in years as of Christmas 2025
#'  age_vec  <- calculate_age(start = birth_days, end = as.Date("2025-12-25"))
#'  age_vec
#'
#'  # Weeks between July 4th 1959 and 1969
#'  age_2 <- calculate_age(start = as.Date("1959-07-04"), end = as.Date("1969-07-04"), unit = "week")
#'  age_2
#'
#'
#'  units(age_2) <- "year"
#'  age_2
#'
calculate_age <- function(start,
                     end = lubridate::now(),
                     unit = c("year", "day", "hour", "minute", "month", "second", "week")) {


  if(is.Date(start)) end <- as.Date(end)

  # ensure the start and end are the same type
  assertthat::assert_that(
    (is.Date(start) & is.Date(end)) ||
    (is.POSIXct(start) & is.POSIXct(end))
  )

  sized_vctrs <- vctrs::vec_recycle_common(start = start, end = end)
  if( rlang::is_empty(start) | rlang::is_empty(end)){
    warning("start or end is empty when calculating age. Vector of NA returned")
    return(rep(x = NA_integer_, times = length(sized_vctrs[["start"]])))
  }
  assertthat::not_empty(start)
  assertthat::not_empty(end)

  unit   <- match.arg(unit)
  assertthat::assert_that(assertthat::is.scalar(unit) & assertthat::is.string(unit))
  res   <- switch(unit,
                  "year"   = calc_year(sized_vctrs[["start"]], sized_vctrs[["end"]]),
                  "month"  = (lubridate::as.period(lubridate::interval(sized_vctrs[["start"]], sized_vctrs[["end"]]), units = "month") / months(1)) |>
                    floor(),
                    # default
                  difftime(sized_vctrs[["end"]], sized_vctrs[["start"]], unit = unit) |> floor()) |>
    units::as_units(unit)
    #`attributes<-`(x = _, list(units = unit))
  return(res)
}


#' @inherit calculate_age
#' @export
calc_age <- function(start,
                     end = lubridate::now(),
                     unit = c("year", "day", "hour", "minute", "month", "second", "week")){
  ret <- calculate_age(start = start, end = end,unit = unit)
  show_message_once("calc_age_deprecated",
                    paste("The calc_age() function is deprecated and will eventually be removed. \n",
                          "Use the updated function calculate_age().  This message is shown once during the session.")
  )
  ret
}


# internal function that calculates years between two dates, Used in calculate_age
# Revised and based on code by Roman Shevtsiv at
# https://stackoverflow.com/questions/15569333/get-date-difference-in-years-floating-point
# updated that code to remove the error with vector use in an if function
# Ignores NA in either start or end
# Assumption is that start and end are the same length and is enforced by the calling function
#' @param start, end
#' @noRd
calc_year <- function(start, end){
  #  return vector set to NA the same length as start and end
  ret <- integer(length(start))
  ret[] <- NA_real_

  # remove NA from being calculated
  na_lgl <- (is.na(start) | is.na(end))
  start  <- start[!na_lgl]
  end    <- end[!na_lgl]

  year_delta    <- lubridate::year(end)  - lubridate::year(start)
  months_delta  <- lubridate::month(end) - lubridate::month(start)
  days_delta    <- lubridate::day(end)   - lubridate::day(start)

  # take away one year based months and days have not occurred yet
  one_lgl       <- ((months_delta < 0) | (months_delta == 0 & days_delta < 0))
  year_delta[one_lgl]  <- year_delta[one_lgl] - 1

  # assign non-NA values and return
  ret[!na_lgl] <- year_delta
  return(ret)
}


# ==== Function age.cat =======
#' @keywords internal
#' @export
age.cat <- function(.ages, .lower = 0, .upper=70, .by = 10,
                    .sep = "-", .above.char = " +") {
  show_message_once("age_dot_cat_deprecated",
                    paste("The age.cat() function is deprecated and will eventually be removed. \n",
                          "Use categorize_age() or age_cat() instead. This message is shown once during the session.")
  )
  categorize_age(ages = .ages, lower = .lower, upper = .upper, by = .by,
                 sep = .sep, above.char = .above.char)
}

categorize_age_impl <- function(ages, lower = 0, upper=70, by = 10,
                                sep = "-", above.char = " +") {

  # check argument types
  num_args_err <- list(ages, lower, upper, by) |>
    rlang::set_names(names(as.list(args(categorize_age_impl))[1:4])) |>
    purrr::map_lgl(is.numeric)

  if(!all(num_args_err)){
    arg_err <- names(num_args_err)[!num_args_err]
    stop('Argument: "', arg_err, '" must be numeric')
  }
  rm(num_args_err)

  if(length(by) ==1){  # uniform span in age groups
    brks <- c(seq(lower, upper, by = by), Inf)
    labs <- brks |> as.age_group(sep = sep, below = lower, above = above.char) |> as.character()
    ret  <-  cut(ages, breaks = brks,
              right = FALSE, labels = labs, ordered_result = T)
      } else {  # custom age cuts being used
    labs   <- by |>  as.age_group(sep = sep, below = lower, above = above.char) |> as.character()
    ret    <- cut(ages, breaks = by, right = FALSE,labels = labs, ordered_result = T)
      }
  if(!is.null(attr(ages, "units"))) attr(ret, "units") <- attr(ages, "units")[["numerator"]]
  return(ret)
}

#' @param ages is a vector of integers or units.  If this is a units vector like that returned from the
#' calculate_age() function, the return value will also be in that unit of time.
#' @param lower is the lowest age (default is 0) to include
#' @param upper is the max age (default is 70), above which the ages are aggregated
#' @param by may be a single number for the span of ages in each age group (e.g. '5' creates five year age groups) or a
#'   vector of cut points that defines each age group. When a single number is given, the upper age group will always
#'   be inclusive of all ages above.  When giving a vector or cut points like 'c(5, 15, 35, 65)' the upper age group will
#'   not be inclusive of ages above unless 'Inf' is added e.g., 'c(5, 15, 35, 65, Inf)'.
#' @param sep is the separation character used in the age group label (default is "-") but may be 'through', 'thru', or
#' 'to'.
#' @param above.char is the character used for the upper summary group.  It can be '>', '+', 'plus' and 'above'
#' @rdname calculate_age
#' @return for categorize_age(), a vector of age groups as an ordered factor.  If the ages argument was a units vector,
#'   the returned factor will have the same units.
#' @examples
#'
#' #age_vec <- c(25, 23, 20, 1, 0, 7, 10, 50, 50, 52, 54, 56,34)
#'
#' #default 10 year age groups
#' grp10 <- categorize_age(ages = age_vec)
#' grp10
#' data.frame(age = age_vec, grp10)
#'
#' # special age groups with a different age separator
#' categorize_age(ages = age_vec,  sep = " to ", by = age.groups$Spec)
#'
#' @export
categorize_age <- function(ages, lower = 0, upper=70, by = 10,
                    sep = "-", above.char = " +") {
  categorize_age_impl(ages = ages, lower = lower, upper = upper, by = by,
                      sep = sep, above.char = above.char)
  }


#' Calculate the Age Auto Determine Unit
#'
#' Using a start time, like a birth date and an event date the function calculates the age based on the minimal unit;
#' days, months, or years.  For example if the number of days is 31 or more but fewer than 365, the number of months are
#' calculated. Likewise if the number days is less than 31, the number of days are returned.
#'
#' Future implemenation will in
#'
#' @param birth,event dates for the birth and event
#' @return for age_auto_unit(), a named vector with ages.  The names denote the unit; y - years, m - months,
#'   and d - days.
#' @rdname calculate_age
#' @export
age_auto_unit <- function(birth, event){

  # if(any(lubridate::is.POSIXct(birth), lubridate::is.POSIXct(event))) {
  #   birth <- as.Date(birth)
  #   event <- as.Date(event)
  # }

  # recycle the vectgors for a common size
  recycle_list <- vec_recycle_common(birth, event)
  birth <- recycle_list[[1]]
  event <- recycle_list[[2]]

  # get the number of days between the dates
  days <- difftime(event, birth, units = "day")

  # age units logical used and the number of days for each, the names match those units passed to calculate_age
  spans <- list(
    year   = days >= 365,  # years
    month  = (days >= 30 & days < 365),  # months
    day    = days < 31  # days
  ) |>
    purrr::keep(.p = \(x) sum(x, na.rm = TRUE) > 0)

  # vector to translate from years, months, days to y, m, and which matches NEDSS unit coding
  # translate <- c(years = "y", months = "m", days = "d")

  ages <- numeric(length(birth))   # the vector to return, set to 0
  nms  <- character(length(birth)) # character vector to use for naming ages
  na_lgl <- is.na(days)
  ages[na_lgl] <- NA_real_
  nms[na_lgl]  <- ""       # set the name to blank for those entries that are NA

  # now change all NAs in the logical span vectors to FALSE
  spans <- purrr::map(spans, function(x) replace(x, is.na(x), FALSE))

  # internal function to calculate the age based on the unit
  age_unit_calc <- function(s, nm){
    ages[s] <<- calculate_age(as.Date(birth[s]), as.Date(event[s]), nm)
    nms[s]  <<- nm
  }

  purrr::iwalk(spans, age_unit_calc)
  names(ages) <- stringr::str_to_title(nms)
  return(ages)
}


#' @inherit categorize_age
#' @export
age_cat <- function(ages, lower = 0, upper=70, by = 10,
                    sep = "-", above.char = " +") {
  show_message_once("age_cat_deprecated",
                    paste("The age_cat() function is deprecated and will eventually be removed. \n",
                          "Use categorize_age() instead. This message is shown once during the session.")
  )
  categorize_age(ages = ages, lower = lower, upper = upper, by = by,
                 sep = sep, above.char = above.char)
}
