EXECUTION_STATUS: enlist `failure;
EXECUTION_FAILURE: `EXECUTION_STATUS$`failure;

TASKS: `long$();

init: `:lib/multi_thread2 2: (`initialize; 1)
remote_execution: `:lib/multi_thread2 2: (`remote_execution; 2)
resolve: `:lib/multi_thread2 2: (`resolve; 1);
start_background_thread: `:lib/multi_thread2 2: (`start_background_thread; 1);

init[];
start_background_thread[];

.z.ts:{[now]
  {[id]
    show .Q.w[];
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

\t 5000
