# Choosing and documenting age groups

Summary for the agecraft vignettes · 17 November 2026

## Shared introductory text

Age groups are analytical choices. Their boundaries determine which age-related differences remain visible and which are combined into a single summary. A useful scheme preserves distinctions relevant to the question, supports reliable estimates, and permits the intended comparisons. Published schemes provide a starting point, but their suitability depends on their purpose and on the available observations and population denominators.

An age scheme brings interval definitions together with information about their origin and intended use. Provenance records the source and history of a scheme, including its version and any adaptations. Purpose and rationale explain what the scheme was designed to describe and why its boundaries are useful. These concepts help readers assess whether a scheme is appropriate for a new analysis.

## Two complementary vignettes

### The age_scheme class: representing and documenting a choice

Start with the shared introduction, then explain how the implemented class represents the interval definitions and available metadata. Map each concept to its actual storage and supported accessors after inspecting the current implementation. This summary proposes documentation content; it does not assert that every item below is an existing field or prescribe a class redesign.

| Concept | What readers should learn |
| --- | --- |
| Interval definitions | How the scheme represents bounds, units, endpoint inclusion, labels, ordering, and any open-ended final interval. |
| Provenance | Where the scheme originated: organization, publication or URL, date or version, and adaptations. |
| Purpose and rationale | Intended application, relevant population, and reasons for the boundaries. |
| Classification | How interval definitions are used to assign observations to an age_group, keeping definitions distinct from classified results. |
| Limitations | What the scheme does not establish about suitable denominators, precision, or fitness for a particular question. |

Use one sourced scheme throughout. If purpose or adaptation information lacks a dedicated field, explain the supported way to document it rather than implying a field exists.

### Choosing age groups: making and defending a choice

Start with the same concepts, then work through these decisions:

1. **Question and purpose.** Distinguish disease surveillance, vaccination coverage, population description, and age adjustment. They can require different boundaries.
2. **Age-related risk.** Use sufficient detail where disease occurrence changes rapidly. Do not assume all members of a broad age group share similar risk.
3. **Denominators.** For rates, match case and population boundaries, geography, period, and relevant population characteristics. A denominator for ages 0–4 cannot directly supply separate denominators for under 1 and 1–4.
4. **Precision.** Examine counts and uncertainty. Narrow groups preserve detail but can yield unstable estimates. Combining adjacent groups may help, at the cost of obscuring differences. There is no universal minimum count appropriate to every analysis.
5. **Comparability.** Establish which published reports, jurisdictions, and years need comparison. For age adjustment, use compatible age groups, weights, and methods; report the standard and scheme version.
6. **Boundary clarity.** Define units, endpoint inclusion, the oldest group, and handling of missing or out-of-range ages. For continuous ages, a label such as 1–4 commonly represents the interval from the first birthday up to, but excluding, the fifth birthday.
7. **Documentation.** Record the chosen scheme, its source, any adaptation, and why it suits the analysis. Keep precise ages when appropriate and permitted so alternative groupings remain possible.

These decisions guide analysis; they need not all become metadata fields in the class.

## Worked example: what grouping can conceal in pertussis data

Use the same observations, geography, period, and denominator source in every comparison. Prefer three main views, with an optional infant detail view.

| View | Proposed intervals in years | Teaching purpose |
| --- | --- | --- |
| CDC childhood surveillance pattern | Under 1; 1–4; 5–9; 10–14; 15–19; 20+ | Preserve the infant distinction and childhood detail. This matches the pattern in CDC's archived epidemiology guidance. |
| Uniform five-year groups | 0–4; 5–9; 10–14; 15–19; then five-year adult groups | Show what happens when infant cases and population are pooled with ages 1–4. |
| Uniform ten-year groups | 0–9; 10–19; 20–29; then ten-year adult groups | Show the further loss of childhood detail. |
| Optional infant detail | Month-based intervals within the first year, selected for a stated question | Explore age in relation to vaccination opportunities, only if age precision, counts, and denominators support it. |

Specify the full adult range and terminal group when building the example. For the clearest initial comparison, display the childhood portion of each scheme so adult differences do not distract from the infant example. If broader adult groups differ from the cited CDC scheme, identify the result as an adaptation.

The CDC childhood surveillance pattern is not a vaccine administration schedule. A separate, vaccine-informed infant scheme can be useful, but its boundaries need a specific rationale and an explicitly cited schedule version. Vaccination coverage by a milestone, such as 24 months, is also a different measure from disease incidence within an age interval.

Plot age-specific incidence rates on a common vertical scale and show counts and uncertainty where feasible. Make interval widths explicit. If using a histogram whose area represents frequency, account for unequal interval widths; a labeled point plot of rates can avoid that display complication.

The pooled 0–4 rate is total cases divided by total population across those ages, multiplied by the rate scale. It is a population-weighted combination of the component rates, not their simple arithmetic mean. A lower pooled rate can conceal higher infant incidence without changing the underlying cases or risk. The result depends on the chosen data: do not manufacture an infant peak or assume every pertussis dataset will show the same pattern.

CDC's historical pertussis example illustrates this principle directly. If its exact numerical data cannot be recovered, use clearly labeled simulated data or an independently documented dataset. Do not present reconstructed values as CDC observations.

## Sources and their roles

The following sources were reviewed during the discussion. Historical teaching guidance is identified as such; example schemes should not be described as universal current reporting requirements.

1. **CDC, Principles of Epidemiology, Lesson 5, Section 5 (archived).** Supports disease-dependent grouping, the childhood scheme, mutually exclusive and comprehensive categories, and matching population denominators. https://archive.cdc.gov/www_cdc_gov/csels/dsepd/ss1978/lesson5/section5.html
2. **CDC, Principles of Epidemiology, Lesson 1, Section 6 (archived).** Provides the pertussis example comparing ages 0–4 with separate infant and 1–4 groups. https://archive.cdc.gov/www_cdc_gov/csels/dsepd/ss1978/lesson1/section6.html
3. **CDC, Vaccination Coverage by Age 24 Months Among Children Born in 2021 and 2022.** Distinguishes the 19–35-month survey eligibility range from coverage assessed by a specific age. https://www.cdc.gov/mmwr/volumes/75/wr/mm7511a2.htm
4. **NCI SEER, Calculating Age-adjusted Rates.** Describes the 20-group scheme ending with 85–89 and 90+, and the previous 19-group scheme ending at 85+. This illustrates why a scheme's version matters. https://seer.cancer.gov/seerstat/tutorials/aarates/definition.html
5. **U.S. Census Bureau, Age and Sex Composition: 2020.** Illustrates demographic presentation with five-year groups and detailed older ages. https://www2.census.gov/library/publications/decennial/2020/census-briefs/c2020br-06.pdf

## Suggested cross-references

End the class vignette's introduction by directing readers to the selection vignette for reasons to choose particular boundaries. In the selection vignette, direct readers to the class vignette for constructing and documenting the chosen scheme. Keep the full risk example in the selection vignette and use a short reference to it in the class vignette.
