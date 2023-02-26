###Before using this script, I recommend that you read the README.md file###

#Open the necessary packages (make sure all packages were previously installed)
library(raster)
library(sf)
library(tibble)
library(ggplot2)

#Set the root dir (need to be changed)
root_dir <- "D:/Downloads/B/"

subdirs <- list.dirs(root_dir, recursive = FALSE)

for (i in seq_along(subdirs)) {
  setwd(subdirs[i])
  
  #Load Data
  # MTL
  MTL_filename = list.files(pattern = ".*_MTL.txt")
  MTL = read.delim(MTL_filename, sep = "=")
  
  # Band 4 (RED)
  RED_file <- list.files(pattern = ".*_B4.TIF$")
  RED = raster(RED_file)
  
  # Band 5 (NIR)
  NIR_file <- list.files(pattern = ".*_B5.TIF$")
  NIR = raster(NIR_file)
  
  # Band 10 (TIR)
  TIR_file <- list.files(pattern = ".*_B10.TIF$")
  TIR = raster(TIR_file)
  
  # Band QA_PIXEL
  QA_pixel_file <- list.files(pattern = ".*_QA_PIXEL.TIF$")
  QA_pixel <- raster(QA_pixel_file)
  
  # Mask and Crop to the region (need to be changed)
  area1 = sf::read_sf("D:/Shapes/your_shapefile_dir_and_name.shp")
  
  RED = raster::mask(RED, area1)
  RED = raster::crop(RED, area1)
  
  NIR = raster::mask(NIR, area1)
  NIR = raster::crop(NIR, area1)
  
  TIR = raster::mask(TIR, area1)
  TIR = raster::crop(TIR, area1)
  
  QA_pixel = raster::mask(QA_pixel, area1)
  QA_pixel = raster::crop(QA_pixel, area1)
  
  # Create cloud mask (based on QA_PIXEL band)
  cloud_mask <- ((QA_pixel == 21826) | (QA_pixel == 21890) | (QA_pixel == 22280) | (QA_pixel == 55052) | (QA_pixel == 56856) | (QA_pixel == 56984) | (QA_pixel == 57240)| (QA_pixel == 23888) | (QA_pixel == 24088) | (QA_pixel == 24216) | (QA_pixel == 24344) | (QA_pixel == 24472) | (QA_pixel == 54596) | (QA_pixel == 54852) | (QA_pixel == 55052))
  
  # Apply cloud mask to all bands
  RED[cloud_mask] <- NA
  NIR[cloud_mask] <- NA
  TIR[cloud_mask] <- NA
  
  #Start of the Calculation
  
  # 1. Convert to TOA Radiance
  M = as.numeric(MTL$LANDSAT_METADATA_FILE[which(MTL$GROUP == "    RADIANCE_MULT_BAND_10 ")])
  A = as.numeric(MTL$LANDSAT_METADATA_FILE[which(MTL$GROUP == "    RADIANCE_ADD_BAND_10 ")])
  
  L = (M * TIR) + A
  plot(L)
  
  # 2. Conversion to Top of Atmosphere Brightness Temperature
  K1 = as.numeric(MTL$LANDSAT_METADATA_FILE[which(MTL$GROUP == "    K1_CONSTANT_BAND_10 ")])
  K2 = as.numeric(MTL$LANDSAT_METADATA_FILE[which(MTL$GROUP == "    K2_CONSTANT_BAND_10 ")])
  
  T = (K2 / log((K1/L) + 1)) - 273.15
  
  # 3. NDVI
  NDVI = (NIR - RED) / (NIR + RED)
  plot(NDVI)
  
  # 4. Proportion of vegetation Pv
  NDVI_min = raster::minValue(NDVI)
  NDVI_max = raster::maxValue(NDVI)
  
  Pv = ((NDVI - NDVI_min) / (NDVI_max - NDVI_min))**2
  
  # 5. Calculate Emissivity ε
  E = (0.004 * Pv) +0.986
  
  # 6. Calculate Land Surface Temperature - LST
  BT = T
  w = 10.8 # μm
  
  # h = Planck’s constant (6.626 * 10^-34 Js)
  # s = Boltzmann constant (1.38 * 10^-23 J/K)
  # c = velocity of light (2.998 * 10^8 m/s)
  
  h = 6.626 * 10^-34
  s = 1.38 * 10^-23
  c = 2.998 * 10^8
  p = h * (c / s)
  
  p = 14380
  
  E = E
  
  LST = BT / (1 + ((w * (BT / p)) * log(E)))
  LST
  
#Exporting LST - the .tif file name will include the date of the L8-9 overpass
#The folders names must have the following structure: LCXX_XXXX_XXXXXX_YYYYMMDD_YYYYMMDD_XX_XX
  
  output_filename <- paste0("LST_", substr(MTL_filename, 18, 25), "_", ".tif")
  writeRaster(LST, output_filename, overwrite=TRUE)
  
# If you also want to export the NDVI, then remove the # from the following lines

  #output_filename <- paste0("NDVI_", substr(MTL_filename, 18, 25), "_", ".tif")
  #writeRaster(NDVI, output_filename, overwrite=TRUE)
  
  pal1 <- colorRampPalette(c("green", "yellow", "red"))
  plot(LST, col = pal1(50), main = output_filename)
  
}
