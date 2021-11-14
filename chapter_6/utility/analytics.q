/
* @file analytics.q
* @overview Define a function to load analytics.
\

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Initial Setting                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

\l utility/load.q

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/
* @brief Load analytics configured in `analytics.config` using the account name of this process. 
\
load_analytics:{[account_name]
  // Cast value (list of string) to list of symbol.
  setting: `$.j.k raze read0 `:config/analytics.config;
  // Get list of files to load searching with an account name.
  files: value[setting] where account_name like/: string key setting;
  // Load each file
  {[file] .load.load_file .Q.dd[`:analytics; file]} each files;
 }

// Load
load_analytics `$first .Q.opt[.z.X] `user;
