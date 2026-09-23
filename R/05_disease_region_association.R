# ============================================================
# Global Outbreak Epidemiology
# 05_disease_region_association.R
#
# Purpose:
# Test whether the distribution of reported diseases differs
# across UN geographic regions.
#
# Rare diseases are grouped into "Other" to reduce sparsity
# in the contingency table.
# ============================================================


library(tidyverse)


# Load cleaned data 

outbreak <- read_rds("data/processed/outbreak_clean.rds")


# Remove records without a UN region 

association_data <- outbreak %>%
  filter(!is.na(unsd_region))



# 1. Initial disease x region table


raw_table <- table(
  association_data$unsd_region,
  association_data$disease
)

dim(raw_table)


# Initial chi-square test 

raw_chisq <- chisq.test(raw_table)

raw_chisq


# Check expected cell counts 

sum(raw_chisq$expected < 5)

sum(raw_chisq$expected < 1)

length(raw_chisq$expected)


# 2. Group less frequently reported diseases


disease_counts <- association_data %>%
  count(
    disease,
    sort = TRUE
  )


# Retain diseases with at least 30 outbreak records 

common_diseases <- disease_counts %>%
  filter(n >= 30) %>%
  pull(disease)


length(common_diseases)

common_diseases


# Group remaining diseases into "Other" 

association_grouped <- association_data %>%
  mutate(
    disease_group = if_else(
      disease %in% common_diseases,
      disease,
      "Other"
    )
  )


# Create grouped contingency table 

grouped_table <- table(
  association_grouped$unsd_region,
  association_grouped$disease_group
)

dim(grouped_table)

grouped_table


# 3. Chi-square test on grouped table


grouped_chisq <- chisq.test(grouped_table)

grouped_chisq

# Expected cell counts 

expected_below_5 <- sum(
  grouped_chisq$expected < 5
)

expected_below_1 <- sum(
  grouped_chisq$expected < 1
)

total_cells <- length(
  grouped_chisq$expected
)

expected_below_5
expected_below_1
total_cells


# 4. Cramer's V

chi_square_value <- unname(
  grouped_chisq$statistic
)

n_total <- sum(grouped_table)

n_rows <- nrow(grouped_table)

n_cols <- ncol(grouped_table)


cramers_v <- sqrt(
  chi_square_value /
    (
      n_total *
        min(
          n_rows - 1,
          n_cols - 1
        )
    )
)

cramers_v


# 5. Standardized residuals

standardised_residuals <- as.data.frame(
  as.table(grouped_chisq$stdres)
) %>%
  rename(
    region = Var1,
    disease_group = Var2,
    standardised_residual = Freq
  )

standardised_residuals

largest_residuals <- standardised_residuals %>%
  mutate(
    absolute_residual = abs(standardised_residual)
  ) %>%
  arrange(
    desc(absolute_residual)
  )

largest_residuals %>%
  slice_head(n = 20)

write_csv(
  largest_residuals,
  "results/tables/disease_region_standardised_residuals.csv"
)


# 6. Standardised residual heatmap


residual_heatmap <- ggplot(
  standardised_residuals,
  aes(
    x = disease_group,
    y = region,
    fill = standardised_residual
  )
) +
  geom_tile() +
  scale_fill_gradient2(
    midpoint = 0
  ) +
  labs(
    title = "Disease-region association",
    subtitle = "Standardised residuals from grouped chi-square analysis",
    x = "Disease",
    y = "UN region",
    fill = "Standardised\nresidual",
    caption = "Positive values indicate more outbreak records than expected under independence; negative values indicate fewer."
  ) +
  theme_minimal() +
  theme(
    axis.text.x = element_text(
      angle = 45,
      hjust = 1
    )
  )

residual_heatmap

ggsave(
  "figures/disease_region_residual_heatmap.png",
  residual_heatmap,
  width = 14,
  height = 7,
  dpi = 300
)

association_results <- tibble(
  statistic = c(
    "Chi-square",
    "Degrees of freedom",
    "Asymptotic p value",
    "Monte Carlo p value",
    "Cramer's V",
    "Cells with expected count <5",
    "Cells with expected count <1",
    "Total cells"
  ),
  value = c(
    chi_square_value,
    unname(grouped_chisq$parameter),
    grouped_chisq$p.value,
    grouped_chisq_monte_carlo$p.value,
    cramers_v,
    expected_below_5,
    expected_below_1,
    total_cells
  )
)

association_results

write_csv(
  association_results,
  "results/tables/disease_region_association_results.csv"
)

write_csv(
  association_results,
  "results/tables/disease_region_association_results.csv"
)

set.seed(123)

grouped_chisq_monte_carlo <- chisq.test(
  grouped_table,
  simulate.p.value = TRUE,
  B = 10000
)

grouped_chisq_monte_carlo