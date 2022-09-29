#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <signal.h>
void sigint_handler(int sig){
    printf("So u think u can stop the bomb with ctrl-c, do u?\n");
    sleep(2);
    printf("Well...");
    sleep(1);
    printf("OK. :-)\n");
    exit(0);
}
int main(){
    if(signal(SIGINT,sigint_handler)==SIG_ERR){
        printf("error");
    }
    pause();
    return 0;
}