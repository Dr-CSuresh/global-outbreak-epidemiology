# ============================================================
# Global Outbreak Epidemiology
# 02_data_quality.R
#
# Purpose:
# Assess missing data, duplicates, and basic data validity.
# ============================================================


library(tidyverse)


# Load cleaned dataset ----------------------------------------------------

outbreak <- read_rds("data/processed/outbreak_clean.rds")


# Dataset dimensions ------------------------------------------------------

dim(outbreak)


# Missing data ------------------------------------------------------------

missingness <- outbreak %>%
  summarise(
    across(
      everything(),
      ~ sum(is.na(.))
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "missing_n"
  ) %>%
  mutate(
    missing_percent = round(
      missing_n / nrow(outbreak) * 100,
      2
    )
  ) %>%
  arrange(desc(missing_n))

missingness

write_csv(
  missingness,
  "results/tables/missingness.csv"
)


# Countries with missing WHO region --------------------------------------

missing_who_region <- outbreak %>%
  filter(is.na(who_region)) %>%
  count(
    country,
    sort = TRUE
  )

missing_who_region

write_csv(
  missing_who_region,
  "results/tables/missing_who_region_by_country.csv"
)


# Records missing both UN and WHO region ---------------------------------

missing_geography <- outbreak %>%
  filter(
    is.na(unsd_region),
    is.na(who_region)
  ) %>%
  count(
    country,
    sort = TRUE
  )

missing_geography


# Full-row duplicates -----------------------------------------------------

duplicate_rows <- sum(
  duplicated(outbreak)
)

duplicate_rows


# Duplicate outbreak IDs -------------------------------------------------

duplicate_outbreak_ids <- outbreak %>%
  count(outbreak_id) %>%
  filter(n > 1)

duplicate_outbreak_ids


# Duplicate country-year-disease combinations ----------------------------

duplicate_country_year_disease <- outbreak %>%
  count(
    country,
    year,
    disease
  ) %>%
  filter(n > 1)

duplicate_country_year_disease


# Check year range --------------------------------------------------------

range(
  outbreak$year,
  na.rm = TRUE
)


# Check number of unique countries and diseases --------------------------

n_distinct(outbreak$country)

n_distinct(outbreak$disease)
