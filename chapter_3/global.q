/
* @file global.q
* @overview Example of modifying a global variable.
\

// System status
STATUS: `Clean;

// Record of suspicious access
SUSPICIOUS_ACCESS: ();

// Counter of trials to change status
total: 0;

/
* @brief
* Increment the counter of visitors.
\
enter:{[]
  -1 "Hello.";
  total::total+1;
 };

/
* @brief
* Change status of system to a passed value. Access count is incremented.
* @param status {symbol}: Target status. Either of `Clean or `Unclean.
\
change_status:{[status]
  // Increment the number of visitors
  enter[];
  $[status in `Clean`Unclean;
    // Valid status
    [
      // Change status
      STATUS::status;
      -1 "status of system was changed: ", string status
    ];
    // Invalid status
    [
      // Add information of timestamp, status and user
      SUSPICIOUS_ACCESS,:enlist (.z.p; status; .z.u);
      -1 "Suspicious activity to change system status to unknown value: ", string status
    ]
    
  ];
 };

/
* @brief
* Calculate total payment of items in basket based on an amount of items and their prices.
* @param prices {list of float}: Prices of items in the basket.
* @note
* Catastorophic!! `total` used inside this function overwrites the global variable `total`.
* Also a new global discount was created!!
\
calc_basket:{[prices]
  // Ensure `prices` is a list
  prices,:();
  discount::$[1 >= count prices; 0; 3 >= count prices; 0.2; 0.3];
  total::0;
  STATUS::`Received;
  -1 string[STATUS], ". discount rate: ", string discount;
  {[price]
    STATUS::`IN_PROGRESS;
    total::total + (1-discount) * price;
    -1 "subtotal: ", string[total];
  } each prices;
  STATUS::`Done;
  -1 string[STATUS], ". total payment is: ", string total;
 };
