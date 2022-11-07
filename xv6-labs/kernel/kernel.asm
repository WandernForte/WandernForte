
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	e2478793          	addi	a5,a5,-476 # 80005e80 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0478793          	addi	a5,a5,-508 # 80000eaa <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af4080e7          	jalr	-1292(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305c63          	blez	s3,8000016c <consolewrite+0x80>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	540080e7          	jalr	1344(ra) # 80002666 <either_copyin>
    8000012e:	01550d63          	beq	a0,s5,80000148 <consolewrite+0x5c>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	79a080e7          	jalr	1946(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
    80000146:	894e                	mv	s2,s3
  }
  release(&cons.lock);
    80000148:	00011517          	auipc	a0,0x11
    8000014c:	6e850513          	addi	a0,a0,1768 # 80011830 <cons>
    80000150:	00001097          	auipc	ra,0x1
    80000154:	b64080e7          	jalr	-1180(ra) # 80000cb4 <release>

  return i;
}
    80000158:	854a                	mv	a0,s2
    8000015a:	60a6                	ld	ra,72(sp)
    8000015c:	6406                	ld	s0,64(sp)
    8000015e:	74e2                	ld	s1,56(sp)
    80000160:	7942                	ld	s2,48(sp)
    80000162:	79a2                	ld	s3,40(sp)
    80000164:	7a02                	ld	s4,32(sp)
    80000166:	6ae2                	ld	s5,24(sp)
    80000168:	6161                	addi	sp,sp,80
    8000016a:	8082                	ret
  for(i = 0; i < n; i++){
    8000016c:	4901                	li	s2,0
    8000016e:	bfe9                	j	80000148 <consolewrite+0x5c>

0000000080000170 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000170:	7159                	addi	sp,sp,-112
    80000172:	f486                	sd	ra,104(sp)
    80000174:	f0a2                	sd	s0,96(sp)
    80000176:	eca6                	sd	s1,88(sp)
    80000178:	e8ca                	sd	s2,80(sp)
    8000017a:	e4ce                	sd	s3,72(sp)
    8000017c:	e0d2                	sd	s4,64(sp)
    8000017e:	fc56                	sd	s5,56(sp)
    80000180:	f85a                	sd	s6,48(sp)
    80000182:	f45e                	sd	s7,40(sp)
    80000184:	f062                	sd	s8,32(sp)
    80000186:	ec66                	sd	s9,24(sp)
    80000188:	e86a                	sd	s10,16(sp)
    8000018a:	1880                	addi	s0,sp,112
    8000018c:	8aaa                	mv	s5,a0
    8000018e:	8a2e                	mv	s4,a1
    80000190:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a62080e7          	jalr	-1438(ra) # 80000c00 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	00011917          	auipc	s2,0x11
    800001b2:	71a90913          	addi	s2,s2,1818 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b6:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b8:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ba:	4ca9                	li	s9,10
  while(n > 0){
    800001bc:	07305863          	blez	s3,8000022c <consoleread+0xbc>
    while(cons.r == cons.w){
    800001c0:	0984a783          	lw	a5,152(s1)
    800001c4:	09c4a703          	lw	a4,156(s1)
    800001c8:	02f71463          	bne	a4,a5,800001f0 <consoleread+0x80>
      if(myproc()->killed){
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	934080e7          	jalr	-1740(ra) # 80001b00 <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	1da080e7          	jalr	474(ra) # 800023b6 <sleep>
    while(cons.r == cons.w){
    800001e4:	0984a783          	lw	a5,152(s1)
    800001e8:	09c4a703          	lw	a4,156(s1)
    800001ec:	fef700e3          	beq	a4,a5,800001cc <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f0:	0017871b          	addiw	a4,a5,1
    800001f4:	08e4ac23          	sw	a4,152(s1)
    800001f8:	07f7f713          	andi	a4,a5,127
    800001fc:	9726                	add	a4,a4,s1
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000206:	077d0563          	beq	s10,s7,80000270 <consoleread+0x100>
    cbuf = c;
    8000020a:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020e:	4685                	li	a3,1
    80000210:	f9f40613          	addi	a2,s0,-97
    80000214:	85d2                	mv	a1,s4
    80000216:	8556                	mv	a0,s5
    80000218:	00002097          	auipc	ra,0x2
    8000021c:	3f8080e7          	jalr	1016(ra) # 80002610 <either_copyout>
    80000220:	01850663          	beq	a0,s8,8000022c <consoleread+0xbc>
    dst++;
    80000224:	0a05                	addi	s4,s4,1
    --n;
    80000226:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000228:	f99d1ae3          	bne	s10,s9,800001bc <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	60450513          	addi	a0,a0,1540 # 80011830 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a80080e7          	jalr	-1408(ra) # 80000cb4 <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xe4>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	5ee50513          	addi	a0,a0,1518 # 80011830 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	a6a080e7          	jalr	-1430(ra) # 80000cb4 <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	70a6                	ld	ra,104(sp)
    80000256:	7406                	ld	s0,96(sp)
    80000258:	64e6                	ld	s1,88(sp)
    8000025a:	6946                	ld	s2,80(sp)
    8000025c:	69a6                	ld	s3,72(sp)
    8000025e:	6a06                	ld	s4,64(sp)
    80000260:	7ae2                	ld	s5,56(sp)
    80000262:	7b42                	ld	s6,48(sp)
    80000264:	7ba2                	ld	s7,40(sp)
    80000266:	7c02                	ld	s8,32(sp)
    80000268:	6ce2                	ld	s9,24(sp)
    8000026a:	6d42                	ld	s10,16(sp)
    8000026c:	6165                	addi	sp,sp,112
    8000026e:	8082                	ret
      if(n < target){
    80000270:	0009871b          	sext.w	a4,s3
    80000274:	fb677ce3          	bgeu	a4,s6,8000022c <consoleread+0xbc>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	64f72823          	sw	a5,1616(a4) # 800118c8 <cons+0x98>
    80000280:	b775                	j	8000022c <consoleread+0xbc>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	560080e7          	jalr	1376(ra) # 800007f2 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	54e080e7          	jalr	1358(ra) # 800007f2 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	542080e7          	jalr	1346(ra) # 800007f2 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	538080e7          	jalr	1336(ra) # 800007f2 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	55e50513          	addi	a0,a0,1374 # 80011830 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	926080e7          	jalr	-1754(ra) # 80000c00 <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	3c4080e7          	jalr	964(ra) # 800026bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	53050513          	addi	a0,a0,1328 # 80011830 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	9ac080e7          	jalr	-1620(ra) # 80000cb4 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	50c70713          	addi	a4,a4,1292 # 80011830 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	4e278793          	addi	a5,a5,1250 # 80011830 <cons>
    80000356:	0a07a703          	lw	a4,160(a5)
    8000035a:	0017069b          	addiw	a3,a4,1
    8000035e:	0006861b          	sext.w	a2,a3
    80000362:	0ad7a023          	sw	a3,160(a5)
    80000366:	07f77713          	andi	a4,a4,127
    8000036a:	97ba                	add	a5,a5,a4
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	54c7a783          	lw	a5,1356(a5) # 800118c8 <cons+0x98>
    80000384:	0807879b          	addiw	a5,a5,128
    80000388:	f6f61ce3          	bne	a2,a5,80000300 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038c:	863e                	mv	a2,a5
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	4a070713          	addi	a4,a4,1184 # 80011830 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	49048493          	addi	s1,s1,1168 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	45470713          	addi	a4,a4,1108 # 80011830 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	4cf72f23          	sw	a5,1246(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	41878793          	addi	a5,a5,1048 # 80011830 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	48c7a823          	sw	a2,1168(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	48450513          	addi	a0,a0,1156 # 800118c8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	0ea080e7          	jalr	234(ra) # 80002536 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	3ca50513          	addi	a0,a0,970 # 80011830 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	702080e7          	jalr	1794(ra) # 80000b70 <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	32c080e7          	jalr	812(ra) # 800007a2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	93278793          	addi	a5,a5,-1742 # 80021db0 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cea70713          	addi	a4,a4,-790 # 80000170 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c5c70713          	addi	a4,a4,-932 # 800000ec <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054763          	bltz	a0,8000053e <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088c63          	beqz	a7,80000504 <printint+0x62>
    buf[i++] = '-';
    800004f0:	fe070793          	addi	a5,a4,-32
    800004f4:	00878733          	add	a4,a5,s0
    800004f8:	02d00793          	li	a5,45
    800004fc:	fef70823          	sb	a5,-16(a4)
    80000500:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000504:	02e05763          	blez	a4,80000532 <printint+0x90>
    80000508:	fd040793          	addi	a5,s0,-48
    8000050c:	00e784b3          	add	s1,a5,a4
    80000510:	fff78913          	addi	s2,a5,-1
    80000514:	993a                	add	s2,s2,a4
    80000516:	377d                	addiw	a4,a4,-1
    80000518:	1702                	slli	a4,a4,0x20
    8000051a:	9301                	srli	a4,a4,0x20
    8000051c:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000520:	fff4c503          	lbu	a0,-1(s1)
    80000524:	00000097          	auipc	ra,0x0
    80000528:	d5e080e7          	jalr	-674(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052c:	14fd                	addi	s1,s1,-1
    8000052e:	ff2499e3          	bne	s1,s2,80000520 <printint+0x7e>
}
    80000532:	70a2                	ld	ra,40(sp)
    80000534:	7402                	ld	s0,32(sp)
    80000536:	64e2                	ld	s1,24(sp)
    80000538:	6942                	ld	s2,16(sp)
    8000053a:	6145                	addi	sp,sp,48
    8000053c:	8082                	ret
    x = -xx;
    8000053e:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000542:	4885                	li	a7,1
    x = -xx;
    80000544:	bf95                	j	800004b8 <printint+0x16>

0000000080000546 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000546:	1101                	addi	sp,sp,-32
    80000548:	ec06                	sd	ra,24(sp)
    8000054a:	e822                	sd	s0,16(sp)
    8000054c:	e426                	sd	s1,8(sp)
    8000054e:	1000                	addi	s0,sp,32
    80000550:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000552:	00011797          	auipc	a5,0x11
    80000556:	3807af23          	sw	zero,926(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055a:	00008517          	auipc	a0,0x8
    8000055e:	abe50513          	addi	a0,a0,-1346 # 80008018 <etext+0x18>
    80000562:	00000097          	auipc	ra,0x0
    80000566:	02e080e7          	jalr	46(ra) # 80000590 <printf>
  printf(s);
    8000056a:	8526                	mv	a0,s1
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	024080e7          	jalr	36(ra) # 80000590 <printf>
  printf("\n");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	b5450513          	addi	a0,a0,-1196 # 800080c8 <digits+0x88>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	014080e7          	jalr	20(ra) # 80000590 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000584:	4785                	li	a5,1
    80000586:	00009717          	auipc	a4,0x9
    8000058a:	a6f72d23          	sw	a5,-1414(a4) # 80009000 <panicked>
  for(;;)
    8000058e:	a001                	j	8000058e <panic+0x48>

0000000080000590 <printf>:
{
    80000590:	7131                	addi	sp,sp,-192
    80000592:	fc86                	sd	ra,120(sp)
    80000594:	f8a2                	sd	s0,112(sp)
    80000596:	f4a6                	sd	s1,104(sp)
    80000598:	f0ca                	sd	s2,96(sp)
    8000059a:	ecce                	sd	s3,88(sp)
    8000059c:	e8d2                	sd	s4,80(sp)
    8000059e:	e4d6                	sd	s5,72(sp)
    800005a0:	e0da                	sd	s6,64(sp)
    800005a2:	fc5e                	sd	s7,56(sp)
    800005a4:	f862                	sd	s8,48(sp)
    800005a6:	f466                	sd	s9,40(sp)
    800005a8:	f06a                	sd	s10,32(sp)
    800005aa:	ec6e                	sd	s11,24(sp)
    800005ac:	0100                	addi	s0,sp,128
    800005ae:	8a2a                	mv	s4,a0
    800005b0:	e40c                	sd	a1,8(s0)
    800005b2:	e810                	sd	a2,16(s0)
    800005b4:	ec14                	sd	a3,24(s0)
    800005b6:	f018                	sd	a4,32(s0)
    800005b8:	f41c                	sd	a5,40(s0)
    800005ba:	03043823          	sd	a6,48(s0)
    800005be:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c2:	00011d97          	auipc	s11,0x11
    800005c6:	32edad83          	lw	s11,814(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005ca:	020d9b63          	bnez	s11,80000600 <printf+0x70>
  if (fmt == 0)
    800005ce:	040a0263          	beqz	s4,80000612 <printf+0x82>
  va_start(ap, fmt);
    800005d2:	00840793          	addi	a5,s0,8
    800005d6:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005da:	000a4503          	lbu	a0,0(s4)
    800005de:	14050f63          	beqz	a0,8000073c <printf+0x1ac>
    800005e2:	4981                	li	s3,0
    if(c != '%'){
    800005e4:	02500a93          	li	s5,37
    switch(c){
    800005e8:	07000b93          	li	s7,112
  consputc('x');
    800005ec:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ee:	00008b17          	auipc	s6,0x8
    800005f2:	a52b0b13          	addi	s6,s6,-1454 # 80008040 <digits>
    switch(c){
    800005f6:	07300c93          	li	s9,115
    800005fa:	06400c13          	li	s8,100
    800005fe:	a82d                	j	80000638 <printf+0xa8>
    acquire(&pr.lock);
    80000600:	00011517          	auipc	a0,0x11
    80000604:	2d850513          	addi	a0,a0,728 # 800118d8 <pr>
    80000608:	00000097          	auipc	ra,0x0
    8000060c:	5f8080e7          	jalr	1528(ra) # 80000c00 <acquire>
    80000610:	bf7d                	j	800005ce <printf+0x3e>
    panic("null fmt");
    80000612:	00008517          	auipc	a0,0x8
    80000616:	a1650513          	addi	a0,a0,-1514 # 80008028 <etext+0x28>
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	f2c080e7          	jalr	-212(ra) # 80000546 <panic>
      consputc(c);
    80000622:	00000097          	auipc	ra,0x0
    80000626:	c60080e7          	jalr	-928(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062a:	2985                	addiw	s3,s3,1
    8000062c:	013a07b3          	add	a5,s4,s3
    80000630:	0007c503          	lbu	a0,0(a5)
    80000634:	10050463          	beqz	a0,8000073c <printf+0x1ac>
    if(c != '%'){
    80000638:	ff5515e3          	bne	a0,s5,80000622 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063c:	2985                	addiw	s3,s3,1
    8000063e:	013a07b3          	add	a5,s4,s3
    80000642:	0007c783          	lbu	a5,0(a5)
    80000646:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000064a:	cbed                	beqz	a5,8000073c <printf+0x1ac>
    switch(c){
    8000064c:	05778a63          	beq	a5,s7,800006a0 <printf+0x110>
    80000650:	02fbf663          	bgeu	s7,a5,8000067c <printf+0xec>
    80000654:	09978863          	beq	a5,s9,800006e4 <printf+0x154>
    80000658:	07800713          	li	a4,120
    8000065c:	0ce79563          	bne	a5,a4,80000726 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	85ea                	mv	a1,s10
    80000670:	4388                	lw	a0,0(a5)
    80000672:	00000097          	auipc	ra,0x0
    80000676:	e30080e7          	jalr	-464(ra) # 800004a2 <printint>
      break;
    8000067a:	bf45                	j	8000062a <printf+0x9a>
    switch(c){
    8000067c:	09578f63          	beq	a5,s5,8000071a <printf+0x18a>
    80000680:	0b879363          	bne	a5,s8,80000726 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	4605                	li	a2,1
    80000692:	45a9                	li	a1,10
    80000694:	4388                	lw	a0,0(a5)
    80000696:	00000097          	auipc	ra,0x0
    8000069a:	e0c080e7          	jalr	-500(ra) # 800004a2 <printint>
      break;
    8000069e:	b771                	j	8000062a <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a0:	f8843783          	ld	a5,-120(s0)
    800006a4:	00878713          	addi	a4,a5,8
    800006a8:	f8e43423          	sd	a4,-120(s0)
    800006ac:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b0:	03000513          	li	a0,48
    800006b4:	00000097          	auipc	ra,0x0
    800006b8:	bce080e7          	jalr	-1074(ra) # 80000282 <consputc>
  consputc('x');
    800006bc:	07800513          	li	a0,120
    800006c0:	00000097          	auipc	ra,0x0
    800006c4:	bc2080e7          	jalr	-1086(ra) # 80000282 <consputc>
    800006c8:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ca:	03c95793          	srli	a5,s2,0x3c
    800006ce:	97da                	add	a5,a5,s6
    800006d0:	0007c503          	lbu	a0,0(a5)
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	bae080e7          	jalr	-1106(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006dc:	0912                	slli	s2,s2,0x4
    800006de:	34fd                	addiw	s1,s1,-1
    800006e0:	f4ed                	bnez	s1,800006ca <printf+0x13a>
    800006e2:	b7a1                	j	8000062a <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	6384                	ld	s1,0(a5)
    800006f2:	cc89                	beqz	s1,8000070c <printf+0x17c>
      for(; *s; s++)
    800006f4:	0004c503          	lbu	a0,0(s1)
    800006f8:	d90d                	beqz	a0,8000062a <printf+0x9a>
        consputc(*s);
    800006fa:	00000097          	auipc	ra,0x0
    800006fe:	b88080e7          	jalr	-1144(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000702:	0485                	addi	s1,s1,1
    80000704:	0004c503          	lbu	a0,0(s1)
    80000708:	f96d                	bnez	a0,800006fa <printf+0x16a>
    8000070a:	b705                	j	8000062a <printf+0x9a>
        s = "(null)";
    8000070c:	00008497          	auipc	s1,0x8
    80000710:	91448493          	addi	s1,s1,-1772 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000714:	02800513          	li	a0,40
    80000718:	b7cd                	j	800006fa <printf+0x16a>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b66080e7          	jalr	-1178(ra) # 80000282 <consputc>
      break;
    80000724:	b719                	j	8000062a <printf+0x9a>
      consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b5a080e7          	jalr	-1190(ra) # 80000282 <consputc>
      consputc(c);
    80000730:	8526                	mv	a0,s1
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b50080e7          	jalr	-1200(ra) # 80000282 <consputc>
      break;
    8000073a:	bdc5                	j	8000062a <printf+0x9a>
  if(locking)
    8000073c:	020d9163          	bnez	s11,8000075e <printf+0x1ce>
}
    80000740:	70e6                	ld	ra,120(sp)
    80000742:	7446                	ld	s0,112(sp)
    80000744:	74a6                	ld	s1,104(sp)
    80000746:	7906                	ld	s2,96(sp)
    80000748:	69e6                	ld	s3,88(sp)
    8000074a:	6a46                	ld	s4,80(sp)
    8000074c:	6aa6                	ld	s5,72(sp)
    8000074e:	6b06                	ld	s6,64(sp)
    80000750:	7be2                	ld	s7,56(sp)
    80000752:	7c42                	ld	s8,48(sp)
    80000754:	7ca2                	ld	s9,40(sp)
    80000756:	7d02                	ld	s10,32(sp)
    80000758:	6de2                	ld	s11,24(sp)
    8000075a:	6129                	addi	sp,sp,192
    8000075c:	8082                	ret
    release(&pr.lock);
    8000075e:	00011517          	auipc	a0,0x11
    80000762:	17a50513          	addi	a0,a0,378 # 800118d8 <pr>
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	54e080e7          	jalr	1358(ra) # 80000cb4 <release>
}
    8000076e:	bfc9                	j	80000740 <printf+0x1b0>

0000000080000770 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000770:	1101                	addi	sp,sp,-32
    80000772:	ec06                	sd	ra,24(sp)
    80000774:	e822                	sd	s0,16(sp)
    80000776:	e426                	sd	s1,8(sp)
    80000778:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077a:	00011497          	auipc	s1,0x11
    8000077e:	15e48493          	addi	s1,s1,350 # 800118d8 <pr>
    80000782:	00008597          	auipc	a1,0x8
    80000786:	8b658593          	addi	a1,a1,-1866 # 80008038 <etext+0x38>
    8000078a:	8526                	mv	a0,s1
    8000078c:	00000097          	auipc	ra,0x0
    80000790:	3e4080e7          	jalr	996(ra) # 80000b70 <initlock>
  pr.locking = 1;
    80000794:	4785                	li	a5,1
    80000796:	cc9c                	sw	a5,24(s1)
}
    80000798:	60e2                	ld	ra,24(sp)
    8000079a:	6442                	ld	s0,16(sp)
    8000079c:	64a2                	ld	s1,8(sp)
    8000079e:	6105                	addi	sp,sp,32
    800007a0:	8082                	ret

00000000800007a2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a2:	1141                	addi	sp,sp,-16
    800007a4:	e406                	sd	ra,8(sp)
    800007a6:	e022                	sd	s0,0(sp)
    800007a8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007aa:	100007b7          	lui	a5,0x10000
    800007ae:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b2:	f8000713          	li	a4,-128
    800007b6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ba:	470d                	li	a4,3
    800007bc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c8:	469d                	li	a3,7
    800007ca:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ce:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d2:	00008597          	auipc	a1,0x8
    800007d6:	88658593          	addi	a1,a1,-1914 # 80008058 <digits+0x18>
    800007da:	00011517          	auipc	a0,0x11
    800007de:	11e50513          	addi	a0,a0,286 # 800118f8 <uart_tx_lock>
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	38e080e7          	jalr	910(ra) # 80000b70 <initlock>
}
    800007ea:	60a2                	ld	ra,8(sp)
    800007ec:	6402                	ld	s0,0(sp)
    800007ee:	0141                	addi	sp,sp,16
    800007f0:	8082                	ret

00000000800007f2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f2:	1101                	addi	sp,sp,-32
    800007f4:	ec06                	sd	ra,24(sp)
    800007f6:	e822                	sd	s0,16(sp)
    800007f8:	e426                	sd	s1,8(sp)
    800007fa:	1000                	addi	s0,sp,32
    800007fc:	84aa                	mv	s1,a0
  push_off();
    800007fe:	00000097          	auipc	ra,0x0
    80000802:	3b6080e7          	jalr	950(ra) # 80000bb4 <push_off>

  if(panicked){
    80000806:	00008797          	auipc	a5,0x8
    8000080a:	7fa7a783          	lw	a5,2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000812:	c391                	beqz	a5,80000816 <uartputc_sync+0x24>
    for(;;)
    80000814:	a001                	j	80000814 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081a:	0207f793          	andi	a5,a5,32
    8000081e:	dfe5                	beqz	a5,80000816 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000820:	0ff4f513          	zext.b	a0,s1
    80000824:	100007b7          	lui	a5,0x10000
    80000828:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082c:	00000097          	auipc	ra,0x0
    80000830:	428080e7          	jalr	1064(ra) # 80000c54 <pop_off>
}
    80000834:	60e2                	ld	ra,24(sp)
    80000836:	6442                	ld	s0,16(sp)
    80000838:	64a2                	ld	s1,8(sp)
    8000083a:	6105                	addi	sp,sp,32
    8000083c:	8082                	ret

000000008000083e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083e:	00008797          	auipc	a5,0x8
    80000842:	7c67a783          	lw	a5,1990(a5) # 80009004 <uart_tx_r>
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	7c272703          	lw	a4,1986(a4) # 80009008 <uart_tx_w>
    8000084e:	08f70063          	beq	a4,a5,800008ce <uartstart+0x90>
{
    80000852:	7139                	addi	sp,sp,-64
    80000854:	fc06                	sd	ra,56(sp)
    80000856:	f822                	sd	s0,48(sp)
    80000858:	f426                	sd	s1,40(sp)
    8000085a:	f04a                	sd	s2,32(sp)
    8000085c:	ec4e                	sd	s3,24(sp)
    8000085e:	e852                	sd	s4,16(sp)
    80000860:	e456                	sd	s5,8(sp)
    80000862:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000868:	00011a97          	auipc	s5,0x11
    8000086c:	090a8a93          	addi	s5,s5,144 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000870:	00008497          	auipc	s1,0x8
    80000874:	79448493          	addi	s1,s1,1940 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000878:	00008a17          	auipc	s4,0x8
    8000087c:	790a0a13          	addi	s4,s4,1936 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000880:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000884:	02077713          	andi	a4,a4,32
    80000888:	cb15                	beqz	a4,800008bc <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    8000088a:	00fa8733          	add	a4,s5,a5
    8000088e:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000892:	2785                	addiw	a5,a5,1
    80000894:	41f7d71b          	sraiw	a4,a5,0x1f
    80000898:	01b7571b          	srliw	a4,a4,0x1b
    8000089c:	9fb9                	addw	a5,a5,a4
    8000089e:	8bfd                	andi	a5,a5,31
    800008a0:	9f99                	subw	a5,a5,a4
    800008a2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	c90080e7          	jalr	-880(ra) # 80002536 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	409c                	lw	a5,0(s1)
    800008b4:	000a2703          	lw	a4,0(s4)
    800008b8:	fcf714e3          	bne	a4,a5,80000880 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008e2:	00011517          	auipc	a0,0x11
    800008e6:	01650513          	addi	a0,a0,22 # 800118f8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	316080e7          	jalr	790(ra) # 80000c00 <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	70e7a783          	lw	a5,1806(a5) # 80009000 <panicked>
    800008fa:	c391                	beqz	a5,800008fe <uartputc+0x2e>
    for(;;)
    800008fc:	a001                	j	800008fc <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fe:	00008697          	auipc	a3,0x8
    80000902:	70a6a683          	lw	a3,1802(a3) # 80009008 <uart_tx_w>
    80000906:	0016879b          	addiw	a5,a3,1
    8000090a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090e:	01b7571b          	srliw	a4,a4,0x1b
    80000912:	9fb9                	addw	a5,a5,a4
    80000914:	8bfd                	andi	a5,a5,31
    80000916:	9f99                	subw	a5,a5,a4
    80000918:	00008717          	auipc	a4,0x8
    8000091c:	6ec72703          	lw	a4,1772(a4) # 80009004 <uart_tx_r>
    80000920:	04f71363          	bne	a4,a5,80000966 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000924:	00011a17          	auipc	s4,0x11
    80000928:	fd4a0a13          	addi	s4,s4,-44 # 800118f8 <uart_tx_lock>
    8000092c:	00008917          	auipc	s2,0x8
    80000930:	6d890913          	addi	s2,s2,1752 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000934:	00008997          	auipc	s3,0x8
    80000938:	6d498993          	addi	s3,s3,1748 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	85d2                	mv	a1,s4
    8000093e:	854a                	mv	a0,s2
    80000940:	00002097          	auipc	ra,0x2
    80000944:	a76080e7          	jalr	-1418(ra) # 800023b6 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000948:	0009a683          	lw	a3,0(s3)
    8000094c:	0016879b          	addiw	a5,a3,1
    80000950:	41f7d71b          	sraiw	a4,a5,0x1f
    80000954:	01b7571b          	srliw	a4,a4,0x1b
    80000958:	9fb9                	addw	a5,a5,a4
    8000095a:	8bfd                	andi	a5,a5,31
    8000095c:	9f99                	subw	a5,a5,a4
    8000095e:	00092703          	lw	a4,0(s2)
    80000962:	fcf70de3          	beq	a4,a5,8000093c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000966:	00011917          	auipc	s2,0x11
    8000096a:	f9290913          	addi	s2,s2,-110 # 800118f8 <uart_tx_lock>
    8000096e:	96ca                	add	a3,a3,s2
    80000970:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000974:	00008717          	auipc	a4,0x8
    80000978:	68f72a23          	sw	a5,1684(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000097c:	00000097          	auipc	ra,0x0
    80000980:	ec2080e7          	jalr	-318(ra) # 8000083e <uartstart>
      release(&uart_tx_lock);
    80000984:	854a                	mv	a0,s2
    80000986:	00000097          	auipc	ra,0x0
    8000098a:	32e080e7          	jalr	814(ra) # 80000cb4 <release>
}
    8000098e:	70a2                	ld	ra,40(sp)
    80000990:	7402                	ld	s0,32(sp)
    80000992:	64e2                	ld	s1,24(sp)
    80000994:	6942                	ld	s2,16(sp)
    80000996:	69a2                	ld	s3,8(sp)
    80000998:	6a02                	ld	s4,0(sp)
    8000099a:	6145                	addi	sp,sp,48
    8000099c:	8082                	ret

000000008000099e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099e:	1141                	addi	sp,sp,-16
    800009a0:	e422                	sd	s0,8(sp)
    800009a2:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a4:	100007b7          	lui	a5,0x10000
    800009a8:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ac:	8b85                	andi	a5,a5,1
    800009ae:	cb81                	beqz	a5,800009be <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009b0:	100007b7          	lui	a5,0x10000
    800009b4:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1a>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f4080e7          	jalr	-1804(ra) # 800002c4 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc6080e7          	jalr	-58(ra) # 8000099e <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	212080e7          	jalr	530(ra) # 80000c00 <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e48080e7          	jalr	-440(ra) # 8000083e <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b4080e7          	jalr	692(ra) # 80000cb4 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00026797          	auipc	a5,0x26
    80000a2a:	5fa78793          	addi	a5,a5,1530 # 80027020 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2be080e7          	jalr	702(ra) # 80000cfc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1b0080e7          	jalr	432(ra) # 80000c00 <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	250080e7          	jalr	592(ra) # 80000cb4 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac6080e7          	jalr	-1338(ra) # 80000546 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	00e504b3          	add	s1,a0,a4
    80000aa2:	777d                	lui	a4,0xfffff
    80000aa4:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa6:	94be                	add	s1,s1,a5
    80000aa8:	0095ee63          	bltu	a1,s1,80000ac4 <freerange+0x3c>
    80000aac:	892e                	mv	s2,a1
    kfree(p);
    80000aae:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab0:	6985                	lui	s3,0x1
    kfree(p);
    80000ab2:	01448533          	add	a0,s1,s4
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	f5c080e7          	jalr	-164(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abe:	94ce                	add	s1,s1,s3
    80000ac0:	fe9979e3          	bgeu	s2,s1,80000ab2 <freerange+0x2a>
}
    80000ac4:	70a2                	ld	ra,40(sp)
    80000ac6:	7402                	ld	s0,32(sp)
    80000ac8:	64e2                	ld	s1,24(sp)
    80000aca:	6942                	ld	s2,16(sp)
    80000acc:	69a2                	ld	s3,8(sp)
    80000ace:	6a02                	ld	s4,0(sp)
    80000ad0:	6145                	addi	sp,sp,48
    80000ad2:	8082                	ret

0000000080000ad4 <kinit>:
{
    80000ad4:	1141                	addi	sp,sp,-16
    80000ad6:	e406                	sd	ra,8(sp)
    80000ad8:	e022                	sd	s0,0(sp)
    80000ada:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000adc:	00007597          	auipc	a1,0x7
    80000ae0:	58c58593          	addi	a1,a1,1420 # 80008068 <digits+0x28>
    80000ae4:	00011517          	auipc	a0,0x11
    80000ae8:	e4c50513          	addi	a0,a0,-436 # 80011930 <kmem>
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	084080e7          	jalr	132(ra) # 80000b70 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af4:	45c5                	li	a1,17
    80000af6:	05ee                	slli	a1,a1,0x1b
    80000af8:	00026517          	auipc	a0,0x26
    80000afc:	52850513          	addi	a0,a0,1320 # 80027020 <end>
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	f88080e7          	jalr	-120(ra) # 80000a88 <freerange>
}
    80000b08:	60a2                	ld	ra,8(sp)
    80000b0a:	6402                	ld	s0,0(sp)
    80000b0c:	0141                	addi	sp,sp,16
    80000b0e:	8082                	ret

0000000080000b10 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b10:	1101                	addi	sp,sp,-32
    80000b12:	ec06                	sd	ra,24(sp)
    80000b14:	e822                	sd	s0,16(sp)
    80000b16:	e426                	sd	s1,8(sp)
    80000b18:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b1a:	00011497          	auipc	s1,0x11
    80000b1e:	e1648493          	addi	s1,s1,-490 # 80011930 <kmem>
    80000b22:	8526                	mv	a0,s1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	0dc080e7          	jalr	220(ra) # 80000c00 <acquire>
  r = kmem.freelist;
    80000b2c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2e:	c885                	beqz	s1,80000b5e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b30:	609c                	ld	a5,0(s1)
    80000b32:	00011517          	auipc	a0,0x11
    80000b36:	dfe50513          	addi	a0,a0,-514 # 80011930 <kmem>
    80000b3a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	178080e7          	jalr	376(ra) # 80000cb4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b44:	6605                	lui	a2,0x1
    80000b46:	4595                	li	a1,5
    80000b48:	8526                	mv	a0,s1
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	1b2080e7          	jalr	434(ra) # 80000cfc <memset>
  return (void*)r;
}
    80000b52:	8526                	mv	a0,s1
    80000b54:	60e2                	ld	ra,24(sp)
    80000b56:	6442                	ld	s0,16(sp)
    80000b58:	64a2                	ld	s1,8(sp)
    80000b5a:	6105                	addi	sp,sp,32
    80000b5c:	8082                	ret
  release(&kmem.lock);
    80000b5e:	00011517          	auipc	a0,0x11
    80000b62:	dd250513          	addi	a0,a0,-558 # 80011930 <kmem>
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	14e080e7          	jalr	334(ra) # 80000cb4 <release>
  if(r)
    80000b6e:	b7d5                	j	80000b52 <kalloc+0x42>

0000000080000b70 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b70:	1141                	addi	sp,sp,-16
    80000b72:	e422                	sd	s0,8(sp)
    80000b74:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b76:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b78:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7c:	00053823          	sd	zero,16(a0)
}
    80000b80:	6422                	ld	s0,8(sp)
    80000b82:	0141                	addi	sp,sp,16
    80000b84:	8082                	ret

0000000080000b86 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b86:	411c                	lw	a5,0(a0)
    80000b88:	e399                	bnez	a5,80000b8e <holding+0x8>
    80000b8a:	4501                	li	a0,0
  return r;
}
    80000b8c:	8082                	ret
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b98:	6904                	ld	s1,16(a0)
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	f4a080e7          	jalr	-182(ra) # 80001ae4 <mycpu>
    80000ba2:	40a48533          	sub	a0,s1,a0
    80000ba6:	00153513          	seqz	a0,a0
}
    80000baa:	60e2                	ld	ra,24(sp)
    80000bac:	6442                	ld	s0,16(sp)
    80000bae:	64a2                	ld	s1,8(sp)
    80000bb0:	6105                	addi	sp,sp,32
    80000bb2:	8082                	ret

0000000080000bb4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb4:	1101                	addi	sp,sp,-32
    80000bb6:	ec06                	sd	ra,24(sp)
    80000bb8:	e822                	sd	s0,16(sp)
    80000bba:	e426                	sd	s1,8(sp)
    80000bbc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbe:	100024f3          	csrr	s1,sstatus
    80000bc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bcc:	00001097          	auipc	ra,0x1
    80000bd0:	f18080e7          	jalr	-232(ra) # 80001ae4 <mycpu>
    80000bd4:	5d3c                	lw	a5,120(a0)
    80000bd6:	cf89                	beqz	a5,80000bf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	f0c080e7          	jalr	-244(ra) # 80001ae4 <mycpu>
    80000be0:	5d3c                	lw	a5,120(a0)
    80000be2:	2785                	addiw	a5,a5,1
    80000be4:	dd3c                	sw	a5,120(a0)
}
    80000be6:	60e2                	ld	ra,24(sp)
    80000be8:	6442                	ld	s0,16(sp)
    80000bea:	64a2                	ld	s1,8(sp)
    80000bec:	6105                	addi	sp,sp,32
    80000bee:	8082                	ret
    mycpu()->intena = old;
    80000bf0:	00001097          	auipc	ra,0x1
    80000bf4:	ef4080e7          	jalr	-268(ra) # 80001ae4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf8:	8085                	srli	s1,s1,0x1
    80000bfa:	8885                	andi	s1,s1,1
    80000bfc:	dd64                	sw	s1,124(a0)
    80000bfe:	bfe9                	j	80000bd8 <push_off+0x24>

0000000080000c00 <acquire>:
{
    80000c00:	1101                	addi	sp,sp,-32
    80000c02:	ec06                	sd	ra,24(sp)
    80000c04:	e822                	sd	s0,16(sp)
    80000c06:	e426                	sd	s1,8(sp)
    80000c08:	1000                	addi	s0,sp,32
    80000c0a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	fa8080e7          	jalr	-88(ra) # 80000bb4 <push_off>
  if(holding(lk))
    80000c14:	8526                	mv	a0,s1
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	f70080e7          	jalr	-144(ra) # 80000b86 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	4705                	li	a4,1
  if(holding(lk))
    80000c20:	e115                	bnez	a0,80000c44 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c22:	87ba                	mv	a5,a4
    80000c24:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c28:	2781                	sext.w	a5,a5
    80000c2a:	ffe5                	bnez	a5,80000c22 <acquire+0x22>
  __sync_synchronize();
    80000c2c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c30:	00001097          	auipc	ra,0x1
    80000c34:	eb4080e7          	jalr	-332(ra) # 80001ae4 <mycpu>
    80000c38:	e888                	sd	a0,16(s1)
}
    80000c3a:	60e2                	ld	ra,24(sp)
    80000c3c:	6442                	ld	s0,16(sp)
    80000c3e:	64a2                	ld	s1,8(sp)
    80000c40:	6105                	addi	sp,sp,32
    80000c42:	8082                	ret
    panic("acquire");
    80000c44:	00007517          	auipc	a0,0x7
    80000c48:	42c50513          	addi	a0,a0,1068 # 80008070 <digits+0x30>
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	8fa080e7          	jalr	-1798(ra) # 80000546 <panic>

0000000080000c54 <pop_off>:

void
pop_off(void)
{
    80000c54:	1141                	addi	sp,sp,-16
    80000c56:	e406                	sd	ra,8(sp)
    80000c58:	e022                	sd	s0,0(sp)
    80000c5a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5c:	00001097          	auipc	ra,0x1
    80000c60:	e88080e7          	jalr	-376(ra) # 80001ae4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c68:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c6a:	e78d                	bnez	a5,80000c94 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6c:	5d3c                	lw	a5,120(a0)
    80000c6e:	02f05b63          	blez	a5,80000ca4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c72:	37fd                	addiw	a5,a5,-1
    80000c74:	0007871b          	sext.w	a4,a5
    80000c78:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c7a:	eb09                	bnez	a4,80000c8c <pop_off+0x38>
    80000c7c:	5d7c                	lw	a5,124(a0)
    80000c7e:	c799                	beqz	a5,80000c8c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c88:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8c:	60a2                	ld	ra,8(sp)
    80000c8e:	6402                	ld	s0,0(sp)
    80000c90:	0141                	addi	sp,sp,16
    80000c92:	8082                	ret
    panic("pop_off - interruptible");
    80000c94:	00007517          	auipc	a0,0x7
    80000c98:	3e450513          	addi	a0,a0,996 # 80008078 <digits+0x38>
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	8aa080e7          	jalr	-1878(ra) # 80000546 <panic>
    panic("pop_off");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3ec50513          	addi	a0,a0,1004 # 80008090 <digits+0x50>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89a080e7          	jalr	-1894(ra) # 80000546 <panic>

0000000080000cb4 <release>:
{
    80000cb4:	1101                	addi	sp,sp,-32
    80000cb6:	ec06                	sd	ra,24(sp)
    80000cb8:	e822                	sd	s0,16(sp)
    80000cba:	e426                	sd	s1,8(sp)
    80000cbc:	1000                	addi	s0,sp,32
    80000cbe:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	ec6080e7          	jalr	-314(ra) # 80000b86 <holding>
    80000cc8:	c115                	beqz	a0,80000cec <release+0x38>
  lk->cpu = 0;
    80000cca:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cce:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd2:	0f50000f          	fence	iorw,ow
    80000cd6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	f7a080e7          	jalr	-134(ra) # 80000c54 <pop_off>
}
    80000ce2:	60e2                	ld	ra,24(sp)
    80000ce4:	6442                	ld	s0,16(sp)
    80000ce6:	64a2                	ld	s1,8(sp)
    80000ce8:	6105                	addi	sp,sp,32
    80000cea:	8082                	ret
    panic("release");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3ac50513          	addi	a0,a0,940 # 80008098 <digits+0x58>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	852080e7          	jalr	-1966(ra) # 80000546 <panic>

0000000080000cfc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfc:	1141                	addi	sp,sp,-16
    80000cfe:	e422                	sd	s0,8(sp)
    80000d00:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d02:	ca19                	beqz	a2,80000d18 <memset+0x1c>
    80000d04:	87aa                	mv	a5,a0
    80000d06:	1602                	slli	a2,a2,0x20
    80000d08:	9201                	srli	a2,a2,0x20
    80000d0a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d12:	0785                	addi	a5,a5,1
    80000d14:	fee79de3          	bne	a5,a4,80000d0e <memset+0x12>
  }
  return dst;
}
    80000d18:	6422                	ld	s0,8(sp)
    80000d1a:	0141                	addi	sp,sp,16
    80000d1c:	8082                	ret

0000000080000d1e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1e:	1141                	addi	sp,sp,-16
    80000d20:	e422                	sd	s0,8(sp)
    80000d22:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d24:	ca05                	beqz	a2,80000d54 <memcmp+0x36>
    80000d26:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d32:	00054783          	lbu	a5,0(a0)
    80000d36:	0005c703          	lbu	a4,0(a1)
    80000d3a:	00e79863          	bne	a5,a4,80000d4a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3e:	0505                	addi	a0,a0,1
    80000d40:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d42:	fed518e3          	bne	a0,a3,80000d32 <memcmp+0x14>
  }

  return 0;
    80000d46:	4501                	li	a0,0
    80000d48:	a019                	j	80000d4e <memcmp+0x30>
      return *s1 - *s2;
    80000d4a:	40e7853b          	subw	a0,a5,a4
}
    80000d4e:	6422                	ld	s0,8(sp)
    80000d50:	0141                	addi	sp,sp,16
    80000d52:	8082                	ret
  return 0;
    80000d54:	4501                	li	a0,0
    80000d56:	bfe5                	j	80000d4e <memcmp+0x30>

0000000080000d58 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d58:	1141                	addi	sp,sp,-16
    80000d5a:	e422                	sd	s0,8(sp)
    80000d5c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5e:	02a5e563          	bltu	a1,a0,80000d88 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d62:	fff6069b          	addiw	a3,a2,-1
    80000d66:	ce11                	beqz	a2,80000d82 <memmove+0x2a>
    80000d68:	1682                	slli	a3,a3,0x20
    80000d6a:	9281                	srli	a3,a3,0x20
    80000d6c:	0685                	addi	a3,a3,1
    80000d6e:	96ae                	add	a3,a3,a1
    80000d70:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d72:	0585                	addi	a1,a1,1
    80000d74:	0785                	addi	a5,a5,1
    80000d76:	fff5c703          	lbu	a4,-1(a1)
    80000d7a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7e:	fed59ae3          	bne	a1,a3,80000d72 <memmove+0x1a>

  return dst;
}
    80000d82:	6422                	ld	s0,8(sp)
    80000d84:	0141                	addi	sp,sp,16
    80000d86:	8082                	ret
  if(s < d && s + n > d){
    80000d88:	02061713          	slli	a4,a2,0x20
    80000d8c:	9301                	srli	a4,a4,0x20
    80000d8e:	00e587b3          	add	a5,a1,a4
    80000d92:	fcf578e3          	bgeu	a0,a5,80000d62 <memmove+0xa>
    d += n;
    80000d96:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d98:	fff6069b          	addiw	a3,a2,-1
    80000d9c:	d27d                	beqz	a2,80000d82 <memmove+0x2a>
    80000d9e:	02069613          	slli	a2,a3,0x20
    80000da2:	9201                	srli	a2,a2,0x20
    80000da4:	fff64613          	not	a2,a2
    80000da8:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000daa:	17fd                	addi	a5,a5,-1
    80000dac:	177d                	addi	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    80000dae:	0007c683          	lbu	a3,0(a5)
    80000db2:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db6:	fef61ae3          	bne	a2,a5,80000daa <memmove+0x52>
    80000dba:	b7e1                	j	80000d82 <memmove+0x2a>

0000000080000dbc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e406                	sd	ra,8(sp)
    80000dc0:	e022                	sd	s0,0(sp)
    80000dc2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc4:	00000097          	auipc	ra,0x0
    80000dc8:	f94080e7          	jalr	-108(ra) # 80000d58 <memmove>
}
    80000dcc:	60a2                	ld	ra,8(sp)
    80000dce:	6402                	ld	s0,0(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret

0000000080000dd4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e422                	sd	s0,8(sp)
    80000dd8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dda:	ce11                	beqz	a2,80000df6 <strncmp+0x22>
    80000ddc:	00054783          	lbu	a5,0(a0)
    80000de0:	cf89                	beqz	a5,80000dfa <strncmp+0x26>
    80000de2:	0005c703          	lbu	a4,0(a1)
    80000de6:	00f71a63          	bne	a4,a5,80000dfa <strncmp+0x26>
    n--, p++, q++;
    80000dea:	367d                	addiw	a2,a2,-1
    80000dec:	0505                	addi	a0,a0,1
    80000dee:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000df0:	f675                	bnez	a2,80000ddc <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	a809                	j	80000e06 <strncmp+0x32>
    80000df6:	4501                	li	a0,0
    80000df8:	a039                	j	80000e06 <strncmp+0x32>
  if(n == 0)
    80000dfa:	ca09                	beqz	a2,80000e0c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfc:	00054503          	lbu	a0,0(a0)
    80000e00:	0005c783          	lbu	a5,0(a1)
    80000e04:	9d1d                	subw	a0,a0,a5
}
    80000e06:	6422                	ld	s0,8(sp)
    80000e08:	0141                	addi	sp,sp,16
    80000e0a:	8082                	ret
    return 0;
    80000e0c:	4501                	li	a0,0
    80000e0e:	bfe5                	j	80000e06 <strncmp+0x32>

0000000080000e10 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e16:	872a                	mv	a4,a0
    80000e18:	8832                	mv	a6,a2
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	01005963          	blez	a6,80000e2e <strncpy+0x1e>
    80000e20:	0705                	addi	a4,a4,1
    80000e22:	0005c783          	lbu	a5,0(a1)
    80000e26:	fef70fa3          	sb	a5,-1(a4)
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	f7f5                	bnez	a5,80000e18 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2e:	86ba                	mv	a3,a4
    80000e30:	00c05c63          	blez	a2,80000e48 <strncpy+0x38>
    *s++ = 0;
    80000e34:	0685                	addi	a3,a3,1
    80000e36:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e3a:	40d707bb          	subw	a5,a4,a3
    80000e3e:	37fd                	addiw	a5,a5,-1
    80000e40:	010787bb          	addw	a5,a5,a6
    80000e44:	fef048e3          	bgtz	a5,80000e34 <strncpy+0x24>
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e54:	02c05363          	blez	a2,80000e7a <safestrcpy+0x2c>
    80000e58:	fff6069b          	addiw	a3,a2,-1
    80000e5c:	1682                	slli	a3,a3,0x20
    80000e5e:	9281                	srli	a3,a3,0x20
    80000e60:	96ae                	add	a3,a3,a1
    80000e62:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e64:	00d58963          	beq	a1,a3,80000e76 <safestrcpy+0x28>
    80000e68:	0585                	addi	a1,a1,1
    80000e6a:	0785                	addi	a5,a5,1
    80000e6c:	fff5c703          	lbu	a4,-1(a1)
    80000e70:	fee78fa3          	sb	a4,-1(a5)
    80000e74:	fb65                	bnez	a4,80000e64 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e76:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret

0000000080000e80 <strlen>:

int
strlen(const char *s)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e86:	00054783          	lbu	a5,0(a0)
    80000e8a:	cf91                	beqz	a5,80000ea6 <strlen+0x26>
    80000e8c:	0505                	addi	a0,a0,1
    80000e8e:	87aa                	mv	a5,a0
    80000e90:	4685                	li	a3,1
    80000e92:	9e89                	subw	a3,a3,a0
    80000e94:	00f6853b          	addw	a0,a3,a5
    80000e98:	0785                	addi	a5,a5,1
    80000e9a:	fff7c703          	lbu	a4,-1(a5)
    80000e9e:	fb7d                	bnez	a4,80000e94 <strlen+0x14>
    ;
  return n;
}
    80000ea0:	6422                	ld	s0,8(sp)
    80000ea2:	0141                	addi	sp,sp,16
    80000ea4:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea6:	4501                	li	a0,0
    80000ea8:	bfe5                	j	80000ea0 <strlen+0x20>

0000000080000eaa <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000eaa:	1141                	addi	sp,sp,-16
    80000eac:	e406                	sd	ra,8(sp)
    80000eae:	e022                	sd	s0,0(sp)
    80000eb0:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	c22080e7          	jalr	-990(ra) # 80001ad4 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eba:	00008717          	auipc	a4,0x8
    80000ebe:	15270713          	addi	a4,a4,338 # 8000900c <started>
  if(cpuid() == 0){
    80000ec2:	c139                	beqz	a0,80000f08 <main+0x5e>
    while(started == 0)
    80000ec4:	431c                	lw	a5,0(a4)
    80000ec6:	2781                	sext.w	a5,a5
    80000ec8:	dff5                	beqz	a5,80000ec4 <main+0x1a>
      ;
    __sync_synchronize();
    80000eca:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	c06080e7          	jalr	-1018(ra) # 80001ad4 <cpuid>
    80000ed6:	85aa                	mv	a1,a0
    80000ed8:	00007517          	auipc	a0,0x7
    80000edc:	1e050513          	addi	a0,a0,480 # 800080b8 <digits+0x78>
    80000ee0:	fffff097          	auipc	ra,0xfffff
    80000ee4:	6b0080e7          	jalr	1712(ra) # 80000590 <printf>
    kvminithart();    // turn on paging
    80000ee8:	00000097          	auipc	ra,0x0
    80000eec:	0e0080e7          	jalr	224(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef0:	00002097          	auipc	ra,0x2
    80000ef4:	90e080e7          	jalr	-1778(ra) # 800027fe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef8:	00005097          	auipc	ra,0x5
    80000efc:	fc8080e7          	jalr	-56(ra) # 80005ec0 <plicinithart>
  }

  scheduler();        
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	1be080e7          	jalr	446(ra) # 800020be <scheduler>
    consoleinit();
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	54e080e7          	jalr	1358(ra) # 80000456 <consoleinit>
    statsinit();
    80000f10:	00005097          	auipc	ra,0x5
    80000f14:	74e080e7          	jalr	1870(ra) # 8000665e <statsinit>
    printfinit();
    80000f18:	00000097          	auipc	ra,0x0
    80000f1c:	858080e7          	jalr	-1960(ra) # 80000770 <printfinit>
    printf("\n");
    80000f20:	00007517          	auipc	a0,0x7
    80000f24:	1a850513          	addi	a0,a0,424 # 800080c8 <digits+0x88>
    80000f28:	fffff097          	auipc	ra,0xfffff
    80000f2c:	668080e7          	jalr	1640(ra) # 80000590 <printf>
    printf("xv6 kernel is booting\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	17050513          	addi	a0,a0,368 # 800080a0 <digits+0x60>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	658080e7          	jalr	1624(ra) # 80000590 <printf>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	18850513          	addi	a0,a0,392 # 800080c8 <digits+0x88>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	648080e7          	jalr	1608(ra) # 80000590 <printf>
    kinit();         // physical page allocator
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	b84080e7          	jalr	-1148(ra) # 80000ad4 <kinit>
    kvminit();       // create kernel page table
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	2a0080e7          	jalr	672(ra) # 800011f8 <kvminit>
    kvminithart();   // turn on paging
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	068080e7          	jalr	104(ra) # 80000fc8 <kvminithart>
    procinit();      // process table
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	a92080e7          	jalr	-1390(ra) # 800019fa <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	866080e7          	jalr	-1946(ra) # 800027d6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	886080e7          	jalr	-1914(ra) # 800027fe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	f2a080e7          	jalr	-214(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	f38080e7          	jalr	-200(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	fc8080e7          	jalr	-56(ra) # 80002f58 <binit>
    iinit();         // inode cache
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	656080e7          	jalr	1622(ra) # 800035ee <iinit>
    fileinit();      // file table
    80000fa0:	00003097          	auipc	ra,0x3
    80000fa4:	5f8080e7          	jalr	1528(ra) # 80004598 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	01e080e7          	jalr	30(ra) # 80005fc6 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	ea0080e7          	jalr	-352(ra) # 80001e50 <userinit>
    __sync_synchronize();
    80000fb8:	0ff0000f          	fence
    started = 1;
    80000fbc:	4785                	li	a5,1
    80000fbe:	00008717          	auipc	a4,0x8
    80000fc2:	04f72723          	sw	a5,78(a4) # 8000900c <started>
    80000fc6:	bf2d                	j	80000f00 <main+0x56>

0000000080000fc8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc8:	1141                	addi	sp,sp,-16
    80000fca:	e422                	sd	s0,8(sp)
    80000fcc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fce:	00008797          	auipc	a5,0x8
    80000fd2:	0427b783          	ld	a5,66(a5) # 80009010 <kernel_pagetable>
    80000fd6:	83b1                	srli	a5,a5,0xc
    80000fd8:	577d                	li	a4,-1
    80000fda:	177e                	slli	a4,a4,0x3f
    80000fdc:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fde:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fe2:	12000073          	sfence.vma
  sfence_vma();
}
    80000fe6:	6422                	ld	s0,8(sp)
    80000fe8:	0141                	addi	sp,sp,16
    80000fea:	8082                	ret

0000000080000fec <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fec:	7139                	addi	sp,sp,-64
    80000fee:	fc06                	sd	ra,56(sp)
    80000ff0:	f822                	sd	s0,48(sp)
    80000ff2:	f426                	sd	s1,40(sp)
    80000ff4:	f04a                	sd	s2,32(sp)
    80000ff6:	ec4e                	sd	s3,24(sp)
    80000ff8:	e852                	sd	s4,16(sp)
    80000ffa:	e456                	sd	s5,8(sp)
    80000ffc:	e05a                	sd	s6,0(sp)
    80000ffe:	0080                	addi	s0,sp,64
    80001000:	84aa                	mv	s1,a0
    80001002:	89ae                	mv	s3,a1
    80001004:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001006:	57fd                	li	a5,-1
    80001008:	83e9                	srli	a5,a5,0x1a
    8000100a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000100c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000100e:	04b7f263          	bgeu	a5,a1,80001052 <walk+0x66>
    panic("walk");
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0be50513          	addi	a0,a0,190 # 800080d0 <digits+0x90>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	52c080e7          	jalr	1324(ra) # 80000546 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001022:	060a8663          	beqz	s5,8000108e <walk+0xa2>
    80001026:	00000097          	auipc	ra,0x0
    8000102a:	aea080e7          	jalr	-1302(ra) # 80000b10 <kalloc>
    8000102e:	84aa                	mv	s1,a0
    80001030:	c529                	beqz	a0,8000107a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001032:	6605                	lui	a2,0x1
    80001034:	4581                	li	a1,0
    80001036:	00000097          	auipc	ra,0x0
    8000103a:	cc6080e7          	jalr	-826(ra) # 80000cfc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000103e:	00c4d793          	srli	a5,s1,0xc
    80001042:	07aa                	slli	a5,a5,0xa
    80001044:	0017e793          	ori	a5,a5,1
    80001048:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000104c:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd7fd7>
    8000104e:	036a0063          	beq	s4,s6,8000106e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001052:	0149d933          	srl	s2,s3,s4
    80001056:	1ff97913          	andi	s2,s2,511
    8000105a:	090e                	slli	s2,s2,0x3
    8000105c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000105e:	00093483          	ld	s1,0(s2)
    80001062:	0014f793          	andi	a5,s1,1
    80001066:	dfd5                	beqz	a5,80001022 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001068:	80a9                	srli	s1,s1,0xa
    8000106a:	04b2                	slli	s1,s1,0xc
    8000106c:	b7c5                	j	8000104c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000106e:	00c9d513          	srli	a0,s3,0xc
    80001072:	1ff57513          	andi	a0,a0,511
    80001076:	050e                	slli	a0,a0,0x3
    80001078:	9526                	add	a0,a0,s1
}
    8000107a:	70e2                	ld	ra,56(sp)
    8000107c:	7442                	ld	s0,48(sp)
    8000107e:	74a2                	ld	s1,40(sp)
    80001080:	7902                	ld	s2,32(sp)
    80001082:	69e2                	ld	s3,24(sp)
    80001084:	6a42                	ld	s4,16(sp)
    80001086:	6aa2                	ld	s5,8(sp)
    80001088:	6b02                	ld	s6,0(sp)
    8000108a:	6121                	addi	sp,sp,64
    8000108c:	8082                	ret
        return 0;
    8000108e:	4501                	li	a0,0
    80001090:	b7ed                	j	8000107a <walk+0x8e>

0000000080001092 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001092:	57fd                	li	a5,-1
    80001094:	83e9                	srli	a5,a5,0x1a
    80001096:	00b7f463          	bgeu	a5,a1,8000109e <walkaddr+0xc>
    return 0;
    8000109a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000109c:	8082                	ret
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010a6:	4601                	li	a2,0
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	f44080e7          	jalr	-188(ra) # 80000fec <walk>
  if(pte == 0)
    800010b0:	c105                	beqz	a0,800010d0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010b2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010b4:	0117f693          	andi	a3,a5,17
    800010b8:	4745                	li	a4,17
    return 0;
    800010ba:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010bc:	00e68663          	beq	a3,a4,800010c8 <walkaddr+0x36>
}
    800010c0:	60a2                	ld	ra,8(sp)
    800010c2:	6402                	ld	s0,0(sp)
    800010c4:	0141                	addi	sp,sp,16
    800010c6:	8082                	ret
  pa = PTE2PA(*pte);
    800010c8:	83a9                	srli	a5,a5,0xa
    800010ca:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010ce:	bfcd                	j	800010c0 <walkaddr+0x2e>
    return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7fd                	j	800010c0 <walkaddr+0x2e>

00000000800010d4 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010d4:	1101                	addi	sp,sp,-32
    800010d6:	ec06                	sd	ra,24(sp)
    800010d8:	e822                	sd	s0,16(sp)
    800010da:	e426                	sd	s1,8(sp)
    800010dc:	1000                	addi	s0,sp,32
    800010de:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010e0:	1552                	slli	a0,a0,0x34
    800010e2:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010e6:	4601                	li	a2,0
    800010e8:	00008517          	auipc	a0,0x8
    800010ec:	f2853503          	ld	a0,-216(a0) # 80009010 <kernel_pagetable>
    800010f0:	00000097          	auipc	ra,0x0
    800010f4:	efc080e7          	jalr	-260(ra) # 80000fec <walk>
  if(pte == 0)
    800010f8:	cd09                	beqz	a0,80001112 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010fa:	6108                	ld	a0,0(a0)
    800010fc:	00157793          	andi	a5,a0,1
    80001100:	c38d                	beqz	a5,80001122 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001102:	8129                	srli	a0,a0,0xa
    80001104:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001106:	9526                	add	a0,a0,s1
    80001108:	60e2                	ld	ra,24(sp)
    8000110a:	6442                	ld	s0,16(sp)
    8000110c:	64a2                	ld	s1,8(sp)
    8000110e:	6105                	addi	sp,sp,32
    80001110:	8082                	ret
    panic("kvmpa");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fc650513          	addi	a0,a0,-58 # 800080d8 <digits+0x98>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	42c080e7          	jalr	1068(ra) # 80000546 <panic>
    panic("kvmpa");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fb650513          	addi	a0,a0,-74 # 800080d8 <digits+0x98>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	41c080e7          	jalr	1052(ra) # 80000546 <panic>

0000000080001132 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001132:	715d                	addi	sp,sp,-80
    80001134:	e486                	sd	ra,72(sp)
    80001136:	e0a2                	sd	s0,64(sp)
    80001138:	fc26                	sd	s1,56(sp)
    8000113a:	f84a                	sd	s2,48(sp)
    8000113c:	f44e                	sd	s3,40(sp)
    8000113e:	f052                	sd	s4,32(sp)
    80001140:	ec56                	sd	s5,24(sp)
    80001142:	e85a                	sd	s6,16(sp)
    80001144:	e45e                	sd	s7,8(sp)
    80001146:	0880                	addi	s0,sp,80
    80001148:	8aaa                	mv	s5,a0
    8000114a:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000114c:	777d                	lui	a4,0xfffff
    8000114e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001152:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    80001156:	99ae                	add	s3,s3,a1
    80001158:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000115c:	893e                	mv	s2,a5
    8000115e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001162:	6b85                	lui	s7,0x1
    80001164:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001168:	4605                	li	a2,1
    8000116a:	85ca                	mv	a1,s2
    8000116c:	8556                	mv	a0,s5
    8000116e:	00000097          	auipc	ra,0x0
    80001172:	e7e080e7          	jalr	-386(ra) # 80000fec <walk>
    80001176:	c51d                	beqz	a0,800011a4 <mappages+0x72>
    if(*pte & PTE_V)
    80001178:	611c                	ld	a5,0(a0)
    8000117a:	8b85                	andi	a5,a5,1
    8000117c:	ef81                	bnez	a5,80001194 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000117e:	80b1                	srli	s1,s1,0xc
    80001180:	04aa                	slli	s1,s1,0xa
    80001182:	0164e4b3          	or	s1,s1,s6
    80001186:	0014e493          	ori	s1,s1,1
    8000118a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000118c:	03390863          	beq	s2,s3,800011bc <mappages+0x8a>
    a += PGSIZE;
    80001190:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001192:	bfc9                	j	80001164 <mappages+0x32>
      panic("remap");
    80001194:	00007517          	auipc	a0,0x7
    80001198:	f4c50513          	addi	a0,a0,-180 # 800080e0 <digits+0xa0>
    8000119c:	fffff097          	auipc	ra,0xfffff
    800011a0:	3aa080e7          	jalr	938(ra) # 80000546 <panic>
      return -1;
    800011a4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011a6:	60a6                	ld	ra,72(sp)
    800011a8:	6406                	ld	s0,64(sp)
    800011aa:	74e2                	ld	s1,56(sp)
    800011ac:	7942                	ld	s2,48(sp)
    800011ae:	79a2                	ld	s3,40(sp)
    800011b0:	7a02                	ld	s4,32(sp)
    800011b2:	6ae2                	ld	s5,24(sp)
    800011b4:	6b42                	ld	s6,16(sp)
    800011b6:	6ba2                	ld	s7,8(sp)
    800011b8:	6161                	addi	sp,sp,80
    800011ba:	8082                	ret
  return 0;
    800011bc:	4501                	li	a0,0
    800011be:	b7e5                	j	800011a6 <mappages+0x74>

00000000800011c0 <kvmmap>:
{
    800011c0:	1141                	addi	sp,sp,-16
    800011c2:	e406                	sd	ra,8(sp)
    800011c4:	e022                	sd	s0,0(sp)
    800011c6:	0800                	addi	s0,sp,16
    800011c8:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011ca:	86ae                	mv	a3,a1
    800011cc:	85aa                	mv	a1,a0
    800011ce:	00008517          	auipc	a0,0x8
    800011d2:	e4253503          	ld	a0,-446(a0) # 80009010 <kernel_pagetable>
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	f5c080e7          	jalr	-164(ra) # 80001132 <mappages>
    800011de:	e509                	bnez	a0,800011e8 <kvmmap+0x28>
}
    800011e0:	60a2                	ld	ra,8(sp)
    800011e2:	6402                	ld	s0,0(sp)
    800011e4:	0141                	addi	sp,sp,16
    800011e6:	8082                	ret
    panic("kvmmap");
    800011e8:	00007517          	auipc	a0,0x7
    800011ec:	f0050513          	addi	a0,a0,-256 # 800080e8 <digits+0xa8>
    800011f0:	fffff097          	auipc	ra,0xfffff
    800011f4:	356080e7          	jalr	854(ra) # 80000546 <panic>

00000000800011f8 <kvminit>:
{
    800011f8:	1101                	addi	sp,sp,-32
    800011fa:	ec06                	sd	ra,24(sp)
    800011fc:	e822                	sd	s0,16(sp)
    800011fe:	e426                	sd	s1,8(sp)
    80001200:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001202:	00000097          	auipc	ra,0x0
    80001206:	90e080e7          	jalr	-1778(ra) # 80000b10 <kalloc>
    8000120a:	00008717          	auipc	a4,0x8
    8000120e:	e0a73323          	sd	a0,-506(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001212:	6605                	lui	a2,0x1
    80001214:	4581                	li	a1,0
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	ae6080e7          	jalr	-1306(ra) # 80000cfc <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4699                	li	a3,6
    80001220:	6605                	lui	a2,0x1
    80001222:	100005b7          	lui	a1,0x10000
    80001226:	10000537          	lui	a0,0x10000
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f96080e7          	jalr	-106(ra) # 800011c0 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001232:	4699                	li	a3,6
    80001234:	6605                	lui	a2,0x1
    80001236:	100015b7          	lui	a1,0x10001
    8000123a:	10001537          	lui	a0,0x10001
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f82080e7          	jalr	-126(ra) # 800011c0 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001246:	4699                	li	a3,6
    80001248:	6641                	lui	a2,0x10
    8000124a:	020005b7          	lui	a1,0x2000
    8000124e:	02000537          	lui	a0,0x2000
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f6e080e7          	jalr	-146(ra) # 800011c0 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000125a:	4699                	li	a3,6
    8000125c:	00400637          	lui	a2,0x400
    80001260:	0c0005b7          	lui	a1,0xc000
    80001264:	0c000537          	lui	a0,0xc000
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f58080e7          	jalr	-168(ra) # 800011c0 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001270:	00007497          	auipc	s1,0x7
    80001274:	d9048493          	addi	s1,s1,-624 # 80008000 <etext>
    80001278:	46a9                	li	a3,10
    8000127a:	80007617          	auipc	a2,0x80007
    8000127e:	d8660613          	addi	a2,a2,-634 # 8000 <_entry-0x7fff8000>
    80001282:	4585                	li	a1,1
    80001284:	05fe                	slli	a1,a1,0x1f
    80001286:	852e                	mv	a0,a1
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	f38080e7          	jalr	-200(ra) # 800011c0 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001290:	4699                	li	a3,6
    80001292:	4645                	li	a2,17
    80001294:	066e                	slli	a2,a2,0x1b
    80001296:	8e05                	sub	a2,a2,s1
    80001298:	85a6                	mv	a1,s1
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f24080e7          	jalr	-220(ra) # 800011c0 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012a4:	46a9                	li	a3,10
    800012a6:	6605                	lui	a2,0x1
    800012a8:	00006597          	auipc	a1,0x6
    800012ac:	d5858593          	addi	a1,a1,-680 # 80007000 <_trampoline>
    800012b0:	04000537          	lui	a0,0x4000
    800012b4:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    800012b6:	0532                	slli	a0,a0,0xc
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f08080e7          	jalr	-248(ra) # 800011c0 <kvmmap>
}
    800012c0:	60e2                	ld	ra,24(sp)
    800012c2:	6442                	ld	s0,16(sp)
    800012c4:	64a2                	ld	s1,8(sp)
    800012c6:	6105                	addi	sp,sp,32
    800012c8:	8082                	ret

00000000800012ca <kvmmap_proc>:
{   
    800012ca:	1141                	addi	sp,sp,-16
    800012cc:	e406                	sd	ra,8(sp)
    800012ce:	e022                	sd	s0,0(sp)
    800012d0:	0800                	addi	s0,sp,16
    800012d2:	87b6                	mv	a5,a3
  if(mappages(kpagetable, va, sz, pa, perm) != 0)
    800012d4:	86b2                	mv	a3,a2
    800012d6:	863e                	mv	a2,a5
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	e5a080e7          	jalr	-422(ra) # 80001132 <mappages>
    800012e0:	e509                	bnez	a0,800012ea <kvmmap_proc+0x20>
}
    800012e2:	60a2                	ld	ra,8(sp)
    800012e4:	6402                	ld	s0,0(sp)
    800012e6:	0141                	addi	sp,sp,16
    800012e8:	8082                	ret
    panic("kvmmap");
    800012ea:	00007517          	auipc	a0,0x7
    800012ee:	dfe50513          	addi	a0,a0,-514 # 800080e8 <digits+0xa8>
    800012f2:	fffff097          	auipc	ra,0xfffff
    800012f6:	254080e7          	jalr	596(ra) # 80000546 <panic>

00000000800012fa <kvminit_proc>:
pagetable_t kvminit_proc(){
    800012fa:	1101                	addi	sp,sp,-32
    800012fc:	ec06                	sd	ra,24(sp)
    800012fe:	e822                	sd	s0,16(sp)
    80001300:	e426                	sd	s1,8(sp)
    80001302:	e04a                	sd	s2,0(sp)
    80001304:	1000                	addi	s0,sp,32
  pagetable_t k_pagetable = (pagetable_t)kalloc();
    80001306:	00000097          	auipc	ra,0x0
    8000130a:	80a080e7          	jalr	-2038(ra) # 80000b10 <kalloc>
    8000130e:	84aa                	mv	s1,a0
  memset(k_pagetable, 0, PGSIZE);
    80001310:	6605                	lui	a2,0x1
    80001312:	4581                	li	a1,0
    80001314:	00000097          	auipc	ra,0x0
    80001318:	9e8080e7          	jalr	-1560(ra) # 80000cfc <memset>
  kvmmap_proc(k_pagetable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000131c:	4719                	li	a4,6
    8000131e:	6685                	lui	a3,0x1
    80001320:	10000637          	lui	a2,0x10000
    80001324:	100005b7          	lui	a1,0x10000
    80001328:	8526                	mv	a0,s1
    8000132a:	00000097          	auipc	ra,0x0
    8000132e:	fa0080e7          	jalr	-96(ra) # 800012ca <kvmmap_proc>
  kvmmap_proc(k_pagetable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001332:	4719                	li	a4,6
    80001334:	6685                	lui	a3,0x1
    80001336:	10001637          	lui	a2,0x10001
    8000133a:	100015b7          	lui	a1,0x10001
    8000133e:	8526                	mv	a0,s1
    80001340:	00000097          	auipc	ra,0x0
    80001344:	f8a080e7          	jalr	-118(ra) # 800012ca <kvmmap_proc>
  kvmmap_proc(k_pagetable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001348:	4719                	li	a4,6
    8000134a:	004006b7          	lui	a3,0x400
    8000134e:	0c000637          	lui	a2,0xc000
    80001352:	0c0005b7          	lui	a1,0xc000
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f72080e7          	jalr	-142(ra) # 800012ca <kvmmap_proc>
  kvmmap_proc(k_pagetable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001360:	00007917          	auipc	s2,0x7
    80001364:	ca090913          	addi	s2,s2,-864 # 80008000 <etext>
    80001368:	4729                	li	a4,10
    8000136a:	80007697          	auipc	a3,0x80007
    8000136e:	c9668693          	addi	a3,a3,-874 # 8000 <_entry-0x7fff8000>
    80001372:	4605                	li	a2,1
    80001374:	067e                	slli	a2,a2,0x1f
    80001376:	85b2                	mv	a1,a2
    80001378:	8526                	mv	a0,s1
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	f50080e7          	jalr	-176(ra) # 800012ca <kvmmap_proc>
  kvmmap_proc(k_pagetable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001382:	4719                	li	a4,6
    80001384:	46c5                	li	a3,17
    80001386:	06ee                	slli	a3,a3,0x1b
    80001388:	412686b3          	sub	a3,a3,s2
    8000138c:	864a                	mv	a2,s2
    8000138e:	85ca                	mv	a1,s2
    80001390:	8526                	mv	a0,s1
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f38080e7          	jalr	-200(ra) # 800012ca <kvmmap_proc>
  kvmmap_proc(k_pagetable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000139a:	4729                	li	a4,10
    8000139c:	6685                	lui	a3,0x1
    8000139e:	00006617          	auipc	a2,0x6
    800013a2:	c6260613          	addi	a2,a2,-926 # 80007000 <_trampoline>
    800013a6:	040005b7          	lui	a1,0x4000
    800013aa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013ac:	05b2                	slli	a1,a1,0xc
    800013ae:	8526                	mv	a0,s1
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	f1a080e7          	jalr	-230(ra) # 800012ca <kvmmap_proc>
}
    800013b8:	8526                	mv	a0,s1
    800013ba:	60e2                	ld	ra,24(sp)
    800013bc:	6442                	ld	s0,16(sp)
    800013be:	64a2                	ld	s1,8(sp)
    800013c0:	6902                	ld	s2,0(sp)
    800013c2:	6105                	addi	sp,sp,32
    800013c4:	8082                	ret

00000000800013c6 <uvmunmap>:
// Optionally free the physical memory.
// If do_free != 0, physical memory will be freed
// starts with u means user virtual memory
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013c6:	715d                	addi	sp,sp,-80
    800013c8:	e486                	sd	ra,72(sp)
    800013ca:	e0a2                	sd	s0,64(sp)
    800013cc:	fc26                	sd	s1,56(sp)
    800013ce:	f84a                	sd	s2,48(sp)
    800013d0:	f44e                	sd	s3,40(sp)
    800013d2:	f052                	sd	s4,32(sp)
    800013d4:	ec56                	sd	s5,24(sp)
    800013d6:	e85a                	sd	s6,16(sp)
    800013d8:	e45e                	sd	s7,8(sp)
    800013da:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013dc:	03459793          	slli	a5,a1,0x34
    800013e0:	e795                	bnez	a5,8000140c <uvmunmap+0x46>
    800013e2:	8a2a                	mv	s4,a0
    800013e4:	892e                	mv	s2,a1
    800013e6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e8:	0632                	slli	a2,a2,0xc
    800013ea:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ee:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f0:	6b05                	lui	s6,0x1
    800013f2:	0735e263          	bltu	a1,s3,80001456 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013f6:	60a6                	ld	ra,72(sp)
    800013f8:	6406                	ld	s0,64(sp)
    800013fa:	74e2                	ld	s1,56(sp)
    800013fc:	7942                	ld	s2,48(sp)
    800013fe:	79a2                	ld	s3,40(sp)
    80001400:	7a02                	ld	s4,32(sp)
    80001402:	6ae2                	ld	s5,24(sp)
    80001404:	6b42                	ld	s6,16(sp)
    80001406:	6ba2                	ld	s7,8(sp)
    80001408:	6161                	addi	sp,sp,80
    8000140a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	ce450513          	addi	a0,a0,-796 # 800080f0 <digits+0xb0>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	132080e7          	jalr	306(ra) # 80000546 <panic>
      panic("uvmunmap: walk");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	cec50513          	addi	a0,a0,-788 # 80008108 <digits+0xc8>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	122080e7          	jalr	290(ra) # 80000546 <panic>
      panic("uvmunmap: not mapped");
    8000142c:	00007517          	auipc	a0,0x7
    80001430:	cec50513          	addi	a0,a0,-788 # 80008118 <digits+0xd8>
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	112080e7          	jalr	274(ra) # 80000546 <panic>
      panic("uvmunmap: not a leaf");
    8000143c:	00007517          	auipc	a0,0x7
    80001440:	cf450513          	addi	a0,a0,-780 # 80008130 <digits+0xf0>
    80001444:	fffff097          	auipc	ra,0xfffff
    80001448:	102080e7          	jalr	258(ra) # 80000546 <panic>
    *pte = 0;
    8000144c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001450:	995a                	add	s2,s2,s6
    80001452:	fb3972e3          	bgeu	s2,s3,800013f6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001456:	4601                	li	a2,0
    80001458:	85ca                	mv	a1,s2
    8000145a:	8552                	mv	a0,s4
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	b90080e7          	jalr	-1136(ra) # 80000fec <walk>
    80001464:	84aa                	mv	s1,a0
    80001466:	d95d                	beqz	a0,8000141c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001468:	6108                	ld	a0,0(a0)
    8000146a:	00157793          	andi	a5,a0,1
    8000146e:	dfdd                	beqz	a5,8000142c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001470:	3ff57793          	andi	a5,a0,1023
    80001474:	fd7784e3          	beq	a5,s7,8000143c <uvmunmap+0x76>
    if(do_free){
    80001478:	fc0a8ae3          	beqz	s5,8000144c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000147c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000147e:	0532                	slli	a0,a0,0xc
    80001480:	fffff097          	auipc	ra,0xfffff
    80001484:	592080e7          	jalr	1426(ra) # 80000a12 <kfree>
    80001488:	b7d1                	j	8000144c <uvmunmap+0x86>

000000008000148a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000148a:	1101                	addi	sp,sp,-32
    8000148c:	ec06                	sd	ra,24(sp)
    8000148e:	e822                	sd	s0,16(sp)
    80001490:	e426                	sd	s1,8(sp)
    80001492:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001494:	fffff097          	auipc	ra,0xfffff
    80001498:	67c080e7          	jalr	1660(ra) # 80000b10 <kalloc>
    8000149c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000149e:	c519                	beqz	a0,800014ac <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014a0:	6605                	lui	a2,0x1
    800014a2:	4581                	li	a1,0
    800014a4:	00000097          	auipc	ra,0x0
    800014a8:	858080e7          	jalr	-1960(ra) # 80000cfc <memset>
  return pagetable;
}
    800014ac:	8526                	mv	a0,s1
    800014ae:	60e2                	ld	ra,24(sp)
    800014b0:	6442                	ld	s0,16(sp)
    800014b2:	64a2                	ld	s1,8(sp)
    800014b4:	6105                	addi	sp,sp,32
    800014b6:	8082                	ret

00000000800014b8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800014b8:	7179                	addi	sp,sp,-48
    800014ba:	f406                	sd	ra,40(sp)
    800014bc:	f022                	sd	s0,32(sp)
    800014be:	ec26                	sd	s1,24(sp)
    800014c0:	e84a                	sd	s2,16(sp)
    800014c2:	e44e                	sd	s3,8(sp)
    800014c4:	e052                	sd	s4,0(sp)
    800014c6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014c8:	6785                	lui	a5,0x1
    800014ca:	04f67863          	bgeu	a2,a5,8000151a <uvminit+0x62>
    800014ce:	8a2a                	mv	s4,a0
    800014d0:	89ae                	mv	s3,a1
    800014d2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014d4:	fffff097          	auipc	ra,0xfffff
    800014d8:	63c080e7          	jalr	1596(ra) # 80000b10 <kalloc>
    800014dc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014de:	6605                	lui	a2,0x1
    800014e0:	4581                	li	a1,0
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	81a080e7          	jalr	-2022(ra) # 80000cfc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ea:	4779                	li	a4,30
    800014ec:	86ca                	mv	a3,s2
    800014ee:	6605                	lui	a2,0x1
    800014f0:	4581                	li	a1,0
    800014f2:	8552                	mv	a0,s4
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	c3e080e7          	jalr	-962(ra) # 80001132 <mappages>
  memmove(mem, src, sz);
    800014fc:	8626                	mv	a2,s1
    800014fe:	85ce                	mv	a1,s3
    80001500:	854a                	mv	a0,s2
    80001502:	00000097          	auipc	ra,0x0
    80001506:	856080e7          	jalr	-1962(ra) # 80000d58 <memmove>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret
    panic("inituvm: more than a page");
    8000151a:	00007517          	auipc	a0,0x7
    8000151e:	c2e50513          	addi	a0,a0,-978 # 80008148 <digits+0x108>
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	024080e7          	jalr	36(ra) # 80000546 <panic>

000000008000152a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000152a:	1101                	addi	sp,sp,-32
    8000152c:	ec06                	sd	ra,24(sp)
    8000152e:	e822                	sd	s0,16(sp)
    80001530:	e426                	sd	s1,8(sp)
    80001532:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001534:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001536:	00b67d63          	bgeu	a2,a1,80001550 <uvmdealloc+0x26>
    8000153a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000153c:	6785                	lui	a5,0x1
    8000153e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001540:	00f60733          	add	a4,a2,a5
    80001544:	76fd                	lui	a3,0xfffff
    80001546:	8f75                	and	a4,a4,a3
    80001548:	97ae                	add	a5,a5,a1
    8000154a:	8ff5                	and	a5,a5,a3
    8000154c:	00f76863          	bltu	a4,a5,8000155c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001550:	8526                	mv	a0,s1
    80001552:	60e2                	ld	ra,24(sp)
    80001554:	6442                	ld	s0,16(sp)
    80001556:	64a2                	ld	s1,8(sp)
    80001558:	6105                	addi	sp,sp,32
    8000155a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000155c:	8f99                	sub	a5,a5,a4
    8000155e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001560:	4685                	li	a3,1
    80001562:	0007861b          	sext.w	a2,a5
    80001566:	85ba                	mv	a1,a4
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	e5e080e7          	jalr	-418(ra) # 800013c6 <uvmunmap>
    80001570:	b7c5                	j	80001550 <uvmdealloc+0x26>

0000000080001572 <uvmalloc>:
  if(newsz < oldsz)
    80001572:	0ab66163          	bltu	a2,a1,80001614 <uvmalloc+0xa2>
{
    80001576:	7139                	addi	sp,sp,-64
    80001578:	fc06                	sd	ra,56(sp)
    8000157a:	f822                	sd	s0,48(sp)
    8000157c:	f426                	sd	s1,40(sp)
    8000157e:	f04a                	sd	s2,32(sp)
    80001580:	ec4e                	sd	s3,24(sp)
    80001582:	e852                	sd	s4,16(sp)
    80001584:	e456                	sd	s5,8(sp)
    80001586:	0080                	addi	s0,sp,64
    80001588:	8aaa                	mv	s5,a0
    8000158a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000158c:	6785                	lui	a5,0x1
    8000158e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001590:	95be                	add	a1,a1,a5
    80001592:	77fd                	lui	a5,0xfffff
    80001594:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001598:	08c9f063          	bgeu	s3,a2,80001618 <uvmalloc+0xa6>
    8000159c:	894e                	mv	s2,s3
    mem = kalloc();
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	572080e7          	jalr	1394(ra) # 80000b10 <kalloc>
    800015a6:	84aa                	mv	s1,a0
    if(mem == 0){
    800015a8:	c51d                	beqz	a0,800015d6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800015aa:	6605                	lui	a2,0x1
    800015ac:	4581                	li	a1,0
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	74e080e7          	jalr	1870(ra) # 80000cfc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800015b6:	4779                	li	a4,30
    800015b8:	86a6                	mv	a3,s1
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85ca                	mv	a1,s2
    800015be:	8556                	mv	a0,s5
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	b72080e7          	jalr	-1166(ra) # 80001132 <mappages>
    800015c8:	e905                	bnez	a0,800015f8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015ca:	6785                	lui	a5,0x1
    800015cc:	993e                	add	s2,s2,a5
    800015ce:	fd4968e3          	bltu	s2,s4,8000159e <uvmalloc+0x2c>
  return newsz;
    800015d2:	8552                	mv	a0,s4
    800015d4:	a809                	j	800015e6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015d6:	864e                	mv	a2,s3
    800015d8:	85ca                	mv	a1,s2
    800015da:	8556                	mv	a0,s5
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	f4e080e7          	jalr	-178(ra) # 8000152a <uvmdealloc>
      return 0;
    800015e4:	4501                	li	a0,0
}
    800015e6:	70e2                	ld	ra,56(sp)
    800015e8:	7442                	ld	s0,48(sp)
    800015ea:	74a2                	ld	s1,40(sp)
    800015ec:	7902                	ld	s2,32(sp)
    800015ee:	69e2                	ld	s3,24(sp)
    800015f0:	6a42                	ld	s4,16(sp)
    800015f2:	6aa2                	ld	s5,8(sp)
    800015f4:	6121                	addi	sp,sp,64
    800015f6:	8082                	ret
      kfree(mem);
    800015f8:	8526                	mv	a0,s1
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	418080e7          	jalr	1048(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001602:	864e                	mv	a2,s3
    80001604:	85ca                	mv	a1,s2
    80001606:	8556                	mv	a0,s5
    80001608:	00000097          	auipc	ra,0x0
    8000160c:	f22080e7          	jalr	-222(ra) # 8000152a <uvmdealloc>
      return 0;
    80001610:	4501                	li	a0,0
    80001612:	bfd1                	j	800015e6 <uvmalloc+0x74>
    return oldsz;
    80001614:	852e                	mv	a0,a1
}
    80001616:	8082                	ret
  return newsz;
    80001618:	8532                	mv	a0,a2
    8000161a:	b7f1                	j	800015e6 <uvmalloc+0x74>

000000008000161c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000161c:	7179                	addi	sp,sp,-48
    8000161e:	f406                	sd	ra,40(sp)
    80001620:	f022                	sd	s0,32(sp)
    80001622:	ec26                	sd	s1,24(sp)
    80001624:	e84a                	sd	s2,16(sp)
    80001626:	e44e                	sd	s3,8(sp)
    80001628:	e052                	sd	s4,0(sp)
    8000162a:	1800                	addi	s0,sp,48
    8000162c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000162e:	84aa                	mv	s1,a0
    80001630:	6905                	lui	s2,0x1
    80001632:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001634:	4985                	li	s3,1
    80001636:	a829                	j	80001650 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001638:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000163a:	00c79513          	slli	a0,a5,0xc
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	fde080e7          	jalr	-34(ra) # 8000161c <freewalk>
      pagetable[i] = 0;  
    80001646:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000164a:	04a1                	addi	s1,s1,8
    8000164c:	03248163          	beq	s1,s2,8000166e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001650:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001652:	00f7f713          	andi	a4,a5,15
    80001656:	ff3701e3          	beq	a4,s3,80001638 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000165a:	8b85                	andi	a5,a5,1
    8000165c:	d7fd                	beqz	a5,8000164a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000165e:	00007517          	auipc	a0,0x7
    80001662:	b0a50513          	addi	a0,a0,-1270 # 80008168 <digits+0x128>
    80001666:	fffff097          	auipc	ra,0xfffff
    8000166a:	ee0080e7          	jalr	-288(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    8000166e:	8552                	mv	a0,s4
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	3a2080e7          	jalr	930(ra) # 80000a12 <kfree>
}
    80001678:	70a2                	ld	ra,40(sp)
    8000167a:	7402                	ld	s0,32(sp)
    8000167c:	64e2                	ld	s1,24(sp)
    8000167e:	6942                	ld	s2,16(sp)
    80001680:	69a2                	ld	s3,8(sp)
    80001682:	6a02                	ld	s4,0(sp)
    80001684:	6145                	addi	sp,sp,48
    80001686:	8082                	ret

0000000080001688 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001688:	1101                	addi	sp,sp,-32
    8000168a:	ec06                	sd	ra,24(sp)
    8000168c:	e822                	sd	s0,16(sp)
    8000168e:	e426                	sd	s1,8(sp)
    80001690:	1000                	addi	s0,sp,32
    80001692:	84aa                	mv	s1,a0
  if(sz > 0)
    80001694:	e999                	bnez	a1,800016aa <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001696:	8526                	mv	a0,s1
    80001698:	00000097          	auipc	ra,0x0
    8000169c:	f84080e7          	jalr	-124(ra) # 8000161c <freewalk>
}
    800016a0:	60e2                	ld	ra,24(sp)
    800016a2:	6442                	ld	s0,16(sp)
    800016a4:	64a2                	ld	s1,8(sp)
    800016a6:	6105                	addi	sp,sp,32
    800016a8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016aa:	6785                	lui	a5,0x1
    800016ac:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016ae:	95be                	add	a1,a1,a5
    800016b0:	4685                	li	a3,1
    800016b2:	00c5d613          	srli	a2,a1,0xc
    800016b6:	4581                	li	a1,0
    800016b8:	00000097          	auipc	ra,0x0
    800016bc:	d0e080e7          	jalr	-754(ra) # 800013c6 <uvmunmap>
    800016c0:	bfd9                	j	80001696 <uvmfree+0xe>

00000000800016c2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016c2:	c679                	beqz	a2,80001790 <uvmcopy+0xce>
{
    800016c4:	715d                	addi	sp,sp,-80
    800016c6:	e486                	sd	ra,72(sp)
    800016c8:	e0a2                	sd	s0,64(sp)
    800016ca:	fc26                	sd	s1,56(sp)
    800016cc:	f84a                	sd	s2,48(sp)
    800016ce:	f44e                	sd	s3,40(sp)
    800016d0:	f052                	sd	s4,32(sp)
    800016d2:	ec56                	sd	s5,24(sp)
    800016d4:	e85a                	sd	s6,16(sp)
    800016d6:	e45e                	sd	s7,8(sp)
    800016d8:	0880                	addi	s0,sp,80
    800016da:	8b2a                	mv	s6,a0
    800016dc:	8aae                	mv	s5,a1
    800016de:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016e0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016e2:	4601                	li	a2,0
    800016e4:	85ce                	mv	a1,s3
    800016e6:	855a                	mv	a0,s6
    800016e8:	00000097          	auipc	ra,0x0
    800016ec:	904080e7          	jalr	-1788(ra) # 80000fec <walk>
    800016f0:	c531                	beqz	a0,8000173c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016f2:	6118                	ld	a4,0(a0)
    800016f4:	00177793          	andi	a5,a4,1
    800016f8:	cbb1                	beqz	a5,8000174c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016fa:	00a75593          	srli	a1,a4,0xa
    800016fe:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001702:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001706:	fffff097          	auipc	ra,0xfffff
    8000170a:	40a080e7          	jalr	1034(ra) # 80000b10 <kalloc>
    8000170e:	892a                	mv	s2,a0
    80001710:	c939                	beqz	a0,80001766 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001712:	6605                	lui	a2,0x1
    80001714:	85de                	mv	a1,s7
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	642080e7          	jalr	1602(ra) # 80000d58 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000171e:	8726                	mv	a4,s1
    80001720:	86ca                	mv	a3,s2
    80001722:	6605                	lui	a2,0x1
    80001724:	85ce                	mv	a1,s3
    80001726:	8556                	mv	a0,s5
    80001728:	00000097          	auipc	ra,0x0
    8000172c:	a0a080e7          	jalr	-1526(ra) # 80001132 <mappages>
    80001730:	e515                	bnez	a0,8000175c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001732:	6785                	lui	a5,0x1
    80001734:	99be                	add	s3,s3,a5
    80001736:	fb49e6e3          	bltu	s3,s4,800016e2 <uvmcopy+0x20>
    8000173a:	a081                	j	8000177a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a3c50513          	addi	a0,a0,-1476 # 80008178 <digits+0x138>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	e02080e7          	jalr	-510(ra) # 80000546 <panic>
      panic("uvmcopy: page not present");
    8000174c:	00007517          	auipc	a0,0x7
    80001750:	a4c50513          	addi	a0,a0,-1460 # 80008198 <digits+0x158>
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	df2080e7          	jalr	-526(ra) # 80000546 <panic>
      kfree(mem);
    8000175c:	854a                	mv	a0,s2
    8000175e:	fffff097          	auipc	ra,0xfffff
    80001762:	2b4080e7          	jalr	692(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001766:	4685                	li	a3,1
    80001768:	00c9d613          	srli	a2,s3,0xc
    8000176c:	4581                	li	a1,0
    8000176e:	8556                	mv	a0,s5
    80001770:	00000097          	auipc	ra,0x0
    80001774:	c56080e7          	jalr	-938(ra) # 800013c6 <uvmunmap>
  return -1;
    80001778:	557d                	li	a0,-1
}
    8000177a:	60a6                	ld	ra,72(sp)
    8000177c:	6406                	ld	s0,64(sp)
    8000177e:	74e2                	ld	s1,56(sp)
    80001780:	7942                	ld	s2,48(sp)
    80001782:	79a2                	ld	s3,40(sp)
    80001784:	7a02                	ld	s4,32(sp)
    80001786:	6ae2                	ld	s5,24(sp)
    80001788:	6b42                	ld	s6,16(sp)
    8000178a:	6ba2                	ld	s7,8(sp)
    8000178c:	6161                	addi	sp,sp,80
    8000178e:	8082                	ret
  return 0;
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret

0000000080001794 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001794:	1141                	addi	sp,sp,-16
    80001796:	e406                	sd	ra,8(sp)
    80001798:	e022                	sd	s0,0(sp)
    8000179a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000179c:	4601                	li	a2,0
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	84e080e7          	jalr	-1970(ra) # 80000fec <walk>
  if(pte == 0)
    800017a6:	c901                	beqz	a0,800017b6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017a8:	611c                	ld	a5,0(a0)
    800017aa:	9bbd                	andi	a5,a5,-17
    800017ac:	e11c                	sd	a5,0(a0)
}
    800017ae:	60a2                	ld	ra,8(sp)
    800017b0:	6402                	ld	s0,0(sp)
    800017b2:	0141                	addi	sp,sp,16
    800017b4:	8082                	ret
    panic("uvmclear");
    800017b6:	00007517          	auipc	a0,0x7
    800017ba:	a0250513          	addi	a0,a0,-1534 # 800081b8 <digits+0x178>
    800017be:	fffff097          	auipc	ra,0xfffff
    800017c2:	d88080e7          	jalr	-632(ra) # 80000546 <panic>

00000000800017c6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017c6:	c6bd                	beqz	a3,80001834 <copyout+0x6e>
{
    800017c8:	715d                	addi	sp,sp,-80
    800017ca:	e486                	sd	ra,72(sp)
    800017cc:	e0a2                	sd	s0,64(sp)
    800017ce:	fc26                	sd	s1,56(sp)
    800017d0:	f84a                	sd	s2,48(sp)
    800017d2:	f44e                	sd	s3,40(sp)
    800017d4:	f052                	sd	s4,32(sp)
    800017d6:	ec56                	sd	s5,24(sp)
    800017d8:	e85a                	sd	s6,16(sp)
    800017da:	e45e                	sd	s7,8(sp)
    800017dc:	e062                	sd	s8,0(sp)
    800017de:	0880                	addi	s0,sp,80
    800017e0:	8b2a                	mv	s6,a0
    800017e2:	8c2e                	mv	s8,a1
    800017e4:	8a32                	mv	s4,a2
    800017e6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017e8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017ea:	6a85                	lui	s5,0x1
    800017ec:	a015                	j	80001810 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017ee:	9562                	add	a0,a0,s8
    800017f0:	0004861b          	sext.w	a2,s1
    800017f4:	85d2                	mv	a1,s4
    800017f6:	41250533          	sub	a0,a0,s2
    800017fa:	fffff097          	auipc	ra,0xfffff
    800017fe:	55e080e7          	jalr	1374(ra) # 80000d58 <memmove>

    len -= n;
    80001802:	409989b3          	sub	s3,s3,s1
    src += n;
    80001806:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001808:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000180c:	02098263          	beqz	s3,80001830 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001810:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001814:	85ca                	mv	a1,s2
    80001816:	855a                	mv	a0,s6
    80001818:	00000097          	auipc	ra,0x0
    8000181c:	87a080e7          	jalr	-1926(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    80001820:	cd01                	beqz	a0,80001838 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001822:	418904b3          	sub	s1,s2,s8
    80001826:	94d6                	add	s1,s1,s5
    80001828:	fc99f3e3          	bgeu	s3,s1,800017ee <copyout+0x28>
    8000182c:	84ce                	mv	s1,s3
    8000182e:	b7c1                	j	800017ee <copyout+0x28>
  }
  return 0;
    80001830:	4501                	li	a0,0
    80001832:	a021                	j	8000183a <copyout+0x74>
    80001834:	4501                	li	a0,0
}
    80001836:	8082                	ret
      return -1;
    80001838:	557d                	li	a0,-1
}
    8000183a:	60a6                	ld	ra,72(sp)
    8000183c:	6406                	ld	s0,64(sp)
    8000183e:	74e2                	ld	s1,56(sp)
    80001840:	7942                	ld	s2,48(sp)
    80001842:	79a2                	ld	s3,40(sp)
    80001844:	7a02                	ld	s4,32(sp)
    80001846:	6ae2                	ld	s5,24(sp)
    80001848:	6b42                	ld	s6,16(sp)
    8000184a:	6ba2                	ld	s7,8(sp)
    8000184c:	6c02                	ld	s8,0(sp)
    8000184e:	6161                	addi	sp,sp,80
    80001850:	8082                	ret

0000000080001852 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001852:	caa5                	beqz	a3,800018c2 <copyin+0x70>
{
    80001854:	715d                	addi	sp,sp,-80
    80001856:	e486                	sd	ra,72(sp)
    80001858:	e0a2                	sd	s0,64(sp)
    8000185a:	fc26                	sd	s1,56(sp)
    8000185c:	f84a                	sd	s2,48(sp)
    8000185e:	f44e                	sd	s3,40(sp)
    80001860:	f052                	sd	s4,32(sp)
    80001862:	ec56                	sd	s5,24(sp)
    80001864:	e85a                	sd	s6,16(sp)
    80001866:	e45e                	sd	s7,8(sp)
    80001868:	e062                	sd	s8,0(sp)
    8000186a:	0880                	addi	s0,sp,80
    8000186c:	8b2a                	mv	s6,a0
    8000186e:	8a2e                	mv	s4,a1
    80001870:	8c32                	mv	s8,a2
    80001872:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001874:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001876:	6a85                	lui	s5,0x1
    80001878:	a01d                	j	8000189e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000187a:	018505b3          	add	a1,a0,s8
    8000187e:	0004861b          	sext.w	a2,s1
    80001882:	412585b3          	sub	a1,a1,s2
    80001886:	8552                	mv	a0,s4
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	4d0080e7          	jalr	1232(ra) # 80000d58 <memmove>

    len -= n;
    80001890:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001894:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001896:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000189a:	02098263          	beqz	s3,800018be <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000189e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018a2:	85ca                	mv	a1,s2
    800018a4:	855a                	mv	a0,s6
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	7ec080e7          	jalr	2028(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800018ae:	cd01                	beqz	a0,800018c6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018b0:	418904b3          	sub	s1,s2,s8
    800018b4:	94d6                	add	s1,s1,s5
    800018b6:	fc99f2e3          	bgeu	s3,s1,8000187a <copyin+0x28>
    800018ba:	84ce                	mv	s1,s3
    800018bc:	bf7d                	j	8000187a <copyin+0x28>
  }
  return 0;
    800018be:	4501                	li	a0,0
    800018c0:	a021                	j	800018c8 <copyin+0x76>
    800018c2:	4501                	li	a0,0
}
    800018c4:	8082                	ret
      return -1;
    800018c6:	557d                	li	a0,-1
}
    800018c8:	60a6                	ld	ra,72(sp)
    800018ca:	6406                	ld	s0,64(sp)
    800018cc:	74e2                	ld	s1,56(sp)
    800018ce:	7942                	ld	s2,48(sp)
    800018d0:	79a2                	ld	s3,40(sp)
    800018d2:	7a02                	ld	s4,32(sp)
    800018d4:	6ae2                	ld	s5,24(sp)
    800018d6:	6b42                	ld	s6,16(sp)
    800018d8:	6ba2                	ld	s7,8(sp)
    800018da:	6c02                	ld	s8,0(sp)
    800018dc:	6161                	addi	sp,sp,80
    800018de:	8082                	ret

00000000800018e0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018e0:	c2dd                	beqz	a3,80001986 <copyinstr+0xa6>
{
    800018e2:	715d                	addi	sp,sp,-80
    800018e4:	e486                	sd	ra,72(sp)
    800018e6:	e0a2                	sd	s0,64(sp)
    800018e8:	fc26                	sd	s1,56(sp)
    800018ea:	f84a                	sd	s2,48(sp)
    800018ec:	f44e                	sd	s3,40(sp)
    800018ee:	f052                	sd	s4,32(sp)
    800018f0:	ec56                	sd	s5,24(sp)
    800018f2:	e85a                	sd	s6,16(sp)
    800018f4:	e45e                	sd	s7,8(sp)
    800018f6:	0880                	addi	s0,sp,80
    800018f8:	8a2a                	mv	s4,a0
    800018fa:	8b2e                	mv	s6,a1
    800018fc:	8bb2                	mv	s7,a2
    800018fe:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001900:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001902:	6985                	lui	s3,0x1
    80001904:	a02d                	j	8000192e <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001906:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000190a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000190c:	37fd                	addiw	a5,a5,-1
    8000190e:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001912:	60a6                	ld	ra,72(sp)
    80001914:	6406                	ld	s0,64(sp)
    80001916:	74e2                	ld	s1,56(sp)
    80001918:	7942                	ld	s2,48(sp)
    8000191a:	79a2                	ld	s3,40(sp)
    8000191c:	7a02                	ld	s4,32(sp)
    8000191e:	6ae2                	ld	s5,24(sp)
    80001920:	6b42                	ld	s6,16(sp)
    80001922:	6ba2                	ld	s7,8(sp)
    80001924:	6161                	addi	sp,sp,80
    80001926:	8082                	ret
    srcva = va0 + PGSIZE;
    80001928:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000192c:	c8a9                	beqz	s1,8000197e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000192e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001932:	85ca                	mv	a1,s2
    80001934:	8552                	mv	a0,s4
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	75c080e7          	jalr	1884(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000193e:	c131                	beqz	a0,80001982 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001940:	417906b3          	sub	a3,s2,s7
    80001944:	96ce                	add	a3,a3,s3
    80001946:	00d4f363          	bgeu	s1,a3,8000194c <copyinstr+0x6c>
    8000194a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000194c:	955e                	add	a0,a0,s7
    8000194e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001952:	daf9                	beqz	a3,80001928 <copyinstr+0x48>
    80001954:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001956:	41650633          	sub	a2,a0,s6
    8000195a:	fff48593          	addi	a1,s1,-1
    8000195e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001960:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001962:	00f60733          	add	a4,a2,a5
    80001966:	00074703          	lbu	a4,0(a4)
    8000196a:	df51                	beqz	a4,80001906 <copyinstr+0x26>
        *dst = *p;
    8000196c:	00e78023          	sb	a4,0(a5)
      --max;
    80001970:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001974:	0785                	addi	a5,a5,1
    while(n > 0){
    80001976:	fed796e3          	bne	a5,a3,80001962 <copyinstr+0x82>
      dst++;
    8000197a:	8b3e                	mv	s6,a5
    8000197c:	b775                	j	80001928 <copyinstr+0x48>
    8000197e:	4781                	li	a5,0
    80001980:	b771                	j	8000190c <copyinstr+0x2c>
      return -1;
    80001982:	557d                	li	a0,-1
    80001984:	b779                	j	80001912 <copyinstr+0x32>
  int got_null = 0;
    80001986:	4781                	li	a5,0
  if(got_null){
    80001988:	37fd                	addiw	a5,a5,-1
    8000198a:	0007851b          	sext.w	a0,a5
}
    8000198e:	8082                	ret

0000000080001990 <test_pagetable>:
// }

// check if use global kpgtbl or not 
int 
test_pagetable()
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001996:	18002773          	csrr	a4,satp
  uint64 satp = r_satp();
  uint64 gsatp = MAKE_SATP(kernel_pagetable);
    8000199a:	00007517          	auipc	a0,0x7
    8000199e:	67653503          	ld	a0,1654(a0) # 80009010 <kernel_pagetable>
    800019a2:	8131                	srli	a0,a0,0xc
    800019a4:	57fd                	li	a5,-1
    800019a6:	17fe                	slli	a5,a5,0x3f
    800019a8:	8d5d                	or	a0,a0,a5
  return satp != gsatp;
    800019aa:	8d19                	sub	a0,a0,a4
}
    800019ac:	00a03533          	snez	a0,a0
    800019b0:	6422                	ld	s0,8(sp)
    800019b2:	0141                	addi	sp,sp,16
    800019b4:	8082                	ret

00000000800019b6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019b6:	1101                	addi	sp,sp,-32
    800019b8:	ec06                	sd	ra,24(sp)
    800019ba:	e822                	sd	s0,16(sp)
    800019bc:	e426                	sd	s1,8(sp)
    800019be:	1000                	addi	s0,sp,32
    800019c0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1c4080e7          	jalr	452(ra) # 80000b86 <holding>
    800019ca:	c909                	beqz	a0,800019dc <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019cc:	749c                	ld	a5,40(s1)
    800019ce:	00978f63          	beq	a5,s1,800019ec <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019d2:	60e2                	ld	ra,24(sp)
    800019d4:	6442                	ld	s0,16(sp)
    800019d6:	64a2                	ld	s1,8(sp)
    800019d8:	6105                	addi	sp,sp,32
    800019da:	8082                	ret
    panic("wakeup1");
    800019dc:	00006517          	auipc	a0,0x6
    800019e0:	7ec50513          	addi	a0,a0,2028 # 800081c8 <digits+0x188>
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	b62080e7          	jalr	-1182(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019ec:	4c98                	lw	a4,24(s1)
    800019ee:	4785                	li	a5,1
    800019f0:	fef711e3          	bne	a4,a5,800019d2 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019f4:	4789                	li	a5,2
    800019f6:	cc9c                	sw	a5,24(s1)
}
    800019f8:	bfe9                	j	800019d2 <wakeup1+0x1c>

00000000800019fa <procinit>:
{
    800019fa:	715d                	addi	sp,sp,-80
    800019fc:	e486                	sd	ra,72(sp)
    800019fe:	e0a2                	sd	s0,64(sp)
    80001a00:	fc26                	sd	s1,56(sp)
    80001a02:	f84a                	sd	s2,48(sp)
    80001a04:	f44e                	sd	s3,40(sp)
    80001a06:	f052                	sd	s4,32(sp)
    80001a08:	ec56                	sd	s5,24(sp)
    80001a0a:	e85a                	sd	s6,16(sp)
    80001a0c:	e45e                	sd	s7,8(sp)
    80001a0e:	e062                	sd	s8,0(sp)
    80001a10:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a12:	00006597          	auipc	a1,0x6
    80001a16:	7be58593          	addi	a1,a1,1982 # 800081d0 <digits+0x190>
    80001a1a:	00010517          	auipc	a0,0x10
    80001a1e:	f3650513          	addi	a0,a0,-202 # 80011950 <pid_lock>
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	14e080e7          	jalr	334(ra) # 80000b70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2a:	00010917          	auipc	s2,0x10
    80001a2e:	33e90913          	addi	s2,s2,830 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a32:	00006c17          	auipc	s8,0x6
    80001a36:	7a6c0c13          	addi	s8,s8,1958 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001a3a:	8bca                	mv	s7,s2
    80001a3c:	00006b17          	auipc	s6,0x6
    80001a40:	5c4b0b13          	addi	s6,s6,1476 # 80008000 <etext>
    80001a44:	04000a37          	lui	s4,0x4000
    80001a48:	1a7d                	addi	s4,s4,-1 # 3ffffff <_entry-0x7c000001>
    80001a4a:	0a32                	slli	s4,s4,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4c:	00016a97          	auipc	s5,0x16
    80001a50:	11ca8a93          	addi	s5,s5,284 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001a54:	85e2                	mv	a1,s8
    80001a56:	854a                	mv	a0,s2
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	118080e7          	jalr	280(ra) # 80000b70 <initlock>
      char *pa = kalloc();
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	0b0080e7          	jalr	176(ra) # 80000b10 <kalloc>
    80001a68:	89aa                	mv	s3,a0
      if(pa == 0)
    80001a6a:	cd29                	beqz	a0,80001ac4 <procinit+0xca>
      uint64 va = KSTACK((int) (p - proc));
    80001a6c:	417904b3          	sub	s1,s2,s7
    80001a70:	848d                	srai	s1,s1,0x3
    80001a72:	000b3783          	ld	a5,0(s6)
    80001a76:	02f484b3          	mul	s1,s1,a5
    80001a7a:	2485                	addiw	s1,s1,1
    80001a7c:	00d4949b          	slliw	s1,s1,0xd
    80001a80:	409a04b3          	sub	s1,s4,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a84:	4699                	li	a3,6
    80001a86:	6605                	lui	a2,0x1
    80001a88:	85aa                	mv	a1,a0
    80001a8a:	8526                	mv	a0,s1
    80001a8c:	fffff097          	auipc	ra,0xfffff
    80001a90:	734080e7          	jalr	1844(ra) # 800011c0 <kvmmap>
      p->kstack = va;
    80001a94:	04993023          	sd	s1,64(s2)
      p->kstack_pa = (uint64)pa;
    80001a98:	17393823          	sd	s3,368(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9c:	17890913          	addi	s2,s2,376
    80001aa0:	fb591ae3          	bne	s2,s5,80001a54 <procinit+0x5a>
  kvminithart();
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	524080e7          	jalr	1316(ra) # 80000fc8 <kvminithart>
}
    80001aac:	60a6                	ld	ra,72(sp)
    80001aae:	6406                	ld	s0,64(sp)
    80001ab0:	74e2                	ld	s1,56(sp)
    80001ab2:	7942                	ld	s2,48(sp)
    80001ab4:	79a2                	ld	s3,40(sp)
    80001ab6:	7a02                	ld	s4,32(sp)
    80001ab8:	6ae2                	ld	s5,24(sp)
    80001aba:	6b42                	ld	s6,16(sp)
    80001abc:	6ba2                	ld	s7,8(sp)
    80001abe:	6c02                	ld	s8,0(sp)
    80001ac0:	6161                	addi	sp,sp,80
    80001ac2:	8082                	ret
        panic("kalloc");
    80001ac4:	00006517          	auipc	a0,0x6
    80001ac8:	71c50513          	addi	a0,a0,1820 # 800081e0 <digits+0x1a0>
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	a7a080e7          	jalr	-1414(ra) # 80000546 <panic>

0000000080001ad4 <cpuid>:
{
    80001ad4:	1141                	addi	sp,sp,-16
    80001ad6:	e422                	sd	s0,8(sp)
    80001ad8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ada:	8512                	mv	a0,tp
}
    80001adc:	2501                	sext.w	a0,a0
    80001ade:	6422                	ld	s0,8(sp)
    80001ae0:	0141                	addi	sp,sp,16
    80001ae2:	8082                	ret

0000000080001ae4 <mycpu>:
mycpu(void) {
    80001ae4:	1141                	addi	sp,sp,-16
    80001ae6:	e422                	sd	s0,8(sp)
    80001ae8:	0800                	addi	s0,sp,16
    80001aea:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aec:	2781                	sext.w	a5,a5
    80001aee:	079e                	slli	a5,a5,0x7
}
    80001af0:	00010517          	auipc	a0,0x10
    80001af4:	e7850513          	addi	a0,a0,-392 # 80011968 <cpus>
    80001af8:	953e                	add	a0,a0,a5
    80001afa:	6422                	ld	s0,8(sp)
    80001afc:	0141                	addi	sp,sp,16
    80001afe:	8082                	ret

0000000080001b00 <myproc>:
myproc(void) {
    80001b00:	1101                	addi	sp,sp,-32
    80001b02:	ec06                	sd	ra,24(sp)
    80001b04:	e822                	sd	s0,16(sp)
    80001b06:	e426                	sd	s1,8(sp)
    80001b08:	1000                	addi	s0,sp,32
  push_off();
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	0aa080e7          	jalr	170(ra) # 80000bb4 <push_off>
    80001b12:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b14:	2781                	sext.w	a5,a5
    80001b16:	079e                	slli	a5,a5,0x7
    80001b18:	00010717          	auipc	a4,0x10
    80001b1c:	e3870713          	addi	a4,a4,-456 # 80011950 <pid_lock>
    80001b20:	97ba                	add	a5,a5,a4
    80001b22:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b24:	fffff097          	auipc	ra,0xfffff
    80001b28:	130080e7          	jalr	304(ra) # 80000c54 <pop_off>
}
    80001b2c:	8526                	mv	a0,s1
    80001b2e:	60e2                	ld	ra,24(sp)
    80001b30:	6442                	ld	s0,16(sp)
    80001b32:	64a2                	ld	s1,8(sp)
    80001b34:	6105                	addi	sp,sp,32
    80001b36:	8082                	ret

0000000080001b38 <forkret>:
{
    80001b38:	1141                	addi	sp,sp,-16
    80001b3a:	e406                	sd	ra,8(sp)
    80001b3c:	e022                	sd	s0,0(sp)
    80001b3e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b40:	00000097          	auipc	ra,0x0
    80001b44:	fc0080e7          	jalr	-64(ra) # 80001b00 <myproc>
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	16c080e7          	jalr	364(ra) # 80000cb4 <release>
  if (first) {
    80001b50:	00007797          	auipc	a5,0x7
    80001b54:	d707a783          	lw	a5,-656(a5) # 800088c0 <first.1>
    80001b58:	eb89                	bnez	a5,80001b6a <forkret+0x32>
  usertrapret();
    80001b5a:	00001097          	auipc	ra,0x1
    80001b5e:	cbc080e7          	jalr	-836(ra) # 80002816 <usertrapret>
}
    80001b62:	60a2                	ld	ra,8(sp)
    80001b64:	6402                	ld	s0,0(sp)
    80001b66:	0141                	addi	sp,sp,16
    80001b68:	8082                	ret
    first = 0;
    80001b6a:	00007797          	auipc	a5,0x7
    80001b6e:	d407ab23          	sw	zero,-682(a5) # 800088c0 <first.1>
    fsinit(ROOTDEV);
    80001b72:	4505                	li	a0,1
    80001b74:	00002097          	auipc	ra,0x2
    80001b78:	9fa080e7          	jalr	-1542(ra) # 8000356e <fsinit>
    80001b7c:	bff9                	j	80001b5a <forkret+0x22>

0000000080001b7e <allocpid>:
allocpid() {
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	e04a                	sd	s2,0(sp)
    80001b88:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b8a:	00010917          	auipc	s2,0x10
    80001b8e:	dc690913          	addi	s2,s2,-570 # 80011950 <pid_lock>
    80001b92:	854a                	mv	a0,s2
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	06c080e7          	jalr	108(ra) # 80000c00 <acquire>
  pid = nextpid;
    80001b9c:	00007797          	auipc	a5,0x7
    80001ba0:	d2878793          	addi	a5,a5,-728 # 800088c4 <nextpid>
    80001ba4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ba6:	0014871b          	addiw	a4,s1,1
    80001baa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bac:	854a                	mv	a0,s2
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	106080e7          	jalr	262(ra) # 80000cb4 <release>
}
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	60e2                	ld	ra,24(sp)
    80001bba:	6442                	ld	s0,16(sp)
    80001bbc:	64a2                	ld	s1,8(sp)
    80001bbe:	6902                	ld	s2,0(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <kvmfree>:
void kvmfree(pagetable_t pagetable){
    80001bc4:	7179                	addi	sp,sp,-48
    80001bc6:	f406                	sd	ra,40(sp)
    80001bc8:	f022                	sd	s0,32(sp)
    80001bca:	ec26                	sd	s1,24(sp)
    80001bcc:	e84a                	sd	s2,16(sp)
    80001bce:	e44e                	sd	s3,8(sp)
    80001bd0:	e052                	sd	s4,0(sp)
    80001bd2:	1800                	addi	s0,sp,48
    80001bd4:	8a2a                	mv	s4,a0
      for(int i = 0; i < 512; i++){
    80001bd6:	84aa                	mv	s1,a0
    80001bd8:	6905                	lui	s2,0x1
    80001bda:	992a                	add	s2,s2,a0
      if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001bdc:	4985                	li	s3,1
    80001bde:	a021                	j	80001be6 <kvmfree+0x22>
      for(int i = 0; i < 512; i++){
    80001be0:	04a1                	addi	s1,s1,8
    80001be2:	03248163          	beq	s1,s2,80001c04 <kvmfree+0x40>
      pte_t pte = pagetable[i];
    80001be6:	609c                	ld	a5,0(s1)
      if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001be8:	00f7f713          	andi	a4,a5,15
    80001bec:	ff371ae3          	bne	a4,s3,80001be0 <kvmfree+0x1c>
        uint64 child = PTE2PA(pte);
    80001bf0:	83a9                	srli	a5,a5,0xa
        kvmfree((pagetable_t)child);
    80001bf2:	00c79513          	slli	a0,a5,0xc
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	fce080e7          	jalr	-50(ra) # 80001bc4 <kvmfree>
        pagetable[i] = 0; 
    80001bfe:	0004b023          	sd	zero,0(s1)
    80001c02:	bff9                	j	80001be0 <kvmfree+0x1c>
  kfree((void*)pagetable);
    80001c04:	8552                	mv	a0,s4
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	e0c080e7          	jalr	-500(ra) # 80000a12 <kfree>
}
    80001c0e:	70a2                	ld	ra,40(sp)
    80001c10:	7402                	ld	s0,32(sp)
    80001c12:	64e2                	ld	s1,24(sp)
    80001c14:	6942                	ld	s2,16(sp)
    80001c16:	69a2                	ld	s3,8(sp)
    80001c18:	6a02                	ld	s4,0(sp)
    80001c1a:	6145                	addi	sp,sp,48
    80001c1c:	8082                	ret

0000000080001c1e <proc_pagetable>:
{
    80001c1e:	1101                	addi	sp,sp,-32
    80001c20:	ec06                	sd	ra,24(sp)
    80001c22:	e822                	sd	s0,16(sp)
    80001c24:	e426                	sd	s1,8(sp)
    80001c26:	e04a                	sd	s2,0(sp)
    80001c28:	1000                	addi	s0,sp,32
    80001c2a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c2c:	00000097          	auipc	ra,0x0
    80001c30:	85e080e7          	jalr	-1954(ra) # 8000148a <uvmcreate>
    80001c34:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c36:	c121                	beqz	a0,80001c76 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c38:	4729                	li	a4,10
    80001c3a:	00005697          	auipc	a3,0x5
    80001c3e:	3c668693          	addi	a3,a3,966 # 80007000 <_trampoline>
    80001c42:	6605                	lui	a2,0x1
    80001c44:	040005b7          	lui	a1,0x4000
    80001c48:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c4a:	05b2                	slli	a1,a1,0xc
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	4e6080e7          	jalr	1254(ra) # 80001132 <mappages>
    80001c54:	02054863          	bltz	a0,80001c84 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c58:	4719                	li	a4,6
    80001c5a:	05893683          	ld	a3,88(s2) # 1058 <_entry-0x7fffefa8>
    80001c5e:	6605                	lui	a2,0x1
    80001c60:	020005b7          	lui	a1,0x2000
    80001c64:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c66:	05b6                	slli	a1,a1,0xd
    80001c68:	8526                	mv	a0,s1
    80001c6a:	fffff097          	auipc	ra,0xfffff
    80001c6e:	4c8080e7          	jalr	1224(ra) # 80001132 <mappages>
    80001c72:	02054163          	bltz	a0,80001c94 <proc_pagetable+0x76>
}
    80001c76:	8526                	mv	a0,s1
    80001c78:	60e2                	ld	ra,24(sp)
    80001c7a:	6442                	ld	s0,16(sp)
    80001c7c:	64a2                	ld	s1,8(sp)
    80001c7e:	6902                	ld	s2,0(sp)
    80001c80:	6105                	addi	sp,sp,32
    80001c82:	8082                	ret
    uvmfree(pagetable, 0);
    80001c84:	4581                	li	a1,0
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	a00080e7          	jalr	-1536(ra) # 80001688 <uvmfree>
    return 0;
    80001c90:	4481                	li	s1,0
    80001c92:	b7d5                	j	80001c76 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c94:	4681                	li	a3,0
    80001c96:	4605                	li	a2,1
    80001c98:	040005b7          	lui	a1,0x4000
    80001c9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c9e:	05b2                	slli	a1,a1,0xc
    80001ca0:	8526                	mv	a0,s1
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	724080e7          	jalr	1828(ra) # 800013c6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001caa:	4581                	li	a1,0
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	9da080e7          	jalr	-1574(ra) # 80001688 <uvmfree>
    return 0;
    80001cb6:	4481                	li	s1,0
    80001cb8:	bf7d                	j	80001c76 <proc_pagetable+0x58>

0000000080001cba <proc_freepagetable>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	e04a                	sd	s2,0(sp)
    80001cc4:	1000                	addi	s0,sp,32
    80001cc6:	84aa                	mv	s1,a0
    80001cc8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cca:	4681                	li	a3,0
    80001ccc:	4605                	li	a2,1
    80001cce:	040005b7          	lui	a1,0x4000
    80001cd2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001cd4:	05b2                	slli	a1,a1,0xc
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	6f0080e7          	jalr	1776(ra) # 800013c6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cde:	4681                	li	a3,0
    80001ce0:	4605                	li	a2,1
    80001ce2:	020005b7          	lui	a1,0x2000
    80001ce6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ce8:	05b6                	slli	a1,a1,0xd
    80001cea:	8526                	mv	a0,s1
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	6da080e7          	jalr	1754(ra) # 800013c6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cf4:	85ca                	mv	a1,s2
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	00000097          	auipc	ra,0x0
    80001cfc:	990080e7          	jalr	-1648(ra) # 80001688 <uvmfree>
}
    80001d00:	60e2                	ld	ra,24(sp)
    80001d02:	6442                	ld	s0,16(sp)
    80001d04:	64a2                	ld	s1,8(sp)
    80001d06:	6902                	ld	s2,0(sp)
    80001d08:	6105                	addi	sp,sp,32
    80001d0a:	8082                	ret

0000000080001d0c <freeproc>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	1000                	addi	s0,sp,32
    80001d16:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d18:	6d28                	ld	a0,88(a0)
    80001d1a:	c509                	beqz	a0,80001d24 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	cf6080e7          	jalr	-778(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001d24:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001d28:	68a8                	ld	a0,80(s1)
    80001d2a:	c511                	beqz	a0,80001d36 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d2c:	64ac                	ld	a1,72(s1)
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	f8c080e7          	jalr	-116(ra) # 80001cba <proc_freepagetable>
  if(p->kpagetable){
    80001d36:	1684b503          	ld	a0,360(s1)
    80001d3a:	c509                	beqz	a0,80001d44 <freeproc+0x38>
    kvmfree(p->kpagetable);
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	e88080e7          	jalr	-376(ra) # 80001bc4 <kvmfree>
  p->pagetable = 0;
    80001d44:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d48:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d4c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d50:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d54:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d58:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d5c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d60:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d64:	0004ac23          	sw	zero,24(s1)
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <allocproc>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d7e:	00010497          	auipc	s1,0x10
    80001d82:	fea48493          	addi	s1,s1,-22 # 80011d68 <proc>
    80001d86:	00016917          	auipc	s2,0x16
    80001d8a:	de290913          	addi	s2,s2,-542 # 80017b68 <tickslock>
    acquire(&p->lock);
    80001d8e:	8526                	mv	a0,s1
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	e70080e7          	jalr	-400(ra) # 80000c00 <acquire>
    if(p->state == UNUSED) {
    80001d98:	4c9c                	lw	a5,24(s1)
    80001d9a:	cf81                	beqz	a5,80001db2 <allocproc+0x40>
      release(&p->lock);
    80001d9c:	8526                	mv	a0,s1
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	f16080e7          	jalr	-234(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001da6:	17848493          	addi	s1,s1,376
    80001daa:	ff2492e3          	bne	s1,s2,80001d8e <allocproc+0x1c>
  return 0;
    80001dae:	4481                	li	s1,0
    80001db0:	a0b5                	j	80001e1c <allocproc+0xaa>
      p->kpagetable=kvminit_proc();
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	548080e7          	jalr	1352(ra) # 800012fa <kvminit_proc>
    80001dba:	16a4b423          	sd	a0,360(s1)
      kvmmap_proc(p->kpagetable, p->kstack, p->kstack_pa, PGSIZE, PTE_R | PTE_W);
    80001dbe:	4719                	li	a4,6
    80001dc0:	6685                	lui	a3,0x1
    80001dc2:	1704b603          	ld	a2,368(s1)
    80001dc6:	60ac                	ld	a1,64(s1)
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	502080e7          	jalr	1282(ra) # 800012ca <kvmmap_proc>
  p->pid = allocpid();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	dae080e7          	jalr	-594(ra) # 80001b7e <allocpid>
    80001dd8:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	d36080e7          	jalr	-714(ra) # 80000b10 <kalloc>
    80001de2:	892a                	mv	s2,a0
    80001de4:	eca8                	sd	a0,88(s1)
    80001de6:	c131                	beqz	a0,80001e2a <allocproc+0xb8>
  p->pagetable = proc_pagetable(p);
    80001de8:	8526                	mv	a0,s1
    80001dea:	00000097          	auipc	ra,0x0
    80001dee:	e34080e7          	jalr	-460(ra) # 80001c1e <proc_pagetable>
    80001df2:	892a                	mv	s2,a0
    80001df4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001df6:	c129                	beqz	a0,80001e38 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001df8:	07000613          	li	a2,112
    80001dfc:	4581                	li	a1,0
    80001dfe:	06048513          	addi	a0,s1,96
    80001e02:	fffff097          	auipc	ra,0xfffff
    80001e06:	efa080e7          	jalr	-262(ra) # 80000cfc <memset>
  p->context.ra = (uint64)forkret;
    80001e0a:	00000797          	auipc	a5,0x0
    80001e0e:	d2e78793          	addi	a5,a5,-722 # 80001b38 <forkret>
    80001e12:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e14:	60bc                	ld	a5,64(s1)
    80001e16:	6705                	lui	a4,0x1
    80001e18:	97ba                	add	a5,a5,a4
    80001e1a:	f4bc                	sd	a5,104(s1)
}
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	60e2                	ld	ra,24(sp)
    80001e20:	6442                	ld	s0,16(sp)
    80001e22:	64a2                	ld	s1,8(sp)
    80001e24:	6902                	ld	s2,0(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret
    release(&p->lock);
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	fffff097          	auipc	ra,0xfffff
    80001e30:	e88080e7          	jalr	-376(ra) # 80000cb4 <release>
    return 0;
    80001e34:	84ca                	mv	s1,s2
    80001e36:	b7dd                	j	80001e1c <allocproc+0xaa>
    freeproc(p);
    80001e38:	8526                	mv	a0,s1
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	ed2080e7          	jalr	-302(ra) # 80001d0c <freeproc>
    release(&p->lock);
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	e70080e7          	jalr	-400(ra) # 80000cb4 <release>
    return 0;
    80001e4c:	84ca                	mv	s1,s2
    80001e4e:	b7f9                	j	80001e1c <allocproc+0xaa>

0000000080001e50 <userinit>:
{
    80001e50:	1101                	addi	sp,sp,-32
    80001e52:	ec06                	sd	ra,24(sp)
    80001e54:	e822                	sd	s0,16(sp)
    80001e56:	e426                	sd	s1,8(sp)
    80001e58:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	f18080e7          	jalr	-232(ra) # 80001d72 <allocproc>
    80001e62:	84aa                	mv	s1,a0
  initproc = p;
    80001e64:	00007797          	auipc	a5,0x7
    80001e68:	1aa7ba23          	sd	a0,436(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e6c:	03400613          	li	a2,52
    80001e70:	00007597          	auipc	a1,0x7
    80001e74:	a6058593          	addi	a1,a1,-1440 # 800088d0 <initcode>
    80001e78:	6928                	ld	a0,80(a0)
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	63e080e7          	jalr	1598(ra) # 800014b8 <uvminit>
  p->sz = PGSIZE;
    80001e82:	6785                	lui	a5,0x1
    80001e84:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e86:	6cb8                	ld	a4,88(s1)
    80001e88:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e8c:	6cb8                	ld	a4,88(s1)
    80001e8e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e90:	4641                	li	a2,16
    80001e92:	00006597          	auipc	a1,0x6
    80001e96:	35658593          	addi	a1,a1,854 # 800081e8 <digits+0x1a8>
    80001e9a:	15848513          	addi	a0,s1,344
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	fb0080e7          	jalr	-80(ra) # 80000e4e <safestrcpy>
  p->cwd = namei("/");
    80001ea6:	00006517          	auipc	a0,0x6
    80001eaa:	35250513          	addi	a0,a0,850 # 800081f8 <digits+0x1b8>
    80001eae:	00002097          	auipc	ra,0x2
    80001eb2:	0f0080e7          	jalr	240(ra) # 80003f9e <namei>
    80001eb6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eba:	4789                	li	a5,2
    80001ebc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	df4080e7          	jalr	-524(ra) # 80000cb4 <release>
}
    80001ec8:	60e2                	ld	ra,24(sp)
    80001eca:	6442                	ld	s0,16(sp)
    80001ecc:	64a2                	ld	s1,8(sp)
    80001ece:	6105                	addi	sp,sp,32
    80001ed0:	8082                	ret

0000000080001ed2 <growproc>:
{
    80001ed2:	1101                	addi	sp,sp,-32
    80001ed4:	ec06                	sd	ra,24(sp)
    80001ed6:	e822                	sd	s0,16(sp)
    80001ed8:	e426                	sd	s1,8(sp)
    80001eda:	e04a                	sd	s2,0(sp)
    80001edc:	1000                	addi	s0,sp,32
    80001ede:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	c20080e7          	jalr	-992(ra) # 80001b00 <myproc>
    80001ee8:	892a                	mv	s2,a0
  sz = p->sz;
    80001eea:	652c                	ld	a1,72(a0)
    80001eec:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001ef0:	00904f63          	bgtz	s1,80001f0e <growproc+0x3c>
  } else if(n < 0){
    80001ef4:	0204cd63          	bltz	s1,80001f2e <growproc+0x5c>
  p->sz = sz;
    80001ef8:	1782                	slli	a5,a5,0x20
    80001efa:	9381                	srli	a5,a5,0x20
    80001efc:	04f93423          	sd	a5,72(s2)
  return 0;
    80001f00:	4501                	li	a0,0
}
    80001f02:	60e2                	ld	ra,24(sp)
    80001f04:	6442                	ld	s0,16(sp)
    80001f06:	64a2                	ld	s1,8(sp)
    80001f08:	6902                	ld	s2,0(sp)
    80001f0a:	6105                	addi	sp,sp,32
    80001f0c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f0e:	00f4863b          	addw	a2,s1,a5
    80001f12:	1602                	slli	a2,a2,0x20
    80001f14:	9201                	srli	a2,a2,0x20
    80001f16:	1582                	slli	a1,a1,0x20
    80001f18:	9181                	srli	a1,a1,0x20
    80001f1a:	6928                	ld	a0,80(a0)
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	656080e7          	jalr	1622(ra) # 80001572 <uvmalloc>
    80001f24:	0005079b          	sext.w	a5,a0
    80001f28:	fbe1                	bnez	a5,80001ef8 <growproc+0x26>
      return -1;
    80001f2a:	557d                	li	a0,-1
    80001f2c:	bfd9                	j	80001f02 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f2e:	00f4863b          	addw	a2,s1,a5
    80001f32:	1602                	slli	a2,a2,0x20
    80001f34:	9201                	srli	a2,a2,0x20
    80001f36:	1582                	slli	a1,a1,0x20
    80001f38:	9181                	srli	a1,a1,0x20
    80001f3a:	6928                	ld	a0,80(a0)
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	5ee080e7          	jalr	1518(ra) # 8000152a <uvmdealloc>
    80001f44:	0005079b          	sext.w	a5,a0
    80001f48:	bf45                	j	80001ef8 <growproc+0x26>

0000000080001f4a <fork>:
{
    80001f4a:	7139                	addi	sp,sp,-64
    80001f4c:	fc06                	sd	ra,56(sp)
    80001f4e:	f822                	sd	s0,48(sp)
    80001f50:	f426                	sd	s1,40(sp)
    80001f52:	f04a                	sd	s2,32(sp)
    80001f54:	ec4e                	sd	s3,24(sp)
    80001f56:	e852                	sd	s4,16(sp)
    80001f58:	e456                	sd	s5,8(sp)
    80001f5a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	ba4080e7          	jalr	-1116(ra) # 80001b00 <myproc>
    80001f64:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	e0c080e7          	jalr	-500(ra) # 80001d72 <allocproc>
    80001f6e:	c17d                	beqz	a0,80002054 <fork+0x10a>
    80001f70:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f72:	048ab603          	ld	a2,72(s5)
    80001f76:	692c                	ld	a1,80(a0)
    80001f78:	050ab503          	ld	a0,80(s5)
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	746080e7          	jalr	1862(ra) # 800016c2 <uvmcopy>
    80001f84:	04054a63          	bltz	a0,80001fd8 <fork+0x8e>
  np->sz = p->sz;
    80001f88:	048ab783          	ld	a5,72(s5)
    80001f8c:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001f90:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f94:	058ab683          	ld	a3,88(s5)
    80001f98:	87b6                	mv	a5,a3
    80001f9a:	058a3703          	ld	a4,88(s4)
    80001f9e:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80001fa2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fa6:	6788                	ld	a0,8(a5)
    80001fa8:	6b8c                	ld	a1,16(a5)
    80001faa:	6f90                	ld	a2,24(a5)
    80001fac:	01073023          	sd	a6,0(a4)
    80001fb0:	e708                	sd	a0,8(a4)
    80001fb2:	eb0c                	sd	a1,16(a4)
    80001fb4:	ef10                	sd	a2,24(a4)
    80001fb6:	02078793          	addi	a5,a5,32
    80001fba:	02070713          	addi	a4,a4,32
    80001fbe:	fed792e3          	bne	a5,a3,80001fa2 <fork+0x58>
  np->trapframe->a0 = 0;
    80001fc2:	058a3783          	ld	a5,88(s4)
    80001fc6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001fca:	0d0a8493          	addi	s1,s5,208
    80001fce:	0d0a0913          	addi	s2,s4,208
    80001fd2:	150a8993          	addi	s3,s5,336
    80001fd6:	a00d                	j	80001ff8 <fork+0xae>
    freeproc(np);
    80001fd8:	8552                	mv	a0,s4
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	d32080e7          	jalr	-718(ra) # 80001d0c <freeproc>
    release(&np->lock);
    80001fe2:	8552                	mv	a0,s4
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	cd0080e7          	jalr	-816(ra) # 80000cb4 <release>
    return -1;
    80001fec:	54fd                	li	s1,-1
    80001fee:	a889                	j	80002040 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001ff0:	04a1                	addi	s1,s1,8
    80001ff2:	0921                	addi	s2,s2,8
    80001ff4:	01348b63          	beq	s1,s3,8000200a <fork+0xc0>
    if(p->ofile[i])
    80001ff8:	6088                	ld	a0,0(s1)
    80001ffa:	d97d                	beqz	a0,80001ff0 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ffc:	00002097          	auipc	ra,0x2
    80002000:	62e080e7          	jalr	1582(ra) # 8000462a <filedup>
    80002004:	00a93023          	sd	a0,0(s2)
    80002008:	b7e5                	j	80001ff0 <fork+0xa6>
  np->cwd = idup(p->cwd);
    8000200a:	150ab503          	ld	a0,336(s5)
    8000200e:	00001097          	auipc	ra,0x1
    80002012:	79c080e7          	jalr	1948(ra) # 800037aa <idup>
    80002016:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000201a:	4641                	li	a2,16
    8000201c:	158a8593          	addi	a1,s5,344
    80002020:	158a0513          	addi	a0,s4,344
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	e2a080e7          	jalr	-470(ra) # 80000e4e <safestrcpy>
  pid = np->pid;
    8000202c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80002030:	4789                	li	a5,2
    80002032:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002036:	8552                	mv	a0,s4
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c7c080e7          	jalr	-900(ra) # 80000cb4 <release>
}
    80002040:	8526                	mv	a0,s1
    80002042:	70e2                	ld	ra,56(sp)
    80002044:	7442                	ld	s0,48(sp)
    80002046:	74a2                	ld	s1,40(sp)
    80002048:	7902                	ld	s2,32(sp)
    8000204a:	69e2                	ld	s3,24(sp)
    8000204c:	6a42                	ld	s4,16(sp)
    8000204e:	6aa2                	ld	s5,8(sp)
    80002050:	6121                	addi	sp,sp,64
    80002052:	8082                	ret
    return -1;
    80002054:	54fd                	li	s1,-1
    80002056:	b7ed                	j	80002040 <fork+0xf6>

0000000080002058 <reparent>:
{
    80002058:	7179                	addi	sp,sp,-48
    8000205a:	f406                	sd	ra,40(sp)
    8000205c:	f022                	sd	s0,32(sp)
    8000205e:	ec26                	sd	s1,24(sp)
    80002060:	e84a                	sd	s2,16(sp)
    80002062:	e44e                	sd	s3,8(sp)
    80002064:	e052                	sd	s4,0(sp)
    80002066:	1800                	addi	s0,sp,48
    80002068:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000206a:	00010497          	auipc	s1,0x10
    8000206e:	cfe48493          	addi	s1,s1,-770 # 80011d68 <proc>
      pp->parent = initproc;
    80002072:	00007a17          	auipc	s4,0x7
    80002076:	fa6a0a13          	addi	s4,s4,-90 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000207a:	00016997          	auipc	s3,0x16
    8000207e:	aee98993          	addi	s3,s3,-1298 # 80017b68 <tickslock>
    80002082:	a029                	j	8000208c <reparent+0x34>
    80002084:	17848493          	addi	s1,s1,376
    80002088:	03348363          	beq	s1,s3,800020ae <reparent+0x56>
    if(pp->parent == p){
    8000208c:	709c                	ld	a5,32(s1)
    8000208e:	ff279be3          	bne	a5,s2,80002084 <reparent+0x2c>
      acquire(&pp->lock);
    80002092:	8526                	mv	a0,s1
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	b6c080e7          	jalr	-1172(ra) # 80000c00 <acquire>
      pp->parent = initproc;
    8000209c:	000a3783          	ld	a5,0(s4)
    800020a0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	c10080e7          	jalr	-1008(ra) # 80000cb4 <release>
    800020ac:	bfe1                	j	80002084 <reparent+0x2c>
}
    800020ae:	70a2                	ld	ra,40(sp)
    800020b0:	7402                	ld	s0,32(sp)
    800020b2:	64e2                	ld	s1,24(sp)
    800020b4:	6942                	ld	s2,16(sp)
    800020b6:	69a2                	ld	s3,8(sp)
    800020b8:	6a02                	ld	s4,0(sp)
    800020ba:	6145                	addi	sp,sp,48
    800020bc:	8082                	ret

00000000800020be <scheduler>:
{
    800020be:	715d                	addi	sp,sp,-80
    800020c0:	e486                	sd	ra,72(sp)
    800020c2:	e0a2                	sd	s0,64(sp)
    800020c4:	fc26                	sd	s1,56(sp)
    800020c6:	f84a                	sd	s2,48(sp)
    800020c8:	f44e                	sd	s3,40(sp)
    800020ca:	f052                	sd	s4,32(sp)
    800020cc:	ec56                	sd	s5,24(sp)
    800020ce:	e85a                	sd	s6,16(sp)
    800020d0:	e45e                	sd	s7,8(sp)
    800020d2:	e062                	sd	s8,0(sp)
    800020d4:	0880                	addi	s0,sp,80
    800020d6:	8792                	mv	a5,tp
  int id = r_tp();
    800020d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020da:	00779b13          	slli	s6,a5,0x7
    800020de:	00010717          	auipc	a4,0x10
    800020e2:	87270713          	addi	a4,a4,-1934 # 80011950 <pid_lock>
    800020e6:	975a                	add	a4,a4,s6
    800020e8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800020ec:	00010717          	auipc	a4,0x10
    800020f0:	88470713          	addi	a4,a4,-1916 # 80011970 <cpus+0x8>
    800020f4:	9b3a                	add	s6,s6,a4
        c->proc = p;
    800020f6:	079e                	slli	a5,a5,0x7
    800020f8:	00010a17          	auipc	s4,0x10
    800020fc:	858a0a13          	addi	s4,s4,-1960 # 80011950 <pid_lock>
    80002100:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    80002102:	5bfd                	li	s7,-1
    80002104:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	00016997          	auipc	s3,0x16
    8000210a:	a6298993          	addi	s3,s3,-1438 # 80017b68 <tickslock>
    8000210e:	a885                	j	8000217e <scheduler+0xc0>
      release(&p->lock);
    80002110:	8526                	mv	a0,s1
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ba2080e7          	jalr	-1118(ra) # 80000cb4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000211a:	17848493          	addi	s1,s1,376
    8000211e:	05348263          	beq	s1,s3,80002162 <scheduler+0xa4>
      acquire(&p->lock);
    80002122:	8526                	mv	a0,s1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	adc080e7          	jalr	-1316(ra) # 80000c00 <acquire>
      if(p->state == RUNNABLE) {
    8000212c:	4c9c                	lw	a5,24(s1)
    8000212e:	ff2791e3          	bne	a5,s2,80002110 <scheduler+0x52>
        p->state = RUNNING;
    80002132:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80002136:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    8000213a:	1684b783          	ld	a5,360(s1)
    8000213e:	83b1                	srli	a5,a5,0xc
    80002140:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80002144:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80002148:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    8000214c:	06048593          	addi	a1,s1,96
    80002150:	855a                	mv	a0,s6
    80002152:	00000097          	auipc	ra,0x0
    80002156:	61a080e7          	jalr	1562(ra) # 8000276c <swtch>
        c->proc = 0; // cpu dosen't run any process now
    8000215a:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000215e:	4c05                	li	s8,1
    80002160:	bf45                	j	80002110 <scheduler+0x52>
      kvminithart();// no process running change to default pagetable
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	e66080e7          	jalr	-410(ra) # 80000fc8 <kvminithart>
    if(found == 0) {
    8000216a:	000c1a63          	bnez	s8,8000217e <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000216e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002172:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002176:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000217a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000217e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002182:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002186:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000218a:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000218c:	00010497          	auipc	s1,0x10
    80002190:	bdc48493          	addi	s1,s1,-1060 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002194:	4909                	li	s2,2
        p->state = RUNNING;
    80002196:	4a8d                	li	s5,3
    80002198:	b769                	j	80002122 <scheduler+0x64>

000000008000219a <sched>:
{
    8000219a:	7179                	addi	sp,sp,-48
    8000219c:	f406                	sd	ra,40(sp)
    8000219e:	f022                	sd	s0,32(sp)
    800021a0:	ec26                	sd	s1,24(sp)
    800021a2:	e84a                	sd	s2,16(sp)
    800021a4:	e44e                	sd	s3,8(sp)
    800021a6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	958080e7          	jalr	-1704(ra) # 80001b00 <myproc>
    800021b0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	9d4080e7          	jalr	-1580(ra) # 80000b86 <holding>
    800021ba:	c93d                	beqz	a0,80002230 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021bc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021be:	2781                	sext.w	a5,a5
    800021c0:	079e                	slli	a5,a5,0x7
    800021c2:	0000f717          	auipc	a4,0xf
    800021c6:	78e70713          	addi	a4,a4,1934 # 80011950 <pid_lock>
    800021ca:	97ba                	add	a5,a5,a4
    800021cc:	0907a703          	lw	a4,144(a5)
    800021d0:	4785                	li	a5,1
    800021d2:	06f71763          	bne	a4,a5,80002240 <sched+0xa6>
  if(p->state == RUNNING)
    800021d6:	4c98                	lw	a4,24(s1)
    800021d8:	478d                	li	a5,3
    800021da:	06f70b63          	beq	a4,a5,80002250 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021de:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021e2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021e4:	efb5                	bnez	a5,80002260 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021e6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021e8:	0000f917          	auipc	s2,0xf
    800021ec:	76890913          	addi	s2,s2,1896 # 80011950 <pid_lock>
    800021f0:	2781                	sext.w	a5,a5
    800021f2:	079e                	slli	a5,a5,0x7
    800021f4:	97ca                	add	a5,a5,s2
    800021f6:	0947a983          	lw	s3,148(a5)
    800021fa:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021fc:	2781                	sext.w	a5,a5
    800021fe:	079e                	slli	a5,a5,0x7
    80002200:	0000f597          	auipc	a1,0xf
    80002204:	77058593          	addi	a1,a1,1904 # 80011970 <cpus+0x8>
    80002208:	95be                	add	a1,a1,a5
    8000220a:	06048513          	addi	a0,s1,96
    8000220e:	00000097          	auipc	ra,0x0
    80002212:	55e080e7          	jalr	1374(ra) # 8000276c <swtch>
    80002216:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002218:	2781                	sext.w	a5,a5
    8000221a:	079e                	slli	a5,a5,0x7
    8000221c:	993e                	add	s2,s2,a5
    8000221e:	09392a23          	sw	s3,148(s2)
}
    80002222:	70a2                	ld	ra,40(sp)
    80002224:	7402                	ld	s0,32(sp)
    80002226:	64e2                	ld	s1,24(sp)
    80002228:	6942                	ld	s2,16(sp)
    8000222a:	69a2                	ld	s3,8(sp)
    8000222c:	6145                	addi	sp,sp,48
    8000222e:	8082                	ret
    panic("sched p->lock");
    80002230:	00006517          	auipc	a0,0x6
    80002234:	fd050513          	addi	a0,a0,-48 # 80008200 <digits+0x1c0>
    80002238:	ffffe097          	auipc	ra,0xffffe
    8000223c:	30e080e7          	jalr	782(ra) # 80000546 <panic>
    panic("sched locks");
    80002240:	00006517          	auipc	a0,0x6
    80002244:	fd050513          	addi	a0,a0,-48 # 80008210 <digits+0x1d0>
    80002248:	ffffe097          	auipc	ra,0xffffe
    8000224c:	2fe080e7          	jalr	766(ra) # 80000546 <panic>
    panic("sched running");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	fd050513          	addi	a0,a0,-48 # 80008220 <digits+0x1e0>
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	2ee080e7          	jalr	750(ra) # 80000546 <panic>
    panic("sched interruptible");
    80002260:	00006517          	auipc	a0,0x6
    80002264:	fd050513          	addi	a0,a0,-48 # 80008230 <digits+0x1f0>
    80002268:	ffffe097          	auipc	ra,0xffffe
    8000226c:	2de080e7          	jalr	734(ra) # 80000546 <panic>

0000000080002270 <exit>:
{
    80002270:	7179                	addi	sp,sp,-48
    80002272:	f406                	sd	ra,40(sp)
    80002274:	f022                	sd	s0,32(sp)
    80002276:	ec26                	sd	s1,24(sp)
    80002278:	e84a                	sd	s2,16(sp)
    8000227a:	e44e                	sd	s3,8(sp)
    8000227c:	e052                	sd	s4,0(sp)
    8000227e:	1800                	addi	s0,sp,48
    80002280:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002282:	00000097          	auipc	ra,0x0
    80002286:	87e080e7          	jalr	-1922(ra) # 80001b00 <myproc>
    8000228a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000228c:	00007797          	auipc	a5,0x7
    80002290:	d8c7b783          	ld	a5,-628(a5) # 80009018 <initproc>
    80002294:	0d050493          	addi	s1,a0,208
    80002298:	15050913          	addi	s2,a0,336
    8000229c:	02a79363          	bne	a5,a0,800022c2 <exit+0x52>
    panic("init exiting");
    800022a0:	00006517          	auipc	a0,0x6
    800022a4:	fa850513          	addi	a0,a0,-88 # 80008248 <digits+0x208>
    800022a8:	ffffe097          	auipc	ra,0xffffe
    800022ac:	29e080e7          	jalr	670(ra) # 80000546 <panic>
      fileclose(f);
    800022b0:	00002097          	auipc	ra,0x2
    800022b4:	3cc080e7          	jalr	972(ra) # 8000467c <fileclose>
      p->ofile[fd] = 0;
    800022b8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022bc:	04a1                	addi	s1,s1,8
    800022be:	01248563          	beq	s1,s2,800022c8 <exit+0x58>
    if(p->ofile[fd]){
    800022c2:	6088                	ld	a0,0(s1)
    800022c4:	f575                	bnez	a0,800022b0 <exit+0x40>
    800022c6:	bfdd                	j	800022bc <exit+0x4c>
  begin_op();
    800022c8:	00002097          	auipc	ra,0x2
    800022cc:	ee6080e7          	jalr	-282(ra) # 800041ae <begin_op>
  iput(p->cwd);
    800022d0:	1509b503          	ld	a0,336(s3)
    800022d4:	00001097          	auipc	ra,0x1
    800022d8:	6ce080e7          	jalr	1742(ra) # 800039a2 <iput>
  end_op();
    800022dc:	00002097          	auipc	ra,0x2
    800022e0:	f50080e7          	jalr	-176(ra) # 8000422c <end_op>
  p->cwd = 0;
    800022e4:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022e8:	00007497          	auipc	s1,0x7
    800022ec:	d3048493          	addi	s1,s1,-720 # 80009018 <initproc>
    800022f0:	6088                	ld	a0,0(s1)
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	90e080e7          	jalr	-1778(ra) # 80000c00 <acquire>
  wakeup1(initproc);
    800022fa:	6088                	ld	a0,0(s1)
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	6ba080e7          	jalr	1722(ra) # 800019b6 <wakeup1>
  release(&initproc->lock);
    80002304:	6088                	ld	a0,0(s1)
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	9ae080e7          	jalr	-1618(ra) # 80000cb4 <release>
  acquire(&p->lock);
    8000230e:	854e                	mv	a0,s3
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	8f0080e7          	jalr	-1808(ra) # 80000c00 <acquire>
  struct proc *original_parent = p->parent;
    80002318:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000231c:	854e                	mv	a0,s3
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	996080e7          	jalr	-1642(ra) # 80000cb4 <release>
  acquire(&original_parent->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8d8080e7          	jalr	-1832(ra) # 80000c00 <acquire>
  acquire(&p->lock);
    80002330:	854e                	mv	a0,s3
    80002332:	fffff097          	auipc	ra,0xfffff
    80002336:	8ce080e7          	jalr	-1842(ra) # 80000c00 <acquire>
  reparent(p);
    8000233a:	854e                	mv	a0,s3
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	d1c080e7          	jalr	-740(ra) # 80002058 <reparent>
  wakeup1(original_parent);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	670080e7          	jalr	1648(ra) # 800019b6 <wakeup1>
  p->xstate = status;
    8000234e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002352:	4791                	li	a5,4
    80002354:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	95a080e7          	jalr	-1702(ra) # 80000cb4 <release>
  sched();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	e38080e7          	jalr	-456(ra) # 8000219a <sched>
  panic("zombie exit");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	eee50513          	addi	a0,a0,-274 # 80008258 <digits+0x218>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1d4080e7          	jalr	468(ra) # 80000546 <panic>

000000008000237a <yield>:
{
    8000237a:	1101                	addi	sp,sp,-32
    8000237c:	ec06                	sd	ra,24(sp)
    8000237e:	e822                	sd	s0,16(sp)
    80002380:	e426                	sd	s1,8(sp)
    80002382:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	77c080e7          	jalr	1916(ra) # 80001b00 <myproc>
    8000238c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	872080e7          	jalr	-1934(ra) # 80000c00 <acquire>
  p->state = RUNNABLE;
    80002396:	4789                	li	a5,2
    80002398:	cc9c                	sw	a5,24(s1)
  sched();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	e00080e7          	jalr	-512(ra) # 8000219a <sched>
  release(&p->lock);
    800023a2:	8526                	mv	a0,s1
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	910080e7          	jalr	-1776(ra) # 80000cb4 <release>
}
    800023ac:	60e2                	ld	ra,24(sp)
    800023ae:	6442                	ld	s0,16(sp)
    800023b0:	64a2                	ld	s1,8(sp)
    800023b2:	6105                	addi	sp,sp,32
    800023b4:	8082                	ret

00000000800023b6 <sleep>:
{
    800023b6:	7179                	addi	sp,sp,-48
    800023b8:	f406                	sd	ra,40(sp)
    800023ba:	f022                	sd	s0,32(sp)
    800023bc:	ec26                	sd	s1,24(sp)
    800023be:	e84a                	sd	s2,16(sp)
    800023c0:	e44e                	sd	s3,8(sp)
    800023c2:	1800                	addi	s0,sp,48
    800023c4:	89aa                	mv	s3,a0
    800023c6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	738080e7          	jalr	1848(ra) # 80001b00 <myproc>
    800023d0:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800023d2:	05250663          	beq	a0,s2,8000241e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	82a080e7          	jalr	-2006(ra) # 80000c00 <acquire>
    release(lk);
    800023de:	854a                	mv	a0,s2
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8d4080e7          	jalr	-1836(ra) # 80000cb4 <release>
  p->chan = chan;
    800023e8:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800023ec:	4785                	li	a5,1
    800023ee:	cc9c                	sw	a5,24(s1)
  sched();
    800023f0:	00000097          	auipc	ra,0x0
    800023f4:	daa080e7          	jalr	-598(ra) # 8000219a <sched>
  p->chan = 0;
    800023f8:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	8b6080e7          	jalr	-1866(ra) # 80000cb4 <release>
    acquire(lk);
    80002406:	854a                	mv	a0,s2
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7f8080e7          	jalr	2040(ra) # 80000c00 <acquire>
}
    80002410:	70a2                	ld	ra,40(sp)
    80002412:	7402                	ld	s0,32(sp)
    80002414:	64e2                	ld	s1,24(sp)
    80002416:	6942                	ld	s2,16(sp)
    80002418:	69a2                	ld	s3,8(sp)
    8000241a:	6145                	addi	sp,sp,48
    8000241c:	8082                	ret
  p->chan = chan;
    8000241e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002422:	4785                	li	a5,1
    80002424:	cd1c                	sw	a5,24(a0)
  sched();
    80002426:	00000097          	auipc	ra,0x0
    8000242a:	d74080e7          	jalr	-652(ra) # 8000219a <sched>
  p->chan = 0;
    8000242e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002432:	bff9                	j	80002410 <sleep+0x5a>

0000000080002434 <wait>:
{
    80002434:	715d                	addi	sp,sp,-80
    80002436:	e486                	sd	ra,72(sp)
    80002438:	e0a2                	sd	s0,64(sp)
    8000243a:	fc26                	sd	s1,56(sp)
    8000243c:	f84a                	sd	s2,48(sp)
    8000243e:	f44e                	sd	s3,40(sp)
    80002440:	f052                	sd	s4,32(sp)
    80002442:	ec56                	sd	s5,24(sp)
    80002444:	e85a                	sd	s6,16(sp)
    80002446:	e45e                	sd	s7,8(sp)
    80002448:	0880                	addi	s0,sp,80
    8000244a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	6b4080e7          	jalr	1716(ra) # 80001b00 <myproc>
    80002454:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	7aa080e7          	jalr	1962(ra) # 80000c00 <acquire>
    havekids = 0;
    8000245e:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002460:	4a11                	li	s4,4
        havekids = 1;
    80002462:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002464:	00015997          	auipc	s3,0x15
    80002468:	70498993          	addi	s3,s3,1796 # 80017b68 <tickslock>
    havekids = 0;
    8000246c:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000246e:	00010497          	auipc	s1,0x10
    80002472:	8fa48493          	addi	s1,s1,-1798 # 80011d68 <proc>
    80002476:	a08d                	j	800024d8 <wait+0xa4>
          pid = np->pid;
    80002478:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000247c:	000b0e63          	beqz	s6,80002498 <wait+0x64>
    80002480:	4691                	li	a3,4
    80002482:	03448613          	addi	a2,s1,52
    80002486:	85da                	mv	a1,s6
    80002488:	05093503          	ld	a0,80(s2)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	33a080e7          	jalr	826(ra) # 800017c6 <copyout>
    80002494:	02054263          	bltz	a0,800024b8 <wait+0x84>
          freeproc(np);
    80002498:	8526                	mv	a0,s1
    8000249a:	00000097          	auipc	ra,0x0
    8000249e:	872080e7          	jalr	-1934(ra) # 80001d0c <freeproc>
          release(&np->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	810080e7          	jalr	-2032(ra) # 80000cb4 <release>
          release(&p->lock);
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	806080e7          	jalr	-2042(ra) # 80000cb4 <release>
          return pid;
    800024b6:	a8a9                	j	80002510 <wait+0xdc>
            release(&np->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7fa080e7          	jalr	2042(ra) # 80000cb4 <release>
            release(&p->lock);
    800024c2:	854a                	mv	a0,s2
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	7f0080e7          	jalr	2032(ra) # 80000cb4 <release>
            return -1;
    800024cc:	59fd                	li	s3,-1
    800024ce:	a089                	j	80002510 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800024d0:	17848493          	addi	s1,s1,376
    800024d4:	03348463          	beq	s1,s3,800024fc <wait+0xc8>
      if(np->parent == p){
    800024d8:	709c                	ld	a5,32(s1)
    800024da:	ff279be3          	bne	a5,s2,800024d0 <wait+0x9c>
        acquire(&np->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	720080e7          	jalr	1824(ra) # 80000c00 <acquire>
        if(np->state == ZOMBIE){
    800024e8:	4c9c                	lw	a5,24(s1)
    800024ea:	f94787e3          	beq	a5,s4,80002478 <wait+0x44>
        release(&np->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	7c4080e7          	jalr	1988(ra) # 80000cb4 <release>
        havekids = 1;
    800024f8:	8756                	mv	a4,s5
    800024fa:	bfd9                	j	800024d0 <wait+0x9c>
    if(!havekids || p->killed){
    800024fc:	c701                	beqz	a4,80002504 <wait+0xd0>
    800024fe:	03092783          	lw	a5,48(s2)
    80002502:	c39d                	beqz	a5,80002528 <wait+0xf4>
      release(&p->lock);
    80002504:	854a                	mv	a0,s2
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	7ae080e7          	jalr	1966(ra) # 80000cb4 <release>
      return -1;
    8000250e:	59fd                	li	s3,-1
}
    80002510:	854e                	mv	a0,s3
    80002512:	60a6                	ld	ra,72(sp)
    80002514:	6406                	ld	s0,64(sp)
    80002516:	74e2                	ld	s1,56(sp)
    80002518:	7942                	ld	s2,48(sp)
    8000251a:	79a2                	ld	s3,40(sp)
    8000251c:	7a02                	ld	s4,32(sp)
    8000251e:	6ae2                	ld	s5,24(sp)
    80002520:	6b42                	ld	s6,16(sp)
    80002522:	6ba2                	ld	s7,8(sp)
    80002524:	6161                	addi	sp,sp,80
    80002526:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002528:	85ca                	mv	a1,s2
    8000252a:	854a                	mv	a0,s2
    8000252c:	00000097          	auipc	ra,0x0
    80002530:	e8a080e7          	jalr	-374(ra) # 800023b6 <sleep>
    havekids = 0;
    80002534:	bf25                	j	8000246c <wait+0x38>

0000000080002536 <wakeup>:
{
    80002536:	7139                	addi	sp,sp,-64
    80002538:	fc06                	sd	ra,56(sp)
    8000253a:	f822                	sd	s0,48(sp)
    8000253c:	f426                	sd	s1,40(sp)
    8000253e:	f04a                	sd	s2,32(sp)
    80002540:	ec4e                	sd	s3,24(sp)
    80002542:	e852                	sd	s4,16(sp)
    80002544:	e456                	sd	s5,8(sp)
    80002546:	0080                	addi	s0,sp,64
    80002548:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254a:	00010497          	auipc	s1,0x10
    8000254e:	81e48493          	addi	s1,s1,-2018 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002552:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002554:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002556:	00015917          	auipc	s2,0x15
    8000255a:	61290913          	addi	s2,s2,1554 # 80017b68 <tickslock>
    8000255e:	a811                	j	80002572 <wakeup+0x3c>
    release(&p->lock);
    80002560:	8526                	mv	a0,s1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	752080e7          	jalr	1874(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000256a:	17848493          	addi	s1,s1,376
    8000256e:	03248063          	beq	s1,s2,8000258e <wakeup+0x58>
    acquire(&p->lock);
    80002572:	8526                	mv	a0,s1
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	68c080e7          	jalr	1676(ra) # 80000c00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000257c:	4c9c                	lw	a5,24(s1)
    8000257e:	ff3791e3          	bne	a5,s3,80002560 <wakeup+0x2a>
    80002582:	749c                	ld	a5,40(s1)
    80002584:	fd479ee3          	bne	a5,s4,80002560 <wakeup+0x2a>
      p->state = RUNNABLE;
    80002588:	0154ac23          	sw	s5,24(s1)
    8000258c:	bfd1                	j	80002560 <wakeup+0x2a>
}
    8000258e:	70e2                	ld	ra,56(sp)
    80002590:	7442                	ld	s0,48(sp)
    80002592:	74a2                	ld	s1,40(sp)
    80002594:	7902                	ld	s2,32(sp)
    80002596:	69e2                	ld	s3,24(sp)
    80002598:	6a42                	ld	s4,16(sp)
    8000259a:	6aa2                	ld	s5,8(sp)
    8000259c:	6121                	addi	sp,sp,64
    8000259e:	8082                	ret

00000000800025a0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800025a0:	7179                	addi	sp,sp,-48
    800025a2:	f406                	sd	ra,40(sp)
    800025a4:	f022                	sd	s0,32(sp)
    800025a6:	ec26                	sd	s1,24(sp)
    800025a8:	e84a                	sd	s2,16(sp)
    800025aa:	e44e                	sd	s3,8(sp)
    800025ac:	1800                	addi	s0,sp,48
    800025ae:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800025b0:	0000f497          	auipc	s1,0xf
    800025b4:	7b848493          	addi	s1,s1,1976 # 80011d68 <proc>
    800025b8:	00015997          	auipc	s3,0x15
    800025bc:	5b098993          	addi	s3,s3,1456 # 80017b68 <tickslock>
    acquire(&p->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	63e080e7          	jalr	1598(ra) # 80000c00 <acquire>
    if(p->pid == pid){
    800025ca:	5c9c                	lw	a5,56(s1)
    800025cc:	01278d63          	beq	a5,s2,800025e6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025d0:	8526                	mv	a0,s1
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	6e2080e7          	jalr	1762(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025da:	17848493          	addi	s1,s1,376
    800025de:	ff3491e3          	bne	s1,s3,800025c0 <kill+0x20>
  }
  return -1;
    800025e2:	557d                	li	a0,-1
    800025e4:	a821                	j	800025fc <kill+0x5c>
      p->killed = 1;
    800025e6:	4785                	li	a5,1
    800025e8:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800025ea:	4c98                	lw	a4,24(s1)
    800025ec:	00f70f63          	beq	a4,a5,8000260a <kill+0x6a>
      release(&p->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	6c2080e7          	jalr	1730(ra) # 80000cb4 <release>
      return 0;
    800025fa:	4501                	li	a0,0
}
    800025fc:	70a2                	ld	ra,40(sp)
    800025fe:	7402                	ld	s0,32(sp)
    80002600:	64e2                	ld	s1,24(sp)
    80002602:	6942                	ld	s2,16(sp)
    80002604:	69a2                	ld	s3,8(sp)
    80002606:	6145                	addi	sp,sp,48
    80002608:	8082                	ret
        p->state = RUNNABLE;
    8000260a:	4789                	li	a5,2
    8000260c:	cc9c                	sw	a5,24(s1)
    8000260e:	b7cd                	j	800025f0 <kill+0x50>

0000000080002610 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002610:	7179                	addi	sp,sp,-48
    80002612:	f406                	sd	ra,40(sp)
    80002614:	f022                	sd	s0,32(sp)
    80002616:	ec26                	sd	s1,24(sp)
    80002618:	e84a                	sd	s2,16(sp)
    8000261a:	e44e                	sd	s3,8(sp)
    8000261c:	e052                	sd	s4,0(sp)
    8000261e:	1800                	addi	s0,sp,48
    80002620:	84aa                	mv	s1,a0
    80002622:	892e                	mv	s2,a1
    80002624:	89b2                	mv	s3,a2
    80002626:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	4d8080e7          	jalr	1240(ra) # 80001b00 <myproc>
  if(user_dst){
    80002630:	c08d                	beqz	s1,80002652 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002632:	86d2                	mv	a3,s4
    80002634:	864e                	mv	a2,s3
    80002636:	85ca                	mv	a1,s2
    80002638:	6928                	ld	a0,80(a0)
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	18c080e7          	jalr	396(ra) # 800017c6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002642:	70a2                	ld	ra,40(sp)
    80002644:	7402                	ld	s0,32(sp)
    80002646:	64e2                	ld	s1,24(sp)
    80002648:	6942                	ld	s2,16(sp)
    8000264a:	69a2                	ld	s3,8(sp)
    8000264c:	6a02                	ld	s4,0(sp)
    8000264e:	6145                	addi	sp,sp,48
    80002650:	8082                	ret
    memmove((char *)dst, src, len);
    80002652:	000a061b          	sext.w	a2,s4
    80002656:	85ce                	mv	a1,s3
    80002658:	854a                	mv	a0,s2
    8000265a:	ffffe097          	auipc	ra,0xffffe
    8000265e:	6fe080e7          	jalr	1790(ra) # 80000d58 <memmove>
    return 0;
    80002662:	8526                	mv	a0,s1
    80002664:	bff9                	j	80002642 <either_copyout+0x32>

0000000080002666 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002666:	7179                	addi	sp,sp,-48
    80002668:	f406                	sd	ra,40(sp)
    8000266a:	f022                	sd	s0,32(sp)
    8000266c:	ec26                	sd	s1,24(sp)
    8000266e:	e84a                	sd	s2,16(sp)
    80002670:	e44e                	sd	s3,8(sp)
    80002672:	e052                	sd	s4,0(sp)
    80002674:	1800                	addi	s0,sp,48
    80002676:	892a                	mv	s2,a0
    80002678:	84ae                	mv	s1,a1
    8000267a:	89b2                	mv	s3,a2
    8000267c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	482080e7          	jalr	1154(ra) # 80001b00 <myproc>
  if(user_src){
    80002686:	c08d                	beqz	s1,800026a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002688:	86d2                	mv	a3,s4
    8000268a:	864e                	mv	a2,s3
    8000268c:	85ca                	mv	a1,s2
    8000268e:	6928                	ld	a0,80(a0)
    80002690:	fffff097          	auipc	ra,0xfffff
    80002694:	1c2080e7          	jalr	450(ra) # 80001852 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002698:	70a2                	ld	ra,40(sp)
    8000269a:	7402                	ld	s0,32(sp)
    8000269c:	64e2                	ld	s1,24(sp)
    8000269e:	6942                	ld	s2,16(sp)
    800026a0:	69a2                	ld	s3,8(sp)
    800026a2:	6a02                	ld	s4,0(sp)
    800026a4:	6145                	addi	sp,sp,48
    800026a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800026a8:	000a061b          	sext.w	a2,s4
    800026ac:	85ce                	mv	a1,s3
    800026ae:	854a                	mv	a0,s2
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	6a8080e7          	jalr	1704(ra) # 80000d58 <memmove>
    return 0;
    800026b8:	8526                	mv	a0,s1
    800026ba:	bff9                	j	80002698 <either_copyin+0x32>

00000000800026bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026bc:	715d                	addi	sp,sp,-80
    800026be:	e486                	sd	ra,72(sp)
    800026c0:	e0a2                	sd	s0,64(sp)
    800026c2:	fc26                	sd	s1,56(sp)
    800026c4:	f84a                	sd	s2,48(sp)
    800026c6:	f44e                	sd	s3,40(sp)
    800026c8:	f052                	sd	s4,32(sp)
    800026ca:	ec56                	sd	s5,24(sp)
    800026cc:	e85a                	sd	s6,16(sp)
    800026ce:	e45e                	sd	s7,8(sp)
    800026d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026d2:	00006517          	auipc	a0,0x6
    800026d6:	9f650513          	addi	a0,a0,-1546 # 800080c8 <digits+0x88>
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	eb6080e7          	jalr	-330(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e2:	0000f497          	auipc	s1,0xf
    800026e6:	7de48493          	addi	s1,s1,2014 # 80011ec0 <proc+0x158>
    800026ea:	00015917          	auipc	s2,0x15
    800026ee:	5d690913          	addi	s2,s2,1494 # 80017cc0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026f4:	00006997          	auipc	s3,0x6
    800026f8:	b7498993          	addi	s3,s3,-1164 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800026fc:	00006a97          	auipc	s5,0x6
    80002700:	b74a8a93          	addi	s5,s5,-1164 # 80008270 <digits+0x230>
    printf("\n");
    80002704:	00006a17          	auipc	s4,0x6
    80002708:	9c4a0a13          	addi	s4,s4,-1596 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000270c:	00006b97          	auipc	s7,0x6
    80002710:	b9cb8b93          	addi	s7,s7,-1124 # 800082a8 <states.0>
    80002714:	a00d                	j	80002736 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002716:	ee06a583          	lw	a1,-288(a3)
    8000271a:	8556                	mv	a0,s5
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	e74080e7          	jalr	-396(ra) # 80000590 <printf>
    printf("\n");
    80002724:	8552                	mv	a0,s4
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	e6a080e7          	jalr	-406(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000272e:	17848493          	addi	s1,s1,376
    80002732:	03248263          	beq	s1,s2,80002756 <procdump+0x9a>
    if(p->state == UNUSED)
    80002736:	86a6                	mv	a3,s1
    80002738:	ec04a783          	lw	a5,-320(s1)
    8000273c:	dbed                	beqz	a5,8000272e <procdump+0x72>
      state = "???";
    8000273e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002740:	fcfb6be3          	bltu	s6,a5,80002716 <procdump+0x5a>
    80002744:	02079713          	slli	a4,a5,0x20
    80002748:	01d75793          	srli	a5,a4,0x1d
    8000274c:	97de                	add	a5,a5,s7
    8000274e:	6390                	ld	a2,0(a5)
    80002750:	f279                	bnez	a2,80002716 <procdump+0x5a>
      state = "???";
    80002752:	864e                	mv	a2,s3
    80002754:	b7c9                	j	80002716 <procdump+0x5a>
  }
}
    80002756:	60a6                	ld	ra,72(sp)
    80002758:	6406                	ld	s0,64(sp)
    8000275a:	74e2                	ld	s1,56(sp)
    8000275c:	7942                	ld	s2,48(sp)
    8000275e:	79a2                	ld	s3,40(sp)
    80002760:	7a02                	ld	s4,32(sp)
    80002762:	6ae2                	ld	s5,24(sp)
    80002764:	6b42                	ld	s6,16(sp)
    80002766:	6ba2                	ld	s7,8(sp)
    80002768:	6161                	addi	sp,sp,80
    8000276a:	8082                	ret

000000008000276c <swtch>:
    8000276c:	00153023          	sd	ra,0(a0)
    80002770:	00253423          	sd	sp,8(a0)
    80002774:	e900                	sd	s0,16(a0)
    80002776:	ed04                	sd	s1,24(a0)
    80002778:	03253023          	sd	s2,32(a0)
    8000277c:	03353423          	sd	s3,40(a0)
    80002780:	03453823          	sd	s4,48(a0)
    80002784:	03553c23          	sd	s5,56(a0)
    80002788:	05653023          	sd	s6,64(a0)
    8000278c:	05753423          	sd	s7,72(a0)
    80002790:	05853823          	sd	s8,80(a0)
    80002794:	05953c23          	sd	s9,88(a0)
    80002798:	07a53023          	sd	s10,96(a0)
    8000279c:	07b53423          	sd	s11,104(a0)
    800027a0:	0005b083          	ld	ra,0(a1)
    800027a4:	0085b103          	ld	sp,8(a1)
    800027a8:	6980                	ld	s0,16(a1)
    800027aa:	6d84                	ld	s1,24(a1)
    800027ac:	0205b903          	ld	s2,32(a1)
    800027b0:	0285b983          	ld	s3,40(a1)
    800027b4:	0305ba03          	ld	s4,48(a1)
    800027b8:	0385ba83          	ld	s5,56(a1)
    800027bc:	0405bb03          	ld	s6,64(a1)
    800027c0:	0485bb83          	ld	s7,72(a1)
    800027c4:	0505bc03          	ld	s8,80(a1)
    800027c8:	0585bc83          	ld	s9,88(a1)
    800027cc:	0605bd03          	ld	s10,96(a1)
    800027d0:	0685bd83          	ld	s11,104(a1)
    800027d4:	8082                	ret

00000000800027d6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027d6:	1141                	addi	sp,sp,-16
    800027d8:	e406                	sd	ra,8(sp)
    800027da:	e022                	sd	s0,0(sp)
    800027dc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027de:	00006597          	auipc	a1,0x6
    800027e2:	af258593          	addi	a1,a1,-1294 # 800082d0 <states.0+0x28>
    800027e6:	00015517          	auipc	a0,0x15
    800027ea:	38250513          	addi	a0,a0,898 # 80017b68 <tickslock>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	382080e7          	jalr	898(ra) # 80000b70 <initlock>
}
    800027f6:	60a2                	ld	ra,8(sp)
    800027f8:	6402                	ld	s0,0(sp)
    800027fa:	0141                	addi	sp,sp,16
    800027fc:	8082                	ret

00000000800027fe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027fe:	1141                	addi	sp,sp,-16
    80002800:	e422                	sd	s0,8(sp)
    80002802:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002804:	00003797          	auipc	a5,0x3
    80002808:	5ec78793          	addi	a5,a5,1516 # 80005df0 <kernelvec>
    8000280c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002810:	6422                	ld	s0,8(sp)
    80002812:	0141                	addi	sp,sp,16
    80002814:	8082                	ret

0000000080002816 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002816:	1141                	addi	sp,sp,-16
    80002818:	e406                	sd	ra,8(sp)
    8000281a:	e022                	sd	s0,0(sp)
    8000281c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	2e2080e7          	jalr	738(ra) # 80001b00 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002826:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000282a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002830:	00004697          	auipc	a3,0x4
    80002834:	7d068693          	addi	a3,a3,2000 # 80007000 <_trampoline>
    80002838:	00004717          	auipc	a4,0x4
    8000283c:	7c870713          	addi	a4,a4,1992 # 80007000 <_trampoline>
    80002840:	8f15                	sub	a4,a4,a3
    80002842:	040007b7          	lui	a5,0x4000
    80002846:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002848:	07b2                	slli	a5,a5,0xc
    8000284a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284c:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002850:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002852:	18002673          	csrr	a2,satp
    80002856:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002858:	6d30                	ld	a2,88(a0)
    8000285a:	6138                	ld	a4,64(a0)
    8000285c:	6585                	lui	a1,0x1
    8000285e:	972e                	add	a4,a4,a1
    80002860:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002862:	6d38                	ld	a4,88(a0)
    80002864:	00000617          	auipc	a2,0x0
    80002868:	13860613          	addi	a2,a2,312 # 8000299c <usertrap>
    8000286c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000286e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002870:	8612                	mv	a2,tp
    80002872:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002874:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002878:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000287c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002880:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002884:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002886:	6f18                	ld	a4,24(a4)
    80002888:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000288c:	692c                	ld	a1,80(a0)
    8000288e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002890:	00005717          	auipc	a4,0x5
    80002894:	80070713          	addi	a4,a4,-2048 # 80007090 <userret>
    80002898:	8f15                	sub	a4,a4,a3
    8000289a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000289c:	577d                	li	a4,-1
    8000289e:	177e                	slli	a4,a4,0x3f
    800028a0:	8dd9                	or	a1,a1,a4
    800028a2:	02000537          	lui	a0,0x2000
    800028a6:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800028a8:	0536                	slli	a0,a0,0xd
    800028aa:	9782                	jalr	a5
}
    800028ac:	60a2                	ld	ra,8(sp)
    800028ae:	6402                	ld	s0,0(sp)
    800028b0:	0141                	addi	sp,sp,16
    800028b2:	8082                	ret

00000000800028b4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028b4:	1101                	addi	sp,sp,-32
    800028b6:	ec06                	sd	ra,24(sp)
    800028b8:	e822                	sd	s0,16(sp)
    800028ba:	e426                	sd	s1,8(sp)
    800028bc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028be:	00015497          	auipc	s1,0x15
    800028c2:	2aa48493          	addi	s1,s1,682 # 80017b68 <tickslock>
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	338080e7          	jalr	824(ra) # 80000c00 <acquire>
  ticks++;
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	75050513          	addi	a0,a0,1872 # 80009020 <ticks>
    800028d8:	411c                	lw	a5,0(a0)
    800028da:	2785                	addiw	a5,a5,1
    800028dc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	c58080e7          	jalr	-936(ra) # 80002536 <wakeup>
  release(&tickslock);
    800028e6:	8526                	mv	a0,s1
    800028e8:	ffffe097          	auipc	ra,0xffffe
    800028ec:	3cc080e7          	jalr	972(ra) # 80000cb4 <release>
}
    800028f0:	60e2                	ld	ra,24(sp)
    800028f2:	6442                	ld	s0,16(sp)
    800028f4:	64a2                	ld	s1,8(sp)
    800028f6:	6105                	addi	sp,sp,32
    800028f8:	8082                	ret

00000000800028fa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028fa:	1101                	addi	sp,sp,-32
    800028fc:	ec06                	sd	ra,24(sp)
    800028fe:	e822                	sd	s0,16(sp)
    80002900:	e426                	sd	s1,8(sp)
    80002902:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002904:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002908:	00074d63          	bltz	a4,80002922 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000290c:	57fd                	li	a5,-1
    8000290e:	17fe                	slli	a5,a5,0x3f
    80002910:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002912:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002914:	06f70363          	beq	a4,a5,8000297a <devintr+0x80>
  }
}
    80002918:	60e2                	ld	ra,24(sp)
    8000291a:	6442                	ld	s0,16(sp)
    8000291c:	64a2                	ld	s1,8(sp)
    8000291e:	6105                	addi	sp,sp,32
    80002920:	8082                	ret
     (scause & 0xff) == 9){
    80002922:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002926:	46a5                	li	a3,9
    80002928:	fed792e3          	bne	a5,a3,8000290c <devintr+0x12>
    int irq = plic_claim();
    8000292c:	00003097          	auipc	ra,0x3
    80002930:	5cc080e7          	jalr	1484(ra) # 80005ef8 <plic_claim>
    80002934:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002936:	47a9                	li	a5,10
    80002938:	02f50763          	beq	a0,a5,80002966 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000293c:	4785                	li	a5,1
    8000293e:	02f50963          	beq	a0,a5,80002970 <devintr+0x76>
    return 1;
    80002942:	4505                	li	a0,1
    } else if(irq){
    80002944:	d8f1                	beqz	s1,80002918 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002946:	85a6                	mv	a1,s1
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	99050513          	addi	a0,a0,-1648 # 800082d8 <states.0+0x30>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c40080e7          	jalr	-960(ra) # 80000590 <printf>
      plic_complete(irq);
    80002958:	8526                	mv	a0,s1
    8000295a:	00003097          	auipc	ra,0x3
    8000295e:	5c2080e7          	jalr	1474(ra) # 80005f1c <plic_complete>
    return 1;
    80002962:	4505                	li	a0,1
    80002964:	bf55                	j	80002918 <devintr+0x1e>
      uartintr();
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	05c080e7          	jalr	92(ra) # 800009c2 <uartintr>
    8000296e:	b7ed                	j	80002958 <devintr+0x5e>
      virtio_disk_intr();
    80002970:	00004097          	auipc	ra,0x4
    80002974:	a20080e7          	jalr	-1504(ra) # 80006390 <virtio_disk_intr>
    80002978:	b7c5                	j	80002958 <devintr+0x5e>
    if(cpuid() == 0){
    8000297a:	fffff097          	auipc	ra,0xfffff
    8000297e:	15a080e7          	jalr	346(ra) # 80001ad4 <cpuid>
    80002982:	c901                	beqz	a0,80002992 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002984:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002988:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000298a:	14479073          	csrw	sip,a5
    return 2;
    8000298e:	4509                	li	a0,2
    80002990:	b761                	j	80002918 <devintr+0x1e>
      clockintr();
    80002992:	00000097          	auipc	ra,0x0
    80002996:	f22080e7          	jalr	-222(ra) # 800028b4 <clockintr>
    8000299a:	b7ed                	j	80002984 <devintr+0x8a>

000000008000299c <usertrap>:
{
    8000299c:	1101                	addi	sp,sp,-32
    8000299e:	ec06                	sd	ra,24(sp)
    800029a0:	e822                	sd	s0,16(sp)
    800029a2:	e426                	sd	s1,8(sp)
    800029a4:	e04a                	sd	s2,0(sp)
    800029a6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029ac:	1007f793          	andi	a5,a5,256
    800029b0:	e3ad                	bnez	a5,80002a12 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029b2:	00003797          	auipc	a5,0x3
    800029b6:	43e78793          	addi	a5,a5,1086 # 80005df0 <kernelvec>
    800029ba:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	142080e7          	jalr	322(ra) # 80001b00 <myproc>
    800029c6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029c8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ca:	14102773          	csrr	a4,sepc
    800029ce:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029d0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029d4:	47a1                	li	a5,8
    800029d6:	04f71c63          	bne	a4,a5,80002a2e <usertrap+0x92>
    if(p->killed)
    800029da:	591c                	lw	a5,48(a0)
    800029dc:	e3b9                	bnez	a5,80002a22 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029de:	6cb8                	ld	a4,88(s1)
    800029e0:	6f1c                	ld	a5,24(a4)
    800029e2:	0791                	addi	a5,a5,4
    800029e4:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ee:	10079073          	csrw	sstatus,a5
    syscall();
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	2e0080e7          	jalr	736(ra) # 80002cd2 <syscall>
  if(p->killed)
    800029fa:	589c                	lw	a5,48(s1)
    800029fc:	ebc1                	bnez	a5,80002a8c <usertrap+0xf0>
  usertrapret();
    800029fe:	00000097          	auipc	ra,0x0
    80002a02:	e18080e7          	jalr	-488(ra) # 80002816 <usertrapret>
}
    80002a06:	60e2                	ld	ra,24(sp)
    80002a08:	6442                	ld	s0,16(sp)
    80002a0a:	64a2                	ld	s1,8(sp)
    80002a0c:	6902                	ld	s2,0(sp)
    80002a0e:	6105                	addi	sp,sp,32
    80002a10:	8082                	ret
    panic("usertrap: not from user mode");
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	8e650513          	addi	a0,a0,-1818 # 800082f8 <states.0+0x50>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b2c080e7          	jalr	-1236(ra) # 80000546 <panic>
      exit(-1);
    80002a22:	557d                	li	a0,-1
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	84c080e7          	jalr	-1972(ra) # 80002270 <exit>
    80002a2c:	bf4d                	j	800029de <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	ecc080e7          	jalr	-308(ra) # 800028fa <devintr>
    80002a36:	892a                	mv	s2,a0
    80002a38:	c501                	beqz	a0,80002a40 <usertrap+0xa4>
  if(p->killed)
    80002a3a:	589c                	lw	a5,48(s1)
    80002a3c:	c3a1                	beqz	a5,80002a7c <usertrap+0xe0>
    80002a3e:	a815                	j	80002a72 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a40:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a44:	5c90                	lw	a2,56(s1)
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	8d250513          	addi	a0,a0,-1838 # 80008318 <states.0+0x70>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b42080e7          	jalr	-1214(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a56:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a5a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	8ea50513          	addi	a0,a0,-1814 # 80008348 <states.0+0xa0>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	b2a080e7          	jalr	-1238(ra) # 80000590 <printf>
    p->killed = 1;
    80002a6e:	4785                	li	a5,1
    80002a70:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a72:	557d                	li	a0,-1
    80002a74:	fffff097          	auipc	ra,0xfffff
    80002a78:	7fc080e7          	jalr	2044(ra) # 80002270 <exit>
  if(which_dev == 2)
    80002a7c:	4789                	li	a5,2
    80002a7e:	f8f910e3          	bne	s2,a5,800029fe <usertrap+0x62>
    yield();
    80002a82:	00000097          	auipc	ra,0x0
    80002a86:	8f8080e7          	jalr	-1800(ra) # 8000237a <yield>
    80002a8a:	bf95                	j	800029fe <usertrap+0x62>
  int which_dev = 0;
    80002a8c:	4901                	li	s2,0
    80002a8e:	b7d5                	j	80002a72 <usertrap+0xd6>

0000000080002a90 <kerneltrap>:
{
    80002a90:	7179                	addi	sp,sp,-48
    80002a92:	f406                	sd	ra,40(sp)
    80002a94:	f022                	sd	s0,32(sp)
    80002a96:	ec26                	sd	s1,24(sp)
    80002a98:	e84a                	sd	s2,16(sp)
    80002a9a:	e44e                	sd	s3,8(sp)
    80002a9c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a9e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aa6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aaa:	1004f793          	andi	a5,s1,256
    80002aae:	cb85                	beqz	a5,80002ade <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ab4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ab6:	ef85                	bnez	a5,80002aee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	e42080e7          	jalr	-446(ra) # 800028fa <devintr>
    80002ac0:	cd1d                	beqz	a0,80002afe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ac2:	4789                	li	a5,2
    80002ac4:	06f50a63          	beq	a0,a5,80002b38 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ac8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002acc:	10049073          	csrw	sstatus,s1
}
    80002ad0:	70a2                	ld	ra,40(sp)
    80002ad2:	7402                	ld	s0,32(sp)
    80002ad4:	64e2                	ld	s1,24(sp)
    80002ad6:	6942                	ld	s2,16(sp)
    80002ad8:	69a2                	ld	s3,8(sp)
    80002ada:	6145                	addi	sp,sp,48
    80002adc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ade:	00006517          	auipc	a0,0x6
    80002ae2:	88a50513          	addi	a0,a0,-1910 # 80008368 <states.0+0xc0>
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	a60080e7          	jalr	-1440(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	8a250513          	addi	a0,a0,-1886 # 80008390 <states.0+0xe8>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a50080e7          	jalr	-1456(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002afe:	85ce                	mv	a1,s3
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	8b050513          	addi	a0,a0,-1872 # 800083b0 <states.0+0x108>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a88080e7          	jalr	-1400(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b14:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b18:	00006517          	auipc	a0,0x6
    80002b1c:	8a850513          	addi	a0,a0,-1880 # 800083c0 <states.0+0x118>
    80002b20:	ffffe097          	auipc	ra,0xffffe
    80002b24:	a70080e7          	jalr	-1424(ra) # 80000590 <printf>
    panic("kerneltrap");
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	8b050513          	addi	a0,a0,-1872 # 800083d8 <states.0+0x130>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	a16080e7          	jalr	-1514(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b38:	fffff097          	auipc	ra,0xfffff
    80002b3c:	fc8080e7          	jalr	-56(ra) # 80001b00 <myproc>
    80002b40:	d541                	beqz	a0,80002ac8 <kerneltrap+0x38>
    80002b42:	fffff097          	auipc	ra,0xfffff
    80002b46:	fbe080e7          	jalr	-66(ra) # 80001b00 <myproc>
    80002b4a:	4d18                	lw	a4,24(a0)
    80002b4c:	478d                	li	a5,3
    80002b4e:	f6f71de3          	bne	a4,a5,80002ac8 <kerneltrap+0x38>
    yield();
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	828080e7          	jalr	-2008(ra) # 8000237a <yield>
    80002b5a:	b7bd                	j	80002ac8 <kerneltrap+0x38>

0000000080002b5c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b5c:	1101                	addi	sp,sp,-32
    80002b5e:	ec06                	sd	ra,24(sp)
    80002b60:	e822                	sd	s0,16(sp)
    80002b62:	e426                	sd	s1,8(sp)
    80002b64:	1000                	addi	s0,sp,32
    80002b66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	f98080e7          	jalr	-104(ra) # 80001b00 <myproc>
  switch (n) {
    80002b70:	4795                	li	a5,5
    80002b72:	0497e163          	bltu	a5,s1,80002bb4 <argraw+0x58>
    80002b76:	048a                	slli	s1,s1,0x2
    80002b78:	00006717          	auipc	a4,0x6
    80002b7c:	89870713          	addi	a4,a4,-1896 # 80008410 <states.0+0x168>
    80002b80:	94ba                	add	s1,s1,a4
    80002b82:	409c                	lw	a5,0(s1)
    80002b84:	97ba                	add	a5,a5,a4
    80002b86:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret
    return p->trapframe->a1;
    80002b96:	6d3c                	ld	a5,88(a0)
    80002b98:	7fa8                	ld	a0,120(a5)
    80002b9a:	bfcd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a2;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	63c8                	ld	a0,128(a5)
    80002ba0:	b7f5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a3;
    80002ba2:	6d3c                	ld	a5,88(a0)
    80002ba4:	67c8                	ld	a0,136(a5)
    80002ba6:	b7dd                	j	80002b8c <argraw+0x30>
    return p->trapframe->a4;
    80002ba8:	6d3c                	ld	a5,88(a0)
    80002baa:	6bc8                	ld	a0,144(a5)
    80002bac:	b7c5                	j	80002b8c <argraw+0x30>
    return p->trapframe->a5;
    80002bae:	6d3c                	ld	a5,88(a0)
    80002bb0:	6fc8                	ld	a0,152(a5)
    80002bb2:	bfe9                	j	80002b8c <argraw+0x30>
  panic("argraw");
    80002bb4:	00006517          	auipc	a0,0x6
    80002bb8:	83450513          	addi	a0,a0,-1996 # 800083e8 <states.0+0x140>
    80002bbc:	ffffe097          	auipc	ra,0xffffe
    80002bc0:	98a080e7          	jalr	-1654(ra) # 80000546 <panic>

0000000080002bc4 <fetchaddr>:
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	e426                	sd	s1,8(sp)
    80002bcc:	e04a                	sd	s2,0(sp)
    80002bce:	1000                	addi	s0,sp,32
    80002bd0:	84aa                	mv	s1,a0
    80002bd2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bd4:	fffff097          	auipc	ra,0xfffff
    80002bd8:	f2c080e7          	jalr	-212(ra) # 80001b00 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bdc:	653c                	ld	a5,72(a0)
    80002bde:	02f4f863          	bgeu	s1,a5,80002c0e <fetchaddr+0x4a>
    80002be2:	00848713          	addi	a4,s1,8
    80002be6:	02e7e663          	bltu	a5,a4,80002c12 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bea:	46a1                	li	a3,8
    80002bec:	8626                	mv	a2,s1
    80002bee:	85ca                	mv	a1,s2
    80002bf0:	6928                	ld	a0,80(a0)
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	c60080e7          	jalr	-928(ra) # 80001852 <copyin>
    80002bfa:	00a03533          	snez	a0,a0
    80002bfe:	40a00533          	neg	a0,a0
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6902                	ld	s2,0(sp)
    80002c0a:	6105                	addi	sp,sp,32
    80002c0c:	8082                	ret
    return -1;
    80002c0e:	557d                	li	a0,-1
    80002c10:	bfcd                	j	80002c02 <fetchaddr+0x3e>
    80002c12:	557d                	li	a0,-1
    80002c14:	b7fd                	j	80002c02 <fetchaddr+0x3e>

0000000080002c16 <fetchstr>:
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	1800                	addi	s0,sp,48
    80002c24:	892a                	mv	s2,a0
    80002c26:	84ae                	mv	s1,a1
    80002c28:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c2a:	fffff097          	auipc	ra,0xfffff
    80002c2e:	ed6080e7          	jalr	-298(ra) # 80001b00 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c32:	86ce                	mv	a3,s3
    80002c34:	864a                	mv	a2,s2
    80002c36:	85a6                	mv	a1,s1
    80002c38:	6928                	ld	a0,80(a0)
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	ca6080e7          	jalr	-858(ra) # 800018e0 <copyinstr>
  if(err < 0)
    80002c42:	00054763          	bltz	a0,80002c50 <fetchstr+0x3a>
  return strlen(buf);
    80002c46:	8526                	mv	a0,s1
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	238080e7          	jalr	568(ra) # 80000e80 <strlen>
}
    80002c50:	70a2                	ld	ra,40(sp)
    80002c52:	7402                	ld	s0,32(sp)
    80002c54:	64e2                	ld	s1,24(sp)
    80002c56:	6942                	ld	s2,16(sp)
    80002c58:	69a2                	ld	s3,8(sp)
    80002c5a:	6145                	addi	sp,sp,48
    80002c5c:	8082                	ret

0000000080002c5e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c5e:	1101                	addi	sp,sp,-32
    80002c60:	ec06                	sd	ra,24(sp)
    80002c62:	e822                	sd	s0,16(sp)
    80002c64:	e426                	sd	s1,8(sp)
    80002c66:	1000                	addi	s0,sp,32
    80002c68:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	ef2080e7          	jalr	-270(ra) # 80002b5c <argraw>
    80002c72:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c74:	4501                	li	a0,0
    80002c76:	60e2                	ld	ra,24(sp)
    80002c78:	6442                	ld	s0,16(sp)
    80002c7a:	64a2                	ld	s1,8(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c80:	1101                	addi	sp,sp,-32
    80002c82:	ec06                	sd	ra,24(sp)
    80002c84:	e822                	sd	s0,16(sp)
    80002c86:	e426                	sd	s1,8(sp)
    80002c88:	1000                	addi	s0,sp,32
    80002c8a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	ed0080e7          	jalr	-304(ra) # 80002b5c <argraw>
    80002c94:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c96:	4501                	li	a0,0
    80002c98:	60e2                	ld	ra,24(sp)
    80002c9a:	6442                	ld	s0,16(sp)
    80002c9c:	64a2                	ld	s1,8(sp)
    80002c9e:	6105                	addi	sp,sp,32
    80002ca0:	8082                	ret

0000000080002ca2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ca2:	1101                	addi	sp,sp,-32
    80002ca4:	ec06                	sd	ra,24(sp)
    80002ca6:	e822                	sd	s0,16(sp)
    80002ca8:	e426                	sd	s1,8(sp)
    80002caa:	e04a                	sd	s2,0(sp)
    80002cac:	1000                	addi	s0,sp,32
    80002cae:	84ae                	mv	s1,a1
    80002cb0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cb2:	00000097          	auipc	ra,0x0
    80002cb6:	eaa080e7          	jalr	-342(ra) # 80002b5c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cba:	864a                	mv	a2,s2
    80002cbc:	85a6                	mv	a1,s1
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	f58080e7          	jalr	-168(ra) # 80002c16 <fetchstr>
}
    80002cc6:	60e2                	ld	ra,24(sp)
    80002cc8:	6442                	ld	s0,16(sp)
    80002cca:	64a2                	ld	s1,8(sp)
    80002ccc:	6902                	ld	s2,0(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret

0000000080002cd2 <syscall>:
[SYS_checkvm] sys_checkvm,
};

void
syscall(void)
{
    80002cd2:	1101                	addi	sp,sp,-32
    80002cd4:	ec06                	sd	ra,24(sp)
    80002cd6:	e822                	sd	s0,16(sp)
    80002cd8:	e426                	sd	s1,8(sp)
    80002cda:	e04a                	sd	s2,0(sp)
    80002cdc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	e22080e7          	jalr	-478(ra) # 80001b00 <myproc>
    80002ce6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ce8:	05853903          	ld	s2,88(a0)
    80002cec:	0a893783          	ld	a5,168(s2)
    80002cf0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cf4:	37fd                	addiw	a5,a5,-1
    80002cf6:	4755                	li	a4,21
    80002cf8:	00f76f63          	bltu	a4,a5,80002d16 <syscall+0x44>
    80002cfc:	00369713          	slli	a4,a3,0x3
    80002d00:	00005797          	auipc	a5,0x5
    80002d04:	72878793          	addi	a5,a5,1832 # 80008428 <syscalls>
    80002d08:	97ba                	add	a5,a5,a4
    80002d0a:	639c                	ld	a5,0(a5)
    80002d0c:	c789                	beqz	a5,80002d16 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d0e:	9782                	jalr	a5
    80002d10:	06a93823          	sd	a0,112(s2)
    80002d14:	a839                	j	80002d32 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d16:	15848613          	addi	a2,s1,344
    80002d1a:	5c8c                	lw	a1,56(s1)
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	6d450513          	addi	a0,a0,1748 # 800083f0 <states.0+0x148>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	86c080e7          	jalr	-1940(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2c:	6cbc                	ld	a5,88(s1)
    80002d2e:	577d                	li	a4,-1
    80002d30:	fbb8                	sd	a4,112(a5)
  }
}
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6902                	ld	s2,0(sp)
    80002d3a:	6105                	addi	sp,sp,32
    80002d3c:	8082                	ret

0000000080002d3e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d46:	fec40593          	addi	a1,s0,-20
    80002d4a:	4501                	li	a0,0
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	f12080e7          	jalr	-238(ra) # 80002c5e <argint>
    return -1;
    80002d54:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d56:	00054963          	bltz	a0,80002d68 <sys_exit+0x2a>
  exit(n);
    80002d5a:	fec42503          	lw	a0,-20(s0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	512080e7          	jalr	1298(ra) # 80002270 <exit>
  return 0;  // not reached
    80002d66:	4781                	li	a5,0
}
    80002d68:	853e                	mv	a0,a5
    80002d6a:	60e2                	ld	ra,24(sp)
    80002d6c:	6442                	ld	s0,16(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d72:	1141                	addi	sp,sp,-16
    80002d74:	e406                	sd	ra,8(sp)
    80002d76:	e022                	sd	s0,0(sp)
    80002d78:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d86080e7          	jalr	-634(ra) # 80001b00 <myproc>
}
    80002d82:	5d08                	lw	a0,56(a0)
    80002d84:	60a2                	ld	ra,8(sp)
    80002d86:	6402                	ld	s0,0(sp)
    80002d88:	0141                	addi	sp,sp,16
    80002d8a:	8082                	ret

0000000080002d8c <sys_fork>:

uint64
sys_fork(void)
{
    80002d8c:	1141                	addi	sp,sp,-16
    80002d8e:	e406                	sd	ra,8(sp)
    80002d90:	e022                	sd	s0,0(sp)
    80002d92:	0800                	addi	s0,sp,16
  return fork();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	1b6080e7          	jalr	438(ra) # 80001f4a <fork>
}
    80002d9c:	60a2                	ld	ra,8(sp)
    80002d9e:	6402                	ld	s0,0(sp)
    80002da0:	0141                	addi	sp,sp,16
    80002da2:	8082                	ret

0000000080002da4 <sys_wait>:

uint64
sys_wait(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dac:	fe840593          	addi	a1,s0,-24
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	ece080e7          	jalr	-306(ra) # 80002c80 <argaddr>
    80002dba:	87aa                	mv	a5,a0
    return -1;
    80002dbc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dbe:	0007c863          	bltz	a5,80002dce <sys_wait+0x2a>
  return wait(p);
    80002dc2:	fe843503          	ld	a0,-24(s0)
    80002dc6:	fffff097          	auipc	ra,0xfffff
    80002dca:	66e080e7          	jalr	1646(ra) # 80002434 <wait>
}
    80002dce:	60e2                	ld	ra,24(sp)
    80002dd0:	6442                	ld	s0,16(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dd6:	7179                	addi	sp,sp,-48
    80002dd8:	f406                	sd	ra,40(sp)
    80002dda:	f022                	sd	s0,32(sp)
    80002ddc:	ec26                	sd	s1,24(sp)
    80002dde:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002de0:	fdc40593          	addi	a1,s0,-36
    80002de4:	4501                	li	a0,0
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	e78080e7          	jalr	-392(ra) # 80002c5e <argint>
    80002dee:	87aa                	mv	a5,a0
    return -1;
    80002df0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002df2:	0207c063          	bltz	a5,80002e12 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	d0a080e7          	jalr	-758(ra) # 80001b00 <myproc>
    80002dfe:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e00:	fdc42503          	lw	a0,-36(s0)
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	0ce080e7          	jalr	206(ra) # 80001ed2 <growproc>
    80002e0c:	00054863          	bltz	a0,80002e1c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e10:	8526                	mv	a0,s1
}
    80002e12:	70a2                	ld	ra,40(sp)
    80002e14:	7402                	ld	s0,32(sp)
    80002e16:	64e2                	ld	s1,24(sp)
    80002e18:	6145                	addi	sp,sp,48
    80002e1a:	8082                	ret
    return -1;
    80002e1c:	557d                	li	a0,-1
    80002e1e:	bfd5                	j	80002e12 <sys_sbrk+0x3c>

0000000080002e20 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e20:	7139                	addi	sp,sp,-64
    80002e22:	fc06                	sd	ra,56(sp)
    80002e24:	f822                	sd	s0,48(sp)
    80002e26:	f426                	sd	s1,40(sp)
    80002e28:	f04a                	sd	s2,32(sp)
    80002e2a:	ec4e                	sd	s3,24(sp)
    80002e2c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e2e:	fcc40593          	addi	a1,s0,-52
    80002e32:	4501                	li	a0,0
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	e2a080e7          	jalr	-470(ra) # 80002c5e <argint>
    return -1;
    80002e3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e3e:	06054563          	bltz	a0,80002ea8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e42:	00015517          	auipc	a0,0x15
    80002e46:	d2650513          	addi	a0,a0,-730 # 80017b68 <tickslock>
    80002e4a:	ffffe097          	auipc	ra,0xffffe
    80002e4e:	db6080e7          	jalr	-586(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002e52:	00006917          	auipc	s2,0x6
    80002e56:	1ce92903          	lw	s2,462(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e5a:	fcc42783          	lw	a5,-52(s0)
    80002e5e:	cf85                	beqz	a5,80002e96 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e60:	00015997          	auipc	s3,0x15
    80002e64:	d0898993          	addi	s3,s3,-760 # 80017b68 <tickslock>
    80002e68:	00006497          	auipc	s1,0x6
    80002e6c:	1b848493          	addi	s1,s1,440 # 80009020 <ticks>
    if(myproc()->killed){
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	c90080e7          	jalr	-880(ra) # 80001b00 <myproc>
    80002e78:	591c                	lw	a5,48(a0)
    80002e7a:	ef9d                	bnez	a5,80002eb8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e7c:	85ce                	mv	a1,s3
    80002e7e:	8526                	mv	a0,s1
    80002e80:	fffff097          	auipc	ra,0xfffff
    80002e84:	536080e7          	jalr	1334(ra) # 800023b6 <sleep>
  while(ticks - ticks0 < n){
    80002e88:	409c                	lw	a5,0(s1)
    80002e8a:	412787bb          	subw	a5,a5,s2
    80002e8e:	fcc42703          	lw	a4,-52(s0)
    80002e92:	fce7efe3          	bltu	a5,a4,80002e70 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e96:	00015517          	auipc	a0,0x15
    80002e9a:	cd250513          	addi	a0,a0,-814 # 80017b68 <tickslock>
    80002e9e:	ffffe097          	auipc	ra,0xffffe
    80002ea2:	e16080e7          	jalr	-490(ra) # 80000cb4 <release>
  return 0;
    80002ea6:	4781                	li	a5,0
}
    80002ea8:	853e                	mv	a0,a5
    80002eaa:	70e2                	ld	ra,56(sp)
    80002eac:	7442                	ld	s0,48(sp)
    80002eae:	74a2                	ld	s1,40(sp)
    80002eb0:	7902                	ld	s2,32(sp)
    80002eb2:	69e2                	ld	s3,24(sp)
    80002eb4:	6121                	addi	sp,sp,64
    80002eb6:	8082                	ret
      release(&tickslock);
    80002eb8:	00015517          	auipc	a0,0x15
    80002ebc:	cb050513          	addi	a0,a0,-848 # 80017b68 <tickslock>
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	df4080e7          	jalr	-524(ra) # 80000cb4 <release>
      return -1;
    80002ec8:	57fd                	li	a5,-1
    80002eca:	bff9                	j	80002ea8 <sys_sleep+0x88>

0000000080002ecc <sys_kill>:

uint64
sys_kill(void)
{
    80002ecc:	1101                	addi	sp,sp,-32
    80002ece:	ec06                	sd	ra,24(sp)
    80002ed0:	e822                	sd	s0,16(sp)
    80002ed2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ed4:	fec40593          	addi	a1,s0,-20
    80002ed8:	4501                	li	a0,0
    80002eda:	00000097          	auipc	ra,0x0
    80002ede:	d84080e7          	jalr	-636(ra) # 80002c5e <argint>
    80002ee2:	87aa                	mv	a5,a0
    return -1;
    80002ee4:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ee6:	0007c863          	bltz	a5,80002ef6 <sys_kill+0x2a>
  return kill(pid);
    80002eea:	fec42503          	lw	a0,-20(s0)
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	6b2080e7          	jalr	1714(ra) # 800025a0 <kill>
}
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	e426                	sd	s1,8(sp)
    80002f06:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f08:	00015517          	auipc	a0,0x15
    80002f0c:	c6050513          	addi	a0,a0,-928 # 80017b68 <tickslock>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	cf0080e7          	jalr	-784(ra) # 80000c00 <acquire>
  xticks = ticks;
    80002f18:	00006497          	auipc	s1,0x6
    80002f1c:	1084a483          	lw	s1,264(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f20:	00015517          	auipc	a0,0x15
    80002f24:	c4850513          	addi	a0,a0,-952 # 80017b68 <tickslock>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	d8c080e7          	jalr	-628(ra) # 80000cb4 <release>
  return xticks;
}
    80002f30:	02049513          	slli	a0,s1,0x20
    80002f34:	9101                	srli	a0,a0,0x20
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	64a2                	ld	s1,8(sp)
    80002f3c:	6105                	addi	sp,sp,32
    80002f3e:	8082                	ret

0000000080002f40 <sys_checkvm>:

uint64
sys_checkvm()
{
    80002f40:	1141                	addi	sp,sp,-16
    80002f42:	e406                	sd	ra,8(sp)
    80002f44:	e022                	sd	s0,0(sp)
    80002f46:	0800                	addi	s0,sp,16
  return (uint64)test_pagetable(); 
    80002f48:	fffff097          	auipc	ra,0xfffff
    80002f4c:	a48080e7          	jalr	-1464(ra) # 80001990 <test_pagetable>
    80002f50:	60a2                	ld	ra,8(sp)
    80002f52:	6402                	ld	s0,0(sp)
    80002f54:	0141                	addi	sp,sp,16
    80002f56:	8082                	ret

0000000080002f58 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f58:	7179                	addi	sp,sp,-48
    80002f5a:	f406                	sd	ra,40(sp)
    80002f5c:	f022                	sd	s0,32(sp)
    80002f5e:	ec26                	sd	s1,24(sp)
    80002f60:	e84a                	sd	s2,16(sp)
    80002f62:	e44e                	sd	s3,8(sp)
    80002f64:	e052                	sd	s4,0(sp)
    80002f66:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f68:	00005597          	auipc	a1,0x5
    80002f6c:	57858593          	addi	a1,a1,1400 # 800084e0 <syscalls+0xb8>
    80002f70:	00015517          	auipc	a0,0x15
    80002f74:	c1050513          	addi	a0,a0,-1008 # 80017b80 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	bf8080e7          	jalr	-1032(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f80:	0001d797          	auipc	a5,0x1d
    80002f84:	c0078793          	addi	a5,a5,-1024 # 8001fb80 <bcache+0x8000>
    80002f88:	0001d717          	auipc	a4,0x1d
    80002f8c:	e6070713          	addi	a4,a4,-416 # 8001fde8 <bcache+0x8268>
    80002f90:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f94:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f98:	00015497          	auipc	s1,0x15
    80002f9c:	c0048493          	addi	s1,s1,-1024 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    80002fa0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fa2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fa4:	00005a17          	auipc	s4,0x5
    80002fa8:	544a0a13          	addi	s4,s4,1348 # 800084e8 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002fac:	2b893783          	ld	a5,696(s2)
    80002fb0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fb2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fb6:	85d2                	mv	a1,s4
    80002fb8:	01048513          	addi	a0,s1,16
    80002fbc:	00001097          	auipc	ra,0x1
    80002fc0:	4b2080e7          	jalr	1202(ra) # 8000446e <initsleeplock>
    bcache.head.next->prev = b;
    80002fc4:	2b893783          	ld	a5,696(s2)
    80002fc8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fca:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fce:	45848493          	addi	s1,s1,1112
    80002fd2:	fd349de3          	bne	s1,s3,80002fac <binit+0x54>
  }
}
    80002fd6:	70a2                	ld	ra,40(sp)
    80002fd8:	7402                	ld	s0,32(sp)
    80002fda:	64e2                	ld	s1,24(sp)
    80002fdc:	6942                	ld	s2,16(sp)
    80002fde:	69a2                	ld	s3,8(sp)
    80002fe0:	6a02                	ld	s4,0(sp)
    80002fe2:	6145                	addi	sp,sp,48
    80002fe4:	8082                	ret

0000000080002fe6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fe6:	7179                	addi	sp,sp,-48
    80002fe8:	f406                	sd	ra,40(sp)
    80002fea:	f022                	sd	s0,32(sp)
    80002fec:	ec26                	sd	s1,24(sp)
    80002fee:	e84a                	sd	s2,16(sp)
    80002ff0:	e44e                	sd	s3,8(sp)
    80002ff2:	1800                	addi	s0,sp,48
    80002ff4:	892a                	mv	s2,a0
    80002ff6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ff8:	00015517          	auipc	a0,0x15
    80002ffc:	b8850513          	addi	a0,a0,-1144 # 80017b80 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	c00080e7          	jalr	-1024(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003008:	0001d497          	auipc	s1,0x1d
    8000300c:	e304b483          	ld	s1,-464(s1) # 8001fe38 <bcache+0x82b8>
    80003010:	0001d797          	auipc	a5,0x1d
    80003014:	dd878793          	addi	a5,a5,-552 # 8001fde8 <bcache+0x8268>
    80003018:	02f48f63          	beq	s1,a5,80003056 <bread+0x70>
    8000301c:	873e                	mv	a4,a5
    8000301e:	a021                	j	80003026 <bread+0x40>
    80003020:	68a4                	ld	s1,80(s1)
    80003022:	02e48a63          	beq	s1,a4,80003056 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003026:	449c                	lw	a5,8(s1)
    80003028:	ff279ce3          	bne	a5,s2,80003020 <bread+0x3a>
    8000302c:	44dc                	lw	a5,12(s1)
    8000302e:	ff3799e3          	bne	a5,s3,80003020 <bread+0x3a>
      b->refcnt++;
    80003032:	40bc                	lw	a5,64(s1)
    80003034:	2785                	addiw	a5,a5,1
    80003036:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003038:	00015517          	auipc	a0,0x15
    8000303c:	b4850513          	addi	a0,a0,-1208 # 80017b80 <bcache>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	c74080e7          	jalr	-908(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80003048:	01048513          	addi	a0,s1,16
    8000304c:	00001097          	auipc	ra,0x1
    80003050:	45c080e7          	jalr	1116(ra) # 800044a8 <acquiresleep>
      return b;
    80003054:	a8b9                	j	800030b2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003056:	0001d497          	auipc	s1,0x1d
    8000305a:	dda4b483          	ld	s1,-550(s1) # 8001fe30 <bcache+0x82b0>
    8000305e:	0001d797          	auipc	a5,0x1d
    80003062:	d8a78793          	addi	a5,a5,-630 # 8001fde8 <bcache+0x8268>
    80003066:	00f48863          	beq	s1,a5,80003076 <bread+0x90>
    8000306a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000306c:	40bc                	lw	a5,64(s1)
    8000306e:	cf81                	beqz	a5,80003086 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003070:	64a4                	ld	s1,72(s1)
    80003072:	fee49de3          	bne	s1,a4,8000306c <bread+0x86>
  panic("bget: no buffers");
    80003076:	00005517          	auipc	a0,0x5
    8000307a:	47a50513          	addi	a0,a0,1146 # 800084f0 <syscalls+0xc8>
    8000307e:	ffffd097          	auipc	ra,0xffffd
    80003082:	4c8080e7          	jalr	1224(ra) # 80000546 <panic>
      b->dev = dev;
    80003086:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000308a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000308e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003092:	4785                	li	a5,1
    80003094:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003096:	00015517          	auipc	a0,0x15
    8000309a:	aea50513          	addi	a0,a0,-1302 # 80017b80 <bcache>
    8000309e:	ffffe097          	auipc	ra,0xffffe
    800030a2:	c16080e7          	jalr	-1002(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    800030a6:	01048513          	addi	a0,s1,16
    800030aa:	00001097          	auipc	ra,0x1
    800030ae:	3fe080e7          	jalr	1022(ra) # 800044a8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030b2:	409c                	lw	a5,0(s1)
    800030b4:	cb89                	beqz	a5,800030c6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030b6:	8526                	mv	a0,s1
    800030b8:	70a2                	ld	ra,40(sp)
    800030ba:	7402                	ld	s0,32(sp)
    800030bc:	64e2                	ld	s1,24(sp)
    800030be:	6942                	ld	s2,16(sp)
    800030c0:	69a2                	ld	s3,8(sp)
    800030c2:	6145                	addi	sp,sp,48
    800030c4:	8082                	ret
    virtio_disk_rw(b, 0);
    800030c6:	4581                	li	a1,0
    800030c8:	8526                	mv	a0,s1
    800030ca:	00003097          	auipc	ra,0x3
    800030ce:	03e080e7          	jalr	62(ra) # 80006108 <virtio_disk_rw>
    b->valid = 1;
    800030d2:	4785                	li	a5,1
    800030d4:	c09c                	sw	a5,0(s1)
  return b;
    800030d6:	b7c5                	j	800030b6 <bread+0xd0>

00000000800030d8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030d8:	1101                	addi	sp,sp,-32
    800030da:	ec06                	sd	ra,24(sp)
    800030dc:	e822                	sd	s0,16(sp)
    800030de:	e426                	sd	s1,8(sp)
    800030e0:	1000                	addi	s0,sp,32
    800030e2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030e4:	0541                	addi	a0,a0,16
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	45c080e7          	jalr	1116(ra) # 80004542 <holdingsleep>
    800030ee:	cd01                	beqz	a0,80003106 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030f0:	4585                	li	a1,1
    800030f2:	8526                	mv	a0,s1
    800030f4:	00003097          	auipc	ra,0x3
    800030f8:	014080e7          	jalr	20(ra) # 80006108 <virtio_disk_rw>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret
    panic("bwrite");
    80003106:	00005517          	auipc	a0,0x5
    8000310a:	40250513          	addi	a0,a0,1026 # 80008508 <syscalls+0xe0>
    8000310e:	ffffd097          	auipc	ra,0xffffd
    80003112:	438080e7          	jalr	1080(ra) # 80000546 <panic>

0000000080003116 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	e04a                	sd	s2,0(sp)
    80003120:	1000                	addi	s0,sp,32
    80003122:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003124:	01050913          	addi	s2,a0,16
    80003128:	854a                	mv	a0,s2
    8000312a:	00001097          	auipc	ra,0x1
    8000312e:	418080e7          	jalr	1048(ra) # 80004542 <holdingsleep>
    80003132:	c92d                	beqz	a0,800031a4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003134:	854a                	mv	a0,s2
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	3c8080e7          	jalr	968(ra) # 800044fe <releasesleep>

  acquire(&bcache.lock);
    8000313e:	00015517          	auipc	a0,0x15
    80003142:	a4250513          	addi	a0,a0,-1470 # 80017b80 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	aba080e7          	jalr	-1350(ra) # 80000c00 <acquire>
  b->refcnt--;
    8000314e:	40bc                	lw	a5,64(s1)
    80003150:	37fd                	addiw	a5,a5,-1
    80003152:	0007871b          	sext.w	a4,a5
    80003156:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003158:	eb05                	bnez	a4,80003188 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000315a:	68bc                	ld	a5,80(s1)
    8000315c:	64b8                	ld	a4,72(s1)
    8000315e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003160:	64bc                	ld	a5,72(s1)
    80003162:	68b8                	ld	a4,80(s1)
    80003164:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003166:	0001d797          	auipc	a5,0x1d
    8000316a:	a1a78793          	addi	a5,a5,-1510 # 8001fb80 <bcache+0x8000>
    8000316e:	2b87b703          	ld	a4,696(a5)
    80003172:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003174:	0001d717          	auipc	a4,0x1d
    80003178:	c7470713          	addi	a4,a4,-908 # 8001fde8 <bcache+0x8268>
    8000317c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000317e:	2b87b703          	ld	a4,696(a5)
    80003182:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003184:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003188:	00015517          	auipc	a0,0x15
    8000318c:	9f850513          	addi	a0,a0,-1544 # 80017b80 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	b24080e7          	jalr	-1244(ra) # 80000cb4 <release>
}
    80003198:	60e2                	ld	ra,24(sp)
    8000319a:	6442                	ld	s0,16(sp)
    8000319c:	64a2                	ld	s1,8(sp)
    8000319e:	6902                	ld	s2,0(sp)
    800031a0:	6105                	addi	sp,sp,32
    800031a2:	8082                	ret
    panic("brelse");
    800031a4:	00005517          	auipc	a0,0x5
    800031a8:	36c50513          	addi	a0,a0,876 # 80008510 <syscalls+0xe8>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	39a080e7          	jalr	922(ra) # 80000546 <panic>

00000000800031b4 <bpin>:

void
bpin(struct buf *b) {
    800031b4:	1101                	addi	sp,sp,-32
    800031b6:	ec06                	sd	ra,24(sp)
    800031b8:	e822                	sd	s0,16(sp)
    800031ba:	e426                	sd	s1,8(sp)
    800031bc:	1000                	addi	s0,sp,32
    800031be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c0:	00015517          	auipc	a0,0x15
    800031c4:	9c050513          	addi	a0,a0,-1600 # 80017b80 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	a38080e7          	jalr	-1480(ra) # 80000c00 <acquire>
  b->refcnt++;
    800031d0:	40bc                	lw	a5,64(s1)
    800031d2:	2785                	addiw	a5,a5,1
    800031d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031d6:	00015517          	auipc	a0,0x15
    800031da:	9aa50513          	addi	a0,a0,-1622 # 80017b80 <bcache>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	ad6080e7          	jalr	-1322(ra) # 80000cb4 <release>
}
    800031e6:	60e2                	ld	ra,24(sp)
    800031e8:	6442                	ld	s0,16(sp)
    800031ea:	64a2                	ld	s1,8(sp)
    800031ec:	6105                	addi	sp,sp,32
    800031ee:	8082                	ret

00000000800031f0 <bunpin>:

void
bunpin(struct buf *b) {
    800031f0:	1101                	addi	sp,sp,-32
    800031f2:	ec06                	sd	ra,24(sp)
    800031f4:	e822                	sd	s0,16(sp)
    800031f6:	e426                	sd	s1,8(sp)
    800031f8:	1000                	addi	s0,sp,32
    800031fa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031fc:	00015517          	auipc	a0,0x15
    80003200:	98450513          	addi	a0,a0,-1660 # 80017b80 <bcache>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	9fc080e7          	jalr	-1540(ra) # 80000c00 <acquire>
  b->refcnt--;
    8000320c:	40bc                	lw	a5,64(s1)
    8000320e:	37fd                	addiw	a5,a5,-1
    80003210:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003212:	00015517          	auipc	a0,0x15
    80003216:	96e50513          	addi	a0,a0,-1682 # 80017b80 <bcache>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	a9a080e7          	jalr	-1382(ra) # 80000cb4 <release>
}
    80003222:	60e2                	ld	ra,24(sp)
    80003224:	6442                	ld	s0,16(sp)
    80003226:	64a2                	ld	s1,8(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret

000000008000322c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	e426                	sd	s1,8(sp)
    80003234:	e04a                	sd	s2,0(sp)
    80003236:	1000                	addi	s0,sp,32
    80003238:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000323a:	00d5d59b          	srliw	a1,a1,0xd
    8000323e:	0001d797          	auipc	a5,0x1d
    80003242:	01e7a783          	lw	a5,30(a5) # 8002025c <sb+0x1c>
    80003246:	9dbd                	addw	a1,a1,a5
    80003248:	00000097          	auipc	ra,0x0
    8000324c:	d9e080e7          	jalr	-610(ra) # 80002fe6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003250:	0074f713          	andi	a4,s1,7
    80003254:	4785                	li	a5,1
    80003256:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000325a:	14ce                	slli	s1,s1,0x33
    8000325c:	90d9                	srli	s1,s1,0x36
    8000325e:	00950733          	add	a4,a0,s1
    80003262:	05874703          	lbu	a4,88(a4)
    80003266:	00e7f6b3          	and	a3,a5,a4
    8000326a:	c69d                	beqz	a3,80003298 <bfree+0x6c>
    8000326c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000326e:	94aa                	add	s1,s1,a0
    80003270:	fff7c793          	not	a5,a5
    80003274:	8f7d                	and	a4,a4,a5
    80003276:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000327a:	00001097          	auipc	ra,0x1
    8000327e:	108080e7          	jalr	264(ra) # 80004382 <log_write>
  brelse(bp);
    80003282:	854a                	mv	a0,s2
    80003284:	00000097          	auipc	ra,0x0
    80003288:	e92080e7          	jalr	-366(ra) # 80003116 <brelse>
}
    8000328c:	60e2                	ld	ra,24(sp)
    8000328e:	6442                	ld	s0,16(sp)
    80003290:	64a2                	ld	s1,8(sp)
    80003292:	6902                	ld	s2,0(sp)
    80003294:	6105                	addi	sp,sp,32
    80003296:	8082                	ret
    panic("freeing free block");
    80003298:	00005517          	auipc	a0,0x5
    8000329c:	28050513          	addi	a0,a0,640 # 80008518 <syscalls+0xf0>
    800032a0:	ffffd097          	auipc	ra,0xffffd
    800032a4:	2a6080e7          	jalr	678(ra) # 80000546 <panic>

00000000800032a8 <balloc>:
{
    800032a8:	711d                	addi	sp,sp,-96
    800032aa:	ec86                	sd	ra,88(sp)
    800032ac:	e8a2                	sd	s0,80(sp)
    800032ae:	e4a6                	sd	s1,72(sp)
    800032b0:	e0ca                	sd	s2,64(sp)
    800032b2:	fc4e                	sd	s3,56(sp)
    800032b4:	f852                	sd	s4,48(sp)
    800032b6:	f456                	sd	s5,40(sp)
    800032b8:	f05a                	sd	s6,32(sp)
    800032ba:	ec5e                	sd	s7,24(sp)
    800032bc:	e862                	sd	s8,16(sp)
    800032be:	e466                	sd	s9,8(sp)
    800032c0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	0001d797          	auipc	a5,0x1d
    800032c6:	f827a783          	lw	a5,-126(a5) # 80020244 <sb+0x4>
    800032ca:	cbc1                	beqz	a5,8000335a <balloc+0xb2>
    800032cc:	8baa                	mv	s7,a0
    800032ce:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032d0:	0001db17          	auipc	s6,0x1d
    800032d4:	f70b0b13          	addi	s6,s6,-144 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032da:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032dc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032de:	6c89                	lui	s9,0x2
    800032e0:	a831                	j	800032fc <balloc+0x54>
    brelse(bp);
    800032e2:	854a                	mv	a0,s2
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	e32080e7          	jalr	-462(ra) # 80003116 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032ec:	015c87bb          	addw	a5,s9,s5
    800032f0:	00078a9b          	sext.w	s5,a5
    800032f4:	004b2703          	lw	a4,4(s6)
    800032f8:	06eaf163          	bgeu	s5,a4,8000335a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800032fc:	41fad79b          	sraiw	a5,s5,0x1f
    80003300:	0137d79b          	srliw	a5,a5,0x13
    80003304:	015787bb          	addw	a5,a5,s5
    80003308:	40d7d79b          	sraiw	a5,a5,0xd
    8000330c:	01cb2583          	lw	a1,28(s6)
    80003310:	9dbd                	addw	a1,a1,a5
    80003312:	855e                	mv	a0,s7
    80003314:	00000097          	auipc	ra,0x0
    80003318:	cd2080e7          	jalr	-814(ra) # 80002fe6 <bread>
    8000331c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331e:	004b2503          	lw	a0,4(s6)
    80003322:	000a849b          	sext.w	s1,s5
    80003326:	8762                	mv	a4,s8
    80003328:	faa4fde3          	bgeu	s1,a0,800032e2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000332c:	00777693          	andi	a3,a4,7
    80003330:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003334:	41f7579b          	sraiw	a5,a4,0x1f
    80003338:	01d7d79b          	srliw	a5,a5,0x1d
    8000333c:	9fb9                	addw	a5,a5,a4
    8000333e:	4037d79b          	sraiw	a5,a5,0x3
    80003342:	00f90633          	add	a2,s2,a5
    80003346:	05864603          	lbu	a2,88(a2)
    8000334a:	00c6f5b3          	and	a1,a3,a2
    8000334e:	cd91                	beqz	a1,8000336a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003350:	2705                	addiw	a4,a4,1
    80003352:	2485                	addiw	s1,s1,1
    80003354:	fd471ae3          	bne	a4,s4,80003328 <balloc+0x80>
    80003358:	b769                	j	800032e2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000335a:	00005517          	auipc	a0,0x5
    8000335e:	1d650513          	addi	a0,a0,470 # 80008530 <syscalls+0x108>
    80003362:	ffffd097          	auipc	ra,0xffffd
    80003366:	1e4080e7          	jalr	484(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000336a:	97ca                	add	a5,a5,s2
    8000336c:	8e55                	or	a2,a2,a3
    8000336e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003372:	854a                	mv	a0,s2
    80003374:	00001097          	auipc	ra,0x1
    80003378:	00e080e7          	jalr	14(ra) # 80004382 <log_write>
        brelse(bp);
    8000337c:	854a                	mv	a0,s2
    8000337e:	00000097          	auipc	ra,0x0
    80003382:	d98080e7          	jalr	-616(ra) # 80003116 <brelse>
  bp = bread(dev, bno);
    80003386:	85a6                	mv	a1,s1
    80003388:	855e                	mv	a0,s7
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	c5c080e7          	jalr	-932(ra) # 80002fe6 <bread>
    80003392:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003394:	40000613          	li	a2,1024
    80003398:	4581                	li	a1,0
    8000339a:	05850513          	addi	a0,a0,88
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	95e080e7          	jalr	-1698(ra) # 80000cfc <memset>
  log_write(bp);
    800033a6:	854a                	mv	a0,s2
    800033a8:	00001097          	auipc	ra,0x1
    800033ac:	fda080e7          	jalr	-38(ra) # 80004382 <log_write>
  brelse(bp);
    800033b0:	854a                	mv	a0,s2
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	d64080e7          	jalr	-668(ra) # 80003116 <brelse>
}
    800033ba:	8526                	mv	a0,s1
    800033bc:	60e6                	ld	ra,88(sp)
    800033be:	6446                	ld	s0,80(sp)
    800033c0:	64a6                	ld	s1,72(sp)
    800033c2:	6906                	ld	s2,64(sp)
    800033c4:	79e2                	ld	s3,56(sp)
    800033c6:	7a42                	ld	s4,48(sp)
    800033c8:	7aa2                	ld	s5,40(sp)
    800033ca:	7b02                	ld	s6,32(sp)
    800033cc:	6be2                	ld	s7,24(sp)
    800033ce:	6c42                	ld	s8,16(sp)
    800033d0:	6ca2                	ld	s9,8(sp)
    800033d2:	6125                	addi	sp,sp,96
    800033d4:	8082                	ret

00000000800033d6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033d6:	7179                	addi	sp,sp,-48
    800033d8:	f406                	sd	ra,40(sp)
    800033da:	f022                	sd	s0,32(sp)
    800033dc:	ec26                	sd	s1,24(sp)
    800033de:	e84a                	sd	s2,16(sp)
    800033e0:	e44e                	sd	s3,8(sp)
    800033e2:	e052                	sd	s4,0(sp)
    800033e4:	1800                	addi	s0,sp,48
    800033e6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033e8:	47ad                	li	a5,11
    800033ea:	04b7fe63          	bgeu	a5,a1,80003446 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033ee:	ff45849b          	addiw	s1,a1,-12
    800033f2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033f6:	0ff00793          	li	a5,255
    800033fa:	0ae7e463          	bltu	a5,a4,800034a2 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033fe:	08052583          	lw	a1,128(a0)
    80003402:	c5b5                	beqz	a1,8000346e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003404:	00092503          	lw	a0,0(s2)
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	bde080e7          	jalr	-1058(ra) # 80002fe6 <bread>
    80003410:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003412:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003416:	02049713          	slli	a4,s1,0x20
    8000341a:	01e75593          	srli	a1,a4,0x1e
    8000341e:	00b784b3          	add	s1,a5,a1
    80003422:	0004a983          	lw	s3,0(s1)
    80003426:	04098e63          	beqz	s3,80003482 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000342a:	8552                	mv	a0,s4
    8000342c:	00000097          	auipc	ra,0x0
    80003430:	cea080e7          	jalr	-790(ra) # 80003116 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003434:	854e                	mv	a0,s3
    80003436:	70a2                	ld	ra,40(sp)
    80003438:	7402                	ld	s0,32(sp)
    8000343a:	64e2                	ld	s1,24(sp)
    8000343c:	6942                	ld	s2,16(sp)
    8000343e:	69a2                	ld	s3,8(sp)
    80003440:	6a02                	ld	s4,0(sp)
    80003442:	6145                	addi	sp,sp,48
    80003444:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003446:	02059793          	slli	a5,a1,0x20
    8000344a:	01e7d593          	srli	a1,a5,0x1e
    8000344e:	00b504b3          	add	s1,a0,a1
    80003452:	0504a983          	lw	s3,80(s1)
    80003456:	fc099fe3          	bnez	s3,80003434 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000345a:	4108                	lw	a0,0(a0)
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e4c080e7          	jalr	-436(ra) # 800032a8 <balloc>
    80003464:	0005099b          	sext.w	s3,a0
    80003468:	0534a823          	sw	s3,80(s1)
    8000346c:	b7e1                	j	80003434 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000346e:	4108                	lw	a0,0(a0)
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e38080e7          	jalr	-456(ra) # 800032a8 <balloc>
    80003478:	0005059b          	sext.w	a1,a0
    8000347c:	08b92023          	sw	a1,128(s2)
    80003480:	b751                	j	80003404 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003482:	00092503          	lw	a0,0(s2)
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	e22080e7          	jalr	-478(ra) # 800032a8 <balloc>
    8000348e:	0005099b          	sext.w	s3,a0
    80003492:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003496:	8552                	mv	a0,s4
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	eea080e7          	jalr	-278(ra) # 80004382 <log_write>
    800034a0:	b769                	j	8000342a <bmap+0x54>
  panic("bmap: out of range");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	0a650513          	addi	a0,a0,166 # 80008548 <syscalls+0x120>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	09c080e7          	jalr	156(ra) # 80000546 <panic>

00000000800034b2 <iget>:
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	e052                	sd	s4,0(sp)
    800034c0:	1800                	addi	s0,sp,48
    800034c2:	89aa                	mv	s3,a0
    800034c4:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034c6:	0001d517          	auipc	a0,0x1d
    800034ca:	d9a50513          	addi	a0,a0,-614 # 80020260 <icache>
    800034ce:	ffffd097          	auipc	ra,0xffffd
    800034d2:	732080e7          	jalr	1842(ra) # 80000c00 <acquire>
  empty = 0;
    800034d6:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034d8:	0001d497          	auipc	s1,0x1d
    800034dc:	da048493          	addi	s1,s1,-608 # 80020278 <icache+0x18>
    800034e0:	0001f697          	auipc	a3,0x1f
    800034e4:	82868693          	addi	a3,a3,-2008 # 80021d08 <log>
    800034e8:	a039                	j	800034f6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ea:	02090b63          	beqz	s2,80003520 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ee:	08848493          	addi	s1,s1,136
    800034f2:	02d48a63          	beq	s1,a3,80003526 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034f6:	449c                	lw	a5,8(s1)
    800034f8:	fef059e3          	blez	a5,800034ea <iget+0x38>
    800034fc:	4098                	lw	a4,0(s1)
    800034fe:	ff3716e3          	bne	a4,s3,800034ea <iget+0x38>
    80003502:	40d8                	lw	a4,4(s1)
    80003504:	ff4713e3          	bne	a4,s4,800034ea <iget+0x38>
      ip->ref++;
    80003508:	2785                	addiw	a5,a5,1
    8000350a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000350c:	0001d517          	auipc	a0,0x1d
    80003510:	d5450513          	addi	a0,a0,-684 # 80020260 <icache>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	7a0080e7          	jalr	1952(ra) # 80000cb4 <release>
      return ip;
    8000351c:	8926                	mv	s2,s1
    8000351e:	a03d                	j	8000354c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003520:	f7f9                	bnez	a5,800034ee <iget+0x3c>
    80003522:	8926                	mv	s2,s1
    80003524:	b7e9                	j	800034ee <iget+0x3c>
  if(empty == 0)
    80003526:	02090c63          	beqz	s2,8000355e <iget+0xac>
  ip->dev = dev;
    8000352a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000352e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003532:	4785                	li	a5,1
    80003534:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003538:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000353c:	0001d517          	auipc	a0,0x1d
    80003540:	d2450513          	addi	a0,a0,-732 # 80020260 <icache>
    80003544:	ffffd097          	auipc	ra,0xffffd
    80003548:	770080e7          	jalr	1904(ra) # 80000cb4 <release>
}
    8000354c:	854a                	mv	a0,s2
    8000354e:	70a2                	ld	ra,40(sp)
    80003550:	7402                	ld	s0,32(sp)
    80003552:	64e2                	ld	s1,24(sp)
    80003554:	6942                	ld	s2,16(sp)
    80003556:	69a2                	ld	s3,8(sp)
    80003558:	6a02                	ld	s4,0(sp)
    8000355a:	6145                	addi	sp,sp,48
    8000355c:	8082                	ret
    panic("iget: no inodes");
    8000355e:	00005517          	auipc	a0,0x5
    80003562:	00250513          	addi	a0,a0,2 # 80008560 <syscalls+0x138>
    80003566:	ffffd097          	auipc	ra,0xffffd
    8000356a:	fe0080e7          	jalr	-32(ra) # 80000546 <panic>

000000008000356e <fsinit>:
fsinit(int dev) {
    8000356e:	7179                	addi	sp,sp,-48
    80003570:	f406                	sd	ra,40(sp)
    80003572:	f022                	sd	s0,32(sp)
    80003574:	ec26                	sd	s1,24(sp)
    80003576:	e84a                	sd	s2,16(sp)
    80003578:	e44e                	sd	s3,8(sp)
    8000357a:	1800                	addi	s0,sp,48
    8000357c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000357e:	4585                	li	a1,1
    80003580:	00000097          	auipc	ra,0x0
    80003584:	a66080e7          	jalr	-1434(ra) # 80002fe6 <bread>
    80003588:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000358a:	0001d997          	auipc	s3,0x1d
    8000358e:	cb698993          	addi	s3,s3,-842 # 80020240 <sb>
    80003592:	02000613          	li	a2,32
    80003596:	05850593          	addi	a1,a0,88
    8000359a:	854e                	mv	a0,s3
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	7bc080e7          	jalr	1980(ra) # 80000d58 <memmove>
  brelse(bp);
    800035a4:	8526                	mv	a0,s1
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	b70080e7          	jalr	-1168(ra) # 80003116 <brelse>
  if(sb.magic != FSMAGIC)
    800035ae:	0009a703          	lw	a4,0(s3)
    800035b2:	102037b7          	lui	a5,0x10203
    800035b6:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ba:	02f71263          	bne	a4,a5,800035de <fsinit+0x70>
  initlog(dev, &sb);
    800035be:	0001d597          	auipc	a1,0x1d
    800035c2:	c8258593          	addi	a1,a1,-894 # 80020240 <sb>
    800035c6:	854a                	mv	a0,s2
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	b42080e7          	jalr	-1214(ra) # 8000410a <initlog>
}
    800035d0:	70a2                	ld	ra,40(sp)
    800035d2:	7402                	ld	s0,32(sp)
    800035d4:	64e2                	ld	s1,24(sp)
    800035d6:	6942                	ld	s2,16(sp)
    800035d8:	69a2                	ld	s3,8(sp)
    800035da:	6145                	addi	sp,sp,48
    800035dc:	8082                	ret
    panic("invalid file system");
    800035de:	00005517          	auipc	a0,0x5
    800035e2:	f9250513          	addi	a0,a0,-110 # 80008570 <syscalls+0x148>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f60080e7          	jalr	-160(ra) # 80000546 <panic>

00000000800035ee <iinit>:
{
    800035ee:	7179                	addi	sp,sp,-48
    800035f0:	f406                	sd	ra,40(sp)
    800035f2:	f022                	sd	s0,32(sp)
    800035f4:	ec26                	sd	s1,24(sp)
    800035f6:	e84a                	sd	s2,16(sp)
    800035f8:	e44e                	sd	s3,8(sp)
    800035fa:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035fc:	00005597          	auipc	a1,0x5
    80003600:	f8c58593          	addi	a1,a1,-116 # 80008588 <syscalls+0x160>
    80003604:	0001d517          	auipc	a0,0x1d
    80003608:	c5c50513          	addi	a0,a0,-932 # 80020260 <icache>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	564080e7          	jalr	1380(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003614:	0001d497          	auipc	s1,0x1d
    80003618:	c7448493          	addi	s1,s1,-908 # 80020288 <icache+0x28>
    8000361c:	0001e997          	auipc	s3,0x1e
    80003620:	6fc98993          	addi	s3,s3,1788 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003624:	00005917          	auipc	s2,0x5
    80003628:	f6c90913          	addi	s2,s2,-148 # 80008590 <syscalls+0x168>
    8000362c:	85ca                	mv	a1,s2
    8000362e:	8526                	mv	a0,s1
    80003630:	00001097          	auipc	ra,0x1
    80003634:	e3e080e7          	jalr	-450(ra) # 8000446e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003638:	08848493          	addi	s1,s1,136
    8000363c:	ff3498e3          	bne	s1,s3,8000362c <iinit+0x3e>
}
    80003640:	70a2                	ld	ra,40(sp)
    80003642:	7402                	ld	s0,32(sp)
    80003644:	64e2                	ld	s1,24(sp)
    80003646:	6942                	ld	s2,16(sp)
    80003648:	69a2                	ld	s3,8(sp)
    8000364a:	6145                	addi	sp,sp,48
    8000364c:	8082                	ret

000000008000364e <ialloc>:
{
    8000364e:	715d                	addi	sp,sp,-80
    80003650:	e486                	sd	ra,72(sp)
    80003652:	e0a2                	sd	s0,64(sp)
    80003654:	fc26                	sd	s1,56(sp)
    80003656:	f84a                	sd	s2,48(sp)
    80003658:	f44e                	sd	s3,40(sp)
    8000365a:	f052                	sd	s4,32(sp)
    8000365c:	ec56                	sd	s5,24(sp)
    8000365e:	e85a                	sd	s6,16(sp)
    80003660:	e45e                	sd	s7,8(sp)
    80003662:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003664:	0001d717          	auipc	a4,0x1d
    80003668:	be872703          	lw	a4,-1048(a4) # 8002024c <sb+0xc>
    8000366c:	4785                	li	a5,1
    8000366e:	04e7fa63          	bgeu	a5,a4,800036c2 <ialloc+0x74>
    80003672:	8aaa                	mv	s5,a0
    80003674:	8bae                	mv	s7,a1
    80003676:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003678:	0001da17          	auipc	s4,0x1d
    8000367c:	bc8a0a13          	addi	s4,s4,-1080 # 80020240 <sb>
    80003680:	00048b1b          	sext.w	s6,s1
    80003684:	0044d593          	srli	a1,s1,0x4
    80003688:	018a2783          	lw	a5,24(s4)
    8000368c:	9dbd                	addw	a1,a1,a5
    8000368e:	8556                	mv	a0,s5
    80003690:	00000097          	auipc	ra,0x0
    80003694:	956080e7          	jalr	-1706(ra) # 80002fe6 <bread>
    80003698:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000369a:	05850993          	addi	s3,a0,88
    8000369e:	00f4f793          	andi	a5,s1,15
    800036a2:	079a                	slli	a5,a5,0x6
    800036a4:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036a6:	00099783          	lh	a5,0(s3)
    800036aa:	c785                	beqz	a5,800036d2 <ialloc+0x84>
    brelse(bp);
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	a6a080e7          	jalr	-1430(ra) # 80003116 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036b4:	0485                	addi	s1,s1,1
    800036b6:	00ca2703          	lw	a4,12(s4)
    800036ba:	0004879b          	sext.w	a5,s1
    800036be:	fce7e1e3          	bltu	a5,a4,80003680 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	ed650513          	addi	a0,a0,-298 # 80008598 <syscalls+0x170>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e7c080e7          	jalr	-388(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    800036d2:	04000613          	li	a2,64
    800036d6:	4581                	li	a1,0
    800036d8:	854e                	mv	a0,s3
    800036da:	ffffd097          	auipc	ra,0xffffd
    800036de:	622080e7          	jalr	1570(ra) # 80000cfc <memset>
      dip->type = type;
    800036e2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036e6:	854a                	mv	a0,s2
    800036e8:	00001097          	auipc	ra,0x1
    800036ec:	c9a080e7          	jalr	-870(ra) # 80004382 <log_write>
      brelse(bp);
    800036f0:	854a                	mv	a0,s2
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	a24080e7          	jalr	-1500(ra) # 80003116 <brelse>
      return iget(dev, inum);
    800036fa:	85da                	mv	a1,s6
    800036fc:	8556                	mv	a0,s5
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	db4080e7          	jalr	-588(ra) # 800034b2 <iget>
}
    80003706:	60a6                	ld	ra,72(sp)
    80003708:	6406                	ld	s0,64(sp)
    8000370a:	74e2                	ld	s1,56(sp)
    8000370c:	7942                	ld	s2,48(sp)
    8000370e:	79a2                	ld	s3,40(sp)
    80003710:	7a02                	ld	s4,32(sp)
    80003712:	6ae2                	ld	s5,24(sp)
    80003714:	6b42                	ld	s6,16(sp)
    80003716:	6ba2                	ld	s7,8(sp)
    80003718:	6161                	addi	sp,sp,80
    8000371a:	8082                	ret

000000008000371c <iupdate>:
{
    8000371c:	1101                	addi	sp,sp,-32
    8000371e:	ec06                	sd	ra,24(sp)
    80003720:	e822                	sd	s0,16(sp)
    80003722:	e426                	sd	s1,8(sp)
    80003724:	e04a                	sd	s2,0(sp)
    80003726:	1000                	addi	s0,sp,32
    80003728:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000372a:	415c                	lw	a5,4(a0)
    8000372c:	0047d79b          	srliw	a5,a5,0x4
    80003730:	0001d597          	auipc	a1,0x1d
    80003734:	b285a583          	lw	a1,-1240(a1) # 80020258 <sb+0x18>
    80003738:	9dbd                	addw	a1,a1,a5
    8000373a:	4108                	lw	a0,0(a0)
    8000373c:	00000097          	auipc	ra,0x0
    80003740:	8aa080e7          	jalr	-1878(ra) # 80002fe6 <bread>
    80003744:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003746:	05850793          	addi	a5,a0,88
    8000374a:	40d8                	lw	a4,4(s1)
    8000374c:	8b3d                	andi	a4,a4,15
    8000374e:	071a                	slli	a4,a4,0x6
    80003750:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003752:	04449703          	lh	a4,68(s1)
    80003756:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000375a:	04649703          	lh	a4,70(s1)
    8000375e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003762:	04849703          	lh	a4,72(s1)
    80003766:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000376a:	04a49703          	lh	a4,74(s1)
    8000376e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003772:	44f8                	lw	a4,76(s1)
    80003774:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003776:	03400613          	li	a2,52
    8000377a:	05048593          	addi	a1,s1,80
    8000377e:	00c78513          	addi	a0,a5,12
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	5d6080e7          	jalr	1494(ra) # 80000d58 <memmove>
  log_write(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	bf6080e7          	jalr	-1034(ra) # 80004382 <log_write>
  brelse(bp);
    80003794:	854a                	mv	a0,s2
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	980080e7          	jalr	-1664(ra) # 80003116 <brelse>
}
    8000379e:	60e2                	ld	ra,24(sp)
    800037a0:	6442                	ld	s0,16(sp)
    800037a2:	64a2                	ld	s1,8(sp)
    800037a4:	6902                	ld	s2,0(sp)
    800037a6:	6105                	addi	sp,sp,32
    800037a8:	8082                	ret

00000000800037aa <idup>:
{
    800037aa:	1101                	addi	sp,sp,-32
    800037ac:	ec06                	sd	ra,24(sp)
    800037ae:	e822                	sd	s0,16(sp)
    800037b0:	e426                	sd	s1,8(sp)
    800037b2:	1000                	addi	s0,sp,32
    800037b4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037b6:	0001d517          	auipc	a0,0x1d
    800037ba:	aaa50513          	addi	a0,a0,-1366 # 80020260 <icache>
    800037be:	ffffd097          	auipc	ra,0xffffd
    800037c2:	442080e7          	jalr	1090(ra) # 80000c00 <acquire>
  ip->ref++;
    800037c6:	449c                	lw	a5,8(s1)
    800037c8:	2785                	addiw	a5,a5,1
    800037ca:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037cc:	0001d517          	auipc	a0,0x1d
    800037d0:	a9450513          	addi	a0,a0,-1388 # 80020260 <icache>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	4e0080e7          	jalr	1248(ra) # 80000cb4 <release>
}
    800037dc:	8526                	mv	a0,s1
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6105                	addi	sp,sp,32
    800037e6:	8082                	ret

00000000800037e8 <ilock>:
{
    800037e8:	1101                	addi	sp,sp,-32
    800037ea:	ec06                	sd	ra,24(sp)
    800037ec:	e822                	sd	s0,16(sp)
    800037ee:	e426                	sd	s1,8(sp)
    800037f0:	e04a                	sd	s2,0(sp)
    800037f2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037f4:	c115                	beqz	a0,80003818 <ilock+0x30>
    800037f6:	84aa                	mv	s1,a0
    800037f8:	451c                	lw	a5,8(a0)
    800037fa:	00f05f63          	blez	a5,80003818 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037fe:	0541                	addi	a0,a0,16
    80003800:	00001097          	auipc	ra,0x1
    80003804:	ca8080e7          	jalr	-856(ra) # 800044a8 <acquiresleep>
  if(ip->valid == 0){
    80003808:	40bc                	lw	a5,64(s1)
    8000380a:	cf99                	beqz	a5,80003828 <ilock+0x40>
}
    8000380c:	60e2                	ld	ra,24(sp)
    8000380e:	6442                	ld	s0,16(sp)
    80003810:	64a2                	ld	s1,8(sp)
    80003812:	6902                	ld	s2,0(sp)
    80003814:	6105                	addi	sp,sp,32
    80003816:	8082                	ret
    panic("ilock");
    80003818:	00005517          	auipc	a0,0x5
    8000381c:	d9850513          	addi	a0,a0,-616 # 800085b0 <syscalls+0x188>
    80003820:	ffffd097          	auipc	ra,0xffffd
    80003824:	d26080e7          	jalr	-730(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003828:	40dc                	lw	a5,4(s1)
    8000382a:	0047d79b          	srliw	a5,a5,0x4
    8000382e:	0001d597          	auipc	a1,0x1d
    80003832:	a2a5a583          	lw	a1,-1494(a1) # 80020258 <sb+0x18>
    80003836:	9dbd                	addw	a1,a1,a5
    80003838:	4088                	lw	a0,0(s1)
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	7ac080e7          	jalr	1964(ra) # 80002fe6 <bread>
    80003842:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003844:	05850593          	addi	a1,a0,88
    80003848:	40dc                	lw	a5,4(s1)
    8000384a:	8bbd                	andi	a5,a5,15
    8000384c:	079a                	slli	a5,a5,0x6
    8000384e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003850:	00059783          	lh	a5,0(a1)
    80003854:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003858:	00259783          	lh	a5,2(a1)
    8000385c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003860:	00459783          	lh	a5,4(a1)
    80003864:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003868:	00659783          	lh	a5,6(a1)
    8000386c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003870:	459c                	lw	a5,8(a1)
    80003872:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003874:	03400613          	li	a2,52
    80003878:	05b1                	addi	a1,a1,12
    8000387a:	05048513          	addi	a0,s1,80
    8000387e:	ffffd097          	auipc	ra,0xffffd
    80003882:	4da080e7          	jalr	1242(ra) # 80000d58 <memmove>
    brelse(bp);
    80003886:	854a                	mv	a0,s2
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	88e080e7          	jalr	-1906(ra) # 80003116 <brelse>
    ip->valid = 1;
    80003890:	4785                	li	a5,1
    80003892:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003894:	04449783          	lh	a5,68(s1)
    80003898:	fbb5                	bnez	a5,8000380c <ilock+0x24>
      panic("ilock: no type");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	d1e50513          	addi	a0,a0,-738 # 800085b8 <syscalls+0x190>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	ca4080e7          	jalr	-860(ra) # 80000546 <panic>

00000000800038aa <iunlock>:
{
    800038aa:	1101                	addi	sp,sp,-32
    800038ac:	ec06                	sd	ra,24(sp)
    800038ae:	e822                	sd	s0,16(sp)
    800038b0:	e426                	sd	s1,8(sp)
    800038b2:	e04a                	sd	s2,0(sp)
    800038b4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038b6:	c905                	beqz	a0,800038e6 <iunlock+0x3c>
    800038b8:	84aa                	mv	s1,a0
    800038ba:	01050913          	addi	s2,a0,16
    800038be:	854a                	mv	a0,s2
    800038c0:	00001097          	auipc	ra,0x1
    800038c4:	c82080e7          	jalr	-894(ra) # 80004542 <holdingsleep>
    800038c8:	cd19                	beqz	a0,800038e6 <iunlock+0x3c>
    800038ca:	449c                	lw	a5,8(s1)
    800038cc:	00f05d63          	blez	a5,800038e6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	c2c080e7          	jalr	-980(ra) # 800044fe <releasesleep>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret
    panic("iunlock");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	ce250513          	addi	a0,a0,-798 # 800085c8 <syscalls+0x1a0>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c58080e7          	jalr	-936(ra) # 80000546 <panic>

00000000800038f6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	e052                	sd	s4,0(sp)
    80003904:	1800                	addi	s0,sp,48
    80003906:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003908:	05050493          	addi	s1,a0,80
    8000390c:	08050913          	addi	s2,a0,128
    80003910:	a021                	j	80003918 <itrunc+0x22>
    80003912:	0491                	addi	s1,s1,4
    80003914:	01248d63          	beq	s1,s2,8000392e <itrunc+0x38>
    if(ip->addrs[i]){
    80003918:	408c                	lw	a1,0(s1)
    8000391a:	dde5                	beqz	a1,80003912 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000391c:	0009a503          	lw	a0,0(s3)
    80003920:	00000097          	auipc	ra,0x0
    80003924:	90c080e7          	jalr	-1780(ra) # 8000322c <bfree>
      ip->addrs[i] = 0;
    80003928:	0004a023          	sw	zero,0(s1)
    8000392c:	b7dd                	j	80003912 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000392e:	0809a583          	lw	a1,128(s3)
    80003932:	e185                	bnez	a1,80003952 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003934:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003938:	854e                	mv	a0,s3
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	de2080e7          	jalr	-542(ra) # 8000371c <iupdate>
}
    80003942:	70a2                	ld	ra,40(sp)
    80003944:	7402                	ld	s0,32(sp)
    80003946:	64e2                	ld	s1,24(sp)
    80003948:	6942                	ld	s2,16(sp)
    8000394a:	69a2                	ld	s3,8(sp)
    8000394c:	6a02                	ld	s4,0(sp)
    8000394e:	6145                	addi	sp,sp,48
    80003950:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003952:	0009a503          	lw	a0,0(s3)
    80003956:	fffff097          	auipc	ra,0xfffff
    8000395a:	690080e7          	jalr	1680(ra) # 80002fe6 <bread>
    8000395e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003960:	05850493          	addi	s1,a0,88
    80003964:	45850913          	addi	s2,a0,1112
    80003968:	a021                	j	80003970 <itrunc+0x7a>
    8000396a:	0491                	addi	s1,s1,4
    8000396c:	01248b63          	beq	s1,s2,80003982 <itrunc+0x8c>
      if(a[j])
    80003970:	408c                	lw	a1,0(s1)
    80003972:	dde5                	beqz	a1,8000396a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003974:	0009a503          	lw	a0,0(s3)
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	8b4080e7          	jalr	-1868(ra) # 8000322c <bfree>
    80003980:	b7ed                	j	8000396a <itrunc+0x74>
    brelse(bp);
    80003982:	8552                	mv	a0,s4
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	792080e7          	jalr	1938(ra) # 80003116 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000398c:	0809a583          	lw	a1,128(s3)
    80003990:	0009a503          	lw	a0,0(s3)
    80003994:	00000097          	auipc	ra,0x0
    80003998:	898080e7          	jalr	-1896(ra) # 8000322c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000399c:	0809a023          	sw	zero,128(s3)
    800039a0:	bf51                	j	80003934 <itrunc+0x3e>

00000000800039a2 <iput>:
{
    800039a2:	1101                	addi	sp,sp,-32
    800039a4:	ec06                	sd	ra,24(sp)
    800039a6:	e822                	sd	s0,16(sp)
    800039a8:	e426                	sd	s1,8(sp)
    800039aa:	e04a                	sd	s2,0(sp)
    800039ac:	1000                	addi	s0,sp,32
    800039ae:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039b0:	0001d517          	auipc	a0,0x1d
    800039b4:	8b050513          	addi	a0,a0,-1872 # 80020260 <icache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	248080e7          	jalr	584(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c0:	4498                	lw	a4,8(s1)
    800039c2:	4785                	li	a5,1
    800039c4:	02f70363          	beq	a4,a5,800039ea <iput+0x48>
  ip->ref--;
    800039c8:	449c                	lw	a5,8(s1)
    800039ca:	37fd                	addiw	a5,a5,-1
    800039cc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039ce:	0001d517          	auipc	a0,0x1d
    800039d2:	89250513          	addi	a0,a0,-1902 # 80020260 <icache>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	2de080e7          	jalr	734(ra) # 80000cb4 <release>
}
    800039de:	60e2                	ld	ra,24(sp)
    800039e0:	6442                	ld	s0,16(sp)
    800039e2:	64a2                	ld	s1,8(sp)
    800039e4:	6902                	ld	s2,0(sp)
    800039e6:	6105                	addi	sp,sp,32
    800039e8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039ea:	40bc                	lw	a5,64(s1)
    800039ec:	dff1                	beqz	a5,800039c8 <iput+0x26>
    800039ee:	04a49783          	lh	a5,74(s1)
    800039f2:	fbf9                	bnez	a5,800039c8 <iput+0x26>
    acquiresleep(&ip->lock);
    800039f4:	01048913          	addi	s2,s1,16
    800039f8:	854a                	mv	a0,s2
    800039fa:	00001097          	auipc	ra,0x1
    800039fe:	aae080e7          	jalr	-1362(ra) # 800044a8 <acquiresleep>
    release(&icache.lock);
    80003a02:	0001d517          	auipc	a0,0x1d
    80003a06:	85e50513          	addi	a0,a0,-1954 # 80020260 <icache>
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	2aa080e7          	jalr	682(ra) # 80000cb4 <release>
    itrunc(ip);
    80003a12:	8526                	mv	a0,s1
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	ee2080e7          	jalr	-286(ra) # 800038f6 <itrunc>
    ip->type = 0;
    80003a1c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a20:	8526                	mv	a0,s1
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	cfa080e7          	jalr	-774(ra) # 8000371c <iupdate>
    ip->valid = 0;
    80003a2a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a2e:	854a                	mv	a0,s2
    80003a30:	00001097          	auipc	ra,0x1
    80003a34:	ace080e7          	jalr	-1330(ra) # 800044fe <releasesleep>
    acquire(&icache.lock);
    80003a38:	0001d517          	auipc	a0,0x1d
    80003a3c:	82850513          	addi	a0,a0,-2008 # 80020260 <icache>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	1c0080e7          	jalr	448(ra) # 80000c00 <acquire>
    80003a48:	b741                	j	800039c8 <iput+0x26>

0000000080003a4a <iunlockput>:
{
    80003a4a:	1101                	addi	sp,sp,-32
    80003a4c:	ec06                	sd	ra,24(sp)
    80003a4e:	e822                	sd	s0,16(sp)
    80003a50:	e426                	sd	s1,8(sp)
    80003a52:	1000                	addi	s0,sp,32
    80003a54:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	e54080e7          	jalr	-428(ra) # 800038aa <iunlock>
  iput(ip);
    80003a5e:	8526                	mv	a0,s1
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	f42080e7          	jalr	-190(ra) # 800039a2 <iput>
}
    80003a68:	60e2                	ld	ra,24(sp)
    80003a6a:	6442                	ld	s0,16(sp)
    80003a6c:	64a2                	ld	s1,8(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret

0000000080003a72 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a72:	1141                	addi	sp,sp,-16
    80003a74:	e422                	sd	s0,8(sp)
    80003a76:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a78:	411c                	lw	a5,0(a0)
    80003a7a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a7c:	415c                	lw	a5,4(a0)
    80003a7e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a80:	04451783          	lh	a5,68(a0)
    80003a84:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a88:	04a51783          	lh	a5,74(a0)
    80003a8c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a90:	04c56783          	lwu	a5,76(a0)
    80003a94:	e99c                	sd	a5,16(a1)
}
    80003a96:	6422                	ld	s0,8(sp)
    80003a98:	0141                	addi	sp,sp,16
    80003a9a:	8082                	ret

0000000080003a9c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a9c:	457c                	lw	a5,76(a0)
    80003a9e:	0ed7e863          	bltu	a5,a3,80003b8e <readi+0xf2>
{
    80003aa2:	7159                	addi	sp,sp,-112
    80003aa4:	f486                	sd	ra,104(sp)
    80003aa6:	f0a2                	sd	s0,96(sp)
    80003aa8:	eca6                	sd	s1,88(sp)
    80003aaa:	e8ca                	sd	s2,80(sp)
    80003aac:	e4ce                	sd	s3,72(sp)
    80003aae:	e0d2                	sd	s4,64(sp)
    80003ab0:	fc56                	sd	s5,56(sp)
    80003ab2:	f85a                	sd	s6,48(sp)
    80003ab4:	f45e                	sd	s7,40(sp)
    80003ab6:	f062                	sd	s8,32(sp)
    80003ab8:	ec66                	sd	s9,24(sp)
    80003aba:	e86a                	sd	s10,16(sp)
    80003abc:	e46e                	sd	s11,8(sp)
    80003abe:	1880                	addi	s0,sp,112
    80003ac0:	8baa                	mv	s7,a0
    80003ac2:	8c2e                	mv	s8,a1
    80003ac4:	8ab2                	mv	s5,a2
    80003ac6:	84b6                	mv	s1,a3
    80003ac8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aca:	9f35                	addw	a4,a4,a3
    return 0;
    80003acc:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ace:	08d76f63          	bltu	a4,a3,80003b6c <readi+0xd0>
  if(off + n > ip->size)
    80003ad2:	00e7f463          	bgeu	a5,a4,80003ada <readi+0x3e>
    n = ip->size - off;
    80003ad6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ada:	0a0b0863          	beqz	s6,80003b8a <readi+0xee>
    80003ade:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ae0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ae4:	5cfd                	li	s9,-1
    80003ae6:	a82d                	j	80003b20 <readi+0x84>
    80003ae8:	020a1d93          	slli	s11,s4,0x20
    80003aec:	020ddd93          	srli	s11,s11,0x20
    80003af0:	05890613          	addi	a2,s2,88
    80003af4:	86ee                	mv	a3,s11
    80003af6:	963a                	add	a2,a2,a4
    80003af8:	85d6                	mv	a1,s5
    80003afa:	8562                	mv	a0,s8
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	b14080e7          	jalr	-1260(ra) # 80002610 <either_copyout>
    80003b04:	05950d63          	beq	a0,s9,80003b5e <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b08:	854a                	mv	a0,s2
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	60c080e7          	jalr	1548(ra) # 80003116 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b12:	013a09bb          	addw	s3,s4,s3
    80003b16:	009a04bb          	addw	s1,s4,s1
    80003b1a:	9aee                	add	s5,s5,s11
    80003b1c:	0569f663          	bgeu	s3,s6,80003b68 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b20:	000ba903          	lw	s2,0(s7)
    80003b24:	00a4d59b          	srliw	a1,s1,0xa
    80003b28:	855e                	mv	a0,s7
    80003b2a:	00000097          	auipc	ra,0x0
    80003b2e:	8ac080e7          	jalr	-1876(ra) # 800033d6 <bmap>
    80003b32:	0005059b          	sext.w	a1,a0
    80003b36:	854a                	mv	a0,s2
    80003b38:	fffff097          	auipc	ra,0xfffff
    80003b3c:	4ae080e7          	jalr	1198(ra) # 80002fe6 <bread>
    80003b40:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b42:	3ff4f713          	andi	a4,s1,1023
    80003b46:	40ed07bb          	subw	a5,s10,a4
    80003b4a:	413b06bb          	subw	a3,s6,s3
    80003b4e:	8a3e                	mv	s4,a5
    80003b50:	2781                	sext.w	a5,a5
    80003b52:	0006861b          	sext.w	a2,a3
    80003b56:	f8f679e3          	bgeu	a2,a5,80003ae8 <readi+0x4c>
    80003b5a:	8a36                	mv	s4,a3
    80003b5c:	b771                	j	80003ae8 <readi+0x4c>
      brelse(bp);
    80003b5e:	854a                	mv	a0,s2
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	5b6080e7          	jalr	1462(ra) # 80003116 <brelse>
  }
  return tot;
    80003b68:	0009851b          	sext.w	a0,s3
}
    80003b6c:	70a6                	ld	ra,104(sp)
    80003b6e:	7406                	ld	s0,96(sp)
    80003b70:	64e6                	ld	s1,88(sp)
    80003b72:	6946                	ld	s2,80(sp)
    80003b74:	69a6                	ld	s3,72(sp)
    80003b76:	6a06                	ld	s4,64(sp)
    80003b78:	7ae2                	ld	s5,56(sp)
    80003b7a:	7b42                	ld	s6,48(sp)
    80003b7c:	7ba2                	ld	s7,40(sp)
    80003b7e:	7c02                	ld	s8,32(sp)
    80003b80:	6ce2                	ld	s9,24(sp)
    80003b82:	6d42                	ld	s10,16(sp)
    80003b84:	6da2                	ld	s11,8(sp)
    80003b86:	6165                	addi	sp,sp,112
    80003b88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b8a:	89da                	mv	s3,s6
    80003b8c:	bff1                	j	80003b68 <readi+0xcc>
    return 0;
    80003b8e:	4501                	li	a0,0
}
    80003b90:	8082                	ret

0000000080003b92 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b92:	457c                	lw	a5,76(a0)
    80003b94:	10d7e663          	bltu	a5,a3,80003ca0 <writei+0x10e>
{
    80003b98:	7159                	addi	sp,sp,-112
    80003b9a:	f486                	sd	ra,104(sp)
    80003b9c:	f0a2                	sd	s0,96(sp)
    80003b9e:	eca6                	sd	s1,88(sp)
    80003ba0:	e8ca                	sd	s2,80(sp)
    80003ba2:	e4ce                	sd	s3,72(sp)
    80003ba4:	e0d2                	sd	s4,64(sp)
    80003ba6:	fc56                	sd	s5,56(sp)
    80003ba8:	f85a                	sd	s6,48(sp)
    80003baa:	f45e                	sd	s7,40(sp)
    80003bac:	f062                	sd	s8,32(sp)
    80003bae:	ec66                	sd	s9,24(sp)
    80003bb0:	e86a                	sd	s10,16(sp)
    80003bb2:	e46e                	sd	s11,8(sp)
    80003bb4:	1880                	addi	s0,sp,112
    80003bb6:	8baa                	mv	s7,a0
    80003bb8:	8c2e                	mv	s8,a1
    80003bba:	8ab2                	mv	s5,a2
    80003bbc:	8936                	mv	s2,a3
    80003bbe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc0:	00e687bb          	addw	a5,a3,a4
    80003bc4:	0ed7e063          	bltu	a5,a3,80003ca4 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bc8:	00043737          	lui	a4,0x43
    80003bcc:	0cf76e63          	bltu	a4,a5,80003ca8 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bd0:	0a0b0763          	beqz	s6,80003c7e <writei+0xec>
    80003bd4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bda:	5cfd                	li	s9,-1
    80003bdc:	a091                	j	80003c20 <writei+0x8e>
    80003bde:	02099d93          	slli	s11,s3,0x20
    80003be2:	020ddd93          	srli	s11,s11,0x20
    80003be6:	05848513          	addi	a0,s1,88
    80003bea:	86ee                	mv	a3,s11
    80003bec:	8656                	mv	a2,s5
    80003bee:	85e2                	mv	a1,s8
    80003bf0:	953a                	add	a0,a0,a4
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	a74080e7          	jalr	-1420(ra) # 80002666 <either_copyin>
    80003bfa:	07950263          	beq	a0,s9,80003c5e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	782080e7          	jalr	1922(ra) # 80004382 <log_write>
    brelse(bp);
    80003c08:	8526                	mv	a0,s1
    80003c0a:	fffff097          	auipc	ra,0xfffff
    80003c0e:	50c080e7          	jalr	1292(ra) # 80003116 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c12:	01498a3b          	addw	s4,s3,s4
    80003c16:	0129893b          	addw	s2,s3,s2
    80003c1a:	9aee                	add	s5,s5,s11
    80003c1c:	056a7663          	bgeu	s4,s6,80003c68 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c20:	000ba483          	lw	s1,0(s7)
    80003c24:	00a9559b          	srliw	a1,s2,0xa
    80003c28:	855e                	mv	a0,s7
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	7ac080e7          	jalr	1964(ra) # 800033d6 <bmap>
    80003c32:	0005059b          	sext.w	a1,a0
    80003c36:	8526                	mv	a0,s1
    80003c38:	fffff097          	auipc	ra,0xfffff
    80003c3c:	3ae080e7          	jalr	942(ra) # 80002fe6 <bread>
    80003c40:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c42:	3ff97713          	andi	a4,s2,1023
    80003c46:	40ed07bb          	subw	a5,s10,a4
    80003c4a:	414b06bb          	subw	a3,s6,s4
    80003c4e:	89be                	mv	s3,a5
    80003c50:	2781                	sext.w	a5,a5
    80003c52:	0006861b          	sext.w	a2,a3
    80003c56:	f8f674e3          	bgeu	a2,a5,80003bde <writei+0x4c>
    80003c5a:	89b6                	mv	s3,a3
    80003c5c:	b749                	j	80003bde <writei+0x4c>
      brelse(bp);
    80003c5e:	8526                	mv	a0,s1
    80003c60:	fffff097          	auipc	ra,0xfffff
    80003c64:	4b6080e7          	jalr	1206(ra) # 80003116 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c68:	04cba783          	lw	a5,76(s7)
    80003c6c:	0127f463          	bgeu	a5,s2,80003c74 <writei+0xe2>
      ip->size = off;
    80003c70:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c74:	855e                	mv	a0,s7
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	aa6080e7          	jalr	-1370(ra) # 8000371c <iupdate>
  }

  return n;
    80003c7e:	000b051b          	sext.w	a0,s6
}
    80003c82:	70a6                	ld	ra,104(sp)
    80003c84:	7406                	ld	s0,96(sp)
    80003c86:	64e6                	ld	s1,88(sp)
    80003c88:	6946                	ld	s2,80(sp)
    80003c8a:	69a6                	ld	s3,72(sp)
    80003c8c:	6a06                	ld	s4,64(sp)
    80003c8e:	7ae2                	ld	s5,56(sp)
    80003c90:	7b42                	ld	s6,48(sp)
    80003c92:	7ba2                	ld	s7,40(sp)
    80003c94:	7c02                	ld	s8,32(sp)
    80003c96:	6ce2                	ld	s9,24(sp)
    80003c98:	6d42                	ld	s10,16(sp)
    80003c9a:	6da2                	ld	s11,8(sp)
    80003c9c:	6165                	addi	sp,sp,112
    80003c9e:	8082                	ret
    return -1;
    80003ca0:	557d                	li	a0,-1
}
    80003ca2:	8082                	ret
    return -1;
    80003ca4:	557d                	li	a0,-1
    80003ca6:	bff1                	j	80003c82 <writei+0xf0>
    return -1;
    80003ca8:	557d                	li	a0,-1
    80003caa:	bfe1                	j	80003c82 <writei+0xf0>

0000000080003cac <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cac:	1141                	addi	sp,sp,-16
    80003cae:	e406                	sd	ra,8(sp)
    80003cb0:	e022                	sd	s0,0(sp)
    80003cb2:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cb4:	4639                	li	a2,14
    80003cb6:	ffffd097          	auipc	ra,0xffffd
    80003cba:	11e080e7          	jalr	286(ra) # 80000dd4 <strncmp>
}
    80003cbe:	60a2                	ld	ra,8(sp)
    80003cc0:	6402                	ld	s0,0(sp)
    80003cc2:	0141                	addi	sp,sp,16
    80003cc4:	8082                	ret

0000000080003cc6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cc6:	7139                	addi	sp,sp,-64
    80003cc8:	fc06                	sd	ra,56(sp)
    80003cca:	f822                	sd	s0,48(sp)
    80003ccc:	f426                	sd	s1,40(sp)
    80003cce:	f04a                	sd	s2,32(sp)
    80003cd0:	ec4e                	sd	s3,24(sp)
    80003cd2:	e852                	sd	s4,16(sp)
    80003cd4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cd6:	04451703          	lh	a4,68(a0)
    80003cda:	4785                	li	a5,1
    80003cdc:	00f71a63          	bne	a4,a5,80003cf0 <dirlookup+0x2a>
    80003ce0:	892a                	mv	s2,a0
    80003ce2:	89ae                	mv	s3,a1
    80003ce4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce6:	457c                	lw	a5,76(a0)
    80003ce8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cea:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cec:	e79d                	bnez	a5,80003d1a <dirlookup+0x54>
    80003cee:	a8a5                	j	80003d66 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cf0:	00005517          	auipc	a0,0x5
    80003cf4:	8e050513          	addi	a0,a0,-1824 # 800085d0 <syscalls+0x1a8>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	84e080e7          	jalr	-1970(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003d00:	00005517          	auipc	a0,0x5
    80003d04:	8e850513          	addi	a0,a0,-1816 # 800085e8 <syscalls+0x1c0>
    80003d08:	ffffd097          	auipc	ra,0xffffd
    80003d0c:	83e080e7          	jalr	-1986(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d10:	24c1                	addiw	s1,s1,16
    80003d12:	04c92783          	lw	a5,76(s2)
    80003d16:	04f4f763          	bgeu	s1,a5,80003d64 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d1a:	4741                	li	a4,16
    80003d1c:	86a6                	mv	a3,s1
    80003d1e:	fc040613          	addi	a2,s0,-64
    80003d22:	4581                	li	a1,0
    80003d24:	854a                	mv	a0,s2
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	d76080e7          	jalr	-650(ra) # 80003a9c <readi>
    80003d2e:	47c1                	li	a5,16
    80003d30:	fcf518e3          	bne	a0,a5,80003d00 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d34:	fc045783          	lhu	a5,-64(s0)
    80003d38:	dfe1                	beqz	a5,80003d10 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d3a:	fc240593          	addi	a1,s0,-62
    80003d3e:	854e                	mv	a0,s3
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	f6c080e7          	jalr	-148(ra) # 80003cac <namecmp>
    80003d48:	f561                	bnez	a0,80003d10 <dirlookup+0x4a>
      if(poff)
    80003d4a:	000a0463          	beqz	s4,80003d52 <dirlookup+0x8c>
        *poff = off;
    80003d4e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d52:	fc045583          	lhu	a1,-64(s0)
    80003d56:	00092503          	lw	a0,0(s2)
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	758080e7          	jalr	1880(ra) # 800034b2 <iget>
    80003d62:	a011                	j	80003d66 <dirlookup+0xa0>
  return 0;
    80003d64:	4501                	li	a0,0
}
    80003d66:	70e2                	ld	ra,56(sp)
    80003d68:	7442                	ld	s0,48(sp)
    80003d6a:	74a2                	ld	s1,40(sp)
    80003d6c:	7902                	ld	s2,32(sp)
    80003d6e:	69e2                	ld	s3,24(sp)
    80003d70:	6a42                	ld	s4,16(sp)
    80003d72:	6121                	addi	sp,sp,64
    80003d74:	8082                	ret

0000000080003d76 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d76:	711d                	addi	sp,sp,-96
    80003d78:	ec86                	sd	ra,88(sp)
    80003d7a:	e8a2                	sd	s0,80(sp)
    80003d7c:	e4a6                	sd	s1,72(sp)
    80003d7e:	e0ca                	sd	s2,64(sp)
    80003d80:	fc4e                	sd	s3,56(sp)
    80003d82:	f852                	sd	s4,48(sp)
    80003d84:	f456                	sd	s5,40(sp)
    80003d86:	f05a                	sd	s6,32(sp)
    80003d88:	ec5e                	sd	s7,24(sp)
    80003d8a:	e862                	sd	s8,16(sp)
    80003d8c:	e466                	sd	s9,8(sp)
    80003d8e:	e06a                	sd	s10,0(sp)
    80003d90:	1080                	addi	s0,sp,96
    80003d92:	84aa                	mv	s1,a0
    80003d94:	8b2e                	mv	s6,a1
    80003d96:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d98:	00054703          	lbu	a4,0(a0)
    80003d9c:	02f00793          	li	a5,47
    80003da0:	02f70363          	beq	a4,a5,80003dc6 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003da4:	ffffe097          	auipc	ra,0xffffe
    80003da8:	d5c080e7          	jalr	-676(ra) # 80001b00 <myproc>
    80003dac:	15053503          	ld	a0,336(a0)
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	9fa080e7          	jalr	-1542(ra) # 800037aa <idup>
    80003db8:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003dba:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003dbe:	4cb5                	li	s9,13
  len = path - s;
    80003dc0:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dc2:	4c05                	li	s8,1
    80003dc4:	a87d                	j	80003e82 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003dc6:	4585                	li	a1,1
    80003dc8:	4505                	li	a0,1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	6e8080e7          	jalr	1768(ra) # 800034b2 <iget>
    80003dd2:	8a2a                	mv	s4,a0
    80003dd4:	b7dd                	j	80003dba <namex+0x44>
      iunlockput(ip);
    80003dd6:	8552                	mv	a0,s4
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	c72080e7          	jalr	-910(ra) # 80003a4a <iunlockput>
      return 0;
    80003de0:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003de2:	8552                	mv	a0,s4
    80003de4:	60e6                	ld	ra,88(sp)
    80003de6:	6446                	ld	s0,80(sp)
    80003de8:	64a6                	ld	s1,72(sp)
    80003dea:	6906                	ld	s2,64(sp)
    80003dec:	79e2                	ld	s3,56(sp)
    80003dee:	7a42                	ld	s4,48(sp)
    80003df0:	7aa2                	ld	s5,40(sp)
    80003df2:	7b02                	ld	s6,32(sp)
    80003df4:	6be2                	ld	s7,24(sp)
    80003df6:	6c42                	ld	s8,16(sp)
    80003df8:	6ca2                	ld	s9,8(sp)
    80003dfa:	6d02                	ld	s10,0(sp)
    80003dfc:	6125                	addi	sp,sp,96
    80003dfe:	8082                	ret
      iunlock(ip);
    80003e00:	8552                	mv	a0,s4
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	aa8080e7          	jalr	-1368(ra) # 800038aa <iunlock>
      return ip;
    80003e0a:	bfe1                	j	80003de2 <namex+0x6c>
      iunlockput(ip);
    80003e0c:	8552                	mv	a0,s4
    80003e0e:	00000097          	auipc	ra,0x0
    80003e12:	c3c080e7          	jalr	-964(ra) # 80003a4a <iunlockput>
      return 0;
    80003e16:	8a4e                	mv	s4,s3
    80003e18:	b7e9                	j	80003de2 <namex+0x6c>
  len = path - s;
    80003e1a:	40998633          	sub	a2,s3,s1
    80003e1e:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e22:	09acd863          	bge	s9,s10,80003eb2 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e26:	4639                	li	a2,14
    80003e28:	85a6                	mv	a1,s1
    80003e2a:	8556                	mv	a0,s5
    80003e2c:	ffffd097          	auipc	ra,0xffffd
    80003e30:	f2c080e7          	jalr	-212(ra) # 80000d58 <memmove>
    80003e34:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	01279763          	bne	a5,s2,80003e48 <namex+0xd2>
    path++;
    80003e3e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e40:	0004c783          	lbu	a5,0(s1)
    80003e44:	ff278de3          	beq	a5,s2,80003e3e <namex+0xc8>
    ilock(ip);
    80003e48:	8552                	mv	a0,s4
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	99e080e7          	jalr	-1634(ra) # 800037e8 <ilock>
    if(ip->type != T_DIR){
    80003e52:	044a1783          	lh	a5,68(s4)
    80003e56:	f98790e3          	bne	a5,s8,80003dd6 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e5a:	000b0563          	beqz	s6,80003e64 <namex+0xee>
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	dfd9                	beqz	a5,80003e00 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e64:	865e                	mv	a2,s7
    80003e66:	85d6                	mv	a1,s5
    80003e68:	8552                	mv	a0,s4
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	e5c080e7          	jalr	-420(ra) # 80003cc6 <dirlookup>
    80003e72:	89aa                	mv	s3,a0
    80003e74:	dd41                	beqz	a0,80003e0c <namex+0x96>
    iunlockput(ip);
    80003e76:	8552                	mv	a0,s4
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	bd2080e7          	jalr	-1070(ra) # 80003a4a <iunlockput>
    ip = next;
    80003e80:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e82:	0004c783          	lbu	a5,0(s1)
    80003e86:	01279763          	bne	a5,s2,80003e94 <namex+0x11e>
    path++;
    80003e8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e8c:	0004c783          	lbu	a5,0(s1)
    80003e90:	ff278de3          	beq	a5,s2,80003e8a <namex+0x114>
  if(*path == 0)
    80003e94:	cb9d                	beqz	a5,80003eca <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e96:	0004c783          	lbu	a5,0(s1)
    80003e9a:	89a6                	mv	s3,s1
  len = path - s;
    80003e9c:	8d5e                	mv	s10,s7
    80003e9e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ea0:	01278963          	beq	a5,s2,80003eb2 <namex+0x13c>
    80003ea4:	dbbd                	beqz	a5,80003e1a <namex+0xa4>
    path++;
    80003ea6:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ea8:	0009c783          	lbu	a5,0(s3)
    80003eac:	ff279ce3          	bne	a5,s2,80003ea4 <namex+0x12e>
    80003eb0:	b7ad                	j	80003e1a <namex+0xa4>
    memmove(name, s, len);
    80003eb2:	2601                	sext.w	a2,a2
    80003eb4:	85a6                	mv	a1,s1
    80003eb6:	8556                	mv	a0,s5
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	ea0080e7          	jalr	-352(ra) # 80000d58 <memmove>
    name[len] = 0;
    80003ec0:	9d56                	add	s10,s10,s5
    80003ec2:	000d0023          	sb	zero,0(s10)
    80003ec6:	84ce                	mv	s1,s3
    80003ec8:	b7bd                	j	80003e36 <namex+0xc0>
  if(nameiparent){
    80003eca:	f00b0ce3          	beqz	s6,80003de2 <namex+0x6c>
    iput(ip);
    80003ece:	8552                	mv	a0,s4
    80003ed0:	00000097          	auipc	ra,0x0
    80003ed4:	ad2080e7          	jalr	-1326(ra) # 800039a2 <iput>
    return 0;
    80003ed8:	4a01                	li	s4,0
    80003eda:	b721                	j	80003de2 <namex+0x6c>

0000000080003edc <dirlink>:
{
    80003edc:	7139                	addi	sp,sp,-64
    80003ede:	fc06                	sd	ra,56(sp)
    80003ee0:	f822                	sd	s0,48(sp)
    80003ee2:	f426                	sd	s1,40(sp)
    80003ee4:	f04a                	sd	s2,32(sp)
    80003ee6:	ec4e                	sd	s3,24(sp)
    80003ee8:	e852                	sd	s4,16(sp)
    80003eea:	0080                	addi	s0,sp,64
    80003eec:	892a                	mv	s2,a0
    80003eee:	8a2e                	mv	s4,a1
    80003ef0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ef2:	4601                	li	a2,0
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	dd2080e7          	jalr	-558(ra) # 80003cc6 <dirlookup>
    80003efc:	e93d                	bnez	a0,80003f72 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efe:	04c92483          	lw	s1,76(s2)
    80003f02:	c49d                	beqz	s1,80003f30 <dirlink+0x54>
    80003f04:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f06:	4741                	li	a4,16
    80003f08:	86a6                	mv	a3,s1
    80003f0a:	fc040613          	addi	a2,s0,-64
    80003f0e:	4581                	li	a1,0
    80003f10:	854a                	mv	a0,s2
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	b8a080e7          	jalr	-1142(ra) # 80003a9c <readi>
    80003f1a:	47c1                	li	a5,16
    80003f1c:	06f51163          	bne	a0,a5,80003f7e <dirlink+0xa2>
    if(de.inum == 0)
    80003f20:	fc045783          	lhu	a5,-64(s0)
    80003f24:	c791                	beqz	a5,80003f30 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f26:	24c1                	addiw	s1,s1,16
    80003f28:	04c92783          	lw	a5,76(s2)
    80003f2c:	fcf4ede3          	bltu	s1,a5,80003f06 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f30:	4639                	li	a2,14
    80003f32:	85d2                	mv	a1,s4
    80003f34:	fc240513          	addi	a0,s0,-62
    80003f38:	ffffd097          	auipc	ra,0xffffd
    80003f3c:	ed8080e7          	jalr	-296(ra) # 80000e10 <strncpy>
  de.inum = inum;
    80003f40:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f44:	4741                	li	a4,16
    80003f46:	86a6                	mv	a3,s1
    80003f48:	fc040613          	addi	a2,s0,-64
    80003f4c:	4581                	li	a1,0
    80003f4e:	854a                	mv	a0,s2
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	c42080e7          	jalr	-958(ra) # 80003b92 <writei>
    80003f58:	872a                	mv	a4,a0
    80003f5a:	47c1                	li	a5,16
  return 0;
    80003f5c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f5e:	02f71863          	bne	a4,a5,80003f8e <dirlink+0xb2>
}
    80003f62:	70e2                	ld	ra,56(sp)
    80003f64:	7442                	ld	s0,48(sp)
    80003f66:	74a2                	ld	s1,40(sp)
    80003f68:	7902                	ld	s2,32(sp)
    80003f6a:	69e2                	ld	s3,24(sp)
    80003f6c:	6a42                	ld	s4,16(sp)
    80003f6e:	6121                	addi	sp,sp,64
    80003f70:	8082                	ret
    iput(ip);
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	a30080e7          	jalr	-1488(ra) # 800039a2 <iput>
    return -1;
    80003f7a:	557d                	li	a0,-1
    80003f7c:	b7dd                	j	80003f62 <dirlink+0x86>
      panic("dirlink read");
    80003f7e:	00004517          	auipc	a0,0x4
    80003f82:	67a50513          	addi	a0,a0,1658 # 800085f8 <syscalls+0x1d0>
    80003f86:	ffffc097          	auipc	ra,0xffffc
    80003f8a:	5c0080e7          	jalr	1472(ra) # 80000546 <panic>
    panic("dirlink");
    80003f8e:	00004517          	auipc	a0,0x4
    80003f92:	7ea50513          	addi	a0,a0,2026 # 80008778 <syscalls+0x350>
    80003f96:	ffffc097          	auipc	ra,0xffffc
    80003f9a:	5b0080e7          	jalr	1456(ra) # 80000546 <panic>

0000000080003f9e <namei>:

struct inode*
namei(char *path)
{
    80003f9e:	1101                	addi	sp,sp,-32
    80003fa0:	ec06                	sd	ra,24(sp)
    80003fa2:	e822                	sd	s0,16(sp)
    80003fa4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fa6:	fe040613          	addi	a2,s0,-32
    80003faa:	4581                	li	a1,0
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	dca080e7          	jalr	-566(ra) # 80003d76 <namex>
}
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	6105                	addi	sp,sp,32
    80003fba:	8082                	ret

0000000080003fbc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fbc:	1141                	addi	sp,sp,-16
    80003fbe:	e406                	sd	ra,8(sp)
    80003fc0:	e022                	sd	s0,0(sp)
    80003fc2:	0800                	addi	s0,sp,16
    80003fc4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fc6:	4585                	li	a1,1
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	dae080e7          	jalr	-594(ra) # 80003d76 <namex>
}
    80003fd0:	60a2                	ld	ra,8(sp)
    80003fd2:	6402                	ld	s0,0(sp)
    80003fd4:	0141                	addi	sp,sp,16
    80003fd6:	8082                	ret

0000000080003fd8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fd8:	1101                	addi	sp,sp,-32
    80003fda:	ec06                	sd	ra,24(sp)
    80003fdc:	e822                	sd	s0,16(sp)
    80003fde:	e426                	sd	s1,8(sp)
    80003fe0:	e04a                	sd	s2,0(sp)
    80003fe2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fe4:	0001e917          	auipc	s2,0x1e
    80003fe8:	d2490913          	addi	s2,s2,-732 # 80021d08 <log>
    80003fec:	01892583          	lw	a1,24(s2)
    80003ff0:	02892503          	lw	a0,40(s2)
    80003ff4:	fffff097          	auipc	ra,0xfffff
    80003ff8:	ff2080e7          	jalr	-14(ra) # 80002fe6 <bread>
    80003ffc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ffe:	02c92683          	lw	a3,44(s2)
    80004002:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004004:	02d05863          	blez	a3,80004034 <write_head+0x5c>
    80004008:	0001e797          	auipc	a5,0x1e
    8000400c:	d3078793          	addi	a5,a5,-720 # 80021d38 <log+0x30>
    80004010:	05c50713          	addi	a4,a0,92
    80004014:	36fd                	addiw	a3,a3,-1
    80004016:	02069613          	slli	a2,a3,0x20
    8000401a:	01e65693          	srli	a3,a2,0x1e
    8000401e:	0001e617          	auipc	a2,0x1e
    80004022:	d1e60613          	addi	a2,a2,-738 # 80021d3c <log+0x34>
    80004026:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004028:	4390                	lw	a2,0(a5)
    8000402a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000402c:	0791                	addi	a5,a5,4
    8000402e:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004030:	fed79ce3          	bne	a5,a3,80004028 <write_head+0x50>
  }
  bwrite(buf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	0a2080e7          	jalr	162(ra) # 800030d8 <bwrite>
  brelse(buf);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	0d6080e7          	jalr	214(ra) # 80003116 <brelse>
}
    80004048:	60e2                	ld	ra,24(sp)
    8000404a:	6442                	ld	s0,16(sp)
    8000404c:	64a2                	ld	s1,8(sp)
    8000404e:	6902                	ld	s2,0(sp)
    80004050:	6105                	addi	sp,sp,32
    80004052:	8082                	ret

0000000080004054 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004054:	0001e797          	auipc	a5,0x1e
    80004058:	ce07a783          	lw	a5,-800(a5) # 80021d34 <log+0x2c>
    8000405c:	0af05663          	blez	a5,80004108 <install_trans+0xb4>
{
    80004060:	7139                	addi	sp,sp,-64
    80004062:	fc06                	sd	ra,56(sp)
    80004064:	f822                	sd	s0,48(sp)
    80004066:	f426                	sd	s1,40(sp)
    80004068:	f04a                	sd	s2,32(sp)
    8000406a:	ec4e                	sd	s3,24(sp)
    8000406c:	e852                	sd	s4,16(sp)
    8000406e:	e456                	sd	s5,8(sp)
    80004070:	0080                	addi	s0,sp,64
    80004072:	0001ea97          	auipc	s5,0x1e
    80004076:	cc6a8a93          	addi	s5,s5,-826 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000407a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000407c:	0001e997          	auipc	s3,0x1e
    80004080:	c8c98993          	addi	s3,s3,-884 # 80021d08 <log>
    80004084:	0189a583          	lw	a1,24(s3)
    80004088:	014585bb          	addw	a1,a1,s4
    8000408c:	2585                	addiw	a1,a1,1
    8000408e:	0289a503          	lw	a0,40(s3)
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	f54080e7          	jalr	-172(ra) # 80002fe6 <bread>
    8000409a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000409c:	000aa583          	lw	a1,0(s5)
    800040a0:	0289a503          	lw	a0,40(s3)
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	f42080e7          	jalr	-190(ra) # 80002fe6 <bread>
    800040ac:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040ae:	40000613          	li	a2,1024
    800040b2:	05890593          	addi	a1,s2,88
    800040b6:	05850513          	addi	a0,a0,88
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	c9e080e7          	jalr	-866(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040c2:	8526                	mv	a0,s1
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	014080e7          	jalr	20(ra) # 800030d8 <bwrite>
    bunpin(dbuf);
    800040cc:	8526                	mv	a0,s1
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	122080e7          	jalr	290(ra) # 800031f0 <bunpin>
    brelse(lbuf);
    800040d6:	854a                	mv	a0,s2
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	03e080e7          	jalr	62(ra) # 80003116 <brelse>
    brelse(dbuf);
    800040e0:	8526                	mv	a0,s1
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	034080e7          	jalr	52(ra) # 80003116 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ea:	2a05                	addiw	s4,s4,1
    800040ec:	0a91                	addi	s5,s5,4
    800040ee:	02c9a783          	lw	a5,44(s3)
    800040f2:	f8fa49e3          	blt	s4,a5,80004084 <install_trans+0x30>
}
    800040f6:	70e2                	ld	ra,56(sp)
    800040f8:	7442                	ld	s0,48(sp)
    800040fa:	74a2                	ld	s1,40(sp)
    800040fc:	7902                	ld	s2,32(sp)
    800040fe:	69e2                	ld	s3,24(sp)
    80004100:	6a42                	ld	s4,16(sp)
    80004102:	6aa2                	ld	s5,8(sp)
    80004104:	6121                	addi	sp,sp,64
    80004106:	8082                	ret
    80004108:	8082                	ret

000000008000410a <initlog>:
{
    8000410a:	7179                	addi	sp,sp,-48
    8000410c:	f406                	sd	ra,40(sp)
    8000410e:	f022                	sd	s0,32(sp)
    80004110:	ec26                	sd	s1,24(sp)
    80004112:	e84a                	sd	s2,16(sp)
    80004114:	e44e                	sd	s3,8(sp)
    80004116:	1800                	addi	s0,sp,48
    80004118:	892a                	mv	s2,a0
    8000411a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000411c:	0001e497          	auipc	s1,0x1e
    80004120:	bec48493          	addi	s1,s1,-1044 # 80021d08 <log>
    80004124:	00004597          	auipc	a1,0x4
    80004128:	4e458593          	addi	a1,a1,1252 # 80008608 <syscalls+0x1e0>
    8000412c:	8526                	mv	a0,s1
    8000412e:	ffffd097          	auipc	ra,0xffffd
    80004132:	a42080e7          	jalr	-1470(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    80004136:	0149a583          	lw	a1,20(s3)
    8000413a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000413c:	0109a783          	lw	a5,16(s3)
    80004140:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004142:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004146:	854a                	mv	a0,s2
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	e9e080e7          	jalr	-354(ra) # 80002fe6 <bread>
  log.lh.n = lh->n;
    80004150:	4d34                	lw	a3,88(a0)
    80004152:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004154:	02d05663          	blez	a3,80004180 <initlog+0x76>
    80004158:	05c50793          	addi	a5,a0,92
    8000415c:	0001e717          	auipc	a4,0x1e
    80004160:	bdc70713          	addi	a4,a4,-1060 # 80021d38 <log+0x30>
    80004164:	36fd                	addiw	a3,a3,-1
    80004166:	02069613          	slli	a2,a3,0x20
    8000416a:	01e65693          	srli	a3,a2,0x1e
    8000416e:	06050613          	addi	a2,a0,96
    80004172:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004174:	4390                	lw	a2,0(a5)
    80004176:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004178:	0791                	addi	a5,a5,4
    8000417a:	0711                	addi	a4,a4,4
    8000417c:	fed79ce3          	bne	a5,a3,80004174 <initlog+0x6a>
  brelse(buf);
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	f96080e7          	jalr	-106(ra) # 80003116 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	ecc080e7          	jalr	-308(ra) # 80004054 <install_trans>
  log.lh.n = 0;
    80004190:	0001e797          	auipc	a5,0x1e
    80004194:	ba07a223          	sw	zero,-1116(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	e40080e7          	jalr	-448(ra) # 80003fd8 <write_head>
}
    800041a0:	70a2                	ld	ra,40(sp)
    800041a2:	7402                	ld	s0,32(sp)
    800041a4:	64e2                	ld	s1,24(sp)
    800041a6:	6942                	ld	s2,16(sp)
    800041a8:	69a2                	ld	s3,8(sp)
    800041aa:	6145                	addi	sp,sp,48
    800041ac:	8082                	ret

00000000800041ae <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041ae:	1101                	addi	sp,sp,-32
    800041b0:	ec06                	sd	ra,24(sp)
    800041b2:	e822                	sd	s0,16(sp)
    800041b4:	e426                	sd	s1,8(sp)
    800041b6:	e04a                	sd	s2,0(sp)
    800041b8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ba:	0001e517          	auipc	a0,0x1e
    800041be:	b4e50513          	addi	a0,a0,-1202 # 80021d08 <log>
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	a3e080e7          	jalr	-1474(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    800041ca:	0001e497          	auipc	s1,0x1e
    800041ce:	b3e48493          	addi	s1,s1,-1218 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d2:	4979                	li	s2,30
    800041d4:	a039                	j	800041e2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041d6:	85a6                	mv	a1,s1
    800041d8:	8526                	mv	a0,s1
    800041da:	ffffe097          	auipc	ra,0xffffe
    800041de:	1dc080e7          	jalr	476(ra) # 800023b6 <sleep>
    if(log.committing){
    800041e2:	50dc                	lw	a5,36(s1)
    800041e4:	fbed                	bnez	a5,800041d6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041e6:	5098                	lw	a4,32(s1)
    800041e8:	2705                	addiw	a4,a4,1
    800041ea:	0007069b          	sext.w	a3,a4
    800041ee:	0027179b          	slliw	a5,a4,0x2
    800041f2:	9fb9                	addw	a5,a5,a4
    800041f4:	0017979b          	slliw	a5,a5,0x1
    800041f8:	54d8                	lw	a4,44(s1)
    800041fa:	9fb9                	addw	a5,a5,a4
    800041fc:	00f95963          	bge	s2,a5,8000420e <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004200:	85a6                	mv	a1,s1
    80004202:	8526                	mv	a0,s1
    80004204:	ffffe097          	auipc	ra,0xffffe
    80004208:	1b2080e7          	jalr	434(ra) # 800023b6 <sleep>
    8000420c:	bfd9                	j	800041e2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000420e:	0001e517          	auipc	a0,0x1e
    80004212:	afa50513          	addi	a0,a0,-1286 # 80021d08 <log>
    80004216:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	a9c080e7          	jalr	-1380(ra) # 80000cb4 <release>
      break;
    }
  }
}
    80004220:	60e2                	ld	ra,24(sp)
    80004222:	6442                	ld	s0,16(sp)
    80004224:	64a2                	ld	s1,8(sp)
    80004226:	6902                	ld	s2,0(sp)
    80004228:	6105                	addi	sp,sp,32
    8000422a:	8082                	ret

000000008000422c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000422c:	7139                	addi	sp,sp,-64
    8000422e:	fc06                	sd	ra,56(sp)
    80004230:	f822                	sd	s0,48(sp)
    80004232:	f426                	sd	s1,40(sp)
    80004234:	f04a                	sd	s2,32(sp)
    80004236:	ec4e                	sd	s3,24(sp)
    80004238:	e852                	sd	s4,16(sp)
    8000423a:	e456                	sd	s5,8(sp)
    8000423c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000423e:	0001e497          	auipc	s1,0x1e
    80004242:	aca48493          	addi	s1,s1,-1334 # 80021d08 <log>
    80004246:	8526                	mv	a0,s1
    80004248:	ffffd097          	auipc	ra,0xffffd
    8000424c:	9b8080e7          	jalr	-1608(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    80004250:	509c                	lw	a5,32(s1)
    80004252:	37fd                	addiw	a5,a5,-1
    80004254:	0007891b          	sext.w	s2,a5
    80004258:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000425a:	50dc                	lw	a5,36(s1)
    8000425c:	e7b9                	bnez	a5,800042aa <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000425e:	04091e63          	bnez	s2,800042ba <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004262:	0001e497          	auipc	s1,0x1e
    80004266:	aa648493          	addi	s1,s1,-1370 # 80021d08 <log>
    8000426a:	4785                	li	a5,1
    8000426c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a44080e7          	jalr	-1468(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004278:	54dc                	lw	a5,44(s1)
    8000427a:	06f04763          	bgtz	a5,800042e8 <end_op+0xbc>
    acquire(&log.lock);
    8000427e:	0001e497          	auipc	s1,0x1e
    80004282:	a8a48493          	addi	s1,s1,-1398 # 80021d08 <log>
    80004286:	8526                	mv	a0,s1
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	978080e7          	jalr	-1672(ra) # 80000c00 <acquire>
    log.committing = 0;
    80004290:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004294:	8526                	mv	a0,s1
    80004296:	ffffe097          	auipc	ra,0xffffe
    8000429a:	2a0080e7          	jalr	672(ra) # 80002536 <wakeup>
    release(&log.lock);
    8000429e:	8526                	mv	a0,s1
    800042a0:	ffffd097          	auipc	ra,0xffffd
    800042a4:	a14080e7          	jalr	-1516(ra) # 80000cb4 <release>
}
    800042a8:	a03d                	j	800042d6 <end_op+0xaa>
    panic("log.committing");
    800042aa:	00004517          	auipc	a0,0x4
    800042ae:	36650513          	addi	a0,a0,870 # 80008610 <syscalls+0x1e8>
    800042b2:	ffffc097          	auipc	ra,0xffffc
    800042b6:	294080e7          	jalr	660(ra) # 80000546 <panic>
    wakeup(&log);
    800042ba:	0001e497          	auipc	s1,0x1e
    800042be:	a4e48493          	addi	s1,s1,-1458 # 80021d08 <log>
    800042c2:	8526                	mv	a0,s1
    800042c4:	ffffe097          	auipc	ra,0xffffe
    800042c8:	272080e7          	jalr	626(ra) # 80002536 <wakeup>
  release(&log.lock);
    800042cc:	8526                	mv	a0,s1
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	9e6080e7          	jalr	-1562(ra) # 80000cb4 <release>
}
    800042d6:	70e2                	ld	ra,56(sp)
    800042d8:	7442                	ld	s0,48(sp)
    800042da:	74a2                	ld	s1,40(sp)
    800042dc:	7902                	ld	s2,32(sp)
    800042de:	69e2                	ld	s3,24(sp)
    800042e0:	6a42                	ld	s4,16(sp)
    800042e2:	6aa2                	ld	s5,8(sp)
    800042e4:	6121                	addi	sp,sp,64
    800042e6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e8:	0001ea97          	auipc	s5,0x1e
    800042ec:	a50a8a93          	addi	s5,s5,-1456 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042f0:	0001ea17          	auipc	s4,0x1e
    800042f4:	a18a0a13          	addi	s4,s4,-1512 # 80021d08 <log>
    800042f8:	018a2583          	lw	a1,24(s4)
    800042fc:	012585bb          	addw	a1,a1,s2
    80004300:	2585                	addiw	a1,a1,1
    80004302:	028a2503          	lw	a0,40(s4)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	ce0080e7          	jalr	-800(ra) # 80002fe6 <bread>
    8000430e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004310:	000aa583          	lw	a1,0(s5)
    80004314:	028a2503          	lw	a0,40(s4)
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	cce080e7          	jalr	-818(ra) # 80002fe6 <bread>
    80004320:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004322:	40000613          	li	a2,1024
    80004326:	05850593          	addi	a1,a0,88
    8000432a:	05848513          	addi	a0,s1,88
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	a2a080e7          	jalr	-1494(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    80004336:	8526                	mv	a0,s1
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	da0080e7          	jalr	-608(ra) # 800030d8 <bwrite>
    brelse(from);
    80004340:	854e                	mv	a0,s3
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	dd4080e7          	jalr	-556(ra) # 80003116 <brelse>
    brelse(to);
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	dca080e7          	jalr	-566(ra) # 80003116 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004354:	2905                	addiw	s2,s2,1
    80004356:	0a91                	addi	s5,s5,4
    80004358:	02ca2783          	lw	a5,44(s4)
    8000435c:	f8f94ee3          	blt	s2,a5,800042f8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004360:	00000097          	auipc	ra,0x0
    80004364:	c78080e7          	jalr	-904(ra) # 80003fd8 <write_head>
    install_trans(); // Now install writes to home locations
    80004368:	00000097          	auipc	ra,0x0
    8000436c:	cec080e7          	jalr	-788(ra) # 80004054 <install_trans>
    log.lh.n = 0;
    80004370:	0001e797          	auipc	a5,0x1e
    80004374:	9c07a223          	sw	zero,-1596(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	c60080e7          	jalr	-928(ra) # 80003fd8 <write_head>
    80004380:	bdfd                	j	8000427e <end_op+0x52>

0000000080004382 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	e426                	sd	s1,8(sp)
    8000438a:	e04a                	sd	s2,0(sp)
    8000438c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000438e:	0001e717          	auipc	a4,0x1e
    80004392:	9a672703          	lw	a4,-1626(a4) # 80021d34 <log+0x2c>
    80004396:	47f5                	li	a5,29
    80004398:	08e7c063          	blt	a5,a4,80004418 <log_write+0x96>
    8000439c:	84aa                	mv	s1,a0
    8000439e:	0001e797          	auipc	a5,0x1e
    800043a2:	9867a783          	lw	a5,-1658(a5) # 80021d24 <log+0x1c>
    800043a6:	37fd                	addiw	a5,a5,-1
    800043a8:	06f75863          	bge	a4,a5,80004418 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043ac:	0001e797          	auipc	a5,0x1e
    800043b0:	97c7a783          	lw	a5,-1668(a5) # 80021d28 <log+0x20>
    800043b4:	06f05a63          	blez	a5,80004428 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043b8:	0001e917          	auipc	s2,0x1e
    800043bc:	95090913          	addi	s2,s2,-1712 # 80021d08 <log>
    800043c0:	854a                	mv	a0,s2
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	83e080e7          	jalr	-1986(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043ca:	02c92603          	lw	a2,44(s2)
    800043ce:	06c05563          	blez	a2,80004438 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043d2:	44cc                	lw	a1,12(s1)
    800043d4:	0001e717          	auipc	a4,0x1e
    800043d8:	96470713          	addi	a4,a4,-1692 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043dc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043de:	4314                	lw	a3,0(a4)
    800043e0:	04b68d63          	beq	a3,a1,8000443a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043e4:	2785                	addiw	a5,a5,1
    800043e6:	0711                	addi	a4,a4,4
    800043e8:	fec79be3          	bne	a5,a2,800043de <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043ec:	0621                	addi	a2,a2,8
    800043ee:	060a                	slli	a2,a2,0x2
    800043f0:	0001e797          	auipc	a5,0x1e
    800043f4:	91878793          	addi	a5,a5,-1768 # 80021d08 <log>
    800043f8:	97b2                	add	a5,a5,a2
    800043fa:	44d8                	lw	a4,12(s1)
    800043fc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043fe:	8526                	mv	a0,s1
    80004400:	fffff097          	auipc	ra,0xfffff
    80004404:	db4080e7          	jalr	-588(ra) # 800031b4 <bpin>
    log.lh.n++;
    80004408:	0001e717          	auipc	a4,0x1e
    8000440c:	90070713          	addi	a4,a4,-1792 # 80021d08 <log>
    80004410:	575c                	lw	a5,44(a4)
    80004412:	2785                	addiw	a5,a5,1
    80004414:	d75c                	sw	a5,44(a4)
    80004416:	a835                	j	80004452 <log_write+0xd0>
    panic("too big a transaction");
    80004418:	00004517          	auipc	a0,0x4
    8000441c:	20850513          	addi	a0,a0,520 # 80008620 <syscalls+0x1f8>
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	126080e7          	jalr	294(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    80004428:	00004517          	auipc	a0,0x4
    8000442c:	21050513          	addi	a0,a0,528 # 80008638 <syscalls+0x210>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	116080e7          	jalr	278(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004438:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000443a:	00878693          	addi	a3,a5,8
    8000443e:	068a                	slli	a3,a3,0x2
    80004440:	0001e717          	auipc	a4,0x1e
    80004444:	8c870713          	addi	a4,a4,-1848 # 80021d08 <log>
    80004448:	9736                	add	a4,a4,a3
    8000444a:	44d4                	lw	a3,12(s1)
    8000444c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000444e:	faf608e3          	beq	a2,a5,800043fe <log_write+0x7c>
  }
  release(&log.lock);
    80004452:	0001e517          	auipc	a0,0x1e
    80004456:	8b650513          	addi	a0,a0,-1866 # 80021d08 <log>
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	85a080e7          	jalr	-1958(ra) # 80000cb4 <release>
}
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6902                	ld	s2,0(sp)
    8000446a:	6105                	addi	sp,sp,32
    8000446c:	8082                	ret

000000008000446e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000446e:	1101                	addi	sp,sp,-32
    80004470:	ec06                	sd	ra,24(sp)
    80004472:	e822                	sd	s0,16(sp)
    80004474:	e426                	sd	s1,8(sp)
    80004476:	e04a                	sd	s2,0(sp)
    80004478:	1000                	addi	s0,sp,32
    8000447a:	84aa                	mv	s1,a0
    8000447c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000447e:	00004597          	auipc	a1,0x4
    80004482:	1da58593          	addi	a1,a1,474 # 80008658 <syscalls+0x230>
    80004486:	0521                	addi	a0,a0,8
    80004488:	ffffc097          	auipc	ra,0xffffc
    8000448c:	6e8080e7          	jalr	1768(ra) # 80000b70 <initlock>
  lk->name = name;
    80004490:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004494:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004498:	0204a423          	sw	zero,40(s1)
}
    8000449c:	60e2                	ld	ra,24(sp)
    8000449e:	6442                	ld	s0,16(sp)
    800044a0:	64a2                	ld	s1,8(sp)
    800044a2:	6902                	ld	s2,0(sp)
    800044a4:	6105                	addi	sp,sp,32
    800044a6:	8082                	ret

00000000800044a8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044a8:	1101                	addi	sp,sp,-32
    800044aa:	ec06                	sd	ra,24(sp)
    800044ac:	e822                	sd	s0,16(sp)
    800044ae:	e426                	sd	s1,8(sp)
    800044b0:	e04a                	sd	s2,0(sp)
    800044b2:	1000                	addi	s0,sp,32
    800044b4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b6:	00850913          	addi	s2,a0,8
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffc097          	auipc	ra,0xffffc
    800044c0:	744080e7          	jalr	1860(ra) # 80000c00 <acquire>
  while (lk->locked) {
    800044c4:	409c                	lw	a5,0(s1)
    800044c6:	cb89                	beqz	a5,800044d8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044c8:	85ca                	mv	a1,s2
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffe097          	auipc	ra,0xffffe
    800044d0:	eea080e7          	jalr	-278(ra) # 800023b6 <sleep>
  while (lk->locked) {
    800044d4:	409c                	lw	a5,0(s1)
    800044d6:	fbed                	bnez	a5,800044c8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044d8:	4785                	li	a5,1
    800044da:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044dc:	ffffd097          	auipc	ra,0xffffd
    800044e0:	624080e7          	jalr	1572(ra) # 80001b00 <myproc>
    800044e4:	5d1c                	lw	a5,56(a0)
    800044e6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	7ca080e7          	jalr	1994(ra) # 80000cb4 <release>
}
    800044f2:	60e2                	ld	ra,24(sp)
    800044f4:	6442                	ld	s0,16(sp)
    800044f6:	64a2                	ld	s1,8(sp)
    800044f8:	6902                	ld	s2,0(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044fe:	1101                	addi	sp,sp,-32
    80004500:	ec06                	sd	ra,24(sp)
    80004502:	e822                	sd	s0,16(sp)
    80004504:	e426                	sd	s1,8(sp)
    80004506:	e04a                	sd	s2,0(sp)
    80004508:	1000                	addi	s0,sp,32
    8000450a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000450c:	00850913          	addi	s2,a0,8
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	6ee080e7          	jalr	1774(ra) # 80000c00 <acquire>
  lk->locked = 0;
    8000451a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000451e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004522:	8526                	mv	a0,s1
    80004524:	ffffe097          	auipc	ra,0xffffe
    80004528:	012080e7          	jalr	18(ra) # 80002536 <wakeup>
  release(&lk->lk);
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	786080e7          	jalr	1926(ra) # 80000cb4 <release>
}
    80004536:	60e2                	ld	ra,24(sp)
    80004538:	6442                	ld	s0,16(sp)
    8000453a:	64a2                	ld	s1,8(sp)
    8000453c:	6902                	ld	s2,0(sp)
    8000453e:	6105                	addi	sp,sp,32
    80004540:	8082                	ret

0000000080004542 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004542:	7179                	addi	sp,sp,-48
    80004544:	f406                	sd	ra,40(sp)
    80004546:	f022                	sd	s0,32(sp)
    80004548:	ec26                	sd	s1,24(sp)
    8000454a:	e84a                	sd	s2,16(sp)
    8000454c:	e44e                	sd	s3,8(sp)
    8000454e:	1800                	addi	s0,sp,48
    80004550:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004552:	00850913          	addi	s2,a0,8
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	6a8080e7          	jalr	1704(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004560:	409c                	lw	a5,0(s1)
    80004562:	ef99                	bnez	a5,80004580 <holdingsleep+0x3e>
    80004564:	4481                	li	s1,0
  release(&lk->lk);
    80004566:	854a                	mv	a0,s2
    80004568:	ffffc097          	auipc	ra,0xffffc
    8000456c:	74c080e7          	jalr	1868(ra) # 80000cb4 <release>
  return r;
}
    80004570:	8526                	mv	a0,s1
    80004572:	70a2                	ld	ra,40(sp)
    80004574:	7402                	ld	s0,32(sp)
    80004576:	64e2                	ld	s1,24(sp)
    80004578:	6942                	ld	s2,16(sp)
    8000457a:	69a2                	ld	s3,8(sp)
    8000457c:	6145                	addi	sp,sp,48
    8000457e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004580:	0284a983          	lw	s3,40(s1)
    80004584:	ffffd097          	auipc	ra,0xffffd
    80004588:	57c080e7          	jalr	1404(ra) # 80001b00 <myproc>
    8000458c:	5d04                	lw	s1,56(a0)
    8000458e:	413484b3          	sub	s1,s1,s3
    80004592:	0014b493          	seqz	s1,s1
    80004596:	bfc1                	j	80004566 <holdingsleep+0x24>

0000000080004598 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004598:	1141                	addi	sp,sp,-16
    8000459a:	e406                	sd	ra,8(sp)
    8000459c:	e022                	sd	s0,0(sp)
    8000459e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045a0:	00004597          	auipc	a1,0x4
    800045a4:	0c858593          	addi	a1,a1,200 # 80008668 <syscalls+0x240>
    800045a8:	0001e517          	auipc	a0,0x1e
    800045ac:	8a850513          	addi	a0,a0,-1880 # 80021e50 <ftable>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	5c0080e7          	jalr	1472(ra) # 80000b70 <initlock>
}
    800045b8:	60a2                	ld	ra,8(sp)
    800045ba:	6402                	ld	s0,0(sp)
    800045bc:	0141                	addi	sp,sp,16
    800045be:	8082                	ret

00000000800045c0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045c0:	1101                	addi	sp,sp,-32
    800045c2:	ec06                	sd	ra,24(sp)
    800045c4:	e822                	sd	s0,16(sp)
    800045c6:	e426                	sd	s1,8(sp)
    800045c8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045ca:	0001e517          	auipc	a0,0x1e
    800045ce:	88650513          	addi	a0,a0,-1914 # 80021e50 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	62e080e7          	jalr	1582(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045da:	0001e497          	auipc	s1,0x1e
    800045de:	88e48493          	addi	s1,s1,-1906 # 80021e68 <ftable+0x18>
    800045e2:	0001f717          	auipc	a4,0x1f
    800045e6:	82670713          	addi	a4,a4,-2010 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    800045ea:	40dc                	lw	a5,4(s1)
    800045ec:	cf99                	beqz	a5,8000460a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ee:	02848493          	addi	s1,s1,40
    800045f2:	fee49ce3          	bne	s1,a4,800045ea <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045f6:	0001e517          	auipc	a0,0x1e
    800045fa:	85a50513          	addi	a0,a0,-1958 # 80021e50 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	6b6080e7          	jalr	1718(ra) # 80000cb4 <release>
  return 0;
    80004606:	4481                	li	s1,0
    80004608:	a819                	j	8000461e <filealloc+0x5e>
      f->ref = 1;
    8000460a:	4785                	li	a5,1
    8000460c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000460e:	0001e517          	auipc	a0,0x1e
    80004612:	84250513          	addi	a0,a0,-1982 # 80021e50 <ftable>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	69e080e7          	jalr	1694(ra) # 80000cb4 <release>
}
    8000461e:	8526                	mv	a0,s1
    80004620:	60e2                	ld	ra,24(sp)
    80004622:	6442                	ld	s0,16(sp)
    80004624:	64a2                	ld	s1,8(sp)
    80004626:	6105                	addi	sp,sp,32
    80004628:	8082                	ret

000000008000462a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000462a:	1101                	addi	sp,sp,-32
    8000462c:	ec06                	sd	ra,24(sp)
    8000462e:	e822                	sd	s0,16(sp)
    80004630:	e426                	sd	s1,8(sp)
    80004632:	1000                	addi	s0,sp,32
    80004634:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004636:	0001e517          	auipc	a0,0x1e
    8000463a:	81a50513          	addi	a0,a0,-2022 # 80021e50 <ftable>
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	5c2080e7          	jalr	1474(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    80004646:	40dc                	lw	a5,4(s1)
    80004648:	02f05263          	blez	a5,8000466c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000464c:	2785                	addiw	a5,a5,1
    8000464e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004650:	0001e517          	auipc	a0,0x1e
    80004654:	80050513          	addi	a0,a0,-2048 # 80021e50 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	65c080e7          	jalr	1628(ra) # 80000cb4 <release>
  return f;
}
    80004660:	8526                	mv	a0,s1
    80004662:	60e2                	ld	ra,24(sp)
    80004664:	6442                	ld	s0,16(sp)
    80004666:	64a2                	ld	s1,8(sp)
    80004668:	6105                	addi	sp,sp,32
    8000466a:	8082                	ret
    panic("filedup");
    8000466c:	00004517          	auipc	a0,0x4
    80004670:	00450513          	addi	a0,a0,4 # 80008670 <syscalls+0x248>
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	ed2080e7          	jalr	-302(ra) # 80000546 <panic>

000000008000467c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000467c:	7139                	addi	sp,sp,-64
    8000467e:	fc06                	sd	ra,56(sp)
    80004680:	f822                	sd	s0,48(sp)
    80004682:	f426                	sd	s1,40(sp)
    80004684:	f04a                	sd	s2,32(sp)
    80004686:	ec4e                	sd	s3,24(sp)
    80004688:	e852                	sd	s4,16(sp)
    8000468a:	e456                	sd	s5,8(sp)
    8000468c:	0080                	addi	s0,sp,64
    8000468e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004690:	0001d517          	auipc	a0,0x1d
    80004694:	7c050513          	addi	a0,a0,1984 # 80021e50 <ftable>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	568080e7          	jalr	1384(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    800046a0:	40dc                	lw	a5,4(s1)
    800046a2:	06f05163          	blez	a5,80004704 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046a6:	37fd                	addiw	a5,a5,-1
    800046a8:	0007871b          	sext.w	a4,a5
    800046ac:	c0dc                	sw	a5,4(s1)
    800046ae:	06e04363          	bgtz	a4,80004714 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046b2:	0004a903          	lw	s2,0(s1)
    800046b6:	0094ca83          	lbu	s5,9(s1)
    800046ba:	0104ba03          	ld	s4,16(s1)
    800046be:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046c2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046c6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046ca:	0001d517          	auipc	a0,0x1d
    800046ce:	78650513          	addi	a0,a0,1926 # 80021e50 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	5e2080e7          	jalr	1506(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    800046da:	4785                	li	a5,1
    800046dc:	04f90d63          	beq	s2,a5,80004736 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046e0:	3979                	addiw	s2,s2,-2
    800046e2:	4785                	li	a5,1
    800046e4:	0527e063          	bltu	a5,s2,80004724 <fileclose+0xa8>
    begin_op();
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	ac6080e7          	jalr	-1338(ra) # 800041ae <begin_op>
    iput(ff.ip);
    800046f0:	854e                	mv	a0,s3
    800046f2:	fffff097          	auipc	ra,0xfffff
    800046f6:	2b0080e7          	jalr	688(ra) # 800039a2 <iput>
    end_op();
    800046fa:	00000097          	auipc	ra,0x0
    800046fe:	b32080e7          	jalr	-1230(ra) # 8000422c <end_op>
    80004702:	a00d                	j	80004724 <fileclose+0xa8>
    panic("fileclose");
    80004704:	00004517          	auipc	a0,0x4
    80004708:	f7450513          	addi	a0,a0,-140 # 80008678 <syscalls+0x250>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	e3a080e7          	jalr	-454(ra) # 80000546 <panic>
    release(&ftable.lock);
    80004714:	0001d517          	auipc	a0,0x1d
    80004718:	73c50513          	addi	a0,a0,1852 # 80021e50 <ftable>
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	598080e7          	jalr	1432(ra) # 80000cb4 <release>
  }
}
    80004724:	70e2                	ld	ra,56(sp)
    80004726:	7442                	ld	s0,48(sp)
    80004728:	74a2                	ld	s1,40(sp)
    8000472a:	7902                	ld	s2,32(sp)
    8000472c:	69e2                	ld	s3,24(sp)
    8000472e:	6a42                	ld	s4,16(sp)
    80004730:	6aa2                	ld	s5,8(sp)
    80004732:	6121                	addi	sp,sp,64
    80004734:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004736:	85d6                	mv	a1,s5
    80004738:	8552                	mv	a0,s4
    8000473a:	00000097          	auipc	ra,0x0
    8000473e:	372080e7          	jalr	882(ra) # 80004aac <pipeclose>
    80004742:	b7cd                	j	80004724 <fileclose+0xa8>

0000000080004744 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004744:	715d                	addi	sp,sp,-80
    80004746:	e486                	sd	ra,72(sp)
    80004748:	e0a2                	sd	s0,64(sp)
    8000474a:	fc26                	sd	s1,56(sp)
    8000474c:	f84a                	sd	s2,48(sp)
    8000474e:	f44e                	sd	s3,40(sp)
    80004750:	0880                	addi	s0,sp,80
    80004752:	84aa                	mv	s1,a0
    80004754:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004756:	ffffd097          	auipc	ra,0xffffd
    8000475a:	3aa080e7          	jalr	938(ra) # 80001b00 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000475e:	409c                	lw	a5,0(s1)
    80004760:	37f9                	addiw	a5,a5,-2
    80004762:	4705                	li	a4,1
    80004764:	04f76763          	bltu	a4,a5,800047b2 <filestat+0x6e>
    80004768:	892a                	mv	s2,a0
    ilock(f->ip);
    8000476a:	6c88                	ld	a0,24(s1)
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	07c080e7          	jalr	124(ra) # 800037e8 <ilock>
    stati(f->ip, &st);
    80004774:	fb840593          	addi	a1,s0,-72
    80004778:	6c88                	ld	a0,24(s1)
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	2f8080e7          	jalr	760(ra) # 80003a72 <stati>
    iunlock(f->ip);
    80004782:	6c88                	ld	a0,24(s1)
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	126080e7          	jalr	294(ra) # 800038aa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000478c:	46e1                	li	a3,24
    8000478e:	fb840613          	addi	a2,s0,-72
    80004792:	85ce                	mv	a1,s3
    80004794:	05093503          	ld	a0,80(s2)
    80004798:	ffffd097          	auipc	ra,0xffffd
    8000479c:	02e080e7          	jalr	46(ra) # 800017c6 <copyout>
    800047a0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047a4:	60a6                	ld	ra,72(sp)
    800047a6:	6406                	ld	s0,64(sp)
    800047a8:	74e2                	ld	s1,56(sp)
    800047aa:	7942                	ld	s2,48(sp)
    800047ac:	79a2                	ld	s3,40(sp)
    800047ae:	6161                	addi	sp,sp,80
    800047b0:	8082                	ret
  return -1;
    800047b2:	557d                	li	a0,-1
    800047b4:	bfc5                	j	800047a4 <filestat+0x60>

00000000800047b6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047b6:	7179                	addi	sp,sp,-48
    800047b8:	f406                	sd	ra,40(sp)
    800047ba:	f022                	sd	s0,32(sp)
    800047bc:	ec26                	sd	s1,24(sp)
    800047be:	e84a                	sd	s2,16(sp)
    800047c0:	e44e                	sd	s3,8(sp)
    800047c2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047c4:	00854783          	lbu	a5,8(a0)
    800047c8:	c3d5                	beqz	a5,8000486c <fileread+0xb6>
    800047ca:	84aa                	mv	s1,a0
    800047cc:	89ae                	mv	s3,a1
    800047ce:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047d0:	411c                	lw	a5,0(a0)
    800047d2:	4705                	li	a4,1
    800047d4:	04e78963          	beq	a5,a4,80004826 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047d8:	470d                	li	a4,3
    800047da:	04e78d63          	beq	a5,a4,80004834 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047de:	4709                	li	a4,2
    800047e0:	06e79e63          	bne	a5,a4,8000485c <fileread+0xa6>
    ilock(f->ip);
    800047e4:	6d08                	ld	a0,24(a0)
    800047e6:	fffff097          	auipc	ra,0xfffff
    800047ea:	002080e7          	jalr	2(ra) # 800037e8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047ee:	874a                	mv	a4,s2
    800047f0:	5094                	lw	a3,32(s1)
    800047f2:	864e                	mv	a2,s3
    800047f4:	4585                	li	a1,1
    800047f6:	6c88                	ld	a0,24(s1)
    800047f8:	fffff097          	auipc	ra,0xfffff
    800047fc:	2a4080e7          	jalr	676(ra) # 80003a9c <readi>
    80004800:	892a                	mv	s2,a0
    80004802:	00a05563          	blez	a0,8000480c <fileread+0x56>
      f->off += r;
    80004806:	509c                	lw	a5,32(s1)
    80004808:	9fa9                	addw	a5,a5,a0
    8000480a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000480c:	6c88                	ld	a0,24(s1)
    8000480e:	fffff097          	auipc	ra,0xfffff
    80004812:	09c080e7          	jalr	156(ra) # 800038aa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004816:	854a                	mv	a0,s2
    80004818:	70a2                	ld	ra,40(sp)
    8000481a:	7402                	ld	s0,32(sp)
    8000481c:	64e2                	ld	s1,24(sp)
    8000481e:	6942                	ld	s2,16(sp)
    80004820:	69a2                	ld	s3,8(sp)
    80004822:	6145                	addi	sp,sp,48
    80004824:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004826:	6908                	ld	a0,16(a0)
    80004828:	00000097          	auipc	ra,0x0
    8000482c:	3f6080e7          	jalr	1014(ra) # 80004c1e <piperead>
    80004830:	892a                	mv	s2,a0
    80004832:	b7d5                	j	80004816 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004834:	02451783          	lh	a5,36(a0)
    80004838:	03079693          	slli	a3,a5,0x30
    8000483c:	92c1                	srli	a3,a3,0x30
    8000483e:	4725                	li	a4,9
    80004840:	02d76863          	bltu	a4,a3,80004870 <fileread+0xba>
    80004844:	0792                	slli	a5,a5,0x4
    80004846:	0001d717          	auipc	a4,0x1d
    8000484a:	56a70713          	addi	a4,a4,1386 # 80021db0 <devsw>
    8000484e:	97ba                	add	a5,a5,a4
    80004850:	639c                	ld	a5,0(a5)
    80004852:	c38d                	beqz	a5,80004874 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004854:	4505                	li	a0,1
    80004856:	9782                	jalr	a5
    80004858:	892a                	mv	s2,a0
    8000485a:	bf75                	j	80004816 <fileread+0x60>
    panic("fileread");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	e2c50513          	addi	a0,a0,-468 # 80008688 <syscalls+0x260>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	ce2080e7          	jalr	-798(ra) # 80000546 <panic>
    return -1;
    8000486c:	597d                	li	s2,-1
    8000486e:	b765                	j	80004816 <fileread+0x60>
      return -1;
    80004870:	597d                	li	s2,-1
    80004872:	b755                	j	80004816 <fileread+0x60>
    80004874:	597d                	li	s2,-1
    80004876:	b745                	j	80004816 <fileread+0x60>

0000000080004878 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004878:	00954783          	lbu	a5,9(a0)
    8000487c:	14078563          	beqz	a5,800049c6 <filewrite+0x14e>
{
    80004880:	715d                	addi	sp,sp,-80
    80004882:	e486                	sd	ra,72(sp)
    80004884:	e0a2                	sd	s0,64(sp)
    80004886:	fc26                	sd	s1,56(sp)
    80004888:	f84a                	sd	s2,48(sp)
    8000488a:	f44e                	sd	s3,40(sp)
    8000488c:	f052                	sd	s4,32(sp)
    8000488e:	ec56                	sd	s5,24(sp)
    80004890:	e85a                	sd	s6,16(sp)
    80004892:	e45e                	sd	s7,8(sp)
    80004894:	e062                	sd	s8,0(sp)
    80004896:	0880                	addi	s0,sp,80
    80004898:	892a                	mv	s2,a0
    8000489a:	8b2e                	mv	s6,a1
    8000489c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000489e:	411c                	lw	a5,0(a0)
    800048a0:	4705                	li	a4,1
    800048a2:	02e78263          	beq	a5,a4,800048c6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048a6:	470d                	li	a4,3
    800048a8:	02e78563          	beq	a5,a4,800048d2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048ac:	4709                	li	a4,2
    800048ae:	10e79463          	bne	a5,a4,800049b6 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048b2:	0ec05e63          	blez	a2,800049ae <filewrite+0x136>
    int i = 0;
    800048b6:	4981                	li	s3,0
    800048b8:	6b85                	lui	s7,0x1
    800048ba:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048be:	6c05                	lui	s8,0x1
    800048c0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048c4:	a851                	j	80004958 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048c6:	6908                	ld	a0,16(a0)
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	254080e7          	jalr	596(ra) # 80004b1c <pipewrite>
    800048d0:	a85d                	j	80004986 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048d2:	02451783          	lh	a5,36(a0)
    800048d6:	03079693          	slli	a3,a5,0x30
    800048da:	92c1                	srli	a3,a3,0x30
    800048dc:	4725                	li	a4,9
    800048de:	0ed76663          	bltu	a4,a3,800049ca <filewrite+0x152>
    800048e2:	0792                	slli	a5,a5,0x4
    800048e4:	0001d717          	auipc	a4,0x1d
    800048e8:	4cc70713          	addi	a4,a4,1228 # 80021db0 <devsw>
    800048ec:	97ba                	add	a5,a5,a4
    800048ee:	679c                	ld	a5,8(a5)
    800048f0:	cff9                	beqz	a5,800049ce <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048f2:	4505                	li	a0,1
    800048f4:	9782                	jalr	a5
    800048f6:	a841                	j	80004986 <filewrite+0x10e>
    800048f8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	8b2080e7          	jalr	-1870(ra) # 800041ae <begin_op>
      ilock(f->ip);
    80004904:	01893503          	ld	a0,24(s2)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	ee0080e7          	jalr	-288(ra) # 800037e8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004910:	8756                	mv	a4,s5
    80004912:	02092683          	lw	a3,32(s2)
    80004916:	01698633          	add	a2,s3,s6
    8000491a:	4585                	li	a1,1
    8000491c:	01893503          	ld	a0,24(s2)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	272080e7          	jalr	626(ra) # 80003b92 <writei>
    80004928:	84aa                	mv	s1,a0
    8000492a:	02a05f63          	blez	a0,80004968 <filewrite+0xf0>
        f->off += r;
    8000492e:	02092783          	lw	a5,32(s2)
    80004932:	9fa9                	addw	a5,a5,a0
    80004934:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004938:	01893503          	ld	a0,24(s2)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	f6e080e7          	jalr	-146(ra) # 800038aa <iunlock>
      end_op();
    80004944:	00000097          	auipc	ra,0x0
    80004948:	8e8080e7          	jalr	-1816(ra) # 8000422c <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000494c:	049a9963          	bne	s5,s1,8000499e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004950:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004954:	0349d663          	bge	s3,s4,80004980 <filewrite+0x108>
      int n1 = n - i;
    80004958:	413a04bb          	subw	s1,s4,s3
    8000495c:	0004879b          	sext.w	a5,s1
    80004960:	f8fbdce3          	bge	s7,a5,800048f8 <filewrite+0x80>
    80004964:	84e2                	mv	s1,s8
    80004966:	bf49                	j	800048f8 <filewrite+0x80>
      iunlock(f->ip);
    80004968:	01893503          	ld	a0,24(s2)
    8000496c:	fffff097          	auipc	ra,0xfffff
    80004970:	f3e080e7          	jalr	-194(ra) # 800038aa <iunlock>
      end_op();
    80004974:	00000097          	auipc	ra,0x0
    80004978:	8b8080e7          	jalr	-1864(ra) # 8000422c <end_op>
      if(r < 0)
    8000497c:	fc04d8e3          	bgez	s1,8000494c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004980:	8552                	mv	a0,s4
    80004982:	033a1863          	bne	s4,s3,800049b2 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004986:	60a6                	ld	ra,72(sp)
    80004988:	6406                	ld	s0,64(sp)
    8000498a:	74e2                	ld	s1,56(sp)
    8000498c:	7942                	ld	s2,48(sp)
    8000498e:	79a2                	ld	s3,40(sp)
    80004990:	7a02                	ld	s4,32(sp)
    80004992:	6ae2                	ld	s5,24(sp)
    80004994:	6b42                	ld	s6,16(sp)
    80004996:	6ba2                	ld	s7,8(sp)
    80004998:	6c02                	ld	s8,0(sp)
    8000499a:	6161                	addi	sp,sp,80
    8000499c:	8082                	ret
        panic("short filewrite");
    8000499e:	00004517          	auipc	a0,0x4
    800049a2:	cfa50513          	addi	a0,a0,-774 # 80008698 <syscalls+0x270>
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	ba0080e7          	jalr	-1120(ra) # 80000546 <panic>
    int i = 0;
    800049ae:	4981                	li	s3,0
    800049b0:	bfc1                	j	80004980 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049b2:	557d                	li	a0,-1
    800049b4:	bfc9                	j	80004986 <filewrite+0x10e>
    panic("filewrite");
    800049b6:	00004517          	auipc	a0,0x4
    800049ba:	cf250513          	addi	a0,a0,-782 # 800086a8 <syscalls+0x280>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	b88080e7          	jalr	-1144(ra) # 80000546 <panic>
    return -1;
    800049c6:	557d                	li	a0,-1
}
    800049c8:	8082                	ret
      return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	bf6d                	j	80004986 <filewrite+0x10e>
    800049ce:	557d                	li	a0,-1
    800049d0:	bf5d                	j	80004986 <filewrite+0x10e>

00000000800049d2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049d2:	7179                	addi	sp,sp,-48
    800049d4:	f406                	sd	ra,40(sp)
    800049d6:	f022                	sd	s0,32(sp)
    800049d8:	ec26                	sd	s1,24(sp)
    800049da:	e84a                	sd	s2,16(sp)
    800049dc:	e44e                	sd	s3,8(sp)
    800049de:	e052                	sd	s4,0(sp)
    800049e0:	1800                	addi	s0,sp,48
    800049e2:	84aa                	mv	s1,a0
    800049e4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049e6:	0005b023          	sd	zero,0(a1)
    800049ea:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	bd2080e7          	jalr	-1070(ra) # 800045c0 <filealloc>
    800049f6:	e088                	sd	a0,0(s1)
    800049f8:	c551                	beqz	a0,80004a84 <pipealloc+0xb2>
    800049fa:	00000097          	auipc	ra,0x0
    800049fe:	bc6080e7          	jalr	-1082(ra) # 800045c0 <filealloc>
    80004a02:	00aa3023          	sd	a0,0(s4)
    80004a06:	c92d                	beqz	a0,80004a78 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	108080e7          	jalr	264(ra) # 80000b10 <kalloc>
    80004a10:	892a                	mv	s2,a0
    80004a12:	c125                	beqz	a0,80004a72 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a14:	4985                	li	s3,1
    80004a16:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a1a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a1e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a22:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a26:	00004597          	auipc	a1,0x4
    80004a2a:	c9258593          	addi	a1,a1,-878 # 800086b8 <syscalls+0x290>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	142080e7          	jalr	322(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    80004a36:	609c                	ld	a5,0(s1)
    80004a38:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a3c:	609c                	ld	a5,0(s1)
    80004a3e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a42:	609c                	ld	a5,0(s1)
    80004a44:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a48:	609c                	ld	a5,0(s1)
    80004a4a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a4e:	000a3783          	ld	a5,0(s4)
    80004a52:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a56:	000a3783          	ld	a5,0(s4)
    80004a5a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a5e:	000a3783          	ld	a5,0(s4)
    80004a62:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a66:	000a3783          	ld	a5,0(s4)
    80004a6a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a6e:	4501                	li	a0,0
    80004a70:	a025                	j	80004a98 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a72:	6088                	ld	a0,0(s1)
    80004a74:	e501                	bnez	a0,80004a7c <pipealloc+0xaa>
    80004a76:	a039                	j	80004a84 <pipealloc+0xb2>
    80004a78:	6088                	ld	a0,0(s1)
    80004a7a:	c51d                	beqz	a0,80004aa8 <pipealloc+0xd6>
    fileclose(*f0);
    80004a7c:	00000097          	auipc	ra,0x0
    80004a80:	c00080e7          	jalr	-1024(ra) # 8000467c <fileclose>
  if(*f1)
    80004a84:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a88:	557d                	li	a0,-1
  if(*f1)
    80004a8a:	c799                	beqz	a5,80004a98 <pipealloc+0xc6>
    fileclose(*f1);
    80004a8c:	853e                	mv	a0,a5
    80004a8e:	00000097          	auipc	ra,0x0
    80004a92:	bee080e7          	jalr	-1042(ra) # 8000467c <fileclose>
  return -1;
    80004a96:	557d                	li	a0,-1
}
    80004a98:	70a2                	ld	ra,40(sp)
    80004a9a:	7402                	ld	s0,32(sp)
    80004a9c:	64e2                	ld	s1,24(sp)
    80004a9e:	6942                	ld	s2,16(sp)
    80004aa0:	69a2                	ld	s3,8(sp)
    80004aa2:	6a02                	ld	s4,0(sp)
    80004aa4:	6145                	addi	sp,sp,48
    80004aa6:	8082                	ret
  return -1;
    80004aa8:	557d                	li	a0,-1
    80004aaa:	b7fd                	j	80004a98 <pipealloc+0xc6>

0000000080004aac <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004aac:	1101                	addi	sp,sp,-32
    80004aae:	ec06                	sd	ra,24(sp)
    80004ab0:	e822                	sd	s0,16(sp)
    80004ab2:	e426                	sd	s1,8(sp)
    80004ab4:	e04a                	sd	s2,0(sp)
    80004ab6:	1000                	addi	s0,sp,32
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	144080e7          	jalr	324(ra) # 80000c00 <acquire>
  if(writable){
    80004ac4:	02090d63          	beqz	s2,80004afe <pipeclose+0x52>
    pi->writeopen = 0;
    80004ac8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004acc:	21848513          	addi	a0,s1,536
    80004ad0:	ffffe097          	auipc	ra,0xffffe
    80004ad4:	a66080e7          	jalr	-1434(ra) # 80002536 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ad8:	2204b783          	ld	a5,544(s1)
    80004adc:	eb95                	bnez	a5,80004b10 <pipeclose+0x64>
    release(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	1d4080e7          	jalr	468(ra) # 80000cb4 <release>
    kfree((char*)pi);
    80004ae8:	8526                	mv	a0,s1
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	f28080e7          	jalr	-216(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004af2:	60e2                	ld	ra,24(sp)
    80004af4:	6442                	ld	s0,16(sp)
    80004af6:	64a2                	ld	s1,8(sp)
    80004af8:	6902                	ld	s2,0(sp)
    80004afa:	6105                	addi	sp,sp,32
    80004afc:	8082                	ret
    pi->readopen = 0;
    80004afe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b02:	21c48513          	addi	a0,s1,540
    80004b06:	ffffe097          	auipc	ra,0xffffe
    80004b0a:	a30080e7          	jalr	-1488(ra) # 80002536 <wakeup>
    80004b0e:	b7e9                	j	80004ad8 <pipeclose+0x2c>
    release(&pi->lock);
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	1a2080e7          	jalr	418(ra) # 80000cb4 <release>
}
    80004b1a:	bfe1                	j	80004af2 <pipeclose+0x46>

0000000080004b1c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b1c:	711d                	addi	sp,sp,-96
    80004b1e:	ec86                	sd	ra,88(sp)
    80004b20:	e8a2                	sd	s0,80(sp)
    80004b22:	e4a6                	sd	s1,72(sp)
    80004b24:	e0ca                	sd	s2,64(sp)
    80004b26:	fc4e                	sd	s3,56(sp)
    80004b28:	f852                	sd	s4,48(sp)
    80004b2a:	f456                	sd	s5,40(sp)
    80004b2c:	f05a                	sd	s6,32(sp)
    80004b2e:	ec5e                	sd	s7,24(sp)
    80004b30:	e862                	sd	s8,16(sp)
    80004b32:	1080                	addi	s0,sp,96
    80004b34:	84aa                	mv	s1,a0
    80004b36:	8b2e                	mv	s6,a1
    80004b38:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b3a:	ffffd097          	auipc	ra,0xffffd
    80004b3e:	fc6080e7          	jalr	-58(ra) # 80001b00 <myproc>
    80004b42:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b44:	8526                	mv	a0,s1
    80004b46:	ffffc097          	auipc	ra,0xffffc
    80004b4a:	0ba080e7          	jalr	186(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80004b4e:	09505863          	blez	s5,80004bde <pipewrite+0xc2>
    80004b52:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b54:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b58:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b5c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b5e:	2184a783          	lw	a5,536(s1)
    80004b62:	21c4a703          	lw	a4,540(s1)
    80004b66:	2007879b          	addiw	a5,a5,512
    80004b6a:	02f71b63          	bne	a4,a5,80004ba0 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004b6e:	2204a783          	lw	a5,544(s1)
    80004b72:	c3d9                	beqz	a5,80004bf8 <pipewrite+0xdc>
    80004b74:	03092783          	lw	a5,48(s2)
    80004b78:	e3c1                	bnez	a5,80004bf8 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004b7a:	8552                	mv	a0,s4
    80004b7c:	ffffe097          	auipc	ra,0xffffe
    80004b80:	9ba080e7          	jalr	-1606(ra) # 80002536 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b84:	85a6                	mv	a1,s1
    80004b86:	854e                	mv	a0,s3
    80004b88:	ffffe097          	auipc	ra,0xffffe
    80004b8c:	82e080e7          	jalr	-2002(ra) # 800023b6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b90:	2184a783          	lw	a5,536(s1)
    80004b94:	21c4a703          	lw	a4,540(s1)
    80004b98:	2007879b          	addiw	a5,a5,512
    80004b9c:	fcf709e3          	beq	a4,a5,80004b6e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba0:	4685                	li	a3,1
    80004ba2:	865a                	mv	a2,s6
    80004ba4:	faf40593          	addi	a1,s0,-81
    80004ba8:	05093503          	ld	a0,80(s2)
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	ca6080e7          	jalr	-858(ra) # 80001852 <copyin>
    80004bb4:	03850663          	beq	a0,s8,80004be0 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bb8:	21c4a783          	lw	a5,540(s1)
    80004bbc:	0017871b          	addiw	a4,a5,1
    80004bc0:	20e4ae23          	sw	a4,540(s1)
    80004bc4:	1ff7f793          	andi	a5,a5,511
    80004bc8:	97a6                	add	a5,a5,s1
    80004bca:	faf44703          	lbu	a4,-81(s0)
    80004bce:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bd2:	2b85                	addiw	s7,s7,1
    80004bd4:	0b05                	addi	s6,s6,1
    80004bd6:	f97a94e3          	bne	s5,s7,80004b5e <pipewrite+0x42>
    80004bda:	8bd6                	mv	s7,s5
    80004bdc:	a011                	j	80004be0 <pipewrite+0xc4>
    80004bde:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004be0:	21848513          	addi	a0,s1,536
    80004be4:	ffffe097          	auipc	ra,0xffffe
    80004be8:	952080e7          	jalr	-1710(ra) # 80002536 <wakeup>
  release(&pi->lock);
    80004bec:	8526                	mv	a0,s1
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	0c6080e7          	jalr	198(ra) # 80000cb4 <release>
  return i;
    80004bf6:	a039                	j	80004c04 <pipewrite+0xe8>
        release(&pi->lock);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	0ba080e7          	jalr	186(ra) # 80000cb4 <release>
        return -1;
    80004c02:	5bfd                	li	s7,-1
}
    80004c04:	855e                	mv	a0,s7
    80004c06:	60e6                	ld	ra,88(sp)
    80004c08:	6446                	ld	s0,80(sp)
    80004c0a:	64a6                	ld	s1,72(sp)
    80004c0c:	6906                	ld	s2,64(sp)
    80004c0e:	79e2                	ld	s3,56(sp)
    80004c10:	7a42                	ld	s4,48(sp)
    80004c12:	7aa2                	ld	s5,40(sp)
    80004c14:	7b02                	ld	s6,32(sp)
    80004c16:	6be2                	ld	s7,24(sp)
    80004c18:	6c42                	ld	s8,16(sp)
    80004c1a:	6125                	addi	sp,sp,96
    80004c1c:	8082                	ret

0000000080004c1e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c1e:	715d                	addi	sp,sp,-80
    80004c20:	e486                	sd	ra,72(sp)
    80004c22:	e0a2                	sd	s0,64(sp)
    80004c24:	fc26                	sd	s1,56(sp)
    80004c26:	f84a                	sd	s2,48(sp)
    80004c28:	f44e                	sd	s3,40(sp)
    80004c2a:	f052                	sd	s4,32(sp)
    80004c2c:	ec56                	sd	s5,24(sp)
    80004c2e:	e85a                	sd	s6,16(sp)
    80004c30:	0880                	addi	s0,sp,80
    80004c32:	84aa                	mv	s1,a0
    80004c34:	892e                	mv	s2,a1
    80004c36:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c38:	ffffd097          	auipc	ra,0xffffd
    80004c3c:	ec8080e7          	jalr	-312(ra) # 80001b00 <myproc>
    80004c40:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c42:	8526                	mv	a0,s1
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	fbc080e7          	jalr	-68(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c4c:	2184a703          	lw	a4,536(s1)
    80004c50:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c54:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c58:	02f71463          	bne	a4,a5,80004c80 <piperead+0x62>
    80004c5c:	2244a783          	lw	a5,548(s1)
    80004c60:	c385                	beqz	a5,80004c80 <piperead+0x62>
    if(pr->killed){
    80004c62:	030a2783          	lw	a5,48(s4)
    80004c66:	ebc9                	bnez	a5,80004cf8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c68:	85a6                	mv	a1,s1
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	74a080e7          	jalr	1866(ra) # 800023b6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c74:	2184a703          	lw	a4,536(s1)
    80004c78:	21c4a783          	lw	a5,540(s1)
    80004c7c:	fef700e3          	beq	a4,a5,80004c5c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c80:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c82:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c84:	05505463          	blez	s5,80004ccc <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004c88:	2184a783          	lw	a5,536(s1)
    80004c8c:	21c4a703          	lw	a4,540(s1)
    80004c90:	02f70e63          	beq	a4,a5,80004ccc <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c94:	0017871b          	addiw	a4,a5,1
    80004c98:	20e4ac23          	sw	a4,536(s1)
    80004c9c:	1ff7f793          	andi	a5,a5,511
    80004ca0:	97a6                	add	a5,a5,s1
    80004ca2:	0187c783          	lbu	a5,24(a5)
    80004ca6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004caa:	4685                	li	a3,1
    80004cac:	fbf40613          	addi	a2,s0,-65
    80004cb0:	85ca                	mv	a1,s2
    80004cb2:	050a3503          	ld	a0,80(s4)
    80004cb6:	ffffd097          	auipc	ra,0xffffd
    80004cba:	b10080e7          	jalr	-1264(ra) # 800017c6 <copyout>
    80004cbe:	01650763          	beq	a0,s6,80004ccc <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc2:	2985                	addiw	s3,s3,1
    80004cc4:	0905                	addi	s2,s2,1
    80004cc6:	fd3a91e3          	bne	s5,s3,80004c88 <piperead+0x6a>
    80004cca:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ccc:	21c48513          	addi	a0,s1,540
    80004cd0:	ffffe097          	auipc	ra,0xffffe
    80004cd4:	866080e7          	jalr	-1946(ra) # 80002536 <wakeup>
  release(&pi->lock);
    80004cd8:	8526                	mv	a0,s1
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	fda080e7          	jalr	-38(ra) # 80000cb4 <release>
  return i;
}
    80004ce2:	854e                	mv	a0,s3
    80004ce4:	60a6                	ld	ra,72(sp)
    80004ce6:	6406                	ld	s0,64(sp)
    80004ce8:	74e2                	ld	s1,56(sp)
    80004cea:	7942                	ld	s2,48(sp)
    80004cec:	79a2                	ld	s3,40(sp)
    80004cee:	7a02                	ld	s4,32(sp)
    80004cf0:	6ae2                	ld	s5,24(sp)
    80004cf2:	6b42                	ld	s6,16(sp)
    80004cf4:	6161                	addi	sp,sp,80
    80004cf6:	8082                	ret
      release(&pi->lock);
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	fba080e7          	jalr	-70(ra) # 80000cb4 <release>
      return -1;
    80004d02:	59fd                	li	s3,-1
    80004d04:	bff9                	j	80004ce2 <piperead+0xc4>

0000000080004d06 <vmprint>:
#include "elf.h"


static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

void vmprint(pagetable_t pa){
    80004d06:	7159                	addi	sp,sp,-112
    80004d08:	f486                	sd	ra,104(sp)
    80004d0a:	f0a2                	sd	s0,96(sp)
    80004d0c:	eca6                	sd	s1,88(sp)
    80004d0e:	e8ca                	sd	s2,80(sp)
    80004d10:	e4ce                	sd	s3,72(sp)
    80004d12:	e0d2                	sd	s4,64(sp)
    80004d14:	fc56                	sd	s5,56(sp)
    80004d16:	f85a                	sd	s6,48(sp)
    80004d18:	f45e                	sd	s7,40(sp)
    80004d1a:	f062                	sd	s8,32(sp)
    80004d1c:	ec66                	sd	s9,24(sp)
    80004d1e:	e86a                	sd	s10,16(sp)
    80004d20:	e46e                	sd	s11,8(sp)
    80004d22:	1880                	addi	s0,sp,112
    80004d24:	8c2a                	mv	s8,a0
    printf("page table %p\n", pa);
    80004d26:	85aa                	mv	a1,a0
    80004d28:	00004517          	auipc	a0,0x4
    80004d2c:	99850513          	addi	a0,a0,-1640 # 800086c0 <syscalls+0x298>
    80004d30:	ffffc097          	auipc	ra,0xffffc
    80004d34:	860080e7          	jalr	-1952(ra) # 80000590 <printf>
    for(int i = 0; i < 512; i++){
    80004d38:	4c81                	li	s9,0
    pte_t pte = pa[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004d3a:	4b85                	li	s7,1
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      printf("||%d: pte %p pa %p\n",i ,pte, child);
      // vmprint((pagetable_t)child);
      
      for(int j = 0; j < 512; j++){
    80004d3c:	4d01                	li	s10,0
        pte_t pte_c = ((pagetable_t)child)[j];
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
          uint64 child_c = PTE2PA(pte_c);
          printf("|| ||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004d3e:	00004d97          	auipc	s11,0x4
    80004d42:	9aad8d93          	addi	s11,s11,-1622 # 800086e8 <syscalls+0x2c0>
          for(int k = 0; k < 512; k++){
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
            // printf("||||||%d: pte %p\n",k ,pte_c_c);
            if((pte_c_c & PTE_V)){
              uint64 child_c_c = PTE2PA(pte_c_c);
              printf("|| || ||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004d46:	00004b17          	auipc	s6,0x4
    80004d4a:	9bab0b13          	addi	s6,s6,-1606 # 80008700 <syscalls+0x2d8>
          for(int k = 0; k < 512; k++){
    80004d4e:	20000993          	li	s3,512
    80004d52:	a8b1                	j	80004dae <vmprint+0xa8>
    80004d54:	2485                	addiw	s1,s1,1
    80004d56:	0921                	addi	s2,s2,8
    80004d58:	03348163          	beq	s1,s3,80004d7a <vmprint+0x74>
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
    80004d5c:	00093603          	ld	a2,0(s2)
            if((pte_c_c & PTE_V)){
    80004d60:	00167793          	andi	a5,a2,1
    80004d64:	dbe5                	beqz	a5,80004d54 <vmprint+0x4e>
              uint64 child_c_c = PTE2PA(pte_c_c);
    80004d66:	00a65693          	srli	a3,a2,0xa
              printf("|| || ||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004d6a:	06b2                	slli	a3,a3,0xc
    80004d6c:	85a6                	mv	a1,s1
    80004d6e:	855a                	mv	a0,s6
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	820080e7          	jalr	-2016(ra) # 80000590 <printf>
    80004d78:	bff1                	j	80004d54 <vmprint+0x4e>
      for(int j = 0; j < 512; j++){
    80004d7a:	2a05                	addiw	s4,s4,1
    80004d7c:	0aa1                	addi	s5,s5,8
    80004d7e:	033a0463          	beq	s4,s3,80004da6 <vmprint+0xa0>
        pte_t pte_c = ((pagetable_t)child)[j];
    80004d82:	000ab603          	ld	a2,0(s5)
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
    80004d86:	00f67793          	andi	a5,a2,15
    80004d8a:	ff7798e3          	bne	a5,s7,80004d7a <vmprint+0x74>
          uint64 child_c = PTE2PA(pte_c);
    80004d8e:	00a65913          	srli	s2,a2,0xa
    80004d92:	0932                	slli	s2,s2,0xc
          printf("|| ||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004d94:	86ca                	mv	a3,s2
    80004d96:	85d2                	mv	a1,s4
    80004d98:	856e                	mv	a0,s11
    80004d9a:	ffffb097          	auipc	ra,0xffffb
    80004d9e:	7f6080e7          	jalr	2038(ra) # 80000590 <printf>
          for(int k = 0; k < 512; k++){
    80004da2:	84ea                	mv	s1,s10
    80004da4:	bf65                	j	80004d5c <vmprint+0x56>
    for(int i = 0; i < 512; i++){
    80004da6:	2c85                	addiw	s9,s9,1 # 2001 <_entry-0x7fffdfff>
    80004da8:	0c21                	addi	s8,s8,8
    80004daa:	033c8763          	beq	s9,s3,80004dd8 <vmprint+0xd2>
    pte_t pte = pa[i];
    80004dae:	000c3603          	ld	a2,0(s8)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004db2:	00f67793          	andi	a5,a2,15
    80004db6:	ff7798e3          	bne	a5,s7,80004da6 <vmprint+0xa0>
      uint64 child = PTE2PA(pte);
    80004dba:	00a65a93          	srli	s5,a2,0xa
    80004dbe:	0ab2                	slli	s5,s5,0xc
      printf("||%d: pte %p pa %p\n",i ,pte, child);
    80004dc0:	86d6                	mv	a3,s5
    80004dc2:	85e6                	mv	a1,s9
    80004dc4:	00004517          	auipc	a0,0x4
    80004dc8:	90c50513          	addi	a0,a0,-1780 # 800086d0 <syscalls+0x2a8>
    80004dcc:	ffffb097          	auipc	ra,0xffffb
    80004dd0:	7c4080e7          	jalr	1988(ra) # 80000590 <printf>
      for(int j = 0; j < 512; j++){
    80004dd4:	8a6a                	mv	s4,s10
    80004dd6:	b775                	j	80004d82 <vmprint+0x7c>
        }

      } 
    }
  }
}
    80004dd8:	70a6                	ld	ra,104(sp)
    80004dda:	7406                	ld	s0,96(sp)
    80004ddc:	64e6                	ld	s1,88(sp)
    80004dde:	6946                	ld	s2,80(sp)
    80004de0:	69a6                	ld	s3,72(sp)
    80004de2:	6a06                	ld	s4,64(sp)
    80004de4:	7ae2                	ld	s5,56(sp)
    80004de6:	7b42                	ld	s6,48(sp)
    80004de8:	7ba2                	ld	s7,40(sp)
    80004dea:	7c02                	ld	s8,32(sp)
    80004dec:	6ce2                	ld	s9,24(sp)
    80004dee:	6d42                	ld	s10,16(sp)
    80004df0:	6da2                	ld	s11,8(sp)
    80004df2:	6165                	addi	sp,sp,112
    80004df4:	8082                	ret

0000000080004df6 <exec>:

int
exec(char *path, char **argv)
{
    80004df6:	de010113          	addi	sp,sp,-544
    80004dfa:	20113c23          	sd	ra,536(sp)
    80004dfe:	20813823          	sd	s0,528(sp)
    80004e02:	20913423          	sd	s1,520(sp)
    80004e06:	21213023          	sd	s2,512(sp)
    80004e0a:	ffce                	sd	s3,504(sp)
    80004e0c:	fbd2                	sd	s4,496(sp)
    80004e0e:	f7d6                	sd	s5,488(sp)
    80004e10:	f3da                	sd	s6,480(sp)
    80004e12:	efde                	sd	s7,472(sp)
    80004e14:	ebe2                	sd	s8,464(sp)
    80004e16:	e7e6                	sd	s9,456(sp)
    80004e18:	e3ea                	sd	s10,448(sp)
    80004e1a:	ff6e                	sd	s11,440(sp)
    80004e1c:	1400                	addi	s0,sp,544
    80004e1e:	892a                	mv	s2,a0
    80004e20:	dea43423          	sd	a0,-536(s0)
    80004e24:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e28:	ffffd097          	auipc	ra,0xffffd
    80004e2c:	cd8080e7          	jalr	-808(ra) # 80001b00 <myproc>
    80004e30:	84aa                	mv	s1,a0

  begin_op();
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	37c080e7          	jalr	892(ra) # 800041ae <begin_op>

  if((ip = namei(path)) == 0){
    80004e3a:	854a                	mv	a0,s2
    80004e3c:	fffff097          	auipc	ra,0xfffff
    80004e40:	162080e7          	jalr	354(ra) # 80003f9e <namei>
    80004e44:	c93d                	beqz	a0,80004eba <exec+0xc4>
    80004e46:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e48:	fffff097          	auipc	ra,0xfffff
    80004e4c:	9a0080e7          	jalr	-1632(ra) # 800037e8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e50:	04000713          	li	a4,64
    80004e54:	4681                	li	a3,0
    80004e56:	e4840613          	addi	a2,s0,-440
    80004e5a:	4581                	li	a1,0
    80004e5c:	8556                	mv	a0,s5
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	c3e080e7          	jalr	-962(ra) # 80003a9c <readi>
    80004e66:	04000793          	li	a5,64
    80004e6a:	00f51a63          	bne	a0,a5,80004e7e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e6e:	e4842703          	lw	a4,-440(s0)
    80004e72:	464c47b7          	lui	a5,0x464c4
    80004e76:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e7a:	04f70663          	beq	a4,a5,80004ec6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e7e:	8556                	mv	a0,s5
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	bca080e7          	jalr	-1078(ra) # 80003a4a <iunlockput>
    end_op();
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	3a4080e7          	jalr	932(ra) # 8000422c <end_op>
  }
  return -1;
    80004e90:	557d                	li	a0,-1
}
    80004e92:	21813083          	ld	ra,536(sp)
    80004e96:	21013403          	ld	s0,528(sp)
    80004e9a:	20813483          	ld	s1,520(sp)
    80004e9e:	20013903          	ld	s2,512(sp)
    80004ea2:	79fe                	ld	s3,504(sp)
    80004ea4:	7a5e                	ld	s4,496(sp)
    80004ea6:	7abe                	ld	s5,488(sp)
    80004ea8:	7b1e                	ld	s6,480(sp)
    80004eaa:	6bfe                	ld	s7,472(sp)
    80004eac:	6c5e                	ld	s8,464(sp)
    80004eae:	6cbe                	ld	s9,456(sp)
    80004eb0:	6d1e                	ld	s10,448(sp)
    80004eb2:	7dfa                	ld	s11,440(sp)
    80004eb4:	22010113          	addi	sp,sp,544
    80004eb8:	8082                	ret
    end_op();
    80004eba:	fffff097          	auipc	ra,0xfffff
    80004ebe:	372080e7          	jalr	882(ra) # 8000422c <end_op>
    return -1;
    80004ec2:	557d                	li	a0,-1
    80004ec4:	b7f9                	j	80004e92 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	ffffd097          	auipc	ra,0xffffd
    80004ecc:	d56080e7          	jalr	-682(ra) # 80001c1e <proc_pagetable>
    80004ed0:	8b2a                	mv	s6,a0
    80004ed2:	d555                	beqz	a0,80004e7e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed4:	e6842783          	lw	a5,-408(s0)
    80004ed8:	e8045703          	lhu	a4,-384(s0)
    80004edc:	c735                	beqz	a4,80004f48 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ede:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ee4:	6a05                	lui	s4,0x1
    80004ee6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004eea:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004eee:	6d85                	lui	s11,0x1
    80004ef0:	7d7d                	lui	s10,0xfffff
    80004ef2:	a4b9                	j	80005140 <exec+0x34a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ef4:	00004517          	auipc	a0,0x4
    80004ef8:	82c50513          	addi	a0,a0,-2004 # 80008720 <syscalls+0x2f8>
    80004efc:	ffffb097          	auipc	ra,0xffffb
    80004f00:	64a080e7          	jalr	1610(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f04:	874a                	mv	a4,s2
    80004f06:	009c86bb          	addw	a3,s9,s1
    80004f0a:	4581                	li	a1,0
    80004f0c:	8556                	mv	a0,s5
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	b8e080e7          	jalr	-1138(ra) # 80003a9c <readi>
    80004f16:	2501                	sext.w	a0,a0
    80004f18:	1ca91463          	bne	s2,a0,800050e0 <exec+0x2ea>
  for(i = 0; i < sz; i += PGSIZE){
    80004f1c:	009d84bb          	addw	s1,s11,s1
    80004f20:	013d09bb          	addw	s3,s10,s3
    80004f24:	1f74fe63          	bgeu	s1,s7,80005120 <exec+0x32a>
    pa = walkaddr(pagetable, va + i);
    80004f28:	02049593          	slli	a1,s1,0x20
    80004f2c:	9181                	srli	a1,a1,0x20
    80004f2e:	95e2                	add	a1,a1,s8
    80004f30:	855a                	mv	a0,s6
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	160080e7          	jalr	352(ra) # 80001092 <walkaddr>
    80004f3a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f3c:	dd45                	beqz	a0,80004ef4 <exec+0xfe>
      n = PGSIZE;
    80004f3e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f40:	fd49f2e3          	bgeu	s3,s4,80004f04 <exec+0x10e>
      n = sz - i;
    80004f44:	894e                	mv	s2,s3
    80004f46:	bf7d                	j	80004f04 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f48:	4481                	li	s1,0
  iunlockput(ip);
    80004f4a:	8556                	mv	a0,s5
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	afe080e7          	jalr	-1282(ra) # 80003a4a <iunlockput>
  end_op();
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	2d8080e7          	jalr	728(ra) # 8000422c <end_op>
  p = myproc();
    80004f5c:	ffffd097          	auipc	ra,0xffffd
    80004f60:	ba4080e7          	jalr	-1116(ra) # 80001b00 <myproc>
    80004f64:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f66:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f6a:	6785                	lui	a5,0x1
    80004f6c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f6e:	97a6                	add	a5,a5,s1
    80004f70:	777d                	lui	a4,0xfffff
    80004f72:	8ff9                	and	a5,a5,a4
    80004f74:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f78:	6609                	lui	a2,0x2
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	85be                	mv	a1,a5
    80004f7e:	855a                	mv	a0,s6
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	5f2080e7          	jalr	1522(ra) # 80001572 <uvmalloc>
    80004f88:	8c2a                	mv	s8,a0
  ip = 0;
    80004f8a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f8c:	14050a63          	beqz	a0,800050e0 <exec+0x2ea>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f90:	75f9                	lui	a1,0xffffe
    80004f92:	95aa                	add	a1,a1,a0
    80004f94:	855a                	mv	a0,s6
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	7fe080e7          	jalr	2046(ra) # 80001794 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f9e:	7afd                	lui	s5,0xfffff
    80004fa0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fa2:	df043783          	ld	a5,-528(s0)
    80004fa6:	6388                	ld	a0,0(a5)
    80004fa8:	c925                	beqz	a0,80005018 <exec+0x222>
    80004faa:	e8840993          	addi	s3,s0,-376
    80004fae:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004fb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fb4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	eca080e7          	jalr	-310(ra) # 80000e80 <strlen>
    80004fbe:	0015079b          	addiw	a5,a0,1
    80004fc2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fc6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004fca:	13596f63          	bltu	s2,s5,80005108 <exec+0x312>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fce:	df043d83          	ld	s11,-528(s0)
    80004fd2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fd6:	8552                	mv	a0,s4
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	ea8080e7          	jalr	-344(ra) # 80000e80 <strlen>
    80004fe0:	0015069b          	addiw	a3,a0,1
    80004fe4:	8652                	mv	a2,s4
    80004fe6:	85ca                	mv	a1,s2
    80004fe8:	855a                	mv	a0,s6
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	7dc080e7          	jalr	2012(ra) # 800017c6 <copyout>
    80004ff2:	10054f63          	bltz	a0,80005110 <exec+0x31a>
    ustack[argc] = sp;
    80004ff6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ffa:	0485                	addi	s1,s1,1
    80004ffc:	008d8793          	addi	a5,s11,8
    80005000:	def43823          	sd	a5,-528(s0)
    80005004:	008db503          	ld	a0,8(s11)
    80005008:	c911                	beqz	a0,8000501c <exec+0x226>
    if(argc >= MAXARG)
    8000500a:	09a1                	addi	s3,s3,8
    8000500c:	fb3c95e3          	bne	s9,s3,80004fb6 <exec+0x1c0>
  sz = sz1;
    80005010:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005014:	4a81                	li	s5,0
    80005016:	a0e9                	j	800050e0 <exec+0x2ea>
  sp = sz;
    80005018:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000501a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000501c:	00349793          	slli	a5,s1,0x3
    80005020:	f9078793          	addi	a5,a5,-112
    80005024:	97a2                	add	a5,a5,s0
    80005026:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000502a:	00148693          	addi	a3,s1,1
    8000502e:	068e                	slli	a3,a3,0x3
    80005030:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005034:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005038:	01597663          	bgeu	s2,s5,80005044 <exec+0x24e>
  sz = sz1;
    8000503c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005040:	4a81                	li	s5,0
    80005042:	a879                	j	800050e0 <exec+0x2ea>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005044:	e8840613          	addi	a2,s0,-376
    80005048:	85ca                	mv	a1,s2
    8000504a:	855a                	mv	a0,s6
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	77a080e7          	jalr	1914(ra) # 800017c6 <copyout>
    80005054:	0c054263          	bltz	a0,80005118 <exec+0x322>
  p->trapframe->a1 = sp;
    80005058:	058bb783          	ld	a5,88(s7)
    8000505c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005060:	de843783          	ld	a5,-536(s0)
    80005064:	0007c703          	lbu	a4,0(a5)
    80005068:	cf11                	beqz	a4,80005084 <exec+0x28e>
    8000506a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000506c:	02f00693          	li	a3,47
    80005070:	a039                	j	8000507e <exec+0x288>
      last = s+1;
    80005072:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005076:	0785                	addi	a5,a5,1
    80005078:	fff7c703          	lbu	a4,-1(a5)
    8000507c:	c701                	beqz	a4,80005084 <exec+0x28e>
    if(*s == '/')
    8000507e:	fed71ce3          	bne	a4,a3,80005076 <exec+0x280>
    80005082:	bfc5                	j	80005072 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005084:	4641                	li	a2,16
    80005086:	de843583          	ld	a1,-536(s0)
    8000508a:	158b8513          	addi	a0,s7,344
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	dc0080e7          	jalr	-576(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    80005096:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000509a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000509e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050a2:	058bb783          	ld	a5,88(s7)
    800050a6:	e6043703          	ld	a4,-416(s0)
    800050aa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050ac:	058bb783          	ld	a5,88(s7)
    800050b0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050b4:	85ea                	mv	a1,s10
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	c04080e7          	jalr	-1020(ra) # 80001cba <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable); 
    800050be:	038ba703          	lw	a4,56(s7)
    800050c2:	4785                	li	a5,1
    800050c4:	00f70563          	beq	a4,a5,800050ce <exec+0x2d8>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050c8:	0004851b          	sext.w	a0,s1
    800050cc:	b3d9                	j	80004e92 <exec+0x9c>
  if(p->pid==1) vmprint(p->pagetable); 
    800050ce:	050bb503          	ld	a0,80(s7)
    800050d2:	00000097          	auipc	ra,0x0
    800050d6:	c34080e7          	jalr	-972(ra) # 80004d06 <vmprint>
    800050da:	b7fd                	j	800050c8 <exec+0x2d2>
    800050dc:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050e0:	df843583          	ld	a1,-520(s0)
    800050e4:	855a                	mv	a0,s6
    800050e6:	ffffd097          	auipc	ra,0xffffd
    800050ea:	bd4080e7          	jalr	-1068(ra) # 80001cba <proc_freepagetable>
  if(ip){
    800050ee:	d80a98e3          	bnez	s5,80004e7e <exec+0x88>
  return -1;
    800050f2:	557d                	li	a0,-1
    800050f4:	bb79                	j	80004e92 <exec+0x9c>
    800050f6:	de943c23          	sd	s1,-520(s0)
    800050fa:	b7dd                	j	800050e0 <exec+0x2ea>
    800050fc:	de943c23          	sd	s1,-520(s0)
    80005100:	b7c5                	j	800050e0 <exec+0x2ea>
    80005102:	de943c23          	sd	s1,-520(s0)
    80005106:	bfe9                	j	800050e0 <exec+0x2ea>
  sz = sz1;
    80005108:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000510c:	4a81                	li	s5,0
    8000510e:	bfc9                	j	800050e0 <exec+0x2ea>
  sz = sz1;
    80005110:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005114:	4a81                	li	s5,0
    80005116:	b7e9                	j	800050e0 <exec+0x2ea>
  sz = sz1;
    80005118:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511c:	4a81                	li	s5,0
    8000511e:	b7c9                	j	800050e0 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005120:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005124:	e0843783          	ld	a5,-504(s0)
    80005128:	0017869b          	addiw	a3,a5,1
    8000512c:	e0d43423          	sd	a3,-504(s0)
    80005130:	e0043783          	ld	a5,-512(s0)
    80005134:	0387879b          	addiw	a5,a5,56
    80005138:	e8045703          	lhu	a4,-384(s0)
    8000513c:	e0e6d7e3          	bge	a3,a4,80004f4a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005140:	2781                	sext.w	a5,a5
    80005142:	e0f43023          	sd	a5,-512(s0)
    80005146:	03800713          	li	a4,56
    8000514a:	86be                	mv	a3,a5
    8000514c:	e1040613          	addi	a2,s0,-496
    80005150:	4581                	li	a1,0
    80005152:	8556                	mv	a0,s5
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	948080e7          	jalr	-1720(ra) # 80003a9c <readi>
    8000515c:	03800793          	li	a5,56
    80005160:	f6f51ee3          	bne	a0,a5,800050dc <exec+0x2e6>
    if(ph.type != ELF_PROG_LOAD)
    80005164:	e1042783          	lw	a5,-496(s0)
    80005168:	4705                	li	a4,1
    8000516a:	fae79de3          	bne	a5,a4,80005124 <exec+0x32e>
    if(ph.memsz < ph.filesz)
    8000516e:	e3843603          	ld	a2,-456(s0)
    80005172:	e3043783          	ld	a5,-464(s0)
    80005176:	f8f660e3          	bltu	a2,a5,800050f6 <exec+0x300>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000517a:	e2043783          	ld	a5,-480(s0)
    8000517e:	963e                	add	a2,a2,a5
    80005180:	f6f66ee3          	bltu	a2,a5,800050fc <exec+0x306>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005184:	85a6                	mv	a1,s1
    80005186:	855a                	mv	a0,s6
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	3ea080e7          	jalr	1002(ra) # 80001572 <uvmalloc>
    80005190:	dea43c23          	sd	a0,-520(s0)
    80005194:	d53d                	beqz	a0,80005102 <exec+0x30c>
    if(ph.vaddr % PGSIZE != 0)
    80005196:	e2043c03          	ld	s8,-480(s0)
    8000519a:	de043783          	ld	a5,-544(s0)
    8000519e:	00fc77b3          	and	a5,s8,a5
    800051a2:	ff9d                	bnez	a5,800050e0 <exec+0x2ea>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051a4:	e1842c83          	lw	s9,-488(s0)
    800051a8:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051ac:	f60b8ae3          	beqz	s7,80005120 <exec+0x32a>
    800051b0:	89de                	mv	s3,s7
    800051b2:	4481                	li	s1,0
    800051b4:	bb95                	j	80004f28 <exec+0x132>

00000000800051b6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051b6:	7179                	addi	sp,sp,-48
    800051b8:	f406                	sd	ra,40(sp)
    800051ba:	f022                	sd	s0,32(sp)
    800051bc:	ec26                	sd	s1,24(sp)
    800051be:	e84a                	sd	s2,16(sp)
    800051c0:	1800                	addi	s0,sp,48
    800051c2:	892e                	mv	s2,a1
    800051c4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800051c6:	fdc40593          	addi	a1,s0,-36
    800051ca:	ffffe097          	auipc	ra,0xffffe
    800051ce:	a94080e7          	jalr	-1388(ra) # 80002c5e <argint>
    800051d2:	04054063          	bltz	a0,80005212 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051d6:	fdc42703          	lw	a4,-36(s0)
    800051da:	47bd                	li	a5,15
    800051dc:	02e7ed63          	bltu	a5,a4,80005216 <argfd+0x60>
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	920080e7          	jalr	-1760(ra) # 80001b00 <myproc>
    800051e8:	fdc42703          	lw	a4,-36(s0)
    800051ec:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd7ffa>
    800051f0:	078e                	slli	a5,a5,0x3
    800051f2:	953e                	add	a0,a0,a5
    800051f4:	611c                	ld	a5,0(a0)
    800051f6:	c395                	beqz	a5,8000521a <argfd+0x64>
    return -1;
  if(pfd)
    800051f8:	00090463          	beqz	s2,80005200 <argfd+0x4a>
    *pfd = fd;
    800051fc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005200:	4501                	li	a0,0
  if(pf)
    80005202:	c091                	beqz	s1,80005206 <argfd+0x50>
    *pf = f;
    80005204:	e09c                	sd	a5,0(s1)
}
    80005206:	70a2                	ld	ra,40(sp)
    80005208:	7402                	ld	s0,32(sp)
    8000520a:	64e2                	ld	s1,24(sp)
    8000520c:	6942                	ld	s2,16(sp)
    8000520e:	6145                	addi	sp,sp,48
    80005210:	8082                	ret
    return -1;
    80005212:	557d                	li	a0,-1
    80005214:	bfcd                	j	80005206 <argfd+0x50>
    return -1;
    80005216:	557d                	li	a0,-1
    80005218:	b7fd                	j	80005206 <argfd+0x50>
    8000521a:	557d                	li	a0,-1
    8000521c:	b7ed                	j	80005206 <argfd+0x50>

000000008000521e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000521e:	1101                	addi	sp,sp,-32
    80005220:	ec06                	sd	ra,24(sp)
    80005222:	e822                	sd	s0,16(sp)
    80005224:	e426                	sd	s1,8(sp)
    80005226:	1000                	addi	s0,sp,32
    80005228:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000522a:	ffffd097          	auipc	ra,0xffffd
    8000522e:	8d6080e7          	jalr	-1834(ra) # 80001b00 <myproc>
    80005232:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005234:	0d050793          	addi	a5,a0,208
    80005238:	4501                	li	a0,0
    8000523a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000523c:	6398                	ld	a4,0(a5)
    8000523e:	cb19                	beqz	a4,80005254 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005240:	2505                	addiw	a0,a0,1
    80005242:	07a1                	addi	a5,a5,8
    80005244:	fed51ce3          	bne	a0,a3,8000523c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005248:	557d                	li	a0,-1
}
    8000524a:	60e2                	ld	ra,24(sp)
    8000524c:	6442                	ld	s0,16(sp)
    8000524e:	64a2                	ld	s1,8(sp)
    80005250:	6105                	addi	sp,sp,32
    80005252:	8082                	ret
      p->ofile[fd] = f;
    80005254:	01a50793          	addi	a5,a0,26
    80005258:	078e                	slli	a5,a5,0x3
    8000525a:	963e                	add	a2,a2,a5
    8000525c:	e204                	sd	s1,0(a2)
      return fd;
    8000525e:	b7f5                	j	8000524a <fdalloc+0x2c>

0000000080005260 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005260:	715d                	addi	sp,sp,-80
    80005262:	e486                	sd	ra,72(sp)
    80005264:	e0a2                	sd	s0,64(sp)
    80005266:	fc26                	sd	s1,56(sp)
    80005268:	f84a                	sd	s2,48(sp)
    8000526a:	f44e                	sd	s3,40(sp)
    8000526c:	f052                	sd	s4,32(sp)
    8000526e:	ec56                	sd	s5,24(sp)
    80005270:	0880                	addi	s0,sp,80
    80005272:	89ae                	mv	s3,a1
    80005274:	8ab2                	mv	s5,a2
    80005276:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005278:	fb040593          	addi	a1,s0,-80
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	d40080e7          	jalr	-704(ra) # 80003fbc <nameiparent>
    80005284:	892a                	mv	s2,a0
    80005286:	12050e63          	beqz	a0,800053c2 <create+0x162>
    return 0;

  ilock(dp);
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	55e080e7          	jalr	1374(ra) # 800037e8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005292:	4601                	li	a2,0
    80005294:	fb040593          	addi	a1,s0,-80
    80005298:	854a                	mv	a0,s2
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	a2c080e7          	jalr	-1492(ra) # 80003cc6 <dirlookup>
    800052a2:	84aa                	mv	s1,a0
    800052a4:	c921                	beqz	a0,800052f4 <create+0x94>
    iunlockput(dp);
    800052a6:	854a                	mv	a0,s2
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	7a2080e7          	jalr	1954(ra) # 80003a4a <iunlockput>
    ilock(ip);
    800052b0:	8526                	mv	a0,s1
    800052b2:	ffffe097          	auipc	ra,0xffffe
    800052b6:	536080e7          	jalr	1334(ra) # 800037e8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052ba:	2981                	sext.w	s3,s3
    800052bc:	4789                	li	a5,2
    800052be:	02f99463          	bne	s3,a5,800052e6 <create+0x86>
    800052c2:	0444d783          	lhu	a5,68(s1)
    800052c6:	37f9                	addiw	a5,a5,-2
    800052c8:	17c2                	slli	a5,a5,0x30
    800052ca:	93c1                	srli	a5,a5,0x30
    800052cc:	4705                	li	a4,1
    800052ce:	00f76c63          	bltu	a4,a5,800052e6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800052d2:	8526                	mv	a0,s1
    800052d4:	60a6                	ld	ra,72(sp)
    800052d6:	6406                	ld	s0,64(sp)
    800052d8:	74e2                	ld	s1,56(sp)
    800052da:	7942                	ld	s2,48(sp)
    800052dc:	79a2                	ld	s3,40(sp)
    800052de:	7a02                	ld	s4,32(sp)
    800052e0:	6ae2                	ld	s5,24(sp)
    800052e2:	6161                	addi	sp,sp,80
    800052e4:	8082                	ret
    iunlockput(ip);
    800052e6:	8526                	mv	a0,s1
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	762080e7          	jalr	1890(ra) # 80003a4a <iunlockput>
    return 0;
    800052f0:	4481                	li	s1,0
    800052f2:	b7c5                	j	800052d2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052f4:	85ce                	mv	a1,s3
    800052f6:	00092503          	lw	a0,0(s2)
    800052fa:	ffffe097          	auipc	ra,0xffffe
    800052fe:	354080e7          	jalr	852(ra) # 8000364e <ialloc>
    80005302:	84aa                	mv	s1,a0
    80005304:	c521                	beqz	a0,8000534c <create+0xec>
  ilock(ip);
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	4e2080e7          	jalr	1250(ra) # 800037e8 <ilock>
  ip->major = major;
    8000530e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005312:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005316:	4a05                	li	s4,1
    80005318:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000531c:	8526                	mv	a0,s1
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	3fe080e7          	jalr	1022(ra) # 8000371c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005326:	2981                	sext.w	s3,s3
    80005328:	03498a63          	beq	s3,s4,8000535c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000532c:	40d0                	lw	a2,4(s1)
    8000532e:	fb040593          	addi	a1,s0,-80
    80005332:	854a                	mv	a0,s2
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	ba8080e7          	jalr	-1112(ra) # 80003edc <dirlink>
    8000533c:	06054b63          	bltz	a0,800053b2 <create+0x152>
  iunlockput(dp);
    80005340:	854a                	mv	a0,s2
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	708080e7          	jalr	1800(ra) # 80003a4a <iunlockput>
  return ip;
    8000534a:	b761                	j	800052d2 <create+0x72>
    panic("create: ialloc");
    8000534c:	00003517          	auipc	a0,0x3
    80005350:	3f450513          	addi	a0,a0,1012 # 80008740 <syscalls+0x318>
    80005354:	ffffb097          	auipc	ra,0xffffb
    80005358:	1f2080e7          	jalr	498(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    8000535c:	04a95783          	lhu	a5,74(s2)
    80005360:	2785                	addiw	a5,a5,1
    80005362:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005366:	854a                	mv	a0,s2
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	3b4080e7          	jalr	948(ra) # 8000371c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005370:	40d0                	lw	a2,4(s1)
    80005372:	00003597          	auipc	a1,0x3
    80005376:	3de58593          	addi	a1,a1,990 # 80008750 <syscalls+0x328>
    8000537a:	8526                	mv	a0,s1
    8000537c:	fffff097          	auipc	ra,0xfffff
    80005380:	b60080e7          	jalr	-1184(ra) # 80003edc <dirlink>
    80005384:	00054f63          	bltz	a0,800053a2 <create+0x142>
    80005388:	00492603          	lw	a2,4(s2)
    8000538c:	00003597          	auipc	a1,0x3
    80005390:	3cc58593          	addi	a1,a1,972 # 80008758 <syscalls+0x330>
    80005394:	8526                	mv	a0,s1
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	b46080e7          	jalr	-1210(ra) # 80003edc <dirlink>
    8000539e:	f80557e3          	bgez	a0,8000532c <create+0xcc>
      panic("create dots");
    800053a2:	00003517          	auipc	a0,0x3
    800053a6:	3be50513          	addi	a0,a0,958 # 80008760 <syscalls+0x338>
    800053aa:	ffffb097          	auipc	ra,0xffffb
    800053ae:	19c080e7          	jalr	412(ra) # 80000546 <panic>
    panic("create: dirlink");
    800053b2:	00003517          	auipc	a0,0x3
    800053b6:	3be50513          	addi	a0,a0,958 # 80008770 <syscalls+0x348>
    800053ba:	ffffb097          	auipc	ra,0xffffb
    800053be:	18c080e7          	jalr	396(ra) # 80000546 <panic>
    return 0;
    800053c2:	84aa                	mv	s1,a0
    800053c4:	b739                	j	800052d2 <create+0x72>

00000000800053c6 <sys_dup>:
{
    800053c6:	7179                	addi	sp,sp,-48
    800053c8:	f406                	sd	ra,40(sp)
    800053ca:	f022                	sd	s0,32(sp)
    800053cc:	ec26                	sd	s1,24(sp)
    800053ce:	e84a                	sd	s2,16(sp)
    800053d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053d2:	fd840613          	addi	a2,s0,-40
    800053d6:	4581                	li	a1,0
    800053d8:	4501                	li	a0,0
    800053da:	00000097          	auipc	ra,0x0
    800053de:	ddc080e7          	jalr	-548(ra) # 800051b6 <argfd>
    return -1;
    800053e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053e4:	02054363          	bltz	a0,8000540a <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800053e8:	fd843903          	ld	s2,-40(s0)
    800053ec:	854a                	mv	a0,s2
    800053ee:	00000097          	auipc	ra,0x0
    800053f2:	e30080e7          	jalr	-464(ra) # 8000521e <fdalloc>
    800053f6:	84aa                	mv	s1,a0
    return -1;
    800053f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053fa:	00054863          	bltz	a0,8000540a <sys_dup+0x44>
  filedup(f);
    800053fe:	854a                	mv	a0,s2
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	22a080e7          	jalr	554(ra) # 8000462a <filedup>
  return fd;
    80005408:	87a6                	mv	a5,s1
}
    8000540a:	853e                	mv	a0,a5
    8000540c:	70a2                	ld	ra,40(sp)
    8000540e:	7402                	ld	s0,32(sp)
    80005410:	64e2                	ld	s1,24(sp)
    80005412:	6942                	ld	s2,16(sp)
    80005414:	6145                	addi	sp,sp,48
    80005416:	8082                	ret

0000000080005418 <sys_read>:
{
    80005418:	7179                	addi	sp,sp,-48
    8000541a:	f406                	sd	ra,40(sp)
    8000541c:	f022                	sd	s0,32(sp)
    8000541e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005420:	fe840613          	addi	a2,s0,-24
    80005424:	4581                	li	a1,0
    80005426:	4501                	li	a0,0
    80005428:	00000097          	auipc	ra,0x0
    8000542c:	d8e080e7          	jalr	-626(ra) # 800051b6 <argfd>
    return -1;
    80005430:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005432:	04054163          	bltz	a0,80005474 <sys_read+0x5c>
    80005436:	fe440593          	addi	a1,s0,-28
    8000543a:	4509                	li	a0,2
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	822080e7          	jalr	-2014(ra) # 80002c5e <argint>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005446:	02054763          	bltz	a0,80005474 <sys_read+0x5c>
    8000544a:	fd840593          	addi	a1,s0,-40
    8000544e:	4505                	li	a0,1
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	830080e7          	jalr	-2000(ra) # 80002c80 <argaddr>
    return -1;
    80005458:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545a:	00054d63          	bltz	a0,80005474 <sys_read+0x5c>
  return fileread(f, p, n);
    8000545e:	fe442603          	lw	a2,-28(s0)
    80005462:	fd843583          	ld	a1,-40(s0)
    80005466:	fe843503          	ld	a0,-24(s0)
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	34c080e7          	jalr	844(ra) # 800047b6 <fileread>
    80005472:	87aa                	mv	a5,a0
}
    80005474:	853e                	mv	a0,a5
    80005476:	70a2                	ld	ra,40(sp)
    80005478:	7402                	ld	s0,32(sp)
    8000547a:	6145                	addi	sp,sp,48
    8000547c:	8082                	ret

000000008000547e <sys_write>:
{
    8000547e:	7179                	addi	sp,sp,-48
    80005480:	f406                	sd	ra,40(sp)
    80005482:	f022                	sd	s0,32(sp)
    80005484:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005486:	fe840613          	addi	a2,s0,-24
    8000548a:	4581                	li	a1,0
    8000548c:	4501                	li	a0,0
    8000548e:	00000097          	auipc	ra,0x0
    80005492:	d28080e7          	jalr	-728(ra) # 800051b6 <argfd>
    return -1;
    80005496:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005498:	04054163          	bltz	a0,800054da <sys_write+0x5c>
    8000549c:	fe440593          	addi	a1,s0,-28
    800054a0:	4509                	li	a0,2
    800054a2:	ffffd097          	auipc	ra,0xffffd
    800054a6:	7bc080e7          	jalr	1980(ra) # 80002c5e <argint>
    return -1;
    800054aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ac:	02054763          	bltz	a0,800054da <sys_write+0x5c>
    800054b0:	fd840593          	addi	a1,s0,-40
    800054b4:	4505                	li	a0,1
    800054b6:	ffffd097          	auipc	ra,0xffffd
    800054ba:	7ca080e7          	jalr	1994(ra) # 80002c80 <argaddr>
    return -1;
    800054be:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c0:	00054d63          	bltz	a0,800054da <sys_write+0x5c>
  return filewrite(f, p, n);
    800054c4:	fe442603          	lw	a2,-28(s0)
    800054c8:	fd843583          	ld	a1,-40(s0)
    800054cc:	fe843503          	ld	a0,-24(s0)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	3a8080e7          	jalr	936(ra) # 80004878 <filewrite>
    800054d8:	87aa                	mv	a5,a0
}
    800054da:	853e                	mv	a0,a5
    800054dc:	70a2                	ld	ra,40(sp)
    800054de:	7402                	ld	s0,32(sp)
    800054e0:	6145                	addi	sp,sp,48
    800054e2:	8082                	ret

00000000800054e4 <sys_close>:
{
    800054e4:	1101                	addi	sp,sp,-32
    800054e6:	ec06                	sd	ra,24(sp)
    800054e8:	e822                	sd	s0,16(sp)
    800054ea:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054ec:	fe040613          	addi	a2,s0,-32
    800054f0:	fec40593          	addi	a1,s0,-20
    800054f4:	4501                	li	a0,0
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	cc0080e7          	jalr	-832(ra) # 800051b6 <argfd>
    return -1;
    800054fe:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005500:	02054463          	bltz	a0,80005528 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005504:	ffffc097          	auipc	ra,0xffffc
    80005508:	5fc080e7          	jalr	1532(ra) # 80001b00 <myproc>
    8000550c:	fec42783          	lw	a5,-20(s0)
    80005510:	07e9                	addi	a5,a5,26
    80005512:	078e                	slli	a5,a5,0x3
    80005514:	953e                	add	a0,a0,a5
    80005516:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000551a:	fe043503          	ld	a0,-32(s0)
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	15e080e7          	jalr	350(ra) # 8000467c <fileclose>
  return 0;
    80005526:	4781                	li	a5,0
}
    80005528:	853e                	mv	a0,a5
    8000552a:	60e2                	ld	ra,24(sp)
    8000552c:	6442                	ld	s0,16(sp)
    8000552e:	6105                	addi	sp,sp,32
    80005530:	8082                	ret

0000000080005532 <sys_fstat>:
{
    80005532:	1101                	addi	sp,sp,-32
    80005534:	ec06                	sd	ra,24(sp)
    80005536:	e822                	sd	s0,16(sp)
    80005538:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000553a:	fe840613          	addi	a2,s0,-24
    8000553e:	4581                	li	a1,0
    80005540:	4501                	li	a0,0
    80005542:	00000097          	auipc	ra,0x0
    80005546:	c74080e7          	jalr	-908(ra) # 800051b6 <argfd>
    return -1;
    8000554a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000554c:	02054563          	bltz	a0,80005576 <sys_fstat+0x44>
    80005550:	fe040593          	addi	a1,s0,-32
    80005554:	4505                	li	a0,1
    80005556:	ffffd097          	auipc	ra,0xffffd
    8000555a:	72a080e7          	jalr	1834(ra) # 80002c80 <argaddr>
    return -1;
    8000555e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005560:	00054b63          	bltz	a0,80005576 <sys_fstat+0x44>
  return filestat(f, st);
    80005564:	fe043583          	ld	a1,-32(s0)
    80005568:	fe843503          	ld	a0,-24(s0)
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	1d8080e7          	jalr	472(ra) # 80004744 <filestat>
    80005574:	87aa                	mv	a5,a0
}
    80005576:	853e                	mv	a0,a5
    80005578:	60e2                	ld	ra,24(sp)
    8000557a:	6442                	ld	s0,16(sp)
    8000557c:	6105                	addi	sp,sp,32
    8000557e:	8082                	ret

0000000080005580 <sys_link>:
{
    80005580:	7169                	addi	sp,sp,-304
    80005582:	f606                	sd	ra,296(sp)
    80005584:	f222                	sd	s0,288(sp)
    80005586:	ee26                	sd	s1,280(sp)
    80005588:	ea4a                	sd	s2,272(sp)
    8000558a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000558c:	08000613          	li	a2,128
    80005590:	ed040593          	addi	a1,s0,-304
    80005594:	4501                	li	a0,0
    80005596:	ffffd097          	auipc	ra,0xffffd
    8000559a:	70c080e7          	jalr	1804(ra) # 80002ca2 <argstr>
    return -1;
    8000559e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a0:	10054e63          	bltz	a0,800056bc <sys_link+0x13c>
    800055a4:	08000613          	li	a2,128
    800055a8:	f5040593          	addi	a1,s0,-176
    800055ac:	4505                	li	a0,1
    800055ae:	ffffd097          	auipc	ra,0xffffd
    800055b2:	6f4080e7          	jalr	1780(ra) # 80002ca2 <argstr>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055b8:	10054263          	bltz	a0,800056bc <sys_link+0x13c>
  begin_op();
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	bf2080e7          	jalr	-1038(ra) # 800041ae <begin_op>
  if((ip = namei(old)) == 0){
    800055c4:	ed040513          	addi	a0,s0,-304
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	9d6080e7          	jalr	-1578(ra) # 80003f9e <namei>
    800055d0:	84aa                	mv	s1,a0
    800055d2:	c551                	beqz	a0,8000565e <sys_link+0xde>
  ilock(ip);
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	214080e7          	jalr	532(ra) # 800037e8 <ilock>
  if(ip->type == T_DIR){
    800055dc:	04449703          	lh	a4,68(s1)
    800055e0:	4785                	li	a5,1
    800055e2:	08f70463          	beq	a4,a5,8000566a <sys_link+0xea>
  ip->nlink++;
    800055e6:	04a4d783          	lhu	a5,74(s1)
    800055ea:	2785                	addiw	a5,a5,1
    800055ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055f0:	8526                	mv	a0,s1
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	12a080e7          	jalr	298(ra) # 8000371c <iupdate>
  iunlock(ip);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	2ae080e7          	jalr	686(ra) # 800038aa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005604:	fd040593          	addi	a1,s0,-48
    80005608:	f5040513          	addi	a0,s0,-176
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	9b0080e7          	jalr	-1616(ra) # 80003fbc <nameiparent>
    80005614:	892a                	mv	s2,a0
    80005616:	c935                	beqz	a0,8000568a <sys_link+0x10a>
  ilock(dp);
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	1d0080e7          	jalr	464(ra) # 800037e8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005620:	00092703          	lw	a4,0(s2)
    80005624:	409c                	lw	a5,0(s1)
    80005626:	04f71d63          	bne	a4,a5,80005680 <sys_link+0x100>
    8000562a:	40d0                	lw	a2,4(s1)
    8000562c:	fd040593          	addi	a1,s0,-48
    80005630:	854a                	mv	a0,s2
    80005632:	fffff097          	auipc	ra,0xfffff
    80005636:	8aa080e7          	jalr	-1878(ra) # 80003edc <dirlink>
    8000563a:	04054363          	bltz	a0,80005680 <sys_link+0x100>
  iunlockput(dp);
    8000563e:	854a                	mv	a0,s2
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	40a080e7          	jalr	1034(ra) # 80003a4a <iunlockput>
  iput(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	358080e7          	jalr	856(ra) # 800039a2 <iput>
  end_op();
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	bda080e7          	jalr	-1062(ra) # 8000422c <end_op>
  return 0;
    8000565a:	4781                	li	a5,0
    8000565c:	a085                	j	800056bc <sys_link+0x13c>
    end_op();
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	bce080e7          	jalr	-1074(ra) # 8000422c <end_op>
    return -1;
    80005666:	57fd                	li	a5,-1
    80005668:	a891                	j	800056bc <sys_link+0x13c>
    iunlockput(ip);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	3de080e7          	jalr	990(ra) # 80003a4a <iunlockput>
    end_op();
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	bb8080e7          	jalr	-1096(ra) # 8000422c <end_op>
    return -1;
    8000567c:	57fd                	li	a5,-1
    8000567e:	a83d                	j	800056bc <sys_link+0x13c>
    iunlockput(dp);
    80005680:	854a                	mv	a0,s2
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	3c8080e7          	jalr	968(ra) # 80003a4a <iunlockput>
  ilock(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	15c080e7          	jalr	348(ra) # 800037e8 <ilock>
  ip->nlink--;
    80005694:	04a4d783          	lhu	a5,74(s1)
    80005698:	37fd                	addiw	a5,a5,-1
    8000569a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000569e:	8526                	mv	a0,s1
    800056a0:	ffffe097          	auipc	ra,0xffffe
    800056a4:	07c080e7          	jalr	124(ra) # 8000371c <iupdate>
  iunlockput(ip);
    800056a8:	8526                	mv	a0,s1
    800056aa:	ffffe097          	auipc	ra,0xffffe
    800056ae:	3a0080e7          	jalr	928(ra) # 80003a4a <iunlockput>
  end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	b7a080e7          	jalr	-1158(ra) # 8000422c <end_op>
  return -1;
    800056ba:	57fd                	li	a5,-1
}
    800056bc:	853e                	mv	a0,a5
    800056be:	70b2                	ld	ra,296(sp)
    800056c0:	7412                	ld	s0,288(sp)
    800056c2:	64f2                	ld	s1,280(sp)
    800056c4:	6952                	ld	s2,272(sp)
    800056c6:	6155                	addi	sp,sp,304
    800056c8:	8082                	ret

00000000800056ca <sys_unlink>:
{
    800056ca:	7151                	addi	sp,sp,-240
    800056cc:	f586                	sd	ra,232(sp)
    800056ce:	f1a2                	sd	s0,224(sp)
    800056d0:	eda6                	sd	s1,216(sp)
    800056d2:	e9ca                	sd	s2,208(sp)
    800056d4:	e5ce                	sd	s3,200(sp)
    800056d6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056d8:	08000613          	li	a2,128
    800056dc:	f3040593          	addi	a1,s0,-208
    800056e0:	4501                	li	a0,0
    800056e2:	ffffd097          	auipc	ra,0xffffd
    800056e6:	5c0080e7          	jalr	1472(ra) # 80002ca2 <argstr>
    800056ea:	18054163          	bltz	a0,8000586c <sys_unlink+0x1a2>
  begin_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	ac0080e7          	jalr	-1344(ra) # 800041ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056f6:	fb040593          	addi	a1,s0,-80
    800056fa:	f3040513          	addi	a0,s0,-208
    800056fe:	fffff097          	auipc	ra,0xfffff
    80005702:	8be080e7          	jalr	-1858(ra) # 80003fbc <nameiparent>
    80005706:	84aa                	mv	s1,a0
    80005708:	c979                	beqz	a0,800057de <sys_unlink+0x114>
  ilock(dp);
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	0de080e7          	jalr	222(ra) # 800037e8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005712:	00003597          	auipc	a1,0x3
    80005716:	03e58593          	addi	a1,a1,62 # 80008750 <syscalls+0x328>
    8000571a:	fb040513          	addi	a0,s0,-80
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	58e080e7          	jalr	1422(ra) # 80003cac <namecmp>
    80005726:	14050a63          	beqz	a0,8000587a <sys_unlink+0x1b0>
    8000572a:	00003597          	auipc	a1,0x3
    8000572e:	02e58593          	addi	a1,a1,46 # 80008758 <syscalls+0x330>
    80005732:	fb040513          	addi	a0,s0,-80
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	576080e7          	jalr	1398(ra) # 80003cac <namecmp>
    8000573e:	12050e63          	beqz	a0,8000587a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005742:	f2c40613          	addi	a2,s0,-212
    80005746:	fb040593          	addi	a1,s0,-80
    8000574a:	8526                	mv	a0,s1
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	57a080e7          	jalr	1402(ra) # 80003cc6 <dirlookup>
    80005754:	892a                	mv	s2,a0
    80005756:	12050263          	beqz	a0,8000587a <sys_unlink+0x1b0>
  ilock(ip);
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	08e080e7          	jalr	142(ra) # 800037e8 <ilock>
  if(ip->nlink < 1)
    80005762:	04a91783          	lh	a5,74(s2)
    80005766:	08f05263          	blez	a5,800057ea <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000576a:	04491703          	lh	a4,68(s2)
    8000576e:	4785                	li	a5,1
    80005770:	08f70563          	beq	a4,a5,800057fa <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005774:	4641                	li	a2,16
    80005776:	4581                	li	a1,0
    80005778:	fc040513          	addi	a0,s0,-64
    8000577c:	ffffb097          	auipc	ra,0xffffb
    80005780:	580080e7          	jalr	1408(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005784:	4741                	li	a4,16
    80005786:	f2c42683          	lw	a3,-212(s0)
    8000578a:	fc040613          	addi	a2,s0,-64
    8000578e:	4581                	li	a1,0
    80005790:	8526                	mv	a0,s1
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	400080e7          	jalr	1024(ra) # 80003b92 <writei>
    8000579a:	47c1                	li	a5,16
    8000579c:	0af51563          	bne	a0,a5,80005846 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057a0:	04491703          	lh	a4,68(s2)
    800057a4:	4785                	li	a5,1
    800057a6:	0af70863          	beq	a4,a5,80005856 <sys_unlink+0x18c>
  iunlockput(dp);
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	29e080e7          	jalr	670(ra) # 80003a4a <iunlockput>
  ip->nlink--;
    800057b4:	04a95783          	lhu	a5,74(s2)
    800057b8:	37fd                	addiw	a5,a5,-1
    800057ba:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	f5c080e7          	jalr	-164(ra) # 8000371c <iupdate>
  iunlockput(ip);
    800057c8:	854a                	mv	a0,s2
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	280080e7          	jalr	640(ra) # 80003a4a <iunlockput>
  end_op();
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	a5a080e7          	jalr	-1446(ra) # 8000422c <end_op>
  return 0;
    800057da:	4501                	li	a0,0
    800057dc:	a84d                	j	8000588e <sys_unlink+0x1c4>
    end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	a4e080e7          	jalr	-1458(ra) # 8000422c <end_op>
    return -1;
    800057e6:	557d                	li	a0,-1
    800057e8:	a05d                	j	8000588e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057ea:	00003517          	auipc	a0,0x3
    800057ee:	f9650513          	addi	a0,a0,-106 # 80008780 <syscalls+0x358>
    800057f2:	ffffb097          	auipc	ra,0xffffb
    800057f6:	d54080e7          	jalr	-684(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057fa:	04c92703          	lw	a4,76(s2)
    800057fe:	02000793          	li	a5,32
    80005802:	f6e7f9e3          	bgeu	a5,a4,80005774 <sys_unlink+0xaa>
    80005806:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000580a:	4741                	li	a4,16
    8000580c:	86ce                	mv	a3,s3
    8000580e:	f1840613          	addi	a2,s0,-232
    80005812:	4581                	li	a1,0
    80005814:	854a                	mv	a0,s2
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	286080e7          	jalr	646(ra) # 80003a9c <readi>
    8000581e:	47c1                	li	a5,16
    80005820:	00f51b63          	bne	a0,a5,80005836 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005824:	f1845783          	lhu	a5,-232(s0)
    80005828:	e7a1                	bnez	a5,80005870 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000582a:	29c1                	addiw	s3,s3,16
    8000582c:	04c92783          	lw	a5,76(s2)
    80005830:	fcf9ede3          	bltu	s3,a5,8000580a <sys_unlink+0x140>
    80005834:	b781                	j	80005774 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005836:	00003517          	auipc	a0,0x3
    8000583a:	f6250513          	addi	a0,a0,-158 # 80008798 <syscalls+0x370>
    8000583e:	ffffb097          	auipc	ra,0xffffb
    80005842:	d08080e7          	jalr	-760(ra) # 80000546 <panic>
    panic("unlink: writei");
    80005846:	00003517          	auipc	a0,0x3
    8000584a:	f6a50513          	addi	a0,a0,-150 # 800087b0 <syscalls+0x388>
    8000584e:	ffffb097          	auipc	ra,0xffffb
    80005852:	cf8080e7          	jalr	-776(ra) # 80000546 <panic>
    dp->nlink--;
    80005856:	04a4d783          	lhu	a5,74(s1)
    8000585a:	37fd                	addiw	a5,a5,-1
    8000585c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	eba080e7          	jalr	-326(ra) # 8000371c <iupdate>
    8000586a:	b781                	j	800057aa <sys_unlink+0xe0>
    return -1;
    8000586c:	557d                	li	a0,-1
    8000586e:	a005                	j	8000588e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005870:	854a                	mv	a0,s2
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	1d8080e7          	jalr	472(ra) # 80003a4a <iunlockput>
  iunlockput(dp);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	1ce080e7          	jalr	462(ra) # 80003a4a <iunlockput>
  end_op();
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	9a8080e7          	jalr	-1624(ra) # 8000422c <end_op>
  return -1;
    8000588c:	557d                	li	a0,-1
}
    8000588e:	70ae                	ld	ra,232(sp)
    80005890:	740e                	ld	s0,224(sp)
    80005892:	64ee                	ld	s1,216(sp)
    80005894:	694e                	ld	s2,208(sp)
    80005896:	69ae                	ld	s3,200(sp)
    80005898:	616d                	addi	sp,sp,240
    8000589a:	8082                	ret

000000008000589c <sys_open>:

uint64
sys_open(void)
{
    8000589c:	7131                	addi	sp,sp,-192
    8000589e:	fd06                	sd	ra,184(sp)
    800058a0:	f922                	sd	s0,176(sp)
    800058a2:	f526                	sd	s1,168(sp)
    800058a4:	f14a                	sd	s2,160(sp)
    800058a6:	ed4e                	sd	s3,152(sp)
    800058a8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058aa:	08000613          	li	a2,128
    800058ae:	f5040593          	addi	a1,s0,-176
    800058b2:	4501                	li	a0,0
    800058b4:	ffffd097          	auipc	ra,0xffffd
    800058b8:	3ee080e7          	jalr	1006(ra) # 80002ca2 <argstr>
    return -1;
    800058bc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058be:	0c054163          	bltz	a0,80005980 <sys_open+0xe4>
    800058c2:	f4c40593          	addi	a1,s0,-180
    800058c6:	4505                	li	a0,1
    800058c8:	ffffd097          	auipc	ra,0xffffd
    800058cc:	396080e7          	jalr	918(ra) # 80002c5e <argint>
    800058d0:	0a054863          	bltz	a0,80005980 <sys_open+0xe4>

  begin_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	8da080e7          	jalr	-1830(ra) # 800041ae <begin_op>

  if(omode & O_CREATE){
    800058dc:	f4c42783          	lw	a5,-180(s0)
    800058e0:	2007f793          	andi	a5,a5,512
    800058e4:	cbdd                	beqz	a5,8000599a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058e6:	4681                	li	a3,0
    800058e8:	4601                	li	a2,0
    800058ea:	4589                	li	a1,2
    800058ec:	f5040513          	addi	a0,s0,-176
    800058f0:	00000097          	auipc	ra,0x0
    800058f4:	970080e7          	jalr	-1680(ra) # 80005260 <create>
    800058f8:	892a                	mv	s2,a0
    if(ip == 0){
    800058fa:	c959                	beqz	a0,80005990 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058fc:	04491703          	lh	a4,68(s2)
    80005900:	478d                	li	a5,3
    80005902:	00f71763          	bne	a4,a5,80005910 <sys_open+0x74>
    80005906:	04695703          	lhu	a4,70(s2)
    8000590a:	47a5                	li	a5,9
    8000590c:	0ce7ec63          	bltu	a5,a4,800059e4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	cb0080e7          	jalr	-848(ra) # 800045c0 <filealloc>
    80005918:	89aa                	mv	s3,a0
    8000591a:	10050263          	beqz	a0,80005a1e <sys_open+0x182>
    8000591e:	00000097          	auipc	ra,0x0
    80005922:	900080e7          	jalr	-1792(ra) # 8000521e <fdalloc>
    80005926:	84aa                	mv	s1,a0
    80005928:	0e054663          	bltz	a0,80005a14 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000592c:	04491703          	lh	a4,68(s2)
    80005930:	478d                	li	a5,3
    80005932:	0cf70463          	beq	a4,a5,800059fa <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005936:	4789                	li	a5,2
    80005938:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000593c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005940:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005944:	f4c42783          	lw	a5,-180(s0)
    80005948:	0017c713          	xori	a4,a5,1
    8000594c:	8b05                	andi	a4,a4,1
    8000594e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005952:	0037f713          	andi	a4,a5,3
    80005956:	00e03733          	snez	a4,a4
    8000595a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000595e:	4007f793          	andi	a5,a5,1024
    80005962:	c791                	beqz	a5,8000596e <sys_open+0xd2>
    80005964:	04491703          	lh	a4,68(s2)
    80005968:	4789                	li	a5,2
    8000596a:	08f70f63          	beq	a4,a5,80005a08 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000596e:	854a                	mv	a0,s2
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	f3a080e7          	jalr	-198(ra) # 800038aa <iunlock>
  end_op();
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	8b4080e7          	jalr	-1868(ra) # 8000422c <end_op>

  return fd;
}
    80005980:	8526                	mv	a0,s1
    80005982:	70ea                	ld	ra,184(sp)
    80005984:	744a                	ld	s0,176(sp)
    80005986:	74aa                	ld	s1,168(sp)
    80005988:	790a                	ld	s2,160(sp)
    8000598a:	69ea                	ld	s3,152(sp)
    8000598c:	6129                	addi	sp,sp,192
    8000598e:	8082                	ret
      end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	89c080e7          	jalr	-1892(ra) # 8000422c <end_op>
      return -1;
    80005998:	b7e5                	j	80005980 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000599a:	f5040513          	addi	a0,s0,-176
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	600080e7          	jalr	1536(ra) # 80003f9e <namei>
    800059a6:	892a                	mv	s2,a0
    800059a8:	c905                	beqz	a0,800059d8 <sys_open+0x13c>
    ilock(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	e3e080e7          	jalr	-450(ra) # 800037e8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059b2:	04491703          	lh	a4,68(s2)
    800059b6:	4785                	li	a5,1
    800059b8:	f4f712e3          	bne	a4,a5,800058fc <sys_open+0x60>
    800059bc:	f4c42783          	lw	a5,-180(s0)
    800059c0:	dba1                	beqz	a5,80005910 <sys_open+0x74>
      iunlockput(ip);
    800059c2:	854a                	mv	a0,s2
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	086080e7          	jalr	134(ra) # 80003a4a <iunlockput>
      end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	860080e7          	jalr	-1952(ra) # 8000422c <end_op>
      return -1;
    800059d4:	54fd                	li	s1,-1
    800059d6:	b76d                	j	80005980 <sys_open+0xe4>
      end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	854080e7          	jalr	-1964(ra) # 8000422c <end_op>
      return -1;
    800059e0:	54fd                	li	s1,-1
    800059e2:	bf79                	j	80005980 <sys_open+0xe4>
    iunlockput(ip);
    800059e4:	854a                	mv	a0,s2
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	064080e7          	jalr	100(ra) # 80003a4a <iunlockput>
    end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	83e080e7          	jalr	-1986(ra) # 8000422c <end_op>
    return -1;
    800059f6:	54fd                	li	s1,-1
    800059f8:	b761                	j	80005980 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059fa:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059fe:	04691783          	lh	a5,70(s2)
    80005a02:	02f99223          	sh	a5,36(s3)
    80005a06:	bf2d                	j	80005940 <sys_open+0xa4>
    itrunc(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	eec080e7          	jalr	-276(ra) # 800038f6 <itrunc>
    80005a12:	bfb1                	j	8000596e <sys_open+0xd2>
      fileclose(f);
    80005a14:	854e                	mv	a0,s3
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	c66080e7          	jalr	-922(ra) # 8000467c <fileclose>
    iunlockput(ip);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	02a080e7          	jalr	42(ra) # 80003a4a <iunlockput>
    end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	804080e7          	jalr	-2044(ra) # 8000422c <end_op>
    return -1;
    80005a30:	54fd                	li	s1,-1
    80005a32:	b7b9                	j	80005980 <sys_open+0xe4>

0000000080005a34 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a34:	7175                	addi	sp,sp,-144
    80005a36:	e506                	sd	ra,136(sp)
    80005a38:	e122                	sd	s0,128(sp)
    80005a3a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	772080e7          	jalr	1906(ra) # 800041ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a44:	08000613          	li	a2,128
    80005a48:	f7040593          	addi	a1,s0,-144
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	254080e7          	jalr	596(ra) # 80002ca2 <argstr>
    80005a56:	02054963          	bltz	a0,80005a88 <sys_mkdir+0x54>
    80005a5a:	4681                	li	a3,0
    80005a5c:	4601                	li	a2,0
    80005a5e:	4585                	li	a1,1
    80005a60:	f7040513          	addi	a0,s0,-144
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	7fc080e7          	jalr	2044(ra) # 80005260 <create>
    80005a6c:	cd11                	beqz	a0,80005a88 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	fdc080e7          	jalr	-36(ra) # 80003a4a <iunlockput>
  end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	7b6080e7          	jalr	1974(ra) # 8000422c <end_op>
  return 0;
    80005a7e:	4501                	li	a0,0
}
    80005a80:	60aa                	ld	ra,136(sp)
    80005a82:	640a                	ld	s0,128(sp)
    80005a84:	6149                	addi	sp,sp,144
    80005a86:	8082                	ret
    end_op();
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	7a4080e7          	jalr	1956(ra) # 8000422c <end_op>
    return -1;
    80005a90:	557d                	li	a0,-1
    80005a92:	b7fd                	j	80005a80 <sys_mkdir+0x4c>

0000000080005a94 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a94:	7135                	addi	sp,sp,-160
    80005a96:	ed06                	sd	ra,152(sp)
    80005a98:	e922                	sd	s0,144(sp)
    80005a9a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	712080e7          	jalr	1810(ra) # 800041ae <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005aa4:	08000613          	li	a2,128
    80005aa8:	f7040593          	addi	a1,s0,-144
    80005aac:	4501                	li	a0,0
    80005aae:	ffffd097          	auipc	ra,0xffffd
    80005ab2:	1f4080e7          	jalr	500(ra) # 80002ca2 <argstr>
    80005ab6:	04054a63          	bltz	a0,80005b0a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005aba:	f6c40593          	addi	a1,s0,-148
    80005abe:	4505                	li	a0,1
    80005ac0:	ffffd097          	auipc	ra,0xffffd
    80005ac4:	19e080e7          	jalr	414(ra) # 80002c5e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ac8:	04054163          	bltz	a0,80005b0a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005acc:	f6840593          	addi	a1,s0,-152
    80005ad0:	4509                	li	a0,2
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	18c080e7          	jalr	396(ra) # 80002c5e <argint>
     argint(1, &major) < 0 ||
    80005ada:	02054863          	bltz	a0,80005b0a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ade:	f6841683          	lh	a3,-152(s0)
    80005ae2:	f6c41603          	lh	a2,-148(s0)
    80005ae6:	458d                	li	a1,3
    80005ae8:	f7040513          	addi	a0,s0,-144
    80005aec:	fffff097          	auipc	ra,0xfffff
    80005af0:	774080e7          	jalr	1908(ra) # 80005260 <create>
     argint(2, &minor) < 0 ||
    80005af4:	c919                	beqz	a0,80005b0a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	f54080e7          	jalr	-172(ra) # 80003a4a <iunlockput>
  end_op();
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	72e080e7          	jalr	1838(ra) # 8000422c <end_op>
  return 0;
    80005b06:	4501                	li	a0,0
    80005b08:	a031                	j	80005b14 <sys_mknod+0x80>
    end_op();
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	722080e7          	jalr	1826(ra) # 8000422c <end_op>
    return -1;
    80005b12:	557d                	li	a0,-1
}
    80005b14:	60ea                	ld	ra,152(sp)
    80005b16:	644a                	ld	s0,144(sp)
    80005b18:	610d                	addi	sp,sp,160
    80005b1a:	8082                	ret

0000000080005b1c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b1c:	7135                	addi	sp,sp,-160
    80005b1e:	ed06                	sd	ra,152(sp)
    80005b20:	e922                	sd	s0,144(sp)
    80005b22:	e526                	sd	s1,136(sp)
    80005b24:	e14a                	sd	s2,128(sp)
    80005b26:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b28:	ffffc097          	auipc	ra,0xffffc
    80005b2c:	fd8080e7          	jalr	-40(ra) # 80001b00 <myproc>
    80005b30:	892a                	mv	s2,a0
  
  begin_op();
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	67c080e7          	jalr	1660(ra) # 800041ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b3a:	08000613          	li	a2,128
    80005b3e:	f6040593          	addi	a1,s0,-160
    80005b42:	4501                	li	a0,0
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	15e080e7          	jalr	350(ra) # 80002ca2 <argstr>
    80005b4c:	04054b63          	bltz	a0,80005ba2 <sys_chdir+0x86>
    80005b50:	f6040513          	addi	a0,s0,-160
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	44a080e7          	jalr	1098(ra) # 80003f9e <namei>
    80005b5c:	84aa                	mv	s1,a0
    80005b5e:	c131                	beqz	a0,80005ba2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	c88080e7          	jalr	-888(ra) # 800037e8 <ilock>
  if(ip->type != T_DIR){
    80005b68:	04449703          	lh	a4,68(s1)
    80005b6c:	4785                	li	a5,1
    80005b6e:	04f71063          	bne	a4,a5,80005bae <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	d36080e7          	jalr	-714(ra) # 800038aa <iunlock>
  iput(p->cwd);
    80005b7c:	15093503          	ld	a0,336(s2)
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	e22080e7          	jalr	-478(ra) # 800039a2 <iput>
  end_op();
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	6a4080e7          	jalr	1700(ra) # 8000422c <end_op>
  p->cwd = ip;
    80005b90:	14993823          	sd	s1,336(s2)
  return 0;
    80005b94:	4501                	li	a0,0
}
    80005b96:	60ea                	ld	ra,152(sp)
    80005b98:	644a                	ld	s0,144(sp)
    80005b9a:	64aa                	ld	s1,136(sp)
    80005b9c:	690a                	ld	s2,128(sp)
    80005b9e:	610d                	addi	sp,sp,160
    80005ba0:	8082                	ret
    end_op();
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	68a080e7          	jalr	1674(ra) # 8000422c <end_op>
    return -1;
    80005baa:	557d                	li	a0,-1
    80005bac:	b7ed                	j	80005b96 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	e9a080e7          	jalr	-358(ra) # 80003a4a <iunlockput>
    end_op();
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	674080e7          	jalr	1652(ra) # 8000422c <end_op>
    return -1;
    80005bc0:	557d                	li	a0,-1
    80005bc2:	bfd1                	j	80005b96 <sys_chdir+0x7a>

0000000080005bc4 <sys_exec>:

uint64
sys_exec(void)
{
    80005bc4:	7145                	addi	sp,sp,-464
    80005bc6:	e786                	sd	ra,456(sp)
    80005bc8:	e3a2                	sd	s0,448(sp)
    80005bca:	ff26                	sd	s1,440(sp)
    80005bcc:	fb4a                	sd	s2,432(sp)
    80005bce:	f74e                	sd	s3,424(sp)
    80005bd0:	f352                	sd	s4,416(sp)
    80005bd2:	ef56                	sd	s5,408(sp)
    80005bd4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bd6:	08000613          	li	a2,128
    80005bda:	f4040593          	addi	a1,s0,-192
    80005bde:	4501                	li	a0,0
    80005be0:	ffffd097          	auipc	ra,0xffffd
    80005be4:	0c2080e7          	jalr	194(ra) # 80002ca2 <argstr>
    return -1;
    80005be8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bea:	0c054b63          	bltz	a0,80005cc0 <sys_exec+0xfc>
    80005bee:	e3840593          	addi	a1,s0,-456
    80005bf2:	4505                	li	a0,1
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	08c080e7          	jalr	140(ra) # 80002c80 <argaddr>
    80005bfc:	0c054263          	bltz	a0,80005cc0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c00:	10000613          	li	a2,256
    80005c04:	4581                	li	a1,0
    80005c06:	e4040513          	addi	a0,s0,-448
    80005c0a:	ffffb097          	auipc	ra,0xffffb
    80005c0e:	0f2080e7          	jalr	242(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c12:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c16:	89a6                	mv	s3,s1
    80005c18:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c1a:	02000a13          	li	s4,32
    80005c1e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c22:	00391513          	slli	a0,s2,0x3
    80005c26:	e3040593          	addi	a1,s0,-464
    80005c2a:	e3843783          	ld	a5,-456(s0)
    80005c2e:	953e                	add	a0,a0,a5
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	f94080e7          	jalr	-108(ra) # 80002bc4 <fetchaddr>
    80005c38:	02054a63          	bltz	a0,80005c6c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c3c:	e3043783          	ld	a5,-464(s0)
    80005c40:	c3b9                	beqz	a5,80005c86 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c42:	ffffb097          	auipc	ra,0xffffb
    80005c46:	ece080e7          	jalr	-306(ra) # 80000b10 <kalloc>
    80005c4a:	85aa                	mv	a1,a0
    80005c4c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c50:	cd11                	beqz	a0,80005c6c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c52:	6605                	lui	a2,0x1
    80005c54:	e3043503          	ld	a0,-464(s0)
    80005c58:	ffffd097          	auipc	ra,0xffffd
    80005c5c:	fbe080e7          	jalr	-66(ra) # 80002c16 <fetchstr>
    80005c60:	00054663          	bltz	a0,80005c6c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c64:	0905                	addi	s2,s2,1
    80005c66:	09a1                	addi	s3,s3,8
    80005c68:	fb491be3          	bne	s2,s4,80005c1e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c6c:	f4040913          	addi	s2,s0,-192
    80005c70:	6088                	ld	a0,0(s1)
    80005c72:	c531                	beqz	a0,80005cbe <sys_exec+0xfa>
    kfree(argv[i]);
    80005c74:	ffffb097          	auipc	ra,0xffffb
    80005c78:	d9e080e7          	jalr	-610(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	04a1                	addi	s1,s1,8
    80005c7e:	ff2499e3          	bne	s1,s2,80005c70 <sys_exec+0xac>
  return -1;
    80005c82:	597d                	li	s2,-1
    80005c84:	a835                	j	80005cc0 <sys_exec+0xfc>
      argv[i] = 0;
    80005c86:	0a8e                	slli	s5,s5,0x3
    80005c88:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd7fa0>
    80005c8c:	00878ab3          	add	s5,a5,s0
    80005c90:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c94:	e4040593          	addi	a1,s0,-448
    80005c98:	f4040513          	addi	a0,s0,-192
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	15a080e7          	jalr	346(ra) # 80004df6 <exec>
    80005ca4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca6:	f4040993          	addi	s3,s0,-192
    80005caa:	6088                	ld	a0,0(s1)
    80005cac:	c911                	beqz	a0,80005cc0 <sys_exec+0xfc>
    kfree(argv[i]);
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	d64080e7          	jalr	-668(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb6:	04a1                	addi	s1,s1,8
    80005cb8:	ff3499e3          	bne	s1,s3,80005caa <sys_exec+0xe6>
    80005cbc:	a011                	j	80005cc0 <sys_exec+0xfc>
  return -1;
    80005cbe:	597d                	li	s2,-1
}
    80005cc0:	854a                	mv	a0,s2
    80005cc2:	60be                	ld	ra,456(sp)
    80005cc4:	641e                	ld	s0,448(sp)
    80005cc6:	74fa                	ld	s1,440(sp)
    80005cc8:	795a                	ld	s2,432(sp)
    80005cca:	79ba                	ld	s3,424(sp)
    80005ccc:	7a1a                	ld	s4,416(sp)
    80005cce:	6afa                	ld	s5,408(sp)
    80005cd0:	6179                	addi	sp,sp,464
    80005cd2:	8082                	ret

0000000080005cd4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005cd4:	7139                	addi	sp,sp,-64
    80005cd6:	fc06                	sd	ra,56(sp)
    80005cd8:	f822                	sd	s0,48(sp)
    80005cda:	f426                	sd	s1,40(sp)
    80005cdc:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cde:	ffffc097          	auipc	ra,0xffffc
    80005ce2:	e22080e7          	jalr	-478(ra) # 80001b00 <myproc>
    80005ce6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ce8:	fd840593          	addi	a1,s0,-40
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	f92080e7          	jalr	-110(ra) # 80002c80 <argaddr>
    return -1;
    80005cf6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cf8:	0e054063          	bltz	a0,80005dd8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cfc:	fc840593          	addi	a1,s0,-56
    80005d00:	fd040513          	addi	a0,s0,-48
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	cce080e7          	jalr	-818(ra) # 800049d2 <pipealloc>
    return -1;
    80005d0c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d0e:	0c054563          	bltz	a0,80005dd8 <sys_pipe+0x104>
  fd0 = -1;
    80005d12:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d16:	fd043503          	ld	a0,-48(s0)
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	504080e7          	jalr	1284(ra) # 8000521e <fdalloc>
    80005d22:	fca42223          	sw	a0,-60(s0)
    80005d26:	08054c63          	bltz	a0,80005dbe <sys_pipe+0xea>
    80005d2a:	fc843503          	ld	a0,-56(s0)
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	4f0080e7          	jalr	1264(ra) # 8000521e <fdalloc>
    80005d36:	fca42023          	sw	a0,-64(s0)
    80005d3a:	06054963          	bltz	a0,80005dac <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d3e:	4691                	li	a3,4
    80005d40:	fc440613          	addi	a2,s0,-60
    80005d44:	fd843583          	ld	a1,-40(s0)
    80005d48:	68a8                	ld	a0,80(s1)
    80005d4a:	ffffc097          	auipc	ra,0xffffc
    80005d4e:	a7c080e7          	jalr	-1412(ra) # 800017c6 <copyout>
    80005d52:	02054063          	bltz	a0,80005d72 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d56:	4691                	li	a3,4
    80005d58:	fc040613          	addi	a2,s0,-64
    80005d5c:	fd843583          	ld	a1,-40(s0)
    80005d60:	0591                	addi	a1,a1,4
    80005d62:	68a8                	ld	a0,80(s1)
    80005d64:	ffffc097          	auipc	ra,0xffffc
    80005d68:	a62080e7          	jalr	-1438(ra) # 800017c6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d6c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d6e:	06055563          	bgez	a0,80005dd8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d72:	fc442783          	lw	a5,-60(s0)
    80005d76:	07e9                	addi	a5,a5,26
    80005d78:	078e                	slli	a5,a5,0x3
    80005d7a:	97a6                	add	a5,a5,s1
    80005d7c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d80:	fc042783          	lw	a5,-64(s0)
    80005d84:	07e9                	addi	a5,a5,26
    80005d86:	078e                	slli	a5,a5,0x3
    80005d88:	00f48533          	add	a0,s1,a5
    80005d8c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d90:	fd043503          	ld	a0,-48(s0)
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	8e8080e7          	jalr	-1816(ra) # 8000467c <fileclose>
    fileclose(wf);
    80005d9c:	fc843503          	ld	a0,-56(s0)
    80005da0:	fffff097          	auipc	ra,0xfffff
    80005da4:	8dc080e7          	jalr	-1828(ra) # 8000467c <fileclose>
    return -1;
    80005da8:	57fd                	li	a5,-1
    80005daa:	a03d                	j	80005dd8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005dac:	fc442783          	lw	a5,-60(s0)
    80005db0:	0007c763          	bltz	a5,80005dbe <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005db4:	07e9                	addi	a5,a5,26
    80005db6:	078e                	slli	a5,a5,0x3
    80005db8:	97a6                	add	a5,a5,s1
    80005dba:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005dbe:	fd043503          	ld	a0,-48(s0)
    80005dc2:	fffff097          	auipc	ra,0xfffff
    80005dc6:	8ba080e7          	jalr	-1862(ra) # 8000467c <fileclose>
    fileclose(wf);
    80005dca:	fc843503          	ld	a0,-56(s0)
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	8ae080e7          	jalr	-1874(ra) # 8000467c <fileclose>
    return -1;
    80005dd6:	57fd                	li	a5,-1
}
    80005dd8:	853e                	mv	a0,a5
    80005dda:	70e2                	ld	ra,56(sp)
    80005ddc:	7442                	ld	s0,48(sp)
    80005dde:	74a2                	ld	s1,40(sp)
    80005de0:	6121                	addi	sp,sp,64
    80005de2:	8082                	ret
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	c61fc0ef          	jal	ra,80002a90 <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	710c                	ld	a1,32(a0)
    80005e8c:	7510                	ld	a2,40(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	c0c080e7          	jalr	-1012(ra) # 80001ad4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	97aa                	add	a5,a5,a0
    80005eec:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	bd4080e7          	jalr	-1068(ra) # 80001ad4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5151b          	slliw	a0,a0,0xd
    80005f0c:	0c2017b7          	lui	a5,0xc201
    80005f10:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f12:	43c8                	lw	a0,4(a5)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	bac080e7          	jalr	-1108(ra) # 80001ad4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cb63          	blt	a5,a0,80005fa6 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f54:	0001d717          	auipc	a4,0x1d
    80005f58:	0ac70713          	addi	a4,a4,172 # 80023000 <disk>
    80005f5c:	972a                	add	a4,a4,a0
    80005f5e:	6789                	lui	a5,0x2
    80005f60:	97ba                	add	a5,a5,a4
    80005f62:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f66:	eba1                	bnez	a5,80005fb6 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f68:	00451713          	slli	a4,a0,0x4
    80005f6c:	0001f797          	auipc	a5,0x1f
    80005f70:	0947b783          	ld	a5,148(a5) # 80025000 <disk+0x2000>
    80005f74:	97ba                	add	a5,a5,a4
    80005f76:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f7a:	0001d717          	auipc	a4,0x1d
    80005f7e:	08670713          	addi	a4,a4,134 # 80023000 <disk>
    80005f82:	972a                	add	a4,a4,a0
    80005f84:	6789                	lui	a5,0x2
    80005f86:	97ba                	add	a5,a5,a4
    80005f88:	4705                	li	a4,1
    80005f8a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f8e:	0001f517          	auipc	a0,0x1f
    80005f92:	08a50513          	addi	a0,a0,138 # 80025018 <disk+0x2018>
    80005f96:	ffffc097          	auipc	ra,0xffffc
    80005f9a:	5a0080e7          	jalr	1440(ra) # 80002536 <wakeup>
}
    80005f9e:	60a2                	ld	ra,8(sp)
    80005fa0:	6402                	ld	s0,0(sp)
    80005fa2:	0141                	addi	sp,sp,16
    80005fa4:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fa6:	00003517          	auipc	a0,0x3
    80005faa:	81a50513          	addi	a0,a0,-2022 # 800087c0 <syscalls+0x398>
    80005fae:	ffffa097          	auipc	ra,0xffffa
    80005fb2:	598080e7          	jalr	1432(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005fb6:	00003517          	auipc	a0,0x3
    80005fba:	82250513          	addi	a0,a0,-2014 # 800087d8 <syscalls+0x3b0>
    80005fbe:	ffffa097          	auipc	ra,0xffffa
    80005fc2:	588080e7          	jalr	1416(ra) # 80000546 <panic>

0000000080005fc6 <virtio_disk_init>:
{
    80005fc6:	1101                	addi	sp,sp,-32
    80005fc8:	ec06                	sd	ra,24(sp)
    80005fca:	e822                	sd	s0,16(sp)
    80005fcc:	e426                	sd	s1,8(sp)
    80005fce:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd0:	00003597          	auipc	a1,0x3
    80005fd4:	82058593          	addi	a1,a1,-2016 # 800087f0 <syscalls+0x3c8>
    80005fd8:	0001f517          	auipc	a0,0x1f
    80005fdc:	0d050513          	addi	a0,a0,208 # 800250a8 <disk+0x20a8>
    80005fe0:	ffffb097          	auipc	ra,0xffffb
    80005fe4:	b90080e7          	jalr	-1136(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fe8:	100017b7          	lui	a5,0x10001
    80005fec:	4398                	lw	a4,0(a5)
    80005fee:	2701                	sext.w	a4,a4
    80005ff0:	747277b7          	lui	a5,0x74727
    80005ff4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ff8:	0ef71063          	bne	a4,a5,800060d8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ffc:	100017b7          	lui	a5,0x10001
    80006000:	43dc                	lw	a5,4(a5)
    80006002:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006004:	4705                	li	a4,1
    80006006:	0ce79963          	bne	a5,a4,800060d8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600a:	100017b7          	lui	a5,0x10001
    8000600e:	479c                	lw	a5,8(a5)
    80006010:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006012:	4709                	li	a4,2
    80006014:	0ce79263          	bne	a5,a4,800060d8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006018:	100017b7          	lui	a5,0x10001
    8000601c:	47d8                	lw	a4,12(a5)
    8000601e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006020:	554d47b7          	lui	a5,0x554d4
    80006024:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006028:	0af71863          	bne	a4,a5,800060d8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602c:	100017b7          	lui	a5,0x10001
    80006030:	4705                	li	a4,1
    80006032:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006034:	470d                	li	a4,3
    80006036:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006038:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000603a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000603e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006042:	8f75                	and	a4,a4,a3
    80006044:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006046:	472d                	li	a4,11
    80006048:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604a:	473d                	li	a4,15
    8000604c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000604e:	6705                	lui	a4,0x1
    80006050:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006052:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006056:	5bdc                	lw	a5,52(a5)
    80006058:	2781                	sext.w	a5,a5
  if(max == 0)
    8000605a:	c7d9                	beqz	a5,800060e8 <virtio_disk_init+0x122>
  if(max < NUM)
    8000605c:	471d                	li	a4,7
    8000605e:	08f77d63          	bgeu	a4,a5,800060f8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006062:	100014b7          	lui	s1,0x10001
    80006066:	47a1                	li	a5,8
    80006068:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000606a:	6609                	lui	a2,0x2
    8000606c:	4581                	li	a1,0
    8000606e:	0001d517          	auipc	a0,0x1d
    80006072:	f9250513          	addi	a0,a0,-110 # 80023000 <disk>
    80006076:	ffffb097          	auipc	ra,0xffffb
    8000607a:	c86080e7          	jalr	-890(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000607e:	0001d717          	auipc	a4,0x1d
    80006082:	f8270713          	addi	a4,a4,-126 # 80023000 <disk>
    80006086:	00c75793          	srli	a5,a4,0xc
    8000608a:	2781                	sext.w	a5,a5
    8000608c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    8000608e:	0001f797          	auipc	a5,0x1f
    80006092:	f7278793          	addi	a5,a5,-142 # 80025000 <disk+0x2000>
    80006096:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80006098:	0001d717          	auipc	a4,0x1d
    8000609c:	fe870713          	addi	a4,a4,-24 # 80023080 <disk+0x80>
    800060a0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060a2:	0001e717          	auipc	a4,0x1e
    800060a6:	f5e70713          	addi	a4,a4,-162 # 80024000 <disk+0x1000>
    800060aa:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060ac:	4705                	li	a4,1
    800060ae:	00e78c23          	sb	a4,24(a5)
    800060b2:	00e78ca3          	sb	a4,25(a5)
    800060b6:	00e78d23          	sb	a4,26(a5)
    800060ba:	00e78da3          	sb	a4,27(a5)
    800060be:	00e78e23          	sb	a4,28(a5)
    800060c2:	00e78ea3          	sb	a4,29(a5)
    800060c6:	00e78f23          	sb	a4,30(a5)
    800060ca:	00e78fa3          	sb	a4,31(a5)
}
    800060ce:	60e2                	ld	ra,24(sp)
    800060d0:	6442                	ld	s0,16(sp)
    800060d2:	64a2                	ld	s1,8(sp)
    800060d4:	6105                	addi	sp,sp,32
    800060d6:	8082                	ret
    panic("could not find virtio disk");
    800060d8:	00002517          	auipc	a0,0x2
    800060dc:	72850513          	addi	a0,a0,1832 # 80008800 <syscalls+0x3d8>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	466080e7          	jalr	1126(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    800060e8:	00002517          	auipc	a0,0x2
    800060ec:	73850513          	addi	a0,a0,1848 # 80008820 <syscalls+0x3f8>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	456080e7          	jalr	1110(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    800060f8:	00002517          	auipc	a0,0x2
    800060fc:	74850513          	addi	a0,a0,1864 # 80008840 <syscalls+0x418>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	446080e7          	jalr	1094(ra) # 80000546 <panic>

0000000080006108 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006108:	7175                	addi	sp,sp,-144
    8000610a:	e506                	sd	ra,136(sp)
    8000610c:	e122                	sd	s0,128(sp)
    8000610e:	fca6                	sd	s1,120(sp)
    80006110:	f8ca                	sd	s2,112(sp)
    80006112:	f4ce                	sd	s3,104(sp)
    80006114:	f0d2                	sd	s4,96(sp)
    80006116:	ecd6                	sd	s5,88(sp)
    80006118:	e8da                	sd	s6,80(sp)
    8000611a:	e4de                	sd	s7,72(sp)
    8000611c:	e0e2                	sd	s8,64(sp)
    8000611e:	fc66                	sd	s9,56(sp)
    80006120:	f86a                	sd	s10,48(sp)
    80006122:	f46e                	sd	s11,40(sp)
    80006124:	0900                	addi	s0,sp,144
    80006126:	8aaa                	mv	s5,a0
    80006128:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000612a:	00c52c83          	lw	s9,12(a0)
    8000612e:	001c9c9b          	slliw	s9,s9,0x1
    80006132:	1c82                	slli	s9,s9,0x20
    80006134:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006138:	0001f517          	auipc	a0,0x1f
    8000613c:	f7050513          	addi	a0,a0,-144 # 800250a8 <disk+0x20a8>
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	ac0080e7          	jalr	-1344(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80006148:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000614a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000614c:	0001dc17          	auipc	s8,0x1d
    80006150:	eb4c0c13          	addi	s8,s8,-332 # 80023000 <disk>
    80006154:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006156:	4b0d                	li	s6,3
    80006158:	a0ad                	j	800061c2 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000615a:	00fc0733          	add	a4,s8,a5
    8000615e:	975e                	add	a4,a4,s7
    80006160:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006164:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006166:	0207c563          	bltz	a5,80006190 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000616a:	2905                	addiw	s2,s2,1
    8000616c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    8000616e:	19690c63          	beq	s2,s6,80006306 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80006172:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006174:	0001f717          	auipc	a4,0x1f
    80006178:	ea470713          	addi	a4,a4,-348 # 80025018 <disk+0x2018>
    8000617c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000617e:	00074683          	lbu	a3,0(a4)
    80006182:	fee1                	bnez	a3,8000615a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006184:	2785                	addiw	a5,a5,1
    80006186:	0705                	addi	a4,a4,1
    80006188:	fe979be3          	bne	a5,s1,8000617e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000618c:	57fd                	li	a5,-1
    8000618e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006190:	01205d63          	blez	s2,800061aa <virtio_disk_rw+0xa2>
    80006194:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006196:	000a2503          	lw	a0,0(s4)
    8000619a:	00000097          	auipc	ra,0x0
    8000619e:	dac080e7          	jalr	-596(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    800061a2:	2d85                	addiw	s11,s11,1
    800061a4:	0a11                	addi	s4,s4,4
    800061a6:	ff2d98e3          	bne	s11,s2,80006196 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061aa:	0001f597          	auipc	a1,0x1f
    800061ae:	efe58593          	addi	a1,a1,-258 # 800250a8 <disk+0x20a8>
    800061b2:	0001f517          	auipc	a0,0x1f
    800061b6:	e6650513          	addi	a0,a0,-410 # 80025018 <disk+0x2018>
    800061ba:	ffffc097          	auipc	ra,0xffffc
    800061be:	1fc080e7          	jalr	508(ra) # 800023b6 <sleep>
  for(int i = 0; i < 3; i++){
    800061c2:	f8040a13          	addi	s4,s0,-128
{
    800061c6:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061c8:	894e                	mv	s2,s3
    800061ca:	b765                	j	80006172 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061cc:	0001f717          	auipc	a4,0x1f
    800061d0:	e3473703          	ld	a4,-460(a4) # 80025000 <disk+0x2000>
    800061d4:	973e                	add	a4,a4,a5
    800061d6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061da:	0001d517          	auipc	a0,0x1d
    800061de:	e2650513          	addi	a0,a0,-474 # 80023000 <disk>
    800061e2:	0001f717          	auipc	a4,0x1f
    800061e6:	e1e70713          	addi	a4,a4,-482 # 80025000 <disk+0x2000>
    800061ea:	6314                	ld	a3,0(a4)
    800061ec:	96be                	add	a3,a3,a5
    800061ee:	00c6d603          	lhu	a2,12(a3)
    800061f2:	00166613          	ori	a2,a2,1
    800061f6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061fa:	f8842683          	lw	a3,-120(s0)
    800061fe:	6310                	ld	a2,0(a4)
    80006200:	97b2                	add	a5,a5,a2
    80006202:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80006206:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000620a:	0612                	slli	a2,a2,0x4
    8000620c:	962a                	add	a2,a2,a0
    8000620e:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006212:	00469793          	slli	a5,a3,0x4
    80006216:	630c                	ld	a1,0(a4)
    80006218:	95be                	add	a1,a1,a5
    8000621a:	6689                	lui	a3,0x2
    8000621c:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006220:	96ca                	add	a3,a3,s2
    80006222:	96aa                	add	a3,a3,a0
    80006224:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006226:	6314                	ld	a3,0(a4)
    80006228:	96be                	add	a3,a3,a5
    8000622a:	4585                	li	a1,1
    8000622c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000622e:	6314                	ld	a3,0(a4)
    80006230:	96be                	add	a3,a3,a5
    80006232:	4509                	li	a0,2
    80006234:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006238:	6314                	ld	a3,0(a4)
    8000623a:	97b6                	add	a5,a5,a3
    8000623c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006240:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006244:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006248:	6714                	ld	a3,8(a4)
    8000624a:	0026d783          	lhu	a5,2(a3)
    8000624e:	8b9d                	andi	a5,a5,7
    80006250:	0789                	addi	a5,a5,2
    80006252:	0786                	slli	a5,a5,0x1
    80006254:	96be                	add	a3,a3,a5
    80006256:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000625a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000625e:	6718                	ld	a4,8(a4)
    80006260:	00275783          	lhu	a5,2(a4)
    80006264:	2785                	addiw	a5,a5,1
    80006266:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000626a:	100017b7          	lui	a5,0x10001
    8000626e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006272:	004aa783          	lw	a5,4(s5)
    80006276:	02b79163          	bne	a5,a1,80006298 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000627a:	0001f917          	auipc	s2,0x1f
    8000627e:	e2e90913          	addi	s2,s2,-466 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006282:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006284:	85ca                	mv	a1,s2
    80006286:	8556                	mv	a0,s5
    80006288:	ffffc097          	auipc	ra,0xffffc
    8000628c:	12e080e7          	jalr	302(ra) # 800023b6 <sleep>
  while(b->disk == 1) {
    80006290:	004aa783          	lw	a5,4(s5)
    80006294:	fe9788e3          	beq	a5,s1,80006284 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006298:	f8042483          	lw	s1,-128(s0)
    8000629c:	20048713          	addi	a4,s1,512
    800062a0:	0712                	slli	a4,a4,0x4
    800062a2:	0001d797          	auipc	a5,0x1d
    800062a6:	d5e78793          	addi	a5,a5,-674 # 80023000 <disk>
    800062aa:	97ba                	add	a5,a5,a4
    800062ac:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062b0:	0001f917          	auipc	s2,0x1f
    800062b4:	d5090913          	addi	s2,s2,-688 # 80025000 <disk+0x2000>
    800062b8:	a019                	j	800062be <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    800062ba:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    800062be:	8526                	mv	a0,s1
    800062c0:	00000097          	auipc	ra,0x0
    800062c4:	c86080e7          	jalr	-890(ra) # 80005f46 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800062c8:	0492                	slli	s1,s1,0x4
    800062ca:	00093783          	ld	a5,0(s2)
    800062ce:	97a6                	add	a5,a5,s1
    800062d0:	00c7d703          	lhu	a4,12(a5)
    800062d4:	8b05                	andi	a4,a4,1
    800062d6:	f375                	bnez	a4,800062ba <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062d8:	0001f517          	auipc	a0,0x1f
    800062dc:	dd050513          	addi	a0,a0,-560 # 800250a8 <disk+0x20a8>
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	9d4080e7          	jalr	-1580(ra) # 80000cb4 <release>
}
    800062e8:	60aa                	ld	ra,136(sp)
    800062ea:	640a                	ld	s0,128(sp)
    800062ec:	74e6                	ld	s1,120(sp)
    800062ee:	7946                	ld	s2,112(sp)
    800062f0:	79a6                	ld	s3,104(sp)
    800062f2:	7a06                	ld	s4,96(sp)
    800062f4:	6ae6                	ld	s5,88(sp)
    800062f6:	6b46                	ld	s6,80(sp)
    800062f8:	6ba6                	ld	s7,72(sp)
    800062fa:	6c06                	ld	s8,64(sp)
    800062fc:	7ce2                	ld	s9,56(sp)
    800062fe:	7d42                	ld	s10,48(sp)
    80006300:	7da2                	ld	s11,40(sp)
    80006302:	6149                	addi	sp,sp,144
    80006304:	8082                	ret
  if(write)
    80006306:	01a037b3          	snez	a5,s10
    8000630a:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    8000630e:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006312:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006316:	f8042483          	lw	s1,-128(s0)
    8000631a:	00449913          	slli	s2,s1,0x4
    8000631e:	0001f997          	auipc	s3,0x1f
    80006322:	ce298993          	addi	s3,s3,-798 # 80025000 <disk+0x2000>
    80006326:	0009ba03          	ld	s4,0(s3)
    8000632a:	9a4a                	add	s4,s4,s2
    8000632c:	f7040513          	addi	a0,s0,-144
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	da4080e7          	jalr	-604(ra) # 800010d4 <kvmpa>
    80006338:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000633c:	0009b783          	ld	a5,0(s3)
    80006340:	97ca                	add	a5,a5,s2
    80006342:	4741                	li	a4,16
    80006344:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006346:	0009b783          	ld	a5,0(s3)
    8000634a:	97ca                	add	a5,a5,s2
    8000634c:	4705                	li	a4,1
    8000634e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006352:	f8442783          	lw	a5,-124(s0)
    80006356:	0009b703          	ld	a4,0(s3)
    8000635a:	974a                	add	a4,a4,s2
    8000635c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006360:	0792                	slli	a5,a5,0x4
    80006362:	0009b703          	ld	a4,0(s3)
    80006366:	973e                	add	a4,a4,a5
    80006368:	058a8693          	addi	a3,s5,88
    8000636c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000636e:	0009b703          	ld	a4,0(s3)
    80006372:	973e                	add	a4,a4,a5
    80006374:	40000693          	li	a3,1024
    80006378:	c714                	sw	a3,8(a4)
  if(write)
    8000637a:	e40d19e3          	bnez	s10,800061cc <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000637e:	0001f717          	auipc	a4,0x1f
    80006382:	c8273703          	ld	a4,-894(a4) # 80025000 <disk+0x2000>
    80006386:	973e                	add	a4,a4,a5
    80006388:	4689                	li	a3,2
    8000638a:	00d71623          	sh	a3,12(a4)
    8000638e:	b5b1                	j	800061da <virtio_disk_rw+0xd2>

0000000080006390 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006390:	1101                	addi	sp,sp,-32
    80006392:	ec06                	sd	ra,24(sp)
    80006394:	e822                	sd	s0,16(sp)
    80006396:	e426                	sd	s1,8(sp)
    80006398:	e04a                	sd	s2,0(sp)
    8000639a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000639c:	0001f517          	auipc	a0,0x1f
    800063a0:	d0c50513          	addi	a0,a0,-756 # 800250a8 <disk+0x20a8>
    800063a4:	ffffb097          	auipc	ra,0xffffb
    800063a8:	85c080e7          	jalr	-1956(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063ac:	0001f717          	auipc	a4,0x1f
    800063b0:	c5470713          	addi	a4,a4,-940 # 80025000 <disk+0x2000>
    800063b4:	02075783          	lhu	a5,32(a4)
    800063b8:	6b18                	ld	a4,16(a4)
    800063ba:	00275683          	lhu	a3,2(a4)
    800063be:	8ebd                	xor	a3,a3,a5
    800063c0:	8a9d                	andi	a3,a3,7
    800063c2:	cab9                	beqz	a3,80006418 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063c4:	0001d917          	auipc	s2,0x1d
    800063c8:	c3c90913          	addi	s2,s2,-964 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063cc:	0001f497          	auipc	s1,0x1f
    800063d0:	c3448493          	addi	s1,s1,-972 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063d4:	078e                	slli	a5,a5,0x3
    800063d6:	973e                	add	a4,a4,a5
    800063d8:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800063da:	20078713          	addi	a4,a5,512
    800063de:	0712                	slli	a4,a4,0x4
    800063e0:	974a                	add	a4,a4,s2
    800063e2:	03074703          	lbu	a4,48(a4)
    800063e6:	ef21                	bnez	a4,8000643e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063e8:	20078793          	addi	a5,a5,512
    800063ec:	0792                	slli	a5,a5,0x4
    800063ee:	97ca                	add	a5,a5,s2
    800063f0:	7798                	ld	a4,40(a5)
    800063f2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063f6:	7788                	ld	a0,40(a5)
    800063f8:	ffffc097          	auipc	ra,0xffffc
    800063fc:	13e080e7          	jalr	318(ra) # 80002536 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006400:	0204d783          	lhu	a5,32(s1)
    80006404:	2785                	addiw	a5,a5,1
    80006406:	8b9d                	andi	a5,a5,7
    80006408:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000640c:	6898                	ld	a4,16(s1)
    8000640e:	00275683          	lhu	a3,2(a4)
    80006412:	8a9d                	andi	a3,a3,7
    80006414:	fcf690e3          	bne	a3,a5,800063d4 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006418:	10001737          	lui	a4,0x10001
    8000641c:	533c                	lw	a5,96(a4)
    8000641e:	8b8d                	andi	a5,a5,3
    80006420:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006422:	0001f517          	auipc	a0,0x1f
    80006426:	c8650513          	addi	a0,a0,-890 # 800250a8 <disk+0x20a8>
    8000642a:	ffffb097          	auipc	ra,0xffffb
    8000642e:	88a080e7          	jalr	-1910(ra) # 80000cb4 <release>
}
    80006432:	60e2                	ld	ra,24(sp)
    80006434:	6442                	ld	s0,16(sp)
    80006436:	64a2                	ld	s1,8(sp)
    80006438:	6902                	ld	s2,0(sp)
    8000643a:	6105                	addi	sp,sp,32
    8000643c:	8082                	ret
      panic("virtio_disk_intr status");
    8000643e:	00002517          	auipc	a0,0x2
    80006442:	42250513          	addi	a0,a0,1058 # 80008860 <syscalls+0x438>
    80006446:	ffffa097          	auipc	ra,0xffffa
    8000644a:	100080e7          	jalr	256(ra) # 80000546 <panic>

000000008000644e <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000644e:	7179                	addi	sp,sp,-48
    80006450:	f406                	sd	ra,40(sp)
    80006452:	f022                	sd	s0,32(sp)
    80006454:	ec26                	sd	s1,24(sp)
    80006456:	e84a                	sd	s2,16(sp)
    80006458:	e44e                	sd	s3,8(sp)
    8000645a:	e052                	sd	s4,0(sp)
    8000645c:	1800                	addi	s0,sp,48
    8000645e:	892a                	mv	s2,a0
    80006460:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006462:	00003a17          	auipc	s4,0x3
    80006466:	bc6a0a13          	addi	s4,s4,-1082 # 80009028 <stats>
    8000646a:	000a2683          	lw	a3,0(s4)
    8000646e:	00002617          	auipc	a2,0x2
    80006472:	40a60613          	addi	a2,a2,1034 # 80008878 <syscalls+0x450>
    80006476:	00000097          	auipc	ra,0x0
    8000647a:	2c6080e7          	jalr	710(ra) # 8000673c <snprintf>
    8000647e:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006480:	004a2683          	lw	a3,4(s4)
    80006484:	00002617          	auipc	a2,0x2
    80006488:	40460613          	addi	a2,a2,1028 # 80008888 <syscalls+0x460>
    8000648c:	85ce                	mv	a1,s3
    8000648e:	954a                	add	a0,a0,s2
    80006490:	00000097          	auipc	ra,0x0
    80006494:	2ac080e7          	jalr	684(ra) # 8000673c <snprintf>
  return n;
}
    80006498:	9d25                	addw	a0,a0,s1
    8000649a:	70a2                	ld	ra,40(sp)
    8000649c:	7402                	ld	s0,32(sp)
    8000649e:	64e2                	ld	s1,24(sp)
    800064a0:	6942                	ld	s2,16(sp)
    800064a2:	69a2                	ld	s3,8(sp)
    800064a4:	6a02                	ld	s4,0(sp)
    800064a6:	6145                	addi	sp,sp,48
    800064a8:	8082                	ret

00000000800064aa <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800064aa:	7179                	addi	sp,sp,-48
    800064ac:	f406                	sd	ra,40(sp)
    800064ae:	f022                	sd	s0,32(sp)
    800064b0:	ec26                	sd	s1,24(sp)
    800064b2:	e84a                	sd	s2,16(sp)
    800064b4:	e44e                	sd	s3,8(sp)
    800064b6:	1800                	addi	s0,sp,48
    800064b8:	89ae                	mv	s3,a1
    800064ba:	84b2                	mv	s1,a2
    800064bc:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800064be:	ffffb097          	auipc	ra,0xffffb
    800064c2:	642080e7          	jalr	1602(ra) # 80001b00 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800064c6:	653c                	ld	a5,72(a0)
    800064c8:	02f4ff63          	bgeu	s1,a5,80006506 <copyin_new+0x5c>
    800064cc:	01248733          	add	a4,s1,s2
    800064d0:	02f77d63          	bgeu	a4,a5,8000650a <copyin_new+0x60>
    800064d4:	02976d63          	bltu	a4,s1,8000650e <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800064d8:	0009061b          	sext.w	a2,s2
    800064dc:	85a6                	mv	a1,s1
    800064de:	854e                	mv	a0,s3
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	878080e7          	jalr	-1928(ra) # 80000d58 <memmove>
  stats.ncopyin++;   // XXX lock
    800064e8:	00003717          	auipc	a4,0x3
    800064ec:	b4070713          	addi	a4,a4,-1216 # 80009028 <stats>
    800064f0:	431c                	lw	a5,0(a4)
    800064f2:	2785                	addiw	a5,a5,1
    800064f4:	c31c                	sw	a5,0(a4)
  return 0;
    800064f6:	4501                	li	a0,0
}
    800064f8:	70a2                	ld	ra,40(sp)
    800064fa:	7402                	ld	s0,32(sp)
    800064fc:	64e2                	ld	s1,24(sp)
    800064fe:	6942                	ld	s2,16(sp)
    80006500:	69a2                	ld	s3,8(sp)
    80006502:	6145                	addi	sp,sp,48
    80006504:	8082                	ret
    return -1;
    80006506:	557d                	li	a0,-1
    80006508:	bfc5                	j	800064f8 <copyin_new+0x4e>
    8000650a:	557d                	li	a0,-1
    8000650c:	b7f5                	j	800064f8 <copyin_new+0x4e>
    8000650e:	557d                	li	a0,-1
    80006510:	b7e5                	j	800064f8 <copyin_new+0x4e>

0000000080006512 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006512:	7179                	addi	sp,sp,-48
    80006514:	f406                	sd	ra,40(sp)
    80006516:	f022                	sd	s0,32(sp)
    80006518:	ec26                	sd	s1,24(sp)
    8000651a:	e84a                	sd	s2,16(sp)
    8000651c:	e44e                	sd	s3,8(sp)
    8000651e:	1800                	addi	s0,sp,48
    80006520:	89ae                	mv	s3,a1
    80006522:	8932                	mv	s2,a2
    80006524:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006526:	ffffb097          	auipc	ra,0xffffb
    8000652a:	5da080e7          	jalr	1498(ra) # 80001b00 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    8000652e:	00003717          	auipc	a4,0x3
    80006532:	afa70713          	addi	a4,a4,-1286 # 80009028 <stats>
    80006536:	435c                	lw	a5,4(a4)
    80006538:	2785                	addiw	a5,a5,1
    8000653a:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000653c:	cc8d                	beqz	s1,80006576 <copyinstr_new+0x64>
    8000653e:	009906b3          	add	a3,s2,s1
    80006542:	87ca                	mv	a5,s2
    80006544:	6538                	ld	a4,72(a0)
    80006546:	02e7f063          	bgeu	a5,a4,80006566 <copyinstr_new+0x54>
    dst[i] = s[i];
    8000654a:	0007c803          	lbu	a6,0(a5)
    8000654e:	41278733          	sub	a4,a5,s2
    80006552:	974e                	add	a4,a4,s3
    80006554:	01070023          	sb	a6,0(a4)
    if(s[i] == '\0')
    80006558:	02080163          	beqz	a6,8000657a <copyinstr_new+0x68>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000655c:	0785                	addi	a5,a5,1
    8000655e:	fed793e3          	bne	a5,a3,80006544 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006562:	557d                	li	a0,-1
    80006564:	a011                	j	80006568 <copyinstr_new+0x56>
    80006566:	557d                	li	a0,-1
}
    80006568:	70a2                	ld	ra,40(sp)
    8000656a:	7402                	ld	s0,32(sp)
    8000656c:	64e2                	ld	s1,24(sp)
    8000656e:	6942                	ld	s2,16(sp)
    80006570:	69a2                	ld	s3,8(sp)
    80006572:	6145                	addi	sp,sp,48
    80006574:	8082                	ret
  return -1;
    80006576:	557d                	li	a0,-1
    80006578:	bfc5                	j	80006568 <copyinstr_new+0x56>
      return 0;
    8000657a:	4501                	li	a0,0
    8000657c:	b7f5                	j	80006568 <copyinstr_new+0x56>

000000008000657e <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000657e:	1141                	addi	sp,sp,-16
    80006580:	e422                	sd	s0,8(sp)
    80006582:	0800                	addi	s0,sp,16
  return -1;
}
    80006584:	557d                	li	a0,-1
    80006586:	6422                	ld	s0,8(sp)
    80006588:	0141                	addi	sp,sp,16
    8000658a:	8082                	ret

000000008000658c <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    8000658c:	7179                	addi	sp,sp,-48
    8000658e:	f406                	sd	ra,40(sp)
    80006590:	f022                	sd	s0,32(sp)
    80006592:	ec26                	sd	s1,24(sp)
    80006594:	e84a                	sd	s2,16(sp)
    80006596:	e44e                	sd	s3,8(sp)
    80006598:	e052                	sd	s4,0(sp)
    8000659a:	1800                	addi	s0,sp,48
    8000659c:	892a                	mv	s2,a0
    8000659e:	89ae                	mv	s3,a1
    800065a0:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800065a2:	00020517          	auipc	a0,0x20
    800065a6:	a5e50513          	addi	a0,a0,-1442 # 80026000 <stats>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	656080e7          	jalr	1622(ra) # 80000c00 <acquire>

  if(stats.sz == 0) {
    800065b2:	00021797          	auipc	a5,0x21
    800065b6:	a667a783          	lw	a5,-1434(a5) # 80027018 <stats+0x1018>
    800065ba:	cbb5                	beqz	a5,8000662e <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800065bc:	00021797          	auipc	a5,0x21
    800065c0:	a4478793          	addi	a5,a5,-1468 # 80027000 <stats+0x1000>
    800065c4:	4fd8                	lw	a4,28(a5)
    800065c6:	4f9c                	lw	a5,24(a5)
    800065c8:	9f99                	subw	a5,a5,a4
    800065ca:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800065ce:	06d05e63          	blez	a3,8000664a <statsread+0xbe>
    if(m > n)
    800065d2:	8a3e                	mv	s4,a5
    800065d4:	00d4d363          	bge	s1,a3,800065da <statsread+0x4e>
    800065d8:	8a26                	mv	s4,s1
    800065da:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065de:	86a6                	mv	a3,s1
    800065e0:	00020617          	auipc	a2,0x20
    800065e4:	a3860613          	addi	a2,a2,-1480 # 80026018 <stats+0x18>
    800065e8:	963a                	add	a2,a2,a4
    800065ea:	85ce                	mv	a1,s3
    800065ec:	854a                	mv	a0,s2
    800065ee:	ffffc097          	auipc	ra,0xffffc
    800065f2:	022080e7          	jalr	34(ra) # 80002610 <either_copyout>
    800065f6:	57fd                	li	a5,-1
    800065f8:	00f50a63          	beq	a0,a5,8000660c <statsread+0x80>
      stats.off += m;
    800065fc:	00021717          	auipc	a4,0x21
    80006600:	a0470713          	addi	a4,a4,-1532 # 80027000 <stats+0x1000>
    80006604:	4f5c                	lw	a5,28(a4)
    80006606:	00fa07bb          	addw	a5,s4,a5
    8000660a:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    8000660c:	00020517          	auipc	a0,0x20
    80006610:	9f450513          	addi	a0,a0,-1548 # 80026000 <stats>
    80006614:	ffffa097          	auipc	ra,0xffffa
    80006618:	6a0080e7          	jalr	1696(ra) # 80000cb4 <release>
  return m;
}
    8000661c:	8526                	mv	a0,s1
    8000661e:	70a2                	ld	ra,40(sp)
    80006620:	7402                	ld	s0,32(sp)
    80006622:	64e2                	ld	s1,24(sp)
    80006624:	6942                	ld	s2,16(sp)
    80006626:	69a2                	ld	s3,8(sp)
    80006628:	6a02                	ld	s4,0(sp)
    8000662a:	6145                	addi	sp,sp,48
    8000662c:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    8000662e:	6585                	lui	a1,0x1
    80006630:	00020517          	auipc	a0,0x20
    80006634:	9e850513          	addi	a0,a0,-1560 # 80026018 <stats+0x18>
    80006638:	00000097          	auipc	ra,0x0
    8000663c:	e16080e7          	jalr	-490(ra) # 8000644e <statscopyin>
    80006640:	00021797          	auipc	a5,0x21
    80006644:	9ca7ac23          	sw	a0,-1576(a5) # 80027018 <stats+0x1018>
    80006648:	bf95                	j	800065bc <statsread+0x30>
    stats.sz = 0;
    8000664a:	00021797          	auipc	a5,0x21
    8000664e:	9b678793          	addi	a5,a5,-1610 # 80027000 <stats+0x1000>
    80006652:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006656:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000665a:	54fd                	li	s1,-1
    8000665c:	bf45                	j	8000660c <statsread+0x80>

000000008000665e <statsinit>:

void
statsinit(void)
{
    8000665e:	1141                	addi	sp,sp,-16
    80006660:	e406                	sd	ra,8(sp)
    80006662:	e022                	sd	s0,0(sp)
    80006664:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006666:	00002597          	auipc	a1,0x2
    8000666a:	23258593          	addi	a1,a1,562 # 80008898 <syscalls+0x470>
    8000666e:	00020517          	auipc	a0,0x20
    80006672:	99250513          	addi	a0,a0,-1646 # 80026000 <stats>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	4fa080e7          	jalr	1274(ra) # 80000b70 <initlock>

  devsw[STATS].read = statsread;
    8000667e:	0001b797          	auipc	a5,0x1b
    80006682:	73278793          	addi	a5,a5,1842 # 80021db0 <devsw>
    80006686:	00000717          	auipc	a4,0x0
    8000668a:	f0670713          	addi	a4,a4,-250 # 8000658c <statsread>
    8000668e:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006690:	00000717          	auipc	a4,0x0
    80006694:	eee70713          	addi	a4,a4,-274 # 8000657e <statswrite>
    80006698:	f798                	sd	a4,40(a5)
}
    8000669a:	60a2                	ld	ra,8(sp)
    8000669c:	6402                	ld	s0,0(sp)
    8000669e:	0141                	addi	sp,sp,16
    800066a0:	8082                	ret

00000000800066a2 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800066a2:	1101                	addi	sp,sp,-32
    800066a4:	ec22                	sd	s0,24(sp)
    800066a6:	1000                	addi	s0,sp,32
    800066a8:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800066aa:	c299                	beqz	a3,800066b0 <sprintint+0xe>
    800066ac:	0805c263          	bltz	a1,80006730 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    800066b0:	2581                	sext.w	a1,a1
    800066b2:	4301                	li	t1,0

  i = 0;
    800066b4:	fe040713          	addi	a4,s0,-32
    800066b8:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800066ba:	2601                	sext.w	a2,a2
    800066bc:	00002697          	auipc	a3,0x2
    800066c0:	1e468693          	addi	a3,a3,484 # 800088a0 <digits>
    800066c4:	88aa                	mv	a7,a0
    800066c6:	2505                	addiw	a0,a0,1
    800066c8:	02c5f7bb          	remuw	a5,a1,a2
    800066cc:	1782                	slli	a5,a5,0x20
    800066ce:	9381                	srli	a5,a5,0x20
    800066d0:	97b6                	add	a5,a5,a3
    800066d2:	0007c783          	lbu	a5,0(a5)
    800066d6:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066da:	0005879b          	sext.w	a5,a1
    800066de:	02c5d5bb          	divuw	a1,a1,a2
    800066e2:	0705                	addi	a4,a4,1
    800066e4:	fec7f0e3          	bgeu	a5,a2,800066c4 <sprintint+0x22>

  if(sign)
    800066e8:	00030b63          	beqz	t1,800066fe <sprintint+0x5c>
    buf[i++] = '-';
    800066ec:	ff050793          	addi	a5,a0,-16
    800066f0:	97a2                	add	a5,a5,s0
    800066f2:	02d00713          	li	a4,45
    800066f6:	fee78823          	sb	a4,-16(a5)
    800066fa:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066fe:	02a05d63          	blez	a0,80006738 <sprintint+0x96>
    80006702:	fe040793          	addi	a5,s0,-32
    80006706:	00a78733          	add	a4,a5,a0
    8000670a:	87c2                	mv	a5,a6
    8000670c:	00180613          	addi	a2,a6,1
    80006710:	fff5069b          	addiw	a3,a0,-1
    80006714:	1682                	slli	a3,a3,0x20
    80006716:	9281                	srli	a3,a3,0x20
    80006718:	9636                	add	a2,a2,a3
  *s = c;
    8000671a:	fff74683          	lbu	a3,-1(a4)
    8000671e:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006722:	177d                	addi	a4,a4,-1
    80006724:	0785                	addi	a5,a5,1
    80006726:	fec79ae3          	bne	a5,a2,8000671a <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000672a:	6462                	ld	s0,24(sp)
    8000672c:	6105                	addi	sp,sp,32
    8000672e:	8082                	ret
    x = -xx;
    80006730:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006734:	4305                	li	t1,1
    x = -xx;
    80006736:	bfbd                	j	800066b4 <sprintint+0x12>
  while(--i >= 0)
    80006738:	4501                	li	a0,0
    8000673a:	bfc5                	j	8000672a <sprintint+0x88>

000000008000673c <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000673c:	7135                	addi	sp,sp,-160
    8000673e:	f486                	sd	ra,104(sp)
    80006740:	f0a2                	sd	s0,96(sp)
    80006742:	eca6                	sd	s1,88(sp)
    80006744:	e8ca                	sd	s2,80(sp)
    80006746:	e4ce                	sd	s3,72(sp)
    80006748:	e0d2                	sd	s4,64(sp)
    8000674a:	fc56                	sd	s5,56(sp)
    8000674c:	f85a                	sd	s6,48(sp)
    8000674e:	f45e                	sd	s7,40(sp)
    80006750:	f062                	sd	s8,32(sp)
    80006752:	ec66                	sd	s9,24(sp)
    80006754:	e86a                	sd	s10,16(sp)
    80006756:	1880                	addi	s0,sp,112
    80006758:	e414                	sd	a3,8(s0)
    8000675a:	e818                	sd	a4,16(s0)
    8000675c:	ec1c                	sd	a5,24(s0)
    8000675e:	03043023          	sd	a6,32(s0)
    80006762:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006766:	c61d                	beqz	a2,80006794 <snprintf+0x58>
    80006768:	8baa                	mv	s7,a0
    8000676a:	89ae                	mv	s3,a1
    8000676c:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000676e:	00840793          	addi	a5,s0,8
    80006772:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    80006776:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006778:	4901                	li	s2,0
    8000677a:	02b05563          	blez	a1,800067a4 <snprintf+0x68>
    if(c != '%'){
    8000677e:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006782:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006786:	02800d13          	li	s10,40
    switch(c){
    8000678a:	07800c93          	li	s9,120
    8000678e:	06400c13          	li	s8,100
    80006792:	a01d                	j	800067b8 <snprintf+0x7c>
    panic("null fmt");
    80006794:	00002517          	auipc	a0,0x2
    80006798:	89450513          	addi	a0,a0,-1900 # 80008028 <etext+0x28>
    8000679c:	ffffa097          	auipc	ra,0xffffa
    800067a0:	daa080e7          	jalr	-598(ra) # 80000546 <panic>
  int off = 0;
    800067a4:	4481                	li	s1,0
    800067a6:	a875                	j	80006862 <snprintf+0x126>
  *s = c;
    800067a8:	009b8733          	add	a4,s7,s1
    800067ac:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800067b0:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067b2:	2905                	addiw	s2,s2,1
    800067b4:	0b34d763          	bge	s1,s3,80006862 <snprintf+0x126>
    800067b8:	012a07b3          	add	a5,s4,s2
    800067bc:	0007c783          	lbu	a5,0(a5)
    800067c0:	0007871b          	sext.w	a4,a5
    800067c4:	cfd9                	beqz	a5,80006862 <snprintf+0x126>
    if(c != '%'){
    800067c6:	ff5711e3          	bne	a4,s5,800067a8 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800067ca:	2905                	addiw	s2,s2,1
    800067cc:	012a07b3          	add	a5,s4,s2
    800067d0:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800067d4:	c7d9                	beqz	a5,80006862 <snprintf+0x126>
    switch(c){
    800067d6:	05678c63          	beq	a5,s6,8000682e <snprintf+0xf2>
    800067da:	02fb6763          	bltu	s6,a5,80006808 <snprintf+0xcc>
    800067de:	0b578763          	beq	a5,s5,8000688c <snprintf+0x150>
    800067e2:	0b879b63          	bne	a5,s8,80006898 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067e6:	f9843783          	ld	a5,-104(s0)
    800067ea:	00878713          	addi	a4,a5,8
    800067ee:	f8e43c23          	sd	a4,-104(s0)
    800067f2:	4685                	li	a3,1
    800067f4:	4629                	li	a2,10
    800067f6:	438c                	lw	a1,0(a5)
    800067f8:	009b8533          	add	a0,s7,s1
    800067fc:	00000097          	auipc	ra,0x0
    80006800:	ea6080e7          	jalr	-346(ra) # 800066a2 <sprintint>
    80006804:	9ca9                	addw	s1,s1,a0
      break;
    80006806:	b775                	j	800067b2 <snprintf+0x76>
    switch(c){
    80006808:	09979863          	bne	a5,s9,80006898 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    8000680c:	f9843783          	ld	a5,-104(s0)
    80006810:	00878713          	addi	a4,a5,8
    80006814:	f8e43c23          	sd	a4,-104(s0)
    80006818:	4685                	li	a3,1
    8000681a:	4641                	li	a2,16
    8000681c:	438c                	lw	a1,0(a5)
    8000681e:	009b8533          	add	a0,s7,s1
    80006822:	00000097          	auipc	ra,0x0
    80006826:	e80080e7          	jalr	-384(ra) # 800066a2 <sprintint>
    8000682a:	9ca9                	addw	s1,s1,a0
      break;
    8000682c:	b759                	j	800067b2 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    8000682e:	f9843783          	ld	a5,-104(s0)
    80006832:	00878713          	addi	a4,a5,8
    80006836:	f8e43c23          	sd	a4,-104(s0)
    8000683a:	639c                	ld	a5,0(a5)
    8000683c:	c3b1                	beqz	a5,80006880 <snprintf+0x144>
      for(; *s && off < sz; s++)
    8000683e:	0007c703          	lbu	a4,0(a5)
    80006842:	db25                	beqz	a4,800067b2 <snprintf+0x76>
    80006844:	0734d563          	bge	s1,s3,800068ae <snprintf+0x172>
    80006848:	009b86b3          	add	a3,s7,s1
  *s = c;
    8000684c:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006850:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006852:	0785                	addi	a5,a5,1
    80006854:	0007c703          	lbu	a4,0(a5)
    80006858:	df29                	beqz	a4,800067b2 <snprintf+0x76>
    8000685a:	0685                	addi	a3,a3,1
    8000685c:	fe9998e3          	bne	s3,s1,8000684c <snprintf+0x110>
  int off = 0;
    80006860:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006862:	8526                	mv	a0,s1
    80006864:	70a6                	ld	ra,104(sp)
    80006866:	7406                	ld	s0,96(sp)
    80006868:	64e6                	ld	s1,88(sp)
    8000686a:	6946                	ld	s2,80(sp)
    8000686c:	69a6                	ld	s3,72(sp)
    8000686e:	6a06                	ld	s4,64(sp)
    80006870:	7ae2                	ld	s5,56(sp)
    80006872:	7b42                	ld	s6,48(sp)
    80006874:	7ba2                	ld	s7,40(sp)
    80006876:	7c02                	ld	s8,32(sp)
    80006878:	6ce2                	ld	s9,24(sp)
    8000687a:	6d42                	ld	s10,16(sp)
    8000687c:	610d                	addi	sp,sp,160
    8000687e:	8082                	ret
        s = "(null)";
    80006880:	00001797          	auipc	a5,0x1
    80006884:	7a078793          	addi	a5,a5,1952 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006888:	876a                	mv	a4,s10
    8000688a:	bf6d                	j	80006844 <snprintf+0x108>
  *s = c;
    8000688c:	009b87b3          	add	a5,s7,s1
    80006890:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    80006894:	2485                	addiw	s1,s1,1
      break;
    80006896:	bf31                	j	800067b2 <snprintf+0x76>
  *s = c;
    80006898:	009b8733          	add	a4,s7,s1
    8000689c:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800068a0:	0014871b          	addiw	a4,s1,1
  *s = c;
    800068a4:	975e                	add	a4,a4,s7
    800068a6:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068aa:	2489                	addiw	s1,s1,2
      break;
    800068ac:	b719                	j	800067b2 <snprintf+0x76>
      for(; *s && off < sz; s++)
    800068ae:	89a6                	mv	s3,s1
    800068b0:	bf45                	j	80006860 <snprintf+0x124>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
