ihds_models <- new.env()
sys.source("src/ihds_replication.R", envir = ihds_models)

point_ihds_contrasts <- function(data) {
  data <- droplevels(data)
  fit <- lm(ihds_models$ihds_formula(data), data = data, weights = data$analysis_weight)
  contrasts <- ihds_models$ihds_contrasts(fit)
  estimable <- ihds_models$estimable_ihds_contrasts(fit, contrasts)
  estimates <- rep(NA_real_, nrow(contrasts))
  identified <- !is.na(coef(fit))
  estimates[estimable] <- as.vector(contrasts[estimable, identified, drop = FALSE] %*% coef(fit)[identified])
  names(estimates) <- rownames(contrasts)
  reference <- data$dominance == 0 & data$water_status == "buyer"
  denominator <- weighted.mean(data$outcome[reference], data$analysis_weight[reference])
  c(estimates[c("buyer_gap", "buyer_minus_owner")], reference_mean = denominator)
}

bootstrap_ihds_ratios <- function(primary, draws = 999L) {
  set.seed(20260908)
  data <- primary$data
  village_states <- unique(data[, c("village_key", "state")])
  stopifnot(!anyDuplicated(village_states$village_key))
  strata <- split(village_states$village_key, village_states$state)
  row_indices <- split(seq_len(nrow(data)), data$village_key)
  estimates <- lapply(seq_len(draws), function(draw) {
    sampled <- unlist(lapply(strata, function(keys) sample(keys, length(keys), replace = TRUE)), use.names = FALSE)
    sample <- data[unlist(row_indices[sampled], use.names = FALSE), ]
    values <- tryCatch(point_ihds_contrasts(sample), error = identity)
    if (inherits(values, "error")) {
      return(data.frame(
        draw = draw, buyer_gap = NA_real_, buyer_minus_owner = NA_real_,
        reference_mean = NA_real_, buyer_ratio = NA_real_, difference_ratio = NA_real_,
        reason = conditionMessage(values)
      ))
    }
    valid <- is.finite(values[3]) && values[3] > 0
    data.frame(
      draw = draw, buyer_gap = values[1], buyer_minus_owner = values[2], reference_mean = values[3],
      buyer_ratio = if (valid) values[1] / values[3] else NA_real_,
      difference_ratio = if (valid) values[2] / values[3] else NA_real_,
      reason = if (valid) "" else "Nonpositive reference mean"
    )
  })
  draws_data <- do.call(rbind, estimates)
  summary <- do.call(rbind, lapply(c("buyer_ratio", "difference_ratio"), function(name) {
    values <- draws_data[[name]]
    interval <- quantile(values, c(.025, .975), na.rm = TRUE)
    data.frame(
      contrast = if (name == "buyer_ratio") "buyer_gap" else "buyer_minus_owner", draws = draws,
      valid = sum(is.finite(values)), failed = sum(!is.finite(values)), lower = interval[1], upper = interval[2]
    )
  }))
  write.csv(draws_data, "output/ihds_ratio_bootstrap_draws.csv", row.names = FALSE)
  write.csv(summary, "output/ihds_ratio_bootstrap_summary.csv", row.names = FALSE)
  summary
}

influence_ihds <- function(primary) {
  data <- primary$data
  results <- do.call(rbind, lapply(unique(data$village_key), function(village) {
    sample <- data[data$village_key != village, ]
    values <- tryCatch(point_ihds_contrasts(sample), error = identity)
    if (inherits(values, "error")) {
      return(data.frame(
        omitted_village = village, buyer_gap = NA_real_,
        buyer_minus_owner = NA_real_, reason = conditionMessage(values)
      ))
    }
    data.frame(omitted_village = village, buyer_gap = values[1], buyer_minus_owner = values[2], reason = "")
  }))
  write.csv(results, "output/ihds_leave_village_out.csv", row.names = FALSE)
  results
}

