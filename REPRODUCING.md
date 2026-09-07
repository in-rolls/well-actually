This directory contains an R reproduction and empirical review of Anderson (2011), using the supplied archive without modifying it. Read [the review](ms/review.md) for the findings.

Run from the repository root:

```sh
make deps
make run
make test
make lint
```

`make deps` restores the pinned `renv.lock` into `.R/library`; the Make targets use that library. The recorded analysis used the installed package versions captured by the lockfile. A fresh network restore has not been tested. `make run` downloads the final article if absent and requires `curl` and Poppler’s `pdftotext` (`brew install poppler` on macOS). It regenerates the numerical results, figure, and README.

The main analysis packages are `haven`, `sandwich`, `clubSandwich`, `ivreg`, `fwildclusterboot`, and `dqrng`; validation and reporting use `digest`, `testthat`, `lintr`, `styler`, and `knitr`. The lockfile records their dependencies and source repositories.

`output/sessionInfo.txt` records the local R session. The bootstrap uses the R engine in fwildclusterboot 0.14.3, with both R and dqrng seeds initialized to 113777. Tests use 9,999 null-imposed Rademacher wild draws, two-sided tests, and the default fnw11 bootstrap. Draws advance in the script’s documented order. The separate IV pairs bootstrap samples 80 villages with replacement, re-estimates both stages, uses 1,999 draws and seed 113778, and records all coefficient draws. It can take several minutes.

`make precision` regenerates the original regressions, the Table 4(2) contrast-specific precision audit, and the README. It compares iid, HC1, village CR1, and village CR2/Satterthwaite inference, and records household/village support and cluster-score variance contributions. Its separate wild bootstrap uses 9,999 null-imposed Webb draws, seed 113779 reset in R and dqrng for each contrast and variant, fnw11 test-inverted confidence intervals, and WCR31 p-values. Reparameterization exposes the full buyer contrast to the bootstrap; tests verify identical fitted values and the intended coefficient. These settings are separate from the earlier bootstrap described above. WCR31 reports two pseudoinverse warnings per contrast: deleting villages 33 and 65 removes the only observation support for district indicators `dist13` and `dist25`, respectively. The saved deletion-rank audit checks every village deletion and verifies that all four focal contrasts remain estimable despite those redundant nuisance columns. The fnw11 intervals and primary CR2 results do not use this WCR31 calculation.

`replicate.R` reads the original `program.txt` and implements its table-specific files and filters. R equal-variance t-tests match Stata’s default two-sample tests. OLS uses clustered CR1 covariance and t(G−1) inference. IV uses the unadjusted clustered sandwich and normal inference to match `ivregress` without `small`. Rank-deficient district columns are omitted by R’s QR decomposition. This changes redundant parameter normalizations but not fitted values or focal coefficients. R warns about collinear IV columns; independent matrix-algebra tests validate the retained estimates.

`diagnostics.R` also writes default, homoskedastic `ivreg` diagnostics through the baseline script. That file is labelled `iv_diagnostics.txt` and is not the published clustered inference. Use `iv_table.csv`, `iv_first_stage_tests.csv`, and the specifically named sensitivity outputs for the audit conclusions.

The published descriptive comparison checks 408 numerical cells from the final article: means, standard deviations, differences, and pooled standard errors for all 68 rows. Table 1 percentage variables and Table 2 irrigated land are rescaled to the printed units. Table 6 reverses the difference to high minus low to match its column. Text was extracted with Poppler `pdftotext -layout`; the extracted numerical targets were checked against the journal tables. Published regression benchmarks are transcribed in `compare_published.R` and saved to `sources/published_regression.csv`.

The tests check the independently archived Stata baseline, manual OLS and IV covariance calculations, identifier uniqueness, interaction construction, ratio arithmetic, comparison coverage, and recovery of planted coefficients. Formatting uses styler; lintr uses a 120-character line limit. No Stata executable was available, so this is an independent R reproduction, with an external Stata log as a cross-check, rather than a new Stata run.

Sources:

- [Published article](https://www.aeaweb.org/articles?id=10.1257/app.3.1.239), downloaded from the [author’s publication page](https://sites.google.com/view/siwan-anderson/home/published-papers), preserved as `sources/paper.pdf`.
- [Original replication archive](https://www.openicpsr.org/openicpsr/project/113777/version/V1/view).
- [Independent 2022 reproduction](https://osf.io/h2u96/), with public Stata output saved as `sources/previous-stata-output.txt`.
- [2005 working paper](https://www.uh.edu/academics/sos/econ/documents/caste.pdf), clearly distinguished from the final article and the unavailable 2009 version.
- Official documentation for [R t-tests](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/t.test.html), [clustered covariance](https://sandwich.r-forge.r-project.org/reference/vcovCL.html), [ivreg](https://zeileis.github.io/ivreg/reference/ivreg.html), [Stata IV conventions](https://www.stata.com/manuals/rivregress.pdf), and [wild bootstrap](https://s3alfisc.github.io/fwildclusterboot/reference/boottest.html).

Validation on 2026-09-06: `make run`, `make test`, and `make lint` completed in the final repository location. All 39 test assertions passed and lintr reported no lints. The wild-bootstrap and IV-pairs-bootstrap summary CSVs were identical to the earlier run. The figure and published Tables 3–5 were visually checked.

Validation on 2026-09-07: `make precision`, `make test`, and `make lint` completed. All 134 assertions passed, including 18 precision-audit assertions; lintr reported no lints. The regenerated README and local documentation links were checked. The land/IHDS crosswalk inspection did not execute a linked outcome analysis.

Cleanup validation on 2026-09-07: after removing the standalone administrative-land branch, `make test lint` passed all 131 remaining assertions with no lints. The original-sample and IHDS outcome analyses remain in the build.
