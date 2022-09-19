#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"
void print_recv_msg(char* content){
    printf("recieved %s", content);
}

int main(int argc,char* argv[]){
    int p[2];
    int pid_p,pid_c;// pid of parent and child
    int stat;// status
    pipe(p);
    
    if((pid_c=fork())==0){
        char* read_out=""; 
        // close(p[1]);
        read(p[0], read_out, 4);
        // close(p[0]);
        printf("%d: received %s",pid_c, read_out);
        printf("\n");
        write(p[1], "pong", 4);
        // close(p[1]);
        // exit(0);
    }else{
        // close(p[0]);
        write(p[1], "ping", 4);
        // close(p[1]);
        wait(&stat);
        pid_p = getpid();
        char* read_out2="";
        // close(p[1]);
        read(p[0], read_out2, 4);
        printf("read_out:%s\n",read_out2);
        printf("%d: received %s",pid_p, read_out2);
        printf("\n");
        // close(p[0]);
        exit(0);
    }
    
    exit(0);
}