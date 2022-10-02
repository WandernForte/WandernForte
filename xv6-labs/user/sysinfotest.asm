
user/_sysinfotest：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <sinfo>:
#include "user/user.h"
#include "kernel/fcntl.h"


void
sinfo(struct sysinfo *info) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (sysinfo(info) < 0) {
   8:	00000097          	auipc	ra,0x0
   c:	744080e7          	jalr	1860(ra) # 74c <sysinfo>
  10:	00054663          	bltz	a0,1c <sinfo+0x1c>
    printf("FAIL: sysinfo failed");
    exit(1);
  }
}
  14:	60a2                	ld	ra,8(sp)
  16:	6402                	ld	s0,0(sp)
  18:	0141                	addi	sp,sp,16
  1a:	8082                	ret
    printf("FAIL: sysinfo failed");
  1c:	00001517          	auipc	a0,0x1
  20:	bb450513          	addi	a0,a0,-1100 # bd0 <malloc+0xea>
  24:	00001097          	auipc	ra,0x1
  28:	a0a080e7          	jalr	-1526(ra) # a2e <printf>
    exit(1);
  2c:	4505                	li	a0,1
  2e:	00000097          	auipc	ra,0x0
  32:	676080e7          	jalr	1654(ra) # 6a4 <exit>

0000000000000036 <countfree>:
//
// use sbrk() to count how many free physical memory pages there are.
//
int
countfree()
{
  36:	715d                	addi	sp,sp,-80
  38:	e486                	sd	ra,72(sp)
  3a:	e0a2                	sd	s0,64(sp)
  3c:	fc26                	sd	s1,56(sp)
  3e:	f84a                	sd	s2,48(sp)
  40:	f44e                	sd	s3,40(sp)
  42:	f052                	sd	s4,32(sp)
  44:	0880                	addi	s0,sp,80
  uint64 sz0 = (uint64)sbrk(0);
  46:	4501                	li	a0,0
  48:	00000097          	auipc	ra,0x0
  4c:	6e4080e7          	jalr	1764(ra) # 72c <sbrk>
  50:	8a2a                	mv	s4,a0
  struct sysinfo info;
  int n = 0;
  52:	4481                	li	s1,0

  while(1){
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  54:	597d                	li	s2,-1
      break;
    }
    n += PGSIZE;
  56:	6985                	lui	s3,0x1
  58:	a019                	j	5e <countfree+0x28>
  5a:	009984bb          	addw	s1,s3,s1
    if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  5e:	6505                	lui	a0,0x1
  60:	00000097          	auipc	ra,0x0
  64:	6cc080e7          	jalr	1740(ra) # 72c <sbrk>
  68:	ff2519e3          	bne	a0,s2,5a <countfree+0x24>
  }
  sinfo(&info);
  6c:	fb840513          	addi	a0,s0,-72
  70:	00000097          	auipc	ra,0x0
  74:	f90080e7          	jalr	-112(ra) # 0 <sinfo>
  if (info.freemem != 0) {
  78:	fb843583          	ld	a1,-72(s0)
  7c:	e58d                	bnez	a1,a6 <countfree+0x70>
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
      info.freemem);
    exit(1);
  }
  sbrk(-((uint64)sbrk(0) - sz0));
  7e:	4501                	li	a0,0
  80:	00000097          	auipc	ra,0x0
  84:	6ac080e7          	jalr	1708(ra) # 72c <sbrk>
  88:	40aa053b          	subw	a0,s4,a0
  8c:	00000097          	auipc	ra,0x0
  90:	6a0080e7          	jalr	1696(ra) # 72c <sbrk>
  return n;
}
  94:	8526                	mv	a0,s1
  96:	60a6                	ld	ra,72(sp)
  98:	6406                	ld	s0,64(sp)
  9a:	74e2                	ld	s1,56(sp)
  9c:	7942                	ld	s2,48(sp)
  9e:	79a2                	ld	s3,40(sp)
  a0:	7a02                	ld	s4,32(sp)
  a2:	6161                	addi	sp,sp,80
  a4:	8082                	ret
    printf("FAIL: there is no free mem, but sysinfo.freemem=%d\n",
  a6:	00001517          	auipc	a0,0x1
  aa:	b4250513          	addi	a0,a0,-1214 # be8 <malloc+0x102>
  ae:	00001097          	auipc	ra,0x1
  b2:	980080e7          	jalr	-1664(ra) # a2e <printf>
    exit(1);
  b6:	4505                	li	a0,1
  b8:	00000097          	auipc	ra,0x0
  bc:	5ec080e7          	jalr	1516(ra) # 6a4 <exit>

00000000000000c0 <testmem>:

void
testmem() {
  c0:	7139                	addi	sp,sp,-64
  c2:	fc06                	sd	ra,56(sp)
  c4:	f822                	sd	s0,48(sp)
  c6:	f426                	sd	s1,40(sp)
  c8:	f04a                	sd	s2,32(sp)
  ca:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 n = countfree();
  cc:	00000097          	auipc	ra,0x0
  d0:	f6a080e7          	jalr	-150(ra) # 36 <countfree>
  d4:	84aa                	mv	s1,a0
  
  sinfo(&info);
  d6:	fc840513          	addi	a0,s0,-56
  da:	00000097          	auipc	ra,0x0
  de:	f26080e7          	jalr	-218(ra) # 0 <sinfo>

  if (info.freemem!= n) {
  e2:	fc843583          	ld	a1,-56(s0)
  e6:	04959e63          	bne	a1,s1,142 <testmem+0x82>
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
    exit(1);
  }
  
  if((uint64)sbrk(PGSIZE) == 0xffffffffffffffff){
  ea:	6505                	lui	a0,0x1
  ec:	00000097          	auipc	ra,0x0
  f0:	640080e7          	jalr	1600(ra) # 72c <sbrk>
  f4:	57fd                	li	a5,-1
  f6:	06f50463          	beq	a0,a5,15e <testmem+0x9e>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
  fa:	fc840513          	addi	a0,s0,-56
  fe:	00000097          	auipc	ra,0x0
 102:	f02080e7          	jalr	-254(ra) # 0 <sinfo>
    
  if (info.freemem != n-PGSIZE) {
 106:	fc843603          	ld	a2,-56(s0)
 10a:	75fd                	lui	a1,0xfffff
 10c:	95a6                	add	a1,a1,s1
 10e:	06b61563          	bne	a2,a1,178 <testmem+0xb8>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
    exit(1);
  }
  
  if((uint64)sbrk(-PGSIZE) == 0xffffffffffffffff){
 112:	757d                	lui	a0,0xfffff
 114:	00000097          	auipc	ra,0x0
 118:	618080e7          	jalr	1560(ra) # 72c <sbrk>
 11c:	57fd                	li	a5,-1
 11e:	06f50a63          	beq	a0,a5,192 <testmem+0xd2>
    printf("sbrk failed");
    exit(1);
  }

  sinfo(&info);
 122:	fc840513          	addi	a0,s0,-56
 126:	00000097          	auipc	ra,0x0
 12a:	eda080e7          	jalr	-294(ra) # 0 <sinfo>
    
  if (info.freemem != n) {
 12e:	fc843603          	ld	a2,-56(s0)
 132:	06961d63          	bne	a2,s1,1ac <testmem+0xec>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
    exit(1);
  }
}
 136:	70e2                	ld	ra,56(sp)
 138:	7442                	ld	s0,48(sp)
 13a:	74a2                	ld	s1,40(sp)
 13c:	7902                	ld	s2,32(sp)
 13e:	6121                	addi	sp,sp,64
 140:	8082                	ret
    printf("FAIL: free mem %d (bytes) instead of %d\n", info.freemem, n);
 142:	8626                	mv	a2,s1
 144:	00001517          	auipc	a0,0x1
 148:	adc50513          	addi	a0,a0,-1316 # c20 <malloc+0x13a>
 14c:	00001097          	auipc	ra,0x1
 150:	8e2080e7          	jalr	-1822(ra) # a2e <printf>
    exit(1);
 154:	4505                	li	a0,1
 156:	00000097          	auipc	ra,0x0
 15a:	54e080e7          	jalr	1358(ra) # 6a4 <exit>
    printf("sbrk failed");
 15e:	00001517          	auipc	a0,0x1
 162:	af250513          	addi	a0,a0,-1294 # c50 <malloc+0x16a>
 166:	00001097          	auipc	ra,0x1
 16a:	8c8080e7          	jalr	-1848(ra) # a2e <printf>
    exit(1);
 16e:	4505                	li	a0,1
 170:	00000097          	auipc	ra,0x0
 174:	534080e7          	jalr	1332(ra) # 6a4 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n-PGSIZE, info.freemem);
 178:	00001517          	auipc	a0,0x1
 17c:	aa850513          	addi	a0,a0,-1368 # c20 <malloc+0x13a>
 180:	00001097          	auipc	ra,0x1
 184:	8ae080e7          	jalr	-1874(ra) # a2e <printf>
    exit(1);
 188:	4505                	li	a0,1
 18a:	00000097          	auipc	ra,0x0
 18e:	51a080e7          	jalr	1306(ra) # 6a4 <exit>
    printf("sbrk failed");
 192:	00001517          	auipc	a0,0x1
 196:	abe50513          	addi	a0,a0,-1346 # c50 <malloc+0x16a>
 19a:	00001097          	auipc	ra,0x1
 19e:	894080e7          	jalr	-1900(ra) # a2e <printf>
    exit(1);
 1a2:	4505                	li	a0,1
 1a4:	00000097          	auipc	ra,0x0
 1a8:	500080e7          	jalr	1280(ra) # 6a4 <exit>
    printf("FAIL: free mem %d (bytes) instead of %d\n", n, info.freemem);
 1ac:	85a6                	mv	a1,s1
 1ae:	00001517          	auipc	a0,0x1
 1b2:	a7250513          	addi	a0,a0,-1422 # c20 <malloc+0x13a>
 1b6:	00001097          	auipc	ra,0x1
 1ba:	878080e7          	jalr	-1928(ra) # a2e <printf>
    exit(1);
 1be:	4505                	li	a0,1
 1c0:	00000097          	auipc	ra,0x0
 1c4:	4e4080e7          	jalr	1252(ra) # 6a4 <exit>

00000000000001c8 <testcall>:

void
testcall() {
 1c8:	7179                	addi	sp,sp,-48
 1ca:	f406                	sd	ra,40(sp)
 1cc:	f022                	sd	s0,32(sp)
 1ce:	1800                	addi	s0,sp,48
  struct sysinfo info;
  
  if (sysinfo(&info) < 0) {
 1d0:	fd840513          	addi	a0,s0,-40
 1d4:	00000097          	auipc	ra,0x0
 1d8:	578080e7          	jalr	1400(ra) # 74c <sysinfo>
 1dc:	02054163          	bltz	a0,1fe <testcall+0x36>
    printf("FAIL: sysinfo failed\n");
    exit(1);
  }

  if (sysinfo((struct sysinfo *) 0xeaeb0b5b00002f5e) !=  0xffffffffffffffff) {
 1e0:	00001517          	auipc	a0,0x1
 1e4:	bf853503          	ld	a0,-1032(a0) # dd8 <__SDATA_BEGIN__>
 1e8:	00000097          	auipc	ra,0x0
 1ec:	564080e7          	jalr	1380(ra) # 74c <sysinfo>
 1f0:	57fd                	li	a5,-1
 1f2:	02f51363          	bne	a0,a5,218 <testcall+0x50>
    printf("FAIL: sysinfo succeeded with bad argument\n");
    exit(1);
  }
}
 1f6:	70a2                	ld	ra,40(sp)
 1f8:	7402                	ld	s0,32(sp)
 1fa:	6145                	addi	sp,sp,48
 1fc:	8082                	ret
    printf("FAIL: sysinfo failed\n");
 1fe:	00001517          	auipc	a0,0x1
 202:	a6250513          	addi	a0,a0,-1438 # c60 <malloc+0x17a>
 206:	00001097          	auipc	ra,0x1
 20a:	828080e7          	jalr	-2008(ra) # a2e <printf>
    exit(1);
 20e:	4505                	li	a0,1
 210:	00000097          	auipc	ra,0x0
 214:	494080e7          	jalr	1172(ra) # 6a4 <exit>
    printf("FAIL: sysinfo succeeded with bad argument\n");
 218:	00001517          	auipc	a0,0x1
 21c:	a6050513          	addi	a0,a0,-1440 # c78 <malloc+0x192>
 220:	00001097          	auipc	ra,0x1
 224:	80e080e7          	jalr	-2034(ra) # a2e <printf>
    exit(1);
 228:	4505                	li	a0,1
 22a:	00000097          	auipc	ra,0x0
 22e:	47a080e7          	jalr	1146(ra) # 6a4 <exit>

0000000000000232 <testproc>:

void testproc() {
 232:	7139                	addi	sp,sp,-64
 234:	fc06                	sd	ra,56(sp)
 236:	f822                	sd	s0,48(sp)
 238:	f426                	sd	s1,40(sp)
 23a:	0080                	addi	s0,sp,64
  struct sysinfo info;
  uint64 nproc;
  int status;
  int pid;
  
  sinfo(&info);
 23c:	fc840513          	addi	a0,s0,-56
 240:	00000097          	auipc	ra,0x0
 244:	dc0080e7          	jalr	-576(ra) # 0 <sinfo>
  nproc = info.nproc;
 248:	fd043483          	ld	s1,-48(s0)

  pid = fork();
 24c:	00000097          	auipc	ra,0x0
 250:	450080e7          	jalr	1104(ra) # 69c <fork>
  if(pid < 0){
 254:	02054c63          	bltz	a0,28c <testproc+0x5a>
    printf("sysinfotest: fork failed\n");
    exit(1);
  }
  if(pid == 0){
 258:	ed21                	bnez	a0,2b0 <testproc+0x7e>
    sinfo(&info);
 25a:	fc840513          	addi	a0,s0,-56
 25e:	00000097          	auipc	ra,0x0
 262:	da2080e7          	jalr	-606(ra) # 0 <sinfo>
    if(info.nproc != nproc-1) {
 266:	fd043583          	ld	a1,-48(s0)
 26a:	fff48613          	addi	a2,s1,-1
 26e:	02c58c63          	beq	a1,a2,2a6 <testproc+0x74>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc-1);
 272:	00001517          	auipc	a0,0x1
 276:	a5650513          	addi	a0,a0,-1450 # cc8 <malloc+0x1e2>
 27a:	00000097          	auipc	ra,0x0
 27e:	7b4080e7          	jalr	1972(ra) # a2e <printf>
      exit(1);
 282:	4505                	li	a0,1
 284:	00000097          	auipc	ra,0x0
 288:	420080e7          	jalr	1056(ra) # 6a4 <exit>
    printf("sysinfotest: fork failed\n");
 28c:	00001517          	auipc	a0,0x1
 290:	a1c50513          	addi	a0,a0,-1508 # ca8 <malloc+0x1c2>
 294:	00000097          	auipc	ra,0x0
 298:	79a080e7          	jalr	1946(ra) # a2e <printf>
    exit(1);
 29c:	4505                	li	a0,1
 29e:	00000097          	auipc	ra,0x0
 2a2:	406080e7          	jalr	1030(ra) # 6a4 <exit>
    }
    exit(0);
 2a6:	4501                	li	a0,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	3fc080e7          	jalr	1020(ra) # 6a4 <exit>
  }
  wait(&status);
 2b0:	fc440513          	addi	a0,s0,-60
 2b4:	00000097          	auipc	ra,0x0
 2b8:	3f8080e7          	jalr	1016(ra) # 6ac <wait>
  sinfo(&info);
 2bc:	fc840513          	addi	a0,s0,-56
 2c0:	00000097          	auipc	ra,0x0
 2c4:	d40080e7          	jalr	-704(ra) # 0 <sinfo>
  if(info.nproc != nproc) {
 2c8:	fd043583          	ld	a1,-48(s0)
 2cc:	00959763          	bne	a1,s1,2da <testproc+0xa8>
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
      exit(1);
  }
}
 2d0:	70e2                	ld	ra,56(sp)
 2d2:	7442                	ld	s0,48(sp)
 2d4:	74a2                	ld	s1,40(sp)
 2d6:	6121                	addi	sp,sp,64
 2d8:	8082                	ret
      printf("sysinfotest: FAIL nproc is %d instead of %d\n", info.nproc, nproc);
 2da:	8626                	mv	a2,s1
 2dc:	00001517          	auipc	a0,0x1
 2e0:	9ec50513          	addi	a0,a0,-1556 # cc8 <malloc+0x1e2>
 2e4:	00000097          	auipc	ra,0x0
 2e8:	74a080e7          	jalr	1866(ra) # a2e <printf>
      exit(1);
 2ec:	4505                	li	a0,1
 2ee:	00000097          	auipc	ra,0x0
 2f2:	3b6080e7          	jalr	950(ra) # 6a4 <exit>

00000000000002f6 <testfd>:

void testfd(){
 2f6:	715d                	addi	sp,sp,-80
 2f8:	e486                	sd	ra,72(sp)
 2fa:	e0a2                	sd	s0,64(sp)
 2fc:	fc26                	sd	s1,56(sp)
 2fe:	f84a                	sd	s2,48(sp)
 300:	f44e                	sd	s3,40(sp)
 302:	0880                	addi	s0,sp,80
  struct sysinfo info;
  sinfo(&info);
 304:	fb840513          	addi	a0,s0,-72
 308:	00000097          	auipc	ra,0x0
 30c:	cf8080e7          	jalr	-776(ra) # 0 <sinfo>
  uint64 nfd = info.freefd;
 310:	fc843983          	ld	s3,-56(s0)

  int fd = open("cat",O_RDONLY);
 314:	4581                	li	a1,0
 316:	00001517          	auipc	a0,0x1
 31a:	9e250513          	addi	a0,a0,-1566 # cf8 <malloc+0x212>
 31e:	00000097          	auipc	ra,0x0
 322:	3c6080e7          	jalr	966(ra) # 6e4 <open>
 326:	892a                	mv	s2,a0

  sinfo(&info);
 328:	fb840513          	addi	a0,s0,-72
 32c:	00000097          	auipc	ra,0x0
 330:	cd4080e7          	jalr	-812(ra) # 0 <sinfo>
  if(info.freefd != nfd - 1) {
 334:	fc843583          	ld	a1,-56(s0)
 338:	fff98613          	addi	a2,s3,-1 # fff <__BSS_END__+0x207>
 33c:	44a9                	li	s1,10
 33e:	04c59c63          	bne	a1,a2,396 <testfd+0xa0>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd - 1);
    exit(1);
  }
  
  for(int i = 0; i < 10; i++){
    dup(fd);
 342:	854a                	mv	a0,s2
 344:	00000097          	auipc	ra,0x0
 348:	3d8080e7          	jalr	984(ra) # 71c <dup>
  for(int i = 0; i < 10; i++){
 34c:	34fd                	addiw	s1,s1,-1
 34e:	f8f5                	bnez	s1,342 <testfd+0x4c>
  }
  sinfo(&info);
 350:	fb840513          	addi	a0,s0,-72
 354:	00000097          	auipc	ra,0x0
 358:	cac080e7          	jalr	-852(ra) # 0 <sinfo>
  if(info.freefd != nfd - 11) {
 35c:	fc843583          	ld	a1,-56(s0)
 360:	ff598613          	addi	a2,s3,-11
 364:	04c59663          	bne	a1,a2,3b0 <testfd+0xba>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-11);
    exit(1);
  }

  close(fd);
 368:	854a                	mv	a0,s2
 36a:	00000097          	auipc	ra,0x0
 36e:	362080e7          	jalr	866(ra) # 6cc <close>
  sinfo(&info);
 372:	fb840513          	addi	a0,s0,-72
 376:	00000097          	auipc	ra,0x0
 37a:	c8a080e7          	jalr	-886(ra) # 0 <sinfo>
  if(info.freefd != nfd - 10) {
 37e:	fc843583          	ld	a1,-56(s0)
 382:	19d9                	addi	s3,s3,-10
 384:	05359363          	bne	a1,s3,3ca <testfd+0xd4>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-10);
    exit(1);
  }
}
 388:	60a6                	ld	ra,72(sp)
 38a:	6406                	ld	s0,64(sp)
 38c:	74e2                	ld	s1,56(sp)
 38e:	7942                	ld	s2,48(sp)
 390:	79a2                	ld	s3,40(sp)
 392:	6161                	addi	sp,sp,80
 394:	8082                	ret
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd - 1);
 396:	00001517          	auipc	a0,0x1
 39a:	96a50513          	addi	a0,a0,-1686 # d00 <malloc+0x21a>
 39e:	00000097          	auipc	ra,0x0
 3a2:	690080e7          	jalr	1680(ra) # a2e <printf>
    exit(1);
 3a6:	4505                	li	a0,1
 3a8:	00000097          	auipc	ra,0x0
 3ac:	2fc080e7          	jalr	764(ra) # 6a4 <exit>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-11);
 3b0:	00001517          	auipc	a0,0x1
 3b4:	95050513          	addi	a0,a0,-1712 # d00 <malloc+0x21a>
 3b8:	00000097          	auipc	ra,0x0
 3bc:	676080e7          	jalr	1654(ra) # a2e <printf>
    exit(1);
 3c0:	4505                	li	a0,1
 3c2:	00000097          	auipc	ra,0x0
 3c6:	2e2080e7          	jalr	738(ra) # 6a4 <exit>
    printf("sysinfotest: FAIL freefd is %d instead of %d\n", info.freefd, nfd-10);
 3ca:	864e                	mv	a2,s3
 3cc:	00001517          	auipc	a0,0x1
 3d0:	93450513          	addi	a0,a0,-1740 # d00 <malloc+0x21a>
 3d4:	00000097          	auipc	ra,0x0
 3d8:	65a080e7          	jalr	1626(ra) # a2e <printf>
    exit(1);
 3dc:	4505                	li	a0,1
 3de:	00000097          	auipc	ra,0x0
 3e2:	2c6080e7          	jalr	710(ra) # 6a4 <exit>

