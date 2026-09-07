library(testthat)
source("src/dominance_sensitivity.R")

test_that("classification changes a whole village and rebuilds both interactions", {
  example <- data.frame(
    village = c(1, 1, 2, 2), domlow = c(0, 0, 1, 1),
    buywater = c(0, 1, 1, 1), ownpump = c(1, 0, 0, 1)
  )
  example$dlbuywater <- example$domlow * example$buywater
  example$dlownpump <- example$domlow * example$ownpump
  changed <- classify_village(example, 1)
  expect_equal(changed$domlow, c(1, 1, 1, 1))
  expect_equal(changed$dlbuywater, c(0, 1, 1, 1))
  expect_equal(changed$dlownpump, c(1, 0, 0, 1))
  expect_equal(classify_village(changed, 1), example)
})

test_that("the exhaustive audit preserves sample sizes and original contrasts", {
  results <- read.csv("output/dominance_single_flip.csv")
  expect_equal(nrow(results), 4 * 91L)
  expect_true(all(results$n == 1295 & results$villages == 90))
  for (rows in split(results, results$specification)) {
    expect_equal(sum(is.na(rows$flipped_village)), 1L)
    expect_equal(length(unique(na.omit(rows$flipped_village))), 90L)
    expect_equal(sum(rows$households_reclassified), 1295)
  }
  reference <- read.csv("output/water_contrasts.csv")
  buyer <- results[results$specification == "buyer_village_gap" & is.na(results$flipped_village), ]
  expect_equal(buyer$estimate, reference$estimate[reference$contrast == "buyer_village_difference"])
  expect_equal(buyer$standard_error, reference$se[reference$contrast == "buyer_village_difference"])
})
