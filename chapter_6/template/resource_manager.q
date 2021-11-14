/
* @file resource_manager.q
* @overview Define functionalities of Resource Manager.
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
* @brief Dictionary of sockets of connection managers.
* - keys {symbol}: Handles of connection detail.
* - values {int}: Sockets of the connection managers.
\
RESOURCE_MANAGERS: (`symbol$())!`int$();

/
* @brief Flag of whether this process is a master.
\
MASTER: 1b;

/
* @brief Handle of master Resource Manager. Updated at the start of this process.
\
MASTER_HANDLE: (::);

/
* @brief Table to manage availability of databases.
* @columns
* - host {symbol}: Host of a database.
* - port {int}: Port of a database.
* - channel {symbol}: Channel of a database.
* - topics {list of symbol}: Topics held by a database.
* - available {bool}: Flag of whether a database is available.
\
DATABASE_AVAILABILITY: flip `host`port`channel`topics`available!"sis*b"$\:();

/
* @brief Channel to receive notification from Log Replayer. 
\
LOG_REPLAYER_CHANNEL: `query_block_notify;

/
* @brief Channel to monitor databases.
\
RDB_CHANNEL: `monitor_rdb;
INTRADAY_HDB_CHANNEL: `monitor_intraday_hdb;
HDB_CHANNEL: `monitor_hdb;

/
* @brief Channel to recive return notification from databases. 
\
DATABASE_RETURN_CHANNEL: `database_return;

/
* @brief Channel to communicate with Gateway.
\
GATEWAY_CHANNEL: `gateway;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register the socket of the Resource Manager who called this function remotely.
* @param host {string}: Host of the caller.
* @param port {string}: Port of the caller. 
\
register_resource_manager:{[host;port]
  handle: hsym `$":" sv (host; port);
  .log.info["peer resource manager notified of a new connection"; handle];
  RESOURCE_MANAGERS[handle]: .z.w;
 }

/
* @brief Connect to a peer Resource Manager and register the socket if
*  the attempt is successful.
* @param peer {symbol}: Handle composed of `[host]:[port]`.
\
connect_peer_manager:{[peer]
  handle: `$":", peer;
  socket: $[handle in key RESOURCE_MANAGERS;
    // Already connected.
    (::);
    // New connection.
    // Null if connection failed.
    @[hopen; handle; {[error] (::)}]
  ];
  if[not socket ~ (::);
    // New connection was established.
    .log.info["connected to a peer resource manager"; handle];
    RESOURCE_MANAGERS[handle]: socket;
    //　Notify the target of the new connection.
    socket (`register_resource_manager; string .z.h; string system "p");
    // Receive database information from the resource manager.
    DATABASE_AVAILABILITY:: socket (get; `DATABASE_AVAILABILITY);
    // Behave as slave.
    MASTER:: 0b;
    // Update master.
    MASTER_HANDLE:: socket (get; `MASTER_HANDLE)
  ];
 }

