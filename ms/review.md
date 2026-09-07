The published regression coefficients reproduce in R. The stronger claim that caste-based failures in groundwater contracts cause a 45% yield gap is not established by this reproduction.

I reproduced the supplied commands for Tables 1–6 of Siwan Anderson’s *Caste as an Impediment to Trade*, American Economic Journal: Applied Economics 3(1), 2011, pp. 239–263. All 54 displayed coefficient/standard-error pairs in Tables 3–4 and the final column of Table 5 agree within 0.1 rupee. Table 5’s three first-stage instrument tests also reproduce: 27.94, 21.33, and 19.67. The original files were not changed.

The paper and the [author-posted final PDF](https://drive.google.com/file/d/1GGvPbS3WOeyfbWfTIU2SI3_4DKJqL8Op/view) support a real distinction between computational reproduction and causal validation. The positive sales association is fairly persistent. Several mechanism claims and some uncertainty statements are much less secure.

| Result | Published coefficient (SE), rupees per acre | R coefficient (SE) | R p-value |
|---|---:|---:|---:|
| Table 3(1): low-caste village | 566.5 (209.0) | 566.534 (209.033) | 0.0081 |
| Table 3(2): add district controls | 393.3 (191.6) | 393.355 (191.563) | 0.0430 |
| Table 4(2): village dominance × water buyer | 850.9 (275.0) | 850.936 (274.975) | 0.0026 |
| Table 5: IV interaction | 3,519.5 (1,413.7) | 3,519.509 (1,413.715) | 0.0128 |

The tolerance above allows minor rounding/transcription discrepancies; it is not a claim of exact agreement at every printed decimal. For example, 393.355 normally rounds to 393.4, whereas the paper prints 393.3. Full comparisons are in [published_regression_comparison.csv](../output/published_regression_comparison.csv) and [published_descriptive_comparison.csv](../output/published_descriptive_comparison.csv).

**What the results measure**

| Claim | Actual comparison and outcome | Scale and population | What is identified without additional assumptions? |
|---|---|---|---|
| Lower-caste households have higher income in low-caste-dominated villages | Difference in annual household income and crop sales between village types | Table 2: 705 versus 592 households; total-income difference ₹3,525.53 | An unweighted difference among sampled households |
| Village dominance improves agricultural performance | OLS coefficient on village dominance, conditional on household characteristics and selected controls | Table 3(1): ₹566.53, or 0.274 sample SD; 1,295 households in 90 villages | A conditional association in crop sales per acre of owned land |
| The advantage operates through water buyers | Interaction between dominance and reported water purchases | Table 4(2): ₹850.94, or 0.412 sample SD; same 90 villages | A difference in conditional slopes across water-market statuses |
| Instrumenting purchases confirms the mechanism | Two endogenous regressors instrumented by predicted purchases and predicted purchases × dominance | Table 5: 1,127 households in 80 villages; interaction ₹3,519.51, or 1.622 outcome SD in that sample | An IV estimand only if its independence, exclusion, and functional-form restrictions hold |
| Lower-caste water buyers have yields 45% higher in lower-caste-dominated villages | No household-level buyer–seller caste pairing, water price, delivered quantity, or contract performance is supplied | Broad caste categories; one 1997–98 survey in two states | The exact percentage and the contract-enforcement mechanism are not independently reconstructed |

For each claim, the calculation serves a recognizable question, and the supplied regression implementation produces the reported coefficients. The main remaining weaknesses concern whether the design answers the causal question and whether the interpretation stays within what was measured.

**The outcome is sales, with a large zero mass**

The Table 2 note defines crop income as sales revenue, explicitly excluding crops consumed by the household. The regression divides those sales by owned land. This is neither physical harvest per cultivated acre nor net agricultural profit. A household that grows food but sells none receives a zero. Changing commercialization, crop choice, consumption, or the relationship between owned and cultivated area can change this measure without an equivalent change in physical productivity.

Of the 1,295 regression households, 795 have zero recorded crop sales per acre, and 345 own no land. Where land ownership is positive, the stored ratio agrees with sales divided by owned land to within ₹0.01. Two households in the wider file report positive sales but zero owned land and are assigned a zero ratio. These facts justify checking the outcome’s construction; they do not establish that every zero is an error.

The main village coefficient remains positive among landowners: ₹779.84, SE ₹282.06, p = 0.0069. Among households with positive sales, it is ₹1,199.04, SE ₹401.59, p = 0.0038. Thus, including landless households does not manufacture the basic positive association. The water-buyer interaction among positive sellers is ₹944.06, SE ₹580.45, p = 0.108. This restriction selects on an outcome and changes the population; it is not a corrected estimate. In the full sample, the analogous interaction for having any positive sales is 13.61 percentage points, SE 4.87, p = 0.0063. The extensive margin of selling crops is empirically relevant.

The statement on p. 247 that median agricultural income is almost doubled also needs a denominator qualification. The unconditional median of recorded crop sales is zero in both village types. Conditional on positive sales, the medians are ₹3,000 and ₹5,250. The latter is a 75% difference, but it describes selected sellers rather than all households.

**The direct irrigation evidence weakens when households are clustered correctly**

The supplied Table 2 commands run ordinary equal-variance two-sample t-tests. They treat households from the same village as independent. Because village dominance varies at the village level, I also estimated the identical mean differences using village-clustered standard errors and t reference distributions with G−1 degrees of freedom.

| Table 2 outcome | Low minus high village difference | Original-command p | Village-clustered p | Wild-cluster p |
|---|---:|---:|---:|---:|
| Share of land irrigated | +6.33 percentage points | 0.0020 | 0.260 | 0.275 |
| Tubewell irrigation | +5.95 percentage points | 0.0311 | 0.413 | 0.413 |
| Buys water | +7.70 percentage points | 0.0102 | 0.232 | 0.249 |
| Owns a pump | +10.57 percentage points | 0.000046 | 0.0118 | 0.0150 |

The point estimates do not change. Evidence for the first three differences becomes inconclusive, while the pump-ownership difference persists. This weakens the particular Table 2 evidence invoked on p. 249; it does not refute the paper’s separately asserted village-level irrigation results, whose underlying area measures are not included in these files.

Multiplicity does not erase all of the paper’s findings. Across four Table 2 income measures, village-clustered Bonferroni p-values range from 0.0043 to 0.0265. Across four irrigation measures, only ownership survives Bonferroni, at p = 0.0473. A broader family of all 16 Table 2 rows gives a different answer: total income, crop income, and crop income per acre have Bonferroni p-values of 0.091, 0.066, and 0.106, respectively, but all three survive Benjamini–Hochberg at 5%. These are explicitly declared sensitivity families, not recovered preregistered families. Alternative specifications of the same outcome were not counted as independent primary outcomes.

Some printed significance stars do not agree exactly with the supplied commands. Water purchases in Table 2 have p = 0.01021 rather than p < 0.01; Table 3(5) has p = 0.01028 under the supplied village-clustered t test. Those are small threshold discrepancies, distinct from the much larger clustering issue above.

**The buyer result is persistent, but buyer-specificity is overstated**

The Table 4(2) interaction survives the village wild bootstrap, p = 0.0014, and every leave-one-village-out regression. Its coefficient ranges from ₹697.41 to ₹903.21 across those 90 deletions, with a largest p-value of 0.0059. It also survives 99th-percentile winsorization, restriction to households whose water status is observed in Table 2, and separate estimation in Uttar Pradesh and Bihar. The corresponding estimates by state are ₹1,022.19 and ₹492.24; their p-values are 0.0115 and 0.0367. This is substantial evidence against a single-village explanation.

The paper argues that the effect is specific to buyers because the buyer interaction is significant and the owner interaction is not. The direct comparison is weaker: buyer interaction minus owner interaction is ₹462.41, SE ₹614.23, p = 0.454, with a 95% interval from −₹758 to ₹1,683. The data do not establish that those two interactions differ. This is particularly relevant to the argument on pp. 260–261 that land quality or other mechanisms should have benefited owners instead.

The interaction is also not itself the complete village contrast for buyers. For buyers who do not own a pump, Table 4(2) implies −₹87.98 + ₹850.94 = ₹762.96, SE ₹310.26, p = 0.0159. The paper describes yields as 45% higher in lower-caste-dominated villages (p. 253). I reproduced the rupee coefficients, but could not reproduce the calculation giving 45%. The recorded outcome is crop sales per owned acre. A higher value can reflect greater production, different crops or prices, or selling a larger share of the harvest instead of consuming it. Calling the gap a yield effect obscures those distinctions; calling it a causal effect of caste requires ruling out other differences between villages.

**Two adjusted results are statistically fragile, and three sample counts are wrong**

Table 3(2)’s district-adjusted coefficient has conventional clustered p = 0.0430 but village wild-bootstrap p = 0.0616. It crosses above 0.05 in 14 of 90 leave-one-village-out regressions. Table 3(6), which adds public goods controls, changes from p = 0.0298 to wild-bootstrap p = 0.0556 and crosses above 0.05 in 4 of 78 village deletions. The other four Table 3 coefficients remain below 0.05 under this bootstrap. All six retain positive point estimates.

| Published column | Printed N | Actual N | Actual villages |
|---|---:|---:|---:|
| Table 3(4), distance controls | 1,295 | 1,127 | 80 |
| Table 3(6), public goods controls | 1,295 | 1,122 | 78 |
| Table 4(4), distance controls | 1,295 | 1,127 | 80 |

The displayed coefficients reproduce using these smaller samples, so this is a sample-reporting defect rather than a failure to recover the coefficients. The distinction matters when interpreting changes across columns. On the public-goods complete-case sample, the baseline village coefficient is already ₹287.05 before adding those controls; adding them increases it to ₹371.27. Comparing ₹566.53 with ₹371.27 across different samples confounds selection with adjustment.

There are lesser table defects. Table 2’s landlord standard deviations print as 0.02 and 0.01; the data give 0.280 and 0.251. Its reported difference has the opposite sign to low minus high. The rows labelled adjusted R-squared in Tables 3–4 generally track ordinary R-squared; for example, Table 3(2) has R-squared 0.2792 but adjusted R-squared 0.2626. Table 4(1) additionally prints 0.31 where the supplied regression gives ordinary R-squared 0.3036. These do not overturn the principal coefficients.

**The IV result is sensitive and its exclusions remain assumptions**

The generated-instrument procedure reproduces Table 5 precisely. It is not the elementary mistake of replacing endogenous regressors with fitted values and then using ordinary second-stage OLS standard errors: the code uses conventional 2SLS with two excluded generated instruments. I checked its coefficients and covariance independently by matrix algebra.

I applied the relevant checks from Lal, Lockhart, Xu, and Zu (2024), *How Much Should We Trust Instrumental Variable Estimates in Political Science?* Their paper's empirical sample excludes specifications with multiple endogenous regressors. Anderson has two: water purchase and its interaction with village dominance. Single-endogenous-regressor diagnostics therefore cannot simply be imported as a complete validation of this model. [Author's paper](https://yiqingxu.org/papers/english/2021_iv/LLXZ_PA.pdf).

With identical controls and the same 1,127 households in 80 villages, the OLS interaction is ₹914.38 and the IV interaction is ₹3,519.51, a ratio of 3.85. The paired village bootstrap puts their difference at ₹2,605, with a 95% percentile interval of [−₹1,204, ₹7,833]. The larger IV point estimate therefore does not establish a statistically clear increase over OLS. Nor does a larger IV estimate by itself prove bias. The ordinary first-stage F statistics are 23.92 and 23.47; clustering by village reduces them to 21.33 and 19.67. These are separate first-stage tests, not conditional strength tests for the two-endogenous-regressor system. Each first stage has a partial R-squared of about 0.041. [Same-sample comparison](../output/iv_ols_same_sample.csv), [first stages](../output/iv_first_stage_comparison.csv).

A village pairs bootstrap that re-estimates the preliminary purchase equation and the 2SLS model in every draw is considerably less precise than the reported normal approximation. Across 1,999 valid draws, its 95% percentile interval for the interaction is [−₹395, ₹8,982], compared with the published-convention interval [₹749, ₹6,290]. The studentized bootstrap interval from the same draws is [₹1,529, ₹10,447], which excludes zero. Reporting only the percentile interval would conceal this disagreement. Both intervals are wide; the bootstrap distribution has heavy tails, and neither method is a weak-instrument-robust confidence set. These results establish sensitivity of inference, not proof of bias. [Both intervals and paired comparison](../output/iv_lal_bootstrap_summary.csv).

Using village area, natural-water availability, and their dominance interactions directly as excluded instruments gives an interaction of −₹8,963, SE ₹8,179, p = 0.273. A clustered Anderson–Rubin joint test of both endogenous coefficients being zero in this alternative specification has p = 0.278. That is a different IV specification, not a correction to the published one, and the joint test does not isolate the interaction. The large change warrants caution about the generated-instrument restrictions.

More fundamentally, village area and access to canals, rivers, ponds, or lakes plausibly affect agricultural sales through routes other than the binary decision to purchase groundwater. Their exclusion from the sales equation is therefore substantive. Balance between caste-dominance groups does not establish exclusion. Nor does historical persistence establish that the locations chosen by landlords and cultivators were unrelated to subsequent agricultural opportunities. There are no historical village observations in the package with which to test that claim.

Even the balance evidence is not an equivalence test: the 95% interval for the village-area difference is approximately −172 to +170 hectares, and for natural-water availability it is −10.9 to +30.6 percentage points. Failure to reject zero leaves economically meaningful differences possible.

**The proposed mechanism remains plausible but unmeasured**

The paper acknowledges on p. 258 that its support for the contracting mechanism is limited by the lack of detailed groundwater terms-of-trade data. The package contains no matched buyer–seller identities, transaction prices, delivery volumes, refusals, or contract breaches. It is consequently unable to distinguish caste-based enforcement failures from local market power, field geography, differences in commercialization, or other unmeasured determinants. Equal village-wide numbers of sellers and buyers are not evidence that individual households face identical local choice sets. The paper’s own account emphasizes how geographically restricted those choice sets are.

External evidence does not justify dismissing a large irrigation-related revenue effect as impossible. A randomized encouragement study in Andhra Pradesh subsidized drip equipment, increasing adoption by about 16 percentage points. It reported substantial revenue gains, including a highly uncertain treatment-on-treated estimate of roughly 150% per acre, partly through crop switching. This is a different intervention, period, region, and estimand; it cannot validate Anderson’s 45% claim. It does show why revenue effects and fixed-crop physical-yield effects must be distinguished. [Fishman, Giné, and Jacoby, 2021](https://documents1.worldbank.org/curated/en/475611624561753275/pdf/Efficient-Irrigation-and-Water-Conservation-Evidence-from-South-India.pdf).

A closer mechanism comparator directly measured groundwater transactions in Pakistan’s Punjab. It found discrimination between tenants and other buyers and examined prices, quantities, and welfare. Its estimated aggregate deadweight loss was 9% of groundwater expenditures, themselves about 8% of household income. Those units differ from crop revenue per acre and should not be treated as a numerical refutation of Anderson. The useful comparison is evidentiary: transaction-level information can test the market mechanism that village-level dominance only proxies. [Jacoby, Murgai, and Rehman, World Bank working paper](https://documents1.worldbank.org/curated/en/962741468759556335/pdf/multi0page.pdf).

**Coverage of the twelve paper-review checks**

| Check | Finding or explicit limit |
|---|---|
| 1. Decompose indices | No summary index. Decomposed sales into participation and positive-sales subsamples; recomputed buyer and owner contrasts. |
| 2. Floors, ceilings, baseline gaps | 795/1,295 sales-per-acre zeros; unconditional medians both zero; irrigation differences and intervals recomputed. |
| 3. Dose response | No measured dose or assigned exposure duration. Historical dominance is binary; no valid dose-response test available. |
| 4. Mechanism validation | Buyer status is observed, but matched trading partners, prices, reliability, and contract enforcement are absent. |
| 5. Implementation fidelity | No intervention was implemented. Actual same-caste trading exposure cannot be checked from broad village labels. |
| 6. ITT to TOT | Inapplicable to this observational dominance comparison. No compliance rate permits a defensible ITT/TOT conversion. |
| 7. Effect-size benchmarks | Compared irrigation intervention and groundwater-market studies above; differences in units prevent a direct magnitude verdict. |
| 8. Statistical fragility | Wild bootstrap, village deletion, district clustering, multiplicity, outcome restrictions, and full-procedure IV resampling completed. Randomization inference is inapplicable because no assignment mechanism is specified. |
| 9. Stated versus revealed preferences | These are reported economic activities and sales rather than aspirations. They remain survey reports; sales exclude own consumption. |
| 10. Companion-paper triangulation | Read the final article and located the 2005 working paper. The 2009 unpublished version cited for numerous additional results was not located. The 2005 draft is not substituted for that missing version. |
| 11. Selective emphasis | Direct buyer–owner test does not support their claimed distinction; some tests lose significance; sample counts and median wording require correction. No inference of deliberate selection or misconduct. |
| 12. Generalizability | Baseline uses 42 low-dominance and 48 high-dominance villages, in 25 districts of two states, in 1997–98. Village labels do not establish actual same-jati trade or transportability across India. |

**Data integrity and remaining limits**

All four files have unique identifiers and no completely duplicated rows. The household file’s SHA-256 matches the independently archived [2022 OSF reproduction](https://osf.io/h2u96/), whose Stata log reproduces Table 3(1). Shared observed values agree between the two household files, but they have different missingness conventions. Among the main 1,295 households, 372 have water status missing in Table 2 and recorded as zero in the regression file; all 372 have zero crop sales and 342 are landless. Restricting to the 923 with observed water status gives an interaction of ₹990.71, SE ₹411.19, p = 0.0181. The interaction therefore persists when those filled values are excluded, although their original construction remains incompletely documented.

The distribution contains four additional households in Table 2 relative to the regression file; two belong to the dominance-comparison sample, which explains 1,297 versus 1,295. No supplied construction script explains the exclusions. The village files contain 122 and 120 records, respectively, but the headline comparison consistently uses the same 90 villages. These are distinct scope counts, not evidence of duplicated analytical villages.

The archive begins with prepared analytical files. It does not reconstruct them from the original LSMS and 2001 census sources, include a data dictionary for every derived field, reproduce the omitted crop-specific analyses, or identify which actual sellers each household faced. No registration or original analysis plan was supplied or located. A separate replication atlas lists a later secondary-data failure, but I have not independently verified that study and do not use its classification as evidence for this audit’s verdict.

The completed work establishes successful reproduction of the principal regression numbers, several concrete reporting defects, and weaker support for some inferential and mechanism claims. The evidence warrants belief in a positive association between village dominance and recorded crop sales, especially among water buyers in these data. It warrants much less confidence in a precisely quantified causal loss from caste-based contract failure.


**Village sampling, weighting, and clustering**

Anderson used existing data from the 1997–98 World Bank survey of Uttar Pradesh and Bihar; she did not collect the survey herself. The questionnaire’s measurement limits and the paper’s subsequent variable construction are separate issues. The paper says the original survey sampled 2,250 households in 120 villages across 25 districts (p. 245). Its short description does not specify the sampling strata or household selection probabilities. Random sampling of villages is not random assignment of caste dominance.

The baseline regression retains 1,295 households in 90 villages. There are 591 households in 48 high-caste-dominated villages and 704 in 42 lower-caste-dominated villages. Retained household counts have a median of 13 and range from 1 to 32. The largest village supplies 2.47% of observations; the ten largest supply 22.16%. These are counts in the analysis, not village populations. [Counts](../output/village_household_counts.csv).

Village clustering is reasonable because households share the village's dominance category, water market, and other local conditions. Their regression errors may consequently move together. Treating all households as independent would overstate how much independent information the sample contains. The regressions already cluster by village; the descriptive household t tests do not. Clustering does not remove differences between villages that could confound the caste comparison, and dependence across villages remains a separate concern.

Giving each village equal total regression weight changes the baseline coefficient from ₹567 to ₹586, the district-adjusted coefficient from ₹393 to ₹552, and the buyer interaction from ₹851 to ₹826. Unequal household counts do not explain away these positive associations. Equal-village weighting changes the target comparison; it is not a substitute for unavailable survey selection weights. [Weighting sensitivity](../output/equal_village_weight.csv).


**What would an exclusion violation actually do?**

Here, a direct effect means a path outside the binary indicator for buying groundwater. Canal irrigation could raise sales among households that buy no groundwater. Access to alternative water could also change the quantity purchased without changing whether a household buys any. The village-area argument is more conjectural: delivery distance might affect reliability or quantity among existing buyers. Village area alone does not mechanically determine sales per owned acre.

Mellon's *Rain, rain, go away* motivates asking whether such alternative pathways are large enough to change an IV conclusion. Wiley blocked the full paper; I obtained its abstract through the DOI metadata. The following is a transparent linear sensitivity calculation, not a claimed reproduction of Mellon's detailed procedure. [Linked paper](https://doi.org/10.1111/ajps.12894).

I hold the published sample, regressors, and instruments fixed, assume an additive direct effect of one proposed pathway, subtract that contribution from crop sales, and re-estimate 2SLS. The direct effect is an assumption, not estimated from the data. Importantly, a positive direct effect of natural-water access common to both dominance groups increases the estimated interaction: assuming a ₹500 increase in annual crop sales per owned acre changes it from ₹3,520 to ₹4,003. The simple argument that canals improve production therefore does not explain away the positive interaction.

Under the common-direct-effect assumption, reducing the interaction point estimate to zero would require natural-water access to reduce sales by approximately ₹3,638 per owned acre. For village area, the corresponding assumption is a ₹561 reduction per additional 100 hectares. These are one-at-a-time algebraic thresholds; neither magnitude has an empirical plausibility benchmark here. They are not confidence bounds, do not allow arbitrary simultaneous violations, and do not resolve instrument independence. A direct effect differing by village dominance constitutes another assumption and is shown separately in the output. [Sensitivity calculations](../output/iv_exclusion_sensitivity.csv), [zero-crossing thresholds](../output/iv_exclusion_thresholds.csv).

This distinction belongs in the verdict: an exclusion concern can weaken identification without providing a numerical explanation for an upward-biased estimate. The proposed alternative pathway's direction must be checked.


**The economics: what prevents farmers from trading around caste?**

A large crop-sales gap raises a basic economic question. If supplying a lower-caste farmer with water creates substantial additional income, why would a seller leave that business unserved? Why would another seller not enter, a farmer not buy from a nearby village, or several farmers not share a well? The larger the available profit, the stronger those incentives become. A caste explanation must account for what prevents these responses and show that the obstruction is caste. These data provide limited evidence on those margins.

The paper offers some economically coherent obstacles. Water must reach the field, so a well in the next village may be too far away even if its owner wants to sell. The paper describes delivery through channels and geographically restricted service areas. It also reports that a tubewell can cost roughly a year's average household income (pp. 253–254). A small farmer can therefore suffer from poor access without being able to finance a profitable substitute. Shared ownership could lower the capital burden but introduces its own financing, maintenance, and allocation problems; the data do not establish whether that option was feasible.

These costs can exist in both types of village. Their existence alone cannot explain an effect of caste dominance. They may prevent farmers from escaping a caste-related disadvantage, but the explanation still needs a reason why caste changes access or contract performance. Alternatively, unequal geography or supplier availability could confound the estimated caste effect. Those are different claims and require different evidence.

Nor does a buyer's gain automatically become a seller's profit. The seller may face pumping costs, scarce water, limited operating time, and competing demand from the seller's own fields. Some of these constraints can support high prices or restricted service. They can explain poor access, but do not by themselves explain why caste determines it.

Anderson's proposed caste mechanism concerns enforcement of delivery agreements. A farmer may invest in a crop before discovering whether promised irrigation will arrive. If the seller can then delay delivery, demand more money, or prioritize another field, an attractive initial offer does not secure reliable service. The paper proposes that caste networks help enforce agreements within groups. Under that account, both parties can recognize gains from trade yet fail to realize them because they cannot credibly commit. That is an economic explanation for persistent losses; it requires evidence about how contracts actually work across caste groups.

This is where the evidence is thin. The dataset does not identify each buyer's seller, map fields to alternative wells, or record water prices, quantities, delivery failures, or cross-village purchases. An administrative village boundary need not coincide with a water market: a well just across it might be closer than one in the farmer's own village. Village caste dominance may consequently misdescribe the suppliers a farmer can actually use.

The observed crop-sales gap also does not establish the size of the profit available to a new seller. Crop revenue is not farm profit, and the village comparison does not observe the same farmer with and without the alleged barrier. Treating the full gap as money people knowingly refuse would assume the causal interpretation that needs to be established.

The useful tests follow from the economic argument. Does the caste gap shrink when farmers have more nearby suppliers, including across village boundaries? Are otherwise comparable cross-caste purchases more expensive or less reliable? Does new well entry or shared irrigation access reduce the gap? Do differences persist after accounting for field-to-well distance and the timing of water demand? These observations would help distinguish caste-based enforcement problems from geography, scarcity, or local monopoly. They are unavailable in the supplied package.

The buyer-minus-owner comparison tests another implication. Buyers depend on trading water; pump owners can supply themselves. The paper's mechanism therefore suggests a larger village advantage for buyers. The estimated difference between the buyer and owner interactions is ₹462, with a 95% interval from −₹758 to ₹1,683. This sample does not establish that the buyer advantage exceeds the owner advantage. That weakens the mechanism's specificity; it is separate from the calculation behind the headline percentage.

The economic objection is thus not that rational people can never suffer large losses. It is that large gains should attract efforts to capture them. Establishing caste as the cause requires evidence about the obstruction to entry, bargaining, or reliable contracting. Reproducing the sales regressions does not supply that missing evidence.


**How far would the estimated gain pay for hauling water?**

A tanker calculation starts with volume. One millimetre of water over an acre requires about 4,047 litres. The table assumes 10,000-litre loads and applies illustrative additional water depths to one acre. These depths are scenarios, not measured irrigation requirements or agronomic recommendations. The calculation uses the complete Table 4(2) buyer village contrast, ₹763 in annual crop sales per owned acre, rather than the buyer interaction alone or the unsupported percentage conversion.

| Additional water depth | Litres per acre | Whole 10,000-litre loads | Extra cost per load the ₹763 sales gain could cover |
|---|---:|---:|---:|
| 10 mm | 40,469 | 5 | ₹153 |
| 25 mm | 101,171 | 11 | ₹69 |
| 50 mm | 202,343 | 21 | ₹36 |
| 100 mm | 404,686 | 41 | ₹19 |

These are survey-period rupees and break-even calculations, not tanker-price quotes. They assume the whole estimated sales difference is recoverable, the watered acre corresponds to an owned acre, no other production costs increase, and existing water payments are not saved. If hauling replaces paid groundwater, those avoided payments would also contribute to the budget; extra production costs would reduce it. Multiple watering rounds would consume more of the annual budget. The regression uncertainty is substantial: its 95% interval for the sales difference is ₹146–₹1,379. At 50 mm, that translates into roughly ₹7–₹66 per whole load under the same assumptions. It does not include uncertainty about water requirements or causal identification. [Reproducible calculations](../output/irrigation_break_even.csv).

The paper supplies neither tanker tariffs nor the additional water quantity needed to recover the sales gap. We therefore cannot conclude that hauling would or would not have been profitable. Nor should tankers stand in for every alternative: a nearby pipe or channel could have a different cost, and a small timely watering might have a different return from supplying an entire season. The empirical question remains whether a feasible profitable alternative was blocked by caste.


The [village-balance audit](water-balance.md) reports uncertainty for all 28 Table 1 comparisons and prioritizes outcome decomposition, physical geography, historical comparability, and buyer-specific mechanism tests. Local 1991 SHRUG files are available, but a verified survey-to-Census village crosswalk is missing; no historical placebo has been run.

The [magnitude and definition audit](magnitude-benchmarks.md) supplies primary-paper benchmarks, examines village adjustment and settlement, and explains why the missing caste-specific land shares prevent a dominance-cutoff sensitivity check.

**Additional classification checks and independent data**

Reversing each of the 90 village labels in turn leaves the baseline, district-adjusted, buyer interaction, and full nonowner-buyer village gap positive in every case. The district-adjusted confidence interval includes zero in 36 of these hypothetical cases; the buyer-interaction interval does so in three. These are tests of sensitivity to one uncertain label, not actual land-share threshold changes. See the [generated classification audit](dominance-sensitivity.md).

The [independent replication feasibility note](land-records-plan.md) inventories IHDS-II, NSS 77, and 2022 Bihar land records. IHDS supplies contemporaneous village caste land-share reports and water-purchase and pump-ownership measures. Its released household outcomes differ from Anderson's sales measure, and many reported caste shares do not sum to the entire village area. No new-data outcome regression has been run.
