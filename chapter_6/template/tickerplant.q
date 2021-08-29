/
* @file tickerplant.q
* @overview Define functionalities of Tickerplant.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:utility/ping.q;
.load.load_file `:api/connection_manager_api.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments. Valid keys are below:
* - user {symbol}: Account name of this process.
* - t {int}: Interval of the timer. Default value is 0.
\
COMMANDLINE_ARGUMENTS: (@/)[.Q.opt .z.X; `user`t; ({[arg] `$first arg}; {[arg] 0 ^ "I"$first arg})];
// Set account name.
MY_ACCOUNT_NAME: COMMANDLINE_ARGUMENTS `user;

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
LOG_REPLAYER_CHANNEL: `$"log_replayer_", string .z.h;

/
* @brief Channel to subscribe to logfile request from RDB. 
\
LOGFILE_REQUEST_CHANNEL: `$"logfile_request_", string .z.h;

// Load schema file for batch processing and create a buffer for storing tables.
if[COMMANDLINE_ARGUMENTS `t;
  system "l schema/schema.q";
  // @brief Buffer for storing tables.
  // @key list of symbol: Tuple of (table; topic).
  // @value table: Temporary table to store data.
  TABLE_BUFFER: enlist[``]!enlist (::);
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
    .cmng_api.call[; `; `.tickerplant.task_on_rolling_logfile; ACTIVE_LOG; 1b] each (RDB_CHANNEL; LOG_REPLAYER_CHANNEL);
    // Roll out a new log file
    ACTIVE_LOG:: hsym `$(string[`date$NEXT_LOG_ROLL_TIME] except "."), "_", string[`hh$NEXT_LOG_ROLL_TIME], ".log";
    // Update next log roll time
    NEXT_LOG_ROLL_TIME +: 01:00:00;
    .log.info["roll out a new log file"; ACTIVE_LOG];
    // Assured to be a new one
    ACTIVE_LOG set ();
    ACTIVE_LOG_SOCKET:: hopen ACTIVE_LOG
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Write received data to a log file and switch a log file if timestamp of the data passes `NEXT_LOG_ROLL_TIME`.
* @param table {symbol}: Name of a table to update.
* @param data {compound list}: Tuple of (sender time; topic; sender name; data).
\
$[COMMANDLINE_ARGUMENTS `t;
  // Use timer for batch processing
  .cmng_api.update:{[table;data]
    // Check timestamp of data and roll out a new log file if necessary.
    log_roll_check[data];
    // Write the data to the log file
    ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; table; data);
    // Store in a table
    // Get schema if the value has not been initialized by a table
    TABLE_BUFFER[(table; data 1)]: $[() ~ current: TABLE_BUFFER[(table; data 1)]; get[table]; current] upsert data;
  };
  // Non-batch processing
  .cmng_api.update:{[table;data]
    // Check timestamp of data and roll out a new log file if necessary.
    log_roll_check[data];
    // Write the data to the log file
    ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; table; data);
    // Change account name temporarily
    my_account_name: MY_ACCOUNT_NAME;
    MY_ACCOUNT_NAME:: data 2;
    // Send data to RDB
    .cmng_api.publish[RDB_CHANNEL; data 1; table; data 3];
    // Restore account name
    MY_ACCOUNT_NAME:: my_account_name;
  }
 ];

/
* @brief Write a function call to a log file.
* @param time {timestamp}: Time when the function was called on the caller side.
* @param caller {symbol}: Caller of the function.
* @param channel {symbol}: Context channel of the call.
* @param topic {symbol}: Context topic of the call.
* @param function {symbol}: Name of a remote function to call.
* @param arguments {compound list}: Arguments of the function.
\
.cmng_api.log_call:{[time;caller;channel;topic;function;arguments]
  // Check timestamp of data and roll out a new log file if necessary.
  log_roll_check[time];
  // Unify teh type of function name to symbol
  if[10 = type function; function: `$function];
  // Write the data to the log file
  ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; `CALL; (time; caller; channel; topic; function; arguments));
 };

/
* @brief Publish buffered table data by topic and table.
\
.z.ts:{[now]
  {[table_topic; data]
    .cmng_api.call[RDB_CHANNEL; table_topic 1; `.cmng_api.update; table_topic[0], data; 1b];
    // Make table empty
    TABLE_BUFFER[table_topic]: 0#TABLE_BUFFER[table_topic];
  } ./: flip (key; value) @\: TABLE_BUFFER;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Overhear with `system_log` channel.
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; `system_log; enlist `all];

// Register as an upstream of RDB and Log Replayer
.cmng_api.register_as_producer[MY_ACCOUNT_NAME;] each (RDB_CHANNEL; LOG_REPLAYER_CHANNEL);

// Register as a consumer of RDB
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; LOGFILE_REQUEST_CHANNEL; enlist `log_request];

// Start timer
\t COMMANDLINE_ARGUMENTS[`t]
