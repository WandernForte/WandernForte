#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
  static char buf[DIRSIZ+1];//buffer
  char *p;//string

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
    ;
  p++;

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), '\0', DIRSIZ-strlen(p));
  return buf;
}

void
find(char*dir, char *path)
{
    // char* t_path=path;
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;
    //检查文件是否合法
    if((fd = open(dir, 0)) < 0){
        fprintf(2, "find: cannot find %s\n", dir);//未找到条目
        return;
    }

    if(fstat(fd, &st) < 0){
        fprintf(2, "find: cannot stat %s\n", dir);
        close(fd);
        return;
  }
//检查文件是否合法
  switch(st.type){//检查文件类型
  case T_FILE:
        printf("./%s\n", fmtname(path));//输出文件名
    break;

  case T_DIR://如果是文件夹
    if(strlen(dir) + 1 + DIRSIZ + 1 > sizeof buf){
      printf("ls: path too long\n");
      break;
    }
    strcpy(buf, dir);
    p = buf+strlen(buf);
    *p++ = '/';
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
        if(de.inum == 0){
            continue;
        }
        memmove(p, de.name, DIRSIZ);
        p[DIRSIZ] = 0;
        if(stat(buf, &st)<0){
            printf("find: cannot stat %s\n", buf);
            continue;
        }
        if(strcmp(fmtname(buf), path)==0){
            printf("%s\n", buf);
        }
        
        // 
        if(st.type==T_DIR && strcmp(fmtname(buf), ".")!=0&&strcmp(fmtname(buf), "..")!=0){
            find(buf,path);
            // printf("runned %s!\n", buf);
        }

        }
    break;
  }
  close(fd);
}

int main(int argc, char *argv[])
{
  int i;

  if(argc < 2){
    printf("find: input cannot be null!");
    exit(0);
  }
  for(i=1; i<argc; i++)
    find(".",argv[i]);
  exit(0);
}