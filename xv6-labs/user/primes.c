#include"user/user.h"
#include"kernel/types.h"
int nums[34]={2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35};
int main(int argc,char* argv[]){
    int stat;
    int p[2];
    int pid;
    pipe(p);
    if((pid=fork())!=0){//父进程
        
        write(p[1], nums, sizeof nums);
        close(p[1]);
        wait(&stat);
        
    }else{//子进程
        int read_out=-1;
    
        if(!read(p[0],&read_out,sizeof read_out)){//空则直接退出
        exit(0);
        }

        int new_ports[2];
        int prime=read_out;
        printf("prime: %d", prime);
        printf("\n");
        pipe(new_ports);//第二个管道
        while(read(p[0], &read_out,sizeof read_out)>0){//管道还能读出数据
    
            if(read_out%prime!=0){
                dup(new_ports[1]);
                write(new_ports[1], &prime,1);
                close(new_ports[1]);
            }
        }
        wait(&stat);
        exit(0);
    }

    exit(0);
}
