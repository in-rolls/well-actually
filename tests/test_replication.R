source("src/replicate.R")
library(testthat)
test_that("baseline matches independently archived Stata 17 output", {
  tab <- reg_results$T3_1
  expect_equal(nrow(models$T3_1$data), 1295L)
  expect_equal(length(unique(models$T3_1$data$village)), 90L)
  expect_equal(tab$estimate[tab$term == "domlow"], 566.5337, tolerance = 1e-7)
  expect_equal(tab$se[tab$term == "domlow"], 209.0335, tolerance = 2e-7)
})
test_that("manual cluster sandwich agrees for every OLS specification", {
  for (m in models) {
    fit <- m$fit
    keep <- !is.na(coef(fit))
    design <- model.matrix(fit)[, keep, drop = FALSE]
    bread <- solve(crossprod(design))
    scores <- rowsum(design * residuals(fit), m$data$village)
    n <- nrow(design)
    k <- ncol(design)
    g <- nrow(scores)
    manual <- bread %*% crossprod(scores) %*% bread * g / (g - 1) * (n - 1) / (n - k)
    vc <- sandwich::vcovCL(fit, cluster = m$data$village, type = "HC1")
    expect_equal(unname(manual), unname(vc), tolerance = 1e-6)
  }
})
test_that("manual 2SLS and structural-residual covariance agree", {
  design <- model.matrix(ivfit, component = "regressors")
  instrument_matrix <- model.matrix(ivfit, component = "instruments")
  design <- design[, !is.na(coef(ivfit)), drop = FALSE]
  qz <- qr(instrument_matrix)
  instrument_matrix <- instrument_matrix[, qz$pivot[seq_len(qz$rank)], drop = FALSE]
  projected <- qr.fitted(qr(instrument_matrix), design)
  response <- model.response(model.frame(ivfit))
  bread <- solve(crossprod(projected))
  b <- bread %*% crossprod(projected, response)
  u <- as.numeric(response - design %*% b)
  scores <- rowsum(projected * u, d$village)
  manual <- bread %*% crossprod(scores) %*% bread
  expect_equal(as.numeric(b), unname(coef(ivfit)[colnames(design)]), tolerance = 1e-7)
  calculated <- sandwich::vcovCL(ivfit,
    cluster = d$village,
    type = "HC0", cadjust = FALSE
  )
  expect_equal(unname(manual), unname(calculated), tolerance = 1e-6)
})
test_that("identifiers and deterministic interactions are intact", {
  for (dd in data) {
    id <- if ("hhcode" %in% names(dd)) "hhcode" else "village"
    expect_equal(anyDuplicated(dd[[id]]), 0L)
  }
  hh <- data$household
  for (pair in list(
    c("dlbuywater", "buywater"), c("dlownpump", "ownpump"),
    c("dltenant", "tenant"), c("dllandlord", "landlord"),
    c("dlbfrelsc", "bfrelsc"), c("dlbfhcast", "bfhcast")
  )) {
    expect_equal(as.numeric(hh[[pair[1]]]), as.numeric(hh$domlow * hh[[pair[2]]]))
  }
  expect_true(all(rowSums(hh[, paste0("dist", 1:25)]) == 1))
  positive <- hh$totland > 0
  expect_lt(max(abs(hh$cropincacre[positive] - hh$cropinc[positive] / hh$totland[positive])), .01)
})
test_that("published comparison covers every displayed Table 3 and 4 coefficient", {
  cmp <- read.csv(file.path(out, "published_regression_comparison.csv"))
  expect_equal(nrow(cmp), 54L)
  expect_true(all(cmp$within_0.1))
  expect_equal(nrow(read.csv(file.path(out, "published_descriptive_comparison.csv"))), 408L)
  expect_equal(nrow(read.csv(file.path(out, "descriptive_tables.csv"))), 68L)
  expect_equal(length(models), 14L)
})
test_that("simulation recovers planted coefficients", {
  set.seed(117)
  dd <- data.frame(village = rep(1:50, each = 10), x = rnorm(500), z = rnorm(500))
  dd$y <- 7 + 3 * dd$x - 2 * dd$z
  fit <- fit_ols(c("y", "x", "z"), dd)$fit
  expect_equal(unname(coef(fit)), c(7, 3, -2), tolerance = 1e-10)
})
test_that("original archive matches its SHA-256 manifest", {
  manifest <- read.csv("data/manifest.csv")
  actual <- vapply(manifest$file, function(path) {
    digest::digest(file = file.path("data/original", path), algo = "sha256")
  }, character(1))
  expect_identical(unname(actual), manifest$sha256)
})
cat("All replication validation tests passed.\n")

test_that("village counts preserve the regression sample", {
  counts <- read.csv("output/village_household_counts.csv")
  counts <- counts[counts$model == "T3_1", ]
  expect_equal(sum(counts$households), 1295)
  expect_equal(nrow(counts), 90L)
  expect_equal(sum(counts$households[counts$domlow == 1]), 704)
  expect_equal(range(counts$households), c(1L, 32L))
})
test_that("paired IV bootstrap reproduces the independent earlier bootstrap", {
  draws <- read.csv("output/iv_paired_bootstrap_draws.csv")
  previous <- read.csv("output/iv_pairs_bootstrap.csv")
  expect_equal(nrow(draws), 1999L)
  expect_true(all(is.finite(as.matrix(draws))))
  expect_equal(draws$difference, draws$iv - draws$ols)
  expected <- previous[previous$term == "dlbuywater", ]
  expect_equal(unname(quantile(draws$iv, .025)), expected$percentile_lower, tolerance = 1e-7)
  expect_equal(unname(quantile(draws$iv, .975)), expected$percentile_upper, tolerance = 1e-7)
})
