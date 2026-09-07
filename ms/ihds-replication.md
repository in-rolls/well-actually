# Another draw from the well: the IHDS replication





**The main IHDS estimate does not reproduce Anderson's positive water-buyer association. Its uncertainty does not decisively rule out a large positive difference, and changing the land denominator changes the direction.** This is a later-survey test of a related crop-value outcome, not an exact replication of her cash-sales outcome or a causal estimate of caste discrimination.

Among nonowner water buyers, the estimated crop-value difference is **₹8,764 lower per owned acre per year** in OBC-majority villages. The 95% interval runs from **₹28,087 lower to ₹10,559 higher**. The comparison includes 743 Hindu OBC/SC farming households in 87 villages, with four separate water statuses. The regression uses household survey weights, district effects, household size, education and an SC indicator. Uncertainty allows households within a village to move together and accounts for the small amount of information supporting each contrast.

The weighted observed mean among upper-village nonowner buyers is ₹36,273 per owned acre. The fitted difference is about **24% lower** relative to that mean. A separate bootstrap that resamples whole villages and recalculates both the regression and the mean gives a relative interval of **71% lower to 53% higher** (999 of 999 draws identified). **That interval includes a 45% advantage.** The rupee and relative intervals use different inference procedures; the relative interval also reflects uncertainty in the denominator. Neither establishes that caste causes the observed gap.

## Why OBC, and what about SC?

Anderson describes the lower-caste landowners as backward agricultural castes, mainly Yadavs (p. 242). Broad OBC ownership is the closest available IHDS category, but it also includes groups outside that description. The primary comparison therefore uses villages where reported land shares establish an OBC-Hindu majority versus an upper-caste-Hindu majority. It does not classify every village lacking an upper majority as OBC dominated.

Before household restrictions there are 60 OBC-majority and 32 upper-majority villages. Only **2 villages establish an SC majority**. SC-dominance comparisons are retained as insufficient-support entries, including the planned alternative cutoffs. They cannot establish a general SC-village effect.

OBC households and SC households are also estimated separately within the OBC-versus-upper comparison. An SC farmer in an OBC-dominated village is not necessarily buying from their own caste. Broad categories cannot identify a buyer and seller's actual jati or relationship.

## Who reports caste land ownership?

Anderson used the existing 1997–98 World Bank UP–Bihar survey. Its village questionnaire has one caste-ranking table. The downloaded questionnaire and metadata do not give us the number of people answering that table, separate answers by respondent, or a disagreement-resolution rule. The 15 or 30 sampled households per village described in the sampling documentation are household interviews, not verified independent answers to the village caste-ranking question. The prepared replication files omit the raw caste-by-caste rankings and their construction into the final dominance label.

A rank reveals who is ahead, not by how much. It cannot distinguish a narrow plurality from a large majority or let us move an ownership cutoff. This is an unresolved measurement and construction issue, not a demonstrated rate of misclassification. [Original survey follow-up](raw-survey-followup.md).

IHDS asks for agricultural land percentages for jatis listed because of their population size. It may omit a small-population or absentee landowning group. We leave unassigned shares unresolved rather than rescale the listed shares to 100. For the primary contrast, 70 of 195 villages remain unresolved and 33 are outside the two majority categories. This selects a narrower population than all rural UP–Bihar villages.

The IHDS roster records **2–14 participants per village, median 11**. There is still only one collective set of land shares; those counts do not measure agreement. Representation varies:


|Village category    | Villages| Median participants| No upper-Hindu participant| No OBC-Hindu participant| No SC-Hindu participant|
|:-------------------|--------:|-------------------:|--------------------------:|------------------------:|-----------------------:|
|OBC majority        |       60|                  10|                         38|                        0|                      24|
|Other or unresolved |      103|                  11|                         50|                       17|                      37|
|Upper majority      |       32|                  11|                          5|                        7|                      16|

These are recorded participants, not a random sample of opinions. Lack of a group's participant creates a question about representation; it does not by itself prove the land estimate is wrong.

## The economic interpretation depends on the denominator

The released `FM22RSHH` aggregate is crop value/income. The IHDS guide lists it separately from crop residues and farm expenses; the questionnaire asks about production and prices. We have not recovered its crop-level construction or an equivalent cash-sales total. `INCCROP` is a separate measure after expenses. Neither outcome is physical crop yield.

Owned acreage is the maximum reported across three seasons, with all seasons observed and converted from local units. Cultivated crop-season acreage sums cultivation across seasons, including operated land that may be leased in. These denominators measure different things. On the identical complete sample:


|Outcome                                    | Households|OBC minus upper (₹) |95% interval (₹)  |
|:------------------------------------------|----------:|:-------------------|:-----------------|
|Crop value per owned acre                  |        739|-8,601              |-28,140 to 10,937 |
|Crop value per cultivated crop-season acre |        739|2,478               |-2,487 to 7,443   |
|Crop income after expenses per owned acre  |        739|1,148               |-10,009 to 12,305 |

The sign reversal between the first two outcomes persists with the same households. Upper-village buyers report more cultivated crop-season acreage relative to owned acreage: weighted mean ratios are 3.87 versus 3.17. Repeated cultivation and leasing can change annual income per owned acre without an equivalent difference in output per crop-season acre. The ratio of household averages is not the average of household ratios; the saved calculations use the latter where appropriate.

