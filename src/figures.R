ols <- read.csv("output/ols_tables.csv")
contrasts <- read.csv("output/water_contrasts.csv")
dir.create("figs", showWarnings = FALSE)

# All rows use the same Table 4(2) sample and village-clustered 95% t intervals.
rows <- rbind(
  ols[ols$model == "T4_2" & ols$term == "dlbuywater", c("estimate", "lower", "upper")],
  ols[ols$model == "T4_2" & ols$term == "dlownpump", c("estimate", "lower", "upper")],
  contrasts[contrasts$contrast == "buyer_minus_owner_interactions", c("estimate", "lower", "upper")]
)
labels <- c("Water-buyer interaction", "Pump-owner interaction", "Buyer minus owner")
stopifnot(nrow(rows) == 3L, all(rows$lower <= rows$estimate), all(rows$estimate <= rows$upper))
png("figs/buyers-and-owners.png", width = 1600, height = 850, res = 170, type = "cairo")
par(mar = c(5.2, 10.2, 3.8, 2.0), family = "sans", col.axis = "#242424", col.lab = "#242424")
y <- 3:1
plot(rows$estimate, y,
  xlim = range(c(rows$lower, rows$upper)) * 1.08, ylim = c(.6, 3.4),
  type = "n", axes = FALSE, xlab = "Difference in crop sales per owned acre (rupees)", ylab = ""
)
abline(v = 0, col = "#777777", lty = 2)
axis(1, at = seq(-1000, 2000, 500), lwd = 0, lwd.ticks = 1, cex.axis = .95)
axis(2, at = y, labels = labels, las = 1, tick = FALSE, cex.axis = 1)
colors <- c("#404040", "#404040", "#007A78")
segments(rows$lower, y, rows$upper, y, col = colors, lwd = 2.8)
points(rows$estimate, y, pch = 16, cex = 1.3, col = colors)
title("The buyer coefficient reproduces. Buyer-specificity is less certain.", adj = 0, cex.main = 1.02)
mtext("Table 4(2): 1,295 households in 90 villages. Bars: village-clustered 95% intervals.",
  side = 1, line = 3.6, cex = .8
)
dev.off()
