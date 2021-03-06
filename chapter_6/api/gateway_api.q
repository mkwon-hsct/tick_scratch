/
* @file gateway_api.q
* @overview Define API to utilize gateway routing.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Channel to receive a query from Gateway.
\
GATEWAY_CHANNEL: $[
  .z.f like "*rdb.q";
  `query_rdb;
  .z.f like "*intraday_hdb.q";
  `query_intraday_hdb;
  // .z.f like "*hdb.q";
  `query_hdb
 ];

/
* @brief Channel to connect with Resource Manager.
\
RESOURCE_MANAGER_CHANNEL: $[
  .z.f like "*rdb.q";
  `monitor_rdb;
  .z.f like "*intraday_hdb.q";
  `monitor_intraday_hdb;
  // .z.f like "*hdb.q";
  `monitor_hdb
 ];

/
* @brief Channel to recive return notification from databases. 
\
DATABASE_RETURN_CHANNEL: `database_return;

/
* @brief Enum of query execution status.
\
EXECUTION_STATUS: enlist `failure;
// Fail value.
EXECUTION_FAILURE: `EXECUTION_STATUS$`failure;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Wrapper of a function called by the Gateway so that callback function is triggerred at complettion.
* @param query_id {long}: Query ID.
* @param function {any}
* - symbol: Name of a built-in function to execute.
* - string: Name of a function to execute which is local to this process.
* @param arguments {any}: List of arguments.
* @param topics {list of symbol}: Topics included in the query.
* @param time_range {list of timestamp}: Start time and end time of the queried range.
\
.gateway.execute:{[query_id;function;arguments;topics;time_range]
  result: @[value; (function; arguments; topics; time_range); {[error] (EXECUTION_FAILURE; string[GATEWAY_CHANNEL], ":", error)}];
  $[any EXECUTION_FAILURE ~/: result;
    // Execution error
    neg[.z.w] (`.gateway.callback; query_id; 1b; result 1);
    // Execution success
    neg[.z.w] (`.gateway.callback; query_id; 0b; result)
  ]
 }