If irrigation access enables an extra crop season, that can be a real economic benefit even without higher physical yield for a given crop. But the benefit must be measured against additional water, labor, seed, rent and other costs. Leasing or cropping intensity could also reflect pre-existing village differences rather than an effect of caste. Changing the denominator changes the question; automatically controlling these channels away would not identify the total effect. The IHDS reversal does not establish that these channels explain Anderson’s original 45% figure.

Anderson's proposed mechanism is that caste ties improve enforcement of water contracts. To explain a large gain through that mechanism, one would want evidence of buyer–seller caste relationships, water delivery, prices and quantities. Agricultural specialization, land use, crop choice and irrigation investment offer rival explanations for a village gap. Existing geography and commercial opportunities could also affect who buys water and who owns a pump. These survey comparisons cannot separate all those paths. [Composition diagnostics](../output/ihds_composition.csv).

## Sensitivity and actual statistical support


|Specification                       | Households| Villages|Buyer gap (₹/owned acre) |95% interval        |
|:-----------------------------------|----------:|--------:|:------------------------|:-------------------|
|Primary: 50% majority               |        743|       87|-8,764                   |-28,087 to 10,559   |
|40% cutoff                          |        840|       99|-4,738                   |-25,374 to 15,898   |
|60% cutoff                          |        476|       54|-14,752                  |-66,166 to 36,662   |
|State effects                       |        743|       87|-6,891                   |-22,303 to 8,521    |
|Equal household weights             |        743|       87|-12,197                  |-29,072 to 4,678    |
|Equal village weights               |        743|       87|-4,800                   |-32,243 to 22,643   |
|No upper majority vs upper majority |       1116|      139|-690                     |-19,147 to 17,767   |
|Combined lower-caste majority       |        976|      112|-1,691                   |-20,802 to 17,420   |
|Single listed jati majority         |        264|       32|-15,235                  |-140,108 to 109,638 |
|OBC households                      |        598|       84|-5,123                   |-26,146 to 15,901   |
|SC households                       |        145|       50|1,179                    |-52,180 to 54,538   |
|At least 0.1 owned acre             |        711|       87|-3,934                   |-21,915 to 14,047   |
|Top 1% capped                       |        743|       87|-7,542                   |-24,943 to 9,859    |

![IHDS buyer-gap sensitivity](../figs/ihds-buyer-gaps.png)

No one-village omission changes the primary buyer gap to positive: the range is **₹11,787 lower to ₹5,439 lower**. This establishes limited influence robustness, not causality or reliable village classification.

The primary sample has 28 upper-majority and 59 OBC-majority villages. Only 16 of 36 districts contain both categories, and 13 of those have one upper village. The owner comparison has only 17 nonbuying owners in 7 upper villages. The CR2 degrees of freedom are 6.8 for the buyer gap and 3.2 for buyer-gap minus owner-gap. Eighty-seven villages therefore do not supply 87 equally informative comparisons.

The buyer gap is **₹5,673 lower than the owner gap**, with a difference interval of **₹-28,764 to ₹17,417**. There is no precise evidence here that buyers have the larger positive village gap. Null-imposed wild village bootstrap checks give p-values 0.27 and 0.45; primary-family Holm corrections are also saved. These checks cannot remedy sparse owner cells. The HC1 comparison also flags a household with leverage essentially one because of its sparse district cell; it is a diagnostic, not our chosen inference method. The WCR31 implementation uses a verified square-root-weighted OLS representation of the same WLS model. It uses generalized inverses in 11 cluster-deletion calculations where nuisance columns lose rank; all corresponding leave-one-village-out primary buyer contrasts remain identified. WCR31 test-inversion intervals are unavailable in this R implementation, so the main reported intervals remain CR2. [Inference ladder](../output/ihds_inference_ladder.csv), [bootstrap diagnostics](../output/ihds_wild_bootstrap.csv).

The Bihar-only model has no upper-majority nonbuying owners. Its buyer gap can be estimated with very wide uncertainty; its owner gap and buyer-minus-owner contrast are explicitly unidentifiable. We test each requested contrast rather than let software's omitted-column choice supply a number.

## What was completed

The [analysis plan](ihds-replication-plan.md) was committed before the first outcome fit, with pre-fit amendments for SC comparisons and the independent audit's support concerns. Data dictionaries, joins, code/label recodes, missingness, village representation and input hashes are saved. An independent reader also reproduced the main point estimates by direct weighted matrix algebra and verified the denominator reversal on the common sample. Unit tests cover unknown land shares, missing pump ownership, unit conversion, estimable versus unsupported contrasts, and weighted bootstrap equivalence.

Post-fit implementation repair: Bihar exposed a rank-deficient nuisance parameterization. The initial program withheld all its contrasts. We replaced that guard with a row-space estimability test, recovering only the identified contrasts; main-sample estimates did not change. The same repair retains an additional identified buyer contrast in the paired bootstrap. The bootstrap-interface adjustment preserves the planned estimator and WCR31 test rather than replacing survey weights.

These findings apply to the selected, classifiable majority villages and the later survey's related outcomes. No original-survey raw rank data, historical SHRUG placebo, physical-yield reconstruction, or causal IV replication was completed. SC dominance lacks enough villages. Other Indian states remain a separate future geographic extension.

Run `make ihds-replication` with the local `../land/data/ihds2/ICPSR_36151` archive available, or set `LAND_REPO`. Run `make test lint` for local validation. [All estimates](../output/ihds_replication_estimates.csv), [sample flow](../output/ihds_sample_flow.csv), [cell support](../output/ihds_replication_cells.csv), [scenario definitions](../output/ihds_scenario_definitions.csv).
