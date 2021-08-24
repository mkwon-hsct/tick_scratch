/
* @file gateway.q
* @overview Define functionalities of Gateway.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

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
* @brief Enum of query execution status.
\
EXECUTION_STATUS: enlist `failure;
// Fail value.
EXECUTION_FAILURE: `EXECUTION_STATUS$`failure;

/
* @brief Table to manage status of databases.
* @keys Database sockets.
* @values Flag of whether a database is blocked.
\
DATABASE_AVAILABILITY: (`int$())!`boolean$();

/
* @brief Table to manage status of query execution.
* @columns
* - id {long}: Query ID.
* - socket {int}: Socket of database.
* - error {bool}: Flag of whether an error happenned in the execution.
* - result {any}: Result of teh query.
\
QUERY_STATUS: 2!enlist `id`socket`error`result!(0N; 0Ni; 0b; ::);

/
* @brief Table of queued queries.
* @columns
* - id {long}: Query ID.
* - topic {symbol}: Topic included in the query.
* - candidates {list of int}: Sockets of databases to which query is to be sent.
* - channel {symbol}: Channel to which the query is to be sent.
* - time_range {list of timestamp}: Start time and end time of the queried range.
\
QUERY_QUEUE: flip `id`topic`candidates`channel`time_range!"js*s*"$\:();

