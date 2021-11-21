/**
 * @file muti_thread2.c
 * @brief Examples to demonstrate multi-threading by using a socketpair.
 */

#include <stdlib.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/socket.h>
#include <pthread.h>
#include <time.h>
#include <k.h>

/**
 * @brief Value indicating failure of creating a socket pair.
 */
const int SOCKET_ERROR = -1;

/**
 * @brief Channel to pass a result of an execution of a function from the sub-thread
 *  to the main thread.
 */
I NOTIFY_CHANNEL[2] = {-1, -1};

/**
 * @brief Channel to pass a function and arguments from the main thread to the sub-thread.
 */
I TASK_CHANNEL[2] = {-1, -1};

/**
 * @brief Dictionary to store results of execution of functions.
 * - keys: Task ID.
 * - values: Result of execution.
 */
K RESULTS = (K) 0;

/**
 * @brief Mutex to lock the sub-thread until the main thread passes a function and arguments.
 */
pthread_mutex_t MUTEX;

/**
 * @brief Conditional variable used with `MUTEX` to lock the sub-thread until the main thread
 *  passes a function and arguments.
 */
pthread_cond_t CONDITIONAL_VARIABLE;

/**
 * @brief Add a result once a task was completed.
 */
K callback(I socket){
  // Receive job ID and fibonacci sequence
  K buffer[4];
  recv(socket, &buffer, 4*sizeof(K), 0);
  // Task ID is not consumed
  ja(&kK(RESULTS)[0], &(buffer[0]->j));
  // Answer is consumed
  jk(&kK(RESULTS)[1], buffer[1]);
  // Free task ID
  r0(buffer[0]);
  // Decrement reference count of function and arguments
  r0(buffer[2]);
  r0(buffer[3]);
  return (K) 0;
}

/**
 * @brief Initialize internal channels, initialize result dictionary and
 *  register a callback.
 */
K initialize(){
  
  // Make pipe
  if(socketpair(AF_LOCAL, SOCK_STREAM, 0, NOTIFY_CHANNEL)){
    return krr("failed to create pipe");
  }
  if(socketpair(AF_LOCAL, SOCK_STREAM, 0, TASK_CHANNEL)){
    return krr("failed to create pipe");
  }

  // Set sockets non-blocking
  if(fcntl(NOTIFY_CHANNEL[0], F_SETFL, O_NONBLOCK) == EINVAL){
    return krr("non blocking mode is not supported");
  }
  if(fcntl(NOTIFY_CHANNEL[1], F_SETFL, O_NONBLOCK) == EINVAL){
    return krr("non blocking mode is not supported");
  }

  // Set sockets non-blocking
  if(fcntl(TASK_CHANNEL[0], F_SETFL, O_NONBLOCK) == EINVAL){
    return krr("non blocking mode is not supported");
  }
  if(fcntl(TASK_CHANNEL[1], F_SETFL, O_NONBLOCK) == EINVAL){
    return krr("non blocking mode is not supported");
  }

  // Initialize `RESULTS` with dictionary
  K keys = ktn(KJ, 1);
  kJ(keys)[0] = nj;
  K values = ktn(0, 1);
  kK(values)[0] = ka(101);
  kK(values)[0]->g = 0;
  RESULTS = xD(keys, values);
  // Register callback
  sd1(NOTIFY_CHANNEL[0], callback);

  return (K) 0;  
}

/**
 * @brief Check internal channel and generate Fibonacci sequence when some
 *  number is posted.
 */
void *evaluator(void *unused){
  // Buffer to receive a task
  K task_buffer[3];
  // Buffer to send a result
  K result_buffer[4];
  while(1){
    ssize_t ok;
    pthread_mutex_lock(&MUTEX);
    pthread_cond_wait(&CONDITIONAL_VARIABLE, &MUTEX);
    pthread_mutex_unlock(&MUTEX);
    if((ok = recv(TASK_CHANNEL[0], (void *) &task_buffer, 3*sizeof(K), 0)) != -1){
      // Apply function to arguments
      K answer = dot(task_buffer[1], task_buffer[2]);
      // Send answer to main thread with ID and inputs to be freed in the main
      result_buffer[0] = task_buffer[0];
      result_buffer[1] = answer;
      result_buffer[2] = task_buffer[1];
      result_buffer[3] = task_buffer[2];
      send(NOTIFY_CHANNEL[1], (const void *) &result_buffer, 4 * sizeof(K), 0);
    }
    else{
      sched_yield();
    }
  }  
}

/**
 * @brief Launch a thread to apply function on arguments.
 */
K start_background_thread(){
  // Launch thread
  pthread_t thread_id;
  pthread_mutex_init(&MUTEX, NULL);
  pthread_cond_init(&CONDITIONAL_VARIABLE, NULL);
  if(pthread_create(&thread_id, NULL, evaluator, "") != 0){
    return krr("pthread_create() error");
  }
  else{
    return (K) 0;
  }
}

/**
 * @brief Execute a function with arguments remotely.
 * @param function: Function to execute.
 * @param arguments: Arguments of the function.
 */
K remote_execution(K function, K arguments){
  // Generate job ID
  time_t now;
  time(&now);
  // Send request
  // ID will be freed on the sub-thread
  // Increment reference count for function and arguments so
  //  that they are not freed at the end of this function, not remote.
  K request[3] = {kj(now), r1(function), r1(arguments)};
  int ok = send(TASK_CHANNEL[1], (const void*) &request, 3 * sizeof(K), 0);
  pthread_mutex_lock(&MUTEX);
  pthread_cond_signal(&CONDITIONAL_VARIABLE);
  pthread_mutex_unlock(&MUTEX);
  // Return job ID
  return kj(now);
}

/**
 * @brief Return position of a given ID in `RESULTS`.
 * @param task_id: Task ID returned by `remote_execution`.
 * @return 
 * - -1: If the ID was not found in the results.
 * - number: Index of the ID in the results.
 */
int find_result(K task_id){
  // Initialize with length of keys
  int position = kK(RESULTS)[0]->n;
  int i = 0;
  while(i != position && kJ(kK(RESULTS)[0])[i] != task_id->j){
    ++i;
  }
  // -1 means not found
  return (i == position)? -1: i;
}

/**
 * @brief Extract a result if the task of the given ID has been completed.
 * @param task_id: Task ID returned by `remote_execution`.
 * @return 
 * - error: If the task has not been completed.
 * - any: Result of the execution.
 */
K resolve(K task_id){
  int position;
  if((position = find_result(task_id)) == -1){
    return krr("not yet resolved");
  }
  else{
    // Extract the result
    K result = k(0, "{[results; id] results[id]}", r1(RESULTS), r1(task_id), (K) 0);
    // Delete the ID and result from dictionary
    RESULTS = k(0, "{[results; id] results _ id}", RESULTS, r1(task_id), (K) 0);
    return result;
  }
}
