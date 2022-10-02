
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
    80000060:	bf478793          	addi	a5,a5,-1036 # 80005c50 <timervec>
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
    80000efc:	d98080e7          	jalr	-616(ra) # 80005c90 <plicinithart>
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
    80000f7c:	d02080e7          	jalr	-766(ra) # 80005c7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	d10080e7          	jalr	-752(ra) # 80005c90 <plicinithart>
    binit();         // buffer cache
    80000f88:	00002097          	auipc	ra,0x2
    80000f8c:	eb0080e7          	jalr	-336(ra) # 80002e38 <binit>
    iinit();         // inode cache
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	53e080e7          	jalr	1342(ra) # 800034ce <iinit>
    fileinit();      // file table
    80000f98:	00003097          	auipc	ra,0x3
    80000f9c:	4e0080e7          	jalr	1248(ra) # 80004478 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	df6080e7          	jalr	-522(ra) # 80005d96 <virtio_disk_init>
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
    80001a20:	ed47a783          	lw	a5,-300(a5) # 800088f0 <first.1>
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
    80001a3a:	ea07ad23          	sw	zero,-326(a5) # 800088f0 <first.1>
    fsinit(ROOTDEV);
    80001a3e:	4505                	li	a0,1
    80001a40:	00002097          	auipc	ra,0x2
    80001a44:	a0e080e7          	jalr	-1522(ra) # 8000344e <fsinit>
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
    80001a6c:	e8c78793          	addi	a5,a5,-372 # 800088f4 <nextpid>
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
    80001cba:	c4a58593          	addi	a1,a1,-950 # 80008900 <initcode>
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
    80001cf8:	18a080e7          	jalr	394(ra) # 80003e7e <namei>
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
    80001e4e:	6c0080e7          	jalr	1728(ra) # 8000450a <filedup>
    80001e52:	00a93023          	sd	a0,0(s2)
    80001e56:	b7e5                	j	80001e3e <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e58:	150ab503          	ld	a0,336(s5)
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	82e080e7          	jalr	-2002(ra) # 8000368a <idup>
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
    800020e6:	47a080e7          	jalr	1146(ra) # 8000455c <fileclose>
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
    800020fe:	f94080e7          	jalr	-108(ra) # 8000408e <begin_op>
  iput(p->cwd);
    80002102:	1509b503          	ld	a0,336(s3)
    80002106:	00001097          	auipc	ra,0x1
    8000210a:	77c080e7          	jalr	1916(ra) # 80003882 <iput>
  end_op();
    8000210e:	00002097          	auipc	ra,0x2
    80002112:	ffe080e7          	jalr	-2(ra) # 8000410c <end_op>
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
  myproc()->mask = mask;
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	57e080e7          	jalr	1406(ra) # 800019cc <myproc>
    80002456:	16952423          	sw	s1,360(a0)
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
    8000265e:	56678793          	addi	a5,a5,1382 # 80005bc0 <kernelvec>
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
    80002786:	546080e7          	jalr	1350(ra) # 80005cc8 <plic_claim>
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
    800027b4:	53c080e7          	jalr	1340(ra) # 80005cec <plic_complete>
    return 1;
    800027b8:	4505                	li	a0,1
    800027ba:	bf55                	j	8000276e <devintr+0x1e>
      uartintr();
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	206080e7          	jalr	518(ra) # 800009c2 <uartintr>
    800027c4:	b7ed                	j	800027ae <devintr+0x5e>
      virtio_disk_intr();
    800027c6:	00004097          	auipc	ra,0x4
    800027ca:	99a080e7          	jalr	-1638(ra) # 80006160 <virtio_disk_intr>
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
    8000280c:	3b878793          	addi	a5,a5,952 # 80005bc0 <kernelvec>
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
  int fstarg;
  argint(0,&fstarg);//get first arg
    80002b4a:	fcc40593          	addi	a1,s0,-52
    80002b4e:	4501                	li	a0,0
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	f64080e7          	jalr	-156(ra) # 80002ab4 <argint>
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b58:	397d                	addiw	s2,s2,-1
    80002b5a:	47d9                	li	a5,22
    80002b5c:	0527ed63          	bltu	a5,s2,80002bb6 <syscall+0x8e>
    80002b60:	00399713          	slli	a4,s3,0x3
    80002b64:	00006797          	auipc	a5,0x6
    80002b68:	98478793          	addi	a5,a5,-1660 # 800084e8 <syscalls>
    80002b6c:	97ba                	add	a5,a5,a4
    80002b6e:	639c                	ld	a5,0(a5)
    80002b70:	c3b9                	beqz	a5,80002bb6 <syscall+0x8e>
    p->trapframe->a0 = syscalls[num]();
    80002b72:	0584b903          	ld	s2,88(s1)
    80002b76:	9782                	jalr	a5
    80002b78:	06a93823          	sd	a0,112(s2)
      if(p->mask&(1<<num)&&p->mask > 0){
    80002b7c:	1684a703          	lw	a4,360(s1)
    80002b80:	413757bb          	sraw	a5,a4,s3
    80002b84:	8b85                	andi	a5,a5,1
    80002b86:	c7b9                	beqz	a5,80002bd4 <syscall+0xac>
    80002b88:	04e05663          	blez	a4,80002bd4 <syscall+0xac>
      // printf("%d:sys_%s(%d)->%d\n",p->pid, p->name, p->trapframe->a0, p->trapframe->ra);
      printf("%d: sys_%s(%d) -> %d\n",p->pid, syscall_names[num], fstarg, p->trapframe->a0);
    80002b8c:	6cb8                	ld	a4,88(s1)
    80002b8e:	098e                	slli	s3,s3,0x3
    80002b90:	00006797          	auipc	a5,0x6
    80002b94:	da878793          	addi	a5,a5,-600 # 80008938 <syscall_names>
    80002b98:	97ce                	add	a5,a5,s3
    80002b9a:	7b38                	ld	a4,112(a4)
    80002b9c:	fcc42683          	lw	a3,-52(s0)
    80002ba0:	6390                	ld	a2,0(a5)
    80002ba2:	5c8c                	lw	a1,56(s1)
    80002ba4:	00006517          	auipc	a0,0x6
    80002ba8:	84c50513          	addi	a0,a0,-1972 # 800083f0 <states.0+0x148>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	9e4080e7          	jalr	-1564(ra) # 80000590 <printf>
    80002bb4:	a005                	j	80002bd4 <syscall+0xac>
  }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bb6:	86ce                	mv	a3,s3
    80002bb8:	15848613          	addi	a2,s1,344
    80002bbc:	5c8c                	lw	a1,56(s1)
    80002bbe:	00006517          	auipc	a0,0x6
    80002bc2:	84a50513          	addi	a0,a0,-1974 # 80008408 <states.0+0x160>
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	9ca080e7          	jalr	-1590(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bce:	6cbc                	ld	a5,88(s1)
    80002bd0:	577d                	li	a4,-1
    80002bd2:	fbb8                	sd	a4,112(a5)
  }


}
    80002bd4:	70e2                	ld	ra,56(sp)
    80002bd6:	7442                	ld	s0,48(sp)
    80002bd8:	74a2                	ld	s1,40(sp)
    80002bda:	7902                	ld	s2,32(sp)
    80002bdc:	69e2                	ld	s3,24(sp)
    80002bde:	6121                	addi	sp,sp,64
    80002be0:	8082                	ret

0000000080002be2 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002bea:	fec40593          	addi	a1,s0,-20
    80002bee:	4501                	li	a0,0
    80002bf0:	00000097          	auipc	ra,0x0
    80002bf4:	ec4080e7          	jalr	-316(ra) # 80002ab4 <argint>
    return -1;
    80002bf8:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002bfa:	00054963          	bltz	a0,80002c0c <sys_exit+0x2a>
  exit(n);
    80002bfe:	fec42503          	lw	a0,-20(s0)
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	4a0080e7          	jalr	1184(ra) # 800020a2 <exit>
  return 0; // not reached
    80002c0a:	4781                	li	a5,0
}
    80002c0c:	853e                	mv	a0,a5
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret

0000000080002c16 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c16:	1141                	addi	sp,sp,-16
    80002c18:	e406                	sd	ra,8(sp)
    80002c1a:	e022                	sd	s0,0(sp)
    80002c1c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	dae080e7          	jalr	-594(ra) # 800019cc <myproc>
}
    80002c26:	5d08                	lw	a0,56(a0)
    80002c28:	60a2                	ld	ra,8(sp)
    80002c2a:	6402                	ld	s0,0(sp)
    80002c2c:	0141                	addi	sp,sp,16
    80002c2e:	8082                	ret

0000000080002c30 <sys_fork>:

uint64
sys_fork(void)
{
    80002c30:	1141                	addi	sp,sp,-16
    80002c32:	e406                	sd	ra,8(sp)
    80002c34:	e022                	sd	s0,0(sp)
    80002c36:	0800                	addi	s0,sp,16
  return fork();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	158080e7          	jalr	344(ra) # 80001d90 <fork>
}
    80002c40:	60a2                	ld	ra,8(sp)
    80002c42:	6402                	ld	s0,0(sp)
    80002c44:	0141                	addi	sp,sp,16
    80002c46:	8082                	ret

0000000080002c48 <sys_wait>:

uint64
sys_wait(void)
{
    80002c48:	1101                	addi	sp,sp,-32
    80002c4a:	ec06                	sd	ra,24(sp)
    80002c4c:	e822                	sd	s0,16(sp)
    80002c4e:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002c50:	fe840593          	addi	a1,s0,-24
    80002c54:	4501                	li	a0,0
    80002c56:	00000097          	auipc	ra,0x0
    80002c5a:	e80080e7          	jalr	-384(ra) # 80002ad6 <argaddr>
    80002c5e:	87aa                	mv	a5,a0
    return -1;
    80002c60:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002c62:	0007c863          	bltz	a5,80002c72 <sys_wait+0x2a>
  return wait(p);
    80002c66:	fe843503          	ld	a0,-24(s0)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	5fc080e7          	jalr	1532(ra) # 80002266 <wait>
}
    80002c72:	60e2                	ld	ra,24(sp)
    80002c74:	6442                	ld	s0,16(sp)
    80002c76:	6105                	addi	sp,sp,32
    80002c78:	8082                	ret

0000000080002c7a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c7a:	7179                	addi	sp,sp,-48
    80002c7c:	f406                	sd	ra,40(sp)
    80002c7e:	f022                	sd	s0,32(sp)
    80002c80:	ec26                	sd	s1,24(sp)
    80002c82:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002c84:	fdc40593          	addi	a1,s0,-36
    80002c88:	4501                	li	a0,0
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	e2a080e7          	jalr	-470(ra) # 80002ab4 <argint>
    80002c92:	87aa                	mv	a5,a0
    return -1;
    80002c94:	557d                	li	a0,-1
  if (argint(0, &n) < 0)
    80002c96:	0207c063          	bltz	a5,80002cb6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	d32080e7          	jalr	-718(ra) # 800019cc <myproc>
    80002ca2:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80002ca4:	fdc42503          	lw	a0,-36(s0)
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	070080e7          	jalr	112(ra) # 80001d18 <growproc>
    80002cb0:	00054863          	bltz	a0,80002cc0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cb4:	8526                	mv	a0,s1
}
    80002cb6:	70a2                	ld	ra,40(sp)
    80002cb8:	7402                	ld	s0,32(sp)
    80002cba:	64e2                	ld	s1,24(sp)
    80002cbc:	6145                	addi	sp,sp,48
    80002cbe:	8082                	ret
    return -1;
    80002cc0:	557d                	li	a0,-1
    80002cc2:	bfd5                	j	80002cb6 <sys_sbrk+0x3c>

0000000080002cc4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cc4:	7139                	addi	sp,sp,-64
    80002cc6:	fc06                	sd	ra,56(sp)
    80002cc8:	f822                	sd	s0,48(sp)
    80002cca:	f426                	sd	s1,40(sp)
    80002ccc:	f04a                	sd	s2,32(sp)
    80002cce:	ec4e                	sd	s3,24(sp)
    80002cd0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002cd2:	fcc40593          	addi	a1,s0,-52
    80002cd6:	4501                	li	a0,0
    80002cd8:	00000097          	auipc	ra,0x0
    80002cdc:	ddc080e7          	jalr	-548(ra) # 80002ab4 <argint>
    return -1;
    80002ce0:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002ce2:	06054563          	bltz	a0,80002d4c <sys_sleep+0x88>
  acquire(&tickslock);
    80002ce6:	00015517          	auipc	a0,0x15
    80002cea:	c8250513          	addi	a0,a0,-894 # 80017968 <tickslock>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	f12080e7          	jalr	-238(ra) # 80000c00 <acquire>
  ticks0 = ticks;
    80002cf6:	00006917          	auipc	s2,0x6
    80002cfa:	32a92903          	lw	s2,810(s2) # 80009020 <ticks>
  while (ticks - ticks0 < n)
    80002cfe:	fcc42783          	lw	a5,-52(s0)
    80002d02:	cf85                	beqz	a5,80002d3a <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d04:	00015997          	auipc	s3,0x15
    80002d08:	c6498993          	addi	s3,s3,-924 # 80017968 <tickslock>
    80002d0c:	00006497          	auipc	s1,0x6
    80002d10:	31448493          	addi	s1,s1,788 # 80009020 <ticks>
    if (myproc()->killed)
    80002d14:	fffff097          	auipc	ra,0xfffff
    80002d18:	cb8080e7          	jalr	-840(ra) # 800019cc <myproc>
    80002d1c:	591c                	lw	a5,48(a0)
    80002d1e:	ef9d                	bnez	a5,80002d5c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d20:	85ce                	mv	a1,s3
    80002d22:	8526                	mv	a0,s1
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	4c4080e7          	jalr	1220(ra) # 800021e8 <sleep>
  while (ticks - ticks0 < n)
    80002d2c:	409c                	lw	a5,0(s1)
    80002d2e:	412787bb          	subw	a5,a5,s2
    80002d32:	fcc42703          	lw	a4,-52(s0)
    80002d36:	fce7efe3          	bltu	a5,a4,80002d14 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d3a:	00015517          	auipc	a0,0x15
    80002d3e:	c2e50513          	addi	a0,a0,-978 # 80017968 <tickslock>
    80002d42:	ffffe097          	auipc	ra,0xffffe
    80002d46:	f72080e7          	jalr	-142(ra) # 80000cb4 <release>
  return 0;
    80002d4a:	4781                	li	a5,0
}
    80002d4c:	853e                	mv	a0,a5
    80002d4e:	70e2                	ld	ra,56(sp)
    80002d50:	7442                	ld	s0,48(sp)
    80002d52:	74a2                	ld	s1,40(sp)
    80002d54:	7902                	ld	s2,32(sp)
    80002d56:	69e2                	ld	s3,24(sp)
    80002d58:	6121                	addi	sp,sp,64
    80002d5a:	8082                	ret
      release(&tickslock);
    80002d5c:	00015517          	auipc	a0,0x15
    80002d60:	c0c50513          	addi	a0,a0,-1012 # 80017968 <tickslock>
    80002d64:	ffffe097          	auipc	ra,0xffffe
    80002d68:	f50080e7          	jalr	-176(ra) # 80000cb4 <release>
      return -1;
    80002d6c:	57fd                	li	a5,-1
    80002d6e:	bff9                	j	80002d4c <sys_sleep+0x88>

0000000080002d70 <sys_kill>:

uint64
sys_kill(void)
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002d78:	fec40593          	addi	a1,s0,-20
    80002d7c:	4501                	li	a0,0
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	d36080e7          	jalr	-714(ra) # 80002ab4 <argint>
    80002d86:	87aa                	mv	a5,a0
    return -1;
    80002d88:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002d8a:	0007c863          	bltz	a5,80002d9a <sys_kill+0x2a>
  return kill(pid);
    80002d8e:	fec42503          	lw	a0,-20(s0)
    80002d92:	fffff097          	auipc	ra,0xfffff
    80002d96:	640080e7          	jalr	1600(ra) # 800023d2 <kill>
}
    80002d9a:	60e2                	ld	ra,24(sp)
    80002d9c:	6442                	ld	s0,16(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	e426                	sd	s1,8(sp)
    80002daa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dac:	00015517          	auipc	a0,0x15
    80002db0:	bbc50513          	addi	a0,a0,-1092 # 80017968 <tickslock>
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	e4c080e7          	jalr	-436(ra) # 80000c00 <acquire>
  xticks = ticks;
    80002dbc:	00006497          	auipc	s1,0x6
    80002dc0:	2644a483          	lw	s1,612(s1) # 80009020 <ticks>
  release(&tickslock);
    80002dc4:	00015517          	auipc	a0,0x15
    80002dc8:	ba450513          	addi	a0,a0,-1116 # 80017968 <tickslock>
    80002dcc:	ffffe097          	auipc	ra,0xffffe
    80002dd0:	ee8080e7          	jalr	-280(ra) # 80000cb4 <release>
  return xticks;
}
    80002dd4:	02049513          	slli	a0,s1,0x20
    80002dd8:	9101                	srli	a0,a0,0x20
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret

0000000080002de4 <sys_trace>:

uint64
sys_trace(void)
{ 
    80002de4:	1101                	addi	sp,sp,-32
    80002de6:	ec06                	sd	ra,24(sp)
    80002de8:	e822                	sd	s0,16(sp)
    80002dea:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0)
    80002dec:	fec40593          	addi	a1,s0,-20
    80002df0:	4501                	li	a0,0
    80002df2:	00000097          	auipc	ra,0x0
    80002df6:	cc2080e7          	jalr	-830(ra) # 80002ab4 <argint>
    80002dfa:	87aa                	mv	a5,a0
    return -1;
    80002dfc:	557d                	li	a0,-1
  if(argint(0, &mask) < 0)
    80002dfe:	0007c863          	bltz	a5,80002e0e <sys_trace+0x2a>
  return trace(mask);
    80002e02:	fec42503          	lw	a0,-20(s0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	63c080e7          	jalr	1596(ra) # 80002442 <trace>
}
    80002e0e:	60e2                	ld	ra,24(sp)
    80002e10:	6442                	ld	s0,16(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret

0000000080002e16 <sys_sysinfo>:
uint64
sys_sysinfo(void){
    80002e16:	1141                	addi	sp,sp,-16
    80002e18:	e406                	sd	ra,8(sp)
    80002e1a:	e022                	sd	s0,0(sp)
    80002e1c:	0800                	addi	s0,sp,16
  printf("test words\n");
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	78a50513          	addi	a0,a0,1930 # 800085a8 <syscalls+0xc0>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	76a080e7          	jalr	1898(ra) # 80000590 <printf>
  return 0;
}
    80002e2e:	4501                	li	a0,0
    80002e30:	60a2                	ld	ra,8(sp)
    80002e32:	6402                	ld	s0,0(sp)
    80002e34:	0141                	addi	sp,sp,16
    80002e36:	8082                	ret

0000000080002e38 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e38:	7179                	addi	sp,sp,-48
    80002e3a:	f406                	sd	ra,40(sp)
    80002e3c:	f022                	sd	s0,32(sp)
    80002e3e:	ec26                	sd	s1,24(sp)
    80002e40:	e84a                	sd	s2,16(sp)
    80002e42:	e44e                	sd	s3,8(sp)
    80002e44:	e052                	sd	s4,0(sp)
    80002e46:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e48:	00005597          	auipc	a1,0x5
    80002e4c:	77058593          	addi	a1,a1,1904 # 800085b8 <syscalls+0xd0>
    80002e50:	00015517          	auipc	a0,0x15
    80002e54:	b3050513          	addi	a0,a0,-1232 # 80017980 <bcache>
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	d18080e7          	jalr	-744(ra) # 80000b70 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e60:	0001d797          	auipc	a5,0x1d
    80002e64:	b2078793          	addi	a5,a5,-1248 # 8001f980 <bcache+0x8000>
    80002e68:	0001d717          	auipc	a4,0x1d
    80002e6c:	d8070713          	addi	a4,a4,-640 # 8001fbe8 <bcache+0x8268>
    80002e70:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e74:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e78:	00015497          	auipc	s1,0x15
    80002e7c:	b2048493          	addi	s1,s1,-1248 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002e80:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e82:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e84:	00005a17          	auipc	s4,0x5
    80002e88:	73ca0a13          	addi	s4,s4,1852 # 800085c0 <syscalls+0xd8>
    b->next = bcache.head.next;
    80002e8c:	2b893783          	ld	a5,696(s2)
    80002e90:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e92:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e96:	85d2                	mv	a1,s4
    80002e98:	01048513          	addi	a0,s1,16
    80002e9c:	00001097          	auipc	ra,0x1
    80002ea0:	4b2080e7          	jalr	1202(ra) # 8000434e <initsleeplock>
    bcache.head.next->prev = b;
    80002ea4:	2b893783          	ld	a5,696(s2)
    80002ea8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002eaa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eae:	45848493          	addi	s1,s1,1112
    80002eb2:	fd349de3          	bne	s1,s3,80002e8c <binit+0x54>
  }
}
    80002eb6:	70a2                	ld	ra,40(sp)
    80002eb8:	7402                	ld	s0,32(sp)
    80002eba:	64e2                	ld	s1,24(sp)
    80002ebc:	6942                	ld	s2,16(sp)
    80002ebe:	69a2                	ld	s3,8(sp)
    80002ec0:	6a02                	ld	s4,0(sp)
    80002ec2:	6145                	addi	sp,sp,48
    80002ec4:	8082                	ret

0000000080002ec6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ec6:	7179                	addi	sp,sp,-48
    80002ec8:	f406                	sd	ra,40(sp)
    80002eca:	f022                	sd	s0,32(sp)
    80002ecc:	ec26                	sd	s1,24(sp)
    80002ece:	e84a                	sd	s2,16(sp)
    80002ed0:	e44e                	sd	s3,8(sp)
    80002ed2:	1800                	addi	s0,sp,48
    80002ed4:	892a                	mv	s2,a0
    80002ed6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ed8:	00015517          	auipc	a0,0x15
    80002edc:	aa850513          	addi	a0,a0,-1368 # 80017980 <bcache>
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	d20080e7          	jalr	-736(ra) # 80000c00 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ee8:	0001d497          	auipc	s1,0x1d
    80002eec:	d504b483          	ld	s1,-688(s1) # 8001fc38 <bcache+0x82b8>
    80002ef0:	0001d797          	auipc	a5,0x1d
    80002ef4:	cf878793          	addi	a5,a5,-776 # 8001fbe8 <bcache+0x8268>
    80002ef8:	02f48f63          	beq	s1,a5,80002f36 <bread+0x70>
    80002efc:	873e                	mv	a4,a5
    80002efe:	a021                	j	80002f06 <bread+0x40>
    80002f00:	68a4                	ld	s1,80(s1)
    80002f02:	02e48a63          	beq	s1,a4,80002f36 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f06:	449c                	lw	a5,8(s1)
    80002f08:	ff279ce3          	bne	a5,s2,80002f00 <bread+0x3a>
    80002f0c:	44dc                	lw	a5,12(s1)
    80002f0e:	ff3799e3          	bne	a5,s3,80002f00 <bread+0x3a>
      b->refcnt++;
    80002f12:	40bc                	lw	a5,64(s1)
    80002f14:	2785                	addiw	a5,a5,1
    80002f16:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f18:	00015517          	auipc	a0,0x15
    80002f1c:	a6850513          	addi	a0,a0,-1432 # 80017980 <bcache>
    80002f20:	ffffe097          	auipc	ra,0xffffe
    80002f24:	d94080e7          	jalr	-620(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002f28:	01048513          	addi	a0,s1,16
    80002f2c:	00001097          	auipc	ra,0x1
    80002f30:	45c080e7          	jalr	1116(ra) # 80004388 <acquiresleep>
      return b;
    80002f34:	a8b9                	j	80002f92 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f36:	0001d497          	auipc	s1,0x1d
    80002f3a:	cfa4b483          	ld	s1,-774(s1) # 8001fc30 <bcache+0x82b0>
    80002f3e:	0001d797          	auipc	a5,0x1d
    80002f42:	caa78793          	addi	a5,a5,-854 # 8001fbe8 <bcache+0x8268>
    80002f46:	00f48863          	beq	s1,a5,80002f56 <bread+0x90>
    80002f4a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f4c:	40bc                	lw	a5,64(s1)
    80002f4e:	cf81                	beqz	a5,80002f66 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f50:	64a4                	ld	s1,72(s1)
    80002f52:	fee49de3          	bne	s1,a4,80002f4c <bread+0x86>
  panic("bget: no buffers");
    80002f56:	00005517          	auipc	a0,0x5
    80002f5a:	67250513          	addi	a0,a0,1650 # 800085c8 <syscalls+0xe0>
    80002f5e:	ffffd097          	auipc	ra,0xffffd
    80002f62:	5e8080e7          	jalr	1512(ra) # 80000546 <panic>
      b->dev = dev;
    80002f66:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f6a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f6e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f72:	4785                	li	a5,1
    80002f74:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f76:	00015517          	auipc	a0,0x15
    80002f7a:	a0a50513          	addi	a0,a0,-1526 # 80017980 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	d36080e7          	jalr	-714(ra) # 80000cb4 <release>
      acquiresleep(&b->lock);
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	3fe080e7          	jalr	1022(ra) # 80004388 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f92:	409c                	lw	a5,0(s1)
    80002f94:	cb89                	beqz	a5,80002fa6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f96:	8526                	mv	a0,s1
    80002f98:	70a2                	ld	ra,40(sp)
    80002f9a:	7402                	ld	s0,32(sp)
    80002f9c:	64e2                	ld	s1,24(sp)
    80002f9e:	6942                	ld	s2,16(sp)
    80002fa0:	69a2                	ld	s3,8(sp)
    80002fa2:	6145                	addi	sp,sp,48
    80002fa4:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fa6:	4581                	li	a1,0
    80002fa8:	8526                	mv	a0,s1
    80002faa:	00003097          	auipc	ra,0x3
    80002fae:	f2e080e7          	jalr	-210(ra) # 80005ed8 <virtio_disk_rw>
    b->valid = 1;
    80002fb2:	4785                	li	a5,1
    80002fb4:	c09c                	sw	a5,0(s1)
  return b;
    80002fb6:	b7c5                	j	80002f96 <bread+0xd0>

0000000080002fb8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	e426                	sd	s1,8(sp)
    80002fc0:	1000                	addi	s0,sp,32
    80002fc2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fc4:	0541                	addi	a0,a0,16
    80002fc6:	00001097          	auipc	ra,0x1
    80002fca:	45c080e7          	jalr	1116(ra) # 80004422 <holdingsleep>
    80002fce:	cd01                	beqz	a0,80002fe6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fd0:	4585                	li	a1,1
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	00003097          	auipc	ra,0x3
    80002fd8:	f04080e7          	jalr	-252(ra) # 80005ed8 <virtio_disk_rw>
}
    80002fdc:	60e2                	ld	ra,24(sp)
    80002fde:	6442                	ld	s0,16(sp)
    80002fe0:	64a2                	ld	s1,8(sp)
    80002fe2:	6105                	addi	sp,sp,32
    80002fe4:	8082                	ret
    panic("bwrite");
    80002fe6:	00005517          	auipc	a0,0x5
    80002fea:	5fa50513          	addi	a0,a0,1530 # 800085e0 <syscalls+0xf8>
    80002fee:	ffffd097          	auipc	ra,0xffffd
    80002ff2:	558080e7          	jalr	1368(ra) # 80000546 <panic>

