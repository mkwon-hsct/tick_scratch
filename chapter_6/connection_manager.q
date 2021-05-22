/
* @file connection_manager.q
* @overview Define functionalities of connection manager.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q
.load.load_file `:utility/log.q;

// Open port defined in `connection_manager.config`.
{[]
  managers: read0 `:config/connection_manager.config;
  system "p ", last ":" vs managers first where managers like\: string[.z.h], "*";
 }[];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

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
* @brief Load accounts of processes. 
\
load_accounts:{[]
  {[name;val] setenv[`$name; val]} ./: ":" vs/: read0 `:config/account.config;
 };

/
* @brief Delete a record of the dropped client from producer and consumer table.
* @param socket {int}: Socket of the dropped client.
\
.z.pc:{[socket_]
  delete from `PRODUCER where socket=socket_;
  delete from `CONSUMER where socket=socket_;
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Interface                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register a client as producer or consumer with channel (and topics). Called symchronously.
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
      `PRODUCER insert (.z.w; name; host_port 0; host_port 1; channel_);
      // Return matched consumer information
      select name, host, port, channel, topics from CONSUMER where channel = channel_
    ];
    // Consumer
    [
      .log.info["add ", string[name], " as a consumer"; (channel_; topics_)];
      `CONSUMER insert (.z.w; name; host_port 0; host_port 1; channel_; topics_);
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
