/
* @file server.q
* @overview Define port and table. 
\

// Set default port 5000
if[not system "p"; system "p 5000"];

/
* @brief Table to receive data from a client. Each column does not
*  have any particular meaning. 
\
nothing: flip `time`country`byte`amount`flag!"psxjc"$\:();
