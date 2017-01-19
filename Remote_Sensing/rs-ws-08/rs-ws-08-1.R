library(satelliteTools)

#Pfade setzen
path_data <- "C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/data/remote_sensing/input/"
path_tmp <- "C:/Users/Lena/Documents/Uni/Master_Marburg/1.Semester/data/remote_sensing/temp/"
path_orfeo <- "C:/OSGeo4W64/bin/"
otbPath <- path_orfeo
otbPath <- "C:/QGIS_2.14.5/OTB-5.8.0-win64/bin/"
path_vector <- paste0(path_data, "vector/")

#step 1

otbcli_MeanShiftSmoothing(x=paste0(path_data,"geonode_ortho_muf_rgb_idx_pca_scaled.tif"), outfile_filter = paste0(path_tmp,"outfile_filter.tif" ),
                          outfile_spatial = paste0(path_tmp,"outfile_spatial.tif" ), return_raster = FALSE, spatialr = 5,
                          ranger = 15, thres = 0.1, maxiter = 100, rangeramp = 0,
                          verbose = FALSE, ram = "8192")


#step 2 mit ranger=15,30

for (i in c(15,30)){
  
  otbcli_ExactLargeScaleMeanShiftSegmentation(x=paste0(path_tmp,"outfile_filter.tif"),
                                              inpos = paste0(path_tmp,"outfile_spatial.tif"), out = paste0(path_tmp,paste0("Segmented",as.character(i),".tif")), 
                                              tmpdir = path_tmp, spatialr = 1, ranger = i,
                                              minsize = 0, tilesizex = 500, tilesizey = 500, verbose = FALSE,
                                              return_raster = F)
  
  #step 3 mit minsize= 40,50,60,70
  
  for (u in c(40,50,60,70))   {
    
    
    otbcli_LSMSSmallRegionsMerging(x=paste0(path_tmp,"outfile_filter.tif"), inseg = paste0(path_tmp,paste0("Segmented",as.character(i),".tif")),
                                   out = paste0(path_tmp, "Merging",as.character(i),"_",as.character(u),".tif"), 
                                   minsize = u, tilesizex = 500, tilesizey = 500,
                                   verbose = FALSE, return_raster = FALSE, ram = "8192")
    
    
    #step 4 Vectorization
    
    otbcli_LSMSVectorization(x= paste0(path_data,"geonode_ortho_muf_rgb_idx_pca_scaled.tif"), inseg = paste0(path_tmp, 
                                                                                                             "Merging",as.character(i),"_",as.character(u),".tif"), 
                             out =paste0(path_tmp, "Merging",as.character(i),"_",as.character(u),".shp"),
                             tilesizex = 500, tilesizey = 500, verbose = FALSE, ram = "8192") 
    
    
  }                                        
}


#Merging15_70 ist am besten geeignet, da bei den 30er Merges die Felder nicht 
#genau abgegrenzt wurden. Die anderen 15er Merges zeigen zu viele Details, 
#die eigentlich gar nicht da sind.