#####################################################################
# R SCRIPT TO DOWNLOAD SEAWIFS SATELLITE DATA
#
# This script downloads daily level-3 processed mapped chl-a data
# (9 km resolution) from 1 Jan 1998 - 31 Dec 2010. The raw seawifs
# data from NASA comes in HDF4 format. You need to be a registered
# user in order to download the seawifs data products.
#
# Need the wget utility (get using Homebrew on Mac OSX)
#
# Data are saved to the ./rawdata directory in compressed format
# 
# Data Source: http://oceandata.sci.gsfc.nasa.gov
#   Need a Username and Password (replace XXX below in code)
#
#
# Michael Malick
# 08 Aug 2013
#
#####################################################################
# PSUEDO-CODE 
#
# For each year
#  For each day of the year
#   1. Download daily seawifs data file (hdf format)
# 
#####################################################################



for(i in 2000) {

    # Account for leap years
	leap <- abs((i - 2000) %% 4) + 1 # leap == 1 is a leap year

    if(leap == 1)
        days <- 1:366
    else
        days <- 1:365

    for(j in days) {
        
        cat("Downloading", i, "day", j, "\n")

        # Need to add leading zeros to numbers < 100
        if(j < 10) j <- paste("00", j, sep = "")
        if(j > 9 & j < 100) j <- paste("0", j, sep = "")

        # URL of data source
        web <- paste("http://oceandata.sci.gsfc.nasa.gov/restrict/", 
            "getfile/S", i, j, ".L3m_DAY_CHL_chlor_a_9km.bz2", 
            sep = "")

        # File name to save data to
        f.name <- paste("./rawdata/S", i, j, sep = "")

        # Download file
        download.file(web, destfile = paste(f.name, ".hdf.bz2", 
            sep = ""), 
            method = "wget", mode = "wb", 
            extra = "--user=XXX --password=XXX")
    }
}



