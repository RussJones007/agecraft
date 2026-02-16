# ------------------------------------------------------------------------------------------------------------------->
# Script: build.r
# Description:
# Builds the package
#
#
# ------------------------------------------------------------------------------------------------------------------->
# Author: Russ Jones
# Created: October 13, 2025
# ------------------------------------------------------------------------------------------------------------------->

# increment the development version
usethis::use_version("dev")
roxygen2::roxygenise()
#document()
pkg <- devtools::build(binary = TRUE)

bspm::disable()
dput(pkg)
devtools::install_local(pkg)
