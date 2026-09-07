suppressPackageStartupMessages(library(arrow))
suppressPackageStartupMessages(library(data.table))
land_dir <- normalizePath(Sys.getenv("LAND_REPO", "../land"))
land <- as.data.table(read_parquet(
  file.path(land_dir, "data/records_accounts_landtype.parquet"),
  col_select = c("account_no", "area_total", "cat4")
))
geo <- as.data.table(read_parquet(
  file.path(land_dir, "data/account_geo.parquet"),
  col_select = c("account_no", "village_key")
))
geo[, account_no := bit64::as.integer64(account_no)]
stopifnot(!anyDuplicated(land$account_no), !anyDuplicated(geo$account_no), !anyNA(geo$account_no))
land[, usable_area := area_total <= 10000]
linked <- land[geo, on = "account_no", nomatch = NULL]
summary <- data.frame(
  quantity = c(
    "land_accounts", "geography_accounts", "linked_accounts", "unlinked_land_accounts",
    "linked_villages", "clean_accounts", "linked_clean_accounts", "clean_area", "linked_clean_area",
    "clean_area_without_stored_category", "linked_clean_area_without_stored_category"
  ),
  value = c(
    nrow(land), nrow(geo), nrow(linked), nrow(land) - nrow(linked), uniqueN(linked$village_key),
    sum(land$usable_area), sum(linked$usable_area), land[usable_area == TRUE, sum(area_total)],
    linked[usable_area == TRUE, sum(area_total)], land[usable_area == TRUE & is.na(cat4), sum(area_total)],
    linked[usable_area == TRUE & is.na(cat4), sum(area_total)]
  )
)
write.csv(summary, "output/land_readiness.csv", row.names = FALSE)
print(summary, row.names = FALSE)
