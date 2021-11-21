#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  if(argc < 3)
  {
    fprintf(2, "usage: setpriority pattern [file ...]\n");
    exit(1);
  }
  int pri = atoi(argv[1]);
  int pid = atoi(argv[2]);
  set_priority(pri,pid);
  exit(0);
}