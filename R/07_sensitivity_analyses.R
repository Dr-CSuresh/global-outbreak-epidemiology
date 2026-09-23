# Global Outbreak Epidemiology
# 07_sensitivity_analyses.R
#
# Purpose:
# Test the robustness of the preferred mixed COM-Poisson
# spline model by:
#
# 1. Excluding COVID-19 records
# 2. Excluding pandemic/zoonotic influenza records in 2009
#
# Completed calendar years only: 1996-2025.



library(tidyverse)
library(glmmTMB)
library(DHARMa)


# Load cleaned data 

outbreak <- read_rds(
  "data/processed/outbreak_clean.rds"
)



# Create country-region lookup


country_region <- outbreak %>%
  group_by(country) %>%
  summarise(
    region = if (
      all(is.na(unsd_region))
    ) {
      NA_character_
    } else {
      first(
        unsd_region[!is.na(unsd_region)]
      )
    },
    .groups = "drop"
  ) %>%
  mutate(
    region = replace_na(
      region,
      "Unclassified"
    )
  )



# COVID-19 EXCLUSION




# 1. Remove COVID-19


outbreak_no_covid <- outbreak %>%
  filter(
    year <= 2025,
    disease != "COVID-19"
  )



# 2. Count diseases within observed country-years


country_year_no_covid_counts <- outbreak_no_covid %>%
  group_by(
    country,
    year
  ) %>%
  summarise(
    diseases_reported = n_distinct(disease),
    .groups = "drop"
  )



# 3. Rebuild complete country-year panel


panel_no_covid <- expand_grid(
  country = sort(
    unique(outbreak$country)
  ),
  year = 1996:2025
) %>%
  left_join(
    country_year_no_covid_counts,
    by = c(
      "country",
      "year"
    )
  ) %>%
  mutate(
    diseases_reported = replace_na(
      diseases_reported,
      0L
    )
  ) %>%
  left_join(
    country_region,
    by = "country"
  )


dim(panel_no_covid)



# 4. Prepare modelling dataset


model_no_covid <- panel_no_covid %>%
  filter(
    region != "Unclassified"
  ) %>%
  mutate(
    region = factor(
      region,
      levels = c(
        "Africa",
        "Americas",
        "Asia",
        "Europe",
        "Oceania"
      )
    ),
    year_centered = year - 1996
  )


dim(model_no_covid)

n_distinct(model_no_covid$country)



# 5. Fit preferred COM-Poisson spline model


compois_no_covid <- glmmTMB(
  diseases_reported ~
    splines::ns(
      year_centered,
      df = 4
    ) +
    region +
    (1 | country),
  family = compois(
    link = "log"
  ),
  data = model_no_covid
)


summary(compois_no_covid)

AIC(compois_no_covid)

compois_no_covid$sdr$pdHess



# 6. DHARMa diagnostics


set.seed(123)

dharma_no_covid <- simulateResiduals(
  fittedModel = compois_no_covid,
  n = 1000
)


no_covid_dispersion <- testDispersion(
  dharma_no_covid
)

no_covid_zero <- testZeroInflation(
  dharma_no_covid
)

no_covid_uniformity <- testUniformity(
  dharma_no_covid
)

no_covid_outliers <- testOutliers(
  dharma_no_covid,
  type = "bootstrap"
)


no_covid_dispersion

no_covid_zero

no_covid_uniformity

no_covid_outliers



# 7. Observed vs fitted trend


model_no_covid <- model_no_covid %>%
  mutate(
    fitted = predict(
      compois_no_covid,
      type = "response"
    )
  )


no_covid_yearly <- model_no_covid %>%
  group_by(year) %>%
  summarise(
    observed = sum(
      diseases_reported
    ),
    fitted = sum(
      fitted
    ),
    .groups = "drop"
  )


no_covid_long <- no_covid_yearly %>%
  pivot_longer(
    cols = c(
      observed,
      fitted
    ),
    names_to = "series",
    values_to = "outbreak_records"
  ) %>%
  mutate(
    series = recode(
      series,
      observed = "Observed",
      fitted = "COM-Poisson fitted"
    )
  )


covid_sensitivity_plot <- ggplot(
  no_covid_long,
  aes(
    x = year,
    y = outbreak_records,
    linetype = series
  )
) +
  geom_line(
    linewidth = 1
  ) +
  geom_point(
    data = no_covid_long %>%
      filter(
        series == "Observed"
      ),
    size = 1.5
  ) +
  labs(
    title = "Temporal outbreak reporting after excluding COVID-19",
    subtitle = "Mixed COM-Poisson model with nonlinear time trend",
    x = "Year",
    y = "Country-disease-year records",
    linetype = NULL,
    caption = "COVID-19 records removed before reconstructing the country-year panel."
  ) +
  theme_minimal()


covid_sensitivity_plot


ggsave(
  "figures/covid_exclusion_model.png",
  covid_sensitivity_plot,
  width = 9,
  height = 6,
  dpi = 300
)


write_csv(
  no_covid_yearly,
  "results/tables/covid_exclusion_observed_fitted.csv"
)



# 2009 PANDEMIC INFLUENZA EXCLUSION




# 8. Remove only 2009 pandemic / zoonotic influenza records


outbreak_no_2009_flu <- outbreak %>%
  filter(
    year <= 2025
  ) %>%
  filter(
    !(
      year == 2009 &
        disease ==
        "Influenza due to identified zoonotic or pandemic influenza virus"
    )
  )



