ihds_models <- new.env()
sys.source("src/ihds_replication.R", envir = ihds_models)

measure_ihds_support <- function(built) {
  data <- built$data
  reasons <- function(group) {
    exposure <- ihds_models$ihds_data_tools$classify_ihds_dominance(group)
    ifelse(is.na(group$upper_min), "invalid_shares",
      ifelse(!is.na(exposure), ifelse(exposure == 0, "upper_majority", "obc_majority"),
        ifelse(group$sc_min > 50, "sc_majority",
          ifelse(group$upper_max <= 50 & group$obc_max <= 50, "neither_majority", "unresolved_bounds")
        )
      )
    )
  }
  village_reasons <- data.frame(reason = reasons(built$villages))
  reason_counts <- as.data.frame(table(village_reasons$reason, useNA = "always"))
  names(reason_counts) <- c("reason", "villages")
  write.csv(reason_counts, "output/ihds_classification_reasons.csv", row.names = FALSE)
  roster_group <- ifelse(ihds_models$ihds_data_tools$classify_ihds_dominance(built$villages) == 0, "upper", "obc")
  roster_group[is.na(roster_group)] <- "other_or_unresolved"
  roster_summary <- do.call(rbind, lapply(split(built$villages, roster_group), function(group) {
    data.frame(
      exposure = roster_group[match(group$village_key[1], built$villages$village_key)], villages = nrow(group),
      participants_median = median(group$participants, na.rm = TRUE),
      no_upper_hindu = sum(group$upper_hindu_participants == 0, na.rm = TRUE),
      no_obc_hindu = sum(group$obc_hindu_participants == 0, na.rm = TRUE),
      no_sc_hindu = sum(group$sc_hindu_participants == 0, na.rm = TRUE),
      no_panchayat = sum(group$panchayat_participants == 0, na.rm = TRUE),
      no_cultivator = sum(group$cultivator_participants == 0, na.rm = TRUE)
    )
  }))
  write.csv(roster_summary, "output/ihds_roster_composition.csv", row.names = FALSE)
  target_data <- data[data$target & !is.na(data$dominance), ]
  target_data$landless <- ifelse(!target_data$farm, 1,
    ifelse(!is.na(target_data$owned_acres), as.numeric(target_data$owned_acres == 0), NA_real_)
  )
  composition_fields <- c(
    "household_size", "education", "sc", "owned_acres", "landless", "buyer", "pump", "upper_population"
  )
  composition <- do.call(rbind, lapply(split(target_data, target_data$dominance), function(group) {
    do.call(rbind, lapply(composition_fields, function(field) {
      observed <- !is.na(group[[field]])
      data.frame(
        dominance = group$dominance[1], variable = field, n = sum(observed),
        villages = length(unique(group$village_key[observed])),
        weighted_mean = weighted.mean(group[[field]][observed], group$survey_weight[observed])
      )
    }))
  }))
  write.csv(composition, "output/ihds_composition.csv", row.names = FALSE)
  primary <- ihds_models$select_ihds_sample(data)
  common <- ihds_models$select_ihds_sample(data, common_outcomes = TRUE)
  buyers <- common[common$water_status == "buyer", ]
  denominator_summary <- do.call(rbind, lapply(split(buyers, buyers$dominance), function(group) {
    data.frame(
      dominance = group$dominance[1], n = nrow(group),
      gross_value = weighted.mean(group$gross_value, group$analysis_weight),
      owned_acres = weighted.mean(group$owned_acres, group$analysis_weight),
      crop_acres = weighted.mean(group$crop_acres, group$analysis_weight),
      crop_to_owned = weighted.mean(group$crop_acres / group$owned_acres, group$analysis_weight),
      value_per_owned = weighted.mean(group$gross_owned, group$analysis_weight),
      value_per_crop = weighted.mean(group$gross_cultivated, group$analysis_weight)
    )
  }))
  write.csv(denominator_summary, "output/ihds_denominator_summary.csv", row.names = FALSE)
  districts <- do.call(rbind, lapply(split(primary, primary$district_key), function(group) {
    data.frame(
      district_key = group$district_key[1], upper_villages = length(unique(group$village_key[group$dominance == 0])),
      obc_villages = length(unique(group$village_key[group$dominance == 1])), households = nrow(group)
    )
  }))
  districts$both_groups <- districts$upper_villages > 0 & districts$obc_villages > 0
  missing_fields <- c(
    "owned_acres", "crop_acres", "buyer", "pump", "gross_value", "net_income", "education", "survey_weight"
  )
  target <- data[data$target, ]
  target$exposure_group <- ifelse(
    is.na(target$dominance), "unresolved_or_other", ifelse(target$dominance == 1, "obc", "upper")
  )
  missingness <- do.call(rbind, lapply(split(target, target$exposure_group), function(group) {
    do.call(rbind, lapply(missing_fields, function(field) {
      data.frame(
        exposure = group$exposure_group[1], field = field, n = nrow(group), missing = sum(is.na(group[[field]])),
        missing_farm = sum(is.na(group[[field]]) & group$farm, na.rm = TRUE),
        missing_nonfarm = sum(is.na(group[[field]]) & !group$farm, na.rm = TRUE)
      )
    }))
  }))
  eligible <- data[data$eligible, ]
  eligible$classifiable <- !is.na(eligible$dominance)
  selection_groups <- split(eligible, interaction(eligible$state, eligible$classifiable))
  selection <- do.call(rbind, lapply(selection_groups, function(group) {
    data.frame(
      state = group$state[1], classifiable = group$classifiable[1], households = nrow(group),
      villages = length(unique(group$village_key)), household_weight = sum(group$survey_weight),
      weight_effective_n = sum(group$survey_weight)^2 / sum(group$survey_weight^2),
      mean_reported_land = weighted.mean(group$reported_land, group$survey_weight),
      sc_share = weighted.mean(group$sc, group$survey_weight),
      mean_roster_participants = weighted.mean(group$participants, group$survey_weight),
      upper_participant_present = weighted.mean(group$upper_hindu_participants > 0, group$survey_weight),
      obc_sc_participant_present = weighted.mean(group$obc_sc_hindu_participants > 0, group$survey_weight)
    )
  }))
  raw <- ihds_models$ihds_data_tools$read_ihds(2)
  owned <- as.matrix(raw[, paste0("FM4", LETTERS[1:3])])
  seasonal_complete <- complete.cases(owned)
  seasonal_disagreement <- seasonal_complete & apply(owned, 1, function(values) length(unique(values)) > 1L)
  village_weights <- aggregate(analysis_weight ~ village_key, primary, sum)
  metrics <- data.frame(
    metric = c(
      "target_households", "target_complete_owned_seasons", "target_owned_season_disagreements",
      "primary_districts", "districts_with_both_groups", "overlap_districts_one_upper_village",
      "primary_effective_households", "largest_village_weight_share", "roster_villages",
      "roster_missing", "roster_min", "roster_median", "roster_max", "roster_no_upper_hindu", "roster_no_obc_sc_hindu"
    ),
    value = c(
      sum(data$target), sum(data$target & seasonal_complete), sum(data$target & seasonal_disagreement),
      nrow(districts), sum(districts$both_groups), sum(districts$both_groups & districts$upper_villages == 1),
      sum(primary$analysis_weight)^2 / sum(primary$analysis_weight^2),
      max(village_weights$analysis_weight) / sum(village_weights$analysis_weight), nrow(built$villages),
      sum(is.na(built$villages$participants)), min(built$villages$participants), median(built$villages$participants),
      max(built$villages$participants), sum(built$villages$upper_hindu_participants == 0),
      sum(built$villages$obc_sc_hindu_participants == 0)
    )
  )
  for (name in c("districts", "missingness", "selection", "metrics")) {
    write.csv(get(name), paste0("output/ihds_measurement_", name, ".csv"), row.names = FALSE)
  }
  cells <- ihds_models$support_cells(primary, "primary")
  write.csv(cells, "output/ihds_primary_support.csv", row.names = FALSE)
  print(metrics)
  invisible(list(metrics = metrics, districts = districts, selection = selection, missingness = missingness))
}

if (sys.nframe() == 0L) measure_ihds_support(ihds_models$ihds_data_tools$build_ihds_replication())
