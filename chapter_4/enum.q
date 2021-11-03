/
* @file: enum.q
* @overview: Provide examples of using enum in functions.
\

/
* @brief Options for the bird function.
\
BIRD_OF_PREY_:`Eagle`Vulture`Hawk;
EAGLE_:`BIRD_OF_PREY_$`Eagle;
VULTURE_:`BIRD_OF_PREY_$`Vulture;
HAWK_:`BIRD_OF_PREY_$`Hawk;

/
* @brief Unique error indicator for executing a function.
\
EXECUTION_STATUS_:`success`failure;
FAILURE_:`EXECUTION_STATUS_$`failure;

/
* @brief Return a message including a name of a bird according to the number.
* @param bird {number}: One of 0-2 indicating a kind of a bird:
* - 0: Eagle
* - 1: Vulture
* - 2: Hawk
* @return string
\
naive_bird:{[bird]
  if[not bird in 0 1 2; '"Not a bird of prey"];
  name:string BIRD_OF_PREY_ bird;
  $[bird ~ 0;
    name, " is the King in the sky!!";
    bird ~ 1;
    name, " is a common bird.";
    // bird ~ 2;
    "Lucky to see ", name, "!"
  ]
 }

/
* @brief Return a message including a name of a bird according to the number.
* @param bird {enum}: Enum value indicating a kind of a bird:
* - `EAGLE_`
* - `VULTURE_`
* - `HAWK_`
* @return string
\
enum_bird:{[bird]
  name:string value bird;
  $[bird ~ EAGLE_;
    name, " is the King in the sky!!";
    bird ~ VULTURE_;
    name, " is a common bird.";
    // bird ~ HAWK_;
    "Lucky to see ", name, "!"
  ]
 }

/
* @brief Try to execute `blackbox` function.
* @return 
* - string: Error message from `blackbox`.
* - any: Successful result from `blackbox`.
\
naive_handler:{[coin]
  result:@[blackbox; coin; {[err] (`failure; err)}];
  $[`failure ~ first result; result 1; result]
 }

/
* @brief Try to execute `blackbox` function.
* @return 
* - string: Error message from `blackbox`.
* - any: Successful result from `blackbox`.
\
enum_handler:{[coin]
  result:@[blackbox; coin; {[err] (FAILURE_; err)}];
  $[FAILURE_ ~ first result; result 1; result]
 }

/
* @brief Randomly generate `success` or `failure` value `coin` times and take last two values.
* @param coin {number}: The number of coin toss.
* @return dicitionary: Dictionary of result which is one of `success` or `failure. Keys are:
*  - a: First lot
*  - b: Secod lot
* @note 777 is an easter egg number returning error.
\
blackbox:{[coin]
  if[coin = 777; '"Unlucky!!"];
  `a`b!-2#coin?`success`failure 
 }
