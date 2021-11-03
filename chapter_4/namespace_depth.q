/
* @file namespace_depth.q
* @overview Reveal the depth of the namespace.
\

/
* @brief Types of columns of table1
* @keys
* - time: Access time
* - host: Source host
* - user: User name
* - permission: Kind of permission
* @note
* New keys will be added.
\
table1_column_types:`time`host`user`permission!"PSSI";

/
* @brief Types of columns of table2
* @keys
* - time: Trade time
* - sym: Company name
* - price: Traded price
* - size: Traded amount
\
table2_column_types:`time`sym`price`size!"PSFJ";

/
* @brief Root dictionary of column types by table. New table will be added.
\
.depth.column_types:`table1`table2!(table1_column_types; table2_column_types);

-1 "\n<< Show column types of table1 >>\n";

-1 "Column types of table1 under depth namespace";
show @[`.depth; `column_types] `table1;

-1 "Column types of table1 under default namespace";
show @[`.; `.depth.column_types] `table1;

-1 "Column types of table1 via direct access to the object with full name";
show @[`.depth.column_types; `table1];

-1 "Column types of table1 via direct access to the object with full name (get)";
show get[`.depth.column_types] `table1;

-1 "\n<< Add new column to table1 >>\n";

.depth.column_types[`table1]:.depth.column_types[`table1], enlist[`pc_id]!enlist "J";
@[`.depth.column_types; `table1; ,; enlist[`num_login_failure]!enlist "I"];

// Show updated column types of table1
-1 "Updated column types of table1 under depth namespace";
show @[`.depth; `column_types] `table1;

-1 "Updated column types of table1 under default namespace";
show @[`.; `.depth.column_types] `table1;

-1 "Updated column types of table1 via direct access to the object with full name";
show @[`.depth.column_types; `table1];

-1 "Updated column types of table1 via direct access to the object with full name (get)";
show get[`.depth.column_types] `table1;


-1 "\n<< Add new table to root dictionary >>\n";

`.depth.column_types upsert enlist[`table3]!enlist `time`id!"PG";
@[`.depth.column_types; `table4; :; `time`item`amount`discount!"PSIF"];

// Show current dictionary status
-1 ".depth.column_types under depth namespace";
show @[`.depth; `column_types];

-1 ".depth.column_types under default namespace";
show @[`.; `.depth.column_types];


-1 "\n<< Overwrite >>\n";

@[`.; `.depth.column_types; :; `a`b!(1 2 3; "456")];

// Show current dictionary status
-1 ".depth.column_types under depth namespace";
show @[`.depth; `column_types];

-1 ".depth.column_types under default namespace";
show @[`.; `.depth.column_types];

-1 ".depth.column_types via direct access to the object with full name";
show .depth.column_types;

-1 ".depth.column_types via direct access to the object with full name (get)";
show get `.depth.column_types;


-1 "\n<< Add new ket to root dictionary >>\n";

`.depth.column_types upsert enlist[`c]!enlist `7`8;
@[`.depth; `column_types; ,; enlist[`d]!enlist "9012"];
@[`.; `.depth.column_types; ,; enlist[`e]!enlist `Happy];

// Show current dictionary status
-1 "Final .depth.column_types under depth namespace";
show @[`.depth; `column_types];

-1 "Final .depth.column_types under default namespace";
show @[`.; `.depth.column_types];

-1 "Final .depth.column_types via direct access to the object with full name";
show .depth.column_types;

-1 "Final .depth.column_types via direct access to the object with full name (get)";
show get `.depth.column_types;
