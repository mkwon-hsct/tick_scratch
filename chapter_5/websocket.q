/
* @file websocket.q
* @overview Defines event handlers for websocket communication.
\

// Run on port 5000 if port is not specified.
if[not system "p"; system "p 5000"];

/
* @brief Enum indicating request execution failure.
\
EXECUTION_STATUS_: `SUCCESS`FAILURE;
EXECUTION_FAILURE_: `EXECUTION_STATUS_$`FAILURE;

/
* @brief Notify the establishment of connection. 
* @param socket {int}: Client handle.
\
.z.wo:{[socket]
  -1 "Connection is established: ", string socket;
 }

/
* @brief Notify the close of the connection.
* @param socket {int}: Client handle.
\
.z.wc:{[socket]
  -1 "Connection was closed. Bye, ", string socket;
 }

/
* @brief Show JSON text as a dictionary and then return JSON messsage containing
*  status and timestamp.
* @param query {string}: JSON message.
\
.z.ws:{[query]
  result: .Q.trp[.j.k; query; {[error; trace] (EXECUTION_FAILURE_; "Error: ", error, "\n", .Q.sbt trace)}];
  $[any EXECUTION_FAILURE_ ~/: result; 
    // Not a valid JSON
    neg[.z.w] result 1; 
    // JSON
    [
      show result;
      neg[.z.w] .h.hn["200"; `json; .j.j `time`status!(.z.p; "OK")];
      neg[.z.w] "ついでにこれもお願い！"
    ]
  ];
 }
