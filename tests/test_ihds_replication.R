library(testthat)
source("src/ihds_replication_data.R")
source("src/ihds_replication.R")

test_that("numeric labels are parsed rather than factor positions", {
  expect_equal(ihds_code(factor(c("(09) Uttar Pradesh", "(01) Other", NA))), c(9, 1, NA))
  expect_error(ihds_code(factor("Unlabelled")))
})

test_that("unknown land can belong to either group and cannot be renormalized", {
  shares <- rbind(c(40, 35, 25), c(40, 30, NA), c(55, 20, NA), c(NA, NA, NA), c(80, 30, NA))
  castes <- matrix(rep(c(1, 3, 4), 5), nrow = 5, byrow = TRUE)
  religions <- matrix(1, 5, 3)
  bounds <- land_share_bounds(shares, castes, religions, 1:2)
  expect_equal(bounds$lower, c(40, 40, 55, 0, NA))
  expect_equal(bounds$upper, c(40, 70, 80, 100, NA))
  obc <- land_share_bounds(shares, castes, religions, 3)
  data <- data.frame(upper_min = bounds$lower, upper_max = bounds$upper, obc_min = obc$lower, obc_max = obc$upper)
  expect_equal(classify_ihds_dominance(data), c(NA, NA, 0, NA, NA))
  religions[3, 1] <- 2
  expect_equal(land_share_bounds(shares, castes, religions, 1:2)$lower[3], 0)
  expect_equal(land_share_bounds(shares, castes, religions, 1:2)$upper[3], 25)
})

test_that("seasonal area and pump status preserve unknowns", {
  areas <- rbind(c(2, 2, 2), c(2, 3, 2), c(2, NA, 2), c(0, 0, 0))
  expect_equal(seasonal_area(areas, c(2, 2, 2, 2)), c(1, 1.5, NA, 0))
  expect_equal(seasonal_area(areas, c(2, 2, 2, 0), "sum"), c(3, 3.5, NA, NA))
  pumps <- rbind(c(0, 0, 0), c(1, NA, NA), c(0, NA, 0), c(NA, NA, NA), c(-1, 1, 0))
  expect_equal(pump_status(pumps), c(0, 1, NA, NA, NA))
})

synthetic_ihds <- function() {
  set.seed(8)
  data <- expand.grid(village = 1:40, person = 1:12)
  data$village_key <- as.character(data$village)
  data$dominance <- as.numeric(data$village > 20)
  data$water_status <- factor(rep(c("buyer", "owner", "both", "neither"), each = 120),
    levels = c("buyer", "owner", "both", "neither")
  )
  data$household_size <- sample(1:8, nrow(data), TRUE)
  data$education <- sample(0:12, nrow(data), TRUE)
  data$sc <- sample(0:1, nrow(data), TRUE)
  data$geography <- factor(data$village %% 4)
  data$analysis_weight <- runif(nrow(data), .5, 2)
  data$outcome <- 100 + data$dominance * ifelse(data$water_status == "buyer", 45, 10) + rnorm(nrow(data))
  data
}

test_that("contrasts recover known gaps and an independent WLS fit", {
  data <- synthetic_ihds()
  fit <- fit_ihds_model(data)
  independent <- lm.wfit(fit$model$x, data$outcome, data$analysis_weight)
  expect_equal(unname(coef(fit$model)), unname(independent$coefficients), tolerance = 1e-9)
  results <- fit$results
  expect_equal(results$estimate[1], 45, tolerance = 1)
  expect_equal(results$estimate[2], 10, tolerance = 1)
  expect_equal(results$estimate[5], results$estimate[1] - results$estimate[2], tolerance = 1e-10)
  expect_true(all(results$lower < results$estimate & results$upper > results$estimate))
  expect_true(all(is.finite(results$df)))
})

test_that("sparse exposure groups are retained as unsupported", {
  data <- synthetic_ihds()
  data <- data[data$dominance == 0 | data$village %in% 21:22, ]
  expect_error(fit_ihds_model(data), "Fewer than five")
})

test_that("an absent owner reference cell does not destroy the buyer contrast", {
  data <- synthetic_ihds()
  data <- data[!(data$dominance == 0 & data$water_status == "owner"), ]
  fit <- fit_ihds_model(data)
  expect_true(is.finite(fit$results$estimate[1]))
  expect_true(all(is.na(fit$results$estimate[c(2, 5)])))
  expect_true(all(fit$results$status[c(2, 5)] == "not_estimable"))
  expect_equal(fit$results$estimate[1], 45, tolerance = 1)
})

source("src/ihds_replication_inference.R")
test_that("square-root weighting preserves WLS coefficients and cluster scores", {
  primary <- fit_ihds_model(synthetic_ihds())
  equivalent <- weighted_ihds_equivalent(primary)
  expect_equal(unname(coef(equivalent)), unname(coef(primary$model)), tolerance = 1e-9)
  original <- clubSandwich::vcovCR(primary$model, cluster = primary$data$village_key, type = "CR0", inverse_var = FALSE)
  transformed <- clubSandwich::vcovCR(equivalent, cluster = primary$data$village_key, type = "CR0", inverse_var = FALSE)
  expect_equal(unname(as.matrix(original)), unname(as.matrix(transformed)), ignore_attr = TRUE, tolerance = 1e-9)
})

test_that("empty sensitivity samples and unknown exposure definitions are explicit", {
  cells <- support_cells(synthetic_ihds()[FALSE, ], "empty")
  expect_equal(cells$n, 0L)
  expect_equal(cells$villages, 0L)
  expect_error(classify_ihds_dominance(data.frame(), definition = "misspelled"))
})

test_that("bootstrap point fits use the same identified contrasts", {
  data <- synthetic_ihds()
  values <- point_ihds_contrasts(data)
  expect_equal(unname(values[1]), 45, tolerance = 1)
  expect_equal(unname(values[2]), 35, tolerance = 1)
})
