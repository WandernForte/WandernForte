#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
void handler(int sig){
    int olderrno = errno;
    sigset_t mask_all,pre_all;
    pid_t pid;
    sigfillset(&mask_all);
    while((pid=waitpid(-1, NULL, 0))>0){
        sigprocmask(SIG_BLOCK, &mask_all, &pre_all);
        deletejob(pid);
        sigprocmask(SIG_SETMASK, &pre_all, NULL);   
    }
}
int main(){
        if(signal(SIGINT,handler)==SIG_ERR){
        printf("error");
    }
    pause();
    return 0;
}