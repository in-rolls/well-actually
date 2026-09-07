# An independent replication with data already in ../land

The strongest immediate candidate is IHDS-II, an independent 2011–12 household and village survey. Anderson used the 1997–98 World Bank UP–Bihar survey; she did not collect that survey herself. IHDS-II did not supply her data. The 2022 Bihar land records and NSS 77 (2018–19) offer additional measurements, with different strengths and limits.

This is a feasibility assessment and proposed design, not an executed outcome analysis or a frozen pre-analysis plan. We have examined questionnaires, codebooks, variable availability, sample counts, village joins, and reported caste-share coverage. We have not estimated an association between dominance and farm outcomes in these new data.

## What is already feasible in IHDS-II

The local ICPSR 36151 archive contains 42,152 households and 1,410 village questionnaires. For rural UP and Bihar, there are 3,789 households in 195 sampling villages, all linked to a village questionnaire using state, district, and PSU together. Bihar contributes 1,085 households in 60 villages; UP contributes 2,704 in 135. There are 197 village-questionnaire rows for these states, of which 195 link to rural household observations.

Before final eligibility and complete-case restrictions, 1,269 OBC/SC/ST Hindu households report positive water expenditure and 410 report at least one tubewell, electric pump, or diesel pump. These categories overlap. They are sample feasibility counts, not the final analysis N or counts of market sellers. ST is included in this inventory; a closer Anderson comparison would separate OBC/SC from ST because the original prepared households contain BAC, OBC, and SC. IHDS's broad OBC code also does not recover Anderson's BAC-versus-artisan-OBC distinction.

The village questionnaire asks each listed jati's share of total agricultural land. However, the list need not cover all castes or all land. Among the 195 linked UP–Bihar villages, reported shares have a median total of 87%. Missing share cannot be silently assigned to lower castes or removed from the denominator. At a strict upper-Hindu majority cutoff (>50%), the reported information establishes 32 villages above the threshold and 120 at or below it, leaving 43 unresolved. This classifies upper-Hindu majority, not OBC dominance: the latter needs its own construction. The 40% and 60% sensitivity counts are retained in the output.

## The proposed independent test

Start with rural UP and Bihar, then reserve other states as a separate geographic extension. Among lower-caste cultivating households, estimate the village-dominance contrast separately for water purchasers and pump owners and test the difference directly. Use the same definition for each group across village types and retain households who both buy water and own pumps as an explicit overlapping category or interaction combination. Ownership does not establish that a household sells water; expenditure does not identify the seller's caste or distinguish free transfers from no use.

The first requirement is a defensible outcome. The released household file contains gross crop value (`FM22RSHH`) and crop income after expenses (`INCCROP`). These are not Anderson's crop sales measure. The household questionnaire separately asks crop quantities produced, quantities sold, prices, crop areas, and seasons, but the corresponding crop-level rows have not been located in the supplied household file. Do not claim physical-yield or sales replication until those records are found. With the existing aggregates, a test of crop value and income per owned versus operated/cultivated acre is feasible, with explicit seasonal denominators; it is a related outcome replication.

Before fitting outcomes, settle the primary comparison and record the analysis plan. Proposed checks are a strict majority versus largest-listed-jati comparison; 40/50/60% share cutoffs; continuous shares where coverage permits; bounds for unreported land shares; and the same construction restricted to well-covered villages. Report the sample changes caused by each definition. A wider unresolved range is information, not a reason to normalize shares to 100%.

Use survey weights and the full state–district–PSU clustering key. Count usable villages and buyer/owner households in each dominance category after all measurement restrictions, then assess whether intervals could distinguish an economically small difference from a 45% difference. Normalize percentage effects to a prespecified comparison-group mean in the same outcome and sample, with uncertainty for that conversion. A newer rupee coefficient cannot be compared directly with 1997 rupees.

The mechanism tests should compare crop value, income after expenses, sales shares and crop-specific physical output where available; irrigation use and spending; and buyers versus owners. Landlessness, tenancy, crop choice and irrigation investment can be part of the mechanism or village adjustment, not automatic placebo outcomes. Historical geography can help assess comparability but does not automatically predate caste institutions. Replicating an association in new data would improve external validity; it would not solve the original causal identification problem.

## What the land records contribute

The records collected in 2022 permit a separate measurement exercise: compute village ownership shares from recorded titles, contrast the largest group with an actual majority, and examine concentration, plot fragmentation and land type. Retain both narrow and broad agricultural definitions because upland `bhith` is mixed. Use recorded caste entries with the curated crosswalk additions and retain an explicit unclassified-area category; do not classify a person from a name just to fill the gap.

The cached intermediate has 11,688,307 ownership accounts. Following the existing land analysis, removing the 50 accounts with total area above 10,000 acres leaves 11,688,257. The existing geography crosswalk links 7,402,631 of those accounts across 29,396 villages, covering 8.89 million of 13.82 million retained acres. This is partial coverage, not a complete village census established by the join. The stored caste categories also predate curated additions. The broad `uc` crosswalk category includes some Muslim jatis, so it cannot be equated with Hindu upper caste without using the recorded religious/caste information consistently.

The land register does not contain landless households, realized crop outcomes, water purchases, or confirmed household residence in the village where a title is held. Administrative accounts are not necessarily people or households. The 2022 records cannot be treated as a baseline covariate for a 2011 or 1997 outcome. An external measurement validation requires an audited village-name/geographic crosswalk plus explicit treatment of date changes and unmatched areas. Do not replace missing survey geography with a district-wide exposure.

## What NSS 77 contributes

The repository contains the raw Nesstar source, DDI dictionary, and 35 converted block files for two visits, not just the household land summary. The Bihar first-visit extract contains 5,111 households. Crop blocks distinguish irrigated and unirrigated area and production and record sales quantities; irrigation-source categories are also available. This makes NSS useful for checking whether large revenue differences reflect physical output, crop mix, commercialization, or land denominators.

A close buyer/owner mechanism replication still needs verified questionnaire item mappings for purchased water and pump ownership. Input and asset blocks use serial-number codes whose detailed meanings are not supplied by the variable labels alone. The questionnaire must establish these mappings before estimation. NSS household and village identifiers also require a separate, validated linkage to land records; a PSU serial is not a public revenue-village name. Verify the eligibility of the land and agricultural-output blocks separately rather than assume every household supplies farming outcomes.

## Next deliverables

1. Complete the variable dictionary, recode ledger and join contract, including all skip rules, units and dominance coverage bounds.
2. Locate any released IHDS crop-level records and the NSS item-code questionnaire; document unavailable measures explicitly.
3. Freeze the primary UP–Bihar comparison and outcome before running an outcome model. Record which definition and coverage information has already been inspected.
4. Build the sample-flow and buyer/owner-by-dominance counts, then assess precision. Run the prespecified tests and preserve unsuccessful and null findings.

The current executable inventory is `src/ihds_feasibility.R`; `src/land_readiness.R` checks the existing land/geography join without altering ../land. Set `LAND_REPO` if that repository is elsewhere. The land check additionally requires R packages arrow, data.table and bit64. All data remain in the original local repository. See [dictionary, recode ledger and join contract](external-data-dictionary.md).
