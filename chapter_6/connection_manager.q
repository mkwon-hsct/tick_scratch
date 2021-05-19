/
* @file connection_manager.q
* @overview Define functionalities of connection manager.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Open port defined in `connection_manager.config`.
{[]
  managers: read0 `:config/connection_manager.config;
  system "p ", last ":" vs managers first where managers like\: string[.z.h], "*";
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Table for managing settings of message producer.
\
PRODUCER: flip `name`host`port`channel!"s**s"$\:();

/
* @brief Table for managing settings of message consumer.
\
CONSUMER: flip `name`host`port`channel`topic!"s**s*"$\:();

/
* @brief Table managing connection between producer and consumer.
\
CONNECTION: flip `producer`consumer!"ss"$\:():

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Load accounts of processes. 
\
load_accounts:{[]
  {[name;val] setenv[`$name; val]} ./: ":" vs/: read0 `:config/account.config;
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
  host_port: getenv each string[name],/: ("_host"; "_port");
  $[side;
    // Producer
    [
      `PRODUCER insert (name; host_port 0; host_port 1; channel_);
      // Return matched consumer information
      select from CONSUMER where channel = channel_
    ]
    // Consumer
    [
      `CONSUMER insert (name; host_port 0; host_port 1; channel_; topics_);
      // Return matched producer information
      select from PRODUCER where channel = channel_
    ]
  ]
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Load accounts.
load_accounts[];
