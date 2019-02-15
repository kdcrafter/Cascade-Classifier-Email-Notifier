#!/bin/bash

#check args
if [ $# -lt 2 ];then
        echo "Usage: $0 <email> <model name>"
        exit 1
fi

#set up and constants
NOTHING_DONE_LIMIT=288 #= 86400/300 = 24 hours / 5 mins
SLEEP_TIME=300 #seconds / 1 min
EMAIL=$1
MODEL_NAME=$2
OUTPUT_FILE=$MODEL_NAME/$MODEL_NAME.txt
mkdir $MODEL_NAME
touch $OUTPUT_FILE

#run the cascade classifier training program
nohup opencv_haartraining -data $MODEL_NAME -vec data.vec -bg negative.txt -npos 2500
0 -nneg 7500 -nstages 25 -mem 512 -mode BASIC -bt GAB > $OUTPUT_FILE 2>&1 &
PID=$!

#monitor while opencv_haartraining is alive
elapsedSeconds=0
status=0 #default 0
prevOutputLines=$(wc -l $OUTPUT_FILE | cut -f1 -d ' ')
nothingDoneCount=0

while [ -n "$(ls /proc/$PID)" ]
do
        sleep $SLEEP_TIME
        let elapsedSeconds+=SLEEP_TIME

        #check if done nothing in 24 hours
        let currOutputLines=$(wc -l $OUTPUT_FILE | cut -f1 -d ' ')
        if [ "$prevOutputLines" -eq "$currOutputLines" ];then
                let nothingDoneCount+=1
        else
                let nothingDoneCount=0
        fi
        let prevOutputLines=currOutputLines

        if [ "$nothingDoneCount" -ge "$NOTHING_DONE_LIMIT" ];then
                let status=1
                break
        fi
done

#send email
printf "The current cascade classifier model is complete\n" > message
elapsedHours=$(echo "scale=4; $elapsedSeconds / 3600" | bc)
printf "Time elapsed: $elapsedSeconds seconds, $elapsedHours hours\n" >> message

printf "Status: " >> message
if [ $status -eq 1 ];then
        printf "The model has not accomplished anything in the last 24 hours\n" >> message
else
        echo "The model has been completed successfully\n" >> message
fi

mailx -s "Cascade Classifier Model $MODEL_NAME" $EMAIL < message
rm message

exit 0
