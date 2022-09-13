#include"user/user.h"
#include"kernel/pipe.c"
int sleep(int ticks){
    while(ticks--){
    }
    exit(ticks);
}

//pipe utils
struct pipe* PIPE;
int pipe(int* ports){
/**
 * @brief ports is a array with 2 length
 * ports[0] denotes output, ports[1] denotes input 
 * 
 */ 
    int len_ports = sizeof(ports)/sizeof(ports[0]);//get length of input arr
    if (len_ports!=2) return -1;
    initlock(&PIPE->lock, "pipe");
    PIPE->nread=0;
    PIPE->nwrite=0;
    PIPE->readopen=1;
    PIPE->writeopen=1;
    ports[0] = 0;
    ports[1] = 1;

    return 0;
}

int write(int port, const void* buf, int strlen){
    char* buf_field = (char*)buf;//type convert to char[]
    if(port==0){
        print("wrong port!");
        exit(-1);
    }
    int i=0;
    for(i;i<strlen&&i<PIPESIZE;i++){
        // char ch = buf[i];
        if(i>=PIPESIZE){
            exit(-1);
        }
        pipewrite(PIPE, &buf, strlen);

    }
    exit(i+1);
}
int read(int port, void* buf, int strlen){
        if(port==1){
        print("wrong port!");
        exit(-1);
        }
        piperead(PIPE, &buf, strlen);
        pipeclose(PIPE,PIPE->writeopen);
    return 0;
}