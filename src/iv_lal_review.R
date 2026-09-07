library(ivreg)
library(sandwich)
x <- readRDS("output/fits.rds")
d <- x$ivdata
iv_formula <- formula(x$ivfit)
pre_formula <- formula(x$models$T5_1$fit)
endogenous <- c("buywater", "dlbuywater")
excluded <- c("bwx", "dlbwx")
exogenous <- setdiff(attr(terms(x$ivfit, component = "regressors"), "term.labels"), endogenous)
ols_formula <- reformulate(c(exogenous, endogenous), response = "cropincacre")
ols <- lm(ols_formula, d)
terms_keep <- c("domlow", endogenous)
baseline <- do.call(rbind, lapply(list(OLS = ols, IV = x$ivfit), function(f) {
  is_iv <- inherits(f, "ivreg")
  v <- vcovCL(f, cluster = d$village, type = if (is_iv) "HC0" else "HC1", cadjust = !is_iv)
  data.frame(
    estimator = if (is_iv) "IV" else "OLS", term = terms_keep,
    estimate = coef(f)[terms_keep], se = sqrt(diag(v))[terms_keep], n = nrow(d), villages = length(unique(d$village))
  )
}))
write.csv(baseline, "output/iv_ols_same_sample.csv", row.names = FALSE)
fs <- do.call(rbind, lapply(endogenous, function(response) {
  full <- lm(reformulate(c(exogenous, excluded), response), d)
  restricted <- lm(reformulate(exogenous, response), d)
  b <- coef(full)[excluded]
  vc <- vcovCL(full, cluster = d$village, type = "HC1")
  data.frame(
    response = response, iid_F = anova(restricted, full)$F[2],
    cluster_F = drop(t(b) %*% solve(vc[excluded, excluded], b)) / 2,
    partial_R2 = 1 - sum(residuals(full)^2) / sum(residuals(restricted)^2), numerator_df = 2,
    cluster_denominator_df = length(unique(d$village)) - 1
  )
}))
write.csv(fs, "output/iv_first_stage_comparison.csv", row.names = FALSE)
# A paired cluster bootstrap compares IV and OLS on identical resampled villages.
set.seed(113778)
clusters <- unique(d$village)
n_boot <- 1999L
boot <- matrix(NA_real_, n_boot, 5, dimnames = list(NULL, c("iv", "iv_se", "ols", "difference", "studentized")))
for (i in seq_len(n_boot)) {
  selected <- sample(clusters, length(clusters), replace = TRUE)
  dd <- do.call(rbind, lapply(seq_along(selected), function(j) {
    z <- d[d$village == selected[j], ]
    z$bootstrap_village <- j
    z
  }))
  preliminary <- lm(pre_formula, dd)
  dd$bwx <- fitted(preliminary)
  dd$dlbwx <- dd$domlow * dd$bwx
  f <- suppressWarnings(ivreg(iv_formula, data = dd))
  o <- lm(ols_formula, dd)
  estimate <- coef(f)["dlbuywater"]
  se <- sqrt(vcovCL(f, cluster = dd$bootstrap_village, type = "HC0", cadjust = FALSE)["dlbuywater", "dlbuywater"])
  boot[i, ] <- c(
    estimate, se, coef(o)["dlbuywater"], estimate - coef(o)["dlbuywater"],
    (estimate - coef(x$ivfit)["dlbuywater"]) / se
  )
}
write.csv(boot, "output/iv_paired_bootstrap_draws.csv", row.names = FALSE)
b_iv <- baseline$estimate[baseline$estimator == "IV" & baseline$term == "dlbuywater"]
s_iv <- baseline$se[baseline$estimator == "IV" & baseline$term == "dlbuywater"]
b_ols <- baseline$estimate[baseline$estimator == "OLS" & baseline$term == "dlbuywater"]
q_t <- quantile(boot[, "studentized"], c(.025, .975), na.rm = TRUE)
summary <- data.frame(
  statistic = c("IV_percentile", "IV_studentized", "IV_minus_OLS_percentile"),
  estimate = c(b_iv, b_iv, b_iv - b_ols),
  lower = c(quantile(boot[, "iv"], .025), b_iv - q_t[2] * s_iv, quantile(boot[, "difference"], .025)),
  upper = c(quantile(boot[, "iv"], .975), b_iv - q_t[1] * s_iv, quantile(boot[, "difference"], .975)),
  B = n_boot, seed = 113778
)
write.csv(summary, "output/iv_lal_bootstrap_summary.csv", row.names = FALSE)
print(baseline)
print(fs)
print(summary)
cat("IV/OLS same-sample ratio:", b_iv / b_ols, "\n")
