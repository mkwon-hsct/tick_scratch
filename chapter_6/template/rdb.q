/
* @file rdb.q
* @overview Define functionalities of RDB.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Load schema
\l schema/schema.q
\l utility/load.q
.load.load_file `:api/connection_manager_api.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments. Valid keys are below:
* - user {symbol}: Account name of this process.
* - topics {list of symbol}: List of topics to subscribe.
\
COMMANDLINE_ARGUMENTS: (@/)[.Q.opt .z.X; `user`topics; ({[arg] `$first arg}; {[topics] `$"," vs first topics})];
// Set account name.
MY_ACCOUNT_NAME: COMMANDLINE_ARGUMENTS `user;

/
* @brief Channel to subscribe to Tickerplant. 
\
TICKERPLANT_CHANNEL: `$"rdb_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Insert a record to a table.
* @param table {symbol}: name of a table.
* @param data {variable}:
*  - compound list: Single record.
*  - table: Bunch of records. 
\
.cmng_api.update:{[table;data]
   table insert data;
 };

/
* @brief Delete data in tables at the rolling of log file.
* @param logfile_ {symbol}: Handle to the log file cut off by the tickerplant. Not used on RDB side.
\
task_at_rolling_logfile:{[logfile_]
  {[table]
    .log.info["delete data from table"; table];
    delete from table;
  } each TABLES_IN_DB;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Tickerplant
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; TICKERPLANT_CHANNEL; COMMANDLINE_ARGUMENTS `topics];

// Register as a producer of RDB channel.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; TICKERPLANT_CHANNEL];

// Get a current log file.
ACTIVE_LOG: first .cmng_api.call[TICKERPLANT_CHANNEL; `log_request; "get"; `ACTIVE_LOG; 0b];

// Replay the log file
.log.info["replay a log file"; ACTIVE_LOG];
-11!ACTIVE_LOG;
