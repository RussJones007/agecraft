# Age_calculation.r
#
# Functions for calculating and categorizing  ages.

# ==== Function calculate_age ======
#' Calculate Age and Age Groups
#'
#' @description Functions to calculate age and age groups. The calculate_age() function returns the age from start to
#'   end dates. The age is calculated in years by default, though other time units can be specified. If the end date is
#'   chronologically before the start date, an error is raised. The start and end date vectors should be either
#'   the same length or one vector must have length one for scalar recycling.
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
#'   Years and months count completed calendar anniversaries using civil dates.
#'   Leap birthdays reach their next year on March 1 in non-leap years. Month
#'   anniversaries use the last day of a shorter month. For POSIXct inputs,
#'   calendar calculations use the start time zone and ignore the time of day;
#'   smaller units measure elapsed time, so a daylight-saving day may be 23 or 25 hours.
#'   Missing pairs return NA. Empty, recyclable inputs return a zero-length units vector.
#'
#' @param start A Date or POSIXct object e.g., date of birth
#' @param end A Date or POSIXct end time, defaulting to [lubridate::now()].
#'   When start is Date, end is converted using as.Date(); when start is POSIXct,
#'   end must also be POSIXct.
#' @param unit  A character string of the age unit to use like: year (default), month, week, day, hour, minute, or
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
#'  age_2 <- units::set_units(age_2, "year")
#'  age_2
#'
calculate_age <- function(start,
                          end = lubridate::now(),
                          unit = c("year", "day", "hour", "minute", "month", "second", "week")) {
  unit <- match.arg(unit)
  if (lubridate::is.Date(start)) end <- as.Date(end)
  assertthat::assert_that(
    (lubridate::is.Date(start) && lubridate::is.Date(end)) ||
      (lubridate::is.POSIXct(start) && lubridate::is.POSIXct(end))
  )
  dates <- vctrs::vec_recycle_common(start = start, end = end)
  start <- dates$start
  end <- dates$end
  if (any(end < start, na.rm = TRUE)) {
    stop("end must not precede start when calculating age", call. = FALSE)
  }
  # Calendar ages use local civil dates in the starting time zone.
  civil_start <- as_civil_date(start)
  civil_end <- as_civil_date(end, tz = lubridate::tz(start))
  res <- switch(unit,
    year = calc_year(civil_start, civil_end),
    month = calc_month(civil_start, civil_end),
    floor(as.numeric(difftime(end, start, units = if (unit == "week") "days" else unit)) /
            if (unit == "week") 7 else 1)
  )
  units::set_units(as.numeric(res), unit, mode = "standard")
}

as_civil_date <- function(x, tz = lubridate::tz(x)) {
  if (lubridate::is.Date(x)) x else as.Date(x, tz = tz)
}

# Completed calendar months; short months use their final day as anniversary.
calc_month <- function(start, end) {
  delta <- (lubridate::year(end) - lubridate::year(start)) * 12 +
    lubridate::month(end) - lubridate::month(start)
  anniversary <- lubridate::add_with_rollback(start, lubridate::period(month = delta))
  delta - as.integer(end < anniversary)
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
#' Deprecated age categorization with legacy argument names
#'
#' Use [categorize_age()] instead. The legacy wrapper emits a deprecation message.
#' @param .ages Numeric ages, optionally carrying units.
#' @param .lower,.upper Lower and upper cut points.
#' @param .by Group width or numeric cut points.
#' @param .sep Separator used in labels.
#' @param .above.char Suffix for the open-ended upper group.
#' @return An ordered factor of age groups.
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

  if(!is.numeric(ages)) stop('Argument: "ages" must be numeric')
  if(!is.numeric(lower)) stop('Argument: "lower" must be numeric')
  if(!is.numeric(upper)) stop('Argument: "upper" must be numeric')

  by_is_numeric <- is.numeric(by)
  by_is_age_group <- is.age_group(by)
  if(!(by_is_numeric || by_is_age_group)) {
    stop('Argument: "by" must be numeric cut points or an age_group vector')
  }

  if(by_is_age_group) {
    ret <- age_cat_iv(age = ages, age_group = by)
  } else

  if(length(by) ==1){  # uniform span in age groups
    brks <- c(seq(lower, upper, by = by), Inf)
    labs <- brks |> as.age_group(sep = sep, below = paste0(lower, "-"), above = above.char) |> as.character()
    ret  <-  cut(ages, breaks = brks,
              right = FALSE, labels = labs, ordered_result = T)
      } else {  # custom age cuts being used
    labs   <- by |>  as.age_group(sep = sep, below = paste0(lower, "-"), above = above.char) |> as.character()
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


#' Calculate age with an automatically selected unit
#'
#' Returns days through day 30. Thereafter uses completed calendar years when
#' available, then completed calendar months, otherwise days. A leap birthday
#' reaches its next year on March 1 in a non-leap year. Short-month anniversaries
#' for month calculations fall on the last day of the month.
#'
#' @param birth,event Date or POSIXct vectors, with scalar recycling. Date-times
#'   are converted to civil dates in their own time zones.
#' @return A numeric vector named "Day", "Month", or "Year" per observation.
#'   Missing pairs return NA with a blank name; empty inputs return an empty vector.
#' @seealso [calculate_age()]
#' @export
age_auto_unit <- function(birth, event) {
  if (!(inherits(birth, "Date") || inherits(birth, "POSIXct")) ||
      !(inherits(event, "Date") || inherits(event, "POSIXct"))) {
    stop("birth and event must be Date or POSIXct vectors", call. = FALSE)
  }
  dates <- vctrs::vec_recycle_common(birth = as_civil_date(birth), event = as_civil_date(event))
  days <- as.numeric(calculate_age(dates$birth, dates$event, "day"))
  years <- as.numeric(calculate_age(dates$birth, dates$event, "year"))
  months <- as.numeric(calculate_age(dates$birth, dates$event, "month"))
  use_year <- !is.na(days) & days > 30 & years >= 1
  use_month <- !is.na(days) & days > 30 & !use_year & months >= 1
  ages <- days
  labels <- rep("Day", length(days))
  ages[use_month] <- months[use_month]
  labels[use_month] <- "Month"
  ages[use_year] <- years[use_year]
  labels[use_year] <- "Year"
  labels[is.na(days)] <- ""
  names(ages) <- labels
  ages
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
