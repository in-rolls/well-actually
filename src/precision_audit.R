water_precision_contrasts <- function(model) {
  contrasts <- matrix(0, 4, length(coef(model)), dimnames = list(
    c("buyer_gap", "buyer_interaction", "owner_gap", "buyer_minus_owner"), names(coef(model))
  ))
  contrasts["buyer_gap", c("domlow", "dlbuywater")] <- 1
  contrasts["buyer_interaction", "dlbuywater"] <- 1
  contrasts["owner_gap", c("domlow", "dlownpump")] <- 1
  contrasts["buyer_minus_owner", c("dlbuywater", "dlownpump")] <- c(1, -1)
  contrasts
}

water_precision <- function(model, data) {
  stopifnot(nobs(model) == nrow(data), !anyNA(coef(model)))
  contrasts <- water_precision_contrasts(model)
  estimate <- as.vector(contrasts %*% coef(model))
  clusters <- length(unique(data$village))
  methods <- c("iid", "HC1", "village_CR1", "village_CR2")
  ladder <- lapply(methods, function(method) {
    if (method == "village_CR2") {
      covariance <- clubSandwich::vcovCR(model, cluster = data$village, type = "CR2", inverse_var = FALSE)
      intervals <- clubSandwich::linear_contrast(model,
        vcov = covariance, contrasts = contrasts,
        test = "Satterthwaite", p_values = TRUE
      )
      error <- intervals$SE
      degrees <- intervals$df
    } else {
      covariance <- switch(method,
        iid = vcov(model),
        HC1 = sandwich::vcovHC(model, type = "HC1"),
        village_CR1 = sandwich::vcovCL(model, cluster = data$village, type = "HC1", cadjust = TRUE)
      )
      error <- sqrt(diag(contrasts %*% covariance %*% t(contrasts)))
      degrees <- if (method == "village_CR1") clusters - 1 else df.residual(model)
    }
    data.frame(
      method = method, contrast = rownames(contrasts), estimate = estimate, std_error = error,
      df = degrees, lower = estimate - qt(.975, degrees) * error,
      upper = estimate + qt(.975, degrees) * error, p_value = 2 * pt(-abs(estimate / error), degrees),
      n = nrow(data), villages = clusters, relative_se = error / abs(estimate)
    )
  })
  do.call(rbind, ladder)
}

precision_cluster_scores <- function(model, data) {
  design <- model.matrix(model)
  bread <- solve(crossprod(design))
  scores <- rowsum(design * residuals(model), data$village)
  contrasts <- water_precision_contrasts(model)
  influence <- scores %*% bread %*% t(contrasts)
  variance <- colSums(influence^2)
  shares <- sweep(influence^2, 2, variance, "/")
  do.call(rbind, lapply(seq_len(ncol(shares)), function(column) {
    data.frame(
      contrast = colnames(shares)[column], village = rownames(shares),
      score = influence[, column], squared_score_share = shares[, column]
    )
  }))
}

