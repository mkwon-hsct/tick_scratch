/
* @file: default_value.q
* @overview: Examples of using a dictionary as a parameter to define default values.
\

/
* @brief Display course items complementing missing items and altering if necessary.
* @param course {dictionary}: Items in the course. Accepted keys are below:
* - `appetizer
* - `main (must)
* - `dessert
* - `drink
\
full_course:{[course]
  // Trim invalid keys.
  course: (`appetizer`main`dessert`drink inter key course)#course;
  // Main dish is a must.
  if[not `main in key course; '"select main dish before ordering"];
  // Default appetizer is a cobb salad, dessert is vannila icecream and drink is tea.
  course: (`appetizer`dessert`drink!`cobb_salad`vanilla_icecream`tea) upsert course;
  // Alcohol is prohibited.
  if[any `beer`sake`wine = course `drink; course[`drink]: `tea];
  // Display the course items.
  -1 "\n" sv ": " sv/: flip string (key; value) @\: course;
 }