/
* @brief Select available databases which holds data of specified topics.
* @param gateway_host: Host of Gateway which called this function.
* @param hosts {list of symbol}: Target hosts to search available databases.
* @param topics_ {symbol}: Topic included in the query.
* @param channel_ {symbol}: Channel to which query is sent.
* @return dictionary:
* - send: List of pairs of (host; port)
* - queue: List of symbol for which database could not be arranged.
\
select_database:{[gateway_host;hosts;topics_;channel_]
  // If hosts are empty, enqueue topics_ and return it.
  if[0 = count hosts; :enlist[`queue]!enlist topics_];

  next_host:$[gateway_host in hosts;
    [
      hosts: hosts except gateway_host;
      gateway_host
    ];
    [
      next_host: first hosts;
      hosts: 1 _ hosts;
      next_host
    ]
  ];
  // Candidates of the target chosen from local databases
  candidates: distinct flip exec (topics; host; port) from DATABASE_AVAILABILITY where host = next_host, channel = channel_, any each ((topics_ in/: topics),' topics ~\: enlist `all), available;
  $[(`all in covered) or all topics_ in covered: raze candidates[::;0];
    // Covered all topics
    `send`queue!(candidates[::; 1 2]; `symbol$());
    // Not covered
    [
      remained: topics_ except covered;
      // Serach from the next host
      (`send`queue!(candidates[::; 1 2]; `symbol$())),' .z.s[gateway_host; hosts; remained; channel_]
    ]
  ]
 }

/
* @brief Propagate the present value of DATABASE_AVAILABILITY to the other Resource Managers.
\
propagate:{[]
  -25!(value[RESOURCE_MANAGERS]; ("set"; `DATABASE_AVAILABILITY; DATABASE_AVAILABILITY));
 }

/
* @brief Definition of Connection Manager API.
\
Z_PC_: .z.pc;

/
* @brief Switch master if peer manager dropped. Otherwise process with Connection Manager API.
\
.z.pc:{[socket_]
  //  Check if the socket is for database
  host_port: first each exec (`$host; "I"$port) from CONNECTION where socket = socket_;
  $[count select from DATABASE_AVAILABILITY where host = host_port[0], port = host_port[1];
    // Database dropped
    [
      .log.info["database dropped"; hsym `$":" sv string host_port];
      delete from `DATABASE_AVAILABILITY where host = host_port[0], port = host_port[1];
    ];
    count handle: where socket_ = RESOURCE_MANAGERS;
    // Peer manager dropped
    [
      
      // Check current master
      // Remove the handle of dropped resource manager
      RESOURCE_MANAGERS _: handle;
      if[MASTER_HANDLE ~ handle;
        // Decide the next master
        MASTER_HANDLE:: first asc key[RESOURCE_MANAGERS], self: hsym `$":" sv string (.z.h; system "p");
        if[self ~ next_master; MASTER:: 1b]
      ];
    ];
    // Not peer manager
    Z_PC_[socket_]
  ]
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Lock or unlock databases when log file is switched..
* @param host_ {symbol}: Host name of Log Replayer.
* @param channel_ {symbol}: Channel of a database to lock or unlock.
* @param is_lock {bool}: Flag of whether to lock the database.
\
.logreplay.task_on_rolling_logfile:{[host_;channel_;is_lock]
  update available: $[is_lock; 0b; 1b] from `DATABASE_AVAILABILITY where host = host_, channel = channel_;
 }

/
* @brief Register a returned database as an available resource.
* @param host {symbol}: Host of a database.
* @param port {int}: Port of a database.
* @param channel {symbol}: Channel to which a database belongs.
\
.rscmng.return:{[host;port;channel]
  `DATABASE_AVAILABILITY insert (host; port; channel; exec topic from CONSUMER_FILTERS where .z.w in/: sockets; 1b);
 }

/
* @brief Select available databases for given channel and topics.
* @param gateway_host: Host of Gateway which called this function.
* @param target {list of symbol}: Channel of database to which query is sent.
* @param topics {list of symbol}: Topics included in the query.
* @return dictionary:
* - keys {symbol}: Channel of database.
* - values {dictionary}:
*   - send: List of pairs of (host; port)
*   - queue: List of symbol for which database could not be arranged.
\
.rscmng.select_database:{[gateway_host;target;topics]
  // Only master reacts
  if[not MASTER; :()];

  hosts: exec distinct host from DATABASE_AVAILABILITY;
  // Map from channel to target databases
  databases: target!select_database[gateway_host; hosts; topics] each target;
  // List of (host; port) in `send
  host_port: raze value[databases] `send;
  // Block databases with the target host and port
  if[count host_port;
    // Target exists
    update available: 0b from `DATABASE_AVAILABILITY where host in host_port[::; 0], port in host_port[::; 1];
    // Propagate availability to the other Resource Managers
    propagate[]
  ];
  databases
 }

/
* @brief Unlock a database with a given host and channel.
* @param channel_ {symbol}: Channel of a database.
* @param host_ {symbol}: Host of a database.
* @param propagate_ {bool}: Flag of whether to propagate the availability.
* @param expression {compound list}: Expression to execute after unlocking database.
\
.rscmng.unlock:{[channel_;host_;propagate_;expression]
  // Only master reacts
  if[not MASTER; :()];
  
  update available: 1b from `DATABASE_AVAILABILITY where host = host_, channel = channel_;
  $[propagate_;
    propagate[];
    value expression
  ]
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Log Replayer.
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; LOG_REPLAYER_CHANNEL; enlist `all];

// Register as a downstream of Gateway.
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; GATEWAY_CHANNEL; enlist `all];

// Register as an upstream of databases.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME] each (RDB_CHANNEL; INTRADAY_HDB_CHANNEL; HDB_CHANNEL);

// Register as a downstream of databases.
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; DATABASE_RETURN_CHANNEL; enlist `return];

// Register databases.
{[channel_]
  dbs: exec distinct raze sockets from CONSUMER_FILTERS where channel = channel_;
  // (hosts; ports)
  db_records: exec (`$host; "I"$port) from CONNECTION where socket in dbs;
  // (hosts; ports; channels)
  db_records,: enlist count[dbs]#`$ssr[string channel_; "monitor"; "query"];
  // (hosts; ports; channels; list of topics)
  db_records,: enlist {[socket] exec topic from CONSUMER_FILTERS where socket in/: sockets} each dbs;
  // (hosts; ports; channels; list of topics; availabilities)
  db_records,: enlist count[dbs]#1b;
  `DATABASE_AVAILABILITY insert db_records;
 } each (RDB_CHANNEL; INTRADAY_HDB_CHANNEL; HDB_CHANNEL);

// Connect to peer Resource Managers.
{[]
  managers: read0 `:config/resource_manager.config;
  // Open self port defined in `resource_manager.config`.
  system "p ", last ":" vs managers self: first where managers like\: string[.z.h], "*";
  // Connect to peer resource managers and receive information of `DATABASE_AVAILABILITY`.
  connect_peer_manager each managers except[til count managers; self];
 }[];
