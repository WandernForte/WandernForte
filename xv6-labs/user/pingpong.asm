
user/_pingpong：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"
// #include "kernel/pipe.c"


int main(int argc,char* argv[]){
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    // int stat;
    pid_t pid_c, pid_p;
    pid_p = getpid();
   8:	00000097          	auipc	ra,0x0
   c:	324080e7          	jalr	804(ra) # 32c <getpid>
    if((pid_c=fork())<0){
  10:	00000097          	auipc	ra,0x0
  14:	294080e7          	jalr	660(ra) # 2a4 <fork>
  18:	00054763          	bltz	a0,26 <main+0x26>
        printf("ERROR!\n");
    }
    if(pid_c==0){//child_proc runs
  1c:	ed09                	bnez	a0,36 <main+0x36>
        //TODO
        exit(0);
  1e:	00000097          	auipc	ra,0x0
  22:	28e080e7          	jalr	654(ra) # 2ac <exit>
        printf("ERROR!\n");
  26:	00000517          	auipc	a0,0x0
  2a:	7a250513          	addi	a0,a0,1954 # 7c8 <malloc+0xea>
  2e:	00000097          	auipc	ra,0x0
  32:	5f8080e7          	jalr	1528(ra) # 626 <printf>
    }
    else{
        //TODO
        exit(0);
  36:	4501                	li	a0,0
  38:	00000097          	auipc	ra,0x0
  3c:	274080e7          	jalr	628(ra) # 2ac <exit>

0000000000000040 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  40:	1141                	addi	sp,sp,-16
  42:	e422                	sd	s0,8(sp)
  44:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  46:	87aa                	mv	a5,a0
  48:	0585                	addi	a1,a1,1
  4a:	0785                	addi	a5,a5,1
  4c:	fff5c703          	lbu	a4,-1(a1)
  50:	fee78fa3          	sb	a4,-1(a5)
  54:	fb75                	bnez	a4,48 <strcpy+0x8>
    ;
  return os;
}
  56:	6422                	ld	s0,8(sp)
  58:	0141                	addi	sp,sp,16
  5a:	8082                	ret

000000000000005c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  5c:	1141                	addi	sp,sp,-16
  5e:	e422                	sd	s0,8(sp)
  60:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  62:	00054783          	lbu	a5,0(a0)
  66:	cb91                	beqz	a5,7a <strcmp+0x1e>
  68:	0005c703          	lbu	a4,0(a1)
  6c:	00f71763          	bne	a4,a5,7a <strcmp+0x1e>
    p++, q++;
  70:	0505                	addi	a0,a0,1
  72:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  74:	00054783          	lbu	a5,0(a0)
  78:	fbe5                	bnez	a5,68 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  7a:	0005c503          	lbu	a0,0(a1)
}
  7e:	40a7853b          	subw	a0,a5,a0
  82:	6422                	ld	s0,8(sp)
  84:	0141                	addi	sp,sp,16
  86:	8082                	ret

0000000000000088 <strlen>:

uint
strlen(const char *s)
{
  88:	1141                	addi	sp,sp,-16
  8a:	e422                	sd	s0,8(sp)
  8c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  8e:	00054783          	lbu	a5,0(a0)
  92:	cf91                	beqz	a5,ae <strlen+0x26>
  94:	0505                	addi	a0,a0,1
  96:	87aa                	mv	a5,a0
  98:	4685                	li	a3,1
  9a:	9e89                	subw	a3,a3,a0
  9c:	00f6853b          	addw	a0,a3,a5
  a0:	0785                	addi	a5,a5,1
  a2:	fff7c703          	lbu	a4,-1(a5)
  a6:	fb7d                	bnez	a4,9c <strlen+0x14>
    ;
  return n;
}
  a8:	6422                	ld	s0,8(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret
  for(n = 0; s[n]; n++)
  ae:	4501                	li	a0,0
  b0:	bfe5                	j	a8 <strlen+0x20>

00000000000000b2 <memset>:

void*
memset(void *dst, int c, uint n)
{
  b2:	1141                	addi	sp,sp,-16
  b4:	e422                	sd	s0,8(sp)
  b6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  b8:	ca19                	beqz	a2,ce <memset+0x1c>
  ba:	87aa                	mv	a5,a0
  bc:	1602                	slli	a2,a2,0x20
  be:	9201                	srli	a2,a2,0x20
  c0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  c4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  c8:	0785                	addi	a5,a5,1
  ca:	fee79de3          	bne	a5,a4,c4 <memset+0x12>
  }
  return dst;
}
  ce:	6422                	ld	s0,8(sp)
  d0:	0141                	addi	sp,sp,16
  d2:	8082                	ret

00000000000000d4 <strchr>:

char*
strchr(const char *s, char c)
{
  d4:	1141                	addi	sp,sp,-16
  d6:	e422                	sd	s0,8(sp)
  d8:	0800                	addi	s0,sp,16
  for(; *s; s++)
  da:	00054783          	lbu	a5,0(a0)
  de:	cb99                	beqz	a5,f4 <strchr+0x20>
    if(*s == c)
  e0:	00f58763          	beq	a1,a5,ee <strchr+0x1a>
  for(; *s; s++)
  e4:	0505                	addi	a0,a0,1
  e6:	00054783          	lbu	a5,0(a0)
  ea:	fbfd                	bnez	a5,e0 <strchr+0xc>
      return (char*)s;
  return 0;
  ec:	4501                	li	a0,0
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	addi	sp,sp,16
  f2:	8082                	ret
  return 0;
  f4:	4501                	li	a0,0
  f6:	bfe5                	j	ee <strchr+0x1a>

00000000000000f8 <gets>:

char*
gets(char *buf, int max)
{
  f8:	711d                	addi	sp,sp,-96
  fa:	ec86                	sd	ra,88(sp)
  fc:	e8a2                	sd	s0,80(sp)
  fe:	e4a6                	sd	s1,72(sp)
 100:	e0ca                	sd	s2,64(sp)
 102:	fc4e                	sd	s3,56(sp)
 104:	f852                	sd	s4,48(sp)
 106:	f456                	sd	s5,40(sp)
 108:	f05a                	sd	s6,32(sp)
 10a:	ec5e                	sd	s7,24(sp)
 10c:	1080                	addi	s0,sp,96
 10e:	8baa                	mv	s7,a0
 110:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 112:	892a                	mv	s2,a0
 114:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 116:	4aa9                	li	s5,10
 118:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 11a:	89a6                	mv	s3,s1
 11c:	2485                	addiw	s1,s1,1
 11e:	0344d863          	bge	s1,s4,14e <gets+0x56>
    cc = read(0, &c, 1);
 122:	4605                	li	a2,1
 124:	faf40593          	addi	a1,s0,-81
 128:	4501                	li	a0,0
 12a:	00000097          	auipc	ra,0x0
 12e:	19a080e7          	jalr	410(ra) # 2c4 <read>
    if(cc < 1)
 132:	00a05e63          	blez	a0,14e <gets+0x56>
    buf[i++] = c;
 136:	faf44783          	lbu	a5,-81(s0)
 13a:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 13e:	01578763          	beq	a5,s5,14c <gets+0x54>
 142:	0905                	addi	s2,s2,1
 144:	fd679be3          	bne	a5,s6,11a <gets+0x22>
  for(i=0; i+1 < max; ){
 148:	89a6                	mv	s3,s1
 14a:	a011                	j	14e <gets+0x56>
 14c:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 14e:	99de                	add	s3,s3,s7
 150:	00098023          	sb	zero,0(s3)
  return buf;
}
 154:	855e                	mv	a0,s7
 156:	60e6                	ld	ra,88(sp)
 158:	6446                	ld	s0,80(sp)
 15a:	64a6                	ld	s1,72(sp)
 15c:	6906                	ld	s2,64(sp)
 15e:	79e2                	ld	s3,56(sp)
 160:	7a42                	ld	s4,48(sp)
 162:	7aa2                	ld	s5,40(sp)
 164:	7b02                	ld	s6,32(sp)
 166:	6be2                	ld	s7,24(sp)
 168:	6125                	addi	sp,sp,96
 16a:	8082                	ret

000000000000016c <stat>:

int
stat(const char *n, struct stat *st)
{
 16c:	1101                	addi	sp,sp,-32
 16e:	ec06                	sd	ra,24(sp)
 170:	e822                	sd	s0,16(sp)
 172:	e426                	sd	s1,8(sp)
 174:	e04a                	sd	s2,0(sp)
 176:	1000                	addi	s0,sp,32
 178:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 17a:	4581                	li	a1,0
 17c:	00000097          	auipc	ra,0x0
 180:	170080e7          	jalr	368(ra) # 2ec <open>
  if(fd < 0)
 184:	02054563          	bltz	a0,1ae <stat+0x42>
 188:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 18a:	85ca                	mv	a1,s2
 18c:	00000097          	auipc	ra,0x0
 190:	178080e7          	jalr	376(ra) # 304 <fstat>
 194:	892a                	mv	s2,a0
  close(fd);
 196:	8526                	mv	a0,s1
 198:	00000097          	auipc	ra,0x0
 19c:	13c080e7          	jalr	316(ra) # 2d4 <close>
  return r;
}
 1a0:	854a                	mv	a0,s2
 1a2:	60e2                	ld	ra,24(sp)
 1a4:	6442                	ld	s0,16(sp)
 1a6:	64a2                	ld	s1,8(sp)
 1a8:	6902                	ld	s2,0(sp)
 1aa:	6105                	addi	sp,sp,32
 1ac:	8082                	ret
    return -1;
 1ae:	597d                	li	s2,-1
 1b0:	bfc5                	j	1a0 <stat+0x34>

00000000000001b2 <atoi>:

int
atoi(const char *s)
{
 1b2:	1141                	addi	sp,sp,-16
 1b4:	e422                	sd	s0,8(sp)
 1b6:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1b8:	00054683          	lbu	a3,0(a0)
 1bc:	fd06879b          	addiw	a5,a3,-48
 1c0:	0ff7f793          	zext.b	a5,a5
 1c4:	4625                	li	a2,9
 1c6:	02f66863          	bltu	a2,a5,1f6 <atoi+0x44>
 1ca:	872a                	mv	a4,a0
  n = 0;
 1cc:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1ce:	0705                	addi	a4,a4,1
 1d0:	0025179b          	slliw	a5,a0,0x2
 1d4:	9fa9                	addw	a5,a5,a0
 1d6:	0017979b          	slliw	a5,a5,0x1
 1da:	9fb5                	addw	a5,a5,a3
 1dc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1e0:	00074683          	lbu	a3,0(a4)
 1e4:	fd06879b          	addiw	a5,a3,-48
 1e8:	0ff7f793          	zext.b	a5,a5
 1ec:	fef671e3          	bgeu	a2,a5,1ce <atoi+0x1c>
  return n;
}
 1f0:	6422                	ld	s0,8(sp)
 1f2:	0141                	addi	sp,sp,16
 1f4:	8082                	ret
  n = 0;
 1f6:	4501                	li	a0,0
 1f8:	bfe5                	j	1f0 <atoi+0x3e>

00000000000001fa <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1fa:	1141                	addi	sp,sp,-16
 1fc:	e422                	sd	s0,8(sp)
 1fe:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 200:	02b57463          	bgeu	a0,a1,228 <memmove+0x2e>
    while(n-- > 0)
 204:	00c05f63          	blez	a2,222 <memmove+0x28>
 208:	1602                	slli	a2,a2,0x20
 20a:	9201                	srli	a2,a2,0x20
 20c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 210:	872a                	mv	a4,a0
      *dst++ = *src++;
 212:	0585                	addi	a1,a1,1
 214:	0705                	addi	a4,a4,1
 216:	fff5c683          	lbu	a3,-1(a1)
 21a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 21e:	fee79ae3          	bne	a5,a4,212 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 222:	6422                	ld	s0,8(sp)
 224:	0141                	addi	sp,sp,16
 226:	8082                	ret
    dst += n;
 228:	00c50733          	add	a4,a0,a2
    src += n;
 22c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 22e:	fec05ae3          	blez	a2,222 <memmove+0x28>
 232:	fff6079b          	addiw	a5,a2,-1
 236:	1782                	slli	a5,a5,0x20
 238:	9381                	srli	a5,a5,0x20
 23a:	fff7c793          	not	a5,a5
 23e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 240:	15fd                	addi	a1,a1,-1
 242:	177d                	addi	a4,a4,-1
 244:	0005c683          	lbu	a3,0(a1)
 248:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 24c:	fee79ae3          	bne	a5,a4,240 <memmove+0x46>
 250:	bfc9                	j	222 <memmove+0x28>

0000000000000252 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 252:	1141                	addi	sp,sp,-16
 254:	e422                	sd	s0,8(sp)
 256:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 258:	ca05                	beqz	a2,288 <memcmp+0x36>
 25a:	fff6069b          	addiw	a3,a2,-1
 25e:	1682                	slli	a3,a3,0x20
 260:	9281                	srli	a3,a3,0x20
 262:	0685                	addi	a3,a3,1
 264:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 266:	00054783          	lbu	a5,0(a0)
 26a:	0005c703          	lbu	a4,0(a1)
 26e:	00e79863          	bne	a5,a4,27e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 272:	0505                	addi	a0,a0,1
    p2++;
 274:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 276:	fed518e3          	bne	a0,a3,266 <memcmp+0x14>
  }
  return 0;
 27a:	4501                	li	a0,0
 27c:	a019                	j	282 <memcmp+0x30>
      return *p1 - *p2;
 27e:	40e7853b          	subw	a0,a5,a4
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret
  return 0;
 288:	4501                	li	a0,0
 28a:	bfe5                	j	282 <memcmp+0x30>

000000000000028c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 28c:	1141                	addi	sp,sp,-16
 28e:	e406                	sd	ra,8(sp)
 290:	e022                	sd	s0,0(sp)
 292:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 294:	00000097          	auipc	ra,0x0
 298:	f66080e7          	jalr	-154(ra) # 1fa <memmove>
}
 29c:	60a2                	ld	ra,8(sp)
 29e:	6402                	ld	s0,0(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret

00000000000002a4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2a4:	4885                	li	a7,1
 ecall
 2a6:	00000073          	ecall
 ret
 2aa:	8082                	ret

00000000000002ac <exit>:
.global exit
exit:
 li a7, SYS_exit
 2ac:	4889                	li	a7,2
 ecall
 2ae:	00000073          	ecall
 ret
 2b2:	8082                	ret

00000000000002b4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2b4:	488d                	li	a7,3
 ecall
 2b6:	00000073          	ecall
 ret
 2ba:	8082                	ret

00000000000002bc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2bc:	4891                	li	a7,4
 ecall
 2be:	00000073          	ecall
 ret
 2c2:	8082                	ret

00000000000002c4 <read>:
.global read
read:
 li a7, SYS_read
 2c4:	4895                	li	a7,5
 ecall
 2c6:	00000073          	ecall
 ret
 2ca:	8082                	ret

00000000000002cc <write>:
.global write
write:
 li a7, SYS_write
 2cc:	48c1                	li	a7,16
 ecall
 2ce:	00000073          	ecall
 ret
 2d2:	8082                	ret

00000000000002d4 <close>:
.global close
close:
 li a7, SYS_close
 2d4:	48d5                	li	a7,21
 ecall
 2d6:	00000073          	ecall
 ret
 2da:	8082                	ret

00000000000002dc <kill>:
.global kill
kill:
 li a7, SYS_kill
 2dc:	4899                	li	a7,6
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2e4:	489d                	li	a7,7
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <open>:
.global open
open:
 li a7, SYS_open
 2ec:	48bd                	li	a7,15
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2f4:	48c5                	li	a7,17
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2fc:	48c9                	li	a7,18
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 304:	48a1                	li	a7,8
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <link>:
.global link
link:
 li a7, SYS_link
 30c:	48cd                	li	a7,19
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 314:	48d1                	li	a7,20
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 31c:	48a5                	li	a7,9
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <dup>:
.global dup
dup:
 li a7, SYS_dup
 324:	48a9                	li	a7,10
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 32c:	48ad                	li	a7,11
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 334:	48b1                	li	a7,12
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 33c:	48b5                	li	a7,13
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 344:	48b9                	li	a7,14
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 34c:	1101                	addi	sp,sp,-32
 34e:	ec06                	sd	ra,24(sp)
 350:	e822                	sd	s0,16(sp)
 352:	1000                	addi	s0,sp,32
 354:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 358:	4605                	li	a2,1
 35a:	fef40593          	addi	a1,s0,-17
 35e:	00000097          	auipc	ra,0x0
 362:	f6e080e7          	jalr	-146(ra) # 2cc <write>
}
 366:	60e2                	ld	ra,24(sp)
 368:	6442                	ld	s0,16(sp)
 36a:	6105                	addi	sp,sp,32
 36c:	8082                	ret

