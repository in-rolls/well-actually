library(ivreg)
out <- "output"
paper <- readLines("sources/paper.txt", warn = FALSE)
nums <- function(line) {
  line <- gsub("−", "-", line, fixed = TRUE)
  line <- sub("^.*? {2,}(?=-?[0-9])", "", line, perl = TRUE)
  matches <- regmatches(line, gregexpr("-?[0-9][0-9,]*(\\.[0-9]+)?", line))[[1]]
  as.numeric(gsub(",", "", matches, fixed = TRUE))
}
block <- function(start, end) {
  a <- grep(start, paper, fixed = TRUE)[1]
  b <- grep(end, paper, fixed = TRUE)
  paper[seq.int(a, b[b > a][1] - 1)]
}
actual <- read.csv(file.path(out, "descriptive_tables.csv"))
actual$pooled_se <- abs(actual$difference / actual$t)
published <- list()
for (tab in c(1, 2)) {
  first <- if (tab == 1) "Number of households" else "Literate                                     0.33"
  a <- grep(first, paper, fixed = TRUE)[1]
  count <- if (tab == 1) 28 else 16
  rows <- paper[a + seq_len(count) - 1]
  parsed <- t(vapply(rows, nums, numeric(6)))
  d <- actual[actual$table == tab, ]
  scale <- rep(1, count)
  if (tab == 1) scale[d$variable %in% c("hhlless", "hhelec")] <- 100
  if (tab == 2) scale[d$variable == "landirr"] <- 100
  for (i in seq_len(count)) {
    observed <- unlist(d[i, c("mean_high", "sd_high", "mean_low", "sd_low", "difference", "pooled_se")]) / scale[i]
    published[[paste(tab, i)]] <- data.frame(
      table = tab, variable = d$variable[i],
      statistic = c("mean_high", "sd_high", "mean_low", "sd_low", "difference", "pooled_se"),
      published = parsed[i, ], reproduced = as.numeric(observed), source_line = rows[i]
    )
  }
}
a <- grep("Acres cultivated            883.8", paper, fixed = TRUE)[1]
rows <- paper[a + 0:23]
for (i in 1:12) {
  means <- nums(rows[2 * i - 1])
  ses <- nums(rows[2 * i])
  stopifnot(length(means) == 6, length(ses) == 6)
  for (panel in 1:2) {
    d <- actual[actual$table == 6, ][i + 12 * (panel - 1), ]
    k <- 3 * (panel - 1) + 1:3
    observed <- c(d$mean_high, d$mean_low, -d$difference, d$sd_high, d$sd_low, d$pooled_se)
    published[[paste(6, panel, i)]] <- data.frame(
      table = 6, variable = d$variable,
      statistic = c("mean_high", "mean_low", "difference_high_minus_low", "sd_high", "sd_low", "pooled_se"),
      published = c(means[k], ses[k]), reproduced = observed, source_line = paste(rows[2 * i - 1], rows[2 * i])
    )
  }
}
result <- do.call(rbind, published)
result$error <- result$reproduced - result$published
write.csv(result, file.path(out, "published_descriptive_comparison.csv"), row.names = FALSE)
add <- function(table, term, columns, est, se) {
  data.frame(
    model = paste0("T", table, "_", columns), term = term,
    published_estimate = est, published_se = se
  )
}
reg <- list(
  add(3, "literate", 1:6, c(255, 294.9, 163.7, 297.4, 288.6, 224.4), c(141.7, 115.4, 127.7, 158.3, 145.6, 104.4)),
  add(3, "totland", 1:6, c(58.5, 52.7, 47.8, 55.9, 65.6, 50.9), c(18.4, 18.1, 17.9, 19.6, 20.5, 15.6)),
  add(3, "domlow", 1:6, c(566.5, 393.3, 387.2, 505.6, 668.5, 371.3), c(209, 191.6, 161.8, 198.6, 254.9, 167.6)),
  add(
    4, "domlow", 1:7,
    c(346.2, -88, 19, -162.1, 48.1, 654.4, 740.7),
    c(196.2, 165.9, 137.1, 186.3, 175, 245.9, 259.7)
  ),
  add(4, "ownpump", 1:5, c(1119.6, 865.7, 755.8, 841, 703.3), c(260, 474.4, 497, 532.7, 524.1)),
  add(4, "buywater", 1:5, c(318.1, -143, 43.4, -233.9, -225.7), c(127.9, 174.9, 193, 171.7, 172.6)),
  add(4, "dlownpump", 2:5, c(388.5, 365.3, 773.2, 654.8), c(500.4, 593.9, 682, 600.1)),
  add(4, "dlbuywater", 2:5, c(850.9, 602.1, 980.7, 901.8), c(275, 254.4, 333.9, 273.7)),
  add(4, "tenant", 6, 79.3, 106.1),
  add(4, "landlord", 6, -324.2, 173),
  add(4, "bfrelsc", 7, -234.8, 125),
  add(4, "bfhcast", 7, -28.6, 161),
  add(4, "dltenant", 6, -420.7, 289),
  add(4, "dllandlord", 6, 189.6, 323.2),
  add(4, "dlbfrelsc", 7, -482.7, 292.2),
  add(4, "dlbfhcast", 7, -542.5, 318.7),
  add(5, "domlow", "IV", -1522.8, 814.1),
  add(5, "buywater", "IV", 202.1, 931.6),
  add(5, "dlbuywater", "IV", 3519.5, 1413.7)
)
published_reg <- do.call(rbind, reg)
write.csv(published_reg, "sources/published_regression.csv", row.names = FALSE)
actual_reg <- rbind(read.csv(file.path(out, "ols_tables.csv")), read.csv(file.path(out, "iv_table.csv")))
compare <- merge(published_reg, actual_reg, by = c("model", "term"), all.x = TRUE)
compare$estimate_error <- compare$estimate - compare$published_estimate
compare$se_error <- compare$se - compare$published_se
compare$within_0.1 <- abs(compare$estimate_error) <= .1 & abs(compare$se_error) <= .1
write.csv(compare, file.path(out, "published_regression_comparison.csv"), row.names = FALSE)
fits <- readRDS(file.path(out, "fits.rds"))$models
metadata <- do.call(rbind, lapply(names(fits)[!grepl("T5", names(fits))], function(id) {
  m <- fits[[id]]
  s <- summary(m$fit)
  data.frame(
    model = id, published_n = 1295, reproduced_n = nrow(m$data),
    r_squared = s$r.squared, adjusted_r_squared = s$adj.r.squared
  )
}))
write.csv(metadata, file.path(out, "published_sample_comparison.csv"), row.names = FALSE)
cat(
  nrow(compare), "published regression coefficients and SEs checked;",
  sum(compare$within_0.1), "pairs within 0.1.\n"
)
print(compare[!compare$within_0.1, ])
print(metadata[metadata$published_n != metadata$reproduced_n, ])
