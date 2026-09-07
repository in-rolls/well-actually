suppressPackageStartupMessages(library(data.table))
account_no <- NULL
prefix <- NULL
village_key <- NULL
prefix_accounts <- NULL
geography_source <- NULL

write_land_prefix_audit <- function() {
  land_dir <- normalizePath(Sys.getenv("LAND_REPO", "../land"))
  geography <- as.data.table(arrow::read_parquet("output/land_account_locations.parquet"))
  geography[, prefix := substr(account_no, 1, 10)]
  mapping <- unique(geography[, list(prefix, village_key)])
  stopifnot(!anyDuplicated(mapping$prefix))
  set.seed(113780)
  held_out <- sample.int(nrow(geography), floor(nrow(geography) / 5))
  training <- geography[-held_out]
  training_map <- training[, list(village_key = village_key[1], prefix_accounts = .N), by = prefix]
  training_map <- training_map[prefix_accounts >= 20]
  predicted <- training_map$village_key[match(geography$prefix[held_out], training_map$prefix)]
  matched <- !is.na(predicted)
  errors <- sum(predicted[matched] != geography$village_key[held_out][matched])
  stopifnot(errors == 0L)
  support <- geography[, list(prefix_accounts = .N), by = prefix]
  reliable <- support[prefix_accounts >= 20, prefix]
  reference_fields <- c("prefix", "district", "sub_division", "zone", "mauja", "village_key")
  reference <- unique(geography[prefix %in% reliable, reference_fields, with = FALSE])
  stopifnot(!anyDuplicated(reference$prefix))
  land <- as.data.table(arrow::read_parquet(file.path(land_dir, "data/records_accounts_landtype.parquet"),
    col_select = c("account_no", "area_total")
  ))
  codes <- as.character(land$account_no)
  stopifnot(all(nchar(codes) <= 16))
  land[, account_no := paste0(strrep("0", 16 - nchar(codes)), codes)]
  missing <- land[!account_no %in% geography$account_no]
  missing[, prefix := substr(account_no, 1, 10)]
  recovered <- merge(missing, reference, by = "prefix", sort = FALSE)
  stopifnot(!anyDuplicated(recovered$account_no))
  clean <- recovered$area_total <= 10000
  summary <- data.frame(
    quantity = c(
      "prefix_width", "minimum_reference_accounts", "held_out_accounts", "held_out_predictions",
      "held_out_errors", "unlinked_land_accounts", "prefix_recovered_accounts", "prefix_recovered_clean_accounts",
      "prefix_recovered_clean_acres", "prefix_recovered_villages"
    ),
    value = c(
      10, 20, length(held_out), sum(matched), errors, nrow(missing), nrow(recovered), sum(clean),
      sum(recovered$area_total[clean]), uniqueN(recovered$village_key)
    )
  )
  geography[, geography_source := "direct_raw_file"]
  recovered[, geography_source := "inferred_account_prefix"]
  fields <- c("account_no", "district", "sub_division", "zone", "mauja", "village_key", "geography_source")
  extended <- rbind(geography[, fields, with = FALSE], recovered[, fields, with = FALSE])
  stopifnot(!anyDuplicated(extended$account_no))
  arrow::write_parquet(extended, "output/land_account_locations_prefix.parquet")
  write.csv(summary, "output/land_prefix_audit.csv", row.names = FALSE)
  print(summary, row.names = FALSE)
}

compare_land_geography <- function() {
  original <- as.data.table(arrow::read_parquet("output/land_village_ownership.parquet"))
  extended <- as.data.table(arrow::read_parquet("output/land_prefix/land_village_ownership.parquet"))
  original <- original[, c("village_key", "coding", "definition", "majority"), with = FALSE]
  extended <- extended[, c("village_key", "coding", "definition", "majority"), with = FALSE]
  setnames(original, "majority", "before")
  setnames(extended, "majority", "after")
  comparison <- merge(original, extended, by = c("village_key", "coding", "definition"), all = TRUE)
  transitions <- comparison[, list(villages = .N), by = c("coding", "definition", "before", "after")]
  write.csv(transitions, "output/land_prefix_transitions.csv", row.names = FALSE)
}

if (sys.nframe() == 0L) write_land_prefix_audit()
