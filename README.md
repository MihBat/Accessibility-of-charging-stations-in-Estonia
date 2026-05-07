# Accessibility of EV charging stations in Estonia

**University:** University of Tartu

**Author:** Mihhail Batura

**Supervisors:** PhD Alexander Kmoch, PhD Anto Aasa, PhD Holger Virro, MSc Pamela Maricela Guaman Pintado 

## Overview

Electric vehicle adoption is growing, but the usability of EVs depends heavily on the accessibility of charging infrastructure. This project evaluates the spatial accessibility of charging stations in Estonia using two complementary methods:

1. **Euclidean distance** to the nearest station (whole country)
2. **Travel time** to the nearest station (southeastern Estonia), accounting for road network and rivers as barriers.

## Methodology

**Data sources**: OpenChargeMap, Estonian Land and Spatial Development Board, university course data

**Distance matrix (whole Estonia):**  
Calculates straight-line (Euclidean) distance from any point to the nearest of 167 charging stations.  
*Tool: R (raster distance)*

**Travel time (southeastern Estonia):**  
A cost-distance analysis for 7 counties (Järva, Jõgeva, Tartu, Põlva, Võru, Valga, Viljandi).  
- 55 charging stations within the study area  
- Roads classified into 5 speed categories (main road: 90 km/h, street: 30 km/h, etc.)  
- Rivers treated as barriers (speed multiplier 0.1)  
- Algorithm: Dijkstra (MCP_Geometric)  
*Tools: R (speed raster) + Python GeoPandas (shortest path)*

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

## Results

1. **Distance map to nearest station (Estonia)** - 
output/MB_dist_matrix.png
- Most stations are located in or near cities (Tallinn, Tartu, Pärnu)  
- Ruhnu island is extremely remote (distance > 150 km from nearest station)

2. **Travel time map to nearest station (southeastern Estonia)** - 
output/MB_travel_time_se.png
- Average travel time to nearest station ≤ 10 minutes under ideal conditions  
- Rural areas (forests, swamps) without paved roads may face accessibility challenges

## Full report
MB_fproj.pdf

## Run instructions

1. Clone the repository or download as ZIP.
2. **R**: Install required packages:

install.packages(c("httr", "jsonlite", "sf", "dplyr", "terra", "sp", "raster", "tmap", "tidyverse", "ggplot2", "ggspatial"))
3. **Python**: Install required packages:
   ```bash
   pip install -r requirements.txt
