# Raw survey files that would resolve specific questions

The public World Bank DDI dictionary and original village questionnaire identify useful data outside Anderson's four prepared files. The raw download currently requires a World Bank login. The dictionary is metadata, not the underlying observations.

| Question | File and fields | What access would make possible |
|---|---|---|
| Where are these villages? | `PSULIST`: `village`, `state`, `district`, `stratum`, `vname`, `weight` | Recover survey ID, name, district, sampling stratum and raising factor together. Validate against Anderson's IDs, then construct an audited Census/SHRUG link. The public dictionary lists village names but does not pair them with survey IDs. |
| How was dominance classified? | `VILL01A1`: caste codes `q1a07b1`–`q1a07b7`, total-land ranks `q1a07d1`–`q1a07d7`, average-holding ranks `q1a07e1`–`q1a07e7` | Reconstruct which group ranked first, distinguish total-land dominance from average holding size, and check correspondence with the supplied binary label. |
| Does the gap also appear in physical crop yields? | `VILL03A`: `crop1p`–`crop9p`, with their corresponding crop identities and prices | Compare reported village crop yields in kg per acre and crop prices, rather than treat household sales as physical output. These are respondent reports, not crop-cut measurements, and the village average is not the household buyer-specific outcome. |
| Was irrigation plentiful and available year-round? | Village questionnaire Section 3A, questions 9–12; raw file `VILL03A` | Inspect irrigation share, seasonality and plentiful supply separately for canals, public/private tubewells and other sources; verify exact variable mappings and ordinal codes before estimation. |

Section 1A question 7 records ranks, not land-share percentages. First in the ranking does not logically imply more than half of the land. The paper describes majority ownership, while the supplied program starts with an already-created binary indicator. This leaves an unresolved construction question, not a demonstrated miscoding: the authors may have used additional information that is not in the supplied program. Moving a numerical majority cutoff requires actual shares; rank data alone cannot support that exercise.

Section 1A also asks for the village name and whether its population grew or declined over the preceding ten years. Such reported history could help describe village adjustment, but would not constitute an untreated placebo for longstanding caste institutions.

Sources inspected September 6, 2026: [World Bank public DDI dictionary](https://microdata.worldbank.org/metadata/export/276/ddi), [village questionnaire, printed pp. 1 and 8–9](https://microdata.worldbank.org/catalog/276/download/11637), and [raw-data access page](https://microdata.worldbank.org/catalog/276/get-microdata). The questionnaire's caste-ranking table was also checked in the rendered PDF.

Once raw data are available, first check identifiers, duplicate records, missing-value codes, sample membership and sampling weights. Then reproduce dominance from the ranking fields, audit the geographic crosswalk, and compare the physical-yield measures. Publish the complete set of exploratory comparisons and their uncertainty, including results consistent with the original interpretation. Do not silently replace the original estimate's population with the subset that happens to link.
