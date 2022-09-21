#include "user/user.h"
#include "kernel/types.h"
//一言以蔽之，就是将之前的输出(用read(0,xx,xx)读取)放到当前命令的后方，如果遇到回车可直接执行
int main(int argc,char* argv[]){
    //先把xargs 后方的命令储存起来
    char* lat_buf[64];//latter buffer: like ab| xx
    // char cur_buf[64];//current buffer, 最后发现似乎用不到
    char pre_buf[64];//previous_buffer:like xx| ab
    char *p_pre_buf = pre_buf;
    int lat_buf_size = argc-1;
    int pre_buf_size = 0;
    int line_buf_size=0;//一行的缓冲长度，碰到1次\n就归零
    for(int i=0;i<lat_buf_size;i++){
        lat_buf[i] = argv[i+1];
    } 
    while((pre_buf_size=read(0, pre_buf, sizeof pre_buf))>0){
        // printf("pre_buf:%s\n", pre_buf);//获取先前命令的输出
        for(int i=0;i<pre_buf_size;i++){
            char cursor = pre_buf[i];
            if(cursor == '\n'){//碰到换行符执行一次pre_buf中的内容
                pre_buf[line_buf_size] = 0;
                lat_buf[lat_buf_size++] = p_pre_buf;
                lat_buf[lat_buf_size] = 0;
            if(fork()==0){//child's turn, 子进程执行新的语句
                exec(argv[1], lat_buf);
            }
            wait(0);
            lat_buf_size = argc-1;
            line_buf_size = 0;
            p_pre_buf = pre_buf;
        }
        else if(cursor ==' '){
            pre_buf[line_buf_size++] = 0;
            lat_buf[lat_buf_size++] = pre_buf;
            p_pre_buf = pre_buf + line_buf_size;
        }else{
            pre_buf[line_buf_size++] = cursor;
        }

}        

}
exit(0);
}