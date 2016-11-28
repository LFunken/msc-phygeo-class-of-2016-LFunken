library(RSAGA) 
library(raster)
library(glcm)
library(gdalUtils)

source("C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/Kurse/fun/add2Path.R")
source("C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/Kurse/fun/gdalUtils.R")
source("C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/Kurse/fun/initSaga.R")
source("C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/Kurse/fun/makGlobalVar.R")

filepath_base<-"C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/data/gis/"
filepath_fun <- "C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/Kurse/fun/"
path_input <- "C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/data/gis/input/"
path_output <- "C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/data/gis/output/"
path_saga <- "C:/OSGeo4W/apps/saga/saga_cmd.exe"
inputFile <- paste0(path_input, "geonode-las_intensity.tif")

gdal<- initgdalUtils()

#1. no Filer
system(paste0(path_saga," io_gdal 0",
              " -GRIDS=", path_output,"rt_dem.sgrd",
              " -FILES=",path_input,"geonode-las_intensity.tif")
)

dem <-raster::raster(paste0(path_input,"geonode-las_intensity.tif"))

cmd <- system(paste0(path_saga," ta_morphometry 0 ",
                     "-ELEVATION ",path_output,"dem_fp.sgrd ",
                     "-SLOPE ",path_output,"dem_slope.sgrd ", 
                     "-ASPECT ",path_output,"dem_aspect.sgrd ",
                     "-C_MINI ",path_output,"dem_mincurve.sgrd ",
                     "-C_MAXI ",path_output,"dem_maxcurve.sgrd"))

cmd <- system(paste0(path_saga," ta_morphometry 25 ",
                     "-SLOPE ",path_output,"dem_slope.sgrd ", 
                     "-MINCURV ",path_output,"dem_mincurve.sgrd ",
                     "-MAXCURV ",path_output,"dem_maxcurve.sgrd ", 
                     "-TCURV ",path_output,"dem_tangcurve.sgrd ",
                     "-PCURV "  ,path_output,"DEM_profcurve.sgrd ",
                     "-PLAIN ",path_output, "dem_plain.sgrd",
                     "-SLOPETODEG=0 ",
                     "-T_SLOPE_MIN=5 ",
                     "-T_SLOPE_MAX=15 ",
                     "-T_CURVE_MIN=0.000002 ",
                     "-T_CURVE_MAX=0.00005 "))

outfile <- paste0(path_output, "dem_plain.sgrd")
outfile <- paste0(substr(outfile, 1, nchar(outfile)-4), "tif")

cmd <- paste0(path_saga," io_gdal 2",
              " -GRIDS ", paste0(path_output, "dem_plain.sgrd"),
              " -FILE ", outfile)
system(cmd)

plain_late<-raster(paste0(path_output,"dem_plain.tif"))
plot(plain_late)

plain_reclass <- reclassify(plain_late, matrix(c(0.7,1,1)))
plot(plain_reclass)

plain_reclass[plain_reclass == 1 & dem < 250] <- 1
plain_reclass[plain_reclass == 1 & dem >= 250] <- 2

plot(plain_reclass)
writeRaster(plain_reclass, "plain_no_filter.tif")

#2. late Filter
msize <- 5

system(paste0(path_saga," grid_filter 6 ",
              "-INPUT ",path_output,"dem_plain.sgrd ",
              "-MODE 0 ",
              "-RESULT ",path_output,"rt_modalSAGA.sgrd ",
              "-RADIUS  ",msize," ",
              "-THRESHOLD 0.000000"))


plain_late_mean <- focal(plain_late, w=matrix(1, nc=msize, nr=msize), fun=modal, na.rm = TRUE, pad = TRUE)
plot(plain_late)

plain_late_reclass <- reclassify(plain_late, matrix(c(0.7,1,1)))
plot(plain_late_reclass)

plain_late_reclass[plain_late_reclass == 1 & dem < 250] <- 1
plain_late_reclass[plain_late_reclass == 1 & dem >= 250] <- 2

plot(plain_late_reclass)
writeRaster(plain_late_reclass, "plain_late_filter.tif")

#3. mean filter
ksize <- 3
dem_focal<- raster::focal(dem, w=matrix(1/(ksize*ksize)*1.0, nc=ksize, nr=ksize))

raster::writeRaster(dem_focal,paste0(path_output,"dem_mean.tif"),overwrite=TRUE)

system(paste0(path_saga," grid_filter 0",
              " -INPUT ",path_output,"rt_dem.sgrd",
              " -RESULT ",path_output,"rt_fildemSAGA.sgrd",
              " -RADIUS ",as.character(ceiling((ksize/2)+1))))
raster::plot(dem_focal)

gdalUtils::gdalwarp(paste0(path_output,"rt_fildemSAGA.sgrd"),paste0(path_output,"rt_fildemSAGA.tif") , overwrite=TRUE)  
demfSAGA<-raster::raster(paste0(path_output,"rt_fildemSAGA.tif"))
raster::plot(demfSAGA$rt_fildemSAGA)

cmd <- system(paste0(path_saga," ta_morphometry 0 ",
                     "-ELEVATION ",path_output,"rt_fildemSAGA.sgrd ",
                     "-SLOPE ",path_output,"dem_slope.sgrd ", 
                     "-ASPECT ",path_output,"dem_aspect.sgrd ",
                     "-C_MINI ",path_output,"dem_mincurve.sgrd ",
                     "-C_MAXI ",path_output,"dem_maxcurve.sgrd"))

cmd <- system(paste0(path_saga," ta_morphometry 25 ",
                     "-SLOPE ",path_output,"dem_slope.sgrd ", 
                     "-MINCURV ",path_output,"dem_mincurve.sgrd ",
                     "-MAXCURV ",path_output,"dem_maxcurve.sgrd ", 
                     "-TCURV ",path_output,"dem_tangcurve.sgrd ",
                     "-PCURV "  ,path_output,"dem_profcurve.sgrd ",
                     "-PLAIN ",path_output, "dem_plain.sgrd",
                     "-SLOPETODEG=0 ",
                     "-T_SLOPE_MIN=5 ",
                     "-T_SLOPE_MAX=15 ",
                     "-T_CURVE_MIN=0.000002 ",
                     "-T_CURVE_MAX=0.00005 "))

outfile <- paste0(path_output, "dem_plain.sgrd")
outfile <- paste0(substr(outfile, 1, nchar(outfile)-4), "tif")

cmd <- paste0(path_saga," io_gdal 2",
              " -GRIDS ", paste0(path_output, "dem_plain.sgrd"),
              " -FILE ", outfile)
system(cmd)

plain_mean<-raster(paste0(path_output,"dem_plain.tif"))
plot(plain_mean)

plain_mean_reclass <- reclassify(plain_mean, matrix(c(0.7,1,1)))
plot(plain_mean_reclass)

plain_mean_reclass[plain_mean_reclass == 1 & dem < 250] <- 1
plain_mean_reclass[plain_mean_reclass == 1 & dem >= 250] <- 2

plot(plain_mean_reclass)
writeRaster(plain_mean_reclass, "plain_mean_filter.tif")