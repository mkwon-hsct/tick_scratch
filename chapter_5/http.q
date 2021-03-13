/
* @file http.q
* @overview
* Defines event handlers for HTTP requests.
\

// Run on port 5000
system "p 5000";

/
* @brief Enum indicating request execution failure.
\
EXECUTION_STATUS_:`SUCCESS`FAILURE;
EXECUTION_FAILURE_:`EXECUTION_STATUS_$`FAILURE;

/
* @brief Table to store posted data via HTTP.
\
POSTED_DATA:flip `time`user`article!"ps*"$\:();

/
* @brief Generate fibonnaci sequence of n elements.
* @param n {number}: The number of elements to generate.
\
fibonacci:{[n]
  $[n=1;
    enlist 1;
    n=2;
    1 1;
    // n>=3
    {[n_] n_-:2; seq: 1 1; while[n_ > 0; seq,: sum -2#seq; n_-:1]; seq}[n]
  ]
 }

/
* @brief Handler for HTTP GET.
* @param text_and_header {compound list}: Tuple of (text; header).
* @note
* curl example message is below:
* ```
* curl http://127.0.0.1:5000/1+2
* ```
\
.z.ph:{[text_and_header]
  show text_and_header 1;
  text: text_and_header 0;
  // Execute query
  result: .Q.trp[value; text; {[error; trace] (EXECUTION_FAILURE_; (error; .Q.sbt trace))}];
  $[any EXECUTION_FAILURE_ ~/: result;
    [
      // Return Bad Request
      -2 last result 1;
      .h.he[result 1];
    ];
    // Return result
    .h.hn["200"; `txt; -3!result]
  ]
 }

/
* @brief Convert a post into dictionary which was sent via HTTP.
* @param text_and_header {compound list}: Tuple of (endpoint and text; header).
* @note
* curl example message is below:
* ```
* curl --data "{time:2020-03-01T00:12:20.555,user:mkwon,article:\"Nebuchadnezzar fell upon his face and did homage to Daniel.\"}" http://127.0.0.1:5000/script/
* ```
\
.z.pp:{[text_and_header]
  text: text_and_header 0;
  // Text is composed of [endpoint] [message].
  whitespace: text?" ";
  endpoint: (whitespace) # text;
  message: (1+whitespace) _ text;
  // Show endpoint
  -1 "endpoint: ", endpoint;
  // Process message as dictionary.
  // Key and value are separated by ':' and the pairs are separated by ','.
  result:.[0:; ("S:*,"; -1 _ 1 _ message); {[error] (EXECUTION_FAILURE_; error)}];
  $[any EXECUTION_FAILURE_ ~/: result;
    // Return Bad Request
    .h.he[first result 1];
    // Return result
    [
      `POSTED_DATA insert dict:update time:"P"$time, user:"S"$user from .[!] result;
      .h.hn["200"; `json; .j.j `time`user`message!(.z.p; dict `user; "Updated.")]
    ]
  ]
 }
