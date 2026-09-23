# Global Outbreak Epidemiology
# 08_spatial_analysis.R
#
# Purpose:
# Describe the spatial distribution of outbreak reporting and
# assess global spatial autocorrelation using Moran's I.
#
# Completed calendar years only: 1996-2025.



library(tidyverse)
library(sf)
library(rnaturalearth)
library(spdep)


# Load cleaned data

outbreak <- read_rds(
  "data/processed/outbreak_clean.rds"
)

outbreak_complete <- outbreak %>%
  filter(year <= 2025)


# PART 1: COUNTRY-LEVEL SPATIAL SUMMARY


country_spatial_summary <- outbreak_complete %>%
  group_by(
    country,
    iso3
  ) %>%
  summarise(
    outbreak_records = n(),
    unique_diseases = n_distinct(disease),
    years_reporting = n_distinct(year),
    .groups = "drop"
  )


country_spatial_summary


# Overall summary

country_spatial_stats <- country_spatial_summary %>%
  summarise(
    countries = n(),
    min_records = min(outbreak_records),
    median_records = median(outbreak_records),
    max_records = max(outbreak_records),
    min_diseases = min(unique_diseases),
    median_diseases = median(unique_diseases),
    max_diseases = max(unique_diseases)
  )

country_spatial_stats


# Countries with most outbreak records

country_spatial_summary %>%
  arrange(desc(outbreak_records)) %>%
  slice_head(n = 15)


write_csv(
  country_spatial_summary,
  "results/tables/country_spatial_summary.csv"
)



# PART 2: JOIN TO WORLD MAP



world <- rnaturalearth::ne_countries(
  scale = "medium",
  returnclass = "sf"
)


# Join outbreak statistics using ISO3 code
world_outbreak <- world %>%
  left_join(
    country_spatial_summary,
    by = c(
      "iso_a3_eh" = "iso3"
    )
  )


# Number of map polygons with outbreak data

sum(
  !is.na(world_outbreak$outbreak_records)
)


# Identify outbreak dataset entities that did not match Natural Earth 

unmatched_entities <- country_spatial_summary %>%
  anti_join(
    world %>%
      st_drop_geometry() %>%
      distinct(iso_a3_eh),
    by = c(
      "iso3" = "iso_a3_eh"
    )
  )


unmatched_entities


write_csv(
  unmatched_entities,
  "results/tables/unmatched_spatial_entities.csv"
)



# PART 3: CHOROPLETH MAPS

# Reported outbreak records

outbreak_map <- ggplot(
  world_outbreak
) +
  geom_sf(
    aes(
      fill = outbreak_records
    ),
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    na.value = "grey90"
  ) +
  labs(
    title = "Reported outbreak records by country, 1996-2025",
    fill = "Outbreak\nrecords",
    caption = "Grey indicates no matched outbreak record in the mapped dataset."
  ) +
  theme_minimal()


outbreak_map


ggsave(
  "figures/outbreak_records_map.png",
  outbreak_map,
  width = 12,
  height = 7,
  dpi = 300
)


# Disease richness 

richness_map <- ggplot(
  world_outbreak
) +
  geom_sf(
    aes(
      fill = unique_diseases
    ),
    linewidth = 0.1
  ) +
  scale_fill_viridis_c(
    na.value = "grey90"
  ) +
  labs(
    title = "Reported disease richness by country, 1996-2025",
    fill = "Unique\ndiseases",
    caption = "Disease richness is the number of distinct diseases with at least one outbreak record."
  ) +
  theme_minimal()


richness_map


ggsave(
  "figures/disease_richness_map.png",
  richness_map,
  width = 12,
  height = 7,
  dpi = 300
)



# PART 4: PREPARE DATA FOR SPATIAL AUTOCORRELATION

# Keep only mapped countries with outbreak data
# Some Natural Earth ISO codes have multiple polygons, so collapse geometries to one observation per ISO3 code before Moran's I.

spatial_analysis <- world_outbreak %>%
  filter(
    !is.na(outbreak_records),
    !is.na(iso_a3_eh)
  ) %>%
  group_by(
    iso_a3_eh
  ) %>%
  summarise(
    outbreak_records = first(outbreak_records),
    unique_diseases = first(unique_diseases),
    geometry = st_union(geometry),
    .groups = "drop"
  )


nrow(spatial_analysis)

sum(
  duplicated(spatial_analysis$iso_a3_eh)
)



# PART 5: K-NEAREST-NEIGHBOUR SPATIAL WEIGHTS
# Queen contiguity is problematic globally because many islands have no land-border neighbours. We therefore use geographic proximity based on k-nearest neighbours.


# Project to Equal Earth projection before calculating proximity
spatial_projected <- spatial_analysis %>%
  st_transform(
    8857
  )


# Create one representative point for each country geometry
spatial_points <- st_point_on_surface(
  spatial_projected
)


coords <- st_coordinates(
  spatial_points
)



# k = 4 nearest neighbours


knn4 <- knearneigh(
  coords,
  k = 4
)

nb4 <- knn2nb(
  knn4,
  sym = TRUE
)


# Examine number of neighbours
table(
  card(nb4)
)


# Check for isolates
sum(
  card(nb4) == 0
)


# Row-standardised spatial weights
listw4 <- nb2listw(
  nb4,
  style = "W",
  zero.policy = TRUE
)



# PART 6: MORAN'S I — k = 4



set.seed(123)

moran_records_k4 <- moran.mc(
  spatial_analysis$outbreak_records,
  listw = listw4,
  nsim = 999,
  zero.policy = TRUE
)


set.seed(123)

moran_richness_k4 <- moran.mc(
  spatial_analysis$unique_diseases,
  listw = listw4,
  nsim = 999,
  zero.policy = TRUE
)


moran_records_k4

moran_richness_k4



# PART 7: k = 6 SENSITIVITY ANALYSIS



knn6 <- knearneigh(
  coords,
  k = 6
)

nb6 <- knn2nb(
  knn6,
  sym = TRUE
)


table(
  card(nb6)
)

sum(
  card(nb6) == 0
)


listw6 <- nb2listw(
  nb6,
  style = "W",
  zero.policy = TRUE
)


set.seed(123)

moran_records_k6 <- moran.mc(
  spatial_analysis$outbreak_records,
  listw = listw6,
  nsim = 999,
  zero.policy = TRUE
)


set.seed(123)

moran_richness_k6 <- moran.mc(
  spatial_analysis$unique_diseases,
  listw = listw6,
  nsim = 999,
  zero.policy = TRUE
)


moran_records_k6

moran_richness_k6



# PART 8: SAVE SPATIAL RESULTS



spatial_results <- tibble(
  outcome = c(
    "Outbreak records",
    "Disease richness",
    "Outbreak records",
    "Disease richness"
  ),
  neighbours = c(
    "k = 4",
    "k = 4",
    "k = 6",
    "k = 6"
  ),
  morans_I = c(
    unname(moran_records_k4$statistic),
    unname(moran_richness_k4$statistic),
    unname(moran_records_k6$statistic),
    unname(moran_richness_k6$statistic)
  ),
  p_value = c(
    moran_records_k4$p.value,
    moran_richness_k4$p.value,
    moran_records_k6$p.value,
    moran_richness_k6$p.value
  )
)


spatial_results


write_csv(
  spatial_results,
  "results/tables/spatial_autocorrelation_results.csv"
)