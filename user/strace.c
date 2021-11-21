#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int i;
  char *nargv[32];

  if(argc < 3 )
  {
    fprintf(2, "Incorrect number of arguments\n", argv[0]);
    exit(1);
  }
  if (argv[1][0] < '0' || argv[1][0] > '9')
  {
    fprintf(2, "Incorrectarguments\n", argv[0]);
    exit(1);    
  }
  if (trace(atoi(argv[1])) < 0) 
  {
    fprintf(2, "%s: trace failed\n", argv[0]);
    exit(1);
  }
  
  for(i = 2; i < argc && i < 32; i++)
  {
    nargv[i-2] = argv[i];
  }
  exec(nargv[0], nargv);
  exit(0);
}
