land_dir <- normalizePath(Sys.getenv("LAND_REPO", "../land"))
read_icpsr <- function(dataset) {
  env <- new.env()
  load(file.path(land_dir, sprintf("data/ihds2/ICPSR_36151/DS%04d/36151-%04d-Data.rda", dataset, dataset)), envir = env)
  env[[ls(env)[1]]]
}
code <- function(x) {
  if (is.factor(x)) as.numeric(sub("^\\(([0-9]+)\\).*", "\\1", as.character(x))) else as.numeric(x)
}
households <- read_icpsr(2)
villages <- read_icpsr(12)
for (name in c("STATEID", "DISTID", "PSUID")) {
  households[[name]] <- code(households[[name]])
  villages[[name]] <- code(villages[[name]])
}
key <- function(x) paste(x$STATEID, x$DISTID, x$PSUID, sep = "_")
villages$village_key <- key(villages)
households$village_key <- key(households)
stopifnot(!anyDuplicated(villages$village_key))
households$rural <- code(households$URBAN2011) == 0
households$lower_caste_hindu <- code(households$ID11) == 1 & code(households$ID13) %in% 3:5
households$buyer <- !is.na(households$FM31) & households$FM31 > 0
households$pump_owner <- rowSums(households[, c("FM40A", "FM40B", "FM40C")] > 0, na.rm = TRUE) > 0
households$has_village <- households$village_key %in% villages$village_key
village_land <- as.matrix(villages[, paste0("VJ6", LETTERS[1:9])])
village_caste <- sapply(villages[, paste0("VJ3", LETTERS[1:9])], code)
village_religion <- sapply(villages[, paste0("VJ4", LETTERS[1:9])], code)
villages$land_sum <- rowSums(village_land, na.rm = TRUE)
villages$reported_groups <- rowSums(!is.na(village_land))
villages$invalid_share <- rowSums(village_land < 0 | village_land > 100, na.rm = TRUE) > 0
feasibility <- list()
for (region in c("Bihar", "Uttar Pradesh", "UP and Bihar", "All India")) {
  states <- switch(region,
    Bihar = 10,
    "Uttar Pradesh" = 9,
    "UP and Bihar" = c(9, 10),
    "All India" = unique(households$STATEID)
  )
  h <- households[households$rural & households$STATEID %in% states, ]
  v <- villages[villages$STATEID %in% states, ]
  feasibility[[region]] <- data.frame(
    region = region, rural_households = nrow(h),
    household_psus = length(unique(h$village_key)), village_questionnaires = nrow(v),
    linked_households = sum(h$has_village), obc_sc_st_hindu_buyers = sum(h$lower_caste_hindu & h$buyer, na.rm = TRUE),
    obc_sc_st_hindu_pump_owners = sum(h$lower_caste_hindu & h$pump_owner, na.rm = TRUE),
    any_land_shares = sum(v$reported_groups > 0), land_sum_100 = sum(abs(v$land_sum - 100) < .01),
    land_sum_zero = sum(v$land_sum == 0), land_sum_above_100 = sum(v$land_sum > 100.01)
  )
  cat(
    region, ": rural households", nrow(h), "; household PSUs", length(unique(h$village_key)),
    "; village questionnaires", nrow(v), "; linked households", sum(h$has_village),
    "; lower-caste Hindu buyers", sum(h$lower_caste_hindu & h$buyer, na.rm = TRUE),
    "; lower-caste Hindu pump owners", sum(h$lower_caste_hindu & h$pump_owner, na.rm = TRUE), "\n"
  )
  cat(
    " Village land shares: any", sum(v$reported_groups > 0), "; total100", sum(abs(v$land_sum - 100) < .01),
    "; total0", sum(v$land_sum == 0), "; total>100", sum(v$land_sum > 100.01),
    "; invalidrange", sum(v$invalid_share), "\n"
  )
}
farming_fields <- grepl("CROP|FM22|FM23|FM24|FM25|ACRE|CONV|FMUNIT", names(households))
cat("Available farming fields:", names(households)[farming_fields], "\n")

target_villages <- households$village_key[households$rural & households$STATEID %in% c(9, 10)]
observed_villages <- villages[villages$village_key %in% target_villages, ]
land_matrix <- as.matrix(observed_villages[, paste0("VJ6", LETTERS[1:9])])
caste_matrix <- sapply(observed_villages[, paste0("VJ3", LETTERS[1:9])], code)
religion_matrix <- sapply(observed_villages[, paste0("VJ4", LETTERS[1:9])], code)
known_upper <- caste_matrix <= 2 & religion_matrix == 1
known_other <- caste_matrix > 2 | religion_matrix != 1
upper_min <- rowSums(ifelse(known_upper, land_matrix, 0), na.rm = TRUE)
upper_max <- 100 - rowSums(ifelse(known_other, land_matrix, 0), na.rm = TRUE)
coverage <- list()
for (threshold in c(40, 50, 60)) {
  coverage[[as.character(threshold)]] <- data.frame(
    threshold = threshold, linked_villages = nrow(observed_villages),
    definitely_above = sum(upper_min > threshold), definitely_at_or_below = sum(upper_max <= threshold),
    unresolved = sum(upper_min <= threshold & upper_max > threshold)
  )
  cat(
    "Upper-Hindu land threshold", threshold, ": definitely above", sum(upper_min > threshold),
    "; definitely at/below", sum(upper_max <= threshold),
    "; unresolved", sum(upper_min <= threshold & upper_max > threshold),
    "of", nrow(observed_villages), "linked villages\n"
  )
}
print(quantile(rowSums(land_matrix, na.rm = TRUE), c(0, .25, .5, .75, 1)))

write.csv(do.call(rbind, feasibility), "output/ihds_feasibility_counts.csv", row.names = FALSE)
write.csv(do.call(rbind, coverage), "output/ihds_dominance_coverage.csv", row.names = FALSE)
stopifnot(nrow(households) == 42152L, nrow(villages) == 1410L)
