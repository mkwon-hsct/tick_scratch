// namespace_trouble.q

// Global
TRAFFIC:`GREEN`YELLOW`RED;
ILLUSION:42;

// Move to namespace 'space1'
\d .space1

/
* @brief Return an instruction according to a traffic signal
* @param signal: Color of the traffic signal. Either of `RED`YELLOW`GREEN
* @type
* - symbol
* @return
* - string
\
instruction:{[signal]
  $[signal ~ @[`.; `TRAFFIC][0];
    "Have a good trip!";
    signal ~ @[`.; `TRAFFIC][1];
    "Stop unless it rather jeoperdizes you or the following car.";
    signal ~ @[`.; `TRAFFIC][2];
    "Stop!!";
    // others
    "Ask HIM what to do."
  ]
 };

// Close namespace 'space1'
\d .