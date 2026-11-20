#include <Rcpp.h>
#include <date.h>
#include <cmath>

namespace {

date::sys_days anniversary(date::year_month month, date::day birth_day,
                           bool roll_to_first) {
  const auto birthday = month / birth_day;
  if (birthday.ok()) {
    return date::sys_days{birthday};
  }

  const date::sys_days month_end{month / date::last};
  return roll_to_first ? month_end + date::days{1} : month_end;
}

bool supports_day_count(double day) {
  // Leave room for the next yearly anniversary at the upper end.
  static const auto first = date::sys_days{date::year::min() / date::January / 1};
  static const auto last =
    date::sys_days{(date::year::max() - date::years{1}) / date::December / 31};
  return day >= first.time_since_epoch().count() &&
    day <= last.time_since_epoch().count() && day == std::trunc(day);
}

} // namespace

// [[Rcpp::export(rng = false)]]
SEXP calendar_age_cpp(Rcpp::NumericVector start, Rcpp::NumericVector end,
                      bool yearly, bool fractional, bool march_first) {
  const R_xlen_t size = start.size();
  if (end.size() != size) {
    Rcpp::stop("calendar_age_cpp requires equal-length date vectors");
  }

  const date::months step{yearly ? 12 : 1};
  const bool roll_to_first = yearly && march_first;
  Rcpp::NumericVector ages(Rcpp::no_init(size));

  for (R_xlen_t i = 0; i < size; ++i) {
    if (i % 65536 == 0) {
      Rcpp::checkUserInterrupt();
    }
    const double birth_day = start[i];
    const double reference_day = end[i];
    if (std::isnan(birth_day) || std::isnan(reference_day)) {
      ages[i] = NA_REAL;
      continue;
    }
    if (!supports_day_count(birth_day) || !supports_day_count(reference_day)) {
      return R_NilValue;
    }

    const date::year_month_day birth{
      date::sys_days{date::days{static_cast<int>(birth_day)}}
    };
    const date::sys_days reference_date{date::days{static_cast<int>(reference_day)}};
    const date::year_month_day reference{reference_date};
    const auto birth_month = birth.year() / birth.month();
    auto last_month = reference.year() / (yearly ? birth.month() : reference.month());
    auto last_birthday = anniversary(last_month, birth.day(), roll_to_first);
    if (reference_date < last_birthday) {
      last_month -= step;
      last_birthday = anniversary(last_month, birth.day(), roll_to_first);
    }

    const int completed = (last_month - birth_month).count() / step.count();
    ages[i] = completed;
    if (fractional && reference_date != last_birthday) {
      const auto next_birthday = anniversary(last_month + step, birth.day(), roll_to_first);
      const double elapsed = (reference_date - last_birthday).count();
      const double span = (next_birthday - last_birthday).count();
      ages[i] += elapsed / span;
    }
  }
  return ages;
}
