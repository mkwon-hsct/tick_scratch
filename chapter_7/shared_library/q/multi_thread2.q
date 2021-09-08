/
* @file multi_thread2.q
* @overview Load a shared library to use a thread and set up the instruments. 
\

/
* @brief Enum value for detecting execution error.
\
EXECUTION_STATUS: enlist `failure;
EXECUTION_FAILURE: `EXECUTION_STATUS$`failure;

/
* @brief List of task IDs to check the results.
\
TASKS: `long$();

/
* @brief Initialize internal channels, initialize result dictionary and
*  register a callback.
\
initialize: `:lib/multi_thread2 2: (`initialize; 1)

/
* @brief Launch a thread to apply function on arguments.
\
start_background_thread: `:lib/multi_thread2 2: (`start_background_thread; 1);

/
* @brief Execute function with arguments remotely.
* @param function {function}: Function to execute.
* @param arguments {any}: Arguments of the function.
\
remote_execution: `:lib/multi_thread2 2: (`remote_execution; 2);

/
* @brief Extract a result if the task of the given ID has been completed.
* @param task_id {long}: Task ID returned by `remote_execution`.
* @return 
* - error: If the task has not been completed.
* - any: Result of the execution.
\
resolve: `:lib/multi_thread2 2: (`resolve; 1);

/
* @brief Check status of tasks and display if it has been resolved.
\
.z.ts:{[now]
  {[id]
    result: @[resolve; id; {[error] (EXECUTION_FAILURE; error)}];
    $[any EXECUTION_FAILURE ~/: result;
      // not yet resolved
      -2 result 1;
      // resolved
      [
        TASKS:: TASKS except id;
        -1"Resolved task-", string[id], ": ", .Q.s1 result
      ]
    ];
  } each TASKS;
 }

// Set up instruments.
initialize[];
start_background_thread[];

// Check results every 5 seconds.
\t 5000
