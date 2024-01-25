library(lidR)
library(sf)
library(future)
library(mapview)
library(dplyr)
library(rgl)
library(ggplot2)
library(gstat)
library(rayshader)
library(raster)
library(RCSF)


setwd("Folder_destination_path")
pt_cloud <- readLAScatalog("Folder_where_the_LAS_file_is_.las")

#inspection of the las file, checking if it meets the ASPRS LAS specifications and is valid for processing.
las_check(pt_cloud) 
pt_cloud

#to plot your point cloud over a map
(ptc_map = plot(pt_cloud, map = T, map.types = "OpenStreetMap",  alpha.regions = 0, color = "red", lwd = 3)) # interactive map
summary(pt_cloud)
plot(pt_cloud)

#to allow paralel computing, if it is possible
plan(multisession(workers = 20))

#to divide the data into small subsets and export it in several las files
opt_chunk_size(pt_cloud) <- 100              # size of square tiles [m]
opt_chunk_buffer(pt_cloud) <- 0             # overlap with other tiles?
plot(pt_cloud, chunk=T)
opt_output_files(pt_cloud) <- paste0(getwd(), "folder_path/retile/tile_{ID}") # file names
pt_cloud = catalog_retile(pt_cloud)
plot(pt_cloud)

#taking the list of the las files and upload them again inside the script
tls = list.files("folder_path/retile", pattern = ".las", full.names = T) # list all tiles
head(tls)
ctg = readLAScatalog(tls)
plot(ctg, alpha.regions = 0, color = "red", map=T)

#ground classification
ctg_class_pmf = classify_ground (ctg, algorithm = csf())
tile = readLAS(ctg_class_pmf)
tile$Classification |> table()

#DTM with TIN
ctg_class_pmf = readLAScatalog(list.files("folder_path", ".las", full.names = T))
opt_chunk_size(ctg_class_pmf) = 100
opt_output_files(ctg_class_pmf) =  file.path(getwd(), "/folder_path/TIN_DTM/{ID}_dtm")
ctg_class_pmf@output_options$drivers$SpatRaster$param$overwrite = T
plan(multisession(workers = 20))
dtm_tin <- rasterize_terrain(ctg_class_pmf, res = 0.1, algorithm = tin())

