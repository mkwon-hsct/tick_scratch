/
* @file basic_ipc_process1.q
* @overview Provide examples of event handlers for process1.
\

/
* @brief Notify an arrival of a new asynchronous message and execute it.
* @param query {any}: 
* - string: Text query.
* - compound list: Functional query.
\
.z.ps:{[query]
  -1 "New message from the socket: ", string[handle];
  value query
 }