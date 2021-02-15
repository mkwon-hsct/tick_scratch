// namespace_trouble2.q

// Move to 'space2'
\d .space2

// Local
ILLUSION:10000;
MAGIC:1978;

// Load namespace_trouble library
// Catastrophic! TRAFFIC is no longer global!
\l namespace_trouble.q

magic:{[]
  // No need to append namespace prefix to MAGIC
  -1 "Super magic!!: ", string MAGIC;
 };

// Which ILLUSION is this function using??
illusion:{[]
  -1 "Super illusion!!: ", string ILLUSION;
 };

// Close namespace 'space2'
\d .