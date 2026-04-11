library(sf)
library(dplyr)
library(terra)
library(raster)
library(sp)
library(ggplot2)
library(ggspatial)

# TRAVEL TIME TO THE NEAREST STATION CALCULATION
# 1. Data preparation

# 1. Load original maakond shapefile
maakond_raw <- st_read("C:/PythonGIS/geopython2025/R_01/maakond.shp")

# 2. Project to EPSG:3301 (meters)
maakond_proj <- st_transform(maakond_raw, 3301)

# 3. Split multipolygons into single polygons to clean administrative boundaries from small islands
maakond_single <- st_cast(maakond_proj, "POLYGON")

glimpse(maakond_single)

# 4. Calculate area in km² (geometry is in meters)
maakond_single$area_km2 <- as.numeric(st_area(maakond_single)) / 1e6

# 5. Remove polygons smaller than 100 km² (small islands, artefacts)
maakond_clean <- maakond_single[maakond_single$area_km2 >= 100, ]

glimpse(maakond_clean)
# ok

# 7. Convert to sf object for further use
maakond <- st_as_sf(data.frame(geometry = maakond_clean))

# 8. Save the maakond shapefile (without small islands)
st_write(maakond, "C:/PythonGIS/geopython2025/R_01/maakond_without_islands.shp", delete_layer = TRUE)

# 9. Clean up intermediate objects (optional)
rm(maakond_raw, maakond_proj, maakond_single, maakond_clean)

# Project to Estonian crs: EPSG:3301
maakond_3301 <- st_transform(maakond, 3301)

# Create one-row sf object with unified geometry
estonia_boundary_sf <- st_as_sf(st_union(maakond_3301))

st_write(estonia_boundary_sf, dsn = "C:/PythonGIS/geopython2025/R_01", layer = "estonia_boundary_dissolved", driver = "ESRI Shapefile", delete_layer = TRUE)

# Read the road shapefile
est_roads <- st_read("C:/PythonGIS/geopython2025/R_01/EST_roads.shp")

glimpse(est_roads)

# Project to Estonian crs: EPSG:3301
est_roads_3301 <- st_transform(est_roads, 3301)

# buffer the roads linestring into polygon with 100 m width
est_roads_buffered <- st_buffer(est_roads_3301, dist = 100)

glimpse(est_roads_buffered)

# union the roads by road class
est_roads_buffered_dissolved <- est_roads_buffered %>%
  group_by(level) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

glimpse(est_roads_buffered_dissolved)

# check here or in GIS
plot(st_geometry(est_roads_buffered_dissolved), col = rainbow(length(unique(est_roads_buffered_dissolved$level))))

# "cut" a road zones in Estonia
estonia_without_road_buffers <- st_difference(estonia_boundary_sf, est_roads_buffered_dissolved)

# check
plot(st_geometry(estonia_without_road_buffers), col = "blue", add = TRUE)
# seems not very good

# add a "empty field" level value 0
estonia_without_road_buffers$level <- 0

glimpse(estonia_without_road_buffers)

# rename a geometry column
names(estonia_without_road_buffers)[names(estonia_without_road_buffers) == "x"] <- "geometry"

# set geometry
st_geometry(estonia_without_road_buffers) <- "geometry"

estonia_without_road_buffers <- st_sf(estonia_without_road_buffers, crs = st_crs(est_roads_buffered_dissolved))

# check a results
names(est_roads_buffered_dissolved)
names(estonia_without_road_buffers)

# merge a zone without roads and road zones (creating vectorized raster by road class)
estonia_combined <- rbind(est_roads_buffered_dissolved, estonia_without_road_buffers)

# check here or GIS (on GIS is better)
glimpse(estonia_combined)

# 1. Some rows of roads seems not good for analysis, estonia_combined already contains: 
# - level: road class (0 = no road, 1,2,3,4,5), but it should be 6 classes
# 2. So decided to dissolve roads by 'level' field 

# Dissolve (merge) polygons by 'level' field
estonia_dissolved <- estonia_combined %>%
  group_by(level) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

# Check result
print(paste("Number of unique road classes after dissolve:", nrow(estonia_dissolved)))

glimpse(estonia_dissolved)

# might be better check in GIS, that roads have right "level", e.g. class 5 would be in city

# Save dissolved version (optional, for debugging)
st_write(estonia_dissolved, "C:/PythonGIS/geopython2025/R_01/road_merged.shp", delete_layer = TRUE)

estonia_combined <- st_transform(estonia_dissolved, 3301)

# load a Estonian rivers shapefile and repeat the same steps with rivers
rivers <- st_read("C:/PythonGIS/geopython2025/R_01/jõed.shp")

glimpse(rivers)

rivers_3301 <- st_transform(rivers, 3301)

rivers_buffered <- st_buffer(rivers_3301, dist = 100)

glimpse(rivers_buffered)

rivers_buffered_dissolved <- rivers_buffered %>%
  group_by(level) %>%
  summarise(geometry = st_union(geometry), .groups = "drop")

glimpse(rivers_buffered_dissolved)

estonia_without_river_buffers <- st_difference(estonia_boundary_sf, rivers_buffered_dissolved)

plot(st_geometry(estonia_without_river_buffers), col = "blue", add = TRUE)

# set 0 is an "empty field"
estonia_without_river_buffers$level <- 0

# set 1 is a river buffer
rivers_buffered_dissolved$level <- 1

glimpse(rivers_buffered_dissolved)

names(rivers_buffered_dissolved)
names(estonia_without_river_buffers)

