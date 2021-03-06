/
* @file escape.q
* @overview Example of escaping from a function.
\

/
* @brief Chop a sentence and glind until no one can tell it is a human writing.
* @param sentence {string}
* @return string
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