/
* @brief Map from query ID to client socket. 
\
QUERY_TO_CLIENT: (`long$())!`int$();

/
* @brief Map from query ID to merge instruction. 
\
QUERY_MERGE_INSTRUCTION: (`long$())!();

/
* @brief Query ID. Incremented by 1 every time.
\
QUERY_ID: 0;

/
* @brief Prevailing time when log file was rolled. Updated by Log Replayer at log file rolling.
\
LATEST_LOG_ROLLING_TIME: .z.d+`time$1000*60*60*`hh$.z.t;

/
* @brief Channel to produce messages to Intra-day HDB. 
\
LOG_REPLAYER_CHANNEL: `$"query_block_notify_", string .z.h;

/
* @brief Channel to send a query to databases.
\
RDB_CHANNEL: `query_rdb;
INTRADAY_HDB_CHANNEL: `query_intraday_hdb;
HDB_CHANNEL: `query_hdb;

/
* @brief Channel to receive a query from a user.
\
USER_CHANNEL: `user_query;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Select database which is not blocked and has minimum queue and at which
*  an expensive query (more than 10 seconds) is not running.  
* @param channel_ {symbol}: Channel to which query is sent.
* @param topic {symbol}: Topic incuded in the query.
* @return
* - int: Socket of a database.
\
select_database:{[channel;topic]
  sockets: raze CONSUMER_FILTERS[((channel; topic); (channel; `all))][`sockets];
  sockets where DATABASE_AVAILABILITY sockets
 };

/
* @brief Enqueue a query with its channel, topic and candidates of a target database.
* @param channel_ {symbol}: Channel to which query is sent.
* @param time_range {list of timestamp}: Start time and end time of the queried range.
* @param topic {symbol}: Topic incuded in the query.
* @return
* - int: Socket of a database.
\
enqueue_query:{[channel;time_range;topic]
  candidates: raze CONSUMER_FILTERS[((channel; topic); (channel; `all))][`sockets];
  `QUERY_QUEUE insert (QUERY_ID; topic; candidates; channel; time_range);
 }

/
* @brief Tie database socket with query ID and send a query to the database.
* @param target {list of int}: Sockets of the target databases.
* @param channel {symbol}: Channel of a target databse.
* @param topics: {list of symbol}: Target topics of the query.
* @param time_range {timestamp list}: Start time and end time of the queried range.
* @param function {symbol}: Function name.
* @param arguments {any}: List of arguments.
\
register_and_send_query:{[target;channel;topics;time_range;function;arguments]
  // Register sockets
  QUERY_STATUS[QUERY_ID,/: target]: `status`result!(0b; ::);
  // Send the query to databases
  -25!(target; function, arguments, enlist time_range);
  // Publish to `system_log` channel
  .cmng_api.log_call[CONSUMER_FILTERS[(`system_log; `all)][`sockets]; .z.p; channel; ; `.gateway.execute; (function; arguments)] each topics;
 };

/
* @brief Select available databases and send a query or enqueue it if database is not available.
* @param topics: {list of symbol}: Target topics of the query.
* @param function {symbol}: Function name.
* @param arguments {any}: List of arguments.
* @param channel {symbol}: Channel of a target databse.
* @param time_range {timestamp list}: Start time and end time of the queried range. 
\
send_or_enqueue:{[topics;function;arguments;channel;time_range]
  queued: where (`int$()) ~/: topics!select_database[channel] each topics;
  sent: queued _ topics;
  // Enqueue topics which cannot be sent.
  enqueue_query each queued;
  // Target sockets
  sent: distinct raze value first each sent;
  // Link a query to query ID and send it.
  register_and_send_query[sent; channel; topics; time_range; function; arguments];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Interface which client calls to send a query to database.
* @param time_range {list of timestamp}: Start time and end time of the selected range.
* @param function {symbol}: Function name.
* @param arguments {any}: List of arguments.
* @param merge_instruction {function}: Function to merge results from databases.
\
.gateway.query:{[time_range;topics;function;arguments;merge_instruction]
  // Capture the client socket
  -30!(::);
  // Store client socket.
  QUERY_TO_CLIENT[QUERY_ID]: .z.w;
  // Store merge instruction
  QUERY_MERGE_INSTRUCTION[QUERY_ID]: merge_instruction;

  // Set of time range and database
  target: (`symbol$())!();

  $[LATEST_LOG_ROLLING_TIME < time_range 0;
    // Only RDB
    // Set RDB task
    target[RDB_CHANNEL]: time_range;
    LATEST_LOG_ROLLING_TIME within time_range;
    // RDB is included
    [
      rdb_time_range: (LATEST_LOG_ROLLING_TIME; time_range 1);
      target[RDB_CHANNEL]: rdb_time_range;
      $[.z.d <= time_range 0;
        // HDB is not included
        [
          // Set Intra-day HDB task
          intraday_hdb_time_range: (time_range 0; LATEST_LOG_ROLLING_TIME);
          target[INTRADAY_HDB_CHANNEL]: intraday_hdb_time_range;
        ];
        // HDB is included
        [
          // Set Intra-day HDB task
          intraday_hdb_time_range: (.z.d+00:00:00; LATEST_LOG_ROLLING_TIME);
          target[INTRADAY_HDB_CHANNEL]: intraday_hdb_time_range;
          // Set HDB task
          hdb_time_range: (time_range 0; .z.d+00:00:00);
          target[INTRADAY_HDB_CHANNEL]: hdb_time_range;
        ]
      ]
    ];
    // LATEST_LOG_ROLLING_TIME > time_range 1;
    // RDB is not included
    $[.z.d <= time_range 0;
      // HDB is not included
      // Set Intra-day HDB task
      target[INTRADAY_HDB_CHANNEL]: time_range;
      // Intra-HDB is not included
      [
        // Set Intra-day HDB task
        intraday_hdb_time_range: (.z.d+00:00:00; time_range 1);
        target[INTRADAY_HDB_CHANNEL]: intraday_hdb_time_range;
        // Set HDB task
        hdb_time_range: (time_range 0; .z.d+00:00:00);
        target[HDB_CHANNEL]: hdb_time_range;
      ]
    ]
  ];

  show "hey";
  send_or_enqueue[topics] ./: flip (key; value) @\: target;
  show "hoo";
  QUERY_ID+:1;
 };

/
* @param result {any}: Query result from a database.
* @param error_indicator {bool}: Flag of whether error happenned at the execution.
\
.gateway.callback:{[result;error_indicator]
  // Client cannot send multiple queries since it is blocked.
  update result: result, error: error_indicator from `QUERY_STATUS where socket = .z.w;
  // Get query ID.
  query_id: exec first id from QUERY_STATUS where socket = .z.w;

  // Part of the query is remained in a queue
  is_queued: count select i from QUERY_QUEUE where id = query_id;

  if[(all not (::) ~ last error_flags_and_results: flip exec (error; result) from QUERY_STATUS where id = query_id) and not is_queued;
    // All results were back
    $[all not first error_flags_and_results;
      // No error
      [
        // Merge results
        merged: @[QUERY_MERGE_INSTRUCTION[query_id]; last error_flags_and_results; {[error] (EXECUTION_FAILURE; error)}];
        $[EXECUTION_FAILURE in merged;
          // Merge failed
          -30!(QUERY_TO_CLIENT query_id; 1b; merged 1);
          // Merge succeeded
          -30!(QUERY_TO_CLIENT query_id; 0b; merged)
        ]
      ];
      // Error existed
      -30!(QUERY_TO_CLIENT query_id; 1b; error_flags_and_results[1] where error_flags_and_results[0])
    ];
    // Remove merge instruction
    QUERY_MERGE_INSTRUCTION _: query_id;
    // Remove client socket
    QUERY_TO_CLIENT _: query_id;
    // Remove query status
    delete from `QUERY_STATUS where id = query_id;
  ];

  // Look for queued queries targeted to the database
  queries: exec topic, first time_range from QUERY_QUEUE where .z.w in/: candidates;
  $[0 = count raze value queries;
    // No queries to process
    // Unlock the database
    DATABASE_AVAILABILITY[.z.w]: 0b;
    // Link a query to query ID and send it.
    register_and_send_query[enlist .z.w; channel; queries[`topic]; queries[`time_range]; function; arguments];
  ]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as an upstream of databases.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME] each (RDB_CHANNEL; INTRADAY_HDB_CHANNEL; HDB_CHANNEL);

.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; USER_CHANNEL; enlist `all];