inference_ihds_ladder <- function(primary) {
  model <- primary$model
  contrasts <- primary$contrasts[c("buyer_gap", "buyer_minus_owner"), , drop = FALSE]
  results <- list()
  for (method in c("HC1", "CR1", "CR2")) {
    covariance <- if (method == "HC1") {
      sandwich::vcovHC(model, type = "HC1")
    } else {
      clubSandwich::vcovCR(model, cluster = primary$data$village_key, type = method, inverse_var = FALSE)
    }
    if (method == "CR2") {
      rows <- primary$results[
        match(rownames(contrasts), primary$results$contrast),
        c("contrast", "estimate", "std_error", "df", "lower", "upper", "p_value")
      ]
    } else {
      estimate <- as.vector(contrasts %*% coef(model))
      error <- sqrt(diag(contrasts %*% covariance %*% t(contrasts)))
      degrees <- if (method == "HC1") df.residual(model) else length(unique(primary$data$village_key)) - 1
      critical <- qt(.975, degrees)
      rows <- data.frame(
        contrast = rownames(contrasts), estimate = estimate, std_error = error, df = degrees,
        lower = estimate - critical * error, upper = estimate + critical * error,
        p_value = 2 * pt(-abs(estimate / error), degrees)
      )
    }
    results[[method]] <- cbind(method = method, rows)
  }
  ladder <- do.call(rbind, results)
  write.csv(ladder, "output/ihds_inference_ladder.csv", row.names = FALSE)
  ladder
}

weighted_ihds_equivalent <- function(primary) {
  root_weight <- sqrt(primary$data$analysis_weight)
  design <- model.matrix(primary$model) * root_weight
  original_names <- colnames(design)
  weighted_data <- as.data.frame(design)
  names(weighted_data) <- make.names(original_names)
  formula <- reformulate(names(weighted_data), response = "weighted_outcome", intercept = FALSE)
  weighted_data$weighted_outcome <- primary$data$outcome * root_weight
  weighted_data$village_key <- primary$data$village_key
  model <- lm(formula, data = weighted_data, x = TRUE, y = TRUE)
  stopifnot(max(abs(unname(coef(model)) - unname(coef(primary$model)))) < 1e-7)
  model
}

wild_ihds <- function(primary, draws = 999L) {
  set.seed(20260907)
  dqrng::dqset.seed(20260907)
  weighted_model <- weighted_ihds_equivalent(primary)
  results <- lapply(c("buyer_gap", "buyer_minus_owner"), function(contrast) {
    parameter <- if (contrast == "buyer_gap") "dominance" else "dominance:water_statusowner"
    warnings <- character()
    result <- tryCatch(withCallingHandlers(
      fwildclusterboot::boottest(
        weighted_model,
        param = make.names(parameter), R = 1,
        clustid = "village_key", B = draws, conf_int = FALSE, type = "webb", impose_null = TRUE,
        bootstrap_type = "31", engine = "R", nthreads = 1
      ),
      warning = function(condition) {
        warnings <<- c(warnings, conditionMessage(condition))
        invokeRestart("muffleWarning")
      }
    ), error = identity)
    if (inherits(result, "error")) {
      return(data.frame(
        contrast = contrast, draws = draws, p_value = NA_real_,
        lower = NA_real_, upper = NA_real_, status = "error", reason = conditionMessage(result),
        pseudo_inverse_warnings = sum(grepl("Pseudo-Inverse", warnings)), warnings = paste(warnings, collapse = " | ")
      ))
    }
    interval <- c(NA_real_, NA_real_)
    data.frame(
      contrast = contrast, draws = draws, p_value = result$p_val,
      lower = interval[1], upper = interval[2], status = "estimated", reason = "",
      pseudo_inverse_warnings = sum(grepl("Pseudo-Inverse", warnings)), warnings = paste(warnings, collapse = " | ")
    )
  })
  results <- do.call(rbind, results)
  results$p_holm <- p.adjust(results$p_value, "holm")
  write.csv(results, "output/ihds_wild_bootstrap.csv", row.names = FALSE)
  results
}

if (sys.nframe() == 0L) {
  built <- ihds_models$ihds_data_tools$build_ihds_replication()
  primary <- ihds_models$fit_ihds_model(ihds_models$select_ihds_sample(built$data))
  print(inference_ihds_ladder(primary))
  print(bootstrap_ihds_ratios(primary))
  influence_ihds(primary)
  print(wild_ihds(primary))
}
