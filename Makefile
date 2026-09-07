R := R_LIBS_USER=$(CURDIR)/.R/library Rscript

.PHONY: run replicate robustness diagnostics report test lint format deps sources

run: sources/paper.txt
	$(R) src/robustness.R
	$(R) src/diagnostics.R
	$(R) src/compare_published.R
	$(R) src/village_design.R
	$(R) src/iv_lal_review.R
	$(R) src/iv_exclusion_sensitivity.R
	$(R) src/irrigation_budget.R
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
