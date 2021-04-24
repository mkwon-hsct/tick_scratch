/
* @file server.q
* @overview Answer of the exercises for chapter 5.
* @note This proces must be started with `-U important_file`.
\

// Set port 5000 if not defined.
if[not system "p"; system "p 5000"]; 

/
* @brief Incremental unique ID of client.
\
CLIENT_ID: 0;

/
* @brief Table to manage connection from clients.
\
CONNECTIONS: 1!flip `socket`user`id!"isj"$\:();

/
* @brief Register client connection to `CONENCTIONS` with an unique ID.
\
giveMeID:{[]
  // Register the client.
  `CONNECTIONS upsert (.z.w; .z.u; CLIENT_ID);
  // Call a regoster function on client side.
  neg[.z.w] (`registerID; CLIENT_ID);
  // Increment client ID.
  CLIENT_ID+:1;
 };

/
* @brief Remove client connection from `CONNECTIONS` when a client connection drops.
\
.z.pc:{[client]
  delete from `CONNECTIONS where socket = client;
 };
