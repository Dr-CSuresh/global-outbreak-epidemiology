# Global Outbreak Epidemiology

This is a reproducible epidemiological analysis of global epidemic- and pandemic-prone disease outbreak reporting from 1996–2025.

This project explores temporal, geographic and disease-specific patterns in a global outbreak surveillance dataset, progressing from data cleaning and descriptive epidemiology through count regression, mixed-effects modelling, sensitivity analyses and spatial autocorrelation.

The aim was to demonstrate a structured epidemiological workflow in R by assessing data quality, choosing models according to the observed data-generating structure, checking assumptions and diagnostics, and testing whether conclusions were robust to influential epidemic periods.

# Data source

This project uses the Global Dataset of Pandemic- and Epidemic-Prone Disease Outbreaks developed by Torres Munguía et al.

The dataset compiles infectious disease outbreak information from the World Health Organization (WHO) Disease Outbreak News (DONs) and, for COVID-19, the WHO Coronavirus Dashboard

The unit of observation is a country–disease–year outbreak record: a country or territory is recorded as having an outbreak when at least one case of a specific disease was reported during that calendar year.

# Citation

Torres Munguía JA, Badarau FC, Díaz Pavez LR, Martínez-Zarzoso I, Wacker KM.  
A global dataset of pandemic- and epidemic-prone disease outbreaks. 
Scientific Data. 2022;9:683.  
https://doi.org/10.1038/s41597-022-01797-2

The continuously updated dataset and accompanying extraction code are maintained by the authors on GitHub:

https://github.com/jatorresmunguia/disease_outbreak_news

The source dataset is not redistributed within this repository.

# Overview

The source dataset contains country–disease–year outbreak records.

A record indicates that a country or territory had at least one reported occurrence of a disease during a calendar year.

- records are not individual cases
- counts are not incidence rates
- multiple cases within the same country–disease–year do not generate multiple observations
- a country-year with no record in the panel means no outbreak record was observed in this dataset but does not confirm absence of disease

The full dataset contained:

- 3,566 outbreak records
- 236 countries and territories
- 92 disease labels
- observations from 1996–2026
- data analysed september 22 2026

Because 2026 was incomplete at the time of analysis, inferential and completed-year temporal analyses were restricted to 1996–2025


# Research questions

This analysis addressed the following questions:

1. How has global outbreak reporting changed over time?
2. Which diseases, countries and world regions account for the greatest number of outbreak records?
3. How geographically widespread and temporally persistent are different diseases?
4. Is reported disease distribution associated with world region?
5. How should country-year outbreak counts be modelled statistically?
6. Are observed temporal patterns robust to the influence of COVID-19 and the 2009 influenza pandemic?
7. Do countries with similar levels of outbreak reporting cluster geographically?

# 1. Data cleaning and quality assessment

Raw variable names were standardised and the year variable converted to integer format.

The cleaned dataset contained 3,566 rows and 17 variables

# Missing data

| Variable | Missing n | Missing % |
| WHO region | 266 | 7.46 |
| Disease definition | 123 | 3.45 |
| UN region | 12 | 0.34 |
| UN subregion | 12 | 0.34 |
| ISO2 code | 6 | 0.17 |

Missing geographic classifications were concentrated in territories and special geographic entities rather than randomly appearing.

# Duplicate checks

No evidence of duplication was found:

- 0 duplicated rows
- 0 duplicated outbreak IDs
- 0 duplicated country–year–disease combinations


# 2. Descriptive epidemiology

# Temporal distribution

Notable annual counts included:

| Year | Outbreak records |
| 2009 | 207 |
| 2020 | 255 |
| 2021 | 274 |
| 2022 | 419 |
| 2023 | 368 |
| 2024 | 302 |
| 2025 | 375 |

!Annual outbreak records(figures/annual_outbreak_records.png)

A three-year centred rolling mean was used to visualise the broader temporal trend while reducing the influence of individual annual fluctuations.

