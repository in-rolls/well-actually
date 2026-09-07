options(warn = 1)
required <- c("haven", "sandwich", "ivreg", "fwildclusterboot", "jsonlite", "digest")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: ", paste(missing, collapse = ", "))
root <- normalizePath(".")
data_dir <- file.path(root, "data/original")
out <- file.path(root, "output")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write_result <- function(x, name) write.csv(x, file.path(out, name), row.names = FALSE)
read_data <- function(name) as.data.frame(haven::read_dta(file.path(data_dir, paste0(name, ".dta"))))
data <- setNames(
  lapply(c("village", "table2", "household", "table6"), read_data),
  c("village", "table2", "household", "table6")
)
lines <- trimws(readLines(file.path(data_dir, "program.txt"), warn = FALSE))
formula_from <- function(tokens) reformulate(tokens[-1], response = tokens[1])
fit_ols <- function(tokens, d) {
  vars <- unique(c(tokens, "village"))
  d <- d[complete.cases(d[, vars]), , drop = FALSE]
  fit <- lm(formula_from(tokens), data = d)
  list(fit = fit, data = d)
}
coefficient_table <- function(fit, d, id, iv = FALSE) {
  # Stata regress, cluster(): CR1 and t(G-1). ivregress defaults to z inference.
  v <- sandwich::vcovCL(fit,
    cluster = d$village, type = if (iv) "HC0" else "HC1",
    cadjust = !iv
  )
  b <- coef(fit)[colnames(v)]
  se <- sqrt(diag(v))
  g <- length(unique(d$village))
  p <- if (iv) 2 * pnorm(-abs(b / se)) else 2 * pt(-abs(b / se), df = g - 1)
  critical <- if (iv) qnorm(.975) else qt(.975, g - 1)
  data.frame(
    model = id, term = names(b), estimate = b, se = se, p = p,
    lower = b - critical * se, upper = b + critical * se,
    n = nrow(d), clusters = g, rank = fit$rank, row.names = NULL
  )
}
models <- list()
reg_results <- list()
ttests <- list()
table_id <- 0
column <- 0
for (line in lines) {
  if (grepl("TABLE [1-6]", line)) {
    table_id <- as.integer(sub(".*TABLE ([1-6]).*", "\\1", line))
    column <- 0
  }
  if (grepl("^ttest ", line)) {
    column <- column + 1
    name <- switch(as.character(table_id),
      `1` = "village",
      `2` = "table2",
      `6` = "table6"
    )
    d <- data[[name]]
    lhs <- trimws(strsplit(sub("^ttest +", "", line), ",")[[1]][1])
    variable <- strsplit(lhs, " +")[[1]][1]
    if (grepl(" if ", lhs)) {
      condition <- sub(".* if +", "", lhs)
      keep <- eval(parse(text = condition), d)
      d <- d[!is.na(keep) & keep, , drop = FALSE]
    }
    d <- d[complete.cases(d[, c(variable, "domhigh")]), , drop = FALSE]
    low <- as.numeric(d[d$domhigh == 0, variable])
    high <- as.numeric(d[d$domhigh == 1, variable])
    test <- t.test(low, high, var.equal = TRUE)
    f <- lm(reformulate("domhigh", response = variable), data = d)
    cr <- coefficient_table(f, d, paste0("T", table_id, "_", column))
    cr <- cr[cr$term == "domhigh", ]
    ttests[[length(ttests) + 1]] <- data.frame(
      table = table_id, row = column,
      variable = variable, n_low = length(low), n_high = length(high),
      mean_low = mean(low), mean_high = mean(high), sd_low = sd(low), sd_high = sd(high),
      difference = mean(low) - mean(high), t = unname(test$statistic), p = test$p.value,
      cluster_se = cr$se, cluster_p = cr$p
    )
  }
  if (grepl("^regress ", line)) {
    column <- column + 1
    tokens <- strsplit(trimws(sub(",.*", "", sub("^regress +", "", line))), " +")[[1]]
    id <- paste0("T", table_id, "_", column)
    m <- fit_ols(tokens, data$household)
    m$tokens <- tokens
    models[[id]] <- m
    reg_results[[id]] <- coefficient_table(m$fit, m$data, id)
  }
}
write_result(do.call(rbind, ttests), "descriptive_tables.csv")
write_result(do.call(rbind, reg_results), "ols_tables.csv")
# Stata predict's default is xb, including observations outside e(sample) when predictors exist.
h <- data$household
h$bwx <- as.numeric(predict(models$T5_1$fit, newdata = h))
h$dlbwx <- h$domlow * h$bwx
ivline <- lines[grepl("^ivregress", lines)]
# The final cluster(village) is removed before extracting the instrument expression.
ivline <- sub(",.*", "", ivline)
inside <- sub(".*\\((.*)\\).*", "\\1", ivline)
parts <- strsplit(inside, " *= *")[[1]]
endog <- strsplit(trimws(parts[1]), " +")[[1]]
instruments <- strsplit(trimws(parts[2]), " +")[[1]]
external <- trimws(gsub("\\([^)]*\\)", "", sub("^ivregress 2sls +", "", ivline)))
tokens <- strsplit(external, " +")[[1]]
y <- tokens[1]
exog <- tokens[-1]
d <- h[complete.cases(h[, unique(c(y, exog, endog, instruments, "village"))]), ]
ivformula <- as.formula(paste(
  y, "~", paste(c(exog, endog), collapse = " + "),
  "|", paste(c(exog, instruments), collapse = " + ")
))
ivfit <- ivreg::ivreg(ivformula, data = d, x = TRUE)
write_result(coefficient_table(ivfit, d, "T5_IV", iv = TRUE), "iv_table.csv")
capture.output(summary(ivfit, diagnostics = TRUE), file = file.path(out, "iv_diagnostics.txt"))
# This is an excluded-predictor Wald test in the preliminary projection, not a weak-IV test.
m <- models$T5_1
v <- sandwich::vcovCL(m$fit, cluster = m$data$village, type = "HC1")
b <- coef(m$fit)[c("area", "naturalwater")]
wald <- drop(t(b) %*% solve(v[names(b), names(b)], b)) / 2
write_result(
  data.frame(
    F = wald, df1 = 2, df2 = length(unique(m$data$village)) - 1,
    p = pf(wald, 2, length(unique(m$data$village)) - 1, lower.tail = FALSE)
  ),
  "preliminary_projection_test.csv"
)
inventory <- do.call(rbind, lapply(names(data), function(name) {
  x <- data[[name]]
  id <- if ("hhcode" %in% names(x)) "hhcode" else "village"
  data.frame(
    file = name, rows = nrow(x), columns = ncol(x), villages = length(unique(x$village)),
    duplicate_rows = sum(duplicated(x)), duplicate_ids = sum(duplicated(x[[id]])),
    sha256 = digest::digest(file = file.path(data_dir, paste0(name, ".dta")), algo = "sha256")
  )
}))
write_result(inventory, "inventory.csv")
missingness <- do.call(rbind, lapply(names(data), function(name) {
  x <- data[[name]]
  data.frame(file = name, variable = names(x), missing = colSums(is.na(x)), n = nrow(x))
}))
write_result(missingness, "missingness.csv")
write_result(do.call(rbind, lapply(names(models), function(id) {
  x <- models[[id]]$data
  u <- unique(x[, c("village", "domlow")])
  data.frame(
    model = id, n = nrow(x), villages_low = sum(u$domlow == 1),
    villages_high = sum(u$domlow == 0), outcome_sd = sd(x[[models[[id]]$tokens[1]]]),
    outcome_mean = mean(x[[models[[id]]$tokens[1]]])
  )
})), "samples.csv")
saveRDS(list(models = models, ivfit = ivfit, ivdata = d, data = data), file.path(out, "fits.rds"))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
cat("Reproduced", length(ttests), "two-sample tests,", length(models), "OLS models, and 1 IV model.\n")
print(subset(do.call(rbind, reg_results), term %in% c("domlow", "dlbuywater")), row.names = FALSE)
