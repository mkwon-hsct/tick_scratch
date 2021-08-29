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
* @brief Detect abominable things in a chat message and fire an alert.
* @param channel {symbol}: Channel to publish an alert.
* @param message {variable}:
* - compound list: Tuple of (sender timestamp; topic; sender; message).
* - table: Table whose columns are (sender timestamp; topic; sender; message).
\
detect_abomination:{[channel;message]
  .dbg.message: message;
  $[98h ~ type message;
    // Table 
    if[count flagged: message any each lower[message `message] like/:\: ABOMINATION;
      // Suspicious message was found
      // Publish to tickerplant
      .cmng_api.publish[channel; `alert; `ALERT; `time`sender`sender_time`topic`user xcols update time: .z.p, sender: MY_ACCOUNT_NAME, sender_time: time, user: sender from flagged]
    ];
    // Single row
    if[any lower[last message] like/: ABOMINATION;
      // Suspicious message was found
      // Publish to Tickerplant
      .cmng_api.publish[channel; `alert; `ALERT; (.z.p; MY_ACCOUNT_NAME), message]
    ]
  ];
 };
