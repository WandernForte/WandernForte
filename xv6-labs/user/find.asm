
user/_find：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <fmtname>:
#include "user/user.h"
#include "kernel/fs.h"

char*
fmtname(char *path)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	1800                	addi	s0,sp,48
   e:	84aa                	mv	s1,a0
  static char buf[DIRSIZ+1];//buffer
  char *p;//string

  // Find first character after last slash.
  for(p=path+strlen(path); p >= path && *p != '/'; p--)
  10:	00000097          	auipc	ra,0x0
  14:	37e080e7          	jalr	894(ra) # 38e <strlen>
  18:	02051793          	slli	a5,a0,0x20
  1c:	9381                	srli	a5,a5,0x20
  1e:	97a6                	add	a5,a5,s1
  20:	02f00693          	li	a3,47
  24:	0097e963          	bltu	a5,s1,36 <fmtname+0x36>
  28:	0007c703          	lbu	a4,0(a5)
  2c:	00d70563          	beq	a4,a3,36 <fmtname+0x36>
  30:	17fd                	addi	a5,a5,-1
  32:	fe97fbe3          	bgeu	a5,s1,28 <fmtname+0x28>
    ;
  p++;
  36:	00178493          	addi	s1,a5,1

  // Return blank-padded name.
  if(strlen(p) >= DIRSIZ)
  3a:	8526                	mv	a0,s1
  3c:	00000097          	auipc	ra,0x0
  40:	352080e7          	jalr	850(ra) # 38e <strlen>
  44:	2501                	sext.w	a0,a0
  46:	47b5                	li	a5,13
  48:	00a7fa63          	bgeu	a5,a0,5c <fmtname+0x5c>
    return p;
  memmove(buf, p, strlen(p));
  memset(buf+strlen(p), '\0', DIRSIZ-strlen(p));
  return buf;
}
  4c:	8526                	mv	a0,s1
  4e:	70a2                	ld	ra,40(sp)
  50:	7402                	ld	s0,32(sp)
  52:	64e2                	ld	s1,24(sp)
  54:	6942                	ld	s2,16(sp)
  56:	69a2                	ld	s3,8(sp)
  58:	6145                	addi	sp,sp,48
  5a:	8082                	ret
  memmove(buf, p, strlen(p));
  5c:	8526                	mv	a0,s1
  5e:	00000097          	auipc	ra,0x0
  62:	330080e7          	jalr	816(ra) # 38e <strlen>
  66:	00001997          	auipc	s3,0x1
  6a:	b7298993          	addi	s3,s3,-1166 # bd8 <buf.0>
  6e:	0005061b          	sext.w	a2,a0
  72:	85a6                	mv	a1,s1
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	48a080e7          	jalr	1162(ra) # 500 <memmove>
  memset(buf+strlen(p), '\0', DIRSIZ-strlen(p));
  7e:	8526                	mv	a0,s1
  80:	00000097          	auipc	ra,0x0
  84:	30e080e7          	jalr	782(ra) # 38e <strlen>
  88:	0005091b          	sext.w	s2,a0
  8c:	8526                	mv	a0,s1
  8e:	00000097          	auipc	ra,0x0
  92:	300080e7          	jalr	768(ra) # 38e <strlen>
  96:	1902                	slli	s2,s2,0x20
  98:	02095913          	srli	s2,s2,0x20
  9c:	4639                	li	a2,14
  9e:	9e09                	subw	a2,a2,a0
  a0:	4581                	li	a1,0
  a2:	01298533          	add	a0,s3,s2
  a6:	00000097          	auipc	ra,0x0
  aa:	312080e7          	jalr	786(ra) # 3b8 <memset>
  return buf;
  ae:	84ce                	mv	s1,s3
  b0:	bf71                	j	4c <fmtname+0x4c>

00000000000000b2 <find>:

