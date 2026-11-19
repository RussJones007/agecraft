# Run existing package tests against the session-only cast candidate.
devtools::load_all(quiet = TRUE)
source("experiments/comparison-performance/candidate.R")
# Keep the namespace binding consistent too: existing mock-based tests refresh
# registrations from that binding when they restore unrelated package functions.
testthat::local_mocked_bindings(vec_cast.age.age = range_cast, .package = "agecraft")
registerS3method("vec_cast", "age.age", range_cast, envir = asNamespace("vctrs"))
testthat::test_local(load_package = "none", stop_on_failure = TRUE)
stopifnot(identical(getS3method("vec_cast", "age.age", envir = asNamespace("vctrs")), range_cast))
cat("Verified candidate registration is still active after the complete test suite.\n")
