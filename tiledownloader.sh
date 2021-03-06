#!/bin/bash


ZOOM=$1
SCALE=$2
ARGLAT=$3
ARGLONG=$4
#CONFIGFILE=$6
#source $CONFIGFILE


long2xtile()  
{ 
    long=$1
    zoom=$2
    echo "${long} ${zoom}" | awk '{ xtile = ($1 + 180.0) / 360 * 2.0^$2; 
  xtile+=xtile<0?-0.5:0.5;
  printf("%d", xtile ) }'
}

lat2ytile() 
{ 
    lat=$1;
    zoom=$2;
    tms=$3;
    ytile=`echo "${lat} ${zoom}" | awk -v PI=3.14159265358979323846 '{ 
   tan_x=sin($1 * PI / 180.0)/cos($1 * PI / 180.0);
   ytile = (1 - log(tan_x + 1/cos($1 * PI/ 180))/PI)/2 * 2.0^$2; 
   ytile+=ytile<0?-0.5:0.5;
   printf("%d", ytile ) }'`;
    if [ ! -z "${tms}" ]
    then
	#  from oms_numbering into tms_numbering
	ytile=`echo "${ytile}" ${zoom} | awk '{printf("%d\n",((2.0^$2)-1)-$1)}'`;
    fi
    echo "${ytile}";
}


TMS="";


TILE_X=$( long2xtile ${ARGLONG} ${ZOOM} );
TILE_Y=$( lat2ytile ${ARGLAT} ${ZOOM} ${TMS} );
echo "Center TILE $TILE_X/$TILE_Y"

Xmax=$((TILE_X+5))
Xmin=$((TILE_X-5))
Ymax=$((TILE_Y+5))
Ymin=$((TILE_Y-5))

TILES=$((($Xmax-$Xmin+1)*($Ymax-$Ymin+1)))

echo "Deleting cache" # tode

rm -rf tile_cache
mkdir tile_cache
rm url_cache

echo "Download $TILES tiles"
for X in $(seq $Xmin $Xmax);
do
    for Y in $(seq $Ymin $Ymax);
    do
	FILENAME="$ZOOM-$Y-$X"
	if [ ! -f "tile_cache/$FILENAME.png" ]; then

	    #wanderreitkarte
	    # source apikey
	    # URL="http://abo.wanderreitkarte.de/php/abosrv.php?url=/$ZOOM/$X/$Y.png&ticket=$APIKEY"

	    #opentopomap
	    #randomize server
	    RND=$(shuf -i 1-3 -n 1)
	    if ((RND==1)); then
	    	SERVER='a'
	    fi
	    if ((RND==2)); then
	    	SERVER='b'
	    fi
	    if ((RND==3)); then
	    	SERVER='c'
	    fi
	    URL="https://$SERVER.tile.opentopomap.org/$ZOOM/$X/$Y.png"
	    echo "$URL" >> url_cache
	    echo " out=$FILENAME.png" >> url_cache
	else
	    echo "$FILENAME.png exists"
	fi
	DONE=$(($DONE+1))
	echo "$DONE/$TILES"
    done
done
#rm "out/out_z${Z}_${X1}_${Y1}-${X2}_${Y2}.png"
aria2c -d tile_cache -i url_cache -j 3

if [ ! -d "out" ]; then
    mkdir out
fi

echo "Concatenating tiles"
montage -mode concatenate -tile "$((Xmax-Xmin+1))x" "tile_cache/*.png" "out/$ZOOM-$TILE_X-$TILE_Y.png"
#montage -mode concatenate "tile_cache/*.png" "out/$ZOOM-$TILE_X-$TILE_Y.png"

# m / pixel conversion factors from
# https://wiki.openstreetmap.org/wiki/Zoom_levels
case $ZOOM in
    0)
	CONV=156 412
	;;
    1)
	CONV=78 206
	;;
    2)
	CONV=39 103
	;;
    3)
	CONV=19 551
	;;
    4)
	CONV=9 776
	;;
    5)
	CONV=4 888
	;;
    6)
	CONV=2 444
	;;
    7)
	CONV=1 222
	;;
    8)
	CONV=610.984
	;;
    9)
	CONV=305.492
	;;
    10)
	CONV=152.746
	;;
    11)
	CONV=76.373
	;;
    12)
	CONV=38.187
	;;
    13)
	CONV=19.093
	;;
    14)
	CONV=9.547
	;;
    15)
	CONV=4.773
	;;
    16)
	CONV=2.387
	;;
    17)
	CONV=1.193
	;;
    18)
	CONV=0.596
	;;
    19)
	CONV=0.298
	;;
esac


# 4*a(1) = pi
# 39.37 conversion m = inch
DPI=`echo "$SCALE/($ARGLAT*(4*a(1)/180)*$CONV*39.37)" | bc -l`
echo "Convert out/$ZOOM-$TILE_X-$TILE_Y.png to PDF 1:$SCALE ($DPI px/inch)"
convert -density "$DPI" "out/$ZOOM-$TILE_X-$TILE_Y.png" "out/$ZOOM-$TILE_X-$TILE_Y.pdf"
