/
* @file exercise_1.q
* @overview Generate a password file.
\

credentials: `peter`jacob`phillip!("churchontherock"; "faithwithoutactionisdead"; "wannaseethefather");

`:important_file 0: ":" sv/: flip ({[cred] string key cred}; {[cred] raze each string md5 each value cred}) @\: credentials;
