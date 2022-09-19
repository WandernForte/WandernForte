#include"user/user.h"
#include"kernel/pipe.c"
int sleep(int ticks){
    while(ticks--){
    }
    exit(ticks);
}