00000000000003e6 <main>:

int
main(int argc, char *argv[])
{
 3e6:	1141                	addi	sp,sp,-16
 3e8:	e406                	sd	ra,8(sp)
 3ea:	e022                	sd	s0,0(sp)
 3ec:	0800                	addi	s0,sp,16
  printf("sysinfotest: start\n");
 3ee:	00001517          	auipc	a0,0x1
 3f2:	94250513          	addi	a0,a0,-1726 # d30 <malloc+0x24a>
 3f6:	00000097          	auipc	ra,0x0
 3fa:	638080e7          	jalr	1592(ra) # a2e <printf>
  testcall();
 3fe:	00000097          	auipc	ra,0x0
 402:	dca080e7          	jalr	-566(ra) # 1c8 <testcall>
  testmem();
 406:	00000097          	auipc	ra,0x0
 40a:	cba080e7          	jalr	-838(ra) # c0 <testmem>
  testproc();
 40e:	00000097          	auipc	ra,0x0
 412:	e24080e7          	jalr	-476(ra) # 232 <testproc>
  testfd();
 416:	00000097          	auipc	ra,0x0
 41a:	ee0080e7          	jalr	-288(ra) # 2f6 <testfd>
  printf("sysinfotest: OK\n");
 41e:	00001517          	auipc	a0,0x1
 422:	92a50513          	addi	a0,a0,-1750 # d48 <malloc+0x262>
 426:	00000097          	auipc	ra,0x0
 42a:	608080e7          	jalr	1544(ra) # a2e <printf>
  exit(0);
 42e:	4501                	li	a0,0
 430:	00000097          	auipc	ra,0x0
 434:	274080e7          	jalr	628(ra) # 6a4 <exit>

0000000000000438 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 438:	1141                	addi	sp,sp,-16
 43a:	e422                	sd	s0,8(sp)
 43c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 43e:	87aa                	mv	a5,a0
 440:	0585                	addi	a1,a1,1 # fffffffffffff001 <__global_pointer$+0xffffffffffffda30>
 442:	0785                	addi	a5,a5,1
 444:	fff5c703          	lbu	a4,-1(a1)
 448:	fee78fa3          	sb	a4,-1(a5)
 44c:	fb75                	bnez	a4,440 <strcpy+0x8>
    ;
  return os;
}
 44e:	6422                	ld	s0,8(sp)
 450:	0141                	addi	sp,sp,16
 452:	8082                	ret

