ihds_code <- function(x) {
  if (!is.factor(x)) {
    return(as.numeric(x))
  }
  labels <- as.character(x)
  valid <- is.na(labels) | grepl("^\\([0-9]+\\)", labels)
  stopifnot(all(valid))
  as.numeric(sub("^\\(([0-9]+)\\).*", "\\1", labels))
}

read_ihds <- function(dataset, land_dir = Sys.getenv("LAND_REPO", "../land")) {
  path <- file.path(land_dir, sprintf("data/ihds2/ICPSR_36151/DS%04d/36151-%04d-Data.rda", dataset, dataset))
  container <- new.env()
  objects <- load(path, envir = container)
  stopifnot(length(objects) == 1L)
  container[[objects]]
}

ihds_key <- function(data) {
  keys <- lapply(data[, c("STATEID", "DISTID", "PSUID")], ihds_code)
  stopifnot(!any(vapply(keys, anyNA, logical(1))))
  do.call(paste, c(keys, sep = "_"))
}

land_share_bounds <- function(shares, castes, religions, group) {
  in_group <- matrix(castes %in% group, nrow = nrow(castes))
  known_group <- !is.na(castes) & in_group & religions == 1
  known_other <- (!is.na(castes) & !in_group) | (!is.na(religions) & religions != 1)
  invalid <- rowSums(shares < 0 | shares > 100, na.rm = TRUE) > 0 |
    rowSums(shares, na.rm = TRUE) > 100.01
  lower <- rowSums(ifelse(known_group, shares, 0), na.rm = TRUE)
  upper <- 100 - rowSums(ifelse(known_other, shares, 0), na.rm = TRUE)
  lower[invalid] <- upper[invalid] <- NA_real_
  data.frame(lower = lower, upper = upper)
}

classify_ihds_dominance <- function(data, threshold = 50, definition = "obc") {
  definition <- match.arg(definition, c("obc", "sc", "broad_lower", "single_jati", "not_upper"))
  group <- switch(definition,
    broad_lower = "lower",
    sc = "sc",
    "obc"
  )
  lower_min <- data[[paste0(group, "_min")]]
  lower_max <- data[[paste0(group, "_max")]]
  if (definition == "single_jati") {
    return(ifelse(data$single_obc > 50, 1, ifelse(data$single_upper > 50, 0, NA_real_)))
  }
  if (definition == "not_upper") {
    return(ifelse(data$upper_min > threshold, 0, ifelse(data$upper_max <= threshold, 1, NA_real_)))
  }
  ifelse(lower_min > threshold & data$upper_max <= threshold, 1,
    ifelse(data$upper_min > threshold & lower_max <= threshold, 0, NA_real_)
  )
}

seasonal_area <- function(areas, conversion, method = "max") {
  valid <- complete.cases(areas) & rowSums(areas < 0, na.rm = TRUE) == 0 &
    !is.na(conversion) & conversion > 0
  result <- rep(NA_real_, nrow(areas))
  if (any(valid)) {
    result[valid] <- if (method == "max") {
      apply(areas[valid, , drop = FALSE], 1, max)
    } else {
      rowSums(areas[valid, , drop = FALSE])
    }
    result[valid] <- result[valid] / conversion[valid]
  }
  result
}

pump_status <- function(counts) {
  positive <- rowSums(counts > 0, na.rm = TRUE) > 0
  zeros <- complete.cases(counts) & rowSums(counts == 0, na.rm = TRUE) == ncol(counts)
  invalid <- rowSums(counts < 0, na.rm = TRUE) > 0
  result <- ifelse(positive, 1, ifelse(zeros, 0, NA_real_))
  result[invalid] <- NA_real_
  result
}

