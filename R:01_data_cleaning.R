# ============================================================
# Global Outbreak Epidemiology
# 01_data_cleaning.R
#
# Purpose:
# Import and clean the global outbreak surveillance dataset.
# ============================================================

library(tidyverse)
library(readxl)

# Import raw data
outbreak_raw <- read_excel("data/raw/outbreak.xlsx")

# Check dimensions
dim(outbreak_raw)

# Rename variables
outbreak <- outbreak_raw %>%
  rename(
    outbreak_id        = `#Year+iso3+icd4`,
    year               = `#date+year`,
    disease_icd        = `#disease+name+icd`,
    disease_icd3       = `#disease+name+icd3`,
    disease_icd4       = `#disease+name+icd4`,
    icd_code           = `#disease+code+icd`,
    icd3_code          = `#disease+code+icd3`,
    icd4_code          = `#disease+code+icd4`,
    disease            = `#disease+name`,
    disease_definition = `#x_disease+definition`,
    country            = `#country+name`,
    iso2               = `#country+code+iso2`,
    iso3               = `#country+code+iso3`,
    unsd_region        = `#region+unsd`,
    unsd_subregion     = `#subregion+unsd`,
    who_region         = `#region+who`,
    news_id            = `#news+id`
  ) %>%
  mutate(
    year = as.integer(year)
  )

# Check cleaned data
dim(outbreak)
names(outbreak)
range(outbreak$year, na.rm = TRUE)
glimpse(outbreak)

# Save cleaned dataset
write_rds(
  outbreak,
  "data/processed/outbreak_clean.rds"
)
