# External data: initial dictionary, recode ledger and join contract

Data definitions for the [completed IHDS replication](ihds-replication.md), with availability and measurement limits for the other local datasets. Source documents are the local ICPSR 36151 DS0002 and DS0012 codebooks and questionnaires, NSS 77 Schedule33.1 DDI, and ../land's processing notebooks. Outstanding definitions are explicit below.

| Construct | Source fields | Meaning / universe | Rule or unresolved issue |
|---|---|---|---|
| Household and village link | IHDS STATEID, DISTID, PSUID | Sampling geography in household and village files | Composite key; village side unique; do not use PSUID alone. Household IDPSU provides a separate cluster identifier. |
| Rural residence | URBAN2011 | All interviewed households | Code0 rural; parse numeric factor labels, not R factor positions. |
| Hindu household / broad caste | ID11, ID13 | All interviewed households | Religion1 Hindu; caste3 OBC,4 SC,5 ST. Inventory includes3:5; final Anderson-like restrictions still to be frozen. |
| Farm questionnaire eligibility | FM1 | Owns or cultivates agricultural land | No means farm module skipped. A yes can be a landless tenant. Do not convert missing farm answers into zeros indiscriminately. |
| Purchased irrigation water | FM31; derived FM31RS | Annual rupee expenditure; raw item asked in farm block | Positive raw expenditure is a purchase proxy. Zero/free transfers and missing/skip require separate treatment; derived zero-filled item not interchangeable. |
| Tubewell / pump ownership | FM40A, FM40B, FM40C | Counts of tubewells, electric pumps, diesel pumps among farm respondents | Any positive is an inventory owner. All missing is unknown, not verified nonownership. Does not identify water sales. |
| Land conversion | FM3 | Local land units per acre | Divide local-unit areas by positive FM3. Missing/nonpositive conversion is unresolved, not one acre. |
| Owned / held / cultivated land | FM4A:C, FM7A:C, FM11A:C | Seasonal local-unit acreage | Retain season. FM7 accounts for land leased in/out. Do not divide annual crop value by an arbitrary seasonal denominator without stating it. |
| Gross crop value | FM22RSHH | Aggregate crop-income/value variable for farm households | Available, but not a verified cash-sales total; component conversion trace still required. |
| Crop income after expenses | INCCROP | Household aggregate, can be negative | Retain legitimate negatives; does not necessarily deduct every economic opportunity cost. |
| Crop production / sales / price | Questionnaire FM20–FM25 | Crop × season × irrigation/tenure rows | Asked in questionnaire; corresponding released rows not yet located. Do not infer availability from questionnaire alone. |
| Village caste/rank/religion | VJ3A:I, VJ4A:I | Listed jatis in village questionnaire | Caste1 Brahmin,2 other Forward,3 OBC,4 SC,5 ST,6 other; religion1 Hindu. Religion and caste must be combined for Hindu upper caste. |
| Caste agricultural land shares | VJ6A:I | Percent of all village agricultural land owned by listed jati | Validate0–100 and sums; omitted groups leave unresolved land. Never renormalize listed shares to100 for majority classification. |
| Village population caste shares | VH1A:F | Reported village population percentages | Distinct from land shares; residents distinct from absentee titleholders. |
| Household weight | WT | IHDS survey weight | Keep explicit; final survey design and stratum construction still to be documented. |
| NSS land/crop inputs | Block5/5.1;6;7;12; identification block | Household land, crop rows, input rows, asset transactions by visit | Verify each block's universe and item serial codes, annual reference periods and multipliers before constructing outcomes. |

The feasibility recodes are deliberately limited. Missing raw water expenditure is counted as no positive report for the displayed purchase count, not assigned nonbuyer status for a regression. Similarly, no positive pump count is not enough to establish nonownership. Counts are before final analytical restrictions. ICPSR labelled factor codes are extracted from the numeric code printed in parentheses; numeric fields remain numeric.

For land-share coverage, the lower bound on upper-Hindu ownership is the sum assigned to listed Hindu Brahmin/Forward jatis. The upper bound is100 minus land positively assigned to other castes or religions. The remainder includes omitted jatis, missing shares, and uncertain classifications. A threshold comparison is unresolved when the interval straddles the threshold. This bounds the classification conditional on reported values; it does not model errors in the reports.