build_ihds_replication <- function() {
  households <- read_ihds(2)
  villages <- read_ihds(12)
  respondents <- read_ihds(14)
  households$village_key <- ihds_key(households)
  villages$village_key <- ihds_key(villages)
  respondents$village_key <- ihds_key(respondents)
  stopifnot(nrow(households) == 42152L, nrow(villages) == 1410L)
  stopifnot(!anyDuplicated(households$IDHH), !anyDuplicated(villages$village_key))
  respondent_key <- paste(respondents$village_key, respondents$VR1)
  duplicate_key <- duplicated(respondent_key) | duplicated(respondent_key, fromLast = TRUE)
  target_respondent <- ihds_code(respondents$STATEID) %in% c(9, 10)
  stopifnot(!any(duplicate_key & target_respondent))
  respondents <- respondents[!duplicate_key, ]

  shares <- as.matrix(villages[, paste0("VJ6", LETTERS[1:9])])
  castes <- sapply(villages[, paste0("VJ3", LETTERS[1:9])], ihds_code)
  religions <- sapply(villages[, paste0("VJ4", LETTERS[1:9])], ihds_code)
  village_data <- data.frame(village_key = villages$village_key)
  groups <- list(upper = 1:2, obc = 3, sc = 4, lower = 3:5)
  for (group in names(groups)) {
    bounds <- land_share_bounds(shares, castes, religions, groups[[group]])
    village_data[[paste0(group, "_min")]] <- bounds$lower
    village_data[[paste0(group, "_max")]] <- bounds$upper
  }
  single_share <- function(group) {
    known <- matrix(castes %in% group, nrow = nrow(castes)) & religions == 1
    values <- ifelse(known & !is.na(shares), shares, 0)
    values[is.na(values)] <- 0
    result <- apply(values, 1, max)
    result[is.na(village_data$upper_min)] <- NA_real_
    result
  }
  village_data$single_upper <- single_share(1:2)
  village_data$single_obc <- single_share(3)
  village_data$reported_land <- rowSums(shares, na.rm = TRUE)
  village_data$upper_population <- villages$VH1A + villages$VH1B
  participant_caste <- ihds_code(respondents$VR5)
  participant_religion <- ihds_code(respondents$VR6)
  participant_position <- ihds_code(respondents$VR3)
  participants <- data.frame(
    village_key = respondents$village_key, participants = 1L,
    upper_hindu_participants = as.integer(participant_caste %in% 1:2 & participant_religion == 1),
    obc_sc_hindu_participants = as.integer(participant_caste %in% 3:4 & participant_religion == 1),
    obc_hindu_participants = as.integer(participant_caste == 3 & participant_religion == 1),
    sc_hindu_participants = as.integer(participant_caste == 4 & participant_religion == 1),
    cultivator_participants = as.integer(ihds_code(respondents$VR7) == 1),
    panchayat_participants = as.integer(participant_position == 1),
    caste_unknown = as.integer(is.na(participant_caste)),
    religion_unknown = as.integer(is.na(participant_religion)),
    position_unknown = as.integer(is.na(participant_position))
  )
  participant_summary <- aggregate(. ~ village_key, participants, sum, na.rm = TRUE, na.action = na.pass)
  participant_index <- match(village_data$village_key, participant_summary$village_key)
  village_data <- cbind(village_data, participant_summary[participant_index, -1])
  rownames(village_data) <- NULL

  data <- data.frame(
    household_id = as.character(households$IDHH), village_key = households$village_key,
    state = ihds_code(households$STATEID), district = ihds_code(households$DISTID),
    rural = ihds_code(households$URBAN2011) == 0,
    hindu = ihds_code(households$ID11) == 1, caste = ihds_code(households$ID13),
    farm = ihds_code(households$FM1) == 1, household_size = households$NPERSONS,
    education = ihds_code(households$HHEDUC), survey_weight = households$WT,
    water_spending = households$FM31,
    buyer = ifelse(is.na(households$FM31) | households$FM31 < 0, NA_real_, as.numeric(households$FM31 > 0)),
    pump = pump_status(as.matrix(households[, c("FM40A", "FM40B", "FM40C")])),
    owned_acres = seasonal_area(as.matrix(households[, paste0("FM4", LETTERS[1:3])]), households$FM3),
    crop_acres = seasonal_area(as.matrix(households[, paste0("FM11", LETTERS[1:3])]), households$FM3, "sum"),
    gross_value = households$FM22RSHH, net_income = households$INCCROP
  )
  data$district_key <- paste(data$state, data$district, sep = "_")
  data$sc <- as.integer(data$caste == 4)
  status <- ifelse(is.na(data$buyer) | is.na(data$pump), NA_character_,
    ifelse(data$pump == 1, ifelse(data$buyer == 1, "both", "owner"), ifelse(data$buyer == 1, "buyer", "neither"))
  )
  data$water_status <- factor(status, levels = c("buyer", "owner", "both", "neither"))
  village_index <- match(data$village_key, village_data$village_key)
  data$linked <- !is.na(village_index)
  data <- cbind(data, village_data[village_index, -1])
  rownames(data) <- NULL
  stopifnot(nrow(data) == nrow(households))
  data$gross_owned <- ifelse(data$owned_acres > 0 & data$gross_value >= 0,
    data$gross_value / data$owned_acres, NA_real_
  )
  data$net_owned <- ifelse(data$owned_acres > 0, data$net_income / data$owned_acres, NA_real_)
  data$gross_cultivated <- ifelse(data$crop_acres > 0 & data$gross_value >= 0,
    data$gross_value / data$crop_acres, NA_real_
  )
  data$log_gross_owned <- ifelse(data$gross_owned > 0, log(pmax(data$gross_owned, .Machine$double.xmin)), NA_real_)
  data$dominance <- classify_ihds_dominance(data)
  data$target <- data$rural & data$state %in% c(9, 10) & data$hindu & data$caste %in% 3:4
  data$target[is.na(data$target)] <- FALSE
  data$eligible <- data$target & data$farm & !is.na(data$owned_acres) & data$owned_acres > 0
  data$eligible[is.na(data$eligible)] <- FALSE

  filters <- list(
    all_households = rep(TRUE, nrow(data)), rural_up_bihar = data$rural & data$state %in% c(9, 10),
    hindu_obc_sc = data$target, farm_positive_owned_land = data$eligible,
    linked = data$eligible & data$linked,
    identified_dominance = data$eligible & data$linked & !is.na(data$dominance),
    observed_water_status = data$eligible & data$linked & !is.na(data$dominance) & !is.na(data$water_status),
    complete_primary = data$eligible & complete.cases(data[, c(
      "dominance", "water_status", "gross_owned", "household_size", "education", "sc", "survey_weight"
    )])
  )
  flow <- do.call(rbind, lapply(names(filters), function(stage) {
    selected <- which(filters[[stage]])
    data.frame(stage = stage, households = length(selected), villages = length(unique(data$village_key[selected])))
  }))
  target_villages <- village_data[village_data$village_key %in% data$village_key[filters$rural_up_bihar], ]
  list(data = data, villages = target_villages, flow = flow, participant_summary = participant_summary)
}

