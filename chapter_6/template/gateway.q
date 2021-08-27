/
* @file gateway.q
* @overview Define functionalities of Gateway.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

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
* @brief Enum of query execution status.
\
EXECUTION_STATUS: enlist `failure;
// Fail value.
EXECUTION_FAILURE: `EXECUTION_STATUS$`failure;

/
* @brief Table to manage status of query execution.
* @columns
* - id {long}: Query ID.
* - socket {int}: Socket of database.
* - error {bool}: Flag of whether an error happenned in the execution.
* - result {any}: Result of the query.
\
QUERY_STATUS: 2!enlist `id`socket`error`result!(0N; 0Ni; 0b; ::);

/
* @brief Table of queued queries.
* @columns
* - id {long}: Query ID.
* - topic {symbol}: Topic included in the query.
* - channel {symbol}: Channel to which the query is to be sent.
* - time_range {list of timestamp}: Start time and end time of the queried range.
* - function {function}: Function.
* - arguments {any}: List of arguments.
\
QUERY_QUEUE: enlist `id`topics`channel`time_range`function`arguments!(0N; `symbol$(); `; `timestamp$(); ::; ::);

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
* @brief Channel to receive notification from Log Replayer. 
\
LOG_REPLAYER_CHANNEL: `$"logfile_rolling_notify_", string .z.h;

/
* @brief Channel to communicate with Resource Manager.
\
RESOURCE_MANAGER_CHANNEL: `gateway;

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
* @brief Split time range into sub time ranges according to the time range each kind of database chold.
* @param time_range {list of timestamp}: Start time and end time of the queried range.
* @return
* - dictionary:
*   - key {symbol}: Channel of database to which query is sent.
*   - value {list of timestamp}: Start time and end time of the queried range that each kind of database searches.
\
split_time_range:{[time_range]
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
          // There is no data within an hour from EOD
          if[not LATEST_LOG_ROLLING_TIME = .z.d+00:00:00;
            intraday_hdb_time_range: (.z.d+00:00:00; LATEST_LOG_ROLLING_TIME);
            target[INTRADAY_HDB_CHANNEL]: intraday_hdb_time_range
          ];
          // Set HDB task
          hdb_time_range: (time_range 0; .z.d+00:00:00);
          target[HDB_CHANNEL]: hdb_time_range;
        ]
      ]
    ];
    // LATEST_LOG_ROLLING_TIME > time_range 1;
    // RDB is not included
    $[.z.d <= time_range 0;
      // Only Intra-day HDB
      // Set Intra-day HDB task
      target[INTRADAY_HDB_CHANNEL]: time_range;
      .z.d > time_range 1;
      // Only HDB
      target[HDB_CHANNEL]: time_range;
      // Mixture of HDB and Intra-day HDB
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

  target
 };

