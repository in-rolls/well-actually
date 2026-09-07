

# Well, Actually

A replication and review of Siwan Anderson’s
[“Caste as an Impediment to Trade”](https://www.aeaweb.org/articles?id=10.1257/app.3.1.239)
(AEJ: Applied Economics, 2011). Groundwater, caste, and a second look at the evidence.

The main coefficients reproduce. All 54 displayed coefficient/standard-error
pairs checked agree within 0.1 rupee. The water-buyer interaction survives removing any one
village. The stronger claim is less secure: the data measure crop sales rather than physical
yields, three of four direct irrigation differences lose significance when clustered by village, and the
data do not establish that buyers benefit differently from pump owners. The instrumental-variable
result also becomes much less precise when both stages are re-estimated in a village bootstrap.

![Buyer and owner interactions, with their direct comparison](figs/buyers-and-owners.png)

The points are the village-dominance interactions for water buyers and pump owners in Table 4(2),
and their difference. All use the same 1,295 households and village-clustered 95% t intervals.
A significant buyer interaction and an insignificant owner interaction do not establish a
difference between them: the direct test has p = 0.454.

The argument and all twelve review checks are in [the review](ms/review.md).

| Check | Result | Evidence |
|---|---:|---|
| Baseline village-dominance coefficient | ₹566.5 (SE 209.0) | [Reproduction](output/published_regression_comparison.csv) |
| Water-buyer interaction | ₹850.9 (SE 275.0) | [OLS tables](output/ols_tables.csv) |
| Buyer minus owner interactions | ₹462.4 (SE 614.2), p = 0.454 | [Direct contrasts](output/water_contrasts.csv) |
| District-adjusted village coefficient, wild bootstrap | p = 0.062 | [Wild bootstrap](output/wild_bootstrap.csv) |
| IV interaction, published inference | ₹3,519.5 (SE 1,413.7) | [IV table](output/iv_table.csv) |
| IV interaction, village pairs bootstrap | 95% percentile interval [₹-395, ₹8,982] | [Full-procedure bootstrap](output/iv_pairs_bootstrap.csv) |
| Three published sample sizes | 1,295 printed; 1,127, 1,122, and 1,127 used | [Sample comparison](output/published_sample_comparison.csv) |

These are reproduction and sensitivity results from the original sample, not an independent
new-data replication. The IV percentile interval is not a weak-instrument-robust confidence set.
The paper says lower-caste water buyers have yields **45% higher** in lower-caste-dominated
villages (p. 253). That is not a 45% loss: 145 is 45% above 100, but 100 is 31% below 145.
I reproduced the rupee coefficients but could not reproduce the calculation giving 45%.
The outcome measures crop sales per owned acre, so these results do not directly measure
physical yields or income that farmers knowingly give up.

The baseline uses **1,295 households in 90 villages**: 591 households in 48 high-caste-dominated
villages and 704 in 42 lower-caste-dominated villages. Village samples range from 1 to 32 households,
with a median of 13. Equal total weight per village gives a baseline difference of ₹586 per owned
acre, compared with ₹567 under the original household weighting. This is a sensitivity check;
it does not recover the original survey weights.

Following the checks discussed by Lal, Lockhart, Xu, and Zu, I compared IV and OLS on the same
1,127 households in 80 villages and bootstrapped the complete estimation procedure.
The IV interaction is 3.85 times the OLS interaction, but their difference is imprecisely estimated.
The two bootstrap intervals disagree about whether zero is excluded. See the
[IV results](output/iv_lal_bootstrap_summary.csv) and [explanation](ms/review.md).

Run from the repository root:

```sh
make deps
make run
make test
make lint
```

`make deps` restores `renv.lock` into `.R/library`; the other targets use that library when
present. R 4.6.0 was used for the recorded run. `make run` reproduces all six tables, performs the
robustness checks, and regenerates the figure and this README from the results. It downloads the final paper if needed, requires Poppler’s `pdftotext`, and takes several minutes. The prose review is a written interpretation of
the recorded analysis. [REPRODUCING.md](REPRODUCING.md) documents inference conventions, seeds,
dependencies, and the tests.

| Directory | Contents |
|---|---|
| `data/original/` | Unmodified Stata files, original commands, readme, and license |
| `src/` | R reproduction, sensitivity analyses, published comparisons, and figure |
| `tests/` | Independent matrix-algebra checks, Stata benchmark, and data invariants |
| `output/` | Machine-readable estimates, intervals, sample counts, and bootstrap draws |
| `ms/` | Review and the twelve-check coverage matrix |
| `sources/` | Provenance and locally cached paper and independent Stata log |

The original [AEA replication archive](https://www.openicpsr.org/openicpsr/project/113777/version/V1/view)
is distributed under the terms in [its license](data/original/LICENSE.txt).
The [author’s final paper](https://drive.google.com/file/d/1GGvPbS3WOeyfbWfTIU2SI3_4DKJqL8Op/view)
and [independent 2022 Stata reproduction](https://osf.io/h2u96/) provide the comparison sources.
See [sources/README.md](sources/README.md) for cached-file provenance.
