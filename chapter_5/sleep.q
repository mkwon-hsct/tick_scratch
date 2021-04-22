/
* @file sleep.q
* @overview
* Define sleep function.
\

/
* @brief Busy sleep for given seconds.
* @param sec {number}: Sleep period in seconds.
* @note
* Worker thread cannot use system call.
\
sleep:{[sec]
  now:.z.p;
  while[(`second$sec) > .z.p-now; (::)];
 };
