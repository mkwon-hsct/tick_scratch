/
* @file parallel.q
* @overview
* Example of thread execution.
\

/
* @brief Busy sleep for a second.
* @note
* Worker thread cannot use system call.
\
sleep:{[]
  now:.z.p;
  while[00:00:01 > .z.p-now; (::)];
 };

/
* @brief Display ID of thread every second. 
\
who_are_you:{[i]
  do[10; -1 "thread ", string i; sleep[]];
 };

/
* @brief Sum million random numbers. 
\
sum_million_rand:{[] sum 1000000?10};

/
* @brief Raise to 3.
* @param num {number}
* @return
* - number 
\
power3:{[num] num xexp 3};

/
* @brief Rejoice when the number is a multiple of 7.
* @param num {number}
* @return
* - symbol: `number` is a multiple of 7.
* - general null: `number` is not a multiple of 7.
\
happy7:{[num] (`happy; ::; ::; ::; ::; ::; ::) num mod 7};
