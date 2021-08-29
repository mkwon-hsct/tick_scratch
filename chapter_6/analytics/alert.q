/
* @file alert.q
* @overview Define functions run on engines.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

ABOMINATION: ("*death*"; "*crow*"; "*vulture*"; "*chameleon*"; "*grasshopper*"; "*lizard*"; "*mouse*");

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                       Functions                       //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
: @brief Detect abominable things in a chat message and fire an alert.
* @param message {variable}:
* - compound list: Tuple of (sender timestamp; topic; sender; message).
* - table: Table whose columns are (sender timestamp; topic; sender; message).
\
detect_abomination:{[message]
  $[98h ~ type message;
    // Table 
    if[count flagged: message any each lower[message `message] like/:\: ABOMINATION;
      // Suspicious message was found
      // 
      .cmng_api.publish[`non_existing; `alert; `ALERT; flagged]
    ];
    // Single row
    if[any lower[last message] like/: ABOMINATION; message;
      // Suspicious message was found
      .cmng_api.call[`non_existing; `alert; `ALERT; message]
    ]
  ];
 };
