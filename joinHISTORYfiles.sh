#!/bin/bash
log_it()
{
  printf "%s - %s\n" "`date +"%Y-%m-%d %H:%M:%S"`" "$*" >> $LOGFILE 2>&1;
}
LOGFILE="/home/master/brt_tracking/brt_tracking.log"
cd /home/master/brt_tracking

if [  $# -lt 1  ]; then
	DAYS=0
else
	DAYS=$1
fi 

DATA=$(date +"%d %B %Y" -d "$DAYS days ago")

log_it "Data di acquisizione esiti: $DATA "

#rm -f BRT_VAB.csv BRT_VAC.csv

#php -f test_imap.php "$DATA" >> $LOGFILE 2>&1

for vab in *FNVAB*
do 
	#echo $vab
	filename=`basename $vab`
	fileext=${filename##*.}
	if [ "$fileext" == "ZIP" ]; then
		unzip -po $vab | awk -F";" '$1!="\"VABATB\""' | cat >> BRT_VAB.csv
		log_it "LAVORATO VAB ZIP: " $(zcat $vab | wc -l)
	else
		awk -F";" '$1!="\"VABATB\""' $vab >> BRT_VAB.csv
		log_it "LAVORATO VAB CSV: "$(wc -l $vab)
	fi
	mv $vab brt_loaded/.
done

for vac in *FNVAC*
do 
	filename=`basename $vac`
	fileext=${filename##*.}
	#echo $filename "-" $fileext
	if [ "$fileext" == "ZIP" ]; then
		unzip -po $vac | awk -F";" '$1!="\"VACAAS\""' | cat >> BRT_VAC.csv
		log_it "LAVORATO VAC ZIP: " $(zcat $vac | wc -l)
	else
		awk -F";" '$1!="\"VACAAS\""'  $vac >> BRT_VAC.csv
		log_it "LAVORATO VAC CSV: "$(wc -l $vac)
	fi
	mv $vac brt_loaded/.
done

mysql -umy_remote -pdb2012 minimegaprint_db --execute="LOAD DATA INFILE '/home/master/brt_tracking/BRT_VAB.csv' INTO TABLE BRT_VAB FIELDS TERMINATED BY ';' ENCLOSED BY '\"' LINES TERMINATED BY '\r\n'; SHOW WARNINGS"  >> $LOGFILE 2>&1
#mysqlimport -v -umy_remote -pdb2012 --local --fields-terminated-by=';' --fields-enclosed-by='"' --lines-terminated-by='\n' minimegaprint_db BRT_VAC.csv
mysql -umy_remote -pdb2012 minimegaprint_db --execute="LOAD DATA INFILE '/home/master/brt_tracking/BRT_VAC.csv' INTO TABLE BRT_VAC FIELDS TERMINATED BY ';' ENCLOSED BY '\"' LINES TERMINATED BY '\r\n'; SHOW WARNINGS" >> $LOGFILE 2>&1

