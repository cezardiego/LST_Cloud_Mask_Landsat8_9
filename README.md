LST_Cloud_Mask_Landsat8_9

=== Land Surface Temperture (Landsat8-9) with cloud masking ===

This script has been adapted from the original version, written by Konlavach Mengsuwan and available at https://github.com/KonlavachMengsuwan/LST_Landsat8_L1.

The script calculates Land Surface Temperature (LST) from Landsat 8/Landsat9 images, including automatic cloud masking based on the QA_PIXEL band.

Make sure all required packages are installed before running the script.

Main improvements compared to the previously mentioned version:

1. Includes loop to run script on all subdirectories within a root dir, allowing to get LST for multiple dates/images;

2. Includes automatic removal of clouds and cloud shadows based on QA_PIXEL band. Note that you can customize this field. For more information, check the product's user guide, available at https://www.usgs.gov/landsat-missions/landsat-collection-2-level-1-data.