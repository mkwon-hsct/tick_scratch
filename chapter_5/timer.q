/
* @file timer.q
* @overview
* Example of concurrent timer events.
\

/
* @brief Possible status of signal.
\
STATUS: `green`yellow`red;

/
* @brief Status of traffic signal.
\
SIGNAL: `green;

/
* @brief Existence of an accident.
\
IN_ACCIDENT: 0b;

/
* @brief Table of instructions to execute with a timer. Items are:
* - instruction {symbol}: Name of the function.
* - args {compound list}: List of arguments of the function.
* - interval {long}: Interval to execute the function.
* - next_execution {timestamp}: Next scheduled time.
* - active {bool}: Indicator of whether the instruction is active or not.
\
INSTRUCTIONS: flip `instruction`args`interval`next_execution`active!"s*jpb"$\:();

/
* @brief Last time when the timer ticked.
\
LAST_EXECUTION_TIME:0Np;

/
* @brief Switch traffic signal.
* @param current_signal {symbol}: Current status of the signal.
\
switch:{[current_signal]
  // Change signal.
  SIGNAL::first 1? STATUS except current_signal;
  -1 "Signal is: ", string SIGNAL;
 };

/
* @brief Go or stop according to the traffic signal and existence of an accident.
\
go: {[signal; in_accident]
  show signal;
  $[(signal in `green`yellow) and not IN_ACCIDENT;
    -1 "Go!!";
    -2 "What a misfortune..."
  ];
 };

/
* @brief Register an instruction executed by a timer.
* @param name {symbol}: Name of the function.
* @param args {compound list}: List of arguments of the function.
* @param interval {number}: Interval of execution in milliseconds.
* @param active {bool}: Indicator of whether the instruction is active or not.
\
register_instruction:{[name; args; interval; active]
  next_execution: $[null LAST_EXECUTION_TIME; 0Np; LAST_EXECUTION_TIME+`timespan$1e9 + interval % 1000];
  `INSTRUCTIONS insert (name; args; `long$interval; next_execution; active);
 };

/
* @brief Remove an instruction from a timer execution list.
\
remove_instruction:{[name]
  delete from `INSTRUCTIONS where instruction = name;
 };

/
* @brief Change the traffic signal to red and deactivate `switch` function.
\
maintenance:{[]
  // Change the traffic signal to red.
  SIGNAL:: `red;
  // Deactivate `switch` function.
  update active: 0b from `INSTRUCTIONS where instruction = `switch;
  -1 "In mentenace. Sorry for inconvenience m(_ _)m";
 };

/
* @brief Timer event to generate an accident randomly and executes instructions in time.
\
.z.ts:{[now]
  if[null LAST_EXECUTION_TIME;
    update next_execution: now + `timespan$1e9 + interval % 1000 from `INSTRUCTIONS;
    LAST_EXECUTION_TIME::now;
    :()
  ];
  IN_ACCIDENT:: first 1?01b;
  -1 string[now], $[IN_ACCIDENT; " ### Accident!! Close the road!!"; " ### Clear road, clear sky."];
  to_run: exec instruction, args, i from INSTRUCTIONS where active and next_execution <= now;
  if[0 = count to_run `x; :()];
  // Retrieve values under variable names and execute with them.
  {[pair] .[pair 0; get each pair 1]} each flip to_run `instruction`args;
  update next_execution: now + `timespan$1e9 * interval % 1000 from `INSTRUCTIONS where i in to_run[`x];
  LAST_EXECUTION_TIME::now;
 };
