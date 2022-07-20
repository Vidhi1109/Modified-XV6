# MODIFIED XV-6
To run
```sh
make clean
make SCHEDULER=X
X=FCFS , X=PBS , X=MLFQ
```
### Syscall Tracing
Added a system call trace and a user program strace.
- strace runs the specified command until it exits.
- It intercepts and records the system calls which are called by a process during its execution.
- It should take one argument, an integer mask, whose bits specify which system calls to trace. For example, to trace the ith system call, a program calls strace 1 << i, where i is the syscall number.

### Files modified:
- syscall.h - Added syscall number
- syscall.c - Modified syscall() and added syscall definition
- sysproc.c - Extracted arguments for trace
- user.h - Included syscall trace
- usys.pl - Made an entry for trace
- Added a file strace.c in user folder
- proc.h - Add variable for mask
<br>
Details of the modifications can be seen in respective files.
 

### Scheduling Algorithms
<br>1. FCFS
<br>The ticks when a process initiates are recorded and scheduler gives priority to the processes that arrived earlier. 
<br>Modifications made:
<br>1. Added variable ctime to struct proc in proc.h
<br>2. Initialise ctime as ticks in allocproc.
<br>3. Added the code for fcfs in void scheduler().
```sh
  struct proc *p;
  struct cpu *c = mycpu();
  struct proc *min;
  c->proc = 0;
  for (;;)
  {
    /*FCFS*/
    c->proc = 0;
    int begin_time = -1;
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);

      if (p->state == RUNNABLE)
      {
        //printf("pid:%d priority:%d",p->pid , p->priority);
        if (begin_time == -1)
        {
          begin_time = p->ctime;
          min = p;
          continue;
        }
        if (begin_time < p->ctime)
        {
          release(&min->lock);
          begin_time = p->ctime;
          min = p;
          continue;
        }
      }
      release(&p->lock);
    }
    if (begin_time == -1)
    {
      continue;
    }
    else
    {
      min->state = RUNNING;
      c->proc = min;
      swtch(&c->context, &min->context);
      c->proc = 0;
      release(&min->lock);
    }
  }
```
<br>4.Disable yield() {pre-emption on timer interrupt} in kerneltrap() and usertrap() in trap.c.

<br>2. PBS
<br> The Static Priorityof a process (SP) can be in the range [0,100],  the smaller value will represent higher priority . Set the default priority of a process as 60. The lower the value the higher the priority.
<br>Dynamic Priority(DP) is calculated from static priority and niceness.
<br>The nicenessis an integer in the range [0, 10] that measures what percentage of the time the process was sleeping.
<br>DP = max(0, min(SP − niceness + 5, 100))
<br>niceness = (ticks spent in sleeping state/(ticks spent in sleeping state + ticks spent in running state))
<br>If two processes have equal dynamic priority , the one which has been scheduled lesser number of times is given a chance. In case even the number of times scheduled are same, the one which started earlier is given priority.
<br> 
<br>Modifications made:
<br>1. Added variables to struct proc in proc.h
<br>2. Initialised them in allocproc , modifications in sleep to record sleep time of the process(when process goes to sleep ticks are recorded similarly when it goes to wakeup ticks are recorded. The difference between these ticks gives the sleeping time).
<br>3. Added the code for pbs in void scheduler(). Also a function calc_dp(struct proc *) was added to calculate new niceness values and dynamic priority.
```sh
int calc_dp(struct proc *p)
{
  if ((p->sleep_time + p->run_time) == 0)
  {
    p->niceness = 5;
    p->dynamic_priority = p->priority;
    return p->dynamic_priority;
  }
  int niceness = ((10 * p->sleep_time) / (p->sleep_time + p->run_time));
  p->niceness = niceness;
  int x = p->priority - niceness + 5;
  p->dynamic_priority = x;
  if (x > 100)
  {
    p->dynamic_priority = 100;
    return 100;
  }
  if (x < 0)
  {
    p->dynamic_priority = 0;
    return 0;
  }
  return x;
} 
```
```sh
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for (;;)
  {
    intr_on();
    c->proc = 0;
    int begin = -1;
    struct proc *pproc = 0;
    int dpriority, num_sched, start_time;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if (begin == -1)
        {
          pproc = p;
          dpriority = calc_dp(p);
          num_sched = p->scheduled;
          start_time = p->ctime;
          begin = 1;
        }
        else
        {
          p->priority = calc_dp(p);
          if (p->dynamic_priority < dpriority)
          {
            release(&pproc->lock);
            pproc = p;
            dpriority = calc_dp(p);
            num_sched = p->scheduled;
            start_time = p->ctime;
          }
          else if (p->dynamic_priority == dpriority && p->scheduled < num_sched)
          {
            release(&pproc->lock);
            pproc = p;
            dpriority = calc_dp(p);
            num_sched = p->scheduled;
            start_time = p->ctime;
          }
          else if (p->dynamic_priority == dpriority && p->scheduled == num_sched && p->ctime < start_time)
          {
            release(&pproc->lock);
            pproc = p;
            dpriority = calc_dp(p);
            num_sched = p->scheduled;
            start_time = p->ctime;
          }
          else
          {
            release(&p->lock);
          }
        }
        continue;
      }
      release(&p->lock);
    }
    if (begin == -1)
    {
      continue;
    }
    else
    {
      pproc->state = RUNNING;
      c->proc = pproc;
      pproc->scheduled++;
      pproc->run_time = 0;
      swtch(&c->context, &pproc->context);
      c->proc = 0;
      release(&pproc->lock);
    }
  }
```
<br>4. Disable yield() {pre-emption on timer interrupt} in kerneltrap() and usertrap() in trap.c.
<br>5. To implement pbs , syscall set_priority() was also implemented.
<br>Files modified:
<br>1. syscall.h - Added syscall number
<br>2. syscall.c - Modified syscall() and added syscall definition
<br>3. sysproc.c - Extracted arguments for set_priority
<br>4. user.h - Included syscall set_priority
<br>5. usys.pl - Made an entry for set_priority
<br>6. Added a file setpriority.c in user folder
<br>7. defs.h - Add function definition
<br>8. proc.c - Function added 
```sh
int set_priority(int new_priority, int pid)
{
  //printf("hello");
  if (new_priority < 0 || new_priority > 100)
    return -1;

  for (struct proc *p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      int old_priority = p->priority;
      p->priority = new_priority;
      p->niceness = 5;
      release(&p->lock);
      if (new_priority < old_priority)
      {
        yield();
      }

      return old_priority;
    }

    release(&p->lock);
  }

  return -1;
}
```
<br> Details of the modifications can be seen in respective files.

