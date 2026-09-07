source("src/replicate.R")
set.seed(113777)
dqrng::dqset.seed(113777)
focus <- c(
  setNames(rep("domlow", 6), paste0("T3_", 1:6)),
  setNames(rep("dlbuywater", 4), paste0("T4_", 2:5))
)
wild <- list()
influence <- list()
for (id in names(focus)) {
  m <- models[[id]]
  d <- m$data
  fit <- lm(formula(m$fit), data = d)
  boot <- fwildclusterboot::boottest(fit,
    param = focus[[id]], clustid = "village",
    B = 9999, conf_int = FALSE, engine = "R", nthreads = 1
  )
  wild[[id]] <- data.frame(
    model = id, term = focus[[id]], p_wild = boot$p_val,
    B = 9999, seed = 113777
  )
  influence[[id]] <- do.call(rbind, lapply(unique(d$village), function(g) {
    dd <- d[d$village != g, ]
    fit <- lm(formula(m$fit), data = dd)
    tab <- coefficient_table(fit, dd, id)
    tab <- tab[tab$term == focus[[id]], ]
    tab$omitted_village <- g
    tab
  }))
}
write_result(do.call(rbind, wild), "wild_bootstrap.csv")
write_result(do.call(rbind, influence), "leave_one_village_out.csv")
robust <- list()
for (id in c("T3_1", "T3_2", "T4_2")) {
  m <- models[[id]]
  d <- m$data
  d$district <- max.col(as.matrix(d[, paste0("dist", 1:25)]), ties.method = "first")
  term <- if (id == "T4_2") "dlbuywater" else "domlow"
  alternatives <- list(
    all = d, landowners = d[d$totland > 0, ],
    positive_sales = d[d$cropincacre > 0, ],
    winsor99 = transform(d, cropincacre = pmin(cropincacre, quantile(cropincacre, .99))),
    log1p_sales = transform(d, cropincacre = log1p(cropincacre)),
    UP = d[d$bihar == 0, ], Bihar = d[d$bihar == 1, ]
  )
  for (label in names(alternatives)) {
    dd <- alternatives[[label]]
    fit <- lm(formula(m$fit), data = dd)
    tab <- coefficient_table(fit, dd, paste(id, label, sep = ":"))
    robust[[paste(id, label)]] <- tab[tab$term == term, ]
  }
  fit <- lm(formula(m$fit), data = d)
  v <- sandwich::vcovCL(fit, cluster = d$district, type = "HC1")
  g <- length(unique(d$district))
  b <- coef(fit)[term]
  se <- sqrt(v[term, term])
  robust[[paste(id, "district")]] <- data.frame(
    model = paste0(id, ":district_cluster"),
    term = term, estimate = b, se = se, p = 2 * pt(-abs(b / se), g - 1),
    lower = b - qt(.975, g - 1) * se, upper = b + qt(.975, g - 1) * se,
    n = nrow(d), clusters = g, rank = fit$rank
  )
  boot <- fwildclusterboot::boottest(fit,
    param = term, clustid = "district", B = 9999,
    conf_int = FALSE, engine = "R", nthreads = 1
  )
  wild[[paste0(id, ":district")]] <- data.frame(
    model = paste0(id, ":district"),
    term = term, p_wild = boot$p_val, B = 9999, seed = 113777
  )
}
write_result(do.call(rbind, wild), "wild_bootstrap.csv")
# Compare added controls on a fixed sample so missingness is not mistaken for adjustment.
for (id in c("T3_4", "T3_6", "T4_4")) {
  base_id <- if (startsWith(id, "T3")) "T3_1" else "T4_2"
  dd <- models[[id]]$data
  f <- lm(formula(models[[base_id]]$fit), data = dd)
  tab <- coefficient_table(f, dd, paste0(base_id, ":sample_of_", id))
  robust[[id]] <- tab[tab$term == if (base_id == "T3_1") "domlow" else "dlbuywater", ]
}
d <- models$T4_2$data
# A buyer effect is the sum of dominance and its buyer interaction for non-pump-owners.
f <- models$T4_2$fit
v <- sandwich::vcovCL(f, cluster = d$village, type = "HC1")
contrasts <- list(
  buyer_village_difference = c(domlow = 1, dlbuywater = 1),
  owner_village_difference = c(domlow = 1, dlownpump = 1),
  buyer_minus_owner_interactions = c(dlbuywater = 1, dlownpump = -1)
)
ct <- do.call(rbind, lapply(names(contrasts), function(label) {
  w <- contrasts[[label]]
  vars <- names(w)
  b <- sum(w * coef(f)[vars])
  se <- sqrt(drop(t(w) %*% v[vars, vars] %*% w))
  g <- length(unique(d$village))
  data.frame(
    contrast = label, estimate = b, se = se, p = 2 * pt(-abs(b / se), g - 1),
    lower = b - qt(.975, g - 1) * se, upper = b + qt(.975, g - 1) * se
  )
}))
write_result(ct, "water_contrasts.csv")
for (caste in 3:5) {
  dd <- d[d$caste == caste, ]
  f <- lm(formula(models$T4_2$fit), data = dd)
  tab <- coefficient_table(f, dd, paste0("T4_2:caste", caste))
  robust[[paste0("caste", caste)]] <- tab[tab$term == "dlbuywater", ]
}
write_result(do.call(rbind, robust), "robustness.csv")
# Explicit outcome families: Table 2 income outcomes, irrigation outcomes, and all 16 rows.
tt <- read.csv(file.path(out, "descriptive_tables.csv"))
multiplicity <- list()
families <- list(
  income = c("totinc", "cropinc", "cropincacre", "tyields"),
  irrigation = c("landirr", "tubewell", "buywater", "ownpump"),
  all_table2 = tt$variable[tt$table == 2]
)
for (family in names(families)) {
  rows <- tt[tt$table == 2 & tt$variable %in% families[[family]], ]
  multiplicity[[family]] <- data.frame(
    family = family, outcome = rows$variable,
    p = rows$cluster_p, bonferroni = p.adjust(rows$cluster_p, "bonferroni"),
    BH = p.adjust(rows$cluster_p, "BH")
  )
}
write_result(do.call(rbind, multiplicity), "multiple_testing.csv")
# Direct irrigation regressions on the Table 2 sample with its recorded missingness.
d <- data$table2
for (outcome in c("landirr", "buywater", "ownpump", "tubewell")) {
  dd <- d[complete.cases(d[, c(outcome, "domhigh", "village")]), ]
  f <- lm(reformulate("domhigh", response = outcome), data = dd)
  boot <- fwildclusterboot::boottest(f,
    param = "domhigh", clustid = "village", B = 9999,
    conf_int = FALSE, engine = "R", nthreads = 1
  )
  wild[[paste0("T2:", outcome)]] <- data.frame(
    model = paste0("T2:", outcome), term = "domhigh",
    p_wild = boot$p_val, B = 9999, seed = 113777
  )
}
write_result(do.call(rbind, wild), "wild_bootstrap.csv")
cat("Completed robustness checks.\n")
print(do.call(rbind, wild), row.names = FALSE)
print(ct, row.names = FALSE)
