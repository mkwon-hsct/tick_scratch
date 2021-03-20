/
* @file query_filtering.q
* @overview
* Example of query filterng by database process.
\

// Load HDB
\l ../chapter_4/hdb

/
* @brief Prohibit anonymous access. 
\
.z.pw:{[username;password]
  (not username ~ `) and not password ~ ""
 };

/
* @brief Probe client query to `trade` table and guard table if unauthorized acccess is found. 
\
query_trade: {[columns; conditions]
  non_admin: not .z.u in `mattew`mark`luke`john;
  if[non_admin;
    // Guard secret columns.
    if[any `stop`cond`ex in columns; '"The secret is still concealed to your eyes..."];
    // Prohibit using secret columns for conditions.
    if[any `stop`cond`ex in raze conditions; '"A goat ate your request in our absence..."]
  ];
  ?[`trade; conditions; 0b; columns!columns]
 };
