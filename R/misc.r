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
#' @format
#' A named list of age groups
#'
#'  * ILI: 0-4, 5-24, 25-49, 50-64, 65+, used by ESSENCE as CDC ILI Age groups
#'  * IMM: <1, 1-4, 5-9, 10-14, 15-19, 20-29, 30-39, 40-49, 50-59, 60+  Immunization Age Groups
#'  * Yr.5:  5 year age groups, 0-4, 5-9, etc
#'  * Yr.10: 10 year age groups, 0-9, 10-19, etc.
#'  * Spec: 0, 1-4, 5-9, 10-19, 20-39, 40-59, 60+
#'  * Annual: 0-14, 15-24, 25-44, 45-64, 65+, used for annual disease report
#'  * Covid: 0-5, 6-12, 13-18, 19, 20-29, 30-39, 40-49, 50-59, 60-69, 70+
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



# utility to show a message when a function is used once per session
# Add to .msg_once_list a flag for each message that could be used using an empty NULL environment
# Then call show_message_once with the list item name and msg inside the function that needs the message
.msg_once_list <- list(
  calc_age_deprecated = new.env(parent = emptyenv()),
  age_dot_cat_deprecated = new.env(parent = emptyenv()),
  age_cat_deprecated = new.env(parent = emptyenv())
)


show_message_once <- function(list_item, msg) {
  if (isTRUE(.msg_once_list[[list_item]])) {
    return(invisible(NULL))
  }

  message(msg)
  .msg_once_list[[list_item]] <- TRUE
}
