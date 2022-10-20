
user/_kalloctest：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <ntas>:
  test2();
  exit(0);
}

int ntas(int print)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
   c:	892a                	mv	s2,a0
  int n;
  char *c;

  if (statistics(buf, SZ) <= 0) {
   e:	6585                	lui	a1,0x1
  10:	00001517          	auipc	a0,0x1
  14:	d0850513          	addi	a0,a0,-760 # d18 <buf>
  18:	00001097          	auipc	ra,0x1
  1c:	aaa080e7          	jalr	-1366(ra) # ac2 <statistics>
  20:	02a05b63          	blez	a0,56 <ntas+0x56>
    fprintf(2, "ntas: no stats\n");
  }
  c = strchr(buf, '=');
  24:	03d00593          	li	a1,61
  28:	00001517          	auipc	a0,0x1
  2c:	cf050513          	addi	a0,a0,-784 # d18 <buf>
  30:	00000097          	auipc	ra,0x0
  34:	3a2080e7          	jalr	930(ra) # 3d2 <strchr>
  n = atoi(c+2);
  38:	0509                	addi	a0,a0,2
  3a:	00000097          	auipc	ra,0x0
  3e:	476080e7          	jalr	1142(ra) # 4b0 <atoi>
  42:	84aa                	mv	s1,a0
  if(print)
  44:	02091363          	bnez	s2,6a <ntas+0x6a>
    printf("%s", buf);
  return n;
}
  48:	8526                	mv	a0,s1
  4a:	60e2                	ld	ra,24(sp)
  4c:	6442                	ld	s0,16(sp)
  4e:	64a2                	ld	s1,8(sp)
  50:	6902                	ld	s2,0(sp)
  52:	6105                	addi	sp,sp,32
  54:	8082                	ret
    fprintf(2, "ntas: no stats\n");
  56:	00001597          	auipc	a1,0x1
  5a:	af258593          	addi	a1,a1,-1294 # b48 <statistics+0x86>
  5e:	4509                	li	a0,2
  60:	00001097          	auipc	ra,0x1
  64:	896080e7          	jalr	-1898(ra) # 8f6 <fprintf>
  68:	bf75                	j	24 <ntas+0x24>
    printf("%s", buf);
  6a:	00001597          	auipc	a1,0x1
  6e:	cae58593          	addi	a1,a1,-850 # d18 <buf>
  72:	00001517          	auipc	a0,0x1
  76:	ae650513          	addi	a0,a0,-1306 # b58 <statistics+0x96>
  7a:	00001097          	auipc	ra,0x1
  7e:	8aa080e7          	jalr	-1878(ra) # 924 <printf>
  82:	b7d9                	j	48 <ntas+0x48>

0000000000000084 <test1>:

