#' Normalize Metrics by Tenure
#'
#' Calculates a tenure adjustment factor where new reps get scaled expectations.
#' Uses continuous scaling: tenure_factor = min(1.0, tenure_months / 60).
#' Experienced reps (60+ months) get factor of 1.0 (no adjustment).
#'
#' @param data A data frame or tibble with tenure_months column
#'
#' @return Input data with new column 'tenure_factor' (range: 0-1)
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", tenure_months = 12)
#' normalize_tenure(df)
normalize_tenure <- function(data) {
  validate_columns(data, "tenure_months")
  validate_non_negative(data, "tenure_months")

  data |>
    dplyr::mutate(
      tenure_factor = pmin(1.0, tenure_months / 60)
    )
}

#' Normalize Metrics by Territory Size
#'
#' Calculates a territory adjustment factor for activity metrics.
#' Baseline is 100 accounts. Factor = territory_size / 100.
#' Larger territories get higher factor (credit for managing more accounts).
#'
#' @param data A data frame or tibble with territory_size column
#'
#' @return Input data with new column 'territory_factor' (range: 0.5-5.0 for
#'   50-500 territories)
#'
#' @examples
#' df <- tibble::tibble(rep_id = "REP001", territory_size = 200)
#' normalize_territory(df)
normalize_territory <- function(data) {
  validate_columns(data, "territory_size")
  validate_non_negative(data, "territory_size")

  data |>
    dplyr::mutate(
      territory_factor = territory_size / 100
    )
}

#' Normalize Revenue by Quota
#'
#' Calculates quota attainment percentage (uncapped).
#' Allows overachievers to score > 100%.
#' Assumes quota > 0. Throws error if quota contains zero or negative values.
#'
#' @param data A data frame or tibble with revenue_generated and quota columns
#'
#' @return Input data with new column 'quota_attainment' (percentage, uncapped)
#'
#' @examples
#' df <- tibble::tibble(revenue_generated = 150000, quota = 100000)
#' normalize_quota(df)
normalize_quota <- function(data) {
  validate_columns(data, c("revenue_generated", "quota"))
  validate_non_negative(data, "revenue_generated")
  validate_non_negative(data, "quota")

  if (any(data$quota == 0, na.rm = TRUE)) {
    stop("Column 'quota' cannot contain zero values (must be > 0)")
  }

  data |>
    dplyr::mutate(
      quota_attainment = (revenue_generated / quota) * 100
    )
}
