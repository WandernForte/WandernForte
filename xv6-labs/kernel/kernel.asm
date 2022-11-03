
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
    80000060:	c7478793          	addi	a5,a5,-908 # 80005cd0 <timervec>
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
    8000012a:	398080e7          	jalr	920(ra) # 800024be <either_copyin>
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
    800001d0:	82e080e7          	jalr	-2002(ra) # 800019fa <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	032080e7          	jalr	50(ra) # 8000220e <sleep>
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
    8000021c:	250080e7          	jalr	592(ra) # 80002468 <either_copyout>
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
    800002fc:	21c080e7          	jalr	540(ra) # 80002514 <procdump>
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
    80000450:	f42080e7          	jalr	-190(ra) # 8000238e <wakeup>
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
    8000047e:	00021797          	auipc	a5,0x21
    80000482:	53278793          	addi	a5,a5,1330 # 800219b0 <devsw>
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
    800008aa:	ae8080e7          	jalr	-1304(ra) # 8000238e <wakeup>
    
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
    80000944:	8ce080e7          	jalr	-1842(ra) # 8000220e <sleep>
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
    80000b9e:	e44080e7          	jalr	-444(ra) # 800019de <mycpu>
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
    80000bd0:	e12080e7          	jalr	-494(ra) # 800019de <mycpu>
    80000bd4:	5d3c                	lw	a5,120(a0)
    80000bd6:	cf89                	beqz	a5,80000bf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	e06080e7          	jalr	-506(ra) # 800019de <mycpu>
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
    80000bf4:	dee080e7          	jalr	-530(ra) # 800019de <mycpu>
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
    80000c34:	dae080e7          	jalr	-594(ra) # 800019de <mycpu>
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
    80000c60:	d82080e7          	jalr	-638(ra) # 800019de <mycpu>
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
    80000eb6:	b1c080e7          	jalr	-1252(ra) # 800019ce <cpuid>
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
    80000ed2:	b00080e7          	jalr	-1280(ra) # 800019ce <cpuid>
    80000ed6:	85aa                	mv	a1,a0
    80000ed8:	00007517          	auipc	a0,0x7
    80000edc:	1e050513          	addi	a0,a0,480 # 800080b8 <digits+0x78>
    80000ee0:	fffff097          	auipc	ra,0xfffff
    80000ee4:	6b0080e7          	jalr	1712(ra) # 80000590 <printf>
    kvminithart();    // turn on paging
    80000ee8:	00000097          	auipc	ra,0x0
    80000eec:	0e0080e7          	jalr	224(ra) # 80000fc8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	766080e7          	jalr	1894(ra) # 80002656 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef8:	00005097          	auipc	ra,0x5
    80000efc:	e18080e7          	jalr	-488(ra) # 80005d10 <plicinithart>
  }

  scheduler();        
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	032080e7          	jalr	50(ra) # 80001f32 <scheduler>
    consoleinit();
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	54e080e7          	jalr	1358(ra) # 80000456 <consoleinit>
    statsinit();
    80000f10:	00005097          	auipc	ra,0x5
    80000f14:	59e080e7          	jalr	1438(ra) # 800064ae <statsinit>
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
    80000f6c:	996080e7          	jalr	-1642(ra) # 800018fe <procinit>
    trapinit();      // trap vectors
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	6be080e7          	jalr	1726(ra) # 8000262e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	6de080e7          	jalr	1758(ra) # 80002656 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	d7a080e7          	jalr	-646(ra) # 80005cfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	d88080e7          	jalr	-632(ra) # 80005d10 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	e20080e7          	jalr	-480(ra) # 80002db0 <binit>
    iinit();         // inode cache
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	4ae080e7          	jalr	1198(ra) # 80003446 <iinit>
    fileinit();      // file table
    80000fa0:	00003097          	auipc	ra,0x3
    80000fa4:	450080e7          	jalr	1104(ra) # 800043f0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	e6e080e7          	jalr	-402(ra) # 80005e16 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	d14080e7          	jalr	-748(ra) # 80001cc4 <userinit>
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

00000000800012ca <uvmunmap>:
// Optionally free the physical memory.
// If do_free != 0, physical memory will be freed
// starts with u means user virtual memory
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ca:	715d                	addi	sp,sp,-80
    800012cc:	e486                	sd	ra,72(sp)
    800012ce:	e0a2                	sd	s0,64(sp)
    800012d0:	fc26                	sd	s1,56(sp)
    800012d2:	f84a                	sd	s2,48(sp)
    800012d4:	f44e                	sd	s3,40(sp)
    800012d6:	f052                	sd	s4,32(sp)
    800012d8:	ec56                	sd	s5,24(sp)
    800012da:	e85a                	sd	s6,16(sp)
    800012dc:	e45e                	sd	s7,8(sp)
    800012de:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012e0:	03459793          	slli	a5,a1,0x34
    800012e4:	e795                	bnez	a5,80001310 <uvmunmap+0x46>
    800012e6:	8a2a                	mv	s4,a0
    800012e8:	892e                	mv	s2,a1
    800012ea:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ec:	0632                	slli	a2,a2,0xc
    800012ee:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f4:	6b05                	lui	s6,0x1
    800012f6:	0735e263          	bltu	a1,s3,8000135a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012fa:	60a6                	ld	ra,72(sp)
    800012fc:	6406                	ld	s0,64(sp)
    800012fe:	74e2                	ld	s1,56(sp)
    80001300:	7942                	ld	s2,48(sp)
    80001302:	79a2                	ld	s3,40(sp)
    80001304:	7a02                	ld	s4,32(sp)
    80001306:	6ae2                	ld	s5,24(sp)
    80001308:	6b42                	ld	s6,16(sp)
    8000130a:	6ba2                	ld	s7,8(sp)
    8000130c:	6161                	addi	sp,sp,80
    8000130e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001310:	00007517          	auipc	a0,0x7
    80001314:	de050513          	addi	a0,a0,-544 # 800080f0 <digits+0xb0>
    80001318:	fffff097          	auipc	ra,0xfffff
    8000131c:	22e080e7          	jalr	558(ra) # 80000546 <panic>
      panic("uvmunmap: walk");
    80001320:	00007517          	auipc	a0,0x7
    80001324:	de850513          	addi	a0,a0,-536 # 80008108 <digits+0xc8>
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	21e080e7          	jalr	542(ra) # 80000546 <panic>
      panic("uvmunmap: not mapped");
    80001330:	00007517          	auipc	a0,0x7
    80001334:	de850513          	addi	a0,a0,-536 # 80008118 <digits+0xd8>
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	20e080e7          	jalr	526(ra) # 80000546 <panic>
      panic("uvmunmap: not a leaf");
    80001340:	00007517          	auipc	a0,0x7
    80001344:	df050513          	addi	a0,a0,-528 # 80008130 <digits+0xf0>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	1fe080e7          	jalr	510(ra) # 80000546 <panic>
    *pte = 0;
    80001350:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001354:	995a                	add	s2,s2,s6
    80001356:	fb3972e3          	bgeu	s2,s3,800012fa <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000135a:	4601                	li	a2,0
    8000135c:	85ca                	mv	a1,s2
    8000135e:	8552                	mv	a0,s4
    80001360:	00000097          	auipc	ra,0x0
    80001364:	c8c080e7          	jalr	-884(ra) # 80000fec <walk>
    80001368:	84aa                	mv	s1,a0
    8000136a:	d95d                	beqz	a0,80001320 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000136c:	6108                	ld	a0,0(a0)
    8000136e:	00157793          	andi	a5,a0,1
    80001372:	dfdd                	beqz	a5,80001330 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001374:	3ff57793          	andi	a5,a0,1023
    80001378:	fd7784e3          	beq	a5,s7,80001340 <uvmunmap+0x76>
    if(do_free){
    8000137c:	fc0a8ae3          	beqz	s5,80001350 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001380:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001382:	0532                	slli	a0,a0,0xc
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	68e080e7          	jalr	1678(ra) # 80000a12 <kfree>
    8000138c:	b7d1                	j	80001350 <uvmunmap+0x86>

000000008000138e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	778080e7          	jalr	1912(ra) # 80000b10 <kalloc>
    800013a0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a2:	c519                	beqz	a0,800013b0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a4:	6605                	lui	a2,0x1
    800013a6:	4581                	li	a1,0
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	954080e7          	jalr	-1708(ra) # 80000cfc <memset>
  return pagetable;
}
    800013b0:	8526                	mv	a0,s1
    800013b2:	60e2                	ld	ra,24(sp)
    800013b4:	6442                	ld	s0,16(sp)
    800013b6:	64a2                	ld	s1,8(sp)
    800013b8:	6105                	addi	sp,sp,32
    800013ba:	8082                	ret

00000000800013bc <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013bc:	7179                	addi	sp,sp,-48
    800013be:	f406                	sd	ra,40(sp)
    800013c0:	f022                	sd	s0,32(sp)
    800013c2:	ec26                	sd	s1,24(sp)
    800013c4:	e84a                	sd	s2,16(sp)
    800013c6:	e44e                	sd	s3,8(sp)
    800013c8:	e052                	sd	s4,0(sp)
    800013ca:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013cc:	6785                	lui	a5,0x1
    800013ce:	04f67863          	bgeu	a2,a5,8000141e <uvminit+0x62>
    800013d2:	8a2a                	mv	s4,a0
    800013d4:	89ae                	mv	s3,a1
    800013d6:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013d8:	fffff097          	auipc	ra,0xfffff
    800013dc:	738080e7          	jalr	1848(ra) # 80000b10 <kalloc>
    800013e0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e2:	6605                	lui	a2,0x1
    800013e4:	4581                	li	a1,0
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	916080e7          	jalr	-1770(ra) # 80000cfc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013ee:	4779                	li	a4,30
    800013f0:	86ca                	mv	a3,s2
    800013f2:	6605                	lui	a2,0x1
    800013f4:	4581                	li	a1,0
    800013f6:	8552                	mv	a0,s4
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	d3a080e7          	jalr	-710(ra) # 80001132 <mappages>
  memmove(mem, src, sz);
    80001400:	8626                	mv	a2,s1
    80001402:	85ce                	mv	a1,s3
    80001404:	854a                	mv	a0,s2
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	952080e7          	jalr	-1710(ra) # 80000d58 <memmove>
}
    8000140e:	70a2                	ld	ra,40(sp)
    80001410:	7402                	ld	s0,32(sp)
    80001412:	64e2                	ld	s1,24(sp)
    80001414:	6942                	ld	s2,16(sp)
    80001416:	69a2                	ld	s3,8(sp)
    80001418:	6a02                	ld	s4,0(sp)
    8000141a:	6145                	addi	sp,sp,48
    8000141c:	8082                	ret
    panic("inituvm: more than a page");
    8000141e:	00007517          	auipc	a0,0x7
    80001422:	d2a50513          	addi	a0,a0,-726 # 80008148 <digits+0x108>
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	120080e7          	jalr	288(ra) # 80000546 <panic>

000000008000142e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000142e:	1101                	addi	sp,sp,-32
    80001430:	ec06                	sd	ra,24(sp)
    80001432:	e822                	sd	s0,16(sp)
    80001434:	e426                	sd	s1,8(sp)
    80001436:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001438:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143a:	00b67d63          	bgeu	a2,a1,80001454 <uvmdealloc+0x26>
    8000143e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001440:	6785                	lui	a5,0x1
    80001442:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001444:	00f60733          	add	a4,a2,a5
    80001448:	76fd                	lui	a3,0xfffff
    8000144a:	8f75                	and	a4,a4,a3
    8000144c:	97ae                	add	a5,a5,a1
    8000144e:	8ff5                	and	a5,a5,a3
    80001450:	00f76863          	bltu	a4,a5,80001460 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001454:	8526                	mv	a0,s1
    80001456:	60e2                	ld	ra,24(sp)
    80001458:	6442                	ld	s0,16(sp)
    8000145a:	64a2                	ld	s1,8(sp)
    8000145c:	6105                	addi	sp,sp,32
    8000145e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001460:	8f99                	sub	a5,a5,a4
    80001462:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001464:	4685                	li	a3,1
    80001466:	0007861b          	sext.w	a2,a5
    8000146a:	85ba                	mv	a1,a4
    8000146c:	00000097          	auipc	ra,0x0
    80001470:	e5e080e7          	jalr	-418(ra) # 800012ca <uvmunmap>
    80001474:	b7c5                	j	80001454 <uvmdealloc+0x26>

0000000080001476 <uvmalloc>:
  if(newsz < oldsz)
    80001476:	0ab66163          	bltu	a2,a1,80001518 <uvmalloc+0xa2>
{
    8000147a:	7139                	addi	sp,sp,-64
    8000147c:	fc06                	sd	ra,56(sp)
    8000147e:	f822                	sd	s0,48(sp)
    80001480:	f426                	sd	s1,40(sp)
    80001482:	f04a                	sd	s2,32(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001494:	95be                	add	a1,a1,a5
    80001496:	77fd                	lui	a5,0xfffff
    80001498:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9f063          	bgeu	s3,a2,8000151c <uvmalloc+0xa6>
    800014a0:	894e                	mv	s2,s3
    mem = kalloc();
    800014a2:	fffff097          	auipc	ra,0xfffff
    800014a6:	66e080e7          	jalr	1646(ra) # 80000b10 <kalloc>
    800014aa:	84aa                	mv	s1,a0
    if(mem == 0){
    800014ac:	c51d                	beqz	a0,800014da <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ae:	6605                	lui	a2,0x1
    800014b0:	4581                	li	a1,0
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	84a080e7          	jalr	-1974(ra) # 80000cfc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ba:	4779                	li	a4,30
    800014bc:	86a6                	mv	a3,s1
    800014be:	6605                	lui	a2,0x1
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	c6e080e7          	jalr	-914(ra) # 80001132 <mappages>
    800014cc:	e905                	bnez	a0,800014fc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ce:	6785                	lui	a5,0x1
    800014d0:	993e                	add	s2,s2,a5
    800014d2:	fd4968e3          	bltu	s2,s4,800014a2 <uvmalloc+0x2c>
  return newsz;
    800014d6:	8552                	mv	a0,s4
    800014d8:	a809                	j	800014ea <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014da:	864e                	mv	a2,s3
    800014dc:	85ca                	mv	a1,s2
    800014de:	8556                	mv	a0,s5
    800014e0:	00000097          	auipc	ra,0x0
    800014e4:	f4e080e7          	jalr	-178(ra) # 8000142e <uvmdealloc>
      return 0;
    800014e8:	4501                	li	a0,0
}
    800014ea:	70e2                	ld	ra,56(sp)
    800014ec:	7442                	ld	s0,48(sp)
    800014ee:	74a2                	ld	s1,40(sp)
    800014f0:	7902                	ld	s2,32(sp)
    800014f2:	69e2                	ld	s3,24(sp)
    800014f4:	6a42                	ld	s4,16(sp)
    800014f6:	6aa2                	ld	s5,8(sp)
    800014f8:	6121                	addi	sp,sp,64
    800014fa:	8082                	ret
      kfree(mem);
    800014fc:	8526                	mv	a0,s1
    800014fe:	fffff097          	auipc	ra,0xfffff
    80001502:	514080e7          	jalr	1300(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001506:	864e                	mv	a2,s3
    80001508:	85ca                	mv	a1,s2
    8000150a:	8556                	mv	a0,s5
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	f22080e7          	jalr	-222(ra) # 8000142e <uvmdealloc>
      return 0;
    80001514:	4501                	li	a0,0
    80001516:	bfd1                	j	800014ea <uvmalloc+0x74>
    return oldsz;
    80001518:	852e                	mv	a0,a1
}
    8000151a:	8082                	ret
  return newsz;
    8000151c:	8532                	mv	a0,a2
    8000151e:	b7f1                	j	800014ea <uvmalloc+0x74>

0000000080001520 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001520:	7179                	addi	sp,sp,-48
    80001522:	f406                	sd	ra,40(sp)
    80001524:	f022                	sd	s0,32(sp)
    80001526:	ec26                	sd	s1,24(sp)
    80001528:	e84a                	sd	s2,16(sp)
    8000152a:	e44e                	sd	s3,8(sp)
    8000152c:	e052                	sd	s4,0(sp)
    8000152e:	1800                	addi	s0,sp,48
    80001530:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001532:	84aa                	mv	s1,a0
    80001534:	6905                	lui	s2,0x1
    80001536:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001538:	4985                	li	s3,1
    8000153a:	a829                	j	80001554 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000153c:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000153e:	00c79513          	slli	a0,a5,0xc
    80001542:	00000097          	auipc	ra,0x0
    80001546:	fde080e7          	jalr	-34(ra) # 80001520 <freewalk>
      pagetable[i] = 0;  
    8000154a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000154e:	04a1                	addi	s1,s1,8
    80001550:	03248163          	beq	s1,s2,80001572 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001554:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001556:	00f7f713          	andi	a4,a5,15
    8000155a:	ff3701e3          	beq	a4,s3,8000153c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000155e:	8b85                	andi	a5,a5,1
    80001560:	d7fd                	beqz	a5,8000154e <freewalk+0x2e>
      panic("freewalk: leaf");
    80001562:	00007517          	auipc	a0,0x7
    80001566:	c0650513          	addi	a0,a0,-1018 # 80008168 <digits+0x128>
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	fdc080e7          	jalr	-36(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    80001572:	8552                	mv	a0,s4
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	49e080e7          	jalr	1182(ra) # 80000a12 <kfree>
}
    8000157c:	70a2                	ld	ra,40(sp)
    8000157e:	7402                	ld	s0,32(sp)
    80001580:	64e2                	ld	s1,24(sp)
    80001582:	6942                	ld	s2,16(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6a02                	ld	s4,0(sp)
    80001588:	6145                	addi	sp,sp,48
    8000158a:	8082                	ret

000000008000158c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000158c:	1101                	addi	sp,sp,-32
    8000158e:	ec06                	sd	ra,24(sp)
    80001590:	e822                	sd	s0,16(sp)
    80001592:	e426                	sd	s1,8(sp)
    80001594:	1000                	addi	s0,sp,32
    80001596:	84aa                	mv	s1,a0
  if(sz > 0)
    80001598:	e999                	bnez	a1,800015ae <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000159a:	8526                	mv	a0,s1
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	f84080e7          	jalr	-124(ra) # 80001520 <freewalk>
}
    800015a4:	60e2                	ld	ra,24(sp)
    800015a6:	6442                	ld	s0,16(sp)
    800015a8:	64a2                	ld	s1,8(sp)
    800015aa:	6105                	addi	sp,sp,32
    800015ac:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015ae:	6785                	lui	a5,0x1
    800015b0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015b2:	95be                	add	a1,a1,a5
    800015b4:	4685                	li	a3,1
    800015b6:	00c5d613          	srli	a2,a1,0xc
    800015ba:	4581                	li	a1,0
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	d0e080e7          	jalr	-754(ra) # 800012ca <uvmunmap>
    800015c4:	bfd9                	j	8000159a <uvmfree+0xe>

00000000800015c6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	c679                	beqz	a2,80001694 <uvmcopy+0xce>
{
    800015c8:	715d                	addi	sp,sp,-80
    800015ca:	e486                	sd	ra,72(sp)
    800015cc:	e0a2                	sd	s0,64(sp)
    800015ce:	fc26                	sd	s1,56(sp)
    800015d0:	f84a                	sd	s2,48(sp)
    800015d2:	f44e                	sd	s3,40(sp)
    800015d4:	f052                	sd	s4,32(sp)
    800015d6:	ec56                	sd	s5,24(sp)
    800015d8:	e85a                	sd	s6,16(sp)
    800015da:	e45e                	sd	s7,8(sp)
    800015dc:	0880                	addi	s0,sp,80
    800015de:	8b2a                	mv	s6,a0
    800015e0:	8aae                	mv	s5,a1
    800015e2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015e4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015e6:	4601                	li	a2,0
    800015e8:	85ce                	mv	a1,s3
    800015ea:	855a                	mv	a0,s6
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	a00080e7          	jalr	-1536(ra) # 80000fec <walk>
    800015f4:	c531                	beqz	a0,80001640 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015f6:	6118                	ld	a4,0(a0)
    800015f8:	00177793          	andi	a5,a4,1
    800015fc:	cbb1                	beqz	a5,80001650 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015fe:	00a75593          	srli	a1,a4,0xa
    80001602:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001606:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	506080e7          	jalr	1286(ra) # 80000b10 <kalloc>
    80001612:	892a                	mv	s2,a0
    80001614:	c939                	beqz	a0,8000166a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001616:	6605                	lui	a2,0x1
    80001618:	85de                	mv	a1,s7
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	73e080e7          	jalr	1854(ra) # 80000d58 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001622:	8726                	mv	a4,s1
    80001624:	86ca                	mv	a3,s2
    80001626:	6605                	lui	a2,0x1
    80001628:	85ce                	mv	a1,s3
    8000162a:	8556                	mv	a0,s5
    8000162c:	00000097          	auipc	ra,0x0
    80001630:	b06080e7          	jalr	-1274(ra) # 80001132 <mappages>
    80001634:	e515                	bnez	a0,80001660 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	6785                	lui	a5,0x1
    80001638:	99be                	add	s3,s3,a5
    8000163a:	fb49e6e3          	bltu	s3,s4,800015e6 <uvmcopy+0x20>
    8000163e:	a081                	j	8000167e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001640:	00007517          	auipc	a0,0x7
    80001644:	b3850513          	addi	a0,a0,-1224 # 80008178 <digits+0x138>
    80001648:	fffff097          	auipc	ra,0xfffff
    8000164c:	efe080e7          	jalr	-258(ra) # 80000546 <panic>
      panic("uvmcopy: page not present");
    80001650:	00007517          	auipc	a0,0x7
    80001654:	b4850513          	addi	a0,a0,-1208 # 80008198 <digits+0x158>
    80001658:	fffff097          	auipc	ra,0xfffff
    8000165c:	eee080e7          	jalr	-274(ra) # 80000546 <panic>
      kfree(mem);
    80001660:	854a                	mv	a0,s2
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	3b0080e7          	jalr	944(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000166a:	4685                	li	a3,1
    8000166c:	00c9d613          	srli	a2,s3,0xc
    80001670:	4581                	li	a1,0
    80001672:	8556                	mv	a0,s5
    80001674:	00000097          	auipc	ra,0x0
    80001678:	c56080e7          	jalr	-938(ra) # 800012ca <uvmunmap>
  return -1;
    8000167c:	557d                	li	a0,-1
}
    8000167e:	60a6                	ld	ra,72(sp)
    80001680:	6406                	ld	s0,64(sp)
    80001682:	74e2                	ld	s1,56(sp)
    80001684:	7942                	ld	s2,48(sp)
    80001686:	79a2                	ld	s3,40(sp)
    80001688:	7a02                	ld	s4,32(sp)
    8000168a:	6ae2                	ld	s5,24(sp)
    8000168c:	6b42                	ld	s6,16(sp)
    8000168e:	6ba2                	ld	s7,8(sp)
    80001690:	6161                	addi	sp,sp,80
    80001692:	8082                	ret
  return 0;
    80001694:	4501                	li	a0,0
}
    80001696:	8082                	ret

0000000080001698 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001698:	1141                	addi	sp,sp,-16
    8000169a:	e406                	sd	ra,8(sp)
    8000169c:	e022                	sd	s0,0(sp)
    8000169e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016a0:	4601                	li	a2,0
    800016a2:	00000097          	auipc	ra,0x0
    800016a6:	94a080e7          	jalr	-1718(ra) # 80000fec <walk>
  if(pte == 0)
    800016aa:	c901                	beqz	a0,800016ba <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016ac:	611c                	ld	a5,0(a0)
    800016ae:	9bbd                	andi	a5,a5,-17
    800016b0:	e11c                	sd	a5,0(a0)
}
    800016b2:	60a2                	ld	ra,8(sp)
    800016b4:	6402                	ld	s0,0(sp)
    800016b6:	0141                	addi	sp,sp,16
    800016b8:	8082                	ret
    panic("uvmclear");
    800016ba:	00007517          	auipc	a0,0x7
    800016be:	afe50513          	addi	a0,a0,-1282 # 800081b8 <digits+0x178>
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	e84080e7          	jalr	-380(ra) # 80000546 <panic>

00000000800016ca <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	c6bd                	beqz	a3,80001738 <copyout+0x6e>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8c2e                	mv	s8,a1
    800016e8:	8a32                	mv	s4,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a015                	j	80001714 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016f2:	9562                	add	a0,a0,s8
    800016f4:	0004861b          	sext.w	a2,s1
    800016f8:	85d2                	mv	a1,s4
    800016fa:	41250533          	sub	a0,a0,s2
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	65a080e7          	jalr	1626(ra) # 80000d58 <memmove>

    len -= n;
    80001706:	409989b3          	sub	s3,s3,s1
    src += n;
    8000170a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000170c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001710:	02098263          	beqz	s3,80001734 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001714:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001718:	85ca                	mv	a1,s2
    8000171a:	855a                	mv	a0,s6
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	976080e7          	jalr	-1674(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    80001724:	cd01                	beqz	a0,8000173c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001726:	418904b3          	sub	s1,s2,s8
    8000172a:	94d6                	add	s1,s1,s5
    8000172c:	fc99f3e3          	bgeu	s3,s1,800016f2 <copyout+0x28>
    80001730:	84ce                	mv	s1,s3
    80001732:	b7c1                	j	800016f2 <copyout+0x28>
  }
  return 0;
    80001734:	4501                	li	a0,0
    80001736:	a021                	j	8000173e <copyout+0x74>
    80001738:	4501                	li	a0,0
}
    8000173a:	8082                	ret
      return -1;
    8000173c:	557d                	li	a0,-1
}
    8000173e:	60a6                	ld	ra,72(sp)
    80001740:	6406                	ld	s0,64(sp)
    80001742:	74e2                	ld	s1,56(sp)
    80001744:	7942                	ld	s2,48(sp)
    80001746:	79a2                	ld	s3,40(sp)
    80001748:	7a02                	ld	s4,32(sp)
    8000174a:	6ae2                	ld	s5,24(sp)
    8000174c:	6b42                	ld	s6,16(sp)
    8000174e:	6ba2                	ld	s7,8(sp)
    80001750:	6c02                	ld	s8,0(sp)
    80001752:	6161                	addi	sp,sp,80
    80001754:	8082                	ret

0000000080001756 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001756:	caa5                	beqz	a3,800017c6 <copyin+0x70>
{
    80001758:	715d                	addi	sp,sp,-80
    8000175a:	e486                	sd	ra,72(sp)
    8000175c:	e0a2                	sd	s0,64(sp)
    8000175e:	fc26                	sd	s1,56(sp)
    80001760:	f84a                	sd	s2,48(sp)
    80001762:	f44e                	sd	s3,40(sp)
    80001764:	f052                	sd	s4,32(sp)
    80001766:	ec56                	sd	s5,24(sp)
    80001768:	e85a                	sd	s6,16(sp)
    8000176a:	e45e                	sd	s7,8(sp)
    8000176c:	e062                	sd	s8,0(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8b2a                	mv	s6,a0
    80001772:	8a2e                	mv	s4,a1
    80001774:	8c32                	mv	s8,a2
    80001776:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6a85                	lui	s5,0x1
    8000177c:	a01d                	j	800017a2 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000177e:	018505b3          	add	a1,a0,s8
    80001782:	0004861b          	sext.w	a2,s1
    80001786:	412585b3          	sub	a1,a1,s2
    8000178a:	8552                	mv	a0,s4
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	5cc080e7          	jalr	1484(ra) # 80000d58 <memmove>

    len -= n;
    80001794:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001798:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000179a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000179e:	02098263          	beqz	s3,800017c2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017a6:	85ca                	mv	a1,s2
    800017a8:	855a                	mv	a0,s6
    800017aa:	00000097          	auipc	ra,0x0
    800017ae:	8e8080e7          	jalr	-1816(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800017b2:	cd01                	beqz	a0,800017ca <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017b4:	418904b3          	sub	s1,s2,s8
    800017b8:	94d6                	add	s1,s1,s5
    800017ba:	fc99f2e3          	bgeu	s3,s1,8000177e <copyin+0x28>
    800017be:	84ce                	mv	s1,s3
    800017c0:	bf7d                	j	8000177e <copyin+0x28>
  }
  return 0;
    800017c2:	4501                	li	a0,0
    800017c4:	a021                	j	800017cc <copyin+0x76>
    800017c6:	4501                	li	a0,0
}
    800017c8:	8082                	ret
      return -1;
    800017ca:	557d                	li	a0,-1
}
    800017cc:	60a6                	ld	ra,72(sp)
    800017ce:	6406                	ld	s0,64(sp)
    800017d0:	74e2                	ld	s1,56(sp)
    800017d2:	7942                	ld	s2,48(sp)
    800017d4:	79a2                	ld	s3,40(sp)
    800017d6:	7a02                	ld	s4,32(sp)
    800017d8:	6ae2                	ld	s5,24(sp)
    800017da:	6b42                	ld	s6,16(sp)
    800017dc:	6ba2                	ld	s7,8(sp)
    800017de:	6c02                	ld	s8,0(sp)
    800017e0:	6161                	addi	sp,sp,80
    800017e2:	8082                	ret

00000000800017e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017e4:	c2dd                	beqz	a3,8000188a <copyinstr+0xa6>
{
    800017e6:	715d                	addi	sp,sp,-80
    800017e8:	e486                	sd	ra,72(sp)
    800017ea:	e0a2                	sd	s0,64(sp)
    800017ec:	fc26                	sd	s1,56(sp)
    800017ee:	f84a                	sd	s2,48(sp)
    800017f0:	f44e                	sd	s3,40(sp)
    800017f2:	f052                	sd	s4,32(sp)
    800017f4:	ec56                	sd	s5,24(sp)
    800017f6:	e85a                	sd	s6,16(sp)
    800017f8:	e45e                	sd	s7,8(sp)
    800017fa:	0880                	addi	s0,sp,80
    800017fc:	8a2a                	mv	s4,a0
    800017fe:	8b2e                	mv	s6,a1
    80001800:	8bb2                	mv	s7,a2
    80001802:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001804:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001806:	6985                	lui	s3,0x1
    80001808:	a02d                	j	80001832 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000180a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000180e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001810:	37fd                	addiw	a5,a5,-1
    80001812:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001816:	60a6                	ld	ra,72(sp)
    80001818:	6406                	ld	s0,64(sp)
    8000181a:	74e2                	ld	s1,56(sp)
    8000181c:	7942                	ld	s2,48(sp)
    8000181e:	79a2                	ld	s3,40(sp)
    80001820:	7a02                	ld	s4,32(sp)
    80001822:	6ae2                	ld	s5,24(sp)
    80001824:	6b42                	ld	s6,16(sp)
    80001826:	6ba2                	ld	s7,8(sp)
    80001828:	6161                	addi	sp,sp,80
    8000182a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000182c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001830:	c8a9                	beqz	s1,80001882 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001832:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001836:	85ca                	mv	a1,s2
    80001838:	8552                	mv	a0,s4
    8000183a:	00000097          	auipc	ra,0x0
    8000183e:	858080e7          	jalr	-1960(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    80001842:	c131                	beqz	a0,80001886 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001844:	417906b3          	sub	a3,s2,s7
    80001848:	96ce                	add	a3,a3,s3
    8000184a:	00d4f363          	bgeu	s1,a3,80001850 <copyinstr+0x6c>
    8000184e:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001850:	955e                	add	a0,a0,s7
    80001852:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001856:	daf9                	beqz	a3,8000182c <copyinstr+0x48>
    80001858:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000185a:	41650633          	sub	a2,a0,s6
    8000185e:	fff48593          	addi	a1,s1,-1
    80001862:	95da                	add	a1,a1,s6
    while(n > 0){
    80001864:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001866:	00f60733          	add	a4,a2,a5
    8000186a:	00074703          	lbu	a4,0(a4)
    8000186e:	df51                	beqz	a4,8000180a <copyinstr+0x26>
        *dst = *p;
    80001870:	00e78023          	sb	a4,0(a5)
      --max;
    80001874:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001878:	0785                	addi	a5,a5,1
    while(n > 0){
    8000187a:	fed796e3          	bne	a5,a3,80001866 <copyinstr+0x82>
      dst++;
    8000187e:	8b3e                	mv	s6,a5
    80001880:	b775                	j	8000182c <copyinstr+0x48>
    80001882:	4781                	li	a5,0
    80001884:	b771                	j	80001810 <copyinstr+0x2c>
      return -1;
    80001886:	557d                	li	a0,-1
    80001888:	b779                	j	80001816 <copyinstr+0x32>
  int got_null = 0;
    8000188a:	4781                	li	a5,0
  if(got_null){
    8000188c:	37fd                	addiw	a5,a5,-1
    8000188e:	0007851b          	sext.w	a0,a5
}
    80001892:	8082                	ret

0000000080001894 <test_pagetable>:

// check if use global kpgtbl or not 
int 
test_pagetable()
{
    80001894:	1141                	addi	sp,sp,-16
    80001896:	e422                	sd	s0,8(sp)
    80001898:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000189a:	18002773          	csrr	a4,satp
  uint64 satp = r_satp();
  uint64 gsatp = MAKE_SATP(kernel_pagetable);
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	77253503          	ld	a0,1906(a0) # 80009010 <kernel_pagetable>
    800018a6:	8131                	srli	a0,a0,0xc
    800018a8:	57fd                	li	a5,-1
    800018aa:	17fe                	slli	a5,a5,0x3f
    800018ac:	8d5d                	or	a0,a0,a5
  return satp != gsatp;
    800018ae:	8d19                	sub	a0,a0,a4
}
    800018b0:	00a03533          	snez	a0,a0
    800018b4:	6422                	ld	s0,8(sp)
    800018b6:	0141                	addi	sp,sp,16
    800018b8:	8082                	ret

00000000800018ba <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ba:	1101                	addi	sp,sp,-32
    800018bc:	ec06                	sd	ra,24(sp)
    800018be:	e822                	sd	s0,16(sp)
    800018c0:	e426                	sd	s1,8(sp)
    800018c2:	1000                	addi	s0,sp,32
    800018c4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	2c0080e7          	jalr	704(ra) # 80000b86 <holding>
    800018ce:	c909                	beqz	a0,800018e0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018d0:	749c                	ld	a5,40(s1)
    800018d2:	00978f63          	beq	a5,s1,800018f0 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018d6:	60e2                	ld	ra,24(sp)
    800018d8:	6442                	ld	s0,16(sp)
    800018da:	64a2                	ld	s1,8(sp)
    800018dc:	6105                	addi	sp,sp,32
    800018de:	8082                	ret
    panic("wakeup1");
    800018e0:	00007517          	auipc	a0,0x7
    800018e4:	8e850513          	addi	a0,a0,-1816 # 800081c8 <digits+0x188>
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	c5e080e7          	jalr	-930(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018f0:	4c98                	lw	a4,24(s1)
    800018f2:	4785                	li	a5,1
    800018f4:	fef711e3          	bne	a4,a5,800018d6 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018f8:	4789                	li	a5,2
    800018fa:	cc9c                	sw	a5,24(s1)
}
    800018fc:	bfe9                	j	800018d6 <wakeup1+0x1c>

00000000800018fe <procinit>:
{
    800018fe:	715d                	addi	sp,sp,-80
    80001900:	e486                	sd	ra,72(sp)
    80001902:	e0a2                	sd	s0,64(sp)
    80001904:	fc26                	sd	s1,56(sp)
    80001906:	f84a                	sd	s2,48(sp)
    80001908:	f44e                	sd	s3,40(sp)
    8000190a:	f052                	sd	s4,32(sp)
    8000190c:	ec56                	sd	s5,24(sp)
    8000190e:	e85a                	sd	s6,16(sp)
    80001910:	e45e                	sd	s7,8(sp)
    80001912:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001914:	00007597          	auipc	a1,0x7
    80001918:	8bc58593          	addi	a1,a1,-1860 # 800081d0 <digits+0x190>
    8000191c:	00010517          	auipc	a0,0x10
    80001920:	03450513          	addi	a0,a0,52 # 80011950 <pid_lock>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	24c080e7          	jalr	588(ra) # 80000b70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192c:	00010917          	auipc	s2,0x10
    80001930:	43c90913          	addi	s2,s2,1084 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001934:	00007b97          	auipc	s7,0x7
    80001938:	8a4b8b93          	addi	s7,s7,-1884 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000193c:	8b4a                	mv	s6,s2
    8000193e:	00006a97          	auipc	s5,0x6
    80001942:	6c2a8a93          	addi	s5,s5,1730 # 80008000 <etext>
    80001946:	040009b7          	lui	s3,0x4000
    8000194a:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000194c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194e:	00016a17          	auipc	s4,0x16
    80001952:	e1aa0a13          	addi	s4,s4,-486 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001956:	85de                	mv	a1,s7
    80001958:	854a                	mv	a0,s2
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	216080e7          	jalr	534(ra) # 80000b70 <initlock>
      char *pa = kalloc();
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	1ae080e7          	jalr	430(ra) # 80000b10 <kalloc>
    8000196a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000196c:	c929                	beqz	a0,800019be <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000196e:	416904b3          	sub	s1,s2,s6
    80001972:	848d                	srai	s1,s1,0x3
    80001974:	000ab783          	ld	a5,0(s5)
    80001978:	02f484b3          	mul	s1,s1,a5
    8000197c:	2485                	addiw	s1,s1,1
    8000197e:	00d4949b          	slliw	s1,s1,0xd
    80001982:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001986:	4699                	li	a3,6
    80001988:	6605                	lui	a2,0x1
    8000198a:	8526                	mv	a0,s1
    8000198c:	00000097          	auipc	ra,0x0
    80001990:	834080e7          	jalr	-1996(ra) # 800011c0 <kvmmap>
      p->kstack = va;
    80001994:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001998:	16890913          	addi	s2,s2,360
    8000199c:	fb491de3          	bne	s2,s4,80001956 <procinit+0x58>
  kvminithart();
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	628080e7          	jalr	1576(ra) # 80000fc8 <kvminithart>
}
    800019a8:	60a6                	ld	ra,72(sp)
    800019aa:	6406                	ld	s0,64(sp)
    800019ac:	74e2                	ld	s1,56(sp)
    800019ae:	7942                	ld	s2,48(sp)
    800019b0:	79a2                	ld	s3,40(sp)
    800019b2:	7a02                	ld	s4,32(sp)
    800019b4:	6ae2                	ld	s5,24(sp)
    800019b6:	6b42                	ld	s6,16(sp)
    800019b8:	6ba2                	ld	s7,8(sp)
    800019ba:	6161                	addi	sp,sp,80
    800019bc:	8082                	ret
        panic("kalloc");
    800019be:	00007517          	auipc	a0,0x7
    800019c2:	82250513          	addi	a0,a0,-2014 # 800081e0 <digits+0x1a0>
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	b80080e7          	jalr	-1152(ra) # 80000546 <panic>

00000000800019ce <cpuid>:
{
    800019ce:	1141                	addi	sp,sp,-16
    800019d0:	e422                	sd	s0,8(sp)
    800019d2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d4:	8512                	mv	a0,tp
}
    800019d6:	2501                	sext.w	a0,a0
    800019d8:	6422                	ld	s0,8(sp)
    800019da:	0141                	addi	sp,sp,16
    800019dc:	8082                	ret

00000000800019de <mycpu>:
mycpu(void) {
    800019de:	1141                	addi	sp,sp,-16
    800019e0:	e422                	sd	s0,8(sp)
    800019e2:	0800                	addi	s0,sp,16
    800019e4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019e6:	2781                	sext.w	a5,a5
    800019e8:	079e                	slli	a5,a5,0x7
}
    800019ea:	00010517          	auipc	a0,0x10
    800019ee:	f7e50513          	addi	a0,a0,-130 # 80011968 <cpus>
    800019f2:	953e                	add	a0,a0,a5
    800019f4:	6422                	ld	s0,8(sp)
    800019f6:	0141                	addi	sp,sp,16
    800019f8:	8082                	ret

00000000800019fa <myproc>:
myproc(void) {
    800019fa:	1101                	addi	sp,sp,-32
    800019fc:	ec06                	sd	ra,24(sp)
    800019fe:	e822                	sd	s0,16(sp)
    80001a00:	e426                	sd	s1,8(sp)
    80001a02:	1000                	addi	s0,sp,32
  push_off();
    80001a04:	fffff097          	auipc	ra,0xfffff
    80001a08:	1b0080e7          	jalr	432(ra) # 80000bb4 <push_off>
    80001a0c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a0e:	2781                	sext.w	a5,a5
    80001a10:	079e                	slli	a5,a5,0x7
    80001a12:	00010717          	auipc	a4,0x10
    80001a16:	f3e70713          	addi	a4,a4,-194 # 80011950 <pid_lock>
    80001a1a:	97ba                	add	a5,a5,a4
    80001a1c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	236080e7          	jalr	566(ra) # 80000c54 <pop_off>
}
    80001a26:	8526                	mv	a0,s1
    80001a28:	60e2                	ld	ra,24(sp)
    80001a2a:	6442                	ld	s0,16(sp)
    80001a2c:	64a2                	ld	s1,8(sp)
    80001a2e:	6105                	addi	sp,sp,32
    80001a30:	8082                	ret

0000000080001a32 <forkret>:
{
    80001a32:	1141                	addi	sp,sp,-16
    80001a34:	e406                	sd	ra,8(sp)
    80001a36:	e022                	sd	s0,0(sp)
    80001a38:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a3a:	00000097          	auipc	ra,0x0
    80001a3e:	fc0080e7          	jalr	-64(ra) # 800019fa <myproc>
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	272080e7          	jalr	626(ra) # 80000cb4 <release>
  if (first) {
    80001a4a:	00007797          	auipc	a5,0x7
    80001a4e:	e667a783          	lw	a5,-410(a5) # 800088b0 <first.1>
    80001a52:	eb89                	bnez	a5,80001a64 <forkret+0x32>
  usertrapret();
    80001a54:	00001097          	auipc	ra,0x1
    80001a58:	c1a080e7          	jalr	-998(ra) # 8000266e <usertrapret>
}
    80001a5c:	60a2                	ld	ra,8(sp)
    80001a5e:	6402                	ld	s0,0(sp)
    80001a60:	0141                	addi	sp,sp,16
    80001a62:	8082                	ret
    first = 0;
    80001a64:	00007797          	auipc	a5,0x7
    80001a68:	e407a623          	sw	zero,-436(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001a6c:	4505                	li	a0,1
    80001a6e:	00002097          	auipc	ra,0x2
    80001a72:	958080e7          	jalr	-1704(ra) # 800033c6 <fsinit>
    80001a76:	bff9                	j	80001a54 <forkret+0x22>

0000000080001a78 <allocpid>:
allocpid() {
    80001a78:	1101                	addi	sp,sp,-32
    80001a7a:	ec06                	sd	ra,24(sp)
    80001a7c:	e822                	sd	s0,16(sp)
    80001a7e:	e426                	sd	s1,8(sp)
    80001a80:	e04a                	sd	s2,0(sp)
    80001a82:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a84:	00010917          	auipc	s2,0x10
    80001a88:	ecc90913          	addi	s2,s2,-308 # 80011950 <pid_lock>
    80001a8c:	854a                	mv	a0,s2
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	172080e7          	jalr	370(ra) # 80000c00 <acquire>
  pid = nextpid;
    80001a96:	00007797          	auipc	a5,0x7
    80001a9a:	e1e78793          	addi	a5,a5,-482 # 800088b4 <nextpid>
    80001a9e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa0:	0014871b          	addiw	a4,s1,1
    80001aa4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa6:	854a                	mv	a0,s2
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	20c080e7          	jalr	524(ra) # 80000cb4 <release>
}
    80001ab0:	8526                	mv	a0,s1
    80001ab2:	60e2                	ld	ra,24(sp)
    80001ab4:	6442                	ld	s0,16(sp)
    80001ab6:	64a2                	ld	s1,8(sp)
    80001ab8:	6902                	ld	s2,0(sp)
    80001aba:	6105                	addi	sp,sp,32
    80001abc:	8082                	ret

0000000080001abe <proc_pagetable>:
{
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	e04a                	sd	s2,0(sp)
    80001ac8:	1000                	addi	s0,sp,32
    80001aca:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001acc:	00000097          	auipc	ra,0x0
    80001ad0:	8c2080e7          	jalr	-1854(ra) # 8000138e <uvmcreate>
    80001ad4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad6:	c121                	beqz	a0,80001b16 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad8:	4729                	li	a4,10
    80001ada:	00005697          	auipc	a3,0x5
    80001ade:	52668693          	addi	a3,a3,1318 # 80007000 <_trampoline>
    80001ae2:	6605                	lui	a2,0x1
    80001ae4:	040005b7          	lui	a1,0x4000
    80001ae8:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001aea:	05b2                	slli	a1,a1,0xc
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	646080e7          	jalr	1606(ra) # 80001132 <mappages>
    80001af4:	02054863          	bltz	a0,80001b24 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af8:	4719                	li	a4,6
    80001afa:	05893683          	ld	a3,88(s2)
    80001afe:	6605                	lui	a2,0x1
    80001b00:	020005b7          	lui	a1,0x2000
    80001b04:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b06:	05b6                	slli	a1,a1,0xd
    80001b08:	8526                	mv	a0,s1
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	628080e7          	jalr	1576(ra) # 80001132 <mappages>
    80001b12:	02054163          	bltz	a0,80001b34 <proc_pagetable+0x76>
}
    80001b16:	8526                	mv	a0,s1
    80001b18:	60e2                	ld	ra,24(sp)
    80001b1a:	6442                	ld	s0,16(sp)
    80001b1c:	64a2                	ld	s1,8(sp)
    80001b1e:	6902                	ld	s2,0(sp)
    80001b20:	6105                	addi	sp,sp,32
    80001b22:	8082                	ret
    uvmfree(pagetable, 0);
    80001b24:	4581                	li	a1,0
    80001b26:	8526                	mv	a0,s1
    80001b28:	00000097          	auipc	ra,0x0
    80001b2c:	a64080e7          	jalr	-1436(ra) # 8000158c <uvmfree>
    return 0;
    80001b30:	4481                	li	s1,0
    80001b32:	b7d5                	j	80001b16 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	040005b7          	lui	a1,0x4000
    80001b3c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3e:	05b2                	slli	a1,a1,0xc
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	788080e7          	jalr	1928(ra) # 800012ca <uvmunmap>
    uvmfree(pagetable, 0);
    80001b4a:	4581                	li	a1,0
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	a3e080e7          	jalr	-1474(ra) # 8000158c <uvmfree>
    return 0;
    80001b56:	4481                	li	s1,0
    80001b58:	bf7d                	j	80001b16 <proc_pagetable+0x58>

0000000080001b5a <proc_freepagetable>:
{
    80001b5a:	1101                	addi	sp,sp,-32
    80001b5c:	ec06                	sd	ra,24(sp)
    80001b5e:	e822                	sd	s0,16(sp)
    80001b60:	e426                	sd	s1,8(sp)
    80001b62:	e04a                	sd	s2,0(sp)
    80001b64:	1000                	addi	s0,sp,32
    80001b66:	84aa                	mv	s1,a0
    80001b68:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b6a:	4681                	li	a3,0
    80001b6c:	4605                	li	a2,1
    80001b6e:	040005b7          	lui	a1,0x4000
    80001b72:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b74:	05b2                	slli	a1,a1,0xc
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	754080e7          	jalr	1876(ra) # 800012ca <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7e:	4681                	li	a3,0
    80001b80:	4605                	li	a2,1
    80001b82:	020005b7          	lui	a1,0x2000
    80001b86:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b88:	05b6                	slli	a1,a1,0xd
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	73e080e7          	jalr	1854(ra) # 800012ca <uvmunmap>
  uvmfree(pagetable, sz);
    80001b94:	85ca                	mv	a1,s2
    80001b96:	8526                	mv	a0,s1
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	9f4080e7          	jalr	-1548(ra) # 8000158c <uvmfree>
}
    80001ba0:	60e2                	ld	ra,24(sp)
    80001ba2:	6442                	ld	s0,16(sp)
    80001ba4:	64a2                	ld	s1,8(sp)
    80001ba6:	6902                	ld	s2,0(sp)
    80001ba8:	6105                	addi	sp,sp,32
    80001baa:	8082                	ret

0000000080001bac <freeproc>:
{
    80001bac:	1101                	addi	sp,sp,-32
    80001bae:	ec06                	sd	ra,24(sp)
    80001bb0:	e822                	sd	s0,16(sp)
    80001bb2:	e426                	sd	s1,8(sp)
    80001bb4:	1000                	addi	s0,sp,32
    80001bb6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb8:	6d28                	ld	a0,88(a0)
    80001bba:	c509                	beqz	a0,80001bc4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	e56080e7          	jalr	-426(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001bc4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc8:	68a8                	ld	a0,80(s1)
    80001bca:	c511                	beqz	a0,80001bd6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bcc:	64ac                	ld	a1,72(s1)
    80001bce:	00000097          	auipc	ra,0x0
    80001bd2:	f8c080e7          	jalr	-116(ra) # 80001b5a <proc_freepagetable>
  p->pagetable = 0;
    80001bd6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bda:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bde:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001be2:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001be6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bea:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bee:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bf2:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bf6:	0004ac23          	sw	zero,24(s1)
}
    80001bfa:	60e2                	ld	ra,24(sp)
    80001bfc:	6442                	ld	s0,16(sp)
    80001bfe:	64a2                	ld	s1,8(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <allocproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	00010497          	auipc	s1,0x10
    80001c14:	15848493          	addi	s1,s1,344 # 80011d68 <proc>
    80001c18:	00016917          	auipc	s2,0x16
    80001c1c:	b5090913          	addi	s2,s2,-1200 # 80017768 <tickslock>
    acquire(&p->lock);
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	fde080e7          	jalr	-34(ra) # 80000c00 <acquire>
    if(p->state == UNUSED) {
    80001c2a:	4c9c                	lw	a5,24(s1)
    80001c2c:	cf81                	beqz	a5,80001c44 <allocproc+0x40>
      release(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	084080e7          	jalr	132(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c38:	16848493          	addi	s1,s1,360
    80001c3c:	ff2492e3          	bne	s1,s2,80001c20 <allocproc+0x1c>
  return 0;
    80001c40:	4481                	li	s1,0
    80001c42:	a0b9                	j	80001c90 <allocproc+0x8c>
  p->pid = allocpid();
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e34080e7          	jalr	-460(ra) # 80001a78 <allocpid>
    80001c4c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	ec2080e7          	jalr	-318(ra) # 80000b10 <kalloc>
    80001c56:	892a                	mv	s2,a0
    80001c58:	eca8                	sd	a0,88(s1)
    80001c5a:	c131                	beqz	a0,80001c9e <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	e60080e7          	jalr	-416(ra) # 80001abe <proc_pagetable>
    80001c66:	892a                	mv	s2,a0
    80001c68:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6a:	c129                	beqz	a0,80001cac <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c6c:	07000613          	li	a2,112
    80001c70:	4581                	li	a1,0
    80001c72:	06048513          	addi	a0,s1,96
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	086080e7          	jalr	134(ra) # 80000cfc <memset>
  p->context.ra = (uint64)forkret;
    80001c7e:	00000797          	auipc	a5,0x0
    80001c82:	db478793          	addi	a5,a5,-588 # 80001a32 <forkret>
    80001c86:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c88:	60bc                	ld	a5,64(s1)
    80001c8a:	6705                	lui	a4,0x1
    80001c8c:	97ba                	add	a5,a5,a4
    80001c8e:	f4bc                	sd	a5,104(s1)
}
    80001c90:	8526                	mv	a0,s1
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6902                	ld	s2,0(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	014080e7          	jalr	20(ra) # 80000cb4 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7dd                	j	80001c90 <allocproc+0x8c>
    freeproc(p);
    80001cac:	8526                	mv	a0,s1
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	efe080e7          	jalr	-258(ra) # 80001bac <freeproc>
    release(&p->lock);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	ffc080e7          	jalr	-4(ra) # 80000cb4 <release>
    return 0;
    80001cc0:	84ca                	mv	s1,s2
    80001cc2:	b7f9                	j	80001c90 <allocproc+0x8c>

0000000080001cc4 <userinit>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	f36080e7          	jalr	-202(ra) # 80001c04 <allocproc>
    80001cd6:	84aa                	mv	s1,a0
  initproc = p;
    80001cd8:	00007797          	auipc	a5,0x7
    80001cdc:	34a7b023          	sd	a0,832(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ce0:	03400613          	li	a2,52
    80001ce4:	00007597          	auipc	a1,0x7
    80001ce8:	bdc58593          	addi	a1,a1,-1060 # 800088c0 <initcode>
    80001cec:	6928                	ld	a0,80(a0)
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	6ce080e7          	jalr	1742(ra) # 800013bc <uvminit>
  p->sz = PGSIZE;
    80001cf6:	6785                	lui	a5,0x1
    80001cf8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cfa:	6cb8                	ld	a4,88(s1)
    80001cfc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d00:	6cb8                	ld	a4,88(s1)
    80001d02:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d04:	4641                	li	a2,16
    80001d06:	00006597          	auipc	a1,0x6
    80001d0a:	4e258593          	addi	a1,a1,1250 # 800081e8 <digits+0x1a8>
    80001d0e:	15848513          	addi	a0,s1,344
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	13c080e7          	jalr	316(ra) # 80000e4e <safestrcpy>
  p->cwd = namei("/");
    80001d1a:	00006517          	auipc	a0,0x6
    80001d1e:	4de50513          	addi	a0,a0,1246 # 800081f8 <digits+0x1b8>
    80001d22:	00002097          	auipc	ra,0x2
    80001d26:	0d4080e7          	jalr	212(ra) # 80003df6 <namei>
    80001d2a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d2e:	4789                	li	a5,2
    80001d30:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	f80080e7          	jalr	-128(ra) # 80000cb4 <release>
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <growproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
    80001d52:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d54:	00000097          	auipc	ra,0x0
    80001d58:	ca6080e7          	jalr	-858(ra) # 800019fa <myproc>
    80001d5c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d5e:	652c                	ld	a1,72(a0)
    80001d60:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d64:	00904f63          	bgtz	s1,80001d82 <growproc+0x3c>
  } else if(n < 0){
    80001d68:	0204cd63          	bltz	s1,80001da2 <growproc+0x5c>
  p->sz = sz;
    80001d6c:	1782                	slli	a5,a5,0x20
    80001d6e:	9381                	srli	a5,a5,0x20
    80001d70:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d74:	4501                	li	a0,0
}
    80001d76:	60e2                	ld	ra,24(sp)
    80001d78:	6442                	ld	s0,16(sp)
    80001d7a:	64a2                	ld	s1,8(sp)
    80001d7c:	6902                	ld	s2,0(sp)
    80001d7e:	6105                	addi	sp,sp,32
    80001d80:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d82:	00f4863b          	addw	a2,s1,a5
    80001d86:	1602                	slli	a2,a2,0x20
    80001d88:	9201                	srli	a2,a2,0x20
    80001d8a:	1582                	slli	a1,a1,0x20
    80001d8c:	9181                	srli	a1,a1,0x20
    80001d8e:	6928                	ld	a0,80(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	6e6080e7          	jalr	1766(ra) # 80001476 <uvmalloc>
    80001d98:	0005079b          	sext.w	a5,a0
    80001d9c:	fbe1                	bnez	a5,80001d6c <growproc+0x26>
      return -1;
    80001d9e:	557d                	li	a0,-1
    80001da0:	bfd9                	j	80001d76 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001da2:	00f4863b          	addw	a2,s1,a5
    80001da6:	1602                	slli	a2,a2,0x20
    80001da8:	9201                	srli	a2,a2,0x20
    80001daa:	1582                	slli	a1,a1,0x20
    80001dac:	9181                	srli	a1,a1,0x20
    80001dae:	6928                	ld	a0,80(a0)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	67e080e7          	jalr	1662(ra) # 8000142e <uvmdealloc>
    80001db8:	0005079b          	sext.w	a5,a0
    80001dbc:	bf45                	j	80001d6c <growproc+0x26>

0000000080001dbe <fork>:
{
    80001dbe:	7139                	addi	sp,sp,-64
    80001dc0:	fc06                	sd	ra,56(sp)
    80001dc2:	f822                	sd	s0,48(sp)
    80001dc4:	f426                	sd	s1,40(sp)
    80001dc6:	f04a                	sd	s2,32(sp)
    80001dc8:	ec4e                	sd	s3,24(sp)
    80001dca:	e852                	sd	s4,16(sp)
    80001dcc:	e456                	sd	s5,8(sp)
    80001dce:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	c2a080e7          	jalr	-982(ra) # 800019fa <myproc>
    80001dd8:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	e2a080e7          	jalr	-470(ra) # 80001c04 <allocproc>
    80001de2:	c17d                	beqz	a0,80001ec8 <fork+0x10a>
    80001de4:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001de6:	048ab603          	ld	a2,72(s5)
    80001dea:	692c                	ld	a1,80(a0)
    80001dec:	050ab503          	ld	a0,80(s5)
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	7d6080e7          	jalr	2006(ra) # 800015c6 <uvmcopy>
    80001df8:	04054a63          	bltz	a0,80001e4c <fork+0x8e>
  np->sz = p->sz;
    80001dfc:	048ab783          	ld	a5,72(s5)
    80001e00:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001e04:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e08:	058ab683          	ld	a3,88(s5)
    80001e0c:	87b6                	mv	a5,a3
    80001e0e:	058a3703          	ld	a4,88(s4)
    80001e12:	12068693          	addi	a3,a3,288
    80001e16:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1a:	6788                	ld	a0,8(a5)
    80001e1c:	6b8c                	ld	a1,16(a5)
    80001e1e:	6f90                	ld	a2,24(a5)
    80001e20:	01073023          	sd	a6,0(a4)
    80001e24:	e708                	sd	a0,8(a4)
    80001e26:	eb0c                	sd	a1,16(a4)
    80001e28:	ef10                	sd	a2,24(a4)
    80001e2a:	02078793          	addi	a5,a5,32
    80001e2e:	02070713          	addi	a4,a4,32
    80001e32:	fed792e3          	bne	a5,a3,80001e16 <fork+0x58>
  np->trapframe->a0 = 0;
    80001e36:	058a3783          	ld	a5,88(s4)
    80001e3a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e3e:	0d0a8493          	addi	s1,s5,208
    80001e42:	0d0a0913          	addi	s2,s4,208
    80001e46:	150a8993          	addi	s3,s5,336
    80001e4a:	a00d                	j	80001e6c <fork+0xae>
    freeproc(np);
    80001e4c:	8552                	mv	a0,s4
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	d5e080e7          	jalr	-674(ra) # 80001bac <freeproc>
    release(&np->lock);
    80001e56:	8552                	mv	a0,s4
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	e5c080e7          	jalr	-420(ra) # 80000cb4 <release>
    return -1;
    80001e60:	54fd                	li	s1,-1
    80001e62:	a889                	j	80001eb4 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e64:	04a1                	addi	s1,s1,8
    80001e66:	0921                	addi	s2,s2,8
    80001e68:	01348b63          	beq	s1,s3,80001e7e <fork+0xc0>
    if(p->ofile[i])
    80001e6c:	6088                	ld	a0,0(s1)
    80001e6e:	d97d                	beqz	a0,80001e64 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e70:	00002097          	auipc	ra,0x2
    80001e74:	612080e7          	jalr	1554(ra) # 80004482 <filedup>
    80001e78:	00a93023          	sd	a0,0(s2)
    80001e7c:	b7e5                	j	80001e64 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e7e:	150ab503          	ld	a0,336(s5)
    80001e82:	00001097          	auipc	ra,0x1
    80001e86:	780080e7          	jalr	1920(ra) # 80003602 <idup>
    80001e8a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e8e:	4641                	li	a2,16
    80001e90:	158a8593          	addi	a1,s5,344
    80001e94:	158a0513          	addi	a0,s4,344
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	fb6080e7          	jalr	-74(ra) # 80000e4e <safestrcpy>
  pid = np->pid;
    80001ea0:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001ea4:	4789                	li	a5,2
    80001ea6:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eaa:	8552                	mv	a0,s4
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	e08080e7          	jalr	-504(ra) # 80000cb4 <release>
}
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	70e2                	ld	ra,56(sp)
    80001eb8:	7442                	ld	s0,48(sp)
    80001eba:	74a2                	ld	s1,40(sp)
    80001ebc:	7902                	ld	s2,32(sp)
    80001ebe:	69e2                	ld	s3,24(sp)
    80001ec0:	6a42                	ld	s4,16(sp)
    80001ec2:	6aa2                	ld	s5,8(sp)
    80001ec4:	6121                	addi	sp,sp,64
    80001ec6:	8082                	ret
    return -1;
    80001ec8:	54fd                	li	s1,-1
    80001eca:	b7ed                	j	80001eb4 <fork+0xf6>

0000000080001ecc <reparent>:
{
    80001ecc:	7179                	addi	sp,sp,-48
    80001ece:	f406                	sd	ra,40(sp)
    80001ed0:	f022                	sd	s0,32(sp)
    80001ed2:	ec26                	sd	s1,24(sp)
    80001ed4:	e84a                	sd	s2,16(sp)
    80001ed6:	e44e                	sd	s3,8(sp)
    80001ed8:	e052                	sd	s4,0(sp)
    80001eda:	1800                	addi	s0,sp,48
    80001edc:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ede:	00010497          	auipc	s1,0x10
    80001ee2:	e8a48493          	addi	s1,s1,-374 # 80011d68 <proc>
      pp->parent = initproc;
    80001ee6:	00007a17          	auipc	s4,0x7
    80001eea:	132a0a13          	addi	s4,s4,306 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eee:	00016997          	auipc	s3,0x16
    80001ef2:	87a98993          	addi	s3,s3,-1926 # 80017768 <tickslock>
    80001ef6:	a029                	j	80001f00 <reparent+0x34>
    80001ef8:	16848493          	addi	s1,s1,360
    80001efc:	03348363          	beq	s1,s3,80001f22 <reparent+0x56>
    if(pp->parent == p){
    80001f00:	709c                	ld	a5,32(s1)
    80001f02:	ff279be3          	bne	a5,s2,80001ef8 <reparent+0x2c>
      acquire(&pp->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	cf8080e7          	jalr	-776(ra) # 80000c00 <acquire>
      pp->parent = initproc;
    80001f10:	000a3783          	ld	a5,0(s4)
    80001f14:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d9c080e7          	jalr	-612(ra) # 80000cb4 <release>
    80001f20:	bfe1                	j	80001ef8 <reparent+0x2c>
}
    80001f22:	70a2                	ld	ra,40(sp)
    80001f24:	7402                	ld	s0,32(sp)
    80001f26:	64e2                	ld	s1,24(sp)
    80001f28:	6942                	ld	s2,16(sp)
    80001f2a:	69a2                	ld	s3,8(sp)
    80001f2c:	6a02                	ld	s4,0(sp)
    80001f2e:	6145                	addi	sp,sp,48
    80001f30:	8082                	ret

0000000080001f32 <scheduler>:
{
    80001f32:	715d                	addi	sp,sp,-80
    80001f34:	e486                	sd	ra,72(sp)
    80001f36:	e0a2                	sd	s0,64(sp)
    80001f38:	fc26                	sd	s1,56(sp)
    80001f3a:	f84a                	sd	s2,48(sp)
    80001f3c:	f44e                	sd	s3,40(sp)
    80001f3e:	f052                	sd	s4,32(sp)
    80001f40:	ec56                	sd	s5,24(sp)
    80001f42:	e85a                	sd	s6,16(sp)
    80001f44:	e45e                	sd	s7,8(sp)
    80001f46:	e062                	sd	s8,0(sp)
    80001f48:	0880                	addi	s0,sp,80
    80001f4a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f4c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f4e:	00779b13          	slli	s6,a5,0x7
    80001f52:	00010717          	auipc	a4,0x10
    80001f56:	9fe70713          	addi	a4,a4,-1538 # 80011950 <pid_lock>
    80001f5a:	975a                	add	a4,a4,s6
    80001f5c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f60:	00010717          	auipc	a4,0x10
    80001f64:	a1070713          	addi	a4,a4,-1520 # 80011970 <cpus+0x8>
    80001f68:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f6a:	4c0d                	li	s8,3
        c->proc = p;
    80001f6c:	079e                	slli	a5,a5,0x7
    80001f6e:	00010a17          	auipc	s4,0x10
    80001f72:	9e2a0a13          	addi	s4,s4,-1566 # 80011950 <pid_lock>
    80001f76:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f78:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f7a:	00015997          	auipc	s3,0x15
    80001f7e:	7ee98993          	addi	s3,s3,2030 # 80017768 <tickslock>
    80001f82:	a899                	j	80001fd8 <scheduler+0xa6>
      release(&p->lock);
    80001f84:	8526                	mv	a0,s1
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d2e080e7          	jalr	-722(ra) # 80000cb4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8e:	16848493          	addi	s1,s1,360
    80001f92:	03348963          	beq	s1,s3,80001fc4 <scheduler+0x92>
      acquire(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	c68080e7          	jalr	-920(ra) # 80000c00 <acquire>
      if(p->state == RUNNABLE) {
    80001fa0:	4c9c                	lw	a5,24(s1)
    80001fa2:	ff2791e3          	bne	a5,s2,80001f84 <scheduler+0x52>
        p->state = RUNNING;
    80001fa6:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001faa:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fae:	06048593          	addi	a1,s1,96
    80001fb2:	855a                	mv	a0,s6
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	610080e7          	jalr	1552(ra) # 800025c4 <swtch>
        c->proc = 0; // cpu dosen't run any process now
    80001fbc:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fc0:	8ade                	mv	s5,s7
    80001fc2:	b7c9                	j	80001f84 <scheduler+0x52>
    if(found == 0) {
    80001fc4:	000a9a63          	bnez	s5,80001fd8 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fcc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fd0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fd4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fdc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fe0:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fe4:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	00010497          	auipc	s1,0x10
    80001fea:	d8248493          	addi	s1,s1,-638 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fee:	4909                	li	s2,2
    80001ff0:	b75d                	j	80001f96 <scheduler+0x64>

0000000080001ff2 <sched>:
{
    80001ff2:	7179                	addi	sp,sp,-48
    80001ff4:	f406                	sd	ra,40(sp)
    80001ff6:	f022                	sd	s0,32(sp)
    80001ff8:	ec26                	sd	s1,24(sp)
    80001ffa:	e84a                	sd	s2,16(sp)
    80001ffc:	e44e                	sd	s3,8(sp)
    80001ffe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	9fa080e7          	jalr	-1542(ra) # 800019fa <myproc>
    80002008:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	b7c080e7          	jalr	-1156(ra) # 80000b86 <holding>
    80002012:	c93d                	beqz	a0,80002088 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002016:	2781                	sext.w	a5,a5
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	00010717          	auipc	a4,0x10
    8000201e:	93670713          	addi	a4,a4,-1738 # 80011950 <pid_lock>
    80002022:	97ba                	add	a5,a5,a4
    80002024:	0907a703          	lw	a4,144(a5)
    80002028:	4785                	li	a5,1
    8000202a:	06f71763          	bne	a4,a5,80002098 <sched+0xa6>
  if(p->state == RUNNING)
    8000202e:	4c98                	lw	a4,24(s1)
    80002030:	478d                	li	a5,3
    80002032:	06f70b63          	beq	a4,a5,800020a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000203a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000203c:	efb5                	bnez	a5,800020b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002040:	00010917          	auipc	s2,0x10
    80002044:	91090913          	addi	s2,s2,-1776 # 80011950 <pid_lock>
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	97ca                	add	a5,a5,s2
    8000204e:	0947a983          	lw	s3,148(a5)
    80002052:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	00010597          	auipc	a1,0x10
    8000205c:	91858593          	addi	a1,a1,-1768 # 80011970 <cpus+0x8>
    80002060:	95be                	add	a1,a1,a5
    80002062:	06048513          	addi	a0,s1,96
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	55e080e7          	jalr	1374(ra) # 800025c4 <swtch>
    8000206e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	993e                	add	s2,s2,a5
    80002076:	09392a23          	sw	s3,148(s2)
}
    8000207a:	70a2                	ld	ra,40(sp)
    8000207c:	7402                	ld	s0,32(sp)
    8000207e:	64e2                	ld	s1,24(sp)
    80002080:	6942                	ld	s2,16(sp)
    80002082:	69a2                	ld	s3,8(sp)
    80002084:	6145                	addi	sp,sp,48
    80002086:	8082                	ret
    panic("sched p->lock");
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	17850513          	addi	a0,a0,376 # 80008200 <digits+0x1c0>
    80002090:	ffffe097          	auipc	ra,0xffffe
    80002094:	4b6080e7          	jalr	1206(ra) # 80000546 <panic>
    panic("sched locks");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	17850513          	addi	a0,a0,376 # 80008210 <digits+0x1d0>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	4a6080e7          	jalr	1190(ra) # 80000546 <panic>
    panic("sched running");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	17850513          	addi	a0,a0,376 # 80008220 <digits+0x1e0>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	496080e7          	jalr	1174(ra) # 80000546 <panic>
    panic("sched interruptible");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	17850513          	addi	a0,a0,376 # 80008230 <digits+0x1f0>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	486080e7          	jalr	1158(ra) # 80000546 <panic>

00000000800020c8 <exit>:
{
    800020c8:	7179                	addi	sp,sp,-48
    800020ca:	f406                	sd	ra,40(sp)
    800020cc:	f022                	sd	s0,32(sp)
    800020ce:	ec26                	sd	s1,24(sp)
    800020d0:	e84a                	sd	s2,16(sp)
    800020d2:	e44e                	sd	s3,8(sp)
    800020d4:	e052                	sd	s4,0(sp)
    800020d6:	1800                	addi	s0,sp,48
    800020d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020da:	00000097          	auipc	ra,0x0
    800020de:	920080e7          	jalr	-1760(ra) # 800019fa <myproc>
    800020e2:	89aa                	mv	s3,a0
  if(p == initproc)
    800020e4:	00007797          	auipc	a5,0x7
    800020e8:	f347b783          	ld	a5,-204(a5) # 80009018 <initproc>
    800020ec:	0d050493          	addi	s1,a0,208
    800020f0:	15050913          	addi	s2,a0,336
    800020f4:	02a79363          	bne	a5,a0,8000211a <exit+0x52>
    panic("init exiting");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	15050513          	addi	a0,a0,336 # 80008248 <digits+0x208>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	446080e7          	jalr	1094(ra) # 80000546 <panic>
      fileclose(f);
    80002108:	00002097          	auipc	ra,0x2
    8000210c:	3cc080e7          	jalr	972(ra) # 800044d4 <fileclose>
      p->ofile[fd] = 0;
    80002110:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002114:	04a1                	addi	s1,s1,8
    80002116:	01248563          	beq	s1,s2,80002120 <exit+0x58>
    if(p->ofile[fd]){
    8000211a:	6088                	ld	a0,0(s1)
    8000211c:	f575                	bnez	a0,80002108 <exit+0x40>
    8000211e:	bfdd                	j	80002114 <exit+0x4c>
  begin_op();
    80002120:	00002097          	auipc	ra,0x2
    80002124:	ee6080e7          	jalr	-282(ra) # 80004006 <begin_op>
  iput(p->cwd);
    80002128:	1509b503          	ld	a0,336(s3)
    8000212c:	00001097          	auipc	ra,0x1
    80002130:	6ce080e7          	jalr	1742(ra) # 800037fa <iput>
  end_op();
    80002134:	00002097          	auipc	ra,0x2
    80002138:	f50080e7          	jalr	-176(ra) # 80004084 <end_op>
  p->cwd = 0;
    8000213c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002140:	00007497          	auipc	s1,0x7
    80002144:	ed848493          	addi	s1,s1,-296 # 80009018 <initproc>
    80002148:	6088                	ld	a0,0(s1)
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	ab6080e7          	jalr	-1354(ra) # 80000c00 <acquire>
  wakeup1(initproc);
    80002152:	6088                	ld	a0,0(s1)
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	766080e7          	jalr	1894(ra) # 800018ba <wakeup1>
  release(&initproc->lock);
    8000215c:	6088                	ld	a0,0(s1)
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	b56080e7          	jalr	-1194(ra) # 80000cb4 <release>
  acquire(&p->lock);
    80002166:	854e                	mv	a0,s3
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a98080e7          	jalr	-1384(ra) # 80000c00 <acquire>
  struct proc *original_parent = p->parent;
    80002170:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002174:	854e                	mv	a0,s3
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b3e080e7          	jalr	-1218(ra) # 80000cb4 <release>
  acquire(&original_parent->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	a80080e7          	jalr	-1408(ra) # 80000c00 <acquire>
  acquire(&p->lock);
    80002188:	854e                	mv	a0,s3
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	a76080e7          	jalr	-1418(ra) # 80000c00 <acquire>
  reparent(p);
    80002192:	854e                	mv	a0,s3
    80002194:	00000097          	auipc	ra,0x0
    80002198:	d38080e7          	jalr	-712(ra) # 80001ecc <reparent>
  wakeup1(original_parent);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	71c080e7          	jalr	1820(ra) # 800018ba <wakeup1>
  p->xstate = status;
    800021a6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021aa:	4791                	li	a5,4
    800021ac:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	b02080e7          	jalr	-1278(ra) # 80000cb4 <release>
  sched();
    800021ba:	00000097          	auipc	ra,0x0
    800021be:	e38080e7          	jalr	-456(ra) # 80001ff2 <sched>
  panic("zombie exit");
    800021c2:	00006517          	auipc	a0,0x6
    800021c6:	09650513          	addi	a0,a0,150 # 80008258 <digits+0x218>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	37c080e7          	jalr	892(ra) # 80000546 <panic>

00000000800021d2 <yield>:
{
    800021d2:	1101                	addi	sp,sp,-32
    800021d4:	ec06                	sd	ra,24(sp)
    800021d6:	e822                	sd	s0,16(sp)
    800021d8:	e426                	sd	s1,8(sp)
    800021da:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	81e080e7          	jalr	-2018(ra) # 800019fa <myproc>
    800021e4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a1a080e7          	jalr	-1510(ra) # 80000c00 <acquire>
  p->state = RUNNABLE;
    800021ee:	4789                	li	a5,2
    800021f0:	cc9c                	sw	a5,24(s1)
  sched();
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	e00080e7          	jalr	-512(ra) # 80001ff2 <sched>
  release(&p->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	ab8080e7          	jalr	-1352(ra) # 80000cb4 <release>
}
    80002204:	60e2                	ld	ra,24(sp)
    80002206:	6442                	ld	s0,16(sp)
    80002208:	64a2                	ld	s1,8(sp)
    8000220a:	6105                	addi	sp,sp,32
    8000220c:	8082                	ret

000000008000220e <sleep>:
{
    8000220e:	7179                	addi	sp,sp,-48
    80002210:	f406                	sd	ra,40(sp)
    80002212:	f022                	sd	s0,32(sp)
    80002214:	ec26                	sd	s1,24(sp)
    80002216:	e84a                	sd	s2,16(sp)
    80002218:	e44e                	sd	s3,8(sp)
    8000221a:	1800                	addi	s0,sp,48
    8000221c:	89aa                	mv	s3,a0
    8000221e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	7da080e7          	jalr	2010(ra) # 800019fa <myproc>
    80002228:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000222a:	05250663          	beq	a0,s2,80002276 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9d2080e7          	jalr	-1582(ra) # 80000c00 <acquire>
    release(lk);
    80002236:	854a                	mv	a0,s2
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	a7c080e7          	jalr	-1412(ra) # 80000cb4 <release>
  p->chan = chan;
    80002240:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002244:	4785                	li	a5,1
    80002246:	cc9c                	sw	a5,24(s1)
  sched();
    80002248:	00000097          	auipc	ra,0x0
    8000224c:	daa080e7          	jalr	-598(ra) # 80001ff2 <sched>
  p->chan = 0;
    80002250:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	a5e080e7          	jalr	-1442(ra) # 80000cb4 <release>
    acquire(lk);
    8000225e:	854a                	mv	a0,s2
    80002260:	fffff097          	auipc	ra,0xfffff
    80002264:	9a0080e7          	jalr	-1632(ra) # 80000c00 <acquire>
}
    80002268:	70a2                	ld	ra,40(sp)
    8000226a:	7402                	ld	s0,32(sp)
    8000226c:	64e2                	ld	s1,24(sp)
    8000226e:	6942                	ld	s2,16(sp)
    80002270:	69a2                	ld	s3,8(sp)
    80002272:	6145                	addi	sp,sp,48
    80002274:	8082                	ret
  p->chan = chan;
    80002276:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000227a:	4785                	li	a5,1
    8000227c:	cd1c                	sw	a5,24(a0)
  sched();
    8000227e:	00000097          	auipc	ra,0x0
    80002282:	d74080e7          	jalr	-652(ra) # 80001ff2 <sched>
  p->chan = 0;
    80002286:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000228a:	bff9                	j	80002268 <sleep+0x5a>

000000008000228c <wait>:
{
    8000228c:	715d                	addi	sp,sp,-80
    8000228e:	e486                	sd	ra,72(sp)
    80002290:	e0a2                	sd	s0,64(sp)
    80002292:	fc26                	sd	s1,56(sp)
    80002294:	f84a                	sd	s2,48(sp)
    80002296:	f44e                	sd	s3,40(sp)
    80002298:	f052                	sd	s4,32(sp)
    8000229a:	ec56                	sd	s5,24(sp)
    8000229c:	e85a                	sd	s6,16(sp)
    8000229e:	e45e                	sd	s7,8(sp)
    800022a0:	0880                	addi	s0,sp,80
    800022a2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	756080e7          	jalr	1878(ra) # 800019fa <myproc>
    800022ac:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	952080e7          	jalr	-1710(ra) # 80000c00 <acquire>
    havekids = 0;
    800022b6:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022b8:	4a11                	li	s4,4
        havekids = 1;
    800022ba:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022bc:	00015997          	auipc	s3,0x15
    800022c0:	4ac98993          	addi	s3,s3,1196 # 80017768 <tickslock>
    havekids = 0;
    800022c4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022c6:	00010497          	auipc	s1,0x10
    800022ca:	aa248493          	addi	s1,s1,-1374 # 80011d68 <proc>
    800022ce:	a08d                	j	80002330 <wait+0xa4>
          pid = np->pid;
    800022d0:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022d4:	000b0e63          	beqz	s6,800022f0 <wait+0x64>
    800022d8:	4691                	li	a3,4
    800022da:	03448613          	addi	a2,s1,52
    800022de:	85da                	mv	a1,s6
    800022e0:	05093503          	ld	a0,80(s2)
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	3e6080e7          	jalr	998(ra) # 800016ca <copyout>
    800022ec:	02054263          	bltz	a0,80002310 <wait+0x84>
          freeproc(np);
    800022f0:	8526                	mv	a0,s1
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	8ba080e7          	jalr	-1862(ra) # 80001bac <freeproc>
          release(&np->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	9b8080e7          	jalr	-1608(ra) # 80000cb4 <release>
          release(&p->lock);
    80002304:	854a                	mv	a0,s2
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	9ae080e7          	jalr	-1618(ra) # 80000cb4 <release>
          return pid;
    8000230e:	a8a9                	j	80002368 <wait+0xdc>
            release(&np->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	9a2080e7          	jalr	-1630(ra) # 80000cb4 <release>
            release(&p->lock);
    8000231a:	854a                	mv	a0,s2
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	998080e7          	jalr	-1640(ra) # 80000cb4 <release>
            return -1;
    80002324:	59fd                	li	s3,-1
    80002326:	a089                	j	80002368 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002328:	16848493          	addi	s1,s1,360
    8000232c:	03348463          	beq	s1,s3,80002354 <wait+0xc8>
      if(np->parent == p){
    80002330:	709c                	ld	a5,32(s1)
    80002332:	ff279be3          	bne	a5,s2,80002328 <wait+0x9c>
        acquire(&np->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	8c8080e7          	jalr	-1848(ra) # 80000c00 <acquire>
        if(np->state == ZOMBIE){
    80002340:	4c9c                	lw	a5,24(s1)
    80002342:	f94787e3          	beq	a5,s4,800022d0 <wait+0x44>
        release(&np->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	96c080e7          	jalr	-1684(ra) # 80000cb4 <release>
        havekids = 1;
    80002350:	8756                	mv	a4,s5
    80002352:	bfd9                	j	80002328 <wait+0x9c>
    if(!havekids || p->killed){
    80002354:	c701                	beqz	a4,8000235c <wait+0xd0>
    80002356:	03092783          	lw	a5,48(s2)
    8000235a:	c39d                	beqz	a5,80002380 <wait+0xf4>
      release(&p->lock);
    8000235c:	854a                	mv	a0,s2
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	956080e7          	jalr	-1706(ra) # 80000cb4 <release>
      return -1;
    80002366:	59fd                	li	s3,-1
}
    80002368:	854e                	mv	a0,s3
    8000236a:	60a6                	ld	ra,72(sp)
    8000236c:	6406                	ld	s0,64(sp)
    8000236e:	74e2                	ld	s1,56(sp)
    80002370:	7942                	ld	s2,48(sp)
    80002372:	79a2                	ld	s3,40(sp)
    80002374:	7a02                	ld	s4,32(sp)
    80002376:	6ae2                	ld	s5,24(sp)
    80002378:	6b42                	ld	s6,16(sp)
    8000237a:	6ba2                	ld	s7,8(sp)
    8000237c:	6161                	addi	sp,sp,80
    8000237e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002380:	85ca                	mv	a1,s2
    80002382:	854a                	mv	a0,s2
    80002384:	00000097          	auipc	ra,0x0
    80002388:	e8a080e7          	jalr	-374(ra) # 8000220e <sleep>
    havekids = 0;
    8000238c:	bf25                	j	800022c4 <wait+0x38>

000000008000238e <wakeup>:
{
    8000238e:	7139                	addi	sp,sp,-64
    80002390:	fc06                	sd	ra,56(sp)
    80002392:	f822                	sd	s0,48(sp)
    80002394:	f426                	sd	s1,40(sp)
    80002396:	f04a                	sd	s2,32(sp)
    80002398:	ec4e                	sd	s3,24(sp)
    8000239a:	e852                	sd	s4,16(sp)
    8000239c:	e456                	sd	s5,8(sp)
    8000239e:	0080                	addi	s0,sp,64
    800023a0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023a2:	00010497          	auipc	s1,0x10
    800023a6:	9c648493          	addi	s1,s1,-1594 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023aa:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023ac:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ae:	00015917          	auipc	s2,0x15
    800023b2:	3ba90913          	addi	s2,s2,954 # 80017768 <tickslock>
    800023b6:	a811                	j	800023ca <wakeup+0x3c>
    release(&p->lock);
    800023b8:	8526                	mv	a0,s1
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8fa080e7          	jalr	-1798(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c2:	16848493          	addi	s1,s1,360
    800023c6:	03248063          	beq	s1,s2,800023e6 <wakeup+0x58>
    acquire(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	834080e7          	jalr	-1996(ra) # 80000c00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023d4:	4c9c                	lw	a5,24(s1)
    800023d6:	ff3791e3          	bne	a5,s3,800023b8 <wakeup+0x2a>
    800023da:	749c                	ld	a5,40(s1)
    800023dc:	fd479ee3          	bne	a5,s4,800023b8 <wakeup+0x2a>
      p->state = RUNNABLE;
    800023e0:	0154ac23          	sw	s5,24(s1)
    800023e4:	bfd1                	j	800023b8 <wakeup+0x2a>
}
    800023e6:	70e2                	ld	ra,56(sp)
    800023e8:	7442                	ld	s0,48(sp)
    800023ea:	74a2                	ld	s1,40(sp)
    800023ec:	7902                	ld	s2,32(sp)
    800023ee:	69e2                	ld	s3,24(sp)
    800023f0:	6a42                	ld	s4,16(sp)
    800023f2:	6aa2                	ld	s5,8(sp)
    800023f4:	6121                	addi	sp,sp,64
    800023f6:	8082                	ret

00000000800023f8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023f8:	7179                	addi	sp,sp,-48
    800023fa:	f406                	sd	ra,40(sp)
    800023fc:	f022                	sd	s0,32(sp)
    800023fe:	ec26                	sd	s1,24(sp)
    80002400:	e84a                	sd	s2,16(sp)
    80002402:	e44e                	sd	s3,8(sp)
    80002404:	1800                	addi	s0,sp,48
    80002406:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002408:	00010497          	auipc	s1,0x10
    8000240c:	96048493          	addi	s1,s1,-1696 # 80011d68 <proc>
    80002410:	00015997          	auipc	s3,0x15
    80002414:	35898993          	addi	s3,s3,856 # 80017768 <tickslock>
    acquire(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7e6080e7          	jalr	2022(ra) # 80000c00 <acquire>
    if(p->pid == pid){
    80002422:	5c9c                	lw	a5,56(s1)
    80002424:	01278d63          	beq	a5,s2,8000243e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	88a080e7          	jalr	-1910(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002432:	16848493          	addi	s1,s1,360
    80002436:	ff3491e3          	bne	s1,s3,80002418 <kill+0x20>
  }
  return -1;
    8000243a:	557d                	li	a0,-1
    8000243c:	a821                	j	80002454 <kill+0x5c>
      p->killed = 1;
    8000243e:	4785                	li	a5,1
    80002440:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002442:	4c98                	lw	a4,24(s1)
    80002444:	00f70f63          	beq	a4,a5,80002462 <kill+0x6a>
      release(&p->lock);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	86a080e7          	jalr	-1942(ra) # 80000cb4 <release>
      return 0;
    80002452:	4501                	li	a0,0
}
    80002454:	70a2                	ld	ra,40(sp)
    80002456:	7402                	ld	s0,32(sp)
    80002458:	64e2                	ld	s1,24(sp)
    8000245a:	6942                	ld	s2,16(sp)
    8000245c:	69a2                	ld	s3,8(sp)
    8000245e:	6145                	addi	sp,sp,48
    80002460:	8082                	ret
        p->state = RUNNABLE;
    80002462:	4789                	li	a5,2
    80002464:	cc9c                	sw	a5,24(s1)
    80002466:	b7cd                	j	80002448 <kill+0x50>

0000000080002468 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002468:	7179                	addi	sp,sp,-48
    8000246a:	f406                	sd	ra,40(sp)
    8000246c:	f022                	sd	s0,32(sp)
    8000246e:	ec26                	sd	s1,24(sp)
    80002470:	e84a                	sd	s2,16(sp)
    80002472:	e44e                	sd	s3,8(sp)
    80002474:	e052                	sd	s4,0(sp)
    80002476:	1800                	addi	s0,sp,48
    80002478:	84aa                	mv	s1,a0
    8000247a:	892e                	mv	s2,a1
    8000247c:	89b2                	mv	s3,a2
    8000247e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	57a080e7          	jalr	1402(ra) # 800019fa <myproc>
  if(user_dst){
    80002488:	c08d                	beqz	s1,800024aa <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000248a:	86d2                	mv	a3,s4
    8000248c:	864e                	mv	a2,s3
    8000248e:	85ca                	mv	a1,s2
    80002490:	6928                	ld	a0,80(a0)
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	238080e7          	jalr	568(ra) # 800016ca <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6a02                	ld	s4,0(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret
    memmove((char *)dst, src, len);
    800024aa:	000a061b          	sext.w	a2,s4
    800024ae:	85ce                	mv	a1,s3
    800024b0:	854a                	mv	a0,s2
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	8a6080e7          	jalr	-1882(ra) # 80000d58 <memmove>
    return 0;
    800024ba:	8526                	mv	a0,s1
    800024bc:	bff9                	j	8000249a <either_copyout+0x32>

00000000800024be <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	e052                	sd	s4,0(sp)
    800024cc:	1800                	addi	s0,sp,48
    800024ce:	892a                	mv	s2,a0
    800024d0:	84ae                	mv	s1,a1
    800024d2:	89b2                	mv	s3,a2
    800024d4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	524080e7          	jalr	1316(ra) # 800019fa <myproc>
  if(user_src){
    800024de:	c08d                	beqz	s1,80002500 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024e0:	86d2                	mv	a3,s4
    800024e2:	864e                	mv	a2,s3
    800024e4:	85ca                	mv	a1,s2
    800024e6:	6928                	ld	a0,80(a0)
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	26e080e7          	jalr	622(ra) # 80001756 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024f0:	70a2                	ld	ra,40(sp)
    800024f2:	7402                	ld	s0,32(sp)
    800024f4:	64e2                	ld	s1,24(sp)
    800024f6:	6942                	ld	s2,16(sp)
    800024f8:	69a2                	ld	s3,8(sp)
    800024fa:	6a02                	ld	s4,0(sp)
    800024fc:	6145                	addi	sp,sp,48
    800024fe:	8082                	ret
    memmove(dst, (char*)src, len);
    80002500:	000a061b          	sext.w	a2,s4
    80002504:	85ce                	mv	a1,s3
    80002506:	854a                	mv	a0,s2
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	850080e7          	jalr	-1968(ra) # 80000d58 <memmove>
    return 0;
    80002510:	8526                	mv	a0,s1
    80002512:	bff9                	j	800024f0 <either_copyin+0x32>

0000000080002514 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002514:	715d                	addi	sp,sp,-80
    80002516:	e486                	sd	ra,72(sp)
    80002518:	e0a2                	sd	s0,64(sp)
    8000251a:	fc26                	sd	s1,56(sp)
    8000251c:	f84a                	sd	s2,48(sp)
    8000251e:	f44e                	sd	s3,40(sp)
    80002520:	f052                	sd	s4,32(sp)
    80002522:	ec56                	sd	s5,24(sp)
    80002524:	e85a                	sd	s6,16(sp)
    80002526:	e45e                	sd	s7,8(sp)
    80002528:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000252a:	00006517          	auipc	a0,0x6
    8000252e:	b9e50513          	addi	a0,a0,-1122 # 800080c8 <digits+0x88>
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	05e080e7          	jalr	94(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000253a:	00010497          	auipc	s1,0x10
    8000253e:	98648493          	addi	s1,s1,-1658 # 80011ec0 <proc+0x158>
    80002542:	00015917          	auipc	s2,0x15
    80002546:	37e90913          	addi	s2,s2,894 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000254a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000254c:	00006997          	auipc	s3,0x6
    80002550:	d1c98993          	addi	s3,s3,-740 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002554:	00006a97          	auipc	s5,0x6
    80002558:	d1ca8a93          	addi	s5,s5,-740 # 80008270 <digits+0x230>
    printf("\n");
    8000255c:	00006a17          	auipc	s4,0x6
    80002560:	b6ca0a13          	addi	s4,s4,-1172 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002564:	00006b97          	auipc	s7,0x6
    80002568:	d44b8b93          	addi	s7,s7,-700 # 800082a8 <states.0>
    8000256c:	a00d                	j	8000258e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256e:	ee06a583          	lw	a1,-288(a3)
    80002572:	8556                	mv	a0,s5
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	01c080e7          	jalr	28(ra) # 80000590 <printf>
    printf("\n");
    8000257c:	8552                	mv	a0,s4
    8000257e:	ffffe097          	auipc	ra,0xffffe
    80002582:	012080e7          	jalr	18(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002586:	16848493          	addi	s1,s1,360
    8000258a:	03248263          	beq	s1,s2,800025ae <procdump+0x9a>
    if(p->state == UNUSED)
    8000258e:	86a6                	mv	a3,s1
    80002590:	ec04a783          	lw	a5,-320(s1)
    80002594:	dbed                	beqz	a5,80002586 <procdump+0x72>
      state = "???";
    80002596:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002598:	fcfb6be3          	bltu	s6,a5,8000256e <procdump+0x5a>
    8000259c:	02079713          	slli	a4,a5,0x20
    800025a0:	01d75793          	srli	a5,a4,0x1d
    800025a4:	97de                	add	a5,a5,s7
    800025a6:	6390                	ld	a2,0(a5)
    800025a8:	f279                	bnez	a2,8000256e <procdump+0x5a>
      state = "???";
    800025aa:	864e                	mv	a2,s3
    800025ac:	b7c9                	j	8000256e <procdump+0x5a>
  }
}
    800025ae:	60a6                	ld	ra,72(sp)
    800025b0:	6406                	ld	s0,64(sp)
    800025b2:	74e2                	ld	s1,56(sp)
    800025b4:	7942                	ld	s2,48(sp)
    800025b6:	79a2                	ld	s3,40(sp)
    800025b8:	7a02                	ld	s4,32(sp)
    800025ba:	6ae2                	ld	s5,24(sp)
    800025bc:	6b42                	ld	s6,16(sp)
    800025be:	6ba2                	ld	s7,8(sp)
    800025c0:	6161                	addi	sp,sp,80
    800025c2:	8082                	ret

00000000800025c4 <swtch>:
    800025c4:	00153023          	sd	ra,0(a0)
    800025c8:	00253423          	sd	sp,8(a0)
    800025cc:	e900                	sd	s0,16(a0)
    800025ce:	ed04                	sd	s1,24(a0)
    800025d0:	03253023          	sd	s2,32(a0)
    800025d4:	03353423          	sd	s3,40(a0)
    800025d8:	03453823          	sd	s4,48(a0)
    800025dc:	03553c23          	sd	s5,56(a0)
    800025e0:	05653023          	sd	s6,64(a0)
    800025e4:	05753423          	sd	s7,72(a0)
    800025e8:	05853823          	sd	s8,80(a0)
    800025ec:	05953c23          	sd	s9,88(a0)
    800025f0:	07a53023          	sd	s10,96(a0)
    800025f4:	07b53423          	sd	s11,104(a0)
    800025f8:	0005b083          	ld	ra,0(a1)
    800025fc:	0085b103          	ld	sp,8(a1)
    80002600:	6980                	ld	s0,16(a1)
    80002602:	6d84                	ld	s1,24(a1)
    80002604:	0205b903          	ld	s2,32(a1)
    80002608:	0285b983          	ld	s3,40(a1)
    8000260c:	0305ba03          	ld	s4,48(a1)
    80002610:	0385ba83          	ld	s5,56(a1)
    80002614:	0405bb03          	ld	s6,64(a1)
    80002618:	0485bb83          	ld	s7,72(a1)
    8000261c:	0505bc03          	ld	s8,80(a1)
    80002620:	0585bc83          	ld	s9,88(a1)
    80002624:	0605bd03          	ld	s10,96(a1)
    80002628:	0685bd83          	ld	s11,104(a1)
    8000262c:	8082                	ret

000000008000262e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000262e:	1141                	addi	sp,sp,-16
    80002630:	e406                	sd	ra,8(sp)
    80002632:	e022                	sd	s0,0(sp)
    80002634:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002636:	00006597          	auipc	a1,0x6
    8000263a:	c9a58593          	addi	a1,a1,-870 # 800082d0 <states.0+0x28>
    8000263e:	00015517          	auipc	a0,0x15
    80002642:	12a50513          	addi	a0,a0,298 # 80017768 <tickslock>
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	52a080e7          	jalr	1322(ra) # 80000b70 <initlock>
}
    8000264e:	60a2                	ld	ra,8(sp)
    80002650:	6402                	ld	s0,0(sp)
    80002652:	0141                	addi	sp,sp,16
    80002654:	8082                	ret

0000000080002656 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002656:	1141                	addi	sp,sp,-16
    80002658:	e422                	sd	s0,8(sp)
    8000265a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265c:	00003797          	auipc	a5,0x3
    80002660:	5e478793          	addi	a5,a5,1508 # 80005c40 <kernelvec>
    80002664:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002668:	6422                	ld	s0,8(sp)
    8000266a:	0141                	addi	sp,sp,16
    8000266c:	8082                	ret

000000008000266e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000266e:	1141                	addi	sp,sp,-16
    80002670:	e406                	sd	ra,8(sp)
    80002672:	e022                	sd	s0,0(sp)
    80002674:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	384080e7          	jalr	900(ra) # 800019fa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000267e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002682:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002684:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002688:	00005697          	auipc	a3,0x5
    8000268c:	97868693          	addi	a3,a3,-1672 # 80007000 <_trampoline>
    80002690:	00005717          	auipc	a4,0x5
    80002694:	97070713          	addi	a4,a4,-1680 # 80007000 <_trampoline>
    80002698:	8f15                	sub	a4,a4,a3
    8000269a:	040007b7          	lui	a5,0x4000
    8000269e:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026a0:	07b2                	slli	a5,a5,0xc
    800026a2:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a4:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026aa:	18002673          	csrr	a2,satp
    800026ae:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026b0:	6d30                	ld	a2,88(a0)
    800026b2:	6138                	ld	a4,64(a0)
    800026b4:	6585                	lui	a1,0x1
    800026b6:	972e                	add	a4,a4,a1
    800026b8:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026ba:	6d38                	ld	a4,88(a0)
    800026bc:	00000617          	auipc	a2,0x0
    800026c0:	13860613          	addi	a2,a2,312 # 800027f4 <usertrap>
    800026c4:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026c6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026c8:	8612                	mv	a2,tp
    800026ca:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026cc:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026d0:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026d4:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d8:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026de:	6f18                	ld	a4,24(a4)
    800026e0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026e4:	692c                	ld	a1,80(a0)
    800026e6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026e8:	00005717          	auipc	a4,0x5
    800026ec:	9a870713          	addi	a4,a4,-1624 # 80007090 <userret>
    800026f0:	8f15                	sub	a4,a4,a3
    800026f2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026f4:	577d                	li	a4,-1
    800026f6:	177e                	slli	a4,a4,0x3f
    800026f8:	8dd9                	or	a1,a1,a4
    800026fa:	02000537          	lui	a0,0x2000
    800026fe:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002700:	0536                	slli	a0,a0,0xd
    80002702:	9782                	jalr	a5
}
    80002704:	60a2                	ld	ra,8(sp)
    80002706:	6402                	ld	s0,0(sp)
    80002708:	0141                	addi	sp,sp,16
    8000270a:	8082                	ret

000000008000270c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000270c:	1101                	addi	sp,sp,-32
    8000270e:	ec06                	sd	ra,24(sp)
    80002710:	e822                	sd	s0,16(sp)
    80002712:	e426                	sd	s1,8(sp)
    80002714:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002716:	00015497          	auipc	s1,0x15
    8000271a:	05248493          	addi	s1,s1,82 # 80017768 <tickslock>
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	4e0080e7          	jalr	1248(ra) # 80000c00 <acquire>
  ticks++;
    80002728:	00007517          	auipc	a0,0x7
    8000272c:	8f850513          	addi	a0,a0,-1800 # 80009020 <ticks>
    80002730:	411c                	lw	a5,0(a0)
    80002732:	2785                	addiw	a5,a5,1
    80002734:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002736:	00000097          	auipc	ra,0x0
    8000273a:	c58080e7          	jalr	-936(ra) # 8000238e <wakeup>
  release(&tickslock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	574080e7          	jalr	1396(ra) # 80000cb4 <release>
}
    80002748:	60e2                	ld	ra,24(sp)
    8000274a:	6442                	ld	s0,16(sp)
    8000274c:	64a2                	ld	s1,8(sp)
    8000274e:	6105                	addi	sp,sp,32
    80002750:	8082                	ret

0000000080002752 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002752:	1101                	addi	sp,sp,-32
    80002754:	ec06                	sd	ra,24(sp)
    80002756:	e822                	sd	s0,16(sp)
    80002758:	e426                	sd	s1,8(sp)
    8000275a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000275c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002760:	00074d63          	bltz	a4,8000277a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002764:	57fd                	li	a5,-1
    80002766:	17fe                	slli	a5,a5,0x3f
    80002768:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000276a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000276c:	06f70363          	beq	a4,a5,800027d2 <devintr+0x80>
  }
}
    80002770:	60e2                	ld	ra,24(sp)
    80002772:	6442                	ld	s0,16(sp)
    80002774:	64a2                	ld	s1,8(sp)
    80002776:	6105                	addi	sp,sp,32
    80002778:	8082                	ret
     (scause & 0xff) == 9){
    8000277a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000277e:	46a5                	li	a3,9
    80002780:	fed792e3          	bne	a5,a3,80002764 <devintr+0x12>
    int irq = plic_claim();
    80002784:	00003097          	auipc	ra,0x3
    80002788:	5c4080e7          	jalr	1476(ra) # 80005d48 <plic_claim>
    8000278c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000278e:	47a9                	li	a5,10
    80002790:	02f50763          	beq	a0,a5,800027be <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002794:	4785                	li	a5,1
    80002796:	02f50963          	beq	a0,a5,800027c8 <devintr+0x76>
    return 1;
    8000279a:	4505                	li	a0,1
    } else if(irq){
    8000279c:	d8f1                	beqz	s1,80002770 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000279e:	85a6                	mv	a1,s1
    800027a0:	00006517          	auipc	a0,0x6
    800027a4:	b3850513          	addi	a0,a0,-1224 # 800082d8 <states.0+0x30>
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	de8080e7          	jalr	-536(ra) # 80000590 <printf>
      plic_complete(irq);
    800027b0:	8526                	mv	a0,s1
    800027b2:	00003097          	auipc	ra,0x3
    800027b6:	5ba080e7          	jalr	1466(ra) # 80005d6c <plic_complete>
    return 1;
    800027ba:	4505                	li	a0,1
    800027bc:	bf55                	j	80002770 <devintr+0x1e>
      uartintr();
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	204080e7          	jalr	516(ra) # 800009c2 <uartintr>
    800027c6:	b7ed                	j	800027b0 <devintr+0x5e>
      virtio_disk_intr();
    800027c8:	00004097          	auipc	ra,0x4
    800027cc:	a18080e7          	jalr	-1512(ra) # 800061e0 <virtio_disk_intr>
    800027d0:	b7c5                	j	800027b0 <devintr+0x5e>
    if(cpuid() == 0){
    800027d2:	fffff097          	auipc	ra,0xfffff
    800027d6:	1fc080e7          	jalr	508(ra) # 800019ce <cpuid>
    800027da:	c901                	beqz	a0,800027ea <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027dc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e2:	14479073          	csrw	sip,a5
    return 2;
    800027e6:	4509                	li	a0,2
    800027e8:	b761                	j	80002770 <devintr+0x1e>
      clockintr();
    800027ea:	00000097          	auipc	ra,0x0
    800027ee:	f22080e7          	jalr	-222(ra) # 8000270c <clockintr>
    800027f2:	b7ed                	j	800027dc <devintr+0x8a>

00000000800027f4 <usertrap>:
{
    800027f4:	1101                	addi	sp,sp,-32
    800027f6:	ec06                	sd	ra,24(sp)
    800027f8:	e822                	sd	s0,16(sp)
    800027fa:	e426                	sd	s1,8(sp)
    800027fc:	e04a                	sd	s2,0(sp)
    800027fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002800:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002804:	1007f793          	andi	a5,a5,256
    80002808:	e3ad                	bnez	a5,8000286a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000280a:	00003797          	auipc	a5,0x3
    8000280e:	43678793          	addi	a5,a5,1078 # 80005c40 <kernelvec>
    80002812:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	1e4080e7          	jalr	484(ra) # 800019fa <myproc>
    8000281e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002820:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002822:	14102773          	csrr	a4,sepc
    80002826:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002828:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000282c:	47a1                	li	a5,8
    8000282e:	04f71c63          	bne	a4,a5,80002886 <usertrap+0x92>
    if(p->killed)
    80002832:	591c                	lw	a5,48(a0)
    80002834:	e3b9                	bnez	a5,8000287a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002836:	6cb8                	ld	a4,88(s1)
    80002838:	6f1c                	ld	a5,24(a4)
    8000283a:	0791                	addi	a5,a5,4
    8000283c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002842:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002846:	10079073          	csrw	sstatus,a5
    syscall();
    8000284a:	00000097          	auipc	ra,0x0
    8000284e:	2e0080e7          	jalr	736(ra) # 80002b2a <syscall>
  if(p->killed)
    80002852:	589c                	lw	a5,48(s1)
    80002854:	ebc1                	bnez	a5,800028e4 <usertrap+0xf0>
  usertrapret();
    80002856:	00000097          	auipc	ra,0x0
    8000285a:	e18080e7          	jalr	-488(ra) # 8000266e <usertrapret>
}
    8000285e:	60e2                	ld	ra,24(sp)
    80002860:	6442                	ld	s0,16(sp)
    80002862:	64a2                	ld	s1,8(sp)
    80002864:	6902                	ld	s2,0(sp)
    80002866:	6105                	addi	sp,sp,32
    80002868:	8082                	ret
    panic("usertrap: not from user mode");
    8000286a:	00006517          	auipc	a0,0x6
    8000286e:	a8e50513          	addi	a0,a0,-1394 # 800082f8 <states.0+0x50>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	cd4080e7          	jalr	-812(ra) # 80000546 <panic>
      exit(-1);
    8000287a:	557d                	li	a0,-1
    8000287c:	00000097          	auipc	ra,0x0
    80002880:	84c080e7          	jalr	-1972(ra) # 800020c8 <exit>
    80002884:	bf4d                	j	80002836 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	ecc080e7          	jalr	-308(ra) # 80002752 <devintr>
    8000288e:	892a                	mv	s2,a0
    80002890:	c501                	beqz	a0,80002898 <usertrap+0xa4>
  if(p->killed)
    80002892:	589c                	lw	a5,48(s1)
    80002894:	c3a1                	beqz	a5,800028d4 <usertrap+0xe0>
    80002896:	a815                	j	800028ca <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002898:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000289c:	5c90                	lw	a2,56(s1)
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	a7a50513          	addi	a0,a0,-1414 # 80008318 <states.0+0x70>
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	cea080e7          	jalr	-790(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028b6:	00006517          	auipc	a0,0x6
    800028ba:	a9250513          	addi	a0,a0,-1390 # 80008348 <states.0+0xa0>
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	cd2080e7          	jalr	-814(ra) # 80000590 <printf>
    p->killed = 1;
    800028c6:	4785                	li	a5,1
    800028c8:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028ca:	557d                	li	a0,-1
    800028cc:	fffff097          	auipc	ra,0xfffff
    800028d0:	7fc080e7          	jalr	2044(ra) # 800020c8 <exit>
  if(which_dev == 2)
    800028d4:	4789                	li	a5,2
    800028d6:	f8f910e3          	bne	s2,a5,80002856 <usertrap+0x62>
    yield();
    800028da:	00000097          	auipc	ra,0x0
    800028de:	8f8080e7          	jalr	-1800(ra) # 800021d2 <yield>
    800028e2:	bf95                	j	80002856 <usertrap+0x62>
  int which_dev = 0;
    800028e4:	4901                	li	s2,0
    800028e6:	b7d5                	j	800028ca <usertrap+0xd6>

00000000800028e8 <kerneltrap>:
{
    800028e8:	7179                	addi	sp,sp,-48
    800028ea:	f406                	sd	ra,40(sp)
    800028ec:	f022                	sd	s0,32(sp)
    800028ee:	ec26                	sd	s1,24(sp)
    800028f0:	e84a                	sd	s2,16(sp)
    800028f2:	e44e                	sd	s3,8(sp)
    800028f4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fe:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002902:	1004f793          	andi	a5,s1,256
    80002906:	cb85                	beqz	a5,80002936 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002908:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000290c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000290e:	ef85                	bnez	a5,80002946 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002910:	00000097          	auipc	ra,0x0
    80002914:	e42080e7          	jalr	-446(ra) # 80002752 <devintr>
    80002918:	cd1d                	beqz	a0,80002956 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000291a:	4789                	li	a5,2
    8000291c:	06f50a63          	beq	a0,a5,80002990 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002920:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002924:	10049073          	csrw	sstatus,s1
}
    80002928:	70a2                	ld	ra,40(sp)
    8000292a:	7402                	ld	s0,32(sp)
    8000292c:	64e2                	ld	s1,24(sp)
    8000292e:	6942                	ld	s2,16(sp)
    80002930:	69a2                	ld	s3,8(sp)
    80002932:	6145                	addi	sp,sp,48
    80002934:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002936:	00006517          	auipc	a0,0x6
    8000293a:	a3250513          	addi	a0,a0,-1486 # 80008368 <states.0+0xc0>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c08080e7          	jalr	-1016(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002946:	00006517          	auipc	a0,0x6
    8000294a:	a4a50513          	addi	a0,a0,-1462 # 80008390 <states.0+0xe8>
    8000294e:	ffffe097          	auipc	ra,0xffffe
    80002952:	bf8080e7          	jalr	-1032(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002956:	85ce                	mv	a1,s3
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a5850513          	addi	a0,a0,-1448 # 800083b0 <states.0+0x108>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	c30080e7          	jalr	-976(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002968:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002970:	00006517          	auipc	a0,0x6
    80002974:	a5050513          	addi	a0,a0,-1456 # 800083c0 <states.0+0x118>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	c18080e7          	jalr	-1000(ra) # 80000590 <printf>
    panic("kerneltrap");
    80002980:	00006517          	auipc	a0,0x6
    80002984:	a5850513          	addi	a0,a0,-1448 # 800083d8 <states.0+0x130>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	bbe080e7          	jalr	-1090(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002990:	fffff097          	auipc	ra,0xfffff
    80002994:	06a080e7          	jalr	106(ra) # 800019fa <myproc>
    80002998:	d541                	beqz	a0,80002920 <kerneltrap+0x38>
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	060080e7          	jalr	96(ra) # 800019fa <myproc>
    800029a2:	4d18                	lw	a4,24(a0)
    800029a4:	478d                	li	a5,3
    800029a6:	f6f71de3          	bne	a4,a5,80002920 <kerneltrap+0x38>
    yield();
    800029aa:	00000097          	auipc	ra,0x0
    800029ae:	828080e7          	jalr	-2008(ra) # 800021d2 <yield>
    800029b2:	b7bd                	j	80002920 <kerneltrap+0x38>

00000000800029b4 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029b4:	1101                	addi	sp,sp,-32
    800029b6:	ec06                	sd	ra,24(sp)
    800029b8:	e822                	sd	s0,16(sp)
    800029ba:	e426                	sd	s1,8(sp)
    800029bc:	1000                	addi	s0,sp,32
    800029be:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	03a080e7          	jalr	58(ra) # 800019fa <myproc>
  switch (n) {
    800029c8:	4795                	li	a5,5
    800029ca:	0497e163          	bltu	a5,s1,80002a0c <argraw+0x58>
    800029ce:	048a                	slli	s1,s1,0x2
    800029d0:	00006717          	auipc	a4,0x6
    800029d4:	a4070713          	addi	a4,a4,-1472 # 80008410 <states.0+0x168>
    800029d8:	94ba                	add	s1,s1,a4
    800029da:	409c                	lw	a5,0(s1)
    800029dc:	97ba                	add	a5,a5,a4
    800029de:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029e0:	6d3c                	ld	a5,88(a0)
    800029e2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029e4:	60e2                	ld	ra,24(sp)
    800029e6:	6442                	ld	s0,16(sp)
    800029e8:	64a2                	ld	s1,8(sp)
    800029ea:	6105                	addi	sp,sp,32
    800029ec:	8082                	ret
    return p->trapframe->a1;
    800029ee:	6d3c                	ld	a5,88(a0)
    800029f0:	7fa8                	ld	a0,120(a5)
    800029f2:	bfcd                	j	800029e4 <argraw+0x30>
    return p->trapframe->a2;
    800029f4:	6d3c                	ld	a5,88(a0)
    800029f6:	63c8                	ld	a0,128(a5)
    800029f8:	b7f5                	j	800029e4 <argraw+0x30>
    return p->trapframe->a3;
    800029fa:	6d3c                	ld	a5,88(a0)
    800029fc:	67c8                	ld	a0,136(a5)
    800029fe:	b7dd                	j	800029e4 <argraw+0x30>
    return p->trapframe->a4;
    80002a00:	6d3c                	ld	a5,88(a0)
    80002a02:	6bc8                	ld	a0,144(a5)
    80002a04:	b7c5                	j	800029e4 <argraw+0x30>
    return p->trapframe->a5;
    80002a06:	6d3c                	ld	a5,88(a0)
    80002a08:	6fc8                	ld	a0,152(a5)
    80002a0a:	bfe9                	j	800029e4 <argraw+0x30>
  panic("argraw");
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	9dc50513          	addi	a0,a0,-1572 # 800083e8 <states.0+0x140>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b32080e7          	jalr	-1230(ra) # 80000546 <panic>

0000000080002a1c <fetchaddr>:
{
    80002a1c:	1101                	addi	sp,sp,-32
    80002a1e:	ec06                	sd	ra,24(sp)
    80002a20:	e822                	sd	s0,16(sp)
    80002a22:	e426                	sd	s1,8(sp)
    80002a24:	e04a                	sd	s2,0(sp)
    80002a26:	1000                	addi	s0,sp,32
    80002a28:	84aa                	mv	s1,a0
    80002a2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	fce080e7          	jalr	-50(ra) # 800019fa <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a34:	653c                	ld	a5,72(a0)
    80002a36:	02f4f863          	bgeu	s1,a5,80002a66 <fetchaddr+0x4a>
    80002a3a:	00848713          	addi	a4,s1,8
    80002a3e:	02e7e663          	bltu	a5,a4,80002a6a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a42:	46a1                	li	a3,8
    80002a44:	8626                	mv	a2,s1
    80002a46:	85ca                	mv	a1,s2
    80002a48:	6928                	ld	a0,80(a0)
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	d0c080e7          	jalr	-756(ra) # 80001756 <copyin>
    80002a52:	00a03533          	snez	a0,a0
    80002a56:	40a00533          	neg	a0,a0
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6902                	ld	s2,0(sp)
    80002a62:	6105                	addi	sp,sp,32
    80002a64:	8082                	ret
    return -1;
    80002a66:	557d                	li	a0,-1
    80002a68:	bfcd                	j	80002a5a <fetchaddr+0x3e>
    80002a6a:	557d                	li	a0,-1
    80002a6c:	b7fd                	j	80002a5a <fetchaddr+0x3e>

0000000080002a6e <fetchstr>:
{
    80002a6e:	7179                	addi	sp,sp,-48
    80002a70:	f406                	sd	ra,40(sp)
    80002a72:	f022                	sd	s0,32(sp)
    80002a74:	ec26                	sd	s1,24(sp)
    80002a76:	e84a                	sd	s2,16(sp)
    80002a78:	e44e                	sd	s3,8(sp)
    80002a7a:	1800                	addi	s0,sp,48
    80002a7c:	892a                	mv	s2,a0
    80002a7e:	84ae                	mv	s1,a1
    80002a80:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a82:	fffff097          	auipc	ra,0xfffff
    80002a86:	f78080e7          	jalr	-136(ra) # 800019fa <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a8a:	86ce                	mv	a3,s3
    80002a8c:	864a                	mv	a2,s2
    80002a8e:	85a6                	mv	a1,s1
    80002a90:	6928                	ld	a0,80(a0)
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	d52080e7          	jalr	-686(ra) # 800017e4 <copyinstr>
  if(err < 0)
    80002a9a:	00054763          	bltz	a0,80002aa8 <fetchstr+0x3a>
  return strlen(buf);
    80002a9e:	8526                	mv	a0,s1
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	3e0080e7          	jalr	992(ra) # 80000e80 <strlen>
}
    80002aa8:	70a2                	ld	ra,40(sp)
    80002aaa:	7402                	ld	s0,32(sp)
    80002aac:	64e2                	ld	s1,24(sp)
    80002aae:	6942                	ld	s2,16(sp)
    80002ab0:	69a2                	ld	s3,8(sp)
    80002ab2:	6145                	addi	sp,sp,48
    80002ab4:	8082                	ret

0000000080002ab6 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	e426                	sd	s1,8(sp)
    80002abe:	1000                	addi	s0,sp,32
    80002ac0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ac2:	00000097          	auipc	ra,0x0
    80002ac6:	ef2080e7          	jalr	-270(ra) # 800029b4 <argraw>
    80002aca:	c088                	sw	a0,0(s1)
  return 0;
}
    80002acc:	4501                	li	a0,0
    80002ace:	60e2                	ld	ra,24(sp)
    80002ad0:	6442                	ld	s0,16(sp)
    80002ad2:	64a2                	ld	s1,8(sp)
    80002ad4:	6105                	addi	sp,sp,32
    80002ad6:	8082                	ret

0000000080002ad8 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ad8:	1101                	addi	sp,sp,-32
    80002ada:	ec06                	sd	ra,24(sp)
    80002adc:	e822                	sd	s0,16(sp)
    80002ade:	e426                	sd	s1,8(sp)
    80002ae0:	1000                	addi	s0,sp,32
    80002ae2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	ed0080e7          	jalr	-304(ra) # 800029b4 <argraw>
    80002aec:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aee:	4501                	li	a0,0
    80002af0:	60e2                	ld	ra,24(sp)
    80002af2:	6442                	ld	s0,16(sp)
    80002af4:	64a2                	ld	s1,8(sp)
    80002af6:	6105                	addi	sp,sp,32
    80002af8:	8082                	ret

0000000080002afa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002afa:	1101                	addi	sp,sp,-32
    80002afc:	ec06                	sd	ra,24(sp)
    80002afe:	e822                	sd	s0,16(sp)
    80002b00:	e426                	sd	s1,8(sp)
    80002b02:	e04a                	sd	s2,0(sp)
    80002b04:	1000                	addi	s0,sp,32
    80002b06:	84ae                	mv	s1,a1
    80002b08:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	eaa080e7          	jalr	-342(ra) # 800029b4 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b12:	864a                	mv	a2,s2
    80002b14:	85a6                	mv	a1,s1
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	f58080e7          	jalr	-168(ra) # 80002a6e <fetchstr>
}
    80002b1e:	60e2                	ld	ra,24(sp)
    80002b20:	6442                	ld	s0,16(sp)
    80002b22:	64a2                	ld	s1,8(sp)
    80002b24:	6902                	ld	s2,0(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret

0000000080002b2a <syscall>:
[SYS_checkvm] sys_checkvm,
};

void
syscall(void)
{
    80002b2a:	1101                	addi	sp,sp,-32
    80002b2c:	ec06                	sd	ra,24(sp)
    80002b2e:	e822                	sd	s0,16(sp)
    80002b30:	e426                	sd	s1,8(sp)
    80002b32:	e04a                	sd	s2,0(sp)
    80002b34:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	ec4080e7          	jalr	-316(ra) # 800019fa <myproc>
    80002b3e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b40:	05853903          	ld	s2,88(a0)
    80002b44:	0a893783          	ld	a5,168(s2)
    80002b48:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b4c:	37fd                	addiw	a5,a5,-1
    80002b4e:	4755                	li	a4,21
    80002b50:	00f76f63          	bltu	a4,a5,80002b6e <syscall+0x44>
    80002b54:	00369713          	slli	a4,a3,0x3
    80002b58:	00006797          	auipc	a5,0x6
    80002b5c:	8d078793          	addi	a5,a5,-1840 # 80008428 <syscalls>
    80002b60:	97ba                	add	a5,a5,a4
    80002b62:	639c                	ld	a5,0(a5)
    80002b64:	c789                	beqz	a5,80002b6e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b66:	9782                	jalr	a5
    80002b68:	06a93823          	sd	a0,112(s2)
    80002b6c:	a839                	j	80002b8a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b6e:	15848613          	addi	a2,s1,344
    80002b72:	5c8c                	lw	a1,56(s1)
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	87c50513          	addi	a0,a0,-1924 # 800083f0 <states.0+0x148>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	a14080e7          	jalr	-1516(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b84:	6cbc                	ld	a5,88(s1)
    80002b86:	577d                	li	a4,-1
    80002b88:	fbb8                	sd	a4,112(a5)
  }
}
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6902                	ld	s2,0(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret

0000000080002b96 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b9e:	fec40593          	addi	a1,s0,-20
    80002ba2:	4501                	li	a0,0
    80002ba4:	00000097          	auipc	ra,0x0
    80002ba8:	f12080e7          	jalr	-238(ra) # 80002ab6 <argint>
    return -1;
    80002bac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002bae:	00054963          	bltz	a0,80002bc0 <sys_exit+0x2a>
  exit(n);
    80002bb2:	fec42503          	lw	a0,-20(s0)
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	512080e7          	jalr	1298(ra) # 800020c8 <exit>
  return 0;  // not reached
    80002bbe:	4781                	li	a5,0
}
    80002bc0:	853e                	mv	a0,a5
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	6105                	addi	sp,sp,32
    80002bc8:	8082                	ret

0000000080002bca <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bca:	1141                	addi	sp,sp,-16
    80002bcc:	e406                	sd	ra,8(sp)
    80002bce:	e022                	sd	s0,0(sp)
    80002bd0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	e28080e7          	jalr	-472(ra) # 800019fa <myproc>
}
    80002bda:	5d08                	lw	a0,56(a0)
    80002bdc:	60a2                	ld	ra,8(sp)
    80002bde:	6402                	ld	s0,0(sp)
    80002be0:	0141                	addi	sp,sp,16
    80002be2:	8082                	ret

0000000080002be4 <sys_fork>:

uint64
sys_fork(void)
{
    80002be4:	1141                	addi	sp,sp,-16
    80002be6:	e406                	sd	ra,8(sp)
    80002be8:	e022                	sd	s0,0(sp)
    80002bea:	0800                	addi	s0,sp,16
  return fork();
    80002bec:	fffff097          	auipc	ra,0xfffff
    80002bf0:	1d2080e7          	jalr	466(ra) # 80001dbe <fork>
}
    80002bf4:	60a2                	ld	ra,8(sp)
    80002bf6:	6402                	ld	s0,0(sp)
    80002bf8:	0141                	addi	sp,sp,16
    80002bfa:	8082                	ret

0000000080002bfc <sys_wait>:

uint64
sys_wait(void)
{
    80002bfc:	1101                	addi	sp,sp,-32
    80002bfe:	ec06                	sd	ra,24(sp)
    80002c00:	e822                	sd	s0,16(sp)
    80002c02:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c04:	fe840593          	addi	a1,s0,-24
    80002c08:	4501                	li	a0,0
    80002c0a:	00000097          	auipc	ra,0x0
    80002c0e:	ece080e7          	jalr	-306(ra) # 80002ad8 <argaddr>
    80002c12:	87aa                	mv	a5,a0
    return -1;
    80002c14:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c16:	0007c863          	bltz	a5,80002c26 <sys_wait+0x2a>
  return wait(p);
    80002c1a:	fe843503          	ld	a0,-24(s0)
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	66e080e7          	jalr	1646(ra) # 8000228c <wait>
}
    80002c26:	60e2                	ld	ra,24(sp)
    80002c28:	6442                	ld	s0,16(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c2e:	7179                	addi	sp,sp,-48
    80002c30:	f406                	sd	ra,40(sp)
    80002c32:	f022                	sd	s0,32(sp)
    80002c34:	ec26                	sd	s1,24(sp)
    80002c36:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c38:	fdc40593          	addi	a1,s0,-36
    80002c3c:	4501                	li	a0,0
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	e78080e7          	jalr	-392(ra) # 80002ab6 <argint>
    80002c46:	87aa                	mv	a5,a0
    return -1;
    80002c48:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c4a:	0207c063          	bltz	a5,80002c6a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	dac080e7          	jalr	-596(ra) # 800019fa <myproc>
    80002c56:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c58:	fdc42503          	lw	a0,-36(s0)
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	0ea080e7          	jalr	234(ra) # 80001d46 <growproc>
    80002c64:	00054863          	bltz	a0,80002c74 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c68:	8526                	mv	a0,s1
}
    80002c6a:	70a2                	ld	ra,40(sp)
    80002c6c:	7402                	ld	s0,32(sp)
    80002c6e:	64e2                	ld	s1,24(sp)
    80002c70:	6145                	addi	sp,sp,48
    80002c72:	8082                	ret
    return -1;
    80002c74:	557d                	li	a0,-1
    80002c76:	bfd5                	j	80002c6a <sys_sbrk+0x3c>

0000000080002c78 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c78:	7139                	addi	sp,sp,-64
    80002c7a:	fc06                	sd	ra,56(sp)
    80002c7c:	f822                	sd	s0,48(sp)
    80002c7e:	f426                	sd	s1,40(sp)
    80002c80:	f04a                	sd	s2,32(sp)
    80002c82:	ec4e                	sd	s3,24(sp)
    80002c84:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c86:	fcc40593          	addi	a1,s0,-52
    80002c8a:	4501                	li	a0,0
    80002c8c:	00000097          	auipc	ra,0x0
    80002c90:	e2a080e7          	jalr	-470(ra) # 80002ab6 <argint>
    return -1;
    80002c94:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c96:	06054563          	bltz	a0,80002d00 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c9a:	00015517          	auipc	a0,0x15
    80002c9e:	ace50513          	addi	a0,a0,-1330 # 80017768 <tickslock>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	f5e080e7          	jalr	-162(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002caa:	00006917          	auipc	s2,0x6
    80002cae:	37692903          	lw	s2,886(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002cb2:	fcc42783          	lw	a5,-52(s0)
    80002cb6:	cf85                	beqz	a5,80002cee <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002cb8:	00015997          	auipc	s3,0x15
    80002cbc:	ab098993          	addi	s3,s3,-1360 # 80017768 <tickslock>
    80002cc0:	00006497          	auipc	s1,0x6
    80002cc4:	36048493          	addi	s1,s1,864 # 80009020 <ticks>
    if(myproc()->killed){
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	d32080e7          	jalr	-718(ra) # 800019fa <myproc>
    80002cd0:	591c                	lw	a5,48(a0)
    80002cd2:	ef9d                	bnez	a5,80002d10 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002cd4:	85ce                	mv	a1,s3
    80002cd6:	8526                	mv	a0,s1
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	536080e7          	jalr	1334(ra) # 8000220e <sleep>
  while(ticks - ticks0 < n){
    80002ce0:	409c                	lw	a5,0(s1)
    80002ce2:	412787bb          	subw	a5,a5,s2
    80002ce6:	fcc42703          	lw	a4,-52(s0)
    80002cea:	fce7efe3          	bltu	a5,a4,80002cc8 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cee:	00015517          	auipc	a0,0x15
    80002cf2:	a7a50513          	addi	a0,a0,-1414 # 80017768 <tickslock>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	fbe080e7          	jalr	-66(ra) # 80000cb4 <release>
  return 0;
    80002cfe:	4781                	li	a5,0
}
    80002d00:	853e                	mv	a0,a5
    80002d02:	70e2                	ld	ra,56(sp)
    80002d04:	7442                	ld	s0,48(sp)
    80002d06:	74a2                	ld	s1,40(sp)
    80002d08:	7902                	ld	s2,32(sp)
    80002d0a:	69e2                	ld	s3,24(sp)
    80002d0c:	6121                	addi	sp,sp,64
    80002d0e:	8082                	ret
      release(&tickslock);
    80002d10:	00015517          	auipc	a0,0x15
    80002d14:	a5850513          	addi	a0,a0,-1448 # 80017768 <tickslock>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	f9c080e7          	jalr	-100(ra) # 80000cb4 <release>
      return -1;
    80002d20:	57fd                	li	a5,-1
    80002d22:	bff9                	j	80002d00 <sys_sleep+0x88>

0000000080002d24 <sys_kill>:

uint64
sys_kill(void)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002d2c:	fec40593          	addi	a1,s0,-20
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	d84080e7          	jalr	-636(ra) # 80002ab6 <argint>
    80002d3a:	87aa                	mv	a5,a0
    return -1;
    80002d3c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d3e:	0007c863          	bltz	a5,80002d4e <sys_kill+0x2a>
  return kill(pid);
    80002d42:	fec42503          	lw	a0,-20(s0)
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	6b2080e7          	jalr	1714(ra) # 800023f8 <kill>
}
    80002d4e:	60e2                	ld	ra,24(sp)
    80002d50:	6442                	ld	s0,16(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret

0000000080002d56 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d60:	00015517          	auipc	a0,0x15
    80002d64:	a0850513          	addi	a0,a0,-1528 # 80017768 <tickslock>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	e98080e7          	jalr	-360(ra) # 80000c00 <acquire>
  xticks = ticks;
    80002d70:	00006497          	auipc	s1,0x6
    80002d74:	2b04a483          	lw	s1,688(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d78:	00015517          	auipc	a0,0x15
    80002d7c:	9f050513          	addi	a0,a0,-1552 # 80017768 <tickslock>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	f34080e7          	jalr	-204(ra) # 80000cb4 <release>
  return xticks;
}
    80002d88:	02049513          	slli	a0,s1,0x20
    80002d8c:	9101                	srli	a0,a0,0x20
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	64a2                	ld	s1,8(sp)
    80002d94:	6105                	addi	sp,sp,32
    80002d96:	8082                	ret

0000000080002d98 <sys_checkvm>:

uint64
sys_checkvm()
{
    80002d98:	1141                	addi	sp,sp,-16
    80002d9a:	e406                	sd	ra,8(sp)
    80002d9c:	e022                	sd	s0,0(sp)
    80002d9e:	0800                	addi	s0,sp,16
  return (uint64)test_pagetable(); 
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	af4080e7          	jalr	-1292(ra) # 80001894 <test_pagetable>
    80002da8:	60a2                	ld	ra,8(sp)
    80002daa:	6402                	ld	s0,0(sp)
    80002dac:	0141                	addi	sp,sp,16
    80002dae:	8082                	ret

0000000080002db0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002db0:	7179                	addi	sp,sp,-48
    80002db2:	f406                	sd	ra,40(sp)
    80002db4:	f022                	sd	s0,32(sp)
    80002db6:	ec26                	sd	s1,24(sp)
    80002db8:	e84a                	sd	s2,16(sp)
    80002dba:	e44e                	sd	s3,8(sp)
    80002dbc:	e052                	sd	s4,0(sp)
    80002dbe:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002dc0:	00005597          	auipc	a1,0x5
    80002dc4:	72058593          	addi	a1,a1,1824 # 800084e0 <syscalls+0xb8>
    80002dc8:	00015517          	auipc	a0,0x15
    80002dcc:	9b850513          	addi	a0,a0,-1608 # 80017780 <bcache>
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	da0080e7          	jalr	-608(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002dd8:	0001d797          	auipc	a5,0x1d
    80002ddc:	9a878793          	addi	a5,a5,-1624 # 8001f780 <bcache+0x8000>
    80002de0:	0001d717          	auipc	a4,0x1d
    80002de4:	c0870713          	addi	a4,a4,-1016 # 8001f9e8 <bcache+0x8268>
    80002de8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002dec:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002df0:	00015497          	auipc	s1,0x15
    80002df4:	9a848493          	addi	s1,s1,-1624 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002df8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002dfa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dfc:	00005a17          	auipc	s4,0x5
    80002e00:	6eca0a13          	addi	s4,s4,1772 # 800084e8 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e04:	2b893783          	ld	a5,696(s2)
    80002e08:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e0a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e0e:	85d2                	mv	a1,s4
    80002e10:	01048513          	addi	a0,s1,16
    80002e14:	00001097          	auipc	ra,0x1
    80002e18:	4b2080e7          	jalr	1202(ra) # 800042c6 <initsleeplock>
    bcache.head.next->prev = b;
    80002e1c:	2b893783          	ld	a5,696(s2)
    80002e20:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e22:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e26:	45848493          	addi	s1,s1,1112
    80002e2a:	fd349de3          	bne	s1,s3,80002e04 <binit+0x54>
  }
}
    80002e2e:	70a2                	ld	ra,40(sp)
    80002e30:	7402                	ld	s0,32(sp)
    80002e32:	64e2                	ld	s1,24(sp)
    80002e34:	6942                	ld	s2,16(sp)
    80002e36:	69a2                	ld	s3,8(sp)
    80002e38:	6a02                	ld	s4,0(sp)
    80002e3a:	6145                	addi	sp,sp,48
    80002e3c:	8082                	ret

0000000080002e3e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e3e:	7179                	addi	sp,sp,-48
    80002e40:	f406                	sd	ra,40(sp)
    80002e42:	f022                	sd	s0,32(sp)
    80002e44:	ec26                	sd	s1,24(sp)
    80002e46:	e84a                	sd	s2,16(sp)
    80002e48:	e44e                	sd	s3,8(sp)
    80002e4a:	1800                	addi	s0,sp,48
    80002e4c:	892a                	mv	s2,a0
    80002e4e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002e50:	00015517          	auipc	a0,0x15
    80002e54:	93050513          	addi	a0,a0,-1744 # 80017780 <bcache>
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	da8080e7          	jalr	-600(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e60:	0001d497          	auipc	s1,0x1d
    80002e64:	bd84b483          	ld	s1,-1064(s1) # 8001fa38 <bcache+0x82b8>
    80002e68:	0001d797          	auipc	a5,0x1d
    80002e6c:	b8078793          	addi	a5,a5,-1152 # 8001f9e8 <bcache+0x8268>
    80002e70:	02f48f63          	beq	s1,a5,80002eae <bread+0x70>
    80002e74:	873e                	mv	a4,a5
    80002e76:	a021                	j	80002e7e <bread+0x40>
    80002e78:	68a4                	ld	s1,80(s1)
    80002e7a:	02e48a63          	beq	s1,a4,80002eae <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e7e:	449c                	lw	a5,8(s1)
    80002e80:	ff279ce3          	bne	a5,s2,80002e78 <bread+0x3a>
    80002e84:	44dc                	lw	a5,12(s1)
    80002e86:	ff3799e3          	bne	a5,s3,80002e78 <bread+0x3a>
      b->refcnt++;
    80002e8a:	40bc                	lw	a5,64(s1)
    80002e8c:	2785                	addiw	a5,a5,1
    80002e8e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e90:	00015517          	auipc	a0,0x15
    80002e94:	8f050513          	addi	a0,a0,-1808 # 80017780 <bcache>
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	e1c080e7          	jalr	-484(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002ea0:	01048513          	addi	a0,s1,16
    80002ea4:	00001097          	auipc	ra,0x1
    80002ea8:	45c080e7          	jalr	1116(ra) # 80004300 <acquiresleep>
      return b;
    80002eac:	a8b9                	j	80002f0a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002eae:	0001d497          	auipc	s1,0x1d
    80002eb2:	b824b483          	ld	s1,-1150(s1) # 8001fa30 <bcache+0x82b0>
    80002eb6:	0001d797          	auipc	a5,0x1d
    80002eba:	b3278793          	addi	a5,a5,-1230 # 8001f9e8 <bcache+0x8268>
    80002ebe:	00f48863          	beq	s1,a5,80002ece <bread+0x90>
    80002ec2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002ec4:	40bc                	lw	a5,64(s1)
    80002ec6:	cf81                	beqz	a5,80002ede <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ec8:	64a4                	ld	s1,72(s1)
    80002eca:	fee49de3          	bne	s1,a4,80002ec4 <bread+0x86>
  panic("bget: no buffers");
    80002ece:	00005517          	auipc	a0,0x5
    80002ed2:	62250513          	addi	a0,a0,1570 # 800084f0 <syscalls+0xc8>
    80002ed6:	ffffd097          	auipc	ra,0xffffd
    80002eda:	670080e7          	jalr	1648(ra) # 80000546 <panic>
      b->dev = dev;
    80002ede:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002ee2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002ee6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002eea:	4785                	li	a5,1
    80002eec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eee:	00015517          	auipc	a0,0x15
    80002ef2:	89250513          	addi	a0,a0,-1902 # 80017780 <bcache>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	dbe080e7          	jalr	-578(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002efe:	01048513          	addi	a0,s1,16
    80002f02:	00001097          	auipc	ra,0x1
    80002f06:	3fe080e7          	jalr	1022(ra) # 80004300 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f0a:	409c                	lw	a5,0(s1)
    80002f0c:	cb89                	beqz	a5,80002f1e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f0e:	8526                	mv	a0,s1
    80002f10:	70a2                	ld	ra,40(sp)
    80002f12:	7402                	ld	s0,32(sp)
    80002f14:	64e2                	ld	s1,24(sp)
    80002f16:	6942                	ld	s2,16(sp)
    80002f18:	69a2                	ld	s3,8(sp)
    80002f1a:	6145                	addi	sp,sp,48
    80002f1c:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f1e:	4581                	li	a1,0
    80002f20:	8526                	mv	a0,s1
    80002f22:	00003097          	auipc	ra,0x3
    80002f26:	036080e7          	jalr	54(ra) # 80005f58 <virtio_disk_rw>
    b->valid = 1;
    80002f2a:	4785                	li	a5,1
    80002f2c:	c09c                	sw	a5,0(s1)
  return b;
    80002f2e:	b7c5                	j	80002f0e <bread+0xd0>

0000000080002f30 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	e426                	sd	s1,8(sp)
    80002f38:	1000                	addi	s0,sp,32
    80002f3a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f3c:	0541                	addi	a0,a0,16
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	45c080e7          	jalr	1116(ra) # 8000439a <holdingsleep>
    80002f46:	cd01                	beqz	a0,80002f5e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f48:	4585                	li	a1,1
    80002f4a:	8526                	mv	a0,s1
    80002f4c:	00003097          	auipc	ra,0x3
    80002f50:	00c080e7          	jalr	12(ra) # 80005f58 <virtio_disk_rw>
}
    80002f54:	60e2                	ld	ra,24(sp)
    80002f56:	6442                	ld	s0,16(sp)
    80002f58:	64a2                	ld	s1,8(sp)
    80002f5a:	6105                	addi	sp,sp,32
    80002f5c:	8082                	ret
    panic("bwrite");
    80002f5e:	00005517          	auipc	a0,0x5
    80002f62:	5aa50513          	addi	a0,a0,1450 # 80008508 <syscalls+0xe0>
    80002f66:	ffffd097          	auipc	ra,0xffffd
    80002f6a:	5e0080e7          	jalr	1504(ra) # 80000546 <panic>

0000000080002f6e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	e426                	sd	s1,8(sp)
    80002f76:	e04a                	sd	s2,0(sp)
    80002f78:	1000                	addi	s0,sp,32
    80002f7a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f7c:	01050913          	addi	s2,a0,16
    80002f80:	854a                	mv	a0,s2
    80002f82:	00001097          	auipc	ra,0x1
    80002f86:	418080e7          	jalr	1048(ra) # 8000439a <holdingsleep>
    80002f8a:	c92d                	beqz	a0,80002ffc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f8c:	854a                	mv	a0,s2
    80002f8e:	00001097          	auipc	ra,0x1
    80002f92:	3c8080e7          	jalr	968(ra) # 80004356 <releasesleep>

  acquire(&bcache.lock);
    80002f96:	00014517          	auipc	a0,0x14
    80002f9a:	7ea50513          	addi	a0,a0,2026 # 80017780 <bcache>
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	c62080e7          	jalr	-926(ra) # 80000c00 <acquire>
  b->refcnt--;
    80002fa6:	40bc                	lw	a5,64(s1)
    80002fa8:	37fd                	addiw	a5,a5,-1
    80002faa:	0007871b          	sext.w	a4,a5
    80002fae:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fb0:	eb05                	bnez	a4,80002fe0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fb2:	68bc                	ld	a5,80(s1)
    80002fb4:	64b8                	ld	a4,72(s1)
    80002fb6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002fb8:	64bc                	ld	a5,72(s1)
    80002fba:	68b8                	ld	a4,80(s1)
    80002fbc:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fbe:	0001c797          	auipc	a5,0x1c
    80002fc2:	7c278793          	addi	a5,a5,1986 # 8001f780 <bcache+0x8000>
    80002fc6:	2b87b703          	ld	a4,696(a5)
    80002fca:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fcc:	0001d717          	auipc	a4,0x1d
    80002fd0:	a1c70713          	addi	a4,a4,-1508 # 8001f9e8 <bcache+0x8268>
    80002fd4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002fd6:	2b87b703          	ld	a4,696(a5)
    80002fda:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002fdc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002fe0:	00014517          	auipc	a0,0x14
    80002fe4:	7a050513          	addi	a0,a0,1952 # 80017780 <bcache>
    80002fe8:	ffffe097          	auipc	ra,0xffffe
    80002fec:	ccc080e7          	jalr	-820(ra) # 80000cb4 <release>
}
    80002ff0:	60e2                	ld	ra,24(sp)
    80002ff2:	6442                	ld	s0,16(sp)
    80002ff4:	64a2                	ld	s1,8(sp)
    80002ff6:	6902                	ld	s2,0(sp)
    80002ff8:	6105                	addi	sp,sp,32
    80002ffa:	8082                	ret
    panic("brelse");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	51450513          	addi	a0,a0,1300 # 80008510 <syscalls+0xe8>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	542080e7          	jalr	1346(ra) # 80000546 <panic>

000000008000300c <bpin>:

void
bpin(struct buf *b) {
    8000300c:	1101                	addi	sp,sp,-32
    8000300e:	ec06                	sd	ra,24(sp)
    80003010:	e822                	sd	s0,16(sp)
    80003012:	e426                	sd	s1,8(sp)
    80003014:	1000                	addi	s0,sp,32
    80003016:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003018:	00014517          	auipc	a0,0x14
    8000301c:	76850513          	addi	a0,a0,1896 # 80017780 <bcache>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	be0080e7          	jalr	-1056(ra) # 80000c00 <acquire>
  b->refcnt++;
    80003028:	40bc                	lw	a5,64(s1)
    8000302a:	2785                	addiw	a5,a5,1
    8000302c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000302e:	00014517          	auipc	a0,0x14
    80003032:	75250513          	addi	a0,a0,1874 # 80017780 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c7e080e7          	jalr	-898(ra) # 80000cb4 <release>
}
    8000303e:	60e2                	ld	ra,24(sp)
    80003040:	6442                	ld	s0,16(sp)
    80003042:	64a2                	ld	s1,8(sp)
    80003044:	6105                	addi	sp,sp,32
    80003046:	8082                	ret

0000000080003048 <bunpin>:

void
bunpin(struct buf *b) {
    80003048:	1101                	addi	sp,sp,-32
    8000304a:	ec06                	sd	ra,24(sp)
    8000304c:	e822                	sd	s0,16(sp)
    8000304e:	e426                	sd	s1,8(sp)
    80003050:	1000                	addi	s0,sp,32
    80003052:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003054:	00014517          	auipc	a0,0x14
    80003058:	72c50513          	addi	a0,a0,1836 # 80017780 <bcache>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	ba4080e7          	jalr	-1116(ra) # 80000c00 <acquire>
  b->refcnt--;
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	37fd                	addiw	a5,a5,-1
    80003068:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000306a:	00014517          	auipc	a0,0x14
    8000306e:	71650513          	addi	a0,a0,1814 # 80017780 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c42080e7          	jalr	-958(ra) # 80000cb4 <release>
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret

0000000080003084 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	e04a                	sd	s2,0(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003092:	00d5d59b          	srliw	a1,a1,0xd
    80003096:	0001d797          	auipc	a5,0x1d
    8000309a:	dc67a783          	lw	a5,-570(a5) # 8001fe5c <sb+0x1c>
    8000309e:	9dbd                	addw	a1,a1,a5
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	d9e080e7          	jalr	-610(ra) # 80002e3e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030a8:	0074f713          	andi	a4,s1,7
    800030ac:	4785                	li	a5,1
    800030ae:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030b2:	14ce                	slli	s1,s1,0x33
    800030b4:	90d9                	srli	s1,s1,0x36
    800030b6:	00950733          	add	a4,a0,s1
    800030ba:	05874703          	lbu	a4,88(a4)
    800030be:	00e7f6b3          	and	a3,a5,a4
    800030c2:	c69d                	beqz	a3,800030f0 <bfree+0x6c>
    800030c4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030c6:	94aa                	add	s1,s1,a0
    800030c8:	fff7c793          	not	a5,a5
    800030cc:	8f7d                	and	a4,a4,a5
    800030ce:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030d2:	00001097          	auipc	ra,0x1
    800030d6:	108080e7          	jalr	264(ra) # 800041da <log_write>
  brelse(bp);
    800030da:	854a                	mv	a0,s2
    800030dc:	00000097          	auipc	ra,0x0
    800030e0:	e92080e7          	jalr	-366(ra) # 80002f6e <brelse>
}
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6902                	ld	s2,0(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret
    panic("freeing free block");
    800030f0:	00005517          	auipc	a0,0x5
    800030f4:	42850513          	addi	a0,a0,1064 # 80008518 <syscalls+0xf0>
    800030f8:	ffffd097          	auipc	ra,0xffffd
    800030fc:	44e080e7          	jalr	1102(ra) # 80000546 <panic>

0000000080003100 <balloc>:
{
    80003100:	711d                	addi	sp,sp,-96
    80003102:	ec86                	sd	ra,88(sp)
    80003104:	e8a2                	sd	s0,80(sp)
    80003106:	e4a6                	sd	s1,72(sp)
    80003108:	e0ca                	sd	s2,64(sp)
    8000310a:	fc4e                	sd	s3,56(sp)
    8000310c:	f852                	sd	s4,48(sp)
    8000310e:	f456                	sd	s5,40(sp)
    80003110:	f05a                	sd	s6,32(sp)
    80003112:	ec5e                	sd	s7,24(sp)
    80003114:	e862                	sd	s8,16(sp)
    80003116:	e466                	sd	s9,8(sp)
    80003118:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000311a:	0001d797          	auipc	a5,0x1d
    8000311e:	d2a7a783          	lw	a5,-726(a5) # 8001fe44 <sb+0x4>
    80003122:	cbc1                	beqz	a5,800031b2 <balloc+0xb2>
    80003124:	8baa                	mv	s7,a0
    80003126:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003128:	0001db17          	auipc	s6,0x1d
    8000312c:	d18b0b13          	addi	s6,s6,-744 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003130:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003132:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003134:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003136:	6c89                	lui	s9,0x2
    80003138:	a831                	j	80003154 <balloc+0x54>
    brelse(bp);
    8000313a:	854a                	mv	a0,s2
    8000313c:	00000097          	auipc	ra,0x0
    80003140:	e32080e7          	jalr	-462(ra) # 80002f6e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003144:	015c87bb          	addw	a5,s9,s5
    80003148:	00078a9b          	sext.w	s5,a5
    8000314c:	004b2703          	lw	a4,4(s6)
    80003150:	06eaf163          	bgeu	s5,a4,800031b2 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003154:	41fad79b          	sraiw	a5,s5,0x1f
    80003158:	0137d79b          	srliw	a5,a5,0x13
    8000315c:	015787bb          	addw	a5,a5,s5
    80003160:	40d7d79b          	sraiw	a5,a5,0xd
    80003164:	01cb2583          	lw	a1,28(s6)
    80003168:	9dbd                	addw	a1,a1,a5
    8000316a:	855e                	mv	a0,s7
    8000316c:	00000097          	auipc	ra,0x0
    80003170:	cd2080e7          	jalr	-814(ra) # 80002e3e <bread>
    80003174:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003176:	004b2503          	lw	a0,4(s6)
    8000317a:	000a849b          	sext.w	s1,s5
    8000317e:	8762                	mv	a4,s8
    80003180:	faa4fde3          	bgeu	s1,a0,8000313a <balloc+0x3a>
      m = 1 << (bi % 8);
    80003184:	00777693          	andi	a3,a4,7
    80003188:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000318c:	41f7579b          	sraiw	a5,a4,0x1f
    80003190:	01d7d79b          	srliw	a5,a5,0x1d
    80003194:	9fb9                	addw	a5,a5,a4
    80003196:	4037d79b          	sraiw	a5,a5,0x3
    8000319a:	00f90633          	add	a2,s2,a5
    8000319e:	05864603          	lbu	a2,88(a2)
    800031a2:	00c6f5b3          	and	a1,a3,a2
    800031a6:	cd91                	beqz	a1,800031c2 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031a8:	2705                	addiw	a4,a4,1
    800031aa:	2485                	addiw	s1,s1,1
    800031ac:	fd471ae3          	bne	a4,s4,80003180 <balloc+0x80>
    800031b0:	b769                	j	8000313a <balloc+0x3a>
  panic("balloc: out of blocks");
    800031b2:	00005517          	auipc	a0,0x5
    800031b6:	37e50513          	addi	a0,a0,894 # 80008530 <syscalls+0x108>
    800031ba:	ffffd097          	auipc	ra,0xffffd
    800031be:	38c080e7          	jalr	908(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800031c2:	97ca                	add	a5,a5,s2
    800031c4:	8e55                	or	a2,a2,a3
    800031c6:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800031ca:	854a                	mv	a0,s2
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	00e080e7          	jalr	14(ra) # 800041da <log_write>
        brelse(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	d98080e7          	jalr	-616(ra) # 80002f6e <brelse>
  bp = bread(dev, bno);
    800031de:	85a6                	mv	a1,s1
    800031e0:	855e                	mv	a0,s7
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	c5c080e7          	jalr	-932(ra) # 80002e3e <bread>
    800031ea:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031ec:	40000613          	li	a2,1024
    800031f0:	4581                	li	a1,0
    800031f2:	05850513          	addi	a0,a0,88
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	b06080e7          	jalr	-1274(ra) # 80000cfc <memset>
  log_write(bp);
    800031fe:	854a                	mv	a0,s2
    80003200:	00001097          	auipc	ra,0x1
    80003204:	fda080e7          	jalr	-38(ra) # 800041da <log_write>
  brelse(bp);
    80003208:	854a                	mv	a0,s2
    8000320a:	00000097          	auipc	ra,0x0
    8000320e:	d64080e7          	jalr	-668(ra) # 80002f6e <brelse>
}
    80003212:	8526                	mv	a0,s1
    80003214:	60e6                	ld	ra,88(sp)
    80003216:	6446                	ld	s0,80(sp)
    80003218:	64a6                	ld	s1,72(sp)
    8000321a:	6906                	ld	s2,64(sp)
    8000321c:	79e2                	ld	s3,56(sp)
    8000321e:	7a42                	ld	s4,48(sp)
    80003220:	7aa2                	ld	s5,40(sp)
    80003222:	7b02                	ld	s6,32(sp)
    80003224:	6be2                	ld	s7,24(sp)
    80003226:	6c42                	ld	s8,16(sp)
    80003228:	6ca2                	ld	s9,8(sp)
    8000322a:	6125                	addi	sp,sp,96
    8000322c:	8082                	ret

000000008000322e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000322e:	7179                	addi	sp,sp,-48
    80003230:	f406                	sd	ra,40(sp)
    80003232:	f022                	sd	s0,32(sp)
    80003234:	ec26                	sd	s1,24(sp)
    80003236:	e84a                	sd	s2,16(sp)
    80003238:	e44e                	sd	s3,8(sp)
    8000323a:	e052                	sd	s4,0(sp)
    8000323c:	1800                	addi	s0,sp,48
    8000323e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003240:	47ad                	li	a5,11
    80003242:	04b7fe63          	bgeu	a5,a1,8000329e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003246:	ff45849b          	addiw	s1,a1,-12
    8000324a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000324e:	0ff00793          	li	a5,255
    80003252:	0ae7e463          	bltu	a5,a4,800032fa <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003256:	08052583          	lw	a1,128(a0)
    8000325a:	c5b5                	beqz	a1,800032c6 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000325c:	00092503          	lw	a0,0(s2)
    80003260:	00000097          	auipc	ra,0x0
    80003264:	bde080e7          	jalr	-1058(ra) # 80002e3e <bread>
    80003268:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000326a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000326e:	02049713          	slli	a4,s1,0x20
    80003272:	01e75593          	srli	a1,a4,0x1e
    80003276:	00b784b3          	add	s1,a5,a1
    8000327a:	0004a983          	lw	s3,0(s1)
    8000327e:	04098e63          	beqz	s3,800032da <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003282:	8552                	mv	a0,s4
    80003284:	00000097          	auipc	ra,0x0
    80003288:	cea080e7          	jalr	-790(ra) # 80002f6e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000328c:	854e                	mv	a0,s3
    8000328e:	70a2                	ld	ra,40(sp)
    80003290:	7402                	ld	s0,32(sp)
    80003292:	64e2                	ld	s1,24(sp)
    80003294:	6942                	ld	s2,16(sp)
    80003296:	69a2                	ld	s3,8(sp)
    80003298:	6a02                	ld	s4,0(sp)
    8000329a:	6145                	addi	sp,sp,48
    8000329c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000329e:	02059793          	slli	a5,a1,0x20
    800032a2:	01e7d593          	srli	a1,a5,0x1e
    800032a6:	00b504b3          	add	s1,a0,a1
    800032aa:	0504a983          	lw	s3,80(s1)
    800032ae:	fc099fe3          	bnez	s3,8000328c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032b2:	4108                	lw	a0,0(a0)
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	e4c080e7          	jalr	-436(ra) # 80003100 <balloc>
    800032bc:	0005099b          	sext.w	s3,a0
    800032c0:	0534a823          	sw	s3,80(s1)
    800032c4:	b7e1                	j	8000328c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032c6:	4108                	lw	a0,0(a0)
    800032c8:	00000097          	auipc	ra,0x0
    800032cc:	e38080e7          	jalr	-456(ra) # 80003100 <balloc>
    800032d0:	0005059b          	sext.w	a1,a0
    800032d4:	08b92023          	sw	a1,128(s2)
    800032d8:	b751                	j	8000325c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800032da:	00092503          	lw	a0,0(s2)
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	e22080e7          	jalr	-478(ra) # 80003100 <balloc>
    800032e6:	0005099b          	sext.w	s3,a0
    800032ea:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800032ee:	8552                	mv	a0,s4
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	eea080e7          	jalr	-278(ra) # 800041da <log_write>
    800032f8:	b769                	j	80003282 <bmap+0x54>
  panic("bmap: out of range");
    800032fa:	00005517          	auipc	a0,0x5
    800032fe:	24e50513          	addi	a0,a0,590 # 80008548 <syscalls+0x120>
    80003302:	ffffd097          	auipc	ra,0xffffd
    80003306:	244080e7          	jalr	580(ra) # 80000546 <panic>

000000008000330a <iget>:
{
    8000330a:	7179                	addi	sp,sp,-48
    8000330c:	f406                	sd	ra,40(sp)
    8000330e:	f022                	sd	s0,32(sp)
    80003310:	ec26                	sd	s1,24(sp)
    80003312:	e84a                	sd	s2,16(sp)
    80003314:	e44e                	sd	s3,8(sp)
    80003316:	e052                	sd	s4,0(sp)
    80003318:	1800                	addi	s0,sp,48
    8000331a:	89aa                	mv	s3,a0
    8000331c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000331e:	0001d517          	auipc	a0,0x1d
    80003322:	b4250513          	addi	a0,a0,-1214 # 8001fe60 <icache>
    80003326:	ffffe097          	auipc	ra,0xffffe
    8000332a:	8da080e7          	jalr	-1830(ra) # 80000c00 <acquire>
  empty = 0;
    8000332e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003330:	0001d497          	auipc	s1,0x1d
    80003334:	b4848493          	addi	s1,s1,-1208 # 8001fe78 <icache+0x18>
    80003338:	0001e697          	auipc	a3,0x1e
    8000333c:	5d068693          	addi	a3,a3,1488 # 80021908 <log>
    80003340:	a039                	j	8000334e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003342:	02090b63          	beqz	s2,80003378 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003346:	08848493          	addi	s1,s1,136
    8000334a:	02d48a63          	beq	s1,a3,8000337e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000334e:	449c                	lw	a5,8(s1)
    80003350:	fef059e3          	blez	a5,80003342 <iget+0x38>
    80003354:	4098                	lw	a4,0(s1)
    80003356:	ff3716e3          	bne	a4,s3,80003342 <iget+0x38>
    8000335a:	40d8                	lw	a4,4(s1)
    8000335c:	ff4713e3          	bne	a4,s4,80003342 <iget+0x38>
      ip->ref++;
    80003360:	2785                	addiw	a5,a5,1
    80003362:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003364:	0001d517          	auipc	a0,0x1d
    80003368:	afc50513          	addi	a0,a0,-1284 # 8001fe60 <icache>
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	948080e7          	jalr	-1720(ra) # 80000cb4 <release>
      return ip;
    80003374:	8926                	mv	s2,s1
    80003376:	a03d                	j	800033a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003378:	f7f9                	bnez	a5,80003346 <iget+0x3c>
    8000337a:	8926                	mv	s2,s1
    8000337c:	b7e9                	j	80003346 <iget+0x3c>
  if(empty == 0)
    8000337e:	02090c63          	beqz	s2,800033b6 <iget+0xac>
  ip->dev = dev;
    80003382:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003386:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000338a:	4785                	li	a5,1
    8000338c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003390:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003394:	0001d517          	auipc	a0,0x1d
    80003398:	acc50513          	addi	a0,a0,-1332 # 8001fe60 <icache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	918080e7          	jalr	-1768(ra) # 80000cb4 <release>
}
    800033a4:	854a                	mv	a0,s2
    800033a6:	70a2                	ld	ra,40(sp)
    800033a8:	7402                	ld	s0,32(sp)
    800033aa:	64e2                	ld	s1,24(sp)
    800033ac:	6942                	ld	s2,16(sp)
    800033ae:	69a2                	ld	s3,8(sp)
    800033b0:	6a02                	ld	s4,0(sp)
    800033b2:	6145                	addi	sp,sp,48
    800033b4:	8082                	ret
    panic("iget: no inodes");
    800033b6:	00005517          	auipc	a0,0x5
    800033ba:	1aa50513          	addi	a0,a0,426 # 80008560 <syscalls+0x138>
    800033be:	ffffd097          	auipc	ra,0xffffd
    800033c2:	188080e7          	jalr	392(ra) # 80000546 <panic>

00000000800033c6 <fsinit>:
fsinit(int dev) {
    800033c6:	7179                	addi	sp,sp,-48
    800033c8:	f406                	sd	ra,40(sp)
    800033ca:	f022                	sd	s0,32(sp)
    800033cc:	ec26                	sd	s1,24(sp)
    800033ce:	e84a                	sd	s2,16(sp)
    800033d0:	e44e                	sd	s3,8(sp)
    800033d2:	1800                	addi	s0,sp,48
    800033d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800033d6:	4585                	li	a1,1
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	a66080e7          	jalr	-1434(ra) # 80002e3e <bread>
    800033e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800033e2:	0001d997          	auipc	s3,0x1d
    800033e6:	a5e98993          	addi	s3,s3,-1442 # 8001fe40 <sb>
    800033ea:	02000613          	li	a2,32
    800033ee:	05850593          	addi	a1,a0,88
    800033f2:	854e                	mv	a0,s3
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	964080e7          	jalr	-1692(ra) # 80000d58 <memmove>
  brelse(bp);
    800033fc:	8526                	mv	a0,s1
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	b70080e7          	jalr	-1168(ra) # 80002f6e <brelse>
  if(sb.magic != FSMAGIC)
    80003406:	0009a703          	lw	a4,0(s3)
    8000340a:	102037b7          	lui	a5,0x10203
    8000340e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003412:	02f71263          	bne	a4,a5,80003436 <fsinit+0x70>
  initlog(dev, &sb);
    80003416:	0001d597          	auipc	a1,0x1d
    8000341a:	a2a58593          	addi	a1,a1,-1494 # 8001fe40 <sb>
    8000341e:	854a                	mv	a0,s2
    80003420:	00001097          	auipc	ra,0x1
    80003424:	b42080e7          	jalr	-1214(ra) # 80003f62 <initlog>
}
    80003428:	70a2                	ld	ra,40(sp)
    8000342a:	7402                	ld	s0,32(sp)
    8000342c:	64e2                	ld	s1,24(sp)
    8000342e:	6942                	ld	s2,16(sp)
    80003430:	69a2                	ld	s3,8(sp)
    80003432:	6145                	addi	sp,sp,48
    80003434:	8082                	ret
    panic("invalid file system");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	13a50513          	addi	a0,a0,314 # 80008570 <syscalls+0x148>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	108080e7          	jalr	264(ra) # 80000546 <panic>

0000000080003446 <iinit>:
{
    80003446:	7179                	addi	sp,sp,-48
    80003448:	f406                	sd	ra,40(sp)
    8000344a:	f022                	sd	s0,32(sp)
    8000344c:	ec26                	sd	s1,24(sp)
    8000344e:	e84a                	sd	s2,16(sp)
    80003450:	e44e                	sd	s3,8(sp)
    80003452:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003454:	00005597          	auipc	a1,0x5
    80003458:	13458593          	addi	a1,a1,308 # 80008588 <syscalls+0x160>
    8000345c:	0001d517          	auipc	a0,0x1d
    80003460:	a0450513          	addi	a0,a0,-1532 # 8001fe60 <icache>
    80003464:	ffffd097          	auipc	ra,0xffffd
    80003468:	70c080e7          	jalr	1804(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000346c:	0001d497          	auipc	s1,0x1d
    80003470:	a1c48493          	addi	s1,s1,-1508 # 8001fe88 <icache+0x28>
    80003474:	0001e997          	auipc	s3,0x1e
    80003478:	4a498993          	addi	s3,s3,1188 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000347c:	00005917          	auipc	s2,0x5
    80003480:	11490913          	addi	s2,s2,276 # 80008590 <syscalls+0x168>
    80003484:	85ca                	mv	a1,s2
    80003486:	8526                	mv	a0,s1
    80003488:	00001097          	auipc	ra,0x1
    8000348c:	e3e080e7          	jalr	-450(ra) # 800042c6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003490:	08848493          	addi	s1,s1,136
    80003494:	ff3498e3          	bne	s1,s3,80003484 <iinit+0x3e>
}
    80003498:	70a2                	ld	ra,40(sp)
    8000349a:	7402                	ld	s0,32(sp)
    8000349c:	64e2                	ld	s1,24(sp)
    8000349e:	6942                	ld	s2,16(sp)
    800034a0:	69a2                	ld	s3,8(sp)
    800034a2:	6145                	addi	sp,sp,48
    800034a4:	8082                	ret

00000000800034a6 <ialloc>:
{
    800034a6:	715d                	addi	sp,sp,-80
    800034a8:	e486                	sd	ra,72(sp)
    800034aa:	e0a2                	sd	s0,64(sp)
    800034ac:	fc26                	sd	s1,56(sp)
    800034ae:	f84a                	sd	s2,48(sp)
    800034b0:	f44e                	sd	s3,40(sp)
    800034b2:	f052                	sd	s4,32(sp)
    800034b4:	ec56                	sd	s5,24(sp)
    800034b6:	e85a                	sd	s6,16(sp)
    800034b8:	e45e                	sd	s7,8(sp)
    800034ba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800034bc:	0001d717          	auipc	a4,0x1d
    800034c0:	99072703          	lw	a4,-1648(a4) # 8001fe4c <sb+0xc>
    800034c4:	4785                	li	a5,1
    800034c6:	04e7fa63          	bgeu	a5,a4,8000351a <ialloc+0x74>
    800034ca:	8aaa                	mv	s5,a0
    800034cc:	8bae                	mv	s7,a1
    800034ce:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800034d0:	0001da17          	auipc	s4,0x1d
    800034d4:	970a0a13          	addi	s4,s4,-1680 # 8001fe40 <sb>
    800034d8:	00048b1b          	sext.w	s6,s1
    800034dc:	0044d593          	srli	a1,s1,0x4
    800034e0:	018a2783          	lw	a5,24(s4)
    800034e4:	9dbd                	addw	a1,a1,a5
    800034e6:	8556                	mv	a0,s5
    800034e8:	00000097          	auipc	ra,0x0
    800034ec:	956080e7          	jalr	-1706(ra) # 80002e3e <bread>
    800034f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800034f2:	05850993          	addi	s3,a0,88
    800034f6:	00f4f793          	andi	a5,s1,15
    800034fa:	079a                	slli	a5,a5,0x6
    800034fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800034fe:	00099783          	lh	a5,0(s3)
    80003502:	c785                	beqz	a5,8000352a <ialloc+0x84>
    brelse(bp);
    80003504:	00000097          	auipc	ra,0x0
    80003508:	a6a080e7          	jalr	-1430(ra) # 80002f6e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000350c:	0485                	addi	s1,s1,1
    8000350e:	00ca2703          	lw	a4,12(s4)
    80003512:	0004879b          	sext.w	a5,s1
    80003516:	fce7e1e3          	bltu	a5,a4,800034d8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	07e50513          	addi	a0,a0,126 # 80008598 <syscalls+0x170>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	024080e7          	jalr	36(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    8000352a:	04000613          	li	a2,64
    8000352e:	4581                	li	a1,0
    80003530:	854e                	mv	a0,s3
    80003532:	ffffd097          	auipc	ra,0xffffd
    80003536:	7ca080e7          	jalr	1994(ra) # 80000cfc <memset>
      dip->type = type;
    8000353a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000353e:	854a                	mv	a0,s2
    80003540:	00001097          	auipc	ra,0x1
    80003544:	c9a080e7          	jalr	-870(ra) # 800041da <log_write>
      brelse(bp);
    80003548:	854a                	mv	a0,s2
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	a24080e7          	jalr	-1500(ra) # 80002f6e <brelse>
      return iget(dev, inum);
    80003552:	85da                	mv	a1,s6
    80003554:	8556                	mv	a0,s5
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	db4080e7          	jalr	-588(ra) # 8000330a <iget>
}
    8000355e:	60a6                	ld	ra,72(sp)
    80003560:	6406                	ld	s0,64(sp)
    80003562:	74e2                	ld	s1,56(sp)
    80003564:	7942                	ld	s2,48(sp)
    80003566:	79a2                	ld	s3,40(sp)
    80003568:	7a02                	ld	s4,32(sp)
    8000356a:	6ae2                	ld	s5,24(sp)
    8000356c:	6b42                	ld	s6,16(sp)
    8000356e:	6ba2                	ld	s7,8(sp)
    80003570:	6161                	addi	sp,sp,80
    80003572:	8082                	ret

0000000080003574 <iupdate>:
{
    80003574:	1101                	addi	sp,sp,-32
    80003576:	ec06                	sd	ra,24(sp)
    80003578:	e822                	sd	s0,16(sp)
    8000357a:	e426                	sd	s1,8(sp)
    8000357c:	e04a                	sd	s2,0(sp)
    8000357e:	1000                	addi	s0,sp,32
    80003580:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003582:	415c                	lw	a5,4(a0)
    80003584:	0047d79b          	srliw	a5,a5,0x4
    80003588:	0001d597          	auipc	a1,0x1d
    8000358c:	8d05a583          	lw	a1,-1840(a1) # 8001fe58 <sb+0x18>
    80003590:	9dbd                	addw	a1,a1,a5
    80003592:	4108                	lw	a0,0(a0)
    80003594:	00000097          	auipc	ra,0x0
    80003598:	8aa080e7          	jalr	-1878(ra) # 80002e3e <bread>
    8000359c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000359e:	05850793          	addi	a5,a0,88
    800035a2:	40d8                	lw	a4,4(s1)
    800035a4:	8b3d                	andi	a4,a4,15
    800035a6:	071a                	slli	a4,a4,0x6
    800035a8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800035aa:	04449703          	lh	a4,68(s1)
    800035ae:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800035b2:	04649703          	lh	a4,70(s1)
    800035b6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800035ba:	04849703          	lh	a4,72(s1)
    800035be:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800035c2:	04a49703          	lh	a4,74(s1)
    800035c6:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800035ca:	44f8                	lw	a4,76(s1)
    800035cc:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800035ce:	03400613          	li	a2,52
    800035d2:	05048593          	addi	a1,s1,80
    800035d6:	00c78513          	addi	a0,a5,12
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	77e080e7          	jalr	1918(ra) # 80000d58 <memmove>
  log_write(bp);
    800035e2:	854a                	mv	a0,s2
    800035e4:	00001097          	auipc	ra,0x1
    800035e8:	bf6080e7          	jalr	-1034(ra) # 800041da <log_write>
  brelse(bp);
    800035ec:	854a                	mv	a0,s2
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	980080e7          	jalr	-1664(ra) # 80002f6e <brelse>
}
    800035f6:	60e2                	ld	ra,24(sp)
    800035f8:	6442                	ld	s0,16(sp)
    800035fa:	64a2                	ld	s1,8(sp)
    800035fc:	6902                	ld	s2,0(sp)
    800035fe:	6105                	addi	sp,sp,32
    80003600:	8082                	ret

0000000080003602 <idup>:
{
    80003602:	1101                	addi	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000360e:	0001d517          	auipc	a0,0x1d
    80003612:	85250513          	addi	a0,a0,-1966 # 8001fe60 <icache>
    80003616:	ffffd097          	auipc	ra,0xffffd
    8000361a:	5ea080e7          	jalr	1514(ra) # 80000c00 <acquire>
  ip->ref++;
    8000361e:	449c                	lw	a5,8(s1)
    80003620:	2785                	addiw	a5,a5,1
    80003622:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003624:	0001d517          	auipc	a0,0x1d
    80003628:	83c50513          	addi	a0,a0,-1988 # 8001fe60 <icache>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	688080e7          	jalr	1672(ra) # 80000cb4 <release>
}
    80003634:	8526                	mv	a0,s1
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6105                	addi	sp,sp,32
    8000363e:	8082                	ret

0000000080003640 <ilock>:
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000364c:	c115                	beqz	a0,80003670 <ilock+0x30>
    8000364e:	84aa                	mv	s1,a0
    80003650:	451c                	lw	a5,8(a0)
    80003652:	00f05f63          	blez	a5,80003670 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003656:	0541                	addi	a0,a0,16
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	ca8080e7          	jalr	-856(ra) # 80004300 <acquiresleep>
  if(ip->valid == 0){
    80003660:	40bc                	lw	a5,64(s1)
    80003662:	cf99                	beqz	a5,80003680 <ilock+0x40>
}
    80003664:	60e2                	ld	ra,24(sp)
    80003666:	6442                	ld	s0,16(sp)
    80003668:	64a2                	ld	s1,8(sp)
    8000366a:	6902                	ld	s2,0(sp)
    8000366c:	6105                	addi	sp,sp,32
    8000366e:	8082                	ret
    panic("ilock");
    80003670:	00005517          	auipc	a0,0x5
    80003674:	f4050513          	addi	a0,a0,-192 # 800085b0 <syscalls+0x188>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	ece080e7          	jalr	-306(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003680:	40dc                	lw	a5,4(s1)
    80003682:	0047d79b          	srliw	a5,a5,0x4
    80003686:	0001c597          	auipc	a1,0x1c
    8000368a:	7d25a583          	lw	a1,2002(a1) # 8001fe58 <sb+0x18>
    8000368e:	9dbd                	addw	a1,a1,a5
    80003690:	4088                	lw	a0,0(s1)
    80003692:	fffff097          	auipc	ra,0xfffff
    80003696:	7ac080e7          	jalr	1964(ra) # 80002e3e <bread>
    8000369a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000369c:	05850593          	addi	a1,a0,88
    800036a0:	40dc                	lw	a5,4(s1)
    800036a2:	8bbd                	andi	a5,a5,15
    800036a4:	079a                	slli	a5,a5,0x6
    800036a6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800036a8:	00059783          	lh	a5,0(a1)
    800036ac:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800036b0:	00259783          	lh	a5,2(a1)
    800036b4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800036b8:	00459783          	lh	a5,4(a1)
    800036bc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800036c0:	00659783          	lh	a5,6(a1)
    800036c4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800036c8:	459c                	lw	a5,8(a1)
    800036ca:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800036cc:	03400613          	li	a2,52
    800036d0:	05b1                	addi	a1,a1,12
    800036d2:	05048513          	addi	a0,s1,80
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	682080e7          	jalr	1666(ra) # 80000d58 <memmove>
    brelse(bp);
    800036de:	854a                	mv	a0,s2
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	88e080e7          	jalr	-1906(ra) # 80002f6e <brelse>
    ip->valid = 1;
    800036e8:	4785                	li	a5,1
    800036ea:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800036ec:	04449783          	lh	a5,68(s1)
    800036f0:	fbb5                	bnez	a5,80003664 <ilock+0x24>
      panic("ilock: no type");
    800036f2:	00005517          	auipc	a0,0x5
    800036f6:	ec650513          	addi	a0,a0,-314 # 800085b8 <syscalls+0x190>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	e4c080e7          	jalr	-436(ra) # 80000546 <panic>

0000000080003702 <iunlock>:
{
    80003702:	1101                	addi	sp,sp,-32
    80003704:	ec06                	sd	ra,24(sp)
    80003706:	e822                	sd	s0,16(sp)
    80003708:	e426                	sd	s1,8(sp)
    8000370a:	e04a                	sd	s2,0(sp)
    8000370c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000370e:	c905                	beqz	a0,8000373e <iunlock+0x3c>
    80003710:	84aa                	mv	s1,a0
    80003712:	01050913          	addi	s2,a0,16
    80003716:	854a                	mv	a0,s2
    80003718:	00001097          	auipc	ra,0x1
    8000371c:	c82080e7          	jalr	-894(ra) # 8000439a <holdingsleep>
    80003720:	cd19                	beqz	a0,8000373e <iunlock+0x3c>
    80003722:	449c                	lw	a5,8(s1)
    80003724:	00f05d63          	blez	a5,8000373e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	c2c080e7          	jalr	-980(ra) # 80004356 <releasesleep>
}
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6902                	ld	s2,0(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret
    panic("iunlock");
    8000373e:	00005517          	auipc	a0,0x5
    80003742:	e8a50513          	addi	a0,a0,-374 # 800085c8 <syscalls+0x1a0>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	e00080e7          	jalr	-512(ra) # 80000546 <panic>

000000008000374e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000374e:	7179                	addi	sp,sp,-48
    80003750:	f406                	sd	ra,40(sp)
    80003752:	f022                	sd	s0,32(sp)
    80003754:	ec26                	sd	s1,24(sp)
    80003756:	e84a                	sd	s2,16(sp)
    80003758:	e44e                	sd	s3,8(sp)
    8000375a:	e052                	sd	s4,0(sp)
    8000375c:	1800                	addi	s0,sp,48
    8000375e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003760:	05050493          	addi	s1,a0,80
    80003764:	08050913          	addi	s2,a0,128
    80003768:	a021                	j	80003770 <itrunc+0x22>
    8000376a:	0491                	addi	s1,s1,4
    8000376c:	01248d63          	beq	s1,s2,80003786 <itrunc+0x38>
    if(ip->addrs[i]){
    80003770:	408c                	lw	a1,0(s1)
    80003772:	dde5                	beqz	a1,8000376a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003774:	0009a503          	lw	a0,0(s3)
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	90c080e7          	jalr	-1780(ra) # 80003084 <bfree>
      ip->addrs[i] = 0;
    80003780:	0004a023          	sw	zero,0(s1)
    80003784:	b7dd                	j	8000376a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003786:	0809a583          	lw	a1,128(s3)
    8000378a:	e185                	bnez	a1,800037aa <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000378c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003790:	854e                	mv	a0,s3
    80003792:	00000097          	auipc	ra,0x0
    80003796:	de2080e7          	jalr	-542(ra) # 80003574 <iupdate>
}
    8000379a:	70a2                	ld	ra,40(sp)
    8000379c:	7402                	ld	s0,32(sp)
    8000379e:	64e2                	ld	s1,24(sp)
    800037a0:	6942                	ld	s2,16(sp)
    800037a2:	69a2                	ld	s3,8(sp)
    800037a4:	6a02                	ld	s4,0(sp)
    800037a6:	6145                	addi	sp,sp,48
    800037a8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800037aa:	0009a503          	lw	a0,0(s3)
    800037ae:	fffff097          	auipc	ra,0xfffff
    800037b2:	690080e7          	jalr	1680(ra) # 80002e3e <bread>
    800037b6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800037b8:	05850493          	addi	s1,a0,88
    800037bc:	45850913          	addi	s2,a0,1112
    800037c0:	a021                	j	800037c8 <itrunc+0x7a>
    800037c2:	0491                	addi	s1,s1,4
    800037c4:	01248b63          	beq	s1,s2,800037da <itrunc+0x8c>
      if(a[j])
    800037c8:	408c                	lw	a1,0(s1)
    800037ca:	dde5                	beqz	a1,800037c2 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800037cc:	0009a503          	lw	a0,0(s3)
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	8b4080e7          	jalr	-1868(ra) # 80003084 <bfree>
    800037d8:	b7ed                	j	800037c2 <itrunc+0x74>
    brelse(bp);
    800037da:	8552                	mv	a0,s4
    800037dc:	fffff097          	auipc	ra,0xfffff
    800037e0:	792080e7          	jalr	1938(ra) # 80002f6e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800037e4:	0809a583          	lw	a1,128(s3)
    800037e8:	0009a503          	lw	a0,0(s3)
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	898080e7          	jalr	-1896(ra) # 80003084 <bfree>
    ip->addrs[NDIRECT] = 0;
    800037f4:	0809a023          	sw	zero,128(s3)
    800037f8:	bf51                	j	8000378c <itrunc+0x3e>

00000000800037fa <iput>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
    80003806:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003808:	0001c517          	auipc	a0,0x1c
    8000380c:	65850513          	addi	a0,a0,1624 # 8001fe60 <icache>
    80003810:	ffffd097          	auipc	ra,0xffffd
    80003814:	3f0080e7          	jalr	1008(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003818:	4498                	lw	a4,8(s1)
    8000381a:	4785                	li	a5,1
    8000381c:	02f70363          	beq	a4,a5,80003842 <iput+0x48>
  ip->ref--;
    80003820:	449c                	lw	a5,8(s1)
    80003822:	37fd                	addiw	a5,a5,-1
    80003824:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003826:	0001c517          	auipc	a0,0x1c
    8000382a:	63a50513          	addi	a0,a0,1594 # 8001fe60 <icache>
    8000382e:	ffffd097          	auipc	ra,0xffffd
    80003832:	486080e7          	jalr	1158(ra) # 80000cb4 <release>
}
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	64a2                	ld	s1,8(sp)
    8000383c:	6902                	ld	s2,0(sp)
    8000383e:	6105                	addi	sp,sp,32
    80003840:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003842:	40bc                	lw	a5,64(s1)
    80003844:	dff1                	beqz	a5,80003820 <iput+0x26>
    80003846:	04a49783          	lh	a5,74(s1)
    8000384a:	fbf9                	bnez	a5,80003820 <iput+0x26>
    acquiresleep(&ip->lock);
    8000384c:	01048913          	addi	s2,s1,16
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	aae080e7          	jalr	-1362(ra) # 80004300 <acquiresleep>
    release(&icache.lock);
    8000385a:	0001c517          	auipc	a0,0x1c
    8000385e:	60650513          	addi	a0,a0,1542 # 8001fe60 <icache>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	452080e7          	jalr	1106(ra) # 80000cb4 <release>
    itrunc(ip);
    8000386a:	8526                	mv	a0,s1
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	ee2080e7          	jalr	-286(ra) # 8000374e <itrunc>
    ip->type = 0;
    80003874:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003878:	8526                	mv	a0,s1
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	cfa080e7          	jalr	-774(ra) # 80003574 <iupdate>
    ip->valid = 0;
    80003882:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003886:	854a                	mv	a0,s2
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	ace080e7          	jalr	-1330(ra) # 80004356 <releasesleep>
    acquire(&icache.lock);
    80003890:	0001c517          	auipc	a0,0x1c
    80003894:	5d050513          	addi	a0,a0,1488 # 8001fe60 <icache>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	368080e7          	jalr	872(ra) # 80000c00 <acquire>
    800038a0:	b741                	j	80003820 <iput+0x26>

00000000800038a2 <iunlockput>:
{
    800038a2:	1101                	addi	sp,sp,-32
    800038a4:	ec06                	sd	ra,24(sp)
    800038a6:	e822                	sd	s0,16(sp)
    800038a8:	e426                	sd	s1,8(sp)
    800038aa:	1000                	addi	s0,sp,32
    800038ac:	84aa                	mv	s1,a0
  iunlock(ip);
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	e54080e7          	jalr	-428(ra) # 80003702 <iunlock>
  iput(ip);
    800038b6:	8526                	mv	a0,s1
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	f42080e7          	jalr	-190(ra) # 800037fa <iput>
}
    800038c0:	60e2                	ld	ra,24(sp)
    800038c2:	6442                	ld	s0,16(sp)
    800038c4:	64a2                	ld	s1,8(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret

00000000800038ca <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038ca:	1141                	addi	sp,sp,-16
    800038cc:	e422                	sd	s0,8(sp)
    800038ce:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038d0:	411c                	lw	a5,0(a0)
    800038d2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038d4:	415c                	lw	a5,4(a0)
    800038d6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038d8:	04451783          	lh	a5,68(a0)
    800038dc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038e0:	04a51783          	lh	a5,74(a0)
    800038e4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038e8:	04c56783          	lwu	a5,76(a0)
    800038ec:	e99c                	sd	a5,16(a1)
}
    800038ee:	6422                	ld	s0,8(sp)
    800038f0:	0141                	addi	sp,sp,16
    800038f2:	8082                	ret

00000000800038f4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038f4:	457c                	lw	a5,76(a0)
    800038f6:	0ed7e863          	bltu	a5,a3,800039e6 <readi+0xf2>
{
    800038fa:	7159                	addi	sp,sp,-112
    800038fc:	f486                	sd	ra,104(sp)
    800038fe:	f0a2                	sd	s0,96(sp)
    80003900:	eca6                	sd	s1,88(sp)
    80003902:	e8ca                	sd	s2,80(sp)
    80003904:	e4ce                	sd	s3,72(sp)
    80003906:	e0d2                	sd	s4,64(sp)
    80003908:	fc56                	sd	s5,56(sp)
    8000390a:	f85a                	sd	s6,48(sp)
    8000390c:	f45e                	sd	s7,40(sp)
    8000390e:	f062                	sd	s8,32(sp)
    80003910:	ec66                	sd	s9,24(sp)
    80003912:	e86a                	sd	s10,16(sp)
    80003914:	e46e                	sd	s11,8(sp)
    80003916:	1880                	addi	s0,sp,112
    80003918:	8baa                	mv	s7,a0
    8000391a:	8c2e                	mv	s8,a1
    8000391c:	8ab2                	mv	s5,a2
    8000391e:	84b6                	mv	s1,a3
    80003920:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003922:	9f35                	addw	a4,a4,a3
    return 0;
    80003924:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003926:	08d76f63          	bltu	a4,a3,800039c4 <readi+0xd0>
  if(off + n > ip->size)
    8000392a:	00e7f463          	bgeu	a5,a4,80003932 <readi+0x3e>
    n = ip->size - off;
    8000392e:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003932:	0a0b0863          	beqz	s6,800039e2 <readi+0xee>
    80003936:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003938:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000393c:	5cfd                	li	s9,-1
    8000393e:	a82d                	j	80003978 <readi+0x84>
    80003940:	020a1d93          	slli	s11,s4,0x20
    80003944:	020ddd93          	srli	s11,s11,0x20
    80003948:	05890613          	addi	a2,s2,88
    8000394c:	86ee                	mv	a3,s11
    8000394e:	963a                	add	a2,a2,a4
    80003950:	85d6                	mv	a1,s5
    80003952:	8562                	mv	a0,s8
    80003954:	fffff097          	auipc	ra,0xfffff
    80003958:	b14080e7          	jalr	-1260(ra) # 80002468 <either_copyout>
    8000395c:	05950d63          	beq	a0,s9,800039b6 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003960:	854a                	mv	a0,s2
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	60c080e7          	jalr	1548(ra) # 80002f6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000396a:	013a09bb          	addw	s3,s4,s3
    8000396e:	009a04bb          	addw	s1,s4,s1
    80003972:	9aee                	add	s5,s5,s11
    80003974:	0569f663          	bgeu	s3,s6,800039c0 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003978:	000ba903          	lw	s2,0(s7)
    8000397c:	00a4d59b          	srliw	a1,s1,0xa
    80003980:	855e                	mv	a0,s7
    80003982:	00000097          	auipc	ra,0x0
    80003986:	8ac080e7          	jalr	-1876(ra) # 8000322e <bmap>
    8000398a:	0005059b          	sext.w	a1,a0
    8000398e:	854a                	mv	a0,s2
    80003990:	fffff097          	auipc	ra,0xfffff
    80003994:	4ae080e7          	jalr	1198(ra) # 80002e3e <bread>
    80003998:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000399a:	3ff4f713          	andi	a4,s1,1023
    8000399e:	40ed07bb          	subw	a5,s10,a4
    800039a2:	413b06bb          	subw	a3,s6,s3
    800039a6:	8a3e                	mv	s4,a5
    800039a8:	2781                	sext.w	a5,a5
    800039aa:	0006861b          	sext.w	a2,a3
    800039ae:	f8f679e3          	bgeu	a2,a5,80003940 <readi+0x4c>
    800039b2:	8a36                	mv	s4,a3
    800039b4:	b771                	j	80003940 <readi+0x4c>
      brelse(bp);
    800039b6:	854a                	mv	a0,s2
    800039b8:	fffff097          	auipc	ra,0xfffff
    800039bc:	5b6080e7          	jalr	1462(ra) # 80002f6e <brelse>
  }
  return tot;
    800039c0:	0009851b          	sext.w	a0,s3
}
    800039c4:	70a6                	ld	ra,104(sp)
    800039c6:	7406                	ld	s0,96(sp)
    800039c8:	64e6                	ld	s1,88(sp)
    800039ca:	6946                	ld	s2,80(sp)
    800039cc:	69a6                	ld	s3,72(sp)
    800039ce:	6a06                	ld	s4,64(sp)
    800039d0:	7ae2                	ld	s5,56(sp)
    800039d2:	7b42                	ld	s6,48(sp)
    800039d4:	7ba2                	ld	s7,40(sp)
    800039d6:	7c02                	ld	s8,32(sp)
    800039d8:	6ce2                	ld	s9,24(sp)
    800039da:	6d42                	ld	s10,16(sp)
    800039dc:	6da2                	ld	s11,8(sp)
    800039de:	6165                	addi	sp,sp,112
    800039e0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039e2:	89da                	mv	s3,s6
    800039e4:	bff1                	j	800039c0 <readi+0xcc>
    return 0;
    800039e6:	4501                	li	a0,0
}
    800039e8:	8082                	ret

00000000800039ea <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ea:	457c                	lw	a5,76(a0)
    800039ec:	10d7e663          	bltu	a5,a3,80003af8 <writei+0x10e>
{
    800039f0:	7159                	addi	sp,sp,-112
    800039f2:	f486                	sd	ra,104(sp)
    800039f4:	f0a2                	sd	s0,96(sp)
    800039f6:	eca6                	sd	s1,88(sp)
    800039f8:	e8ca                	sd	s2,80(sp)
    800039fa:	e4ce                	sd	s3,72(sp)
    800039fc:	e0d2                	sd	s4,64(sp)
    800039fe:	fc56                	sd	s5,56(sp)
    80003a00:	f85a                	sd	s6,48(sp)
    80003a02:	f45e                	sd	s7,40(sp)
    80003a04:	f062                	sd	s8,32(sp)
    80003a06:	ec66                	sd	s9,24(sp)
    80003a08:	e86a                	sd	s10,16(sp)
    80003a0a:	e46e                	sd	s11,8(sp)
    80003a0c:	1880                	addi	s0,sp,112
    80003a0e:	8baa                	mv	s7,a0
    80003a10:	8c2e                	mv	s8,a1
    80003a12:	8ab2                	mv	s5,a2
    80003a14:	8936                	mv	s2,a3
    80003a16:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a18:	00e687bb          	addw	a5,a3,a4
    80003a1c:	0ed7e063          	bltu	a5,a3,80003afc <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a20:	00043737          	lui	a4,0x43
    80003a24:	0cf76e63          	bltu	a4,a5,80003b00 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a28:	0a0b0763          	beqz	s6,80003ad6 <writei+0xec>
    80003a2c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a2e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a32:	5cfd                	li	s9,-1
    80003a34:	a091                	j	80003a78 <writei+0x8e>
    80003a36:	02099d93          	slli	s11,s3,0x20
    80003a3a:	020ddd93          	srli	s11,s11,0x20
    80003a3e:	05848513          	addi	a0,s1,88
    80003a42:	86ee                	mv	a3,s11
    80003a44:	8656                	mv	a2,s5
    80003a46:	85e2                	mv	a1,s8
    80003a48:	953a                	add	a0,a0,a4
    80003a4a:	fffff097          	auipc	ra,0xfffff
    80003a4e:	a74080e7          	jalr	-1420(ra) # 800024be <either_copyin>
    80003a52:	07950263          	beq	a0,s9,80003ab6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a56:	8526                	mv	a0,s1
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	782080e7          	jalr	1922(ra) # 800041da <log_write>
    brelse(bp);
    80003a60:	8526                	mv	a0,s1
    80003a62:	fffff097          	auipc	ra,0xfffff
    80003a66:	50c080e7          	jalr	1292(ra) # 80002f6e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a6a:	01498a3b          	addw	s4,s3,s4
    80003a6e:	0129893b          	addw	s2,s3,s2
    80003a72:	9aee                	add	s5,s5,s11
    80003a74:	056a7663          	bgeu	s4,s6,80003ac0 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a78:	000ba483          	lw	s1,0(s7)
    80003a7c:	00a9559b          	srliw	a1,s2,0xa
    80003a80:	855e                	mv	a0,s7
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	7ac080e7          	jalr	1964(ra) # 8000322e <bmap>
    80003a8a:	0005059b          	sext.w	a1,a0
    80003a8e:	8526                	mv	a0,s1
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	3ae080e7          	jalr	942(ra) # 80002e3e <bread>
    80003a98:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9a:	3ff97713          	andi	a4,s2,1023
    80003a9e:	40ed07bb          	subw	a5,s10,a4
    80003aa2:	414b06bb          	subw	a3,s6,s4
    80003aa6:	89be                	mv	s3,a5
    80003aa8:	2781                	sext.w	a5,a5
    80003aaa:	0006861b          	sext.w	a2,a3
    80003aae:	f8f674e3          	bgeu	a2,a5,80003a36 <writei+0x4c>
    80003ab2:	89b6                	mv	s3,a3
    80003ab4:	b749                	j	80003a36 <writei+0x4c>
      brelse(bp);
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	4b6080e7          	jalr	1206(ra) # 80002f6e <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003ac0:	04cba783          	lw	a5,76(s7)
    80003ac4:	0127f463          	bgeu	a5,s2,80003acc <writei+0xe2>
      ip->size = off;
    80003ac8:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003acc:	855e                	mv	a0,s7
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	aa6080e7          	jalr	-1370(ra) # 80003574 <iupdate>
  }

  return n;
    80003ad6:	000b051b          	sext.w	a0,s6
}
    80003ada:	70a6                	ld	ra,104(sp)
    80003adc:	7406                	ld	s0,96(sp)
    80003ade:	64e6                	ld	s1,88(sp)
    80003ae0:	6946                	ld	s2,80(sp)
    80003ae2:	69a6                	ld	s3,72(sp)
    80003ae4:	6a06                	ld	s4,64(sp)
    80003ae6:	7ae2                	ld	s5,56(sp)
    80003ae8:	7b42                	ld	s6,48(sp)
    80003aea:	7ba2                	ld	s7,40(sp)
    80003aec:	7c02                	ld	s8,32(sp)
    80003aee:	6ce2                	ld	s9,24(sp)
    80003af0:	6d42                	ld	s10,16(sp)
    80003af2:	6da2                	ld	s11,8(sp)
    80003af4:	6165                	addi	sp,sp,112
    80003af6:	8082                	ret
    return -1;
    80003af8:	557d                	li	a0,-1
}
    80003afa:	8082                	ret
    return -1;
    80003afc:	557d                	li	a0,-1
    80003afe:	bff1                	j	80003ada <writei+0xf0>
    return -1;
    80003b00:	557d                	li	a0,-1
    80003b02:	bfe1                	j	80003ada <writei+0xf0>

0000000080003b04 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b04:	1141                	addi	sp,sp,-16
    80003b06:	e406                	sd	ra,8(sp)
    80003b08:	e022                	sd	s0,0(sp)
    80003b0a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b0c:	4639                	li	a2,14
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	2c6080e7          	jalr	710(ra) # 80000dd4 <strncmp>
}
    80003b16:	60a2                	ld	ra,8(sp)
    80003b18:	6402                	ld	s0,0(sp)
    80003b1a:	0141                	addi	sp,sp,16
    80003b1c:	8082                	ret

0000000080003b1e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b1e:	7139                	addi	sp,sp,-64
    80003b20:	fc06                	sd	ra,56(sp)
    80003b22:	f822                	sd	s0,48(sp)
    80003b24:	f426                	sd	s1,40(sp)
    80003b26:	f04a                	sd	s2,32(sp)
    80003b28:	ec4e                	sd	s3,24(sp)
    80003b2a:	e852                	sd	s4,16(sp)
    80003b2c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b2e:	04451703          	lh	a4,68(a0)
    80003b32:	4785                	li	a5,1
    80003b34:	00f71a63          	bne	a4,a5,80003b48 <dirlookup+0x2a>
    80003b38:	892a                	mv	s2,a0
    80003b3a:	89ae                	mv	s3,a1
    80003b3c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b3e:	457c                	lw	a5,76(a0)
    80003b40:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b42:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b44:	e79d                	bnez	a5,80003b72 <dirlookup+0x54>
    80003b46:	a8a5                	j	80003bbe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003b48:	00005517          	auipc	a0,0x5
    80003b4c:	a8850513          	addi	a0,a0,-1400 # 800085d0 <syscalls+0x1a8>
    80003b50:	ffffd097          	auipc	ra,0xffffd
    80003b54:	9f6080e7          	jalr	-1546(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003b58:	00005517          	auipc	a0,0x5
    80003b5c:	a9050513          	addi	a0,a0,-1392 # 800085e8 <syscalls+0x1c0>
    80003b60:	ffffd097          	auipc	ra,0xffffd
    80003b64:	9e6080e7          	jalr	-1562(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b68:	24c1                	addiw	s1,s1,16
    80003b6a:	04c92783          	lw	a5,76(s2)
    80003b6e:	04f4f763          	bgeu	s1,a5,80003bbc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b72:	4741                	li	a4,16
    80003b74:	86a6                	mv	a3,s1
    80003b76:	fc040613          	addi	a2,s0,-64
    80003b7a:	4581                	li	a1,0
    80003b7c:	854a                	mv	a0,s2
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	d76080e7          	jalr	-650(ra) # 800038f4 <readi>
    80003b86:	47c1                	li	a5,16
    80003b88:	fcf518e3          	bne	a0,a5,80003b58 <dirlookup+0x3a>
    if(de.inum == 0)
    80003b8c:	fc045783          	lhu	a5,-64(s0)
    80003b90:	dfe1                	beqz	a5,80003b68 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003b92:	fc240593          	addi	a1,s0,-62
    80003b96:	854e                	mv	a0,s3
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	f6c080e7          	jalr	-148(ra) # 80003b04 <namecmp>
    80003ba0:	f561                	bnez	a0,80003b68 <dirlookup+0x4a>
      if(poff)
    80003ba2:	000a0463          	beqz	s4,80003baa <dirlookup+0x8c>
        *poff = off;
    80003ba6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003baa:	fc045583          	lhu	a1,-64(s0)
    80003bae:	00092503          	lw	a0,0(s2)
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	758080e7          	jalr	1880(ra) # 8000330a <iget>
    80003bba:	a011                	j	80003bbe <dirlookup+0xa0>
  return 0;
    80003bbc:	4501                	li	a0,0
}
    80003bbe:	70e2                	ld	ra,56(sp)
    80003bc0:	7442                	ld	s0,48(sp)
    80003bc2:	74a2                	ld	s1,40(sp)
    80003bc4:	7902                	ld	s2,32(sp)
    80003bc6:	69e2                	ld	s3,24(sp)
    80003bc8:	6a42                	ld	s4,16(sp)
    80003bca:	6121                	addi	sp,sp,64
    80003bcc:	8082                	ret

0000000080003bce <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003bce:	711d                	addi	sp,sp,-96
    80003bd0:	ec86                	sd	ra,88(sp)
    80003bd2:	e8a2                	sd	s0,80(sp)
    80003bd4:	e4a6                	sd	s1,72(sp)
    80003bd6:	e0ca                	sd	s2,64(sp)
    80003bd8:	fc4e                	sd	s3,56(sp)
    80003bda:	f852                	sd	s4,48(sp)
    80003bdc:	f456                	sd	s5,40(sp)
    80003bde:	f05a                	sd	s6,32(sp)
    80003be0:	ec5e                	sd	s7,24(sp)
    80003be2:	e862                	sd	s8,16(sp)
    80003be4:	e466                	sd	s9,8(sp)
    80003be6:	e06a                	sd	s10,0(sp)
    80003be8:	1080                	addi	s0,sp,96
    80003bea:	84aa                	mv	s1,a0
    80003bec:	8b2e                	mv	s6,a1
    80003bee:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bf0:	00054703          	lbu	a4,0(a0)
    80003bf4:	02f00793          	li	a5,47
    80003bf8:	02f70363          	beq	a4,a5,80003c1e <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bfc:	ffffe097          	auipc	ra,0xffffe
    80003c00:	dfe080e7          	jalr	-514(ra) # 800019fa <myproc>
    80003c04:	15053503          	ld	a0,336(a0)
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	9fa080e7          	jalr	-1542(ra) # 80003602 <idup>
    80003c10:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c12:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c16:	4cb5                	li	s9,13
  len = path - s;
    80003c18:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c1a:	4c05                	li	s8,1
    80003c1c:	a87d                	j	80003cda <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c1e:	4585                	li	a1,1
    80003c20:	4505                	li	a0,1
    80003c22:	fffff097          	auipc	ra,0xfffff
    80003c26:	6e8080e7          	jalr	1768(ra) # 8000330a <iget>
    80003c2a:	8a2a                	mv	s4,a0
    80003c2c:	b7dd                	j	80003c12 <namex+0x44>
      iunlockput(ip);
    80003c2e:	8552                	mv	a0,s4
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	c72080e7          	jalr	-910(ra) # 800038a2 <iunlockput>
      return 0;
    80003c38:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003c3a:	8552                	mv	a0,s4
    80003c3c:	60e6                	ld	ra,88(sp)
    80003c3e:	6446                	ld	s0,80(sp)
    80003c40:	64a6                	ld	s1,72(sp)
    80003c42:	6906                	ld	s2,64(sp)
    80003c44:	79e2                	ld	s3,56(sp)
    80003c46:	7a42                	ld	s4,48(sp)
    80003c48:	7aa2                	ld	s5,40(sp)
    80003c4a:	7b02                	ld	s6,32(sp)
    80003c4c:	6be2                	ld	s7,24(sp)
    80003c4e:	6c42                	ld	s8,16(sp)
    80003c50:	6ca2                	ld	s9,8(sp)
    80003c52:	6d02                	ld	s10,0(sp)
    80003c54:	6125                	addi	sp,sp,96
    80003c56:	8082                	ret
      iunlock(ip);
    80003c58:	8552                	mv	a0,s4
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	aa8080e7          	jalr	-1368(ra) # 80003702 <iunlock>
      return ip;
    80003c62:	bfe1                	j	80003c3a <namex+0x6c>
      iunlockput(ip);
    80003c64:	8552                	mv	a0,s4
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	c3c080e7          	jalr	-964(ra) # 800038a2 <iunlockput>
      return 0;
    80003c6e:	8a4e                	mv	s4,s3
    80003c70:	b7e9                	j	80003c3a <namex+0x6c>
  len = path - s;
    80003c72:	40998633          	sub	a2,s3,s1
    80003c76:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003c7a:	09acd863          	bge	s9,s10,80003d0a <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003c7e:	4639                	li	a2,14
    80003c80:	85a6                	mv	a1,s1
    80003c82:	8556                	mv	a0,s5
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	0d4080e7          	jalr	212(ra) # 80000d58 <memmove>
    80003c8c:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c8e:	0004c783          	lbu	a5,0(s1)
    80003c92:	01279763          	bne	a5,s2,80003ca0 <namex+0xd2>
    path++;
    80003c96:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c98:	0004c783          	lbu	a5,0(s1)
    80003c9c:	ff278de3          	beq	a5,s2,80003c96 <namex+0xc8>
    ilock(ip);
    80003ca0:	8552                	mv	a0,s4
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	99e080e7          	jalr	-1634(ra) # 80003640 <ilock>
    if(ip->type != T_DIR){
    80003caa:	044a1783          	lh	a5,68(s4)
    80003cae:	f98790e3          	bne	a5,s8,80003c2e <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003cb2:	000b0563          	beqz	s6,80003cbc <namex+0xee>
    80003cb6:	0004c783          	lbu	a5,0(s1)
    80003cba:	dfd9                	beqz	a5,80003c58 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003cbc:	865e                	mv	a2,s7
    80003cbe:	85d6                	mv	a1,s5
    80003cc0:	8552                	mv	a0,s4
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	e5c080e7          	jalr	-420(ra) # 80003b1e <dirlookup>
    80003cca:	89aa                	mv	s3,a0
    80003ccc:	dd41                	beqz	a0,80003c64 <namex+0x96>
    iunlockput(ip);
    80003cce:	8552                	mv	a0,s4
    80003cd0:	00000097          	auipc	ra,0x0
    80003cd4:	bd2080e7          	jalr	-1070(ra) # 800038a2 <iunlockput>
    ip = next;
    80003cd8:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003cda:	0004c783          	lbu	a5,0(s1)
    80003cde:	01279763          	bne	a5,s2,80003cec <namex+0x11e>
    path++;
    80003ce2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ce4:	0004c783          	lbu	a5,0(s1)
    80003ce8:	ff278de3          	beq	a5,s2,80003ce2 <namex+0x114>
  if(*path == 0)
    80003cec:	cb9d                	beqz	a5,80003d22 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003cee:	0004c783          	lbu	a5,0(s1)
    80003cf2:	89a6                	mv	s3,s1
  len = path - s;
    80003cf4:	8d5e                	mv	s10,s7
    80003cf6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003cf8:	01278963          	beq	a5,s2,80003d0a <namex+0x13c>
    80003cfc:	dbbd                	beqz	a5,80003c72 <namex+0xa4>
    path++;
    80003cfe:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d00:	0009c783          	lbu	a5,0(s3)
    80003d04:	ff279ce3          	bne	a5,s2,80003cfc <namex+0x12e>
    80003d08:	b7ad                	j	80003c72 <namex+0xa4>
    memmove(name, s, len);
    80003d0a:	2601                	sext.w	a2,a2
    80003d0c:	85a6                	mv	a1,s1
    80003d0e:	8556                	mv	a0,s5
    80003d10:	ffffd097          	auipc	ra,0xffffd
    80003d14:	048080e7          	jalr	72(ra) # 80000d58 <memmove>
    name[len] = 0;
    80003d18:	9d56                	add	s10,s10,s5
    80003d1a:	000d0023          	sb	zero,0(s10)
    80003d1e:	84ce                	mv	s1,s3
    80003d20:	b7bd                	j	80003c8e <namex+0xc0>
  if(nameiparent){
    80003d22:	f00b0ce3          	beqz	s6,80003c3a <namex+0x6c>
    iput(ip);
    80003d26:	8552                	mv	a0,s4
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	ad2080e7          	jalr	-1326(ra) # 800037fa <iput>
    return 0;
    80003d30:	4a01                	li	s4,0
    80003d32:	b721                	j	80003c3a <namex+0x6c>

0000000080003d34 <dirlink>:
{
    80003d34:	7139                	addi	sp,sp,-64
    80003d36:	fc06                	sd	ra,56(sp)
    80003d38:	f822                	sd	s0,48(sp)
    80003d3a:	f426                	sd	s1,40(sp)
    80003d3c:	f04a                	sd	s2,32(sp)
    80003d3e:	ec4e                	sd	s3,24(sp)
    80003d40:	e852                	sd	s4,16(sp)
    80003d42:	0080                	addi	s0,sp,64
    80003d44:	892a                	mv	s2,a0
    80003d46:	8a2e                	mv	s4,a1
    80003d48:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003d4a:	4601                	li	a2,0
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	dd2080e7          	jalr	-558(ra) # 80003b1e <dirlookup>
    80003d54:	e93d                	bnez	a0,80003dca <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d56:	04c92483          	lw	s1,76(s2)
    80003d5a:	c49d                	beqz	s1,80003d88 <dirlink+0x54>
    80003d5c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d5e:	4741                	li	a4,16
    80003d60:	86a6                	mv	a3,s1
    80003d62:	fc040613          	addi	a2,s0,-64
    80003d66:	4581                	li	a1,0
    80003d68:	854a                	mv	a0,s2
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	b8a080e7          	jalr	-1142(ra) # 800038f4 <readi>
    80003d72:	47c1                	li	a5,16
    80003d74:	06f51163          	bne	a0,a5,80003dd6 <dirlink+0xa2>
    if(de.inum == 0)
    80003d78:	fc045783          	lhu	a5,-64(s0)
    80003d7c:	c791                	beqz	a5,80003d88 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d7e:	24c1                	addiw	s1,s1,16
    80003d80:	04c92783          	lw	a5,76(s2)
    80003d84:	fcf4ede3          	bltu	s1,a5,80003d5e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003d88:	4639                	li	a2,14
    80003d8a:	85d2                	mv	a1,s4
    80003d8c:	fc240513          	addi	a0,s0,-62
    80003d90:	ffffd097          	auipc	ra,0xffffd
    80003d94:	080080e7          	jalr	128(ra) # 80000e10 <strncpy>
  de.inum = inum;
    80003d98:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d9c:	4741                	li	a4,16
    80003d9e:	86a6                	mv	a3,s1
    80003da0:	fc040613          	addi	a2,s0,-64
    80003da4:	4581                	li	a1,0
    80003da6:	854a                	mv	a0,s2
    80003da8:	00000097          	auipc	ra,0x0
    80003dac:	c42080e7          	jalr	-958(ra) # 800039ea <writei>
    80003db0:	872a                	mv	a4,a0
    80003db2:	47c1                	li	a5,16
  return 0;
    80003db4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db6:	02f71863          	bne	a4,a5,80003de6 <dirlink+0xb2>
}
    80003dba:	70e2                	ld	ra,56(sp)
    80003dbc:	7442                	ld	s0,48(sp)
    80003dbe:	74a2                	ld	s1,40(sp)
    80003dc0:	7902                	ld	s2,32(sp)
    80003dc2:	69e2                	ld	s3,24(sp)
    80003dc4:	6a42                	ld	s4,16(sp)
    80003dc6:	6121                	addi	sp,sp,64
    80003dc8:	8082                	ret
    iput(ip);
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	a30080e7          	jalr	-1488(ra) # 800037fa <iput>
    return -1;
    80003dd2:	557d                	li	a0,-1
    80003dd4:	b7dd                	j	80003dba <dirlink+0x86>
      panic("dirlink read");
    80003dd6:	00005517          	auipc	a0,0x5
    80003dda:	82250513          	addi	a0,a0,-2014 # 800085f8 <syscalls+0x1d0>
    80003dde:	ffffc097          	auipc	ra,0xffffc
    80003de2:	768080e7          	jalr	1896(ra) # 80000546 <panic>
    panic("dirlink");
    80003de6:	00005517          	auipc	a0,0x5
    80003dea:	98a50513          	addi	a0,a0,-1654 # 80008770 <syscalls+0x348>
    80003dee:	ffffc097          	auipc	ra,0xffffc
    80003df2:	758080e7          	jalr	1880(ra) # 80000546 <panic>

0000000080003df6 <namei>:

struct inode*
namei(char *path)
{
    80003df6:	1101                	addi	sp,sp,-32
    80003df8:	ec06                	sd	ra,24(sp)
    80003dfa:	e822                	sd	s0,16(sp)
    80003dfc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003dfe:	fe040613          	addi	a2,s0,-32
    80003e02:	4581                	li	a1,0
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	dca080e7          	jalr	-566(ra) # 80003bce <namex>
}
    80003e0c:	60e2                	ld	ra,24(sp)
    80003e0e:	6442                	ld	s0,16(sp)
    80003e10:	6105                	addi	sp,sp,32
    80003e12:	8082                	ret

0000000080003e14 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e14:	1141                	addi	sp,sp,-16
    80003e16:	e406                	sd	ra,8(sp)
    80003e18:	e022                	sd	s0,0(sp)
    80003e1a:	0800                	addi	s0,sp,16
    80003e1c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e1e:	4585                	li	a1,1
    80003e20:	00000097          	auipc	ra,0x0
    80003e24:	dae080e7          	jalr	-594(ra) # 80003bce <namex>
}
    80003e28:	60a2                	ld	ra,8(sp)
    80003e2a:	6402                	ld	s0,0(sp)
    80003e2c:	0141                	addi	sp,sp,16
    80003e2e:	8082                	ret

0000000080003e30 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e30:	1101                	addi	sp,sp,-32
    80003e32:	ec06                	sd	ra,24(sp)
    80003e34:	e822                	sd	s0,16(sp)
    80003e36:	e426                	sd	s1,8(sp)
    80003e38:	e04a                	sd	s2,0(sp)
    80003e3a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003e3c:	0001e917          	auipc	s2,0x1e
    80003e40:	acc90913          	addi	s2,s2,-1332 # 80021908 <log>
    80003e44:	01892583          	lw	a1,24(s2)
    80003e48:	02892503          	lw	a0,40(s2)
    80003e4c:	fffff097          	auipc	ra,0xfffff
    80003e50:	ff2080e7          	jalr	-14(ra) # 80002e3e <bread>
    80003e54:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003e56:	02c92683          	lw	a3,44(s2)
    80003e5a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003e5c:	02d05863          	blez	a3,80003e8c <write_head+0x5c>
    80003e60:	0001e797          	auipc	a5,0x1e
    80003e64:	ad878793          	addi	a5,a5,-1320 # 80021938 <log+0x30>
    80003e68:	05c50713          	addi	a4,a0,92
    80003e6c:	36fd                	addiw	a3,a3,-1
    80003e6e:	02069613          	slli	a2,a3,0x20
    80003e72:	01e65693          	srli	a3,a2,0x1e
    80003e76:	0001e617          	auipc	a2,0x1e
    80003e7a:	ac660613          	addi	a2,a2,-1338 # 8002193c <log+0x34>
    80003e7e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003e80:	4390                	lw	a2,0(a5)
    80003e82:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003e84:	0791                	addi	a5,a5,4
    80003e86:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003e88:	fed79ce3          	bne	a5,a3,80003e80 <write_head+0x50>
  }
  bwrite(buf);
    80003e8c:	8526                	mv	a0,s1
    80003e8e:	fffff097          	auipc	ra,0xfffff
    80003e92:	0a2080e7          	jalr	162(ra) # 80002f30 <bwrite>
  brelse(buf);
    80003e96:	8526                	mv	a0,s1
    80003e98:	fffff097          	auipc	ra,0xfffff
    80003e9c:	0d6080e7          	jalr	214(ra) # 80002f6e <brelse>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	64a2                	ld	s1,8(sp)
    80003ea6:	6902                	ld	s2,0(sp)
    80003ea8:	6105                	addi	sp,sp,32
    80003eaa:	8082                	ret

0000000080003eac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003eac:	0001e797          	auipc	a5,0x1e
    80003eb0:	a887a783          	lw	a5,-1400(a5) # 80021934 <log+0x2c>
    80003eb4:	0af05663          	blez	a5,80003f60 <install_trans+0xb4>
{
    80003eb8:	7139                	addi	sp,sp,-64
    80003eba:	fc06                	sd	ra,56(sp)
    80003ebc:	f822                	sd	s0,48(sp)
    80003ebe:	f426                	sd	s1,40(sp)
    80003ec0:	f04a                	sd	s2,32(sp)
    80003ec2:	ec4e                	sd	s3,24(sp)
    80003ec4:	e852                	sd	s4,16(sp)
    80003ec6:	e456                	sd	s5,8(sp)
    80003ec8:	0080                	addi	s0,sp,64
    80003eca:	0001ea97          	auipc	s5,0x1e
    80003ece:	a6ea8a93          	addi	s5,s5,-1426 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ed2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ed4:	0001e997          	auipc	s3,0x1e
    80003ed8:	a3498993          	addi	s3,s3,-1484 # 80021908 <log>
    80003edc:	0189a583          	lw	a1,24(s3)
    80003ee0:	014585bb          	addw	a1,a1,s4
    80003ee4:	2585                	addiw	a1,a1,1
    80003ee6:	0289a503          	lw	a0,40(s3)
    80003eea:	fffff097          	auipc	ra,0xfffff
    80003eee:	f54080e7          	jalr	-172(ra) # 80002e3e <bread>
    80003ef2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003ef4:	000aa583          	lw	a1,0(s5)
    80003ef8:	0289a503          	lw	a0,40(s3)
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	f42080e7          	jalr	-190(ra) # 80002e3e <bread>
    80003f04:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f06:	40000613          	li	a2,1024
    80003f0a:	05890593          	addi	a1,s2,88
    80003f0e:	05850513          	addi	a0,a0,88
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	e46080e7          	jalr	-442(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f1a:	8526                	mv	a0,s1
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	014080e7          	jalr	20(ra) # 80002f30 <bwrite>
    bunpin(dbuf);
    80003f24:	8526                	mv	a0,s1
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	122080e7          	jalr	290(ra) # 80003048 <bunpin>
    brelse(lbuf);
    80003f2e:	854a                	mv	a0,s2
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	03e080e7          	jalr	62(ra) # 80002f6e <brelse>
    brelse(dbuf);
    80003f38:	8526                	mv	a0,s1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	034080e7          	jalr	52(ra) # 80002f6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f42:	2a05                	addiw	s4,s4,1
    80003f44:	0a91                	addi	s5,s5,4
    80003f46:	02c9a783          	lw	a5,44(s3)
    80003f4a:	f8fa49e3          	blt	s4,a5,80003edc <install_trans+0x30>
}
    80003f4e:	70e2                	ld	ra,56(sp)
    80003f50:	7442                	ld	s0,48(sp)
    80003f52:	74a2                	ld	s1,40(sp)
    80003f54:	7902                	ld	s2,32(sp)
    80003f56:	69e2                	ld	s3,24(sp)
    80003f58:	6a42                	ld	s4,16(sp)
    80003f5a:	6aa2                	ld	s5,8(sp)
    80003f5c:	6121                	addi	sp,sp,64
    80003f5e:	8082                	ret
    80003f60:	8082                	ret

0000000080003f62 <initlog>:
{
    80003f62:	7179                	addi	sp,sp,-48
    80003f64:	f406                	sd	ra,40(sp)
    80003f66:	f022                	sd	s0,32(sp)
    80003f68:	ec26                	sd	s1,24(sp)
    80003f6a:	e84a                	sd	s2,16(sp)
    80003f6c:	e44e                	sd	s3,8(sp)
    80003f6e:	1800                	addi	s0,sp,48
    80003f70:	892a                	mv	s2,a0
    80003f72:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003f74:	0001e497          	auipc	s1,0x1e
    80003f78:	99448493          	addi	s1,s1,-1644 # 80021908 <log>
    80003f7c:	00004597          	auipc	a1,0x4
    80003f80:	68c58593          	addi	a1,a1,1676 # 80008608 <syscalls+0x1e0>
    80003f84:	8526                	mv	a0,s1
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	bea080e7          	jalr	-1046(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    80003f8e:	0149a583          	lw	a1,20(s3)
    80003f92:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80003f94:	0109a783          	lw	a5,16(s3)
    80003f98:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80003f9a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003f9e:	854a                	mv	a0,s2
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	e9e080e7          	jalr	-354(ra) # 80002e3e <bread>
  log.lh.n = lh->n;
    80003fa8:	4d34                	lw	a3,88(a0)
    80003faa:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003fac:	02d05663          	blez	a3,80003fd8 <initlog+0x76>
    80003fb0:	05c50793          	addi	a5,a0,92
    80003fb4:	0001e717          	auipc	a4,0x1e
    80003fb8:	98470713          	addi	a4,a4,-1660 # 80021938 <log+0x30>
    80003fbc:	36fd                	addiw	a3,a3,-1
    80003fbe:	02069613          	slli	a2,a3,0x20
    80003fc2:	01e65693          	srli	a3,a2,0x1e
    80003fc6:	06050613          	addi	a2,a0,96
    80003fca:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80003fcc:	4390                	lw	a2,0(a5)
    80003fce:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fd0:	0791                	addi	a5,a5,4
    80003fd2:	0711                	addi	a4,a4,4
    80003fd4:	fed79ce3          	bne	a5,a3,80003fcc <initlog+0x6a>
  brelse(buf);
    80003fd8:	fffff097          	auipc	ra,0xfffff
    80003fdc:	f96080e7          	jalr	-106(ra) # 80002f6e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	ecc080e7          	jalr	-308(ra) # 80003eac <install_trans>
  log.lh.n = 0;
    80003fe8:	0001e797          	auipc	a5,0x1e
    80003fec:	9407a623          	sw	zero,-1716(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	e40080e7          	jalr	-448(ra) # 80003e30 <write_head>
}
    80003ff8:	70a2                	ld	ra,40(sp)
    80003ffa:	7402                	ld	s0,32(sp)
    80003ffc:	64e2                	ld	s1,24(sp)
    80003ffe:	6942                	ld	s2,16(sp)
    80004000:	69a2                	ld	s3,8(sp)
    80004002:	6145                	addi	sp,sp,48
    80004004:	8082                	ret

0000000080004006 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004006:	1101                	addi	sp,sp,-32
    80004008:	ec06                	sd	ra,24(sp)
    8000400a:	e822                	sd	s0,16(sp)
    8000400c:	e426                	sd	s1,8(sp)
    8000400e:	e04a                	sd	s2,0(sp)
    80004010:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004012:	0001e517          	auipc	a0,0x1e
    80004016:	8f650513          	addi	a0,a0,-1802 # 80021908 <log>
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	be6080e7          	jalr	-1050(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    80004022:	0001e497          	auipc	s1,0x1e
    80004026:	8e648493          	addi	s1,s1,-1818 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000402a:	4979                	li	s2,30
    8000402c:	a039                	j	8000403a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000402e:	85a6                	mv	a1,s1
    80004030:	8526                	mv	a0,s1
    80004032:	ffffe097          	auipc	ra,0xffffe
    80004036:	1dc080e7          	jalr	476(ra) # 8000220e <sleep>
    if(log.committing){
    8000403a:	50dc                	lw	a5,36(s1)
    8000403c:	fbed                	bnez	a5,8000402e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000403e:	5098                	lw	a4,32(s1)
    80004040:	2705                	addiw	a4,a4,1
    80004042:	0007069b          	sext.w	a3,a4
    80004046:	0027179b          	slliw	a5,a4,0x2
    8000404a:	9fb9                	addw	a5,a5,a4
    8000404c:	0017979b          	slliw	a5,a5,0x1
    80004050:	54d8                	lw	a4,44(s1)
    80004052:	9fb9                	addw	a5,a5,a4
    80004054:	00f95963          	bge	s2,a5,80004066 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004058:	85a6                	mv	a1,s1
    8000405a:	8526                	mv	a0,s1
    8000405c:	ffffe097          	auipc	ra,0xffffe
    80004060:	1b2080e7          	jalr	434(ra) # 8000220e <sleep>
    80004064:	bfd9                	j	8000403a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004066:	0001e517          	auipc	a0,0x1e
    8000406a:	8a250513          	addi	a0,a0,-1886 # 80021908 <log>
    8000406e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004070:	ffffd097          	auipc	ra,0xffffd
    80004074:	c44080e7          	jalr	-956(ra) # 80000cb4 <release>
      break;
    }
  }
}
    80004078:	60e2                	ld	ra,24(sp)
    8000407a:	6442                	ld	s0,16(sp)
    8000407c:	64a2                	ld	s1,8(sp)
    8000407e:	6902                	ld	s2,0(sp)
    80004080:	6105                	addi	sp,sp,32
    80004082:	8082                	ret

0000000080004084 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004084:	7139                	addi	sp,sp,-64
    80004086:	fc06                	sd	ra,56(sp)
    80004088:	f822                	sd	s0,48(sp)
    8000408a:	f426                	sd	s1,40(sp)
    8000408c:	f04a                	sd	s2,32(sp)
    8000408e:	ec4e                	sd	s3,24(sp)
    80004090:	e852                	sd	s4,16(sp)
    80004092:	e456                	sd	s5,8(sp)
    80004094:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004096:	0001e497          	auipc	s1,0x1e
    8000409a:	87248493          	addi	s1,s1,-1934 # 80021908 <log>
    8000409e:	8526                	mv	a0,s1
    800040a0:	ffffd097          	auipc	ra,0xffffd
    800040a4:	b60080e7          	jalr	-1184(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    800040a8:	509c                	lw	a5,32(s1)
    800040aa:	37fd                	addiw	a5,a5,-1
    800040ac:	0007891b          	sext.w	s2,a5
    800040b0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800040b2:	50dc                	lw	a5,36(s1)
    800040b4:	e7b9                	bnez	a5,80004102 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800040b6:	04091e63          	bnez	s2,80004112 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800040ba:	0001e497          	auipc	s1,0x1e
    800040be:	84e48493          	addi	s1,s1,-1970 # 80021908 <log>
    800040c2:	4785                	li	a5,1
    800040c4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffd097          	auipc	ra,0xffffd
    800040cc:	bec080e7          	jalr	-1044(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800040d0:	54dc                	lw	a5,44(s1)
    800040d2:	06f04763          	bgtz	a5,80004140 <end_op+0xbc>
    acquire(&log.lock);
    800040d6:	0001e497          	auipc	s1,0x1e
    800040da:	83248493          	addi	s1,s1,-1998 # 80021908 <log>
    800040de:	8526                	mv	a0,s1
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	b20080e7          	jalr	-1248(ra) # 80000c00 <acquire>
    log.committing = 0;
    800040e8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800040ec:	8526                	mv	a0,s1
    800040ee:	ffffe097          	auipc	ra,0xffffe
    800040f2:	2a0080e7          	jalr	672(ra) # 8000238e <wakeup>
    release(&log.lock);
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	bbc080e7          	jalr	-1092(ra) # 80000cb4 <release>
}
    80004100:	a03d                	j	8000412e <end_op+0xaa>
    panic("log.committing");
    80004102:	00004517          	auipc	a0,0x4
    80004106:	50e50513          	addi	a0,a0,1294 # 80008610 <syscalls+0x1e8>
    8000410a:	ffffc097          	auipc	ra,0xffffc
    8000410e:	43c080e7          	jalr	1084(ra) # 80000546 <panic>
    wakeup(&log);
    80004112:	0001d497          	auipc	s1,0x1d
    80004116:	7f648493          	addi	s1,s1,2038 # 80021908 <log>
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffe097          	auipc	ra,0xffffe
    80004120:	272080e7          	jalr	626(ra) # 8000238e <wakeup>
  release(&log.lock);
    80004124:	8526                	mv	a0,s1
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	b8e080e7          	jalr	-1138(ra) # 80000cb4 <release>
}
    8000412e:	70e2                	ld	ra,56(sp)
    80004130:	7442                	ld	s0,48(sp)
    80004132:	74a2                	ld	s1,40(sp)
    80004134:	7902                	ld	s2,32(sp)
    80004136:	69e2                	ld	s3,24(sp)
    80004138:	6a42                	ld	s4,16(sp)
    8000413a:	6aa2                	ld	s5,8(sp)
    8000413c:	6121                	addi	sp,sp,64
    8000413e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004140:	0001da97          	auipc	s5,0x1d
    80004144:	7f8a8a93          	addi	s5,s5,2040 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004148:	0001da17          	auipc	s4,0x1d
    8000414c:	7c0a0a13          	addi	s4,s4,1984 # 80021908 <log>
    80004150:	018a2583          	lw	a1,24(s4)
    80004154:	012585bb          	addw	a1,a1,s2
    80004158:	2585                	addiw	a1,a1,1
    8000415a:	028a2503          	lw	a0,40(s4)
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	ce0080e7          	jalr	-800(ra) # 80002e3e <bread>
    80004166:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004168:	000aa583          	lw	a1,0(s5)
    8000416c:	028a2503          	lw	a0,40(s4)
    80004170:	fffff097          	auipc	ra,0xfffff
    80004174:	cce080e7          	jalr	-818(ra) # 80002e3e <bread>
    80004178:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000417a:	40000613          	li	a2,1024
    8000417e:	05850593          	addi	a1,a0,88
    80004182:	05848513          	addi	a0,s1,88
    80004186:	ffffd097          	auipc	ra,0xffffd
    8000418a:	bd2080e7          	jalr	-1070(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	da0080e7          	jalr	-608(ra) # 80002f30 <bwrite>
    brelse(from);
    80004198:	854e                	mv	a0,s3
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	dd4080e7          	jalr	-556(ra) # 80002f6e <brelse>
    brelse(to);
    800041a2:	8526                	mv	a0,s1
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	dca080e7          	jalr	-566(ra) # 80002f6e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ac:	2905                	addiw	s2,s2,1
    800041ae:	0a91                	addi	s5,s5,4
    800041b0:	02ca2783          	lw	a5,44(s4)
    800041b4:	f8f94ee3          	blt	s2,a5,80004150 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	c78080e7          	jalr	-904(ra) # 80003e30 <write_head>
    install_trans(); // Now install writes to home locations
    800041c0:	00000097          	auipc	ra,0x0
    800041c4:	cec080e7          	jalr	-788(ra) # 80003eac <install_trans>
    log.lh.n = 0;
    800041c8:	0001d797          	auipc	a5,0x1d
    800041cc:	7607a623          	sw	zero,1900(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	c60080e7          	jalr	-928(ra) # 80003e30 <write_head>
    800041d8:	bdfd                	j	800040d6 <end_op+0x52>

00000000800041da <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800041da:	1101                	addi	sp,sp,-32
    800041dc:	ec06                	sd	ra,24(sp)
    800041de:	e822                	sd	s0,16(sp)
    800041e0:	e426                	sd	s1,8(sp)
    800041e2:	e04a                	sd	s2,0(sp)
    800041e4:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800041e6:	0001d717          	auipc	a4,0x1d
    800041ea:	74e72703          	lw	a4,1870(a4) # 80021934 <log+0x2c>
    800041ee:	47f5                	li	a5,29
    800041f0:	08e7c063          	blt	a5,a4,80004270 <log_write+0x96>
    800041f4:	84aa                	mv	s1,a0
    800041f6:	0001d797          	auipc	a5,0x1d
    800041fa:	72e7a783          	lw	a5,1838(a5) # 80021924 <log+0x1c>
    800041fe:	37fd                	addiw	a5,a5,-1
    80004200:	06f75863          	bge	a4,a5,80004270 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004204:	0001d797          	auipc	a5,0x1d
    80004208:	7247a783          	lw	a5,1828(a5) # 80021928 <log+0x20>
    8000420c:	06f05a63          	blez	a5,80004280 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004210:	0001d917          	auipc	s2,0x1d
    80004214:	6f890913          	addi	s2,s2,1784 # 80021908 <log>
    80004218:	854a                	mv	a0,s2
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9e6080e7          	jalr	-1562(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004222:	02c92603          	lw	a2,44(s2)
    80004226:	06c05563          	blez	a2,80004290 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000422a:	44cc                	lw	a1,12(s1)
    8000422c:	0001d717          	auipc	a4,0x1d
    80004230:	70c70713          	addi	a4,a4,1804 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004234:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004236:	4314                	lw	a3,0(a4)
    80004238:	04b68d63          	beq	a3,a1,80004292 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000423c:	2785                	addiw	a5,a5,1
    8000423e:	0711                	addi	a4,a4,4
    80004240:	fec79be3          	bne	a5,a2,80004236 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004244:	0621                	addi	a2,a2,8
    80004246:	060a                	slli	a2,a2,0x2
    80004248:	0001d797          	auipc	a5,0x1d
    8000424c:	6c078793          	addi	a5,a5,1728 # 80021908 <log>
    80004250:	97b2                	add	a5,a5,a2
    80004252:	44d8                	lw	a4,12(s1)
    80004254:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004256:	8526                	mv	a0,s1
    80004258:	fffff097          	auipc	ra,0xfffff
    8000425c:	db4080e7          	jalr	-588(ra) # 8000300c <bpin>
    log.lh.n++;
    80004260:	0001d717          	auipc	a4,0x1d
    80004264:	6a870713          	addi	a4,a4,1704 # 80021908 <log>
    80004268:	575c                	lw	a5,44(a4)
    8000426a:	2785                	addiw	a5,a5,1
    8000426c:	d75c                	sw	a5,44(a4)
    8000426e:	a835                	j	800042aa <log_write+0xd0>
    panic("too big a transaction");
    80004270:	00004517          	auipc	a0,0x4
    80004274:	3b050513          	addi	a0,a0,944 # 80008620 <syscalls+0x1f8>
    80004278:	ffffc097          	auipc	ra,0xffffc
    8000427c:	2ce080e7          	jalr	718(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    80004280:	00004517          	auipc	a0,0x4
    80004284:	3b850513          	addi	a0,a0,952 # 80008638 <syscalls+0x210>
    80004288:	ffffc097          	auipc	ra,0xffffc
    8000428c:	2be080e7          	jalr	702(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004290:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004292:	00878693          	addi	a3,a5,8
    80004296:	068a                	slli	a3,a3,0x2
    80004298:	0001d717          	auipc	a4,0x1d
    8000429c:	67070713          	addi	a4,a4,1648 # 80021908 <log>
    800042a0:	9736                	add	a4,a4,a3
    800042a2:	44d4                	lw	a3,12(s1)
    800042a4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800042a6:	faf608e3          	beq	a2,a5,80004256 <log_write+0x7c>
  }
  release(&log.lock);
    800042aa:	0001d517          	auipc	a0,0x1d
    800042ae:	65e50513          	addi	a0,a0,1630 # 80021908 <log>
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	a02080e7          	jalr	-1534(ra) # 80000cb4 <release>
}
    800042ba:	60e2                	ld	ra,24(sp)
    800042bc:	6442                	ld	s0,16(sp)
    800042be:	64a2                	ld	s1,8(sp)
    800042c0:	6902                	ld	s2,0(sp)
    800042c2:	6105                	addi	sp,sp,32
    800042c4:	8082                	ret

00000000800042c6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800042c6:	1101                	addi	sp,sp,-32
    800042c8:	ec06                	sd	ra,24(sp)
    800042ca:	e822                	sd	s0,16(sp)
    800042cc:	e426                	sd	s1,8(sp)
    800042ce:	e04a                	sd	s2,0(sp)
    800042d0:	1000                	addi	s0,sp,32
    800042d2:	84aa                	mv	s1,a0
    800042d4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800042d6:	00004597          	auipc	a1,0x4
    800042da:	38258593          	addi	a1,a1,898 # 80008658 <syscalls+0x230>
    800042de:	0521                	addi	a0,a0,8
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	890080e7          	jalr	-1904(ra) # 80000b70 <initlock>
  lk->name = name;
    800042e8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800042ec:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800042f0:	0204a423          	sw	zero,40(s1)
}
    800042f4:	60e2                	ld	ra,24(sp)
    800042f6:	6442                	ld	s0,16(sp)
    800042f8:	64a2                	ld	s1,8(sp)
    800042fa:	6902                	ld	s2,0(sp)
    800042fc:	6105                	addi	sp,sp,32
    800042fe:	8082                	ret

0000000080004300 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004300:	1101                	addi	sp,sp,-32
    80004302:	ec06                	sd	ra,24(sp)
    80004304:	e822                	sd	s0,16(sp)
    80004306:	e426                	sd	s1,8(sp)
    80004308:	e04a                	sd	s2,0(sp)
    8000430a:	1000                	addi	s0,sp,32
    8000430c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000430e:	00850913          	addi	s2,a0,8
    80004312:	854a                	mv	a0,s2
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	8ec080e7          	jalr	-1812(ra) # 80000c00 <acquire>
  while (lk->locked) {
    8000431c:	409c                	lw	a5,0(s1)
    8000431e:	cb89                	beqz	a5,80004330 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004320:	85ca                	mv	a1,s2
    80004322:	8526                	mv	a0,s1
    80004324:	ffffe097          	auipc	ra,0xffffe
    80004328:	eea080e7          	jalr	-278(ra) # 8000220e <sleep>
  while (lk->locked) {
    8000432c:	409c                	lw	a5,0(s1)
    8000432e:	fbed                	bnez	a5,80004320 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004330:	4785                	li	a5,1
    80004332:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	6c6080e7          	jalr	1734(ra) # 800019fa <myproc>
    8000433c:	5d1c                	lw	a5,56(a0)
    8000433e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004340:	854a                	mv	a0,s2
    80004342:	ffffd097          	auipc	ra,0xffffd
    80004346:	972080e7          	jalr	-1678(ra) # 80000cb4 <release>
}
    8000434a:	60e2                	ld	ra,24(sp)
    8000434c:	6442                	ld	s0,16(sp)
    8000434e:	64a2                	ld	s1,8(sp)
    80004350:	6902                	ld	s2,0(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004356:	1101                	addi	sp,sp,-32
    80004358:	ec06                	sd	ra,24(sp)
    8000435a:	e822                	sd	s0,16(sp)
    8000435c:	e426                	sd	s1,8(sp)
    8000435e:	e04a                	sd	s2,0(sp)
    80004360:	1000                	addi	s0,sp,32
    80004362:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004364:	00850913          	addi	s2,a0,8
    80004368:	854a                	mv	a0,s2
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	896080e7          	jalr	-1898(ra) # 80000c00 <acquire>
  lk->locked = 0;
    80004372:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004376:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffe097          	auipc	ra,0xffffe
    80004380:	012080e7          	jalr	18(ra) # 8000238e <wakeup>
  release(&lk->lk);
    80004384:	854a                	mv	a0,s2
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	92e080e7          	jalr	-1746(ra) # 80000cb4 <release>
}
    8000438e:	60e2                	ld	ra,24(sp)
    80004390:	6442                	ld	s0,16(sp)
    80004392:	64a2                	ld	s1,8(sp)
    80004394:	6902                	ld	s2,0(sp)
    80004396:	6105                	addi	sp,sp,32
    80004398:	8082                	ret

000000008000439a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000439a:	7179                	addi	sp,sp,-48
    8000439c:	f406                	sd	ra,40(sp)
    8000439e:	f022                	sd	s0,32(sp)
    800043a0:	ec26                	sd	s1,24(sp)
    800043a2:	e84a                	sd	s2,16(sp)
    800043a4:	e44e                	sd	s3,8(sp)
    800043a6:	1800                	addi	s0,sp,48
    800043a8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800043aa:	00850913          	addi	s2,a0,8
    800043ae:	854a                	mv	a0,s2
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	850080e7          	jalr	-1968(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800043b8:	409c                	lw	a5,0(s1)
    800043ba:	ef99                	bnez	a5,800043d8 <holdingsleep+0x3e>
    800043bc:	4481                	li	s1,0
  release(&lk->lk);
    800043be:	854a                	mv	a0,s2
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	8f4080e7          	jalr	-1804(ra) # 80000cb4 <release>
  return r;
}
    800043c8:	8526                	mv	a0,s1
    800043ca:	70a2                	ld	ra,40(sp)
    800043cc:	7402                	ld	s0,32(sp)
    800043ce:	64e2                	ld	s1,24(sp)
    800043d0:	6942                	ld	s2,16(sp)
    800043d2:	69a2                	ld	s3,8(sp)
    800043d4:	6145                	addi	sp,sp,48
    800043d6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800043d8:	0284a983          	lw	s3,40(s1)
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	61e080e7          	jalr	1566(ra) # 800019fa <myproc>
    800043e4:	5d04                	lw	s1,56(a0)
    800043e6:	413484b3          	sub	s1,s1,s3
    800043ea:	0014b493          	seqz	s1,s1
    800043ee:	bfc1                	j	800043be <holdingsleep+0x24>

00000000800043f0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800043f0:	1141                	addi	sp,sp,-16
    800043f2:	e406                	sd	ra,8(sp)
    800043f4:	e022                	sd	s0,0(sp)
    800043f6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800043f8:	00004597          	auipc	a1,0x4
    800043fc:	27058593          	addi	a1,a1,624 # 80008668 <syscalls+0x240>
    80004400:	0001d517          	auipc	a0,0x1d
    80004404:	65050513          	addi	a0,a0,1616 # 80021a50 <ftable>
    80004408:	ffffc097          	auipc	ra,0xffffc
    8000440c:	768080e7          	jalr	1896(ra) # 80000b70 <initlock>
}
    80004410:	60a2                	ld	ra,8(sp)
    80004412:	6402                	ld	s0,0(sp)
    80004414:	0141                	addi	sp,sp,16
    80004416:	8082                	ret

0000000080004418 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004418:	1101                	addi	sp,sp,-32
    8000441a:	ec06                	sd	ra,24(sp)
    8000441c:	e822                	sd	s0,16(sp)
    8000441e:	e426                	sd	s1,8(sp)
    80004420:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004422:	0001d517          	auipc	a0,0x1d
    80004426:	62e50513          	addi	a0,a0,1582 # 80021a50 <ftable>
    8000442a:	ffffc097          	auipc	ra,0xffffc
    8000442e:	7d6080e7          	jalr	2006(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004432:	0001d497          	auipc	s1,0x1d
    80004436:	63648493          	addi	s1,s1,1590 # 80021a68 <ftable+0x18>
    8000443a:	0001e717          	auipc	a4,0x1e
    8000443e:	5ce70713          	addi	a4,a4,1486 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004442:	40dc                	lw	a5,4(s1)
    80004444:	cf99                	beqz	a5,80004462 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004446:	02848493          	addi	s1,s1,40
    8000444a:	fee49ce3          	bne	s1,a4,80004442 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000444e:	0001d517          	auipc	a0,0x1d
    80004452:	60250513          	addi	a0,a0,1538 # 80021a50 <ftable>
    80004456:	ffffd097          	auipc	ra,0xffffd
    8000445a:	85e080e7          	jalr	-1954(ra) # 80000cb4 <release>
  return 0;
    8000445e:	4481                	li	s1,0
    80004460:	a819                	j	80004476 <filealloc+0x5e>
      f->ref = 1;
    80004462:	4785                	li	a5,1
    80004464:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004466:	0001d517          	auipc	a0,0x1d
    8000446a:	5ea50513          	addi	a0,a0,1514 # 80021a50 <ftable>
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	846080e7          	jalr	-1978(ra) # 80000cb4 <release>
}
    80004476:	8526                	mv	a0,s1
    80004478:	60e2                	ld	ra,24(sp)
    8000447a:	6442                	ld	s0,16(sp)
    8000447c:	64a2                	ld	s1,8(sp)
    8000447e:	6105                	addi	sp,sp,32
    80004480:	8082                	ret

0000000080004482 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004482:	1101                	addi	sp,sp,-32
    80004484:	ec06                	sd	ra,24(sp)
    80004486:	e822                	sd	s0,16(sp)
    80004488:	e426                	sd	s1,8(sp)
    8000448a:	1000                	addi	s0,sp,32
    8000448c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000448e:	0001d517          	auipc	a0,0x1d
    80004492:	5c250513          	addi	a0,a0,1474 # 80021a50 <ftable>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	76a080e7          	jalr	1898(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    8000449e:	40dc                	lw	a5,4(s1)
    800044a0:	02f05263          	blez	a5,800044c4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800044a4:	2785                	addiw	a5,a5,1
    800044a6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800044a8:	0001d517          	auipc	a0,0x1d
    800044ac:	5a850513          	addi	a0,a0,1448 # 80021a50 <ftable>
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	804080e7          	jalr	-2044(ra) # 80000cb4 <release>
  return f;
}
    800044b8:	8526                	mv	a0,s1
    800044ba:	60e2                	ld	ra,24(sp)
    800044bc:	6442                	ld	s0,16(sp)
    800044be:	64a2                	ld	s1,8(sp)
    800044c0:	6105                	addi	sp,sp,32
    800044c2:	8082                	ret
    panic("filedup");
    800044c4:	00004517          	auipc	a0,0x4
    800044c8:	1ac50513          	addi	a0,a0,428 # 80008670 <syscalls+0x248>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	07a080e7          	jalr	122(ra) # 80000546 <panic>

00000000800044d4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800044d4:	7139                	addi	sp,sp,-64
    800044d6:	fc06                	sd	ra,56(sp)
    800044d8:	f822                	sd	s0,48(sp)
    800044da:	f426                	sd	s1,40(sp)
    800044dc:	f04a                	sd	s2,32(sp)
    800044de:	ec4e                	sd	s3,24(sp)
    800044e0:	e852                	sd	s4,16(sp)
    800044e2:	e456                	sd	s5,8(sp)
    800044e4:	0080                	addi	s0,sp,64
    800044e6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	56850513          	addi	a0,a0,1384 # 80021a50 <ftable>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	710080e7          	jalr	1808(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    800044f8:	40dc                	lw	a5,4(s1)
    800044fa:	06f05163          	blez	a5,8000455c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800044fe:	37fd                	addiw	a5,a5,-1
    80004500:	0007871b          	sext.w	a4,a5
    80004504:	c0dc                	sw	a5,4(s1)
    80004506:	06e04363          	bgtz	a4,8000456c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000450a:	0004a903          	lw	s2,0(s1)
    8000450e:	0094ca83          	lbu	s5,9(s1)
    80004512:	0104ba03          	ld	s4,16(s1)
    80004516:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000451a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000451e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004522:	0001d517          	auipc	a0,0x1d
    80004526:	52e50513          	addi	a0,a0,1326 # 80021a50 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	78a080e7          	jalr	1930(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    80004532:	4785                	li	a5,1
    80004534:	04f90d63          	beq	s2,a5,8000458e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004538:	3979                	addiw	s2,s2,-2
    8000453a:	4785                	li	a5,1
    8000453c:	0527e063          	bltu	a5,s2,8000457c <fileclose+0xa8>
    begin_op();
    80004540:	00000097          	auipc	ra,0x0
    80004544:	ac6080e7          	jalr	-1338(ra) # 80004006 <begin_op>
    iput(ff.ip);
    80004548:	854e                	mv	a0,s3
    8000454a:	fffff097          	auipc	ra,0xfffff
    8000454e:	2b0080e7          	jalr	688(ra) # 800037fa <iput>
    end_op();
    80004552:	00000097          	auipc	ra,0x0
    80004556:	b32080e7          	jalr	-1230(ra) # 80004084 <end_op>
    8000455a:	a00d                	j	8000457c <fileclose+0xa8>
    panic("fileclose");
    8000455c:	00004517          	auipc	a0,0x4
    80004560:	11c50513          	addi	a0,a0,284 # 80008678 <syscalls+0x250>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	fe2080e7          	jalr	-30(ra) # 80000546 <panic>
    release(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	4e450513          	addi	a0,a0,1252 # 80021a50 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	740080e7          	jalr	1856(ra) # 80000cb4 <release>
  }
}
    8000457c:	70e2                	ld	ra,56(sp)
    8000457e:	7442                	ld	s0,48(sp)
    80004580:	74a2                	ld	s1,40(sp)
    80004582:	7902                	ld	s2,32(sp)
    80004584:	69e2                	ld	s3,24(sp)
    80004586:	6a42                	ld	s4,16(sp)
    80004588:	6aa2                	ld	s5,8(sp)
    8000458a:	6121                	addi	sp,sp,64
    8000458c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000458e:	85d6                	mv	a1,s5
    80004590:	8552                	mv	a0,s4
    80004592:	00000097          	auipc	ra,0x0
    80004596:	372080e7          	jalr	882(ra) # 80004904 <pipeclose>
    8000459a:	b7cd                	j	8000457c <fileclose+0xa8>

000000008000459c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000459c:	715d                	addi	sp,sp,-80
    8000459e:	e486                	sd	ra,72(sp)
    800045a0:	e0a2                	sd	s0,64(sp)
    800045a2:	fc26                	sd	s1,56(sp)
    800045a4:	f84a                	sd	s2,48(sp)
    800045a6:	f44e                	sd	s3,40(sp)
    800045a8:	0880                	addi	s0,sp,80
    800045aa:	84aa                	mv	s1,a0
    800045ac:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800045ae:	ffffd097          	auipc	ra,0xffffd
    800045b2:	44c080e7          	jalr	1100(ra) # 800019fa <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800045b6:	409c                	lw	a5,0(s1)
    800045b8:	37f9                	addiw	a5,a5,-2
    800045ba:	4705                	li	a4,1
    800045bc:	04f76763          	bltu	a4,a5,8000460a <filestat+0x6e>
    800045c0:	892a                	mv	s2,a0
    ilock(f->ip);
    800045c2:	6c88                	ld	a0,24(s1)
    800045c4:	fffff097          	auipc	ra,0xfffff
    800045c8:	07c080e7          	jalr	124(ra) # 80003640 <ilock>
    stati(f->ip, &st);
    800045cc:	fb840593          	addi	a1,s0,-72
    800045d0:	6c88                	ld	a0,24(s1)
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	2f8080e7          	jalr	760(ra) # 800038ca <stati>
    iunlock(f->ip);
    800045da:	6c88                	ld	a0,24(s1)
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	126080e7          	jalr	294(ra) # 80003702 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800045e4:	46e1                	li	a3,24
    800045e6:	fb840613          	addi	a2,s0,-72
    800045ea:	85ce                	mv	a1,s3
    800045ec:	05093503          	ld	a0,80(s2)
    800045f0:	ffffd097          	auipc	ra,0xffffd
    800045f4:	0da080e7          	jalr	218(ra) # 800016ca <copyout>
    800045f8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800045fc:	60a6                	ld	ra,72(sp)
    800045fe:	6406                	ld	s0,64(sp)
    80004600:	74e2                	ld	s1,56(sp)
    80004602:	7942                	ld	s2,48(sp)
    80004604:	79a2                	ld	s3,40(sp)
    80004606:	6161                	addi	sp,sp,80
    80004608:	8082                	ret
  return -1;
    8000460a:	557d                	li	a0,-1
    8000460c:	bfc5                	j	800045fc <filestat+0x60>

000000008000460e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000460e:	7179                	addi	sp,sp,-48
    80004610:	f406                	sd	ra,40(sp)
    80004612:	f022                	sd	s0,32(sp)
    80004614:	ec26                	sd	s1,24(sp)
    80004616:	e84a                	sd	s2,16(sp)
    80004618:	e44e                	sd	s3,8(sp)
    8000461a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000461c:	00854783          	lbu	a5,8(a0)
    80004620:	c3d5                	beqz	a5,800046c4 <fileread+0xb6>
    80004622:	84aa                	mv	s1,a0
    80004624:	89ae                	mv	s3,a1
    80004626:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004628:	411c                	lw	a5,0(a0)
    8000462a:	4705                	li	a4,1
    8000462c:	04e78963          	beq	a5,a4,8000467e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004630:	470d                	li	a4,3
    80004632:	04e78d63          	beq	a5,a4,8000468c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004636:	4709                	li	a4,2
    80004638:	06e79e63          	bne	a5,a4,800046b4 <fileread+0xa6>
    ilock(f->ip);
    8000463c:	6d08                	ld	a0,24(a0)
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	002080e7          	jalr	2(ra) # 80003640 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004646:	874a                	mv	a4,s2
    80004648:	5094                	lw	a3,32(s1)
    8000464a:	864e                	mv	a2,s3
    8000464c:	4585                	li	a1,1
    8000464e:	6c88                	ld	a0,24(s1)
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	2a4080e7          	jalr	676(ra) # 800038f4 <readi>
    80004658:	892a                	mv	s2,a0
    8000465a:	00a05563          	blez	a0,80004664 <fileread+0x56>
      f->off += r;
    8000465e:	509c                	lw	a5,32(s1)
    80004660:	9fa9                	addw	a5,a5,a0
    80004662:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004664:	6c88                	ld	a0,24(s1)
    80004666:	fffff097          	auipc	ra,0xfffff
    8000466a:	09c080e7          	jalr	156(ra) # 80003702 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000466e:	854a                	mv	a0,s2
    80004670:	70a2                	ld	ra,40(sp)
    80004672:	7402                	ld	s0,32(sp)
    80004674:	64e2                	ld	s1,24(sp)
    80004676:	6942                	ld	s2,16(sp)
    80004678:	69a2                	ld	s3,8(sp)
    8000467a:	6145                	addi	sp,sp,48
    8000467c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000467e:	6908                	ld	a0,16(a0)
    80004680:	00000097          	auipc	ra,0x0
    80004684:	3f6080e7          	jalr	1014(ra) # 80004a76 <piperead>
    80004688:	892a                	mv	s2,a0
    8000468a:	b7d5                	j	8000466e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000468c:	02451783          	lh	a5,36(a0)
    80004690:	03079693          	slli	a3,a5,0x30
    80004694:	92c1                	srli	a3,a3,0x30
    80004696:	4725                	li	a4,9
    80004698:	02d76863          	bltu	a4,a3,800046c8 <fileread+0xba>
    8000469c:	0792                	slli	a5,a5,0x4
    8000469e:	0001d717          	auipc	a4,0x1d
    800046a2:	31270713          	addi	a4,a4,786 # 800219b0 <devsw>
    800046a6:	97ba                	add	a5,a5,a4
    800046a8:	639c                	ld	a5,0(a5)
    800046aa:	c38d                	beqz	a5,800046cc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800046ac:	4505                	li	a0,1
    800046ae:	9782                	jalr	a5
    800046b0:	892a                	mv	s2,a0
    800046b2:	bf75                	j	8000466e <fileread+0x60>
    panic("fileread");
    800046b4:	00004517          	auipc	a0,0x4
    800046b8:	fd450513          	addi	a0,a0,-44 # 80008688 <syscalls+0x260>
    800046bc:	ffffc097          	auipc	ra,0xffffc
    800046c0:	e8a080e7          	jalr	-374(ra) # 80000546 <panic>
    return -1;
    800046c4:	597d                	li	s2,-1
    800046c6:	b765                	j	8000466e <fileread+0x60>
      return -1;
    800046c8:	597d                	li	s2,-1
    800046ca:	b755                	j	8000466e <fileread+0x60>
    800046cc:	597d                	li	s2,-1
    800046ce:	b745                	j	8000466e <fileread+0x60>

00000000800046d0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800046d0:	00954783          	lbu	a5,9(a0)
    800046d4:	14078563          	beqz	a5,8000481e <filewrite+0x14e>
{
    800046d8:	715d                	addi	sp,sp,-80
    800046da:	e486                	sd	ra,72(sp)
    800046dc:	e0a2                	sd	s0,64(sp)
    800046de:	fc26                	sd	s1,56(sp)
    800046e0:	f84a                	sd	s2,48(sp)
    800046e2:	f44e                	sd	s3,40(sp)
    800046e4:	f052                	sd	s4,32(sp)
    800046e6:	ec56                	sd	s5,24(sp)
    800046e8:	e85a                	sd	s6,16(sp)
    800046ea:	e45e                	sd	s7,8(sp)
    800046ec:	e062                	sd	s8,0(sp)
    800046ee:	0880                	addi	s0,sp,80
    800046f0:	892a                	mv	s2,a0
    800046f2:	8b2e                	mv	s6,a1
    800046f4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800046f6:	411c                	lw	a5,0(a0)
    800046f8:	4705                	li	a4,1
    800046fa:	02e78263          	beq	a5,a4,8000471e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046fe:	470d                	li	a4,3
    80004700:	02e78563          	beq	a5,a4,8000472a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004704:	4709                	li	a4,2
    80004706:	10e79463          	bne	a5,a4,8000480e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000470a:	0ec05e63          	blez	a2,80004806 <filewrite+0x136>
    int i = 0;
    8000470e:	4981                	li	s3,0
    80004710:	6b85                	lui	s7,0x1
    80004712:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004716:	6c05                	lui	s8,0x1
    80004718:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000471c:	a851                	j	800047b0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000471e:	6908                	ld	a0,16(a0)
    80004720:	00000097          	auipc	ra,0x0
    80004724:	254080e7          	jalr	596(ra) # 80004974 <pipewrite>
    80004728:	a85d                	j	800047de <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000472a:	02451783          	lh	a5,36(a0)
    8000472e:	03079693          	slli	a3,a5,0x30
    80004732:	92c1                	srli	a3,a3,0x30
    80004734:	4725                	li	a4,9
    80004736:	0ed76663          	bltu	a4,a3,80004822 <filewrite+0x152>
    8000473a:	0792                	slli	a5,a5,0x4
    8000473c:	0001d717          	auipc	a4,0x1d
    80004740:	27470713          	addi	a4,a4,628 # 800219b0 <devsw>
    80004744:	97ba                	add	a5,a5,a4
    80004746:	679c                	ld	a5,8(a5)
    80004748:	cff9                	beqz	a5,80004826 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000474a:	4505                	li	a0,1
    8000474c:	9782                	jalr	a5
    8000474e:	a841                	j	800047de <filewrite+0x10e>
    80004750:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004754:	00000097          	auipc	ra,0x0
    80004758:	8b2080e7          	jalr	-1870(ra) # 80004006 <begin_op>
      ilock(f->ip);
    8000475c:	01893503          	ld	a0,24(s2)
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	ee0080e7          	jalr	-288(ra) # 80003640 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004768:	8756                	mv	a4,s5
    8000476a:	02092683          	lw	a3,32(s2)
    8000476e:	01698633          	add	a2,s3,s6
    80004772:	4585                	li	a1,1
    80004774:	01893503          	ld	a0,24(s2)
    80004778:	fffff097          	auipc	ra,0xfffff
    8000477c:	272080e7          	jalr	626(ra) # 800039ea <writei>
    80004780:	84aa                	mv	s1,a0
    80004782:	02a05f63          	blez	a0,800047c0 <filewrite+0xf0>
        f->off += r;
    80004786:	02092783          	lw	a5,32(s2)
    8000478a:	9fa9                	addw	a5,a5,a0
    8000478c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004790:	01893503          	ld	a0,24(s2)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	f6e080e7          	jalr	-146(ra) # 80003702 <iunlock>
      end_op();
    8000479c:	00000097          	auipc	ra,0x0
    800047a0:	8e8080e7          	jalr	-1816(ra) # 80004084 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800047a4:	049a9963          	bne	s5,s1,800047f6 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800047a8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800047ac:	0349d663          	bge	s3,s4,800047d8 <filewrite+0x108>
      int n1 = n - i;
    800047b0:	413a04bb          	subw	s1,s4,s3
    800047b4:	0004879b          	sext.w	a5,s1
    800047b8:	f8fbdce3          	bge	s7,a5,80004750 <filewrite+0x80>
    800047bc:	84e2                	mv	s1,s8
    800047be:	bf49                	j	80004750 <filewrite+0x80>
      iunlock(f->ip);
    800047c0:	01893503          	ld	a0,24(s2)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	f3e080e7          	jalr	-194(ra) # 80003702 <iunlock>
      end_op();
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	8b8080e7          	jalr	-1864(ra) # 80004084 <end_op>
      if(r < 0)
    800047d4:	fc04d8e3          	bgez	s1,800047a4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800047d8:	8552                	mv	a0,s4
    800047da:	033a1863          	bne	s4,s3,8000480a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800047de:	60a6                	ld	ra,72(sp)
    800047e0:	6406                	ld	s0,64(sp)
    800047e2:	74e2                	ld	s1,56(sp)
    800047e4:	7942                	ld	s2,48(sp)
    800047e6:	79a2                	ld	s3,40(sp)
    800047e8:	7a02                	ld	s4,32(sp)
    800047ea:	6ae2                	ld	s5,24(sp)
    800047ec:	6b42                	ld	s6,16(sp)
    800047ee:	6ba2                	ld	s7,8(sp)
    800047f0:	6c02                	ld	s8,0(sp)
    800047f2:	6161                	addi	sp,sp,80
    800047f4:	8082                	ret
        panic("short filewrite");
    800047f6:	00004517          	auipc	a0,0x4
    800047fa:	ea250513          	addi	a0,a0,-350 # 80008698 <syscalls+0x270>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	d48080e7          	jalr	-696(ra) # 80000546 <panic>
    int i = 0;
    80004806:	4981                	li	s3,0
    80004808:	bfc1                	j	800047d8 <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000480a:	557d                	li	a0,-1
    8000480c:	bfc9                	j	800047de <filewrite+0x10e>
    panic("filewrite");
    8000480e:	00004517          	auipc	a0,0x4
    80004812:	e9a50513          	addi	a0,a0,-358 # 800086a8 <syscalls+0x280>
    80004816:	ffffc097          	auipc	ra,0xffffc
    8000481a:	d30080e7          	jalr	-720(ra) # 80000546 <panic>
    return -1;
    8000481e:	557d                	li	a0,-1
}
    80004820:	8082                	ret
      return -1;
    80004822:	557d                	li	a0,-1
    80004824:	bf6d                	j	800047de <filewrite+0x10e>
    80004826:	557d                	li	a0,-1
    80004828:	bf5d                	j	800047de <filewrite+0x10e>

000000008000482a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000482a:	7179                	addi	sp,sp,-48
    8000482c:	f406                	sd	ra,40(sp)
    8000482e:	f022                	sd	s0,32(sp)
    80004830:	ec26                	sd	s1,24(sp)
    80004832:	e84a                	sd	s2,16(sp)
    80004834:	e44e                	sd	s3,8(sp)
    80004836:	e052                	sd	s4,0(sp)
    80004838:	1800                	addi	s0,sp,48
    8000483a:	84aa                	mv	s1,a0
    8000483c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000483e:	0005b023          	sd	zero,0(a1)
    80004842:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004846:	00000097          	auipc	ra,0x0
    8000484a:	bd2080e7          	jalr	-1070(ra) # 80004418 <filealloc>
    8000484e:	e088                	sd	a0,0(s1)
    80004850:	c551                	beqz	a0,800048dc <pipealloc+0xb2>
    80004852:	00000097          	auipc	ra,0x0
    80004856:	bc6080e7          	jalr	-1082(ra) # 80004418 <filealloc>
    8000485a:	00aa3023          	sd	a0,0(s4)
    8000485e:	c92d                	beqz	a0,800048d0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	2b0080e7          	jalr	688(ra) # 80000b10 <kalloc>
    80004868:	892a                	mv	s2,a0
    8000486a:	c125                	beqz	a0,800048ca <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000486c:	4985                	li	s3,1
    8000486e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004872:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004876:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000487a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000487e:	00004597          	auipc	a1,0x4
    80004882:	e3a58593          	addi	a1,a1,-454 # 800086b8 <syscalls+0x290>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	2ea080e7          	jalr	746(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    8000488e:	609c                	ld	a5,0(s1)
    80004890:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004894:	609c                	ld	a5,0(s1)
    80004896:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000489a:	609c                	ld	a5,0(s1)
    8000489c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048a0:	609c                	ld	a5,0(s1)
    800048a2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048a6:	000a3783          	ld	a5,0(s4)
    800048aa:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048ae:	000a3783          	ld	a5,0(s4)
    800048b2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800048b6:	000a3783          	ld	a5,0(s4)
    800048ba:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800048be:	000a3783          	ld	a5,0(s4)
    800048c2:	0127b823          	sd	s2,16(a5)
  return 0;
    800048c6:	4501                	li	a0,0
    800048c8:	a025                	j	800048f0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800048ca:	6088                	ld	a0,0(s1)
    800048cc:	e501                	bnez	a0,800048d4 <pipealloc+0xaa>
    800048ce:	a039                	j	800048dc <pipealloc+0xb2>
    800048d0:	6088                	ld	a0,0(s1)
    800048d2:	c51d                	beqz	a0,80004900 <pipealloc+0xd6>
    fileclose(*f0);
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	c00080e7          	jalr	-1024(ra) # 800044d4 <fileclose>
  if(*f1)
    800048dc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800048e0:	557d                	li	a0,-1
  if(*f1)
    800048e2:	c799                	beqz	a5,800048f0 <pipealloc+0xc6>
    fileclose(*f1);
    800048e4:	853e                	mv	a0,a5
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	bee080e7          	jalr	-1042(ra) # 800044d4 <fileclose>
  return -1;
    800048ee:	557d                	li	a0,-1
}
    800048f0:	70a2                	ld	ra,40(sp)
    800048f2:	7402                	ld	s0,32(sp)
    800048f4:	64e2                	ld	s1,24(sp)
    800048f6:	6942                	ld	s2,16(sp)
    800048f8:	69a2                	ld	s3,8(sp)
    800048fa:	6a02                	ld	s4,0(sp)
    800048fc:	6145                	addi	sp,sp,48
    800048fe:	8082                	ret
  return -1;
    80004900:	557d                	li	a0,-1
    80004902:	b7fd                	j	800048f0 <pipealloc+0xc6>

0000000080004904 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004904:	1101                	addi	sp,sp,-32
    80004906:	ec06                	sd	ra,24(sp)
    80004908:	e822                	sd	s0,16(sp)
    8000490a:	e426                	sd	s1,8(sp)
    8000490c:	e04a                	sd	s2,0(sp)
    8000490e:	1000                	addi	s0,sp,32
    80004910:	84aa                	mv	s1,a0
    80004912:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004914:	ffffc097          	auipc	ra,0xffffc
    80004918:	2ec080e7          	jalr	748(ra) # 80000c00 <acquire>
  if(writable){
    8000491c:	02090d63          	beqz	s2,80004956 <pipeclose+0x52>
    pi->writeopen = 0;
    80004920:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004924:	21848513          	addi	a0,s1,536
    80004928:	ffffe097          	auipc	ra,0xffffe
    8000492c:	a66080e7          	jalr	-1434(ra) # 8000238e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004930:	2204b783          	ld	a5,544(s1)
    80004934:	eb95                	bnez	a5,80004968 <pipeclose+0x64>
    release(&pi->lock);
    80004936:	8526                	mv	a0,s1
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	37c080e7          	jalr	892(ra) # 80000cb4 <release>
    kfree((char*)pi);
    80004940:	8526                	mv	a0,s1
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	0d0080e7          	jalr	208(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    8000494a:	60e2                	ld	ra,24(sp)
    8000494c:	6442                	ld	s0,16(sp)
    8000494e:	64a2                	ld	s1,8(sp)
    80004950:	6902                	ld	s2,0(sp)
    80004952:	6105                	addi	sp,sp,32
    80004954:	8082                	ret
    pi->readopen = 0;
    80004956:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000495a:	21c48513          	addi	a0,s1,540
    8000495e:	ffffe097          	auipc	ra,0xffffe
    80004962:	a30080e7          	jalr	-1488(ra) # 8000238e <wakeup>
    80004966:	b7e9                	j	80004930 <pipeclose+0x2c>
    release(&pi->lock);
    80004968:	8526                	mv	a0,s1
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	34a080e7          	jalr	842(ra) # 80000cb4 <release>
}
    80004972:	bfe1                	j	8000494a <pipeclose+0x46>

0000000080004974 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004974:	711d                	addi	sp,sp,-96
    80004976:	ec86                	sd	ra,88(sp)
    80004978:	e8a2                	sd	s0,80(sp)
    8000497a:	e4a6                	sd	s1,72(sp)
    8000497c:	e0ca                	sd	s2,64(sp)
    8000497e:	fc4e                	sd	s3,56(sp)
    80004980:	f852                	sd	s4,48(sp)
    80004982:	f456                	sd	s5,40(sp)
    80004984:	f05a                	sd	s6,32(sp)
    80004986:	ec5e                	sd	s7,24(sp)
    80004988:	e862                	sd	s8,16(sp)
    8000498a:	1080                	addi	s0,sp,96
    8000498c:	84aa                	mv	s1,a0
    8000498e:	8b2e                	mv	s6,a1
    80004990:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004992:	ffffd097          	auipc	ra,0xffffd
    80004996:	068080e7          	jalr	104(ra) # 800019fa <myproc>
    8000499a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    8000499c:	8526                	mv	a0,s1
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	262080e7          	jalr	610(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    800049a6:	09505863          	blez	s5,80004a36 <pipewrite+0xc2>
    800049aa:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    800049ac:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800049b0:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049b4:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049b6:	2184a783          	lw	a5,536(s1)
    800049ba:	21c4a703          	lw	a4,540(s1)
    800049be:	2007879b          	addiw	a5,a5,512
    800049c2:	02f71b63          	bne	a4,a5,800049f8 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    800049c6:	2204a783          	lw	a5,544(s1)
    800049ca:	c3d9                	beqz	a5,80004a50 <pipewrite+0xdc>
    800049cc:	03092783          	lw	a5,48(s2)
    800049d0:	e3c1                	bnez	a5,80004a50 <pipewrite+0xdc>
      wakeup(&pi->nread);
    800049d2:	8552                	mv	a0,s4
    800049d4:	ffffe097          	auipc	ra,0xffffe
    800049d8:	9ba080e7          	jalr	-1606(ra) # 8000238e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800049dc:	85a6                	mv	a1,s1
    800049de:	854e                	mv	a0,s3
    800049e0:	ffffe097          	auipc	ra,0xffffe
    800049e4:	82e080e7          	jalr	-2002(ra) # 8000220e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    800049e8:	2184a783          	lw	a5,536(s1)
    800049ec:	21c4a703          	lw	a4,540(s1)
    800049f0:	2007879b          	addiw	a5,a5,512
    800049f4:	fcf709e3          	beq	a4,a5,800049c6 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049f8:	4685                	li	a3,1
    800049fa:	865a                	mv	a2,s6
    800049fc:	faf40593          	addi	a1,s0,-81
    80004a00:	05093503          	ld	a0,80(s2)
    80004a04:	ffffd097          	auipc	ra,0xffffd
    80004a08:	d52080e7          	jalr	-686(ra) # 80001756 <copyin>
    80004a0c:	03850663          	beq	a0,s8,80004a38 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a10:	21c4a783          	lw	a5,540(s1)
    80004a14:	0017871b          	addiw	a4,a5,1
    80004a18:	20e4ae23          	sw	a4,540(s1)
    80004a1c:	1ff7f793          	andi	a5,a5,511
    80004a20:	97a6                	add	a5,a5,s1
    80004a22:	faf44703          	lbu	a4,-81(s0)
    80004a26:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a2a:	2b85                	addiw	s7,s7,1
    80004a2c:	0b05                	addi	s6,s6,1
    80004a2e:	f97a94e3          	bne	s5,s7,800049b6 <pipewrite+0x42>
    80004a32:	8bd6                	mv	s7,s5
    80004a34:	a011                	j	80004a38 <pipewrite+0xc4>
    80004a36:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004a38:	21848513          	addi	a0,s1,536
    80004a3c:	ffffe097          	auipc	ra,0xffffe
    80004a40:	952080e7          	jalr	-1710(ra) # 8000238e <wakeup>
  release(&pi->lock);
    80004a44:	8526                	mv	a0,s1
    80004a46:	ffffc097          	auipc	ra,0xffffc
    80004a4a:	26e080e7          	jalr	622(ra) # 80000cb4 <release>
  return i;
    80004a4e:	a039                	j	80004a5c <pipewrite+0xe8>
        release(&pi->lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	262080e7          	jalr	610(ra) # 80000cb4 <release>
        return -1;
    80004a5a:	5bfd                	li	s7,-1
}
    80004a5c:	855e                	mv	a0,s7
    80004a5e:	60e6                	ld	ra,88(sp)
    80004a60:	6446                	ld	s0,80(sp)
    80004a62:	64a6                	ld	s1,72(sp)
    80004a64:	6906                	ld	s2,64(sp)
    80004a66:	79e2                	ld	s3,56(sp)
    80004a68:	7a42                	ld	s4,48(sp)
    80004a6a:	7aa2                	ld	s5,40(sp)
    80004a6c:	7b02                	ld	s6,32(sp)
    80004a6e:	6be2                	ld	s7,24(sp)
    80004a70:	6c42                	ld	s8,16(sp)
    80004a72:	6125                	addi	sp,sp,96
    80004a74:	8082                	ret

0000000080004a76 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004a76:	715d                	addi	sp,sp,-80
    80004a78:	e486                	sd	ra,72(sp)
    80004a7a:	e0a2                	sd	s0,64(sp)
    80004a7c:	fc26                	sd	s1,56(sp)
    80004a7e:	f84a                	sd	s2,48(sp)
    80004a80:	f44e                	sd	s3,40(sp)
    80004a82:	f052                	sd	s4,32(sp)
    80004a84:	ec56                	sd	s5,24(sp)
    80004a86:	e85a                	sd	s6,16(sp)
    80004a88:	0880                	addi	s0,sp,80
    80004a8a:	84aa                	mv	s1,a0
    80004a8c:	892e                	mv	s2,a1
    80004a8e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	f6a080e7          	jalr	-150(ra) # 800019fa <myproc>
    80004a98:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	164080e7          	jalr	356(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004aa4:	2184a703          	lw	a4,536(s1)
    80004aa8:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004aac:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ab0:	02f71463          	bne	a4,a5,80004ad8 <piperead+0x62>
    80004ab4:	2244a783          	lw	a5,548(s1)
    80004ab8:	c385                	beqz	a5,80004ad8 <piperead+0x62>
    if(pr->killed){
    80004aba:	030a2783          	lw	a5,48(s4)
    80004abe:	ebc9                	bnez	a5,80004b50 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ac0:	85a6                	mv	a1,s1
    80004ac2:	854e                	mv	a0,s3
    80004ac4:	ffffd097          	auipc	ra,0xffffd
    80004ac8:	74a080e7          	jalr	1866(ra) # 8000220e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004acc:	2184a703          	lw	a4,536(s1)
    80004ad0:	21c4a783          	lw	a5,540(s1)
    80004ad4:	fef700e3          	beq	a4,a5,80004ab4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ad8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ada:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004adc:	05505463          	blez	s5,80004b24 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004ae0:	2184a783          	lw	a5,536(s1)
    80004ae4:	21c4a703          	lw	a4,540(s1)
    80004ae8:	02f70e63          	beq	a4,a5,80004b24 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004aec:	0017871b          	addiw	a4,a5,1
    80004af0:	20e4ac23          	sw	a4,536(s1)
    80004af4:	1ff7f793          	andi	a5,a5,511
    80004af8:	97a6                	add	a5,a5,s1
    80004afa:	0187c783          	lbu	a5,24(a5)
    80004afe:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b02:	4685                	li	a3,1
    80004b04:	fbf40613          	addi	a2,s0,-65
    80004b08:	85ca                	mv	a1,s2
    80004b0a:	050a3503          	ld	a0,80(s4)
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	bbc080e7          	jalr	-1092(ra) # 800016ca <copyout>
    80004b16:	01650763          	beq	a0,s6,80004b24 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b1a:	2985                	addiw	s3,s3,1
    80004b1c:	0905                	addi	s2,s2,1
    80004b1e:	fd3a91e3          	bne	s5,s3,80004ae0 <piperead+0x6a>
    80004b22:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b24:	21c48513          	addi	a0,s1,540
    80004b28:	ffffe097          	auipc	ra,0xffffe
    80004b2c:	866080e7          	jalr	-1946(ra) # 8000238e <wakeup>
  release(&pi->lock);
    80004b30:	8526                	mv	a0,s1
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	182080e7          	jalr	386(ra) # 80000cb4 <release>
  return i;
}
    80004b3a:	854e                	mv	a0,s3
    80004b3c:	60a6                	ld	ra,72(sp)
    80004b3e:	6406                	ld	s0,64(sp)
    80004b40:	74e2                	ld	s1,56(sp)
    80004b42:	7942                	ld	s2,48(sp)
    80004b44:	79a2                	ld	s3,40(sp)
    80004b46:	7a02                	ld	s4,32(sp)
    80004b48:	6ae2                	ld	s5,24(sp)
    80004b4a:	6b42                	ld	s6,16(sp)
    80004b4c:	6161                	addi	sp,sp,80
    80004b4e:	8082                	ret
      release(&pi->lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	162080e7          	jalr	354(ra) # 80000cb4 <release>
      return -1;
    80004b5a:	59fd                	li	s3,-1
    80004b5c:	bff9                	j	80004b3a <piperead+0xc4>

0000000080004b5e <vmprint>:
#include "elf.h"


static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

void vmprint(pagetable_t pa){
    80004b5e:	7159                	addi	sp,sp,-112
    80004b60:	f486                	sd	ra,104(sp)
    80004b62:	f0a2                	sd	s0,96(sp)
    80004b64:	eca6                	sd	s1,88(sp)
    80004b66:	e8ca                	sd	s2,80(sp)
    80004b68:	e4ce                	sd	s3,72(sp)
    80004b6a:	e0d2                	sd	s4,64(sp)
    80004b6c:	fc56                	sd	s5,56(sp)
    80004b6e:	f85a                	sd	s6,48(sp)
    80004b70:	f45e                	sd	s7,40(sp)
    80004b72:	f062                	sd	s8,32(sp)
    80004b74:	ec66                	sd	s9,24(sp)
    80004b76:	e86a                	sd	s10,16(sp)
    80004b78:	e46e                	sd	s11,8(sp)
    80004b7a:	1880                	addi	s0,sp,112
    80004b7c:	8c2a                	mv	s8,a0
    printf("page table %p\n", pa);
    80004b7e:	85aa                	mv	a1,a0
    80004b80:	00004517          	auipc	a0,0x4
    80004b84:	b4050513          	addi	a0,a0,-1216 # 800086c0 <syscalls+0x298>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	a08080e7          	jalr	-1528(ra) # 80000590 <printf>
    for(int i = 0; i < 512; i++){
    80004b90:	4c81                	li	s9,0
    pte_t pte = pa[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004b92:	4b85                	li	s7,1
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      printf("||%d: pte %p pa %p\n",i ,pte, child);
      // vmprint((pagetable_t)child);
      
      for(int j = 0; j < 512; j++){
    80004b94:	4d01                	li	s10,0
        pte_t pte_c = ((pagetable_t)child)[j];
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
          uint64 child_c = PTE2PA(pte_c);
          printf("||||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004b96:	00004d97          	auipc	s11,0x4
    80004b9a:	b52d8d93          	addi	s11,s11,-1198 # 800086e8 <syscalls+0x2c0>
          for(int k = 0; k < 512; k++){
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
            // printf("||||||%d: pte %p\n",k ,pte_c_c);
            if((pte_c_c & PTE_V)){
              uint64 child_c_c = PTE2PA(pte_c_c);
              printf("||||||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004b9e:	00004b17          	auipc	s6,0x4
    80004ba2:	b62b0b13          	addi	s6,s6,-1182 # 80008700 <syscalls+0x2d8>
          for(int k = 0; k < 512; k++){
    80004ba6:	20000993          	li	s3,512
    80004baa:	a8b1                	j	80004c06 <vmprint+0xa8>
    80004bac:	2485                	addiw	s1,s1,1
    80004bae:	0921                	addi	s2,s2,8
    80004bb0:	03348163          	beq	s1,s3,80004bd2 <vmprint+0x74>
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
    80004bb4:	00093603          	ld	a2,0(s2)
            if((pte_c_c & PTE_V)){
    80004bb8:	00167793          	andi	a5,a2,1
    80004bbc:	dbe5                	beqz	a5,80004bac <vmprint+0x4e>
              uint64 child_c_c = PTE2PA(pte_c_c);
    80004bbe:	00a65693          	srli	a3,a2,0xa
              printf("||||||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004bc2:	06b2                	slli	a3,a3,0xc
    80004bc4:	85a6                	mv	a1,s1
    80004bc6:	855a                	mv	a0,s6
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	9c8080e7          	jalr	-1592(ra) # 80000590 <printf>
    80004bd0:	bff1                	j	80004bac <vmprint+0x4e>
      for(int j = 0; j < 512; j++){
    80004bd2:	2a05                	addiw	s4,s4,1
    80004bd4:	0aa1                	addi	s5,s5,8
    80004bd6:	033a0463          	beq	s4,s3,80004bfe <vmprint+0xa0>
        pte_t pte_c = ((pagetable_t)child)[j];
    80004bda:	000ab603          	ld	a2,0(s5)
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
    80004bde:	00f67793          	andi	a5,a2,15
    80004be2:	ff7798e3          	bne	a5,s7,80004bd2 <vmprint+0x74>
          uint64 child_c = PTE2PA(pte_c);
    80004be6:	00a65913          	srli	s2,a2,0xa
    80004bea:	0932                	slli	s2,s2,0xc
          printf("||||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004bec:	86ca                	mv	a3,s2
    80004bee:	85d2                	mv	a1,s4
    80004bf0:	856e                	mv	a0,s11
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	99e080e7          	jalr	-1634(ra) # 80000590 <printf>
          for(int k = 0; k < 512; k++){
    80004bfa:	84ea                	mv	s1,s10
    80004bfc:	bf65                	j	80004bb4 <vmprint+0x56>
    for(int i = 0; i < 512; i++){
    80004bfe:	2c85                	addiw	s9,s9,1 # 2001 <_entry-0x7fffdfff>
    80004c00:	0c21                	addi	s8,s8,8
    80004c02:	033c8763          	beq	s9,s3,80004c30 <vmprint+0xd2>
    pte_t pte = pa[i];
    80004c06:	000c3603          	ld	a2,0(s8)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004c0a:	00f67793          	andi	a5,a2,15
    80004c0e:	ff7798e3          	bne	a5,s7,80004bfe <vmprint+0xa0>
      uint64 child = PTE2PA(pte);
    80004c12:	00a65a93          	srli	s5,a2,0xa
    80004c16:	0ab2                	slli	s5,s5,0xc
      printf("||%d: pte %p pa %p\n",i ,pte, child);
    80004c18:	86d6                	mv	a3,s5
    80004c1a:	85e6                	mv	a1,s9
    80004c1c:	00004517          	auipc	a0,0x4
    80004c20:	ab450513          	addi	a0,a0,-1356 # 800086d0 <syscalls+0x2a8>
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	96c080e7          	jalr	-1684(ra) # 80000590 <printf>
      for(int j = 0; j < 512; j++){
    80004c2c:	8a6a                	mv	s4,s10
    80004c2e:	b775                	j	80004bda <vmprint+0x7c>
        }

      } 
    }
  }
}
    80004c30:	70a6                	ld	ra,104(sp)
    80004c32:	7406                	ld	s0,96(sp)
    80004c34:	64e6                	ld	s1,88(sp)
    80004c36:	6946                	ld	s2,80(sp)
    80004c38:	69a6                	ld	s3,72(sp)
    80004c3a:	6a06                	ld	s4,64(sp)
    80004c3c:	7ae2                	ld	s5,56(sp)
    80004c3e:	7b42                	ld	s6,48(sp)
    80004c40:	7ba2                	ld	s7,40(sp)
    80004c42:	7c02                	ld	s8,32(sp)
    80004c44:	6ce2                	ld	s9,24(sp)
    80004c46:	6d42                	ld	s10,16(sp)
    80004c48:	6da2                	ld	s11,8(sp)
    80004c4a:	6165                	addi	sp,sp,112
    80004c4c:	8082                	ret

0000000080004c4e <exec>:

int
exec(char *path, char **argv)
{
    80004c4e:	de010113          	addi	sp,sp,-544
    80004c52:	20113c23          	sd	ra,536(sp)
    80004c56:	20813823          	sd	s0,528(sp)
    80004c5a:	20913423          	sd	s1,520(sp)
    80004c5e:	21213023          	sd	s2,512(sp)
    80004c62:	ffce                	sd	s3,504(sp)
    80004c64:	fbd2                	sd	s4,496(sp)
    80004c66:	f7d6                	sd	s5,488(sp)
    80004c68:	f3da                	sd	s6,480(sp)
    80004c6a:	efde                	sd	s7,472(sp)
    80004c6c:	ebe2                	sd	s8,464(sp)
    80004c6e:	e7e6                	sd	s9,456(sp)
    80004c70:	e3ea                	sd	s10,448(sp)
    80004c72:	ff6e                	sd	s11,440(sp)
    80004c74:	1400                	addi	s0,sp,544
    80004c76:	892a                	mv	s2,a0
    80004c78:	dea43423          	sd	a0,-536(s0)
    80004c7c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	d7a080e7          	jalr	-646(ra) # 800019fa <myproc>
    80004c88:	84aa                	mv	s1,a0

  begin_op();
    80004c8a:	fffff097          	auipc	ra,0xfffff
    80004c8e:	37c080e7          	jalr	892(ra) # 80004006 <begin_op>

  if((ip = namei(path)) == 0){
    80004c92:	854a                	mv	a0,s2
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	162080e7          	jalr	354(ra) # 80003df6 <namei>
    80004c9c:	c93d                	beqz	a0,80004d12 <exec+0xc4>
    80004c9e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	9a0080e7          	jalr	-1632(ra) # 80003640 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ca8:	04000713          	li	a4,64
    80004cac:	4681                	li	a3,0
    80004cae:	e4840613          	addi	a2,s0,-440
    80004cb2:	4581                	li	a1,0
    80004cb4:	8556                	mv	a0,s5
    80004cb6:	fffff097          	auipc	ra,0xfffff
    80004cba:	c3e080e7          	jalr	-962(ra) # 800038f4 <readi>
    80004cbe:	04000793          	li	a5,64
    80004cc2:	00f51a63          	bne	a0,a5,80004cd6 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cc6:	e4842703          	lw	a4,-440(s0)
    80004cca:	464c47b7          	lui	a5,0x464c4
    80004cce:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cd2:	04f70663          	beq	a4,a5,80004d1e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cd6:	8556                	mv	a0,s5
    80004cd8:	fffff097          	auipc	ra,0xfffff
    80004cdc:	bca080e7          	jalr	-1078(ra) # 800038a2 <iunlockput>
    end_op();
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	3a4080e7          	jalr	932(ra) # 80004084 <end_op>
  }
  return -1;
    80004ce8:	557d                	li	a0,-1
}
    80004cea:	21813083          	ld	ra,536(sp)
    80004cee:	21013403          	ld	s0,528(sp)
    80004cf2:	20813483          	ld	s1,520(sp)
    80004cf6:	20013903          	ld	s2,512(sp)
    80004cfa:	79fe                	ld	s3,504(sp)
    80004cfc:	7a5e                	ld	s4,496(sp)
    80004cfe:	7abe                	ld	s5,488(sp)
    80004d00:	7b1e                	ld	s6,480(sp)
    80004d02:	6bfe                	ld	s7,472(sp)
    80004d04:	6c5e                	ld	s8,464(sp)
    80004d06:	6cbe                	ld	s9,456(sp)
    80004d08:	6d1e                	ld	s10,448(sp)
    80004d0a:	7dfa                	ld	s11,440(sp)
    80004d0c:	22010113          	addi	sp,sp,544
    80004d10:	8082                	ret
    end_op();
    80004d12:	fffff097          	auipc	ra,0xfffff
    80004d16:	372080e7          	jalr	882(ra) # 80004084 <end_op>
    return -1;
    80004d1a:	557d                	li	a0,-1
    80004d1c:	b7f9                	j	80004cea <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d1e:	8526                	mv	a0,s1
    80004d20:	ffffd097          	auipc	ra,0xffffd
    80004d24:	d9e080e7          	jalr	-610(ra) # 80001abe <proc_pagetable>
    80004d28:	8b2a                	mv	s6,a0
    80004d2a:	d555                	beqz	a0,80004cd6 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d2c:	e6842783          	lw	a5,-408(s0)
    80004d30:	e8045703          	lhu	a4,-384(s0)
    80004d34:	c735                	beqz	a4,80004da0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d36:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d38:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d3c:	6a05                	lui	s4,0x1
    80004d3e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d42:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004d46:	6d85                	lui	s11,0x1
    80004d48:	7d7d                	lui	s10,0xfffff
    80004d4a:	a4b9                	j	80004f98 <exec+0x34a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d4c:	00004517          	auipc	a0,0x4
    80004d50:	9cc50513          	addi	a0,a0,-1588 # 80008718 <syscalls+0x2f0>
    80004d54:	ffffb097          	auipc	ra,0xffffb
    80004d58:	7f2080e7          	jalr	2034(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d5c:	874a                	mv	a4,s2
    80004d5e:	009c86bb          	addw	a3,s9,s1
    80004d62:	4581                	li	a1,0
    80004d64:	8556                	mv	a0,s5
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	b8e080e7          	jalr	-1138(ra) # 800038f4 <readi>
    80004d6e:	2501                	sext.w	a0,a0
    80004d70:	1ca91463          	bne	s2,a0,80004f38 <exec+0x2ea>
  for(i = 0; i < sz; i += PGSIZE){
    80004d74:	009d84bb          	addw	s1,s11,s1
    80004d78:	013d09bb          	addw	s3,s10,s3
    80004d7c:	1f74fe63          	bgeu	s1,s7,80004f78 <exec+0x32a>
    pa = walkaddr(pagetable, va + i);
    80004d80:	02049593          	slli	a1,s1,0x20
    80004d84:	9181                	srli	a1,a1,0x20
    80004d86:	95e2                	add	a1,a1,s8
    80004d88:	855a                	mv	a0,s6
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	308080e7          	jalr	776(ra) # 80001092 <walkaddr>
    80004d92:	862a                	mv	a2,a0
    if(pa == 0)
    80004d94:	dd45                	beqz	a0,80004d4c <exec+0xfe>
      n = PGSIZE;
    80004d96:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d98:	fd49f2e3          	bgeu	s3,s4,80004d5c <exec+0x10e>
      n = sz - i;
    80004d9c:	894e                	mv	s2,s3
    80004d9e:	bf7d                	j	80004d5c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004da0:	4481                	li	s1,0
  iunlockput(ip);
    80004da2:	8556                	mv	a0,s5
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	afe080e7          	jalr	-1282(ra) # 800038a2 <iunlockput>
  end_op();
    80004dac:	fffff097          	auipc	ra,0xfffff
    80004db0:	2d8080e7          	jalr	728(ra) # 80004084 <end_op>
  p = myproc();
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	c46080e7          	jalr	-954(ra) # 800019fa <myproc>
    80004dbc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dbe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dc2:	6785                	lui	a5,0x1
    80004dc4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004dc6:	97a6                	add	a5,a5,s1
    80004dc8:	777d                	lui	a4,0xfffff
    80004dca:	8ff9                	and	a5,a5,a4
    80004dcc:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dd0:	6609                	lui	a2,0x2
    80004dd2:	963e                	add	a2,a2,a5
    80004dd4:	85be                	mv	a1,a5
    80004dd6:	855a                	mv	a0,s6
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	69e080e7          	jalr	1694(ra) # 80001476 <uvmalloc>
    80004de0:	8c2a                	mv	s8,a0
  ip = 0;
    80004de2:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004de4:	14050a63          	beqz	a0,80004f38 <exec+0x2ea>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004de8:	75f9                	lui	a1,0xffffe
    80004dea:	95aa                	add	a1,a1,a0
    80004dec:	855a                	mv	a0,s6
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	8aa080e7          	jalr	-1878(ra) # 80001698 <uvmclear>
  stackbase = sp - PGSIZE;
    80004df6:	7afd                	lui	s5,0xfffff
    80004df8:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dfa:	df043783          	ld	a5,-528(s0)
    80004dfe:	6388                	ld	a0,0(a5)
    80004e00:	c925                	beqz	a0,80004e70 <exec+0x222>
    80004e02:	e8840993          	addi	s3,s0,-376
    80004e06:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e0a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e0c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	072080e7          	jalr	114(ra) # 80000e80 <strlen>
    80004e16:	0015079b          	addiw	a5,a0,1
    80004e1a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e1e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e22:	13596f63          	bltu	s2,s5,80004f60 <exec+0x312>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e26:	df043d83          	ld	s11,-528(s0)
    80004e2a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e2e:	8552                	mv	a0,s4
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	050080e7          	jalr	80(ra) # 80000e80 <strlen>
    80004e38:	0015069b          	addiw	a3,a0,1
    80004e3c:	8652                	mv	a2,s4
    80004e3e:	85ca                	mv	a1,s2
    80004e40:	855a                	mv	a0,s6
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	888080e7          	jalr	-1912(ra) # 800016ca <copyout>
    80004e4a:	10054f63          	bltz	a0,80004f68 <exec+0x31a>
    ustack[argc] = sp;
    80004e4e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e52:	0485                	addi	s1,s1,1
    80004e54:	008d8793          	addi	a5,s11,8
    80004e58:	def43823          	sd	a5,-528(s0)
    80004e5c:	008db503          	ld	a0,8(s11)
    80004e60:	c911                	beqz	a0,80004e74 <exec+0x226>
    if(argc >= MAXARG)
    80004e62:	09a1                	addi	s3,s3,8
    80004e64:	fb3c95e3          	bne	s9,s3,80004e0e <exec+0x1c0>
  sz = sz1;
    80004e68:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e6c:	4a81                	li	s5,0
    80004e6e:	a0e9                	j	80004f38 <exec+0x2ea>
  sp = sz;
    80004e70:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e72:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e74:	00349793          	slli	a5,s1,0x3
    80004e78:	f9078793          	addi	a5,a5,-112
    80004e7c:	97a2                	add	a5,a5,s0
    80004e7e:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e82:	00148693          	addi	a3,s1,1
    80004e86:	068e                	slli	a3,a3,0x3
    80004e88:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e8c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e90:	01597663          	bgeu	s2,s5,80004e9c <exec+0x24e>
  sz = sz1;
    80004e94:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e98:	4a81                	li	s5,0
    80004e9a:	a879                	j	80004f38 <exec+0x2ea>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e9c:	e8840613          	addi	a2,s0,-376
    80004ea0:	85ca                	mv	a1,s2
    80004ea2:	855a                	mv	a0,s6
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	826080e7          	jalr	-2010(ra) # 800016ca <copyout>
    80004eac:	0c054263          	bltz	a0,80004f70 <exec+0x322>
  p->trapframe->a1 = sp;
    80004eb0:	058bb783          	ld	a5,88(s7)
    80004eb4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eb8:	de843783          	ld	a5,-536(s0)
    80004ebc:	0007c703          	lbu	a4,0(a5)
    80004ec0:	cf11                	beqz	a4,80004edc <exec+0x28e>
    80004ec2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ec4:	02f00693          	li	a3,47
    80004ec8:	a039                	j	80004ed6 <exec+0x288>
      last = s+1;
    80004eca:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004ece:	0785                	addi	a5,a5,1
    80004ed0:	fff7c703          	lbu	a4,-1(a5)
    80004ed4:	c701                	beqz	a4,80004edc <exec+0x28e>
    if(*s == '/')
    80004ed6:	fed71ce3          	bne	a4,a3,80004ece <exec+0x280>
    80004eda:	bfc5                	j	80004eca <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004edc:	4641                	li	a2,16
    80004ede:	de843583          	ld	a1,-536(s0)
    80004ee2:	158b8513          	addi	a0,s7,344
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	f68080e7          	jalr	-152(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    80004eee:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004ef2:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004ef6:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004efa:	058bb783          	ld	a5,88(s7)
    80004efe:	e6043703          	ld	a4,-416(s0)
    80004f02:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f04:	058bb783          	ld	a5,88(s7)
    80004f08:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f0c:	85ea                	mv	a1,s10
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	c4c080e7          	jalr	-948(ra) # 80001b5a <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable); 
    80004f16:	038ba703          	lw	a4,56(s7)
    80004f1a:	4785                	li	a5,1
    80004f1c:	00f70563          	beq	a4,a5,80004f26 <exec+0x2d8>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f20:	0004851b          	sext.w	a0,s1
    80004f24:	b3d9                	j	80004cea <exec+0x9c>
  if(p->pid==1) vmprint(p->pagetable); 
    80004f26:	050bb503          	ld	a0,80(s7)
    80004f2a:	00000097          	auipc	ra,0x0
    80004f2e:	c34080e7          	jalr	-972(ra) # 80004b5e <vmprint>
    80004f32:	b7fd                	j	80004f20 <exec+0x2d2>
    80004f34:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f38:	df843583          	ld	a1,-520(s0)
    80004f3c:	855a                	mv	a0,s6
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	c1c080e7          	jalr	-996(ra) # 80001b5a <proc_freepagetable>
  if(ip){
    80004f46:	d80a98e3          	bnez	s5,80004cd6 <exec+0x88>
  return -1;
    80004f4a:	557d                	li	a0,-1
    80004f4c:	bb79                	j	80004cea <exec+0x9c>
    80004f4e:	de943c23          	sd	s1,-520(s0)
    80004f52:	b7dd                	j	80004f38 <exec+0x2ea>
    80004f54:	de943c23          	sd	s1,-520(s0)
    80004f58:	b7c5                	j	80004f38 <exec+0x2ea>
    80004f5a:	de943c23          	sd	s1,-520(s0)
    80004f5e:	bfe9                	j	80004f38 <exec+0x2ea>
  sz = sz1;
    80004f60:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f64:	4a81                	li	s5,0
    80004f66:	bfc9                	j	80004f38 <exec+0x2ea>
  sz = sz1;
    80004f68:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f6c:	4a81                	li	s5,0
    80004f6e:	b7e9                	j	80004f38 <exec+0x2ea>
  sz = sz1;
    80004f70:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f74:	4a81                	li	s5,0
    80004f76:	b7c9                	j	80004f38 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f78:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7c:	e0843783          	ld	a5,-504(s0)
    80004f80:	0017869b          	addiw	a3,a5,1
    80004f84:	e0d43423          	sd	a3,-504(s0)
    80004f88:	e0043783          	ld	a5,-512(s0)
    80004f8c:	0387879b          	addiw	a5,a5,56
    80004f90:	e8045703          	lhu	a4,-384(s0)
    80004f94:	e0e6d7e3          	bge	a3,a4,80004da2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f98:	2781                	sext.w	a5,a5
    80004f9a:	e0f43023          	sd	a5,-512(s0)
    80004f9e:	03800713          	li	a4,56
    80004fa2:	86be                	mv	a3,a5
    80004fa4:	e1040613          	addi	a2,s0,-496
    80004fa8:	4581                	li	a1,0
    80004faa:	8556                	mv	a0,s5
    80004fac:	fffff097          	auipc	ra,0xfffff
    80004fb0:	948080e7          	jalr	-1720(ra) # 800038f4 <readi>
    80004fb4:	03800793          	li	a5,56
    80004fb8:	f6f51ee3          	bne	a0,a5,80004f34 <exec+0x2e6>
    if(ph.type != ELF_PROG_LOAD)
    80004fbc:	e1042783          	lw	a5,-496(s0)
    80004fc0:	4705                	li	a4,1
    80004fc2:	fae79de3          	bne	a5,a4,80004f7c <exec+0x32e>
    if(ph.memsz < ph.filesz)
    80004fc6:	e3843603          	ld	a2,-456(s0)
    80004fca:	e3043783          	ld	a5,-464(s0)
    80004fce:	f8f660e3          	bltu	a2,a5,80004f4e <exec+0x300>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fd2:	e2043783          	ld	a5,-480(s0)
    80004fd6:	963e                	add	a2,a2,a5
    80004fd8:	f6f66ee3          	bltu	a2,a5,80004f54 <exec+0x306>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fdc:	85a6                	mv	a1,s1
    80004fde:	855a                	mv	a0,s6
    80004fe0:	ffffc097          	auipc	ra,0xffffc
    80004fe4:	496080e7          	jalr	1174(ra) # 80001476 <uvmalloc>
    80004fe8:	dea43c23          	sd	a0,-520(s0)
    80004fec:	d53d                	beqz	a0,80004f5a <exec+0x30c>
    if(ph.vaddr % PGSIZE != 0)
    80004fee:	e2043c03          	ld	s8,-480(s0)
    80004ff2:	de043783          	ld	a5,-544(s0)
    80004ff6:	00fc77b3          	and	a5,s8,a5
    80004ffa:	ff9d                	bnez	a5,80004f38 <exec+0x2ea>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ffc:	e1842c83          	lw	s9,-488(s0)
    80005000:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005004:	f60b8ae3          	beqz	s7,80004f78 <exec+0x32a>
    80005008:	89de                	mv	s3,s7
    8000500a:	4481                	li	s1,0
    8000500c:	bb95                	j	80004d80 <exec+0x132>

000000008000500e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000500e:	7179                	addi	sp,sp,-48
    80005010:	f406                	sd	ra,40(sp)
    80005012:	f022                	sd	s0,32(sp)
    80005014:	ec26                	sd	s1,24(sp)
    80005016:	e84a                	sd	s2,16(sp)
    80005018:	1800                	addi	s0,sp,48
    8000501a:	892e                	mv	s2,a1
    8000501c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000501e:	fdc40593          	addi	a1,s0,-36
    80005022:	ffffe097          	auipc	ra,0xffffe
    80005026:	a94080e7          	jalr	-1388(ra) # 80002ab6 <argint>
    8000502a:	04054063          	bltz	a0,8000506a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000502e:	fdc42703          	lw	a4,-36(s0)
    80005032:	47bd                	li	a5,15
    80005034:	02e7ed63          	bltu	a5,a4,8000506e <argfd+0x60>
    80005038:	ffffd097          	auipc	ra,0xffffd
    8000503c:	9c2080e7          	jalr	-1598(ra) # 800019fa <myproc>
    80005040:	fdc42703          	lw	a4,-36(s0)
    80005044:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd7ffa>
    80005048:	078e                	slli	a5,a5,0x3
    8000504a:	953e                	add	a0,a0,a5
    8000504c:	611c                	ld	a5,0(a0)
    8000504e:	c395                	beqz	a5,80005072 <argfd+0x64>
    return -1;
  if(pfd)
    80005050:	00090463          	beqz	s2,80005058 <argfd+0x4a>
    *pfd = fd;
    80005054:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005058:	4501                	li	a0,0
  if(pf)
    8000505a:	c091                	beqz	s1,8000505e <argfd+0x50>
    *pf = f;
    8000505c:	e09c                	sd	a5,0(s1)
}
    8000505e:	70a2                	ld	ra,40(sp)
    80005060:	7402                	ld	s0,32(sp)
    80005062:	64e2                	ld	s1,24(sp)
    80005064:	6942                	ld	s2,16(sp)
    80005066:	6145                	addi	sp,sp,48
    80005068:	8082                	ret
    return -1;
    8000506a:	557d                	li	a0,-1
    8000506c:	bfcd                	j	8000505e <argfd+0x50>
    return -1;
    8000506e:	557d                	li	a0,-1
    80005070:	b7fd                	j	8000505e <argfd+0x50>
    80005072:	557d                	li	a0,-1
    80005074:	b7ed                	j	8000505e <argfd+0x50>

0000000080005076 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005076:	1101                	addi	sp,sp,-32
    80005078:	ec06                	sd	ra,24(sp)
    8000507a:	e822                	sd	s0,16(sp)
    8000507c:	e426                	sd	s1,8(sp)
    8000507e:	1000                	addi	s0,sp,32
    80005080:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	978080e7          	jalr	-1672(ra) # 800019fa <myproc>
    8000508a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000508c:	0d050793          	addi	a5,a0,208
    80005090:	4501                	li	a0,0
    80005092:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005094:	6398                	ld	a4,0(a5)
    80005096:	cb19                	beqz	a4,800050ac <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005098:	2505                	addiw	a0,a0,1
    8000509a:	07a1                	addi	a5,a5,8
    8000509c:	fed51ce3          	bne	a0,a3,80005094 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050a0:	557d                	li	a0,-1
}
    800050a2:	60e2                	ld	ra,24(sp)
    800050a4:	6442                	ld	s0,16(sp)
    800050a6:	64a2                	ld	s1,8(sp)
    800050a8:	6105                	addi	sp,sp,32
    800050aa:	8082                	ret
      p->ofile[fd] = f;
    800050ac:	01a50793          	addi	a5,a0,26
    800050b0:	078e                	slli	a5,a5,0x3
    800050b2:	963e                	add	a2,a2,a5
    800050b4:	e204                	sd	s1,0(a2)
      return fd;
    800050b6:	b7f5                	j	800050a2 <fdalloc+0x2c>

00000000800050b8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b8:	715d                	addi	sp,sp,-80
    800050ba:	e486                	sd	ra,72(sp)
    800050bc:	e0a2                	sd	s0,64(sp)
    800050be:	fc26                	sd	s1,56(sp)
    800050c0:	f84a                	sd	s2,48(sp)
    800050c2:	f44e                	sd	s3,40(sp)
    800050c4:	f052                	sd	s4,32(sp)
    800050c6:	ec56                	sd	s5,24(sp)
    800050c8:	0880                	addi	s0,sp,80
    800050ca:	89ae                	mv	s3,a1
    800050cc:	8ab2                	mv	s5,a2
    800050ce:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050d0:	fb040593          	addi	a1,s0,-80
    800050d4:	fffff097          	auipc	ra,0xfffff
    800050d8:	d40080e7          	jalr	-704(ra) # 80003e14 <nameiparent>
    800050dc:	892a                	mv	s2,a0
    800050de:	12050e63          	beqz	a0,8000521a <create+0x162>
    return 0;

  ilock(dp);
    800050e2:	ffffe097          	auipc	ra,0xffffe
    800050e6:	55e080e7          	jalr	1374(ra) # 80003640 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050ea:	4601                	li	a2,0
    800050ec:	fb040593          	addi	a1,s0,-80
    800050f0:	854a                	mv	a0,s2
    800050f2:	fffff097          	auipc	ra,0xfffff
    800050f6:	a2c080e7          	jalr	-1492(ra) # 80003b1e <dirlookup>
    800050fa:	84aa                	mv	s1,a0
    800050fc:	c921                	beqz	a0,8000514c <create+0x94>
    iunlockput(dp);
    800050fe:	854a                	mv	a0,s2
    80005100:	ffffe097          	auipc	ra,0xffffe
    80005104:	7a2080e7          	jalr	1954(ra) # 800038a2 <iunlockput>
    ilock(ip);
    80005108:	8526                	mv	a0,s1
    8000510a:	ffffe097          	auipc	ra,0xffffe
    8000510e:	536080e7          	jalr	1334(ra) # 80003640 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005112:	2981                	sext.w	s3,s3
    80005114:	4789                	li	a5,2
    80005116:	02f99463          	bne	s3,a5,8000513e <create+0x86>
    8000511a:	0444d783          	lhu	a5,68(s1)
    8000511e:	37f9                	addiw	a5,a5,-2
    80005120:	17c2                	slli	a5,a5,0x30
    80005122:	93c1                	srli	a5,a5,0x30
    80005124:	4705                	li	a4,1
    80005126:	00f76c63          	bltu	a4,a5,8000513e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000512a:	8526                	mv	a0,s1
    8000512c:	60a6                	ld	ra,72(sp)
    8000512e:	6406                	ld	s0,64(sp)
    80005130:	74e2                	ld	s1,56(sp)
    80005132:	7942                	ld	s2,48(sp)
    80005134:	79a2                	ld	s3,40(sp)
    80005136:	7a02                	ld	s4,32(sp)
    80005138:	6ae2                	ld	s5,24(sp)
    8000513a:	6161                	addi	sp,sp,80
    8000513c:	8082                	ret
    iunlockput(ip);
    8000513e:	8526                	mv	a0,s1
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	762080e7          	jalr	1890(ra) # 800038a2 <iunlockput>
    return 0;
    80005148:	4481                	li	s1,0
    8000514a:	b7c5                	j	8000512a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000514c:	85ce                	mv	a1,s3
    8000514e:	00092503          	lw	a0,0(s2)
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	354080e7          	jalr	852(ra) # 800034a6 <ialloc>
    8000515a:	84aa                	mv	s1,a0
    8000515c:	c521                	beqz	a0,800051a4 <create+0xec>
  ilock(ip);
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	4e2080e7          	jalr	1250(ra) # 80003640 <ilock>
  ip->major = major;
    80005166:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000516a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000516e:	4a05                	li	s4,1
    80005170:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005174:	8526                	mv	a0,s1
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	3fe080e7          	jalr	1022(ra) # 80003574 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000517e:	2981                	sext.w	s3,s3
    80005180:	03498a63          	beq	s3,s4,800051b4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005184:	40d0                	lw	a2,4(s1)
    80005186:	fb040593          	addi	a1,s0,-80
    8000518a:	854a                	mv	a0,s2
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	ba8080e7          	jalr	-1112(ra) # 80003d34 <dirlink>
    80005194:	06054b63          	bltz	a0,8000520a <create+0x152>
  iunlockput(dp);
    80005198:	854a                	mv	a0,s2
    8000519a:	ffffe097          	auipc	ra,0xffffe
    8000519e:	708080e7          	jalr	1800(ra) # 800038a2 <iunlockput>
  return ip;
    800051a2:	b761                	j	8000512a <create+0x72>
    panic("create: ialloc");
    800051a4:	00003517          	auipc	a0,0x3
    800051a8:	59450513          	addi	a0,a0,1428 # 80008738 <syscalls+0x310>
    800051ac:	ffffb097          	auipc	ra,0xffffb
    800051b0:	39a080e7          	jalr	922(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    800051b4:	04a95783          	lhu	a5,74(s2)
    800051b8:	2785                	addiw	a5,a5,1
    800051ba:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051be:	854a                	mv	a0,s2
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	3b4080e7          	jalr	948(ra) # 80003574 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c8:	40d0                	lw	a2,4(s1)
    800051ca:	00003597          	auipc	a1,0x3
    800051ce:	57e58593          	addi	a1,a1,1406 # 80008748 <syscalls+0x320>
    800051d2:	8526                	mv	a0,s1
    800051d4:	fffff097          	auipc	ra,0xfffff
    800051d8:	b60080e7          	jalr	-1184(ra) # 80003d34 <dirlink>
    800051dc:	00054f63          	bltz	a0,800051fa <create+0x142>
    800051e0:	00492603          	lw	a2,4(s2)
    800051e4:	00003597          	auipc	a1,0x3
    800051e8:	56c58593          	addi	a1,a1,1388 # 80008750 <syscalls+0x328>
    800051ec:	8526                	mv	a0,s1
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	b46080e7          	jalr	-1210(ra) # 80003d34 <dirlink>
    800051f6:	f80557e3          	bgez	a0,80005184 <create+0xcc>
      panic("create dots");
    800051fa:	00003517          	auipc	a0,0x3
    800051fe:	55e50513          	addi	a0,a0,1374 # 80008758 <syscalls+0x330>
    80005202:	ffffb097          	auipc	ra,0xffffb
    80005206:	344080e7          	jalr	836(ra) # 80000546 <panic>
    panic("create: dirlink");
    8000520a:	00003517          	auipc	a0,0x3
    8000520e:	55e50513          	addi	a0,a0,1374 # 80008768 <syscalls+0x340>
    80005212:	ffffb097          	auipc	ra,0xffffb
    80005216:	334080e7          	jalr	820(ra) # 80000546 <panic>
    return 0;
    8000521a:	84aa                	mv	s1,a0
    8000521c:	b739                	j	8000512a <create+0x72>

000000008000521e <sys_dup>:
{
    8000521e:	7179                	addi	sp,sp,-48
    80005220:	f406                	sd	ra,40(sp)
    80005222:	f022                	sd	s0,32(sp)
    80005224:	ec26                	sd	s1,24(sp)
    80005226:	e84a                	sd	s2,16(sp)
    80005228:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000522a:	fd840613          	addi	a2,s0,-40
    8000522e:	4581                	li	a1,0
    80005230:	4501                	li	a0,0
    80005232:	00000097          	auipc	ra,0x0
    80005236:	ddc080e7          	jalr	-548(ra) # 8000500e <argfd>
    return -1;
    8000523a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000523c:	02054363          	bltz	a0,80005262 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005240:	fd843903          	ld	s2,-40(s0)
    80005244:	854a                	mv	a0,s2
    80005246:	00000097          	auipc	ra,0x0
    8000524a:	e30080e7          	jalr	-464(ra) # 80005076 <fdalloc>
    8000524e:	84aa                	mv	s1,a0
    return -1;
    80005250:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005252:	00054863          	bltz	a0,80005262 <sys_dup+0x44>
  filedup(f);
    80005256:	854a                	mv	a0,s2
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	22a080e7          	jalr	554(ra) # 80004482 <filedup>
  return fd;
    80005260:	87a6                	mv	a5,s1
}
    80005262:	853e                	mv	a0,a5
    80005264:	70a2                	ld	ra,40(sp)
    80005266:	7402                	ld	s0,32(sp)
    80005268:	64e2                	ld	s1,24(sp)
    8000526a:	6942                	ld	s2,16(sp)
    8000526c:	6145                	addi	sp,sp,48
    8000526e:	8082                	ret

0000000080005270 <sys_read>:
{
    80005270:	7179                	addi	sp,sp,-48
    80005272:	f406                	sd	ra,40(sp)
    80005274:	f022                	sd	s0,32(sp)
    80005276:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005278:	fe840613          	addi	a2,s0,-24
    8000527c:	4581                	li	a1,0
    8000527e:	4501                	li	a0,0
    80005280:	00000097          	auipc	ra,0x0
    80005284:	d8e080e7          	jalr	-626(ra) # 8000500e <argfd>
    return -1;
    80005288:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528a:	04054163          	bltz	a0,800052cc <sys_read+0x5c>
    8000528e:	fe440593          	addi	a1,s0,-28
    80005292:	4509                	li	a0,2
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	822080e7          	jalr	-2014(ra) # 80002ab6 <argint>
    return -1;
    8000529c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000529e:	02054763          	bltz	a0,800052cc <sys_read+0x5c>
    800052a2:	fd840593          	addi	a1,s0,-40
    800052a6:	4505                	li	a0,1
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	830080e7          	jalr	-2000(ra) # 80002ad8 <argaddr>
    return -1;
    800052b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b2:	00054d63          	bltz	a0,800052cc <sys_read+0x5c>
  return fileread(f, p, n);
    800052b6:	fe442603          	lw	a2,-28(s0)
    800052ba:	fd843583          	ld	a1,-40(s0)
    800052be:	fe843503          	ld	a0,-24(s0)
    800052c2:	fffff097          	auipc	ra,0xfffff
    800052c6:	34c080e7          	jalr	844(ra) # 8000460e <fileread>
    800052ca:	87aa                	mv	a5,a0
}
    800052cc:	853e                	mv	a0,a5
    800052ce:	70a2                	ld	ra,40(sp)
    800052d0:	7402                	ld	s0,32(sp)
    800052d2:	6145                	addi	sp,sp,48
    800052d4:	8082                	ret

00000000800052d6 <sys_write>:
{
    800052d6:	7179                	addi	sp,sp,-48
    800052d8:	f406                	sd	ra,40(sp)
    800052da:	f022                	sd	s0,32(sp)
    800052dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052de:	fe840613          	addi	a2,s0,-24
    800052e2:	4581                	li	a1,0
    800052e4:	4501                	li	a0,0
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	d28080e7          	jalr	-728(ra) # 8000500e <argfd>
    return -1;
    800052ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f0:	04054163          	bltz	a0,80005332 <sys_write+0x5c>
    800052f4:	fe440593          	addi	a1,s0,-28
    800052f8:	4509                	li	a0,2
    800052fa:	ffffd097          	auipc	ra,0xffffd
    800052fe:	7bc080e7          	jalr	1980(ra) # 80002ab6 <argint>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005304:	02054763          	bltz	a0,80005332 <sys_write+0x5c>
    80005308:	fd840593          	addi	a1,s0,-40
    8000530c:	4505                	li	a0,1
    8000530e:	ffffd097          	auipc	ra,0xffffd
    80005312:	7ca080e7          	jalr	1994(ra) # 80002ad8 <argaddr>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005318:	00054d63          	bltz	a0,80005332 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000531c:	fe442603          	lw	a2,-28(s0)
    80005320:	fd843583          	ld	a1,-40(s0)
    80005324:	fe843503          	ld	a0,-24(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	3a8080e7          	jalr	936(ra) # 800046d0 <filewrite>
    80005330:	87aa                	mv	a5,a0
}
    80005332:	853e                	mv	a0,a5
    80005334:	70a2                	ld	ra,40(sp)
    80005336:	7402                	ld	s0,32(sp)
    80005338:	6145                	addi	sp,sp,48
    8000533a:	8082                	ret

000000008000533c <sys_close>:
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005344:	fe040613          	addi	a2,s0,-32
    80005348:	fec40593          	addi	a1,s0,-20
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	cc0080e7          	jalr	-832(ra) # 8000500e <argfd>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005358:	02054463          	bltz	a0,80005380 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	69e080e7          	jalr	1694(ra) # 800019fa <myproc>
    80005364:	fec42783          	lw	a5,-20(s0)
    80005368:	07e9                	addi	a5,a5,26
    8000536a:	078e                	slli	a5,a5,0x3
    8000536c:	953e                	add	a0,a0,a5
    8000536e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005372:	fe043503          	ld	a0,-32(s0)
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	15e080e7          	jalr	350(ra) # 800044d4 <fileclose>
  return 0;
    8000537e:	4781                	li	a5,0
}
    80005380:	853e                	mv	a0,a5
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	6105                	addi	sp,sp,32
    80005388:	8082                	ret

000000008000538a <sys_fstat>:
{
    8000538a:	1101                	addi	sp,sp,-32
    8000538c:	ec06                	sd	ra,24(sp)
    8000538e:	e822                	sd	s0,16(sp)
    80005390:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005392:	fe840613          	addi	a2,s0,-24
    80005396:	4581                	li	a1,0
    80005398:	4501                	li	a0,0
    8000539a:	00000097          	auipc	ra,0x0
    8000539e:	c74080e7          	jalr	-908(ra) # 8000500e <argfd>
    return -1;
    800053a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053a4:	02054563          	bltz	a0,800053ce <sys_fstat+0x44>
    800053a8:	fe040593          	addi	a1,s0,-32
    800053ac:	4505                	li	a0,1
    800053ae:	ffffd097          	auipc	ra,0xffffd
    800053b2:	72a080e7          	jalr	1834(ra) # 80002ad8 <argaddr>
    return -1;
    800053b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b8:	00054b63          	bltz	a0,800053ce <sys_fstat+0x44>
  return filestat(f, st);
    800053bc:	fe043583          	ld	a1,-32(s0)
    800053c0:	fe843503          	ld	a0,-24(s0)
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	1d8080e7          	jalr	472(ra) # 8000459c <filestat>
    800053cc:	87aa                	mv	a5,a0
}
    800053ce:	853e                	mv	a0,a5
    800053d0:	60e2                	ld	ra,24(sp)
    800053d2:	6442                	ld	s0,16(sp)
    800053d4:	6105                	addi	sp,sp,32
    800053d6:	8082                	ret

00000000800053d8 <sys_link>:
{
    800053d8:	7169                	addi	sp,sp,-304
    800053da:	f606                	sd	ra,296(sp)
    800053dc:	f222                	sd	s0,288(sp)
    800053de:	ee26                	sd	s1,280(sp)
    800053e0:	ea4a                	sd	s2,272(sp)
    800053e2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053e4:	08000613          	li	a2,128
    800053e8:	ed040593          	addi	a1,s0,-304
    800053ec:	4501                	li	a0,0
    800053ee:	ffffd097          	auipc	ra,0xffffd
    800053f2:	70c080e7          	jalr	1804(ra) # 80002afa <argstr>
    return -1;
    800053f6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f8:	10054e63          	bltz	a0,80005514 <sys_link+0x13c>
    800053fc:	08000613          	li	a2,128
    80005400:	f5040593          	addi	a1,s0,-176
    80005404:	4505                	li	a0,1
    80005406:	ffffd097          	auipc	ra,0xffffd
    8000540a:	6f4080e7          	jalr	1780(ra) # 80002afa <argstr>
    return -1;
    8000540e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005410:	10054263          	bltz	a0,80005514 <sys_link+0x13c>
  begin_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	bf2080e7          	jalr	-1038(ra) # 80004006 <begin_op>
  if((ip = namei(old)) == 0){
    8000541c:	ed040513          	addi	a0,s0,-304
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	9d6080e7          	jalr	-1578(ra) # 80003df6 <namei>
    80005428:	84aa                	mv	s1,a0
    8000542a:	c551                	beqz	a0,800054b6 <sys_link+0xde>
  ilock(ip);
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	214080e7          	jalr	532(ra) # 80003640 <ilock>
  if(ip->type == T_DIR){
    80005434:	04449703          	lh	a4,68(s1)
    80005438:	4785                	li	a5,1
    8000543a:	08f70463          	beq	a4,a5,800054c2 <sys_link+0xea>
  ip->nlink++;
    8000543e:	04a4d783          	lhu	a5,74(s1)
    80005442:	2785                	addiw	a5,a5,1
    80005444:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	12a080e7          	jalr	298(ra) # 80003574 <iupdate>
  iunlock(ip);
    80005452:	8526                	mv	a0,s1
    80005454:	ffffe097          	auipc	ra,0xffffe
    80005458:	2ae080e7          	jalr	686(ra) # 80003702 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000545c:	fd040593          	addi	a1,s0,-48
    80005460:	f5040513          	addi	a0,s0,-176
    80005464:	fffff097          	auipc	ra,0xfffff
    80005468:	9b0080e7          	jalr	-1616(ra) # 80003e14 <nameiparent>
    8000546c:	892a                	mv	s2,a0
    8000546e:	c935                	beqz	a0,800054e2 <sys_link+0x10a>
  ilock(dp);
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	1d0080e7          	jalr	464(ra) # 80003640 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005478:	00092703          	lw	a4,0(s2)
    8000547c:	409c                	lw	a5,0(s1)
    8000547e:	04f71d63          	bne	a4,a5,800054d8 <sys_link+0x100>
    80005482:	40d0                	lw	a2,4(s1)
    80005484:	fd040593          	addi	a1,s0,-48
    80005488:	854a                	mv	a0,s2
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	8aa080e7          	jalr	-1878(ra) # 80003d34 <dirlink>
    80005492:	04054363          	bltz	a0,800054d8 <sys_link+0x100>
  iunlockput(dp);
    80005496:	854a                	mv	a0,s2
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	40a080e7          	jalr	1034(ra) # 800038a2 <iunlockput>
  iput(ip);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	358080e7          	jalr	856(ra) # 800037fa <iput>
  end_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	bda080e7          	jalr	-1062(ra) # 80004084 <end_op>
  return 0;
    800054b2:	4781                	li	a5,0
    800054b4:	a085                	j	80005514 <sys_link+0x13c>
    end_op();
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	bce080e7          	jalr	-1074(ra) # 80004084 <end_op>
    return -1;
    800054be:	57fd                	li	a5,-1
    800054c0:	a891                	j	80005514 <sys_link+0x13c>
    iunlockput(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	3de080e7          	jalr	990(ra) # 800038a2 <iunlockput>
    end_op();
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	bb8080e7          	jalr	-1096(ra) # 80004084 <end_op>
    return -1;
    800054d4:	57fd                	li	a5,-1
    800054d6:	a83d                	j	80005514 <sys_link+0x13c>
    iunlockput(dp);
    800054d8:	854a                	mv	a0,s2
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	3c8080e7          	jalr	968(ra) # 800038a2 <iunlockput>
  ilock(ip);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	15c080e7          	jalr	348(ra) # 80003640 <ilock>
  ip->nlink--;
    800054ec:	04a4d783          	lhu	a5,74(s1)
    800054f0:	37fd                	addiw	a5,a5,-1
    800054f2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	07c080e7          	jalr	124(ra) # 80003574 <iupdate>
  iunlockput(ip);
    80005500:	8526                	mv	a0,s1
    80005502:	ffffe097          	auipc	ra,0xffffe
    80005506:	3a0080e7          	jalr	928(ra) # 800038a2 <iunlockput>
  end_op();
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	b7a080e7          	jalr	-1158(ra) # 80004084 <end_op>
  return -1;
    80005512:	57fd                	li	a5,-1
}
    80005514:	853e                	mv	a0,a5
    80005516:	70b2                	ld	ra,296(sp)
    80005518:	7412                	ld	s0,288(sp)
    8000551a:	64f2                	ld	s1,280(sp)
    8000551c:	6952                	ld	s2,272(sp)
    8000551e:	6155                	addi	sp,sp,304
    80005520:	8082                	ret

0000000080005522 <sys_unlink>:
{
    80005522:	7151                	addi	sp,sp,-240
    80005524:	f586                	sd	ra,232(sp)
    80005526:	f1a2                	sd	s0,224(sp)
    80005528:	eda6                	sd	s1,216(sp)
    8000552a:	e9ca                	sd	s2,208(sp)
    8000552c:	e5ce                	sd	s3,200(sp)
    8000552e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005530:	08000613          	li	a2,128
    80005534:	f3040593          	addi	a1,s0,-208
    80005538:	4501                	li	a0,0
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	5c0080e7          	jalr	1472(ra) # 80002afa <argstr>
    80005542:	18054163          	bltz	a0,800056c4 <sys_unlink+0x1a2>
  begin_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	ac0080e7          	jalr	-1344(ra) # 80004006 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000554e:	fb040593          	addi	a1,s0,-80
    80005552:	f3040513          	addi	a0,s0,-208
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	8be080e7          	jalr	-1858(ra) # 80003e14 <nameiparent>
    8000555e:	84aa                	mv	s1,a0
    80005560:	c979                	beqz	a0,80005636 <sys_unlink+0x114>
  ilock(dp);
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	0de080e7          	jalr	222(ra) # 80003640 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000556a:	00003597          	auipc	a1,0x3
    8000556e:	1de58593          	addi	a1,a1,478 # 80008748 <syscalls+0x320>
    80005572:	fb040513          	addi	a0,s0,-80
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	58e080e7          	jalr	1422(ra) # 80003b04 <namecmp>
    8000557e:	14050a63          	beqz	a0,800056d2 <sys_unlink+0x1b0>
    80005582:	00003597          	auipc	a1,0x3
    80005586:	1ce58593          	addi	a1,a1,462 # 80008750 <syscalls+0x328>
    8000558a:	fb040513          	addi	a0,s0,-80
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	576080e7          	jalr	1398(ra) # 80003b04 <namecmp>
    80005596:	12050e63          	beqz	a0,800056d2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000559a:	f2c40613          	addi	a2,s0,-212
    8000559e:	fb040593          	addi	a1,s0,-80
    800055a2:	8526                	mv	a0,s1
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	57a080e7          	jalr	1402(ra) # 80003b1e <dirlookup>
    800055ac:	892a                	mv	s2,a0
    800055ae:	12050263          	beqz	a0,800056d2 <sys_unlink+0x1b0>
  ilock(ip);
    800055b2:	ffffe097          	auipc	ra,0xffffe
    800055b6:	08e080e7          	jalr	142(ra) # 80003640 <ilock>
  if(ip->nlink < 1)
    800055ba:	04a91783          	lh	a5,74(s2)
    800055be:	08f05263          	blez	a5,80005642 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055c2:	04491703          	lh	a4,68(s2)
    800055c6:	4785                	li	a5,1
    800055c8:	08f70563          	beq	a4,a5,80005652 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055cc:	4641                	li	a2,16
    800055ce:	4581                	li	a1,0
    800055d0:	fc040513          	addi	a0,s0,-64
    800055d4:	ffffb097          	auipc	ra,0xffffb
    800055d8:	728080e7          	jalr	1832(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055dc:	4741                	li	a4,16
    800055de:	f2c42683          	lw	a3,-212(s0)
    800055e2:	fc040613          	addi	a2,s0,-64
    800055e6:	4581                	li	a1,0
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	400080e7          	jalr	1024(ra) # 800039ea <writei>
    800055f2:	47c1                	li	a5,16
    800055f4:	0af51563          	bne	a0,a5,8000569e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055f8:	04491703          	lh	a4,68(s2)
    800055fc:	4785                	li	a5,1
    800055fe:	0af70863          	beq	a4,a5,800056ae <sys_unlink+0x18c>
  iunlockput(dp);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	29e080e7          	jalr	670(ra) # 800038a2 <iunlockput>
  ip->nlink--;
    8000560c:	04a95783          	lhu	a5,74(s2)
    80005610:	37fd                	addiw	a5,a5,-1
    80005612:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005616:	854a                	mv	a0,s2
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	f5c080e7          	jalr	-164(ra) # 80003574 <iupdate>
  iunlockput(ip);
    80005620:	854a                	mv	a0,s2
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	280080e7          	jalr	640(ra) # 800038a2 <iunlockput>
  end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	a5a080e7          	jalr	-1446(ra) # 80004084 <end_op>
  return 0;
    80005632:	4501                	li	a0,0
    80005634:	a84d                	j	800056e6 <sys_unlink+0x1c4>
    end_op();
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	a4e080e7          	jalr	-1458(ra) # 80004084 <end_op>
    return -1;
    8000563e:	557d                	li	a0,-1
    80005640:	a05d                	j	800056e6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005642:	00003517          	auipc	a0,0x3
    80005646:	13650513          	addi	a0,a0,310 # 80008778 <syscalls+0x350>
    8000564a:	ffffb097          	auipc	ra,0xffffb
    8000564e:	efc080e7          	jalr	-260(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005652:	04c92703          	lw	a4,76(s2)
    80005656:	02000793          	li	a5,32
    8000565a:	f6e7f9e3          	bgeu	a5,a4,800055cc <sys_unlink+0xaa>
    8000565e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005662:	4741                	li	a4,16
    80005664:	86ce                	mv	a3,s3
    80005666:	f1840613          	addi	a2,s0,-232
    8000566a:	4581                	li	a1,0
    8000566c:	854a                	mv	a0,s2
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	286080e7          	jalr	646(ra) # 800038f4 <readi>
    80005676:	47c1                	li	a5,16
    80005678:	00f51b63          	bne	a0,a5,8000568e <sys_unlink+0x16c>
    if(de.inum != 0)
    8000567c:	f1845783          	lhu	a5,-232(s0)
    80005680:	e7a1                	bnez	a5,800056c8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005682:	29c1                	addiw	s3,s3,16
    80005684:	04c92783          	lw	a5,76(s2)
    80005688:	fcf9ede3          	bltu	s3,a5,80005662 <sys_unlink+0x140>
    8000568c:	b781                	j	800055cc <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000568e:	00003517          	auipc	a0,0x3
    80005692:	10250513          	addi	a0,a0,258 # 80008790 <syscalls+0x368>
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	eb0080e7          	jalr	-336(ra) # 80000546 <panic>
    panic("unlink: writei");
    8000569e:	00003517          	auipc	a0,0x3
    800056a2:	10a50513          	addi	a0,a0,266 # 800087a8 <syscalls+0x380>
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	ea0080e7          	jalr	-352(ra) # 80000546 <panic>
    dp->nlink--;
    800056ae:	04a4d783          	lhu	a5,74(s1)
    800056b2:	37fd                	addiw	a5,a5,-1
    800056b4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	eba080e7          	jalr	-326(ra) # 80003574 <iupdate>
    800056c2:	b781                	j	80005602 <sys_unlink+0xe0>
    return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	a005                	j	800056e6 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	1d8080e7          	jalr	472(ra) # 800038a2 <iunlockput>
  iunlockput(dp);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	1ce080e7          	jalr	462(ra) # 800038a2 <iunlockput>
  end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	9a8080e7          	jalr	-1624(ra) # 80004084 <end_op>
  return -1;
    800056e4:	557d                	li	a0,-1
}
    800056e6:	70ae                	ld	ra,232(sp)
    800056e8:	740e                	ld	s0,224(sp)
    800056ea:	64ee                	ld	s1,216(sp)
    800056ec:	694e                	ld	s2,208(sp)
    800056ee:	69ae                	ld	s3,200(sp)
    800056f0:	616d                	addi	sp,sp,240
    800056f2:	8082                	ret

00000000800056f4 <sys_open>:

uint64
sys_open(void)
{
    800056f4:	7131                	addi	sp,sp,-192
    800056f6:	fd06                	sd	ra,184(sp)
    800056f8:	f922                	sd	s0,176(sp)
    800056fa:	f526                	sd	s1,168(sp)
    800056fc:	f14a                	sd	s2,160(sp)
    800056fe:	ed4e                	sd	s3,152(sp)
    80005700:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005702:	08000613          	li	a2,128
    80005706:	f5040593          	addi	a1,s0,-176
    8000570a:	4501                	li	a0,0
    8000570c:	ffffd097          	auipc	ra,0xffffd
    80005710:	3ee080e7          	jalr	1006(ra) # 80002afa <argstr>
    return -1;
    80005714:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005716:	0c054163          	bltz	a0,800057d8 <sys_open+0xe4>
    8000571a:	f4c40593          	addi	a1,s0,-180
    8000571e:	4505                	li	a0,1
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	396080e7          	jalr	918(ra) # 80002ab6 <argint>
    80005728:	0a054863          	bltz	a0,800057d8 <sys_open+0xe4>

  begin_op();
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	8da080e7          	jalr	-1830(ra) # 80004006 <begin_op>

  if(omode & O_CREATE){
    80005734:	f4c42783          	lw	a5,-180(s0)
    80005738:	2007f793          	andi	a5,a5,512
    8000573c:	cbdd                	beqz	a5,800057f2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000573e:	4681                	li	a3,0
    80005740:	4601                	li	a2,0
    80005742:	4589                	li	a1,2
    80005744:	f5040513          	addi	a0,s0,-176
    80005748:	00000097          	auipc	ra,0x0
    8000574c:	970080e7          	jalr	-1680(ra) # 800050b8 <create>
    80005750:	892a                	mv	s2,a0
    if(ip == 0){
    80005752:	c959                	beqz	a0,800057e8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005754:	04491703          	lh	a4,68(s2)
    80005758:	478d                	li	a5,3
    8000575a:	00f71763          	bne	a4,a5,80005768 <sys_open+0x74>
    8000575e:	04695703          	lhu	a4,70(s2)
    80005762:	47a5                	li	a5,9
    80005764:	0ce7ec63          	bltu	a5,a4,8000583c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	cb0080e7          	jalr	-848(ra) # 80004418 <filealloc>
    80005770:	89aa                	mv	s3,a0
    80005772:	10050263          	beqz	a0,80005876 <sys_open+0x182>
    80005776:	00000097          	auipc	ra,0x0
    8000577a:	900080e7          	jalr	-1792(ra) # 80005076 <fdalloc>
    8000577e:	84aa                	mv	s1,a0
    80005780:	0e054663          	bltz	a0,8000586c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005784:	04491703          	lh	a4,68(s2)
    80005788:	478d                	li	a5,3
    8000578a:	0cf70463          	beq	a4,a5,80005852 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000578e:	4789                	li	a5,2
    80005790:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005794:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005798:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000579c:	f4c42783          	lw	a5,-180(s0)
    800057a0:	0017c713          	xori	a4,a5,1
    800057a4:	8b05                	andi	a4,a4,1
    800057a6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057aa:	0037f713          	andi	a4,a5,3
    800057ae:	00e03733          	snez	a4,a4
    800057b2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057b6:	4007f793          	andi	a5,a5,1024
    800057ba:	c791                	beqz	a5,800057c6 <sys_open+0xd2>
    800057bc:	04491703          	lh	a4,68(s2)
    800057c0:	4789                	li	a5,2
    800057c2:	08f70f63          	beq	a4,a5,80005860 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057c6:	854a                	mv	a0,s2
    800057c8:	ffffe097          	auipc	ra,0xffffe
    800057cc:	f3a080e7          	jalr	-198(ra) # 80003702 <iunlock>
  end_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	8b4080e7          	jalr	-1868(ra) # 80004084 <end_op>

  return fd;
}
    800057d8:	8526                	mv	a0,s1
    800057da:	70ea                	ld	ra,184(sp)
    800057dc:	744a                	ld	s0,176(sp)
    800057de:	74aa                	ld	s1,168(sp)
    800057e0:	790a                	ld	s2,160(sp)
    800057e2:	69ea                	ld	s3,152(sp)
    800057e4:	6129                	addi	sp,sp,192
    800057e6:	8082                	ret
      end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	89c080e7          	jalr	-1892(ra) # 80004084 <end_op>
      return -1;
    800057f0:	b7e5                	j	800057d8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057f2:	f5040513          	addi	a0,s0,-176
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	600080e7          	jalr	1536(ra) # 80003df6 <namei>
    800057fe:	892a                	mv	s2,a0
    80005800:	c905                	beqz	a0,80005830 <sys_open+0x13c>
    ilock(ip);
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	e3e080e7          	jalr	-450(ra) # 80003640 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000580a:	04491703          	lh	a4,68(s2)
    8000580e:	4785                	li	a5,1
    80005810:	f4f712e3          	bne	a4,a5,80005754 <sys_open+0x60>
    80005814:	f4c42783          	lw	a5,-180(s0)
    80005818:	dba1                	beqz	a5,80005768 <sys_open+0x74>
      iunlockput(ip);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	086080e7          	jalr	134(ra) # 800038a2 <iunlockput>
      end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	860080e7          	jalr	-1952(ra) # 80004084 <end_op>
      return -1;
    8000582c:	54fd                	li	s1,-1
    8000582e:	b76d                	j	800057d8 <sys_open+0xe4>
      end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	854080e7          	jalr	-1964(ra) # 80004084 <end_op>
      return -1;
    80005838:	54fd                	li	s1,-1
    8000583a:	bf79                	j	800057d8 <sys_open+0xe4>
    iunlockput(ip);
    8000583c:	854a                	mv	a0,s2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	064080e7          	jalr	100(ra) # 800038a2 <iunlockput>
    end_op();
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	83e080e7          	jalr	-1986(ra) # 80004084 <end_op>
    return -1;
    8000584e:	54fd                	li	s1,-1
    80005850:	b761                	j	800057d8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005852:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005856:	04691783          	lh	a5,70(s2)
    8000585a:	02f99223          	sh	a5,36(s3)
    8000585e:	bf2d                	j	80005798 <sys_open+0xa4>
    itrunc(ip);
    80005860:	854a                	mv	a0,s2
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	eec080e7          	jalr	-276(ra) # 8000374e <itrunc>
    8000586a:	bfb1                	j	800057c6 <sys_open+0xd2>
      fileclose(f);
    8000586c:	854e                	mv	a0,s3
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	c66080e7          	jalr	-922(ra) # 800044d4 <fileclose>
    iunlockput(ip);
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	02a080e7          	jalr	42(ra) # 800038a2 <iunlockput>
    end_op();
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	804080e7          	jalr	-2044(ra) # 80004084 <end_op>
    return -1;
    80005888:	54fd                	li	s1,-1
    8000588a:	b7b9                	j	800057d8 <sys_open+0xe4>

000000008000588c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000588c:	7175                	addi	sp,sp,-144
    8000588e:	e506                	sd	ra,136(sp)
    80005890:	e122                	sd	s0,128(sp)
    80005892:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	772080e7          	jalr	1906(ra) # 80004006 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000589c:	08000613          	li	a2,128
    800058a0:	f7040593          	addi	a1,s0,-144
    800058a4:	4501                	li	a0,0
    800058a6:	ffffd097          	auipc	ra,0xffffd
    800058aa:	254080e7          	jalr	596(ra) # 80002afa <argstr>
    800058ae:	02054963          	bltz	a0,800058e0 <sys_mkdir+0x54>
    800058b2:	4681                	li	a3,0
    800058b4:	4601                	li	a2,0
    800058b6:	4585                	li	a1,1
    800058b8:	f7040513          	addi	a0,s0,-144
    800058bc:	fffff097          	auipc	ra,0xfffff
    800058c0:	7fc080e7          	jalr	2044(ra) # 800050b8 <create>
    800058c4:	cd11                	beqz	a0,800058e0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	fdc080e7          	jalr	-36(ra) # 800038a2 <iunlockput>
  end_op();
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	7b6080e7          	jalr	1974(ra) # 80004084 <end_op>
  return 0;
    800058d6:	4501                	li	a0,0
}
    800058d8:	60aa                	ld	ra,136(sp)
    800058da:	640a                	ld	s0,128(sp)
    800058dc:	6149                	addi	sp,sp,144
    800058de:	8082                	ret
    end_op();
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	7a4080e7          	jalr	1956(ra) # 80004084 <end_op>
    return -1;
    800058e8:	557d                	li	a0,-1
    800058ea:	b7fd                	j	800058d8 <sys_mkdir+0x4c>

00000000800058ec <sys_mknod>:

uint64
sys_mknod(void)
{
    800058ec:	7135                	addi	sp,sp,-160
    800058ee:	ed06                	sd	ra,152(sp)
    800058f0:	e922                	sd	s0,144(sp)
    800058f2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	712080e7          	jalr	1810(ra) # 80004006 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058fc:	08000613          	li	a2,128
    80005900:	f7040593          	addi	a1,s0,-144
    80005904:	4501                	li	a0,0
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	1f4080e7          	jalr	500(ra) # 80002afa <argstr>
    8000590e:	04054a63          	bltz	a0,80005962 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005912:	f6c40593          	addi	a1,s0,-148
    80005916:	4505                	li	a0,1
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	19e080e7          	jalr	414(ra) # 80002ab6 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005920:	04054163          	bltz	a0,80005962 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005924:	f6840593          	addi	a1,s0,-152
    80005928:	4509                	li	a0,2
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	18c080e7          	jalr	396(ra) # 80002ab6 <argint>
     argint(1, &major) < 0 ||
    80005932:	02054863          	bltz	a0,80005962 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005936:	f6841683          	lh	a3,-152(s0)
    8000593a:	f6c41603          	lh	a2,-148(s0)
    8000593e:	458d                	li	a1,3
    80005940:	f7040513          	addi	a0,s0,-144
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	774080e7          	jalr	1908(ra) # 800050b8 <create>
     argint(2, &minor) < 0 ||
    8000594c:	c919                	beqz	a0,80005962 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	f54080e7          	jalr	-172(ra) # 800038a2 <iunlockput>
  end_op();
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	72e080e7          	jalr	1838(ra) # 80004084 <end_op>
  return 0;
    8000595e:	4501                	li	a0,0
    80005960:	a031                	j	8000596c <sys_mknod+0x80>
    end_op();
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	722080e7          	jalr	1826(ra) # 80004084 <end_op>
    return -1;
    8000596a:	557d                	li	a0,-1
}
    8000596c:	60ea                	ld	ra,152(sp)
    8000596e:	644a                	ld	s0,144(sp)
    80005970:	610d                	addi	sp,sp,160
    80005972:	8082                	ret

0000000080005974 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005974:	7135                	addi	sp,sp,-160
    80005976:	ed06                	sd	ra,152(sp)
    80005978:	e922                	sd	s0,144(sp)
    8000597a:	e526                	sd	s1,136(sp)
    8000597c:	e14a                	sd	s2,128(sp)
    8000597e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005980:	ffffc097          	auipc	ra,0xffffc
    80005984:	07a080e7          	jalr	122(ra) # 800019fa <myproc>
    80005988:	892a                	mv	s2,a0
  
  begin_op();
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	67c080e7          	jalr	1660(ra) # 80004006 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005992:	08000613          	li	a2,128
    80005996:	f6040593          	addi	a1,s0,-160
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	15e080e7          	jalr	350(ra) # 80002afa <argstr>
    800059a4:	04054b63          	bltz	a0,800059fa <sys_chdir+0x86>
    800059a8:	f6040513          	addi	a0,s0,-160
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	44a080e7          	jalr	1098(ra) # 80003df6 <namei>
    800059b4:	84aa                	mv	s1,a0
    800059b6:	c131                	beqz	a0,800059fa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	c88080e7          	jalr	-888(ra) # 80003640 <ilock>
  if(ip->type != T_DIR){
    800059c0:	04449703          	lh	a4,68(s1)
    800059c4:	4785                	li	a5,1
    800059c6:	04f71063          	bne	a4,a5,80005a06 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ca:	8526                	mv	a0,s1
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	d36080e7          	jalr	-714(ra) # 80003702 <iunlock>
  iput(p->cwd);
    800059d4:	15093503          	ld	a0,336(s2)
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	e22080e7          	jalr	-478(ra) # 800037fa <iput>
  end_op();
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	6a4080e7          	jalr	1700(ra) # 80004084 <end_op>
  p->cwd = ip;
    800059e8:	14993823          	sd	s1,336(s2)
  return 0;
    800059ec:	4501                	li	a0,0
}
    800059ee:	60ea                	ld	ra,152(sp)
    800059f0:	644a                	ld	s0,144(sp)
    800059f2:	64aa                	ld	s1,136(sp)
    800059f4:	690a                	ld	s2,128(sp)
    800059f6:	610d                	addi	sp,sp,160
    800059f8:	8082                	ret
    end_op();
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	68a080e7          	jalr	1674(ra) # 80004084 <end_op>
    return -1;
    80005a02:	557d                	li	a0,-1
    80005a04:	b7ed                	j	800059ee <sys_chdir+0x7a>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	e9a080e7          	jalr	-358(ra) # 800038a2 <iunlockput>
    end_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	674080e7          	jalr	1652(ra) # 80004084 <end_op>
    return -1;
    80005a18:	557d                	li	a0,-1
    80005a1a:	bfd1                	j	800059ee <sys_chdir+0x7a>

0000000080005a1c <sys_exec>:

uint64
sys_exec(void)
{
    80005a1c:	7145                	addi	sp,sp,-464
    80005a1e:	e786                	sd	ra,456(sp)
    80005a20:	e3a2                	sd	s0,448(sp)
    80005a22:	ff26                	sd	s1,440(sp)
    80005a24:	fb4a                	sd	s2,432(sp)
    80005a26:	f74e                	sd	s3,424(sp)
    80005a28:	f352                	sd	s4,416(sp)
    80005a2a:	ef56                	sd	s5,408(sp)
    80005a2c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a2e:	08000613          	li	a2,128
    80005a32:	f4040593          	addi	a1,s0,-192
    80005a36:	4501                	li	a0,0
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	0c2080e7          	jalr	194(ra) # 80002afa <argstr>
    return -1;
    80005a40:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a42:	0c054b63          	bltz	a0,80005b18 <sys_exec+0xfc>
    80005a46:	e3840593          	addi	a1,s0,-456
    80005a4a:	4505                	li	a0,1
    80005a4c:	ffffd097          	auipc	ra,0xffffd
    80005a50:	08c080e7          	jalr	140(ra) # 80002ad8 <argaddr>
    80005a54:	0c054263          	bltz	a0,80005b18 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a58:	10000613          	li	a2,256
    80005a5c:	4581                	li	a1,0
    80005a5e:	e4040513          	addi	a0,s0,-448
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	29a080e7          	jalr	666(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a6a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a6e:	89a6                	mv	s3,s1
    80005a70:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a72:	02000a13          	li	s4,32
    80005a76:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a7a:	00391513          	slli	a0,s2,0x3
    80005a7e:	e3040593          	addi	a1,s0,-464
    80005a82:	e3843783          	ld	a5,-456(s0)
    80005a86:	953e                	add	a0,a0,a5
    80005a88:	ffffd097          	auipc	ra,0xffffd
    80005a8c:	f94080e7          	jalr	-108(ra) # 80002a1c <fetchaddr>
    80005a90:	02054a63          	bltz	a0,80005ac4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a94:	e3043783          	ld	a5,-464(s0)
    80005a98:	c3b9                	beqz	a5,80005ade <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	076080e7          	jalr	118(ra) # 80000b10 <kalloc>
    80005aa2:	85aa                	mv	a1,a0
    80005aa4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aa8:	cd11                	beqz	a0,80005ac4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aaa:	6605                	lui	a2,0x1
    80005aac:	e3043503          	ld	a0,-464(s0)
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	fbe080e7          	jalr	-66(ra) # 80002a6e <fetchstr>
    80005ab8:	00054663          	bltz	a0,80005ac4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005abc:	0905                	addi	s2,s2,1
    80005abe:	09a1                	addi	s3,s3,8
    80005ac0:	fb491be3          	bne	s2,s4,80005a76 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac4:	f4040913          	addi	s2,s0,-192
    80005ac8:	6088                	ld	a0,0(s1)
    80005aca:	c531                	beqz	a0,80005b16 <sys_exec+0xfa>
    kfree(argv[i]);
    80005acc:	ffffb097          	auipc	ra,0xffffb
    80005ad0:	f46080e7          	jalr	-186(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ad4:	04a1                	addi	s1,s1,8
    80005ad6:	ff2499e3          	bne	s1,s2,80005ac8 <sys_exec+0xac>
  return -1;
    80005ada:	597d                	li	s2,-1
    80005adc:	a835                	j	80005b18 <sys_exec+0xfc>
      argv[i] = 0;
    80005ade:	0a8e                	slli	s5,s5,0x3
    80005ae0:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd7fa0>
    80005ae4:	00878ab3          	add	s5,a5,s0
    80005ae8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005aec:	e4040593          	addi	a1,s0,-448
    80005af0:	f4040513          	addi	a0,s0,-192
    80005af4:	fffff097          	auipc	ra,0xfffff
    80005af8:	15a080e7          	jalr	346(ra) # 80004c4e <exec>
    80005afc:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005afe:	f4040993          	addi	s3,s0,-192
    80005b02:	6088                	ld	a0,0(s1)
    80005b04:	c911                	beqz	a0,80005b18 <sys_exec+0xfc>
    kfree(argv[i]);
    80005b06:	ffffb097          	auipc	ra,0xffffb
    80005b0a:	f0c080e7          	jalr	-244(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b0e:	04a1                	addi	s1,s1,8
    80005b10:	ff3499e3          	bne	s1,s3,80005b02 <sys_exec+0xe6>
    80005b14:	a011                	j	80005b18 <sys_exec+0xfc>
  return -1;
    80005b16:	597d                	li	s2,-1
}
    80005b18:	854a                	mv	a0,s2
    80005b1a:	60be                	ld	ra,456(sp)
    80005b1c:	641e                	ld	s0,448(sp)
    80005b1e:	74fa                	ld	s1,440(sp)
    80005b20:	795a                	ld	s2,432(sp)
    80005b22:	79ba                	ld	s3,424(sp)
    80005b24:	7a1a                	ld	s4,416(sp)
    80005b26:	6afa                	ld	s5,408(sp)
    80005b28:	6179                	addi	sp,sp,464
    80005b2a:	8082                	ret

0000000080005b2c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b2c:	7139                	addi	sp,sp,-64
    80005b2e:	fc06                	sd	ra,56(sp)
    80005b30:	f822                	sd	s0,48(sp)
    80005b32:	f426                	sd	s1,40(sp)
    80005b34:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b36:	ffffc097          	auipc	ra,0xffffc
    80005b3a:	ec4080e7          	jalr	-316(ra) # 800019fa <myproc>
    80005b3e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b40:	fd840593          	addi	a1,s0,-40
    80005b44:	4501                	li	a0,0
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	f92080e7          	jalr	-110(ra) # 80002ad8 <argaddr>
    return -1;
    80005b4e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b50:	0e054063          	bltz	a0,80005c30 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b54:	fc840593          	addi	a1,s0,-56
    80005b58:	fd040513          	addi	a0,s0,-48
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	cce080e7          	jalr	-818(ra) # 8000482a <pipealloc>
    return -1;
    80005b64:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b66:	0c054563          	bltz	a0,80005c30 <sys_pipe+0x104>
  fd0 = -1;
    80005b6a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b6e:	fd043503          	ld	a0,-48(s0)
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	504080e7          	jalr	1284(ra) # 80005076 <fdalloc>
    80005b7a:	fca42223          	sw	a0,-60(s0)
    80005b7e:	08054c63          	bltz	a0,80005c16 <sys_pipe+0xea>
    80005b82:	fc843503          	ld	a0,-56(s0)
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	4f0080e7          	jalr	1264(ra) # 80005076 <fdalloc>
    80005b8e:	fca42023          	sw	a0,-64(s0)
    80005b92:	06054963          	bltz	a0,80005c04 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b96:	4691                	li	a3,4
    80005b98:	fc440613          	addi	a2,s0,-60
    80005b9c:	fd843583          	ld	a1,-40(s0)
    80005ba0:	68a8                	ld	a0,80(s1)
    80005ba2:	ffffc097          	auipc	ra,0xffffc
    80005ba6:	b28080e7          	jalr	-1240(ra) # 800016ca <copyout>
    80005baa:	02054063          	bltz	a0,80005bca <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bae:	4691                	li	a3,4
    80005bb0:	fc040613          	addi	a2,s0,-64
    80005bb4:	fd843583          	ld	a1,-40(s0)
    80005bb8:	0591                	addi	a1,a1,4
    80005bba:	68a8                	ld	a0,80(s1)
    80005bbc:	ffffc097          	auipc	ra,0xffffc
    80005bc0:	b0e080e7          	jalr	-1266(ra) # 800016ca <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bc4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc6:	06055563          	bgez	a0,80005c30 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bca:	fc442783          	lw	a5,-60(s0)
    80005bce:	07e9                	addi	a5,a5,26
    80005bd0:	078e                	slli	a5,a5,0x3
    80005bd2:	97a6                	add	a5,a5,s1
    80005bd4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bd8:	fc042783          	lw	a5,-64(s0)
    80005bdc:	07e9                	addi	a5,a5,26
    80005bde:	078e                	slli	a5,a5,0x3
    80005be0:	00f48533          	add	a0,s1,a5
    80005be4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005be8:	fd043503          	ld	a0,-48(s0)
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	8e8080e7          	jalr	-1816(ra) # 800044d4 <fileclose>
    fileclose(wf);
    80005bf4:	fc843503          	ld	a0,-56(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	8dc080e7          	jalr	-1828(ra) # 800044d4 <fileclose>
    return -1;
    80005c00:	57fd                	li	a5,-1
    80005c02:	a03d                	j	80005c30 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c04:	fc442783          	lw	a5,-60(s0)
    80005c08:	0007c763          	bltz	a5,80005c16 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c0c:	07e9                	addi	a5,a5,26
    80005c0e:	078e                	slli	a5,a5,0x3
    80005c10:	97a6                	add	a5,a5,s1
    80005c12:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c16:	fd043503          	ld	a0,-48(s0)
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	8ba080e7          	jalr	-1862(ra) # 800044d4 <fileclose>
    fileclose(wf);
    80005c22:	fc843503          	ld	a0,-56(s0)
    80005c26:	fffff097          	auipc	ra,0xfffff
    80005c2a:	8ae080e7          	jalr	-1874(ra) # 800044d4 <fileclose>
    return -1;
    80005c2e:	57fd                	li	a5,-1
}
    80005c30:	853e                	mv	a0,a5
    80005c32:	70e2                	ld	ra,56(sp)
    80005c34:	7442                	ld	s0,48(sp)
    80005c36:	74a2                	ld	s1,40(sp)
    80005c38:	6121                	addi	sp,sp,64
    80005c3a:	8082                	ret
    80005c3c:	0000                	unimp
	...

0000000080005c40 <kernelvec>:
    80005c40:	7111                	addi	sp,sp,-256
    80005c42:	e006                	sd	ra,0(sp)
    80005c44:	e40a                	sd	sp,8(sp)
    80005c46:	e80e                	sd	gp,16(sp)
    80005c48:	ec12                	sd	tp,24(sp)
    80005c4a:	f016                	sd	t0,32(sp)
    80005c4c:	f41a                	sd	t1,40(sp)
    80005c4e:	f81e                	sd	t2,48(sp)
    80005c50:	fc22                	sd	s0,56(sp)
    80005c52:	e0a6                	sd	s1,64(sp)
    80005c54:	e4aa                	sd	a0,72(sp)
    80005c56:	e8ae                	sd	a1,80(sp)
    80005c58:	ecb2                	sd	a2,88(sp)
    80005c5a:	f0b6                	sd	a3,96(sp)
    80005c5c:	f4ba                	sd	a4,104(sp)
    80005c5e:	f8be                	sd	a5,112(sp)
    80005c60:	fcc2                	sd	a6,120(sp)
    80005c62:	e146                	sd	a7,128(sp)
    80005c64:	e54a                	sd	s2,136(sp)
    80005c66:	e94e                	sd	s3,144(sp)
    80005c68:	ed52                	sd	s4,152(sp)
    80005c6a:	f156                	sd	s5,160(sp)
    80005c6c:	f55a                	sd	s6,168(sp)
    80005c6e:	f95e                	sd	s7,176(sp)
    80005c70:	fd62                	sd	s8,184(sp)
    80005c72:	e1e6                	sd	s9,192(sp)
    80005c74:	e5ea                	sd	s10,200(sp)
    80005c76:	e9ee                	sd	s11,208(sp)
    80005c78:	edf2                	sd	t3,216(sp)
    80005c7a:	f1f6                	sd	t4,224(sp)
    80005c7c:	f5fa                	sd	t5,232(sp)
    80005c7e:	f9fe                	sd	t6,240(sp)
    80005c80:	c69fc0ef          	jal	ra,800028e8 <kerneltrap>
    80005c84:	6082                	ld	ra,0(sp)
    80005c86:	6122                	ld	sp,8(sp)
    80005c88:	61c2                	ld	gp,16(sp)
    80005c8a:	7282                	ld	t0,32(sp)
    80005c8c:	7322                	ld	t1,40(sp)
    80005c8e:	73c2                	ld	t2,48(sp)
    80005c90:	7462                	ld	s0,56(sp)
    80005c92:	6486                	ld	s1,64(sp)
    80005c94:	6526                	ld	a0,72(sp)
    80005c96:	65c6                	ld	a1,80(sp)
    80005c98:	6666                	ld	a2,88(sp)
    80005c9a:	7686                	ld	a3,96(sp)
    80005c9c:	7726                	ld	a4,104(sp)
    80005c9e:	77c6                	ld	a5,112(sp)
    80005ca0:	7866                	ld	a6,120(sp)
    80005ca2:	688a                	ld	a7,128(sp)
    80005ca4:	692a                	ld	s2,136(sp)
    80005ca6:	69ca                	ld	s3,144(sp)
    80005ca8:	6a6a                	ld	s4,152(sp)
    80005caa:	7a8a                	ld	s5,160(sp)
    80005cac:	7b2a                	ld	s6,168(sp)
    80005cae:	7bca                	ld	s7,176(sp)
    80005cb0:	7c6a                	ld	s8,184(sp)
    80005cb2:	6c8e                	ld	s9,192(sp)
    80005cb4:	6d2e                	ld	s10,200(sp)
    80005cb6:	6dce                	ld	s11,208(sp)
    80005cb8:	6e6e                	ld	t3,216(sp)
    80005cba:	7e8e                	ld	t4,224(sp)
    80005cbc:	7f2e                	ld	t5,232(sp)
    80005cbe:	7fce                	ld	t6,240(sp)
    80005cc0:	6111                	addi	sp,sp,256
    80005cc2:	10200073          	sret
    80005cc6:	00000013          	nop
    80005cca:	00000013          	nop
    80005cce:	0001                	nop

0000000080005cd0 <timervec>:
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	e10c                	sd	a1,0(a0)
    80005cd6:	e510                	sd	a2,8(a0)
    80005cd8:	e914                	sd	a3,16(a0)
    80005cda:	710c                	ld	a1,32(a0)
    80005cdc:	7510                	ld	a2,40(a0)
    80005cde:	6194                	ld	a3,0(a1)
    80005ce0:	96b2                	add	a3,a3,a2
    80005ce2:	e194                	sd	a3,0(a1)
    80005ce4:	4589                	li	a1,2
    80005ce6:	14459073          	csrw	sip,a1
    80005cea:	6914                	ld	a3,16(a0)
    80005cec:	6510                	ld	a2,8(a0)
    80005cee:	610c                	ld	a1,0(a0)
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	30200073          	mret
	...

0000000080005cfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cfa:	1141                	addi	sp,sp,-16
    80005cfc:	e422                	sd	s0,8(sp)
    80005cfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d00:	0c0007b7          	lui	a5,0xc000
    80005d04:	4705                	li	a4,1
    80005d06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d08:	c3d8                	sw	a4,4(a5)
}
    80005d0a:	6422                	ld	s0,8(sp)
    80005d0c:	0141                	addi	sp,sp,16
    80005d0e:	8082                	ret

0000000080005d10 <plicinithart>:

void
plicinithart(void)
{
    80005d10:	1141                	addi	sp,sp,-16
    80005d12:	e406                	sd	ra,8(sp)
    80005d14:	e022                	sd	s0,0(sp)
    80005d16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	cb6080e7          	jalr	-842(ra) # 800019ce <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d20:	0085171b          	slliw	a4,a0,0x8
    80005d24:	0c0027b7          	lui	a5,0xc002
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	40200713          	li	a4,1026
    80005d2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d32:	00d5151b          	slliw	a0,a0,0xd
    80005d36:	0c2017b7          	lui	a5,0xc201
    80005d3a:	97aa                	add	a5,a5,a0
    80005d3c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d40:	60a2                	ld	ra,8(sp)
    80005d42:	6402                	ld	s0,0(sp)
    80005d44:	0141                	addi	sp,sp,16
    80005d46:	8082                	ret

0000000080005d48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d48:	1141                	addi	sp,sp,-16
    80005d4a:	e406                	sd	ra,8(sp)
    80005d4c:	e022                	sd	s0,0(sp)
    80005d4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d50:	ffffc097          	auipc	ra,0xffffc
    80005d54:	c7e080e7          	jalr	-898(ra) # 800019ce <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d58:	00d5151b          	slliw	a0,a0,0xd
    80005d5c:	0c2017b7          	lui	a5,0xc201
    80005d60:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d62:	43c8                	lw	a0,4(a5)
    80005d64:	60a2                	ld	ra,8(sp)
    80005d66:	6402                	ld	s0,0(sp)
    80005d68:	0141                	addi	sp,sp,16
    80005d6a:	8082                	ret

0000000080005d6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d6c:	1101                	addi	sp,sp,-32
    80005d6e:	ec06                	sd	ra,24(sp)
    80005d70:	e822                	sd	s0,16(sp)
    80005d72:	e426                	sd	s1,8(sp)
    80005d74:	1000                	addi	s0,sp,32
    80005d76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	c56080e7          	jalr	-938(ra) # 800019ce <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d80:	00d5151b          	slliw	a0,a0,0xd
    80005d84:	0c2017b7          	lui	a5,0xc201
    80005d88:	97aa                	add	a5,a5,a0
    80005d8a:	c3c4                	sw	s1,4(a5)
}
    80005d8c:	60e2                	ld	ra,24(sp)
    80005d8e:	6442                	ld	s0,16(sp)
    80005d90:	64a2                	ld	s1,8(sp)
    80005d92:	6105                	addi	sp,sp,32
    80005d94:	8082                	ret

0000000080005d96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d96:	1141                	addi	sp,sp,-16
    80005d98:	e406                	sd	ra,8(sp)
    80005d9a:	e022                	sd	s0,0(sp)
    80005d9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d9e:	479d                	li	a5,7
    80005da0:	04a7cb63          	blt	a5,a0,80005df6 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005da4:	0001d717          	auipc	a4,0x1d
    80005da8:	25c70713          	addi	a4,a4,604 # 80023000 <disk>
    80005dac:	972a                	add	a4,a4,a0
    80005dae:	6789                	lui	a5,0x2
    80005db0:	97ba                	add	a5,a5,a4
    80005db2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005db6:	eba1                	bnez	a5,80005e06 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005db8:	00451713          	slli	a4,a0,0x4
    80005dbc:	0001f797          	auipc	a5,0x1f
    80005dc0:	2447b783          	ld	a5,580(a5) # 80025000 <disk+0x2000>
    80005dc4:	97ba                	add	a5,a5,a4
    80005dc6:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dca:	0001d717          	auipc	a4,0x1d
    80005dce:	23670713          	addi	a4,a4,566 # 80023000 <disk>
    80005dd2:	972a                	add	a4,a4,a0
    80005dd4:	6789                	lui	a5,0x2
    80005dd6:	97ba                	add	a5,a5,a4
    80005dd8:	4705                	li	a4,1
    80005dda:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dde:	0001f517          	auipc	a0,0x1f
    80005de2:	23a50513          	addi	a0,a0,570 # 80025018 <disk+0x2018>
    80005de6:	ffffc097          	auipc	ra,0xffffc
    80005dea:	5a8080e7          	jalr	1448(ra) # 8000238e <wakeup>
}
    80005dee:	60a2                	ld	ra,8(sp)
    80005df0:	6402                	ld	s0,0(sp)
    80005df2:	0141                	addi	sp,sp,16
    80005df4:	8082                	ret
    panic("virtio_disk_intr 1");
    80005df6:	00003517          	auipc	a0,0x3
    80005dfa:	9c250513          	addi	a0,a0,-1598 # 800087b8 <syscalls+0x390>
    80005dfe:	ffffa097          	auipc	ra,0xffffa
    80005e02:	748080e7          	jalr	1864(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005e06:	00003517          	auipc	a0,0x3
    80005e0a:	9ca50513          	addi	a0,a0,-1590 # 800087d0 <syscalls+0x3a8>
    80005e0e:	ffffa097          	auipc	ra,0xffffa
    80005e12:	738080e7          	jalr	1848(ra) # 80000546 <panic>

0000000080005e16 <virtio_disk_init>:
{
    80005e16:	1101                	addi	sp,sp,-32
    80005e18:	ec06                	sd	ra,24(sp)
    80005e1a:	e822                	sd	s0,16(sp)
    80005e1c:	e426                	sd	s1,8(sp)
    80005e1e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e20:	00003597          	auipc	a1,0x3
    80005e24:	9c858593          	addi	a1,a1,-1592 # 800087e8 <syscalls+0x3c0>
    80005e28:	0001f517          	auipc	a0,0x1f
    80005e2c:	28050513          	addi	a0,a0,640 # 800250a8 <disk+0x20a8>
    80005e30:	ffffb097          	auipc	ra,0xffffb
    80005e34:	d40080e7          	jalr	-704(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e38:	100017b7          	lui	a5,0x10001
    80005e3c:	4398                	lw	a4,0(a5)
    80005e3e:	2701                	sext.w	a4,a4
    80005e40:	747277b7          	lui	a5,0x74727
    80005e44:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e48:	0ef71063          	bne	a4,a5,80005f28 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e4c:	100017b7          	lui	a5,0x10001
    80005e50:	43dc                	lw	a5,4(a5)
    80005e52:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e54:	4705                	li	a4,1
    80005e56:	0ce79963          	bne	a5,a4,80005f28 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	479c                	lw	a5,8(a5)
    80005e60:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e62:	4709                	li	a4,2
    80005e64:	0ce79263          	bne	a5,a4,80005f28 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e68:	100017b7          	lui	a5,0x10001
    80005e6c:	47d8                	lw	a4,12(a5)
    80005e6e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e70:	554d47b7          	lui	a5,0x554d4
    80005e74:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e78:	0af71863          	bne	a4,a5,80005f28 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	4705                	li	a4,1
    80005e82:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e84:	470d                	li	a4,3
    80005e86:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e88:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e8a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e8e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80005e92:	8f75                	and	a4,a4,a3
    80005e94:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e96:	472d                	li	a4,11
    80005e98:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9a:	473d                	li	a4,15
    80005e9c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e9e:	6705                	lui	a4,0x1
    80005ea0:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ea2:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ea6:	5bdc                	lw	a5,52(a5)
    80005ea8:	2781                	sext.w	a5,a5
  if(max == 0)
    80005eaa:	c7d9                	beqz	a5,80005f38 <virtio_disk_init+0x122>
  if(max < NUM)
    80005eac:	471d                	li	a4,7
    80005eae:	08f77d63          	bgeu	a4,a5,80005f48 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005eb2:	100014b7          	lui	s1,0x10001
    80005eb6:	47a1                	li	a5,8
    80005eb8:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eba:	6609                	lui	a2,0x2
    80005ebc:	4581                	li	a1,0
    80005ebe:	0001d517          	auipc	a0,0x1d
    80005ec2:	14250513          	addi	a0,a0,322 # 80023000 <disk>
    80005ec6:	ffffb097          	auipc	ra,0xffffb
    80005eca:	e36080e7          	jalr	-458(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ece:	0001d717          	auipc	a4,0x1d
    80005ed2:	13270713          	addi	a4,a4,306 # 80023000 <disk>
    80005ed6:	00c75793          	srli	a5,a4,0xc
    80005eda:	2781                	sext.w	a5,a5
    80005edc:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ede:	0001f797          	auipc	a5,0x1f
    80005ee2:	12278793          	addi	a5,a5,290 # 80025000 <disk+0x2000>
    80005ee6:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005ee8:	0001d717          	auipc	a4,0x1d
    80005eec:	19870713          	addi	a4,a4,408 # 80023080 <disk+0x80>
    80005ef0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ef2:	0001e717          	auipc	a4,0x1e
    80005ef6:	10e70713          	addi	a4,a4,270 # 80024000 <disk+0x1000>
    80005efa:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005efc:	4705                	li	a4,1
    80005efe:	00e78c23          	sb	a4,24(a5)
    80005f02:	00e78ca3          	sb	a4,25(a5)
    80005f06:	00e78d23          	sb	a4,26(a5)
    80005f0a:	00e78da3          	sb	a4,27(a5)
    80005f0e:	00e78e23          	sb	a4,28(a5)
    80005f12:	00e78ea3          	sb	a4,29(a5)
    80005f16:	00e78f23          	sb	a4,30(a5)
    80005f1a:	00e78fa3          	sb	a4,31(a5)
}
    80005f1e:	60e2                	ld	ra,24(sp)
    80005f20:	6442                	ld	s0,16(sp)
    80005f22:	64a2                	ld	s1,8(sp)
    80005f24:	6105                	addi	sp,sp,32
    80005f26:	8082                	ret
    panic("could not find virtio disk");
    80005f28:	00003517          	auipc	a0,0x3
    80005f2c:	8d050513          	addi	a0,a0,-1840 # 800087f8 <syscalls+0x3d0>
    80005f30:	ffffa097          	auipc	ra,0xffffa
    80005f34:	616080e7          	jalr	1558(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	8e050513          	addi	a0,a0,-1824 # 80008818 <syscalls+0x3f0>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	606080e7          	jalr	1542(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	8f050513          	addi	a0,a0,-1808 # 80008838 <syscalls+0x410>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f6080e7          	jalr	1526(ra) # 80000546 <panic>

0000000080005f58 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f58:	7175                	addi	sp,sp,-144
    80005f5a:	e506                	sd	ra,136(sp)
    80005f5c:	e122                	sd	s0,128(sp)
    80005f5e:	fca6                	sd	s1,120(sp)
    80005f60:	f8ca                	sd	s2,112(sp)
    80005f62:	f4ce                	sd	s3,104(sp)
    80005f64:	f0d2                	sd	s4,96(sp)
    80005f66:	ecd6                	sd	s5,88(sp)
    80005f68:	e8da                	sd	s6,80(sp)
    80005f6a:	e4de                	sd	s7,72(sp)
    80005f6c:	e0e2                	sd	s8,64(sp)
    80005f6e:	fc66                	sd	s9,56(sp)
    80005f70:	f86a                	sd	s10,48(sp)
    80005f72:	f46e                	sd	s11,40(sp)
    80005f74:	0900                	addi	s0,sp,144
    80005f76:	8aaa                	mv	s5,a0
    80005f78:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f7a:	00c52c83          	lw	s9,12(a0)
    80005f7e:	001c9c9b          	slliw	s9,s9,0x1
    80005f82:	1c82                	slli	s9,s9,0x20
    80005f84:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f88:	0001f517          	auipc	a0,0x1f
    80005f8c:	12050513          	addi	a0,a0,288 # 800250a8 <disk+0x20a8>
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	c70080e7          	jalr	-912(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80005f98:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f9a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f9c:	0001dc17          	auipc	s8,0x1d
    80005fa0:	064c0c13          	addi	s8,s8,100 # 80023000 <disk>
    80005fa4:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005fa6:	4b0d                	li	s6,3
    80005fa8:	a0ad                	j	80006012 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005faa:	00fc0733          	add	a4,s8,a5
    80005fae:	975e                	add	a4,a4,s7
    80005fb0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fb4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fb6:	0207c563          	bltz	a5,80005fe0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fba:	2905                	addiw	s2,s2,1
    80005fbc:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005fbe:	19690c63          	beq	s2,s6,80006156 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005fc2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fc4:	0001f717          	auipc	a4,0x1f
    80005fc8:	05470713          	addi	a4,a4,84 # 80025018 <disk+0x2018>
    80005fcc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fce:	00074683          	lbu	a3,0(a4)
    80005fd2:	fee1                	bnez	a3,80005faa <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fd4:	2785                	addiw	a5,a5,1
    80005fd6:	0705                	addi	a4,a4,1
    80005fd8:	fe979be3          	bne	a5,s1,80005fce <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fdc:	57fd                	li	a5,-1
    80005fde:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fe0:	01205d63          	blez	s2,80005ffa <virtio_disk_rw+0xa2>
    80005fe4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005fe6:	000a2503          	lw	a0,0(s4)
    80005fea:	00000097          	auipc	ra,0x0
    80005fee:	dac080e7          	jalr	-596(ra) # 80005d96 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff2:	2d85                	addiw	s11,s11,1
    80005ff4:	0a11                	addi	s4,s4,4
    80005ff6:	ff2d98e3          	bne	s11,s2,80005fe6 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ffa:	0001f597          	auipc	a1,0x1f
    80005ffe:	0ae58593          	addi	a1,a1,174 # 800250a8 <disk+0x20a8>
    80006002:	0001f517          	auipc	a0,0x1f
    80006006:	01650513          	addi	a0,a0,22 # 80025018 <disk+0x2018>
    8000600a:	ffffc097          	auipc	ra,0xffffc
    8000600e:	204080e7          	jalr	516(ra) # 8000220e <sleep>
  for(int i = 0; i < 3; i++){
    80006012:	f8040a13          	addi	s4,s0,-128
{
    80006016:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006018:	894e                	mv	s2,s3
    8000601a:	b765                	j	80005fc2 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000601c:	0001f717          	auipc	a4,0x1f
    80006020:	fe473703          	ld	a4,-28(a4) # 80025000 <disk+0x2000>
    80006024:	973e                	add	a4,a4,a5
    80006026:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000602a:	0001d517          	auipc	a0,0x1d
    8000602e:	fd650513          	addi	a0,a0,-42 # 80023000 <disk>
    80006032:	0001f717          	auipc	a4,0x1f
    80006036:	fce70713          	addi	a4,a4,-50 # 80025000 <disk+0x2000>
    8000603a:	6314                	ld	a3,0(a4)
    8000603c:	96be                	add	a3,a3,a5
    8000603e:	00c6d603          	lhu	a2,12(a3)
    80006042:	00166613          	ori	a2,a2,1
    80006046:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000604a:	f8842683          	lw	a3,-120(s0)
    8000604e:	6310                	ld	a2,0(a4)
    80006050:	97b2                	add	a5,a5,a2
    80006052:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80006056:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000605a:	0612                	slli	a2,a2,0x4
    8000605c:	962a                	add	a2,a2,a0
    8000605e:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006062:	00469793          	slli	a5,a3,0x4
    80006066:	630c                	ld	a1,0(a4)
    80006068:	95be                	add	a1,a1,a5
    8000606a:	6689                	lui	a3,0x2
    8000606c:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006070:	96ca                	add	a3,a3,s2
    80006072:	96aa                	add	a3,a3,a0
    80006074:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006076:	6314                	ld	a3,0(a4)
    80006078:	96be                	add	a3,a3,a5
    8000607a:	4585                	li	a1,1
    8000607c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000607e:	6314                	ld	a3,0(a4)
    80006080:	96be                	add	a3,a3,a5
    80006082:	4509                	li	a0,2
    80006084:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006088:	6314                	ld	a3,0(a4)
    8000608a:	97b6                	add	a5,a5,a3
    8000608c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006090:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006094:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006098:	6714                	ld	a3,8(a4)
    8000609a:	0026d783          	lhu	a5,2(a3)
    8000609e:	8b9d                	andi	a5,a5,7
    800060a0:	0789                	addi	a5,a5,2
    800060a2:	0786                	slli	a5,a5,0x1
    800060a4:	96be                	add	a3,a3,a5
    800060a6:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    800060aa:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800060ae:	6718                	ld	a4,8(a4)
    800060b0:	00275783          	lhu	a5,2(a4)
    800060b4:	2785                	addiw	a5,a5,1
    800060b6:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060ba:	100017b7          	lui	a5,0x10001
    800060be:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800060c2:	004aa783          	lw	a5,4(s5)
    800060c6:	02b79163          	bne	a5,a1,800060e8 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800060ca:	0001f917          	auipc	s2,0x1f
    800060ce:	fde90913          	addi	s2,s2,-34 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800060d2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800060d4:	85ca                	mv	a1,s2
    800060d6:	8556                	mv	a0,s5
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	136080e7          	jalr	310(ra) # 8000220e <sleep>
  while(b->disk == 1) {
    800060e0:	004aa783          	lw	a5,4(s5)
    800060e4:	fe9788e3          	beq	a5,s1,800060d4 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800060e8:	f8042483          	lw	s1,-128(s0)
    800060ec:	20048713          	addi	a4,s1,512
    800060f0:	0712                	slli	a4,a4,0x4
    800060f2:	0001d797          	auipc	a5,0x1d
    800060f6:	f0e78793          	addi	a5,a5,-242 # 80023000 <disk>
    800060fa:	97ba                	add	a5,a5,a4
    800060fc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006100:	0001f917          	auipc	s2,0x1f
    80006104:	f0090913          	addi	s2,s2,-256 # 80025000 <disk+0x2000>
    80006108:	a019                	j	8000610e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000610a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000610e:	8526                	mv	a0,s1
    80006110:	00000097          	auipc	ra,0x0
    80006114:	c86080e7          	jalr	-890(ra) # 80005d96 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006118:	0492                	slli	s1,s1,0x4
    8000611a:	00093783          	ld	a5,0(s2)
    8000611e:	97a6                	add	a5,a5,s1
    80006120:	00c7d703          	lhu	a4,12(a5)
    80006124:	8b05                	andi	a4,a4,1
    80006126:	f375                	bnez	a4,8000610a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006128:	0001f517          	auipc	a0,0x1f
    8000612c:	f8050513          	addi	a0,a0,-128 # 800250a8 <disk+0x20a8>
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	b84080e7          	jalr	-1148(ra) # 80000cb4 <release>
}
    80006138:	60aa                	ld	ra,136(sp)
    8000613a:	640a                	ld	s0,128(sp)
    8000613c:	74e6                	ld	s1,120(sp)
    8000613e:	7946                	ld	s2,112(sp)
    80006140:	79a6                	ld	s3,104(sp)
    80006142:	7a06                	ld	s4,96(sp)
    80006144:	6ae6                	ld	s5,88(sp)
    80006146:	6b46                	ld	s6,80(sp)
    80006148:	6ba6                	ld	s7,72(sp)
    8000614a:	6c06                	ld	s8,64(sp)
    8000614c:	7ce2                	ld	s9,56(sp)
    8000614e:	7d42                	ld	s10,48(sp)
    80006150:	7da2                	ld	s11,40(sp)
    80006152:	6149                	addi	sp,sp,144
    80006154:	8082                	ret
  if(write)
    80006156:	01a037b3          	snez	a5,s10
    8000615a:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    8000615e:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006162:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006166:	f8042483          	lw	s1,-128(s0)
    8000616a:	00449913          	slli	s2,s1,0x4
    8000616e:	0001f997          	auipc	s3,0x1f
    80006172:	e9298993          	addi	s3,s3,-366 # 80025000 <disk+0x2000>
    80006176:	0009ba03          	ld	s4,0(s3)
    8000617a:	9a4a                	add	s4,s4,s2
    8000617c:	f7040513          	addi	a0,s0,-144
    80006180:	ffffb097          	auipc	ra,0xffffb
    80006184:	f54080e7          	jalr	-172(ra) # 800010d4 <kvmpa>
    80006188:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000618c:	0009b783          	ld	a5,0(s3)
    80006190:	97ca                	add	a5,a5,s2
    80006192:	4741                	li	a4,16
    80006194:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006196:	0009b783          	ld	a5,0(s3)
    8000619a:	97ca                	add	a5,a5,s2
    8000619c:	4705                	li	a4,1
    8000619e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061a2:	f8442783          	lw	a5,-124(s0)
    800061a6:	0009b703          	ld	a4,0(s3)
    800061aa:	974a                	add	a4,a4,s2
    800061ac:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800061b0:	0792                	slli	a5,a5,0x4
    800061b2:	0009b703          	ld	a4,0(s3)
    800061b6:	973e                	add	a4,a4,a5
    800061b8:	058a8693          	addi	a3,s5,88
    800061bc:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800061be:	0009b703          	ld	a4,0(s3)
    800061c2:	973e                	add	a4,a4,a5
    800061c4:	40000693          	li	a3,1024
    800061c8:	c714                	sw	a3,8(a4)
  if(write)
    800061ca:	e40d19e3          	bnez	s10,8000601c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ce:	0001f717          	auipc	a4,0x1f
    800061d2:	e3273703          	ld	a4,-462(a4) # 80025000 <disk+0x2000>
    800061d6:	973e                	add	a4,a4,a5
    800061d8:	4689                	li	a3,2
    800061da:	00d71623          	sh	a3,12(a4)
    800061de:	b5b1                	j	8000602a <virtio_disk_rw+0xd2>

00000000800061e0 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061e0:	1101                	addi	sp,sp,-32
    800061e2:	ec06                	sd	ra,24(sp)
    800061e4:	e822                	sd	s0,16(sp)
    800061e6:	e426                	sd	s1,8(sp)
    800061e8:	e04a                	sd	s2,0(sp)
    800061ea:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800061ec:	0001f517          	auipc	a0,0x1f
    800061f0:	ebc50513          	addi	a0,a0,-324 # 800250a8 <disk+0x20a8>
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	a0c080e7          	jalr	-1524(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061fc:	0001f717          	auipc	a4,0x1f
    80006200:	e0470713          	addi	a4,a4,-508 # 80025000 <disk+0x2000>
    80006204:	02075783          	lhu	a5,32(a4)
    80006208:	6b18                	ld	a4,16(a4)
    8000620a:	00275683          	lhu	a3,2(a4)
    8000620e:	8ebd                	xor	a3,a3,a5
    80006210:	8a9d                	andi	a3,a3,7
    80006212:	cab9                	beqz	a3,80006268 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006214:	0001d917          	auipc	s2,0x1d
    80006218:	dec90913          	addi	s2,s2,-532 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000621c:	0001f497          	auipc	s1,0x1f
    80006220:	de448493          	addi	s1,s1,-540 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006224:	078e                	slli	a5,a5,0x3
    80006226:	973e                	add	a4,a4,a5
    80006228:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    8000622a:	20078713          	addi	a4,a5,512
    8000622e:	0712                	slli	a4,a4,0x4
    80006230:	974a                	add	a4,a4,s2
    80006232:	03074703          	lbu	a4,48(a4)
    80006236:	ef21                	bnez	a4,8000628e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006238:	20078793          	addi	a5,a5,512
    8000623c:	0792                	slli	a5,a5,0x4
    8000623e:	97ca                	add	a5,a5,s2
    80006240:	7798                	ld	a4,40(a5)
    80006242:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006246:	7788                	ld	a0,40(a5)
    80006248:	ffffc097          	auipc	ra,0xffffc
    8000624c:	146080e7          	jalr	326(ra) # 8000238e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006250:	0204d783          	lhu	a5,32(s1)
    80006254:	2785                	addiw	a5,a5,1
    80006256:	8b9d                	andi	a5,a5,7
    80006258:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000625c:	6898                	ld	a4,16(s1)
    8000625e:	00275683          	lhu	a3,2(a4)
    80006262:	8a9d                	andi	a3,a3,7
    80006264:	fcf690e3          	bne	a3,a5,80006224 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006268:	10001737          	lui	a4,0x10001
    8000626c:	533c                	lw	a5,96(a4)
    8000626e:	8b8d                	andi	a5,a5,3
    80006270:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006272:	0001f517          	auipc	a0,0x1f
    80006276:	e3650513          	addi	a0,a0,-458 # 800250a8 <disk+0x20a8>
    8000627a:	ffffb097          	auipc	ra,0xffffb
    8000627e:	a3a080e7          	jalr	-1478(ra) # 80000cb4 <release>
}
    80006282:	60e2                	ld	ra,24(sp)
    80006284:	6442                	ld	s0,16(sp)
    80006286:	64a2                	ld	s1,8(sp)
    80006288:	6902                	ld	s2,0(sp)
    8000628a:	6105                	addi	sp,sp,32
    8000628c:	8082                	ret
      panic("virtio_disk_intr status");
    8000628e:	00002517          	auipc	a0,0x2
    80006292:	5ca50513          	addi	a0,a0,1482 # 80008858 <syscalls+0x430>
    80006296:	ffffa097          	auipc	ra,0xffffa
    8000629a:	2b0080e7          	jalr	688(ra) # 80000546 <panic>

000000008000629e <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000629e:	7179                	addi	sp,sp,-48
    800062a0:	f406                	sd	ra,40(sp)
    800062a2:	f022                	sd	s0,32(sp)
    800062a4:	ec26                	sd	s1,24(sp)
    800062a6:	e84a                	sd	s2,16(sp)
    800062a8:	e44e                	sd	s3,8(sp)
    800062aa:	e052                	sd	s4,0(sp)
    800062ac:	1800                	addi	s0,sp,48
    800062ae:	892a                	mv	s2,a0
    800062b0:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800062b2:	00003a17          	auipc	s4,0x3
    800062b6:	d76a0a13          	addi	s4,s4,-650 # 80009028 <stats>
    800062ba:	000a2683          	lw	a3,0(s4)
    800062be:	00002617          	auipc	a2,0x2
    800062c2:	5b260613          	addi	a2,a2,1458 # 80008870 <syscalls+0x448>
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	2c6080e7          	jalr	710(ra) # 8000658c <snprintf>
    800062ce:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800062d0:	004a2683          	lw	a3,4(s4)
    800062d4:	00002617          	auipc	a2,0x2
    800062d8:	5ac60613          	addi	a2,a2,1452 # 80008880 <syscalls+0x458>
    800062dc:	85ce                	mv	a1,s3
    800062de:	954a                	add	a0,a0,s2
    800062e0:	00000097          	auipc	ra,0x0
    800062e4:	2ac080e7          	jalr	684(ra) # 8000658c <snprintf>
  return n;
}
    800062e8:	9d25                	addw	a0,a0,s1
    800062ea:	70a2                	ld	ra,40(sp)
    800062ec:	7402                	ld	s0,32(sp)
    800062ee:	64e2                	ld	s1,24(sp)
    800062f0:	6942                	ld	s2,16(sp)
    800062f2:	69a2                	ld	s3,8(sp)
    800062f4:	6a02                	ld	s4,0(sp)
    800062f6:	6145                	addi	sp,sp,48
    800062f8:	8082                	ret

00000000800062fa <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800062fa:	7179                	addi	sp,sp,-48
    800062fc:	f406                	sd	ra,40(sp)
    800062fe:	f022                	sd	s0,32(sp)
    80006300:	ec26                	sd	s1,24(sp)
    80006302:	e84a                	sd	s2,16(sp)
    80006304:	e44e                	sd	s3,8(sp)
    80006306:	1800                	addi	s0,sp,48
    80006308:	89ae                	mv	s3,a1
    8000630a:	84b2                	mv	s1,a2
    8000630c:	8936                	mv	s2,a3
  struct proc *p = myproc();
    8000630e:	ffffb097          	auipc	ra,0xffffb
    80006312:	6ec080e7          	jalr	1772(ra) # 800019fa <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006316:	653c                	ld	a5,72(a0)
    80006318:	02f4ff63          	bgeu	s1,a5,80006356 <copyin_new+0x5c>
    8000631c:	01248733          	add	a4,s1,s2
    80006320:	02f77d63          	bgeu	a4,a5,8000635a <copyin_new+0x60>
    80006324:	02976d63          	bltu	a4,s1,8000635e <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    80006328:	0009061b          	sext.w	a2,s2
    8000632c:	85a6                	mv	a1,s1
    8000632e:	854e                	mv	a0,s3
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	a28080e7          	jalr	-1496(ra) # 80000d58 <memmove>
  stats.ncopyin++;   // XXX lock
    80006338:	00003717          	auipc	a4,0x3
    8000633c:	cf070713          	addi	a4,a4,-784 # 80009028 <stats>
    80006340:	431c                	lw	a5,0(a4)
    80006342:	2785                	addiw	a5,a5,1
    80006344:	c31c                	sw	a5,0(a4)
  return 0;
    80006346:	4501                	li	a0,0
}
    80006348:	70a2                	ld	ra,40(sp)
    8000634a:	7402                	ld	s0,32(sp)
    8000634c:	64e2                	ld	s1,24(sp)
    8000634e:	6942                	ld	s2,16(sp)
    80006350:	69a2                	ld	s3,8(sp)
    80006352:	6145                	addi	sp,sp,48
    80006354:	8082                	ret
    return -1;
    80006356:	557d                	li	a0,-1
    80006358:	bfc5                	j	80006348 <copyin_new+0x4e>
    8000635a:	557d                	li	a0,-1
    8000635c:	b7f5                	j	80006348 <copyin_new+0x4e>
    8000635e:	557d                	li	a0,-1
    80006360:	b7e5                	j	80006348 <copyin_new+0x4e>

0000000080006362 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006362:	7179                	addi	sp,sp,-48
    80006364:	f406                	sd	ra,40(sp)
    80006366:	f022                	sd	s0,32(sp)
    80006368:	ec26                	sd	s1,24(sp)
    8000636a:	e84a                	sd	s2,16(sp)
    8000636c:	e44e                	sd	s3,8(sp)
    8000636e:	1800                	addi	s0,sp,48
    80006370:	89ae                	mv	s3,a1
    80006372:	8932                	mv	s2,a2
    80006374:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006376:	ffffb097          	auipc	ra,0xffffb
    8000637a:	684080e7          	jalr	1668(ra) # 800019fa <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    8000637e:	00003717          	auipc	a4,0x3
    80006382:	caa70713          	addi	a4,a4,-854 # 80009028 <stats>
    80006386:	435c                	lw	a5,4(a4)
    80006388:	2785                	addiw	a5,a5,1
    8000638a:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000638c:	cc8d                	beqz	s1,800063c6 <copyinstr_new+0x64>
    8000638e:	009906b3          	add	a3,s2,s1
    80006392:	87ca                	mv	a5,s2
    80006394:	6538                	ld	a4,72(a0)
    80006396:	02e7f063          	bgeu	a5,a4,800063b6 <copyinstr_new+0x54>
    dst[i] = s[i];
    8000639a:	0007c803          	lbu	a6,0(a5)
    8000639e:	41278733          	sub	a4,a5,s2
    800063a2:	974e                	add	a4,a4,s3
    800063a4:	01070023          	sb	a6,0(a4)
    if(s[i] == '\0')
    800063a8:	02080163          	beqz	a6,800063ca <copyinstr_new+0x68>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800063ac:	0785                	addi	a5,a5,1
    800063ae:	fed793e3          	bne	a5,a3,80006394 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800063b2:	557d                	li	a0,-1
    800063b4:	a011                	j	800063b8 <copyinstr_new+0x56>
    800063b6:	557d                	li	a0,-1
}
    800063b8:	70a2                	ld	ra,40(sp)
    800063ba:	7402                	ld	s0,32(sp)
    800063bc:	64e2                	ld	s1,24(sp)
    800063be:	6942                	ld	s2,16(sp)
    800063c0:	69a2                	ld	s3,8(sp)
    800063c2:	6145                	addi	sp,sp,48
    800063c4:	8082                	ret
  return -1;
    800063c6:	557d                	li	a0,-1
    800063c8:	bfc5                	j	800063b8 <copyinstr_new+0x56>
      return 0;
    800063ca:	4501                	li	a0,0
    800063cc:	b7f5                	j	800063b8 <copyinstr_new+0x56>

00000000800063ce <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800063ce:	1141                	addi	sp,sp,-16
    800063d0:	e422                	sd	s0,8(sp)
    800063d2:	0800                	addi	s0,sp,16
  return -1;
}
    800063d4:	557d                	li	a0,-1
    800063d6:	6422                	ld	s0,8(sp)
    800063d8:	0141                	addi	sp,sp,16
    800063da:	8082                	ret

00000000800063dc <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800063dc:	7179                	addi	sp,sp,-48
    800063de:	f406                	sd	ra,40(sp)
    800063e0:	f022                	sd	s0,32(sp)
    800063e2:	ec26                	sd	s1,24(sp)
    800063e4:	e84a                	sd	s2,16(sp)
    800063e6:	e44e                	sd	s3,8(sp)
    800063e8:	e052                	sd	s4,0(sp)
    800063ea:	1800                	addi	s0,sp,48
    800063ec:	892a                	mv	s2,a0
    800063ee:	89ae                	mv	s3,a1
    800063f0:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800063f2:	00020517          	auipc	a0,0x20
    800063f6:	c0e50513          	addi	a0,a0,-1010 # 80026000 <stats>
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	806080e7          	jalr	-2042(ra) # 80000c00 <acquire>

  if(stats.sz == 0) {
    80006402:	00021797          	auipc	a5,0x21
    80006406:	c167a783          	lw	a5,-1002(a5) # 80027018 <stats+0x1018>
    8000640a:	cbb5                	beqz	a5,8000647e <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    8000640c:	00021797          	auipc	a5,0x21
    80006410:	bf478793          	addi	a5,a5,-1036 # 80027000 <stats+0x1000>
    80006414:	4fd8                	lw	a4,28(a5)
    80006416:	4f9c                	lw	a5,24(a5)
    80006418:	9f99                	subw	a5,a5,a4
    8000641a:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    8000641e:	06d05e63          	blez	a3,8000649a <statsread+0xbe>
    if(m > n)
    80006422:	8a3e                	mv	s4,a5
    80006424:	00d4d363          	bge	s1,a3,8000642a <statsread+0x4e>
    80006428:	8a26                	mv	s4,s1
    8000642a:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    8000642e:	86a6                	mv	a3,s1
    80006430:	00020617          	auipc	a2,0x20
    80006434:	be860613          	addi	a2,a2,-1048 # 80026018 <stats+0x18>
    80006438:	963a                	add	a2,a2,a4
    8000643a:	85ce                	mv	a1,s3
    8000643c:	854a                	mv	a0,s2
    8000643e:	ffffc097          	auipc	ra,0xffffc
    80006442:	02a080e7          	jalr	42(ra) # 80002468 <either_copyout>
    80006446:	57fd                	li	a5,-1
    80006448:	00f50a63          	beq	a0,a5,8000645c <statsread+0x80>
      stats.off += m;
    8000644c:	00021717          	auipc	a4,0x21
    80006450:	bb470713          	addi	a4,a4,-1100 # 80027000 <stats+0x1000>
    80006454:	4f5c                	lw	a5,28(a4)
    80006456:	00fa07bb          	addw	a5,s4,a5
    8000645a:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    8000645c:	00020517          	auipc	a0,0x20
    80006460:	ba450513          	addi	a0,a0,-1116 # 80026000 <stats>
    80006464:	ffffb097          	auipc	ra,0xffffb
    80006468:	850080e7          	jalr	-1968(ra) # 80000cb4 <release>
  return m;
}
    8000646c:	8526                	mv	a0,s1
    8000646e:	70a2                	ld	ra,40(sp)
    80006470:	7402                	ld	s0,32(sp)
    80006472:	64e2                	ld	s1,24(sp)
    80006474:	6942                	ld	s2,16(sp)
    80006476:	69a2                	ld	s3,8(sp)
    80006478:	6a02                	ld	s4,0(sp)
    8000647a:	6145                	addi	sp,sp,48
    8000647c:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    8000647e:	6585                	lui	a1,0x1
    80006480:	00020517          	auipc	a0,0x20
    80006484:	b9850513          	addi	a0,a0,-1128 # 80026018 <stats+0x18>
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	e16080e7          	jalr	-490(ra) # 8000629e <statscopyin>
    80006490:	00021797          	auipc	a5,0x21
    80006494:	b8a7a423          	sw	a0,-1144(a5) # 80027018 <stats+0x1018>
    80006498:	bf95                	j	8000640c <statsread+0x30>
    stats.sz = 0;
    8000649a:	00021797          	auipc	a5,0x21
    8000649e:	b6678793          	addi	a5,a5,-1178 # 80027000 <stats+0x1000>
    800064a2:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800064a6:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800064aa:	54fd                	li	s1,-1
    800064ac:	bf45                	j	8000645c <statsread+0x80>

00000000800064ae <statsinit>:

void
statsinit(void)
{
    800064ae:	1141                	addi	sp,sp,-16
    800064b0:	e406                	sd	ra,8(sp)
    800064b2:	e022                	sd	s0,0(sp)
    800064b4:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800064b6:	00002597          	auipc	a1,0x2
    800064ba:	3da58593          	addi	a1,a1,986 # 80008890 <syscalls+0x468>
    800064be:	00020517          	auipc	a0,0x20
    800064c2:	b4250513          	addi	a0,a0,-1214 # 80026000 <stats>
    800064c6:	ffffa097          	auipc	ra,0xffffa
    800064ca:	6aa080e7          	jalr	1706(ra) # 80000b70 <initlock>

  devsw[STATS].read = statsread;
    800064ce:	0001b797          	auipc	a5,0x1b
    800064d2:	4e278793          	addi	a5,a5,1250 # 800219b0 <devsw>
    800064d6:	00000717          	auipc	a4,0x0
    800064da:	f0670713          	addi	a4,a4,-250 # 800063dc <statsread>
    800064de:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800064e0:	00000717          	auipc	a4,0x0
    800064e4:	eee70713          	addi	a4,a4,-274 # 800063ce <statswrite>
    800064e8:	f798                	sd	a4,40(a5)
}
    800064ea:	60a2                	ld	ra,8(sp)
    800064ec:	6402                	ld	s0,0(sp)
    800064ee:	0141                	addi	sp,sp,16
    800064f0:	8082                	ret

00000000800064f2 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800064f2:	1101                	addi	sp,sp,-32
    800064f4:	ec22                	sd	s0,24(sp)
    800064f6:	1000                	addi	s0,sp,32
    800064f8:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800064fa:	c299                	beqz	a3,80006500 <sprintint+0xe>
    800064fc:	0805c263          	bltz	a1,80006580 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    80006500:	2581                	sext.w	a1,a1
    80006502:	4301                	li	t1,0

  i = 0;
    80006504:	fe040713          	addi	a4,s0,-32
    80006508:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000650a:	2601                	sext.w	a2,a2
    8000650c:	00002697          	auipc	a3,0x2
    80006510:	38c68693          	addi	a3,a3,908 # 80008898 <digits>
    80006514:	88aa                	mv	a7,a0
    80006516:	2505                	addiw	a0,a0,1
    80006518:	02c5f7bb          	remuw	a5,a1,a2
    8000651c:	1782                	slli	a5,a5,0x20
    8000651e:	9381                	srli	a5,a5,0x20
    80006520:	97b6                	add	a5,a5,a3
    80006522:	0007c783          	lbu	a5,0(a5)
    80006526:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000652a:	0005879b          	sext.w	a5,a1
    8000652e:	02c5d5bb          	divuw	a1,a1,a2
    80006532:	0705                	addi	a4,a4,1
    80006534:	fec7f0e3          	bgeu	a5,a2,80006514 <sprintint+0x22>

  if(sign)
    80006538:	00030b63          	beqz	t1,8000654e <sprintint+0x5c>
    buf[i++] = '-';
    8000653c:	ff050793          	addi	a5,a0,-16
    80006540:	97a2                	add	a5,a5,s0
    80006542:	02d00713          	li	a4,45
    80006546:	fee78823          	sb	a4,-16(a5)
    8000654a:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    8000654e:	02a05d63          	blez	a0,80006588 <sprintint+0x96>
    80006552:	fe040793          	addi	a5,s0,-32
    80006556:	00a78733          	add	a4,a5,a0
    8000655a:	87c2                	mv	a5,a6
    8000655c:	00180613          	addi	a2,a6,1
    80006560:	fff5069b          	addiw	a3,a0,-1
    80006564:	1682                	slli	a3,a3,0x20
    80006566:	9281                	srli	a3,a3,0x20
    80006568:	9636                	add	a2,a2,a3
  *s = c;
    8000656a:	fff74683          	lbu	a3,-1(a4)
    8000656e:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006572:	177d                	addi	a4,a4,-1
    80006574:	0785                	addi	a5,a5,1
    80006576:	fec79ae3          	bne	a5,a2,8000656a <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000657a:	6462                	ld	s0,24(sp)
    8000657c:	6105                	addi	sp,sp,32
    8000657e:	8082                	ret
    x = -xx;
    80006580:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006584:	4305                	li	t1,1
    x = -xx;
    80006586:	bfbd                	j	80006504 <sprintint+0x12>
  while(--i >= 0)
    80006588:	4501                	li	a0,0
    8000658a:	bfc5                	j	8000657a <sprintint+0x88>

000000008000658c <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000658c:	7135                	addi	sp,sp,-160
    8000658e:	f486                	sd	ra,104(sp)
    80006590:	f0a2                	sd	s0,96(sp)
    80006592:	eca6                	sd	s1,88(sp)
    80006594:	e8ca                	sd	s2,80(sp)
    80006596:	e4ce                	sd	s3,72(sp)
    80006598:	e0d2                	sd	s4,64(sp)
    8000659a:	fc56                	sd	s5,56(sp)
    8000659c:	f85a                	sd	s6,48(sp)
    8000659e:	f45e                	sd	s7,40(sp)
    800065a0:	f062                	sd	s8,32(sp)
    800065a2:	ec66                	sd	s9,24(sp)
    800065a4:	e86a                	sd	s10,16(sp)
    800065a6:	1880                	addi	s0,sp,112
    800065a8:	e414                	sd	a3,8(s0)
    800065aa:	e818                	sd	a4,16(s0)
    800065ac:	ec1c                	sd	a5,24(s0)
    800065ae:	03043023          	sd	a6,32(s0)
    800065b2:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800065b6:	c61d                	beqz	a2,800065e4 <snprintf+0x58>
    800065b8:	8baa                	mv	s7,a0
    800065ba:	89ae                	mv	s3,a1
    800065bc:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800065be:	00840793          	addi	a5,s0,8
    800065c2:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    800065c6:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800065c8:	4901                	li	s2,0
    800065ca:	02b05563          	blez	a1,800065f4 <snprintf+0x68>
    if(c != '%'){
    800065ce:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800065d2:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800065d6:	02800d13          	li	s10,40
    switch(c){
    800065da:	07800c93          	li	s9,120
    800065de:	06400c13          	li	s8,100
    800065e2:	a01d                	j	80006608 <snprintf+0x7c>
    panic("null fmt");
    800065e4:	00002517          	auipc	a0,0x2
    800065e8:	a4450513          	addi	a0,a0,-1468 # 80008028 <etext+0x28>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	f5a080e7          	jalr	-166(ra) # 80000546 <panic>
  int off = 0;
    800065f4:	4481                	li	s1,0
    800065f6:	a875                	j	800066b2 <snprintf+0x126>
  *s = c;
    800065f8:	009b8733          	add	a4,s7,s1
    800065fc:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006600:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006602:	2905                	addiw	s2,s2,1
    80006604:	0b34d763          	bge	s1,s3,800066b2 <snprintf+0x126>
    80006608:	012a07b3          	add	a5,s4,s2
    8000660c:	0007c783          	lbu	a5,0(a5)
    80006610:	0007871b          	sext.w	a4,a5
    80006614:	cfd9                	beqz	a5,800066b2 <snprintf+0x126>
    if(c != '%'){
    80006616:	ff5711e3          	bne	a4,s5,800065f8 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    8000661a:	2905                	addiw	s2,s2,1
    8000661c:	012a07b3          	add	a5,s4,s2
    80006620:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006624:	c7d9                	beqz	a5,800066b2 <snprintf+0x126>
    switch(c){
    80006626:	05678c63          	beq	a5,s6,8000667e <snprintf+0xf2>
    8000662a:	02fb6763          	bltu	s6,a5,80006658 <snprintf+0xcc>
    8000662e:	0b578763          	beq	a5,s5,800066dc <snprintf+0x150>
    80006632:	0b879b63          	bne	a5,s8,800066e8 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006636:	f9843783          	ld	a5,-104(s0)
    8000663a:	00878713          	addi	a4,a5,8
    8000663e:	f8e43c23          	sd	a4,-104(s0)
    80006642:	4685                	li	a3,1
    80006644:	4629                	li	a2,10
    80006646:	438c                	lw	a1,0(a5)
    80006648:	009b8533          	add	a0,s7,s1
    8000664c:	00000097          	auipc	ra,0x0
    80006650:	ea6080e7          	jalr	-346(ra) # 800064f2 <sprintint>
    80006654:	9ca9                	addw	s1,s1,a0
      break;
    80006656:	b775                	j	80006602 <snprintf+0x76>
    switch(c){
    80006658:	09979863          	bne	a5,s9,800066e8 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    8000665c:	f9843783          	ld	a5,-104(s0)
    80006660:	00878713          	addi	a4,a5,8
    80006664:	f8e43c23          	sd	a4,-104(s0)
    80006668:	4685                	li	a3,1
    8000666a:	4641                	li	a2,16
    8000666c:	438c                	lw	a1,0(a5)
    8000666e:	009b8533          	add	a0,s7,s1
    80006672:	00000097          	auipc	ra,0x0
    80006676:	e80080e7          	jalr	-384(ra) # 800064f2 <sprintint>
    8000667a:	9ca9                	addw	s1,s1,a0
      break;
    8000667c:	b759                	j	80006602 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    8000667e:	f9843783          	ld	a5,-104(s0)
    80006682:	00878713          	addi	a4,a5,8
    80006686:	f8e43c23          	sd	a4,-104(s0)
    8000668a:	639c                	ld	a5,0(a5)
    8000668c:	c3b1                	beqz	a5,800066d0 <snprintf+0x144>
      for(; *s && off < sz; s++)
    8000668e:	0007c703          	lbu	a4,0(a5)
    80006692:	db25                	beqz	a4,80006602 <snprintf+0x76>
    80006694:	0734d563          	bge	s1,s3,800066fe <snprintf+0x172>
    80006698:	009b86b3          	add	a3,s7,s1
  *s = c;
    8000669c:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800066a0:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800066a2:	0785                	addi	a5,a5,1
    800066a4:	0007c703          	lbu	a4,0(a5)
    800066a8:	df29                	beqz	a4,80006602 <snprintf+0x76>
    800066aa:	0685                	addi	a3,a3,1
    800066ac:	fe9998e3          	bne	s3,s1,8000669c <snprintf+0x110>
  int off = 0;
    800066b0:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800066b2:	8526                	mv	a0,s1
    800066b4:	70a6                	ld	ra,104(sp)
    800066b6:	7406                	ld	s0,96(sp)
    800066b8:	64e6                	ld	s1,88(sp)
    800066ba:	6946                	ld	s2,80(sp)
    800066bc:	69a6                	ld	s3,72(sp)
    800066be:	6a06                	ld	s4,64(sp)
    800066c0:	7ae2                	ld	s5,56(sp)
    800066c2:	7b42                	ld	s6,48(sp)
    800066c4:	7ba2                	ld	s7,40(sp)
    800066c6:	7c02                	ld	s8,32(sp)
    800066c8:	6ce2                	ld	s9,24(sp)
    800066ca:	6d42                	ld	s10,16(sp)
    800066cc:	610d                	addi	sp,sp,160
    800066ce:	8082                	ret
        s = "(null)";
    800066d0:	00002797          	auipc	a5,0x2
    800066d4:	95078793          	addi	a5,a5,-1712 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800066d8:	876a                	mv	a4,s10
    800066da:	bf6d                	j	80006694 <snprintf+0x108>
  *s = c;
    800066dc:	009b87b3          	add	a5,s7,s1
    800066e0:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800066e4:	2485                	addiw	s1,s1,1
      break;
    800066e6:	bf31                	j	80006602 <snprintf+0x76>
  *s = c;
    800066e8:	009b8733          	add	a4,s7,s1
    800066ec:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800066f0:	0014871b          	addiw	a4,s1,1
  *s = c;
    800066f4:	975e                	add	a4,a4,s7
    800066f6:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800066fa:	2489                	addiw	s1,s1,2
      break;
    800066fc:	b719                	j	80006602 <snprintf+0x76>
      for(; *s && off < sz; s++)
    800066fe:	89a6                	mv	s3,s1
    80006700:	bf45                	j	800066b0 <snprintf+0x124>
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
