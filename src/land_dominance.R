suppressPackageStartupMessages(library(data.table))
caste_landrecords <- NULL
caste_category <- NULL
caste_standard <- NULL
muslim <- NULL
status <- NULL
group <- NULL
category <- NULL
account_no <- NULL
caste <- NULL
jati <- NULL
acres <- NULL
village_key <- NULL
area_cropland_paddy <- NULL
area_fallow <- NULL
area_upland_bhith <- NULL
area_total <- NULL
district <- NULL
total_acres <- NULL
majority <- NULL
guaranteed_largest <- NULL
largest_known_share <- NULL
classified_share <- NULL
known_margin <- NULL
coding <- NULL
definition <- NULL
accounts <- NULL
mean_account_acres <- NULL
paddy_share <- NULL
fallow_share <- NULL
largest_account_share <- NULL
before <- NULL

read_land_crosswalk <- function(land_dir, additions = TRUE) {
  base <- as.data.table(haven::read_dta(file.path(land_dir, "data/caste_codes/caste_code_landrecords.dta")))
  base <- base[, list(
    key = trimws(caste_landrecords), category = caste_category,
    jati = caste_standard, muslim
  )]
  if (additions) {
    extra <- fread(file.path(land_dir, "crosswalk/caste_crosswalk_additions.tsv"), colClasses = "character")
    extra <- extra[status == "mapped", list(
      key = trimws(caste_landrecords), category = caste_category,
      jati = caste_standard, muslim = as.numeric(muslim)
    )]
    base <- rbind(base, extra)
  }
  base <- unique(base)
  stopifnot(!anyDuplicated(base$key))
  base[, group := "unknown"]
  base[muslim == 0 & category == "uc", group := "upper"]
  base[muslim == 0 & category %in% c("bc1", "bc2", "ebc"), group := "obc"]
  base[muslim == 0 & category == "sc", group := "sc"]
  base[muslim == 0 & category == "st", group := "st"]
  base[muslim == 1, group := "muslim"]
  base
}

ownership_bounds <- function(villages) {
  groups <- c("upper", "obc", "sc", "st", "muslim")
  shares <- as.matrix(villages[, groups, with = FALSE]) / villages$total_acres
  unknown_share <- villages$unknown / villages$total_acres
  stopifnot(all(villages$total_acres > 0), all(abs(rowSums(shares) + unknown_share - 1) < 1e-10))
  top <- max.col(shares, ties.method = "first")
  largest <- shares[cbind(seq_len(nrow(shares)), top)]
  runner_up <- shares
  runner_up[cbind(seq_len(nrow(shares)), top)] <- -Inf
  second <- apply(runner_up, 1, max)
  villages[, `:=`(
    classified_share = 1 - unknown_share, largest_group = groups[top], largest_known_share = largest,
    second_known_share = second, known_margin = largest - second,
    guaranteed_largest = largest > second + unknown_share,
    majority = ifelse(largest > .5, groups[top], ifelse(largest + unknown_share <= .5, "none", "unresolved"))
  )]
  villages
}

classify_ownership <- function(lower, upper, threshold) {
  ifelse(lower > threshold, "above", ifelse(upper <= threshold, "at_or_below", "unresolved"))
}

summarize_land_thresholds <- function(villages) {
  results <- list()
  for (group_name in c("upper", "obc", "sc", "st", "muslim")) {
    lower <- villages[[group_name]] / villages$total_acres
    upper_bound <- lower + villages$unknown / villages$total_acres
    for (cutoff in c(.4, .5, .6)) {
      status <- classify_ownership(lower, upper_bound, cutoff)
      for (value in c("above", "at_or_below", "unresolved")) {
        results[[length(results) + 1L]] <- data.table(
          group = group_name, threshold = cutoff, classification = value, villages = sum(status == value)
        )
      }
    }
  }
  rbindlist(results)
}

