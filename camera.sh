#!/bin/bash
# Record web-camera streams to server

# Camera, Version 1

function commands {
	echo "Usage: `basename $0` stream-url camera-name";
}

# Run as root

LOG_DIR=~/camera/log
ROOT_UID=0
E_XCD=86
E_NOTROOT=87

# Database Function

TABLE=camera
SQLUSER=root
SQLPASS=password
function db {
	echo "DB"
		SQLSTATEMENT='use ' $TABLE '; INSERT INTO files(date, dir, camera) VALUES ('$1','$2','$3');'
		mysql -u $SQLUSER -$SQLPASS -h localhost $SQLSTATEMENT
}

#if [ "$UID" -ne "$ROOT_UID" ]
#then
#  echo "Must be root to run this script."
#  exit $E_NOTROOT
#fi

case "$1" in
""	) commands ; echo "Missing stream-url"; exit 0;;
*	) STREAM=$1;;
esac
case "$2" in
""	) commands ; echo "Missing camera-name"; exit 0;;
*	) CAMERA=$2;;
esac


DATE=`date +%s`
TIMESTAMP=`date +%Y-%m-%d-%H-%M`
DIR="~/camera/video/"$CAMERA"/"
DIR+=`date +%Y/%m/%d`
FILE=`date +%H%M`


cd $LOG_DIR || {
  echo "Cannot change to necessary directory. " >&2
  exit $E_XCD;
}

touch $CAMERA
echo -e ${TIMESTAMP}" -- Camera recording started.\n"  >> $CAMERA

mkdir -p ~/camera/video/$CAMERA/$DIR

cd $DIR
ffmpeg -i $STREAM -r 25 -bf 2 -ar 22050 -copyright "K9 Karma" -timelimit 120 "$FILE".mpg 2>> $LOG_DIR/$CAMERA &
db $DATE $DIR $CAMERA
#sleep 1m
#kill &
exit 0
