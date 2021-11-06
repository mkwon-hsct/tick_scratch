/
* @file loop.q
* @overview Examples of iteration.
\

/
* @brief Generate first `n` elements of Fibonacci sequence.
* @param n {number}: The number of elements to generate.
* @return list of long
\
fibonacci:{[n]
  $[n in 1 2;
    n#1 1;
    [
      i:n-2;
      seq: 1 1;
      while[i; seq,: sum -2#seq; i-:1];
      seq
    ]
  ]
 }

/
* @brief Mock sum function.
* @param seq {list of long}: Sequence of numbers.
* @return long
\
 naive_sum:{[seq]
   ({[x; y] x + y}/) seq
 }

/
* @brief Mock sum function with initial value.
* @param init {long}: Initial value.
* @param seq {list of long}: Sequence of numbers.
* @return long
\
 naive_sum_with_init:{[init; seq]
   init {[x; y] x + y}/ seq
 }

/
* @brief Apply a series of patch functions consequtively to corresponding target numbers.
* @param seq {list of long}: Original sequence of numbers.
* @param target {long}: Target numbers.
* @param func {function}: Functions applied to 'target's.
* @return list of long
\
dynamic_patch:{[seq; targets; funcs]
  ({[seq_; target; func] @[seq_; where seq_ = target; func]}/)[seq; targets; funcs]
 }

/
* @brief Generate first `n` elements of Fibonacci sequence.
* @param n {number}: The number of elements to generate.
* @return list of long
\
fibonacci2:{[n]
  $[n in 1 2;
    n#1 1;
    (n-2) {[seq] seq, sum -2#seq}/ 1 1
  ]
 }

/
* @brief Generate Fibonacci sequence until the last elment exceed 'threshold'.
* @param threshold {long}: Threshold where generation of sequence stops.
* @return list of long
\
fibonacci_until:{[threshold]
  {[seq] seq, sum -2#seq}/[{[threshold_; res] threshold_ > last res}[threshold]; 1 1]
 }

/
* @brief Mock prds function.
* @param seq {list of long}: Sequence of numbers.
* @return list of long
\
 naive_prds:{[seq]
   ({[x; y] x * y}\) seq
 }

/
* @brief Mock prds function with initial value.
* @param init {long}: Initial value.
* @param seq {list of long}: Sequence of numbers.
* @return list of long
\
 naive_prds_with_init:{[init; seq]
   init {[x; y] x * y}\ seq
 }

/
* @brief Apply a series of patch functions consequtively to corresponding target numbers. Dynamics changes can be observed.
* @param seq {list of long}: Original sequence of numbers.
* @param target {long}: Target numbers.
* @param func {function}: Functions applied to 'target's.
* @return compound list
\
observe_dynamic_patch:{[seq; targets; funcs]
  ({[seq_; target; func] @[seq_; where seq_ = target; func]}\)[seq; targets; funcs]
 }

/
* @brief Generate first 'n' elements of Fibonacci sequence.
* @param n {number}: The number of elements to generate.
* @return compound list
\
observe_fibonacci2:{[n]
  $[n in 1 2;
    (1+til n)#\:1 1;
    enlist[1], (n-2) {[seq] seq, sum -2#seq}\ 1 1
  ]
 }

/
* @brief Generate Fibonacci sequence until the last elment exceed 'threshold'.
* @param threshold {long}: Threshold where generation of sequence stops.
* @return compound list
\
observe_fibonacci_until:{[threshold]
  {[seq] seq, sum -2#seq}\[{[threshold_; res] threshold_ > last res}[threshold]; 1 1]
 }

/
* @brief Change each element to `happy if previous element is a multiple of 3 (including 0); otherwise negate it.
* @param seq {list of long}: Sequence of number.
* @return
* - mixed list IF 'seq' includes an element which is not a multiple of 3 among non-tail elements
* - list of symbol IF all elements of 'seq' other than the last element are multiples of 3 
\
happy3:{[seq]
  0 {[this; pre] $[not pre mod 3; `happy; neg this]}': seq
 }
