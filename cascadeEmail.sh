#!/bin/bash

#user runs opencv_haartraing before this one

#TODO: put output in logfile, account for &
#TODO: recored nohup output
#TODO: deal with errors

#check args
if [ $# -lt 1 ];then
        echo "Usage: $0 <email>"
        exit 1
fi

#check if nohup was used
if [ ! -f ./nohup.out ];then
        echo "Error: nohup.out does not exist"
        exit 1
fi

#get PID
PID=$(ps -u $USER | grep "opencv_haartrai" | awk '{print $1}')

#check if opencv_haartraining is currently running
if [ -z $PID ];then
        echo "Error: opencv_haartraining is not running"
        exit 1
fi

#monitor while opencv_haartraining is alive
timeElasped=0 #seconds
sleepTime=1 #300 seconds
status=0 #default 0
prevNohupLines=$(wc -l ./nohup.out)
nothingDoneCount=0

while [ -n "$(ls /proc/$PID)" ]
do
        sleep $sleepTime
        let timeElapsed+=sleepTime
        echo "Time Elapsed: $timeElapsed"

        #check if done nothing in 24 hours
        currNohupLines=$(wc -l ./nohup.out)
        if [ "$prevNohupLines" -eq "$currNohupLines" ];then
                let nothingDoneCount+=1
        else
                let nothingDoneCount=0
        fi
        let prevNohupLines=currNohupLines

        echo "Nothing Done Count: $nothingDoneCount"

        if [ $doNothingCount -gt 10 ];then #288 = 86400/300 = 24 hours / 5 minutes
                let status=1
                break
        fi
done

#send email
echo "The current cascade classifier model is complete" > message
echo >> message
echo "TIME_ELAPSED: $timeElapsed" >> message
echo >> message

echo "Status: " >> message
if [ $status -eq 1 ];then
        echo "the model has not accomplished anything in the last 24 hours\n" >> message
else
        echo "the model has been completed successfully\n" >> message
fi
echo >> message

mailx -s "Cascade Classifier Model" $1 < message
rm message

exit 0

