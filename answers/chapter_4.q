/
* @file chapter_4.q
* @overview Anser keys for the exercises of chapter 4.
\

exercise_1:{[] string .[!] flip ((Hazael; Syria); (Nebuchadenezzar; Babylon); (David; Israel))};

exercise_2:{[]
  ![trades; ((within; `date; 2013.07.01 2013.07.03); (in; `sym; enlist `AAPL`MSFT)); 0b; `sym`size!(({`$3#/:string x}; `sym); (xbar; 10000; `size))]
 };

// expense:flip `person`item`price`date!(`bear_sato`bear_sato`bear_sato`tower_hisamitsu`tower_hisamitsu`tower_hisamitsu`glico_nakai`raimon_kimijima`raimon_kimijima`mentai_takenaka; 
//  `salmon`melon`merry_go_round`ra_men`udon`yakiniku`caramel`jinrikisha`taxi`mentaiko; 
//  5000 5000 2000 1200 1000 3000 500 1000 3000 800;
//  2019.10.01 2019.10.13 2019.10.28 2019.10.03 2019.10.20 2019.10.30 2019.10.18 2019.10.02 2019.10.20 2019.10.07)

// expense: delete date from expense_orig
exercise_3:{[]
  .Q.dpft[`:.; 2019.10.05; `person; `expense]
 };

// expense: update date:2019.10.01+10?4 from expense_orig
exercise_4:{[]
  {[date_] (` sv (`$":", string date_; `expense; `)) set .Q.en[`:.] delete date from `person xasc select from expense where date=date_} each exec distinct date from expense
 };

// mini_quote2:select from quote where date=2013.05.22, sym in `AAPL`DELL`GOOG`MSFT, time within 09:30:00 09:30:05;
exercise_5:{[]
  fills (`time xasc select time from mini_quote2) lj/ {[sym_] `time xkey (`$string[sym_],/: ("_bid"; "_ask")) xcol select bid, ask, time from mini_quote2 where sym = sym_} each exec distinct sym from mini_quote2
 };
 