write_land_dominance <- function(geo_file = "output/land_account_locations.parquet", output_dir = "output") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  land_dir <- normalizePath(Sys.getenv("LAND_REPO", "../land"))
  fields <- c(
    "account_no", "caste", "cat4", "area_total", "area_cropland_paddy", "area_cropland_other",
    "area_fallow", "area_upland_bhith"
  )
  land <- as.data.table(arrow::read_parquet(file.path(land_dir, "data/records_accounts_landtype.parquet"),
    col_select = tidyselect::all_of(fields)
  ))
  geo <- as.data.table(arrow::read_parquet(geo_file))
  geo[, account_no := bit64::as.integer64(account_no)]
  stopifnot(!anyDuplicated(land$account_no), !anyDuplicated(geo$account_no), !anyNA(geo$account_no))
  area_fields <- fields[grepl("^area_", fields)]
  valid_area <- Reduce(`&`, lapply(land[, area_fields, with = FALSE], function(x) is.finite(x) & x >= 0))
  excluded <- data.frame(
    quantity = c("raw_accounts", "invalid_area_accounts", "over_10000_acre_accounts"),
    value = c(nrow(land), sum(!valid_area), sum(land$area_total > 10000, na.rm = TRUE))
  )
  land <- land[valid_area & land$area_total <= 10000]
  land[, key := trimws(caste)]
  index <- match(land$account_no, geo$account_no)
  land[, `:=`(village_key = geo$village_key[index], district = geo$district[index])]
  narrow <- land$area_cropland_paddy + land$area_cropland_other + land$area_fallow
  broad <- narrow + land$area_upland_bhith
  stopifnot(all(broad <= land$area_total + 1e-7))
  village_results <- list()
  coverage_results <- list()
  threshold_results <- list()
  jati_results <- list()
  recode_results <- list()
  for (policy in c("base", "curated")) {
    crosswalk <- read_land_crosswalk(land_dir, additions = policy == "curated")
    index <- match(land$key, crosswalk$key)
    land[, group := crosswalk$group[index]]
    land[is.na(group), group := "unknown"]
    land[, jati := crosswalk$jati[index]]
    category <- crosswalk$category[index]
    rebuilt <- c(uc = "Others", bc1 = "OBC", bc2 = "OBC", ebc = "OBC", sc = "SC", st = "ST")[category]
    conflict <- !is.na(land$cat4) & !is.na(rebuilt) & land$cat4 != rebuilt
    stopifnot(!any(conflict))
    recode_results[[policy]] <- data.frame(
      coding = policy, conflicts = sum(conflict),
      newly_categorized_accounts = sum(is.na(land$cat4) & !is.na(rebuilt)),
      stored_category_without_crosswalk = sum(!is.na(land$cat4) & is.na(rebuilt))
    )
    for (definition_name in c("narrow", "broad")) {
      land[, acres := if (definition_name == "narrow") narrow else broad]
      agriculture <- land[acres > 0]
      coverage <- agriculture[, list(accounts = .N, acres = sum(acres)),
        by = list(group, linked = !is.na(village_key))
      ]
      coverage[, `:=`(coding = policy, definition = definition_name)]
      coverage_results[[paste(policy, definition_name)]] <- coverage
      linked <- agriculture[!is.na(village_key)]
      village <- linked[, list(
        accounts = .N, total_acres = sum(acres), largest_account_share = max(acres) / sum(acres),
        paddy_share = sum(area_cropland_paddy) / sum(acres), fallow_share = sum(area_fallow) / sum(acres),
        bhith_share = sum(area_upland_bhith) / sum(area_total), mean_account_acres = mean(acres)
      ), by = list(village_key, district)]
      grouped <- linked[, list(acres = sum(acres)), by = list(village_key, group)]
      shares <- dcast(grouped, village_key ~ group, value.var = "acres", fill = 0)
      for (missing in setdiff(c("upper", "obc", "sc", "st", "muslim", "unknown"), names(shares))) {
        shares[, (missing) := 0]
      }
      village <- merge(village, shares, by = "village_key", sort = FALSE)
      stopifnot(nrow(village) == uniqueN(linked$village_key))
      village <- ownership_bounds(village)
      village[, `:=`(coding = policy, definition = definition_name)]
      village_results[[paste(policy, definition_name)]] <- village
      thresholds <- summarize_land_thresholds(village)
      thresholds[, `:=`(coding = policy, definition = definition_name)]
      threshold_results[[paste(policy, definition_name)]] <- thresholds
      jatis <- linked[!is.na(jati) & nzchar(jati), list(acres = sum(acres)), by = list(village_key, jati)]
      jati_summary <- jatis[, list(largest_jati_acres = max(acres), yadav_acres = sum(acres[jati == "yadav"])),
        by = village_key
      ]
      jati_summary <- merge(village[, list(village_key, total_acres)], jati_summary, by = "village_key", all.x = TRUE)
      jati_results[[paste(policy, definition_name)]] <- data.frame(
        coding = policy, definition = definition_name, villages = nrow(village),
        known_jati_majority = sum(jati_summary$largest_jati_acres > .5 * jati_summary$total_acres, na.rm = TRUE),
        known_yadav_majority = sum(jati_summary$yadav_acres > .5 * jati_summary$total_acres, na.rm = TRUE)
      )
      message(policy, "/", definition_name, ": ", nrow(village), " villages aggregated")
    }
  }
  villages <- rbindlist(village_results)
  arrow::write_parquet(villages, file.path(output_dir, "land_village_ownership.parquet"))
  write.csv(excluded, file.path(output_dir, "land_area_audit.csv"), row.names = FALSE)
  write.csv(rbindlist(recode_results), file.path(output_dir, "land_recode_audit.csv"), row.names = FALSE)
  write.csv(rbindlist(coverage_results), file.path(output_dir, "land_ownership_coverage.csv"), row.names = FALSE)
  write.csv(rbindlist(threshold_results), file.path(output_dir, "land_ownership_thresholds.csv"), row.names = FALSE)
  write.csv(rbindlist(jati_results), file.path(output_dir, "land_jati_majorities.csv"), row.names = FALSE)
  summary <- villages[, list(
    villages = .N, known_majority = sum(majority %in% c("upper", "obc", "sc", "st", "muslim")),
    definitely_no_majority = sum(majority == "none"), unresolved_majority = sum(majority == "unresolved"),
    guaranteed_largest = sum(guaranteed_largest),
    largest_known_below_half = sum(largest_known_share <= .5),
    median_unknown_share = median(1 - classified_share),
    high_classification_coverage_villages = sum(classified_share >= .9),
    median_known_margin = median(known_margin)
  ), by = list(coding, definition)]
  write.csv(summary, file.path(output_dir, "land_ownership_summary.csv"), row.names = FALSE)
  profiles <- villages[coding == "curated", list(
    villages = .N, median_accounts = median(accounts), median_total_acres = median(total_acres),
    median_account_acres = median(mean_account_acres), median_paddy_share = median(paddy_share),
    median_fallow_share = median(fallow_share), median_largest_account_share = median(largest_account_share)
  ), by = list(definition, majority)]
  write.csv(profiles, file.path(output_dir, "land_ownership_profiles.csv"), row.names = FALSE)
  support <- list()
  for (definition_name in c("narrow", "broad")) {
    for (floor in c(1, 25, 50, 100)) {
      for (coverage in c(0, .9)) {
        selected <- villages[
          coding == "curated" & definition == definition_name &
            accounts >= floor & classified_share >= coverage
        ]
        support[[length(support) + 1L]] <- data.frame(
          definition = definition_name, minimum_accounts = floor, minimum_classified_share = coverage,
          villages = nrow(selected), upper_majority = sum(selected$majority == "upper"),
          obc_majority = sum(selected$majority == "obc"), sc_majority = sum(selected$majority == "sc"),
          unresolved_majority = sum(selected$majority == "unresolved")
        )
      }
    }
  }
  write.csv(rbindlist(support), file.path(output_dir, "land_ownership_support.csv"), row.names = FALSE)

  baseline <- villages[coding == "base", list(village_key, definition, before = majority)]
  after <- villages[coding == "curated", list(village_key, definition, after = majority)]
  transitions <- merge(baseline, after, by = c("village_key", "definition"))
  write.csv(transitions[, list(villages = .N), by = list(definition, before, after)],
    file.path(output_dir, "land_coding_transitions.csv"),
    row.names = FALSE
  )
  narrow_labels <- villages[coding == "curated" & definition == "narrow", list(village_key, before = majority)]
  broad_labels <- villages[coding == "curated" & definition == "broad", list(village_key, after = majority)]
  transitions <- merge(narrow_labels, broad_labels, by = "village_key", all = TRUE)
  write.csv(transitions[, list(villages = .N), by = list(before, after)],
    file.path(output_dir, "land_area_transitions.csv"),
    row.names = FALSE
  )
  inputs <- c(
    file.path(land_dir, c(
      "data/records_accounts_landtype.parquet", "data/account.csv.gz",
      "data/caste_codes/caste_code_landrecords.dta", "crosswalk/caste_crosswalk_additions.tsv"
    )),
    geo_file
  )
  hashes <- vapply(inputs, digest::digest, character(1), algo = "sha256", file = TRUE)
  provenance <- data.frame(file = inputs, sha256 = hashes)
  write.csv(provenance, file.path(output_dir, "land_dominance_provenance.csv"), row.names = FALSE)
  print(summary)
}

if (sys.nframe() == 0L) write_land_dominance()
