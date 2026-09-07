source("src/replicate.R")
x <- readRDS(file.path(out, "fits.rds"))
h <- x$data$household
t <- x$data$table2
j <- match(h$hhcode, t$hhcode)
stopifnot(!anyDuplicated(h$hhcode), !anyDuplicated(t$hhcode), !anyNA(j))
comparison <- do.call(rbind, lapply(intersect(names(h), names(t)), function(v) {
  a <- as.numeric(h[[v]])
  b <- as.numeric(t[[v]][j])
  data.frame(
    variable = v, different_observed = sum(abs(a - b) > 1e-5, na.rm = TRUE),
    different_missingness = sum(is.na(a) != is.na(b))
  )
}))
write_result(comparison, "cross_file_comparison.csv")
h$original_water_missing <- is.na(t$buywater[j])
h$district <- max.col(as.matrix(h[, paste0("dist", 1:25)]), ties.method = "first")
write_result(
  aggregate(cbind(
    n = rep(1, nrow(h)), landless = as.integer(h$totland == 0),
    positive_sales = as.integer(h$cropincacre > 0)
  ) ~ original_water_missing + domlow, h, sum),
  "water_missingness.csv"
)
d <- models$T4_2$data
d$original_water_missing <- h$original_water_missing[match(d$hhcode, h$hhcode)]
f <- lm(formula(models$T4_2$fit), data = d[!d$original_water_missing, ])
dd <- d[!d$original_water_missing, ]
write_result(coefficient_table(f, dd, "T4_2:observed_water_status"), "observed_water_status.csv")
write_result(aggregate(cropincacre ~ domlow + buywater, d, function(a) {
  c(n = length(a), mean = mean(a), sd = sd(a), zero = mean(a == 0))
}), "water_cells.csv")
# The sample is fixed here; positive sales and positive revenues conditional on sales are different outcomes.
d$positive_sales <- as.numeric(d$cropincacre > 0)
f <- lm(update(formula(models$T4_2$fit), positive_sales ~ .), data = d)
write_result(coefficient_table(f, d, "T4_2:positive_sales_probability"), "sales_participation.csv")
u <- unique(h[!is.na(h$domlow), c("district", "village", "domlow")])
write_result(as.data.frame.matrix(table(u$district, u$domlow)), "district_overlap.csv")
# Reproduce the two actual first stages, including clustered excluded-instrument tests.
d <- x$ivdata
first_stages <- list()
first_tests <- list()
for (response in c("buywater", "dlbuywater")) {
  f <- lm(reformulate(c(exog, instruments), response = response), data = d)
  tab <- coefficient_table(f, d, paste0("T5_FS_", response))
  first_stages[[response]] <- tab
  v <- sandwich::vcovCL(f, cluster = d$village, type = "HC1")
  b <- coef(f)[instruments]
  fstat <- drop(t(b) %*% solve(v[instruments, instruments], b)) / length(instruments)
  first_tests[[response]] <- data.frame(
    response = response, F = fstat,
    df1 = length(instruments), df2 = length(unique(d$village)) - 1
  )
}
write_result(do.call(rbind, first_stages), "iv_first_stages.csv")
write_result(do.call(rbind, first_tests), "iv_first_stage_tests.csv")
# Direct excluded instruments are a different IV specification, not a correction.
d$dlarea <- d$domlow * d$area
d$dlnaturalwater <- d$domlow * d$naturalwater
raw_inst <- c("area", "naturalwater", "dlarea", "dlnaturalwater")
fml <- as.formula(paste(
  y, "~", paste(c(exog, endog), collapse = " + "), "|",
  paste(c(exog, raw_inst), collapse = " + ")
))
f <- ivreg::ivreg(fml, data = d)
write_result(coefficient_table(f, d, "T5_IV:raw_instruments", iv = TRUE), "iv_raw_instruments.csv")
# Null-imposed Anderson-Rubin joint test of both endogenous coefficients equal to zero.
f <- lm(reformulate(c(exog, raw_inst), response = y), data = d)
v <- sandwich::vcovCL(f, cluster = d$village, type = "HC1")
b <- coef(f)[raw_inst]
ar <- drop(t(b) %*% solve(v[raw_inst, raw_inst], b)) / length(raw_inst)
write_result(
  data.frame(
    null = "buywater = dlbuywater = 0", F = ar, df1 = 4,
    df2 = length(unique(d$village)) - 1, p = pf(ar, 4, length(unique(d$village)) - 1, lower.tail = FALSE)
  ),
  "iv_joint_AR.csv"
)
# Resample villages and re-estimate both the generated instruments and 2SLS.
set.seed(113778)
clusters <- unique(d$village)
pre_formula <- formula(models$T5_1$fit)
boot <- matrix(NA_real_, 1999, 3, dimnames = list(NULL, c("domlow", "buywater", "dlbuywater")))
for (i in seq_len(nrow(boot))) {
  selected <- sample(clusters, length(clusters), replace = TRUE)
  dd <- do.call(rbind, lapply(selected, function(g) d[d$village == g, ]))
  pre <- lm(pre_formula, data = dd)
  dd$bwx <- fitted(pre)
  dd$dlbwx <- dd$domlow * dd$bwx
  fit <- tryCatch(suppressWarnings(ivreg::ivreg(ivformula, data = dd)), error = function(e) NULL)
  if (!is.null(fit)) boot[i, ] <- coef(fit)[colnames(boot)]
}
write_result(as.data.frame(boot), "iv_pairs_bootstrap_draws.csv")
bs <- do.call(rbind, lapply(seq_len(ncol(boot)), function(k) {
  good <- is.finite(boot[, k])
  ci <- quantile(boot[good, k], c(.025, .5, .975))
  data.frame(
    term = colnames(boot)[k], B = nrow(boot), valid = sum(good), seed = 113778,
    percentile_lower = ci[1], median = ci[2], percentile_upper = ci[3], sd = sd(boot[good, k])
  )
}))
write_result(bs, "iv_pairs_bootstrap.csv")
cat("Diagnostics completed\n")
print(bs, row.names = FALSE)
