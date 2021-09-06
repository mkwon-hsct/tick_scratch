/**
 * @file error.c
 * @brief Examples to distinct error and nullptr. 
 */ 

#include <k.h>
#include <stdio.h>

/**
 * @brief Display type and contents of a catched error.
 * @param mode {int}: Flag to switch likely error object:
 * - 0: Use nullptr.
 * - 1: Use general null.
 * - 2: Use genuine error.
 * @note Mode 0 will crash.
 */
K error_detect(K mode){
  K error=(K) 0;
  switch(mode->i){
    case 1:
      error = ka(101);
      error->g = 0;
      break;
    case 2:
      error = krr("oh no! this is a genuine error!!");
      break;
    default:
      // nothing to do
      break;
  }

  // Catch error
  K catched = ee(error);
  printf("type: %d\n", (int) catched->t);
  printf("error: %s\n", catched->s);
  fflush(stdout);
  
  return catched;
}