void
find(char*dir, char *path)
{
  b2:	d8010113          	addi	sp,sp,-640
  b6:	26113c23          	sd	ra,632(sp)
  ba:	26813823          	sd	s0,624(sp)
  be:	26913423          	sd	s1,616(sp)
  c2:	27213023          	sd	s2,608(sp)
  c6:	25313c23          	sd	s3,600(sp)
  ca:	25413823          	sd	s4,592(sp)
  ce:	25513423          	sd	s5,584(sp)
  d2:	25613023          	sd	s6,576(sp)
  d6:	23713c23          	sd	s7,568(sp)
  da:	23813823          	sd	s8,560(sp)
  de:	0500                	addi	s0,sp,640
  e0:	892a                	mv	s2,a0
  e2:	89ae                	mv	s3,a1
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;
    //检查文件是否合法
    if((fd = open(dir, 0)) < 0){
  e4:	4581                	li	a1,0
  e6:	00000097          	auipc	ra,0x0
  ea:	50c080e7          	jalr	1292(ra) # 5f2 <open>
  ee:	06054f63          	bltz	a0,16c <find+0xba>
  f2:	84aa                	mv	s1,a0
        fprintf(2, "find: cannot find %s\n", dir);//未找到条目
        return;
    }

    if(fstat(fd, &st) < 0){
  f4:	d8840593          	addi	a1,s0,-632
  f8:	00000097          	auipc	ra,0x0
  fc:	512080e7          	jalr	1298(ra) # 60a <fstat>
 100:	08054163          	bltz	a0,182 <find+0xd0>
        fprintf(2, "find: cannot stat %s\n", dir);
        close(fd);
        return;
  }
//检查文件是否合法
  switch(st.type){//检查文件类型
 104:	d9041783          	lh	a5,-624(s0)
 108:	0007869b          	sext.w	a3,a5
 10c:	4705                	li	a4,1
 10e:	08e68a63          	beq	a3,a4,1a2 <find+0xf0>
 112:	4709                	li	a4,2
 114:	02e69063          	bne	a3,a4,134 <find+0x82>
  case T_FILE:
        printf("./%s\n", fmtname(path));//输出文件名
 118:	854e                	mv	a0,s3
 11a:	00000097          	auipc	ra,0x0
 11e:	ee6080e7          	jalr	-282(ra) # 0 <fmtname>
 122:	85aa                	mv	a1,a0
 124:	00001517          	auipc	a0,0x1
 128:	9dc50513          	addi	a0,a0,-1572 # b00 <malloc+0x11c>
 12c:	00001097          	auipc	ra,0x1
 130:	800080e7          	jalr	-2048(ra) # 92c <printf>
        }

        }
    break;
  }
  close(fd);
 134:	8526                	mv	a0,s1
 136:	00000097          	auipc	ra,0x0
 13a:	4a4080e7          	jalr	1188(ra) # 5da <close>
}
 13e:	27813083          	ld	ra,632(sp)
 142:	27013403          	ld	s0,624(sp)
 146:	26813483          	ld	s1,616(sp)
 14a:	26013903          	ld	s2,608(sp)
 14e:	25813983          	ld	s3,600(sp)
 152:	25013a03          	ld	s4,592(sp)
 156:	24813a83          	ld	s5,584(sp)
 15a:	24013b03          	ld	s6,576(sp)
 15e:	23813b83          	ld	s7,568(sp)
 162:	23013c03          	ld	s8,560(sp)
 166:	28010113          	addi	sp,sp,640
 16a:	8082                	ret
        fprintf(2, "find: cannot find %s\n", dir);//未找到条目
 16c:	864a                	mv	a2,s2
 16e:	00001597          	auipc	a1,0x1
 172:	96258593          	addi	a1,a1,-1694 # ad0 <malloc+0xec>
 176:	4509                	li	a0,2
 178:	00000097          	auipc	ra,0x0
 17c:	786080e7          	jalr	1926(ra) # 8fe <fprintf>
        return;
 180:	bf7d                	j	13e <find+0x8c>
        fprintf(2, "find: cannot stat %s\n", dir);
 182:	864a                	mv	a2,s2
 184:	00001597          	auipc	a1,0x1
 188:	96458593          	addi	a1,a1,-1692 # ae8 <malloc+0x104>
 18c:	4509                	li	a0,2
 18e:	00000097          	auipc	ra,0x0
 192:	770080e7          	jalr	1904(ra) # 8fe <fprintf>
        close(fd);
 196:	8526                	mv	a0,s1
 198:	00000097          	auipc	ra,0x0
 19c:	442080e7          	jalr	1090(ra) # 5da <close>
        return;
 1a0:	bf79                	j	13e <find+0x8c>
    if(strlen(dir) + 1 + DIRSIZ + 1 > sizeof buf){
 1a2:	854a                	mv	a0,s2
 1a4:	00000097          	auipc	ra,0x0
 1a8:	1ea080e7          	jalr	490(ra) # 38e <strlen>
 1ac:	2541                	addiw	a0,a0,16
 1ae:	20000793          	li	a5,512
 1b2:	00a7fb63          	bgeu	a5,a0,1c8 <find+0x116>
      printf("ls: path too long\n");
 1b6:	00001517          	auipc	a0,0x1
 1ba:	95250513          	addi	a0,a0,-1710 # b08 <malloc+0x124>
 1be:	00000097          	auipc	ra,0x0
 1c2:	76e080e7          	jalr	1902(ra) # 92c <printf>
      break;
 1c6:	b7bd                	j	134 <find+0x82>
    strcpy(buf, dir);
 1c8:	85ca                	mv	a1,s2
 1ca:	db040513          	addi	a0,s0,-592
 1ce:	00000097          	auipc	ra,0x0
 1d2:	178080e7          	jalr	376(ra) # 346 <strcpy>
    p = buf+strlen(buf);
 1d6:	db040513          	addi	a0,s0,-592
 1da:	00000097          	auipc	ra,0x0
 1de:	1b4080e7          	jalr	436(ra) # 38e <strlen>
 1e2:	1502                	slli	a0,a0,0x20
 1e4:	9101                	srli	a0,a0,0x20
 1e6:	db040793          	addi	a5,s0,-592
 1ea:	00a78933          	add	s2,a5,a0
    *p++ = '/';
 1ee:	00190a13          	addi	s4,s2,1
 1f2:	02f00793          	li	a5,47
 1f6:	00f90023          	sb	a5,0(s2)
        if(st.type==T_DIR && strcmp(fmtname(buf), ".")!=0&&strcmp(fmtname(buf), "..")!=0){
 1fa:	4a85                	li	s5,1
 1fc:	00001b97          	auipc	s7,0x1
 200:	92cb8b93          	addi	s7,s7,-1748 # b28 <malloc+0x144>
 204:	00001c17          	auipc	s8,0x1
 208:	92cc0c13          	addi	s8,s8,-1748 # b30 <malloc+0x14c>
            printf("%s\n", buf);
 20c:	00001b17          	auipc	s6,0x1
 210:	914b0b13          	addi	s6,s6,-1772 # b20 <malloc+0x13c>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 214:	a005                	j	234 <find+0x182>
            printf("find: cannot stat %s\n", buf);
 216:	db040593          	addi	a1,s0,-592
 21a:	00001517          	auipc	a0,0x1
 21e:	8ce50513          	addi	a0,a0,-1842 # ae8 <malloc+0x104>
 222:	00000097          	auipc	ra,0x0
 226:	70a080e7          	jalr	1802(ra) # 92c <printf>
            continue;
 22a:	a029                	j	234 <find+0x182>
        if(st.type==T_DIR && strcmp(fmtname(buf), ".")!=0&&strcmp(fmtname(buf), "..")!=0){
 22c:	d9041783          	lh	a5,-624(s0)
 230:	07578863          	beq	a5,s5,2a0 <find+0x1ee>
    while(read(fd, &de, sizeof(de)) == sizeof(de)){
 234:	4641                	li	a2,16
 236:	da040593          	addi	a1,s0,-608
 23a:	8526                	mv	a0,s1
 23c:	00000097          	auipc	ra,0x0
 240:	38e080e7          	jalr	910(ra) # 5ca <read>
 244:	47c1                	li	a5,16
 246:	eef517e3          	bne	a0,a5,134 <find+0x82>
        if(de.inum == 0){
 24a:	da045783          	lhu	a5,-608(s0)
 24e:	d3fd                	beqz	a5,234 <find+0x182>
        memmove(p, de.name, DIRSIZ);
 250:	4639                	li	a2,14
 252:	da240593          	addi	a1,s0,-606
 256:	8552                	mv	a0,s4
 258:	00000097          	auipc	ra,0x0
 25c:	2a8080e7          	jalr	680(ra) # 500 <memmove>
        p[DIRSIZ] = 0;
 260:	000907a3          	sb	zero,15(s2)
        if(stat(buf, &st)<0){
 264:	d8840593          	addi	a1,s0,-632
 268:	db040513          	addi	a0,s0,-592
 26c:	00000097          	auipc	ra,0x0
 270:	206080e7          	jalr	518(ra) # 472 <stat>
 274:	fa0541e3          	bltz	a0,216 <find+0x164>
        if(strcmp(fmtname(buf), path)==0){
 278:	db040513          	addi	a0,s0,-592
 27c:	00000097          	auipc	ra,0x0
 280:	d84080e7          	jalr	-636(ra) # 0 <fmtname>
 284:	85ce                	mv	a1,s3
 286:	00000097          	auipc	ra,0x0
 28a:	0dc080e7          	jalr	220(ra) # 362 <strcmp>
 28e:	fd59                	bnez	a0,22c <find+0x17a>
            printf("%s\n", buf);
 290:	db040593          	addi	a1,s0,-592
 294:	855a                	mv	a0,s6
 296:	00000097          	auipc	ra,0x0
 29a:	696080e7          	jalr	1686(ra) # 92c <printf>
 29e:	b779                	j	22c <find+0x17a>
        if(st.type==T_DIR && strcmp(fmtname(buf), ".")!=0&&strcmp(fmtname(buf), "..")!=0){
 2a0:	db040513          	addi	a0,s0,-592
 2a4:	00000097          	auipc	ra,0x0
 2a8:	d5c080e7          	jalr	-676(ra) # 0 <fmtname>
 2ac:	85de                	mv	a1,s7
 2ae:	00000097          	auipc	ra,0x0
 2b2:	0b4080e7          	jalr	180(ra) # 362 <strcmp>
 2b6:	dd3d                	beqz	a0,234 <find+0x182>
 2b8:	db040513          	addi	a0,s0,-592
 2bc:	00000097          	auipc	ra,0x0
 2c0:	d44080e7          	jalr	-700(ra) # 0 <fmtname>
 2c4:	85e2                	mv	a1,s8
 2c6:	00000097          	auipc	ra,0x0
 2ca:	09c080e7          	jalr	156(ra) # 362 <strcmp>
 2ce:	d13d                	beqz	a0,234 <find+0x182>
            find(buf,path);
 2d0:	85ce                	mv	a1,s3
 2d2:	db040513          	addi	a0,s0,-592
 2d6:	00000097          	auipc	ra,0x0
 2da:	ddc080e7          	jalr	-548(ra) # b2 <find>
 2de:	bf99                	j	234 <find+0x182>

00000000000002e0 <main>:

int main(int argc, char *argv[])
{
 2e0:	7179                	addi	sp,sp,-48
 2e2:	f406                	sd	ra,40(sp)
 2e4:	f022                	sd	s0,32(sp)
 2e6:	ec26                	sd	s1,24(sp)
 2e8:	e84a                	sd	s2,16(sp)
 2ea:	e44e                	sd	s3,8(sp)
 2ec:	1800                	addi	s0,sp,48
  int i;

  if(argc < 2){
 2ee:	4785                	li	a5,1
 2f0:	02a7de63          	bge	a5,a0,32c <main+0x4c>
 2f4:	00858493          	addi	s1,a1,8
 2f8:	ffe5091b          	addiw	s2,a0,-2
 2fc:	02091793          	slli	a5,s2,0x20
 300:	01d7d913          	srli	s2,a5,0x1d
 304:	05c1                	addi	a1,a1,16
 306:	992e                	add	s2,s2,a1
    printf("find: input cannot be null!");
    exit(0);
  }
  for(i=1; i<argc; i++)
    find(".",argv[i]);
 308:	00001997          	auipc	s3,0x1
 30c:	82098993          	addi	s3,s3,-2016 # b28 <malloc+0x144>
 310:	608c                	ld	a1,0(s1)
 312:	854e                	mv	a0,s3
 314:	00000097          	auipc	ra,0x0
 318:	d9e080e7          	jalr	-610(ra) # b2 <find>
  for(i=1; i<argc; i++)
 31c:	04a1                	addi	s1,s1,8
 31e:	ff2499e3          	bne	s1,s2,310 <main+0x30>
  exit(0);
 322:	4501                	li	a0,0
 324:	00000097          	auipc	ra,0x0
 328:	28e080e7          	jalr	654(ra) # 5b2 <exit>
    printf("find: input cannot be null!");
 32c:	00001517          	auipc	a0,0x1
 330:	80c50513          	addi	a0,a0,-2036 # b38 <malloc+0x154>
 334:	00000097          	auipc	ra,0x0
 338:	5f8080e7          	jalr	1528(ra) # 92c <printf>
    exit(0);
 33c:	4501                	li	a0,0
 33e:	00000097          	auipc	ra,0x0
 342:	274080e7          	jalr	628(ra) # 5b2 <exit>

0000000000000346 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 346:	1141                	addi	sp,sp,-16
 348:	e422                	sd	s0,8(sp)
 34a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 34c:	87aa                	mv	a5,a0
 34e:	0585                	addi	a1,a1,1
 350:	0785                	addi	a5,a5,1
 352:	fff5c703          	lbu	a4,-1(a1)
 356:	fee78fa3          	sb	a4,-1(a5)
 35a:	fb75                	bnez	a4,34e <strcpy+0x8>
    ;
  return os;
}
 35c:	6422                	ld	s0,8(sp)
 35e:	0141                	addi	sp,sp,16
 360:	8082                	ret

0000000000000362 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 362:	1141                	addi	sp,sp,-16
 364:	e422                	sd	s0,8(sp)
 366:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 368:	00054783          	lbu	a5,0(a0)
 36c:	cb91                	beqz	a5,380 <strcmp+0x1e>
 36e:	0005c703          	lbu	a4,0(a1)
 372:	00f71763          	bne	a4,a5,380 <strcmp+0x1e>
    p++, q++;
 376:	0505                	addi	a0,a0,1
 378:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 37a:	00054783          	lbu	a5,0(a0)
 37e:	fbe5                	bnez	a5,36e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 380:	0005c503          	lbu	a0,0(a1)
}
 384:	40a7853b          	subw	a0,a5,a0
 388:	6422                	ld	s0,8(sp)
 38a:	0141                	addi	sp,sp,16
 38c:	8082                	ret

000000000000038e <strlen>:

uint
strlen(const char *s)
{
 38e:	1141                	addi	sp,sp,-16
 390:	e422                	sd	s0,8(sp)
 392:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 394:	00054783          	lbu	a5,0(a0)
 398:	cf91                	beqz	a5,3b4 <strlen+0x26>
 39a:	0505                	addi	a0,a0,1
 39c:	87aa                	mv	a5,a0
 39e:	4685                	li	a3,1
 3a0:	9e89                	subw	a3,a3,a0
 3a2:	00f6853b          	addw	a0,a3,a5
 3a6:	0785                	addi	a5,a5,1
 3a8:	fff7c703          	lbu	a4,-1(a5)
 3ac:	fb7d                	bnez	a4,3a2 <strlen+0x14>
    ;
  return n;
}
 3ae:	6422                	ld	s0,8(sp)
 3b0:	0141                	addi	sp,sp,16
 3b2:	8082                	ret
  for(n = 0; s[n]; n++)
 3b4:	4501                	li	a0,0
 3b6:	bfe5                	j	3ae <strlen+0x20>

00000000000003b8 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3b8:	1141                	addi	sp,sp,-16
 3ba:	e422                	sd	s0,8(sp)
 3bc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3be:	ca19                	beqz	a2,3d4 <memset+0x1c>
 3c0:	87aa                	mv	a5,a0
 3c2:	1602                	slli	a2,a2,0x20
 3c4:	9201                	srli	a2,a2,0x20
 3c6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3ca:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3ce:	0785                	addi	a5,a5,1
 3d0:	fee79de3          	bne	a5,a4,3ca <memset+0x12>
  }
  return dst;
}
 3d4:	6422                	ld	s0,8(sp)
 3d6:	0141                	addi	sp,sp,16
 3d8:	8082                	ret

00000000000003da <strchr>:

char*
strchr(const char *s, char c)
{
 3da:	1141                	addi	sp,sp,-16
 3dc:	e422                	sd	s0,8(sp)
 3de:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3e0:	00054783          	lbu	a5,0(a0)
 3e4:	cb99                	beqz	a5,3fa <strchr+0x20>
    if(*s == c)
 3e6:	00f58763          	beq	a1,a5,3f4 <strchr+0x1a>
  for(; *s; s++)
 3ea:	0505                	addi	a0,a0,1
 3ec:	00054783          	lbu	a5,0(a0)
 3f0:	fbfd                	bnez	a5,3e6 <strchr+0xc>
      return (char*)s;
  return 0;
 3f2:	4501                	li	a0,0
}
 3f4:	6422                	ld	s0,8(sp)
 3f6:	0141                	addi	sp,sp,16
 3f8:	8082                	ret
  return 0;
 3fa:	4501                	li	a0,0
 3fc:	bfe5                	j	3f4 <strchr+0x1a>

00000000000003fe <gets>:

char*
gets(char *buf, int max)
{
 3fe:	711d                	addi	sp,sp,-96
 400:	ec86                	sd	ra,88(sp)
 402:	e8a2                	sd	s0,80(sp)
 404:	e4a6                	sd	s1,72(sp)
 406:	e0ca                	sd	s2,64(sp)
 408:	fc4e                	sd	s3,56(sp)
 40a:	f852                	sd	s4,48(sp)
 40c:	f456                	sd	s5,40(sp)
 40e:	f05a                	sd	s6,32(sp)
 410:	ec5e                	sd	s7,24(sp)
 412:	1080                	addi	s0,sp,96
 414:	8baa                	mv	s7,a0
 416:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 418:	892a                	mv	s2,a0
 41a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 41c:	4aa9                	li	s5,10
 41e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 420:	89a6                	mv	s3,s1
 422:	2485                	addiw	s1,s1,1
 424:	0344d863          	bge	s1,s4,454 <gets+0x56>
    cc = read(0, &c, 1);
 428:	4605                	li	a2,1
 42a:	faf40593          	addi	a1,s0,-81
 42e:	4501                	li	a0,0
 430:	00000097          	auipc	ra,0x0
 434:	19a080e7          	jalr	410(ra) # 5ca <read>
    if(cc < 1)
 438:	00a05e63          	blez	a0,454 <gets+0x56>
    buf[i++] = c;
 43c:	faf44783          	lbu	a5,-81(s0)
 440:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 444:	01578763          	beq	a5,s5,452 <gets+0x54>
 448:	0905                	addi	s2,s2,1
 44a:	fd679be3          	bne	a5,s6,420 <gets+0x22>
  for(i=0; i+1 < max; ){
 44e:	89a6                	mv	s3,s1
 450:	a011                	j	454 <gets+0x56>
 452:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 454:	99de                	add	s3,s3,s7
 456:	00098023          	sb	zero,0(s3)
  return buf;
}
 45a:	855e                	mv	a0,s7
 45c:	60e6                	ld	ra,88(sp)
 45e:	6446                	ld	s0,80(sp)
 460:	64a6                	ld	s1,72(sp)
 462:	6906                	ld	s2,64(sp)
 464:	79e2                	ld	s3,56(sp)
 466:	7a42                	ld	s4,48(sp)
 468:	7aa2                	ld	s5,40(sp)
 46a:	7b02                	ld	s6,32(sp)
 46c:	6be2                	ld	s7,24(sp)
 46e:	6125                	addi	sp,sp,96
 470:	8082                	ret

0000000000000472 <stat>:

int
stat(const char *n, struct stat *st)
{
 472:	1101                	addi	sp,sp,-32
 474:	ec06                	sd	ra,24(sp)
 476:	e822                	sd	s0,16(sp)
 478:	e426                	sd	s1,8(sp)
 47a:	e04a                	sd	s2,0(sp)
 47c:	1000                	addi	s0,sp,32
 47e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 480:	4581                	li	a1,0
 482:	00000097          	auipc	ra,0x0
 486:	170080e7          	jalr	368(ra) # 5f2 <open>
  if(fd < 0)
 48a:	02054563          	bltz	a0,4b4 <stat+0x42>
 48e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 490:	85ca                	mv	a1,s2
 492:	00000097          	auipc	ra,0x0
 496:	178080e7          	jalr	376(ra) # 60a <fstat>
 49a:	892a                	mv	s2,a0
  close(fd);
 49c:	8526                	mv	a0,s1
 49e:	00000097          	auipc	ra,0x0
 4a2:	13c080e7          	jalr	316(ra) # 5da <close>
  return r;
}
 4a6:	854a                	mv	a0,s2
 4a8:	60e2                	ld	ra,24(sp)
 4aa:	6442                	ld	s0,16(sp)
 4ac:	64a2                	ld	s1,8(sp)
 4ae:	6902                	ld	s2,0(sp)
 4b0:	6105                	addi	sp,sp,32
 4b2:	8082                	ret
    return -1;
 4b4:	597d                	li	s2,-1
 4b6:	bfc5                	j	4a6 <stat+0x34>

00000000000004b8 <atoi>:

int
atoi(const char *s)
{
 4b8:	1141                	addi	sp,sp,-16
 4ba:	e422                	sd	s0,8(sp)
 4bc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4be:	00054683          	lbu	a3,0(a0)
 4c2:	fd06879b          	addiw	a5,a3,-48
 4c6:	0ff7f793          	zext.b	a5,a5
 4ca:	4625                	li	a2,9
 4cc:	02f66863          	bltu	a2,a5,4fc <atoi+0x44>
 4d0:	872a                	mv	a4,a0
  n = 0;
 4d2:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 4d4:	0705                	addi	a4,a4,1
 4d6:	0025179b          	slliw	a5,a0,0x2
 4da:	9fa9                	addw	a5,a5,a0
 4dc:	0017979b          	slliw	a5,a5,0x1
 4e0:	9fb5                	addw	a5,a5,a3
 4e2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4e6:	00074683          	lbu	a3,0(a4)
 4ea:	fd06879b          	addiw	a5,a3,-48
 4ee:	0ff7f793          	zext.b	a5,a5
 4f2:	fef671e3          	bgeu	a2,a5,4d4 <atoi+0x1c>
  return n;
}
 4f6:	6422                	ld	s0,8(sp)
 4f8:	0141                	addi	sp,sp,16
 4fa:	8082                	ret
  n = 0;
 4fc:	4501                	li	a0,0
 4fe:	bfe5                	j	4f6 <atoi+0x3e>

0000000000000500 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 500:	1141                	addi	sp,sp,-16
 502:	e422                	sd	s0,8(sp)
 504:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 506:	02b57463          	bgeu	a0,a1,52e <memmove+0x2e>
    while(n-- > 0)
 50a:	00c05f63          	blez	a2,528 <memmove+0x28>
 50e:	1602                	slli	a2,a2,0x20
 510:	9201                	srli	a2,a2,0x20
 512:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 516:	872a                	mv	a4,a0
      *dst++ = *src++;
 518:	0585                	addi	a1,a1,1
 51a:	0705                	addi	a4,a4,1
 51c:	fff5c683          	lbu	a3,-1(a1)
 520:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 524:	fee79ae3          	bne	a5,a4,518 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 528:	6422                	ld	s0,8(sp)
 52a:	0141                	addi	sp,sp,16
 52c:	8082                	ret
    dst += n;
 52e:	00c50733          	add	a4,a0,a2
    src += n;
 532:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 534:	fec05ae3          	blez	a2,528 <memmove+0x28>
 538:	fff6079b          	addiw	a5,a2,-1
 53c:	1782                	slli	a5,a5,0x20
 53e:	9381                	srli	a5,a5,0x20
 540:	fff7c793          	not	a5,a5
 544:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 546:	15fd                	addi	a1,a1,-1
 548:	177d                	addi	a4,a4,-1
 54a:	0005c683          	lbu	a3,0(a1)
 54e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 552:	fee79ae3          	bne	a5,a4,546 <memmove+0x46>
 556:	bfc9                	j	528 <memmove+0x28>

0000000000000558 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 558:	1141                	addi	sp,sp,-16
 55a:	e422                	sd	s0,8(sp)
 55c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 55e:	ca05                	beqz	a2,58e <memcmp+0x36>
 560:	fff6069b          	addiw	a3,a2,-1
 564:	1682                	slli	a3,a3,0x20
 566:	9281                	srli	a3,a3,0x20
 568:	0685                	addi	a3,a3,1
 56a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 56c:	00054783          	lbu	a5,0(a0)
 570:	0005c703          	lbu	a4,0(a1)
 574:	00e79863          	bne	a5,a4,584 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 578:	0505                	addi	a0,a0,1
    p2++;
 57a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 57c:	fed518e3          	bne	a0,a3,56c <memcmp+0x14>
  }
  return 0;
 580:	4501                	li	a0,0
 582:	a019                	j	588 <memcmp+0x30>
      return *p1 - *p2;
 584:	40e7853b          	subw	a0,a5,a4
}
 588:	6422                	ld	s0,8(sp)
 58a:	0141                	addi	sp,sp,16
 58c:	8082                	ret
  return 0;
 58e:	4501                	li	a0,0
 590:	bfe5                	j	588 <memcmp+0x30>

0000000000000592 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 592:	1141                	addi	sp,sp,-16
 594:	e406                	sd	ra,8(sp)
 596:	e022                	sd	s0,0(sp)
 598:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 59a:	00000097          	auipc	ra,0x0
 59e:	f66080e7          	jalr	-154(ra) # 500 <memmove>
}
 5a2:	60a2                	ld	ra,8(sp)
 5a4:	6402                	ld	s0,0(sp)
 5a6:	0141                	addi	sp,sp,16
 5a8:	8082                	ret

00000000000005aa <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5aa:	4885                	li	a7,1
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 5b2:	4889                	li	a7,2
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <wait>:
.global wait
wait:
 li a7, SYS_wait
 5ba:	488d                	li	a7,3
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5c2:	4891                	li	a7,4
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <read>:
.global read
read:
 li a7, SYS_read
 5ca:	4895                	li	a7,5
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <write>:
.global write
write:
 li a7, SYS_write
 5d2:	48c1                	li	a7,16
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <close>:
.global close
close:
 li a7, SYS_close
 5da:	48d5                	li	a7,21
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 5e2:	4899                	li	a7,6
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <exec>:
.global exec
exec:
 li a7, SYS_exec
 5ea:	489d                	li	a7,7
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <open>:
.global open
open:
 li a7, SYS_open
 5f2:	48bd                	li	a7,15
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5fa:	48c5                	li	a7,17
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 602:	48c9                	li	a7,18
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 60a:	48a1                	li	a7,8
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <link>:
.global link
link:
 li a7, SYS_link
 612:	48cd                	li	a7,19
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 61a:	48d1                	li	a7,20
 ecall
 61c:	00000073          	ecall
 ret
 620:	8082                	ret

0000000000000622 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 622:	48a5                	li	a7,9
 ecall
 624:	00000073          	ecall
 ret
 628:	8082                	ret

000000000000062a <dup>:
.global dup
dup:
 li a7, SYS_dup
 62a:	48a9                	li	a7,10
 ecall
 62c:	00000073          	ecall
 ret
 630:	8082                	ret

0000000000000632 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 632:	48ad                	li	a7,11
 ecall
 634:	00000073          	ecall
 ret
 638:	8082                	ret

000000000000063a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 63a:	48b1                	li	a7,12
 ecall
 63c:	00000073          	ecall
 ret
 640:	8082                	ret

0000000000000642 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 642:	48b5                	li	a7,13
 ecall
 644:	00000073          	ecall
 ret
 648:	8082                	ret

000000000000064a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 64a:	48b9                	li	a7,14
 ecall
 64c:	00000073          	ecall
 ret
 650:	8082                	ret

0000000000000652 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 652:	1101                	addi	sp,sp,-32
 654:	ec06                	sd	ra,24(sp)
 656:	e822                	sd	s0,16(sp)
 658:	1000                	addi	s0,sp,32
 65a:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 65e:	4605                	li	a2,1
 660:	fef40593          	addi	a1,s0,-17
 664:	00000097          	auipc	ra,0x0
 668:	f6e080e7          	jalr	-146(ra) # 5d2 <write>
}
 66c:	60e2                	ld	ra,24(sp)
 66e:	6442                	ld	s0,16(sp)
 670:	6105                	addi	sp,sp,32
 672:	8082                	ret

0000000000000674 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 674:	7139                	addi	sp,sp,-64
 676:	fc06                	sd	ra,56(sp)
 678:	f822                	sd	s0,48(sp)
 67a:	f426                	sd	s1,40(sp)
 67c:	f04a                	sd	s2,32(sp)
 67e:	ec4e                	sd	s3,24(sp)
 680:	0080                	addi	s0,sp,64
 682:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 684:	c299                	beqz	a3,68a <printint+0x16>
 686:	0805c963          	bltz	a1,718 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 68a:	2581                	sext.w	a1,a1
  neg = 0;
 68c:	4881                	li	a7,0
 68e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 692:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 694:	2601                	sext.w	a2,a2
 696:	00000517          	auipc	a0,0x0
 69a:	52250513          	addi	a0,a0,1314 # bb8 <digits>
 69e:	883a                	mv	a6,a4
 6a0:	2705                	addiw	a4,a4,1
 6a2:	02c5f7bb          	remuw	a5,a1,a2
 6a6:	1782                	slli	a5,a5,0x20
 6a8:	9381                	srli	a5,a5,0x20
 6aa:	97aa                	add	a5,a5,a0
 6ac:	0007c783          	lbu	a5,0(a5)
 6b0:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6b4:	0005879b          	sext.w	a5,a1
 6b8:	02c5d5bb          	divuw	a1,a1,a2
 6bc:	0685                	addi	a3,a3,1
 6be:	fec7f0e3          	bgeu	a5,a2,69e <printint+0x2a>
  if(neg)
 6c2:	00088c63          	beqz	a7,6da <printint+0x66>
    buf[i++] = '-';
 6c6:	fd070793          	addi	a5,a4,-48
 6ca:	00878733          	add	a4,a5,s0
 6ce:	02d00793          	li	a5,45
 6d2:	fef70823          	sb	a5,-16(a4)
 6d6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6da:	02e05863          	blez	a4,70a <printint+0x96>
 6de:	fc040793          	addi	a5,s0,-64
 6e2:	00e78933          	add	s2,a5,a4
 6e6:	fff78993          	addi	s3,a5,-1
 6ea:	99ba                	add	s3,s3,a4
 6ec:	377d                	addiw	a4,a4,-1
 6ee:	1702                	slli	a4,a4,0x20
 6f0:	9301                	srli	a4,a4,0x20
 6f2:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6f6:	fff94583          	lbu	a1,-1(s2)
 6fa:	8526                	mv	a0,s1
 6fc:	00000097          	auipc	ra,0x0
 700:	f56080e7          	jalr	-170(ra) # 652 <putc>
  while(--i >= 0)
 704:	197d                	addi	s2,s2,-1
 706:	ff3918e3          	bne	s2,s3,6f6 <printint+0x82>
}
 70a:	70e2                	ld	ra,56(sp)
 70c:	7442                	ld	s0,48(sp)
 70e:	74a2                	ld	s1,40(sp)
 710:	7902                	ld	s2,32(sp)
 712:	69e2                	ld	s3,24(sp)
 714:	6121                	addi	sp,sp,64
 716:	8082                	ret
    x = -xx;
 718:	40b005bb          	negw	a1,a1
    neg = 1;
 71c:	4885                	li	a7,1
    x = -xx;
 71e:	bf85                	j	68e <printint+0x1a>

0000000000000720 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 720:	7119                	addi	sp,sp,-128
 722:	fc86                	sd	ra,120(sp)
 724:	f8a2                	sd	s0,112(sp)
 726:	f4a6                	sd	s1,104(sp)
 728:	f0ca                	sd	s2,96(sp)
 72a:	ecce                	sd	s3,88(sp)
 72c:	e8d2                	sd	s4,80(sp)
 72e:	e4d6                	sd	s5,72(sp)
 730:	e0da                	sd	s6,64(sp)
 732:	fc5e                	sd	s7,56(sp)
 734:	f862                	sd	s8,48(sp)
 736:	f466                	sd	s9,40(sp)
 738:	f06a                	sd	s10,32(sp)
 73a:	ec6e                	sd	s11,24(sp)
 73c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 73e:	0005c903          	lbu	s2,0(a1)
 742:	18090f63          	beqz	s2,8e0 <vprintf+0x1c0>
 746:	8aaa                	mv	s5,a0
 748:	8b32                	mv	s6,a2
 74a:	00158493          	addi	s1,a1,1
  state = 0;
 74e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 750:	02500a13          	li	s4,37
 754:	4c55                	li	s8,21
 756:	00000c97          	auipc	s9,0x0
 75a:	40ac8c93          	addi	s9,s9,1034 # b60 <malloc+0x17c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 75e:	02800d93          	li	s11,40
  putc(fd, 'x');
 762:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 764:	00000b97          	auipc	s7,0x0
 768:	454b8b93          	addi	s7,s7,1108 # bb8 <digits>
 76c:	a839                	j	78a <vprintf+0x6a>
        putc(fd, c);
 76e:	85ca                	mv	a1,s2
 770:	8556                	mv	a0,s5
 772:	00000097          	auipc	ra,0x0
 776:	ee0080e7          	jalr	-288(ra) # 652 <putc>
 77a:	a019                	j	780 <vprintf+0x60>
    } else if(state == '%'){
 77c:	01498d63          	beq	s3,s4,796 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 780:	0485                	addi	s1,s1,1
 782:	fff4c903          	lbu	s2,-1(s1)
 786:	14090d63          	beqz	s2,8e0 <vprintf+0x1c0>
    if(state == 0){
 78a:	fe0999e3          	bnez	s3,77c <vprintf+0x5c>
      if(c == '%'){
 78e:	ff4910e3          	bne	s2,s4,76e <vprintf+0x4e>
        state = '%';
 792:	89d2                	mv	s3,s4
 794:	b7f5                	j	780 <vprintf+0x60>
      if(c == 'd'){
 796:	11490c63          	beq	s2,s4,8ae <vprintf+0x18e>
 79a:	f9d9079b          	addiw	a5,s2,-99
 79e:	0ff7f793          	zext.b	a5,a5
 7a2:	10fc6e63          	bltu	s8,a5,8be <vprintf+0x19e>
 7a6:	f9d9079b          	addiw	a5,s2,-99
 7aa:	0ff7f713          	zext.b	a4,a5
 7ae:	10ec6863          	bltu	s8,a4,8be <vprintf+0x19e>
 7b2:	00271793          	slli	a5,a4,0x2
 7b6:	97e6                	add	a5,a5,s9
 7b8:	439c                	lw	a5,0(a5)
 7ba:	97e6                	add	a5,a5,s9
 7bc:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 7be:	008b0913          	addi	s2,s6,8
 7c2:	4685                	li	a3,1
 7c4:	4629                	li	a2,10
 7c6:	000b2583          	lw	a1,0(s6)
 7ca:	8556                	mv	a0,s5
 7cc:	00000097          	auipc	ra,0x0
 7d0:	ea8080e7          	jalr	-344(ra) # 674 <printint>
 7d4:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 7d6:	4981                	li	s3,0
 7d8:	b765                	j	780 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7da:	008b0913          	addi	s2,s6,8
 7de:	4681                	li	a3,0
 7e0:	4629                	li	a2,10
 7e2:	000b2583          	lw	a1,0(s6)
 7e6:	8556                	mv	a0,s5
 7e8:	00000097          	auipc	ra,0x0
 7ec:	e8c080e7          	jalr	-372(ra) # 674 <printint>
 7f0:	8b4a                	mv	s6,s2
      state = 0;
 7f2:	4981                	li	s3,0
 7f4:	b771                	j	780 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7f6:	008b0913          	addi	s2,s6,8
 7fa:	4681                	li	a3,0
 7fc:	866a                	mv	a2,s10
 7fe:	000b2583          	lw	a1,0(s6)
 802:	8556                	mv	a0,s5
 804:	00000097          	auipc	ra,0x0
 808:	e70080e7          	jalr	-400(ra) # 674 <printint>
 80c:	8b4a                	mv	s6,s2
      state = 0;
 80e:	4981                	li	s3,0
 810:	bf85                	j	780 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 812:	008b0793          	addi	a5,s6,8
 816:	f8f43423          	sd	a5,-120(s0)
 81a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 81e:	03000593          	li	a1,48
 822:	8556                	mv	a0,s5
 824:	00000097          	auipc	ra,0x0
 828:	e2e080e7          	jalr	-466(ra) # 652 <putc>
  putc(fd, 'x');
 82c:	07800593          	li	a1,120
 830:	8556                	mv	a0,s5
 832:	00000097          	auipc	ra,0x0
 836:	e20080e7          	jalr	-480(ra) # 652 <putc>
 83a:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 83c:	03c9d793          	srli	a5,s3,0x3c
 840:	97de                	add	a5,a5,s7
 842:	0007c583          	lbu	a1,0(a5)
 846:	8556                	mv	a0,s5
 848:	00000097          	auipc	ra,0x0
 84c:	e0a080e7          	jalr	-502(ra) # 652 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 850:	0992                	slli	s3,s3,0x4
 852:	397d                	addiw	s2,s2,-1
 854:	fe0914e3          	bnez	s2,83c <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 858:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 85c:	4981                	li	s3,0
 85e:	b70d                	j	780 <vprintf+0x60>
        s = va_arg(ap, char*);
 860:	008b0913          	addi	s2,s6,8
 864:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 868:	02098163          	beqz	s3,88a <vprintf+0x16a>
        while(*s != 0){
 86c:	0009c583          	lbu	a1,0(s3)
 870:	c5ad                	beqz	a1,8da <vprintf+0x1ba>
          putc(fd, *s);
 872:	8556                	mv	a0,s5
 874:	00000097          	auipc	ra,0x0
 878:	dde080e7          	jalr	-546(ra) # 652 <putc>
          s++;
 87c:	0985                	addi	s3,s3,1
        while(*s != 0){
 87e:	0009c583          	lbu	a1,0(s3)
 882:	f9e5                	bnez	a1,872 <vprintf+0x152>
        s = va_arg(ap, char*);
 884:	8b4a                	mv	s6,s2
      state = 0;
 886:	4981                	li	s3,0
 888:	bde5                	j	780 <vprintf+0x60>
          s = "(null)";
 88a:	00000997          	auipc	s3,0x0
 88e:	2ce98993          	addi	s3,s3,718 # b58 <malloc+0x174>
        while(*s != 0){
 892:	85ee                	mv	a1,s11
 894:	bff9                	j	872 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 896:	008b0913          	addi	s2,s6,8
 89a:	000b4583          	lbu	a1,0(s6)
 89e:	8556                	mv	a0,s5
 8a0:	00000097          	auipc	ra,0x0
 8a4:	db2080e7          	jalr	-590(ra) # 652 <putc>
 8a8:	8b4a                	mv	s6,s2
      state = 0;
 8aa:	4981                	li	s3,0
 8ac:	bdd1                	j	780 <vprintf+0x60>
        putc(fd, c);
 8ae:	85d2                	mv	a1,s4
 8b0:	8556                	mv	a0,s5
 8b2:	00000097          	auipc	ra,0x0
 8b6:	da0080e7          	jalr	-608(ra) # 652 <putc>
      state = 0;
 8ba:	4981                	li	s3,0
 8bc:	b5d1                	j	780 <vprintf+0x60>
        putc(fd, '%');
 8be:	85d2                	mv	a1,s4
 8c0:	8556                	mv	a0,s5
 8c2:	00000097          	auipc	ra,0x0
 8c6:	d90080e7          	jalr	-624(ra) # 652 <putc>
        putc(fd, c);
 8ca:	85ca                	mv	a1,s2
 8cc:	8556                	mv	a0,s5
 8ce:	00000097          	auipc	ra,0x0
 8d2:	d84080e7          	jalr	-636(ra) # 652 <putc>
      state = 0;
 8d6:	4981                	li	s3,0
 8d8:	b565                	j	780 <vprintf+0x60>
        s = va_arg(ap, char*);
 8da:	8b4a                	mv	s6,s2
      state = 0;
 8dc:	4981                	li	s3,0
 8de:	b54d                	j	780 <vprintf+0x60>
    }
  }
}
 8e0:	70e6                	ld	ra,120(sp)
 8e2:	7446                	ld	s0,112(sp)
 8e4:	74a6                	ld	s1,104(sp)
 8e6:	7906                	ld	s2,96(sp)
 8e8:	69e6                	ld	s3,88(sp)
 8ea:	6a46                	ld	s4,80(sp)
 8ec:	6aa6                	ld	s5,72(sp)
 8ee:	6b06                	ld	s6,64(sp)
 8f0:	7be2                	ld	s7,56(sp)
 8f2:	7c42                	ld	s8,48(sp)
 8f4:	7ca2                	ld	s9,40(sp)
 8f6:	7d02                	ld	s10,32(sp)
 8f8:	6de2                	ld	s11,24(sp)
 8fa:	6109                	addi	sp,sp,128
 8fc:	8082                	ret

00000000000008fe <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8fe:	715d                	addi	sp,sp,-80
 900:	ec06                	sd	ra,24(sp)
 902:	e822                	sd	s0,16(sp)
 904:	1000                	addi	s0,sp,32
 906:	e010                	sd	a2,0(s0)
 908:	e414                	sd	a3,8(s0)
 90a:	e818                	sd	a4,16(s0)
 90c:	ec1c                	sd	a5,24(s0)
 90e:	03043023          	sd	a6,32(s0)
 912:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 916:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 91a:	8622                	mv	a2,s0
 91c:	00000097          	auipc	ra,0x0
 920:	e04080e7          	jalr	-508(ra) # 720 <vprintf>
}
 924:	60e2                	ld	ra,24(sp)
 926:	6442                	ld	s0,16(sp)
 928:	6161                	addi	sp,sp,80
 92a:	8082                	ret

000000000000092c <printf>:

void
printf(const char *fmt, ...)
{
 92c:	711d                	addi	sp,sp,-96
 92e:	ec06                	sd	ra,24(sp)
 930:	e822                	sd	s0,16(sp)
 932:	1000                	addi	s0,sp,32
 934:	e40c                	sd	a1,8(s0)
 936:	e810                	sd	a2,16(s0)
 938:	ec14                	sd	a3,24(s0)
 93a:	f018                	sd	a4,32(s0)
 93c:	f41c                	sd	a5,40(s0)
 93e:	03043823          	sd	a6,48(s0)
 942:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 946:	00840613          	addi	a2,s0,8
 94a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 94e:	85aa                	mv	a1,a0
 950:	4505                	li	a0,1
 952:	00000097          	auipc	ra,0x0
 956:	dce080e7          	jalr	-562(ra) # 720 <vprintf>
}
 95a:	60e2                	ld	ra,24(sp)
 95c:	6442                	ld	s0,16(sp)
 95e:	6125                	addi	sp,sp,96
 960:	8082                	ret

0000000000000962 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 962:	1141                	addi	sp,sp,-16
 964:	e422                	sd	s0,8(sp)
 966:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 968:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 96c:	00000797          	auipc	a5,0x0
 970:	2647b783          	ld	a5,612(a5) # bd0 <freep>
 974:	a02d                	j	99e <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 976:	4618                	lw	a4,8(a2)
 978:	9f2d                	addw	a4,a4,a1
 97a:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 97e:	6398                	ld	a4,0(a5)
 980:	6310                	ld	a2,0(a4)
 982:	a83d                	j	9c0 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 984:	ff852703          	lw	a4,-8(a0)
 988:	9f31                	addw	a4,a4,a2
 98a:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 98c:	ff053683          	ld	a3,-16(a0)
 990:	a091                	j	9d4 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 992:	6398                	ld	a4,0(a5)
 994:	00e7e463          	bltu	a5,a4,99c <free+0x3a>
 998:	00e6ea63          	bltu	a3,a4,9ac <free+0x4a>
{
 99c:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 99e:	fed7fae3          	bgeu	a5,a3,992 <free+0x30>
 9a2:	6398                	ld	a4,0(a5)
 9a4:	00e6e463          	bltu	a3,a4,9ac <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9a8:	fee7eae3          	bltu	a5,a4,99c <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 9ac:	ff852583          	lw	a1,-8(a0)
 9b0:	6390                	ld	a2,0(a5)
 9b2:	02059813          	slli	a6,a1,0x20
 9b6:	01c85713          	srli	a4,a6,0x1c
 9ba:	9736                	add	a4,a4,a3
 9bc:	fae60de3          	beq	a2,a4,976 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 9c0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9c4:	4790                	lw	a2,8(a5)
 9c6:	02061593          	slli	a1,a2,0x20
 9ca:	01c5d713          	srli	a4,a1,0x1c
 9ce:	973e                	add	a4,a4,a5
 9d0:	fae68ae3          	beq	a3,a4,984 <free+0x22>
    p->s.ptr = bp->s.ptr;
 9d4:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 9d6:	00000717          	auipc	a4,0x0
 9da:	1ef73d23          	sd	a5,506(a4) # bd0 <freep>
}
 9de:	6422                	ld	s0,8(sp)
 9e0:	0141                	addi	sp,sp,16
 9e2:	8082                	ret

00000000000009e4 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9e4:	7139                	addi	sp,sp,-64
 9e6:	fc06                	sd	ra,56(sp)
 9e8:	f822                	sd	s0,48(sp)
 9ea:	f426                	sd	s1,40(sp)
 9ec:	f04a                	sd	s2,32(sp)
 9ee:	ec4e                	sd	s3,24(sp)
 9f0:	e852                	sd	s4,16(sp)
 9f2:	e456                	sd	s5,8(sp)
 9f4:	e05a                	sd	s6,0(sp)
 9f6:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9f8:	02051493          	slli	s1,a0,0x20
 9fc:	9081                	srli	s1,s1,0x20
 9fe:	04bd                	addi	s1,s1,15
 a00:	8091                	srli	s1,s1,0x4
 a02:	0014899b          	addiw	s3,s1,1
 a06:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a08:	00000517          	auipc	a0,0x0
 a0c:	1c853503          	ld	a0,456(a0) # bd0 <freep>
 a10:	c515                	beqz	a0,a3c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a12:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a14:	4798                	lw	a4,8(a5)
 a16:	02977f63          	bgeu	a4,s1,a54 <malloc+0x70>
 a1a:	8a4e                	mv	s4,s3
 a1c:	0009871b          	sext.w	a4,s3
 a20:	6685                	lui	a3,0x1
 a22:	00d77363          	bgeu	a4,a3,a28 <malloc+0x44>
 a26:	6a05                	lui	s4,0x1
 a28:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a2c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a30:	00000917          	auipc	s2,0x0
 a34:	1a090913          	addi	s2,s2,416 # bd0 <freep>
  if(p == (char*)-1)
 a38:	5afd                	li	s5,-1
 a3a:	a895                	j	aae <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a3c:	00000797          	auipc	a5,0x0
 a40:	1ac78793          	addi	a5,a5,428 # be8 <base>
 a44:	00000717          	auipc	a4,0x0
 a48:	18f73623          	sd	a5,396(a4) # bd0 <freep>
 a4c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a4e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a52:	b7e1                	j	a1a <malloc+0x36>
      if(p->s.size == nunits)
 a54:	02e48c63          	beq	s1,a4,a8c <malloc+0xa8>
        p->s.size -= nunits;
 a58:	4137073b          	subw	a4,a4,s3
 a5c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a5e:	02071693          	slli	a3,a4,0x20
 a62:	01c6d713          	srli	a4,a3,0x1c
 a66:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a68:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a6c:	00000717          	auipc	a4,0x0
 a70:	16a73223          	sd	a0,356(a4) # bd0 <freep>
      return (void*)(p + 1);
 a74:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a78:	70e2                	ld	ra,56(sp)
 a7a:	7442                	ld	s0,48(sp)
 a7c:	74a2                	ld	s1,40(sp)
 a7e:	7902                	ld	s2,32(sp)
 a80:	69e2                	ld	s3,24(sp)
 a82:	6a42                	ld	s4,16(sp)
 a84:	6aa2                	ld	s5,8(sp)
 a86:	6b02                	ld	s6,0(sp)
 a88:	6121                	addi	sp,sp,64
 a8a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a8c:	6398                	ld	a4,0(a5)
 a8e:	e118                	sd	a4,0(a0)
 a90:	bff1                	j	a6c <malloc+0x88>
  hp->s.size = nu;
 a92:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a96:	0541                	addi	a0,a0,16
 a98:	00000097          	auipc	ra,0x0
 a9c:	eca080e7          	jalr	-310(ra) # 962 <free>
  return freep;
 aa0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 aa4:	d971                	beqz	a0,a78 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 aa6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 aa8:	4798                	lw	a4,8(a5)
 aaa:	fa9775e3          	bgeu	a4,s1,a54 <malloc+0x70>
    if(p == freep)
 aae:	00093703          	ld	a4,0(s2)
 ab2:	853e                	mv	a0,a5
 ab4:	fef719e3          	bne	a4,a5,aa6 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 ab8:	8552                	mv	a0,s4
 aba:	00000097          	auipc	ra,0x0
 abe:	b80080e7          	jalr	-1152(ra) # 63a <sbrk>
  if(p == (char*)-1)
 ac2:	fd5518e3          	bne	a0,s5,a92 <malloc+0xae>
        return 0;
 ac6:	4501                	li	a0,0
 ac8:	bf45                	j	a78 <malloc+0x94>
