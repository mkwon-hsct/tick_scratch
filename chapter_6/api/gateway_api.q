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
  `query_intaraday_hdb;
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
\
.gateway.execute:{[function;arguments]
  result: .[value; (function; arguments); {[error] (EXECUTION_FAILURE; error)}];
  $[EXECUTION_FAILURE ~/: result;
    // Execution error
    .z.w (`.gateway.callback; 1b; result 1);
    // Execution success
    .z.w (`.gateway.callback; 0b; result)
  ]
 };
