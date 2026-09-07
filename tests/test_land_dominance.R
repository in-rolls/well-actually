library(testthat)
source("src/land_dominance.R")
source("src/land_geography_audit.R")

test_that("a largest caste need not own a majority and unknown land stays in the denominator", {
  fixture <- data.table(
    upper = c(40, 51, 35, 50), obc = c(35, 25, 30, 50), sc = c(25, 10, 0, 0), st = 0,
    muslim = 0, unknown = c(0, 14, 35, 0), total_acres = 100
  )
  result <- ownership_bounds(fixture)
  expect_equal(result$majority, c("none", "upper", "unresolved", "none"))
  expect_equal(result$guaranteed_largest, c(TRUE, TRUE, FALSE, FALSE))
  expect_equal(result$largest_known_share, c(.4, .51, .35, .5))
  expect_equal(classify_ownership(.35, .7, .5), "unresolved")
  expect_equal(classify_ownership(.5, .5, .5), "at_or_below")
})

test_that("duplicate plot rows are harmless but conflicting account locations are detected", {
  locations <- data.table(
    account_no = c("01", "01", "02", "02"),
    district = "d", sub_division = "s", zone = "z", mauja = c("a", "a", "a", "b")
  )
  result <- count_account_locations(locations)
  expect_equal(result$locations, c(1L, 2L))
  expect_equal(result$account_no, c("01", "02"))
})

test_that("every village is counted once in each threshold classification and cutoffs are nested", {
  results <- read.csv("output/land_ownership_thresholds.csv")
  summary <- read.csv("output/land_ownership_summary.csv")
  for (policy in unique(results$coding)) {
    for (area in unique(results$definition)) {
      subset <- results[results$coding == policy & results$definition == area, ]
      expected <- summary$villages[summary$coding == policy & summary$definition == area]
      expect_true(all(tapply(subset$villages, list(subset$group, subset$threshold), sum) == expected))
      for (category in unique(subset$group)) {
        above <- subset[subset$group == category & subset$classification == "above", ]
        below <- subset[subset$group == category & subset$classification == "at_or_below", ]
        expect_true(all(diff(above$villages[order(above$threshold)]) <= 0))
        expect_true(all(diff(below$villages[order(below$threshold)]) >= 0))
      }
    }
  }
})

test_that("updating caste codes changes neither land acreage nor geography coverage", {
  coverage <- read.csv("output/land_ownership_coverage.csv")
  totals <- aggregate(cbind(accounts, acres) ~ coding + definition + linked, coverage, sum)
  original <- totals[totals$coding == "base", ]
  updated <- totals[totals$coding == "curated", ]
  ordering <- function(x) x[order(x$definition, x$linked), c("accounts", "acres")]
  rownames(original) <- rownames(updated) <- NULL
  expect_equal(unname(as.matrix(ordering(original))), unname(as.matrix(ordering(updated))), tolerance = 1e-10)
  recodes <- read.csv("output/land_recode_audit.csv")
  expect_true(all(recodes$conflicts == 0))
})

test_that("the prefix extension reallocates geography without adding land or accounts", {
  original <- read.csv("output/land_ownership_coverage.csv")
  extended <- read.csv("output/land_prefix/land_ownership_coverage.csv")
  totals <- function(data) {
    result <- aggregate(cbind(accounts, acres) ~ coding + definition + group, data, sum)
    result[order(result$coding, result$definition, result$group), ]
  }
  expect_equal(totals(original), totals(extended), tolerance = 1e-9)
})
