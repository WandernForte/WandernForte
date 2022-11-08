
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
    80000060:	fd478793          	addi	a5,a5,-44 # 80006030 <timervec>
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
    8000012a:	6cc080e7          	jalr	1740(ra) # 800027f2 <either_copyin>
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
    800001d0:	a42080e7          	jalr	-1470(ra) # 80001c0e <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	366080e7          	jalr	870(ra) # 80002542 <sleep>
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
    8000021c:	584080e7          	jalr	1412(ra) # 8000279c <either_copyout>
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
    800002fc:	550080e7          	jalr	1360(ra) # 80002848 <procdump>
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
    80000450:	276080e7          	jalr	630(ra) # 800026c2 <wakeup>
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
    800008aa:	e1c080e7          	jalr	-484(ra) # 800026c2 <wakeup>
    
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
    80000944:	c02080e7          	jalr	-1022(ra) # 80002542 <sleep>
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
    80000b9e:	058080e7          	jalr	88(ra) # 80001bf2 <mycpu>
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
    80000bd0:	026080e7          	jalr	38(ra) # 80001bf2 <mycpu>
    80000bd4:	5d3c                	lw	a5,120(a0)
    80000bd6:	cf89                	beqz	a5,80000bf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	01a080e7          	jalr	26(ra) # 80001bf2 <mycpu>
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
    80000bf4:	002080e7          	jalr	2(ra) # 80001bf2 <mycpu>
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
    80000c34:	fc2080e7          	jalr	-62(ra) # 80001bf2 <mycpu>
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
    80000c60:	f96080e7          	jalr	-106(ra) # 80001bf2 <mycpu>
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
    80000eb6:	d30080e7          	jalr	-720(ra) # 80001be2 <cpuid>
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
    80000ed2:	d14080e7          	jalr	-748(ra) # 80001be2 <cpuid>
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
    80000ef4:	a9a080e7          	jalr	-1382(ra) # 8000298a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef8:	00005097          	auipc	ra,0x5
    80000efc:	178080e7          	jalr	376(ra) # 80006070 <plicinithart>
  }

  scheduler();        
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	34a080e7          	jalr	842(ra) # 8000224a <scheduler>
    consoleinit();
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	54e080e7          	jalr	1358(ra) # 80000456 <consoleinit>
    statsinit();
    80000f10:	00006097          	auipc	ra,0x6
    80000f14:	926080e7          	jalr	-1754(ra) # 80006836 <statsinit>
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
    80000f6c:	ba0080e7          	jalr	-1120(ra) # 80001b08 <procinit>
    trapinit();      // trap vectors
    80000f70:	00002097          	auipc	ra,0x2
    80000f74:	9f2080e7          	jalr	-1550(ra) # 80002962 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	a12080e7          	jalr	-1518(ra) # 8000298a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	0da080e7          	jalr	218(ra) # 8000605a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f88:	00005097          	auipc	ra,0x5
    80000f8c:	0e8080e7          	jalr	232(ra) # 80006070 <plicinithart>
    binit();         // buffer cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	154080e7          	jalr	340(ra) # 800030e4 <binit>
    iinit();         // inode cache
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	7e2080e7          	jalr	2018(ra) # 8000377a <iinit>
    fileinit();      // file table
    80000fa0:	00003097          	auipc	ra,0x3
    80000fa4:	784080e7          	jalr	1924(ra) # 80004724 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	1ce080e7          	jalr	462(ra) # 80006176 <virtio_disk_init>
    userinit();      // first user process
    80000fb0:	00001097          	auipc	ra,0x1
    80000fb4:	fae080e7          	jalr	-82(ra) # 80001f5e <userinit>
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

000000008000161c <kvmdealloc>:
uint64
kvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000161c:	1101                	addi	sp,sp,-32
    8000161e:	ec06                	sd	ra,24(sp)
    80001620:	e822                	sd	s0,16(sp)
    80001622:	e426                	sd	s1,8(sp)
    80001624:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001626:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001628:	00b67d63          	bgeu	a2,a1,80001642 <kvmdealloc+0x26>
    8000162c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000162e:	6785                	lui	a5,0x1
    80001630:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001632:	00f60733          	add	a4,a2,a5
    80001636:	76fd                	lui	a3,0xfffff
    80001638:	8f75                	and	a4,a4,a3
    8000163a:	97ae                	add	a5,a5,a1
    8000163c:	8ff5                	and	a5,a5,a3
    8000163e:	00f76863          	bltu	a4,a5,8000164e <kvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);// no free
  }

  return newsz;
}
    80001642:	8526                	mv	a0,s1
    80001644:	60e2                	ld	ra,24(sp)
    80001646:	6442                	ld	s0,16(sp)
    80001648:	64a2                	ld	s1,8(sp)
    8000164a:	6105                	addi	sp,sp,32
    8000164c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000164e:	8f99                	sub	a5,a5,a4
    80001650:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);// no free
    80001652:	4681                	li	a3,0
    80001654:	0007861b          	sext.w	a2,a5
    80001658:	85ba                	mv	a1,a4
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	d6c080e7          	jalr	-660(ra) # 800013c6 <uvmunmap>
    80001662:	b7c5                	j	80001642 <kvmdealloc+0x26>

0000000080001664 <freewalk>:
// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001664:	7179                	addi	sp,sp,-48
    80001666:	f406                	sd	ra,40(sp)
    80001668:	f022                	sd	s0,32(sp)
    8000166a:	ec26                	sd	s1,24(sp)
    8000166c:	e84a                	sd	s2,16(sp)
    8000166e:	e44e                	sd	s3,8(sp)
    80001670:	e052                	sd	s4,0(sp)
    80001672:	1800                	addi	s0,sp,48
    80001674:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001676:	84aa                	mv	s1,a0
    80001678:	6905                	lui	s2,0x1
    8000167a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000167c:	4985                	li	s3,1
    8000167e:	a829                	j	80001698 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001680:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001682:	00c79513          	slli	a0,a5,0xc
    80001686:	00000097          	auipc	ra,0x0
    8000168a:	fde080e7          	jalr	-34(ra) # 80001664 <freewalk>
      pagetable[i] = 0;  
    8000168e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001692:	04a1                	addi	s1,s1,8
    80001694:	03248163          	beq	s1,s2,800016b6 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001698:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000169a:	00f7f713          	andi	a4,a5,15
    8000169e:	ff3701e3          	beq	a4,s3,80001680 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016a2:	8b85                	andi	a5,a5,1
    800016a4:	d7fd                	beqz	a5,80001692 <freewalk+0x2e>
      panic("freewalk: leaf");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	ac250513          	addi	a0,a0,-1342 # 80008168 <digits+0x128>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	e98080e7          	jalr	-360(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    800016b6:	8552                	mv	a0,s4
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	35a080e7          	jalr	858(ra) # 80000a12 <kfree>
}
    800016c0:	70a2                	ld	ra,40(sp)
    800016c2:	7402                	ld	s0,32(sp)
    800016c4:	64e2                	ld	s1,24(sp)
    800016c6:	6942                	ld	s2,16(sp)
    800016c8:	69a2                	ld	s3,8(sp)
    800016ca:	6a02                	ld	s4,0(sp)
    800016cc:	6145                	addi	sp,sp,48
    800016ce:	8082                	ret

00000000800016d0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016d0:	1101                	addi	sp,sp,-32
    800016d2:	ec06                	sd	ra,24(sp)
    800016d4:	e822                	sd	s0,16(sp)
    800016d6:	e426                	sd	s1,8(sp)
    800016d8:	1000                	addi	s0,sp,32
    800016da:	84aa                	mv	s1,a0
  if(sz > 0)
    800016dc:	e999                	bnez	a1,800016f2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016de:	8526                	mv	a0,s1
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	f84080e7          	jalr	-124(ra) # 80001664 <freewalk>
}
    800016e8:	60e2                	ld	ra,24(sp)
    800016ea:	6442                	ld	s0,16(sp)
    800016ec:	64a2                	ld	s1,8(sp)
    800016ee:	6105                	addi	sp,sp,32
    800016f0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016f2:	6785                	lui	a5,0x1
    800016f4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016f6:	95be                	add	a1,a1,a5
    800016f8:	4685                	li	a3,1
    800016fa:	00c5d613          	srli	a2,a1,0xc
    800016fe:	4581                	li	a1,0
    80001700:	00000097          	auipc	ra,0x0
    80001704:	cc6080e7          	jalr	-826(ra) # 800013c6 <uvmunmap>
    80001708:	bfd9                	j	800016de <uvmfree+0xe>

000000008000170a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000170a:	c679                	beqz	a2,800017d8 <uvmcopy+0xce>
{
    8000170c:	715d                	addi	sp,sp,-80
    8000170e:	e486                	sd	ra,72(sp)
    80001710:	e0a2                	sd	s0,64(sp)
    80001712:	fc26                	sd	s1,56(sp)
    80001714:	f84a                	sd	s2,48(sp)
    80001716:	f44e                	sd	s3,40(sp)
    80001718:	f052                	sd	s4,32(sp)
    8000171a:	ec56                	sd	s5,24(sp)
    8000171c:	e85a                	sd	s6,16(sp)
    8000171e:	e45e                	sd	s7,8(sp)
    80001720:	0880                	addi	s0,sp,80
    80001722:	8b2a                	mv	s6,a0
    80001724:	8aae                	mv	s5,a1
    80001726:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001728:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000172a:	4601                	li	a2,0
    8000172c:	85ce                	mv	a1,s3
    8000172e:	855a                	mv	a0,s6
    80001730:	00000097          	auipc	ra,0x0
    80001734:	8bc080e7          	jalr	-1860(ra) # 80000fec <walk>
    80001738:	c531                	beqz	a0,80001784 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000173a:	6118                	ld	a4,0(a0)
    8000173c:	00177793          	andi	a5,a4,1
    80001740:	cbb1                	beqz	a5,80001794 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001742:	00a75593          	srli	a1,a4,0xa
    80001746:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000174a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	3c2080e7          	jalr	962(ra) # 80000b10 <kalloc>
    80001756:	892a                	mv	s2,a0
    80001758:	c939                	beqz	a0,800017ae <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000175a:	6605                	lui	a2,0x1
    8000175c:	85de                	mv	a1,s7
    8000175e:	fffff097          	auipc	ra,0xfffff
    80001762:	5fa080e7          	jalr	1530(ra) # 80000d58 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001766:	8726                	mv	a4,s1
    80001768:	86ca                	mv	a3,s2
    8000176a:	6605                	lui	a2,0x1
    8000176c:	85ce                	mv	a1,s3
    8000176e:	8556                	mv	a0,s5
    80001770:	00000097          	auipc	ra,0x0
    80001774:	9c2080e7          	jalr	-1598(ra) # 80001132 <mappages>
    80001778:	e515                	bnez	a0,800017a4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000177a:	6785                	lui	a5,0x1
    8000177c:	99be                	add	s3,s3,a5
    8000177e:	fb49e6e3          	bltu	s3,s4,8000172a <uvmcopy+0x20>
    80001782:	a081                	j	800017c2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001784:	00007517          	auipc	a0,0x7
    80001788:	9f450513          	addi	a0,a0,-1548 # 80008178 <digits+0x138>
    8000178c:	fffff097          	auipc	ra,0xfffff
    80001790:	dba080e7          	jalr	-582(ra) # 80000546 <panic>
      panic("uvmcopy: page not present");
    80001794:	00007517          	auipc	a0,0x7
    80001798:	a0450513          	addi	a0,a0,-1532 # 80008198 <digits+0x158>
    8000179c:	fffff097          	auipc	ra,0xfffff
    800017a0:	daa080e7          	jalr	-598(ra) # 80000546 <panic>
      kfree(mem);
    800017a4:	854a                	mv	a0,s2
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	26c080e7          	jalr	620(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017ae:	4685                	li	a3,1
    800017b0:	00c9d613          	srli	a2,s3,0xc
    800017b4:	4581                	li	a1,0
    800017b6:	8556                	mv	a0,s5
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	c0e080e7          	jalr	-1010(ra) # 800013c6 <uvmunmap>
  return -1;
    800017c0:	557d                	li	a0,-1
}
    800017c2:	60a6                	ld	ra,72(sp)
    800017c4:	6406                	ld	s0,64(sp)
    800017c6:	74e2                	ld	s1,56(sp)
    800017c8:	7942                	ld	s2,48(sp)
    800017ca:	79a2                	ld	s3,40(sp)
    800017cc:	7a02                	ld	s4,32(sp)
    800017ce:	6ae2                	ld	s5,24(sp)
    800017d0:	6b42                	ld	s6,16(sp)
    800017d2:	6ba2                	ld	s7,8(sp)
    800017d4:	6161                	addi	sp,sp,80
    800017d6:	8082                	ret
  return 0;
    800017d8:	4501                	li	a0,0
}
    800017da:	8082                	ret

00000000800017dc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800017dc:	1141                	addi	sp,sp,-16
    800017de:	e406                	sd	ra,8(sp)
    800017e0:	e022                	sd	s0,0(sp)
    800017e2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800017e4:	4601                	li	a2,0
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	806080e7          	jalr	-2042(ra) # 80000fec <walk>
  if(pte == 0)
    800017ee:	c901                	beqz	a0,800017fe <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800017f0:	611c                	ld	a5,0(a0)
    800017f2:	9bbd                	andi	a5,a5,-17
    800017f4:	e11c                	sd	a5,0(a0)
}
    800017f6:	60a2                	ld	ra,8(sp)
    800017f8:	6402                	ld	s0,0(sp)
    800017fa:	0141                	addi	sp,sp,16
    800017fc:	8082                	ret
    panic("uvmclear");
    800017fe:	00007517          	auipc	a0,0x7
    80001802:	9ba50513          	addi	a0,a0,-1606 # 800081b8 <digits+0x178>
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	d40080e7          	jalr	-704(ra) # 80000546 <panic>

000000008000180e <upgtbl2kpgtbl>:
upgtbl2kpgtbl(pagetable_t upgtbl, pagetable_t kpgtbl, uint64 st, uint64 len){
    pte_t *pte;
    uint64 pa, i;
    uint flags;

    if (len > PLIC) return -1;
    8000180e:	0c0007b7          	lui	a5,0xc000
    80001812:	0ad7ed63          	bltu	a5,a3,800018cc <upgtbl2kpgtbl+0xbe>
upgtbl2kpgtbl(pagetable_t upgtbl, pagetable_t kpgtbl, uint64 st, uint64 len){
    80001816:	7179                	addi	sp,sp,-48
    80001818:	f406                	sd	ra,40(sp)
    8000181a:	f022                	sd	s0,32(sp)
    8000181c:	ec26                	sd	s1,24(sp)
    8000181e:	e84a                	sd	s2,16(sp)
    80001820:	e44e                	sd	s3,8(sp)
    80001822:	e052                	sd	s4,0(sp)
    80001824:	1800                	addi	s0,sp,48
    80001826:	89aa                	mv	s3,a0
    80001828:	8a2e                	mv	s4,a1

    st = PGROUNDUP(st);
    8000182a:	6785                	lui	a5,0x1
    8000182c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000182e:	963e                	add	a2,a2,a5
    80001830:	77fd                	lui	a5,0xfffff
    80001832:	00f674b3          	and	s1,a2,a5

    for(i = st; i < len; i += PGSIZE) {
    80001836:	08d4fd63          	bgeu	s1,a3,800018d0 <upgtbl2kpgtbl+0xc2>
    8000183a:	fff68913          	addi	s2,a3,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    8000183e:	40990933          	sub	s2,s2,s1
    80001842:	00f97933          	and	s2,s2,a5
    80001846:	6785                	lui	a5,0x1
    80001848:	97a6                	add	a5,a5,s1
    8000184a:	993e                	add	s2,s2,a5
        if((pte = walk(upgtbl, i, 0)) == 0)
    8000184c:	4601                	li	a2,0
    8000184e:	85a6                	mv	a1,s1
    80001850:	854e                	mv	a0,s3
    80001852:	fffff097          	auipc	ra,0xfffff
    80001856:	79a080e7          	jalr	1946(ra) # 80000fec <walk>
    8000185a:	c51d                	beqz	a0,80001888 <upgtbl2kpgtbl+0x7a>
            panic("kvmcopy: pte should exist");
        if((*pte & PTE_V) == 0)
    8000185c:	6118                	ld	a4,0(a0)
    8000185e:	00177793          	andi	a5,a4,1
    80001862:	cb9d                	beqz	a5,80001898 <upgtbl2kpgtbl+0x8a>
            panic("kvmcopy: page not present");
        pa = PTE2PA(*pte);
    80001864:	00a75693          	srli	a3,a4,0xa
        flags = PTE_FLAGS(*pte) & (~PTE_U);
        if(mappages(kpgtbl, i, PGSIZE, (uint64)pa, flags) != 0){
    80001868:	3ef77713          	andi	a4,a4,1007
    8000186c:	06b2                	slli	a3,a3,0xc
    8000186e:	6605                	lui	a2,0x1
    80001870:	85a6                	mv	a1,s1
    80001872:	8552                	mv	a0,s4
    80001874:	00000097          	auipc	ra,0x0
    80001878:	8be080e7          	jalr	-1858(ra) # 80001132 <mappages>
    8000187c:	e515                	bnez	a0,800018a8 <upgtbl2kpgtbl+0x9a>
    for(i = st; i < len; i += PGSIZE) {
    8000187e:	6785                	lui	a5,0x1
    80001880:	94be                	add	s1,s1,a5
    80001882:	fd2495e3          	bne	s1,s2,8000184c <upgtbl2kpgtbl+0x3e>
    80001886:	a81d                	j	800018bc <upgtbl2kpgtbl+0xae>
            panic("kvmcopy: pte should exist");
    80001888:	00007517          	auipc	a0,0x7
    8000188c:	94050513          	addi	a0,a0,-1728 # 800081c8 <digits+0x188>
    80001890:	fffff097          	auipc	ra,0xfffff
    80001894:	cb6080e7          	jalr	-842(ra) # 80000546 <panic>
            panic("kvmcopy: page not present");
    80001898:	00007517          	auipc	a0,0x7
    8000189c:	95050513          	addi	a0,a0,-1712 # 800081e8 <digits+0x1a8>
    800018a0:	fffff097          	auipc	ra,0xfffff
    800018a4:	ca6080e7          	jalr	-858(ra) # 80000546 <panic>
            uvmunmap(upgtbl, 0, i / PGSIZE, 0);
    800018a8:	4681                	li	a3,0
    800018aa:	00c4d613          	srli	a2,s1,0xc
    800018ae:	4581                	li	a1,0
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	b14080e7          	jalr	-1260(ra) # 800013c6 <uvmunmap>
            return -1;
    800018ba:	557d                	li	a0,-1
        }
    }
    return 0;
    
}
    800018bc:	70a2                	ld	ra,40(sp)
    800018be:	7402                	ld	s0,32(sp)
    800018c0:	64e2                	ld	s1,24(sp)
    800018c2:	6942                	ld	s2,16(sp)
    800018c4:	69a2                	ld	s3,8(sp)
    800018c6:	6a02                	ld	s4,0(sp)
    800018c8:	6145                	addi	sp,sp,48
    800018ca:	8082                	ret
    if (len > PLIC) return -1;
    800018cc:	557d                	li	a0,-1
}
    800018ce:	8082                	ret
    return 0;
    800018d0:	4501                	li	a0,0
    800018d2:	b7ed                	j	800018bc <upgtbl2kpgtbl+0xae>

00000000800018d4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018d4:	c6bd                	beqz	a3,80001942 <copyout+0x6e>
{
    800018d6:	715d                	addi	sp,sp,-80
    800018d8:	e486                	sd	ra,72(sp)
    800018da:	e0a2                	sd	s0,64(sp)
    800018dc:	fc26                	sd	s1,56(sp)
    800018de:	f84a                	sd	s2,48(sp)
    800018e0:	f44e                	sd	s3,40(sp)
    800018e2:	f052                	sd	s4,32(sp)
    800018e4:	ec56                	sd	s5,24(sp)
    800018e6:	e85a                	sd	s6,16(sp)
    800018e8:	e45e                	sd	s7,8(sp)
    800018ea:	e062                	sd	s8,0(sp)
    800018ec:	0880                	addi	s0,sp,80
    800018ee:	8b2a                	mv	s6,a0
    800018f0:	8c2e                	mv	s8,a1
    800018f2:	8a32                	mv	s4,a2
    800018f4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018f6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018f8:	6a85                	lui	s5,0x1
    800018fa:	a015                	j	8000191e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018fc:	9562                	add	a0,a0,s8
    800018fe:	0004861b          	sext.w	a2,s1
    80001902:	85d2                	mv	a1,s4
    80001904:	41250533          	sub	a0,a0,s2
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	450080e7          	jalr	1104(ra) # 80000d58 <memmove>

    len -= n;
    80001910:	409989b3          	sub	s3,s3,s1
    src += n;
    80001914:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001916:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000191a:	02098263          	beqz	s3,8000193e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000191e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001922:	85ca                	mv	a1,s2
    80001924:	855a                	mv	a0,s6
    80001926:	fffff097          	auipc	ra,0xfffff
    8000192a:	76c080e7          	jalr	1900(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    8000192e:	cd01                	beqz	a0,80001946 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001930:	418904b3          	sub	s1,s2,s8
    80001934:	94d6                	add	s1,s1,s5
    80001936:	fc99f3e3          	bgeu	s3,s1,800018fc <copyout+0x28>
    8000193a:	84ce                	mv	s1,s3
    8000193c:	b7c1                	j	800018fc <copyout+0x28>
  }
  return 0;
    8000193e:	4501                	li	a0,0
    80001940:	a021                	j	80001948 <copyout+0x74>
    80001942:	4501                	li	a0,0
}
    80001944:	8082                	ret
      return -1;
    80001946:	557d                	li	a0,-1
}
    80001948:	60a6                	ld	ra,72(sp)
    8000194a:	6406                	ld	s0,64(sp)
    8000194c:	74e2                	ld	s1,56(sp)
    8000194e:	7942                	ld	s2,48(sp)
    80001950:	79a2                	ld	s3,40(sp)
    80001952:	7a02                	ld	s4,32(sp)
    80001954:	6ae2                	ld	s5,24(sp)
    80001956:	6b42                	ld	s6,16(sp)
    80001958:	6ba2                	ld	s7,8(sp)
    8000195a:	6c02                	ld	s8,0(sp)
    8000195c:	6161                	addi	sp,sp,80
    8000195e:	8082                	ret

0000000080001960 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001960:	caa5                	beqz	a3,800019d0 <copyin+0x70>
{
    80001962:	715d                	addi	sp,sp,-80
    80001964:	e486                	sd	ra,72(sp)
    80001966:	e0a2                	sd	s0,64(sp)
    80001968:	fc26                	sd	s1,56(sp)
    8000196a:	f84a                	sd	s2,48(sp)
    8000196c:	f44e                	sd	s3,40(sp)
    8000196e:	f052                	sd	s4,32(sp)
    80001970:	ec56                	sd	s5,24(sp)
    80001972:	e85a                	sd	s6,16(sp)
    80001974:	e45e                	sd	s7,8(sp)
    80001976:	e062                	sd	s8,0(sp)
    80001978:	0880                	addi	s0,sp,80
    8000197a:	8b2a                	mv	s6,a0
    8000197c:	8a2e                	mv	s4,a1
    8000197e:	8c32                	mv	s8,a2
    80001980:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);//reserved 
    80001982:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);// modify
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001984:	6a85                	lui	s5,0x1
    80001986:	a01d                	j	800019ac <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001988:	018505b3          	add	a1,a0,s8
    8000198c:	0004861b          	sext.w	a2,s1
    80001990:	412585b3          	sub	a1,a1,s2
    80001994:	8552                	mv	a0,s4
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	3c2080e7          	jalr	962(ra) # 80000d58 <memmove>

    len -= n;
    8000199e:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019a2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019a4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800019a8:	02098263          	beqz	s3,800019cc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);//reserved 
    800019ac:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);// modify
    800019b0:	85ca                	mv	a1,s2
    800019b2:	855a                	mv	a0,s6
    800019b4:	fffff097          	auipc	ra,0xfffff
    800019b8:	6de080e7          	jalr	1758(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    800019bc:	cd01                	beqz	a0,800019d4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800019be:	418904b3          	sub	s1,s2,s8
    800019c2:	94d6                	add	s1,s1,s5
    800019c4:	fc99f2e3          	bgeu	s3,s1,80001988 <copyin+0x28>
    800019c8:	84ce                	mv	s1,s3
    800019ca:	bf7d                	j	80001988 <copyin+0x28>
  }
  return 0;
    800019cc:	4501                	li	a0,0
    800019ce:	a021                	j	800019d6 <copyin+0x76>
    800019d0:	4501                	li	a0,0
}
    800019d2:	8082                	ret
      return -1;
    800019d4:	557d                	li	a0,-1
}
    800019d6:	60a6                	ld	ra,72(sp)
    800019d8:	6406                	ld	s0,64(sp)
    800019da:	74e2                	ld	s1,56(sp)
    800019dc:	7942                	ld	s2,48(sp)
    800019de:	79a2                	ld	s3,40(sp)
    800019e0:	7a02                	ld	s4,32(sp)
    800019e2:	6ae2                	ld	s5,24(sp)
    800019e4:	6b42                	ld	s6,16(sp)
    800019e6:	6ba2                	ld	s7,8(sp)
    800019e8:	6c02                	ld	s8,0(sp)
    800019ea:	6161                	addi	sp,sp,80
    800019ec:	8082                	ret

00000000800019ee <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019ee:	c2dd                	beqz	a3,80001a94 <copyinstr+0xa6>
{
    800019f0:	715d                	addi	sp,sp,-80
    800019f2:	e486                	sd	ra,72(sp)
    800019f4:	e0a2                	sd	s0,64(sp)
    800019f6:	fc26                	sd	s1,56(sp)
    800019f8:	f84a                	sd	s2,48(sp)
    800019fa:	f44e                	sd	s3,40(sp)
    800019fc:	f052                	sd	s4,32(sp)
    800019fe:	ec56                	sd	s5,24(sp)
    80001a00:	e85a                	sd	s6,16(sp)
    80001a02:	e45e                	sd	s7,8(sp)
    80001a04:	0880                	addi	s0,sp,80
    80001a06:	8a2a                	mv	s4,a0
    80001a08:	8b2e                	mv	s6,a1
    80001a0a:	8bb2                	mv	s7,a2
    80001a0c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a0e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a10:	6985                	lui	s3,0x1
    80001a12:	a02d                	j	80001a3c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a14:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a18:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a1a:	37fd                	addiw	a5,a5,-1
    80001a1c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a20:	60a6                	ld	ra,72(sp)
    80001a22:	6406                	ld	s0,64(sp)
    80001a24:	74e2                	ld	s1,56(sp)
    80001a26:	7942                	ld	s2,48(sp)
    80001a28:	79a2                	ld	s3,40(sp)
    80001a2a:	7a02                	ld	s4,32(sp)
    80001a2c:	6ae2                	ld	s5,24(sp)
    80001a2e:	6b42                	ld	s6,16(sp)
    80001a30:	6ba2                	ld	s7,8(sp)
    80001a32:	6161                	addi	sp,sp,80
    80001a34:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a36:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a3a:	c8a9                	beqz	s1,80001a8c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001a3c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a40:	85ca                	mv	a1,s2
    80001a42:	8552                	mv	a0,s4
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	64e080e7          	jalr	1614(ra) # 80001092 <walkaddr>
    if(pa0 == 0)
    80001a4c:	c131                	beqz	a0,80001a90 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001a4e:	417906b3          	sub	a3,s2,s7
    80001a52:	96ce                	add	a3,a3,s3
    80001a54:	00d4f363          	bgeu	s1,a3,80001a5a <copyinstr+0x6c>
    80001a58:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a5a:	955e                	add	a0,a0,s7
    80001a5c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a60:	daf9                	beqz	a3,80001a36 <copyinstr+0x48>
    80001a62:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a64:	41650633          	sub	a2,a0,s6
    80001a68:	fff48593          	addi	a1,s1,-1
    80001a6c:	95da                	add	a1,a1,s6
    while(n > 0){
    80001a6e:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001a70:	00f60733          	add	a4,a2,a5
    80001a74:	00074703          	lbu	a4,0(a4)
    80001a78:	df51                	beqz	a4,80001a14 <copyinstr+0x26>
        *dst = *p;
    80001a7a:	00e78023          	sb	a4,0(a5)
      --max;
    80001a7e:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001a82:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a84:	fed796e3          	bne	a5,a3,80001a70 <copyinstr+0x82>
      dst++;
    80001a88:	8b3e                	mv	s6,a5
    80001a8a:	b775                	j	80001a36 <copyinstr+0x48>
    80001a8c:	4781                	li	a5,0
    80001a8e:	b771                	j	80001a1a <copyinstr+0x2c>
      return -1;
    80001a90:	557d                	li	a0,-1
    80001a92:	b779                	j	80001a20 <copyinstr+0x32>
  int got_null = 0;
    80001a94:	4781                	li	a5,0
  if(got_null){
    80001a96:	37fd                	addiw	a5,a5,-1
    80001a98:	0007851b          	sext.w	a0,a5
}
    80001a9c:	8082                	ret

0000000080001a9e <test_pagetable>:


// check if use global kpgtbl or not 
int 
test_pagetable()
{
    80001a9e:	1141                	addi	sp,sp,-16
    80001aa0:	e422                	sd	s0,8(sp)
    80001aa2:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, satp" : "=r" (x) );
    80001aa4:	18002773          	csrr	a4,satp
  uint64 satp = r_satp();
  uint64 gsatp = MAKE_SATP(kernel_pagetable);
    80001aa8:	00007517          	auipc	a0,0x7
    80001aac:	56853503          	ld	a0,1384(a0) # 80009010 <kernel_pagetable>
    80001ab0:	8131                	srli	a0,a0,0xc
    80001ab2:	57fd                	li	a5,-1
    80001ab4:	17fe                	slli	a5,a5,0x3f
    80001ab6:	8d5d                	or	a0,a0,a5
  return satp != gsatp;
    80001ab8:	8d19                	sub	a0,a0,a4
}
    80001aba:	00a03533          	snez	a0,a0
    80001abe:	6422                	ld	s0,8(sp)
    80001ac0:	0141                	addi	sp,sp,16
    80001ac2:	8082                	ret

0000000080001ac4 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001ac4:	1101                	addi	sp,sp,-32
    80001ac6:	ec06                	sd	ra,24(sp)
    80001ac8:	e822                	sd	s0,16(sp)
    80001aca:	e426                	sd	s1,8(sp)
    80001acc:	1000                	addi	s0,sp,32
    80001ace:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	0b6080e7          	jalr	182(ra) # 80000b86 <holding>
    80001ad8:	c909                	beqz	a0,80001aea <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001ada:	749c                	ld	a5,40(s1)
    80001adc:	00978f63          	beq	a5,s1,80001afa <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001ae0:	60e2                	ld	ra,24(sp)
    80001ae2:	6442                	ld	s0,16(sp)
    80001ae4:	64a2                	ld	s1,8(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    panic("wakeup1");
    80001aea:	00006517          	auipc	a0,0x6
    80001aee:	71e50513          	addi	a0,a0,1822 # 80008208 <digits+0x1c8>
    80001af2:	fffff097          	auipc	ra,0xfffff
    80001af6:	a54080e7          	jalr	-1452(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001afa:	4c98                	lw	a4,24(s1)
    80001afc:	4785                	li	a5,1
    80001afe:	fef711e3          	bne	a4,a5,80001ae0 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b02:	4789                	li	a5,2
    80001b04:	cc9c                	sw	a5,24(s1)
}
    80001b06:	bfe9                	j	80001ae0 <wakeup1+0x1c>

0000000080001b08 <procinit>:
{
    80001b08:	715d                	addi	sp,sp,-80
    80001b0a:	e486                	sd	ra,72(sp)
    80001b0c:	e0a2                	sd	s0,64(sp)
    80001b0e:	fc26                	sd	s1,56(sp)
    80001b10:	f84a                	sd	s2,48(sp)
    80001b12:	f44e                	sd	s3,40(sp)
    80001b14:	f052                	sd	s4,32(sp)
    80001b16:	ec56                	sd	s5,24(sp)
    80001b18:	e85a                	sd	s6,16(sp)
    80001b1a:	e45e                	sd	s7,8(sp)
    80001b1c:	e062                	sd	s8,0(sp)
    80001b1e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001b20:	00006597          	auipc	a1,0x6
    80001b24:	6f058593          	addi	a1,a1,1776 # 80008210 <digits+0x1d0>
    80001b28:	00010517          	auipc	a0,0x10
    80001b2c:	e2850513          	addi	a0,a0,-472 # 80011950 <pid_lock>
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	040080e7          	jalr	64(ra) # 80000b70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b38:	00010917          	auipc	s2,0x10
    80001b3c:	23090913          	addi	s2,s2,560 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001b40:	00006c17          	auipc	s8,0x6
    80001b44:	6d8c0c13          	addi	s8,s8,1752 # 80008218 <digits+0x1d8>
      uint64 va = KSTACK((int) (p - proc));
    80001b48:	8bca                	mv	s7,s2
    80001b4a:	00006b17          	auipc	s6,0x6
    80001b4e:	4b6b0b13          	addi	s6,s6,1206 # 80008000 <etext>
    80001b52:	04000a37          	lui	s4,0x4000
    80001b56:	1a7d                	addi	s4,s4,-1 # 3ffffff <_entry-0x7c000001>
    80001b58:	0a32                	slli	s4,s4,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5a:	00016a97          	auipc	s5,0x16
    80001b5e:	00ea8a93          	addi	s5,s5,14 # 80017b68 <tickslock>
      initlock(&p->lock, "proc");
    80001b62:	85e2                	mv	a1,s8
    80001b64:	854a                	mv	a0,s2
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	00a080e7          	jalr	10(ra) # 80000b70 <initlock>
      char *pa = kalloc();
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	fa2080e7          	jalr	-94(ra) # 80000b10 <kalloc>
    80001b76:	89aa                	mv	s3,a0
      if(pa == 0)
    80001b78:	cd29                	beqz	a0,80001bd2 <procinit+0xca>
      uint64 va = KSTACK((int) (p - proc));
    80001b7a:	417904b3          	sub	s1,s2,s7
    80001b7e:	848d                	srai	s1,s1,0x3
    80001b80:	000b3783          	ld	a5,0(s6)
    80001b84:	02f484b3          	mul	s1,s1,a5
    80001b88:	2485                	addiw	s1,s1,1
    80001b8a:	00d4949b          	slliw	s1,s1,0xd
    80001b8e:	409a04b3          	sub	s1,s4,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b92:	4699                	li	a3,6
    80001b94:	6605                	lui	a2,0x1
    80001b96:	85aa                	mv	a1,a0
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	626080e7          	jalr	1574(ra) # 800011c0 <kvmmap>
      p->kstack = va;
    80001ba2:	04993023          	sd	s1,64(s2)
      p->kstack_pa = (uint64)pa;
    80001ba6:	17393823          	sd	s3,368(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001baa:	17890913          	addi	s2,s2,376
    80001bae:	fb591ae3          	bne	s2,s5,80001b62 <procinit+0x5a>
  kvminithart();
    80001bb2:	fffff097          	auipc	ra,0xfffff
    80001bb6:	416080e7          	jalr	1046(ra) # 80000fc8 <kvminithart>
}
    80001bba:	60a6                	ld	ra,72(sp)
    80001bbc:	6406                	ld	s0,64(sp)
    80001bbe:	74e2                	ld	s1,56(sp)
    80001bc0:	7942                	ld	s2,48(sp)
    80001bc2:	79a2                	ld	s3,40(sp)
    80001bc4:	7a02                	ld	s4,32(sp)
    80001bc6:	6ae2                	ld	s5,24(sp)
    80001bc8:	6b42                	ld	s6,16(sp)
    80001bca:	6ba2                	ld	s7,8(sp)
    80001bcc:	6c02                	ld	s8,0(sp)
    80001bce:	6161                	addi	sp,sp,80
    80001bd0:	8082                	ret
        panic("kalloc");
    80001bd2:	00006517          	auipc	a0,0x6
    80001bd6:	64e50513          	addi	a0,a0,1614 # 80008220 <digits+0x1e0>
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	96c080e7          	jalr	-1684(ra) # 80000546 <panic>

0000000080001be2 <cpuid>:
{
    80001be2:	1141                	addi	sp,sp,-16
    80001be4:	e422                	sd	s0,8(sp)
    80001be6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001be8:	8512                	mv	a0,tp
}
    80001bea:	2501                	sext.w	a0,a0
    80001bec:	6422                	ld	s0,8(sp)
    80001bee:	0141                	addi	sp,sp,16
    80001bf0:	8082                	ret

0000000080001bf2 <mycpu>:
mycpu(void) {
    80001bf2:	1141                	addi	sp,sp,-16
    80001bf4:	e422                	sd	s0,8(sp)
    80001bf6:	0800                	addi	s0,sp,16
    80001bf8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001bfa:	2781                	sext.w	a5,a5
    80001bfc:	079e                	slli	a5,a5,0x7
}
    80001bfe:	00010517          	auipc	a0,0x10
    80001c02:	d6a50513          	addi	a0,a0,-662 # 80011968 <cpus>
    80001c06:	953e                	add	a0,a0,a5
    80001c08:	6422                	ld	s0,8(sp)
    80001c0a:	0141                	addi	sp,sp,16
    80001c0c:	8082                	ret

0000000080001c0e <myproc>:
myproc(void) {
    80001c0e:	1101                	addi	sp,sp,-32
    80001c10:	ec06                	sd	ra,24(sp)
    80001c12:	e822                	sd	s0,16(sp)
    80001c14:	e426                	sd	s1,8(sp)
    80001c16:	1000                	addi	s0,sp,32
  push_off();
    80001c18:	fffff097          	auipc	ra,0xfffff
    80001c1c:	f9c080e7          	jalr	-100(ra) # 80000bb4 <push_off>
    80001c20:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001c22:	2781                	sext.w	a5,a5
    80001c24:	079e                	slli	a5,a5,0x7
    80001c26:	00010717          	auipc	a4,0x10
    80001c2a:	d2a70713          	addi	a4,a4,-726 # 80011950 <pid_lock>
    80001c2e:	97ba                	add	a5,a5,a4
    80001c30:	6f84                	ld	s1,24(a5)
  pop_off();
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	022080e7          	jalr	34(ra) # 80000c54 <pop_off>
}
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret

0000000080001c46 <forkret>:
{
    80001c46:	1141                	addi	sp,sp,-16
    80001c48:	e406                	sd	ra,8(sp)
    80001c4a:	e022                	sd	s0,0(sp)
    80001c4c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	fc0080e7          	jalr	-64(ra) # 80001c0e <myproc>
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	05e080e7          	jalr	94(ra) # 80000cb4 <release>
  if (first) {
    80001c5e:	00007797          	auipc	a5,0x7
    80001c62:	ca27a783          	lw	a5,-862(a5) # 80008900 <first.1>
    80001c66:	eb89                	bnez	a5,80001c78 <forkret+0x32>
  usertrapret();
    80001c68:	00001097          	auipc	ra,0x1
    80001c6c:	d3a080e7          	jalr	-710(ra) # 800029a2 <usertrapret>
}
    80001c70:	60a2                	ld	ra,8(sp)
    80001c72:	6402                	ld	s0,0(sp)
    80001c74:	0141                	addi	sp,sp,16
    80001c76:	8082                	ret
    first = 0;
    80001c78:	00007797          	auipc	a5,0x7
    80001c7c:	c807a423          	sw	zero,-888(a5) # 80008900 <first.1>
    fsinit(ROOTDEV);
    80001c80:	4505                	li	a0,1
    80001c82:	00002097          	auipc	ra,0x2
    80001c86:	a78080e7          	jalr	-1416(ra) # 800036fa <fsinit>
    80001c8a:	bff9                	j	80001c68 <forkret+0x22>

0000000080001c8c <allocpid>:
allocpid() {
    80001c8c:	1101                	addi	sp,sp,-32
    80001c8e:	ec06                	sd	ra,24(sp)
    80001c90:	e822                	sd	s0,16(sp)
    80001c92:	e426                	sd	s1,8(sp)
    80001c94:	e04a                	sd	s2,0(sp)
    80001c96:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c98:	00010917          	auipc	s2,0x10
    80001c9c:	cb890913          	addi	s2,s2,-840 # 80011950 <pid_lock>
    80001ca0:	854a                	mv	a0,s2
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	f5e080e7          	jalr	-162(ra) # 80000c00 <acquire>
  pid = nextpid;
    80001caa:	00007797          	auipc	a5,0x7
    80001cae:	c5a78793          	addi	a5,a5,-934 # 80008904 <nextpid>
    80001cb2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cb4:	0014871b          	addiw	a4,s1,1
    80001cb8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cba:	854a                	mv	a0,s2
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	ff8080e7          	jalr	-8(ra) # 80000cb4 <release>
}
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	60e2                	ld	ra,24(sp)
    80001cc8:	6442                	ld	s0,16(sp)
    80001cca:	64a2                	ld	s1,8(sp)
    80001ccc:	6902                	ld	s2,0(sp)
    80001cce:	6105                	addi	sp,sp,32
    80001cd0:	8082                	ret

0000000080001cd2 <kvmfree>:
void kvmfree(pagetable_t pagetable){
    80001cd2:	7179                	addi	sp,sp,-48
    80001cd4:	f406                	sd	ra,40(sp)
    80001cd6:	f022                	sd	s0,32(sp)
    80001cd8:	ec26                	sd	s1,24(sp)
    80001cda:	e84a                	sd	s2,16(sp)
    80001cdc:	e44e                	sd	s3,8(sp)
    80001cde:	e052                	sd	s4,0(sp)
    80001ce0:	1800                	addi	s0,sp,48
    80001ce2:	8a2a                	mv	s4,a0
      for(int i = 0; i < 512; i++){
    80001ce4:	84aa                	mv	s1,a0
    80001ce6:	6905                	lui	s2,0x1
    80001ce8:	992a                	add	s2,s2,a0
      if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001cea:	4985                	li	s3,1
    80001cec:	a021                	j	80001cf4 <kvmfree+0x22>
      for(int i = 0; i < 512; i++){
    80001cee:	04a1                	addi	s1,s1,8
    80001cf0:	03248163          	beq	s1,s2,80001d12 <kvmfree+0x40>
      pte_t pte = pagetable[i];
    80001cf4:	609c                	ld	a5,0(s1)
      if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001cf6:	00f7f713          	andi	a4,a5,15
    80001cfa:	ff371ae3          	bne	a4,s3,80001cee <kvmfree+0x1c>
        uint64 child = PTE2PA(pte);
    80001cfe:	83a9                	srli	a5,a5,0xa
        kvmfree((pagetable_t)child);
    80001d00:	00c79513          	slli	a0,a5,0xc
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	fce080e7          	jalr	-50(ra) # 80001cd2 <kvmfree>
        pagetable[i] = 0; 
    80001d0c:	0004b023          	sd	zero,0(s1)
    80001d10:	bff9                	j	80001cee <kvmfree+0x1c>
  kfree((void*)pagetable);
    80001d12:	8552                	mv	a0,s4
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	cfe080e7          	jalr	-770(ra) # 80000a12 <kfree>
}
    80001d1c:	70a2                	ld	ra,40(sp)
    80001d1e:	7402                	ld	s0,32(sp)
    80001d20:	64e2                	ld	s1,24(sp)
    80001d22:	6942                	ld	s2,16(sp)
    80001d24:	69a2                	ld	s3,8(sp)
    80001d26:	6a02                	ld	s4,0(sp)
    80001d28:	6145                	addi	sp,sp,48
    80001d2a:	8082                	ret

0000000080001d2c <proc_pagetable>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	e04a                	sd	s2,0(sp)
    80001d36:	1000                	addi	s0,sp,32
    80001d38:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	750080e7          	jalr	1872(ra) # 8000148a <uvmcreate>
    80001d42:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001d44:	c121                	beqz	a0,80001d84 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001d46:	4729                	li	a4,10
    80001d48:	00005697          	auipc	a3,0x5
    80001d4c:	2b868693          	addi	a3,a3,696 # 80007000 <_trampoline>
    80001d50:	6605                	lui	a2,0x1
    80001d52:	040005b7          	lui	a1,0x4000
    80001d56:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001d58:	05b2                	slli	a1,a1,0xc
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	3d8080e7          	jalr	984(ra) # 80001132 <mappages>
    80001d62:	02054863          	bltz	a0,80001d92 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d66:	4719                	li	a4,6
    80001d68:	05893683          	ld	a3,88(s2) # 1058 <_entry-0x7fffefa8>
    80001d6c:	6605                	lui	a2,0x1
    80001d6e:	020005b7          	lui	a1,0x2000
    80001d72:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001d74:	05b6                	slli	a1,a1,0xd
    80001d76:	8526                	mv	a0,s1
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	3ba080e7          	jalr	954(ra) # 80001132 <mappages>
    80001d80:	02054163          	bltz	a0,80001da2 <proc_pagetable+0x76>
}
    80001d84:	8526                	mv	a0,s1
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6902                	ld	s2,0(sp)
    80001d8e:	6105                	addi	sp,sp,32
    80001d90:	8082                	ret
    uvmfree(pagetable, 0);
    80001d92:	4581                	li	a1,0
    80001d94:	8526                	mv	a0,s1
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	93a080e7          	jalr	-1734(ra) # 800016d0 <uvmfree>
    return 0;
    80001d9e:	4481                	li	s1,0
    80001da0:	b7d5                	j	80001d84 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001da2:	4681                	li	a3,0
    80001da4:	4605                	li	a2,1
    80001da6:	040005b7          	lui	a1,0x4000
    80001daa:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dac:	05b2                	slli	a1,a1,0xc
    80001dae:	8526                	mv	a0,s1
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	616080e7          	jalr	1558(ra) # 800013c6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001db8:	4581                	li	a1,0
    80001dba:	8526                	mv	a0,s1
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	914080e7          	jalr	-1772(ra) # 800016d0 <uvmfree>
    return 0;
    80001dc4:	4481                	li	s1,0
    80001dc6:	bf7d                	j	80001d84 <proc_pagetable+0x58>

0000000080001dc8 <proc_freepagetable>:
{
    80001dc8:	1101                	addi	sp,sp,-32
    80001dca:	ec06                	sd	ra,24(sp)
    80001dcc:	e822                	sd	s0,16(sp)
    80001dce:	e426                	sd	s1,8(sp)
    80001dd0:	e04a                	sd	s2,0(sp)
    80001dd2:	1000                	addi	s0,sp,32
    80001dd4:	84aa                	mv	s1,a0
    80001dd6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dd8:	4681                	li	a3,0
    80001dda:	4605                	li	a2,1
    80001ddc:	040005b7          	lui	a1,0x4000
    80001de0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001de2:	05b2                	slli	a1,a1,0xc
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	5e2080e7          	jalr	1506(ra) # 800013c6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001dec:	4681                	li	a3,0
    80001dee:	4605                	li	a2,1
    80001df0:	020005b7          	lui	a1,0x2000
    80001df4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001df6:	05b6                	slli	a1,a1,0xd
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	5cc080e7          	jalr	1484(ra) # 800013c6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e02:	85ca                	mv	a1,s2
    80001e04:	8526                	mv	a0,s1
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	8ca080e7          	jalr	-1846(ra) # 800016d0 <uvmfree>
}
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6902                	ld	s2,0(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret

0000000080001e1a <freeproc>:
{
    80001e1a:	1101                	addi	sp,sp,-32
    80001e1c:	ec06                	sd	ra,24(sp)
    80001e1e:	e822                	sd	s0,16(sp)
    80001e20:	e426                	sd	s1,8(sp)
    80001e22:	1000                	addi	s0,sp,32
    80001e24:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e26:	6d28                	ld	a0,88(a0)
    80001e28:	c509                	beqz	a0,80001e32 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	be8080e7          	jalr	-1048(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001e32:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e36:	68a8                	ld	a0,80(s1)
    80001e38:	c511                	beqz	a0,80001e44 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001e3a:	64ac                	ld	a1,72(s1)
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	f8c080e7          	jalr	-116(ra) # 80001dc8 <proc_freepagetable>
  if(p->kpagetable){
    80001e44:	1684b503          	ld	a0,360(s1)
    80001e48:	c509                	beqz	a0,80001e52 <freeproc+0x38>
    kvmfree(p->kpagetable);
    80001e4a:	00000097          	auipc	ra,0x0
    80001e4e:	e88080e7          	jalr	-376(ra) # 80001cd2 <kvmfree>
  p->pagetable = 0;
    80001e52:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e56:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e5a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e5e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e62:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e66:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e6a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e6e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e72:	0004ac23          	sw	zero,24(s1)
}
    80001e76:	60e2                	ld	ra,24(sp)
    80001e78:	6442                	ld	s0,16(sp)
    80001e7a:	64a2                	ld	s1,8(sp)
    80001e7c:	6105                	addi	sp,sp,32
    80001e7e:	8082                	ret

0000000080001e80 <allocproc>:
{
    80001e80:	1101                	addi	sp,sp,-32
    80001e82:	ec06                	sd	ra,24(sp)
    80001e84:	e822                	sd	s0,16(sp)
    80001e86:	e426                	sd	s1,8(sp)
    80001e88:	e04a                	sd	s2,0(sp)
    80001e8a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8c:	00010497          	auipc	s1,0x10
    80001e90:	edc48493          	addi	s1,s1,-292 # 80011d68 <proc>
    80001e94:	00016917          	auipc	s2,0x16
    80001e98:	cd490913          	addi	s2,s2,-812 # 80017b68 <tickslock>
    acquire(&p->lock);
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	d62080e7          	jalr	-670(ra) # 80000c00 <acquire>
    if(p->state == UNUSED) {
    80001ea6:	4c9c                	lw	a5,24(s1)
    80001ea8:	cf81                	beqz	a5,80001ec0 <allocproc+0x40>
      release(&p->lock);
    80001eaa:	8526                	mv	a0,s1
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	e08080e7          	jalr	-504(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eb4:	17848493          	addi	s1,s1,376
    80001eb8:	ff2492e3          	bne	s1,s2,80001e9c <allocproc+0x1c>
  return 0;
    80001ebc:	4481                	li	s1,0
    80001ebe:	a0b5                	j	80001f2a <allocproc+0xaa>
      p->kpagetable=kvminit_proc();
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	43a080e7          	jalr	1082(ra) # 800012fa <kvminit_proc>
    80001ec8:	16a4b423          	sd	a0,360(s1)
      kvmmap_proc(p->kpagetable, p->kstack, p->kstack_pa, PGSIZE, PTE_R | PTE_W);
    80001ecc:	4719                	li	a4,6
    80001ece:	6685                	lui	a3,0x1
    80001ed0:	1704b603          	ld	a2,368(s1)
    80001ed4:	60ac                	ld	a1,64(s1)
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	3f4080e7          	jalr	1012(ra) # 800012ca <kvmmap_proc>
  p->pid = allocpid();
    80001ede:	00000097          	auipc	ra,0x0
    80001ee2:	dae080e7          	jalr	-594(ra) # 80001c8c <allocpid>
    80001ee6:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	c28080e7          	jalr	-984(ra) # 80000b10 <kalloc>
    80001ef0:	892a                	mv	s2,a0
    80001ef2:	eca8                	sd	a0,88(s1)
    80001ef4:	c131                	beqz	a0,80001f38 <allocproc+0xb8>
  p->pagetable = proc_pagetable(p);
    80001ef6:	8526                	mv	a0,s1
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	e34080e7          	jalr	-460(ra) # 80001d2c <proc_pagetable>
    80001f00:	892a                	mv	s2,a0
    80001f02:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f04:	c129                	beqz	a0,80001f46 <allocproc+0xc6>
  memset(&p->context, 0, sizeof(p->context));
    80001f06:	07000613          	li	a2,112
    80001f0a:	4581                	li	a1,0
    80001f0c:	06048513          	addi	a0,s1,96
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	dec080e7          	jalr	-532(ra) # 80000cfc <memset>
  p->context.ra = (uint64)forkret;
    80001f18:	00000797          	auipc	a5,0x0
    80001f1c:	d2e78793          	addi	a5,a5,-722 # 80001c46 <forkret>
    80001f20:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f22:	60bc                	ld	a5,64(s1)
    80001f24:	6705                	lui	a4,0x1
    80001f26:	97ba                	add	a5,a5,a4
    80001f28:	f4bc                	sd	a5,104(s1)
}
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	60e2                	ld	ra,24(sp)
    80001f2e:	6442                	ld	s0,16(sp)
    80001f30:	64a2                	ld	s1,8(sp)
    80001f32:	6902                	ld	s2,0(sp)
    80001f34:	6105                	addi	sp,sp,32
    80001f36:	8082                	ret
    release(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d7a080e7          	jalr	-646(ra) # 80000cb4 <release>
    return 0;
    80001f42:	84ca                	mv	s1,s2
    80001f44:	b7dd                	j	80001f2a <allocproc+0xaa>
    freeproc(p);
    80001f46:	8526                	mv	a0,s1
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	ed2080e7          	jalr	-302(ra) # 80001e1a <freeproc>
    release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d62080e7          	jalr	-670(ra) # 80000cb4 <release>
    return 0;
    80001f5a:	84ca                	mv	s1,s2
    80001f5c:	b7f9                	j	80001f2a <allocproc+0xaa>

0000000080001f5e <userinit>:
{
    80001f5e:	1101                	addi	sp,sp,-32
    80001f60:	ec06                	sd	ra,24(sp)
    80001f62:	e822                	sd	s0,16(sp)
    80001f64:	e426                	sd	s1,8(sp)
    80001f66:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	f18080e7          	jalr	-232(ra) # 80001e80 <allocproc>
    80001f70:	84aa                	mv	s1,a0
  initproc = p;
    80001f72:	00007797          	auipc	a5,0x7
    80001f76:	0aa7b323          	sd	a0,166(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f7a:	03400613          	li	a2,52
    80001f7e:	00007597          	auipc	a1,0x7
    80001f82:	99258593          	addi	a1,a1,-1646 # 80008910 <initcode>
    80001f86:	6928                	ld	a0,80(a0)
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	530080e7          	jalr	1328(ra) # 800014b8 <uvminit>
  p->sz = PGSIZE;
    80001f90:	6785                	lui	a5,0x1
    80001f92:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f94:	6cb8                	ld	a4,88(s1)
    80001f96:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f9a:	6cb8                	ld	a4,88(s1)
    80001f9c:	fb1c                	sd	a5,48(a4)
  upgtbl2kpgtbl(p->pagetable, p->kpagetable, 0, PGSIZE);
    80001f9e:	6685                	lui	a3,0x1
    80001fa0:	4601                	li	a2,0
    80001fa2:	1684b583          	ld	a1,360(s1)
    80001fa6:	68a8                	ld	a0,80(s1)
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	866080e7          	jalr	-1946(ra) # 8000180e <upgtbl2kpgtbl>
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fb0:	4641                	li	a2,16
    80001fb2:	00006597          	auipc	a1,0x6
    80001fb6:	27658593          	addi	a1,a1,630 # 80008228 <digits+0x1e8>
    80001fba:	15848513          	addi	a0,s1,344
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	e90080e7          	jalr	-368(ra) # 80000e4e <safestrcpy>
  p->cwd = namei("/");
    80001fc6:	00006517          	auipc	a0,0x6
    80001fca:	27250513          	addi	a0,a0,626 # 80008238 <digits+0x1f8>
    80001fce:	00002097          	auipc	ra,0x2
    80001fd2:	15c080e7          	jalr	348(ra) # 8000412a <namei>
    80001fd6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fda:	4789                	li	a5,2
    80001fdc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	cd4080e7          	jalr	-812(ra) # 80000cb4 <release>
}
    80001fe8:	60e2                	ld	ra,24(sp)
    80001fea:	6442                	ld	s0,16(sp)
    80001fec:	64a2                	ld	s1,8(sp)
    80001fee:	6105                	addi	sp,sp,32
    80001ff0:	8082                	ret

0000000080001ff2 <growproc>:
{
    80001ff2:	7179                	addi	sp,sp,-48
    80001ff4:	f406                	sd	ra,40(sp)
    80001ff6:	f022                	sd	s0,32(sp)
    80001ff8:	ec26                	sd	s1,24(sp)
    80001ffa:	e84a                	sd	s2,16(sp)
    80001ffc:	e44e                	sd	s3,8(sp)
    80001ffe:	1800                	addi	s0,sp,48
    80002000:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    80002002:	00000097          	auipc	ra,0x0
    80002006:	c0c080e7          	jalr	-1012(ra) # 80001c0e <myproc>
    8000200a:	892a                	mv	s2,a0
  sz = p->sz;
    8000200c:	652c                	ld	a1,72(a0)
    8000200e:	0005849b          	sext.w	s1,a1
  if(n > 0){
    80002012:	03304063          	bgtz	s3,80002032 <growproc+0x40>
  } else if(n < 0){
    80002016:	0409cc63          	bltz	s3,8000206e <growproc+0x7c>
  p->sz = sz;
    8000201a:	1482                	slli	s1,s1,0x20
    8000201c:	9081                	srli	s1,s1,0x20
    8000201e:	04993423          	sd	s1,72(s2)
  return 0;
    80002022:	4501                	li	a0,0
}
    80002024:	70a2                	ld	ra,40(sp)
    80002026:	7402                	ld	s0,32(sp)
    80002028:	64e2                	ld	s1,24(sp)
    8000202a:	6942                	ld	s2,16(sp)
    8000202c:	69a2                	ld	s3,8(sp)
    8000202e:	6145                	addi	sp,sp,48
    80002030:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002032:	0099863b          	addw	a2,s3,s1
    80002036:	1602                	slli	a2,a2,0x20
    80002038:	9201                	srli	a2,a2,0x20
    8000203a:	1582                	slli	a1,a1,0x20
    8000203c:	9181                	srli	a1,a1,0x20
    8000203e:	6928                	ld	a0,80(a0)
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	532080e7          	jalr	1330(ra) # 80001572 <uvmalloc>
    80002048:	0005049b          	sext.w	s1,a0
    8000204c:	c8a9                	beqz	s1,8000209e <growproc+0xac>
    if(upgtbl2kpgtbl(p->pagetable, p->kpagetable, p->sz, p->sz+n)<0){
    8000204e:	04893603          	ld	a2,72(s2)
    80002052:	00c986b3          	add	a3,s3,a2
    80002056:	16893583          	ld	a1,360(s2)
    8000205a:	05093503          	ld	a0,80(s2)
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	7b0080e7          	jalr	1968(ra) # 8000180e <upgtbl2kpgtbl>
    80002066:	fa055ae3          	bgez	a0,8000201a <growproc+0x28>
      return -1;
    8000206a:	557d                	li	a0,-1
    8000206c:	bf65                	j	80002024 <growproc+0x32>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000206e:	0099863b          	addw	a2,s3,s1
    80002072:	1602                	slli	a2,a2,0x20
    80002074:	9201                	srli	a2,a2,0x20
    80002076:	1582                	slli	a1,a1,0x20
    80002078:	9181                	srli	a1,a1,0x20
    8000207a:	6928                	ld	a0,80(a0)
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	4ae080e7          	jalr	1198(ra) # 8000152a <uvmdealloc>
    80002084:	0005049b          	sext.w	s1,a0
    kvmdealloc(p->kpagetable, p->sz, p->sz+n);
    80002088:	04893583          	ld	a1,72(s2)
    8000208c:	00b98633          	add	a2,s3,a1
    80002090:	16893503          	ld	a0,360(s2)
    80002094:	fffff097          	auipc	ra,0xfffff
    80002098:	588080e7          	jalr	1416(ra) # 8000161c <kvmdealloc>
    8000209c:	bfbd                	j	8000201a <growproc+0x28>
      return -1;
    8000209e:	557d                	li	a0,-1
    800020a0:	b751                	j	80002024 <growproc+0x32>

00000000800020a2 <fork>:
{
    800020a2:	7139                	addi	sp,sp,-64
    800020a4:	fc06                	sd	ra,56(sp)
    800020a6:	f822                	sd	s0,48(sp)
    800020a8:	f426                	sd	s1,40(sp)
    800020aa:	f04a                	sd	s2,32(sp)
    800020ac:	ec4e                	sd	s3,24(sp)
    800020ae:	e852                	sd	s4,16(sp)
    800020b0:	e456                	sd	s5,8(sp)
    800020b2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	b5a080e7          	jalr	-1190(ra) # 80001c0e <myproc>
    800020bc:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	dc2080e7          	jalr	-574(ra) # 80001e80 <allocproc>
    800020c6:	10050d63          	beqz	a0,800021e0 <fork+0x13e>
    800020ca:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020cc:	048ab603          	ld	a2,72(s5)
    800020d0:	692c                	ld	a1,80(a0)
    800020d2:	050ab503          	ld	a0,80(s5)
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	634080e7          	jalr	1588(ra) # 8000170a <uvmcopy>
    800020de:	06054763          	bltz	a0,8000214c <fork+0xaa>
  if(upgtbl2kpgtbl(np->pagetable, np->kpagetable, 0, p->sz) < 0){
    800020e2:	048ab683          	ld	a3,72(s5)
    800020e6:	4601                	li	a2,0
    800020e8:	1689b583          	ld	a1,360(s3) # 1168 <_entry-0x7fffee98>
    800020ec:	0509b503          	ld	a0,80(s3)
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	71e080e7          	jalr	1822(ra) # 8000180e <upgtbl2kpgtbl>
    800020f8:	06054663          	bltz	a0,80002164 <fork+0xc2>
  np->sz = p->sz;
    800020fc:	048ab783          	ld	a5,72(s5)
    80002100:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80002104:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002108:	058ab683          	ld	a3,88(s5)
    8000210c:	87b6                	mv	a5,a3
    8000210e:	0589b703          	ld	a4,88(s3)
    80002112:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002116:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    8000211a:	6788                	ld	a0,8(a5)
    8000211c:	6b8c                	ld	a1,16(a5)
    8000211e:	6f90                	ld	a2,24(a5)
    80002120:	01073023          	sd	a6,0(a4)
    80002124:	e708                	sd	a0,8(a4)
    80002126:	eb0c                	sd	a1,16(a4)
    80002128:	ef10                	sd	a2,24(a4)
    8000212a:	02078793          	addi	a5,a5,32
    8000212e:	02070713          	addi	a4,a4,32
    80002132:	fed792e3          	bne	a5,a3,80002116 <fork+0x74>
  np->trapframe->a0 = 0;
    80002136:	0589b783          	ld	a5,88(s3)
    8000213a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000213e:	0d0a8493          	addi	s1,s5,208
    80002142:	0d098913          	addi	s2,s3,208
    80002146:	150a8a13          	addi	s4,s5,336
    8000214a:	a82d                	j	80002184 <fork+0xe2>
    freeproc(np);
    8000214c:	854e                	mv	a0,s3
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	ccc080e7          	jalr	-820(ra) # 80001e1a <freeproc>
    release(&np->lock);
    80002156:	854e                	mv	a0,s3
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b5c080e7          	jalr	-1188(ra) # 80000cb4 <release>
    return -1;
    80002160:	54fd                	li	s1,-1
    80002162:	a0ad                	j	800021cc <fork+0x12a>
    freeproc(np);
    80002164:	854e                	mv	a0,s3
    80002166:	00000097          	auipc	ra,0x0
    8000216a:	cb4080e7          	jalr	-844(ra) # 80001e1a <freeproc>
    release(&np->lock);
    8000216e:	854e                	mv	a0,s3
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b44080e7          	jalr	-1212(ra) # 80000cb4 <release>
    return -1;
    80002178:	54fd                	li	s1,-1
    8000217a:	a889                	j	800021cc <fork+0x12a>
  for(i = 0; i < NOFILE; i++)
    8000217c:	04a1                	addi	s1,s1,8
    8000217e:	0921                	addi	s2,s2,8
    80002180:	01448b63          	beq	s1,s4,80002196 <fork+0xf4>
    if(p->ofile[i])
    80002184:	6088                	ld	a0,0(s1)
    80002186:	d97d                	beqz	a0,8000217c <fork+0xda>
      np->ofile[i] = filedup(p->ofile[i]);
    80002188:	00002097          	auipc	ra,0x2
    8000218c:	62e080e7          	jalr	1582(ra) # 800047b6 <filedup>
    80002190:	00a93023          	sd	a0,0(s2)
    80002194:	b7e5                	j	8000217c <fork+0xda>
  np->cwd = idup(p->cwd);
    80002196:	150ab503          	ld	a0,336(s5)
    8000219a:	00001097          	auipc	ra,0x1
    8000219e:	79c080e7          	jalr	1948(ra) # 80003936 <idup>
    800021a2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021a6:	4641                	li	a2,16
    800021a8:	158a8593          	addi	a1,s5,344
    800021ac:	15898513          	addi	a0,s3,344
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	c9e080e7          	jalr	-866(ra) # 80000e4e <safestrcpy>
  pid = np->pid;
    800021b8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800021bc:	4789                	li	a5,2
    800021be:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021c2:	854e                	mv	a0,s3
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	af0080e7          	jalr	-1296(ra) # 80000cb4 <release>
}
    800021cc:	8526                	mv	a0,s1
    800021ce:	70e2                	ld	ra,56(sp)
    800021d0:	7442                	ld	s0,48(sp)
    800021d2:	74a2                	ld	s1,40(sp)
    800021d4:	7902                	ld	s2,32(sp)
    800021d6:	69e2                	ld	s3,24(sp)
    800021d8:	6a42                	ld	s4,16(sp)
    800021da:	6aa2                	ld	s5,8(sp)
    800021dc:	6121                	addi	sp,sp,64
    800021de:	8082                	ret
    return -1;
    800021e0:	54fd                	li	s1,-1
    800021e2:	b7ed                	j	800021cc <fork+0x12a>

00000000800021e4 <reparent>:
{
    800021e4:	7179                	addi	sp,sp,-48
    800021e6:	f406                	sd	ra,40(sp)
    800021e8:	f022                	sd	s0,32(sp)
    800021ea:	ec26                	sd	s1,24(sp)
    800021ec:	e84a                	sd	s2,16(sp)
    800021ee:	e44e                	sd	s3,8(sp)
    800021f0:	e052                	sd	s4,0(sp)
    800021f2:	1800                	addi	s0,sp,48
    800021f4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00010497          	auipc	s1,0x10
    800021fa:	b7248493          	addi	s1,s1,-1166 # 80011d68 <proc>
      pp->parent = initproc;
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	e1aa0a13          	addi	s4,s4,-486 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002206:	00016997          	auipc	s3,0x16
    8000220a:	96298993          	addi	s3,s3,-1694 # 80017b68 <tickslock>
    8000220e:	a029                	j	80002218 <reparent+0x34>
    80002210:	17848493          	addi	s1,s1,376
    80002214:	03348363          	beq	s1,s3,8000223a <reparent+0x56>
    if(pp->parent == p){
    80002218:	709c                	ld	a5,32(s1)
    8000221a:	ff279be3          	bne	a5,s2,80002210 <reparent+0x2c>
      acquire(&pp->lock);
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9e0080e7          	jalr	-1568(ra) # 80000c00 <acquire>
      pp->parent = initproc;
    80002228:	000a3783          	ld	a5,0(s4)
    8000222c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a84080e7          	jalr	-1404(ra) # 80000cb4 <release>
    80002238:	bfe1                	j	80002210 <reparent+0x2c>
}
    8000223a:	70a2                	ld	ra,40(sp)
    8000223c:	7402                	ld	s0,32(sp)
    8000223e:	64e2                	ld	s1,24(sp)
    80002240:	6942                	ld	s2,16(sp)
    80002242:	69a2                	ld	s3,8(sp)
    80002244:	6a02                	ld	s4,0(sp)
    80002246:	6145                	addi	sp,sp,48
    80002248:	8082                	ret

000000008000224a <scheduler>:
{
    8000224a:	715d                	addi	sp,sp,-80
    8000224c:	e486                	sd	ra,72(sp)
    8000224e:	e0a2                	sd	s0,64(sp)
    80002250:	fc26                	sd	s1,56(sp)
    80002252:	f84a                	sd	s2,48(sp)
    80002254:	f44e                	sd	s3,40(sp)
    80002256:	f052                	sd	s4,32(sp)
    80002258:	ec56                	sd	s5,24(sp)
    8000225a:	e85a                	sd	s6,16(sp)
    8000225c:	e45e                	sd	s7,8(sp)
    8000225e:	e062                	sd	s8,0(sp)
    80002260:	0880                	addi	s0,sp,80
    80002262:	8792                	mv	a5,tp
  int id = r_tp();
    80002264:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002266:	00779b13          	slli	s6,a5,0x7
    8000226a:	0000f717          	auipc	a4,0xf
    8000226e:	6e670713          	addi	a4,a4,1766 # 80011950 <pid_lock>
    80002272:	975a                	add	a4,a4,s6
    80002274:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002278:	0000f717          	auipc	a4,0xf
    8000227c:	6f870713          	addi	a4,a4,1784 # 80011970 <cpus+0x8>
    80002280:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80002282:	079e                	slli	a5,a5,0x7
    80002284:	0000fa17          	auipc	s4,0xf
    80002288:	6cca0a13          	addi	s4,s4,1740 # 80011950 <pid_lock>
    8000228c:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kpagetable));
    8000228e:	5bfd                	li	s7,-1
    80002290:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80002292:	00016997          	auipc	s3,0x16
    80002296:	8d698993          	addi	s3,s3,-1834 # 80017b68 <tickslock>
    8000229a:	a885                	j	8000230a <scheduler+0xc0>
      release(&p->lock);
    8000229c:	8526                	mv	a0,s1
    8000229e:	fffff097          	auipc	ra,0xfffff
    800022a2:	a16080e7          	jalr	-1514(ra) # 80000cb4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022a6:	17848493          	addi	s1,s1,376
    800022aa:	05348263          	beq	s1,s3,800022ee <scheduler+0xa4>
      acquire(&p->lock);
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	950080e7          	jalr	-1712(ra) # 80000c00 <acquire>
      if(p->state == RUNNABLE) {
    800022b8:	4c9c                	lw	a5,24(s1)
    800022ba:	ff2791e3          	bne	a5,s2,8000229c <scheduler+0x52>
        p->state = RUNNING;
    800022be:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800022c2:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kpagetable));
    800022c6:	1684b783          	ld	a5,360(s1)
    800022ca:	83b1                	srli	a5,a5,0xc
    800022cc:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    800022d0:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800022d4:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800022d8:	06048593          	addi	a1,s1,96
    800022dc:	855a                	mv	a0,s6
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	61a080e7          	jalr	1562(ra) # 800028f8 <swtch>
        c->proc = 0; // cpu dosen't run any process now
    800022e6:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800022ea:	4c05                	li	s8,1
    800022ec:	bf45                	j	8000229c <scheduler+0x52>
      kvminithart();// no process running change to default pagetable
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	cda080e7          	jalr	-806(ra) # 80000fc8 <kvminithart>
    if(found == 0) {
    800022f6:	000c1a63          	bnez	s8,8000230a <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022fa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022fe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002302:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002306:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000230e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002312:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002316:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002318:	00010497          	auipc	s1,0x10
    8000231c:	a5048493          	addi	s1,s1,-1456 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002320:	4909                	li	s2,2
        p->state = RUNNING;
    80002322:	4a8d                	li	s5,3
    80002324:	b769                	j	800022ae <scheduler+0x64>

0000000080002326 <sched>:
{
    80002326:	7179                	addi	sp,sp,-48
    80002328:	f406                	sd	ra,40(sp)
    8000232a:	f022                	sd	s0,32(sp)
    8000232c:	ec26                	sd	s1,24(sp)
    8000232e:	e84a                	sd	s2,16(sp)
    80002330:	e44e                	sd	s3,8(sp)
    80002332:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002334:	00000097          	auipc	ra,0x0
    80002338:	8da080e7          	jalr	-1830(ra) # 80001c0e <myproc>
    8000233c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000233e:	fffff097          	auipc	ra,0xfffff
    80002342:	848080e7          	jalr	-1976(ra) # 80000b86 <holding>
    80002346:	c93d                	beqz	a0,800023bc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002348:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000234a:	2781                	sext.w	a5,a5
    8000234c:	079e                	slli	a5,a5,0x7
    8000234e:	0000f717          	auipc	a4,0xf
    80002352:	60270713          	addi	a4,a4,1538 # 80011950 <pid_lock>
    80002356:	97ba                	add	a5,a5,a4
    80002358:	0907a703          	lw	a4,144(a5)
    8000235c:	4785                	li	a5,1
    8000235e:	06f71763          	bne	a4,a5,800023cc <sched+0xa6>
  if(p->state == RUNNING)
    80002362:	4c98                	lw	a4,24(s1)
    80002364:	478d                	li	a5,3
    80002366:	06f70b63          	beq	a4,a5,800023dc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000236a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000236e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002370:	efb5                	bnez	a5,800023ec <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002372:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002374:	0000f917          	auipc	s2,0xf
    80002378:	5dc90913          	addi	s2,s2,1500 # 80011950 <pid_lock>
    8000237c:	2781                	sext.w	a5,a5
    8000237e:	079e                	slli	a5,a5,0x7
    80002380:	97ca                	add	a5,a5,s2
    80002382:	0947a983          	lw	s3,148(a5)
    80002386:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002388:	2781                	sext.w	a5,a5
    8000238a:	079e                	slli	a5,a5,0x7
    8000238c:	0000f597          	auipc	a1,0xf
    80002390:	5e458593          	addi	a1,a1,1508 # 80011970 <cpus+0x8>
    80002394:	95be                	add	a1,a1,a5
    80002396:	06048513          	addi	a0,s1,96
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	55e080e7          	jalr	1374(ra) # 800028f8 <swtch>
    800023a2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023a4:	2781                	sext.w	a5,a5
    800023a6:	079e                	slli	a5,a5,0x7
    800023a8:	993e                	add	s2,s2,a5
    800023aa:	09392a23          	sw	s3,148(s2)
}
    800023ae:	70a2                	ld	ra,40(sp)
    800023b0:	7402                	ld	s0,32(sp)
    800023b2:	64e2                	ld	s1,24(sp)
    800023b4:	6942                	ld	s2,16(sp)
    800023b6:	69a2                	ld	s3,8(sp)
    800023b8:	6145                	addi	sp,sp,48
    800023ba:	8082                	ret
    panic("sched p->lock");
    800023bc:	00006517          	auipc	a0,0x6
    800023c0:	e8450513          	addi	a0,a0,-380 # 80008240 <digits+0x200>
    800023c4:	ffffe097          	auipc	ra,0xffffe
    800023c8:	182080e7          	jalr	386(ra) # 80000546 <panic>
    panic("sched locks");
    800023cc:	00006517          	auipc	a0,0x6
    800023d0:	e8450513          	addi	a0,a0,-380 # 80008250 <digits+0x210>
    800023d4:	ffffe097          	auipc	ra,0xffffe
    800023d8:	172080e7          	jalr	370(ra) # 80000546 <panic>
    panic("sched running");
    800023dc:	00006517          	auipc	a0,0x6
    800023e0:	e8450513          	addi	a0,a0,-380 # 80008260 <digits+0x220>
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	162080e7          	jalr	354(ra) # 80000546 <panic>
    panic("sched interruptible");
    800023ec:	00006517          	auipc	a0,0x6
    800023f0:	e8450513          	addi	a0,a0,-380 # 80008270 <digits+0x230>
    800023f4:	ffffe097          	auipc	ra,0xffffe
    800023f8:	152080e7          	jalr	338(ra) # 80000546 <panic>

00000000800023fc <exit>:
{
    800023fc:	7179                	addi	sp,sp,-48
    800023fe:	f406                	sd	ra,40(sp)
    80002400:	f022                	sd	s0,32(sp)
    80002402:	ec26                	sd	s1,24(sp)
    80002404:	e84a                	sd	s2,16(sp)
    80002406:	e44e                	sd	s3,8(sp)
    80002408:	e052                	sd	s4,0(sp)
    8000240a:	1800                	addi	s0,sp,48
    8000240c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	800080e7          	jalr	-2048(ra) # 80001c0e <myproc>
    80002416:	89aa                	mv	s3,a0
  if(p == initproc)
    80002418:	00007797          	auipc	a5,0x7
    8000241c:	c007b783          	ld	a5,-1024(a5) # 80009018 <initproc>
    80002420:	0d050493          	addi	s1,a0,208
    80002424:	15050913          	addi	s2,a0,336
    80002428:	02a79363          	bne	a5,a0,8000244e <exit+0x52>
    panic("init exiting");
    8000242c:	00006517          	auipc	a0,0x6
    80002430:	e5c50513          	addi	a0,a0,-420 # 80008288 <digits+0x248>
    80002434:	ffffe097          	auipc	ra,0xffffe
    80002438:	112080e7          	jalr	274(ra) # 80000546 <panic>
      fileclose(f);
    8000243c:	00002097          	auipc	ra,0x2
    80002440:	3cc080e7          	jalr	972(ra) # 80004808 <fileclose>
      p->ofile[fd] = 0;
    80002444:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002448:	04a1                	addi	s1,s1,8
    8000244a:	01248563          	beq	s1,s2,80002454 <exit+0x58>
    if(p->ofile[fd]){
    8000244e:	6088                	ld	a0,0(s1)
    80002450:	f575                	bnez	a0,8000243c <exit+0x40>
    80002452:	bfdd                	j	80002448 <exit+0x4c>
  begin_op();
    80002454:	00002097          	auipc	ra,0x2
    80002458:	ee6080e7          	jalr	-282(ra) # 8000433a <begin_op>
  iput(p->cwd);
    8000245c:	1509b503          	ld	a0,336(s3)
    80002460:	00001097          	auipc	ra,0x1
    80002464:	6ce080e7          	jalr	1742(ra) # 80003b2e <iput>
  end_op();
    80002468:	00002097          	auipc	ra,0x2
    8000246c:	f50080e7          	jalr	-176(ra) # 800043b8 <end_op>
  p->cwd = 0;
    80002470:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002474:	00007497          	auipc	s1,0x7
    80002478:	ba448493          	addi	s1,s1,-1116 # 80009018 <initproc>
    8000247c:	6088                	ld	a0,0(s1)
    8000247e:	ffffe097          	auipc	ra,0xffffe
    80002482:	782080e7          	jalr	1922(ra) # 80000c00 <acquire>
  wakeup1(initproc);
    80002486:	6088                	ld	a0,0(s1)
    80002488:	fffff097          	auipc	ra,0xfffff
    8000248c:	63c080e7          	jalr	1596(ra) # 80001ac4 <wakeup1>
  release(&initproc->lock);
    80002490:	6088                	ld	a0,0(s1)
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	822080e7          	jalr	-2014(ra) # 80000cb4 <release>
  acquire(&p->lock);
    8000249a:	854e                	mv	a0,s3
    8000249c:	ffffe097          	auipc	ra,0xffffe
    800024a0:	764080e7          	jalr	1892(ra) # 80000c00 <acquire>
  struct proc *original_parent = p->parent;
    800024a4:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800024a8:	854e                	mv	a0,s3
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	80a080e7          	jalr	-2038(ra) # 80000cb4 <release>
  acquire(&original_parent->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	74c080e7          	jalr	1868(ra) # 80000c00 <acquire>
  acquire(&p->lock);
    800024bc:	854e                	mv	a0,s3
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	742080e7          	jalr	1858(ra) # 80000c00 <acquire>
  reparent(p);
    800024c6:	854e                	mv	a0,s3
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	d1c080e7          	jalr	-740(ra) # 800021e4 <reparent>
  wakeup1(original_parent);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	5f2080e7          	jalr	1522(ra) # 80001ac4 <wakeup1>
  p->xstate = status;
    800024da:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800024de:	4791                	li	a5,4
    800024e0:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800024e4:	8526                	mv	a0,s1
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	7ce080e7          	jalr	1998(ra) # 80000cb4 <release>
  sched();
    800024ee:	00000097          	auipc	ra,0x0
    800024f2:	e38080e7          	jalr	-456(ra) # 80002326 <sched>
  panic("zombie exit");
    800024f6:	00006517          	auipc	a0,0x6
    800024fa:	da250513          	addi	a0,a0,-606 # 80008298 <digits+0x258>
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	048080e7          	jalr	72(ra) # 80000546 <panic>

0000000080002506 <yield>:
{
    80002506:	1101                	addi	sp,sp,-32
    80002508:	ec06                	sd	ra,24(sp)
    8000250a:	e822                	sd	s0,16(sp)
    8000250c:	e426                	sd	s1,8(sp)
    8000250e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	6fe080e7          	jalr	1790(ra) # 80001c0e <myproc>
    80002518:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	6e6080e7          	jalr	1766(ra) # 80000c00 <acquire>
  p->state = RUNNABLE;
    80002522:	4789                	li	a5,2
    80002524:	cc9c                	sw	a5,24(s1)
  sched();
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	e00080e7          	jalr	-512(ra) # 80002326 <sched>
  release(&p->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	784080e7          	jalr	1924(ra) # 80000cb4 <release>
}
    80002538:	60e2                	ld	ra,24(sp)
    8000253a:	6442                	ld	s0,16(sp)
    8000253c:	64a2                	ld	s1,8(sp)
    8000253e:	6105                	addi	sp,sp,32
    80002540:	8082                	ret

0000000080002542 <sleep>:
{
    80002542:	7179                	addi	sp,sp,-48
    80002544:	f406                	sd	ra,40(sp)
    80002546:	f022                	sd	s0,32(sp)
    80002548:	ec26                	sd	s1,24(sp)
    8000254a:	e84a                	sd	s2,16(sp)
    8000254c:	e44e                	sd	s3,8(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	89aa                	mv	s3,a0
    80002552:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002554:	fffff097          	auipc	ra,0xfffff
    80002558:	6ba080e7          	jalr	1722(ra) # 80001c0e <myproc>
    8000255c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000255e:	05250663          	beq	a0,s2,800025aa <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	69e080e7          	jalr	1694(ra) # 80000c00 <acquire>
    release(lk);
    8000256a:	854a                	mv	a0,s2
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	748080e7          	jalr	1864(ra) # 80000cb4 <release>
  p->chan = chan;
    80002574:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002578:	4785                	li	a5,1
    8000257a:	cc9c                	sw	a5,24(s1)
  sched();
    8000257c:	00000097          	auipc	ra,0x0
    80002580:	daa080e7          	jalr	-598(ra) # 80002326 <sched>
  p->chan = 0;
    80002584:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002588:	8526                	mv	a0,s1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	72a080e7          	jalr	1834(ra) # 80000cb4 <release>
    acquire(lk);
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	66c080e7          	jalr	1644(ra) # 80000c00 <acquire>
}
    8000259c:	70a2                	ld	ra,40(sp)
    8000259e:	7402                	ld	s0,32(sp)
    800025a0:	64e2                	ld	s1,24(sp)
    800025a2:	6942                	ld	s2,16(sp)
    800025a4:	69a2                	ld	s3,8(sp)
    800025a6:	6145                	addi	sp,sp,48
    800025a8:	8082                	ret
  p->chan = chan;
    800025aa:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800025ae:	4785                	li	a5,1
    800025b0:	cd1c                	sw	a5,24(a0)
  sched();
    800025b2:	00000097          	auipc	ra,0x0
    800025b6:	d74080e7          	jalr	-652(ra) # 80002326 <sched>
  p->chan = 0;
    800025ba:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800025be:	bff9                	j	8000259c <sleep+0x5a>

00000000800025c0 <wait>:
{
    800025c0:	715d                	addi	sp,sp,-80
    800025c2:	e486                	sd	ra,72(sp)
    800025c4:	e0a2                	sd	s0,64(sp)
    800025c6:	fc26                	sd	s1,56(sp)
    800025c8:	f84a                	sd	s2,48(sp)
    800025ca:	f44e                	sd	s3,40(sp)
    800025cc:	f052                	sd	s4,32(sp)
    800025ce:	ec56                	sd	s5,24(sp)
    800025d0:	e85a                	sd	s6,16(sp)
    800025d2:	e45e                	sd	s7,8(sp)
    800025d4:	0880                	addi	s0,sp,80
    800025d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	636080e7          	jalr	1590(ra) # 80001c0e <myproc>
    800025e0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	61e080e7          	jalr	1566(ra) # 80000c00 <acquire>
    havekids = 0;
    800025ea:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ec:	4a11                	li	s4,4
        havekids = 1;
    800025ee:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025f0:	00015997          	auipc	s3,0x15
    800025f4:	57898993          	addi	s3,s3,1400 # 80017b68 <tickslock>
    havekids = 0;
    800025f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025fa:	0000f497          	auipc	s1,0xf
    800025fe:	76e48493          	addi	s1,s1,1902 # 80011d68 <proc>
    80002602:	a08d                	j	80002664 <wait+0xa4>
          pid = np->pid;
    80002604:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002608:	000b0e63          	beqz	s6,80002624 <wait+0x64>
    8000260c:	4691                	li	a3,4
    8000260e:	03448613          	addi	a2,s1,52
    80002612:	85da                	mv	a1,s6
    80002614:	05093503          	ld	a0,80(s2)
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	2bc080e7          	jalr	700(ra) # 800018d4 <copyout>
    80002620:	02054263          	bltz	a0,80002644 <wait+0x84>
          freeproc(np);
    80002624:	8526                	mv	a0,s1
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	7f4080e7          	jalr	2036(ra) # 80001e1a <freeproc>
          release(&np->lock);
    8000262e:	8526                	mv	a0,s1
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	684080e7          	jalr	1668(ra) # 80000cb4 <release>
          release(&p->lock);
    80002638:	854a                	mv	a0,s2
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	67a080e7          	jalr	1658(ra) # 80000cb4 <release>
          return pid;
    80002642:	a8a9                	j	8000269c <wait+0xdc>
            release(&np->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	66e080e7          	jalr	1646(ra) # 80000cb4 <release>
            release(&p->lock);
    8000264e:	854a                	mv	a0,s2
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	664080e7          	jalr	1636(ra) # 80000cb4 <release>
            return -1;
    80002658:	59fd                	li	s3,-1
    8000265a:	a089                	j	8000269c <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000265c:	17848493          	addi	s1,s1,376
    80002660:	03348463          	beq	s1,s3,80002688 <wait+0xc8>
      if(np->parent == p){
    80002664:	709c                	ld	a5,32(s1)
    80002666:	ff279be3          	bne	a5,s2,8000265c <wait+0x9c>
        acquire(&np->lock);
    8000266a:	8526                	mv	a0,s1
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	594080e7          	jalr	1428(ra) # 80000c00 <acquire>
        if(np->state == ZOMBIE){
    80002674:	4c9c                	lw	a5,24(s1)
    80002676:	f94787e3          	beq	a5,s4,80002604 <wait+0x44>
        release(&np->lock);
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	638080e7          	jalr	1592(ra) # 80000cb4 <release>
        havekids = 1;
    80002684:	8756                	mv	a4,s5
    80002686:	bfd9                	j	8000265c <wait+0x9c>
    if(!havekids || p->killed){
    80002688:	c701                	beqz	a4,80002690 <wait+0xd0>
    8000268a:	03092783          	lw	a5,48(s2)
    8000268e:	c39d                	beqz	a5,800026b4 <wait+0xf4>
      release(&p->lock);
    80002690:	854a                	mv	a0,s2
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	622080e7          	jalr	1570(ra) # 80000cb4 <release>
      return -1;
    8000269a:	59fd                	li	s3,-1
}
    8000269c:	854e                	mv	a0,s3
    8000269e:	60a6                	ld	ra,72(sp)
    800026a0:	6406                	ld	s0,64(sp)
    800026a2:	74e2                	ld	s1,56(sp)
    800026a4:	7942                	ld	s2,48(sp)
    800026a6:	79a2                	ld	s3,40(sp)
    800026a8:	7a02                	ld	s4,32(sp)
    800026aa:	6ae2                	ld	s5,24(sp)
    800026ac:	6b42                	ld	s6,16(sp)
    800026ae:	6ba2                	ld	s7,8(sp)
    800026b0:	6161                	addi	sp,sp,80
    800026b2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026b4:	85ca                	mv	a1,s2
    800026b6:	854a                	mv	a0,s2
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	e8a080e7          	jalr	-374(ra) # 80002542 <sleep>
    havekids = 0;
    800026c0:	bf25                	j	800025f8 <wait+0x38>

00000000800026c2 <wakeup>:
{
    800026c2:	7139                	addi	sp,sp,-64
    800026c4:	fc06                	sd	ra,56(sp)
    800026c6:	f822                	sd	s0,48(sp)
    800026c8:	f426                	sd	s1,40(sp)
    800026ca:	f04a                	sd	s2,32(sp)
    800026cc:	ec4e                	sd	s3,24(sp)
    800026ce:	e852                	sd	s4,16(sp)
    800026d0:	e456                	sd	s5,8(sp)
    800026d2:	0080                	addi	s0,sp,64
    800026d4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026d6:	0000f497          	auipc	s1,0xf
    800026da:	69248493          	addi	s1,s1,1682 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026de:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026e0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e2:	00015917          	auipc	s2,0x15
    800026e6:	48690913          	addi	s2,s2,1158 # 80017b68 <tickslock>
    800026ea:	a811                	j	800026fe <wakeup+0x3c>
    release(&p->lock);
    800026ec:	8526                	mv	a0,s1
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	5c6080e7          	jalr	1478(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f6:	17848493          	addi	s1,s1,376
    800026fa:	03248063          	beq	s1,s2,8000271a <wakeup+0x58>
    acquire(&p->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	500080e7          	jalr	1280(ra) # 80000c00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002708:	4c9c                	lw	a5,24(s1)
    8000270a:	ff3791e3          	bne	a5,s3,800026ec <wakeup+0x2a>
    8000270e:	749c                	ld	a5,40(s1)
    80002710:	fd479ee3          	bne	a5,s4,800026ec <wakeup+0x2a>
      p->state = RUNNABLE;
    80002714:	0154ac23          	sw	s5,24(s1)
    80002718:	bfd1                	j	800026ec <wakeup+0x2a>
}
    8000271a:	70e2                	ld	ra,56(sp)
    8000271c:	7442                	ld	s0,48(sp)
    8000271e:	74a2                	ld	s1,40(sp)
    80002720:	7902                	ld	s2,32(sp)
    80002722:	69e2                	ld	s3,24(sp)
    80002724:	6a42                	ld	s4,16(sp)
    80002726:	6aa2                	ld	s5,8(sp)
    80002728:	6121                	addi	sp,sp,64
    8000272a:	8082                	ret

000000008000272c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000272c:	7179                	addi	sp,sp,-48
    8000272e:	f406                	sd	ra,40(sp)
    80002730:	f022                	sd	s0,32(sp)
    80002732:	ec26                	sd	s1,24(sp)
    80002734:	e84a                	sd	s2,16(sp)
    80002736:	e44e                	sd	s3,8(sp)
    80002738:	1800                	addi	s0,sp,48
    8000273a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000273c:	0000f497          	auipc	s1,0xf
    80002740:	62c48493          	addi	s1,s1,1580 # 80011d68 <proc>
    80002744:	00015997          	auipc	s3,0x15
    80002748:	42498993          	addi	s3,s3,1060 # 80017b68 <tickslock>
    acquire(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	4b2080e7          	jalr	1202(ra) # 80000c00 <acquire>
    if(p->pid == pid){
    80002756:	5c9c                	lw	a5,56(s1)
    80002758:	01278d63          	beq	a5,s2,80002772 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	556080e7          	jalr	1366(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002766:	17848493          	addi	s1,s1,376
    8000276a:	ff3491e3          	bne	s1,s3,8000274c <kill+0x20>
  }
  return -1;
    8000276e:	557d                	li	a0,-1
    80002770:	a821                	j	80002788 <kill+0x5c>
      p->killed = 1;
    80002772:	4785                	li	a5,1
    80002774:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002776:	4c98                	lw	a4,24(s1)
    80002778:	00f70f63          	beq	a4,a5,80002796 <kill+0x6a>
      release(&p->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	536080e7          	jalr	1334(ra) # 80000cb4 <release>
      return 0;
    80002786:	4501                	li	a0,0
}
    80002788:	70a2                	ld	ra,40(sp)
    8000278a:	7402                	ld	s0,32(sp)
    8000278c:	64e2                	ld	s1,24(sp)
    8000278e:	6942                	ld	s2,16(sp)
    80002790:	69a2                	ld	s3,8(sp)
    80002792:	6145                	addi	sp,sp,48
    80002794:	8082                	ret
        p->state = RUNNABLE;
    80002796:	4789                	li	a5,2
    80002798:	cc9c                	sw	a5,24(s1)
    8000279a:	b7cd                	j	8000277c <kill+0x50>

000000008000279c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279c:	7179                	addi	sp,sp,-48
    8000279e:	f406                	sd	ra,40(sp)
    800027a0:	f022                	sd	s0,32(sp)
    800027a2:	ec26                	sd	s1,24(sp)
    800027a4:	e84a                	sd	s2,16(sp)
    800027a6:	e44e                	sd	s3,8(sp)
    800027a8:	e052                	sd	s4,0(sp)
    800027aa:	1800                	addi	s0,sp,48
    800027ac:	84aa                	mv	s1,a0
    800027ae:	892e                	mv	s2,a1
    800027b0:	89b2                	mv	s3,a2
    800027b2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b4:	fffff097          	auipc	ra,0xfffff
    800027b8:	45a080e7          	jalr	1114(ra) # 80001c0e <myproc>
  if(user_dst){
    800027bc:	c08d                	beqz	s1,800027de <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027be:	86d2                	mv	a3,s4
    800027c0:	864e                	mv	a2,s3
    800027c2:	85ca                	mv	a1,s2
    800027c4:	6928                	ld	a0,80(a0)
    800027c6:	fffff097          	auipc	ra,0xfffff
    800027ca:	10e080e7          	jalr	270(ra) # 800018d4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027ce:	70a2                	ld	ra,40(sp)
    800027d0:	7402                	ld	s0,32(sp)
    800027d2:	64e2                	ld	s1,24(sp)
    800027d4:	6942                	ld	s2,16(sp)
    800027d6:	69a2                	ld	s3,8(sp)
    800027d8:	6a02                	ld	s4,0(sp)
    800027da:	6145                	addi	sp,sp,48
    800027dc:	8082                	ret
    memmove((char *)dst, src, len);
    800027de:	000a061b          	sext.w	a2,s4
    800027e2:	85ce                	mv	a1,s3
    800027e4:	854a                	mv	a0,s2
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	572080e7          	jalr	1394(ra) # 80000d58 <memmove>
    return 0;
    800027ee:	8526                	mv	a0,s1
    800027f0:	bff9                	j	800027ce <either_copyout+0x32>

00000000800027f2 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f2:	7179                	addi	sp,sp,-48
    800027f4:	f406                	sd	ra,40(sp)
    800027f6:	f022                	sd	s0,32(sp)
    800027f8:	ec26                	sd	s1,24(sp)
    800027fa:	e84a                	sd	s2,16(sp)
    800027fc:	e44e                	sd	s3,8(sp)
    800027fe:	e052                	sd	s4,0(sp)
    80002800:	1800                	addi	s0,sp,48
    80002802:	892a                	mv	s2,a0
    80002804:	84ae                	mv	s1,a1
    80002806:	89b2                	mv	s3,a2
    80002808:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000280a:	fffff097          	auipc	ra,0xfffff
    8000280e:	404080e7          	jalr	1028(ra) # 80001c0e <myproc>
  if(user_src){
    80002812:	c08d                	beqz	s1,80002834 <either_copyin+0x42>
    return copyin_new(p->pagetable, dst, src, len);
    80002814:	86d2                	mv	a3,s4
    80002816:	864e                	mv	a2,s3
    80002818:	85ca                	mv	a1,s2
    8000281a:	6928                	ld	a0,80(a0)
    8000281c:	00004097          	auipc	ra,0x4
    80002820:	e3e080e7          	jalr	-450(ra) # 8000665a <copyin_new>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002824:	70a2                	ld	ra,40(sp)
    80002826:	7402                	ld	s0,32(sp)
    80002828:	64e2                	ld	s1,24(sp)
    8000282a:	6942                	ld	s2,16(sp)
    8000282c:	69a2                	ld	s3,8(sp)
    8000282e:	6a02                	ld	s4,0(sp)
    80002830:	6145                	addi	sp,sp,48
    80002832:	8082                	ret
    memmove(dst, (char*)src, len);
    80002834:	000a061b          	sext.w	a2,s4
    80002838:	85ce                	mv	a1,s3
    8000283a:	854a                	mv	a0,s2
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	51c080e7          	jalr	1308(ra) # 80000d58 <memmove>
    return 0;
    80002844:	8526                	mv	a0,s1
    80002846:	bff9                	j	80002824 <either_copyin+0x32>

0000000080002848 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002848:	715d                	addi	sp,sp,-80
    8000284a:	e486                	sd	ra,72(sp)
    8000284c:	e0a2                	sd	s0,64(sp)
    8000284e:	fc26                	sd	s1,56(sp)
    80002850:	f84a                	sd	s2,48(sp)
    80002852:	f44e                	sd	s3,40(sp)
    80002854:	f052                	sd	s4,32(sp)
    80002856:	ec56                	sd	s5,24(sp)
    80002858:	e85a                	sd	s6,16(sp)
    8000285a:	e45e                	sd	s7,8(sp)
    8000285c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000285e:	00006517          	auipc	a0,0x6
    80002862:	86a50513          	addi	a0,a0,-1942 # 800080c8 <digits+0x88>
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	d2a080e7          	jalr	-726(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000286e:	0000f497          	auipc	s1,0xf
    80002872:	65248493          	addi	s1,s1,1618 # 80011ec0 <proc+0x158>
    80002876:	00015917          	auipc	s2,0x15
    8000287a:	44a90913          	addi	s2,s2,1098 # 80017cc0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287e:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002880:	00006997          	auipc	s3,0x6
    80002884:	a2898993          	addi	s3,s3,-1496 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    80002888:	00006a97          	auipc	s5,0x6
    8000288c:	a28a8a93          	addi	s5,s5,-1496 # 800082b0 <digits+0x270>
    printf("\n");
    80002890:	00006a17          	auipc	s4,0x6
    80002894:	838a0a13          	addi	s4,s4,-1992 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002898:	00006b97          	auipc	s7,0x6
    8000289c:	a50b8b93          	addi	s7,s7,-1456 # 800082e8 <states.0>
    800028a0:	a00d                	j	800028c2 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a2:	ee06a583          	lw	a1,-288(a3)
    800028a6:	8556                	mv	a0,s5
    800028a8:	ffffe097          	auipc	ra,0xffffe
    800028ac:	ce8080e7          	jalr	-792(ra) # 80000590 <printf>
    printf("\n");
    800028b0:	8552                	mv	a0,s4
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	cde080e7          	jalr	-802(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ba:	17848493          	addi	s1,s1,376
    800028be:	03248263          	beq	s1,s2,800028e2 <procdump+0x9a>
    if(p->state == UNUSED)
    800028c2:	86a6                	mv	a3,s1
    800028c4:	ec04a783          	lw	a5,-320(s1)
    800028c8:	dbed                	beqz	a5,800028ba <procdump+0x72>
      state = "???";
    800028ca:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028cc:	fcfb6be3          	bltu	s6,a5,800028a2 <procdump+0x5a>
    800028d0:	02079713          	slli	a4,a5,0x20
    800028d4:	01d75793          	srli	a5,a4,0x1d
    800028d8:	97de                	add	a5,a5,s7
    800028da:	6390                	ld	a2,0(a5)
    800028dc:	f279                	bnez	a2,800028a2 <procdump+0x5a>
      state = "???";
    800028de:	864e                	mv	a2,s3
    800028e0:	b7c9                	j	800028a2 <procdump+0x5a>
  }
}
    800028e2:	60a6                	ld	ra,72(sp)
    800028e4:	6406                	ld	s0,64(sp)
    800028e6:	74e2                	ld	s1,56(sp)
    800028e8:	7942                	ld	s2,48(sp)
    800028ea:	79a2                	ld	s3,40(sp)
    800028ec:	7a02                	ld	s4,32(sp)
    800028ee:	6ae2                	ld	s5,24(sp)
    800028f0:	6b42                	ld	s6,16(sp)
    800028f2:	6ba2                	ld	s7,8(sp)
    800028f4:	6161                	addi	sp,sp,80
    800028f6:	8082                	ret

00000000800028f8 <swtch>:
    800028f8:	00153023          	sd	ra,0(a0)
    800028fc:	00253423          	sd	sp,8(a0)
    80002900:	e900                	sd	s0,16(a0)
    80002902:	ed04                	sd	s1,24(a0)
    80002904:	03253023          	sd	s2,32(a0)
    80002908:	03353423          	sd	s3,40(a0)
    8000290c:	03453823          	sd	s4,48(a0)
    80002910:	03553c23          	sd	s5,56(a0)
    80002914:	05653023          	sd	s6,64(a0)
    80002918:	05753423          	sd	s7,72(a0)
    8000291c:	05853823          	sd	s8,80(a0)
    80002920:	05953c23          	sd	s9,88(a0)
    80002924:	07a53023          	sd	s10,96(a0)
    80002928:	07b53423          	sd	s11,104(a0)
    8000292c:	0005b083          	ld	ra,0(a1)
    80002930:	0085b103          	ld	sp,8(a1)
    80002934:	6980                	ld	s0,16(a1)
    80002936:	6d84                	ld	s1,24(a1)
    80002938:	0205b903          	ld	s2,32(a1)
    8000293c:	0285b983          	ld	s3,40(a1)
    80002940:	0305ba03          	ld	s4,48(a1)
    80002944:	0385ba83          	ld	s5,56(a1)
    80002948:	0405bb03          	ld	s6,64(a1)
    8000294c:	0485bb83          	ld	s7,72(a1)
    80002950:	0505bc03          	ld	s8,80(a1)
    80002954:	0585bc83          	ld	s9,88(a1)
    80002958:	0605bd03          	ld	s10,96(a1)
    8000295c:	0685bd83          	ld	s11,104(a1)
    80002960:	8082                	ret

0000000080002962 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002962:	1141                	addi	sp,sp,-16
    80002964:	e406                	sd	ra,8(sp)
    80002966:	e022                	sd	s0,0(sp)
    80002968:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296a:	00006597          	auipc	a1,0x6
    8000296e:	9a658593          	addi	a1,a1,-1626 # 80008310 <states.0+0x28>
    80002972:	00015517          	auipc	a0,0x15
    80002976:	1f650513          	addi	a0,a0,502 # 80017b68 <tickslock>
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	1f6080e7          	jalr	502(ra) # 80000b70 <initlock>
}
    80002982:	60a2                	ld	ra,8(sp)
    80002984:	6402                	ld	s0,0(sp)
    80002986:	0141                	addi	sp,sp,16
    80002988:	8082                	ret

000000008000298a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298a:	1141                	addi	sp,sp,-16
    8000298c:	e422                	sd	s0,8(sp)
    8000298e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002990:	00003797          	auipc	a5,0x3
    80002994:	61078793          	addi	a5,a5,1552 # 80005fa0 <kernelvec>
    80002998:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299c:	6422                	ld	s0,8(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e406                	sd	ra,8(sp)
    800029a6:	e022                	sd	s0,0(sp)
    800029a8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029aa:	fffff097          	auipc	ra,0xfffff
    800029ae:	264080e7          	jalr	612(ra) # 80001c0e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029bc:	00004697          	auipc	a3,0x4
    800029c0:	64468693          	addi	a3,a3,1604 # 80007000 <_trampoline>
    800029c4:	00004717          	auipc	a4,0x4
    800029c8:	63c70713          	addi	a4,a4,1596 # 80007000 <_trampoline>
    800029cc:	8f15                	sub	a4,a4,a3
    800029ce:	040007b7          	lui	a5,0x4000
    800029d2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029d4:	07b2                	slli	a5,a5,0xc
    800029d6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d8:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029dc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029de:	18002673          	csrr	a2,satp
    800029e2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e4:	6d30                	ld	a2,88(a0)
    800029e6:	6138                	ld	a4,64(a0)
    800029e8:	6585                	lui	a1,0x1
    800029ea:	972e                	add	a4,a4,a1
    800029ec:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ee:	6d38                	ld	a4,88(a0)
    800029f0:	00000617          	auipc	a2,0x0
    800029f4:	13860613          	addi	a2,a2,312 # 80002b28 <usertrap>
    800029f8:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fa:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fc:	8612                	mv	a2,tp
    800029fe:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a00:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a04:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a08:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a10:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a12:	6f18                	ld	a4,24(a4)
    80002a14:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a18:	692c                	ld	a1,80(a0)
    80002a1a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1c:	00004717          	auipc	a4,0x4
    80002a20:	67470713          	addi	a4,a4,1652 # 80007090 <userret>
    80002a24:	8f15                	sub	a4,a4,a3
    80002a26:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a28:	577d                	li	a4,-1
    80002a2a:	177e                	slli	a4,a4,0x3f
    80002a2c:	8dd9                	or	a1,a1,a4
    80002a2e:	02000537          	lui	a0,0x2000
    80002a32:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a34:	0536                	slli	a0,a0,0xd
    80002a36:	9782                	jalr	a5
}
    80002a38:	60a2                	ld	ra,8(sp)
    80002a3a:	6402                	ld	s0,0(sp)
    80002a3c:	0141                	addi	sp,sp,16
    80002a3e:	8082                	ret

0000000080002a40 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4a:	00015497          	auipc	s1,0x15
    80002a4e:	11e48493          	addi	s1,s1,286 # 80017b68 <tickslock>
    80002a52:	8526                	mv	a0,s1
    80002a54:	ffffe097          	auipc	ra,0xffffe
    80002a58:	1ac080e7          	jalr	428(ra) # 80000c00 <acquire>
  ticks++;
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	5c450513          	addi	a0,a0,1476 # 80009020 <ticks>
    80002a64:	411c                	lw	a5,0(a0)
    80002a66:	2785                	addiw	a5,a5,1
    80002a68:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	c58080e7          	jalr	-936(ra) # 800026c2 <wakeup>
  release(&tickslock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	240080e7          	jalr	576(ra) # 80000cb4 <release>
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret

0000000080002a86 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a86:	1101                	addi	sp,sp,-32
    80002a88:	ec06                	sd	ra,24(sp)
    80002a8a:	e822                	sd	s0,16(sp)
    80002a8c:	e426                	sd	s1,8(sp)
    80002a8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a90:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a94:	00074d63          	bltz	a4,80002aae <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a98:	57fd                	li	a5,-1
    80002a9a:	17fe                	slli	a5,a5,0x3f
    80002a9c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa0:	06f70363          	beq	a4,a5,80002b06 <devintr+0x80>
  }
}
    80002aa4:	60e2                	ld	ra,24(sp)
    80002aa6:	6442                	ld	s0,16(sp)
    80002aa8:	64a2                	ld	s1,8(sp)
    80002aaa:	6105                	addi	sp,sp,32
    80002aac:	8082                	ret
     (scause & 0xff) == 9){
    80002aae:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002ab2:	46a5                	li	a3,9
    80002ab4:	fed792e3          	bne	a5,a3,80002a98 <devintr+0x12>
    int irq = plic_claim();
    80002ab8:	00003097          	auipc	ra,0x3
    80002abc:	5f0080e7          	jalr	1520(ra) # 800060a8 <plic_claim>
    80002ac0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac2:	47a9                	li	a5,10
    80002ac4:	02f50763          	beq	a0,a5,80002af2 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac8:	4785                	li	a5,1
    80002aca:	02f50963          	beq	a0,a5,80002afc <devintr+0x76>
    return 1;
    80002ace:	4505                	li	a0,1
    } else if(irq){
    80002ad0:	d8f1                	beqz	s1,80002aa4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	84450513          	addi	a0,a0,-1980 # 80008318 <states.0+0x30>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	ab4080e7          	jalr	-1356(ra) # 80000590 <printf>
      plic_complete(irq);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	00003097          	auipc	ra,0x3
    80002aea:	5e6080e7          	jalr	1510(ra) # 800060cc <plic_complete>
    return 1;
    80002aee:	4505                	li	a0,1
    80002af0:	bf55                	j	80002aa4 <devintr+0x1e>
      uartintr();
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	ed0080e7          	jalr	-304(ra) # 800009c2 <uartintr>
    80002afa:	b7ed                	j	80002ae4 <devintr+0x5e>
      virtio_disk_intr();
    80002afc:	00004097          	auipc	ra,0x4
    80002b00:	a44080e7          	jalr	-1468(ra) # 80006540 <virtio_disk_intr>
    80002b04:	b7c5                	j	80002ae4 <devintr+0x5e>
    if(cpuid() == 0){
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	0dc080e7          	jalr	220(ra) # 80001be2 <cpuid>
    80002b0e:	c901                	beqz	a0,80002b1e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b10:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b16:	14479073          	csrw	sip,a5
    return 2;
    80002b1a:	4509                	li	a0,2
    80002b1c:	b761                	j	80002aa4 <devintr+0x1e>
      clockintr();
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	f22080e7          	jalr	-222(ra) # 80002a40 <clockintr>
    80002b26:	b7ed                	j	80002b10 <devintr+0x8a>

0000000080002b28 <usertrap>:
{
    80002b28:	1101                	addi	sp,sp,-32
    80002b2a:	ec06                	sd	ra,24(sp)
    80002b2c:	e822                	sd	s0,16(sp)
    80002b2e:	e426                	sd	s1,8(sp)
    80002b30:	e04a                	sd	s2,0(sp)
    80002b32:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b34:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b38:	1007f793          	andi	a5,a5,256
    80002b3c:	e3ad                	bnez	a5,80002b9e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3e:	00003797          	auipc	a5,0x3
    80002b42:	46278793          	addi	a5,a5,1122 # 80005fa0 <kernelvec>
    80002b46:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	0c4080e7          	jalr	196(ra) # 80001c0e <myproc>
    80002b52:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b54:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b56:	14102773          	csrr	a4,sepc
    80002b5a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b60:	47a1                	li	a5,8
    80002b62:	04f71c63          	bne	a4,a5,80002bba <usertrap+0x92>
    if(p->killed)
    80002b66:	591c                	lw	a5,48(a0)
    80002b68:	e3b9                	bnez	a5,80002bae <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b6a:	6cb8                	ld	a4,88(s1)
    80002b6c:	6f1c                	ld	a5,24(a4)
    80002b6e:	0791                	addi	a5,a5,4
    80002b70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	2e0080e7          	jalr	736(ra) # 80002e5e <syscall>
  if(p->killed)
    80002b86:	589c                	lw	a5,48(s1)
    80002b88:	ebc1                	bnez	a5,80002c18 <usertrap+0xf0>
  usertrapret();
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	e18080e7          	jalr	-488(ra) # 800029a2 <usertrapret>
}
    80002b92:	60e2                	ld	ra,24(sp)
    80002b94:	6442                	ld	s0,16(sp)
    80002b96:	64a2                	ld	s1,8(sp)
    80002b98:	6902                	ld	s2,0(sp)
    80002b9a:	6105                	addi	sp,sp,32
    80002b9c:	8082                	ret
    panic("usertrap: not from user mode");
    80002b9e:	00005517          	auipc	a0,0x5
    80002ba2:	79a50513          	addi	a0,a0,1946 # 80008338 <states.0+0x50>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9a0080e7          	jalr	-1632(ra) # 80000546 <panic>
      exit(-1);
    80002bae:	557d                	li	a0,-1
    80002bb0:	00000097          	auipc	ra,0x0
    80002bb4:	84c080e7          	jalr	-1972(ra) # 800023fc <exit>
    80002bb8:	bf4d                	j	80002b6a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	ecc080e7          	jalr	-308(ra) # 80002a86 <devintr>
    80002bc2:	892a                	mv	s2,a0
    80002bc4:	c501                	beqz	a0,80002bcc <usertrap+0xa4>
  if(p->killed)
    80002bc6:	589c                	lw	a5,48(s1)
    80002bc8:	c3a1                	beqz	a5,80002c08 <usertrap+0xe0>
    80002bca:	a815                	j	80002bfe <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bcc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd0:	5c90                	lw	a2,56(s1)
    80002bd2:	00005517          	auipc	a0,0x5
    80002bd6:	78650513          	addi	a0,a0,1926 # 80008358 <states.0+0x70>
    80002bda:	ffffe097          	auipc	ra,0xffffe
    80002bde:	9b6080e7          	jalr	-1610(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bea:	00005517          	auipc	a0,0x5
    80002bee:	79e50513          	addi	a0,a0,1950 # 80008388 <states.0+0xa0>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	99e080e7          	jalr	-1634(ra) # 80000590 <printf>
    p->killed = 1;
    80002bfa:	4785                	li	a5,1
    80002bfc:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002bfe:	557d                	li	a0,-1
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	7fc080e7          	jalr	2044(ra) # 800023fc <exit>
  if(which_dev == 2)
    80002c08:	4789                	li	a5,2
    80002c0a:	f8f910e3          	bne	s2,a5,80002b8a <usertrap+0x62>
    yield();
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	8f8080e7          	jalr	-1800(ra) # 80002506 <yield>
    80002c16:	bf95                	j	80002b8a <usertrap+0x62>
  int which_dev = 0;
    80002c18:	4901                	li	s2,0
    80002c1a:	b7d5                	j	80002bfe <usertrap+0xd6>

0000000080002c1c <kerneltrap>:
{
    80002c1c:	7179                	addi	sp,sp,-48
    80002c1e:	f406                	sd	ra,40(sp)
    80002c20:	f022                	sd	s0,32(sp)
    80002c22:	ec26                	sd	s1,24(sp)
    80002c24:	e84a                	sd	s2,16(sp)
    80002c26:	e44e                	sd	s3,8(sp)
    80002c28:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c36:	1004f793          	andi	a5,s1,256
    80002c3a:	cb85                	beqz	a5,80002c6a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c40:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c42:	ef85                	bnez	a5,80002c7a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c44:	00000097          	auipc	ra,0x0
    80002c48:	e42080e7          	jalr	-446(ra) # 80002a86 <devintr>
    80002c4c:	cd1d                	beqz	a0,80002c8a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c4e:	4789                	li	a5,2
    80002c50:	06f50a63          	beq	a0,a5,80002cc4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c54:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c58:	10049073          	csrw	sstatus,s1
}
    80002c5c:	70a2                	ld	ra,40(sp)
    80002c5e:	7402                	ld	s0,32(sp)
    80002c60:	64e2                	ld	s1,24(sp)
    80002c62:	6942                	ld	s2,16(sp)
    80002c64:	69a2                	ld	s3,8(sp)
    80002c66:	6145                	addi	sp,sp,48
    80002c68:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	73e50513          	addi	a0,a0,1854 # 800083a8 <states.0+0xc0>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	8d4080e7          	jalr	-1836(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	75650513          	addi	a0,a0,1878 # 800083d0 <states.0+0xe8>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	8c4080e7          	jalr	-1852(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002c8a:	85ce                	mv	a1,s3
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	76450513          	addi	a0,a0,1892 # 800083f0 <states.0+0x108>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8fc080e7          	jalr	-1796(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	75c50513          	addi	a0,a0,1884 # 80008400 <states.0+0x118>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	8e4080e7          	jalr	-1820(ra) # 80000590 <printf>
    panic("kerneltrap");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	76450513          	addi	a0,a0,1892 # 80008418 <states.0+0x130>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	88a080e7          	jalr	-1910(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	f4a080e7          	jalr	-182(ra) # 80001c0e <myproc>
    80002ccc:	d541                	beqz	a0,80002c54 <kerneltrap+0x38>
    80002cce:	fffff097          	auipc	ra,0xfffff
    80002cd2:	f40080e7          	jalr	-192(ra) # 80001c0e <myproc>
    80002cd6:	4d18                	lw	a4,24(a0)
    80002cd8:	478d                	li	a5,3
    80002cda:	f6f71de3          	bne	a4,a5,80002c54 <kerneltrap+0x38>
    yield();
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	828080e7          	jalr	-2008(ra) # 80002506 <yield>
    80002ce6:	b7bd                	j	80002c54 <kerneltrap+0x38>

0000000080002ce8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce8:	1101                	addi	sp,sp,-32
    80002cea:	ec06                	sd	ra,24(sp)
    80002cec:	e822                	sd	s0,16(sp)
    80002cee:	e426                	sd	s1,8(sp)
    80002cf0:	1000                	addi	s0,sp,32
    80002cf2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	f1a080e7          	jalr	-230(ra) # 80001c0e <myproc>
  switch (n) {
    80002cfc:	4795                	li	a5,5
    80002cfe:	0497e163          	bltu	a5,s1,80002d40 <argraw+0x58>
    80002d02:	048a                	slli	s1,s1,0x2
    80002d04:	00005717          	auipc	a4,0x5
    80002d08:	74c70713          	addi	a4,a4,1868 # 80008450 <states.0+0x168>
    80002d0c:	94ba                	add	s1,s1,a4
    80002d0e:	409c                	lw	a5,0(s1)
    80002d10:	97ba                	add	a5,a5,a4
    80002d12:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d14:	6d3c                	ld	a5,88(a0)
    80002d16:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret
    return p->trapframe->a1;
    80002d22:	6d3c                	ld	a5,88(a0)
    80002d24:	7fa8                	ld	a0,120(a5)
    80002d26:	bfcd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a2;
    80002d28:	6d3c                	ld	a5,88(a0)
    80002d2a:	63c8                	ld	a0,128(a5)
    80002d2c:	b7f5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a3;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	67c8                	ld	a0,136(a5)
    80002d32:	b7dd                	j	80002d18 <argraw+0x30>
    return p->trapframe->a4;
    80002d34:	6d3c                	ld	a5,88(a0)
    80002d36:	6bc8                	ld	a0,144(a5)
    80002d38:	b7c5                	j	80002d18 <argraw+0x30>
    return p->trapframe->a5;
    80002d3a:	6d3c                	ld	a5,88(a0)
    80002d3c:	6fc8                	ld	a0,152(a5)
    80002d3e:	bfe9                	j	80002d18 <argraw+0x30>
  panic("argraw");
    80002d40:	00005517          	auipc	a0,0x5
    80002d44:	6e850513          	addi	a0,a0,1768 # 80008428 <states.0+0x140>
    80002d48:	ffffd097          	auipc	ra,0xffffd
    80002d4c:	7fe080e7          	jalr	2046(ra) # 80000546 <panic>

0000000080002d50 <fetchaddr>:
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	e04a                	sd	s2,0(sp)
    80002d5a:	1000                	addi	s0,sp,32
    80002d5c:	84aa                	mv	s1,a0
    80002d5e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	eae080e7          	jalr	-338(ra) # 80001c0e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d68:	653c                	ld	a5,72(a0)
    80002d6a:	02f4f863          	bgeu	s1,a5,80002d9a <fetchaddr+0x4a>
    80002d6e:	00848713          	addi	a4,s1,8
    80002d72:	02e7e663          	bltu	a5,a4,80002d9e <fetchaddr+0x4e>
  if(copyin_new(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d76:	46a1                	li	a3,8
    80002d78:	8626                	mv	a2,s1
    80002d7a:	85ca                	mv	a1,s2
    80002d7c:	6928                	ld	a0,80(a0)
    80002d7e:	00004097          	auipc	ra,0x4
    80002d82:	8dc080e7          	jalr	-1828(ra) # 8000665a <copyin_new>
    80002d86:	00a03533          	snez	a0,a0
    80002d8a:	40a00533          	neg	a0,a0
}
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	64a2                	ld	s1,8(sp)
    80002d94:	6902                	ld	s2,0(sp)
    80002d96:	6105                	addi	sp,sp,32
    80002d98:	8082                	ret
    return -1;
    80002d9a:	557d                	li	a0,-1
    80002d9c:	bfcd                	j	80002d8e <fetchaddr+0x3e>
    80002d9e:	557d                	li	a0,-1
    80002da0:	b7fd                	j	80002d8e <fetchaddr+0x3e>

0000000080002da2 <fetchstr>:
{
    80002da2:	7179                	addi	sp,sp,-48
    80002da4:	f406                	sd	ra,40(sp)
    80002da6:	f022                	sd	s0,32(sp)
    80002da8:	ec26                	sd	s1,24(sp)
    80002daa:	e84a                	sd	s2,16(sp)
    80002dac:	e44e                	sd	s3,8(sp)
    80002dae:	1800                	addi	s0,sp,48
    80002db0:	892a                	mv	s2,a0
    80002db2:	84ae                	mv	s1,a1
    80002db4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	e58080e7          	jalr	-424(ra) # 80001c0e <myproc>
  int err = copyinstr_new(p->pagetable, buf, addr, max);
    80002dbe:	86ce                	mv	a3,s3
    80002dc0:	864a                	mv	a2,s2
    80002dc2:	85a6                	mv	a1,s1
    80002dc4:	6928                	ld	a0,80(a0)
    80002dc6:	00004097          	auipc	ra,0x4
    80002dca:	914080e7          	jalr	-1772(ra) # 800066da <copyinstr_new>
  if(err < 0)
    80002dce:	00054763          	bltz	a0,80002ddc <fetchstr+0x3a>
  return strlen(buf);
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	0ac080e7          	jalr	172(ra) # 80000e80 <strlen>
}
    80002ddc:	70a2                	ld	ra,40(sp)
    80002dde:	7402                	ld	s0,32(sp)
    80002de0:	64e2                	ld	s1,24(sp)
    80002de2:	6942                	ld	s2,16(sp)
    80002de4:	69a2                	ld	s3,8(sp)
    80002de6:	6145                	addi	sp,sp,48
    80002de8:	8082                	ret

0000000080002dea <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	1000                	addi	s0,sp,32
    80002df4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	ef2080e7          	jalr	-270(ra) # 80002ce8 <argraw>
    80002dfe:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e00:	4501                	li	a0,0
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	1000                	addi	s0,sp,32
    80002e16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e18:	00000097          	auipc	ra,0x0
    80002e1c:	ed0080e7          	jalr	-304(ra) # 80002ce8 <argraw>
    80002e20:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e22:	4501                	li	a0,0
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	64a2                	ld	s1,8(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e2e:	1101                	addi	sp,sp,-32
    80002e30:	ec06                	sd	ra,24(sp)
    80002e32:	e822                	sd	s0,16(sp)
    80002e34:	e426                	sd	s1,8(sp)
    80002e36:	e04a                	sd	s2,0(sp)
    80002e38:	1000                	addi	s0,sp,32
    80002e3a:	84ae                	mv	s1,a1
    80002e3c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	eaa080e7          	jalr	-342(ra) # 80002ce8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e46:	864a                	mv	a2,s2
    80002e48:	85a6                	mv	a1,s1
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	f58080e7          	jalr	-168(ra) # 80002da2 <fetchstr>
}
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	64a2                	ld	s1,8(sp)
    80002e58:	6902                	ld	s2,0(sp)
    80002e5a:	6105                	addi	sp,sp,32
    80002e5c:	8082                	ret

0000000080002e5e <syscall>:
[SYS_checkvm] sys_checkvm,
};

void
syscall(void)
{
    80002e5e:	1101                	addi	sp,sp,-32
    80002e60:	ec06                	sd	ra,24(sp)
    80002e62:	e822                	sd	s0,16(sp)
    80002e64:	e426                	sd	s1,8(sp)
    80002e66:	e04a                	sd	s2,0(sp)
    80002e68:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	da4080e7          	jalr	-604(ra) # 80001c0e <myproc>
    80002e72:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e74:	05853903          	ld	s2,88(a0)
    80002e78:	0a893783          	ld	a5,168(s2)
    80002e7c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e80:	37fd                	addiw	a5,a5,-1
    80002e82:	4755                	li	a4,21
    80002e84:	00f76f63          	bltu	a4,a5,80002ea2 <syscall+0x44>
    80002e88:	00369713          	slli	a4,a3,0x3
    80002e8c:	00005797          	auipc	a5,0x5
    80002e90:	5dc78793          	addi	a5,a5,1500 # 80008468 <syscalls>
    80002e94:	97ba                	add	a5,a5,a4
    80002e96:	639c                	ld	a5,0(a5)
    80002e98:	c789                	beqz	a5,80002ea2 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e9a:	9782                	jalr	a5
    80002e9c:	06a93823          	sd	a0,112(s2)
    80002ea0:	a839                	j	80002ebe <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea2:	15848613          	addi	a2,s1,344
    80002ea6:	5c8c                	lw	a1,56(s1)
    80002ea8:	00005517          	auipc	a0,0x5
    80002eac:	58850513          	addi	a0,a0,1416 # 80008430 <states.0+0x148>
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6e0080e7          	jalr	1760(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb8:	6cbc                	ld	a5,88(s1)
    80002eba:	577d                	li	a4,-1
    80002ebc:	fbb8                	sd	a4,112(a5)
  }
}
    80002ebe:	60e2                	ld	ra,24(sp)
    80002ec0:	6442                	ld	s0,16(sp)
    80002ec2:	64a2                	ld	s1,8(sp)
    80002ec4:	6902                	ld	s2,0(sp)
    80002ec6:	6105                	addi	sp,sp,32
    80002ec8:	8082                	ret

0000000080002eca <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002eca:	1101                	addi	sp,sp,-32
    80002ecc:	ec06                	sd	ra,24(sp)
    80002ece:	e822                	sd	s0,16(sp)
    80002ed0:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed2:	fec40593          	addi	a1,s0,-20
    80002ed6:	4501                	li	a0,0
    80002ed8:	00000097          	auipc	ra,0x0
    80002edc:	f12080e7          	jalr	-238(ra) # 80002dea <argint>
    return -1;
    80002ee0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee2:	00054963          	bltz	a0,80002ef4 <sys_exit+0x2a>
  exit(n);
    80002ee6:	fec42503          	lw	a0,-20(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	512080e7          	jalr	1298(ra) # 800023fc <exit>
  return 0;  // not reached
    80002ef2:	4781                	li	a5,0
}
    80002ef4:	853e                	mv	a0,a5
    80002ef6:	60e2                	ld	ra,24(sp)
    80002ef8:	6442                	ld	s0,16(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret

0000000080002efe <sys_getpid>:

uint64
sys_getpid(void)
{
    80002efe:	1141                	addi	sp,sp,-16
    80002f00:	e406                	sd	ra,8(sp)
    80002f02:	e022                	sd	s0,0(sp)
    80002f04:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	d08080e7          	jalr	-760(ra) # 80001c0e <myproc>
}
    80002f0e:	5d08                	lw	a0,56(a0)
    80002f10:	60a2                	ld	ra,8(sp)
    80002f12:	6402                	ld	s0,0(sp)
    80002f14:	0141                	addi	sp,sp,16
    80002f16:	8082                	ret

0000000080002f18 <sys_fork>:

uint64
sys_fork(void)
{
    80002f18:	1141                	addi	sp,sp,-16
    80002f1a:	e406                	sd	ra,8(sp)
    80002f1c:	e022                	sd	s0,0(sp)
    80002f1e:	0800                	addi	s0,sp,16
  return fork();
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	182080e7          	jalr	386(ra) # 800020a2 <fork>
}
    80002f28:	60a2                	ld	ra,8(sp)
    80002f2a:	6402                	ld	s0,0(sp)
    80002f2c:	0141                	addi	sp,sp,16
    80002f2e:	8082                	ret

0000000080002f30 <sys_wait>:

uint64
sys_wait(void)
{
    80002f30:	1101                	addi	sp,sp,-32
    80002f32:	ec06                	sd	ra,24(sp)
    80002f34:	e822                	sd	s0,16(sp)
    80002f36:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f38:	fe840593          	addi	a1,s0,-24
    80002f3c:	4501                	li	a0,0
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	ece080e7          	jalr	-306(ra) # 80002e0c <argaddr>
    80002f46:	87aa                	mv	a5,a0
    return -1;
    80002f48:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f4a:	0007c863          	bltz	a5,80002f5a <sys_wait+0x2a>
  return wait(p);
    80002f4e:	fe843503          	ld	a0,-24(s0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	66e080e7          	jalr	1646(ra) # 800025c0 <wait>
}
    80002f5a:	60e2                	ld	ra,24(sp)
    80002f5c:	6442                	ld	s0,16(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret

0000000080002f62 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f62:	7179                	addi	sp,sp,-48
    80002f64:	f406                	sd	ra,40(sp)
    80002f66:	f022                	sd	s0,32(sp)
    80002f68:	ec26                	sd	s1,24(sp)
    80002f6a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f6c:	fdc40593          	addi	a1,s0,-36
    80002f70:	4501                	li	a0,0
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	e78080e7          	jalr	-392(ra) # 80002dea <argint>
    80002f7a:	87aa                	mv	a5,a0
    return -1;
    80002f7c:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f7e:	0207c063          	bltz	a5,80002f9e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	c8c080e7          	jalr	-884(ra) # 80001c0e <myproc>
    80002f8a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f8c:	fdc42503          	lw	a0,-36(s0)
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	062080e7          	jalr	98(ra) # 80001ff2 <growproc>
    80002f98:	00054863          	bltz	a0,80002fa8 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f9c:	8526                	mv	a0,s1
}
    80002f9e:	70a2                	ld	ra,40(sp)
    80002fa0:	7402                	ld	s0,32(sp)
    80002fa2:	64e2                	ld	s1,24(sp)
    80002fa4:	6145                	addi	sp,sp,48
    80002fa6:	8082                	ret
    return -1;
    80002fa8:	557d                	li	a0,-1
    80002faa:	bfd5                	j	80002f9e <sys_sbrk+0x3c>

0000000080002fac <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fac:	7139                	addi	sp,sp,-64
    80002fae:	fc06                	sd	ra,56(sp)
    80002fb0:	f822                	sd	s0,48(sp)
    80002fb2:	f426                	sd	s1,40(sp)
    80002fb4:	f04a                	sd	s2,32(sp)
    80002fb6:	ec4e                	sd	s3,24(sp)
    80002fb8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fba:	fcc40593          	addi	a1,s0,-52
    80002fbe:	4501                	li	a0,0
    80002fc0:	00000097          	auipc	ra,0x0
    80002fc4:	e2a080e7          	jalr	-470(ra) # 80002dea <argint>
    return -1;
    80002fc8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fca:	06054563          	bltz	a0,80003034 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fce:	00015517          	auipc	a0,0x15
    80002fd2:	b9a50513          	addi	a0,a0,-1126 # 80017b68 <tickslock>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c2a080e7          	jalr	-982(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002fde:	00006917          	auipc	s2,0x6
    80002fe2:	04292903          	lw	s2,66(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fe6:	fcc42783          	lw	a5,-52(s0)
    80002fea:	cf85                	beqz	a5,80003022 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fec:	00015997          	auipc	s3,0x15
    80002ff0:	b7c98993          	addi	s3,s3,-1156 # 80017b68 <tickslock>
    80002ff4:	00006497          	auipc	s1,0x6
    80002ff8:	02c48493          	addi	s1,s1,44 # 80009020 <ticks>
    if(myproc()->killed){
    80002ffc:	fffff097          	auipc	ra,0xfffff
    80003000:	c12080e7          	jalr	-1006(ra) # 80001c0e <myproc>
    80003004:	591c                	lw	a5,48(a0)
    80003006:	ef9d                	bnez	a5,80003044 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003008:	85ce                	mv	a1,s3
    8000300a:	8526                	mv	a0,s1
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	536080e7          	jalr	1334(ra) # 80002542 <sleep>
  while(ticks - ticks0 < n){
    80003014:	409c                	lw	a5,0(s1)
    80003016:	412787bb          	subw	a5,a5,s2
    8000301a:	fcc42703          	lw	a4,-52(s0)
    8000301e:	fce7efe3          	bltu	a5,a4,80002ffc <sys_sleep+0x50>
  }
  release(&tickslock);
    80003022:	00015517          	auipc	a0,0x15
    80003026:	b4650513          	addi	a0,a0,-1210 # 80017b68 <tickslock>
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	c8a080e7          	jalr	-886(ra) # 80000cb4 <release>
  return 0;
    80003032:	4781                	li	a5,0
}
    80003034:	853e                	mv	a0,a5
    80003036:	70e2                	ld	ra,56(sp)
    80003038:	7442                	ld	s0,48(sp)
    8000303a:	74a2                	ld	s1,40(sp)
    8000303c:	7902                	ld	s2,32(sp)
    8000303e:	69e2                	ld	s3,24(sp)
    80003040:	6121                	addi	sp,sp,64
    80003042:	8082                	ret
      release(&tickslock);
    80003044:	00015517          	auipc	a0,0x15
    80003048:	b2450513          	addi	a0,a0,-1244 # 80017b68 <tickslock>
    8000304c:	ffffe097          	auipc	ra,0xffffe
    80003050:	c68080e7          	jalr	-920(ra) # 80000cb4 <release>
      return -1;
    80003054:	57fd                	li	a5,-1
    80003056:	bff9                	j	80003034 <sys_sleep+0x88>

0000000080003058 <sys_kill>:

uint64
sys_kill(void)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003060:	fec40593          	addi	a1,s0,-20
    80003064:	4501                	li	a0,0
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	d84080e7          	jalr	-636(ra) # 80002dea <argint>
    8000306e:	87aa                	mv	a5,a0
    return -1;
    80003070:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003072:	0007c863          	bltz	a5,80003082 <sys_kill+0x2a>
  return kill(pid);
    80003076:	fec42503          	lw	a0,-20(s0)
    8000307a:	fffff097          	auipc	ra,0xfffff
    8000307e:	6b2080e7          	jalr	1714(ra) # 8000272c <kill>
}
    80003082:	60e2                	ld	ra,24(sp)
    80003084:	6442                	ld	s0,16(sp)
    80003086:	6105                	addi	sp,sp,32
    80003088:	8082                	ret

000000008000308a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000308a:	1101                	addi	sp,sp,-32
    8000308c:	ec06                	sd	ra,24(sp)
    8000308e:	e822                	sd	s0,16(sp)
    80003090:	e426                	sd	s1,8(sp)
    80003092:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003094:	00015517          	auipc	a0,0x15
    80003098:	ad450513          	addi	a0,a0,-1324 # 80017b68 <tickslock>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b64080e7          	jalr	-1180(ra) # 80000c00 <acquire>
  xticks = ticks;
    800030a4:	00006497          	auipc	s1,0x6
    800030a8:	f7c4a483          	lw	s1,-132(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ac:	00015517          	auipc	a0,0x15
    800030b0:	abc50513          	addi	a0,a0,-1348 # 80017b68 <tickslock>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	c00080e7          	jalr	-1024(ra) # 80000cb4 <release>
  return xticks;
}
    800030bc:	02049513          	slli	a0,s1,0x20
    800030c0:	9101                	srli	a0,a0,0x20
    800030c2:	60e2                	ld	ra,24(sp)
    800030c4:	6442                	ld	s0,16(sp)
    800030c6:	64a2                	ld	s1,8(sp)
    800030c8:	6105                	addi	sp,sp,32
    800030ca:	8082                	ret

00000000800030cc <sys_checkvm>:

uint64
sys_checkvm()
{
    800030cc:	1141                	addi	sp,sp,-16
    800030ce:	e406                	sd	ra,8(sp)
    800030d0:	e022                	sd	s0,0(sp)
    800030d2:	0800                	addi	s0,sp,16
  return (uint64)test_pagetable(); 
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	9ca080e7          	jalr	-1590(ra) # 80001a9e <test_pagetable>
    800030dc:	60a2                	ld	ra,8(sp)
    800030de:	6402                	ld	s0,0(sp)
    800030e0:	0141                	addi	sp,sp,16
    800030e2:	8082                	ret

00000000800030e4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030e4:	7179                	addi	sp,sp,-48
    800030e6:	f406                	sd	ra,40(sp)
    800030e8:	f022                	sd	s0,32(sp)
    800030ea:	ec26                	sd	s1,24(sp)
    800030ec:	e84a                	sd	s2,16(sp)
    800030ee:	e44e                	sd	s3,8(sp)
    800030f0:	e052                	sd	s4,0(sp)
    800030f2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030f4:	00005597          	auipc	a1,0x5
    800030f8:	42c58593          	addi	a1,a1,1068 # 80008520 <syscalls+0xb8>
    800030fc:	00015517          	auipc	a0,0x15
    80003100:	a8450513          	addi	a0,a0,-1404 # 80017b80 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	a6c080e7          	jalr	-1428(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000310c:	0001d797          	auipc	a5,0x1d
    80003110:	a7478793          	addi	a5,a5,-1420 # 8001fb80 <bcache+0x8000>
    80003114:	0001d717          	auipc	a4,0x1d
    80003118:	cd470713          	addi	a4,a4,-812 # 8001fde8 <bcache+0x8268>
    8000311c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003120:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003124:	00015497          	auipc	s1,0x15
    80003128:	a7448493          	addi	s1,s1,-1420 # 80017b98 <bcache+0x18>
    b->next = bcache.head.next;
    8000312c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000312e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003130:	00005a17          	auipc	s4,0x5
    80003134:	3f8a0a13          	addi	s4,s4,1016 # 80008528 <syscalls+0xc0>
    b->next = bcache.head.next;
    80003138:	2b893783          	ld	a5,696(s2)
    8000313c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000313e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003142:	85d2                	mv	a1,s4
    80003144:	01048513          	addi	a0,s1,16
    80003148:	00001097          	auipc	ra,0x1
    8000314c:	4b2080e7          	jalr	1202(ra) # 800045fa <initsleeplock>
    bcache.head.next->prev = b;
    80003150:	2b893783          	ld	a5,696(s2)
    80003154:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003156:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315a:	45848493          	addi	s1,s1,1112
    8000315e:	fd349de3          	bne	s1,s3,80003138 <binit+0x54>
  }
}
    80003162:	70a2                	ld	ra,40(sp)
    80003164:	7402                	ld	s0,32(sp)
    80003166:	64e2                	ld	s1,24(sp)
    80003168:	6942                	ld	s2,16(sp)
    8000316a:	69a2                	ld	s3,8(sp)
    8000316c:	6a02                	ld	s4,0(sp)
    8000316e:	6145                	addi	sp,sp,48
    80003170:	8082                	ret

0000000080003172 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003172:	7179                	addi	sp,sp,-48
    80003174:	f406                	sd	ra,40(sp)
    80003176:	f022                	sd	s0,32(sp)
    80003178:	ec26                	sd	s1,24(sp)
    8000317a:	e84a                	sd	s2,16(sp)
    8000317c:	e44e                	sd	s3,8(sp)
    8000317e:	1800                	addi	s0,sp,48
    80003180:	892a                	mv	s2,a0
    80003182:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003184:	00015517          	auipc	a0,0x15
    80003188:	9fc50513          	addi	a0,a0,-1540 # 80017b80 <bcache>
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	a74080e7          	jalr	-1420(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003194:	0001d497          	auipc	s1,0x1d
    80003198:	ca44b483          	ld	s1,-860(s1) # 8001fe38 <bcache+0x82b8>
    8000319c:	0001d797          	auipc	a5,0x1d
    800031a0:	c4c78793          	addi	a5,a5,-948 # 8001fde8 <bcache+0x8268>
    800031a4:	02f48f63          	beq	s1,a5,800031e2 <bread+0x70>
    800031a8:	873e                	mv	a4,a5
    800031aa:	a021                	j	800031b2 <bread+0x40>
    800031ac:	68a4                	ld	s1,80(s1)
    800031ae:	02e48a63          	beq	s1,a4,800031e2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031b2:	449c                	lw	a5,8(s1)
    800031b4:	ff279ce3          	bne	a5,s2,800031ac <bread+0x3a>
    800031b8:	44dc                	lw	a5,12(s1)
    800031ba:	ff3799e3          	bne	a5,s3,800031ac <bread+0x3a>
      b->refcnt++;
    800031be:	40bc                	lw	a5,64(s1)
    800031c0:	2785                	addiw	a5,a5,1
    800031c2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031c4:	00015517          	auipc	a0,0x15
    800031c8:	9bc50513          	addi	a0,a0,-1604 # 80017b80 <bcache>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	ae8080e7          	jalr	-1304(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    800031d4:	01048513          	addi	a0,s1,16
    800031d8:	00001097          	auipc	ra,0x1
    800031dc:	45c080e7          	jalr	1116(ra) # 80004634 <acquiresleep>
      return b;
    800031e0:	a8b9                	j	8000323e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031e2:	0001d497          	auipc	s1,0x1d
    800031e6:	c4e4b483          	ld	s1,-946(s1) # 8001fe30 <bcache+0x82b0>
    800031ea:	0001d797          	auipc	a5,0x1d
    800031ee:	bfe78793          	addi	a5,a5,-1026 # 8001fde8 <bcache+0x8268>
    800031f2:	00f48863          	beq	s1,a5,80003202 <bread+0x90>
    800031f6:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031f8:	40bc                	lw	a5,64(s1)
    800031fa:	cf81                	beqz	a5,80003212 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031fc:	64a4                	ld	s1,72(s1)
    800031fe:	fee49de3          	bne	s1,a4,800031f8 <bread+0x86>
  panic("bget: no buffers");
    80003202:	00005517          	auipc	a0,0x5
    80003206:	32e50513          	addi	a0,a0,814 # 80008530 <syscalls+0xc8>
    8000320a:	ffffd097          	auipc	ra,0xffffd
    8000320e:	33c080e7          	jalr	828(ra) # 80000546 <panic>
      b->dev = dev;
    80003212:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003216:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000321a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000321e:	4785                	li	a5,1
    80003220:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003222:	00015517          	auipc	a0,0x15
    80003226:	95e50513          	addi	a0,a0,-1698 # 80017b80 <bcache>
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	a8a080e7          	jalr	-1398(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80003232:	01048513          	addi	a0,s1,16
    80003236:	00001097          	auipc	ra,0x1
    8000323a:	3fe080e7          	jalr	1022(ra) # 80004634 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000323e:	409c                	lw	a5,0(s1)
    80003240:	cb89                	beqz	a5,80003252 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003242:	8526                	mv	a0,s1
    80003244:	70a2                	ld	ra,40(sp)
    80003246:	7402                	ld	s0,32(sp)
    80003248:	64e2                	ld	s1,24(sp)
    8000324a:	6942                	ld	s2,16(sp)
    8000324c:	69a2                	ld	s3,8(sp)
    8000324e:	6145                	addi	sp,sp,48
    80003250:	8082                	ret
    virtio_disk_rw(b, 0);
    80003252:	4581                	li	a1,0
    80003254:	8526                	mv	a0,s1
    80003256:	00003097          	auipc	ra,0x3
    8000325a:	062080e7          	jalr	98(ra) # 800062b8 <virtio_disk_rw>
    b->valid = 1;
    8000325e:	4785                	li	a5,1
    80003260:	c09c                	sw	a5,0(s1)
  return b;
    80003262:	b7c5                	j	80003242 <bread+0xd0>

0000000080003264 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003264:	1101                	addi	sp,sp,-32
    80003266:	ec06                	sd	ra,24(sp)
    80003268:	e822                	sd	s0,16(sp)
    8000326a:	e426                	sd	s1,8(sp)
    8000326c:	1000                	addi	s0,sp,32
    8000326e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003270:	0541                	addi	a0,a0,16
    80003272:	00001097          	auipc	ra,0x1
    80003276:	45c080e7          	jalr	1116(ra) # 800046ce <holdingsleep>
    8000327a:	cd01                	beqz	a0,80003292 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000327c:	4585                	li	a1,1
    8000327e:	8526                	mv	a0,s1
    80003280:	00003097          	auipc	ra,0x3
    80003284:	038080e7          	jalr	56(ra) # 800062b8 <virtio_disk_rw>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret
    panic("bwrite");
    80003292:	00005517          	auipc	a0,0x5
    80003296:	2b650513          	addi	a0,a0,694 # 80008548 <syscalls+0xe0>
    8000329a:	ffffd097          	auipc	ra,0xffffd
    8000329e:	2ac080e7          	jalr	684(ra) # 80000546 <panic>

00000000800032a2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	e04a                	sd	s2,0(sp)
    800032ac:	1000                	addi	s0,sp,32
    800032ae:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b0:	01050913          	addi	s2,a0,16
    800032b4:	854a                	mv	a0,s2
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	418080e7          	jalr	1048(ra) # 800046ce <holdingsleep>
    800032be:	c92d                	beqz	a0,80003330 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032c0:	854a                	mv	a0,s2
    800032c2:	00001097          	auipc	ra,0x1
    800032c6:	3c8080e7          	jalr	968(ra) # 8000468a <releasesleep>

  acquire(&bcache.lock);
    800032ca:	00015517          	auipc	a0,0x15
    800032ce:	8b650513          	addi	a0,a0,-1866 # 80017b80 <bcache>
    800032d2:	ffffe097          	auipc	ra,0xffffe
    800032d6:	92e080e7          	jalr	-1746(ra) # 80000c00 <acquire>
  b->refcnt--;
    800032da:	40bc                	lw	a5,64(s1)
    800032dc:	37fd                	addiw	a5,a5,-1
    800032de:	0007871b          	sext.w	a4,a5
    800032e2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032e4:	eb05                	bnez	a4,80003314 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032e6:	68bc                	ld	a5,80(s1)
    800032e8:	64b8                	ld	a4,72(s1)
    800032ea:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032ec:	64bc                	ld	a5,72(s1)
    800032ee:	68b8                	ld	a4,80(s1)
    800032f0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032f2:	0001d797          	auipc	a5,0x1d
    800032f6:	88e78793          	addi	a5,a5,-1906 # 8001fb80 <bcache+0x8000>
    800032fa:	2b87b703          	ld	a4,696(a5)
    800032fe:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003300:	0001d717          	auipc	a4,0x1d
    80003304:	ae870713          	addi	a4,a4,-1304 # 8001fde8 <bcache+0x8268>
    80003308:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000330a:	2b87b703          	ld	a4,696(a5)
    8000330e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003310:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003314:	00015517          	auipc	a0,0x15
    80003318:	86c50513          	addi	a0,a0,-1940 # 80017b80 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	998080e7          	jalr	-1640(ra) # 80000cb4 <release>
}
    80003324:	60e2                	ld	ra,24(sp)
    80003326:	6442                	ld	s0,16(sp)
    80003328:	64a2                	ld	s1,8(sp)
    8000332a:	6902                	ld	s2,0(sp)
    8000332c:	6105                	addi	sp,sp,32
    8000332e:	8082                	ret
    panic("brelse");
    80003330:	00005517          	auipc	a0,0x5
    80003334:	22050513          	addi	a0,a0,544 # 80008550 <syscalls+0xe8>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	20e080e7          	jalr	526(ra) # 80000546 <panic>

0000000080003340 <bpin>:

void
bpin(struct buf *b) {
    80003340:	1101                	addi	sp,sp,-32
    80003342:	ec06                	sd	ra,24(sp)
    80003344:	e822                	sd	s0,16(sp)
    80003346:	e426                	sd	s1,8(sp)
    80003348:	1000                	addi	s0,sp,32
    8000334a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000334c:	00015517          	auipc	a0,0x15
    80003350:	83450513          	addi	a0,a0,-1996 # 80017b80 <bcache>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	8ac080e7          	jalr	-1876(ra) # 80000c00 <acquire>
  b->refcnt++;
    8000335c:	40bc                	lw	a5,64(s1)
    8000335e:	2785                	addiw	a5,a5,1
    80003360:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003362:	00015517          	auipc	a0,0x15
    80003366:	81e50513          	addi	a0,a0,-2018 # 80017b80 <bcache>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	94a080e7          	jalr	-1718(ra) # 80000cb4 <release>
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	64a2                	ld	s1,8(sp)
    80003378:	6105                	addi	sp,sp,32
    8000337a:	8082                	ret

000000008000337c <bunpin>:

void
bunpin(struct buf *b) {
    8000337c:	1101                	addi	sp,sp,-32
    8000337e:	ec06                	sd	ra,24(sp)
    80003380:	e822                	sd	s0,16(sp)
    80003382:	e426                	sd	s1,8(sp)
    80003384:	1000                	addi	s0,sp,32
    80003386:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003388:	00014517          	auipc	a0,0x14
    8000338c:	7f850513          	addi	a0,a0,2040 # 80017b80 <bcache>
    80003390:	ffffe097          	auipc	ra,0xffffe
    80003394:	870080e7          	jalr	-1936(ra) # 80000c00 <acquire>
  b->refcnt--;
    80003398:	40bc                	lw	a5,64(s1)
    8000339a:	37fd                	addiw	a5,a5,-1
    8000339c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339e:	00014517          	auipc	a0,0x14
    800033a2:	7e250513          	addi	a0,a0,2018 # 80017b80 <bcache>
    800033a6:	ffffe097          	auipc	ra,0xffffe
    800033aa:	90e080e7          	jalr	-1778(ra) # 80000cb4 <release>
}
    800033ae:	60e2                	ld	ra,24(sp)
    800033b0:	6442                	ld	s0,16(sp)
    800033b2:	64a2                	ld	s1,8(sp)
    800033b4:	6105                	addi	sp,sp,32
    800033b6:	8082                	ret

00000000800033b8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033b8:	1101                	addi	sp,sp,-32
    800033ba:	ec06                	sd	ra,24(sp)
    800033bc:	e822                	sd	s0,16(sp)
    800033be:	e426                	sd	s1,8(sp)
    800033c0:	e04a                	sd	s2,0(sp)
    800033c2:	1000                	addi	s0,sp,32
    800033c4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033c6:	00d5d59b          	srliw	a1,a1,0xd
    800033ca:	0001d797          	auipc	a5,0x1d
    800033ce:	e927a783          	lw	a5,-366(a5) # 8002025c <sb+0x1c>
    800033d2:	9dbd                	addw	a1,a1,a5
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	d9e080e7          	jalr	-610(ra) # 80003172 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033dc:	0074f713          	andi	a4,s1,7
    800033e0:	4785                	li	a5,1
    800033e2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033e6:	14ce                	slli	s1,s1,0x33
    800033e8:	90d9                	srli	s1,s1,0x36
    800033ea:	00950733          	add	a4,a0,s1
    800033ee:	05874703          	lbu	a4,88(a4)
    800033f2:	00e7f6b3          	and	a3,a5,a4
    800033f6:	c69d                	beqz	a3,80003424 <bfree+0x6c>
    800033f8:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033fa:	94aa                	add	s1,s1,a0
    800033fc:	fff7c793          	not	a5,a5
    80003400:	8f7d                	and	a4,a4,a5
    80003402:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	108080e7          	jalr	264(ra) # 8000450e <log_write>
  brelse(bp);
    8000340e:	854a                	mv	a0,s2
    80003410:	00000097          	auipc	ra,0x0
    80003414:	e92080e7          	jalr	-366(ra) # 800032a2 <brelse>
}
    80003418:	60e2                	ld	ra,24(sp)
    8000341a:	6442                	ld	s0,16(sp)
    8000341c:	64a2                	ld	s1,8(sp)
    8000341e:	6902                	ld	s2,0(sp)
    80003420:	6105                	addi	sp,sp,32
    80003422:	8082                	ret
    panic("freeing free block");
    80003424:	00005517          	auipc	a0,0x5
    80003428:	13450513          	addi	a0,a0,308 # 80008558 <syscalls+0xf0>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	11a080e7          	jalr	282(ra) # 80000546 <panic>

0000000080003434 <balloc>:
{
    80003434:	711d                	addi	sp,sp,-96
    80003436:	ec86                	sd	ra,88(sp)
    80003438:	e8a2                	sd	s0,80(sp)
    8000343a:	e4a6                	sd	s1,72(sp)
    8000343c:	e0ca                	sd	s2,64(sp)
    8000343e:	fc4e                	sd	s3,56(sp)
    80003440:	f852                	sd	s4,48(sp)
    80003442:	f456                	sd	s5,40(sp)
    80003444:	f05a                	sd	s6,32(sp)
    80003446:	ec5e                	sd	s7,24(sp)
    80003448:	e862                	sd	s8,16(sp)
    8000344a:	e466                	sd	s9,8(sp)
    8000344c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000344e:	0001d797          	auipc	a5,0x1d
    80003452:	df67a783          	lw	a5,-522(a5) # 80020244 <sb+0x4>
    80003456:	cbc1                	beqz	a5,800034e6 <balloc+0xb2>
    80003458:	8baa                	mv	s7,a0
    8000345a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000345c:	0001db17          	auipc	s6,0x1d
    80003460:	de4b0b13          	addi	s6,s6,-540 # 80020240 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003464:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003466:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003468:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000346a:	6c89                	lui	s9,0x2
    8000346c:	a831                	j	80003488 <balloc+0x54>
    brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e32080e7          	jalr	-462(ra) # 800032a2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003478:	015c87bb          	addw	a5,s9,s5
    8000347c:	00078a9b          	sext.w	s5,a5
    80003480:	004b2703          	lw	a4,4(s6)
    80003484:	06eaf163          	bgeu	s5,a4,800034e6 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003488:	41fad79b          	sraiw	a5,s5,0x1f
    8000348c:	0137d79b          	srliw	a5,a5,0x13
    80003490:	015787bb          	addw	a5,a5,s5
    80003494:	40d7d79b          	sraiw	a5,a5,0xd
    80003498:	01cb2583          	lw	a1,28(s6)
    8000349c:	9dbd                	addw	a1,a1,a5
    8000349e:	855e                	mv	a0,s7
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	cd2080e7          	jalr	-814(ra) # 80003172 <bread>
    800034a8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034aa:	004b2503          	lw	a0,4(s6)
    800034ae:	000a849b          	sext.w	s1,s5
    800034b2:	8762                	mv	a4,s8
    800034b4:	faa4fde3          	bgeu	s1,a0,8000346e <balloc+0x3a>
      m = 1 << (bi % 8);
    800034b8:	00777693          	andi	a3,a4,7
    800034bc:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c0:	41f7579b          	sraiw	a5,a4,0x1f
    800034c4:	01d7d79b          	srliw	a5,a5,0x1d
    800034c8:	9fb9                	addw	a5,a5,a4
    800034ca:	4037d79b          	sraiw	a5,a5,0x3
    800034ce:	00f90633          	add	a2,s2,a5
    800034d2:	05864603          	lbu	a2,88(a2)
    800034d6:	00c6f5b3          	and	a1,a3,a2
    800034da:	cd91                	beqz	a1,800034f6 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034dc:	2705                	addiw	a4,a4,1
    800034de:	2485                	addiw	s1,s1,1
    800034e0:	fd471ae3          	bne	a4,s4,800034b4 <balloc+0x80>
    800034e4:	b769                	j	8000346e <balloc+0x3a>
  panic("balloc: out of blocks");
    800034e6:	00005517          	auipc	a0,0x5
    800034ea:	08a50513          	addi	a0,a0,138 # 80008570 <syscalls+0x108>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	058080e7          	jalr	88(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034f6:	97ca                	add	a5,a5,s2
    800034f8:	8e55                	or	a2,a2,a3
    800034fa:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00001097          	auipc	ra,0x1
    80003504:	00e080e7          	jalr	14(ra) # 8000450e <log_write>
        brelse(bp);
    80003508:	854a                	mv	a0,s2
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	d98080e7          	jalr	-616(ra) # 800032a2 <brelse>
  bp = bread(dev, bno);
    80003512:	85a6                	mv	a1,s1
    80003514:	855e                	mv	a0,s7
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	c5c080e7          	jalr	-932(ra) # 80003172 <bread>
    8000351e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003520:	40000613          	li	a2,1024
    80003524:	4581                	li	a1,0
    80003526:	05850513          	addi	a0,a0,88
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	7d2080e7          	jalr	2002(ra) # 80000cfc <memset>
  log_write(bp);
    80003532:	854a                	mv	a0,s2
    80003534:	00001097          	auipc	ra,0x1
    80003538:	fda080e7          	jalr	-38(ra) # 8000450e <log_write>
  brelse(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	d64080e7          	jalr	-668(ra) # 800032a2 <brelse>
}
    80003546:	8526                	mv	a0,s1
    80003548:	60e6                	ld	ra,88(sp)
    8000354a:	6446                	ld	s0,80(sp)
    8000354c:	64a6                	ld	s1,72(sp)
    8000354e:	6906                	ld	s2,64(sp)
    80003550:	79e2                	ld	s3,56(sp)
    80003552:	7a42                	ld	s4,48(sp)
    80003554:	7aa2                	ld	s5,40(sp)
    80003556:	7b02                	ld	s6,32(sp)
    80003558:	6be2                	ld	s7,24(sp)
    8000355a:	6c42                	ld	s8,16(sp)
    8000355c:	6ca2                	ld	s9,8(sp)
    8000355e:	6125                	addi	sp,sp,96
    80003560:	8082                	ret

0000000080003562 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003562:	7179                	addi	sp,sp,-48
    80003564:	f406                	sd	ra,40(sp)
    80003566:	f022                	sd	s0,32(sp)
    80003568:	ec26                	sd	s1,24(sp)
    8000356a:	e84a                	sd	s2,16(sp)
    8000356c:	e44e                	sd	s3,8(sp)
    8000356e:	e052                	sd	s4,0(sp)
    80003570:	1800                	addi	s0,sp,48
    80003572:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003574:	47ad                	li	a5,11
    80003576:	04b7fe63          	bgeu	a5,a1,800035d2 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000357a:	ff45849b          	addiw	s1,a1,-12
    8000357e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003582:	0ff00793          	li	a5,255
    80003586:	0ae7e463          	bltu	a5,a4,8000362e <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000358a:	08052583          	lw	a1,128(a0)
    8000358e:	c5b5                	beqz	a1,800035fa <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003590:	00092503          	lw	a0,0(s2)
    80003594:	00000097          	auipc	ra,0x0
    80003598:	bde080e7          	jalr	-1058(ra) # 80003172 <bread>
    8000359c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000359e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035a2:	02049713          	slli	a4,s1,0x20
    800035a6:	01e75593          	srli	a1,a4,0x1e
    800035aa:	00b784b3          	add	s1,a5,a1
    800035ae:	0004a983          	lw	s3,0(s1)
    800035b2:	04098e63          	beqz	s3,8000360e <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035b6:	8552                	mv	a0,s4
    800035b8:	00000097          	auipc	ra,0x0
    800035bc:	cea080e7          	jalr	-790(ra) # 800032a2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035c0:	854e                	mv	a0,s3
    800035c2:	70a2                	ld	ra,40(sp)
    800035c4:	7402                	ld	s0,32(sp)
    800035c6:	64e2                	ld	s1,24(sp)
    800035c8:	6942                	ld	s2,16(sp)
    800035ca:	69a2                	ld	s3,8(sp)
    800035cc:	6a02                	ld	s4,0(sp)
    800035ce:	6145                	addi	sp,sp,48
    800035d0:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035d2:	02059793          	slli	a5,a1,0x20
    800035d6:	01e7d593          	srli	a1,a5,0x1e
    800035da:	00b504b3          	add	s1,a0,a1
    800035de:	0504a983          	lw	s3,80(s1)
    800035e2:	fc099fe3          	bnez	s3,800035c0 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035e6:	4108                	lw	a0,0(a0)
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	e4c080e7          	jalr	-436(ra) # 80003434 <balloc>
    800035f0:	0005099b          	sext.w	s3,a0
    800035f4:	0534a823          	sw	s3,80(s1)
    800035f8:	b7e1                	j	800035c0 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035fa:	4108                	lw	a0,0(a0)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e38080e7          	jalr	-456(ra) # 80003434 <balloc>
    80003604:	0005059b          	sext.w	a1,a0
    80003608:	08b92023          	sw	a1,128(s2)
    8000360c:	b751                	j	80003590 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000360e:	00092503          	lw	a0,0(s2)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e22080e7          	jalr	-478(ra) # 80003434 <balloc>
    8000361a:	0005099b          	sext.w	s3,a0
    8000361e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003622:	8552                	mv	a0,s4
    80003624:	00001097          	auipc	ra,0x1
    80003628:	eea080e7          	jalr	-278(ra) # 8000450e <log_write>
    8000362c:	b769                	j	800035b6 <bmap+0x54>
  panic("bmap: out of range");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	f5a50513          	addi	a0,a0,-166 # 80008588 <syscalls+0x120>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f10080e7          	jalr	-240(ra) # 80000546 <panic>

000000008000363e <iget>:
{
    8000363e:	7179                	addi	sp,sp,-48
    80003640:	f406                	sd	ra,40(sp)
    80003642:	f022                	sd	s0,32(sp)
    80003644:	ec26                	sd	s1,24(sp)
    80003646:	e84a                	sd	s2,16(sp)
    80003648:	e44e                	sd	s3,8(sp)
    8000364a:	e052                	sd	s4,0(sp)
    8000364c:	1800                	addi	s0,sp,48
    8000364e:	89aa                	mv	s3,a0
    80003650:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003652:	0001d517          	auipc	a0,0x1d
    80003656:	c0e50513          	addi	a0,a0,-1010 # 80020260 <icache>
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	5a6080e7          	jalr	1446(ra) # 80000c00 <acquire>
  empty = 0;
    80003662:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003664:	0001d497          	auipc	s1,0x1d
    80003668:	c1448493          	addi	s1,s1,-1004 # 80020278 <icache+0x18>
    8000366c:	0001e697          	auipc	a3,0x1e
    80003670:	69c68693          	addi	a3,a3,1692 # 80021d08 <log>
    80003674:	a039                	j	80003682 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003676:	02090b63          	beqz	s2,800036ac <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000367a:	08848493          	addi	s1,s1,136
    8000367e:	02d48a63          	beq	s1,a3,800036b2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003682:	449c                	lw	a5,8(s1)
    80003684:	fef059e3          	blez	a5,80003676 <iget+0x38>
    80003688:	4098                	lw	a4,0(s1)
    8000368a:	ff3716e3          	bne	a4,s3,80003676 <iget+0x38>
    8000368e:	40d8                	lw	a4,4(s1)
    80003690:	ff4713e3          	bne	a4,s4,80003676 <iget+0x38>
      ip->ref++;
    80003694:	2785                	addiw	a5,a5,1
    80003696:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003698:	0001d517          	auipc	a0,0x1d
    8000369c:	bc850513          	addi	a0,a0,-1080 # 80020260 <icache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	614080e7          	jalr	1556(ra) # 80000cb4 <release>
      return ip;
    800036a8:	8926                	mv	s2,s1
    800036aa:	a03d                	j	800036d8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ac:	f7f9                	bnez	a5,8000367a <iget+0x3c>
    800036ae:	8926                	mv	s2,s1
    800036b0:	b7e9                	j	8000367a <iget+0x3c>
  if(empty == 0)
    800036b2:	02090c63          	beqz	s2,800036ea <iget+0xac>
  ip->dev = dev;
    800036b6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ba:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036be:	4785                	li	a5,1
    800036c0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c4:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036c8:	0001d517          	auipc	a0,0x1d
    800036cc:	b9850513          	addi	a0,a0,-1128 # 80020260 <icache>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	5e4080e7          	jalr	1508(ra) # 80000cb4 <release>
}
    800036d8:	854a                	mv	a0,s2
    800036da:	70a2                	ld	ra,40(sp)
    800036dc:	7402                	ld	s0,32(sp)
    800036de:	64e2                	ld	s1,24(sp)
    800036e0:	6942                	ld	s2,16(sp)
    800036e2:	69a2                	ld	s3,8(sp)
    800036e4:	6a02                	ld	s4,0(sp)
    800036e6:	6145                	addi	sp,sp,48
    800036e8:	8082                	ret
    panic("iget: no inodes");
    800036ea:	00005517          	auipc	a0,0x5
    800036ee:	eb650513          	addi	a0,a0,-330 # 800085a0 <syscalls+0x138>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	e54080e7          	jalr	-428(ra) # 80000546 <panic>

00000000800036fa <fsinit>:
fsinit(int dev) {
    800036fa:	7179                	addi	sp,sp,-48
    800036fc:	f406                	sd	ra,40(sp)
    800036fe:	f022                	sd	s0,32(sp)
    80003700:	ec26                	sd	s1,24(sp)
    80003702:	e84a                	sd	s2,16(sp)
    80003704:	e44e                	sd	s3,8(sp)
    80003706:	1800                	addi	s0,sp,48
    80003708:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000370a:	4585                	li	a1,1
    8000370c:	00000097          	auipc	ra,0x0
    80003710:	a66080e7          	jalr	-1434(ra) # 80003172 <bread>
    80003714:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003716:	0001d997          	auipc	s3,0x1d
    8000371a:	b2a98993          	addi	s3,s3,-1238 # 80020240 <sb>
    8000371e:	02000613          	li	a2,32
    80003722:	05850593          	addi	a1,a0,88
    80003726:	854e                	mv	a0,s3
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	630080e7          	jalr	1584(ra) # 80000d58 <memmove>
  brelse(bp);
    80003730:	8526                	mv	a0,s1
    80003732:	00000097          	auipc	ra,0x0
    80003736:	b70080e7          	jalr	-1168(ra) # 800032a2 <brelse>
  if(sb.magic != FSMAGIC)
    8000373a:	0009a703          	lw	a4,0(s3)
    8000373e:	102037b7          	lui	a5,0x10203
    80003742:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003746:	02f71263          	bne	a4,a5,8000376a <fsinit+0x70>
  initlog(dev, &sb);
    8000374a:	0001d597          	auipc	a1,0x1d
    8000374e:	af658593          	addi	a1,a1,-1290 # 80020240 <sb>
    80003752:	854a                	mv	a0,s2
    80003754:	00001097          	auipc	ra,0x1
    80003758:	b42080e7          	jalr	-1214(ra) # 80004296 <initlog>
}
    8000375c:	70a2                	ld	ra,40(sp)
    8000375e:	7402                	ld	s0,32(sp)
    80003760:	64e2                	ld	s1,24(sp)
    80003762:	6942                	ld	s2,16(sp)
    80003764:	69a2                	ld	s3,8(sp)
    80003766:	6145                	addi	sp,sp,48
    80003768:	8082                	ret
    panic("invalid file system");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	e4650513          	addi	a0,a0,-442 # 800085b0 <syscalls+0x148>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dd4080e7          	jalr	-556(ra) # 80000546 <panic>

000000008000377a <iinit>:
{
    8000377a:	7179                	addi	sp,sp,-48
    8000377c:	f406                	sd	ra,40(sp)
    8000377e:	f022                	sd	s0,32(sp)
    80003780:	ec26                	sd	s1,24(sp)
    80003782:	e84a                	sd	s2,16(sp)
    80003784:	e44e                	sd	s3,8(sp)
    80003786:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003788:	00005597          	auipc	a1,0x5
    8000378c:	e4058593          	addi	a1,a1,-448 # 800085c8 <syscalls+0x160>
    80003790:	0001d517          	auipc	a0,0x1d
    80003794:	ad050513          	addi	a0,a0,-1328 # 80020260 <icache>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	3d8080e7          	jalr	984(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a0:	0001d497          	auipc	s1,0x1d
    800037a4:	ae848493          	addi	s1,s1,-1304 # 80020288 <icache+0x28>
    800037a8:	0001e997          	auipc	s3,0x1e
    800037ac:	57098993          	addi	s3,s3,1392 # 80021d18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037b0:	00005917          	auipc	s2,0x5
    800037b4:	e2090913          	addi	s2,s2,-480 # 800085d0 <syscalls+0x168>
    800037b8:	85ca                	mv	a1,s2
    800037ba:	8526                	mv	a0,s1
    800037bc:	00001097          	auipc	ra,0x1
    800037c0:	e3e080e7          	jalr	-450(ra) # 800045fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c4:	08848493          	addi	s1,s1,136
    800037c8:	ff3498e3          	bne	s1,s3,800037b8 <iinit+0x3e>
}
    800037cc:	70a2                	ld	ra,40(sp)
    800037ce:	7402                	ld	s0,32(sp)
    800037d0:	64e2                	ld	s1,24(sp)
    800037d2:	6942                	ld	s2,16(sp)
    800037d4:	69a2                	ld	s3,8(sp)
    800037d6:	6145                	addi	sp,sp,48
    800037d8:	8082                	ret

00000000800037da <ialloc>:
{
    800037da:	715d                	addi	sp,sp,-80
    800037dc:	e486                	sd	ra,72(sp)
    800037de:	e0a2                	sd	s0,64(sp)
    800037e0:	fc26                	sd	s1,56(sp)
    800037e2:	f84a                	sd	s2,48(sp)
    800037e4:	f44e                	sd	s3,40(sp)
    800037e6:	f052                	sd	s4,32(sp)
    800037e8:	ec56                	sd	s5,24(sp)
    800037ea:	e85a                	sd	s6,16(sp)
    800037ec:	e45e                	sd	s7,8(sp)
    800037ee:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f0:	0001d717          	auipc	a4,0x1d
    800037f4:	a5c72703          	lw	a4,-1444(a4) # 8002024c <sb+0xc>
    800037f8:	4785                	li	a5,1
    800037fa:	04e7fa63          	bgeu	a5,a4,8000384e <ialloc+0x74>
    800037fe:	8aaa                	mv	s5,a0
    80003800:	8bae                	mv	s7,a1
    80003802:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003804:	0001da17          	auipc	s4,0x1d
    80003808:	a3ca0a13          	addi	s4,s4,-1476 # 80020240 <sb>
    8000380c:	00048b1b          	sext.w	s6,s1
    80003810:	0044d593          	srli	a1,s1,0x4
    80003814:	018a2783          	lw	a5,24(s4)
    80003818:	9dbd                	addw	a1,a1,a5
    8000381a:	8556                	mv	a0,s5
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	956080e7          	jalr	-1706(ra) # 80003172 <bread>
    80003824:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003826:	05850993          	addi	s3,a0,88
    8000382a:	00f4f793          	andi	a5,s1,15
    8000382e:	079a                	slli	a5,a5,0x6
    80003830:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003832:	00099783          	lh	a5,0(s3)
    80003836:	c785                	beqz	a5,8000385e <ialloc+0x84>
    brelse(bp);
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	a6a080e7          	jalr	-1430(ra) # 800032a2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003840:	0485                	addi	s1,s1,1
    80003842:	00ca2703          	lw	a4,12(s4)
    80003846:	0004879b          	sext.w	a5,s1
    8000384a:	fce7e1e3          	bltu	a5,a4,8000380c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	d8a50513          	addi	a0,a0,-630 # 800085d8 <syscalls+0x170>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	cf0080e7          	jalr	-784(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    8000385e:	04000613          	li	a2,64
    80003862:	4581                	li	a1,0
    80003864:	854e                	mv	a0,s3
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	496080e7          	jalr	1174(ra) # 80000cfc <memset>
      dip->type = type;
    8000386e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	c9a080e7          	jalr	-870(ra) # 8000450e <log_write>
      brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	a24080e7          	jalr	-1500(ra) # 800032a2 <brelse>
      return iget(dev, inum);
    80003886:	85da                	mv	a1,s6
    80003888:	8556                	mv	a0,s5
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	db4080e7          	jalr	-588(ra) # 8000363e <iget>
}
    80003892:	60a6                	ld	ra,72(sp)
    80003894:	6406                	ld	s0,64(sp)
    80003896:	74e2                	ld	s1,56(sp)
    80003898:	7942                	ld	s2,48(sp)
    8000389a:	79a2                	ld	s3,40(sp)
    8000389c:	7a02                	ld	s4,32(sp)
    8000389e:	6ae2                	ld	s5,24(sp)
    800038a0:	6b42                	ld	s6,16(sp)
    800038a2:	6ba2                	ld	s7,8(sp)
    800038a4:	6161                	addi	sp,sp,80
    800038a6:	8082                	ret

00000000800038a8 <iupdate>:
{
    800038a8:	1101                	addi	sp,sp,-32
    800038aa:	ec06                	sd	ra,24(sp)
    800038ac:	e822                	sd	s0,16(sp)
    800038ae:	e426                	sd	s1,8(sp)
    800038b0:	e04a                	sd	s2,0(sp)
    800038b2:	1000                	addi	s0,sp,32
    800038b4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038b6:	415c                	lw	a5,4(a0)
    800038b8:	0047d79b          	srliw	a5,a5,0x4
    800038bc:	0001d597          	auipc	a1,0x1d
    800038c0:	99c5a583          	lw	a1,-1636(a1) # 80020258 <sb+0x18>
    800038c4:	9dbd                	addw	a1,a1,a5
    800038c6:	4108                	lw	a0,0(a0)
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	8aa080e7          	jalr	-1878(ra) # 80003172 <bread>
    800038d0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038d2:	05850793          	addi	a5,a0,88
    800038d6:	40d8                	lw	a4,4(s1)
    800038d8:	8b3d                	andi	a4,a4,15
    800038da:	071a                	slli	a4,a4,0x6
    800038dc:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038de:	04449703          	lh	a4,68(s1)
    800038e2:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038e6:	04649703          	lh	a4,70(s1)
    800038ea:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038ee:	04849703          	lh	a4,72(s1)
    800038f2:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038f6:	04a49703          	lh	a4,74(s1)
    800038fa:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038fe:	44f8                	lw	a4,76(s1)
    80003900:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003902:	03400613          	li	a2,52
    80003906:	05048593          	addi	a1,s1,80
    8000390a:	00c78513          	addi	a0,a5,12
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	44a080e7          	jalr	1098(ra) # 80000d58 <memmove>
  log_write(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00001097          	auipc	ra,0x1
    8000391c:	bf6080e7          	jalr	-1034(ra) # 8000450e <log_write>
  brelse(bp);
    80003920:	854a                	mv	a0,s2
    80003922:	00000097          	auipc	ra,0x0
    80003926:	980080e7          	jalr	-1664(ra) # 800032a2 <brelse>
}
    8000392a:	60e2                	ld	ra,24(sp)
    8000392c:	6442                	ld	s0,16(sp)
    8000392e:	64a2                	ld	s1,8(sp)
    80003930:	6902                	ld	s2,0(sp)
    80003932:	6105                	addi	sp,sp,32
    80003934:	8082                	ret

0000000080003936 <idup>:
{
    80003936:	1101                	addi	sp,sp,-32
    80003938:	ec06                	sd	ra,24(sp)
    8000393a:	e822                	sd	s0,16(sp)
    8000393c:	e426                	sd	s1,8(sp)
    8000393e:	1000                	addi	s0,sp,32
    80003940:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003942:	0001d517          	auipc	a0,0x1d
    80003946:	91e50513          	addi	a0,a0,-1762 # 80020260 <icache>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	2b6080e7          	jalr	694(ra) # 80000c00 <acquire>
  ip->ref++;
    80003952:	449c                	lw	a5,8(s1)
    80003954:	2785                	addiw	a5,a5,1
    80003956:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003958:	0001d517          	auipc	a0,0x1d
    8000395c:	90850513          	addi	a0,a0,-1784 # 80020260 <icache>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	354080e7          	jalr	852(ra) # 80000cb4 <release>
}
    80003968:	8526                	mv	a0,s1
    8000396a:	60e2                	ld	ra,24(sp)
    8000396c:	6442                	ld	s0,16(sp)
    8000396e:	64a2                	ld	s1,8(sp)
    80003970:	6105                	addi	sp,sp,32
    80003972:	8082                	ret

0000000080003974 <ilock>:
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	e04a                	sd	s2,0(sp)
    8000397e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003980:	c115                	beqz	a0,800039a4 <ilock+0x30>
    80003982:	84aa                	mv	s1,a0
    80003984:	451c                	lw	a5,8(a0)
    80003986:	00f05f63          	blez	a5,800039a4 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000398a:	0541                	addi	a0,a0,16
    8000398c:	00001097          	auipc	ra,0x1
    80003990:	ca8080e7          	jalr	-856(ra) # 80004634 <acquiresleep>
  if(ip->valid == 0){
    80003994:	40bc                	lw	a5,64(s1)
    80003996:	cf99                	beqz	a5,800039b4 <ilock+0x40>
}
    80003998:	60e2                	ld	ra,24(sp)
    8000399a:	6442                	ld	s0,16(sp)
    8000399c:	64a2                	ld	s1,8(sp)
    8000399e:	6902                	ld	s2,0(sp)
    800039a0:	6105                	addi	sp,sp,32
    800039a2:	8082                	ret
    panic("ilock");
    800039a4:	00005517          	auipc	a0,0x5
    800039a8:	c4c50513          	addi	a0,a0,-948 # 800085f0 <syscalls+0x188>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	b9a080e7          	jalr	-1126(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039b4:	40dc                	lw	a5,4(s1)
    800039b6:	0047d79b          	srliw	a5,a5,0x4
    800039ba:	0001d597          	auipc	a1,0x1d
    800039be:	89e5a583          	lw	a1,-1890(a1) # 80020258 <sb+0x18>
    800039c2:	9dbd                	addw	a1,a1,a5
    800039c4:	4088                	lw	a0,0(s1)
    800039c6:	fffff097          	auipc	ra,0xfffff
    800039ca:	7ac080e7          	jalr	1964(ra) # 80003172 <bread>
    800039ce:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d0:	05850593          	addi	a1,a0,88
    800039d4:	40dc                	lw	a5,4(s1)
    800039d6:	8bbd                	andi	a5,a5,15
    800039d8:	079a                	slli	a5,a5,0x6
    800039da:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039dc:	00059783          	lh	a5,0(a1)
    800039e0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039e4:	00259783          	lh	a5,2(a1)
    800039e8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039ec:	00459783          	lh	a5,4(a1)
    800039f0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039f4:	00659783          	lh	a5,6(a1)
    800039f8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039fc:	459c                	lw	a5,8(a1)
    800039fe:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a00:	03400613          	li	a2,52
    80003a04:	05b1                	addi	a1,a1,12
    80003a06:	05048513          	addi	a0,s1,80
    80003a0a:	ffffd097          	auipc	ra,0xffffd
    80003a0e:	34e080e7          	jalr	846(ra) # 80000d58 <memmove>
    brelse(bp);
    80003a12:	854a                	mv	a0,s2
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	88e080e7          	jalr	-1906(ra) # 800032a2 <brelse>
    ip->valid = 1;
    80003a1c:	4785                	li	a5,1
    80003a1e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a20:	04449783          	lh	a5,68(s1)
    80003a24:	fbb5                	bnez	a5,80003998 <ilock+0x24>
      panic("ilock: no type");
    80003a26:	00005517          	auipc	a0,0x5
    80003a2a:	bd250513          	addi	a0,a0,-1070 # 800085f8 <syscalls+0x190>
    80003a2e:	ffffd097          	auipc	ra,0xffffd
    80003a32:	b18080e7          	jalr	-1256(ra) # 80000546 <panic>

0000000080003a36 <iunlock>:
{
    80003a36:	1101                	addi	sp,sp,-32
    80003a38:	ec06                	sd	ra,24(sp)
    80003a3a:	e822                	sd	s0,16(sp)
    80003a3c:	e426                	sd	s1,8(sp)
    80003a3e:	e04a                	sd	s2,0(sp)
    80003a40:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a42:	c905                	beqz	a0,80003a72 <iunlock+0x3c>
    80003a44:	84aa                	mv	s1,a0
    80003a46:	01050913          	addi	s2,a0,16
    80003a4a:	854a                	mv	a0,s2
    80003a4c:	00001097          	auipc	ra,0x1
    80003a50:	c82080e7          	jalr	-894(ra) # 800046ce <holdingsleep>
    80003a54:	cd19                	beqz	a0,80003a72 <iunlock+0x3c>
    80003a56:	449c                	lw	a5,8(s1)
    80003a58:	00f05d63          	blez	a5,80003a72 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	c2c080e7          	jalr	-980(ra) # 8000468a <releasesleep>
}
    80003a66:	60e2                	ld	ra,24(sp)
    80003a68:	6442                	ld	s0,16(sp)
    80003a6a:	64a2                	ld	s1,8(sp)
    80003a6c:	6902                	ld	s2,0(sp)
    80003a6e:	6105                	addi	sp,sp,32
    80003a70:	8082                	ret
    panic("iunlock");
    80003a72:	00005517          	auipc	a0,0x5
    80003a76:	b9650513          	addi	a0,a0,-1130 # 80008608 <syscalls+0x1a0>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	acc080e7          	jalr	-1332(ra) # 80000546 <panic>

0000000080003a82 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a82:	7179                	addi	sp,sp,-48
    80003a84:	f406                	sd	ra,40(sp)
    80003a86:	f022                	sd	s0,32(sp)
    80003a88:	ec26                	sd	s1,24(sp)
    80003a8a:	e84a                	sd	s2,16(sp)
    80003a8c:	e44e                	sd	s3,8(sp)
    80003a8e:	e052                	sd	s4,0(sp)
    80003a90:	1800                	addi	s0,sp,48
    80003a92:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a94:	05050493          	addi	s1,a0,80
    80003a98:	08050913          	addi	s2,a0,128
    80003a9c:	a021                	j	80003aa4 <itrunc+0x22>
    80003a9e:	0491                	addi	s1,s1,4
    80003aa0:	01248d63          	beq	s1,s2,80003aba <itrunc+0x38>
    if(ip->addrs[i]){
    80003aa4:	408c                	lw	a1,0(s1)
    80003aa6:	dde5                	beqz	a1,80003a9e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aa8:	0009a503          	lw	a0,0(s3)
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	90c080e7          	jalr	-1780(ra) # 800033b8 <bfree>
      ip->addrs[i] = 0;
    80003ab4:	0004a023          	sw	zero,0(s1)
    80003ab8:	b7dd                	j	80003a9e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aba:	0809a583          	lw	a1,128(s3)
    80003abe:	e185                	bnez	a1,80003ade <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ac0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ac4:	854e                	mv	a0,s3
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	de2080e7          	jalr	-542(ra) # 800038a8 <iupdate>
}
    80003ace:	70a2                	ld	ra,40(sp)
    80003ad0:	7402                	ld	s0,32(sp)
    80003ad2:	64e2                	ld	s1,24(sp)
    80003ad4:	6942                	ld	s2,16(sp)
    80003ad6:	69a2                	ld	s3,8(sp)
    80003ad8:	6a02                	ld	s4,0(sp)
    80003ada:	6145                	addi	sp,sp,48
    80003adc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ade:	0009a503          	lw	a0,0(s3)
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	690080e7          	jalr	1680(ra) # 80003172 <bread>
    80003aea:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aec:	05850493          	addi	s1,a0,88
    80003af0:	45850913          	addi	s2,a0,1112
    80003af4:	a021                	j	80003afc <itrunc+0x7a>
    80003af6:	0491                	addi	s1,s1,4
    80003af8:	01248b63          	beq	s1,s2,80003b0e <itrunc+0x8c>
      if(a[j])
    80003afc:	408c                	lw	a1,0(s1)
    80003afe:	dde5                	beqz	a1,80003af6 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b00:	0009a503          	lw	a0,0(s3)
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	8b4080e7          	jalr	-1868(ra) # 800033b8 <bfree>
    80003b0c:	b7ed                	j	80003af6 <itrunc+0x74>
    brelse(bp);
    80003b0e:	8552                	mv	a0,s4
    80003b10:	fffff097          	auipc	ra,0xfffff
    80003b14:	792080e7          	jalr	1938(ra) # 800032a2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b18:	0809a583          	lw	a1,128(s3)
    80003b1c:	0009a503          	lw	a0,0(s3)
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	898080e7          	jalr	-1896(ra) # 800033b8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b28:	0809a023          	sw	zero,128(s3)
    80003b2c:	bf51                	j	80003ac0 <itrunc+0x3e>

0000000080003b2e <iput>:
{
    80003b2e:	1101                	addi	sp,sp,-32
    80003b30:	ec06                	sd	ra,24(sp)
    80003b32:	e822                	sd	s0,16(sp)
    80003b34:	e426                	sd	s1,8(sp)
    80003b36:	e04a                	sd	s2,0(sp)
    80003b38:	1000                	addi	s0,sp,32
    80003b3a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b3c:	0001c517          	auipc	a0,0x1c
    80003b40:	72450513          	addi	a0,a0,1828 # 80020260 <icache>
    80003b44:	ffffd097          	auipc	ra,0xffffd
    80003b48:	0bc080e7          	jalr	188(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b4c:	4498                	lw	a4,8(s1)
    80003b4e:	4785                	li	a5,1
    80003b50:	02f70363          	beq	a4,a5,80003b76 <iput+0x48>
  ip->ref--;
    80003b54:	449c                	lw	a5,8(s1)
    80003b56:	37fd                	addiw	a5,a5,-1
    80003b58:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b5a:	0001c517          	auipc	a0,0x1c
    80003b5e:	70650513          	addi	a0,a0,1798 # 80020260 <icache>
    80003b62:	ffffd097          	auipc	ra,0xffffd
    80003b66:	152080e7          	jalr	338(ra) # 80000cb4 <release>
}
    80003b6a:	60e2                	ld	ra,24(sp)
    80003b6c:	6442                	ld	s0,16(sp)
    80003b6e:	64a2                	ld	s1,8(sp)
    80003b70:	6902                	ld	s2,0(sp)
    80003b72:	6105                	addi	sp,sp,32
    80003b74:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b76:	40bc                	lw	a5,64(s1)
    80003b78:	dff1                	beqz	a5,80003b54 <iput+0x26>
    80003b7a:	04a49783          	lh	a5,74(s1)
    80003b7e:	fbf9                	bnez	a5,80003b54 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b80:	01048913          	addi	s2,s1,16
    80003b84:	854a                	mv	a0,s2
    80003b86:	00001097          	auipc	ra,0x1
    80003b8a:	aae080e7          	jalr	-1362(ra) # 80004634 <acquiresleep>
    release(&icache.lock);
    80003b8e:	0001c517          	auipc	a0,0x1c
    80003b92:	6d250513          	addi	a0,a0,1746 # 80020260 <icache>
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	11e080e7          	jalr	286(ra) # 80000cb4 <release>
    itrunc(ip);
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	ee2080e7          	jalr	-286(ra) # 80003a82 <itrunc>
    ip->type = 0;
    80003ba8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bac:	8526                	mv	a0,s1
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	cfa080e7          	jalr	-774(ra) # 800038a8 <iupdate>
    ip->valid = 0;
    80003bb6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bba:	854a                	mv	a0,s2
    80003bbc:	00001097          	auipc	ra,0x1
    80003bc0:	ace080e7          	jalr	-1330(ra) # 8000468a <releasesleep>
    acquire(&icache.lock);
    80003bc4:	0001c517          	auipc	a0,0x1c
    80003bc8:	69c50513          	addi	a0,a0,1692 # 80020260 <icache>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	034080e7          	jalr	52(ra) # 80000c00 <acquire>
    80003bd4:	b741                	j	80003b54 <iput+0x26>

0000000080003bd6 <iunlockput>:
{
    80003bd6:	1101                	addi	sp,sp,-32
    80003bd8:	ec06                	sd	ra,24(sp)
    80003bda:	e822                	sd	s0,16(sp)
    80003bdc:	e426                	sd	s1,8(sp)
    80003bde:	1000                	addi	s0,sp,32
    80003be0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	e54080e7          	jalr	-428(ra) # 80003a36 <iunlock>
  iput(ip);
    80003bea:	8526                	mv	a0,s1
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	f42080e7          	jalr	-190(ra) # 80003b2e <iput>
}
    80003bf4:	60e2                	ld	ra,24(sp)
    80003bf6:	6442                	ld	s0,16(sp)
    80003bf8:	64a2                	ld	s1,8(sp)
    80003bfa:	6105                	addi	sp,sp,32
    80003bfc:	8082                	ret

0000000080003bfe <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bfe:	1141                	addi	sp,sp,-16
    80003c00:	e422                	sd	s0,8(sp)
    80003c02:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c04:	411c                	lw	a5,0(a0)
    80003c06:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c08:	415c                	lw	a5,4(a0)
    80003c0a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c0c:	04451783          	lh	a5,68(a0)
    80003c10:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c14:	04a51783          	lh	a5,74(a0)
    80003c18:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c1c:	04c56783          	lwu	a5,76(a0)
    80003c20:	e99c                	sd	a5,16(a1)
}
    80003c22:	6422                	ld	s0,8(sp)
    80003c24:	0141                	addi	sp,sp,16
    80003c26:	8082                	ret

0000000080003c28 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c28:	457c                	lw	a5,76(a0)
    80003c2a:	0ed7e863          	bltu	a5,a3,80003d1a <readi+0xf2>
{
    80003c2e:	7159                	addi	sp,sp,-112
    80003c30:	f486                	sd	ra,104(sp)
    80003c32:	f0a2                	sd	s0,96(sp)
    80003c34:	eca6                	sd	s1,88(sp)
    80003c36:	e8ca                	sd	s2,80(sp)
    80003c38:	e4ce                	sd	s3,72(sp)
    80003c3a:	e0d2                	sd	s4,64(sp)
    80003c3c:	fc56                	sd	s5,56(sp)
    80003c3e:	f85a                	sd	s6,48(sp)
    80003c40:	f45e                	sd	s7,40(sp)
    80003c42:	f062                	sd	s8,32(sp)
    80003c44:	ec66                	sd	s9,24(sp)
    80003c46:	e86a                	sd	s10,16(sp)
    80003c48:	e46e                	sd	s11,8(sp)
    80003c4a:	1880                	addi	s0,sp,112
    80003c4c:	8baa                	mv	s7,a0
    80003c4e:	8c2e                	mv	s8,a1
    80003c50:	8ab2                	mv	s5,a2
    80003c52:	84b6                	mv	s1,a3
    80003c54:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c56:	9f35                	addw	a4,a4,a3
    return 0;
    80003c58:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c5a:	08d76f63          	bltu	a4,a3,80003cf8 <readi+0xd0>
  if(off + n > ip->size)
    80003c5e:	00e7f463          	bgeu	a5,a4,80003c66 <readi+0x3e>
    n = ip->size - off;
    80003c62:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c66:	0a0b0863          	beqz	s6,80003d16 <readi+0xee>
    80003c6a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c6c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c70:	5cfd                	li	s9,-1
    80003c72:	a82d                	j	80003cac <readi+0x84>
    80003c74:	020a1d93          	slli	s11,s4,0x20
    80003c78:	020ddd93          	srli	s11,s11,0x20
    80003c7c:	05890613          	addi	a2,s2,88
    80003c80:	86ee                	mv	a3,s11
    80003c82:	963a                	add	a2,a2,a4
    80003c84:	85d6                	mv	a1,s5
    80003c86:	8562                	mv	a0,s8
    80003c88:	fffff097          	auipc	ra,0xfffff
    80003c8c:	b14080e7          	jalr	-1260(ra) # 8000279c <either_copyout>
    80003c90:	05950d63          	beq	a0,s9,80003cea <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c94:	854a                	mv	a0,s2
    80003c96:	fffff097          	auipc	ra,0xfffff
    80003c9a:	60c080e7          	jalr	1548(ra) # 800032a2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c9e:	013a09bb          	addw	s3,s4,s3
    80003ca2:	009a04bb          	addw	s1,s4,s1
    80003ca6:	9aee                	add	s5,s5,s11
    80003ca8:	0569f663          	bgeu	s3,s6,80003cf4 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cac:	000ba903          	lw	s2,0(s7)
    80003cb0:	00a4d59b          	srliw	a1,s1,0xa
    80003cb4:	855e                	mv	a0,s7
    80003cb6:	00000097          	auipc	ra,0x0
    80003cba:	8ac080e7          	jalr	-1876(ra) # 80003562 <bmap>
    80003cbe:	0005059b          	sext.w	a1,a0
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	fffff097          	auipc	ra,0xfffff
    80003cc8:	4ae080e7          	jalr	1198(ra) # 80003172 <bread>
    80003ccc:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cce:	3ff4f713          	andi	a4,s1,1023
    80003cd2:	40ed07bb          	subw	a5,s10,a4
    80003cd6:	413b06bb          	subw	a3,s6,s3
    80003cda:	8a3e                	mv	s4,a5
    80003cdc:	2781                	sext.w	a5,a5
    80003cde:	0006861b          	sext.w	a2,a3
    80003ce2:	f8f679e3          	bgeu	a2,a5,80003c74 <readi+0x4c>
    80003ce6:	8a36                	mv	s4,a3
    80003ce8:	b771                	j	80003c74 <readi+0x4c>
      brelse(bp);
    80003cea:	854a                	mv	a0,s2
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	5b6080e7          	jalr	1462(ra) # 800032a2 <brelse>
  }
  return tot;
    80003cf4:	0009851b          	sext.w	a0,s3
}
    80003cf8:	70a6                	ld	ra,104(sp)
    80003cfa:	7406                	ld	s0,96(sp)
    80003cfc:	64e6                	ld	s1,88(sp)
    80003cfe:	6946                	ld	s2,80(sp)
    80003d00:	69a6                	ld	s3,72(sp)
    80003d02:	6a06                	ld	s4,64(sp)
    80003d04:	7ae2                	ld	s5,56(sp)
    80003d06:	7b42                	ld	s6,48(sp)
    80003d08:	7ba2                	ld	s7,40(sp)
    80003d0a:	7c02                	ld	s8,32(sp)
    80003d0c:	6ce2                	ld	s9,24(sp)
    80003d0e:	6d42                	ld	s10,16(sp)
    80003d10:	6da2                	ld	s11,8(sp)
    80003d12:	6165                	addi	sp,sp,112
    80003d14:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d16:	89da                	mv	s3,s6
    80003d18:	bff1                	j	80003cf4 <readi+0xcc>
    return 0;
    80003d1a:	4501                	li	a0,0
}
    80003d1c:	8082                	ret

0000000080003d1e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d1e:	457c                	lw	a5,76(a0)
    80003d20:	10d7e663          	bltu	a5,a3,80003e2c <writei+0x10e>
{
    80003d24:	7159                	addi	sp,sp,-112
    80003d26:	f486                	sd	ra,104(sp)
    80003d28:	f0a2                	sd	s0,96(sp)
    80003d2a:	eca6                	sd	s1,88(sp)
    80003d2c:	e8ca                	sd	s2,80(sp)
    80003d2e:	e4ce                	sd	s3,72(sp)
    80003d30:	e0d2                	sd	s4,64(sp)
    80003d32:	fc56                	sd	s5,56(sp)
    80003d34:	f85a                	sd	s6,48(sp)
    80003d36:	f45e                	sd	s7,40(sp)
    80003d38:	f062                	sd	s8,32(sp)
    80003d3a:	ec66                	sd	s9,24(sp)
    80003d3c:	e86a                	sd	s10,16(sp)
    80003d3e:	e46e                	sd	s11,8(sp)
    80003d40:	1880                	addi	s0,sp,112
    80003d42:	8baa                	mv	s7,a0
    80003d44:	8c2e                	mv	s8,a1
    80003d46:	8ab2                	mv	s5,a2
    80003d48:	8936                	mv	s2,a3
    80003d4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d4c:	00e687bb          	addw	a5,a3,a4
    80003d50:	0ed7e063          	bltu	a5,a3,80003e30 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d54:	00043737          	lui	a4,0x43
    80003d58:	0cf76e63          	bltu	a4,a5,80003e34 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5c:	0a0b0763          	beqz	s6,80003e0a <writei+0xec>
    80003d60:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d62:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d66:	5cfd                	li	s9,-1
    80003d68:	a091                	j	80003dac <writei+0x8e>
    80003d6a:	02099d93          	slli	s11,s3,0x20
    80003d6e:	020ddd93          	srli	s11,s11,0x20
    80003d72:	05848513          	addi	a0,s1,88
    80003d76:	86ee                	mv	a3,s11
    80003d78:	8656                	mv	a2,s5
    80003d7a:	85e2                	mv	a1,s8
    80003d7c:	953a                	add	a0,a0,a4
    80003d7e:	fffff097          	auipc	ra,0xfffff
    80003d82:	a74080e7          	jalr	-1420(ra) # 800027f2 <either_copyin>
    80003d86:	07950263          	beq	a0,s9,80003dea <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d8a:	8526                	mv	a0,s1
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	782080e7          	jalr	1922(ra) # 8000450e <log_write>
    brelse(bp);
    80003d94:	8526                	mv	a0,s1
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	50c080e7          	jalr	1292(ra) # 800032a2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d9e:	01498a3b          	addw	s4,s3,s4
    80003da2:	0129893b          	addw	s2,s3,s2
    80003da6:	9aee                	add	s5,s5,s11
    80003da8:	056a7663          	bgeu	s4,s6,80003df4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dac:	000ba483          	lw	s1,0(s7)
    80003db0:	00a9559b          	srliw	a1,s2,0xa
    80003db4:	855e                	mv	a0,s7
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	7ac080e7          	jalr	1964(ra) # 80003562 <bmap>
    80003dbe:	0005059b          	sext.w	a1,a0
    80003dc2:	8526                	mv	a0,s1
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	3ae080e7          	jalr	942(ra) # 80003172 <bread>
    80003dcc:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dce:	3ff97713          	andi	a4,s2,1023
    80003dd2:	40ed07bb          	subw	a5,s10,a4
    80003dd6:	414b06bb          	subw	a3,s6,s4
    80003dda:	89be                	mv	s3,a5
    80003ddc:	2781                	sext.w	a5,a5
    80003dde:	0006861b          	sext.w	a2,a3
    80003de2:	f8f674e3          	bgeu	a2,a5,80003d6a <writei+0x4c>
    80003de6:	89b6                	mv	s3,a3
    80003de8:	b749                	j	80003d6a <writei+0x4c>
      brelse(bp);
    80003dea:	8526                	mv	a0,s1
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	4b6080e7          	jalr	1206(ra) # 800032a2 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003df4:	04cba783          	lw	a5,76(s7)
    80003df8:	0127f463          	bgeu	a5,s2,80003e00 <writei+0xe2>
      ip->size = off;
    80003dfc:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e00:	855e                	mv	a0,s7
    80003e02:	00000097          	auipc	ra,0x0
    80003e06:	aa6080e7          	jalr	-1370(ra) # 800038a8 <iupdate>
  }

  return n;
    80003e0a:	000b051b          	sext.w	a0,s6
}
    80003e0e:	70a6                	ld	ra,104(sp)
    80003e10:	7406                	ld	s0,96(sp)
    80003e12:	64e6                	ld	s1,88(sp)
    80003e14:	6946                	ld	s2,80(sp)
    80003e16:	69a6                	ld	s3,72(sp)
    80003e18:	6a06                	ld	s4,64(sp)
    80003e1a:	7ae2                	ld	s5,56(sp)
    80003e1c:	7b42                	ld	s6,48(sp)
    80003e1e:	7ba2                	ld	s7,40(sp)
    80003e20:	7c02                	ld	s8,32(sp)
    80003e22:	6ce2                	ld	s9,24(sp)
    80003e24:	6d42                	ld	s10,16(sp)
    80003e26:	6da2                	ld	s11,8(sp)
    80003e28:	6165                	addi	sp,sp,112
    80003e2a:	8082                	ret
    return -1;
    80003e2c:	557d                	li	a0,-1
}
    80003e2e:	8082                	ret
    return -1;
    80003e30:	557d                	li	a0,-1
    80003e32:	bff1                	j	80003e0e <writei+0xf0>
    return -1;
    80003e34:	557d                	li	a0,-1
    80003e36:	bfe1                	j	80003e0e <writei+0xf0>

0000000080003e38 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e38:	1141                	addi	sp,sp,-16
    80003e3a:	e406                	sd	ra,8(sp)
    80003e3c:	e022                	sd	s0,0(sp)
    80003e3e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e40:	4639                	li	a2,14
    80003e42:	ffffd097          	auipc	ra,0xffffd
    80003e46:	f92080e7          	jalr	-110(ra) # 80000dd4 <strncmp>
}
    80003e4a:	60a2                	ld	ra,8(sp)
    80003e4c:	6402                	ld	s0,0(sp)
    80003e4e:	0141                	addi	sp,sp,16
    80003e50:	8082                	ret

0000000080003e52 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e52:	7139                	addi	sp,sp,-64
    80003e54:	fc06                	sd	ra,56(sp)
    80003e56:	f822                	sd	s0,48(sp)
    80003e58:	f426                	sd	s1,40(sp)
    80003e5a:	f04a                	sd	s2,32(sp)
    80003e5c:	ec4e                	sd	s3,24(sp)
    80003e5e:	e852                	sd	s4,16(sp)
    80003e60:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e62:	04451703          	lh	a4,68(a0)
    80003e66:	4785                	li	a5,1
    80003e68:	00f71a63          	bne	a4,a5,80003e7c <dirlookup+0x2a>
    80003e6c:	892a                	mv	s2,a0
    80003e6e:	89ae                	mv	s3,a1
    80003e70:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e72:	457c                	lw	a5,76(a0)
    80003e74:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e76:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e78:	e79d                	bnez	a5,80003ea6 <dirlookup+0x54>
    80003e7a:	a8a5                	j	80003ef2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e7c:	00004517          	auipc	a0,0x4
    80003e80:	79450513          	addi	a0,a0,1940 # 80008610 <syscalls+0x1a8>
    80003e84:	ffffc097          	auipc	ra,0xffffc
    80003e88:	6c2080e7          	jalr	1730(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003e8c:	00004517          	auipc	a0,0x4
    80003e90:	79c50513          	addi	a0,a0,1948 # 80008628 <syscalls+0x1c0>
    80003e94:	ffffc097          	auipc	ra,0xffffc
    80003e98:	6b2080e7          	jalr	1714(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9c:	24c1                	addiw	s1,s1,16
    80003e9e:	04c92783          	lw	a5,76(s2)
    80003ea2:	04f4f763          	bgeu	s1,a5,80003ef0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea6:	4741                	li	a4,16
    80003ea8:	86a6                	mv	a3,s1
    80003eaa:	fc040613          	addi	a2,s0,-64
    80003eae:	4581                	li	a1,0
    80003eb0:	854a                	mv	a0,s2
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	d76080e7          	jalr	-650(ra) # 80003c28 <readi>
    80003eba:	47c1                	li	a5,16
    80003ebc:	fcf518e3          	bne	a0,a5,80003e8c <dirlookup+0x3a>
    if(de.inum == 0)
    80003ec0:	fc045783          	lhu	a5,-64(s0)
    80003ec4:	dfe1                	beqz	a5,80003e9c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ec6:	fc240593          	addi	a1,s0,-62
    80003eca:	854e                	mv	a0,s3
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	f6c080e7          	jalr	-148(ra) # 80003e38 <namecmp>
    80003ed4:	f561                	bnez	a0,80003e9c <dirlookup+0x4a>
      if(poff)
    80003ed6:	000a0463          	beqz	s4,80003ede <dirlookup+0x8c>
        *poff = off;
    80003eda:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ede:	fc045583          	lhu	a1,-64(s0)
    80003ee2:	00092503          	lw	a0,0(s2)
    80003ee6:	fffff097          	auipc	ra,0xfffff
    80003eea:	758080e7          	jalr	1880(ra) # 8000363e <iget>
    80003eee:	a011                	j	80003ef2 <dirlookup+0xa0>
  return 0;
    80003ef0:	4501                	li	a0,0
}
    80003ef2:	70e2                	ld	ra,56(sp)
    80003ef4:	7442                	ld	s0,48(sp)
    80003ef6:	74a2                	ld	s1,40(sp)
    80003ef8:	7902                	ld	s2,32(sp)
    80003efa:	69e2                	ld	s3,24(sp)
    80003efc:	6a42                	ld	s4,16(sp)
    80003efe:	6121                	addi	sp,sp,64
    80003f00:	8082                	ret

0000000080003f02 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f02:	711d                	addi	sp,sp,-96
    80003f04:	ec86                	sd	ra,88(sp)
    80003f06:	e8a2                	sd	s0,80(sp)
    80003f08:	e4a6                	sd	s1,72(sp)
    80003f0a:	e0ca                	sd	s2,64(sp)
    80003f0c:	fc4e                	sd	s3,56(sp)
    80003f0e:	f852                	sd	s4,48(sp)
    80003f10:	f456                	sd	s5,40(sp)
    80003f12:	f05a                	sd	s6,32(sp)
    80003f14:	ec5e                	sd	s7,24(sp)
    80003f16:	e862                	sd	s8,16(sp)
    80003f18:	e466                	sd	s9,8(sp)
    80003f1a:	e06a                	sd	s10,0(sp)
    80003f1c:	1080                	addi	s0,sp,96
    80003f1e:	84aa                	mv	s1,a0
    80003f20:	8b2e                	mv	s6,a1
    80003f22:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f24:	00054703          	lbu	a4,0(a0)
    80003f28:	02f00793          	li	a5,47
    80003f2c:	02f70363          	beq	a4,a5,80003f52 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f30:	ffffe097          	auipc	ra,0xffffe
    80003f34:	cde080e7          	jalr	-802(ra) # 80001c0e <myproc>
    80003f38:	15053503          	ld	a0,336(a0)
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	9fa080e7          	jalr	-1542(ra) # 80003936 <idup>
    80003f44:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f46:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f4a:	4cb5                	li	s9,13
  len = path - s;
    80003f4c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f4e:	4c05                	li	s8,1
    80003f50:	a87d                	j	8000400e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f52:	4585                	li	a1,1
    80003f54:	4505                	li	a0,1
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	6e8080e7          	jalr	1768(ra) # 8000363e <iget>
    80003f5e:	8a2a                	mv	s4,a0
    80003f60:	b7dd                	j	80003f46 <namex+0x44>
      iunlockput(ip);
    80003f62:	8552                	mv	a0,s4
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	c72080e7          	jalr	-910(ra) # 80003bd6 <iunlockput>
      return 0;
    80003f6c:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f6e:	8552                	mv	a0,s4
    80003f70:	60e6                	ld	ra,88(sp)
    80003f72:	6446                	ld	s0,80(sp)
    80003f74:	64a6                	ld	s1,72(sp)
    80003f76:	6906                	ld	s2,64(sp)
    80003f78:	79e2                	ld	s3,56(sp)
    80003f7a:	7a42                	ld	s4,48(sp)
    80003f7c:	7aa2                	ld	s5,40(sp)
    80003f7e:	7b02                	ld	s6,32(sp)
    80003f80:	6be2                	ld	s7,24(sp)
    80003f82:	6c42                	ld	s8,16(sp)
    80003f84:	6ca2                	ld	s9,8(sp)
    80003f86:	6d02                	ld	s10,0(sp)
    80003f88:	6125                	addi	sp,sp,96
    80003f8a:	8082                	ret
      iunlock(ip);
    80003f8c:	8552                	mv	a0,s4
    80003f8e:	00000097          	auipc	ra,0x0
    80003f92:	aa8080e7          	jalr	-1368(ra) # 80003a36 <iunlock>
      return ip;
    80003f96:	bfe1                	j	80003f6e <namex+0x6c>
      iunlockput(ip);
    80003f98:	8552                	mv	a0,s4
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	c3c080e7          	jalr	-964(ra) # 80003bd6 <iunlockput>
      return 0;
    80003fa2:	8a4e                	mv	s4,s3
    80003fa4:	b7e9                	j	80003f6e <namex+0x6c>
  len = path - s;
    80003fa6:	40998633          	sub	a2,s3,s1
    80003faa:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003fae:	09acd863          	bge	s9,s10,8000403e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003fb2:	4639                	li	a2,14
    80003fb4:	85a6                	mv	a1,s1
    80003fb6:	8556                	mv	a0,s5
    80003fb8:	ffffd097          	auipc	ra,0xffffd
    80003fbc:	da0080e7          	jalr	-608(ra) # 80000d58 <memmove>
    80003fc0:	84ce                	mv	s1,s3
  while(*path == '/')
    80003fc2:	0004c783          	lbu	a5,0(s1)
    80003fc6:	01279763          	bne	a5,s2,80003fd4 <namex+0xd2>
    path++;
    80003fca:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fcc:	0004c783          	lbu	a5,0(s1)
    80003fd0:	ff278de3          	beq	a5,s2,80003fca <namex+0xc8>
    ilock(ip);
    80003fd4:	8552                	mv	a0,s4
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	99e080e7          	jalr	-1634(ra) # 80003974 <ilock>
    if(ip->type != T_DIR){
    80003fde:	044a1783          	lh	a5,68(s4)
    80003fe2:	f98790e3          	bne	a5,s8,80003f62 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fe6:	000b0563          	beqz	s6,80003ff0 <namex+0xee>
    80003fea:	0004c783          	lbu	a5,0(s1)
    80003fee:	dfd9                	beqz	a5,80003f8c <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff0:	865e                	mv	a2,s7
    80003ff2:	85d6                	mv	a1,s5
    80003ff4:	8552                	mv	a0,s4
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	e5c080e7          	jalr	-420(ra) # 80003e52 <dirlookup>
    80003ffe:	89aa                	mv	s3,a0
    80004000:	dd41                	beqz	a0,80003f98 <namex+0x96>
    iunlockput(ip);
    80004002:	8552                	mv	a0,s4
    80004004:	00000097          	auipc	ra,0x0
    80004008:	bd2080e7          	jalr	-1070(ra) # 80003bd6 <iunlockput>
    ip = next;
    8000400c:	8a4e                	mv	s4,s3
  while(*path == '/')
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	01279763          	bne	a5,s2,80004020 <namex+0x11e>
    path++;
    80004016:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004018:	0004c783          	lbu	a5,0(s1)
    8000401c:	ff278de3          	beq	a5,s2,80004016 <namex+0x114>
  if(*path == 0)
    80004020:	cb9d                	beqz	a5,80004056 <namex+0x154>
  while(*path != '/' && *path != 0)
    80004022:	0004c783          	lbu	a5,0(s1)
    80004026:	89a6                	mv	s3,s1
  len = path - s;
    80004028:	8d5e                	mv	s10,s7
    8000402a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000402c:	01278963          	beq	a5,s2,8000403e <namex+0x13c>
    80004030:	dbbd                	beqz	a5,80003fa6 <namex+0xa4>
    path++;
    80004032:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004034:	0009c783          	lbu	a5,0(s3)
    80004038:	ff279ce3          	bne	a5,s2,80004030 <namex+0x12e>
    8000403c:	b7ad                	j	80003fa6 <namex+0xa4>
    memmove(name, s, len);
    8000403e:	2601                	sext.w	a2,a2
    80004040:	85a6                	mv	a1,s1
    80004042:	8556                	mv	a0,s5
    80004044:	ffffd097          	auipc	ra,0xffffd
    80004048:	d14080e7          	jalr	-748(ra) # 80000d58 <memmove>
    name[len] = 0;
    8000404c:	9d56                	add	s10,s10,s5
    8000404e:	000d0023          	sb	zero,0(s10)
    80004052:	84ce                	mv	s1,s3
    80004054:	b7bd                	j	80003fc2 <namex+0xc0>
  if(nameiparent){
    80004056:	f00b0ce3          	beqz	s6,80003f6e <namex+0x6c>
    iput(ip);
    8000405a:	8552                	mv	a0,s4
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	ad2080e7          	jalr	-1326(ra) # 80003b2e <iput>
    return 0;
    80004064:	4a01                	li	s4,0
    80004066:	b721                	j	80003f6e <namex+0x6c>

0000000080004068 <dirlink>:
{
    80004068:	7139                	addi	sp,sp,-64
    8000406a:	fc06                	sd	ra,56(sp)
    8000406c:	f822                	sd	s0,48(sp)
    8000406e:	f426                	sd	s1,40(sp)
    80004070:	f04a                	sd	s2,32(sp)
    80004072:	ec4e                	sd	s3,24(sp)
    80004074:	e852                	sd	s4,16(sp)
    80004076:	0080                	addi	s0,sp,64
    80004078:	892a                	mv	s2,a0
    8000407a:	8a2e                	mv	s4,a1
    8000407c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000407e:	4601                	li	a2,0
    80004080:	00000097          	auipc	ra,0x0
    80004084:	dd2080e7          	jalr	-558(ra) # 80003e52 <dirlookup>
    80004088:	e93d                	bnez	a0,800040fe <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000408a:	04c92483          	lw	s1,76(s2)
    8000408e:	c49d                	beqz	s1,800040bc <dirlink+0x54>
    80004090:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004092:	4741                	li	a4,16
    80004094:	86a6                	mv	a3,s1
    80004096:	fc040613          	addi	a2,s0,-64
    8000409a:	4581                	li	a1,0
    8000409c:	854a                	mv	a0,s2
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	b8a080e7          	jalr	-1142(ra) # 80003c28 <readi>
    800040a6:	47c1                	li	a5,16
    800040a8:	06f51163          	bne	a0,a5,8000410a <dirlink+0xa2>
    if(de.inum == 0)
    800040ac:	fc045783          	lhu	a5,-64(s0)
    800040b0:	c791                	beqz	a5,800040bc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b2:	24c1                	addiw	s1,s1,16
    800040b4:	04c92783          	lw	a5,76(s2)
    800040b8:	fcf4ede3          	bltu	s1,a5,80004092 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040bc:	4639                	li	a2,14
    800040be:	85d2                	mv	a1,s4
    800040c0:	fc240513          	addi	a0,s0,-62
    800040c4:	ffffd097          	auipc	ra,0xffffd
    800040c8:	d4c080e7          	jalr	-692(ra) # 80000e10 <strncpy>
  de.inum = inum;
    800040cc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d0:	4741                	li	a4,16
    800040d2:	86a6                	mv	a3,s1
    800040d4:	fc040613          	addi	a2,s0,-64
    800040d8:	4581                	li	a1,0
    800040da:	854a                	mv	a0,s2
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	c42080e7          	jalr	-958(ra) # 80003d1e <writei>
    800040e4:	872a                	mv	a4,a0
    800040e6:	47c1                	li	a5,16
  return 0;
    800040e8:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ea:	02f71863          	bne	a4,a5,8000411a <dirlink+0xb2>
}
    800040ee:	70e2                	ld	ra,56(sp)
    800040f0:	7442                	ld	s0,48(sp)
    800040f2:	74a2                	ld	s1,40(sp)
    800040f4:	7902                	ld	s2,32(sp)
    800040f6:	69e2                	ld	s3,24(sp)
    800040f8:	6a42                	ld	s4,16(sp)
    800040fa:	6121                	addi	sp,sp,64
    800040fc:	8082                	ret
    iput(ip);
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	a30080e7          	jalr	-1488(ra) # 80003b2e <iput>
    return -1;
    80004106:	557d                	li	a0,-1
    80004108:	b7dd                	j	800040ee <dirlink+0x86>
      panic("dirlink read");
    8000410a:	00004517          	auipc	a0,0x4
    8000410e:	52e50513          	addi	a0,a0,1326 # 80008638 <syscalls+0x1d0>
    80004112:	ffffc097          	auipc	ra,0xffffc
    80004116:	434080e7          	jalr	1076(ra) # 80000546 <panic>
    panic("dirlink");
    8000411a:	00004517          	auipc	a0,0x4
    8000411e:	69e50513          	addi	a0,a0,1694 # 800087b8 <syscalls+0x350>
    80004122:	ffffc097          	auipc	ra,0xffffc
    80004126:	424080e7          	jalr	1060(ra) # 80000546 <panic>

000000008000412a <namei>:

struct inode*
namei(char *path)
{
    8000412a:	1101                	addi	sp,sp,-32
    8000412c:	ec06                	sd	ra,24(sp)
    8000412e:	e822                	sd	s0,16(sp)
    80004130:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004132:	fe040613          	addi	a2,s0,-32
    80004136:	4581                	li	a1,0
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	dca080e7          	jalr	-566(ra) # 80003f02 <namex>
}
    80004140:	60e2                	ld	ra,24(sp)
    80004142:	6442                	ld	s0,16(sp)
    80004144:	6105                	addi	sp,sp,32
    80004146:	8082                	ret

0000000080004148 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004148:	1141                	addi	sp,sp,-16
    8000414a:	e406                	sd	ra,8(sp)
    8000414c:	e022                	sd	s0,0(sp)
    8000414e:	0800                	addi	s0,sp,16
    80004150:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004152:	4585                	li	a1,1
    80004154:	00000097          	auipc	ra,0x0
    80004158:	dae080e7          	jalr	-594(ra) # 80003f02 <namex>
}
    8000415c:	60a2                	ld	ra,8(sp)
    8000415e:	6402                	ld	s0,0(sp)
    80004160:	0141                	addi	sp,sp,16
    80004162:	8082                	ret

0000000080004164 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004164:	1101                	addi	sp,sp,-32
    80004166:	ec06                	sd	ra,24(sp)
    80004168:	e822                	sd	s0,16(sp)
    8000416a:	e426                	sd	s1,8(sp)
    8000416c:	e04a                	sd	s2,0(sp)
    8000416e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004170:	0001e917          	auipc	s2,0x1e
    80004174:	b9890913          	addi	s2,s2,-1128 # 80021d08 <log>
    80004178:	01892583          	lw	a1,24(s2)
    8000417c:	02892503          	lw	a0,40(s2)
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	ff2080e7          	jalr	-14(ra) # 80003172 <bread>
    80004188:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000418a:	02c92683          	lw	a3,44(s2)
    8000418e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004190:	02d05863          	blez	a3,800041c0 <write_head+0x5c>
    80004194:	0001e797          	auipc	a5,0x1e
    80004198:	ba478793          	addi	a5,a5,-1116 # 80021d38 <log+0x30>
    8000419c:	05c50713          	addi	a4,a0,92
    800041a0:	36fd                	addiw	a3,a3,-1
    800041a2:	02069613          	slli	a2,a3,0x20
    800041a6:	01e65693          	srli	a3,a2,0x1e
    800041aa:	0001e617          	auipc	a2,0x1e
    800041ae:	b9260613          	addi	a2,a2,-1134 # 80021d3c <log+0x34>
    800041b2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041b4:	4390                	lw	a2,0(a5)
    800041b6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b8:	0791                	addi	a5,a5,4
    800041ba:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800041bc:	fed79ce3          	bne	a5,a3,800041b4 <write_head+0x50>
  }
  bwrite(buf);
    800041c0:	8526                	mv	a0,s1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	0a2080e7          	jalr	162(ra) # 80003264 <bwrite>
  brelse(buf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	0d6080e7          	jalr	214(ra) # 800032a2 <brelse>
}
    800041d4:	60e2                	ld	ra,24(sp)
    800041d6:	6442                	ld	s0,16(sp)
    800041d8:	64a2                	ld	s1,8(sp)
    800041da:	6902                	ld	s2,0(sp)
    800041dc:	6105                	addi	sp,sp,32
    800041de:	8082                	ret

00000000800041e0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e0:	0001e797          	auipc	a5,0x1e
    800041e4:	b547a783          	lw	a5,-1196(a5) # 80021d34 <log+0x2c>
    800041e8:	0af05663          	blez	a5,80004294 <install_trans+0xb4>
{
    800041ec:	7139                	addi	sp,sp,-64
    800041ee:	fc06                	sd	ra,56(sp)
    800041f0:	f822                	sd	s0,48(sp)
    800041f2:	f426                	sd	s1,40(sp)
    800041f4:	f04a                	sd	s2,32(sp)
    800041f6:	ec4e                	sd	s3,24(sp)
    800041f8:	e852                	sd	s4,16(sp)
    800041fa:	e456                	sd	s5,8(sp)
    800041fc:	0080                	addi	s0,sp,64
    800041fe:	0001ea97          	auipc	s5,0x1e
    80004202:	b3aa8a93          	addi	s5,s5,-1222 # 80021d38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004206:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004208:	0001e997          	auipc	s3,0x1e
    8000420c:	b0098993          	addi	s3,s3,-1280 # 80021d08 <log>
    80004210:	0189a583          	lw	a1,24(s3)
    80004214:	014585bb          	addw	a1,a1,s4
    80004218:	2585                	addiw	a1,a1,1
    8000421a:	0289a503          	lw	a0,40(s3)
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	f54080e7          	jalr	-172(ra) # 80003172 <bread>
    80004226:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004228:	000aa583          	lw	a1,0(s5)
    8000422c:	0289a503          	lw	a0,40(s3)
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	f42080e7          	jalr	-190(ra) # 80003172 <bread>
    80004238:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000423a:	40000613          	li	a2,1024
    8000423e:	05890593          	addi	a1,s2,88
    80004242:	05850513          	addi	a0,a0,88
    80004246:	ffffd097          	auipc	ra,0xffffd
    8000424a:	b12080e7          	jalr	-1262(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	014080e7          	jalr	20(ra) # 80003264 <bwrite>
    bunpin(dbuf);
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	122080e7          	jalr	290(ra) # 8000337c <bunpin>
    brelse(lbuf);
    80004262:	854a                	mv	a0,s2
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	03e080e7          	jalr	62(ra) # 800032a2 <brelse>
    brelse(dbuf);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	034080e7          	jalr	52(ra) # 800032a2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004276:	2a05                	addiw	s4,s4,1
    80004278:	0a91                	addi	s5,s5,4
    8000427a:	02c9a783          	lw	a5,44(s3)
    8000427e:	f8fa49e3          	blt	s4,a5,80004210 <install_trans+0x30>
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6aa2                	ld	s5,8(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    80004294:	8082                	ret

0000000080004296 <initlog>:
{
    80004296:	7179                	addi	sp,sp,-48
    80004298:	f406                	sd	ra,40(sp)
    8000429a:	f022                	sd	s0,32(sp)
    8000429c:	ec26                	sd	s1,24(sp)
    8000429e:	e84a                	sd	s2,16(sp)
    800042a0:	e44e                	sd	s3,8(sp)
    800042a2:	1800                	addi	s0,sp,48
    800042a4:	892a                	mv	s2,a0
    800042a6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042a8:	0001e497          	auipc	s1,0x1e
    800042ac:	a6048493          	addi	s1,s1,-1440 # 80021d08 <log>
    800042b0:	00004597          	auipc	a1,0x4
    800042b4:	39858593          	addi	a1,a1,920 # 80008648 <syscalls+0x1e0>
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	8b6080e7          	jalr	-1866(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    800042c2:	0149a583          	lw	a1,20(s3)
    800042c6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042c8:	0109a783          	lw	a5,16(s3)
    800042cc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ce:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d2:	854a                	mv	a0,s2
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	e9e080e7          	jalr	-354(ra) # 80003172 <bread>
  log.lh.n = lh->n;
    800042dc:	4d34                	lw	a3,88(a0)
    800042de:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e0:	02d05663          	blez	a3,8000430c <initlog+0x76>
    800042e4:	05c50793          	addi	a5,a0,92
    800042e8:	0001e717          	auipc	a4,0x1e
    800042ec:	a5070713          	addi	a4,a4,-1456 # 80021d38 <log+0x30>
    800042f0:	36fd                	addiw	a3,a3,-1
    800042f2:	02069613          	slli	a2,a3,0x20
    800042f6:	01e65693          	srli	a3,a2,0x1e
    800042fa:	06050613          	addi	a2,a0,96
    800042fe:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004300:	4390                	lw	a2,0(a5)
    80004302:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0791                	addi	a5,a5,4
    80004306:	0711                	addi	a4,a4,4
    80004308:	fed79ce3          	bne	a5,a3,80004300 <initlog+0x6a>
  brelse(buf);
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	f96080e7          	jalr	-106(ra) # 800032a2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004314:	00000097          	auipc	ra,0x0
    80004318:	ecc080e7          	jalr	-308(ra) # 800041e0 <install_trans>
  log.lh.n = 0;
    8000431c:	0001e797          	auipc	a5,0x1e
    80004320:	a007ac23          	sw	zero,-1512(a5) # 80021d34 <log+0x2c>
  write_head(); // clear the log
    80004324:	00000097          	auipc	ra,0x0
    80004328:	e40080e7          	jalr	-448(ra) # 80004164 <write_head>
}
    8000432c:	70a2                	ld	ra,40(sp)
    8000432e:	7402                	ld	s0,32(sp)
    80004330:	64e2                	ld	s1,24(sp)
    80004332:	6942                	ld	s2,16(sp)
    80004334:	69a2                	ld	s3,8(sp)
    80004336:	6145                	addi	sp,sp,48
    80004338:	8082                	ret

000000008000433a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004346:	0001e517          	auipc	a0,0x1e
    8000434a:	9c250513          	addi	a0,a0,-1598 # 80021d08 <log>
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	8b2080e7          	jalr	-1870(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    80004356:	0001e497          	auipc	s1,0x1e
    8000435a:	9b248493          	addi	s1,s1,-1614 # 80021d08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000435e:	4979                	li	s2,30
    80004360:	a039                	j	8000436e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004362:	85a6                	mv	a1,s1
    80004364:	8526                	mv	a0,s1
    80004366:	ffffe097          	auipc	ra,0xffffe
    8000436a:	1dc080e7          	jalr	476(ra) # 80002542 <sleep>
    if(log.committing){
    8000436e:	50dc                	lw	a5,36(s1)
    80004370:	fbed                	bnez	a5,80004362 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004372:	5098                	lw	a4,32(s1)
    80004374:	2705                	addiw	a4,a4,1
    80004376:	0007069b          	sext.w	a3,a4
    8000437a:	0027179b          	slliw	a5,a4,0x2
    8000437e:	9fb9                	addw	a5,a5,a4
    80004380:	0017979b          	slliw	a5,a5,0x1
    80004384:	54d8                	lw	a4,44(s1)
    80004386:	9fb9                	addw	a5,a5,a4
    80004388:	00f95963          	bge	s2,a5,8000439a <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000438c:	85a6                	mv	a1,s1
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffe097          	auipc	ra,0xffffe
    80004394:	1b2080e7          	jalr	434(ra) # 80002542 <sleep>
    80004398:	bfd9                	j	8000436e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000439a:	0001e517          	auipc	a0,0x1e
    8000439e:	96e50513          	addi	a0,a0,-1682 # 80021d08 <log>
    800043a2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	910080e7          	jalr	-1776(ra) # 80000cb4 <release>
      break;
    }
  }
}
    800043ac:	60e2                	ld	ra,24(sp)
    800043ae:	6442                	ld	s0,16(sp)
    800043b0:	64a2                	ld	s1,8(sp)
    800043b2:	6902                	ld	s2,0(sp)
    800043b4:	6105                	addi	sp,sp,32
    800043b6:	8082                	ret

00000000800043b8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043b8:	7139                	addi	sp,sp,-64
    800043ba:	fc06                	sd	ra,56(sp)
    800043bc:	f822                	sd	s0,48(sp)
    800043be:	f426                	sd	s1,40(sp)
    800043c0:	f04a                	sd	s2,32(sp)
    800043c2:	ec4e                	sd	s3,24(sp)
    800043c4:	e852                	sd	s4,16(sp)
    800043c6:	e456                	sd	s5,8(sp)
    800043c8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043ca:	0001e497          	auipc	s1,0x1e
    800043ce:	93e48493          	addi	s1,s1,-1730 # 80021d08 <log>
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	82c080e7          	jalr	-2004(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    800043dc:	509c                	lw	a5,32(s1)
    800043de:	37fd                	addiw	a5,a5,-1
    800043e0:	0007891b          	sext.w	s2,a5
    800043e4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043e6:	50dc                	lw	a5,36(s1)
    800043e8:	e7b9                	bnez	a5,80004436 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ea:	04091e63          	bnez	s2,80004446 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043ee:	0001e497          	auipc	s1,0x1e
    800043f2:	91a48493          	addi	s1,s1,-1766 # 80021d08 <log>
    800043f6:	4785                	li	a5,1
    800043f8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043fa:	8526                	mv	a0,s1
    800043fc:	ffffd097          	auipc	ra,0xffffd
    80004400:	8b8080e7          	jalr	-1864(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004404:	54dc                	lw	a5,44(s1)
    80004406:	06f04763          	bgtz	a5,80004474 <end_op+0xbc>
    acquire(&log.lock);
    8000440a:	0001e497          	auipc	s1,0x1e
    8000440e:	8fe48493          	addi	s1,s1,-1794 # 80021d08 <log>
    80004412:	8526                	mv	a0,s1
    80004414:	ffffc097          	auipc	ra,0xffffc
    80004418:	7ec080e7          	jalr	2028(ra) # 80000c00 <acquire>
    log.committing = 0;
    8000441c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	2a0080e7          	jalr	672(ra) # 800026c2 <wakeup>
    release(&log.lock);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	888080e7          	jalr	-1912(ra) # 80000cb4 <release>
}
    80004434:	a03d                	j	80004462 <end_op+0xaa>
    panic("log.committing");
    80004436:	00004517          	auipc	a0,0x4
    8000443a:	21a50513          	addi	a0,a0,538 # 80008650 <syscalls+0x1e8>
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	108080e7          	jalr	264(ra) # 80000546 <panic>
    wakeup(&log);
    80004446:	0001e497          	auipc	s1,0x1e
    8000444a:	8c248493          	addi	s1,s1,-1854 # 80021d08 <log>
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffe097          	auipc	ra,0xffffe
    80004454:	272080e7          	jalr	626(ra) # 800026c2 <wakeup>
  release(&log.lock);
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	85a080e7          	jalr	-1958(ra) # 80000cb4 <release>
}
    80004462:	70e2                	ld	ra,56(sp)
    80004464:	7442                	ld	s0,48(sp)
    80004466:	74a2                	ld	s1,40(sp)
    80004468:	7902                	ld	s2,32(sp)
    8000446a:	69e2                	ld	s3,24(sp)
    8000446c:	6a42                	ld	s4,16(sp)
    8000446e:	6aa2                	ld	s5,8(sp)
    80004470:	6121                	addi	sp,sp,64
    80004472:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004474:	0001ea97          	auipc	s5,0x1e
    80004478:	8c4a8a93          	addi	s5,s5,-1852 # 80021d38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000447c:	0001ea17          	auipc	s4,0x1e
    80004480:	88ca0a13          	addi	s4,s4,-1908 # 80021d08 <log>
    80004484:	018a2583          	lw	a1,24(s4)
    80004488:	012585bb          	addw	a1,a1,s2
    8000448c:	2585                	addiw	a1,a1,1
    8000448e:	028a2503          	lw	a0,40(s4)
    80004492:	fffff097          	auipc	ra,0xfffff
    80004496:	ce0080e7          	jalr	-800(ra) # 80003172 <bread>
    8000449a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000449c:	000aa583          	lw	a1,0(s5)
    800044a0:	028a2503          	lw	a0,40(s4)
    800044a4:	fffff097          	auipc	ra,0xfffff
    800044a8:	cce080e7          	jalr	-818(ra) # 80003172 <bread>
    800044ac:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ae:	40000613          	li	a2,1024
    800044b2:	05850593          	addi	a1,a0,88
    800044b6:	05848513          	addi	a0,s1,88
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	89e080e7          	jalr	-1890(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    800044c2:	8526                	mv	a0,s1
    800044c4:	fffff097          	auipc	ra,0xfffff
    800044c8:	da0080e7          	jalr	-608(ra) # 80003264 <bwrite>
    brelse(from);
    800044cc:	854e                	mv	a0,s3
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	dd4080e7          	jalr	-556(ra) # 800032a2 <brelse>
    brelse(to);
    800044d6:	8526                	mv	a0,s1
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	dca080e7          	jalr	-566(ra) # 800032a2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e0:	2905                	addiw	s2,s2,1
    800044e2:	0a91                	addi	s5,s5,4
    800044e4:	02ca2783          	lw	a5,44(s4)
    800044e8:	f8f94ee3          	blt	s2,a5,80004484 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	c78080e7          	jalr	-904(ra) # 80004164 <write_head>
    install_trans(); // Now install writes to home locations
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	cec080e7          	jalr	-788(ra) # 800041e0 <install_trans>
    log.lh.n = 0;
    800044fc:	0001e797          	auipc	a5,0x1e
    80004500:	8207ac23          	sw	zero,-1992(a5) # 80021d34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004504:	00000097          	auipc	ra,0x0
    80004508:	c60080e7          	jalr	-928(ra) # 80004164 <write_head>
    8000450c:	bdfd                	j	8000440a <end_op+0x52>

000000008000450e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000450e:	1101                	addi	sp,sp,-32
    80004510:	ec06                	sd	ra,24(sp)
    80004512:	e822                	sd	s0,16(sp)
    80004514:	e426                	sd	s1,8(sp)
    80004516:	e04a                	sd	s2,0(sp)
    80004518:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000451a:	0001e717          	auipc	a4,0x1e
    8000451e:	81a72703          	lw	a4,-2022(a4) # 80021d34 <log+0x2c>
    80004522:	47f5                	li	a5,29
    80004524:	08e7c063          	blt	a5,a4,800045a4 <log_write+0x96>
    80004528:	84aa                	mv	s1,a0
    8000452a:	0001d797          	auipc	a5,0x1d
    8000452e:	7fa7a783          	lw	a5,2042(a5) # 80021d24 <log+0x1c>
    80004532:	37fd                	addiw	a5,a5,-1
    80004534:	06f75863          	bge	a4,a5,800045a4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004538:	0001d797          	auipc	a5,0x1d
    8000453c:	7f07a783          	lw	a5,2032(a5) # 80021d28 <log+0x20>
    80004540:	06f05a63          	blez	a5,800045b4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004544:	0001d917          	auipc	s2,0x1d
    80004548:	7c490913          	addi	s2,s2,1988 # 80021d08 <log>
    8000454c:	854a                	mv	a0,s2
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	6b2080e7          	jalr	1714(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004556:	02c92603          	lw	a2,44(s2)
    8000455a:	06c05563          	blez	a2,800045c4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000455e:	44cc                	lw	a1,12(s1)
    80004560:	0001d717          	auipc	a4,0x1d
    80004564:	7d870713          	addi	a4,a4,2008 # 80021d38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004568:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456a:	4314                	lw	a3,0(a4)
    8000456c:	04b68d63          	beq	a3,a1,800045c6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004570:	2785                	addiw	a5,a5,1
    80004572:	0711                	addi	a4,a4,4
    80004574:	fec79be3          	bne	a5,a2,8000456a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004578:	0621                	addi	a2,a2,8
    8000457a:	060a                	slli	a2,a2,0x2
    8000457c:	0001d797          	auipc	a5,0x1d
    80004580:	78c78793          	addi	a5,a5,1932 # 80021d08 <log>
    80004584:	97b2                	add	a5,a5,a2
    80004586:	44d8                	lw	a4,12(s1)
    80004588:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000458a:	8526                	mv	a0,s1
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	db4080e7          	jalr	-588(ra) # 80003340 <bpin>
    log.lh.n++;
    80004594:	0001d717          	auipc	a4,0x1d
    80004598:	77470713          	addi	a4,a4,1908 # 80021d08 <log>
    8000459c:	575c                	lw	a5,44(a4)
    8000459e:	2785                	addiw	a5,a5,1
    800045a0:	d75c                	sw	a5,44(a4)
    800045a2:	a835                	j	800045de <log_write+0xd0>
    panic("too big a transaction");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	0bc50513          	addi	a0,a0,188 # 80008660 <syscalls+0x1f8>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	f9a080e7          	jalr	-102(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	0c450513          	addi	a0,a0,196 # 80008678 <syscalls+0x210>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f8a080e7          	jalr	-118(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045c4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045c6:	00878693          	addi	a3,a5,8
    800045ca:	068a                	slli	a3,a3,0x2
    800045cc:	0001d717          	auipc	a4,0x1d
    800045d0:	73c70713          	addi	a4,a4,1852 # 80021d08 <log>
    800045d4:	9736                	add	a4,a4,a3
    800045d6:	44d4                	lw	a3,12(s1)
    800045d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045da:	faf608e3          	beq	a2,a5,8000458a <log_write+0x7c>
  }
  release(&log.lock);
    800045de:	0001d517          	auipc	a0,0x1d
    800045e2:	72a50513          	addi	a0,a0,1834 # 80021d08 <log>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6ce080e7          	jalr	1742(ra) # 80000cb4 <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
    80004608:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460a:	00004597          	auipc	a1,0x4
    8000460e:	08e58593          	addi	a1,a1,142 # 80008698 <syscalls+0x230>
    80004612:	0521                	addi	a0,a0,8
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	55c080e7          	jalr	1372(ra) # 80000b70 <initlock>
  lk->name = name;
    8000461c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004620:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004624:	0204a423          	sw	zero,40(s1)
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	5b8080e7          	jalr	1464(ra) # 80000c00 <acquire>
  while (lk->locked) {
    80004650:	409c                	lw	a5,0(s1)
    80004652:	cb89                	beqz	a5,80004664 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004654:	85ca                	mv	a1,s2
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	eea080e7          	jalr	-278(ra) # 80002542 <sleep>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	fbed                	bnez	a5,80004654 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004664:	4785                	li	a5,1
    80004666:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	5a6080e7          	jalr	1446(ra) # 80001c0e <myproc>
    80004670:	5d1c                	lw	a5,56(a0)
    80004672:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	63e080e7          	jalr	1598(ra) # 80000cb4 <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	e04a                	sd	s2,0(sp)
    80004694:	1000                	addi	s0,sp,32
    80004696:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004698:	00850913          	addi	s2,a0,8
    8000469c:	854a                	mv	a0,s2
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	562080e7          	jalr	1378(ra) # 80000c00 <acquire>
  lk->locked = 0;
    800046a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	012080e7          	jalr	18(ra) # 800026c2 <wakeup>
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5fa080e7          	jalr	1530(ra) # 80000cb4 <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ce:	7179                	addi	sp,sp,-48
    800046d0:	f406                	sd	ra,40(sp)
    800046d2:	f022                	sd	s0,32(sp)
    800046d4:	ec26                	sd	s1,24(sp)
    800046d6:	e84a                	sd	s2,16(sp)
    800046d8:	e44e                	sd	s3,8(sp)
    800046da:	1800                	addi	s0,sp,48
    800046dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	51c080e7          	jalr	1308(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	ef99                	bnez	a5,8000470c <holdingsleep+0x3e>
    800046f0:	4481                	li	s1,0
  release(&lk->lk);
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5c0080e7          	jalr	1472(ra) # 80000cb4 <release>
  return r;
}
    800046fc:	8526                	mv	a0,s1
    800046fe:	70a2                	ld	ra,40(sp)
    80004700:	7402                	ld	s0,32(sp)
    80004702:	64e2                	ld	s1,24(sp)
    80004704:	6942                	ld	s2,16(sp)
    80004706:	69a2                	ld	s3,8(sp)
    80004708:	6145                	addi	sp,sp,48
    8000470a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470c:	0284a983          	lw	s3,40(s1)
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	4fe080e7          	jalr	1278(ra) # 80001c0e <myproc>
    80004718:	5d04                	lw	s1,56(a0)
    8000471a:	413484b3          	sub	s1,s1,s3
    8000471e:	0014b493          	seqz	s1,s1
    80004722:	bfc1                	j	800046f2 <holdingsleep+0x24>

0000000080004724 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004724:	1141                	addi	sp,sp,-16
    80004726:	e406                	sd	ra,8(sp)
    80004728:	e022                	sd	s0,0(sp)
    8000472a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000472c:	00004597          	auipc	a1,0x4
    80004730:	f7c58593          	addi	a1,a1,-132 # 800086a8 <syscalls+0x240>
    80004734:	0001d517          	auipc	a0,0x1d
    80004738:	71c50513          	addi	a0,a0,1820 # 80021e50 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	434080e7          	jalr	1076(ra) # 80000b70 <initlock>
}
    80004744:	60a2                	ld	ra,8(sp)
    80004746:	6402                	ld	s0,0(sp)
    80004748:	0141                	addi	sp,sp,16
    8000474a:	8082                	ret

000000008000474c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004756:	0001d517          	auipc	a0,0x1d
    8000475a:	6fa50513          	addi	a0,a0,1786 # 80021e50 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	4a2080e7          	jalr	1186(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004766:	0001d497          	auipc	s1,0x1d
    8000476a:	70248493          	addi	s1,s1,1794 # 80021e68 <ftable+0x18>
    8000476e:	0001e717          	auipc	a4,0x1e
    80004772:	69a70713          	addi	a4,a4,1690 # 80022e08 <ftable+0xfb8>
    if(f->ref == 0){
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	cf99                	beqz	a5,80004796 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477a:	02848493          	addi	s1,s1,40
    8000477e:	fee49ce3          	bne	s1,a4,80004776 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004782:	0001d517          	auipc	a0,0x1d
    80004786:	6ce50513          	addi	a0,a0,1742 # 80021e50 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	52a080e7          	jalr	1322(ra) # 80000cb4 <release>
  return 0;
    80004792:	4481                	li	s1,0
    80004794:	a819                	j	800047aa <filealloc+0x5e>
      f->ref = 1;
    80004796:	4785                	li	a5,1
    80004798:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479a:	0001d517          	auipc	a0,0x1d
    8000479e:	6b650513          	addi	a0,a0,1718 # 80021e50 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	512080e7          	jalr	1298(ra) # 80000cb4 <release>
}
    800047aa:	8526                	mv	a0,s1
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	68e50513          	addi	a0,a0,1678 # 80021e50 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	436080e7          	jalr	1078(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    800047d2:	40dc                	lw	a5,4(s1)
    800047d4:	02f05263          	blez	a5,800047f8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047d8:	2785                	addiw	a5,a5,1
    800047da:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047dc:	0001d517          	auipc	a0,0x1d
    800047e0:	67450513          	addi	a0,a0,1652 # 80021e50 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4d0080e7          	jalr	1232(ra) # 80000cb4 <release>
  return f;
}
    800047ec:	8526                	mv	a0,s1
    800047ee:	60e2                	ld	ra,24(sp)
    800047f0:	6442                	ld	s0,16(sp)
    800047f2:	64a2                	ld	s1,8(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret
    panic("filedup");
    800047f8:	00004517          	auipc	a0,0x4
    800047fc:	eb850513          	addi	a0,a0,-328 # 800086b0 <syscalls+0x248>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	d46080e7          	jalr	-698(ra) # 80000546 <panic>

0000000080004808 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004808:	7139                	addi	sp,sp,-64
    8000480a:	fc06                	sd	ra,56(sp)
    8000480c:	f822                	sd	s0,48(sp)
    8000480e:	f426                	sd	s1,40(sp)
    80004810:	f04a                	sd	s2,32(sp)
    80004812:	ec4e                	sd	s3,24(sp)
    80004814:	e852                	sd	s4,16(sp)
    80004816:	e456                	sd	s5,8(sp)
    80004818:	0080                	addi	s0,sp,64
    8000481a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	63450513          	addi	a0,a0,1588 # 80021e50 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3dc080e7          	jalr	988(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	06f05163          	blez	a5,80004890 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004832:	37fd                	addiw	a5,a5,-1
    80004834:	0007871b          	sext.w	a4,a5
    80004838:	c0dc                	sw	a5,4(s1)
    8000483a:	06e04363          	bgtz	a4,800048a0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000483e:	0004a903          	lw	s2,0(s1)
    80004842:	0094ca83          	lbu	s5,9(s1)
    80004846:	0104ba03          	ld	s4,16(s1)
    8000484a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000484e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004852:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004856:	0001d517          	auipc	a0,0x1d
    8000485a:	5fa50513          	addi	a0,a0,1530 # 80021e50 <ftable>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	456080e7          	jalr	1110(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    80004866:	4785                	li	a5,1
    80004868:	04f90d63          	beq	s2,a5,800048c2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000486c:	3979                	addiw	s2,s2,-2
    8000486e:	4785                	li	a5,1
    80004870:	0527e063          	bltu	a5,s2,800048b0 <fileclose+0xa8>
    begin_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	ac6080e7          	jalr	-1338(ra) # 8000433a <begin_op>
    iput(ff.ip);
    8000487c:	854e                	mv	a0,s3
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	2b0080e7          	jalr	688(ra) # 80003b2e <iput>
    end_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	b32080e7          	jalr	-1230(ra) # 800043b8 <end_op>
    8000488e:	a00d                	j	800048b0 <fileclose+0xa8>
    panic("fileclose");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e2850513          	addi	a0,a0,-472 # 800086b8 <syscalls+0x250>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	cae080e7          	jalr	-850(ra) # 80000546 <panic>
    release(&ftable.lock);
    800048a0:	0001d517          	auipc	a0,0x1d
    800048a4:	5b050513          	addi	a0,a0,1456 # 80021e50 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	40c080e7          	jalr	1036(ra) # 80000cb4 <release>
  }
}
    800048b0:	70e2                	ld	ra,56(sp)
    800048b2:	7442                	ld	s0,48(sp)
    800048b4:	74a2                	ld	s1,40(sp)
    800048b6:	7902                	ld	s2,32(sp)
    800048b8:	69e2                	ld	s3,24(sp)
    800048ba:	6a42                	ld	s4,16(sp)
    800048bc:	6aa2                	ld	s5,8(sp)
    800048be:	6121                	addi	sp,sp,64
    800048c0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c2:	85d6                	mv	a1,s5
    800048c4:	8552                	mv	a0,s4
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	372080e7          	jalr	882(ra) # 80004c38 <pipeclose>
    800048ce:	b7cd                	j	800048b0 <fileclose+0xa8>

00000000800048d0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	0880                	addi	s0,sp,80
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e2:	ffffd097          	auipc	ra,0xffffd
    800048e6:	32c080e7          	jalr	812(ra) # 80001c0e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	37f9                	addiw	a5,a5,-2
    800048ee:	4705                	li	a4,1
    800048f0:	04f76763          	bltu	a4,a5,8000493e <filestat+0x6e>
    800048f4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	07c080e7          	jalr	124(ra) # 80003974 <ilock>
    stati(f->ip, &st);
    80004900:	fb840593          	addi	a1,s0,-72
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	2f8080e7          	jalr	760(ra) # 80003bfe <stati>
    iunlock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	126080e7          	jalr	294(ra) # 80003a36 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004918:	46e1                	li	a3,24
    8000491a:	fb840613          	addi	a2,s0,-72
    8000491e:	85ce                	mv	a1,s3
    80004920:	05093503          	ld	a0,80(s2)
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	fb0080e7          	jalr	-80(ra) # 800018d4 <copyout>
    8000492c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004930:	60a6                	ld	ra,72(sp)
    80004932:	6406                	ld	s0,64(sp)
    80004934:	74e2                	ld	s1,56(sp)
    80004936:	7942                	ld	s2,48(sp)
    80004938:	79a2                	ld	s3,40(sp)
    8000493a:	6161                	addi	sp,sp,80
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	bfc5                	j	80004930 <filestat+0x60>

0000000080004942 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004942:	7179                	addi	sp,sp,-48
    80004944:	f406                	sd	ra,40(sp)
    80004946:	f022                	sd	s0,32(sp)
    80004948:	ec26                	sd	s1,24(sp)
    8000494a:	e84a                	sd	s2,16(sp)
    8000494c:	e44e                	sd	s3,8(sp)
    8000494e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004950:	00854783          	lbu	a5,8(a0)
    80004954:	c3d5                	beqz	a5,800049f8 <fileread+0xb6>
    80004956:	84aa                	mv	s1,a0
    80004958:	89ae                	mv	s3,a1
    8000495a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000495c:	411c                	lw	a5,0(a0)
    8000495e:	4705                	li	a4,1
    80004960:	04e78963          	beq	a5,a4,800049b2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004964:	470d                	li	a4,3
    80004966:	04e78d63          	beq	a5,a4,800049c0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496a:	4709                	li	a4,2
    8000496c:	06e79e63          	bne	a5,a4,800049e8 <fileread+0xa6>
    ilock(f->ip);
    80004970:	6d08                	ld	a0,24(a0)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	002080e7          	jalr	2(ra) # 80003974 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497a:	874a                	mv	a4,s2
    8000497c:	5094                	lw	a3,32(s1)
    8000497e:	864e                	mv	a2,s3
    80004980:	4585                	li	a1,1
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	2a4080e7          	jalr	676(ra) # 80003c28 <readi>
    8000498c:	892a                	mv	s2,a0
    8000498e:	00a05563          	blez	a0,80004998 <fileread+0x56>
      f->off += r;
    80004992:	509c                	lw	a5,32(s1)
    80004994:	9fa9                	addw	a5,a5,a0
    80004996:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	09c080e7          	jalr	156(ra) # 80003a36 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a2:	854a                	mv	a0,s2
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6145                	addi	sp,sp,48
    800049b0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b2:	6908                	ld	a0,16(a0)
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	3f6080e7          	jalr	1014(ra) # 80004daa <piperead>
    800049bc:	892a                	mv	s2,a0
    800049be:	b7d5                	j	800049a2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c0:	02451783          	lh	a5,36(a0)
    800049c4:	03079693          	slli	a3,a5,0x30
    800049c8:	92c1                	srli	a3,a3,0x30
    800049ca:	4725                	li	a4,9
    800049cc:	02d76863          	bltu	a4,a3,800049fc <fileread+0xba>
    800049d0:	0792                	slli	a5,a5,0x4
    800049d2:	0001d717          	auipc	a4,0x1d
    800049d6:	3de70713          	addi	a4,a4,990 # 80021db0 <devsw>
    800049da:	97ba                	add	a5,a5,a4
    800049dc:	639c                	ld	a5,0(a5)
    800049de:	c38d                	beqz	a5,80004a00 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e0:	4505                	li	a0,1
    800049e2:	9782                	jalr	a5
    800049e4:	892a                	mv	s2,a0
    800049e6:	bf75                	j	800049a2 <fileread+0x60>
    panic("fileread");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	ce050513          	addi	a0,a0,-800 # 800086c8 <syscalls+0x260>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b56080e7          	jalr	-1194(ra) # 80000546 <panic>
    return -1;
    800049f8:	597d                	li	s2,-1
    800049fa:	b765                	j	800049a2 <fileread+0x60>
      return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b755                	j	800049a2 <fileread+0x60>
    80004a00:	597d                	li	s2,-1
    80004a02:	b745                	j	800049a2 <fileread+0x60>

0000000080004a04 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a04:	00954783          	lbu	a5,9(a0)
    80004a08:	14078563          	beqz	a5,80004b52 <filewrite+0x14e>
{
    80004a0c:	715d                	addi	sp,sp,-80
    80004a0e:	e486                	sd	ra,72(sp)
    80004a10:	e0a2                	sd	s0,64(sp)
    80004a12:	fc26                	sd	s1,56(sp)
    80004a14:	f84a                	sd	s2,48(sp)
    80004a16:	f44e                	sd	s3,40(sp)
    80004a18:	f052                	sd	s4,32(sp)
    80004a1a:	ec56                	sd	s5,24(sp)
    80004a1c:	e85a                	sd	s6,16(sp)
    80004a1e:	e45e                	sd	s7,8(sp)
    80004a20:	e062                	sd	s8,0(sp)
    80004a22:	0880                	addi	s0,sp,80
    80004a24:	892a                	mv	s2,a0
    80004a26:	8b2e                	mv	s6,a1
    80004a28:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2a:	411c                	lw	a5,0(a0)
    80004a2c:	4705                	li	a4,1
    80004a2e:	02e78263          	beq	a5,a4,80004a52 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a32:	470d                	li	a4,3
    80004a34:	02e78563          	beq	a5,a4,80004a5e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a38:	4709                	li	a4,2
    80004a3a:	10e79463          	bne	a5,a4,80004b42 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a3e:	0ec05e63          	blez	a2,80004b3a <filewrite+0x136>
    int i = 0;
    80004a42:	4981                	li	s3,0
    80004a44:	6b85                	lui	s7,0x1
    80004a46:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a4a:	6c05                	lui	s8,0x1
    80004a4c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a50:	a851                	j	80004ae4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a52:	6908                	ld	a0,16(a0)
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	254080e7          	jalr	596(ra) # 80004ca8 <pipewrite>
    80004a5c:	a85d                	j	80004b12 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a5e:	02451783          	lh	a5,36(a0)
    80004a62:	03079693          	slli	a3,a5,0x30
    80004a66:	92c1                	srli	a3,a3,0x30
    80004a68:	4725                	li	a4,9
    80004a6a:	0ed76663          	bltu	a4,a3,80004b56 <filewrite+0x152>
    80004a6e:	0792                	slli	a5,a5,0x4
    80004a70:	0001d717          	auipc	a4,0x1d
    80004a74:	34070713          	addi	a4,a4,832 # 80021db0 <devsw>
    80004a78:	97ba                	add	a5,a5,a4
    80004a7a:	679c                	ld	a5,8(a5)
    80004a7c:	cff9                	beqz	a5,80004b5a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a7e:	4505                	li	a0,1
    80004a80:	9782                	jalr	a5
    80004a82:	a841                	j	80004b12 <filewrite+0x10e>
    80004a84:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	8b2080e7          	jalr	-1870(ra) # 8000433a <begin_op>
      ilock(f->ip);
    80004a90:	01893503          	ld	a0,24(s2)
    80004a94:	fffff097          	auipc	ra,0xfffff
    80004a98:	ee0080e7          	jalr	-288(ra) # 80003974 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a9c:	8756                	mv	a4,s5
    80004a9e:	02092683          	lw	a3,32(s2)
    80004aa2:	01698633          	add	a2,s3,s6
    80004aa6:	4585                	li	a1,1
    80004aa8:	01893503          	ld	a0,24(s2)
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	272080e7          	jalr	626(ra) # 80003d1e <writei>
    80004ab4:	84aa                	mv	s1,a0
    80004ab6:	02a05f63          	blez	a0,80004af4 <filewrite+0xf0>
        f->off += r;
    80004aba:	02092783          	lw	a5,32(s2)
    80004abe:	9fa9                	addw	a5,a5,a0
    80004ac0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac4:	01893503          	ld	a0,24(s2)
    80004ac8:	fffff097          	auipc	ra,0xfffff
    80004acc:	f6e080e7          	jalr	-146(ra) # 80003a36 <iunlock>
      end_op();
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	8e8080e7          	jalr	-1816(ra) # 800043b8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ad8:	049a9963          	bne	s5,s1,80004b2a <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004adc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae0:	0349d663          	bge	s3,s4,80004b0c <filewrite+0x108>
      int n1 = n - i;
    80004ae4:	413a04bb          	subw	s1,s4,s3
    80004ae8:	0004879b          	sext.w	a5,s1
    80004aec:	f8fbdce3          	bge	s7,a5,80004a84 <filewrite+0x80>
    80004af0:	84e2                	mv	s1,s8
    80004af2:	bf49                	j	80004a84 <filewrite+0x80>
      iunlock(f->ip);
    80004af4:	01893503          	ld	a0,24(s2)
    80004af8:	fffff097          	auipc	ra,0xfffff
    80004afc:	f3e080e7          	jalr	-194(ra) # 80003a36 <iunlock>
      end_op();
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	8b8080e7          	jalr	-1864(ra) # 800043b8 <end_op>
      if(r < 0)
    80004b08:	fc04d8e3          	bgez	s1,80004ad8 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b0c:	8552                	mv	a0,s4
    80004b0e:	033a1863          	bne	s4,s3,80004b3e <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b12:	60a6                	ld	ra,72(sp)
    80004b14:	6406                	ld	s0,64(sp)
    80004b16:	74e2                	ld	s1,56(sp)
    80004b18:	7942                	ld	s2,48(sp)
    80004b1a:	79a2                	ld	s3,40(sp)
    80004b1c:	7a02                	ld	s4,32(sp)
    80004b1e:	6ae2                	ld	s5,24(sp)
    80004b20:	6b42                	ld	s6,16(sp)
    80004b22:	6ba2                	ld	s7,8(sp)
    80004b24:	6c02                	ld	s8,0(sp)
    80004b26:	6161                	addi	sp,sp,80
    80004b28:	8082                	ret
        panic("short filewrite");
    80004b2a:	00004517          	auipc	a0,0x4
    80004b2e:	bae50513          	addi	a0,a0,-1106 # 800086d8 <syscalls+0x270>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	a14080e7          	jalr	-1516(ra) # 80000546 <panic>
    int i = 0;
    80004b3a:	4981                	li	s3,0
    80004b3c:	bfc1                	j	80004b0c <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b3e:	557d                	li	a0,-1
    80004b40:	bfc9                	j	80004b12 <filewrite+0x10e>
    panic("filewrite");
    80004b42:	00004517          	auipc	a0,0x4
    80004b46:	ba650513          	addi	a0,a0,-1114 # 800086e8 <syscalls+0x280>
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	9fc080e7          	jalr	-1540(ra) # 80000546 <panic>
    return -1;
    80004b52:	557d                	li	a0,-1
}
    80004b54:	8082                	ret
      return -1;
    80004b56:	557d                	li	a0,-1
    80004b58:	bf6d                	j	80004b12 <filewrite+0x10e>
    80004b5a:	557d                	li	a0,-1
    80004b5c:	bf5d                	j	80004b12 <filewrite+0x10e>

0000000080004b5e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b5e:	7179                	addi	sp,sp,-48
    80004b60:	f406                	sd	ra,40(sp)
    80004b62:	f022                	sd	s0,32(sp)
    80004b64:	ec26                	sd	s1,24(sp)
    80004b66:	e84a                	sd	s2,16(sp)
    80004b68:	e44e                	sd	s3,8(sp)
    80004b6a:	e052                	sd	s4,0(sp)
    80004b6c:	1800                	addi	s0,sp,48
    80004b6e:	84aa                	mv	s1,a0
    80004b70:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b72:	0005b023          	sd	zero,0(a1)
    80004b76:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	bd2080e7          	jalr	-1070(ra) # 8000474c <filealloc>
    80004b82:	e088                	sd	a0,0(s1)
    80004b84:	c551                	beqz	a0,80004c10 <pipealloc+0xb2>
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	bc6080e7          	jalr	-1082(ra) # 8000474c <filealloc>
    80004b8e:	00aa3023          	sd	a0,0(s4)
    80004b92:	c92d                	beqz	a0,80004c04 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	f7c080e7          	jalr	-132(ra) # 80000b10 <kalloc>
    80004b9c:	892a                	mv	s2,a0
    80004b9e:	c125                	beqz	a0,80004bfe <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ba0:	4985                	li	s3,1
    80004ba2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ba6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004baa:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bae:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bb2:	00004597          	auipc	a1,0x4
    80004bb6:	b4658593          	addi	a1,a1,-1210 # 800086f8 <syscalls+0x290>
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	fb6080e7          	jalr	-74(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    80004bc2:	609c                	ld	a5,0(s1)
    80004bc4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bc8:	609c                	ld	a5,0(s1)
    80004bca:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bce:	609c                	ld	a5,0(s1)
    80004bd0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bd4:	609c                	ld	a5,0(s1)
    80004bd6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bda:	000a3783          	ld	a5,0(s4)
    80004bde:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004be2:	000a3783          	ld	a5,0(s4)
    80004be6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bea:	000a3783          	ld	a5,0(s4)
    80004bee:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bf2:	000a3783          	ld	a5,0(s4)
    80004bf6:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bfa:	4501                	li	a0,0
    80004bfc:	a025                	j	80004c24 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bfe:	6088                	ld	a0,0(s1)
    80004c00:	e501                	bnez	a0,80004c08 <pipealloc+0xaa>
    80004c02:	a039                	j	80004c10 <pipealloc+0xb2>
    80004c04:	6088                	ld	a0,0(s1)
    80004c06:	c51d                	beqz	a0,80004c34 <pipealloc+0xd6>
    fileclose(*f0);
    80004c08:	00000097          	auipc	ra,0x0
    80004c0c:	c00080e7          	jalr	-1024(ra) # 80004808 <fileclose>
  if(*f1)
    80004c10:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c14:	557d                	li	a0,-1
  if(*f1)
    80004c16:	c799                	beqz	a5,80004c24 <pipealloc+0xc6>
    fileclose(*f1);
    80004c18:	853e                	mv	a0,a5
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	bee080e7          	jalr	-1042(ra) # 80004808 <fileclose>
  return -1;
    80004c22:	557d                	li	a0,-1
}
    80004c24:	70a2                	ld	ra,40(sp)
    80004c26:	7402                	ld	s0,32(sp)
    80004c28:	64e2                	ld	s1,24(sp)
    80004c2a:	6942                	ld	s2,16(sp)
    80004c2c:	69a2                	ld	s3,8(sp)
    80004c2e:	6a02                	ld	s4,0(sp)
    80004c30:	6145                	addi	sp,sp,48
    80004c32:	8082                	ret
  return -1;
    80004c34:	557d                	li	a0,-1
    80004c36:	b7fd                	j	80004c24 <pipealloc+0xc6>

0000000080004c38 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c38:	1101                	addi	sp,sp,-32
    80004c3a:	ec06                	sd	ra,24(sp)
    80004c3c:	e822                	sd	s0,16(sp)
    80004c3e:	e426                	sd	s1,8(sp)
    80004c40:	e04a                	sd	s2,0(sp)
    80004c42:	1000                	addi	s0,sp,32
    80004c44:	84aa                	mv	s1,a0
    80004c46:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	fb8080e7          	jalr	-72(ra) # 80000c00 <acquire>
  if(writable){
    80004c50:	02090d63          	beqz	s2,80004c8a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c54:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c58:	21848513          	addi	a0,s1,536
    80004c5c:	ffffe097          	auipc	ra,0xffffe
    80004c60:	a66080e7          	jalr	-1434(ra) # 800026c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c64:	2204b783          	ld	a5,544(s1)
    80004c68:	eb95                	bnez	a5,80004c9c <pipeclose+0x64>
    release(&pi->lock);
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	048080e7          	jalr	72(ra) # 80000cb4 <release>
    kfree((char*)pi);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	d9c080e7          	jalr	-612(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004c7e:	60e2                	ld	ra,24(sp)
    80004c80:	6442                	ld	s0,16(sp)
    80004c82:	64a2                	ld	s1,8(sp)
    80004c84:	6902                	ld	s2,0(sp)
    80004c86:	6105                	addi	sp,sp,32
    80004c88:	8082                	ret
    pi->readopen = 0;
    80004c8a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c8e:	21c48513          	addi	a0,s1,540
    80004c92:	ffffe097          	auipc	ra,0xffffe
    80004c96:	a30080e7          	jalr	-1488(ra) # 800026c2 <wakeup>
    80004c9a:	b7e9                	j	80004c64 <pipeclose+0x2c>
    release(&pi->lock);
    80004c9c:	8526                	mv	a0,s1
    80004c9e:	ffffc097          	auipc	ra,0xffffc
    80004ca2:	016080e7          	jalr	22(ra) # 80000cb4 <release>
}
    80004ca6:	bfe1                	j	80004c7e <pipeclose+0x46>

0000000080004ca8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ca8:	711d                	addi	sp,sp,-96
    80004caa:	ec86                	sd	ra,88(sp)
    80004cac:	e8a2                	sd	s0,80(sp)
    80004cae:	e4a6                	sd	s1,72(sp)
    80004cb0:	e0ca                	sd	s2,64(sp)
    80004cb2:	fc4e                	sd	s3,56(sp)
    80004cb4:	f852                	sd	s4,48(sp)
    80004cb6:	f456                	sd	s5,40(sp)
    80004cb8:	f05a                	sd	s6,32(sp)
    80004cba:	ec5e                	sd	s7,24(sp)
    80004cbc:	e862                	sd	s8,16(sp)
    80004cbe:	1080                	addi	s0,sp,96
    80004cc0:	84aa                	mv	s1,a0
    80004cc2:	8b2e                	mv	s6,a1
    80004cc4:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	f48080e7          	jalr	-184(ra) # 80001c0e <myproc>
    80004cce:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	f2e080e7          	jalr	-210(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80004cda:	09505863          	blez	s5,80004d6a <pipewrite+0xc2>
    80004cde:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ce0:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ce4:	21c48993          	addi	s3,s1,540
    }
    if(copyin_new(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ce8:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cea:	2184a783          	lw	a5,536(s1)
    80004cee:	21c4a703          	lw	a4,540(s1)
    80004cf2:	2007879b          	addiw	a5,a5,512
    80004cf6:	02f71b63          	bne	a4,a5,80004d2c <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004cfa:	2204a783          	lw	a5,544(s1)
    80004cfe:	c3d9                	beqz	a5,80004d84 <pipewrite+0xdc>
    80004d00:	03092783          	lw	a5,48(s2)
    80004d04:	e3c1                	bnez	a5,80004d84 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004d06:	8552                	mv	a0,s4
    80004d08:	ffffe097          	auipc	ra,0xffffe
    80004d0c:	9ba080e7          	jalr	-1606(ra) # 800026c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d10:	85a6                	mv	a1,s1
    80004d12:	854e                	mv	a0,s3
    80004d14:	ffffe097          	auipc	ra,0xffffe
    80004d18:	82e080e7          	jalr	-2002(ra) # 80002542 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d1c:	2184a783          	lw	a5,536(s1)
    80004d20:	21c4a703          	lw	a4,540(s1)
    80004d24:	2007879b          	addiw	a5,a5,512
    80004d28:	fcf709e3          	beq	a4,a5,80004cfa <pipewrite+0x52>
    if(copyin_new(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d2c:	4685                	li	a3,1
    80004d2e:	865a                	mv	a2,s6
    80004d30:	faf40593          	addi	a1,s0,-81
    80004d34:	05093503          	ld	a0,80(s2)
    80004d38:	00002097          	auipc	ra,0x2
    80004d3c:	922080e7          	jalr	-1758(ra) # 8000665a <copyin_new>
    80004d40:	03850663          	beq	a0,s8,80004d6c <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d44:	21c4a783          	lw	a5,540(s1)
    80004d48:	0017871b          	addiw	a4,a5,1
    80004d4c:	20e4ae23          	sw	a4,540(s1)
    80004d50:	1ff7f793          	andi	a5,a5,511
    80004d54:	97a6                	add	a5,a5,s1
    80004d56:	faf44703          	lbu	a4,-81(s0)
    80004d5a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d5e:	2b85                	addiw	s7,s7,1
    80004d60:	0b05                	addi	s6,s6,1
    80004d62:	f97a94e3          	bne	s5,s7,80004cea <pipewrite+0x42>
    80004d66:	8bd6                	mv	s7,s5
    80004d68:	a011                	j	80004d6c <pipewrite+0xc4>
    80004d6a:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d6c:	21848513          	addi	a0,s1,536
    80004d70:	ffffe097          	auipc	ra,0xffffe
    80004d74:	952080e7          	jalr	-1710(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    80004d78:	8526                	mv	a0,s1
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f3a080e7          	jalr	-198(ra) # 80000cb4 <release>
  return i;
    80004d82:	a039                	j	80004d90 <pipewrite+0xe8>
        release(&pi->lock);
    80004d84:	8526                	mv	a0,s1
    80004d86:	ffffc097          	auipc	ra,0xffffc
    80004d8a:	f2e080e7          	jalr	-210(ra) # 80000cb4 <release>
        return -1;
    80004d8e:	5bfd                	li	s7,-1
}
    80004d90:	855e                	mv	a0,s7
    80004d92:	60e6                	ld	ra,88(sp)
    80004d94:	6446                	ld	s0,80(sp)
    80004d96:	64a6                	ld	s1,72(sp)
    80004d98:	6906                	ld	s2,64(sp)
    80004d9a:	79e2                	ld	s3,56(sp)
    80004d9c:	7a42                	ld	s4,48(sp)
    80004d9e:	7aa2                	ld	s5,40(sp)
    80004da0:	7b02                	ld	s6,32(sp)
    80004da2:	6be2                	ld	s7,24(sp)
    80004da4:	6c42                	ld	s8,16(sp)
    80004da6:	6125                	addi	sp,sp,96
    80004da8:	8082                	ret

0000000080004daa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004daa:	715d                	addi	sp,sp,-80
    80004dac:	e486                	sd	ra,72(sp)
    80004dae:	e0a2                	sd	s0,64(sp)
    80004db0:	fc26                	sd	s1,56(sp)
    80004db2:	f84a                	sd	s2,48(sp)
    80004db4:	f44e                	sd	s3,40(sp)
    80004db6:	f052                	sd	s4,32(sp)
    80004db8:	ec56                	sd	s5,24(sp)
    80004dba:	e85a                	sd	s6,16(sp)
    80004dbc:	0880                	addi	s0,sp,80
    80004dbe:	84aa                	mv	s1,a0
    80004dc0:	892e                	mv	s2,a1
    80004dc2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	e4a080e7          	jalr	-438(ra) # 80001c0e <myproc>
    80004dcc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	e30080e7          	jalr	-464(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dd8:	2184a703          	lw	a4,536(s1)
    80004ddc:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004de0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de4:	02f71463          	bne	a4,a5,80004e0c <piperead+0x62>
    80004de8:	2244a783          	lw	a5,548(s1)
    80004dec:	c385                	beqz	a5,80004e0c <piperead+0x62>
    if(pr->killed){
    80004dee:	030a2783          	lw	a5,48(s4)
    80004df2:	ebc9                	bnez	a5,80004e84 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df4:	85a6                	mv	a1,s1
    80004df6:	854e                	mv	a0,s3
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	74a080e7          	jalr	1866(ra) # 80002542 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e00:	2184a703          	lw	a4,536(s1)
    80004e04:	21c4a783          	lw	a5,540(s1)
    80004e08:	fef700e3          	beq	a4,a5,80004de8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e0c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e0e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e10:	05505463          	blez	s5,80004e58 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004e14:	2184a783          	lw	a5,536(s1)
    80004e18:	21c4a703          	lw	a4,540(s1)
    80004e1c:	02f70e63          	beq	a4,a5,80004e58 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e20:	0017871b          	addiw	a4,a5,1
    80004e24:	20e4ac23          	sw	a4,536(s1)
    80004e28:	1ff7f793          	andi	a5,a5,511
    80004e2c:	97a6                	add	a5,a5,s1
    80004e2e:	0187c783          	lbu	a5,24(a5)
    80004e32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e36:	4685                	li	a3,1
    80004e38:	fbf40613          	addi	a2,s0,-65
    80004e3c:	85ca                	mv	a1,s2
    80004e3e:	050a3503          	ld	a0,80(s4)
    80004e42:	ffffd097          	auipc	ra,0xffffd
    80004e46:	a92080e7          	jalr	-1390(ra) # 800018d4 <copyout>
    80004e4a:	01650763          	beq	a0,s6,80004e58 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4e:	2985                	addiw	s3,s3,1
    80004e50:	0905                	addi	s2,s2,1
    80004e52:	fd3a91e3          	bne	s5,s3,80004e14 <piperead+0x6a>
    80004e56:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e58:	21c48513          	addi	a0,s1,540
    80004e5c:	ffffe097          	auipc	ra,0xffffe
    80004e60:	866080e7          	jalr	-1946(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    80004e64:	8526                	mv	a0,s1
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	e4e080e7          	jalr	-434(ra) # 80000cb4 <release>
  return i;
}
    80004e6e:	854e                	mv	a0,s3
    80004e70:	60a6                	ld	ra,72(sp)
    80004e72:	6406                	ld	s0,64(sp)
    80004e74:	74e2                	ld	s1,56(sp)
    80004e76:	7942                	ld	s2,48(sp)
    80004e78:	79a2                	ld	s3,40(sp)
    80004e7a:	7a02                	ld	s4,32(sp)
    80004e7c:	6ae2                	ld	s5,24(sp)
    80004e7e:	6b42                	ld	s6,16(sp)
    80004e80:	6161                	addi	sp,sp,80
    80004e82:	8082                	ret
      release(&pi->lock);
    80004e84:	8526                	mv	a0,s1
    80004e86:	ffffc097          	auipc	ra,0xffffc
    80004e8a:	e2e080e7          	jalr	-466(ra) # 80000cb4 <release>
      return -1;
    80004e8e:	59fd                	li	s3,-1
    80004e90:	bff9                	j	80004e6e <piperead+0xc4>

0000000080004e92 <vmprint>:
#include "elf.h"


static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

void vmprint(pagetable_t pa){
    80004e92:	7159                	addi	sp,sp,-112
    80004e94:	f486                	sd	ra,104(sp)
    80004e96:	f0a2                	sd	s0,96(sp)
    80004e98:	eca6                	sd	s1,88(sp)
    80004e9a:	e8ca                	sd	s2,80(sp)
    80004e9c:	e4ce                	sd	s3,72(sp)
    80004e9e:	e0d2                	sd	s4,64(sp)
    80004ea0:	fc56                	sd	s5,56(sp)
    80004ea2:	f85a                	sd	s6,48(sp)
    80004ea4:	f45e                	sd	s7,40(sp)
    80004ea6:	f062                	sd	s8,32(sp)
    80004ea8:	ec66                	sd	s9,24(sp)
    80004eaa:	e86a                	sd	s10,16(sp)
    80004eac:	e46e                	sd	s11,8(sp)
    80004eae:	1880                	addi	s0,sp,112
    80004eb0:	8c2a                	mv	s8,a0
    printf("page table %p\n", pa);
    80004eb2:	85aa                	mv	a1,a0
    80004eb4:	00004517          	auipc	a0,0x4
    80004eb8:	84c50513          	addi	a0,a0,-1972 # 80008700 <syscalls+0x298>
    80004ebc:	ffffb097          	auipc	ra,0xffffb
    80004ec0:	6d4080e7          	jalr	1748(ra) # 80000590 <printf>
    for(int i = 0; i < 512; i++){
    80004ec4:	4c81                	li	s9,0
    pte_t pte = pa[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004ec6:	4b85                	li	s7,1
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      printf("||%d: pte %p pa %p\n",i ,pte, child);
      // vmprint((pagetable_t)child);
      
      for(int j = 0; j < 512; j++){
    80004ec8:	4d01                	li	s10,0
        pte_t pte_c = ((pagetable_t)child)[j];
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
          uint64 child_c = PTE2PA(pte_c);
          printf("|| ||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004eca:	00004d97          	auipc	s11,0x4
    80004ece:	85ed8d93          	addi	s11,s11,-1954 # 80008728 <syscalls+0x2c0>
          for(int k = 0; k < 512; k++){
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
            // printf("||||||%d: pte %p\n",k ,pte_c_c);
            if((pte_c_c & PTE_V)){
              uint64 child_c_c = PTE2PA(pte_c_c);
              printf("|| || ||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004ed2:	00004b17          	auipc	s6,0x4
    80004ed6:	86eb0b13          	addi	s6,s6,-1938 # 80008740 <syscalls+0x2d8>
          for(int k = 0; k < 512; k++){
    80004eda:	20000993          	li	s3,512
    80004ede:	a8b1                	j	80004f3a <vmprint+0xa8>
    80004ee0:	2485                	addiw	s1,s1,1
    80004ee2:	0921                	addi	s2,s2,8
    80004ee4:	03348163          	beq	s1,s3,80004f06 <vmprint+0x74>
            pte_t pte_c_c = ((pagetable_t)child_c)[k];
    80004ee8:	00093603          	ld	a2,0(s2)
            if((pte_c_c & PTE_V)){
    80004eec:	00167793          	andi	a5,a2,1
    80004ef0:	dbe5                	beqz	a5,80004ee0 <vmprint+0x4e>
              uint64 child_c_c = PTE2PA(pte_c_c);
    80004ef2:	00a65693          	srli	a3,a2,0xa
              printf("|| || ||%d: pte %p pa %p\n",k ,pte_c_c, child_c_c);
    80004ef6:	06b2                	slli	a3,a3,0xc
    80004ef8:	85a6                	mv	a1,s1
    80004efa:	855a                	mv	a0,s6
    80004efc:	ffffb097          	auipc	ra,0xffffb
    80004f00:	694080e7          	jalr	1684(ra) # 80000590 <printf>
    80004f04:	bff1                	j	80004ee0 <vmprint+0x4e>
      for(int j = 0; j < 512; j++){
    80004f06:	2a05                	addiw	s4,s4,1
    80004f08:	0aa1                	addi	s5,s5,8
    80004f0a:	033a0463          	beq	s4,s3,80004f32 <vmprint+0xa0>
        pte_t pte_c = ((pagetable_t)child)[j];
    80004f0e:	000ab603          	ld	a2,0(s5)
        if((pte_c & PTE_V) && (pte_c & (PTE_R|PTE_W|PTE_X)) == 0){
    80004f12:	00f67793          	andi	a5,a2,15
    80004f16:	ff7798e3          	bne	a5,s7,80004f06 <vmprint+0x74>
          uint64 child_c = PTE2PA(pte_c);
    80004f1a:	00a65913          	srli	s2,a2,0xa
    80004f1e:	0932                	slli	s2,s2,0xc
          printf("|| ||%d: pte %p pa %p\n",j ,pte_c, child_c);
    80004f20:	86ca                	mv	a3,s2
    80004f22:	85d2                	mv	a1,s4
    80004f24:	856e                	mv	a0,s11
    80004f26:	ffffb097          	auipc	ra,0xffffb
    80004f2a:	66a080e7          	jalr	1642(ra) # 80000590 <printf>
          for(int k = 0; k < 512; k++){
    80004f2e:	84ea                	mv	s1,s10
    80004f30:	bf65                	j	80004ee8 <vmprint+0x56>
    for(int i = 0; i < 512; i++){
    80004f32:	2c85                	addiw	s9,s9,1 # 2001 <_entry-0x7fffdfff>
    80004f34:	0c21                	addi	s8,s8,8
    80004f36:	033c8763          	beq	s9,s3,80004f64 <vmprint+0xd2>
    pte_t pte = pa[i];
    80004f3a:	000c3603          	ld	a2,0(s8)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80004f3e:	00f67793          	andi	a5,a2,15
    80004f42:	ff7798e3          	bne	a5,s7,80004f32 <vmprint+0xa0>
      uint64 child = PTE2PA(pte);
    80004f46:	00a65a93          	srli	s5,a2,0xa
    80004f4a:	0ab2                	slli	s5,s5,0xc
      printf("||%d: pte %p pa %p\n",i ,pte, child);
    80004f4c:	86d6                	mv	a3,s5
    80004f4e:	85e6                	mv	a1,s9
    80004f50:	00003517          	auipc	a0,0x3
    80004f54:	7c050513          	addi	a0,a0,1984 # 80008710 <syscalls+0x2a8>
    80004f58:	ffffb097          	auipc	ra,0xffffb
    80004f5c:	638080e7          	jalr	1592(ra) # 80000590 <printf>
      for(int j = 0; j < 512; j++){
    80004f60:	8a6a                	mv	s4,s10
    80004f62:	b775                	j	80004f0e <vmprint+0x7c>
        }

      } 
    }
  }
}
    80004f64:	70a6                	ld	ra,104(sp)
    80004f66:	7406                	ld	s0,96(sp)
    80004f68:	64e6                	ld	s1,88(sp)
    80004f6a:	6946                	ld	s2,80(sp)
    80004f6c:	69a6                	ld	s3,72(sp)
    80004f6e:	6a06                	ld	s4,64(sp)
    80004f70:	7ae2                	ld	s5,56(sp)
    80004f72:	7b42                	ld	s6,48(sp)
    80004f74:	7ba2                	ld	s7,40(sp)
    80004f76:	7c02                	ld	s8,32(sp)
    80004f78:	6ce2                	ld	s9,24(sp)
    80004f7a:	6d42                	ld	s10,16(sp)
    80004f7c:	6da2                	ld	s11,8(sp)
    80004f7e:	6165                	addi	sp,sp,112
    80004f80:	8082                	ret

0000000080004f82 <exec>:

int
exec(char *path, char **argv)
{
    80004f82:	de010113          	addi	sp,sp,-544
    80004f86:	20113c23          	sd	ra,536(sp)
    80004f8a:	20813823          	sd	s0,528(sp)
    80004f8e:	20913423          	sd	s1,520(sp)
    80004f92:	21213023          	sd	s2,512(sp)
    80004f96:	ffce                	sd	s3,504(sp)
    80004f98:	fbd2                	sd	s4,496(sp)
    80004f9a:	f7d6                	sd	s5,488(sp)
    80004f9c:	f3da                	sd	s6,480(sp)
    80004f9e:	efde                	sd	s7,472(sp)
    80004fa0:	ebe2                	sd	s8,464(sp)
    80004fa2:	e7e6                	sd	s9,456(sp)
    80004fa4:	e3ea                	sd	s10,448(sp)
    80004fa6:	ff6e                	sd	s11,440(sp)
    80004fa8:	1400                	addi	s0,sp,544
    80004faa:	892a                	mv	s2,a0
    80004fac:	dea43423          	sd	a0,-536(s0)
    80004fb0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	c5a080e7          	jalr	-934(ra) # 80001c0e <myproc>
    80004fbc:	84aa                	mv	s1,a0

  begin_op();
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	37c080e7          	jalr	892(ra) # 8000433a <begin_op>

  if((ip = namei(path)) == 0){
    80004fc6:	854a                	mv	a0,s2
    80004fc8:	fffff097          	auipc	ra,0xfffff
    80004fcc:	162080e7          	jalr	354(ra) # 8000412a <namei>
    80004fd0:	c93d                	beqz	a0,80005046 <exec+0xc4>
    80004fd2:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fd4:	fffff097          	auipc	ra,0xfffff
    80004fd8:	9a0080e7          	jalr	-1632(ra) # 80003974 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fdc:	04000713          	li	a4,64
    80004fe0:	4681                	li	a3,0
    80004fe2:	e4840613          	addi	a2,s0,-440
    80004fe6:	4581                	li	a1,0
    80004fe8:	8556                	mv	a0,s5
    80004fea:	fffff097          	auipc	ra,0xfffff
    80004fee:	c3e080e7          	jalr	-962(ra) # 80003c28 <readi>
    80004ff2:	04000793          	li	a5,64
    80004ff6:	00f51a63          	bne	a0,a5,8000500a <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ffa:	e4842703          	lw	a4,-440(s0)
    80004ffe:	464c47b7          	lui	a5,0x464c4
    80005002:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005006:	04f70663          	beq	a4,a5,80005052 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000500a:	8556                	mv	a0,s5
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	bca080e7          	jalr	-1078(ra) # 80003bd6 <iunlockput>
    end_op();
    80005014:	fffff097          	auipc	ra,0xfffff
    80005018:	3a4080e7          	jalr	932(ra) # 800043b8 <end_op>
  }
  return -1;
    8000501c:	557d                	li	a0,-1
}
    8000501e:	21813083          	ld	ra,536(sp)
    80005022:	21013403          	ld	s0,528(sp)
    80005026:	20813483          	ld	s1,520(sp)
    8000502a:	20013903          	ld	s2,512(sp)
    8000502e:	79fe                	ld	s3,504(sp)
    80005030:	7a5e                	ld	s4,496(sp)
    80005032:	7abe                	ld	s5,488(sp)
    80005034:	7b1e                	ld	s6,480(sp)
    80005036:	6bfe                	ld	s7,472(sp)
    80005038:	6c5e                	ld	s8,464(sp)
    8000503a:	6cbe                	ld	s9,456(sp)
    8000503c:	6d1e                	ld	s10,448(sp)
    8000503e:	7dfa                	ld	s11,440(sp)
    80005040:	22010113          	addi	sp,sp,544
    80005044:	8082                	ret
    end_op();
    80005046:	fffff097          	auipc	ra,0xfffff
    8000504a:	372080e7          	jalr	882(ra) # 800043b8 <end_op>
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	b7f9                	j	8000501e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005052:	8526                	mv	a0,s1
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	cd8080e7          	jalr	-808(ra) # 80001d2c <proc_pagetable>
    8000505c:	8b2a                	mv	s6,a0
    8000505e:	d555                	beqz	a0,8000500a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005060:	e6842783          	lw	a5,-408(s0)
    80005064:	e8045703          	lhu	a4,-384(s0)
    80005068:	c735                	beqz	a4,800050d4 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000506a:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506c:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005070:	6a05                	lui	s4,0x1
    80005072:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005076:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000507a:	6d85                	lui	s11,0x1
    8000507c:	7d7d                	lui	s10,0xfffff
    8000507e:	ac85                	j	800052ee <exec+0x36c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005080:	00003517          	auipc	a0,0x3
    80005084:	6e050513          	addi	a0,a0,1760 # 80008760 <syscalls+0x2f8>
    80005088:	ffffb097          	auipc	ra,0xffffb
    8000508c:	4be080e7          	jalr	1214(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005090:	874a                	mv	a4,s2
    80005092:	009c86bb          	addw	a3,s9,s1
    80005096:	4581                	li	a1,0
    80005098:	8556                	mv	a0,s5
    8000509a:	fffff097          	auipc	ra,0xfffff
    8000509e:	b8e080e7          	jalr	-1138(ra) # 80003c28 <readi>
    800050a2:	2501                	sext.w	a0,a0
    800050a4:	1ea91963          	bne	s2,a0,80005296 <exec+0x314>
  for(i = 0; i < sz; i += PGSIZE){
    800050a8:	009d84bb          	addw	s1,s11,s1
    800050ac:	013d09bb          	addw	s3,s10,s3
    800050b0:	2174ff63          	bgeu	s1,s7,800052ce <exec+0x34c>
    pa = walkaddr(pagetable, va + i);
    800050b4:	02049593          	slli	a1,s1,0x20
    800050b8:	9181                	srli	a1,a1,0x20
    800050ba:	95e2                	add	a1,a1,s8
    800050bc:	855a                	mv	a0,s6
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	fd4080e7          	jalr	-44(ra) # 80001092 <walkaddr>
    800050c6:	862a                	mv	a2,a0
    if(pa == 0)
    800050c8:	dd45                	beqz	a0,80005080 <exec+0xfe>
      n = PGSIZE;
    800050ca:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800050cc:	fd49f2e3          	bgeu	s3,s4,80005090 <exec+0x10e>
      n = sz - i;
    800050d0:	894e                	mv	s2,s3
    800050d2:	bf7d                	j	80005090 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800050d4:	4481                	li	s1,0
  iunlockput(ip);
    800050d6:	8556                	mv	a0,s5
    800050d8:	fffff097          	auipc	ra,0xfffff
    800050dc:	afe080e7          	jalr	-1282(ra) # 80003bd6 <iunlockput>
  end_op();
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	2d8080e7          	jalr	728(ra) # 800043b8 <end_op>
  p = myproc();
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	b26080e7          	jalr	-1242(ra) # 80001c0e <myproc>
    800050f0:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800050f2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800050f6:	6785                	lui	a5,0x1
    800050f8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800050fa:	94be                	add	s1,s1,a5
    800050fc:	77fd                	lui	a5,0xfffff
    800050fe:	8cfd                	and	s1,s1,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005100:	6609                	lui	a2,0x2
    80005102:	9626                	add	a2,a2,s1
    80005104:	85a6                	mv	a1,s1
    80005106:	855a                	mv	a0,s6
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	46a080e7          	jalr	1130(ra) # 80001572 <uvmalloc>
    80005110:	892a                	mv	s2,a0
    80005112:	dea43c23          	sd	a0,-520(s0)
    80005116:	e509                	bnez	a0,80005120 <exec+0x19e>
  sz = PGROUNDUP(sz);
    80005118:	de943c23          	sd	s1,-520(s0)
  ip = 0;
    8000511c:	4a81                	li	s5,0
    8000511e:	aaa5                	j	80005296 <exec+0x314>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005120:	75f9                	lui	a1,0xffffe
    80005122:	95aa                	add	a1,a1,a0
    80005124:	855a                	mv	a0,s6
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	6b6080e7          	jalr	1718(ra) # 800017dc <uvmclear>
  stackbase = sp - PGSIZE;
    8000512e:	7c7d                	lui	s8,0xfffff
    80005130:	9c4a                	add	s8,s8,s2
  for(argc = 0; argv[argc]; argc++) {
    80005132:	df043783          	ld	a5,-528(s0)
    80005136:	6388                	ld	a0,0(a5)
    80005138:	c52d                	beqz	a0,800051a2 <exec+0x220>
    8000513a:	e8840993          	addi	s3,s0,-376
    8000513e:	f8840a93          	addi	s5,s0,-120
    80005142:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	d3c080e7          	jalr	-708(ra) # 80000e80 <strlen>
    8000514c:	0015079b          	addiw	a5,a0,1
    80005150:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005154:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005158:	17896363          	bltu	s2,s8,800052be <exec+0x33c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000515c:	df043d03          	ld	s10,-528(s0)
    80005160:	000d3a03          	ld	s4,0(s10) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80005164:	8552                	mv	a0,s4
    80005166:	ffffc097          	auipc	ra,0xffffc
    8000516a:	d1a080e7          	jalr	-742(ra) # 80000e80 <strlen>
    8000516e:	0015069b          	addiw	a3,a0,1
    80005172:	8652                	mv	a2,s4
    80005174:	85ca                	mv	a1,s2
    80005176:	855a                	mv	a0,s6
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	75c080e7          	jalr	1884(ra) # 800018d4 <copyout>
    80005180:	14054163          	bltz	a0,800052c2 <exec+0x340>
    ustack[argc] = sp;
    80005184:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005188:	0485                	addi	s1,s1,1
    8000518a:	008d0793          	addi	a5,s10,8
    8000518e:	def43823          	sd	a5,-528(s0)
    80005192:	008d3503          	ld	a0,8(s10)
    80005196:	c909                	beqz	a0,800051a8 <exec+0x226>
    if(argc >= MAXARG)
    80005198:	09a1                	addi	s3,s3,8
    8000519a:	fb3a95e3          	bne	s5,s3,80005144 <exec+0x1c2>
  ip = 0;
    8000519e:	4a81                	li	s5,0
    800051a0:	a8dd                	j	80005296 <exec+0x314>
  sp = sz;
    800051a2:	df843903          	ld	s2,-520(s0)
  for(argc = 0; argv[argc]; argc++) {
    800051a6:	4481                	li	s1,0
  ustack[argc] = 0;
    800051a8:	00349793          	slli	a5,s1,0x3
    800051ac:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd7f70>
    800051b0:	97a2                	add	a5,a5,s0
    800051b2:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    800051b6:	00148693          	addi	a3,s1,1
    800051ba:	068e                	slli	a3,a3,0x3
    800051bc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051c0:	ff097913          	andi	s2,s2,-16
  ip = 0;
    800051c4:	4a81                	li	s5,0
  if(sp < stackbase)
    800051c6:	0d896863          	bltu	s2,s8,80005296 <exec+0x314>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051ca:	e8840613          	addi	a2,s0,-376
    800051ce:	85ca                	mv	a1,s2
    800051d0:	855a                	mv	a0,s6
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	702080e7          	jalr	1794(ra) # 800018d4 <copyout>
    800051da:	0e054663          	bltz	a0,800052c6 <exec+0x344>
  p->trapframe->a1 = sp;
    800051de:	058bb783          	ld	a5,88(s7)
    800051e2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051e6:	de843783          	ld	a5,-536(s0)
    800051ea:	0007c703          	lbu	a4,0(a5)
    800051ee:	cf11                	beqz	a4,8000520a <exec+0x288>
    800051f0:	0785                	addi	a5,a5,1
    if(*s == '/')
    800051f2:	02f00693          	li	a3,47
    800051f6:	a039                	j	80005204 <exec+0x282>
      last = s+1;
    800051f8:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800051fc:	0785                	addi	a5,a5,1
    800051fe:	fff7c703          	lbu	a4,-1(a5)
    80005202:	c701                	beqz	a4,8000520a <exec+0x288>
    if(*s == '/')
    80005204:	fed71ce3          	bne	a4,a3,800051fc <exec+0x27a>
    80005208:	bfc5                	j	800051f8 <exec+0x276>
  safestrcpy(p->name, last, sizeof(p->name));
    8000520a:	4641                	li	a2,16
    8000520c:	de843583          	ld	a1,-536(s0)
    80005210:	158b8513          	addi	a0,s7,344
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	c3a080e7          	jalr	-966(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    8000521c:	050bb983          	ld	s3,80(s7)
  p->pagetable = pagetable;
    80005220:	056bb823          	sd	s6,80(s7)
  kvmdealloc(p->kpagetable, p->sz, 0);
    80005224:	4601                	li	a2,0
    80005226:	048bb583          	ld	a1,72(s7)
    8000522a:	168bb503          	ld	a0,360(s7)
    8000522e:	ffffc097          	auipc	ra,0xffffc
    80005232:	3ee080e7          	jalr	1006(ra) # 8000161c <kvmdealloc>
  if(upgtbl2kpgtbl(p->pagetable, p->kpagetable, 0, sz)<0){
    80005236:	df843a03          	ld	s4,-520(s0)
    8000523a:	86d2                	mv	a3,s4
    8000523c:	4601                	li	a2,0
    8000523e:	168bb583          	ld	a1,360(s7)
    80005242:	050bb503          	ld	a0,80(s7)
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	5c8080e7          	jalr	1480(ra) # 8000180e <upgtbl2kpgtbl>
    8000524e:	06054e63          	bltz	a0,800052ca <exec+0x348>
  p->sz = sz;
    80005252:	054bb423          	sd	s4,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005256:	058bb783          	ld	a5,88(s7)
    8000525a:	e6043703          	ld	a4,-416(s0)
    8000525e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005260:	058bb783          	ld	a5,88(s7)
    80005264:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005268:	85e6                	mv	a1,s9
    8000526a:	854e                	mv	a0,s3
    8000526c:	ffffd097          	auipc	ra,0xffffd
    80005270:	b5c080e7          	jalr	-1188(ra) # 80001dc8 <proc_freepagetable>
  if(p->pid==1) vmprint(p->pagetable); 
    80005274:	038ba703          	lw	a4,56(s7)
    80005278:	4785                	li	a5,1
    8000527a:	00f70563          	beq	a4,a5,80005284 <exec+0x302>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000527e:	0004851b          	sext.w	a0,s1
    80005282:	bb71                	j	8000501e <exec+0x9c>
  if(p->pid==1) vmprint(p->pagetable); 
    80005284:	050bb503          	ld	a0,80(s7)
    80005288:	00000097          	auipc	ra,0x0
    8000528c:	c0a080e7          	jalr	-1014(ra) # 80004e92 <vmprint>
    80005290:	b7fd                	j	8000527e <exec+0x2fc>
    80005292:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005296:	df843583          	ld	a1,-520(s0)
    8000529a:	855a                	mv	a0,s6
    8000529c:	ffffd097          	auipc	ra,0xffffd
    800052a0:	b2c080e7          	jalr	-1236(ra) # 80001dc8 <proc_freepagetable>
  if(ip){
    800052a4:	d60a93e3          	bnez	s5,8000500a <exec+0x88>
  return -1;
    800052a8:	557d                	li	a0,-1
    800052aa:	bb95                	j	8000501e <exec+0x9c>
    800052ac:	de943c23          	sd	s1,-520(s0)
    800052b0:	b7dd                	j	80005296 <exec+0x314>
    800052b2:	de943c23          	sd	s1,-520(s0)
    800052b6:	b7c5                	j	80005296 <exec+0x314>
    800052b8:	de943c23          	sd	s1,-520(s0)
    800052bc:	bfe9                	j	80005296 <exec+0x314>
  ip = 0;
    800052be:	4a81                	li	s5,0
    800052c0:	bfd9                	j	80005296 <exec+0x314>
    800052c2:	4a81                	li	s5,0
    800052c4:	bfc9                	j	80005296 <exec+0x314>
    800052c6:	4a81                	li	s5,0
    800052c8:	b7f9                	j	80005296 <exec+0x314>
    800052ca:	4a81                	li	s5,0
    800052cc:	b7e9                	j	80005296 <exec+0x314>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052ce:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052d2:	e0843783          	ld	a5,-504(s0)
    800052d6:	0017869b          	addiw	a3,a5,1
    800052da:	e0d43423          	sd	a3,-504(s0)
    800052de:	e0043783          	ld	a5,-512(s0)
    800052e2:	0387879b          	addiw	a5,a5,56
    800052e6:	e8045703          	lhu	a4,-384(s0)
    800052ea:	dee6d6e3          	bge	a3,a4,800050d6 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052ee:	2781                	sext.w	a5,a5
    800052f0:	e0f43023          	sd	a5,-512(s0)
    800052f4:	03800713          	li	a4,56
    800052f8:	86be                	mv	a3,a5
    800052fa:	e1040613          	addi	a2,s0,-496
    800052fe:	4581                	li	a1,0
    80005300:	8556                	mv	a0,s5
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	926080e7          	jalr	-1754(ra) # 80003c28 <readi>
    8000530a:	03800793          	li	a5,56
    8000530e:	f8f512e3          	bne	a0,a5,80005292 <exec+0x310>
    if(ph.type != ELF_PROG_LOAD)
    80005312:	e1042783          	lw	a5,-496(s0)
    80005316:	4705                	li	a4,1
    80005318:	fae79de3          	bne	a5,a4,800052d2 <exec+0x350>
    if(ph.memsz < ph.filesz)
    8000531c:	e3843603          	ld	a2,-456(s0)
    80005320:	e3043783          	ld	a5,-464(s0)
    80005324:	f8f664e3          	bltu	a2,a5,800052ac <exec+0x32a>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005328:	e2043783          	ld	a5,-480(s0)
    8000532c:	963e                	add	a2,a2,a5
    8000532e:	f8f662e3          	bltu	a2,a5,800052b2 <exec+0x330>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005332:	85a6                	mv	a1,s1
    80005334:	855a                	mv	a0,s6
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	23c080e7          	jalr	572(ra) # 80001572 <uvmalloc>
    8000533e:	dea43c23          	sd	a0,-520(s0)
    80005342:	d93d                	beqz	a0,800052b8 <exec+0x336>
    if(ph.vaddr % PGSIZE != 0)
    80005344:	e2043c03          	ld	s8,-480(s0)
    80005348:	de043783          	ld	a5,-544(s0)
    8000534c:	00fc77b3          	and	a5,s8,a5
    80005350:	f3b9                	bnez	a5,80005296 <exec+0x314>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005352:	e1842c83          	lw	s9,-488(s0)
    80005356:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000535a:	f60b8ae3          	beqz	s7,800052ce <exec+0x34c>
    8000535e:	89de                	mv	s3,s7
    80005360:	4481                	li	s1,0
    80005362:	bb89                	j	800050b4 <exec+0x132>

0000000080005364 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005364:	7179                	addi	sp,sp,-48
    80005366:	f406                	sd	ra,40(sp)
    80005368:	f022                	sd	s0,32(sp)
    8000536a:	ec26                	sd	s1,24(sp)
    8000536c:	e84a                	sd	s2,16(sp)
    8000536e:	1800                	addi	s0,sp,48
    80005370:	892e                	mv	s2,a1
    80005372:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005374:	fdc40593          	addi	a1,s0,-36
    80005378:	ffffe097          	auipc	ra,0xffffe
    8000537c:	a72080e7          	jalr	-1422(ra) # 80002dea <argint>
    80005380:	04054063          	bltz	a0,800053c0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005384:	fdc42703          	lw	a4,-36(s0)
    80005388:	47bd                	li	a5,15
    8000538a:	02e7ed63          	bltu	a5,a4,800053c4 <argfd+0x60>
    8000538e:	ffffd097          	auipc	ra,0xffffd
    80005392:	880080e7          	jalr	-1920(ra) # 80001c0e <myproc>
    80005396:	fdc42703          	lw	a4,-36(s0)
    8000539a:	01a70793          	addi	a5,a4,26
    8000539e:	078e                	slli	a5,a5,0x3
    800053a0:	953e                	add	a0,a0,a5
    800053a2:	611c                	ld	a5,0(a0)
    800053a4:	c395                	beqz	a5,800053c8 <argfd+0x64>
    return -1;
  if(pfd)
    800053a6:	00090463          	beqz	s2,800053ae <argfd+0x4a>
    *pfd = fd;
    800053aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053ae:	4501                	li	a0,0
  if(pf)
    800053b0:	c091                	beqz	s1,800053b4 <argfd+0x50>
    *pf = f;
    800053b2:	e09c                	sd	a5,0(s1)
}
    800053b4:	70a2                	ld	ra,40(sp)
    800053b6:	7402                	ld	s0,32(sp)
    800053b8:	64e2                	ld	s1,24(sp)
    800053ba:	6942                	ld	s2,16(sp)
    800053bc:	6145                	addi	sp,sp,48
    800053be:	8082                	ret
    return -1;
    800053c0:	557d                	li	a0,-1
    800053c2:	bfcd                	j	800053b4 <argfd+0x50>
    return -1;
    800053c4:	557d                	li	a0,-1
    800053c6:	b7fd                	j	800053b4 <argfd+0x50>
    800053c8:	557d                	li	a0,-1
    800053ca:	b7ed                	j	800053b4 <argfd+0x50>

00000000800053cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053cc:	1101                	addi	sp,sp,-32
    800053ce:	ec06                	sd	ra,24(sp)
    800053d0:	e822                	sd	s0,16(sp)
    800053d2:	e426                	sd	s1,8(sp)
    800053d4:	1000                	addi	s0,sp,32
    800053d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	836080e7          	jalr	-1994(ra) # 80001c0e <myproc>
    800053e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053e2:	0d050793          	addi	a5,a0,208
    800053e6:	4501                	li	a0,0
    800053e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800053ea:	6398                	ld	a4,0(a5)
    800053ec:	cb19                	beqz	a4,80005402 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800053ee:	2505                	addiw	a0,a0,1
    800053f0:	07a1                	addi	a5,a5,8
    800053f2:	fed51ce3          	bne	a0,a3,800053ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053f6:	557d                	li	a0,-1
}
    800053f8:	60e2                	ld	ra,24(sp)
    800053fa:	6442                	ld	s0,16(sp)
    800053fc:	64a2                	ld	s1,8(sp)
    800053fe:	6105                	addi	sp,sp,32
    80005400:	8082                	ret
      p->ofile[fd] = f;
    80005402:	01a50793          	addi	a5,a0,26
    80005406:	078e                	slli	a5,a5,0x3
    80005408:	963e                	add	a2,a2,a5
    8000540a:	e204                	sd	s1,0(a2)
      return fd;
    8000540c:	b7f5                	j	800053f8 <fdalloc+0x2c>

000000008000540e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000540e:	715d                	addi	sp,sp,-80
    80005410:	e486                	sd	ra,72(sp)
    80005412:	e0a2                	sd	s0,64(sp)
    80005414:	fc26                	sd	s1,56(sp)
    80005416:	f84a                	sd	s2,48(sp)
    80005418:	f44e                	sd	s3,40(sp)
    8000541a:	f052                	sd	s4,32(sp)
    8000541c:	ec56                	sd	s5,24(sp)
    8000541e:	0880                	addi	s0,sp,80
    80005420:	89ae                	mv	s3,a1
    80005422:	8ab2                	mv	s5,a2
    80005424:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005426:	fb040593          	addi	a1,s0,-80
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	d1e080e7          	jalr	-738(ra) # 80004148 <nameiparent>
    80005432:	892a                	mv	s2,a0
    80005434:	12050e63          	beqz	a0,80005570 <create+0x162>
    return 0;

  ilock(dp);
    80005438:	ffffe097          	auipc	ra,0xffffe
    8000543c:	53c080e7          	jalr	1340(ra) # 80003974 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005440:	4601                	li	a2,0
    80005442:	fb040593          	addi	a1,s0,-80
    80005446:	854a                	mv	a0,s2
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	a0a080e7          	jalr	-1526(ra) # 80003e52 <dirlookup>
    80005450:	84aa                	mv	s1,a0
    80005452:	c921                	beqz	a0,800054a2 <create+0x94>
    iunlockput(dp);
    80005454:	854a                	mv	a0,s2
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	780080e7          	jalr	1920(ra) # 80003bd6 <iunlockput>
    ilock(ip);
    8000545e:	8526                	mv	a0,s1
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	514080e7          	jalr	1300(ra) # 80003974 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005468:	2981                	sext.w	s3,s3
    8000546a:	4789                	li	a5,2
    8000546c:	02f99463          	bne	s3,a5,80005494 <create+0x86>
    80005470:	0444d783          	lhu	a5,68(s1)
    80005474:	37f9                	addiw	a5,a5,-2
    80005476:	17c2                	slli	a5,a5,0x30
    80005478:	93c1                	srli	a5,a5,0x30
    8000547a:	4705                	li	a4,1
    8000547c:	00f76c63          	bltu	a4,a5,80005494 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005480:	8526                	mv	a0,s1
    80005482:	60a6                	ld	ra,72(sp)
    80005484:	6406                	ld	s0,64(sp)
    80005486:	74e2                	ld	s1,56(sp)
    80005488:	7942                	ld	s2,48(sp)
    8000548a:	79a2                	ld	s3,40(sp)
    8000548c:	7a02                	ld	s4,32(sp)
    8000548e:	6ae2                	ld	s5,24(sp)
    80005490:	6161                	addi	sp,sp,80
    80005492:	8082                	ret
    iunlockput(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	740080e7          	jalr	1856(ra) # 80003bd6 <iunlockput>
    return 0;
    8000549e:	4481                	li	s1,0
    800054a0:	b7c5                	j	80005480 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800054a2:	85ce                	mv	a1,s3
    800054a4:	00092503          	lw	a0,0(s2)
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	332080e7          	jalr	818(ra) # 800037da <ialloc>
    800054b0:	84aa                	mv	s1,a0
    800054b2:	c521                	beqz	a0,800054fa <create+0xec>
  ilock(ip);
    800054b4:	ffffe097          	auipc	ra,0xffffe
    800054b8:	4c0080e7          	jalr	1216(ra) # 80003974 <ilock>
  ip->major = major;
    800054bc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800054c0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800054c4:	4a05                	li	s4,1
    800054c6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800054ca:	8526                	mv	a0,s1
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	3dc080e7          	jalr	988(ra) # 800038a8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054d4:	2981                	sext.w	s3,s3
    800054d6:	03498a63          	beq	s3,s4,8000550a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800054da:	40d0                	lw	a2,4(s1)
    800054dc:	fb040593          	addi	a1,s0,-80
    800054e0:	854a                	mv	a0,s2
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	b86080e7          	jalr	-1146(ra) # 80004068 <dirlink>
    800054ea:	06054b63          	bltz	a0,80005560 <create+0x152>
  iunlockput(dp);
    800054ee:	854a                	mv	a0,s2
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	6e6080e7          	jalr	1766(ra) # 80003bd6 <iunlockput>
  return ip;
    800054f8:	b761                	j	80005480 <create+0x72>
    panic("create: ialloc");
    800054fa:	00003517          	auipc	a0,0x3
    800054fe:	28650513          	addi	a0,a0,646 # 80008780 <syscalls+0x318>
    80005502:	ffffb097          	auipc	ra,0xffffb
    80005506:	044080e7          	jalr	68(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    8000550a:	04a95783          	lhu	a5,74(s2)
    8000550e:	2785                	addiw	a5,a5,1
    80005510:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005514:	854a                	mv	a0,s2
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	392080e7          	jalr	914(ra) # 800038a8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000551e:	40d0                	lw	a2,4(s1)
    80005520:	00003597          	auipc	a1,0x3
    80005524:	27058593          	addi	a1,a1,624 # 80008790 <syscalls+0x328>
    80005528:	8526                	mv	a0,s1
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	b3e080e7          	jalr	-1218(ra) # 80004068 <dirlink>
    80005532:	00054f63          	bltz	a0,80005550 <create+0x142>
    80005536:	00492603          	lw	a2,4(s2)
    8000553a:	00003597          	auipc	a1,0x3
    8000553e:	25e58593          	addi	a1,a1,606 # 80008798 <syscalls+0x330>
    80005542:	8526                	mv	a0,s1
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	b24080e7          	jalr	-1244(ra) # 80004068 <dirlink>
    8000554c:	f80557e3          	bgez	a0,800054da <create+0xcc>
      panic("create dots");
    80005550:	00003517          	auipc	a0,0x3
    80005554:	25050513          	addi	a0,a0,592 # 800087a0 <syscalls+0x338>
    80005558:	ffffb097          	auipc	ra,0xffffb
    8000555c:	fee080e7          	jalr	-18(ra) # 80000546 <panic>
    panic("create: dirlink");
    80005560:	00003517          	auipc	a0,0x3
    80005564:	25050513          	addi	a0,a0,592 # 800087b0 <syscalls+0x348>
    80005568:	ffffb097          	auipc	ra,0xffffb
    8000556c:	fde080e7          	jalr	-34(ra) # 80000546 <panic>
    return 0;
    80005570:	84aa                	mv	s1,a0
    80005572:	b739                	j	80005480 <create+0x72>

0000000080005574 <sys_dup>:
{
    80005574:	7179                	addi	sp,sp,-48
    80005576:	f406                	sd	ra,40(sp)
    80005578:	f022                	sd	s0,32(sp)
    8000557a:	ec26                	sd	s1,24(sp)
    8000557c:	e84a                	sd	s2,16(sp)
    8000557e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005580:	fd840613          	addi	a2,s0,-40
    80005584:	4581                	li	a1,0
    80005586:	4501                	li	a0,0
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	ddc080e7          	jalr	-548(ra) # 80005364 <argfd>
    return -1;
    80005590:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005592:	02054363          	bltz	a0,800055b8 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005596:	fd843903          	ld	s2,-40(s0)
    8000559a:	854a                	mv	a0,s2
    8000559c:	00000097          	auipc	ra,0x0
    800055a0:	e30080e7          	jalr	-464(ra) # 800053cc <fdalloc>
    800055a4:	84aa                	mv	s1,a0
    return -1;
    800055a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055a8:	00054863          	bltz	a0,800055b8 <sys_dup+0x44>
  filedup(f);
    800055ac:	854a                	mv	a0,s2
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	208080e7          	jalr	520(ra) # 800047b6 <filedup>
  return fd;
    800055b6:	87a6                	mv	a5,s1
}
    800055b8:	853e                	mv	a0,a5
    800055ba:	70a2                	ld	ra,40(sp)
    800055bc:	7402                	ld	s0,32(sp)
    800055be:	64e2                	ld	s1,24(sp)
    800055c0:	6942                	ld	s2,16(sp)
    800055c2:	6145                	addi	sp,sp,48
    800055c4:	8082                	ret

00000000800055c6 <sys_read>:
{
    800055c6:	7179                	addi	sp,sp,-48
    800055c8:	f406                	sd	ra,40(sp)
    800055ca:	f022                	sd	s0,32(sp)
    800055cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ce:	fe840613          	addi	a2,s0,-24
    800055d2:	4581                	li	a1,0
    800055d4:	4501                	li	a0,0
    800055d6:	00000097          	auipc	ra,0x0
    800055da:	d8e080e7          	jalr	-626(ra) # 80005364 <argfd>
    return -1;
    800055de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e0:	04054163          	bltz	a0,80005622 <sys_read+0x5c>
    800055e4:	fe440593          	addi	a1,s0,-28
    800055e8:	4509                	li	a0,2
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	800080e7          	jalr	-2048(ra) # 80002dea <argint>
    return -1;
    800055f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055f4:	02054763          	bltz	a0,80005622 <sys_read+0x5c>
    800055f8:	fd840593          	addi	a1,s0,-40
    800055fc:	4505                	li	a0,1
    800055fe:	ffffe097          	auipc	ra,0xffffe
    80005602:	80e080e7          	jalr	-2034(ra) # 80002e0c <argaddr>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005608:	00054d63          	bltz	a0,80005622 <sys_read+0x5c>
  return fileread(f, p, n);
    8000560c:	fe442603          	lw	a2,-28(s0)
    80005610:	fd843583          	ld	a1,-40(s0)
    80005614:	fe843503          	ld	a0,-24(s0)
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	32a080e7          	jalr	810(ra) # 80004942 <fileread>
    80005620:	87aa                	mv	a5,a0
}
    80005622:	853e                	mv	a0,a5
    80005624:	70a2                	ld	ra,40(sp)
    80005626:	7402                	ld	s0,32(sp)
    80005628:	6145                	addi	sp,sp,48
    8000562a:	8082                	ret

000000008000562c <sys_write>:
{
    8000562c:	7179                	addi	sp,sp,-48
    8000562e:	f406                	sd	ra,40(sp)
    80005630:	f022                	sd	s0,32(sp)
    80005632:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005634:	fe840613          	addi	a2,s0,-24
    80005638:	4581                	li	a1,0
    8000563a:	4501                	li	a0,0
    8000563c:	00000097          	auipc	ra,0x0
    80005640:	d28080e7          	jalr	-728(ra) # 80005364 <argfd>
    return -1;
    80005644:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005646:	04054163          	bltz	a0,80005688 <sys_write+0x5c>
    8000564a:	fe440593          	addi	a1,s0,-28
    8000564e:	4509                	li	a0,2
    80005650:	ffffd097          	auipc	ra,0xffffd
    80005654:	79a080e7          	jalr	1946(ra) # 80002dea <argint>
    return -1;
    80005658:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000565a:	02054763          	bltz	a0,80005688 <sys_write+0x5c>
    8000565e:	fd840593          	addi	a1,s0,-40
    80005662:	4505                	li	a0,1
    80005664:	ffffd097          	auipc	ra,0xffffd
    80005668:	7a8080e7          	jalr	1960(ra) # 80002e0c <argaddr>
    return -1;
    8000566c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000566e:	00054d63          	bltz	a0,80005688 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005672:	fe442603          	lw	a2,-28(s0)
    80005676:	fd843583          	ld	a1,-40(s0)
    8000567a:	fe843503          	ld	a0,-24(s0)
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	386080e7          	jalr	902(ra) # 80004a04 <filewrite>
    80005686:	87aa                	mv	a5,a0
}
    80005688:	853e                	mv	a0,a5
    8000568a:	70a2                	ld	ra,40(sp)
    8000568c:	7402                	ld	s0,32(sp)
    8000568e:	6145                	addi	sp,sp,48
    80005690:	8082                	ret

0000000080005692 <sys_close>:
{
    80005692:	1101                	addi	sp,sp,-32
    80005694:	ec06                	sd	ra,24(sp)
    80005696:	e822                	sd	s0,16(sp)
    80005698:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000569a:	fe040613          	addi	a2,s0,-32
    8000569e:	fec40593          	addi	a1,s0,-20
    800056a2:	4501                	li	a0,0
    800056a4:	00000097          	auipc	ra,0x0
    800056a8:	cc0080e7          	jalr	-832(ra) # 80005364 <argfd>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056ae:	02054463          	bltz	a0,800056d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056b2:	ffffc097          	auipc	ra,0xffffc
    800056b6:	55c080e7          	jalr	1372(ra) # 80001c0e <myproc>
    800056ba:	fec42783          	lw	a5,-20(s0)
    800056be:	07e9                	addi	a5,a5,26
    800056c0:	078e                	slli	a5,a5,0x3
    800056c2:	953e                	add	a0,a0,a5
    800056c4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800056c8:	fe043503          	ld	a0,-32(s0)
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	13c080e7          	jalr	316(ra) # 80004808 <fileclose>
  return 0;
    800056d4:	4781                	li	a5,0
}
    800056d6:	853e                	mv	a0,a5
    800056d8:	60e2                	ld	ra,24(sp)
    800056da:	6442                	ld	s0,16(sp)
    800056dc:	6105                	addi	sp,sp,32
    800056de:	8082                	ret

00000000800056e0 <sys_fstat>:
{
    800056e0:	1101                	addi	sp,sp,-32
    800056e2:	ec06                	sd	ra,24(sp)
    800056e4:	e822                	sd	s0,16(sp)
    800056e6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056e8:	fe840613          	addi	a2,s0,-24
    800056ec:	4581                	li	a1,0
    800056ee:	4501                	li	a0,0
    800056f0:	00000097          	auipc	ra,0x0
    800056f4:	c74080e7          	jalr	-908(ra) # 80005364 <argfd>
    return -1;
    800056f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056fa:	02054563          	bltz	a0,80005724 <sys_fstat+0x44>
    800056fe:	fe040593          	addi	a1,s0,-32
    80005702:	4505                	li	a0,1
    80005704:	ffffd097          	auipc	ra,0xffffd
    80005708:	708080e7          	jalr	1800(ra) # 80002e0c <argaddr>
    return -1;
    8000570c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000570e:	00054b63          	bltz	a0,80005724 <sys_fstat+0x44>
  return filestat(f, st);
    80005712:	fe043583          	ld	a1,-32(s0)
    80005716:	fe843503          	ld	a0,-24(s0)
    8000571a:	fffff097          	auipc	ra,0xfffff
    8000571e:	1b6080e7          	jalr	438(ra) # 800048d0 <filestat>
    80005722:	87aa                	mv	a5,a0
}
    80005724:	853e                	mv	a0,a5
    80005726:	60e2                	ld	ra,24(sp)
    80005728:	6442                	ld	s0,16(sp)
    8000572a:	6105                	addi	sp,sp,32
    8000572c:	8082                	ret

000000008000572e <sys_link>:
{
    8000572e:	7169                	addi	sp,sp,-304
    80005730:	f606                	sd	ra,296(sp)
    80005732:	f222                	sd	s0,288(sp)
    80005734:	ee26                	sd	s1,280(sp)
    80005736:	ea4a                	sd	s2,272(sp)
    80005738:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000573a:	08000613          	li	a2,128
    8000573e:	ed040593          	addi	a1,s0,-304
    80005742:	4501                	li	a0,0
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	6ea080e7          	jalr	1770(ra) # 80002e2e <argstr>
    return -1;
    8000574c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000574e:	10054e63          	bltz	a0,8000586a <sys_link+0x13c>
    80005752:	08000613          	li	a2,128
    80005756:	f5040593          	addi	a1,s0,-176
    8000575a:	4505                	li	a0,1
    8000575c:	ffffd097          	auipc	ra,0xffffd
    80005760:	6d2080e7          	jalr	1746(ra) # 80002e2e <argstr>
    return -1;
    80005764:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005766:	10054263          	bltz	a0,8000586a <sys_link+0x13c>
  begin_op();
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	bd0080e7          	jalr	-1072(ra) # 8000433a <begin_op>
  if((ip = namei(old)) == 0){
    80005772:	ed040513          	addi	a0,s0,-304
    80005776:	fffff097          	auipc	ra,0xfffff
    8000577a:	9b4080e7          	jalr	-1612(ra) # 8000412a <namei>
    8000577e:	84aa                	mv	s1,a0
    80005780:	c551                	beqz	a0,8000580c <sys_link+0xde>
  ilock(ip);
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	1f2080e7          	jalr	498(ra) # 80003974 <ilock>
  if(ip->type == T_DIR){
    8000578a:	04449703          	lh	a4,68(s1)
    8000578e:	4785                	li	a5,1
    80005790:	08f70463          	beq	a4,a5,80005818 <sys_link+0xea>
  ip->nlink++;
    80005794:	04a4d783          	lhu	a5,74(s1)
    80005798:	2785                	addiw	a5,a5,1
    8000579a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000579e:	8526                	mv	a0,s1
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	108080e7          	jalr	264(ra) # 800038a8 <iupdate>
  iunlock(ip);
    800057a8:	8526                	mv	a0,s1
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	28c080e7          	jalr	652(ra) # 80003a36 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057b2:	fd040593          	addi	a1,s0,-48
    800057b6:	f5040513          	addi	a0,s0,-176
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	98e080e7          	jalr	-1650(ra) # 80004148 <nameiparent>
    800057c2:	892a                	mv	s2,a0
    800057c4:	c935                	beqz	a0,80005838 <sys_link+0x10a>
  ilock(dp);
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	1ae080e7          	jalr	430(ra) # 80003974 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057ce:	00092703          	lw	a4,0(s2)
    800057d2:	409c                	lw	a5,0(s1)
    800057d4:	04f71d63          	bne	a4,a5,8000582e <sys_link+0x100>
    800057d8:	40d0                	lw	a2,4(s1)
    800057da:	fd040593          	addi	a1,s0,-48
    800057de:	854a                	mv	a0,s2
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	888080e7          	jalr	-1912(ra) # 80004068 <dirlink>
    800057e8:	04054363          	bltz	a0,8000582e <sys_link+0x100>
  iunlockput(dp);
    800057ec:	854a                	mv	a0,s2
    800057ee:	ffffe097          	auipc	ra,0xffffe
    800057f2:	3e8080e7          	jalr	1000(ra) # 80003bd6 <iunlockput>
  iput(ip);
    800057f6:	8526                	mv	a0,s1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	336080e7          	jalr	822(ra) # 80003b2e <iput>
  end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	bb8080e7          	jalr	-1096(ra) # 800043b8 <end_op>
  return 0;
    80005808:	4781                	li	a5,0
    8000580a:	a085                	j	8000586a <sys_link+0x13c>
    end_op();
    8000580c:	fffff097          	auipc	ra,0xfffff
    80005810:	bac080e7          	jalr	-1108(ra) # 800043b8 <end_op>
    return -1;
    80005814:	57fd                	li	a5,-1
    80005816:	a891                	j	8000586a <sys_link+0x13c>
    iunlockput(ip);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	3bc080e7          	jalr	956(ra) # 80003bd6 <iunlockput>
    end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	b96080e7          	jalr	-1130(ra) # 800043b8 <end_op>
    return -1;
    8000582a:	57fd                	li	a5,-1
    8000582c:	a83d                	j	8000586a <sys_link+0x13c>
    iunlockput(dp);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	3a6080e7          	jalr	934(ra) # 80003bd6 <iunlockput>
  ilock(ip);
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	13a080e7          	jalr	314(ra) # 80003974 <ilock>
  ip->nlink--;
    80005842:	04a4d783          	lhu	a5,74(s1)
    80005846:	37fd                	addiw	a5,a5,-1
    80005848:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	05a080e7          	jalr	90(ra) # 800038a8 <iupdate>
  iunlockput(ip);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	37e080e7          	jalr	894(ra) # 80003bd6 <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	b58080e7          	jalr	-1192(ra) # 800043b8 <end_op>
  return -1;
    80005868:	57fd                	li	a5,-1
}
    8000586a:	853e                	mv	a0,a5
    8000586c:	70b2                	ld	ra,296(sp)
    8000586e:	7412                	ld	s0,288(sp)
    80005870:	64f2                	ld	s1,280(sp)
    80005872:	6952                	ld	s2,272(sp)
    80005874:	6155                	addi	sp,sp,304
    80005876:	8082                	ret

0000000080005878 <sys_unlink>:
{
    80005878:	7151                	addi	sp,sp,-240
    8000587a:	f586                	sd	ra,232(sp)
    8000587c:	f1a2                	sd	s0,224(sp)
    8000587e:	eda6                	sd	s1,216(sp)
    80005880:	e9ca                	sd	s2,208(sp)
    80005882:	e5ce                	sd	s3,200(sp)
    80005884:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005886:	08000613          	li	a2,128
    8000588a:	f3040593          	addi	a1,s0,-208
    8000588e:	4501                	li	a0,0
    80005890:	ffffd097          	auipc	ra,0xffffd
    80005894:	59e080e7          	jalr	1438(ra) # 80002e2e <argstr>
    80005898:	18054163          	bltz	a0,80005a1a <sys_unlink+0x1a2>
  begin_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	a9e080e7          	jalr	-1378(ra) # 8000433a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058a4:	fb040593          	addi	a1,s0,-80
    800058a8:	f3040513          	addi	a0,s0,-208
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	89c080e7          	jalr	-1892(ra) # 80004148 <nameiparent>
    800058b4:	84aa                	mv	s1,a0
    800058b6:	c979                	beqz	a0,8000598c <sys_unlink+0x114>
  ilock(dp);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	0bc080e7          	jalr	188(ra) # 80003974 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058c0:	00003597          	auipc	a1,0x3
    800058c4:	ed058593          	addi	a1,a1,-304 # 80008790 <syscalls+0x328>
    800058c8:	fb040513          	addi	a0,s0,-80
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	56c080e7          	jalr	1388(ra) # 80003e38 <namecmp>
    800058d4:	14050a63          	beqz	a0,80005a28 <sys_unlink+0x1b0>
    800058d8:	00003597          	auipc	a1,0x3
    800058dc:	ec058593          	addi	a1,a1,-320 # 80008798 <syscalls+0x330>
    800058e0:	fb040513          	addi	a0,s0,-80
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	554080e7          	jalr	1364(ra) # 80003e38 <namecmp>
    800058ec:	12050e63          	beqz	a0,80005a28 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058f0:	f2c40613          	addi	a2,s0,-212
    800058f4:	fb040593          	addi	a1,s0,-80
    800058f8:	8526                	mv	a0,s1
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	558080e7          	jalr	1368(ra) # 80003e52 <dirlookup>
    80005902:	892a                	mv	s2,a0
    80005904:	12050263          	beqz	a0,80005a28 <sys_unlink+0x1b0>
  ilock(ip);
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	06c080e7          	jalr	108(ra) # 80003974 <ilock>
  if(ip->nlink < 1)
    80005910:	04a91783          	lh	a5,74(s2)
    80005914:	08f05263          	blez	a5,80005998 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005918:	04491703          	lh	a4,68(s2)
    8000591c:	4785                	li	a5,1
    8000591e:	08f70563          	beq	a4,a5,800059a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005922:	4641                	li	a2,16
    80005924:	4581                	li	a1,0
    80005926:	fc040513          	addi	a0,s0,-64
    8000592a:	ffffb097          	auipc	ra,0xffffb
    8000592e:	3d2080e7          	jalr	978(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005932:	4741                	li	a4,16
    80005934:	f2c42683          	lw	a3,-212(s0)
    80005938:	fc040613          	addi	a2,s0,-64
    8000593c:	4581                	li	a1,0
    8000593e:	8526                	mv	a0,s1
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	3de080e7          	jalr	990(ra) # 80003d1e <writei>
    80005948:	47c1                	li	a5,16
    8000594a:	0af51563          	bne	a0,a5,800059f4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000594e:	04491703          	lh	a4,68(s2)
    80005952:	4785                	li	a5,1
    80005954:	0af70863          	beq	a4,a5,80005a04 <sys_unlink+0x18c>
  iunlockput(dp);
    80005958:	8526                	mv	a0,s1
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	27c080e7          	jalr	636(ra) # 80003bd6 <iunlockput>
  ip->nlink--;
    80005962:	04a95783          	lhu	a5,74(s2)
    80005966:	37fd                	addiw	a5,a5,-1
    80005968:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000596c:	854a                	mv	a0,s2
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	f3a080e7          	jalr	-198(ra) # 800038a8 <iupdate>
  iunlockput(ip);
    80005976:	854a                	mv	a0,s2
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	25e080e7          	jalr	606(ra) # 80003bd6 <iunlockput>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	a38080e7          	jalr	-1480(ra) # 800043b8 <end_op>
  return 0;
    80005988:	4501                	li	a0,0
    8000598a:	a84d                	j	80005a3c <sys_unlink+0x1c4>
    end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	a2c080e7          	jalr	-1492(ra) # 800043b8 <end_op>
    return -1;
    80005994:	557d                	li	a0,-1
    80005996:	a05d                	j	80005a3c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005998:	00003517          	auipc	a0,0x3
    8000599c:	e2850513          	addi	a0,a0,-472 # 800087c0 <syscalls+0x358>
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	ba6080e7          	jalr	-1114(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059a8:	04c92703          	lw	a4,76(s2)
    800059ac:	02000793          	li	a5,32
    800059b0:	f6e7f9e3          	bgeu	a5,a4,80005922 <sys_unlink+0xaa>
    800059b4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059b8:	4741                	li	a4,16
    800059ba:	86ce                	mv	a3,s3
    800059bc:	f1840613          	addi	a2,s0,-232
    800059c0:	4581                	li	a1,0
    800059c2:	854a                	mv	a0,s2
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	264080e7          	jalr	612(ra) # 80003c28 <readi>
    800059cc:	47c1                	li	a5,16
    800059ce:	00f51b63          	bne	a0,a5,800059e4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059d2:	f1845783          	lhu	a5,-232(s0)
    800059d6:	e7a1                	bnez	a5,80005a1e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059d8:	29c1                	addiw	s3,s3,16
    800059da:	04c92783          	lw	a5,76(s2)
    800059de:	fcf9ede3          	bltu	s3,a5,800059b8 <sys_unlink+0x140>
    800059e2:	b781                	j	80005922 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059e4:	00003517          	auipc	a0,0x3
    800059e8:	df450513          	addi	a0,a0,-524 # 800087d8 <syscalls+0x370>
    800059ec:	ffffb097          	auipc	ra,0xffffb
    800059f0:	b5a080e7          	jalr	-1190(ra) # 80000546 <panic>
    panic("unlink: writei");
    800059f4:	00003517          	auipc	a0,0x3
    800059f8:	dfc50513          	addi	a0,a0,-516 # 800087f0 <syscalls+0x388>
    800059fc:	ffffb097          	auipc	ra,0xffffb
    80005a00:	b4a080e7          	jalr	-1206(ra) # 80000546 <panic>
    dp->nlink--;
    80005a04:	04a4d783          	lhu	a5,74(s1)
    80005a08:	37fd                	addiw	a5,a5,-1
    80005a0a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a0e:	8526                	mv	a0,s1
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	e98080e7          	jalr	-360(ra) # 800038a8 <iupdate>
    80005a18:	b781                	j	80005958 <sys_unlink+0xe0>
    return -1;
    80005a1a:	557d                	li	a0,-1
    80005a1c:	a005                	j	80005a3c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	1b6080e7          	jalr	438(ra) # 80003bd6 <iunlockput>
  iunlockput(dp);
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	1ac080e7          	jalr	428(ra) # 80003bd6 <iunlockput>
  end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	986080e7          	jalr	-1658(ra) # 800043b8 <end_op>
  return -1;
    80005a3a:	557d                	li	a0,-1
}
    80005a3c:	70ae                	ld	ra,232(sp)
    80005a3e:	740e                	ld	s0,224(sp)
    80005a40:	64ee                	ld	s1,216(sp)
    80005a42:	694e                	ld	s2,208(sp)
    80005a44:	69ae                	ld	s3,200(sp)
    80005a46:	616d                	addi	sp,sp,240
    80005a48:	8082                	ret

0000000080005a4a <sys_open>:

uint64
sys_open(void)
{
    80005a4a:	7131                	addi	sp,sp,-192
    80005a4c:	fd06                	sd	ra,184(sp)
    80005a4e:	f922                	sd	s0,176(sp)
    80005a50:	f526                	sd	s1,168(sp)
    80005a52:	f14a                	sd	s2,160(sp)
    80005a54:	ed4e                	sd	s3,152(sp)
    80005a56:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a58:	08000613          	li	a2,128
    80005a5c:	f5040593          	addi	a1,s0,-176
    80005a60:	4501                	li	a0,0
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	3cc080e7          	jalr	972(ra) # 80002e2e <argstr>
    return -1;
    80005a6a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a6c:	0c054163          	bltz	a0,80005b2e <sys_open+0xe4>
    80005a70:	f4c40593          	addi	a1,s0,-180
    80005a74:	4505                	li	a0,1
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	374080e7          	jalr	884(ra) # 80002dea <argint>
    80005a7e:	0a054863          	bltz	a0,80005b2e <sys_open+0xe4>

  begin_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	8b8080e7          	jalr	-1864(ra) # 8000433a <begin_op>

  if(omode & O_CREATE){
    80005a8a:	f4c42783          	lw	a5,-180(s0)
    80005a8e:	2007f793          	andi	a5,a5,512
    80005a92:	cbdd                	beqz	a5,80005b48 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a94:	4681                	li	a3,0
    80005a96:	4601                	li	a2,0
    80005a98:	4589                	li	a1,2
    80005a9a:	f5040513          	addi	a0,s0,-176
    80005a9e:	00000097          	auipc	ra,0x0
    80005aa2:	970080e7          	jalr	-1680(ra) # 8000540e <create>
    80005aa6:	892a                	mv	s2,a0
    if(ip == 0){
    80005aa8:	c959                	beqz	a0,80005b3e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005aaa:	04491703          	lh	a4,68(s2)
    80005aae:	478d                	li	a5,3
    80005ab0:	00f71763          	bne	a4,a5,80005abe <sys_open+0x74>
    80005ab4:	04695703          	lhu	a4,70(s2)
    80005ab8:	47a5                	li	a5,9
    80005aba:	0ce7ec63          	bltu	a5,a4,80005b92 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	c8e080e7          	jalr	-882(ra) # 8000474c <filealloc>
    80005ac6:	89aa                	mv	s3,a0
    80005ac8:	10050263          	beqz	a0,80005bcc <sys_open+0x182>
    80005acc:	00000097          	auipc	ra,0x0
    80005ad0:	900080e7          	jalr	-1792(ra) # 800053cc <fdalloc>
    80005ad4:	84aa                	mv	s1,a0
    80005ad6:	0e054663          	bltz	a0,80005bc2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ada:	04491703          	lh	a4,68(s2)
    80005ade:	478d                	li	a5,3
    80005ae0:	0cf70463          	beq	a4,a5,80005ba8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ae4:	4789                	li	a5,2
    80005ae6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005aea:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005aee:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005af2:	f4c42783          	lw	a5,-180(s0)
    80005af6:	0017c713          	xori	a4,a5,1
    80005afa:	8b05                	andi	a4,a4,1
    80005afc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b00:	0037f713          	andi	a4,a5,3
    80005b04:	00e03733          	snez	a4,a4
    80005b08:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b0c:	4007f793          	andi	a5,a5,1024
    80005b10:	c791                	beqz	a5,80005b1c <sys_open+0xd2>
    80005b12:	04491703          	lh	a4,68(s2)
    80005b16:	4789                	li	a5,2
    80005b18:	08f70f63          	beq	a4,a5,80005bb6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b1c:	854a                	mv	a0,s2
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	f18080e7          	jalr	-232(ra) # 80003a36 <iunlock>
  end_op();
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	892080e7          	jalr	-1902(ra) # 800043b8 <end_op>

  return fd;
}
    80005b2e:	8526                	mv	a0,s1
    80005b30:	70ea                	ld	ra,184(sp)
    80005b32:	744a                	ld	s0,176(sp)
    80005b34:	74aa                	ld	s1,168(sp)
    80005b36:	790a                	ld	s2,160(sp)
    80005b38:	69ea                	ld	s3,152(sp)
    80005b3a:	6129                	addi	sp,sp,192
    80005b3c:	8082                	ret
      end_op();
    80005b3e:	fffff097          	auipc	ra,0xfffff
    80005b42:	87a080e7          	jalr	-1926(ra) # 800043b8 <end_op>
      return -1;
    80005b46:	b7e5                	j	80005b2e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b48:	f5040513          	addi	a0,s0,-176
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	5de080e7          	jalr	1502(ra) # 8000412a <namei>
    80005b54:	892a                	mv	s2,a0
    80005b56:	c905                	beqz	a0,80005b86 <sys_open+0x13c>
    ilock(ip);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	e1c080e7          	jalr	-484(ra) # 80003974 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b60:	04491703          	lh	a4,68(s2)
    80005b64:	4785                	li	a5,1
    80005b66:	f4f712e3          	bne	a4,a5,80005aaa <sys_open+0x60>
    80005b6a:	f4c42783          	lw	a5,-180(s0)
    80005b6e:	dba1                	beqz	a5,80005abe <sys_open+0x74>
      iunlockput(ip);
    80005b70:	854a                	mv	a0,s2
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	064080e7          	jalr	100(ra) # 80003bd6 <iunlockput>
      end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	83e080e7          	jalr	-1986(ra) # 800043b8 <end_op>
      return -1;
    80005b82:	54fd                	li	s1,-1
    80005b84:	b76d                	j	80005b2e <sys_open+0xe4>
      end_op();
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	832080e7          	jalr	-1998(ra) # 800043b8 <end_op>
      return -1;
    80005b8e:	54fd                	li	s1,-1
    80005b90:	bf79                	j	80005b2e <sys_open+0xe4>
    iunlockput(ip);
    80005b92:	854a                	mv	a0,s2
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	042080e7          	jalr	66(ra) # 80003bd6 <iunlockput>
    end_op();
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	81c080e7          	jalr	-2020(ra) # 800043b8 <end_op>
    return -1;
    80005ba4:	54fd                	li	s1,-1
    80005ba6:	b761                	j	80005b2e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ba8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bac:	04691783          	lh	a5,70(s2)
    80005bb0:	02f99223          	sh	a5,36(s3)
    80005bb4:	bf2d                	j	80005aee <sys_open+0xa4>
    itrunc(ip);
    80005bb6:	854a                	mv	a0,s2
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	eca080e7          	jalr	-310(ra) # 80003a82 <itrunc>
    80005bc0:	bfb1                	j	80005b1c <sys_open+0xd2>
      fileclose(f);
    80005bc2:	854e                	mv	a0,s3
    80005bc4:	fffff097          	auipc	ra,0xfffff
    80005bc8:	c44080e7          	jalr	-956(ra) # 80004808 <fileclose>
    iunlockput(ip);
    80005bcc:	854a                	mv	a0,s2
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	008080e7          	jalr	8(ra) # 80003bd6 <iunlockput>
    end_op();
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	7e2080e7          	jalr	2018(ra) # 800043b8 <end_op>
    return -1;
    80005bde:	54fd                	li	s1,-1
    80005be0:	b7b9                	j	80005b2e <sys_open+0xe4>

0000000080005be2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005be2:	7175                	addi	sp,sp,-144
    80005be4:	e506                	sd	ra,136(sp)
    80005be6:	e122                	sd	s0,128(sp)
    80005be8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	750080e7          	jalr	1872(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bf2:	08000613          	li	a2,128
    80005bf6:	f7040593          	addi	a1,s0,-144
    80005bfa:	4501                	li	a0,0
    80005bfc:	ffffd097          	auipc	ra,0xffffd
    80005c00:	232080e7          	jalr	562(ra) # 80002e2e <argstr>
    80005c04:	02054963          	bltz	a0,80005c36 <sys_mkdir+0x54>
    80005c08:	4681                	li	a3,0
    80005c0a:	4601                	li	a2,0
    80005c0c:	4585                	li	a1,1
    80005c0e:	f7040513          	addi	a0,s0,-144
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	7fc080e7          	jalr	2044(ra) # 8000540e <create>
    80005c1a:	cd11                	beqz	a0,80005c36 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	fba080e7          	jalr	-70(ra) # 80003bd6 <iunlockput>
  end_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	794080e7          	jalr	1940(ra) # 800043b8 <end_op>
  return 0;
    80005c2c:	4501                	li	a0,0
}
    80005c2e:	60aa                	ld	ra,136(sp)
    80005c30:	640a                	ld	s0,128(sp)
    80005c32:	6149                	addi	sp,sp,144
    80005c34:	8082                	ret
    end_op();
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	782080e7          	jalr	1922(ra) # 800043b8 <end_op>
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	b7fd                	j	80005c2e <sys_mkdir+0x4c>

0000000080005c42 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c42:	7135                	addi	sp,sp,-160
    80005c44:	ed06                	sd	ra,152(sp)
    80005c46:	e922                	sd	s0,144(sp)
    80005c48:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	6f0080e7          	jalr	1776(ra) # 8000433a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c52:	08000613          	li	a2,128
    80005c56:	f7040593          	addi	a1,s0,-144
    80005c5a:	4501                	li	a0,0
    80005c5c:	ffffd097          	auipc	ra,0xffffd
    80005c60:	1d2080e7          	jalr	466(ra) # 80002e2e <argstr>
    80005c64:	04054a63          	bltz	a0,80005cb8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c68:	f6c40593          	addi	a1,s0,-148
    80005c6c:	4505                	li	a0,1
    80005c6e:	ffffd097          	auipc	ra,0xffffd
    80005c72:	17c080e7          	jalr	380(ra) # 80002dea <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c76:	04054163          	bltz	a0,80005cb8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c7a:	f6840593          	addi	a1,s0,-152
    80005c7e:	4509                	li	a0,2
    80005c80:	ffffd097          	auipc	ra,0xffffd
    80005c84:	16a080e7          	jalr	362(ra) # 80002dea <argint>
     argint(1, &major) < 0 ||
    80005c88:	02054863          	bltz	a0,80005cb8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c8c:	f6841683          	lh	a3,-152(s0)
    80005c90:	f6c41603          	lh	a2,-148(s0)
    80005c94:	458d                	li	a1,3
    80005c96:	f7040513          	addi	a0,s0,-144
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	774080e7          	jalr	1908(ra) # 8000540e <create>
     argint(2, &minor) < 0 ||
    80005ca2:	c919                	beqz	a0,80005cb8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	f32080e7          	jalr	-206(ra) # 80003bd6 <iunlockput>
  end_op();
    80005cac:	ffffe097          	auipc	ra,0xffffe
    80005cb0:	70c080e7          	jalr	1804(ra) # 800043b8 <end_op>
  return 0;
    80005cb4:	4501                	li	a0,0
    80005cb6:	a031                	j	80005cc2 <sys_mknod+0x80>
    end_op();
    80005cb8:	ffffe097          	auipc	ra,0xffffe
    80005cbc:	700080e7          	jalr	1792(ra) # 800043b8 <end_op>
    return -1;
    80005cc0:	557d                	li	a0,-1
}
    80005cc2:	60ea                	ld	ra,152(sp)
    80005cc4:	644a                	ld	s0,144(sp)
    80005cc6:	610d                	addi	sp,sp,160
    80005cc8:	8082                	ret

0000000080005cca <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cca:	7135                	addi	sp,sp,-160
    80005ccc:	ed06                	sd	ra,152(sp)
    80005cce:	e922                	sd	s0,144(sp)
    80005cd0:	e526                	sd	s1,136(sp)
    80005cd2:	e14a                	sd	s2,128(sp)
    80005cd4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005cd6:	ffffc097          	auipc	ra,0xffffc
    80005cda:	f38080e7          	jalr	-200(ra) # 80001c0e <myproc>
    80005cde:	892a                	mv	s2,a0
  
  begin_op();
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	65a080e7          	jalr	1626(ra) # 8000433a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ce8:	08000613          	li	a2,128
    80005cec:	f6040593          	addi	a1,s0,-160
    80005cf0:	4501                	li	a0,0
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	13c080e7          	jalr	316(ra) # 80002e2e <argstr>
    80005cfa:	04054b63          	bltz	a0,80005d50 <sys_chdir+0x86>
    80005cfe:	f6040513          	addi	a0,s0,-160
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	428080e7          	jalr	1064(ra) # 8000412a <namei>
    80005d0a:	84aa                	mv	s1,a0
    80005d0c:	c131                	beqz	a0,80005d50 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	c66080e7          	jalr	-922(ra) # 80003974 <ilock>
  if(ip->type != T_DIR){
    80005d16:	04449703          	lh	a4,68(s1)
    80005d1a:	4785                	li	a5,1
    80005d1c:	04f71063          	bne	a4,a5,80005d5c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d20:	8526                	mv	a0,s1
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	d14080e7          	jalr	-748(ra) # 80003a36 <iunlock>
  iput(p->cwd);
    80005d2a:	15093503          	ld	a0,336(s2)
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	e00080e7          	jalr	-512(ra) # 80003b2e <iput>
  end_op();
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	682080e7          	jalr	1666(ra) # 800043b8 <end_op>
  p->cwd = ip;
    80005d3e:	14993823          	sd	s1,336(s2)
  return 0;
    80005d42:	4501                	li	a0,0
}
    80005d44:	60ea                	ld	ra,152(sp)
    80005d46:	644a                	ld	s0,144(sp)
    80005d48:	64aa                	ld	s1,136(sp)
    80005d4a:	690a                	ld	s2,128(sp)
    80005d4c:	610d                	addi	sp,sp,160
    80005d4e:	8082                	ret
    end_op();
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	668080e7          	jalr	1640(ra) # 800043b8 <end_op>
    return -1;
    80005d58:	557d                	li	a0,-1
    80005d5a:	b7ed                	j	80005d44 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d5c:	8526                	mv	a0,s1
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	e78080e7          	jalr	-392(ra) # 80003bd6 <iunlockput>
    end_op();
    80005d66:	ffffe097          	auipc	ra,0xffffe
    80005d6a:	652080e7          	jalr	1618(ra) # 800043b8 <end_op>
    return -1;
    80005d6e:	557d                	li	a0,-1
    80005d70:	bfd1                	j	80005d44 <sys_chdir+0x7a>

0000000080005d72 <sys_exec>:

uint64
sys_exec(void)
{
    80005d72:	7145                	addi	sp,sp,-464
    80005d74:	e786                	sd	ra,456(sp)
    80005d76:	e3a2                	sd	s0,448(sp)
    80005d78:	ff26                	sd	s1,440(sp)
    80005d7a:	fb4a                	sd	s2,432(sp)
    80005d7c:	f74e                	sd	s3,424(sp)
    80005d7e:	f352                	sd	s4,416(sp)
    80005d80:	ef56                	sd	s5,408(sp)
    80005d82:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d84:	08000613          	li	a2,128
    80005d88:	f4040593          	addi	a1,s0,-192
    80005d8c:	4501                	li	a0,0
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	0a0080e7          	jalr	160(ra) # 80002e2e <argstr>
    return -1;
    80005d96:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d98:	0c054b63          	bltz	a0,80005e6e <sys_exec+0xfc>
    80005d9c:	e3840593          	addi	a1,s0,-456
    80005da0:	4505                	li	a0,1
    80005da2:	ffffd097          	auipc	ra,0xffffd
    80005da6:	06a080e7          	jalr	106(ra) # 80002e0c <argaddr>
    80005daa:	0c054263          	bltz	a0,80005e6e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005dae:	10000613          	li	a2,256
    80005db2:	4581                	li	a1,0
    80005db4:	e4040513          	addi	a0,s0,-448
    80005db8:	ffffb097          	auipc	ra,0xffffb
    80005dbc:	f44080e7          	jalr	-188(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dc0:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dc4:	89a6                	mv	s3,s1
    80005dc6:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dc8:	02000a13          	li	s4,32
    80005dcc:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dd0:	00391513          	slli	a0,s2,0x3
    80005dd4:	e3040593          	addi	a1,s0,-464
    80005dd8:	e3843783          	ld	a5,-456(s0)
    80005ddc:	953e                	add	a0,a0,a5
    80005dde:	ffffd097          	auipc	ra,0xffffd
    80005de2:	f72080e7          	jalr	-142(ra) # 80002d50 <fetchaddr>
    80005de6:	02054a63          	bltz	a0,80005e1a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005dea:	e3043783          	ld	a5,-464(s0)
    80005dee:	c3b9                	beqz	a5,80005e34 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005df0:	ffffb097          	auipc	ra,0xffffb
    80005df4:	d20080e7          	jalr	-736(ra) # 80000b10 <kalloc>
    80005df8:	85aa                	mv	a1,a0
    80005dfa:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005dfe:	cd11                	beqz	a0,80005e1a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e00:	6605                	lui	a2,0x1
    80005e02:	e3043503          	ld	a0,-464(s0)
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	f9c080e7          	jalr	-100(ra) # 80002da2 <fetchstr>
    80005e0e:	00054663          	bltz	a0,80005e1a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e12:	0905                	addi	s2,s2,1
    80005e14:	09a1                	addi	s3,s3,8
    80005e16:	fb491be3          	bne	s2,s4,80005dcc <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e1a:	f4040913          	addi	s2,s0,-192
    80005e1e:	6088                	ld	a0,0(s1)
    80005e20:	c531                	beqz	a0,80005e6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005e22:	ffffb097          	auipc	ra,0xffffb
    80005e26:	bf0080e7          	jalr	-1040(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e2a:	04a1                	addi	s1,s1,8
    80005e2c:	ff2499e3          	bne	s1,s2,80005e1e <sys_exec+0xac>
  return -1;
    80005e30:	597d                	li	s2,-1
    80005e32:	a835                	j	80005e6e <sys_exec+0xfc>
      argv[i] = 0;
    80005e34:	0a8e                	slli	s5,s5,0x3
    80005e36:	fc0a8793          	addi	a5,s5,-64
    80005e3a:	00878ab3          	add	s5,a5,s0
    80005e3e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e42:	e4040593          	addi	a1,s0,-448
    80005e46:	f4040513          	addi	a0,s0,-192
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	138080e7          	jalr	312(ra) # 80004f82 <exec>
    80005e52:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e54:	f4040993          	addi	s3,s0,-192
    80005e58:	6088                	ld	a0,0(s1)
    80005e5a:	c911                	beqz	a0,80005e6e <sys_exec+0xfc>
    kfree(argv[i]);
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	bb6080e7          	jalr	-1098(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e64:	04a1                	addi	s1,s1,8
    80005e66:	ff3499e3          	bne	s1,s3,80005e58 <sys_exec+0xe6>
    80005e6a:	a011                	j	80005e6e <sys_exec+0xfc>
  return -1;
    80005e6c:	597d                	li	s2,-1
}
    80005e6e:	854a                	mv	a0,s2
    80005e70:	60be                	ld	ra,456(sp)
    80005e72:	641e                	ld	s0,448(sp)
    80005e74:	74fa                	ld	s1,440(sp)
    80005e76:	795a                	ld	s2,432(sp)
    80005e78:	79ba                	ld	s3,424(sp)
    80005e7a:	7a1a                	ld	s4,416(sp)
    80005e7c:	6afa                	ld	s5,408(sp)
    80005e7e:	6179                	addi	sp,sp,464
    80005e80:	8082                	ret

0000000080005e82 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e82:	7139                	addi	sp,sp,-64
    80005e84:	fc06                	sd	ra,56(sp)
    80005e86:	f822                	sd	s0,48(sp)
    80005e88:	f426                	sd	s1,40(sp)
    80005e8a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e8c:	ffffc097          	auipc	ra,0xffffc
    80005e90:	d82080e7          	jalr	-638(ra) # 80001c0e <myproc>
    80005e94:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e96:	fd840593          	addi	a1,s0,-40
    80005e9a:	4501                	li	a0,0
    80005e9c:	ffffd097          	auipc	ra,0xffffd
    80005ea0:	f70080e7          	jalr	-144(ra) # 80002e0c <argaddr>
    return -1;
    80005ea4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ea6:	0e054063          	bltz	a0,80005f86 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005eaa:	fc840593          	addi	a1,s0,-56
    80005eae:	fd040513          	addi	a0,s0,-48
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	cac080e7          	jalr	-852(ra) # 80004b5e <pipealloc>
    return -1;
    80005eba:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ebc:	0c054563          	bltz	a0,80005f86 <sys_pipe+0x104>
  fd0 = -1;
    80005ec0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ec4:	fd043503          	ld	a0,-48(s0)
    80005ec8:	fffff097          	auipc	ra,0xfffff
    80005ecc:	504080e7          	jalr	1284(ra) # 800053cc <fdalloc>
    80005ed0:	fca42223          	sw	a0,-60(s0)
    80005ed4:	08054c63          	bltz	a0,80005f6c <sys_pipe+0xea>
    80005ed8:	fc843503          	ld	a0,-56(s0)
    80005edc:	fffff097          	auipc	ra,0xfffff
    80005ee0:	4f0080e7          	jalr	1264(ra) # 800053cc <fdalloc>
    80005ee4:	fca42023          	sw	a0,-64(s0)
    80005ee8:	06054963          	bltz	a0,80005f5a <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eec:	4691                	li	a3,4
    80005eee:	fc440613          	addi	a2,s0,-60
    80005ef2:	fd843583          	ld	a1,-40(s0)
    80005ef6:	68a8                	ld	a0,80(s1)
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	9dc080e7          	jalr	-1572(ra) # 800018d4 <copyout>
    80005f00:	02054063          	bltz	a0,80005f20 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f04:	4691                	li	a3,4
    80005f06:	fc040613          	addi	a2,s0,-64
    80005f0a:	fd843583          	ld	a1,-40(s0)
    80005f0e:	0591                	addi	a1,a1,4
    80005f10:	68a8                	ld	a0,80(s1)
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	9c2080e7          	jalr	-1598(ra) # 800018d4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f1a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f1c:	06055563          	bgez	a0,80005f86 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005f20:	fc442783          	lw	a5,-60(s0)
    80005f24:	07e9                	addi	a5,a5,26
    80005f26:	078e                	slli	a5,a5,0x3
    80005f28:	97a6                	add	a5,a5,s1
    80005f2a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f2e:	fc042783          	lw	a5,-64(s0)
    80005f32:	07e9                	addi	a5,a5,26
    80005f34:	078e                	slli	a5,a5,0x3
    80005f36:	00f48533          	add	a0,s1,a5
    80005f3a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005f3e:	fd043503          	ld	a0,-48(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	8c6080e7          	jalr	-1850(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005f4a:	fc843503          	ld	a0,-56(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	8ba080e7          	jalr	-1862(ra) # 80004808 <fileclose>
    return -1;
    80005f56:	57fd                	li	a5,-1
    80005f58:	a03d                	j	80005f86 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005f5a:	fc442783          	lw	a5,-60(s0)
    80005f5e:	0007c763          	bltz	a5,80005f6c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005f62:	07e9                	addi	a5,a5,26
    80005f64:	078e                	slli	a5,a5,0x3
    80005f66:	97a6                	add	a5,a5,s1
    80005f68:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005f6c:	fd043503          	ld	a0,-48(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	898080e7          	jalr	-1896(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005f78:	fc843503          	ld	a0,-56(s0)
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	88c080e7          	jalr	-1908(ra) # 80004808 <fileclose>
    return -1;
    80005f84:	57fd                	li	a5,-1
}
    80005f86:	853e                	mv	a0,a5
    80005f88:	70e2                	ld	ra,56(sp)
    80005f8a:	7442                	ld	s0,48(sp)
    80005f8c:	74a2                	ld	s1,40(sp)
    80005f8e:	6121                	addi	sp,sp,64
    80005f90:	8082                	ret
	...

0000000080005fa0 <kernelvec>:
    80005fa0:	7111                	addi	sp,sp,-256
    80005fa2:	e006                	sd	ra,0(sp)
    80005fa4:	e40a                	sd	sp,8(sp)
    80005fa6:	e80e                	sd	gp,16(sp)
    80005fa8:	ec12                	sd	tp,24(sp)
    80005faa:	f016                	sd	t0,32(sp)
    80005fac:	f41a                	sd	t1,40(sp)
    80005fae:	f81e                	sd	t2,48(sp)
    80005fb0:	fc22                	sd	s0,56(sp)
    80005fb2:	e0a6                	sd	s1,64(sp)
    80005fb4:	e4aa                	sd	a0,72(sp)
    80005fb6:	e8ae                	sd	a1,80(sp)
    80005fb8:	ecb2                	sd	a2,88(sp)
    80005fba:	f0b6                	sd	a3,96(sp)
    80005fbc:	f4ba                	sd	a4,104(sp)
    80005fbe:	f8be                	sd	a5,112(sp)
    80005fc0:	fcc2                	sd	a6,120(sp)
    80005fc2:	e146                	sd	a7,128(sp)
    80005fc4:	e54a                	sd	s2,136(sp)
    80005fc6:	e94e                	sd	s3,144(sp)
    80005fc8:	ed52                	sd	s4,152(sp)
    80005fca:	f156                	sd	s5,160(sp)
    80005fcc:	f55a                	sd	s6,168(sp)
    80005fce:	f95e                	sd	s7,176(sp)
    80005fd0:	fd62                	sd	s8,184(sp)
    80005fd2:	e1e6                	sd	s9,192(sp)
    80005fd4:	e5ea                	sd	s10,200(sp)
    80005fd6:	e9ee                	sd	s11,208(sp)
    80005fd8:	edf2                	sd	t3,216(sp)
    80005fda:	f1f6                	sd	t4,224(sp)
    80005fdc:	f5fa                	sd	t5,232(sp)
    80005fde:	f9fe                	sd	t6,240(sp)
    80005fe0:	c3dfc0ef          	jal	ra,80002c1c <kerneltrap>
    80005fe4:	6082                	ld	ra,0(sp)
    80005fe6:	6122                	ld	sp,8(sp)
    80005fe8:	61c2                	ld	gp,16(sp)
    80005fea:	7282                	ld	t0,32(sp)
    80005fec:	7322                	ld	t1,40(sp)
    80005fee:	73c2                	ld	t2,48(sp)
    80005ff0:	7462                	ld	s0,56(sp)
    80005ff2:	6486                	ld	s1,64(sp)
    80005ff4:	6526                	ld	a0,72(sp)
    80005ff6:	65c6                	ld	a1,80(sp)
    80005ff8:	6666                	ld	a2,88(sp)
    80005ffa:	7686                	ld	a3,96(sp)
    80005ffc:	7726                	ld	a4,104(sp)
    80005ffe:	77c6                	ld	a5,112(sp)
    80006000:	7866                	ld	a6,120(sp)
    80006002:	688a                	ld	a7,128(sp)
    80006004:	692a                	ld	s2,136(sp)
    80006006:	69ca                	ld	s3,144(sp)
    80006008:	6a6a                	ld	s4,152(sp)
    8000600a:	7a8a                	ld	s5,160(sp)
    8000600c:	7b2a                	ld	s6,168(sp)
    8000600e:	7bca                	ld	s7,176(sp)
    80006010:	7c6a                	ld	s8,184(sp)
    80006012:	6c8e                	ld	s9,192(sp)
    80006014:	6d2e                	ld	s10,200(sp)
    80006016:	6dce                	ld	s11,208(sp)
    80006018:	6e6e                	ld	t3,216(sp)
    8000601a:	7e8e                	ld	t4,224(sp)
    8000601c:	7f2e                	ld	t5,232(sp)
    8000601e:	7fce                	ld	t6,240(sp)
    80006020:	6111                	addi	sp,sp,256
    80006022:	10200073          	sret
    80006026:	00000013          	nop
    8000602a:	00000013          	nop
    8000602e:	0001                	nop

0000000080006030 <timervec>:
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	e10c                	sd	a1,0(a0)
    80006036:	e510                	sd	a2,8(a0)
    80006038:	e914                	sd	a3,16(a0)
    8000603a:	710c                	ld	a1,32(a0)
    8000603c:	7510                	ld	a2,40(a0)
    8000603e:	6194                	ld	a3,0(a1)
    80006040:	96b2                	add	a3,a3,a2
    80006042:	e194                	sd	a3,0(a1)
    80006044:	4589                	li	a1,2
    80006046:	14459073          	csrw	sip,a1
    8000604a:	6914                	ld	a3,16(a0)
    8000604c:	6510                	ld	a2,8(a0)
    8000604e:	610c                	ld	a1,0(a0)
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	30200073          	mret
	...

000000008000605a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000605a:	1141                	addi	sp,sp,-16
    8000605c:	e422                	sd	s0,8(sp)
    8000605e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006060:	0c0007b7          	lui	a5,0xc000
    80006064:	4705                	li	a4,1
    80006066:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006068:	c3d8                	sw	a4,4(a5)
}
    8000606a:	6422                	ld	s0,8(sp)
    8000606c:	0141                	addi	sp,sp,16
    8000606e:	8082                	ret

0000000080006070 <plicinithart>:

void
plicinithart(void)
{
    80006070:	1141                	addi	sp,sp,-16
    80006072:	e406                	sd	ra,8(sp)
    80006074:	e022                	sd	s0,0(sp)
    80006076:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	b6a080e7          	jalr	-1174(ra) # 80001be2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006080:	0085171b          	slliw	a4,a0,0x8
    80006084:	0c0027b7          	lui	a5,0xc002
    80006088:	97ba                	add	a5,a5,a4
    8000608a:	40200713          	li	a4,1026
    8000608e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006092:	00d5151b          	slliw	a0,a0,0xd
    80006096:	0c2017b7          	lui	a5,0xc201
    8000609a:	97aa                	add	a5,a5,a0
    8000609c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800060a0:	60a2                	ld	ra,8(sp)
    800060a2:	6402                	ld	s0,0(sp)
    800060a4:	0141                	addi	sp,sp,16
    800060a6:	8082                	ret

00000000800060a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060a8:	1141                	addi	sp,sp,-16
    800060aa:	e406                	sd	ra,8(sp)
    800060ac:	e022                	sd	s0,0(sp)
    800060ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	b32080e7          	jalr	-1230(ra) # 80001be2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060b8:	00d5151b          	slliw	a0,a0,0xd
    800060bc:	0c2017b7          	lui	a5,0xc201
    800060c0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060c2:	43c8                	lw	a0,4(a5)
    800060c4:	60a2                	ld	ra,8(sp)
    800060c6:	6402                	ld	s0,0(sp)
    800060c8:	0141                	addi	sp,sp,16
    800060ca:	8082                	ret

00000000800060cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060cc:	1101                	addi	sp,sp,-32
    800060ce:	ec06                	sd	ra,24(sp)
    800060d0:	e822                	sd	s0,16(sp)
    800060d2:	e426                	sd	s1,8(sp)
    800060d4:	1000                	addi	s0,sp,32
    800060d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	b0a080e7          	jalr	-1270(ra) # 80001be2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060e0:	00d5151b          	slliw	a0,a0,0xd
    800060e4:	0c2017b7          	lui	a5,0xc201
    800060e8:	97aa                	add	a5,a5,a0
    800060ea:	c3c4                	sw	s1,4(a5)
}
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	64a2                	ld	s1,8(sp)
    800060f2:	6105                	addi	sp,sp,32
    800060f4:	8082                	ret

00000000800060f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060f6:	1141                	addi	sp,sp,-16
    800060f8:	e406                	sd	ra,8(sp)
    800060fa:	e022                	sd	s0,0(sp)
    800060fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060fe:	479d                	li	a5,7
    80006100:	04a7cb63          	blt	a5,a0,80006156 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006104:	0001d717          	auipc	a4,0x1d
    80006108:	efc70713          	addi	a4,a4,-260 # 80023000 <disk>
    8000610c:	972a                	add	a4,a4,a0
    8000610e:	6789                	lui	a5,0x2
    80006110:	97ba                	add	a5,a5,a4
    80006112:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006116:	eba1                	bnez	a5,80006166 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80006118:	00451713          	slli	a4,a0,0x4
    8000611c:	0001f797          	auipc	a5,0x1f
    80006120:	ee47b783          	ld	a5,-284(a5) # 80025000 <disk+0x2000>
    80006124:	97ba                	add	a5,a5,a4
    80006126:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000612a:	0001d717          	auipc	a4,0x1d
    8000612e:	ed670713          	addi	a4,a4,-298 # 80023000 <disk>
    80006132:	972a                	add	a4,a4,a0
    80006134:	6789                	lui	a5,0x2
    80006136:	97ba                	add	a5,a5,a4
    80006138:	4705                	li	a4,1
    8000613a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000613e:	0001f517          	auipc	a0,0x1f
    80006142:	eda50513          	addi	a0,a0,-294 # 80025018 <disk+0x2018>
    80006146:	ffffc097          	auipc	ra,0xffffc
    8000614a:	57c080e7          	jalr	1404(ra) # 800026c2 <wakeup>
}
    8000614e:	60a2                	ld	ra,8(sp)
    80006150:	6402                	ld	s0,0(sp)
    80006152:	0141                	addi	sp,sp,16
    80006154:	8082                	ret
    panic("virtio_disk_intr 1");
    80006156:	00002517          	auipc	a0,0x2
    8000615a:	6aa50513          	addi	a0,a0,1706 # 80008800 <syscalls+0x398>
    8000615e:	ffffa097          	auipc	ra,0xffffa
    80006162:	3e8080e7          	jalr	1000(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80006166:	00002517          	auipc	a0,0x2
    8000616a:	6b250513          	addi	a0,a0,1714 # 80008818 <syscalls+0x3b0>
    8000616e:	ffffa097          	auipc	ra,0xffffa
    80006172:	3d8080e7          	jalr	984(ra) # 80000546 <panic>

0000000080006176 <virtio_disk_init>:
{
    80006176:	1101                	addi	sp,sp,-32
    80006178:	ec06                	sd	ra,24(sp)
    8000617a:	e822                	sd	s0,16(sp)
    8000617c:	e426                	sd	s1,8(sp)
    8000617e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006180:	00002597          	auipc	a1,0x2
    80006184:	6b058593          	addi	a1,a1,1712 # 80008830 <syscalls+0x3c8>
    80006188:	0001f517          	auipc	a0,0x1f
    8000618c:	f2050513          	addi	a0,a0,-224 # 800250a8 <disk+0x20a8>
    80006190:	ffffb097          	auipc	ra,0xffffb
    80006194:	9e0080e7          	jalr	-1568(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006198:	100017b7          	lui	a5,0x10001
    8000619c:	4398                	lw	a4,0(a5)
    8000619e:	2701                	sext.w	a4,a4
    800061a0:	747277b7          	lui	a5,0x74727
    800061a4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061a8:	0ef71063          	bne	a4,a5,80006288 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061ac:	100017b7          	lui	a5,0x10001
    800061b0:	43dc                	lw	a5,4(a5)
    800061b2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b4:	4705                	li	a4,1
    800061b6:	0ce79963          	bne	a5,a4,80006288 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061ba:	100017b7          	lui	a5,0x10001
    800061be:	479c                	lw	a5,8(a5)
    800061c0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061c2:	4709                	li	a4,2
    800061c4:	0ce79263          	bne	a5,a4,80006288 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061c8:	100017b7          	lui	a5,0x10001
    800061cc:	47d8                	lw	a4,12(a5)
    800061ce:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061d0:	554d47b7          	lui	a5,0x554d4
    800061d4:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061d8:	0af71863          	bne	a4,a5,80006288 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061dc:	100017b7          	lui	a5,0x10001
    800061e0:	4705                	li	a4,1
    800061e2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e4:	470d                	li	a4,3
    800061e6:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061e8:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061ea:	c7ffe6b7          	lui	a3,0xc7ffe
    800061ee:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800061f2:	8f75                	and	a4,a4,a3
    800061f4:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f6:	472d                	li	a4,11
    800061f8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061fa:	473d                	li	a4,15
    800061fc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061fe:	6705                	lui	a4,0x1
    80006200:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006202:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006206:	5bdc                	lw	a5,52(a5)
    80006208:	2781                	sext.w	a5,a5
  if(max == 0)
    8000620a:	c7d9                	beqz	a5,80006298 <virtio_disk_init+0x122>
  if(max < NUM)
    8000620c:	471d                	li	a4,7
    8000620e:	08f77d63          	bgeu	a4,a5,800062a8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006212:	100014b7          	lui	s1,0x10001
    80006216:	47a1                	li	a5,8
    80006218:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000621a:	6609                	lui	a2,0x2
    8000621c:	4581                	li	a1,0
    8000621e:	0001d517          	auipc	a0,0x1d
    80006222:	de250513          	addi	a0,a0,-542 # 80023000 <disk>
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	ad6080e7          	jalr	-1322(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000622e:	0001d717          	auipc	a4,0x1d
    80006232:	dd270713          	addi	a4,a4,-558 # 80023000 <disk>
    80006236:	00c75793          	srli	a5,a4,0xc
    8000623a:	2781                	sext.w	a5,a5
    8000623c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    8000623e:	0001f797          	auipc	a5,0x1f
    80006242:	dc278793          	addi	a5,a5,-574 # 80025000 <disk+0x2000>
    80006246:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80006248:	0001d717          	auipc	a4,0x1d
    8000624c:	e3870713          	addi	a4,a4,-456 # 80023080 <disk+0x80>
    80006250:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006252:	0001e717          	auipc	a4,0x1e
    80006256:	dae70713          	addi	a4,a4,-594 # 80024000 <disk+0x1000>
    8000625a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000625c:	4705                	li	a4,1
    8000625e:	00e78c23          	sb	a4,24(a5)
    80006262:	00e78ca3          	sb	a4,25(a5)
    80006266:	00e78d23          	sb	a4,26(a5)
    8000626a:	00e78da3          	sb	a4,27(a5)
    8000626e:	00e78e23          	sb	a4,28(a5)
    80006272:	00e78ea3          	sb	a4,29(a5)
    80006276:	00e78f23          	sb	a4,30(a5)
    8000627a:	00e78fa3          	sb	a4,31(a5)
}
    8000627e:	60e2                	ld	ra,24(sp)
    80006280:	6442                	ld	s0,16(sp)
    80006282:	64a2                	ld	s1,8(sp)
    80006284:	6105                	addi	sp,sp,32
    80006286:	8082                	ret
    panic("could not find virtio disk");
    80006288:	00002517          	auipc	a0,0x2
    8000628c:	5b850513          	addi	a0,a0,1464 # 80008840 <syscalls+0x3d8>
    80006290:	ffffa097          	auipc	ra,0xffffa
    80006294:	2b6080e7          	jalr	694(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80006298:	00002517          	auipc	a0,0x2
    8000629c:	5c850513          	addi	a0,a0,1480 # 80008860 <syscalls+0x3f8>
    800062a0:	ffffa097          	auipc	ra,0xffffa
    800062a4:	2a6080e7          	jalr	678(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    800062a8:	00002517          	auipc	a0,0x2
    800062ac:	5d850513          	addi	a0,a0,1496 # 80008880 <syscalls+0x418>
    800062b0:	ffffa097          	auipc	ra,0xffffa
    800062b4:	296080e7          	jalr	662(ra) # 80000546 <panic>

00000000800062b8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062b8:	7175                	addi	sp,sp,-144
    800062ba:	e506                	sd	ra,136(sp)
    800062bc:	e122                	sd	s0,128(sp)
    800062be:	fca6                	sd	s1,120(sp)
    800062c0:	f8ca                	sd	s2,112(sp)
    800062c2:	f4ce                	sd	s3,104(sp)
    800062c4:	f0d2                	sd	s4,96(sp)
    800062c6:	ecd6                	sd	s5,88(sp)
    800062c8:	e8da                	sd	s6,80(sp)
    800062ca:	e4de                	sd	s7,72(sp)
    800062cc:	e0e2                	sd	s8,64(sp)
    800062ce:	fc66                	sd	s9,56(sp)
    800062d0:	f86a                	sd	s10,48(sp)
    800062d2:	f46e                	sd	s11,40(sp)
    800062d4:	0900                	addi	s0,sp,144
    800062d6:	8aaa                	mv	s5,a0
    800062d8:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062da:	00c52c83          	lw	s9,12(a0)
    800062de:	001c9c9b          	slliw	s9,s9,0x1
    800062e2:	1c82                	slli	s9,s9,0x20
    800062e4:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062e8:	0001f517          	auipc	a0,0x1f
    800062ec:	dc050513          	addi	a0,a0,-576 # 800250a8 <disk+0x20a8>
    800062f0:	ffffb097          	auipc	ra,0xffffb
    800062f4:	910080e7          	jalr	-1776(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    800062f8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062fa:	44a1                	li	s1,8
      disk.free[i] = 0;
    800062fc:	0001dc17          	auipc	s8,0x1d
    80006300:	d04c0c13          	addi	s8,s8,-764 # 80023000 <disk>
    80006304:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006306:	4b0d                	li	s6,3
    80006308:	a0ad                	j	80006372 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000630a:	00fc0733          	add	a4,s8,a5
    8000630e:	975e                	add	a4,a4,s7
    80006310:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006314:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006316:	0207c563          	bltz	a5,80006340 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000631a:	2905                	addiw	s2,s2,1
    8000631c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    8000631e:	19690c63          	beq	s2,s6,800064b6 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80006322:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006324:	0001f717          	auipc	a4,0x1f
    80006328:	cf470713          	addi	a4,a4,-780 # 80025018 <disk+0x2018>
    8000632c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000632e:	00074683          	lbu	a3,0(a4)
    80006332:	fee1                	bnez	a3,8000630a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006334:	2785                	addiw	a5,a5,1
    80006336:	0705                	addi	a4,a4,1
    80006338:	fe979be3          	bne	a5,s1,8000632e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000633c:	57fd                	li	a5,-1
    8000633e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006340:	01205d63          	blez	s2,8000635a <virtio_disk_rw+0xa2>
    80006344:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006346:	000a2503          	lw	a0,0(s4)
    8000634a:	00000097          	auipc	ra,0x0
    8000634e:	dac080e7          	jalr	-596(ra) # 800060f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006352:	2d85                	addiw	s11,s11,1 # 1001 <_entry-0x7fffefff>
    80006354:	0a11                	addi	s4,s4,4
    80006356:	ff2d98e3          	bne	s11,s2,80006346 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000635a:	0001f597          	auipc	a1,0x1f
    8000635e:	d4e58593          	addi	a1,a1,-690 # 800250a8 <disk+0x20a8>
    80006362:	0001f517          	auipc	a0,0x1f
    80006366:	cb650513          	addi	a0,a0,-842 # 80025018 <disk+0x2018>
    8000636a:	ffffc097          	auipc	ra,0xffffc
    8000636e:	1d8080e7          	jalr	472(ra) # 80002542 <sleep>
  for(int i = 0; i < 3; i++){
    80006372:	f8040a13          	addi	s4,s0,-128
{
    80006376:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006378:	894e                	mv	s2,s3
    8000637a:	b765                	j	80006322 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000637c:	0001f717          	auipc	a4,0x1f
    80006380:	c8473703          	ld	a4,-892(a4) # 80025000 <disk+0x2000>
    80006384:	973e                	add	a4,a4,a5
    80006386:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000638a:	0001d517          	auipc	a0,0x1d
    8000638e:	c7650513          	addi	a0,a0,-906 # 80023000 <disk>
    80006392:	0001f717          	auipc	a4,0x1f
    80006396:	c6e70713          	addi	a4,a4,-914 # 80025000 <disk+0x2000>
    8000639a:	6314                	ld	a3,0(a4)
    8000639c:	96be                	add	a3,a3,a5
    8000639e:	00c6d603          	lhu	a2,12(a3)
    800063a2:	00166613          	ori	a2,a2,1
    800063a6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063aa:	f8842683          	lw	a3,-120(s0)
    800063ae:	6310                	ld	a2,0(a4)
    800063b0:	97b2                	add	a5,a5,a2
    800063b2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    800063b6:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    800063ba:	0612                	slli	a2,a2,0x4
    800063bc:	962a                	add	a2,a2,a0
    800063be:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063c2:	00469793          	slli	a5,a3,0x4
    800063c6:	630c                	ld	a1,0(a4)
    800063c8:	95be                	add	a1,a1,a5
    800063ca:	6689                	lui	a3,0x2
    800063cc:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800063d0:	96ca                	add	a3,a3,s2
    800063d2:	96aa                	add	a3,a3,a0
    800063d4:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800063d6:	6314                	ld	a3,0(a4)
    800063d8:	96be                	add	a3,a3,a5
    800063da:	4585                	li	a1,1
    800063dc:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063de:	6314                	ld	a3,0(a4)
    800063e0:	96be                	add	a3,a3,a5
    800063e2:	4509                	li	a0,2
    800063e4:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800063e8:	6314                	ld	a3,0(a4)
    800063ea:	97b6                	add	a5,a5,a3
    800063ec:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063f0:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800063f4:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800063f8:	6714                	ld	a3,8(a4)
    800063fa:	0026d783          	lhu	a5,2(a3)
    800063fe:	8b9d                	andi	a5,a5,7
    80006400:	0789                	addi	a5,a5,2
    80006402:	0786                	slli	a5,a5,0x1
    80006404:	96be                	add	a3,a3,a5
    80006406:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000640a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000640e:	6718                	ld	a4,8(a4)
    80006410:	00275783          	lhu	a5,2(a4)
    80006414:	2785                	addiw	a5,a5,1
    80006416:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000641a:	100017b7          	lui	a5,0x10001
    8000641e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006422:	004aa783          	lw	a5,4(s5)
    80006426:	02b79163          	bne	a5,a1,80006448 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000642a:	0001f917          	auipc	s2,0x1f
    8000642e:	c7e90913          	addi	s2,s2,-898 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006432:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006434:	85ca                	mv	a1,s2
    80006436:	8556                	mv	a0,s5
    80006438:	ffffc097          	auipc	ra,0xffffc
    8000643c:	10a080e7          	jalr	266(ra) # 80002542 <sleep>
  while(b->disk == 1) {
    80006440:	004aa783          	lw	a5,4(s5)
    80006444:	fe9788e3          	beq	a5,s1,80006434 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006448:	f8042483          	lw	s1,-128(s0)
    8000644c:	20048713          	addi	a4,s1,512
    80006450:	0712                	slli	a4,a4,0x4
    80006452:	0001d797          	auipc	a5,0x1d
    80006456:	bae78793          	addi	a5,a5,-1106 # 80023000 <disk>
    8000645a:	97ba                	add	a5,a5,a4
    8000645c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006460:	0001f917          	auipc	s2,0x1f
    80006464:	ba090913          	addi	s2,s2,-1120 # 80025000 <disk+0x2000>
    80006468:	a019                	j	8000646e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000646a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000646e:	8526                	mv	a0,s1
    80006470:	00000097          	auipc	ra,0x0
    80006474:	c86080e7          	jalr	-890(ra) # 800060f6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006478:	0492                	slli	s1,s1,0x4
    8000647a:	00093783          	ld	a5,0(s2)
    8000647e:	97a6                	add	a5,a5,s1
    80006480:	00c7d703          	lhu	a4,12(a5)
    80006484:	8b05                	andi	a4,a4,1
    80006486:	f375                	bnez	a4,8000646a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006488:	0001f517          	auipc	a0,0x1f
    8000648c:	c2050513          	addi	a0,a0,-992 # 800250a8 <disk+0x20a8>
    80006490:	ffffb097          	auipc	ra,0xffffb
    80006494:	824080e7          	jalr	-2012(ra) # 80000cb4 <release>
}
    80006498:	60aa                	ld	ra,136(sp)
    8000649a:	640a                	ld	s0,128(sp)
    8000649c:	74e6                	ld	s1,120(sp)
    8000649e:	7946                	ld	s2,112(sp)
    800064a0:	79a6                	ld	s3,104(sp)
    800064a2:	7a06                	ld	s4,96(sp)
    800064a4:	6ae6                	ld	s5,88(sp)
    800064a6:	6b46                	ld	s6,80(sp)
    800064a8:	6ba6                	ld	s7,72(sp)
    800064aa:	6c06                	ld	s8,64(sp)
    800064ac:	7ce2                	ld	s9,56(sp)
    800064ae:	7d42                	ld	s10,48(sp)
    800064b0:	7da2                	ld	s11,40(sp)
    800064b2:	6149                	addi	sp,sp,144
    800064b4:	8082                	ret
  if(write)
    800064b6:	01a037b3          	snez	a5,s10
    800064ba:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800064be:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800064c2:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800064c6:	f8042483          	lw	s1,-128(s0)
    800064ca:	00449913          	slli	s2,s1,0x4
    800064ce:	0001f997          	auipc	s3,0x1f
    800064d2:	b3298993          	addi	s3,s3,-1230 # 80025000 <disk+0x2000>
    800064d6:	0009ba03          	ld	s4,0(s3)
    800064da:	9a4a                	add	s4,s4,s2
    800064dc:	f7040513          	addi	a0,s0,-144
    800064e0:	ffffb097          	auipc	ra,0xffffb
    800064e4:	bf4080e7          	jalr	-1036(ra) # 800010d4 <kvmpa>
    800064e8:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800064ec:	0009b783          	ld	a5,0(s3)
    800064f0:	97ca                	add	a5,a5,s2
    800064f2:	4741                	li	a4,16
    800064f4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064f6:	0009b783          	ld	a5,0(s3)
    800064fa:	97ca                	add	a5,a5,s2
    800064fc:	4705                	li	a4,1
    800064fe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006502:	f8442783          	lw	a5,-124(s0)
    80006506:	0009b703          	ld	a4,0(s3)
    8000650a:	974a                	add	a4,a4,s2
    8000650c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006510:	0792                	slli	a5,a5,0x4
    80006512:	0009b703          	ld	a4,0(s3)
    80006516:	973e                	add	a4,a4,a5
    80006518:	058a8693          	addi	a3,s5,88
    8000651c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000651e:	0009b703          	ld	a4,0(s3)
    80006522:	973e                	add	a4,a4,a5
    80006524:	40000693          	li	a3,1024
    80006528:	c714                	sw	a3,8(a4)
  if(write)
    8000652a:	e40d19e3          	bnez	s10,8000637c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000652e:	0001f717          	auipc	a4,0x1f
    80006532:	ad273703          	ld	a4,-1326(a4) # 80025000 <disk+0x2000>
    80006536:	973e                	add	a4,a4,a5
    80006538:	4689                	li	a3,2
    8000653a:	00d71623          	sh	a3,12(a4)
    8000653e:	b5b1                	j	8000638a <virtio_disk_rw+0xd2>

0000000080006540 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006540:	1101                	addi	sp,sp,-32
    80006542:	ec06                	sd	ra,24(sp)
    80006544:	e822                	sd	s0,16(sp)
    80006546:	e426                	sd	s1,8(sp)
    80006548:	e04a                	sd	s2,0(sp)
    8000654a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000654c:	0001f517          	auipc	a0,0x1f
    80006550:	b5c50513          	addi	a0,a0,-1188 # 800250a8 <disk+0x20a8>
    80006554:	ffffa097          	auipc	ra,0xffffa
    80006558:	6ac080e7          	jalr	1708(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000655c:	0001f717          	auipc	a4,0x1f
    80006560:	aa470713          	addi	a4,a4,-1372 # 80025000 <disk+0x2000>
    80006564:	02075783          	lhu	a5,32(a4)
    80006568:	6b18                	ld	a4,16(a4)
    8000656a:	00275683          	lhu	a3,2(a4)
    8000656e:	8ebd                	xor	a3,a3,a5
    80006570:	8a9d                	andi	a3,a3,7
    80006572:	cab9                	beqz	a3,800065c8 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006574:	0001d917          	auipc	s2,0x1d
    80006578:	a8c90913          	addi	s2,s2,-1396 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000657c:	0001f497          	auipc	s1,0x1f
    80006580:	a8448493          	addi	s1,s1,-1404 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006584:	078e                	slli	a5,a5,0x3
    80006586:	973e                	add	a4,a4,a5
    80006588:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    8000658a:	20078713          	addi	a4,a5,512
    8000658e:	0712                	slli	a4,a4,0x4
    80006590:	974a                	add	a4,a4,s2
    80006592:	03074703          	lbu	a4,48(a4)
    80006596:	ef21                	bnez	a4,800065ee <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006598:	20078793          	addi	a5,a5,512
    8000659c:	0792                	slli	a5,a5,0x4
    8000659e:	97ca                	add	a5,a5,s2
    800065a0:	7798                	ld	a4,40(a5)
    800065a2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800065a6:	7788                	ld	a0,40(a5)
    800065a8:	ffffc097          	auipc	ra,0xffffc
    800065ac:	11a080e7          	jalr	282(ra) # 800026c2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800065b0:	0204d783          	lhu	a5,32(s1)
    800065b4:	2785                	addiw	a5,a5,1
    800065b6:	8b9d                	andi	a5,a5,7
    800065b8:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800065bc:	6898                	ld	a4,16(s1)
    800065be:	00275683          	lhu	a3,2(a4)
    800065c2:	8a9d                	andi	a3,a3,7
    800065c4:	fcf690e3          	bne	a3,a5,80006584 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065c8:	10001737          	lui	a4,0x10001
    800065cc:	533c                	lw	a5,96(a4)
    800065ce:	8b8d                	andi	a5,a5,3
    800065d0:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800065d2:	0001f517          	auipc	a0,0x1f
    800065d6:	ad650513          	addi	a0,a0,-1322 # 800250a8 <disk+0x20a8>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	6da080e7          	jalr	1754(ra) # 80000cb4 <release>
}
    800065e2:	60e2                	ld	ra,24(sp)
    800065e4:	6442                	ld	s0,16(sp)
    800065e6:	64a2                	ld	s1,8(sp)
    800065e8:	6902                	ld	s2,0(sp)
    800065ea:	6105                	addi	sp,sp,32
    800065ec:	8082                	ret
      panic("virtio_disk_intr status");
    800065ee:	00002517          	auipc	a0,0x2
    800065f2:	2b250513          	addi	a0,a0,690 # 800088a0 <syscalls+0x438>
    800065f6:	ffffa097          	auipc	ra,0xffffa
    800065fa:	f50080e7          	jalr	-176(ra) # 80000546 <panic>

00000000800065fe <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800065fe:	7179                	addi	sp,sp,-48
    80006600:	f406                	sd	ra,40(sp)
    80006602:	f022                	sd	s0,32(sp)
    80006604:	ec26                	sd	s1,24(sp)
    80006606:	e84a                	sd	s2,16(sp)
    80006608:	e44e                	sd	s3,8(sp)
    8000660a:	e052                	sd	s4,0(sp)
    8000660c:	1800                	addi	s0,sp,48
    8000660e:	892a                	mv	s2,a0
    80006610:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006612:	00003a17          	auipc	s4,0x3
    80006616:	a16a0a13          	addi	s4,s4,-1514 # 80009028 <stats>
    8000661a:	000a2683          	lw	a3,0(s4)
    8000661e:	00002617          	auipc	a2,0x2
    80006622:	29a60613          	addi	a2,a2,666 # 800088b8 <syscalls+0x450>
    80006626:	00000097          	auipc	ra,0x0
    8000662a:	2ee080e7          	jalr	750(ra) # 80006914 <snprintf>
    8000662e:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006630:	004a2683          	lw	a3,4(s4)
    80006634:	00002617          	auipc	a2,0x2
    80006638:	29460613          	addi	a2,a2,660 # 800088c8 <syscalls+0x460>
    8000663c:	85ce                	mv	a1,s3
    8000663e:	954a                	add	a0,a0,s2
    80006640:	00000097          	auipc	ra,0x0
    80006644:	2d4080e7          	jalr	724(ra) # 80006914 <snprintf>
  return n;
}
    80006648:	9d25                	addw	a0,a0,s1
    8000664a:	70a2                	ld	ra,40(sp)
    8000664c:	7402                	ld	s0,32(sp)
    8000664e:	64e2                	ld	s1,24(sp)
    80006650:	6942                	ld	s2,16(sp)
    80006652:	69a2                	ld	s3,8(sp)
    80006654:	6a02                	ld	s4,0(sp)
    80006656:	6145                	addi	sp,sp,48
    80006658:	8082                	ret

000000008000665a <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000665a:	7179                	addi	sp,sp,-48
    8000665c:	f406                	sd	ra,40(sp)
    8000665e:	f022                	sd	s0,32(sp)
    80006660:	ec26                	sd	s1,24(sp)
    80006662:	e84a                	sd	s2,16(sp)
    80006664:	e44e                	sd	s3,8(sp)
    80006666:	1800                	addi	s0,sp,48
    80006668:	89ae                	mv	s3,a1
    8000666a:	84b2                	mv	s1,a2
    8000666c:	8936                	mv	s2,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000666e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SPP);
    80006672:	1007e793          	ori	a5,a5,256
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80006676:	10079073          	csrw	sstatus,a5
  struct proc *p = myproc();
    8000667a:	ffffb097          	auipc	ra,0xffffb
    8000667e:	594080e7          	jalr	1428(ra) # 80001c0e <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    80006682:	653c                	ld	a5,72(a0)
    80006684:	04f4f563          	bgeu	s1,a5,800066ce <copyin_new+0x74>
    80006688:	01248733          	add	a4,s1,s2
    8000668c:	04f77363          	bgeu	a4,a5,800066d2 <copyin_new+0x78>
    80006690:	04976363          	bltu	a4,s1,800066d6 <copyin_new+0x7c>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    80006694:	0009061b          	sext.w	a2,s2
    80006698:	85a6                	mv	a1,s1
    8000669a:	854e                	mv	a0,s3
    8000669c:	ffffa097          	auipc	ra,0xffffa
    800066a0:	6bc080e7          	jalr	1724(ra) # 80000d58 <memmove>
  stats.ncopyin++;   // XXX lock
    800066a4:	00003717          	auipc	a4,0x3
    800066a8:	98470713          	addi	a4,a4,-1660 # 80009028 <stats>
    800066ac:	431c                	lw	a5,0(a4)
    800066ae:	2785                	addiw	a5,a5,1
    800066b0:	c31c                	sw	a5,0(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800066b2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SPP);
    800066b6:	eff7f793          	andi	a5,a5,-257
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800066ba:	10079073          	csrw	sstatus,a5
  return 0;
    800066be:	4501                	li	a0,0
}
    800066c0:	70a2                	ld	ra,40(sp)
    800066c2:	7402                	ld	s0,32(sp)
    800066c4:	64e2                	ld	s1,24(sp)
    800066c6:	6942                	ld	s2,16(sp)
    800066c8:	69a2                	ld	s3,8(sp)
    800066ca:	6145                	addi	sp,sp,48
    800066cc:	8082                	ret
    return -1;
    800066ce:	557d                	li	a0,-1
    800066d0:	bfc5                	j	800066c0 <copyin_new+0x66>
    800066d2:	557d                	li	a0,-1
    800066d4:	b7f5                	j	800066c0 <copyin_new+0x66>
    800066d6:	557d                	li	a0,-1
    800066d8:	b7e5                	j	800066c0 <copyin_new+0x66>

00000000800066da <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800066da:	7179                	addi	sp,sp,-48
    800066dc:	f406                	sd	ra,40(sp)
    800066de:	f022                	sd	s0,32(sp)
    800066e0:	ec26                	sd	s1,24(sp)
    800066e2:	e84a                	sd	s2,16(sp)
    800066e4:	e44e                	sd	s3,8(sp)
    800066e6:	1800                	addi	s0,sp,48
    800066e8:	89ae                	mv	s3,a1
    800066ea:	8932                	mv	s2,a2
    800066ec:	84b6                	mv	s1,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800066ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SPP);
    800066f2:	1007e793          	ori	a5,a5,256
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800066f6:	10079073          	csrw	sstatus,a5
  struct proc *p = myproc();
    800066fa:	ffffb097          	auipc	ra,0xffffb
    800066fe:	514080e7          	jalr	1300(ra) # 80001c0e <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006702:	00003717          	auipc	a4,0x3
    80006706:	92670713          	addi	a4,a4,-1754 # 80009028 <stats>
    8000670a:	435c                	lw	a5,4(a4)
    8000670c:	2785                	addiw	a5,a5,1
    8000670e:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006710:	c09d                	beqz	s1,80006736 <copyinstr_new+0x5c>
    80006712:	009906b3          	add	a3,s2,s1
    80006716:	87ca                	mv	a5,s2
    80006718:	6538                	ld	a4,72(a0)
    8000671a:	00e7fe63          	bgeu	a5,a4,80006736 <copyinstr_new+0x5c>
    dst[i] = s[i];
    8000671e:	0007c803          	lbu	a6,0(a5)
    80006722:	41278733          	sub	a4,a5,s2
    80006726:	974e                	add	a4,a4,s3
    80006728:	01070023          	sb	a6,0(a4)
    if(s[i] == '\0')
    8000672c:	02080363          	beqz	a6,80006752 <copyinstr_new+0x78>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006730:	0785                	addi	a5,a5,1
    80006732:	fed793e3          	bne	a5,a3,80006718 <copyinstr_new+0x3e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80006736:	100027f3          	csrr	a5,sstatus
      return 0;
  }
  w_sstatus(r_sstatus() & ~SSTATUS_SPP);
    8000673a:	eff7f793          	andi	a5,a5,-257
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000673e:	10079073          	csrw	sstatus,a5
  return -1;
    80006742:	557d                	li	a0,-1
}
    80006744:	70a2                	ld	ra,40(sp)
    80006746:	7402                	ld	s0,32(sp)
    80006748:	64e2                	ld	s1,24(sp)
    8000674a:	6942                	ld	s2,16(sp)
    8000674c:	69a2                	ld	s3,8(sp)
    8000674e:	6145                	addi	sp,sp,48
    80006750:	8082                	ret
      return 0;
    80006752:	4501                	li	a0,0
    80006754:	bfc5                	j	80006744 <copyinstr_new+0x6a>

0000000080006756 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006756:	1141                	addi	sp,sp,-16
    80006758:	e422                	sd	s0,8(sp)
    8000675a:	0800                	addi	s0,sp,16
  return -1;
}
    8000675c:	557d                	li	a0,-1
    8000675e:	6422                	ld	s0,8(sp)
    80006760:	0141                	addi	sp,sp,16
    80006762:	8082                	ret

0000000080006764 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006764:	7179                	addi	sp,sp,-48
    80006766:	f406                	sd	ra,40(sp)
    80006768:	f022                	sd	s0,32(sp)
    8000676a:	ec26                	sd	s1,24(sp)
    8000676c:	e84a                	sd	s2,16(sp)
    8000676e:	e44e                	sd	s3,8(sp)
    80006770:	e052                	sd	s4,0(sp)
    80006772:	1800                	addi	s0,sp,48
    80006774:	892a                	mv	s2,a0
    80006776:	89ae                	mv	s3,a1
    80006778:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    8000677a:	00020517          	auipc	a0,0x20
    8000677e:	88650513          	addi	a0,a0,-1914 # 80026000 <stats>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	47e080e7          	jalr	1150(ra) # 80000c00 <acquire>

  if(stats.sz == 0) {
    8000678a:	00021797          	auipc	a5,0x21
    8000678e:	88e7a783          	lw	a5,-1906(a5) # 80027018 <stats+0x1018>
    80006792:	cbb5                	beqz	a5,80006806 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006794:	00021797          	auipc	a5,0x21
    80006798:	86c78793          	addi	a5,a5,-1940 # 80027000 <stats+0x1000>
    8000679c:	4fd8                	lw	a4,28(a5)
    8000679e:	4f9c                	lw	a5,24(a5)
    800067a0:	9f99                	subw	a5,a5,a4
    800067a2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067a6:	06d05e63          	blez	a3,80006822 <statsread+0xbe>
    if(m > n)
    800067aa:	8a3e                	mv	s4,a5
    800067ac:	00d4d363          	bge	s1,a3,800067b2 <statsread+0x4e>
    800067b0:	8a26                	mv	s4,s1
    800067b2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800067b6:	86a6                	mv	a3,s1
    800067b8:	00020617          	auipc	a2,0x20
    800067bc:	86060613          	addi	a2,a2,-1952 # 80026018 <stats+0x18>
    800067c0:	963a                	add	a2,a2,a4
    800067c2:	85ce                	mv	a1,s3
    800067c4:	854a                	mv	a0,s2
    800067c6:	ffffc097          	auipc	ra,0xffffc
    800067ca:	fd6080e7          	jalr	-42(ra) # 8000279c <either_copyout>
    800067ce:	57fd                	li	a5,-1
    800067d0:	00f50a63          	beq	a0,a5,800067e4 <statsread+0x80>
      stats.off += m;
    800067d4:	00021717          	auipc	a4,0x21
    800067d8:	82c70713          	addi	a4,a4,-2004 # 80027000 <stats+0x1000>
    800067dc:	4f5c                	lw	a5,28(a4)
    800067de:	00fa07bb          	addw	a5,s4,a5
    800067e2:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800067e4:	00020517          	auipc	a0,0x20
    800067e8:	81c50513          	addi	a0,a0,-2020 # 80026000 <stats>
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	4c8080e7          	jalr	1224(ra) # 80000cb4 <release>
  return m;
}
    800067f4:	8526                	mv	a0,s1
    800067f6:	70a2                	ld	ra,40(sp)
    800067f8:	7402                	ld	s0,32(sp)
    800067fa:	64e2                	ld	s1,24(sp)
    800067fc:	6942                	ld	s2,16(sp)
    800067fe:	69a2                	ld	s3,8(sp)
    80006800:	6a02                	ld	s4,0(sp)
    80006802:	6145                	addi	sp,sp,48
    80006804:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006806:	6585                	lui	a1,0x1
    80006808:	00020517          	auipc	a0,0x20
    8000680c:	81050513          	addi	a0,a0,-2032 # 80026018 <stats+0x18>
    80006810:	00000097          	auipc	ra,0x0
    80006814:	dee080e7          	jalr	-530(ra) # 800065fe <statscopyin>
    80006818:	00021797          	auipc	a5,0x21
    8000681c:	80a7a023          	sw	a0,-2048(a5) # 80027018 <stats+0x1018>
    80006820:	bf95                	j	80006794 <statsread+0x30>
    stats.sz = 0;
    80006822:	00020797          	auipc	a5,0x20
    80006826:	7de78793          	addi	a5,a5,2014 # 80027000 <stats+0x1000>
    8000682a:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000682e:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006832:	54fd                	li	s1,-1
    80006834:	bf45                	j	800067e4 <statsread+0x80>

0000000080006836 <statsinit>:

void
statsinit(void)
{
    80006836:	1141                	addi	sp,sp,-16
    80006838:	e406                	sd	ra,8(sp)
    8000683a:	e022                	sd	s0,0(sp)
    8000683c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000683e:	00002597          	auipc	a1,0x2
    80006842:	09a58593          	addi	a1,a1,154 # 800088d8 <syscalls+0x470>
    80006846:	0001f517          	auipc	a0,0x1f
    8000684a:	7ba50513          	addi	a0,a0,1978 # 80026000 <stats>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	322080e7          	jalr	802(ra) # 80000b70 <initlock>

  devsw[STATS].read = statsread;
    80006856:	0001b797          	auipc	a5,0x1b
    8000685a:	55a78793          	addi	a5,a5,1370 # 80021db0 <devsw>
    8000685e:	00000717          	auipc	a4,0x0
    80006862:	f0670713          	addi	a4,a4,-250 # 80006764 <statsread>
    80006866:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006868:	00000717          	auipc	a4,0x0
    8000686c:	eee70713          	addi	a4,a4,-274 # 80006756 <statswrite>
    80006870:	f798                	sd	a4,40(a5)
}
    80006872:	60a2                	ld	ra,8(sp)
    80006874:	6402                	ld	s0,0(sp)
    80006876:	0141                	addi	sp,sp,16
    80006878:	8082                	ret

000000008000687a <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    8000687a:	1101                	addi	sp,sp,-32
    8000687c:	ec22                	sd	s0,24(sp)
    8000687e:	1000                	addi	s0,sp,32
    80006880:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    80006882:	c299                	beqz	a3,80006888 <sprintint+0xe>
    80006884:	0805c263          	bltz	a1,80006908 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    80006888:	2581                	sext.w	a1,a1
    8000688a:	4301                	li	t1,0

  i = 0;
    8000688c:	fe040713          	addi	a4,s0,-32
    80006890:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    80006892:	2601                	sext.w	a2,a2
    80006894:	00002697          	auipc	a3,0x2
    80006898:	04c68693          	addi	a3,a3,76 # 800088e0 <digits>
    8000689c:	88aa                	mv	a7,a0
    8000689e:	2505                	addiw	a0,a0,1
    800068a0:	02c5f7bb          	remuw	a5,a1,a2
    800068a4:	1782                	slli	a5,a5,0x20
    800068a6:	9381                	srli	a5,a5,0x20
    800068a8:	97b6                	add	a5,a5,a3
    800068aa:	0007c783          	lbu	a5,0(a5)
    800068ae:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800068b2:	0005879b          	sext.w	a5,a1
    800068b6:	02c5d5bb          	divuw	a1,a1,a2
    800068ba:	0705                	addi	a4,a4,1
    800068bc:	fec7f0e3          	bgeu	a5,a2,8000689c <sprintint+0x22>

  if(sign)
    800068c0:	00030b63          	beqz	t1,800068d6 <sprintint+0x5c>
    buf[i++] = '-';
    800068c4:	ff050793          	addi	a5,a0,-16
    800068c8:	97a2                	add	a5,a5,s0
    800068ca:	02d00713          	li	a4,45
    800068ce:	fee78823          	sb	a4,-16(a5)
    800068d2:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800068d6:	02a05d63          	blez	a0,80006910 <sprintint+0x96>
    800068da:	fe040793          	addi	a5,s0,-32
    800068de:	00a78733          	add	a4,a5,a0
    800068e2:	87c2                	mv	a5,a6
    800068e4:	00180613          	addi	a2,a6,1
    800068e8:	fff5069b          	addiw	a3,a0,-1
    800068ec:	1682                	slli	a3,a3,0x20
    800068ee:	9281                	srli	a3,a3,0x20
    800068f0:	9636                	add	a2,a2,a3
  *s = c;
    800068f2:	fff74683          	lbu	a3,-1(a4)
    800068f6:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800068fa:	177d                	addi	a4,a4,-1
    800068fc:	0785                	addi	a5,a5,1
    800068fe:	fec79ae3          	bne	a5,a2,800068f2 <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006902:	6462                	ld	s0,24(sp)
    80006904:	6105                	addi	sp,sp,32
    80006906:	8082                	ret
    x = -xx;
    80006908:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000690c:	4305                	li	t1,1
    x = -xx;
    8000690e:	bfbd                	j	8000688c <sprintint+0x12>
  while(--i >= 0)
    80006910:	4501                	li	a0,0
    80006912:	bfc5                	j	80006902 <sprintint+0x88>

0000000080006914 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006914:	7135                	addi	sp,sp,-160
    80006916:	f486                	sd	ra,104(sp)
    80006918:	f0a2                	sd	s0,96(sp)
    8000691a:	eca6                	sd	s1,88(sp)
    8000691c:	e8ca                	sd	s2,80(sp)
    8000691e:	e4ce                	sd	s3,72(sp)
    80006920:	e0d2                	sd	s4,64(sp)
    80006922:	fc56                	sd	s5,56(sp)
    80006924:	f85a                	sd	s6,48(sp)
    80006926:	f45e                	sd	s7,40(sp)
    80006928:	f062                	sd	s8,32(sp)
    8000692a:	ec66                	sd	s9,24(sp)
    8000692c:	e86a                	sd	s10,16(sp)
    8000692e:	1880                	addi	s0,sp,112
    80006930:	e414                	sd	a3,8(s0)
    80006932:	e818                	sd	a4,16(s0)
    80006934:	ec1c                	sd	a5,24(s0)
    80006936:	03043023          	sd	a6,32(s0)
    8000693a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000693e:	c61d                	beqz	a2,8000696c <snprintf+0x58>
    80006940:	8baa                	mv	s7,a0
    80006942:	89ae                	mv	s3,a1
    80006944:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006946:	00840793          	addi	a5,s0,8
    8000694a:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    8000694e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006950:	4901                	li	s2,0
    80006952:	02b05563          	blez	a1,8000697c <snprintf+0x68>
    if(c != '%'){
    80006956:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000695a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000695e:	02800d13          	li	s10,40
    switch(c){
    80006962:	07800c93          	li	s9,120
    80006966:	06400c13          	li	s8,100
    8000696a:	a01d                	j	80006990 <snprintf+0x7c>
    panic("null fmt");
    8000696c:	00001517          	auipc	a0,0x1
    80006970:	6bc50513          	addi	a0,a0,1724 # 80008028 <etext+0x28>
    80006974:	ffffa097          	auipc	ra,0xffffa
    80006978:	bd2080e7          	jalr	-1070(ra) # 80000546 <panic>
  int off = 0;
    8000697c:	4481                	li	s1,0
    8000697e:	a875                	j	80006a3a <snprintf+0x126>
  *s = c;
    80006980:	009b8733          	add	a4,s7,s1
    80006984:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006988:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000698a:	2905                	addiw	s2,s2,1
    8000698c:	0b34d763          	bge	s1,s3,80006a3a <snprintf+0x126>
    80006990:	012a07b3          	add	a5,s4,s2
    80006994:	0007c783          	lbu	a5,0(a5)
    80006998:	0007871b          	sext.w	a4,a5
    8000699c:	cfd9                	beqz	a5,80006a3a <snprintf+0x126>
    if(c != '%'){
    8000699e:	ff5711e3          	bne	a4,s5,80006980 <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800069a2:	2905                	addiw	s2,s2,1
    800069a4:	012a07b3          	add	a5,s4,s2
    800069a8:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800069ac:	c7d9                	beqz	a5,80006a3a <snprintf+0x126>
    switch(c){
    800069ae:	05678c63          	beq	a5,s6,80006a06 <snprintf+0xf2>
    800069b2:	02fb6763          	bltu	s6,a5,800069e0 <snprintf+0xcc>
    800069b6:	0b578763          	beq	a5,s5,80006a64 <snprintf+0x150>
    800069ba:	0b879b63          	bne	a5,s8,80006a70 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800069be:	f9843783          	ld	a5,-104(s0)
    800069c2:	00878713          	addi	a4,a5,8
    800069c6:	f8e43c23          	sd	a4,-104(s0)
    800069ca:	4685                	li	a3,1
    800069cc:	4629                	li	a2,10
    800069ce:	438c                	lw	a1,0(a5)
    800069d0:	009b8533          	add	a0,s7,s1
    800069d4:	00000097          	auipc	ra,0x0
    800069d8:	ea6080e7          	jalr	-346(ra) # 8000687a <sprintint>
    800069dc:	9ca9                	addw	s1,s1,a0
      break;
    800069de:	b775                	j	8000698a <snprintf+0x76>
    switch(c){
    800069e0:	09979863          	bne	a5,s9,80006a70 <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    800069e4:	f9843783          	ld	a5,-104(s0)
    800069e8:	00878713          	addi	a4,a5,8
    800069ec:	f8e43c23          	sd	a4,-104(s0)
    800069f0:	4685                	li	a3,1
    800069f2:	4641                	li	a2,16
    800069f4:	438c                	lw	a1,0(a5)
    800069f6:	009b8533          	add	a0,s7,s1
    800069fa:	00000097          	auipc	ra,0x0
    800069fe:	e80080e7          	jalr	-384(ra) # 8000687a <sprintint>
    80006a02:	9ca9                	addw	s1,s1,a0
      break;
    80006a04:	b759                	j	8000698a <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    80006a06:	f9843783          	ld	a5,-104(s0)
    80006a0a:	00878713          	addi	a4,a5,8
    80006a0e:	f8e43c23          	sd	a4,-104(s0)
    80006a12:	639c                	ld	a5,0(a5)
    80006a14:	c3b1                	beqz	a5,80006a58 <snprintf+0x144>
      for(; *s && off < sz; s++)
    80006a16:	0007c703          	lbu	a4,0(a5)
    80006a1a:	db25                	beqz	a4,8000698a <snprintf+0x76>
    80006a1c:	0734d563          	bge	s1,s3,80006a86 <snprintf+0x172>
    80006a20:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a24:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a28:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a2a:	0785                	addi	a5,a5,1
    80006a2c:	0007c703          	lbu	a4,0(a5)
    80006a30:	df29                	beqz	a4,8000698a <snprintf+0x76>
    80006a32:	0685                	addi	a3,a3,1
    80006a34:	fe9998e3          	bne	s3,s1,80006a24 <snprintf+0x110>
  int off = 0;
    80006a38:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a3a:	8526                	mv	a0,s1
    80006a3c:	70a6                	ld	ra,104(sp)
    80006a3e:	7406                	ld	s0,96(sp)
    80006a40:	64e6                	ld	s1,88(sp)
    80006a42:	6946                	ld	s2,80(sp)
    80006a44:	69a6                	ld	s3,72(sp)
    80006a46:	6a06                	ld	s4,64(sp)
    80006a48:	7ae2                	ld	s5,56(sp)
    80006a4a:	7b42                	ld	s6,48(sp)
    80006a4c:	7ba2                	ld	s7,40(sp)
    80006a4e:	7c02                	ld	s8,32(sp)
    80006a50:	6ce2                	ld	s9,24(sp)
    80006a52:	6d42                	ld	s10,16(sp)
    80006a54:	610d                	addi	sp,sp,160
    80006a56:	8082                	ret
        s = "(null)";
    80006a58:	00001797          	auipc	a5,0x1
    80006a5c:	5c878793          	addi	a5,a5,1480 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006a60:	876a                	mv	a4,s10
    80006a62:	bf6d                	j	80006a1c <snprintf+0x108>
  *s = c;
    80006a64:	009b87b3          	add	a5,s7,s1
    80006a68:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    80006a6c:	2485                	addiw	s1,s1,1
      break;
    80006a6e:	bf31                	j	8000698a <snprintf+0x76>
  *s = c;
    80006a70:	009b8733          	add	a4,s7,s1
    80006a74:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    80006a78:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006a7c:	975e                	add	a4,a4,s7
    80006a7e:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006a82:	2489                	addiw	s1,s1,2
      break;
    80006a84:	b719                	j	8000698a <snprintf+0x76>
      for(; *s && off < sz; s++)
    80006a86:	89a6                	mv	s3,s1
    80006a88:	bf45                	j	80006a38 <snprintf+0x124>
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
