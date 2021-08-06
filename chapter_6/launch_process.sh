#!/bin/bash

# @file launch_process.sh
# @overview Launch a process with options.

# @param $1 process_type
# @param $2 port
# @param $3 username
# @param $4 
#  - timer: Tickerplant
#  - topics: RDB

if [[ $1 == "connection_manager" ]]; then
  q template/connection_manager.q
elif [[ $1 == "tickerplant" ]]; then
  q template/tickerplant.q -p $2 -user $3 -t $4
elif [[ $1 == "rdb" ]]; then
  q template/rdb.q -p $2 -user $3 -topics $4
elif [[ $1 == "user" ]]; then
  q template/user.q -p $2 -user $3
else
  echo -e "\[\e[32m\]Unknow process type\[\e[0m\]"
  exit 1
fi
