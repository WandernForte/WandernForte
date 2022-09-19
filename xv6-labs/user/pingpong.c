#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"
void print_recv_msg(char* content){
    printf("recieved %s", content);
}

int main(int argc,char* argv[]){
    int p[2];
    int pid_p, pid_c;// pid of parent and child
    int stat;// status
    pipe(p);
    write(p[1], "ping", 4);
    if((pid_c=fork())==0){
        char* read_out=""; 
        close(p[1]);
        read(p[0], read_out, 4);
        close(p[0]);
        printf("%d: received %s\n",pid_c, read_out);
        write(p[1], "pong", 4);
        exit(0);
    }else{
        pid_p = getpid();
        wait(&stat);
        close(p[1]);
        char* read_out="";
        read(p[0], read_out, 4);
        printf("%d: received %s\n",pid_p, read_out);
        close(p[0]);
        exit(0);
    }
    exit(0);
}