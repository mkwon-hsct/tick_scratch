// escape.q

/
* @brief Chop a sentence and glind until no one can tell it is the human writing.
* @param sentence
* @type
* - string
* @return
* - string
\
choppy:{[sentence]
  sentence:lower sentence;
  sentence:@[sentence; where sentence="a"; {"c"$1+`int$x}];
  sentence:@[sentence; where sentence="u"; :; "X"];
  sentence:ssr[sentence; "o"; "+|\\*/"];
  sentence:(0, where sentence="e") cut sentence;
  :sentence;
  // The lines below will not be executed
  sentence: upper each sentence;
  sentence
 }