0000000080002ff6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ff6:	1101                	addi	sp,sp,-32
    80002ff8:	ec06                	sd	ra,24(sp)
    80002ffa:	e822                	sd	s0,16(sp)
    80002ffc:	e426                	sd	s1,8(sp)
    80002ffe:	e04a                	sd	s2,0(sp)
    80003000:	1000                	addi	s0,sp,32
    80003002:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003004:	01050913          	addi	s2,a0,16
    80003008:	854a                	mv	a0,s2
    8000300a:	00001097          	auipc	ra,0x1
    8000300e:	418080e7          	jalr	1048(ra) # 80004422 <holdingsleep>
    80003012:	c92d                	beqz	a0,80003084 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003014:	854a                	mv	a0,s2
    80003016:	00001097          	auipc	ra,0x1
    8000301a:	3c8080e7          	jalr	968(ra) # 800043de <releasesleep>

  acquire(&bcache.lock);
    8000301e:	00015517          	auipc	a0,0x15
    80003022:	96250513          	addi	a0,a0,-1694 # 80017980 <bcache>
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	bda080e7          	jalr	-1062(ra) # 80000c00 <acquire>
  b->refcnt--;
    8000302e:	40bc                	lw	a5,64(s1)
    80003030:	37fd                	addiw	a5,a5,-1
    80003032:	0007871b          	sext.w	a4,a5
    80003036:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003038:	eb05                	bnez	a4,80003068 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000303a:	68bc                	ld	a5,80(s1)
    8000303c:	64b8                	ld	a4,72(s1)
    8000303e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003040:	64bc                	ld	a5,72(s1)
    80003042:	68b8                	ld	a4,80(s1)
    80003044:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003046:	0001d797          	auipc	a5,0x1d
    8000304a:	93a78793          	addi	a5,a5,-1734 # 8001f980 <bcache+0x8000>
    8000304e:	2b87b703          	ld	a4,696(a5)
    80003052:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003054:	0001d717          	auipc	a4,0x1d
    80003058:	b9470713          	addi	a4,a4,-1132 # 8001fbe8 <bcache+0x8268>
    8000305c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000305e:	2b87b703          	ld	a4,696(a5)
    80003062:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003064:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003068:	00015517          	auipc	a0,0x15
    8000306c:	91850513          	addi	a0,a0,-1768 # 80017980 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	c44080e7          	jalr	-956(ra) # 80000cb4 <release>
}
    80003078:	60e2                	ld	ra,24(sp)
    8000307a:	6442                	ld	s0,16(sp)
    8000307c:	64a2                	ld	s1,8(sp)
    8000307e:	6902                	ld	s2,0(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret
    panic("brelse");
    80003084:	00005517          	auipc	a0,0x5
    80003088:	56450513          	addi	a0,a0,1380 # 800085e8 <syscalls+0x100>
    8000308c:	ffffd097          	auipc	ra,0xffffd
    80003090:	4ba080e7          	jalr	1210(ra) # 80000546 <panic>

0000000080003094 <bpin>:

void
bpin(struct buf *b) {
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	1000                	addi	s0,sp,32
    8000309e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030a0:	00015517          	auipc	a0,0x15
    800030a4:	8e050513          	addi	a0,a0,-1824 # 80017980 <bcache>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	b58080e7          	jalr	-1192(ra) # 80000c00 <acquire>
  b->refcnt++;
    800030b0:	40bc                	lw	a5,64(s1)
    800030b2:	2785                	addiw	a5,a5,1
    800030b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030b6:	00015517          	auipc	a0,0x15
    800030ba:	8ca50513          	addi	a0,a0,-1846 # 80017980 <bcache>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	bf6080e7          	jalr	-1034(ra) # 80000cb4 <release>
}
    800030c6:	60e2                	ld	ra,24(sp)
    800030c8:	6442                	ld	s0,16(sp)
    800030ca:	64a2                	ld	s1,8(sp)
    800030cc:	6105                	addi	sp,sp,32
    800030ce:	8082                	ret

00000000800030d0 <bunpin>:

void
bunpin(struct buf *b) {
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	e426                	sd	s1,8(sp)
    800030d8:	1000                	addi	s0,sp,32
    800030da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030dc:	00015517          	auipc	a0,0x15
    800030e0:	8a450513          	addi	a0,a0,-1884 # 80017980 <bcache>
    800030e4:	ffffe097          	auipc	ra,0xffffe
    800030e8:	b1c080e7          	jalr	-1252(ra) # 80000c00 <acquire>
  b->refcnt--;
    800030ec:	40bc                	lw	a5,64(s1)
    800030ee:	37fd                	addiw	a5,a5,-1
    800030f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030f2:	00015517          	auipc	a0,0x15
    800030f6:	88e50513          	addi	a0,a0,-1906 # 80017980 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	bba080e7          	jalr	-1094(ra) # 80000cb4 <release>
}
    80003102:	60e2                	ld	ra,24(sp)
    80003104:	6442                	ld	s0,16(sp)
    80003106:	64a2                	ld	s1,8(sp)
    80003108:	6105                	addi	sp,sp,32
    8000310a:	8082                	ret

000000008000310c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000310c:	1101                	addi	sp,sp,-32
    8000310e:	ec06                	sd	ra,24(sp)
    80003110:	e822                	sd	s0,16(sp)
    80003112:	e426                	sd	s1,8(sp)
    80003114:	e04a                	sd	s2,0(sp)
    80003116:	1000                	addi	s0,sp,32
    80003118:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000311a:	00d5d59b          	srliw	a1,a1,0xd
    8000311e:	0001d797          	auipc	a5,0x1d
    80003122:	f3e7a783          	lw	a5,-194(a5) # 8002005c <sb+0x1c>
    80003126:	9dbd                	addw	a1,a1,a5
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	d9e080e7          	jalr	-610(ra) # 80002ec6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003130:	0074f713          	andi	a4,s1,7
    80003134:	4785                	li	a5,1
    80003136:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000313a:	14ce                	slli	s1,s1,0x33
    8000313c:	90d9                	srli	s1,s1,0x36
    8000313e:	00950733          	add	a4,a0,s1
    80003142:	05874703          	lbu	a4,88(a4)
    80003146:	00e7f6b3          	and	a3,a5,a4
    8000314a:	c69d                	beqz	a3,80003178 <bfree+0x6c>
    8000314c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000314e:	94aa                	add	s1,s1,a0
    80003150:	fff7c793          	not	a5,a5
    80003154:	8f7d                	and	a4,a4,a5
    80003156:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	108080e7          	jalr	264(ra) # 80004262 <log_write>
  brelse(bp);
    80003162:	854a                	mv	a0,s2
    80003164:	00000097          	auipc	ra,0x0
    80003168:	e92080e7          	jalr	-366(ra) # 80002ff6 <brelse>
}
    8000316c:	60e2                	ld	ra,24(sp)
    8000316e:	6442                	ld	s0,16(sp)
    80003170:	64a2                	ld	s1,8(sp)
    80003172:	6902                	ld	s2,0(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret
    panic("freeing free block");
    80003178:	00005517          	auipc	a0,0x5
    8000317c:	47850513          	addi	a0,a0,1144 # 800085f0 <syscalls+0x108>
    80003180:	ffffd097          	auipc	ra,0xffffd
    80003184:	3c6080e7          	jalr	966(ra) # 80000546 <panic>

0000000080003188 <balloc>:
{
    80003188:	711d                	addi	sp,sp,-96
    8000318a:	ec86                	sd	ra,88(sp)
    8000318c:	e8a2                	sd	s0,80(sp)
    8000318e:	e4a6                	sd	s1,72(sp)
    80003190:	e0ca                	sd	s2,64(sp)
    80003192:	fc4e                	sd	s3,56(sp)
    80003194:	f852                	sd	s4,48(sp)
    80003196:	f456                	sd	s5,40(sp)
    80003198:	f05a                	sd	s6,32(sp)
    8000319a:	ec5e                	sd	s7,24(sp)
    8000319c:	e862                	sd	s8,16(sp)
    8000319e:	e466                	sd	s9,8(sp)
    800031a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031a2:	0001d797          	auipc	a5,0x1d
    800031a6:	ea27a783          	lw	a5,-350(a5) # 80020044 <sb+0x4>
    800031aa:	cbc1                	beqz	a5,8000323a <balloc+0xb2>
    800031ac:	8baa                	mv	s7,a0
    800031ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031b0:	0001db17          	auipc	s6,0x1d
    800031b4:	e90b0b13          	addi	s6,s6,-368 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031be:	6c89                	lui	s9,0x2
    800031c0:	a831                	j	800031dc <balloc+0x54>
    brelse(bp);
    800031c2:	854a                	mv	a0,s2
    800031c4:	00000097          	auipc	ra,0x0
    800031c8:	e32080e7          	jalr	-462(ra) # 80002ff6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031cc:	015c87bb          	addw	a5,s9,s5
    800031d0:	00078a9b          	sext.w	s5,a5
    800031d4:	004b2703          	lw	a4,4(s6)
    800031d8:	06eaf163          	bgeu	s5,a4,8000323a <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    800031dc:	41fad79b          	sraiw	a5,s5,0x1f
    800031e0:	0137d79b          	srliw	a5,a5,0x13
    800031e4:	015787bb          	addw	a5,a5,s5
    800031e8:	40d7d79b          	sraiw	a5,a5,0xd
    800031ec:	01cb2583          	lw	a1,28(s6)
    800031f0:	9dbd                	addw	a1,a1,a5
    800031f2:	855e                	mv	a0,s7
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	cd2080e7          	jalr	-814(ra) # 80002ec6 <bread>
    800031fc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031fe:	004b2503          	lw	a0,4(s6)
    80003202:	000a849b          	sext.w	s1,s5
    80003206:	8762                	mv	a4,s8
    80003208:	faa4fde3          	bgeu	s1,a0,800031c2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000320c:	00777693          	andi	a3,a4,7
    80003210:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003214:	41f7579b          	sraiw	a5,a4,0x1f
    80003218:	01d7d79b          	srliw	a5,a5,0x1d
    8000321c:	9fb9                	addw	a5,a5,a4
    8000321e:	4037d79b          	sraiw	a5,a5,0x3
    80003222:	00f90633          	add	a2,s2,a5
    80003226:	05864603          	lbu	a2,88(a2)
    8000322a:	00c6f5b3          	and	a1,a3,a2
    8000322e:	cd91                	beqz	a1,8000324a <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003230:	2705                	addiw	a4,a4,1
    80003232:	2485                	addiw	s1,s1,1
    80003234:	fd471ae3          	bne	a4,s4,80003208 <balloc+0x80>
    80003238:	b769                	j	800031c2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000323a:	00005517          	auipc	a0,0x5
    8000323e:	3ce50513          	addi	a0,a0,974 # 80008608 <syscalls+0x120>
    80003242:	ffffd097          	auipc	ra,0xffffd
    80003246:	304080e7          	jalr	772(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000324a:	97ca                	add	a5,a5,s2
    8000324c:	8e55                	or	a2,a2,a3
    8000324e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003252:	854a                	mv	a0,s2
    80003254:	00001097          	auipc	ra,0x1
    80003258:	00e080e7          	jalr	14(ra) # 80004262 <log_write>
        brelse(bp);
    8000325c:	854a                	mv	a0,s2
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	d98080e7          	jalr	-616(ra) # 80002ff6 <brelse>
  bp = bread(dev, bno);
    80003266:	85a6                	mv	a1,s1
    80003268:	855e                	mv	a0,s7
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	c5c080e7          	jalr	-932(ra) # 80002ec6 <bread>
    80003272:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003274:	40000613          	li	a2,1024
    80003278:	4581                	li	a1,0
    8000327a:	05850513          	addi	a0,a0,88
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	a7e080e7          	jalr	-1410(ra) # 80000cfc <memset>
  log_write(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	fda080e7          	jalr	-38(ra) # 80004262 <log_write>
  brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	d64080e7          	jalr	-668(ra) # 80002ff6 <brelse>
}
    8000329a:	8526                	mv	a0,s1
    8000329c:	60e6                	ld	ra,88(sp)
    8000329e:	6446                	ld	s0,80(sp)
    800032a0:	64a6                	ld	s1,72(sp)
    800032a2:	6906                	ld	s2,64(sp)
    800032a4:	79e2                	ld	s3,56(sp)
    800032a6:	7a42                	ld	s4,48(sp)
    800032a8:	7aa2                	ld	s5,40(sp)
    800032aa:	7b02                	ld	s6,32(sp)
    800032ac:	6be2                	ld	s7,24(sp)
    800032ae:	6c42                	ld	s8,16(sp)
    800032b0:	6ca2                	ld	s9,8(sp)
    800032b2:	6125                	addi	sp,sp,96
    800032b4:	8082                	ret

00000000800032b6 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032b6:	7179                	addi	sp,sp,-48
    800032b8:	f406                	sd	ra,40(sp)
    800032ba:	f022                	sd	s0,32(sp)
    800032bc:	ec26                	sd	s1,24(sp)
    800032be:	e84a                	sd	s2,16(sp)
    800032c0:	e44e                	sd	s3,8(sp)
    800032c2:	e052                	sd	s4,0(sp)
    800032c4:	1800                	addi	s0,sp,48
    800032c6:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032c8:	47ad                	li	a5,11
    800032ca:	04b7fe63          	bgeu	a5,a1,80003326 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032ce:	ff45849b          	addiw	s1,a1,-12
    800032d2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032d6:	0ff00793          	li	a5,255
    800032da:	0ae7e463          	bltu	a5,a4,80003382 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032de:	08052583          	lw	a1,128(a0)
    800032e2:	c5b5                	beqz	a1,8000334e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032e4:	00092503          	lw	a0,0(s2)
    800032e8:	00000097          	auipc	ra,0x0
    800032ec:	bde080e7          	jalr	-1058(ra) # 80002ec6 <bread>
    800032f0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032f2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032f6:	02049713          	slli	a4,s1,0x20
    800032fa:	01e75593          	srli	a1,a4,0x1e
    800032fe:	00b784b3          	add	s1,a5,a1
    80003302:	0004a983          	lw	s3,0(s1)
    80003306:	04098e63          	beqz	s3,80003362 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000330a:	8552                	mv	a0,s4
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	cea080e7          	jalr	-790(ra) # 80002ff6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003314:	854e                	mv	a0,s3
    80003316:	70a2                	ld	ra,40(sp)
    80003318:	7402                	ld	s0,32(sp)
    8000331a:	64e2                	ld	s1,24(sp)
    8000331c:	6942                	ld	s2,16(sp)
    8000331e:	69a2                	ld	s3,8(sp)
    80003320:	6a02                	ld	s4,0(sp)
    80003322:	6145                	addi	sp,sp,48
    80003324:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003326:	02059793          	slli	a5,a1,0x20
    8000332a:	01e7d593          	srli	a1,a5,0x1e
    8000332e:	00b504b3          	add	s1,a0,a1
    80003332:	0504a983          	lw	s3,80(s1)
    80003336:	fc099fe3          	bnez	s3,80003314 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000333a:	4108                	lw	a0,0(a0)
    8000333c:	00000097          	auipc	ra,0x0
    80003340:	e4c080e7          	jalr	-436(ra) # 80003188 <balloc>
    80003344:	0005099b          	sext.w	s3,a0
    80003348:	0534a823          	sw	s3,80(s1)
    8000334c:	b7e1                	j	80003314 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000334e:	4108                	lw	a0,0(a0)
    80003350:	00000097          	auipc	ra,0x0
    80003354:	e38080e7          	jalr	-456(ra) # 80003188 <balloc>
    80003358:	0005059b          	sext.w	a1,a0
    8000335c:	08b92023          	sw	a1,128(s2)
    80003360:	b751                	j	800032e4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003362:	00092503          	lw	a0,0(s2)
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	e22080e7          	jalr	-478(ra) # 80003188 <balloc>
    8000336e:	0005099b          	sext.w	s3,a0
    80003372:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003376:	8552                	mv	a0,s4
    80003378:	00001097          	auipc	ra,0x1
    8000337c:	eea080e7          	jalr	-278(ra) # 80004262 <log_write>
    80003380:	b769                	j	8000330a <bmap+0x54>
  panic("bmap: out of range");
    80003382:	00005517          	auipc	a0,0x5
    80003386:	29e50513          	addi	a0,a0,670 # 80008620 <syscalls+0x138>
    8000338a:	ffffd097          	auipc	ra,0xffffd
    8000338e:	1bc080e7          	jalr	444(ra) # 80000546 <panic>

0000000080003392 <iget>:
{
    80003392:	7179                	addi	sp,sp,-48
    80003394:	f406                	sd	ra,40(sp)
    80003396:	f022                	sd	s0,32(sp)
    80003398:	ec26                	sd	s1,24(sp)
    8000339a:	e84a                	sd	s2,16(sp)
    8000339c:	e44e                	sd	s3,8(sp)
    8000339e:	e052                	sd	s4,0(sp)
    800033a0:	1800                	addi	s0,sp,48
    800033a2:	89aa                	mv	s3,a0
    800033a4:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033a6:	0001d517          	auipc	a0,0x1d
    800033aa:	cba50513          	addi	a0,a0,-838 # 80020060 <icache>
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	852080e7          	jalr	-1966(ra) # 80000c00 <acquire>
  empty = 0;
    800033b6:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033b8:	0001d497          	auipc	s1,0x1d
    800033bc:	cc048493          	addi	s1,s1,-832 # 80020078 <icache+0x18>
    800033c0:	0001e697          	auipc	a3,0x1e
    800033c4:	74868693          	addi	a3,a3,1864 # 80021b08 <log>
    800033c8:	a039                	j	800033d6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ca:	02090b63          	beqz	s2,80003400 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033ce:	08848493          	addi	s1,s1,136
    800033d2:	02d48a63          	beq	s1,a3,80003406 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033d6:	449c                	lw	a5,8(s1)
    800033d8:	fef059e3          	blez	a5,800033ca <iget+0x38>
    800033dc:	4098                	lw	a4,0(s1)
    800033de:	ff3716e3          	bne	a4,s3,800033ca <iget+0x38>
    800033e2:	40d8                	lw	a4,4(s1)
    800033e4:	ff4713e3          	bne	a4,s4,800033ca <iget+0x38>
      ip->ref++;
    800033e8:	2785                	addiw	a5,a5,1
    800033ea:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033ec:	0001d517          	auipc	a0,0x1d
    800033f0:	c7450513          	addi	a0,a0,-908 # 80020060 <icache>
    800033f4:	ffffe097          	auipc	ra,0xffffe
    800033f8:	8c0080e7          	jalr	-1856(ra) # 80000cb4 <release>
      return ip;
    800033fc:	8926                	mv	s2,s1
    800033fe:	a03d                	j	8000342c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003400:	f7f9                	bnez	a5,800033ce <iget+0x3c>
    80003402:	8926                	mv	s2,s1
    80003404:	b7e9                	j	800033ce <iget+0x3c>
  if(empty == 0)
    80003406:	02090c63          	beqz	s2,8000343e <iget+0xac>
  ip->dev = dev;
    8000340a:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000340e:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003412:	4785                	li	a5,1
    80003414:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003418:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000341c:	0001d517          	auipc	a0,0x1d
    80003420:	c4450513          	addi	a0,a0,-956 # 80020060 <icache>
    80003424:	ffffe097          	auipc	ra,0xffffe
    80003428:	890080e7          	jalr	-1904(ra) # 80000cb4 <release>
}
    8000342c:	854a                	mv	a0,s2
    8000342e:	70a2                	ld	ra,40(sp)
    80003430:	7402                	ld	s0,32(sp)
    80003432:	64e2                	ld	s1,24(sp)
    80003434:	6942                	ld	s2,16(sp)
    80003436:	69a2                	ld	s3,8(sp)
    80003438:	6a02                	ld	s4,0(sp)
    8000343a:	6145                	addi	sp,sp,48
    8000343c:	8082                	ret
    panic("iget: no inodes");
    8000343e:	00005517          	auipc	a0,0x5
    80003442:	1fa50513          	addi	a0,a0,506 # 80008638 <syscalls+0x150>
    80003446:	ffffd097          	auipc	ra,0xffffd
    8000344a:	100080e7          	jalr	256(ra) # 80000546 <panic>

000000008000344e <fsinit>:
fsinit(int dev) {
    8000344e:	7179                	addi	sp,sp,-48
    80003450:	f406                	sd	ra,40(sp)
    80003452:	f022                	sd	s0,32(sp)
    80003454:	ec26                	sd	s1,24(sp)
    80003456:	e84a                	sd	s2,16(sp)
    80003458:	e44e                	sd	s3,8(sp)
    8000345a:	1800                	addi	s0,sp,48
    8000345c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000345e:	4585                	li	a1,1
    80003460:	00000097          	auipc	ra,0x0
    80003464:	a66080e7          	jalr	-1434(ra) # 80002ec6 <bread>
    80003468:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000346a:	0001d997          	auipc	s3,0x1d
    8000346e:	bd698993          	addi	s3,s3,-1066 # 80020040 <sb>
    80003472:	02000613          	li	a2,32
    80003476:	05850593          	addi	a1,a0,88
    8000347a:	854e                	mv	a0,s3
    8000347c:	ffffe097          	auipc	ra,0xffffe
    80003480:	8dc080e7          	jalr	-1828(ra) # 80000d58 <memmove>
  brelse(bp);
    80003484:	8526                	mv	a0,s1
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	b70080e7          	jalr	-1168(ra) # 80002ff6 <brelse>
  if(sb.magic != FSMAGIC)
    8000348e:	0009a703          	lw	a4,0(s3)
    80003492:	102037b7          	lui	a5,0x10203
    80003496:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000349a:	02f71263          	bne	a4,a5,800034be <fsinit+0x70>
  initlog(dev, &sb);
    8000349e:	0001d597          	auipc	a1,0x1d
    800034a2:	ba258593          	addi	a1,a1,-1118 # 80020040 <sb>
    800034a6:	854a                	mv	a0,s2
    800034a8:	00001097          	auipc	ra,0x1
    800034ac:	b42080e7          	jalr	-1214(ra) # 80003fea <initlog>
}
    800034b0:	70a2                	ld	ra,40(sp)
    800034b2:	7402                	ld	s0,32(sp)
    800034b4:	64e2                	ld	s1,24(sp)
    800034b6:	6942                	ld	s2,16(sp)
    800034b8:	69a2                	ld	s3,8(sp)
    800034ba:	6145                	addi	sp,sp,48
    800034bc:	8082                	ret
    panic("invalid file system");
    800034be:	00005517          	auipc	a0,0x5
    800034c2:	18a50513          	addi	a0,a0,394 # 80008648 <syscalls+0x160>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	080080e7          	jalr	128(ra) # 80000546 <panic>

00000000800034ce <iinit>:
{
    800034ce:	7179                	addi	sp,sp,-48
    800034d0:	f406                	sd	ra,40(sp)
    800034d2:	f022                	sd	s0,32(sp)
    800034d4:	ec26                	sd	s1,24(sp)
    800034d6:	e84a                	sd	s2,16(sp)
    800034d8:	e44e                	sd	s3,8(sp)
    800034da:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034dc:	00005597          	auipc	a1,0x5
    800034e0:	18458593          	addi	a1,a1,388 # 80008660 <syscalls+0x178>
    800034e4:	0001d517          	auipc	a0,0x1d
    800034e8:	b7c50513          	addi	a0,a0,-1156 # 80020060 <icache>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	684080e7          	jalr	1668(ra) # 80000b70 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034f4:	0001d497          	auipc	s1,0x1d
    800034f8:	b9448493          	addi	s1,s1,-1132 # 80020088 <icache+0x28>
    800034fc:	0001e997          	auipc	s3,0x1e
    80003500:	61c98993          	addi	s3,s3,1564 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003504:	00005917          	auipc	s2,0x5
    80003508:	16490913          	addi	s2,s2,356 # 80008668 <syscalls+0x180>
    8000350c:	85ca                	mv	a1,s2
    8000350e:	8526                	mv	a0,s1
    80003510:	00001097          	auipc	ra,0x1
    80003514:	e3e080e7          	jalr	-450(ra) # 8000434e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003518:	08848493          	addi	s1,s1,136
    8000351c:	ff3498e3          	bne	s1,s3,8000350c <iinit+0x3e>
}
    80003520:	70a2                	ld	ra,40(sp)
    80003522:	7402                	ld	s0,32(sp)
    80003524:	64e2                	ld	s1,24(sp)
    80003526:	6942                	ld	s2,16(sp)
    80003528:	69a2                	ld	s3,8(sp)
    8000352a:	6145                	addi	sp,sp,48
    8000352c:	8082                	ret

000000008000352e <ialloc>:
{
    8000352e:	715d                	addi	sp,sp,-80
    80003530:	e486                	sd	ra,72(sp)
    80003532:	e0a2                	sd	s0,64(sp)
    80003534:	fc26                	sd	s1,56(sp)
    80003536:	f84a                	sd	s2,48(sp)
    80003538:	f44e                	sd	s3,40(sp)
    8000353a:	f052                	sd	s4,32(sp)
    8000353c:	ec56                	sd	s5,24(sp)
    8000353e:	e85a                	sd	s6,16(sp)
    80003540:	e45e                	sd	s7,8(sp)
    80003542:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003544:	0001d717          	auipc	a4,0x1d
    80003548:	b0872703          	lw	a4,-1272(a4) # 8002004c <sb+0xc>
    8000354c:	4785                	li	a5,1
    8000354e:	04e7fa63          	bgeu	a5,a4,800035a2 <ialloc+0x74>
    80003552:	8aaa                	mv	s5,a0
    80003554:	8bae                	mv	s7,a1
    80003556:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003558:	0001da17          	auipc	s4,0x1d
    8000355c:	ae8a0a13          	addi	s4,s4,-1304 # 80020040 <sb>
    80003560:	00048b1b          	sext.w	s6,s1
    80003564:	0044d593          	srli	a1,s1,0x4
    80003568:	018a2783          	lw	a5,24(s4)
    8000356c:	9dbd                	addw	a1,a1,a5
    8000356e:	8556                	mv	a0,s5
    80003570:	00000097          	auipc	ra,0x0
    80003574:	956080e7          	jalr	-1706(ra) # 80002ec6 <bread>
    80003578:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000357a:	05850993          	addi	s3,a0,88
    8000357e:	00f4f793          	andi	a5,s1,15
    80003582:	079a                	slli	a5,a5,0x6
    80003584:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003586:	00099783          	lh	a5,0(s3)
    8000358a:	c785                	beqz	a5,800035b2 <ialloc+0x84>
    brelse(bp);
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	a6a080e7          	jalr	-1430(ra) # 80002ff6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003594:	0485                	addi	s1,s1,1
    80003596:	00ca2703          	lw	a4,12(s4)
    8000359a:	0004879b          	sext.w	a5,s1
    8000359e:	fce7e1e3          	bltu	a5,a4,80003560 <ialloc+0x32>
  panic("ialloc: no inodes");
    800035a2:	00005517          	auipc	a0,0x5
    800035a6:	0ce50513          	addi	a0,a0,206 # 80008670 <syscalls+0x188>
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	f9c080e7          	jalr	-100(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    800035b2:	04000613          	li	a2,64
    800035b6:	4581                	li	a1,0
    800035b8:	854e                	mv	a0,s3
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	742080e7          	jalr	1858(ra) # 80000cfc <memset>
      dip->type = type;
    800035c2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035c6:	854a                	mv	a0,s2
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	c9a080e7          	jalr	-870(ra) # 80004262 <log_write>
      brelse(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	a24080e7          	jalr	-1500(ra) # 80002ff6 <brelse>
      return iget(dev, inum);
    800035da:	85da                	mv	a1,s6
    800035dc:	8556                	mv	a0,s5
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	db4080e7          	jalr	-588(ra) # 80003392 <iget>
}
    800035e6:	60a6                	ld	ra,72(sp)
    800035e8:	6406                	ld	s0,64(sp)
    800035ea:	74e2                	ld	s1,56(sp)
    800035ec:	7942                	ld	s2,48(sp)
    800035ee:	79a2                	ld	s3,40(sp)
    800035f0:	7a02                	ld	s4,32(sp)
    800035f2:	6ae2                	ld	s5,24(sp)
    800035f4:	6b42                	ld	s6,16(sp)
    800035f6:	6ba2                	ld	s7,8(sp)
    800035f8:	6161                	addi	sp,sp,80
    800035fa:	8082                	ret

00000000800035fc <iupdate>:
{
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	e04a                	sd	s2,0(sp)
    80003606:	1000                	addi	s0,sp,32
    80003608:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000360a:	415c                	lw	a5,4(a0)
    8000360c:	0047d79b          	srliw	a5,a5,0x4
    80003610:	0001d597          	auipc	a1,0x1d
    80003614:	a485a583          	lw	a1,-1464(a1) # 80020058 <sb+0x18>
    80003618:	9dbd                	addw	a1,a1,a5
    8000361a:	4108                	lw	a0,0(a0)
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	8aa080e7          	jalr	-1878(ra) # 80002ec6 <bread>
    80003624:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003626:	05850793          	addi	a5,a0,88
    8000362a:	40d8                	lw	a4,4(s1)
    8000362c:	8b3d                	andi	a4,a4,15
    8000362e:	071a                	slli	a4,a4,0x6
    80003630:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003632:	04449703          	lh	a4,68(s1)
    80003636:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000363a:	04649703          	lh	a4,70(s1)
    8000363e:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003642:	04849703          	lh	a4,72(s1)
    80003646:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000364a:	04a49703          	lh	a4,74(s1)
    8000364e:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003652:	44f8                	lw	a4,76(s1)
    80003654:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003656:	03400613          	li	a2,52
    8000365a:	05048593          	addi	a1,s1,80
    8000365e:	00c78513          	addi	a0,a5,12
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	6f6080e7          	jalr	1782(ra) # 80000d58 <memmove>
  log_write(bp);
    8000366a:	854a                	mv	a0,s2
    8000366c:	00001097          	auipc	ra,0x1
    80003670:	bf6080e7          	jalr	-1034(ra) # 80004262 <log_write>
  brelse(bp);
    80003674:	854a                	mv	a0,s2
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	980080e7          	jalr	-1664(ra) # 80002ff6 <brelse>
}
    8000367e:	60e2                	ld	ra,24(sp)
    80003680:	6442                	ld	s0,16(sp)
    80003682:	64a2                	ld	s1,8(sp)
    80003684:	6902                	ld	s2,0(sp)
    80003686:	6105                	addi	sp,sp,32
    80003688:	8082                	ret

000000008000368a <idup>:
{
    8000368a:	1101                	addi	sp,sp,-32
    8000368c:	ec06                	sd	ra,24(sp)
    8000368e:	e822                	sd	s0,16(sp)
    80003690:	e426                	sd	s1,8(sp)
    80003692:	1000                	addi	s0,sp,32
    80003694:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003696:	0001d517          	auipc	a0,0x1d
    8000369a:	9ca50513          	addi	a0,a0,-1590 # 80020060 <icache>
    8000369e:	ffffd097          	auipc	ra,0xffffd
    800036a2:	562080e7          	jalr	1378(ra) # 80000c00 <acquire>
  ip->ref++;
    800036a6:	449c                	lw	a5,8(s1)
    800036a8:	2785                	addiw	a5,a5,1
    800036aa:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036ac:	0001d517          	auipc	a0,0x1d
    800036b0:	9b450513          	addi	a0,a0,-1612 # 80020060 <icache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	600080e7          	jalr	1536(ra) # 80000cb4 <release>
}
    800036bc:	8526                	mv	a0,s1
    800036be:	60e2                	ld	ra,24(sp)
    800036c0:	6442                	ld	s0,16(sp)
    800036c2:	64a2                	ld	s1,8(sp)
    800036c4:	6105                	addi	sp,sp,32
    800036c6:	8082                	ret

00000000800036c8 <ilock>:
{
    800036c8:	1101                	addi	sp,sp,-32
    800036ca:	ec06                	sd	ra,24(sp)
    800036cc:	e822                	sd	s0,16(sp)
    800036ce:	e426                	sd	s1,8(sp)
    800036d0:	e04a                	sd	s2,0(sp)
    800036d2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036d4:	c115                	beqz	a0,800036f8 <ilock+0x30>
    800036d6:	84aa                	mv	s1,a0
    800036d8:	451c                	lw	a5,8(a0)
    800036da:	00f05f63          	blez	a5,800036f8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036de:	0541                	addi	a0,a0,16
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	ca8080e7          	jalr	-856(ra) # 80004388 <acquiresleep>
  if(ip->valid == 0){
    800036e8:	40bc                	lw	a5,64(s1)
    800036ea:	cf99                	beqz	a5,80003708 <ilock+0x40>
}
    800036ec:	60e2                	ld	ra,24(sp)
    800036ee:	6442                	ld	s0,16(sp)
    800036f0:	64a2                	ld	s1,8(sp)
    800036f2:	6902                	ld	s2,0(sp)
    800036f4:	6105                	addi	sp,sp,32
    800036f6:	8082                	ret
    panic("ilock");
    800036f8:	00005517          	auipc	a0,0x5
    800036fc:	f9050513          	addi	a0,a0,-112 # 80008688 <syscalls+0x1a0>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	e46080e7          	jalr	-442(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003708:	40dc                	lw	a5,4(s1)
    8000370a:	0047d79b          	srliw	a5,a5,0x4
    8000370e:	0001d597          	auipc	a1,0x1d
    80003712:	94a5a583          	lw	a1,-1718(a1) # 80020058 <sb+0x18>
    80003716:	9dbd                	addw	a1,a1,a5
    80003718:	4088                	lw	a0,0(s1)
    8000371a:	fffff097          	auipc	ra,0xfffff
    8000371e:	7ac080e7          	jalr	1964(ra) # 80002ec6 <bread>
    80003722:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003724:	05850593          	addi	a1,a0,88
    80003728:	40dc                	lw	a5,4(s1)
    8000372a:	8bbd                	andi	a5,a5,15
    8000372c:	079a                	slli	a5,a5,0x6
    8000372e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003730:	00059783          	lh	a5,0(a1)
    80003734:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003738:	00259783          	lh	a5,2(a1)
    8000373c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003740:	00459783          	lh	a5,4(a1)
    80003744:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003748:	00659783          	lh	a5,6(a1)
    8000374c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003750:	459c                	lw	a5,8(a1)
    80003752:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003754:	03400613          	li	a2,52
    80003758:	05b1                	addi	a1,a1,12
    8000375a:	05048513          	addi	a0,s1,80
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	5fa080e7          	jalr	1530(ra) # 80000d58 <memmove>
    brelse(bp);
    80003766:	854a                	mv	a0,s2
    80003768:	00000097          	auipc	ra,0x0
    8000376c:	88e080e7          	jalr	-1906(ra) # 80002ff6 <brelse>
    ip->valid = 1;
    80003770:	4785                	li	a5,1
    80003772:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003774:	04449783          	lh	a5,68(s1)
    80003778:	fbb5                	bnez	a5,800036ec <ilock+0x24>
      panic("ilock: no type");
    8000377a:	00005517          	auipc	a0,0x5
    8000377e:	f1650513          	addi	a0,a0,-234 # 80008690 <syscalls+0x1a8>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	dc4080e7          	jalr	-572(ra) # 80000546 <panic>

000000008000378a <iunlock>:
{
    8000378a:	1101                	addi	sp,sp,-32
    8000378c:	ec06                	sd	ra,24(sp)
    8000378e:	e822                	sd	s0,16(sp)
    80003790:	e426                	sd	s1,8(sp)
    80003792:	e04a                	sd	s2,0(sp)
    80003794:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003796:	c905                	beqz	a0,800037c6 <iunlock+0x3c>
    80003798:	84aa                	mv	s1,a0
    8000379a:	01050913          	addi	s2,a0,16
    8000379e:	854a                	mv	a0,s2
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	c82080e7          	jalr	-894(ra) # 80004422 <holdingsleep>
    800037a8:	cd19                	beqz	a0,800037c6 <iunlock+0x3c>
    800037aa:	449c                	lw	a5,8(s1)
    800037ac:	00f05d63          	blez	a5,800037c6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037b0:	854a                	mv	a0,s2
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	c2c080e7          	jalr	-980(ra) # 800043de <releasesleep>
}
    800037ba:	60e2                	ld	ra,24(sp)
    800037bc:	6442                	ld	s0,16(sp)
    800037be:	64a2                	ld	s1,8(sp)
    800037c0:	6902                	ld	s2,0(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret
    panic("iunlock");
    800037c6:	00005517          	auipc	a0,0x5
    800037ca:	eda50513          	addi	a0,a0,-294 # 800086a0 <syscalls+0x1b8>
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	d78080e7          	jalr	-648(ra) # 80000546 <panic>

00000000800037d6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037d6:	7179                	addi	sp,sp,-48
    800037d8:	f406                	sd	ra,40(sp)
    800037da:	f022                	sd	s0,32(sp)
    800037dc:	ec26                	sd	s1,24(sp)
    800037de:	e84a                	sd	s2,16(sp)
    800037e0:	e44e                	sd	s3,8(sp)
    800037e2:	e052                	sd	s4,0(sp)
    800037e4:	1800                	addi	s0,sp,48
    800037e6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037e8:	05050493          	addi	s1,a0,80
    800037ec:	08050913          	addi	s2,a0,128
    800037f0:	a021                	j	800037f8 <itrunc+0x22>
    800037f2:	0491                	addi	s1,s1,4
    800037f4:	01248d63          	beq	s1,s2,8000380e <itrunc+0x38>
    if(ip->addrs[i]){
    800037f8:	408c                	lw	a1,0(s1)
    800037fa:	dde5                	beqz	a1,800037f2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037fc:	0009a503          	lw	a0,0(s3)
    80003800:	00000097          	auipc	ra,0x0
    80003804:	90c080e7          	jalr	-1780(ra) # 8000310c <bfree>
      ip->addrs[i] = 0;
    80003808:	0004a023          	sw	zero,0(s1)
    8000380c:	b7dd                	j	800037f2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000380e:	0809a583          	lw	a1,128(s3)
    80003812:	e185                	bnez	a1,80003832 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003814:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003818:	854e                	mv	a0,s3
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	de2080e7          	jalr	-542(ra) # 800035fc <iupdate>
}
    80003822:	70a2                	ld	ra,40(sp)
    80003824:	7402                	ld	s0,32(sp)
    80003826:	64e2                	ld	s1,24(sp)
    80003828:	6942                	ld	s2,16(sp)
    8000382a:	69a2                	ld	s3,8(sp)
    8000382c:	6a02                	ld	s4,0(sp)
    8000382e:	6145                	addi	sp,sp,48
    80003830:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003832:	0009a503          	lw	a0,0(s3)
    80003836:	fffff097          	auipc	ra,0xfffff
    8000383a:	690080e7          	jalr	1680(ra) # 80002ec6 <bread>
    8000383e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003840:	05850493          	addi	s1,a0,88
    80003844:	45850913          	addi	s2,a0,1112
    80003848:	a021                	j	80003850 <itrunc+0x7a>
    8000384a:	0491                	addi	s1,s1,4
    8000384c:	01248b63          	beq	s1,s2,80003862 <itrunc+0x8c>
      if(a[j])
    80003850:	408c                	lw	a1,0(s1)
    80003852:	dde5                	beqz	a1,8000384a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003854:	0009a503          	lw	a0,0(s3)
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	8b4080e7          	jalr	-1868(ra) # 8000310c <bfree>
    80003860:	b7ed                	j	8000384a <itrunc+0x74>
    brelse(bp);
    80003862:	8552                	mv	a0,s4
    80003864:	fffff097          	auipc	ra,0xfffff
    80003868:	792080e7          	jalr	1938(ra) # 80002ff6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000386c:	0809a583          	lw	a1,128(s3)
    80003870:	0009a503          	lw	a0,0(s3)
    80003874:	00000097          	auipc	ra,0x0
    80003878:	898080e7          	jalr	-1896(ra) # 8000310c <bfree>
    ip->addrs[NDIRECT] = 0;
    8000387c:	0809a023          	sw	zero,128(s3)
    80003880:	bf51                	j	80003814 <itrunc+0x3e>

0000000080003882 <iput>:
{
    80003882:	1101                	addi	sp,sp,-32
    80003884:	ec06                	sd	ra,24(sp)
    80003886:	e822                	sd	s0,16(sp)
    80003888:	e426                	sd	s1,8(sp)
    8000388a:	e04a                	sd	s2,0(sp)
    8000388c:	1000                	addi	s0,sp,32
    8000388e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003890:	0001c517          	auipc	a0,0x1c
    80003894:	7d050513          	addi	a0,a0,2000 # 80020060 <icache>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	368080e7          	jalr	872(ra) # 80000c00 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038a0:	4498                	lw	a4,8(s1)
    800038a2:	4785                	li	a5,1
    800038a4:	02f70363          	beq	a4,a5,800038ca <iput+0x48>
  ip->ref--;
    800038a8:	449c                	lw	a5,8(s1)
    800038aa:	37fd                	addiw	a5,a5,-1
    800038ac:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038ae:	0001c517          	auipc	a0,0x1c
    800038b2:	7b250513          	addi	a0,a0,1970 # 80020060 <icache>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	3fe080e7          	jalr	1022(ra) # 80000cb4 <release>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	64a2                	ld	s1,8(sp)
    800038c4:	6902                	ld	s2,0(sp)
    800038c6:	6105                	addi	sp,sp,32
    800038c8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038ca:	40bc                	lw	a5,64(s1)
    800038cc:	dff1                	beqz	a5,800038a8 <iput+0x26>
    800038ce:	04a49783          	lh	a5,74(s1)
    800038d2:	fbf9                	bnez	a5,800038a8 <iput+0x26>
    acquiresleep(&ip->lock);
    800038d4:	01048913          	addi	s2,s1,16
    800038d8:	854a                	mv	a0,s2
    800038da:	00001097          	auipc	ra,0x1
    800038de:	aae080e7          	jalr	-1362(ra) # 80004388 <acquiresleep>
    release(&icache.lock);
    800038e2:	0001c517          	auipc	a0,0x1c
    800038e6:	77e50513          	addi	a0,a0,1918 # 80020060 <icache>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	3ca080e7          	jalr	970(ra) # 80000cb4 <release>
    itrunc(ip);
    800038f2:	8526                	mv	a0,s1
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	ee2080e7          	jalr	-286(ra) # 800037d6 <itrunc>
    ip->type = 0;
    800038fc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003900:	8526                	mv	a0,s1
    80003902:	00000097          	auipc	ra,0x0
    80003906:	cfa080e7          	jalr	-774(ra) # 800035fc <iupdate>
    ip->valid = 0;
    8000390a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000390e:	854a                	mv	a0,s2
    80003910:	00001097          	auipc	ra,0x1
    80003914:	ace080e7          	jalr	-1330(ra) # 800043de <releasesleep>
    acquire(&icache.lock);
    80003918:	0001c517          	auipc	a0,0x1c
    8000391c:	74850513          	addi	a0,a0,1864 # 80020060 <icache>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	2e0080e7          	jalr	736(ra) # 80000c00 <acquire>
    80003928:	b741                	j	800038a8 <iput+0x26>

000000008000392a <iunlockput>:
{
    8000392a:	1101                	addi	sp,sp,-32
    8000392c:	ec06                	sd	ra,24(sp)
    8000392e:	e822                	sd	s0,16(sp)
    80003930:	e426                	sd	s1,8(sp)
    80003932:	1000                	addi	s0,sp,32
    80003934:	84aa                	mv	s1,a0
  iunlock(ip);
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	e54080e7          	jalr	-428(ra) # 8000378a <iunlock>
  iput(ip);
    8000393e:	8526                	mv	a0,s1
    80003940:	00000097          	auipc	ra,0x0
    80003944:	f42080e7          	jalr	-190(ra) # 80003882 <iput>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6105                	addi	sp,sp,32
    80003950:	8082                	ret

0000000080003952 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003952:	1141                	addi	sp,sp,-16
    80003954:	e422                	sd	s0,8(sp)
    80003956:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003958:	411c                	lw	a5,0(a0)
    8000395a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000395c:	415c                	lw	a5,4(a0)
    8000395e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003960:	04451783          	lh	a5,68(a0)
    80003964:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003968:	04a51783          	lh	a5,74(a0)
    8000396c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003970:	04c56783          	lwu	a5,76(a0)
    80003974:	e99c                	sd	a5,16(a1)
}
    80003976:	6422                	ld	s0,8(sp)
    80003978:	0141                	addi	sp,sp,16
    8000397a:	8082                	ret

000000008000397c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000397c:	457c                	lw	a5,76(a0)
    8000397e:	0ed7e863          	bltu	a5,a3,80003a6e <readi+0xf2>
{
    80003982:	7159                	addi	sp,sp,-112
    80003984:	f486                	sd	ra,104(sp)
    80003986:	f0a2                	sd	s0,96(sp)
    80003988:	eca6                	sd	s1,88(sp)
    8000398a:	e8ca                	sd	s2,80(sp)
    8000398c:	e4ce                	sd	s3,72(sp)
    8000398e:	e0d2                	sd	s4,64(sp)
    80003990:	fc56                	sd	s5,56(sp)
    80003992:	f85a                	sd	s6,48(sp)
    80003994:	f45e                	sd	s7,40(sp)
    80003996:	f062                	sd	s8,32(sp)
    80003998:	ec66                	sd	s9,24(sp)
    8000399a:	e86a                	sd	s10,16(sp)
    8000399c:	e46e                	sd	s11,8(sp)
    8000399e:	1880                	addi	s0,sp,112
    800039a0:	8baa                	mv	s7,a0
    800039a2:	8c2e                	mv	s8,a1
    800039a4:	8ab2                	mv	s5,a2
    800039a6:	84b6                	mv	s1,a3
    800039a8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039aa:	9f35                	addw	a4,a4,a3
    return 0;
    800039ac:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039ae:	08d76f63          	bltu	a4,a3,80003a4c <readi+0xd0>
  if(off + n > ip->size)
    800039b2:	00e7f463          	bgeu	a5,a4,800039ba <readi+0x3e>
    n = ip->size - off;
    800039b6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ba:	0a0b0863          	beqz	s6,80003a6a <readi+0xee>
    800039be:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039c0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039c4:	5cfd                	li	s9,-1
    800039c6:	a82d                	j	80003a00 <readi+0x84>
    800039c8:	020a1d93          	slli	s11,s4,0x20
    800039cc:	020ddd93          	srli	s11,s11,0x20
    800039d0:	05890613          	addi	a2,s2,88
    800039d4:	86ee                	mv	a3,s11
    800039d6:	963a                	add	a2,a2,a4
    800039d8:	85d6                	mv	a1,s5
    800039da:	8562                	mv	a0,s8
    800039dc:	fffff097          	auipc	ra,0xfffff
    800039e0:	a8a080e7          	jalr	-1398(ra) # 80002466 <either_copyout>
    800039e4:	05950d63          	beq	a0,s9,80003a3e <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039e8:	854a                	mv	a0,s2
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	60c080e7          	jalr	1548(ra) # 80002ff6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039f2:	013a09bb          	addw	s3,s4,s3
    800039f6:	009a04bb          	addw	s1,s4,s1
    800039fa:	9aee                	add	s5,s5,s11
    800039fc:	0569f663          	bgeu	s3,s6,80003a48 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a00:	000ba903          	lw	s2,0(s7)
    80003a04:	00a4d59b          	srliw	a1,s1,0xa
    80003a08:	855e                	mv	a0,s7
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	8ac080e7          	jalr	-1876(ra) # 800032b6 <bmap>
    80003a12:	0005059b          	sext.w	a1,a0
    80003a16:	854a                	mv	a0,s2
    80003a18:	fffff097          	auipc	ra,0xfffff
    80003a1c:	4ae080e7          	jalr	1198(ra) # 80002ec6 <bread>
    80003a20:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a22:	3ff4f713          	andi	a4,s1,1023
    80003a26:	40ed07bb          	subw	a5,s10,a4
    80003a2a:	413b06bb          	subw	a3,s6,s3
    80003a2e:	8a3e                	mv	s4,a5
    80003a30:	2781                	sext.w	a5,a5
    80003a32:	0006861b          	sext.w	a2,a3
    80003a36:	f8f679e3          	bgeu	a2,a5,800039c8 <readi+0x4c>
    80003a3a:	8a36                	mv	s4,a3
    80003a3c:	b771                	j	800039c8 <readi+0x4c>
      brelse(bp);
    80003a3e:	854a                	mv	a0,s2
    80003a40:	fffff097          	auipc	ra,0xfffff
    80003a44:	5b6080e7          	jalr	1462(ra) # 80002ff6 <brelse>
  }
  return tot;
    80003a48:	0009851b          	sext.w	a0,s3
}
    80003a4c:	70a6                	ld	ra,104(sp)
    80003a4e:	7406                	ld	s0,96(sp)
    80003a50:	64e6                	ld	s1,88(sp)
    80003a52:	6946                	ld	s2,80(sp)
    80003a54:	69a6                	ld	s3,72(sp)
    80003a56:	6a06                	ld	s4,64(sp)
    80003a58:	7ae2                	ld	s5,56(sp)
    80003a5a:	7b42                	ld	s6,48(sp)
    80003a5c:	7ba2                	ld	s7,40(sp)
    80003a5e:	7c02                	ld	s8,32(sp)
    80003a60:	6ce2                	ld	s9,24(sp)
    80003a62:	6d42                	ld	s10,16(sp)
    80003a64:	6da2                	ld	s11,8(sp)
    80003a66:	6165                	addi	sp,sp,112
    80003a68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a6a:	89da                	mv	s3,s6
    80003a6c:	bff1                	j	80003a48 <readi+0xcc>
    return 0;
    80003a6e:	4501                	li	a0,0
}
    80003a70:	8082                	ret

0000000080003a72 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a72:	457c                	lw	a5,76(a0)
    80003a74:	10d7e663          	bltu	a5,a3,80003b80 <writei+0x10e>
{
    80003a78:	7159                	addi	sp,sp,-112
    80003a7a:	f486                	sd	ra,104(sp)
    80003a7c:	f0a2                	sd	s0,96(sp)
    80003a7e:	eca6                	sd	s1,88(sp)
    80003a80:	e8ca                	sd	s2,80(sp)
    80003a82:	e4ce                	sd	s3,72(sp)
    80003a84:	e0d2                	sd	s4,64(sp)
    80003a86:	fc56                	sd	s5,56(sp)
    80003a88:	f85a                	sd	s6,48(sp)
    80003a8a:	f45e                	sd	s7,40(sp)
    80003a8c:	f062                	sd	s8,32(sp)
    80003a8e:	ec66                	sd	s9,24(sp)
    80003a90:	e86a                	sd	s10,16(sp)
    80003a92:	e46e                	sd	s11,8(sp)
    80003a94:	1880                	addi	s0,sp,112
    80003a96:	8baa                	mv	s7,a0
    80003a98:	8c2e                	mv	s8,a1
    80003a9a:	8ab2                	mv	s5,a2
    80003a9c:	8936                	mv	s2,a3
    80003a9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aa0:	00e687bb          	addw	a5,a3,a4
    80003aa4:	0ed7e063          	bltu	a5,a3,80003b84 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aa8:	00043737          	lui	a4,0x43
    80003aac:	0cf76e63          	bltu	a4,a5,80003b88 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ab0:	0a0b0763          	beqz	s6,80003b5e <writei+0xec>
    80003ab4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003aba:	5cfd                	li	s9,-1
    80003abc:	a091                	j	80003b00 <writei+0x8e>
    80003abe:	02099d93          	slli	s11,s3,0x20
    80003ac2:	020ddd93          	srli	s11,s11,0x20
    80003ac6:	05848513          	addi	a0,s1,88
    80003aca:	86ee                	mv	a3,s11
    80003acc:	8656                	mv	a2,s5
    80003ace:	85e2                	mv	a1,s8
    80003ad0:	953a                	add	a0,a0,a4
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	9ea080e7          	jalr	-1558(ra) # 800024bc <either_copyin>
    80003ada:	07950263          	beq	a0,s9,80003b3e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ade:	8526                	mv	a0,s1
    80003ae0:	00000097          	auipc	ra,0x0
    80003ae4:	782080e7          	jalr	1922(ra) # 80004262 <log_write>
    brelse(bp);
    80003ae8:	8526                	mv	a0,s1
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	50c080e7          	jalr	1292(ra) # 80002ff6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003af2:	01498a3b          	addw	s4,s3,s4
    80003af6:	0129893b          	addw	s2,s3,s2
    80003afa:	9aee                	add	s5,s5,s11
    80003afc:	056a7663          	bgeu	s4,s6,80003b48 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b00:	000ba483          	lw	s1,0(s7)
    80003b04:	00a9559b          	srliw	a1,s2,0xa
    80003b08:	855e                	mv	a0,s7
    80003b0a:	fffff097          	auipc	ra,0xfffff
    80003b0e:	7ac080e7          	jalr	1964(ra) # 800032b6 <bmap>
    80003b12:	0005059b          	sext.w	a1,a0
    80003b16:	8526                	mv	a0,s1
    80003b18:	fffff097          	auipc	ra,0xfffff
    80003b1c:	3ae080e7          	jalr	942(ra) # 80002ec6 <bread>
    80003b20:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b22:	3ff97713          	andi	a4,s2,1023
    80003b26:	40ed07bb          	subw	a5,s10,a4
    80003b2a:	414b06bb          	subw	a3,s6,s4
    80003b2e:	89be                	mv	s3,a5
    80003b30:	2781                	sext.w	a5,a5
    80003b32:	0006861b          	sext.w	a2,a3
    80003b36:	f8f674e3          	bgeu	a2,a5,80003abe <writei+0x4c>
    80003b3a:	89b6                	mv	s3,a3
    80003b3c:	b749                	j	80003abe <writei+0x4c>
      brelse(bp);
    80003b3e:	8526                	mv	a0,s1
    80003b40:	fffff097          	auipc	ra,0xfffff
    80003b44:	4b6080e7          	jalr	1206(ra) # 80002ff6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b48:	04cba783          	lw	a5,76(s7)
    80003b4c:	0127f463          	bgeu	a5,s2,80003b54 <writei+0xe2>
      ip->size = off;
    80003b50:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b54:	855e                	mv	a0,s7
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	aa6080e7          	jalr	-1370(ra) # 800035fc <iupdate>
  }

  return n;
    80003b5e:	000b051b          	sext.w	a0,s6
}
    80003b62:	70a6                	ld	ra,104(sp)
    80003b64:	7406                	ld	s0,96(sp)
    80003b66:	64e6                	ld	s1,88(sp)
    80003b68:	6946                	ld	s2,80(sp)
    80003b6a:	69a6                	ld	s3,72(sp)
    80003b6c:	6a06                	ld	s4,64(sp)
    80003b6e:	7ae2                	ld	s5,56(sp)
    80003b70:	7b42                	ld	s6,48(sp)
    80003b72:	7ba2                	ld	s7,40(sp)
    80003b74:	7c02                	ld	s8,32(sp)
    80003b76:	6ce2                	ld	s9,24(sp)
    80003b78:	6d42                	ld	s10,16(sp)
    80003b7a:	6da2                	ld	s11,8(sp)
    80003b7c:	6165                	addi	sp,sp,112
    80003b7e:	8082                	ret
    return -1;
    80003b80:	557d                	li	a0,-1
}
    80003b82:	8082                	ret
    return -1;
    80003b84:	557d                	li	a0,-1
    80003b86:	bff1                	j	80003b62 <writei+0xf0>
    return -1;
    80003b88:	557d                	li	a0,-1
    80003b8a:	bfe1                	j	80003b62 <writei+0xf0>

0000000080003b8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b8c:	1141                	addi	sp,sp,-16
    80003b8e:	e406                	sd	ra,8(sp)
    80003b90:	e022                	sd	s0,0(sp)
    80003b92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b94:	4639                	li	a2,14
    80003b96:	ffffd097          	auipc	ra,0xffffd
    80003b9a:	23e080e7          	jalr	574(ra) # 80000dd4 <strncmp>
}
    80003b9e:	60a2                	ld	ra,8(sp)
    80003ba0:	6402                	ld	s0,0(sp)
    80003ba2:	0141                	addi	sp,sp,16
    80003ba4:	8082                	ret

0000000080003ba6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ba6:	7139                	addi	sp,sp,-64
    80003ba8:	fc06                	sd	ra,56(sp)
    80003baa:	f822                	sd	s0,48(sp)
    80003bac:	f426                	sd	s1,40(sp)
    80003bae:	f04a                	sd	s2,32(sp)
    80003bb0:	ec4e                	sd	s3,24(sp)
    80003bb2:	e852                	sd	s4,16(sp)
    80003bb4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bb6:	04451703          	lh	a4,68(a0)
    80003bba:	4785                	li	a5,1
    80003bbc:	00f71a63          	bne	a4,a5,80003bd0 <dirlookup+0x2a>
    80003bc0:	892a                	mv	s2,a0
    80003bc2:	89ae                	mv	s3,a1
    80003bc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc6:	457c                	lw	a5,76(a0)
    80003bc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bcc:	e79d                	bnez	a5,80003bfa <dirlookup+0x54>
    80003bce:	a8a5                	j	80003c46 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bd0:	00005517          	auipc	a0,0x5
    80003bd4:	ad850513          	addi	a0,a0,-1320 # 800086a8 <syscalls+0x1c0>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	96e080e7          	jalr	-1682(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003be0:	00005517          	auipc	a0,0x5
    80003be4:	ae050513          	addi	a0,a0,-1312 # 800086c0 <syscalls+0x1d8>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	95e080e7          	jalr	-1698(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bf0:	24c1                	addiw	s1,s1,16
    80003bf2:	04c92783          	lw	a5,76(s2)
    80003bf6:	04f4f763          	bgeu	s1,a5,80003c44 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bfa:	4741                	li	a4,16
    80003bfc:	86a6                	mv	a3,s1
    80003bfe:	fc040613          	addi	a2,s0,-64
    80003c02:	4581                	li	a1,0
    80003c04:	854a                	mv	a0,s2
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	d76080e7          	jalr	-650(ra) # 8000397c <readi>
    80003c0e:	47c1                	li	a5,16
    80003c10:	fcf518e3          	bne	a0,a5,80003be0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c14:	fc045783          	lhu	a5,-64(s0)
    80003c18:	dfe1                	beqz	a5,80003bf0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c1a:	fc240593          	addi	a1,s0,-62
    80003c1e:	854e                	mv	a0,s3
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	f6c080e7          	jalr	-148(ra) # 80003b8c <namecmp>
    80003c28:	f561                	bnez	a0,80003bf0 <dirlookup+0x4a>
      if(poff)
    80003c2a:	000a0463          	beqz	s4,80003c32 <dirlookup+0x8c>
        *poff = off;
    80003c2e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c32:	fc045583          	lhu	a1,-64(s0)
    80003c36:	00092503          	lw	a0,0(s2)
    80003c3a:	fffff097          	auipc	ra,0xfffff
    80003c3e:	758080e7          	jalr	1880(ra) # 80003392 <iget>
    80003c42:	a011                	j	80003c46 <dirlookup+0xa0>
  return 0;
    80003c44:	4501                	li	a0,0
}
    80003c46:	70e2                	ld	ra,56(sp)
    80003c48:	7442                	ld	s0,48(sp)
    80003c4a:	74a2                	ld	s1,40(sp)
    80003c4c:	7902                	ld	s2,32(sp)
    80003c4e:	69e2                	ld	s3,24(sp)
    80003c50:	6a42                	ld	s4,16(sp)
    80003c52:	6121                	addi	sp,sp,64
    80003c54:	8082                	ret

0000000080003c56 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c56:	711d                	addi	sp,sp,-96
    80003c58:	ec86                	sd	ra,88(sp)
    80003c5a:	e8a2                	sd	s0,80(sp)
    80003c5c:	e4a6                	sd	s1,72(sp)
    80003c5e:	e0ca                	sd	s2,64(sp)
    80003c60:	fc4e                	sd	s3,56(sp)
    80003c62:	f852                	sd	s4,48(sp)
    80003c64:	f456                	sd	s5,40(sp)
    80003c66:	f05a                	sd	s6,32(sp)
    80003c68:	ec5e                	sd	s7,24(sp)
    80003c6a:	e862                	sd	s8,16(sp)
    80003c6c:	e466                	sd	s9,8(sp)
    80003c6e:	e06a                	sd	s10,0(sp)
    80003c70:	1080                	addi	s0,sp,96
    80003c72:	84aa                	mv	s1,a0
    80003c74:	8b2e                	mv	s6,a1
    80003c76:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c78:	00054703          	lbu	a4,0(a0)
    80003c7c:	02f00793          	li	a5,47
    80003c80:	02f70363          	beq	a4,a5,80003ca6 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c84:	ffffe097          	auipc	ra,0xffffe
    80003c88:	d48080e7          	jalr	-696(ra) # 800019cc <myproc>
    80003c8c:	15053503          	ld	a0,336(a0)
    80003c90:	00000097          	auipc	ra,0x0
    80003c94:	9fa080e7          	jalr	-1542(ra) # 8000368a <idup>
    80003c98:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c9a:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c9e:	4cb5                	li	s9,13
  len = path - s;
    80003ca0:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ca2:	4c05                	li	s8,1
    80003ca4:	a87d                	j	80003d62 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003ca6:	4585                	li	a1,1
    80003ca8:	4505                	li	a0,1
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	6e8080e7          	jalr	1768(ra) # 80003392 <iget>
    80003cb2:	8a2a                	mv	s4,a0
    80003cb4:	b7dd                	j	80003c9a <namex+0x44>
      iunlockput(ip);
    80003cb6:	8552                	mv	a0,s4
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	c72080e7          	jalr	-910(ra) # 8000392a <iunlockput>
      return 0;
    80003cc0:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cc2:	8552                	mv	a0,s4
    80003cc4:	60e6                	ld	ra,88(sp)
    80003cc6:	6446                	ld	s0,80(sp)
    80003cc8:	64a6                	ld	s1,72(sp)
    80003cca:	6906                	ld	s2,64(sp)
    80003ccc:	79e2                	ld	s3,56(sp)
    80003cce:	7a42                	ld	s4,48(sp)
    80003cd0:	7aa2                	ld	s5,40(sp)
    80003cd2:	7b02                	ld	s6,32(sp)
    80003cd4:	6be2                	ld	s7,24(sp)
    80003cd6:	6c42                	ld	s8,16(sp)
    80003cd8:	6ca2                	ld	s9,8(sp)
    80003cda:	6d02                	ld	s10,0(sp)
    80003cdc:	6125                	addi	sp,sp,96
    80003cde:	8082                	ret
      iunlock(ip);
    80003ce0:	8552                	mv	a0,s4
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	aa8080e7          	jalr	-1368(ra) # 8000378a <iunlock>
      return ip;
    80003cea:	bfe1                	j	80003cc2 <namex+0x6c>
      iunlockput(ip);
    80003cec:	8552                	mv	a0,s4
    80003cee:	00000097          	auipc	ra,0x0
    80003cf2:	c3c080e7          	jalr	-964(ra) # 8000392a <iunlockput>
      return 0;
    80003cf6:	8a4e                	mv	s4,s3
    80003cf8:	b7e9                	j	80003cc2 <namex+0x6c>
  len = path - s;
    80003cfa:	40998633          	sub	a2,s3,s1
    80003cfe:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003d02:	09acd863          	bge	s9,s10,80003d92 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003d06:	4639                	li	a2,14
    80003d08:	85a6                	mv	a1,s1
    80003d0a:	8556                	mv	a0,s5
    80003d0c:	ffffd097          	auipc	ra,0xffffd
    80003d10:	04c080e7          	jalr	76(ra) # 80000d58 <memmove>
    80003d14:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d16:	0004c783          	lbu	a5,0(s1)
    80003d1a:	01279763          	bne	a5,s2,80003d28 <namex+0xd2>
    path++;
    80003d1e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d20:	0004c783          	lbu	a5,0(s1)
    80003d24:	ff278de3          	beq	a5,s2,80003d1e <namex+0xc8>
    ilock(ip);
    80003d28:	8552                	mv	a0,s4
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	99e080e7          	jalr	-1634(ra) # 800036c8 <ilock>
    if(ip->type != T_DIR){
    80003d32:	044a1783          	lh	a5,68(s4)
    80003d36:	f98790e3          	bne	a5,s8,80003cb6 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d3a:	000b0563          	beqz	s6,80003d44 <namex+0xee>
    80003d3e:	0004c783          	lbu	a5,0(s1)
    80003d42:	dfd9                	beqz	a5,80003ce0 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d44:	865e                	mv	a2,s7
    80003d46:	85d6                	mv	a1,s5
    80003d48:	8552                	mv	a0,s4
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	e5c080e7          	jalr	-420(ra) # 80003ba6 <dirlookup>
    80003d52:	89aa                	mv	s3,a0
    80003d54:	dd41                	beqz	a0,80003cec <namex+0x96>
    iunlockput(ip);
    80003d56:	8552                	mv	a0,s4
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	bd2080e7          	jalr	-1070(ra) # 8000392a <iunlockput>
    ip = next;
    80003d60:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d62:	0004c783          	lbu	a5,0(s1)
    80003d66:	01279763          	bne	a5,s2,80003d74 <namex+0x11e>
    path++;
    80003d6a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d6c:	0004c783          	lbu	a5,0(s1)
    80003d70:	ff278de3          	beq	a5,s2,80003d6a <namex+0x114>
  if(*path == 0)
    80003d74:	cb9d                	beqz	a5,80003daa <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d76:	0004c783          	lbu	a5,0(s1)
    80003d7a:	89a6                	mv	s3,s1
  len = path - s;
    80003d7c:	8d5e                	mv	s10,s7
    80003d7e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d80:	01278963          	beq	a5,s2,80003d92 <namex+0x13c>
    80003d84:	dbbd                	beqz	a5,80003cfa <namex+0xa4>
    path++;
    80003d86:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d88:	0009c783          	lbu	a5,0(s3)
    80003d8c:	ff279ce3          	bne	a5,s2,80003d84 <namex+0x12e>
    80003d90:	b7ad                	j	80003cfa <namex+0xa4>
    memmove(name, s, len);
    80003d92:	2601                	sext.w	a2,a2
    80003d94:	85a6                	mv	a1,s1
    80003d96:	8556                	mv	a0,s5
    80003d98:	ffffd097          	auipc	ra,0xffffd
    80003d9c:	fc0080e7          	jalr	-64(ra) # 80000d58 <memmove>
    name[len] = 0;
    80003da0:	9d56                	add	s10,s10,s5
    80003da2:	000d0023          	sb	zero,0(s10)
    80003da6:	84ce                	mv	s1,s3
    80003da8:	b7bd                	j	80003d16 <namex+0xc0>
  if(nameiparent){
    80003daa:	f00b0ce3          	beqz	s6,80003cc2 <namex+0x6c>
    iput(ip);
    80003dae:	8552                	mv	a0,s4
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	ad2080e7          	jalr	-1326(ra) # 80003882 <iput>
    return 0;
    80003db8:	4a01                	li	s4,0
    80003dba:	b721                	j	80003cc2 <namex+0x6c>

0000000080003dbc <dirlink>:
{
    80003dbc:	7139                	addi	sp,sp,-64
    80003dbe:	fc06                	sd	ra,56(sp)
    80003dc0:	f822                	sd	s0,48(sp)
    80003dc2:	f426                	sd	s1,40(sp)
    80003dc4:	f04a                	sd	s2,32(sp)
    80003dc6:	ec4e                	sd	s3,24(sp)
    80003dc8:	e852                	sd	s4,16(sp)
    80003dca:	0080                	addi	s0,sp,64
    80003dcc:	892a                	mv	s2,a0
    80003dce:	8a2e                	mv	s4,a1
    80003dd0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dd2:	4601                	li	a2,0
    80003dd4:	00000097          	auipc	ra,0x0
    80003dd8:	dd2080e7          	jalr	-558(ra) # 80003ba6 <dirlookup>
    80003ddc:	e93d                	bnez	a0,80003e52 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dde:	04c92483          	lw	s1,76(s2)
    80003de2:	c49d                	beqz	s1,80003e10 <dirlink+0x54>
    80003de4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003de6:	4741                	li	a4,16
    80003de8:	86a6                	mv	a3,s1
    80003dea:	fc040613          	addi	a2,s0,-64
    80003dee:	4581                	li	a1,0
    80003df0:	854a                	mv	a0,s2
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	b8a080e7          	jalr	-1142(ra) # 8000397c <readi>
    80003dfa:	47c1                	li	a5,16
    80003dfc:	06f51163          	bne	a0,a5,80003e5e <dirlink+0xa2>
    if(de.inum == 0)
    80003e00:	fc045783          	lhu	a5,-64(s0)
    80003e04:	c791                	beqz	a5,80003e10 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e06:	24c1                	addiw	s1,s1,16
    80003e08:	04c92783          	lw	a5,76(s2)
    80003e0c:	fcf4ede3          	bltu	s1,a5,80003de6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e10:	4639                	li	a2,14
    80003e12:	85d2                	mv	a1,s4
    80003e14:	fc240513          	addi	a0,s0,-62
    80003e18:	ffffd097          	auipc	ra,0xffffd
    80003e1c:	ff8080e7          	jalr	-8(ra) # 80000e10 <strncpy>
  de.inum = inum;
    80003e20:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e24:	4741                	li	a4,16
    80003e26:	86a6                	mv	a3,s1
    80003e28:	fc040613          	addi	a2,s0,-64
    80003e2c:	4581                	li	a1,0
    80003e2e:	854a                	mv	a0,s2
    80003e30:	00000097          	auipc	ra,0x0
    80003e34:	c42080e7          	jalr	-958(ra) # 80003a72 <writei>
    80003e38:	872a                	mv	a4,a0
    80003e3a:	47c1                	li	a5,16
  return 0;
    80003e3c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e3e:	02f71863          	bne	a4,a5,80003e6e <dirlink+0xb2>
}
    80003e42:	70e2                	ld	ra,56(sp)
    80003e44:	7442                	ld	s0,48(sp)
    80003e46:	74a2                	ld	s1,40(sp)
    80003e48:	7902                	ld	s2,32(sp)
    80003e4a:	69e2                	ld	s3,24(sp)
    80003e4c:	6a42                	ld	s4,16(sp)
    80003e4e:	6121                	addi	sp,sp,64
    80003e50:	8082                	ret
    iput(ip);
    80003e52:	00000097          	auipc	ra,0x0
    80003e56:	a30080e7          	jalr	-1488(ra) # 80003882 <iput>
    return -1;
    80003e5a:	557d                	li	a0,-1
    80003e5c:	b7dd                	j	80003e42 <dirlink+0x86>
      panic("dirlink read");
    80003e5e:	00005517          	auipc	a0,0x5
    80003e62:	87250513          	addi	a0,a0,-1934 # 800086d0 <syscalls+0x1e8>
    80003e66:	ffffc097          	auipc	ra,0xffffc
    80003e6a:	6e0080e7          	jalr	1760(ra) # 80000546 <panic>
    panic("dirlink");
    80003e6e:	00005517          	auipc	a0,0x5
    80003e72:	97a50513          	addi	a0,a0,-1670 # 800087e8 <syscalls+0x300>
    80003e76:	ffffc097          	auipc	ra,0xffffc
    80003e7a:	6d0080e7          	jalr	1744(ra) # 80000546 <panic>

0000000080003e7e <namei>:

struct inode*
namei(char *path)
{
    80003e7e:	1101                	addi	sp,sp,-32
    80003e80:	ec06                	sd	ra,24(sp)
    80003e82:	e822                	sd	s0,16(sp)
    80003e84:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e86:	fe040613          	addi	a2,s0,-32
    80003e8a:	4581                	li	a1,0
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	dca080e7          	jalr	-566(ra) # 80003c56 <namex>
}
    80003e94:	60e2                	ld	ra,24(sp)
    80003e96:	6442                	ld	s0,16(sp)
    80003e98:	6105                	addi	sp,sp,32
    80003e9a:	8082                	ret

0000000080003e9c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e9c:	1141                	addi	sp,sp,-16
    80003e9e:	e406                	sd	ra,8(sp)
    80003ea0:	e022                	sd	s0,0(sp)
    80003ea2:	0800                	addi	s0,sp,16
    80003ea4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ea6:	4585                	li	a1,1
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	dae080e7          	jalr	-594(ra) # 80003c56 <namex>
}
    80003eb0:	60a2                	ld	ra,8(sp)
    80003eb2:	6402                	ld	s0,0(sp)
    80003eb4:	0141                	addi	sp,sp,16
    80003eb6:	8082                	ret

0000000080003eb8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eb8:	1101                	addi	sp,sp,-32
    80003eba:	ec06                	sd	ra,24(sp)
    80003ebc:	e822                	sd	s0,16(sp)
    80003ebe:	e426                	sd	s1,8(sp)
    80003ec0:	e04a                	sd	s2,0(sp)
    80003ec2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ec4:	0001e917          	auipc	s2,0x1e
    80003ec8:	c4490913          	addi	s2,s2,-956 # 80021b08 <log>
    80003ecc:	01892583          	lw	a1,24(s2)
    80003ed0:	02892503          	lw	a0,40(s2)
    80003ed4:	fffff097          	auipc	ra,0xfffff
    80003ed8:	ff2080e7          	jalr	-14(ra) # 80002ec6 <bread>
    80003edc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ede:	02c92683          	lw	a3,44(s2)
    80003ee2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ee4:	02d05863          	blez	a3,80003f14 <write_head+0x5c>
    80003ee8:	0001e797          	auipc	a5,0x1e
    80003eec:	c5078793          	addi	a5,a5,-944 # 80021b38 <log+0x30>
    80003ef0:	05c50713          	addi	a4,a0,92
    80003ef4:	36fd                	addiw	a3,a3,-1
    80003ef6:	02069613          	slli	a2,a3,0x20
    80003efa:	01e65693          	srli	a3,a2,0x1e
    80003efe:	0001e617          	auipc	a2,0x1e
    80003f02:	c3e60613          	addi	a2,a2,-962 # 80021b3c <log+0x34>
    80003f06:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f08:	4390                	lw	a2,0(a5)
    80003f0a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f0c:	0791                	addi	a5,a5,4
    80003f0e:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003f10:	fed79ce3          	bne	a5,a3,80003f08 <write_head+0x50>
  }
  bwrite(buf);
    80003f14:	8526                	mv	a0,s1
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	0a2080e7          	jalr	162(ra) # 80002fb8 <bwrite>
  brelse(buf);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	0d6080e7          	jalr	214(ra) # 80002ff6 <brelse>
}
    80003f28:	60e2                	ld	ra,24(sp)
    80003f2a:	6442                	ld	s0,16(sp)
    80003f2c:	64a2                	ld	s1,8(sp)
    80003f2e:	6902                	ld	s2,0(sp)
    80003f30:	6105                	addi	sp,sp,32
    80003f32:	8082                	ret

0000000080003f34 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f34:	0001e797          	auipc	a5,0x1e
    80003f38:	c007a783          	lw	a5,-1024(a5) # 80021b34 <log+0x2c>
    80003f3c:	0af05663          	blez	a5,80003fe8 <install_trans+0xb4>
{
    80003f40:	7139                	addi	sp,sp,-64
    80003f42:	fc06                	sd	ra,56(sp)
    80003f44:	f822                	sd	s0,48(sp)
    80003f46:	f426                	sd	s1,40(sp)
    80003f48:	f04a                	sd	s2,32(sp)
    80003f4a:	ec4e                	sd	s3,24(sp)
    80003f4c:	e852                	sd	s4,16(sp)
    80003f4e:	e456                	sd	s5,8(sp)
    80003f50:	0080                	addi	s0,sp,64
    80003f52:	0001ea97          	auipc	s5,0x1e
    80003f56:	be6a8a93          	addi	s5,s5,-1050 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f5a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f5c:	0001e997          	auipc	s3,0x1e
    80003f60:	bac98993          	addi	s3,s3,-1108 # 80021b08 <log>
    80003f64:	0189a583          	lw	a1,24(s3)
    80003f68:	014585bb          	addw	a1,a1,s4
    80003f6c:	2585                	addiw	a1,a1,1
    80003f6e:	0289a503          	lw	a0,40(s3)
    80003f72:	fffff097          	auipc	ra,0xfffff
    80003f76:	f54080e7          	jalr	-172(ra) # 80002ec6 <bread>
    80003f7a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f7c:	000aa583          	lw	a1,0(s5)
    80003f80:	0289a503          	lw	a0,40(s3)
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	f42080e7          	jalr	-190(ra) # 80002ec6 <bread>
    80003f8c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f8e:	40000613          	li	a2,1024
    80003f92:	05890593          	addi	a1,s2,88
    80003f96:	05850513          	addi	a0,a0,88
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	dbe080e7          	jalr	-578(ra) # 80000d58 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	014080e7          	jalr	20(ra) # 80002fb8 <bwrite>
    bunpin(dbuf);
    80003fac:	8526                	mv	a0,s1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	122080e7          	jalr	290(ra) # 800030d0 <bunpin>
    brelse(lbuf);
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	03e080e7          	jalr	62(ra) # 80002ff6 <brelse>
    brelse(dbuf);
    80003fc0:	8526                	mv	a0,s1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	034080e7          	jalr	52(ra) # 80002ff6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fca:	2a05                	addiw	s4,s4,1
    80003fcc:	0a91                	addi	s5,s5,4
    80003fce:	02c9a783          	lw	a5,44(s3)
    80003fd2:	f8fa49e3          	blt	s4,a5,80003f64 <install_trans+0x30>
}
    80003fd6:	70e2                	ld	ra,56(sp)
    80003fd8:	7442                	ld	s0,48(sp)
    80003fda:	74a2                	ld	s1,40(sp)
    80003fdc:	7902                	ld	s2,32(sp)
    80003fde:	69e2                	ld	s3,24(sp)
    80003fe0:	6a42                	ld	s4,16(sp)
    80003fe2:	6aa2                	ld	s5,8(sp)
    80003fe4:	6121                	addi	sp,sp,64
    80003fe6:	8082                	ret
    80003fe8:	8082                	ret

0000000080003fea <initlog>:
{
    80003fea:	7179                	addi	sp,sp,-48
    80003fec:	f406                	sd	ra,40(sp)
    80003fee:	f022                	sd	s0,32(sp)
    80003ff0:	ec26                	sd	s1,24(sp)
    80003ff2:	e84a                	sd	s2,16(sp)
    80003ff4:	e44e                	sd	s3,8(sp)
    80003ff6:	1800                	addi	s0,sp,48
    80003ff8:	892a                	mv	s2,a0
    80003ffa:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ffc:	0001e497          	auipc	s1,0x1e
    80004000:	b0c48493          	addi	s1,s1,-1268 # 80021b08 <log>
    80004004:	00004597          	auipc	a1,0x4
    80004008:	6dc58593          	addi	a1,a1,1756 # 800086e0 <syscalls+0x1f8>
    8000400c:	8526                	mv	a0,s1
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	b62080e7          	jalr	-1182(ra) # 80000b70 <initlock>
  log.start = sb->logstart;
    80004016:	0149a583          	lw	a1,20(s3)
    8000401a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000401c:	0109a783          	lw	a5,16(s3)
    80004020:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004022:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004026:	854a                	mv	a0,s2
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	e9e080e7          	jalr	-354(ra) # 80002ec6 <bread>
  log.lh.n = lh->n;
    80004030:	4d34                	lw	a3,88(a0)
    80004032:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004034:	02d05663          	blez	a3,80004060 <initlog+0x76>
    80004038:	05c50793          	addi	a5,a0,92
    8000403c:	0001e717          	auipc	a4,0x1e
    80004040:	afc70713          	addi	a4,a4,-1284 # 80021b38 <log+0x30>
    80004044:	36fd                	addiw	a3,a3,-1
    80004046:	02069613          	slli	a2,a3,0x20
    8000404a:	01e65693          	srli	a3,a2,0x1e
    8000404e:	06050613          	addi	a2,a0,96
    80004052:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004054:	4390                	lw	a2,0(a5)
    80004056:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004058:	0791                	addi	a5,a5,4
    8000405a:	0711                	addi	a4,a4,4
    8000405c:	fed79ce3          	bne	a5,a3,80004054 <initlog+0x6a>
  brelse(buf);
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	f96080e7          	jalr	-106(ra) # 80002ff6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004068:	00000097          	auipc	ra,0x0
    8000406c:	ecc080e7          	jalr	-308(ra) # 80003f34 <install_trans>
  log.lh.n = 0;
    80004070:	0001e797          	auipc	a5,0x1e
    80004074:	ac07a223          	sw	zero,-1340(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004078:	00000097          	auipc	ra,0x0
    8000407c:	e40080e7          	jalr	-448(ra) # 80003eb8 <write_head>
}
    80004080:	70a2                	ld	ra,40(sp)
    80004082:	7402                	ld	s0,32(sp)
    80004084:	64e2                	ld	s1,24(sp)
    80004086:	6942                	ld	s2,16(sp)
    80004088:	69a2                	ld	s3,8(sp)
    8000408a:	6145                	addi	sp,sp,48
    8000408c:	8082                	ret

000000008000408e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000408e:	1101                	addi	sp,sp,-32
    80004090:	ec06                	sd	ra,24(sp)
    80004092:	e822                	sd	s0,16(sp)
    80004094:	e426                	sd	s1,8(sp)
    80004096:	e04a                	sd	s2,0(sp)
    80004098:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000409a:	0001e517          	auipc	a0,0x1e
    8000409e:	a6e50513          	addi	a0,a0,-1426 # 80021b08 <log>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	b5e080e7          	jalr	-1186(ra) # 80000c00 <acquire>
  while(1){
    if(log.committing){
    800040aa:	0001e497          	auipc	s1,0x1e
    800040ae:	a5e48493          	addi	s1,s1,-1442 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040b2:	4979                	li	s2,30
    800040b4:	a039                	j	800040c2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040b6:	85a6                	mv	a1,s1
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffe097          	auipc	ra,0xffffe
    800040be:	12e080e7          	jalr	302(ra) # 800021e8 <sleep>
    if(log.committing){
    800040c2:	50dc                	lw	a5,36(s1)
    800040c4:	fbed                	bnez	a5,800040b6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040c6:	5098                	lw	a4,32(s1)
    800040c8:	2705                	addiw	a4,a4,1
    800040ca:	0007069b          	sext.w	a3,a4
    800040ce:	0027179b          	slliw	a5,a4,0x2
    800040d2:	9fb9                	addw	a5,a5,a4
    800040d4:	0017979b          	slliw	a5,a5,0x1
    800040d8:	54d8                	lw	a4,44(s1)
    800040da:	9fb9                	addw	a5,a5,a4
    800040dc:	00f95963          	bge	s2,a5,800040ee <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040e0:	85a6                	mv	a1,s1
    800040e2:	8526                	mv	a0,s1
    800040e4:	ffffe097          	auipc	ra,0xffffe
    800040e8:	104080e7          	jalr	260(ra) # 800021e8 <sleep>
    800040ec:	bfd9                	j	800040c2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040ee:	0001e517          	auipc	a0,0x1e
    800040f2:	a1a50513          	addi	a0,a0,-1510 # 80021b08 <log>
    800040f6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	bbc080e7          	jalr	-1092(ra) # 80000cb4 <release>
      break;
    }
  }
}
    80004100:	60e2                	ld	ra,24(sp)
    80004102:	6442                	ld	s0,16(sp)
    80004104:	64a2                	ld	s1,8(sp)
    80004106:	6902                	ld	s2,0(sp)
    80004108:	6105                	addi	sp,sp,32
    8000410a:	8082                	ret

000000008000410c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000410c:	7139                	addi	sp,sp,-64
    8000410e:	fc06                	sd	ra,56(sp)
    80004110:	f822                	sd	s0,48(sp)
    80004112:	f426                	sd	s1,40(sp)
    80004114:	f04a                	sd	s2,32(sp)
    80004116:	ec4e                	sd	s3,24(sp)
    80004118:	e852                	sd	s4,16(sp)
    8000411a:	e456                	sd	s5,8(sp)
    8000411c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000411e:	0001e497          	auipc	s1,0x1e
    80004122:	9ea48493          	addi	s1,s1,-1558 # 80021b08 <log>
    80004126:	8526                	mv	a0,s1
    80004128:	ffffd097          	auipc	ra,0xffffd
    8000412c:	ad8080e7          	jalr	-1320(ra) # 80000c00 <acquire>
  log.outstanding -= 1;
    80004130:	509c                	lw	a5,32(s1)
    80004132:	37fd                	addiw	a5,a5,-1
    80004134:	0007891b          	sext.w	s2,a5
    80004138:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000413a:	50dc                	lw	a5,36(s1)
    8000413c:	e7b9                	bnez	a5,8000418a <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000413e:	04091e63          	bnez	s2,8000419a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004142:	0001e497          	auipc	s1,0x1e
    80004146:	9c648493          	addi	s1,s1,-1594 # 80021b08 <log>
    8000414a:	4785                	li	a5,1
    8000414c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000414e:	8526                	mv	a0,s1
    80004150:	ffffd097          	auipc	ra,0xffffd
    80004154:	b64080e7          	jalr	-1180(ra) # 80000cb4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004158:	54dc                	lw	a5,44(s1)
    8000415a:	06f04763          	bgtz	a5,800041c8 <end_op+0xbc>
    acquire(&log.lock);
    8000415e:	0001e497          	auipc	s1,0x1e
    80004162:	9aa48493          	addi	s1,s1,-1622 # 80021b08 <log>
    80004166:	8526                	mv	a0,s1
    80004168:	ffffd097          	auipc	ra,0xffffd
    8000416c:	a98080e7          	jalr	-1384(ra) # 80000c00 <acquire>
    log.committing = 0;
    80004170:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004174:	8526                	mv	a0,s1
    80004176:	ffffe097          	auipc	ra,0xffffe
    8000417a:	1f2080e7          	jalr	498(ra) # 80002368 <wakeup>
    release(&log.lock);
    8000417e:	8526                	mv	a0,s1
    80004180:	ffffd097          	auipc	ra,0xffffd
    80004184:	b34080e7          	jalr	-1228(ra) # 80000cb4 <release>
}
    80004188:	a03d                	j	800041b6 <end_op+0xaa>
    panic("log.committing");
    8000418a:	00004517          	auipc	a0,0x4
    8000418e:	55e50513          	addi	a0,a0,1374 # 800086e8 <syscalls+0x200>
    80004192:	ffffc097          	auipc	ra,0xffffc
    80004196:	3b4080e7          	jalr	948(ra) # 80000546 <panic>
    wakeup(&log);
    8000419a:	0001e497          	auipc	s1,0x1e
    8000419e:	96e48493          	addi	s1,s1,-1682 # 80021b08 <log>
    800041a2:	8526                	mv	a0,s1
    800041a4:	ffffe097          	auipc	ra,0xffffe
    800041a8:	1c4080e7          	jalr	452(ra) # 80002368 <wakeup>
  release(&log.lock);
    800041ac:	8526                	mv	a0,s1
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	b06080e7          	jalr	-1274(ra) # 80000cb4 <release>
}
    800041b6:	70e2                	ld	ra,56(sp)
    800041b8:	7442                	ld	s0,48(sp)
    800041ba:	74a2                	ld	s1,40(sp)
    800041bc:	7902                	ld	s2,32(sp)
    800041be:	69e2                	ld	s3,24(sp)
    800041c0:	6a42                	ld	s4,16(sp)
    800041c2:	6aa2                	ld	s5,8(sp)
    800041c4:	6121                	addi	sp,sp,64
    800041c6:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c8:	0001ea97          	auipc	s5,0x1e
    800041cc:	970a8a93          	addi	s5,s5,-1680 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041d0:	0001ea17          	auipc	s4,0x1e
    800041d4:	938a0a13          	addi	s4,s4,-1736 # 80021b08 <log>
    800041d8:	018a2583          	lw	a1,24(s4)
    800041dc:	012585bb          	addw	a1,a1,s2
    800041e0:	2585                	addiw	a1,a1,1
    800041e2:	028a2503          	lw	a0,40(s4)
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	ce0080e7          	jalr	-800(ra) # 80002ec6 <bread>
    800041ee:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041f0:	000aa583          	lw	a1,0(s5)
    800041f4:	028a2503          	lw	a0,40(s4)
    800041f8:	fffff097          	auipc	ra,0xfffff
    800041fc:	cce080e7          	jalr	-818(ra) # 80002ec6 <bread>
    80004200:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004202:	40000613          	li	a2,1024
    80004206:	05850593          	addi	a1,a0,88
    8000420a:	05848513          	addi	a0,s1,88
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	b4a080e7          	jalr	-1206(ra) # 80000d58 <memmove>
    bwrite(to);  // write the log
    80004216:	8526                	mv	a0,s1
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	da0080e7          	jalr	-608(ra) # 80002fb8 <bwrite>
    brelse(from);
    80004220:	854e                	mv	a0,s3
    80004222:	fffff097          	auipc	ra,0xfffff
    80004226:	dd4080e7          	jalr	-556(ra) # 80002ff6 <brelse>
    brelse(to);
    8000422a:	8526                	mv	a0,s1
    8000422c:	fffff097          	auipc	ra,0xfffff
    80004230:	dca080e7          	jalr	-566(ra) # 80002ff6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004234:	2905                	addiw	s2,s2,1
    80004236:	0a91                	addi	s5,s5,4
    80004238:	02ca2783          	lw	a5,44(s4)
    8000423c:	f8f94ee3          	blt	s2,a5,800041d8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004240:	00000097          	auipc	ra,0x0
    80004244:	c78080e7          	jalr	-904(ra) # 80003eb8 <write_head>
    install_trans(); // Now install writes to home locations
    80004248:	00000097          	auipc	ra,0x0
    8000424c:	cec080e7          	jalr	-788(ra) # 80003f34 <install_trans>
    log.lh.n = 0;
    80004250:	0001e797          	auipc	a5,0x1e
    80004254:	8e07a223          	sw	zero,-1820(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	c60080e7          	jalr	-928(ra) # 80003eb8 <write_head>
    80004260:	bdfd                	j	8000415e <end_op+0x52>

0000000080004262 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004262:	1101                	addi	sp,sp,-32
    80004264:	ec06                	sd	ra,24(sp)
    80004266:	e822                	sd	s0,16(sp)
    80004268:	e426                	sd	s1,8(sp)
    8000426a:	e04a                	sd	s2,0(sp)
    8000426c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000426e:	0001e717          	auipc	a4,0x1e
    80004272:	8c672703          	lw	a4,-1850(a4) # 80021b34 <log+0x2c>
    80004276:	47f5                	li	a5,29
    80004278:	08e7c063          	blt	a5,a4,800042f8 <log_write+0x96>
    8000427c:	84aa                	mv	s1,a0
    8000427e:	0001e797          	auipc	a5,0x1e
    80004282:	8a67a783          	lw	a5,-1882(a5) # 80021b24 <log+0x1c>
    80004286:	37fd                	addiw	a5,a5,-1
    80004288:	06f75863          	bge	a4,a5,800042f8 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000428c:	0001e797          	auipc	a5,0x1e
    80004290:	89c7a783          	lw	a5,-1892(a5) # 80021b28 <log+0x20>
    80004294:	06f05a63          	blez	a5,80004308 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004298:	0001e917          	auipc	s2,0x1e
    8000429c:	87090913          	addi	s2,s2,-1936 # 80021b08 <log>
    800042a0:	854a                	mv	a0,s2
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	95e080e7          	jalr	-1698(ra) # 80000c00 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042aa:	02c92603          	lw	a2,44(s2)
    800042ae:	06c05563          	blez	a2,80004318 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042b2:	44cc                	lw	a1,12(s1)
    800042b4:	0001e717          	auipc	a4,0x1e
    800042b8:	88470713          	addi	a4,a4,-1916 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042be:	4314                	lw	a3,0(a4)
    800042c0:	04b68d63          	beq	a3,a1,8000431a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042c4:	2785                	addiw	a5,a5,1
    800042c6:	0711                	addi	a4,a4,4
    800042c8:	fec79be3          	bne	a5,a2,800042be <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042cc:	0621                	addi	a2,a2,8
    800042ce:	060a                	slli	a2,a2,0x2
    800042d0:	0001e797          	auipc	a5,0x1e
    800042d4:	83878793          	addi	a5,a5,-1992 # 80021b08 <log>
    800042d8:	97b2                	add	a5,a5,a2
    800042da:	44d8                	lw	a4,12(s1)
    800042dc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042de:	8526                	mv	a0,s1
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	db4080e7          	jalr	-588(ra) # 80003094 <bpin>
    log.lh.n++;
    800042e8:	0001e717          	auipc	a4,0x1e
    800042ec:	82070713          	addi	a4,a4,-2016 # 80021b08 <log>
    800042f0:	575c                	lw	a5,44(a4)
    800042f2:	2785                	addiw	a5,a5,1
    800042f4:	d75c                	sw	a5,44(a4)
    800042f6:	a835                	j	80004332 <log_write+0xd0>
    panic("too big a transaction");
    800042f8:	00004517          	auipc	a0,0x4
    800042fc:	40050513          	addi	a0,a0,1024 # 800086f8 <syscalls+0x210>
    80004300:	ffffc097          	auipc	ra,0xffffc
    80004304:	246080e7          	jalr	582(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	40850513          	addi	a0,a0,1032 # 80008710 <syscalls+0x228>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	236080e7          	jalr	566(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004318:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000431a:	00878693          	addi	a3,a5,8
    8000431e:	068a                	slli	a3,a3,0x2
    80004320:	0001d717          	auipc	a4,0x1d
    80004324:	7e870713          	addi	a4,a4,2024 # 80021b08 <log>
    80004328:	9736                	add	a4,a4,a3
    8000432a:	44d4                	lw	a3,12(s1)
    8000432c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000432e:	faf608e3          	beq	a2,a5,800042de <log_write+0x7c>
  }
  release(&log.lock);
    80004332:	0001d517          	auipc	a0,0x1d
    80004336:	7d650513          	addi	a0,a0,2006 # 80021b08 <log>
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	97a080e7          	jalr	-1670(ra) # 80000cb4 <release>
}
    80004342:	60e2                	ld	ra,24(sp)
    80004344:	6442                	ld	s0,16(sp)
    80004346:	64a2                	ld	s1,8(sp)
    80004348:	6902                	ld	s2,0(sp)
    8000434a:	6105                	addi	sp,sp,32
    8000434c:	8082                	ret

