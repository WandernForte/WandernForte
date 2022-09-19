#include"user/user.h"
#include"kernel/types.h"
int nums[34]={2,3,4,5,6,7,8,9,10,
            11,12,13,14,15,16,17,
            18,19,20,21,22,23,24,
            25,26,27,28,29,30,31,
            32,33,34,35};
int main(int argc,char* argv[]){
    int stat;
    int p[2];
    int pid;
    int* flag={0};
    
    start:
    pipe(p);
    if((pid=fork())<0){//子进程
        exit(-1);
    }
    else if(pid==0){
    int port_out=dup(p[0]);
    read(port_out, nums, 34);
    int* num2Next={0};
    int cnt=0;// counts remained nums
    int port_in=dup(p[1]);
    for(int i=1;i<(sizeof nums)/4;i++){
        if(nums[i]%flag[0]!=0){
        // printf("%d",nums[i]);
        sleep(1);
        num2Next[cnt]=nums[i];
        cnt++;
        }
        }
    // printf("prime %d",nums[0]);
    // printf("\n");
    
    p[0]=port_out,p[1]=port_in;
    // pipe(p);
    write(port_in, num2Next, 34);
    // close(port_in);
    wait(&stat);
    exit(0);
    }
    else{
    //主进程
    write(p[1], nums, 34);//init
    // close(p[1]);
    wait(&stat);
    if(sizeof nums>0){
        printf("%d",nums[0]);
        goto start;
    }
    exit(0);
    }
    
}
