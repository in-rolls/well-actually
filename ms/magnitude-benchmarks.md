# How large is the claimed crop-sales gain?

Anderson's headline is a 45% advantage for lower-caste water buyers across village types. The supplied regression outcome is annual crop sales per acre owned, not physical output per cultivated acre or net farm profit. Its rupee coefficients reproduce; the supplied program does not show the denominator used to convert them into 45%. Treat 45% as a reported claim whose calculation remains unresolved.

The larger IV estimate is a separate result: on the same sample, the IV buyer interaction is about 3.85 times the OLS interaction. Rejecting the IV assumptions would not erase the OLS association, but would remove that proposed source of causal support.

## Comparisons grounded in original papers

| Study and intervention | Reported result and unit | Why it is useful, and what differs |
|---|---|---|
| Jensen (2007), mobile-phone coverage in Kerala fishing markets | About 8–9% higher fishing-unit profits. Table VIII reports daily revenue +₹205 (SE 62), costs +₹72 (SE 5.6), and profits +₹133 (SE 60), in 2001 rupees. | A major improvement in trading opportunities, with measured sales, costs and waste. It concerns fishing-unit profit rather than crop sales per owned acre. |
| Giné and Jacoby (2020), groundwater contracting in Andhra Pradesh | Section 6.3 estimates contracting distortions cost the median borewell owner 1.9% of seasonal income; all modeled groundwater-market distortions cost 5.9%. | Closer to Anderson's proposed irrigation-contract mechanism. These are structural counterfactuals for borewell owners, not an estimated caste effect on water buyers. |
| Asher, Campion, Gollin and Novosad (May 2024 working paper), access to India's irrigation canals | Section 6.1 reports approximately 7.1% higher winter and 1.7% higher monsoon-season satellite-derived agricultural productivity; irrigated share rises 7.5 percentage points. | A direct water-access comparison with season-specific outcomes. It uses a satellite proxy and a different design and population, rather than household sales records. |

Sources: [Jensen, pp. 883, 914–917 and Table VIII](https://web.stanford.edu/class/comm1a/readings/jensen-digital-divide.pdf); [Giné and Jacoby, pp. 428–429](https://www.econstor.eu/bitstream/10419/217191/1/0720-3479-1-PB.pdf); [Asher and coauthors, Section 6.1](https://paulnovosad.com/pdf/acgn-canals.pdf). These are deliberately transcribed published benchmarks, not newly replicated estimates. Jensen's introduction summarizes the profit gain as 8%; the main results describe ₹133 as about 9%. The range records that difference rather than silently selecting one. We now have local copies of these papers, but not Jensen's underlying survey data.

The comparisons make 45% a demanding claim. They do not establish an upper bound on what irrigation or caste barriers can do. In particular, a gain averaged over many producers is not the same estimand as a gain for a selected set of water buyers, and profit percentages cannot be ranked mechanically against revenue percentages. Anderson needs evidence that the particular difference in water delivery between these village groups could generate the claimed sales difference. That evidence would include changes in irrigated acreage, timing and quantities of water, crop-specific output, costs and sale shares.

Jensen's paper also offers a useful standard for demonstrating a mechanism: it links the introduction of phones to changes in where fishermen sell, unsold catch, prices, revenue and costs. The irrigation replication archive has no comparable transaction-by-transaction account of how caste changes water delivery and then farm returns.

## A village can adjust in more ways than current crop sales

The canal study explicitly investigates the wider adjustments: its introduction reports 22% higher population density in directly irrigated settlements and growth of regional towns. It distinguishes local agricultural effects from population movements and spillovers. This is evidence for studying those margins in Anderson, not a replication of Anderson's setting or a rejection of her instruments. [Asher and coauthors, pp. 3–5](https://paulnovosad.com/pdf/acgn-canals.pdf).

Access to water can influence where people settle, the demand for land, investment, crop choice, tenancy, and disputes over scarce resources. Those are plausible pathways into both the historical composition of villages and current returns. A variable's historical origin does not establish that it is independent of such pathways. Current groundwater depth can also respond to extraction; an engineering threshold, a geological measure, and current water access therefore require different identifying arguments.

Sekhri's “Wells, Water, and Welfare” studies poverty and irrigation disputes using a change in pumping technology at an eight-meter depth threshold. It supplies a relevant example of water access affecting more than water purchases. This citation is based on the publisher abstract, not a full replication or audit of that study. It uses a different identification strategy from Anderson. [Sekhri (2014), publisher abstract](https://www.aeaweb.org/articles?id=10.1257/app.6.3.76).

A targeted search has not identified a paper that directly demonstrates the invalidity of Anderson's exact generated-instrument specification. The substantive objection does not require such a predecessor: village area and natural-water access need a convincing argument for why their relation to crop sales operates only through the modeled buying channel, conditional on controls. It is also necessary to justify the assumed exogeneity of caste dominance, which the IV does not itself instrument. Our direct-effect sensitivity shows why identifying a possible pathway is only the beginning: its direction, magnitude, and variation across groups determine its effect on the estimate.

## Check the definition of dominance

The paper defines the dominant caste as the group owning the majority of village land. Its historical narrative also describes lower-caste-dominated villages as having almost no upper-caste residents (pp. 239, 242–245). This may be a comparison of quite different settlement types; we should not assume that it is driven by villages barely above or below 50%.

The original village questionnaire adds an important distinction: Section 1A question 7 records caste ranks by total land ownership, rather than land-share percentages. The highest rank need not imply majority ownership. We need the construction code and raw ranking records to resolve how the paper maps this information to its stated definition. See the [raw-survey follow-up](raw-survey-followup.md).

The supplied files contain the binary dominance label but not the underlying village land shares or the code constructing that label. We therefore cannot yet rerun the comparison at alternative cutoffs or show how close villages lie to the threshold. Household land shares calculated from the selected lower-caste regression sample would not recover village-wide ownership shares.

With the original village ownership data, the useful audit is to reproduce the label, plot the land-share distribution, and report results across a stated set of cutoffs alongside a continuous land-share relationship. Excluding villages near the boundary would reveal sensitivity to ambiguous classification, while also changing the sample and reducing precision. Counts and overlap must accompany every specification, and all selected cutoffs should be reported. A cutoff is a researcher classification here, not evidence of an actual discontinuity in caste relations or a valid regression-discontinuity design.

The [balance and land-ownership audit](water-balance.md) records what we can test now and the precise survey-to-Census crosswalk needed for historical SHRUG checks.
