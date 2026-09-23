# ============================================================
# Global Outbreak Epidemiology
# 03_descriptive_epidemiology.R
#
# Purpose:
# Describe the temporal, geographic, and disease distribution
# of outbreak reporting.
#
# Note:
# 2026 is incomplete, so completed-year trend analyses use
# 1996-2025.
# ============================================================


library(tidyverse)


# Load cleaned data -------------------------------------------------------

outbreak <- read_rds("data/processed/outbreak_clean.rds")

# Completed calendar years only
outbreak_complete <- outbreak %>%
  filter(year <= 2025)


# Overall dataset summary -------------------------------------------------

dataset_summary <- tibble(
  measure = c(
    "Total outbreak records",
    "Countries/territories",
    "Diseases",
    "First year",
    "Latest year"
  ),
  value = c(
    nrow(outbreak),
    n_distinct(outbreak$country),
    n_distinct(outbreak$disease),
    min(outbreak$year),
    max(outbreak$year)
  )
)

dataset_summary

write_csv(
  dataset_summary,
  "results/tables/dataset_summary.csv"
)


# Annual outbreak records -------------------------------------------------

annual_counts <- outbreak_complete %>%
  count(year, name = "outbreak_records")

annual_counts

write_csv(
  annual_counts,
  "results/tables/annual_outbreak_records.csv"
)


# Plot annual outbreak records -------------------------------------------

annual_plot <- ggplot(
  annual_counts,
  aes(
    x = year,
    y = outbreak_records
  )
) +
  geom_line() +
  geom_point() +
  labs(
    title = "Annual outbreak records, 1996-2025",
    subtitle = "Country-disease-year outbreak records",
    x = "Year",
    y = "Number of outbreak records",
    caption = "2026 excluded because the calendar year is incomplete."
  ) +
  theme_minimal()

annual_plot

ggsave(
  "figures/annual_outbreak_records.png",
  annual_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# Regional distribution --------------------------------------------------

regional_counts <- outbreak %>%
  count(
    unsd_region,
    sort = TRUE,
    name = "outbreak_records"
  )

regional_counts

write_csv(
  regional_counts,
  "results/tables/outbreak_records_by_region.csv"
)


regional_plot <- ggplot(
  regional_counts,
  aes(
    x = reorder(unsd_region, outbreak_records),
    y = outbreak_records
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Reported outbreak records by UN region",
    x = "UN region",
    y = "Number of outbreak records"
  ) +
  theme_minimal()

regional_plot

ggsave(
  "figures/outbreak_records_by_region.png",
  regional_plot,
  width = 8,
  height = 6,
  dpi = 300
)


# Most frequently reported diseases --------------------------------------

top_diseases <- outbreak %>%
  count(
    disease,
    sort = TRUE,
    name = "outbreak_records"
  ) %>%
  slice_head(n = 15)

top_diseases

write_csv(
  top_diseases,
  "results/tables/top_diseases.csv"
)


top_diseases_plot <- ggplot(
  top_diseases,
  aes(
    x = reorder(disease, outbreak_records),
    y = outbreak_records
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most frequently reported diseases",
    x = "Disease",
    y = "Number of outbreak records"
  ) +
  theme_minimal()

top_diseases_plot

ggsave(
  "figures/top_diseases.png",
  top_diseases_plot,
  width = 10,
  height = 7,
  dpi = 300
)


# Countries with most outbreak records -----------------------------------

top_countries <- outbreak_complete %>%
  count(
    country,
    sort = TRUE,
    name = "outbreak_records"
  ) %>%
  slice_head(n = 15)

top_countries

write_csv(
  top_countries,
  "results/tables/top_countries.csv"
)


# Disease richness by country --------------------------------------------

country_disease_richness <- outbreak_complete %>%
  group_by(country) %>%
  summarise(
    unique_diseases = n_distinct(disease),
    .groups = "drop"
  ) %>%
  arrange(desc(unique_diseases))

country_disease_richness

write_csv(
  country_disease_richness,
  "results/tables/country_disease_richness.csv"
)


# Geographic reach of each disease ---------------------------------------

disease_geographic_reach <- outbreak_complete %>%
  group_by(disease) %>%
  summarise(
    countries_reported = n_distinct(country),
    .groups = "drop"
  ) %>%
  arrange(desc(countries_reported))

disease_geographic_reach

write_csv(
  disease_geographic_reach,
  "results/tables/disease_geographic_reach.csv"
)


# Temporal persistence of each disease -----------------------------------

disease_persistence <- outbreak_complete %>%
  group_by(disease) %>%
  summarise(
    years_reported = n_distinct(year),
    .groups = "drop"
  ) %>%
  arrange(desc(years_reported))

disease_persistence

write_csv(
  disease_persistence,
  "results/tables/disease_persistence.csv"
)


# Disease richness within each country-year -------------------------------

country_year_richness <- outbreak_complete %>%
  group_by(
    country,
    year
  ) %>%
  summarise(
    diseases_reported = n_distinct(disease),
    .groups = "drop"
  ) %>%
  arrange(desc(diseases_reported))

country_year_richness

write_csv(
  country_year_richness,
  "results/tables/country_year_disease_richness.csv"
)


# Investigate the 2009 peak ----------------------------------------------

outbreak_2009 <- outbreak %>%
  filter(year == 2009) %>%
  count(
    disease,
    sort = TRUE,
    name = "outbreak_records"
  )

outbreak_2009

write_csv(
  outbreak_2009,
  "results/tables/2009_disease_breakdown.csv"
)
