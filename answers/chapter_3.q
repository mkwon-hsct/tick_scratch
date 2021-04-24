/
* @file chapter_3.q
* @overview Anser keys for the exercises of chapter 3.
\

// Expand  width of console
\c 25 200

exercise_1: (7*; "D"$) @' (7; "4 Jan, 2020");

exercise_2:{[name; grp]
  $[
    // Invalid name
    name like "S*"; ['"Name starting from S is invalid: ", string name];
    // Invalid group
    not grp in "NO"; ['"Invalid group: ", grp];
    // Valid case
    [string[name], " from ", grp]
  ]
 };

exercise_3:{[err]
  $[
    // Name Error
    err like "Name *"; ["Name Error >> ", err];
    // Group Error
    err like "Invalid group *"; ["Group Error >> ", err];
    // Other Error
    ["Unknown Error >> ", err]
  ]
 };

// Apply exercise_2 to each pair of (name; group) with exercise_3 an error catch function
.[exercise_2; ; exercise_3] each flip (`Jacob`Joshua`Graham`David`Mattew`Peter`Samuel; "NOXONNO")

exercise_4:{[num]
  // Collatz sequence generator
  collatz_gen:{[seq]
    $[
      // Even
      0 = last[seq] mod 2; [seq, last[seq] % 2];
      // Odd
      [seq, 1 + 3 * last seq]
    ]
  };
  // Iterate until last element becomes 1 or the length of the sequence becomes larger than 20
  (collatz_gen/)[{[seq] (not last[seq] = 1) and 20 > count[seq]}; num]
 };

exercise_4 110

exercise_4 12

exercise_5:{[truefalse; true_seq; false_seq]
  inner:{[seq; true_val; false_val]
    // Replace first non-boolean value.
    // Use if-else to decide which value to substitute.
    @[seq; first where -1h = type each seq; {[true_val_; false_val_; which] $[which; true_val_; false_val_]}[true_val; false_val]]
  };
  // Add (::) to make bool list changeable
  // Remove first (::) when returning result
  1 _ (inner/)[(::), truefalse; true_seq; false_seq]
 };

exercise_5[11010b; til 5; neg til 5]


