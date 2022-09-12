#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"


int main(int argc,char* argv[]){
    // int stat;
    pid_t pid_c, pid_p;
    int p2c[2]={1, 0};
    int c2p[2]={0, 1};
    int ret = pipe(p2c);
    pid_p = getpid();
    if((pid_c=fork())<0){
        printf("ERROR!\n");
    }
    if(pid_c==0){//child_proc runs
        //TODO
        exit(0);
    }
    else{
        //TODO
        exit(0);
    }
    // pipewrite(pi_p2c,stat,5);
    return pid_c+pid_p;
}