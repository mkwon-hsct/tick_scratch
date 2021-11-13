#!/bin/sh

# @file launch_process.sh
# @overview Launch a process with options.

# @param $1 process_type
# @param $2 port
# @param $3 username
# @param $4 
# - timer: Tickerplant
# - topics: RDB

## @brief Wrapper to use rlwrap.
function launch(){
  ## process_yyyymmdd_HHMMSSNNNNNNNNN.log
  local LOGFILE=`echo $1 | sed 's/template/log/g' | tr -d .q`;
  LOGFILE="${LOGFILE}_`date +%Y%m%d_%H%M%S%N`.log";
  ## Run on the background
  nohup q $@ < /dev/null >> ${LOGFILE} 2>&1 &
}

## Load `.env`
source config/.env

## Launch Process
case "$1" in
  connection_manager)
    launch template/${1}.q ;;
  tickerplant)
    launch template/${1}.q -p $2 -user $3 -t $4 ;;
  rdb | engine)
    launch template/${1}.q -p $2 -user $3 -topics $4 ;;
  hdb | intraday_hdb | gateway | log_replayer | resource_manager | user)
    launch template/${1}.q -p $2 -user $3 ;;
  *)
    echo -e "\e[31mUnknown process type: ${1}\e[0m"
    exit 1 ;;
esac
