#!/bin/sh

# @file terminate_process.sh
# @overview Terminate a process.

# @param $1 process_type

## Get process ID
PROCESS_ID=`ps x | awk -v "process_type=${1}" '{
  if($6 ~ process_type){
    print $1
  }
}'`;

## Terminate
if [ "${PROCESS_ID}" != "" ]; then
  kill ${PROCESS_ID};
fi
