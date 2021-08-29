/
* @file schema.q
* @overview Define schemas to be loaded by Tickerplant, RDB and Log Replayer
*  and others if necessary.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                        Schema                         //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief List of tables stored in a database.
\
TABLES_IN_DB: `MESSAGE_BOX`CALL`ALERT;

/
* @brief Table for user chat messages.
* @columns
* - time {timestamp}: Time when a message was received by a recipient.
* - topic {symbol}: Topic of a message.
* - sender {symbol}: Sender of a message.
* - message {string}: Message itself.
\
MESSAGE_BOX: flip `time`topic`sender`message!"pss*"$\: ();

/
* @brief Table to store a remote function call.
* @columns
* - time {timestamp}: Time when the function was called on the caller side.
* - caller {symbol}: Caller of the function. 
* - channel {symbol}: Context channel of the call.
* - topic {symbol}: Context topic of the call.
* - function {symbol}: Name of a function.
* - arguments {compound list}: Argumentf passed to the function.
\
CALL: flip `time`caller`channel`topic`function`arguments!"pssss*"$\:();

/
* @brief Table for suspicious chat messages.
* @columns
* - time {timestamp}: When this message was sent by an engine.
* - sender {symbol}: Name of an engine.
* - sender_time {timestamp}: Time when a message was sent by a user.
* - topic {symbol}: Topic of a message.
* - user {symbol}: Name of the user who sent a message.
* - message {string}: Message itself.
\
ALERT: flip `time`sender`sender_time`topic`user`message!"pspss*"$\: ();

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                        Sort Key                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Keys to sort tables at intra-day write down. 
* @key symbol: Table name.
* @value symbol: Column name used to sort a table.
\
TABLE_SORT_KEY: .[!] flip ( /
  (`MESSAGE_BOX; `topic); /
  (`CALL; `caller); /
  (`ALERT; `user) /
 );
