library(httr)
library(jsonlite)
library(sf)
library(dplyr)
library(terra)
library(sp)
library(raster)
library(tmap)
library(tidyverse)
library(ggplot2)
library(ggspatial)

# INITIAL DATA PREPARATION


# request into web map service

#response <- GET("https://api.openchargemap.io/v3/poi/",
#                query = list(
#                  output = "json",
#                 countrycode = "EE",
#                  maxresults = 500,
#                  compact = "true",
#                  verbose = "false",
#                  key = ""  # I should register in OCM for it
#                ))

# reconsruction of JSON

#data <- fromJSON(content(response, "text", encoding = "UTF-8"))

#glimpse(data)

# get data from OCM

#stations_raw <- bind_cols(
#  dplyr::select(data, ID),
#  data$AddressInfo
#)

# create a simple feature layer

#stations_sf <- st_as_sf(
#  stations_raw,
#  coords = c("Longitude", "Latitude"),
#  crs = 4326
#)

# check

#glimpse(stations_sf)

# save as shapefile

#st_write(stations_sf, "C:/PythonGIS/geopython2025/R_01/charging_stations_estonia.shp", delete_layer = TRUE)

# Load shapefile
stations <- st_read("C:/PythonGIS/geopython2025/R_01/charging_stations_estonia.shp")

# Project to a metric CRS (Estonia official: EPSG:3301)
stations_3301 <- st_transform(stations, 3301)

glimpse(stations_3301)

# Keep desired columns (including geometry!)
stations_3301 <- dplyr::select(stations_3301, ID___1, Title, AddrsL1, Town, SttOrPr, geometry)  # Keep desired columns (including geometry!)

glimpse(stations_3301)

# make columns more readable
stations_3301 <- stations_3301 %>%
  rename(
    id = ID___1,
    title = Title,
    address = AddrsL1,
    municipality = Town,
    county = SttOrPr
  )

glimpse(stations_3301)


# DISTANCE TO THE NEAREST STATION CALCULATION


# Estonia administrative boundary (maakond) as extent
maakond <- st_read("C:/PythonGIS/geopython2025/R_01/maakond.shp")

maakond_3301 <- st_transform(maakond, 3301)

# convert to terra Objects
stations_vect <- vect(stations_3301)
maakond_vect <- vect(maakond_3301)

# Create empty raster grid over Estonia extent
r <- rast(ext(maakond_vect), resolution = 500)  # 100m cell size
crs(r) <- "EPSG:3301"

# Rasterize points (set value = 1 at station locations)
pts_rast <- rasterize(stations_vect, r, field = 1)

# Compute distance from each raster cell to nearest station (in meters)
dist_rast <- distance(pts_rast)

# Clip raster to Estonia boundary
dist_rast_clipped <- mask(dist_rast, maakond_vect)

# convert m to km
r_kilometers <- dist_rast_clipped / 1000

# Plot
plot(r_kilometers, main = "Distance to Nearest Charging Station (m)")

# Save to raster file
writeRaster(r_kilometers, "C:/PythonGIS/geopython2025/R_01/charging_stations_distance_km.tif", overwrite = TRUE)

st_write(stations_3301, "C:/PythonGIS/geopython2025/R_01/charging_stations_est.shp", delete_layer = TRUE)


# for design a final map load layers that you need to represent
stations_est <- st_read("C:/PythonGIS/geopython2025/R_01/charging_stations_est.shp")

distance_matrix <- rast("C:/PythonGIS/geopython2025/R_01/charging_stations_distance_km.tif")

# # transform crs
stations_est <- st_transform(stations_est, crs(distance_matrix))

# # Convert to df for ggplot
distance_df <- as.data.frame(distance_matrix, xy = TRUE, na.rm = TRUE)
colnames(distance_df)[3] <- "distance"

# design a map
ggplot() +
  geom_raster(data = distance_df, aes(x = x, y = y, fill = distance)) +
  scale_fill_gradientn(
    colours = viridisLite::cividis(20),
    name = "Distance to station (km)"
  ) +
  geom_sf(data = stations_est, color = "black", fill = "orange", size = 1.5, shape = 21) +
  annotation_scale(location = "bl", width_hint = 0.2, text_cex = 0.6) +
  annotation_north_arrow(location = "tr", which_north = "true",
                         style = north_arrow_orienteering(text_size = 0.00000001)) +
  labs(
    title = "Accessibility to charging stations in Estonia",
    subtitle = "Source: OpenChargeMap, Estonian Landboard",
    caption = "Author: Mihhail Batura"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, color = "black"),
    plot.subtitle = element_text(hjust = 0, color = "black", size = 8),
    plot.caption = element_text(hjust = 1, color = "black", size = 8),
    plot.background = element_rect(fill = "white"),              # Set the plot background to white
    panel.background = element_rect(fill = "#b3b3b3"),
    legend.title = element_text(size = 8),
    legend.position = "right"
  )

# Save the map as a PNG image
ggsave("C:/PythonGIS/geopython2025/R_01/MB_dist_matrix.png", width = 8, height = 6, dpi = 300)
