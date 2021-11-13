/
* @file connection_manager_api.q
* @overview Define API to interact with the connection manager.
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
* @brief Table holding sockets used for each pair of channel and topic.
* @columns
* - channel {symbol}: Target channel of a message.
* - topic {topic}: Topic of a message.
* - sockets {list of int}: Target sockets for the channel and the topic.
* @note Add a dummy record to fix the type of sockets as a list of int.
\
CONSUMER_FILTERS: 2!flip `channel`topic`sockets!(enlist `; enlist `; enlist `int$());

/
* @brief Map from a target name to a unique channel.
* @keys {symbol}: Target user name.
* @values {symbol}: Channel name used for the chat with the target.
\
PRIVATE_MESSAGE_CHANNEL: (`$())!`$();

/
* @brief Name pattern of processes which are excluded from publishers of `system_log` channel.
\
SYSTEM_LOG_EXCLUDED_PROCESS: "tickerplant*";

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register the host, port and socket of a process who called this function remotely
*  at the establishment of a new connection.
* @param host {string}: Host of the caller.
* @param port {string}: Port of the caller.
\
register_counter_party:{[host; port]
  `CONNECTION insert (enlist host; enlist port; .z.w);
 }

/
* @brief Add channel, topics and socket to `CONSUMEMR_FILTERS`.
* @param channel {symbol}: Channel.
* @param topics {list of symbol}: Topics in which the consumer is interested.
* @param remote {bool}: Flag of whether this function was called remotely.
* @param socket {int}: Socket of the target if called locally: null otherwise.
\
add_consumer_filter:{[channel;topics;remote;socket]
  filters: channel,/: topics,\: $[remote; .z.w; socket];
  .log.info["add a consumer to filters"; filters];
  {[channel;topic;socket]
    // Replace the value (`sockets![list of int]) with the new value of the same type.
    CONSUMER_FILTERS[(channel; topic)]: @[CONSUMER_FILTERS[(channel; topic)]; `sockets; {[existing;new] distinct existing, new}; socket];
  } ./: filters;
 }

/
* @brief Start connection from a matched record if it has not been connected.
* @param matched {dictionary}: Record of matched user/process. Valid keys are:
* - name {symbol}: Account name of conterparty.
* - host {string}: Host of the target.
* - port {string}: Port of the target.
* - channel {symbol}: Channel name.
* - (topics) {list of symbol}: Topics in which the target consumer is interested.
* @param topics {any}: 
* - list of symbol: Topics registered to the connection manager this time if the caller is a consumer.
* - general null: If the caller is a producer
\
connect_and_register:{[matched;topics]
  host_port: matched `host`port;
  // Search if the host-port already exists
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
    add_consumer_filter[matched `channel; matched `topics; 0b; socket];
    // Matched record is a producer
    socket (`add_consumer_filter; matched `channel; topics; 1b; 0Ni)
  ];
 
 }

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
 }

/
* @brief Delete a record of the dropped counter-party.
* @param socket_ {int}: Socket of the dropped counter-party.
\
.z.pc:{[socket_]
  handle: hsym `$":" sv value first each exec (host; port) from CONNECTION where socket = socket_;
  if[not handle ~ `:;
    // Registered socket.
    .log.info["connection dropped"; handle];
    delete from `CONNECTION where socket = socket_;
    // Delete the socket from filters
    delete_socket_from_filters[socket_]
  ];
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register a channel as a producer. If there are matched consumers, start communication with them.
* @param name {symbol}: User name to connect to the connection manager.
* @param channel {symbol}: Channel to publish a message.
\
.cmng_api.register_as_producer: {[name;channel]
  // Initialize account name if not defined
  if[MY_ACCOUNT_NAME ~ `; MY_ACCOUNT_NAME::name];
  // Publish to `system_log` channel if process name does not match the pattern of excluded processes.
  matched: $[name like SYSTEM_LOG_EXCLUDED_PROCESS;
    CONNECTION_MANAGER_SOCKET (`.cmng.register; name; 1b; channel; (::));
    raze CONNECTION_MANAGER_SOCKET each (`.cmng.register; name; 1b),/: (channel; `system_log),\:  (::)
  ];
  $[count matched;
    [
      // Matched some records
      .log.info["matched ", string[count matched], " records."; ::];
      connect_and_register[; ::] each matched
    ];
    [
      // No record matched
      .log.info["no record matched"; (::)];
      :()
    ]
  ];
 }

/
* @brief Register a channel as a consumer. If there are matched producers, start communication with them.
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
      .log.info["matched ", string[count matched], " records."; ::];
      connect_and_register[; topics] each matched
    ];
    [
      // No record matched
      .log.info["no record matched"; (::)];
      :()
    ]
  ];
 }

