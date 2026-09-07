library(testthat)

test_that("external feasibility counts preserve the household-village join", {
  counts <- read.csv("output/ihds_feasibility_counts.csv")
  target <- counts[counts$region == "UP and Bihar", ]
  states <- counts[counts$region %in% c("Bihar", "Uttar Pradesh"), ]
  expect_equal(target$rural_households, sum(states$rural_households))
  expect_equal(target$household_psus, sum(states$household_psus))
  expect_equal(target$linked_households, target$rural_households)
  expect_equal(target$rural_households, 3789)
  expect_equal(target$household_psus, 195)
})

test_that("dominance uncertainty partitions the villages at every threshold", {
  coverage <- read.csv("output/ihds_dominance_coverage.csv")
  expect_equal(
    coverage$definitely_above + coverage$definitely_at_or_below + coverage$unresolved,
    coverage$linked_villages
  )
  expect_true(all(diff(coverage$definitely_above) <= 0))
  expect_true(all(diff(coverage$definitely_at_or_below) >= 0))
})
