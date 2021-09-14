/**
 * @file q_console.c
 * @brief Define backend thread task and main console.
 */ 

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Load Libraries                    //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <sys/time.h>
#include <q_format.h>

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                    Global Variables                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief One day in nanoseconds.
 */
const J KDB_TIMESTAMP_OFFSET = 946684800000000000LL;

/**
 * @brief Buffer for user input.
 */
char INPUT[1024];

/**
 * @brief Country options from which one value is picked up randomly.
 */
const char *COUNTRIES[4] = {"Japan", "Korea", "Vietnam", "Singapore"};

/**
 * @brief Flag options from which one value is picked up randomly.
 */
char FLAGS[3] = "OAB";

/**
 * @brief Mutex to send data to q process.
 */
pthread_mutex_t MUTEX;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                        Structs                        //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief `timeval` struct to get current time.
 * @note Somehow this struct is not defined in `sys/time.h`.
 */
typedef struct {
    time_t tv_sec;            /* Seconds.  */
    suseconds_t tv_usec;      /* Microseconds.  */
} timeval;

/**
 * @brief Struct to hold a target socket and the number of rows to generate.
 */
typedef struct{
  int socket;
  int num_rows;
} TaskSet;

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                   Private Functions                   //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Generate data to send.
 * @return 
 * - compound list: Single row.
 */
K generate(){
  // List to return
  K data = ktn(0, 5);
  // t\Time
  struct timeval ts;
  gettimeofday(&ts, NULL);
  kK(data)[0]=ktj(-KP, (ts.tv_sec * 1000000LL + 1000LL * ts.tv_usec) - KDB_TIMESTAMP_OFFSET);
  // Country
  kK(data)[1]=ks((S) COUNTRIES[rand() % 4]);
  // Byte
  kK(data)[2]=kg((G) rand() % 256);
  // Amount
  kK(data)[3]=kj(1000LL * (1 + rand() % 5));
  // Flag
  kK(data)[4]=kc(FLAGS[rand() % 3]);
  return data;
}

/**
 * @brief Send single row to q process specified times by a task set.
 * @param task_set: Pointer to a struct which holds a target socket and the number of data to generate.
 */
void *task(void *task_set_){
  // Restore TaskSet
  TaskSet *task_set = (TaskSet*) task_set_;
  for(int i = 0; i!=task_set->num_rows; ++i){
    // Generate data
    K data = generate();

    // Lock socket
    pthread_mutex_lock(&MUTEX);
    // Send asynchronously
    K result = k(0 - task_set->socket, "insert", ks("nothing"), data, (K) 0);
    // Unlock
    pthread_mutex_unlock(&MUTEX);

    if(!result){
      // Network error
      fprintf(stderr, "network error\n");
    }

    sleep(1);
  }
  
  // Free K objects generated in this thread
  m9();
  // Exit
  pthread_exit(0);
}

//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//
//                     Main Function                     //
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++//

/**
 * @brief Main q console.
 * @param argv:
 * - [0]: Port number of target q process.
 */
int main(int argc, char *argv[]){
  // Connect to local q process with Unix domain socket
  int socket = khpun("0.0.0.0", atoi(argv[1]), "console:getmein", 1000);
  // Handle error if any
  switch (socket){
    case 0:
      fprintf(stderr, "authentication failure\n");
      exit(1);
    case -1:
      fprintf(stderr, "connection refused\n");
      exit(1);
    case -2:
      fprintf(stderr, "connection timeout\n");
      exit(1);
    default:
      break;
  }

  // Set seed
  srand(888);
  // Initialize mutex
  pthread_mutex_init(&MUTEX, NULL);
 
  // Console start 
  while(1){
    printf("q)");
    fflush(stdout);
    fgets(INPUT, sizeof(INPUT), stdin);
    // Trim new line
    INPUT[strlen(INPUT)-1]='\0';
    if(!strcmp(INPUT, "\\\\")){
      // Exit q console
      break;
    }
    else if(!strlen(INPUT)){
      // "Enter" key. Nothing to do.
      continue;
    }
    else if(!strncmp(INPUT, "feed[", 5)){
      // Launch data feed.
      int n=0;
      sscanf(INPUT, "feed[%d]", &n);
      pthread_t id;
      TaskSet new_task;
      // Define task set with the target port and the number of rows to send
      new_task.socket = socket;
      new_task.num_rows = n;
      if (pthread_create(&id, NULL, task, (void *) &new_task) != 0) {
        fprintf(stderr, "pthread_create() error\0");
        exit(1);
      }
    }
    else{
      // Direct query
      pthread_mutex_lock(&MUTEX);
      K result = ee(k(socket, INPUT, (K) 0));
      pthread_mutex_unlock(&MUTEX);
      // Display result
      format(result);
      r0(result);
    }   
  }
  return 0;
}