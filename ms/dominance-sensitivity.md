# How much rests on the village classification?





Anderson used the existing 1997–98 World Bank survey of Uttar Pradesh and Bihar. She did not collect these village reports herself. That survey’s village questionnaire asks informants to rank the important castes by total land owned and by average holding size (Section 1A, question 7). It does not record ownership percentages. Ranking the largest landowning group is a reasonable survey question; it requires less information than calculating an exact share. But the largest group can hold less than half. A hypothetical 40/35/25 split illustrates the distinction; it is not a measured split in these villages.

Anderson defines dominance as majority land ownership. She also says the observed comparison is largely between villages with upper-caste residents and villages without them (p. 242). That account could imply a pronounced difference rather than a delicate 49% versus 51% cutoff. The missing construction code prevents us from checking the correspondence. The rank-versus-share distinction is therefore a question to resolve, not proof that the village labels are erroneous or arbitrary.

## A sensitivity check possible with the prepared files

We keep every household, outcome, control, and district assignment fixed. For each of the 90 villages in turn, we reverse its dominance label for all its households and recompute both dominance-by-water-status interactions. We refit the baseline, district-adjusted, and water-interaction specifications, retaining village-clustered HC1 intervals and t inference with 89 degrees of freedom.


|Comparison                      | Original ₹/acre| Smallest ₹/acre| Largest ₹/acre| Sign reversals / 90| Intervals including zero / 90|
|:-------------------------------|---------------:|---------------:|--------------:|-------------------:|-----------------------------:|
|Baseline village gap            |          566.53|          244.62|         656.13|                   0|                             3|
|Buyer interaction               |          850.94|          511.99|         927.52|                   0|                             3|
|Full nonowner-buyer village gap |          762.96|          301.59|         899.71|                   0|                             5|
|District-adjusted village gap   |          393.35|           91.79|         509.63|                   0|                            36|

No single reassignment reverses any of the four point estimates. That is evidence against the association being wholly dependent on one village label. Precision is less stable, particularly for the district-adjusted village coefficient. A confidence interval crossing zero does not establish that the effect vanished, and counting such crossings is not an estimated error probability.

These are hypothetical relabelings, not a reconstruction of plausible alternative ownership cutoffs. We do not know which villages, if any, were misclassified. The exercise does not address errors in several villages, systematic classification differences, or confounding between village types. It also cannot validate a causal water-market interpretation.

Run `make dominance-sensitivity` to regenerate the estimates and report. The [raw-survey follow-up](raw-survey-followup.md) identifies the missing ranking observations and village roster. Actual land shares would be needed to move a numerical ownership cutoff. The [Bihar land-records plan](land-records-plan.md) explains how the separate 2022 records can support an external measurement check.
