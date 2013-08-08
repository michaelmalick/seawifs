#!/bin/csh -f

#####################################################################
# This script computes pentads from daily resolution chl-a data
# recorded by SeaWiFS. 
#
# To run this script:
#   - Change working directory to this folder
#   - chmod a+x 5day_write.csh
#   - ./5day_write.csh
#
#
# Michael Malick
# 26 Mar 2013
#
#####################################################################



# Define 'environment' variables
set THIS_DIR = `pwd`
set OUT_DIR = $THIS_DIR/5day_data
set SRC_DIR = $THIS_DIR/1day_data
# set OUTFIL = $OUT_DIR/2008_chloro_pentad.nc
set INFIL = nep
set DAY = 5day
set NCOOPTS = '-O -F -h -H'
#	-h don't append header
#	-F use Fortran subscripts [1-5] vs C subscripts [0-4]

cd $SRC_DIR

set yr = 1998
set ind1 = 1

while ( $yr <= 2010 )
    
    echo "Year = $yr"
    set pen_ind = 1
    set day_ind = 1
    set fname = $SRC_DIR/S$yr$INFIL.nc

    @ leap = $yr % 4 # @ means 'math follows'

    while ( $pen_ind <= 73 ) # throw-out december 31 of each yr
		
		# account for leap years
		if ( $leap == 0 && $pen_ind == 12 ) then
		    set ind2 = 6
		else
		    set ind2 = 5
		endif
		
		# create temporary file for each pentad
		if ( $pen_ind < 10 ) then
		    set temfil = $SRC_DIR/temfil.0$pen_ind.nc
		else
		    set temfil = $SRC_DIR/temfil.$pen_ind.nc
		endif

		@ ind1a = $day_ind + $ind1 - 1 # low (1)
		@ ind2a = $day_ind + $ind2 - 1 

		# create average and save to temp file
		ncra -H -h $NCOOPTS -d time,$ind1a,$ind2a $fname $temfil

	    @ day_ind = $day_ind + $ind2 
		@ pen_ind = $pen_ind + 1 

    end

	# concatenate all temp pentad files for a year
	echo "Concatenating files for $yr"
    ncrcat -O -H -h $SRC_DIR/temfil.??.nc $OUT_DIR/S$yr$INFIL$DAY.nc
	# ? means all digits from 0 to 9
	
	# remove temp pentad files
    /bin/rm $SRC_DIR/temfil.??.nc
	
    @ yr = ($yr + 1) # move year counter ahead 1
end


# echo "Generating one big outfile from yearly files"
# ncrcat -O $SRC_DIR/temyrfil.????.nc $OUTFIL

# echo "Cleaning up"
# /bin/rm temfil.??.nc
# /bin/rm temyrfil.????.nc

echo "Done!"











