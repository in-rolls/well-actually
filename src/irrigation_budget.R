contrast <- read.csv("output/water_contrasts.csv")
b <- contrast[contrast$contrast == "buyer_village_difference", ]
acre_m2 <- 4046.8564224
litres_per_load <- 10000
out <- data.frame(additional_depth_mm = c(10, 25, 50, 100))
out$litres_per_acre <- out$additional_depth_mm * acre_m2
out$loads_10000_litres <- out$litres_per_acre / litres_per_load
out$whole_loads <- ceiling(out$loads_10000_litres)
out$annual_sales_difference_per_owned_acre <- b$estimate
out$extra_cost_per_whole_load_covered <- b$estimate / out$whole_loads
out$lower_sales_difference_per_load <- b$lower / out$whole_loads
out$upper_sales_difference_per_load <- b$upper / out$whole_loads
stopifnot(out$whole_loads[out$additional_depth_mm == 50] == 21)
write.csv(out, "output/irrigation_break_even.csv", row.names = FALSE)
print(out)
