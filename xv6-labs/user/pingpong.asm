
user/_pingpong：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <print_recv_msg>:
#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"
void print_recv_msg(char* content){
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
   8:	85aa                	mv	a1,a0
    printf("recieved %s", content);
   a:	00001517          	auipc	a0,0x1
   e:	86e50513          	addi	a0,a0,-1938 # 878 <malloc+0xe6>
  12:	00000097          	auipc	ra,0x0
  16:	6c8080e7          	jalr	1736(ra) # 6da <printf>
}
  1a:	60a2                	ld	ra,8(sp)
  1c:	6402                	ld	s0,0(sp)
  1e:	0141                	addi	sp,sp,16
  20:	8082                	ret

0000000000000022 <main>:

int main(int argc,char* argv[]){
  22:	7179                	addi	sp,sp,-48
  24:	f406                	sd	ra,40(sp)
  26:	f022                	sd	s0,32(sp)
  28:	1800                	addi	s0,sp,48
    // int stat;
    pid_t pid_c, pid_p;
    int p2c[2]={1, 0};
  2a:	4785                	li	a5,1
  2c:	fef42423          	sw	a5,-24(s0)
  30:	fe042623          	sw	zero,-20(s0)
    int c2p[2]={0, 1};
  34:	fe042023          	sw	zero,-32(s0)
  38:	fef42223          	sw	a5,-28(s0)
    int stat;
    pipe(p2c);
  3c:	fe840513          	addi	a0,s0,-24
  40:	00000097          	auipc	ra,0x0
  44:	330080e7          	jalr	816(ra) # 370 <pipe>
    // pid_p = getpid();
    if((pid_c=fork())<0){
  48:	00000097          	auipc	ra,0x0
  4c:	310080e7          	jalr	784(ra) # 358 <fork>
  50:	04054163          	bltz	a0,92 <main+0x70>
        printf("ERROR!\n");
    }
    if(pid_c==0){//child_proc runs
  54:	e539                	bnez	a0,a2 <main+0x80>
        //TODO
        pipe(c2p);
  56:	fe040513          	addi	a0,s0,-32
  5a:	00000097          	auipc	ra,0x0
  5e:	316080e7          	jalr	790(ra) # 370 <pipe>
        char* content="";
        read(c2p[0], content, 4);
  62:	4611                	li	a2,4
  64:	00001597          	auipc	a1,0x1
  68:	82c58593          	addi	a1,a1,-2004 # 890 <malloc+0xfe>
  6c:	fe042503          	lw	a0,-32(s0)
  70:	00000097          	auipc	ra,0x0
  74:	308080e7          	jalr	776(ra) # 378 <read>
        print_recv_msg(content);
  78:	00001517          	auipc	a0,0x1
  7c:	81850513          	addi	a0,a0,-2024 # 890 <malloc+0xfe>
  80:	00000097          	auipc	ra,0x0
  84:	f80080e7          	jalr	-128(ra) # 0 <print_recv_msg>
        exit(0);
  88:	4501                	li	a0,0
  8a:	00000097          	auipc	ra,0x0
  8e:	2d6080e7          	jalr	726(ra) # 360 <exit>
        printf("ERROR!\n");
  92:	00000517          	auipc	a0,0x0
  96:	7f650513          	addi	a0,a0,2038 # 888 <malloc+0xf6>
  9a:	00000097          	auipc	ra,0x0
  9e:	640080e7          	jalr	1600(ra) # 6da <printf>
    }
    else{//parent proc runs
        write(p2c[1],"ping",4);
  a2:	4611                	li	a2,4
  a4:	00000597          	auipc	a1,0x0
  a8:	7f458593          	addi	a1,a1,2036 # 898 <malloc+0x106>
  ac:	fec42503          	lw	a0,-20(s0)
  b0:	00000097          	auipc	ra,0x0
  b4:	2d0080e7          	jalr	720(ra) # 380 <write>
        wait(&stat);
  b8:	fdc40513          	addi	a0,s0,-36
  bc:	00000097          	auipc	ra,0x0
  c0:	2ac080e7          	jalr	684(ra) # 368 <wait>
        char* content="";
        read(p2c[0], content, 4);
  c4:	4611                	li	a2,4
  c6:	00000597          	auipc	a1,0x0
  ca:	7ca58593          	addi	a1,a1,1994 # 890 <malloc+0xfe>
  ce:	fe842503          	lw	a0,-24(s0)
  d2:	00000097          	auipc	ra,0x0
  d6:	2a6080e7          	jalr	678(ra) # 378 <read>
        print_recv_msg(content);
  da:	00000517          	auipc	a0,0x0
  de:	7b650513          	addi	a0,a0,1974 # 890 <malloc+0xfe>
  e2:	00000097          	auipc	ra,0x0
  e6:	f1e080e7          	jalr	-226(ra) # 0 <print_recv_msg>
        //TODO
        exit(0);
  ea:	4501                	li	a0,0
  ec:	00000097          	auipc	ra,0x0
  f0:	274080e7          	jalr	628(ra) # 360 <exit>

00000000000000f4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  f4:	1141                	addi	sp,sp,-16
  f6:	e422                	sd	s0,8(sp)
  f8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  fa:	87aa                	mv	a5,a0
  fc:	0585                	addi	a1,a1,1
  fe:	0785                	addi	a5,a5,1
 100:	fff5c703          	lbu	a4,-1(a1)
 104:	fee78fa3          	sb	a4,-1(a5)
 108:	fb75                	bnez	a4,fc <strcpy+0x8>
    ;
  return os;
}
 10a:	6422                	ld	s0,8(sp)
 10c:	0141                	addi	sp,sp,16
 10e:	8082                	ret

0000000000000110 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 110:	1141                	addi	sp,sp,-16
 112:	e422                	sd	s0,8(sp)
 114:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 116:	00054783          	lbu	a5,0(a0)
 11a:	cb91                	beqz	a5,12e <strcmp+0x1e>
 11c:	0005c703          	lbu	a4,0(a1)
 120:	00f71763          	bne	a4,a5,12e <strcmp+0x1e>
    p++, q++;
 124:	0505                	addi	a0,a0,1
 126:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 128:	00054783          	lbu	a5,0(a0)
 12c:	fbe5                	bnez	a5,11c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 12e:	0005c503          	lbu	a0,0(a1)
}
 132:	40a7853b          	subw	a0,a5,a0
 136:	6422                	ld	s0,8(sp)
 138:	0141                	addi	sp,sp,16
 13a:	8082                	ret

