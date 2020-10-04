// lambda_func.q

/
* @brief Calculate correlation of two vectors
* @param v1: first vector
* @type
* - list of long
* - list of float
* @param v2: second vector
* @type
* - list of long
* - list of float
* @return
* - float
\
correlation:{[vec1;vec2]
  // dev[v1] * dev[v2]
  denominator:prd {sqrt {[v] v$v} x - avg x} each (vec1; vec2);
  // cov[v1; v2]
  numerator:.[$] {x - avg x} each (vec1; vec2);
  numerator % denominator
 };

v1:1.5 0.8 2.6 1.2;
v2:4.2 2.9 4.0 3.3;

r:correlation[v1;v2];
show r;