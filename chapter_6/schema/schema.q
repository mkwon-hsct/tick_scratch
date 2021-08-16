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
TABLES_IN_DB: `MESSAGE_BOX`CALL;

/
* @brief Table for user chat messages.
* @column time {timestamp}: Time when a message was received by a recipient.
* @column topic {symbol}: Topic of the message.
* @column sender {symbol}: Sender of the message.
* @column message {string}: Message itself.
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
