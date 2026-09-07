library(sandwich)
x <- readRDS("output/fits.rds")
counts <- list()
summaries <- list()
estimates <- list()
for (id in c("T3_1", "T3_2", "T4_2")) {
  m <- x$models[[id]]
  d <- m$data
  villages <- aggregate(rep(1, nrow(d)), d[c("village", "domlow", "bihar")], sum)
  names(villages)[4] <- "households"
  villages$model <- id
  counts[[id]] <- villages
  for (g in c(-1, 0, 1)) {
    z <- if (g == -1) villages else villages[villages$domlow == g, ]
    n <- z$households
    summaries[[paste(id, g)]] <- data.frame(
      model = id, dominance = g, villages = length(n), households = sum(n),
      minimum = min(n), p25 = unname(quantile(n, .25)), median = median(n), p75 = unname(quantile(n, .75)),
      maximum = max(n), largest_share = max(n) / sum(n),
      top10_share = sum(sort(n, decreasing = TRUE)[seq_len(min(10, length(n)))]) / sum(n),
      size_effective_villages = sum(n)^2 / sum(n^2)
    )
  }
  d$inverse_village_size <- 1 / ave(rep(1, nrow(d)), d$village, FUN = sum)
  f <- lm(formula(m$fit), d, weights = inverse_village_size)
  v <- vcovCL(f, cluster = d$village, type = "HC1")
  term <- if (id == "T4_2") "dlbuywater" else "domlow"
  b <- coef(f)[term]
  se <- sqrt(v[term, term])
  estimates[[id]] <- data.frame(
    model = id, weighting = "equal_total_weight_per_village", term = term,
    estimate = b, se = se, p = 2 * pt(-abs(b / se), nrow(villages) - 1)
  )
}
write.csv(do.call(rbind, counts), "output/village_household_counts.csv", row.names = FALSE)
write.csv(do.call(rbind, summaries), "output/village_size_summary.csv", row.names = FALSE)
write.csv(do.call(rbind, estimates), "output/equal_village_weight.csv", row.names = FALSE)
print(do.call(rbind, summaries))
print(do.call(rbind, estimates))
