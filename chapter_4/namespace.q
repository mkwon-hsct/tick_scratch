/
* @file namespace.q
* @overview Demostrate namespace usage with examples of calculating distance between coordinates.
\

// pi
PI: acos -1;

/
* @brief Table to contain results of conversion between cartesian to pollar system.
* @columns
* - cartesian {list of float} Point in cartesian coordinate.
* - pollar {list of float} Point in pollar coordinate.
\
.coordinates.HISTORY: flip `cartesian`pollar!"**"$\:();

/
* @brief Calculate a distance of two points expressed in cartesian coordeinates.
* @param cart1 {list of float}: point in cartesian coordinates space.
* @param cart2 {list of float}: point in cartesian coordinates space.
* @return float
\
.coordinates.cartesian.distance:{[cart1; cart2]
  sqrt {x$x} `float$cart1 - cart2
 }

/
* @brief Calculate a distance of two points expressed in pollar coordeinates.
* @param cart1 {list of float}: point in pollar coordinates.
* @param cart2 {list of float}: point in pollar coordinates.
* @return float
\
.coordinates.pollar.distance:{[pollar1; pollar2]
  // sqrt(r1^2 + r2^2 - 2 * r1 * r2 * cos(|theta2-theta1|))
  sqrt xexp[pollar1 0; 2] + xexp[pollar2 0; 2] - 2 * pollar1[0] * pollar2[0] * cos abs pollar2[1]-pollar1[1]
 }

/
* @brief Convert cartesian coordibates into pollar coordinates.
* @param cart {list of float}: point in cartesian coordinates space.
* @return list of float
\
.coordinates.cart_to_pollar:{[cart]
  // (r; theta)
  r: sqrt {x$x} cart;
  theta: / 
    $[(-1=cart 1) and 0=cart 0;
      // -pi / 2
      neg PI % 2;
      (0=cart 1) and 1=cart 0;
      // 0
      0f;
      (1=cart 1) and 0=cart 0;
      // pi / 2
      PI % 2;
      (0=cart 1) and -1=cart 0;
      // pi
      PI;  
      // arctan(sin(theta) / cos(theta))
      atan cart[1] % cart 0
    ];
  // Insert record
  `.coordinates.HISTORY insert (enlist cart; enlist (r; theta));
  (r; theta)
 }

/
* @brief Convert pollar coordibates into cartesian coordinates.
* @param pollar {list of float}: point in pollar coordinates space.
* @return list of float
\
.coordinates.pollar_to_cart:{[pollar]
  // (r * cos(theta); r * sin(theta))
  cart: (pollar[0]*cos pollar 1; pollar[0]*sin pollar 1);
  `.coordinates.HISTORY insert (enlist cart; enlist pollar);
  cart
 }

// Calculation test
/
* @brief Test conversion between cartesian and pollar coordinates and their calculations of distance
* @param cart1 {list of float}: point in cartesian coordinates space
* @param cart2 {list of float}: point in cartesian coordinates space
* @return boolean
\
distance_test:{[cart1; cart2]
  // Calculate distance for cartesian coordinates
  cart_dist:.coordinates.cartesian.distance[cart1; cart2];

  // Convert into pollar coordinates and then calculate distance
  pollars: .coordinates.cart_to_pollar @/: (cart1; cart2);
  pollar_dist: .coordinates.pollar.distance . pollars;

  // Test: Compare distances of cartesian and pollar coordinates
  match_two_system_dist: cart_dist ~ pollar_dist;
  
  // Revert to cartesian and calculate distance
  carts: .coordinates.pollar_to_cart @/: pollars;
  cart_dist2: .coordinates.pollar.distance . pollars;
  
  // Test: Compare two cart distances
  match_two_cart_dist: cart_dist ~ cart_dist2;

  all (match_two_system_dist; match_two_cart_dist)
 }