000000000000013c <strlen>:

uint
strlen(const char *s)
{
 13c:	1141                	addi	sp,sp,-16
 13e:	e422                	sd	s0,8(sp)
 140:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 142:	00054783          	lbu	a5,0(a0)
 146:	cf91                	beqz	a5,162 <strlen+0x26>
 148:	0505                	addi	a0,a0,1
 14a:	87aa                	mv	a5,a0
 14c:	4685                	li	a3,1
 14e:	9e89                	subw	a3,a3,a0
 150:	00f6853b          	addw	a0,a3,a5
 154:	0785                	addi	a5,a5,1
 156:	fff7c703          	lbu	a4,-1(a5)
 15a:	fb7d                	bnez	a4,150 <strlen+0x14>
    ;
  return n;
}
 15c:	6422                	ld	s0,8(sp)
 15e:	0141                	addi	sp,sp,16
 160:	8082                	ret
  for(n = 0; s[n]; n++)
 162:	4501                	li	a0,0
 164:	bfe5                	j	15c <strlen+0x20>

0000000000000166 <memset>:

void*
memset(void *dst, int c, uint n)
{
 166:	1141                	addi	sp,sp,-16
 168:	e422                	sd	s0,8(sp)
 16a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 16c:	ca19                	beqz	a2,182 <memset+0x1c>
 16e:	87aa                	mv	a5,a0
 170:	1602                	slli	a2,a2,0x20
 172:	9201                	srli	a2,a2,0x20
 174:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 178:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 17c:	0785                	addi	a5,a5,1
 17e:	fee79de3          	bne	a5,a4,178 <memset+0x12>
  }
  return dst;
}
 182:	6422                	ld	s0,8(sp)
 184:	0141                	addi	sp,sp,16
 186:	8082                	ret

0000000000000188 <strchr>:

char*
strchr(const char *s, char c)
{
 188:	1141                	addi	sp,sp,-16
 18a:	e422                	sd	s0,8(sp)
 18c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18e:	00054783          	lbu	a5,0(a0)
 192:	cb99                	beqz	a5,1a8 <strchr+0x20>
    if(*s == c)
 194:	00f58763          	beq	a1,a5,1a2 <strchr+0x1a>
  for(; *s; s++)
 198:	0505                	addi	a0,a0,1
 19a:	00054783          	lbu	a5,0(a0)
 19e:	fbfd                	bnez	a5,194 <strchr+0xc>
      return (char*)s;
  return 0;
 1a0:	4501                	li	a0,0
}
 1a2:	6422                	ld	s0,8(sp)
 1a4:	0141                	addi	sp,sp,16
 1a6:	8082                	ret
  return 0;
 1a8:	4501                	li	a0,0
 1aa:	bfe5                	j	1a2 <strchr+0x1a>

00000000000001ac <gets>:

char*
gets(char *buf, int max)
{
 1ac:	711d                	addi	sp,sp,-96
 1ae:	ec86                	sd	ra,88(sp)
 1b0:	e8a2                	sd	s0,80(sp)
 1b2:	e4a6                	sd	s1,72(sp)
 1b4:	e0ca                	sd	s2,64(sp)
 1b6:	fc4e                	sd	s3,56(sp)
 1b8:	f852                	sd	s4,48(sp)
 1ba:	f456                	sd	s5,40(sp)
 1bc:	f05a                	sd	s6,32(sp)
 1be:	ec5e                	sd	s7,24(sp)
 1c0:	1080                	addi	s0,sp,96
 1c2:	8baa                	mv	s7,a0
 1c4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c6:	892a                	mv	s2,a0
 1c8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1ca:	4aa9                	li	s5,10
 1cc:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ce:	89a6                	mv	s3,s1
 1d0:	2485                	addiw	s1,s1,1
 1d2:	0344d863          	bge	s1,s4,202 <gets+0x56>
    cc = read(0, &c, 1);
 1d6:	4605                	li	a2,1
 1d8:	faf40593          	addi	a1,s0,-81
 1dc:	4501                	li	a0,0
 1de:	00000097          	auipc	ra,0x0
 1e2:	19a080e7          	jalr	410(ra) # 378 <read>
    if(cc < 1)
 1e6:	00a05e63          	blez	a0,202 <gets+0x56>
    buf[i++] = c;
 1ea:	faf44783          	lbu	a5,-81(s0)
 1ee:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1f2:	01578763          	beq	a5,s5,200 <gets+0x54>
 1f6:	0905                	addi	s2,s2,1
 1f8:	fd679be3          	bne	a5,s6,1ce <gets+0x22>
  for(i=0; i+1 < max; ){
 1fc:	89a6                	mv	s3,s1
 1fe:	a011                	j	202 <gets+0x56>
 200:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 202:	99de                	add	s3,s3,s7
 204:	00098023          	sb	zero,0(s3)
  return buf;
}
 208:	855e                	mv	a0,s7
 20a:	60e6                	ld	ra,88(sp)
 20c:	6446                	ld	s0,80(sp)
 20e:	64a6                	ld	s1,72(sp)
 210:	6906                	ld	s2,64(sp)
 212:	79e2                	ld	s3,56(sp)
 214:	7a42                	ld	s4,48(sp)
 216:	7aa2                	ld	s5,40(sp)
 218:	7b02                	ld	s6,32(sp)
 21a:	6be2                	ld	s7,24(sp)
 21c:	6125                	addi	sp,sp,96
 21e:	8082                	ret

0000000000000220 <stat>:

int
stat(const char *n, struct stat *st)
{
 220:	1101                	addi	sp,sp,-32
 222:	ec06                	sd	ra,24(sp)
 224:	e822                	sd	s0,16(sp)
 226:	e426                	sd	s1,8(sp)
 228:	e04a                	sd	s2,0(sp)
 22a:	1000                	addi	s0,sp,32
 22c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 22e:	4581                	li	a1,0
 230:	00000097          	auipc	ra,0x0
 234:	170080e7          	jalr	368(ra) # 3a0 <open>
  if(fd < 0)
 238:	02054563          	bltz	a0,262 <stat+0x42>
 23c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 23e:	85ca                	mv	a1,s2
 240:	00000097          	auipc	ra,0x0
 244:	178080e7          	jalr	376(ra) # 3b8 <fstat>
 248:	892a                	mv	s2,a0
  close(fd);
 24a:	8526                	mv	a0,s1
 24c:	00000097          	auipc	ra,0x0
 250:	13c080e7          	jalr	316(ra) # 388 <close>
  return r;
}
 254:	854a                	mv	a0,s2
 256:	60e2                	ld	ra,24(sp)
 258:	6442                	ld	s0,16(sp)
 25a:	64a2                	ld	s1,8(sp)
 25c:	6902                	ld	s2,0(sp)
 25e:	6105                	addi	sp,sp,32
 260:	8082                	ret
    return -1;
 262:	597d                	li	s2,-1
 264:	bfc5                	j	254 <stat+0x34>

0000000000000266 <atoi>:

int
atoi(const char *s)
{
 266:	1141                	addi	sp,sp,-16
 268:	e422                	sd	s0,8(sp)
 26a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 26c:	00054683          	lbu	a3,0(a0)
 270:	fd06879b          	addiw	a5,a3,-48
 274:	0ff7f793          	zext.b	a5,a5
 278:	4625                	li	a2,9
 27a:	02f66863          	bltu	a2,a5,2aa <atoi+0x44>
 27e:	872a                	mv	a4,a0
  n = 0;
 280:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 282:	0705                	addi	a4,a4,1
 284:	0025179b          	slliw	a5,a0,0x2
 288:	9fa9                	addw	a5,a5,a0
 28a:	0017979b          	slliw	a5,a5,0x1
 28e:	9fb5                	addw	a5,a5,a3
 290:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 294:	00074683          	lbu	a3,0(a4)
 298:	fd06879b          	addiw	a5,a3,-48
 29c:	0ff7f793          	zext.b	a5,a5
 2a0:	fef671e3          	bgeu	a2,a5,282 <atoi+0x1c>
  return n;
}
 2a4:	6422                	ld	s0,8(sp)
 2a6:	0141                	addi	sp,sp,16
 2a8:	8082                	ret
  n = 0;
 2aa:	4501                	li	a0,0
 2ac:	bfe5                	j	2a4 <atoi+0x3e>

00000000000002ae <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ae:	1141                	addi	sp,sp,-16
 2b0:	e422                	sd	s0,8(sp)
 2b2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2b4:	02b57463          	bgeu	a0,a1,2dc <memmove+0x2e>
    while(n-- > 0)
 2b8:	00c05f63          	blez	a2,2d6 <memmove+0x28>
 2bc:	1602                	slli	a2,a2,0x20
 2be:	9201                	srli	a2,a2,0x20
 2c0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2c4:	872a                	mv	a4,a0
      *dst++ = *src++;
 2c6:	0585                	addi	a1,a1,1
 2c8:	0705                	addi	a4,a4,1
 2ca:	fff5c683          	lbu	a3,-1(a1)
 2ce:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2d2:	fee79ae3          	bne	a5,a4,2c6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2d6:	6422                	ld	s0,8(sp)
 2d8:	0141                	addi	sp,sp,16
 2da:	8082                	ret
    dst += n;
 2dc:	00c50733          	add	a4,a0,a2
    src += n;
 2e0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2e2:	fec05ae3          	blez	a2,2d6 <memmove+0x28>
 2e6:	fff6079b          	addiw	a5,a2,-1
 2ea:	1782                	slli	a5,a5,0x20
 2ec:	9381                	srli	a5,a5,0x20
 2ee:	fff7c793          	not	a5,a5
 2f2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2f4:	15fd                	addi	a1,a1,-1
 2f6:	177d                	addi	a4,a4,-1
 2f8:	0005c683          	lbu	a3,0(a1)
 2fc:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 300:	fee79ae3          	bne	a5,a4,2f4 <memmove+0x46>
 304:	bfc9                	j	2d6 <memmove+0x28>

0000000000000306 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 306:	1141                	addi	sp,sp,-16
 308:	e422                	sd	s0,8(sp)
 30a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 30c:	ca05                	beqz	a2,33c <memcmp+0x36>
 30e:	fff6069b          	addiw	a3,a2,-1
 312:	1682                	slli	a3,a3,0x20
 314:	9281                	srli	a3,a3,0x20
 316:	0685                	addi	a3,a3,1
 318:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 31a:	00054783          	lbu	a5,0(a0)
 31e:	0005c703          	lbu	a4,0(a1)
 322:	00e79863          	bne	a5,a4,332 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 326:	0505                	addi	a0,a0,1
    p2++;
 328:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 32a:	fed518e3          	bne	a0,a3,31a <memcmp+0x14>
  }
  return 0;
 32e:	4501                	li	a0,0
 330:	a019                	j	336 <memcmp+0x30>
      return *p1 - *p2;
 332:	40e7853b          	subw	a0,a5,a4
}
 336:	6422                	ld	s0,8(sp)
 338:	0141                	addi	sp,sp,16
 33a:	8082                	ret
  return 0;
 33c:	4501                	li	a0,0
 33e:	bfe5                	j	336 <memcmp+0x30>