000000008000434e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000434e:	1101                	addi	sp,sp,-32
    80004350:	ec06                	sd	ra,24(sp)
    80004352:	e822                	sd	s0,16(sp)
    80004354:	e426                	sd	s1,8(sp)
    80004356:	e04a                	sd	s2,0(sp)
    80004358:	1000                	addi	s0,sp,32
    8000435a:	84aa                	mv	s1,a0
    8000435c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000435e:	00004597          	auipc	a1,0x4
    80004362:	3d258593          	addi	a1,a1,978 # 80008730 <syscalls+0x248>
    80004366:	0521                	addi	a0,a0,8
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	808080e7          	jalr	-2040(ra) # 80000b70 <initlock>
  lk->name = name;
    80004370:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004374:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004378:	0204a423          	sw	zero,40(s1)
}
    8000437c:	60e2                	ld	ra,24(sp)
    8000437e:	6442                	ld	s0,16(sp)
    80004380:	64a2                	ld	s1,8(sp)
    80004382:	6902                	ld	s2,0(sp)
    80004384:	6105                	addi	sp,sp,32
    80004386:	8082                	ret

0000000080004388 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004388:	1101                	addi	sp,sp,-32
    8000438a:	ec06                	sd	ra,24(sp)
    8000438c:	e822                	sd	s0,16(sp)
    8000438e:	e426                	sd	s1,8(sp)
    80004390:	e04a                	sd	s2,0(sp)
    80004392:	1000                	addi	s0,sp,32
    80004394:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004396:	00850913          	addi	s2,a0,8
    8000439a:	854a                	mv	a0,s2
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	864080e7          	jalr	-1948(ra) # 80000c00 <acquire>
  while (lk->locked) {
    800043a4:	409c                	lw	a5,0(s1)
    800043a6:	cb89                	beqz	a5,800043b8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043a8:	85ca                	mv	a1,s2
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffe097          	auipc	ra,0xffffe
    800043b0:	e3c080e7          	jalr	-452(ra) # 800021e8 <sleep>
  while (lk->locked) {
    800043b4:	409c                	lw	a5,0(s1)
    800043b6:	fbed                	bnez	a5,800043a8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043b8:	4785                	li	a5,1
    800043ba:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	610080e7          	jalr	1552(ra) # 800019cc <myproc>
    800043c4:	5d1c                	lw	a5,56(a0)
    800043c6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043c8:	854a                	mv	a0,s2
    800043ca:	ffffd097          	auipc	ra,0xffffd
    800043ce:	8ea080e7          	jalr	-1814(ra) # 80000cb4 <release>
}
    800043d2:	60e2                	ld	ra,24(sp)
    800043d4:	6442                	ld	s0,16(sp)
    800043d6:	64a2                	ld	s1,8(sp)
    800043d8:	6902                	ld	s2,0(sp)
    800043da:	6105                	addi	sp,sp,32
    800043dc:	8082                	ret

00000000800043de <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043de:	1101                	addi	sp,sp,-32
    800043e0:	ec06                	sd	ra,24(sp)
    800043e2:	e822                	sd	s0,16(sp)
    800043e4:	e426                	sd	s1,8(sp)
    800043e6:	e04a                	sd	s2,0(sp)
    800043e8:	1000                	addi	s0,sp,32
    800043ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043ec:	00850913          	addi	s2,a0,8
    800043f0:	854a                	mv	a0,s2
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	80e080e7          	jalr	-2034(ra) # 80000c00 <acquire>
  lk->locked = 0;
    800043fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043fe:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004402:	8526                	mv	a0,s1
    80004404:	ffffe097          	auipc	ra,0xffffe
    80004408:	f64080e7          	jalr	-156(ra) # 80002368 <wakeup>
  release(&lk->lk);
    8000440c:	854a                	mv	a0,s2
    8000440e:	ffffd097          	auipc	ra,0xffffd
    80004412:	8a6080e7          	jalr	-1882(ra) # 80000cb4 <release>
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6902                	ld	s2,0(sp)
    8000441e:	6105                	addi	sp,sp,32
    80004420:	8082                	ret

0000000080004422 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004422:	7179                	addi	sp,sp,-48
    80004424:	f406                	sd	ra,40(sp)
    80004426:	f022                	sd	s0,32(sp)
    80004428:	ec26                	sd	s1,24(sp)
    8000442a:	e84a                	sd	s2,16(sp)
    8000442c:	e44e                	sd	s3,8(sp)
    8000442e:	1800                	addi	s0,sp,48
    80004430:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004432:	00850913          	addi	s2,a0,8
    80004436:	854a                	mv	a0,s2
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	7c8080e7          	jalr	1992(ra) # 80000c00 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004440:	409c                	lw	a5,0(s1)
    80004442:	ef99                	bnez	a5,80004460 <holdingsleep+0x3e>
    80004444:	4481                	li	s1,0
  release(&lk->lk);
    80004446:	854a                	mv	a0,s2
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	86c080e7          	jalr	-1940(ra) # 80000cb4 <release>
  return r;
}
    80004450:	8526                	mv	a0,s1
    80004452:	70a2                	ld	ra,40(sp)
    80004454:	7402                	ld	s0,32(sp)
    80004456:	64e2                	ld	s1,24(sp)
    80004458:	6942                	ld	s2,16(sp)
    8000445a:	69a2                	ld	s3,8(sp)
    8000445c:	6145                	addi	sp,sp,48
    8000445e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004460:	0284a983          	lw	s3,40(s1)
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	568080e7          	jalr	1384(ra) # 800019cc <myproc>
    8000446c:	5d04                	lw	s1,56(a0)
    8000446e:	413484b3          	sub	s1,s1,s3
    80004472:	0014b493          	seqz	s1,s1
    80004476:	bfc1                	j	80004446 <holdingsleep+0x24>

