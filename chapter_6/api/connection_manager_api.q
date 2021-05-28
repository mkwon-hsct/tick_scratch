/
* @file connection_manager_api.q
* @overview Define API to access a connection manager.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:utility/log.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Socket used to communicate with a local connection manager defined in `connection_manager.config`.
\
CONNECTION_MANAGER_SOCKET: {[]
  managers: read0 `:config/connection_manager.config;
  // Use Unix domain socket
  hopen `$":unix://", last ":" vs managers first where managers like\: string[.z.h], "*"
 }[];

/
* @brief Table holding information of processes/users currently conncted.
* @columns
* - host {string}: Host of the counter party
* - port {string}: Port of the counter party.
* - socket {int}: Socket of the counter party.
\
CONNECTION: flip `host`port`socket!"**i"$\:();

/
* @brief Table holding sockets for a combination of a channel and a topic.
* @columns
* - channel {symbol}: Target channel of a message.
* - topic {topic}: Topic of the message.
* - sockets {list of int}: Target sockets for the channel and the topic.
\
CONSUMER_FILTERS: 2!flip `channel`topic`sockets!"ss*"$\:();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief A process/user calls this function remotely to notify the counter party
*  that a new connection was established. Register the host, the port and a socket
*  of the caller.
* @param host {string}: Host of the caller.
* @param port {string}: Port of the caller.
\
register_counter_party:{[host; port]
  `CONNECTION insert (enlist host; enlist port; .z.w);
 };

/
* @brief Add channel, topics and socket to `CONSUMEMR_FILTERS`.
* @param channel {symbol}: Channel.
* @param topics {list of symbol}: Topics in which the consumer is interested.
* @param remote {bool}: Called remotely.
* @param socket {int}: Socket of the target if called locally: null otherwise.
\
add_consumer_filter:{[channel;topics;remote;socket]
  filters: channel,/: topics,\: $[remote; .z.w; socket];
  .log.info["add a consumer to filters"; filters];
  `CONSUMER_FILTERS upsert/: filters;
 };

/
* @brief Start connection from a matched record if it has not been connected.
* @param matched {dictionary}: Record of matched user/process.
* - host {string}: Host of the target.
* - port {string}: Port of the target.
* - (topics) {list of symbol}: Topics in which the target soncumer is interested.
* @param channel {symbol}: Channel registered to the connection manager this time.
* @param topics {variable}: 
* - list of symbol: Topics registered to the connection manager this time if the caller is a consumer.
* - general null: If the caller is a producer
\
connect_and_register:{[matched;channel;topics]
  host_port: matched `host`port;
  // Serach if the host-port already exists
  socket: $[not null socket_: first exec socket from CONNECTION where (host,' port) ~\: raze host_port;
    // Already connected
    [
      .log.info["already connected"; `$":" sv host_port];
      socket_
    ];
    // New connection
    [
      .log.info["new connection"; `$":" sv host_port];
      handle: $[.z.h ~ `$host_port 0;
        // Use unix domain socket if the target is in the same host
        `$":unix://", host_port 1;
        hsym `$":" sv host_port
      ];
      socket_: hopen handle;
      // Register to `CONNECTION`
      `CONNECTION insert (enlist host_port 0; enlist host_port 1; socket_);
      // Notify the target of the new connection.
      socket_ (`register_counter_party; string .z.h; string system "p");
      socket_
    ]
  ];

  // Register the socket to `CONSUMER_FILTERS` if the matched record is a consumer's one.
  $[`topics in key matched;
    // The record has `topics`, meaning it is a consumer
    add_consumer_filter[channel; matched `topics; 0b; socket];
    // Matched record is a producer
    socket (`add_consumer_filter; channel; topics; 1b; 0Ni)
  ];
 
 };

/
* @brief Delete a socket from `CONSUMER_FILTERS`.
* @param socket_ {int}: Socket to delete from filters. 
\
delete_socket_from_filters:{[socket_]
  keys_and_count: flip exec (channel; topic; sockets) from CONSUMER_FILTERS where socket_ in/: sockets;
  {[socket_;channel_;topic_;sockets]
    $[1 = count sockets;
      // Only socket. Delete the filter.
      delete from `CONSUMER_FILTERS where channel = channel_, topic = topic_;
      // Other consumers are subscribing
      CONSUMER_FILTERS[(channel_; topic_)]: CONSUMER_FILTERS[(channel_; topic_)] except socket_
    ];
  }[socket_] ./: keys_and_count; 
 };

/
* @brief Delete a record of the dropped counter-party.
* @param socket_ {int}: Socket of the dropped counter-party.
\
.z.pc:{[socket_]
  handle: `$":" sv first each exec (host; port) from CONNECTION where socket = socket_;
  .log.info["connection dropped"; handle];
  delete from `CONNECTION where socket = socket_;
  // Delete the socket from filters
  delete_socket_from_filters[socket_];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register channel as a producer. If there are matched consumers, start communication with them.
\
.cmng_api.register_as_producer: {[name;channel]
  matched: CONNECTION_MANAGER_SOCKET (`.cmng.register; name; 1b; channel; (::));
  $[count matched;
    [
      // Matched some records
      .log.info["matched ", string[count matched], " records."; (::)];
      connect_and_register[; channel; ::] each matched
    ];
    [
      // No record matched
      .log.info["no record matched"; (::)];
      :()
    ]
  ];
 };

/
* @brief Register channel as a producer. If there are matched consumers, start communication with them.
\
.cmng_api.register_as_consumer: {[name;channel;topics]
  matched: CONNECTION_MANAGER_SOCKET (`.cmng.register; name; 0b; channel; topics);
  $[count matched;
    [
      // Matched some records
      .log.info["matched ", string[count matched], " records."; (::)];
      connect_and_register[; channel; topics] each matched
    ];
    [
      // No record matched
      .log.info["no record matched"; (::)];
      :()
    ]
  ];
 };