000000000000036e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 36e:	7139                	addi	sp,sp,-64
 370:	fc06                	sd	ra,56(sp)
 372:	f822                	sd	s0,48(sp)
 374:	f426                	sd	s1,40(sp)
 376:	f04a                	sd	s2,32(sp)
 378:	ec4e                	sd	s3,24(sp)
 37a:	0080                	addi	s0,sp,64
 37c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 37e:	c299                	beqz	a3,384 <printint+0x16>
 380:	0805c963          	bltz	a1,412 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 384:	2581                	sext.w	a1,a1
  neg = 0;
 386:	4881                	li	a7,0
 388:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 38c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 38e:	2601                	sext.w	a2,a2
 390:	00000517          	auipc	a0,0x0
 394:	4a050513          	addi	a0,a0,1184 # 830 <digits>
 398:	883a                	mv	a6,a4
 39a:	2705                	addiw	a4,a4,1
 39c:	02c5f7bb          	remuw	a5,a1,a2
 3a0:	1782                	slli	a5,a5,0x20
 3a2:	9381                	srli	a5,a5,0x20
 3a4:	97aa                	add	a5,a5,a0
 3a6:	0007c783          	lbu	a5,0(a5)
 3aa:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ae:	0005879b          	sext.w	a5,a1
 3b2:	02c5d5bb          	divuw	a1,a1,a2
 3b6:	0685                	addi	a3,a3,1
 3b8:	fec7f0e3          	bgeu	a5,a2,398 <printint+0x2a>
  if(neg)
 3bc:	00088c63          	beqz	a7,3d4 <printint+0x66>
    buf[i++] = '-';
 3c0:	fd070793          	addi	a5,a4,-48
 3c4:	00878733          	add	a4,a5,s0
 3c8:	02d00793          	li	a5,45
 3cc:	fef70823          	sb	a5,-16(a4)
 3d0:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3d4:	02e05863          	blez	a4,404 <printint+0x96>
 3d8:	fc040793          	addi	a5,s0,-64
 3dc:	00e78933          	add	s2,a5,a4
 3e0:	fff78993          	addi	s3,a5,-1
 3e4:	99ba                	add	s3,s3,a4
 3e6:	377d                	addiw	a4,a4,-1
 3e8:	1702                	slli	a4,a4,0x20
 3ea:	9301                	srli	a4,a4,0x20
 3ec:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3f0:	fff94583          	lbu	a1,-1(s2)
 3f4:	8526                	mv	a0,s1
 3f6:	00000097          	auipc	ra,0x0
 3fa:	f56080e7          	jalr	-170(ra) # 34c <putc>
  while(--i >= 0)
 3fe:	197d                	addi	s2,s2,-1
 400:	ff3918e3          	bne	s2,s3,3f0 <printint+0x82>
}
 404:	70e2                	ld	ra,56(sp)
 406:	7442                	ld	s0,48(sp)
 408:	74a2                	ld	s1,40(sp)
 40a:	7902                	ld	s2,32(sp)
 40c:	69e2                	ld	s3,24(sp)
 40e:	6121                	addi	sp,sp,64
 410:	8082                	ret
    x = -xx;
 412:	40b005bb          	negw	a1,a1
    neg = 1;
 416:	4885                	li	a7,1
    x = -xx;
 418:	bf85                	j	388 <printint+0x1a>

