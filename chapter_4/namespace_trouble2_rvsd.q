/
* @file namespace_trouble2_rvsd.q
* @overview Revised version of namespace_trouble2.q.
\

// Load namespace_trouble library
\l namespace_trouble.q

// Move to `space2`
\d .space2

// Local
ILLUSION: 10000;
MAGIC: 1978;

magic:{[]
  // No need to append namespace prefix to MAGIC
  -1 "Super magic!!: ", string MAGIC;
 }

// Which ILLUSION is this function using??
illusion:{[]
  -1 "Super illusion!!: ", string ILLUSION;
 }

// Close namespace `space2`
\d .
