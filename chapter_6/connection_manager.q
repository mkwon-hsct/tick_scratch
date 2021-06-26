/
* @file connection_manager.q
* @overview Define functionalities of connection manager.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:utility/log.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Dictionary of sockets of connection managers.
* @keys
* Handles of connection detail.
* @values
* Sockets of the connection managers.
\
CONNECTION_MANAGERS: ()!`int$();

/
* @brief Table for managing settings of message producer.
* @columns
* - socket {int}: Socket of a client.
* - name {symbol}: Account name of the client.
* - host {string}: Host of the client account.
* - port {string}: Port of the client account.
* - channel {symbol}: Registered channel of the client.
\
PRODUCER: flip `socket`name`host`port`channel!"is**s"$\:();

/
* @brief Table for managing settings of message consumer.
* @columns
* - socket {int}: Socket of a client.
* - name {symbol}: Account name of the client.
* - host {string}: Host of the client account.
* - port {string}: Port of the client account.
* - channel {symbol}: Registered channel of the client.
* - topics {list of symbol}: Registered topics of the client.
\
CONSUMER: flip `socket`name`host`port`channel`topics!"is**s*"$\:();

/
* @brief Table managing connection between producer and consumer.
* @columns
* - producer {symbol}: Account name of a producer.
* - consumer {symbol}: Account name of a consumer.
\
CONNECTION: flip `producer`consumer!"ss"$\:();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register the socket of the connection manager who called this function remotely.
* @param host {string}: Host of the caller.
* @param port {string}: Port of the caller. 
\
register_connection_manager:{[host;port]
  handle: hsym `$":" sv (host; port);
  .log.info["peer connection manager notified of a new connection"; handle];
  CONNECTION_MANAGERS[handle]: .z.w;
 };

/
* @brief Connect to a peer connection manager and register the socket if
*  the attempt is successful.
* @param peer {symbol}: Handle composed of [host]:[port].
\
connect_peer_manager:{[peer]
  handle: `$":", peer;
  socket: $[handle in key CONNECTION_MANAGERS;
    // Already connected.
    (::);
    // New connection.
    // Null if connection failed.
    @[hopen; handle; {[error] (::)}]
  ];
  if[not socket ~ (::);
    // New connection was established.
    .log.info["connected to a peer connection manager"; handle];
    CONNECTION_MANAGERS[handle]: socket;
    //　Notify the target of the new connection.
    socket (`register_connection_manager; string .z.h; string system "p");
    // Receive client information from the connection manager.
    `PRODUCER insert update socket: 0Ni from socket (get; `PRODUCER);
    `CONSUMER insert update socket: 0Ni from socket (get; `CONSUMER)
  ];
 };

/
* @brief Register a producer.
* @param socket {int}: Socket of a local producer or null if it is a propagated information.
* @param name {symbol}: Account name of the client.
* @param host {string}: Host of the client.
* @param port {string}: Port of the client.
* @param channel {symbol}: Registered channel of the client.
\
register_producer:{[socket;name;host;port;channel]
  `PRODUCER insert (socket; name; host; port; channel);
 };

/
* @brief Register a consumer.
* @param socket {int}: Socket of a local producer or null if it is a propagated information.
* @param name {symbol}: Account name of the client.
* @param host {string}: Host of the client.
* @param port {string}: Port of the client.
* @param channel {symbol}: Registered channel of the client.
* @param topics {list of symbol}: registered topics of the consumer.
\
register_consumer:{[socket;name;host;port;channel;topics]
  `CONSUMER insert (socket; name; host; port; channel; topics);
 };

/
* @brief Delete a record of a client who dropped in a remote host.
* @param host_ {string}: Host of the client.
* @param port_ {string}: Port of the client.
\
delete_client:{[table;host_;port_]
  delete from table where (host,' port) ~\: (host_, port_);
 };

/
* @brief Load accounts of processes. 
\
load_accounts:{[]
  {[name;val] setenv[`$name; val]} ./: ":" vs/: read0 `:config/account.config;
 };

/
* @brief Delete a record of the dropped client from producer and consumer table.
* @param socket_ {int}: Socket of the dropped client.
\
.z.pc:{[socket_]

  $[
    not ` ~ handle: CONNECTION_MANAGERS?socket_;
    [
      // Socket of a connection manager.
      .log.info["peer connection manager dropped"; handle];
      // Delete the record of the connection manager.
      CONNECTION_MANAGERS _: handle;
      // Escape
      :()
    ];

    // dropped_producer is ("some_host"; "some_port") or ((); ())
    count first dropped_producer: first each exec (host; port) from PRODUCER where socket=socket_;
    [
      // Socket of a producer.
      delete from `PRODUCER where socket=socket_;
      // Propagate the information to remote connection managers
      neg[value CONNECTION_MANAGERS] @\: (`delete_client; `PRODUCER; dropped_producer 0; dropped_producer 1);
      // Escape
      :()
    ];
    
    [
      // Socket of a consumer.
      count first dropped_consumer: first each exec (host; port) from CONSUMER where socket=socket_;
      delete from `CONSUMER where socket=socket_;
      // Propagate the information to remote connection managers
      neg[value CONNECTION_MANAGERS] @\: (`delete_client; `CONSUMER; dropped_consumer 0; dropped_consumer 1)
    ]
  ];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register a client as producer or consumer with channel (and topics). Called synchronously.
* @param name {symbol}: Account name.
* @param side {bool}: Producer or consumer.
* - true: Producer
* - false: Consumer 
* @param channel_ {symbol}: Channel name.
* @param topics_ {symbol list}: Topic names.
* @return 
* - table: Matched consumer/producer information.
\
.cmng.register:{[name;side;channel_;topics_]
  host_port: getenv each `$string[name],/: ("_host"; "_port");
  if["" ~ host_port 0; neg[.z.w] (show; "Who are you?"); :()];
  $[side;
    // Producer
    [
      .log.info["add ", string[name], " as a producer"; channel_];
      register_producer[.z.w; name; host_port 0; host_port 1; channel_];
      // Propagate the information to the remote connection managers 
      value[CONNECTION_MANAGERS] @\: (`register_producer; 0Ni; name; host_port 0; host_port 1; channel_);
      // Return matched consumer information
      select name, host, port, channel, topics from CONSUMER where channel = channel_
    ];
    // Consumer
    [
      .log.info["add ", string[name], " as a consumer"; (channel_; topics_)];
      register_consumer[.z.w; name; host_port 0; host_port 1; channel_; topics_];
      // Propagate the information to the remote connection managers 
      value[CONNECTION_MANAGERS] @\: (`register_consumer; 0Ni; name; host_port 0; host_port 1; channel_; topics_);
      // Return matched producer information
      select name, host, port, channel from PRODUCER where channel = channel_
    ]
  ]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Load accounts.
load_accounts[];

{[]
  managers: read0 `:config/connection_manager.config;
  // Open self port defined in `connection_manager.config`.
  system "p ", last ":" vs managers self: first where managers like\: string[.z.h], "*";
  // Connect to peer connection managers and receive information of `PRODUCER` and `CONSUMER`.
  connect_peer_manager each managers except[til count managers; self];
 }[];