names(estonia_without_river_buffers)[names(estonia_without_river_buffers) == "x"] <- "geometry"

st_geometry(estonia_without_river_buffers) <- "geometry"

estonia_without_river_buffers <- st_sf(estonia_without_river_buffers, crs = st_crs(rivers_buffered_dissolved))

est_rivers <- rbind(rivers_buffered_dissolved, estonia_without_river_buffers)

glimpse(est_rivers)

st_write(est_rivers, "C:/PythonGIS/geopython2025/R_01/rivers_fields.shp", delete_layer = TRUE)


# load a csv file with road speeds by class
road_speed <- read.csv("C:/PythonGIS/geopython2025/R_01/road_speed.csv")

glimpse(road_speed)

# join a table into gdf by road class (level)
estonia_combined <- estonia_combined %>%
  left_join(road_speed, by = "level")

glimpse(estonia_combined)

# check a results about speed column
summary(estonia_combined$speed_km_h)

# create a spatvector before rasterizing
estonia_vect <- vect(estonia_combined)

# create an empty raster
r_template <- rast(ext(estonia_vect), resolution = 100)
crs(r_template) <- crs(estonia_vect)  # 

# create a road speed raster, extent - Estonia
r_speed <- rasterize(estonia_vect, r_template, field = "speed_km_h")

# check a result here or on GIS
plot(r_speed, main = "Speed Map (km/h)", col = terrain.colors(10))

writeRaster(r_speed, "C:/PythonGIS/geopython2025/R_01/speed_map_100_m.tif", overwrite = TRUE)

rm(est_rivers)

# load a river "speed", here the rivers act as barriers
river_speed <- read.csv("C:/PythonGIS/geopython2025/R_01/river_speed.csv")

est_river <- st_read("C:/PythonGIS/geopython2025/R_01/rivers_fields.shp")

# repeat the same steps on rivers
est_rivers <- st_transform(est_river, 3301)

glimpse(est_rivers)

est_rivers <- est_rivers %>%
  left_join(river_speed, by = "level")

glimpse(est_rivers)

river_vect <- vect(est_rivers)

river_temp <- rast(ext(river_vect), resolution = 100)
crs(river_temp) <- crs(river_vect)  # 

riv_speed <- rasterize(river_vect, river_temp, field = "speed_km_h")

plot(riv_speed, main = "Speed Map (km/h)", col = terrain.colors(10))

writeRaster(riv_speed, "C:/PythonGIS/geopython2025/R_01/speed_map_river_100m.tif", overwrite = TRUE)


# load 2 rasters after checking
r1 <- rast("C:/PythonGIS/geopython2025/R_01/speed_map_100_m.tif")
r2 <- rast("C:/PythonGIS/geopython2025/R_01/speed_map_river_100m.tif")

# compare, if geometry is the same
compareGeom(r1, r2, stopOnError = TRUE)

# resample second raster, if needed
r2_resampled <- resample(r2, r1, method = "near")

# combine road classes raster and rivers raster
r_combined <- r1 * r2_resampled

# check here or on GIS
plot(r_combined, main = "Combined Speed Map (Roads × Rivers)")

writeRaster(r_combined, "C:/PythonGIS/geopython2025/R_01/speed_combined_100_m.tif", overwrite = TRUE)

# create a friction raster (km/h to m/min)
r_speed_m_min <- r_combined * (1000 / 60)  # or * 16.6667

# check here or on GIS
writeRaster(r_speed_m_min, "C:/PythonGIS/geopython2025/R_01/speed_combined_m_min.tif", overwrite = TRUE)

# load charging stations (as sf)
stations_sf <- st_read("C:/PythonGIS/geopython2025/R_01/charging_stations_est.shp")

glimpse(stations_sf)

# to avoid a system crash, make a research area smaller (to calculate travel time)

glimpse(maakond_3301)

# choose a research area (extent)
wanted <- c("Valga maakond", "Tartu maakond", "Järva maakond",
            "Viljandi maakond", "Võru maakond", "Jõgeva maakond", "Põlva maakond")

# use counties as extent
maakond_selected <- maakond_3301 %>%
  filter(MNIMI %in% wanted)

glimpse(maakond_selected)

st_write(maakond_selected, "C:/PythonGIS/geopython2025/R_01/selected_counties_SE.shp", delete_layer = TRUE)

# check a crs of both layers
st_crs(stations_sf)
st_crs(maakond_selected)

# select only this charging stations that located in research area
stations_in_selected <- stations_sf[st_intersection(stations_sf, maakond_selected, sparse = FALSE), ]

st_write(stations_in_selected, "C:/PythonGIS/geopython2025/R_01/stations_counties_SE.shp", delete_layer = TRUE)

# load a friction raster
speed_m_min <- rast("C:/PythonGIS/geopython2025/R_01/speed_combined_m_min.tif")

# change to spatvector
maakond_vect <- vect(maakond_selected)  # sf → SpatVector
maakond_vect <- project(maakond_vect, crs(speed_m_min))  # to raster crs

# crop a friction raster
speed_crop <- crop(speed_m_min, maakond_vect)
speed_clipped <- mask(speed_crop, maakond_vect)

# check a result
plot(speed_clipped, main = "Speed (m/min) — Selected Counties")

writeRaster(speed_clipped, "C:/PythonGIS/geopython2025/R_01/speed_m_min_SE_counties.tif", overwrite = TRUE)


# Calculating a travel time did not work here. So decide to arrange it in geopython software (Batura_fproj3.ipynb)