<br>3. MLFQ
### Answer to the question 
<br>A process could potentially take advantage of this scheduling policy by giving up CPU just before time slice is over, so that it is not demoted to a lower queue and gets a fresh time slice. So, if a process entered highest priority queue and it leaves cpu before time slice is over, it will return again to the highest priority queue. This way the process will be in highest priority queue for all the time of its execution.
<br>Modifications made:
<br>Queues are not implemented just by adding a variable queue in struct proc . This variable will update the queue number of the process.
<br>1. Added variables to struct proc in proc.h
<br>2. Initialised them in allocproc.
```sh
  p->cur_ticks = 0;
  p->num_runs = 0;
  p->ticks[0] = p->ticks[1] = p->ticks[2] = p->ticks[3] = p->ticks[4] = 0;
  p->exec_last = 0;
  p->queue = 0;
  p->flag = 0;
```  
<br>3. Added yield() in fork to run preempt a process when a new ones comes in.
<br>4. Timer ticks are updated in update_timer().
```sh
 struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      // if (p->state != RUNNABLE)
      // {
      //   release(&p->lock);
      //   continue;
      // }
      if (p->state == RUNNABLE && p->flag == 1)
      {
        if (p->queue < 4)
        {
          //printf("hello");
          p->queue++;
          printf("changed to %d ", p->queue);
          p->cur_ticks = 0;
          p->flag = 0;
        }
        release(&p->lock);
        continue;
      }
      release(&p->lock);
    }
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      // if (p->state != RUNNABLE)
      // {
      //   release(&p->lock);
      //   continue;
      // }
      if (p->state == RUNNABLE && ticks - p->exec_last > 500)
      {
        if (p->queue > 0)
        {
          p->queue--;
          p->cur_ticks = 0;
        }
        release(&p->lock);
        continue;
      }
      release(&p->lock);
    }
    for (int que_num = 0; que_num < 5; que_num++)
    {
      for (p = proc; p < &proc[NPROC]; p++)
      {
        acquire(&p->lock);
        if (p->state == RUNNABLE && p->queue == que_num)
        {
          p->num_runs++;
          c->proc = p;
          p->state = RUNNING;
          swtch(&c->context, &p->context);
          c->proc = 0;
          release(&p->lock);
          continue;
        }
        release(&p->lock);
      }
    }
  }
```
<br>5. Pre-emption for different time slices has been done in trap.c kerneltrap() and usertrap() functions.
<br>4. Procdump
<br>Only certain values from struct proc were to be printed. 
<br>SCHEDULER TEST RESULTS
<br>Average rtime Average wtime
<br>117   44   PBS
<br>132   39   MLFQ
<br>97    80   FCFS
<br>116   42   Round Robin 