0000000000000454 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 454:	1141                	addi	sp,sp,-16
 456:	e422                	sd	s0,8(sp)
 458:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 45a:	00054783          	lbu	a5,0(a0)
 45e:	cb91                	beqz	a5,472 <strcmp+0x1e>
 460:	0005c703          	lbu	a4,0(a1)
 464:	00f71763          	bne	a4,a5,472 <strcmp+0x1e>
    p++, q++;
 468:	0505                	addi	a0,a0,1
 46a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 46c:	00054783          	lbu	a5,0(a0)
 470:	fbe5                	bnez	a5,460 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 472:	0005c503          	lbu	a0,0(a1)
}
 476:	40a7853b          	subw	a0,a5,a0
 47a:	6422                	ld	s0,8(sp)
 47c:	0141                	addi	sp,sp,16
 47e:	8082                	ret

0000000000000480 <strlen>:

uint
strlen(const char *s)
{
 480:	1141                	addi	sp,sp,-16
 482:	e422                	sd	s0,8(sp)
 484:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 486:	00054783          	lbu	a5,0(a0)
 48a:	cf91                	beqz	a5,4a6 <strlen+0x26>
 48c:	0505                	addi	a0,a0,1
 48e:	87aa                	mv	a5,a0
 490:	4685                	li	a3,1
 492:	9e89                	subw	a3,a3,a0
 494:	00f6853b          	addw	a0,a3,a5
 498:	0785                	addi	a5,a5,1
 49a:	fff7c703          	lbu	a4,-1(a5)
 49e:	fb7d                	bnez	a4,494 <strlen+0x14>
    ;
  return n;
}
 4a0:	6422                	ld	s0,8(sp)
 4a2:	0141                	addi	sp,sp,16
 4a4:	8082                	ret
  for(n = 0; s[n]; n++)
 4a6:	4501                	li	a0,0
 4a8:	bfe5                	j	4a0 <strlen+0x20>