/
* @brief Tie database socket with query ID and send a query to the database.
* @param topics: {list of symbol}: Target topics of the query.
* @param time_range {timestamp list}: Start time and end time of the queried range.
* @param function {symbol}: Function name.
* @param arguments {any}: List of arguments.
* @param channel {symbol}: Channel of a target databse.
* @param target {compound list}: List of pairs of (host; port).
\
register_and_send_query:{[topics;function;arguments;channel;targets;time_range]
  // Empty topics must be ignored
  if[not count topics; :()];

  // Get socket from host and port
  sockets: exec socket from CONNECTION where $[`;host] in targets[::; 0], $["I";port] in targets[::; 1];
  // Register sockets
  `QUERY_STATUS upsert/: (QUERY_ID,/: sockets),\: (0b; ::);
  // Send the query to databases
  -25!(sockets; (`.gateway.execute; function; arguments; topics; time_range));
  // Publish to `system_log` channel
  .cmng_api.publish_call_to_system_log[.z.p; channel; `query; `.gateway.execute; (function; arguments; topics; time_range)];
 };

/
* @brief Enqueue a query with its channel, topic and candidates of a target database.
* @param function {function}: Function.
* @param arguments {any}: List of arguments.
* @param channel_ {symbol}: Channel to which query is sent.
* @param topics {list of symbol}: Topics incuded in the query.
* @param time_range {list of timestamp}: Start time and end time of the queried range.
* @return
* - int: Socket of a database.
\
enqueue_query:{[function;arguments;channel;topics;time_range]
  // Emplty topics must be ignored
  if[not count topics; :()];
  show "enqueue";
  .dbg.queue: (QUERY_ID; topics; channel; time_range; function; arguments);
  .dbg.query_queue: QUERY_QUEUE;
  `QUERY_QUEUE insert (QUERY_ID; topics; channel; time_range; function; arguments);
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Update the time of latest log file rolling.
* @param host {symbol}: Host of Log Replayer. Not used.
* @param channel_ {symbol}: Channel of a database to lock or unlock. Not used.
* @param is_lock {bool}: Flag of whether to lock the database. Not used.
\
.logreplay.task_on_rolling_logfile:{[host;channel_;is_lock]
  LATEST_LOG_ROLLING_TIME +: 01:00:00;
 };

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

  // Decide target channel.
  target: split_time_range time_range;

  // Expand `all` topics.
  if[0 > type topics; enlist topics];
  filtered: $[topics ~ enlist `all;
    exec distinct topic from CONSUMER_FILTERS where channel = RDB_CHANNEL;
    [
      // Filter out non-existing topics
      topics inter existing: exec distinct topic from CONSUMER_FILTERS where channel = RDB_CHANNEL;
      $[(0 = count filtered) and not existing ~ enlist `all;
        // Return null if no topic is available in databases.
        :-30!(.z.w; 1b; "no such topics");
        // `all` will handle these.
        topics
      ];
    ]
  ];

  // Get available databases.
  // `raze` is necessary because call executes function to list.
  databases: raze .cmng_api.call[RESOURCE_MANAGER_CHANNEL; `; `.rscmng.select_database; (.z.h; key target; filtered); 0b];

  // Send query
  register_and_send_query[filtered;function;arguments] ./: flip ((key; {[dictionary] value[dictionary][`send]}) @\: databases), enlist value target;
  // Enqueue query
  enqueue_query[function;arguments] ./: flip ((key; {[dictionary] value[dictionary][`queue]}) @\: databases), enlist value target;

  QUERY_ID+:1;
 };

/
* @param error_indicator {bool}: Flag of whether error happenned at the execution.
* @param result {any}: Query result from a database.
\
.gateway.callback:{[error_indicator;result]
  // Get query ID.
  query_id: exec first id from QUERY_STATUS where socket = .z.w;

  // Client cannot send multiple queries since it is blocked.
  `QUERY_STATUS upsert (query_id; .z.w; error_indicator; result);

  // Part of the query is remained in a queue
  is_queued: count select i from QUERY_QUEUE where id = query_id;

  if[(all not (::) ~/: last error_flags_and_results: exec (error; result) from QUERY_STATUS where id = query_id) and not is_queued;
    // All results were back
    $[all not first error_flags_and_results;
      // No error
      [
        // Merge results
        merged: @[QUERY_MERGE_INSTRUCTION[query_id]; last error_flags_and_results; {[error] (EXECUTION_FAILURE; error)}];
        $[any EXECUTION_FAILURE ~/: merged;
          // Merge failed
          -30!(QUERY_TO_CLIENT query_id; 1b; merged 1);
          // Merge succeeded
          -30!(QUERY_TO_CLIENT query_id; 0b; merged)
        ]
      ];
      // Error existed
      // Concatenate all errors with ";"
      -30!(QUERY_TO_CLIENT query_id; 1b; ";" sv error_flags_and_results[1] where error_flags_and_results[0])
    ];
    // Remove merge instruction
    QUERY_MERGE_INSTRUCTION _: query_id;
    // Remove client socket
    QUERY_TO_CLIENT _: query_id;
    // Remove query status
    delete from `QUERY_STATUS where id = query_id;
  ];

  // Get host and channel of the database
  channel_: first exec channel from CONSUMER_FILTERS where .z.w in/: sockets;
  host_: `$first exec host from CONNECTION where socket = .z.w;
  $[count query: select from QUERY_QUEUE where channel = channel_, id = min id;
    // Found queued request for the database
    [
      // Unlock the database to send another query.
      // Do not bother to propagate and execute atomically
      database: raze .cmng_api.call[RESOURCE_MANAGER_CHANNEL;`;`.rscmng.unlock;(channel_; host_; 0b); 0b; (`.rscmng.select_database; .z.h; query[`channel]!query[`time_range]; raze query `topics)];
      // Convert into dictionary because the number of rows of `query` is 1.
      query: first query;
      // Send query
      register_and_send_query[query `topics; query `function; query `arguments; channel_; database[channel_][`send]; query `time_range];
      // Delete the query from queue
      delete from `QUERY_QUEUE where channel = channel_, id = min id;
    ];
    // No queue was found for this database
    // Unlock the database and propagate to make it available for everyone
    .cmng_api.call[RESOURCE_MANAGER_CHANNEL;`;`.rscmng.unlock;(channel_; host_; 1b); 1b; ::]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as an upstream of databases.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME] each (RDB_CHANNEL; INTRADAY_HDB_CHANNEL; HDB_CHANNEL);

// Register as an upstream of Resource Manager.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME;RESOURCE_MANAGER_CHANNEL];

// Register as an downstream of user process
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; USER_CHANNEL; enlist `all];
