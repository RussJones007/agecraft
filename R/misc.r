# ------------------------------------------------------------------------------------------------------------------->
# Script: misc.r
# Description:
#  Define and document misc data
#
# ------------------------------------------------------------------------------------------------------------------->
# Author: Russ Jones
# Created: October 13, 2025
#
# ------------------------------------------------------------------------------------------------------------------->

# Age group variables ----
#' Age Groups List with Definitions
#'
#' A named list of frequently used age group definitions.  The definitions are cut points that can be passed to the
#' either [categorize_age()] or [cut()] functions.  These definitions are based on age groups by years and all
#' include an "Age and above" group.
#'
#' @source Preserved from the rage 0.1.0.9009 data-generation script. ILI was
#'   attributed to ESSENCE/CDC ILI in the original documentation; an authoritative
#'   edition/date was not recorded. The other named reporting schemes also lack
#'   an external edition/date. Five- and ten-year bands are algorithmic sequences.
#' @details These are legacy reporting conventions, not current clinical guidance.
#'   Confirm cut points against the receiving system's specification. A provenance
#'   table with intended use, available sources, and unknown source-version dates
#'   is installed at `system.file("extdata", "age-group-provenance.csv", package = "agecraft")`.
#'   Cut points were retained unchanged on October 9, 2026.
#' @format
#' A named list of age groups
#'
#'  * ILI: 0-4, 5-24, 25-49, 50-64, 65+, used by ESSENCE as CDC ILI Age groups
#'  * IMM: <1, 1-4, 5-9, 10-14, 15-19, 20-29, 30-39, 40-49, 50-59, 60+  Immunization Age Groups
#'  * Yr.5:  5 year age groups, 0-4, 5-9, etc
#'  * Yr.10: 10 year age groups, 0-9, 10-19, etc.
#'  * Spec: 0, 1-4, 5-9, 10-19, 20-39, 40-59, 60+
#'  * Annual: 0-14, 15-24, 25-44, 45-64, 65+, used for annual disease report
#'  * School: 0-4, 5-10, 11-13, 14-18, 19-23, 24-29, 30-39, etc., 70+
#'  * Covid: 0-4, 5-11, 12-17, 18-19, 20-29, 30-39, 40-49, 50-59, 60-69, 70+
#'
#' @seealso [categorize_age()] to create a vector of age categories as an ordered factor.
#' @seealso [calculate_age()] to calculate age.
#' @examples
#'
#' # Show the definition of some age groups
#' age.groups$ILI
#' age.groups$Annual
#'
"age.groups"



# Persist deprecation state in a namespace-owned environment for the session.
.msg_once_list <- new.env(parent = emptyenv())

show_message_once <- function(list_item, msg) {
  if (isTRUE(.msg_once_list[[list_item]])) return(invisible(NULL))
  message(msg)
  .msg_once_list[[list_item]] <- TRUE
  invisible(NULL)
}
