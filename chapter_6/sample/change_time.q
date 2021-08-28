/
* @file change_time.q
* @overview Define functions to change the start time of Intra-day HDB data.
\

/
* @brief Find all time column file under the specified directory.
* @param directory {symbol}: Path to a directory in which time column files are searched.
\
find_time:{[directory]
  $[directory ~ children: key directory;
    // file
    $[`time ~ last ` vs directory; directory; `symbol$()];
    // directory
    raze {[current;child] find_time .Q.dd[current; child]}[directory] each children
  ]
 };

/
* @brief Change start time of all tables in the specified directory.
* @param start_time {timestamp}: Target start time from when timestamp of data starts.
* @param directory {symbol}: Path to a directory in which time column files are searched.
\
change_time:{[start_time; directory]
  {[start_time;file]
    timestamps: get file;
    file set $[1 < count timestamps;
      start_time, start_time + 1 _ deltas timestamps;
      1 = count timestamps;
      enlist start_time;
      // 0 = count timestamps
      `timestamp$()
    ];
  }[start_time] each find_time directory;
 };
