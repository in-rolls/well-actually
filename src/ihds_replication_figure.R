estimates <- read.csv("output/ihds_replication_estimates.csv")
scenarios <- c(
  "primary", "cutoff_40", "cutoff_60", "state_effects", "equal_households", "equal_villages", "minimum_tenth_acre"
)
labels <- c(
  "Primary: 50% majority", "40% cutoff", "60% cutoff", "State effects", "Equal household weights",
  "Equal village weights", "At least 0.1 owned acre"
)
rows <- do.call(rbind, lapply(scenarios, function(scenario) {
  estimates[estimates$scenario == scenario & !is.na(estimates$contrast) & estimates$contrast == "buyer_gap", ]
}))
stopifnot(nrow(rows) == length(labels), all(is.finite(rows$estimate)))
dir.create("figs", showWarnings = FALSE)
plot_ihds_gaps <- function() {
  par(mar = c(6.5, 11.2, 4.2, 2), family = "sans", col.axis = "#242424", col.lab = "#242424")
  positions <- rev(seq_len(nrow(rows)))
  plot(rows$estimate / 1000, positions,
    type = "n", axes = FALSE,
    xlim = range(c(rows$lower, rows$upper)) / 1000 * 1.08, ylim = c(.5, nrow(rows) + .5),
    xlab = "OBC minus upper: annual crop value per owned acre (thousand rupees)", ylab = ""
  )
  abline(v = 0, col = "#888888", lty = 2)
  axis(1, lwd = 0, lwd.ticks = 1)
  axis(2, at = positions, labels = labels, las = 1, tick = FALSE, cex.axis = .92)
  colors <- c("#007A78", rep("#4C4C4C", nrow(rows) - 1))
  segments(rows$lower / 1000, positions, rows$upper / 1000, positions, col = colors, lwd = 2.6)
  points(rows$estimate / 1000, positions, pch = 16, col = colors, cex = 1.2)
  title("IHDS: the main buyer gap is negative, with wide uncertainty", adj = 0, cex.main = 1)
  mtext("Nonowner water buyers; bars are village CR2 95% intervals. Samples vary by specification.",
    side = 1, line = 5, cex = .76
  )
}
png("figs/ihds-buyer-gaps.png", width = 1800, height = 1050, res = 170, type = "cairo")
plot_ihds_gaps()
dev.off()
pdf("figs/ihds-buyer-gaps.pdf", width = 10.6, height = 6.2)
plot_ihds_gaps()
dev.off()