0000000080004478 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004478:	1141                	addi	sp,sp,-16
    8000447a:	e406                	sd	ra,8(sp)
    8000447c:	e022                	sd	s0,0(sp)
    8000447e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004480:	00004597          	auipc	a1,0x4
    80004484:	2c058593          	addi	a1,a1,704 # 80008740 <syscalls+0x258>
    80004488:	0001d517          	auipc	a0,0x1d
    8000448c:	7c850513          	addi	a0,a0,1992 # 80021c50 <ftable>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	6e0080e7          	jalr	1760(ra) # 80000b70 <initlock>
}
    80004498:	60a2                	ld	ra,8(sp)
    8000449a:	6402                	ld	s0,0(sp)
    8000449c:	0141                	addi	sp,sp,16
    8000449e:	8082                	ret

00000000800044a0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044a0:	1101                	addi	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044aa:	0001d517          	auipc	a0,0x1d
    800044ae:	7a650513          	addi	a0,a0,1958 # 80021c50 <ftable>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	74e080e7          	jalr	1870(ra) # 80000c00 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ba:	0001d497          	auipc	s1,0x1d
    800044be:	7ae48493          	addi	s1,s1,1966 # 80021c68 <ftable+0x18>
    800044c2:	0001e717          	auipc	a4,0x1e
    800044c6:	74670713          	addi	a4,a4,1862 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800044ca:	40dc                	lw	a5,4(s1)
    800044cc:	cf99                	beqz	a5,800044ea <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ce:	02848493          	addi	s1,s1,40
    800044d2:	fee49ce3          	bne	s1,a4,800044ca <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044d6:	0001d517          	auipc	a0,0x1d
    800044da:	77a50513          	addi	a0,a0,1914 # 80021c50 <ftable>
    800044de:	ffffc097          	auipc	ra,0xffffc
    800044e2:	7d6080e7          	jalr	2006(ra) # 80000cb4 <release>
  return 0;
    800044e6:	4481                	li	s1,0
    800044e8:	a819                	j	800044fe <filealloc+0x5e>
      f->ref = 1;
    800044ea:	4785                	li	a5,1
    800044ec:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044ee:	0001d517          	auipc	a0,0x1d
    800044f2:	76250513          	addi	a0,a0,1890 # 80021c50 <ftable>
    800044f6:	ffffc097          	auipc	ra,0xffffc
    800044fa:	7be080e7          	jalr	1982(ra) # 80000cb4 <release>
}
    800044fe:	8526                	mv	a0,s1
    80004500:	60e2                	ld	ra,24(sp)
    80004502:	6442                	ld	s0,16(sp)
    80004504:	64a2                	ld	s1,8(sp)
    80004506:	6105                	addi	sp,sp,32
    80004508:	8082                	ret

000000008000450a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000450a:	1101                	addi	sp,sp,-32
    8000450c:	ec06                	sd	ra,24(sp)
    8000450e:	e822                	sd	s0,16(sp)
    80004510:	e426                	sd	s1,8(sp)
    80004512:	1000                	addi	s0,sp,32
    80004514:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004516:	0001d517          	auipc	a0,0x1d
    8000451a:	73a50513          	addi	a0,a0,1850 # 80021c50 <ftable>
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6e2080e7          	jalr	1762(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    80004526:	40dc                	lw	a5,4(s1)
    80004528:	02f05263          	blez	a5,8000454c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000452c:	2785                	addiw	a5,a5,1
    8000452e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004530:	0001d517          	auipc	a0,0x1d
    80004534:	72050513          	addi	a0,a0,1824 # 80021c50 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	77c080e7          	jalr	1916(ra) # 80000cb4 <release>
  return f;
}
    80004540:	8526                	mv	a0,s1
    80004542:	60e2                	ld	ra,24(sp)
    80004544:	6442                	ld	s0,16(sp)
    80004546:	64a2                	ld	s1,8(sp)
    80004548:	6105                	addi	sp,sp,32
    8000454a:	8082                	ret
    panic("filedup");
    8000454c:	00004517          	auipc	a0,0x4
    80004550:	1fc50513          	addi	a0,a0,508 # 80008748 <syscalls+0x260>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	ff2080e7          	jalr	-14(ra) # 80000546 <panic>