0000000000000340 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 340:	1141                	addi	sp,sp,-16
 342:	e406                	sd	ra,8(sp)
 344:	e022                	sd	s0,0(sp)
 346:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 348:	00000097          	auipc	ra,0x0
 34c:	f66080e7          	jalr	-154(ra) # 2ae <memmove>
}
 350:	60a2                	ld	ra,8(sp)
 352:	6402                	ld	s0,0(sp)
 354:	0141                	addi	sp,sp,16
 356:	8082                	ret

0000000000000358 <fork>:
 358:	4885                	li	a7,1
 35a:	00000073          	ecall
 35e:	8082                	ret

0000000000000360 <exit>:
 360:	4889                	li	a7,2
 362:	00000073          	ecall
 366:	8082                	ret

0000000000000368 <wait>:
 368:	488d                	li	a7,3
 36a:	00000073          	ecall
 36e:	8082                	ret

0000000000000370 <pipe>:
 370:	4891                	li	a7,4
 372:	00000073          	ecall
 376:	8082                	ret

0000000000000378 <read>:
 378:	4895                	li	a7,5
 37a:	00000073          	ecall
 37e:	8082                	ret

0000000000000380 <write>:
 380:	48c1                	li	a7,16
 382:	00000073          	ecall
 386:	8082                	ret

0000000000000388 <close>:
 388:	48d5                	li	a7,21
 38a:	00000073          	ecall
 38e:	8082                	ret

0000000000000390 <kill>:
 390:	4899                	li	a7,6
 392:	00000073          	ecall
 396:	8082                	ret

0000000000000398 <exec>:
 398:	489d                	li	a7,7
 39a:	00000073          	ecall
 39e:	8082                	ret

00000000000003a0 <open>:
 3a0:	48bd                	li	a7,15
 3a2:	00000073          	ecall
 3a6:	8082                	ret

00000000000003a8 <mknod>:
 3a8:	48c5                	li	a7,17
 3aa:	00000073          	ecall
 3ae:	8082                	ret

00000000000003b0 <unlink>:
 3b0:	48c9                	li	a7,18
 3b2:	00000073          	ecall
 3b6:	8082                	ret

00000000000003b8 <fstat>:
 3b8:	48a1                	li	a7,8
 3ba:	00000073          	ecall
 3be:	8082                	ret

00000000000003c0 <link>:
 3c0:	48cd                	li	a7,19
 3c2:	00000073          	ecall
 3c6:	8082                	ret

00000000000003c8 <mkdir>:
 3c8:	48d1                	li	a7,20
 3ca:	00000073          	ecall
 3ce:	8082                	ret

00000000000003d0 <chdir>:
 3d0:	48a5                	li	a7,9
 3d2:	00000073          	ecall
 3d6:	8082                	ret

00000000000003d8 <dup>:
 3d8:	48a9                	li	a7,10
 3da:	00000073          	ecall
 3de:	8082                	ret

00000000000003e0 <getpid>:
 3e0:	48ad                	li	a7,11
 3e2:	00000073          	ecall
 3e6:	8082                	ret

00000000000003e8 <sbrk>:
 3e8:	48b1                	li	a7,12
 3ea:	00000073          	ecall
 3ee:	8082                	ret

00000000000003f0 <sleep>:
 3f0:	48b5                	li	a7,13
 3f2:	00000073          	ecall
 3f6:	8082                	ret

00000000000003f8 <uptime>:
 3f8:	48b9                	li	a7,14
 3fa:	00000073          	ecall
 3fe:	8082                	ret

