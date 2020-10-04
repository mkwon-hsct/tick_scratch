// chapter_3.q

/
* Anser keys for the exercises of chapter 3.
\

// Expand  width of console
\c 25 200

exercise_1:{[name; grp]
  $[
    // Invalid name
    name like "S*"; ['"Name starting from S is invalid: ", string name];
    // Invalid group
    not grp in "NO"; ['"Invalid group: ", grp];
    // Valid case
    [string[name], " from ", grp]
  ]
 };

exercise_2:{[err]
  $[
    // Name Error
    err like "Name *"; ["Name Error >> ", err];
    // Group Error
    err like "Invalid group *"; ["Group Error >> ", err];
    // Other Error
    ["Unknown Error >> ", err]
  ]
 };

// Apply exercise_1 to each pair of (name; group) with exercise_2 an error catch function
.[exercise_1; ; exercise_2] each flip (`Jacob`Joshua`Graham`David`Mattew`Peter`Samuel; "NOXONNO")

exercise_3:{[num]
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

exercise_3 110

exercise_3 12

exercise_4:{[truefalse; true_seq; false_seq]
  inner:{[seq; true_val; false_val]
    // Replace first non-boolean value.
    // Use if-else to decide which value to substitute.
    @[seq; first where -1h = type each seq; {[true_val_; false_val_; which] $[which; true_val_; false_val_]}[true_val; false_val]]
  };
  // Add (::) to make bool list changeable
  // Remove first (::) when returning result
  1 _ (inner/)[(::), truefalse; true_seq; false_seq]
 };

exercise_4[11010b; til 5; neg til 5]