!Temporal trend(figures/temporal_trend_rolling_average.png)


# The 2009 outbreak-reporting spike

Of the 207 records in 2009, 193 (93.2%) represented:

> Influenza due to identified zoonotic or pandemic influenza virus

This demonstrated that the marked 2009 peak was due to the influenza reporting rather than a general increase across all diseases.


# Geographic distribution

The number of outbreak records by UN region was:

| Region | Records |
| Africa | 1,210 |
| Asia | 755 |
| Americas | 736 |
| Europe | 683 |
| Oceania | 170 |
| Unclassified | 12 |

!Regional distribution(figures/outbreak_records_by_region.png)

These counts represent the distribution of reported outbreak records, rather than regional disease incidence or burden.

# Most frequently reported diseases

The most frequently represented diseases included:

| Disease | Records |
| COVID-19 | 1,214 |
| Pandemic / zoonotic influenza | 554 |
| Cholera | 245 |
| Dengue fever | 209 |
| Yellow fever | 159 |
| Acute poliomyelitis | 125 |
| Monkeypox | 108 |
| Measles | 99 |
| Meningococcal meningitis | 96 |
| Middle East respiratory syndrome | 76 |

!Most frequently reported diseases(figures/top_diseases.png)


# Country-level patterns

Up to and including 2025, countries with the largest numbers of outbreak records included:

| Country | Records |
| Democratic Republic of the Congo | 79 |
| Nigeria | 59 |
| United States of America | 51 |
| China | 49 |
| Brazil | 45 |
| France | 43 |
| United Kingdom | 41 |

Additional descriptive measures included:

- disease richness: number of distinct diseases reported within each country
- geographic reach: number of countries where each disease was reported
- temporal persistence: number of distinct years in which each disease appeared
- country-year richness: number of distinct diseases reported within a country during a given year

# 3. Disease–region association

The initial disease × region contingency table was sparse because the dataset contained 92 disease categories.

Diseases with fewer than 30 outbreak records were therefore grouped into an 'Other' category.

The resulting table contained:

- 5 geographic regions
- 19 disease groups
- 95 cells

Only 11/95 cells (11.6%) had expected counts below five and none had expected counts below one.

# Chi-square analysis

The grouped analysis demonstrated strong evidence of an association between disease and region:

χ²(72) = 1301.9, p < 0.001

A 10,000-replicate Monte Carlo sensitivity analysis produced the same conclusion.

# Effect size

Cramér's V = 0.303

indicating a moderate meaningful association between disease group and geographic region.

# Standardised residuals

Several disease–region combinations occurred more frequently than expected under independence, including:

- Middle East respiratory syndrome – Asia: +12.15
- Cholera – Africa: +11.82
- Dengue – Americas: +11.10
- Yellow fever – Africa: +10.94
- Meningococcal meningitis – Africa: +10.33
- Acute poliomyelitis – Africa: +8.92
- Zika virus disease – Americas: +8.10
- Ebola disease – Africa: +6.17

!Disease-region residual heatmap(figures/disease_region_residual_heatmap.png)

These findings should not be interpreted as evidence that geographic region causes disease occurrence.

# 4. Country-year count modelling

A complete panel was created containing every country–year combination between 1996 and 2025.

The complete panel contained:

- 7,080 country-year observations
- 236 countries and territories

65.9% of country-years had zero observed outbreak records.

For modelling, countries without a classified UN region were excluded:

- 7,020 observations
- 234 countries

The outcome: the number of distinct diseases with outbreak records in each country-year

# Model development

Models were developed sequentially.

| Model | AIC |
| Poisson GLM | 11,753 |
| Negative-binomial GLM | 11,742 |
| Mixed Poisson – linear time | 11,084 |
| Mixed Poisson – quadratic time | 10,631 |
| Mixed Poisson – spline time | 10,595 |
| Mixed COM-Poisson – spline time | 10,465 |

