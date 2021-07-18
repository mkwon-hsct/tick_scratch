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
\
COMMANDLINE_ARGUMENTS: (@/)[.Q.opt .z.X; enlist `user; enlist {[arg] `$first arg}];

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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Write received data to a log file and switch a log file if timestamp of the data passes `NEXT_LOG_ROLL_TIME`.
* @param table {symbol}: Name of a table to update.
* @param data {compound list}: Tuple of (sender time; topic; sender name; data).
\
.cmng_api.update:{[table;data]
  // Check timestamp of data
  if[NEXT_LOG_ROLL_TIME <= first data;
    // Roll out a new log file
    hclose ACTIVE_LOG_SOCKET;
    ACTIVE_LOG:: hsym `$(string[`date$NEXT_LOG_ROLL_TIME] except "."), "_", string[`hh$NEXT_LOG_ROLL_TIME], ".log";
    // Assured to be a new one
    ACTIVE_LOG set ();
    ACTIVE_LOG_SOCKET:: hopen ACTIVE_LOG
  ];
  // Write the data to teh log file
  ACTIVE_LOG_SOCKET enlist (`.cmng_api.update; table; data);

 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Overhear with `system_log` channel.
.cmng_api.register_as_consumer[COMMANDLINE_ARGUMENTS `user; `system_log; enlist `all];
