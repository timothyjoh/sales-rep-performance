#' Generate Improvement Suggestions Based on Score Patterns
#'
#' Analyzes rep performance scores and returns rule-based coaching recommendations.
#' Identifies specific skill gaps and development opportunities using dimension scores.
#'
#' @param scored_data Data frame with columns: rep_id, rep_name, score,
#'   activity_score, conversion_score, revenue_score
#'
#' @return Data frame with columns: rep_id, rep_name, suggestion_category,
#'   suggestion_text. Returns empty data frame if no suggestions match.
#'   When multiple rules match, returns the most critical suggestion per rep.
#'
#' @details
#' Implements 5 rule-based patterns with priority ordering:
#' 1. Low overall score (<40) -> comprehensive_coaching (HIGHEST PRIORITY)
#' 2. High overall score (>85) -> mentorship
#' 3. High activity (>75) + Low conversion (<50) -> conversion_training
#' 4. Low activity (<40) + High conversion (>70) -> increase_outreach
#' 5. High conversion (>75) + Low revenue (<50) -> deal_sizing
#'
#' Priority rationale: Struggling reps need comprehensive support before
#' dimension-specific coaching. High performers identified for leadership roles.
#' Mid-range scores receive targeted coaching on specific weaknesses.
#'
#' @examples
#' scored_data <- data.frame(
#'   rep_id = "REP001", rep_name = "Rep A",
#'   score = 90, activity_score = 88,
#'   conversion_score = 90, revenue_score = 92
#' )
#' suggestions <- generate_suggestions(scored_data)
#'
#' @export
generate_suggestions <- function(scored_data) {
  # Return empty result for non-data-frame or empty input
  empty_result <- data.frame(
    rep_id = character(0),
    rep_name = character(0),
    suggestion_category = character(0),
    suggestion_text = character(0),
    stringsAsFactors = FALSE
  )

  if (!is.data.frame(scored_data) || nrow(scored_data) == 0) {
    return(empty_result)
  }

  # Validate required columns
  required_cols <- c("rep_id", "rep_name", "score", "activity_score",
                     "conversion_score", "revenue_score")
  missing <- setdiff(required_cols, names(scored_data))
  if (length(missing) > 0) {
    stop(paste0("Missing required columns: ", paste(missing, collapse = ", ")))
  }

  # Process each rep individually, applying priority-ordered rules
  suggestions_list <- lapply(seq_len(nrow(scored_data)), function(i) {
    rep <- scored_data[i, ]

    # Skip reps with NA dimension scores (insufficient data for recommendation)
    if (any(is.na(c(rep$activity_score, rep$conversion_score,
                     rep$revenue_score)))) {
      return(NULL)
    }

    # Priority 1: Low overall score -> comprehensive coaching
    # Rationale: Struggling across multiple dimensions needs holistic intervention
    if (rep$score < 40) {
      return(data.frame(
        rep_id = as.character(rep$rep_id),
        rep_name = as.character(rep$rep_name),
        suggestion_category = "comprehensive_coaching",
        suggestion_text = "Schedule comprehensive coaching session to identify skill gaps and barriers",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 2: High overall score -> mentorship
    # Rationale: Top performers can develop others and take on leadership
    if (rep$score > 85) {
      return(data.frame(
        rep_id = as.character(rep$rep_id),
        rep_name = as.character(rep$rep_name),
        suggestion_category = "mentorship",
        suggestion_text = "Consider for mentorship role or leadership development",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 3: High activity + Low conversion -> conversion training
    # Rationale: Strong outreach but poor closing suggests skill gap
    if (rep$activity_score > 75 && rep$conversion_score < 50) {
      return(data.frame(
        rep_id = as.character(rep$rep_id),
        rep_name = as.character(rep$rep_name),
        suggestion_category = "conversion_training",
        suggestion_text = "Focus on meeting quality and follow-up techniques to improve conversion rate",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 4: Low activity + High conversion -> increase outreach
    # Rationale: Strong closing ability but insufficient pipeline volume
    if (rep$activity_score < 40 && rep$conversion_score > 70) {
      return(data.frame(
        rep_id = as.character(rep$rep_id),
        rep_name = as.character(rep$rep_name),
        suggestion_category = "increase_outreach",
        suggestion_text = "Increase outreach volume to capitalize on strong conversion skills",
        stringsAsFactors = FALSE
      ))
    }

    # Priority 5: High conversion + Low revenue -> deal sizing
    # Rationale: Good at closing but small deal sizes limit revenue
    if (rep$conversion_score > 75 && rep$revenue_score < 50) {
      return(data.frame(
        rep_id = as.character(rep$rep_id),
        rep_name = as.character(rep$rep_name),
        suggestion_category = "deal_sizing",
        suggestion_text = "Focus on deal sizing and upselling to increase revenue per closed deal",
        stringsAsFactors = FALSE
      ))
    }

    # No matching pattern — mid-range performers need no specific suggestion
    return(NULL)
  })

  # Combine all suggestions, removing NULLs (reps with no matching pattern)
  suggestions_list <- Filter(Negate(is.null), suggestions_list)

  if (length(suggestions_list) == 0) {
    return(empty_result)
  }

  do.call(rbind, suggestions_list)
}
