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

The internal IHDS household-to-village join supports a survey-only replication. Linking IHDS or Anderson to administrative land records or Census/SHRUG requires a separate verified geographic crosswalk.

## IHDS replication recode and join resolution

The frozen plan uses Hindu OBC/SC farm households, positive maximum owned acreage across three fully observed seasons, and explicit FM3 conversion. Cultivated acreage is the sum of three fully observed seasons. Pump nonownership requires three reported zeros; any observed positive establishes ownership unless an invalid negative is present. Missing values never establish nonbuying/nonownership. Complete-case regression exclusions are recorded in `ihds_sample_flow.csv`, field/skip missingness by exposure in `ihds_measurement_missingness.csv`, and categorical recodes in `ihds_recode_*.csv`.

Household IDHH is unique; the full state–district–PSU village key is unique on DS12. The household-left join preserves42,152 rows; all3,789 rural UP/Bihar households link. DS14 participant records are aggregated before the village join and cannot multiply households. Four duplicate participant-key rows occur outside UP/Bihar and are excluded from roster aggregation; target-state participant keys are unique. The target195 villages all have a roster. Input SHA256 values are in `ihds_input_provenance.csv`; no household-level extract is redistributed.

The outcome is the released FM22RSHH crop-value aggregate, which the user guide lists separately from residue and expenses. Its crop-row construction remains unavailable. INCCROP explicitly subtracts expenses and may be negative. The dictionary therefore does not equate either measure with Anderson’s cash crop sales.

## Other available data

The IHDS comparison has been executed; its estimates and sample restrictions are in the [replication report](ihds-replication.md). The following records describe additional data already inspected, not completed new outcome analyses.

### Bihar land records

No land-record outcome replication has been run. The available administrative records cannot test Anderson's economic claim without farm outcomes for the same villages. Linking them to IHDS requires a verified village crosswalk and evidence that ownership dates are comparable to the 2011–12 survey outcomes. The required inputs are an IHDS village-to-Census crosswalk and the land notebook's `br_lr_census_crosswalk.dta`. If geography and dates can be verified, compare the same IHDS households using reported versus recorded ownership and the existing farm-outcome definitions. Otherwise, do not proceed with this extension.

### NSS 77 (2018–19)

The repository contains the raw Nesstar source, DDI dictionary, and 35 converted block files for two visits, not just the household land summary. The Bihar first-visit extract contains 5,111 households. Crop blocks distinguish irrigated and unirrigated area and production and record sales quantities; irrigation-source categories are also available. This makes NSS useful for checking whether large revenue differences reflect physical output, crop mix, commercialization, or land denominators.

A close buyer/owner mechanism replication still needs verified questionnaire item mappings for purchased water and pump ownership. Input and asset blocks use serial-number codes whose detailed meanings are not supplied by the variable labels alone. The questionnaire must establish these mappings before estimation. NSS household and village identifiers also require a separate, validated linkage to land records; a PSU serial is not a public revenue-village name. Verify the eligibility of the land and agricultural-output blocks separately rather than assume every household supplies farming outcomes.


The IHDS inventory is `src/ihds_feasibility.R`; run `make external-feasibility` with `LAND_REPO` pointing to the local land repository. Original observations remain in that repository.