The land/geography join uses ownership-account identifiers without floating-point conversion: records hold int64 IDs, geography holds16-character strings with leading zeros. Convert the strings to integer64 and verify uniqueness on both sides. The join preserves each matched account once. Exclusions above10,000 acres follow the existing land notebooks, not a new outcome-selected threshold. The raw-source audit now verifies that no observed account spans multiple locations and that every saved account location agrees with the raw file. This establishes consistency within the supplied geography source, not complete coverage of the larger land register.

No link between Anderson IDs and IHDS IDs is intended: these are independent samples. Linking either survey to Census/SHRUG or 2022 land titles requires its own geographic crosswalk and coverage audit. The current internal IHDS join is sufficient for a survey-only independent test, but not for a title-record validation.

## IHDS replication recode and join resolution

The frozen plan uses Hindu OBC/SC farm households, positive maximum owned acreage across three fully observed seasons, and explicit FM3 conversion. Cultivated acreage is the sum of three fully observed seasons. Pump nonownership requires three reported zeros; any observed positive establishes ownership unless an invalid negative is present. Missing values never establish nonbuying/nonownership. Complete-case regression exclusions are recorded in `ihds_sample_flow.csv`, field/skip missingness by exposure in `ihds_measurement_missingness.csv`, and categorical recodes in `ihds_recode_*.csv`.

Household IDHH is unique; the full state–district–PSU village key is unique on DS12. The household-left join preserves42,152 rows; all3,789 rural UP/Bihar households link. DS14 participant records are aggregated before the village join and cannot multiply households. Four duplicate participant-key rows occur outside UP/Bihar and are excluded from roster aggregation; target-state participant keys are unique. The target195 villages all have a roster. Input SHA256 values are in `ihds_input_provenance.csv`; no household-level extract is redistributed.

The outcome is the released FM22RSHH crop-value aggregate, which the user guide lists separately from residue and expenses. Its crop-row construction remains unavailable. INCCROP explicitly subtracts expenses and may be negative. The dictionary therefore does not equate either measure with Anderson’s cash crop sales.

## Other available data

The IHDS comparison has been executed; its estimates and sample restrictions are in the [replication report](ihds-replication.md). The land-record measurement checks below have also been executed. A linked administrative-record/IHDS outcome analysis and an NSS outcome analysis remain unrun.

### Bihar land records (2022)

The records collected in 2022 permit a separate measurement exercise: compute village ownership shares from recorded titles, contrast the largest group with an actual majority, and examine concentration, plot fragmentation and land type. Retain both narrow and broad agricultural definitions because upland `bhith` is mixed. Use recorded caste entries with the curated crosswalk additions and retain an explicit unclassified-area category; do not classify a person from a name just to fill the gap.

The cached intermediate has 11,688,307 ownership accounts. Following the existing land analysis, removing the 50 accounts with total area above 10,000 acres leaves 11,688,257. The existing geography crosswalk links 7,402,631 of those accounts across 29,396 villages, covering 8.89 million of 13.82 million retained acres. This is partial coverage, not a complete village census established by the join. The stored caste categories also predate curated additions. The broad `uc` crosswalk category includes some Muslim jatis, so it cannot be equated with Hindu upper caste without using the recorded religious/caste information consistently.

The land register does not contain landless households, realized crop outcomes, water purchases, or confirmed household residence in the village where a title is held. Administrative accounts are not necessarily people or households. The 2022 records cannot be treated as a baseline covariate for a 2011 or 1997 outcome. An external measurement validation requires an audited village-name/geographic crosswalk plus explicit treatment of date changes and unmatched areas. Do not replace missing survey geography with a district-wide exposure.


### Completed land-record measurement checks

`make land-measurement` scans the raw geography file and constructs village ownership shares. It leaves `../land` unchanged. Local account and village Parquet outputs are excluded from Git; the linked CSV summaries contain aggregate diagnostics.

**Geography passes its internal check.** All 29,275,117 raw rows were scanned without parsing failures. The 7,859,522 accounts each have one complete location; none disagrees with the saved crosswalk. Village keys also uniquely identify the full district/subdivision/zone/mauja tuple. This does not resolve why the separate ownership file contains additional accounts without geography. [Geography audit](../output/land_geography_audit.csv).

