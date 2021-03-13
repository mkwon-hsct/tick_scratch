/
* @file: 2.q
* @overview: Provide examples of event handlers for process2.
\

// Open port 5000
system "p 5000";

/
* @brief Does authetication with user name and password.
* @param username {symbol}: Username.
* @param password {string}: Password.
\
.z.pw:{[username;password] (username in `mattew`john`mark`luke) and password ~ "ZXRlcm5hbF9saWZl"}

/
* @brief Notice handle open on console and send back greetings to the client.
* @param socket {int}: Client handle.
\
.z.po:{[socket]
  -1 "Your client ", string[.z.u], " came in. He is ready at socket ", string[socket];
  neg[socket] "show \"Welcome ", string[.z.u], ".\"";
  }

/
* @brief Notice handle close.
* @param socket {int}: Client handle.
\
.z.pc:{[socket]
  -1 "Sir, お客様がお帰りです。Socket ", string[socket], " is now closed.";
 }

/
* @brief Notice an arrival of a synchronous message from some user and sends bask response.
* @param query {dynamic}
* - string: Text query.
* - compound list: Functional query.
\
.z.pg:{[query]
  -1 "Sir, ", string[.z.u], "が緊急のご要望をお持ちです。";
  -1 "なんだって？こんなに忙しいというのに。やむを得んな。";
  neg[.z.w] "show \"Wait for a moment.\"";
  value query
 }

/
* @brief Notice an arrival of an asynchronous message from some user and sends bask response after executing it.
* @param query {dynamic}
* - string: Text query.
* - compound list: Functional query.
\
.z.ps:{[query]
  -1 "New message from ", string[.z.u];
  // Execute the query.
  // ";" is fine because asynchronous call should complete inside this process.
  value query;
  neg[.z.w] "show \"I am OOO til I get ready to send back.\"";
 }