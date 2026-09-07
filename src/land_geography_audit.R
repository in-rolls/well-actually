suppressPackageStartupMessages(library(data.table))
account_no <- NULL
village_key <- NULL
district <- NULL
zone <- NULL
mauja <- NULL
sub_division <- NULL

count_account_locations <- function(locations) {
  unique(locations)[, list(locations = .N), by = account_no]
}

write_land_geography_audit <- function() {
  land_dir <- normalizePath(Sys.getenv("LAND_REPO", "../land"))
  source <- file.path(land_dir, "data/account.csv.gz")
  parts <- list()
  rows <- 0L
  missing_accounts <- 0L
  parse_problems <- 0L
  callback <- readr::SideEffectChunkCallback$new(function(chunk, position) {
    parse_problems <<- parse_problems + nrow(readr::problems(chunk))
    chunk <- as.data.table(chunk)
    setnames(
      chunk, c("Account_Holder_No", "District", "Sub_Division", "Zone", "Mauja"),
      c("account_no", "district", "sub_division", "zone", "mauja")
    )
    rows <<- rows + nrow(chunk)
    missing_accounts <<- missing_accounts + sum(is.na(chunk$account_no))
    parts[[length(parts) + 1L]] <<- unique(chunk[!is.na(account_no)])
    message("Scanned ", format(rows, big.mark = ","), " raw rows")
  })
  readr::read_csv_chunked(source, callback,
    chunk_size = 1000000,
    col_types = readr::cols_only(
      Account_Holder_No = readr::col_character(), District = readr::col_character(),
      Sub_Division = readr::col_character(), Zone = readr::col_character(), Mauja = readr::col_character()
    ), trim_ws = FALSE, progress = FALSE
  )
  stopifnot(parse_problems == 0L)
  locations <- unique(rbindlist(parts))
  rm(parts)
  counts <- count_account_locations(locations)
  valid <- locations[counts[locations == 1L], on = "account_no"]
  valid[, village_key := paste(district, zone, mauja, sep = "|")]
  complete <- complete.cases(valid[, list(district, sub_division, zone, mauja)])
  valid <- valid[complete]
  places <- unique(valid[, list(village_key, district, sub_division, zone, mauja)])
  stopifnot(!anyDuplicated(places$village_key))
  stopifnot(!anyDuplicated(valid$account_no), all(grepl("^[0-9]{16}$", valid$account_no)))
  stored <- as.data.table(arrow::read_parquet(file.path(land_dir, "data/account_geo.parquet")))
  stopifnot(!anyDuplicated(stored$account_no))
  index <- match(valid$account_no, stored$account_no)
  disagreements <- sum(!is.na(index) & valid$village_key != stored$village_key[index], na.rm = TRUE)
  summary <- data.frame(
    quantity = c(
      "raw_rows", "missing_account_rows", "parse_problems", "unique_accounts",
      "accounts_multiple_locations", "accounts_single_location_incomplete_geography", "verified_accounts",
      "verified_villages", "verified_accounts_absent_from_stored", "stored_village_disagreements"
    ),
    value = c(
      rows, missing_accounts, parse_problems, nrow(counts), sum(counts$locations > 1L),
      sum(!complete), nrow(valid), uniqueN(valid$village_key), sum(is.na(index)), disagreements
    )
  )
  write.csv(summary, "output/land_geography_audit.csv", row.names = FALSE)
  arrow::write_parquet(
    valid[, list(account_no, district, sub_division, zone, mauja, village_key)],
    "output/land_account_locations.parquet"
  )
  print(summary, row.names = FALSE)
}

if (sys.nframe() == 0L) write_land_geography_audit()
