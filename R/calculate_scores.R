#' Validate Weight Configuration
#'
#' Checks that weights are a named numeric vector with correct names,
#' all positive values, and sum to 1.0 (within tolerance).
#'
#' @param weights Named numeric vector with names: activity, conversion, revenue
#'
#' @return NULL (invisibly). Function only used for validation side effect.
#'
#' @examples
#' validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.3))
#' \dontrun{
#' validate_weights(c(activity = 0.3, conversion = 0.4, revenue = 0.29))
#' }
validate_weights <- function(weights) {
  if (!is.numeric(weights) || is.null(names(weights))) {
    stop("Weights must be a named numeric vector")
  }

  expected_names <- c("activity", "conversion", "revenue")
  if (!all(expected_names %in% names(weights)) || length(weights) != 3) {
    stop("Weights must have exactly three names: activity, conversion, revenue")
  }

  if (any(weights < 0)) {
    stop("All weights must be non-negative")
  }

  weight_sum <- sum(weights)
  if (abs(weight_sum - 1.0) > 0.001) {
    stop("Weights sum to ", round(weight_sum, 3),
         ", must sum to 1.0 (tolerance \u00b10.001)")
  }

  invisible(NULL)
}

#' Calculate Final Productivity Scores
#'
#' Orchestrates full scoring pipeline: normalization, dimension scoring,
#' then weighted sum. Returns input data with four new score columns.
#'
#' @param data A data frame with all required columns from sample_reps.csv
#' @param weights Named numeric vector with dimension weights
#'   (default: equal weighting)
#'
#' @return Input data with new columns: activity_score, conversion_score,
#'   revenue_score, score
#'
#' @examples
#' df <- read.csv("data/sample_reps.csv")
#' scored <- calculate_scores(df)
#' scored_custom <- calculate_scores(
#'   df, c(activity = 0.5, conversion = 0.3, revenue = 0.2)
#' )
calculate_scores <- function(
    data,
    weights = c(activity = 0.333, conversion = 0.334, revenue = 0.333)) {
  required <- c("rep_id", "tenure_months", "territory_size", "quota",
                "calls_made", "followups_done", "meetings_scheduled",
                "deals_closed", "revenue_generated")
  validate_columns(data, required)
  validate_weights(weights)

  # Normalization pipeline
  data_normalized <- data |>
    normalize_tenure() |>
    normalize_territory() |>
    normalize_quota()

  # Dimension scoring pipeline
  data_scored <- data_normalized |>
    score_activity() |>
    score_conversion() |>
    score_revenue()

  # Calculate final weighted score and clean up intermediate columns
  data_scored |>
    dplyr::mutate(
      score = activity_score * weights["activity"] +
        conversion_score * weights["conversion"] +
        revenue_score * weights["revenue"]
    ) |>
    dplyr::select(-tenure_factor, -territory_factor, -quota_attainment)
}
