# ============================================================
# Global Outbreak Epidemiology
# 04_temporal_analysis.R
#
# Purpose:
# Examine temporal patterns in outbreak reporting from
# 1996-2025, including smoothing and COVID-19 exclusion.
# ============================================================


library(tidyverse)
library(zoo)


# Load cleaned data 

outbreak <- read_rds("data/processed/outbreak_clean.rds")

# Completed calendar years only
outbreak_complete <- outbreak %>%
  filter(year <= 2025)


# Annual outbreak records 

annual_counts <- outbreak_complete %>%
  count(
    year,
    name = "outbreak_records"
  ) %>%
  complete(
    year = 1996:2025,
    fill = list(outbreak_records = 0)
  )


# 3-year centred rolling average 

annual_counts <- annual_counts %>%
  mutate(
    rolling_mean_3yr = zoo::rollmean(
      outbreak_records,
      k = 3,
      fill = NA,
      align = "center"
    )
  )

annual_counts


# Plot annual counts with rolling average 

temporal_plot <- ggplot(
  annual_counts,
  aes(
    x = year,
    y = outbreak_records
  )
) +
  geom_line() +
  geom_point() +
  geom_line(
    aes(y = rolling_mean_3yr),
    linewidth = 1
  ) +
  labs(
    title = "Temporal trend in reported outbreak records, 1996-2025",
    subtitle = "Annual records with 3-year centred rolling average",
    x = "Year",
    y = "Number of outbreak records",
    caption = "2026 excluded because the calendar year is incomplete."
  ) +
  theme_minimal()

temporal_plot

ggsave(
  "figures/temporal_trend_rolling_average.png",
  temporal_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# Save temporal data 

write_csv(
  annual_counts,
  "results/tables/annual_temporal_trend.csv"
)


# COVID-19 excluded 

annual_counts_no_covid <- outbreak_complete %>%
  filter(
    disease != "COVID-19"
  ) %>%
  count(
    year,
    name = "outbreak_records"
  ) %>%
  complete(
    year = 1996:2025,
    fill = list(outbreak_records = 0)
  )

annual_counts_no_covid


# Combine full and COVID-excluded series 

temporal_comparison <- annual_counts %>%
  dplyr::select(
    year,
    all_records = outbreak_records
  ) %>%
  left_join(
    annual_counts_no_covid %>%
      rename(
        excluding_covid = outbreak_records
      ),
    by = "year"
  )

temporal_comparison


# Convert to long format for plotting 

temporal_comparison_long <- temporal_comparison %>%
  pivot_longer(
    cols = c(
      all_records,
      excluding_covid
    ),
    names_to = "series",
    values_to = "outbreak_records"
  ) %>%
  mutate(
    series = recode(
      series,
      all_records = "All outbreak records",
      excluding_covid = "Excluding COVID-19"
    )
  )


# Plot COVID sensitivity 

covid_temporal_plot <- ggplot(
  temporal_comparison_long,
  aes(
    x = year,
    y = outbreak_records,
    linetype = series
  )
) +
  geom_line(
    linewidth = 1
  ) +
  labs(
    title = "Temporal trend in outbreak reporting with and without COVID-19",
    subtitle = "Completed calendar years, 1996-2025",
    x = "Year",
    y = "Number of outbreak records",
    linetype = NULL,
    caption = "COVID-19 exclusion assesses the contribution of pandemic reporting to the post-2020 increase."
  ) +
  theme_minimal()

covid_temporal_plot

ggsave(
  "figures/temporal_trend_covid_sensitivity.png",
  covid_temporal_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# Save comparison table 

write_csv(
  temporal_comparison,
  "results/tables/temporal_covid_comparison.csv"
)


# Investigate the 2009 spike 

influenza_2009 <- outbreak_complete %>%
  filter(
    year == 2009,
    disease == "Influenza due to identified zoonotic or pandemic influenza virus"
  ) %>%
  summarise(
    influenza_records = n()
  )

influenza_2009


total_2009 <- outbreak_complete %>%
  filter(year == 2009) %>%
  summarise(
    total_records = n()
  )

total_2009


# Percentage of 2009 records due to pandemic/zoonotic influenza 

influenza_2009_percent <- (
  influenza_2009$influenza_records /
    total_2009$total_records
) * 100

influenza_2009_percent