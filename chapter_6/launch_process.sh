#!/bin/bash

# @file launch_process.sh
# @overview Launch a process with options.

# @param $1 process_type
# @param $2 port
# @param $3 username
# @param $4 
#  - timer: Tickerplant
#  - topics: RDB

## @brief Wrapper to use rlwrap.
function launch(){
  rlwrap q $@
}

## Load `.env`
source config/.env

## Launch Process
if [[ $1 == "connection_manager" ]]; then
  launch template/connection_manager.q
elif [[ $1 == "tickerplant" ]]; then
  launch template/tickerplant.q -p $2 -user $3 -t $4
elif [[ $1 == "rdb" ]]; then
  launch template/rdb.q -p $2 -user $3 -topics $4
elif [[ $1 == "log_replayer" ]]; then
  launch template/log_replayer.q -p $2 -user $3
elif [[ $1 == "user" ]]; then
  launch template/user.q -p $2 -user $3
else
  echo -e "\[\e[32m\]Unknown process type\[\e[0m\]"
  exit 1
fi