00000000000004aa <memset>:

void*
memset(void *dst, int c, uint n)
{
 4aa:	1141                	addi	sp,sp,-16
 4ac:	e422                	sd	s0,8(sp)
 4ae:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4b0:	ca19                	beqz	a2,4c6 <memset+0x1c>
 4b2:	87aa                	mv	a5,a0
 4b4:	1602                	slli	a2,a2,0x20
 4b6:	9201                	srli	a2,a2,0x20
 4b8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 4bc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4c0:	0785                	addi	a5,a5,1
 4c2:	fee79de3          	bne	a5,a4,4bc <memset+0x12>
  }
  return dst;
}
 4c6:	6422                	ld	s0,8(sp)
 4c8:	0141                	addi	sp,sp,16
 4ca:	8082                	ret

00000000000004cc <strchr>:

char*
strchr(const char *s, char c)
{
 4cc:	1141                	addi	sp,sp,-16
 4ce:	e422                	sd	s0,8(sp)
 4d0:	0800                	addi	s0,sp,16
  for(; *s; s++)
 4d2:	00054783          	lbu	a5,0(a0)
 4d6:	cb99                	beqz	a5,4ec <strchr+0x20>
    if(*s == c)
 4d8:	00f58763          	beq	a1,a5,4e6 <strchr+0x1a>
  for(; *s; s++)
 4dc:	0505                	addi	a0,a0,1
 4de:	00054783          	lbu	a5,0(a0)
 4e2:	fbfd                	bnez	a5,4d8 <strchr+0xc>
      return (char*)s;
  return 0;
 4e4:	4501                	li	a0,0
}
 4e6:	6422                	ld	s0,8(sp)
 4e8:	0141                	addi	sp,sp,16
 4ea:	8082                	ret
  return 0;
 4ec:	4501                	li	a0,0
 4ee:	bfe5                	j	4e6 <strchr+0x1a>

00000000000004f0 <gets>:

char*
gets(char *buf, int max)
{
 4f0:	711d                	addi	sp,sp,-96
 4f2:	ec86                	sd	ra,88(sp)
 4f4:	e8a2                	sd	s0,80(sp)
 4f6:	e4a6                	sd	s1,72(sp)
 4f8:	e0ca                	sd	s2,64(sp)
 4fa:	fc4e                	sd	s3,56(sp)
 4fc:	f852                	sd	s4,48(sp)
 4fe:	f456                	sd	s5,40(sp)
 500:	f05a                	sd	s6,32(sp)
 502:	ec5e                	sd	s7,24(sp)
 504:	1080                	addi	s0,sp,96
 506:	8baa                	mv	s7,a0
 508:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 50a:	892a                	mv	s2,a0
 50c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 50e:	4aa9                	li	s5,10
 510:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 512:	89a6                	mv	s3,s1
 514:	2485                	addiw	s1,s1,1
 516:	0344d863          	bge	s1,s4,546 <gets+0x56>
    cc = read(0, &c, 1);
 51a:	4605                	li	a2,1
 51c:	faf40593          	addi	a1,s0,-81
 520:	4501                	li	a0,0
 522:	00000097          	auipc	ra,0x0
 526:	19a080e7          	jalr	410(ra) # 6bc <read>
    if(cc < 1)
 52a:	00a05e63          	blez	a0,546 <gets+0x56>
    buf[i++] = c;
 52e:	faf44783          	lbu	a5,-81(s0)
 532:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 536:	01578763          	beq	a5,s5,544 <gets+0x54>
 53a:	0905                	addi	s2,s2,1
 53c:	fd679be3          	bne	a5,s6,512 <gets+0x22>
  for(i=0; i+1 < max; ){
 540:	89a6                	mv	s3,s1
 542:	a011                	j	546 <gets+0x56>
 544:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 546:	99de                	add	s3,s3,s7
 548:	00098023          	sb	zero,0(s3)
  return buf;
}
 54c:	855e                	mv	a0,s7
 54e:	60e6                	ld	ra,88(sp)
 550:	6446                	ld	s0,80(sp)
 552:	64a6                	ld	s1,72(sp)
 554:	6906                	ld	s2,64(sp)
 556:	79e2                	ld	s3,56(sp)
 558:	7a42                	ld	s4,48(sp)
 55a:	7aa2                	ld	s5,40(sp)
 55c:	7b02                	ld	s6,32(sp)
 55e:	6be2                	ld	s7,24(sp)
 560:	6125                	addi	sp,sp,96
 562:	8082                	ret

0000000000000564 <stat>:

int
stat(const char *n, struct stat *st)
{
 564:	1101                	addi	sp,sp,-32
 566:	ec06                	sd	ra,24(sp)
 568:	e822                	sd	s0,16(sp)
 56a:	e426                	sd	s1,8(sp)
 56c:	e04a                	sd	s2,0(sp)
 56e:	1000                	addi	s0,sp,32
 570:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 572:	4581                	li	a1,0
 574:	00000097          	auipc	ra,0x0
 578:	170080e7          	jalr	368(ra) # 6e4 <open>
  if(fd < 0)
 57c:	02054563          	bltz	a0,5a6 <stat+0x42>
 580:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 582:	85ca                	mv	a1,s2
 584:	00000097          	auipc	ra,0x0
 588:	178080e7          	jalr	376(ra) # 6fc <fstat>
 58c:	892a                	mv	s2,a0
  close(fd);
 58e:	8526                	mv	a0,s1
 590:	00000097          	auipc	ra,0x0
 594:	13c080e7          	jalr	316(ra) # 6cc <close>
  return r;
}
 598:	854a                	mv	a0,s2
 59a:	60e2                	ld	ra,24(sp)
 59c:	6442                	ld	s0,16(sp)
 59e:	64a2                	ld	s1,8(sp)
 5a0:	6902                	ld	s2,0(sp)
 5a2:	6105                	addi	sp,sp,32
 5a4:	8082                	ret
    return -1;
 5a6:	597d                	li	s2,-1
 5a8:	bfc5                	j	598 <stat+0x34>

00000000000005aa <atoi>:

int
atoi(const char *s)
{
 5aa:	1141                	addi	sp,sp,-16
 5ac:	e422                	sd	s0,8(sp)
 5ae:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5b0:	00054683          	lbu	a3,0(a0)
 5b4:	fd06879b          	addiw	a5,a3,-48
 5b8:	0ff7f793          	zext.b	a5,a5
 5bc:	4625                	li	a2,9
 5be:	02f66863          	bltu	a2,a5,5ee <atoi+0x44>
 5c2:	872a                	mv	a4,a0
  n = 0;
 5c4:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 5c6:	0705                	addi	a4,a4,1
 5c8:	0025179b          	slliw	a5,a0,0x2
 5cc:	9fa9                	addw	a5,a5,a0
 5ce:	0017979b          	slliw	a5,a5,0x1
 5d2:	9fb5                	addw	a5,a5,a3
 5d4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 5d8:	00074683          	lbu	a3,0(a4)
 5dc:	fd06879b          	addiw	a5,a3,-48
 5e0:	0ff7f793          	zext.b	a5,a5
 5e4:	fef671e3          	bgeu	a2,a5,5c6 <atoi+0x1c>
  return n;
}
 5e8:	6422                	ld	s0,8(sp)
 5ea:	0141                	addi	sp,sp,16
 5ec:	8082                	ret
  n = 0;
 5ee:	4501                	li	a0,0
 5f0:	bfe5                	j	5e8 <atoi+0x3e>

00000000000005f2 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 5f2:	1141                	addi	sp,sp,-16
 5f4:	e422                	sd	s0,8(sp)
 5f6:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 5f8:	02b57463          	bgeu	a0,a1,620 <memmove+0x2e>
    while(n-- > 0)
 5fc:	00c05f63          	blez	a2,61a <memmove+0x28>
 600:	1602                	slli	a2,a2,0x20
 602:	9201                	srli	a2,a2,0x20
 604:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 608:	872a                	mv	a4,a0
      *dst++ = *src++;
 60a:	0585                	addi	a1,a1,1
 60c:	0705                	addi	a4,a4,1
 60e:	fff5c683          	lbu	a3,-1(a1)
 612:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 616:	fee79ae3          	bne	a5,a4,60a <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 61a:	6422                	ld	s0,8(sp)
 61c:	0141                	addi	sp,sp,16
 61e:	8082                	ret
    dst += n;
 620:	00c50733          	add	a4,a0,a2
    src += n;
 624:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 626:	fec05ae3          	blez	a2,61a <memmove+0x28>
 62a:	fff6079b          	addiw	a5,a2,-1
 62e:	1782                	slli	a5,a5,0x20
 630:	9381                	srli	a5,a5,0x20
 632:	fff7c793          	not	a5,a5
 636:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 638:	15fd                	addi	a1,a1,-1
 63a:	177d                	addi	a4,a4,-1
 63c:	0005c683          	lbu	a3,0(a1)
 640:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 644:	fee79ae3          	bne	a5,a4,638 <memmove+0x46>
 648:	bfc9                	j	61a <memmove+0x28>

000000000000064a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 64a:	1141                	addi	sp,sp,-16
 64c:	e422                	sd	s0,8(sp)
 64e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 650:	ca05                	beqz	a2,680 <memcmp+0x36>
 652:	fff6069b          	addiw	a3,a2,-1
 656:	1682                	slli	a3,a3,0x20
 658:	9281                	srli	a3,a3,0x20
 65a:	0685                	addi	a3,a3,1
 65c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 65e:	00054783          	lbu	a5,0(a0)
 662:	0005c703          	lbu	a4,0(a1)
 666:	00e79863          	bne	a5,a4,676 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 66a:	0505                	addi	a0,a0,1
    p2++;
 66c:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 66e:	fed518e3          	bne	a0,a3,65e <memcmp+0x14>
  }
  return 0;
 672:	4501                	li	a0,0
 674:	a019                	j	67a <memcmp+0x30>
      return *p1 - *p2;
 676:	40e7853b          	subw	a0,a5,a4
}
 67a:	6422                	ld	s0,8(sp)
 67c:	0141                	addi	sp,sp,16
 67e:	8082                	ret
  return 0;
 680:	4501                	li	a0,0
 682:	bfe5                	j	67a <memcmp+0x30>

0000000000000684 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 684:	1141                	addi	sp,sp,-16
 686:	e406                	sd	ra,8(sp)
 688:	e022                	sd	s0,0(sp)
 68a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 68c:	00000097          	auipc	ra,0x0
 690:	f66080e7          	jalr	-154(ra) # 5f2 <memmove>
}
 694:	60a2                	ld	ra,8(sp)
 696:	6402                	ld	s0,0(sp)
 698:	0141                	addi	sp,sp,16
 69a:	8082                	ret

000000000000069c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 69c:	4885                	li	a7,1
 ecall
 69e:	00000073          	ecall
 ret
 6a2:	8082                	ret

00000000000006a4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6a4:	4889                	li	a7,2
 ecall
 6a6:	00000073          	ecall
 ret
 6aa:	8082                	ret

00000000000006ac <wait>:
.global wait
wait:
 li a7, SYS_wait
 6ac:	488d                	li	a7,3
 ecall
 6ae:	00000073          	ecall
 ret
 6b2:	8082                	ret

00000000000006b4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6b4:	4891                	li	a7,4
 ecall
 6b6:	00000073          	ecall
 ret
 6ba:	8082                	ret

00000000000006bc <read>:
.global read
read:
 li a7, SYS_read
 6bc:	4895                	li	a7,5
 ecall
 6be:	00000073          	ecall
 ret
 6c2:	8082                	ret

00000000000006c4 <write>:
.global write
write:
 li a7, SYS_write
 6c4:	48c1                	li	a7,16
 ecall
 6c6:	00000073          	ecall
 ret
 6ca:	8082                	ret

00000000000006cc <close>:
.global close
close:
 li a7, SYS_close
 6cc:	48d5                	li	a7,21
 ecall
 6ce:	00000073          	ecall
 ret
 6d2:	8082                	ret

00000000000006d4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 6d4:	4899                	li	a7,6
 ecall
 6d6:	00000073          	ecall
 ret
 6da:	8082                	ret

00000000000006dc <exec>:
.global exec
exec:
 li a7, SYS_exec
 6dc:	489d                	li	a7,7
 ecall
 6de:	00000073          	ecall
 ret
 6e2:	8082                	ret

00000000000006e4 <open>:
.global open
open:
 li a7, SYS_open
 6e4:	48bd                	li	a7,15
 ecall
 6e6:	00000073          	ecall
 ret
 6ea:	8082                	ret

00000000000006ec <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 6ec:	48c5                	li	a7,17
 ecall
 6ee:	00000073          	ecall
 ret
 6f2:	8082                	ret

00000000000006f4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 6f4:	48c9                	li	a7,18
 ecall
 6f6:	00000073          	ecall
 ret
 6fa:	8082                	ret

00000000000006fc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 6fc:	48a1                	li	a7,8
 ecall
 6fe:	00000073          	ecall
 ret
 702:	8082                	ret

0000000000000704 <link>:
.global link
link:
 li a7, SYS_link
 704:	48cd                	li	a7,19
 ecall
 706:	00000073          	ecall
 ret
 70a:	8082                	ret

