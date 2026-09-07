ihds_data_tools <- new.env()
sys.source("src/ihds_replication_data.R", envir = ihds_data_tools)

select_ihds_sample <- function(data, definition = "obc", threshold = 50, outcome = "gross_owned",
                               subgroup = "all", weighting = "survey", geography = "district", min_area = 0,
                               winsorize = FALSE, common_outcomes = FALSE) {
  stopifnot(all(is.finite(data$survey_weight) & data$survey_weight > 0))
  data$dominance <- ihds_data_tools$classify_ihds_dominance(data, threshold, definition)
  data$outcome <- data[[outcome]]
  eligible <- data$eligible & data$owned_acres >= min_area
  if (subgroup == "obc") eligible <- eligible & data$caste == 3
  if (subgroup == "sc") eligible <- eligible & data$caste == 4
  if (subgroup == "up") eligible <- eligible & data$state == 9
  if (subgroup == "bihar") eligible <- eligible & data$state == 10
  if (winsorize) {
    ceiling <- quantile(data$outcome[data$eligible], .99, na.rm = TRUE)
    data$outcome <- pmin(data$outcome, ceiling)
  }
  fields <- c("dominance", "water_status", "outcome", "household_size", "education", "sc", "survey_weight")
  if (common_outcomes) fields <- c(fields, "gross_owned", "net_owned", "gross_cultivated")
  finite_fields <- c("outcome", "household_size", "education", "sc", "survey_weight")
  finite_rows <- Reduce(`&`, lapply(data[, finite_fields], is.finite))
  data <- droplevels(data[which(eligible & complete.cases(data[, fields]) & finite_rows), ])
  data$analysis_weight <- switch(weighting,
    survey = data$survey_weight,
    household = rep(1, nrow(data)),
    village = 1 / as.numeric(table(data$village_key)[data$village_key])
  )
  data$analysis_weight <- data$analysis_weight / mean(data$analysis_weight)
  data$geography <- factor(if (geography == "district") data$district_key else data$state)
  data
}

ihds_formula <- function(data) {
  controls <- c("household_size", "education", "sc", "geography")
  controls <- controls[vapply(data[, controls], function(x) length(unique(x)) > 1L, logical(1))]
  reformulate(c("dominance * water_status", controls), response = "outcome")
}

ihds_contrasts <- function(model) {
  terms <- names(coef(model))
  contrast <- matrix(0, 5, length(terms), dimnames = list(
    c("buyer_gap", "owner_gap", "both_gap", "neither_gap", "buyer_minus_owner"), terms
  ))
  contrast[1:4, "dominance"] <- 1
  for (status in c("owner", "both", "neither")) {
    name <- paste0("dominance:water_status", status)
    if (name %in% terms) {
      contrast[paste0(status, "_gap"), name] <- 1
    } else {
      contrast[paste0(status, "_gap"), ] <- NA_real_
    }
  }
  contrast["buyer_minus_owner", ] <- contrast["buyer_gap", ] - contrast["owner_gap", ]
  contrast
}

estimable_ihds_contrasts <- function(model, contrasts) {
  basis <- qr.Q(qr(t(model.matrix(model))))[, seq_len(model$rank), drop = FALSE]
  discrepancy <- contrasts - contrasts %*% basis %*% t(basis)
  apply(abs(discrepancy), 1, max) < 1e-7
}

fit_ihds_model <- function(data) {
  clusters <- vapply(0:1, function(group) length(unique(data$village_key[data$dominance == group])), integer(1))
  if (any(clusters < 5L)) stop("Fewer than five villages in one dominance group; descriptive support only")
  if (!all(c("buyer", "owner", "both", "neither") %in% levels(data$water_status))) {
    stop("At least one water-status category is absent")
  }
  fit <- lm(ihds_formula(data), data = data, weights = data$analysis_weight, x = TRUE, y = TRUE)
  covariance <- clubSandwich::vcovCR(fit, cluster = data$village_key, type = "CR2", inverse_var = FALSE)
  contrast <- ihds_contrasts(fit)
  estimable <- estimable_ihds_contrasts(fit, contrast)
  intervals <- data.frame(
    Est = rep(NA_real_, nrow(contrast)), SE = NA_real_, df = NA_real_,
    CI_L = NA_real_, CI_U = NA_real_, p_val = NA_real_
  )
  if (any(estimable)) {
    identified <- clubSandwich::linear_contrast(fit,
      vcov = covariance,
      contrasts = contrast[estimable, !is.na(coef(fit)), drop = FALSE],
      test = "Satterthwaite", p_values = TRUE
    )
    intervals[estimable, ] <- identified[, names(intervals)]
  }
  reference <- data$dominance == 0 & data$water_status == "buyer"
  denominator <- weighted.mean(data$outcome[reference], data$analysis_weight[reference])
  results <- data.frame(
    contrast = rownames(contrast), estimate = intervals$Est, std_error = intervals$SE,
    df = intervals$df, lower = intervals$CI_L, upper = intervals$CI_U, p_value = intervals$p_val,
    n = nrow(data), villages = length(unique(data$village_key)), upper_villages = clusters[1],
    lower_villages = clusters[2], reference_mean = denominator,
    descriptive_ratio = if (is.finite(denominator) && denominator > 0) intervals$Est / denominator else NA_real_,
    status = ifelse(estimable, "estimated", "not_estimable"),
    reason = ifelse(estimable, "", "Contrast not identified by observed status and geography cells")
  )
  list(model = fit, covariance = covariance, contrasts = contrast, results = results, data = data)
}