0000000000000400 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 400:	1101                	addi	sp,sp,-32
 402:	ec06                	sd	ra,24(sp)
 404:	e822                	sd	s0,16(sp)
 406:	1000                	addi	s0,sp,32
 408:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 40c:	4605                	li	a2,1
 40e:	fef40593          	addi	a1,s0,-17
 412:	00000097          	auipc	ra,0x0
 416:	f6e080e7          	jalr	-146(ra) # 380 <write>
}
 41a:	60e2                	ld	ra,24(sp)
 41c:	6442                	ld	s0,16(sp)
 41e:	6105                	addi	sp,sp,32
 420:	8082                	ret

0000000000000422 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 422:	7139                	addi	sp,sp,-64
 424:	fc06                	sd	ra,56(sp)
 426:	f822                	sd	s0,48(sp)
 428:	f426                	sd	s1,40(sp)
 42a:	f04a                	sd	s2,32(sp)
 42c:	ec4e                	sd	s3,24(sp)
 42e:	0080                	addi	s0,sp,64
 430:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 432:	c299                	beqz	a3,438 <printint+0x16>
 434:	0805c963          	bltz	a1,4c6 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 438:	2581                	sext.w	a1,a1
  neg = 0;
 43a:	4881                	li	a7,0
 43c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 440:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 442:	2601                	sext.w	a2,a2
 444:	00000517          	auipc	a0,0x0
 448:	4bc50513          	addi	a0,a0,1212 # 900 <digits>
 44c:	883a                	mv	a6,a4
 44e:	2705                	addiw	a4,a4,1
 450:	02c5f7bb          	remuw	a5,a1,a2
 454:	1782                	slli	a5,a5,0x20
 456:	9381                	srli	a5,a5,0x20
 458:	97aa                	add	a5,a5,a0
 45a:	0007c783          	lbu	a5,0(a5)
 45e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 462:	0005879b          	sext.w	a5,a1
 466:	02c5d5bb          	divuw	a1,a1,a2
 46a:	0685                	addi	a3,a3,1
 46c:	fec7f0e3          	bgeu	a5,a2,44c <printint+0x2a>
  if(neg)
 470:	00088c63          	beqz	a7,488 <printint+0x66>
    buf[i++] = '-';
 474:	fd070793          	addi	a5,a4,-48
 478:	00878733          	add	a4,a5,s0
 47c:	02d00793          	li	a5,45
 480:	fef70823          	sb	a5,-16(a4)
 484:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 488:	02e05863          	blez	a4,4b8 <printint+0x96>
 48c:	fc040793          	addi	a5,s0,-64
 490:	00e78933          	add	s2,a5,a4
 494:	fff78993          	addi	s3,a5,-1
 498:	99ba                	add	s3,s3,a4
 49a:	377d                	addiw	a4,a4,-1
 49c:	1702                	slli	a4,a4,0x20
 49e:	9301                	srli	a4,a4,0x20
 4a0:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4a4:	fff94583          	lbu	a1,-1(s2)
 4a8:	8526                	mv	a0,s1
 4aa:	00000097          	auipc	ra,0x0
 4ae:	f56080e7          	jalr	-170(ra) # 400 <putc>
  while(--i >= 0)
 4b2:	197d                	addi	s2,s2,-1
 4b4:	ff3918e3          	bne	s2,s3,4a4 <printint+0x82>
}
 4b8:	70e2                	ld	ra,56(sp)
 4ba:	7442                	ld	s0,48(sp)
 4bc:	74a2                	ld	s1,40(sp)
 4be:	7902                	ld	s2,32(sp)
 4c0:	69e2                	ld	s3,24(sp)
 4c2:	6121                	addi	sp,sp,64
 4c4:	8082                	ret
    x = -xx;
 4c6:	40b005bb          	negw	a1,a1
    neg = 1;
 4ca:	4885                	li	a7,1
    x = -xx;
 4cc:	bf85                	j	43c <printint+0x1a>

