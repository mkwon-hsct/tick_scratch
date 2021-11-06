/
* @file monitoring.q
* @overview Monitor other processes with a timer in a sub-process. 
\

TARGET_PORT: 5001;

TARGET_SOKET: hopen `$":" sv (""; ""; string TARGET_PORT);
PARENT_SOCKET: (::);

/
* @brief Register the socket of parent process.
\
.z.po:{[socket]
  PARENT_SOCKET::socket;
 };

/
* @brief Check the status of a targeta and trigger a function in the parent process if
*  the target is dancing. 
\
.z.ts:{[now]
  status:TARGET_SOKET "status";
  if[status ~ `dancing;
    // Report to the parent and trigger record function with current time.
    neg[PARENT_SOCKET] "record ", string now;
  ];
 };

// Monitor every second.
\t 1000
