// ifelse.q

a:42;

// Change has been done but return nothing
case1:if[a > 0; a:10000; a];
show case1 ~ (::);

// Escaped local value is returned
case2:{[x] if[x > 0; x:300; :x];}[a]
show case2;

// Display values to standard out
if[a > 0; show a; a:500; -1 string a; a:700];

// Show current value
show a;

// Different types of values can be returned
case3:$[a > 0; `its_true; "Unfortunately it was false..."];
show case3;

case4:$[a <= 0;
  [a:"This line is not executed"; "Woops,", a];
  [-1 "Oh no, a is negative!!"; a:(0b; "a is no longer what you saw before."); a[1],: " bluh bluh..."; a]
 ];

show case4;

// Intentionally returns an error
/
* @brief Returns error if type of 'arg' is neither a long nor a list of long
* @param arg: Argument to check its type
* @type
* - any type
* @return
* - string IF 'arg' is either of a long or a long of list
* - error IF 'arg' is neither a long nor a list of long
\
only_long:{[arg]
  $[type[arg] in -7 7h;
    string arg;
    '"The argument must be either of a long or a list of long"
  ]
 };