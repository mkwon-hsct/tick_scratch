/
* @file exercise\1.q
* @overview Generate password file.
\

credentials: `peter`jacob`phillip!("churchontherock"; "faithwithoutactionisdead"; "wannaseethefather");

`:important_file 0: ":" sv/: flip ({[cred] string key cred}; {[cred] raze each string md5 each value cred}) @\: credentials;
