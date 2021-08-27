/
* @file intraday_hdb.q
* @overview Define functionalities of Intra-day HDB.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:api/connection_manager_api.q;
.load.load_file `:api/gateway_api.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments. Valid keys are below:
* - user {symbol}: Account name of this process.
\
COMMANDLINE_ARGUMENTS: @[.Q.opt .z.X; `user; {[arg] `$first arg}];
// Set account name.
MY_ACCOUNT_NAME: COMMANDLINE_ARGUMENTS `user;

/
* @brief Channel to produce messages to Intra-day HDB. 
\
LOG_REPLAYER_CHANNEL: `$"intraday_hdb_", string .z.h;

/
* @brief Path to HDB directory.
\
HDB_HOME: hsym `$getenv[`KDB_HDB_HOME];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Reload Intra-day HDB directory and sym file in HDB.
\
load_intraday_HDB:{[]
  .log.info["load Intraday-HDB"; ::];
  system "l ", getenv `KDB_INTRADAY_HDB_HOME;
  // Reload sym file in HDB.
  // HDB can be empty at first.
  sym:: @[get; .Q.dd[HDB_HOME; `sym]; {[error] .log.error[error; ::]}];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Reload Intra-day HDB directory and sym file in HDB. Called by Log Replayer.
\
.logreplay.reload_on_disk_write: load_intraday_HDB;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Log Replayer
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; LOG_REPLAYER_CHANNEL; enlist `all];

// Register as a downstream of Gateway
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; GATEWAY_CHANNEL; enlist `all];

// Register as a downstream of Resource Manager
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; RESOURCE_MANAGER_CHANNEL; enlist `all];

// Load Intra-day HDB directory.
load_intraday_HDB[];