000000008000455c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000455c:	7139                	addi	sp,sp,-64
    8000455e:	fc06                	sd	ra,56(sp)
    80004560:	f822                	sd	s0,48(sp)
    80004562:	f426                	sd	s1,40(sp)
    80004564:	f04a                	sd	s2,32(sp)
    80004566:	ec4e                	sd	s3,24(sp)
    80004568:	e852                	sd	s4,16(sp)
    8000456a:	e456                	sd	s5,8(sp)
    8000456c:	0080                	addi	s0,sp,64
    8000456e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004570:	0001d517          	auipc	a0,0x1d
    80004574:	6e050513          	addi	a0,a0,1760 # 80021c50 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	688080e7          	jalr	1672(ra) # 80000c00 <acquire>
  if(f->ref < 1)
    80004580:	40dc                	lw	a5,4(s1)
    80004582:	06f05163          	blez	a5,800045e4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004586:	37fd                	addiw	a5,a5,-1
    80004588:	0007871b          	sext.w	a4,a5
    8000458c:	c0dc                	sw	a5,4(s1)
    8000458e:	06e04363          	bgtz	a4,800045f4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004592:	0004a903          	lw	s2,0(s1)
    80004596:	0094ca83          	lbu	s5,9(s1)
    8000459a:	0104ba03          	ld	s4,16(s1)
    8000459e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045a2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045a6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045aa:	0001d517          	auipc	a0,0x1d
    800045ae:	6a650513          	addi	a0,a0,1702 # 80021c50 <ftable>
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	702080e7          	jalr	1794(ra) # 80000cb4 <release>

  if(ff.type == FD_PIPE){
    800045ba:	4785                	li	a5,1
    800045bc:	04f90d63          	beq	s2,a5,80004616 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045c0:	3979                	addiw	s2,s2,-2
    800045c2:	4785                	li	a5,1
    800045c4:	0527e063          	bltu	a5,s2,80004604 <fileclose+0xa8>
    begin_op();
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	ac6080e7          	jalr	-1338(ra) # 8000408e <begin_op>
    iput(ff.ip);
    800045d0:	854e                	mv	a0,s3
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	2b0080e7          	jalr	688(ra) # 80003882 <iput>
    end_op();
    800045da:	00000097          	auipc	ra,0x0
    800045de:	b32080e7          	jalr	-1230(ra) # 8000410c <end_op>
    800045e2:	a00d                	j	80004604 <fileclose+0xa8>
    panic("fileclose");
    800045e4:	00004517          	auipc	a0,0x4
    800045e8:	16c50513          	addi	a0,a0,364 # 80008750 <syscalls+0x268>
    800045ec:	ffffc097          	auipc	ra,0xffffc
    800045f0:	f5a080e7          	jalr	-166(ra) # 80000546 <panic>
    release(&ftable.lock);
    800045f4:	0001d517          	auipc	a0,0x1d
    800045f8:	65c50513          	addi	a0,a0,1628 # 80021c50 <ftable>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	6b8080e7          	jalr	1720(ra) # 80000cb4 <release>
  }
}
    80004604:	70e2                	ld	ra,56(sp)
    80004606:	7442                	ld	s0,48(sp)
    80004608:	74a2                	ld	s1,40(sp)
    8000460a:	7902                	ld	s2,32(sp)
    8000460c:	69e2                	ld	s3,24(sp)
    8000460e:	6a42                	ld	s4,16(sp)
    80004610:	6aa2                	ld	s5,8(sp)
    80004612:	6121                	addi	sp,sp,64
    80004614:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004616:	85d6                	mv	a1,s5
    80004618:	8552                	mv	a0,s4
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	372080e7          	jalr	882(ra) # 8000498c <pipeclose>
    80004622:	b7cd                	j	80004604 <fileclose+0xa8>

0000000080004624 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004624:	715d                	addi	sp,sp,-80
    80004626:	e486                	sd	ra,72(sp)
    80004628:	e0a2                	sd	s0,64(sp)
    8000462a:	fc26                	sd	s1,56(sp)
    8000462c:	f84a                	sd	s2,48(sp)
    8000462e:	f44e                	sd	s3,40(sp)
    80004630:	0880                	addi	s0,sp,80
    80004632:	84aa                	mv	s1,a0
    80004634:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004636:	ffffd097          	auipc	ra,0xffffd
    8000463a:	396080e7          	jalr	918(ra) # 800019cc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000463e:	409c                	lw	a5,0(s1)
    80004640:	37f9                	addiw	a5,a5,-2
    80004642:	4705                	li	a4,1
    80004644:	04f76763          	bltu	a4,a5,80004692 <filestat+0x6e>
    80004648:	892a                	mv	s2,a0
    ilock(f->ip);
    8000464a:	6c88                	ld	a0,24(s1)
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	07c080e7          	jalr	124(ra) # 800036c8 <ilock>
    stati(f->ip, &st);
    80004654:	fb840593          	addi	a1,s0,-72
    80004658:	6c88                	ld	a0,24(s1)
    8000465a:	fffff097          	auipc	ra,0xfffff
    8000465e:	2f8080e7          	jalr	760(ra) # 80003952 <stati>
    iunlock(f->ip);
    80004662:	6c88                	ld	a0,24(s1)
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	126080e7          	jalr	294(ra) # 8000378a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000466c:	46e1                	li	a3,24
    8000466e:	fb840613          	addi	a2,s0,-72
    80004672:	85ce                	mv	a1,s3
    80004674:	05093503          	ld	a0,80(s2)
    80004678:	ffffd097          	auipc	ra,0xffffd
    8000467c:	04a080e7          	jalr	74(ra) # 800016c2 <copyout>
    80004680:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004684:	60a6                	ld	ra,72(sp)
    80004686:	6406                	ld	s0,64(sp)
    80004688:	74e2                	ld	s1,56(sp)
    8000468a:	7942                	ld	s2,48(sp)
    8000468c:	79a2                	ld	s3,40(sp)
    8000468e:	6161                	addi	sp,sp,80
    80004690:	8082                	ret
  return -1;
    80004692:	557d                	li	a0,-1
    80004694:	bfc5                	j	80004684 <filestat+0x60>

0000000080004696 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004696:	7179                	addi	sp,sp,-48
    80004698:	f406                	sd	ra,40(sp)
    8000469a:	f022                	sd	s0,32(sp)
    8000469c:	ec26                	sd	s1,24(sp)
    8000469e:	e84a                	sd	s2,16(sp)
    800046a0:	e44e                	sd	s3,8(sp)
    800046a2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046a4:	00854783          	lbu	a5,8(a0)
    800046a8:	c3d5                	beqz	a5,8000474c <fileread+0xb6>
    800046aa:	84aa                	mv	s1,a0
    800046ac:	89ae                	mv	s3,a1
    800046ae:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046b0:	411c                	lw	a5,0(a0)
    800046b2:	4705                	li	a4,1
    800046b4:	04e78963          	beq	a5,a4,80004706 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b8:	470d                	li	a4,3
    800046ba:	04e78d63          	beq	a5,a4,80004714 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046be:	4709                	li	a4,2
    800046c0:	06e79e63          	bne	a5,a4,8000473c <fileread+0xa6>
    ilock(f->ip);
    800046c4:	6d08                	ld	a0,24(a0)
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	002080e7          	jalr	2(ra) # 800036c8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ce:	874a                	mv	a4,s2
    800046d0:	5094                	lw	a3,32(s1)
    800046d2:	864e                	mv	a2,s3
    800046d4:	4585                	li	a1,1
    800046d6:	6c88                	ld	a0,24(s1)
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	2a4080e7          	jalr	676(ra) # 8000397c <readi>
    800046e0:	892a                	mv	s2,a0
    800046e2:	00a05563          	blez	a0,800046ec <fileread+0x56>
      f->off += r;
    800046e6:	509c                	lw	a5,32(s1)
    800046e8:	9fa9                	addw	a5,a5,a0
    800046ea:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046ec:	6c88                	ld	a0,24(s1)
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	09c080e7          	jalr	156(ra) # 8000378a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046f6:	854a                	mv	a0,s2
    800046f8:	70a2                	ld	ra,40(sp)
    800046fa:	7402                	ld	s0,32(sp)
    800046fc:	64e2                	ld	s1,24(sp)
    800046fe:	6942                	ld	s2,16(sp)
    80004700:	69a2                	ld	s3,8(sp)
    80004702:	6145                	addi	sp,sp,48
    80004704:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004706:	6908                	ld	a0,16(a0)
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	3f6080e7          	jalr	1014(ra) # 80004afe <piperead>
    80004710:	892a                	mv	s2,a0
    80004712:	b7d5                	j	800046f6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004714:	02451783          	lh	a5,36(a0)
    80004718:	03079693          	slli	a3,a5,0x30
    8000471c:	92c1                	srli	a3,a3,0x30
    8000471e:	4725                	li	a4,9
    80004720:	02d76863          	bltu	a4,a3,80004750 <fileread+0xba>
    80004724:	0792                	slli	a5,a5,0x4
    80004726:	0001d717          	auipc	a4,0x1d
    8000472a:	48a70713          	addi	a4,a4,1162 # 80021bb0 <devsw>
    8000472e:	97ba                	add	a5,a5,a4
    80004730:	639c                	ld	a5,0(a5)
    80004732:	c38d                	beqz	a5,80004754 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004734:	4505                	li	a0,1
    80004736:	9782                	jalr	a5
    80004738:	892a                	mv	s2,a0
    8000473a:	bf75                	j	800046f6 <fileread+0x60>
    panic("fileread");
    8000473c:	00004517          	auipc	a0,0x4
    80004740:	02450513          	addi	a0,a0,36 # 80008760 <syscalls+0x278>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	e02080e7          	jalr	-510(ra) # 80000546 <panic>
    return -1;
    8000474c:	597d                	li	s2,-1
    8000474e:	b765                	j	800046f6 <fileread+0x60>
      return -1;
    80004750:	597d                	li	s2,-1
    80004752:	b755                	j	800046f6 <fileread+0x60>
    80004754:	597d                	li	s2,-1
    80004756:	b745                	j	800046f6 <fileread+0x60>

0000000080004758 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004758:	00954783          	lbu	a5,9(a0)
    8000475c:	14078563          	beqz	a5,800048a6 <filewrite+0x14e>
{
    80004760:	715d                	addi	sp,sp,-80
    80004762:	e486                	sd	ra,72(sp)
    80004764:	e0a2                	sd	s0,64(sp)
    80004766:	fc26                	sd	s1,56(sp)
    80004768:	f84a                	sd	s2,48(sp)
    8000476a:	f44e                	sd	s3,40(sp)
    8000476c:	f052                	sd	s4,32(sp)
    8000476e:	ec56                	sd	s5,24(sp)
    80004770:	e85a                	sd	s6,16(sp)
    80004772:	e45e                	sd	s7,8(sp)
    80004774:	e062                	sd	s8,0(sp)
    80004776:	0880                	addi	s0,sp,80
    80004778:	892a                	mv	s2,a0
    8000477a:	8b2e                	mv	s6,a1
    8000477c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477e:	411c                	lw	a5,0(a0)
    80004780:	4705                	li	a4,1
    80004782:	02e78263          	beq	a5,a4,800047a6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004786:	470d                	li	a4,3
    80004788:	02e78563          	beq	a5,a4,800047b2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000478c:	4709                	li	a4,2
    8000478e:	10e79463          	bne	a5,a4,80004896 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004792:	0ec05e63          	blez	a2,8000488e <filewrite+0x136>
    int i = 0;
    80004796:	4981                	li	s3,0
    80004798:	6b85                	lui	s7,0x1
    8000479a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000479e:	6c05                	lui	s8,0x1
    800047a0:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047a4:	a851                	j	80004838 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047a6:	6908                	ld	a0,16(a0)
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	254080e7          	jalr	596(ra) # 800049fc <pipewrite>
    800047b0:	a85d                	j	80004866 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047b2:	02451783          	lh	a5,36(a0)
    800047b6:	03079693          	slli	a3,a5,0x30
    800047ba:	92c1                	srli	a3,a3,0x30
    800047bc:	4725                	li	a4,9
    800047be:	0ed76663          	bltu	a4,a3,800048aa <filewrite+0x152>
    800047c2:	0792                	slli	a5,a5,0x4
    800047c4:	0001d717          	auipc	a4,0x1d
    800047c8:	3ec70713          	addi	a4,a4,1004 # 80021bb0 <devsw>
    800047cc:	97ba                	add	a5,a5,a4
    800047ce:	679c                	ld	a5,8(a5)
    800047d0:	cff9                	beqz	a5,800048ae <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047d2:	4505                	li	a0,1
    800047d4:	9782                	jalr	a5
    800047d6:	a841                	j	80004866 <filewrite+0x10e>
    800047d8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047dc:	00000097          	auipc	ra,0x0
    800047e0:	8b2080e7          	jalr	-1870(ra) # 8000408e <begin_op>
      ilock(f->ip);
    800047e4:	01893503          	ld	a0,24(s2)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	ee0080e7          	jalr	-288(ra) # 800036c8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047f0:	8756                	mv	a4,s5
    800047f2:	02092683          	lw	a3,32(s2)
    800047f6:	01698633          	add	a2,s3,s6
    800047fa:	4585                	li	a1,1
    800047fc:	01893503          	ld	a0,24(s2)
    80004800:	fffff097          	auipc	ra,0xfffff
    80004804:	272080e7          	jalr	626(ra) # 80003a72 <writei>
    80004808:	84aa                	mv	s1,a0
    8000480a:	02a05f63          	blez	a0,80004848 <filewrite+0xf0>
        f->off += r;
    8000480e:	02092783          	lw	a5,32(s2)
    80004812:	9fa9                	addw	a5,a5,a0
    80004814:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004818:	01893503          	ld	a0,24(s2)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	f6e080e7          	jalr	-146(ra) # 8000378a <iunlock>
      end_op();
    80004824:	00000097          	auipc	ra,0x0
    80004828:	8e8080e7          	jalr	-1816(ra) # 8000410c <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000482c:	049a9963          	bne	s5,s1,8000487e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004830:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004834:	0349d663          	bge	s3,s4,80004860 <filewrite+0x108>
      int n1 = n - i;
    80004838:	413a04bb          	subw	s1,s4,s3
    8000483c:	0004879b          	sext.w	a5,s1
    80004840:	f8fbdce3          	bge	s7,a5,800047d8 <filewrite+0x80>
    80004844:	84e2                	mv	s1,s8
    80004846:	bf49                	j	800047d8 <filewrite+0x80>
      iunlock(f->ip);
    80004848:	01893503          	ld	a0,24(s2)
    8000484c:	fffff097          	auipc	ra,0xfffff
    80004850:	f3e080e7          	jalr	-194(ra) # 8000378a <iunlock>
      end_op();
    80004854:	00000097          	auipc	ra,0x0
    80004858:	8b8080e7          	jalr	-1864(ra) # 8000410c <end_op>
      if(r < 0)
    8000485c:	fc04d8e3          	bgez	s1,8000482c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004860:	8552                	mv	a0,s4
    80004862:	033a1863          	bne	s4,s3,80004892 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004866:	60a6                	ld	ra,72(sp)
    80004868:	6406                	ld	s0,64(sp)
    8000486a:	74e2                	ld	s1,56(sp)
    8000486c:	7942                	ld	s2,48(sp)
    8000486e:	79a2                	ld	s3,40(sp)
    80004870:	7a02                	ld	s4,32(sp)
    80004872:	6ae2                	ld	s5,24(sp)
    80004874:	6b42                	ld	s6,16(sp)
    80004876:	6ba2                	ld	s7,8(sp)
    80004878:	6c02                	ld	s8,0(sp)
    8000487a:	6161                	addi	sp,sp,80
    8000487c:	8082                	ret
        panic("short filewrite");
    8000487e:	00004517          	auipc	a0,0x4
    80004882:	ef250513          	addi	a0,a0,-270 # 80008770 <syscalls+0x288>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	cc0080e7          	jalr	-832(ra) # 80000546 <panic>
    int i = 0;
    8000488e:	4981                	li	s3,0
    80004890:	bfc1                	j	80004860 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004892:	557d                	li	a0,-1
    80004894:	bfc9                	j	80004866 <filewrite+0x10e>
    panic("filewrite");
    80004896:	00004517          	auipc	a0,0x4
    8000489a:	eea50513          	addi	a0,a0,-278 # 80008780 <syscalls+0x298>
    8000489e:	ffffc097          	auipc	ra,0xffffc
    800048a2:	ca8080e7          	jalr	-856(ra) # 80000546 <panic>
    return -1;
    800048a6:	557d                	li	a0,-1
}
    800048a8:	8082                	ret
      return -1;
    800048aa:	557d                	li	a0,-1
    800048ac:	bf6d                	j	80004866 <filewrite+0x10e>
    800048ae:	557d                	li	a0,-1
    800048b0:	bf5d                	j	80004866 <filewrite+0x10e>

00000000800048b2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048b2:	7179                	addi	sp,sp,-48
    800048b4:	f406                	sd	ra,40(sp)
    800048b6:	f022                	sd	s0,32(sp)
    800048b8:	ec26                	sd	s1,24(sp)
    800048ba:	e84a                	sd	s2,16(sp)
    800048bc:	e44e                	sd	s3,8(sp)
    800048be:	e052                	sd	s4,0(sp)
    800048c0:	1800                	addi	s0,sp,48
    800048c2:	84aa                	mv	s1,a0
    800048c4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048c6:	0005b023          	sd	zero,0(a1)
    800048ca:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	bd2080e7          	jalr	-1070(ra) # 800044a0 <filealloc>
    800048d6:	e088                	sd	a0,0(s1)
    800048d8:	c551                	beqz	a0,80004964 <pipealloc+0xb2>
    800048da:	00000097          	auipc	ra,0x0
    800048de:	bc6080e7          	jalr	-1082(ra) # 800044a0 <filealloc>
    800048e2:	00aa3023          	sd	a0,0(s4)
    800048e6:	c92d                	beqz	a0,80004958 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	228080e7          	jalr	552(ra) # 80000b10 <kalloc>
    800048f0:	892a                	mv	s2,a0
    800048f2:	c125                	beqz	a0,80004952 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048f4:	4985                	li	s3,1
    800048f6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048fa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048fe:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004902:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004906:	00004597          	auipc	a1,0x4
    8000490a:	b3a58593          	addi	a1,a1,-1222 # 80008440 <states.0+0x198>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	262080e7          	jalr	610(ra) # 80000b70 <initlock>
  (*f0)->type = FD_PIPE;
    80004916:	609c                	ld	a5,0(s1)
    80004918:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000491c:	609c                	ld	a5,0(s1)
    8000491e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004922:	609c                	ld	a5,0(s1)
    80004924:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004928:	609c                	ld	a5,0(s1)
    8000492a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000492e:	000a3783          	ld	a5,0(s4)
    80004932:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004936:	000a3783          	ld	a5,0(s4)
    8000493a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000493e:	000a3783          	ld	a5,0(s4)
    80004942:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004946:	000a3783          	ld	a5,0(s4)
    8000494a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000494e:	4501                	li	a0,0
    80004950:	a025                	j	80004978 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004952:	6088                	ld	a0,0(s1)
    80004954:	e501                	bnez	a0,8000495c <pipealloc+0xaa>
    80004956:	a039                	j	80004964 <pipealloc+0xb2>
    80004958:	6088                	ld	a0,0(s1)
    8000495a:	c51d                	beqz	a0,80004988 <pipealloc+0xd6>
    fileclose(*f0);
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	c00080e7          	jalr	-1024(ra) # 8000455c <fileclose>
  if(*f1)
    80004964:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004968:	557d                	li	a0,-1
  if(*f1)
    8000496a:	c799                	beqz	a5,80004978 <pipealloc+0xc6>
    fileclose(*f1);
    8000496c:	853e                	mv	a0,a5
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	bee080e7          	jalr	-1042(ra) # 8000455c <fileclose>
  return -1;
    80004976:	557d                	li	a0,-1
}
    80004978:	70a2                	ld	ra,40(sp)
    8000497a:	7402                	ld	s0,32(sp)
    8000497c:	64e2                	ld	s1,24(sp)
    8000497e:	6942                	ld	s2,16(sp)
    80004980:	69a2                	ld	s3,8(sp)
    80004982:	6a02                	ld	s4,0(sp)
    80004984:	6145                	addi	sp,sp,48
    80004986:	8082                	ret
  return -1;
    80004988:	557d                	li	a0,-1
    8000498a:	b7fd                	j	80004978 <pipealloc+0xc6>

