/
* @file hdb.q
* @overview Define functionalities of HDB.
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
LOG_REPLAYER_CHANNEL: `$"hdb_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Reload HDB directory.
\
load_HDB:{[]
  .log.info["load HDB"; ::];
  system "l ", getenv `KDB_HDB_HOME;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Reload HDB directory. Called by Log Replayer.
\
.logreplay.reload_on_disk_write: load_HDB;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Log Replayer
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; LOG_REPLAYER_CHANNEL; enlist `all];

// Load HDB directory.
load_HDB[];

// Register as a downstream of Gateway
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; GATEWAY_CHANNEL; enlist `all];

// Register as a downstream of Resource Manager
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; RESOURCE_MANAGER_CHANNEL; enlist `all];

// Register as a producer of Resource Manager.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; DATABASE_RETURN_CHANNEL];
if[count sockets: exec sockets from CONSUMER_FILTERS where channel = DATABASE_RETURN_CHANNEL;
  .cmng_api.call[DATABASE_RETURN_CHANNEL; `return; `.rscmng.return; (.z.h; "I"$first COMMANDLINE_ARGUMENTS `p; GATEWAY_CHANNEL); 1b]
 ];
