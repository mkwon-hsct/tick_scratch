/
* @file load.q
* @overview Define a behavior of file load control.
\

// If `LOAD_Q_` is defined nothing todo.
// Otherwise load definitions below.
if[not @[get; `LOAD_Q_; 0b];

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

  // Define `LOAD_Q_`.
  LOAD_Q_: 1b;

  // List of loaded file tokens.
  LOADED_FILES_: enlist `LOAD_Q_;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

  // @brief Load a file if a toke of the file is not in `LOADED_FILES_`.
  // @param file {symbol}: File handle, e.g., `:path/to/file.
  .load.load_file:{[file]
    // Create a token from the file name.
    // ex.) utility/log.q => LOG_Q_
    token: `$ssr[last "/" vs upper string file; "."; "_"], "_";
    $[token in LOADED_FILES_;
      (::);
      [
        // Load the file.
        system "l ", string file;
        // Add the file to the loaded file list.
        LOADED_FILES_,: token
      ]
    ]
  };

// if[not @[get; `LOAD_Q_; 0b];
 ];
