classify_village <- function(analysis_data, village_id) {
  affected <- analysis_data$village == village_id
  analysis_data$domlow[affected] <- 1 - analysis_data$domlow[affected]
  analysis_data$dlbuywater <- analysis_data$domlow * analysis_data$buywater
  analysis_data$dlownpump <- analysis_data$domlow * analysis_data$ownpump
  analysis_data
}

estimate_contrast <- function(analysis_data, model_formula, terms) {
  fit <- lm(model_formula, data = analysis_data)
  covariance <- sandwich::vcovCL(fit, cluster = analysis_data$village, type = "HC1")
  estimate <- sum(coef(fit)[terms])
  standard_error <- sqrt(sum(covariance[terms, terms, drop = FALSE]))
  degrees_freedom <- length(unique(analysis_data$village)) - 1L
  interval_width <- qt(.975, degrees_freedom) * standard_error
  c(
    estimate = estimate, standard_error = standard_error,
    lower = estimate - interval_width, upper = estimate + interval_width,
    p_value = 2 * pt(-abs(estimate / standard_error), degrees_freedom)
  )
}

if (sys.nframe() == 0L) {
  replication <- readRDS("output/fits.rds")
  specifications <- list(
    baseline = list(model = "T3_1", terms = "domlow"),
    district_adjusted = list(model = "T3_2", terms = "domlow"),
    buyer_interaction = list(model = "T4_2", terms = "dlbuywater"),
    buyer_village_gap = list(model = "T4_2", terms = c("domlow", "dlbuywater"))
  )
  results <- list()
  for (specification in names(specifications)) {
    setup <- specifications[[specification]]
    model <- replication$models[[setup$model]]
    villages <- sort(unique(model$data$village))
    for (village_id in c(NA, villages)) {
      analysis_data <- if (is.na(village_id)) model$data else classify_village(model$data, village_id)
      result <- estimate_contrast(analysis_data, formula(model$fit), setup$terms)
      results[[length(results) + 1L]] <- data.frame(
        specification = specification, flipped_village = village_id,
        original_domlow = if (is.na(village_id)) NA else unique(model$data$domlow[model$data$village == village_id]),
        households_reclassified = if (is.na(village_id)) 0L else sum(model$data$village == village_id),
        n = nrow(analysis_data), villages = length(villages), as.list(result)
      )
    }
  }
  results <- do.call(rbind, results)
  write.csv(results, "output/dominance_single_flip.csv", row.names = FALSE)
  summary <- do.call(rbind, lapply(split(results, results$specification), function(rows) {
    original <- rows[is.na(rows$flipped_village), ]
    alternatives <- rows[!is.na(rows$flipped_village), ]
    data.frame(
      specification = original$specification, original_estimate = original$estimate,
      original_p = original$p_value, alternatives = nrow(alternatives),
      smallest_estimate = min(alternatives$estimate), largest_estimate = max(alternatives$estimate),
      sign_reversals = sum(sign(alternatives$estimate) != sign(original$estimate)),
      intervals_including_zero = sum(alternatives$lower <= 0 & alternatives$upper >= 0)
    )
  }))
  write.csv(summary, "output/dominance_single_flip_summary.csv", row.names = FALSE)
  print(summary, row.names = FALSE)
}
