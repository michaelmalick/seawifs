#####################################################################
# R SCRIPT TO PROCESS SEAWIFS HDF4 DATA FILES
#
# This script takes as input, compressed daily  level-3 mapped 
# seawifs data and subsets the area to the NE Pacific. It then 
# writes the data in netCDF format with one file per year that
# containes an array with 365 slices (one for each day of the year).
#
# Full seawifs datafiles (downloaded from NASA) are located in:
#   ./data/seawifs
#
# Seawifs data files are in HDF4 format
# Level-3 mapped data products for 1998-2010
#
# Map subset 45N to 70N and -170W to -120W (NE Pacific)
#
# Need both ncl and nco operators installed to work
#
# This script takes ~4hr to run on a Mac OSX 10.8.2 2.53 Ghz dual
# core processor with 4 GB of ram
#
# Michael Malick
# 01 Jul 2013
#
#####################################################################
#
# For each year
#  For each day of the year
#   1. Uncompress HDF data file
#   2. Convert to netCDF format
#   3. Read in netCDF data file (~34 mb)
#   4. Subset latitude and longitude
#   5. Write subsetted data to new netCDF file (~90 kb)
#   6. Delete original .hdf and .nc data files
# 
#####################################################################



library(ncdf)



for(i in 1999:2010) {

    # Account for leap years
    leap <- abs((i - 2000) %% 4) + 1 # leap == 1 is a leap year

    if(leap == 1)
        days <- 1:366
    else
        days <- 1:365

    for(j in days) {
     
        cat("Processing Year", i, "Day", j, "\n")

        if(j < 10) j <- paste("00", j, sep = "")
        if(j > 9 & j < 100) j <- paste("0", j, sep = "")

        # File name
        f.name <- paste("S", i, j, sep = "")

        # -----------------------------------------------
        # Check if the compressed HDF4 is empty. If it 
        # is create an empty netCDF with the same
        # dimensions as the raw HDF4 file. If it's not
        # continue processing the data.
        # ------------------------------------------------
        if(file.info(paste("./rawdata/", f.name, ".hdf.bz2", 
            sep = ""))$size < 0.1) {

            mat <- matrix(rep(NA, 2160*4320), ncol = 2160, 
                nrow = 4320)

            # Create empty netCDF file
            m <- dim.def.ncdf(name = "x", units = "units", 
                vals = 1:2160)
            n <- dim.def.ncdf(name = "y", units = "units", 
                vals = 1:4320)


            na.var <- var.def.ncdf(name = "l3m_data", 
                units = "units", dim = list(m, n), missval = -32767)

            na.nc <- create.ncdf(paste(f.name, ".nc", sep = ""), 
                na.var)

            put.var.ncdf(na.nc, na.var, mat)
            close.ncdf(na.nc)

        } else {

            # Copy compressed HDF4 data to working directory
            file.copy(paste("./rawdata/", f.name, ".hdf.bz2", 
                sep = ""), paste("./"))

            # Unzip file
            invisible(system(paste("bunzip2 -kf ", f.name, 
                ".hdf.bz2", sep = "")))

            # Convert to .nc
            system(paste("ncl_convert2nc ", f.name, ".hdf", 
                sep = ""))
        }

        # Read in .nc file
        dat.file.nc <- open.ncdf(paste(f.name, ".nc", sep = ""))
        dat.nc      <- get.var.ncdf(dat.file.nc, 
                           varid = "l3m_data")    
        dim.nc      <- dim(dat.nc)  
        invisible(close.ncdf(dat.file.nc)) 
        x <- list(dim = dim.nc, dat = dat.nc)

        # Create lat and lon vectors
        x$lat <- seq(-90, 90, 0.083334)
        x$lon <- seq(-180, 180, 0.083334)

        # Flip the data matrix (needed to use the image() function)
        # I do this to make it easier to plot the data in R
        dat.flip <- x$dat[1:dim(x$dat)[1], dim(x$dat)[2]:1]  

        # Subset lat and lon 
        lat.min <- which(x$lat > 44.99 & x$lat < 45.01)
        lat.max <- which(x$lat > 69.99 & x$lat < 70.01)
        lon.min <- which(x$lon < -169.99 & x$lon > -170.01)
        lon.max <- which(x$lon < -119.99 & x$lon > -120.01)

        lat <- x$lat[lat.min:lat.max]
        lon <- x$lon[lon.min:lon.max]
        dat <- dat.flip[lon.min:lon.max, lat.min:lat.max]

        # ----------------------------
        # Write new netCDF data file
        # ----------------------------
        m <- dim.def.ncdf(name = "lon", units = "degrees_east", 
            vals = lon)

        n <- dim.def.ncdf(name = "lat", units = "degrees_north", 
            vals = lat)

        t <- dim.def.ncdf(name = "time", 
            units = "hours since 1800-1-1 0:0:0", vals = 365, 
            unlim = TRUE)

        chl <- var.def.ncdf(name = "chl", units = "mg m^3", 
            dim = list(m,n,t), missval = -32767,
            longname = "Chl-a concentration")

        chl.nc <- create.ncdf(paste(f.name, "nep.nc", sep = ""), chl)

        put.var.ncdf(chl.nc, chl, dat)

        # Need to specify the _FillValue in order for the NCO
        # averager (ncra) to properly handle missing values
        att.put.ncdf(chl.nc, varid = chl, attname = "_FillValue",
            attval = -32767)

        att.put.ncdf(chl.nc, varid = 0, attname = "history", 
            attval = 
            "Sea-viewing Wide Field-of-view Sensor (SeaWiFS) daily
            chlorophyll-a in mg m-3 for the NE Pacific 
            (45-70N, 170-120W).  The data are the
            'standard mapped image' level 3 data.  The original data
            are 9km resolution which is consistent with the grid
            resolution on the equator.  The SeaWiFS data are produced
            by the National Aeronautics and Space Administration, and
            are available at
            http://seawifs.gsfc.nasa.gov/SEAWIFS.html.  O Reilly,
            J.E., and 24 Coauthors, 2000: SeaWiFS Postlaunch
            Calibration and Validation Analyses, Part 3. NASA Tech.
            Memo. 2000-206892, Vol. 11, S.B. Hooker and E.R.
            Firestone, Eds., NASA Goddard Space Flight Center, 49 pp.
            http://seawifs.gsfc.nasa.gov/seawifs_scripts/
            postlaunch_tech_memo.pl?11
            Wang, M., K. D. Knobelspiesse, and C. R. McClain, 2005:
            Study of the Sea-Viewing Wide Field-of-View Sensor
            (SeaWiFS) aerosol optical property data over ocean in
            combination with the ocean color products.  J. Geophys.
            Res., 110, D10S06, doi:10.1029/2004JD004950 The data were 
            written at NASA in September 2010, and I wrote the file.
            Michael Malick, July 2013." )

        close.ncdf(chl.nc)

        # Delete temp files
        unlink(paste(f.name, ".hdf.bz2", sep = ""))
        unlink(paste(f.name, ".hdf", sep = ""))
        unlink(paste(f.name, ".nc", sep = ""))

    }

    # Concatanate daily files into a single yearly file
    system(paste("ncrcat -h ", "S", i, "???nep.nc ", "S", i, "nep.nc",
        sep = ""))

    # Delete daily subsetted .nc files
    system(paste("rm ", "S", i, "???nep.nc ", sep = ""))

}







