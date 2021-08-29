/
* @file engine.q
* @overview Define functionalities of Engine.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:api/connection_manager_api.q;
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
* @brief Dummy channel in order to send a message to Tickerplant only.
\
VOID_CHANNEL: `$"_dev_null_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.cmng_api.update: {[table;message]
  if[table ~ `MESSAGE_BOX; detect_abomination[VOID_CHANNEL; message]];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Tickerplant.
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; TICKERPLANT_CHANNEL; COMMANDLINE_ARGUMENTS `topics];

// Register as a publisher.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; VOID_CHANNEL];