support_cells <- function(data, scenario) {
  if (nrow(data) == 0L) {
    return(data.frame(
      scenario = scenario, dominance = NA_real_, water_status = NA_character_,
      n = 0L, villages = 0L, weight_sum = 0, effective_households = NA_real_
    ))
  }
  groups <- split(data, interaction(data$dominance, data$water_status, drop = TRUE))
  do.call(rbind, lapply(groups, function(group) {
    data.frame(
      scenario = scenario, dominance = group$dominance[1], water_status = as.character(group$water_status[1]),
      n = nrow(group), villages = length(unique(group$village_key)),
      weight_sum = sum(group$analysis_weight),
      effective_households = sum(group$analysis_weight)^2 / sum(group$analysis_weight^2)
    )
  }))
}

scenario_grid <- function() {
  base <- list(
    definition = "obc", threshold = 50, outcome = "gross_owned", subgroup = "all",
    weighting = "survey", geography = "district", min_area = 0, winsorize = FALSE, common_outcomes = FALSE
  )
  updates <- list(
    primary = list(), state_effects = list(geography = "state"), equal_households = list(weighting = "household"),
    equal_villages = list(weighting = "village"), cutoff_40 = list(threshold = 40), cutoff_60 = list(threshold = 60),
    not_upper_majority = list(definition = "not_upper"), broad_lower_majority = list(definition = "broad_lower"),
    single_jati_majority = list(definition = "single_jati"), sc_majority = list(definition = "sc"),
    obc_households = list(subgroup = "obc"), sc_households = list(subgroup = "sc"),
    sc_majority_obc_households = list(definition = "sc", subgroup = "obc"),
    sc_majority_sc_households = list(definition = "sc", subgroup = "sc"),
    sc_majority_40 = list(definition = "sc", threshold = 40),
    sc_majority_60 = list(definition = "sc", threshold = 60),
    not_upper_obc_households = list(definition = "not_upper", subgroup = "obc"),
    not_upper_sc_households = list(definition = "not_upper", subgroup = "sc"),
    broad_lower_obc_households = list(definition = "broad_lower", subgroup = "obc"),
    broad_lower_sc_households = list(definition = "broad_lower", subgroup = "sc"),
    single_jati_obc_households = list(definition = "single_jati", subgroup = "obc"),
    single_jati_sc_households = list(definition = "single_jati", subgroup = "sc"),
    up_only = list(subgroup = "up"), bihar_only = list(subgroup = "bihar"),
    minimum_tenth_acre = list(min_area = .1), winsorized_99 = list(winsorize = TRUE),
    net_income = list(outcome = "net_owned"), crop_season_acres = list(outcome = "gross_cultivated"),
    log_gross_value = list(outcome = "log_gross_owned"),
    common_sample_gross = list(common_outcomes = TRUE),
    common_sample_net = list(common_outcomes = TRUE, outcome = "net_owned"),
    common_sample_cultivated = list(common_outcomes = TRUE, outcome = "gross_cultivated")
  )
  lapply(updates, function(update) modifyList(base, update))
}

run_ihds_models <- function(built) {
  results <- cells <- list()
  primary <- NULL
  scenarios <- scenario_grid()
  for (scenario in names(scenarios)) {
    sample <- do.call(select_ihds_sample, c(list(data = built$data), scenarios[[scenario]]))
    cells[[scenario]] <- support_cells(sample, scenario)
    fit <- tryCatch(fit_ihds_model(sample), error = identity)
    if (inherits(fit, "error")) {
      results[[scenario]] <- data.frame(
        scenario = scenario, contrast = NA_character_,
        estimate = NA_real_, std_error = NA_real_, df = NA_real_, lower = NA_real_, upper = NA_real_,
        p_value = NA_real_, n = nrow(sample), villages = length(unique(sample$village_key)),
        upper_villages = length(unique(sample$village_key[sample$dominance == 0])),
        lower_villages = length(unique(sample$village_key[sample$dominance == 1])),
        reference_mean = NA_real_, descriptive_ratio = NA_real_, status = "not_estimated",
        reason = conditionMessage(fit)
      )
    } else {
      if (scenarios[[scenario]]$outcome == "log_gross_owned") fit$results$descriptive_ratio <- NA_real_
      results[[scenario]] <- cbind(scenario = scenario, fit$results)
      if (scenario == "primary") primary <- fit
    }
    message("Completed IHDS scenario: ", scenario)
  }
  settings <- do.call(rbind, lapply(names(scenarios), function(name) {
    cbind(scenario = name, as.data.frame(scenarios[[name]]))
  }))
  write.csv(settings, "output/ihds_scenario_definitions.csv", row.names = FALSE)
  estimates <- do.call(rbind, results)
  estimates$p_holm_primary <- NA_real_
  main <- estimates$scenario == "primary" & estimates$contrast %in% c("buyer_gap", "buyer_minus_owner")
  estimates$p_holm_primary[main] <- p.adjust(estimates$p_value[main], "holm")
  write.csv(estimates, "output/ihds_replication_estimates.csv", row.names = FALSE)
  write.csv(do.call(rbind, cells), "output/ihds_replication_cells.csv", row.names = FALSE)
  stopifnot(!is.null(primary))
  list(primary = primary, estimates = estimates)
}

if (sys.nframe() == 0L) {
  built <- ihds_data_tools$build_ihds_replication()
  run <- run_ihds_models(built)
  print(run$primary$results)
}
