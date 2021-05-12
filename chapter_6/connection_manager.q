/
* @file connection_manager.q
* @overview Define q functions to build a pipeline.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

// Open port defined in `connection_manager.config`.
{[]
  managers: read0 `:config/connection_manager.config;
  system "p ", last ":" vs managers first where managers like\: string[.z.h], "*";
 };

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                      Functions                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Load accounts of processes. 
\
load_accounts:{[]
  {[name;val] setenv[`$name; val]} ./: ":" vs/: read0 `:config/account.config;
 };