The simple Poisson model showed evidence of overdispersion.
Introducing a country-level random intercept substantially improved model fit, indicating important between-country heterogeneity.
Allowing the relationship with calendar year to be nonlinear produced further substantial improvement.


# Preferred model

The final model was a mixed-effects COM-Poisson regression containing:

- natural spline for calendar year
- UN region as a fixed effect
- country-specific random intercept

The COM-Poisson distribution was selected after the mixed Poisson spline model demonstrated significant underdispersion

# Poisson spline diagnostics

Dispersion ratio:

**0.785, p = 0.002**

# COM-Poisson diagnostics

Dispersion:

0.960, p = 0.718

Zero-count test:

observed/simulated ratio = 0.997, p = 0.812

Bootstrap outlier test:

13 / 7,020 observations classified as outliers, p = 0.08

The residual uniformity test remained statistically significant:

p = 0.0004


# Observed versus modelled temporal pattern

!Observed versus modelled(figures/observed_vs_modelled_compois.png)

The preferred model captured the broad nonlinear temporal pattern but did not reproduce individual annual spikes perfectly.

A smooth temporal function cannot fully reproduce abrupt events such as the 2009 influenza reporting peak or the marked year-to-year variation observed during the early 2020s.


# 5. Sensitivity analyses

Two sensitivity analyses tested whether major epidemic periods disproportionately determined the temporal results.

## Excluding COVID-19

Removing COVID-19 substantially reduced the post-2020 rise in outbreak records.

Excluding COVID-19:

| Year | Records |
| 2019 | 95 |
| 2020 | 37 |
| 2021 | 54 |
| 2022 | 189 |
| 2023 | 158 |
| 2024 | 159 |
| 2025 | 266 |

!COVID sensitivity(figures/covid_exclusion_model.png)

The COVID-excluded COM-Poisson model showed good diagnostic behaviour:

- dispersion p = 0.556
- zero-count p = 0.728
- residual uniformity p = 0.102
- bootstrap outlier p = 0.760
- convergence: successful

This suggests that the broader increase in reported outbreak activity during the 2020s was not solely attributable to COVID-19 records

This does not imply that the true incidence of outbreaks increased as it is likely there were changes in surveillance, reporting, and data availability.


# Excluding the 2009 influenza spike

A second sensitivity analysis removed only the pandemic / zoonotic influenza records occurring in 2009.

!2009 influenza sensitivity(figures/2009_influenza_exclusion_model.png)

Removing the 2009 influenza spike substantially reduced the exceptional late-2000s peak while leaving the broad post-2020 pattern intact.

Both sensitivity models converged successfully.

AIC values from these sensitivity models are not directly compared with the main model, because removing disease records changes the response dataset.


# 6. Spatial epidemiology

Country-level summaries were linked to Natural Earth geographic boundaries using ISO3 codes.

The country summary contained 236 entities

Nine source entities could not be matched directly to Natural Earth geometries:

- Bonaire, Sint Eustatius and Saba
- French Guiana
- Gibraltar
- Guadeloupe
- Kosovo
- Martinique
- Mayotte
- Réunion
- Tokelau

Following geometry matching and aggregation, 227 spatial units were included in spatial autocorrelation analysis.

# Global distribution of outbreak records

!Outbreak records map(figures/outbreak_records_map.png)

# Global disease richness

!Disease richness map(figures/disease_richness_map.png)

# Spatial autocorrelation

A global land-border neighbour structure would leave many islands without neighbours.

Spatial relationships were therefore defined using k-nearest neighbours after projection to the Equal Earth coordinate reference system.

A primary analysis using k = 4 was accompanied by a k = 6 sensitivity analysis

No spatial units had zero neighbours.

# Moran's I results

