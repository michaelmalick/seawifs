#####################################################################
# Map the SeaWiFS Chl-a for the NEP Subset
#
# This script maps the SeaWiFS chl-a data on the original spatial
# scale (i.e., 9km x 9km) for each composite created for the North
# East Pacific subset
# 
# Michael Malick
# 08 Aug 2013
#
#####################################################################
#
# Functions:
#   - map.chl()
#
#####################################################################



library(ncdf)
library(malick)
library(lattice)
library(maps)


#####################################################################
# map.chl()
#
# This function reads in the raw seawifs data and plots the raw
# chl-a values (on a log scale) for each time period (e.g., daily)
# for each year. A single jpeg file is created for each day/week and
# year.
#
#####################################################################
# {{{
map.chl.raw <- function(years = 1998:2010, composite = 7,
    data.path = "./data/seawifs_nep/7day_data/",
    plot.path = "./plots/raw_chl/7day_data/") {

    # years = years of data to loop over
    # composite = number of days of composite input data
    # data.path = path to the seawifs data

    for(i in years) {

        cat("Plotting", i, "\n")

        if(composite == 1) {
            f.name <- paste(data.path, "S", i, 
                "nep.nc", sep = "")
            time <- "day"
        }

        if(composite == 5) {
            f.name <- paste(data.path, "S", i, 
                "nep5day.nc", sep = "") 
            time <- "pentad"
        }

        if(composite == 7) {
            f.name <- paste(data.path, "S", i, 
                "nep7day.nc", sep = "") 
            time <- "week"
        }

        if(composite == 8) {
            f.name <- paste(data.path, "S", i, 
                "nep8day.nc", sep = "") 
            time <- "octad"
        }

        chl.dat <- load.ncdf(f.name, var = "chl")


        for(j in 1:chl.dat$dim[3]) {

            dat    <- chl.dat$dat[ , , j]
            x      <- chl.dat$datLon
            y      <- chl.dat$datLat
            all.na <- chl.dat$dim[1]*chl.dat$dim[2]

            if(sum(is.na(dat)) == all.na) {
                cat("    ", time, j, "(no data)", "\n")
                color <- "white"
            }

            if(sum(is.na(dat)) != all.na) {
                cat("    ", time, j, "\n")
                color <- jet.colors
            }

            reg <- c("USA", "Canada")

            p.file <- paste(plot.path, i, "_", j, ".jpg", sep = "")
            jpeg(p.file)

            # Suppress warnings produced when all data are NA
            suppressWarnings(
            l <- levelplot(log(dat, 10), col.regions = color, 
                aspect = "fill", row.values = x, 
                column.values = y, 
                main = paste("Chl-a", i, time, j),
                ylab = "Latitude", xlab = "Longitude", 
                par.settings = mm.par(),
                at = seq(-2, 2, 0.1),
                colorkey = list(labels = list(at = seq(-2, 2, 1), 
                    labels = paste(10^seq(-2, 2, 1)))),
                panel = function(...) {
                    panel.levelplot(...) 
                    mp <- map('world2', fill = TRUE, regions = reg, 
                        plot = FALSE)
                    lpolygon(mp$x - 360, mp$y, col = "grey25", 
                        border = "black")
                }))

                # Suppress warnings produced when all data are NA
                suppressWarnings(print(l))

            dev.off()

        }

    }

}





# }}}



map.chl.raw(years = 1998:2010, composite = 1, 
    data.path = "./1day_data/",
    plot.path = "./maps_nep/1day_composites/")


map.chl.raw(years = 1998:2010, composite = 5, 
    data.path = "./5day_data/",
    plot.path = "./maps_nep/5day_composites/")


map.chl.raw(years = 1998:2010, composite = 7, 
    data.path = "./7day_data/",
    plot.path = "./maps_nep/7day_composites/")


map.chl.raw(years = 1998:2010, composite = 8, 
    data.path = "./8day_data/",
    plot.path = "./maps_nep/8day_composites/")











