/
* @file database.q
* @overview Defines database interface.
\

/
* @brief Error indicator.
\
EXECUTION_STATUS_: enlist `FAILURE;
EXECUTION_FAILURE_: `EXECUTION_STATUS_$`FAILURE;

/
* @brief Busy sleep.
* @param seconds {list of number}: Blocking time in seconds.
* @note Argument comes as enlist seconds.
\
sleep:{[seconds]
  now: .z.p;
  -1 "I will sleep for ", string[seconds], " seconds...";
  while[(`second$first seconds) > .z.p-now; (::)];
  -1 "Awake!!";
  // Always succeeds without any exception.
  neg[.z.w] (`callback; ::; 0b);
 }

/
* @brief Select statement against table.
* @param table_conditions_columns {compound list}: Tuple of (table; conditions; columns).
* - table {symbol}: Table name.
* - conditions {compound list}: List of conditions in functional form.
* - columns {list of symbol}: Column names to extract.
\
extract:{[table_conditions_columns]
  // Expand parameters.
  table: table_conditions_columns 0;
  conditions: table_conditions_columns 1;
  columns: table_conditions_columns 2;
  // Execute select query.
  result: .[?; (table; conditions; 0b; columns!columns); {[error] (EXECUTION_FAILURE_; error)}];
  $[any EXECUTION_FAILURE_ ~/: result;
    // Execution failure
    neg[.z.w] (`callback; result 1; 1b);
    // Execution success
    neg[.z.w] (`callback; result; 0b)
  ];
 }
