#include<stdio.h>
#include<unistd.h>
#include<signal.h>
#include<stdlib.h>
void fork12(){
    int N = 5;
    pid_t pid[N];
    int child_stat;
    for(int i=0;i<N;i++){
        if((pid[i]=fork())==0){
            while(1);
        }
    }
    for(int i=0;i<N;i++){
        printf("killing proc %d\n",pid[i]);
        kill(pid[i],SIGINT);
    }
    for(int i=0;i<N;i++){
        pid_t wpid = wait(&child_stat);
        if(WIFEXITED(child_stat)){
            printf("child %d terminated with stat %d\n",wpid, WEXITSTATUS(child_stat));
        }else{
            printf("child %d terminated abnormally\n",wpid);
        }
    }

}
int main(){
    fork12();
    exit(0);
}