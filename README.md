# Accessibility of EV charging stations in Estonia

**University** University of Tartu
**Author:** Mihhail Batura
**Supervisors** PhD Alexander Kmoch, PhD Anto Aasa, PhD Holger Virro, MSc Pamela Maricela Guaman Pintado 

## Overview

This project evaluates the accessibility of electric vehicle (EV) charging stations in Estonia using two spatial approaches:

1. **Euclidean distance** to the nearest station (whole country)
2. **Travel time** to the nearest station (southeastern Estonia), accounting for road network and rivers as barriers.

## Workflow

1. **Distance matrix (R)** – `code/Batura_fproj1.R`  
   Creates a raster of Euclidean distance to the nearest station.

2. **Speed raster preparation (R)** – `code/Batura_fproj2.R`  
   Builds a speed raster (m/min) based on road classes and rivers as barriers.  

3. **Travel time calculation (Geopandas)** – `code/Batura_fproj3.ipynb`  
   Cost‑distance analysis using Dijkstra's algorithm (`MCP_Geometric`).

4. **Final map (R)** – `code/Batura_fproj4.R`  
   Loads travel time raster, classifies, and produces the final map.

## Technologies

- **R**: `sf`, `terra`, `dplyr`, `ggplot2`, `ggspatial`
- **Python**: `rasterio`, `numpy`, `skimage.graph`, `geopandas`
- **Data sources**: OpenChargeMap, Estonian Land Board, university course data

## Results

1. Distance map to nearest station (Estonia)
output/MB_dist_matrix.png
2. Travel time map to nearest station (southeastern Estonia)
output/MB_travel_time_se.png

## Full report
MB_fproj.pdf
