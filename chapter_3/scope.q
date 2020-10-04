// scope.q

// Global
a:42;
global_f:{[arg] -1 "Global. Passed argument was: ", string arg;};

/
* @brief Add globally defined 'a' to num
* @param num: some number
* @type long
* @return
* - long
\
add_global_a:{[num]
  a+num
 }

/
* @brief Add locally defined 'a' to num
* @param num: some number
* @type long
* @return
* - long
\
add_local_a:{[num]
  // Hides globaly defined 'a'
  a:100;
  a+num
 }

/
* @brief Show the passed argument with a global function
* @param arg: Argument to print
* @type any atom 
* @return
* - general null
\
print:{[arg]
  global_f[arg]
 }

/
* @brief Try to use locally defined 'b' inside a local function.
* @param num: some number
* @type long
*
* This function should fail
\
add_b_fail:{[num]
  // Define local variable
  b:42;
  // Cannot use 'b'
  {[x] b + x}[num]
 }

/
* @brief Use locally defined 'b' inside a local function by passing it as an argument of the function
* @param num: some number
* @type long
* @return
* - long
\
add_b_success:{[num]
  // Define local variable
  b:42;
  // Pass 'b' as an argument
  {[x;y] x+y}[b; num]
 }