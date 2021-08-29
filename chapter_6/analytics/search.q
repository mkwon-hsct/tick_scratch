/
* @file search.q
* @overview Define functions run on databases.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Functions                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Find records with specified topics that falls in a specifed time range.
* @param arguments {dictionary}: Valid keys are below:
* - table {symbol}: Table name.
* - grouping {dictionary}: Map from aggregate name and column name.
* - columns {list of symbol}: Columns to select.
* - keyword {string}: Pattern of a message to search. Optional. Only for `MESSAGE_BOX`.
* - sender {symbol}: Sender of a message to search. Optional. Only for `MESSAGE_BOX`.
* @param topics {list of symbol}: Topics to find a message.
* @param time_range {list of timestamp}: Queried range.
\
history:{[arguments;topics;time_range]
  // HDB uses date as the first filter
  is_hdb: `sym in key `:.;
  where_clause: $[is_hdb; enlist (within; `date; `date$time_range); ()], ((in; `topic; enlist topics); (within; `time; time_range));
  // MESSAGE_BOX allows user to search a message with a keyword.
  if[(arguments[`table] ~ `MESSAGE_BOX) and `keyword in key arguments; where_clause,: enlist (like; `message; arguments `keyword)]; 
  // MESSAGE_BOX allows user to search a message with a sender.
  if[(arguments[`table] ~ `MESSAGE_BOX) and `sender in key arguments; where_clause,: enlist (=; `sender; arguments `sender)]; 
  // Filter out invalid columns
  columns: arguments[`columns] inter cols arguments `table;
  columns: $[count columns; columns!columns; ()];
  // Simple select.
  ?[arguments `table; where_clause; arguments `grouping; columns]
 };
