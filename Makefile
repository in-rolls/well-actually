R := R_LIBS_USER=$(CURDIR)/.R/library Rscript

.PHONY: run replicate robustness diagnostics report test lint format deps sources dominance-sensitivity external-feasibility

run: sources/paper.txt
	$(R) src/robustness.R
	$(R) src/diagnostics.R
	$(R) src/compare_published.R
	$(R) src/village_design.R
	$(R) src/iv_lal_review.R
	$(R) src/iv_exclusion_sensitivity.R
	$(R) src/irrigation_budget.R
	$(R) src/water_balance_checks.R
	$(R) src/land_ownership_checks.R
	$(R) -e 'knitr::opts_knit$$set(root.dir = getwd()); knitr::knit("ms/water-balance.Rmd", output = "ms/water-balance.md", quiet = TRUE)'
	$(R) src/figures.R
	$(R) -e 'knitr::knit("README.Rmd", output = "README.md", quiet = TRUE)'

replicate: sources/paper.txt
	$(R) src/replicate.R
	$(R) src/compare_published.R

robustness:
	$(R) src/robustness.R

diagnostics:
	$(R) src/diagnostics.R

report:
	$(R) src/figures.R
	$(R) -e 'knitr::knit("README.Rmd", output = "README.md", quiet = TRUE)'

test:
	$(R) tests/test_replication.R
	$(R) tests/test_dominance_sensitivity.R
	$(R) tests/test_external_feasibility.R

lint:
	$(R) -e 'x <- lintr::lint_dir("."); print(x); stopifnot(length(x) == 0L)'

format:
	$(R) -e 'styler::cache_deactivate(); styler::style_dir("src"); styler::style_dir("tests")'

deps:
	@mkdir -p .R/library
	$(R) -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); renv::restore(library = ".R/library", prompt = FALSE)'

sources: sources/paper.txt

sources/paper.pdf:
	curl -L --fail 'https://drive.google.com/uc?export=download&id=1GGvPbS3WOeyfbWfTIU2SI3_4DKJqL8Op' -o sources/paper.pdf

sources/paper.txt: sources/paper.pdf
	pdftotext -layout sources/paper.pdf sources/paper.txt

dominance-sensitivity:
	$(R) src/dominance_sensitivity.R
	$(R) -e 'knitr::knit("ms/dominance-sensitivity.Rmd", output = "ms/dominance-sensitivity.md", quiet = TRUE)'

external-feasibility:
	$(R) src/ihds_feasibility.R
	$(R) src/land_readiness.R