write_ihds_measurement <- function(built) {
  write.csv(built$flow, "output/ihds_sample_flow.csv", row.names = FALSE)
  write.csv(built$villages, "output/ihds_village_measurement.csv", row.names = FALSE)
  profile_fields <- c("owned_acres", "crop_acres", "water_spending", "gross_value", "net_income", "survey_weight")
  target <- built$data[built$data$target, ]
  profile <- do.call(rbind, lapply(profile_fields, function(name) {
    values <- target[[name]]
    data.frame(
      variable = name, n = length(values), missing = sum(is.na(values)),
      negative = sum(values < 0, na.rm = TRUE), zero = sum(values == 0, na.rm = TRUE),
      minimum = min(values, na.rm = TRUE), median = median(values, na.rm = TRUE), maximum = max(values, na.rm = TRUE)
    )
  }))
  write.csv(profile, "output/ihds_field_profile.csv", row.names = FALSE)
  recodes <- list(
    buyer = as.data.frame(table(raw_positive = target$water_spending > 0, buyer = target$buyer, useNA = "always")),
    water_status = as.data.frame(table(
      buyer = target$buyer, pump = target$pump, status = target$water_status, useNA = "always"
    ))
  )
  for (name in names(recodes)) {
    write.csv(recodes[[name]], paste0("output/ihds_recode_", name, ".csv"), row.names = FALSE)
  }
  paths <- vapply(c(2, 12, 14), function(dataset) {
    file.path(
      Sys.getenv("LAND_REPO", "../land"),
      sprintf("data/ihds2/ICPSR_36151/DS%04d/36151-%04d-Data.rda", dataset, dataset)
    )
  }, character(1))
  provenance <- data.frame(
    dataset = c(2, 12, 14), path = paths,
    sha256 = vapply(paths, digest::digest, character(1), algo = "sha256", file = TRUE)
  )
  write.csv(provenance, "output/ihds_input_provenance.csv", row.names = FALSE)
  print(built$flow)
  cat("Participant counts in linked UP-Bihar villages:\n")
  print(summary(built$villages$participants))
  invisible(built)
}

if (sys.nframe() == 0L) write_ihds_measurement(build_ihds_replication())
