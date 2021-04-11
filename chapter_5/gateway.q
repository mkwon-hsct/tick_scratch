/
* @file gateway.q
* @overview
* Defines gateway functionality.
\

/
* @brief Commandline arguments. 
\
COMMANDLINE_ARGS:.Q.opt .z.X;

/
* @brief Socket of database bundle. 
\
WORKERS: hopen each `$":" sv/: (""; ""),/: enlist each COMMANDLINE_ARGS `dbports;

/
* @brief Event handler of socket close. Remove socket if database process goes down.
\
.z.pc:{[socket] WORKERS _: socket;};

/
* @brief ID of query.
\
QUERY_ID: 0;

/
* @brief Map between query ID and client socket. 
\
CLIENT_TO_QUERY: (`int$())!`long$();

/
* @brief Map between query ID and worker socket. 
\
WORKER_TO_QUERY: (`int$())!();

/
* @brief Interface which client calls to send a query to database.
* @param function {symbol}: Function name.
* @param args {compound list}: List of arguments.
\
query:{[function;args]
  // Block client til response is ready.
  -30!(::);
  // Register client with the ID.
  CLIENT_TO_QUERY[.z.w]: QUERY_ID;
  // Decide worker in Round-robin way.
  worker: WORKERS[QUERY_ID mod count WORKERS];
  // Add query ID to the queue of thw worker.
  WORKER_TO_QUERY[worker],: QUERY_ID;
  QUERY_ID+: 1;
  // Deligate processing to the worker.
  neg[worker] (function; args); 
 }

/
* @brief Callback function triggerred by a worker to return query result to a client. 
* @param result {any}:
* - string: If query execution failed.
* - any: If query execution succeeded.
* @param error_indicator {bool}: True if execution failed.
\
callback:{[result; error_indicator]
  // Retrieve query ID from the worker queue.
  queryID: first WORKER_TO_QUERY .z.w;
  // Remove query ID from the worker queue.
  WORKER_TO_QUERY[.z.w] _: 0; 
  // Identify client with the query ID.
  client: CLIENT_TO_QUERY?queryID;
  // Remove client.
  CLIENT_TO_QUERY _: client;
  // Return result to client.
  -30!(client; error_indicator; result);
 };