/
* @brief Publish to `system_log` channel appending a timestamp, caller name, channel and topic.
* @param time {timestamp}: Publish time of this log message.
* @param channel {symbol}: Channel of the call.
* @param topic {symbol}: Topic of the call.
* @param function {symbol}: Name of the called function.
* @param arguments {any}: List of arguments of the function.
\
.cmng_api.publish_call_to_system_log:{[time;channel;topic;function;arguments]
  // Ensure `arguments` is a compound list
  -25!(CONSUMER_FILTERS[(`system_log; `all)][`sockets]; `.cmng_api.log_call, time, MY_ACCOUNT_NAME, channel, topic, function, enlist $[0h ~ type arguments; arguments; arguments, (::)]);
 }

/
* @brief Call a remote function applying a filter to a channel and topic.
* @param channel_ {symbol}: Channel to which call a function.
* @param topic {symbol}: Topic of the call. Null symbol to broadcast to a channel.
* @param function {any}:
* - symbol: Name of a remote function to call.
* - string: Name of a built-in function to call.
* @param arguments {any}: List of arguments of the function.
* @param is_async {bool}: Flag to call the function asynchronously.
* @return 
* - null: If the call is asynchronous.
* - any: If the call is synchronous.
\
.cmng_api.call:{[channel_;topic;function;arguments;is_async]
  sockets: $[topic ~ `;
    // Broadcast to the channel
    // Ensure the type of sockets is a list of int even if the condition does not hit anything.
    (`int$()), distinct raze exec sockets from CONSUMER_FILTERS where channel = channel_;
    // Specific topic in the channel
    raze CONSUMER_FILTERS[((channel_; topic); (channel_; `all))][`sockets]
  ];
  // built-in funtion is string
  if[10h ~ type function; function: enlist function];
  // Publish to `system_log` channel
  .cmng_api.publish_call_to_system_log[.z.p; channel_; topic; function; arguments];
  $[is_async;
    -25!(sockets; function, arguments);
    sockets @\: function, arguments
  ]
 }

/
* @brief Publish a message applying a filter to a channel and a topic.
* @param channel_ {symbol}: Channel to publish a message.
* @param topic {symbol}: Topic of the message. Null symbol to broadcast to a channel.
* @param message {any}: Message to send.
\
.cmng_api.publish:{[channel_;topic;table;message]
  sockets: $[topic ~ `;
    // Broadcast to the channel
    // Ensure the type of sockets is a list of int even if the condition does not hit anything.
    (`int$()), distinct raze exec sockets from CONSUMER_FILTERS where channel in (channel_; `system_log);
    // Specific topic in the channel
    raze CONSUMER_FILTERS[((channel_; topic); (channel_; `all); (`system_log; `all))][`sockets]
  ];
  -25!(sockets; (`.cmng_api.update; table; (.z.p; topic; MY_ACCOUNT_NAME; message)));
 }

/
* @brief Start a private chat with a specific user.
* @param name {symbol}: User name to connect to the connection manager.
* @param target {symbol}: Target user name to talk with.
* @oaram is_requester {bool}: Flag of whether the caller is a requester.
* @param channel {symbol}: Channel to use for the private chat.
* - null: Arbitrary value for a request.
* - other: Unique value assigned by the connection manager.
\
.cmng_api.start_private_chat:{[name;target;is_requester;channel]

  // If this is a request, overwrite the channel input with a unique value generated on the connection manager.
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
 }

/
* @brief Publish a message to a specific user in private chat.
* @param message {string}: Text message to send.
\
.cmng_api.publish_private: {[target;message]
  .cmng_api.publish[PRIVATE_MESSAGE_CHANNEL target; `user_chat; `MESSAGE_BOX; message]
 }
