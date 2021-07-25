/
* @file tickerplant.q
* @overview Define functionalities of Tickerplant.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:api/connection_manager_api.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments. Valid keys are below:
* - user {symbol}: Account name of this process.
* - t {int}: Interval of the timer.
\
COMMANDLINE_ARGUMENTS: (@/)[.Q.opt .z.X; `user`t; ({[arg] `$first arg}; {[arg] "I"$first arg})];

/
* @brief Current active tickerplant log file. This value changes every hour.
\
ACTIVE_LOG: hsym `$(string[.z.d] except "."), "_", string[`hh$.z.t], ".log";

/
* @brief Socket to the current active tickerplant log file. This value changes every hour.
\
ACTIVE_LOG_SOCKET: {
  if[() ~ key ACTIVE_LOG;
    // Initialize if the log file does not exist.
    ACTIVE_LOG set ()
  ];
  hopen ACTIVE_LOG
 }[];

/
* @brief Time of the next log rolling. This value changes every hour.
\
NEXT_LOG_ROLL_TIME: 01:00:00 + .z.d+`time$1000*60*60*`hh$.z.t;

/
* @brief Channel to publish data and send a signal to RDB. 
\
RDB_CHANNEL: `$"rdb_", string .z.h;

/
* @brief Channel to send a signal to Log Replayer. 
\
LOG_REPLAYER_CHANNEL: `$"log_replayer_", string .z.h;;

// Load schema file for batch processing and create a buffer for storing tables.
if[COMMANDLINE_ARGUMENTS `t;
  system "l schema.q";
  // @brief Buffer for storing tables.
  // @key list of symbol: Tuple of (table; topic).
  // @value table: Temporary table to store data.
  TABLE_BUFFER: ()!();
 ];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Check timestamp of data and roll out a new log file if the time is over `NEXT_LOG_ROLL_TIME`.
* @param data {compound list}: Tuple of (sender time; topic; sender name; data).
\
log_roll_check:{[data]
  if[NEXT_LOG_ROLL_TIME <= first data;
    // Roll out a new log file
    hclose ACTIVE_LOG_SOCKET;
    // Send a signal to RDB and Log Replayer with the name of the current log file
    .cmng_api.call[; `; `task_at_rolling_logfile; enlist ACTIVE_LOG; 1b] each (RDB_CHANNEL; LOG_REPLAYER_CHANNEL);
    ACTIVE_LOG:: hsym `$(string[`date$NEXT_LOG_ROLL_TIME] except "."), "_", string[`hh$NEXT_LOG_ROLL_TIME], ".log";
    .log.info["roll out a new log file"; ACTIVE_LOG];
    // Assured to be a new one
    ACTIVE_LOG set ();
    ACTIVE_LOG_SOCKET:: hopen ACTIVE_LOG
  ];
 };

/
* @brief Write received data to a log file and switch a log file if timestamp of the data passes `NEXT_LOG_ROLL_TIME`.
* @param table {symbol}: Name of a table to update.
* @param data {compound list}: Tuple of (sender time; topic; sender name; data).
\
$[not null COMMANDLINE_ARGUMENTS `t;
  // Use timer for batch processing
  .cmng_api.update:{[table;data]
    // Check timestamp of data and roll out a new log file if necessary.
    log_roll_check[data];
    // Write the data to the log file
    ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; table; data);
    // Store in a table
    TABLE_BUFFER[(table; data 1)]: TABLE_BUFFER[(table; data 1)] upsert data;
  };
  // Non-batch processing
  .cmng_api.update:{[table;data]
    // Check timestamp of data and roll out a new log file if necessary.
    log_roll_check[data];
    // Write the data to the log file
    ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; table; data);
    // Send data to RDB
    .cmng_api.publish[RDB_CHANNEL; data 1; table; data 3];
  }
 ];

/
* @brief Write a function cal to a log file.
* @param function {symbol}: Name of a remote function to call.
* @param arguments {compound list}: Arguments of the function.
\
.cmng_api.log_call:{[function;arguments]
  // Check timestamp of data and roll out a new log file if necessary.
  log_roll_check[data];
  // Write the data to the log file
  ACTIVE_LOG_SOCKET enlist (`.cmng_api.log_call; function; arguments);
 };

/
* @brief Publish buffered table data by topic and table.
\
.z.ts:{[now]
  {[table_topic; data]
    .cmng_api.call[RDB_CHANNEL; table_topic 1; `.cmng_api.update; table_topic[1], enlist data; 1b];
  } each flip (key; value) @\: TABLE_BUFFER;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Overhear with `system_log` channel.
.cmng_api.register_as_consumer[COMMANDLINE_ARGUMENTS `user; `system_log; enlist `all];

// Register as an upstream of RDB and Log Replayer
.cmng_api.register_as_producer[COMMANDLINE_ARGUMENTS `user;] each (RDB_CHANNEL; LOG_REPLAYER_CHANNEL);
