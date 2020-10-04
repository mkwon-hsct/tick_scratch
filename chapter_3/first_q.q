// first_q.q

a:42 //a is now 42
/
These lines are ignored
a: 100
\
//"show" writes the argument to standard out
show a;

// Continue the expression to the next line
b: 1 + 2 + 3 + 4 + 5 + 6 /
    + 7 + 8 + 9 + 10;

// Display the value of b
show b;

func:{[x]
  res: 1+x;
  //0N![string]; outputs the string to standard out.
  0N!"x is ", string x;
  res
 }
 