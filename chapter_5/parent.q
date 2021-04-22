/
* @file parent.q
* @overview Example of monitoring using a sub-process.
\

// Start a sub-process.
\q monitoring.q -p 5000

// Load sleep function.
\l sleep.q

/
* @brief Murmur for a suspicious activity of a target.
* @param time {timestamp}: Time when sub-process checked the target.
\
record:{[time]
 -1 "Why was he dancing at ", string[time], " while I was sleeping?";
 };

// Wait until subprocess becomes ready.
sleep 1;

// Connect to the subprocess.
socket:hopen `::5000;
