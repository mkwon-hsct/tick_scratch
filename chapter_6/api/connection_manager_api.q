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
* @brief Name of this process used for communication. This value is initialized at the registration
*  to the connection manager.
\
MY_ACCOUNT_NAME: `;

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

/
* @brief Map from a target name to a unique channel.
* @key symbol: Target user name.
* @value symbol: Channel name used for the chat with the target.
\
PRIVATE_MESSAGE_CHANNEL: (`$())!`$();

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
  {[channel;topic;socket]
    // Replace the value (`sockets![list of int]) with the new value of the same type.
    CONSUMER_FILTERS[(channel; topic)]:@[CONSUMER_FILTERS[(channel; topic)]; `sockets; ,; socket];
  } ./: filters;
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
      .log.info["already connected"; hsym `$":" sv host_port];
      socket_
    ];
    // New connection
    [
      .log.info["new connection"; hsym `$":" sv host_port];
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
      // Last socket. Delete the filter.
      delete from `CONSUMER_FILTERS where channel = channel_, topic = topic_;
      // Other consumers are subscribing
      CONSUMER_FILTERS[(channel_; topic_)]: @[CONSUMER_FILTERS[(channel_; topic_)]; `sockets; except; socket_]
    ];
  }[socket_] ./: keys_and_count; 
 };

/
* @brief Delete a record of the dropped counter-party.
* @param socket_ {int}: Socket of the dropped counter-party.
\
.z.pc:{[socket_]
  handle: hsym `$":" sv first each exec (host; port) from CONNECTION where socket = socket_;
  if[not handle ~ `:;
    // Registered socket.
    .log.info["connection dropped"; handle];
    delete from `CONNECTION where socket = socket_;
    // Delete the socket from filters
    delete_socket_from_filters[socket_]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register channel as a producer. If there are matched consumers, start communication with them.
* @param name {symbol}: User name to connect to the connection manager.
* @param channel {symbol}: Channel to which publish a message.
\
.cmng_api.register_as_producer: {[name;channel]
  // Initialize account name if not defined
  if[MY_ACCOUNT_NAME ~ `; MY_ACCOUNT_NAME::name];
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
* @brief Register channel as a consumer. If there are matched producers, start communication with them.
* @param name {symbol}: User name to connect to the connection manager.
* @param channel {symbol}: Channel to subscribe.
* @topics {list of symbol}: Topics to subscribe.
\
.cmng_api.register_as_consumer: {[name;channel;topics]
  // Initialize account name if not defined
  if[MY_ACCOUNT_NAME ~ `; MY_ACCOUNT_NAME::name];
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

/
* @brief Publish a message applying a filter to a channel and a topic.
* @param channel {symbol}: Channel to which publish a message.
* @param topic {symbol}: Topic of the message.
* @param message {any}: Message to send.
* @param is_async {bool}: Flag to publish a message asynchronously.
\
.cmng_api.publish:{[channel;topic;table;message;is_async]
  ($[is_async; neg; ::] raze CONSUMER_FILTERS[((channel; topic); (channel; `all))][`sockets]) @\: (`.cmng_api.update; table; (.z.p; topic; MY_ACCOUNT_NAME; message));
 }

/
* @brief Start a private chat with a specific user.
* @param name {symbol}: User name to connect to the connection manager.
* @param target {symbol}: Traget user name to talk with.
* @param is_requester {bool}: Indicates if the caller is a requester.
* @param channel {symbol}: Chennel to use for the private chat.
*  - null: Arbitrary value for a request.
*  - other: Unique value assigned by the connection manager.
\
.cmng_api.start_private_chat:{[name;target;is_requester;channel]

  // Create a chat table and update function if they do not exist
  if[not `MESSAGE_BOX in tables[];
    MESSAGE_BOX:: flip `time`topic`sender`message!"pss*"$\: ();
    .cmng_api.update: {[table;message]
      table insert (.z.p; message 1; message 2; message 3)
    }
  ];

  // If this is a request, overwrite with a unique value generated on the connection manager.
  if[is_requester;
    result: CONNECTION_MANAGER_SOCKET (`.cmng.process_private_chat_request; name; target);
    $[10h ~ type result;
      // Propagate an error
      'result;
      // Overwrite the channel value
      channel: last result
    ]
  ];
  // Close the temporary handle to this process which was opened remotely.
  if[.z.w > 0i; hclose .z.w];
  // Register as both producer and consumer.
  .cmng_api.register_as_consumer[name; channel; enlist `user_chat];
  .cmng_api.register_as_producer[name; channel];
  // Register the channel for the target.
  PRIVATE_MESSAGE_CHANNEL[target]: channel;

  if[is_requester;
    // Notify the target to start chat
    handle: hopen hsym `$":" sv -1 _ result;
    neg[handle] (`.cmng_api.start_private_chat; target; name; 0b; channel)
  ];
 };

/
* @brief Publish a message to a specific user in private chat.
* @param message {string}: Text message to send.
\
.cmng_api.publish_private: {[target;message]
  .cmng_api.publish[PRIVATE_MESSAGE_CHANNEL target; `user_chat; `MESSAGE_BOX; enlist message; 1b]
 };