000000000000041a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 41a:	7119                	addi	sp,sp,-128
 41c:	fc86                	sd	ra,120(sp)
 41e:	f8a2                	sd	s0,112(sp)
 420:	f4a6                	sd	s1,104(sp)
 422:	f0ca                	sd	s2,96(sp)
 424:	ecce                	sd	s3,88(sp)
 426:	e8d2                	sd	s4,80(sp)
 428:	e4d6                	sd	s5,72(sp)
 42a:	e0da                	sd	s6,64(sp)
 42c:	fc5e                	sd	s7,56(sp)
 42e:	f862                	sd	s8,48(sp)
 430:	f466                	sd	s9,40(sp)
 432:	f06a                	sd	s10,32(sp)
 434:	ec6e                	sd	s11,24(sp)
 436:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 438:	0005c903          	lbu	s2,0(a1)
 43c:	18090f63          	beqz	s2,5da <vprintf+0x1c0>
 440:	8aaa                	mv	s5,a0
 442:	8b32                	mv	s6,a2
 444:	00158493          	addi	s1,a1,1
  state = 0;
 448:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 44a:	02500a13          	li	s4,37
 44e:	4c55                	li	s8,21
 450:	00000c97          	auipc	s9,0x0
 454:	388c8c93          	addi	s9,s9,904 # 7d8 <malloc+0xfa>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 458:	02800d93          	li	s11,40
  putc(fd, 'x');
 45c:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 45e:	00000b97          	auipc	s7,0x0
 462:	3d2b8b93          	addi	s7,s7,978 # 830 <digits>
 466:	a839                	j	484 <vprintf+0x6a>
        putc(fd, c);
 468:	85ca                	mv	a1,s2
 46a:	8556                	mv	a0,s5
 46c:	00000097          	auipc	ra,0x0
 470:	ee0080e7          	jalr	-288(ra) # 34c <putc>
 474:	a019                	j	47a <vprintf+0x60>
    } else if(state == '%'){
 476:	01498d63          	beq	s3,s4,490 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 47a:	0485                	addi	s1,s1,1
 47c:	fff4c903          	lbu	s2,-1(s1)
 480:	14090d63          	beqz	s2,5da <vprintf+0x1c0>
    if(state == 0){
 484:	fe0999e3          	bnez	s3,476 <vprintf+0x5c>
      if(c == '%'){
 488:	ff4910e3          	bne	s2,s4,468 <vprintf+0x4e>
        state = '%';
 48c:	89d2                	mv	s3,s4
 48e:	b7f5                	j	47a <vprintf+0x60>
      if(c == 'd'){
 490:	11490c63          	beq	s2,s4,5a8 <vprintf+0x18e>
 494:	f9d9079b          	addiw	a5,s2,-99
 498:	0ff7f793          	zext.b	a5,a5
 49c:	10fc6e63          	bltu	s8,a5,5b8 <vprintf+0x19e>
 4a0:	f9d9079b          	addiw	a5,s2,-99
 4a4:	0ff7f713          	zext.b	a4,a5
 4a8:	10ec6863          	bltu	s8,a4,5b8 <vprintf+0x19e>
 4ac:	00271793          	slli	a5,a4,0x2
 4b0:	97e6                	add	a5,a5,s9
 4b2:	439c                	lw	a5,0(a5)
 4b4:	97e6                	add	a5,a5,s9
 4b6:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4b8:	008b0913          	addi	s2,s6,8
 4bc:	4685                	li	a3,1
 4be:	4629                	li	a2,10
 4c0:	000b2583          	lw	a1,0(s6)
 4c4:	8556                	mv	a0,s5
 4c6:	00000097          	auipc	ra,0x0
 4ca:	ea8080e7          	jalr	-344(ra) # 36e <printint>
 4ce:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4d0:	4981                	li	s3,0
 4d2:	b765                	j	47a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4d4:	008b0913          	addi	s2,s6,8
 4d8:	4681                	li	a3,0
 4da:	4629                	li	a2,10
 4dc:	000b2583          	lw	a1,0(s6)
 4e0:	8556                	mv	a0,s5
 4e2:	00000097          	auipc	ra,0x0
 4e6:	e8c080e7          	jalr	-372(ra) # 36e <printint>
 4ea:	8b4a                	mv	s6,s2
      state = 0;
 4ec:	4981                	li	s3,0
 4ee:	b771                	j	47a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 4f0:	008b0913          	addi	s2,s6,8
 4f4:	4681                	li	a3,0
 4f6:	866a                	mv	a2,s10
 4f8:	000b2583          	lw	a1,0(s6)
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e70080e7          	jalr	-400(ra) # 36e <printint>
 506:	8b4a                	mv	s6,s2
      state = 0;
 508:	4981                	li	s3,0
 50a:	bf85                	j	47a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 50c:	008b0793          	addi	a5,s6,8
 510:	f8f43423          	sd	a5,-120(s0)
 514:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 518:	03000593          	li	a1,48
 51c:	8556                	mv	a0,s5
 51e:	00000097          	auipc	ra,0x0
 522:	e2e080e7          	jalr	-466(ra) # 34c <putc>
  putc(fd, 'x');
 526:	07800593          	li	a1,120
 52a:	8556                	mv	a0,s5
 52c:	00000097          	auipc	ra,0x0
 530:	e20080e7          	jalr	-480(ra) # 34c <putc>
 534:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 536:	03c9d793          	srli	a5,s3,0x3c
 53a:	97de                	add	a5,a5,s7
 53c:	0007c583          	lbu	a1,0(a5)
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	e0a080e7          	jalr	-502(ra) # 34c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 54a:	0992                	slli	s3,s3,0x4
 54c:	397d                	addiw	s2,s2,-1
 54e:	fe0914e3          	bnez	s2,536 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 552:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 556:	4981                	li	s3,0
 558:	b70d                	j	47a <vprintf+0x60>
        s = va_arg(ap, char*);
 55a:	008b0913          	addi	s2,s6,8
 55e:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 562:	02098163          	beqz	s3,584 <vprintf+0x16a>
        while(*s != 0){
 566:	0009c583          	lbu	a1,0(s3)
 56a:	c5ad                	beqz	a1,5d4 <vprintf+0x1ba>
          putc(fd, *s);
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	dde080e7          	jalr	-546(ra) # 34c <putc>
          s++;
 576:	0985                	addi	s3,s3,1
        while(*s != 0){
 578:	0009c583          	lbu	a1,0(s3)
 57c:	f9e5                	bnez	a1,56c <vprintf+0x152>
        s = va_arg(ap, char*);
 57e:	8b4a                	mv	s6,s2
      state = 0;
 580:	4981                	li	s3,0
 582:	bde5                	j	47a <vprintf+0x60>
          s = "(null)";
 584:	00000997          	auipc	s3,0x0
 588:	24c98993          	addi	s3,s3,588 # 7d0 <malloc+0xf2>
        while(*s != 0){
 58c:	85ee                	mv	a1,s11
 58e:	bff9                	j	56c <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 590:	008b0913          	addi	s2,s6,8
 594:	000b4583          	lbu	a1,0(s6)
 598:	8556                	mv	a0,s5
 59a:	00000097          	auipc	ra,0x0
 59e:	db2080e7          	jalr	-590(ra) # 34c <putc>
 5a2:	8b4a                	mv	s6,s2
      state = 0;
 5a4:	4981                	li	s3,0
 5a6:	bdd1                	j	47a <vprintf+0x60>
        putc(fd, c);
 5a8:	85d2                	mv	a1,s4
 5aa:	8556                	mv	a0,s5
 5ac:	00000097          	auipc	ra,0x0
 5b0:	da0080e7          	jalr	-608(ra) # 34c <putc>
      state = 0;
 5b4:	4981                	li	s3,0
 5b6:	b5d1                	j	47a <vprintf+0x60>
        putc(fd, '%');
 5b8:	85d2                	mv	a1,s4
 5ba:	8556                	mv	a0,s5
 5bc:	00000097          	auipc	ra,0x0
 5c0:	d90080e7          	jalr	-624(ra) # 34c <putc>
        putc(fd, c);
 5c4:	85ca                	mv	a1,s2
 5c6:	8556                	mv	a0,s5
 5c8:	00000097          	auipc	ra,0x0
 5cc:	d84080e7          	jalr	-636(ra) # 34c <putc>
      state = 0;
 5d0:	4981                	li	s3,0
 5d2:	b565                	j	47a <vprintf+0x60>
        s = va_arg(ap, char*);
 5d4:	8b4a                	mv	s6,s2
      state = 0;
 5d6:	4981                	li	s3,0
 5d8:	b54d                	j	47a <vprintf+0x60>
    }
  }
}
 5da:	70e6                	ld	ra,120(sp)
 5dc:	7446                	ld	s0,112(sp)
 5de:	74a6                	ld	s1,104(sp)
 5e0:	7906                	ld	s2,96(sp)
 5e2:	69e6                	ld	s3,88(sp)
 5e4:	6a46                	ld	s4,80(sp)
 5e6:	6aa6                	ld	s5,72(sp)
 5e8:	6b06                	ld	s6,64(sp)
 5ea:	7be2                	ld	s7,56(sp)
 5ec:	7c42                	ld	s8,48(sp)
 5ee:	7ca2                	ld	s9,40(sp)
 5f0:	7d02                	ld	s10,32(sp)
 5f2:	6de2                	ld	s11,24(sp)
 5f4:	6109                	addi	sp,sp,128
 5f6:	8082                	ret

00000000000005f8 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5f8:	715d                	addi	sp,sp,-80
 5fa:	ec06                	sd	ra,24(sp)
 5fc:	e822                	sd	s0,16(sp)
 5fe:	1000                	addi	s0,sp,32
 600:	e010                	sd	a2,0(s0)
 602:	e414                	sd	a3,8(s0)
 604:	e818                	sd	a4,16(s0)
 606:	ec1c                	sd	a5,24(s0)
 608:	03043023          	sd	a6,32(s0)
 60c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 610:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 614:	8622                	mv	a2,s0
 616:	00000097          	auipc	ra,0x0
 61a:	e04080e7          	jalr	-508(ra) # 41a <vprintf>
}
 61e:	60e2                	ld	ra,24(sp)
 620:	6442                	ld	s0,16(sp)
 622:	6161                	addi	sp,sp,80
 624:	8082                	ret

0000000000000626 <printf>:

void
printf(const char *fmt, ...)
{
 626:	711d                	addi	sp,sp,-96
 628:	ec06                	sd	ra,24(sp)
 62a:	e822                	sd	s0,16(sp)
 62c:	1000                	addi	s0,sp,32
 62e:	e40c                	sd	a1,8(s0)
 630:	e810                	sd	a2,16(s0)
 632:	ec14                	sd	a3,24(s0)
 634:	f018                	sd	a4,32(s0)
 636:	f41c                	sd	a5,40(s0)
 638:	03043823          	sd	a6,48(s0)
 63c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 640:	00840613          	addi	a2,s0,8
 644:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 648:	85aa                	mv	a1,a0
 64a:	4505                	li	a0,1
 64c:	00000097          	auipc	ra,0x0
 650:	dce080e7          	jalr	-562(ra) # 41a <vprintf>
}
 654:	60e2                	ld	ra,24(sp)
 656:	6442                	ld	s0,16(sp)
 658:	6125                	addi	sp,sp,96
 65a:	8082                	ret

000000000000065c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 65c:	1141                	addi	sp,sp,-16
 65e:	e422                	sd	s0,8(sp)
 660:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 662:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 666:	00000797          	auipc	a5,0x0
 66a:	1e27b783          	ld	a5,482(a5) # 848 <freep>
 66e:	a02d                	j	698 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 670:	4618                	lw	a4,8(a2)
 672:	9f2d                	addw	a4,a4,a1
 674:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 678:	6398                	ld	a4,0(a5)
 67a:	6310                	ld	a2,0(a4)
 67c:	a83d                	j	6ba <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 67e:	ff852703          	lw	a4,-8(a0)
 682:	9f31                	addw	a4,a4,a2
 684:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 686:	ff053683          	ld	a3,-16(a0)
 68a:	a091                	j	6ce <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68c:	6398                	ld	a4,0(a5)
 68e:	00e7e463          	bltu	a5,a4,696 <free+0x3a>
 692:	00e6ea63          	bltu	a3,a4,6a6 <free+0x4a>
{
 696:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 698:	fed7fae3          	bgeu	a5,a3,68c <free+0x30>
 69c:	6398                	ld	a4,0(a5)
 69e:	00e6e463          	bltu	a3,a4,6a6 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a2:	fee7eae3          	bltu	a5,a4,696 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6a6:	ff852583          	lw	a1,-8(a0)
 6aa:	6390                	ld	a2,0(a5)
 6ac:	02059813          	slli	a6,a1,0x20
 6b0:	01c85713          	srli	a4,a6,0x1c
 6b4:	9736                	add	a4,a4,a3
 6b6:	fae60de3          	beq	a2,a4,670 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6ba:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6be:	4790                	lw	a2,8(a5)
 6c0:	02061593          	slli	a1,a2,0x20
 6c4:	01c5d713          	srli	a4,a1,0x1c
 6c8:	973e                	add	a4,a4,a5
 6ca:	fae68ae3          	beq	a3,a4,67e <free+0x22>
    p->s.ptr = bp->s.ptr;
 6ce:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6d0:	00000717          	auipc	a4,0x0
 6d4:	16f73c23          	sd	a5,376(a4) # 848 <freep>
}
 6d8:	6422                	ld	s0,8(sp)
 6da:	0141                	addi	sp,sp,16
 6dc:	8082                	ret

00000000000006de <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6de:	7139                	addi	sp,sp,-64
 6e0:	fc06                	sd	ra,56(sp)
 6e2:	f822                	sd	s0,48(sp)
 6e4:	f426                	sd	s1,40(sp)
 6e6:	f04a                	sd	s2,32(sp)
 6e8:	ec4e                	sd	s3,24(sp)
 6ea:	e852                	sd	s4,16(sp)
 6ec:	e456                	sd	s5,8(sp)
 6ee:	e05a                	sd	s6,0(sp)
 6f0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f2:	02051493          	slli	s1,a0,0x20
 6f6:	9081                	srli	s1,s1,0x20
 6f8:	04bd                	addi	s1,s1,15
 6fa:	8091                	srli	s1,s1,0x4
 6fc:	0014899b          	addiw	s3,s1,1
 700:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 702:	00000517          	auipc	a0,0x0
 706:	14653503          	ld	a0,326(a0) # 848 <freep>
 70a:	c515                	beqz	a0,736 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 70e:	4798                	lw	a4,8(a5)
 710:	02977f63          	bgeu	a4,s1,74e <malloc+0x70>
 714:	8a4e                	mv	s4,s3
 716:	0009871b          	sext.w	a4,s3
 71a:	6685                	lui	a3,0x1
 71c:	00d77363          	bgeu	a4,a3,722 <malloc+0x44>
 720:	6a05                	lui	s4,0x1
 722:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 726:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 72a:	00000917          	auipc	s2,0x0
 72e:	11e90913          	addi	s2,s2,286 # 848 <freep>
  if(p == (char*)-1)
 732:	5afd                	li	s5,-1
 734:	a895                	j	7a8 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 736:	00000797          	auipc	a5,0x0
 73a:	11a78793          	addi	a5,a5,282 # 850 <base>
 73e:	00000717          	auipc	a4,0x0
 742:	10f73523          	sd	a5,266(a4) # 848 <freep>
 746:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 748:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 74c:	b7e1                	j	714 <malloc+0x36>
      if(p->s.size == nunits)
 74e:	02e48c63          	beq	s1,a4,786 <malloc+0xa8>
        p->s.size -= nunits;
 752:	4137073b          	subw	a4,a4,s3
 756:	c798                	sw	a4,8(a5)
        p += p->s.size;
 758:	02071693          	slli	a3,a4,0x20
 75c:	01c6d713          	srli	a4,a3,0x1c
 760:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 762:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 766:	00000717          	auipc	a4,0x0
 76a:	0ea73123          	sd	a0,226(a4) # 848 <freep>
      return (void*)(p + 1);
 76e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 772:	70e2                	ld	ra,56(sp)
 774:	7442                	ld	s0,48(sp)
 776:	74a2                	ld	s1,40(sp)
 778:	7902                	ld	s2,32(sp)
 77a:	69e2                	ld	s3,24(sp)
 77c:	6a42                	ld	s4,16(sp)
 77e:	6aa2                	ld	s5,8(sp)
 780:	6b02                	ld	s6,0(sp)
 782:	6121                	addi	sp,sp,64
 784:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 786:	6398                	ld	a4,0(a5)
 788:	e118                	sd	a4,0(a0)
 78a:	bff1                	j	766 <malloc+0x88>
  hp->s.size = nu;
 78c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 790:	0541                	addi	a0,a0,16
 792:	00000097          	auipc	ra,0x0
 796:	eca080e7          	jalr	-310(ra) # 65c <free>
  return freep;
 79a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 79e:	d971                	beqz	a0,772 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a2:	4798                	lw	a4,8(a5)
 7a4:	fa9775e3          	bgeu	a4,s1,74e <malloc+0x70>
    if(p == freep)
 7a8:	00093703          	ld	a4,0(s2)
 7ac:	853e                	mv	a0,a5
 7ae:	fef719e3          	bne	a4,a5,7a0 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7b2:	8552                	mv	a0,s4
 7b4:	00000097          	auipc	ra,0x0
 7b8:	b80080e7          	jalr	-1152(ra) # 334 <sbrk>
  if(p == (char*)-1)
 7bc:	fd5518e3          	bne	a0,s5,78c <malloc+0xae>
        return 0;
 7c0:	4501                	li	a0,0
 7c2:	bf45                	j	772 <malloc+0x94>
