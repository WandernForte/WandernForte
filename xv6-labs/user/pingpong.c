#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"
void print_recv_msg(char* content){
    printf("recieved %s", content);
}

int main(int argc,char* argv[]){
    // int stat;
    pid_t pid_c, pid_p;
    int p2c[2]={1, 0};
    int c2p[2]={0, 1};
    int stat;
    pipe(p2c);
    // pid_p = getpid();
    if((pid_c=fork())<0){
        printf("ERROR!\n");
    }
    if(pid_c==0){//child_proc runs
        //TODO
        pipe(c2p);
        char* content="";
        read(c2p[0], content, 4);
        print_recv_msg(content);
        exit(0);
    }
    else{//parent proc runs
        write(p2c[1],"ping",4);
        wait(&stat);
        char* content="";
        read(p2c[0], content, 4);
        print_recv_msg(content);
        //TODO
        exit(0);
    }
    // pipewrite(pi_p2c,stat,5);
    return pid_c+pid_p;
}