# 9. Count diseases within observed country-years


country_year_no_2009_flu_counts <- outbreak_no_2009_flu %>%
  group_by(
    country,
    year
  ) %>%
  summarise(
    diseases_reported = n_distinct(disease),
    .groups = "drop"
  )



# 10. Rebuild complete country-year panel


panel_no_2009_flu <- expand_grid(
  country = sort(
    unique(outbreak$country)
  ),
  year = 1996:2025
) %>%
  left_join(
    country_year_no_2009_flu_counts,
    by = c(
      "country",
      "year"
    )
  ) %>%
  mutate(
    diseases_reported = replace_na(
      diseases_reported,
      0L
    )
  ) %>%
  left_join(
    country_region,
    by = "country"
  )



# 11. Prepare modelling dataset


model_no_2009_flu <- panel_no_2009_flu %>%
  filter(
    region != "Unclassified"
  ) %>%
  mutate(
    region = factor(
      region,
      levels = c(
        "Africa",
        "Americas",
        "Asia",
        "Europe",
        "Oceania"
      )
    ),
    year_centered = year - 1996
  )


dim(model_no_2009_flu)

n_distinct(
  model_no_2009_flu$country
)



# 12. Fit preferred COM-Poisson spline model


compois_no_2009_flu <- glmmTMB(
  diseases_reported ~
    splines::ns(
      year_centered,
      df = 4
    ) +
    region +
    (1 | country),
  family = compois(
    link = "log"
  ),
  data = model_no_2009_flu
)


summary(compois_no_2009_flu)

AIC(compois_no_2009_flu)

compois_no_2009_flu$sdr$pdHess



# 13. DHARMa diagnostics


set.seed(123)

dharma_no_2009_flu <- simulateResiduals(
  fittedModel = compois_no_2009_flu,
  n = 1000
)


no_2009_flu_dispersion <- testDispersion(
  dharma_no_2009_flu
)

no_2009_flu_zero <- testZeroInflation(
  dharma_no_2009_flu
)

no_2009_flu_uniformity <- testUniformity(
  dharma_no_2009_flu
)

no_2009_flu_outliers <- testOutliers(
  dharma_no_2009_flu,
  type = "bootstrap"
)


no_2009_flu_dispersion

no_2009_flu_zero

no_2009_flu_uniformity

no_2009_flu_outliers



# 14. Observed vs fitted trend


model_no_2009_flu <- model_no_2009_flu %>%
  mutate(
    fitted = predict(
      compois_no_2009_flu,
      type = "response"
    )
  )


no_2009_flu_yearly <- model_no_2009_flu %>%
  group_by(year) %>%
  summarise(
    observed = sum(
      diseases_reported
    ),
    fitted = sum(
      fitted
    ),
    .groups = "drop"
  )


no_2009_flu_long <- no_2009_flu_yearly %>%
  pivot_longer(
    cols = c(
      observed,
      fitted
    ),
    names_to = "series",
    values_to = "outbreak_records"
  ) %>%
  mutate(
    series = recode(
      series,
      observed = "Observed",
      fitted = "COM-Poisson fitted"
    )
  )


influenza_sensitivity_plot <- ggplot(
  no_2009_flu_long,
  aes(
    x = year,
    y = outbreak_records,
    linetype = series
  )
) +
  geom_line(
    linewidth = 1
  ) +
  geom_point(
    data = no_2009_flu_long %>%
      filter(
        series == "Observed"
      ),
    size = 1.5
  ) +
  labs(
    title = "Temporal outbreak reporting after excluding the 2009 influenza spike",
    subtitle = "Mixed COM-Poisson model with nonlinear time trend",
    x = "Year",
    y = "Country-disease-year records",
    linetype = NULL,
    caption = "Only 2009 pandemic/zoonotic influenza records were removed."
  ) +
  theme_minimal()


influenza_sensitivity_plot


ggsave(
  "figures/2009_influenza_exclusion_model.png",
  influenza_sensitivity_plot,
  width = 9,
  height = 6,
  dpi = 300
)


write_csv(
  no_2009_flu_yearly,
  "results/tables/2009_influenza_exclusion_observed_fitted.csv"
)



# SUMMARY TABLE



# Extract country random-intercept standard deviations

random_sd_no_covid <- attr(
  VarCorr(
    compois_no_covid
  )$cond$country,
  "stddev"
)[1]


random_sd_no_2009_flu <- attr(
  VarCorr(
    compois_no_2009_flu
  )$cond$country,
  "stddev"
)[1]


# Extract COM-Poisson dispersion parameters

dispersion_parameter_no_covid <- sigma(
  compois_no_covid
)

dispersion_parameter_no_2009_flu <- sigma(
  compois_no_2009_flu
)


sensitivity_model_summary <- tibble(
  analysis = c(
    "COVID-19 excluded",
    "2009 pandemic influenza excluded"
  ),
  AIC = c(
    AIC(compois_no_covid),
    AIC(compois_no_2009_flu)
  ),
  country_random_SD = c(
    random_sd_no_covid,
    random_sd_no_2009_flu
  ),
  COM_Poisson_dispersion = c(
    dispersion_parameter_no_covid,
    dispersion_parameter_no_2009_flu
  ),
  converged = c(
    compois_no_covid$sdr$pdHess,
    compois_no_2009_flu$sdr$pdHess
  )
)


sensitivity_model_summary


write_csv(
  sensitivity_model_summary,
  "results/tables/sensitivity_model_summary.csv"
)