000000000000070c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 70c:	48d1                	li	a7,20
 ecall
 70e:	00000073          	ecall
 ret
 712:	8082                	ret

0000000000000714 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 714:	48a5                	li	a7,9
 ecall
 716:	00000073          	ecall
 ret
 71a:	8082                	ret

000000000000071c <dup>:
.global dup
dup:
 li a7, SYS_dup
 71c:	48a9                	li	a7,10
 ecall
 71e:	00000073          	ecall
 ret
 722:	8082                	ret

0000000000000724 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 724:	48ad                	li	a7,11
 ecall
 726:	00000073          	ecall
 ret
 72a:	8082                	ret

000000000000072c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 72c:	48b1                	li	a7,12
 ecall
 72e:	00000073          	ecall
 ret
 732:	8082                	ret

0000000000000734 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 734:	48b5                	li	a7,13
 ecall
 736:	00000073          	ecall
 ret
 73a:	8082                	ret

000000000000073c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 73c:	48b9                	li	a7,14
 ecall
 73e:	00000073          	ecall
 ret
 742:	8082                	ret

0000000000000744 <trace>:
.global trace
trace:
 li a7, SYS_trace
 744:	48d9                	li	a7,22
 ecall
 746:	00000073          	ecall
 ret
 74a:	8082                	ret

000000000000074c <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 74c:	48dd                	li	a7,23
 ecall
 74e:	00000073          	ecall
 ret
 752:	8082                	ret

0000000000000754 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 754:	1101                	addi	sp,sp,-32
 756:	ec06                	sd	ra,24(sp)
 758:	e822                	sd	s0,16(sp)
 75a:	1000                	addi	s0,sp,32
 75c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 760:	4605                	li	a2,1
 762:	fef40593          	addi	a1,s0,-17
 766:	00000097          	auipc	ra,0x0
 76a:	f5e080e7          	jalr	-162(ra) # 6c4 <write>
}
 76e:	60e2                	ld	ra,24(sp)
 770:	6442                	ld	s0,16(sp)
 772:	6105                	addi	sp,sp,32
 774:	8082                	ret

0000000000000776 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 776:	7139                	addi	sp,sp,-64
 778:	fc06                	sd	ra,56(sp)
 77a:	f822                	sd	s0,48(sp)
 77c:	f426                	sd	s1,40(sp)
 77e:	f04a                	sd	s2,32(sp)
 780:	ec4e                	sd	s3,24(sp)
 782:	0080                	addi	s0,sp,64
 784:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 786:	c299                	beqz	a3,78c <printint+0x16>
 788:	0805c963          	bltz	a1,81a <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 78c:	2581                	sext.w	a1,a1
  neg = 0;
 78e:	4881                	li	a7,0
 790:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 794:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 796:	2601                	sext.w	a2,a2
 798:	00000517          	auipc	a0,0x0
 79c:	62850513          	addi	a0,a0,1576 # dc0 <digits>
 7a0:	883a                	mv	a6,a4
 7a2:	2705                	addiw	a4,a4,1
 7a4:	02c5f7bb          	remuw	a5,a1,a2
 7a8:	1782                	slli	a5,a5,0x20
 7aa:	9381                	srli	a5,a5,0x20
 7ac:	97aa                	add	a5,a5,a0
 7ae:	0007c783          	lbu	a5,0(a5)
 7b2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7b6:	0005879b          	sext.w	a5,a1
 7ba:	02c5d5bb          	divuw	a1,a1,a2
 7be:	0685                	addi	a3,a3,1
 7c0:	fec7f0e3          	bgeu	a5,a2,7a0 <printint+0x2a>
  if(neg)
 7c4:	00088c63          	beqz	a7,7dc <printint+0x66>
    buf[i++] = '-';
 7c8:	fd070793          	addi	a5,a4,-48
 7cc:	00878733          	add	a4,a5,s0
 7d0:	02d00793          	li	a5,45
 7d4:	fef70823          	sb	a5,-16(a4)
 7d8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 7dc:	02e05863          	blez	a4,80c <printint+0x96>
 7e0:	fc040793          	addi	a5,s0,-64
 7e4:	00e78933          	add	s2,a5,a4
 7e8:	fff78993          	addi	s3,a5,-1
 7ec:	99ba                	add	s3,s3,a4
 7ee:	377d                	addiw	a4,a4,-1
 7f0:	1702                	slli	a4,a4,0x20
 7f2:	9301                	srli	a4,a4,0x20
 7f4:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 7f8:	fff94583          	lbu	a1,-1(s2)
 7fc:	8526                	mv	a0,s1
 7fe:	00000097          	auipc	ra,0x0
 802:	f56080e7          	jalr	-170(ra) # 754 <putc>
  while(--i >= 0)
 806:	197d                	addi	s2,s2,-1
 808:	ff3918e3          	bne	s2,s3,7f8 <printint+0x82>
}
 80c:	70e2                	ld	ra,56(sp)
 80e:	7442                	ld	s0,48(sp)
 810:	74a2                	ld	s1,40(sp)
 812:	7902                	ld	s2,32(sp)
 814:	69e2                	ld	s3,24(sp)
 816:	6121                	addi	sp,sp,64
 818:	8082                	ret
    x = -xx;
 81a:	40b005bb          	negw	a1,a1
    neg = 1;
 81e:	4885                	li	a7,1
    x = -xx;
 820:	bf85                	j	790 <printint+0x1a>

