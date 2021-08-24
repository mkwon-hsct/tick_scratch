#!/bin/bash

## @file tick_controller.sh
## @overview Start/stop tick architecture based on configuration.

## @param $1 operation: "start" or "stop".

## @brief Configuration of tick architecture.
CONFIG=config/tick_architecture.config;

## @brief Parse a line of the tick configuration and build a command to luanch the process.
## @param $1 line: Line of the tick configuration file delimited by ";".
function launch(){
  ## Build a launch command
  LAUNCH_COMMAND=$(echo $1 | awk '
    BEGIN{
      COMMAND="./launch_process.sh ";
    }
    {
      SIZE=split($0, line, ";");
      for(i-1; i<=SIZE; ++i){
        COMMAND=COMMAND line[i] " ";
      }
    }
    END{
      print(COMMAND);
    }'
  );
  ## Execute the command
  ${LAUNCH_COMMAND}
}

## @brief Parse a line of the tick configuration and launch the process.
## @param $1 line: Line of the tick configuration file delimited by ";".
function terminate(){
  ## Get process type
  PROCESS_TYPE=$(echo $1 | awk -F";" '{print $1}');
  ## Get process ID
  PROCESS_ID=$(ps x | awk -v "process_type=${PROCESS_TYPE}" '{
    if($6 ~ process_type){
      print $1
    }
  }');
  ## Terminate
  if [[ ${PROCESS_ID} != "" ]]; then
    kill ${PROCESS_ID};
  fi
}

## Launch or terminate processes.
if [[ $1 == "start" ]]; then
  while read line
  do
    ## Launch process
    launch $line;
    ## Wait until process becomes ready
    if [[ $(echo $line | awk -F";" '{print $1}') == "tickerplant" ]]; then
      TARGET_PORT=$(echo $line | awk -F";" '{print $2}');
      RESPONSE=$(curl http://127.0.0.1:${TARGET_PORT}/ping);
      while [[ ${RESPONSE} != "alive" ]]
      do
        RESPONSE=$(curl http://127.0.0.1:${TARGET_PORT}/ping);
        sleep "1";
      done
    else
      sleep "0.1";
    fi
  done < $CONFIG
elif [[ $1 == "stop" ]]; then
  tac $CONFIG | while read line
  do
    ## Terminate process
    terminate $line;
    sleep "0.1";
  done
else
  echo -e "\[\e[32m\]Unknown operation: $1\[\e[m\]";
fi