000000008000498c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000498c:	1101                	addi	sp,sp,-32
    8000498e:	ec06                	sd	ra,24(sp)
    80004990:	e822                	sd	s0,16(sp)
    80004992:	e426                	sd	s1,8(sp)
    80004994:	e04a                	sd	s2,0(sp)
    80004996:	1000                	addi	s0,sp,32
    80004998:	84aa                	mv	s1,a0
    8000499a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	264080e7          	jalr	612(ra) # 80000c00 <acquire>
  if(writable){
    800049a4:	02090d63          	beqz	s2,800049de <pipeclose+0x52>
    pi->writeopen = 0;
    800049a8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049ac:	21848513          	addi	a0,s1,536
    800049b0:	ffffe097          	auipc	ra,0xffffe
    800049b4:	9b8080e7          	jalr	-1608(ra) # 80002368 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049b8:	2204b783          	ld	a5,544(s1)
    800049bc:	eb95                	bnez	a5,800049f0 <pipeclose+0x64>
    release(&pi->lock);
    800049be:	8526                	mv	a0,s1
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	2f4080e7          	jalr	756(ra) # 80000cb4 <release>
    kfree((char*)pi);
    800049c8:	8526                	mv	a0,s1
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	048080e7          	jalr	72(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800049d2:	60e2                	ld	ra,24(sp)
    800049d4:	6442                	ld	s0,16(sp)
    800049d6:	64a2                	ld	s1,8(sp)
    800049d8:	6902                	ld	s2,0(sp)
    800049da:	6105                	addi	sp,sp,32
    800049dc:	8082                	ret
    pi->readopen = 0;
    800049de:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049e2:	21c48513          	addi	a0,s1,540
    800049e6:	ffffe097          	auipc	ra,0xffffe
    800049ea:	982080e7          	jalr	-1662(ra) # 80002368 <wakeup>
    800049ee:	b7e9                	j	800049b8 <pipeclose+0x2c>
    release(&pi->lock);
    800049f0:	8526                	mv	a0,s1
    800049f2:	ffffc097          	auipc	ra,0xffffc
    800049f6:	2c2080e7          	jalr	706(ra) # 80000cb4 <release>
}
    800049fa:	bfe1                	j	800049d2 <pipeclose+0x46>

00000000800049fc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049fc:	711d                	addi	sp,sp,-96
    800049fe:	ec86                	sd	ra,88(sp)
    80004a00:	e8a2                	sd	s0,80(sp)
    80004a02:	e4a6                	sd	s1,72(sp)
    80004a04:	e0ca                	sd	s2,64(sp)
    80004a06:	fc4e                	sd	s3,56(sp)
    80004a08:	f852                	sd	s4,48(sp)
    80004a0a:	f456                	sd	s5,40(sp)
    80004a0c:	f05a                	sd	s6,32(sp)
    80004a0e:	ec5e                	sd	s7,24(sp)
    80004a10:	e862                	sd	s8,16(sp)
    80004a12:	1080                	addi	s0,sp,96
    80004a14:	84aa                	mv	s1,a0
    80004a16:	8b2e                	mv	s6,a1
    80004a18:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a1a:	ffffd097          	auipc	ra,0xffffd
    80004a1e:	fb2080e7          	jalr	-78(ra) # 800019cc <myproc>
    80004a22:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a24:	8526                	mv	a0,s1
    80004a26:	ffffc097          	auipc	ra,0xffffc
    80004a2a:	1da080e7          	jalr	474(ra) # 80000c00 <acquire>
  for(i = 0; i < n; i++){
    80004a2e:	09505863          	blez	s5,80004abe <pipewrite+0xc2>
    80004a32:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a34:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a38:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a3c:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a3e:	2184a783          	lw	a5,536(s1)
    80004a42:	21c4a703          	lw	a4,540(s1)
    80004a46:	2007879b          	addiw	a5,a5,512
    80004a4a:	02f71b63          	bne	a4,a5,80004a80 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004a4e:	2204a783          	lw	a5,544(s1)
    80004a52:	c3d9                	beqz	a5,80004ad8 <pipewrite+0xdc>
    80004a54:	03092783          	lw	a5,48(s2)
    80004a58:	e3c1                	bnez	a5,80004ad8 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004a5a:	8552                	mv	a0,s4
    80004a5c:	ffffe097          	auipc	ra,0xffffe
    80004a60:	90c080e7          	jalr	-1780(ra) # 80002368 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a64:	85a6                	mv	a1,s1
    80004a66:	854e                	mv	a0,s3
    80004a68:	ffffd097          	auipc	ra,0xffffd
    80004a6c:	780080e7          	jalr	1920(ra) # 800021e8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a70:	2184a783          	lw	a5,536(s1)
    80004a74:	21c4a703          	lw	a4,540(s1)
    80004a78:	2007879b          	addiw	a5,a5,512
    80004a7c:	fcf709e3          	beq	a4,a5,80004a4e <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a80:	4685                	li	a3,1
    80004a82:	865a                	mv	a2,s6
    80004a84:	faf40593          	addi	a1,s0,-81
    80004a88:	05093503          	ld	a0,80(s2)
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	cc2080e7          	jalr	-830(ra) # 8000174e <copyin>
    80004a94:	03850663          	beq	a0,s8,80004ac0 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a98:	21c4a783          	lw	a5,540(s1)
    80004a9c:	0017871b          	addiw	a4,a5,1
    80004aa0:	20e4ae23          	sw	a4,540(s1)
    80004aa4:	1ff7f793          	andi	a5,a5,511
    80004aa8:	97a6                	add	a5,a5,s1
    80004aaa:	faf44703          	lbu	a4,-81(s0)
    80004aae:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004ab2:	2b85                	addiw	s7,s7,1
    80004ab4:	0b05                	addi	s6,s6,1
    80004ab6:	f97a94e3          	bne	s5,s7,80004a3e <pipewrite+0x42>
    80004aba:	8bd6                	mv	s7,s5
    80004abc:	a011                	j	80004ac0 <pipewrite+0xc4>
    80004abe:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004ac0:	21848513          	addi	a0,s1,536
    80004ac4:	ffffe097          	auipc	ra,0xffffe
    80004ac8:	8a4080e7          	jalr	-1884(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	1e6080e7          	jalr	486(ra) # 80000cb4 <release>
  return i;
    80004ad6:	a039                	j	80004ae4 <pipewrite+0xe8>
        release(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1da080e7          	jalr	474(ra) # 80000cb4 <release>
        return -1;
    80004ae2:	5bfd                	li	s7,-1
}
    80004ae4:	855e                	mv	a0,s7
    80004ae6:	60e6                	ld	ra,88(sp)
    80004ae8:	6446                	ld	s0,80(sp)
    80004aea:	64a6                	ld	s1,72(sp)
    80004aec:	6906                	ld	s2,64(sp)
    80004aee:	79e2                	ld	s3,56(sp)
    80004af0:	7a42                	ld	s4,48(sp)
    80004af2:	7aa2                	ld	s5,40(sp)
    80004af4:	7b02                	ld	s6,32(sp)
    80004af6:	6be2                	ld	s7,24(sp)
    80004af8:	6c42                	ld	s8,16(sp)
    80004afa:	6125                	addi	sp,sp,96
    80004afc:	8082                	ret

0000000080004afe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004afe:	715d                	addi	sp,sp,-80
    80004b00:	e486                	sd	ra,72(sp)
    80004b02:	e0a2                	sd	s0,64(sp)
    80004b04:	fc26                	sd	s1,56(sp)
    80004b06:	f84a                	sd	s2,48(sp)
    80004b08:	f44e                	sd	s3,40(sp)
    80004b0a:	f052                	sd	s4,32(sp)
    80004b0c:	ec56                	sd	s5,24(sp)
    80004b0e:	e85a                	sd	s6,16(sp)
    80004b10:	0880                	addi	s0,sp,80
    80004b12:	84aa                	mv	s1,a0
    80004b14:	892e                	mv	s2,a1
    80004b16:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b18:	ffffd097          	auipc	ra,0xffffd
    80004b1c:	eb4080e7          	jalr	-332(ra) # 800019cc <myproc>
    80004b20:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b22:	8526                	mv	a0,s1
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	0dc080e7          	jalr	220(ra) # 80000c00 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b2c:	2184a703          	lw	a4,536(s1)
    80004b30:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b34:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b38:	02f71463          	bne	a4,a5,80004b60 <piperead+0x62>
    80004b3c:	2244a783          	lw	a5,548(s1)
    80004b40:	c385                	beqz	a5,80004b60 <piperead+0x62>
    if(pr->killed){
    80004b42:	030a2783          	lw	a5,48(s4)
    80004b46:	ebc9                	bnez	a5,80004bd8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b48:	85a6                	mv	a1,s1
    80004b4a:	854e                	mv	a0,s3
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	69c080e7          	jalr	1692(ra) # 800021e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b54:	2184a703          	lw	a4,536(s1)
    80004b58:	21c4a783          	lw	a5,540(s1)
    80004b5c:	fef700e3          	beq	a4,a5,80004b3c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b60:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b62:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b64:	05505463          	blez	s5,80004bac <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004b68:	2184a783          	lw	a5,536(s1)
    80004b6c:	21c4a703          	lw	a4,540(s1)
    80004b70:	02f70e63          	beq	a4,a5,80004bac <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b74:	0017871b          	addiw	a4,a5,1
    80004b78:	20e4ac23          	sw	a4,536(s1)
    80004b7c:	1ff7f793          	andi	a5,a5,511
    80004b80:	97a6                	add	a5,a5,s1
    80004b82:	0187c783          	lbu	a5,24(a5)
    80004b86:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b8a:	4685                	li	a3,1
    80004b8c:	fbf40613          	addi	a2,s0,-65
    80004b90:	85ca                	mv	a1,s2
    80004b92:	050a3503          	ld	a0,80(s4)
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	b2c080e7          	jalr	-1236(ra) # 800016c2 <copyout>
    80004b9e:	01650763          	beq	a0,s6,80004bac <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ba2:	2985                	addiw	s3,s3,1
    80004ba4:	0905                	addi	s2,s2,1
    80004ba6:	fd3a91e3          	bne	s5,s3,80004b68 <piperead+0x6a>
    80004baa:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bac:	21c48513          	addi	a0,s1,540
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	7b8080e7          	jalr	1976(ra) # 80002368 <wakeup>
  release(&pi->lock);
    80004bb8:	8526                	mv	a0,s1
    80004bba:	ffffc097          	auipc	ra,0xffffc
    80004bbe:	0fa080e7          	jalr	250(ra) # 80000cb4 <release>
  return i;
}
    80004bc2:	854e                	mv	a0,s3
    80004bc4:	60a6                	ld	ra,72(sp)
    80004bc6:	6406                	ld	s0,64(sp)
    80004bc8:	74e2                	ld	s1,56(sp)
    80004bca:	7942                	ld	s2,48(sp)
    80004bcc:	79a2                	ld	s3,40(sp)
    80004bce:	7a02                	ld	s4,32(sp)
    80004bd0:	6ae2                	ld	s5,24(sp)
    80004bd2:	6b42                	ld	s6,16(sp)
    80004bd4:	6161                	addi	sp,sp,80
    80004bd6:	8082                	ret
      release(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	0da080e7          	jalr	218(ra) # 80000cb4 <release>
      return -1;
    80004be2:	59fd                	li	s3,-1
    80004be4:	bff9                	j	80004bc2 <piperead+0xc4>

0000000080004be6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004be6:	de010113          	addi	sp,sp,-544
    80004bea:	20113c23          	sd	ra,536(sp)
    80004bee:	20813823          	sd	s0,528(sp)
    80004bf2:	20913423          	sd	s1,520(sp)
    80004bf6:	21213023          	sd	s2,512(sp)
    80004bfa:	ffce                	sd	s3,504(sp)
    80004bfc:	fbd2                	sd	s4,496(sp)
    80004bfe:	f7d6                	sd	s5,488(sp)
    80004c00:	f3da                	sd	s6,480(sp)
    80004c02:	efde                	sd	s7,472(sp)
    80004c04:	ebe2                	sd	s8,464(sp)
    80004c06:	e7e6                	sd	s9,456(sp)
    80004c08:	e3ea                	sd	s10,448(sp)
    80004c0a:	ff6e                	sd	s11,440(sp)
    80004c0c:	1400                	addi	s0,sp,544
    80004c0e:	892a                	mv	s2,a0
    80004c10:	dea43423          	sd	a0,-536(s0)
    80004c14:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c18:	ffffd097          	auipc	ra,0xffffd
    80004c1c:	db4080e7          	jalr	-588(ra) # 800019cc <myproc>
    80004c20:	84aa                	mv	s1,a0

  begin_op();
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	46c080e7          	jalr	1132(ra) # 8000408e <begin_op>

  if((ip = namei(path)) == 0){
    80004c2a:	854a                	mv	a0,s2
    80004c2c:	fffff097          	auipc	ra,0xfffff
    80004c30:	252080e7          	jalr	594(ra) # 80003e7e <namei>
    80004c34:	c93d                	beqz	a0,80004caa <exec+0xc4>
    80004c36:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c38:	fffff097          	auipc	ra,0xfffff
    80004c3c:	a90080e7          	jalr	-1392(ra) # 800036c8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c40:	04000713          	li	a4,64
    80004c44:	4681                	li	a3,0
    80004c46:	e4840613          	addi	a2,s0,-440
    80004c4a:	4581                	li	a1,0
    80004c4c:	8556                	mv	a0,s5
    80004c4e:	fffff097          	auipc	ra,0xfffff
    80004c52:	d2e080e7          	jalr	-722(ra) # 8000397c <readi>
    80004c56:	04000793          	li	a5,64
    80004c5a:	00f51a63          	bne	a0,a5,80004c6e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c5e:	e4842703          	lw	a4,-440(s0)
    80004c62:	464c47b7          	lui	a5,0x464c4
    80004c66:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c6a:	04f70663          	beq	a4,a5,80004cb6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c6e:	8556                	mv	a0,s5
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	cba080e7          	jalr	-838(ra) # 8000392a <iunlockput>
    end_op();
    80004c78:	fffff097          	auipc	ra,0xfffff
    80004c7c:	494080e7          	jalr	1172(ra) # 8000410c <end_op>
  }
  return -1;
    80004c80:	557d                	li	a0,-1
}
    80004c82:	21813083          	ld	ra,536(sp)
    80004c86:	21013403          	ld	s0,528(sp)
    80004c8a:	20813483          	ld	s1,520(sp)
    80004c8e:	20013903          	ld	s2,512(sp)
    80004c92:	79fe                	ld	s3,504(sp)
    80004c94:	7a5e                	ld	s4,496(sp)
    80004c96:	7abe                	ld	s5,488(sp)
    80004c98:	7b1e                	ld	s6,480(sp)
    80004c9a:	6bfe                	ld	s7,472(sp)
    80004c9c:	6c5e                	ld	s8,464(sp)
    80004c9e:	6cbe                	ld	s9,456(sp)
    80004ca0:	6d1e                	ld	s10,448(sp)
    80004ca2:	7dfa                	ld	s11,440(sp)
    80004ca4:	22010113          	addi	sp,sp,544
    80004ca8:	8082                	ret
    end_op();
    80004caa:	fffff097          	auipc	ra,0xfffff
    80004cae:	462080e7          	jalr	1122(ra) # 8000410c <end_op>
    return -1;
    80004cb2:	557d                	li	a0,-1
    80004cb4:	b7f9                	j	80004c82 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffd097          	auipc	ra,0xffffd
    80004cbc:	dd8080e7          	jalr	-552(ra) # 80001a90 <proc_pagetable>
    80004cc0:	8b2a                	mv	s6,a0
    80004cc2:	d555                	beqz	a0,80004c6e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc4:	e6842783          	lw	a5,-408(s0)
    80004cc8:	e8045703          	lhu	a4,-384(s0)
    80004ccc:	c735                	beqz	a4,80004d38 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cce:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cd0:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cd4:	6a05                	lui	s4,0x1
    80004cd6:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cda:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cde:	6d85                	lui	s11,0x1
    80004ce0:	7d7d                	lui	s10,0xfffff
    80004ce2:	ac1d                	j	80004f18 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ce4:	00004517          	auipc	a0,0x4
    80004ce8:	aac50513          	addi	a0,a0,-1364 # 80008790 <syscalls+0x2a8>
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	85a080e7          	jalr	-1958(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cf4:	874a                	mv	a4,s2
    80004cf6:	009c86bb          	addw	a3,s9,s1
    80004cfa:	4581                	li	a1,0
    80004cfc:	8556                	mv	a0,s5
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	c7e080e7          	jalr	-898(ra) # 8000397c <readi>
    80004d06:	2501                	sext.w	a0,a0
    80004d08:	1aa91863          	bne	s2,a0,80004eb8 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d0c:	009d84bb          	addw	s1,s11,s1
    80004d10:	013d09bb          	addw	s3,s10,s3
    80004d14:	1f74f263          	bgeu	s1,s7,80004ef8 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d18:	02049593          	slli	a1,s1,0x20
    80004d1c:	9181                	srli	a1,a1,0x20
    80004d1e:	95e2                	add	a1,a1,s8
    80004d20:	855a                	mv	a0,s6
    80004d22:	ffffc097          	auipc	ra,0xffffc
    80004d26:	368080e7          	jalr	872(ra) # 8000108a <walkaddr>
    80004d2a:	862a                	mv	a2,a0
    if(pa == 0)
    80004d2c:	dd45                	beqz	a0,80004ce4 <exec+0xfe>
      n = PGSIZE;
    80004d2e:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d30:	fd49f2e3          	bgeu	s3,s4,80004cf4 <exec+0x10e>
      n = sz - i;
    80004d34:	894e                	mv	s2,s3
    80004d36:	bf7d                	j	80004cf4 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d38:	4481                	li	s1,0
  iunlockput(ip);
    80004d3a:	8556                	mv	a0,s5
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	bee080e7          	jalr	-1042(ra) # 8000392a <iunlockput>
  end_op();
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	3c8080e7          	jalr	968(ra) # 8000410c <end_op>
  p = myproc();
    80004d4c:	ffffd097          	auipc	ra,0xffffd
    80004d50:	c80080e7          	jalr	-896(ra) # 800019cc <myproc>
    80004d54:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d56:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d5a:	6785                	lui	a5,0x1
    80004d5c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d5e:	97a6                	add	a5,a5,s1
    80004d60:	777d                	lui	a4,0xfffff
    80004d62:	8ff9                	and	a5,a5,a4
    80004d64:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d68:	6609                	lui	a2,0x2
    80004d6a:	963e                	add	a2,a2,a5
    80004d6c:	85be                	mv	a1,a5
    80004d6e:	855a                	mv	a0,s6
    80004d70:	ffffc097          	auipc	ra,0xffffc
    80004d74:	6fe080e7          	jalr	1790(ra) # 8000146e <uvmalloc>
    80004d78:	8c2a                	mv	s8,a0
  ip = 0;
    80004d7a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d7c:	12050e63          	beqz	a0,80004eb8 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d80:	75f9                	lui	a1,0xffffe
    80004d82:	95aa                	add	a1,a1,a0
    80004d84:	855a                	mv	a0,s6
    80004d86:	ffffd097          	auipc	ra,0xffffd
    80004d8a:	90a080e7          	jalr	-1782(ra) # 80001690 <uvmclear>
  stackbase = sp - PGSIZE;
    80004d8e:	7afd                	lui	s5,0xfffff
    80004d90:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d92:	df043783          	ld	a5,-528(s0)
    80004d96:	6388                	ld	a0,0(a5)
    80004d98:	c925                	beqz	a0,80004e08 <exec+0x222>
    80004d9a:	e8840993          	addi	s3,s0,-376
    80004d9e:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004da2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004da4:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	0da080e7          	jalr	218(ra) # 80000e80 <strlen>
    80004dae:	0015079b          	addiw	a5,a0,1
    80004db2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004db6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004dba:	13596363          	bltu	s2,s5,80004ee0 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004dbe:	df043d83          	ld	s11,-528(s0)
    80004dc2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dc6:	8552                	mv	a0,s4
    80004dc8:	ffffc097          	auipc	ra,0xffffc
    80004dcc:	0b8080e7          	jalr	184(ra) # 80000e80 <strlen>
    80004dd0:	0015069b          	addiw	a3,a0,1
    80004dd4:	8652                	mv	a2,s4
    80004dd6:	85ca                	mv	a1,s2
    80004dd8:	855a                	mv	a0,s6
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	8e8080e7          	jalr	-1816(ra) # 800016c2 <copyout>
    80004de2:	10054363          	bltz	a0,80004ee8 <exec+0x302>
    ustack[argc] = sp;
    80004de6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dea:	0485                	addi	s1,s1,1
    80004dec:	008d8793          	addi	a5,s11,8
    80004df0:	def43823          	sd	a5,-528(s0)
    80004df4:	008db503          	ld	a0,8(s11)
    80004df8:	c911                	beqz	a0,80004e0c <exec+0x226>
    if(argc >= MAXARG)
    80004dfa:	09a1                	addi	s3,s3,8
    80004dfc:	fb3c95e3          	bne	s9,s3,80004da6 <exec+0x1c0>
  sz = sz1;
    80004e00:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e04:	4a81                	li	s5,0
    80004e06:	a84d                	j	80004eb8 <exec+0x2d2>
  sp = sz;
    80004e08:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e0a:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e0c:	00349793          	slli	a5,s1,0x3
    80004e10:	f9078793          	addi	a5,a5,-112
    80004e14:	97a2                	add	a5,a5,s0
    80004e16:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004e1a:	00148693          	addi	a3,s1,1
    80004e1e:	068e                	slli	a3,a3,0x3
    80004e20:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e24:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e28:	01597663          	bgeu	s2,s5,80004e34 <exec+0x24e>
  sz = sz1;
    80004e2c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e30:	4a81                	li	s5,0
    80004e32:	a059                	j	80004eb8 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e34:	e8840613          	addi	a2,s0,-376
    80004e38:	85ca                	mv	a1,s2
    80004e3a:	855a                	mv	a0,s6
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	886080e7          	jalr	-1914(ra) # 800016c2 <copyout>
    80004e44:	0a054663          	bltz	a0,80004ef0 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e48:	058bb783          	ld	a5,88(s7)
    80004e4c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e50:	de843783          	ld	a5,-536(s0)
    80004e54:	0007c703          	lbu	a4,0(a5)
    80004e58:	cf11                	beqz	a4,80004e74 <exec+0x28e>
    80004e5a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e5c:	02f00693          	li	a3,47
    80004e60:	a039                	j	80004e6e <exec+0x288>
      last = s+1;
    80004e62:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e66:	0785                	addi	a5,a5,1
    80004e68:	fff7c703          	lbu	a4,-1(a5)
    80004e6c:	c701                	beqz	a4,80004e74 <exec+0x28e>
    if(*s == '/')
    80004e6e:	fed71ce3          	bne	a4,a3,80004e66 <exec+0x280>
    80004e72:	bfc5                	j	80004e62 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e74:	4641                	li	a2,16
    80004e76:	de843583          	ld	a1,-536(s0)
    80004e7a:	158b8513          	addi	a0,s7,344
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	fd0080e7          	jalr	-48(ra) # 80000e4e <safestrcpy>
  oldpagetable = p->pagetable;
    80004e86:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e8a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e8e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e92:	058bb783          	ld	a5,88(s7)
    80004e96:	e6043703          	ld	a4,-416(s0)
    80004e9a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e9c:	058bb783          	ld	a5,88(s7)
    80004ea0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ea4:	85ea                	mv	a1,s10
    80004ea6:	ffffd097          	auipc	ra,0xffffd
    80004eaa:	c86080e7          	jalr	-890(ra) # 80001b2c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004eae:	0004851b          	sext.w	a0,s1
    80004eb2:	bbc1                	j	80004c82 <exec+0x9c>
    80004eb4:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004eb8:	df843583          	ld	a1,-520(s0)
    80004ebc:	855a                	mv	a0,s6
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	c6e080e7          	jalr	-914(ra) # 80001b2c <proc_freepagetable>
  if(ip){
    80004ec6:	da0a94e3          	bnez	s5,80004c6e <exec+0x88>
  return -1;
    80004eca:	557d                	li	a0,-1
    80004ecc:	bb5d                	j	80004c82 <exec+0x9c>
    80004ece:	de943c23          	sd	s1,-520(s0)
    80004ed2:	b7dd                	j	80004eb8 <exec+0x2d2>
    80004ed4:	de943c23          	sd	s1,-520(s0)
    80004ed8:	b7c5                	j	80004eb8 <exec+0x2d2>
    80004eda:	de943c23          	sd	s1,-520(s0)
    80004ede:	bfe9                	j	80004eb8 <exec+0x2d2>
  sz = sz1;
    80004ee0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ee4:	4a81                	li	s5,0
    80004ee6:	bfc9                	j	80004eb8 <exec+0x2d2>
  sz = sz1;
    80004ee8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eec:	4a81                	li	s5,0
    80004eee:	b7e9                	j	80004eb8 <exec+0x2d2>
  sz = sz1;
    80004ef0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef4:	4a81                	li	s5,0
    80004ef6:	b7c9                	j	80004eb8 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ef8:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004efc:	e0843783          	ld	a5,-504(s0)
    80004f00:	0017869b          	addiw	a3,a5,1
    80004f04:	e0d43423          	sd	a3,-504(s0)
    80004f08:	e0043783          	ld	a5,-512(s0)
    80004f0c:	0387879b          	addiw	a5,a5,56
    80004f10:	e8045703          	lhu	a4,-384(s0)
    80004f14:	e2e6d3e3          	bge	a3,a4,80004d3a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f18:	2781                	sext.w	a5,a5
    80004f1a:	e0f43023          	sd	a5,-512(s0)
    80004f1e:	03800713          	li	a4,56
    80004f22:	86be                	mv	a3,a5
    80004f24:	e1040613          	addi	a2,s0,-496
    80004f28:	4581                	li	a1,0
    80004f2a:	8556                	mv	a0,s5
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	a50080e7          	jalr	-1456(ra) # 8000397c <readi>
    80004f34:	03800793          	li	a5,56
    80004f38:	f6f51ee3          	bne	a0,a5,80004eb4 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f3c:	e1042783          	lw	a5,-496(s0)
    80004f40:	4705                	li	a4,1
    80004f42:	fae79de3          	bne	a5,a4,80004efc <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f46:	e3843603          	ld	a2,-456(s0)
    80004f4a:	e3043783          	ld	a5,-464(s0)
    80004f4e:	f8f660e3          	bltu	a2,a5,80004ece <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f52:	e2043783          	ld	a5,-480(s0)
    80004f56:	963e                	add	a2,a2,a5
    80004f58:	f6f66ee3          	bltu	a2,a5,80004ed4 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f5c:	85a6                	mv	a1,s1
    80004f5e:	855a                	mv	a0,s6
    80004f60:	ffffc097          	auipc	ra,0xffffc
    80004f64:	50e080e7          	jalr	1294(ra) # 8000146e <uvmalloc>
    80004f68:	dea43c23          	sd	a0,-520(s0)
    80004f6c:	d53d                	beqz	a0,80004eda <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f6e:	e2043c03          	ld	s8,-480(s0)
    80004f72:	de043783          	ld	a5,-544(s0)
    80004f76:	00fc77b3          	and	a5,s8,a5
    80004f7a:	ff9d                	bnez	a5,80004eb8 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f7c:	e1842c83          	lw	s9,-488(s0)
    80004f80:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f84:	f60b8ae3          	beqz	s7,80004ef8 <exec+0x312>
    80004f88:	89de                	mv	s3,s7
    80004f8a:	4481                	li	s1,0
    80004f8c:	b371                	j	80004d18 <exec+0x132>

0000000080004f8e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f8e:	7179                	addi	sp,sp,-48
    80004f90:	f406                	sd	ra,40(sp)
    80004f92:	f022                	sd	s0,32(sp)
    80004f94:	ec26                	sd	s1,24(sp)
    80004f96:	e84a                	sd	s2,16(sp)
    80004f98:	1800                	addi	s0,sp,48
    80004f9a:	892e                	mv	s2,a1
    80004f9c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f9e:	fdc40593          	addi	a1,s0,-36
    80004fa2:	ffffe097          	auipc	ra,0xffffe
    80004fa6:	b12080e7          	jalr	-1262(ra) # 80002ab4 <argint>
    80004faa:	04054063          	bltz	a0,80004fea <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fae:	fdc42703          	lw	a4,-36(s0)
    80004fb2:	47bd                	li	a5,15
    80004fb4:	02e7ed63          	bltu	a5,a4,80004fee <argfd+0x60>
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	a14080e7          	jalr	-1516(ra) # 800019cc <myproc>
    80004fc0:	fdc42703          	lw	a4,-36(s0)
    80004fc4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    80004fc8:	078e                	slli	a5,a5,0x3
    80004fca:	953e                	add	a0,a0,a5
    80004fcc:	611c                	ld	a5,0(a0)
    80004fce:	c395                	beqz	a5,80004ff2 <argfd+0x64>
    return -1;
  if(pfd)
    80004fd0:	00090463          	beqz	s2,80004fd8 <argfd+0x4a>
    *pfd = fd;
    80004fd4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fd8:	4501                	li	a0,0
  if(pf)
    80004fda:	c091                	beqz	s1,80004fde <argfd+0x50>
    *pf = f;
    80004fdc:	e09c                	sd	a5,0(s1)
}
    80004fde:	70a2                	ld	ra,40(sp)
    80004fe0:	7402                	ld	s0,32(sp)
    80004fe2:	64e2                	ld	s1,24(sp)
    80004fe4:	6942                	ld	s2,16(sp)
    80004fe6:	6145                	addi	sp,sp,48
    80004fe8:	8082                	ret
    return -1;
    80004fea:	557d                	li	a0,-1
    80004fec:	bfcd                	j	80004fde <argfd+0x50>
    return -1;
    80004fee:	557d                	li	a0,-1
    80004ff0:	b7fd                	j	80004fde <argfd+0x50>
    80004ff2:	557d                	li	a0,-1
    80004ff4:	b7ed                	j	80004fde <argfd+0x50>

0000000080004ff6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004ff6:	1101                	addi	sp,sp,-32
    80004ff8:	ec06                	sd	ra,24(sp)
    80004ffa:	e822                	sd	s0,16(sp)
    80004ffc:	e426                	sd	s1,8(sp)
    80004ffe:	1000                	addi	s0,sp,32
    80005000:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005002:	ffffd097          	auipc	ra,0xffffd
    80005006:	9ca080e7          	jalr	-1590(ra) # 800019cc <myproc>
    8000500a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000500c:	0d050793          	addi	a5,a0,208
    80005010:	4501                	li	a0,0
    80005012:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005014:	6398                	ld	a4,0(a5)
    80005016:	cb19                	beqz	a4,8000502c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005018:	2505                	addiw	a0,a0,1
    8000501a:	07a1                	addi	a5,a5,8
    8000501c:	fed51ce3          	bne	a0,a3,80005014 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005020:	557d                	li	a0,-1
}
    80005022:	60e2                	ld	ra,24(sp)
    80005024:	6442                	ld	s0,16(sp)
    80005026:	64a2                	ld	s1,8(sp)
    80005028:	6105                	addi	sp,sp,32
    8000502a:	8082                	ret
      p->ofile[fd] = f;
    8000502c:	01a50793          	addi	a5,a0,26
    80005030:	078e                	slli	a5,a5,0x3
    80005032:	963e                	add	a2,a2,a5
    80005034:	e204                	sd	s1,0(a2)
      return fd;
    80005036:	b7f5                	j	80005022 <fdalloc+0x2c>

0000000080005038 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005038:	715d                	addi	sp,sp,-80
    8000503a:	e486                	sd	ra,72(sp)
    8000503c:	e0a2                	sd	s0,64(sp)
    8000503e:	fc26                	sd	s1,56(sp)
    80005040:	f84a                	sd	s2,48(sp)
    80005042:	f44e                	sd	s3,40(sp)
    80005044:	f052                	sd	s4,32(sp)
    80005046:	ec56                	sd	s5,24(sp)
    80005048:	0880                	addi	s0,sp,80
    8000504a:	89ae                	mv	s3,a1
    8000504c:	8ab2                	mv	s5,a2
    8000504e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005050:	fb040593          	addi	a1,s0,-80
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	e48080e7          	jalr	-440(ra) # 80003e9c <nameiparent>
    8000505c:	892a                	mv	s2,a0
    8000505e:	12050e63          	beqz	a0,8000519a <create+0x162>
    return 0;

  ilock(dp);
    80005062:	ffffe097          	auipc	ra,0xffffe
    80005066:	666080e7          	jalr	1638(ra) # 800036c8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000506a:	4601                	li	a2,0
    8000506c:	fb040593          	addi	a1,s0,-80
    80005070:	854a                	mv	a0,s2
    80005072:	fffff097          	auipc	ra,0xfffff
    80005076:	b34080e7          	jalr	-1228(ra) # 80003ba6 <dirlookup>
    8000507a:	84aa                	mv	s1,a0
    8000507c:	c921                	beqz	a0,800050cc <create+0x94>
    iunlockput(dp);
    8000507e:	854a                	mv	a0,s2
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	8aa080e7          	jalr	-1878(ra) # 8000392a <iunlockput>
    ilock(ip);
    80005088:	8526                	mv	a0,s1
    8000508a:	ffffe097          	auipc	ra,0xffffe
    8000508e:	63e080e7          	jalr	1598(ra) # 800036c8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005092:	2981                	sext.w	s3,s3
    80005094:	4789                	li	a5,2
    80005096:	02f99463          	bne	s3,a5,800050be <create+0x86>
    8000509a:	0444d783          	lhu	a5,68(s1)
    8000509e:	37f9                	addiw	a5,a5,-2
    800050a0:	17c2                	slli	a5,a5,0x30
    800050a2:	93c1                	srli	a5,a5,0x30
    800050a4:	4705                	li	a4,1
    800050a6:	00f76c63          	bltu	a4,a5,800050be <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050aa:	8526                	mv	a0,s1
    800050ac:	60a6                	ld	ra,72(sp)
    800050ae:	6406                	ld	s0,64(sp)
    800050b0:	74e2                	ld	s1,56(sp)
    800050b2:	7942                	ld	s2,48(sp)
    800050b4:	79a2                	ld	s3,40(sp)
    800050b6:	7a02                	ld	s4,32(sp)
    800050b8:	6ae2                	ld	s5,24(sp)
    800050ba:	6161                	addi	sp,sp,80
    800050bc:	8082                	ret
    iunlockput(ip);
    800050be:	8526                	mv	a0,s1
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	86a080e7          	jalr	-1942(ra) # 8000392a <iunlockput>
    return 0;
    800050c8:	4481                	li	s1,0
    800050ca:	b7c5                	j	800050aa <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050cc:	85ce                	mv	a1,s3
    800050ce:	00092503          	lw	a0,0(s2)
    800050d2:	ffffe097          	auipc	ra,0xffffe
    800050d6:	45c080e7          	jalr	1116(ra) # 8000352e <ialloc>
    800050da:	84aa                	mv	s1,a0
    800050dc:	c521                	beqz	a0,80005124 <create+0xec>
  ilock(ip);
    800050de:	ffffe097          	auipc	ra,0xffffe
    800050e2:	5ea080e7          	jalr	1514(ra) # 800036c8 <ilock>
  ip->major = major;
    800050e6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050ea:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050ee:	4a05                	li	s4,1
    800050f0:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050f4:	8526                	mv	a0,s1
    800050f6:	ffffe097          	auipc	ra,0xffffe
    800050fa:	506080e7          	jalr	1286(ra) # 800035fc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050fe:	2981                	sext.w	s3,s3
    80005100:	03498a63          	beq	s3,s4,80005134 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005104:	40d0                	lw	a2,4(s1)
    80005106:	fb040593          	addi	a1,s0,-80
    8000510a:	854a                	mv	a0,s2
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	cb0080e7          	jalr	-848(ra) # 80003dbc <dirlink>
    80005114:	06054b63          	bltz	a0,8000518a <create+0x152>
  iunlockput(dp);
    80005118:	854a                	mv	a0,s2
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	810080e7          	jalr	-2032(ra) # 8000392a <iunlockput>
  return ip;
    80005122:	b761                	j	800050aa <create+0x72>
    panic("create: ialloc");
    80005124:	00003517          	auipc	a0,0x3
    80005128:	68c50513          	addi	a0,a0,1676 # 800087b0 <syscalls+0x2c8>
    8000512c:	ffffb097          	auipc	ra,0xffffb
    80005130:	41a080e7          	jalr	1050(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    80005134:	04a95783          	lhu	a5,74(s2)
    80005138:	2785                	addiw	a5,a5,1
    8000513a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000513e:	854a                	mv	a0,s2
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	4bc080e7          	jalr	1212(ra) # 800035fc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005148:	40d0                	lw	a2,4(s1)
    8000514a:	00003597          	auipc	a1,0x3
    8000514e:	67658593          	addi	a1,a1,1654 # 800087c0 <syscalls+0x2d8>
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	c68080e7          	jalr	-920(ra) # 80003dbc <dirlink>
    8000515c:	00054f63          	bltz	a0,8000517a <create+0x142>
    80005160:	00492603          	lw	a2,4(s2)
    80005164:	00003597          	auipc	a1,0x3
    80005168:	66458593          	addi	a1,a1,1636 # 800087c8 <syscalls+0x2e0>
    8000516c:	8526                	mv	a0,s1
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	c4e080e7          	jalr	-946(ra) # 80003dbc <dirlink>
    80005176:	f80557e3          	bgez	a0,80005104 <create+0xcc>
      panic("create dots");
    8000517a:	00003517          	auipc	a0,0x3
    8000517e:	65650513          	addi	a0,a0,1622 # 800087d0 <syscalls+0x2e8>
    80005182:	ffffb097          	auipc	ra,0xffffb
    80005186:	3c4080e7          	jalr	964(ra) # 80000546 <panic>
    panic("create: dirlink");
    8000518a:	00003517          	auipc	a0,0x3
    8000518e:	65650513          	addi	a0,a0,1622 # 800087e0 <syscalls+0x2f8>
    80005192:	ffffb097          	auipc	ra,0xffffb
    80005196:	3b4080e7          	jalr	948(ra) # 80000546 <panic>
    return 0;
    8000519a:	84aa                	mv	s1,a0
    8000519c:	b739                	j	800050aa <create+0x72>

000000008000519e <sys_dup>:
{
    8000519e:	7179                	addi	sp,sp,-48
    800051a0:	f406                	sd	ra,40(sp)
    800051a2:	f022                	sd	s0,32(sp)
    800051a4:	ec26                	sd	s1,24(sp)
    800051a6:	e84a                	sd	s2,16(sp)
    800051a8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051aa:	fd840613          	addi	a2,s0,-40
    800051ae:	4581                	li	a1,0
    800051b0:	4501                	li	a0,0
    800051b2:	00000097          	auipc	ra,0x0
    800051b6:	ddc080e7          	jalr	-548(ra) # 80004f8e <argfd>
    return -1;
    800051ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051bc:	02054363          	bltz	a0,800051e2 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051c0:	fd843903          	ld	s2,-40(s0)
    800051c4:	854a                	mv	a0,s2
    800051c6:	00000097          	auipc	ra,0x0
    800051ca:	e30080e7          	jalr	-464(ra) # 80004ff6 <fdalloc>
    800051ce:	84aa                	mv	s1,a0
    return -1;
    800051d0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051d2:	00054863          	bltz	a0,800051e2 <sys_dup+0x44>
  filedup(f);
    800051d6:	854a                	mv	a0,s2
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	332080e7          	jalr	818(ra) # 8000450a <filedup>
  return fd;
    800051e0:	87a6                	mv	a5,s1
}
    800051e2:	853e                	mv	a0,a5
    800051e4:	70a2                	ld	ra,40(sp)
    800051e6:	7402                	ld	s0,32(sp)
    800051e8:	64e2                	ld	s1,24(sp)
    800051ea:	6942                	ld	s2,16(sp)
    800051ec:	6145                	addi	sp,sp,48
    800051ee:	8082                	ret

00000000800051f0 <sys_read>:
{
    800051f0:	7179                	addi	sp,sp,-48
    800051f2:	f406                	sd	ra,40(sp)
    800051f4:	f022                	sd	s0,32(sp)
    800051f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051f8:	fe840613          	addi	a2,s0,-24
    800051fc:	4581                	li	a1,0
    800051fe:	4501                	li	a0,0
    80005200:	00000097          	auipc	ra,0x0
    80005204:	d8e080e7          	jalr	-626(ra) # 80004f8e <argfd>
    return -1;
    80005208:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000520a:	04054163          	bltz	a0,8000524c <sys_read+0x5c>
    8000520e:	fe440593          	addi	a1,s0,-28
    80005212:	4509                	li	a0,2
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	8a0080e7          	jalr	-1888(ra) # 80002ab4 <argint>
    return -1;
    8000521c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000521e:	02054763          	bltz	a0,8000524c <sys_read+0x5c>
    80005222:	fd840593          	addi	a1,s0,-40
    80005226:	4505                	li	a0,1
    80005228:	ffffe097          	auipc	ra,0xffffe
    8000522c:	8ae080e7          	jalr	-1874(ra) # 80002ad6 <argaddr>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005232:	00054d63          	bltz	a0,8000524c <sys_read+0x5c>
  return fileread(f, p, n);
    80005236:	fe442603          	lw	a2,-28(s0)
    8000523a:	fd843583          	ld	a1,-40(s0)
    8000523e:	fe843503          	ld	a0,-24(s0)
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	454080e7          	jalr	1108(ra) # 80004696 <fileread>
    8000524a:	87aa                	mv	a5,a0
}
    8000524c:	853e                	mv	a0,a5
    8000524e:	70a2                	ld	ra,40(sp)
    80005250:	7402                	ld	s0,32(sp)
    80005252:	6145                	addi	sp,sp,48
    80005254:	8082                	ret

0000000080005256 <sys_write>:
{
    80005256:	7179                	addi	sp,sp,-48
    80005258:	f406                	sd	ra,40(sp)
    8000525a:	f022                	sd	s0,32(sp)
    8000525c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000525e:	fe840613          	addi	a2,s0,-24
    80005262:	4581                	li	a1,0
    80005264:	4501                	li	a0,0
    80005266:	00000097          	auipc	ra,0x0
    8000526a:	d28080e7          	jalr	-728(ra) # 80004f8e <argfd>
    return -1;
    8000526e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005270:	04054163          	bltz	a0,800052b2 <sys_write+0x5c>
    80005274:	fe440593          	addi	a1,s0,-28
    80005278:	4509                	li	a0,2
    8000527a:	ffffe097          	auipc	ra,0xffffe
    8000527e:	83a080e7          	jalr	-1990(ra) # 80002ab4 <argint>
    return -1;
    80005282:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005284:	02054763          	bltz	a0,800052b2 <sys_write+0x5c>
    80005288:	fd840593          	addi	a1,s0,-40
    8000528c:	4505                	li	a0,1
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	848080e7          	jalr	-1976(ra) # 80002ad6 <argaddr>
    return -1;
    80005296:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005298:	00054d63          	bltz	a0,800052b2 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000529c:	fe442603          	lw	a2,-28(s0)
    800052a0:	fd843583          	ld	a1,-40(s0)
    800052a4:	fe843503          	ld	a0,-24(s0)
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	4b0080e7          	jalr	1200(ra) # 80004758 <filewrite>
    800052b0:	87aa                	mv	a5,a0
}
    800052b2:	853e                	mv	a0,a5
    800052b4:	70a2                	ld	ra,40(sp)
    800052b6:	7402                	ld	s0,32(sp)
    800052b8:	6145                	addi	sp,sp,48
    800052ba:	8082                	ret

00000000800052bc <sys_close>:
{
    800052bc:	1101                	addi	sp,sp,-32
    800052be:	ec06                	sd	ra,24(sp)
    800052c0:	e822                	sd	s0,16(sp)
    800052c2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052c4:	fe040613          	addi	a2,s0,-32
    800052c8:	fec40593          	addi	a1,s0,-20
    800052cc:	4501                	li	a0,0
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	cc0080e7          	jalr	-832(ra) # 80004f8e <argfd>
    return -1;
    800052d6:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052d8:	02054463          	bltz	a0,80005300 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	6f0080e7          	jalr	1776(ra) # 800019cc <myproc>
    800052e4:	fec42783          	lw	a5,-20(s0)
    800052e8:	07e9                	addi	a5,a5,26
    800052ea:	078e                	slli	a5,a5,0x3
    800052ec:	953e                	add	a0,a0,a5
    800052ee:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052f2:	fe043503          	ld	a0,-32(s0)
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	266080e7          	jalr	614(ra) # 8000455c <fileclose>
  return 0;
    800052fe:	4781                	li	a5,0
}
    80005300:	853e                	mv	a0,a5
    80005302:	60e2                	ld	ra,24(sp)
    80005304:	6442                	ld	s0,16(sp)
    80005306:	6105                	addi	sp,sp,32
    80005308:	8082                	ret

000000008000530a <sys_fstat>:
{
    8000530a:	1101                	addi	sp,sp,-32
    8000530c:	ec06                	sd	ra,24(sp)
    8000530e:	e822                	sd	s0,16(sp)
    80005310:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005312:	fe840613          	addi	a2,s0,-24
    80005316:	4581                	li	a1,0
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	c74080e7          	jalr	-908(ra) # 80004f8e <argfd>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005324:	02054563          	bltz	a0,8000534e <sys_fstat+0x44>
    80005328:	fe040593          	addi	a1,s0,-32
    8000532c:	4505                	li	a0,1
    8000532e:	ffffd097          	auipc	ra,0xffffd
    80005332:	7a8080e7          	jalr	1960(ra) # 80002ad6 <argaddr>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005338:	00054b63          	bltz	a0,8000534e <sys_fstat+0x44>
  return filestat(f, st);
    8000533c:	fe043583          	ld	a1,-32(s0)
    80005340:	fe843503          	ld	a0,-24(s0)
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	2e0080e7          	jalr	736(ra) # 80004624 <filestat>
    8000534c:	87aa                	mv	a5,a0
}
    8000534e:	853e                	mv	a0,a5
    80005350:	60e2                	ld	ra,24(sp)
    80005352:	6442                	ld	s0,16(sp)
    80005354:	6105                	addi	sp,sp,32
    80005356:	8082                	ret

0000000080005358 <sys_link>:
{
    80005358:	7169                	addi	sp,sp,-304
    8000535a:	f606                	sd	ra,296(sp)
    8000535c:	f222                	sd	s0,288(sp)
    8000535e:	ee26                	sd	s1,280(sp)
    80005360:	ea4a                	sd	s2,272(sp)
    80005362:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005364:	08000613          	li	a2,128
    80005368:	ed040593          	addi	a1,s0,-304
    8000536c:	4501                	li	a0,0
    8000536e:	ffffd097          	auipc	ra,0xffffd
    80005372:	78a080e7          	jalr	1930(ra) # 80002af8 <argstr>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005378:	10054e63          	bltz	a0,80005494 <sys_link+0x13c>
    8000537c:	08000613          	li	a2,128
    80005380:	f5040593          	addi	a1,s0,-176
    80005384:	4505                	li	a0,1
    80005386:	ffffd097          	auipc	ra,0xffffd
    8000538a:	772080e7          	jalr	1906(ra) # 80002af8 <argstr>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005390:	10054263          	bltz	a0,80005494 <sys_link+0x13c>
  begin_op();
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	cfa080e7          	jalr	-774(ra) # 8000408e <begin_op>
  if((ip = namei(old)) == 0){
    8000539c:	ed040513          	addi	a0,s0,-304
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	ade080e7          	jalr	-1314(ra) # 80003e7e <namei>
    800053a8:	84aa                	mv	s1,a0
    800053aa:	c551                	beqz	a0,80005436 <sys_link+0xde>
  ilock(ip);
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	31c080e7          	jalr	796(ra) # 800036c8 <ilock>
  if(ip->type == T_DIR){
    800053b4:	04449703          	lh	a4,68(s1)
    800053b8:	4785                	li	a5,1
    800053ba:	08f70463          	beq	a4,a5,80005442 <sys_link+0xea>
  ip->nlink++;
    800053be:	04a4d783          	lhu	a5,74(s1)
    800053c2:	2785                	addiw	a5,a5,1
    800053c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	232080e7          	jalr	562(ra) # 800035fc <iupdate>
  iunlock(ip);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	3b6080e7          	jalr	950(ra) # 8000378a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053dc:	fd040593          	addi	a1,s0,-48
    800053e0:	f5040513          	addi	a0,s0,-176
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	ab8080e7          	jalr	-1352(ra) # 80003e9c <nameiparent>
    800053ec:	892a                	mv	s2,a0
    800053ee:	c935                	beqz	a0,80005462 <sys_link+0x10a>
  ilock(dp);
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	2d8080e7          	jalr	728(ra) # 800036c8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053f8:	00092703          	lw	a4,0(s2)
    800053fc:	409c                	lw	a5,0(s1)
    800053fe:	04f71d63          	bne	a4,a5,80005458 <sys_link+0x100>
    80005402:	40d0                	lw	a2,4(s1)
    80005404:	fd040593          	addi	a1,s0,-48
    80005408:	854a                	mv	a0,s2
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	9b2080e7          	jalr	-1614(ra) # 80003dbc <dirlink>
    80005412:	04054363          	bltz	a0,80005458 <sys_link+0x100>
  iunlockput(dp);
    80005416:	854a                	mv	a0,s2
    80005418:	ffffe097          	auipc	ra,0xffffe
    8000541c:	512080e7          	jalr	1298(ra) # 8000392a <iunlockput>
  iput(ip);
    80005420:	8526                	mv	a0,s1
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	460080e7          	jalr	1120(ra) # 80003882 <iput>
  end_op();
    8000542a:	fffff097          	auipc	ra,0xfffff
    8000542e:	ce2080e7          	jalr	-798(ra) # 8000410c <end_op>
  return 0;
    80005432:	4781                	li	a5,0
    80005434:	a085                	j	80005494 <sys_link+0x13c>
    end_op();
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	cd6080e7          	jalr	-810(ra) # 8000410c <end_op>
    return -1;
    8000543e:	57fd                	li	a5,-1
    80005440:	a891                	j	80005494 <sys_link+0x13c>
    iunlockput(ip);
    80005442:	8526                	mv	a0,s1
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	4e6080e7          	jalr	1254(ra) # 8000392a <iunlockput>
    end_op();
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	cc0080e7          	jalr	-832(ra) # 8000410c <end_op>
    return -1;
    80005454:	57fd                	li	a5,-1
    80005456:	a83d                	j	80005494 <sys_link+0x13c>
    iunlockput(dp);
    80005458:	854a                	mv	a0,s2
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	4d0080e7          	jalr	1232(ra) # 8000392a <iunlockput>
  ilock(ip);
    80005462:	8526                	mv	a0,s1
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	264080e7          	jalr	612(ra) # 800036c8 <ilock>
  ip->nlink--;
    8000546c:	04a4d783          	lhu	a5,74(s1)
    80005470:	37fd                	addiw	a5,a5,-1
    80005472:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005476:	8526                	mv	a0,s1
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	184080e7          	jalr	388(ra) # 800035fc <iupdate>
  iunlockput(ip);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	4a8080e7          	jalr	1192(ra) # 8000392a <iunlockput>
  end_op();
    8000548a:	fffff097          	auipc	ra,0xfffff
    8000548e:	c82080e7          	jalr	-894(ra) # 8000410c <end_op>
  return -1;
    80005492:	57fd                	li	a5,-1
}
    80005494:	853e                	mv	a0,a5
    80005496:	70b2                	ld	ra,296(sp)
    80005498:	7412                	ld	s0,288(sp)
    8000549a:	64f2                	ld	s1,280(sp)
    8000549c:	6952                	ld	s2,272(sp)
    8000549e:	6155                	addi	sp,sp,304
    800054a0:	8082                	ret

00000000800054a2 <sys_unlink>:
{
    800054a2:	7151                	addi	sp,sp,-240
    800054a4:	f586                	sd	ra,232(sp)
    800054a6:	f1a2                	sd	s0,224(sp)
    800054a8:	eda6                	sd	s1,216(sp)
    800054aa:	e9ca                	sd	s2,208(sp)
    800054ac:	e5ce                	sd	s3,200(sp)
    800054ae:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054b0:	08000613          	li	a2,128
    800054b4:	f3040593          	addi	a1,s0,-208
    800054b8:	4501                	li	a0,0
    800054ba:	ffffd097          	auipc	ra,0xffffd
    800054be:	63e080e7          	jalr	1598(ra) # 80002af8 <argstr>
    800054c2:	18054163          	bltz	a0,80005644 <sys_unlink+0x1a2>
  begin_op();
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	bc8080e7          	jalr	-1080(ra) # 8000408e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	f3040513          	addi	a0,s0,-208
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	9c6080e7          	jalr	-1594(ra) # 80003e9c <nameiparent>
    800054de:	84aa                	mv	s1,a0
    800054e0:	c979                	beqz	a0,800055b6 <sys_unlink+0x114>
  ilock(dp);
    800054e2:	ffffe097          	auipc	ra,0xffffe
    800054e6:	1e6080e7          	jalr	486(ra) # 800036c8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054ea:	00003597          	auipc	a1,0x3
    800054ee:	2d658593          	addi	a1,a1,726 # 800087c0 <syscalls+0x2d8>
    800054f2:	fb040513          	addi	a0,s0,-80
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	696080e7          	jalr	1686(ra) # 80003b8c <namecmp>
    800054fe:	14050a63          	beqz	a0,80005652 <sys_unlink+0x1b0>
    80005502:	00003597          	auipc	a1,0x3
    80005506:	2c658593          	addi	a1,a1,710 # 800087c8 <syscalls+0x2e0>
    8000550a:	fb040513          	addi	a0,s0,-80
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	67e080e7          	jalr	1662(ra) # 80003b8c <namecmp>
    80005516:	12050e63          	beqz	a0,80005652 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000551a:	f2c40613          	addi	a2,s0,-212
    8000551e:	fb040593          	addi	a1,s0,-80
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	682080e7          	jalr	1666(ra) # 80003ba6 <dirlookup>
    8000552c:	892a                	mv	s2,a0
    8000552e:	12050263          	beqz	a0,80005652 <sys_unlink+0x1b0>
  ilock(ip);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	196080e7          	jalr	406(ra) # 800036c8 <ilock>
  if(ip->nlink < 1)
    8000553a:	04a91783          	lh	a5,74(s2)
    8000553e:	08f05263          	blez	a5,800055c2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005542:	04491703          	lh	a4,68(s2)
    80005546:	4785                	li	a5,1
    80005548:	08f70563          	beq	a4,a5,800055d2 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000554c:	4641                	li	a2,16
    8000554e:	4581                	li	a1,0
    80005550:	fc040513          	addi	a0,s0,-64
    80005554:	ffffb097          	auipc	ra,0xffffb
    80005558:	7a8080e7          	jalr	1960(ra) # 80000cfc <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000555c:	4741                	li	a4,16
    8000555e:	f2c42683          	lw	a3,-212(s0)
    80005562:	fc040613          	addi	a2,s0,-64
    80005566:	4581                	li	a1,0
    80005568:	8526                	mv	a0,s1
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	508080e7          	jalr	1288(ra) # 80003a72 <writei>
    80005572:	47c1                	li	a5,16
    80005574:	0af51563          	bne	a0,a5,8000561e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005578:	04491703          	lh	a4,68(s2)
    8000557c:	4785                	li	a5,1
    8000557e:	0af70863          	beq	a4,a5,8000562e <sys_unlink+0x18c>
  iunlockput(dp);
    80005582:	8526                	mv	a0,s1
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	3a6080e7          	jalr	934(ra) # 8000392a <iunlockput>
  ip->nlink--;
    8000558c:	04a95783          	lhu	a5,74(s2)
    80005590:	37fd                	addiw	a5,a5,-1
    80005592:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005596:	854a                	mv	a0,s2
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	064080e7          	jalr	100(ra) # 800035fc <iupdate>
  iunlockput(ip);
    800055a0:	854a                	mv	a0,s2
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	388080e7          	jalr	904(ra) # 8000392a <iunlockput>
  end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	b62080e7          	jalr	-1182(ra) # 8000410c <end_op>
  return 0;
    800055b2:	4501                	li	a0,0
    800055b4:	a84d                	j	80005666 <sys_unlink+0x1c4>
    end_op();
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	b56080e7          	jalr	-1194(ra) # 8000410c <end_op>
    return -1;
    800055be:	557d                	li	a0,-1
    800055c0:	a05d                	j	80005666 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055c2:	00003517          	auipc	a0,0x3
    800055c6:	22e50513          	addi	a0,a0,558 # 800087f0 <syscalls+0x308>
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	f7c080e7          	jalr	-132(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055d2:	04c92703          	lw	a4,76(s2)
    800055d6:	02000793          	li	a5,32
    800055da:	f6e7f9e3          	bgeu	a5,a4,8000554c <sys_unlink+0xaa>
    800055de:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055e2:	4741                	li	a4,16
    800055e4:	86ce                	mv	a3,s3
    800055e6:	f1840613          	addi	a2,s0,-232
    800055ea:	4581                	li	a1,0
    800055ec:	854a                	mv	a0,s2
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	38e080e7          	jalr	910(ra) # 8000397c <readi>
    800055f6:	47c1                	li	a5,16
    800055f8:	00f51b63          	bne	a0,a5,8000560e <sys_unlink+0x16c>
    if(de.inum != 0)
    800055fc:	f1845783          	lhu	a5,-232(s0)
    80005600:	e7a1                	bnez	a5,80005648 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005602:	29c1                	addiw	s3,s3,16
    80005604:	04c92783          	lw	a5,76(s2)
    80005608:	fcf9ede3          	bltu	s3,a5,800055e2 <sys_unlink+0x140>
    8000560c:	b781                	j	8000554c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000560e:	00003517          	auipc	a0,0x3
    80005612:	1fa50513          	addi	a0,a0,506 # 80008808 <syscalls+0x320>
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	f30080e7          	jalr	-208(ra) # 80000546 <panic>
    panic("unlink: writei");
    8000561e:	00003517          	auipc	a0,0x3
    80005622:	20250513          	addi	a0,a0,514 # 80008820 <syscalls+0x338>
    80005626:	ffffb097          	auipc	ra,0xffffb
    8000562a:	f20080e7          	jalr	-224(ra) # 80000546 <panic>
    dp->nlink--;
    8000562e:	04a4d783          	lhu	a5,74(s1)
    80005632:	37fd                	addiw	a5,a5,-1
    80005634:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	fc2080e7          	jalr	-62(ra) # 800035fc <iupdate>
    80005642:	b781                	j	80005582 <sys_unlink+0xe0>
    return -1;
    80005644:	557d                	li	a0,-1
    80005646:	a005                	j	80005666 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005648:	854a                	mv	a0,s2
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	2e0080e7          	jalr	736(ra) # 8000392a <iunlockput>
  iunlockput(dp);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	2d6080e7          	jalr	726(ra) # 8000392a <iunlockput>
  end_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	ab0080e7          	jalr	-1360(ra) # 8000410c <end_op>
  return -1;
    80005664:	557d                	li	a0,-1
}
    80005666:	70ae                	ld	ra,232(sp)
    80005668:	740e                	ld	s0,224(sp)
    8000566a:	64ee                	ld	s1,216(sp)
    8000566c:	694e                	ld	s2,208(sp)
    8000566e:	69ae                	ld	s3,200(sp)
    80005670:	616d                	addi	sp,sp,240
    80005672:	8082                	ret

0000000080005674 <sys_open>:

uint64
sys_open(void)
{
    80005674:	7131                	addi	sp,sp,-192
    80005676:	fd06                	sd	ra,184(sp)
    80005678:	f922                	sd	s0,176(sp)
    8000567a:	f526                	sd	s1,168(sp)
    8000567c:	f14a                	sd	s2,160(sp)
    8000567e:	ed4e                	sd	s3,152(sp)
    80005680:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005682:	08000613          	li	a2,128
    80005686:	f5040593          	addi	a1,s0,-176
    8000568a:	4501                	li	a0,0
    8000568c:	ffffd097          	auipc	ra,0xffffd
    80005690:	46c080e7          	jalr	1132(ra) # 80002af8 <argstr>
    return -1;
    80005694:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005696:	0c054163          	bltz	a0,80005758 <sys_open+0xe4>
    8000569a:	f4c40593          	addi	a1,s0,-180
    8000569e:	4505                	li	a0,1
    800056a0:	ffffd097          	auipc	ra,0xffffd
    800056a4:	414080e7          	jalr	1044(ra) # 80002ab4 <argint>
    800056a8:	0a054863          	bltz	a0,80005758 <sys_open+0xe4>

  begin_op();
    800056ac:	fffff097          	auipc	ra,0xfffff
    800056b0:	9e2080e7          	jalr	-1566(ra) # 8000408e <begin_op>

  if(omode & O_CREATE){
    800056b4:	f4c42783          	lw	a5,-180(s0)
    800056b8:	2007f793          	andi	a5,a5,512
    800056bc:	cbdd                	beqz	a5,80005772 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056be:	4681                	li	a3,0
    800056c0:	4601                	li	a2,0
    800056c2:	4589                	li	a1,2
    800056c4:	f5040513          	addi	a0,s0,-176
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	970080e7          	jalr	-1680(ra) # 80005038 <create>
    800056d0:	892a                	mv	s2,a0
    if(ip == 0){
    800056d2:	c959                	beqz	a0,80005768 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056d4:	04491703          	lh	a4,68(s2)
    800056d8:	478d                	li	a5,3
    800056da:	00f71763          	bne	a4,a5,800056e8 <sys_open+0x74>
    800056de:	04695703          	lhu	a4,70(s2)
    800056e2:	47a5                	li	a5,9
    800056e4:	0ce7ec63          	bltu	a5,a4,800057bc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	db8080e7          	jalr	-584(ra) # 800044a0 <filealloc>
    800056f0:	89aa                	mv	s3,a0
    800056f2:	10050263          	beqz	a0,800057f6 <sys_open+0x182>
    800056f6:	00000097          	auipc	ra,0x0
    800056fa:	900080e7          	jalr	-1792(ra) # 80004ff6 <fdalloc>
    800056fe:	84aa                	mv	s1,a0
    80005700:	0e054663          	bltz	a0,800057ec <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005704:	04491703          	lh	a4,68(s2)
    80005708:	478d                	li	a5,3
    8000570a:	0cf70463          	beq	a4,a5,800057d2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000570e:	4789                	li	a5,2
    80005710:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005714:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005718:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000571c:	f4c42783          	lw	a5,-180(s0)
    80005720:	0017c713          	xori	a4,a5,1
    80005724:	8b05                	andi	a4,a4,1
    80005726:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000572a:	0037f713          	andi	a4,a5,3
    8000572e:	00e03733          	snez	a4,a4
    80005732:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005736:	4007f793          	andi	a5,a5,1024
    8000573a:	c791                	beqz	a5,80005746 <sys_open+0xd2>
    8000573c:	04491703          	lh	a4,68(s2)
    80005740:	4789                	li	a5,2
    80005742:	08f70f63          	beq	a4,a5,800057e0 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	042080e7          	jalr	66(ra) # 8000378a <iunlock>
  end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	9bc080e7          	jalr	-1604(ra) # 8000410c <end_op>

  return fd;
}
    80005758:	8526                	mv	a0,s1
    8000575a:	70ea                	ld	ra,184(sp)
    8000575c:	744a                	ld	s0,176(sp)
    8000575e:	74aa                	ld	s1,168(sp)
    80005760:	790a                	ld	s2,160(sp)
    80005762:	69ea                	ld	s3,152(sp)
    80005764:	6129                	addi	sp,sp,192
    80005766:	8082                	ret
      end_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	9a4080e7          	jalr	-1628(ra) # 8000410c <end_op>
      return -1;
    80005770:	b7e5                	j	80005758 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005772:	f5040513          	addi	a0,s0,-176
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	708080e7          	jalr	1800(ra) # 80003e7e <namei>
    8000577e:	892a                	mv	s2,a0
    80005780:	c905                	beqz	a0,800057b0 <sys_open+0x13c>
    ilock(ip);
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	f46080e7          	jalr	-186(ra) # 800036c8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000578a:	04491703          	lh	a4,68(s2)
    8000578e:	4785                	li	a5,1
    80005790:	f4f712e3          	bne	a4,a5,800056d4 <sys_open+0x60>
    80005794:	f4c42783          	lw	a5,-180(s0)
    80005798:	dba1                	beqz	a5,800056e8 <sys_open+0x74>
      iunlockput(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	18e080e7          	jalr	398(ra) # 8000392a <iunlockput>
      end_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	968080e7          	jalr	-1688(ra) # 8000410c <end_op>
      return -1;
    800057ac:	54fd                	li	s1,-1
    800057ae:	b76d                	j	80005758 <sys_open+0xe4>
      end_op();
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	95c080e7          	jalr	-1700(ra) # 8000410c <end_op>
      return -1;
    800057b8:	54fd                	li	s1,-1
    800057ba:	bf79                	j	80005758 <sys_open+0xe4>
    iunlockput(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	16c080e7          	jalr	364(ra) # 8000392a <iunlockput>
    end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	946080e7          	jalr	-1722(ra) # 8000410c <end_op>
    return -1;
    800057ce:	54fd                	li	s1,-1
    800057d0:	b761                	j	80005758 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057d2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057d6:	04691783          	lh	a5,70(s2)
    800057da:	02f99223          	sh	a5,36(s3)
    800057de:	bf2d                	j	80005718 <sys_open+0xa4>
    itrunc(ip);
    800057e0:	854a                	mv	a0,s2
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	ff4080e7          	jalr	-12(ra) # 800037d6 <itrunc>
    800057ea:	bfb1                	j	80005746 <sys_open+0xd2>
      fileclose(f);
    800057ec:	854e                	mv	a0,s3
    800057ee:	fffff097          	auipc	ra,0xfffff
    800057f2:	d6e080e7          	jalr	-658(ra) # 8000455c <fileclose>
    iunlockput(ip);
    800057f6:	854a                	mv	a0,s2
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	132080e7          	jalr	306(ra) # 8000392a <iunlockput>
    end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	90c080e7          	jalr	-1780(ra) # 8000410c <end_op>
    return -1;
    80005808:	54fd                	li	s1,-1
    8000580a:	b7b9                	j	80005758 <sys_open+0xe4>

000000008000580c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000580c:	7175                	addi	sp,sp,-144
    8000580e:	e506                	sd	ra,136(sp)
    80005810:	e122                	sd	s0,128(sp)
    80005812:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	87a080e7          	jalr	-1926(ra) # 8000408e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000581c:	08000613          	li	a2,128
    80005820:	f7040593          	addi	a1,s0,-144
    80005824:	4501                	li	a0,0
    80005826:	ffffd097          	auipc	ra,0xffffd
    8000582a:	2d2080e7          	jalr	722(ra) # 80002af8 <argstr>
    8000582e:	02054963          	bltz	a0,80005860 <sys_mkdir+0x54>
    80005832:	4681                	li	a3,0
    80005834:	4601                	li	a2,0
    80005836:	4585                	li	a1,1
    80005838:	f7040513          	addi	a0,s0,-144
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	7fc080e7          	jalr	2044(ra) # 80005038 <create>
    80005844:	cd11                	beqz	a0,80005860 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	0e4080e7          	jalr	228(ra) # 8000392a <iunlockput>
  end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	8be080e7          	jalr	-1858(ra) # 8000410c <end_op>
  return 0;
    80005856:	4501                	li	a0,0
}
    80005858:	60aa                	ld	ra,136(sp)
    8000585a:	640a                	ld	s0,128(sp)
    8000585c:	6149                	addi	sp,sp,144
    8000585e:	8082                	ret
    end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	8ac080e7          	jalr	-1876(ra) # 8000410c <end_op>
    return -1;
    80005868:	557d                	li	a0,-1
    8000586a:	b7fd                	j	80005858 <sys_mkdir+0x4c>

000000008000586c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000586c:	7135                	addi	sp,sp,-160
    8000586e:	ed06                	sd	ra,152(sp)
    80005870:	e922                	sd	s0,144(sp)
    80005872:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	81a080e7          	jalr	-2022(ra) # 8000408e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000587c:	08000613          	li	a2,128
    80005880:	f7040593          	addi	a1,s0,-144
    80005884:	4501                	li	a0,0
    80005886:	ffffd097          	auipc	ra,0xffffd
    8000588a:	272080e7          	jalr	626(ra) # 80002af8 <argstr>
    8000588e:	04054a63          	bltz	a0,800058e2 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005892:	f6c40593          	addi	a1,s0,-148
    80005896:	4505                	li	a0,1
    80005898:	ffffd097          	auipc	ra,0xffffd
    8000589c:	21c080e7          	jalr	540(ra) # 80002ab4 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058a0:	04054163          	bltz	a0,800058e2 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800058a4:	f6840593          	addi	a1,s0,-152
    800058a8:	4509                	li	a0,2
    800058aa:	ffffd097          	auipc	ra,0xffffd
    800058ae:	20a080e7          	jalr	522(ra) # 80002ab4 <argint>
     argint(1, &major) < 0 ||
    800058b2:	02054863          	bltz	a0,800058e2 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058b6:	f6841683          	lh	a3,-152(s0)
    800058ba:	f6c41603          	lh	a2,-148(s0)
    800058be:	458d                	li	a1,3
    800058c0:	f7040513          	addi	a0,s0,-144
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	774080e7          	jalr	1908(ra) # 80005038 <create>
     argint(2, &minor) < 0 ||
    800058cc:	c919                	beqz	a0,800058e2 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	05c080e7          	jalr	92(ra) # 8000392a <iunlockput>
  end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	836080e7          	jalr	-1994(ra) # 8000410c <end_op>
  return 0;
    800058de:	4501                	li	a0,0
    800058e0:	a031                	j	800058ec <sys_mknod+0x80>
    end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	82a080e7          	jalr	-2006(ra) # 8000410c <end_op>
    return -1;
    800058ea:	557d                	li	a0,-1
}
    800058ec:	60ea                	ld	ra,152(sp)
    800058ee:	644a                	ld	s0,144(sp)
    800058f0:	610d                	addi	sp,sp,160
    800058f2:	8082                	ret

00000000800058f4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058f4:	7135                	addi	sp,sp,-160
    800058f6:	ed06                	sd	ra,152(sp)
    800058f8:	e922                	sd	s0,144(sp)
    800058fa:	e526                	sd	s1,136(sp)
    800058fc:	e14a                	sd	s2,128(sp)
    800058fe:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005900:	ffffc097          	auipc	ra,0xffffc
    80005904:	0cc080e7          	jalr	204(ra) # 800019cc <myproc>
    80005908:	892a                	mv	s2,a0
  
  begin_op();
    8000590a:	ffffe097          	auipc	ra,0xffffe
    8000590e:	784080e7          	jalr	1924(ra) # 8000408e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005912:	08000613          	li	a2,128
    80005916:	f6040593          	addi	a1,s0,-160
    8000591a:	4501                	li	a0,0
    8000591c:	ffffd097          	auipc	ra,0xffffd
    80005920:	1dc080e7          	jalr	476(ra) # 80002af8 <argstr>
    80005924:	04054b63          	bltz	a0,8000597a <sys_chdir+0x86>
    80005928:	f6040513          	addi	a0,s0,-160
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	552080e7          	jalr	1362(ra) # 80003e7e <namei>
    80005934:	84aa                	mv	s1,a0
    80005936:	c131                	beqz	a0,8000597a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	d90080e7          	jalr	-624(ra) # 800036c8 <ilock>
  if(ip->type != T_DIR){
    80005940:	04449703          	lh	a4,68(s1)
    80005944:	4785                	li	a5,1
    80005946:	04f71063          	bne	a4,a5,80005986 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	e3e080e7          	jalr	-450(ra) # 8000378a <iunlock>
  iput(p->cwd);
    80005954:	15093503          	ld	a0,336(s2)
    80005958:	ffffe097          	auipc	ra,0xffffe
    8000595c:	f2a080e7          	jalr	-214(ra) # 80003882 <iput>
  end_op();
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	7ac080e7          	jalr	1964(ra) # 8000410c <end_op>
  p->cwd = ip;
    80005968:	14993823          	sd	s1,336(s2)
  return 0;
    8000596c:	4501                	li	a0,0
}
    8000596e:	60ea                	ld	ra,152(sp)
    80005970:	644a                	ld	s0,144(sp)
    80005972:	64aa                	ld	s1,136(sp)
    80005974:	690a                	ld	s2,128(sp)
    80005976:	610d                	addi	sp,sp,160
    80005978:	8082                	ret
    end_op();
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	792080e7          	jalr	1938(ra) # 8000410c <end_op>
    return -1;
    80005982:	557d                	li	a0,-1
    80005984:	b7ed                	j	8000596e <sys_chdir+0x7a>
    iunlockput(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	fa2080e7          	jalr	-94(ra) # 8000392a <iunlockput>
    end_op();
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	77c080e7          	jalr	1916(ra) # 8000410c <end_op>
    return -1;
    80005998:	557d                	li	a0,-1
    8000599a:	bfd1                	j	8000596e <sys_chdir+0x7a>

000000008000599c <sys_exec>:

uint64
sys_exec(void)
{
    8000599c:	7145                	addi	sp,sp,-464
    8000599e:	e786                	sd	ra,456(sp)
    800059a0:	e3a2                	sd	s0,448(sp)
    800059a2:	ff26                	sd	s1,440(sp)
    800059a4:	fb4a                	sd	s2,432(sp)
    800059a6:	f74e                	sd	s3,424(sp)
    800059a8:	f352                	sd	s4,416(sp)
    800059aa:	ef56                	sd	s5,408(sp)
    800059ac:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059ae:	08000613          	li	a2,128
    800059b2:	f4040593          	addi	a1,s0,-192
    800059b6:	4501                	li	a0,0
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	140080e7          	jalr	320(ra) # 80002af8 <argstr>
    return -1;
    800059c0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059c2:	0c054b63          	bltz	a0,80005a98 <sys_exec+0xfc>
    800059c6:	e3840593          	addi	a1,s0,-456
    800059ca:	4505                	li	a0,1
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	10a080e7          	jalr	266(ra) # 80002ad6 <argaddr>
    800059d4:	0c054263          	bltz	a0,80005a98 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059d8:	10000613          	li	a2,256
    800059dc:	4581                	li	a1,0
    800059de:	e4040513          	addi	a0,s0,-448
    800059e2:	ffffb097          	auipc	ra,0xffffb
    800059e6:	31a080e7          	jalr	794(ra) # 80000cfc <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059ee:	89a6                	mv	s3,s1
    800059f0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059f2:	02000a13          	li	s4,32
    800059f6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059fa:	00391513          	slli	a0,s2,0x3
    800059fe:	e3040593          	addi	a1,s0,-464
    80005a02:	e3843783          	ld	a5,-456(s0)
    80005a06:	953e                	add	a0,a0,a5
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	012080e7          	jalr	18(ra) # 80002a1a <fetchaddr>
    80005a10:	02054a63          	bltz	a0,80005a44 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a14:	e3043783          	ld	a5,-464(s0)
    80005a18:	c3b9                	beqz	a5,80005a5e <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a1a:	ffffb097          	auipc	ra,0xffffb
    80005a1e:	0f6080e7          	jalr	246(ra) # 80000b10 <kalloc>
    80005a22:	85aa                	mv	a1,a0
    80005a24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a28:	cd11                	beqz	a0,80005a44 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a2a:	6605                	lui	a2,0x1
    80005a2c:	e3043503          	ld	a0,-464(s0)
    80005a30:	ffffd097          	auipc	ra,0xffffd
    80005a34:	03c080e7          	jalr	60(ra) # 80002a6c <fetchstr>
    80005a38:	00054663          	bltz	a0,80005a44 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a3c:	0905                	addi	s2,s2,1
    80005a3e:	09a1                	addi	s3,s3,8
    80005a40:	fb491be3          	bne	s2,s4,800059f6 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a44:	f4040913          	addi	s2,s0,-192
    80005a48:	6088                	ld	a0,0(s1)
    80005a4a:	c531                	beqz	a0,80005a96 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	fc6080e7          	jalr	-58(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a54:	04a1                	addi	s1,s1,8
    80005a56:	ff2499e3          	bne	s1,s2,80005a48 <sys_exec+0xac>
  return -1;
    80005a5a:	597d                	li	s2,-1
    80005a5c:	a835                	j	80005a98 <sys_exec+0xfc>
      argv[i] = 0;
    80005a5e:	0a8e                	slli	s5,s5,0x3
    80005a60:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005a64:	00878ab3          	add	s5,a5,s0
    80005a68:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a6c:	e4040593          	addi	a1,s0,-448
    80005a70:	f4040513          	addi	a0,s0,-192
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	172080e7          	jalr	370(ra) # 80004be6 <exec>
    80005a7c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a7e:	f4040993          	addi	s3,s0,-192
    80005a82:	6088                	ld	a0,0(s1)
    80005a84:	c911                	beqz	a0,80005a98 <sys_exec+0xfc>
    kfree(argv[i]);
    80005a86:	ffffb097          	auipc	ra,0xffffb
    80005a8a:	f8c080e7          	jalr	-116(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a8e:	04a1                	addi	s1,s1,8
    80005a90:	ff3499e3          	bne	s1,s3,80005a82 <sys_exec+0xe6>
    80005a94:	a011                	j	80005a98 <sys_exec+0xfc>
  return -1;
    80005a96:	597d                	li	s2,-1
}
    80005a98:	854a                	mv	a0,s2
    80005a9a:	60be                	ld	ra,456(sp)
    80005a9c:	641e                	ld	s0,448(sp)
    80005a9e:	74fa                	ld	s1,440(sp)
    80005aa0:	795a                	ld	s2,432(sp)
    80005aa2:	79ba                	ld	s3,424(sp)
    80005aa4:	7a1a                	ld	s4,416(sp)
    80005aa6:	6afa                	ld	s5,408(sp)
    80005aa8:	6179                	addi	sp,sp,464
    80005aaa:	8082                	ret

0000000080005aac <sys_pipe>:

uint64
sys_pipe(void)
{
    80005aac:	7139                	addi	sp,sp,-64
    80005aae:	fc06                	sd	ra,56(sp)
    80005ab0:	f822                	sd	s0,48(sp)
    80005ab2:	f426                	sd	s1,40(sp)
    80005ab4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ab6:	ffffc097          	auipc	ra,0xffffc
    80005aba:	f16080e7          	jalr	-234(ra) # 800019cc <myproc>
    80005abe:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ac0:	fd840593          	addi	a1,s0,-40
    80005ac4:	4501                	li	a0,0
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	010080e7          	jalr	16(ra) # 80002ad6 <argaddr>
    return -1;
    80005ace:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ad0:	0e054063          	bltz	a0,80005bb0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ad4:	fc840593          	addi	a1,s0,-56
    80005ad8:	fd040513          	addi	a0,s0,-48
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	dd6080e7          	jalr	-554(ra) # 800048b2 <pipealloc>
    return -1;
    80005ae4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ae6:	0c054563          	bltz	a0,80005bb0 <sys_pipe+0x104>
  fd0 = -1;
    80005aea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005aee:	fd043503          	ld	a0,-48(s0)
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	504080e7          	jalr	1284(ra) # 80004ff6 <fdalloc>
    80005afa:	fca42223          	sw	a0,-60(s0)
    80005afe:	08054c63          	bltz	a0,80005b96 <sys_pipe+0xea>
    80005b02:	fc843503          	ld	a0,-56(s0)
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	4f0080e7          	jalr	1264(ra) # 80004ff6 <fdalloc>
    80005b0e:	fca42023          	sw	a0,-64(s0)
    80005b12:	06054963          	bltz	a0,80005b84 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b16:	4691                	li	a3,4
    80005b18:	fc440613          	addi	a2,s0,-60
    80005b1c:	fd843583          	ld	a1,-40(s0)
    80005b20:	68a8                	ld	a0,80(s1)
    80005b22:	ffffc097          	auipc	ra,0xffffc
    80005b26:	ba0080e7          	jalr	-1120(ra) # 800016c2 <copyout>
    80005b2a:	02054063          	bltz	a0,80005b4a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b2e:	4691                	li	a3,4
    80005b30:	fc040613          	addi	a2,s0,-64
    80005b34:	fd843583          	ld	a1,-40(s0)
    80005b38:	0591                	addi	a1,a1,4
    80005b3a:	68a8                	ld	a0,80(s1)
    80005b3c:	ffffc097          	auipc	ra,0xffffc
    80005b40:	b86080e7          	jalr	-1146(ra) # 800016c2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b44:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b46:	06055563          	bgez	a0,80005bb0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b4a:	fc442783          	lw	a5,-60(s0)
    80005b4e:	07e9                	addi	a5,a5,26
    80005b50:	078e                	slli	a5,a5,0x3
    80005b52:	97a6                	add	a5,a5,s1
    80005b54:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b58:	fc042783          	lw	a5,-64(s0)
    80005b5c:	07e9                	addi	a5,a5,26
    80005b5e:	078e                	slli	a5,a5,0x3
    80005b60:	00f48533          	add	a0,s1,a5
    80005b64:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b68:	fd043503          	ld	a0,-48(s0)
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	9f0080e7          	jalr	-1552(ra) # 8000455c <fileclose>
    fileclose(wf);
    80005b74:	fc843503          	ld	a0,-56(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	9e4080e7          	jalr	-1564(ra) # 8000455c <fileclose>
    return -1;
    80005b80:	57fd                	li	a5,-1
    80005b82:	a03d                	j	80005bb0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b84:	fc442783          	lw	a5,-60(s0)
    80005b88:	0007c763          	bltz	a5,80005b96 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b8c:	07e9                	addi	a5,a5,26
    80005b8e:	078e                	slli	a5,a5,0x3
    80005b90:	97a6                	add	a5,a5,s1
    80005b92:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b96:	fd043503          	ld	a0,-48(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	9c2080e7          	jalr	-1598(ra) # 8000455c <fileclose>
    fileclose(wf);
    80005ba2:	fc843503          	ld	a0,-56(s0)
    80005ba6:	fffff097          	auipc	ra,0xfffff
    80005baa:	9b6080e7          	jalr	-1610(ra) # 8000455c <fileclose>
    return -1;
    80005bae:	57fd                	li	a5,-1
}
    80005bb0:	853e                	mv	a0,a5
    80005bb2:	70e2                	ld	ra,56(sp)
    80005bb4:	7442                	ld	s0,48(sp)
    80005bb6:	74a2                	ld	s1,40(sp)
    80005bb8:	6121                	addi	sp,sp,64
    80005bba:	8082                	ret
    80005bbc:	0000                	unimp
	...

0000000080005bc0 <kernelvec>:
    80005bc0:	7111                	addi	sp,sp,-256
    80005bc2:	e006                	sd	ra,0(sp)
    80005bc4:	e40a                	sd	sp,8(sp)
    80005bc6:	e80e                	sd	gp,16(sp)
    80005bc8:	ec12                	sd	tp,24(sp)
    80005bca:	f016                	sd	t0,32(sp)
    80005bcc:	f41a                	sd	t1,40(sp)
    80005bce:	f81e                	sd	t2,48(sp)
    80005bd0:	fc22                	sd	s0,56(sp)
    80005bd2:	e0a6                	sd	s1,64(sp)
    80005bd4:	e4aa                	sd	a0,72(sp)
    80005bd6:	e8ae                	sd	a1,80(sp)
    80005bd8:	ecb2                	sd	a2,88(sp)
    80005bda:	f0b6                	sd	a3,96(sp)
    80005bdc:	f4ba                	sd	a4,104(sp)
    80005bde:	f8be                	sd	a5,112(sp)
    80005be0:	fcc2                	sd	a6,120(sp)
    80005be2:	e146                	sd	a7,128(sp)
    80005be4:	e54a                	sd	s2,136(sp)
    80005be6:	e94e                	sd	s3,144(sp)
    80005be8:	ed52                	sd	s4,152(sp)
    80005bea:	f156                	sd	s5,160(sp)
    80005bec:	f55a                	sd	s6,168(sp)
    80005bee:	f95e                	sd	s7,176(sp)
    80005bf0:	fd62                	sd	s8,184(sp)
    80005bf2:	e1e6                	sd	s9,192(sp)
    80005bf4:	e5ea                	sd	s10,200(sp)
    80005bf6:	e9ee                	sd	s11,208(sp)
    80005bf8:	edf2                	sd	t3,216(sp)
    80005bfa:	f1f6                	sd	t4,224(sp)
    80005bfc:	f5fa                	sd	t5,232(sp)
    80005bfe:	f9fe                	sd	t6,240(sp)
    80005c00:	ce7fc0ef          	jal	ra,800028e6 <kerneltrap>
    80005c04:	6082                	ld	ra,0(sp)
    80005c06:	6122                	ld	sp,8(sp)
    80005c08:	61c2                	ld	gp,16(sp)
    80005c0a:	7282                	ld	t0,32(sp)
    80005c0c:	7322                	ld	t1,40(sp)
    80005c0e:	73c2                	ld	t2,48(sp)
    80005c10:	7462                	ld	s0,56(sp)
    80005c12:	6486                	ld	s1,64(sp)
    80005c14:	6526                	ld	a0,72(sp)
    80005c16:	65c6                	ld	a1,80(sp)
    80005c18:	6666                	ld	a2,88(sp)
    80005c1a:	7686                	ld	a3,96(sp)
    80005c1c:	7726                	ld	a4,104(sp)
    80005c1e:	77c6                	ld	a5,112(sp)
    80005c20:	7866                	ld	a6,120(sp)
    80005c22:	688a                	ld	a7,128(sp)
    80005c24:	692a                	ld	s2,136(sp)
    80005c26:	69ca                	ld	s3,144(sp)
    80005c28:	6a6a                	ld	s4,152(sp)
    80005c2a:	7a8a                	ld	s5,160(sp)
    80005c2c:	7b2a                	ld	s6,168(sp)
    80005c2e:	7bca                	ld	s7,176(sp)
    80005c30:	7c6a                	ld	s8,184(sp)
    80005c32:	6c8e                	ld	s9,192(sp)
    80005c34:	6d2e                	ld	s10,200(sp)
    80005c36:	6dce                	ld	s11,208(sp)
    80005c38:	6e6e                	ld	t3,216(sp)
    80005c3a:	7e8e                	ld	t4,224(sp)
    80005c3c:	7f2e                	ld	t5,232(sp)
    80005c3e:	7fce                	ld	t6,240(sp)
    80005c40:	6111                	addi	sp,sp,256
    80005c42:	10200073          	sret
    80005c46:	00000013          	nop
    80005c4a:	00000013          	nop
    80005c4e:	0001                	nop

0000000080005c50 <timervec>:
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	e10c                	sd	a1,0(a0)
    80005c56:	e510                	sd	a2,8(a0)
    80005c58:	e914                	sd	a3,16(a0)
    80005c5a:	710c                	ld	a1,32(a0)
    80005c5c:	7510                	ld	a2,40(a0)
    80005c5e:	6194                	ld	a3,0(a1)
    80005c60:	96b2                	add	a3,a3,a2
    80005c62:	e194                	sd	a3,0(a1)
    80005c64:	4589                	li	a1,2
    80005c66:	14459073          	csrw	sip,a1
    80005c6a:	6914                	ld	a3,16(a0)
    80005c6c:	6510                	ld	a2,8(a0)
    80005c6e:	610c                	ld	a1,0(a0)
    80005c70:	34051573          	csrrw	a0,mscratch,a0
    80005c74:	30200073          	mret
	...

0000000080005c7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c7a:	1141                	addi	sp,sp,-16
    80005c7c:	e422                	sd	s0,8(sp)
    80005c7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c80:	0c0007b7          	lui	a5,0xc000
    80005c84:	4705                	li	a4,1
    80005c86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c88:	c3d8                	sw	a4,4(a5)
}
    80005c8a:	6422                	ld	s0,8(sp)
    80005c8c:	0141                	addi	sp,sp,16
    80005c8e:	8082                	ret

0000000080005c90 <plicinithart>:

void
plicinithart(void)
{
    80005c90:	1141                	addi	sp,sp,-16
    80005c92:	e406                	sd	ra,8(sp)
    80005c94:	e022                	sd	s0,0(sp)
    80005c96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	d08080e7          	jalr	-760(ra) # 800019a0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ca0:	0085171b          	slliw	a4,a0,0x8
    80005ca4:	0c0027b7          	lui	a5,0xc002
    80005ca8:	97ba                	add	a5,a5,a4
    80005caa:	40200713          	li	a4,1026
    80005cae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005cb2:	00d5151b          	slliw	a0,a0,0xd
    80005cb6:	0c2017b7          	lui	a5,0xc201
    80005cba:	97aa                	add	a5,a5,a0
    80005cbc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005cc0:	60a2                	ld	ra,8(sp)
    80005cc2:	6402                	ld	s0,0(sp)
    80005cc4:	0141                	addi	sp,sp,16
    80005cc6:	8082                	ret

0000000080005cc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cc8:	1141                	addi	sp,sp,-16
    80005cca:	e406                	sd	ra,8(sp)
    80005ccc:	e022                	sd	s0,0(sp)
    80005cce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	cd0080e7          	jalr	-816(ra) # 800019a0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cd8:	00d5151b          	slliw	a0,a0,0xd
    80005cdc:	0c2017b7          	lui	a5,0xc201
    80005ce0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005ce2:	43c8                	lw	a0,4(a5)
    80005ce4:	60a2                	ld	ra,8(sp)
    80005ce6:	6402                	ld	s0,0(sp)
    80005ce8:	0141                	addi	sp,sp,16
    80005cea:	8082                	ret

0000000080005cec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cec:	1101                	addi	sp,sp,-32
    80005cee:	ec06                	sd	ra,24(sp)
    80005cf0:	e822                	sd	s0,16(sp)
    80005cf2:	e426                	sd	s1,8(sp)
    80005cf4:	1000                	addi	s0,sp,32
    80005cf6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	ca8080e7          	jalr	-856(ra) # 800019a0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d00:	00d5151b          	slliw	a0,a0,0xd
    80005d04:	0c2017b7          	lui	a5,0xc201
    80005d08:	97aa                	add	a5,a5,a0
    80005d0a:	c3c4                	sw	s1,4(a5)
}
    80005d0c:	60e2                	ld	ra,24(sp)
    80005d0e:	6442                	ld	s0,16(sp)
    80005d10:	64a2                	ld	s1,8(sp)
    80005d12:	6105                	addi	sp,sp,32
    80005d14:	8082                	ret

0000000080005d16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d16:	1141                	addi	sp,sp,-16
    80005d18:	e406                	sd	ra,8(sp)
    80005d1a:	e022                	sd	s0,0(sp)
    80005d1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d1e:	479d                	li	a5,7
    80005d20:	04a7cb63          	blt	a5,a0,80005d76 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d24:	0001d717          	auipc	a4,0x1d
    80005d28:	2dc70713          	addi	a4,a4,732 # 80023000 <disk>
    80005d2c:	972a                	add	a4,a4,a0
    80005d2e:	6789                	lui	a5,0x2
    80005d30:	97ba                	add	a5,a5,a4
    80005d32:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d36:	eba1                	bnez	a5,80005d86 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d38:	00451713          	slli	a4,a0,0x4
    80005d3c:	0001f797          	auipc	a5,0x1f
    80005d40:	2c47b783          	ld	a5,708(a5) # 80025000 <disk+0x2000>
    80005d44:	97ba                	add	a5,a5,a4
    80005d46:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d4a:	0001d717          	auipc	a4,0x1d
    80005d4e:	2b670713          	addi	a4,a4,694 # 80023000 <disk>
    80005d52:	972a                	add	a4,a4,a0
    80005d54:	6789                	lui	a5,0x2
    80005d56:	97ba                	add	a5,a5,a4
    80005d58:	4705                	li	a4,1
    80005d5a:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d5e:	0001f517          	auipc	a0,0x1f
    80005d62:	2ba50513          	addi	a0,a0,698 # 80025018 <disk+0x2018>
    80005d66:	ffffc097          	auipc	ra,0xffffc
    80005d6a:	602080e7          	jalr	1538(ra) # 80002368 <wakeup>
}
    80005d6e:	60a2                	ld	ra,8(sp)
    80005d70:	6402                	ld	s0,0(sp)
    80005d72:	0141                	addi	sp,sp,16
    80005d74:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d76:	00003517          	auipc	a0,0x3
    80005d7a:	aba50513          	addi	a0,a0,-1350 # 80008830 <syscalls+0x348>
    80005d7e:	ffffa097          	auipc	ra,0xffffa
    80005d82:	7c8080e7          	jalr	1992(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005d86:	00003517          	auipc	a0,0x3
    80005d8a:	ac250513          	addi	a0,a0,-1342 # 80008848 <syscalls+0x360>
    80005d8e:	ffffa097          	auipc	ra,0xffffa
    80005d92:	7b8080e7          	jalr	1976(ra) # 80000546 <panic>

0000000080005d96 <virtio_disk_init>:
{
    80005d96:	1101                	addi	sp,sp,-32
    80005d98:	ec06                	sd	ra,24(sp)
    80005d9a:	e822                	sd	s0,16(sp)
    80005d9c:	e426                	sd	s1,8(sp)
    80005d9e:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005da0:	00003597          	auipc	a1,0x3
    80005da4:	ac058593          	addi	a1,a1,-1344 # 80008860 <syscalls+0x378>
    80005da8:	0001f517          	auipc	a0,0x1f
    80005dac:	30050513          	addi	a0,a0,768 # 800250a8 <disk+0x20a8>
    80005db0:	ffffb097          	auipc	ra,0xffffb
    80005db4:	dc0080e7          	jalr	-576(ra) # 80000b70 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db8:	100017b7          	lui	a5,0x10001
    80005dbc:	4398                	lw	a4,0(a5)
    80005dbe:	2701                	sext.w	a4,a4
    80005dc0:	747277b7          	lui	a5,0x74727
    80005dc4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dc8:	0ef71063          	bne	a4,a5,80005ea8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dcc:	100017b7          	lui	a5,0x10001
    80005dd0:	43dc                	lw	a5,4(a5)
    80005dd2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dd4:	4705                	li	a4,1
    80005dd6:	0ce79963          	bne	a5,a4,80005ea8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dda:	100017b7          	lui	a5,0x10001
    80005dde:	479c                	lw	a5,8(a5)
    80005de0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005de2:	4709                	li	a4,2
    80005de4:	0ce79263          	bne	a5,a4,80005ea8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005de8:	100017b7          	lui	a5,0x10001
    80005dec:	47d8                	lw	a4,12(a5)
    80005dee:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005df0:	554d47b7          	lui	a5,0x554d4
    80005df4:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005df8:	0af71863          	bne	a4,a5,80005ea8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dfc:	100017b7          	lui	a5,0x10001
    80005e00:	4705                	li	a4,1
    80005e02:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e04:	470d                	li	a4,3
    80005e06:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e08:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e0a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e0e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e12:	8f75                	and	a4,a4,a3
    80005e14:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e16:	472d                	li	a4,11
    80005e18:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e1a:	473d                	li	a4,15
    80005e1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e1e:	6705                	lui	a4,0x1
    80005e20:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e22:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e26:	5bdc                	lw	a5,52(a5)
    80005e28:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e2a:	c7d9                	beqz	a5,80005eb8 <virtio_disk_init+0x122>
  if(max < NUM)
    80005e2c:	471d                	li	a4,7
    80005e2e:	08f77d63          	bgeu	a4,a5,80005ec8 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e32:	100014b7          	lui	s1,0x10001
    80005e36:	47a1                	li	a5,8
    80005e38:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e3a:	6609                	lui	a2,0x2
    80005e3c:	4581                	li	a1,0
    80005e3e:	0001d517          	auipc	a0,0x1d
    80005e42:	1c250513          	addi	a0,a0,450 # 80023000 <disk>
    80005e46:	ffffb097          	auipc	ra,0xffffb
    80005e4a:	eb6080e7          	jalr	-330(ra) # 80000cfc <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e4e:	0001d717          	auipc	a4,0x1d
    80005e52:	1b270713          	addi	a4,a4,434 # 80023000 <disk>
    80005e56:	00c75793          	srli	a5,a4,0xc
    80005e5a:	2781                	sext.w	a5,a5
    80005e5c:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e5e:	0001f797          	auipc	a5,0x1f
    80005e62:	1a278793          	addi	a5,a5,418 # 80025000 <disk+0x2000>
    80005e66:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e68:	0001d717          	auipc	a4,0x1d
    80005e6c:	21870713          	addi	a4,a4,536 # 80023080 <disk+0x80>
    80005e70:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e72:	0001e717          	auipc	a4,0x1e
    80005e76:	18e70713          	addi	a4,a4,398 # 80024000 <disk+0x1000>
    80005e7a:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e7c:	4705                	li	a4,1
    80005e7e:	00e78c23          	sb	a4,24(a5)
    80005e82:	00e78ca3          	sb	a4,25(a5)
    80005e86:	00e78d23          	sb	a4,26(a5)
    80005e8a:	00e78da3          	sb	a4,27(a5)
    80005e8e:	00e78e23          	sb	a4,28(a5)
    80005e92:	00e78ea3          	sb	a4,29(a5)
    80005e96:	00e78f23          	sb	a4,30(a5)
    80005e9a:	00e78fa3          	sb	a4,31(a5)
}
    80005e9e:	60e2                	ld	ra,24(sp)
    80005ea0:	6442                	ld	s0,16(sp)
    80005ea2:	64a2                	ld	s1,8(sp)
    80005ea4:	6105                	addi	sp,sp,32
    80005ea6:	8082                	ret
    panic("could not find virtio disk");
    80005ea8:	00003517          	auipc	a0,0x3
    80005eac:	9c850513          	addi	a0,a0,-1592 # 80008870 <syscalls+0x388>
    80005eb0:	ffffa097          	auipc	ra,0xffffa
    80005eb4:	696080e7          	jalr	1686(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80005eb8:	00003517          	auipc	a0,0x3
    80005ebc:	9d850513          	addi	a0,a0,-1576 # 80008890 <syscalls+0x3a8>
    80005ec0:	ffffa097          	auipc	ra,0xffffa
    80005ec4:	686080e7          	jalr	1670(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	9e850513          	addi	a0,a0,-1560 # 800088b0 <syscalls+0x3c8>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	676080e7          	jalr	1654(ra) # 80000546 <panic>

0000000080005ed8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ed8:	7175                	addi	sp,sp,-144
    80005eda:	e506                	sd	ra,136(sp)
    80005edc:	e122                	sd	s0,128(sp)
    80005ede:	fca6                	sd	s1,120(sp)
    80005ee0:	f8ca                	sd	s2,112(sp)
    80005ee2:	f4ce                	sd	s3,104(sp)
    80005ee4:	f0d2                	sd	s4,96(sp)
    80005ee6:	ecd6                	sd	s5,88(sp)
    80005ee8:	e8da                	sd	s6,80(sp)
    80005eea:	e4de                	sd	s7,72(sp)
    80005eec:	e0e2                	sd	s8,64(sp)
    80005eee:	fc66                	sd	s9,56(sp)
    80005ef0:	f86a                	sd	s10,48(sp)
    80005ef2:	f46e                	sd	s11,40(sp)
    80005ef4:	0900                	addi	s0,sp,144
    80005ef6:	8aaa                	mv	s5,a0
    80005ef8:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005efa:	00c52c83          	lw	s9,12(a0)
    80005efe:	001c9c9b          	slliw	s9,s9,0x1
    80005f02:	1c82                	slli	s9,s9,0x20
    80005f04:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f08:	0001f517          	auipc	a0,0x1f
    80005f0c:	1a050513          	addi	a0,a0,416 # 800250a8 <disk+0x20a8>
    80005f10:	ffffb097          	auipc	ra,0xffffb
    80005f14:	cf0080e7          	jalr	-784(ra) # 80000c00 <acquire>
  for(int i = 0; i < 3; i++){
    80005f18:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f1a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f1c:	0001dc17          	auipc	s8,0x1d
    80005f20:	0e4c0c13          	addi	s8,s8,228 # 80023000 <disk>
    80005f24:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f26:	4b0d                	li	s6,3
    80005f28:	a0ad                	j	80005f92 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f2a:	00fc0733          	add	a4,s8,a5
    80005f2e:	975e                	add	a4,a4,s7
    80005f30:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f34:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f36:	0207c563          	bltz	a5,80005f60 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f3a:	2905                	addiw	s2,s2,1
    80005f3c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80005f3e:	19690c63          	beq	s2,s6,800060d6 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80005f42:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f44:	0001f717          	auipc	a4,0x1f
    80005f48:	0d470713          	addi	a4,a4,212 # 80025018 <disk+0x2018>
    80005f4c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f4e:	00074683          	lbu	a3,0(a4)
    80005f52:	fee1                	bnez	a3,80005f2a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f54:	2785                	addiw	a5,a5,1
    80005f56:	0705                	addi	a4,a4,1
    80005f58:	fe979be3          	bne	a5,s1,80005f4e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f5c:	57fd                	li	a5,-1
    80005f5e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f60:	01205d63          	blez	s2,80005f7a <virtio_disk_rw+0xa2>
    80005f64:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f66:	000a2503          	lw	a0,0(s4)
    80005f6a:	00000097          	auipc	ra,0x0
    80005f6e:	dac080e7          	jalr	-596(ra) # 80005d16 <free_desc>
      for(int j = 0; j < i; j++)
    80005f72:	2d85                	addiw	s11,s11,1
    80005f74:	0a11                	addi	s4,s4,4
    80005f76:	ff2d98e3          	bne	s11,s2,80005f66 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f7a:	0001f597          	auipc	a1,0x1f
    80005f7e:	12e58593          	addi	a1,a1,302 # 800250a8 <disk+0x20a8>
    80005f82:	0001f517          	auipc	a0,0x1f
    80005f86:	09650513          	addi	a0,a0,150 # 80025018 <disk+0x2018>
    80005f8a:	ffffc097          	auipc	ra,0xffffc
    80005f8e:	25e080e7          	jalr	606(ra) # 800021e8 <sleep>
  for(int i = 0; i < 3; i++){
    80005f92:	f8040a13          	addi	s4,s0,-128
{
    80005f96:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f98:	894e                	mv	s2,s3
    80005f9a:	b765                	j	80005f42 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f9c:	0001f717          	auipc	a4,0x1f
    80005fa0:	06473703          	ld	a4,100(a4) # 80025000 <disk+0x2000>
    80005fa4:	973e                	add	a4,a4,a5
    80005fa6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005faa:	0001d517          	auipc	a0,0x1d
    80005fae:	05650513          	addi	a0,a0,86 # 80023000 <disk>
    80005fb2:	0001f717          	auipc	a4,0x1f
    80005fb6:	04e70713          	addi	a4,a4,78 # 80025000 <disk+0x2000>
    80005fba:	6314                	ld	a3,0(a4)
    80005fbc:	96be                	add	a3,a3,a5
    80005fbe:	00c6d603          	lhu	a2,12(a3)
    80005fc2:	00166613          	ori	a2,a2,1
    80005fc6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fca:	f8842683          	lw	a3,-120(s0)
    80005fce:	6310                	ld	a2,0(a4)
    80005fd0:	97b2                	add	a5,a5,a2
    80005fd2:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005fd6:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005fda:	0612                	slli	a2,a2,0x4
    80005fdc:	962a                	add	a2,a2,a0
    80005fde:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fe2:	00469793          	slli	a5,a3,0x4
    80005fe6:	630c                	ld	a1,0(a4)
    80005fe8:	95be                	add	a1,a1,a5
    80005fea:	6689                	lui	a3,0x2
    80005fec:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005ff0:	96ca                	add	a3,a3,s2
    80005ff2:	96aa                	add	a3,a3,a0
    80005ff4:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005ff6:	6314                	ld	a3,0(a4)
    80005ff8:	96be                	add	a3,a3,a5
    80005ffa:	4585                	li	a1,1
    80005ffc:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ffe:	6314                	ld	a3,0(a4)
    80006000:	96be                	add	a3,a3,a5
    80006002:	4509                	li	a0,2
    80006004:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006008:	6314                	ld	a3,0(a4)
    8000600a:	97b6                	add	a5,a5,a3
    8000600c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006010:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006014:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006018:	6714                	ld	a3,8(a4)
    8000601a:	0026d783          	lhu	a5,2(a3)
    8000601e:	8b9d                	andi	a5,a5,7
    80006020:	0789                	addi	a5,a5,2
    80006022:	0786                	slli	a5,a5,0x1
    80006024:	96be                	add	a3,a3,a5
    80006026:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000602a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000602e:	6718                	ld	a4,8(a4)
    80006030:	00275783          	lhu	a5,2(a4)
    80006034:	2785                	addiw	a5,a5,1
    80006036:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000603a:	100017b7          	lui	a5,0x10001
    8000603e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006042:	004aa783          	lw	a5,4(s5)
    80006046:	02b79163          	bne	a5,a1,80006068 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000604a:	0001f917          	auipc	s2,0x1f
    8000604e:	05e90913          	addi	s2,s2,94 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006052:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006054:	85ca                	mv	a1,s2
    80006056:	8556                	mv	a0,s5
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	190080e7          	jalr	400(ra) # 800021e8 <sleep>
  while(b->disk == 1) {
    80006060:	004aa783          	lw	a5,4(s5)
    80006064:	fe9788e3          	beq	a5,s1,80006054 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006068:	f8042483          	lw	s1,-128(s0)
    8000606c:	20048713          	addi	a4,s1,512
    80006070:	0712                	slli	a4,a4,0x4
    80006072:	0001d797          	auipc	a5,0x1d
    80006076:	f8e78793          	addi	a5,a5,-114 # 80023000 <disk>
    8000607a:	97ba                	add	a5,a5,a4
    8000607c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006080:	0001f917          	auipc	s2,0x1f
    80006084:	f8090913          	addi	s2,s2,-128 # 80025000 <disk+0x2000>
    80006088:	a019                	j	8000608e <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    8000608a:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    8000608e:	8526                	mv	a0,s1
    80006090:	00000097          	auipc	ra,0x0
    80006094:	c86080e7          	jalr	-890(ra) # 80005d16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006098:	0492                	slli	s1,s1,0x4
    8000609a:	00093783          	ld	a5,0(s2)
    8000609e:	97a6                	add	a5,a5,s1
    800060a0:	00c7d703          	lhu	a4,12(a5)
    800060a4:	8b05                	andi	a4,a4,1
    800060a6:	f375                	bnez	a4,8000608a <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800060a8:	0001f517          	auipc	a0,0x1f
    800060ac:	00050513          	mv	a0,a0
    800060b0:	ffffb097          	auipc	ra,0xffffb
    800060b4:	c04080e7          	jalr	-1020(ra) # 80000cb4 <release>
}
    800060b8:	60aa                	ld	ra,136(sp)
    800060ba:	640a                	ld	s0,128(sp)
    800060bc:	74e6                	ld	s1,120(sp)
    800060be:	7946                	ld	s2,112(sp)
    800060c0:	79a6                	ld	s3,104(sp)
    800060c2:	7a06                	ld	s4,96(sp)
    800060c4:	6ae6                	ld	s5,88(sp)
    800060c6:	6b46                	ld	s6,80(sp)
    800060c8:	6ba6                	ld	s7,72(sp)
    800060ca:	6c06                	ld	s8,64(sp)
    800060cc:	7ce2                	ld	s9,56(sp)
    800060ce:	7d42                	ld	s10,48(sp)
    800060d0:	7da2                	ld	s11,40(sp)
    800060d2:	6149                	addi	sp,sp,144
    800060d4:	8082                	ret
  if(write)
    800060d6:	01a037b3          	snez	a5,s10
    800060da:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800060de:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800060e2:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060e6:	f8042483          	lw	s1,-128(s0)
    800060ea:	00449913          	slli	s2,s1,0x4
    800060ee:	0001f997          	auipc	s3,0x1f
    800060f2:	f1298993          	addi	s3,s3,-238 # 80025000 <disk+0x2000>
    800060f6:	0009ba03          	ld	s4,0(s3)
    800060fa:	9a4a                	add	s4,s4,s2
    800060fc:	f7040513          	addi	a0,s0,-144
    80006100:	ffffb097          	auipc	ra,0xffffb
    80006104:	fcc080e7          	jalr	-52(ra) # 800010cc <kvmpa>
    80006108:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000610c:	0009b783          	ld	a5,0(s3)
    80006110:	97ca                	add	a5,a5,s2
    80006112:	4741                	li	a4,16
    80006114:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006116:	0009b783          	ld	a5,0(s3)
    8000611a:	97ca                	add	a5,a5,s2
    8000611c:	4705                	li	a4,1
    8000611e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006122:	f8442783          	lw	a5,-124(s0)
    80006126:	0009b703          	ld	a4,0(s3)
    8000612a:	974a                	add	a4,a4,s2
    8000612c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006130:	0792                	slli	a5,a5,0x4
    80006132:	0009b703          	ld	a4,0(s3)
    80006136:	973e                	add	a4,a4,a5
    80006138:	058a8693          	addi	a3,s5,88
    8000613c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000613e:	0009b703          	ld	a4,0(s3)
    80006142:	973e                	add	a4,a4,a5
    80006144:	40000693          	li	a3,1024
    80006148:	c714                	sw	a3,8(a4)
  if(write)
    8000614a:	e40d19e3          	bnez	s10,80005f9c <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000614e:	0001f717          	auipc	a4,0x1f
    80006152:	eb273703          	ld	a4,-334(a4) # 80025000 <disk+0x2000>
    80006156:	973e                	add	a4,a4,a5
    80006158:	4689                	li	a3,2
    8000615a:	00d71623          	sh	a3,12(a4)
    8000615e:	b5b1                	j	80005faa <virtio_disk_rw+0xd2>

0000000080006160 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006160:	1101                	addi	sp,sp,-32
    80006162:	ec06                	sd	ra,24(sp)
    80006164:	e822                	sd	s0,16(sp)
    80006166:	e426                	sd	s1,8(sp)
    80006168:	e04a                	sd	s2,0(sp)
    8000616a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000616c:	0001f517          	auipc	a0,0x1f
    80006170:	f3c50513          	addi	a0,a0,-196 # 800250a8 <disk+0x20a8>
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	a8c080e7          	jalr	-1396(ra) # 80000c00 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000617c:	0001f717          	auipc	a4,0x1f
    80006180:	e8470713          	addi	a4,a4,-380 # 80025000 <disk+0x2000>
    80006184:	02075783          	lhu	a5,32(a4)
    80006188:	6b18                	ld	a4,16(a4)
    8000618a:	00275683          	lhu	a3,2(a4)
    8000618e:	8ebd                	xor	a3,a3,a5
    80006190:	8a9d                	andi	a3,a3,7
    80006192:	cab9                	beqz	a3,800061e8 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    80006194:	0001d917          	auipc	s2,0x1d
    80006198:	e6c90913          	addi	s2,s2,-404 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    8000619c:	0001f497          	auipc	s1,0x1f
    800061a0:	e6448493          	addi	s1,s1,-412 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800061a4:	078e                	slli	a5,a5,0x3
    800061a6:	973e                	add	a4,a4,a5
    800061a8:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800061aa:	20078713          	addi	a4,a5,512
    800061ae:	0712                	slli	a4,a4,0x4
    800061b0:	974a                	add	a4,a4,s2
    800061b2:	03074703          	lbu	a4,48(a4)
    800061b6:	ef21                	bnez	a4,8000620e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800061b8:	20078793          	addi	a5,a5,512
    800061bc:	0792                	slli	a5,a5,0x4
    800061be:	97ca                	add	a5,a5,s2
    800061c0:	7798                	ld	a4,40(a5)
    800061c2:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061c6:	7788                	ld	a0,40(a5)
    800061c8:	ffffc097          	auipc	ra,0xffffc
    800061cc:	1a0080e7          	jalr	416(ra) # 80002368 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061d0:	0204d783          	lhu	a5,32(s1)
    800061d4:	2785                	addiw	a5,a5,1
    800061d6:	8b9d                	andi	a5,a5,7
    800061d8:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061dc:	6898                	ld	a4,16(s1)
    800061de:	00275683          	lhu	a3,2(a4)
    800061e2:	8a9d                	andi	a3,a3,7
    800061e4:	fcf690e3          	bne	a3,a5,800061a4 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061e8:	10001737          	lui	a4,0x10001
    800061ec:	533c                	lw	a5,96(a4)
    800061ee:	8b8d                	andi	a5,a5,3
    800061f0:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061f2:	0001f517          	auipc	a0,0x1f
    800061f6:	eb650513          	addi	a0,a0,-330 # 800250a8 <disk+0x20a8>
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	aba080e7          	jalr	-1350(ra) # 80000cb4 <release>
}
    80006202:	60e2                	ld	ra,24(sp)
    80006204:	6442                	ld	s0,16(sp)
    80006206:	64a2                	ld	s1,8(sp)
    80006208:	6902                	ld	s2,0(sp)
    8000620a:	6105                	addi	sp,sp,32
    8000620c:	8082                	ret
      panic("virtio_disk_intr status");
    8000620e:	00002517          	auipc	a0,0x2
    80006212:	6c250513          	addi	a0,a0,1730 # 800088d0 <syscalls+0x3e8>
    80006216:	ffffa097          	auipc	ra,0xffffa
    8000621a:	330080e7          	jalr	816(ra) # 80000546 <panic>
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
