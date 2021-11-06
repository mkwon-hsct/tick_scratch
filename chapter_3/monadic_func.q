/
* @file monadic_func.q
* @overview Example of monadic function.
\

/
* @brief Add 1 to an argument.
* @param num {long | list of long | float | list of float}: some number.
* @return
* - (list of) long IF 'num' is long
* - (list of) float IF 'num' is float
* @note This should cause an error when symbol or char is passed .
\
add_one:{[num]
  1+num
 }

// func[arg]
0N!"add_one[42]";
a: add_one[42];
show a;

// func arg
0N!"Do: add_one 42";
a: add_one 42;
show a;

// func @ arg
0N!"Do: add_one @ 42";
a: add_one @ 42;
show a;

// Since @ is a dyadic function
// we can use "each-right" with it
0N!"Do: add_one @/: (42 43; 1 2f)";
a: add_one @/: (42 43; 1 2f);
show a;

// @[func; arg]
0N!"Do: @[add_one; 42]";
a: @[add_one; 42];
show a;

// @[func; arg; catch_func]
0N!"Do: @[add_one; `a; {[err] \"Catastrophic!: \", err}]";
a: @[add_one; `a; {[err] "Catastrophic!: ", err}];
show a;

func:{[x]
  res: 1+x;
  //0N![string]; displays the string in standard out.
  0N!"x is ", string x;
  res
 }
