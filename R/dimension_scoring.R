#' Score Activity Quality Dimension
#'
#' Calculates activity quality score (0-100) based on normalized activity
#' metrics. Combines calls, followups, and meetings with equal weighting.
#' Uses percentile ranking across all rows in dataset.
#'
#' @param data A data frame with calls_made, followups_done, meetings_scheduled,
#'   tenure_factor, and territory_factor columns
#'
#' @return Input data with new column 'activity_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   calls_made = 100, followups_done = 50, meetings_scheduled = 20,
#'   tenure_factor = 0.5, territory_factor = 2.0
#' )
#' score_activity(df)
score_activity <- function(data) {
  required <- c("calls_made", "followups_done", "meetings_scheduled",
                "tenure_factor", "territory_factor")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      calls_normalized = (calls_made / territory_factor) * tenure_factor,
      followups_normalized = (followups_done / territory_factor) * tenure_factor,
      meetings_normalized = (meetings_scheduled / territory_factor) *
        tenure_factor,
      activity_composite = (calls_normalized + followups_normalized +
        meetings_normalized) / 3,
      activity_score = percentile_rank(activity_composite)
    ) |>
    dplyr::select(
      -calls_normalized, -followups_normalized, -meetings_normalized,
      -activity_composite
    )
}

#' Score Conversion Efficiency Dimension
#'
#' Calculates conversion efficiency score (0-100) based on:
#' - Meetings-to-deals ratio (50% weight)
#' - Revenue per activity unit (50% weight)
#' Uses percentile ranking for each component.
#'
#' @param data A data frame with deals_closed, meetings_scheduled,
#'   revenue_generated, calls_made, followups_done columns
#'
#' @return Input data with new column 'conversion_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   deals_closed = 10, meetings_scheduled = 20,
#'   revenue_generated = 100000, calls_made = 100, followups_done = 50
#' )
#' score_conversion(df)
score_conversion <- function(data) {
  required <- c("deals_closed", "meetings_scheduled", "revenue_generated",
                "calls_made", "followups_done")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      meetings_to_deals = deals_closed / pmax(1, meetings_scheduled),
      meetings_to_deals_score = percentile_rank(meetings_to_deals),
      total_activities = calls_made + followups_done + meetings_scheduled,
      revenue_per_activity = revenue_generated / pmax(1, total_activities),
      revenue_per_activity_score = percentile_rank(revenue_per_activity),
      conversion_score = (meetings_to_deals_score +
        revenue_per_activity_score) / 2
    ) |>
    dplyr::select(
      -meetings_to_deals, -meetings_to_deals_score,
      -total_activities, -revenue_per_activity, -revenue_per_activity_score
    )
}

#' Score Revenue Contribution Dimension
#'
#' Calculates revenue contribution score (0-100) based on:
#' - Quota attainment percentage (50% weight)
#' - Revenue per deal closed (50% weight)
#' Uses percentile ranking for each component.
#'
#' @param data A data frame with quota_attainment, revenue_generated,
#'   deals_closed columns
#'
#' @return Input data with new column 'revenue_score' (0-100)
#'
#' @examples
#' df <- tibble::tibble(
#'   quota_attainment = 150, revenue_generated = 150000, deals_closed = 10
#' )
#' score_revenue(df)
score_revenue <- function(data) {
  required <- c("quota_attainment", "revenue_generated", "deals_closed")
  validate_columns(data, required)

  data |>
    dplyr::mutate(
      quota_attainment_score = percentile_rank(quota_attainment),
      revenue_per_deal = revenue_generated / pmax(1, deals_closed),
      revenue_per_deal_score = percentile_rank(revenue_per_deal),
      revenue_score = (quota_attainment_score + revenue_per_deal_score) / 2
    ) |>
    dplyr::select(
      -quota_attainment_score, -revenue_per_deal, -revenue_per_deal_score
    )
}
