#' Validate Required Columns in DataFrame
#'
#' Checks that all required columns exist in the input data frame.
#' Throws an error listing missing columns if any are not found.
#'
#' @param data A data frame or tibble to validate
#' @param required_cols Character vector of required column names
#'
#' @return NULL (invisibly). Function only used for side effect (error if validation fails).
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", score = 85)
#' validate_columns(df, c("rep_id", "score"))
#' \dontrun{
#' validate_columns(df, c("rep_id", "missing_col"))
#' }
validate_columns <- function(data, required_cols) {
  missing <- setdiff(required_cols, names(data))
  if (length(missing) > 0) {
    stop("Required columns missing: ", paste(missing, collapse = ", "))
  }
  invisible(NULL)
}

#' Validate No Negative Values in Column
#'
#' Checks that a numeric column contains no negative values.
#' Throws an error if negative values are found.
#'
#' @param data A data frame or tibble
#' @param col_name String name of column to validate
#'
#' @return NULL (invisibly). Function only used for side effect (error if validation fails).
#'
#' @examples
#' df <- tibble::tibble(tenure_months = c(1, 12, 36))
#' validate_non_negative(df, "tenure_months")
validate_non_negative <- function(data, col_name) {
  if (any(data[[col_name]] < 0, na.rm = TRUE)) {
    stop("Column '", col_name, "' cannot contain negative values")
  }
  invisible(NULL)
}

#' Calculate Percentile Rank
#'
#' Converts a numeric vector to percentile ranks (0-100 scale).
#' Handles ties using average method. All-zero vectors return zeros.
#'
#' @param x Numeric vector to rank
#'
#' @return Numeric vector of percentile ranks (0-100)
#'
#' @examples
#' percentile_rank(c(10, 20, 30))
#' percentile_rank(c(5, 5, 5))
percentile_rank <- function(x) {
  if (all(x == 0)) {
    return(rep(0, length(x)))
  }
  n <- length(x)
  if (n == 1) {
    return(0)
  }
  (rank(x, ties.method = "average") - 1) / (n - 1) * 100
}
