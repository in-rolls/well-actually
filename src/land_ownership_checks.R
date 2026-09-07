replication <- readRDS("output/fits.rds")
analysis_data <- replication$models$T3_1$data
analysis_data$owns_land <- as.integer(analysis_data$totland > 0)
analysis_data$district <- max.col(as.matrix(analysis_data[, paste0("dist", 1:25)]))
stopifnot(all(rowSums(analysis_data[, paste0("dist", 1:25)]) == 1))
variables <- c("owns_land", "totland", "tenant", "ownpump", "literate")
comparisons <- list()
for (variable in variables) {
  for (adjustment in c("unadjusted", "district_and_caste")) {
    predictors <- if (adjustment == "unadjusted") {
      "domlow"
    } else {
      c("domlow", "factor(district)", "caste4", "caste5")
    }
    needed <- unique(c(variable, "village", "domlow", "district", "caste4", "caste5"))
    sample_data <- analysis_data[complete.cases(analysis_data[, needed]), ]
    fit <- lm(reformulate(predictors, response = variable), data = sample_data)
    covariance <- sandwich::vcovCL(fit, cluster = sample_data$village, type = "HC1")
    villages <- length(unique(sample_data$village))
    estimate <- unname(coef(fit)["domlow"])
    standard_error <- sqrt(covariance["domlow", "domlow"])
    interval_width <- qt(.975, villages - 1) * standard_error
    comparisons[[length(comparisons) + 1L]] <- data.frame(
      variable = variable, adjustment = adjustment, n = nrow(sample_data), villages = villages,
      n_low = sum(sample_data$domlow == 1), n_high = sum(sample_data$domlow == 0),
      mean_low = mean(sample_data[sample_data$domlow == 1, variable]),
      mean_high = mean(sample_data[sample_data$domlow == 0, variable]),
      difference = estimate, standard_error = standard_error,
      lower = estimate - interval_width, upper = estimate + interval_width,
      p_value = 2 * pt(-abs(estimate / standard_error), villages - 1)
    )
  }
}
comparisons <- do.call(rbind, comparisons)
comparisons$p_holm <- ave(comparisons$p_value, comparisons$adjustment, FUN = function(x) p.adjust(x, "holm"))
write.csv(comparisons, "output/land_ownership_checks.csv", row.names = FALSE)
print(comparisons[comparisons$variable == "owns_land", ], row.names = FALSE)
