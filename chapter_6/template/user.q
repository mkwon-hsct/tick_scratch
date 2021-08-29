/
* @file user.q
* @overview Define functionalities of chat user.
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
\
COMMANDLINE_ARGUMENTS: @[.Q.opt .z.X; `user; {[arg] `$first arg}];
// Set account name.
MY_ACCOUNT_NAME: COMMANDLINE_ARGUMENTS `user;

/
* @brief Channel to send a query to Gateway.
\
GATEWAY_CHANNEL: `$"user_query_", string .z.h;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.cmng_api.update: {[table;message]
  table insert (.z.p; message 1; message 2; message 3);
 };

/
* @brief Search messages with topics, time range and some conditions.
* @param topics {list of symbol}: Topics to find a message.
* @param time_range {list of timestamp}: Queried range.
* @param option {dictionary}: Valid keys are below:
* - group {dictionary}: Map from aggregate name and column name. Optional.
* - columns {list of symbol}: Columns to select. Optional.
* - keyword {string}: Pattern of a message to search. Optional.
* - sender {symbol}: Sender of a message to search. Optional.
* @return
* - table: Merged table.
\
//
search_message: {[topics;time_range;options]
  // Table is fixed as `MESSAGE_BOX`
  options: (``table!(::; `MESSAGE_BOX)), options;
  // Select all columns by default
  if[not `columns in key options; options[`columns]:()];
  // Does not group by default
  if[not `grouping in key options; options[`grouping]: 0b];
  raze .cmng_api.call[GATEWAY_CHANNEL; `query; `.gateway.query; (time_range; topics; `history; options; {[results] delete int, date from (uj/) results}); 0b]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

.cmng_api.register_as_producer[MY_ACCOUNT_NAME; GATEWAY_CHANNEL];
