// chapter_2.q

/
* Anser keys for the exercises of chapter 2.
\

exercise_1:type (2D; 00:01);

exercise_2:(2#`time`sym`bid`ask`bsize`asize), `channel, (2 _ `time`sym`bid`ask`bsize`asize);

// You can't swap / and \ because it leadds to a different answer
exercise_3:1 2 3 4 */:\: 10 20 30 40;

// Possible answer 1
exercise_4_1:asc `timestamp$.z.p+10?10000000000

// Possible answer 2
exercise_4_2:asc .z.p+10?0D00:00:10;

exercise_5:100 xbar `time$exercise_4_1;

// Possible answer 1
// Parse first string as string
exercise_6:"*D"$' "," vs "Million sales!, 05 April 2020"

// Possible answer 2
// Cast first string to string
exercise_6:"cD"$' "," vs "Million sales!, 05 April 2020"

// Add "k" so that 'cut' leaves a character to the head of the first block
exercise_7:avg each 1 _/: (where orig in .Q.a) cut orig:"k", "051x64a9300v75h983"