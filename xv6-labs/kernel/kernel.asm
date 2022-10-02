
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
    80000060:	bd478793          	addi	a5,a5,-1068 # 80005c30 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
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
    8000012a:	396080e7          	jalr	918(ra) # 800024bc <either_copyin>
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
    800001d0:	800080e7          	jalr	-2048(ra) # 800019cc <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	00c080e7          	jalr	12(ra) # 800021e8 <sleep>
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
    8000021c:	24e080e7          	jalr	590(ra) # 80002466 <either_copyout>
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
    800002fc:	21a080e7          	jalr	538(ra) # 80002512 <procdump>
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
    80000450:	f1c080e7          	jalr	-228(ra) # 80002368 <wakeup>
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
    80000482:	73278793          	addi	a5,a5,1842 # 80021bb0 <devsw>
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
    800008aa:	ac2080e7          	jalr	-1342(ra) # 80002368 <wakeup>
    
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
    80000944:	8a8080e7          	jalr	-1880(ra) # 800021e8 <sleep>
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
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
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
    80000af8:	00025517          	auipc	a0,0x25
    80000afc:	50850513          	addi	a0,a0,1288 # 80026000 <end>
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
    80000b9e:	e16080e7          	jalr	-490(ra) # 800019b0 <mycpu>
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
    80000bd0:	de4080e7          	jalr	-540(ra) # 800019b0 <mycpu>
    80000bd4:	5d3c                	lw	a5,120(a0)
    80000bd6:	cf89                	beqz	a5,80000bf0 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd8:	00001097          	auipc	ra,0x1
    80000bdc:	dd8080e7          	jalr	-552(ra) # 800019b0 <mycpu>
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
    80000bf4:	dc0080e7          	jalr	-576(ra) # 800019b0 <mycpu>
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
    80000c34:	d80080e7          	jalr	-640(ra) # 800019b0 <mycpu>
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
    80000c60:	d54080e7          	jalr	-684(ra) # 800019b0 <mycpu>
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
    80000dac:	177d                	addi	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
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
    80000eb6:	aee080e7          	jalr	-1298(ra) # 800019a0 <cpuid>
    virtio_disk_init(); // emulated hard disk
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
    80000ed2:	ad2080e7          	jalr	-1326(ra) # 800019a0 <cpuid>
    80000ed6:	85aa                	mv	a1,a0
    80000ed8:	00007517          	auipc	a0,0x7
    80000edc:	1e050513          	addi	a0,a0,480 # 800080b8 <digits+0x78>
    80000ee0:	fffff097          	auipc	ra,0xfffff
    80000ee4:	6b0080e7          	jalr	1712(ra) # 80000590 <printf>
    kvminithart();    // turn on paging
    80000ee8:	00000097          	auipc	ra,0x0
    80000eec:	0d8080e7          	jalr	216(ra) # 80000fc0 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	764080e7          	jalr	1892(ra) # 80002654 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef8:	00005097          	auipc	ra,0x5
    80000efc:	d78080e7          	jalr	-648(ra) # 80005c70 <plicinithart>
  }

  scheduler();        
    80000f00:	00001097          	auipc	ra,0x1
    80000f04:	00c080e7          	jalr	12(ra) # 80001f0c <scheduler>
    consoleinit();
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	54e080e7          	jalr	1358(ra) # 80000456 <consoleinit>
    printfinit();
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	860080e7          	jalr	-1952(ra) # 80000770 <printfinit>
    printf("\n");
    80000f18:	00007517          	auipc	a0,0x7
    80000f1c:	1b050513          	addi	a0,a0,432 # 800080c8 <digits+0x88>
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	670080e7          	jalr	1648(ra) # 80000590 <printf>
    printf("xv6 kernel is booting\n");
    80000f28:	00007517          	auipc	a0,0x7
    80000f2c:	17850513          	addi	a0,a0,376 # 800080a0 <digits+0x60>
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	660080e7          	jalr	1632(ra) # 80000590 <printf>
    printf("\n");
    80000f38:	00007517          	auipc	a0,0x7
    80000f3c:	19050513          	addi	a0,a0,400 # 800080c8 <digits+0x88>
    80000f40:	fffff097          	auipc	ra,0xfffff
    80000f44:	650080e7          	jalr	1616(ra) # 80000590 <printf>
    kinit();         // physical page allocator
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	b8c080e7          	jalr	-1140(ra) # 80000ad4 <kinit>
    kvminit();       // create kernel page table
    80000f50:	00000097          	auipc	ra,0x0
    80000f54:	2a0080e7          	jalr	672(ra) # 800011f0 <kvminit>
    kvminithart();   // turn on paging
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	068080e7          	jalr	104(ra) # 80000fc0 <kvminithart>
    procinit();      // process table
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	970080e7          	jalr	-1680(ra) # 800018d0 <procinit>
    trapinit();      // trap vectors
    80000f68:	00001097          	auipc	ra,0x1
    80000f6c:	6c4080e7          	jalr	1732(ra) # 8000262c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	6e4080e7          	jalr	1764(ra) # 80002654 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f78:	00005097          	auipc	ra,0x5
    80000f7c:	ce2080e7          	jalr	-798(ra) # 80005c5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	cf0080e7          	jalr	-784(ra) # 80005c70 <plicinithart>
    binit();         // buffer cache
    80000f88:	00002097          	auipc	ra,0x2
    80000f8c:	e94080e7          	jalr	-364(ra) # 80002e1c <binit>
    iinit();         // inode cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	522080e7          	jalr	1314(ra) # 800034b2 <iinit>
    fileinit();      // file table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	4c4080e7          	jalr	1220(ra) # 8000445c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	dd6080e7          	jalr	-554(ra) # 80005d76 <virtio_disk_init>
    userinit();      // first user process
    80000fa8:	00001097          	auipc	ra,0x1
    80000fac:	cee080e7          	jalr	-786(ra) # 80001c96 <userinit>
    __sync_synchronize();
    80000fb0:	0ff0000f          	fence
    started = 1;
    80000fb4:	4785                	li	a5,1
    80000fb6:	00008717          	auipc	a4,0x8
    80000fba:	04f72b23          	sw	a5,86(a4) # 8000900c <started>
    80000fbe:	b789                	j	80000f00 <main+0x56>

0000000080000fc0 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fc0:	1141                	addi	sp,sp,-16
    80000fc2:	e422                	sd	s0,8(sp)
    80000fc4:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fc6:	00008797          	auipc	a5,0x8
    80000fca:	04a7b783          	ld	a5,74(a5) # 80009010 <kernel_pagetable>
    80000fce:	83b1                	srli	a5,a5,0xc
    80000fd0:	577d                	li	a4,-1
    80000fd2:	177e                	slli	a4,a4,0x3f
    80000fd4:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fd6:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fda:	12000073          	sfence.vma
  sfence_vma();
}
    80000fde:	6422                	ld	s0,8(sp)
    80000fe0:	0141                	addi	sp,sp,16
    80000fe2:	8082                	ret

0000000080000fe4 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fe4:	7139                	addi	sp,sp,-64
    80000fe6:	fc06                	sd	ra,56(sp)
    80000fe8:	f822                	sd	s0,48(sp)
    80000fea:	f426                	sd	s1,40(sp)
    80000fec:	f04a                	sd	s2,32(sp)
    80000fee:	ec4e                	sd	s3,24(sp)
    80000ff0:	e852                	sd	s4,16(sp)
    80000ff2:	e456                	sd	s5,8(sp)
    80000ff4:	e05a                	sd	s6,0(sp)
    80000ff6:	0080                	addi	s0,sp,64
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	89ae                	mv	s3,a1
    80000ffc:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000ffe:	57fd                	li	a5,-1
    80001000:	83e9                	srli	a5,a5,0x1a
    80001002:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001004:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001006:	04b7f263          	bgeu	a5,a1,8000104a <walk+0x66>
    panic("walk");
    8000100a:	00007517          	auipc	a0,0x7
    8000100e:	0c650513          	addi	a0,a0,198 # 800080d0 <digits+0x90>
    80001012:	fffff097          	auipc	ra,0xfffff
    80001016:	534080e7          	jalr	1332(ra) # 80000546 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000101a:	060a8663          	beqz	s5,80001086 <walk+0xa2>
    8000101e:	00000097          	auipc	ra,0x0
    80001022:	af2080e7          	jalr	-1294(ra) # 80000b10 <kalloc>
    80001026:	84aa                	mv	s1,a0
    80001028:	c529                	beqz	a0,80001072 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000102a:	6605                	lui	a2,0x1
    8000102c:	4581                	li	a1,0
    8000102e:	00000097          	auipc	ra,0x0
    80001032:	cce080e7          	jalr	-818(ra) # 80000cfc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001036:	00c4d793          	srli	a5,s1,0xc
    8000103a:	07aa                	slli	a5,a5,0xa
    8000103c:	0017e793          	ori	a5,a5,1
    80001040:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001044:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    80001046:	036a0063          	beq	s4,s6,80001066 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000104a:	0149d933          	srl	s2,s3,s4
    8000104e:	1ff97913          	andi	s2,s2,511
    80001052:	090e                	slli	s2,s2,0x3
    80001054:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001056:	00093483          	ld	s1,0(s2)
    8000105a:	0014f793          	andi	a5,s1,1
    8000105e:	dfd5                	beqz	a5,8000101a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001060:	80a9                	srli	s1,s1,0xa
    80001062:	04b2                	slli	s1,s1,0xc
    80001064:	b7c5                	j	80001044 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001066:	00c9d513          	srli	a0,s3,0xc
    8000106a:	1ff57513          	andi	a0,a0,511
    8000106e:	050e                	slli	a0,a0,0x3
    80001070:	9526                	add	a0,a0,s1
}
    80001072:	70e2                	ld	ra,56(sp)
    80001074:	7442                	ld	s0,48(sp)
    80001076:	74a2                	ld	s1,40(sp)
    80001078:	7902                	ld	s2,32(sp)
    8000107a:	69e2                	ld	s3,24(sp)
    8000107c:	6a42                	ld	s4,16(sp)
    8000107e:	6aa2                	ld	s5,8(sp)
    80001080:	6b02                	ld	s6,0(sp)
    80001082:	6121                	addi	sp,sp,64
    80001084:	8082                	ret
        return 0;
    80001086:	4501                	li	a0,0
    80001088:	b7ed                	j	80001072 <walk+0x8e>

000000008000108a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000108a:	57fd                	li	a5,-1
    8000108c:	83e9                	srli	a5,a5,0x1a
    8000108e:	00b7f463          	bgeu	a5,a1,80001096 <walkaddr+0xc>
    return 0;
    80001092:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001094:	8082                	ret
{
    80001096:	1141                	addi	sp,sp,-16
    80001098:	e406                	sd	ra,8(sp)
    8000109a:	e022                	sd	s0,0(sp)
    8000109c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000109e:	4601                	li	a2,0
    800010a0:	00000097          	auipc	ra,0x0
    800010a4:	f44080e7          	jalr	-188(ra) # 80000fe4 <walk>
  if(pte == 0)
    800010a8:	c105                	beqz	a0,800010c8 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010aa:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010ac:	0117f693          	andi	a3,a5,17
    800010b0:	4745                	li	a4,17
    return 0;
    800010b2:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010b4:	00e68663          	beq	a3,a4,800010c0 <walkaddr+0x36>
}
    800010b8:	60a2                	ld	ra,8(sp)
    800010ba:	6402                	ld	s0,0(sp)
    800010bc:	0141                	addi	sp,sp,16
    800010be:	8082                	ret
  pa = PTE2PA(*pte);
    800010c0:	83a9                	srli	a5,a5,0xa
    800010c2:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010c6:	bfcd                	j	800010b8 <walkaddr+0x2e>
    return 0;
    800010c8:	4501                	li	a0,0
    800010ca:	b7fd                	j	800010b8 <walkaddr+0x2e>

00000000800010cc <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010cc:	1101                	addi	sp,sp,-32
    800010ce:	ec06                	sd	ra,24(sp)
    800010d0:	e822                	sd	s0,16(sp)
    800010d2:	e426                	sd	s1,8(sp)
    800010d4:	1000                	addi	s0,sp,32
    800010d6:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010d8:	1552                	slli	a0,a0,0x34
    800010da:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010de:	4601                	li	a2,0
    800010e0:	00008517          	auipc	a0,0x8
    800010e4:	f3053503          	ld	a0,-208(a0) # 80009010 <kernel_pagetable>
    800010e8:	00000097          	auipc	ra,0x0
    800010ec:	efc080e7          	jalr	-260(ra) # 80000fe4 <walk>
  if(pte == 0)
    800010f0:	cd09                	beqz	a0,8000110a <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010f2:	6108                	ld	a0,0(a0)
    800010f4:	00157793          	andi	a5,a0,1
    800010f8:	c38d                	beqz	a5,8000111a <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010fa:	8129                	srli	a0,a0,0xa
    800010fc:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010fe:	9526                	add	a0,a0,s1
    80001100:	60e2                	ld	ra,24(sp)
    80001102:	6442                	ld	s0,16(sp)
    80001104:	64a2                	ld	s1,8(sp)
    80001106:	6105                	addi	sp,sp,32
    80001108:	8082                	ret
    panic("kvmpa");
    8000110a:	00007517          	auipc	a0,0x7
    8000110e:	fce50513          	addi	a0,a0,-50 # 800080d8 <digits+0x98>
    80001112:	fffff097          	auipc	ra,0xfffff
    80001116:	434080e7          	jalr	1076(ra) # 80000546 <panic>
    panic("kvmpa");
    8000111a:	00007517          	auipc	a0,0x7
    8000111e:	fbe50513          	addi	a0,a0,-66 # 800080d8 <digits+0x98>
    80001122:	fffff097          	auipc	ra,0xfffff
    80001126:	424080e7          	jalr	1060(ra) # 80000546 <panic>

000000008000112a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000112a:	715d                	addi	sp,sp,-80
    8000112c:	e486                	sd	ra,72(sp)
    8000112e:	e0a2                	sd	s0,64(sp)
    80001130:	fc26                	sd	s1,56(sp)
    80001132:	f84a                	sd	s2,48(sp)
    80001134:	f44e                	sd	s3,40(sp)
    80001136:	f052                	sd	s4,32(sp)
    80001138:	ec56                	sd	s5,24(sp)
    8000113a:	e85a                	sd	s6,16(sp)
    8000113c:	e45e                	sd	s7,8(sp)
    8000113e:	0880                	addi	s0,sp,80
    80001140:	8aaa                	mv	s5,a0
    80001142:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001144:	777d                	lui	a4,0xfffff
    80001146:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000114a:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    8000114e:	99ae                	add	s3,s3,a1
    80001150:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001154:	893e                	mv	s2,a5
    80001156:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000115a:	6b85                	lui	s7,0x1
    8000115c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001160:	4605                	li	a2,1
    80001162:	85ca                	mv	a1,s2
    80001164:	8556                	mv	a0,s5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	e7e080e7          	jalr	-386(ra) # 80000fe4 <walk>
    8000116e:	c51d                	beqz	a0,8000119c <mappages+0x72>
    if(*pte & PTE_V)
    80001170:	611c                	ld	a5,0(a0)
    80001172:	8b85                	andi	a5,a5,1
    80001174:	ef81                	bnez	a5,8000118c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001176:	80b1                	srli	s1,s1,0xc
    80001178:	04aa                	slli	s1,s1,0xa
    8000117a:	0164e4b3          	or	s1,s1,s6
    8000117e:	0014e493          	ori	s1,s1,1
    80001182:	e104                	sd	s1,0(a0)
    if(a == last)
    80001184:	03390863          	beq	s2,s3,800011b4 <mappages+0x8a>
    a += PGSIZE;
    80001188:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000118a:	bfc9                	j	8000115c <mappages+0x32>
      panic("remap");
    8000118c:	00007517          	auipc	a0,0x7
    80001190:	f5450513          	addi	a0,a0,-172 # 800080e0 <digits+0xa0>
    80001194:	fffff097          	auipc	ra,0xfffff
    80001198:	3b2080e7          	jalr	946(ra) # 80000546 <panic>
      return -1;
    8000119c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119e:	60a6                	ld	ra,72(sp)
    800011a0:	6406                	ld	s0,64(sp)
    800011a2:	74e2                	ld	s1,56(sp)
    800011a4:	7942                	ld	s2,48(sp)
    800011a6:	79a2                	ld	s3,40(sp)
    800011a8:	7a02                	ld	s4,32(sp)
    800011aa:	6ae2                	ld	s5,24(sp)
    800011ac:	6b42                	ld	s6,16(sp)
    800011ae:	6ba2                	ld	s7,8(sp)
    800011b0:	6161                	addi	sp,sp,80
    800011b2:	8082                	ret
  return 0;
    800011b4:	4501                	li	a0,0
    800011b6:	b7e5                	j	8000119e <mappages+0x74>

00000000800011b8 <kvmmap>:
{
    800011b8:	1141                	addi	sp,sp,-16
    800011ba:	e406                	sd	ra,8(sp)
    800011bc:	e022                	sd	s0,0(sp)
    800011be:	0800                	addi	s0,sp,16
    800011c0:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011c2:	86ae                	mv	a3,a1
    800011c4:	85aa                	mv	a1,a0
    800011c6:	00008517          	auipc	a0,0x8
    800011ca:	e4a53503          	ld	a0,-438(a0) # 80009010 <kernel_pagetable>
    800011ce:	00000097          	auipc	ra,0x0
    800011d2:	f5c080e7          	jalr	-164(ra) # 8000112a <mappages>
    800011d6:	e509                	bnez	a0,800011e0 <kvmmap+0x28>
}
    800011d8:	60a2                	ld	ra,8(sp)
    800011da:	6402                	ld	s0,0(sp)
    800011dc:	0141                	addi	sp,sp,16
    800011de:	8082                	ret
    panic("kvmmap");
    800011e0:	00007517          	auipc	a0,0x7
    800011e4:	f0850513          	addi	a0,a0,-248 # 800080e8 <digits+0xa8>
    800011e8:	fffff097          	auipc	ra,0xfffff
    800011ec:	35e080e7          	jalr	862(ra) # 80000546 <panic>

00000000800011f0 <kvminit>:
{
    800011f0:	1101                	addi	sp,sp,-32
    800011f2:	ec06                	sd	ra,24(sp)
    800011f4:	e822                	sd	s0,16(sp)
    800011f6:	e426                	sd	s1,8(sp)
    800011f8:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	916080e7          	jalr	-1770(ra) # 80000b10 <kalloc>
    80001202:	00008717          	auipc	a4,0x8
    80001206:	e0a73723          	sd	a0,-498(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000120a:	6605                	lui	a2,0x1
    8000120c:	4581                	li	a1,0
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	aee080e7          	jalr	-1298(ra) # 80000cfc <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001216:	4699                	li	a3,6
    80001218:	6605                	lui	a2,0x1
    8000121a:	100005b7          	lui	a1,0x10000
    8000121e:	10000537          	lui	a0,0x10000
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f96080e7          	jalr	-106(ra) # 800011b8 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100015b7          	lui	a1,0x10001
    80001232:	10001537          	lui	a0,0x10001
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f82080e7          	jalr	-126(ra) # 800011b8 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6641                	lui	a2,0x10
    80001242:	020005b7          	lui	a1,0x2000
    80001246:	02000537          	lui	a0,0x2000
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f6e080e7          	jalr	-146(ra) # 800011b8 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	00400637          	lui	a2,0x400
    80001258:	0c0005b7          	lui	a1,0xc000
    8000125c:	0c000537          	lui	a0,0xc000
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f58080e7          	jalr	-168(ra) # 800011b8 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001268:	00007497          	auipc	s1,0x7
    8000126c:	d9848493          	addi	s1,s1,-616 # 80008000 <etext>
    80001270:	46a9                	li	a3,10
    80001272:	80007617          	auipc	a2,0x80007
    80001276:	d8e60613          	addi	a2,a2,-626 # 8000 <_entry-0x7fff8000>
    8000127a:	4585                	li	a1,1
    8000127c:	05fe                	slli	a1,a1,0x1f
    8000127e:	852e                	mv	a0,a1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f38080e7          	jalr	-200(ra) # 800011b8 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001288:	4699                	li	a3,6
    8000128a:	4645                	li	a2,17
    8000128c:	066e                	slli	a2,a2,0x1b
    8000128e:	8e05                	sub	a2,a2,s1
    80001290:	85a6                	mv	a1,s1
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f24080e7          	jalr	-220(ra) # 800011b8 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000129c:	46a9                	li	a3,10
    8000129e:	6605                	lui	a2,0x1
    800012a0:	00006597          	auipc	a1,0x6
    800012a4:	d6058593          	addi	a1,a1,-672 # 80007000 <_trampoline>
    800012a8:	04000537          	lui	a0,0x4000
    800012ac:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    800012ae:	0532                	slli	a0,a0,0xc
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f08080e7          	jalr	-248(ra) # 800011b8 <kvmmap>
}
    800012b8:	60e2                	ld	ra,24(sp)
    800012ba:	6442                	ld	s0,16(sp)
    800012bc:	64a2                	ld	s1,8(sp)
    800012be:	6105                	addi	sp,sp,32
    800012c0:	8082                	ret

00000000800012c2 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012c2:	715d                	addi	sp,sp,-80
    800012c4:	e486                	sd	ra,72(sp)
    800012c6:	e0a2                	sd	s0,64(sp)
    800012c8:	fc26                	sd	s1,56(sp)
    800012ca:	f84a                	sd	s2,48(sp)
    800012cc:	f44e                	sd	s3,40(sp)
    800012ce:	f052                	sd	s4,32(sp)
    800012d0:	ec56                	sd	s5,24(sp)
    800012d2:	e85a                	sd	s6,16(sp)
    800012d4:	e45e                	sd	s7,8(sp)
    800012d6:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012d8:	03459793          	slli	a5,a1,0x34
    800012dc:	e795                	bnez	a5,80001308 <uvmunmap+0x46>
    800012de:	8a2a                	mv	s4,a0
    800012e0:	892e                	mv	s2,a1
    800012e2:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e4:	0632                	slli	a2,a2,0xc
    800012e6:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ea:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ec:	6b05                	lui	s6,0x1
    800012ee:	0735e263          	bltu	a1,s3,80001352 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012f2:	60a6                	ld	ra,72(sp)
    800012f4:	6406                	ld	s0,64(sp)
    800012f6:	74e2                	ld	s1,56(sp)
    800012f8:	7942                	ld	s2,48(sp)
    800012fa:	79a2                	ld	s3,40(sp)
    800012fc:	7a02                	ld	s4,32(sp)
    800012fe:	6ae2                	ld	s5,24(sp)
    80001300:	6b42                	ld	s6,16(sp)
    80001302:	6ba2                	ld	s7,8(sp)
    80001304:	6161                	addi	sp,sp,80
    80001306:	8082                	ret
    panic("uvmunmap: not aligned");
    80001308:	00007517          	auipc	a0,0x7
    8000130c:	de850513          	addi	a0,a0,-536 # 800080f0 <digits+0xb0>
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	236080e7          	jalr	566(ra) # 80000546 <panic>
      panic("uvmunmap: walk");
    80001318:	00007517          	auipc	a0,0x7
    8000131c:	df050513          	addi	a0,a0,-528 # 80008108 <digits+0xc8>
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	226080e7          	jalr	550(ra) # 80000546 <panic>
      panic("uvmunmap: not mapped");
    80001328:	00007517          	auipc	a0,0x7
    8000132c:	df050513          	addi	a0,a0,-528 # 80008118 <digits+0xd8>
    80001330:	fffff097          	auipc	ra,0xfffff
    80001334:	216080e7          	jalr	534(ra) # 80000546 <panic>
      panic("uvmunmap: not a leaf");
    80001338:	00007517          	auipc	a0,0x7
    8000133c:	df850513          	addi	a0,a0,-520 # 80008130 <digits+0xf0>
    80001340:	fffff097          	auipc	ra,0xfffff
    80001344:	206080e7          	jalr	518(ra) # 80000546 <panic>
    *pte = 0;
    80001348:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134c:	995a                	add	s2,s2,s6
    8000134e:	fb3972e3          	bgeu	s2,s3,800012f2 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001352:	4601                	li	a2,0
    80001354:	85ca                	mv	a1,s2
    80001356:	8552                	mv	a0,s4
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	c8c080e7          	jalr	-884(ra) # 80000fe4 <walk>
    80001360:	84aa                	mv	s1,a0
    80001362:	d95d                	beqz	a0,80001318 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001364:	6108                	ld	a0,0(a0)
    80001366:	00157793          	andi	a5,a0,1
    8000136a:	dfdd                	beqz	a5,80001328 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136c:	3ff57793          	andi	a5,a0,1023
    80001370:	fd7784e3          	beq	a5,s7,80001338 <uvmunmap+0x76>
    if(do_free){
    80001374:	fc0a8ae3          	beqz	s5,80001348 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001378:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000137a:	0532                	slli	a0,a0,0xc
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	696080e7          	jalr	1686(ra) # 80000a12 <kfree>
    80001384:	b7d1                	j	80001348 <uvmunmap+0x86>

0000000080001386 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001386:	1101                	addi	sp,sp,-32
    80001388:	ec06                	sd	ra,24(sp)
    8000138a:	e822                	sd	s0,16(sp)
    8000138c:	e426                	sd	s1,8(sp)
    8000138e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	780080e7          	jalr	1920(ra) # 80000b10 <kalloc>
    80001398:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000139a:	c519                	beqz	a0,800013a8 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000139c:	6605                	lui	a2,0x1
    8000139e:	4581                	li	a1,0
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	95c080e7          	jalr	-1700(ra) # 80000cfc <memset>
  return pagetable;
}
    800013a8:	8526                	mv	a0,s1
    800013aa:	60e2                	ld	ra,24(sp)
    800013ac:	6442                	ld	s0,16(sp)
    800013ae:	64a2                	ld	s1,8(sp)
    800013b0:	6105                	addi	sp,sp,32
    800013b2:	8082                	ret

00000000800013b4 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b4:	7179                	addi	sp,sp,-48
    800013b6:	f406                	sd	ra,40(sp)
    800013b8:	f022                	sd	s0,32(sp)
    800013ba:	ec26                	sd	s1,24(sp)
    800013bc:	e84a                	sd	s2,16(sp)
    800013be:	e44e                	sd	s3,8(sp)
    800013c0:	e052                	sd	s4,0(sp)
    800013c2:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c4:	6785                	lui	a5,0x1
    800013c6:	04f67863          	bgeu	a2,a5,80001416 <uvminit+0x62>
    800013ca:	8a2a                	mv	s4,a0
    800013cc:	89ae                	mv	s3,a1
    800013ce:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	740080e7          	jalr	1856(ra) # 80000b10 <kalloc>
    800013d8:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013da:	6605                	lui	a2,0x1
    800013dc:	4581                	li	a1,0
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	91e080e7          	jalr	-1762(ra) # 80000cfc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e6:	4779                	li	a4,30
    800013e8:	86ca                	mv	a3,s2
    800013ea:	6605                	lui	a2,0x1
    800013ec:	4581                	li	a1,0
    800013ee:	8552                	mv	a0,s4
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	d3a080e7          	jalr	-710(ra) # 8000112a <mappages>
  memmove(mem, src, sz);
    800013f8:	8626                	mv	a2,s1
    800013fa:	85ce                	mv	a1,s3
    800013fc:	854a                	mv	a0,s2
    800013fe:	00000097          	auipc	ra,0x0
    80001402:	95a080e7          	jalr	-1702(ra) # 80000d58 <memmove>
}
    80001406:	70a2                	ld	ra,40(sp)
    80001408:	7402                	ld	s0,32(sp)
    8000140a:	64e2                	ld	s1,24(sp)
    8000140c:	6942                	ld	s2,16(sp)
    8000140e:	69a2                	ld	s3,8(sp)
    80001410:	6a02                	ld	s4,0(sp)
    80001412:	6145                	addi	sp,sp,48
    80001414:	8082                	ret
    panic("inituvm: more than a page");
    80001416:	00007517          	auipc	a0,0x7
    8000141a:	d3250513          	addi	a0,a0,-718 # 80008148 <digits+0x108>
    8000141e:	fffff097          	auipc	ra,0xfffff
    80001422:	128080e7          	jalr	296(ra) # 80000546 <panic>

0000000080001426 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001426:	1101                	addi	sp,sp,-32
    80001428:	ec06                	sd	ra,24(sp)
    8000142a:	e822                	sd	s0,16(sp)
    8000142c:	e426                	sd	s1,8(sp)
    8000142e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001430:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001432:	00b67d63          	bgeu	a2,a1,8000144c <uvmdealloc+0x26>
    80001436:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001438:	6785                	lui	a5,0x1
    8000143a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000143c:	00f60733          	add	a4,a2,a5
    80001440:	76fd                	lui	a3,0xfffff
    80001442:	8f75                	and	a4,a4,a3
    80001444:	97ae                	add	a5,a5,a1
    80001446:	8ff5                	and	a5,a5,a3
    80001448:	00f76863          	bltu	a4,a5,80001458 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000144c:	8526                	mv	a0,s1
    8000144e:	60e2                	ld	ra,24(sp)
    80001450:	6442                	ld	s0,16(sp)
    80001452:	64a2                	ld	s1,8(sp)
    80001454:	6105                	addi	sp,sp,32
    80001456:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001458:	8f99                	sub	a5,a5,a4
    8000145a:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000145c:	4685                	li	a3,1
    8000145e:	0007861b          	sext.w	a2,a5
    80001462:	85ba                	mv	a1,a4
    80001464:	00000097          	auipc	ra,0x0
    80001468:	e5e080e7          	jalr	-418(ra) # 800012c2 <uvmunmap>
    8000146c:	b7c5                	j	8000144c <uvmdealloc+0x26>

000000008000146e <uvmalloc>:
  if(newsz < oldsz)
    8000146e:	0ab66163          	bltu	a2,a1,80001510 <uvmalloc+0xa2>
{
    80001472:	7139                	addi	sp,sp,-64
    80001474:	fc06                	sd	ra,56(sp)
    80001476:	f822                	sd	s0,48(sp)
    80001478:	f426                	sd	s1,40(sp)
    8000147a:	f04a                	sd	s2,32(sp)
    8000147c:	ec4e                	sd	s3,24(sp)
    8000147e:	e852                	sd	s4,16(sp)
    80001480:	e456                	sd	s5,8(sp)
    80001482:	0080                	addi	s0,sp,64
    80001484:	8aaa                	mv	s5,a0
    80001486:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001488:	6785                	lui	a5,0x1
    8000148a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000148c:	95be                	add	a1,a1,a5
    8000148e:	77fd                	lui	a5,0xfffff
    80001490:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001494:	08c9f063          	bgeu	s3,a2,80001514 <uvmalloc+0xa6>
    80001498:	894e                	mv	s2,s3
    mem = kalloc();
    8000149a:	fffff097          	auipc	ra,0xfffff
    8000149e:	676080e7          	jalr	1654(ra) # 80000b10 <kalloc>
    800014a2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014a4:	c51d                	beqz	a0,800014d2 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014a6:	6605                	lui	a2,0x1
    800014a8:	4581                	li	a1,0
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	852080e7          	jalr	-1966(ra) # 80000cfc <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014b2:	4779                	li	a4,30
    800014b4:	86a6                	mv	a3,s1
    800014b6:	6605                	lui	a2,0x1
    800014b8:	85ca                	mv	a1,s2
    800014ba:	8556                	mv	a0,s5
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	c6e080e7          	jalr	-914(ra) # 8000112a <mappages>
    800014c4:	e905                	bnez	a0,800014f4 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014c6:	6785                	lui	a5,0x1
    800014c8:	993e                	add	s2,s2,a5
    800014ca:	fd4968e3          	bltu	s2,s4,8000149a <uvmalloc+0x2c>
  return newsz;
    800014ce:	8552                	mv	a0,s4
    800014d0:	a809                	j	800014e2 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014d2:	864e                	mv	a2,s3
    800014d4:	85ca                	mv	a1,s2
    800014d6:	8556                	mv	a0,s5
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	f4e080e7          	jalr	-178(ra) # 80001426 <uvmdealloc>
      return 0;
    800014e0:	4501                	li	a0,0
}
    800014e2:	70e2                	ld	ra,56(sp)
    800014e4:	7442                	ld	s0,48(sp)
    800014e6:	74a2                	ld	s1,40(sp)
    800014e8:	7902                	ld	s2,32(sp)
    800014ea:	69e2                	ld	s3,24(sp)
    800014ec:	6a42                	ld	s4,16(sp)
    800014ee:	6aa2                	ld	s5,8(sp)
    800014f0:	6121                	addi	sp,sp,64
    800014f2:	8082                	ret
      kfree(mem);
    800014f4:	8526                	mv	a0,s1
    800014f6:	fffff097          	auipc	ra,0xfffff
    800014fa:	51c080e7          	jalr	1308(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014fe:	864e                	mv	a2,s3
    80001500:	85ca                	mv	a1,s2
    80001502:	8556                	mv	a0,s5
    80001504:	00000097          	auipc	ra,0x0
    80001508:	f22080e7          	jalr	-222(ra) # 80001426 <uvmdealloc>
      return 0;
    8000150c:	4501                	li	a0,0
    8000150e:	bfd1                	j	800014e2 <uvmalloc+0x74>
    return oldsz;
    80001510:	852e                	mv	a0,a1
}
    80001512:	8082                	ret
  return newsz;
    80001514:	8532                	mv	a0,a2
    80001516:	b7f1                	j	800014e2 <uvmalloc+0x74>

0000000080001518 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001518:	7179                	addi	sp,sp,-48
    8000151a:	f406                	sd	ra,40(sp)
    8000151c:	f022                	sd	s0,32(sp)
    8000151e:	ec26                	sd	s1,24(sp)
    80001520:	e84a                	sd	s2,16(sp)
    80001522:	e44e                	sd	s3,8(sp)
    80001524:	e052                	sd	s4,0(sp)
    80001526:	1800                	addi	s0,sp,48
    80001528:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000152a:	84aa                	mv	s1,a0
    8000152c:	6905                	lui	s2,0x1
    8000152e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001530:	4985                	li	s3,1
    80001532:	a829                	j	8000154c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001534:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001536:	00c79513          	slli	a0,a5,0xc
    8000153a:	00000097          	auipc	ra,0x0
    8000153e:	fde080e7          	jalr	-34(ra) # 80001518 <freewalk>
      pagetable[i] = 0;
    80001542:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001546:	04a1                	addi	s1,s1,8
    80001548:	03248163          	beq	s1,s2,8000156a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000154c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000154e:	00f7f713          	andi	a4,a5,15
    80001552:	ff3701e3          	beq	a4,s3,80001534 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001556:	8b85                	andi	a5,a5,1
    80001558:	d7fd                	beqz	a5,80001546 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000155a:	00007517          	auipc	a0,0x7
    8000155e:	c0e50513          	addi	a0,a0,-1010 # 80008168 <digits+0x128>
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	fe4080e7          	jalr	-28(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    8000156a:	8552                	mv	a0,s4
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	4a6080e7          	jalr	1190(ra) # 80000a12 <kfree>
}
    80001574:	70a2                	ld	ra,40(sp)
    80001576:	7402                	ld	s0,32(sp)
    80001578:	64e2                	ld	s1,24(sp)
    8000157a:	6942                	ld	s2,16(sp)
    8000157c:	69a2                	ld	s3,8(sp)
    8000157e:	6a02                	ld	s4,0(sp)
    80001580:	6145                	addi	sp,sp,48
    80001582:	8082                	ret

0000000080001584 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001584:	1101                	addi	sp,sp,-32
    80001586:	ec06                	sd	ra,24(sp)
    80001588:	e822                	sd	s0,16(sp)
    8000158a:	e426                	sd	s1,8(sp)
    8000158c:	1000                	addi	s0,sp,32
    8000158e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001590:	e999                	bnez	a1,800015a6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001592:	8526                	mv	a0,s1
    80001594:	00000097          	auipc	ra,0x0
    80001598:	f84080e7          	jalr	-124(ra) # 80001518 <freewalk>
}
    8000159c:	60e2                	ld	ra,24(sp)
    8000159e:	6442                	ld	s0,16(sp)
    800015a0:	64a2                	ld	s1,8(sp)
    800015a2:	6105                	addi	sp,sp,32
    800015a4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015a6:	6785                	lui	a5,0x1
    800015a8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015aa:	95be                	add	a1,a1,a5
    800015ac:	4685                	li	a3,1
    800015ae:	00c5d613          	srli	a2,a1,0xc
    800015b2:	4581                	li	a1,0
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	d0e080e7          	jalr	-754(ra) # 800012c2 <uvmunmap>
    800015bc:	bfd9                	j	80001592 <uvmfree+0xe>

00000000800015be <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015be:	c679                	beqz	a2,8000168c <uvmcopy+0xce>
{
    800015c0:	715d                	addi	sp,sp,-80
    800015c2:	e486                	sd	ra,72(sp)
    800015c4:	e0a2                	sd	s0,64(sp)
    800015c6:	fc26                	sd	s1,56(sp)
    800015c8:	f84a                	sd	s2,48(sp)
    800015ca:	f44e                	sd	s3,40(sp)
    800015cc:	f052                	sd	s4,32(sp)
    800015ce:	ec56                	sd	s5,24(sp)
    800015d0:	e85a                	sd	s6,16(sp)
    800015d2:	e45e                	sd	s7,8(sp)
    800015d4:	0880                	addi	s0,sp,80
    800015d6:	8b2a                	mv	s6,a0
    800015d8:	8aae                	mv	s5,a1
    800015da:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015dc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015de:	4601                	li	a2,0
    800015e0:	85ce                	mv	a1,s3
    800015e2:	855a                	mv	a0,s6
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	a00080e7          	jalr	-1536(ra) # 80000fe4 <walk>
    800015ec:	c531                	beqz	a0,80001638 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015ee:	6118                	ld	a4,0(a0)
    800015f0:	00177793          	andi	a5,a4,1
    800015f4:	cbb1                	beqz	a5,80001648 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015f6:	00a75593          	srli	a1,a4,0xa
    800015fa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015fe:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	50e080e7          	jalr	1294(ra) # 80000b10 <kalloc>
    8000160a:	892a                	mv	s2,a0
    8000160c:	c939                	beqz	a0,80001662 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000160e:	6605                	lui	a2,0x1
    80001610:	85de                	mv	a1,s7
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	746080e7          	jalr	1862(ra) # 80000d58 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000161a:	8726                	mv	a4,s1
    8000161c:	86ca                	mv	a3,s2
    8000161e:	6605                	lui	a2,0x1
    80001620:	85ce                	mv	a1,s3
    80001622:	8556                	mv	a0,s5
    80001624:	00000097          	auipc	ra,0x0
    80001628:	b06080e7          	jalr	-1274(ra) # 8000112a <mappages>
    8000162c:	e515                	bnez	a0,80001658 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000162e:	6785                	lui	a5,0x1
    80001630:	99be                	add	s3,s3,a5
    80001632:	fb49e6e3          	bltu	s3,s4,800015de <uvmcopy+0x20>
    80001636:	a081                	j	80001676 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001638:	00007517          	auipc	a0,0x7
    8000163c:	b4050513          	addi	a0,a0,-1216 # 80008178 <digits+0x138>
    80001640:	fffff097          	auipc	ra,0xfffff
    80001644:	f06080e7          	jalr	-250(ra) # 80000546 <panic>
      panic("uvmcopy: page not present");
    80001648:	00007517          	auipc	a0,0x7
    8000164c:	b5050513          	addi	a0,a0,-1200 # 80008198 <digits+0x158>
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	ef6080e7          	jalr	-266(ra) # 80000546 <panic>
      kfree(mem);
    80001658:	854a                	mv	a0,s2
    8000165a:	fffff097          	auipc	ra,0xfffff
    8000165e:	3b8080e7          	jalr	952(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001662:	4685                	li	a3,1
    80001664:	00c9d613          	srli	a2,s3,0xc
    80001668:	4581                	li	a1,0
    8000166a:	8556                	mv	a0,s5
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	c56080e7          	jalr	-938(ra) # 800012c2 <uvmunmap>
  return -1;
    80001674:	557d                	li	a0,-1
}
    80001676:	60a6                	ld	ra,72(sp)
    80001678:	6406                	ld	s0,64(sp)
    8000167a:	74e2                	ld	s1,56(sp)
    8000167c:	7942                	ld	s2,48(sp)
    8000167e:	79a2                	ld	s3,40(sp)
    80001680:	7a02                	ld	s4,32(sp)
    80001682:	6ae2                	ld	s5,24(sp)
    80001684:	6b42                	ld	s6,16(sp)
    80001686:	6ba2                	ld	s7,8(sp)
    80001688:	6161                	addi	sp,sp,80
    8000168a:	8082                	ret
  return 0;
    8000168c:	4501                	li	a0,0
}
    8000168e:	8082                	ret

0000000080001690 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001690:	1141                	addi	sp,sp,-16
    80001692:	e406                	sd	ra,8(sp)
    80001694:	e022                	sd	s0,0(sp)
    80001696:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001698:	4601                	li	a2,0
    8000169a:	00000097          	auipc	ra,0x0
    8000169e:	94a080e7          	jalr	-1718(ra) # 80000fe4 <walk>
  if(pte == 0)
    800016a2:	c901                	beqz	a0,800016b2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016a4:	611c                	ld	a5,0(a0)
    800016a6:	9bbd                	andi	a5,a5,-17
    800016a8:	e11c                	sd	a5,0(a0)
}
    800016aa:	60a2                	ld	ra,8(sp)
    800016ac:	6402                	ld	s0,0(sp)
    800016ae:	0141                	addi	sp,sp,16
    800016b0:	8082                	ret
    panic("uvmclear");
    800016b2:	00007517          	auipc	a0,0x7
    800016b6:	b0650513          	addi	a0,a0,-1274 # 800081b8 <digits+0x178>
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	e8c080e7          	jalr	-372(ra) # 80000546 <panic>

00000000800016c2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016c2:	c6bd                	beqz	a3,80001730 <copyout+0x6e>
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
    800016d8:	e062                	sd	s8,0(sp)
    800016da:	0880                	addi	s0,sp,80
    800016dc:	8b2a                	mv	s6,a0
    800016de:	8c2e                	mv	s8,a1
    800016e0:	8a32                	mv	s4,a2
    800016e2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016e4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016e6:	6a85                	lui	s5,0x1
    800016e8:	a015                	j	8000170c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ea:	9562                	add	a0,a0,s8
    800016ec:	0004861b          	sext.w	a2,s1
    800016f0:	85d2                	mv	a1,s4
    800016f2:	41250533          	sub	a0,a0,s2
    800016f6:	fffff097          	auipc	ra,0xfffff
    800016fa:	662080e7          	jalr	1634(ra) # 80000d58 <memmove>

    len -= n;
    800016fe:	409989b3          	sub	s3,s3,s1
    src += n;
    80001702:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001704:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001708:	02098263          	beqz	s3,8000172c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000170c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001710:	85ca                	mv	a1,s2
    80001712:	855a                	mv	a0,s6
    80001714:	00000097          	auipc	ra,0x0
    80001718:	976080e7          	jalr	-1674(ra) # 8000108a <walkaddr>
    if(pa0 == 0)
    8000171c:	cd01                	beqz	a0,80001734 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000171e:	418904b3          	sub	s1,s2,s8
    80001722:	94d6                	add	s1,s1,s5
    80001724:	fc99f3e3          	bgeu	s3,s1,800016ea <copyout+0x28>
    80001728:	84ce                	mv	s1,s3
    8000172a:	b7c1                	j	800016ea <copyout+0x28>
  }
  return 0;
    8000172c:	4501                	li	a0,0
    8000172e:	a021                	j	80001736 <copyout+0x74>
    80001730:	4501                	li	a0,0
}
    80001732:	8082                	ret
      return -1;
    80001734:	557d                	li	a0,-1
}
    80001736:	60a6                	ld	ra,72(sp)
    80001738:	6406                	ld	s0,64(sp)
    8000173a:	74e2                	ld	s1,56(sp)
    8000173c:	7942                	ld	s2,48(sp)
    8000173e:	79a2                	ld	s3,40(sp)
    80001740:	7a02                	ld	s4,32(sp)
    80001742:	6ae2                	ld	s5,24(sp)
    80001744:	6b42                	ld	s6,16(sp)
    80001746:	6ba2                	ld	s7,8(sp)
    80001748:	6c02                	ld	s8,0(sp)
    8000174a:	6161                	addi	sp,sp,80
    8000174c:	8082                	ret

000000008000174e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000174e:	caa5                	beqz	a3,800017be <copyin+0x70>
{
    80001750:	715d                	addi	sp,sp,-80
    80001752:	e486                	sd	ra,72(sp)
    80001754:	e0a2                	sd	s0,64(sp)
    80001756:	fc26                	sd	s1,56(sp)
    80001758:	f84a                	sd	s2,48(sp)
    8000175a:	f44e                	sd	s3,40(sp)
    8000175c:	f052                	sd	s4,32(sp)
    8000175e:	ec56                	sd	s5,24(sp)
    80001760:	e85a                	sd	s6,16(sp)
    80001762:	e45e                	sd	s7,8(sp)
    80001764:	e062                	sd	s8,0(sp)
    80001766:	0880                	addi	s0,sp,80
    80001768:	8b2a                	mv	s6,a0
    8000176a:	8a2e                	mv	s4,a1
    8000176c:	8c32                	mv	s8,a2
    8000176e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001770:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001772:	6a85                	lui	s5,0x1
    80001774:	a01d                	j	8000179a <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001776:	018505b3          	add	a1,a0,s8
    8000177a:	0004861b          	sext.w	a2,s1
    8000177e:	412585b3          	sub	a1,a1,s2
    80001782:	8552                	mv	a0,s4
    80001784:	fffff097          	auipc	ra,0xfffff
    80001788:	5d4080e7          	jalr	1492(ra) # 80000d58 <memmove>

    len -= n;
    8000178c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001790:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001792:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001796:	02098263          	beqz	s3,800017ba <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000179a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000179e:	85ca                	mv	a1,s2
    800017a0:	855a                	mv	a0,s6
    800017a2:	00000097          	auipc	ra,0x0
    800017a6:	8e8080e7          	jalr	-1816(ra) # 8000108a <walkaddr>
    if(pa0 == 0)
    800017aa:	cd01                	beqz	a0,800017c2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ac:	418904b3          	sub	s1,s2,s8
    800017b0:	94d6                	add	s1,s1,s5
    800017b2:	fc99f2e3          	bgeu	s3,s1,80001776 <copyin+0x28>
    800017b6:	84ce                	mv	s1,s3
    800017b8:	bf7d                	j	80001776 <copyin+0x28>
  }
  return 0;
    800017ba:	4501                	li	a0,0
    800017bc:	a021                	j	800017c4 <copyin+0x76>
    800017be:	4501                	li	a0,0
}
    800017c0:	8082                	ret
      return -1;
    800017c2:	557d                	li	a0,-1
}
    800017c4:	60a6                	ld	ra,72(sp)
    800017c6:	6406                	ld	s0,64(sp)
    800017c8:	74e2                	ld	s1,56(sp)
    800017ca:	7942                	ld	s2,48(sp)
    800017cc:	79a2                	ld	s3,40(sp)
    800017ce:	7a02                	ld	s4,32(sp)
    800017d0:	6ae2                	ld	s5,24(sp)
    800017d2:	6b42                	ld	s6,16(sp)
    800017d4:	6ba2                	ld	s7,8(sp)
    800017d6:	6c02                	ld	s8,0(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret

00000000800017dc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017dc:	c2dd                	beqz	a3,80001882 <copyinstr+0xa6>
{
    800017de:	715d                	addi	sp,sp,-80
    800017e0:	e486                	sd	ra,72(sp)
    800017e2:	e0a2                	sd	s0,64(sp)
    800017e4:	fc26                	sd	s1,56(sp)
    800017e6:	f84a                	sd	s2,48(sp)
    800017e8:	f44e                	sd	s3,40(sp)
    800017ea:	f052                	sd	s4,32(sp)
    800017ec:	ec56                	sd	s5,24(sp)
    800017ee:	e85a                	sd	s6,16(sp)
    800017f0:	e45e                	sd	s7,8(sp)
    800017f2:	0880                	addi	s0,sp,80
    800017f4:	8a2a                	mv	s4,a0
    800017f6:	8b2e                	mv	s6,a1
    800017f8:	8bb2                	mv	s7,a2
    800017fa:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017fc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017fe:	6985                	lui	s3,0x1
    80001800:	a02d                	j	8000182a <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001802:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001806:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001808:	37fd                	addiw	a5,a5,-1
    8000180a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000180e:	60a6                	ld	ra,72(sp)
    80001810:	6406                	ld	s0,64(sp)
    80001812:	74e2                	ld	s1,56(sp)
    80001814:	7942                	ld	s2,48(sp)
    80001816:	79a2                	ld	s3,40(sp)
    80001818:	7a02                	ld	s4,32(sp)
    8000181a:	6ae2                	ld	s5,24(sp)
    8000181c:	6b42                	ld	s6,16(sp)
    8000181e:	6ba2                	ld	s7,8(sp)
    80001820:	6161                	addi	sp,sp,80
    80001822:	8082                	ret
    srcva = va0 + PGSIZE;
    80001824:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001828:	c8a9                	beqz	s1,8000187a <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000182a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000182e:	85ca                	mv	a1,s2
    80001830:	8552                	mv	a0,s4
    80001832:	00000097          	auipc	ra,0x0
    80001836:	858080e7          	jalr	-1960(ra) # 8000108a <walkaddr>
    if(pa0 == 0)
    8000183a:	c131                	beqz	a0,8000187e <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000183c:	417906b3          	sub	a3,s2,s7
    80001840:	96ce                	add	a3,a3,s3
    80001842:	00d4f363          	bgeu	s1,a3,80001848 <copyinstr+0x6c>
    80001846:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001848:	955e                	add	a0,a0,s7
    8000184a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000184e:	daf9                	beqz	a3,80001824 <copyinstr+0x48>
    80001850:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001852:	41650633          	sub	a2,a0,s6
    80001856:	fff48593          	addi	a1,s1,-1
    8000185a:	95da                	add	a1,a1,s6
    while(n > 0){
    8000185c:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    8000185e:	00f60733          	add	a4,a2,a5
    80001862:	00074703          	lbu	a4,0(a4)
    80001866:	df51                	beqz	a4,80001802 <copyinstr+0x26>
        *dst = *p;
    80001868:	00e78023          	sb	a4,0(a5)
      --max;
    8000186c:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001870:	0785                	addi	a5,a5,1
    while(n > 0){
    80001872:	fed796e3          	bne	a5,a3,8000185e <copyinstr+0x82>
      dst++;
    80001876:	8b3e                	mv	s6,a5
    80001878:	b775                	j	80001824 <copyinstr+0x48>
    8000187a:	4781                	li	a5,0
    8000187c:	b771                	j	80001808 <copyinstr+0x2c>
      return -1;
    8000187e:	557d                	li	a0,-1
    80001880:	b779                	j	8000180e <copyinstr+0x32>
  int got_null = 0;
    80001882:	4781                	li	a5,0
  if(got_null){
    80001884:	37fd                	addiw	a5,a5,-1
    80001886:	0007851b          	sext.w	a0,a5
}
    8000188a:	8082                	ret

000000008000188c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000188c:	1101                	addi	sp,sp,-32
    8000188e:	ec06                	sd	ra,24(sp)
    80001890:	e822                	sd	s0,16(sp)
    80001892:	e426                	sd	s1,8(sp)
    80001894:	1000                	addi	s0,sp,32
    80001896:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001898:	fffff097          	auipc	ra,0xfffff
    8000189c:	2ee080e7          	jalr	750(ra) # 80000b86 <holding>
    800018a0:	c909                	beqz	a0,800018b2 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018a2:	749c                	ld	a5,40(s1)
    800018a4:	00978f63          	beq	a5,s1,800018c2 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018a8:	60e2                	ld	ra,24(sp)
    800018aa:	6442                	ld	s0,16(sp)
    800018ac:	64a2                	ld	s1,8(sp)
    800018ae:	6105                	addi	sp,sp,32
    800018b0:	8082                	ret
    panic("wakeup1");
    800018b2:	00007517          	auipc	a0,0x7
    800018b6:	91650513          	addi	a0,a0,-1770 # 800081c8 <digits+0x188>
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	c8c080e7          	jalr	-884(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018c2:	4c98                	lw	a4,24(s1)
    800018c4:	4785                	li	a5,1
    800018c6:	fef711e3          	bne	a4,a5,800018a8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018ca:	4789                	li	a5,2
    800018cc:	cc9c                	sw	a5,24(s1)
}
    800018ce:	bfe9                	j	800018a8 <wakeup1+0x1c>

00000000800018d0 <procinit>:
{
    800018d0:	715d                	addi	sp,sp,-80
    800018d2:	e486                	sd	ra,72(sp)
    800018d4:	e0a2                	sd	s0,64(sp)
    800018d6:	fc26                	sd	s1,56(sp)
    800018d8:	f84a                	sd	s2,48(sp)
    800018da:	f44e                	sd	s3,40(sp)
    800018dc:	f052                	sd	s4,32(sp)
    800018de:	ec56                	sd	s5,24(sp)
    800018e0:	e85a                	sd	s6,16(sp)
    800018e2:	e45e                	sd	s7,8(sp)
    800018e4:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018e6:	00007597          	auipc	a1,0x7
    800018ea:	8ea58593          	addi	a1,a1,-1814 # 800081d0 <digits+0x190>
    800018ee:	00010517          	auipc	a0,0x10
    800018f2:	06250513          	addi	a0,a0,98 # 80011950 <pid_lock>
    800018f6:	fffff097          	auipc	ra,0xfffff
    800018fa:	27a080e7          	jalr	634(ra) # 80000b70 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018fe:	00010917          	auipc	s2,0x10
    80001902:	46a90913          	addi	s2,s2,1130 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001906:	00007b97          	auipc	s7,0x7
    8000190a:	8d2b8b93          	addi	s7,s7,-1838 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000190e:	8b4a                	mv	s6,s2
    80001910:	00006a97          	auipc	s5,0x6
    80001914:	6f0a8a93          	addi	s5,s5,1776 # 80008000 <etext>
    80001918:	040009b7          	lui	s3,0x4000
    8000191c:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000191e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001920:	00016a17          	auipc	s4,0x16
    80001924:	048a0a13          	addi	s4,s4,72 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001928:	85de                	mv	a1,s7
    8000192a:	854a                	mv	a0,s2
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	244080e7          	jalr	580(ra) # 80000b70 <initlock>
      char *pa = kalloc();
    80001934:	fffff097          	auipc	ra,0xfffff
    80001938:	1dc080e7          	jalr	476(ra) # 80000b10 <kalloc>
    8000193c:	85aa                	mv	a1,a0
      if(pa == 0)
    8000193e:	c929                	beqz	a0,80001990 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001940:	416904b3          	sub	s1,s2,s6
    80001944:	8491                	srai	s1,s1,0x4
    80001946:	000ab783          	ld	a5,0(s5)
    8000194a:	02f484b3          	mul	s1,s1,a5
    8000194e:	2485                	addiw	s1,s1,1
    80001950:	00d4949b          	slliw	s1,s1,0xd
    80001954:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001958:	4699                	li	a3,6
    8000195a:	6605                	lui	a2,0x1
    8000195c:	8526                	mv	a0,s1
    8000195e:	00000097          	auipc	ra,0x0
    80001962:	85a080e7          	jalr	-1958(ra) # 800011b8 <kvmmap>
      p->kstack = va;
    80001966:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	17090913          	addi	s2,s2,368
    8000196e:	fb491de3          	bne	s2,s4,80001928 <procinit+0x58>
  kvminithart();
    80001972:	fffff097          	auipc	ra,0xfffff
    80001976:	64e080e7          	jalr	1614(ra) # 80000fc0 <kvminithart>
}
    8000197a:	60a6                	ld	ra,72(sp)
    8000197c:	6406                	ld	s0,64(sp)
    8000197e:	74e2                	ld	s1,56(sp)
    80001980:	7942                	ld	s2,48(sp)
    80001982:	79a2                	ld	s3,40(sp)
    80001984:	7a02                	ld	s4,32(sp)
    80001986:	6ae2                	ld	s5,24(sp)
    80001988:	6b42                	ld	s6,16(sp)
    8000198a:	6ba2                	ld	s7,8(sp)
    8000198c:	6161                	addi	sp,sp,80
    8000198e:	8082                	ret
        panic("kalloc");
    80001990:	00007517          	auipc	a0,0x7
    80001994:	85050513          	addi	a0,a0,-1968 # 800081e0 <digits+0x1a0>
    80001998:	fffff097          	auipc	ra,0xfffff
    8000199c:	bae080e7          	jalr	-1106(ra) # 80000546 <panic>

00000000800019a0 <cpuid>:
{
    800019a0:	1141                	addi	sp,sp,-16
    800019a2:	e422                	sd	s0,8(sp)
    800019a4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a6:	8512                	mv	a0,tp
}
    800019a8:	2501                	sext.w	a0,a0
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <mycpu>:
mycpu(void) {
    800019b0:	1141                	addi	sp,sp,-16
    800019b2:	e422                	sd	s0,8(sp)
    800019b4:	0800                	addi	s0,sp,16
    800019b6:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019b8:	2781                	sext.w	a5,a5
    800019ba:	079e                	slli	a5,a5,0x7
}
    800019bc:	00010517          	auipc	a0,0x10
    800019c0:	fac50513          	addi	a0,a0,-84 # 80011968 <cpus>
    800019c4:	953e                	add	a0,a0,a5
    800019c6:	6422                	ld	s0,8(sp)
    800019c8:	0141                	addi	sp,sp,16
    800019ca:	8082                	ret

00000000800019cc <myproc>:
myproc(void) {
    800019cc:	1101                	addi	sp,sp,-32
    800019ce:	ec06                	sd	ra,24(sp)
    800019d0:	e822                	sd	s0,16(sp)
    800019d2:	e426                	sd	s1,8(sp)
    800019d4:	1000                	addi	s0,sp,32
  push_off();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	1de080e7          	jalr	478(ra) # 80000bb4 <push_off>
    800019de:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019e0:	2781                	sext.w	a5,a5
    800019e2:	079e                	slli	a5,a5,0x7
    800019e4:	00010717          	auipc	a4,0x10
    800019e8:	f6c70713          	addi	a4,a4,-148 # 80011950 <pid_lock>
    800019ec:	97ba                	add	a5,a5,a4
    800019ee:	6f84                	ld	s1,24(a5)
  pop_off();
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	264080e7          	jalr	612(ra) # 80000c54 <pop_off>
}
    800019f8:	8526                	mv	a0,s1
    800019fa:	60e2                	ld	ra,24(sp)
    800019fc:	6442                	ld	s0,16(sp)
    800019fe:	64a2                	ld	s1,8(sp)
    80001a00:	6105                	addi	sp,sp,32
    80001a02:	8082                	ret

0000000080001a04 <forkret>:
{
    80001a04:	1141                	addi	sp,sp,-16
    80001a06:	e406                	sd	ra,8(sp)
    80001a08:	e022                	sd	s0,0(sp)
    80001a0a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a0c:	00000097          	auipc	ra,0x0
    80001a10:	fc0080e7          	jalr	-64(ra) # 800019cc <myproc>
    80001a14:	fffff097          	auipc	ra,0xfffff
    80001a18:	2a0080e7          	jalr	672(ra) # 80000cb4 <release>
  if (first) {
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	eb47a783          	lw	a5,-332(a5) # 800088d0 <first.1>
    80001a24:	eb89                	bnez	a5,80001a36 <forkret+0x32>
  usertrapret();
    80001a26:	00001097          	auipc	ra,0x1
    80001a2a:	c46080e7          	jalr	-954(ra) # 8000266c <usertrapret>
}
    80001a2e:	60a2                	ld	ra,8(sp)
    80001a30:	6402                	ld	s0,0(sp)
    80001a32:	0141                	addi	sp,sp,16
    80001a34:	8082                	ret
    first = 0;
    80001a36:	00007797          	auipc	a5,0x7
    80001a3a:	e807ad23          	sw	zero,-358(a5) # 800088d0 <first.1>
    fsinit(ROOTDEV);
    80001a3e:	4505                	li	a0,1
    80001a40:	00002097          	auipc	ra,0x2
    80001a44:	9f2080e7          	jalr	-1550(ra) # 80003432 <fsinit>
    80001a48:	bff9                	j	80001a26 <forkret+0x22>

0000000080001a4a <allocpid>:
allocpid() {
    80001a4a:	1101                	addi	sp,sp,-32
    80001a4c:	ec06                	sd	ra,24(sp)
    80001a4e:	e822                	sd	s0,16(sp)
    80001a50:	e426                	sd	s1,8(sp)
    80001a52:	e04a                	sd	s2,0(sp)
    80001a54:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a56:	00010917          	auipc	s2,0x10
    80001a5a:	efa90913          	addi	s2,s2,-262 # 80011950 <pid_lock>
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	1a0080e7          	jalr	416(ra) # 80000c00 <acquire>
  pid = nextpid;
    80001a68:	00007797          	auipc	a5,0x7
    80001a6c:	e6c78793          	addi	a5,a5,-404 # 800088d4 <nextpid>
    80001a70:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a72:	0014871b          	addiw	a4,s1,1
    80001a76:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a78:	854a                	mv	a0,s2
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	23a080e7          	jalr	570(ra) # 80000cb4 <release>
}
    80001a82:	8526                	mv	a0,s1
    80001a84:	60e2                	ld	ra,24(sp)
    80001a86:	6442                	ld	s0,16(sp)
    80001a88:	64a2                	ld	s1,8(sp)
    80001a8a:	6902                	ld	s2,0(sp)
    80001a8c:	6105                	addi	sp,sp,32
    80001a8e:	8082                	ret

0000000080001a90 <proc_pagetable>:
{
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	e04a                	sd	s2,0(sp)
    80001a9a:	1000                	addi	s0,sp,32
    80001a9c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a9e:	00000097          	auipc	ra,0x0
    80001aa2:	8e8080e7          	jalr	-1816(ra) # 80001386 <uvmcreate>
    80001aa6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa8:	c121                	beqz	a0,80001ae8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aaa:	4729                	li	a4,10
    80001aac:	00005697          	auipc	a3,0x5
    80001ab0:	55468693          	addi	a3,a3,1364 # 80007000 <_trampoline>
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	040005b7          	lui	a1,0x4000
    80001aba:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001abc:	05b2                	slli	a1,a1,0xc
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	66c080e7          	jalr	1644(ra) # 8000112a <mappages>
    80001ac6:	02054863          	bltz	a0,80001af6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aca:	4719                	li	a4,6
    80001acc:	05893683          	ld	a3,88(s2)
    80001ad0:	6605                	lui	a2,0x1
    80001ad2:	020005b7          	lui	a1,0x2000
    80001ad6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ad8:	05b6                	slli	a1,a1,0xd
    80001ada:	8526                	mv	a0,s1
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	64e080e7          	jalr	1614(ra) # 8000112a <mappages>
    80001ae4:	02054163          	bltz	a0,80001b06 <proc_pagetable+0x76>
}
    80001ae8:	8526                	mv	a0,s1
    80001aea:	60e2                	ld	ra,24(sp)
    80001aec:	6442                	ld	s0,16(sp)
    80001aee:	64a2                	ld	s1,8(sp)
    80001af0:	6902                	ld	s2,0(sp)
    80001af2:	6105                	addi	sp,sp,32
    80001af4:	8082                	ret
    uvmfree(pagetable, 0);
    80001af6:	4581                	li	a1,0
    80001af8:	8526                	mv	a0,s1
    80001afa:	00000097          	auipc	ra,0x0
    80001afe:	a8a080e7          	jalr	-1398(ra) # 80001584 <uvmfree>
    return 0;
    80001b02:	4481                	li	s1,0
    80001b04:	b7d5                	j	80001ae8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b06:	4681                	li	a3,0
    80001b08:	4605                	li	a2,1
    80001b0a:	040005b7          	lui	a1,0x4000
    80001b0e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b10:	05b2                	slli	a1,a1,0xc
    80001b12:	8526                	mv	a0,s1
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	7ae080e7          	jalr	1966(ra) # 800012c2 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b1c:	4581                	li	a1,0
    80001b1e:	8526                	mv	a0,s1
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	a64080e7          	jalr	-1436(ra) # 80001584 <uvmfree>
    return 0;
    80001b28:	4481                	li	s1,0
    80001b2a:	bf7d                	j	80001ae8 <proc_pagetable+0x58>

0000000080001b2c <proc_freepagetable>:
{
    80001b2c:	1101                	addi	sp,sp,-32
    80001b2e:	ec06                	sd	ra,24(sp)
    80001b30:	e822                	sd	s0,16(sp)
    80001b32:	e426                	sd	s1,8(sp)
    80001b34:	e04a                	sd	s2,0(sp)
    80001b36:	1000                	addi	s0,sp,32
    80001b38:	84aa                	mv	s1,a0
    80001b3a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	fffff097          	auipc	ra,0xfffff
    80001b4c:	77a080e7          	jalr	1914(ra) # 800012c2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b50:	4681                	li	a3,0
    80001b52:	4605                	li	a2,1
    80001b54:	020005b7          	lui	a1,0x2000
    80001b58:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b5a:	05b6                	slli	a1,a1,0xd
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	764080e7          	jalr	1892(ra) # 800012c2 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b66:	85ca                	mv	a1,s2
    80001b68:	8526                	mv	a0,s1
    80001b6a:	00000097          	auipc	ra,0x0
    80001b6e:	a1a080e7          	jalr	-1510(ra) # 80001584 <uvmfree>
}
    80001b72:	60e2                	ld	ra,24(sp)
    80001b74:	6442                	ld	s0,16(sp)
    80001b76:	64a2                	ld	s1,8(sp)
    80001b78:	6902                	ld	s2,0(sp)
    80001b7a:	6105                	addi	sp,sp,32
    80001b7c:	8082                	ret

0000000080001b7e <freeproc>:
{
    80001b7e:	1101                	addi	sp,sp,-32
    80001b80:	ec06                	sd	ra,24(sp)
    80001b82:	e822                	sd	s0,16(sp)
    80001b84:	e426                	sd	s1,8(sp)
    80001b86:	1000                	addi	s0,sp,32
    80001b88:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b8a:	6d28                	ld	a0,88(a0)
    80001b8c:	c509                	beqz	a0,80001b96 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	e84080e7          	jalr	-380(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001b96:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b9a:	68a8                	ld	a0,80(s1)
    80001b9c:	c511                	beqz	a0,80001ba8 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b9e:	64ac                	ld	a1,72(s1)
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	f8c080e7          	jalr	-116(ra) # 80001b2c <proc_freepagetable>
  p->pagetable = 0;
    80001ba8:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bac:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bb0:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bb4:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bb8:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bbc:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bc0:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bc4:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bc8:	0004ac23          	sw	zero,24(s1)
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <allocproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001be2:	00010497          	auipc	s1,0x10
    80001be6:	18648493          	addi	s1,s1,390 # 80011d68 <proc>
    80001bea:	00016917          	auipc	s2,0x16
    80001bee:	d7e90913          	addi	s2,s2,-642 # 80017968 <tickslock>
    acquire(&p->lock);
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	00c080e7          	jalr	12(ra) # 80000c00 <acquire>
    if(p->state == UNUSED) {
    80001bfc:	4c9c                	lw	a5,24(s1)
    80001bfe:	cf81                	beqz	a5,80001c16 <allocproc+0x40>
      release(&p->lock);
    80001c00:	8526                	mv	a0,s1
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	0b2080e7          	jalr	178(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c0a:	17048493          	addi	s1,s1,368
    80001c0e:	ff2492e3          	bne	s1,s2,80001bf2 <allocproc+0x1c>
  return 0;
    80001c12:	4481                	li	s1,0
    80001c14:	a0b9                	j	80001c62 <allocproc+0x8c>
  p->pid = allocpid();
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	e34080e7          	jalr	-460(ra) # 80001a4a <allocpid>
    80001c1e:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	ef0080e7          	jalr	-272(ra) # 80000b10 <kalloc>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	eca8                	sd	a0,88(s1)
    80001c2c:	c131                	beqz	a0,80001c70 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	e60080e7          	jalr	-416(ra) # 80001a90 <proc_pagetable>
    80001c38:	892a                	mv	s2,a0
    80001c3a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3c:	c129                	beqz	a0,80001c7e <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c3e:	07000613          	li	a2,112
    80001c42:	4581                	li	a1,0
    80001c44:	06048513          	addi	a0,s1,96
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	0b4080e7          	jalr	180(ra) # 80000cfc <memset>
  p->context.ra = (uint64)forkret;
    80001c50:	00000797          	auipc	a5,0x0
    80001c54:	db478793          	addi	a5,a5,-588 # 80001a04 <forkret>
    80001c58:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5a:	60bc                	ld	a5,64(s1)
    80001c5c:	6705                	lui	a4,0x1
    80001c5e:	97ba                	add	a5,a5,a4
    80001c60:	f4bc                	sd	a5,104(s1)
}
    80001c62:	8526                	mv	a0,s1
    80001c64:	60e2                	ld	ra,24(sp)
    80001c66:	6442                	ld	s0,16(sp)
    80001c68:	64a2                	ld	s1,8(sp)
    80001c6a:	6902                	ld	s2,0(sp)
    80001c6c:	6105                	addi	sp,sp,32
    80001c6e:	8082                	ret
    release(&p->lock);
    80001c70:	8526                	mv	a0,s1
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	042080e7          	jalr	66(ra) # 80000cb4 <release>
    return 0;
    80001c7a:	84ca                	mv	s1,s2
    80001c7c:	b7dd                	j	80001c62 <allocproc+0x8c>
    freeproc(p);
    80001c7e:	8526                	mv	a0,s1
    80001c80:	00000097          	auipc	ra,0x0
    80001c84:	efe080e7          	jalr	-258(ra) # 80001b7e <freeproc>
    release(&p->lock);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	fffff097          	auipc	ra,0xfffff
    80001c8e:	02a080e7          	jalr	42(ra) # 80000cb4 <release>
    return 0;
    80001c92:	84ca                	mv	s1,s2
    80001c94:	b7f9                	j	80001c62 <allocproc+0x8c>

0000000080001c96 <userinit>:
{
    80001c96:	1101                	addi	sp,sp,-32
    80001c98:	ec06                	sd	ra,24(sp)
    80001c9a:	e822                	sd	s0,16(sp)
    80001c9c:	e426                	sd	s1,8(sp)
    80001c9e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca0:	00000097          	auipc	ra,0x0
    80001ca4:	f36080e7          	jalr	-202(ra) # 80001bd6 <allocproc>
    80001ca8:	84aa                	mv	s1,a0
  initproc = p;
    80001caa:	00007797          	auipc	a5,0x7
    80001cae:	36a7b723          	sd	a0,878(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb2:	03400613          	li	a2,52
    80001cb6:	00007597          	auipc	a1,0x7
    80001cba:	c2a58593          	addi	a1,a1,-982 # 800088e0 <initcode>
    80001cbe:	6928                	ld	a0,80(a0)
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	6f4080e7          	jalr	1780(ra) # 800013b4 <uvminit>
  p->sz = PGSIZE;
    80001cc8:	6785                	lui	a5,0x1
    80001cca:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001ccc:	6cb8                	ld	a4,88(s1)
    80001cce:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd2:	6cb8                	ld	a4,88(s1)
    80001cd4:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd6:	4641                	li	a2,16
    80001cd8:	00006597          	auipc	a1,0x6
    80001cdc:	51058593          	addi	a1,a1,1296 # 800081e8 <digits+0x1a8>
    80001ce0:	15848513          	addi	a0,s1,344
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	16a080e7          	jalr	362(ra) # 80000e4e <safestrcpy>
  p->cwd = namei("/");
    80001cec:	00006517          	auipc	a0,0x6
    80001cf0:	50c50513          	addi	a0,a0,1292 # 800081f8 <digits+0x1b8>
    80001cf4:	00002097          	auipc	ra,0x2
    80001cf8:	16e080e7          	jalr	366(ra) # 80003e62 <namei>
    80001cfc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d00:	4789                	li	a5,2
    80001d02:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	fae080e7          	jalr	-82(ra) # 80000cb4 <release>
}
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6105                	addi	sp,sp,32
    80001d16:	8082                	ret

0000000080001d18 <growproc>:
{
    80001d18:	1101                	addi	sp,sp,-32
    80001d1a:	ec06                	sd	ra,24(sp)
    80001d1c:	e822                	sd	s0,16(sp)
    80001d1e:	e426                	sd	s1,8(sp)
    80001d20:	e04a                	sd	s2,0(sp)
    80001d22:	1000                	addi	s0,sp,32
    80001d24:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d26:	00000097          	auipc	ra,0x0
    80001d2a:	ca6080e7          	jalr	-858(ra) # 800019cc <myproc>
    80001d2e:	892a                	mv	s2,a0
  sz = p->sz;
    80001d30:	652c                	ld	a1,72(a0)
    80001d32:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d36:	00904f63          	bgtz	s1,80001d54 <growproc+0x3c>
  } else if(n < 0){
    80001d3a:	0204cd63          	bltz	s1,80001d74 <growproc+0x5c>
  p->sz = sz;
    80001d3e:	1782                	slli	a5,a5,0x20
    80001d40:	9381                	srli	a5,a5,0x20
    80001d42:	04f93423          	sd	a5,72(s2)
  return 0;
    80001d46:	4501                	li	a0,0
}
    80001d48:	60e2                	ld	ra,24(sp)
    80001d4a:	6442                	ld	s0,16(sp)
    80001d4c:	64a2                	ld	s1,8(sp)
    80001d4e:	6902                	ld	s2,0(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d54:	00f4863b          	addw	a2,s1,a5
    80001d58:	1602                	slli	a2,a2,0x20
    80001d5a:	9201                	srli	a2,a2,0x20
    80001d5c:	1582                	slli	a1,a1,0x20
    80001d5e:	9181                	srli	a1,a1,0x20
    80001d60:	6928                	ld	a0,80(a0)
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	70c080e7          	jalr	1804(ra) # 8000146e <uvmalloc>
    80001d6a:	0005079b          	sext.w	a5,a0
    80001d6e:	fbe1                	bnez	a5,80001d3e <growproc+0x26>
      return -1;
    80001d70:	557d                	li	a0,-1
    80001d72:	bfd9                	j	80001d48 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d74:	00f4863b          	addw	a2,s1,a5
    80001d78:	1602                	slli	a2,a2,0x20
    80001d7a:	9201                	srli	a2,a2,0x20
    80001d7c:	1582                	slli	a1,a1,0x20
    80001d7e:	9181                	srli	a1,a1,0x20
    80001d80:	6928                	ld	a0,80(a0)
    80001d82:	fffff097          	auipc	ra,0xfffff
    80001d86:	6a4080e7          	jalr	1700(ra) # 80001426 <uvmdealloc>
    80001d8a:	0005079b          	sext.w	a5,a0
    80001d8e:	bf45                	j	80001d3e <growproc+0x26>

0000000080001d90 <fork>:
{
    80001d90:	7139                	addi	sp,sp,-64
    80001d92:	fc06                	sd	ra,56(sp)
    80001d94:	f822                	sd	s0,48(sp)
    80001d96:	f426                	sd	s1,40(sp)
    80001d98:	f04a                	sd	s2,32(sp)
    80001d9a:	ec4e                	sd	s3,24(sp)
    80001d9c:	e852                	sd	s4,16(sp)
    80001d9e:	e456                	sd	s5,8(sp)
    80001da0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001da2:	00000097          	auipc	ra,0x0
    80001da6:	c2a080e7          	jalr	-982(ra) # 800019cc <myproc>
    80001daa:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	e2a080e7          	jalr	-470(ra) # 80001bd6 <allocproc>
    80001db4:	c57d                	beqz	a0,80001ea2 <fork+0x112>
    80001db6:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001db8:	048ab603          	ld	a2,72(s5)
    80001dbc:	692c                	ld	a1,80(a0)
    80001dbe:	050ab503          	ld	a0,80(s5)
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	7fc080e7          	jalr	2044(ra) # 800015be <uvmcopy>
    80001dca:	04054e63          	bltz	a0,80001e26 <fork+0x96>
  np->sz = p->sz;
    80001dce:	048ab783          	ld	a5,72(s5)
    80001dd2:	04fa3423          	sd	a5,72(s4)
  np->mask = p->mask;
    80001dd6:	168aa783          	lw	a5,360(s5)
    80001dda:	16fa2423          	sw	a5,360(s4)
  np->parent = p;
    80001dde:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de2:	058ab683          	ld	a3,88(s5)
    80001de6:	87b6                	mv	a5,a3
    80001de8:	058a3703          	ld	a4,88(s4)
    80001dec:	12068693          	addi	a3,a3,288
    80001df0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df4:	6788                	ld	a0,8(a5)
    80001df6:	6b8c                	ld	a1,16(a5)
    80001df8:	6f90                	ld	a2,24(a5)
    80001dfa:	01073023          	sd	a6,0(a4)
    80001dfe:	e708                	sd	a0,8(a4)
    80001e00:	eb0c                	sd	a1,16(a4)
    80001e02:	ef10                	sd	a2,24(a4)
    80001e04:	02078793          	addi	a5,a5,32
    80001e08:	02070713          	addi	a4,a4,32
    80001e0c:	fed792e3          	bne	a5,a3,80001df0 <fork+0x60>
  np->trapframe->a0 = 0;
    80001e10:	058a3783          	ld	a5,88(s4)
    80001e14:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e18:	0d0a8493          	addi	s1,s5,208
    80001e1c:	0d0a0913          	addi	s2,s4,208
    80001e20:	150a8993          	addi	s3,s5,336
    80001e24:	a00d                	j	80001e46 <fork+0xb6>
    freeproc(np);
    80001e26:	8552                	mv	a0,s4
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	d56080e7          	jalr	-682(ra) # 80001b7e <freeproc>
    release(&np->lock);
    80001e30:	8552                	mv	a0,s4
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e82080e7          	jalr	-382(ra) # 80000cb4 <release>
    return -1;
    80001e3a:	54fd                	li	s1,-1
    80001e3c:	a889                	j	80001e8e <fork+0xfe>
  for(i = 0; i < NOFILE; i++)
    80001e3e:	04a1                	addi	s1,s1,8
    80001e40:	0921                	addi	s2,s2,8
    80001e42:	01348b63          	beq	s1,s3,80001e58 <fork+0xc8>
    if(p->ofile[i])
    80001e46:	6088                	ld	a0,0(s1)
    80001e48:	d97d                	beqz	a0,80001e3e <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	6a4080e7          	jalr	1700(ra) # 800044ee <filedup>
    80001e52:	00a93023          	sd	a0,0(s2)
    80001e56:	b7e5                	j	80001e3e <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e58:	150ab503          	ld	a0,336(s5)
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	812080e7          	jalr	-2030(ra) # 8000366e <idup>
    80001e64:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e68:	4641                	li	a2,16
    80001e6a:	158a8593          	addi	a1,s5,344
    80001e6e:	158a0513          	addi	a0,s4,344
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	fdc080e7          	jalr	-36(ra) # 80000e4e <safestrcpy>
  pid = np->pid;
    80001e7a:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e7e:	4789                	li	a5,2
    80001e80:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e84:	8552                	mv	a0,s4
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	e2e080e7          	jalr	-466(ra) # 80000cb4 <release>
}
    80001e8e:	8526                	mv	a0,s1
    80001e90:	70e2                	ld	ra,56(sp)
    80001e92:	7442                	ld	s0,48(sp)
    80001e94:	74a2                	ld	s1,40(sp)
    80001e96:	7902                	ld	s2,32(sp)
    80001e98:	69e2                	ld	s3,24(sp)
    80001e9a:	6a42                	ld	s4,16(sp)
    80001e9c:	6aa2                	ld	s5,8(sp)
    80001e9e:	6121                	addi	sp,sp,64
    80001ea0:	8082                	ret
    return -1;
    80001ea2:	54fd                	li	s1,-1
    80001ea4:	b7ed                	j	80001e8e <fork+0xfe>

0000000080001ea6 <reparent>:
{
    80001ea6:	7179                	addi	sp,sp,-48
    80001ea8:	f406                	sd	ra,40(sp)
    80001eaa:	f022                	sd	s0,32(sp)
    80001eac:	ec26                	sd	s1,24(sp)
    80001eae:	e84a                	sd	s2,16(sp)
    80001eb0:	e44e                	sd	s3,8(sp)
    80001eb2:	e052                	sd	s4,0(sp)
    80001eb4:	1800                	addi	s0,sp,48
    80001eb6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eb8:	00010497          	auipc	s1,0x10
    80001ebc:	eb048493          	addi	s1,s1,-336 # 80011d68 <proc>
      pp->parent = initproc;
    80001ec0:	00007a17          	auipc	s4,0x7
    80001ec4:	158a0a13          	addi	s4,s4,344 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001ec8:	00016997          	auipc	s3,0x16
    80001ecc:	aa098993          	addi	s3,s3,-1376 # 80017968 <tickslock>
    80001ed0:	a029                	j	80001eda <reparent+0x34>
    80001ed2:	17048493          	addi	s1,s1,368
    80001ed6:	03348363          	beq	s1,s3,80001efc <reparent+0x56>
    if(pp->parent == p){
    80001eda:	709c                	ld	a5,32(s1)
    80001edc:	ff279be3          	bne	a5,s2,80001ed2 <reparent+0x2c>
      acquire(&pp->lock);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	d1e080e7          	jalr	-738(ra) # 80000c00 <acquire>
      pp->parent = initproc;
    80001eea:	000a3783          	ld	a5,0(s4)
    80001eee:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ef0:	8526                	mv	a0,s1
    80001ef2:	fffff097          	auipc	ra,0xfffff
    80001ef6:	dc2080e7          	jalr	-574(ra) # 80000cb4 <release>
    80001efa:	bfe1                	j	80001ed2 <reparent+0x2c>
}
    80001efc:	70a2                	ld	ra,40(sp)
    80001efe:	7402                	ld	s0,32(sp)
    80001f00:	64e2                	ld	s1,24(sp)
    80001f02:	6942                	ld	s2,16(sp)
    80001f04:	69a2                	ld	s3,8(sp)
    80001f06:	6a02                	ld	s4,0(sp)
    80001f08:	6145                	addi	sp,sp,48
    80001f0a:	8082                	ret

0000000080001f0c <scheduler>:
{
    80001f0c:	715d                	addi	sp,sp,-80
    80001f0e:	e486                	sd	ra,72(sp)
    80001f10:	e0a2                	sd	s0,64(sp)
    80001f12:	fc26                	sd	s1,56(sp)
    80001f14:	f84a                	sd	s2,48(sp)
    80001f16:	f44e                	sd	s3,40(sp)
    80001f18:	f052                	sd	s4,32(sp)
    80001f1a:	ec56                	sd	s5,24(sp)
    80001f1c:	e85a                	sd	s6,16(sp)
    80001f1e:	e45e                	sd	s7,8(sp)
    80001f20:	e062                	sd	s8,0(sp)
    80001f22:	0880                	addi	s0,sp,80
    80001f24:	8792                	mv	a5,tp
  int id = r_tp();
    80001f26:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f28:	00779b13          	slli	s6,a5,0x7
    80001f2c:	00010717          	auipc	a4,0x10
    80001f30:	a2470713          	addi	a4,a4,-1500 # 80011950 <pid_lock>
    80001f34:	975a                	add	a4,a4,s6
    80001f36:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f3a:	00010717          	auipc	a4,0x10
    80001f3e:	a3670713          	addi	a4,a4,-1482 # 80011970 <cpus+0x8>
    80001f42:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f44:	4c0d                	li	s8,3
        c->proc = p;
    80001f46:	079e                	slli	a5,a5,0x7
    80001f48:	00010a17          	auipc	s4,0x10
    80001f4c:	a08a0a13          	addi	s4,s4,-1528 # 80011950 <pid_lock>
    80001f50:	9a3e                	add	s4,s4,a5
        found = 1;
    80001f52:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f54:	00016997          	auipc	s3,0x16
    80001f58:	a1498993          	addi	s3,s3,-1516 # 80017968 <tickslock>
    80001f5c:	a899                	j	80001fb2 <scheduler+0xa6>
      release(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d54080e7          	jalr	-684(ra) # 80000cb4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f68:	17048493          	addi	s1,s1,368
    80001f6c:	03348963          	beq	s1,s3,80001f9e <scheduler+0x92>
      acquire(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	c8e080e7          	jalr	-882(ra) # 80000c00 <acquire>
      if(p->state == RUNNABLE) {
    80001f7a:	4c9c                	lw	a5,24(s1)
    80001f7c:	ff2791e3          	bne	a5,s2,80001f5e <scheduler+0x52>
        p->state = RUNNING;
    80001f80:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f84:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f88:	06048593          	addi	a1,s1,96
    80001f8c:	855a                	mv	a0,s6
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	634080e7          	jalr	1588(ra) # 800025c2 <swtch>
        c->proc = 0;
    80001f96:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001f9a:	8ade                	mv	s5,s7
    80001f9c:	b7c9                	j	80001f5e <scheduler+0x52>
    if(found == 0) {
    80001f9e:	000a9a63          	bnez	s5,80001fb2 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fa2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fa6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001faa:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fae:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fba:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001fbe:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc0:	00010497          	auipc	s1,0x10
    80001fc4:	da848493          	addi	s1,s1,-600 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001fc8:	4909                	li	s2,2
    80001fca:	b75d                	j	80001f70 <scheduler+0x64>

0000000080001fcc <sched>:
{
    80001fcc:	7179                	addi	sp,sp,-48
    80001fce:	f406                	sd	ra,40(sp)
    80001fd0:	f022                	sd	s0,32(sp)
    80001fd2:	ec26                	sd	s1,24(sp)
    80001fd4:	e84a                	sd	s2,16(sp)
    80001fd6:	e44e                	sd	s3,8(sp)
    80001fd8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	9f2080e7          	jalr	-1550(ra) # 800019cc <myproc>
    80001fe2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	ba2080e7          	jalr	-1118(ra) # 80000b86 <holding>
    80001fec:	c93d                	beqz	a0,80002062 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	00010717          	auipc	a4,0x10
    80001ff8:	95c70713          	addi	a4,a4,-1700 # 80011950 <pid_lock>
    80001ffc:	97ba                	add	a5,a5,a4
    80001ffe:	0907a703          	lw	a4,144(a5)
    80002002:	4785                	li	a5,1
    80002004:	06f71763          	bne	a4,a5,80002072 <sched+0xa6>
  if(p->state == RUNNING)
    80002008:	4c98                	lw	a4,24(s1)
    8000200a:	478d                	li	a5,3
    8000200c:	06f70b63          	beq	a4,a5,80002082 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002010:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002014:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002016:	efb5                	bnez	a5,80002092 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002018:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000201a:	00010917          	auipc	s2,0x10
    8000201e:	93690913          	addi	s2,s2,-1738 # 80011950 <pid_lock>
    80002022:	2781                	sext.w	a5,a5
    80002024:	079e                	slli	a5,a5,0x7
    80002026:	97ca                	add	a5,a5,s2
    80002028:	0947a983          	lw	s3,148(a5)
    8000202c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000202e:	2781                	sext.w	a5,a5
    80002030:	079e                	slli	a5,a5,0x7
    80002032:	00010597          	auipc	a1,0x10
    80002036:	93e58593          	addi	a1,a1,-1730 # 80011970 <cpus+0x8>
    8000203a:	95be                	add	a1,a1,a5
    8000203c:	06048513          	addi	a0,s1,96
    80002040:	00000097          	auipc	ra,0x0
    80002044:	582080e7          	jalr	1410(ra) # 800025c2 <swtch>
    80002048:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	993e                	add	s2,s2,a5
    80002050:	09392a23          	sw	s3,148(s2)
}
    80002054:	70a2                	ld	ra,40(sp)
    80002056:	7402                	ld	s0,32(sp)
    80002058:	64e2                	ld	s1,24(sp)
    8000205a:	6942                	ld	s2,16(sp)
    8000205c:	69a2                	ld	s3,8(sp)
    8000205e:	6145                	addi	sp,sp,48
    80002060:	8082                	ret
    panic("sched p->lock");
    80002062:	00006517          	auipc	a0,0x6
    80002066:	19e50513          	addi	a0,a0,414 # 80008200 <digits+0x1c0>
    8000206a:	ffffe097          	auipc	ra,0xffffe
    8000206e:	4dc080e7          	jalr	1244(ra) # 80000546 <panic>
    panic("sched locks");
    80002072:	00006517          	auipc	a0,0x6
    80002076:	19e50513          	addi	a0,a0,414 # 80008210 <digits+0x1d0>
    8000207a:	ffffe097          	auipc	ra,0xffffe
    8000207e:	4cc080e7          	jalr	1228(ra) # 80000546 <panic>
    panic("sched running");
    80002082:	00006517          	auipc	a0,0x6
    80002086:	19e50513          	addi	a0,a0,414 # 80008220 <digits+0x1e0>
    8000208a:	ffffe097          	auipc	ra,0xffffe
    8000208e:	4bc080e7          	jalr	1212(ra) # 80000546 <panic>
    panic("sched interruptible");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	19e50513          	addi	a0,a0,414 # 80008230 <digits+0x1f0>
    8000209a:	ffffe097          	auipc	ra,0xffffe
    8000209e:	4ac080e7          	jalr	1196(ra) # 80000546 <panic>

00000000800020a2 <exit>:
{
    800020a2:	7179                	addi	sp,sp,-48
    800020a4:	f406                	sd	ra,40(sp)
    800020a6:	f022                	sd	s0,32(sp)
    800020a8:	ec26                	sd	s1,24(sp)
    800020aa:	e84a                	sd	s2,16(sp)
    800020ac:	e44e                	sd	s3,8(sp)
    800020ae:	e052                	sd	s4,0(sp)
    800020b0:	1800                	addi	s0,sp,48
    800020b2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	918080e7          	jalr	-1768(ra) # 800019cc <myproc>
    800020bc:	89aa                	mv	s3,a0
  if(p == initproc)
    800020be:	00007797          	auipc	a5,0x7
    800020c2:	f5a7b783          	ld	a5,-166(a5) # 80009018 <initproc>
    800020c6:	0d050493          	addi	s1,a0,208
    800020ca:	15050913          	addi	s2,a0,336
    800020ce:	02a79363          	bne	a5,a0,800020f4 <exit+0x52>
    panic("init exiting");
    800020d2:	00006517          	auipc	a0,0x6
    800020d6:	17650513          	addi	a0,a0,374 # 80008248 <digits+0x208>
    800020da:	ffffe097          	auipc	ra,0xffffe
    800020de:	46c080e7          	jalr	1132(ra) # 80000546 <panic>
      fileclose(f);
    800020e2:	00002097          	auipc	ra,0x2
    800020e6:	45e080e7          	jalr	1118(ra) # 80004540 <fileclose>
      p->ofile[fd] = 0;
    800020ea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020ee:	04a1                	addi	s1,s1,8
    800020f0:	01248563          	beq	s1,s2,800020fa <exit+0x58>
    if(p->ofile[fd]){
    800020f4:	6088                	ld	a0,0(s1)
    800020f6:	f575                	bnez	a0,800020e2 <exit+0x40>
    800020f8:	bfdd                	j	800020ee <exit+0x4c>
  begin_op();
    800020fa:	00002097          	auipc	ra,0x2
    800020fe:	f78080e7          	jalr	-136(ra) # 80004072 <begin_op>
  iput(p->cwd);
    80002102:	1509b503          	ld	a0,336(s3)
    80002106:	00001097          	auipc	ra,0x1
    8000210a:	760080e7          	jalr	1888(ra) # 80003866 <iput>
  end_op();
    8000210e:	00002097          	auipc	ra,0x2
    80002112:	fe2080e7          	jalr	-30(ra) # 800040f0 <end_op>
  p->cwd = 0;
    80002116:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000211a:	00007497          	auipc	s1,0x7
    8000211e:	efe48493          	addi	s1,s1,-258 # 80009018 <initproc>
    80002122:	6088                	ld	a0,0(s1)
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	adc080e7          	jalr	-1316(ra) # 80000c00 <acquire>
  wakeup1(initproc);
    8000212c:	6088                	ld	a0,0(s1)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	75e080e7          	jalr	1886(ra) # 8000188c <wakeup1>
  release(&initproc->lock);
    80002136:	6088                	ld	a0,0(s1)
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b7c080e7          	jalr	-1156(ra) # 80000cb4 <release>
  acquire(&p->lock);
    80002140:	854e                	mv	a0,s3
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	abe080e7          	jalr	-1346(ra) # 80000c00 <acquire>
  struct proc *original_parent = p->parent;
    8000214a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000214e:	854e                	mv	a0,s3
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	b64080e7          	jalr	-1180(ra) # 80000cb4 <release>
  acquire(&original_parent->lock);
    80002158:	8526                	mv	a0,s1
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	aa6080e7          	jalr	-1370(ra) # 80000c00 <acquire>
  acquire(&p->lock);
    80002162:	854e                	mv	a0,s3
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	a9c080e7          	jalr	-1380(ra) # 80000c00 <acquire>
  reparent(p);
    8000216c:	854e                	mv	a0,s3
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	d38080e7          	jalr	-712(ra) # 80001ea6 <reparent>
  wakeup1(original_parent);
    80002176:	8526                	mv	a0,s1
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	714080e7          	jalr	1812(ra) # 8000188c <wakeup1>
  p->xstate = status;
    80002180:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002184:	4791                	li	a5,4
    80002186:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000218a:	8526                	mv	a0,s1
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b28080e7          	jalr	-1240(ra) # 80000cb4 <release>
  sched();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	e38080e7          	jalr	-456(ra) # 80001fcc <sched>
  panic("zombie exit");
    8000219c:	00006517          	auipc	a0,0x6
    800021a0:	0bc50513          	addi	a0,a0,188 # 80008258 <digits+0x218>
    800021a4:	ffffe097          	auipc	ra,0xffffe
    800021a8:	3a2080e7          	jalr	930(ra) # 80000546 <panic>

00000000800021ac <yield>:
{
    800021ac:	1101                	addi	sp,sp,-32
    800021ae:	ec06                	sd	ra,24(sp)
    800021b0:	e822                	sd	s0,16(sp)
    800021b2:	e426                	sd	s1,8(sp)
    800021b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	816080e7          	jalr	-2026(ra) # 800019cc <myproc>
    800021be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	a40080e7          	jalr	-1472(ra) # 80000c00 <acquire>
  p->state = RUNNABLE;
    800021c8:	4789                	li	a5,2
    800021ca:	cc9c                	sw	a5,24(s1)
  sched();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	e00080e7          	jalr	-512(ra) # 80001fcc <sched>
  release(&p->lock);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	ade080e7          	jalr	-1314(ra) # 80000cb4 <release>
}
    800021de:	60e2                	ld	ra,24(sp)
    800021e0:	6442                	ld	s0,16(sp)
    800021e2:	64a2                	ld	s1,8(sp)
    800021e4:	6105                	addi	sp,sp,32
    800021e6:	8082                	ret

00000000800021e8 <sleep>:
{
    800021e8:	7179                	addi	sp,sp,-48
    800021ea:	f406                	sd	ra,40(sp)
    800021ec:	f022                	sd	s0,32(sp)
    800021ee:	ec26                	sd	s1,24(sp)
    800021f0:	e84a                	sd	s2,16(sp)
    800021f2:	e44e                	sd	s3,8(sp)
    800021f4:	1800                	addi	s0,sp,48
    800021f6:	89aa                	mv	s3,a0
    800021f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	7d2080e7          	jalr	2002(ra) # 800019cc <myproc>
    80002202:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002204:	05250663          	beq	a0,s2,80002250 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	9f8080e7          	jalr	-1544(ra) # 80000c00 <acquire>
    release(lk);
    80002210:	854a                	mv	a0,s2
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	aa2080e7          	jalr	-1374(ra) # 80000cb4 <release>
  p->chan = chan;
    8000221a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000221e:	4785                	li	a5,1
    80002220:	cc9c                	sw	a5,24(s1)
  sched();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	daa080e7          	jalr	-598(ra) # 80001fcc <sched>
  p->chan = 0;
    8000222a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a84080e7          	jalr	-1404(ra) # 80000cb4 <release>
    acquire(lk);
    80002238:	854a                	mv	a0,s2
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	9c6080e7          	jalr	-1594(ra) # 80000c00 <acquire>
}
    80002242:	70a2                	ld	ra,40(sp)
    80002244:	7402                	ld	s0,32(sp)
    80002246:	64e2                	ld	s1,24(sp)
    80002248:	6942                	ld	s2,16(sp)
    8000224a:	69a2                	ld	s3,8(sp)
    8000224c:	6145                	addi	sp,sp,48
    8000224e:	8082                	ret
  p->chan = chan;
    80002250:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002254:	4785                	li	a5,1
    80002256:	cd1c                	sw	a5,24(a0)
  sched();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	d74080e7          	jalr	-652(ra) # 80001fcc <sched>
  p->chan = 0;
    80002260:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002264:	bff9                	j	80002242 <sleep+0x5a>

0000000080002266 <wait>:
{
    80002266:	715d                	addi	sp,sp,-80
    80002268:	e486                	sd	ra,72(sp)
    8000226a:	e0a2                	sd	s0,64(sp)
    8000226c:	fc26                	sd	s1,56(sp)
    8000226e:	f84a                	sd	s2,48(sp)
    80002270:	f44e                	sd	s3,40(sp)
    80002272:	f052                	sd	s4,32(sp)
    80002274:	ec56                	sd	s5,24(sp)
    80002276:	e85a                	sd	s6,16(sp)
    80002278:	e45e                	sd	s7,8(sp)
    8000227a:	0880                	addi	s0,sp,80
    8000227c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	74e080e7          	jalr	1870(ra) # 800019cc <myproc>
    80002286:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	978080e7          	jalr	-1672(ra) # 80000c00 <acquire>
    havekids = 0;
    80002290:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002292:	4a11                	li	s4,4
        havekids = 1;
    80002294:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002296:	00015997          	auipc	s3,0x15
    8000229a:	6d298993          	addi	s3,s3,1746 # 80017968 <tickslock>
    havekids = 0;
    8000229e:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022a0:	00010497          	auipc	s1,0x10
    800022a4:	ac848493          	addi	s1,s1,-1336 # 80011d68 <proc>
    800022a8:	a08d                	j	8000230a <wait+0xa4>
          pid = np->pid;
    800022aa:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022ae:	000b0e63          	beqz	s6,800022ca <wait+0x64>
    800022b2:	4691                	li	a3,4
    800022b4:	03448613          	addi	a2,s1,52
    800022b8:	85da                	mv	a1,s6
    800022ba:	05093503          	ld	a0,80(s2)
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	404080e7          	jalr	1028(ra) # 800016c2 <copyout>
    800022c6:	02054263          	bltz	a0,800022ea <wait+0x84>
          freeproc(np);
    800022ca:	8526                	mv	a0,s1
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	8b2080e7          	jalr	-1870(ra) # 80001b7e <freeproc>
          release(&np->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9de080e7          	jalr	-1570(ra) # 80000cb4 <release>
          release(&p->lock);
    800022de:	854a                	mv	a0,s2
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	9d4080e7          	jalr	-1580(ra) # 80000cb4 <release>
          return pid;
    800022e8:	a8a9                	j	80002342 <wait+0xdc>
            release(&np->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	9c8080e7          	jalr	-1592(ra) # 80000cb4 <release>
            release(&p->lock);
    800022f4:	854a                	mv	a0,s2
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	9be080e7          	jalr	-1602(ra) # 80000cb4 <release>
            return -1;
    800022fe:	59fd                	li	s3,-1
    80002300:	a089                	j	80002342 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002302:	17048493          	addi	s1,s1,368
    80002306:	03348463          	beq	s1,s3,8000232e <wait+0xc8>
      if(np->parent == p){
    8000230a:	709c                	ld	a5,32(s1)
    8000230c:	ff279be3          	bne	a5,s2,80002302 <wait+0x9c>
        acquire(&np->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8ee080e7          	jalr	-1810(ra) # 80000c00 <acquire>
        if(np->state == ZOMBIE){
    8000231a:	4c9c                	lw	a5,24(s1)
    8000231c:	f94787e3          	beq	a5,s4,800022aa <wait+0x44>
        release(&np->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	992080e7          	jalr	-1646(ra) # 80000cb4 <release>
        havekids = 1;
    8000232a:	8756                	mv	a4,s5
    8000232c:	bfd9                	j	80002302 <wait+0x9c>
    if(!havekids || p->killed){
    8000232e:	c701                	beqz	a4,80002336 <wait+0xd0>
    80002330:	03092783          	lw	a5,48(s2)
    80002334:	c39d                	beqz	a5,8000235a <wait+0xf4>
      release(&p->lock);
    80002336:	854a                	mv	a0,s2
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	97c080e7          	jalr	-1668(ra) # 80000cb4 <release>
      return -1;
    80002340:	59fd                	li	s3,-1
}
    80002342:	854e                	mv	a0,s3
    80002344:	60a6                	ld	ra,72(sp)
    80002346:	6406                	ld	s0,64(sp)
    80002348:	74e2                	ld	s1,56(sp)
    8000234a:	7942                	ld	s2,48(sp)
    8000234c:	79a2                	ld	s3,40(sp)
    8000234e:	7a02                	ld	s4,32(sp)
    80002350:	6ae2                	ld	s5,24(sp)
    80002352:	6b42                	ld	s6,16(sp)
    80002354:	6ba2                	ld	s7,8(sp)
    80002356:	6161                	addi	sp,sp,80
    80002358:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000235a:	85ca                	mv	a1,s2
    8000235c:	854a                	mv	a0,s2
    8000235e:	00000097          	auipc	ra,0x0
    80002362:	e8a080e7          	jalr	-374(ra) # 800021e8 <sleep>
    havekids = 0;
    80002366:	bf25                	j	8000229e <wait+0x38>

0000000080002368 <wakeup>:
{
    80002368:	7139                	addi	sp,sp,-64
    8000236a:	fc06                	sd	ra,56(sp)
    8000236c:	f822                	sd	s0,48(sp)
    8000236e:	f426                	sd	s1,40(sp)
    80002370:	f04a                	sd	s2,32(sp)
    80002372:	ec4e                	sd	s3,24(sp)
    80002374:	e852                	sd	s4,16(sp)
    80002376:	e456                	sd	s5,8(sp)
    80002378:	0080                	addi	s0,sp,64
    8000237a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000237c:	00010497          	auipc	s1,0x10
    80002380:	9ec48493          	addi	s1,s1,-1556 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002384:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002386:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002388:	00015917          	auipc	s2,0x15
    8000238c:	5e090913          	addi	s2,s2,1504 # 80017968 <tickslock>
    80002390:	a811                	j	800023a4 <wakeup+0x3c>
    release(&p->lock);
    80002392:	8526                	mv	a0,s1
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	920080e7          	jalr	-1760(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000239c:	17048493          	addi	s1,s1,368
    800023a0:	03248063          	beq	s1,s2,800023c0 <wakeup+0x58>
    acquire(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	85a080e7          	jalr	-1958(ra) # 80000c00 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023ae:	4c9c                	lw	a5,24(s1)
    800023b0:	ff3791e3          	bne	a5,s3,80002392 <wakeup+0x2a>
    800023b4:	749c                	ld	a5,40(s1)
    800023b6:	fd479ee3          	bne	a5,s4,80002392 <wakeup+0x2a>
      p->state = RUNNABLE;
    800023ba:	0154ac23          	sw	s5,24(s1)
    800023be:	bfd1                	j	80002392 <wakeup+0x2a>
}
    800023c0:	70e2                	ld	ra,56(sp)
    800023c2:	7442                	ld	s0,48(sp)
    800023c4:	74a2                	ld	s1,40(sp)
    800023c6:	7902                	ld	s2,32(sp)
    800023c8:	69e2                	ld	s3,24(sp)
    800023ca:	6a42                	ld	s4,16(sp)
    800023cc:	6aa2                	ld	s5,8(sp)
    800023ce:	6121                	addi	sp,sp,64
    800023d0:	8082                	ret

00000000800023d2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	1800                	addi	s0,sp,48
    800023e0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023e2:	00010497          	auipc	s1,0x10
    800023e6:	98648493          	addi	s1,s1,-1658 # 80011d68 <proc>
    800023ea:	00015997          	auipc	s3,0x15
    800023ee:	57e98993          	addi	s3,s3,1406 # 80017968 <tickslock>
    acquire(&p->lock);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	80c080e7          	jalr	-2036(ra) # 80000c00 <acquire>
    if(p->pid == pid){
    800023fc:	5c9c                	lw	a5,56(s1)
    800023fe:	01278d63          	beq	a5,s2,80002418 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002402:	8526                	mv	a0,s1
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	8b0080e7          	jalr	-1872(ra) # 80000cb4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000240c:	17048493          	addi	s1,s1,368
    80002410:	ff3491e3          	bne	s1,s3,800023f2 <kill+0x20>
  }
  return -1;
    80002414:	557d                	li	a0,-1
    80002416:	a821                	j	8000242e <kill+0x5c>
      p->killed = 1;
    80002418:	4785                	li	a5,1
    8000241a:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000241c:	4c98                	lw	a4,24(s1)
    8000241e:	00f70f63          	beq	a4,a5,8000243c <kill+0x6a>
      release(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	890080e7          	jalr	-1904(ra) # 80000cb4 <release>
      return 0;
    8000242c:	4501                	li	a0,0
}
    8000242e:	70a2                	ld	ra,40(sp)
    80002430:	7402                	ld	s0,32(sp)
    80002432:	64e2                	ld	s1,24(sp)
    80002434:	6942                	ld	s2,16(sp)
    80002436:	69a2                	ld	s3,8(sp)
    80002438:	6145                	addi	sp,sp,48
    8000243a:	8082                	ret
        p->state = RUNNABLE;
    8000243c:	4789                	li	a5,2
    8000243e:	cc9c                	sw	a5,24(s1)
    80002440:	b7cd                	j	80002422 <kill+0x50>

0000000080002442 <trace>:

int trace(int mask){
    80002442:	1101                	addi	sp,sp,-32
    80002444:	ec06                	sd	ra,24(sp)
    80002446:	e822                	sd	s0,16(sp)
    80002448:	e426                	sd	s1,8(sp)
    8000244a:	1000                	addi	s0,sp,32
    8000244c:	84aa                	mv	s1,a0
  // struct proc *cur_proc = myproc();
  myproc()->mask = mask;
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	57e080e7          	jalr	1406(ra) # 800019cc <myproc>
    80002456:	16952423          	sw	s1,360(a0)
  // printf("%d:sys_%s(%d)->%d\n",cur_proc->pid, cur_proc->name, argint(0,&arg0), cur_proc->xstate);
  return 0;
}
    8000245a:	4501                	li	a0,0
    8000245c:	60e2                	ld	ra,24(sp)
    8000245e:	6442                	ld	s0,16(sp)
    80002460:	64a2                	ld	s1,8(sp)
    80002462:	6105                	addi	sp,sp,32
    80002464:	8082                	ret

0000000080002466 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	84aa                	mv	s1,a0
    80002478:	892e                	mv	s2,a1
    8000247a:	89b2                	mv	s3,a2
    8000247c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	54e080e7          	jalr	1358(ra) # 800019cc <myproc>
  if(user_dst){
    80002486:	c08d                	beqz	s1,800024a8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002488:	86d2                	mv	a3,s4
    8000248a:	864e                	mv	a2,s3
    8000248c:	85ca                	mv	a1,s2
    8000248e:	6928                	ld	a0,80(a0)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	232080e7          	jalr	562(ra) # 800016c2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002498:	70a2                	ld	ra,40(sp)
    8000249a:	7402                	ld	s0,32(sp)
    8000249c:	64e2                	ld	s1,24(sp)
    8000249e:	6942                	ld	s2,16(sp)
    800024a0:	69a2                	ld	s3,8(sp)
    800024a2:	6a02                	ld	s4,0(sp)
    800024a4:	6145                	addi	sp,sp,48
    800024a6:	8082                	ret
    memmove((char *)dst, src, len);
    800024a8:	000a061b          	sext.w	a2,s4
    800024ac:	85ce                	mv	a1,s3
    800024ae:	854a                	mv	a0,s2
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	8a8080e7          	jalr	-1880(ra) # 80000d58 <memmove>
    return 0;
    800024b8:	8526                	mv	a0,s1
    800024ba:	bff9                	j	80002498 <either_copyout+0x32>

00000000800024bc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024bc:	7179                	addi	sp,sp,-48
    800024be:	f406                	sd	ra,40(sp)
    800024c0:	f022                	sd	s0,32(sp)
    800024c2:	ec26                	sd	s1,24(sp)
    800024c4:	e84a                	sd	s2,16(sp)
    800024c6:	e44e                	sd	s3,8(sp)
    800024c8:	e052                	sd	s4,0(sp)
    800024ca:	1800                	addi	s0,sp,48
    800024cc:	892a                	mv	s2,a0
    800024ce:	84ae                	mv	s1,a1
    800024d0:	89b2                	mv	s3,a2
    800024d2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	4f8080e7          	jalr	1272(ra) # 800019cc <myproc>
  if(user_src){
    800024dc:	c08d                	beqz	s1,800024fe <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024de:	86d2                	mv	a3,s4
    800024e0:	864e                	mv	a2,s3
    800024e2:	85ca                	mv	a1,s2
    800024e4:	6928                	ld	a0,80(a0)
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	268080e7          	jalr	616(ra) # 8000174e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ee:	70a2                	ld	ra,40(sp)
    800024f0:	7402                	ld	s0,32(sp)
    800024f2:	64e2                	ld	s1,24(sp)
    800024f4:	6942                	ld	s2,16(sp)
    800024f6:	69a2                	ld	s3,8(sp)
    800024f8:	6a02                	ld	s4,0(sp)
    800024fa:	6145                	addi	sp,sp,48
    800024fc:	8082                	ret
    memmove(dst, (char*)src, len);
    800024fe:	000a061b          	sext.w	a2,s4
    80002502:	85ce                	mv	a1,s3
    80002504:	854a                	mv	a0,s2
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	852080e7          	jalr	-1966(ra) # 80000d58 <memmove>
    return 0;
    8000250e:	8526                	mv	a0,s1
    80002510:	bff9                	j	800024ee <either_copyin+0x32>

0000000080002512 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002512:	715d                	addi	sp,sp,-80
    80002514:	e486                	sd	ra,72(sp)
    80002516:	e0a2                	sd	s0,64(sp)
    80002518:	fc26                	sd	s1,56(sp)
    8000251a:	f84a                	sd	s2,48(sp)
    8000251c:	f44e                	sd	s3,40(sp)
    8000251e:	f052                	sd	s4,32(sp)
    80002520:	ec56                	sd	s5,24(sp)
    80002522:	e85a                	sd	s6,16(sp)
    80002524:	e45e                	sd	s7,8(sp)
    80002526:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002528:	00006517          	auipc	a0,0x6
    8000252c:	ba050513          	addi	a0,a0,-1120 # 800080c8 <digits+0x88>
    80002530:	ffffe097          	auipc	ra,0xffffe
    80002534:	060080e7          	jalr	96(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002538:	00010497          	auipc	s1,0x10
    8000253c:	98848493          	addi	s1,s1,-1656 # 80011ec0 <proc+0x158>
    80002540:	00015917          	auipc	s2,0x15
    80002544:	58090913          	addi	s2,s2,1408 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002548:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000254a:	00006997          	auipc	s3,0x6
    8000254e:	d1e98993          	addi	s3,s3,-738 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002552:	00006a97          	auipc	s5,0x6
    80002556:	d1ea8a93          	addi	s5,s5,-738 # 80008270 <digits+0x230>
    printf("\n");
    8000255a:	00006a17          	auipc	s4,0x6
    8000255e:	b6ea0a13          	addi	s4,s4,-1170 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002562:	00006b97          	auipc	s7,0x6
    80002566:	d46b8b93          	addi	s7,s7,-698 # 800082a8 <states.0>
    8000256a:	a00d                	j	8000258c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256c:	ee06a583          	lw	a1,-288(a3)
    80002570:	8556                	mv	a0,s5
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	01e080e7          	jalr	30(ra) # 80000590 <printf>
    printf("\n");
    8000257a:	8552                	mv	a0,s4
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	014080e7          	jalr	20(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002584:	17048493          	addi	s1,s1,368
    80002588:	03248263          	beq	s1,s2,800025ac <procdump+0x9a>
    if(p->state == UNUSED)
    8000258c:	86a6                	mv	a3,s1
    8000258e:	ec04a783          	lw	a5,-320(s1)
    80002592:	dbed                	beqz	a5,80002584 <procdump+0x72>
      state = "???";
    80002594:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002596:	fcfb6be3          	bltu	s6,a5,8000256c <procdump+0x5a>
    8000259a:	02079713          	slli	a4,a5,0x20
    8000259e:	01d75793          	srli	a5,a4,0x1d
    800025a2:	97de                	add	a5,a5,s7
    800025a4:	6390                	ld	a2,0(a5)
    800025a6:	f279                	bnez	a2,8000256c <procdump+0x5a>
      state = "???";
    800025a8:	864e                	mv	a2,s3
    800025aa:	b7c9                	j	8000256c <procdump+0x5a>
  }
}
    800025ac:	60a6                	ld	ra,72(sp)
    800025ae:	6406                	ld	s0,64(sp)
    800025b0:	74e2                	ld	s1,56(sp)
    800025b2:	7942                	ld	s2,48(sp)
    800025b4:	79a2                	ld	s3,40(sp)
    800025b6:	7a02                	ld	s4,32(sp)
    800025b8:	6ae2                	ld	s5,24(sp)
    800025ba:	6b42                	ld	s6,16(sp)
    800025bc:	6ba2                	ld	s7,8(sp)
    800025be:	6161                	addi	sp,sp,80
    800025c0:	8082                	ret

00000000800025c2 <swtch>:
    800025c2:	00153023          	sd	ra,0(a0)
    800025c6:	00253423          	sd	sp,8(a0)
    800025ca:	e900                	sd	s0,16(a0)
    800025cc:	ed04                	sd	s1,24(a0)
    800025ce:	03253023          	sd	s2,32(a0)
    800025d2:	03353423          	sd	s3,40(a0)
    800025d6:	03453823          	sd	s4,48(a0)
    800025da:	03553c23          	sd	s5,56(a0)
    800025de:	05653023          	sd	s6,64(a0)
    800025e2:	05753423          	sd	s7,72(a0)
    800025e6:	05853823          	sd	s8,80(a0)
    800025ea:	05953c23          	sd	s9,88(a0)
    800025ee:	07a53023          	sd	s10,96(a0)
    800025f2:	07b53423          	sd	s11,104(a0)
    800025f6:	0005b083          	ld	ra,0(a1)
    800025fa:	0085b103          	ld	sp,8(a1)
    800025fe:	6980                	ld	s0,16(a1)
    80002600:	6d84                	ld	s1,24(a1)
    80002602:	0205b903          	ld	s2,32(a1)
    80002606:	0285b983          	ld	s3,40(a1)
    8000260a:	0305ba03          	ld	s4,48(a1)
    8000260e:	0385ba83          	ld	s5,56(a1)
    80002612:	0405bb03          	ld	s6,64(a1)
    80002616:	0485bb83          	ld	s7,72(a1)
    8000261a:	0505bc03          	ld	s8,80(a1)
    8000261e:	0585bc83          	ld	s9,88(a1)
    80002622:	0605bd03          	ld	s10,96(a1)
    80002626:	0685bd83          	ld	s11,104(a1)
    8000262a:	8082                	ret

000000008000262c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000262c:	1141                	addi	sp,sp,-16
    8000262e:	e406                	sd	ra,8(sp)
    80002630:	e022                	sd	s0,0(sp)
    80002632:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002634:	00006597          	auipc	a1,0x6
    80002638:	c9c58593          	addi	a1,a1,-868 # 800082d0 <states.0+0x28>
    8000263c:	00015517          	auipc	a0,0x15
    80002640:	32c50513          	addi	a0,a0,812 # 80017968 <tickslock>
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	52c080e7          	jalr	1324(ra) # 80000b70 <initlock>
}
    8000264c:	60a2                	ld	ra,8(sp)
    8000264e:	6402                	ld	s0,0(sp)
    80002650:	0141                	addi	sp,sp,16
    80002652:	8082                	ret

0000000080002654 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002654:	1141                	addi	sp,sp,-16
    80002656:	e422                	sd	s0,8(sp)
    80002658:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000265a:	00003797          	auipc	a5,0x3
    8000265e:	54678793          	addi	a5,a5,1350 # 80005ba0 <kernelvec>
    80002662:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002666:	6422                	ld	s0,8(sp)
    80002668:	0141                	addi	sp,sp,16
    8000266a:	8082                	ret

000000008000266c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e406                	sd	ra,8(sp)
    80002670:	e022                	sd	s0,0(sp)
    80002672:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002674:	fffff097          	auipc	ra,0xfffff
    80002678:	358080e7          	jalr	856(ra) # 800019cc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000267c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002680:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002682:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002686:	00005697          	auipc	a3,0x5
    8000268a:	97a68693          	addi	a3,a3,-1670 # 80007000 <_trampoline>
    8000268e:	00005717          	auipc	a4,0x5
    80002692:	97270713          	addi	a4,a4,-1678 # 80007000 <_trampoline>
    80002696:	8f15                	sub	a4,a4,a3
    80002698:	040007b7          	lui	a5,0x4000
    8000269c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000269e:	07b2                	slli	a5,a5,0xc
    800026a0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a2:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026a6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026a8:	18002673          	csrr	a2,satp
    800026ac:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026ae:	6d30                	ld	a2,88(a0)
    800026b0:	6138                	ld	a4,64(a0)
    800026b2:	6585                	lui	a1,0x1
    800026b4:	972e                	add	a4,a4,a1
    800026b6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026b8:	6d38                	ld	a4,88(a0)
    800026ba:	00000617          	auipc	a2,0x0
    800026be:	13860613          	addi	a2,a2,312 # 800027f2 <usertrap>
    800026c2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026c4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026c6:	8612                	mv	a2,tp
    800026c8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ca:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026ce:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800026d2:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026d6:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026da:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026dc:	6f18                	ld	a4,24(a4)
    800026de:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026e2:	692c                	ld	a1,80(a0)
    800026e4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026e6:	00005717          	auipc	a4,0x5
    800026ea:	9aa70713          	addi	a4,a4,-1622 # 80007090 <userret>
    800026ee:	8f15                	sub	a4,a4,a3
    800026f0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026f2:	577d                	li	a4,-1
    800026f4:	177e                	slli	a4,a4,0x3f
    800026f6:	8dd9                	or	a1,a1,a4
    800026f8:	02000537          	lui	a0,0x2000
    800026fc:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800026fe:	0536                	slli	a0,a0,0xd
    80002700:	9782                	jalr	a5
}
    80002702:	60a2                	ld	ra,8(sp)
    80002704:	6402                	ld	s0,0(sp)
    80002706:	0141                	addi	sp,sp,16
    80002708:	8082                	ret

000000008000270a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000270a:	1101                	addi	sp,sp,-32
    8000270c:	ec06                	sd	ra,24(sp)
    8000270e:	e822                	sd	s0,16(sp)
    80002710:	e426                	sd	s1,8(sp)
    80002712:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002714:	00015497          	auipc	s1,0x15
    80002718:	25448493          	addi	s1,s1,596 # 80017968 <tickslock>
    8000271c:	8526                	mv	a0,s1
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	4e2080e7          	jalr	1250(ra) # 80000c00 <acquire>
  ticks++;
    80002726:	00007517          	auipc	a0,0x7
    8000272a:	8fa50513          	addi	a0,a0,-1798 # 80009020 <ticks>
    8000272e:	411c                	lw	a5,0(a0)
    80002730:	2785                	addiw	a5,a5,1
    80002732:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002734:	00000097          	auipc	ra,0x0
    80002738:	c34080e7          	jalr	-972(ra) # 80002368 <wakeup>
  release(&tickslock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	576080e7          	jalr	1398(ra) # 80000cb4 <release>
}
    80002746:	60e2                	ld	ra,24(sp)
    80002748:	6442                	ld	s0,16(sp)
    8000274a:	64a2                	ld	s1,8(sp)
    8000274c:	6105                	addi	sp,sp,32
    8000274e:	8082                	ret

0000000080002750 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002750:	1101                	addi	sp,sp,-32
    80002752:	ec06                	sd	ra,24(sp)
    80002754:	e822                	sd	s0,16(sp)
    80002756:	e426                	sd	s1,8(sp)
    80002758:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000275a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000275e:	00074d63          	bltz	a4,80002778 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002762:	57fd                	li	a5,-1
    80002764:	17fe                	slli	a5,a5,0x3f
    80002766:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002768:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000276a:	06f70363          	beq	a4,a5,800027d0 <devintr+0x80>
  }
}
    8000276e:	60e2                	ld	ra,24(sp)
    80002770:	6442                	ld	s0,16(sp)
    80002772:	64a2                	ld	s1,8(sp)
    80002774:	6105                	addi	sp,sp,32
    80002776:	8082                	ret
     (scause & 0xff) == 9){
    80002778:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000277c:	46a5                	li	a3,9
    8000277e:	fed792e3          	bne	a5,a3,80002762 <devintr+0x12>
    int irq = plic_claim();
    80002782:	00003097          	auipc	ra,0x3
    80002786:	526080e7          	jalr	1318(ra) # 80005ca8 <plic_claim>
    8000278a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000278c:	47a9                	li	a5,10
    8000278e:	02f50763          	beq	a0,a5,800027bc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002792:	4785                	li	a5,1
    80002794:	02f50963          	beq	a0,a5,800027c6 <devintr+0x76>
    return 1;
    80002798:	4505                	li	a0,1
    } else if(irq){
    8000279a:	d8f1                	beqz	s1,8000276e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000279c:	85a6                	mv	a1,s1
    8000279e:	00006517          	auipc	a0,0x6
    800027a2:	b3a50513          	addi	a0,a0,-1222 # 800082d8 <states.0+0x30>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	dea080e7          	jalr	-534(ra) # 80000590 <printf>
      plic_complete(irq);
    800027ae:	8526                	mv	a0,s1
    800027b0:	00003097          	auipc	ra,0x3
    800027b4:	51c080e7          	jalr	1308(ra) # 80005ccc <plic_complete>
    return 1;
    800027b8:	4505                	li	a0,1
    800027ba:	bf55                	j	8000276e <devintr+0x1e>
      uartintr();
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	206080e7          	jalr	518(ra) # 800009c2 <uartintr>
    800027c4:	b7ed                	j	800027ae <devintr+0x5e>
      virtio_disk_intr();
    800027c6:	00004097          	auipc	ra,0x4
    800027ca:	97a080e7          	jalr	-1670(ra) # 80006140 <virtio_disk_intr>
    800027ce:	b7c5                	j	800027ae <devintr+0x5e>
    if(cpuid() == 0){
    800027d0:	fffff097          	auipc	ra,0xfffff
    800027d4:	1d0080e7          	jalr	464(ra) # 800019a0 <cpuid>
    800027d8:	c901                	beqz	a0,800027e8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027da:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027de:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027e0:	14479073          	csrw	sip,a5
    return 2;
    800027e4:	4509                	li	a0,2
    800027e6:	b761                	j	8000276e <devintr+0x1e>
      clockintr();
    800027e8:	00000097          	auipc	ra,0x0
    800027ec:	f22080e7          	jalr	-222(ra) # 8000270a <clockintr>
    800027f0:	b7ed                	j	800027da <devintr+0x8a>

00000000800027f2 <usertrap>:
{
    800027f2:	1101                	addi	sp,sp,-32
    800027f4:	ec06                	sd	ra,24(sp)
    800027f6:	e822                	sd	s0,16(sp)
    800027f8:	e426                	sd	s1,8(sp)
    800027fa:	e04a                	sd	s2,0(sp)
    800027fc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027fe:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002802:	1007f793          	andi	a5,a5,256
    80002806:	e3ad                	bnez	a5,80002868 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002808:	00003797          	auipc	a5,0x3
    8000280c:	39878793          	addi	a5,a5,920 # 80005ba0 <kernelvec>
    80002810:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002814:	fffff097          	auipc	ra,0xfffff
    80002818:	1b8080e7          	jalr	440(ra) # 800019cc <myproc>
    8000281c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000281e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002820:	14102773          	csrr	a4,sepc
    80002824:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002826:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000282a:	47a1                	li	a5,8
    8000282c:	04f71c63          	bne	a4,a5,80002884 <usertrap+0x92>
    if(p->killed)
    80002830:	591c                	lw	a5,48(a0)
    80002832:	e3b9                	bnez	a5,80002878 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002834:	6cb8                	ld	a4,88(s1)
    80002836:	6f1c                	ld	a5,24(a4)
    80002838:	0791                	addi	a5,a5,4
    8000283a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002840:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002844:	10079073          	csrw	sstatus,a5
    syscall();
    80002848:	00000097          	auipc	ra,0x0
    8000284c:	2e0080e7          	jalr	736(ra) # 80002b28 <syscall>
  if(p->killed)
    80002850:	589c                	lw	a5,48(s1)
    80002852:	ebc1                	bnez	a5,800028e2 <usertrap+0xf0>
  usertrapret();
    80002854:	00000097          	auipc	ra,0x0
    80002858:	e18080e7          	jalr	-488(ra) # 8000266c <usertrapret>
}
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6902                	ld	s2,0(sp)
    80002864:	6105                	addi	sp,sp,32
    80002866:	8082                	ret
    panic("usertrap: not from user mode");
    80002868:	00006517          	auipc	a0,0x6
    8000286c:	a9050513          	addi	a0,a0,-1392 # 800082f8 <states.0+0x50>
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	cd6080e7          	jalr	-810(ra) # 80000546 <panic>
      exit(-1);
    80002878:	557d                	li	a0,-1
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	828080e7          	jalr	-2008(ra) # 800020a2 <exit>
    80002882:	bf4d                	j	80002834 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002884:	00000097          	auipc	ra,0x0
    80002888:	ecc080e7          	jalr	-308(ra) # 80002750 <devintr>
    8000288c:	892a                	mv	s2,a0
    8000288e:	c501                	beqz	a0,80002896 <usertrap+0xa4>
  if(p->killed)
    80002890:	589c                	lw	a5,48(s1)
    80002892:	c3a1                	beqz	a5,800028d2 <usertrap+0xe0>
    80002894:	a815                	j	800028c8 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002896:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000289a:	5c90                	lw	a2,56(s1)
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	a7c50513          	addi	a0,a0,-1412 # 80008318 <states.0+0x70>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	cec080e7          	jalr	-788(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028b0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028b4:	00006517          	auipc	a0,0x6
    800028b8:	a9450513          	addi	a0,a0,-1388 # 80008348 <states.0+0xa0>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	cd4080e7          	jalr	-812(ra) # 80000590 <printf>
    p->killed = 1;
    800028c4:	4785                	li	a5,1
    800028c6:	d89c                	sw	a5,48(s1)
    exit(-1);
    800028c8:	557d                	li	a0,-1
    800028ca:	fffff097          	auipc	ra,0xfffff
    800028ce:	7d8080e7          	jalr	2008(ra) # 800020a2 <exit>
  if(which_dev == 2)
    800028d2:	4789                	li	a5,2
    800028d4:	f8f910e3          	bne	s2,a5,80002854 <usertrap+0x62>
    yield();
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	8d4080e7          	jalr	-1836(ra) # 800021ac <yield>
    800028e0:	bf95                	j	80002854 <usertrap+0x62>
  int which_dev = 0;
    800028e2:	4901                	li	s2,0
    800028e4:	b7d5                	j	800028c8 <usertrap+0xd6>

00000000800028e6 <kerneltrap>:
{
    800028e6:	7179                	addi	sp,sp,-48
    800028e8:	f406                	sd	ra,40(sp)
    800028ea:	f022                	sd	s0,32(sp)
    800028ec:	ec26                	sd	s1,24(sp)
    800028ee:	e84a                	sd	s2,16(sp)
    800028f0:	e44e                	sd	s3,8(sp)
    800028f2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f4:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f8:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fc:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002900:	1004f793          	andi	a5,s1,256
    80002904:	cb85                	beqz	a5,80002934 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000290a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000290c:	ef85                	bnez	a5,80002944 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000290e:	00000097          	auipc	ra,0x0
    80002912:	e42080e7          	jalr	-446(ra) # 80002750 <devintr>
    80002916:	cd1d                	beqz	a0,80002954 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002918:	4789                	li	a5,2
    8000291a:	06f50a63          	beq	a0,a5,8000298e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000291e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002922:	10049073          	csrw	sstatus,s1
}
    80002926:	70a2                	ld	ra,40(sp)
    80002928:	7402                	ld	s0,32(sp)
    8000292a:	64e2                	ld	s1,24(sp)
    8000292c:	6942                	ld	s2,16(sp)
    8000292e:	69a2                	ld	s3,8(sp)
    80002930:	6145                	addi	sp,sp,48
    80002932:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	a3450513          	addi	a0,a0,-1484 # 80008368 <states.0+0xc0>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c0a080e7          	jalr	-1014(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002944:	00006517          	auipc	a0,0x6
    80002948:	a4c50513          	addi	a0,a0,-1460 # 80008390 <states.0+0xe8>
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	bfa080e7          	jalr	-1030(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002954:	85ce                	mv	a1,s3
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	a5a50513          	addi	a0,a0,-1446 # 800083b0 <states.0+0x108>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	c32080e7          	jalr	-974(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002966:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	a5250513          	addi	a0,a0,-1454 # 800083c0 <states.0+0x118>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	c1a080e7          	jalr	-998(ra) # 80000590 <printf>
    panic("kerneltrap");
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	a5a50513          	addi	a0,a0,-1446 # 800083d8 <states.0+0x130>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	bc0080e7          	jalr	-1088(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000298e:	fffff097          	auipc	ra,0xfffff
    80002992:	03e080e7          	jalr	62(ra) # 800019cc <myproc>
    80002996:	d541                	beqz	a0,8000291e <kerneltrap+0x38>
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	034080e7          	jalr	52(ra) # 800019cc <myproc>
    800029a0:	4d18                	lw	a4,24(a0)
    800029a2:	478d                	li	a5,3
    800029a4:	f6f71de3          	bne	a4,a5,8000291e <kerneltrap+0x38>
    yield();
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	804080e7          	jalr	-2044(ra) # 800021ac <yield>
    800029b0:	b7bd                	j	8000291e <kerneltrap+0x38>

00000000800029b2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029b2:	1101                	addi	sp,sp,-32
    800029b4:	ec06                	sd	ra,24(sp)
    800029b6:	e822                	sd	s0,16(sp)
    800029b8:	e426                	sd	s1,8(sp)
    800029ba:	1000                	addi	s0,sp,32
    800029bc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800029be:	fffff097          	auipc	ra,0xfffff
    800029c2:	00e080e7          	jalr	14(ra) # 800019cc <myproc>
  switch (n) {
    800029c6:	4795                	li	a5,5
    800029c8:	0497e163          	bltu	a5,s1,80002a0a <argraw+0x58>
    800029cc:	048a                	slli	s1,s1,0x2
    800029ce:	00006717          	auipc	a4,0x6
    800029d2:	b0270713          	addi	a4,a4,-1278 # 800084d0 <states.0+0x228>
    800029d6:	94ba                	add	s1,s1,a4
    800029d8:	409c                	lw	a5,0(s1)
    800029da:	97ba                	add	a5,a5,a4
    800029dc:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029de:	6d3c                	ld	a5,88(a0)
    800029e0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029e2:	60e2                	ld	ra,24(sp)
    800029e4:	6442                	ld	s0,16(sp)
    800029e6:	64a2                	ld	s1,8(sp)
    800029e8:	6105                	addi	sp,sp,32
    800029ea:	8082                	ret
    return p->trapframe->a1;
    800029ec:	6d3c                	ld	a5,88(a0)
    800029ee:	7fa8                	ld	a0,120(a5)
    800029f0:	bfcd                	j	800029e2 <argraw+0x30>
    return p->trapframe->a2;
    800029f2:	6d3c                	ld	a5,88(a0)
    800029f4:	63c8                	ld	a0,128(a5)
    800029f6:	b7f5                	j	800029e2 <argraw+0x30>
    return p->trapframe->a3;
    800029f8:	6d3c                	ld	a5,88(a0)
    800029fa:	67c8                	ld	a0,136(a5)
    800029fc:	b7dd                	j	800029e2 <argraw+0x30>
    return p->trapframe->a4;
    800029fe:	6d3c                	ld	a5,88(a0)
    80002a00:	6bc8                	ld	a0,144(a5)
    80002a02:	b7c5                	j	800029e2 <argraw+0x30>
    return p->trapframe->a5;
    80002a04:	6d3c                	ld	a5,88(a0)
    80002a06:	6fc8                	ld	a0,152(a5)
    80002a08:	bfe9                	j	800029e2 <argraw+0x30>
  panic("argraw");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	9de50513          	addi	a0,a0,-1570 # 800083e8 <states.0+0x140>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b34080e7          	jalr	-1228(ra) # 80000546 <panic>

0000000080002a1a <fetchaddr>:
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	e04a                	sd	s2,0(sp)
    80002a24:	1000                	addi	s0,sp,32
    80002a26:	84aa                	mv	s1,a0
    80002a28:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a2a:	fffff097          	auipc	ra,0xfffff
    80002a2e:	fa2080e7          	jalr	-94(ra) # 800019cc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a32:	653c                	ld	a5,72(a0)
    80002a34:	02f4f863          	bgeu	s1,a5,80002a64 <fetchaddr+0x4a>
    80002a38:	00848713          	addi	a4,s1,8
    80002a3c:	02e7e663          	bltu	a5,a4,80002a68 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a40:	46a1                	li	a3,8
    80002a42:	8626                	mv	a2,s1
    80002a44:	85ca                	mv	a1,s2
    80002a46:	6928                	ld	a0,80(a0)
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	d06080e7          	jalr	-762(ra) # 8000174e <copyin>
    80002a50:	00a03533          	snez	a0,a0
    80002a54:	40a00533          	neg	a0,a0
}
    80002a58:	60e2                	ld	ra,24(sp)
    80002a5a:	6442                	ld	s0,16(sp)
    80002a5c:	64a2                	ld	s1,8(sp)
    80002a5e:	6902                	ld	s2,0(sp)
    80002a60:	6105                	addi	sp,sp,32
    80002a62:	8082                	ret
    return -1;
    80002a64:	557d                	li	a0,-1
    80002a66:	bfcd                	j	80002a58 <fetchaddr+0x3e>
    80002a68:	557d                	li	a0,-1
    80002a6a:	b7fd                	j	80002a58 <fetchaddr+0x3e>

0000000080002a6c <fetchstr>:
{
    80002a6c:	7179                	addi	sp,sp,-48
    80002a6e:	f406                	sd	ra,40(sp)
    80002a70:	f022                	sd	s0,32(sp)
    80002a72:	ec26                	sd	s1,24(sp)
    80002a74:	e84a                	sd	s2,16(sp)
    80002a76:	e44e                	sd	s3,8(sp)
    80002a78:	1800                	addi	s0,sp,48
    80002a7a:	892a                	mv	s2,a0
    80002a7c:	84ae                	mv	s1,a1
    80002a7e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a80:	fffff097          	auipc	ra,0xfffff
    80002a84:	f4c080e7          	jalr	-180(ra) # 800019cc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a88:	86ce                	mv	a3,s3
    80002a8a:	864a                	mv	a2,s2
    80002a8c:	85a6                	mv	a1,s1
    80002a8e:	6928                	ld	a0,80(a0)
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	d4c080e7          	jalr	-692(ra) # 800017dc <copyinstr>
  if(err < 0)
    80002a98:	00054763          	bltz	a0,80002aa6 <fetchstr+0x3a>
  return strlen(buf);
    80002a9c:	8526                	mv	a0,s1
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	3e2080e7          	jalr	994(ra) # 80000e80 <strlen>
}
    80002aa6:	70a2                	ld	ra,40(sp)
    80002aa8:	7402                	ld	s0,32(sp)
    80002aaa:	64e2                	ld	s1,24(sp)
    80002aac:	6942                	ld	s2,16(sp)
    80002aae:	69a2                	ld	s3,8(sp)
    80002ab0:	6145                	addi	sp,sp,48
    80002ab2:	8082                	ret

0000000080002ab4 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	1000                	addi	s0,sp,32
    80002abe:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	ef2080e7          	jalr	-270(ra) # 800029b2 <argraw>
    80002ac8:	c088                	sw	a0,0(s1)
  return 0;
}
    80002aca:	4501                	li	a0,0
    80002acc:	60e2                	ld	ra,24(sp)
    80002ace:	6442                	ld	s0,16(sp)
    80002ad0:	64a2                	ld	s1,8(sp)
    80002ad2:	6105                	addi	sp,sp,32
    80002ad4:	8082                	ret

0000000080002ad6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	1000                	addi	s0,sp,32
    80002ae0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	ed0080e7          	jalr	-304(ra) # 800029b2 <argraw>
    80002aea:	e088                	sd	a0,0(s1)
  return 0;
}
    80002aec:	4501                	li	a0,0
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret

0000000080002af8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002af8:	1101                	addi	sp,sp,-32
    80002afa:	ec06                	sd	ra,24(sp)
    80002afc:	e822                	sd	s0,16(sp)
    80002afe:	e426                	sd	s1,8(sp)
    80002b00:	e04a                	sd	s2,0(sp)
    80002b02:	1000                	addi	s0,sp,32
    80002b04:	84ae                	mv	s1,a1
    80002b06:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	eaa080e7          	jalr	-342(ra) # 800029b2 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b10:	864a                	mv	a2,s2
    80002b12:	85a6                	mv	a1,s1
    80002b14:	00000097          	auipc	ra,0x0
    80002b18:	f58080e7          	jalr	-168(ra) # 80002a6c <fetchstr>
}
    80002b1c:	60e2                	ld	ra,24(sp)
    80002b1e:	6442                	ld	s0,16(sp)
    80002b20:	64a2                	ld	s1,8(sp)
    80002b22:	6902                	ld	s2,0(sp)
    80002b24:	6105                	addi	sp,sp,32
    80002b26:	8082                	ret

0000000080002b28 <syscall>:
char* syscall_names[24] = {"", "fork", "exit", "wait", "pipe", "read", "kill", "exec",
                      "fstat", "chdir", "dup", "getpid", "sbrk", "sleep", "uptime",
                      "open", "write", "mknod", "unlink", "link", "mkdir", "close", "trace"};
void
syscall(void)
{
    80002b28:	7139                	addi	sp,sp,-64
    80002b2a:	fc06                	sd	ra,56(sp)
    80002b2c:	f822                	sd	s0,48(sp)
    80002b2e:	f426                	sd	s1,40(sp)
    80002b30:	f04a                	sd	s2,32(sp)
    80002b32:	ec4e                	sd	s3,24(sp)
    80002b34:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e96080e7          	jalr	-362(ra) # 800019cc <myproc>
    80002b3e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b40:	6d3c                	ld	a5,88(a0)
    80002b42:	0a87b903          	ld	s2,168(a5)
    80002b46:	0009099b          	sext.w	s3,s2
  int fstarg=p->trapframe->a0;
    80002b4a:	7bbc                	ld	a5,112(a5)
    80002b4c:	fcf42623          	sw	a5,-52(s0)
  argint(0,&fstarg);
    80002b50:	fcc40593          	addi	a1,s0,-52
    80002b54:	4501                	li	a0,0
    80002b56:	00000097          	auipc	ra,0x0
    80002b5a:	f5e080e7          	jalr	-162(ra) # 80002ab4 <argint>
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b5e:	397d                	addiw	s2,s2,-1
    80002b60:	47d5                	li	a5,21
    80002b62:	0527ed63          	bltu	a5,s2,80002bbc <syscall+0x94>
    80002b66:	00399713          	slli	a4,s3,0x3
    80002b6a:	00006797          	auipc	a5,0x6
    80002b6e:	97e78793          	addi	a5,a5,-1666 # 800084e8 <syscalls>
    80002b72:	97ba                	add	a5,a5,a4
    80002b74:	639c                	ld	a5,0(a5)
    80002b76:	c3b9                	beqz	a5,80002bbc <syscall+0x94>
    p->trapframe->a0 = syscalls[num]();
    80002b78:	0584b903          	ld	s2,88(s1)
    80002b7c:	9782                	jalr	a5
    80002b7e:	06a93823          	sd	a0,112(s2)
      if(p->mask&(1<<num)&&p->mask > 0){
    80002b82:	1684a703          	lw	a4,360(s1)
    80002b86:	413757bb          	sraw	a5,a4,s3
    80002b8a:	8b85                	andi	a5,a5,1
    80002b8c:	c7b9                	beqz	a5,80002bda <syscall+0xb2>
    80002b8e:	04e05663          	blez	a4,80002bda <syscall+0xb2>
      // printf("%d:sys_%s(%d)->%d\n",p->pid, p->name, p->trapframe->a0, p->trapframe->ra);
      printf("%d: sys_%s(%d) -> %d\n",p->pid, syscall_names[num], fstarg, p->trapframe->a0);
    80002b92:	6cb8                	ld	a4,88(s1)
    80002b94:	098e                	slli	s3,s3,0x3
    80002b96:	00006797          	auipc	a5,0x6
    80002b9a:	d8278793          	addi	a5,a5,-638 # 80008918 <syscall_names>
    80002b9e:	97ce                	add	a5,a5,s3
    80002ba0:	7b38                	ld	a4,112(a4)
    80002ba2:	fcc42683          	lw	a3,-52(s0)
    80002ba6:	6390                	ld	a2,0(a5)
    80002ba8:	5c8c                	lw	a1,56(s1)
    80002baa:	00006517          	auipc	a0,0x6
    80002bae:	84650513          	addi	a0,a0,-1978 # 800083f0 <states.0+0x148>
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	9de080e7          	jalr	-1570(ra) # 80000590 <printf>
    80002bba:	a005                	j	80002bda <syscall+0xb2>
  }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bbc:	86ce                	mv	a3,s3
    80002bbe:	15848613          	addi	a2,s1,344
    80002bc2:	5c8c                	lw	a1,56(s1)
    80002bc4:	00006517          	auipc	a0,0x6
    80002bc8:	84450513          	addi	a0,a0,-1980 # 80008408 <states.0+0x160>
    80002bcc:	ffffe097          	auipc	ra,0xffffe
    80002bd0:	9c4080e7          	jalr	-1596(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bd4:	6cbc                	ld	a5,88(s1)
    80002bd6:	577d                	li	a4,-1
    80002bd8:	fbb8                	sd	a4,112(a5)
  }
  // printf("mask:%x,syscallid:%x\n",p->mask,num);

}
    80002bda:	70e2                	ld	ra,56(sp)
    80002bdc:	7442                	ld	s0,48(sp)
    80002bde:	74a2                	ld	s1,40(sp)
    80002be0:	7902                	ld	s2,32(sp)
    80002be2:	69e2                	ld	s3,24(sp)
    80002be4:	6121                	addi	sp,sp,64
    80002be6:	8082                	ret

0000000080002be8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002be8:	1101                	addi	sp,sp,-32
    80002bea:	ec06                	sd	ra,24(sp)
    80002bec:	e822                	sd	s0,16(sp)
    80002bee:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002bf0:	fec40593          	addi	a1,s0,-20
    80002bf4:	4501                	li	a0,0
    80002bf6:	00000097          	auipc	ra,0x0
    80002bfa:	ebe080e7          	jalr	-322(ra) # 80002ab4 <argint>
    return -1;
    80002bfe:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002c00:	00054963          	bltz	a0,80002c12 <sys_exit+0x2a>
  exit(n);
    80002c04:	fec42503          	lw	a0,-20(s0)
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	49a080e7          	jalr	1178(ra) # 800020a2 <exit>
  return 0; // not reached
    80002c10:	4781                	li	a5,0
}
    80002c12:	853e                	mv	a0,a5
    80002c14:	60e2                	ld	ra,24(sp)
    80002c16:	6442                	ld	s0,16(sp)
    80002c18:	6105                	addi	sp,sp,32
    80002c1a:	8082                	ret

0000000080002c1c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c1c:	1141                	addi	sp,sp,-16
    80002c1e:	e406                	sd	ra,8(sp)
    80002c20:	e022                	sd	s0,0(sp)
    80002c22:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	da8080e7          	jalr	-600(ra) # 800019cc <myproc>
}
    80002c2c:	5d08                	lw	a0,56(a0)
    80002c2e:	60a2                	ld	ra,8(sp)
    80002c30:	6402                	ld	s0,0(sp)
    80002c32:	0141                	addi	sp,sp,16
    80002c34:	8082                	ret

0000000080002c36 <sys_fork>:

uint64
sys_fork(void)
{
    80002c36:	1141                	addi	sp,sp,-16
    80002c38:	e406                	sd	ra,8(sp)
    80002c3a:	e022                	sd	s0,0(sp)
    80002c3c:	0800                	addi	s0,sp,16
  return fork();
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	152080e7          	jalr	338(ra) # 80001d90 <fork>
}
    80002c46:	60a2                	ld	ra,8(sp)
    80002c48:	6402                	ld	s0,0(sp)
    80002c4a:	0141                	addi	sp,sp,16
    80002c4c:	8082                	ret

0000000080002c4e <sys_wait>:

uint64
sys_wait(void)
{
    80002c4e:	1101                	addi	sp,sp,-32
    80002c50:	ec06                	sd	ra,24(sp)
    80002c52:	e822                	sd	s0,16(sp)
    80002c54:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002c56:	fe840593          	addi	a1,s0,-24
    80002c5a:	4501                	li	a0,0
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	e7a080e7          	jalr	-390(ra) # 80002ad6 <argaddr>
    80002c64:	87aa                	mv	a5,a0
    return -1;
    80002c66:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002c68:	0007c863          	bltz	a5,80002c78 <sys_wait+0x2a>
  return wait(p);
    80002c6c:	fe843503          	ld	a0,-24(s0)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	5f6080e7          	jalr	1526(ra) # 80002266 <wait>
}
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c80:	7179                	addi	sp,sp,-48
    80002c82:	f406                	sd	ra,40(sp)
    80002c84:	f022                	sd	s0,32(sp)
    80002c86:	ec26                	sd	s1,24(sp)
    80002c88:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002c8a:	fdc40593          	addi	a1,s0,-36
    80002c8e:	4501                	li	a0,0
    80002c90:	00000097          	auipc	ra,0x0
    80002c94:	e24080e7          	jalr	-476(ra) # 80002ab4 <argint>
    80002c98:	87aa                	mv	a5,a0
    return -1;
    80002c9a:	557d                	li	a0,-1
  if (argint(0, &n) < 0)
    80002c9c:	0207c063          	bltz	a5,80002cbc <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	d2c080e7          	jalr	-724(ra) # 800019cc <myproc>
    80002ca8:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80002caa:	fdc42503          	lw	a0,-36(s0)
    80002cae:	fffff097          	auipc	ra,0xfffff
    80002cb2:	06a080e7          	jalr	106(ra) # 80001d18 <growproc>
    80002cb6:	00054863          	bltz	a0,80002cc6 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cba:	8526                	mv	a0,s1
}
    80002cbc:	70a2                	ld	ra,40(sp)
    80002cbe:	7402                	ld	s0,32(sp)
    80002cc0:	64e2                	ld	s1,24(sp)
    80002cc2:	6145                	addi	sp,sp,48
    80002cc4:	8082                	ret
    return -1;
    80002cc6:	557d                	li	a0,-1
    80002cc8:	bfd5                	j	80002cbc <sys_sbrk+0x3c>

0000000080002cca <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cca:	7139                	addi	sp,sp,-64
    80002ccc:	fc06                	sd	ra,56(sp)
    80002cce:	f822                	sd	s0,48(sp)
    80002cd0:	f426                	sd	s1,40(sp)
    80002cd2:	f04a                	sd	s2,32(sp)
    80002cd4:	ec4e                	sd	s3,24(sp)
    80002cd6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002cd8:	fcc40593          	addi	a1,s0,-52
    80002cdc:	4501                	li	a0,0
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	dd6080e7          	jalr	-554(ra) # 80002ab4 <argint>
    return -1;
    80002ce6:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002ce8:	06054563          	bltz	a0,80002d52 <sys_sleep+0x88>
  acquire(&tickslock);
    80002cec:	00015517          	auipc	a0,0x15
    80002cf0:	c7c50513          	addi	a0,a0,-900 # 80017968 <tickslock>
    80002cf4:	ffffe097          	auipc	ra,0xffffe
    80002cf8:	f0c080e7          	jalr	-244(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002cfc:	00006917          	auipc	s2,0x6
    80002d00:	32492903          	lw	s2,804(s2) # 80009020 <ticks>
  while (ticks - ticks0 < n)
    80002d04:	fcc42783          	lw	a5,-52(s0)
    80002d08:	cf85                	beqz	a5,80002d40 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d0a:	00015997          	auipc	s3,0x15
    80002d0e:	c5e98993          	addi	s3,s3,-930 # 80017968 <tickslock>
    80002d12:	00006497          	auipc	s1,0x6
    80002d16:	30e48493          	addi	s1,s1,782 # 80009020 <ticks>
    if (myproc()->killed)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	cb2080e7          	jalr	-846(ra) # 800019cc <myproc>
    80002d22:	591c                	lw	a5,48(a0)
    80002d24:	ef9d                	bnez	a5,80002d62 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d26:	85ce                	mv	a1,s3
    80002d28:	8526                	mv	a0,s1
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	4be080e7          	jalr	1214(ra) # 800021e8 <sleep>
  while (ticks - ticks0 < n)
    80002d32:	409c                	lw	a5,0(s1)
    80002d34:	412787bb          	subw	a5,a5,s2
    80002d38:	fcc42703          	lw	a4,-52(s0)
    80002d3c:	fce7efe3          	bltu	a5,a4,80002d1a <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d40:	00015517          	auipc	a0,0x15
    80002d44:	c2850513          	addi	a0,a0,-984 # 80017968 <tickslock>
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	f6c080e7          	jalr	-148(ra) # 80000cb4 <release>
  return 0;
    80002d50:	4781                	li	a5,0
}
    80002d52:	853e                	mv	a0,a5
    80002d54:	70e2                	ld	ra,56(sp)
    80002d56:	7442                	ld	s0,48(sp)
    80002d58:	74a2                	ld	s1,40(sp)
    80002d5a:	7902                	ld	s2,32(sp)
    80002d5c:	69e2                	ld	s3,24(sp)
    80002d5e:	6121                	addi	sp,sp,64
    80002d60:	8082                	ret
      release(&tickslock);
    80002d62:	00015517          	auipc	a0,0x15
    80002d66:	c0650513          	addi	a0,a0,-1018 # 80017968 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	f4a080e7          	jalr	-182(ra) # 80000cb4 <release>
      return -1;
    80002d72:	57fd                	li	a5,-1
    80002d74:	bff9                	j	80002d52 <sys_sleep+0x88>

0000000080002d76 <sys_kill>:

uint64
sys_kill(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002d7e:	fec40593          	addi	a1,s0,-20
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	d30080e7          	jalr	-720(ra) # 80002ab4 <argint>
    80002d8c:	87aa                	mv	a5,a0
    return -1;
    80002d8e:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002d90:	0007c863          	bltz	a5,80002da0 <sys_kill+0x2a>
  return kill(pid);
    80002d94:	fec42503          	lw	a0,-20(s0)
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	63a080e7          	jalr	1594(ra) # 800023d2 <kill>
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret

0000000080002da8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002da8:	1101                	addi	sp,sp,-32
    80002daa:	ec06                	sd	ra,24(sp)
    80002dac:	e822                	sd	s0,16(sp)
    80002dae:	e426                	sd	s1,8(sp)
    80002db0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002db2:	00015517          	auipc	a0,0x15
    80002db6:	bb650513          	addi	a0,a0,-1098 # 80017968 <tickslock>
    80002dba:	ffffe097          	auipc	ra,0xffffe
    80002dbe:	e46080e7          	jalr	-442(ra) # 80000c00 <acquire>
  xticks = ticks;
    80002dc2:	00006497          	auipc	s1,0x6
    80002dc6:	25e4a483          	lw	s1,606(s1) # 80009020 <ticks>
  release(&tickslock);
    80002dca:	00015517          	auipc	a0,0x15
    80002dce:	b9e50513          	addi	a0,a0,-1122 # 80017968 <tickslock>
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	ee2080e7          	jalr	-286(ra) # 80000cb4 <release>
  return xticks;
}
    80002dda:	02049513          	slli	a0,s1,0x20
    80002dde:	9101                	srli	a0,a0,0x20
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	64a2                	ld	s1,8(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <sys_trace>:

uint64
sys_trace(void)
{ 
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0)
    80002df2:	fec40593          	addi	a1,s0,-20
    80002df6:	4501                	li	a0,0
    80002df8:	00000097          	auipc	ra,0x0
    80002dfc:	cbc080e7          	jalr	-836(ra) # 80002ab4 <argint>
    80002e00:	87aa                	mv	a5,a0
    return -1;
    80002e02:	557d                	li	a0,-1
  if(argint(0, &mask) < 0)
    80002e04:	0007c863          	bltz	a5,80002e14 <sys_trace+0x2a>
  return trace(mask);
    80002e08:	fec42503          	lw	a0,-20(s0)
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	636080e7          	jalr	1590(ra) # 80002442 <trace>
}
    80002e14:	60e2                	ld	ra,24(sp)
    80002e16:	6442                	ld	s0,16(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e1c:	7179                	addi	sp,sp,-48
    80002e1e:	f406                	sd	ra,40(sp)
    80002e20:	f022                	sd	s0,32(sp)
    80002e22:	ec26                	sd	s1,24(sp)
    80002e24:	e84a                	sd	s2,16(sp)
    80002e26:	e44e                	sd	s3,8(sp)
    80002e28:	e052                	sd	s4,0(sp)
    80002e2a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e2c:	00005597          	auipc	a1,0x5
    80002e30:	77458593          	addi	a1,a1,1908 # 800085a0 <syscalls+0xb8>
    80002e34:	00015517          	auipc	a0,0x15
    80002e38:	b4c50513          	addi	a0,a0,-1204 # 80017980 <bcache>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	d34080e7          	jalr	-716(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e44:	0001d797          	auipc	a5,0x1d
    80002e48:	b3c78793          	addi	a5,a5,-1220 # 8001f980 <bcache+0x8000>
    80002e4c:	0001d717          	auipc	a4,0x1d
    80002e50:	d9c70713          	addi	a4,a4,-612 # 8001fbe8 <bcache+0x8268>
    80002e54:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e58:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e5c:	00015497          	auipc	s1,0x15
    80002e60:	b3c48493          	addi	s1,s1,-1220 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002e64:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e66:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e68:	00005a17          	auipc	s4,0x5
    80002e6c:	740a0a13          	addi	s4,s4,1856 # 800085a8 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e70:	2b893783          	ld	a5,696(s2)
    80002e74:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e76:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e7a:	85d2                	mv	a1,s4
    80002e7c:	01048513          	addi	a0,s1,16
    80002e80:	00001097          	auipc	ra,0x1
    80002e84:	4b2080e7          	jalr	1202(ra) # 80004332 <initsleeplock>
    bcache.head.next->prev = b;
    80002e88:	2b893783          	ld	a5,696(s2)
    80002e8c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e8e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e92:	45848493          	addi	s1,s1,1112
    80002e96:	fd349de3          	bne	s1,s3,80002e70 <binit+0x54>
  }
}
    80002e9a:	70a2                	ld	ra,40(sp)
    80002e9c:	7402                	ld	s0,32(sp)
    80002e9e:	64e2                	ld	s1,24(sp)
    80002ea0:	6942                	ld	s2,16(sp)
    80002ea2:	69a2                	ld	s3,8(sp)
    80002ea4:	6a02                	ld	s4,0(sp)
    80002ea6:	6145                	addi	sp,sp,48
    80002ea8:	8082                	ret

0000000080002eaa <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	1800                	addi	s0,sp,48
    80002eb8:	892a                	mv	s2,a0
    80002eba:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ebc:	00015517          	auipc	a0,0x15
    80002ec0:	ac450513          	addi	a0,a0,-1340 # 80017980 <bcache>
    80002ec4:	ffffe097          	auipc	ra,0xffffe
    80002ec8:	d3c080e7          	jalr	-708(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ecc:	0001d497          	auipc	s1,0x1d
    80002ed0:	d6c4b483          	ld	s1,-660(s1) # 8001fc38 <bcache+0x82b8>
    80002ed4:	0001d797          	auipc	a5,0x1d
    80002ed8:	d1478793          	addi	a5,a5,-748 # 8001fbe8 <bcache+0x8268>
    80002edc:	02f48f63          	beq	s1,a5,80002f1a <bread+0x70>
    80002ee0:	873e                	mv	a4,a5
    80002ee2:	a021                	j	80002eea <bread+0x40>
    80002ee4:	68a4                	ld	s1,80(s1)
    80002ee6:	02e48a63          	beq	s1,a4,80002f1a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002eea:	449c                	lw	a5,8(s1)
    80002eec:	ff279ce3          	bne	a5,s2,80002ee4 <bread+0x3a>
    80002ef0:	44dc                	lw	a5,12(s1)
    80002ef2:	ff3799e3          	bne	a5,s3,80002ee4 <bread+0x3a>
      b->refcnt++;
    80002ef6:	40bc                	lw	a5,64(s1)
    80002ef8:	2785                	addiw	a5,a5,1
    80002efa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002efc:	00015517          	auipc	a0,0x15
    80002f00:	a8450513          	addi	a0,a0,-1404 # 80017980 <bcache>
    80002f04:	ffffe097          	auipc	ra,0xffffe
    80002f08:	db0080e7          	jalr	-592(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002f0c:	01048513          	addi	a0,s1,16
    80002f10:	00001097          	auipc	ra,0x1
    80002f14:	45c080e7          	jalr	1116(ra) # 8000436c <acquiresleep>
      return b;
    80002f18:	a8b9                	j	80002f76 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f1a:	0001d497          	auipc	s1,0x1d
    80002f1e:	d164b483          	ld	s1,-746(s1) # 8001fc30 <bcache+0x82b0>
    80002f22:	0001d797          	auipc	a5,0x1d
    80002f26:	cc678793          	addi	a5,a5,-826 # 8001fbe8 <bcache+0x8268>
    80002f2a:	00f48863          	beq	s1,a5,80002f3a <bread+0x90>
    80002f2e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f30:	40bc                	lw	a5,64(s1)
    80002f32:	cf81                	beqz	a5,80002f4a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f34:	64a4                	ld	s1,72(s1)
    80002f36:	fee49de3          	bne	s1,a4,80002f30 <bread+0x86>
  panic("bget: no buffers");
    80002f3a:	00005517          	auipc	a0,0x5
    80002f3e:	67650513          	addi	a0,a0,1654 # 800085b0 <syscalls+0xc8>
    80002f42:	ffffd097          	auipc	ra,0xffffd
    80002f46:	604080e7          	jalr	1540(ra) # 80000546 <panic>
      b->dev = dev;
    80002f4a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f4e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f52:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f56:	4785                	li	a5,1
    80002f58:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f5a:	00015517          	auipc	a0,0x15
    80002f5e:	a2650513          	addi	a0,a0,-1498 # 80017980 <bcache>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d52080e7          	jalr	-686(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002f6a:	01048513          	addi	a0,s1,16
    80002f6e:	00001097          	auipc	ra,0x1
    80002f72:	3fe080e7          	jalr	1022(ra) # 8000436c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f76:	409c                	lw	a5,0(s1)
    80002f78:	cb89                	beqz	a5,80002f8a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	70a2                	ld	ra,40(sp)
    80002f7e:	7402                	ld	s0,32(sp)
    80002f80:	64e2                	ld	s1,24(sp)
    80002f82:	6942                	ld	s2,16(sp)
    80002f84:	69a2                	ld	s3,8(sp)
    80002f86:	6145                	addi	sp,sp,48
    80002f88:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f8a:	4581                	li	a1,0
    80002f8c:	8526                	mv	a0,s1
    80002f8e:	00003097          	auipc	ra,0x3
    80002f92:	f2a080e7          	jalr	-214(ra) # 80005eb8 <virtio_disk_rw>
    b->valid = 1;
    80002f96:	4785                	li	a5,1
    80002f98:	c09c                	sw	a5,0(s1)
  return b;
    80002f9a:	b7c5                	j	80002f7a <bread+0xd0>

0000000080002f9c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f9c:	1101                	addi	sp,sp,-32
    80002f9e:	ec06                	sd	ra,24(sp)
    80002fa0:	e822                	sd	s0,16(sp)
    80002fa2:	e426                	sd	s1,8(sp)
    80002fa4:	1000                	addi	s0,sp,32
    80002fa6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fa8:	0541                	addi	a0,a0,16
    80002faa:	00001097          	auipc	ra,0x1
    80002fae:	45c080e7          	jalr	1116(ra) # 80004406 <holdingsleep>
    80002fb2:	cd01                	beqz	a0,80002fca <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fb4:	4585                	li	a1,1
    80002fb6:	8526                	mv	a0,s1
    80002fb8:	00003097          	auipc	ra,0x3
    80002fbc:	f00080e7          	jalr	-256(ra) # 80005eb8 <virtio_disk_rw>
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret
    panic("bwrite");
    80002fca:	00005517          	auipc	a0,0x5
    80002fce:	5fe50513          	addi	a0,a0,1534 # 800085c8 <syscalls+0xe0>
    80002fd2:	ffffd097          	auipc	ra,0xffffd
    80002fd6:	574080e7          	jalr	1396(ra) # 80000546 <panic>

0000000080002fda <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	e04a                	sd	s2,0(sp)
    80002fe4:	1000                	addi	s0,sp,32
    80002fe6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fe8:	01050913          	addi	s2,a0,16
    80002fec:	854a                	mv	a0,s2
    80002fee:	00001097          	auipc	ra,0x1
    80002ff2:	418080e7          	jalr	1048(ra) # 80004406 <holdingsleep>
    80002ff6:	c92d                	beqz	a0,80003068 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002ff8:	854a                	mv	a0,s2
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	3c8080e7          	jalr	968(ra) # 800043c2 <releasesleep>

  acquire(&bcache.lock);
    80003002:	00015517          	auipc	a0,0x15
    80003006:	97e50513          	addi	a0,a0,-1666 # 80017980 <bcache>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	bf6080e7          	jalr	-1034(ra) # 80000c00 <acquire>
  b->refcnt--;
    80003012:	40bc                	lw	a5,64(s1)
    80003014:	37fd                	addiw	a5,a5,-1
    80003016:	0007871b          	sext.w	a4,a5
    8000301a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000301c:	eb05                	bnez	a4,8000304c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000301e:	68bc                	ld	a5,80(s1)
    80003020:	64b8                	ld	a4,72(s1)
    80003022:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003024:	64bc                	ld	a5,72(s1)
    80003026:	68b8                	ld	a4,80(s1)
    80003028:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000302a:	0001d797          	auipc	a5,0x1d
    8000302e:	95678793          	addi	a5,a5,-1706 # 8001f980 <bcache+0x8000>
    80003032:	2b87b703          	ld	a4,696(a5)
    80003036:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003038:	0001d717          	auipc	a4,0x1d
    8000303c:	bb070713          	addi	a4,a4,-1104 # 8001fbe8 <bcache+0x8268>
    80003040:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003042:	2b87b703          	ld	a4,696(a5)
    80003046:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003048:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000304c:	00015517          	auipc	a0,0x15
    80003050:	93450513          	addi	a0,a0,-1740 # 80017980 <bcache>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	c60080e7          	jalr	-928(ra) # 80000cb4 <release>
}
    8000305c:	60e2                	ld	ra,24(sp)
    8000305e:	6442                	ld	s0,16(sp)
    80003060:	64a2                	ld	s1,8(sp)
    80003062:	6902                	ld	s2,0(sp)
    80003064:	6105                	addi	sp,sp,32
    80003066:	8082                	ret
    panic("brelse");
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	56850513          	addi	a0,a0,1384 # 800085d0 <syscalls+0xe8>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	4d6080e7          	jalr	1238(ra) # 80000546 <panic>

0000000080003078 <bpin>:

void
bpin(struct buf *b) {
    80003078:	1101                	addi	sp,sp,-32
    8000307a:	ec06                	sd	ra,24(sp)
    8000307c:	e822                	sd	s0,16(sp)
    8000307e:	e426                	sd	s1,8(sp)
    80003080:	1000                	addi	s0,sp,32
    80003082:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003084:	00015517          	auipc	a0,0x15
    80003088:	8fc50513          	addi	a0,a0,-1796 # 80017980 <bcache>
    8000308c:	ffffe097          	auipc	ra,0xffffe
    80003090:	b74080e7          	jalr	-1164(ra) # 80000c00 <acquire>
  b->refcnt++;
    80003094:	40bc                	lw	a5,64(s1)
    80003096:	2785                	addiw	a5,a5,1
    80003098:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000309a:	00015517          	auipc	a0,0x15
    8000309e:	8e650513          	addi	a0,a0,-1818 # 80017980 <bcache>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	c12080e7          	jalr	-1006(ra) # 80000cb4 <release>
}
    800030aa:	60e2                	ld	ra,24(sp)
    800030ac:	6442                	ld	s0,16(sp)
    800030ae:	64a2                	ld	s1,8(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret

00000000800030b4 <bunpin>:

void
bunpin(struct buf *b) {
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	e426                	sd	s1,8(sp)
    800030bc:	1000                	addi	s0,sp,32
    800030be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030c0:	00015517          	auipc	a0,0x15
    800030c4:	8c050513          	addi	a0,a0,-1856 # 80017980 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	b38080e7          	jalr	-1224(ra) # 80000c00 <acquire>
  b->refcnt--;
    800030d0:	40bc                	lw	a5,64(s1)
    800030d2:	37fd                	addiw	a5,a5,-1
    800030d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030d6:	00015517          	auipc	a0,0x15
    800030da:	8aa50513          	addi	a0,a0,-1878 # 80017980 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	bd6080e7          	jalr	-1066(ra) # 80000cb4 <release>
}
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	e04a                	sd	s2,0(sp)
    800030fa:	1000                	addi	s0,sp,32
    800030fc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030fe:	00d5d59b          	srliw	a1,a1,0xd
    80003102:	0001d797          	auipc	a5,0x1d
    80003106:	f5a7a783          	lw	a5,-166(a5) # 8002005c <sb+0x1c>
    8000310a:	9dbd                	addw	a1,a1,a5
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	d9e080e7          	jalr	-610(ra) # 80002eaa <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003114:	0074f713          	andi	a4,s1,7
    80003118:	4785                	li	a5,1
    8000311a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000311e:	14ce                	slli	s1,s1,0x33
    80003120:	90d9                	srli	s1,s1,0x36
    80003122:	00950733          	add	a4,a0,s1
    80003126:	05874703          	lbu	a4,88(a4)
    8000312a:	00e7f6b3          	and	a3,a5,a4
    8000312e:	c69d                	beqz	a3,8000315c <bfree+0x6c>
    80003130:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003132:	94aa                	add	s1,s1,a0
    80003134:	fff7c793          	not	a5,a5
    80003138:	8f7d                	and	a4,a4,a5
    8000313a:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	108080e7          	jalr	264(ra) # 80004246 <log_write>
  brelse(bp);
    80003146:	854a                	mv	a0,s2
    80003148:	00000097          	auipc	ra,0x0
    8000314c:	e92080e7          	jalr	-366(ra) # 80002fda <brelse>
}
    80003150:	60e2                	ld	ra,24(sp)
    80003152:	6442                	ld	s0,16(sp)
    80003154:	64a2                	ld	s1,8(sp)
    80003156:	6902                	ld	s2,0(sp)
    80003158:	6105                	addi	sp,sp,32
    8000315a:	8082                	ret
    panic("freeing free block");
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	47c50513          	addi	a0,a0,1148 # 800085d8 <syscalls+0xf0>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	3e2080e7          	jalr	994(ra) # 80000546 <panic>

000000008000316c <balloc>:
{
    8000316c:	711d                	addi	sp,sp,-96
    8000316e:	ec86                	sd	ra,88(sp)
    80003170:	e8a2                	sd	s0,80(sp)
    80003172:	e4a6                	sd	s1,72(sp)
    80003174:	e0ca                	sd	s2,64(sp)
    80003176:	fc4e                	sd	s3,56(sp)
    80003178:	f852                	sd	s4,48(sp)
    8000317a:	f456                	sd	s5,40(sp)
    8000317c:	f05a                	sd	s6,32(sp)
    8000317e:	ec5e                	sd	s7,24(sp)
    80003180:	e862                	sd	s8,16(sp)
    80003182:	e466                	sd	s9,8(sp)
    80003184:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003186:	0001d797          	auipc	a5,0x1d
    8000318a:	ebe7a783          	lw	a5,-322(a5) # 80020044 <sb+0x4>
    8000318e:	cbc1                	beqz	a5,8000321e <balloc+0xb2>
    80003190:	8baa                	mv	s7,a0
    80003192:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003194:	0001db17          	auipc	s6,0x1d
    80003198:	eacb0b13          	addi	s6,s6,-340 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000319c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000319e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031a0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031a2:	6c89                	lui	s9,0x2
    800031a4:	a831                	j	800031c0 <balloc+0x54>
    brelse(bp);
    800031a6:	854a                	mv	a0,s2
    800031a8:	00000097          	auipc	ra,0x0
    800031ac:	e32080e7          	jalr	-462(ra) # 80002fda <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031b0:	015c87bb          	addw	a5,s9,s5
    800031b4:	00078a9b          	sext.w	s5,a5
    800031b8:	004b2703          	lw	a4,4(s6)
    800031bc:	06eaf163          	bgeu	s5,a4,8000321e <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800031c0:	41fad79b          	sraiw	a5,s5,0x1f
    800031c4:	0137d79b          	srliw	a5,a5,0x13
    800031c8:	015787bb          	addw	a5,a5,s5
    800031cc:	40d7d79b          	sraiw	a5,a5,0xd
    800031d0:	01cb2583          	lw	a1,28(s6)
    800031d4:	9dbd                	addw	a1,a1,a5
    800031d6:	855e                	mv	a0,s7
    800031d8:	00000097          	auipc	ra,0x0
    800031dc:	cd2080e7          	jalr	-814(ra) # 80002eaa <bread>
    800031e0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e2:	004b2503          	lw	a0,4(s6)
    800031e6:	000a849b          	sext.w	s1,s5
    800031ea:	8762                	mv	a4,s8
    800031ec:	faa4fde3          	bgeu	s1,a0,800031a6 <balloc+0x3a>
      m = 1 << (bi % 8);
    800031f0:	00777693          	andi	a3,a4,7
    800031f4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031f8:	41f7579b          	sraiw	a5,a4,0x1f
    800031fc:	01d7d79b          	srliw	a5,a5,0x1d
    80003200:	9fb9                	addw	a5,a5,a4
    80003202:	4037d79b          	sraiw	a5,a5,0x3
    80003206:	00f90633          	add	a2,s2,a5
    8000320a:	05864603          	lbu	a2,88(a2)
    8000320e:	00c6f5b3          	and	a1,a3,a2
    80003212:	cd91                	beqz	a1,8000322e <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003214:	2705                	addiw	a4,a4,1
    80003216:	2485                	addiw	s1,s1,1
    80003218:	fd471ae3          	bne	a4,s4,800031ec <balloc+0x80>
    8000321c:	b769                	j	800031a6 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	3d250513          	addi	a0,a0,978 # 800085f0 <syscalls+0x108>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	320080e7          	jalr	800(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000322e:	97ca                	add	a5,a5,s2
    80003230:	8e55                	or	a2,a2,a3
    80003232:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003236:	854a                	mv	a0,s2
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	00e080e7          	jalr	14(ra) # 80004246 <log_write>
        brelse(bp);
    80003240:	854a                	mv	a0,s2
    80003242:	00000097          	auipc	ra,0x0
    80003246:	d98080e7          	jalr	-616(ra) # 80002fda <brelse>
  bp = bread(dev, bno);
    8000324a:	85a6                	mv	a1,s1
    8000324c:	855e                	mv	a0,s7
    8000324e:	00000097          	auipc	ra,0x0
    80003252:	c5c080e7          	jalr	-932(ra) # 80002eaa <bread>
    80003256:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003258:	40000613          	li	a2,1024
    8000325c:	4581                	li	a1,0
    8000325e:	05850513          	addi	a0,a0,88
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a9a080e7          	jalr	-1382(ra) # 80000cfc <memset>
  log_write(bp);
    8000326a:	854a                	mv	a0,s2
    8000326c:	00001097          	auipc	ra,0x1
    80003270:	fda080e7          	jalr	-38(ra) # 80004246 <log_write>
  brelse(bp);
    80003274:	854a                	mv	a0,s2
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	d64080e7          	jalr	-668(ra) # 80002fda <brelse>
}
    8000327e:	8526                	mv	a0,s1
    80003280:	60e6                	ld	ra,88(sp)
    80003282:	6446                	ld	s0,80(sp)
    80003284:	64a6                	ld	s1,72(sp)
    80003286:	6906                	ld	s2,64(sp)
    80003288:	79e2                	ld	s3,56(sp)
    8000328a:	7a42                	ld	s4,48(sp)
    8000328c:	7aa2                	ld	s5,40(sp)
    8000328e:	7b02                	ld	s6,32(sp)
    80003290:	6be2                	ld	s7,24(sp)
    80003292:	6c42                	ld	s8,16(sp)
    80003294:	6ca2                	ld	s9,8(sp)
    80003296:	6125                	addi	sp,sp,96
    80003298:	8082                	ret

000000008000329a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000329a:	7179                	addi	sp,sp,-48
    8000329c:	f406                	sd	ra,40(sp)
    8000329e:	f022                	sd	s0,32(sp)
    800032a0:	ec26                	sd	s1,24(sp)
    800032a2:	e84a                	sd	s2,16(sp)
    800032a4:	e44e                	sd	s3,8(sp)
    800032a6:	e052                	sd	s4,0(sp)
    800032a8:	1800                	addi	s0,sp,48
    800032aa:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032ac:	47ad                	li	a5,11
    800032ae:	04b7fe63          	bgeu	a5,a1,8000330a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032b2:	ff45849b          	addiw	s1,a1,-12
    800032b6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032ba:	0ff00793          	li	a5,255
    800032be:	0ae7e463          	bltu	a5,a4,80003366 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032c2:	08052583          	lw	a1,128(a0)
    800032c6:	c5b5                	beqz	a1,80003332 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032c8:	00092503          	lw	a0,0(s2)
    800032cc:	00000097          	auipc	ra,0x0
    800032d0:	bde080e7          	jalr	-1058(ra) # 80002eaa <bread>
    800032d4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032d6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032da:	02049713          	slli	a4,s1,0x20
    800032de:	01e75593          	srli	a1,a4,0x1e
    800032e2:	00b784b3          	add	s1,a5,a1
    800032e6:	0004a983          	lw	s3,0(s1)
    800032ea:	04098e63          	beqz	s3,80003346 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800032ee:	8552                	mv	a0,s4
    800032f0:	00000097          	auipc	ra,0x0
    800032f4:	cea080e7          	jalr	-790(ra) # 80002fda <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800032f8:	854e                	mv	a0,s3
    800032fa:	70a2                	ld	ra,40(sp)
    800032fc:	7402                	ld	s0,32(sp)
    800032fe:	64e2                	ld	s1,24(sp)
    80003300:	6942                	ld	s2,16(sp)
    80003302:	69a2                	ld	s3,8(sp)
    80003304:	6a02                	ld	s4,0(sp)
    80003306:	6145                	addi	sp,sp,48
    80003308:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000330a:	02059793          	slli	a5,a1,0x20
    8000330e:	01e7d593          	srli	a1,a5,0x1e
    80003312:	00b504b3          	add	s1,a0,a1
    80003316:	0504a983          	lw	s3,80(s1)
    8000331a:	fc099fe3          	bnez	s3,800032f8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000331e:	4108                	lw	a0,0(a0)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	e4c080e7          	jalr	-436(ra) # 8000316c <balloc>
    80003328:	0005099b          	sext.w	s3,a0
    8000332c:	0534a823          	sw	s3,80(s1)
    80003330:	b7e1                	j	800032f8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003332:	4108                	lw	a0,0(a0)
    80003334:	00000097          	auipc	ra,0x0
    80003338:	e38080e7          	jalr	-456(ra) # 8000316c <balloc>
    8000333c:	0005059b          	sext.w	a1,a0
    80003340:	08b92023          	sw	a1,128(s2)
    80003344:	b751                	j	800032c8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003346:	00092503          	lw	a0,0(s2)
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e22080e7          	jalr	-478(ra) # 8000316c <balloc>
    80003352:	0005099b          	sext.w	s3,a0
    80003356:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000335a:	8552                	mv	a0,s4
    8000335c:	00001097          	auipc	ra,0x1
    80003360:	eea080e7          	jalr	-278(ra) # 80004246 <log_write>
    80003364:	b769                	j	800032ee <bmap+0x54>
  panic("bmap: out of range");
    80003366:	00005517          	auipc	a0,0x5
    8000336a:	2a250513          	addi	a0,a0,674 # 80008608 <syscalls+0x120>
    8000336e:	ffffd097          	auipc	ra,0xffffd
    80003372:	1d8080e7          	jalr	472(ra) # 80000546 <panic>

0000000080003376 <iget>:
{
    80003376:	7179                	addi	sp,sp,-48
    80003378:	f406                	sd	ra,40(sp)
    8000337a:	f022                	sd	s0,32(sp)
    8000337c:	ec26                	sd	s1,24(sp)
    8000337e:	e84a                	sd	s2,16(sp)
    80003380:	e44e                	sd	s3,8(sp)
    80003382:	e052                	sd	s4,0(sp)
    80003384:	1800                	addi	s0,sp,48
    80003386:	89aa                	mv	s3,a0
    80003388:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000338a:	0001d517          	auipc	a0,0x1d
    8000338e:	cd650513          	addi	a0,a0,-810 # 80020060 <icache>
    80003392:	ffffe097          	auipc	ra,0xffffe
    80003396:	86e080e7          	jalr	-1938(ra) # 80000c00 <acquire>
  empty = 0;
    8000339a:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000339c:	0001d497          	auipc	s1,0x1d
    800033a0:	cdc48493          	addi	s1,s1,-804 # 80020078 <icache+0x18>
    800033a4:	0001e697          	auipc	a3,0x1e
    800033a8:	76468693          	addi	a3,a3,1892 # 80021b08 <log>
    800033ac:	a039                	j	800033ba <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ae:	02090b63          	beqz	s2,800033e4 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033b2:	08848493          	addi	s1,s1,136
    800033b6:	02d48a63          	beq	s1,a3,800033ea <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033ba:	449c                	lw	a5,8(s1)
    800033bc:	fef059e3          	blez	a5,800033ae <iget+0x38>
    800033c0:	4098                	lw	a4,0(s1)
    800033c2:	ff3716e3          	bne	a4,s3,800033ae <iget+0x38>
    800033c6:	40d8                	lw	a4,4(s1)
    800033c8:	ff4713e3          	bne	a4,s4,800033ae <iget+0x38>
      ip->ref++;
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033d0:	0001d517          	auipc	a0,0x1d
    800033d4:	c9050513          	addi	a0,a0,-880 # 80020060 <icache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	8dc080e7          	jalr	-1828(ra) # 80000cb4 <release>
      return ip;
    800033e0:	8926                	mv	s2,s1
    800033e2:	a03d                	j	80003410 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e4:	f7f9                	bnez	a5,800033b2 <iget+0x3c>
    800033e6:	8926                	mv	s2,s1
    800033e8:	b7e9                	j	800033b2 <iget+0x3c>
  if(empty == 0)
    800033ea:	02090c63          	beqz	s2,80003422 <iget+0xac>
  ip->dev = dev;
    800033ee:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033f2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033f6:	4785                	li	a5,1
    800033f8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800033fc:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003400:	0001d517          	auipc	a0,0x1d
    80003404:	c6050513          	addi	a0,a0,-928 # 80020060 <icache>
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	8ac080e7          	jalr	-1876(ra) # 80000cb4 <release>
}
    80003410:	854a                	mv	a0,s2
    80003412:	70a2                	ld	ra,40(sp)
    80003414:	7402                	ld	s0,32(sp)
    80003416:	64e2                	ld	s1,24(sp)
    80003418:	6942                	ld	s2,16(sp)
    8000341a:	69a2                	ld	s3,8(sp)
    8000341c:	6a02                	ld	s4,0(sp)
    8000341e:	6145                	addi	sp,sp,48
    80003420:	8082                	ret
    panic("iget: no inodes");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	1fe50513          	addi	a0,a0,510 # 80008620 <syscalls+0x138>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	11c080e7          	jalr	284(ra) # 80000546 <panic>

0000000080003432 <fsinit>:
fsinit(int dev) {
    80003432:	7179                	addi	sp,sp,-48
    80003434:	f406                	sd	ra,40(sp)
    80003436:	f022                	sd	s0,32(sp)
    80003438:	ec26                	sd	s1,24(sp)
    8000343a:	e84a                	sd	s2,16(sp)
    8000343c:	e44e                	sd	s3,8(sp)
    8000343e:	1800                	addi	s0,sp,48
    80003440:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003442:	4585                	li	a1,1
    80003444:	00000097          	auipc	ra,0x0
    80003448:	a66080e7          	jalr	-1434(ra) # 80002eaa <bread>
    8000344c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000344e:	0001d997          	auipc	s3,0x1d
    80003452:	bf298993          	addi	s3,s3,-1038 # 80020040 <sb>
    80003456:	02000613          	li	a2,32
    8000345a:	05850593          	addi	a1,a0,88
    8000345e:	854e                	mv	a0,s3
    80003460:	ffffe097          	auipc	ra,0xffffe
    80003464:	8f8080e7          	jalr	-1800(ra) # 80000d58 <memmove>
  brelse(bp);
    80003468:	8526                	mv	a0,s1
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	b70080e7          	jalr	-1168(ra) # 80002fda <brelse>
  if(sb.magic != FSMAGIC)
    80003472:	0009a703          	lw	a4,0(s3)
    80003476:	102037b7          	lui	a5,0x10203
    8000347a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000347e:	02f71263          	bne	a4,a5,800034a2 <fsinit+0x70>
  initlog(dev, &sb);
    80003482:	0001d597          	auipc	a1,0x1d
    80003486:	bbe58593          	addi	a1,a1,-1090 # 80020040 <sb>
    8000348a:	854a                	mv	a0,s2
    8000348c:	00001097          	auipc	ra,0x1
    80003490:	b42080e7          	jalr	-1214(ra) # 80003fce <initlog>
}
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    panic("invalid file system");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	18e50513          	addi	a0,a0,398 # 80008630 <syscalls+0x148>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	09c080e7          	jalr	156(ra) # 80000546 <panic>

00000000800034b2 <iinit>:
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034c0:	00005597          	auipc	a1,0x5
    800034c4:	18858593          	addi	a1,a1,392 # 80008648 <syscalls+0x160>
    800034c8:	0001d517          	auipc	a0,0x1d
    800034cc:	b9850513          	addi	a0,a0,-1128 # 80020060 <icache>
    800034d0:	ffffd097          	auipc	ra,0xffffd
    800034d4:	6a0080e7          	jalr	1696(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034d8:	0001d497          	auipc	s1,0x1d
    800034dc:	bb048493          	addi	s1,s1,-1104 # 80020088 <icache+0x28>
    800034e0:	0001e997          	auipc	s3,0x1e
    800034e4:	63898993          	addi	s3,s3,1592 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034e8:	00005917          	auipc	s2,0x5
    800034ec:	16890913          	addi	s2,s2,360 # 80008650 <syscalls+0x168>
    800034f0:	85ca                	mv	a1,s2
    800034f2:	8526                	mv	a0,s1
    800034f4:	00001097          	auipc	ra,0x1
    800034f8:	e3e080e7          	jalr	-450(ra) # 80004332 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800034fc:	08848493          	addi	s1,s1,136
    80003500:	ff3498e3          	bne	s1,s3,800034f0 <iinit+0x3e>
}
    80003504:	70a2                	ld	ra,40(sp)
    80003506:	7402                	ld	s0,32(sp)
    80003508:	64e2                	ld	s1,24(sp)
    8000350a:	6942                	ld	s2,16(sp)
    8000350c:	69a2                	ld	s3,8(sp)
    8000350e:	6145                	addi	sp,sp,48
    80003510:	8082                	ret

0000000080003512 <ialloc>:
{
    80003512:	715d                	addi	sp,sp,-80
    80003514:	e486                	sd	ra,72(sp)
    80003516:	e0a2                	sd	s0,64(sp)
    80003518:	fc26                	sd	s1,56(sp)
    8000351a:	f84a                	sd	s2,48(sp)
    8000351c:	f44e                	sd	s3,40(sp)
    8000351e:	f052                	sd	s4,32(sp)
    80003520:	ec56                	sd	s5,24(sp)
    80003522:	e85a                	sd	s6,16(sp)
    80003524:	e45e                	sd	s7,8(sp)
    80003526:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003528:	0001d717          	auipc	a4,0x1d
    8000352c:	b2472703          	lw	a4,-1244(a4) # 8002004c <sb+0xc>
    80003530:	4785                	li	a5,1
    80003532:	04e7fa63          	bgeu	a5,a4,80003586 <ialloc+0x74>
    80003536:	8aaa                	mv	s5,a0
    80003538:	8bae                	mv	s7,a1
    8000353a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000353c:	0001da17          	auipc	s4,0x1d
    80003540:	b04a0a13          	addi	s4,s4,-1276 # 80020040 <sb>
    80003544:	00048b1b          	sext.w	s6,s1
    80003548:	0044d593          	srli	a1,s1,0x4
    8000354c:	018a2783          	lw	a5,24(s4)
    80003550:	9dbd                	addw	a1,a1,a5
    80003552:	8556                	mv	a0,s5
    80003554:	00000097          	auipc	ra,0x0
    80003558:	956080e7          	jalr	-1706(ra) # 80002eaa <bread>
    8000355c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000355e:	05850993          	addi	s3,a0,88
    80003562:	00f4f793          	andi	a5,s1,15
    80003566:	079a                	slli	a5,a5,0x6
    80003568:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000356a:	00099783          	lh	a5,0(s3)
    8000356e:	c785                	beqz	a5,80003596 <ialloc+0x84>
    brelse(bp);
    80003570:	00000097          	auipc	ra,0x0
    80003574:	a6a080e7          	jalr	-1430(ra) # 80002fda <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003578:	0485                	addi	s1,s1,1
    8000357a:	00ca2703          	lw	a4,12(s4)
    8000357e:	0004879b          	sext.w	a5,s1
    80003582:	fce7e1e3          	bltu	a5,a4,80003544 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003586:	00005517          	auipc	a0,0x5
    8000358a:	0d250513          	addi	a0,a0,210 # 80008658 <syscalls+0x170>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	fb8080e7          	jalr	-72(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    80003596:	04000613          	li	a2,64
    8000359a:	4581                	li	a1,0
    8000359c:	854e                	mv	a0,s3
    8000359e:	ffffd097          	auipc	ra,0xffffd
    800035a2:	75e080e7          	jalr	1886(ra) # 80000cfc <memset>
      dip->type = type;
    800035a6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035aa:	854a                	mv	a0,s2
    800035ac:	00001097          	auipc	ra,0x1
    800035b0:	c9a080e7          	jalr	-870(ra) # 80004246 <log_write>
      brelse(bp);
    800035b4:	854a                	mv	a0,s2
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	a24080e7          	jalr	-1500(ra) # 80002fda <brelse>
      return iget(dev, inum);
    800035be:	85da                	mv	a1,s6
    800035c0:	8556                	mv	a0,s5
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	db4080e7          	jalr	-588(ra) # 80003376 <iget>
}
    800035ca:	60a6                	ld	ra,72(sp)
    800035cc:	6406                	ld	s0,64(sp)
    800035ce:	74e2                	ld	s1,56(sp)
    800035d0:	7942                	ld	s2,48(sp)
    800035d2:	79a2                	ld	s3,40(sp)
    800035d4:	7a02                	ld	s4,32(sp)
    800035d6:	6ae2                	ld	s5,24(sp)
    800035d8:	6b42                	ld	s6,16(sp)
    800035da:	6ba2                	ld	s7,8(sp)
    800035dc:	6161                	addi	sp,sp,80
    800035de:	8082                	ret

00000000800035e0 <iupdate>:
{
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	e04a                	sd	s2,0(sp)
    800035ea:	1000                	addi	s0,sp,32
    800035ec:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035ee:	415c                	lw	a5,4(a0)
    800035f0:	0047d79b          	srliw	a5,a5,0x4
    800035f4:	0001d597          	auipc	a1,0x1d
    800035f8:	a645a583          	lw	a1,-1436(a1) # 80020058 <sb+0x18>
    800035fc:	9dbd                	addw	a1,a1,a5
    800035fe:	4108                	lw	a0,0(a0)
    80003600:	00000097          	auipc	ra,0x0
    80003604:	8aa080e7          	jalr	-1878(ra) # 80002eaa <bread>
    80003608:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000360a:	05850793          	addi	a5,a0,88
    8000360e:	40d8                	lw	a4,4(s1)
    80003610:	8b3d                	andi	a4,a4,15
    80003612:	071a                	slli	a4,a4,0x6
    80003614:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003616:	04449703          	lh	a4,68(s1)
    8000361a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000361e:	04649703          	lh	a4,70(s1)
    80003622:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003626:	04849703          	lh	a4,72(s1)
    8000362a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000362e:	04a49703          	lh	a4,74(s1)
    80003632:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003636:	44f8                	lw	a4,76(s1)
    80003638:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000363a:	03400613          	li	a2,52
    8000363e:	05048593          	addi	a1,s1,80
    80003642:	00c78513          	addi	a0,a5,12
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	712080e7          	jalr	1810(ra) # 80000d58 <memmove>
  log_write(bp);
    8000364e:	854a                	mv	a0,s2
    80003650:	00001097          	auipc	ra,0x1
    80003654:	bf6080e7          	jalr	-1034(ra) # 80004246 <log_write>
  brelse(bp);
    80003658:	854a                	mv	a0,s2
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	980080e7          	jalr	-1664(ra) # 80002fda <brelse>
}
    80003662:	60e2                	ld	ra,24(sp)
    80003664:	6442                	ld	s0,16(sp)
    80003666:	64a2                	ld	s1,8(sp)
    80003668:	6902                	ld	s2,0(sp)
    8000366a:	6105                	addi	sp,sp,32
    8000366c:	8082                	ret

000000008000366e <idup>:
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	1000                	addi	s0,sp,32
    80003678:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000367a:	0001d517          	auipc	a0,0x1d
    8000367e:	9e650513          	addi	a0,a0,-1562 # 80020060 <icache>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	57e080e7          	jalr	1406(ra) # 80000c00 <acquire>
  ip->ref++;
    8000368a:	449c                	lw	a5,8(s1)
    8000368c:	2785                	addiw	a5,a5,1
    8000368e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003690:	0001d517          	auipc	a0,0x1d
    80003694:	9d050513          	addi	a0,a0,-1584 # 80020060 <icache>
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	61c080e7          	jalr	1564(ra) # 80000cb4 <release>
}
    800036a0:	8526                	mv	a0,s1
    800036a2:	60e2                	ld	ra,24(sp)
    800036a4:	6442                	ld	s0,16(sp)
    800036a6:	64a2                	ld	s1,8(sp)
    800036a8:	6105                	addi	sp,sp,32
    800036aa:	8082                	ret

00000000800036ac <ilock>:
{
    800036ac:	1101                	addi	sp,sp,-32
    800036ae:	ec06                	sd	ra,24(sp)
    800036b0:	e822                	sd	s0,16(sp)
    800036b2:	e426                	sd	s1,8(sp)
    800036b4:	e04a                	sd	s2,0(sp)
    800036b6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036b8:	c115                	beqz	a0,800036dc <ilock+0x30>
    800036ba:	84aa                	mv	s1,a0
    800036bc:	451c                	lw	a5,8(a0)
    800036be:	00f05f63          	blez	a5,800036dc <ilock+0x30>
  acquiresleep(&ip->lock);
    800036c2:	0541                	addi	a0,a0,16
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	ca8080e7          	jalr	-856(ra) # 8000436c <acquiresleep>
  if(ip->valid == 0){
    800036cc:	40bc                	lw	a5,64(s1)
    800036ce:	cf99                	beqz	a5,800036ec <ilock+0x40>
}
    800036d0:	60e2                	ld	ra,24(sp)
    800036d2:	6442                	ld	s0,16(sp)
    800036d4:	64a2                	ld	s1,8(sp)
    800036d6:	6902                	ld	s2,0(sp)
    800036d8:	6105                	addi	sp,sp,32
    800036da:	8082                	ret
    panic("ilock");
    800036dc:	00005517          	auipc	a0,0x5
    800036e0:	f9450513          	addi	a0,a0,-108 # 80008670 <syscalls+0x188>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	e62080e7          	jalr	-414(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ec:	40dc                	lw	a5,4(s1)
    800036ee:	0047d79b          	srliw	a5,a5,0x4
    800036f2:	0001d597          	auipc	a1,0x1d
    800036f6:	9665a583          	lw	a1,-1690(a1) # 80020058 <sb+0x18>
    800036fa:	9dbd                	addw	a1,a1,a5
    800036fc:	4088                	lw	a0,0(s1)
    800036fe:	fffff097          	auipc	ra,0xfffff
    80003702:	7ac080e7          	jalr	1964(ra) # 80002eaa <bread>
    80003706:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003708:	05850593          	addi	a1,a0,88
    8000370c:	40dc                	lw	a5,4(s1)
    8000370e:	8bbd                	andi	a5,a5,15
    80003710:	079a                	slli	a5,a5,0x6
    80003712:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003714:	00059783          	lh	a5,0(a1)
    80003718:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000371c:	00259783          	lh	a5,2(a1)
    80003720:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003724:	00459783          	lh	a5,4(a1)
    80003728:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000372c:	00659783          	lh	a5,6(a1)
    80003730:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003734:	459c                	lw	a5,8(a1)
    80003736:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003738:	03400613          	li	a2,52
    8000373c:	05b1                	addi	a1,a1,12
    8000373e:	05048513          	addi	a0,s1,80
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	616080e7          	jalr	1558(ra) # 80000d58 <memmove>
    brelse(bp);
    8000374a:	854a                	mv	a0,s2
    8000374c:	00000097          	auipc	ra,0x0
    80003750:	88e080e7          	jalr	-1906(ra) # 80002fda <brelse>
    ip->valid = 1;
    80003754:	4785                	li	a5,1
    80003756:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003758:	04449783          	lh	a5,68(s1)
    8000375c:	fbb5                	bnez	a5,800036d0 <ilock+0x24>
      panic("ilock: no type");
    8000375e:	00005517          	auipc	a0,0x5
    80003762:	f1a50513          	addi	a0,a0,-230 # 80008678 <syscalls+0x190>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	de0080e7          	jalr	-544(ra) # 80000546 <panic>

000000008000376e <iunlock>:
{
    8000376e:	1101                	addi	sp,sp,-32
    80003770:	ec06                	sd	ra,24(sp)
    80003772:	e822                	sd	s0,16(sp)
    80003774:	e426                	sd	s1,8(sp)
    80003776:	e04a                	sd	s2,0(sp)
    80003778:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000377a:	c905                	beqz	a0,800037aa <iunlock+0x3c>
    8000377c:	84aa                	mv	s1,a0
    8000377e:	01050913          	addi	s2,a0,16
    80003782:	854a                	mv	a0,s2
    80003784:	00001097          	auipc	ra,0x1
    80003788:	c82080e7          	jalr	-894(ra) # 80004406 <holdingsleep>
    8000378c:	cd19                	beqz	a0,800037aa <iunlock+0x3c>
    8000378e:	449c                	lw	a5,8(s1)
    80003790:	00f05d63          	blez	a5,800037aa <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003794:	854a                	mv	a0,s2
    80003796:	00001097          	auipc	ra,0x1
    8000379a:	c2c080e7          	jalr	-980(ra) # 800043c2 <releasesleep>
}
    8000379e:	60e2                	ld	ra,24(sp)
    800037a0:	6442                	ld	s0,16(sp)
    800037a2:	64a2                	ld	s1,8(sp)
    800037a4:	6902                	ld	s2,0(sp)
    800037a6:	6105                	addi	sp,sp,32
    800037a8:	8082                	ret
    panic("iunlock");
    800037aa:	00005517          	auipc	a0,0x5
    800037ae:	ede50513          	addi	a0,a0,-290 # 80008688 <syscalls+0x1a0>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	d94080e7          	jalr	-620(ra) # 80000546 <panic>

00000000800037ba <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037ba:	7179                	addi	sp,sp,-48
    800037bc:	f406                	sd	ra,40(sp)
    800037be:	f022                	sd	s0,32(sp)
    800037c0:	ec26                	sd	s1,24(sp)
    800037c2:	e84a                	sd	s2,16(sp)
    800037c4:	e44e                	sd	s3,8(sp)
    800037c6:	e052                	sd	s4,0(sp)
    800037c8:	1800                	addi	s0,sp,48
    800037ca:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037cc:	05050493          	addi	s1,a0,80
    800037d0:	08050913          	addi	s2,a0,128
    800037d4:	a021                	j	800037dc <itrunc+0x22>
    800037d6:	0491                	addi	s1,s1,4
    800037d8:	01248d63          	beq	s1,s2,800037f2 <itrunc+0x38>
    if(ip->addrs[i]){
    800037dc:	408c                	lw	a1,0(s1)
    800037de:	dde5                	beqz	a1,800037d6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037e0:	0009a503          	lw	a0,0(s3)
    800037e4:	00000097          	auipc	ra,0x0
    800037e8:	90c080e7          	jalr	-1780(ra) # 800030f0 <bfree>
      ip->addrs[i] = 0;
    800037ec:	0004a023          	sw	zero,0(s1)
    800037f0:	b7dd                	j	800037d6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037f2:	0809a583          	lw	a1,128(s3)
    800037f6:	e185                	bnez	a1,80003816 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800037f8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800037fc:	854e                	mv	a0,s3
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	de2080e7          	jalr	-542(ra) # 800035e0 <iupdate>
}
    80003806:	70a2                	ld	ra,40(sp)
    80003808:	7402                	ld	s0,32(sp)
    8000380a:	64e2                	ld	s1,24(sp)
    8000380c:	6942                	ld	s2,16(sp)
    8000380e:	69a2                	ld	s3,8(sp)
    80003810:	6a02                	ld	s4,0(sp)
    80003812:	6145                	addi	sp,sp,48
    80003814:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003816:	0009a503          	lw	a0,0(s3)
    8000381a:	fffff097          	auipc	ra,0xfffff
    8000381e:	690080e7          	jalr	1680(ra) # 80002eaa <bread>
    80003822:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003824:	05850493          	addi	s1,a0,88
    80003828:	45850913          	addi	s2,a0,1112
    8000382c:	a021                	j	80003834 <itrunc+0x7a>
    8000382e:	0491                	addi	s1,s1,4
    80003830:	01248b63          	beq	s1,s2,80003846 <itrunc+0x8c>
      if(a[j])
    80003834:	408c                	lw	a1,0(s1)
    80003836:	dde5                	beqz	a1,8000382e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003838:	0009a503          	lw	a0,0(s3)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	8b4080e7          	jalr	-1868(ra) # 800030f0 <bfree>
    80003844:	b7ed                	j	8000382e <itrunc+0x74>
    brelse(bp);
    80003846:	8552                	mv	a0,s4
    80003848:	fffff097          	auipc	ra,0xfffff
    8000384c:	792080e7          	jalr	1938(ra) # 80002fda <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003850:	0809a583          	lw	a1,128(s3)
    80003854:	0009a503          	lw	a0,0(s3)
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	898080e7          	jalr	-1896(ra) # 800030f0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003860:	0809a023          	sw	zero,128(s3)
    80003864:	bf51                	j	800037f8 <itrunc+0x3e>

0000000080003866 <iput>:
{
    80003866:	1101                	addi	sp,sp,-32
    80003868:	ec06                	sd	ra,24(sp)
    8000386a:	e822                	sd	s0,16(sp)
    8000386c:	e426                	sd	s1,8(sp)
    8000386e:	e04a                	sd	s2,0(sp)
    80003870:	1000                	addi	s0,sp,32
    80003872:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003874:	0001c517          	auipc	a0,0x1c
    80003878:	7ec50513          	addi	a0,a0,2028 # 80020060 <icache>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	384080e7          	jalr	900(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003884:	4498                	lw	a4,8(s1)
    80003886:	4785                	li	a5,1
    80003888:	02f70363          	beq	a4,a5,800038ae <iput+0x48>
  ip->ref--;
    8000388c:	449c                	lw	a5,8(s1)
    8000388e:	37fd                	addiw	a5,a5,-1
    80003890:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003892:	0001c517          	auipc	a0,0x1c
    80003896:	7ce50513          	addi	a0,a0,1998 # 80020060 <icache>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	41a080e7          	jalr	1050(ra) # 80000cb4 <release>
}
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	64a2                	ld	s1,8(sp)
    800038a8:	6902                	ld	s2,0(sp)
    800038aa:	6105                	addi	sp,sp,32
    800038ac:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ae:	40bc                	lw	a5,64(s1)
    800038b0:	dff1                	beqz	a5,8000388c <iput+0x26>
    800038b2:	04a49783          	lh	a5,74(s1)
    800038b6:	fbf9                	bnez	a5,8000388c <iput+0x26>
    acquiresleep(&ip->lock);
    800038b8:	01048913          	addi	s2,s1,16
    800038bc:	854a                	mv	a0,s2
    800038be:	00001097          	auipc	ra,0x1
    800038c2:	aae080e7          	jalr	-1362(ra) # 8000436c <acquiresleep>
    release(&icache.lock);
    800038c6:	0001c517          	auipc	a0,0x1c
    800038ca:	79a50513          	addi	a0,a0,1946 # 80020060 <icache>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	3e6080e7          	jalr	998(ra) # 80000cb4 <release>
    itrunc(ip);
    800038d6:	8526                	mv	a0,s1
    800038d8:	00000097          	auipc	ra,0x0
    800038dc:	ee2080e7          	jalr	-286(ra) # 800037ba <itrunc>
    ip->type = 0;
    800038e0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038e4:	8526                	mv	a0,s1
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	cfa080e7          	jalr	-774(ra) # 800035e0 <iupdate>
    ip->valid = 0;
    800038ee:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00001097          	auipc	ra,0x1
    800038f8:	ace080e7          	jalr	-1330(ra) # 800043c2 <releasesleep>
    acquire(&icache.lock);
    800038fc:	0001c517          	auipc	a0,0x1c
    80003900:	76450513          	addi	a0,a0,1892 # 80020060 <icache>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	2fc080e7          	jalr	764(ra) # 80000c00 <acquire>
    8000390c:	b741                	j	8000388c <iput+0x26>

000000008000390e <iunlockput>:
{
    8000390e:	1101                	addi	sp,sp,-32
    80003910:	ec06                	sd	ra,24(sp)
    80003912:	e822                	sd	s0,16(sp)
    80003914:	e426                	sd	s1,8(sp)
    80003916:	1000                	addi	s0,sp,32
    80003918:	84aa                	mv	s1,a0
  iunlock(ip);
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	e54080e7          	jalr	-428(ra) # 8000376e <iunlock>
  iput(ip);
    80003922:	8526                	mv	a0,s1
    80003924:	00000097          	auipc	ra,0x0
    80003928:	f42080e7          	jalr	-190(ra) # 80003866 <iput>
}
    8000392c:	60e2                	ld	ra,24(sp)
    8000392e:	6442                	ld	s0,16(sp)
    80003930:	64a2                	ld	s1,8(sp)
    80003932:	6105                	addi	sp,sp,32
    80003934:	8082                	ret

0000000080003936 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003936:	1141                	addi	sp,sp,-16
    80003938:	e422                	sd	s0,8(sp)
    8000393a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000393c:	411c                	lw	a5,0(a0)
    8000393e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003940:	415c                	lw	a5,4(a0)
    80003942:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003944:	04451783          	lh	a5,68(a0)
    80003948:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000394c:	04a51783          	lh	a5,74(a0)
    80003950:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003954:	04c56783          	lwu	a5,76(a0)
    80003958:	e99c                	sd	a5,16(a1)
}
    8000395a:	6422                	ld	s0,8(sp)
    8000395c:	0141                	addi	sp,sp,16
    8000395e:	8082                	ret

0000000080003960 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003960:	457c                	lw	a5,76(a0)
    80003962:	0ed7e863          	bltu	a5,a3,80003a52 <readi+0xf2>
{
    80003966:	7159                	addi	sp,sp,-112
    80003968:	f486                	sd	ra,104(sp)
    8000396a:	f0a2                	sd	s0,96(sp)
    8000396c:	eca6                	sd	s1,88(sp)
    8000396e:	e8ca                	sd	s2,80(sp)
    80003970:	e4ce                	sd	s3,72(sp)
    80003972:	e0d2                	sd	s4,64(sp)
    80003974:	fc56                	sd	s5,56(sp)
    80003976:	f85a                	sd	s6,48(sp)
    80003978:	f45e                	sd	s7,40(sp)
    8000397a:	f062                	sd	s8,32(sp)
    8000397c:	ec66                	sd	s9,24(sp)
    8000397e:	e86a                	sd	s10,16(sp)
    80003980:	e46e                	sd	s11,8(sp)
    80003982:	1880                	addi	s0,sp,112
    80003984:	8baa                	mv	s7,a0
    80003986:	8c2e                	mv	s8,a1
    80003988:	8ab2                	mv	s5,a2
    8000398a:	84b6                	mv	s1,a3
    8000398c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000398e:	9f35                	addw	a4,a4,a3
    return 0;
    80003990:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003992:	08d76f63          	bltu	a4,a3,80003a30 <readi+0xd0>
  if(off + n > ip->size)
    80003996:	00e7f463          	bgeu	a5,a4,8000399e <readi+0x3e>
    n = ip->size - off;
    8000399a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000399e:	0a0b0863          	beqz	s6,80003a4e <readi+0xee>
    800039a2:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039a4:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039a8:	5cfd                	li	s9,-1
    800039aa:	a82d                	j	800039e4 <readi+0x84>
    800039ac:	020a1d93          	slli	s11,s4,0x20
    800039b0:	020ddd93          	srli	s11,s11,0x20
    800039b4:	05890613          	addi	a2,s2,88
    800039b8:	86ee                	mv	a3,s11
    800039ba:	963a                	add	a2,a2,a4
    800039bc:	85d6                	mv	a1,s5
    800039be:	8562                	mv	a0,s8
    800039c0:	fffff097          	auipc	ra,0xfffff
    800039c4:	aa6080e7          	jalr	-1370(ra) # 80002466 <either_copyout>
    800039c8:	05950d63          	beq	a0,s9,80003a22 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039cc:	854a                	mv	a0,s2
    800039ce:	fffff097          	auipc	ra,0xfffff
    800039d2:	60c080e7          	jalr	1548(ra) # 80002fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039d6:	013a09bb          	addw	s3,s4,s3
    800039da:	009a04bb          	addw	s1,s4,s1
    800039de:	9aee                	add	s5,s5,s11
    800039e0:	0569f663          	bgeu	s3,s6,80003a2c <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039e4:	000ba903          	lw	s2,0(s7)
    800039e8:	00a4d59b          	srliw	a1,s1,0xa
    800039ec:	855e                	mv	a0,s7
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	8ac080e7          	jalr	-1876(ra) # 8000329a <bmap>
    800039f6:	0005059b          	sext.w	a1,a0
    800039fa:	854a                	mv	a0,s2
    800039fc:	fffff097          	auipc	ra,0xfffff
    80003a00:	4ae080e7          	jalr	1198(ra) # 80002eaa <bread>
    80003a04:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a06:	3ff4f713          	andi	a4,s1,1023
    80003a0a:	40ed07bb          	subw	a5,s10,a4
    80003a0e:	413b06bb          	subw	a3,s6,s3
    80003a12:	8a3e                	mv	s4,a5
    80003a14:	2781                	sext.w	a5,a5
    80003a16:	0006861b          	sext.w	a2,a3
    80003a1a:	f8f679e3          	bgeu	a2,a5,800039ac <readi+0x4c>
    80003a1e:	8a36                	mv	s4,a3
    80003a20:	b771                	j	800039ac <readi+0x4c>
      brelse(bp);
    80003a22:	854a                	mv	a0,s2
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	5b6080e7          	jalr	1462(ra) # 80002fda <brelse>
  }
  return tot;
    80003a2c:	0009851b          	sext.w	a0,s3
}
    80003a30:	70a6                	ld	ra,104(sp)
    80003a32:	7406                	ld	s0,96(sp)
    80003a34:	64e6                	ld	s1,88(sp)
    80003a36:	6946                	ld	s2,80(sp)
    80003a38:	69a6                	ld	s3,72(sp)
    80003a3a:	6a06                	ld	s4,64(sp)
    80003a3c:	7ae2                	ld	s5,56(sp)
    80003a3e:	7b42                	ld	s6,48(sp)
    80003a40:	7ba2                	ld	s7,40(sp)
    80003a42:	7c02                	ld	s8,32(sp)
    80003a44:	6ce2                	ld	s9,24(sp)
    80003a46:	6d42                	ld	s10,16(sp)
    80003a48:	6da2                	ld	s11,8(sp)
    80003a4a:	6165                	addi	sp,sp,112
    80003a4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	89da                	mv	s3,s6
    80003a50:	bff1                	j	80003a2c <readi+0xcc>
    return 0;
    80003a52:	4501                	li	a0,0
}
    80003a54:	8082                	ret

0000000080003a56 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a56:	457c                	lw	a5,76(a0)
    80003a58:	10d7e663          	bltu	a5,a3,80003b64 <writei+0x10e>
{
    80003a5c:	7159                	addi	sp,sp,-112
    80003a5e:	f486                	sd	ra,104(sp)
    80003a60:	f0a2                	sd	s0,96(sp)
    80003a62:	eca6                	sd	s1,88(sp)
    80003a64:	e8ca                	sd	s2,80(sp)
    80003a66:	e4ce                	sd	s3,72(sp)
    80003a68:	e0d2                	sd	s4,64(sp)
    80003a6a:	fc56                	sd	s5,56(sp)
    80003a6c:	f85a                	sd	s6,48(sp)
    80003a6e:	f45e                	sd	s7,40(sp)
    80003a70:	f062                	sd	s8,32(sp)
    80003a72:	ec66                	sd	s9,24(sp)
    80003a74:	e86a                	sd	s10,16(sp)
    80003a76:	e46e                	sd	s11,8(sp)
    80003a78:	1880                	addi	s0,sp,112
    80003a7a:	8baa                	mv	s7,a0
    80003a7c:	8c2e                	mv	s8,a1
    80003a7e:	8ab2                	mv	s5,a2
    80003a80:	8936                	mv	s2,a3
    80003a82:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a84:	00e687bb          	addw	a5,a3,a4
    80003a88:	0ed7e063          	bltu	a5,a3,80003b68 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a8c:	00043737          	lui	a4,0x43
    80003a90:	0cf76e63          	bltu	a4,a5,80003b6c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a94:	0a0b0763          	beqz	s6,80003b42 <writei+0xec>
    80003a98:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a9a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a9e:	5cfd                	li	s9,-1
    80003aa0:	a091                	j	80003ae4 <writei+0x8e>
    80003aa2:	02099d93          	slli	s11,s3,0x20
    80003aa6:	020ddd93          	srli	s11,s11,0x20
    80003aaa:	05848513          	addi	a0,s1,88
    80003aae:	86ee                	mv	a3,s11
    80003ab0:	8656                	mv	a2,s5
    80003ab2:	85e2                	mv	a1,s8
    80003ab4:	953a                	add	a0,a0,a4
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	a06080e7          	jalr	-1530(ra) # 800024bc <either_copyin>
    80003abe:	07950263          	beq	a0,s9,80003b22 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ac2:	8526                	mv	a0,s1
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	782080e7          	jalr	1922(ra) # 80004246 <log_write>
    brelse(bp);
    80003acc:	8526                	mv	a0,s1
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	50c080e7          	jalr	1292(ra) # 80002fda <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad6:	01498a3b          	addw	s4,s3,s4
    80003ada:	0129893b          	addw	s2,s3,s2
    80003ade:	9aee                	add	s5,s5,s11
    80003ae0:	056a7663          	bgeu	s4,s6,80003b2c <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ae4:	000ba483          	lw	s1,0(s7)
    80003ae8:	00a9559b          	srliw	a1,s2,0xa
    80003aec:	855e                	mv	a0,s7
    80003aee:	fffff097          	auipc	ra,0xfffff
    80003af2:	7ac080e7          	jalr	1964(ra) # 8000329a <bmap>
    80003af6:	0005059b          	sext.w	a1,a0
    80003afa:	8526                	mv	a0,s1
    80003afc:	fffff097          	auipc	ra,0xfffff
    80003b00:	3ae080e7          	jalr	942(ra) # 80002eaa <bread>
    80003b04:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b06:	3ff97713          	andi	a4,s2,1023
    80003b0a:	40ed07bb          	subw	a5,s10,a4
    80003b0e:	414b06bb          	subw	a3,s6,s4
    80003b12:	89be                	mv	s3,a5
    80003b14:	2781                	sext.w	a5,a5
    80003b16:	0006861b          	sext.w	a2,a3
    80003b1a:	f8f674e3          	bgeu	a2,a5,80003aa2 <writei+0x4c>
    80003b1e:	89b6                	mv	s3,a3
    80003b20:	b749                	j	80003aa2 <writei+0x4c>
      brelse(bp);
    80003b22:	8526                	mv	a0,s1
    80003b24:	fffff097          	auipc	ra,0xfffff
    80003b28:	4b6080e7          	jalr	1206(ra) # 80002fda <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b2c:	04cba783          	lw	a5,76(s7)
    80003b30:	0127f463          	bgeu	a5,s2,80003b38 <writei+0xe2>
      ip->size = off;
    80003b34:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b38:	855e                	mv	a0,s7
    80003b3a:	00000097          	auipc	ra,0x0
    80003b3e:	aa6080e7          	jalr	-1370(ra) # 800035e0 <iupdate>
  }

  return n;
    80003b42:	000b051b          	sext.w	a0,s6
}
    80003b46:	70a6                	ld	ra,104(sp)
    80003b48:	7406                	ld	s0,96(sp)
    80003b4a:	64e6                	ld	s1,88(sp)
    80003b4c:	6946                	ld	s2,80(sp)
    80003b4e:	69a6                	ld	s3,72(sp)
    80003b50:	6a06                	ld	s4,64(sp)
    80003b52:	7ae2                	ld	s5,56(sp)
    80003b54:	7b42                	ld	s6,48(sp)
    80003b56:	7ba2                	ld	s7,40(sp)
    80003b58:	7c02                	ld	s8,32(sp)
    80003b5a:	6ce2                	ld	s9,24(sp)
    80003b5c:	6d42                	ld	s10,16(sp)
    80003b5e:	6da2                	ld	s11,8(sp)
    80003b60:	6165                	addi	sp,sp,112
    80003b62:	8082                	ret
    return -1;
    80003b64:	557d                	li	a0,-1
}
    80003b66:	8082                	ret
    return -1;
    80003b68:	557d                	li	a0,-1
    80003b6a:	bff1                	j	80003b46 <writei+0xf0>
    return -1;
    80003b6c:	557d                	li	a0,-1
    80003b6e:	bfe1                	j	80003b46 <writei+0xf0>

0000000080003b70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b70:	1141                	addi	sp,sp,-16
    80003b72:	e406                	sd	ra,8(sp)
    80003b74:	e022                	sd	s0,0(sp)
    80003b76:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b78:	4639                	li	a2,14
    80003b7a:	ffffd097          	auipc	ra,0xffffd
    80003b7e:	25a080e7          	jalr	602(ra) # 80000dd4 <strncmp>
}
    80003b82:	60a2                	ld	ra,8(sp)
    80003b84:	6402                	ld	s0,0(sp)
    80003b86:	0141                	addi	sp,sp,16
    80003b88:	8082                	ret

0000000080003b8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b8a:	7139                	addi	sp,sp,-64
    80003b8c:	fc06                	sd	ra,56(sp)
    80003b8e:	f822                	sd	s0,48(sp)
    80003b90:	f426                	sd	s1,40(sp)
    80003b92:	f04a                	sd	s2,32(sp)
    80003b94:	ec4e                	sd	s3,24(sp)
    80003b96:	e852                	sd	s4,16(sp)
    80003b98:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b9a:	04451703          	lh	a4,68(a0)
    80003b9e:	4785                	li	a5,1
    80003ba0:	00f71a63          	bne	a4,a5,80003bb4 <dirlookup+0x2a>
    80003ba4:	892a                	mv	s2,a0
    80003ba6:	89ae                	mv	s3,a1
    80003ba8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003baa:	457c                	lw	a5,76(a0)
    80003bac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb0:	e79d                	bnez	a5,80003bde <dirlookup+0x54>
    80003bb2:	a8a5                	j	80003c2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bb4:	00005517          	auipc	a0,0x5
    80003bb8:	adc50513          	addi	a0,a0,-1316 # 80008690 <syscalls+0x1a8>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	98a080e7          	jalr	-1654(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	ae450513          	addi	a0,a0,-1308 # 800086a8 <syscalls+0x1c0>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	97a080e7          	jalr	-1670(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bd4:	24c1                	addiw	s1,s1,16
    80003bd6:	04c92783          	lw	a5,76(s2)
    80003bda:	04f4f763          	bgeu	s1,a5,80003c28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bde:	4741                	li	a4,16
    80003be0:	86a6                	mv	a3,s1
    80003be2:	fc040613          	addi	a2,s0,-64
    80003be6:	4581                	li	a1,0
    80003be8:	854a                	mv	a0,s2
    80003bea:	00000097          	auipc	ra,0x0
    80003bee:	d76080e7          	jalr	-650(ra) # 80003960 <readi>
    80003bf2:	47c1                	li	a5,16
    80003bf4:	fcf518e3          	bne	a0,a5,80003bc4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003bf8:	fc045783          	lhu	a5,-64(s0)
    80003bfc:	dfe1                	beqz	a5,80003bd4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003bfe:	fc240593          	addi	a1,s0,-62
    80003c02:	854e                	mv	a0,s3
    80003c04:	00000097          	auipc	ra,0x0
    80003c08:	f6c080e7          	jalr	-148(ra) # 80003b70 <namecmp>
    80003c0c:	f561                	bnez	a0,80003bd4 <dirlookup+0x4a>
      if(poff)
    80003c0e:	000a0463          	beqz	s4,80003c16 <dirlookup+0x8c>
        *poff = off;
    80003c12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c16:	fc045583          	lhu	a1,-64(s0)
    80003c1a:	00092503          	lw	a0,0(s2)
    80003c1e:	fffff097          	auipc	ra,0xfffff
    80003c22:	758080e7          	jalr	1880(ra) # 80003376 <iget>
    80003c26:	a011                	j	80003c2a <dirlookup+0xa0>
  return 0;
    80003c28:	4501                	li	a0,0
}
    80003c2a:	70e2                	ld	ra,56(sp)
    80003c2c:	7442                	ld	s0,48(sp)
    80003c2e:	74a2                	ld	s1,40(sp)
    80003c30:	7902                	ld	s2,32(sp)
    80003c32:	69e2                	ld	s3,24(sp)
    80003c34:	6a42                	ld	s4,16(sp)
    80003c36:	6121                	addi	sp,sp,64
    80003c38:	8082                	ret

0000000080003c3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c3a:	711d                	addi	sp,sp,-96
    80003c3c:	ec86                	sd	ra,88(sp)
    80003c3e:	e8a2                	sd	s0,80(sp)
    80003c40:	e4a6                	sd	s1,72(sp)
    80003c42:	e0ca                	sd	s2,64(sp)
    80003c44:	fc4e                	sd	s3,56(sp)
    80003c46:	f852                	sd	s4,48(sp)
    80003c48:	f456                	sd	s5,40(sp)
    80003c4a:	f05a                	sd	s6,32(sp)
    80003c4c:	ec5e                	sd	s7,24(sp)
    80003c4e:	e862                	sd	s8,16(sp)
    80003c50:	e466                	sd	s9,8(sp)
    80003c52:	e06a                	sd	s10,0(sp)
    80003c54:	1080                	addi	s0,sp,96
    80003c56:	84aa                	mv	s1,a0
    80003c58:	8b2e                	mv	s6,a1
    80003c5a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c5c:	00054703          	lbu	a4,0(a0)
    80003c60:	02f00793          	li	a5,47
    80003c64:	02f70363          	beq	a4,a5,80003c8a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c68:	ffffe097          	auipc	ra,0xffffe
    80003c6c:	d64080e7          	jalr	-668(ra) # 800019cc <myproc>
    80003c70:	15053503          	ld	a0,336(a0)
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	9fa080e7          	jalr	-1542(ra) # 8000366e <idup>
    80003c7c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c7e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c82:	4cb5                	li	s9,13
  len = path - s;
    80003c84:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c86:	4c05                	li	s8,1
    80003c88:	a87d                	j	80003d46 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c8a:	4585                	li	a1,1
    80003c8c:	4505                	li	a0,1
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	6e8080e7          	jalr	1768(ra) # 80003376 <iget>
    80003c96:	8a2a                	mv	s4,a0
    80003c98:	b7dd                	j	80003c7e <namex+0x44>
      iunlockput(ip);
    80003c9a:	8552                	mv	a0,s4
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	c72080e7          	jalr	-910(ra) # 8000390e <iunlockput>
      return 0;
    80003ca4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ca6:	8552                	mv	a0,s4
    80003ca8:	60e6                	ld	ra,88(sp)
    80003caa:	6446                	ld	s0,80(sp)
    80003cac:	64a6                	ld	s1,72(sp)
    80003cae:	6906                	ld	s2,64(sp)
    80003cb0:	79e2                	ld	s3,56(sp)
    80003cb2:	7a42                	ld	s4,48(sp)
    80003cb4:	7aa2                	ld	s5,40(sp)
    80003cb6:	7b02                	ld	s6,32(sp)
    80003cb8:	6be2                	ld	s7,24(sp)
    80003cba:	6c42                	ld	s8,16(sp)
    80003cbc:	6ca2                	ld	s9,8(sp)
    80003cbe:	6d02                	ld	s10,0(sp)
    80003cc0:	6125                	addi	sp,sp,96
    80003cc2:	8082                	ret
      iunlock(ip);
    80003cc4:	8552                	mv	a0,s4
    80003cc6:	00000097          	auipc	ra,0x0
    80003cca:	aa8080e7          	jalr	-1368(ra) # 8000376e <iunlock>
      return ip;
    80003cce:	bfe1                	j	80003ca6 <namex+0x6c>
      iunlockput(ip);
    80003cd0:	8552                	mv	a0,s4
    80003cd2:	00000097          	auipc	ra,0x0
    80003cd6:	c3c080e7          	jalr	-964(ra) # 8000390e <iunlockput>
      return 0;
    80003cda:	8a4e                	mv	s4,s3
    80003cdc:	b7e9                	j	80003ca6 <namex+0x6c>
  len = path - s;
    80003cde:	40998633          	sub	a2,s3,s1
    80003ce2:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003ce6:	09acd863          	bge	s9,s10,80003d76 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003cea:	4639                	li	a2,14
    80003cec:	85a6                	mv	a1,s1
    80003cee:	8556                	mv	a0,s5
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	068080e7          	jalr	104(ra) # 80000d58 <memmove>
    80003cf8:	84ce                	mv	s1,s3
  while(*path == '/')
    80003cfa:	0004c783          	lbu	a5,0(s1)
    80003cfe:	01279763          	bne	a5,s2,80003d0c <namex+0xd2>
    path++;
    80003d02:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d04:	0004c783          	lbu	a5,0(s1)
    80003d08:	ff278de3          	beq	a5,s2,80003d02 <namex+0xc8>
    ilock(ip);
    80003d0c:	8552                	mv	a0,s4
    80003d0e:	00000097          	auipc	ra,0x0
    80003d12:	99e080e7          	jalr	-1634(ra) # 800036ac <ilock>
    if(ip->type != T_DIR){
    80003d16:	044a1783          	lh	a5,68(s4)
    80003d1a:	f98790e3          	bne	a5,s8,80003c9a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d1e:	000b0563          	beqz	s6,80003d28 <namex+0xee>
    80003d22:	0004c783          	lbu	a5,0(s1)
    80003d26:	dfd9                	beqz	a5,80003cc4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d28:	865e                	mv	a2,s7
    80003d2a:	85d6                	mv	a1,s5
    80003d2c:	8552                	mv	a0,s4
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	e5c080e7          	jalr	-420(ra) # 80003b8a <dirlookup>
    80003d36:	89aa                	mv	s3,a0
    80003d38:	dd41                	beqz	a0,80003cd0 <namex+0x96>
    iunlockput(ip);
    80003d3a:	8552                	mv	a0,s4
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	bd2080e7          	jalr	-1070(ra) # 8000390e <iunlockput>
    ip = next;
    80003d44:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d46:	0004c783          	lbu	a5,0(s1)
    80003d4a:	01279763          	bne	a5,s2,80003d58 <namex+0x11e>
    path++;
    80003d4e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d50:	0004c783          	lbu	a5,0(s1)
    80003d54:	ff278de3          	beq	a5,s2,80003d4e <namex+0x114>
  if(*path == 0)
    80003d58:	cb9d                	beqz	a5,80003d8e <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d5a:	0004c783          	lbu	a5,0(s1)
    80003d5e:	89a6                	mv	s3,s1
  len = path - s;
    80003d60:	8d5e                	mv	s10,s7
    80003d62:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d64:	01278963          	beq	a5,s2,80003d76 <namex+0x13c>
    80003d68:	dbbd                	beqz	a5,80003cde <namex+0xa4>
    path++;
    80003d6a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d6c:	0009c783          	lbu	a5,0(s3)
    80003d70:	ff279ce3          	bne	a5,s2,80003d68 <namex+0x12e>
    80003d74:	b7ad                	j	80003cde <namex+0xa4>
    memmove(name, s, len);
    80003d76:	2601                	sext.w	a2,a2
    80003d78:	85a6                	mv	a1,s1
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	fdc080e7          	jalr	-36(ra) # 80000d58 <memmove>
    name[len] = 0;
    80003d84:	9d56                	add	s10,s10,s5
    80003d86:	000d0023          	sb	zero,0(s10)
    80003d8a:	84ce                	mv	s1,s3
    80003d8c:	b7bd                	j	80003cfa <namex+0xc0>
  if(nameiparent){
    80003d8e:	f00b0ce3          	beqz	s6,80003ca6 <namex+0x6c>
    iput(ip);
    80003d92:	8552                	mv	a0,s4
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	ad2080e7          	jalr	-1326(ra) # 80003866 <iput>
    return 0;
    80003d9c:	4a01                	li	s4,0
    80003d9e:	b721                	j	80003ca6 <namex+0x6c>

0000000080003da0 <dirlink>:
{
    80003da0:	7139                	addi	sp,sp,-64
    80003da2:	fc06                	sd	ra,56(sp)
    80003da4:	f822                	sd	s0,48(sp)
    80003da6:	f426                	sd	s1,40(sp)
    80003da8:	f04a                	sd	s2,32(sp)
    80003daa:	ec4e                	sd	s3,24(sp)
    80003dac:	e852                	sd	s4,16(sp)
    80003dae:	0080                	addi	s0,sp,64
    80003db0:	892a                	mv	s2,a0
    80003db2:	8a2e                	mv	s4,a1
    80003db4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003db6:	4601                	li	a2,0
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	dd2080e7          	jalr	-558(ra) # 80003b8a <dirlookup>
    80003dc0:	e93d                	bnez	a0,80003e36 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dc2:	04c92483          	lw	s1,76(s2)
    80003dc6:	c49d                	beqz	s1,80003df4 <dirlink+0x54>
    80003dc8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dca:	4741                	li	a4,16
    80003dcc:	86a6                	mv	a3,s1
    80003dce:	fc040613          	addi	a2,s0,-64
    80003dd2:	4581                	li	a1,0
    80003dd4:	854a                	mv	a0,s2
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	b8a080e7          	jalr	-1142(ra) # 80003960 <readi>
    80003dde:	47c1                	li	a5,16
    80003de0:	06f51163          	bne	a0,a5,80003e42 <dirlink+0xa2>
    if(de.inum == 0)
    80003de4:	fc045783          	lhu	a5,-64(s0)
    80003de8:	c791                	beqz	a5,80003df4 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dea:	24c1                	addiw	s1,s1,16
    80003dec:	04c92783          	lw	a5,76(s2)
    80003df0:	fcf4ede3          	bltu	s1,a5,80003dca <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003df4:	4639                	li	a2,14
    80003df6:	85d2                	mv	a1,s4
    80003df8:	fc240513          	addi	a0,s0,-62
    80003dfc:	ffffd097          	auipc	ra,0xffffd
    80003e00:	014080e7          	jalr	20(ra) # 80000e10 <strncpy>
  de.inum = inum;
    80003e04:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e08:	4741                	li	a4,16
    80003e0a:	86a6                	mv	a3,s1
    80003e0c:	fc040613          	addi	a2,s0,-64
    80003e10:	4581                	li	a1,0
    80003e12:	854a                	mv	a0,s2
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	c42080e7          	jalr	-958(ra) # 80003a56 <writei>
    80003e1c:	872a                	mv	a4,a0
    80003e1e:	47c1                	li	a5,16
  return 0;
    80003e20:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e22:	02f71863          	bne	a4,a5,80003e52 <dirlink+0xb2>
}
    80003e26:	70e2                	ld	ra,56(sp)
    80003e28:	7442                	ld	s0,48(sp)
    80003e2a:	74a2                	ld	s1,40(sp)
    80003e2c:	7902                	ld	s2,32(sp)
    80003e2e:	69e2                	ld	s3,24(sp)
    80003e30:	6a42                	ld	s4,16(sp)
    80003e32:	6121                	addi	sp,sp,64
    80003e34:	8082                	ret
    iput(ip);
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	a30080e7          	jalr	-1488(ra) # 80003866 <iput>
    return -1;
    80003e3e:	557d                	li	a0,-1
    80003e40:	b7dd                	j	80003e26 <dirlink+0x86>
      panic("dirlink read");
    80003e42:	00005517          	auipc	a0,0x5
    80003e46:	87650513          	addi	a0,a0,-1930 # 800086b8 <syscalls+0x1d0>
    80003e4a:	ffffc097          	auipc	ra,0xffffc
    80003e4e:	6fc080e7          	jalr	1788(ra) # 80000546 <panic>
    panic("dirlink");
    80003e52:	00005517          	auipc	a0,0x5
    80003e56:	97e50513          	addi	a0,a0,-1666 # 800087d0 <syscalls+0x2e8>
    80003e5a:	ffffc097          	auipc	ra,0xffffc
    80003e5e:	6ec080e7          	jalr	1772(ra) # 80000546 <panic>

0000000080003e62 <namei>:

struct inode*
namei(char *path)
{
    80003e62:	1101                	addi	sp,sp,-32
    80003e64:	ec06                	sd	ra,24(sp)
    80003e66:	e822                	sd	s0,16(sp)
    80003e68:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e6a:	fe040613          	addi	a2,s0,-32
    80003e6e:	4581                	li	a1,0
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	dca080e7          	jalr	-566(ra) # 80003c3a <namex>
}
    80003e78:	60e2                	ld	ra,24(sp)
    80003e7a:	6442                	ld	s0,16(sp)
    80003e7c:	6105                	addi	sp,sp,32
    80003e7e:	8082                	ret

0000000080003e80 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e80:	1141                	addi	sp,sp,-16
    80003e82:	e406                	sd	ra,8(sp)
    80003e84:	e022                	sd	s0,0(sp)
    80003e86:	0800                	addi	s0,sp,16
    80003e88:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e8a:	4585                	li	a1,1
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	dae080e7          	jalr	-594(ra) # 80003c3a <namex>
}
    80003e94:	60a2                	ld	ra,8(sp)
    80003e96:	6402                	ld	s0,0(sp)
    80003e98:	0141                	addi	sp,sp,16
    80003e9a:	8082                	ret

0000000080003e9c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e9c:	1101                	addi	sp,sp,-32
    80003e9e:	ec06                	sd	ra,24(sp)
    80003ea0:	e822                	sd	s0,16(sp)
    80003ea2:	e426                	sd	s1,8(sp)
    80003ea4:	e04a                	sd	s2,0(sp)
    80003ea6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ea8:	0001e917          	auipc	s2,0x1e
    80003eac:	c6090913          	addi	s2,s2,-928 # 80021b08 <log>
    80003eb0:	01892583          	lw	a1,24(s2)
    80003eb4:	02892503          	lw	a0,40(s2)
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	ff2080e7          	jalr	-14(ra) # 80002eaa <bread>
    80003ec0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ec2:	02c92683          	lw	a3,44(s2)
    80003ec6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ec8:	02d05863          	blez	a3,80003ef8 <write_head+0x5c>
    80003ecc:	0001e797          	auipc	a5,0x1e
    80003ed0:	c6c78793          	addi	a5,a5,-916 # 80021b38 <log+0x30>
    80003ed4:	05c50713          	addi	a4,a0,92
    80003ed8:	36fd                	addiw	a3,a3,-1
    80003eda:	02069613          	slli	a2,a3,0x20
    80003ede:	01e65693          	srli	a3,a2,0x1e
    80003ee2:	0001e617          	auipc	a2,0x1e
    80003ee6:	c5a60613          	addi	a2,a2,-934 # 80021b3c <log+0x34>
    80003eea:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003eec:	4390                	lw	a2,0(a5)
    80003eee:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ef0:	0791                	addi	a5,a5,4
    80003ef2:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003ef4:	fed79ce3          	bne	a5,a3,80003eec <write_head+0x50>
  }
  bwrite(buf);
    80003ef8:	8526                	mv	a0,s1
    80003efa:	fffff097          	auipc	ra,0xfffff
    80003efe:	0a2080e7          	jalr	162(ra) # 80002f9c <bwrite>
  brelse(buf);
    80003f02:	8526                	mv	a0,s1
    80003f04:	fffff097          	auipc	ra,0xfffff
    80003f08:	0d6080e7          	jalr	214(ra) # 80002fda <brelse>
}
    80003f0c:	60e2                	ld	ra,24(sp)
    80003f0e:	6442                	ld	s0,16(sp)
    80003f10:	64a2                	ld	s1,8(sp)
    80003f12:	6902                	ld	s2,0(sp)
    80003f14:	6105                	addi	sp,sp,32
    80003f16:	8082                	ret

0000000080003f18 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f18:	0001e797          	auipc	a5,0x1e
    80003f1c:	c1c7a783          	lw	a5,-996(a5) # 80021b34 <log+0x2c>
    80003f20:	0af05663          	blez	a5,80003fcc <install_trans+0xb4>
{
    80003f24:	7139                	addi	sp,sp,-64
    80003f26:	fc06                	sd	ra,56(sp)
    80003f28:	f822                	sd	s0,48(sp)
    80003f2a:	f426                	sd	s1,40(sp)
    80003f2c:	f04a                	sd	s2,32(sp)
    80003f2e:	ec4e                	sd	s3,24(sp)
    80003f30:	e852                	sd	s4,16(sp)
    80003f32:	e456                	sd	s5,8(sp)
    80003f34:	0080                	addi	s0,sp,64
    80003f36:	0001ea97          	auipc	s5,0x1e
    80003f3a:	c02a8a93          	addi	s5,s5,-1022 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f3e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f40:	0001e997          	auipc	s3,0x1e
    80003f44:	bc898993          	addi	s3,s3,-1080 # 80021b08 <log>
    80003f48:	0189a583          	lw	a1,24(s3)
    80003f4c:	014585bb          	addw	a1,a1,s4
    80003f50:	2585                	addiw	a1,a1,1
    80003f52:	0289a503          	lw	a0,40(s3)
    80003f56:	fffff097          	auipc	ra,0xfffff
    80003f5a:	f54080e7          	jalr	-172(ra) # 80002eaa <bread>
    80003f5e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f60:	000aa583          	lw	a1,0(s5)
    80003f64:	0289a503          	lw	a0,40(s3)
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	f42080e7          	jalr	-190(ra) # 80002eaa <bread>
    80003f70:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f72:	40000613          	li	a2,1024
    80003f76:	05890593          	addi	a1,s2,88
    80003f7a:	05850513          	addi	a0,a0,88
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	dda080e7          	jalr	-550(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f86:	8526                	mv	a0,s1
    80003f88:	fffff097          	auipc	ra,0xfffff
    80003f8c:	014080e7          	jalr	20(ra) # 80002f9c <bwrite>
    bunpin(dbuf);
    80003f90:	8526                	mv	a0,s1
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	122080e7          	jalr	290(ra) # 800030b4 <bunpin>
    brelse(lbuf);
    80003f9a:	854a                	mv	a0,s2
    80003f9c:	fffff097          	auipc	ra,0xfffff
    80003fa0:	03e080e7          	jalr	62(ra) # 80002fda <brelse>
    brelse(dbuf);
    80003fa4:	8526                	mv	a0,s1
    80003fa6:	fffff097          	auipc	ra,0xfffff
    80003faa:	034080e7          	jalr	52(ra) # 80002fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fae:	2a05                	addiw	s4,s4,1
    80003fb0:	0a91                	addi	s5,s5,4
    80003fb2:	02c9a783          	lw	a5,44(s3)
    80003fb6:	f8fa49e3          	blt	s4,a5,80003f48 <install_trans+0x30>
}
    80003fba:	70e2                	ld	ra,56(sp)
    80003fbc:	7442                	ld	s0,48(sp)
    80003fbe:	74a2                	ld	s1,40(sp)
    80003fc0:	7902                	ld	s2,32(sp)
    80003fc2:	69e2                	ld	s3,24(sp)
    80003fc4:	6a42                	ld	s4,16(sp)
    80003fc6:	6aa2                	ld	s5,8(sp)
    80003fc8:	6121                	addi	sp,sp,64
    80003fca:	8082                	ret
    80003fcc:	8082                	ret

0000000080003fce <initlog>:
{
    80003fce:	7179                	addi	sp,sp,-48
    80003fd0:	f406                	sd	ra,40(sp)
    80003fd2:	f022                	sd	s0,32(sp)
    80003fd4:	ec26                	sd	s1,24(sp)
    80003fd6:	e84a                	sd	s2,16(sp)
    80003fd8:	e44e                	sd	s3,8(sp)
    80003fda:	1800                	addi	s0,sp,48
    80003fdc:	892a                	mv	s2,a0
    80003fde:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fe0:	0001e497          	auipc	s1,0x1e
    80003fe4:	b2848493          	addi	s1,s1,-1240 # 80021b08 <log>
    80003fe8:	00004597          	auipc	a1,0x4
    80003fec:	6e058593          	addi	a1,a1,1760 # 800086c8 <syscalls+0x1e0>
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	b7e080e7          	jalr	-1154(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    80003ffa:	0149a583          	lw	a1,20(s3)
    80003ffe:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004000:	0109a783          	lw	a5,16(s3)
    80004004:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004006:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000400a:	854a                	mv	a0,s2
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	e9e080e7          	jalr	-354(ra) # 80002eaa <bread>
  log.lh.n = lh->n;
    80004014:	4d34                	lw	a3,88(a0)
    80004016:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004018:	02d05663          	blez	a3,80004044 <initlog+0x76>
    8000401c:	05c50793          	addi	a5,a0,92
    80004020:	0001e717          	auipc	a4,0x1e
    80004024:	b1870713          	addi	a4,a4,-1256 # 80021b38 <log+0x30>
    80004028:	36fd                	addiw	a3,a3,-1
    8000402a:	02069613          	slli	a2,a3,0x20
    8000402e:	01e65693          	srli	a3,a2,0x1e
    80004032:	06050613          	addi	a2,a0,96
    80004036:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004038:	4390                	lw	a2,0(a5)
    8000403a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000403c:	0791                	addi	a5,a5,4
    8000403e:	0711                	addi	a4,a4,4
    80004040:	fed79ce3          	bne	a5,a3,80004038 <initlog+0x6a>
  brelse(buf);
    80004044:	fffff097          	auipc	ra,0xfffff
    80004048:	f96080e7          	jalr	-106(ra) # 80002fda <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	ecc080e7          	jalr	-308(ra) # 80003f18 <install_trans>
  log.lh.n = 0;
    80004054:	0001e797          	auipc	a5,0x1e
    80004058:	ae07a023          	sw	zero,-1312(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	e40080e7          	jalr	-448(ra) # 80003e9c <write_head>
}
    80004064:	70a2                	ld	ra,40(sp)
    80004066:	7402                	ld	s0,32(sp)
    80004068:	64e2                	ld	s1,24(sp)
    8000406a:	6942                	ld	s2,16(sp)
    8000406c:	69a2                	ld	s3,8(sp)
    8000406e:	6145                	addi	sp,sp,48
    80004070:	8082                	ret

0000000080004072 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004072:	1101                	addi	sp,sp,-32
    80004074:	ec06                	sd	ra,24(sp)
    80004076:	e822                	sd	s0,16(sp)
    80004078:	e426                	sd	s1,8(sp)
    8000407a:	e04a                	sd	s2,0(sp)
    8000407c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000407e:	0001e517          	auipc	a0,0x1e
    80004082:	a8a50513          	addi	a0,a0,-1398 # 80021b08 <log>
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	b7a080e7          	jalr	-1158(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    8000408e:	0001e497          	auipc	s1,0x1e
    80004092:	a7a48493          	addi	s1,s1,-1414 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004096:	4979                	li	s2,30
    80004098:	a039                	j	800040a6 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000409a:	85a6                	mv	a1,s1
    8000409c:	8526                	mv	a0,s1
    8000409e:	ffffe097          	auipc	ra,0xffffe
    800040a2:	14a080e7          	jalr	330(ra) # 800021e8 <sleep>
    if(log.committing){
    800040a6:	50dc                	lw	a5,36(s1)
    800040a8:	fbed                	bnez	a5,8000409a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040aa:	5098                	lw	a4,32(s1)
    800040ac:	2705                	addiw	a4,a4,1
    800040ae:	0007069b          	sext.w	a3,a4
    800040b2:	0027179b          	slliw	a5,a4,0x2
    800040b6:	9fb9                	addw	a5,a5,a4
    800040b8:	0017979b          	slliw	a5,a5,0x1
    800040bc:	54d8                	lw	a4,44(s1)
    800040be:	9fb9                	addw	a5,a5,a4
    800040c0:	00f95963          	bge	s2,a5,800040d2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040c4:	85a6                	mv	a1,s1
    800040c6:	8526                	mv	a0,s1
    800040c8:	ffffe097          	auipc	ra,0xffffe
    800040cc:	120080e7          	jalr	288(ra) # 800021e8 <sleep>
    800040d0:	bfd9                	j	800040a6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040d2:	0001e517          	auipc	a0,0x1e
    800040d6:	a3650513          	addi	a0,a0,-1482 # 80021b08 <log>
    800040da:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	bd8080e7          	jalr	-1064(ra) # 80000cb4 <release>
      break;
    }
  }
}
    800040e4:	60e2                	ld	ra,24(sp)
    800040e6:	6442                	ld	s0,16(sp)
    800040e8:	64a2                	ld	s1,8(sp)
    800040ea:	6902                	ld	s2,0(sp)
    800040ec:	6105                	addi	sp,sp,32
    800040ee:	8082                	ret

00000000800040f0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040f0:	7139                	addi	sp,sp,-64
    800040f2:	fc06                	sd	ra,56(sp)
    800040f4:	f822                	sd	s0,48(sp)
    800040f6:	f426                	sd	s1,40(sp)
    800040f8:	f04a                	sd	s2,32(sp)
    800040fa:	ec4e                	sd	s3,24(sp)
    800040fc:	e852                	sd	s4,16(sp)
    800040fe:	e456                	sd	s5,8(sp)
    80004100:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004102:	0001e497          	auipc	s1,0x1e
    80004106:	a0648493          	addi	s1,s1,-1530 # 80021b08 <log>
    8000410a:	8526                	mv	a0,s1
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	af4080e7          	jalr	-1292(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    80004114:	509c                	lw	a5,32(s1)
    80004116:	37fd                	addiw	a5,a5,-1
    80004118:	0007891b          	sext.w	s2,a5
    8000411c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000411e:	50dc                	lw	a5,36(s1)
    80004120:	e7b9                	bnez	a5,8000416e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004122:	04091e63          	bnez	s2,8000417e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004126:	0001e497          	auipc	s1,0x1e
    8000412a:	9e248493          	addi	s1,s1,-1566 # 80021b08 <log>
    8000412e:	4785                	li	a5,1
    80004130:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004132:	8526                	mv	a0,s1
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	b80080e7          	jalr	-1152(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000413c:	54dc                	lw	a5,44(s1)
    8000413e:	06f04763          	bgtz	a5,800041ac <end_op+0xbc>
    acquire(&log.lock);
    80004142:	0001e497          	auipc	s1,0x1e
    80004146:	9c648493          	addi	s1,s1,-1594 # 80021b08 <log>
    8000414a:	8526                	mv	a0,s1
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	ab4080e7          	jalr	-1356(ra) # 80000c00 <acquire>
    log.committing = 0;
    80004154:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffe097          	auipc	ra,0xffffe
    8000415e:	20e080e7          	jalr	526(ra) # 80002368 <wakeup>
    release(&log.lock);
    80004162:	8526                	mv	a0,s1
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	b50080e7          	jalr	-1200(ra) # 80000cb4 <release>
}
    8000416c:	a03d                	j	8000419a <end_op+0xaa>
    panic("log.committing");
    8000416e:	00004517          	auipc	a0,0x4
    80004172:	56250513          	addi	a0,a0,1378 # 800086d0 <syscalls+0x1e8>
    80004176:	ffffc097          	auipc	ra,0xffffc
    8000417a:	3d0080e7          	jalr	976(ra) # 80000546 <panic>
    wakeup(&log);
    8000417e:	0001e497          	auipc	s1,0x1e
    80004182:	98a48493          	addi	s1,s1,-1654 # 80021b08 <log>
    80004186:	8526                	mv	a0,s1
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	1e0080e7          	jalr	480(ra) # 80002368 <wakeup>
  release(&log.lock);
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	b22080e7          	jalr	-1246(ra) # 80000cb4 <release>
}
    8000419a:	70e2                	ld	ra,56(sp)
    8000419c:	7442                	ld	s0,48(sp)
    8000419e:	74a2                	ld	s1,40(sp)
    800041a0:	7902                	ld	s2,32(sp)
    800041a2:	69e2                	ld	s3,24(sp)
    800041a4:	6a42                	ld	s4,16(sp)
    800041a6:	6aa2                	ld	s5,8(sp)
    800041a8:	6121                	addi	sp,sp,64
    800041aa:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ac:	0001ea97          	auipc	s5,0x1e
    800041b0:	98ca8a93          	addi	s5,s5,-1652 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041b4:	0001ea17          	auipc	s4,0x1e
    800041b8:	954a0a13          	addi	s4,s4,-1708 # 80021b08 <log>
    800041bc:	018a2583          	lw	a1,24(s4)
    800041c0:	012585bb          	addw	a1,a1,s2
    800041c4:	2585                	addiw	a1,a1,1
    800041c6:	028a2503          	lw	a0,40(s4)
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	ce0080e7          	jalr	-800(ra) # 80002eaa <bread>
    800041d2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041d4:	000aa583          	lw	a1,0(s5)
    800041d8:	028a2503          	lw	a0,40(s4)
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	cce080e7          	jalr	-818(ra) # 80002eaa <bread>
    800041e4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041e6:	40000613          	li	a2,1024
    800041ea:	05850593          	addi	a1,a0,88
    800041ee:	05848513          	addi	a0,s1,88
    800041f2:	ffffd097          	auipc	ra,0xffffd
    800041f6:	b66080e7          	jalr	-1178(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    800041fa:	8526                	mv	a0,s1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	da0080e7          	jalr	-608(ra) # 80002f9c <bwrite>
    brelse(from);
    80004204:	854e                	mv	a0,s3
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	dd4080e7          	jalr	-556(ra) # 80002fda <brelse>
    brelse(to);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	dca080e7          	jalr	-566(ra) # 80002fda <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004218:	2905                	addiw	s2,s2,1
    8000421a:	0a91                	addi	s5,s5,4
    8000421c:	02ca2783          	lw	a5,44(s4)
    80004220:	f8f94ee3          	blt	s2,a5,800041bc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004224:	00000097          	auipc	ra,0x0
    80004228:	c78080e7          	jalr	-904(ra) # 80003e9c <write_head>
    install_trans(); // Now install writes to home locations
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	cec080e7          	jalr	-788(ra) # 80003f18 <install_trans>
    log.lh.n = 0;
    80004234:	0001e797          	auipc	a5,0x1e
    80004238:	9007a023          	sw	zero,-1792(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	c60080e7          	jalr	-928(ra) # 80003e9c <write_head>
    80004244:	bdfd                	j	80004142 <end_op+0x52>

0000000080004246 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004246:	1101                	addi	sp,sp,-32
    80004248:	ec06                	sd	ra,24(sp)
    8000424a:	e822                	sd	s0,16(sp)
    8000424c:	e426                	sd	s1,8(sp)
    8000424e:	e04a                	sd	s2,0(sp)
    80004250:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004252:	0001e717          	auipc	a4,0x1e
    80004256:	8e272703          	lw	a4,-1822(a4) # 80021b34 <log+0x2c>
    8000425a:	47f5                	li	a5,29
    8000425c:	08e7c063          	blt	a5,a4,800042dc <log_write+0x96>
    80004260:	84aa                	mv	s1,a0
    80004262:	0001e797          	auipc	a5,0x1e
    80004266:	8c27a783          	lw	a5,-1854(a5) # 80021b24 <log+0x1c>
    8000426a:	37fd                	addiw	a5,a5,-1
    8000426c:	06f75863          	bge	a4,a5,800042dc <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004270:	0001e797          	auipc	a5,0x1e
    80004274:	8b87a783          	lw	a5,-1864(a5) # 80021b28 <log+0x20>
    80004278:	06f05a63          	blez	a5,800042ec <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000427c:	0001e917          	auipc	s2,0x1e
    80004280:	88c90913          	addi	s2,s2,-1908 # 80021b08 <log>
    80004284:	854a                	mv	a0,s2
    80004286:	ffffd097          	auipc	ra,0xffffd
    8000428a:	97a080e7          	jalr	-1670(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000428e:	02c92603          	lw	a2,44(s2)
    80004292:	06c05563          	blez	a2,800042fc <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004296:	44cc                	lw	a1,12(s1)
    80004298:	0001e717          	auipc	a4,0x1e
    8000429c:	8a070713          	addi	a4,a4,-1888 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042a0:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042a2:	4314                	lw	a3,0(a4)
    800042a4:	04b68d63          	beq	a3,a1,800042fe <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042a8:	2785                	addiw	a5,a5,1
    800042aa:	0711                	addi	a4,a4,4
    800042ac:	fec79be3          	bne	a5,a2,800042a2 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042b0:	0621                	addi	a2,a2,8
    800042b2:	060a                	slli	a2,a2,0x2
    800042b4:	0001e797          	auipc	a5,0x1e
    800042b8:	85478793          	addi	a5,a5,-1964 # 80021b08 <log>
    800042bc:	97b2                	add	a5,a5,a2
    800042be:	44d8                	lw	a4,12(s1)
    800042c0:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	db4080e7          	jalr	-588(ra) # 80003078 <bpin>
    log.lh.n++;
    800042cc:	0001e717          	auipc	a4,0x1e
    800042d0:	83c70713          	addi	a4,a4,-1988 # 80021b08 <log>
    800042d4:	575c                	lw	a5,44(a4)
    800042d6:	2785                	addiw	a5,a5,1
    800042d8:	d75c                	sw	a5,44(a4)
    800042da:	a835                	j	80004316 <log_write+0xd0>
    panic("too big a transaction");
    800042dc:	00004517          	auipc	a0,0x4
    800042e0:	40450513          	addi	a0,a0,1028 # 800086e0 <syscalls+0x1f8>
    800042e4:	ffffc097          	auipc	ra,0xffffc
    800042e8:	262080e7          	jalr	610(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    800042ec:	00004517          	auipc	a0,0x4
    800042f0:	40c50513          	addi	a0,a0,1036 # 800086f8 <syscalls+0x210>
    800042f4:	ffffc097          	auipc	ra,0xffffc
    800042f8:	252080e7          	jalr	594(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800042fc:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800042fe:	00878693          	addi	a3,a5,8
    80004302:	068a                	slli	a3,a3,0x2
    80004304:	0001e717          	auipc	a4,0x1e
    80004308:	80470713          	addi	a4,a4,-2044 # 80021b08 <log>
    8000430c:	9736                	add	a4,a4,a3
    8000430e:	44d4                	lw	a3,12(s1)
    80004310:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004312:	faf608e3          	beq	a2,a5,800042c2 <log_write+0x7c>
  }
  release(&log.lock);
    80004316:	0001d517          	auipc	a0,0x1d
    8000431a:	7f250513          	addi	a0,a0,2034 # 80021b08 <log>
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	996080e7          	jalr	-1642(ra) # 80000cb4 <release>
}
    80004326:	60e2                	ld	ra,24(sp)
    80004328:	6442                	ld	s0,16(sp)
    8000432a:	64a2                	ld	s1,8(sp)
    8000432c:	6902                	ld	s2,0(sp)
    8000432e:	6105                	addi	sp,sp,32
    80004330:	8082                	ret

0000000080004332 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004332:	1101                	addi	sp,sp,-32
    80004334:	ec06                	sd	ra,24(sp)
    80004336:	e822                	sd	s0,16(sp)
    80004338:	e426                	sd	s1,8(sp)
    8000433a:	e04a                	sd	s2,0(sp)
    8000433c:	1000                	addi	s0,sp,32
    8000433e:	84aa                	mv	s1,a0
    80004340:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004342:	00004597          	auipc	a1,0x4
    80004346:	3d658593          	addi	a1,a1,982 # 80008718 <syscalls+0x230>
    8000434a:	0521                	addi	a0,a0,8
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	824080e7          	jalr	-2012(ra) # 80000b70 <initlock>
  lk->name = name;
    80004354:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004358:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000435c:	0204a423          	sw	zero,40(s1)
}
    80004360:	60e2                	ld	ra,24(sp)
    80004362:	6442                	ld	s0,16(sp)
    80004364:	64a2                	ld	s1,8(sp)
    80004366:	6902                	ld	s2,0(sp)
    80004368:	6105                	addi	sp,sp,32
    8000436a:	8082                	ret

000000008000436c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
    80004378:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000437a:	00850913          	addi	s2,a0,8
    8000437e:	854a                	mv	a0,s2
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	880080e7          	jalr	-1920(ra) # 80000c00 <acquire>
  while (lk->locked) {
    80004388:	409c                	lw	a5,0(s1)
    8000438a:	cb89                	beqz	a5,8000439c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000438c:	85ca                	mv	a1,s2
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffe097          	auipc	ra,0xffffe
    80004394:	e58080e7          	jalr	-424(ra) # 800021e8 <sleep>
  while (lk->locked) {
    80004398:	409c                	lw	a5,0(s1)
    8000439a:	fbed                	bnez	a5,8000438c <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000439c:	4785                	li	a5,1
    8000439e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043a0:	ffffd097          	auipc	ra,0xffffd
    800043a4:	62c080e7          	jalr	1580(ra) # 800019cc <myproc>
    800043a8:	5d1c                	lw	a5,56(a0)
    800043aa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043ac:	854a                	mv	a0,s2
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	906080e7          	jalr	-1786(ra) # 80000cb4 <release>
}
    800043b6:	60e2                	ld	ra,24(sp)
    800043b8:	6442                	ld	s0,16(sp)
    800043ba:	64a2                	ld	s1,8(sp)
    800043bc:	6902                	ld	s2,0(sp)
    800043be:	6105                	addi	sp,sp,32
    800043c0:	8082                	ret

00000000800043c2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043c2:	1101                	addi	sp,sp,-32
    800043c4:	ec06                	sd	ra,24(sp)
    800043c6:	e822                	sd	s0,16(sp)
    800043c8:	e426                	sd	s1,8(sp)
    800043ca:	e04a                	sd	s2,0(sp)
    800043cc:	1000                	addi	s0,sp,32
    800043ce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d0:	00850913          	addi	s2,a0,8
    800043d4:	854a                	mv	a0,s2
    800043d6:	ffffd097          	auipc	ra,0xffffd
    800043da:	82a080e7          	jalr	-2006(ra) # 80000c00 <acquire>
  lk->locked = 0;
    800043de:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	f80080e7          	jalr	-128(ra) # 80002368 <wakeup>
  release(&lk->lk);
    800043f0:	854a                	mv	a0,s2
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	8c2080e7          	jalr	-1854(ra) # 80000cb4 <release>
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret

0000000080004406 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004406:	7179                	addi	sp,sp,-48
    80004408:	f406                	sd	ra,40(sp)
    8000440a:	f022                	sd	s0,32(sp)
    8000440c:	ec26                	sd	s1,24(sp)
    8000440e:	e84a                	sd	s2,16(sp)
    80004410:	e44e                	sd	s3,8(sp)
    80004412:	1800                	addi	s0,sp,48
    80004414:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004416:	00850913          	addi	s2,a0,8
    8000441a:	854a                	mv	a0,s2
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	7e4080e7          	jalr	2020(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004424:	409c                	lw	a5,0(s1)
    80004426:	ef99                	bnez	a5,80004444 <holdingsleep+0x3e>
    80004428:	4481                	li	s1,0
  release(&lk->lk);
    8000442a:	854a                	mv	a0,s2
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	888080e7          	jalr	-1912(ra) # 80000cb4 <release>
  return r;
}
    80004434:	8526                	mv	a0,s1
    80004436:	70a2                	ld	ra,40(sp)
    80004438:	7402                	ld	s0,32(sp)
    8000443a:	64e2                	ld	s1,24(sp)
    8000443c:	6942                	ld	s2,16(sp)
    8000443e:	69a2                	ld	s3,8(sp)
    80004440:	6145                	addi	sp,sp,48
    80004442:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004444:	0284a983          	lw	s3,40(s1)
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	584080e7          	jalr	1412(ra) # 800019cc <myproc>
    80004450:	5d04                	lw	s1,56(a0)
    80004452:	413484b3          	sub	s1,s1,s3
    80004456:	0014b493          	seqz	s1,s1
    8000445a:	bfc1                	j	8000442a <holdingsleep+0x24>

000000008000445c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000445c:	1141                	addi	sp,sp,-16
    8000445e:	e406                	sd	ra,8(sp)
    80004460:	e022                	sd	s0,0(sp)
    80004462:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004464:	00004597          	auipc	a1,0x4
    80004468:	2c458593          	addi	a1,a1,708 # 80008728 <syscalls+0x240>
    8000446c:	0001d517          	auipc	a0,0x1d
    80004470:	7e450513          	addi	a0,a0,2020 # 80021c50 <ftable>
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	6fc080e7          	jalr	1788(ra) # 80000b70 <initlock>
}
    8000447c:	60a2                	ld	ra,8(sp)
    8000447e:	6402                	ld	s0,0(sp)
    80004480:	0141                	addi	sp,sp,16
    80004482:	8082                	ret

0000000080004484 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004484:	1101                	addi	sp,sp,-32
    80004486:	ec06                	sd	ra,24(sp)
    80004488:	e822                	sd	s0,16(sp)
    8000448a:	e426                	sd	s1,8(sp)
    8000448c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000448e:	0001d517          	auipc	a0,0x1d
    80004492:	7c250513          	addi	a0,a0,1986 # 80021c50 <ftable>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	76a080e7          	jalr	1898(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000449e:	0001d497          	auipc	s1,0x1d
    800044a2:	7ca48493          	addi	s1,s1,1994 # 80021c68 <ftable+0x18>
    800044a6:	0001e717          	auipc	a4,0x1e
    800044aa:	76270713          	addi	a4,a4,1890 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800044ae:	40dc                	lw	a5,4(s1)
    800044b0:	cf99                	beqz	a5,800044ce <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044b2:	02848493          	addi	s1,s1,40
    800044b6:	fee49ce3          	bne	s1,a4,800044ae <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044ba:	0001d517          	auipc	a0,0x1d
    800044be:	79650513          	addi	a0,a0,1942 # 80021c50 <ftable>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	7f2080e7          	jalr	2034(ra) # 80000cb4 <release>
  return 0;
    800044ca:	4481                	li	s1,0
    800044cc:	a819                	j	800044e2 <filealloc+0x5e>
      f->ref = 1;
    800044ce:	4785                	li	a5,1
    800044d0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044d2:	0001d517          	auipc	a0,0x1d
    800044d6:	77e50513          	addi	a0,a0,1918 # 80021c50 <ftable>
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	7da080e7          	jalr	2010(ra) # 80000cb4 <release>
}
    800044e2:	8526                	mv	a0,s1
    800044e4:	60e2                	ld	ra,24(sp)
    800044e6:	6442                	ld	s0,16(sp)
    800044e8:	64a2                	ld	s1,8(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044ee:	1101                	addi	sp,sp,-32
    800044f0:	ec06                	sd	ra,24(sp)
    800044f2:	e822                	sd	s0,16(sp)
    800044f4:	e426                	sd	s1,8(sp)
    800044f6:	1000                	addi	s0,sp,32
    800044f8:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800044fa:	0001d517          	auipc	a0,0x1d
    800044fe:	75650513          	addi	a0,a0,1878 # 80021c50 <ftable>
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	6fe080e7          	jalr	1790(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    8000450a:	40dc                	lw	a5,4(s1)
    8000450c:	02f05263          	blez	a5,80004530 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004510:	2785                	addiw	a5,a5,1
    80004512:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004514:	0001d517          	auipc	a0,0x1d
    80004518:	73c50513          	addi	a0,a0,1852 # 80021c50 <ftable>
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	798080e7          	jalr	1944(ra) # 80000cb4 <release>
  return f;
}
    80004524:	8526                	mv	a0,s1
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6105                	addi	sp,sp,32
    8000452e:	8082                	ret
    panic("filedup");
    80004530:	00004517          	auipc	a0,0x4
    80004534:	20050513          	addi	a0,a0,512 # 80008730 <syscalls+0x248>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	00e080e7          	jalr	14(ra) # 80000546 <panic>

0000000080004540 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004540:	7139                	addi	sp,sp,-64
    80004542:	fc06                	sd	ra,56(sp)
    80004544:	f822                	sd	s0,48(sp)
    80004546:	f426                	sd	s1,40(sp)
    80004548:	f04a                	sd	s2,32(sp)
    8000454a:	ec4e                	sd	s3,24(sp)
    8000454c:	e852                	sd	s4,16(sp)
    8000454e:	e456                	sd	s5,8(sp)
    80004550:	0080                	addi	s0,sp,64
    80004552:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004554:	0001d517          	auipc	a0,0x1d
    80004558:	6fc50513          	addi	a0,a0,1788 # 80021c50 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	6a4080e7          	jalr	1700(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    80004564:	40dc                	lw	a5,4(s1)
    80004566:	06f05163          	blez	a5,800045c8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000456a:	37fd                	addiw	a5,a5,-1
    8000456c:	0007871b          	sext.w	a4,a5
    80004570:	c0dc                	sw	a5,4(s1)
    80004572:	06e04363          	bgtz	a4,800045d8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004576:	0004a903          	lw	s2,0(s1)
    8000457a:	0094ca83          	lbu	s5,9(s1)
    8000457e:	0104ba03          	ld	s4,16(s1)
    80004582:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004586:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000458a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000458e:	0001d517          	auipc	a0,0x1d
    80004592:	6c250513          	addi	a0,a0,1730 # 80021c50 <ftable>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	71e080e7          	jalr	1822(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    8000459e:	4785                	li	a5,1
    800045a0:	04f90d63          	beq	s2,a5,800045fa <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045a4:	3979                	addiw	s2,s2,-2
    800045a6:	4785                	li	a5,1
    800045a8:	0527e063          	bltu	a5,s2,800045e8 <fileclose+0xa8>
    begin_op();
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	ac6080e7          	jalr	-1338(ra) # 80004072 <begin_op>
    iput(ff.ip);
    800045b4:	854e                	mv	a0,s3
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	2b0080e7          	jalr	688(ra) # 80003866 <iput>
    end_op();
    800045be:	00000097          	auipc	ra,0x0
    800045c2:	b32080e7          	jalr	-1230(ra) # 800040f0 <end_op>
    800045c6:	a00d                	j	800045e8 <fileclose+0xa8>
    panic("fileclose");
    800045c8:	00004517          	auipc	a0,0x4
    800045cc:	17050513          	addi	a0,a0,368 # 80008738 <syscalls+0x250>
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	f76080e7          	jalr	-138(ra) # 80000546 <panic>
    release(&ftable.lock);
    800045d8:	0001d517          	auipc	a0,0x1d
    800045dc:	67850513          	addi	a0,a0,1656 # 80021c50 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6d4080e7          	jalr	1748(ra) # 80000cb4 <release>
  }
}
    800045e8:	70e2                	ld	ra,56(sp)
    800045ea:	7442                	ld	s0,48(sp)
    800045ec:	74a2                	ld	s1,40(sp)
    800045ee:	7902                	ld	s2,32(sp)
    800045f0:	69e2                	ld	s3,24(sp)
    800045f2:	6a42                	ld	s4,16(sp)
    800045f4:	6aa2                	ld	s5,8(sp)
    800045f6:	6121                	addi	sp,sp,64
    800045f8:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800045fa:	85d6                	mv	a1,s5
    800045fc:	8552                	mv	a0,s4
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	372080e7          	jalr	882(ra) # 80004970 <pipeclose>
    80004606:	b7cd                	j	800045e8 <fileclose+0xa8>

0000000080004608 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004608:	715d                	addi	sp,sp,-80
    8000460a:	e486                	sd	ra,72(sp)
    8000460c:	e0a2                	sd	s0,64(sp)
    8000460e:	fc26                	sd	s1,56(sp)
    80004610:	f84a                	sd	s2,48(sp)
    80004612:	f44e                	sd	s3,40(sp)
    80004614:	0880                	addi	s0,sp,80
    80004616:	84aa                	mv	s1,a0
    80004618:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000461a:	ffffd097          	auipc	ra,0xffffd
    8000461e:	3b2080e7          	jalr	946(ra) # 800019cc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004622:	409c                	lw	a5,0(s1)
    80004624:	37f9                	addiw	a5,a5,-2
    80004626:	4705                	li	a4,1
    80004628:	04f76763          	bltu	a4,a5,80004676 <filestat+0x6e>
    8000462c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000462e:	6c88                	ld	a0,24(s1)
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	07c080e7          	jalr	124(ra) # 800036ac <ilock>
    stati(f->ip, &st);
    80004638:	fb840593          	addi	a1,s0,-72
    8000463c:	6c88                	ld	a0,24(s1)
    8000463e:	fffff097          	auipc	ra,0xfffff
    80004642:	2f8080e7          	jalr	760(ra) # 80003936 <stati>
    iunlock(f->ip);
    80004646:	6c88                	ld	a0,24(s1)
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	126080e7          	jalr	294(ra) # 8000376e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004650:	46e1                	li	a3,24
    80004652:	fb840613          	addi	a2,s0,-72
    80004656:	85ce                	mv	a1,s3
    80004658:	05093503          	ld	a0,80(s2)
    8000465c:	ffffd097          	auipc	ra,0xffffd
    80004660:	066080e7          	jalr	102(ra) # 800016c2 <copyout>
    80004664:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004668:	60a6                	ld	ra,72(sp)
    8000466a:	6406                	ld	s0,64(sp)
    8000466c:	74e2                	ld	s1,56(sp)
    8000466e:	7942                	ld	s2,48(sp)
    80004670:	79a2                	ld	s3,40(sp)
    80004672:	6161                	addi	sp,sp,80
    80004674:	8082                	ret
  return -1;
    80004676:	557d                	li	a0,-1
    80004678:	bfc5                	j	80004668 <filestat+0x60>

000000008000467a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000467a:	7179                	addi	sp,sp,-48
    8000467c:	f406                	sd	ra,40(sp)
    8000467e:	f022                	sd	s0,32(sp)
    80004680:	ec26                	sd	s1,24(sp)
    80004682:	e84a                	sd	s2,16(sp)
    80004684:	e44e                	sd	s3,8(sp)
    80004686:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004688:	00854783          	lbu	a5,8(a0)
    8000468c:	c3d5                	beqz	a5,80004730 <fileread+0xb6>
    8000468e:	84aa                	mv	s1,a0
    80004690:	89ae                	mv	s3,a1
    80004692:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004694:	411c                	lw	a5,0(a0)
    80004696:	4705                	li	a4,1
    80004698:	04e78963          	beq	a5,a4,800046ea <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000469c:	470d                	li	a4,3
    8000469e:	04e78d63          	beq	a5,a4,800046f8 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046a2:	4709                	li	a4,2
    800046a4:	06e79e63          	bne	a5,a4,80004720 <fileread+0xa6>
    ilock(f->ip);
    800046a8:	6d08                	ld	a0,24(a0)
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	002080e7          	jalr	2(ra) # 800036ac <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046b2:	874a                	mv	a4,s2
    800046b4:	5094                	lw	a3,32(s1)
    800046b6:	864e                	mv	a2,s3
    800046b8:	4585                	li	a1,1
    800046ba:	6c88                	ld	a0,24(s1)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	2a4080e7          	jalr	676(ra) # 80003960 <readi>
    800046c4:	892a                	mv	s2,a0
    800046c6:	00a05563          	blez	a0,800046d0 <fileread+0x56>
      f->off += r;
    800046ca:	509c                	lw	a5,32(s1)
    800046cc:	9fa9                	addw	a5,a5,a0
    800046ce:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046d0:	6c88                	ld	a0,24(s1)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	09c080e7          	jalr	156(ra) # 8000376e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046da:	854a                	mv	a0,s2
    800046dc:	70a2                	ld	ra,40(sp)
    800046de:	7402                	ld	s0,32(sp)
    800046e0:	64e2                	ld	s1,24(sp)
    800046e2:	6942                	ld	s2,16(sp)
    800046e4:	69a2                	ld	s3,8(sp)
    800046e6:	6145                	addi	sp,sp,48
    800046e8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046ea:	6908                	ld	a0,16(a0)
    800046ec:	00000097          	auipc	ra,0x0
    800046f0:	3f6080e7          	jalr	1014(ra) # 80004ae2 <piperead>
    800046f4:	892a                	mv	s2,a0
    800046f6:	b7d5                	j	800046da <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800046f8:	02451783          	lh	a5,36(a0)
    800046fc:	03079693          	slli	a3,a5,0x30
    80004700:	92c1                	srli	a3,a3,0x30
    80004702:	4725                	li	a4,9
    80004704:	02d76863          	bltu	a4,a3,80004734 <fileread+0xba>
    80004708:	0792                	slli	a5,a5,0x4
    8000470a:	0001d717          	auipc	a4,0x1d
    8000470e:	4a670713          	addi	a4,a4,1190 # 80021bb0 <devsw>
    80004712:	97ba                	add	a5,a5,a4
    80004714:	639c                	ld	a5,0(a5)
    80004716:	c38d                	beqz	a5,80004738 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004718:	4505                	li	a0,1
    8000471a:	9782                	jalr	a5
    8000471c:	892a                	mv	s2,a0
    8000471e:	bf75                	j	800046da <fileread+0x60>
    panic("fileread");
    80004720:	00004517          	auipc	a0,0x4
    80004724:	02850513          	addi	a0,a0,40 # 80008748 <syscalls+0x260>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	e1e080e7          	jalr	-482(ra) # 80000546 <panic>
    return -1;
    80004730:	597d                	li	s2,-1
    80004732:	b765                	j	800046da <fileread+0x60>
      return -1;
    80004734:	597d                	li	s2,-1
    80004736:	b755                	j	800046da <fileread+0x60>
    80004738:	597d                	li	s2,-1
    8000473a:	b745                	j	800046da <fileread+0x60>

000000008000473c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000473c:	00954783          	lbu	a5,9(a0)
    80004740:	14078563          	beqz	a5,8000488a <filewrite+0x14e>
{
    80004744:	715d                	addi	sp,sp,-80
    80004746:	e486                	sd	ra,72(sp)
    80004748:	e0a2                	sd	s0,64(sp)
    8000474a:	fc26                	sd	s1,56(sp)
    8000474c:	f84a                	sd	s2,48(sp)
    8000474e:	f44e                	sd	s3,40(sp)
    80004750:	f052                	sd	s4,32(sp)
    80004752:	ec56                	sd	s5,24(sp)
    80004754:	e85a                	sd	s6,16(sp)
    80004756:	e45e                	sd	s7,8(sp)
    80004758:	e062                	sd	s8,0(sp)
    8000475a:	0880                	addi	s0,sp,80
    8000475c:	892a                	mv	s2,a0
    8000475e:	8b2e                	mv	s6,a1
    80004760:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004762:	411c                	lw	a5,0(a0)
    80004764:	4705                	li	a4,1
    80004766:	02e78263          	beq	a5,a4,8000478a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000476a:	470d                	li	a4,3
    8000476c:	02e78563          	beq	a5,a4,80004796 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004770:	4709                	li	a4,2
    80004772:	10e79463          	bne	a5,a4,8000487a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004776:	0ec05e63          	blez	a2,80004872 <filewrite+0x136>
    int i = 0;
    8000477a:	4981                	li	s3,0
    8000477c:	6b85                	lui	s7,0x1
    8000477e:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004782:	6c05                	lui	s8,0x1
    80004784:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004788:	a851                	j	8000481c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000478a:	6908                	ld	a0,16(a0)
    8000478c:	00000097          	auipc	ra,0x0
    80004790:	254080e7          	jalr	596(ra) # 800049e0 <pipewrite>
    80004794:	a85d                	j	8000484a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004796:	02451783          	lh	a5,36(a0)
    8000479a:	03079693          	slli	a3,a5,0x30
    8000479e:	92c1                	srli	a3,a3,0x30
    800047a0:	4725                	li	a4,9
    800047a2:	0ed76663          	bltu	a4,a3,8000488e <filewrite+0x152>
    800047a6:	0792                	slli	a5,a5,0x4
    800047a8:	0001d717          	auipc	a4,0x1d
    800047ac:	40870713          	addi	a4,a4,1032 # 80021bb0 <devsw>
    800047b0:	97ba                	add	a5,a5,a4
    800047b2:	679c                	ld	a5,8(a5)
    800047b4:	cff9                	beqz	a5,80004892 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047b6:	4505                	li	a0,1
    800047b8:	9782                	jalr	a5
    800047ba:	a841                	j	8000484a <filewrite+0x10e>
    800047bc:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	8b2080e7          	jalr	-1870(ra) # 80004072 <begin_op>
      ilock(f->ip);
    800047c8:	01893503          	ld	a0,24(s2)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	ee0080e7          	jalr	-288(ra) # 800036ac <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047d4:	8756                	mv	a4,s5
    800047d6:	02092683          	lw	a3,32(s2)
    800047da:	01698633          	add	a2,s3,s6
    800047de:	4585                	li	a1,1
    800047e0:	01893503          	ld	a0,24(s2)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	272080e7          	jalr	626(ra) # 80003a56 <writei>
    800047ec:	84aa                	mv	s1,a0
    800047ee:	02a05f63          	blez	a0,8000482c <filewrite+0xf0>
        f->off += r;
    800047f2:	02092783          	lw	a5,32(s2)
    800047f6:	9fa9                	addw	a5,a5,a0
    800047f8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800047fc:	01893503          	ld	a0,24(s2)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	f6e080e7          	jalr	-146(ra) # 8000376e <iunlock>
      end_op();
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	8e8080e7          	jalr	-1816(ra) # 800040f0 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004810:	049a9963          	bne	s5,s1,80004862 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004814:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004818:	0349d663          	bge	s3,s4,80004844 <filewrite+0x108>
      int n1 = n - i;
    8000481c:	413a04bb          	subw	s1,s4,s3
    80004820:	0004879b          	sext.w	a5,s1
    80004824:	f8fbdce3          	bge	s7,a5,800047bc <filewrite+0x80>
    80004828:	84e2                	mv	s1,s8
    8000482a:	bf49                	j	800047bc <filewrite+0x80>
      iunlock(f->ip);
    8000482c:	01893503          	ld	a0,24(s2)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	f3e080e7          	jalr	-194(ra) # 8000376e <iunlock>
      end_op();
    80004838:	00000097          	auipc	ra,0x0
    8000483c:	8b8080e7          	jalr	-1864(ra) # 800040f0 <end_op>
      if(r < 0)
    80004840:	fc04d8e3          	bgez	s1,80004810 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004844:	8552                	mv	a0,s4
    80004846:	033a1863          	bne	s4,s3,80004876 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000484a:	60a6                	ld	ra,72(sp)
    8000484c:	6406                	ld	s0,64(sp)
    8000484e:	74e2                	ld	s1,56(sp)
    80004850:	7942                	ld	s2,48(sp)
    80004852:	79a2                	ld	s3,40(sp)
    80004854:	7a02                	ld	s4,32(sp)
    80004856:	6ae2                	ld	s5,24(sp)
    80004858:	6b42                	ld	s6,16(sp)
    8000485a:	6ba2                	ld	s7,8(sp)
    8000485c:	6c02                	ld	s8,0(sp)
    8000485e:	6161                	addi	sp,sp,80
    80004860:	8082                	ret
        panic("short filewrite");
    80004862:	00004517          	auipc	a0,0x4
    80004866:	ef650513          	addi	a0,a0,-266 # 80008758 <syscalls+0x270>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	cdc080e7          	jalr	-804(ra) # 80000546 <panic>
    int i = 0;
    80004872:	4981                	li	s3,0
    80004874:	bfc1                	j	80004844 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004876:	557d                	li	a0,-1
    80004878:	bfc9                	j	8000484a <filewrite+0x10e>
    panic("filewrite");
    8000487a:	00004517          	auipc	a0,0x4
    8000487e:	eee50513          	addi	a0,a0,-274 # 80008768 <syscalls+0x280>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	cc4080e7          	jalr	-828(ra) # 80000546 <panic>
    return -1;
    8000488a:	557d                	li	a0,-1
}
    8000488c:	8082                	ret
      return -1;
    8000488e:	557d                	li	a0,-1
    80004890:	bf6d                	j	8000484a <filewrite+0x10e>
    80004892:	557d                	li	a0,-1
    80004894:	bf5d                	j	8000484a <filewrite+0x10e>

0000000080004896 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004896:	7179                	addi	sp,sp,-48
    80004898:	f406                	sd	ra,40(sp)
    8000489a:	f022                	sd	s0,32(sp)
    8000489c:	ec26                	sd	s1,24(sp)
    8000489e:	e84a                	sd	s2,16(sp)
    800048a0:	e44e                	sd	s3,8(sp)
    800048a2:	e052                	sd	s4,0(sp)
    800048a4:	1800                	addi	s0,sp,48
    800048a6:	84aa                	mv	s1,a0
    800048a8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048aa:	0005b023          	sd	zero,0(a1)
    800048ae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	bd2080e7          	jalr	-1070(ra) # 80004484 <filealloc>
    800048ba:	e088                	sd	a0,0(s1)
    800048bc:	c551                	beqz	a0,80004948 <pipealloc+0xb2>
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	bc6080e7          	jalr	-1082(ra) # 80004484 <filealloc>
    800048c6:	00aa3023          	sd	a0,0(s4)
    800048ca:	c92d                	beqz	a0,8000493c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	244080e7          	jalr	580(ra) # 80000b10 <kalloc>
    800048d4:	892a                	mv	s2,a0
    800048d6:	c125                	beqz	a0,80004936 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048d8:	4985                	li	s3,1
    800048da:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048de:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048e2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048e6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048ea:	00004597          	auipc	a1,0x4
    800048ee:	b5658593          	addi	a1,a1,-1194 # 80008440 <states.0+0x198>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	27e080e7          	jalr	638(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    800048fa:	609c                	ld	a5,0(s1)
    800048fc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004900:	609c                	ld	a5,0(s1)
    80004902:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004906:	609c                	ld	a5,0(s1)
    80004908:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000490c:	609c                	ld	a5,0(s1)
    8000490e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004912:	000a3783          	ld	a5,0(s4)
    80004916:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000491a:	000a3783          	ld	a5,0(s4)
    8000491e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004922:	000a3783          	ld	a5,0(s4)
    80004926:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000492a:	000a3783          	ld	a5,0(s4)
    8000492e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004932:	4501                	li	a0,0
    80004934:	a025                	j	8000495c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004936:	6088                	ld	a0,0(s1)
    80004938:	e501                	bnez	a0,80004940 <pipealloc+0xaa>
    8000493a:	a039                	j	80004948 <pipealloc+0xb2>
    8000493c:	6088                	ld	a0,0(s1)
    8000493e:	c51d                	beqz	a0,8000496c <pipealloc+0xd6>
    fileclose(*f0);
    80004940:	00000097          	auipc	ra,0x0
    80004944:	c00080e7          	jalr	-1024(ra) # 80004540 <fileclose>
  if(*f1)
    80004948:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000494c:	557d                	li	a0,-1
  if(*f1)
    8000494e:	c799                	beqz	a5,8000495c <pipealloc+0xc6>
    fileclose(*f1);
    80004950:	853e                	mv	a0,a5
    80004952:	00000097          	auipc	ra,0x0
    80004956:	bee080e7          	jalr	-1042(ra) # 80004540 <fileclose>
  return -1;
    8000495a:	557d                	li	a0,-1
}
    8000495c:	70a2                	ld	ra,40(sp)
    8000495e:	7402                	ld	s0,32(sp)
    80004960:	64e2                	ld	s1,24(sp)
    80004962:	6942                	ld	s2,16(sp)
    80004964:	69a2                	ld	s3,8(sp)
    80004966:	6a02                	ld	s4,0(sp)
    80004968:	6145                	addi	sp,sp,48
    8000496a:	8082                	ret
  return -1;
    8000496c:	557d                	li	a0,-1
    8000496e:	b7fd                	j	8000495c <pipealloc+0xc6>

0000000080004970 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004970:	1101                	addi	sp,sp,-32
    80004972:	ec06                	sd	ra,24(sp)
    80004974:	e822                	sd	s0,16(sp)
    80004976:	e426                	sd	s1,8(sp)
    80004978:	e04a                	sd	s2,0(sp)
    8000497a:	1000                	addi	s0,sp,32
    8000497c:	84aa                	mv	s1,a0
    8000497e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	280080e7          	jalr	640(ra) # 80000c00 <acquire>
  if(writable){
    80004988:	02090d63          	beqz	s2,800049c2 <pipeclose+0x52>
    pi->writeopen = 0;
    8000498c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004990:	21848513          	addi	a0,s1,536
    80004994:	ffffe097          	auipc	ra,0xffffe
    80004998:	9d4080e7          	jalr	-1580(ra) # 80002368 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000499c:	2204b783          	ld	a5,544(s1)
    800049a0:	eb95                	bnez	a5,800049d4 <pipeclose+0x64>
    release(&pi->lock);
    800049a2:	8526                	mv	a0,s1
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	310080e7          	jalr	784(ra) # 80000cb4 <release>
    kfree((char*)pi);
    800049ac:	8526                	mv	a0,s1
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	064080e7          	jalr	100(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800049b6:	60e2                	ld	ra,24(sp)
    800049b8:	6442                	ld	s0,16(sp)
    800049ba:	64a2                	ld	s1,8(sp)
    800049bc:	6902                	ld	s2,0(sp)
    800049be:	6105                	addi	sp,sp,32
    800049c0:	8082                	ret
    pi->readopen = 0;
    800049c2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049c6:	21c48513          	addi	a0,s1,540
    800049ca:	ffffe097          	auipc	ra,0xffffe
    800049ce:	99e080e7          	jalr	-1634(ra) # 80002368 <wakeup>
    800049d2:	b7e9                	j	8000499c <pipeclose+0x2c>
    release(&pi->lock);
    800049d4:	8526                	mv	a0,s1
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	2de080e7          	jalr	734(ra) # 80000cb4 <release>
}
    800049de:	bfe1                	j	800049b6 <pipeclose+0x46>

00000000800049e0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049e0:	711d                	addi	sp,sp,-96
    800049e2:	ec86                	sd	ra,88(sp)
    800049e4:	e8a2                	sd	s0,80(sp)
    800049e6:	e4a6                	sd	s1,72(sp)
    800049e8:	e0ca                	sd	s2,64(sp)
    800049ea:	fc4e                	sd	s3,56(sp)
    800049ec:	f852                	sd	s4,48(sp)
    800049ee:	f456                	sd	s5,40(sp)
    800049f0:	f05a                	sd	s6,32(sp)
    800049f2:	ec5e                	sd	s7,24(sp)
    800049f4:	e862                	sd	s8,16(sp)
    800049f6:	1080                	addi	s0,sp,96
    800049f8:	84aa                	mv	s1,a0
    800049fa:	8b2e                	mv	s6,a1
    800049fc:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    800049fe:	ffffd097          	auipc	ra,0xffffd
    80004a02:	fce080e7          	jalr	-50(ra) # 800019cc <myproc>
    80004a06:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a08:	8526                	mv	a0,s1
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	1f6080e7          	jalr	502(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80004a12:	09505863          	blez	s5,80004aa2 <pipewrite+0xc2>
    80004a16:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a18:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a1c:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a20:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a22:	2184a783          	lw	a5,536(s1)
    80004a26:	21c4a703          	lw	a4,540(s1)
    80004a2a:	2007879b          	addiw	a5,a5,512
    80004a2e:	02f71b63          	bne	a4,a5,80004a64 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004a32:	2204a783          	lw	a5,544(s1)
    80004a36:	c3d9                	beqz	a5,80004abc <pipewrite+0xdc>
    80004a38:	03092783          	lw	a5,48(s2)
    80004a3c:	e3c1                	bnez	a5,80004abc <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004a3e:	8552                	mv	a0,s4
    80004a40:	ffffe097          	auipc	ra,0xffffe
    80004a44:	928080e7          	jalr	-1752(ra) # 80002368 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a48:	85a6                	mv	a1,s1
    80004a4a:	854e                	mv	a0,s3
    80004a4c:	ffffd097          	auipc	ra,0xffffd
    80004a50:	79c080e7          	jalr	1948(ra) # 800021e8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a54:	2184a783          	lw	a5,536(s1)
    80004a58:	21c4a703          	lw	a4,540(s1)
    80004a5c:	2007879b          	addiw	a5,a5,512
    80004a60:	fcf709e3          	beq	a4,a5,80004a32 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a64:	4685                	li	a3,1
    80004a66:	865a                	mv	a2,s6
    80004a68:	faf40593          	addi	a1,s0,-81
    80004a6c:	05093503          	ld	a0,80(s2)
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	cde080e7          	jalr	-802(ra) # 8000174e <copyin>
    80004a78:	03850663          	beq	a0,s8,80004aa4 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a7c:	21c4a783          	lw	a5,540(s1)
    80004a80:	0017871b          	addiw	a4,a5,1
    80004a84:	20e4ae23          	sw	a4,540(s1)
    80004a88:	1ff7f793          	andi	a5,a5,511
    80004a8c:	97a6                	add	a5,a5,s1
    80004a8e:	faf44703          	lbu	a4,-81(s0)
    80004a92:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004a96:	2b85                	addiw	s7,s7,1
    80004a98:	0b05                	addi	s6,s6,1
    80004a9a:	f97a94e3          	bne	s5,s7,80004a22 <pipewrite+0x42>
    80004a9e:	8bd6                	mv	s7,s5
    80004aa0:	a011                	j	80004aa4 <pipewrite+0xc4>
    80004aa2:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004aa4:	21848513          	addi	a0,s1,536
    80004aa8:	ffffe097          	auipc	ra,0xffffe
    80004aac:	8c0080e7          	jalr	-1856(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	202080e7          	jalr	514(ra) # 80000cb4 <release>
  return i;
    80004aba:	a039                	j	80004ac8 <pipewrite+0xe8>
        release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	1f6080e7          	jalr	502(ra) # 80000cb4 <release>
        return -1;
    80004ac6:	5bfd                	li	s7,-1
}
    80004ac8:	855e                	mv	a0,s7
    80004aca:	60e6                	ld	ra,88(sp)
    80004acc:	6446                	ld	s0,80(sp)
    80004ace:	64a6                	ld	s1,72(sp)
    80004ad0:	6906                	ld	s2,64(sp)
    80004ad2:	79e2                	ld	s3,56(sp)
    80004ad4:	7a42                	ld	s4,48(sp)
    80004ad6:	7aa2                	ld	s5,40(sp)
    80004ad8:	7b02                	ld	s6,32(sp)
    80004ada:	6be2                	ld	s7,24(sp)
    80004adc:	6c42                	ld	s8,16(sp)
    80004ade:	6125                	addi	sp,sp,96
    80004ae0:	8082                	ret

0000000080004ae2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ae2:	715d                	addi	sp,sp,-80
    80004ae4:	e486                	sd	ra,72(sp)
    80004ae6:	e0a2                	sd	s0,64(sp)
    80004ae8:	fc26                	sd	s1,56(sp)
    80004aea:	f84a                	sd	s2,48(sp)
    80004aec:	f44e                	sd	s3,40(sp)
    80004aee:	f052                	sd	s4,32(sp)
    80004af0:	ec56                	sd	s5,24(sp)
    80004af2:	e85a                	sd	s6,16(sp)
    80004af4:	0880                	addi	s0,sp,80
    80004af6:	84aa                	mv	s1,a0
    80004af8:	892e                	mv	s2,a1
    80004afa:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	ed0080e7          	jalr	-304(ra) # 800019cc <myproc>
    80004b04:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	0f8080e7          	jalr	248(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b10:	2184a703          	lw	a4,536(s1)
    80004b14:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b18:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b1c:	02f71463          	bne	a4,a5,80004b44 <piperead+0x62>
    80004b20:	2244a783          	lw	a5,548(s1)
    80004b24:	c385                	beqz	a5,80004b44 <piperead+0x62>
    if(pr->killed){
    80004b26:	030a2783          	lw	a5,48(s4)
    80004b2a:	ebc9                	bnez	a5,80004bbc <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b2c:	85a6                	mv	a1,s1
    80004b2e:	854e                	mv	a0,s3
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	6b8080e7          	jalr	1720(ra) # 800021e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b38:	2184a703          	lw	a4,536(s1)
    80004b3c:	21c4a783          	lw	a5,540(s1)
    80004b40:	fef700e3          	beq	a4,a5,80004b20 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b46:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b48:	05505463          	blez	s5,80004b90 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b4c:	2184a783          	lw	a5,536(s1)
    80004b50:	21c4a703          	lw	a4,540(s1)
    80004b54:	02f70e63          	beq	a4,a5,80004b90 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b58:	0017871b          	addiw	a4,a5,1
    80004b5c:	20e4ac23          	sw	a4,536(s1)
    80004b60:	1ff7f793          	andi	a5,a5,511
    80004b64:	97a6                	add	a5,a5,s1
    80004b66:	0187c783          	lbu	a5,24(a5)
    80004b6a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b6e:	4685                	li	a3,1
    80004b70:	fbf40613          	addi	a2,s0,-65
    80004b74:	85ca                	mv	a1,s2
    80004b76:	050a3503          	ld	a0,80(s4)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	b48080e7          	jalr	-1208(ra) # 800016c2 <copyout>
    80004b82:	01650763          	beq	a0,s6,80004b90 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b86:	2985                	addiw	s3,s3,1
    80004b88:	0905                	addi	s2,s2,1
    80004b8a:	fd3a91e3          	bne	s5,s3,80004b4c <piperead+0x6a>
    80004b8e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b90:	21c48513          	addi	a0,s1,540
    80004b94:	ffffd097          	auipc	ra,0xffffd
    80004b98:	7d4080e7          	jalr	2004(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004b9c:	8526                	mv	a0,s1
    80004b9e:	ffffc097          	auipc	ra,0xffffc
    80004ba2:	116080e7          	jalr	278(ra) # 80000cb4 <release>
  return i;
}
    80004ba6:	854e                	mv	a0,s3
    80004ba8:	60a6                	ld	ra,72(sp)
    80004baa:	6406                	ld	s0,64(sp)
    80004bac:	74e2                	ld	s1,56(sp)
    80004bae:	7942                	ld	s2,48(sp)
    80004bb0:	79a2                	ld	s3,40(sp)
    80004bb2:	7a02                	ld	s4,32(sp)
    80004bb4:	6ae2                	ld	s5,24(sp)
    80004bb6:	6b42                	ld	s6,16(sp)
    80004bb8:	6161                	addi	sp,sp,80
    80004bba:	8082                	ret
      release(&pi->lock);
    80004bbc:	8526                	mv	a0,s1
    80004bbe:	ffffc097          	auipc	ra,0xffffc
    80004bc2:	0f6080e7          	jalr	246(ra) # 80000cb4 <release>
      return -1;
    80004bc6:	59fd                	li	s3,-1
    80004bc8:	bff9                	j	80004ba6 <piperead+0xc4>

0000000080004bca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bca:	de010113          	addi	sp,sp,-544
    80004bce:	20113c23          	sd	ra,536(sp)
    80004bd2:	20813823          	sd	s0,528(sp)
    80004bd6:	20913423          	sd	s1,520(sp)
    80004bda:	21213023          	sd	s2,512(sp)
    80004bde:	ffce                	sd	s3,504(sp)
    80004be0:	fbd2                	sd	s4,496(sp)
    80004be2:	f7d6                	sd	s5,488(sp)
    80004be4:	f3da                	sd	s6,480(sp)
    80004be6:	efde                	sd	s7,472(sp)
    80004be8:	ebe2                	sd	s8,464(sp)
    80004bea:	e7e6                	sd	s9,456(sp)
    80004bec:	e3ea                	sd	s10,448(sp)
    80004bee:	ff6e                	sd	s11,440(sp)
    80004bf0:	1400                	addi	s0,sp,544
    80004bf2:	892a                	mv	s2,a0
    80004bf4:	dea43423          	sd	a0,-536(s0)
    80004bf8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	dd0080e7          	jalr	-560(ra) # 800019cc <myproc>
    80004c04:	84aa                	mv	s1,a0

  begin_op();
    80004c06:	fffff097          	auipc	ra,0xfffff
    80004c0a:	46c080e7          	jalr	1132(ra) # 80004072 <begin_op>

  if((ip = namei(path)) == 0){
    80004c0e:	854a                	mv	a0,s2
    80004c10:	fffff097          	auipc	ra,0xfffff
    80004c14:	252080e7          	jalr	594(ra) # 80003e62 <namei>
    80004c18:	c93d                	beqz	a0,80004c8e <exec+0xc4>
    80004c1a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	a90080e7          	jalr	-1392(ra) # 800036ac <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c24:	04000713          	li	a4,64
    80004c28:	4681                	li	a3,0
    80004c2a:	e4840613          	addi	a2,s0,-440
    80004c2e:	4581                	li	a1,0
    80004c30:	8556                	mv	a0,s5
    80004c32:	fffff097          	auipc	ra,0xfffff
    80004c36:	d2e080e7          	jalr	-722(ra) # 80003960 <readi>
    80004c3a:	04000793          	li	a5,64
    80004c3e:	00f51a63          	bne	a0,a5,80004c52 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c42:	e4842703          	lw	a4,-440(s0)
    80004c46:	464c47b7          	lui	a5,0x464c4
    80004c4a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c4e:	04f70663          	beq	a4,a5,80004c9a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c52:	8556                	mv	a0,s5
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	cba080e7          	jalr	-838(ra) # 8000390e <iunlockput>
    end_op();
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	494080e7          	jalr	1172(ra) # 800040f0 <end_op>
  }
  return -1;
    80004c64:	557d                	li	a0,-1
}
    80004c66:	21813083          	ld	ra,536(sp)
    80004c6a:	21013403          	ld	s0,528(sp)
    80004c6e:	20813483          	ld	s1,520(sp)
    80004c72:	20013903          	ld	s2,512(sp)
    80004c76:	79fe                	ld	s3,504(sp)
    80004c78:	7a5e                	ld	s4,496(sp)
    80004c7a:	7abe                	ld	s5,488(sp)
    80004c7c:	7b1e                	ld	s6,480(sp)
    80004c7e:	6bfe                	ld	s7,472(sp)
    80004c80:	6c5e                	ld	s8,464(sp)
    80004c82:	6cbe                	ld	s9,456(sp)
    80004c84:	6d1e                	ld	s10,448(sp)
    80004c86:	7dfa                	ld	s11,440(sp)
    80004c88:	22010113          	addi	sp,sp,544
    80004c8c:	8082                	ret
    end_op();
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	462080e7          	jalr	1122(ra) # 800040f0 <end_op>
    return -1;
    80004c96:	557d                	li	a0,-1
    80004c98:	b7f9                	j	80004c66 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffd097          	auipc	ra,0xffffd
    80004ca0:	df4080e7          	jalr	-524(ra) # 80001a90 <proc_pagetable>
    80004ca4:	8b2a                	mv	s6,a0
    80004ca6:	d555                	beqz	a0,80004c52 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca8:	e6842783          	lw	a5,-408(s0)
    80004cac:	e8045703          	lhu	a4,-384(s0)
    80004cb0:	c735                	beqz	a4,80004d1c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cb2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cb4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cb8:	6a05                	lui	s4,0x1
    80004cba:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cbe:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cc2:	6d85                	lui	s11,0x1
    80004cc4:	7d7d                	lui	s10,0xfffff
    80004cc6:	ac1d                	j	80004efc <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cc8:	00004517          	auipc	a0,0x4
    80004ccc:	ab050513          	addi	a0,a0,-1360 # 80008778 <syscalls+0x290>
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	876080e7          	jalr	-1930(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cd8:	874a                	mv	a4,s2
    80004cda:	009c86bb          	addw	a3,s9,s1
    80004cde:	4581                	li	a1,0
    80004ce0:	8556                	mv	a0,s5
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	c7e080e7          	jalr	-898(ra) # 80003960 <readi>
    80004cea:	2501                	sext.w	a0,a0
    80004cec:	1aa91863          	bne	s2,a0,80004e9c <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004cf0:	009d84bb          	addw	s1,s11,s1
    80004cf4:	013d09bb          	addw	s3,s10,s3
    80004cf8:	1f74f263          	bgeu	s1,s7,80004edc <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004cfc:	02049593          	slli	a1,s1,0x20
    80004d00:	9181                	srli	a1,a1,0x20
    80004d02:	95e2                	add	a1,a1,s8
    80004d04:	855a                	mv	a0,s6
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	384080e7          	jalr	900(ra) # 8000108a <walkaddr>
    80004d0e:	862a                	mv	a2,a0
    if(pa == 0)
    80004d10:	dd45                	beqz	a0,80004cc8 <exec+0xfe>
      n = PGSIZE;
    80004d12:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d14:	fd49f2e3          	bgeu	s3,s4,80004cd8 <exec+0x10e>
      n = sz - i;
    80004d18:	894e                	mv	s2,s3
    80004d1a:	bf7d                	j	80004cd8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d1c:	4481                	li	s1,0
  iunlockput(ip);
    80004d1e:	8556                	mv	a0,s5
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	bee080e7          	jalr	-1042(ra) # 8000390e <iunlockput>
  end_op();
    80004d28:	fffff097          	auipc	ra,0xfffff
    80004d2c:	3c8080e7          	jalr	968(ra) # 800040f0 <end_op>
  p = myproc();
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	c9c080e7          	jalr	-868(ra) # 800019cc <myproc>
    80004d38:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d3a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d3e:	6785                	lui	a5,0x1
    80004d40:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d42:	97a6                	add	a5,a5,s1
    80004d44:	777d                	lui	a4,0xfffff
    80004d46:	8ff9                	and	a5,a5,a4
    80004d48:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d4c:	6609                	lui	a2,0x2
    80004d4e:	963e                	add	a2,a2,a5
    80004d50:	85be                	mv	a1,a5
    80004d52:	855a                	mv	a0,s6
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	71a080e7          	jalr	1818(ra) # 8000146e <uvmalloc>
    80004d5c:	8c2a                	mv	s8,a0
  ip = 0;
    80004d5e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d60:	12050e63          	beqz	a0,80004e9c <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d64:	75f9                	lui	a1,0xffffe
    80004d66:	95aa                	add	a1,a1,a0
    80004d68:	855a                	mv	a0,s6
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	926080e7          	jalr	-1754(ra) # 80001690 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d72:	7afd                	lui	s5,0xfffff
    80004d74:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d76:	df043783          	ld	a5,-528(s0)
    80004d7a:	6388                	ld	a0,0(a5)
    80004d7c:	c925                	beqz	a0,80004dec <exec+0x222>
    80004d7e:	e8840993          	addi	s3,s0,-376
    80004d82:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d86:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d88:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d8a:	ffffc097          	auipc	ra,0xffffc
    80004d8e:	0f6080e7          	jalr	246(ra) # 80000e80 <strlen>
    80004d92:	0015079b          	addiw	a5,a0,1
    80004d96:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d9a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d9e:	13596363          	bltu	s2,s5,80004ec4 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004da2:	df043d83          	ld	s11,-528(s0)
    80004da6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004daa:	8552                	mv	a0,s4
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	0d4080e7          	jalr	212(ra) # 80000e80 <strlen>
    80004db4:	0015069b          	addiw	a3,a0,1
    80004db8:	8652                	mv	a2,s4
    80004dba:	85ca                	mv	a1,s2
    80004dbc:	855a                	mv	a0,s6
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	904080e7          	jalr	-1788(ra) # 800016c2 <copyout>
    80004dc6:	10054363          	bltz	a0,80004ecc <exec+0x302>
    ustack[argc] = sp;
    80004dca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dce:	0485                	addi	s1,s1,1
    80004dd0:	008d8793          	addi	a5,s11,8
    80004dd4:	def43823          	sd	a5,-528(s0)
    80004dd8:	008db503          	ld	a0,8(s11)
    80004ddc:	c911                	beqz	a0,80004df0 <exec+0x226>
    if(argc >= MAXARG)
    80004dde:	09a1                	addi	s3,s3,8
    80004de0:	fb3c95e3          	bne	s9,s3,80004d8a <exec+0x1c0>
  sz = sz1;
    80004de4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004de8:	4a81                	li	s5,0
    80004dea:	a84d                	j	80004e9c <exec+0x2d2>
  sp = sz;
    80004dec:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004dee:	4481                	li	s1,0
  ustack[argc] = 0;
    80004df0:	00349793          	slli	a5,s1,0x3
    80004df4:	f9078793          	addi	a5,a5,-112
    80004df8:	97a2                	add	a5,a5,s0
    80004dfa:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004dfe:	00148693          	addi	a3,s1,1
    80004e02:	068e                	slli	a3,a3,0x3
    80004e04:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e08:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e0c:	01597663          	bgeu	s2,s5,80004e18 <exec+0x24e>
  sz = sz1;
    80004e10:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e14:	4a81                	li	s5,0
    80004e16:	a059                	j	80004e9c <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e18:	e8840613          	addi	a2,s0,-376
    80004e1c:	85ca                	mv	a1,s2
    80004e1e:	855a                	mv	a0,s6
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	8a2080e7          	jalr	-1886(ra) # 800016c2 <copyout>
    80004e28:	0a054663          	bltz	a0,80004ed4 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e2c:	058bb783          	ld	a5,88(s7)
    80004e30:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e34:	de843783          	ld	a5,-536(s0)
    80004e38:	0007c703          	lbu	a4,0(a5)
    80004e3c:	cf11                	beqz	a4,80004e58 <exec+0x28e>
    80004e3e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e40:	02f00693          	li	a3,47
    80004e44:	a039                	j	80004e52 <exec+0x288>
      last = s+1;
    80004e46:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e4a:	0785                	addi	a5,a5,1
    80004e4c:	fff7c703          	lbu	a4,-1(a5)
    80004e50:	c701                	beqz	a4,80004e58 <exec+0x28e>
    if(*s == '/')
    80004e52:	fed71ce3          	bne	a4,a3,80004e4a <exec+0x280>
    80004e56:	bfc5                	j	80004e46 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e58:	4641                	li	a2,16
    80004e5a:	de843583          	ld	a1,-536(s0)
    80004e5e:	158b8513          	addi	a0,s7,344
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	fec080e7          	jalr	-20(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    80004e6a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e6e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e72:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e76:	058bb783          	ld	a5,88(s7)
    80004e7a:	e6043703          	ld	a4,-416(s0)
    80004e7e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e80:	058bb783          	ld	a5,88(s7)
    80004e84:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e88:	85ea                	mv	a1,s10
    80004e8a:	ffffd097          	auipc	ra,0xffffd
    80004e8e:	ca2080e7          	jalr	-862(ra) # 80001b2c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e92:	0004851b          	sext.w	a0,s1
    80004e96:	bbc1                	j	80004c66 <exec+0x9c>
    80004e98:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e9c:	df843583          	ld	a1,-520(s0)
    80004ea0:	855a                	mv	a0,s6
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	c8a080e7          	jalr	-886(ra) # 80001b2c <proc_freepagetable>
  if(ip){
    80004eaa:	da0a94e3          	bnez	s5,80004c52 <exec+0x88>
  return -1;
    80004eae:	557d                	li	a0,-1
    80004eb0:	bb5d                	j	80004c66 <exec+0x9c>
    80004eb2:	de943c23          	sd	s1,-520(s0)
    80004eb6:	b7dd                	j	80004e9c <exec+0x2d2>
    80004eb8:	de943c23          	sd	s1,-520(s0)
    80004ebc:	b7c5                	j	80004e9c <exec+0x2d2>
    80004ebe:	de943c23          	sd	s1,-520(s0)
    80004ec2:	bfe9                	j	80004e9c <exec+0x2d2>
  sz = sz1;
    80004ec4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec8:	4a81                	li	s5,0
    80004eca:	bfc9                	j	80004e9c <exec+0x2d2>
  sz = sz1;
    80004ecc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed0:	4a81                	li	s5,0
    80004ed2:	b7e9                	j	80004e9c <exec+0x2d2>
  sz = sz1;
    80004ed4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed8:	4a81                	li	s5,0
    80004eda:	b7c9                	j	80004e9c <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004edc:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee0:	e0843783          	ld	a5,-504(s0)
    80004ee4:	0017869b          	addiw	a3,a5,1
    80004ee8:	e0d43423          	sd	a3,-504(s0)
    80004eec:	e0043783          	ld	a5,-512(s0)
    80004ef0:	0387879b          	addiw	a5,a5,56
    80004ef4:	e8045703          	lhu	a4,-384(s0)
    80004ef8:	e2e6d3e3          	bge	a3,a4,80004d1e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004efc:	2781                	sext.w	a5,a5
    80004efe:	e0f43023          	sd	a5,-512(s0)
    80004f02:	03800713          	li	a4,56
    80004f06:	86be                	mv	a3,a5
    80004f08:	e1040613          	addi	a2,s0,-496
    80004f0c:	4581                	li	a1,0
    80004f0e:	8556                	mv	a0,s5
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	a50080e7          	jalr	-1456(ra) # 80003960 <readi>
    80004f18:	03800793          	li	a5,56
    80004f1c:	f6f51ee3          	bne	a0,a5,80004e98 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f20:	e1042783          	lw	a5,-496(s0)
    80004f24:	4705                	li	a4,1
    80004f26:	fae79de3          	bne	a5,a4,80004ee0 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f2a:	e3843603          	ld	a2,-456(s0)
    80004f2e:	e3043783          	ld	a5,-464(s0)
    80004f32:	f8f660e3          	bltu	a2,a5,80004eb2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f36:	e2043783          	ld	a5,-480(s0)
    80004f3a:	963e                	add	a2,a2,a5
    80004f3c:	f6f66ee3          	bltu	a2,a5,80004eb8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f40:	85a6                	mv	a1,s1
    80004f42:	855a                	mv	a0,s6
    80004f44:	ffffc097          	auipc	ra,0xffffc
    80004f48:	52a080e7          	jalr	1322(ra) # 8000146e <uvmalloc>
    80004f4c:	dea43c23          	sd	a0,-520(s0)
    80004f50:	d53d                	beqz	a0,80004ebe <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f52:	e2043c03          	ld	s8,-480(s0)
    80004f56:	de043783          	ld	a5,-544(s0)
    80004f5a:	00fc77b3          	and	a5,s8,a5
    80004f5e:	ff9d                	bnez	a5,80004e9c <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f60:	e1842c83          	lw	s9,-488(s0)
    80004f64:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f68:	f60b8ae3          	beqz	s7,80004edc <exec+0x312>
    80004f6c:	89de                	mv	s3,s7
    80004f6e:	4481                	li	s1,0
    80004f70:	b371                	j	80004cfc <exec+0x132>

0000000080004f72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f72:	7179                	addi	sp,sp,-48
    80004f74:	f406                	sd	ra,40(sp)
    80004f76:	f022                	sd	s0,32(sp)
    80004f78:	ec26                	sd	s1,24(sp)
    80004f7a:	e84a                	sd	s2,16(sp)
    80004f7c:	1800                	addi	s0,sp,48
    80004f7e:	892e                	mv	s2,a1
    80004f80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f82:	fdc40593          	addi	a1,s0,-36
    80004f86:	ffffe097          	auipc	ra,0xffffe
    80004f8a:	b2e080e7          	jalr	-1234(ra) # 80002ab4 <argint>
    80004f8e:	04054063          	bltz	a0,80004fce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f92:	fdc42703          	lw	a4,-36(s0)
    80004f96:	47bd                	li	a5,15
    80004f98:	02e7ed63          	bltu	a5,a4,80004fd2 <argfd+0x60>
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	a30080e7          	jalr	-1488(ra) # 800019cc <myproc>
    80004fa4:	fdc42703          	lw	a4,-36(s0)
    80004fa8:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fac:	078e                	slli	a5,a5,0x3
    80004fae:	953e                	add	a0,a0,a5
    80004fb0:	611c                	ld	a5,0(a0)
    80004fb2:	c395                	beqz	a5,80004fd6 <argfd+0x64>
    return -1;
  if(pfd)
    80004fb4:	00090463          	beqz	s2,80004fbc <argfd+0x4a>
    *pfd = fd;
    80004fb8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fbc:	4501                	li	a0,0
  if(pf)
    80004fbe:	c091                	beqz	s1,80004fc2 <argfd+0x50>
    *pf = f;
    80004fc0:	e09c                	sd	a5,0(s1)
}
    80004fc2:	70a2                	ld	ra,40(sp)
    80004fc4:	7402                	ld	s0,32(sp)
    80004fc6:	64e2                	ld	s1,24(sp)
    80004fc8:	6942                	ld	s2,16(sp)
    80004fca:	6145                	addi	sp,sp,48
    80004fcc:	8082                	ret
    return -1;
    80004fce:	557d                	li	a0,-1
    80004fd0:	bfcd                	j	80004fc2 <argfd+0x50>
    return -1;
    80004fd2:	557d                	li	a0,-1
    80004fd4:	b7fd                	j	80004fc2 <argfd+0x50>
    80004fd6:	557d                	li	a0,-1
    80004fd8:	b7ed                	j	80004fc2 <argfd+0x50>

0000000080004fda <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fda:	1101                	addi	sp,sp,-32
    80004fdc:	ec06                	sd	ra,24(sp)
    80004fde:	e822                	sd	s0,16(sp)
    80004fe0:	e426                	sd	s1,8(sp)
    80004fe2:	1000                	addi	s0,sp,32
    80004fe4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	9e6080e7          	jalr	-1562(ra) # 800019cc <myproc>
    80004fee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ff0:	0d050793          	addi	a5,a0,208
    80004ff4:	4501                	li	a0,0
    80004ff6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ff8:	6398                	ld	a4,0(a5)
    80004ffa:	cb19                	beqz	a4,80005010 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80004ffc:	2505                	addiw	a0,a0,1
    80004ffe:	07a1                	addi	a5,a5,8
    80005000:	fed51ce3          	bne	a0,a3,80004ff8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005004:	557d                	li	a0,-1
}
    80005006:	60e2                	ld	ra,24(sp)
    80005008:	6442                	ld	s0,16(sp)
    8000500a:	64a2                	ld	s1,8(sp)
    8000500c:	6105                	addi	sp,sp,32
    8000500e:	8082                	ret
      p->ofile[fd] = f;
    80005010:	01a50793          	addi	a5,a0,26
    80005014:	078e                	slli	a5,a5,0x3
    80005016:	963e                	add	a2,a2,a5
    80005018:	e204                	sd	s1,0(a2)
      return fd;
    8000501a:	b7f5                	j	80005006 <fdalloc+0x2c>

000000008000501c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000501c:	715d                	addi	sp,sp,-80
    8000501e:	e486                	sd	ra,72(sp)
    80005020:	e0a2                	sd	s0,64(sp)
    80005022:	fc26                	sd	s1,56(sp)
    80005024:	f84a                	sd	s2,48(sp)
    80005026:	f44e                	sd	s3,40(sp)
    80005028:	f052                	sd	s4,32(sp)
    8000502a:	ec56                	sd	s5,24(sp)
    8000502c:	0880                	addi	s0,sp,80
    8000502e:	89ae                	mv	s3,a1
    80005030:	8ab2                	mv	s5,a2
    80005032:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005034:	fb040593          	addi	a1,s0,-80
    80005038:	fffff097          	auipc	ra,0xfffff
    8000503c:	e48080e7          	jalr	-440(ra) # 80003e80 <nameiparent>
    80005040:	892a                	mv	s2,a0
    80005042:	12050e63          	beqz	a0,8000517e <create+0x162>
    return 0;

  ilock(dp);
    80005046:	ffffe097          	auipc	ra,0xffffe
    8000504a:	666080e7          	jalr	1638(ra) # 800036ac <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000504e:	4601                	li	a2,0
    80005050:	fb040593          	addi	a1,s0,-80
    80005054:	854a                	mv	a0,s2
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	b34080e7          	jalr	-1228(ra) # 80003b8a <dirlookup>
    8000505e:	84aa                	mv	s1,a0
    80005060:	c921                	beqz	a0,800050b0 <create+0x94>
    iunlockput(dp);
    80005062:	854a                	mv	a0,s2
    80005064:	fffff097          	auipc	ra,0xfffff
    80005068:	8aa080e7          	jalr	-1878(ra) # 8000390e <iunlockput>
    ilock(ip);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffe097          	auipc	ra,0xffffe
    80005072:	63e080e7          	jalr	1598(ra) # 800036ac <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005076:	2981                	sext.w	s3,s3
    80005078:	4789                	li	a5,2
    8000507a:	02f99463          	bne	s3,a5,800050a2 <create+0x86>
    8000507e:	0444d783          	lhu	a5,68(s1)
    80005082:	37f9                	addiw	a5,a5,-2
    80005084:	17c2                	slli	a5,a5,0x30
    80005086:	93c1                	srli	a5,a5,0x30
    80005088:	4705                	li	a4,1
    8000508a:	00f76c63          	bltu	a4,a5,800050a2 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000508e:	8526                	mv	a0,s1
    80005090:	60a6                	ld	ra,72(sp)
    80005092:	6406                	ld	s0,64(sp)
    80005094:	74e2                	ld	s1,56(sp)
    80005096:	7942                	ld	s2,48(sp)
    80005098:	79a2                	ld	s3,40(sp)
    8000509a:	7a02                	ld	s4,32(sp)
    8000509c:	6ae2                	ld	s5,24(sp)
    8000509e:	6161                	addi	sp,sp,80
    800050a0:	8082                	ret
    iunlockput(ip);
    800050a2:	8526                	mv	a0,s1
    800050a4:	fffff097          	auipc	ra,0xfffff
    800050a8:	86a080e7          	jalr	-1942(ra) # 8000390e <iunlockput>
    return 0;
    800050ac:	4481                	li	s1,0
    800050ae:	b7c5                	j	8000508e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050b0:	85ce                	mv	a1,s3
    800050b2:	00092503          	lw	a0,0(s2)
    800050b6:	ffffe097          	auipc	ra,0xffffe
    800050ba:	45c080e7          	jalr	1116(ra) # 80003512 <ialloc>
    800050be:	84aa                	mv	s1,a0
    800050c0:	c521                	beqz	a0,80005108 <create+0xec>
  ilock(ip);
    800050c2:	ffffe097          	auipc	ra,0xffffe
    800050c6:	5ea080e7          	jalr	1514(ra) # 800036ac <ilock>
  ip->major = major;
    800050ca:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ce:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050d2:	4a05                	li	s4,1
    800050d4:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050d8:	8526                	mv	a0,s1
    800050da:	ffffe097          	auipc	ra,0xffffe
    800050de:	506080e7          	jalr	1286(ra) # 800035e0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050e2:	2981                	sext.w	s3,s3
    800050e4:	03498a63          	beq	s3,s4,80005118 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050e8:	40d0                	lw	a2,4(s1)
    800050ea:	fb040593          	addi	a1,s0,-80
    800050ee:	854a                	mv	a0,s2
    800050f0:	fffff097          	auipc	ra,0xfffff
    800050f4:	cb0080e7          	jalr	-848(ra) # 80003da0 <dirlink>
    800050f8:	06054b63          	bltz	a0,8000516e <create+0x152>
  iunlockput(dp);
    800050fc:	854a                	mv	a0,s2
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	810080e7          	jalr	-2032(ra) # 8000390e <iunlockput>
  return ip;
    80005106:	b761                	j	8000508e <create+0x72>
    panic("create: ialloc");
    80005108:	00003517          	auipc	a0,0x3
    8000510c:	69050513          	addi	a0,a0,1680 # 80008798 <syscalls+0x2b0>
    80005110:	ffffb097          	auipc	ra,0xffffb
    80005114:	436080e7          	jalr	1078(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    80005118:	04a95783          	lhu	a5,74(s2)
    8000511c:	2785                	addiw	a5,a5,1
    8000511e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005122:	854a                	mv	a0,s2
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	4bc080e7          	jalr	1212(ra) # 800035e0 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000512c:	40d0                	lw	a2,4(s1)
    8000512e:	00003597          	auipc	a1,0x3
    80005132:	67a58593          	addi	a1,a1,1658 # 800087a8 <syscalls+0x2c0>
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	c68080e7          	jalr	-920(ra) # 80003da0 <dirlink>
    80005140:	00054f63          	bltz	a0,8000515e <create+0x142>
    80005144:	00492603          	lw	a2,4(s2)
    80005148:	00003597          	auipc	a1,0x3
    8000514c:	66858593          	addi	a1,a1,1640 # 800087b0 <syscalls+0x2c8>
    80005150:	8526                	mv	a0,s1
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	c4e080e7          	jalr	-946(ra) # 80003da0 <dirlink>
    8000515a:	f80557e3          	bgez	a0,800050e8 <create+0xcc>
      panic("create dots");
    8000515e:	00003517          	auipc	a0,0x3
    80005162:	65a50513          	addi	a0,a0,1626 # 800087b8 <syscalls+0x2d0>
    80005166:	ffffb097          	auipc	ra,0xffffb
    8000516a:	3e0080e7          	jalr	992(ra) # 80000546 <panic>
    panic("create: dirlink");
    8000516e:	00003517          	auipc	a0,0x3
    80005172:	65a50513          	addi	a0,a0,1626 # 800087c8 <syscalls+0x2e0>
    80005176:	ffffb097          	auipc	ra,0xffffb
    8000517a:	3d0080e7          	jalr	976(ra) # 80000546 <panic>
    return 0;
    8000517e:	84aa                	mv	s1,a0
    80005180:	b739                	j	8000508e <create+0x72>

0000000080005182 <sys_dup>:
{
    80005182:	7179                	addi	sp,sp,-48
    80005184:	f406                	sd	ra,40(sp)
    80005186:	f022                	sd	s0,32(sp)
    80005188:	ec26                	sd	s1,24(sp)
    8000518a:	e84a                	sd	s2,16(sp)
    8000518c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000518e:	fd840613          	addi	a2,s0,-40
    80005192:	4581                	li	a1,0
    80005194:	4501                	li	a0,0
    80005196:	00000097          	auipc	ra,0x0
    8000519a:	ddc080e7          	jalr	-548(ra) # 80004f72 <argfd>
    return -1;
    8000519e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051a0:	02054363          	bltz	a0,800051c6 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051a4:	fd843903          	ld	s2,-40(s0)
    800051a8:	854a                	mv	a0,s2
    800051aa:	00000097          	auipc	ra,0x0
    800051ae:	e30080e7          	jalr	-464(ra) # 80004fda <fdalloc>
    800051b2:	84aa                	mv	s1,a0
    return -1;
    800051b4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051b6:	00054863          	bltz	a0,800051c6 <sys_dup+0x44>
  filedup(f);
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	332080e7          	jalr	818(ra) # 800044ee <filedup>
  return fd;
    800051c4:	87a6                	mv	a5,s1
}
    800051c6:	853e                	mv	a0,a5
    800051c8:	70a2                	ld	ra,40(sp)
    800051ca:	7402                	ld	s0,32(sp)
    800051cc:	64e2                	ld	s1,24(sp)
    800051ce:	6942                	ld	s2,16(sp)
    800051d0:	6145                	addi	sp,sp,48
    800051d2:	8082                	ret

00000000800051d4 <sys_read>:
{
    800051d4:	7179                	addi	sp,sp,-48
    800051d6:	f406                	sd	ra,40(sp)
    800051d8:	f022                	sd	s0,32(sp)
    800051da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051dc:	fe840613          	addi	a2,s0,-24
    800051e0:	4581                	li	a1,0
    800051e2:	4501                	li	a0,0
    800051e4:	00000097          	auipc	ra,0x0
    800051e8:	d8e080e7          	jalr	-626(ra) # 80004f72 <argfd>
    return -1;
    800051ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ee:	04054163          	bltz	a0,80005230 <sys_read+0x5c>
    800051f2:	fe440593          	addi	a1,s0,-28
    800051f6:	4509                	li	a0,2
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	8bc080e7          	jalr	-1860(ra) # 80002ab4 <argint>
    return -1;
    80005200:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005202:	02054763          	bltz	a0,80005230 <sys_read+0x5c>
    80005206:	fd840593          	addi	a1,s0,-40
    8000520a:	4505                	li	a0,1
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	8ca080e7          	jalr	-1846(ra) # 80002ad6 <argaddr>
    return -1;
    80005214:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005216:	00054d63          	bltz	a0,80005230 <sys_read+0x5c>
  return fileread(f, p, n);
    8000521a:	fe442603          	lw	a2,-28(s0)
    8000521e:	fd843583          	ld	a1,-40(s0)
    80005222:	fe843503          	ld	a0,-24(s0)
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	454080e7          	jalr	1108(ra) # 8000467a <fileread>
    8000522e:	87aa                	mv	a5,a0
}
    80005230:	853e                	mv	a0,a5
    80005232:	70a2                	ld	ra,40(sp)
    80005234:	7402                	ld	s0,32(sp)
    80005236:	6145                	addi	sp,sp,48
    80005238:	8082                	ret

000000008000523a <sys_write>:
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005242:	fe840613          	addi	a2,s0,-24
    80005246:	4581                	li	a1,0
    80005248:	4501                	li	a0,0
    8000524a:	00000097          	auipc	ra,0x0
    8000524e:	d28080e7          	jalr	-728(ra) # 80004f72 <argfd>
    return -1;
    80005252:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005254:	04054163          	bltz	a0,80005296 <sys_write+0x5c>
    80005258:	fe440593          	addi	a1,s0,-28
    8000525c:	4509                	li	a0,2
    8000525e:	ffffe097          	auipc	ra,0xffffe
    80005262:	856080e7          	jalr	-1962(ra) # 80002ab4 <argint>
    return -1;
    80005266:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005268:	02054763          	bltz	a0,80005296 <sys_write+0x5c>
    8000526c:	fd840593          	addi	a1,s0,-40
    80005270:	4505                	li	a0,1
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	864080e7          	jalr	-1948(ra) # 80002ad6 <argaddr>
    return -1;
    8000527a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527c:	00054d63          	bltz	a0,80005296 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005280:	fe442603          	lw	a2,-28(s0)
    80005284:	fd843583          	ld	a1,-40(s0)
    80005288:	fe843503          	ld	a0,-24(s0)
    8000528c:	fffff097          	auipc	ra,0xfffff
    80005290:	4b0080e7          	jalr	1200(ra) # 8000473c <filewrite>
    80005294:	87aa                	mv	a5,a0
}
    80005296:	853e                	mv	a0,a5
    80005298:	70a2                	ld	ra,40(sp)
    8000529a:	7402                	ld	s0,32(sp)
    8000529c:	6145                	addi	sp,sp,48
    8000529e:	8082                	ret

00000000800052a0 <sys_close>:
{
    800052a0:	1101                	addi	sp,sp,-32
    800052a2:	ec06                	sd	ra,24(sp)
    800052a4:	e822                	sd	s0,16(sp)
    800052a6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052a8:	fe040613          	addi	a2,s0,-32
    800052ac:	fec40593          	addi	a1,s0,-20
    800052b0:	4501                	li	a0,0
    800052b2:	00000097          	auipc	ra,0x0
    800052b6:	cc0080e7          	jalr	-832(ra) # 80004f72 <argfd>
    return -1;
    800052ba:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052bc:	02054463          	bltz	a0,800052e4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052c0:	ffffc097          	auipc	ra,0xffffc
    800052c4:	70c080e7          	jalr	1804(ra) # 800019cc <myproc>
    800052c8:	fec42783          	lw	a5,-20(s0)
    800052cc:	07e9                	addi	a5,a5,26
    800052ce:	078e                	slli	a5,a5,0x3
    800052d0:	953e                	add	a0,a0,a5
    800052d2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052d6:	fe043503          	ld	a0,-32(s0)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	266080e7          	jalr	614(ra) # 80004540 <fileclose>
  return 0;
    800052e2:	4781                	li	a5,0
}
    800052e4:	853e                	mv	a0,a5
    800052e6:	60e2                	ld	ra,24(sp)
    800052e8:	6442                	ld	s0,16(sp)
    800052ea:	6105                	addi	sp,sp,32
    800052ec:	8082                	ret

00000000800052ee <sys_fstat>:
{
    800052ee:	1101                	addi	sp,sp,-32
    800052f0:	ec06                	sd	ra,24(sp)
    800052f2:	e822                	sd	s0,16(sp)
    800052f4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800052f6:	fe840613          	addi	a2,s0,-24
    800052fa:	4581                	li	a1,0
    800052fc:	4501                	li	a0,0
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	c74080e7          	jalr	-908(ra) # 80004f72 <argfd>
    return -1;
    80005306:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005308:	02054563          	bltz	a0,80005332 <sys_fstat+0x44>
    8000530c:	fe040593          	addi	a1,s0,-32
    80005310:	4505                	li	a0,1
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	7c4080e7          	jalr	1988(ra) # 80002ad6 <argaddr>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000531c:	00054b63          	bltz	a0,80005332 <sys_fstat+0x44>
  return filestat(f, st);
    80005320:	fe043583          	ld	a1,-32(s0)
    80005324:	fe843503          	ld	a0,-24(s0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	2e0080e7          	jalr	736(ra) # 80004608 <filestat>
    80005330:	87aa                	mv	a5,a0
}
    80005332:	853e                	mv	a0,a5
    80005334:	60e2                	ld	ra,24(sp)
    80005336:	6442                	ld	s0,16(sp)
    80005338:	6105                	addi	sp,sp,32
    8000533a:	8082                	ret

000000008000533c <sys_link>:
{
    8000533c:	7169                	addi	sp,sp,-304
    8000533e:	f606                	sd	ra,296(sp)
    80005340:	f222                	sd	s0,288(sp)
    80005342:	ee26                	sd	s1,280(sp)
    80005344:	ea4a                	sd	s2,272(sp)
    80005346:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005348:	08000613          	li	a2,128
    8000534c:	ed040593          	addi	a1,s0,-304
    80005350:	4501                	li	a0,0
    80005352:	ffffd097          	auipc	ra,0xffffd
    80005356:	7a6080e7          	jalr	1958(ra) # 80002af8 <argstr>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000535c:	10054e63          	bltz	a0,80005478 <sys_link+0x13c>
    80005360:	08000613          	li	a2,128
    80005364:	f5040593          	addi	a1,s0,-176
    80005368:	4505                	li	a0,1
    8000536a:	ffffd097          	auipc	ra,0xffffd
    8000536e:	78e080e7          	jalr	1934(ra) # 80002af8 <argstr>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005374:	10054263          	bltz	a0,80005478 <sys_link+0x13c>
  begin_op();
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	cfa080e7          	jalr	-774(ra) # 80004072 <begin_op>
  if((ip = namei(old)) == 0){
    80005380:	ed040513          	addi	a0,s0,-304
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	ade080e7          	jalr	-1314(ra) # 80003e62 <namei>
    8000538c:	84aa                	mv	s1,a0
    8000538e:	c551                	beqz	a0,8000541a <sys_link+0xde>
  ilock(ip);
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	31c080e7          	jalr	796(ra) # 800036ac <ilock>
  if(ip->type == T_DIR){
    80005398:	04449703          	lh	a4,68(s1)
    8000539c:	4785                	li	a5,1
    8000539e:	08f70463          	beq	a4,a5,80005426 <sys_link+0xea>
  ip->nlink++;
    800053a2:	04a4d783          	lhu	a5,74(s1)
    800053a6:	2785                	addiw	a5,a5,1
    800053a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ac:	8526                	mv	a0,s1
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	232080e7          	jalr	562(ra) # 800035e0 <iupdate>
  iunlock(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	3b6080e7          	jalr	950(ra) # 8000376e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053c0:	fd040593          	addi	a1,s0,-48
    800053c4:	f5040513          	addi	a0,s0,-176
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	ab8080e7          	jalr	-1352(ra) # 80003e80 <nameiparent>
    800053d0:	892a                	mv	s2,a0
    800053d2:	c935                	beqz	a0,80005446 <sys_link+0x10a>
  ilock(dp);
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	2d8080e7          	jalr	728(ra) # 800036ac <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053dc:	00092703          	lw	a4,0(s2)
    800053e0:	409c                	lw	a5,0(s1)
    800053e2:	04f71d63          	bne	a4,a5,8000543c <sys_link+0x100>
    800053e6:	40d0                	lw	a2,4(s1)
    800053e8:	fd040593          	addi	a1,s0,-48
    800053ec:	854a                	mv	a0,s2
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	9b2080e7          	jalr	-1614(ra) # 80003da0 <dirlink>
    800053f6:	04054363          	bltz	a0,8000543c <sys_link+0x100>
  iunlockput(dp);
    800053fa:	854a                	mv	a0,s2
    800053fc:	ffffe097          	auipc	ra,0xffffe
    80005400:	512080e7          	jalr	1298(ra) # 8000390e <iunlockput>
  iput(ip);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	460080e7          	jalr	1120(ra) # 80003866 <iput>
  end_op();
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	ce2080e7          	jalr	-798(ra) # 800040f0 <end_op>
  return 0;
    80005416:	4781                	li	a5,0
    80005418:	a085                	j	80005478 <sys_link+0x13c>
    end_op();
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	cd6080e7          	jalr	-810(ra) # 800040f0 <end_op>
    return -1;
    80005422:	57fd                	li	a5,-1
    80005424:	a891                	j	80005478 <sys_link+0x13c>
    iunlockput(ip);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	4e6080e7          	jalr	1254(ra) # 8000390e <iunlockput>
    end_op();
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	cc0080e7          	jalr	-832(ra) # 800040f0 <end_op>
    return -1;
    80005438:	57fd                	li	a5,-1
    8000543a:	a83d                	j	80005478 <sys_link+0x13c>
    iunlockput(dp);
    8000543c:	854a                	mv	a0,s2
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	4d0080e7          	jalr	1232(ra) # 8000390e <iunlockput>
  ilock(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	264080e7          	jalr	612(ra) # 800036ac <ilock>
  ip->nlink--;
    80005450:	04a4d783          	lhu	a5,74(s1)
    80005454:	37fd                	addiw	a5,a5,-1
    80005456:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000545a:	8526                	mv	a0,s1
    8000545c:	ffffe097          	auipc	ra,0xffffe
    80005460:	184080e7          	jalr	388(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005464:	8526                	mv	a0,s1
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	4a8080e7          	jalr	1192(ra) # 8000390e <iunlockput>
  end_op();
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	c82080e7          	jalr	-894(ra) # 800040f0 <end_op>
  return -1;
    80005476:	57fd                	li	a5,-1
}
    80005478:	853e                	mv	a0,a5
    8000547a:	70b2                	ld	ra,296(sp)
    8000547c:	7412                	ld	s0,288(sp)
    8000547e:	64f2                	ld	s1,280(sp)
    80005480:	6952                	ld	s2,272(sp)
    80005482:	6155                	addi	sp,sp,304
    80005484:	8082                	ret

0000000080005486 <sys_unlink>:
{
    80005486:	7151                	addi	sp,sp,-240
    80005488:	f586                	sd	ra,232(sp)
    8000548a:	f1a2                	sd	s0,224(sp)
    8000548c:	eda6                	sd	s1,216(sp)
    8000548e:	e9ca                	sd	s2,208(sp)
    80005490:	e5ce                	sd	s3,200(sp)
    80005492:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005494:	08000613          	li	a2,128
    80005498:	f3040593          	addi	a1,s0,-208
    8000549c:	4501                	li	a0,0
    8000549e:	ffffd097          	auipc	ra,0xffffd
    800054a2:	65a080e7          	jalr	1626(ra) # 80002af8 <argstr>
    800054a6:	18054163          	bltz	a0,80005628 <sys_unlink+0x1a2>
  begin_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	bc8080e7          	jalr	-1080(ra) # 80004072 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054b2:	fb040593          	addi	a1,s0,-80
    800054b6:	f3040513          	addi	a0,s0,-208
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	9c6080e7          	jalr	-1594(ra) # 80003e80 <nameiparent>
    800054c2:	84aa                	mv	s1,a0
    800054c4:	c979                	beqz	a0,8000559a <sys_unlink+0x114>
  ilock(dp);
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	1e6080e7          	jalr	486(ra) # 800036ac <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ce:	00003597          	auipc	a1,0x3
    800054d2:	2da58593          	addi	a1,a1,730 # 800087a8 <syscalls+0x2c0>
    800054d6:	fb040513          	addi	a0,s0,-80
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	696080e7          	jalr	1686(ra) # 80003b70 <namecmp>
    800054e2:	14050a63          	beqz	a0,80005636 <sys_unlink+0x1b0>
    800054e6:	00003597          	auipc	a1,0x3
    800054ea:	2ca58593          	addi	a1,a1,714 # 800087b0 <syscalls+0x2c8>
    800054ee:	fb040513          	addi	a0,s0,-80
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	67e080e7          	jalr	1662(ra) # 80003b70 <namecmp>
    800054fa:	12050e63          	beqz	a0,80005636 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800054fe:	f2c40613          	addi	a2,s0,-212
    80005502:	fb040593          	addi	a1,s0,-80
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	682080e7          	jalr	1666(ra) # 80003b8a <dirlookup>
    80005510:	892a                	mv	s2,a0
    80005512:	12050263          	beqz	a0,80005636 <sys_unlink+0x1b0>
  ilock(ip);
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	196080e7          	jalr	406(ra) # 800036ac <ilock>
  if(ip->nlink < 1)
    8000551e:	04a91783          	lh	a5,74(s2)
    80005522:	08f05263          	blez	a5,800055a6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005526:	04491703          	lh	a4,68(s2)
    8000552a:	4785                	li	a5,1
    8000552c:	08f70563          	beq	a4,a5,800055b6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005530:	4641                	li	a2,16
    80005532:	4581                	li	a1,0
    80005534:	fc040513          	addi	a0,s0,-64
    80005538:	ffffb097          	auipc	ra,0xffffb
    8000553c:	7c4080e7          	jalr	1988(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005540:	4741                	li	a4,16
    80005542:	f2c42683          	lw	a3,-212(s0)
    80005546:	fc040613          	addi	a2,s0,-64
    8000554a:	4581                	li	a1,0
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	508080e7          	jalr	1288(ra) # 80003a56 <writei>
    80005556:	47c1                	li	a5,16
    80005558:	0af51563          	bne	a0,a5,80005602 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000555c:	04491703          	lh	a4,68(s2)
    80005560:	4785                	li	a5,1
    80005562:	0af70863          	beq	a4,a5,80005612 <sys_unlink+0x18c>
  iunlockput(dp);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	3a6080e7          	jalr	934(ra) # 8000390e <iunlockput>
  ip->nlink--;
    80005570:	04a95783          	lhu	a5,74(s2)
    80005574:	37fd                	addiw	a5,a5,-1
    80005576:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000557a:	854a                	mv	a0,s2
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	064080e7          	jalr	100(ra) # 800035e0 <iupdate>
  iunlockput(ip);
    80005584:	854a                	mv	a0,s2
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	388080e7          	jalr	904(ra) # 8000390e <iunlockput>
  end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	b62080e7          	jalr	-1182(ra) # 800040f0 <end_op>
  return 0;
    80005596:	4501                	li	a0,0
    80005598:	a84d                	j	8000564a <sys_unlink+0x1c4>
    end_op();
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	b56080e7          	jalr	-1194(ra) # 800040f0 <end_op>
    return -1;
    800055a2:	557d                	li	a0,-1
    800055a4:	a05d                	j	8000564a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055a6:	00003517          	auipc	a0,0x3
    800055aa:	23250513          	addi	a0,a0,562 # 800087d8 <syscalls+0x2f0>
    800055ae:	ffffb097          	auipc	ra,0xffffb
    800055b2:	f98080e7          	jalr	-104(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055b6:	04c92703          	lw	a4,76(s2)
    800055ba:	02000793          	li	a5,32
    800055be:	f6e7f9e3          	bgeu	a5,a4,80005530 <sys_unlink+0xaa>
    800055c2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055c6:	4741                	li	a4,16
    800055c8:	86ce                	mv	a3,s3
    800055ca:	f1840613          	addi	a2,s0,-232
    800055ce:	4581                	li	a1,0
    800055d0:	854a                	mv	a0,s2
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	38e080e7          	jalr	910(ra) # 80003960 <readi>
    800055da:	47c1                	li	a5,16
    800055dc:	00f51b63          	bne	a0,a5,800055f2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055e0:	f1845783          	lhu	a5,-232(s0)
    800055e4:	e7a1                	bnez	a5,8000562c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055e6:	29c1                	addiw	s3,s3,16
    800055e8:	04c92783          	lw	a5,76(s2)
    800055ec:	fcf9ede3          	bltu	s3,a5,800055c6 <sys_unlink+0x140>
    800055f0:	b781                	j	80005530 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055f2:	00003517          	auipc	a0,0x3
    800055f6:	1fe50513          	addi	a0,a0,510 # 800087f0 <syscalls+0x308>
    800055fa:	ffffb097          	auipc	ra,0xffffb
    800055fe:	f4c080e7          	jalr	-180(ra) # 80000546 <panic>
    panic("unlink: writei");
    80005602:	00003517          	auipc	a0,0x3
    80005606:	20650513          	addi	a0,a0,518 # 80008808 <syscalls+0x320>
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	f3c080e7          	jalr	-196(ra) # 80000546 <panic>
    dp->nlink--;
    80005612:	04a4d783          	lhu	a5,74(s1)
    80005616:	37fd                	addiw	a5,a5,-1
    80005618:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	fc2080e7          	jalr	-62(ra) # 800035e0 <iupdate>
    80005626:	b781                	j	80005566 <sys_unlink+0xe0>
    return -1;
    80005628:	557d                	li	a0,-1
    8000562a:	a005                	j	8000564a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	2e0080e7          	jalr	736(ra) # 8000390e <iunlockput>
  iunlockput(dp);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	2d6080e7          	jalr	726(ra) # 8000390e <iunlockput>
  end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	ab0080e7          	jalr	-1360(ra) # 800040f0 <end_op>
  return -1;
    80005648:	557d                	li	a0,-1
}
    8000564a:	70ae                	ld	ra,232(sp)
    8000564c:	740e                	ld	s0,224(sp)
    8000564e:	64ee                	ld	s1,216(sp)
    80005650:	694e                	ld	s2,208(sp)
    80005652:	69ae                	ld	s3,200(sp)
    80005654:	616d                	addi	sp,sp,240
    80005656:	8082                	ret

0000000080005658 <sys_open>:

uint64
sys_open(void)
{
    80005658:	7131                	addi	sp,sp,-192
    8000565a:	fd06                	sd	ra,184(sp)
    8000565c:	f922                	sd	s0,176(sp)
    8000565e:	f526                	sd	s1,168(sp)
    80005660:	f14a                	sd	s2,160(sp)
    80005662:	ed4e                	sd	s3,152(sp)
    80005664:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005666:	08000613          	li	a2,128
    8000566a:	f5040593          	addi	a1,s0,-176
    8000566e:	4501                	li	a0,0
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	488080e7          	jalr	1160(ra) # 80002af8 <argstr>
    return -1;
    80005678:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000567a:	0c054163          	bltz	a0,8000573c <sys_open+0xe4>
    8000567e:	f4c40593          	addi	a1,s0,-180
    80005682:	4505                	li	a0,1
    80005684:	ffffd097          	auipc	ra,0xffffd
    80005688:	430080e7          	jalr	1072(ra) # 80002ab4 <argint>
    8000568c:	0a054863          	bltz	a0,8000573c <sys_open+0xe4>

  begin_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	9e2080e7          	jalr	-1566(ra) # 80004072 <begin_op>

  if(omode & O_CREATE){
    80005698:	f4c42783          	lw	a5,-180(s0)
    8000569c:	2007f793          	andi	a5,a5,512
    800056a0:	cbdd                	beqz	a5,80005756 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056a2:	4681                	li	a3,0
    800056a4:	4601                	li	a2,0
    800056a6:	4589                	li	a1,2
    800056a8:	f5040513          	addi	a0,s0,-176
    800056ac:	00000097          	auipc	ra,0x0
    800056b0:	970080e7          	jalr	-1680(ra) # 8000501c <create>
    800056b4:	892a                	mv	s2,a0
    if(ip == 0){
    800056b6:	c959                	beqz	a0,8000574c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056b8:	04491703          	lh	a4,68(s2)
    800056bc:	478d                	li	a5,3
    800056be:	00f71763          	bne	a4,a5,800056cc <sys_open+0x74>
    800056c2:	04695703          	lhu	a4,70(s2)
    800056c6:	47a5                	li	a5,9
    800056c8:	0ce7ec63          	bltu	a5,a4,800057a0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	db8080e7          	jalr	-584(ra) # 80004484 <filealloc>
    800056d4:	89aa                	mv	s3,a0
    800056d6:	10050263          	beqz	a0,800057da <sys_open+0x182>
    800056da:	00000097          	auipc	ra,0x0
    800056de:	900080e7          	jalr	-1792(ra) # 80004fda <fdalloc>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	0e054663          	bltz	a0,800057d0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056e8:	04491703          	lh	a4,68(s2)
    800056ec:	478d                	li	a5,3
    800056ee:	0cf70463          	beq	a4,a5,800057b6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056f2:	4789                	li	a5,2
    800056f4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056f8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800056fc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005700:	f4c42783          	lw	a5,-180(s0)
    80005704:	0017c713          	xori	a4,a5,1
    80005708:	8b05                	andi	a4,a4,1
    8000570a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000570e:	0037f713          	andi	a4,a5,3
    80005712:	00e03733          	snez	a4,a4
    80005716:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000571a:	4007f793          	andi	a5,a5,1024
    8000571e:	c791                	beqz	a5,8000572a <sys_open+0xd2>
    80005720:	04491703          	lh	a4,68(s2)
    80005724:	4789                	li	a5,2
    80005726:	08f70f63          	beq	a4,a5,800057c4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000572a:	854a                	mv	a0,s2
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	042080e7          	jalr	66(ra) # 8000376e <iunlock>
  end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	9bc080e7          	jalr	-1604(ra) # 800040f0 <end_op>

  return fd;
}
    8000573c:	8526                	mv	a0,s1
    8000573e:	70ea                	ld	ra,184(sp)
    80005740:	744a                	ld	s0,176(sp)
    80005742:	74aa                	ld	s1,168(sp)
    80005744:	790a                	ld	s2,160(sp)
    80005746:	69ea                	ld	s3,152(sp)
    80005748:	6129                	addi	sp,sp,192
    8000574a:	8082                	ret
      end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	9a4080e7          	jalr	-1628(ra) # 800040f0 <end_op>
      return -1;
    80005754:	b7e5                	j	8000573c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005756:	f5040513          	addi	a0,s0,-176
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	708080e7          	jalr	1800(ra) # 80003e62 <namei>
    80005762:	892a                	mv	s2,a0
    80005764:	c905                	beqz	a0,80005794 <sys_open+0x13c>
    ilock(ip);
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	f46080e7          	jalr	-186(ra) # 800036ac <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000576e:	04491703          	lh	a4,68(s2)
    80005772:	4785                	li	a5,1
    80005774:	f4f712e3          	bne	a4,a5,800056b8 <sys_open+0x60>
    80005778:	f4c42783          	lw	a5,-180(s0)
    8000577c:	dba1                	beqz	a5,800056cc <sys_open+0x74>
      iunlockput(ip);
    8000577e:	854a                	mv	a0,s2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	18e080e7          	jalr	398(ra) # 8000390e <iunlockput>
      end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	968080e7          	jalr	-1688(ra) # 800040f0 <end_op>
      return -1;
    80005790:	54fd                	li	s1,-1
    80005792:	b76d                	j	8000573c <sys_open+0xe4>
      end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	95c080e7          	jalr	-1700(ra) # 800040f0 <end_op>
      return -1;
    8000579c:	54fd                	li	s1,-1
    8000579e:	bf79                	j	8000573c <sys_open+0xe4>
    iunlockput(ip);
    800057a0:	854a                	mv	a0,s2
    800057a2:	ffffe097          	auipc	ra,0xffffe
    800057a6:	16c080e7          	jalr	364(ra) # 8000390e <iunlockput>
    end_op();
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	946080e7          	jalr	-1722(ra) # 800040f0 <end_op>
    return -1;
    800057b2:	54fd                	li	s1,-1
    800057b4:	b761                	j	8000573c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057b6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057ba:	04691783          	lh	a5,70(s2)
    800057be:	02f99223          	sh	a5,36(s3)
    800057c2:	bf2d                	j	800056fc <sys_open+0xa4>
    itrunc(ip);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	ff4080e7          	jalr	-12(ra) # 800037ba <itrunc>
    800057ce:	bfb1                	j	8000572a <sys_open+0xd2>
      fileclose(f);
    800057d0:	854e                	mv	a0,s3
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	d6e080e7          	jalr	-658(ra) # 80004540 <fileclose>
    iunlockput(ip);
    800057da:	854a                	mv	a0,s2
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	132080e7          	jalr	306(ra) # 8000390e <iunlockput>
    end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	90c080e7          	jalr	-1780(ra) # 800040f0 <end_op>
    return -1;
    800057ec:	54fd                	li	s1,-1
    800057ee:	b7b9                	j	8000573c <sys_open+0xe4>

00000000800057f0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057f0:	7175                	addi	sp,sp,-144
    800057f2:	e506                	sd	ra,136(sp)
    800057f4:	e122                	sd	s0,128(sp)
    800057f6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	87a080e7          	jalr	-1926(ra) # 80004072 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005800:	08000613          	li	a2,128
    80005804:	f7040593          	addi	a1,s0,-144
    80005808:	4501                	li	a0,0
    8000580a:	ffffd097          	auipc	ra,0xffffd
    8000580e:	2ee080e7          	jalr	750(ra) # 80002af8 <argstr>
    80005812:	02054963          	bltz	a0,80005844 <sys_mkdir+0x54>
    80005816:	4681                	li	a3,0
    80005818:	4601                	li	a2,0
    8000581a:	4585                	li	a1,1
    8000581c:	f7040513          	addi	a0,s0,-144
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	7fc080e7          	jalr	2044(ra) # 8000501c <create>
    80005828:	cd11                	beqz	a0,80005844 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	0e4080e7          	jalr	228(ra) # 8000390e <iunlockput>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	8be080e7          	jalr	-1858(ra) # 800040f0 <end_op>
  return 0;
    8000583a:	4501                	li	a0,0
}
    8000583c:	60aa                	ld	ra,136(sp)
    8000583e:	640a                	ld	s0,128(sp)
    80005840:	6149                	addi	sp,sp,144
    80005842:	8082                	ret
    end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	8ac080e7          	jalr	-1876(ra) # 800040f0 <end_op>
    return -1;
    8000584c:	557d                	li	a0,-1
    8000584e:	b7fd                	j	8000583c <sys_mkdir+0x4c>

0000000080005850 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005850:	7135                	addi	sp,sp,-160
    80005852:	ed06                	sd	ra,152(sp)
    80005854:	e922                	sd	s0,144(sp)
    80005856:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	81a080e7          	jalr	-2022(ra) # 80004072 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005860:	08000613          	li	a2,128
    80005864:	f7040593          	addi	a1,s0,-144
    80005868:	4501                	li	a0,0
    8000586a:	ffffd097          	auipc	ra,0xffffd
    8000586e:	28e080e7          	jalr	654(ra) # 80002af8 <argstr>
    80005872:	04054a63          	bltz	a0,800058c6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005876:	f6c40593          	addi	a1,s0,-148
    8000587a:	4505                	li	a0,1
    8000587c:	ffffd097          	auipc	ra,0xffffd
    80005880:	238080e7          	jalr	568(ra) # 80002ab4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005884:	04054163          	bltz	a0,800058c6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005888:	f6840593          	addi	a1,s0,-152
    8000588c:	4509                	li	a0,2
    8000588e:	ffffd097          	auipc	ra,0xffffd
    80005892:	226080e7          	jalr	550(ra) # 80002ab4 <argint>
     argint(1, &major) < 0 ||
    80005896:	02054863          	bltz	a0,800058c6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000589a:	f6841683          	lh	a3,-152(s0)
    8000589e:	f6c41603          	lh	a2,-148(s0)
    800058a2:	458d                	li	a1,3
    800058a4:	f7040513          	addi	a0,s0,-144
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	774080e7          	jalr	1908(ra) # 8000501c <create>
     argint(2, &minor) < 0 ||
    800058b0:	c919                	beqz	a0,800058c6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	05c080e7          	jalr	92(ra) # 8000390e <iunlockput>
  end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	836080e7          	jalr	-1994(ra) # 800040f0 <end_op>
  return 0;
    800058c2:	4501                	li	a0,0
    800058c4:	a031                	j	800058d0 <sys_mknod+0x80>
    end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	82a080e7          	jalr	-2006(ra) # 800040f0 <end_op>
    return -1;
    800058ce:	557d                	li	a0,-1
}
    800058d0:	60ea                	ld	ra,152(sp)
    800058d2:	644a                	ld	s0,144(sp)
    800058d4:	610d                	addi	sp,sp,160
    800058d6:	8082                	ret

00000000800058d8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058d8:	7135                	addi	sp,sp,-160
    800058da:	ed06                	sd	ra,152(sp)
    800058dc:	e922                	sd	s0,144(sp)
    800058de:	e526                	sd	s1,136(sp)
    800058e0:	e14a                	sd	s2,128(sp)
    800058e2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058e4:	ffffc097          	auipc	ra,0xffffc
    800058e8:	0e8080e7          	jalr	232(ra) # 800019cc <myproc>
    800058ec:	892a                	mv	s2,a0
  
  begin_op();
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	784080e7          	jalr	1924(ra) # 80004072 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058f6:	08000613          	li	a2,128
    800058fa:	f6040593          	addi	a1,s0,-160
    800058fe:	4501                	li	a0,0
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	1f8080e7          	jalr	504(ra) # 80002af8 <argstr>
    80005908:	04054b63          	bltz	a0,8000595e <sys_chdir+0x86>
    8000590c:	f6040513          	addi	a0,s0,-160
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	552080e7          	jalr	1362(ra) # 80003e62 <namei>
    80005918:	84aa                	mv	s1,a0
    8000591a:	c131                	beqz	a0,8000595e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	d90080e7          	jalr	-624(ra) # 800036ac <ilock>
  if(ip->type != T_DIR){
    80005924:	04449703          	lh	a4,68(s1)
    80005928:	4785                	li	a5,1
    8000592a:	04f71063          	bne	a4,a5,8000596a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000592e:	8526                	mv	a0,s1
    80005930:	ffffe097          	auipc	ra,0xffffe
    80005934:	e3e080e7          	jalr	-450(ra) # 8000376e <iunlock>
  iput(p->cwd);
    80005938:	15093503          	ld	a0,336(s2)
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	f2a080e7          	jalr	-214(ra) # 80003866 <iput>
  end_op();
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	7ac080e7          	jalr	1964(ra) # 800040f0 <end_op>
  p->cwd = ip;
    8000594c:	14993823          	sd	s1,336(s2)
  return 0;
    80005950:	4501                	li	a0,0
}
    80005952:	60ea                	ld	ra,152(sp)
    80005954:	644a                	ld	s0,144(sp)
    80005956:	64aa                	ld	s1,136(sp)
    80005958:	690a                	ld	s2,128(sp)
    8000595a:	610d                	addi	sp,sp,160
    8000595c:	8082                	ret
    end_op();
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	792080e7          	jalr	1938(ra) # 800040f0 <end_op>
    return -1;
    80005966:	557d                	li	a0,-1
    80005968:	b7ed                	j	80005952 <sys_chdir+0x7a>
    iunlockput(ip);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	fa2080e7          	jalr	-94(ra) # 8000390e <iunlockput>
    end_op();
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	77c080e7          	jalr	1916(ra) # 800040f0 <end_op>
    return -1;
    8000597c:	557d                	li	a0,-1
    8000597e:	bfd1                	j	80005952 <sys_chdir+0x7a>

0000000080005980 <sys_exec>:

uint64
sys_exec(void)
{
    80005980:	7145                	addi	sp,sp,-464
    80005982:	e786                	sd	ra,456(sp)
    80005984:	e3a2                	sd	s0,448(sp)
    80005986:	ff26                	sd	s1,440(sp)
    80005988:	fb4a                	sd	s2,432(sp)
    8000598a:	f74e                	sd	s3,424(sp)
    8000598c:	f352                	sd	s4,416(sp)
    8000598e:	ef56                	sd	s5,408(sp)
    80005990:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005992:	08000613          	li	a2,128
    80005996:	f4040593          	addi	a1,s0,-192
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	15c080e7          	jalr	348(ra) # 80002af8 <argstr>
    return -1;
    800059a4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059a6:	0c054b63          	bltz	a0,80005a7c <sys_exec+0xfc>
    800059aa:	e3840593          	addi	a1,s0,-456
    800059ae:	4505                	li	a0,1
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	126080e7          	jalr	294(ra) # 80002ad6 <argaddr>
    800059b8:	0c054263          	bltz	a0,80005a7c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059bc:	10000613          	li	a2,256
    800059c0:	4581                	li	a1,0
    800059c2:	e4040513          	addi	a0,s0,-448
    800059c6:	ffffb097          	auipc	ra,0xffffb
    800059ca:	336080e7          	jalr	822(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ce:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059d2:	89a6                	mv	s3,s1
    800059d4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059d6:	02000a13          	li	s4,32
    800059da:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059de:	00391513          	slli	a0,s2,0x3
    800059e2:	e3040593          	addi	a1,s0,-464
    800059e6:	e3843783          	ld	a5,-456(s0)
    800059ea:	953e                	add	a0,a0,a5
    800059ec:	ffffd097          	auipc	ra,0xffffd
    800059f0:	02e080e7          	jalr	46(ra) # 80002a1a <fetchaddr>
    800059f4:	02054a63          	bltz	a0,80005a28 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800059f8:	e3043783          	ld	a5,-464(s0)
    800059fc:	c3b9                	beqz	a5,80005a42 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	112080e7          	jalr	274(ra) # 80000b10 <kalloc>
    80005a06:	85aa                	mv	a1,a0
    80005a08:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a0c:	cd11                	beqz	a0,80005a28 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a0e:	6605                	lui	a2,0x1
    80005a10:	e3043503          	ld	a0,-464(s0)
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	058080e7          	jalr	88(ra) # 80002a6c <fetchstr>
    80005a1c:	00054663          	bltz	a0,80005a28 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a20:	0905                	addi	s2,s2,1
    80005a22:	09a1                	addi	s3,s3,8
    80005a24:	fb491be3          	bne	s2,s4,800059da <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a28:	f4040913          	addi	s2,s0,-192
    80005a2c:	6088                	ld	a0,0(s1)
    80005a2e:	c531                	beqz	a0,80005a7a <sys_exec+0xfa>
    kfree(argv[i]);
    80005a30:	ffffb097          	auipc	ra,0xffffb
    80005a34:	fe2080e7          	jalr	-30(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a38:	04a1                	addi	s1,s1,8
    80005a3a:	ff2499e3          	bne	s1,s2,80005a2c <sys_exec+0xac>
  return -1;
    80005a3e:	597d                	li	s2,-1
    80005a40:	a835                	j	80005a7c <sys_exec+0xfc>
      argv[i] = 0;
    80005a42:	0a8e                	slli	s5,s5,0x3
    80005a44:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a48:	00878ab3          	add	s5,a5,s0
    80005a4c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a50:	e4040593          	addi	a1,s0,-448
    80005a54:	f4040513          	addi	a0,s0,-192
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	172080e7          	jalr	370(ra) # 80004bca <exec>
    80005a60:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a62:	f4040993          	addi	s3,s0,-192
    80005a66:	6088                	ld	a0,0(s1)
    80005a68:	c911                	beqz	a0,80005a7c <sys_exec+0xfc>
    kfree(argv[i]);
    80005a6a:	ffffb097          	auipc	ra,0xffffb
    80005a6e:	fa8080e7          	jalr	-88(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a72:	04a1                	addi	s1,s1,8
    80005a74:	ff3499e3          	bne	s1,s3,80005a66 <sys_exec+0xe6>
    80005a78:	a011                	j	80005a7c <sys_exec+0xfc>
  return -1;
    80005a7a:	597d                	li	s2,-1
}
    80005a7c:	854a                	mv	a0,s2
    80005a7e:	60be                	ld	ra,456(sp)
    80005a80:	641e                	ld	s0,448(sp)
    80005a82:	74fa                	ld	s1,440(sp)
    80005a84:	795a                	ld	s2,432(sp)
    80005a86:	79ba                	ld	s3,424(sp)
    80005a88:	7a1a                	ld	s4,416(sp)
    80005a8a:	6afa                	ld	s5,408(sp)
    80005a8c:	6179                	addi	sp,sp,464
    80005a8e:	8082                	ret

0000000080005a90 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a90:	7139                	addi	sp,sp,-64
    80005a92:	fc06                	sd	ra,56(sp)
    80005a94:	f822                	sd	s0,48(sp)
    80005a96:	f426                	sd	s1,40(sp)
    80005a98:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a9a:	ffffc097          	auipc	ra,0xffffc
    80005a9e:	f32080e7          	jalr	-206(ra) # 800019cc <myproc>
    80005aa2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005aa4:	fd840593          	addi	a1,s0,-40
    80005aa8:	4501                	li	a0,0
    80005aaa:	ffffd097          	auipc	ra,0xffffd
    80005aae:	02c080e7          	jalr	44(ra) # 80002ad6 <argaddr>
    return -1;
    80005ab2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ab4:	0e054063          	bltz	a0,80005b94 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ab8:	fc840593          	addi	a1,s0,-56
    80005abc:	fd040513          	addi	a0,s0,-48
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	dd6080e7          	jalr	-554(ra) # 80004896 <pipealloc>
    return -1;
    80005ac8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005aca:	0c054563          	bltz	a0,80005b94 <sys_pipe+0x104>
  fd0 = -1;
    80005ace:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ad2:	fd043503          	ld	a0,-48(s0)
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	504080e7          	jalr	1284(ra) # 80004fda <fdalloc>
    80005ade:	fca42223          	sw	a0,-60(s0)
    80005ae2:	08054c63          	bltz	a0,80005b7a <sys_pipe+0xea>
    80005ae6:	fc843503          	ld	a0,-56(s0)
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	4f0080e7          	jalr	1264(ra) # 80004fda <fdalloc>
    80005af2:	fca42023          	sw	a0,-64(s0)
    80005af6:	06054963          	bltz	a0,80005b68 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005afa:	4691                	li	a3,4
    80005afc:	fc440613          	addi	a2,s0,-60
    80005b00:	fd843583          	ld	a1,-40(s0)
    80005b04:	68a8                	ld	a0,80(s1)
    80005b06:	ffffc097          	auipc	ra,0xffffc
    80005b0a:	bbc080e7          	jalr	-1092(ra) # 800016c2 <copyout>
    80005b0e:	02054063          	bltz	a0,80005b2e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b12:	4691                	li	a3,4
    80005b14:	fc040613          	addi	a2,s0,-64
    80005b18:	fd843583          	ld	a1,-40(s0)
    80005b1c:	0591                	addi	a1,a1,4
    80005b1e:	68a8                	ld	a0,80(s1)
    80005b20:	ffffc097          	auipc	ra,0xffffc
    80005b24:	ba2080e7          	jalr	-1118(ra) # 800016c2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b28:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b2a:	06055563          	bgez	a0,80005b94 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b2e:	fc442783          	lw	a5,-60(s0)
    80005b32:	07e9                	addi	a5,a5,26
    80005b34:	078e                	slli	a5,a5,0x3
    80005b36:	97a6                	add	a5,a5,s1
    80005b38:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b3c:	fc042783          	lw	a5,-64(s0)
    80005b40:	07e9                	addi	a5,a5,26
    80005b42:	078e                	slli	a5,a5,0x3
    80005b44:	00f48533          	add	a0,s1,a5
    80005b48:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b4c:	fd043503          	ld	a0,-48(s0)
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	9f0080e7          	jalr	-1552(ra) # 80004540 <fileclose>
    fileclose(wf);
    80005b58:	fc843503          	ld	a0,-56(s0)
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	9e4080e7          	jalr	-1564(ra) # 80004540 <fileclose>
    return -1;
    80005b64:	57fd                	li	a5,-1
    80005b66:	a03d                	j	80005b94 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b68:	fc442783          	lw	a5,-60(s0)
    80005b6c:	0007c763          	bltz	a5,80005b7a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b70:	07e9                	addi	a5,a5,26
    80005b72:	078e                	slli	a5,a5,0x3
    80005b74:	97a6                	add	a5,a5,s1
    80005b76:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b7a:	fd043503          	ld	a0,-48(s0)
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	9c2080e7          	jalr	-1598(ra) # 80004540 <fileclose>
    fileclose(wf);
    80005b86:	fc843503          	ld	a0,-56(s0)
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	9b6080e7          	jalr	-1610(ra) # 80004540 <fileclose>
    return -1;
    80005b92:	57fd                	li	a5,-1
}
    80005b94:	853e                	mv	a0,a5
    80005b96:	70e2                	ld	ra,56(sp)
    80005b98:	7442                	ld	s0,48(sp)
    80005b9a:	74a2                	ld	s1,40(sp)
    80005b9c:	6121                	addi	sp,sp,64
    80005b9e:	8082                	ret

0000000080005ba0 <kernelvec>:
    80005ba0:	7111                	addi	sp,sp,-256
    80005ba2:	e006                	sd	ra,0(sp)
    80005ba4:	e40a                	sd	sp,8(sp)
    80005ba6:	e80e                	sd	gp,16(sp)
    80005ba8:	ec12                	sd	tp,24(sp)
    80005baa:	f016                	sd	t0,32(sp)
    80005bac:	f41a                	sd	t1,40(sp)
    80005bae:	f81e                	sd	t2,48(sp)
    80005bb0:	fc22                	sd	s0,56(sp)
    80005bb2:	e0a6                	sd	s1,64(sp)
    80005bb4:	e4aa                	sd	a0,72(sp)
    80005bb6:	e8ae                	sd	a1,80(sp)
    80005bb8:	ecb2                	sd	a2,88(sp)
    80005bba:	f0b6                	sd	a3,96(sp)
    80005bbc:	f4ba                	sd	a4,104(sp)
    80005bbe:	f8be                	sd	a5,112(sp)
    80005bc0:	fcc2                	sd	a6,120(sp)
    80005bc2:	e146                	sd	a7,128(sp)
    80005bc4:	e54a                	sd	s2,136(sp)
    80005bc6:	e94e                	sd	s3,144(sp)
    80005bc8:	ed52                	sd	s4,152(sp)
    80005bca:	f156                	sd	s5,160(sp)
    80005bcc:	f55a                	sd	s6,168(sp)
    80005bce:	f95e                	sd	s7,176(sp)
    80005bd0:	fd62                	sd	s8,184(sp)
    80005bd2:	e1e6                	sd	s9,192(sp)
    80005bd4:	e5ea                	sd	s10,200(sp)
    80005bd6:	e9ee                	sd	s11,208(sp)
    80005bd8:	edf2                	sd	t3,216(sp)
    80005bda:	f1f6                	sd	t4,224(sp)
    80005bdc:	f5fa                	sd	t5,232(sp)
    80005bde:	f9fe                	sd	t6,240(sp)
    80005be0:	d07fc0ef          	jal	ra,800028e6 <kerneltrap>
    80005be4:	6082                	ld	ra,0(sp)
    80005be6:	6122                	ld	sp,8(sp)
    80005be8:	61c2                	ld	gp,16(sp)
    80005bea:	7282                	ld	t0,32(sp)
    80005bec:	7322                	ld	t1,40(sp)
    80005bee:	73c2                	ld	t2,48(sp)
    80005bf0:	7462                	ld	s0,56(sp)
    80005bf2:	6486                	ld	s1,64(sp)
    80005bf4:	6526                	ld	a0,72(sp)
    80005bf6:	65c6                	ld	a1,80(sp)
    80005bf8:	6666                	ld	a2,88(sp)
    80005bfa:	7686                	ld	a3,96(sp)
    80005bfc:	7726                	ld	a4,104(sp)
    80005bfe:	77c6                	ld	a5,112(sp)
    80005c00:	7866                	ld	a6,120(sp)
    80005c02:	688a                	ld	a7,128(sp)
    80005c04:	692a                	ld	s2,136(sp)
    80005c06:	69ca                	ld	s3,144(sp)
    80005c08:	6a6a                	ld	s4,152(sp)
    80005c0a:	7a8a                	ld	s5,160(sp)
    80005c0c:	7b2a                	ld	s6,168(sp)
    80005c0e:	7bca                	ld	s7,176(sp)
    80005c10:	7c6a                	ld	s8,184(sp)
    80005c12:	6c8e                	ld	s9,192(sp)
    80005c14:	6d2e                	ld	s10,200(sp)
    80005c16:	6dce                	ld	s11,208(sp)
    80005c18:	6e6e                	ld	t3,216(sp)
    80005c1a:	7e8e                	ld	t4,224(sp)
    80005c1c:	7f2e                	ld	t5,232(sp)
    80005c1e:	7fce                	ld	t6,240(sp)
    80005c20:	6111                	addi	sp,sp,256
    80005c22:	10200073          	sret
    80005c26:	00000013          	nop
    80005c2a:	00000013          	nop
    80005c2e:	0001                	nop

0000000080005c30 <timervec>:
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	e10c                	sd	a1,0(a0)
    80005c36:	e510                	sd	a2,8(a0)
    80005c38:	e914                	sd	a3,16(a0)
    80005c3a:	710c                	ld	a1,32(a0)
    80005c3c:	7510                	ld	a2,40(a0)
    80005c3e:	6194                	ld	a3,0(a1)
    80005c40:	96b2                	add	a3,a3,a2
    80005c42:	e194                	sd	a3,0(a1)
    80005c44:	4589                	li	a1,2
    80005c46:	14459073          	csrw	sip,a1
    80005c4a:	6914                	ld	a3,16(a0)
    80005c4c:	6510                	ld	a2,8(a0)
    80005c4e:	610c                	ld	a1,0(a0)
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	30200073          	mret
	...

0000000080005c5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c5a:	1141                	addi	sp,sp,-16
    80005c5c:	e422                	sd	s0,8(sp)
    80005c5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c60:	0c0007b7          	lui	a5,0xc000
    80005c64:	4705                	li	a4,1
    80005c66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c68:	c3d8                	sw	a4,4(a5)
}
    80005c6a:	6422                	ld	s0,8(sp)
    80005c6c:	0141                	addi	sp,sp,16
    80005c6e:	8082                	ret

0000000080005c70 <plicinithart>:

void
plicinithart(void)
{
    80005c70:	1141                	addi	sp,sp,-16
    80005c72:	e406                	sd	ra,8(sp)
    80005c74:	e022                	sd	s0,0(sp)
    80005c76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	d28080e7          	jalr	-728(ra) # 800019a0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c80:	0085171b          	slliw	a4,a0,0x8
    80005c84:	0c0027b7          	lui	a5,0xc002
    80005c88:	97ba                	add	a5,a5,a4
    80005c8a:	40200713          	li	a4,1026
    80005c8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c92:	00d5151b          	slliw	a0,a0,0xd
    80005c96:	0c2017b7          	lui	a5,0xc201
    80005c9a:	97aa                	add	a5,a5,a0
    80005c9c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ca0:	60a2                	ld	ra,8(sp)
    80005ca2:	6402                	ld	s0,0(sp)
    80005ca4:	0141                	addi	sp,sp,16
    80005ca6:	8082                	ret

0000000080005ca8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ca8:	1141                	addi	sp,sp,-16
    80005caa:	e406                	sd	ra,8(sp)
    80005cac:	e022                	sd	s0,0(sp)
    80005cae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	cf0080e7          	jalr	-784(ra) # 800019a0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cb8:	00d5151b          	slliw	a0,a0,0xd
    80005cbc:	0c2017b7          	lui	a5,0xc201
    80005cc0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cc2:	43c8                	lw	a0,4(a5)
    80005cc4:	60a2                	ld	ra,8(sp)
    80005cc6:	6402                	ld	s0,0(sp)
    80005cc8:	0141                	addi	sp,sp,16
    80005cca:	8082                	ret

0000000080005ccc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ccc:	1101                	addi	sp,sp,-32
    80005cce:	ec06                	sd	ra,24(sp)
    80005cd0:	e822                	sd	s0,16(sp)
    80005cd2:	e426                	sd	s1,8(sp)
    80005cd4:	1000                	addi	s0,sp,32
    80005cd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	cc8080e7          	jalr	-824(ra) # 800019a0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ce0:	00d5151b          	slliw	a0,a0,0xd
    80005ce4:	0c2017b7          	lui	a5,0xc201
    80005ce8:	97aa                	add	a5,a5,a0
    80005cea:	c3c4                	sw	s1,4(a5)
}
    80005cec:	60e2                	ld	ra,24(sp)
    80005cee:	6442                	ld	s0,16(sp)
    80005cf0:	64a2                	ld	s1,8(sp)
    80005cf2:	6105                	addi	sp,sp,32
    80005cf4:	8082                	ret

0000000080005cf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cf6:	1141                	addi	sp,sp,-16
    80005cf8:	e406                	sd	ra,8(sp)
    80005cfa:	e022                	sd	s0,0(sp)
    80005cfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cfe:	479d                	li	a5,7
    80005d00:	04a7cb63          	blt	a5,a0,80005d56 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d04:	0001d717          	auipc	a4,0x1d
    80005d08:	2fc70713          	addi	a4,a4,764 # 80023000 <disk>
    80005d0c:	972a                	add	a4,a4,a0
    80005d0e:	6789                	lui	a5,0x2
    80005d10:	97ba                	add	a5,a5,a4
    80005d12:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d16:	eba1                	bnez	a5,80005d66 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d18:	00451713          	slli	a4,a0,0x4
    80005d1c:	0001f797          	auipc	a5,0x1f
    80005d20:	2e47b783          	ld	a5,740(a5) # 80025000 <disk+0x2000>
    80005d24:	97ba                	add	a5,a5,a4
    80005d26:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d2a:	0001d717          	auipc	a4,0x1d
    80005d2e:	2d670713          	addi	a4,a4,726 # 80023000 <disk>
    80005d32:	972a                	add	a4,a4,a0
    80005d34:	6789                	lui	a5,0x2
    80005d36:	97ba                	add	a5,a5,a4
    80005d38:	4705                	li	a4,1
    80005d3a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d3e:	0001f517          	auipc	a0,0x1f
    80005d42:	2da50513          	addi	a0,a0,730 # 80025018 <disk+0x2018>
    80005d46:	ffffc097          	auipc	ra,0xffffc
    80005d4a:	622080e7          	jalr	1570(ra) # 80002368 <wakeup>
}
    80005d4e:	60a2                	ld	ra,8(sp)
    80005d50:	6402                	ld	s0,0(sp)
    80005d52:	0141                	addi	sp,sp,16
    80005d54:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d56:	00003517          	auipc	a0,0x3
    80005d5a:	ac250513          	addi	a0,a0,-1342 # 80008818 <syscalls+0x330>
    80005d5e:	ffffa097          	auipc	ra,0xffffa
    80005d62:	7e8080e7          	jalr	2024(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005d66:	00003517          	auipc	a0,0x3
    80005d6a:	aca50513          	addi	a0,a0,-1334 # 80008830 <syscalls+0x348>
    80005d6e:	ffffa097          	auipc	ra,0xffffa
    80005d72:	7d8080e7          	jalr	2008(ra) # 80000546 <panic>

0000000080005d76 <virtio_disk_init>:
{
    80005d76:	1101                	addi	sp,sp,-32
    80005d78:	ec06                	sd	ra,24(sp)
    80005d7a:	e822                	sd	s0,16(sp)
    80005d7c:	e426                	sd	s1,8(sp)
    80005d7e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d80:	00003597          	auipc	a1,0x3
    80005d84:	ac858593          	addi	a1,a1,-1336 # 80008848 <syscalls+0x360>
    80005d88:	0001f517          	auipc	a0,0x1f
    80005d8c:	32050513          	addi	a0,a0,800 # 800250a8 <disk+0x20a8>
    80005d90:	ffffb097          	auipc	ra,0xffffb
    80005d94:	de0080e7          	jalr	-544(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d98:	100017b7          	lui	a5,0x10001
    80005d9c:	4398                	lw	a4,0(a5)
    80005d9e:	2701                	sext.w	a4,a4
    80005da0:	747277b7          	lui	a5,0x74727
    80005da4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005da8:	0ef71063          	bne	a4,a5,80005e88 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dac:	100017b7          	lui	a5,0x10001
    80005db0:	43dc                	lw	a5,4(a5)
    80005db2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db4:	4705                	li	a4,1
    80005db6:	0ce79963          	bne	a5,a4,80005e88 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dba:	100017b7          	lui	a5,0x10001
    80005dbe:	479c                	lw	a5,8(a5)
    80005dc0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dc2:	4709                	li	a4,2
    80005dc4:	0ce79263          	bne	a5,a4,80005e88 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dc8:	100017b7          	lui	a5,0x10001
    80005dcc:	47d8                	lw	a4,12(a5)
    80005dce:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dd0:	554d47b7          	lui	a5,0x554d4
    80005dd4:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dd8:	0af71863          	bne	a4,a5,80005e88 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ddc:	100017b7          	lui	a5,0x10001
    80005de0:	4705                	li	a4,1
    80005de2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de4:	470d                	li	a4,3
    80005de6:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005de8:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005dea:	c7ffe6b7          	lui	a3,0xc7ffe
    80005dee:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005df2:	8f75                	and	a4,a4,a3
    80005df4:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df6:	472d                	li	a4,11
    80005df8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dfa:	473d                	li	a4,15
    80005dfc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005dfe:	6705                	lui	a4,0x1
    80005e00:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e02:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e06:	5bdc                	lw	a5,52(a5)
    80005e08:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e0a:	c7d9                	beqz	a5,80005e98 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e0c:	471d                	li	a4,7
    80005e0e:	08f77d63          	bgeu	a4,a5,80005ea8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e12:	100014b7          	lui	s1,0x10001
    80005e16:	47a1                	li	a5,8
    80005e18:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e1a:	6609                	lui	a2,0x2
    80005e1c:	4581                	li	a1,0
    80005e1e:	0001d517          	auipc	a0,0x1d
    80005e22:	1e250513          	addi	a0,a0,482 # 80023000 <disk>
    80005e26:	ffffb097          	auipc	ra,0xffffb
    80005e2a:	ed6080e7          	jalr	-298(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e2e:	0001d717          	auipc	a4,0x1d
    80005e32:	1d270713          	addi	a4,a4,466 # 80023000 <disk>
    80005e36:	00c75793          	srli	a5,a4,0xc
    80005e3a:	2781                	sext.w	a5,a5
    80005e3c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e3e:	0001f797          	auipc	a5,0x1f
    80005e42:	1c278793          	addi	a5,a5,450 # 80025000 <disk+0x2000>
    80005e46:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e48:	0001d717          	auipc	a4,0x1d
    80005e4c:	23870713          	addi	a4,a4,568 # 80023080 <disk+0x80>
    80005e50:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e52:	0001e717          	auipc	a4,0x1e
    80005e56:	1ae70713          	addi	a4,a4,430 # 80024000 <disk+0x1000>
    80005e5a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e5c:	4705                	li	a4,1
    80005e5e:	00e78c23          	sb	a4,24(a5)
    80005e62:	00e78ca3          	sb	a4,25(a5)
    80005e66:	00e78d23          	sb	a4,26(a5)
    80005e6a:	00e78da3          	sb	a4,27(a5)
    80005e6e:	00e78e23          	sb	a4,28(a5)
    80005e72:	00e78ea3          	sb	a4,29(a5)
    80005e76:	00e78f23          	sb	a4,30(a5)
    80005e7a:	00e78fa3          	sb	a4,31(a5)
}
    80005e7e:	60e2                	ld	ra,24(sp)
    80005e80:	6442                	ld	s0,16(sp)
    80005e82:	64a2                	ld	s1,8(sp)
    80005e84:	6105                	addi	sp,sp,32
    80005e86:	8082                	ret
    panic("could not find virtio disk");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	9d050513          	addi	a0,a0,-1584 # 80008858 <syscalls+0x370>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6b6080e7          	jalr	1718(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80005e98:	00003517          	auipc	a0,0x3
    80005e9c:	9e050513          	addi	a0,a0,-1568 # 80008878 <syscalls+0x390>
    80005ea0:	ffffa097          	auipc	ra,0xffffa
    80005ea4:	6a6080e7          	jalr	1702(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    80005ea8:	00003517          	auipc	a0,0x3
    80005eac:	9f050513          	addi	a0,a0,-1552 # 80008898 <syscalls+0x3b0>
    80005eb0:	ffffa097          	auipc	ra,0xffffa
    80005eb4:	696080e7          	jalr	1686(ra) # 80000546 <panic>

0000000080005eb8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005eb8:	7175                	addi	sp,sp,-144
    80005eba:	e506                	sd	ra,136(sp)
    80005ebc:	e122                	sd	s0,128(sp)
    80005ebe:	fca6                	sd	s1,120(sp)
    80005ec0:	f8ca                	sd	s2,112(sp)
    80005ec2:	f4ce                	sd	s3,104(sp)
    80005ec4:	f0d2                	sd	s4,96(sp)
    80005ec6:	ecd6                	sd	s5,88(sp)
    80005ec8:	e8da                	sd	s6,80(sp)
    80005eca:	e4de                	sd	s7,72(sp)
    80005ecc:	e0e2                	sd	s8,64(sp)
    80005ece:	fc66                	sd	s9,56(sp)
    80005ed0:	f86a                	sd	s10,48(sp)
    80005ed2:	f46e                	sd	s11,40(sp)
    80005ed4:	0900                	addi	s0,sp,144
    80005ed6:	8aaa                	mv	s5,a0
    80005ed8:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005eda:	00c52c83          	lw	s9,12(a0)
    80005ede:	001c9c9b          	slliw	s9,s9,0x1
    80005ee2:	1c82                	slli	s9,s9,0x20
    80005ee4:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005ee8:	0001f517          	auipc	a0,0x1f
    80005eec:	1c050513          	addi	a0,a0,448 # 800250a8 <disk+0x20a8>
    80005ef0:	ffffb097          	auipc	ra,0xffffb
    80005ef4:	d10080e7          	jalr	-752(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80005ef8:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005efa:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005efc:	0001dc17          	auipc	s8,0x1d
    80005f00:	104c0c13          	addi	s8,s8,260 # 80023000 <disk>
    80005f04:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f06:	4b0d                	li	s6,3
    80005f08:	a0ad                	j	80005f72 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f0a:	00fc0733          	add	a4,s8,a5
    80005f0e:	975e                	add	a4,a4,s7
    80005f10:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f14:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f16:	0207c563          	bltz	a5,80005f40 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f1a:	2905                	addiw	s2,s2,1
    80005f1c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f1e:	19690c63          	beq	s2,s6,800060b6 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f22:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f24:	0001f717          	auipc	a4,0x1f
    80005f28:	0f470713          	addi	a4,a4,244 # 80025018 <disk+0x2018>
    80005f2c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f2e:	00074683          	lbu	a3,0(a4)
    80005f32:	fee1                	bnez	a3,80005f0a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f34:	2785                	addiw	a5,a5,1
    80005f36:	0705                	addi	a4,a4,1
    80005f38:	fe979be3          	bne	a5,s1,80005f2e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f3c:	57fd                	li	a5,-1
    80005f3e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f40:	01205d63          	blez	s2,80005f5a <virtio_disk_rw+0xa2>
    80005f44:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f46:	000a2503          	lw	a0,0(s4)
    80005f4a:	00000097          	auipc	ra,0x0
    80005f4e:	dac080e7          	jalr	-596(ra) # 80005cf6 <free_desc>
      for(int j = 0; j < i; j++)
    80005f52:	2d85                	addiw	s11,s11,1
    80005f54:	0a11                	addi	s4,s4,4
    80005f56:	ff2d98e3          	bne	s11,s2,80005f46 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f5a:	0001f597          	auipc	a1,0x1f
    80005f5e:	14e58593          	addi	a1,a1,334 # 800250a8 <disk+0x20a8>
    80005f62:	0001f517          	auipc	a0,0x1f
    80005f66:	0b650513          	addi	a0,a0,182 # 80025018 <disk+0x2018>
    80005f6a:	ffffc097          	auipc	ra,0xffffc
    80005f6e:	27e080e7          	jalr	638(ra) # 800021e8 <sleep>
  for(int i = 0; i < 3; i++){
    80005f72:	f8040a13          	addi	s4,s0,-128
{
    80005f76:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f78:	894e                	mv	s2,s3
    80005f7a:	b765                	j	80005f22 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f7c:	0001f717          	auipc	a4,0x1f
    80005f80:	08473703          	ld	a4,132(a4) # 80025000 <disk+0x2000>
    80005f84:	973e                	add	a4,a4,a5
    80005f86:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f8a:	0001d517          	auipc	a0,0x1d
    80005f8e:	07650513          	addi	a0,a0,118 # 80023000 <disk>
    80005f92:	0001f717          	auipc	a4,0x1f
    80005f96:	06e70713          	addi	a4,a4,110 # 80025000 <disk+0x2000>
    80005f9a:	6314                	ld	a3,0(a4)
    80005f9c:	96be                	add	a3,a3,a5
    80005f9e:	00c6d603          	lhu	a2,12(a3)
    80005fa2:	00166613          	ori	a2,a2,1
    80005fa6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005faa:	f8842683          	lw	a3,-120(s0)
    80005fae:	6310                	ld	a2,0(a4)
    80005fb0:	97b2                	add	a5,a5,a2
    80005fb2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005fb6:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005fba:	0612                	slli	a2,a2,0x4
    80005fbc:	962a                	add	a2,a2,a0
    80005fbe:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fc2:	00469793          	slli	a5,a3,0x4
    80005fc6:	630c                	ld	a1,0(a4)
    80005fc8:	95be                	add	a1,a1,a5
    80005fca:	6689                	lui	a3,0x2
    80005fcc:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005fd0:	96ca                	add	a3,a3,s2
    80005fd2:	96aa                	add	a3,a3,a0
    80005fd4:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005fd6:	6314                	ld	a3,0(a4)
    80005fd8:	96be                	add	a3,a3,a5
    80005fda:	4585                	li	a1,1
    80005fdc:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005fde:	6314                	ld	a3,0(a4)
    80005fe0:	96be                	add	a3,a3,a5
    80005fe2:	4509                	li	a0,2
    80005fe4:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005fe8:	6314                	ld	a3,0(a4)
    80005fea:	97b6                	add	a5,a5,a3
    80005fec:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005ff0:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80005ff4:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80005ff8:	6714                	ld	a3,8(a4)
    80005ffa:	0026d783          	lhu	a5,2(a3)
    80005ffe:	8b9d                	andi	a5,a5,7
    80006000:	0789                	addi	a5,a5,2
    80006002:	0786                	slli	a5,a5,0x1
    80006004:	96be                	add	a3,a3,a5
    80006006:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000600a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000600e:	6718                	ld	a4,8(a4)
    80006010:	00275783          	lhu	a5,2(a4)
    80006014:	2785                	addiw	a5,a5,1
    80006016:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006022:	004aa783          	lw	a5,4(s5)
    80006026:	02b79163          	bne	a5,a1,80006048 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000602a:	0001f917          	auipc	s2,0x1f
    8000602e:	07e90913          	addi	s2,s2,126 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006032:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006034:	85ca                	mv	a1,s2
    80006036:	8556                	mv	a0,s5
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	1b0080e7          	jalr	432(ra) # 800021e8 <sleep>
  while(b->disk == 1) {
    80006040:	004aa783          	lw	a5,4(s5)
    80006044:	fe9788e3          	beq	a5,s1,80006034 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006048:	f8042483          	lw	s1,-128(s0)
    8000604c:	20048713          	addi	a4,s1,512
    80006050:	0712                	slli	a4,a4,0x4
    80006052:	0001d797          	auipc	a5,0x1d
    80006056:	fae78793          	addi	a5,a5,-82 # 80023000 <disk>
    8000605a:	97ba                	add	a5,a5,a4
    8000605c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006060:	0001f917          	auipc	s2,0x1f
    80006064:	fa090913          	addi	s2,s2,-96 # 80025000 <disk+0x2000>
    80006068:	a019                	j	8000606e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000606a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000606e:	8526                	mv	a0,s1
    80006070:	00000097          	auipc	ra,0x0
    80006074:	c86080e7          	jalr	-890(ra) # 80005cf6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006078:	0492                	slli	s1,s1,0x4
    8000607a:	00093783          	ld	a5,0(s2)
    8000607e:	97a6                	add	a5,a5,s1
    80006080:	00c7d703          	lhu	a4,12(a5)
    80006084:	8b05                	andi	a4,a4,1
    80006086:	f375                	bnez	a4,8000606a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006088:	0001f517          	auipc	a0,0x1f
    8000608c:	02050513          	addi	a0,a0,32 # 800250a8 <disk+0x20a8>
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	c24080e7          	jalr	-988(ra) # 80000cb4 <release>
}
    80006098:	60aa                	ld	ra,136(sp)
    8000609a:	640a                	ld	s0,128(sp)
    8000609c:	74e6                	ld	s1,120(sp)
    8000609e:	7946                	ld	s2,112(sp)
    800060a0:	79a6                	ld	s3,104(sp)
    800060a2:	7a06                	ld	s4,96(sp)
    800060a4:	6ae6                	ld	s5,88(sp)
    800060a6:	6b46                	ld	s6,80(sp)
    800060a8:	6ba6                	ld	s7,72(sp)
    800060aa:	6c06                	ld	s8,64(sp)
    800060ac:	7ce2                	ld	s9,56(sp)
    800060ae:	7d42                	ld	s10,48(sp)
    800060b0:	7da2                	ld	s11,40(sp)
    800060b2:	6149                	addi	sp,sp,144
    800060b4:	8082                	ret
  if(write)
    800060b6:	01a037b3          	snez	a5,s10
    800060ba:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800060be:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800060c2:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060c6:	f8042483          	lw	s1,-128(s0)
    800060ca:	00449913          	slli	s2,s1,0x4
    800060ce:	0001f997          	auipc	s3,0x1f
    800060d2:	f3298993          	addi	s3,s3,-206 # 80025000 <disk+0x2000>
    800060d6:	0009ba03          	ld	s4,0(s3)
    800060da:	9a4a                	add	s4,s4,s2
    800060dc:	f7040513          	addi	a0,s0,-144
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	fec080e7          	jalr	-20(ra) # 800010cc <kvmpa>
    800060e8:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060ec:	0009b783          	ld	a5,0(s3)
    800060f0:	97ca                	add	a5,a5,s2
    800060f2:	4741                	li	a4,16
    800060f4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f6:	0009b783          	ld	a5,0(s3)
    800060fa:	97ca                	add	a5,a5,s2
    800060fc:	4705                	li	a4,1
    800060fe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006102:	f8442783          	lw	a5,-124(s0)
    80006106:	0009b703          	ld	a4,0(s3)
    8000610a:	974a                	add	a4,a4,s2
    8000610c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0792                	slli	a5,a5,0x4
    80006112:	0009b703          	ld	a4,0(s3)
    80006116:	973e                	add	a4,a4,a5
    80006118:	058a8693          	addi	a3,s5,88
    8000611c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000611e:	0009b703          	ld	a4,0(s3)
    80006122:	973e                	add	a4,a4,a5
    80006124:	40000693          	li	a3,1024
    80006128:	c714                	sw	a3,8(a4)
  if(write)
    8000612a:	e40d19e3          	bnez	s10,80005f7c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000612e:	0001f717          	auipc	a4,0x1f
    80006132:	ed273703          	ld	a4,-302(a4) # 80025000 <disk+0x2000>
    80006136:	973e                	add	a4,a4,a5
    80006138:	4689                	li	a3,2
    8000613a:	00d71623          	sh	a3,12(a4)
    8000613e:	b5b1                	j	80005f8a <virtio_disk_rw+0xd2>

0000000080006140 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006140:	1101                	addi	sp,sp,-32
    80006142:	ec06                	sd	ra,24(sp)
    80006144:	e822                	sd	s0,16(sp)
    80006146:	e426                	sd	s1,8(sp)
    80006148:	e04a                	sd	s2,0(sp)
    8000614a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000614c:	0001f517          	auipc	a0,0x1f
    80006150:	f5c50513          	addi	a0,a0,-164 # 800250a8 <disk+0x20a8>
    80006154:	ffffb097          	auipc	ra,0xffffb
    80006158:	aac080e7          	jalr	-1364(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000615c:	0001f717          	auipc	a4,0x1f
    80006160:	ea470713          	addi	a4,a4,-348 # 80025000 <disk+0x2000>
    80006164:	02075783          	lhu	a5,32(a4)
    80006168:	6b18                	ld	a4,16(a4)
    8000616a:	00275683          	lhu	a3,2(a4)
    8000616e:	8ebd                	xor	a3,a3,a5
    80006170:	8a9d                	andi	a3,a3,7
    80006172:	cab9                	beqz	a3,800061c8 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006174:	0001d917          	auipc	s2,0x1d
    80006178:	e8c90913          	addi	s2,s2,-372 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000617c:	0001f497          	auipc	s1,0x1f
    80006180:	e8448493          	addi	s1,s1,-380 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    80006184:	078e                	slli	a5,a5,0x3
    80006186:	973e                	add	a4,a4,a5
    80006188:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    8000618a:	20078713          	addi	a4,a5,512
    8000618e:	0712                	slli	a4,a4,0x4
    80006190:	974a                	add	a4,a4,s2
    80006192:	03074703          	lbu	a4,48(a4)
    80006196:	ef21                	bnez	a4,800061ee <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006198:	20078793          	addi	a5,a5,512
    8000619c:	0792                	slli	a5,a5,0x4
    8000619e:	97ca                	add	a5,a5,s2
    800061a0:	7798                	ld	a4,40(a5)
    800061a2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061a6:	7788                	ld	a0,40(a5)
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	1c0080e7          	jalr	448(ra) # 80002368 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061b0:	0204d783          	lhu	a5,32(s1)
    800061b4:	2785                	addiw	a5,a5,1
    800061b6:	8b9d                	andi	a5,a5,7
    800061b8:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061bc:	6898                	ld	a4,16(s1)
    800061be:	00275683          	lhu	a3,2(a4)
    800061c2:	8a9d                	andi	a3,a3,7
    800061c4:	fcf690e3          	bne	a3,a5,80006184 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061c8:	10001737          	lui	a4,0x10001
    800061cc:	533c                	lw	a5,96(a4)
    800061ce:	8b8d                	andi	a5,a5,3
    800061d0:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061d2:	0001f517          	auipc	a0,0x1f
    800061d6:	ed650513          	addi	a0,a0,-298 # 800250a8 <disk+0x20a8>
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	ada080e7          	jalr	-1318(ra) # 80000cb4 <release>
}
    800061e2:	60e2                	ld	ra,24(sp)
    800061e4:	6442                	ld	s0,16(sp)
    800061e6:	64a2                	ld	s1,8(sp)
    800061e8:	6902                	ld	s2,0(sp)
    800061ea:	6105                	addi	sp,sp,32
    800061ec:	8082                	ret
      panic("virtio_disk_intr status");
    800061ee:	00002517          	auipc	a0,0x2
    800061f2:	6ca50513          	addi	a0,a0,1738 # 800088b8 <syscalls+0x3d0>
    800061f6:	ffffa097          	auipc	ra,0xffffa
    800061fa:	350080e7          	jalr	848(ra) # 80000546 <panic>
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
