/
* @file ping.q
* @overview Define an event handler for ping message.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Handler of HTTP request to check a reponse.
* @param request {compound list}: Tuple of (endpoint; dictionary of headers).
* @return 
* - string: HTTP response.
\
.z.ph:{[request]
  $["ping" ~ request 0;
    .h.hn["200"; `txt; "alive"];
    .h.hn["404"; `txt; "Not Found"]
  ]
 };
