/
* @file rdb.q
* @overview Define functionalities of RDB.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l schema.q
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
COMMANDLINE_ARGUMENTS: (@/)[.Q.opt .z.X; `user; {[arg] `$first arg}];

/
* @brief Channel to subscribe to tickerplant. 
\
RDB_CHANNEL: `$"rdb_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.cmng_api.update:{[table;data]
   table insert data;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Tickerplant
.cmng_api.register_as_consumer[COMMANDLINE_ARGUMENTS `user; RDB_CHANNEL; enlist `all];

// Register as a producer of RDB channel.
.cmng_api.register_as_producer[COMMANDLINE_ARGUMENTS `user; RDB_CHANNEL];

// Get a current log file.
ACTIVE_LOG: first .cmng_api.call[RDB_CHANNEL; `request; "get"; `ACTIVE_LOG; 0b];

// Replay the log file
-11!ACTIVE_LOG;
