#include"user/user.h"
#include"kernel/types.h"
int nums[34]={2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35};
void primes(int*ports, int max){
    int prime,read_out;
    int num2Next[34]={-1};
    int cnt=0;
    int len=read(ports[0],&prime,sizeof prime);
    printf("prime %d\n",prime);
    if(len <=0||prime==max) exit(0);
    
    while(read(ports[0], &read_out,sizeof read_out)>0){//管道还能读出数据
        if(read_out%prime!=0){
            
            num2Next[cnt] = read_out;
            cnt++;
        }
        if(read_out>=max){
            break;
        }
    }
    write(ports[1], num2Next, cnt*4);
    
    if(fork() == 0){ //child's turn
        primes(ports, num2Next[cnt-1]);
        exit(0);
    }
    wait(0);
    return;
}
int main(int argc,char* argv[]){
    int p[2];
    pipe(p);
    write(p[1],nums,sizeof nums);
    primes(p, 35);
    
    close(p[1]);
    close(p[0]);
    exit(0);
}
