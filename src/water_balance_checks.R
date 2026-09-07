results <- read.csv("output/descriptive_tables.csv")
village_balance <- results[results$table == 1, ]
village_balance$villages <- village_balance$n_low + village_balance$n_high
sum_of_squares <- (village_balance$n_low - 1) * village_balance$sd_low^2 +
  (village_balance$n_high - 1) * village_balance$sd_high^2
village_balance$pooled_sd <- sqrt(sum_of_squares / (village_balance$villages - 2))
village_balance$standardized_difference <- village_balance$difference / village_balance$pooled_sd
critical_value <- qt(.975, village_balance$villages - 1)
village_balance$lower <- village_balance$difference - critical_value * village_balance$cluster_se
village_balance$upper <- village_balance$difference + critical_value * village_balance$cluster_se
village_balance$p_holm <- p.adjust(village_balance$cluster_p, "holm")
write.csv(village_balance, "output/village_balance_intervals.csv", row.names = FALSE)
stopifnot(nrow(village_balance) == 28L, all(village_balance$villages <= 90L))
