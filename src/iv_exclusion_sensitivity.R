library(ivreg)
library(sandwich)
x <- readRDS("output/fits.rds")
d <- x$ivdata
fml <- formula(x$ivfit)
b0 <- coef(x$ivfit)["dlbuywater"]
paths <- list(
  natural_water = d$naturalwater, village_area_100ha = d$area / 100,
  dominance_natural_water = d$domlow * d$naturalwater,
  dominance_area_100ha = d$domlow * d$area / 100
)
thresholds <- list()
results <- list()
for (name in names(paths)) {
  z <- paths[[name]]
  dd <- d
  dd$cropincacre <- z
  loading <- coef(ivreg(fml, data = dd))["dlbuywater"]
  threshold <- b0 / loading
  thresholds[[name]] <- data.frame(
    pathway = name, interaction_loading = loading,
    assumed_direct_effect_to_zero = threshold,
    outcome_unit = "annual_crop_sales_rupees_per_owned_acre"
  )
  for (gamma in unique(c(-1000, -500, -250, 0, 250, 500, 1000, threshold))) {
    dd$cropincacre <- d$cropincacre - gamma * z
    f <- ivreg(fml, data = dd)
    b <- coef(f)["dlbuywater"]
    se <- sqrt(vcovCL(f, cluster = d$village, type = "HC0", cadjust = FALSE)["dlbuywater", "dlbuywater"])
    stopifnot(isTRUE(all.equal(unname(b), unname(b0 - gamma * loading), tolerance = 1e-7)))
    results[[paste(name, gamma)]] <- data.frame(
      pathway = name, assumed_direct_effect = gamma,
      interaction = b, se = se, normal_lower = b - qnorm(.975) * se, normal_upper = b + qnorm(.975) * se
    )
  }
}
write.csv(do.call(rbind, thresholds), "output/iv_exclusion_thresholds.csv", row.names = FALSE)
write.csv(do.call(rbind, results), "output/iv_exclusion_sensitivity.csv", row.names = FALSE)
print(do.call(rbind, thresholds))
