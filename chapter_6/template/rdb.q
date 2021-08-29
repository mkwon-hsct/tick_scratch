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
.load.load_file `:api/gateway_api.q;
.load.load_file `:utility/analytics.q;

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

/
* @brief Channel to produce logfile request to Tickerplant. 
\
LOGFILE_REQUEST_CHANNEL: `$"logfile_request_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Add grouping attribute to a table.
* @param table {symbol}: Table name.
\
add_grouping_attribute:{[table]
  grouping_column: TABLE_SORT_KEY table;
  ![table; (); 0b; enlist[grouping_column]!enlist (`g#; grouping_column)];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Insert a record to a table.
* @param table {symbol}: name of a table.
* @param data {variable}:
*  - compound list: Single record.
*  - table: Bunch of records. 
\
.cmng_api.update:{[table;data]
  $[table ~ `ALERT;
    // ALert data. Ignore the information appended by Tickerplant.
    table insert last data;
    table insert data
  ];
 };

/
* @brief Delete data in tables at the rolling of log file.
* @param logfile_ {symbol}: Handle to the log file cut off by the tickerplant. Not used on RDB side.
\
.tickerplant.task_on_rolling_logfile:{[logfile_]
  {[table]
    // Make the table empty.
    .log.info["delete data from table"; table];
    delete from table;
    // Assign grouping attribute again.
    add_grouping_attribute table;
  } each TABLES_IN_DB;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Add grouping attribute to tables
add_grouping_attribute each TABLES_IN_DB;

// Register as a downstream of Tickerplant
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; TICKERPLANT_CHANNEL; COMMANDLINE_ARGUMENTS `topics];

// Register as a producer of logfile request channel.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; LOGFILE_REQUEST_CHANNEL];

// Get a current log file.
ACTIVE_LOG: first .cmng_api.call[LOGFILE_REQUEST_CHANNEL; `log_request; "get"; `ACTIVE_LOG; 0b];

// Replay the log file
.log.info["replay a log file"; ACTIVE_LOG];
// Filter
.z.ps:{[message]
  // Execute messages with topics to which this process is subscribing
  if[(COMMANDLINE_ARGUMENTS[`topics] ~ enlist `all) or any COMMANDLINE_ARGUMENTS[`topics] in last message;
    value message
  ];
 };
// Replay
-11!ACTIVE_LOG;
// Discard the filter
\x .z.ps

// Register as a downstream of Gateway
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; GATEWAY_CHANNEL; COMMANDLINE_ARGUMENTS `topics];

// Register as a downstream of Resource Manager
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; RESOURCE_MANAGER_CHANNEL; COMMANDLINE_ARGUMENTS `topics];

// Register as a producer of Resource Manager.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; DATABASE_RETURN_CHANNEL];
if[count sockets: exec sockets from CONSUMER_FILTERS where channel = DATABASE_RETURN_CHANNEL;
  .cmng_api.call[DATABASE_RETURN_CHANNEL; `return; `.rscmng.return; (.z.h; "I"$first COMMANDLINE_ARGUMENTS `p; GATEWAY_CHANNEL); 1b]
 ];
