/
* @file log.q
* @overview Define logging functions.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Format a log message.
* @param level {string}: Log level.
* @param message {string}: Log message.
* @param option {any}: Optional information.
* @return string: Formatted log message.
\
log_common: {[level;message;option]
  " ### " sv (string .z.p; 7$level; string .z.h; string .z.u; message; .Q.s1 option)
 }

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Interface                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Display informational log message.
* @param message {string}: Log message.
* @param option {any}: Optional information.
* @return string: Formatted log message.
\
.log.info:{[message;option]
  -1 log_common["INFO"; message; option];
 }

/
* @brief Display warning log message.
* @param message {string}: Log message.
* @param option {any}: Optional information.
* @return string: Formatted log message.
\
.log.warning:{[message;option]
  -1 log_common["WARNING"; message; option];
 }

/
* @brief Display error log message.
* @param message {string}: Log message.
* @param option {any}: Optional information.
* @return string: Formatted log message.
\
.log.error:{[message;option]
  -2 log_common["ERROR"; message; option];
 }
