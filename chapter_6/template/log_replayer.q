/
* @file log_replayer.q
* @overview Define functionalities of Log Replayer.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Load schema
\l schema/schema.q
\l utility/load.q
.load.load_file `:api/connection_manager_api.q;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Command line arguments. Valid keys are below:
* - user {symbol}: Account name of this process.
\
COMMANDLINE_ARGUMENTS: @[.Q.opt .z.X; `user; {[arg] `$first arg}];
// Set account name.
MY_ACCOUNT_NAME: COMMANDLINE_ARGUMENTS `user;

/
* @brief Channel to subscribe to Tickerplant. 
\
TICKERPLANT_CHANNEL: `$"log_replayer_", string .z.h;

/
* @brief Channel to produce messages to Intra-day HDB. 
\
INTRADAY_HDB_CHANNEL: `$"intraday_hdb_", string .z.h;

/
* @brief Channel to produce messages to HDB. 
\
HDB_CHANNEL: `$"hdb_", string .z.h;

/
* @brief Path to Intra-day HDB directory.
\
INTRADAY_HDB_HOME: hsym `$getenv[`KDB_INTRADAY_HDB_HOME];

/
* @brief Path to HDB directory.
\
HDB_HOME: hsym `$getenv[`KDB_HDB_HOME];

/
* @brief EOD time in hour.
\
EOD_TIME: "I"$getenv `KDB_EOD_TIME;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Insert a record to a table.
* @param table {symbol}: name of a table.
* @param data {variable}:
*  - compound list: Single record.
*  - table: Bunch of records. 
\
.cmng_api.update:{[table;data]
   table insert data;
 };

/
* @brief Save a table with symbol partitions at intra-day write down.
* @param table {symbol}: Table name.
\
save_table:{[table]
  // Symbol column with which table is partitioned.
  sort_column: TABLE_SORT_KEY table;
  // Get distinct symbol values
  symbols: ?[table; (); (); (distinct; sort_column)];
  // Save the table by spliting it to symbol partitions
  .log.info["save table"; table];
  {[table_;sort_column_;symbol]
    // Partition coincides with the index in `sym`.
    partition: .Q.dd[HDB_HOME; `sym]?symbol;
    // Save as a splayed table under the partition.
    target: .Q.dd[INTRADAY_HDB_HOME; (`int$partition; table_; `)];

    target $[() ~ key target;
      // Target does not exist
      set;
      // Target already exists
      insert
    ] .Q.en[HDB_HOME; ?[table_; enlist (=; sort_column_; enlist symbol); 0b; ()]];
    
    // Delete records with the symbol
    ![table_;  enlist (=; sort_column_; enlist symbol); 0b; `symbol$()];
  }[table; sort_column] each symbols;

 };

/
* @brief Migrate Intra-day HDB data to HDB while creating a new partition.
* @param date {date}: Partition name.
* @param table {symbol}: Name of table to move.
\
move_to_HDB:{[date;table]
  // `:intraday_hdb/partition/table/
  partitions: .Q.dd[INTRADAY_HDB_HOME] each key[INTRADAY_HDB_HOME],/: table, `;
  // Target HDB partition
  target: .Q.dd[HDB_HOME; (date; table; `)];
  // Migrate all partitions to HDB.
  .log.info["move table to HDB"; table];
  {[target_;source]
    target $[() ~ key target;
      // Target does not exist
      set;
      // Target already exists
      insert
    ] get source;
    // Delete unnecessary data
    system "rm -r ", 1 _ string source;
  } each partitions;
 };

/
* @brief Delete data in tables at the rolling of log file.
* @param logfile {symbol}: Handle to the log file cut off by the tickerplant. Not used on RDB side.
\
task_at_rolling_logfile:{[logfile]
  // Replay log file.
  -11!logfile;
  // Save tables
  save_table each TABLES_IN_DB;
  // Parse yyyymmdd_HH.log into (date; hour);
  date_hour: "DI"$' "_" vs first "." vs string[logfile];
  // Move Intra-day HDB data to HDB at EOD.
  if[date_hour[1] = EOD_TIME -1;
    .log.info["End of day"; ::];
    move_to_HDB[date_hour 0] each TABLES_IN_DB;
    // Notify HDB the completion of EOD procedure.
    .cmng_api.call[HDB_CHANNEL; `; `reload; enlist (::); 1b]
  ];
  // Fill missing tables
  .Q.chk INTRADAY_HDB_HOME;
  // Notify Intra-day HDB the completion of disk write.
  .cmng_api.call[INTRADAY_HDB_CHANNEL; `; `reload; enlist (::); 1b];
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Start Process                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Register as a downstream of Tickerplant
.cmng_api.register_as_consumer[MY_ACCOUNT_NAME; TICKERPLANT_CHANNEL; enlist `all];

// Register as a producer of Intraday-HDB channel.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; INTRADAY_HDB_CHANNEL];

// Register as a producer of HDB channel.
.cmng_api.register_as_producer[MY_ACCOUNT_NAME; HDB_CHANNEL];
