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

travel_time_100m <- rast("C:/PythonGIS/geopython2025/R_01/travel_time_SE_counties.tif")

# to avoid a system crash make resolution lower
# Aggregate to 500x500 m: factor = 5 (since 500 / 100 = 5)
travel_time_500m <- aggregate(travel_time_100m, fact = 5, fun = "mean", na.rm = TRUE)

# save and check on GIS
writeRaster(travel_time_500m, "C:/PythonGIS/geopython2025/R_01/travel_time_500m.tif", overwrite = TRUE)

# final output visualisation in QGIS using travel_time_500m.tif, roads_SE.shp, stations_counties_SE.shp