**The agricultural definition matters.** The narrow definition sums paddy, other cropland and fallow land; the broad definition adds upland `bhith`. Both retain the upstream exclusion of accounts above 10,000 total acres. The narrow linked sample contains 3,758,751 agricultural accounts, 4.68 million acres and 26,620 villages. An additional 2.58 million agricultural acres have no verified geography. These are observed account holdings, not household holdings or a complete village land census. [Area and linkage coverage](../output/land_ownership_coverage.csv).

**Unknown caste stays in the denominator.** We use recorded caste strings, the base crosswalk and its 21 mapped additions. The crosswalk includes 43 duplicated strings with identical assignments, which are collapsed without changing labels; no conflicting category assignments were found. The stored `cat4` omits the additions. The processed account religion field involves name prediction, so this analysis instead uses the crosswalk's religion coding. `upper`, `obc`, `sc` and `st` here mean the corresponding non-Muslim-coded caste groups; non-Muslim is not independently verified Hindu identity. Muslim-coded castes are separate, and unresolved strings or religion codes remain unknown. No new name-based classifications are made.

Under the updated crosswalk and narrow land definition, 30.7% of linked agricultural acreage remains unclassified. An ownership share's lower bound assigns none of that unknown acreage to the group; its upper bound assigns all of it. These bounds address unknown coding within the linked records only. They do not cover incorrect known labels or land absent from the records.

| Group | Villages definitely above 40% | Above 50% | Above 60% |
|---|---:|---:|---:|
| Upper caste | 9,013 | 7,571 | 6,232 |
| OBC | 9,350 | 7,549 | 5,988 |
| SC | 257 | 188 | 145 |

At the 50% cutoff, 16,132 villages have an established majority group among the recorded acres, 490 definitely have no majority, and 9,998 remain unresolved. Thus a ranked list cannot simply be read as majority ownership. The files retain continuous shares, the gap between the two largest known groups and a check of whether unknown acreage could change the largest group. [All cutoffs and unresolved counts](../output/land_ownership_thresholds.csv), [ownership summary](../output/land_ownership_summary.csv).

**Several choices change the classifications.** Updating the caste crosswalk resolves 601 previously uncertain village classifications. Adding `bhith` changes 2,377 classifications among the same 26,620 villages and adds 1,822 villages with no narrow-definition agricultural land. Among the common villages, 105 switch from upper-caste to OBC majority and 108 switch the other way. These are changes in the measured exposure, not changes in estimated effects. [Coding transitions](../output/land_coding_transitions.csv), [land-definition transitions](../output/land_area_transitions.csv).

**SC majority counts are especially sensitive to sparse records.** Of 188 narrow-definition SC-majority villages, only 32 have at least 50 observed agricultural accounts; requiring at least 90% classified acreage as well leaves 23. The corresponding counts are 3,574 upper-caste and 2,940 OBC-majority villages. The account and coverage floors are sensitivity checks, not proof that the remaining records are complete. [Support checks](../output/land_ownership_support.csv).

**OBC majority is not synonymous with Yadav majority.** The updated narrow-definition file establishes a Yadav majority in 2,024 villages, versus 7,549 villages with an OBC majority. This makes the broader OBC measure a substantively different exposure from dominance by a particular agricultural caste. [Jati counts](../output/land_jati_majorities.csv). Descriptive account-size, land-type and concentration comparisons are in [ownership profiles](../output/land_ownership_profiles.csv); they do not establish productivity differences.

**Geography coverage is selective.** In the narrow definition, the direct geography file covers 70.5% of upper-caste-coded agricultural acreage, 64.3% of OBC acreage and 60.7% of SC acreage. That is a reason to investigate missing records, not to assume the linked villages contain a representative set of owners.

**An account-prefix extension changes relatively few classifications.** Prefixes of six and eight digits map to multiple villages; among the observed accounts, ten-digit prefixes map to one village each. A lookup based on 80% of accounts and at least 20 reference accounts per prefix predicts locations for 1,564,922 held-out accounts without a disagreement. This is an internal consistency check: the prefix length was suggested by inspection of the full data, and agreement among known accounts does not validate locations for previously unmatched accounts.

