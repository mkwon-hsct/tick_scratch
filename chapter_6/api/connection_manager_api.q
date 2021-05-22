/
* @file connection_manager_api.q
* @overview Define API to access a connection manager.
\

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

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Register channel as a producer. If there are matched consumers, start communication with them.
\
.cmng_api.register_as_producer: {[name;channel]
  matched: CONNECTION_MANAGER_SOCKET (`.cmng.register; name; 1b; channel; (::));
  show matched;
 };

/
* @brief Register channel as a producer. If there are matched consumers, start communication with them.
\
.cmng_api.register_as_consumer: {[name;channel;topics]
  matched: CONNECTION_MANAGER_SOCKET (`.cmng.register; name; 0b; channel; topics);
  show matched;
 };
