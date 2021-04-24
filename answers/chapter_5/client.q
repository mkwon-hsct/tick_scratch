/
* @file client.q
* @overview Answer of the exercises for chapter 5.
* @note This process must be started with:
*   q client.q -user peter -password churchontherock
\

/
* @brief Commandline arguments.
\
COMMANDLINE_ARGS: .Q.opt .z.X;

/
* @brief Connection handle of the server process.
\
SERVER_HANDLE: `$":" sv (""; ""; "5000"; first COMMANDLINE_ARGS `user; first COMMANDLINE_ARGS `password);

/
* @brief Client ID assigned to this process. 
\
MY_ID: 0;

/
* @brief Register client ID assigned by a server to this process.
* @param id {long}: Client ID assigned by a server.
\
registerID:{[id] MY_ID::id;};

/
* @brief Retry to connect with a timer.
\
.z.ts:{[now]
  connected: @[hopen; SERVER_HANDLE; {[error] error}];
  $[10h ~ type connected;
    // Connection failure. We know socket type is int.
    -2 string[now], " ### ", connected;
    [
      -1 string[now], " ### Connected!!";
      // Stop timer
      system "t 0";
      SERVER_SOCKET:: connected;
      // Register this process.
      neg[SERVER_SOCKET] (`giveMeID; ::)
    ]
  ];
 };

.z.pc:{[server]
  -2 "Oh no!! Server connection dropped!!";
  // Start timer
  system "t 1000";
 };

// Connect to a server. One of followings:
// `::5000:peter:churchontherock
// `::5000:jacob:faithwithoutactionisdead
// `::5000:phillip:wannaseethefather
SERVER_SOCKET: hopen SERVER_HANDLE;

// Register this process to a server.
neg[SERVER_SOCKET] (`giveMeID; ::);
