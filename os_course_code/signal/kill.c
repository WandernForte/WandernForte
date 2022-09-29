#include<stdio.h>
#include<unistd.h>
#include<signal.h>
#include<stdlib.h>
int main(){
    pid_t pid;
    if((pid=fork())==0){
        pause();//pause 时就被杀死了
        printf("ctrl should never reach here!\n");
        exit(0);
    }

    kill(pid, SIGKILL);
    exit(0);

}