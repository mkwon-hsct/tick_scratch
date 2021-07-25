/
* @file schema.q
* @overview Define schemas to be loaded by Tickerplant, RDB and Log Replayer
*  and others if necessary.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                        Schema                         //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief List of tables sotred in database.
\
DATABASE_TABLES: enlist `MESSAGE_BOX;

/
* @brief Table for user chat messages.
* @column time {timestamp}: Time when a message was received by a recipient.
* @column topic {symbol}: Topic of the message.
* @column sender {symbol}: Sender of the message.
* @column message {string}: Message itself.
\
MESSAGE_BOX:: flip `time`topic`sender`message!"pss*"$\: ();