write_precision_audit <- function() {
  archive <- readRDS("output/fits.rds")
  main <- archive$models$T4_2
  model <- main$fit
  data <- haven::zap_labels(main$data)
  ladder <- water_precision(model, data)
  write.csv(ladder, "output/precision_ladder.csv", row.names = FALSE)
  scores <- precision_cluster_scores(model, data)
  write.csv(scores, "output/precision_cluster_scores.csv", row.names = FALSE)
  concentration <- do.call(rbind, lapply(split(scores, scores$contrast), function(group) {
    shares <- sort(group$squared_score_share, decreasing = TRUE)
    data.frame(
      contrast = group$contrast[1], largest_variance_share = shares[1],
      top_five_variance_share = sum(head(shares, 5)), inverse_concentration = 1 / sum(shares^2)
    )
  }))
  write.csv(concentration, "output/precision_concentration.csv", row.names = FALSE)
  data$water_status <- ifelse(data$ownpump == 1, ifelse(data$buywater == 1, "both", "owner"),
    ifelse(data$buywater == 1, "buyer", "neither")
  )
  data$district <- max.col(as.matrix(data[, paste0("dist", 1:25)]), ties.method = "first")
  cells <- do.call(rbind, lapply(split(data, interaction(data$domlow, data$water_status)), function(group) {
    data.frame(
      dominance = group$domlow[1], water_status = group$water_status[1], households = nrow(group),
      villages = length(unique(group$village)), districts = length(unique(group$district))
    )
  }))
  write.csv(cells, "output/precision_cells.csv", row.names = FALSE)
  district_support <- do.call(rbind, lapply(split(data, data$district), function(group) {
    data.frame(
      district = group$district[1], upper_villages = length(unique(group$village[group$domlow == 0])),
      lower_villages = length(unique(group$village[group$domlow == 1]))
    )
  }))
  write.csv(district_support, "output/precision_district_support.csv", row.names = FALSE)
  covariance <- sandwich::vcovCL(model, cluster = data$village, type = "HC1", cadjust = TRUE)
  variance_parts <- data.frame(
    term = c("dominance_variance", "buyer_interaction_variance", "twice_covariance", "full_buyer_variance"),
    value = c(
      covariance["domlow", "domlow"], covariance["dlbuywater", "dlbuywater"],
      2 * covariance["domlow", "dlbuywater"],
      sum(covariance[c("domlow", "dlbuywater"), c("domlow", "dlbuywater")])
    )
  )
  write.csv(variance_parts, "output/precision_variance_components.csv", row.names = FALSE)
  contrasts <- water_precision_contrasts(model)
  deletion_rank <- do.call(rbind, lapply(unique(data$village), function(village) {
    fit <- lm(formula(model), data = data[data$village != village, ])
    decomposition <- qr(t(model.matrix(fit)))
    basis <- qr.Q(decomposition)[, seq_len(decomposition$rank), drop = FALSE]
    remainder <- contrasts - contrasts %*% basis %*% t(basis)
    data.frame(
      village = village, rank = fit$rank, max_contrast_residual = max(abs(remainder)),
      aliases = paste(names(coef(fit))[is.na(coef(fit))], collapse = ",")
    )
  }))
  stopifnot(max(deletion_rank$max_contrast_residual) < 1e-7)
  write.csv(deletion_rank, "output/precision_deletion_rank.csv", row.names = FALSE)
  print(ladder[ladder$method %in% c("village_CR1", "village_CR2"), ], row.names = FALSE)
  invisible(ladder)
}

precision_bootstrap_fit <- function(model, data, contrast) {
  data <- haven::zap_labels(data)
  terms <- attr(terms(model), "term.labels")
  if (contrast == "buyer_gap") {
    data$domlow_nonbuyer <- data$domlow - data$dlbuywater
    terms[terms == "domlow"] <- "domlow_nonbuyer"
  }
  if (contrast == "buyer_minus_owner") {
    data$dominance_water_status <- data$dlbuywater + data$dlownpump
    terms[terms == "dlownpump"] <- "dominance_water_status"
  }
  fit <- lm(reformulate(terms, response = "cropincacre"), data = data)
  expected <- sum(water_precision_contrasts(model)[contrast, ] * coef(model))
  stopifnot(abs(coef(fit)["dlbuywater"] - expected) < 1e-7)
  fit
}

write_precision_bootstrap <- function() {
  main <- readRDS("output/fits.rds")$models$T4_2
  results <- list()
  for (contrast in c("buyer_gap", "buyer_interaction", "buyer_minus_owner")) {
    fit <- precision_bootstrap_fit(main$fit, main$data, contrast)
    for (method in c("fnw11", "31")) {
      set.seed(113779)
      dqrng::dqset.seed(113779)
      warnings <- character()
      result <- withCallingHandlers(
        fwildclusterboot::boottest(fit,
          param = "dlbuywater", clustid = "village", B = 9999,
          conf_int = method == "fnw11", type = "webb", impose_null = TRUE,
          bootstrap_type = method, engine = "R", nthreads = 1
        ),
        warning = function(condition) {
          warnings <<- c(warnings, conditionMessage(condition))
          invokeRestart("muffleWarning")
        }
      )
      interval <- if (method == "fnw11") as.numeric(result$conf_int) else c(NA_real_, NA_real_)
      results[[paste(contrast, method)]] <- data.frame(
        contrast = contrast, method = method, draws = 9999, seed = 113779, p_value = result$p_val,
        lower = interval[1], upper = interval[2],
        pseudo_inverse_warnings = sum(grepl("Pseudo-Inverse", warnings)), warnings = paste(warnings, collapse = " | ")
      )
    }
  }
  results <- do.call(rbind, results)
  write.csv(results, "output/precision_wild_bootstrap.csv", row.names = FALSE)
  print(results[, 1:7], row.names = FALSE)
  invisible(results)
}

if (sys.nframe() == 0L) {
  write_precision_audit()
  write_precision_bootstrap()
}
