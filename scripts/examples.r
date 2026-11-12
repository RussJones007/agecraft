# Agecraft arithmetic and classification examples

library(agecraft)

x <- age(c(2.25, 5.75, 10.5), unit = "year")

x                            # Prints completed ages: 2, 5, 10
as.numeric(x)                # Full precision: 2.25, 5.75, 10.5
as.integer(x)                # Completed units: 2, 5, 10
format(x, fractional = TRUE) # Show fractional values

x + 1
# Ages: 3.25, 6.75, 11.5 years

1 + x
# Same result

x - 0.25
# Ages: 2, 5.5, 10.25 years

x + c(0.5, 1, 2)
# Ages: 2.75, 6.75, 12.5 years

age(2, "day") + age(12, "hour")
# 2.5 days

age(12, "hour") + age(2, "day")
# 60 hours

six_months <- as_age(
  age(6, "month"),
  unit = "year",
  allow_approx = TRUE
)

age(2, "year") + six_months
# 2.5 years

round(x)          # 2, 6, 10 years: R uses ties-to-even rounding
round(x, digits = 1)
floor(x)          # 2, 5, 10 years
ceiling(x)        # 3, 6, 11 years
trunc(x)          # 2, 5, 10 years
abs(x)            # Unchanged because ages are nonnegative

mean(x)    # About 6.166667 years
median(x)  # 5.75 years
min(x)     # 2.25 years
max(x)     # 10.5 years
range(x)   # 2.25 and 10.5 years

y <- age(c(2.5, NA, 7), "year")

mean(y, na.rm = TRUE)    # 4.75 years
median(y, na.rm = TRUE)  # 4.75 years

y + 1                   # Missing values remain missing

x > age(5, "year")
# FALSE TRUE TRUE

x == age(5.75, "year")
# FALSE TRUE FALSE

sort(x, decreasing = TRUE)
# Ages ordered as 10.5, 5.75, 2.25

groups <- age_interval(
  c(0, 5, 18),
  c(5, 18, Inf),
  unit = "year"
)

names(groups) <- c("Under 5", "5 to under 18", "18 and older")

categorize_age(
  age(c(4.5, 5, 17.9, 18), "year"),
  by = groups
)
# Under 5, 5 to under 18, 5 to under 18, 18 and older

categorize_age(age(4.5, "year") + 0.5, by = groups)
# 5 to under 18

scheme <- age_scheme(
  groups,
  id = "example",
  name = "Example age bands",
  domain = c(0, Inf),
  complete = TRUE
)

categorize_age(x, by = scheme)  # Ordered category factor
classify_age_scheme(x, scheme) # Membership table

scheme_intervals(scheme)         # Underlying intervals
as.data.frame(scheme)         # Labels and numerical boundaries
summary(scheme)               # Coverage and validation summary

list_age_schemes()            # Available built-in schemes

a <- age_interval(0, 18, unit = "year")
b <- age_interval(5, 25, unit = "year")

compare_age_intervals(a, b, operation = "intersection")
# [5, 18)

compare_age_intervals(a, b, operation = "union")
# [0, 25)

compare_age_intervals(a, b, operation = "difference")
# [0, 5): the part of a outside b

compare_age_intervals(a, operation = "width")
# 18 years

# x - x
# 10 - x
# x * 2
# x / 2
# sum(x)
# log(x)
# exp(x)
# age(1, "year") - 2  # Would produce a negative age
