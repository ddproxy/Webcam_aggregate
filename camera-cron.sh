#!/bin/bash
DIR=~/camera
BACKUPDIR=~/camera-bk2
BACKUP=$BACKUPDIR/camera-$(date --date '100 minutes' +%Y-%m-%d-%H-%M)
FILENAME=camera-$(date --date '100 minutes' +%Y-%m-%d-%H-%M).mp4
DATE=$BACKUP/$FILENAME
DIRSTR=/camera-$(date --date '100 minutes' +%Y-%m-%d-%H-%M)/
DATESTR=$(date --date '100 minutes' +%m-%d-%Y)
TIMESTR=$(date --date '100 minutes' +%H:%M)

ftp -inv <<EOJ>> ~/cameralog
open ftp.ipage.com
user User Password,
cd /camera
asc
dir * ~/camera.lst
quit
EOJ

rm /home/k9karma/batch.out

echo "Appending to batch.out"
echo "open ftp.ipage.com" >> ~/batch.out
echo "user k9karma_ftp Theta5g6," >> ~/batch.out
echo "cd /camera" >> ~/batch.out
echo "lcd /home/k9karma/camera/" >> ~/batch.out
echo "Should be in Camera"

awk '{print $NF}' ~/camera.lst | while read file; do
echo "get $file" >> ~/batch.out
echo "del $file" >> ~/batch.out
done
echo "bye" >> ~/batch.out
rm ~/camera.lst
ftp -inv < ~/batch.out >> ~/cameralog
echo "Should be done"


echo "This scripts checks the existence of new files."
echo "Checking..."

echo "...done."

     echo "Files found, creating backup and transfering files..."

     mkdir $BACKUP
     echo "Made $BACKUP"
     mv ~/camera-cache/*.jpg $BACKUP


     echo "Done..."
     find $DIR -name "*.jpg" -exec mv {} ~/camera-cache \;
     echo "Files moved, waiting..."
     wait ${!}
     echo "Renaming all *.jpg's to xxxx.jpg"
     cd ~/camera-cache
     i=1
     for file in *.jpg
       do
        j=$( printf "%08d" "$i" )
        mv "$file" "$j.jpg"
        (( i++ ))
     done
     echo "Done..."

     wait ${!}


if [ -f 00000001.jpg ]
	then
	echo "Moving current.mp4 to back-up folder..."
	mv ~/camera-cache/current.mp4 $DATE
	mv ~/camera-cache/current.flv $DATE
	echo "Executing the following query"
	echo "INSERT INTO files(date, time,url,dir) VALUES ('$DATESTR','$TIMESTR','$FILENAME','$DIRSTR')"

	mysql -u user -password -h mysql.domain.com <<eof
	use table;
	INSERT INTO files(date, time,url,dir) VALUES ('$DATESTR','$TIMESTR','$FILENAME','$DIRSTR');
eof
fi


     echo "Done..."
     wait ${!}
     echo "Running ffmpeg to generate current.mp4"
     ffmpeg -r 5 -b 120k -i %08d.jpg current.mp4
     echo "Done..."
     echo "Checking current's exist"
		if [ -f current.mp4 ]
			then
			echo "Deleting jpgs"
			rm *.jpg
		fi
     cd $BACKUPDIR

echo "Checking for current.mp4 in cache"

if [ -f ~/camera-cache/current.mp4 ]
   then
     echo "File exists, doing nothing..."
   else
     echo "File does not exist, OOPS! Notifying Administrator!"
     ls -a
#requires: date,sendmail
function fappend {
    echo "$2">>$1;
}
YYYYMMDD=`date +%Y%m%d`

# CHANGE THESE
TOEMAIL="someone@gmail.com";
FREMAIL="crondaemon@domain.com";
SUBJECT="Camera! Emergency!";
MSGBODY="There is an emergency on the Camera! Need to make sure the current feed is available!";

# DON'T CHANGE ANYTHING BELOW
TMP="/tmp/tmpfil_123"$RANDOM;

rm -rf $TMP;
fappend $TMP "From: $FREMAIL";
fappend $TMP "To: $TOEMAIL";
fappend $TMP "Reply-To: $FREMAIL";
fappend $TMP "Subject: $SUBJECT";
fappend $TMP "";
fappend $TMP "$MSGBODY";
fappend $TMP "";
fappend $TMP "";
cat $TMP|/usr/sbin/sendmail -t;
rm $TMP;
fi
