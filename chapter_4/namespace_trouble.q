/
* @file namespace_trouble.q
* @overview "Globally" define variables and functions. This file is intended to be loaded by another file.
\

// Global
TRAFFIC: `GREEN`YELLOW`RED;
ILLUSION: 42;

// Move to namespace `space1`
\d .space1

/
* @brief Return an instruction according to a traffic signal
* @param signal {symbol}: Color of the traffic signal. One of `RED`YELLOW`GREEN
* @return string
\
instruction:{[signal]
  $[signal ~ @[`.; `TRAFFIC][0];
    "Have a good trip!";
    signal ~ @[`.; `TRAFFIC][1];
    "Stop unless it rather jeoperdizes you or the following car.";
    signal ~ @[`.; `TRAFFIC][2];
    "Stop!!";
    // others
    "Do it well."
  ]
 };

// Close namespace `space1`
\d .