Using all directly located accounts as references, the same rule supplies candidate locations for 190,740 additional accounts in 251 villages; 190,739 survive the area exclusion. Their total recorded area is 223,462 acres, including nonagricultural land. Each inferred location is flagged separately in the local extended file. The [prefix audit](../output/land_prefix_audit.csv) and separate [extended ownership results](../output/land_prefix/land_ownership_summary.csv) preserve this distinction. In the updated narrow-definition comparison, the extension adds six agricultural villages and changes 28 majority classifications among the original 26,620. Most originally unmatched accounts remain unmatched. [Geography transitions](../output/land_prefix_transitions.csv).

These checks prepare and stress-test the exposure. They do not test Anderson's crop-sales effect, establish village landlessness, or substitute for the missing IHDS geographic link. Original files and derived linkage inputs are fingerprinted in [input provenance](../output/land_dominance_provenance.csv).

### Combining land records with IHDS outcomes

This would replace the survey's collective report of caste land ownership with an exposure constructed from administrative records. For verified common villages, compare survey and recorded shares, largest-group and majority classifications, continuous shares and 40/50/60% cutoffs. Re-estimate the IHDS buyer comparison on exactly the same matched households with each exposure, retaining the separate owned-area and cultivated-area outcomes. Report unmatched villages and unclassified acreage. The replacement is a measurement check; it does not make caste dominance exogenous or constitute an IV first stage.

The local linkage inspection on 2026-09-07 found:

- `../land/scripts/crosswalk_district_block_village.ipynb` references `data/br_lr_census_crosswalk.dta`, described as supplied by Aaditya. That input is absent from the inspected local data directory. The notebook joins land-record district/block/village names to Census geography; it does not supply an IHDS link.
- IHDS DS0002, DS0011 and DS0012 contain internal state/district/PSU identifiers. DS0012 also contains `VILL`, labelled village code, but it has only 29 distinct values across 1,410 rows. The inspected files provide no verified Census village identifier or village-name crosswalk. The user guide (pp. 11–12) describes `IDPSU` as a constructed survey-cluster identifier.
- The `census_village_surname_jati.parquet` and `surname_census_bridge.parquet` files are Mahadalit-census surname/jati lookup products, not IHDS-to-Census geographic crosswalks.

The administrative records cover Bihar. IHDS-II contains 1,085 rural Bihar households in 60 villages before farming and caste restrictions; linked analytical support can only be smaller. The records were collected in 2022, whereas IHDS outcomes refer to 2011–12. A linked comparison would therefore require evidence on record vintages and ownership changes; without it, later recorded ownership cannot be treated as a predetermined cause of earlier outcomes. A geographic crosswalk would also permit historical Census/SHRUG balance checks, but those links have not been executed.

**Status:** survey-only IHDS replication and land-record measurement checks complete; combined administrative-exposure/IHDS-outcome analysis not run. The immediate missing inputs are the IHDS village crosswalk and the referenced land-to-Census crosswalk, followed by verification of village boundaries, record coverage and dates.

### NSS 77 (2018–19)

The repository contains the raw Nesstar source, DDI dictionary, and 35 converted block files for two visits, not just the household land summary. The Bihar first-visit extract contains 5,111 households. Crop blocks distinguish irrigated and unirrigated area and production and record sales quantities; irrigation-source categories are also available. This makes NSS useful for checking whether large revenue differences reflect physical output, crop mix, commercialization, or land denominators.

A close buyer/owner mechanism replication still needs verified questionnaire item mappings for purchased water and pump ownership. Input and asset blocks use serial-number codes whose detailed meanings are not supplied by the variable labels alone. The questionnaire must establish these mappings before estimation. NSS household and village identifiers also require a separate, validated linkage to land records; a PSU serial is not a public revenue-village name. Verify the eligibility of the land and agricultural-output blocks separately rather than assume every household supplies farming outcomes.


The executable inventories are `src/ihds_feasibility.R` and `src/land_readiness.R`; run `make external-feasibility` with `LAND_REPO` pointing to the local land repository. The land check uses arrow, data.table and bit64. Original observations remain in that repository.