00000000000004ce <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4ce:	7119                	addi	sp,sp,-128
 4d0:	fc86                	sd	ra,120(sp)
 4d2:	f8a2                	sd	s0,112(sp)
 4d4:	f4a6                	sd	s1,104(sp)
 4d6:	f0ca                	sd	s2,96(sp)
 4d8:	ecce                	sd	s3,88(sp)
 4da:	e8d2                	sd	s4,80(sp)
 4dc:	e4d6                	sd	s5,72(sp)
 4de:	e0da                	sd	s6,64(sp)
 4e0:	fc5e                	sd	s7,56(sp)
 4e2:	f862                	sd	s8,48(sp)
 4e4:	f466                	sd	s9,40(sp)
 4e6:	f06a                	sd	s10,32(sp)
 4e8:	ec6e                	sd	s11,24(sp)
 4ea:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ec:	0005c903          	lbu	s2,0(a1)
 4f0:	18090f63          	beqz	s2,68e <vprintf+0x1c0>
 4f4:	8aaa                	mv	s5,a0
 4f6:	8b32                	mv	s6,a2
 4f8:	00158493          	addi	s1,a1,1
  state = 0;
 4fc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4fe:	02500a13          	li	s4,37
 502:	4c55                	li	s8,21
 504:	00000c97          	auipc	s9,0x0
 508:	3a4c8c93          	addi	s9,s9,932 # 8a8 <malloc+0x116>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 50c:	02800d93          	li	s11,40
  putc(fd, 'x');
 510:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 512:	00000b97          	auipc	s7,0x0
 516:	3eeb8b93          	addi	s7,s7,1006 # 900 <digits>
 51a:	a839                	j	538 <vprintf+0x6a>
        putc(fd, c);
 51c:	85ca                	mv	a1,s2
 51e:	8556                	mv	a0,s5
 520:	00000097          	auipc	ra,0x0
 524:	ee0080e7          	jalr	-288(ra) # 400 <putc>
 528:	a019                	j	52e <vprintf+0x60>
    } else if(state == '%'){
 52a:	01498d63          	beq	s3,s4,544 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 52e:	0485                	addi	s1,s1,1
 530:	fff4c903          	lbu	s2,-1(s1)
 534:	14090d63          	beqz	s2,68e <vprintf+0x1c0>
    if(state == 0){
 538:	fe0999e3          	bnez	s3,52a <vprintf+0x5c>
      if(c == '%'){
 53c:	ff4910e3          	bne	s2,s4,51c <vprintf+0x4e>
        state = '%';
 540:	89d2                	mv	s3,s4
 542:	b7f5                	j	52e <vprintf+0x60>
      if(c == 'd'){
 544:	11490c63          	beq	s2,s4,65c <vprintf+0x18e>
 548:	f9d9079b          	addiw	a5,s2,-99
 54c:	0ff7f793          	zext.b	a5,a5
 550:	10fc6e63          	bltu	s8,a5,66c <vprintf+0x19e>
 554:	f9d9079b          	addiw	a5,s2,-99
 558:	0ff7f713          	zext.b	a4,a5
 55c:	10ec6863          	bltu	s8,a4,66c <vprintf+0x19e>
 560:	00271793          	slli	a5,a4,0x2
 564:	97e6                	add	a5,a5,s9
 566:	439c                	lw	a5,0(a5)
 568:	97e6                	add	a5,a5,s9
 56a:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 56c:	008b0913          	addi	s2,s6,8
 570:	4685                	li	a3,1
 572:	4629                	li	a2,10
 574:	000b2583          	lw	a1,0(s6)
 578:	8556                	mv	a0,s5
 57a:	00000097          	auipc	ra,0x0
 57e:	ea8080e7          	jalr	-344(ra) # 422 <printint>
 582:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 584:	4981                	li	s3,0
 586:	b765                	j	52e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 588:	008b0913          	addi	s2,s6,8
 58c:	4681                	li	a3,0
 58e:	4629                	li	a2,10
 590:	000b2583          	lw	a1,0(s6)
 594:	8556                	mv	a0,s5
 596:	00000097          	auipc	ra,0x0
 59a:	e8c080e7          	jalr	-372(ra) # 422 <printint>
 59e:	8b4a                	mv	s6,s2
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b771                	j	52e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5a4:	008b0913          	addi	s2,s6,8
 5a8:	4681                	li	a3,0
 5aa:	866a                	mv	a2,s10
 5ac:	000b2583          	lw	a1,0(s6)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	e70080e7          	jalr	-400(ra) # 422 <printint>
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	bf85                	j	52e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5c0:	008b0793          	addi	a5,s6,8
 5c4:	f8f43423          	sd	a5,-120(s0)
 5c8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5cc:	03000593          	li	a1,48
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	e2e080e7          	jalr	-466(ra) # 400 <putc>
  putc(fd, 'x');
 5da:	07800593          	li	a1,120
 5de:	8556                	mv	a0,s5
 5e0:	00000097          	auipc	ra,0x0
 5e4:	e20080e7          	jalr	-480(ra) # 400 <putc>
 5e8:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5ea:	03c9d793          	srli	a5,s3,0x3c
 5ee:	97de                	add	a5,a5,s7
 5f0:	0007c583          	lbu	a1,0(a5)
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	e0a080e7          	jalr	-502(ra) # 400 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5fe:	0992                	slli	s3,s3,0x4
 600:	397d                	addiw	s2,s2,-1
 602:	fe0914e3          	bnez	s2,5ea <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 606:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 60a:	4981                	li	s3,0
 60c:	b70d                	j	52e <vprintf+0x60>
        s = va_arg(ap, char*);
 60e:	008b0913          	addi	s2,s6,8
 612:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 616:	02098163          	beqz	s3,638 <vprintf+0x16a>
        while(*s != 0){
 61a:	0009c583          	lbu	a1,0(s3)
 61e:	c5ad                	beqz	a1,688 <vprintf+0x1ba>
          putc(fd, *s);
 620:	8556                	mv	a0,s5
 622:	00000097          	auipc	ra,0x0
 626:	dde080e7          	jalr	-546(ra) # 400 <putc>
          s++;
 62a:	0985                	addi	s3,s3,1
        while(*s != 0){
 62c:	0009c583          	lbu	a1,0(s3)
 630:	f9e5                	bnez	a1,620 <vprintf+0x152>
        s = va_arg(ap, char*);
 632:	8b4a                	mv	s6,s2
      state = 0;
 634:	4981                	li	s3,0
 636:	bde5                	j	52e <vprintf+0x60>
          s = "(null)";
 638:	00000997          	auipc	s3,0x0
 63c:	26898993          	addi	s3,s3,616 # 8a0 <malloc+0x10e>
        while(*s != 0){
 640:	85ee                	mv	a1,s11
 642:	bff9                	j	620 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 644:	008b0913          	addi	s2,s6,8
 648:	000b4583          	lbu	a1,0(s6)
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	db2080e7          	jalr	-590(ra) # 400 <putc>
 656:	8b4a                	mv	s6,s2
      state = 0;
 658:	4981                	li	s3,0
 65a:	bdd1                	j	52e <vprintf+0x60>
        putc(fd, c);
 65c:	85d2                	mv	a1,s4
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	da0080e7          	jalr	-608(ra) # 400 <putc>
      state = 0;
 668:	4981                	li	s3,0
 66a:	b5d1                	j	52e <vprintf+0x60>
        putc(fd, '%');
 66c:	85d2                	mv	a1,s4
 66e:	8556                	mv	a0,s5
 670:	00000097          	auipc	ra,0x0
 674:	d90080e7          	jalr	-624(ra) # 400 <putc>
        putc(fd, c);
 678:	85ca                	mv	a1,s2
 67a:	8556                	mv	a0,s5
 67c:	00000097          	auipc	ra,0x0
 680:	d84080e7          	jalr	-636(ra) # 400 <putc>
      state = 0;
 684:	4981                	li	s3,0
 686:	b565                	j	52e <vprintf+0x60>
        s = va_arg(ap, char*);
 688:	8b4a                	mv	s6,s2
      state = 0;
 68a:	4981                	li	s3,0
 68c:	b54d                	j	52e <vprintf+0x60>
    }
  }
}
 68e:	70e6                	ld	ra,120(sp)
 690:	7446                	ld	s0,112(sp)
 692:	74a6                	ld	s1,104(sp)
 694:	7906                	ld	s2,96(sp)
 696:	69e6                	ld	s3,88(sp)
 698:	6a46                	ld	s4,80(sp)
 69a:	6aa6                	ld	s5,72(sp)
 69c:	6b06                	ld	s6,64(sp)
 69e:	7be2                	ld	s7,56(sp)
 6a0:	7c42                	ld	s8,48(sp)
 6a2:	7ca2                	ld	s9,40(sp)
 6a4:	7d02                	ld	s10,32(sp)
 6a6:	6de2                	ld	s11,24(sp)
 6a8:	6109                	addi	sp,sp,128
 6aa:	8082                	ret

00000000000006ac <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6ac:	715d                	addi	sp,sp,-80
 6ae:	ec06                	sd	ra,24(sp)
 6b0:	e822                	sd	s0,16(sp)
 6b2:	1000                	addi	s0,sp,32
 6b4:	e010                	sd	a2,0(s0)
 6b6:	e414                	sd	a3,8(s0)
 6b8:	e818                	sd	a4,16(s0)
 6ba:	ec1c                	sd	a5,24(s0)
 6bc:	03043023          	sd	a6,32(s0)
 6c0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6c4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6c8:	8622                	mv	a2,s0
 6ca:	00000097          	auipc	ra,0x0
 6ce:	e04080e7          	jalr	-508(ra) # 4ce <vprintf>
}
 6d2:	60e2                	ld	ra,24(sp)
 6d4:	6442                	ld	s0,16(sp)
 6d6:	6161                	addi	sp,sp,80
 6d8:	8082                	ret

00000000000006da <printf>:

void
printf(const char *fmt, ...)
{
 6da:	711d                	addi	sp,sp,-96
 6dc:	ec06                	sd	ra,24(sp)
 6de:	e822                	sd	s0,16(sp)
 6e0:	1000                	addi	s0,sp,32
 6e2:	e40c                	sd	a1,8(s0)
 6e4:	e810                	sd	a2,16(s0)
 6e6:	ec14                	sd	a3,24(s0)
 6e8:	f018                	sd	a4,32(s0)
 6ea:	f41c                	sd	a5,40(s0)
 6ec:	03043823          	sd	a6,48(s0)
 6f0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6f4:	00840613          	addi	a2,s0,8
 6f8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6fc:	85aa                	mv	a1,a0
 6fe:	4505                	li	a0,1
 700:	00000097          	auipc	ra,0x0
 704:	dce080e7          	jalr	-562(ra) # 4ce <vprintf>
}
 708:	60e2                	ld	ra,24(sp)
 70a:	6442                	ld	s0,16(sp)
 70c:	6125                	addi	sp,sp,96
 70e:	8082                	ret

0000000000000710 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 710:	1141                	addi	sp,sp,-16
 712:	e422                	sd	s0,8(sp)
 714:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 716:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 71a:	00000797          	auipc	a5,0x0
 71e:	1fe7b783          	ld	a5,510(a5) # 918 <freep>
 722:	a02d                	j	74c <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 724:	4618                	lw	a4,8(a2)
 726:	9f2d                	addw	a4,a4,a1
 728:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 72c:	6398                	ld	a4,0(a5)
 72e:	6310                	ld	a2,0(a4)
 730:	a83d                	j	76e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 732:	ff852703          	lw	a4,-8(a0)
 736:	9f31                	addw	a4,a4,a2
 738:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 73a:	ff053683          	ld	a3,-16(a0)
 73e:	a091                	j	782 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 740:	6398                	ld	a4,0(a5)
 742:	00e7e463          	bltu	a5,a4,74a <free+0x3a>
 746:	00e6ea63          	bltu	a3,a4,75a <free+0x4a>
{
 74a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 74c:	fed7fae3          	bgeu	a5,a3,740 <free+0x30>
 750:	6398                	ld	a4,0(a5)
 752:	00e6e463          	bltu	a3,a4,75a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 756:	fee7eae3          	bltu	a5,a4,74a <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 75a:	ff852583          	lw	a1,-8(a0)
 75e:	6390                	ld	a2,0(a5)
 760:	02059813          	slli	a6,a1,0x20
 764:	01c85713          	srli	a4,a6,0x1c
 768:	9736                	add	a4,a4,a3
 76a:	fae60de3          	beq	a2,a4,724 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 76e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 772:	4790                	lw	a2,8(a5)
 774:	02061593          	slli	a1,a2,0x20
 778:	01c5d713          	srli	a4,a1,0x1c
 77c:	973e                	add	a4,a4,a5
 77e:	fae68ae3          	beq	a3,a4,732 <free+0x22>
    p->s.ptr = bp->s.ptr;
 782:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 784:	00000717          	auipc	a4,0x0
 788:	18f73a23          	sd	a5,404(a4) # 918 <freep>
}
 78c:	6422                	ld	s0,8(sp)
 78e:	0141                	addi	sp,sp,16
 790:	8082                	ret

0000000000000792 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 792:	7139                	addi	sp,sp,-64
 794:	fc06                	sd	ra,56(sp)
 796:	f822                	sd	s0,48(sp)
 798:	f426                	sd	s1,40(sp)
 79a:	f04a                	sd	s2,32(sp)
 79c:	ec4e                	sd	s3,24(sp)
 79e:	e852                	sd	s4,16(sp)
 7a0:	e456                	sd	s5,8(sp)
 7a2:	e05a                	sd	s6,0(sp)
 7a4:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7a6:	02051493          	slli	s1,a0,0x20
 7aa:	9081                	srli	s1,s1,0x20
 7ac:	04bd                	addi	s1,s1,15
 7ae:	8091                	srli	s1,s1,0x4
 7b0:	0014899b          	addiw	s3,s1,1
 7b4:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7b6:	00000517          	auipc	a0,0x0
 7ba:	16253503          	ld	a0,354(a0) # 918 <freep>
 7be:	c515                	beqz	a0,7ea <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7c0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c2:	4798                	lw	a4,8(a5)
 7c4:	02977f63          	bgeu	a4,s1,802 <malloc+0x70>
 7c8:	8a4e                	mv	s4,s3
 7ca:	0009871b          	sext.w	a4,s3
 7ce:	6685                	lui	a3,0x1
 7d0:	00d77363          	bgeu	a4,a3,7d6 <malloc+0x44>
 7d4:	6a05                	lui	s4,0x1
 7d6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7da:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7de:	00000917          	auipc	s2,0x0
 7e2:	13a90913          	addi	s2,s2,314 # 918 <freep>
  if(p == (char*)-1)
 7e6:	5afd                	li	s5,-1
 7e8:	a895                	j	85c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7ea:	00000797          	auipc	a5,0x0
 7ee:	13678793          	addi	a5,a5,310 # 920 <base>
 7f2:	00000717          	auipc	a4,0x0
 7f6:	12f73323          	sd	a5,294(a4) # 918 <freep>
 7fa:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7fc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 800:	b7e1                	j	7c8 <malloc+0x36>
      if(p->s.size == nunits)
 802:	02e48c63          	beq	s1,a4,83a <malloc+0xa8>
        p->s.size -= nunits;
 806:	4137073b          	subw	a4,a4,s3
 80a:	c798                	sw	a4,8(a5)
        p += p->s.size;
 80c:	02071693          	slli	a3,a4,0x20
 810:	01c6d713          	srli	a4,a3,0x1c
 814:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 816:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 81a:	00000717          	auipc	a4,0x0
 81e:	0ea73f23          	sd	a0,254(a4) # 918 <freep>
      return (void*)(p + 1);
 822:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 826:	70e2                	ld	ra,56(sp)
 828:	7442                	ld	s0,48(sp)
 82a:	74a2                	ld	s1,40(sp)
 82c:	7902                	ld	s2,32(sp)
 82e:	69e2                	ld	s3,24(sp)
 830:	6a42                	ld	s4,16(sp)
 832:	6aa2                	ld	s5,8(sp)
 834:	6b02                	ld	s6,0(sp)
 836:	6121                	addi	sp,sp,64
 838:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 83a:	6398                	ld	a4,0(a5)
 83c:	e118                	sd	a4,0(a0)
 83e:	bff1                	j	81a <malloc+0x88>
  hp->s.size = nu;
 840:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 844:	0541                	addi	a0,a0,16
 846:	00000097          	auipc	ra,0x0
 84a:	eca080e7          	jalr	-310(ra) # 710 <free>
  return freep;
 84e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 852:	d971                	beqz	a0,826 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 854:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 856:	4798                	lw	a4,8(a5)
 858:	fa9775e3          	bgeu	a4,s1,802 <malloc+0x70>
    if(p == freep)
 85c:	00093703          	ld	a4,0(s2)
 860:	853e                	mv	a0,a5
 862:	fef719e3          	bne	a4,a5,854 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 866:	8552                	mv	a0,s4
 868:	00000097          	auipc	ra,0x0
 86c:	b80080e7          	jalr	-1152(ra) # 3e8 <sbrk>
  if(p == (char*)-1)
 870:	fd5518e3          	bne	a0,s5,840 <malloc+0xae>
        return 0;
 874:	4501                	li	a0,0
 876:	bf45                	j	826 <malloc+0x94>
