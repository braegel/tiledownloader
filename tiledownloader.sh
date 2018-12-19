#!/bin/sh


ZOOM=$1
ARGLAT=$2
ARGLONG=$3
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
	FILENAME="$ZOOM-$Y-$X.png"
	if [ ! -f "tile_cache/$FILENAME" ]; then
	    #	    URL="http://abo.wanderreitkarte.de/php/abosrv.php?url=/$ZOOM/$X/$Y.png&ticket=$APIKEY"
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
	    echo " out=$FILENAME" >> url_cache
	else
	    echo "$FILENAME exists"
	fi
	DONE=$(($DONE+1))
	echo "$DONE/$TILES"
    done
done
#rm "out/out_z${Z}_${X1}_${Y1}-${X2}_${Y2}.png"
aria2c -d tile_cache -i url_cache -j 3
#montage -mode concatenate -tile "$((Xmax-Xmin+1))x" "tile_cache/*.png" "out/$ZOOM-$TILE_X-$TILE_Y.png"
montage -mode concatenate "tile_cache/*.png" "out/$ZOOM-$TILE_X-$TILE_Y.png"
