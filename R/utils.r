# ------------------------------------------------------------------------------------------------------------------->
# Script: utils.r
# Description:
#  Utility functions used in the package
#
# ------------------------------------------------------------------------------------------------------------------->
# Author: Russ Jones
# Created: October 12, 2025
#
# ------------------------------------------------------------------------------------------------------------------->

# Intervals summary method -----
#' Summary method of intervals
#'
#' Internally used for data frame summaries when an ivs class interval is one of the columns
#'
#' @param object an ivs class vector
#' @param ...
#'
#' @return a summary character string
#' @noRd
#' @export
summary.ivs_iv <- function(object, ...) {
  start <- min(object) |> iv_start()
  end <- max(object) |> iv_end()
  unique_n <- unique(object) |> length()
  c("Min" = start, "Max" = end, "Unique_n" = unique_n)
}

# Intervals as.character method ================
#' Internal function to convert a double interval to a character string
#'
#' @param x a vector of ivs_iv
#' @param ...
#'
#' @return a character vector
#' @noRd
#' @export
as.character.ivs_iv <- function(x, ...){
  paste0("[", iv_start(x), ", ", iv_end(x), ")")
}
