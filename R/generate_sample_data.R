#' Generate Sample Sales Rep Data
#'
#' Creates realistic sales rep activity data for testing and demos.
#' Generates data for multiple reps across multiple quarters with varying
#' performance profiles (new/experienced reps, high/low activity levels).
#'
#' @param n_reps Number of sales reps to generate (default: 20)
#' @param n_quarters Number of quarters to generate data for (default: 4)
#' @param seed Random seed for reproducibility (default: 42)
#'
#' @return A tibble with columns: rep_id, rep_name, tenure_months, calls_made,
#'   followups_done, meetings_scheduled, deals_closed, revenue_generated,
#'   quota, territory_size, period
#'
#' @examples
#' # Generate default dataset (20 reps, 4 quarters)
#' data <- generate_sample_data()
#'
#' # Generate smaller dataset for testing
#' data <- generate_sample_data(n_reps = 5, n_quarters = 2, seed = 123)
#'
generate_sample_data <- function(n_reps = 20, n_quarters = 4, seed = 42) {
  set.seed(seed)

  # Calculate profile counts ensuring they sum to n_reps
  n_new <- round(n_reps * 0.3)
  n_mid <- round(n_reps * 0.4)
  n_exp <- n_reps - n_new - n_mid

  # Generate rep profiles (tenure determines experience level)
  rep_profiles <- tibble::tibble(
    rep_id = sprintf("REP%03d", seq_len(n_reps)),
    rep_name = paste("Rep", LETTERS[(seq_len(n_reps) - 1) %% 26 + 1]),
    tenure_months = sample(c(
      sample(1:12, n_new, replace = TRUE),
      sample(13:36, n_mid, replace = TRUE),
      sample(37:120, n_exp, replace = TRUE)
    ), n_reps),
    quota = sample(c(50000, 75000, 100000, 150000), n_reps, replace = TRUE),
    territory_size = round(runif(n_reps, min = 50, max = 500))
  )

  # Generate quarterly data for each rep
  quarters <- sprintf("Q%d-2025", seq_len(n_quarters))

  data <- purrr::map_dfr(quarters, function(quarter) {
    rep_profiles |>
      dplyr::mutate(
        period = quarter,
        calls_made = pmax(0L, as.integer(round(rnorm(
          n_reps,
          mean = 80 + tenure_months * 0.5,
          sd = 20
        )))),
        followups_done = pmax(0L, as.integer(round(rnorm(
          n_reps,
          mean = 40 + tenure_months * 0.3,
          sd = 15
        )))),
        meetings_scheduled = pmax(0L, as.integer(round(rnorm(
          n_reps,
          mean = 15 + tenure_months * 0.2,
          sd = 8
        )))),
        deals_closed = pmax(0L, as.integer(round(rnorm(
          n_reps,
          mean = 5 + tenure_months * 0.1,
          sd = 3
        )))),
        revenue_generated = pmax(0, round(
          deals_closed * (quota / 10) * runif(n_reps, 0.8, 1.2)
        ))
      )
  })

  # Reorder columns to match spec
  data |>
    dplyr::select(
      rep_id, rep_name, tenure_months, calls_made, followups_done,
      meetings_scheduled, deals_closed, revenue_generated, quota,
      territory_size, period
    )
}
