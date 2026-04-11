library(sf)
library(dplyr)
library(terra)
library(raster)
library(sp)
library(ggplot2)
library(ggspatial)

# TRAVEL TIME TO THE NEAREST STATION CALCULATION 
# 3. Final processing ad data visualization

# load a calculated travel time raster
travel_time <- rast("C:/PythonGIS/geopython2025/R_01/travel_time_SE.tif")

# load a southestern and central Estonia counties to clip a roads linestring
counties_SE <- st_read("C:/PythonGIS/geopython2025/R_01/selected_counties_SE.shp")

# create a spatvector
maakond_vect <- vect(counties_SE)
maakond_vect <- project(maakond_vect, crs(travel_time))

# crop a travel time raster
travel_crop <- crop(travel_time, maakond_vect)
travel_masked <- mask(travel_crop, maakond_vect)

# check a result
plot(travel_masked, main = "Travel Time to Stations (Selected Counties)")

# it seemed like some pixels have too large values, might be an error of calculation 

# try to remove too high values
travel_masked[travel_masked > 100] <- NA

# check a result
plot(travel_masked, main = "Travel Time ≤ 1000 min")
# seems more logical

writeRaster(travel_masked, "C:/PythonGIS/geopython2025/R_01/travel_time_SE_counties.tif", overwrite = TRUE)



roads_est <- st_read("C:/PythonGIS/geopython2025/R_01/EST_roads.shp")

roads_3301 <- st_transform(roads_est, 3301)

# Crop (rough rectangle)
roads_crop <- st_crop(roads_3301, counties_SE)

# Clip exactly to boundary
roads_clipped <- st_intersection(roads_crop, counties_SE)

# save and check on GIS
st_write(roads_clipped, "C:/PythonGIS/geopython2025/R_01/roads_SE.shp", delete_layer = TRUE)



# for design a final map load layers that you need to represent
roads_se <- st_read("C:/PythonGIS/geopython2025/R_01/roads_SE.shp")

travel_time_100m <- rast("C:/PythonGIS/geopython2025/R_01/travel_time_SE_counties.tif")

stations_se <- st_read("C:/PythonGIS/geopython2025/R_01/stations_counties_SE.shp")

# to avoid a system crash make resolution lower
# Aggregate to 500x500 m: factor = 5 (since 500 / 100 = 5)
travel_time_500m <- aggregate(travel_time_100m, fact = 5, fun = "mean", na.rm = TRUE)

# save and check on GIS
writeRaster(travel_time_500m, "C:/PythonGIS/geopython2025/R_01/travel_time_500m.tif", overwrite = TRUE)

# check crs
crs_rast <- crs(travel_time_500m)
roads_se <- st_transform(roads_se, crs_rast)
stations_se <- st_transform(stations_se, crs_rast)

# Define 6 classes of travelling time
breaks <- c(0, 10, 20, 30, 40, 50, Inf)
labels <- c("≤ 10", "10–20", "20–30", "30–40", "40–50", "> 50")

# Classify 
rcl_matrix <- matrix(c(
  0, 10, 1,
  10, 20, 2,
  20, 30, 3,
  30, 40, 4,
  40, 50, 5,
  50, Inf, 6
), ncol = 3, byrow = TRUE)

tt_classified <- classify(travel_time_500m, rcl = rcl_matrix)

# Convert to df for ggplot
tt_df <- as.data.frame(tt_classified, xy = TRUE, na.rm = TRUE)
colnames(tt_df)[3] <- "class"

# Make sure it's a factor with correct levels
tt_df$class <- factor(tt_df$class, levels = 1:6, labels = labels)

# define a color palette for 6 classes
travel_colors <- c(
  "≤ 10" = "#1a9641",
  "10–20" = "#a6d96a",
  "20–30" = "#ffffbf",
  "30–40" = "#fdae61",
  "40–50" = "#d7191c",
  "> 50" = "#800026"
)

# design a map
ggplot() +
  geom_raster(data = tt_df, aes(x = x, y = y, fill = class)) +
  scale_fill_manual(
    name = "Travel time, min",
    values = travel_colors
  ) +
  geom_sf(data = roads_se, color = "grey20", size = 0.1, alpha = 1) +
  geom_sf(data = stations_se, shape = 21, fill = "yellow", color = "black", size = 2) +
  annotation_scale(location = "bl", width_hint = 0.2) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_orienteering(text_size = 0)) +
  labs(
    title = "Charging station accessibility in southeastern Estonia",
    subtitle = "Source: OpenChargeMap, Estonian Landboard",
    caption = "Author: Mihhail Batura"
  ) +
  coord_sf() +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, color = "black"),
    plot.subtitle = element_text(hjust = 0, color = "black", size = 8),
    plot.caption = element_text(hjust = 1, color = "black", size = 8),
    plot.background = element_rect(fill = "white"),              # Set the plot background to white
    panel.background = element_rect(fill = "white"),
    legend.title = element_text(size = 8),
    legend.position = "right"
  )

# Save the map as a PNG image
ggsave("C:/PythonGIS/geopython2025/R_01/MB_travel_time_se.png", width = 8, height = 6, dpi = 300)
