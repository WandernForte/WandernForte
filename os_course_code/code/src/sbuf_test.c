#include "../include/csapp.h"
#include "../conc/sbuf.h"
#include <pthread.h>
#define MAX_SP 100
sbuf_t sp;
void *reader(void *wargs){
  sbuf_remove(&sp);
}
void *writer(void *wargs){
  // int arg =; 
  sbuf_insert(&sp, (int)wargs+1);
}
int main(int argc, char *argv[]){
    int stacksize = atoi(argv[1]);
    // printf("%s", argv[1]);
    pthread_t thread[stacksize];
    pthread_attr_t attr;
    long t;
    void *status;
    
   /* Initialize and set thread detached attribute */
    sbuf_init(&sp, stacksize);
    
    pthread_attr_init(&attr);
    // printf("runned here\n");
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
    
    
    for(t=0; t<stacksize; t++) {
      // printf("Main: creating thread %ld\n", t);
      if(t%10==0){
        pthread_create(&thread[t], &attr, writer, (void *)t);//writer
      }else{
        pthread_create(&thread[t], &attr, reader, (void *)t);//reader
      } 
      // pthread_exit(NULL);
      
      }
       for(t=0; t<stacksize; t++) {
        pthread_join(thread[t], &status);
        printf("items:%ld,slots:%ld\n",sp.items.__align, sp.slots.__align);
      }

    // pthread_create(pth, &attr, sbuf_insert);
    sbuf_deinit(&sp);
    pthread_attr_destroy(&attr);
    pthread_exit(NULL);
    return 0;
}