0000000000000822 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 822:	7119                	addi	sp,sp,-128
 824:	fc86                	sd	ra,120(sp)
 826:	f8a2                	sd	s0,112(sp)
 828:	f4a6                	sd	s1,104(sp)
 82a:	f0ca                	sd	s2,96(sp)
 82c:	ecce                	sd	s3,88(sp)
 82e:	e8d2                	sd	s4,80(sp)
 830:	e4d6                	sd	s5,72(sp)
 832:	e0da                	sd	s6,64(sp)
 834:	fc5e                	sd	s7,56(sp)
 836:	f862                	sd	s8,48(sp)
 838:	f466                	sd	s9,40(sp)
 83a:	f06a                	sd	s10,32(sp)
 83c:	ec6e                	sd	s11,24(sp)
 83e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 840:	0005c903          	lbu	s2,0(a1)
 844:	18090f63          	beqz	s2,9e2 <vprintf+0x1c0>
 848:	8aaa                	mv	s5,a0
 84a:	8b32                	mv	s6,a2
 84c:	00158493          	addi	s1,a1,1
  state = 0;
 850:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 852:	02500a13          	li	s4,37
 856:	4c55                	li	s8,21
 858:	00000c97          	auipc	s9,0x0
 85c:	510c8c93          	addi	s9,s9,1296 # d68 <malloc+0x282>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 860:	02800d93          	li	s11,40
  putc(fd, 'x');
 864:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 866:	00000b97          	auipc	s7,0x0
 86a:	55ab8b93          	addi	s7,s7,1370 # dc0 <digits>
 86e:	a839                	j	88c <vprintf+0x6a>
        putc(fd, c);
 870:	85ca                	mv	a1,s2
 872:	8556                	mv	a0,s5
 874:	00000097          	auipc	ra,0x0
 878:	ee0080e7          	jalr	-288(ra) # 754 <putc>
 87c:	a019                	j	882 <vprintf+0x60>
    } else if(state == '%'){
 87e:	01498d63          	beq	s3,s4,898 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 882:	0485                	addi	s1,s1,1
 884:	fff4c903          	lbu	s2,-1(s1)
 888:	14090d63          	beqz	s2,9e2 <vprintf+0x1c0>
    if(state == 0){
 88c:	fe0999e3          	bnez	s3,87e <vprintf+0x5c>
      if(c == '%'){
 890:	ff4910e3          	bne	s2,s4,870 <vprintf+0x4e>
        state = '%';
 894:	89d2                	mv	s3,s4
 896:	b7f5                	j	882 <vprintf+0x60>
      if(c == 'd'){
 898:	11490c63          	beq	s2,s4,9b0 <vprintf+0x18e>
 89c:	f9d9079b          	addiw	a5,s2,-99
 8a0:	0ff7f793          	zext.b	a5,a5
 8a4:	10fc6e63          	bltu	s8,a5,9c0 <vprintf+0x19e>
 8a8:	f9d9079b          	addiw	a5,s2,-99
 8ac:	0ff7f713          	zext.b	a4,a5
 8b0:	10ec6863          	bltu	s8,a4,9c0 <vprintf+0x19e>
 8b4:	00271793          	slli	a5,a4,0x2
 8b8:	97e6                	add	a5,a5,s9
 8ba:	439c                	lw	a5,0(a5)
 8bc:	97e6                	add	a5,a5,s9
 8be:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 8c0:	008b0913          	addi	s2,s6,8
 8c4:	4685                	li	a3,1
 8c6:	4629                	li	a2,10
 8c8:	000b2583          	lw	a1,0(s6)
 8cc:	8556                	mv	a0,s5
 8ce:	00000097          	auipc	ra,0x0
 8d2:	ea8080e7          	jalr	-344(ra) # 776 <printint>
 8d6:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 8d8:	4981                	li	s3,0
 8da:	b765                	j	882 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 8dc:	008b0913          	addi	s2,s6,8
 8e0:	4681                	li	a3,0
 8e2:	4629                	li	a2,10
 8e4:	000b2583          	lw	a1,0(s6)
 8e8:	8556                	mv	a0,s5
 8ea:	00000097          	auipc	ra,0x0
 8ee:	e8c080e7          	jalr	-372(ra) # 776 <printint>
 8f2:	8b4a                	mv	s6,s2
      state = 0;
 8f4:	4981                	li	s3,0
 8f6:	b771                	j	882 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 8f8:	008b0913          	addi	s2,s6,8
 8fc:	4681                	li	a3,0
 8fe:	866a                	mv	a2,s10
 900:	000b2583          	lw	a1,0(s6)
 904:	8556                	mv	a0,s5
 906:	00000097          	auipc	ra,0x0
 90a:	e70080e7          	jalr	-400(ra) # 776 <printint>
 90e:	8b4a                	mv	s6,s2
      state = 0;
 910:	4981                	li	s3,0
 912:	bf85                	j	882 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 914:	008b0793          	addi	a5,s6,8
 918:	f8f43423          	sd	a5,-120(s0)
 91c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 920:	03000593          	li	a1,48
 924:	8556                	mv	a0,s5
 926:	00000097          	auipc	ra,0x0
 92a:	e2e080e7          	jalr	-466(ra) # 754 <putc>
  putc(fd, 'x');
 92e:	07800593          	li	a1,120
 932:	8556                	mv	a0,s5
 934:	00000097          	auipc	ra,0x0
 938:	e20080e7          	jalr	-480(ra) # 754 <putc>
 93c:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 93e:	03c9d793          	srli	a5,s3,0x3c
 942:	97de                	add	a5,a5,s7
 944:	0007c583          	lbu	a1,0(a5)
 948:	8556                	mv	a0,s5
 94a:	00000097          	auipc	ra,0x0
 94e:	e0a080e7          	jalr	-502(ra) # 754 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 952:	0992                	slli	s3,s3,0x4
 954:	397d                	addiw	s2,s2,-1
 956:	fe0914e3          	bnez	s2,93e <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 95a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 95e:	4981                	li	s3,0
 960:	b70d                	j	882 <vprintf+0x60>
        s = va_arg(ap, char*);
 962:	008b0913          	addi	s2,s6,8
 966:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 96a:	02098163          	beqz	s3,98c <vprintf+0x16a>
        while(*s != 0){
 96e:	0009c583          	lbu	a1,0(s3)
 972:	c5ad                	beqz	a1,9dc <vprintf+0x1ba>
          putc(fd, *s);
 974:	8556                	mv	a0,s5
 976:	00000097          	auipc	ra,0x0
 97a:	dde080e7          	jalr	-546(ra) # 754 <putc>
          s++;
 97e:	0985                	addi	s3,s3,1
        while(*s != 0){
 980:	0009c583          	lbu	a1,0(s3)
 984:	f9e5                	bnez	a1,974 <vprintf+0x152>
        s = va_arg(ap, char*);
 986:	8b4a                	mv	s6,s2
      state = 0;
 988:	4981                	li	s3,0
 98a:	bde5                	j	882 <vprintf+0x60>
          s = "(null)";
 98c:	00000997          	auipc	s3,0x0
 990:	3d498993          	addi	s3,s3,980 # d60 <malloc+0x27a>
        while(*s != 0){
 994:	85ee                	mv	a1,s11
 996:	bff9                	j	974 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 998:	008b0913          	addi	s2,s6,8
 99c:	000b4583          	lbu	a1,0(s6)
 9a0:	8556                	mv	a0,s5
 9a2:	00000097          	auipc	ra,0x0
 9a6:	db2080e7          	jalr	-590(ra) # 754 <putc>
 9aa:	8b4a                	mv	s6,s2
      state = 0;
 9ac:	4981                	li	s3,0
 9ae:	bdd1                	j	882 <vprintf+0x60>
        putc(fd, c);
 9b0:	85d2                	mv	a1,s4
 9b2:	8556                	mv	a0,s5
 9b4:	00000097          	auipc	ra,0x0
 9b8:	da0080e7          	jalr	-608(ra) # 754 <putc>
      state = 0;
 9bc:	4981                	li	s3,0
 9be:	b5d1                	j	882 <vprintf+0x60>
        putc(fd, '%');
 9c0:	85d2                	mv	a1,s4
 9c2:	8556                	mv	a0,s5
 9c4:	00000097          	auipc	ra,0x0
 9c8:	d90080e7          	jalr	-624(ra) # 754 <putc>
        putc(fd, c);
 9cc:	85ca                	mv	a1,s2
 9ce:	8556                	mv	a0,s5
 9d0:	00000097          	auipc	ra,0x0
 9d4:	d84080e7          	jalr	-636(ra) # 754 <putc>
      state = 0;
 9d8:	4981                	li	s3,0
 9da:	b565                	j	882 <vprintf+0x60>
        s = va_arg(ap, char*);
 9dc:	8b4a                	mv	s6,s2
      state = 0;
 9de:	4981                	li	s3,0
 9e0:	b54d                	j	882 <vprintf+0x60>
    }
  }
}
 9e2:	70e6                	ld	ra,120(sp)
 9e4:	7446                	ld	s0,112(sp)
 9e6:	74a6                	ld	s1,104(sp)
 9e8:	7906                	ld	s2,96(sp)
 9ea:	69e6                	ld	s3,88(sp)
 9ec:	6a46                	ld	s4,80(sp)
 9ee:	6aa6                	ld	s5,72(sp)
 9f0:	6b06                	ld	s6,64(sp)
 9f2:	7be2                	ld	s7,56(sp)
 9f4:	7c42                	ld	s8,48(sp)
 9f6:	7ca2                	ld	s9,40(sp)
 9f8:	7d02                	ld	s10,32(sp)
 9fa:	6de2                	ld	s11,24(sp)
 9fc:	6109                	addi	sp,sp,128
 9fe:	8082                	ret

0000000000000a00 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a00:	715d                	addi	sp,sp,-80
 a02:	ec06                	sd	ra,24(sp)
 a04:	e822                	sd	s0,16(sp)
 a06:	1000                	addi	s0,sp,32
 a08:	e010                	sd	a2,0(s0)
 a0a:	e414                	sd	a3,8(s0)
 a0c:	e818                	sd	a4,16(s0)
 a0e:	ec1c                	sd	a5,24(s0)
 a10:	03043023          	sd	a6,32(s0)
 a14:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a18:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a1c:	8622                	mv	a2,s0
 a1e:	00000097          	auipc	ra,0x0
 a22:	e04080e7          	jalr	-508(ra) # 822 <vprintf>
}
 a26:	60e2                	ld	ra,24(sp)
 a28:	6442                	ld	s0,16(sp)
 a2a:	6161                	addi	sp,sp,80
 a2c:	8082                	ret

0000000000000a2e <printf>:

void
printf(const char *fmt, ...)
{
 a2e:	711d                	addi	sp,sp,-96
 a30:	ec06                	sd	ra,24(sp)
 a32:	e822                	sd	s0,16(sp)
 a34:	1000                	addi	s0,sp,32
 a36:	e40c                	sd	a1,8(s0)
 a38:	e810                	sd	a2,16(s0)
 a3a:	ec14                	sd	a3,24(s0)
 a3c:	f018                	sd	a4,32(s0)
 a3e:	f41c                	sd	a5,40(s0)
 a40:	03043823          	sd	a6,48(s0)
 a44:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a48:	00840613          	addi	a2,s0,8
 a4c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a50:	85aa                	mv	a1,a0
 a52:	4505                	li	a0,1
 a54:	00000097          	auipc	ra,0x0
 a58:	dce080e7          	jalr	-562(ra) # 822 <vprintf>
}
 a5c:	60e2                	ld	ra,24(sp)
 a5e:	6442                	ld	s0,16(sp)
 a60:	6125                	addi	sp,sp,96
 a62:	8082                	ret

0000000000000a64 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a64:	1141                	addi	sp,sp,-16
 a66:	e422                	sd	s0,8(sp)
 a68:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a6a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a6e:	00000797          	auipc	a5,0x0
 a72:	3727b783          	ld	a5,882(a5) # de0 <freep>
 a76:	a02d                	j	aa0 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 a78:	4618                	lw	a4,8(a2)
 a7a:	9f2d                	addw	a4,a4,a1
 a7c:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 a80:	6398                	ld	a4,0(a5)
 a82:	6310                	ld	a2,0(a4)
 a84:	a83d                	j	ac2 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 a86:	ff852703          	lw	a4,-8(a0)
 a8a:	9f31                	addw	a4,a4,a2
 a8c:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 a8e:	ff053683          	ld	a3,-16(a0)
 a92:	a091                	j	ad6 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 a94:	6398                	ld	a4,0(a5)
 a96:	00e7e463          	bltu	a5,a4,a9e <free+0x3a>
 a9a:	00e6ea63          	bltu	a3,a4,aae <free+0x4a>
{
 a9e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 aa0:	fed7fae3          	bgeu	a5,a3,a94 <free+0x30>
 aa4:	6398                	ld	a4,0(a5)
 aa6:	00e6e463          	bltu	a3,a4,aae <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 aaa:	fee7eae3          	bltu	a5,a4,a9e <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 aae:	ff852583          	lw	a1,-8(a0)
 ab2:	6390                	ld	a2,0(a5)
 ab4:	02059813          	slli	a6,a1,0x20
 ab8:	01c85713          	srli	a4,a6,0x1c
 abc:	9736                	add	a4,a4,a3
 abe:	fae60de3          	beq	a2,a4,a78 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 ac2:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 ac6:	4790                	lw	a2,8(a5)
 ac8:	02061593          	slli	a1,a2,0x20
 acc:	01c5d713          	srli	a4,a1,0x1c
 ad0:	973e                	add	a4,a4,a5
 ad2:	fae68ae3          	beq	a3,a4,a86 <free+0x22>
    p->s.ptr = bp->s.ptr;
 ad6:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 ad8:	00000717          	auipc	a4,0x0
 adc:	30f73423          	sd	a5,776(a4) # de0 <freep>
}
 ae0:	6422                	ld	s0,8(sp)
 ae2:	0141                	addi	sp,sp,16
 ae4:	8082                	ret

0000000000000ae6 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 ae6:	7139                	addi	sp,sp,-64
 ae8:	fc06                	sd	ra,56(sp)
 aea:	f822                	sd	s0,48(sp)
 aec:	f426                	sd	s1,40(sp)
 aee:	f04a                	sd	s2,32(sp)
 af0:	ec4e                	sd	s3,24(sp)
 af2:	e852                	sd	s4,16(sp)
 af4:	e456                	sd	s5,8(sp)
 af6:	e05a                	sd	s6,0(sp)
 af8:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 afa:	02051493          	slli	s1,a0,0x20
 afe:	9081                	srli	s1,s1,0x20
 b00:	04bd                	addi	s1,s1,15
 b02:	8091                	srli	s1,s1,0x4
 b04:	0014899b          	addiw	s3,s1,1
 b08:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b0a:	00000517          	auipc	a0,0x0
 b0e:	2d653503          	ld	a0,726(a0) # de0 <freep>
 b12:	c515                	beqz	a0,b3e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b14:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b16:	4798                	lw	a4,8(a5)
 b18:	02977f63          	bgeu	a4,s1,b56 <malloc+0x70>
 b1c:	8a4e                	mv	s4,s3
 b1e:	0009871b          	sext.w	a4,s3
 b22:	6685                	lui	a3,0x1
 b24:	00d77363          	bgeu	a4,a3,b2a <malloc+0x44>
 b28:	6a05                	lui	s4,0x1
 b2a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b2e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b32:	00000917          	auipc	s2,0x0
 b36:	2ae90913          	addi	s2,s2,686 # de0 <freep>
  if(p == (char*)-1)
 b3a:	5afd                	li	s5,-1
 b3c:	a895                	j	bb0 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 b3e:	00000797          	auipc	a5,0x0
 b42:	2aa78793          	addi	a5,a5,682 # de8 <base>
 b46:	00000717          	auipc	a4,0x0
 b4a:	28f73d23          	sd	a5,666(a4) # de0 <freep>
 b4e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b50:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b54:	b7e1                	j	b1c <malloc+0x36>
      if(p->s.size == nunits)
 b56:	02e48c63          	beq	s1,a4,b8e <malloc+0xa8>
        p->s.size -= nunits;
 b5a:	4137073b          	subw	a4,a4,s3
 b5e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b60:	02071693          	slli	a3,a4,0x20
 b64:	01c6d713          	srli	a4,a3,0x1c
 b68:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b6a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 b6e:	00000717          	auipc	a4,0x0
 b72:	26a73923          	sd	a0,626(a4) # de0 <freep>
      return (void*)(p + 1);
 b76:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 b7a:	70e2                	ld	ra,56(sp)
 b7c:	7442                	ld	s0,48(sp)
 b7e:	74a2                	ld	s1,40(sp)
 b80:	7902                	ld	s2,32(sp)
 b82:	69e2                	ld	s3,24(sp)
 b84:	6a42                	ld	s4,16(sp)
 b86:	6aa2                	ld	s5,8(sp)
 b88:	6b02                	ld	s6,0(sp)
 b8a:	6121                	addi	sp,sp,64
 b8c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 b8e:	6398                	ld	a4,0(a5)
 b90:	e118                	sd	a4,0(a0)
 b92:	bff1                	j	b6e <malloc+0x88>
  hp->s.size = nu;
 b94:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 b98:	0541                	addi	a0,a0,16
 b9a:	00000097          	auipc	ra,0x0
 b9e:	eca080e7          	jalr	-310(ra) # a64 <free>
  return freep;
 ba2:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 ba6:	d971                	beqz	a0,b7a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 ba8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 baa:	4798                	lw	a4,8(a5)
 bac:	fa9775e3          	bgeu	a4,s1,b56 <malloc+0x70>
    if(p == freep)
 bb0:	00093703          	ld	a4,0(s2)
 bb4:	853e                	mv	a0,a5
 bb6:	fef719e3          	bne	a4,a5,ba8 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 bba:	8552                	mv	a0,s4
 bbc:	00000097          	auipc	ra,0x0
 bc0:	b70080e7          	jalr	-1168(ra) # 72c <sbrk>
  if(p == (char*)-1)
 bc4:	fd5518e3          	bne	a0,s5,b94 <malloc+0xae>
        return 0;
 bc8:	4501                	li	a0,0
 bca:	bf45                	j	b7a <malloc+0x94>