void test1(void)
{
  84:	7179                	addi	sp,sp,-48
  86:	f406                	sd	ra,40(sp)
  88:	f022                	sd	s0,32(sp)
  8a:	ec26                	sd	s1,24(sp)
  8c:	e84a                	sd	s2,16(sp)
  8e:	e44e                	sd	s3,8(sp)
  90:	1800                	addi	s0,sp,48
  void *a, *a1;
  int n, m;
  printf("start test1\n");  
  92:	00001517          	auipc	a0,0x1
  96:	ace50513          	addi	a0,a0,-1330 # b60 <statistics+0x9e>
  9a:	00001097          	auipc	ra,0x1
  9e:	88a080e7          	jalr	-1910(ra) # 924 <printf>
  m = ntas(0);
  a2:	4501                	li	a0,0
  a4:	00000097          	auipc	ra,0x0
  a8:	f5c080e7          	jalr	-164(ra) # 0 <ntas>
  ac:	84aa                	mv	s1,a0
  for(int i = 0; i < NCHILD; i++){
    int pid = fork();
  ae:	00000097          	auipc	ra,0x0
  b2:	4f4080e7          	jalr	1268(ra) # 5a2 <fork>
    if(pid < 0){
  b6:	06054463          	bltz	a0,11e <test1+0x9a>
      printf("fork failed");
      exit(-1);
    }
    if(pid == 0){
  ba:	cd3d                	beqz	a0,138 <test1+0xb4>
    int pid = fork();
  bc:	00000097          	auipc	ra,0x0
  c0:	4e6080e7          	jalr	1254(ra) # 5a2 <fork>
    if(pid < 0){
  c4:	04054d63          	bltz	a0,11e <test1+0x9a>
    if(pid == 0){
  c8:	c925                	beqz	a0,138 <test1+0xb4>
      exit(-1);
    }
  }

  for(int i = 0; i < NCHILD; i++){
    wait(0);
  ca:	4501                	li	a0,0
  cc:	00000097          	auipc	ra,0x0
  d0:	4e6080e7          	jalr	1254(ra) # 5b2 <wait>
  d4:	4501                	li	a0,0
  d6:	00000097          	auipc	ra,0x0
  da:	4dc080e7          	jalr	1244(ra) # 5b2 <wait>
  }
  printf("test1 results:\n");
  de:	00001517          	auipc	a0,0x1
  e2:	ab250513          	addi	a0,a0,-1358 # b90 <statistics+0xce>
  e6:	00001097          	auipc	ra,0x1
  ea:	83e080e7          	jalr	-1986(ra) # 924 <printf>
  n = ntas(1);
  ee:	4505                	li	a0,1
  f0:	00000097          	auipc	ra,0x0
  f4:	f10080e7          	jalr	-240(ra) # 0 <ntas>
  if(n-m < 10) 
  f8:	9d05                	subw	a0,a0,s1
  fa:	47a5                	li	a5,9
  fc:	08a7c863          	blt	a5,a0,18c <test1+0x108>
    printf("test1 OK\n");
 100:	00001517          	auipc	a0,0x1
 104:	aa050513          	addi	a0,a0,-1376 # ba0 <statistics+0xde>
 108:	00001097          	auipc	ra,0x1
 10c:	81c080e7          	jalr	-2020(ra) # 924 <printf>
  else
    printf("test1 FAIL\n");
}
 110:	70a2                	ld	ra,40(sp)
 112:	7402                	ld	s0,32(sp)
 114:	64e2                	ld	s1,24(sp)
 116:	6942                	ld	s2,16(sp)
 118:	69a2                	ld	s3,8(sp)
 11a:	6145                	addi	sp,sp,48
 11c:	8082                	ret
      printf("fork failed");
 11e:	00001517          	auipc	a0,0x1
 122:	a5250513          	addi	a0,a0,-1454 # b70 <statistics+0xae>
 126:	00000097          	auipc	ra,0x0
 12a:	7fe080e7          	jalr	2046(ra) # 924 <printf>
      exit(-1);
 12e:	557d                	li	a0,-1
 130:	00000097          	auipc	ra,0x0
 134:	47a080e7          	jalr	1146(ra) # 5aa <exit>
{
 138:	6961                	lui	s2,0x18
 13a:	6a090913          	addi	s2,s2,1696 # 186a0 <__BSS_END__+0x16978>
        *(int *)(a+4) = 1;
 13e:	4985                	li	s3,1
        a = sbrk(4096);
 140:	6505                	lui	a0,0x1
 142:	00000097          	auipc	ra,0x0
 146:	4f0080e7          	jalr	1264(ra) # 632 <sbrk>
 14a:	84aa                	mv	s1,a0
        *(int *)(a+4) = 1;
 14c:	01352223          	sw	s3,4(a0) # 1004 <buf+0x2ec>
        a1 = sbrk(-4096);
 150:	757d                	lui	a0,0xfffff
 152:	00000097          	auipc	ra,0x0
 156:	4e0080e7          	jalr	1248(ra) # 632 <sbrk>
        if (a1 != a + 4096) {
 15a:	6785                	lui	a5,0x1
 15c:	94be                	add	s1,s1,a5
 15e:	00951a63          	bne	a0,s1,172 <test1+0xee>
      for(i = 0; i < N; i++) {
 162:	397d                	addiw	s2,s2,-1
 164:	fc091ee3          	bnez	s2,140 <test1+0xbc>
      exit(-1);
 168:	557d                	li	a0,-1
 16a:	00000097          	auipc	ra,0x0
 16e:	440080e7          	jalr	1088(ra) # 5aa <exit>
          printf("wrong sbrk\n");
 172:	00001517          	auipc	a0,0x1
 176:	a0e50513          	addi	a0,a0,-1522 # b80 <statistics+0xbe>
 17a:	00000097          	auipc	ra,0x0
 17e:	7aa080e7          	jalr	1962(ra) # 924 <printf>
          exit(-1);
 182:	557d                	li	a0,-1
 184:	00000097          	auipc	ra,0x0
 188:	426080e7          	jalr	1062(ra) # 5aa <exit>
    printf("test1 FAIL\n");
 18c:	00001517          	auipc	a0,0x1
 190:	a2450513          	addi	a0,a0,-1500 # bb0 <statistics+0xee>
 194:	00000097          	auipc	ra,0x0
 198:	790080e7          	jalr	1936(ra) # 924 <printf>
}
 19c:	bf95                	j	110 <test1+0x8c>

000000000000019e <countfree>:
//
// countfree() from usertests.c
//
int
countfree()
{
 19e:	7139                	addi	sp,sp,-64
 1a0:	fc06                	sd	ra,56(sp)
 1a2:	f822                	sd	s0,48(sp)
 1a4:	f426                	sd	s1,40(sp)
 1a6:	f04a                	sd	s2,32(sp)
 1a8:	ec4e                	sd	s3,24(sp)
 1aa:	e852                	sd	s4,16(sp)
 1ac:	e456                	sd	s5,8(sp)
 1ae:	e05a                	sd	s6,0(sp)
 1b0:	0080                	addi	s0,sp,64
  // printf("runned1\n");
  uint64 sz0 = (uint64)sbrk(0);
 1b2:	4501                	li	a0,0
 1b4:	00000097          	auipc	ra,0x0
 1b8:	47e080e7          	jalr	1150(ra) # 632 <sbrk>
 1bc:	8b2a                	mv	s6,a0
  int n = 0;
 1be:	4901                	li	s2,0
  // printf("runned2\n");
  while(1){
    uint64 a = (uint64) sbrk(4096);
    // dead loop here
    printf("a=%x\n", a);
 1c0:	00001a17          	auipc	s4,0x1
 1c4:	a00a0a13          	addi	s4,s4,-1536 # bc0 <statistics+0xfe>
    if(a == 0xffffffffffffffff){
 1c8:	59fd                	li	s3,-1
      break;
    }
    // modify the memory to make sure it's really allocated.
    *(char *)(a + 4096 - 1) = 1;
 1ca:	4a85                	li	s5,1
 1cc:	a031                	j	1d8 <countfree+0x3a>
 1ce:	6785                	lui	a5,0x1
 1d0:	97a6                	add	a5,a5,s1
 1d2:	ff578fa3          	sb	s5,-1(a5) # fff <buf+0x2e7>
    n += 1;
 1d6:	2905                	addiw	s2,s2,1
    uint64 a = (uint64) sbrk(4096);
 1d8:	6505                	lui	a0,0x1
 1da:	00000097          	auipc	ra,0x0
 1de:	458080e7          	jalr	1112(ra) # 632 <sbrk>
 1e2:	84aa                	mv	s1,a0
    printf("a=%x\n", a);
 1e4:	85aa                	mv	a1,a0
 1e6:	8552                	mv	a0,s4
 1e8:	00000097          	auipc	ra,0x0
 1ec:	73c080e7          	jalr	1852(ra) # 924 <printf>
    if(a == 0xffffffffffffffff){
 1f0:	fd349fe3          	bne	s1,s3,1ce <countfree+0x30>
  }
  sbrk(-((uint64)sbrk(0) - sz0));
 1f4:	4501                	li	a0,0
 1f6:	00000097          	auipc	ra,0x0
 1fa:	43c080e7          	jalr	1084(ra) # 632 <sbrk>
 1fe:	40ab053b          	subw	a0,s6,a0
 202:	00000097          	auipc	ra,0x0
 206:	430080e7          	jalr	1072(ra) # 632 <sbrk>
  return n;
}
 20a:	854a                	mv	a0,s2
 20c:	70e2                	ld	ra,56(sp)
 20e:	7442                	ld	s0,48(sp)
 210:	74a2                	ld	s1,40(sp)
 212:	7902                	ld	s2,32(sp)
 214:	69e2                	ld	s3,24(sp)
 216:	6a42                	ld	s4,16(sp)
 218:	6aa2                	ld	s5,8(sp)
 21a:	6b02                	ld	s6,0(sp)
 21c:	6121                	addi	sp,sp,64
 21e:	8082                	ret

0000000000000220 <test2>:

void test2() {
 220:	715d                	addi	sp,sp,-80
 222:	e486                	sd	ra,72(sp)
 224:	e0a2                	sd	s0,64(sp)
 226:	fc26                	sd	s1,56(sp)
 228:	f84a                	sd	s2,48(sp)
 22a:	f44e                	sd	s3,40(sp)
 22c:	f052                	sd	s4,32(sp)
 22e:	ec56                	sd	s5,24(sp)
 230:	e85a                	sd	s6,16(sp)
 232:	e45e                	sd	s7,8(sp)
 234:	e062                	sd	s8,0(sp)
 236:	0880                	addi	s0,sp,80
  int free0 = countfree();
 238:	00000097          	auipc	ra,0x0
 23c:	f66080e7          	jalr	-154(ra) # 19e <countfree>
 240:	8a2a                	mv	s4,a0
  int free1;
  int n = (PHYSTOP-KERNBASE)/PGSIZE;
  printf("start test2\n");  
 242:	00001517          	auipc	a0,0x1
 246:	98650513          	addi	a0,a0,-1658 # bc8 <statistics+0x106>
 24a:	00000097          	auipc	ra,0x0
 24e:	6da080e7          	jalr	1754(ra) # 924 <printf>
  printf("total free number of pages: %d (out of %d)\n", free0, n);
 252:	6621                	lui	a2,0x8
 254:	85d2                	mv	a1,s4
 256:	00001517          	auipc	a0,0x1
 25a:	98250513          	addi	a0,a0,-1662 # bd8 <statistics+0x116>
 25e:	00000097          	auipc	ra,0x0
 262:	6c6080e7          	jalr	1734(ra) # 924 <printf>
  if(n - free0 > 1000) {
 266:	67a1                	lui	a5,0x8
 268:	414787bb          	subw	a5,a5,s4
 26c:	3e800713          	li	a4,1000
 270:	02f74163          	blt	a4,a5,292 <test2+0x72>
    printf("test2 FAILED: cannot allocate enough memory");
    exit(-1);
  }
  for (int i = 0; i < 50; i++) {
    free1 = countfree();
 274:	00000097          	auipc	ra,0x0
 278:	f2a080e7          	jalr	-214(ra) # 19e <countfree>
 27c:	892a                	mv	s2,a0
  for (int i = 0; i < 50; i++) {
 27e:	4981                	li	s3,0
 280:	03200a93          	li	s5,50
    if(i % 10 == 9)
 284:	4ba9                	li	s7,10
 286:	4b25                	li	s6,9
      printf(".");
 288:	00001c17          	auipc	s8,0x1
 28c:	9b0c0c13          	addi	s8,s8,-1616 # c38 <statistics+0x176>
 290:	a01d                	j	2b6 <test2+0x96>
    printf("test2 FAILED: cannot allocate enough memory");
 292:	00001517          	auipc	a0,0x1
 296:	97650513          	addi	a0,a0,-1674 # c08 <statistics+0x146>
 29a:	00000097          	auipc	ra,0x0
 29e:	68a080e7          	jalr	1674(ra) # 924 <printf>
    exit(-1);
 2a2:	557d                	li	a0,-1
 2a4:	00000097          	auipc	ra,0x0
 2a8:	306080e7          	jalr	774(ra) # 5aa <exit>
      printf(".");
 2ac:	8562                	mv	a0,s8
 2ae:	00000097          	auipc	ra,0x0
 2b2:	676080e7          	jalr	1654(ra) # 924 <printf>
    if(free1 != free0) {
 2b6:	032a1263          	bne	s4,s2,2da <test2+0xba>
  for (int i = 0; i < 50; i++) {
 2ba:	0019849b          	addiw	s1,s3,1
 2be:	0004899b          	sext.w	s3,s1
 2c2:	03598963          	beq	s3,s5,2f4 <test2+0xd4>
    free1 = countfree();
 2c6:	00000097          	auipc	ra,0x0
 2ca:	ed8080e7          	jalr	-296(ra) # 19e <countfree>
 2ce:	892a                	mv	s2,a0
    if(i % 10 == 9)
 2d0:	0374e4bb          	remw	s1,s1,s7
 2d4:	ff6491e3          	bne	s1,s6,2b6 <test2+0x96>
 2d8:	bfd1                	j	2ac <test2+0x8c>
      printf("test2 FAIL: losing pages\n");
 2da:	00001517          	auipc	a0,0x1
 2de:	96650513          	addi	a0,a0,-1690 # c40 <statistics+0x17e>
 2e2:	00000097          	auipc	ra,0x0
 2e6:	642080e7          	jalr	1602(ra) # 924 <printf>
      exit(-1);
 2ea:	557d                	li	a0,-1
 2ec:	00000097          	auipc	ra,0x0
 2f0:	2be080e7          	jalr	702(ra) # 5aa <exit>
    }
  }
  printf("\ntest2 OK\n");  
 2f4:	00001517          	auipc	a0,0x1
 2f8:	96c50513          	addi	a0,a0,-1684 # c60 <statistics+0x19e>
 2fc:	00000097          	auipc	ra,0x0
 300:	628080e7          	jalr	1576(ra) # 924 <printf>
}
 304:	60a6                	ld	ra,72(sp)
 306:	6406                	ld	s0,64(sp)
 308:	74e2                	ld	s1,56(sp)
 30a:	7942                	ld	s2,48(sp)
 30c:	79a2                	ld	s3,40(sp)
 30e:	7a02                	ld	s4,32(sp)
 310:	6ae2                	ld	s5,24(sp)
 312:	6b42                	ld	s6,16(sp)
 314:	6ba2                	ld	s7,8(sp)
 316:	6c02                	ld	s8,0(sp)
 318:	6161                	addi	sp,sp,80
 31a:	8082                	ret

000000000000031c <main>:
{
 31c:	1141                	addi	sp,sp,-16
 31e:	e406                	sd	ra,8(sp)
 320:	e022                	sd	s0,0(sp)
 322:	0800                	addi	s0,sp,16
  test1();
 324:	00000097          	auipc	ra,0x0
 328:	d60080e7          	jalr	-672(ra) # 84 <test1>
  test2();
 32c:	00000097          	auipc	ra,0x0
 330:	ef4080e7          	jalr	-268(ra) # 220 <test2>
  exit(0);
 334:	4501                	li	a0,0
 336:	00000097          	auipc	ra,0x0
 33a:	274080e7          	jalr	628(ra) # 5aa <exit>

000000000000033e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 33e:	1141                	addi	sp,sp,-16
 340:	e422                	sd	s0,8(sp)
 342:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 344:	87aa                	mv	a5,a0
 346:	0585                	addi	a1,a1,1
 348:	0785                	addi	a5,a5,1 # 8001 <__BSS_END__+0x62d9>
 34a:	fff5c703          	lbu	a4,-1(a1)
 34e:	fee78fa3          	sb	a4,-1(a5)
 352:	fb75                	bnez	a4,346 <strcpy+0x8>
    ;
  return os;
}
 354:	6422                	ld	s0,8(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret

000000000000035a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 35a:	1141                	addi	sp,sp,-16
 35c:	e422                	sd	s0,8(sp)
 35e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 360:	00054783          	lbu	a5,0(a0)
 364:	cb91                	beqz	a5,378 <strcmp+0x1e>
 366:	0005c703          	lbu	a4,0(a1)
 36a:	00f71763          	bne	a4,a5,378 <strcmp+0x1e>
    p++, q++;
 36e:	0505                	addi	a0,a0,1
 370:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 372:	00054783          	lbu	a5,0(a0)
 376:	fbe5                	bnez	a5,366 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 378:	0005c503          	lbu	a0,0(a1)
}
 37c:	40a7853b          	subw	a0,a5,a0
 380:	6422                	ld	s0,8(sp)
 382:	0141                	addi	sp,sp,16
 384:	8082                	ret

0000000000000386 <strlen>:

uint
strlen(const char *s)
{
 386:	1141                	addi	sp,sp,-16
 388:	e422                	sd	s0,8(sp)
 38a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 38c:	00054783          	lbu	a5,0(a0)
 390:	cf91                	beqz	a5,3ac <strlen+0x26>
 392:	0505                	addi	a0,a0,1
 394:	87aa                	mv	a5,a0
 396:	4685                	li	a3,1
 398:	9e89                	subw	a3,a3,a0
 39a:	00f6853b          	addw	a0,a3,a5
 39e:	0785                	addi	a5,a5,1
 3a0:	fff7c703          	lbu	a4,-1(a5)
 3a4:	fb7d                	bnez	a4,39a <strlen+0x14>
    ;
  return n;
}
 3a6:	6422                	ld	s0,8(sp)
 3a8:	0141                	addi	sp,sp,16
 3aa:	8082                	ret
  for(n = 0; s[n]; n++)
 3ac:	4501                	li	a0,0
 3ae:	bfe5                	j	3a6 <strlen+0x20>

00000000000003b0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 3b0:	1141                	addi	sp,sp,-16
 3b2:	e422                	sd	s0,8(sp)
 3b4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 3b6:	ca19                	beqz	a2,3cc <memset+0x1c>
 3b8:	87aa                	mv	a5,a0
 3ba:	1602                	slli	a2,a2,0x20
 3bc:	9201                	srli	a2,a2,0x20
 3be:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 3c2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 3c6:	0785                	addi	a5,a5,1
 3c8:	fee79de3          	bne	a5,a4,3c2 <memset+0x12>
  }
  return dst;
}
 3cc:	6422                	ld	s0,8(sp)
 3ce:	0141                	addi	sp,sp,16
 3d0:	8082                	ret

00000000000003d2 <strchr>:

char*
strchr(const char *s, char c)
{
 3d2:	1141                	addi	sp,sp,-16
 3d4:	e422                	sd	s0,8(sp)
 3d6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 3d8:	00054783          	lbu	a5,0(a0)
 3dc:	cb99                	beqz	a5,3f2 <strchr+0x20>
    if(*s == c)
 3de:	00f58763          	beq	a1,a5,3ec <strchr+0x1a>
  for(; *s; s++)
 3e2:	0505                	addi	a0,a0,1
 3e4:	00054783          	lbu	a5,0(a0)
 3e8:	fbfd                	bnez	a5,3de <strchr+0xc>
      return (char*)s;
  return 0;
 3ea:	4501                	li	a0,0
}
 3ec:	6422                	ld	s0,8(sp)
 3ee:	0141                	addi	sp,sp,16
 3f0:	8082                	ret
  return 0;
 3f2:	4501                	li	a0,0
 3f4:	bfe5                	j	3ec <strchr+0x1a>

00000000000003f6 <gets>:

char*
gets(char *buf, int max)
{
 3f6:	711d                	addi	sp,sp,-96
 3f8:	ec86                	sd	ra,88(sp)
 3fa:	e8a2                	sd	s0,80(sp)
 3fc:	e4a6                	sd	s1,72(sp)
 3fe:	e0ca                	sd	s2,64(sp)
 400:	fc4e                	sd	s3,56(sp)
 402:	f852                	sd	s4,48(sp)
 404:	f456                	sd	s5,40(sp)
 406:	f05a                	sd	s6,32(sp)
 408:	ec5e                	sd	s7,24(sp)
 40a:	1080                	addi	s0,sp,96
 40c:	8baa                	mv	s7,a0
 40e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 410:	892a                	mv	s2,a0
 412:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 414:	4aa9                	li	s5,10
 416:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 418:	89a6                	mv	s3,s1
 41a:	2485                	addiw	s1,s1,1
 41c:	0344d863          	bge	s1,s4,44c <gets+0x56>
    cc = read(0, &c, 1);
 420:	4605                	li	a2,1
 422:	faf40593          	addi	a1,s0,-81
 426:	4501                	li	a0,0
 428:	00000097          	auipc	ra,0x0
 42c:	19a080e7          	jalr	410(ra) # 5c2 <read>
    if(cc < 1)
 430:	00a05e63          	blez	a0,44c <gets+0x56>
    buf[i++] = c;
 434:	faf44783          	lbu	a5,-81(s0)
 438:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 43c:	01578763          	beq	a5,s5,44a <gets+0x54>
 440:	0905                	addi	s2,s2,1
 442:	fd679be3          	bne	a5,s6,418 <gets+0x22>
  for(i=0; i+1 < max; ){
 446:	89a6                	mv	s3,s1
 448:	a011                	j	44c <gets+0x56>
 44a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 44c:	99de                	add	s3,s3,s7
 44e:	00098023          	sb	zero,0(s3)
  return buf;
}
 452:	855e                	mv	a0,s7
 454:	60e6                	ld	ra,88(sp)
 456:	6446                	ld	s0,80(sp)
 458:	64a6                	ld	s1,72(sp)
 45a:	6906                	ld	s2,64(sp)
 45c:	79e2                	ld	s3,56(sp)
 45e:	7a42                	ld	s4,48(sp)
 460:	7aa2                	ld	s5,40(sp)
 462:	7b02                	ld	s6,32(sp)
 464:	6be2                	ld	s7,24(sp)
 466:	6125                	addi	sp,sp,96
 468:	8082                	ret

000000000000046a <stat>:

int
stat(const char *n, struct stat *st)
{
 46a:	1101                	addi	sp,sp,-32
 46c:	ec06                	sd	ra,24(sp)
 46e:	e822                	sd	s0,16(sp)
 470:	e426                	sd	s1,8(sp)
 472:	e04a                	sd	s2,0(sp)
 474:	1000                	addi	s0,sp,32
 476:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 478:	4581                	li	a1,0
 47a:	00000097          	auipc	ra,0x0
 47e:	170080e7          	jalr	368(ra) # 5ea <open>
  if(fd < 0)
 482:	02054563          	bltz	a0,4ac <stat+0x42>
 486:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 488:	85ca                	mv	a1,s2
 48a:	00000097          	auipc	ra,0x0
 48e:	178080e7          	jalr	376(ra) # 602 <fstat>
 492:	892a                	mv	s2,a0
  close(fd);
 494:	8526                	mv	a0,s1
 496:	00000097          	auipc	ra,0x0
 49a:	13c080e7          	jalr	316(ra) # 5d2 <close>
  return r;
}
 49e:	854a                	mv	a0,s2
 4a0:	60e2                	ld	ra,24(sp)
 4a2:	6442                	ld	s0,16(sp)
 4a4:	64a2                	ld	s1,8(sp)
 4a6:	6902                	ld	s2,0(sp)
 4a8:	6105                	addi	sp,sp,32
 4aa:	8082                	ret
    return -1;
 4ac:	597d                	li	s2,-1
 4ae:	bfc5                	j	49e <stat+0x34>

00000000000004b0 <atoi>:

int
atoi(const char *s)
{
 4b0:	1141                	addi	sp,sp,-16
 4b2:	e422                	sd	s0,8(sp)
 4b4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 4b6:	00054683          	lbu	a3,0(a0)
 4ba:	fd06879b          	addiw	a5,a3,-48
 4be:	0ff7f793          	zext.b	a5,a5
 4c2:	4625                	li	a2,9
 4c4:	02f66863          	bltu	a2,a5,4f4 <atoi+0x44>
 4c8:	872a                	mv	a4,a0
  n = 0;
 4ca:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 4cc:	0705                	addi	a4,a4,1
 4ce:	0025179b          	slliw	a5,a0,0x2
 4d2:	9fa9                	addw	a5,a5,a0
 4d4:	0017979b          	slliw	a5,a5,0x1
 4d8:	9fb5                	addw	a5,a5,a3
 4da:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 4de:	00074683          	lbu	a3,0(a4)
 4e2:	fd06879b          	addiw	a5,a3,-48
 4e6:	0ff7f793          	zext.b	a5,a5
 4ea:	fef671e3          	bgeu	a2,a5,4cc <atoi+0x1c>
  return n;
}
 4ee:	6422                	ld	s0,8(sp)
 4f0:	0141                	addi	sp,sp,16
 4f2:	8082                	ret
  n = 0;
 4f4:	4501                	li	a0,0
 4f6:	bfe5                	j	4ee <atoi+0x3e>

00000000000004f8 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 4f8:	1141                	addi	sp,sp,-16
 4fa:	e422                	sd	s0,8(sp)
 4fc:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4fe:	02b57463          	bgeu	a0,a1,526 <memmove+0x2e>
    while(n-- > 0)
 502:	00c05f63          	blez	a2,520 <memmove+0x28>
 506:	1602                	slli	a2,a2,0x20
 508:	9201                	srli	a2,a2,0x20
 50a:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 50e:	872a                	mv	a4,a0
      *dst++ = *src++;
 510:	0585                	addi	a1,a1,1
 512:	0705                	addi	a4,a4,1
 514:	fff5c683          	lbu	a3,-1(a1)
 518:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 51c:	fee79ae3          	bne	a5,a4,510 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 520:	6422                	ld	s0,8(sp)
 522:	0141                	addi	sp,sp,16
 524:	8082                	ret
    dst += n;
 526:	00c50733          	add	a4,a0,a2
    src += n;
 52a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 52c:	fec05ae3          	blez	a2,520 <memmove+0x28>
 530:	fff6079b          	addiw	a5,a2,-1 # 7fff <__BSS_END__+0x62d7>
 534:	1782                	slli	a5,a5,0x20
 536:	9381                	srli	a5,a5,0x20
 538:	fff7c793          	not	a5,a5
 53c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 53e:	15fd                	addi	a1,a1,-1
 540:	177d                	addi	a4,a4,-1
 542:	0005c683          	lbu	a3,0(a1)
 546:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 54a:	fee79ae3          	bne	a5,a4,53e <memmove+0x46>
 54e:	bfc9                	j	520 <memmove+0x28>

0000000000000550 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 550:	1141                	addi	sp,sp,-16
 552:	e422                	sd	s0,8(sp)
 554:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 556:	ca05                	beqz	a2,586 <memcmp+0x36>
 558:	fff6069b          	addiw	a3,a2,-1
 55c:	1682                	slli	a3,a3,0x20
 55e:	9281                	srli	a3,a3,0x20
 560:	0685                	addi	a3,a3,1
 562:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 564:	00054783          	lbu	a5,0(a0)
 568:	0005c703          	lbu	a4,0(a1)
 56c:	00e79863          	bne	a5,a4,57c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 570:	0505                	addi	a0,a0,1
    p2++;
 572:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 574:	fed518e3          	bne	a0,a3,564 <memcmp+0x14>
  }
  return 0;
 578:	4501                	li	a0,0
 57a:	a019                	j	580 <memcmp+0x30>
      return *p1 - *p2;
 57c:	40e7853b          	subw	a0,a5,a4
}
 580:	6422                	ld	s0,8(sp)
 582:	0141                	addi	sp,sp,16
 584:	8082                	ret
  return 0;
 586:	4501                	li	a0,0
 588:	bfe5                	j	580 <memcmp+0x30>

000000000000058a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 58a:	1141                	addi	sp,sp,-16
 58c:	e406                	sd	ra,8(sp)
 58e:	e022                	sd	s0,0(sp)
 590:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 592:	00000097          	auipc	ra,0x0
 596:	f66080e7          	jalr	-154(ra) # 4f8 <memmove>
}
 59a:	60a2                	ld	ra,8(sp)
 59c:	6402                	ld	s0,0(sp)
 59e:	0141                	addi	sp,sp,16
 5a0:	8082                	ret

00000000000005a2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 5a2:	4885                	li	a7,1
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <exit>:
.global exit
exit:
 li a7, SYS_exit
 5aa:	4889                	li	a7,2
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 5b2:	488d                	li	a7,3
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 5ba:	4891                	li	a7,4
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <read>:
.global read
read:
 li a7, SYS_read
 5c2:	4895                	li	a7,5
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <write>:
.global write
write:
 li a7, SYS_write
 5ca:	48c1                	li	a7,16
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <close>:
.global close
close:
 li a7, SYS_close
 5d2:	48d5                	li	a7,21
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <kill>:
.global kill
kill:
 li a7, SYS_kill
 5da:	4899                	li	a7,6
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 5e2:	489d                	li	a7,7
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <open>:
.global open
open:
 li a7, SYS_open
 5ea:	48bd                	li	a7,15
 ecall
 5ec:	00000073          	ecall
 ret
 5f0:	8082                	ret

00000000000005f2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 5f2:	48c5                	li	a7,17
 ecall
 5f4:	00000073          	ecall
 ret
 5f8:	8082                	ret

00000000000005fa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5fa:	48c9                	li	a7,18
 ecall
 5fc:	00000073          	ecall
 ret
 600:	8082                	ret

0000000000000602 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 602:	48a1                	li	a7,8
 ecall
 604:	00000073          	ecall
 ret
 608:	8082                	ret

000000000000060a <link>:
.global link
link:
 li a7, SYS_link
 60a:	48cd                	li	a7,19
 ecall
 60c:	00000073          	ecall
 ret
 610:	8082                	ret

0000000000000612 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 612:	48d1                	li	a7,20
 ecall
 614:	00000073          	ecall
 ret
 618:	8082                	ret

000000000000061a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 61a:	48a5                	li	a7,9
 ecall
 61c:	00000073          	ecall
 ret
 620:	8082                	ret

0000000000000622 <dup>:
.global dup
dup:
 li a7, SYS_dup
 622:	48a9                	li	a7,10
 ecall
 624:	00000073          	ecall
 ret
 628:	8082                	ret

000000000000062a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 62a:	48ad                	li	a7,11
 ecall
 62c:	00000073          	ecall
 ret
 630:	8082                	ret

0000000000000632 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 632:	48b1                	li	a7,12
 ecall
 634:	00000073          	ecall
 ret
 638:	8082                	ret

000000000000063a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 63a:	48b5                	li	a7,13
 ecall
 63c:	00000073          	ecall
 ret
 640:	8082                	ret

0000000000000642 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 642:	48b9                	li	a7,14
 ecall
 644:	00000073          	ecall
 ret
 648:	8082                	ret

000000000000064a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 64a:	1101                	addi	sp,sp,-32
 64c:	ec06                	sd	ra,24(sp)
 64e:	e822                	sd	s0,16(sp)
 650:	1000                	addi	s0,sp,32
 652:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 656:	4605                	li	a2,1
 658:	fef40593          	addi	a1,s0,-17
 65c:	00000097          	auipc	ra,0x0
 660:	f6e080e7          	jalr	-146(ra) # 5ca <write>
}
 664:	60e2                	ld	ra,24(sp)
 666:	6442                	ld	s0,16(sp)
 668:	6105                	addi	sp,sp,32
 66a:	8082                	ret

000000000000066c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 66c:	7139                	addi	sp,sp,-64
 66e:	fc06                	sd	ra,56(sp)
 670:	f822                	sd	s0,48(sp)
 672:	f426                	sd	s1,40(sp)
 674:	f04a                	sd	s2,32(sp)
 676:	ec4e                	sd	s3,24(sp)
 678:	0080                	addi	s0,sp,64
 67a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 67c:	c299                	beqz	a3,682 <printint+0x16>
 67e:	0805c963          	bltz	a1,710 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 682:	2581                	sext.w	a1,a1
  neg = 0;
 684:	4881                	li	a7,0
 686:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 68a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 68c:	2601                	sext.w	a2,a2
 68e:	00000517          	auipc	a0,0x0
 692:	64250513          	addi	a0,a0,1602 # cd0 <digits>
 696:	883a                	mv	a6,a4
 698:	2705                	addiw	a4,a4,1
 69a:	02c5f7bb          	remuw	a5,a1,a2
 69e:	1782                	slli	a5,a5,0x20
 6a0:	9381                	srli	a5,a5,0x20
 6a2:	97aa                	add	a5,a5,a0
 6a4:	0007c783          	lbu	a5,0(a5)
 6a8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 6ac:	0005879b          	sext.w	a5,a1
 6b0:	02c5d5bb          	divuw	a1,a1,a2
 6b4:	0685                	addi	a3,a3,1
 6b6:	fec7f0e3          	bgeu	a5,a2,696 <printint+0x2a>
  if(neg)
 6ba:	00088c63          	beqz	a7,6d2 <printint+0x66>
    buf[i++] = '-';
 6be:	fd070793          	addi	a5,a4,-48
 6c2:	00878733          	add	a4,a5,s0
 6c6:	02d00793          	li	a5,45
 6ca:	fef70823          	sb	a5,-16(a4)
 6ce:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 6d2:	02e05863          	blez	a4,702 <printint+0x96>
 6d6:	fc040793          	addi	a5,s0,-64
 6da:	00e78933          	add	s2,a5,a4
 6de:	fff78993          	addi	s3,a5,-1
 6e2:	99ba                	add	s3,s3,a4
 6e4:	377d                	addiw	a4,a4,-1
 6e6:	1702                	slli	a4,a4,0x20
 6e8:	9301                	srli	a4,a4,0x20
 6ea:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6ee:	fff94583          	lbu	a1,-1(s2)
 6f2:	8526                	mv	a0,s1
 6f4:	00000097          	auipc	ra,0x0
 6f8:	f56080e7          	jalr	-170(ra) # 64a <putc>
  while(--i >= 0)
 6fc:	197d                	addi	s2,s2,-1
 6fe:	ff3918e3          	bne	s2,s3,6ee <printint+0x82>
}
 702:	70e2                	ld	ra,56(sp)
 704:	7442                	ld	s0,48(sp)
 706:	74a2                	ld	s1,40(sp)
 708:	7902                	ld	s2,32(sp)
 70a:	69e2                	ld	s3,24(sp)
 70c:	6121                	addi	sp,sp,64
 70e:	8082                	ret
    x = -xx;
 710:	40b005bb          	negw	a1,a1
    neg = 1;
 714:	4885                	li	a7,1
    x = -xx;
 716:	bf85                	j	686 <printint+0x1a>

0000000000000718 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 718:	7119                	addi	sp,sp,-128
 71a:	fc86                	sd	ra,120(sp)
 71c:	f8a2                	sd	s0,112(sp)
 71e:	f4a6                	sd	s1,104(sp)
 720:	f0ca                	sd	s2,96(sp)
 722:	ecce                	sd	s3,88(sp)
 724:	e8d2                	sd	s4,80(sp)
 726:	e4d6                	sd	s5,72(sp)
 728:	e0da                	sd	s6,64(sp)
 72a:	fc5e                	sd	s7,56(sp)
 72c:	f862                	sd	s8,48(sp)
 72e:	f466                	sd	s9,40(sp)
 730:	f06a                	sd	s10,32(sp)
 732:	ec6e                	sd	s11,24(sp)
 734:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 736:	0005c903          	lbu	s2,0(a1)
 73a:	18090f63          	beqz	s2,8d8 <vprintf+0x1c0>
 73e:	8aaa                	mv	s5,a0
 740:	8b32                	mv	s6,a2
 742:	00158493          	addi	s1,a1,1
  state = 0;
 746:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 748:	02500a13          	li	s4,37
 74c:	4c55                	li	s8,21
 74e:	00000c97          	auipc	s9,0x0
 752:	52ac8c93          	addi	s9,s9,1322 # c78 <statistics+0x1b6>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 756:	02800d93          	li	s11,40
  putc(fd, 'x');
 75a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 75c:	00000b97          	auipc	s7,0x0
 760:	574b8b93          	addi	s7,s7,1396 # cd0 <digits>
 764:	a839                	j	782 <vprintf+0x6a>
        putc(fd, c);
 766:	85ca                	mv	a1,s2
 768:	8556                	mv	a0,s5
 76a:	00000097          	auipc	ra,0x0
 76e:	ee0080e7          	jalr	-288(ra) # 64a <putc>
 772:	a019                	j	778 <vprintf+0x60>
    } else if(state == '%'){
 774:	01498d63          	beq	s3,s4,78e <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 778:	0485                	addi	s1,s1,1
 77a:	fff4c903          	lbu	s2,-1(s1)
 77e:	14090d63          	beqz	s2,8d8 <vprintf+0x1c0>
    if(state == 0){
 782:	fe0999e3          	bnez	s3,774 <vprintf+0x5c>
      if(c == '%'){
 786:	ff4910e3          	bne	s2,s4,766 <vprintf+0x4e>
        state = '%';
 78a:	89d2                	mv	s3,s4
 78c:	b7f5                	j	778 <vprintf+0x60>
      if(c == 'd'){
 78e:	11490c63          	beq	s2,s4,8a6 <vprintf+0x18e>
 792:	f9d9079b          	addiw	a5,s2,-99
 796:	0ff7f793          	zext.b	a5,a5
 79a:	10fc6e63          	bltu	s8,a5,8b6 <vprintf+0x19e>
 79e:	f9d9079b          	addiw	a5,s2,-99
 7a2:	0ff7f713          	zext.b	a4,a5
 7a6:	10ec6863          	bltu	s8,a4,8b6 <vprintf+0x19e>
 7aa:	00271793          	slli	a5,a4,0x2
 7ae:	97e6                	add	a5,a5,s9
 7b0:	439c                	lw	a5,0(a5)
 7b2:	97e6                	add	a5,a5,s9
 7b4:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 7b6:	008b0913          	addi	s2,s6,8
 7ba:	4685                	li	a3,1
 7bc:	4629                	li	a2,10
 7be:	000b2583          	lw	a1,0(s6)
 7c2:	8556                	mv	a0,s5
 7c4:	00000097          	auipc	ra,0x0
 7c8:	ea8080e7          	jalr	-344(ra) # 66c <printint>
 7cc:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 7ce:	4981                	li	s3,0
 7d0:	b765                	j	778 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7d2:	008b0913          	addi	s2,s6,8
 7d6:	4681                	li	a3,0
 7d8:	4629                	li	a2,10
 7da:	000b2583          	lw	a1,0(s6)
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	e8c080e7          	jalr	-372(ra) # 66c <printint>
 7e8:	8b4a                	mv	s6,s2
      state = 0;
 7ea:	4981                	li	s3,0
 7ec:	b771                	j	778 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7ee:	008b0913          	addi	s2,s6,8
 7f2:	4681                	li	a3,0
 7f4:	866a                	mv	a2,s10
 7f6:	000b2583          	lw	a1,0(s6)
 7fa:	8556                	mv	a0,s5
 7fc:	00000097          	auipc	ra,0x0
 800:	e70080e7          	jalr	-400(ra) # 66c <printint>
 804:	8b4a                	mv	s6,s2
      state = 0;
 806:	4981                	li	s3,0
 808:	bf85                	j	778 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 80a:	008b0793          	addi	a5,s6,8
 80e:	f8f43423          	sd	a5,-120(s0)
 812:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 816:	03000593          	li	a1,48
 81a:	8556                	mv	a0,s5
 81c:	00000097          	auipc	ra,0x0
 820:	e2e080e7          	jalr	-466(ra) # 64a <putc>
  putc(fd, 'x');
 824:	07800593          	li	a1,120
 828:	8556                	mv	a0,s5
 82a:	00000097          	auipc	ra,0x0
 82e:	e20080e7          	jalr	-480(ra) # 64a <putc>
 832:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 834:	03c9d793          	srli	a5,s3,0x3c
 838:	97de                	add	a5,a5,s7
 83a:	0007c583          	lbu	a1,0(a5)
 83e:	8556                	mv	a0,s5
 840:	00000097          	auipc	ra,0x0
 844:	e0a080e7          	jalr	-502(ra) # 64a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 848:	0992                	slli	s3,s3,0x4
 84a:	397d                	addiw	s2,s2,-1
 84c:	fe0914e3          	bnez	s2,834 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 850:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 854:	4981                	li	s3,0
 856:	b70d                	j	778 <vprintf+0x60>
        s = va_arg(ap, char*);
 858:	008b0913          	addi	s2,s6,8
 85c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 860:	02098163          	beqz	s3,882 <vprintf+0x16a>
        while(*s != 0){
 864:	0009c583          	lbu	a1,0(s3)
 868:	c5ad                	beqz	a1,8d2 <vprintf+0x1ba>
          putc(fd, *s);
 86a:	8556                	mv	a0,s5
 86c:	00000097          	auipc	ra,0x0
 870:	dde080e7          	jalr	-546(ra) # 64a <putc>
          s++;
 874:	0985                	addi	s3,s3,1
        while(*s != 0){
 876:	0009c583          	lbu	a1,0(s3)
 87a:	f9e5                	bnez	a1,86a <vprintf+0x152>
        s = va_arg(ap, char*);
 87c:	8b4a                	mv	s6,s2
      state = 0;
 87e:	4981                	li	s3,0
 880:	bde5                	j	778 <vprintf+0x60>
          s = "(null)";
 882:	00000997          	auipc	s3,0x0
 886:	3ee98993          	addi	s3,s3,1006 # c70 <statistics+0x1ae>
        while(*s != 0){
 88a:	85ee                	mv	a1,s11
 88c:	bff9                	j	86a <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 88e:	008b0913          	addi	s2,s6,8
 892:	000b4583          	lbu	a1,0(s6)
 896:	8556                	mv	a0,s5
 898:	00000097          	auipc	ra,0x0
 89c:	db2080e7          	jalr	-590(ra) # 64a <putc>
 8a0:	8b4a                	mv	s6,s2
      state = 0;
 8a2:	4981                	li	s3,0
 8a4:	bdd1                	j	778 <vprintf+0x60>
        putc(fd, c);
 8a6:	85d2                	mv	a1,s4
 8a8:	8556                	mv	a0,s5
 8aa:	00000097          	auipc	ra,0x0
 8ae:	da0080e7          	jalr	-608(ra) # 64a <putc>
      state = 0;
 8b2:	4981                	li	s3,0
 8b4:	b5d1                	j	778 <vprintf+0x60>
        putc(fd, '%');
 8b6:	85d2                	mv	a1,s4
 8b8:	8556                	mv	a0,s5
 8ba:	00000097          	auipc	ra,0x0
 8be:	d90080e7          	jalr	-624(ra) # 64a <putc>
        putc(fd, c);
 8c2:	85ca                	mv	a1,s2
 8c4:	8556                	mv	a0,s5
 8c6:	00000097          	auipc	ra,0x0
 8ca:	d84080e7          	jalr	-636(ra) # 64a <putc>
      state = 0;
 8ce:	4981                	li	s3,0
 8d0:	b565                	j	778 <vprintf+0x60>
        s = va_arg(ap, char*);
 8d2:	8b4a                	mv	s6,s2
      state = 0;
 8d4:	4981                	li	s3,0
 8d6:	b54d                	j	778 <vprintf+0x60>
    }
  }
}
 8d8:	70e6                	ld	ra,120(sp)
 8da:	7446                	ld	s0,112(sp)
 8dc:	74a6                	ld	s1,104(sp)
 8de:	7906                	ld	s2,96(sp)
 8e0:	69e6                	ld	s3,88(sp)
 8e2:	6a46                	ld	s4,80(sp)
 8e4:	6aa6                	ld	s5,72(sp)
 8e6:	6b06                	ld	s6,64(sp)
 8e8:	7be2                	ld	s7,56(sp)
 8ea:	7c42                	ld	s8,48(sp)
 8ec:	7ca2                	ld	s9,40(sp)
 8ee:	7d02                	ld	s10,32(sp)
 8f0:	6de2                	ld	s11,24(sp)
 8f2:	6109                	addi	sp,sp,128
 8f4:	8082                	ret

00000000000008f6 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8f6:	715d                	addi	sp,sp,-80
 8f8:	ec06                	sd	ra,24(sp)
 8fa:	e822                	sd	s0,16(sp)
 8fc:	1000                	addi	s0,sp,32
 8fe:	e010                	sd	a2,0(s0)
 900:	e414                	sd	a3,8(s0)
 902:	e818                	sd	a4,16(s0)
 904:	ec1c                	sd	a5,24(s0)
 906:	03043023          	sd	a6,32(s0)
 90a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 90e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 912:	8622                	mv	a2,s0
 914:	00000097          	auipc	ra,0x0
 918:	e04080e7          	jalr	-508(ra) # 718 <vprintf>
}
 91c:	60e2                	ld	ra,24(sp)
 91e:	6442                	ld	s0,16(sp)
 920:	6161                	addi	sp,sp,80
 922:	8082                	ret

0000000000000924 <printf>:

void
printf(const char *fmt, ...)
{
 924:	711d                	addi	sp,sp,-96
 926:	ec06                	sd	ra,24(sp)
 928:	e822                	sd	s0,16(sp)
 92a:	1000                	addi	s0,sp,32
 92c:	e40c                	sd	a1,8(s0)
 92e:	e810                	sd	a2,16(s0)
 930:	ec14                	sd	a3,24(s0)
 932:	f018                	sd	a4,32(s0)
 934:	f41c                	sd	a5,40(s0)
 936:	03043823          	sd	a6,48(s0)
 93a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 93e:	00840613          	addi	a2,s0,8
 942:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 946:	85aa                	mv	a1,a0
 948:	4505                	li	a0,1
 94a:	00000097          	auipc	ra,0x0
 94e:	dce080e7          	jalr	-562(ra) # 718 <vprintf>
}
 952:	60e2                	ld	ra,24(sp)
 954:	6442                	ld	s0,16(sp)
 956:	6125                	addi	sp,sp,96
 958:	8082                	ret

000000000000095a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 95a:	1141                	addi	sp,sp,-16
 95c:	e422                	sd	s0,8(sp)
 95e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 960:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 964:	00000797          	auipc	a5,0x0
 968:	3ac7b783          	ld	a5,940(a5) # d10 <freep>
 96c:	a02d                	j	996 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 96e:	4618                	lw	a4,8(a2)
 970:	9f2d                	addw	a4,a4,a1
 972:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 976:	6398                	ld	a4,0(a5)
 978:	6310                	ld	a2,0(a4)
 97a:	a83d                	j	9b8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 97c:	ff852703          	lw	a4,-8(a0)
 980:	9f31                	addw	a4,a4,a2
 982:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 984:	ff053683          	ld	a3,-16(a0)
 988:	a091                	j	9cc <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 98a:	6398                	ld	a4,0(a5)
 98c:	00e7e463          	bltu	a5,a4,994 <free+0x3a>
 990:	00e6ea63          	bltu	a3,a4,9a4 <free+0x4a>
{
 994:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 996:	fed7fae3          	bgeu	a5,a3,98a <free+0x30>
 99a:	6398                	ld	a4,0(a5)
 99c:	00e6e463          	bltu	a3,a4,9a4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 9a0:	fee7eae3          	bltu	a5,a4,994 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 9a4:	ff852583          	lw	a1,-8(a0)
 9a8:	6390                	ld	a2,0(a5)
 9aa:	02059813          	slli	a6,a1,0x20
 9ae:	01c85713          	srli	a4,a6,0x1c
 9b2:	9736                	add	a4,a4,a3
 9b4:	fae60de3          	beq	a2,a4,96e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 9b8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 9bc:	4790                	lw	a2,8(a5)
 9be:	02061593          	slli	a1,a2,0x20
 9c2:	01c5d713          	srli	a4,a1,0x1c
 9c6:	973e                	add	a4,a4,a5
 9c8:	fae68ae3          	beq	a3,a4,97c <free+0x22>
    p->s.ptr = bp->s.ptr;
 9cc:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 9ce:	00000717          	auipc	a4,0x0
 9d2:	34f73123          	sd	a5,834(a4) # d10 <freep>
}
 9d6:	6422                	ld	s0,8(sp)
 9d8:	0141                	addi	sp,sp,16
 9da:	8082                	ret

00000000000009dc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 9dc:	7139                	addi	sp,sp,-64
 9de:	fc06                	sd	ra,56(sp)
 9e0:	f822                	sd	s0,48(sp)
 9e2:	f426                	sd	s1,40(sp)
 9e4:	f04a                	sd	s2,32(sp)
 9e6:	ec4e                	sd	s3,24(sp)
 9e8:	e852                	sd	s4,16(sp)
 9ea:	e456                	sd	s5,8(sp)
 9ec:	e05a                	sd	s6,0(sp)
 9ee:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9f0:	02051493          	slli	s1,a0,0x20
 9f4:	9081                	srli	s1,s1,0x20
 9f6:	04bd                	addi	s1,s1,15
 9f8:	8091                	srli	s1,s1,0x4
 9fa:	0014899b          	addiw	s3,s1,1
 9fe:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 a00:	00000517          	auipc	a0,0x0
 a04:	31053503          	ld	a0,784(a0) # d10 <freep>
 a08:	c515                	beqz	a0,a34 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a0a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a0c:	4798                	lw	a4,8(a5)
 a0e:	02977f63          	bgeu	a4,s1,a4c <malloc+0x70>
 a12:	8a4e                	mv	s4,s3
 a14:	0009871b          	sext.w	a4,s3
 a18:	6685                	lui	a3,0x1
 a1a:	00d77363          	bgeu	a4,a3,a20 <malloc+0x44>
 a1e:	6a05                	lui	s4,0x1
 a20:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 a24:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 a28:	00000917          	auipc	s2,0x0
 a2c:	2e890913          	addi	s2,s2,744 # d10 <freep>
  if(p == (char*)-1)
 a30:	5afd                	li	s5,-1
 a32:	a895                	j	aa6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 a34:	00001797          	auipc	a5,0x1
 a38:	2e478793          	addi	a5,a5,740 # 1d18 <base>
 a3c:	00000717          	auipc	a4,0x0
 a40:	2cf73a23          	sd	a5,724(a4) # d10 <freep>
 a44:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a46:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a4a:	b7e1                	j	a12 <malloc+0x36>
      if(p->s.size == nunits)
 a4c:	02e48c63          	beq	s1,a4,a84 <malloc+0xa8>
        p->s.size -= nunits;
 a50:	4137073b          	subw	a4,a4,s3
 a54:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a56:	02071693          	slli	a3,a4,0x20
 a5a:	01c6d713          	srli	a4,a3,0x1c
 a5e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a60:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a64:	00000717          	auipc	a4,0x0
 a68:	2aa73623          	sd	a0,684(a4) # d10 <freep>
      return (void*)(p + 1);
 a6c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a70:	70e2                	ld	ra,56(sp)
 a72:	7442                	ld	s0,48(sp)
 a74:	74a2                	ld	s1,40(sp)
 a76:	7902                	ld	s2,32(sp)
 a78:	69e2                	ld	s3,24(sp)
 a7a:	6a42                	ld	s4,16(sp)
 a7c:	6aa2                	ld	s5,8(sp)
 a7e:	6b02                	ld	s6,0(sp)
 a80:	6121                	addi	sp,sp,64
 a82:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a84:	6398                	ld	a4,0(a5)
 a86:	e118                	sd	a4,0(a0)
 a88:	bff1                	j	a64 <malloc+0x88>
  hp->s.size = nu;
 a8a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a8e:	0541                	addi	a0,a0,16
 a90:	00000097          	auipc	ra,0x0
 a94:	eca080e7          	jalr	-310(ra) # 95a <free>
  return freep;
 a98:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a9c:	d971                	beqz	a0,a70 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a9e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 aa0:	4798                	lw	a4,8(a5)
 aa2:	fa9775e3          	bgeu	a4,s1,a4c <malloc+0x70>
    if(p == freep)
 aa6:	00093703          	ld	a4,0(s2)
 aaa:	853e                	mv	a0,a5
 aac:	fef719e3          	bne	a4,a5,a9e <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 ab0:	8552                	mv	a0,s4
 ab2:	00000097          	auipc	ra,0x0
 ab6:	b80080e7          	jalr	-1152(ra) # 632 <sbrk>
  if(p == (char*)-1)
 aba:	fd5518e3          	bne	a0,s5,a8a <malloc+0xae>
        return 0;
 abe:	4501                	li	a0,0
 ac0:	bf45                	j	a70 <malloc+0x94>

0000000000000ac2 <statistics>:
#include "kernel/fcntl.h"
#include "user/user.h"

int
statistics(void *buf, int sz)
{
 ac2:	7179                	addi	sp,sp,-48
 ac4:	f406                	sd	ra,40(sp)
 ac6:	f022                	sd	s0,32(sp)
 ac8:	ec26                	sd	s1,24(sp)
 aca:	e84a                	sd	s2,16(sp)
 acc:	e44e                	sd	s3,8(sp)
 ace:	e052                	sd	s4,0(sp)
 ad0:	1800                	addi	s0,sp,48
 ad2:	8a2a                	mv	s4,a0
 ad4:	892e                	mv	s2,a1
  int fd, i, n;
  
  fd = open("statistics", O_RDONLY);
 ad6:	4581                	li	a1,0
 ad8:	00000517          	auipc	a0,0x0
 adc:	21050513          	addi	a0,a0,528 # ce8 <digits+0x18>
 ae0:	00000097          	auipc	ra,0x0
 ae4:	b0a080e7          	jalr	-1270(ra) # 5ea <open>
  if(fd < 0) {
 ae8:	04054263          	bltz	a0,b2c <statistics+0x6a>
 aec:	89aa                	mv	s3,a0
      fprintf(2, "stats: open failed\n");
      exit(1);
  }
  for (i = 0; i < sz; ) {
 aee:	4481                	li	s1,0
 af0:	03205063          	blez	s2,b10 <statistics+0x4e>
    if ((n = read(fd, buf+i, sz-i)) < 0) {
 af4:	4099063b          	subw	a2,s2,s1
 af8:	009a05b3          	add	a1,s4,s1
 afc:	854e                	mv	a0,s3
 afe:	00000097          	auipc	ra,0x0
 b02:	ac4080e7          	jalr	-1340(ra) # 5c2 <read>
 b06:	00054563          	bltz	a0,b10 <statistics+0x4e>
      break;
    }
    i += n;
 b0a:	9ca9                	addw	s1,s1,a0
  for (i = 0; i < sz; ) {
 b0c:	ff24c4e3          	blt	s1,s2,af4 <statistics+0x32>
  }
  close(fd);
 b10:	854e                	mv	a0,s3
 b12:	00000097          	auipc	ra,0x0
 b16:	ac0080e7          	jalr	-1344(ra) # 5d2 <close>
  return i;
}
 b1a:	8526                	mv	a0,s1
 b1c:	70a2                	ld	ra,40(sp)
 b1e:	7402                	ld	s0,32(sp)
 b20:	64e2                	ld	s1,24(sp)
 b22:	6942                	ld	s2,16(sp)
 b24:	69a2                	ld	s3,8(sp)
 b26:	6a02                	ld	s4,0(sp)
 b28:	6145                	addi	sp,sp,48
 b2a:	8082                	ret
      fprintf(2, "stats: open failed\n");
 b2c:	00000597          	auipc	a1,0x0
 b30:	1cc58593          	addi	a1,a1,460 # cf8 <digits+0x28>
 b34:	4509                	li	a0,2
 b36:	00000097          	auipc	ra,0x0
 b3a:	dc0080e7          	jalr	-576(ra) # 8f6 <fprintf>
      exit(1);
 b3e:	4505                	li	a0,1
 b40:	00000097          	auipc	ra,0x0
 b44:	a6a080e7          	jalr	-1430(ra) # 5aa <exit>
