/**
 * @file muti_thread.c
 * @brief Examples to demonstrate multi-threading by collecting launched threads.
 */

#include <stdlib.h>
#include <pthread.h>
#include <memory.h>
#include <k.h>

/**
 * @brief Calculate average of list of int.
 * @param list {variable}:
 * - list of int: List of int to calculate average.
 * - any: Unexpected type.
 */
void *averager(void *list){
  K q_list = (K) list;
  K average = (K) 0;

  if(((K) list)->t == KI){
    // List of int
    F sum=0;
    for(J i = 0; i!= q_list->n; ++i){
      sum+=kI(q_list)[i];
    }
    // Generate average value
    average = kf(sum / q_list->n);
  }
  else{
    // Wrong type
    average = ks("unexpected");
  }
  
  // Encode to list of byte
  K q_bytes = b9(1, average);
  // Copy to raw bytes
  G *bytes = (G*) malloc(q_bytes->n);
  memcpy(bytes, kG(q_bytes), q_bytes->n);
  // Free K objects generated in this thread
  m9();
  // Return bytes
  pthread_exit(bytes);
}

/**
 * @brief Extract total length of bytes.
 * @param bytes: Serialized q object.
 * @return Total length of the given bytes.
 */
int get_size(G *bytes){
  if(bytes[0]){
    return bytes[7] << 24 | bytes[6] << 16 | bytes[5] << 8 | bytes[4];
  }
  else{
    return bytes[4] << 24 | bytes[5] << 16 | bytes[6] << 8 | bytes[7];
  }
}

/**
 * @brief Launch a thread to calculate an average of integer sequence while main
 *  thread add a byte to a compound list to be returned at the end.
 * @param list: Argument passed to the sub thread.
 * - list of int: List to calculate. The remote function returns float type.
 * - any: Wrong type. The remote function returns symbol type.
 * @return 
 * - compound list
 */
K remote_avg(K list){
  // List to which remotely generated value is added.
  K final = ktn(0, 0);
  
  // Launch thread
  pthread_t id;
  // Enable sub-thread to refer to main sym.
  setm(1);
  if (pthread_create(&id, NULL, averager, (void *) list) != 0) {
    return krr("pthread_create() error");
  }

  // Add arbitrary value
  jk(&final, kg(0x4d));
  jk(&final, ks("main"));

  // Receive serialized object
  void *bytes;
  if (pthread_join(id, &bytes) != 0) {
    return krr("pthread_join() error");
  }
  // Reset reference flag
  setm(0);

  // Copy to K object
  K q_bytes = ktn(KG, get_size((G*) bytes));
  memcpy(kG(q_bytes), (G*) bytes, q_bytes->n);

  // Free bytes allocated by `malloc`
  free(bytes);

  // Join the deserialized result
  jk(&final, d9(q_bytes));
  // Free K result
  r0(q_bytes);

  return final;
}
