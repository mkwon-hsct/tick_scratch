/
* @file gateway_api.q
* @overview Define API to utilize gateway routing.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

GATEWAY_CHANNEL: $[
  .z.f like "*rdb.q";
  `query_rdb;
  .z.f like "*intraday_hdb.q";
  `query_intraday_hdb;
  // .z.f like "*hdb.q";
  `query_hdb
 ];

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
* @param function {variable}
* - symbol: Name of a built-in function to execute.
* - string: Name of a function to execute which is local to this process.
* @param arguments {any}: List of arguments.
* @param time_range {timestamp list}: Start time and end time of the queried range.
\
.gateway.execute:{[function;arguments;time_range]
  result: @[value; (function; arguments; time_range); {[error] (EXECUTION_FAILURE; error)}];
  $[any EXECUTION_FAILURE ~/: result;
    // Execution error
    neg[.z.w] (`.gateway.callback; 1b; result 1);
    // Execution success
    neg[.z.w] (`.gateway.callback; 0b; result)
  ]
 };
