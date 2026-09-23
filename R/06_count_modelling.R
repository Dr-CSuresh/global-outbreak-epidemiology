
# 6. Mixed-effects Poisson model

# Add a random intercept for country to account for repeated observations within countries across years.

poisson_mixed <- glmmTMB(
  diseases_reported ~ year_centered + region + (1 | country),
  family = poisson(link = "log"),
  data = model_data
)

summary(poisson_mixed)

AIC(poisson_mixed)


# 7. Mixed-effects negative-binomial model


nb_mixed <- glmmTMB(
  diseases_reported ~ year_centered + region + (1 | country),
  family = nbinom2(link = "log"),
  data = model_data
)

summary(nb_mixed)

AIC(nb_mixed)


# Compare mixed linear-time models
AIC(
  poisson_mixed,
  nb_mixed
)



# 8. Quadratic time trend


poisson_mixed_quadratic <- glmmTMB(
  diseases_reported ~
    year_centered +
    I(year_centered^2) +
    region +
    (1 | country),
  family = poisson(link = "log"),
  data = model_data
)

summary(poisson_mixed_quadratic)

AIC(poisson_mixed_quadratic)



# 9. Natural spline time trend


poisson_mixed_spline <- glmmTMB(
  diseases_reported ~
    splines::ns(year_centered, df = 4) +
    region +
    (1 | country),
  family = poisson(link = "log"),
  data = model_data
)

summary(poisson_mixed_spline)

AIC(poisson_mixed_spline)



# 10. Preliminary model comparison


model_comparison_preliminary <- tibble(
  model = c(
    "Poisson GLM",
    "Negative-binomial GLM",
    "Mixed Poisson - linear time",
    "Mixed negative-binomial - linear time",
    "Mixed Poisson - quadratic time",
    "Mixed Poisson - spline time"
  ),
  AIC = c(
    AIC(poisson_glm),
    AIC(nb_glm),
    AIC(poisson_mixed),
    AIC(nb_mixed),
    AIC(poisson_mixed_quadratic),
    AIC(poisson_mixed_spline)
  )
)

model_comparison_preliminary



# 11. DHARMa diagnostics for mixed Poisson spline

set.seed(123)

dharma_poisson_spline <- simulateResiduals(
  fittedModel = poisson_mixed_spline,
  n = 1000
)


# Save diagnostic plot to file instead of plotting in small RStudio pane

png(
  "figures/DHARMa_poisson_spline_diagnostics.png",
  width = 1600,
  height = 1200,
  res = 150
)

plot(dharma_poisson_spline)

dev.off()


# Formal diagnostic tests

poisson_spline_dispersion <- testDispersion(
  dharma_poisson_spline
)

poisson_spline_zero <- testZeroInflation(
  dharma_poisson_spline
)

poisson_spline_uniformity <- testUniformity(
  dharma_poisson_spline
)


poisson_spline_dispersion

poisson_spline_zero

poisson_spline_uniformity



# 12. COM-Poisson mixed-effects spline model


compois_mixed_spline <- glmmTMB(
  diseases_reported ~
    splines::ns(year_centered, df = 4) +
    region +
    (1 | country),
  family = compois(link = "log"),
  data = model_data
)

summary(compois_mixed_spline)

AIC(compois_mixed_spline)



# 13. DHARMa diagnostics for COM-Poisson model

set.seed(123)

dharma_compois <- simulateResiduals(
  fittedModel = compois_mixed_spline,
  n = 1000
)


# Save diagnostic plot to file

png(
  "figures/DHARMa_compois_diagnostics.png",
  width = 1600,
  height = 1200,
  res = 150
)

plot(dharma_compois)

dev.off()


# Formal diagnostic tests

compois_dispersion <- testDispersion(
  dharma_compois
)

compois_zero <- testZeroInflation(
  dharma_compois
)

compois_uniformity <- testUniformity(
  dharma_compois
)

compois_outliers <- testOutliers(
  dharma_compois,
  type = "bootstrap"
)


compois_dispersion

compois_zero

compois_uniformity

compois_outliers



# 14. Final model comparison

model_comparison <- tibble(
  model = c(
    "Poisson GLM",
    "Negative-binomial GLM",
    "Mixed Poisson - linear time",
    "Mixed Poisson - quadratic time",
    "Mixed Poisson - spline time",
    "Mixed COM-Poisson - spline time"
  ),
  AIC = c(
    AIC(poisson_glm),
    AIC(nb_glm),
    AIC(poisson_mixed),
    AIC(poisson_mixed_quadratic),
    AIC(poisson_mixed_spline),
    AIC(compois_mixed_spline)
  )
) %>%
  arrange(AIC)

model_comparison


# Save model-comparison table

write_csv(
  model_comparison,
  "results/tables/model_comparison.csv"
)



# 15. Convergence checks


convergence_checks <- tibble(
  model = c(
    "Mixed Poisson - linear time",
    "Mixed negative-binomial - linear time",
    "Mixed Poisson - quadratic time",
    "Mixed Poisson - spline time",
    "Mixed COM-Poisson - spline time"
  ),
  pdHess = c(
    poisson_mixed$sdr$pdHess,
    nb_mixed$sdr$pdHess,
    poisson_mixed_quadratic$sdr$pdHess,
    poisson_mixed_spline$sdr$pdHess,
    compois_mixed_spline$sdr$pdHess
  )
)

convergence_checks


write_csv(
  convergence_checks,
  "results/tables/model_convergence_checks.csv"
)


# 16. Observed versus modelled temporal pattern


# Obtain fitted values from the preferred COM-Poisson model
model_data <- model_data %>%
  mutate(
    fitted_compois = predict(
      compois_mixed_spline,
      type = "response"
    )
  )


# Sum observed and fitted country-year counts within each year
observed_fitted_year <- model_data %>%
  group_by(year) %>%
  summarise(
    observed = sum(diseases_reported),
    fitted = sum(fitted_compois),
    .groups = "drop"
  )


observed_fitted_year


# Convert to long format for plotting
observed_fitted_long <- observed_fitted_year %>%
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


# Plot observed versus modelled trend
observed_fitted_plot <- ggplot(
  observed_fitted_long,
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
    data = observed_fitted_long %>%
      filter(series == "Observed"),
    size = 1.5
  ) +
  labs(
    title = "Observed and modelled outbreak reporting over time",
    subtitle = "Preferred mixed COM-Poisson model with nonlinear time trend",
    x = "Year",
    y = "Country-disease-year records",
    linetype = NULL,
    caption = "Model includes UN region, a natural spline for year, and a country-level random intercept."
  ) +
  theme_minimal()


observed_fitted_plot


# Save figure
ggsave(
  "figures/observed_vs_modelled_compois.png",
  observed_fitted_plot,
  width = 9,
  height = 6,
  dpi = 300
)


# Save underlying values
write_csv(
  observed_fitted_year,
  "results/tables/observed_vs_modelled_compois.csv"
)