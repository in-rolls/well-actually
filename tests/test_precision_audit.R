library(testthat)
source("src/precision_audit.R")
main <- readRDS("output/fits.rds")$models$T4_2

test_that("the full buyer contrast reproduces the saved Stata-convention interval", {
  ladder <- water_precision(main$fit, main$data)
  saved <- read.csv("output/water_contrasts.csv")
  original <- ladder[ladder$method == "village_CR1" & ladder$contrast == "buyer_gap", ]
  expected <- saved[saved$contrast == "buyer_village_difference", ]
  expect_equal(original$estimate, expected$estimate, tolerance = 1e-8)
  expect_equal(original$std_error, expected$se, tolerance = 1e-8)
  expect_equal(original$lower, expected$lower, tolerance = 1e-8)
  expect_equal(original$upper, expected$upper, tolerance = 1e-8)
})

test_that("cluster-score components independently reproduce contrast variances", {
  scores <- precision_cluster_scores(main$fit, main$data)
  ladder <- water_precision(main$fit, main$data)
  n <- nrow(main$data)
  g <- length(unique(main$data$village))
  correction <- g / (g - 1) * (n - 1) / (n - main$fit$rank)
  for (name in unique(scores$contrast)) {
    group <- scores[scores$contrast == name, ]
    expected <- ladder$std_error[ladder$method == "village_CR1" & ladder$contrast == name]^2
    expect_equal(sum(group$score^2) * correction, expected, tolerance = 1e-8)
    expect_equal(sum(group$squared_score_share), 1, tolerance = 1e-12)
  }
})

test_that("bootstrap reparameterizations preserve fitted values and the targeted contrast", {
  contrasts <- water_precision_contrasts(main$fit)
  for (name in c("buyer_gap", "buyer_interaction", "buyer_minus_owner")) {
    fit <- precision_bootstrap_fit(main$fit, main$data, name)
    expect_equal(as.numeric(fitted(fit)), as.numeric(fitted(main$fit)), tolerance = 1e-7)
    expect_equal(unname(coef(fit)["dlbuywater"]), sum(contrasts[name, ] * coef(main$fit)), tolerance = 1e-7)
  }
})
