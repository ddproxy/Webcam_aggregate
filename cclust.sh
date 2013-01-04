#!/bin/bash
# Starts camera.sh scripts
# Manages Backups, Database and Archiving

DIR=~/cgi-bin
LOG_DIR=~/log
ROOT_UID=0
E_XCD=86
E_NOTROOT=87
TIMESTAMP=`date +%Y-%m-%d-%I-%M`
SQLUSER=root
SQLPASS=password
touch $LOG_DIR/cluster

# Functions

function log {
	touch $LOG_DIR/cluster
	echo -e ${TIMESTAMP}" -- "$1 >> $LOG_DIR/cluster
}

function process {
echo $1
while read line; do
	log "$line" 
	camera $line &
done< $1 
}

# Commands

function commands {
	echo -e "\e[0;31mUsage: `basename $0` {options -adh -t <date> -f <lst> -u <url> -n <name> -z  <archive>}\e[00m

By default, `basename $0` will use local directory camera.lst file for cameras.

Log file exists at $LOG_DIR

camera.lst format --
stream-url camera-name

Example:
http://192.168.1.2/img/video.asf test

Uses camera.sh script to record streams. Streams are recorded in ~/video/

OPTIONS::
	-h help -- this document

	-a add  -- Use with -u,-n to add cameras to the list

	-d delete -- Use with -n to remove cameras to the list

	-l list -- Return a list of cameras saved to camera.lst

	-f      -- Process a different camera.lst

	-u url  -- Url to process - use with -n

	-n name -- Name of camera to process - use wuth -u

	-r retrieve -- Use in conunction with -z to retrieve an archived file


	-z archive -- Use in conjunction with -n to designate the camera

	"
}

# Camera

function camera {
	LOG="Calling camera "$2" at "$1
	log "$LOG"
	echo $LOG
	~/cgi-bin/camera.sh $1 $2
}

# Backup

function backup {
	echo "Backup"
}

# Database

function db {
	echo "DB"
		mysql -u $SQLUSER -$SQLPASS -h localhost <<eof
	use table;
	INSERT INTO files(date, dir, camera) VALUES ('$1','$2','$3');
eof
}

# Archive

function archive {
	echo "Archive"
	if [ "$NAME" != '' ]
	then
		echo "Yesterday"
		mkdir -p ~/video/archive/$NAME
		tar --remove-files -zcPf ~/video/archive/$NAME/`date -d "-1 day" +%Y-%m-%d`.tar.gz ~/video/$NAME/`date -d "-1 day"  +%Y/%m/%d`/ 2>&1 | log 

	fi
}

while getopts ":hlrad:f:u:n:z" optname
  do
	case $optname in
	  h)
		commands >&2
	  ;;
	  l)
		echo -e "\e[0;31mCameras saved to $DIR/camera.lst\e[0m\n"
		cat $DIR/camera.lst
		echo ""
	  ;;
	  f)
		process $OPTARG >&2
	  ;;
	  u)
		URL=$OPTARG
	  ;;
	  n)
		NAME=$OPTARG
	  ;;
	  a)
		ADD=true >&2
	  ;;
	  d)
		DELETE=true >&2
	  ;;
	  z)
		archive >&2
	  ;;
	  :)
		echo "No argument value for option $OPTARG" >&2
	  ;;
	  \?)
		echo "Unknown Error while processing options."
	  ;;
	esac
	PROCESS=false
  done

if [ "$ADD" == "true" ]
then
	echo "Adding $URL $NAME"
	echo "$URL $NAME" >> camera.lst
else
	if [ "$DELETE" == "true" ]
	then
		echo "Deleting $URL $NAME"
		sed -e "s/$URL $NAME//d" -i camera.lst
	fi
	if [ "$NAME" != "" ]
	then
	  if [ "$URL" != "" ]
	  then
		camera $URL $NAME
	  fi
	fi
fi
if [ "$PROCESS" != 'false' ]
then
	process $DIR/camera.lst
fi

exit 0