| Outcome | Neighbours | Moran's I | Permutation p |
| Outbreak records | k = 4 | 0.299 | 0.001 |
| Disease richness | k = 4 | 0.214 | 0.001 |
| Outbreak records | k = 6 | 0.275 | 0.001 |
| Disease richness | k = 6 | 0.197 | 0.001 |

Both measures demonstrated positive spatial autocorrelation and the finding was strong to the choice of neighbourhood size.

Countries geographically closer to one another therefore tended to have more similar levels of reported outbreak activity and disease richness than under random spatial arrangement.

This does not demonstrate transmission between neighbouring countries or identify a causal spatial mechanism though cannot be ruled out.

# Key findings

1. Global outbreak reporting showed strong temporal variation, including major reporting peaks associated with pandemic influenza and COVID-19.
2. The post-2020 increase in reported outbreak records persisted after COVID-19 was excluded, although it was attenuated.
3. Disease distributions differed substantially between world regions.
4. Country-specific heterogeneity and nonlinear temporal change were important features of country-year outbreak counts.
5. A mixed COM-Poisson model handled the observed count distribution more appropriately than simpler Poisson or negative-binomial specifications.
6. Reported outbreak activity and disease richness/diversity demonstrated positive global spatial autocorrelation.
7. Sensitivity analyses showed that the broad temporal conclusions were not entirely driven by either COVID-19 or the 2009 influenza reporting year.

# Limitations

Several limitations when interpreting these analyses:

# Reporting data are not incidence data

The dataset represents country–disease–year outbreak reporting rather than numbers of infected individuals.

Consequently, the analysis cannot estimate:

- incidence
- prevalence
- case-fatality risk
- individual-level disease risk
- transmission rates
- reproduction numbers

#Zero values

Zeros introduced when constructing the complete country-year panel represent:

> no outbreak record observed in the dataset

rather than confirmed absence of disease.

# Surveillance and reporting

Differences between countries and changes over time may reflect:

- surveillance capacity
- reporting practices
- diagnostic availability
- health-system infrastructure
- international reporting requirements
- changes in the underlying source data
- genuine epidemiological differences.

# Incomplete 2026 data

The source dataset contained observations from 2026, but the year was incomplete and therefore excluded from completed-year modelling and trend analyses.

# Spatial analysis

Positive spatial autocorrelation demonstrates geographic clustering in the measured reporting patterns.

It does not establish:

- cross-border transmission
- causal geographic effects
- direction of spread

# Reproducible workflow

The analysis is organised into sequential R scripts:

R/
├── 01_data_cleaning.R
├── 02_data_quality.R
├── 03_descriptive_epidemiology.R
├── 04_temporal_analysis.R
├── 05_disease_region_association.R
├── 06_count_modelling.R
├── 07_sensitivity_analyses.R
└── 08_spatial_analysis.R

# Methods and R packages

tidyverse — data manipulation and visualisation
readxl — Excel import
zoo — rolling averages
MASS — negative-binomial regression
glmmTMB — mixed-effects Poisson, negative-binomial and COM-Poisson models
DHARMa — simulation-based residual diagnostics
sf — spatial data manipulation
rnaturalearth — world geographic boundaries
spdep — neighbourhood structures and Moran's I

# Skills
This project demonstrates practical experience in:

-epidemiological data cleaning
-surveillance data interpretation
-missing-data assessment
-descriptive epidemiology
-temporal trend analysis
-contingency-table analysis
-chi-square testing
-Monte Carlo sensitivity testing
-effect-size estimation
-Poisson regression
-negative-binomial regression
-mixed-effects count modelling
-COM-Poisson regression
-nonlinear modelling using natural splines
-simulation-based model diagnostics
-sensitivity analysis
-spatial data linkage
-choropleth mapping
-spatial weights construction
-Moran's I spatial autocorrelation
-reproducible analysis in R
-Git and GitHub version control

# Author

Chandhini Suresh

Clinical researcher and medical doctor with an interest in epidemiology, infectious diseases and population health.
