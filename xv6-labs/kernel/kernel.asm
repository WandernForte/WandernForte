
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
    80000060:	d4478793          	addi	a5,a5,-700 # 80005da0 <timervec>
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
    800000aa:	e5e78793          	addi	a5,a5,-418 # 80000f04 <main>
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
    80000110:	b4e080e7          	jalr	-1202(ra) # 80000c5a <acquire>
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
    8000012a:	3f0080e7          	jalr	1008(ra) # 80002516 <either_copyin>
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
    80000154:	bbe080e7          	jalr	-1090(ra) # 80000d0e <release>

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
    800001a2:	abc080e7          	jalr	-1348(ra) # 80000c5a <acquire>
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
    800001d0:	85a080e7          	jalr	-1958(ra) # 80001a26 <myproc>
    800001d4:	591c                	lw	a5,48(a0)
    800001d6:	e7b5                	bnez	a5,80000242 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d8:	85a6                	mv	a1,s1
    800001da:	854a                	mv	a0,s2
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	066080e7          	jalr	102(ra) # 80002242 <sleep>
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
    8000021c:	2a8080e7          	jalr	680(ra) # 800024c0 <either_copyout>
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
    80000238:	ada080e7          	jalr	-1318(ra) # 80000d0e <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xe4>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	5ee50513          	addi	a0,a0,1518 # 80011830 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ac4080e7          	jalr	-1340(ra) # 80000d0e <release>
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
    800002de:	980080e7          	jalr	-1664(ra) # 80000c5a <acquire>

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
    800002fc:	274080e7          	jalr	628(ra) # 8000256c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	53050513          	addi	a0,a0,1328 # 80011830 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	a06080e7          	jalr	-1530(ra) # 80000d0e <release>
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
    80000450:	f76080e7          	jalr	-138(ra) # 800023c2 <wakeup>
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
    80000472:	75c080e7          	jalr	1884(ra) # 80000bca <initlock>

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
    8000060c:	652080e7          	jalr	1618(ra) # 80000c5a <acquire>
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
    8000076a:	5a8080e7          	jalr	1448(ra) # 80000d0e <release>
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
    80000790:	43e080e7          	jalr	1086(ra) # 80000bca <initlock>
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
    800007e6:	3e8080e7          	jalr	1000(ra) # 80000bca <initlock>
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
    80000802:	410080e7          	jalr	1040(ra) # 80000c0e <push_off>

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
    80000830:	482080e7          	jalr	1154(ra) # 80000cae <pop_off>
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
    800008aa:	b1c080e7          	jalr	-1252(ra) # 800023c2 <wakeup>
    
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
    800008ee:	370080e7          	jalr	880(ra) # 80000c5a <acquire>
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
    80000944:	902080e7          	jalr	-1790(ra) # 80002242 <sleep>
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
    8000098a:	388080e7          	jalr	904(ra) # 80000d0e <release>
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
    800009f2:	26c080e7          	jalr	620(ra) # 80000c5a <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e48080e7          	jalr	-440(ra) # 8000083e <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	30e080e7          	jalr	782(ra) # 80000d0e <release>
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
    80000a42:	318080e7          	jalr	792(ra) # 80000d56 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	20a080e7          	jalr	522(ra) # 80000c5a <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	2aa080e7          	jalr	682(ra) # 80000d0e <release>
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
    80000af0:	0de080e7          	jalr	222(ra) # 80000bca <initlock>
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
    80000b28:	136080e7          	jalr	310(ra) # 80000c5a <acquire>
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
    80000b40:	1d2080e7          	jalr	466(ra) # 80000d0e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b44:	6605                	lui	a2,0x1
    80000b46:	4595                	li	a1,5
    80000b48:	8526                	mv	a0,s1
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	20c080e7          	jalr	524(ra) # 80000d56 <memset>
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
    80000b6a:	1a8080e7          	jalr	424(ra) # 80000d0e <release>
  if(r)
    80000b6e:	b7d5                	j	80000b52 <kalloc+0x42>

0000000080000b70 <cal_free_mem>:
//TODO calculate free memory
uint64 
cal_free_mem(){
    80000b70:	1101                	addi	sp,sp,-32
    80000b72:	ec06                	sd	ra,24(sp)
    80000b74:	e822                	sd	s0,16(sp)
    80000b76:	e426                	sd	s1,8(sp)
    80000b78:	1000                	addi	s0,sp,32
  struct run*r;
  int free_mem=0; 
  acquire(&kmem.lock);
    80000b7a:	00011497          	auipc	s1,0x11
    80000b7e:	db648493          	addi	s1,s1,-586 # 80011930 <kmem>
    80000b82:	8526                	mv	a0,s1
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	0d6080e7          	jalr	214(ra) # 80000c5a <acquire>
  r = kmem.freelist;
    80000b8c:	6c9c                	ld	a5,24(s1)
  int free_mem=0; 
    80000b8e:	4481                	li	s1,0
  if(!r){
    80000b90:	c39d                	beqz	a5,80000bb6 <cal_free_mem+0x46>
    release(&kmem.lock);
    return 0;
  }
  while(r){
    ++free_mem;
    80000b92:	2485                	addiw	s1,s1,1
    r = r->next;
    80000b94:	639c                	ld	a5,0(a5)
  while(r){
    80000b96:	fff5                	bnez	a5,80000b92 <cal_free_mem+0x22>
  }
  release(&kmem.lock);
    80000b98:	00011517          	auipc	a0,0x11
    80000b9c:	d9850513          	addi	a0,a0,-616 # 80011930 <kmem>
    80000ba0:	00000097          	auipc	ra,0x0
    80000ba4:	16e080e7          	jalr	366(ra) # 80000d0e <release>
  return free_mem*PGSIZE;
    80000ba8:	00c4951b          	slliw	a0,s1,0xc
}
    80000bac:	60e2                	ld	ra,24(sp)
    80000bae:	6442                	ld	s0,16(sp)
    80000bb0:	64a2                	ld	s1,8(sp)
    80000bb2:	6105                	addi	sp,sp,32
    80000bb4:	8082                	ret
    release(&kmem.lock);
    80000bb6:	00011517          	auipc	a0,0x11
    80000bba:	d7a50513          	addi	a0,a0,-646 # 80011930 <kmem>
    80000bbe:	00000097          	auipc	ra,0x0
    80000bc2:	150080e7          	jalr	336(ra) # 80000d0e <release>
    return 0;
    80000bc6:	4501                	li	a0,0
    80000bc8:	b7d5                	j	80000bac <cal_free_mem+0x3c>

0000000080000bca <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bca:	1141                	addi	sp,sp,-16
    80000bcc:	e422                	sd	s0,8(sp)
    80000bce:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd0:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd2:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bd6:	00053823          	sd	zero,16(a0)
}
    80000bda:	6422                	ld	s0,8(sp)
    80000bdc:	0141                	addi	sp,sp,16
    80000bde:	8082                	ret

0000000080000be0 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	411c                	lw	a5,0(a0)
    80000be2:	e399                	bnez	a5,80000be8 <holding+0x8>
    80000be4:	4501                	li	a0,0
  return r;
}
    80000be6:	8082                	ret
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	6904                	ld	s1,16(a0)
    80000bf4:	00001097          	auipc	ra,0x1
    80000bf8:	e16080e7          	jalr	-490(ra) # 80001a0a <mycpu>
    80000bfc:	40a48533          	sub	a0,s1,a0
    80000c00:	00153513          	seqz	a0,a0
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret

0000000080000c0e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c0e:	1101                	addi	sp,sp,-32
    80000c10:	ec06                	sd	ra,24(sp)
    80000c12:	e822                	sd	s0,16(sp)
    80000c14:	e426                	sd	s1,8(sp)
    80000c16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c18:	100024f3          	csrr	s1,sstatus
    80000c1c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c20:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c22:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c26:	00001097          	auipc	ra,0x1
    80000c2a:	de4080e7          	jalr	-540(ra) # 80001a0a <mycpu>
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	cf89                	beqz	a5,80000c4a <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	dd8080e7          	jalr	-552(ra) # 80001a0a <mycpu>
    80000c3a:	5d3c                	lw	a5,120(a0)
    80000c3c:	2785                	addiw	a5,a5,1
    80000c3e:	dd3c                	sw	a5,120(a0)
}
    80000c40:	60e2                	ld	ra,24(sp)
    80000c42:	6442                	ld	s0,16(sp)
    80000c44:	64a2                	ld	s1,8(sp)
    80000c46:	6105                	addi	sp,sp,32
    80000c48:	8082                	ret
    mycpu()->intena = old;
    80000c4a:	00001097          	auipc	ra,0x1
    80000c4e:	dc0080e7          	jalr	-576(ra) # 80001a0a <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8085                	srli	s1,s1,0x1
    80000c54:	8885                	andi	s1,s1,1
    80000c56:	dd64                	sw	s1,124(a0)
    80000c58:	bfe9                	j	80000c32 <push_off+0x24>

0000000080000c5a <acquire>:
{
    80000c5a:	1101                	addi	sp,sp,-32
    80000c5c:	ec06                	sd	ra,24(sp)
    80000c5e:	e822                	sd	s0,16(sp)
    80000c60:	e426                	sd	s1,8(sp)
    80000c62:	1000                	addi	s0,sp,32
    80000c64:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c66:	00000097          	auipc	ra,0x0
    80000c6a:	fa8080e7          	jalr	-88(ra) # 80000c0e <push_off>
  if(holding(lk))
    80000c6e:	8526                	mv	a0,s1
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	f70080e7          	jalr	-144(ra) # 80000be0 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c78:	4705                	li	a4,1
  if(holding(lk))
    80000c7a:	e115                	bnez	a0,80000c9e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7c:	87ba                	mv	a5,a4
    80000c7e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c82:	2781                	sext.w	a5,a5
    80000c84:	ffe5                	bnez	a5,80000c7c <acquire+0x22>
  __sync_synchronize();
    80000c86:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c8a:	00001097          	auipc	ra,0x1
    80000c8e:	d80080e7          	jalr	-640(ra) # 80001a0a <mycpu>
    80000c92:	e888                	sd	a0,16(s1)
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6105                	addi	sp,sp,32
    80000c9c:	8082                	ret
    panic("acquire");
    80000c9e:	00007517          	auipc	a0,0x7
    80000ca2:	3d250513          	addi	a0,a0,978 # 80008070 <digits+0x30>
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	8a0080e7          	jalr	-1888(ra) # 80000546 <panic>

0000000080000cae <pop_off>:

void
pop_off(void)
{
    80000cae:	1141                	addi	sp,sp,-16
    80000cb0:	e406                	sd	ra,8(sp)
    80000cb2:	e022                	sd	s0,0(sp)
    80000cb4:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cb6:	00001097          	auipc	ra,0x1
    80000cba:	d54080e7          	jalr	-684(ra) # 80001a0a <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cbe:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc2:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cc4:	e78d                	bnez	a5,80000cee <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	02f05b63          	blez	a5,80000cfe <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ccc:	37fd                	addiw	a5,a5,-1
    80000cce:	0007871b          	sext.w	a4,a5
    80000cd2:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cd4:	eb09                	bnez	a4,80000ce6 <pop_off+0x38>
    80000cd6:	5d7c                	lw	a5,124(a0)
    80000cd8:	c799                	beqz	a5,80000ce6 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cda:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cde:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce2:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000ce6:	60a2                	ld	ra,8(sp)
    80000ce8:	6402                	ld	s0,0(sp)
    80000cea:	0141                	addi	sp,sp,16
    80000cec:	8082                	ret
    panic("pop_off - interruptible");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	38a50513          	addi	a0,a0,906 # 80008078 <digits+0x38>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	850080e7          	jalr	-1968(ra) # 80000546 <panic>
    panic("pop_off");
    80000cfe:	00007517          	auipc	a0,0x7
    80000d02:	39250513          	addi	a0,a0,914 # 80008090 <digits+0x50>
    80000d06:	00000097          	auipc	ra,0x0
    80000d0a:	840080e7          	jalr	-1984(ra) # 80000546 <panic>

0000000080000d0e <release>:
{
    80000d0e:	1101                	addi	sp,sp,-32
    80000d10:	ec06                	sd	ra,24(sp)
    80000d12:	e822                	sd	s0,16(sp)
    80000d14:	e426                	sd	s1,8(sp)
    80000d16:	1000                	addi	s0,sp,32
    80000d18:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d1a:	00000097          	auipc	ra,0x0
    80000d1e:	ec6080e7          	jalr	-314(ra) # 80000be0 <holding>
    80000d22:	c115                	beqz	a0,80000d46 <release+0x38>
  lk->cpu = 0;
    80000d24:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d28:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d2c:	0f50000f          	fence	iorw,ow
    80000d30:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d34:	00000097          	auipc	ra,0x0
    80000d38:	f7a080e7          	jalr	-134(ra) # 80000cae <pop_off>
}
    80000d3c:	60e2                	ld	ra,24(sp)
    80000d3e:	6442                	ld	s0,16(sp)
    80000d40:	64a2                	ld	s1,8(sp)
    80000d42:	6105                	addi	sp,sp,32
    80000d44:	8082                	ret
    panic("release");
    80000d46:	00007517          	auipc	a0,0x7
    80000d4a:	35250513          	addi	a0,a0,850 # 80008098 <digits+0x58>
    80000d4e:	fffff097          	auipc	ra,0xfffff
    80000d52:	7f8080e7          	jalr	2040(ra) # 80000546 <panic>

0000000080000d56 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d5c:	ca19                	beqz	a2,80000d72 <memset+0x1c>
    80000d5e:	87aa                	mv	a5,a0
    80000d60:	1602                	slli	a2,a2,0x20
    80000d62:	9201                	srli	a2,a2,0x20
    80000d64:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d68:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d6c:	0785                	addi	a5,a5,1
    80000d6e:	fee79de3          	bne	a5,a4,80000d68 <memset+0x12>
  }
  return dst;
}
    80000d72:	6422                	ld	s0,8(sp)
    80000d74:	0141                	addi	sp,sp,16
    80000d76:	8082                	ret

0000000080000d78 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d78:	1141                	addi	sp,sp,-16
    80000d7a:	e422                	sd	s0,8(sp)
    80000d7c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d7e:	ca05                	beqz	a2,80000dae <memcmp+0x36>
    80000d80:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d84:	1682                	slli	a3,a3,0x20
    80000d86:	9281                	srli	a3,a3,0x20
    80000d88:	0685                	addi	a3,a3,1
    80000d8a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d8c:	00054783          	lbu	a5,0(a0)
    80000d90:	0005c703          	lbu	a4,0(a1)
    80000d94:	00e79863          	bne	a5,a4,80000da4 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d98:	0505                	addi	a0,a0,1
    80000d9a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d9c:	fed518e3          	bne	a0,a3,80000d8c <memcmp+0x14>
  }

  return 0;
    80000da0:	4501                	li	a0,0
    80000da2:	a019                	j	80000da8 <memcmp+0x30>
      return *s1 - *s2;
    80000da4:	40e7853b          	subw	a0,a5,a4
}
    80000da8:	6422                	ld	s0,8(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret
  return 0;
    80000dae:	4501                	li	a0,0
    80000db0:	bfe5                	j	80000da8 <memcmp+0x30>

0000000080000db2 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e422                	sd	s0,8(sp)
    80000db6:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000db8:	02a5e563          	bltu	a1,a0,80000de2 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dbc:	fff6069b          	addiw	a3,a2,-1
    80000dc0:	ce11                	beqz	a2,80000ddc <memmove+0x2a>
    80000dc2:	1682                	slli	a3,a3,0x20
    80000dc4:	9281                	srli	a3,a3,0x20
    80000dc6:	0685                	addi	a3,a3,1
    80000dc8:	96ae                	add	a3,a3,a1
    80000dca:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000dcc:	0585                	addi	a1,a1,1
    80000dce:	0785                	addi	a5,a5,1
    80000dd0:	fff5c703          	lbu	a4,-1(a1)
    80000dd4:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dd8:	fed59ae3          	bne	a1,a3,80000dcc <memmove+0x1a>

  return dst;
}
    80000ddc:	6422                	ld	s0,8(sp)
    80000dde:	0141                	addi	sp,sp,16
    80000de0:	8082                	ret
  if(s < d && s + n > d){
    80000de2:	02061713          	slli	a4,a2,0x20
    80000de6:	9301                	srli	a4,a4,0x20
    80000de8:	00e587b3          	add	a5,a1,a4
    80000dec:	fcf578e3          	bgeu	a0,a5,80000dbc <memmove+0xa>
    d += n;
    80000df0:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000df2:	fff6069b          	addiw	a3,a2,-1
    80000df6:	d27d                	beqz	a2,80000ddc <memmove+0x2a>
    80000df8:	02069613          	slli	a2,a3,0x20
    80000dfc:	9201                	srli	a2,a2,0x20
    80000dfe:	fff64613          	not	a2,a2
    80000e02:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e04:	17fd                	addi	a5,a5,-1
    80000e06:	177d                	addi	a4,a4,-1 # ffffffffffffefff <end+0xffffffff7ffd8fff>
    80000e08:	0007c683          	lbu	a3,0(a5)
    80000e0c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e10:	fef61ae3          	bne	a2,a5,80000e04 <memmove+0x52>
    80000e14:	b7e1                	j	80000ddc <memmove+0x2a>

0000000080000e16 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e16:	1141                	addi	sp,sp,-16
    80000e18:	e406                	sd	ra,8(sp)
    80000e1a:	e022                	sd	s0,0(sp)
    80000e1c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	f94080e7          	jalr	-108(ra) # 80000db2 <memmove>
}
    80000e26:	60a2                	ld	ra,8(sp)
    80000e28:	6402                	ld	s0,0(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret

0000000080000e2e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e2e:	1141                	addi	sp,sp,-16
    80000e30:	e422                	sd	s0,8(sp)
    80000e32:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e34:	ce11                	beqz	a2,80000e50 <strncmp+0x22>
    80000e36:	00054783          	lbu	a5,0(a0)
    80000e3a:	cf89                	beqz	a5,80000e54 <strncmp+0x26>
    80000e3c:	0005c703          	lbu	a4,0(a1)
    80000e40:	00f71a63          	bne	a4,a5,80000e54 <strncmp+0x26>
    n--, p++, q++;
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	0505                	addi	a0,a0,1
    80000e48:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e4a:	f675                	bnez	a2,80000e36 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	a809                	j	80000e60 <strncmp+0x32>
    80000e50:	4501                	li	a0,0
    80000e52:	a039                	j	80000e60 <strncmp+0x32>
  if(n == 0)
    80000e54:	ca09                	beqz	a2,80000e66 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e56:	00054503          	lbu	a0,0(a0)
    80000e5a:	0005c783          	lbu	a5,0(a1)
    80000e5e:	9d1d                	subw	a0,a0,a5
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret
    return 0;
    80000e66:	4501                	li	a0,0
    80000e68:	bfe5                	j	80000e60 <strncmp+0x32>

0000000080000e6a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e70:	872a                	mv	a4,a0
    80000e72:	8832                	mv	a6,a2
    80000e74:	367d                	addiw	a2,a2,-1
    80000e76:	01005963          	blez	a6,80000e88 <strncpy+0x1e>
    80000e7a:	0705                	addi	a4,a4,1
    80000e7c:	0005c783          	lbu	a5,0(a1)
    80000e80:	fef70fa3          	sb	a5,-1(a4)
    80000e84:	0585                	addi	a1,a1,1
    80000e86:	f7f5                	bnez	a5,80000e72 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e88:	86ba                	mv	a3,a4
    80000e8a:	00c05c63          	blez	a2,80000ea2 <strncpy+0x38>
    *s++ = 0;
    80000e8e:	0685                	addi	a3,a3,1
    80000e90:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e94:	40d707bb          	subw	a5,a4,a3
    80000e98:	37fd                	addiw	a5,a5,-1
    80000e9a:	010787bb          	addw	a5,a5,a6
    80000e9e:	fef048e3          	bgtz	a5,80000e8e <strncpy+0x24>
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eae:	02c05363          	blez	a2,80000ed4 <safestrcpy+0x2c>
    80000eb2:	fff6069b          	addiw	a3,a2,-1
    80000eb6:	1682                	slli	a3,a3,0x20
    80000eb8:	9281                	srli	a3,a3,0x20
    80000eba:	96ae                	add	a3,a3,a1
    80000ebc:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ebe:	00d58963          	beq	a1,a3,80000ed0 <safestrcpy+0x28>
    80000ec2:	0585                	addi	a1,a1,1
    80000ec4:	0785                	addi	a5,a5,1
    80000ec6:	fff5c703          	lbu	a4,-1(a1)
    80000eca:	fee78fa3          	sb	a4,-1(a5)
    80000ece:	fb65                	bnez	a4,80000ebe <safestrcpy+0x16>
    ;
  *s = 0;
    80000ed0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ed4:	6422                	ld	s0,8(sp)
    80000ed6:	0141                	addi	sp,sp,16
    80000ed8:	8082                	ret

0000000080000eda <strlen>:

int
strlen(const char *s)
{
    80000eda:	1141                	addi	sp,sp,-16
    80000edc:	e422                	sd	s0,8(sp)
    80000ede:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ee0:	00054783          	lbu	a5,0(a0)
    80000ee4:	cf91                	beqz	a5,80000f00 <strlen+0x26>
    80000ee6:	0505                	addi	a0,a0,1
    80000ee8:	87aa                	mv	a5,a0
    80000eea:	4685                	li	a3,1
    80000eec:	9e89                	subw	a3,a3,a0
    80000eee:	00f6853b          	addw	a0,a3,a5
    80000ef2:	0785                	addi	a5,a5,1
    80000ef4:	fff7c703          	lbu	a4,-1(a5)
    80000ef8:	fb7d                	bnez	a4,80000eee <strlen+0x14>
    ;
  return n;
}
    80000efa:	6422                	ld	s0,8(sp)
    80000efc:	0141                	addi	sp,sp,16
    80000efe:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f00:	4501                	li	a0,0
    80000f02:	bfe5                	j	80000efa <strlen+0x20>

0000000080000f04 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f04:	1141                	addi	sp,sp,-16
    80000f06:	e406                	sd	ra,8(sp)
    80000f08:	e022                	sd	s0,0(sp)
    80000f0a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aee080e7          	jalr	-1298(ra) # 800019fa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f14:	00008717          	auipc	a4,0x8
    80000f18:	0f870713          	addi	a4,a4,248 # 8000900c <started>
  if(cpuid() == 0){
    80000f1c:	c139                	beqz	a0,80000f62 <main+0x5e>
    while(started == 0)
    80000f1e:	431c                	lw	a5,0(a4)
    80000f20:	2781                	sext.w	a5,a5
    80000f22:	dff5                	beqz	a5,80000f1e <main+0x1a>
      ;
    __sync_synchronize();
    80000f24:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	ad2080e7          	jalr	-1326(ra) # 800019fa <cpuid>
    80000f30:	85aa                	mv	a1,a0
    80000f32:	00007517          	auipc	a0,0x7
    80000f36:	18650513          	addi	a0,a0,390 # 800080b8 <digits+0x78>
    80000f3a:	fffff097          	auipc	ra,0xfffff
    80000f3e:	656080e7          	jalr	1622(ra) # 80000590 <printf>
    kvminithart();    // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	0d8080e7          	jalr	216(ra) # 8000101a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	862080e7          	jalr	-1950(ra) # 800027ac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	e8e080e7          	jalr	-370(ra) # 80005de0 <plicinithart>
  }

  scheduler();        
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	00c080e7          	jalr	12(ra) # 80001f66 <scheduler>
    consoleinit();
    80000f62:	fffff097          	auipc	ra,0xfffff
    80000f66:	4f4080e7          	jalr	1268(ra) # 80000456 <consoleinit>
    printfinit();
    80000f6a:	00000097          	auipc	ra,0x0
    80000f6e:	806080e7          	jalr	-2042(ra) # 80000770 <printfinit>
    printf("\n");
    80000f72:	00007517          	auipc	a0,0x7
    80000f76:	15650513          	addi	a0,a0,342 # 800080c8 <digits+0x88>
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	616080e7          	jalr	1558(ra) # 80000590 <printf>
    printf("xv6 kernel is booting\n");
    80000f82:	00007517          	auipc	a0,0x7
    80000f86:	11e50513          	addi	a0,a0,286 # 800080a0 <digits+0x60>
    80000f8a:	fffff097          	auipc	ra,0xfffff
    80000f8e:	606080e7          	jalr	1542(ra) # 80000590 <printf>
    printf("\n");
    80000f92:	00007517          	auipc	a0,0x7
    80000f96:	13650513          	addi	a0,a0,310 # 800080c8 <digits+0x88>
    80000f9a:	fffff097          	auipc	ra,0xfffff
    80000f9e:	5f6080e7          	jalr	1526(ra) # 80000590 <printf>
    kinit();         // physical page allocator
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	b32080e7          	jalr	-1230(ra) # 80000ad4 <kinit>
    kvminit();       // create kernel page table
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	2a0080e7          	jalr	672(ra) # 8000124a <kvminit>
    kvminithart();   // turn on paging
    80000fb2:	00000097          	auipc	ra,0x0
    80000fb6:	068080e7          	jalr	104(ra) # 8000101a <kvminithart>
    procinit();      // process table
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	970080e7          	jalr	-1680(ra) # 8000192a <procinit>
    trapinit();      // trap vectors
    80000fc2:	00001097          	auipc	ra,0x1
    80000fc6:	7c2080e7          	jalr	1986(ra) # 80002784 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	7e2080e7          	jalr	2018(ra) # 800027ac <trapinithart>
    plicinit();      // set up interrupt controller
    80000fd2:	00005097          	auipc	ra,0x5
    80000fd6:	df8080e7          	jalr	-520(ra) # 80005dca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fda:	00005097          	auipc	ra,0x5
    80000fde:	e06080e7          	jalr	-506(ra) # 80005de0 <plicinithart>
    binit();         // buffer cache
    80000fe2:	00002097          	auipc	ra,0x2
    80000fe6:	fa8080e7          	jalr	-88(ra) # 80002f8a <binit>
    iinit();         // inode cache
    80000fea:	00002097          	auipc	ra,0x2
    80000fee:	636080e7          	jalr	1590(ra) # 80003620 <iinit>
    fileinit();      // file table
    80000ff2:	00003097          	auipc	ra,0x3
    80000ff6:	5d8080e7          	jalr	1496(ra) # 800045ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ffa:	00005097          	auipc	ra,0x5
    80000ffe:	eec080e7          	jalr	-276(ra) # 80005ee6 <virtio_disk_init>
    userinit();      // first user process
    80001002:	00001097          	auipc	ra,0x1
    80001006:	cee080e7          	jalr	-786(ra) # 80001cf0 <userinit>
    __sync_synchronize();
    8000100a:	0ff0000f          	fence
    started = 1;
    8000100e:	4785                	li	a5,1
    80001010:	00008717          	auipc	a4,0x8
    80001014:	fef72e23          	sw	a5,-4(a4) # 8000900c <started>
    80001018:	b789                	j	80000f5a <main+0x56>

000000008000101a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000101a:	1141                	addi	sp,sp,-16
    8000101c:	e422                	sd	s0,8(sp)
    8000101e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001020:	00008797          	auipc	a5,0x8
    80001024:	ff07b783          	ld	a5,-16(a5) # 80009010 <kernel_pagetable>
    80001028:	83b1                	srli	a5,a5,0xc
    8000102a:	577d                	li	a4,-1
    8000102c:	177e                	slli	a4,a4,0x3f
    8000102e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001030:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001034:	12000073          	sfence.vma
  sfence_vma();
}
    80001038:	6422                	ld	s0,8(sp)
    8000103a:	0141                	addi	sp,sp,16
    8000103c:	8082                	ret

000000008000103e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000103e:	7139                	addi	sp,sp,-64
    80001040:	fc06                	sd	ra,56(sp)
    80001042:	f822                	sd	s0,48(sp)
    80001044:	f426                	sd	s1,40(sp)
    80001046:	f04a                	sd	s2,32(sp)
    80001048:	ec4e                	sd	s3,24(sp)
    8000104a:	e852                	sd	s4,16(sp)
    8000104c:	e456                	sd	s5,8(sp)
    8000104e:	e05a                	sd	s6,0(sp)
    80001050:	0080                	addi	s0,sp,64
    80001052:	84aa                	mv	s1,a0
    80001054:	89ae                	mv	s3,a1
    80001056:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001058:	57fd                	li	a5,-1
    8000105a:	83e9                	srli	a5,a5,0x1a
    8000105c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000105e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001060:	04b7f263          	bgeu	a5,a1,800010a4 <walk+0x66>
    panic("walk");
    80001064:	00007517          	auipc	a0,0x7
    80001068:	06c50513          	addi	a0,a0,108 # 800080d0 <digits+0x90>
    8000106c:	fffff097          	auipc	ra,0xfffff
    80001070:	4da080e7          	jalr	1242(ra) # 80000546 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001074:	060a8663          	beqz	s5,800010e0 <walk+0xa2>
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	a98080e7          	jalr	-1384(ra) # 80000b10 <kalloc>
    80001080:	84aa                	mv	s1,a0
    80001082:	c529                	beqz	a0,800010cc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001084:	6605                	lui	a2,0x1
    80001086:	4581                	li	a1,0
    80001088:	00000097          	auipc	ra,0x0
    8000108c:	cce080e7          	jalr	-818(ra) # 80000d56 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001090:	00c4d793          	srli	a5,s1,0xc
    80001094:	07aa                	slli	a5,a5,0xa
    80001096:	0017e793          	ori	a5,a5,1
    8000109a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000109e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd8ff7>
    800010a0:	036a0063          	beq	s4,s6,800010c0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010a4:	0149d933          	srl	s2,s3,s4
    800010a8:	1ff97913          	andi	s2,s2,511
    800010ac:	090e                	slli	s2,s2,0x3
    800010ae:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010b0:	00093483          	ld	s1,0(s2)
    800010b4:	0014f793          	andi	a5,s1,1
    800010b8:	dfd5                	beqz	a5,80001074 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ba:	80a9                	srli	s1,s1,0xa
    800010bc:	04b2                	slli	s1,s1,0xc
    800010be:	b7c5                	j	8000109e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010c0:	00c9d513          	srli	a0,s3,0xc
    800010c4:	1ff57513          	andi	a0,a0,511
    800010c8:	050e                	slli	a0,a0,0x3
    800010ca:	9526                	add	a0,a0,s1
}
    800010cc:	70e2                	ld	ra,56(sp)
    800010ce:	7442                	ld	s0,48(sp)
    800010d0:	74a2                	ld	s1,40(sp)
    800010d2:	7902                	ld	s2,32(sp)
    800010d4:	69e2                	ld	s3,24(sp)
    800010d6:	6a42                	ld	s4,16(sp)
    800010d8:	6aa2                	ld	s5,8(sp)
    800010da:	6b02                	ld	s6,0(sp)
    800010dc:	6121                	addi	sp,sp,64
    800010de:	8082                	ret
        return 0;
    800010e0:	4501                	li	a0,0
    800010e2:	b7ed                	j	800010cc <walk+0x8e>

00000000800010e4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010e4:	57fd                	li	a5,-1
    800010e6:	83e9                	srli	a5,a5,0x1a
    800010e8:	00b7f463          	bgeu	a5,a1,800010f0 <walkaddr+0xc>
    return 0;
    800010ec:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010ee:	8082                	ret
{
    800010f0:	1141                	addi	sp,sp,-16
    800010f2:	e406                	sd	ra,8(sp)
    800010f4:	e022                	sd	s0,0(sp)
    800010f6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010f8:	4601                	li	a2,0
    800010fa:	00000097          	auipc	ra,0x0
    800010fe:	f44080e7          	jalr	-188(ra) # 8000103e <walk>
  if(pte == 0)
    80001102:	c105                	beqz	a0,80001122 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001104:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001106:	0117f693          	andi	a3,a5,17
    8000110a:	4745                	li	a4,17
    return 0;
    8000110c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000110e:	00e68663          	beq	a3,a4,8000111a <walkaddr+0x36>
}
    80001112:	60a2                	ld	ra,8(sp)
    80001114:	6402                	ld	s0,0(sp)
    80001116:	0141                	addi	sp,sp,16
    80001118:	8082                	ret
  pa = PTE2PA(*pte);
    8000111a:	83a9                	srli	a5,a5,0xa
    8000111c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001120:	bfcd                	j	80001112 <walkaddr+0x2e>
    return 0;
    80001122:	4501                	li	a0,0
    80001124:	b7fd                	j	80001112 <walkaddr+0x2e>

0000000080001126 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001126:	1101                	addi	sp,sp,-32
    80001128:	ec06                	sd	ra,24(sp)
    8000112a:	e822                	sd	s0,16(sp)
    8000112c:	e426                	sd	s1,8(sp)
    8000112e:	1000                	addi	s0,sp,32
    80001130:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001132:	1552                	slli	a0,a0,0x34
    80001134:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001138:	4601                	li	a2,0
    8000113a:	00008517          	auipc	a0,0x8
    8000113e:	ed653503          	ld	a0,-298(a0) # 80009010 <kernel_pagetable>
    80001142:	00000097          	auipc	ra,0x0
    80001146:	efc080e7          	jalr	-260(ra) # 8000103e <walk>
  if(pte == 0)
    8000114a:	cd09                	beqz	a0,80001164 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000114c:	6108                	ld	a0,0(a0)
    8000114e:	00157793          	andi	a5,a0,1
    80001152:	c38d                	beqz	a5,80001174 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001154:	8129                	srli	a0,a0,0xa
    80001156:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001158:	9526                	add	a0,a0,s1
    8000115a:	60e2                	ld	ra,24(sp)
    8000115c:	6442                	ld	s0,16(sp)
    8000115e:	64a2                	ld	s1,8(sp)
    80001160:	6105                	addi	sp,sp,32
    80001162:	8082                	ret
    panic("kvmpa");
    80001164:	00007517          	auipc	a0,0x7
    80001168:	f7450513          	addi	a0,a0,-140 # 800080d8 <digits+0x98>
    8000116c:	fffff097          	auipc	ra,0xfffff
    80001170:	3da080e7          	jalr	986(ra) # 80000546 <panic>
    panic("kvmpa");
    80001174:	00007517          	auipc	a0,0x7
    80001178:	f6450513          	addi	a0,a0,-156 # 800080d8 <digits+0x98>
    8000117c:	fffff097          	auipc	ra,0xfffff
    80001180:	3ca080e7          	jalr	970(ra) # 80000546 <panic>

0000000080001184 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001184:	715d                	addi	sp,sp,-80
    80001186:	e486                	sd	ra,72(sp)
    80001188:	e0a2                	sd	s0,64(sp)
    8000118a:	fc26                	sd	s1,56(sp)
    8000118c:	f84a                	sd	s2,48(sp)
    8000118e:	f44e                	sd	s3,40(sp)
    80001190:	f052                	sd	s4,32(sp)
    80001192:	ec56                	sd	s5,24(sp)
    80001194:	e85a                	sd	s6,16(sp)
    80001196:	e45e                	sd	s7,8(sp)
    80001198:	0880                	addi	s0,sp,80
    8000119a:	8aaa                	mv	s5,a0
    8000119c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000119e:	777d                	lui	a4,0xfffff
    800011a0:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011a4:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800011a8:	99ae                	add	s3,s3,a1
    800011aa:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011ae:	893e                	mv	s2,a5
    800011b0:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011b4:	6b85                	lui	s7,0x1
    800011b6:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ba:	4605                	li	a2,1
    800011bc:	85ca                	mv	a1,s2
    800011be:	8556                	mv	a0,s5
    800011c0:	00000097          	auipc	ra,0x0
    800011c4:	e7e080e7          	jalr	-386(ra) # 8000103e <walk>
    800011c8:	c51d                	beqz	a0,800011f6 <mappages+0x72>
    if(*pte & PTE_V)
    800011ca:	611c                	ld	a5,0(a0)
    800011cc:	8b85                	andi	a5,a5,1
    800011ce:	ef81                	bnez	a5,800011e6 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d0:	80b1                	srli	s1,s1,0xc
    800011d2:	04aa                	slli	s1,s1,0xa
    800011d4:	0164e4b3          	or	s1,s1,s6
    800011d8:	0014e493          	ori	s1,s1,1
    800011dc:	e104                	sd	s1,0(a0)
    if(a == last)
    800011de:	03390863          	beq	s2,s3,8000120e <mappages+0x8a>
    a += PGSIZE;
    800011e2:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e4:	bfc9                	j	800011b6 <mappages+0x32>
      panic("remap");
    800011e6:	00007517          	auipc	a0,0x7
    800011ea:	efa50513          	addi	a0,a0,-262 # 800080e0 <digits+0xa0>
    800011ee:	fffff097          	auipc	ra,0xfffff
    800011f2:	358080e7          	jalr	856(ra) # 80000546 <panic>
      return -1;
    800011f6:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011f8:	60a6                	ld	ra,72(sp)
    800011fa:	6406                	ld	s0,64(sp)
    800011fc:	74e2                	ld	s1,56(sp)
    800011fe:	7942                	ld	s2,48(sp)
    80001200:	79a2                	ld	s3,40(sp)
    80001202:	7a02                	ld	s4,32(sp)
    80001204:	6ae2                	ld	s5,24(sp)
    80001206:	6b42                	ld	s6,16(sp)
    80001208:	6ba2                	ld	s7,8(sp)
    8000120a:	6161                	addi	sp,sp,80
    8000120c:	8082                	ret
  return 0;
    8000120e:	4501                	li	a0,0
    80001210:	b7e5                	j	800011f8 <mappages+0x74>

0000000080001212 <kvmmap>:
{
    80001212:	1141                	addi	sp,sp,-16
    80001214:	e406                	sd	ra,8(sp)
    80001216:	e022                	sd	s0,0(sp)
    80001218:	0800                	addi	s0,sp,16
    8000121a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000121c:	86ae                	mv	a3,a1
    8000121e:	85aa                	mv	a1,a0
    80001220:	00008517          	auipc	a0,0x8
    80001224:	df053503          	ld	a0,-528(a0) # 80009010 <kernel_pagetable>
    80001228:	00000097          	auipc	ra,0x0
    8000122c:	f5c080e7          	jalr	-164(ra) # 80001184 <mappages>
    80001230:	e509                	bnez	a0,8000123a <kvmmap+0x28>
}
    80001232:	60a2                	ld	ra,8(sp)
    80001234:	6402                	ld	s0,0(sp)
    80001236:	0141                	addi	sp,sp,16
    80001238:	8082                	ret
    panic("kvmmap");
    8000123a:	00007517          	auipc	a0,0x7
    8000123e:	eae50513          	addi	a0,a0,-338 # 800080e8 <digits+0xa8>
    80001242:	fffff097          	auipc	ra,0xfffff
    80001246:	304080e7          	jalr	772(ra) # 80000546 <panic>

000000008000124a <kvminit>:
{
    8000124a:	1101                	addi	sp,sp,-32
    8000124c:	ec06                	sd	ra,24(sp)
    8000124e:	e822                	sd	s0,16(sp)
    80001250:	e426                	sd	s1,8(sp)
    80001252:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001254:	00000097          	auipc	ra,0x0
    80001258:	8bc080e7          	jalr	-1860(ra) # 80000b10 <kalloc>
    8000125c:	00008717          	auipc	a4,0x8
    80001260:	daa73a23          	sd	a0,-588(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001264:	6605                	lui	a2,0x1
    80001266:	4581                	li	a1,0
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	aee080e7          	jalr	-1298(ra) # 80000d56 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001270:	4699                	li	a3,6
    80001272:	6605                	lui	a2,0x1
    80001274:	100005b7          	lui	a1,0x10000
    80001278:	10000537          	lui	a0,0x10000
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	f96080e7          	jalr	-106(ra) # 80001212 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001284:	4699                	li	a3,6
    80001286:	6605                	lui	a2,0x1
    80001288:	100015b7          	lui	a1,0x10001
    8000128c:	10001537          	lui	a0,0x10001
    80001290:	00000097          	auipc	ra,0x0
    80001294:	f82080e7          	jalr	-126(ra) # 80001212 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001298:	4699                	li	a3,6
    8000129a:	6641                	lui	a2,0x10
    8000129c:	020005b7          	lui	a1,0x2000
    800012a0:	02000537          	lui	a0,0x2000
    800012a4:	00000097          	auipc	ra,0x0
    800012a8:	f6e080e7          	jalr	-146(ra) # 80001212 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012ac:	4699                	li	a3,6
    800012ae:	00400637          	lui	a2,0x400
    800012b2:	0c0005b7          	lui	a1,0xc000
    800012b6:	0c000537          	lui	a0,0xc000
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f58080e7          	jalr	-168(ra) # 80001212 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012c2:	00007497          	auipc	s1,0x7
    800012c6:	d3e48493          	addi	s1,s1,-706 # 80008000 <etext>
    800012ca:	46a9                	li	a3,10
    800012cc:	80007617          	auipc	a2,0x80007
    800012d0:	d3460613          	addi	a2,a2,-716 # 8000 <_entry-0x7fff8000>
    800012d4:	4585                	li	a1,1
    800012d6:	05fe                	slli	a1,a1,0x1f
    800012d8:	852e                	mv	a0,a1
    800012da:	00000097          	auipc	ra,0x0
    800012de:	f38080e7          	jalr	-200(ra) # 80001212 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012e2:	4699                	li	a3,6
    800012e4:	4645                	li	a2,17
    800012e6:	066e                	slli	a2,a2,0x1b
    800012e8:	8e05                	sub	a2,a2,s1
    800012ea:	85a6                	mv	a1,s1
    800012ec:	8526                	mv	a0,s1
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	f24080e7          	jalr	-220(ra) # 80001212 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012f6:	46a9                	li	a3,10
    800012f8:	6605                	lui	a2,0x1
    800012fa:	00006597          	auipc	a1,0x6
    800012fe:	d0658593          	addi	a1,a1,-762 # 80007000 <_trampoline>
    80001302:	04000537          	lui	a0,0x4000
    80001306:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	f08080e7          	jalr	-248(ra) # 80001212 <kvmmap>
}
    80001312:	60e2                	ld	ra,24(sp)
    80001314:	6442                	ld	s0,16(sp)
    80001316:	64a2                	ld	s1,8(sp)
    80001318:	6105                	addi	sp,sp,32
    8000131a:	8082                	ret

000000008000131c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000131c:	715d                	addi	sp,sp,-80
    8000131e:	e486                	sd	ra,72(sp)
    80001320:	e0a2                	sd	s0,64(sp)
    80001322:	fc26                	sd	s1,56(sp)
    80001324:	f84a                	sd	s2,48(sp)
    80001326:	f44e                	sd	s3,40(sp)
    80001328:	f052                	sd	s4,32(sp)
    8000132a:	ec56                	sd	s5,24(sp)
    8000132c:	e85a                	sd	s6,16(sp)
    8000132e:	e45e                	sd	s7,8(sp)
    80001330:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001332:	03459793          	slli	a5,a1,0x34
    80001336:	e795                	bnez	a5,80001362 <uvmunmap+0x46>
    80001338:	8a2a                	mv	s4,a0
    8000133a:	892e                	mv	s2,a1
    8000133c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133e:	0632                	slli	a2,a2,0xc
    80001340:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001344:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001346:	6b05                	lui	s6,0x1
    80001348:	0735e263          	bltu	a1,s3,800013ac <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000134c:	60a6                	ld	ra,72(sp)
    8000134e:	6406                	ld	s0,64(sp)
    80001350:	74e2                	ld	s1,56(sp)
    80001352:	7942                	ld	s2,48(sp)
    80001354:	79a2                	ld	s3,40(sp)
    80001356:	7a02                	ld	s4,32(sp)
    80001358:	6ae2                	ld	s5,24(sp)
    8000135a:	6b42                	ld	s6,16(sp)
    8000135c:	6ba2                	ld	s7,8(sp)
    8000135e:	6161                	addi	sp,sp,80
    80001360:	8082                	ret
    panic("uvmunmap: not aligned");
    80001362:	00007517          	auipc	a0,0x7
    80001366:	d8e50513          	addi	a0,a0,-626 # 800080f0 <digits+0xb0>
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	1dc080e7          	jalr	476(ra) # 80000546 <panic>
      panic("uvmunmap: walk");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	d9650513          	addi	a0,a0,-618 # 80008108 <digits+0xc8>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1cc080e7          	jalr	460(ra) # 80000546 <panic>
      panic("uvmunmap: not mapped");
    80001382:	00007517          	auipc	a0,0x7
    80001386:	d9650513          	addi	a0,a0,-618 # 80008118 <digits+0xd8>
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	1bc080e7          	jalr	444(ra) # 80000546 <panic>
      panic("uvmunmap: not a leaf");
    80001392:	00007517          	auipc	a0,0x7
    80001396:	d9e50513          	addi	a0,a0,-610 # 80008130 <digits+0xf0>
    8000139a:	fffff097          	auipc	ra,0xfffff
    8000139e:	1ac080e7          	jalr	428(ra) # 80000546 <panic>
    *pte = 0;
    800013a2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013a6:	995a                	add	s2,s2,s6
    800013a8:	fb3972e3          	bgeu	s2,s3,8000134c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ac:	4601                	li	a2,0
    800013ae:	85ca                	mv	a1,s2
    800013b0:	8552                	mv	a0,s4
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	c8c080e7          	jalr	-884(ra) # 8000103e <walk>
    800013ba:	84aa                	mv	s1,a0
    800013bc:	d95d                	beqz	a0,80001372 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013be:	6108                	ld	a0,0(a0)
    800013c0:	00157793          	andi	a5,a0,1
    800013c4:	dfdd                	beqz	a5,80001382 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c6:	3ff57793          	andi	a5,a0,1023
    800013ca:	fd7784e3          	beq	a5,s7,80001392 <uvmunmap+0x76>
    if(do_free){
    800013ce:	fc0a8ae3          	beqz	s5,800013a2 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800013d2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013d4:	0532                	slli	a0,a0,0xc
    800013d6:	fffff097          	auipc	ra,0xfffff
    800013da:	63c080e7          	jalr	1596(ra) # 80000a12 <kfree>
    800013de:	b7d1                	j	800013a2 <uvmunmap+0x86>

00000000800013e0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013e0:	1101                	addi	sp,sp,-32
    800013e2:	ec06                	sd	ra,24(sp)
    800013e4:	e822                	sd	s0,16(sp)
    800013e6:	e426                	sd	s1,8(sp)
    800013e8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	726080e7          	jalr	1830(ra) # 80000b10 <kalloc>
    800013f2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013f4:	c519                	beqz	a0,80001402 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	95c080e7          	jalr	-1700(ra) # 80000d56 <memset>
  return pagetable;
}
    80001402:	8526                	mv	a0,s1
    80001404:	60e2                	ld	ra,24(sp)
    80001406:	6442                	ld	s0,16(sp)
    80001408:	64a2                	ld	s1,8(sp)
    8000140a:	6105                	addi	sp,sp,32
    8000140c:	8082                	ret

000000008000140e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000140e:	7179                	addi	sp,sp,-48
    80001410:	f406                	sd	ra,40(sp)
    80001412:	f022                	sd	s0,32(sp)
    80001414:	ec26                	sd	s1,24(sp)
    80001416:	e84a                	sd	s2,16(sp)
    80001418:	e44e                	sd	s3,8(sp)
    8000141a:	e052                	sd	s4,0(sp)
    8000141c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000141e:	6785                	lui	a5,0x1
    80001420:	04f67863          	bgeu	a2,a5,80001470 <uvminit+0x62>
    80001424:	8a2a                	mv	s4,a0
    80001426:	89ae                	mv	s3,a1
    80001428:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	6e6080e7          	jalr	1766(ra) # 80000b10 <kalloc>
    80001432:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001434:	6605                	lui	a2,0x1
    80001436:	4581                	li	a1,0
    80001438:	00000097          	auipc	ra,0x0
    8000143c:	91e080e7          	jalr	-1762(ra) # 80000d56 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001440:	4779                	li	a4,30
    80001442:	86ca                	mv	a3,s2
    80001444:	6605                	lui	a2,0x1
    80001446:	4581                	li	a1,0
    80001448:	8552                	mv	a0,s4
    8000144a:	00000097          	auipc	ra,0x0
    8000144e:	d3a080e7          	jalr	-710(ra) # 80001184 <mappages>
  memmove(mem, src, sz);
    80001452:	8626                	mv	a2,s1
    80001454:	85ce                	mv	a1,s3
    80001456:	854a                	mv	a0,s2
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	95a080e7          	jalr	-1702(ra) # 80000db2 <memmove>
}
    80001460:	70a2                	ld	ra,40(sp)
    80001462:	7402                	ld	s0,32(sp)
    80001464:	64e2                	ld	s1,24(sp)
    80001466:	6942                	ld	s2,16(sp)
    80001468:	69a2                	ld	s3,8(sp)
    8000146a:	6a02                	ld	s4,0(sp)
    8000146c:	6145                	addi	sp,sp,48
    8000146e:	8082                	ret
    panic("inituvm: more than a page");
    80001470:	00007517          	auipc	a0,0x7
    80001474:	cd850513          	addi	a0,a0,-808 # 80008148 <digits+0x108>
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	0ce080e7          	jalr	206(ra) # 80000546 <panic>

0000000080001480 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001480:	1101                	addi	sp,sp,-32
    80001482:	ec06                	sd	ra,24(sp)
    80001484:	e822                	sd	s0,16(sp)
    80001486:	e426                	sd	s1,8(sp)
    80001488:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000148a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000148c:	00b67d63          	bgeu	a2,a1,800014a6 <uvmdealloc+0x26>
    80001490:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001492:	6785                	lui	a5,0x1
    80001494:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001496:	00f60733          	add	a4,a2,a5
    8000149a:	76fd                	lui	a3,0xfffff
    8000149c:	8f75                	and	a4,a4,a3
    8000149e:	97ae                	add	a5,a5,a1
    800014a0:	8ff5                	and	a5,a5,a3
    800014a2:	00f76863          	bltu	a4,a5,800014b2 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014a6:	8526                	mv	a0,s1
    800014a8:	60e2                	ld	ra,24(sp)
    800014aa:	6442                	ld	s0,16(sp)
    800014ac:	64a2                	ld	s1,8(sp)
    800014ae:	6105                	addi	sp,sp,32
    800014b0:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014b2:	8f99                	sub	a5,a5,a4
    800014b4:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014b6:	4685                	li	a3,1
    800014b8:	0007861b          	sext.w	a2,a5
    800014bc:	85ba                	mv	a1,a4
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	e5e080e7          	jalr	-418(ra) # 8000131c <uvmunmap>
    800014c6:	b7c5                	j	800014a6 <uvmdealloc+0x26>

00000000800014c8 <uvmalloc>:
  if(newsz < oldsz)
    800014c8:	0ab66163          	bltu	a2,a1,8000156a <uvmalloc+0xa2>
{
    800014cc:	7139                	addi	sp,sp,-64
    800014ce:	fc06                	sd	ra,56(sp)
    800014d0:	f822                	sd	s0,48(sp)
    800014d2:	f426                	sd	s1,40(sp)
    800014d4:	f04a                	sd	s2,32(sp)
    800014d6:	ec4e                	sd	s3,24(sp)
    800014d8:	e852                	sd	s4,16(sp)
    800014da:	e456                	sd	s5,8(sp)
    800014dc:	0080                	addi	s0,sp,64
    800014de:	8aaa                	mv	s5,a0
    800014e0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014e2:	6785                	lui	a5,0x1
    800014e4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014e6:	95be                	add	a1,a1,a5
    800014e8:	77fd                	lui	a5,0xfffff
    800014ea:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ee:	08c9f063          	bgeu	s3,a2,8000156e <uvmalloc+0xa6>
    800014f2:	894e                	mv	s2,s3
    mem = kalloc();
    800014f4:	fffff097          	auipc	ra,0xfffff
    800014f8:	61c080e7          	jalr	1564(ra) # 80000b10 <kalloc>
    800014fc:	84aa                	mv	s1,a0
    if(mem == 0){
    800014fe:	c51d                	beqz	a0,8000152c <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001500:	6605                	lui	a2,0x1
    80001502:	4581                	li	a1,0
    80001504:	00000097          	auipc	ra,0x0
    80001508:	852080e7          	jalr	-1966(ra) # 80000d56 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000150c:	4779                	li	a4,30
    8000150e:	86a6                	mv	a3,s1
    80001510:	6605                	lui	a2,0x1
    80001512:	85ca                	mv	a1,s2
    80001514:	8556                	mv	a0,s5
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	c6e080e7          	jalr	-914(ra) # 80001184 <mappages>
    8000151e:	e905                	bnez	a0,8000154e <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001520:	6785                	lui	a5,0x1
    80001522:	993e                	add	s2,s2,a5
    80001524:	fd4968e3          	bltu	s2,s4,800014f4 <uvmalloc+0x2c>
  return newsz;
    80001528:	8552                	mv	a0,s4
    8000152a:	a809                	j	8000153c <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000152c:	864e                	mv	a2,s3
    8000152e:	85ca                	mv	a1,s2
    80001530:	8556                	mv	a0,s5
    80001532:	00000097          	auipc	ra,0x0
    80001536:	f4e080e7          	jalr	-178(ra) # 80001480 <uvmdealloc>
      return 0;
    8000153a:	4501                	li	a0,0
}
    8000153c:	70e2                	ld	ra,56(sp)
    8000153e:	7442                	ld	s0,48(sp)
    80001540:	74a2                	ld	s1,40(sp)
    80001542:	7902                	ld	s2,32(sp)
    80001544:	69e2                	ld	s3,24(sp)
    80001546:	6a42                	ld	s4,16(sp)
    80001548:	6aa2                	ld	s5,8(sp)
    8000154a:	6121                	addi	sp,sp,64
    8000154c:	8082                	ret
      kfree(mem);
    8000154e:	8526                	mv	a0,s1
    80001550:	fffff097          	auipc	ra,0xfffff
    80001554:	4c2080e7          	jalr	1218(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001558:	864e                	mv	a2,s3
    8000155a:	85ca                	mv	a1,s2
    8000155c:	8556                	mv	a0,s5
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	f22080e7          	jalr	-222(ra) # 80001480 <uvmdealloc>
      return 0;
    80001566:	4501                	li	a0,0
    80001568:	bfd1                	j	8000153c <uvmalloc+0x74>
    return oldsz;
    8000156a:	852e                	mv	a0,a1
}
    8000156c:	8082                	ret
  return newsz;
    8000156e:	8532                	mv	a0,a2
    80001570:	b7f1                	j	8000153c <uvmalloc+0x74>

0000000080001572 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001572:	7179                	addi	sp,sp,-48
    80001574:	f406                	sd	ra,40(sp)
    80001576:	f022                	sd	s0,32(sp)
    80001578:	ec26                	sd	s1,24(sp)
    8000157a:	e84a                	sd	s2,16(sp)
    8000157c:	e44e                	sd	s3,8(sp)
    8000157e:	e052                	sd	s4,0(sp)
    80001580:	1800                	addi	s0,sp,48
    80001582:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001584:	84aa                	mv	s1,a0
    80001586:	6905                	lui	s2,0x1
    80001588:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000158a:	4985                	li	s3,1
    8000158c:	a829                	j	800015a6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000158e:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001590:	00c79513          	slli	a0,a5,0xc
    80001594:	00000097          	auipc	ra,0x0
    80001598:	fde080e7          	jalr	-34(ra) # 80001572 <freewalk>
      pagetable[i] = 0;
    8000159c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a0:	04a1                	addi	s1,s1,8
    800015a2:	03248163          	beq	s1,s2,800015c4 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800015a6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a8:	00f7f713          	andi	a4,a5,15
    800015ac:	ff3701e3          	beq	a4,s3,8000158e <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b0:	8b85                	andi	a5,a5,1
    800015b2:	d7fd                	beqz	a5,800015a0 <freewalk+0x2e>
      panic("freewalk: leaf");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bb450513          	addi	a0,a0,-1100 # 80008168 <digits+0x128>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f8a080e7          	jalr	-118(ra) # 80000546 <panic>
    }
  }
  kfree((void*)pagetable);
    800015c4:	8552                	mv	a0,s4
    800015c6:	fffff097          	auipc	ra,0xfffff
    800015ca:	44c080e7          	jalr	1100(ra) # 80000a12 <kfree>
}
    800015ce:	70a2                	ld	ra,40(sp)
    800015d0:	7402                	ld	s0,32(sp)
    800015d2:	64e2                	ld	s1,24(sp)
    800015d4:	6942                	ld	s2,16(sp)
    800015d6:	69a2                	ld	s3,8(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	6145                	addi	sp,sp,48
    800015dc:	8082                	ret

00000000800015de <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015de:	1101                	addi	sp,sp,-32
    800015e0:	ec06                	sd	ra,24(sp)
    800015e2:	e822                	sd	s0,16(sp)
    800015e4:	e426                	sd	s1,8(sp)
    800015e6:	1000                	addi	s0,sp,32
    800015e8:	84aa                	mv	s1,a0
  if(sz > 0)
    800015ea:	e999                	bnez	a1,80001600 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015ec:	8526                	mv	a0,s1
    800015ee:	00000097          	auipc	ra,0x0
    800015f2:	f84080e7          	jalr	-124(ra) # 80001572 <freewalk>
}
    800015f6:	60e2                	ld	ra,24(sp)
    800015f8:	6442                	ld	s0,16(sp)
    800015fa:	64a2                	ld	s1,8(sp)
    800015fc:	6105                	addi	sp,sp,32
    800015fe:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001600:	6785                	lui	a5,0x1
    80001602:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001604:	95be                	add	a1,a1,a5
    80001606:	4685                	li	a3,1
    80001608:	00c5d613          	srli	a2,a1,0xc
    8000160c:	4581                	li	a1,0
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d0e080e7          	jalr	-754(ra) # 8000131c <uvmunmap>
    80001616:	bfd9                	j	800015ec <uvmfree+0xe>

0000000080001618 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001618:	c679                	beqz	a2,800016e6 <uvmcopy+0xce>
{
    8000161a:	715d                	addi	sp,sp,-80
    8000161c:	e486                	sd	ra,72(sp)
    8000161e:	e0a2                	sd	s0,64(sp)
    80001620:	fc26                	sd	s1,56(sp)
    80001622:	f84a                	sd	s2,48(sp)
    80001624:	f44e                	sd	s3,40(sp)
    80001626:	f052                	sd	s4,32(sp)
    80001628:	ec56                	sd	s5,24(sp)
    8000162a:	e85a                	sd	s6,16(sp)
    8000162c:	e45e                	sd	s7,8(sp)
    8000162e:	0880                	addi	s0,sp,80
    80001630:	8b2a                	mv	s6,a0
    80001632:	8aae                	mv	s5,a1
    80001634:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001636:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001638:	4601                	li	a2,0
    8000163a:	85ce                	mv	a1,s3
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	a00080e7          	jalr	-1536(ra) # 8000103e <walk>
    80001646:	c531                	beqz	a0,80001692 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001648:	6118                	ld	a4,0(a0)
    8000164a:	00177793          	andi	a5,a4,1
    8000164e:	cbb1                	beqz	a5,800016a2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001650:	00a75593          	srli	a1,a4,0xa
    80001654:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001658:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000165c:	fffff097          	auipc	ra,0xfffff
    80001660:	4b4080e7          	jalr	1204(ra) # 80000b10 <kalloc>
    80001664:	892a                	mv	s2,a0
    80001666:	c939                	beqz	a0,800016bc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001668:	6605                	lui	a2,0x1
    8000166a:	85de                	mv	a1,s7
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	746080e7          	jalr	1862(ra) # 80000db2 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001674:	8726                	mv	a4,s1
    80001676:	86ca                	mv	a3,s2
    80001678:	6605                	lui	a2,0x1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	8556                	mv	a0,s5
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	b06080e7          	jalr	-1274(ra) # 80001184 <mappages>
    80001686:	e515                	bnez	a0,800016b2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001688:	6785                	lui	a5,0x1
    8000168a:	99be                	add	s3,s3,a5
    8000168c:	fb49e6e3          	bltu	s3,s4,80001638 <uvmcopy+0x20>
    80001690:	a081                	j	800016d0 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001692:	00007517          	auipc	a0,0x7
    80001696:	ae650513          	addi	a0,a0,-1306 # 80008178 <digits+0x138>
    8000169a:	fffff097          	auipc	ra,0xfffff
    8000169e:	eac080e7          	jalr	-340(ra) # 80000546 <panic>
      panic("uvmcopy: page not present");
    800016a2:	00007517          	auipc	a0,0x7
    800016a6:	af650513          	addi	a0,a0,-1290 # 80008198 <digits+0x158>
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	e9c080e7          	jalr	-356(ra) # 80000546 <panic>
      kfree(mem);
    800016b2:	854a                	mv	a0,s2
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	35e080e7          	jalr	862(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016bc:	4685                	li	a3,1
    800016be:	00c9d613          	srli	a2,s3,0xc
    800016c2:	4581                	li	a1,0
    800016c4:	8556                	mv	a0,s5
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	c56080e7          	jalr	-938(ra) # 8000131c <uvmunmap>
  return -1;
    800016ce:	557d                	li	a0,-1
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
  return 0;
    800016e6:	4501                	li	a0,0
}
    800016e8:	8082                	ret

00000000800016ea <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016ea:	1141                	addi	sp,sp,-16
    800016ec:	e406                	sd	ra,8(sp)
    800016ee:	e022                	sd	s0,0(sp)
    800016f0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f2:	4601                	li	a2,0
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	94a080e7          	jalr	-1718(ra) # 8000103e <walk>
  if(pte == 0)
    800016fc:	c901                	beqz	a0,8000170c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016fe:	611c                	ld	a5,0(a0)
    80001700:	9bbd                	andi	a5,a5,-17
    80001702:	e11c                	sd	a5,0(a0)
}
    80001704:	60a2                	ld	ra,8(sp)
    80001706:	6402                	ld	s0,0(sp)
    80001708:	0141                	addi	sp,sp,16
    8000170a:	8082                	ret
    panic("uvmclear");
    8000170c:	00007517          	auipc	a0,0x7
    80001710:	aac50513          	addi	a0,a0,-1364 # 800081b8 <digits+0x178>
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	e32080e7          	jalr	-462(ra) # 80000546 <panic>

000000008000171c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000171c:	c6bd                	beqz	a3,8000178a <copyout+0x6e>
{
    8000171e:	715d                	addi	sp,sp,-80
    80001720:	e486                	sd	ra,72(sp)
    80001722:	e0a2                	sd	s0,64(sp)
    80001724:	fc26                	sd	s1,56(sp)
    80001726:	f84a                	sd	s2,48(sp)
    80001728:	f44e                	sd	s3,40(sp)
    8000172a:	f052                	sd	s4,32(sp)
    8000172c:	ec56                	sd	s5,24(sp)
    8000172e:	e85a                	sd	s6,16(sp)
    80001730:	e45e                	sd	s7,8(sp)
    80001732:	e062                	sd	s8,0(sp)
    80001734:	0880                	addi	s0,sp,80
    80001736:	8b2a                	mv	s6,a0
    80001738:	8c2e                	mv	s8,a1
    8000173a:	8a32                	mv	s4,a2
    8000173c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000173e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001740:	6a85                	lui	s5,0x1
    80001742:	a015                	j	80001766 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001744:	9562                	add	a0,a0,s8
    80001746:	0004861b          	sext.w	a2,s1
    8000174a:	85d2                	mv	a1,s4
    8000174c:	41250533          	sub	a0,a0,s2
    80001750:	fffff097          	auipc	ra,0xfffff
    80001754:	662080e7          	jalr	1634(ra) # 80000db2 <memmove>

    len -= n;
    80001758:	409989b3          	sub	s3,s3,s1
    src += n;
    8000175c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000175e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001762:	02098263          	beqz	s3,80001786 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001766:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000176a:	85ca                	mv	a1,s2
    8000176c:	855a                	mv	a0,s6
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	976080e7          	jalr	-1674(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001776:	cd01                	beqz	a0,8000178e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001778:	418904b3          	sub	s1,s2,s8
    8000177c:	94d6                	add	s1,s1,s5
    8000177e:	fc99f3e3          	bgeu	s3,s1,80001744 <copyout+0x28>
    80001782:	84ce                	mv	s1,s3
    80001784:	b7c1                	j	80001744 <copyout+0x28>
  }
  return 0;
    80001786:	4501                	li	a0,0
    80001788:	a021                	j	80001790 <copyout+0x74>
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
      return -1;
    8000178e:	557d                	li	a0,-1
}
    80001790:	60a6                	ld	ra,72(sp)
    80001792:	6406                	ld	s0,64(sp)
    80001794:	74e2                	ld	s1,56(sp)
    80001796:	7942                	ld	s2,48(sp)
    80001798:	79a2                	ld	s3,40(sp)
    8000179a:	7a02                	ld	s4,32(sp)
    8000179c:	6ae2                	ld	s5,24(sp)
    8000179e:	6b42                	ld	s6,16(sp)
    800017a0:	6ba2                	ld	s7,8(sp)
    800017a2:	6c02                	ld	s8,0(sp)
    800017a4:	6161                	addi	sp,sp,80
    800017a6:	8082                	ret

00000000800017a8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a8:	caa5                	beqz	a3,80001818 <copyin+0x70>
{
    800017aa:	715d                	addi	sp,sp,-80
    800017ac:	e486                	sd	ra,72(sp)
    800017ae:	e0a2                	sd	s0,64(sp)
    800017b0:	fc26                	sd	s1,56(sp)
    800017b2:	f84a                	sd	s2,48(sp)
    800017b4:	f44e                	sd	s3,40(sp)
    800017b6:	f052                	sd	s4,32(sp)
    800017b8:	ec56                	sd	s5,24(sp)
    800017ba:	e85a                	sd	s6,16(sp)
    800017bc:	e45e                	sd	s7,8(sp)
    800017be:	e062                	sd	s8,0(sp)
    800017c0:	0880                	addi	s0,sp,80
    800017c2:	8b2a                	mv	s6,a0
    800017c4:	8a2e                	mv	s4,a1
    800017c6:	8c32                	mv	s8,a2
    800017c8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017ca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017cc:	6a85                	lui	s5,0x1
    800017ce:	a01d                	j	800017f4 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d0:	018505b3          	add	a1,a0,s8
    800017d4:	0004861b          	sext.w	a2,s1
    800017d8:	412585b3          	sub	a1,a1,s2
    800017dc:	8552                	mv	a0,s4
    800017de:	fffff097          	auipc	ra,0xfffff
    800017e2:	5d4080e7          	jalr	1492(ra) # 80000db2 <memmove>

    len -= n;
    800017e6:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017ea:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f0:	02098263          	beqz	s3,80001814 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017f8:	85ca                	mv	a1,s2
    800017fa:	855a                	mv	a0,s6
    800017fc:	00000097          	auipc	ra,0x0
    80001800:	8e8080e7          	jalr	-1816(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001804:	cd01                	beqz	a0,8000181c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001806:	418904b3          	sub	s1,s2,s8
    8000180a:	94d6                	add	s1,s1,s5
    8000180c:	fc99f2e3          	bgeu	s3,s1,800017d0 <copyin+0x28>
    80001810:	84ce                	mv	s1,s3
    80001812:	bf7d                	j	800017d0 <copyin+0x28>
  }
  return 0;
    80001814:	4501                	li	a0,0
    80001816:	a021                	j	8000181e <copyin+0x76>
    80001818:	4501                	li	a0,0
}
    8000181a:	8082                	ret
      return -1;
    8000181c:	557d                	li	a0,-1
}
    8000181e:	60a6                	ld	ra,72(sp)
    80001820:	6406                	ld	s0,64(sp)
    80001822:	74e2                	ld	s1,56(sp)
    80001824:	7942                	ld	s2,48(sp)
    80001826:	79a2                	ld	s3,40(sp)
    80001828:	7a02                	ld	s4,32(sp)
    8000182a:	6ae2                	ld	s5,24(sp)
    8000182c:	6b42                	ld	s6,16(sp)
    8000182e:	6ba2                	ld	s7,8(sp)
    80001830:	6c02                	ld	s8,0(sp)
    80001832:	6161                	addi	sp,sp,80
    80001834:	8082                	ret

0000000080001836 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001836:	c2dd                	beqz	a3,800018dc <copyinstr+0xa6>
{
    80001838:	715d                	addi	sp,sp,-80
    8000183a:	e486                	sd	ra,72(sp)
    8000183c:	e0a2                	sd	s0,64(sp)
    8000183e:	fc26                	sd	s1,56(sp)
    80001840:	f84a                	sd	s2,48(sp)
    80001842:	f44e                	sd	s3,40(sp)
    80001844:	f052                	sd	s4,32(sp)
    80001846:	ec56                	sd	s5,24(sp)
    80001848:	e85a                	sd	s6,16(sp)
    8000184a:	e45e                	sd	s7,8(sp)
    8000184c:	0880                	addi	s0,sp,80
    8000184e:	8a2a                	mv	s4,a0
    80001850:	8b2e                	mv	s6,a1
    80001852:	8bb2                	mv	s7,a2
    80001854:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001856:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001858:	6985                	lui	s3,0x1
    8000185a:	a02d                	j	80001884 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000185c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001860:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001862:	37fd                	addiw	a5,a5,-1
    80001864:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001868:	60a6                	ld	ra,72(sp)
    8000186a:	6406                	ld	s0,64(sp)
    8000186c:	74e2                	ld	s1,56(sp)
    8000186e:	7942                	ld	s2,48(sp)
    80001870:	79a2                	ld	s3,40(sp)
    80001872:	7a02                	ld	s4,32(sp)
    80001874:	6ae2                	ld	s5,24(sp)
    80001876:	6b42                	ld	s6,16(sp)
    80001878:	6ba2                	ld	s7,8(sp)
    8000187a:	6161                	addi	sp,sp,80
    8000187c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000187e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001882:	c8a9                	beqz	s1,800018d4 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001884:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001888:	85ca                	mv	a1,s2
    8000188a:	8552                	mv	a0,s4
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	858080e7          	jalr	-1960(ra) # 800010e4 <walkaddr>
    if(pa0 == 0)
    80001894:	c131                	beqz	a0,800018d8 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001896:	417906b3          	sub	a3,s2,s7
    8000189a:	96ce                	add	a3,a3,s3
    8000189c:	00d4f363          	bgeu	s1,a3,800018a2 <copyinstr+0x6c>
    800018a0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a2:	955e                	add	a0,a0,s7
    800018a4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018a8:	daf9                	beqz	a3,8000187e <copyinstr+0x48>
    800018aa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018ac:	41650633          	sub	a2,a0,s6
    800018b0:	fff48593          	addi	a1,s1,-1
    800018b4:	95da                	add	a1,a1,s6
    while(n > 0){
    800018b6:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800018b8:	00f60733          	add	a4,a2,a5
    800018bc:	00074703          	lbu	a4,0(a4)
    800018c0:	df51                	beqz	a4,8000185c <copyinstr+0x26>
        *dst = *p;
    800018c2:	00e78023          	sb	a4,0(a5)
      --max;
    800018c6:	40f584b3          	sub	s1,a1,a5
      dst++;
    800018ca:	0785                	addi	a5,a5,1
    while(n > 0){
    800018cc:	fed796e3          	bne	a5,a3,800018b8 <copyinstr+0x82>
      dst++;
    800018d0:	8b3e                	mv	s6,a5
    800018d2:	b775                	j	8000187e <copyinstr+0x48>
    800018d4:	4781                	li	a5,0
    800018d6:	b771                	j	80001862 <copyinstr+0x2c>
      return -1;
    800018d8:	557d                	li	a0,-1
    800018da:	b779                	j	80001868 <copyinstr+0x32>
  int got_null = 0;
    800018dc:	4781                	li	a5,0
  if(got_null){
    800018de:	37fd                	addiw	a5,a5,-1
    800018e0:	0007851b          	sext.w	a0,a5
}
    800018e4:	8082                	ret

00000000800018e6 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018e6:	1101                	addi	sp,sp,-32
    800018e8:	ec06                	sd	ra,24(sp)
    800018ea:	e822                	sd	s0,16(sp)
    800018ec:	e426                	sd	s1,8(sp)
    800018ee:	1000                	addi	s0,sp,32
    800018f0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018f2:	fffff097          	auipc	ra,0xfffff
    800018f6:	2ee080e7          	jalr	750(ra) # 80000be0 <holding>
    800018fa:	c909                	beqz	a0,8000190c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018fc:	749c                	ld	a5,40(s1)
    800018fe:	00978f63          	beq	a5,s1,8000191c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001902:	60e2                	ld	ra,24(sp)
    80001904:	6442                	ld	s0,16(sp)
    80001906:	64a2                	ld	s1,8(sp)
    80001908:	6105                	addi	sp,sp,32
    8000190a:	8082                	ret
    panic("wakeup1");
    8000190c:	00007517          	auipc	a0,0x7
    80001910:	8bc50513          	addi	a0,a0,-1860 # 800081c8 <digits+0x188>
    80001914:	fffff097          	auipc	ra,0xfffff
    80001918:	c32080e7          	jalr	-974(ra) # 80000546 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000191c:	4c98                	lw	a4,24(s1)
    8000191e:	4785                	li	a5,1
    80001920:	fef711e3          	bne	a4,a5,80001902 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001924:	4789                	li	a5,2
    80001926:	cc9c                	sw	a5,24(s1)
}
    80001928:	bfe9                	j	80001902 <wakeup1+0x1c>

000000008000192a <procinit>:
{
    8000192a:	715d                	addi	sp,sp,-80
    8000192c:	e486                	sd	ra,72(sp)
    8000192e:	e0a2                	sd	s0,64(sp)
    80001930:	fc26                	sd	s1,56(sp)
    80001932:	f84a                	sd	s2,48(sp)
    80001934:	f44e                	sd	s3,40(sp)
    80001936:	f052                	sd	s4,32(sp)
    80001938:	ec56                	sd	s5,24(sp)
    8000193a:	e85a                	sd	s6,16(sp)
    8000193c:	e45e                	sd	s7,8(sp)
    8000193e:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001940:	00007597          	auipc	a1,0x7
    80001944:	89058593          	addi	a1,a1,-1904 # 800081d0 <digits+0x190>
    80001948:	00010517          	auipc	a0,0x10
    8000194c:	00850513          	addi	a0,a0,8 # 80011950 <pid_lock>
    80001950:	fffff097          	auipc	ra,0xfffff
    80001954:	27a080e7          	jalr	634(ra) # 80000bca <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	00010917          	auipc	s2,0x10
    8000195c:	41090913          	addi	s2,s2,1040 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001960:	00007b97          	auipc	s7,0x7
    80001964:	878b8b93          	addi	s7,s7,-1928 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001968:	8b4a                	mv	s6,s2
    8000196a:	00006a97          	auipc	s5,0x6
    8000196e:	696a8a93          	addi	s5,s5,1686 # 80008000 <etext>
    80001972:	040009b7          	lui	s3,0x4000
    80001976:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001978:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197a:	00016a17          	auipc	s4,0x16
    8000197e:	feea0a13          	addi	s4,s4,-18 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001982:	85de                	mv	a1,s7
    80001984:	854a                	mv	a0,s2
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	244080e7          	jalr	580(ra) # 80000bca <initlock>
      char *pa = kalloc();
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	182080e7          	jalr	386(ra) # 80000b10 <kalloc>
    80001996:	85aa                	mv	a1,a0
      if(pa == 0)
    80001998:	c929                	beqz	a0,800019ea <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000199a:	416904b3          	sub	s1,s2,s6
    8000199e:	8491                	srai	s1,s1,0x4
    800019a0:	000ab783          	ld	a5,0(s5)
    800019a4:	02f484b3          	mul	s1,s1,a5
    800019a8:	2485                	addiw	s1,s1,1
    800019aa:	00d4949b          	slliw	s1,s1,0xd
    800019ae:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019b2:	4699                	li	a3,6
    800019b4:	6605                	lui	a2,0x1
    800019b6:	8526                	mv	a0,s1
    800019b8:	00000097          	auipc	ra,0x0
    800019bc:	85a080e7          	jalr	-1958(ra) # 80001212 <kvmmap>
      p->kstack = va;
    800019c0:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	17090913          	addi	s2,s2,368
    800019c8:	fb491de3          	bne	s2,s4,80001982 <procinit+0x58>
  kvminithart();
    800019cc:	fffff097          	auipc	ra,0xfffff
    800019d0:	64e080e7          	jalr	1614(ra) # 8000101a <kvminithart>
}
    800019d4:	60a6                	ld	ra,72(sp)
    800019d6:	6406                	ld	s0,64(sp)
    800019d8:	74e2                	ld	s1,56(sp)
    800019da:	7942                	ld	s2,48(sp)
    800019dc:	79a2                	ld	s3,40(sp)
    800019de:	7a02                	ld	s4,32(sp)
    800019e0:	6ae2                	ld	s5,24(sp)
    800019e2:	6b42                	ld	s6,16(sp)
    800019e4:	6ba2                	ld	s7,8(sp)
    800019e6:	6161                	addi	sp,sp,80
    800019e8:	8082                	ret
        panic("kalloc");
    800019ea:	00006517          	auipc	a0,0x6
    800019ee:	7f650513          	addi	a0,a0,2038 # 800081e0 <digits+0x1a0>
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	b54080e7          	jalr	-1196(ra) # 80000546 <panic>

00000000800019fa <cpuid>:
{
    800019fa:	1141                	addi	sp,sp,-16
    800019fc:	e422                	sd	s0,8(sp)
    800019fe:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a00:	8512                	mv	a0,tp
}
    80001a02:	2501                	sext.w	a0,a0
    80001a04:	6422                	ld	s0,8(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret

0000000080001a0a <mycpu>:
mycpu(void) {
    80001a0a:	1141                	addi	sp,sp,-16
    80001a0c:	e422                	sd	s0,8(sp)
    80001a0e:	0800                	addi	s0,sp,16
    80001a10:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a12:	2781                	sext.w	a5,a5
    80001a14:	079e                	slli	a5,a5,0x7
}
    80001a16:	00010517          	auipc	a0,0x10
    80001a1a:	f5250513          	addi	a0,a0,-174 # 80011968 <cpus>
    80001a1e:	953e                	add	a0,a0,a5
    80001a20:	6422                	ld	s0,8(sp)
    80001a22:	0141                	addi	sp,sp,16
    80001a24:	8082                	ret

0000000080001a26 <myproc>:
myproc(void) {
    80001a26:	1101                	addi	sp,sp,-32
    80001a28:	ec06                	sd	ra,24(sp)
    80001a2a:	e822                	sd	s0,16(sp)
    80001a2c:	e426                	sd	s1,8(sp)
    80001a2e:	1000                	addi	s0,sp,32
  push_off();
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	1de080e7          	jalr	478(ra) # 80000c0e <push_off>
    80001a38:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a3a:	2781                	sext.w	a5,a5
    80001a3c:	079e                	slli	a5,a5,0x7
    80001a3e:	00010717          	auipc	a4,0x10
    80001a42:	f1270713          	addi	a4,a4,-238 # 80011950 <pid_lock>
    80001a46:	97ba                	add	a5,a5,a4
    80001a48:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	264080e7          	jalr	612(ra) # 80000cae <pop_off>
}
    80001a52:	8526                	mv	a0,s1
    80001a54:	60e2                	ld	ra,24(sp)
    80001a56:	6442                	ld	s0,16(sp)
    80001a58:	64a2                	ld	s1,8(sp)
    80001a5a:	6105                	addi	sp,sp,32
    80001a5c:	8082                	ret

0000000080001a5e <forkret>:
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e406                	sd	ra,8(sp)
    80001a62:	e022                	sd	s0,0(sp)
    80001a64:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a66:	00000097          	auipc	ra,0x0
    80001a6a:	fc0080e7          	jalr	-64(ra) # 80001a26 <myproc>
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	2a0080e7          	jalr	672(ra) # 80000d0e <release>
  if (first) {
    80001a76:	00007797          	auipc	a5,0x7
    80001a7a:	e6a7a783          	lw	a5,-406(a5) # 800088e0 <first.1>
    80001a7e:	eb89                	bnez	a5,80001a90 <forkret+0x32>
  usertrapret();
    80001a80:	00001097          	auipc	ra,0x1
    80001a84:	d44080e7          	jalr	-700(ra) # 800027c4 <usertrapret>
}
    80001a88:	60a2                	ld	ra,8(sp)
    80001a8a:	6402                	ld	s0,0(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret
    first = 0;
    80001a90:	00007797          	auipc	a5,0x7
    80001a94:	e407a823          	sw	zero,-432(a5) # 800088e0 <first.1>
    fsinit(ROOTDEV);
    80001a98:	4505                	li	a0,1
    80001a9a:	00002097          	auipc	ra,0x2
    80001a9e:	b06080e7          	jalr	-1274(ra) # 800035a0 <fsinit>
    80001aa2:	bff9                	j	80001a80 <forkret+0x22>

0000000080001aa4 <allocpid>:
allocpid() {
    80001aa4:	1101                	addi	sp,sp,-32
    80001aa6:	ec06                	sd	ra,24(sp)
    80001aa8:	e822                	sd	s0,16(sp)
    80001aaa:	e426                	sd	s1,8(sp)
    80001aac:	e04a                	sd	s2,0(sp)
    80001aae:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab0:	00010917          	auipc	s2,0x10
    80001ab4:	ea090913          	addi	s2,s2,-352 # 80011950 <pid_lock>
    80001ab8:	854a                	mv	a0,s2
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	1a0080e7          	jalr	416(ra) # 80000c5a <acquire>
  pid = nextpid;
    80001ac2:	00007797          	auipc	a5,0x7
    80001ac6:	e2278793          	addi	a5,a5,-478 # 800088e4 <nextpid>
    80001aca:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001acc:	0014871b          	addiw	a4,s1,1
    80001ad0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad2:	854a                	mv	a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	23a080e7          	jalr	570(ra) # 80000d0e <release>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret

0000000080001aea <proc_pagetable>:
{
    80001aea:	1101                	addi	sp,sp,-32
    80001aec:	ec06                	sd	ra,24(sp)
    80001aee:	e822                	sd	s0,16(sp)
    80001af0:	e426                	sd	s1,8(sp)
    80001af2:	e04a                	sd	s2,0(sp)
    80001af4:	1000                	addi	s0,sp,32
    80001af6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af8:	00000097          	auipc	ra,0x0
    80001afc:	8e8080e7          	jalr	-1816(ra) # 800013e0 <uvmcreate>
    80001b00:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b02:	c121                	beqz	a0,80001b42 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b04:	4729                	li	a4,10
    80001b06:	00005697          	auipc	a3,0x5
    80001b0a:	4fa68693          	addi	a3,a3,1274 # 80007000 <_trampoline>
    80001b0e:	6605                	lui	a2,0x1
    80001b10:	040005b7          	lui	a1,0x4000
    80001b14:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b16:	05b2                	slli	a1,a1,0xc
    80001b18:	fffff097          	auipc	ra,0xfffff
    80001b1c:	66c080e7          	jalr	1644(ra) # 80001184 <mappages>
    80001b20:	02054863          	bltz	a0,80001b50 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b24:	4719                	li	a4,6
    80001b26:	05893683          	ld	a3,88(s2)
    80001b2a:	6605                	lui	a2,0x1
    80001b2c:	020005b7          	lui	a1,0x2000
    80001b30:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b32:	05b6                	slli	a1,a1,0xd
    80001b34:	8526                	mv	a0,s1
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	64e080e7          	jalr	1614(ra) # 80001184 <mappages>
    80001b3e:	02054163          	bltz	a0,80001b60 <proc_pagetable+0x76>
}
    80001b42:	8526                	mv	a0,s1
    80001b44:	60e2                	ld	ra,24(sp)
    80001b46:	6442                	ld	s0,16(sp)
    80001b48:	64a2                	ld	s1,8(sp)
    80001b4a:	6902                	ld	s2,0(sp)
    80001b4c:	6105                	addi	sp,sp,32
    80001b4e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b50:	4581                	li	a1,0
    80001b52:	8526                	mv	a0,s1
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	a8a080e7          	jalr	-1398(ra) # 800015de <uvmfree>
    return 0;
    80001b5c:	4481                	li	s1,0
    80001b5e:	b7d5                	j	80001b42 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b60:	4681                	li	a3,0
    80001b62:	4605                	li	a2,1
    80001b64:	040005b7          	lui	a1,0x4000
    80001b68:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b6a:	05b2                	slli	a1,a1,0xc
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	7ae080e7          	jalr	1966(ra) # 8000131c <uvmunmap>
    uvmfree(pagetable, 0);
    80001b76:	4581                	li	a1,0
    80001b78:	8526                	mv	a0,s1
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	a64080e7          	jalr	-1436(ra) # 800015de <uvmfree>
    return 0;
    80001b82:	4481                	li	s1,0
    80001b84:	bf7d                	j	80001b42 <proc_pagetable+0x58>

0000000080001b86 <proc_freepagetable>:
{
    80001b86:	1101                	addi	sp,sp,-32
    80001b88:	ec06                	sd	ra,24(sp)
    80001b8a:	e822                	sd	s0,16(sp)
    80001b8c:	e426                	sd	s1,8(sp)
    80001b8e:	e04a                	sd	s2,0(sp)
    80001b90:	1000                	addi	s0,sp,32
    80001b92:	84aa                	mv	s1,a0
    80001b94:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b96:	4681                	li	a3,0
    80001b98:	4605                	li	a2,1
    80001b9a:	040005b7          	lui	a1,0x4000
    80001b9e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ba0:	05b2                	slli	a1,a1,0xc
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	77a080e7          	jalr	1914(ra) # 8000131c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001baa:	4681                	li	a3,0
    80001bac:	4605                	li	a2,1
    80001bae:	020005b7          	lui	a1,0x2000
    80001bb2:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb4:	05b6                	slli	a1,a1,0xd
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	764080e7          	jalr	1892(ra) # 8000131c <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc0:	85ca                	mv	a1,s2
    80001bc2:	8526                	mv	a0,s1
    80001bc4:	00000097          	auipc	ra,0x0
    80001bc8:	a1a080e7          	jalr	-1510(ra) # 800015de <uvmfree>
}
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <freeproc>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	1000                	addi	s0,sp,32
    80001be2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001be4:	6d28                	ld	a0,88(a0)
    80001be6:	c509                	beqz	a0,80001bf0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	e2a080e7          	jalr	-470(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001bf0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bf4:	68a8                	ld	a0,80(s1)
    80001bf6:	c511                	beqz	a0,80001c02 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bf8:	64ac                	ld	a1,72(s1)
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	f8c080e7          	jalr	-116(ra) # 80001b86 <proc_freepagetable>
  p->pagetable = 0;
    80001c02:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c06:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c0a:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c0e:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c12:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c16:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c1a:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c1e:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c22:	0004ac23          	sw	zero,24(s1)
}
    80001c26:	60e2                	ld	ra,24(sp)
    80001c28:	6442                	ld	s0,16(sp)
    80001c2a:	64a2                	ld	s1,8(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret

0000000080001c30 <allocproc>:
{
    80001c30:	1101                	addi	sp,sp,-32
    80001c32:	ec06                	sd	ra,24(sp)
    80001c34:	e822                	sd	s0,16(sp)
    80001c36:	e426                	sd	s1,8(sp)
    80001c38:	e04a                	sd	s2,0(sp)
    80001c3a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c3c:	00010497          	auipc	s1,0x10
    80001c40:	12c48493          	addi	s1,s1,300 # 80011d68 <proc>
    80001c44:	00016917          	auipc	s2,0x16
    80001c48:	d2490913          	addi	s2,s2,-732 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	fffff097          	auipc	ra,0xfffff
    80001c52:	00c080e7          	jalr	12(ra) # 80000c5a <acquire>
    if(p->state == UNUSED) {
    80001c56:	4c9c                	lw	a5,24(s1)
    80001c58:	cf81                	beqz	a5,80001c70 <allocproc+0x40>
      release(&p->lock);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	0b2080e7          	jalr	178(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c64:	17048493          	addi	s1,s1,368
    80001c68:	ff2492e3          	bne	s1,s2,80001c4c <allocproc+0x1c>
  return 0;
    80001c6c:	4481                	li	s1,0
    80001c6e:	a0b9                	j	80001cbc <allocproc+0x8c>
  p->pid = allocpid();
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	e34080e7          	jalr	-460(ra) # 80001aa4 <allocpid>
    80001c78:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	e96080e7          	jalr	-362(ra) # 80000b10 <kalloc>
    80001c82:	892a                	mv	s2,a0
    80001c84:	eca8                	sd	a0,88(s1)
    80001c86:	c131                	beqz	a0,80001cca <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c88:	8526                	mv	a0,s1
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e60080e7          	jalr	-416(ra) # 80001aea <proc_pagetable>
    80001c92:	892a                	mv	s2,a0
    80001c94:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c96:	c129                	beqz	a0,80001cd8 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c98:	07000613          	li	a2,112
    80001c9c:	4581                	li	a1,0
    80001c9e:	06048513          	addi	a0,s1,96
    80001ca2:	fffff097          	auipc	ra,0xfffff
    80001ca6:	0b4080e7          	jalr	180(ra) # 80000d56 <memset>
  p->context.ra = (uint64)forkret;
    80001caa:	00000797          	auipc	a5,0x0
    80001cae:	db478793          	addi	a5,a5,-588 # 80001a5e <forkret>
    80001cb2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cb4:	60bc                	ld	a5,64(s1)
    80001cb6:	6705                	lui	a4,0x1
    80001cb8:	97ba                	add	a5,a5,a4
    80001cba:	f4bc                	sd	a5,104(s1)
}
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6902                	ld	s2,0(sp)
    80001cc6:	6105                	addi	sp,sp,32
    80001cc8:	8082                	ret
    release(&p->lock);
    80001cca:	8526                	mv	a0,s1
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	042080e7          	jalr	66(ra) # 80000d0e <release>
    return 0;
    80001cd4:	84ca                	mv	s1,s2
    80001cd6:	b7dd                	j	80001cbc <allocproc+0x8c>
    freeproc(p);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	efe080e7          	jalr	-258(ra) # 80001bd8 <freeproc>
    release(&p->lock);
    80001ce2:	8526                	mv	a0,s1
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	02a080e7          	jalr	42(ra) # 80000d0e <release>
    return 0;
    80001cec:	84ca                	mv	s1,s2
    80001cee:	b7f9                	j	80001cbc <allocproc+0x8c>

0000000080001cf0 <userinit>:
{
    80001cf0:	1101                	addi	sp,sp,-32
    80001cf2:	ec06                	sd	ra,24(sp)
    80001cf4:	e822                	sd	s0,16(sp)
    80001cf6:	e426                	sd	s1,8(sp)
    80001cf8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cfa:	00000097          	auipc	ra,0x0
    80001cfe:	f36080e7          	jalr	-202(ra) # 80001c30 <allocproc>
    80001d02:	84aa                	mv	s1,a0
  initproc = p;
    80001d04:	00007797          	auipc	a5,0x7
    80001d08:	30a7ba23          	sd	a0,788(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d0c:	03400613          	li	a2,52
    80001d10:	00007597          	auipc	a1,0x7
    80001d14:	be058593          	addi	a1,a1,-1056 # 800088f0 <initcode>
    80001d18:	6928                	ld	a0,80(a0)
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	6f4080e7          	jalr	1780(ra) # 8000140e <uvminit>
  p->sz = PGSIZE;
    80001d22:	6785                	lui	a5,0x1
    80001d24:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d26:	6cb8                	ld	a4,88(s1)
    80001d28:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d2c:	6cb8                	ld	a4,88(s1)
    80001d2e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d30:	4641                	li	a2,16
    80001d32:	00006597          	auipc	a1,0x6
    80001d36:	4b658593          	addi	a1,a1,1206 # 800081e8 <digits+0x1a8>
    80001d3a:	15848513          	addi	a0,s1,344
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	16a080e7          	jalr	362(ra) # 80000ea8 <safestrcpy>
  p->cwd = namei("/");
    80001d46:	00006517          	auipc	a0,0x6
    80001d4a:	4b250513          	addi	a0,a0,1202 # 800081f8 <digits+0x1b8>
    80001d4e:	00002097          	auipc	ra,0x2
    80001d52:	282080e7          	jalr	642(ra) # 80003fd0 <namei>
    80001d56:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d5a:	4789                	li	a5,2
    80001d5c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	fae080e7          	jalr	-82(ra) # 80000d0e <release>
}
    80001d68:	60e2                	ld	ra,24(sp)
    80001d6a:	6442                	ld	s0,16(sp)
    80001d6c:	64a2                	ld	s1,8(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret

0000000080001d72 <growproc>:
{
    80001d72:	1101                	addi	sp,sp,-32
    80001d74:	ec06                	sd	ra,24(sp)
    80001d76:	e822                	sd	s0,16(sp)
    80001d78:	e426                	sd	s1,8(sp)
    80001d7a:	e04a                	sd	s2,0(sp)
    80001d7c:	1000                	addi	s0,sp,32
    80001d7e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d80:	00000097          	auipc	ra,0x0
    80001d84:	ca6080e7          	jalr	-858(ra) # 80001a26 <myproc>
    80001d88:	892a                	mv	s2,a0
  sz = p->sz;
    80001d8a:	652c                	ld	a1,72(a0)
    80001d8c:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80001d90:	00904f63          	bgtz	s1,80001dae <growproc+0x3c>
  } else if(n < 0){
    80001d94:	0204cd63          	bltz	s1,80001dce <growproc+0x5c>
  p->sz = sz;
    80001d98:	1782                	slli	a5,a5,0x20
    80001d9a:	9381                	srli	a5,a5,0x20
    80001d9c:	04f93423          	sd	a5,72(s2)
  return 0;
    80001da0:	4501                	li	a0,0
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6902                	ld	s2,0(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dae:	00f4863b          	addw	a2,s1,a5
    80001db2:	1602                	slli	a2,a2,0x20
    80001db4:	9201                	srli	a2,a2,0x20
    80001db6:	1582                	slli	a1,a1,0x20
    80001db8:	9181                	srli	a1,a1,0x20
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	70c080e7          	jalr	1804(ra) # 800014c8 <uvmalloc>
    80001dc4:	0005079b          	sext.w	a5,a0
    80001dc8:	fbe1                	bnez	a5,80001d98 <growproc+0x26>
      return -1;
    80001dca:	557d                	li	a0,-1
    80001dcc:	bfd9                	j	80001da2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dce:	00f4863b          	addw	a2,s1,a5
    80001dd2:	1602                	slli	a2,a2,0x20
    80001dd4:	9201                	srli	a2,a2,0x20
    80001dd6:	1582                	slli	a1,a1,0x20
    80001dd8:	9181                	srli	a1,a1,0x20
    80001dda:	6928                	ld	a0,80(a0)
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	6a4080e7          	jalr	1700(ra) # 80001480 <uvmdealloc>
    80001de4:	0005079b          	sext.w	a5,a0
    80001de8:	bf45                	j	80001d98 <growproc+0x26>

0000000080001dea <fork>:
{
    80001dea:	7139                	addi	sp,sp,-64
    80001dec:	fc06                	sd	ra,56(sp)
    80001dee:	f822                	sd	s0,48(sp)
    80001df0:	f426                	sd	s1,40(sp)
    80001df2:	f04a                	sd	s2,32(sp)
    80001df4:	ec4e                	sd	s3,24(sp)
    80001df6:	e852                	sd	s4,16(sp)
    80001df8:	e456                	sd	s5,8(sp)
    80001dfa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	c2a080e7          	jalr	-982(ra) # 80001a26 <myproc>
    80001e04:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e06:	00000097          	auipc	ra,0x0
    80001e0a:	e2a080e7          	jalr	-470(ra) # 80001c30 <allocproc>
    80001e0e:	c57d                	beqz	a0,80001efc <fork+0x112>
    80001e10:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e12:	048ab603          	ld	a2,72(s5)
    80001e16:	692c                	ld	a1,80(a0)
    80001e18:	050ab503          	ld	a0,80(s5)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	7fc080e7          	jalr	2044(ra) # 80001618 <uvmcopy>
    80001e24:	04054e63          	bltz	a0,80001e80 <fork+0x96>
  np->sz = p->sz;
    80001e28:	048ab783          	ld	a5,72(s5)
    80001e2c:	04fa3423          	sd	a5,72(s4)
  np->mask = p->mask;
    80001e30:	168aa783          	lw	a5,360(s5)
    80001e34:	16fa2423          	sw	a5,360(s4)
  np->parent = p;
    80001e38:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e3c:	058ab683          	ld	a3,88(s5)
    80001e40:	87b6                	mv	a5,a3
    80001e42:	058a3703          	ld	a4,88(s4)
    80001e46:	12068693          	addi	a3,a3,288
    80001e4a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e4e:	6788                	ld	a0,8(a5)
    80001e50:	6b8c                	ld	a1,16(a5)
    80001e52:	6f90                	ld	a2,24(a5)
    80001e54:	01073023          	sd	a6,0(a4)
    80001e58:	e708                	sd	a0,8(a4)
    80001e5a:	eb0c                	sd	a1,16(a4)
    80001e5c:	ef10                	sd	a2,24(a4)
    80001e5e:	02078793          	addi	a5,a5,32
    80001e62:	02070713          	addi	a4,a4,32
    80001e66:	fed792e3          	bne	a5,a3,80001e4a <fork+0x60>
  np->trapframe->a0 = 0;
    80001e6a:	058a3783          	ld	a5,88(s4)
    80001e6e:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e72:	0d0a8493          	addi	s1,s5,208
    80001e76:	0d0a0913          	addi	s2,s4,208
    80001e7a:	150a8993          	addi	s3,s5,336
    80001e7e:	a00d                	j	80001ea0 <fork+0xb6>
    freeproc(np);
    80001e80:	8552                	mv	a0,s4
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	d56080e7          	jalr	-682(ra) # 80001bd8 <freeproc>
    release(&np->lock);
    80001e8a:	8552                	mv	a0,s4
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	e82080e7          	jalr	-382(ra) # 80000d0e <release>
    return -1;
    80001e94:	54fd                	li	s1,-1
    80001e96:	a889                	j	80001ee8 <fork+0xfe>
  for(i = 0; i < NOFILE; i++)
    80001e98:	04a1                	addi	s1,s1,8
    80001e9a:	0921                	addi	s2,s2,8
    80001e9c:	01348b63          	beq	s1,s3,80001eb2 <fork+0xc8>
    if(p->ofile[i])
    80001ea0:	6088                	ld	a0,0(s1)
    80001ea2:	d97d                	beqz	a0,80001e98 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ea4:	00002097          	auipc	ra,0x2
    80001ea8:	7b8080e7          	jalr	1976(ra) # 8000465c <filedup>
    80001eac:	00a93023          	sd	a0,0(s2)
    80001eb0:	b7e5                	j	80001e98 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eb2:	150ab503          	ld	a0,336(s5)
    80001eb6:	00002097          	auipc	ra,0x2
    80001eba:	926080e7          	jalr	-1754(ra) # 800037dc <idup>
    80001ebe:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec2:	4641                	li	a2,16
    80001ec4:	158a8593          	addi	a1,s5,344
    80001ec8:	158a0513          	addi	a0,s4,344
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	fdc080e7          	jalr	-36(ra) # 80000ea8 <safestrcpy>
  pid = np->pid;
    80001ed4:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001ed8:	4789                	li	a5,2
    80001eda:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ede:	8552                	mv	a0,s4
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	e2e080e7          	jalr	-466(ra) # 80000d0e <release>
}
    80001ee8:	8526                	mv	a0,s1
    80001eea:	70e2                	ld	ra,56(sp)
    80001eec:	7442                	ld	s0,48(sp)
    80001eee:	74a2                	ld	s1,40(sp)
    80001ef0:	7902                	ld	s2,32(sp)
    80001ef2:	69e2                	ld	s3,24(sp)
    80001ef4:	6a42                	ld	s4,16(sp)
    80001ef6:	6aa2                	ld	s5,8(sp)
    80001ef8:	6121                	addi	sp,sp,64
    80001efa:	8082                	ret
    return -1;
    80001efc:	54fd                	li	s1,-1
    80001efe:	b7ed                	j	80001ee8 <fork+0xfe>

0000000080001f00 <reparent>:
{
    80001f00:	7179                	addi	sp,sp,-48
    80001f02:	f406                	sd	ra,40(sp)
    80001f04:	f022                	sd	s0,32(sp)
    80001f06:	ec26                	sd	s1,24(sp)
    80001f08:	e84a                	sd	s2,16(sp)
    80001f0a:	e44e                	sd	s3,8(sp)
    80001f0c:	e052                	sd	s4,0(sp)
    80001f0e:	1800                	addi	s0,sp,48
    80001f10:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f12:	00010497          	auipc	s1,0x10
    80001f16:	e5648493          	addi	s1,s1,-426 # 80011d68 <proc>
      pp->parent = initproc;
    80001f1a:	00007a17          	auipc	s4,0x7
    80001f1e:	0fea0a13          	addi	s4,s4,254 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f22:	00016997          	auipc	s3,0x16
    80001f26:	a4698993          	addi	s3,s3,-1466 # 80017968 <tickslock>
    80001f2a:	a029                	j	80001f34 <reparent+0x34>
    80001f2c:	17048493          	addi	s1,s1,368
    80001f30:	03348363          	beq	s1,s3,80001f56 <reparent+0x56>
    if(pp->parent == p){
    80001f34:	709c                	ld	a5,32(s1)
    80001f36:	ff279be3          	bne	a5,s2,80001f2c <reparent+0x2c>
      acquire(&pp->lock);
    80001f3a:	8526                	mv	a0,s1
    80001f3c:	fffff097          	auipc	ra,0xfffff
    80001f40:	d1e080e7          	jalr	-738(ra) # 80000c5a <acquire>
      pp->parent = initproc;
    80001f44:	000a3783          	ld	a5,0(s4)
    80001f48:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	fffff097          	auipc	ra,0xfffff
    80001f50:	dc2080e7          	jalr	-574(ra) # 80000d0e <release>
    80001f54:	bfe1                	j	80001f2c <reparent+0x2c>
}
    80001f56:	70a2                	ld	ra,40(sp)
    80001f58:	7402                	ld	s0,32(sp)
    80001f5a:	64e2                	ld	s1,24(sp)
    80001f5c:	6942                	ld	s2,16(sp)
    80001f5e:	69a2                	ld	s3,8(sp)
    80001f60:	6a02                	ld	s4,0(sp)
    80001f62:	6145                	addi	sp,sp,48
    80001f64:	8082                	ret

0000000080001f66 <scheduler>:
{
    80001f66:	715d                	addi	sp,sp,-80
    80001f68:	e486                	sd	ra,72(sp)
    80001f6a:	e0a2                	sd	s0,64(sp)
    80001f6c:	fc26                	sd	s1,56(sp)
    80001f6e:	f84a                	sd	s2,48(sp)
    80001f70:	f44e                	sd	s3,40(sp)
    80001f72:	f052                	sd	s4,32(sp)
    80001f74:	ec56                	sd	s5,24(sp)
    80001f76:	e85a                	sd	s6,16(sp)
    80001f78:	e45e                	sd	s7,8(sp)
    80001f7a:	e062                	sd	s8,0(sp)
    80001f7c:	0880                	addi	s0,sp,80
    80001f7e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f80:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f82:	00779b13          	slli	s6,a5,0x7
    80001f86:	00010717          	auipc	a4,0x10
    80001f8a:	9ca70713          	addi	a4,a4,-1590 # 80011950 <pid_lock>
    80001f8e:	975a                	add	a4,a4,s6
    80001f90:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f94:	00010717          	auipc	a4,0x10
    80001f98:	9dc70713          	addi	a4,a4,-1572 # 80011970 <cpus+0x8>
    80001f9c:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f9e:	4c0d                	li	s8,3
        c->proc = p;
    80001fa0:	079e                	slli	a5,a5,0x7
    80001fa2:	00010a17          	auipc	s4,0x10
    80001fa6:	9aea0a13          	addi	s4,s4,-1618 # 80011950 <pid_lock>
    80001faa:	9a3e                	add	s4,s4,a5
        found = 1;
    80001fac:	4b85                	li	s7,1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fae:	00016997          	auipc	s3,0x16
    80001fb2:	9ba98993          	addi	s3,s3,-1606 # 80017968 <tickslock>
    80001fb6:	a899                	j	8000200c <scheduler+0xa6>
      release(&p->lock);
    80001fb8:	8526                	mv	a0,s1
    80001fba:	fffff097          	auipc	ra,0xfffff
    80001fbe:	d54080e7          	jalr	-684(ra) # 80000d0e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc2:	17048493          	addi	s1,s1,368
    80001fc6:	03348963          	beq	s1,s3,80001ff8 <scheduler+0x92>
      acquire(&p->lock);
    80001fca:	8526                	mv	a0,s1
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	c8e080e7          	jalr	-882(ra) # 80000c5a <acquire>
      if(p->state == RUNNABLE) {
    80001fd4:	4c9c                	lw	a5,24(s1)
    80001fd6:	ff2791e3          	bne	a5,s2,80001fb8 <scheduler+0x52>
        p->state = RUNNING;
    80001fda:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fde:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fe2:	06048593          	addi	a1,s1,96
    80001fe6:	855a                	mv	a0,s6
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	732080e7          	jalr	1842(ra) # 8000271a <swtch>
        c->proc = 0;
    80001ff0:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001ff4:	8ade                	mv	s5,s7
    80001ff6:	b7c9                	j	80001fb8 <scheduler+0x52>
    if(found == 0) {
    80001ff8:	000a9a63          	bnez	s5,8000200c <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ffc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002000:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002004:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002008:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000200c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002010:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002014:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002018:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201a:	00010497          	auipc	s1,0x10
    8000201e:	d4e48493          	addi	s1,s1,-690 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002022:	4909                	li	s2,2
    80002024:	b75d                	j	80001fca <scheduler+0x64>

0000000080002026 <sched>:
{
    80002026:	7179                	addi	sp,sp,-48
    80002028:	f406                	sd	ra,40(sp)
    8000202a:	f022                	sd	s0,32(sp)
    8000202c:	ec26                	sd	s1,24(sp)
    8000202e:	e84a                	sd	s2,16(sp)
    80002030:	e44e                	sd	s3,8(sp)
    80002032:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002034:	00000097          	auipc	ra,0x0
    80002038:	9f2080e7          	jalr	-1550(ra) # 80001a26 <myproc>
    8000203c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	ba2080e7          	jalr	-1118(ra) # 80000be0 <holding>
    80002046:	c93d                	beqz	a0,800020bc <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002048:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	00010717          	auipc	a4,0x10
    80002052:	90270713          	addi	a4,a4,-1790 # 80011950 <pid_lock>
    80002056:	97ba                	add	a5,a5,a4
    80002058:	0907a703          	lw	a4,144(a5)
    8000205c:	4785                	li	a5,1
    8000205e:	06f71763          	bne	a4,a5,800020cc <sched+0xa6>
  if(p->state == RUNNING)
    80002062:	4c98                	lw	a4,24(s1)
    80002064:	478d                	li	a5,3
    80002066:	06f70b63          	beq	a4,a5,800020dc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000206e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002070:	efb5                	bnez	a5,800020ec <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002072:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002074:	00010917          	auipc	s2,0x10
    80002078:	8dc90913          	addi	s2,s2,-1828 # 80011950 <pid_lock>
    8000207c:	2781                	sext.w	a5,a5
    8000207e:	079e                	slli	a5,a5,0x7
    80002080:	97ca                	add	a5,a5,s2
    80002082:	0947a983          	lw	s3,148(a5)
    80002086:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002088:	2781                	sext.w	a5,a5
    8000208a:	079e                	slli	a5,a5,0x7
    8000208c:	00010597          	auipc	a1,0x10
    80002090:	8e458593          	addi	a1,a1,-1820 # 80011970 <cpus+0x8>
    80002094:	95be                	add	a1,a1,a5
    80002096:	06048513          	addi	a0,s1,96
    8000209a:	00000097          	auipc	ra,0x0
    8000209e:	680080e7          	jalr	1664(ra) # 8000271a <swtch>
    800020a2:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a4:	2781                	sext.w	a5,a5
    800020a6:	079e                	slli	a5,a5,0x7
    800020a8:	993e                	add	s2,s2,a5
    800020aa:	09392a23          	sw	s3,148(s2)
}
    800020ae:	70a2                	ld	ra,40(sp)
    800020b0:	7402                	ld	s0,32(sp)
    800020b2:	64e2                	ld	s1,24(sp)
    800020b4:	6942                	ld	s2,16(sp)
    800020b6:	69a2                	ld	s3,8(sp)
    800020b8:	6145                	addi	sp,sp,48
    800020ba:	8082                	ret
    panic("sched p->lock");
    800020bc:	00006517          	auipc	a0,0x6
    800020c0:	14450513          	addi	a0,a0,324 # 80008200 <digits+0x1c0>
    800020c4:	ffffe097          	auipc	ra,0xffffe
    800020c8:	482080e7          	jalr	1154(ra) # 80000546 <panic>
    panic("sched locks");
    800020cc:	00006517          	auipc	a0,0x6
    800020d0:	14450513          	addi	a0,a0,324 # 80008210 <digits+0x1d0>
    800020d4:	ffffe097          	auipc	ra,0xffffe
    800020d8:	472080e7          	jalr	1138(ra) # 80000546 <panic>
    panic("sched running");
    800020dc:	00006517          	auipc	a0,0x6
    800020e0:	14450513          	addi	a0,a0,324 # 80008220 <digits+0x1e0>
    800020e4:	ffffe097          	auipc	ra,0xffffe
    800020e8:	462080e7          	jalr	1122(ra) # 80000546 <panic>
    panic("sched interruptible");
    800020ec:	00006517          	auipc	a0,0x6
    800020f0:	14450513          	addi	a0,a0,324 # 80008230 <digits+0x1f0>
    800020f4:	ffffe097          	auipc	ra,0xffffe
    800020f8:	452080e7          	jalr	1106(ra) # 80000546 <panic>

00000000800020fc <exit>:
{
    800020fc:	7179                	addi	sp,sp,-48
    800020fe:	f406                	sd	ra,40(sp)
    80002100:	f022                	sd	s0,32(sp)
    80002102:	ec26                	sd	s1,24(sp)
    80002104:	e84a                	sd	s2,16(sp)
    80002106:	e44e                	sd	s3,8(sp)
    80002108:	e052                	sd	s4,0(sp)
    8000210a:	1800                	addi	s0,sp,48
    8000210c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	918080e7          	jalr	-1768(ra) # 80001a26 <myproc>
    80002116:	89aa                	mv	s3,a0
  if(p == initproc)
    80002118:	00007797          	auipc	a5,0x7
    8000211c:	f007b783          	ld	a5,-256(a5) # 80009018 <initproc>
    80002120:	0d050493          	addi	s1,a0,208
    80002124:	15050913          	addi	s2,a0,336
    80002128:	02a79363          	bne	a5,a0,8000214e <exit+0x52>
    panic("init exiting");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	11c50513          	addi	a0,a0,284 # 80008248 <digits+0x208>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	412080e7          	jalr	1042(ra) # 80000546 <panic>
      fileclose(f);
    8000213c:	00002097          	auipc	ra,0x2
    80002140:	572080e7          	jalr	1394(ra) # 800046ae <fileclose>
      p->ofile[fd] = 0;
    80002144:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002148:	04a1                	addi	s1,s1,8
    8000214a:	01248563          	beq	s1,s2,80002154 <exit+0x58>
    if(p->ofile[fd]){
    8000214e:	6088                	ld	a0,0(s1)
    80002150:	f575                	bnez	a0,8000213c <exit+0x40>
    80002152:	bfdd                	j	80002148 <exit+0x4c>
  begin_op();
    80002154:	00002097          	auipc	ra,0x2
    80002158:	08c080e7          	jalr	140(ra) # 800041e0 <begin_op>
  iput(p->cwd);
    8000215c:	1509b503          	ld	a0,336(s3)
    80002160:	00002097          	auipc	ra,0x2
    80002164:	874080e7          	jalr	-1932(ra) # 800039d4 <iput>
  end_op();
    80002168:	00002097          	auipc	ra,0x2
    8000216c:	0f6080e7          	jalr	246(ra) # 8000425e <end_op>
  p->cwd = 0;
    80002170:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002174:	00007497          	auipc	s1,0x7
    80002178:	ea448493          	addi	s1,s1,-348 # 80009018 <initproc>
    8000217c:	6088                	ld	a0,0(s1)
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	adc080e7          	jalr	-1316(ra) # 80000c5a <acquire>
  wakeup1(initproc);
    80002186:	6088                	ld	a0,0(s1)
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	75e080e7          	jalr	1886(ra) # 800018e6 <wakeup1>
  release(&initproc->lock);
    80002190:	6088                	ld	a0,0(s1)
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	b7c080e7          	jalr	-1156(ra) # 80000d0e <release>
  acquire(&p->lock);
    8000219a:	854e                	mv	a0,s3
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	abe080e7          	jalr	-1346(ra) # 80000c5a <acquire>
  struct proc *original_parent = p->parent;
    800021a4:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021a8:	854e                	mv	a0,s3
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	b64080e7          	jalr	-1180(ra) # 80000d0e <release>
  acquire(&original_parent->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	aa6080e7          	jalr	-1370(ra) # 80000c5a <acquire>
  acquire(&p->lock);
    800021bc:	854e                	mv	a0,s3
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	a9c080e7          	jalr	-1380(ra) # 80000c5a <acquire>
  reparent(p);
    800021c6:	854e                	mv	a0,s3
    800021c8:	00000097          	auipc	ra,0x0
    800021cc:	d38080e7          	jalr	-712(ra) # 80001f00 <reparent>
  wakeup1(original_parent);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	714080e7          	jalr	1812(ra) # 800018e6 <wakeup1>
  p->xstate = status;
    800021da:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021de:	4791                	li	a5,4
    800021e0:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e4:	8526                	mv	a0,s1
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	b28080e7          	jalr	-1240(ra) # 80000d0e <release>
  sched();
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	e38080e7          	jalr	-456(ra) # 80002026 <sched>
  panic("zombie exit");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	06250513          	addi	a0,a0,98 # 80008258 <digits+0x218>
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	348080e7          	jalr	840(ra) # 80000546 <panic>

0000000080002206 <yield>:
{
    80002206:	1101                	addi	sp,sp,-32
    80002208:	ec06                	sd	ra,24(sp)
    8000220a:	e822                	sd	s0,16(sp)
    8000220c:	e426                	sd	s1,8(sp)
    8000220e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002210:	00000097          	auipc	ra,0x0
    80002214:	816080e7          	jalr	-2026(ra) # 80001a26 <myproc>
    80002218:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a40080e7          	jalr	-1472(ra) # 80000c5a <acquire>
  p->state = RUNNABLE;
    80002222:	4789                	li	a5,2
    80002224:	cc9c                	sw	a5,24(s1)
  sched();
    80002226:	00000097          	auipc	ra,0x0
    8000222a:	e00080e7          	jalr	-512(ra) # 80002026 <sched>
  release(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	ade080e7          	jalr	-1314(ra) # 80000d0e <release>
}
    80002238:	60e2                	ld	ra,24(sp)
    8000223a:	6442                	ld	s0,16(sp)
    8000223c:	64a2                	ld	s1,8(sp)
    8000223e:	6105                	addi	sp,sp,32
    80002240:	8082                	ret

0000000080002242 <sleep>:
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	1800                	addi	s0,sp,48
    80002250:	89aa                	mv	s3,a0
    80002252:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	7d2080e7          	jalr	2002(ra) # 80001a26 <myproc>
    8000225c:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000225e:	05250663          	beq	a0,s2,800022aa <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	9f8080e7          	jalr	-1544(ra) # 80000c5a <acquire>
    release(lk);
    8000226a:	854a                	mv	a0,s2
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	aa2080e7          	jalr	-1374(ra) # 80000d0e <release>
  p->chan = chan;
    80002274:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002278:	4785                	li	a5,1
    8000227a:	cc9c                	sw	a5,24(s1)
  sched();
    8000227c:	00000097          	auipc	ra,0x0
    80002280:	daa080e7          	jalr	-598(ra) # 80002026 <sched>
  p->chan = 0;
    80002284:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002288:	8526                	mv	a0,s1
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a84080e7          	jalr	-1404(ra) # 80000d0e <release>
    acquire(lk);
    80002292:	854a                	mv	a0,s2
    80002294:	fffff097          	auipc	ra,0xfffff
    80002298:	9c6080e7          	jalr	-1594(ra) # 80000c5a <acquire>
}
    8000229c:	70a2                	ld	ra,40(sp)
    8000229e:	7402                	ld	s0,32(sp)
    800022a0:	64e2                	ld	s1,24(sp)
    800022a2:	6942                	ld	s2,16(sp)
    800022a4:	69a2                	ld	s3,8(sp)
    800022a6:	6145                	addi	sp,sp,48
    800022a8:	8082                	ret
  p->chan = chan;
    800022aa:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022ae:	4785                	li	a5,1
    800022b0:	cd1c                	sw	a5,24(a0)
  sched();
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	d74080e7          	jalr	-652(ra) # 80002026 <sched>
  p->chan = 0;
    800022ba:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022be:	bff9                	j	8000229c <sleep+0x5a>

00000000800022c0 <wait>:
{
    800022c0:	715d                	addi	sp,sp,-80
    800022c2:	e486                	sd	ra,72(sp)
    800022c4:	e0a2                	sd	s0,64(sp)
    800022c6:	fc26                	sd	s1,56(sp)
    800022c8:	f84a                	sd	s2,48(sp)
    800022ca:	f44e                	sd	s3,40(sp)
    800022cc:	f052                	sd	s4,32(sp)
    800022ce:	ec56                	sd	s5,24(sp)
    800022d0:	e85a                	sd	s6,16(sp)
    800022d2:	e45e                	sd	s7,8(sp)
    800022d4:	0880                	addi	s0,sp,80
    800022d6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	74e080e7          	jalr	1870(ra) # 80001a26 <myproc>
    800022e0:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	978080e7          	jalr	-1672(ra) # 80000c5a <acquire>
    havekids = 0;
    800022ea:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022ec:	4a11                	li	s4,4
        havekids = 1;
    800022ee:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800022f0:	00015997          	auipc	s3,0x15
    800022f4:	67898993          	addi	s3,s3,1656 # 80017968 <tickslock>
    havekids = 0;
    800022f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022fa:	00010497          	auipc	s1,0x10
    800022fe:	a6e48493          	addi	s1,s1,-1426 # 80011d68 <proc>
    80002302:	a08d                	j	80002364 <wait+0xa4>
          pid = np->pid;
    80002304:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002308:	000b0e63          	beqz	s6,80002324 <wait+0x64>
    8000230c:	4691                	li	a3,4
    8000230e:	03448613          	addi	a2,s1,52
    80002312:	85da                	mv	a1,s6
    80002314:	05093503          	ld	a0,80(s2)
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	404080e7          	jalr	1028(ra) # 8000171c <copyout>
    80002320:	02054263          	bltz	a0,80002344 <wait+0x84>
          freeproc(np);
    80002324:	8526                	mv	a0,s1
    80002326:	00000097          	auipc	ra,0x0
    8000232a:	8b2080e7          	jalr	-1870(ra) # 80001bd8 <freeproc>
          release(&np->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	9de080e7          	jalr	-1570(ra) # 80000d0e <release>
          release(&p->lock);
    80002338:	854a                	mv	a0,s2
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	9d4080e7          	jalr	-1580(ra) # 80000d0e <release>
          return pid;
    80002342:	a8a9                	j	8000239c <wait+0xdc>
            release(&np->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	9c8080e7          	jalr	-1592(ra) # 80000d0e <release>
            release(&p->lock);
    8000234e:	854a                	mv	a0,s2
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	9be080e7          	jalr	-1602(ra) # 80000d0e <release>
            return -1;
    80002358:	59fd                	li	s3,-1
    8000235a:	a089                	j	8000239c <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000235c:	17048493          	addi	s1,s1,368
    80002360:	03348463          	beq	s1,s3,80002388 <wait+0xc8>
      if(np->parent == p){
    80002364:	709c                	ld	a5,32(s1)
    80002366:	ff279be3          	bne	a5,s2,8000235c <wait+0x9c>
        acquire(&np->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	8ee080e7          	jalr	-1810(ra) # 80000c5a <acquire>
        if(np->state == ZOMBIE){
    80002374:	4c9c                	lw	a5,24(s1)
    80002376:	f94787e3          	beq	a5,s4,80002304 <wait+0x44>
        release(&np->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	992080e7          	jalr	-1646(ra) # 80000d0e <release>
        havekids = 1;
    80002384:	8756                	mv	a4,s5
    80002386:	bfd9                	j	8000235c <wait+0x9c>
    if(!havekids || p->killed){
    80002388:	c701                	beqz	a4,80002390 <wait+0xd0>
    8000238a:	03092783          	lw	a5,48(s2)
    8000238e:	c39d                	beqz	a5,800023b4 <wait+0xf4>
      release(&p->lock);
    80002390:	854a                	mv	a0,s2
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	97c080e7          	jalr	-1668(ra) # 80000d0e <release>
      return -1;
    8000239a:	59fd                	li	s3,-1
}
    8000239c:	854e                	mv	a0,s3
    8000239e:	60a6                	ld	ra,72(sp)
    800023a0:	6406                	ld	s0,64(sp)
    800023a2:	74e2                	ld	s1,56(sp)
    800023a4:	7942                	ld	s2,48(sp)
    800023a6:	79a2                	ld	s3,40(sp)
    800023a8:	7a02                	ld	s4,32(sp)
    800023aa:	6ae2                	ld	s5,24(sp)
    800023ac:	6b42                	ld	s6,16(sp)
    800023ae:	6ba2                	ld	s7,8(sp)
    800023b0:	6161                	addi	sp,sp,80
    800023b2:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023b4:	85ca                	mv	a1,s2
    800023b6:	854a                	mv	a0,s2
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	e8a080e7          	jalr	-374(ra) # 80002242 <sleep>
    havekids = 0;
    800023c0:	bf25                	j	800022f8 <wait+0x38>

00000000800023c2 <wakeup>:
{
    800023c2:	7139                	addi	sp,sp,-64
    800023c4:	fc06                	sd	ra,56(sp)
    800023c6:	f822                	sd	s0,48(sp)
    800023c8:	f426                	sd	s1,40(sp)
    800023ca:	f04a                	sd	s2,32(sp)
    800023cc:	ec4e                	sd	s3,24(sp)
    800023ce:	e852                	sd	s4,16(sp)
    800023d0:	e456                	sd	s5,8(sp)
    800023d2:	0080                	addi	s0,sp,64
    800023d4:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d6:	00010497          	auipc	s1,0x10
    800023da:	99248493          	addi	s1,s1,-1646 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023de:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023e0:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e2:	00015917          	auipc	s2,0x15
    800023e6:	58690913          	addi	s2,s2,1414 # 80017968 <tickslock>
    800023ea:	a811                	j	800023fe <wakeup+0x3c>
    release(&p->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	920080e7          	jalr	-1760(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023f6:	17048493          	addi	s1,s1,368
    800023fa:	03248063          	beq	s1,s2,8000241a <wakeup+0x58>
    acquire(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	85a080e7          	jalr	-1958(ra) # 80000c5a <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002408:	4c9c                	lw	a5,24(s1)
    8000240a:	ff3791e3          	bne	a5,s3,800023ec <wakeup+0x2a>
    8000240e:	749c                	ld	a5,40(s1)
    80002410:	fd479ee3          	bne	a5,s4,800023ec <wakeup+0x2a>
      p->state = RUNNABLE;
    80002414:	0154ac23          	sw	s5,24(s1)
    80002418:	bfd1                	j	800023ec <wakeup+0x2a>
}
    8000241a:	70e2                	ld	ra,56(sp)
    8000241c:	7442                	ld	s0,48(sp)
    8000241e:	74a2                	ld	s1,40(sp)
    80002420:	7902                	ld	s2,32(sp)
    80002422:	69e2                	ld	s3,24(sp)
    80002424:	6a42                	ld	s4,16(sp)
    80002426:	6aa2                	ld	s5,8(sp)
    80002428:	6121                	addi	sp,sp,64
    8000242a:	8082                	ret

000000008000242c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000243c:	00010497          	auipc	s1,0x10
    80002440:	92c48493          	addi	s1,s1,-1748 # 80011d68 <proc>
    80002444:	00015997          	auipc	s3,0x15
    80002448:	52498993          	addi	s3,s3,1316 # 80017968 <tickslock>
    acquire(&p->lock);
    8000244c:	8526                	mv	a0,s1
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	80c080e7          	jalr	-2036(ra) # 80000c5a <acquire>
    if(p->pid == pid){
    80002456:	5c9c                	lw	a5,56(s1)
    80002458:	01278d63          	beq	a5,s2,80002472 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000245c:	8526                	mv	a0,s1
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	8b0080e7          	jalr	-1872(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002466:	17048493          	addi	s1,s1,368
    8000246a:	ff3491e3          	bne	s1,s3,8000244c <kill+0x20>
  }
  return -1;
    8000246e:	557d                	li	a0,-1
    80002470:	a821                	j	80002488 <kill+0x5c>
      p->killed = 1;
    80002472:	4785                	li	a5,1
    80002474:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002476:	4c98                	lw	a4,24(s1)
    80002478:	00f70f63          	beq	a4,a5,80002496 <kill+0x6a>
      release(&p->lock);
    8000247c:	8526                	mv	a0,s1
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	890080e7          	jalr	-1904(ra) # 80000d0e <release>
      return 0;
    80002486:	4501                	li	a0,0
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
        p->state = RUNNABLE;
    80002496:	4789                	li	a5,2
    80002498:	cc9c                	sw	a5,24(s1)
    8000249a:	b7cd                	j	8000247c <kill+0x50>

000000008000249c <trace>:

int trace(int mask){
    8000249c:	1101                	addi	sp,sp,-32
    8000249e:	ec06                	sd	ra,24(sp)
    800024a0:	e822                	sd	s0,16(sp)
    800024a2:	e426                	sd	s1,8(sp)
    800024a4:	1000                	addi	s0,sp,32
    800024a6:	84aa                	mv	s1,a0
  myproc()->mask = mask;
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	57e080e7          	jalr	1406(ra) # 80001a26 <myproc>
    800024b0:	16952423          	sw	s1,360(a0)
  return 0;
}
    800024b4:	4501                	li	a0,0
    800024b6:	60e2                	ld	ra,24(sp)
    800024b8:	6442                	ld	s0,16(sp)
    800024ba:	64a2                	ld	s1,8(sp)
    800024bc:	6105                	addi	sp,sp,32
    800024be:	8082                	ret

00000000800024c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	84aa                	mv	s1,a0
    800024d2:	892e                	mv	s2,a1
    800024d4:	89b2                	mv	s3,a2
    800024d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	54e080e7          	jalr	1358(ra) # 80001a26 <myproc>
  if(user_dst){
    800024e0:	c08d                	beqz	s1,80002502 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e2:	86d2                	mv	a3,s4
    800024e4:	864e                	mv	a2,s3
    800024e6:	85ca                	mv	a1,s2
    800024e8:	6928                	ld	a0,80(a0)
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	232080e7          	jalr	562(ra) # 8000171c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f2:	70a2                	ld	ra,40(sp)
    800024f4:	7402                	ld	s0,32(sp)
    800024f6:	64e2                	ld	s1,24(sp)
    800024f8:	6942                	ld	s2,16(sp)
    800024fa:	69a2                	ld	s3,8(sp)
    800024fc:	6a02                	ld	s4,0(sp)
    800024fe:	6145                	addi	sp,sp,48
    80002500:	8082                	ret
    memmove((char *)dst, src, len);
    80002502:	000a061b          	sext.w	a2,s4
    80002506:	85ce                	mv	a1,s3
    80002508:	854a                	mv	a0,s2
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	8a8080e7          	jalr	-1880(ra) # 80000db2 <memmove>
    return 0;
    80002512:	8526                	mv	a0,s1
    80002514:	bff9                	j	800024f2 <either_copyout+0x32>

0000000080002516 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	892a                	mv	s2,a0
    80002528:	84ae                	mv	s1,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	4f8080e7          	jalr	1272(ra) # 80001a26 <myproc>
  if(user_src){
    80002536:	c08d                	beqz	s1,80002558 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6928                	ld	a0,80(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	268080e7          	jalr	616(ra) # 800017a8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove(dst, (char*)src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	852080e7          	jalr	-1966(ra) # 80000db2 <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyin+0x32>

000000008000256c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256c:	715d                	addi	sp,sp,-80
    8000256e:	e486                	sd	ra,72(sp)
    80002570:	e0a2                	sd	s0,64(sp)
    80002572:	fc26                	sd	s1,56(sp)
    80002574:	f84a                	sd	s2,48(sp)
    80002576:	f44e                	sd	s3,40(sp)
    80002578:	f052                	sd	s4,32(sp)
    8000257a:	ec56                	sd	s5,24(sp)
    8000257c:	e85a                	sd	s6,16(sp)
    8000257e:	e45e                	sd	s7,8(sp)
    80002580:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	b4650513          	addi	a0,a0,-1210 # 800080c8 <digits+0x88>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	006080e7          	jalr	6(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	00010497          	auipc	s1,0x10
    80002596:	92e48493          	addi	s1,s1,-1746 # 80011ec0 <proc+0x158>
    8000259a:	00015917          	auipc	s2,0x15
    8000259e:	52690913          	addi	s2,s2,1318 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025a4:	00006997          	auipc	s3,0x6
    800025a8:	cc498993          	addi	s3,s3,-828 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025ac:	00006a97          	auipc	s5,0x6
    800025b0:	cc4a8a93          	addi	s5,s5,-828 # 80008270 <digits+0x230>
    printf("\n");
    800025b4:	00006a17          	auipc	s4,0x6
    800025b8:	b14a0a13          	addi	s4,s4,-1260 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	cecb8b93          	addi	s7,s7,-788 # 800082a8 <states.0>
    800025c4:	a00d                	j	800025e6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c6:	ee06a583          	lw	a1,-288(a3)
    800025ca:	8556                	mv	a0,s5
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fc4080e7          	jalr	-60(ra) # 80000590 <printf>
    printf("\n");
    800025d4:	8552                	mv	a0,s4
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fba080e7          	jalr	-70(ra) # 80000590 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	17048493          	addi	s1,s1,368
    800025e2:	03248263          	beq	s1,s2,80002606 <procdump+0x9a>
    if(p->state == UNUSED)
    800025e6:	86a6                	mv	a3,s1
    800025e8:	ec04a783          	lw	a5,-320(s1)
    800025ec:	dbed                	beqz	a5,800025de <procdump+0x72>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	fcfb6be3          	bltu	s6,a5,800025c6 <procdump+0x5a>
    800025f4:	02079713          	slli	a4,a5,0x20
    800025f8:	01d75793          	srli	a5,a4,0x1d
    800025fc:	97de                	add	a5,a5,s7
    800025fe:	6390                	ld	a2,0(a5)
    80002600:	f279                	bnez	a2,800025c6 <procdump+0x5a>
      state = "???";
    80002602:	864e                	mv	a2,s3
    80002604:	b7c9                	j	800025c6 <procdump+0x5a>
  }
}
    80002606:	60a6                	ld	ra,72(sp)
    80002608:	6406                	ld	s0,64(sp)
    8000260a:	74e2                	ld	s1,56(sp)
    8000260c:	7942                	ld	s2,48(sp)
    8000260e:	79a2                	ld	s3,40(sp)
    80002610:	7a02                	ld	s4,32(sp)
    80002612:	6ae2                	ld	s5,24(sp)
    80002614:	6b42                	ld	s6,16(sp)
    80002616:	6ba2                	ld	s7,8(sp)
    80002618:	6161                	addi	sp,sp,80
    8000261a:	8082                	ret

000000008000261c <num_freeproc>:

int 
num_freeproc(){
    8000261c:	7179                	addi	sp,sp,-48
    8000261e:	f406                	sd	ra,40(sp)
    80002620:	f022                	sd	s0,32(sp)
    80002622:	ec26                	sd	s1,24(sp)
    80002624:	e84a                	sd	s2,16(sp)
    80002626:	e44e                	sd	s3,8(sp)
    80002628:	1800                	addi	s0,sp,48
  int result=0;
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000262a:	0000f497          	auipc	s1,0xf
    8000262e:	73e48493          	addi	s1,s1,1854 # 80011d68 <proc>
  int result=0;
    80002632:	4901                	li	s2,0
  for(p = proc; p < &proc[NPROC]; p++){
    80002634:	00015997          	auipc	s3,0x15
    80002638:	33498993          	addi	s3,s3,820 # 80017968 <tickslock>
    8000263c:	a811                	j	80002650 <num_freeproc+0x34>
    acquire(&p->lock);
    if(p->state==UNUSED){
      result++;
    }
    release(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	6ce080e7          	jalr	1742(ra) # 80000d0e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002648:	17048493          	addi	s1,s1,368
    8000264c:	01348b63          	beq	s1,s3,80002662 <num_freeproc+0x46>
    acquire(&p->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	608080e7          	jalr	1544(ra) # 80000c5a <acquire>
    if(p->state==UNUSED){
    8000265a:	4c9c                	lw	a5,24(s1)
    8000265c:	f3ed                	bnez	a5,8000263e <num_freeproc+0x22>
      result++;
    8000265e:	2905                	addiw	s2,s2,1
    80002660:	bff9                	j	8000263e <num_freeproc+0x22>
  }
  return result;
}
    80002662:	854a                	mv	a0,s2
    80002664:	70a2                	ld	ra,40(sp)
    80002666:	7402                	ld	s0,32(sp)
    80002668:	64e2                	ld	s1,24(sp)
    8000266a:	6942                	ld	s2,16(sp)
    8000266c:	69a2                	ld	s3,8(sp)
    8000266e:	6145                	addi	sp,sp,48
    80002670:	8082                	ret

0000000080002672 <num_free_ofile>:

uint64 
num_free_ofile(){
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	3ac080e7          	jalr	940(ra) # 80001a26 <myproc>
  int result=0;

  for(int fd = 0; fd < NOFILE; fd++){
    80002682:	0d050793          	addi	a5,a0,208
    80002686:	15050693          	addi	a3,a0,336
  int result=0;
    8000268a:	4501                	li	a0,0
    8000268c:	a021                	j	80002694 <num_free_ofile+0x22>
  for(int fd = 0; fd < NOFILE; fd++){
    8000268e:	07a1                	addi	a5,a5,8
    80002690:	00d78663          	beq	a5,a3,8000269c <num_free_ofile+0x2a>
    if(!p->ofile[fd]){
    80002694:	6398                	ld	a4,0(a5)
    80002696:	ff65                	bnez	a4,8000268e <num_free_ofile+0x1c>
      result++;
    80002698:	2505                	addiw	a0,a0,1
    8000269a:	bfd5                	j	8000268e <num_free_ofile+0x1c>
    }
  }
  return result;
}
    8000269c:	60a2                	ld	ra,8(sp)
    8000269e:	6402                	ld	s0,0(sp)
    800026a0:	0141                	addi	sp,sp,16
    800026a2:	8082                	ret

00000000800026a4 <sysinfo>:

int sysinfo(struct sysinfo* info){
    800026a4:	7179                	addi	sp,sp,-48
    800026a6:	f406                	sd	ra,40(sp)
    800026a8:	f022                	sd	s0,32(sp)
    800026aa:	ec26                	sd	s1,24(sp)
    800026ac:	e84a                	sd	s2,16(sp)
    800026ae:	1800                	addi	s0,sp,48
    800026b0:	84aa                	mv	s1,a0
    uint64 addr;
    if(argaddr(0,&addr)<0)
    800026b2:	fd840593          	addi	a1,s0,-40
    800026b6:	4501                	li	a0,0
    800026b8:	00000097          	auipc	ra,0x0
    800026bc:	576080e7          	jalr	1398(ra) # 80002c2e <argaddr>
    800026c0:	04054863          	bltz	a0,80002710 <sysinfo+0x6c>
    {
      exit(-1);
    }
    struct proc* p = myproc();
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	362080e7          	jalr	866(ra) # 80001a26 <myproc>
    800026cc:	892a                	mv	s2,a0
    info->freemem = cal_free_mem();
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	4a2080e7          	jalr	1186(ra) # 80000b70 <cal_free_mem>
    800026d6:	e088                	sd	a0,0(s1)
    info->freefd = num_free_ofile();
    800026d8:	00000097          	auipc	ra,0x0
    800026dc:	f9a080e7          	jalr	-102(ra) # 80002672 <num_free_ofile>
    800026e0:	e888                	sd	a0,16(s1)
    info->nproc = num_freeproc();
    800026e2:	00000097          	auipc	ra,0x0
    800026e6:	f3a080e7          	jalr	-198(ra) # 8000261c <num_freeproc>
    800026ea:	e488                	sd	a0,8(s1)
    if(copyout(p->pagetable, addr, (char *)info, sizeof(*info)) < 0)
    800026ec:	46e1                	li	a3,24
    800026ee:	8626                	mv	a2,s1
    800026f0:	fd843583          	ld	a1,-40(s0)
    800026f4:	05093503          	ld	a0,80(s2)
    800026f8:	fffff097          	auipc	ra,0xfffff
    800026fc:	024080e7          	jalr	36(ra) # 8000171c <copyout>
      return -1;
    return 0;
    80002700:	41f5551b          	sraiw	a0,a0,0x1f
    80002704:	70a2                	ld	ra,40(sp)
    80002706:	7402                	ld	s0,32(sp)
    80002708:	64e2                	ld	s1,24(sp)
    8000270a:	6942                	ld	s2,16(sp)
    8000270c:	6145                	addi	sp,sp,48
    8000270e:	8082                	ret
      exit(-1);
    80002710:	557d                	li	a0,-1
    80002712:	00000097          	auipc	ra,0x0
    80002716:	9ea080e7          	jalr	-1558(ra) # 800020fc <exit>

000000008000271a <swtch>:
    8000271a:	00153023          	sd	ra,0(a0)
    8000271e:	00253423          	sd	sp,8(a0)
    80002722:	e900                	sd	s0,16(a0)
    80002724:	ed04                	sd	s1,24(a0)
    80002726:	03253023          	sd	s2,32(a0)
    8000272a:	03353423          	sd	s3,40(a0)
    8000272e:	03453823          	sd	s4,48(a0)
    80002732:	03553c23          	sd	s5,56(a0)
    80002736:	05653023          	sd	s6,64(a0)
    8000273a:	05753423          	sd	s7,72(a0)
    8000273e:	05853823          	sd	s8,80(a0)
    80002742:	05953c23          	sd	s9,88(a0)
    80002746:	07a53023          	sd	s10,96(a0)
    8000274a:	07b53423          	sd	s11,104(a0)
    8000274e:	0005b083          	ld	ra,0(a1)
    80002752:	0085b103          	ld	sp,8(a1)
    80002756:	6980                	ld	s0,16(a1)
    80002758:	6d84                	ld	s1,24(a1)
    8000275a:	0205b903          	ld	s2,32(a1)
    8000275e:	0285b983          	ld	s3,40(a1)
    80002762:	0305ba03          	ld	s4,48(a1)
    80002766:	0385ba83          	ld	s5,56(a1)
    8000276a:	0405bb03          	ld	s6,64(a1)
    8000276e:	0485bb83          	ld	s7,72(a1)
    80002772:	0505bc03          	ld	s8,80(a1)
    80002776:	0585bc83          	ld	s9,88(a1)
    8000277a:	0605bd03          	ld	s10,96(a1)
    8000277e:	0685bd83          	ld	s11,104(a1)
    80002782:	8082                	ret

0000000080002784 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002784:	1141                	addi	sp,sp,-16
    80002786:	e406                	sd	ra,8(sp)
    80002788:	e022                	sd	s0,0(sp)
    8000278a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000278c:	00006597          	auipc	a1,0x6
    80002790:	b4458593          	addi	a1,a1,-1212 # 800082d0 <states.0+0x28>
    80002794:	00015517          	auipc	a0,0x15
    80002798:	1d450513          	addi	a0,a0,468 # 80017968 <tickslock>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	42e080e7          	jalr	1070(ra) # 80000bca <initlock>
}
    800027a4:	60a2                	ld	ra,8(sp)
    800027a6:	6402                	ld	s0,0(sp)
    800027a8:	0141                	addi	sp,sp,16
    800027aa:	8082                	ret

00000000800027ac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ac:	1141                	addi	sp,sp,-16
    800027ae:	e422                	sd	s0,8(sp)
    800027b0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b2:	00003797          	auipc	a5,0x3
    800027b6:	55e78793          	addi	a5,a5,1374 # 80005d10 <kernelvec>
    800027ba:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027be:	6422                	ld	s0,8(sp)
    800027c0:	0141                	addi	sp,sp,16
    800027c2:	8082                	ret

00000000800027c4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027c4:	1141                	addi	sp,sp,-16
    800027c6:	e406                	sd	ra,8(sp)
    800027c8:	e022                	sd	s0,0(sp)
    800027ca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027cc:	fffff097          	auipc	ra,0xfffff
    800027d0:	25a080e7          	jalr	602(ra) # 80001a26 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027d8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027da:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027de:	00005697          	auipc	a3,0x5
    800027e2:	82268693          	addi	a3,a3,-2014 # 80007000 <_trampoline>
    800027e6:	00005717          	auipc	a4,0x5
    800027ea:	81a70713          	addi	a4,a4,-2022 # 80007000 <_trampoline>
    800027ee:	8f15                	sub	a4,a4,a3
    800027f0:	040007b7          	lui	a5,0x4000
    800027f4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800027f6:	07b2                	slli	a5,a5,0xc
    800027f8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fa:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027fe:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002800:	18002673          	csrr	a2,satp
    80002804:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002806:	6d30                	ld	a2,88(a0)
    80002808:	6138                	ld	a4,64(a0)
    8000280a:	6585                	lui	a1,0x1
    8000280c:	972e                	add	a4,a4,a1
    8000280e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002810:	6d38                	ld	a4,88(a0)
    80002812:	00000617          	auipc	a2,0x0
    80002816:	13860613          	addi	a2,a2,312 # 8000294a <usertrap>
    8000281a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000281c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000281e:	8612                	mv	a2,tp
    80002820:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002822:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002826:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000282a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000282e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002832:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002834:	6f18                	ld	a4,24(a4)
    80002836:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000283a:	692c                	ld	a1,80(a0)
    8000283c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000283e:	00005717          	auipc	a4,0x5
    80002842:	85270713          	addi	a4,a4,-1966 # 80007090 <userret>
    80002846:	8f15                	sub	a4,a4,a3
    80002848:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000284a:	577d                	li	a4,-1
    8000284c:	177e                	slli	a4,a4,0x3f
    8000284e:	8dd9                	or	a1,a1,a4
    80002850:	02000537          	lui	a0,0x2000
    80002854:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002856:	0536                	slli	a0,a0,0xd
    80002858:	9782                	jalr	a5
}
    8000285a:	60a2                	ld	ra,8(sp)
    8000285c:	6402                	ld	s0,0(sp)
    8000285e:	0141                	addi	sp,sp,16
    80002860:	8082                	ret

0000000080002862 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002862:	1101                	addi	sp,sp,-32
    80002864:	ec06                	sd	ra,24(sp)
    80002866:	e822                	sd	s0,16(sp)
    80002868:	e426                	sd	s1,8(sp)
    8000286a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000286c:	00015497          	auipc	s1,0x15
    80002870:	0fc48493          	addi	s1,s1,252 # 80017968 <tickslock>
    80002874:	8526                	mv	a0,s1
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	3e4080e7          	jalr	996(ra) # 80000c5a <acquire>
  ticks++;
    8000287e:	00006517          	auipc	a0,0x6
    80002882:	7a250513          	addi	a0,a0,1954 # 80009020 <ticks>
    80002886:	411c                	lw	a5,0(a0)
    80002888:	2785                	addiw	a5,a5,1
    8000288a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	b36080e7          	jalr	-1226(ra) # 800023c2 <wakeup>
  release(&tickslock);
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	478080e7          	jalr	1144(ra) # 80000d0e <release>
}
    8000289e:	60e2                	ld	ra,24(sp)
    800028a0:	6442                	ld	s0,16(sp)
    800028a2:	64a2                	ld	s1,8(sp)
    800028a4:	6105                	addi	sp,sp,32
    800028a6:	8082                	ret

00000000800028a8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028a8:	1101                	addi	sp,sp,-32
    800028aa:	ec06                	sd	ra,24(sp)
    800028ac:	e822                	sd	s0,16(sp)
    800028ae:	e426                	sd	s1,8(sp)
    800028b0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028b6:	00074d63          	bltz	a4,800028d0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028ba:	57fd                	li	a5,-1
    800028bc:	17fe                	slli	a5,a5,0x3f
    800028be:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028c0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028c2:	06f70363          	beq	a4,a5,80002928 <devintr+0x80>
  }
}
    800028c6:	60e2                	ld	ra,24(sp)
    800028c8:	6442                	ld	s0,16(sp)
    800028ca:	64a2                	ld	s1,8(sp)
    800028cc:	6105                	addi	sp,sp,32
    800028ce:	8082                	ret
     (scause & 0xff) == 9){
    800028d0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800028d4:	46a5                	li	a3,9
    800028d6:	fed792e3          	bne	a5,a3,800028ba <devintr+0x12>
    int irq = plic_claim();
    800028da:	00003097          	auipc	ra,0x3
    800028de:	53e080e7          	jalr	1342(ra) # 80005e18 <plic_claim>
    800028e2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028e4:	47a9                	li	a5,10
    800028e6:	02f50763          	beq	a0,a5,80002914 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ea:	4785                	li	a5,1
    800028ec:	02f50963          	beq	a0,a5,8000291e <devintr+0x76>
    return 1;
    800028f0:	4505                	li	a0,1
    } else if(irq){
    800028f2:	d8f1                	beqz	s1,800028c6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f4:	85a6                	mv	a1,s1
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	9e250513          	addi	a0,a0,-1566 # 800082d8 <states.0+0x30>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c92080e7          	jalr	-878(ra) # 80000590 <printf>
      plic_complete(irq);
    80002906:	8526                	mv	a0,s1
    80002908:	00003097          	auipc	ra,0x3
    8000290c:	534080e7          	jalr	1332(ra) # 80005e3c <plic_complete>
    return 1;
    80002910:	4505                	li	a0,1
    80002912:	bf55                	j	800028c6 <devintr+0x1e>
      uartintr();
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	0ae080e7          	jalr	174(ra) # 800009c2 <uartintr>
    8000291c:	b7ed                	j	80002906 <devintr+0x5e>
      virtio_disk_intr();
    8000291e:	00004097          	auipc	ra,0x4
    80002922:	992080e7          	jalr	-1646(ra) # 800062b0 <virtio_disk_intr>
    80002926:	b7c5                	j	80002906 <devintr+0x5e>
    if(cpuid() == 0){
    80002928:	fffff097          	auipc	ra,0xfffff
    8000292c:	0d2080e7          	jalr	210(ra) # 800019fa <cpuid>
    80002930:	c901                	beqz	a0,80002940 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002932:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002936:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002938:	14479073          	csrw	sip,a5
    return 2;
    8000293c:	4509                	li	a0,2
    8000293e:	b761                	j	800028c6 <devintr+0x1e>
      clockintr();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	f22080e7          	jalr	-222(ra) # 80002862 <clockintr>
    80002948:	b7ed                	j	80002932 <devintr+0x8a>

000000008000294a <usertrap>:
{
    8000294a:	1101                	addi	sp,sp,-32
    8000294c:	ec06                	sd	ra,24(sp)
    8000294e:	e822                	sd	s0,16(sp)
    80002950:	e426                	sd	s1,8(sp)
    80002952:	e04a                	sd	s2,0(sp)
    80002954:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002956:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000295a:	1007f793          	andi	a5,a5,256
    8000295e:	e3ad                	bnez	a5,800029c0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002960:	00003797          	auipc	a5,0x3
    80002964:	3b078793          	addi	a5,a5,944 # 80005d10 <kernelvec>
    80002968:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000296c:	fffff097          	auipc	ra,0xfffff
    80002970:	0ba080e7          	jalr	186(ra) # 80001a26 <myproc>
    80002974:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002976:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002978:	14102773          	csrr	a4,sepc
    8000297c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002982:	47a1                	li	a5,8
    80002984:	04f71c63          	bne	a4,a5,800029dc <usertrap+0x92>
    if(p->killed)
    80002988:	591c                	lw	a5,48(a0)
    8000298a:	e3b9                	bnez	a5,800029d0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000298c:	6cb8                	ld	a4,88(s1)
    8000298e:	6f1c                	ld	a5,24(a4)
    80002990:	0791                	addi	a5,a5,4
    80002992:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002998:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299c:	10079073          	csrw	sstatus,a5
    syscall();
    800029a0:	00000097          	auipc	ra,0x0
    800029a4:	2e0080e7          	jalr	736(ra) # 80002c80 <syscall>
  if(p->killed)
    800029a8:	589c                	lw	a5,48(s1)
    800029aa:	ebc1                	bnez	a5,80002a3a <usertrap+0xf0>
  usertrapret();
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	e18080e7          	jalr	-488(ra) # 800027c4 <usertrapret>
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6902                	ld	s2,0(sp)
    800029bc:	6105                	addi	sp,sp,32
    800029be:	8082                	ret
    panic("usertrap: not from user mode");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	93850513          	addi	a0,a0,-1736 # 800082f8 <states.0+0x50>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	b7e080e7          	jalr	-1154(ra) # 80000546 <panic>
      exit(-1);
    800029d0:	557d                	li	a0,-1
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	72a080e7          	jalr	1834(ra) # 800020fc <exit>
    800029da:	bf4d                	j	8000298c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	ecc080e7          	jalr	-308(ra) # 800028a8 <devintr>
    800029e4:	892a                	mv	s2,a0
    800029e6:	c501                	beqz	a0,800029ee <usertrap+0xa4>
  if(p->killed)
    800029e8:	589c                	lw	a5,48(s1)
    800029ea:	c3a1                	beqz	a5,80002a2a <usertrap+0xe0>
    800029ec:	a815                	j	80002a20 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ee:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029f2:	5c90                	lw	a2,56(s1)
    800029f4:	00006517          	auipc	a0,0x6
    800029f8:	92450513          	addi	a0,a0,-1756 # 80008318 <states.0+0x70>
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	b94080e7          	jalr	-1132(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a04:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a08:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	93c50513          	addi	a0,a0,-1732 # 80008348 <states.0+0xa0>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b7c080e7          	jalr	-1156(ra) # 80000590 <printf>
    p->killed = 1;
    80002a1c:	4785                	li	a5,1
    80002a1e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a20:	557d                	li	a0,-1
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	6da080e7          	jalr	1754(ra) # 800020fc <exit>
  if(which_dev == 2)
    80002a2a:	4789                	li	a5,2
    80002a2c:	f8f910e3          	bne	s2,a5,800029ac <usertrap+0x62>
    yield();
    80002a30:	fffff097          	auipc	ra,0xfffff
    80002a34:	7d6080e7          	jalr	2006(ra) # 80002206 <yield>
    80002a38:	bf95                	j	800029ac <usertrap+0x62>
  int which_dev = 0;
    80002a3a:	4901                	li	s2,0
    80002a3c:	b7d5                	j	80002a20 <usertrap+0xd6>

0000000080002a3e <kerneltrap>:
{
    80002a3e:	7179                	addi	sp,sp,-48
    80002a40:	f406                	sd	ra,40(sp)
    80002a42:	f022                	sd	s0,32(sp)
    80002a44:	ec26                	sd	s1,24(sp)
    80002a46:	e84a                	sd	s2,16(sp)
    80002a48:	e44e                	sd	s3,8(sp)
    80002a4a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a4c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a50:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a54:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a58:	1004f793          	andi	a5,s1,256
    80002a5c:	cb85                	beqz	a5,80002a8c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a62:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a64:	ef85                	bnez	a5,80002a9c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a66:	00000097          	auipc	ra,0x0
    80002a6a:	e42080e7          	jalr	-446(ra) # 800028a8 <devintr>
    80002a6e:	cd1d                	beqz	a0,80002aac <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a70:	4789                	li	a5,2
    80002a72:	06f50a63          	beq	a0,a5,80002ae6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a76:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a7a:	10049073          	csrw	sstatus,s1
}
    80002a7e:	70a2                	ld	ra,40(sp)
    80002a80:	7402                	ld	s0,32(sp)
    80002a82:	64e2                	ld	s1,24(sp)
    80002a84:	6942                	ld	s2,16(sp)
    80002a86:	69a2                	ld	s3,8(sp)
    80002a88:	6145                	addi	sp,sp,48
    80002a8a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	8dc50513          	addi	a0,a0,-1828 # 80008368 <states.0+0xc0>
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	ab2080e7          	jalr	-1358(ra) # 80000546 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	8f450513          	addi	a0,a0,-1804 # 80008390 <states.0+0xe8>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	aa2080e7          	jalr	-1374(ra) # 80000546 <panic>
    printf("scause %p\n", scause);
    80002aac:	85ce                	mv	a1,s3
    80002aae:	00006517          	auipc	a0,0x6
    80002ab2:	90250513          	addi	a0,a0,-1790 # 800083b0 <states.0+0x108>
    80002ab6:	ffffe097          	auipc	ra,0xffffe
    80002aba:	ada080e7          	jalr	-1318(ra) # 80000590 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002abe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ac2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	8fa50513          	addi	a0,a0,-1798 # 800083c0 <states.0+0x118>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	ac2080e7          	jalr	-1342(ra) # 80000590 <printf>
    panic("kerneltrap");
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	90250513          	addi	a0,a0,-1790 # 800083d8 <states.0+0x130>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	a68080e7          	jalr	-1432(ra) # 80000546 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	f40080e7          	jalr	-192(ra) # 80001a26 <myproc>
    80002aee:	d541                	beqz	a0,80002a76 <kerneltrap+0x38>
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	f36080e7          	jalr	-202(ra) # 80001a26 <myproc>
    80002af8:	4d18                	lw	a4,24(a0)
    80002afa:	478d                	li	a5,3
    80002afc:	f6f71de3          	bne	a4,a5,80002a76 <kerneltrap+0x38>
    yield();
    80002b00:	fffff097          	auipc	ra,0xfffff
    80002b04:	706080e7          	jalr	1798(ra) # 80002206 <yield>
    80002b08:	b7bd                	j	80002a76 <kerneltrap+0x38>

0000000080002b0a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b0a:	1101                	addi	sp,sp,-32
    80002b0c:	ec06                	sd	ra,24(sp)
    80002b0e:	e822                	sd	s0,16(sp)
    80002b10:	e426                	sd	s1,8(sp)
    80002b12:	1000                	addi	s0,sp,32
    80002b14:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b16:	fffff097          	auipc	ra,0xfffff
    80002b1a:	f10080e7          	jalr	-240(ra) # 80001a26 <myproc>
  switch (n) {
    80002b1e:	4795                	li	a5,5
    80002b20:	0497e163          	bltu	a5,s1,80002b62 <argraw+0x58>
    80002b24:	048a                	slli	s1,s1,0x2
    80002b26:	00006717          	auipc	a4,0x6
    80002b2a:	9aa70713          	addi	a4,a4,-1622 # 800084d0 <states.0+0x228>
    80002b2e:	94ba                	add	s1,s1,a4
    80002b30:	409c                	lw	a5,0(s1)
    80002b32:	97ba                	add	a5,a5,a4
    80002b34:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b36:	6d3c                	ld	a5,88(a0)
    80002b38:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b3a:	60e2                	ld	ra,24(sp)
    80002b3c:	6442                	ld	s0,16(sp)
    80002b3e:	64a2                	ld	s1,8(sp)
    80002b40:	6105                	addi	sp,sp,32
    80002b42:	8082                	ret
    return p->trapframe->a1;
    80002b44:	6d3c                	ld	a5,88(a0)
    80002b46:	7fa8                	ld	a0,120(a5)
    80002b48:	bfcd                	j	80002b3a <argraw+0x30>
    return p->trapframe->a2;
    80002b4a:	6d3c                	ld	a5,88(a0)
    80002b4c:	63c8                	ld	a0,128(a5)
    80002b4e:	b7f5                	j	80002b3a <argraw+0x30>
    return p->trapframe->a3;
    80002b50:	6d3c                	ld	a5,88(a0)
    80002b52:	67c8                	ld	a0,136(a5)
    80002b54:	b7dd                	j	80002b3a <argraw+0x30>
    return p->trapframe->a4;
    80002b56:	6d3c                	ld	a5,88(a0)
    80002b58:	6bc8                	ld	a0,144(a5)
    80002b5a:	b7c5                	j	80002b3a <argraw+0x30>
    return p->trapframe->a5;
    80002b5c:	6d3c                	ld	a5,88(a0)
    80002b5e:	6fc8                	ld	a0,152(a5)
    80002b60:	bfe9                	j	80002b3a <argraw+0x30>
  panic("argraw");
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	88650513          	addi	a0,a0,-1914 # 800083e8 <states.0+0x140>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	9dc080e7          	jalr	-1572(ra) # 80000546 <panic>

0000000080002b72 <fetchaddr>:
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	e04a                	sd	s2,0(sp)
    80002b7c:	1000                	addi	s0,sp,32
    80002b7e:	84aa                	mv	s1,a0
    80002b80:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	ea4080e7          	jalr	-348(ra) # 80001a26 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b8a:	653c                	ld	a5,72(a0)
    80002b8c:	02f4f863          	bgeu	s1,a5,80002bbc <fetchaddr+0x4a>
    80002b90:	00848713          	addi	a4,s1,8
    80002b94:	02e7e663          	bltu	a5,a4,80002bc0 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b98:	46a1                	li	a3,8
    80002b9a:	8626                	mv	a2,s1
    80002b9c:	85ca                	mv	a1,s2
    80002b9e:	6928                	ld	a0,80(a0)
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	c08080e7          	jalr	-1016(ra) # 800017a8 <copyin>
    80002ba8:	00a03533          	snez	a0,a0
    80002bac:	40a00533          	neg	a0,a0
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6902                	ld	s2,0(sp)
    80002bb8:	6105                	addi	sp,sp,32
    80002bba:	8082                	ret
    return -1;
    80002bbc:	557d                	li	a0,-1
    80002bbe:	bfcd                	j	80002bb0 <fetchaddr+0x3e>
    80002bc0:	557d                	li	a0,-1
    80002bc2:	b7fd                	j	80002bb0 <fetchaddr+0x3e>

0000000080002bc4 <fetchstr>:
{
    80002bc4:	7179                	addi	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	e84a                	sd	s2,16(sp)
    80002bce:	e44e                	sd	s3,8(sp)
    80002bd0:	1800                	addi	s0,sp,48
    80002bd2:	892a                	mv	s2,a0
    80002bd4:	84ae                	mv	s1,a1
    80002bd6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bd8:	fffff097          	auipc	ra,0xfffff
    80002bdc:	e4e080e7          	jalr	-434(ra) # 80001a26 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002be0:	86ce                	mv	a3,s3
    80002be2:	864a                	mv	a2,s2
    80002be4:	85a6                	mv	a1,s1
    80002be6:	6928                	ld	a0,80(a0)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	c4e080e7          	jalr	-946(ra) # 80001836 <copyinstr>
  if(err < 0)
    80002bf0:	00054763          	bltz	a0,80002bfe <fetchstr+0x3a>
  return strlen(buf);
    80002bf4:	8526                	mv	a0,s1
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	2e4080e7          	jalr	740(ra) # 80000eda <strlen>
}
    80002bfe:	70a2                	ld	ra,40(sp)
    80002c00:	7402                	ld	s0,32(sp)
    80002c02:	64e2                	ld	s1,24(sp)
    80002c04:	6942                	ld	s2,16(sp)
    80002c06:	69a2                	ld	s3,8(sp)
    80002c08:	6145                	addi	sp,sp,48
    80002c0a:	8082                	ret

0000000080002c0c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c0c:	1101                	addi	sp,sp,-32
    80002c0e:	ec06                	sd	ra,24(sp)
    80002c10:	e822                	sd	s0,16(sp)
    80002c12:	e426                	sd	s1,8(sp)
    80002c14:	1000                	addi	s0,sp,32
    80002c16:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	ef2080e7          	jalr	-270(ra) # 80002b0a <argraw>
    80002c20:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c22:	4501                	li	a0,0
    80002c24:	60e2                	ld	ra,24(sp)
    80002c26:	6442                	ld	s0,16(sp)
    80002c28:	64a2                	ld	s1,8(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	e426                	sd	s1,8(sp)
    80002c36:	1000                	addi	s0,sp,32
    80002c38:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	ed0080e7          	jalr	-304(ra) # 80002b0a <argraw>
    80002c42:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c44:	4501                	li	a0,0
    80002c46:	60e2                	ld	ra,24(sp)
    80002c48:	6442                	ld	s0,16(sp)
    80002c4a:	64a2                	ld	s1,8(sp)
    80002c4c:	6105                	addi	sp,sp,32
    80002c4e:	8082                	ret

0000000080002c50 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	e04a                	sd	s2,0(sp)
    80002c5a:	1000                	addi	s0,sp,32
    80002c5c:	84ae                	mv	s1,a1
    80002c5e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	eaa080e7          	jalr	-342(ra) # 80002b0a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c68:	864a                	mv	a2,s2
    80002c6a:	85a6                	mv	a1,s1
    80002c6c:	00000097          	auipc	ra,0x0
    80002c70:	f58080e7          	jalr	-168(ra) # 80002bc4 <fetchstr>
}
    80002c74:	60e2                	ld	ra,24(sp)
    80002c76:	6442                	ld	s0,16(sp)
    80002c78:	64a2                	ld	s1,8(sp)
    80002c7a:	6902                	ld	s2,0(sp)
    80002c7c:	6105                	addi	sp,sp,32
    80002c7e:	8082                	ret

0000000080002c80 <syscall>:
char* syscall_names[24] = {"", "fork", "exit", "wait", "pipe", "read", "kill", "exec",
                      "fstat", "chdir", "dup", "getpid", "sbrk", "sleep", "uptime",
                      "open", "write", "mknod", "unlink", "link", "mkdir", "close", "trace"};
void
syscall(void)
{
    80002c80:	7139                	addi	sp,sp,-64
    80002c82:	fc06                	sd	ra,56(sp)
    80002c84:	f822                	sd	s0,48(sp)
    80002c86:	f426                	sd	s1,40(sp)
    80002c88:	f04a                	sd	s2,32(sp)
    80002c8a:	ec4e                	sd	s3,24(sp)
    80002c8c:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c8e:	fffff097          	auipc	ra,0xfffff
    80002c92:	d98080e7          	jalr	-616(ra) # 80001a26 <myproc>
    80002c96:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c98:	6d3c                	ld	a5,88(a0)
    80002c9a:	0a87b903          	ld	s2,168(a5)
    80002c9e:	0009099b          	sext.w	s3,s2
  int fstarg;
  argint(0,&fstarg);//get first arg
    80002ca2:	fcc40593          	addi	a1,s0,-52
    80002ca6:	4501                	li	a0,0
    80002ca8:	00000097          	auipc	ra,0x0
    80002cac:	f64080e7          	jalr	-156(ra) # 80002c0c <argint>
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cb0:	397d                	addiw	s2,s2,-1
    80002cb2:	47d9                	li	a5,22
    80002cb4:	0527ed63          	bltu	a5,s2,80002d0e <syscall+0x8e>
    80002cb8:	00399713          	slli	a4,s3,0x3
    80002cbc:	00006797          	auipc	a5,0x6
    80002cc0:	82c78793          	addi	a5,a5,-2004 # 800084e8 <syscalls>
    80002cc4:	97ba                	add	a5,a5,a4
    80002cc6:	639c                	ld	a5,0(a5)
    80002cc8:	c3b9                	beqz	a5,80002d0e <syscall+0x8e>
    p->trapframe->a0 = syscalls[num]();
    80002cca:	0584b903          	ld	s2,88(s1)
    80002cce:	9782                	jalr	a5
    80002cd0:	06a93823          	sd	a0,112(s2)
      if(p->mask&(1<<num)&&p->mask > 0){
    80002cd4:	1684a703          	lw	a4,360(s1)
    80002cd8:	413757bb          	sraw	a5,a4,s3
    80002cdc:	8b85                	andi	a5,a5,1
    80002cde:	c7b9                	beqz	a5,80002d2c <syscall+0xac>
    80002ce0:	04e05663          	blez	a4,80002d2c <syscall+0xac>
      // printf("%d:sys_%s(%d)->%d\n",p->pid, p->name, p->trapframe->a0, p->trapframe->ra);
      printf("%d: sys_%s(%d) -> %d\n",p->pid, syscall_names[num], fstarg, p->trapframe->a0);
    80002ce4:	6cb8                	ld	a4,88(s1)
    80002ce6:	098e                	slli	s3,s3,0x3
    80002ce8:	00006797          	auipc	a5,0x6
    80002cec:	c4078793          	addi	a5,a5,-960 # 80008928 <syscall_names>
    80002cf0:	97ce                	add	a5,a5,s3
    80002cf2:	7b38                	ld	a4,112(a4)
    80002cf4:	fcc42683          	lw	a3,-52(s0)
    80002cf8:	6390                	ld	a2,0(a5)
    80002cfa:	5c8c                	lw	a1,56(s1)
    80002cfc:	00005517          	auipc	a0,0x5
    80002d00:	6f450513          	addi	a0,a0,1780 # 800083f0 <states.0+0x148>
    80002d04:	ffffe097          	auipc	ra,0xffffe
    80002d08:	88c080e7          	jalr	-1908(ra) # 80000590 <printf>
    80002d0c:	a005                	j	80002d2c <syscall+0xac>
  }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d0e:	86ce                	mv	a3,s3
    80002d10:	15848613          	addi	a2,s1,344
    80002d14:	5c8c                	lw	a1,56(s1)
    80002d16:	00005517          	auipc	a0,0x5
    80002d1a:	6f250513          	addi	a0,a0,1778 # 80008408 <states.0+0x160>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	872080e7          	jalr	-1934(ra) # 80000590 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d26:	6cbc                	ld	a5,88(s1)
    80002d28:	577d                	li	a4,-1
    80002d2a:	fbb8                	sd	a4,112(a5)
  }


}
    80002d2c:	70e2                	ld	ra,56(sp)
    80002d2e:	7442                	ld	s0,48(sp)
    80002d30:	74a2                	ld	s1,40(sp)
    80002d32:	7902                	ld	s2,32(sp)
    80002d34:	69e2                	ld	s3,24(sp)
    80002d36:	6121                	addi	sp,sp,64
    80002d38:	8082                	ret

0000000080002d3a <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002d3a:	1101                	addi	sp,sp,-32
    80002d3c:	ec06                	sd	ra,24(sp)
    80002d3e:	e822                	sd	s0,16(sp)
    80002d40:	1000                	addi	s0,sp,32
  int n;
  if (argint(0, &n) < 0)
    80002d42:	fec40593          	addi	a1,s0,-20
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	ec4080e7          	jalr	-316(ra) # 80002c0c <argint>
    return -1;
    80002d50:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002d52:	00054963          	bltz	a0,80002d64 <sys_exit+0x2a>
  exit(n);
    80002d56:	fec42503          	lw	a0,-20(s0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	3a2080e7          	jalr	930(ra) # 800020fc <exit>
  return 0; // not reached
    80002d62:	4781                	li	a5,0
}
    80002d64:	853e                	mv	a0,a5
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6e:	1141                	addi	sp,sp,-16
    80002d70:	e406                	sd	ra,8(sp)
    80002d72:	e022                	sd	s0,0(sp)
    80002d74:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	cb0080e7          	jalr	-848(ra) # 80001a26 <myproc>
}
    80002d7e:	5d08                	lw	a0,56(a0)
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_fork>:

uint64
sys_fork(void)
{
    80002d88:	1141                	addi	sp,sp,-16
    80002d8a:	e406                	sd	ra,8(sp)
    80002d8c:	e022                	sd	s0,0(sp)
    80002d8e:	0800                	addi	s0,sp,16
  return fork();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	05a080e7          	jalr	90(ra) # 80001dea <fork>
}
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_wait>:

uint64
sys_wait(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  uint64 p;
  if (argaddr(0, &p) < 0)
    80002da8:	fe840593          	addi	a1,s0,-24
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e80080e7          	jalr	-384(ra) # 80002c2e <argaddr>
    80002db6:	87aa                	mv	a5,a0
    return -1;
    80002db8:	557d                	li	a0,-1
  if (argaddr(0, &p) < 0)
    80002dba:	0007c863          	bltz	a5,80002dca <sys_wait+0x2a>
  return wait(p);
    80002dbe:	fe843503          	ld	a0,-24(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	4fe080e7          	jalr	1278(ra) # 800022c0 <wait>
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dd2:	7179                	addi	sp,sp,-48
    80002dd4:	f406                	sd	ra,40(sp)
    80002dd6:	f022                	sd	s0,32(sp)
    80002dd8:	ec26                	sd	s1,24(sp)
    80002dda:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if (argint(0, &n) < 0)
    80002ddc:	fdc40593          	addi	a1,s0,-36
    80002de0:	4501                	li	a0,0
    80002de2:	00000097          	auipc	ra,0x0
    80002de6:	e2a080e7          	jalr	-470(ra) # 80002c0c <argint>
    80002dea:	87aa                	mv	a5,a0
    return -1;
    80002dec:	557d                	li	a0,-1
  if (argint(0, &n) < 0)
    80002dee:	0207c063          	bltz	a5,80002e0e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	c34080e7          	jalr	-972(ra) # 80001a26 <myproc>
    80002dfa:	4524                	lw	s1,72(a0)
  if (growproc(n) < 0)
    80002dfc:	fdc42503          	lw	a0,-36(s0)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	f72080e7          	jalr	-142(ra) # 80001d72 <growproc>
    80002e08:	00054863          	bltz	a0,80002e18 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e0c:	8526                	mv	a0,s1
}
    80002e0e:	70a2                	ld	ra,40(sp)
    80002e10:	7402                	ld	s0,32(sp)
    80002e12:	64e2                	ld	s1,24(sp)
    80002e14:	6145                	addi	sp,sp,48
    80002e16:	8082                	ret
    return -1;
    80002e18:	557d                	li	a0,-1
    80002e1a:	bfd5                	j	80002e0e <sys_sbrk+0x3c>

0000000080002e1c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e1c:	7139                	addi	sp,sp,-64
    80002e1e:	fc06                	sd	ra,56(sp)
    80002e20:	f822                	sd	s0,48(sp)
    80002e22:	f426                	sd	s1,40(sp)
    80002e24:	f04a                	sd	s2,32(sp)
    80002e26:	ec4e                	sd	s3,24(sp)
    80002e28:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if (argint(0, &n) < 0)
    80002e2a:	fcc40593          	addi	a1,s0,-52
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	ddc080e7          	jalr	-548(ra) # 80002c0c <argint>
    return -1;
    80002e38:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002e3a:	06054563          	bltz	a0,80002ea4 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e3e:	00015517          	auipc	a0,0x15
    80002e42:	b2a50513          	addi	a0,a0,-1238 # 80017968 <tickslock>
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	e14080e7          	jalr	-492(ra) # 80000c5a <acquire>
  ticks0 = ticks;
    80002e4e:	00006917          	auipc	s2,0x6
    80002e52:	1d292903          	lw	s2,466(s2) # 80009020 <ticks>
  while (ticks - ticks0 < n)
    80002e56:	fcc42783          	lw	a5,-52(s0)
    80002e5a:	cf85                	beqz	a5,80002e92 <sys_sleep+0x76>
    if (myproc()->killed)
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e5c:	00015997          	auipc	s3,0x15
    80002e60:	b0c98993          	addi	s3,s3,-1268 # 80017968 <tickslock>
    80002e64:	00006497          	auipc	s1,0x6
    80002e68:	1bc48493          	addi	s1,s1,444 # 80009020 <ticks>
    if (myproc()->killed)
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	bba080e7          	jalr	-1094(ra) # 80001a26 <myproc>
    80002e74:	591c                	lw	a5,48(a0)
    80002e76:	ef9d                	bnez	a5,80002eb4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e78:	85ce                	mv	a1,s3
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	3c6080e7          	jalr	966(ra) # 80002242 <sleep>
  while (ticks - ticks0 < n)
    80002e84:	409c                	lw	a5,0(s1)
    80002e86:	412787bb          	subw	a5,a5,s2
    80002e8a:	fcc42703          	lw	a4,-52(s0)
    80002e8e:	fce7efe3          	bltu	a5,a4,80002e6c <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e92:	00015517          	auipc	a0,0x15
    80002e96:	ad650513          	addi	a0,a0,-1322 # 80017968 <tickslock>
    80002e9a:	ffffe097          	auipc	ra,0xffffe
    80002e9e:	e74080e7          	jalr	-396(ra) # 80000d0e <release>
  return 0;
    80002ea2:	4781                	li	a5,0
}
    80002ea4:	853e                	mv	a0,a5
    80002ea6:	70e2                	ld	ra,56(sp)
    80002ea8:	7442                	ld	s0,48(sp)
    80002eaa:	74a2                	ld	s1,40(sp)
    80002eac:	7902                	ld	s2,32(sp)
    80002eae:	69e2                	ld	s3,24(sp)
    80002eb0:	6121                	addi	sp,sp,64
    80002eb2:	8082                	ret
      release(&tickslock);
    80002eb4:	00015517          	auipc	a0,0x15
    80002eb8:	ab450513          	addi	a0,a0,-1356 # 80017968 <tickslock>
    80002ebc:	ffffe097          	auipc	ra,0xffffe
    80002ec0:	e52080e7          	jalr	-430(ra) # 80000d0e <release>
      return -1;
    80002ec4:	57fd                	li	a5,-1
    80002ec6:	bff9                	j	80002ea4 <sys_sleep+0x88>

0000000080002ec8 <sys_kill>:

uint64
sys_kill(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	1000                	addi	s0,sp,32
  int pid;

  if (argint(0, &pid) < 0)
    80002ed0:	fec40593          	addi	a1,s0,-20
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	d36080e7          	jalr	-714(ra) # 80002c0c <argint>
    80002ede:	87aa                	mv	a5,a0
    return -1;
    80002ee0:	557d                	li	a0,-1
  if (argint(0, &pid) < 0)
    80002ee2:	0007c863          	bltz	a5,80002ef2 <sys_kill+0x2a>
  return kill(pid);
    80002ee6:	fec42503          	lw	a0,-20(s0)
    80002eea:	fffff097          	auipc	ra,0xfffff
    80002eee:	542080e7          	jalr	1346(ra) # 8000242c <kill>
}
    80002ef2:	60e2                	ld	ra,24(sp)
    80002ef4:	6442                	ld	s0,16(sp)
    80002ef6:	6105                	addi	sp,sp,32
    80002ef8:	8082                	ret

0000000080002efa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	e426                	sd	s1,8(sp)
    80002f02:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f04:	00015517          	auipc	a0,0x15
    80002f08:	a6450513          	addi	a0,a0,-1436 # 80017968 <tickslock>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	d4e080e7          	jalr	-690(ra) # 80000c5a <acquire>
  xticks = ticks;
    80002f14:	00006497          	auipc	s1,0x6
    80002f18:	10c4a483          	lw	s1,268(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f1c:	00015517          	auipc	a0,0x15
    80002f20:	a4c50513          	addi	a0,a0,-1460 # 80017968 <tickslock>
    80002f24:	ffffe097          	auipc	ra,0xffffe
    80002f28:	dea080e7          	jalr	-534(ra) # 80000d0e <release>
  return xticks;
}
    80002f2c:	02049513          	slli	a0,s1,0x20
    80002f30:	9101                	srli	a0,a0,0x20
    80002f32:	60e2                	ld	ra,24(sp)
    80002f34:	6442                	ld	s0,16(sp)
    80002f36:	64a2                	ld	s1,8(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <sys_trace>:

uint64
sys_trace(void)
{ 
    80002f3c:	1101                	addi	sp,sp,-32
    80002f3e:	ec06                	sd	ra,24(sp)
    80002f40:	e822                	sd	s0,16(sp)
    80002f42:	1000                	addi	s0,sp,32
  int mask;
  if(argint(0, &mask) < 0)
    80002f44:	fec40593          	addi	a1,s0,-20
    80002f48:	4501                	li	a0,0
    80002f4a:	00000097          	auipc	ra,0x0
    80002f4e:	cc2080e7          	jalr	-830(ra) # 80002c0c <argint>
    80002f52:	87aa                	mv	a5,a0
    return -1;
    80002f54:	557d                	li	a0,-1
  if(argint(0, &mask) < 0)
    80002f56:	0007c863          	bltz	a5,80002f66 <sys_trace+0x2a>
  return trace(mask);
    80002f5a:	fec42503          	lw	a0,-20(s0)
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	53e080e7          	jalr	1342(ra) # 8000249c <trace>
}
    80002f66:	60e2                	ld	ra,24(sp)
    80002f68:	6442                	ld	s0,16(sp)
    80002f6a:	6105                	addi	sp,sp,32
    80002f6c:	8082                	ret

0000000080002f6e <sys_sysinfo>:
uint64
sys_sysinfo(void){
    80002f6e:	7179                	addi	sp,sp,-48
    80002f70:	f406                	sd	ra,40(sp)
    80002f72:	f022                	sd	s0,32(sp)
    80002f74:	1800                	addi	s0,sp,48

  struct sysinfo info;
  // info.freefd=0;
  // info.freemem=0;
  // info.nproc=0;
  return sysinfo(&info);
    80002f76:	fd840513          	addi	a0,s0,-40
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	72a080e7          	jalr	1834(ra) # 800026a4 <sysinfo>

}
    80002f82:	70a2                	ld	ra,40(sp)
    80002f84:	7402                	ld	s0,32(sp)
    80002f86:	6145                	addi	sp,sp,48
    80002f88:	8082                	ret

0000000080002f8a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f8a:	7179                	addi	sp,sp,-48
    80002f8c:	f406                	sd	ra,40(sp)
    80002f8e:	f022                	sd	s0,32(sp)
    80002f90:	ec26                	sd	s1,24(sp)
    80002f92:	e84a                	sd	s2,16(sp)
    80002f94:	e44e                	sd	s3,8(sp)
    80002f96:	e052                	sd	s4,0(sp)
    80002f98:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f9a:	00005597          	auipc	a1,0x5
    80002f9e:	60e58593          	addi	a1,a1,1550 # 800085a8 <syscalls+0xc0>
    80002fa2:	00015517          	auipc	a0,0x15
    80002fa6:	9de50513          	addi	a0,a0,-1570 # 80017980 <bcache>
    80002faa:	ffffe097          	auipc	ra,0xffffe
    80002fae:	c20080e7          	jalr	-992(ra) # 80000bca <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fb2:	0001d797          	auipc	a5,0x1d
    80002fb6:	9ce78793          	addi	a5,a5,-1586 # 8001f980 <bcache+0x8000>
    80002fba:	0001d717          	auipc	a4,0x1d
    80002fbe:	c2e70713          	addi	a4,a4,-978 # 8001fbe8 <bcache+0x8268>
    80002fc2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fc6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fca:	00015497          	auipc	s1,0x15
    80002fce:	9ce48493          	addi	s1,s1,-1586 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002fd2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fd4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fd6:	00005a17          	auipc	s4,0x5
    80002fda:	5daa0a13          	addi	s4,s4,1498 # 800085b0 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fde:	2b893783          	ld	a5,696(s2)
    80002fe2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fe4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fe8:	85d2                	mv	a1,s4
    80002fea:	01048513          	addi	a0,s1,16
    80002fee:	00001097          	auipc	ra,0x1
    80002ff2:	4b2080e7          	jalr	1202(ra) # 800044a0 <initsleeplock>
    bcache.head.next->prev = b;
    80002ff6:	2b893783          	ld	a5,696(s2)
    80002ffa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ffc:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003000:	45848493          	addi	s1,s1,1112
    80003004:	fd349de3          	bne	s1,s3,80002fde <binit+0x54>
  }
}
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6a02                	ld	s4,0(sp)
    80003014:	6145                	addi	sp,sp,48
    80003016:	8082                	ret

0000000080003018 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003018:	7179                	addi	sp,sp,-48
    8000301a:	f406                	sd	ra,40(sp)
    8000301c:	f022                	sd	s0,32(sp)
    8000301e:	ec26                	sd	s1,24(sp)
    80003020:	e84a                	sd	s2,16(sp)
    80003022:	e44e                	sd	s3,8(sp)
    80003024:	1800                	addi	s0,sp,48
    80003026:	892a                	mv	s2,a0
    80003028:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000302a:	00015517          	auipc	a0,0x15
    8000302e:	95650513          	addi	a0,a0,-1706 # 80017980 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c28080e7          	jalr	-984(ra) # 80000c5a <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000303a:	0001d497          	auipc	s1,0x1d
    8000303e:	bfe4b483          	ld	s1,-1026(s1) # 8001fc38 <bcache+0x82b8>
    80003042:	0001d797          	auipc	a5,0x1d
    80003046:	ba678793          	addi	a5,a5,-1114 # 8001fbe8 <bcache+0x8268>
    8000304a:	02f48f63          	beq	s1,a5,80003088 <bread+0x70>
    8000304e:	873e                	mv	a4,a5
    80003050:	a021                	j	80003058 <bread+0x40>
    80003052:	68a4                	ld	s1,80(s1)
    80003054:	02e48a63          	beq	s1,a4,80003088 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003058:	449c                	lw	a5,8(s1)
    8000305a:	ff279ce3          	bne	a5,s2,80003052 <bread+0x3a>
    8000305e:	44dc                	lw	a5,12(s1)
    80003060:	ff3799e3          	bne	a5,s3,80003052 <bread+0x3a>
      b->refcnt++;
    80003064:	40bc                	lw	a5,64(s1)
    80003066:	2785                	addiw	a5,a5,1
    80003068:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306a:	00015517          	auipc	a0,0x15
    8000306e:	91650513          	addi	a0,a0,-1770 # 80017980 <bcache>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c9c080e7          	jalr	-868(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    8000307a:	01048513          	addi	a0,s1,16
    8000307e:	00001097          	auipc	ra,0x1
    80003082:	45c080e7          	jalr	1116(ra) # 800044da <acquiresleep>
      return b;
    80003086:	a8b9                	j	800030e4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003088:	0001d497          	auipc	s1,0x1d
    8000308c:	ba84b483          	ld	s1,-1112(s1) # 8001fc30 <bcache+0x82b0>
    80003090:	0001d797          	auipc	a5,0x1d
    80003094:	b5878793          	addi	a5,a5,-1192 # 8001fbe8 <bcache+0x8268>
    80003098:	00f48863          	beq	s1,a5,800030a8 <bread+0x90>
    8000309c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000309e:	40bc                	lw	a5,64(s1)
    800030a0:	cf81                	beqz	a5,800030b8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a2:	64a4                	ld	s1,72(s1)
    800030a4:	fee49de3          	bne	s1,a4,8000309e <bread+0x86>
  panic("bget: no buffers");
    800030a8:	00005517          	auipc	a0,0x5
    800030ac:	51050513          	addi	a0,a0,1296 # 800085b8 <syscalls+0xd0>
    800030b0:	ffffd097          	auipc	ra,0xffffd
    800030b4:	496080e7          	jalr	1174(ra) # 80000546 <panic>
      b->dev = dev;
    800030b8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030bc:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030c0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030c4:	4785                	li	a5,1
    800030c6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c8:	00015517          	auipc	a0,0x15
    800030cc:	8b850513          	addi	a0,a0,-1864 # 80017980 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	c3e080e7          	jalr	-962(ra) # 80000d0e <release>
      acquiresleep(&b->lock);
    800030d8:	01048513          	addi	a0,s1,16
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	3fe080e7          	jalr	1022(ra) # 800044da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e4:	409c                	lw	a5,0(s1)
    800030e6:	cb89                	beqz	a5,800030f8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e8:	8526                	mv	a0,s1
    800030ea:	70a2                	ld	ra,40(sp)
    800030ec:	7402                	ld	s0,32(sp)
    800030ee:	64e2                	ld	s1,24(sp)
    800030f0:	6942                	ld	s2,16(sp)
    800030f2:	69a2                	ld	s3,8(sp)
    800030f4:	6145                	addi	sp,sp,48
    800030f6:	8082                	ret
    virtio_disk_rw(b, 0);
    800030f8:	4581                	li	a1,0
    800030fa:	8526                	mv	a0,s1
    800030fc:	00003097          	auipc	ra,0x3
    80003100:	f2c080e7          	jalr	-212(ra) # 80006028 <virtio_disk_rw>
    b->valid = 1;
    80003104:	4785                	li	a5,1
    80003106:	c09c                	sw	a5,0(s1)
  return b;
    80003108:	b7c5                	j	800030e8 <bread+0xd0>

000000008000310a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	e426                	sd	s1,8(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003116:	0541                	addi	a0,a0,16
    80003118:	00001097          	auipc	ra,0x1
    8000311c:	45c080e7          	jalr	1116(ra) # 80004574 <holdingsleep>
    80003120:	cd01                	beqz	a0,80003138 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003122:	4585                	li	a1,1
    80003124:	8526                	mv	a0,s1
    80003126:	00003097          	auipc	ra,0x3
    8000312a:	f02080e7          	jalr	-254(ra) # 80006028 <virtio_disk_rw>
}
    8000312e:	60e2                	ld	ra,24(sp)
    80003130:	6442                	ld	s0,16(sp)
    80003132:	64a2                	ld	s1,8(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("bwrite");
    80003138:	00005517          	auipc	a0,0x5
    8000313c:	49850513          	addi	a0,a0,1176 # 800085d0 <syscalls+0xe8>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	406080e7          	jalr	1030(ra) # 80000546 <panic>

0000000080003148 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	e04a                	sd	s2,0(sp)
    80003152:	1000                	addi	s0,sp,32
    80003154:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003156:	01050913          	addi	s2,a0,16
    8000315a:	854a                	mv	a0,s2
    8000315c:	00001097          	auipc	ra,0x1
    80003160:	418080e7          	jalr	1048(ra) # 80004574 <holdingsleep>
    80003164:	c92d                	beqz	a0,800031d6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003166:	854a                	mv	a0,s2
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	3c8080e7          	jalr	968(ra) # 80004530 <releasesleep>

  acquire(&bcache.lock);
    80003170:	00015517          	auipc	a0,0x15
    80003174:	81050513          	addi	a0,a0,-2032 # 80017980 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	ae2080e7          	jalr	-1310(ra) # 80000c5a <acquire>
  b->refcnt--;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	37fd                	addiw	a5,a5,-1
    80003184:	0007871b          	sext.w	a4,a5
    80003188:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000318a:	eb05                	bnez	a4,800031ba <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000318c:	68bc                	ld	a5,80(s1)
    8000318e:	64b8                	ld	a4,72(s1)
    80003190:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003192:	64bc                	ld	a5,72(s1)
    80003194:	68b8                	ld	a4,80(s1)
    80003196:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003198:	0001c797          	auipc	a5,0x1c
    8000319c:	7e878793          	addi	a5,a5,2024 # 8001f980 <bcache+0x8000>
    800031a0:	2b87b703          	ld	a4,696(a5)
    800031a4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031a6:	0001d717          	auipc	a4,0x1d
    800031aa:	a4270713          	addi	a4,a4,-1470 # 8001fbe8 <bcache+0x8268>
    800031ae:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031b0:	2b87b703          	ld	a4,696(a5)
    800031b4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031b6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ba:	00014517          	auipc	a0,0x14
    800031be:	7c650513          	addi	a0,a0,1990 # 80017980 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	b4c080e7          	jalr	-1204(ra) # 80000d0e <release>
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6902                	ld	s2,0(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret
    panic("brelse");
    800031d6:	00005517          	auipc	a0,0x5
    800031da:	40250513          	addi	a0,a0,1026 # 800085d8 <syscalls+0xf0>
    800031de:	ffffd097          	auipc	ra,0xffffd
    800031e2:	368080e7          	jalr	872(ra) # 80000546 <panic>

00000000800031e6 <bpin>:

void
bpin(struct buf *b) {
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	1000                	addi	s0,sp,32
    800031f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f2:	00014517          	auipc	a0,0x14
    800031f6:	78e50513          	addi	a0,a0,1934 # 80017980 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	a60080e7          	jalr	-1440(ra) # 80000c5a <acquire>
  b->refcnt++;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	2785                	addiw	a5,a5,1
    80003206:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003208:	00014517          	auipc	a0,0x14
    8000320c:	77850513          	addi	a0,a0,1912 # 80017980 <bcache>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	afe080e7          	jalr	-1282(ra) # 80000d0e <release>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <bunpin>:

void
bunpin(struct buf *b) {
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322e:	00014517          	auipc	a0,0x14
    80003232:	75250513          	addi	a0,a0,1874 # 80017980 <bcache>
    80003236:	ffffe097          	auipc	ra,0xffffe
    8000323a:	a24080e7          	jalr	-1500(ra) # 80000c5a <acquire>
  b->refcnt--;
    8000323e:	40bc                	lw	a5,64(s1)
    80003240:	37fd                	addiw	a5,a5,-1
    80003242:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003244:	00014517          	auipc	a0,0x14
    80003248:	73c50513          	addi	a0,a0,1852 # 80017980 <bcache>
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	ac2080e7          	jalr	-1342(ra) # 80000d0e <release>
}
    80003254:	60e2                	ld	ra,24(sp)
    80003256:	6442                	ld	s0,16(sp)
    80003258:	64a2                	ld	s1,8(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000325e:	1101                	addi	sp,sp,-32
    80003260:	ec06                	sd	ra,24(sp)
    80003262:	e822                	sd	s0,16(sp)
    80003264:	e426                	sd	s1,8(sp)
    80003266:	e04a                	sd	s2,0(sp)
    80003268:	1000                	addi	s0,sp,32
    8000326a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000326c:	00d5d59b          	srliw	a1,a1,0xd
    80003270:	0001d797          	auipc	a5,0x1d
    80003274:	dec7a783          	lw	a5,-532(a5) # 8002005c <sb+0x1c>
    80003278:	9dbd                	addw	a1,a1,a5
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	d9e080e7          	jalr	-610(ra) # 80003018 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003282:	0074f713          	andi	a4,s1,7
    80003286:	4785                	li	a5,1
    80003288:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000328c:	14ce                	slli	s1,s1,0x33
    8000328e:	90d9                	srli	s1,s1,0x36
    80003290:	00950733          	add	a4,a0,s1
    80003294:	05874703          	lbu	a4,88(a4)
    80003298:	00e7f6b3          	and	a3,a5,a4
    8000329c:	c69d                	beqz	a3,800032ca <bfree+0x6c>
    8000329e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032a0:	94aa                	add	s1,s1,a0
    800032a2:	fff7c793          	not	a5,a5
    800032a6:	8f7d                	and	a4,a4,a5
    800032a8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	108080e7          	jalr	264(ra) # 800043b4 <log_write>
  brelse(bp);
    800032b4:	854a                	mv	a0,s2
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	e92080e7          	jalr	-366(ra) # 80003148 <brelse>
}
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	64a2                	ld	s1,8(sp)
    800032c4:	6902                	ld	s2,0(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret
    panic("freeing free block");
    800032ca:	00005517          	auipc	a0,0x5
    800032ce:	31650513          	addi	a0,a0,790 # 800085e0 <syscalls+0xf8>
    800032d2:	ffffd097          	auipc	ra,0xffffd
    800032d6:	274080e7          	jalr	628(ra) # 80000546 <panic>

00000000800032da <balloc>:
{
    800032da:	711d                	addi	sp,sp,-96
    800032dc:	ec86                	sd	ra,88(sp)
    800032de:	e8a2                	sd	s0,80(sp)
    800032e0:	e4a6                	sd	s1,72(sp)
    800032e2:	e0ca                	sd	s2,64(sp)
    800032e4:	fc4e                	sd	s3,56(sp)
    800032e6:	f852                	sd	s4,48(sp)
    800032e8:	f456                	sd	s5,40(sp)
    800032ea:	f05a                	sd	s6,32(sp)
    800032ec:	ec5e                	sd	s7,24(sp)
    800032ee:	e862                	sd	s8,16(sp)
    800032f0:	e466                	sd	s9,8(sp)
    800032f2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032f4:	0001d797          	auipc	a5,0x1d
    800032f8:	d507a783          	lw	a5,-688(a5) # 80020044 <sb+0x4>
    800032fc:	cbc1                	beqz	a5,8000338c <balloc+0xb2>
    800032fe:	8baa                	mv	s7,a0
    80003300:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003302:	0001db17          	auipc	s6,0x1d
    80003306:	d3eb0b13          	addi	s6,s6,-706 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000330c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003310:	6c89                	lui	s9,0x2
    80003312:	a831                	j	8000332e <balloc+0x54>
    brelse(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	e32080e7          	jalr	-462(ra) # 80003148 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000331e:	015c87bb          	addw	a5,s9,s5
    80003322:	00078a9b          	sext.w	s5,a5
    80003326:	004b2703          	lw	a4,4(s6)
    8000332a:	06eaf163          	bgeu	s5,a4,8000338c <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000332e:	41fad79b          	sraiw	a5,s5,0x1f
    80003332:	0137d79b          	srliw	a5,a5,0x13
    80003336:	015787bb          	addw	a5,a5,s5
    8000333a:	40d7d79b          	sraiw	a5,a5,0xd
    8000333e:	01cb2583          	lw	a1,28(s6)
    80003342:	9dbd                	addw	a1,a1,a5
    80003344:	855e                	mv	a0,s7
    80003346:	00000097          	auipc	ra,0x0
    8000334a:	cd2080e7          	jalr	-814(ra) # 80003018 <bread>
    8000334e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003350:	004b2503          	lw	a0,4(s6)
    80003354:	000a849b          	sext.w	s1,s5
    80003358:	8762                	mv	a4,s8
    8000335a:	faa4fde3          	bgeu	s1,a0,80003314 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000335e:	00777693          	andi	a3,a4,7
    80003362:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003366:	41f7579b          	sraiw	a5,a4,0x1f
    8000336a:	01d7d79b          	srliw	a5,a5,0x1d
    8000336e:	9fb9                	addw	a5,a5,a4
    80003370:	4037d79b          	sraiw	a5,a5,0x3
    80003374:	00f90633          	add	a2,s2,a5
    80003378:	05864603          	lbu	a2,88(a2)
    8000337c:	00c6f5b3          	and	a1,a3,a2
    80003380:	cd91                	beqz	a1,8000339c <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003382:	2705                	addiw	a4,a4,1
    80003384:	2485                	addiw	s1,s1,1
    80003386:	fd471ae3          	bne	a4,s4,8000335a <balloc+0x80>
    8000338a:	b769                	j	80003314 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000338c:	00005517          	auipc	a0,0x5
    80003390:	26c50513          	addi	a0,a0,620 # 800085f8 <syscalls+0x110>
    80003394:	ffffd097          	auipc	ra,0xffffd
    80003398:	1b2080e7          	jalr	434(ra) # 80000546 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000339c:	97ca                	add	a5,a5,s2
    8000339e:	8e55                	or	a2,a2,a3
    800033a0:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033a4:	854a                	mv	a0,s2
    800033a6:	00001097          	auipc	ra,0x1
    800033aa:	00e080e7          	jalr	14(ra) # 800043b4 <log_write>
        brelse(bp);
    800033ae:	854a                	mv	a0,s2
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	d98080e7          	jalr	-616(ra) # 80003148 <brelse>
  bp = bread(dev, bno);
    800033b8:	85a6                	mv	a1,s1
    800033ba:	855e                	mv	a0,s7
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	c5c080e7          	jalr	-932(ra) # 80003018 <bread>
    800033c4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033c6:	40000613          	li	a2,1024
    800033ca:	4581                	li	a1,0
    800033cc:	05850513          	addi	a0,a0,88
    800033d0:	ffffe097          	auipc	ra,0xffffe
    800033d4:	986080e7          	jalr	-1658(ra) # 80000d56 <memset>
  log_write(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00001097          	auipc	ra,0x1
    800033de:	fda080e7          	jalr	-38(ra) # 800043b4 <log_write>
  brelse(bp);
    800033e2:	854a                	mv	a0,s2
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	d64080e7          	jalr	-668(ra) # 80003148 <brelse>
}
    800033ec:	8526                	mv	a0,s1
    800033ee:	60e6                	ld	ra,88(sp)
    800033f0:	6446                	ld	s0,80(sp)
    800033f2:	64a6                	ld	s1,72(sp)
    800033f4:	6906                	ld	s2,64(sp)
    800033f6:	79e2                	ld	s3,56(sp)
    800033f8:	7a42                	ld	s4,48(sp)
    800033fa:	7aa2                	ld	s5,40(sp)
    800033fc:	7b02                	ld	s6,32(sp)
    800033fe:	6be2                	ld	s7,24(sp)
    80003400:	6c42                	ld	s8,16(sp)
    80003402:	6ca2                	ld	s9,8(sp)
    80003404:	6125                	addi	sp,sp,96
    80003406:	8082                	ret

0000000080003408 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003408:	7179                	addi	sp,sp,-48
    8000340a:	f406                	sd	ra,40(sp)
    8000340c:	f022                	sd	s0,32(sp)
    8000340e:	ec26                	sd	s1,24(sp)
    80003410:	e84a                	sd	s2,16(sp)
    80003412:	e44e                	sd	s3,8(sp)
    80003414:	e052                	sd	s4,0(sp)
    80003416:	1800                	addi	s0,sp,48
    80003418:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000341a:	47ad                	li	a5,11
    8000341c:	04b7fe63          	bgeu	a5,a1,80003478 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003420:	ff45849b          	addiw	s1,a1,-12
    80003424:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003428:	0ff00793          	li	a5,255
    8000342c:	0ae7e463          	bltu	a5,a4,800034d4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003430:	08052583          	lw	a1,128(a0)
    80003434:	c5b5                	beqz	a1,800034a0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003436:	00092503          	lw	a0,0(s2)
    8000343a:	00000097          	auipc	ra,0x0
    8000343e:	bde080e7          	jalr	-1058(ra) # 80003018 <bread>
    80003442:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003444:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003448:	02049713          	slli	a4,s1,0x20
    8000344c:	01e75593          	srli	a1,a4,0x1e
    80003450:	00b784b3          	add	s1,a5,a1
    80003454:	0004a983          	lw	s3,0(s1)
    80003458:	04098e63          	beqz	s3,800034b4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000345c:	8552                	mv	a0,s4
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	cea080e7          	jalr	-790(ra) # 80003148 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003466:	854e                	mv	a0,s3
    80003468:	70a2                	ld	ra,40(sp)
    8000346a:	7402                	ld	s0,32(sp)
    8000346c:	64e2                	ld	s1,24(sp)
    8000346e:	6942                	ld	s2,16(sp)
    80003470:	69a2                	ld	s3,8(sp)
    80003472:	6a02                	ld	s4,0(sp)
    80003474:	6145                	addi	sp,sp,48
    80003476:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003478:	02059793          	slli	a5,a1,0x20
    8000347c:	01e7d593          	srli	a1,a5,0x1e
    80003480:	00b504b3          	add	s1,a0,a1
    80003484:	0504a983          	lw	s3,80(s1)
    80003488:	fc099fe3          	bnez	s3,80003466 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000348c:	4108                	lw	a0,0(a0)
    8000348e:	00000097          	auipc	ra,0x0
    80003492:	e4c080e7          	jalr	-436(ra) # 800032da <balloc>
    80003496:	0005099b          	sext.w	s3,a0
    8000349a:	0534a823          	sw	s3,80(s1)
    8000349e:	b7e1                	j	80003466 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034a0:	4108                	lw	a0,0(a0)
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	e38080e7          	jalr	-456(ra) # 800032da <balloc>
    800034aa:	0005059b          	sext.w	a1,a0
    800034ae:	08b92023          	sw	a1,128(s2)
    800034b2:	b751                	j	80003436 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034b4:	00092503          	lw	a0,0(s2)
    800034b8:	00000097          	auipc	ra,0x0
    800034bc:	e22080e7          	jalr	-478(ra) # 800032da <balloc>
    800034c0:	0005099b          	sext.w	s3,a0
    800034c4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034c8:	8552                	mv	a0,s4
    800034ca:	00001097          	auipc	ra,0x1
    800034ce:	eea080e7          	jalr	-278(ra) # 800043b4 <log_write>
    800034d2:	b769                	j	8000345c <bmap+0x54>
  panic("bmap: out of range");
    800034d4:	00005517          	auipc	a0,0x5
    800034d8:	13c50513          	addi	a0,a0,316 # 80008610 <syscalls+0x128>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	06a080e7          	jalr	106(ra) # 80000546 <panic>

00000000800034e4 <iget>:
{
    800034e4:	7179                	addi	sp,sp,-48
    800034e6:	f406                	sd	ra,40(sp)
    800034e8:	f022                	sd	s0,32(sp)
    800034ea:	ec26                	sd	s1,24(sp)
    800034ec:	e84a                	sd	s2,16(sp)
    800034ee:	e44e                	sd	s3,8(sp)
    800034f0:	e052                	sd	s4,0(sp)
    800034f2:	1800                	addi	s0,sp,48
    800034f4:	89aa                	mv	s3,a0
    800034f6:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034f8:	0001d517          	auipc	a0,0x1d
    800034fc:	b6850513          	addi	a0,a0,-1176 # 80020060 <icache>
    80003500:	ffffd097          	auipc	ra,0xffffd
    80003504:	75a080e7          	jalr	1882(ra) # 80000c5a <acquire>
  empty = 0;
    80003508:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000350a:	0001d497          	auipc	s1,0x1d
    8000350e:	b6e48493          	addi	s1,s1,-1170 # 80020078 <icache+0x18>
    80003512:	0001e697          	auipc	a3,0x1e
    80003516:	5f668693          	addi	a3,a3,1526 # 80021b08 <log>
    8000351a:	a039                	j	80003528 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000351c:	02090b63          	beqz	s2,80003552 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003520:	08848493          	addi	s1,s1,136
    80003524:	02d48a63          	beq	s1,a3,80003558 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003528:	449c                	lw	a5,8(s1)
    8000352a:	fef059e3          	blez	a5,8000351c <iget+0x38>
    8000352e:	4098                	lw	a4,0(s1)
    80003530:	ff3716e3          	bne	a4,s3,8000351c <iget+0x38>
    80003534:	40d8                	lw	a4,4(s1)
    80003536:	ff4713e3          	bne	a4,s4,8000351c <iget+0x38>
      ip->ref++;
    8000353a:	2785                	addiw	a5,a5,1
    8000353c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000353e:	0001d517          	auipc	a0,0x1d
    80003542:	b2250513          	addi	a0,a0,-1246 # 80020060 <icache>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	7c8080e7          	jalr	1992(ra) # 80000d0e <release>
      return ip;
    8000354e:	8926                	mv	s2,s1
    80003550:	a03d                	j	8000357e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003552:	f7f9                	bnez	a5,80003520 <iget+0x3c>
    80003554:	8926                	mv	s2,s1
    80003556:	b7e9                	j	80003520 <iget+0x3c>
  if(empty == 0)
    80003558:	02090c63          	beqz	s2,80003590 <iget+0xac>
  ip->dev = dev;
    8000355c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003560:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003564:	4785                	li	a5,1
    80003566:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000356a:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000356e:	0001d517          	auipc	a0,0x1d
    80003572:	af250513          	addi	a0,a0,-1294 # 80020060 <icache>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	798080e7          	jalr	1944(ra) # 80000d0e <release>
}
    8000357e:	854a                	mv	a0,s2
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6a02                	ld	s4,0(sp)
    8000358c:	6145                	addi	sp,sp,48
    8000358e:	8082                	ret
    panic("iget: no inodes");
    80003590:	00005517          	auipc	a0,0x5
    80003594:	09850513          	addi	a0,a0,152 # 80008628 <syscalls+0x140>
    80003598:	ffffd097          	auipc	ra,0xffffd
    8000359c:	fae080e7          	jalr	-82(ra) # 80000546 <panic>

00000000800035a0 <fsinit>:
fsinit(int dev) {
    800035a0:	7179                	addi	sp,sp,-48
    800035a2:	f406                	sd	ra,40(sp)
    800035a4:	f022                	sd	s0,32(sp)
    800035a6:	ec26                	sd	s1,24(sp)
    800035a8:	e84a                	sd	s2,16(sp)
    800035aa:	e44e                	sd	s3,8(sp)
    800035ac:	1800                	addi	s0,sp,48
    800035ae:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035b0:	4585                	li	a1,1
    800035b2:	00000097          	auipc	ra,0x0
    800035b6:	a66080e7          	jalr	-1434(ra) # 80003018 <bread>
    800035ba:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035bc:	0001d997          	auipc	s3,0x1d
    800035c0:	a8498993          	addi	s3,s3,-1404 # 80020040 <sb>
    800035c4:	02000613          	li	a2,32
    800035c8:	05850593          	addi	a1,a0,88
    800035cc:	854e                	mv	a0,s3
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	7e4080e7          	jalr	2020(ra) # 80000db2 <memmove>
  brelse(bp);
    800035d6:	8526                	mv	a0,s1
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	b70080e7          	jalr	-1168(ra) # 80003148 <brelse>
  if(sb.magic != FSMAGIC)
    800035e0:	0009a703          	lw	a4,0(s3)
    800035e4:	102037b7          	lui	a5,0x10203
    800035e8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035ec:	02f71263          	bne	a4,a5,80003610 <fsinit+0x70>
  initlog(dev, &sb);
    800035f0:	0001d597          	auipc	a1,0x1d
    800035f4:	a5058593          	addi	a1,a1,-1456 # 80020040 <sb>
    800035f8:	854a                	mv	a0,s2
    800035fa:	00001097          	auipc	ra,0x1
    800035fe:	b42080e7          	jalr	-1214(ra) # 8000413c <initlog>
}
    80003602:	70a2                	ld	ra,40(sp)
    80003604:	7402                	ld	s0,32(sp)
    80003606:	64e2                	ld	s1,24(sp)
    80003608:	6942                	ld	s2,16(sp)
    8000360a:	69a2                	ld	s3,8(sp)
    8000360c:	6145                	addi	sp,sp,48
    8000360e:	8082                	ret
    panic("invalid file system");
    80003610:	00005517          	auipc	a0,0x5
    80003614:	02850513          	addi	a0,a0,40 # 80008638 <syscalls+0x150>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	f2e080e7          	jalr	-210(ra) # 80000546 <panic>

0000000080003620 <iinit>:
{
    80003620:	7179                	addi	sp,sp,-48
    80003622:	f406                	sd	ra,40(sp)
    80003624:	f022                	sd	s0,32(sp)
    80003626:	ec26                	sd	s1,24(sp)
    80003628:	e84a                	sd	s2,16(sp)
    8000362a:	e44e                	sd	s3,8(sp)
    8000362c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000362e:	00005597          	auipc	a1,0x5
    80003632:	02258593          	addi	a1,a1,34 # 80008650 <syscalls+0x168>
    80003636:	0001d517          	auipc	a0,0x1d
    8000363a:	a2a50513          	addi	a0,a0,-1494 # 80020060 <icache>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	58c080e7          	jalr	1420(ra) # 80000bca <initlock>
  for(i = 0; i < NINODE; i++) {
    80003646:	0001d497          	auipc	s1,0x1d
    8000364a:	a4248493          	addi	s1,s1,-1470 # 80020088 <icache+0x28>
    8000364e:	0001e997          	auipc	s3,0x1e
    80003652:	4ca98993          	addi	s3,s3,1226 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003656:	00005917          	auipc	s2,0x5
    8000365a:	00290913          	addi	s2,s2,2 # 80008658 <syscalls+0x170>
    8000365e:	85ca                	mv	a1,s2
    80003660:	8526                	mv	a0,s1
    80003662:	00001097          	auipc	ra,0x1
    80003666:	e3e080e7          	jalr	-450(ra) # 800044a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000366a:	08848493          	addi	s1,s1,136
    8000366e:	ff3498e3          	bne	s1,s3,8000365e <iinit+0x3e>
}
    80003672:	70a2                	ld	ra,40(sp)
    80003674:	7402                	ld	s0,32(sp)
    80003676:	64e2                	ld	s1,24(sp)
    80003678:	6942                	ld	s2,16(sp)
    8000367a:	69a2                	ld	s3,8(sp)
    8000367c:	6145                	addi	sp,sp,48
    8000367e:	8082                	ret

0000000080003680 <ialloc>:
{
    80003680:	715d                	addi	sp,sp,-80
    80003682:	e486                	sd	ra,72(sp)
    80003684:	e0a2                	sd	s0,64(sp)
    80003686:	fc26                	sd	s1,56(sp)
    80003688:	f84a                	sd	s2,48(sp)
    8000368a:	f44e                	sd	s3,40(sp)
    8000368c:	f052                	sd	s4,32(sp)
    8000368e:	ec56                	sd	s5,24(sp)
    80003690:	e85a                	sd	s6,16(sp)
    80003692:	e45e                	sd	s7,8(sp)
    80003694:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003696:	0001d717          	auipc	a4,0x1d
    8000369a:	9b672703          	lw	a4,-1610(a4) # 8002004c <sb+0xc>
    8000369e:	4785                	li	a5,1
    800036a0:	04e7fa63          	bgeu	a5,a4,800036f4 <ialloc+0x74>
    800036a4:	8aaa                	mv	s5,a0
    800036a6:	8bae                	mv	s7,a1
    800036a8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036aa:	0001da17          	auipc	s4,0x1d
    800036ae:	996a0a13          	addi	s4,s4,-1642 # 80020040 <sb>
    800036b2:	00048b1b          	sext.w	s6,s1
    800036b6:	0044d593          	srli	a1,s1,0x4
    800036ba:	018a2783          	lw	a5,24(s4)
    800036be:	9dbd                	addw	a1,a1,a5
    800036c0:	8556                	mv	a0,s5
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	956080e7          	jalr	-1706(ra) # 80003018 <bread>
    800036ca:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036cc:	05850993          	addi	s3,a0,88
    800036d0:	00f4f793          	andi	a5,s1,15
    800036d4:	079a                	slli	a5,a5,0x6
    800036d6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036d8:	00099783          	lh	a5,0(s3)
    800036dc:	c785                	beqz	a5,80003704 <ialloc+0x84>
    brelse(bp);
    800036de:	00000097          	auipc	ra,0x0
    800036e2:	a6a080e7          	jalr	-1430(ra) # 80003148 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036e6:	0485                	addi	s1,s1,1
    800036e8:	00ca2703          	lw	a4,12(s4)
    800036ec:	0004879b          	sext.w	a5,s1
    800036f0:	fce7e1e3          	bltu	a5,a4,800036b2 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036f4:	00005517          	auipc	a0,0x5
    800036f8:	f6c50513          	addi	a0,a0,-148 # 80008660 <syscalls+0x178>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e4a080e7          	jalr	-438(ra) # 80000546 <panic>
      memset(dip, 0, sizeof(*dip));
    80003704:	04000613          	li	a2,64
    80003708:	4581                	li	a1,0
    8000370a:	854e                	mv	a0,s3
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	64a080e7          	jalr	1610(ra) # 80000d56 <memset>
      dip->type = type;
    80003714:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003718:	854a                	mv	a0,s2
    8000371a:	00001097          	auipc	ra,0x1
    8000371e:	c9a080e7          	jalr	-870(ra) # 800043b4 <log_write>
      brelse(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00000097          	auipc	ra,0x0
    80003728:	a24080e7          	jalr	-1500(ra) # 80003148 <brelse>
      return iget(dev, inum);
    8000372c:	85da                	mv	a1,s6
    8000372e:	8556                	mv	a0,s5
    80003730:	00000097          	auipc	ra,0x0
    80003734:	db4080e7          	jalr	-588(ra) # 800034e4 <iget>
}
    80003738:	60a6                	ld	ra,72(sp)
    8000373a:	6406                	ld	s0,64(sp)
    8000373c:	74e2                	ld	s1,56(sp)
    8000373e:	7942                	ld	s2,48(sp)
    80003740:	79a2                	ld	s3,40(sp)
    80003742:	7a02                	ld	s4,32(sp)
    80003744:	6ae2                	ld	s5,24(sp)
    80003746:	6b42                	ld	s6,16(sp)
    80003748:	6ba2                	ld	s7,8(sp)
    8000374a:	6161                	addi	sp,sp,80
    8000374c:	8082                	ret

000000008000374e <iupdate>:
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	e426                	sd	s1,8(sp)
    80003756:	e04a                	sd	s2,0(sp)
    80003758:	1000                	addi	s0,sp,32
    8000375a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000375c:	415c                	lw	a5,4(a0)
    8000375e:	0047d79b          	srliw	a5,a5,0x4
    80003762:	0001d597          	auipc	a1,0x1d
    80003766:	8f65a583          	lw	a1,-1802(a1) # 80020058 <sb+0x18>
    8000376a:	9dbd                	addw	a1,a1,a5
    8000376c:	4108                	lw	a0,0(a0)
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	8aa080e7          	jalr	-1878(ra) # 80003018 <bread>
    80003776:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003778:	05850793          	addi	a5,a0,88
    8000377c:	40d8                	lw	a4,4(s1)
    8000377e:	8b3d                	andi	a4,a4,15
    80003780:	071a                	slli	a4,a4,0x6
    80003782:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003784:	04449703          	lh	a4,68(s1)
    80003788:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000378c:	04649703          	lh	a4,70(s1)
    80003790:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003794:	04849703          	lh	a4,72(s1)
    80003798:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000379c:	04a49703          	lh	a4,74(s1)
    800037a0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800037a4:	44f8                	lw	a4,76(s1)
    800037a6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037a8:	03400613          	li	a2,52
    800037ac:	05048593          	addi	a1,s1,80
    800037b0:	00c78513          	addi	a0,a5,12
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	5fe080e7          	jalr	1534(ra) # 80000db2 <memmove>
  log_write(bp);
    800037bc:	854a                	mv	a0,s2
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	bf6080e7          	jalr	-1034(ra) # 800043b4 <log_write>
  brelse(bp);
    800037c6:	854a                	mv	a0,s2
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	980080e7          	jalr	-1664(ra) # 80003148 <brelse>
}
    800037d0:	60e2                	ld	ra,24(sp)
    800037d2:	6442                	ld	s0,16(sp)
    800037d4:	64a2                	ld	s1,8(sp)
    800037d6:	6902                	ld	s2,0(sp)
    800037d8:	6105                	addi	sp,sp,32
    800037da:	8082                	ret

00000000800037dc <idup>:
{
    800037dc:	1101                	addi	sp,sp,-32
    800037de:	ec06                	sd	ra,24(sp)
    800037e0:	e822                	sd	s0,16(sp)
    800037e2:	e426                	sd	s1,8(sp)
    800037e4:	1000                	addi	s0,sp,32
    800037e6:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037e8:	0001d517          	auipc	a0,0x1d
    800037ec:	87850513          	addi	a0,a0,-1928 # 80020060 <icache>
    800037f0:	ffffd097          	auipc	ra,0xffffd
    800037f4:	46a080e7          	jalr	1130(ra) # 80000c5a <acquire>
  ip->ref++;
    800037f8:	449c                	lw	a5,8(s1)
    800037fa:	2785                	addiw	a5,a5,1
    800037fc:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037fe:	0001d517          	auipc	a0,0x1d
    80003802:	86250513          	addi	a0,a0,-1950 # 80020060 <icache>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	508080e7          	jalr	1288(ra) # 80000d0e <release>
}
    8000380e:	8526                	mv	a0,s1
    80003810:	60e2                	ld	ra,24(sp)
    80003812:	6442                	ld	s0,16(sp)
    80003814:	64a2                	ld	s1,8(sp)
    80003816:	6105                	addi	sp,sp,32
    80003818:	8082                	ret

000000008000381a <ilock>:
{
    8000381a:	1101                	addi	sp,sp,-32
    8000381c:	ec06                	sd	ra,24(sp)
    8000381e:	e822                	sd	s0,16(sp)
    80003820:	e426                	sd	s1,8(sp)
    80003822:	e04a                	sd	s2,0(sp)
    80003824:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003826:	c115                	beqz	a0,8000384a <ilock+0x30>
    80003828:	84aa                	mv	s1,a0
    8000382a:	451c                	lw	a5,8(a0)
    8000382c:	00f05f63          	blez	a5,8000384a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003830:	0541                	addi	a0,a0,16
    80003832:	00001097          	auipc	ra,0x1
    80003836:	ca8080e7          	jalr	-856(ra) # 800044da <acquiresleep>
  if(ip->valid == 0){
    8000383a:	40bc                	lw	a5,64(s1)
    8000383c:	cf99                	beqz	a5,8000385a <ilock+0x40>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6902                	ld	s2,0(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret
    panic("ilock");
    8000384a:	00005517          	auipc	a0,0x5
    8000384e:	e2e50513          	addi	a0,a0,-466 # 80008678 <syscalls+0x190>
    80003852:	ffffd097          	auipc	ra,0xffffd
    80003856:	cf4080e7          	jalr	-780(ra) # 80000546 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000385a:	40dc                	lw	a5,4(s1)
    8000385c:	0047d79b          	srliw	a5,a5,0x4
    80003860:	0001c597          	auipc	a1,0x1c
    80003864:	7f85a583          	lw	a1,2040(a1) # 80020058 <sb+0x18>
    80003868:	9dbd                	addw	a1,a1,a5
    8000386a:	4088                	lw	a0,0(s1)
    8000386c:	fffff097          	auipc	ra,0xfffff
    80003870:	7ac080e7          	jalr	1964(ra) # 80003018 <bread>
    80003874:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003876:	05850593          	addi	a1,a0,88
    8000387a:	40dc                	lw	a5,4(s1)
    8000387c:	8bbd                	andi	a5,a5,15
    8000387e:	079a                	slli	a5,a5,0x6
    80003880:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003882:	00059783          	lh	a5,0(a1)
    80003886:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000388a:	00259783          	lh	a5,2(a1)
    8000388e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003892:	00459783          	lh	a5,4(a1)
    80003896:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000389a:	00659783          	lh	a5,6(a1)
    8000389e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038a2:	459c                	lw	a5,8(a1)
    800038a4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038a6:	03400613          	li	a2,52
    800038aa:	05b1                	addi	a1,a1,12
    800038ac:	05048513          	addi	a0,s1,80
    800038b0:	ffffd097          	auipc	ra,0xffffd
    800038b4:	502080e7          	jalr	1282(ra) # 80000db2 <memmove>
    brelse(bp);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	88e080e7          	jalr	-1906(ra) # 80003148 <brelse>
    ip->valid = 1;
    800038c2:	4785                	li	a5,1
    800038c4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038c6:	04449783          	lh	a5,68(s1)
    800038ca:	fbb5                	bnez	a5,8000383e <ilock+0x24>
      panic("ilock: no type");
    800038cc:	00005517          	auipc	a0,0x5
    800038d0:	db450513          	addi	a0,a0,-588 # 80008680 <syscalls+0x198>
    800038d4:	ffffd097          	auipc	ra,0xffffd
    800038d8:	c72080e7          	jalr	-910(ra) # 80000546 <panic>

00000000800038dc <iunlock>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	e04a                	sd	s2,0(sp)
    800038e6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038e8:	c905                	beqz	a0,80003918 <iunlock+0x3c>
    800038ea:	84aa                	mv	s1,a0
    800038ec:	01050913          	addi	s2,a0,16
    800038f0:	854a                	mv	a0,s2
    800038f2:	00001097          	auipc	ra,0x1
    800038f6:	c82080e7          	jalr	-894(ra) # 80004574 <holdingsleep>
    800038fa:	cd19                	beqz	a0,80003918 <iunlock+0x3c>
    800038fc:	449c                	lw	a5,8(s1)
    800038fe:	00f05d63          	blez	a5,80003918 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003902:	854a                	mv	a0,s2
    80003904:	00001097          	auipc	ra,0x1
    80003908:	c2c080e7          	jalr	-980(ra) # 80004530 <releasesleep>
}
    8000390c:	60e2                	ld	ra,24(sp)
    8000390e:	6442                	ld	s0,16(sp)
    80003910:	64a2                	ld	s1,8(sp)
    80003912:	6902                	ld	s2,0(sp)
    80003914:	6105                	addi	sp,sp,32
    80003916:	8082                	ret
    panic("iunlock");
    80003918:	00005517          	auipc	a0,0x5
    8000391c:	d7850513          	addi	a0,a0,-648 # 80008690 <syscalls+0x1a8>
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	c26080e7          	jalr	-986(ra) # 80000546 <panic>

0000000080003928 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003928:	7179                	addi	sp,sp,-48
    8000392a:	f406                	sd	ra,40(sp)
    8000392c:	f022                	sd	s0,32(sp)
    8000392e:	ec26                	sd	s1,24(sp)
    80003930:	e84a                	sd	s2,16(sp)
    80003932:	e44e                	sd	s3,8(sp)
    80003934:	e052                	sd	s4,0(sp)
    80003936:	1800                	addi	s0,sp,48
    80003938:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000393a:	05050493          	addi	s1,a0,80
    8000393e:	08050913          	addi	s2,a0,128
    80003942:	a021                	j	8000394a <itrunc+0x22>
    80003944:	0491                	addi	s1,s1,4
    80003946:	01248d63          	beq	s1,s2,80003960 <itrunc+0x38>
    if(ip->addrs[i]){
    8000394a:	408c                	lw	a1,0(s1)
    8000394c:	dde5                	beqz	a1,80003944 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000394e:	0009a503          	lw	a0,0(s3)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	90c080e7          	jalr	-1780(ra) # 8000325e <bfree>
      ip->addrs[i] = 0;
    8000395a:	0004a023          	sw	zero,0(s1)
    8000395e:	b7dd                	j	80003944 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003960:	0809a583          	lw	a1,128(s3)
    80003964:	e185                	bnez	a1,80003984 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003966:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000396a:	854e                	mv	a0,s3
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	de2080e7          	jalr	-542(ra) # 8000374e <iupdate>
}
    80003974:	70a2                	ld	ra,40(sp)
    80003976:	7402                	ld	s0,32(sp)
    80003978:	64e2                	ld	s1,24(sp)
    8000397a:	6942                	ld	s2,16(sp)
    8000397c:	69a2                	ld	s3,8(sp)
    8000397e:	6a02                	ld	s4,0(sp)
    80003980:	6145                	addi	sp,sp,48
    80003982:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003984:	0009a503          	lw	a0,0(s3)
    80003988:	fffff097          	auipc	ra,0xfffff
    8000398c:	690080e7          	jalr	1680(ra) # 80003018 <bread>
    80003990:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003992:	05850493          	addi	s1,a0,88
    80003996:	45850913          	addi	s2,a0,1112
    8000399a:	a021                	j	800039a2 <itrunc+0x7a>
    8000399c:	0491                	addi	s1,s1,4
    8000399e:	01248b63          	beq	s1,s2,800039b4 <itrunc+0x8c>
      if(a[j])
    800039a2:	408c                	lw	a1,0(s1)
    800039a4:	dde5                	beqz	a1,8000399c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039a6:	0009a503          	lw	a0,0(s3)
    800039aa:	00000097          	auipc	ra,0x0
    800039ae:	8b4080e7          	jalr	-1868(ra) # 8000325e <bfree>
    800039b2:	b7ed                	j	8000399c <itrunc+0x74>
    brelse(bp);
    800039b4:	8552                	mv	a0,s4
    800039b6:	fffff097          	auipc	ra,0xfffff
    800039ba:	792080e7          	jalr	1938(ra) # 80003148 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039be:	0809a583          	lw	a1,128(s3)
    800039c2:	0009a503          	lw	a0,0(s3)
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	898080e7          	jalr	-1896(ra) # 8000325e <bfree>
    ip->addrs[NDIRECT] = 0;
    800039ce:	0809a023          	sw	zero,128(s3)
    800039d2:	bf51                	j	80003966 <itrunc+0x3e>

00000000800039d4 <iput>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	e04a                	sd	s2,0(sp)
    800039de:	1000                	addi	s0,sp,32
    800039e0:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039e2:	0001c517          	auipc	a0,0x1c
    800039e6:	67e50513          	addi	a0,a0,1662 # 80020060 <icache>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	270080e7          	jalr	624(ra) # 80000c5a <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039f2:	4498                	lw	a4,8(s1)
    800039f4:	4785                	li	a5,1
    800039f6:	02f70363          	beq	a4,a5,80003a1c <iput+0x48>
  ip->ref--;
    800039fa:	449c                	lw	a5,8(s1)
    800039fc:	37fd                	addiw	a5,a5,-1
    800039fe:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a00:	0001c517          	auipc	a0,0x1c
    80003a04:	66050513          	addi	a0,a0,1632 # 80020060 <icache>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	306080e7          	jalr	774(ra) # 80000d0e <release>
}
    80003a10:	60e2                	ld	ra,24(sp)
    80003a12:	6442                	ld	s0,16(sp)
    80003a14:	64a2                	ld	s1,8(sp)
    80003a16:	6902                	ld	s2,0(sp)
    80003a18:	6105                	addi	sp,sp,32
    80003a1a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a1c:	40bc                	lw	a5,64(s1)
    80003a1e:	dff1                	beqz	a5,800039fa <iput+0x26>
    80003a20:	04a49783          	lh	a5,74(s1)
    80003a24:	fbf9                	bnez	a5,800039fa <iput+0x26>
    acquiresleep(&ip->lock);
    80003a26:	01048913          	addi	s2,s1,16
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	aae080e7          	jalr	-1362(ra) # 800044da <acquiresleep>
    release(&icache.lock);
    80003a34:	0001c517          	auipc	a0,0x1c
    80003a38:	62c50513          	addi	a0,a0,1580 # 80020060 <icache>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	2d2080e7          	jalr	722(ra) # 80000d0e <release>
    itrunc(ip);
    80003a44:	8526                	mv	a0,s1
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	ee2080e7          	jalr	-286(ra) # 80003928 <itrunc>
    ip->type = 0;
    80003a4e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a52:	8526                	mv	a0,s1
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	cfa080e7          	jalr	-774(ra) # 8000374e <iupdate>
    ip->valid = 0;
    80003a5c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a60:	854a                	mv	a0,s2
    80003a62:	00001097          	auipc	ra,0x1
    80003a66:	ace080e7          	jalr	-1330(ra) # 80004530 <releasesleep>
    acquire(&icache.lock);
    80003a6a:	0001c517          	auipc	a0,0x1c
    80003a6e:	5f650513          	addi	a0,a0,1526 # 80020060 <icache>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	1e8080e7          	jalr	488(ra) # 80000c5a <acquire>
    80003a7a:	b741                	j	800039fa <iput+0x26>

0000000080003a7c <iunlockput>:
{
    80003a7c:	1101                	addi	sp,sp,-32
    80003a7e:	ec06                	sd	ra,24(sp)
    80003a80:	e822                	sd	s0,16(sp)
    80003a82:	e426                	sd	s1,8(sp)
    80003a84:	1000                	addi	s0,sp,32
    80003a86:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	e54080e7          	jalr	-428(ra) # 800038dc <iunlock>
  iput(ip);
    80003a90:	8526                	mv	a0,s1
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	f42080e7          	jalr	-190(ra) # 800039d4 <iput>
}
    80003a9a:	60e2                	ld	ra,24(sp)
    80003a9c:	6442                	ld	s0,16(sp)
    80003a9e:	64a2                	ld	s1,8(sp)
    80003aa0:	6105                	addi	sp,sp,32
    80003aa2:	8082                	ret

0000000080003aa4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aa4:	1141                	addi	sp,sp,-16
    80003aa6:	e422                	sd	s0,8(sp)
    80003aa8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003aaa:	411c                	lw	a5,0(a0)
    80003aac:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003aae:	415c                	lw	a5,4(a0)
    80003ab0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ab2:	04451783          	lh	a5,68(a0)
    80003ab6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aba:	04a51783          	lh	a5,74(a0)
    80003abe:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ac2:	04c56783          	lwu	a5,76(a0)
    80003ac6:	e99c                	sd	a5,16(a1)
}
    80003ac8:	6422                	ld	s0,8(sp)
    80003aca:	0141                	addi	sp,sp,16
    80003acc:	8082                	ret

0000000080003ace <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ace:	457c                	lw	a5,76(a0)
    80003ad0:	0ed7e863          	bltu	a5,a3,80003bc0 <readi+0xf2>
{
    80003ad4:	7159                	addi	sp,sp,-112
    80003ad6:	f486                	sd	ra,104(sp)
    80003ad8:	f0a2                	sd	s0,96(sp)
    80003ada:	eca6                	sd	s1,88(sp)
    80003adc:	e8ca                	sd	s2,80(sp)
    80003ade:	e4ce                	sd	s3,72(sp)
    80003ae0:	e0d2                	sd	s4,64(sp)
    80003ae2:	fc56                	sd	s5,56(sp)
    80003ae4:	f85a                	sd	s6,48(sp)
    80003ae6:	f45e                	sd	s7,40(sp)
    80003ae8:	f062                	sd	s8,32(sp)
    80003aea:	ec66                	sd	s9,24(sp)
    80003aec:	e86a                	sd	s10,16(sp)
    80003aee:	e46e                	sd	s11,8(sp)
    80003af0:	1880                	addi	s0,sp,112
    80003af2:	8baa                	mv	s7,a0
    80003af4:	8c2e                	mv	s8,a1
    80003af6:	8ab2                	mv	s5,a2
    80003af8:	84b6                	mv	s1,a3
    80003afa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003afc:	9f35                	addw	a4,a4,a3
    return 0;
    80003afe:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b00:	08d76f63          	bltu	a4,a3,80003b9e <readi+0xd0>
  if(off + n > ip->size)
    80003b04:	00e7f463          	bgeu	a5,a4,80003b0c <readi+0x3e>
    n = ip->size - off;
    80003b08:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0c:	0a0b0863          	beqz	s6,80003bbc <readi+0xee>
    80003b10:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b12:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b16:	5cfd                	li	s9,-1
    80003b18:	a82d                	j	80003b52 <readi+0x84>
    80003b1a:	020a1d93          	slli	s11,s4,0x20
    80003b1e:	020ddd93          	srli	s11,s11,0x20
    80003b22:	05890613          	addi	a2,s2,88
    80003b26:	86ee                	mv	a3,s11
    80003b28:	963a                	add	a2,a2,a4
    80003b2a:	85d6                	mv	a1,s5
    80003b2c:	8562                	mv	a0,s8
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	992080e7          	jalr	-1646(ra) # 800024c0 <either_copyout>
    80003b36:	05950d63          	beq	a0,s9,80003b90 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b3a:	854a                	mv	a0,s2
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	60c080e7          	jalr	1548(ra) # 80003148 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b44:	013a09bb          	addw	s3,s4,s3
    80003b48:	009a04bb          	addw	s1,s4,s1
    80003b4c:	9aee                	add	s5,s5,s11
    80003b4e:	0569f663          	bgeu	s3,s6,80003b9a <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b52:	000ba903          	lw	s2,0(s7)
    80003b56:	00a4d59b          	srliw	a1,s1,0xa
    80003b5a:	855e                	mv	a0,s7
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	8ac080e7          	jalr	-1876(ra) # 80003408 <bmap>
    80003b64:	0005059b          	sext.w	a1,a0
    80003b68:	854a                	mv	a0,s2
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	4ae080e7          	jalr	1198(ra) # 80003018 <bread>
    80003b72:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b74:	3ff4f713          	andi	a4,s1,1023
    80003b78:	40ed07bb          	subw	a5,s10,a4
    80003b7c:	413b06bb          	subw	a3,s6,s3
    80003b80:	8a3e                	mv	s4,a5
    80003b82:	2781                	sext.w	a5,a5
    80003b84:	0006861b          	sext.w	a2,a3
    80003b88:	f8f679e3          	bgeu	a2,a5,80003b1a <readi+0x4c>
    80003b8c:	8a36                	mv	s4,a3
    80003b8e:	b771                	j	80003b1a <readi+0x4c>
      brelse(bp);
    80003b90:	854a                	mv	a0,s2
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	5b6080e7          	jalr	1462(ra) # 80003148 <brelse>
  }
  return tot;
    80003b9a:	0009851b          	sext.w	a0,s3
}
    80003b9e:	70a6                	ld	ra,104(sp)
    80003ba0:	7406                	ld	s0,96(sp)
    80003ba2:	64e6                	ld	s1,88(sp)
    80003ba4:	6946                	ld	s2,80(sp)
    80003ba6:	69a6                	ld	s3,72(sp)
    80003ba8:	6a06                	ld	s4,64(sp)
    80003baa:	7ae2                	ld	s5,56(sp)
    80003bac:	7b42                	ld	s6,48(sp)
    80003bae:	7ba2                	ld	s7,40(sp)
    80003bb0:	7c02                	ld	s8,32(sp)
    80003bb2:	6ce2                	ld	s9,24(sp)
    80003bb4:	6d42                	ld	s10,16(sp)
    80003bb6:	6da2                	ld	s11,8(sp)
    80003bb8:	6165                	addi	sp,sp,112
    80003bba:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bbc:	89da                	mv	s3,s6
    80003bbe:	bff1                	j	80003b9a <readi+0xcc>
    return 0;
    80003bc0:	4501                	li	a0,0
}
    80003bc2:	8082                	ret

0000000080003bc4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bc4:	457c                	lw	a5,76(a0)
    80003bc6:	10d7e663          	bltu	a5,a3,80003cd2 <writei+0x10e>
{
    80003bca:	7159                	addi	sp,sp,-112
    80003bcc:	f486                	sd	ra,104(sp)
    80003bce:	f0a2                	sd	s0,96(sp)
    80003bd0:	eca6                	sd	s1,88(sp)
    80003bd2:	e8ca                	sd	s2,80(sp)
    80003bd4:	e4ce                	sd	s3,72(sp)
    80003bd6:	e0d2                	sd	s4,64(sp)
    80003bd8:	fc56                	sd	s5,56(sp)
    80003bda:	f85a                	sd	s6,48(sp)
    80003bdc:	f45e                	sd	s7,40(sp)
    80003bde:	f062                	sd	s8,32(sp)
    80003be0:	ec66                	sd	s9,24(sp)
    80003be2:	e86a                	sd	s10,16(sp)
    80003be4:	e46e                	sd	s11,8(sp)
    80003be6:	1880                	addi	s0,sp,112
    80003be8:	8baa                	mv	s7,a0
    80003bea:	8c2e                	mv	s8,a1
    80003bec:	8ab2                	mv	s5,a2
    80003bee:	8936                	mv	s2,a3
    80003bf0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bf2:	00e687bb          	addw	a5,a3,a4
    80003bf6:	0ed7e063          	bltu	a5,a3,80003cd6 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bfa:	00043737          	lui	a4,0x43
    80003bfe:	0cf76e63          	bltu	a4,a5,80003cda <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c02:	0a0b0763          	beqz	s6,80003cb0 <writei+0xec>
    80003c06:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c08:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c0c:	5cfd                	li	s9,-1
    80003c0e:	a091                	j	80003c52 <writei+0x8e>
    80003c10:	02099d93          	slli	s11,s3,0x20
    80003c14:	020ddd93          	srli	s11,s11,0x20
    80003c18:	05848513          	addi	a0,s1,88
    80003c1c:	86ee                	mv	a3,s11
    80003c1e:	8656                	mv	a2,s5
    80003c20:	85e2                	mv	a1,s8
    80003c22:	953a                	add	a0,a0,a4
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	8f2080e7          	jalr	-1806(ra) # 80002516 <either_copyin>
    80003c2c:	07950263          	beq	a0,s9,80003c90 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c30:	8526                	mv	a0,s1
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	782080e7          	jalr	1922(ra) # 800043b4 <log_write>
    brelse(bp);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	50c080e7          	jalr	1292(ra) # 80003148 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c44:	01498a3b          	addw	s4,s3,s4
    80003c48:	0129893b          	addw	s2,s3,s2
    80003c4c:	9aee                	add	s5,s5,s11
    80003c4e:	056a7663          	bgeu	s4,s6,80003c9a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c52:	000ba483          	lw	s1,0(s7)
    80003c56:	00a9559b          	srliw	a1,s2,0xa
    80003c5a:	855e                	mv	a0,s7
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	7ac080e7          	jalr	1964(ra) # 80003408 <bmap>
    80003c64:	0005059b          	sext.w	a1,a0
    80003c68:	8526                	mv	a0,s1
    80003c6a:	fffff097          	auipc	ra,0xfffff
    80003c6e:	3ae080e7          	jalr	942(ra) # 80003018 <bread>
    80003c72:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c74:	3ff97713          	andi	a4,s2,1023
    80003c78:	40ed07bb          	subw	a5,s10,a4
    80003c7c:	414b06bb          	subw	a3,s6,s4
    80003c80:	89be                	mv	s3,a5
    80003c82:	2781                	sext.w	a5,a5
    80003c84:	0006861b          	sext.w	a2,a3
    80003c88:	f8f674e3          	bgeu	a2,a5,80003c10 <writei+0x4c>
    80003c8c:	89b6                	mv	s3,a3
    80003c8e:	b749                	j	80003c10 <writei+0x4c>
      brelse(bp);
    80003c90:	8526                	mv	a0,s1
    80003c92:	fffff097          	auipc	ra,0xfffff
    80003c96:	4b6080e7          	jalr	1206(ra) # 80003148 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c9a:	04cba783          	lw	a5,76(s7)
    80003c9e:	0127f463          	bgeu	a5,s2,80003ca6 <writei+0xe2>
      ip->size = off;
    80003ca2:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003ca6:	855e                	mv	a0,s7
    80003ca8:	00000097          	auipc	ra,0x0
    80003cac:	aa6080e7          	jalr	-1370(ra) # 8000374e <iupdate>
  }

  return n;
    80003cb0:	000b051b          	sext.w	a0,s6
}
    80003cb4:	70a6                	ld	ra,104(sp)
    80003cb6:	7406                	ld	s0,96(sp)
    80003cb8:	64e6                	ld	s1,88(sp)
    80003cba:	6946                	ld	s2,80(sp)
    80003cbc:	69a6                	ld	s3,72(sp)
    80003cbe:	6a06                	ld	s4,64(sp)
    80003cc0:	7ae2                	ld	s5,56(sp)
    80003cc2:	7b42                	ld	s6,48(sp)
    80003cc4:	7ba2                	ld	s7,40(sp)
    80003cc6:	7c02                	ld	s8,32(sp)
    80003cc8:	6ce2                	ld	s9,24(sp)
    80003cca:	6d42                	ld	s10,16(sp)
    80003ccc:	6da2                	ld	s11,8(sp)
    80003cce:	6165                	addi	sp,sp,112
    80003cd0:	8082                	ret
    return -1;
    80003cd2:	557d                	li	a0,-1
}
    80003cd4:	8082                	ret
    return -1;
    80003cd6:	557d                	li	a0,-1
    80003cd8:	bff1                	j	80003cb4 <writei+0xf0>
    return -1;
    80003cda:	557d                	li	a0,-1
    80003cdc:	bfe1                	j	80003cb4 <writei+0xf0>

0000000080003cde <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cde:	1141                	addi	sp,sp,-16
    80003ce0:	e406                	sd	ra,8(sp)
    80003ce2:	e022                	sd	s0,0(sp)
    80003ce4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ce6:	4639                	li	a2,14
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	146080e7          	jalr	326(ra) # 80000e2e <strncmp>
}
    80003cf0:	60a2                	ld	ra,8(sp)
    80003cf2:	6402                	ld	s0,0(sp)
    80003cf4:	0141                	addi	sp,sp,16
    80003cf6:	8082                	ret

0000000080003cf8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cf8:	7139                	addi	sp,sp,-64
    80003cfa:	fc06                	sd	ra,56(sp)
    80003cfc:	f822                	sd	s0,48(sp)
    80003cfe:	f426                	sd	s1,40(sp)
    80003d00:	f04a                	sd	s2,32(sp)
    80003d02:	ec4e                	sd	s3,24(sp)
    80003d04:	e852                	sd	s4,16(sp)
    80003d06:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d08:	04451703          	lh	a4,68(a0)
    80003d0c:	4785                	li	a5,1
    80003d0e:	00f71a63          	bne	a4,a5,80003d22 <dirlookup+0x2a>
    80003d12:	892a                	mv	s2,a0
    80003d14:	89ae                	mv	s3,a1
    80003d16:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d18:	457c                	lw	a5,76(a0)
    80003d1a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d1c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d1e:	e79d                	bnez	a5,80003d4c <dirlookup+0x54>
    80003d20:	a8a5                	j	80003d98 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d22:	00005517          	auipc	a0,0x5
    80003d26:	97650513          	addi	a0,a0,-1674 # 80008698 <syscalls+0x1b0>
    80003d2a:	ffffd097          	auipc	ra,0xffffd
    80003d2e:	81c080e7          	jalr	-2020(ra) # 80000546 <panic>
      panic("dirlookup read");
    80003d32:	00005517          	auipc	a0,0x5
    80003d36:	97e50513          	addi	a0,a0,-1666 # 800086b0 <syscalls+0x1c8>
    80003d3a:	ffffd097          	auipc	ra,0xffffd
    80003d3e:	80c080e7          	jalr	-2036(ra) # 80000546 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d42:	24c1                	addiw	s1,s1,16
    80003d44:	04c92783          	lw	a5,76(s2)
    80003d48:	04f4f763          	bgeu	s1,a5,80003d96 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d4c:	4741                	li	a4,16
    80003d4e:	86a6                	mv	a3,s1
    80003d50:	fc040613          	addi	a2,s0,-64
    80003d54:	4581                	li	a1,0
    80003d56:	854a                	mv	a0,s2
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	d76080e7          	jalr	-650(ra) # 80003ace <readi>
    80003d60:	47c1                	li	a5,16
    80003d62:	fcf518e3          	bne	a0,a5,80003d32 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d66:	fc045783          	lhu	a5,-64(s0)
    80003d6a:	dfe1                	beqz	a5,80003d42 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d6c:	fc240593          	addi	a1,s0,-62
    80003d70:	854e                	mv	a0,s3
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	f6c080e7          	jalr	-148(ra) # 80003cde <namecmp>
    80003d7a:	f561                	bnez	a0,80003d42 <dirlookup+0x4a>
      if(poff)
    80003d7c:	000a0463          	beqz	s4,80003d84 <dirlookup+0x8c>
        *poff = off;
    80003d80:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d84:	fc045583          	lhu	a1,-64(s0)
    80003d88:	00092503          	lw	a0,0(s2)
    80003d8c:	fffff097          	auipc	ra,0xfffff
    80003d90:	758080e7          	jalr	1880(ra) # 800034e4 <iget>
    80003d94:	a011                	j	80003d98 <dirlookup+0xa0>
  return 0;
    80003d96:	4501                	li	a0,0
}
    80003d98:	70e2                	ld	ra,56(sp)
    80003d9a:	7442                	ld	s0,48(sp)
    80003d9c:	74a2                	ld	s1,40(sp)
    80003d9e:	7902                	ld	s2,32(sp)
    80003da0:	69e2                	ld	s3,24(sp)
    80003da2:	6a42                	ld	s4,16(sp)
    80003da4:	6121                	addi	sp,sp,64
    80003da6:	8082                	ret

0000000080003da8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003da8:	711d                	addi	sp,sp,-96
    80003daa:	ec86                	sd	ra,88(sp)
    80003dac:	e8a2                	sd	s0,80(sp)
    80003dae:	e4a6                	sd	s1,72(sp)
    80003db0:	e0ca                	sd	s2,64(sp)
    80003db2:	fc4e                	sd	s3,56(sp)
    80003db4:	f852                	sd	s4,48(sp)
    80003db6:	f456                	sd	s5,40(sp)
    80003db8:	f05a                	sd	s6,32(sp)
    80003dba:	ec5e                	sd	s7,24(sp)
    80003dbc:	e862                	sd	s8,16(sp)
    80003dbe:	e466                	sd	s9,8(sp)
    80003dc0:	e06a                	sd	s10,0(sp)
    80003dc2:	1080                	addi	s0,sp,96
    80003dc4:	84aa                	mv	s1,a0
    80003dc6:	8b2e                	mv	s6,a1
    80003dc8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dca:	00054703          	lbu	a4,0(a0)
    80003dce:	02f00793          	li	a5,47
    80003dd2:	02f70363          	beq	a4,a5,80003df8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003dd6:	ffffe097          	auipc	ra,0xffffe
    80003dda:	c50080e7          	jalr	-944(ra) # 80001a26 <myproc>
    80003dde:	15053503          	ld	a0,336(a0)
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	9fa080e7          	jalr	-1542(ra) # 800037dc <idup>
    80003dea:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003dec:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003df0:	4cb5                	li	s9,13
  len = path - s;
    80003df2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003df4:	4c05                	li	s8,1
    80003df6:	a87d                	j	80003eb4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003df8:	4585                	li	a1,1
    80003dfa:	4505                	li	a0,1
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	6e8080e7          	jalr	1768(ra) # 800034e4 <iget>
    80003e04:	8a2a                	mv	s4,a0
    80003e06:	b7dd                	j	80003dec <namex+0x44>
      iunlockput(ip);
    80003e08:	8552                	mv	a0,s4
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	c72080e7          	jalr	-910(ra) # 80003a7c <iunlockput>
      return 0;
    80003e12:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e14:	8552                	mv	a0,s4
    80003e16:	60e6                	ld	ra,88(sp)
    80003e18:	6446                	ld	s0,80(sp)
    80003e1a:	64a6                	ld	s1,72(sp)
    80003e1c:	6906                	ld	s2,64(sp)
    80003e1e:	79e2                	ld	s3,56(sp)
    80003e20:	7a42                	ld	s4,48(sp)
    80003e22:	7aa2                	ld	s5,40(sp)
    80003e24:	7b02                	ld	s6,32(sp)
    80003e26:	6be2                	ld	s7,24(sp)
    80003e28:	6c42                	ld	s8,16(sp)
    80003e2a:	6ca2                	ld	s9,8(sp)
    80003e2c:	6d02                	ld	s10,0(sp)
    80003e2e:	6125                	addi	sp,sp,96
    80003e30:	8082                	ret
      iunlock(ip);
    80003e32:	8552                	mv	a0,s4
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	aa8080e7          	jalr	-1368(ra) # 800038dc <iunlock>
      return ip;
    80003e3c:	bfe1                	j	80003e14 <namex+0x6c>
      iunlockput(ip);
    80003e3e:	8552                	mv	a0,s4
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	c3c080e7          	jalr	-964(ra) # 80003a7c <iunlockput>
      return 0;
    80003e48:	8a4e                	mv	s4,s3
    80003e4a:	b7e9                	j	80003e14 <namex+0x6c>
  len = path - s;
    80003e4c:	40998633          	sub	a2,s3,s1
    80003e50:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e54:	09acd863          	bge	s9,s10,80003ee4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e58:	4639                	li	a2,14
    80003e5a:	85a6                	mv	a1,s1
    80003e5c:	8556                	mv	a0,s5
    80003e5e:	ffffd097          	auipc	ra,0xffffd
    80003e62:	f54080e7          	jalr	-172(ra) # 80000db2 <memmove>
    80003e66:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e68:	0004c783          	lbu	a5,0(s1)
    80003e6c:	01279763          	bne	a5,s2,80003e7a <namex+0xd2>
    path++;
    80003e70:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e72:	0004c783          	lbu	a5,0(s1)
    80003e76:	ff278de3          	beq	a5,s2,80003e70 <namex+0xc8>
    ilock(ip);
    80003e7a:	8552                	mv	a0,s4
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	99e080e7          	jalr	-1634(ra) # 8000381a <ilock>
    if(ip->type != T_DIR){
    80003e84:	044a1783          	lh	a5,68(s4)
    80003e88:	f98790e3          	bne	a5,s8,80003e08 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e8c:	000b0563          	beqz	s6,80003e96 <namex+0xee>
    80003e90:	0004c783          	lbu	a5,0(s1)
    80003e94:	dfd9                	beqz	a5,80003e32 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e96:	865e                	mv	a2,s7
    80003e98:	85d6                	mv	a1,s5
    80003e9a:	8552                	mv	a0,s4
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	e5c080e7          	jalr	-420(ra) # 80003cf8 <dirlookup>
    80003ea4:	89aa                	mv	s3,a0
    80003ea6:	dd41                	beqz	a0,80003e3e <namex+0x96>
    iunlockput(ip);
    80003ea8:	8552                	mv	a0,s4
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	bd2080e7          	jalr	-1070(ra) # 80003a7c <iunlockput>
    ip = next;
    80003eb2:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003eb4:	0004c783          	lbu	a5,0(s1)
    80003eb8:	01279763          	bne	a5,s2,80003ec6 <namex+0x11e>
    path++;
    80003ebc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ebe:	0004c783          	lbu	a5,0(s1)
    80003ec2:	ff278de3          	beq	a5,s2,80003ebc <namex+0x114>
  if(*path == 0)
    80003ec6:	cb9d                	beqz	a5,80003efc <namex+0x154>
  while(*path != '/' && *path != 0)
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	89a6                	mv	s3,s1
  len = path - s;
    80003ece:	8d5e                	mv	s10,s7
    80003ed0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ed2:	01278963          	beq	a5,s2,80003ee4 <namex+0x13c>
    80003ed6:	dbbd                	beqz	a5,80003e4c <namex+0xa4>
    path++;
    80003ed8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003eda:	0009c783          	lbu	a5,0(s3)
    80003ede:	ff279ce3          	bne	a5,s2,80003ed6 <namex+0x12e>
    80003ee2:	b7ad                	j	80003e4c <namex+0xa4>
    memmove(name, s, len);
    80003ee4:	2601                	sext.w	a2,a2
    80003ee6:	85a6                	mv	a1,s1
    80003ee8:	8556                	mv	a0,s5
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	ec8080e7          	jalr	-312(ra) # 80000db2 <memmove>
    name[len] = 0;
    80003ef2:	9d56                	add	s10,s10,s5
    80003ef4:	000d0023          	sb	zero,0(s10)
    80003ef8:	84ce                	mv	s1,s3
    80003efa:	b7bd                	j	80003e68 <namex+0xc0>
  if(nameiparent){
    80003efc:	f00b0ce3          	beqz	s6,80003e14 <namex+0x6c>
    iput(ip);
    80003f00:	8552                	mv	a0,s4
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	ad2080e7          	jalr	-1326(ra) # 800039d4 <iput>
    return 0;
    80003f0a:	4a01                	li	s4,0
    80003f0c:	b721                	j	80003e14 <namex+0x6c>

0000000080003f0e <dirlink>:
{
    80003f0e:	7139                	addi	sp,sp,-64
    80003f10:	fc06                	sd	ra,56(sp)
    80003f12:	f822                	sd	s0,48(sp)
    80003f14:	f426                	sd	s1,40(sp)
    80003f16:	f04a                	sd	s2,32(sp)
    80003f18:	ec4e                	sd	s3,24(sp)
    80003f1a:	e852                	sd	s4,16(sp)
    80003f1c:	0080                	addi	s0,sp,64
    80003f1e:	892a                	mv	s2,a0
    80003f20:	8a2e                	mv	s4,a1
    80003f22:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f24:	4601                	li	a2,0
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	dd2080e7          	jalr	-558(ra) # 80003cf8 <dirlookup>
    80003f2e:	e93d                	bnez	a0,80003fa4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f30:	04c92483          	lw	s1,76(s2)
    80003f34:	c49d                	beqz	s1,80003f62 <dirlink+0x54>
    80003f36:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f38:	4741                	li	a4,16
    80003f3a:	86a6                	mv	a3,s1
    80003f3c:	fc040613          	addi	a2,s0,-64
    80003f40:	4581                	li	a1,0
    80003f42:	854a                	mv	a0,s2
    80003f44:	00000097          	auipc	ra,0x0
    80003f48:	b8a080e7          	jalr	-1142(ra) # 80003ace <readi>
    80003f4c:	47c1                	li	a5,16
    80003f4e:	06f51163          	bne	a0,a5,80003fb0 <dirlink+0xa2>
    if(de.inum == 0)
    80003f52:	fc045783          	lhu	a5,-64(s0)
    80003f56:	c791                	beqz	a5,80003f62 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f58:	24c1                	addiw	s1,s1,16
    80003f5a:	04c92783          	lw	a5,76(s2)
    80003f5e:	fcf4ede3          	bltu	s1,a5,80003f38 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f62:	4639                	li	a2,14
    80003f64:	85d2                	mv	a1,s4
    80003f66:	fc240513          	addi	a0,s0,-62
    80003f6a:	ffffd097          	auipc	ra,0xffffd
    80003f6e:	f00080e7          	jalr	-256(ra) # 80000e6a <strncpy>
  de.inum = inum;
    80003f72:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f76:	4741                	li	a4,16
    80003f78:	86a6                	mv	a3,s1
    80003f7a:	fc040613          	addi	a2,s0,-64
    80003f7e:	4581                	li	a1,0
    80003f80:	854a                	mv	a0,s2
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	c42080e7          	jalr	-958(ra) # 80003bc4 <writei>
    80003f8a:	872a                	mv	a4,a0
    80003f8c:	47c1                	li	a5,16
  return 0;
    80003f8e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f90:	02f71863          	bne	a4,a5,80003fc0 <dirlink+0xb2>
}
    80003f94:	70e2                	ld	ra,56(sp)
    80003f96:	7442                	ld	s0,48(sp)
    80003f98:	74a2                	ld	s1,40(sp)
    80003f9a:	7902                	ld	s2,32(sp)
    80003f9c:	69e2                	ld	s3,24(sp)
    80003f9e:	6a42                	ld	s4,16(sp)
    80003fa0:	6121                	addi	sp,sp,64
    80003fa2:	8082                	ret
    iput(ip);
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	a30080e7          	jalr	-1488(ra) # 800039d4 <iput>
    return -1;
    80003fac:	557d                	li	a0,-1
    80003fae:	b7dd                	j	80003f94 <dirlink+0x86>
      panic("dirlink read");
    80003fb0:	00004517          	auipc	a0,0x4
    80003fb4:	71050513          	addi	a0,a0,1808 # 800086c0 <syscalls+0x1d8>
    80003fb8:	ffffc097          	auipc	ra,0xffffc
    80003fbc:	58e080e7          	jalr	1422(ra) # 80000546 <panic>
    panic("dirlink");
    80003fc0:	00005517          	auipc	a0,0x5
    80003fc4:	81850513          	addi	a0,a0,-2024 # 800087d8 <syscalls+0x2f0>
    80003fc8:	ffffc097          	auipc	ra,0xffffc
    80003fcc:	57e080e7          	jalr	1406(ra) # 80000546 <panic>

0000000080003fd0 <namei>:

struct inode*
namei(char *path)
{
    80003fd0:	1101                	addi	sp,sp,-32
    80003fd2:	ec06                	sd	ra,24(sp)
    80003fd4:	e822                	sd	s0,16(sp)
    80003fd6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fd8:	fe040613          	addi	a2,s0,-32
    80003fdc:	4581                	li	a1,0
    80003fde:	00000097          	auipc	ra,0x0
    80003fe2:	dca080e7          	jalr	-566(ra) # 80003da8 <namex>
}
    80003fe6:	60e2                	ld	ra,24(sp)
    80003fe8:	6442                	ld	s0,16(sp)
    80003fea:	6105                	addi	sp,sp,32
    80003fec:	8082                	ret

0000000080003fee <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fee:	1141                	addi	sp,sp,-16
    80003ff0:	e406                	sd	ra,8(sp)
    80003ff2:	e022                	sd	s0,0(sp)
    80003ff4:	0800                	addi	s0,sp,16
    80003ff6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ff8:	4585                	li	a1,1
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	dae080e7          	jalr	-594(ra) # 80003da8 <namex>
}
    80004002:	60a2                	ld	ra,8(sp)
    80004004:	6402                	ld	s0,0(sp)
    80004006:	0141                	addi	sp,sp,16
    80004008:	8082                	ret

000000008000400a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000400a:	1101                	addi	sp,sp,-32
    8000400c:	ec06                	sd	ra,24(sp)
    8000400e:	e822                	sd	s0,16(sp)
    80004010:	e426                	sd	s1,8(sp)
    80004012:	e04a                	sd	s2,0(sp)
    80004014:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004016:	0001e917          	auipc	s2,0x1e
    8000401a:	af290913          	addi	s2,s2,-1294 # 80021b08 <log>
    8000401e:	01892583          	lw	a1,24(s2)
    80004022:	02892503          	lw	a0,40(s2)
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	ff2080e7          	jalr	-14(ra) # 80003018 <bread>
    8000402e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004030:	02c92683          	lw	a3,44(s2)
    80004034:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004036:	02d05863          	blez	a3,80004066 <write_head+0x5c>
    8000403a:	0001e797          	auipc	a5,0x1e
    8000403e:	afe78793          	addi	a5,a5,-1282 # 80021b38 <log+0x30>
    80004042:	05c50713          	addi	a4,a0,92
    80004046:	36fd                	addiw	a3,a3,-1
    80004048:	02069613          	slli	a2,a3,0x20
    8000404c:	01e65693          	srli	a3,a2,0x1e
    80004050:	0001e617          	auipc	a2,0x1e
    80004054:	aec60613          	addi	a2,a2,-1300 # 80021b3c <log+0x34>
    80004058:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000405a:	4390                	lw	a2,0(a5)
    8000405c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000405e:	0791                	addi	a5,a5,4
    80004060:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004062:	fed79ce3          	bne	a5,a3,8000405a <write_head+0x50>
  }
  bwrite(buf);
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	0a2080e7          	jalr	162(ra) # 8000310a <bwrite>
  brelse(buf);
    80004070:	8526                	mv	a0,s1
    80004072:	fffff097          	auipc	ra,0xfffff
    80004076:	0d6080e7          	jalr	214(ra) # 80003148 <brelse>
}
    8000407a:	60e2                	ld	ra,24(sp)
    8000407c:	6442                	ld	s0,16(sp)
    8000407e:	64a2                	ld	s1,8(sp)
    80004080:	6902                	ld	s2,0(sp)
    80004082:	6105                	addi	sp,sp,32
    80004084:	8082                	ret

0000000080004086 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004086:	0001e797          	auipc	a5,0x1e
    8000408a:	aae7a783          	lw	a5,-1362(a5) # 80021b34 <log+0x2c>
    8000408e:	0af05663          	blez	a5,8000413a <install_trans+0xb4>
{
    80004092:	7139                	addi	sp,sp,-64
    80004094:	fc06                	sd	ra,56(sp)
    80004096:	f822                	sd	s0,48(sp)
    80004098:	f426                	sd	s1,40(sp)
    8000409a:	f04a                	sd	s2,32(sp)
    8000409c:	ec4e                	sd	s3,24(sp)
    8000409e:	e852                	sd	s4,16(sp)
    800040a0:	e456                	sd	s5,8(sp)
    800040a2:	0080                	addi	s0,sp,64
    800040a4:	0001ea97          	auipc	s5,0x1e
    800040a8:	a94a8a93          	addi	s5,s5,-1388 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040ac:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ae:	0001e997          	auipc	s3,0x1e
    800040b2:	a5a98993          	addi	s3,s3,-1446 # 80021b08 <log>
    800040b6:	0189a583          	lw	a1,24(s3)
    800040ba:	014585bb          	addw	a1,a1,s4
    800040be:	2585                	addiw	a1,a1,1
    800040c0:	0289a503          	lw	a0,40(s3)
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	f54080e7          	jalr	-172(ra) # 80003018 <bread>
    800040cc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040ce:	000aa583          	lw	a1,0(s5)
    800040d2:	0289a503          	lw	a0,40(s3)
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	f42080e7          	jalr	-190(ra) # 80003018 <bread>
    800040de:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040e0:	40000613          	li	a2,1024
    800040e4:	05890593          	addi	a1,s2,88
    800040e8:	05850513          	addi	a0,a0,88
    800040ec:	ffffd097          	auipc	ra,0xffffd
    800040f0:	cc6080e7          	jalr	-826(ra) # 80000db2 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040f4:	8526                	mv	a0,s1
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	014080e7          	jalr	20(ra) # 8000310a <bwrite>
    bunpin(dbuf);
    800040fe:	8526                	mv	a0,s1
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	122080e7          	jalr	290(ra) # 80003222 <bunpin>
    brelse(lbuf);
    80004108:	854a                	mv	a0,s2
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	03e080e7          	jalr	62(ra) # 80003148 <brelse>
    brelse(dbuf);
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	034080e7          	jalr	52(ra) # 80003148 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000411c:	2a05                	addiw	s4,s4,1
    8000411e:	0a91                	addi	s5,s5,4
    80004120:	02c9a783          	lw	a5,44(s3)
    80004124:	f8fa49e3          	blt	s4,a5,800040b6 <install_trans+0x30>
}
    80004128:	70e2                	ld	ra,56(sp)
    8000412a:	7442                	ld	s0,48(sp)
    8000412c:	74a2                	ld	s1,40(sp)
    8000412e:	7902                	ld	s2,32(sp)
    80004130:	69e2                	ld	s3,24(sp)
    80004132:	6a42                	ld	s4,16(sp)
    80004134:	6aa2                	ld	s5,8(sp)
    80004136:	6121                	addi	sp,sp,64
    80004138:	8082                	ret
    8000413a:	8082                	ret

000000008000413c <initlog>:
{
    8000413c:	7179                	addi	sp,sp,-48
    8000413e:	f406                	sd	ra,40(sp)
    80004140:	f022                	sd	s0,32(sp)
    80004142:	ec26                	sd	s1,24(sp)
    80004144:	e84a                	sd	s2,16(sp)
    80004146:	e44e                	sd	s3,8(sp)
    80004148:	1800                	addi	s0,sp,48
    8000414a:	892a                	mv	s2,a0
    8000414c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000414e:	0001e497          	auipc	s1,0x1e
    80004152:	9ba48493          	addi	s1,s1,-1606 # 80021b08 <log>
    80004156:	00004597          	auipc	a1,0x4
    8000415a:	57a58593          	addi	a1,a1,1402 # 800086d0 <syscalls+0x1e8>
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	a6a080e7          	jalr	-1430(ra) # 80000bca <initlock>
  log.start = sb->logstart;
    80004168:	0149a583          	lw	a1,20(s3)
    8000416c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000416e:	0109a783          	lw	a5,16(s3)
    80004172:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004174:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004178:	854a                	mv	a0,s2
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	e9e080e7          	jalr	-354(ra) # 80003018 <bread>
  log.lh.n = lh->n;
    80004182:	4d34                	lw	a3,88(a0)
    80004184:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004186:	02d05663          	blez	a3,800041b2 <initlog+0x76>
    8000418a:	05c50793          	addi	a5,a0,92
    8000418e:	0001e717          	auipc	a4,0x1e
    80004192:	9aa70713          	addi	a4,a4,-1622 # 80021b38 <log+0x30>
    80004196:	36fd                	addiw	a3,a3,-1
    80004198:	02069613          	slli	a2,a3,0x20
    8000419c:	01e65693          	srli	a3,a2,0x1e
    800041a0:	06050613          	addi	a2,a0,96
    800041a4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041a6:	4390                	lw	a2,0(a5)
    800041a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041aa:	0791                	addi	a5,a5,4
    800041ac:	0711                	addi	a4,a4,4
    800041ae:	fed79ce3          	bne	a5,a3,800041a6 <initlog+0x6a>
  brelse(buf);
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	f96080e7          	jalr	-106(ra) # 80003148 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041ba:	00000097          	auipc	ra,0x0
    800041be:	ecc080e7          	jalr	-308(ra) # 80004086 <install_trans>
  log.lh.n = 0;
    800041c2:	0001e797          	auipc	a5,0x1e
    800041c6:	9607a923          	sw	zero,-1678(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800041ca:	00000097          	auipc	ra,0x0
    800041ce:	e40080e7          	jalr	-448(ra) # 8000400a <write_head>
}
    800041d2:	70a2                	ld	ra,40(sp)
    800041d4:	7402                	ld	s0,32(sp)
    800041d6:	64e2                	ld	s1,24(sp)
    800041d8:	6942                	ld	s2,16(sp)
    800041da:	69a2                	ld	s3,8(sp)
    800041dc:	6145                	addi	sp,sp,48
    800041de:	8082                	ret

00000000800041e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e0:	1101                	addi	sp,sp,-32
    800041e2:	ec06                	sd	ra,24(sp)
    800041e4:	e822                	sd	s0,16(sp)
    800041e6:	e426                	sd	s1,8(sp)
    800041e8:	e04a                	sd	s2,0(sp)
    800041ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ec:	0001e517          	auipc	a0,0x1e
    800041f0:	91c50513          	addi	a0,a0,-1764 # 80021b08 <log>
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	a66080e7          	jalr	-1434(ra) # 80000c5a <acquire>
  while(1){
    if(log.committing){
    800041fc:	0001e497          	auipc	s1,0x1e
    80004200:	90c48493          	addi	s1,s1,-1780 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004204:	4979                	li	s2,30
    80004206:	a039                	j	80004214 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004208:	85a6                	mv	a1,s1
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffe097          	auipc	ra,0xffffe
    80004210:	036080e7          	jalr	54(ra) # 80002242 <sleep>
    if(log.committing){
    80004214:	50dc                	lw	a5,36(s1)
    80004216:	fbed                	bnez	a5,80004208 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004218:	5098                	lw	a4,32(s1)
    8000421a:	2705                	addiw	a4,a4,1
    8000421c:	0007069b          	sext.w	a3,a4
    80004220:	0027179b          	slliw	a5,a4,0x2
    80004224:	9fb9                	addw	a5,a5,a4
    80004226:	0017979b          	slliw	a5,a5,0x1
    8000422a:	54d8                	lw	a4,44(s1)
    8000422c:	9fb9                	addw	a5,a5,a4
    8000422e:	00f95963          	bge	s2,a5,80004240 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004232:	85a6                	mv	a1,s1
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	00c080e7          	jalr	12(ra) # 80002242 <sleep>
    8000423e:	bfd9                	j	80004214 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004240:	0001e517          	auipc	a0,0x1e
    80004244:	8c850513          	addi	a0,a0,-1848 # 80021b08 <log>
    80004248:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	ac4080e7          	jalr	-1340(ra) # 80000d0e <release>
      break;
    }
  }
}
    80004252:	60e2                	ld	ra,24(sp)
    80004254:	6442                	ld	s0,16(sp)
    80004256:	64a2                	ld	s1,8(sp)
    80004258:	6902                	ld	s2,0(sp)
    8000425a:	6105                	addi	sp,sp,32
    8000425c:	8082                	ret

000000008000425e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000425e:	7139                	addi	sp,sp,-64
    80004260:	fc06                	sd	ra,56(sp)
    80004262:	f822                	sd	s0,48(sp)
    80004264:	f426                	sd	s1,40(sp)
    80004266:	f04a                	sd	s2,32(sp)
    80004268:	ec4e                	sd	s3,24(sp)
    8000426a:	e852                	sd	s4,16(sp)
    8000426c:	e456                	sd	s5,8(sp)
    8000426e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004270:	0001e497          	auipc	s1,0x1e
    80004274:	89848493          	addi	s1,s1,-1896 # 80021b08 <log>
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	9e0080e7          	jalr	-1568(ra) # 80000c5a <acquire>
  log.outstanding -= 1;
    80004282:	509c                	lw	a5,32(s1)
    80004284:	37fd                	addiw	a5,a5,-1
    80004286:	0007891b          	sext.w	s2,a5
    8000428a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000428c:	50dc                	lw	a5,36(s1)
    8000428e:	e7b9                	bnez	a5,800042dc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004290:	04091e63          	bnez	s2,800042ec <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004294:	0001e497          	auipc	s1,0x1e
    80004298:	87448493          	addi	s1,s1,-1932 # 80021b08 <log>
    8000429c:	4785                	li	a5,1
    8000429e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffd097          	auipc	ra,0xffffd
    800042a6:	a6c080e7          	jalr	-1428(ra) # 80000d0e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042aa:	54dc                	lw	a5,44(s1)
    800042ac:	06f04763          	bgtz	a5,8000431a <end_op+0xbc>
    acquire(&log.lock);
    800042b0:	0001e497          	auipc	s1,0x1e
    800042b4:	85848493          	addi	s1,s1,-1960 # 80021b08 <log>
    800042b8:	8526                	mv	a0,s1
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	9a0080e7          	jalr	-1632(ra) # 80000c5a <acquire>
    log.committing = 0;
    800042c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffe097          	auipc	ra,0xffffe
    800042cc:	0fa080e7          	jalr	250(ra) # 800023c2 <wakeup>
    release(&log.lock);
    800042d0:	8526                	mv	a0,s1
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	a3c080e7          	jalr	-1476(ra) # 80000d0e <release>
}
    800042da:	a03d                	j	80004308 <end_op+0xaa>
    panic("log.committing");
    800042dc:	00004517          	auipc	a0,0x4
    800042e0:	3fc50513          	addi	a0,a0,1020 # 800086d8 <syscalls+0x1f0>
    800042e4:	ffffc097          	auipc	ra,0xffffc
    800042e8:	262080e7          	jalr	610(ra) # 80000546 <panic>
    wakeup(&log);
    800042ec:	0001e497          	auipc	s1,0x1e
    800042f0:	81c48493          	addi	s1,s1,-2020 # 80021b08 <log>
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffe097          	auipc	ra,0xffffe
    800042fa:	0cc080e7          	jalr	204(ra) # 800023c2 <wakeup>
  release(&log.lock);
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	a0e080e7          	jalr	-1522(ra) # 80000d0e <release>
}
    80004308:	70e2                	ld	ra,56(sp)
    8000430a:	7442                	ld	s0,48(sp)
    8000430c:	74a2                	ld	s1,40(sp)
    8000430e:	7902                	ld	s2,32(sp)
    80004310:	69e2                	ld	s3,24(sp)
    80004312:	6a42                	ld	s4,16(sp)
    80004314:	6aa2                	ld	s5,8(sp)
    80004316:	6121                	addi	sp,sp,64
    80004318:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431a:	0001ea97          	auipc	s5,0x1e
    8000431e:	81ea8a93          	addi	s5,s5,-2018 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004322:	0001da17          	auipc	s4,0x1d
    80004326:	7e6a0a13          	addi	s4,s4,2022 # 80021b08 <log>
    8000432a:	018a2583          	lw	a1,24(s4)
    8000432e:	012585bb          	addw	a1,a1,s2
    80004332:	2585                	addiw	a1,a1,1
    80004334:	028a2503          	lw	a0,40(s4)
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	ce0080e7          	jalr	-800(ra) # 80003018 <bread>
    80004340:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004342:	000aa583          	lw	a1,0(s5)
    80004346:	028a2503          	lw	a0,40(s4)
    8000434a:	fffff097          	auipc	ra,0xfffff
    8000434e:	cce080e7          	jalr	-818(ra) # 80003018 <bread>
    80004352:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004354:	40000613          	li	a2,1024
    80004358:	05850593          	addi	a1,a0,88
    8000435c:	05848513          	addi	a0,s1,88
    80004360:	ffffd097          	auipc	ra,0xffffd
    80004364:	a52080e7          	jalr	-1454(ra) # 80000db2 <memmove>
    bwrite(to);  // write the log
    80004368:	8526                	mv	a0,s1
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	da0080e7          	jalr	-608(ra) # 8000310a <bwrite>
    brelse(from);
    80004372:	854e                	mv	a0,s3
    80004374:	fffff097          	auipc	ra,0xfffff
    80004378:	dd4080e7          	jalr	-556(ra) # 80003148 <brelse>
    brelse(to);
    8000437c:	8526                	mv	a0,s1
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	dca080e7          	jalr	-566(ra) # 80003148 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004386:	2905                	addiw	s2,s2,1
    80004388:	0a91                	addi	s5,s5,4
    8000438a:	02ca2783          	lw	a5,44(s4)
    8000438e:	f8f94ee3          	blt	s2,a5,8000432a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004392:	00000097          	auipc	ra,0x0
    80004396:	c78080e7          	jalr	-904(ra) # 8000400a <write_head>
    install_trans(); // Now install writes to home locations
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	cec080e7          	jalr	-788(ra) # 80004086 <install_trans>
    log.lh.n = 0;
    800043a2:	0001d797          	auipc	a5,0x1d
    800043a6:	7807a923          	sw	zero,1938(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	c60080e7          	jalr	-928(ra) # 8000400a <write_head>
    800043b2:	bdfd                	j	800042b0 <end_op+0x52>

00000000800043b4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043b4:	1101                	addi	sp,sp,-32
    800043b6:	ec06                	sd	ra,24(sp)
    800043b8:	e822                	sd	s0,16(sp)
    800043ba:	e426                	sd	s1,8(sp)
    800043bc:	e04a                	sd	s2,0(sp)
    800043be:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043c0:	0001d717          	auipc	a4,0x1d
    800043c4:	77472703          	lw	a4,1908(a4) # 80021b34 <log+0x2c>
    800043c8:	47f5                	li	a5,29
    800043ca:	08e7c063          	blt	a5,a4,8000444a <log_write+0x96>
    800043ce:	84aa                	mv	s1,a0
    800043d0:	0001d797          	auipc	a5,0x1d
    800043d4:	7547a783          	lw	a5,1876(a5) # 80021b24 <log+0x1c>
    800043d8:	37fd                	addiw	a5,a5,-1
    800043da:	06f75863          	bge	a4,a5,8000444a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043de:	0001d797          	auipc	a5,0x1d
    800043e2:	74a7a783          	lw	a5,1866(a5) # 80021b28 <log+0x20>
    800043e6:	06f05a63          	blez	a5,8000445a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043ea:	0001d917          	auipc	s2,0x1d
    800043ee:	71e90913          	addi	s2,s2,1822 # 80021b08 <log>
    800043f2:	854a                	mv	a0,s2
    800043f4:	ffffd097          	auipc	ra,0xffffd
    800043f8:	866080e7          	jalr	-1946(ra) # 80000c5a <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043fc:	02c92603          	lw	a2,44(s2)
    80004400:	06c05563          	blez	a2,8000446a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004404:	44cc                	lw	a1,12(s1)
    80004406:	0001d717          	auipc	a4,0x1d
    8000440a:	73270713          	addi	a4,a4,1842 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000440e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004410:	4314                	lw	a3,0(a4)
    80004412:	04b68d63          	beq	a3,a1,8000446c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004416:	2785                	addiw	a5,a5,1
    80004418:	0711                	addi	a4,a4,4
    8000441a:	fec79be3          	bne	a5,a2,80004410 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000441e:	0621                	addi	a2,a2,8
    80004420:	060a                	slli	a2,a2,0x2
    80004422:	0001d797          	auipc	a5,0x1d
    80004426:	6e678793          	addi	a5,a5,1766 # 80021b08 <log>
    8000442a:	97b2                	add	a5,a5,a2
    8000442c:	44d8                	lw	a4,12(s1)
    8000442e:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	db4080e7          	jalr	-588(ra) # 800031e6 <bpin>
    log.lh.n++;
    8000443a:	0001d717          	auipc	a4,0x1d
    8000443e:	6ce70713          	addi	a4,a4,1742 # 80021b08 <log>
    80004442:	575c                	lw	a5,44(a4)
    80004444:	2785                	addiw	a5,a5,1
    80004446:	d75c                	sw	a5,44(a4)
    80004448:	a835                	j	80004484 <log_write+0xd0>
    panic("too big a transaction");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	29e50513          	addi	a0,a0,670 # 800086e8 <syscalls+0x200>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0f4080e7          	jalr	244(ra) # 80000546 <panic>
    panic("log_write outside of trans");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	2a650513          	addi	a0,a0,678 # 80008700 <syscalls+0x218>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	0e4080e7          	jalr	228(ra) # 80000546 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000446a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000446c:	00878693          	addi	a3,a5,8
    80004470:	068a                	slli	a3,a3,0x2
    80004472:	0001d717          	auipc	a4,0x1d
    80004476:	69670713          	addi	a4,a4,1686 # 80021b08 <log>
    8000447a:	9736                	add	a4,a4,a3
    8000447c:	44d4                	lw	a3,12(s1)
    8000447e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004480:	faf608e3          	beq	a2,a5,80004430 <log_write+0x7c>
  }
  release(&log.lock);
    80004484:	0001d517          	auipc	a0,0x1d
    80004488:	68450513          	addi	a0,a0,1668 # 80021b08 <log>
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	882080e7          	jalr	-1918(ra) # 80000d0e <release>
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	64a2                	ld	s1,8(sp)
    8000449a:	6902                	ld	s2,0(sp)
    8000449c:	6105                	addi	sp,sp,32
    8000449e:	8082                	ret

00000000800044a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044a0:	1101                	addi	sp,sp,-32
    800044a2:	ec06                	sd	ra,24(sp)
    800044a4:	e822                	sd	s0,16(sp)
    800044a6:	e426                	sd	s1,8(sp)
    800044a8:	e04a                	sd	s2,0(sp)
    800044aa:	1000                	addi	s0,sp,32
    800044ac:	84aa                	mv	s1,a0
    800044ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044b0:	00004597          	auipc	a1,0x4
    800044b4:	27058593          	addi	a1,a1,624 # 80008720 <syscalls+0x238>
    800044b8:	0521                	addi	a0,a0,8
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	710080e7          	jalr	1808(ra) # 80000bca <initlock>
  lk->name = name;
    800044c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ca:	0204a423          	sw	zero,40(s1)
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044da:	1101                	addi	sp,sp,-32
    800044dc:	ec06                	sd	ra,24(sp)
    800044de:	e822                	sd	s0,16(sp)
    800044e0:	e426                	sd	s1,8(sp)
    800044e2:	e04a                	sd	s2,0(sp)
    800044e4:	1000                	addi	s0,sp,32
    800044e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e8:	00850913          	addi	s2,a0,8
    800044ec:	854a                	mv	a0,s2
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	76c080e7          	jalr	1900(ra) # 80000c5a <acquire>
  while (lk->locked) {
    800044f6:	409c                	lw	a5,0(s1)
    800044f8:	cb89                	beqz	a5,8000450a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044fa:	85ca                	mv	a1,s2
    800044fc:	8526                	mv	a0,s1
    800044fe:	ffffe097          	auipc	ra,0xffffe
    80004502:	d44080e7          	jalr	-700(ra) # 80002242 <sleep>
  while (lk->locked) {
    80004506:	409c                	lw	a5,0(s1)
    80004508:	fbed                	bnez	a5,800044fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000450a:	4785                	li	a5,1
    8000450c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	518080e7          	jalr	1304(ra) # 80001a26 <myproc>
    80004516:	5d1c                	lw	a5,56(a0)
    80004518:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000451a:	854a                	mv	a0,s2
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	7f2080e7          	jalr	2034(ra) # 80000d0e <release>
}
    80004524:	60e2                	ld	ra,24(sp)
    80004526:	6442                	ld	s0,16(sp)
    80004528:	64a2                	ld	s1,8(sp)
    8000452a:	6902                	ld	s2,0(sp)
    8000452c:	6105                	addi	sp,sp,32
    8000452e:	8082                	ret

0000000080004530 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004530:	1101                	addi	sp,sp,-32
    80004532:	ec06                	sd	ra,24(sp)
    80004534:	e822                	sd	s0,16(sp)
    80004536:	e426                	sd	s1,8(sp)
    80004538:	e04a                	sd	s2,0(sp)
    8000453a:	1000                	addi	s0,sp,32
    8000453c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000453e:	00850913          	addi	s2,a0,8
    80004542:	854a                	mv	a0,s2
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	716080e7          	jalr	1814(ra) # 80000c5a <acquire>
  lk->locked = 0;
    8000454c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004550:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004554:	8526                	mv	a0,s1
    80004556:	ffffe097          	auipc	ra,0xffffe
    8000455a:	e6c080e7          	jalr	-404(ra) # 800023c2 <wakeup>
  release(&lk->lk);
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	7ae080e7          	jalr	1966(ra) # 80000d0e <release>
}
    80004568:	60e2                	ld	ra,24(sp)
    8000456a:	6442                	ld	s0,16(sp)
    8000456c:	64a2                	ld	s1,8(sp)
    8000456e:	6902                	ld	s2,0(sp)
    80004570:	6105                	addi	sp,sp,32
    80004572:	8082                	ret

0000000080004574 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004574:	7179                	addi	sp,sp,-48
    80004576:	f406                	sd	ra,40(sp)
    80004578:	f022                	sd	s0,32(sp)
    8000457a:	ec26                	sd	s1,24(sp)
    8000457c:	e84a                	sd	s2,16(sp)
    8000457e:	e44e                	sd	s3,8(sp)
    80004580:	1800                	addi	s0,sp,48
    80004582:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004584:	00850913          	addi	s2,a0,8
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	6d0080e7          	jalr	1744(ra) # 80000c5a <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004592:	409c                	lw	a5,0(s1)
    80004594:	ef99                	bnez	a5,800045b2 <holdingsleep+0x3e>
    80004596:	4481                	li	s1,0
  release(&lk->lk);
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	774080e7          	jalr	1908(ra) # 80000d0e <release>
  return r;
}
    800045a2:	8526                	mv	a0,s1
    800045a4:	70a2                	ld	ra,40(sp)
    800045a6:	7402                	ld	s0,32(sp)
    800045a8:	64e2                	ld	s1,24(sp)
    800045aa:	6942                	ld	s2,16(sp)
    800045ac:	69a2                	ld	s3,8(sp)
    800045ae:	6145                	addi	sp,sp,48
    800045b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b2:	0284a983          	lw	s3,40(s1)
    800045b6:	ffffd097          	auipc	ra,0xffffd
    800045ba:	470080e7          	jalr	1136(ra) # 80001a26 <myproc>
    800045be:	5d04                	lw	s1,56(a0)
    800045c0:	413484b3          	sub	s1,s1,s3
    800045c4:	0014b493          	seqz	s1,s1
    800045c8:	bfc1                	j	80004598 <holdingsleep+0x24>

00000000800045ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045ca:	1141                	addi	sp,sp,-16
    800045cc:	e406                	sd	ra,8(sp)
    800045ce:	e022                	sd	s0,0(sp)
    800045d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d2:	00004597          	auipc	a1,0x4
    800045d6:	15e58593          	addi	a1,a1,350 # 80008730 <syscalls+0x248>
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	67650513          	addi	a0,a0,1654 # 80021c50 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	5e8080e7          	jalr	1512(ra) # 80000bca <initlock>
}
    800045ea:	60a2                	ld	ra,8(sp)
    800045ec:	6402                	ld	s0,0(sp)
    800045ee:	0141                	addi	sp,sp,16
    800045f0:	8082                	ret

00000000800045f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f2:	1101                	addi	sp,sp,-32
    800045f4:	ec06                	sd	ra,24(sp)
    800045f6:	e822                	sd	s0,16(sp)
    800045f8:	e426                	sd	s1,8(sp)
    800045fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045fc:	0001d517          	auipc	a0,0x1d
    80004600:	65450513          	addi	a0,a0,1620 # 80021c50 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	656080e7          	jalr	1622(ra) # 80000c5a <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000460c:	0001d497          	auipc	s1,0x1d
    80004610:	65c48493          	addi	s1,s1,1628 # 80021c68 <ftable+0x18>
    80004614:	0001e717          	auipc	a4,0x1e
    80004618:	5f470713          	addi	a4,a4,1524 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000461c:	40dc                	lw	a5,4(s1)
    8000461e:	cf99                	beqz	a5,8000463c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004620:	02848493          	addi	s1,s1,40
    80004624:	fee49ce3          	bne	s1,a4,8000461c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004628:	0001d517          	auipc	a0,0x1d
    8000462c:	62850513          	addi	a0,a0,1576 # 80021c50 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	6de080e7          	jalr	1758(ra) # 80000d0e <release>
  return 0;
    80004638:	4481                	li	s1,0
    8000463a:	a819                	j	80004650 <filealloc+0x5e>
      f->ref = 1;
    8000463c:	4785                	li	a5,1
    8000463e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004640:	0001d517          	auipc	a0,0x1d
    80004644:	61050513          	addi	a0,a0,1552 # 80021c50 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	6c6080e7          	jalr	1734(ra) # 80000d0e <release>
}
    80004650:	8526                	mv	a0,s1
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret

000000008000465c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000465c:	1101                	addi	sp,sp,-32
    8000465e:	ec06                	sd	ra,24(sp)
    80004660:	e822                	sd	s0,16(sp)
    80004662:	e426                	sd	s1,8(sp)
    80004664:	1000                	addi	s0,sp,32
    80004666:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004668:	0001d517          	auipc	a0,0x1d
    8000466c:	5e850513          	addi	a0,a0,1512 # 80021c50 <ftable>
    80004670:	ffffc097          	auipc	ra,0xffffc
    80004674:	5ea080e7          	jalr	1514(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    80004678:	40dc                	lw	a5,4(s1)
    8000467a:	02f05263          	blez	a5,8000469e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000467e:	2785                	addiw	a5,a5,1
    80004680:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004682:	0001d517          	auipc	a0,0x1d
    80004686:	5ce50513          	addi	a0,a0,1486 # 80021c50 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	684080e7          	jalr	1668(ra) # 80000d0e <release>
  return f;
}
    80004692:	8526                	mv	a0,s1
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6105                	addi	sp,sp,32
    8000469c:	8082                	ret
    panic("filedup");
    8000469e:	00004517          	auipc	a0,0x4
    800046a2:	09a50513          	addi	a0,a0,154 # 80008738 <syscalls+0x250>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	ea0080e7          	jalr	-352(ra) # 80000546 <panic>

00000000800046ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ae:	7139                	addi	sp,sp,-64
    800046b0:	fc06                	sd	ra,56(sp)
    800046b2:	f822                	sd	s0,48(sp)
    800046b4:	f426                	sd	s1,40(sp)
    800046b6:	f04a                	sd	s2,32(sp)
    800046b8:	ec4e                	sd	s3,24(sp)
    800046ba:	e852                	sd	s4,16(sp)
    800046bc:	e456                	sd	s5,8(sp)
    800046be:	0080                	addi	s0,sp,64
    800046c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c2:	0001d517          	auipc	a0,0x1d
    800046c6:	58e50513          	addi	a0,a0,1422 # 80021c50 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	590080e7          	jalr	1424(ra) # 80000c5a <acquire>
  if(f->ref < 1)
    800046d2:	40dc                	lw	a5,4(s1)
    800046d4:	06f05163          	blez	a5,80004736 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046d8:	37fd                	addiw	a5,a5,-1
    800046da:	0007871b          	sext.w	a4,a5
    800046de:	c0dc                	sw	a5,4(s1)
    800046e0:	06e04363          	bgtz	a4,80004746 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046e4:	0004a903          	lw	s2,0(s1)
    800046e8:	0094ca83          	lbu	s5,9(s1)
    800046ec:	0104ba03          	ld	s4,16(s1)
    800046f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046fc:	0001d517          	auipc	a0,0x1d
    80004700:	55450513          	addi	a0,a0,1364 # 80021c50 <ftable>
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	60a080e7          	jalr	1546(ra) # 80000d0e <release>

  if(ff.type == FD_PIPE){
    8000470c:	4785                	li	a5,1
    8000470e:	04f90d63          	beq	s2,a5,80004768 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004712:	3979                	addiw	s2,s2,-2
    80004714:	4785                	li	a5,1
    80004716:	0527e063          	bltu	a5,s2,80004756 <fileclose+0xa8>
    begin_op();
    8000471a:	00000097          	auipc	ra,0x0
    8000471e:	ac6080e7          	jalr	-1338(ra) # 800041e0 <begin_op>
    iput(ff.ip);
    80004722:	854e                	mv	a0,s3
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	2b0080e7          	jalr	688(ra) # 800039d4 <iput>
    end_op();
    8000472c:	00000097          	auipc	ra,0x0
    80004730:	b32080e7          	jalr	-1230(ra) # 8000425e <end_op>
    80004734:	a00d                	j	80004756 <fileclose+0xa8>
    panic("fileclose");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	00a50513          	addi	a0,a0,10 # 80008740 <syscalls+0x258>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e08080e7          	jalr	-504(ra) # 80000546 <panic>
    release(&ftable.lock);
    80004746:	0001d517          	auipc	a0,0x1d
    8000474a:	50a50513          	addi	a0,a0,1290 # 80021c50 <ftable>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	5c0080e7          	jalr	1472(ra) # 80000d0e <release>
  }
}
    80004756:	70e2                	ld	ra,56(sp)
    80004758:	7442                	ld	s0,48(sp)
    8000475a:	74a2                	ld	s1,40(sp)
    8000475c:	7902                	ld	s2,32(sp)
    8000475e:	69e2                	ld	s3,24(sp)
    80004760:	6a42                	ld	s4,16(sp)
    80004762:	6aa2                	ld	s5,8(sp)
    80004764:	6121                	addi	sp,sp,64
    80004766:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004768:	85d6                	mv	a1,s5
    8000476a:	8552                	mv	a0,s4
    8000476c:	00000097          	auipc	ra,0x0
    80004770:	372080e7          	jalr	882(ra) # 80004ade <pipeclose>
    80004774:	b7cd                	j	80004756 <fileclose+0xa8>

0000000080004776 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004776:	715d                	addi	sp,sp,-80
    80004778:	e486                	sd	ra,72(sp)
    8000477a:	e0a2                	sd	s0,64(sp)
    8000477c:	fc26                	sd	s1,56(sp)
    8000477e:	f84a                	sd	s2,48(sp)
    80004780:	f44e                	sd	s3,40(sp)
    80004782:	0880                	addi	s0,sp,80
    80004784:	84aa                	mv	s1,a0
    80004786:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004788:	ffffd097          	auipc	ra,0xffffd
    8000478c:	29e080e7          	jalr	670(ra) # 80001a26 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004790:	409c                	lw	a5,0(s1)
    80004792:	37f9                	addiw	a5,a5,-2
    80004794:	4705                	li	a4,1
    80004796:	04f76763          	bltu	a4,a5,800047e4 <filestat+0x6e>
    8000479a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000479c:	6c88                	ld	a0,24(s1)
    8000479e:	fffff097          	auipc	ra,0xfffff
    800047a2:	07c080e7          	jalr	124(ra) # 8000381a <ilock>
    stati(f->ip, &st);
    800047a6:	fb840593          	addi	a1,s0,-72
    800047aa:	6c88                	ld	a0,24(s1)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	2f8080e7          	jalr	760(ra) # 80003aa4 <stati>
    iunlock(f->ip);
    800047b4:	6c88                	ld	a0,24(s1)
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	126080e7          	jalr	294(ra) # 800038dc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047be:	46e1                	li	a3,24
    800047c0:	fb840613          	addi	a2,s0,-72
    800047c4:	85ce                	mv	a1,s3
    800047c6:	05093503          	ld	a0,80(s2)
    800047ca:	ffffd097          	auipc	ra,0xffffd
    800047ce:	f52080e7          	jalr	-174(ra) # 8000171c <copyout>
    800047d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047d6:	60a6                	ld	ra,72(sp)
    800047d8:	6406                	ld	s0,64(sp)
    800047da:	74e2                	ld	s1,56(sp)
    800047dc:	7942                	ld	s2,48(sp)
    800047de:	79a2                	ld	s3,40(sp)
    800047e0:	6161                	addi	sp,sp,80
    800047e2:	8082                	ret
  return -1;
    800047e4:	557d                	li	a0,-1
    800047e6:	bfc5                	j	800047d6 <filestat+0x60>

00000000800047e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047e8:	7179                	addi	sp,sp,-48
    800047ea:	f406                	sd	ra,40(sp)
    800047ec:	f022                	sd	s0,32(sp)
    800047ee:	ec26                	sd	s1,24(sp)
    800047f0:	e84a                	sd	s2,16(sp)
    800047f2:	e44e                	sd	s3,8(sp)
    800047f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047f6:	00854783          	lbu	a5,8(a0)
    800047fa:	c3d5                	beqz	a5,8000489e <fileread+0xb6>
    800047fc:	84aa                	mv	s1,a0
    800047fe:	89ae                	mv	s3,a1
    80004800:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004802:	411c                	lw	a5,0(a0)
    80004804:	4705                	li	a4,1
    80004806:	04e78963          	beq	a5,a4,80004858 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000480a:	470d                	li	a4,3
    8000480c:	04e78d63          	beq	a5,a4,80004866 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004810:	4709                	li	a4,2
    80004812:	06e79e63          	bne	a5,a4,8000488e <fileread+0xa6>
    ilock(f->ip);
    80004816:	6d08                	ld	a0,24(a0)
    80004818:	fffff097          	auipc	ra,0xfffff
    8000481c:	002080e7          	jalr	2(ra) # 8000381a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004820:	874a                	mv	a4,s2
    80004822:	5094                	lw	a3,32(s1)
    80004824:	864e                	mv	a2,s3
    80004826:	4585                	li	a1,1
    80004828:	6c88                	ld	a0,24(s1)
    8000482a:	fffff097          	auipc	ra,0xfffff
    8000482e:	2a4080e7          	jalr	676(ra) # 80003ace <readi>
    80004832:	892a                	mv	s2,a0
    80004834:	00a05563          	blez	a0,8000483e <fileread+0x56>
      f->off += r;
    80004838:	509c                	lw	a5,32(s1)
    8000483a:	9fa9                	addw	a5,a5,a0
    8000483c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000483e:	6c88                	ld	a0,24(s1)
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	09c080e7          	jalr	156(ra) # 800038dc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004848:	854a                	mv	a0,s2
    8000484a:	70a2                	ld	ra,40(sp)
    8000484c:	7402                	ld	s0,32(sp)
    8000484e:	64e2                	ld	s1,24(sp)
    80004850:	6942                	ld	s2,16(sp)
    80004852:	69a2                	ld	s3,8(sp)
    80004854:	6145                	addi	sp,sp,48
    80004856:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004858:	6908                	ld	a0,16(a0)
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	3f6080e7          	jalr	1014(ra) # 80004c50 <piperead>
    80004862:	892a                	mv	s2,a0
    80004864:	b7d5                	j	80004848 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004866:	02451783          	lh	a5,36(a0)
    8000486a:	03079693          	slli	a3,a5,0x30
    8000486e:	92c1                	srli	a3,a3,0x30
    80004870:	4725                	li	a4,9
    80004872:	02d76863          	bltu	a4,a3,800048a2 <fileread+0xba>
    80004876:	0792                	slli	a5,a5,0x4
    80004878:	0001d717          	auipc	a4,0x1d
    8000487c:	33870713          	addi	a4,a4,824 # 80021bb0 <devsw>
    80004880:	97ba                	add	a5,a5,a4
    80004882:	639c                	ld	a5,0(a5)
    80004884:	c38d                	beqz	a5,800048a6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004886:	4505                	li	a0,1
    80004888:	9782                	jalr	a5
    8000488a:	892a                	mv	s2,a0
    8000488c:	bf75                	j	80004848 <fileread+0x60>
    panic("fileread");
    8000488e:	00004517          	auipc	a0,0x4
    80004892:	ec250513          	addi	a0,a0,-318 # 80008750 <syscalls+0x268>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	cb0080e7          	jalr	-848(ra) # 80000546 <panic>
    return -1;
    8000489e:	597d                	li	s2,-1
    800048a0:	b765                	j	80004848 <fileread+0x60>
      return -1;
    800048a2:	597d                	li	s2,-1
    800048a4:	b755                	j	80004848 <fileread+0x60>
    800048a6:	597d                	li	s2,-1
    800048a8:	b745                	j	80004848 <fileread+0x60>

00000000800048aa <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048aa:	00954783          	lbu	a5,9(a0)
    800048ae:	14078563          	beqz	a5,800049f8 <filewrite+0x14e>
{
    800048b2:	715d                	addi	sp,sp,-80
    800048b4:	e486                	sd	ra,72(sp)
    800048b6:	e0a2                	sd	s0,64(sp)
    800048b8:	fc26                	sd	s1,56(sp)
    800048ba:	f84a                	sd	s2,48(sp)
    800048bc:	f44e                	sd	s3,40(sp)
    800048be:	f052                	sd	s4,32(sp)
    800048c0:	ec56                	sd	s5,24(sp)
    800048c2:	e85a                	sd	s6,16(sp)
    800048c4:	e45e                	sd	s7,8(sp)
    800048c6:	e062                	sd	s8,0(sp)
    800048c8:	0880                	addi	s0,sp,80
    800048ca:	892a                	mv	s2,a0
    800048cc:	8b2e                	mv	s6,a1
    800048ce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d0:	411c                	lw	a5,0(a0)
    800048d2:	4705                	li	a4,1
    800048d4:	02e78263          	beq	a5,a4,800048f8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d8:	470d                	li	a4,3
    800048da:	02e78563          	beq	a5,a4,80004904 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048de:	4709                	li	a4,2
    800048e0:	10e79463          	bne	a5,a4,800049e8 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048e4:	0ec05e63          	blez	a2,800049e0 <filewrite+0x136>
    int i = 0;
    800048e8:	4981                	li	s3,0
    800048ea:	6b85                	lui	s7,0x1
    800048ec:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048f0:	6c05                	lui	s8,0x1
    800048f2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048f6:	a851                	j	8000498a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048f8:	6908                	ld	a0,16(a0)
    800048fa:	00000097          	auipc	ra,0x0
    800048fe:	254080e7          	jalr	596(ra) # 80004b4e <pipewrite>
    80004902:	a85d                	j	800049b8 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004904:	02451783          	lh	a5,36(a0)
    80004908:	03079693          	slli	a3,a5,0x30
    8000490c:	92c1                	srli	a3,a3,0x30
    8000490e:	4725                	li	a4,9
    80004910:	0ed76663          	bltu	a4,a3,800049fc <filewrite+0x152>
    80004914:	0792                	slli	a5,a5,0x4
    80004916:	0001d717          	auipc	a4,0x1d
    8000491a:	29a70713          	addi	a4,a4,666 # 80021bb0 <devsw>
    8000491e:	97ba                	add	a5,a5,a4
    80004920:	679c                	ld	a5,8(a5)
    80004922:	cff9                	beqz	a5,80004a00 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004924:	4505                	li	a0,1
    80004926:	9782                	jalr	a5
    80004928:	a841                	j	800049b8 <filewrite+0x10e>
    8000492a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	8b2080e7          	jalr	-1870(ra) # 800041e0 <begin_op>
      ilock(f->ip);
    80004936:	01893503          	ld	a0,24(s2)
    8000493a:	fffff097          	auipc	ra,0xfffff
    8000493e:	ee0080e7          	jalr	-288(ra) # 8000381a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004942:	8756                	mv	a4,s5
    80004944:	02092683          	lw	a3,32(s2)
    80004948:	01698633          	add	a2,s3,s6
    8000494c:	4585                	li	a1,1
    8000494e:	01893503          	ld	a0,24(s2)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	272080e7          	jalr	626(ra) # 80003bc4 <writei>
    8000495a:	84aa                	mv	s1,a0
    8000495c:	02a05f63          	blez	a0,8000499a <filewrite+0xf0>
        f->off += r;
    80004960:	02092783          	lw	a5,32(s2)
    80004964:	9fa9                	addw	a5,a5,a0
    80004966:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000496a:	01893503          	ld	a0,24(s2)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	f6e080e7          	jalr	-146(ra) # 800038dc <iunlock>
      end_op();
    80004976:	00000097          	auipc	ra,0x0
    8000497a:	8e8080e7          	jalr	-1816(ra) # 8000425e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000497e:	049a9963          	bne	s5,s1,800049d0 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004982:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004986:	0349d663          	bge	s3,s4,800049b2 <filewrite+0x108>
      int n1 = n - i;
    8000498a:	413a04bb          	subw	s1,s4,s3
    8000498e:	0004879b          	sext.w	a5,s1
    80004992:	f8fbdce3          	bge	s7,a5,8000492a <filewrite+0x80>
    80004996:	84e2                	mv	s1,s8
    80004998:	bf49                	j	8000492a <filewrite+0x80>
      iunlock(f->ip);
    8000499a:	01893503          	ld	a0,24(s2)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	f3e080e7          	jalr	-194(ra) # 800038dc <iunlock>
      end_op();
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	8b8080e7          	jalr	-1864(ra) # 8000425e <end_op>
      if(r < 0)
    800049ae:	fc04d8e3          	bgez	s1,8000497e <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049b2:	8552                	mv	a0,s4
    800049b4:	033a1863          	bne	s4,s3,800049e4 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049b8:	60a6                	ld	ra,72(sp)
    800049ba:	6406                	ld	s0,64(sp)
    800049bc:	74e2                	ld	s1,56(sp)
    800049be:	7942                	ld	s2,48(sp)
    800049c0:	79a2                	ld	s3,40(sp)
    800049c2:	7a02                	ld	s4,32(sp)
    800049c4:	6ae2                	ld	s5,24(sp)
    800049c6:	6b42                	ld	s6,16(sp)
    800049c8:	6ba2                	ld	s7,8(sp)
    800049ca:	6c02                	ld	s8,0(sp)
    800049cc:	6161                	addi	sp,sp,80
    800049ce:	8082                	ret
        panic("short filewrite");
    800049d0:	00004517          	auipc	a0,0x4
    800049d4:	d9050513          	addi	a0,a0,-624 # 80008760 <syscalls+0x278>
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	b6e080e7          	jalr	-1170(ra) # 80000546 <panic>
    int i = 0;
    800049e0:	4981                	li	s3,0
    800049e2:	bfc1                	j	800049b2 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049e4:	557d                	li	a0,-1
    800049e6:	bfc9                	j	800049b8 <filewrite+0x10e>
    panic("filewrite");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	d8850513          	addi	a0,a0,-632 # 80008770 <syscalls+0x288>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b56080e7          	jalr	-1194(ra) # 80000546 <panic>
    return -1;
    800049f8:	557d                	li	a0,-1
}
    800049fa:	8082                	ret
      return -1;
    800049fc:	557d                	li	a0,-1
    800049fe:	bf6d                	j	800049b8 <filewrite+0x10e>
    80004a00:	557d                	li	a0,-1
    80004a02:	bf5d                	j	800049b8 <filewrite+0x10e>

0000000080004a04 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a04:	7179                	addi	sp,sp,-48
    80004a06:	f406                	sd	ra,40(sp)
    80004a08:	f022                	sd	s0,32(sp)
    80004a0a:	ec26                	sd	s1,24(sp)
    80004a0c:	e84a                	sd	s2,16(sp)
    80004a0e:	e44e                	sd	s3,8(sp)
    80004a10:	e052                	sd	s4,0(sp)
    80004a12:	1800                	addi	s0,sp,48
    80004a14:	84aa                	mv	s1,a0
    80004a16:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a18:	0005b023          	sd	zero,0(a1)
    80004a1c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a20:	00000097          	auipc	ra,0x0
    80004a24:	bd2080e7          	jalr	-1070(ra) # 800045f2 <filealloc>
    80004a28:	e088                	sd	a0,0(s1)
    80004a2a:	c551                	beqz	a0,80004ab6 <pipealloc+0xb2>
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	bc6080e7          	jalr	-1082(ra) # 800045f2 <filealloc>
    80004a34:	00aa3023          	sd	a0,0(s4)
    80004a38:	c92d                	beqz	a0,80004aaa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	0d6080e7          	jalr	214(ra) # 80000b10 <kalloc>
    80004a42:	892a                	mv	s2,a0
    80004a44:	c125                	beqz	a0,80004aa4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a46:	4985                	li	s3,1
    80004a48:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a4c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a50:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a54:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a58:	00004597          	auipc	a1,0x4
    80004a5c:	9e858593          	addi	a1,a1,-1560 # 80008440 <states.0+0x198>
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	16a080e7          	jalr	362(ra) # 80000bca <initlock>
  (*f0)->type = FD_PIPE;
    80004a68:	609c                	ld	a5,0(s1)
    80004a6a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a6e:	609c                	ld	a5,0(s1)
    80004a70:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a74:	609c                	ld	a5,0(s1)
    80004a76:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a7a:	609c                	ld	a5,0(s1)
    80004a7c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a80:	000a3783          	ld	a5,0(s4)
    80004a84:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a88:	000a3783          	ld	a5,0(s4)
    80004a8c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a90:	000a3783          	ld	a5,0(s4)
    80004a94:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a98:	000a3783          	ld	a5,0(s4)
    80004a9c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aa0:	4501                	li	a0,0
    80004aa2:	a025                	j	80004aca <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aa4:	6088                	ld	a0,0(s1)
    80004aa6:	e501                	bnez	a0,80004aae <pipealloc+0xaa>
    80004aa8:	a039                	j	80004ab6 <pipealloc+0xb2>
    80004aaa:	6088                	ld	a0,0(s1)
    80004aac:	c51d                	beqz	a0,80004ada <pipealloc+0xd6>
    fileclose(*f0);
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	c00080e7          	jalr	-1024(ra) # 800046ae <fileclose>
  if(*f1)
    80004ab6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aba:	557d                	li	a0,-1
  if(*f1)
    80004abc:	c799                	beqz	a5,80004aca <pipealloc+0xc6>
    fileclose(*f1);
    80004abe:	853e                	mv	a0,a5
    80004ac0:	00000097          	auipc	ra,0x0
    80004ac4:	bee080e7          	jalr	-1042(ra) # 800046ae <fileclose>
  return -1;
    80004ac8:	557d                	li	a0,-1
}
    80004aca:	70a2                	ld	ra,40(sp)
    80004acc:	7402                	ld	s0,32(sp)
    80004ace:	64e2                	ld	s1,24(sp)
    80004ad0:	6942                	ld	s2,16(sp)
    80004ad2:	69a2                	ld	s3,8(sp)
    80004ad4:	6a02                	ld	s4,0(sp)
    80004ad6:	6145                	addi	sp,sp,48
    80004ad8:	8082                	ret
  return -1;
    80004ada:	557d                	li	a0,-1
    80004adc:	b7fd                	j	80004aca <pipealloc+0xc6>

0000000080004ade <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ade:	1101                	addi	sp,sp,-32
    80004ae0:	ec06                	sd	ra,24(sp)
    80004ae2:	e822                	sd	s0,16(sp)
    80004ae4:	e426                	sd	s1,8(sp)
    80004ae6:	e04a                	sd	s2,0(sp)
    80004ae8:	1000                	addi	s0,sp,32
    80004aea:	84aa                	mv	s1,a0
    80004aec:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	16c080e7          	jalr	364(ra) # 80000c5a <acquire>
  if(writable){
    80004af6:	02090d63          	beqz	s2,80004b30 <pipeclose+0x52>
    pi->writeopen = 0;
    80004afa:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004afe:	21848513          	addi	a0,s1,536
    80004b02:	ffffe097          	auipc	ra,0xffffe
    80004b06:	8c0080e7          	jalr	-1856(ra) # 800023c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b0a:	2204b783          	ld	a5,544(s1)
    80004b0e:	eb95                	bnez	a5,80004b42 <pipeclose+0x64>
    release(&pi->lock);
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	1fc080e7          	jalr	508(ra) # 80000d0e <release>
    kfree((char*)pi);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	ef6080e7          	jalr	-266(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    80004b24:	60e2                	ld	ra,24(sp)
    80004b26:	6442                	ld	s0,16(sp)
    80004b28:	64a2                	ld	s1,8(sp)
    80004b2a:	6902                	ld	s2,0(sp)
    80004b2c:	6105                	addi	sp,sp,32
    80004b2e:	8082                	ret
    pi->readopen = 0;
    80004b30:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b34:	21c48513          	addi	a0,s1,540
    80004b38:	ffffe097          	auipc	ra,0xffffe
    80004b3c:	88a080e7          	jalr	-1910(ra) # 800023c2 <wakeup>
    80004b40:	b7e9                	j	80004b0a <pipeclose+0x2c>
    release(&pi->lock);
    80004b42:	8526                	mv	a0,s1
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	1ca080e7          	jalr	458(ra) # 80000d0e <release>
}
    80004b4c:	bfe1                	j	80004b24 <pipeclose+0x46>

0000000080004b4e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b4e:	711d                	addi	sp,sp,-96
    80004b50:	ec86                	sd	ra,88(sp)
    80004b52:	e8a2                	sd	s0,80(sp)
    80004b54:	e4a6                	sd	s1,72(sp)
    80004b56:	e0ca                	sd	s2,64(sp)
    80004b58:	fc4e                	sd	s3,56(sp)
    80004b5a:	f852                	sd	s4,48(sp)
    80004b5c:	f456                	sd	s5,40(sp)
    80004b5e:	f05a                	sd	s6,32(sp)
    80004b60:	ec5e                	sd	s7,24(sp)
    80004b62:	e862                	sd	s8,16(sp)
    80004b64:	1080                	addi	s0,sp,96
    80004b66:	84aa                	mv	s1,a0
    80004b68:	8b2e                	mv	s6,a1
    80004b6a:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b6c:	ffffd097          	auipc	ra,0xffffd
    80004b70:	eba080e7          	jalr	-326(ra) # 80001a26 <myproc>
    80004b74:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b76:	8526                	mv	a0,s1
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	0e2080e7          	jalr	226(ra) # 80000c5a <acquire>
  for(i = 0; i < n; i++){
    80004b80:	09505863          	blez	s5,80004c10 <pipewrite+0xc2>
    80004b84:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b86:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b8a:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b8e:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b90:	2184a783          	lw	a5,536(s1)
    80004b94:	21c4a703          	lw	a4,540(s1)
    80004b98:	2007879b          	addiw	a5,a5,512
    80004b9c:	02f71b63          	bne	a4,a5,80004bd2 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004ba0:	2204a783          	lw	a5,544(s1)
    80004ba4:	c3d9                	beqz	a5,80004c2a <pipewrite+0xdc>
    80004ba6:	03092783          	lw	a5,48(s2)
    80004baa:	e3c1                	bnez	a5,80004c2a <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004bac:	8552                	mv	a0,s4
    80004bae:	ffffe097          	auipc	ra,0xffffe
    80004bb2:	814080e7          	jalr	-2028(ra) # 800023c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bb6:	85a6                	mv	a1,s1
    80004bb8:	854e                	mv	a0,s3
    80004bba:	ffffd097          	auipc	ra,0xffffd
    80004bbe:	688080e7          	jalr	1672(ra) # 80002242 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bc2:	2184a783          	lw	a5,536(s1)
    80004bc6:	21c4a703          	lw	a4,540(s1)
    80004bca:	2007879b          	addiw	a5,a5,512
    80004bce:	fcf709e3          	beq	a4,a5,80004ba0 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bd2:	4685                	li	a3,1
    80004bd4:	865a                	mv	a2,s6
    80004bd6:	faf40593          	addi	a1,s0,-81
    80004bda:	05093503          	ld	a0,80(s2)
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	bca080e7          	jalr	-1078(ra) # 800017a8 <copyin>
    80004be6:	03850663          	beq	a0,s8,80004c12 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bea:	21c4a783          	lw	a5,540(s1)
    80004bee:	0017871b          	addiw	a4,a5,1
    80004bf2:	20e4ae23          	sw	a4,540(s1)
    80004bf6:	1ff7f793          	andi	a5,a5,511
    80004bfa:	97a6                	add	a5,a5,s1
    80004bfc:	faf44703          	lbu	a4,-81(s0)
    80004c00:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c04:	2b85                	addiw	s7,s7,1
    80004c06:	0b05                	addi	s6,s6,1
    80004c08:	f97a94e3          	bne	s5,s7,80004b90 <pipewrite+0x42>
    80004c0c:	8bd6                	mv	s7,s5
    80004c0e:	a011                	j	80004c12 <pipewrite+0xc4>
    80004c10:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004c12:	21848513          	addi	a0,s1,536
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	7ac080e7          	jalr	1964(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	0ee080e7          	jalr	238(ra) # 80000d0e <release>
  return i;
    80004c28:	a039                	j	80004c36 <pipewrite+0xe8>
        release(&pi->lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	0e2080e7          	jalr	226(ra) # 80000d0e <release>
        return -1;
    80004c34:	5bfd                	li	s7,-1
}
    80004c36:	855e                	mv	a0,s7
    80004c38:	60e6                	ld	ra,88(sp)
    80004c3a:	6446                	ld	s0,80(sp)
    80004c3c:	64a6                	ld	s1,72(sp)
    80004c3e:	6906                	ld	s2,64(sp)
    80004c40:	79e2                	ld	s3,56(sp)
    80004c42:	7a42                	ld	s4,48(sp)
    80004c44:	7aa2                	ld	s5,40(sp)
    80004c46:	7b02                	ld	s6,32(sp)
    80004c48:	6be2                	ld	s7,24(sp)
    80004c4a:	6c42                	ld	s8,16(sp)
    80004c4c:	6125                	addi	sp,sp,96
    80004c4e:	8082                	ret

0000000080004c50 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c50:	715d                	addi	sp,sp,-80
    80004c52:	e486                	sd	ra,72(sp)
    80004c54:	e0a2                	sd	s0,64(sp)
    80004c56:	fc26                	sd	s1,56(sp)
    80004c58:	f84a                	sd	s2,48(sp)
    80004c5a:	f44e                	sd	s3,40(sp)
    80004c5c:	f052                	sd	s4,32(sp)
    80004c5e:	ec56                	sd	s5,24(sp)
    80004c60:	e85a                	sd	s6,16(sp)
    80004c62:	0880                	addi	s0,sp,80
    80004c64:	84aa                	mv	s1,a0
    80004c66:	892e                	mv	s2,a1
    80004c68:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	dbc080e7          	jalr	-580(ra) # 80001a26 <myproc>
    80004c72:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	fe4080e7          	jalr	-28(ra) # 80000c5a <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c7e:	2184a703          	lw	a4,536(s1)
    80004c82:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c86:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8a:	02f71463          	bne	a4,a5,80004cb2 <piperead+0x62>
    80004c8e:	2244a783          	lw	a5,548(s1)
    80004c92:	c385                	beqz	a5,80004cb2 <piperead+0x62>
    if(pr->killed){
    80004c94:	030a2783          	lw	a5,48(s4)
    80004c98:	ebc9                	bnez	a5,80004d2a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c9a:	85a6                	mv	a1,s1
    80004c9c:	854e                	mv	a0,s3
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	5a4080e7          	jalr	1444(ra) # 80002242 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca6:	2184a703          	lw	a4,536(s1)
    80004caa:	21c4a783          	lw	a5,540(s1)
    80004cae:	fef700e3          	beq	a4,a5,80004c8e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb2:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cb4:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb6:	05505463          	blez	s5,80004cfe <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004cba:	2184a783          	lw	a5,536(s1)
    80004cbe:	21c4a703          	lw	a4,540(s1)
    80004cc2:	02f70e63          	beq	a4,a5,80004cfe <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cc6:	0017871b          	addiw	a4,a5,1
    80004cca:	20e4ac23          	sw	a4,536(s1)
    80004cce:	1ff7f793          	andi	a5,a5,511
    80004cd2:	97a6                	add	a5,a5,s1
    80004cd4:	0187c783          	lbu	a5,24(a5)
    80004cd8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cdc:	4685                	li	a3,1
    80004cde:	fbf40613          	addi	a2,s0,-65
    80004ce2:	85ca                	mv	a1,s2
    80004ce4:	050a3503          	ld	a0,80(s4)
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	a34080e7          	jalr	-1484(ra) # 8000171c <copyout>
    80004cf0:	01650763          	beq	a0,s6,80004cfe <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf4:	2985                	addiw	s3,s3,1
    80004cf6:	0905                	addi	s2,s2,1
    80004cf8:	fd3a91e3          	bne	s5,s3,80004cba <piperead+0x6a>
    80004cfc:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cfe:	21c48513          	addi	a0,s1,540
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	6c0080e7          	jalr	1728(ra) # 800023c2 <wakeup>
  release(&pi->lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	002080e7          	jalr	2(ra) # 80000d0e <release>
  return i;
}
    80004d14:	854e                	mv	a0,s3
    80004d16:	60a6                	ld	ra,72(sp)
    80004d18:	6406                	ld	s0,64(sp)
    80004d1a:	74e2                	ld	s1,56(sp)
    80004d1c:	7942                	ld	s2,48(sp)
    80004d1e:	79a2                	ld	s3,40(sp)
    80004d20:	7a02                	ld	s4,32(sp)
    80004d22:	6ae2                	ld	s5,24(sp)
    80004d24:	6b42                	ld	s6,16(sp)
    80004d26:	6161                	addi	sp,sp,80
    80004d28:	8082                	ret
      release(&pi->lock);
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	ffffc097          	auipc	ra,0xffffc
    80004d30:	fe2080e7          	jalr	-30(ra) # 80000d0e <release>
      return -1;
    80004d34:	59fd                	li	s3,-1
    80004d36:	bff9                	j	80004d14 <piperead+0xc4>

0000000080004d38 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d38:	de010113          	addi	sp,sp,-544
    80004d3c:	20113c23          	sd	ra,536(sp)
    80004d40:	20813823          	sd	s0,528(sp)
    80004d44:	20913423          	sd	s1,520(sp)
    80004d48:	21213023          	sd	s2,512(sp)
    80004d4c:	ffce                	sd	s3,504(sp)
    80004d4e:	fbd2                	sd	s4,496(sp)
    80004d50:	f7d6                	sd	s5,488(sp)
    80004d52:	f3da                	sd	s6,480(sp)
    80004d54:	efde                	sd	s7,472(sp)
    80004d56:	ebe2                	sd	s8,464(sp)
    80004d58:	e7e6                	sd	s9,456(sp)
    80004d5a:	e3ea                	sd	s10,448(sp)
    80004d5c:	ff6e                	sd	s11,440(sp)
    80004d5e:	1400                	addi	s0,sp,544
    80004d60:	892a                	mv	s2,a0
    80004d62:	dea43423          	sd	a0,-536(s0)
    80004d66:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	cbc080e7          	jalr	-836(ra) # 80001a26 <myproc>
    80004d72:	84aa                	mv	s1,a0

  begin_op();
    80004d74:	fffff097          	auipc	ra,0xfffff
    80004d78:	46c080e7          	jalr	1132(ra) # 800041e0 <begin_op>

  if((ip = namei(path)) == 0){
    80004d7c:	854a                	mv	a0,s2
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	252080e7          	jalr	594(ra) # 80003fd0 <namei>
    80004d86:	c93d                	beqz	a0,80004dfc <exec+0xc4>
    80004d88:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d8a:	fffff097          	auipc	ra,0xfffff
    80004d8e:	a90080e7          	jalr	-1392(ra) # 8000381a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d92:	04000713          	li	a4,64
    80004d96:	4681                	li	a3,0
    80004d98:	e4840613          	addi	a2,s0,-440
    80004d9c:	4581                	li	a1,0
    80004d9e:	8556                	mv	a0,s5
    80004da0:	fffff097          	auipc	ra,0xfffff
    80004da4:	d2e080e7          	jalr	-722(ra) # 80003ace <readi>
    80004da8:	04000793          	li	a5,64
    80004dac:	00f51a63          	bne	a0,a5,80004dc0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004db0:	e4842703          	lw	a4,-440(s0)
    80004db4:	464c47b7          	lui	a5,0x464c4
    80004db8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dbc:	04f70663          	beq	a4,a5,80004e08 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dc0:	8556                	mv	a0,s5
    80004dc2:	fffff097          	auipc	ra,0xfffff
    80004dc6:	cba080e7          	jalr	-838(ra) # 80003a7c <iunlockput>
    end_op();
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	494080e7          	jalr	1172(ra) # 8000425e <end_op>
  }
  return -1;
    80004dd2:	557d                	li	a0,-1
}
    80004dd4:	21813083          	ld	ra,536(sp)
    80004dd8:	21013403          	ld	s0,528(sp)
    80004ddc:	20813483          	ld	s1,520(sp)
    80004de0:	20013903          	ld	s2,512(sp)
    80004de4:	79fe                	ld	s3,504(sp)
    80004de6:	7a5e                	ld	s4,496(sp)
    80004de8:	7abe                	ld	s5,488(sp)
    80004dea:	7b1e                	ld	s6,480(sp)
    80004dec:	6bfe                	ld	s7,472(sp)
    80004dee:	6c5e                	ld	s8,464(sp)
    80004df0:	6cbe                	ld	s9,456(sp)
    80004df2:	6d1e                	ld	s10,448(sp)
    80004df4:	7dfa                	ld	s11,440(sp)
    80004df6:	22010113          	addi	sp,sp,544
    80004dfa:	8082                	ret
    end_op();
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	462080e7          	jalr	1122(ra) # 8000425e <end_op>
    return -1;
    80004e04:	557d                	li	a0,-1
    80004e06:	b7f9                	j	80004dd4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffd097          	auipc	ra,0xffffd
    80004e0e:	ce0080e7          	jalr	-800(ra) # 80001aea <proc_pagetable>
    80004e12:	8b2a                	mv	s6,a0
    80004e14:	d555                	beqz	a0,80004dc0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e16:	e6842783          	lw	a5,-408(s0)
    80004e1a:	e8045703          	lhu	a4,-384(s0)
    80004e1e:	c735                	beqz	a4,80004e8a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e20:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e22:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e26:	6a05                	lui	s4,0x1
    80004e28:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e2c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e30:	6d85                	lui	s11,0x1
    80004e32:	7d7d                	lui	s10,0xfffff
    80004e34:	ac1d                	j	8000506a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e36:	00004517          	auipc	a0,0x4
    80004e3a:	94a50513          	addi	a0,a0,-1718 # 80008780 <syscalls+0x298>
    80004e3e:	ffffb097          	auipc	ra,0xffffb
    80004e42:	708080e7          	jalr	1800(ra) # 80000546 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e46:	874a                	mv	a4,s2
    80004e48:	009c86bb          	addw	a3,s9,s1
    80004e4c:	4581                	li	a1,0
    80004e4e:	8556                	mv	a0,s5
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	c7e080e7          	jalr	-898(ra) # 80003ace <readi>
    80004e58:	2501                	sext.w	a0,a0
    80004e5a:	1aa91863          	bne	s2,a0,8000500a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e5e:	009d84bb          	addw	s1,s11,s1
    80004e62:	013d09bb          	addw	s3,s10,s3
    80004e66:	1f74f263          	bgeu	s1,s7,8000504a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e6a:	02049593          	slli	a1,s1,0x20
    80004e6e:	9181                	srli	a1,a1,0x20
    80004e70:	95e2                	add	a1,a1,s8
    80004e72:	855a                	mv	a0,s6
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	270080e7          	jalr	624(ra) # 800010e4 <walkaddr>
    80004e7c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e7e:	dd45                	beqz	a0,80004e36 <exec+0xfe>
      n = PGSIZE;
    80004e80:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e82:	fd49f2e3          	bgeu	s3,s4,80004e46 <exec+0x10e>
      n = sz - i;
    80004e86:	894e                	mv	s2,s3
    80004e88:	bf7d                	j	80004e46 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e8a:	4481                	li	s1,0
  iunlockput(ip);
    80004e8c:	8556                	mv	a0,s5
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	bee080e7          	jalr	-1042(ra) # 80003a7c <iunlockput>
  end_op();
    80004e96:	fffff097          	auipc	ra,0xfffff
    80004e9a:	3c8080e7          	jalr	968(ra) # 8000425e <end_op>
  p = myproc();
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	b88080e7          	jalr	-1144(ra) # 80001a26 <myproc>
    80004ea6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004ea8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eac:	6785                	lui	a5,0x1
    80004eae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004eb0:	97a6                	add	a5,a5,s1
    80004eb2:	777d                	lui	a4,0xfffff
    80004eb4:	8ff9                	and	a5,a5,a4
    80004eb6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eba:	6609                	lui	a2,0x2
    80004ebc:	963e                	add	a2,a2,a5
    80004ebe:	85be                	mv	a1,a5
    80004ec0:	855a                	mv	a0,s6
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	606080e7          	jalr	1542(ra) # 800014c8 <uvmalloc>
    80004eca:	8c2a                	mv	s8,a0
  ip = 0;
    80004ecc:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ece:	12050e63          	beqz	a0,8000500a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ed2:	75f9                	lui	a1,0xffffe
    80004ed4:	95aa                	add	a1,a1,a0
    80004ed6:	855a                	mv	a0,s6
    80004ed8:	ffffd097          	auipc	ra,0xffffd
    80004edc:	812080e7          	jalr	-2030(ra) # 800016ea <uvmclear>
  stackbase = sp - PGSIZE;
    80004ee0:	7afd                	lui	s5,0xfffff
    80004ee2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ee4:	df043783          	ld	a5,-528(s0)
    80004ee8:	6388                	ld	a0,0(a5)
    80004eea:	c925                	beqz	a0,80004f5a <exec+0x222>
    80004eec:	e8840993          	addi	s3,s0,-376
    80004ef0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ef4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ef6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	fe2080e7          	jalr	-30(ra) # 80000eda <strlen>
    80004f00:	0015079b          	addiw	a5,a0,1
    80004f04:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f08:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f0c:	13596363          	bltu	s2,s5,80005032 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f10:	df043d83          	ld	s11,-528(s0)
    80004f14:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f18:	8552                	mv	a0,s4
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	fc0080e7          	jalr	-64(ra) # 80000eda <strlen>
    80004f22:	0015069b          	addiw	a3,a0,1
    80004f26:	8652                	mv	a2,s4
    80004f28:	85ca                	mv	a1,s2
    80004f2a:	855a                	mv	a0,s6
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	7f0080e7          	jalr	2032(ra) # 8000171c <copyout>
    80004f34:	10054363          	bltz	a0,8000503a <exec+0x302>
    ustack[argc] = sp;
    80004f38:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f3c:	0485                	addi	s1,s1,1
    80004f3e:	008d8793          	addi	a5,s11,8
    80004f42:	def43823          	sd	a5,-528(s0)
    80004f46:	008db503          	ld	a0,8(s11)
    80004f4a:	c911                	beqz	a0,80004f5e <exec+0x226>
    if(argc >= MAXARG)
    80004f4c:	09a1                	addi	s3,s3,8
    80004f4e:	fb3c95e3          	bne	s9,s3,80004ef8 <exec+0x1c0>
  sz = sz1;
    80004f52:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f56:	4a81                	li	s5,0
    80004f58:	a84d                	j	8000500a <exec+0x2d2>
  sp = sz;
    80004f5a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f5c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f5e:	00349793          	slli	a5,s1,0x3
    80004f62:	f9078793          	addi	a5,a5,-112
    80004f66:	97a2                	add	a5,a5,s0
    80004f68:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f6c:	00148693          	addi	a3,s1,1
    80004f70:	068e                	slli	a3,a3,0x3
    80004f72:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f76:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f7a:	01597663          	bgeu	s2,s5,80004f86 <exec+0x24e>
  sz = sz1;
    80004f7e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f82:	4a81                	li	s5,0
    80004f84:	a059                	j	8000500a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f86:	e8840613          	addi	a2,s0,-376
    80004f8a:	85ca                	mv	a1,s2
    80004f8c:	855a                	mv	a0,s6
    80004f8e:	ffffc097          	auipc	ra,0xffffc
    80004f92:	78e080e7          	jalr	1934(ra) # 8000171c <copyout>
    80004f96:	0a054663          	bltz	a0,80005042 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f9a:	058bb783          	ld	a5,88(s7)
    80004f9e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fa2:	de843783          	ld	a5,-536(s0)
    80004fa6:	0007c703          	lbu	a4,0(a5)
    80004faa:	cf11                	beqz	a4,80004fc6 <exec+0x28e>
    80004fac:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fae:	02f00693          	li	a3,47
    80004fb2:	a039                	j	80004fc0 <exec+0x288>
      last = s+1;
    80004fb4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004fb8:	0785                	addi	a5,a5,1
    80004fba:	fff7c703          	lbu	a4,-1(a5)
    80004fbe:	c701                	beqz	a4,80004fc6 <exec+0x28e>
    if(*s == '/')
    80004fc0:	fed71ce3          	bne	a4,a3,80004fb8 <exec+0x280>
    80004fc4:	bfc5                	j	80004fb4 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fc6:	4641                	li	a2,16
    80004fc8:	de843583          	ld	a1,-536(s0)
    80004fcc:	158b8513          	addi	a0,s7,344
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	ed8080e7          	jalr	-296(ra) # 80000ea8 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fd8:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fdc:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fe0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fe4:	058bb783          	ld	a5,88(s7)
    80004fe8:	e6043703          	ld	a4,-416(s0)
    80004fec:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fee:	058bb783          	ld	a5,88(s7)
    80004ff2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ff6:	85ea                	mv	a1,s10
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	b8e080e7          	jalr	-1138(ra) # 80001b86 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005000:	0004851b          	sext.w	a0,s1
    80005004:	bbc1                	j	80004dd4 <exec+0x9c>
    80005006:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000500a:	df843583          	ld	a1,-520(s0)
    8000500e:	855a                	mv	a0,s6
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	b76080e7          	jalr	-1162(ra) # 80001b86 <proc_freepagetable>
  if(ip){
    80005018:	da0a94e3          	bnez	s5,80004dc0 <exec+0x88>
  return -1;
    8000501c:	557d                	li	a0,-1
    8000501e:	bb5d                	j	80004dd4 <exec+0x9c>
    80005020:	de943c23          	sd	s1,-520(s0)
    80005024:	b7dd                	j	8000500a <exec+0x2d2>
    80005026:	de943c23          	sd	s1,-520(s0)
    8000502a:	b7c5                	j	8000500a <exec+0x2d2>
    8000502c:	de943c23          	sd	s1,-520(s0)
    80005030:	bfe9                	j	8000500a <exec+0x2d2>
  sz = sz1;
    80005032:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005036:	4a81                	li	s5,0
    80005038:	bfc9                	j	8000500a <exec+0x2d2>
  sz = sz1;
    8000503a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000503e:	4a81                	li	s5,0
    80005040:	b7e9                	j	8000500a <exec+0x2d2>
  sz = sz1;
    80005042:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005046:	4a81                	li	s5,0
    80005048:	b7c9                	j	8000500a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000504a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504e:	e0843783          	ld	a5,-504(s0)
    80005052:	0017869b          	addiw	a3,a5,1
    80005056:	e0d43423          	sd	a3,-504(s0)
    8000505a:	e0043783          	ld	a5,-512(s0)
    8000505e:	0387879b          	addiw	a5,a5,56
    80005062:	e8045703          	lhu	a4,-384(s0)
    80005066:	e2e6d3e3          	bge	a3,a4,80004e8c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000506a:	2781                	sext.w	a5,a5
    8000506c:	e0f43023          	sd	a5,-512(s0)
    80005070:	03800713          	li	a4,56
    80005074:	86be                	mv	a3,a5
    80005076:	e1040613          	addi	a2,s0,-496
    8000507a:	4581                	li	a1,0
    8000507c:	8556                	mv	a0,s5
    8000507e:	fffff097          	auipc	ra,0xfffff
    80005082:	a50080e7          	jalr	-1456(ra) # 80003ace <readi>
    80005086:	03800793          	li	a5,56
    8000508a:	f6f51ee3          	bne	a0,a5,80005006 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000508e:	e1042783          	lw	a5,-496(s0)
    80005092:	4705                	li	a4,1
    80005094:	fae79de3          	bne	a5,a4,8000504e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005098:	e3843603          	ld	a2,-456(s0)
    8000509c:	e3043783          	ld	a5,-464(s0)
    800050a0:	f8f660e3          	bltu	a2,a5,80005020 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050a4:	e2043783          	ld	a5,-480(s0)
    800050a8:	963e                	add	a2,a2,a5
    800050aa:	f6f66ee3          	bltu	a2,a5,80005026 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ae:	85a6                	mv	a1,s1
    800050b0:	855a                	mv	a0,s6
    800050b2:	ffffc097          	auipc	ra,0xffffc
    800050b6:	416080e7          	jalr	1046(ra) # 800014c8 <uvmalloc>
    800050ba:	dea43c23          	sd	a0,-520(s0)
    800050be:	d53d                	beqz	a0,8000502c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800050c0:	e2043c03          	ld	s8,-480(s0)
    800050c4:	de043783          	ld	a5,-544(s0)
    800050c8:	00fc77b3          	and	a5,s8,a5
    800050cc:	ff9d                	bnez	a5,8000500a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050ce:	e1842c83          	lw	s9,-488(s0)
    800050d2:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050d6:	f60b8ae3          	beqz	s7,8000504a <exec+0x312>
    800050da:	89de                	mv	s3,s7
    800050dc:	4481                	li	s1,0
    800050de:	b371                	j	80004e6a <exec+0x132>

00000000800050e0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050e0:	7179                	addi	sp,sp,-48
    800050e2:	f406                	sd	ra,40(sp)
    800050e4:	f022                	sd	s0,32(sp)
    800050e6:	ec26                	sd	s1,24(sp)
    800050e8:	e84a                	sd	s2,16(sp)
    800050ea:	1800                	addi	s0,sp,48
    800050ec:	892e                	mv	s2,a1
    800050ee:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050f0:	fdc40593          	addi	a1,s0,-36
    800050f4:	ffffe097          	auipc	ra,0xffffe
    800050f8:	b18080e7          	jalr	-1256(ra) # 80002c0c <argint>
    800050fc:	04054063          	bltz	a0,8000513c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005100:	fdc42703          	lw	a4,-36(s0)
    80005104:	47bd                	li	a5,15
    80005106:	02e7ed63          	bltu	a5,a4,80005140 <argfd+0x60>
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	91c080e7          	jalr	-1764(ra) # 80001a26 <myproc>
    80005112:	fdc42703          	lw	a4,-36(s0)
    80005116:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd901a>
    8000511a:	078e                	slli	a5,a5,0x3
    8000511c:	953e                	add	a0,a0,a5
    8000511e:	611c                	ld	a5,0(a0)
    80005120:	c395                	beqz	a5,80005144 <argfd+0x64>
    return -1;
  if(pfd)
    80005122:	00090463          	beqz	s2,8000512a <argfd+0x4a>
    *pfd = fd;
    80005126:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000512a:	4501                	li	a0,0
  if(pf)
    8000512c:	c091                	beqz	s1,80005130 <argfd+0x50>
    *pf = f;
    8000512e:	e09c                	sd	a5,0(s1)
}
    80005130:	70a2                	ld	ra,40(sp)
    80005132:	7402                	ld	s0,32(sp)
    80005134:	64e2                	ld	s1,24(sp)
    80005136:	6942                	ld	s2,16(sp)
    80005138:	6145                	addi	sp,sp,48
    8000513a:	8082                	ret
    return -1;
    8000513c:	557d                	li	a0,-1
    8000513e:	bfcd                	j	80005130 <argfd+0x50>
    return -1;
    80005140:	557d                	li	a0,-1
    80005142:	b7fd                	j	80005130 <argfd+0x50>
    80005144:	557d                	li	a0,-1
    80005146:	b7ed                	j	80005130 <argfd+0x50>

0000000080005148 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005148:	1101                	addi	sp,sp,-32
    8000514a:	ec06                	sd	ra,24(sp)
    8000514c:	e822                	sd	s0,16(sp)
    8000514e:	e426                	sd	s1,8(sp)
    80005150:	1000                	addi	s0,sp,32
    80005152:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005154:	ffffd097          	auipc	ra,0xffffd
    80005158:	8d2080e7          	jalr	-1838(ra) # 80001a26 <myproc>
    8000515c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000515e:	0d050793          	addi	a5,a0,208
    80005162:	4501                	li	a0,0
    80005164:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005166:	6398                	ld	a4,0(a5)
    80005168:	cb19                	beqz	a4,8000517e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000516a:	2505                	addiw	a0,a0,1
    8000516c:	07a1                	addi	a5,a5,8
    8000516e:	fed51ce3          	bne	a0,a3,80005166 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005172:	557d                	li	a0,-1
}
    80005174:	60e2                	ld	ra,24(sp)
    80005176:	6442                	ld	s0,16(sp)
    80005178:	64a2                	ld	s1,8(sp)
    8000517a:	6105                	addi	sp,sp,32
    8000517c:	8082                	ret
      p->ofile[fd] = f;
    8000517e:	01a50793          	addi	a5,a0,26
    80005182:	078e                	slli	a5,a5,0x3
    80005184:	963e                	add	a2,a2,a5
    80005186:	e204                	sd	s1,0(a2)
      return fd;
    80005188:	b7f5                	j	80005174 <fdalloc+0x2c>

000000008000518a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000518a:	715d                	addi	sp,sp,-80
    8000518c:	e486                	sd	ra,72(sp)
    8000518e:	e0a2                	sd	s0,64(sp)
    80005190:	fc26                	sd	s1,56(sp)
    80005192:	f84a                	sd	s2,48(sp)
    80005194:	f44e                	sd	s3,40(sp)
    80005196:	f052                	sd	s4,32(sp)
    80005198:	ec56                	sd	s5,24(sp)
    8000519a:	0880                	addi	s0,sp,80
    8000519c:	89ae                	mv	s3,a1
    8000519e:	8ab2                	mv	s5,a2
    800051a0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051a2:	fb040593          	addi	a1,s0,-80
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	e48080e7          	jalr	-440(ra) # 80003fee <nameiparent>
    800051ae:	892a                	mv	s2,a0
    800051b0:	12050e63          	beqz	a0,800052ec <create+0x162>
    return 0;

  ilock(dp);
    800051b4:	ffffe097          	auipc	ra,0xffffe
    800051b8:	666080e7          	jalr	1638(ra) # 8000381a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051bc:	4601                	li	a2,0
    800051be:	fb040593          	addi	a1,s0,-80
    800051c2:	854a                	mv	a0,s2
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	b34080e7          	jalr	-1228(ra) # 80003cf8 <dirlookup>
    800051cc:	84aa                	mv	s1,a0
    800051ce:	c921                	beqz	a0,8000521e <create+0x94>
    iunlockput(dp);
    800051d0:	854a                	mv	a0,s2
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	8aa080e7          	jalr	-1878(ra) # 80003a7c <iunlockput>
    ilock(ip);
    800051da:	8526                	mv	a0,s1
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	63e080e7          	jalr	1598(ra) # 8000381a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051e4:	2981                	sext.w	s3,s3
    800051e6:	4789                	li	a5,2
    800051e8:	02f99463          	bne	s3,a5,80005210 <create+0x86>
    800051ec:	0444d783          	lhu	a5,68(s1)
    800051f0:	37f9                	addiw	a5,a5,-2
    800051f2:	17c2                	slli	a5,a5,0x30
    800051f4:	93c1                	srli	a5,a5,0x30
    800051f6:	4705                	li	a4,1
    800051f8:	00f76c63          	bltu	a4,a5,80005210 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051fc:	8526                	mv	a0,s1
    800051fe:	60a6                	ld	ra,72(sp)
    80005200:	6406                	ld	s0,64(sp)
    80005202:	74e2                	ld	s1,56(sp)
    80005204:	7942                	ld	s2,48(sp)
    80005206:	79a2                	ld	s3,40(sp)
    80005208:	7a02                	ld	s4,32(sp)
    8000520a:	6ae2                	ld	s5,24(sp)
    8000520c:	6161                	addi	sp,sp,80
    8000520e:	8082                	ret
    iunlockput(ip);
    80005210:	8526                	mv	a0,s1
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	86a080e7          	jalr	-1942(ra) # 80003a7c <iunlockput>
    return 0;
    8000521a:	4481                	li	s1,0
    8000521c:	b7c5                	j	800051fc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000521e:	85ce                	mv	a1,s3
    80005220:	00092503          	lw	a0,0(s2)
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	45c080e7          	jalr	1116(ra) # 80003680 <ialloc>
    8000522c:	84aa                	mv	s1,a0
    8000522e:	c521                	beqz	a0,80005276 <create+0xec>
  ilock(ip);
    80005230:	ffffe097          	auipc	ra,0xffffe
    80005234:	5ea080e7          	jalr	1514(ra) # 8000381a <ilock>
  ip->major = major;
    80005238:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000523c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005240:	4a05                	li	s4,1
    80005242:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005246:	8526                	mv	a0,s1
    80005248:	ffffe097          	auipc	ra,0xffffe
    8000524c:	506080e7          	jalr	1286(ra) # 8000374e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005250:	2981                	sext.w	s3,s3
    80005252:	03498a63          	beq	s3,s4,80005286 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005256:	40d0                	lw	a2,4(s1)
    80005258:	fb040593          	addi	a1,s0,-80
    8000525c:	854a                	mv	a0,s2
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	cb0080e7          	jalr	-848(ra) # 80003f0e <dirlink>
    80005266:	06054b63          	bltz	a0,800052dc <create+0x152>
  iunlockput(dp);
    8000526a:	854a                	mv	a0,s2
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	810080e7          	jalr	-2032(ra) # 80003a7c <iunlockput>
  return ip;
    80005274:	b761                	j	800051fc <create+0x72>
    panic("create: ialloc");
    80005276:	00003517          	auipc	a0,0x3
    8000527a:	52a50513          	addi	a0,a0,1322 # 800087a0 <syscalls+0x2b8>
    8000527e:	ffffb097          	auipc	ra,0xffffb
    80005282:	2c8080e7          	jalr	712(ra) # 80000546 <panic>
    dp->nlink++;  // for ".."
    80005286:	04a95783          	lhu	a5,74(s2)
    8000528a:	2785                	addiw	a5,a5,1
    8000528c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005290:	854a                	mv	a0,s2
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	4bc080e7          	jalr	1212(ra) # 8000374e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000529a:	40d0                	lw	a2,4(s1)
    8000529c:	00003597          	auipc	a1,0x3
    800052a0:	51458593          	addi	a1,a1,1300 # 800087b0 <syscalls+0x2c8>
    800052a4:	8526                	mv	a0,s1
    800052a6:	fffff097          	auipc	ra,0xfffff
    800052aa:	c68080e7          	jalr	-920(ra) # 80003f0e <dirlink>
    800052ae:	00054f63          	bltz	a0,800052cc <create+0x142>
    800052b2:	00492603          	lw	a2,4(s2)
    800052b6:	00003597          	auipc	a1,0x3
    800052ba:	50258593          	addi	a1,a1,1282 # 800087b8 <syscalls+0x2d0>
    800052be:	8526                	mv	a0,s1
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	c4e080e7          	jalr	-946(ra) # 80003f0e <dirlink>
    800052c8:	f80557e3          	bgez	a0,80005256 <create+0xcc>
      panic("create dots");
    800052cc:	00003517          	auipc	a0,0x3
    800052d0:	4f450513          	addi	a0,a0,1268 # 800087c0 <syscalls+0x2d8>
    800052d4:	ffffb097          	auipc	ra,0xffffb
    800052d8:	272080e7          	jalr	626(ra) # 80000546 <panic>
    panic("create: dirlink");
    800052dc:	00003517          	auipc	a0,0x3
    800052e0:	4f450513          	addi	a0,a0,1268 # 800087d0 <syscalls+0x2e8>
    800052e4:	ffffb097          	auipc	ra,0xffffb
    800052e8:	262080e7          	jalr	610(ra) # 80000546 <panic>
    return 0;
    800052ec:	84aa                	mv	s1,a0
    800052ee:	b739                	j	800051fc <create+0x72>

00000000800052f0 <sys_dup>:
{
    800052f0:	7179                	addi	sp,sp,-48
    800052f2:	f406                	sd	ra,40(sp)
    800052f4:	f022                	sd	s0,32(sp)
    800052f6:	ec26                	sd	s1,24(sp)
    800052f8:	e84a                	sd	s2,16(sp)
    800052fa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052fc:	fd840613          	addi	a2,s0,-40
    80005300:	4581                	li	a1,0
    80005302:	4501                	li	a0,0
    80005304:	00000097          	auipc	ra,0x0
    80005308:	ddc080e7          	jalr	-548(ra) # 800050e0 <argfd>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000530e:	02054363          	bltz	a0,80005334 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005312:	fd843903          	ld	s2,-40(s0)
    80005316:	854a                	mv	a0,s2
    80005318:	00000097          	auipc	ra,0x0
    8000531c:	e30080e7          	jalr	-464(ra) # 80005148 <fdalloc>
    80005320:	84aa                	mv	s1,a0
    return -1;
    80005322:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005324:	00054863          	bltz	a0,80005334 <sys_dup+0x44>
  filedup(f);
    80005328:	854a                	mv	a0,s2
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	332080e7          	jalr	818(ra) # 8000465c <filedup>
  return fd;
    80005332:	87a6                	mv	a5,s1
}
    80005334:	853e                	mv	a0,a5
    80005336:	70a2                	ld	ra,40(sp)
    80005338:	7402                	ld	s0,32(sp)
    8000533a:	64e2                	ld	s1,24(sp)
    8000533c:	6942                	ld	s2,16(sp)
    8000533e:	6145                	addi	sp,sp,48
    80005340:	8082                	ret

0000000080005342 <sys_read>:
{
    80005342:	7179                	addi	sp,sp,-48
    80005344:	f406                	sd	ra,40(sp)
    80005346:	f022                	sd	s0,32(sp)
    80005348:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534a:	fe840613          	addi	a2,s0,-24
    8000534e:	4581                	li	a1,0
    80005350:	4501                	li	a0,0
    80005352:	00000097          	auipc	ra,0x0
    80005356:	d8e080e7          	jalr	-626(ra) # 800050e0 <argfd>
    return -1;
    8000535a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000535c:	04054163          	bltz	a0,8000539e <sys_read+0x5c>
    80005360:	fe440593          	addi	a1,s0,-28
    80005364:	4509                	li	a0,2
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	8a6080e7          	jalr	-1882(ra) # 80002c0c <argint>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005370:	02054763          	bltz	a0,8000539e <sys_read+0x5c>
    80005374:	fd840593          	addi	a1,s0,-40
    80005378:	4505                	li	a0,1
    8000537a:	ffffe097          	auipc	ra,0xffffe
    8000537e:	8b4080e7          	jalr	-1868(ra) # 80002c2e <argaddr>
    return -1;
    80005382:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005384:	00054d63          	bltz	a0,8000539e <sys_read+0x5c>
  return fileread(f, p, n);
    80005388:	fe442603          	lw	a2,-28(s0)
    8000538c:	fd843583          	ld	a1,-40(s0)
    80005390:	fe843503          	ld	a0,-24(s0)
    80005394:	fffff097          	auipc	ra,0xfffff
    80005398:	454080e7          	jalr	1108(ra) # 800047e8 <fileread>
    8000539c:	87aa                	mv	a5,a0
}
    8000539e:	853e                	mv	a0,a5
    800053a0:	70a2                	ld	ra,40(sp)
    800053a2:	7402                	ld	s0,32(sp)
    800053a4:	6145                	addi	sp,sp,48
    800053a6:	8082                	ret

00000000800053a8 <sys_write>:
{
    800053a8:	7179                	addi	sp,sp,-48
    800053aa:	f406                	sd	ra,40(sp)
    800053ac:	f022                	sd	s0,32(sp)
    800053ae:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b0:	fe840613          	addi	a2,s0,-24
    800053b4:	4581                	li	a1,0
    800053b6:	4501                	li	a0,0
    800053b8:	00000097          	auipc	ra,0x0
    800053bc:	d28080e7          	jalr	-728(ra) # 800050e0 <argfd>
    return -1;
    800053c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c2:	04054163          	bltz	a0,80005404 <sys_write+0x5c>
    800053c6:	fe440593          	addi	a1,s0,-28
    800053ca:	4509                	li	a0,2
    800053cc:	ffffe097          	auipc	ra,0xffffe
    800053d0:	840080e7          	jalr	-1984(ra) # 80002c0c <argint>
    return -1;
    800053d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053d6:	02054763          	bltz	a0,80005404 <sys_write+0x5c>
    800053da:	fd840593          	addi	a1,s0,-40
    800053de:	4505                	li	a0,1
    800053e0:	ffffe097          	auipc	ra,0xffffe
    800053e4:	84e080e7          	jalr	-1970(ra) # 80002c2e <argaddr>
    return -1;
    800053e8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ea:	00054d63          	bltz	a0,80005404 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053ee:	fe442603          	lw	a2,-28(s0)
    800053f2:	fd843583          	ld	a1,-40(s0)
    800053f6:	fe843503          	ld	a0,-24(s0)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	4b0080e7          	jalr	1200(ra) # 800048aa <filewrite>
    80005402:	87aa                	mv	a5,a0
}
    80005404:	853e                	mv	a0,a5
    80005406:	70a2                	ld	ra,40(sp)
    80005408:	7402                	ld	s0,32(sp)
    8000540a:	6145                	addi	sp,sp,48
    8000540c:	8082                	ret

000000008000540e <sys_close>:
{
    8000540e:	1101                	addi	sp,sp,-32
    80005410:	ec06                	sd	ra,24(sp)
    80005412:	e822                	sd	s0,16(sp)
    80005414:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005416:	fe040613          	addi	a2,s0,-32
    8000541a:	fec40593          	addi	a1,s0,-20
    8000541e:	4501                	li	a0,0
    80005420:	00000097          	auipc	ra,0x0
    80005424:	cc0080e7          	jalr	-832(ra) # 800050e0 <argfd>
    return -1;
    80005428:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000542a:	02054463          	bltz	a0,80005452 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000542e:	ffffc097          	auipc	ra,0xffffc
    80005432:	5f8080e7          	jalr	1528(ra) # 80001a26 <myproc>
    80005436:	fec42783          	lw	a5,-20(s0)
    8000543a:	07e9                	addi	a5,a5,26
    8000543c:	078e                	slli	a5,a5,0x3
    8000543e:	953e                	add	a0,a0,a5
    80005440:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005444:	fe043503          	ld	a0,-32(s0)
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	266080e7          	jalr	614(ra) # 800046ae <fileclose>
  return 0;
    80005450:	4781                	li	a5,0
}
    80005452:	853e                	mv	a0,a5
    80005454:	60e2                	ld	ra,24(sp)
    80005456:	6442                	ld	s0,16(sp)
    80005458:	6105                	addi	sp,sp,32
    8000545a:	8082                	ret

000000008000545c <sys_fstat>:
{
    8000545c:	1101                	addi	sp,sp,-32
    8000545e:	ec06                	sd	ra,24(sp)
    80005460:	e822                	sd	s0,16(sp)
    80005462:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005464:	fe840613          	addi	a2,s0,-24
    80005468:	4581                	li	a1,0
    8000546a:	4501                	li	a0,0
    8000546c:	00000097          	auipc	ra,0x0
    80005470:	c74080e7          	jalr	-908(ra) # 800050e0 <argfd>
    return -1;
    80005474:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005476:	02054563          	bltz	a0,800054a0 <sys_fstat+0x44>
    8000547a:	fe040593          	addi	a1,s0,-32
    8000547e:	4505                	li	a0,1
    80005480:	ffffd097          	auipc	ra,0xffffd
    80005484:	7ae080e7          	jalr	1966(ra) # 80002c2e <argaddr>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000548a:	00054b63          	bltz	a0,800054a0 <sys_fstat+0x44>
  return filestat(f, st);
    8000548e:	fe043583          	ld	a1,-32(s0)
    80005492:	fe843503          	ld	a0,-24(s0)
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	2e0080e7          	jalr	736(ra) # 80004776 <filestat>
    8000549e:	87aa                	mv	a5,a0
}
    800054a0:	853e                	mv	a0,a5
    800054a2:	60e2                	ld	ra,24(sp)
    800054a4:	6442                	ld	s0,16(sp)
    800054a6:	6105                	addi	sp,sp,32
    800054a8:	8082                	ret

00000000800054aa <sys_link>:
{
    800054aa:	7169                	addi	sp,sp,-304
    800054ac:	f606                	sd	ra,296(sp)
    800054ae:	f222                	sd	s0,288(sp)
    800054b0:	ee26                	sd	s1,280(sp)
    800054b2:	ea4a                	sd	s2,272(sp)
    800054b4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b6:	08000613          	li	a2,128
    800054ba:	ed040593          	addi	a1,s0,-304
    800054be:	4501                	li	a0,0
    800054c0:	ffffd097          	auipc	ra,0xffffd
    800054c4:	790080e7          	jalr	1936(ra) # 80002c50 <argstr>
    return -1;
    800054c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ca:	10054e63          	bltz	a0,800055e6 <sys_link+0x13c>
    800054ce:	08000613          	li	a2,128
    800054d2:	f5040593          	addi	a1,s0,-176
    800054d6:	4505                	li	a0,1
    800054d8:	ffffd097          	auipc	ra,0xffffd
    800054dc:	778080e7          	jalr	1912(ra) # 80002c50 <argstr>
    return -1;
    800054e0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054e2:	10054263          	bltz	a0,800055e6 <sys_link+0x13c>
  begin_op();
    800054e6:	fffff097          	auipc	ra,0xfffff
    800054ea:	cfa080e7          	jalr	-774(ra) # 800041e0 <begin_op>
  if((ip = namei(old)) == 0){
    800054ee:	ed040513          	addi	a0,s0,-304
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	ade080e7          	jalr	-1314(ra) # 80003fd0 <namei>
    800054fa:	84aa                	mv	s1,a0
    800054fc:	c551                	beqz	a0,80005588 <sys_link+0xde>
  ilock(ip);
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	31c080e7          	jalr	796(ra) # 8000381a <ilock>
  if(ip->type == T_DIR){
    80005506:	04449703          	lh	a4,68(s1)
    8000550a:	4785                	li	a5,1
    8000550c:	08f70463          	beq	a4,a5,80005594 <sys_link+0xea>
  ip->nlink++;
    80005510:	04a4d783          	lhu	a5,74(s1)
    80005514:	2785                	addiw	a5,a5,1
    80005516:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	232080e7          	jalr	562(ra) # 8000374e <iupdate>
  iunlock(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	3b6080e7          	jalr	950(ra) # 800038dc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000552e:	fd040593          	addi	a1,s0,-48
    80005532:	f5040513          	addi	a0,s0,-176
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	ab8080e7          	jalr	-1352(ra) # 80003fee <nameiparent>
    8000553e:	892a                	mv	s2,a0
    80005540:	c935                	beqz	a0,800055b4 <sys_link+0x10a>
  ilock(dp);
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	2d8080e7          	jalr	728(ra) # 8000381a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000554a:	00092703          	lw	a4,0(s2)
    8000554e:	409c                	lw	a5,0(s1)
    80005550:	04f71d63          	bne	a4,a5,800055aa <sys_link+0x100>
    80005554:	40d0                	lw	a2,4(s1)
    80005556:	fd040593          	addi	a1,s0,-48
    8000555a:	854a                	mv	a0,s2
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	9b2080e7          	jalr	-1614(ra) # 80003f0e <dirlink>
    80005564:	04054363          	bltz	a0,800055aa <sys_link+0x100>
  iunlockput(dp);
    80005568:	854a                	mv	a0,s2
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	512080e7          	jalr	1298(ra) # 80003a7c <iunlockput>
  iput(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	460080e7          	jalr	1120(ra) # 800039d4 <iput>
  end_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	ce2080e7          	jalr	-798(ra) # 8000425e <end_op>
  return 0;
    80005584:	4781                	li	a5,0
    80005586:	a085                	j	800055e6 <sys_link+0x13c>
    end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	cd6080e7          	jalr	-810(ra) # 8000425e <end_op>
    return -1;
    80005590:	57fd                	li	a5,-1
    80005592:	a891                	j	800055e6 <sys_link+0x13c>
    iunlockput(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	4e6080e7          	jalr	1254(ra) # 80003a7c <iunlockput>
    end_op();
    8000559e:	fffff097          	auipc	ra,0xfffff
    800055a2:	cc0080e7          	jalr	-832(ra) # 8000425e <end_op>
    return -1;
    800055a6:	57fd                	li	a5,-1
    800055a8:	a83d                	j	800055e6 <sys_link+0x13c>
    iunlockput(dp);
    800055aa:	854a                	mv	a0,s2
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	4d0080e7          	jalr	1232(ra) # 80003a7c <iunlockput>
  ilock(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	264080e7          	jalr	612(ra) # 8000381a <ilock>
  ip->nlink--;
    800055be:	04a4d783          	lhu	a5,74(s1)
    800055c2:	37fd                	addiw	a5,a5,-1
    800055c4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	184080e7          	jalr	388(ra) # 8000374e <iupdate>
  iunlockput(ip);
    800055d2:	8526                	mv	a0,s1
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	4a8080e7          	jalr	1192(ra) # 80003a7c <iunlockput>
  end_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	c82080e7          	jalr	-894(ra) # 8000425e <end_op>
  return -1;
    800055e4:	57fd                	li	a5,-1
}
    800055e6:	853e                	mv	a0,a5
    800055e8:	70b2                	ld	ra,296(sp)
    800055ea:	7412                	ld	s0,288(sp)
    800055ec:	64f2                	ld	s1,280(sp)
    800055ee:	6952                	ld	s2,272(sp)
    800055f0:	6155                	addi	sp,sp,304
    800055f2:	8082                	ret

00000000800055f4 <sys_unlink>:
{
    800055f4:	7151                	addi	sp,sp,-240
    800055f6:	f586                	sd	ra,232(sp)
    800055f8:	f1a2                	sd	s0,224(sp)
    800055fa:	eda6                	sd	s1,216(sp)
    800055fc:	e9ca                	sd	s2,208(sp)
    800055fe:	e5ce                	sd	s3,200(sp)
    80005600:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005602:	08000613          	li	a2,128
    80005606:	f3040593          	addi	a1,s0,-208
    8000560a:	4501                	li	a0,0
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	644080e7          	jalr	1604(ra) # 80002c50 <argstr>
    80005614:	18054163          	bltz	a0,80005796 <sys_unlink+0x1a2>
  begin_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	bc8080e7          	jalr	-1080(ra) # 800041e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005620:	fb040593          	addi	a1,s0,-80
    80005624:	f3040513          	addi	a0,s0,-208
    80005628:	fffff097          	auipc	ra,0xfffff
    8000562c:	9c6080e7          	jalr	-1594(ra) # 80003fee <nameiparent>
    80005630:	84aa                	mv	s1,a0
    80005632:	c979                	beqz	a0,80005708 <sys_unlink+0x114>
  ilock(dp);
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	1e6080e7          	jalr	486(ra) # 8000381a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000563c:	00003597          	auipc	a1,0x3
    80005640:	17458593          	addi	a1,a1,372 # 800087b0 <syscalls+0x2c8>
    80005644:	fb040513          	addi	a0,s0,-80
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	696080e7          	jalr	1686(ra) # 80003cde <namecmp>
    80005650:	14050a63          	beqz	a0,800057a4 <sys_unlink+0x1b0>
    80005654:	00003597          	auipc	a1,0x3
    80005658:	16458593          	addi	a1,a1,356 # 800087b8 <syscalls+0x2d0>
    8000565c:	fb040513          	addi	a0,s0,-80
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	67e080e7          	jalr	1662(ra) # 80003cde <namecmp>
    80005668:	12050e63          	beqz	a0,800057a4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000566c:	f2c40613          	addi	a2,s0,-212
    80005670:	fb040593          	addi	a1,s0,-80
    80005674:	8526                	mv	a0,s1
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	682080e7          	jalr	1666(ra) # 80003cf8 <dirlookup>
    8000567e:	892a                	mv	s2,a0
    80005680:	12050263          	beqz	a0,800057a4 <sys_unlink+0x1b0>
  ilock(ip);
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	196080e7          	jalr	406(ra) # 8000381a <ilock>
  if(ip->nlink < 1)
    8000568c:	04a91783          	lh	a5,74(s2)
    80005690:	08f05263          	blez	a5,80005714 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005694:	04491703          	lh	a4,68(s2)
    80005698:	4785                	li	a5,1
    8000569a:	08f70563          	beq	a4,a5,80005724 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000569e:	4641                	li	a2,16
    800056a0:	4581                	li	a1,0
    800056a2:	fc040513          	addi	a0,s0,-64
    800056a6:	ffffb097          	auipc	ra,0xffffb
    800056aa:	6b0080e7          	jalr	1712(ra) # 80000d56 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ae:	4741                	li	a4,16
    800056b0:	f2c42683          	lw	a3,-212(s0)
    800056b4:	fc040613          	addi	a2,s0,-64
    800056b8:	4581                	li	a1,0
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	508080e7          	jalr	1288(ra) # 80003bc4 <writei>
    800056c4:	47c1                	li	a5,16
    800056c6:	0af51563          	bne	a0,a5,80005770 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056ca:	04491703          	lh	a4,68(s2)
    800056ce:	4785                	li	a5,1
    800056d0:	0af70863          	beq	a4,a5,80005780 <sys_unlink+0x18c>
  iunlockput(dp);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	3a6080e7          	jalr	934(ra) # 80003a7c <iunlockput>
  ip->nlink--;
    800056de:	04a95783          	lhu	a5,74(s2)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	064080e7          	jalr	100(ra) # 8000374e <iupdate>
  iunlockput(ip);
    800056f2:	854a                	mv	a0,s2
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	388080e7          	jalr	904(ra) # 80003a7c <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	b62080e7          	jalr	-1182(ra) # 8000425e <end_op>
  return 0;
    80005704:	4501                	li	a0,0
    80005706:	a84d                	j	800057b8 <sys_unlink+0x1c4>
    end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	b56080e7          	jalr	-1194(ra) # 8000425e <end_op>
    return -1;
    80005710:	557d                	li	a0,-1
    80005712:	a05d                	j	800057b8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005714:	00003517          	auipc	a0,0x3
    80005718:	0cc50513          	addi	a0,a0,204 # 800087e0 <syscalls+0x2f8>
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	e2a080e7          	jalr	-470(ra) # 80000546 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005724:	04c92703          	lw	a4,76(s2)
    80005728:	02000793          	li	a5,32
    8000572c:	f6e7f9e3          	bgeu	a5,a4,8000569e <sys_unlink+0xaa>
    80005730:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005734:	4741                	li	a4,16
    80005736:	86ce                	mv	a3,s3
    80005738:	f1840613          	addi	a2,s0,-232
    8000573c:	4581                	li	a1,0
    8000573e:	854a                	mv	a0,s2
    80005740:	ffffe097          	auipc	ra,0xffffe
    80005744:	38e080e7          	jalr	910(ra) # 80003ace <readi>
    80005748:	47c1                	li	a5,16
    8000574a:	00f51b63          	bne	a0,a5,80005760 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000574e:	f1845783          	lhu	a5,-232(s0)
    80005752:	e7a1                	bnez	a5,8000579a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005754:	29c1                	addiw	s3,s3,16
    80005756:	04c92783          	lw	a5,76(s2)
    8000575a:	fcf9ede3          	bltu	s3,a5,80005734 <sys_unlink+0x140>
    8000575e:	b781                	j	8000569e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005760:	00003517          	auipc	a0,0x3
    80005764:	09850513          	addi	a0,a0,152 # 800087f8 <syscalls+0x310>
    80005768:	ffffb097          	auipc	ra,0xffffb
    8000576c:	dde080e7          	jalr	-546(ra) # 80000546 <panic>
    panic("unlink: writei");
    80005770:	00003517          	auipc	a0,0x3
    80005774:	0a050513          	addi	a0,a0,160 # 80008810 <syscalls+0x328>
    80005778:	ffffb097          	auipc	ra,0xffffb
    8000577c:	dce080e7          	jalr	-562(ra) # 80000546 <panic>
    dp->nlink--;
    80005780:	04a4d783          	lhu	a5,74(s1)
    80005784:	37fd                	addiw	a5,a5,-1
    80005786:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	fc2080e7          	jalr	-62(ra) # 8000374e <iupdate>
    80005794:	b781                	j	800056d4 <sys_unlink+0xe0>
    return -1;
    80005796:	557d                	li	a0,-1
    80005798:	a005                	j	800057b8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	2e0080e7          	jalr	736(ra) # 80003a7c <iunlockput>
  iunlockput(dp);
    800057a4:	8526                	mv	a0,s1
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	2d6080e7          	jalr	726(ra) # 80003a7c <iunlockput>
  end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	ab0080e7          	jalr	-1360(ra) # 8000425e <end_op>
  return -1;
    800057b6:	557d                	li	a0,-1
}
    800057b8:	70ae                	ld	ra,232(sp)
    800057ba:	740e                	ld	s0,224(sp)
    800057bc:	64ee                	ld	s1,216(sp)
    800057be:	694e                	ld	s2,208(sp)
    800057c0:	69ae                	ld	s3,200(sp)
    800057c2:	616d                	addi	sp,sp,240
    800057c4:	8082                	ret

00000000800057c6 <sys_open>:

uint64
sys_open(void)
{
    800057c6:	7131                	addi	sp,sp,-192
    800057c8:	fd06                	sd	ra,184(sp)
    800057ca:	f922                	sd	s0,176(sp)
    800057cc:	f526                	sd	s1,168(sp)
    800057ce:	f14a                	sd	s2,160(sp)
    800057d0:	ed4e                	sd	s3,152(sp)
    800057d2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d4:	08000613          	li	a2,128
    800057d8:	f5040593          	addi	a1,s0,-176
    800057dc:	4501                	li	a0,0
    800057de:	ffffd097          	auipc	ra,0xffffd
    800057e2:	472080e7          	jalr	1138(ra) # 80002c50 <argstr>
    return -1;
    800057e6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e8:	0c054163          	bltz	a0,800058aa <sys_open+0xe4>
    800057ec:	f4c40593          	addi	a1,s0,-180
    800057f0:	4505                	li	a0,1
    800057f2:	ffffd097          	auipc	ra,0xffffd
    800057f6:	41a080e7          	jalr	1050(ra) # 80002c0c <argint>
    800057fa:	0a054863          	bltz	a0,800058aa <sys_open+0xe4>

  begin_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	9e2080e7          	jalr	-1566(ra) # 800041e0 <begin_op>

  if(omode & O_CREATE){
    80005806:	f4c42783          	lw	a5,-180(s0)
    8000580a:	2007f793          	andi	a5,a5,512
    8000580e:	cbdd                	beqz	a5,800058c4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005810:	4681                	li	a3,0
    80005812:	4601                	li	a2,0
    80005814:	4589                	li	a1,2
    80005816:	f5040513          	addi	a0,s0,-176
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	970080e7          	jalr	-1680(ra) # 8000518a <create>
    80005822:	892a                	mv	s2,a0
    if(ip == 0){
    80005824:	c959                	beqz	a0,800058ba <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005826:	04491703          	lh	a4,68(s2)
    8000582a:	478d                	li	a5,3
    8000582c:	00f71763          	bne	a4,a5,8000583a <sys_open+0x74>
    80005830:	04695703          	lhu	a4,70(s2)
    80005834:	47a5                	li	a5,9
    80005836:	0ce7ec63          	bltu	a5,a4,8000590e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	db8080e7          	jalr	-584(ra) # 800045f2 <filealloc>
    80005842:	89aa                	mv	s3,a0
    80005844:	10050263          	beqz	a0,80005948 <sys_open+0x182>
    80005848:	00000097          	auipc	ra,0x0
    8000584c:	900080e7          	jalr	-1792(ra) # 80005148 <fdalloc>
    80005850:	84aa                	mv	s1,a0
    80005852:	0e054663          	bltz	a0,8000593e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005856:	04491703          	lh	a4,68(s2)
    8000585a:	478d                	li	a5,3
    8000585c:	0cf70463          	beq	a4,a5,80005924 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005860:	4789                	li	a5,2
    80005862:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005866:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000586a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000586e:	f4c42783          	lw	a5,-180(s0)
    80005872:	0017c713          	xori	a4,a5,1
    80005876:	8b05                	andi	a4,a4,1
    80005878:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000587c:	0037f713          	andi	a4,a5,3
    80005880:	00e03733          	snez	a4,a4
    80005884:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005888:	4007f793          	andi	a5,a5,1024
    8000588c:	c791                	beqz	a5,80005898 <sys_open+0xd2>
    8000588e:	04491703          	lh	a4,68(s2)
    80005892:	4789                	li	a5,2
    80005894:	08f70f63          	beq	a4,a5,80005932 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005898:	854a                	mv	a0,s2
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	042080e7          	jalr	66(ra) # 800038dc <iunlock>
  end_op();
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	9bc080e7          	jalr	-1604(ra) # 8000425e <end_op>

  return fd;
}
    800058aa:	8526                	mv	a0,s1
    800058ac:	70ea                	ld	ra,184(sp)
    800058ae:	744a                	ld	s0,176(sp)
    800058b0:	74aa                	ld	s1,168(sp)
    800058b2:	790a                	ld	s2,160(sp)
    800058b4:	69ea                	ld	s3,152(sp)
    800058b6:	6129                	addi	sp,sp,192
    800058b8:	8082                	ret
      end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	9a4080e7          	jalr	-1628(ra) # 8000425e <end_op>
      return -1;
    800058c2:	b7e5                	j	800058aa <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058c4:	f5040513          	addi	a0,s0,-176
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	708080e7          	jalr	1800(ra) # 80003fd0 <namei>
    800058d0:	892a                	mv	s2,a0
    800058d2:	c905                	beqz	a0,80005902 <sys_open+0x13c>
    ilock(ip);
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	f46080e7          	jalr	-186(ra) # 8000381a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058dc:	04491703          	lh	a4,68(s2)
    800058e0:	4785                	li	a5,1
    800058e2:	f4f712e3          	bne	a4,a5,80005826 <sys_open+0x60>
    800058e6:	f4c42783          	lw	a5,-180(s0)
    800058ea:	dba1                	beqz	a5,8000583a <sys_open+0x74>
      iunlockput(ip);
    800058ec:	854a                	mv	a0,s2
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	18e080e7          	jalr	398(ra) # 80003a7c <iunlockput>
      end_op();
    800058f6:	fffff097          	auipc	ra,0xfffff
    800058fa:	968080e7          	jalr	-1688(ra) # 8000425e <end_op>
      return -1;
    800058fe:	54fd                	li	s1,-1
    80005900:	b76d                	j	800058aa <sys_open+0xe4>
      end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	95c080e7          	jalr	-1700(ra) # 8000425e <end_op>
      return -1;
    8000590a:	54fd                	li	s1,-1
    8000590c:	bf79                	j	800058aa <sys_open+0xe4>
    iunlockput(ip);
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	16c080e7          	jalr	364(ra) # 80003a7c <iunlockput>
    end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	946080e7          	jalr	-1722(ra) # 8000425e <end_op>
    return -1;
    80005920:	54fd                	li	s1,-1
    80005922:	b761                	j	800058aa <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005924:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005928:	04691783          	lh	a5,70(s2)
    8000592c:	02f99223          	sh	a5,36(s3)
    80005930:	bf2d                	j	8000586a <sys_open+0xa4>
    itrunc(ip);
    80005932:	854a                	mv	a0,s2
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	ff4080e7          	jalr	-12(ra) # 80003928 <itrunc>
    8000593c:	bfb1                	j	80005898 <sys_open+0xd2>
      fileclose(f);
    8000593e:	854e                	mv	a0,s3
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	d6e080e7          	jalr	-658(ra) # 800046ae <fileclose>
    iunlockput(ip);
    80005948:	854a                	mv	a0,s2
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	132080e7          	jalr	306(ra) # 80003a7c <iunlockput>
    end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	90c080e7          	jalr	-1780(ra) # 8000425e <end_op>
    return -1;
    8000595a:	54fd                	li	s1,-1
    8000595c:	b7b9                	j	800058aa <sys_open+0xe4>

000000008000595e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000595e:	7175                	addi	sp,sp,-144
    80005960:	e506                	sd	ra,136(sp)
    80005962:	e122                	sd	s0,128(sp)
    80005964:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	87a080e7          	jalr	-1926(ra) # 800041e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000596e:	08000613          	li	a2,128
    80005972:	f7040593          	addi	a1,s0,-144
    80005976:	4501                	li	a0,0
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	2d8080e7          	jalr	728(ra) # 80002c50 <argstr>
    80005980:	02054963          	bltz	a0,800059b2 <sys_mkdir+0x54>
    80005984:	4681                	li	a3,0
    80005986:	4601                	li	a2,0
    80005988:	4585                	li	a1,1
    8000598a:	f7040513          	addi	a0,s0,-144
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	7fc080e7          	jalr	2044(ra) # 8000518a <create>
    80005996:	cd11                	beqz	a0,800059b2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	0e4080e7          	jalr	228(ra) # 80003a7c <iunlockput>
  end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	8be080e7          	jalr	-1858(ra) # 8000425e <end_op>
  return 0;
    800059a8:	4501                	li	a0,0
}
    800059aa:	60aa                	ld	ra,136(sp)
    800059ac:	640a                	ld	s0,128(sp)
    800059ae:	6149                	addi	sp,sp,144
    800059b0:	8082                	ret
    end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	8ac080e7          	jalr	-1876(ra) # 8000425e <end_op>
    return -1;
    800059ba:	557d                	li	a0,-1
    800059bc:	b7fd                	j	800059aa <sys_mkdir+0x4c>

00000000800059be <sys_mknod>:

uint64
sys_mknod(void)
{
    800059be:	7135                	addi	sp,sp,-160
    800059c0:	ed06                	sd	ra,152(sp)
    800059c2:	e922                	sd	s0,144(sp)
    800059c4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059c6:	fffff097          	auipc	ra,0xfffff
    800059ca:	81a080e7          	jalr	-2022(ra) # 800041e0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ce:	08000613          	li	a2,128
    800059d2:	f7040593          	addi	a1,s0,-144
    800059d6:	4501                	li	a0,0
    800059d8:	ffffd097          	auipc	ra,0xffffd
    800059dc:	278080e7          	jalr	632(ra) # 80002c50 <argstr>
    800059e0:	04054a63          	bltz	a0,80005a34 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059e4:	f6c40593          	addi	a1,s0,-148
    800059e8:	4505                	li	a0,1
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	222080e7          	jalr	546(ra) # 80002c0c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059f2:	04054163          	bltz	a0,80005a34 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059f6:	f6840593          	addi	a1,s0,-152
    800059fa:	4509                	li	a0,2
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	210080e7          	jalr	528(ra) # 80002c0c <argint>
     argint(1, &major) < 0 ||
    80005a04:	02054863          	bltz	a0,80005a34 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a08:	f6841683          	lh	a3,-152(s0)
    80005a0c:	f6c41603          	lh	a2,-148(s0)
    80005a10:	458d                	li	a1,3
    80005a12:	f7040513          	addi	a0,s0,-144
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	774080e7          	jalr	1908(ra) # 8000518a <create>
     argint(2, &minor) < 0 ||
    80005a1e:	c919                	beqz	a0,80005a34 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	05c080e7          	jalr	92(ra) # 80003a7c <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	836080e7          	jalr	-1994(ra) # 8000425e <end_op>
  return 0;
    80005a30:	4501                	li	a0,0
    80005a32:	a031                	j	80005a3e <sys_mknod+0x80>
    end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	82a080e7          	jalr	-2006(ra) # 8000425e <end_op>
    return -1;
    80005a3c:	557d                	li	a0,-1
}
    80005a3e:	60ea                	ld	ra,152(sp)
    80005a40:	644a                	ld	s0,144(sp)
    80005a42:	610d                	addi	sp,sp,160
    80005a44:	8082                	ret

0000000080005a46 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a46:	7135                	addi	sp,sp,-160
    80005a48:	ed06                	sd	ra,152(sp)
    80005a4a:	e922                	sd	s0,144(sp)
    80005a4c:	e526                	sd	s1,136(sp)
    80005a4e:	e14a                	sd	s2,128(sp)
    80005a50:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a52:	ffffc097          	auipc	ra,0xffffc
    80005a56:	fd4080e7          	jalr	-44(ra) # 80001a26 <myproc>
    80005a5a:	892a                	mv	s2,a0
  
  begin_op();
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	784080e7          	jalr	1924(ra) # 800041e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a64:	08000613          	li	a2,128
    80005a68:	f6040593          	addi	a1,s0,-160
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	1e2080e7          	jalr	482(ra) # 80002c50 <argstr>
    80005a76:	04054b63          	bltz	a0,80005acc <sys_chdir+0x86>
    80005a7a:	f6040513          	addi	a0,s0,-160
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	552080e7          	jalr	1362(ra) # 80003fd0 <namei>
    80005a86:	84aa                	mv	s1,a0
    80005a88:	c131                	beqz	a0,80005acc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	d90080e7          	jalr	-624(ra) # 8000381a <ilock>
  if(ip->type != T_DIR){
    80005a92:	04449703          	lh	a4,68(s1)
    80005a96:	4785                	li	a5,1
    80005a98:	04f71063          	bne	a4,a5,80005ad8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	e3e080e7          	jalr	-450(ra) # 800038dc <iunlock>
  iput(p->cwd);
    80005aa6:	15093503          	ld	a0,336(s2)
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	f2a080e7          	jalr	-214(ra) # 800039d4 <iput>
  end_op();
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	7ac080e7          	jalr	1964(ra) # 8000425e <end_op>
  p->cwd = ip;
    80005aba:	14993823          	sd	s1,336(s2)
  return 0;
    80005abe:	4501                	li	a0,0
}
    80005ac0:	60ea                	ld	ra,152(sp)
    80005ac2:	644a                	ld	s0,144(sp)
    80005ac4:	64aa                	ld	s1,136(sp)
    80005ac6:	690a                	ld	s2,128(sp)
    80005ac8:	610d                	addi	sp,sp,160
    80005aca:	8082                	ret
    end_op();
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	792080e7          	jalr	1938(ra) # 8000425e <end_op>
    return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	b7ed                	j	80005ac0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	fa2080e7          	jalr	-94(ra) # 80003a7c <iunlockput>
    end_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	77c080e7          	jalr	1916(ra) # 8000425e <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
    80005aec:	bfd1                	j	80005ac0 <sys_chdir+0x7a>

0000000080005aee <sys_exec>:

uint64
sys_exec(void)
{
    80005aee:	7145                	addi	sp,sp,-464
    80005af0:	e786                	sd	ra,456(sp)
    80005af2:	e3a2                	sd	s0,448(sp)
    80005af4:	ff26                	sd	s1,440(sp)
    80005af6:	fb4a                	sd	s2,432(sp)
    80005af8:	f74e                	sd	s3,424(sp)
    80005afa:	f352                	sd	s4,416(sp)
    80005afc:	ef56                	sd	s5,408(sp)
    80005afe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b00:	08000613          	li	a2,128
    80005b04:	f4040593          	addi	a1,s0,-192
    80005b08:	4501                	li	a0,0
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	146080e7          	jalr	326(ra) # 80002c50 <argstr>
    return -1;
    80005b12:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b14:	0c054b63          	bltz	a0,80005bea <sys_exec+0xfc>
    80005b18:	e3840593          	addi	a1,s0,-456
    80005b1c:	4505                	li	a0,1
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	110080e7          	jalr	272(ra) # 80002c2e <argaddr>
    80005b26:	0c054263          	bltz	a0,80005bea <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b2a:	10000613          	li	a2,256
    80005b2e:	4581                	li	a1,0
    80005b30:	e4040513          	addi	a0,s0,-448
    80005b34:	ffffb097          	auipc	ra,0xffffb
    80005b38:	222080e7          	jalr	546(ra) # 80000d56 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b3c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b40:	89a6                	mv	s3,s1
    80005b42:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b44:	02000a13          	li	s4,32
    80005b48:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b4c:	00391513          	slli	a0,s2,0x3
    80005b50:	e3040593          	addi	a1,s0,-464
    80005b54:	e3843783          	ld	a5,-456(s0)
    80005b58:	953e                	add	a0,a0,a5
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	018080e7          	jalr	24(ra) # 80002b72 <fetchaddr>
    80005b62:	02054a63          	bltz	a0,80005b96 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b66:	e3043783          	ld	a5,-464(s0)
    80005b6a:	c3b9                	beqz	a5,80005bb0 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b6c:	ffffb097          	auipc	ra,0xffffb
    80005b70:	fa4080e7          	jalr	-92(ra) # 80000b10 <kalloc>
    80005b74:	85aa                	mv	a1,a0
    80005b76:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b7a:	cd11                	beqz	a0,80005b96 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b7c:	6605                	lui	a2,0x1
    80005b7e:	e3043503          	ld	a0,-464(s0)
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	042080e7          	jalr	66(ra) # 80002bc4 <fetchstr>
    80005b8a:	00054663          	bltz	a0,80005b96 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b8e:	0905                	addi	s2,s2,1
    80005b90:	09a1                	addi	s3,s3,8
    80005b92:	fb491be3          	bne	s2,s4,80005b48 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b96:	f4040913          	addi	s2,s0,-192
    80005b9a:	6088                	ld	a0,0(s1)
    80005b9c:	c531                	beqz	a0,80005be8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b9e:	ffffb097          	auipc	ra,0xffffb
    80005ba2:	e74080e7          	jalr	-396(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba6:	04a1                	addi	s1,s1,8
    80005ba8:	ff2499e3          	bne	s1,s2,80005b9a <sys_exec+0xac>
  return -1;
    80005bac:	597d                	li	s2,-1
    80005bae:	a835                	j	80005bea <sys_exec+0xfc>
      argv[i] = 0;
    80005bb0:	0a8e                	slli	s5,s5,0x3
    80005bb2:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd8fc0>
    80005bb6:	00878ab3          	add	s5,a5,s0
    80005bba:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bbe:	e4040593          	addi	a1,s0,-448
    80005bc2:	f4040513          	addi	a0,s0,-192
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	172080e7          	jalr	370(ra) # 80004d38 <exec>
    80005bce:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	f4040993          	addi	s3,s0,-192
    80005bd4:	6088                	ld	a0,0(s1)
    80005bd6:	c911                	beqz	a0,80005bea <sys_exec+0xfc>
    kfree(argv[i]);
    80005bd8:	ffffb097          	auipc	ra,0xffffb
    80005bdc:	e3a080e7          	jalr	-454(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be0:	04a1                	addi	s1,s1,8
    80005be2:	ff3499e3          	bne	s1,s3,80005bd4 <sys_exec+0xe6>
    80005be6:	a011                	j	80005bea <sys_exec+0xfc>
  return -1;
    80005be8:	597d                	li	s2,-1
}
    80005bea:	854a                	mv	a0,s2
    80005bec:	60be                	ld	ra,456(sp)
    80005bee:	641e                	ld	s0,448(sp)
    80005bf0:	74fa                	ld	s1,440(sp)
    80005bf2:	795a                	ld	s2,432(sp)
    80005bf4:	79ba                	ld	s3,424(sp)
    80005bf6:	7a1a                	ld	s4,416(sp)
    80005bf8:	6afa                	ld	s5,408(sp)
    80005bfa:	6179                	addi	sp,sp,464
    80005bfc:	8082                	ret

0000000080005bfe <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bfe:	7139                	addi	sp,sp,-64
    80005c00:	fc06                	sd	ra,56(sp)
    80005c02:	f822                	sd	s0,48(sp)
    80005c04:	f426                	sd	s1,40(sp)
    80005c06:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c08:	ffffc097          	auipc	ra,0xffffc
    80005c0c:	e1e080e7          	jalr	-482(ra) # 80001a26 <myproc>
    80005c10:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c12:	fd840593          	addi	a1,s0,-40
    80005c16:	4501                	li	a0,0
    80005c18:	ffffd097          	auipc	ra,0xffffd
    80005c1c:	016080e7          	jalr	22(ra) # 80002c2e <argaddr>
    return -1;
    80005c20:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c22:	0e054063          	bltz	a0,80005d02 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c26:	fc840593          	addi	a1,s0,-56
    80005c2a:	fd040513          	addi	a0,s0,-48
    80005c2e:	fffff097          	auipc	ra,0xfffff
    80005c32:	dd6080e7          	jalr	-554(ra) # 80004a04 <pipealloc>
    return -1;
    80005c36:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c38:	0c054563          	bltz	a0,80005d02 <sys_pipe+0x104>
  fd0 = -1;
    80005c3c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c40:	fd043503          	ld	a0,-48(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	504080e7          	jalr	1284(ra) # 80005148 <fdalloc>
    80005c4c:	fca42223          	sw	a0,-60(s0)
    80005c50:	08054c63          	bltz	a0,80005ce8 <sys_pipe+0xea>
    80005c54:	fc843503          	ld	a0,-56(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	4f0080e7          	jalr	1264(ra) # 80005148 <fdalloc>
    80005c60:	fca42023          	sw	a0,-64(s0)
    80005c64:	06054963          	bltz	a0,80005cd6 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c68:	4691                	li	a3,4
    80005c6a:	fc440613          	addi	a2,s0,-60
    80005c6e:	fd843583          	ld	a1,-40(s0)
    80005c72:	68a8                	ld	a0,80(s1)
    80005c74:	ffffc097          	auipc	ra,0xffffc
    80005c78:	aa8080e7          	jalr	-1368(ra) # 8000171c <copyout>
    80005c7c:	02054063          	bltz	a0,80005c9c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c80:	4691                	li	a3,4
    80005c82:	fc040613          	addi	a2,s0,-64
    80005c86:	fd843583          	ld	a1,-40(s0)
    80005c8a:	0591                	addi	a1,a1,4
    80005c8c:	68a8                	ld	a0,80(s1)
    80005c8e:	ffffc097          	auipc	ra,0xffffc
    80005c92:	a8e080e7          	jalr	-1394(ra) # 8000171c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c96:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c98:	06055563          	bgez	a0,80005d02 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c9c:	fc442783          	lw	a5,-60(s0)
    80005ca0:	07e9                	addi	a5,a5,26
    80005ca2:	078e                	slli	a5,a5,0x3
    80005ca4:	97a6                	add	a5,a5,s1
    80005ca6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005caa:	fc042783          	lw	a5,-64(s0)
    80005cae:	07e9                	addi	a5,a5,26
    80005cb0:	078e                	slli	a5,a5,0x3
    80005cb2:	00f48533          	add	a0,s1,a5
    80005cb6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cba:	fd043503          	ld	a0,-48(s0)
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	9f0080e7          	jalr	-1552(ra) # 800046ae <fileclose>
    fileclose(wf);
    80005cc6:	fc843503          	ld	a0,-56(s0)
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	9e4080e7          	jalr	-1564(ra) # 800046ae <fileclose>
    return -1;
    80005cd2:	57fd                	li	a5,-1
    80005cd4:	a03d                	j	80005d02 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cd6:	fc442783          	lw	a5,-60(s0)
    80005cda:	0007c763          	bltz	a5,80005ce8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cde:	07e9                	addi	a5,a5,26
    80005ce0:	078e                	slli	a5,a5,0x3
    80005ce2:	97a6                	add	a5,a5,s1
    80005ce4:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005ce8:	fd043503          	ld	a0,-48(s0)
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	9c2080e7          	jalr	-1598(ra) # 800046ae <fileclose>
    fileclose(wf);
    80005cf4:	fc843503          	ld	a0,-56(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	9b6080e7          	jalr	-1610(ra) # 800046ae <fileclose>
    return -1;
    80005d00:	57fd                	li	a5,-1
}
    80005d02:	853e                	mv	a0,a5
    80005d04:	70e2                	ld	ra,56(sp)
    80005d06:	7442                	ld	s0,48(sp)
    80005d08:	74a2                	ld	s1,40(sp)
    80005d0a:	6121                	addi	sp,sp,64
    80005d0c:	8082                	ret
	...

0000000080005d10 <kernelvec>:
    80005d10:	7111                	addi	sp,sp,-256
    80005d12:	e006                	sd	ra,0(sp)
    80005d14:	e40a                	sd	sp,8(sp)
    80005d16:	e80e                	sd	gp,16(sp)
    80005d18:	ec12                	sd	tp,24(sp)
    80005d1a:	f016                	sd	t0,32(sp)
    80005d1c:	f41a                	sd	t1,40(sp)
    80005d1e:	f81e                	sd	t2,48(sp)
    80005d20:	fc22                	sd	s0,56(sp)
    80005d22:	e0a6                	sd	s1,64(sp)
    80005d24:	e4aa                	sd	a0,72(sp)
    80005d26:	e8ae                	sd	a1,80(sp)
    80005d28:	ecb2                	sd	a2,88(sp)
    80005d2a:	f0b6                	sd	a3,96(sp)
    80005d2c:	f4ba                	sd	a4,104(sp)
    80005d2e:	f8be                	sd	a5,112(sp)
    80005d30:	fcc2                	sd	a6,120(sp)
    80005d32:	e146                	sd	a7,128(sp)
    80005d34:	e54a                	sd	s2,136(sp)
    80005d36:	e94e                	sd	s3,144(sp)
    80005d38:	ed52                	sd	s4,152(sp)
    80005d3a:	f156                	sd	s5,160(sp)
    80005d3c:	f55a                	sd	s6,168(sp)
    80005d3e:	f95e                	sd	s7,176(sp)
    80005d40:	fd62                	sd	s8,184(sp)
    80005d42:	e1e6                	sd	s9,192(sp)
    80005d44:	e5ea                	sd	s10,200(sp)
    80005d46:	e9ee                	sd	s11,208(sp)
    80005d48:	edf2                	sd	t3,216(sp)
    80005d4a:	f1f6                	sd	t4,224(sp)
    80005d4c:	f5fa                	sd	t5,232(sp)
    80005d4e:	f9fe                	sd	t6,240(sp)
    80005d50:	ceffc0ef          	jal	ra,80002a3e <kerneltrap>
    80005d54:	6082                	ld	ra,0(sp)
    80005d56:	6122                	ld	sp,8(sp)
    80005d58:	61c2                	ld	gp,16(sp)
    80005d5a:	7282                	ld	t0,32(sp)
    80005d5c:	7322                	ld	t1,40(sp)
    80005d5e:	73c2                	ld	t2,48(sp)
    80005d60:	7462                	ld	s0,56(sp)
    80005d62:	6486                	ld	s1,64(sp)
    80005d64:	6526                	ld	a0,72(sp)
    80005d66:	65c6                	ld	a1,80(sp)
    80005d68:	6666                	ld	a2,88(sp)
    80005d6a:	7686                	ld	a3,96(sp)
    80005d6c:	7726                	ld	a4,104(sp)
    80005d6e:	77c6                	ld	a5,112(sp)
    80005d70:	7866                	ld	a6,120(sp)
    80005d72:	688a                	ld	a7,128(sp)
    80005d74:	692a                	ld	s2,136(sp)
    80005d76:	69ca                	ld	s3,144(sp)
    80005d78:	6a6a                	ld	s4,152(sp)
    80005d7a:	7a8a                	ld	s5,160(sp)
    80005d7c:	7b2a                	ld	s6,168(sp)
    80005d7e:	7bca                	ld	s7,176(sp)
    80005d80:	7c6a                	ld	s8,184(sp)
    80005d82:	6c8e                	ld	s9,192(sp)
    80005d84:	6d2e                	ld	s10,200(sp)
    80005d86:	6dce                	ld	s11,208(sp)
    80005d88:	6e6e                	ld	t3,216(sp)
    80005d8a:	7e8e                	ld	t4,224(sp)
    80005d8c:	7f2e                	ld	t5,232(sp)
    80005d8e:	7fce                	ld	t6,240(sp)
    80005d90:	6111                	addi	sp,sp,256
    80005d92:	10200073          	sret
    80005d96:	00000013          	nop
    80005d9a:	00000013          	nop
    80005d9e:	0001                	nop

0000000080005da0 <timervec>:
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	e10c                	sd	a1,0(a0)
    80005da6:	e510                	sd	a2,8(a0)
    80005da8:	e914                	sd	a3,16(a0)
    80005daa:	710c                	ld	a1,32(a0)
    80005dac:	7510                	ld	a2,40(a0)
    80005dae:	6194                	ld	a3,0(a1)
    80005db0:	96b2                	add	a3,a3,a2
    80005db2:	e194                	sd	a3,0(a1)
    80005db4:	4589                	li	a1,2
    80005db6:	14459073          	csrw	sip,a1
    80005dba:	6914                	ld	a3,16(a0)
    80005dbc:	6510                	ld	a2,8(a0)
    80005dbe:	610c                	ld	a1,0(a0)
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	30200073          	mret
	...

0000000080005dca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dca:	1141                	addi	sp,sp,-16
    80005dcc:	e422                	sd	s0,8(sp)
    80005dce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dd0:	0c0007b7          	lui	a5,0xc000
    80005dd4:	4705                	li	a4,1
    80005dd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dd8:	c3d8                	sw	a4,4(a5)
}
    80005dda:	6422                	ld	s0,8(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret

0000000080005de0 <plicinithart>:

void
plicinithart(void)
{
    80005de0:	1141                	addi	sp,sp,-16
    80005de2:	e406                	sd	ra,8(sp)
    80005de4:	e022                	sd	s0,0(sp)
    80005de6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	c12080e7          	jalr	-1006(ra) # 800019fa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005df0:	0085171b          	slliw	a4,a0,0x8
    80005df4:	0c0027b7          	lui	a5,0xc002
    80005df8:	97ba                	add	a5,a5,a4
    80005dfa:	40200713          	li	a4,1026
    80005dfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e02:	00d5151b          	slliw	a0,a0,0xd
    80005e06:	0c2017b7          	lui	a5,0xc201
    80005e0a:	97aa                	add	a5,a5,a0
    80005e0c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret

0000000080005e18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e18:	1141                	addi	sp,sp,-16
    80005e1a:	e406                	sd	ra,8(sp)
    80005e1c:	e022                	sd	s0,0(sp)
    80005e1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	bda080e7          	jalr	-1062(ra) # 800019fa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e28:	00d5151b          	slliw	a0,a0,0xd
    80005e2c:	0c2017b7          	lui	a5,0xc201
    80005e30:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e32:	43c8                	lw	a0,4(a5)
    80005e34:	60a2                	ld	ra,8(sp)
    80005e36:	6402                	ld	s0,0(sp)
    80005e38:	0141                	addi	sp,sp,16
    80005e3a:	8082                	ret

0000000080005e3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e3c:	1101                	addi	sp,sp,-32
    80005e3e:	ec06                	sd	ra,24(sp)
    80005e40:	e822                	sd	s0,16(sp)
    80005e42:	e426                	sd	s1,8(sp)
    80005e44:	1000                	addi	s0,sp,32
    80005e46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	bb2080e7          	jalr	-1102(ra) # 800019fa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e50:	00d5151b          	slliw	a0,a0,0xd
    80005e54:	0c2017b7          	lui	a5,0xc201
    80005e58:	97aa                	add	a5,a5,a0
    80005e5a:	c3c4                	sw	s1,4(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret

0000000080005e66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e66:	1141                	addi	sp,sp,-16
    80005e68:	e406                	sd	ra,8(sp)
    80005e6a:	e022                	sd	s0,0(sp)
    80005e6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e6e:	479d                	li	a5,7
    80005e70:	04a7cb63          	blt	a5,a0,80005ec6 <free_desc+0x60>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e74:	0001d717          	auipc	a4,0x1d
    80005e78:	18c70713          	addi	a4,a4,396 # 80023000 <disk>
    80005e7c:	972a                	add	a4,a4,a0
    80005e7e:	6789                	lui	a5,0x2
    80005e80:	97ba                	add	a5,a5,a4
    80005e82:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e86:	eba1                	bnez	a5,80005ed6 <free_desc+0x70>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e88:	00451713          	slli	a4,a0,0x4
    80005e8c:	0001f797          	auipc	a5,0x1f
    80005e90:	1747b783          	ld	a5,372(a5) # 80025000 <disk+0x2000>
    80005e94:	97ba                	add	a5,a5,a4
    80005e96:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e9a:	0001d717          	auipc	a4,0x1d
    80005e9e:	16670713          	addi	a4,a4,358 # 80023000 <disk>
    80005ea2:	972a                	add	a4,a4,a0
    80005ea4:	6789                	lui	a5,0x2
    80005ea6:	97ba                	add	a5,a5,a4
    80005ea8:	4705                	li	a4,1
    80005eaa:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eae:	0001f517          	auipc	a0,0x1f
    80005eb2:	16a50513          	addi	a0,a0,362 # 80025018 <disk+0x2018>
    80005eb6:	ffffc097          	auipc	ra,0xffffc
    80005eba:	50c080e7          	jalr	1292(ra) # 800023c2 <wakeup>
}
    80005ebe:	60a2                	ld	ra,8(sp)
    80005ec0:	6402                	ld	s0,0(sp)
    80005ec2:	0141                	addi	sp,sp,16
    80005ec4:	8082                	ret
    panic("virtio_disk_intr 1");
    80005ec6:	00003517          	auipc	a0,0x3
    80005eca:	95a50513          	addi	a0,a0,-1702 # 80008820 <syscalls+0x338>
    80005ece:	ffffa097          	auipc	ra,0xffffa
    80005ed2:	678080e7          	jalr	1656(ra) # 80000546 <panic>
    panic("virtio_disk_intr 2");
    80005ed6:	00003517          	auipc	a0,0x3
    80005eda:	96250513          	addi	a0,a0,-1694 # 80008838 <syscalls+0x350>
    80005ede:	ffffa097          	auipc	ra,0xffffa
    80005ee2:	668080e7          	jalr	1640(ra) # 80000546 <panic>

0000000080005ee6 <virtio_disk_init>:
{
    80005ee6:	1101                	addi	sp,sp,-32
    80005ee8:	ec06                	sd	ra,24(sp)
    80005eea:	e822                	sd	s0,16(sp)
    80005eec:	e426                	sd	s1,8(sp)
    80005eee:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ef0:	00003597          	auipc	a1,0x3
    80005ef4:	96058593          	addi	a1,a1,-1696 # 80008850 <syscalls+0x368>
    80005ef8:	0001f517          	auipc	a0,0x1f
    80005efc:	1b050513          	addi	a0,a0,432 # 800250a8 <disk+0x20a8>
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	cca080e7          	jalr	-822(ra) # 80000bca <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f08:	100017b7          	lui	a5,0x10001
    80005f0c:	4398                	lw	a4,0(a5)
    80005f0e:	2701                	sext.w	a4,a4
    80005f10:	747277b7          	lui	a5,0x74727
    80005f14:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f18:	0ef71063          	bne	a4,a5,80005ff8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f1c:	100017b7          	lui	a5,0x10001
    80005f20:	43dc                	lw	a5,4(a5)
    80005f22:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f24:	4705                	li	a4,1
    80005f26:	0ce79963          	bne	a5,a4,80005ff8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f2a:	100017b7          	lui	a5,0x10001
    80005f2e:	479c                	lw	a5,8(a5)
    80005f30:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f32:	4709                	li	a4,2
    80005f34:	0ce79263          	bne	a5,a4,80005ff8 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f38:	100017b7          	lui	a5,0x10001
    80005f3c:	47d8                	lw	a4,12(a5)
    80005f3e:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f40:	554d47b7          	lui	a5,0x554d4
    80005f44:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f48:	0af71863          	bne	a4,a5,80005ff8 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	4705                	li	a4,1
    80005f52:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f54:	470d                	li	a4,3
    80005f56:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f58:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f5a:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f5e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f62:	8f75                	and	a4,a4,a3
    80005f64:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f66:	472d                	li	a4,11
    80005f68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6a:	473d                	li	a4,15
    80005f6c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f6e:	6705                	lui	a4,0x1
    80005f70:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f72:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f76:	5bdc                	lw	a5,52(a5)
    80005f78:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f7a:	c7d9                	beqz	a5,80006008 <virtio_disk_init+0x122>
  if(max < NUM)
    80005f7c:	471d                	li	a4,7
    80005f7e:	08f77d63          	bgeu	a4,a5,80006018 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f82:	100014b7          	lui	s1,0x10001
    80005f86:	47a1                	li	a5,8
    80005f88:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f8a:	6609                	lui	a2,0x2
    80005f8c:	4581                	li	a1,0
    80005f8e:	0001d517          	auipc	a0,0x1d
    80005f92:	07250513          	addi	a0,a0,114 # 80023000 <disk>
    80005f96:	ffffb097          	auipc	ra,0xffffb
    80005f9a:	dc0080e7          	jalr	-576(ra) # 80000d56 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f9e:	0001d717          	auipc	a4,0x1d
    80005fa2:	06270713          	addi	a4,a4,98 # 80023000 <disk>
    80005fa6:	00c75793          	srli	a5,a4,0xc
    80005faa:	2781                	sext.w	a5,a5
    80005fac:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005fae:	0001f797          	auipc	a5,0x1f
    80005fb2:	05278793          	addi	a5,a5,82 # 80025000 <disk+0x2000>
    80005fb6:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005fb8:	0001d717          	auipc	a4,0x1d
    80005fbc:	0c870713          	addi	a4,a4,200 # 80023080 <disk+0x80>
    80005fc0:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005fc2:	0001e717          	auipc	a4,0x1e
    80005fc6:	03e70713          	addi	a4,a4,62 # 80024000 <disk+0x1000>
    80005fca:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fcc:	4705                	li	a4,1
    80005fce:	00e78c23          	sb	a4,24(a5)
    80005fd2:	00e78ca3          	sb	a4,25(a5)
    80005fd6:	00e78d23          	sb	a4,26(a5)
    80005fda:	00e78da3          	sb	a4,27(a5)
    80005fde:	00e78e23          	sb	a4,28(a5)
    80005fe2:	00e78ea3          	sb	a4,29(a5)
    80005fe6:	00e78f23          	sb	a4,30(a5)
    80005fea:	00e78fa3          	sb	a4,31(a5)
}
    80005fee:	60e2                	ld	ra,24(sp)
    80005ff0:	6442                	ld	s0,16(sp)
    80005ff2:	64a2                	ld	s1,8(sp)
    80005ff4:	6105                	addi	sp,sp,32
    80005ff6:	8082                	ret
    panic("could not find virtio disk");
    80005ff8:	00003517          	auipc	a0,0x3
    80005ffc:	86850513          	addi	a0,a0,-1944 # 80008860 <syscalls+0x378>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	546080e7          	jalr	1350(ra) # 80000546 <panic>
    panic("virtio disk has no queue 0");
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	87850513          	addi	a0,a0,-1928 # 80008880 <syscalls+0x398>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	536080e7          	jalr	1334(ra) # 80000546 <panic>
    panic("virtio disk max queue too short");
    80006018:	00003517          	auipc	a0,0x3
    8000601c:	88850513          	addi	a0,a0,-1912 # 800088a0 <syscalls+0x3b8>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	526080e7          	jalr	1318(ra) # 80000546 <panic>

0000000080006028 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006028:	7175                	addi	sp,sp,-144
    8000602a:	e506                	sd	ra,136(sp)
    8000602c:	e122                	sd	s0,128(sp)
    8000602e:	fca6                	sd	s1,120(sp)
    80006030:	f8ca                	sd	s2,112(sp)
    80006032:	f4ce                	sd	s3,104(sp)
    80006034:	f0d2                	sd	s4,96(sp)
    80006036:	ecd6                	sd	s5,88(sp)
    80006038:	e8da                	sd	s6,80(sp)
    8000603a:	e4de                	sd	s7,72(sp)
    8000603c:	e0e2                	sd	s8,64(sp)
    8000603e:	fc66                	sd	s9,56(sp)
    80006040:	f86a                	sd	s10,48(sp)
    80006042:	f46e                	sd	s11,40(sp)
    80006044:	0900                	addi	s0,sp,144
    80006046:	8aaa                	mv	s5,a0
    80006048:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000604a:	00c52c83          	lw	s9,12(a0)
    8000604e:	001c9c9b          	slliw	s9,s9,0x1
    80006052:	1c82                	slli	s9,s9,0x20
    80006054:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006058:	0001f517          	auipc	a0,0x1f
    8000605c:	05050513          	addi	a0,a0,80 # 800250a8 <disk+0x20a8>
    80006060:	ffffb097          	auipc	ra,0xffffb
    80006064:	bfa080e7          	jalr	-1030(ra) # 80000c5a <acquire>
  for(int i = 0; i < 3; i++){
    80006068:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000606a:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000606c:	0001dc17          	auipc	s8,0x1d
    80006070:	f94c0c13          	addi	s8,s8,-108 # 80023000 <disk>
    80006074:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006076:	4b0d                	li	s6,3
    80006078:	a0ad                	j	800060e2 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    8000607a:	00fc0733          	add	a4,s8,a5
    8000607e:	975e                	add	a4,a4,s7
    80006080:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006084:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006086:	0207c563          	bltz	a5,800060b0 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000608a:	2905                	addiw	s2,s2,1
    8000608c:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    8000608e:	19690c63          	beq	s2,s6,80006226 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    80006092:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006094:	0001f717          	auipc	a4,0x1f
    80006098:	f8470713          	addi	a4,a4,-124 # 80025018 <disk+0x2018>
    8000609c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000609e:	00074683          	lbu	a3,0(a4)
    800060a2:	fee1                	bnez	a3,8000607a <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060a4:	2785                	addiw	a5,a5,1
    800060a6:	0705                	addi	a4,a4,1
    800060a8:	fe979be3          	bne	a5,s1,8000609e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060ac:	57fd                	li	a5,-1
    800060ae:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060b0:	01205d63          	blez	s2,800060ca <virtio_disk_rw+0xa2>
    800060b4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060b6:	000a2503          	lw	a0,0(s4)
    800060ba:	00000097          	auipc	ra,0x0
    800060be:	dac080e7          	jalr	-596(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    800060c2:	2d85                	addiw	s11,s11,1
    800060c4:	0a11                	addi	s4,s4,4
    800060c6:	ff2d98e3          	bne	s11,s2,800060b6 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060ca:	0001f597          	auipc	a1,0x1f
    800060ce:	fde58593          	addi	a1,a1,-34 # 800250a8 <disk+0x20a8>
    800060d2:	0001f517          	auipc	a0,0x1f
    800060d6:	f4650513          	addi	a0,a0,-186 # 80025018 <disk+0x2018>
    800060da:	ffffc097          	auipc	ra,0xffffc
    800060de:	168080e7          	jalr	360(ra) # 80002242 <sleep>
  for(int i = 0; i < 3; i++){
    800060e2:	f8040a13          	addi	s4,s0,-128
{
    800060e6:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060e8:	894e                	mv	s2,s3
    800060ea:	b765                	j	80006092 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ec:	0001f717          	auipc	a4,0x1f
    800060f0:	f1473703          	ld	a4,-236(a4) # 80025000 <disk+0x2000>
    800060f4:	973e                	add	a4,a4,a5
    800060f6:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060fa:	0001d517          	auipc	a0,0x1d
    800060fe:	f0650513          	addi	a0,a0,-250 # 80023000 <disk>
    80006102:	0001f717          	auipc	a4,0x1f
    80006106:	efe70713          	addi	a4,a4,-258 # 80025000 <disk+0x2000>
    8000610a:	6314                	ld	a3,0(a4)
    8000610c:	96be                	add	a3,a3,a5
    8000610e:	00c6d603          	lhu	a2,12(a3)
    80006112:	00166613          	ori	a2,a2,1
    80006116:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000611a:	f8842683          	lw	a3,-120(s0)
    8000611e:	6310                	ld	a2,0(a4)
    80006120:	97b2                	add	a5,a5,a2
    80006122:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80006126:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000612a:	0612                	slli	a2,a2,0x4
    8000612c:	962a                	add	a2,a2,a0
    8000612e:	02060823          	sb	zero,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006132:	00469793          	slli	a5,a3,0x4
    80006136:	630c                	ld	a1,0(a4)
    80006138:	95be                	add	a1,a1,a5
    8000613a:	6689                	lui	a3,0x2
    8000613c:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80006140:	96ca                	add	a3,a3,s2
    80006142:	96aa                	add	a3,a3,a0
    80006144:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80006146:	6314                	ld	a3,0(a4)
    80006148:	96be                	add	a3,a3,a5
    8000614a:	4585                	li	a1,1
    8000614c:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000614e:	6314                	ld	a3,0(a4)
    80006150:	96be                	add	a3,a3,a5
    80006152:	4509                	li	a0,2
    80006154:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006158:	6314                	ld	a3,0(a4)
    8000615a:	97b6                	add	a5,a5,a3
    8000615c:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006160:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006164:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006168:	6714                	ld	a3,8(a4)
    8000616a:	0026d783          	lhu	a5,2(a3)
    8000616e:	8b9d                	andi	a5,a5,7
    80006170:	0789                	addi	a5,a5,2
    80006172:	0786                	slli	a5,a5,0x1
    80006174:	96be                	add	a3,a3,a5
    80006176:	00969023          	sh	s1,0(a3)
  __sync_synchronize();
    8000617a:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000617e:	6718                	ld	a4,8(a4)
    80006180:	00275783          	lhu	a5,2(a4)
    80006184:	2785                	addiw	a5,a5,1
    80006186:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000618a:	100017b7          	lui	a5,0x10001
    8000618e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006192:	004aa783          	lw	a5,4(s5)
    80006196:	02b79163          	bne	a5,a1,800061b8 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000619a:	0001f917          	auipc	s2,0x1f
    8000619e:	f0e90913          	addi	s2,s2,-242 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061a2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a4:	85ca                	mv	a1,s2
    800061a6:	8556                	mv	a0,s5
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	09a080e7          	jalr	154(ra) # 80002242 <sleep>
  while(b->disk == 1) {
    800061b0:	004aa783          	lw	a5,4(s5)
    800061b4:	fe9788e3          	beq	a5,s1,800061a4 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061b8:	f8042483          	lw	s1,-128(s0)
    800061bc:	20048713          	addi	a4,s1,512
    800061c0:	0712                	slli	a4,a4,0x4
    800061c2:	0001d797          	auipc	a5,0x1d
    800061c6:	e3e78793          	addi	a5,a5,-450 # 80023000 <disk>
    800061ca:	97ba                	add	a5,a5,a4
    800061cc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061d0:	0001f917          	auipc	s2,0x1f
    800061d4:	e3090913          	addi	s2,s2,-464 # 80025000 <disk+0x2000>
    800061d8:	a019                	j	800061de <virtio_disk_rw+0x1b6>
      i = disk.desc[i].next;
    800061da:	00e7d483          	lhu	s1,14(a5)
    free_desc(i);
    800061de:	8526                	mv	a0,s1
    800061e0:	00000097          	auipc	ra,0x0
    800061e4:	c86080e7          	jalr	-890(ra) # 80005e66 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061e8:	0492                	slli	s1,s1,0x4
    800061ea:	00093783          	ld	a5,0(s2)
    800061ee:	97a6                	add	a5,a5,s1
    800061f0:	00c7d703          	lhu	a4,12(a5)
    800061f4:	8b05                	andi	a4,a4,1
    800061f6:	f375                	bnez	a4,800061da <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061f8:	0001f517          	auipc	a0,0x1f
    800061fc:	eb050513          	addi	a0,a0,-336 # 800250a8 <disk+0x20a8>
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	b0e080e7          	jalr	-1266(ra) # 80000d0e <release>
}
    80006208:	60aa                	ld	ra,136(sp)
    8000620a:	640a                	ld	s0,128(sp)
    8000620c:	74e6                	ld	s1,120(sp)
    8000620e:	7946                	ld	s2,112(sp)
    80006210:	79a6                	ld	s3,104(sp)
    80006212:	7a06                	ld	s4,96(sp)
    80006214:	6ae6                	ld	s5,88(sp)
    80006216:	6b46                	ld	s6,80(sp)
    80006218:	6ba6                	ld	s7,72(sp)
    8000621a:	6c06                	ld	s8,64(sp)
    8000621c:	7ce2                	ld	s9,56(sp)
    8000621e:	7d42                	ld	s10,48(sp)
    80006220:	7da2                	ld	s11,40(sp)
    80006222:	6149                	addi	sp,sp,144
    80006224:	8082                	ret
  if(write)
    80006226:	01a037b3          	snez	a5,s10
    8000622a:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    8000622e:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006232:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006236:	f8042483          	lw	s1,-128(s0)
    8000623a:	00449913          	slli	s2,s1,0x4
    8000623e:	0001f997          	auipc	s3,0x1f
    80006242:	dc298993          	addi	s3,s3,-574 # 80025000 <disk+0x2000>
    80006246:	0009ba03          	ld	s4,0(s3)
    8000624a:	9a4a                	add	s4,s4,s2
    8000624c:	f7040513          	addi	a0,s0,-144
    80006250:	ffffb097          	auipc	ra,0xffffb
    80006254:	ed6080e7          	jalr	-298(ra) # 80001126 <kvmpa>
    80006258:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000625c:	0009b783          	ld	a5,0(s3)
    80006260:	97ca                	add	a5,a5,s2
    80006262:	4741                	li	a4,16
    80006264:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006266:	0009b783          	ld	a5,0(s3)
    8000626a:	97ca                	add	a5,a5,s2
    8000626c:	4705                	li	a4,1
    8000626e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006272:	f8442783          	lw	a5,-124(s0)
    80006276:	0009b703          	ld	a4,0(s3)
    8000627a:	974a                	add	a4,a4,s2
    8000627c:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006280:	0792                	slli	a5,a5,0x4
    80006282:	0009b703          	ld	a4,0(s3)
    80006286:	973e                	add	a4,a4,a5
    80006288:	058a8693          	addi	a3,s5,88
    8000628c:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    8000628e:	0009b703          	ld	a4,0(s3)
    80006292:	973e                	add	a4,a4,a5
    80006294:	40000693          	li	a3,1024
    80006298:	c714                	sw	a3,8(a4)
  if(write)
    8000629a:	e40d19e3          	bnez	s10,800060ec <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000629e:	0001f717          	auipc	a4,0x1f
    800062a2:	d6273703          	ld	a4,-670(a4) # 80025000 <disk+0x2000>
    800062a6:	973e                	add	a4,a4,a5
    800062a8:	4689                	li	a3,2
    800062aa:	00d71623          	sh	a3,12(a4)
    800062ae:	b5b1                	j	800060fa <virtio_disk_rw+0xd2>

00000000800062b0 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062b0:	1101                	addi	sp,sp,-32
    800062b2:	ec06                	sd	ra,24(sp)
    800062b4:	e822                	sd	s0,16(sp)
    800062b6:	e426                	sd	s1,8(sp)
    800062b8:	e04a                	sd	s2,0(sp)
    800062ba:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062bc:	0001f517          	auipc	a0,0x1f
    800062c0:	dec50513          	addi	a0,a0,-532 # 800250a8 <disk+0x20a8>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	996080e7          	jalr	-1642(ra) # 80000c5a <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062cc:	0001f717          	auipc	a4,0x1f
    800062d0:	d3470713          	addi	a4,a4,-716 # 80025000 <disk+0x2000>
    800062d4:	02075783          	lhu	a5,32(a4)
    800062d8:	6b18                	ld	a4,16(a4)
    800062da:	00275683          	lhu	a3,2(a4)
    800062de:	8ebd                	xor	a3,a3,a5
    800062e0:	8a9d                	andi	a3,a3,7
    800062e2:	cab9                	beqz	a3,80006338 <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062e4:	0001d917          	auipc	s2,0x1d
    800062e8:	d1c90913          	addi	s2,s2,-740 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062ec:	0001f497          	auipc	s1,0x1f
    800062f0:	d1448493          	addi	s1,s1,-748 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062f4:	078e                	slli	a5,a5,0x3
    800062f6:	973e                	add	a4,a4,a5
    800062f8:	435c                	lw	a5,4(a4)
    if(disk.info[id].status != 0)
    800062fa:	20078713          	addi	a4,a5,512
    800062fe:	0712                	slli	a4,a4,0x4
    80006300:	974a                	add	a4,a4,s2
    80006302:	03074703          	lbu	a4,48(a4)
    80006306:	ef21                	bnez	a4,8000635e <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    80006308:	20078793          	addi	a5,a5,512
    8000630c:	0792                	slli	a5,a5,0x4
    8000630e:	97ca                	add	a5,a5,s2
    80006310:	7798                	ld	a4,40(a5)
    80006312:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006316:	7788                	ld	a0,40(a5)
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	0aa080e7          	jalr	170(ra) # 800023c2 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006320:	0204d783          	lhu	a5,32(s1)
    80006324:	2785                	addiw	a5,a5,1
    80006326:	8b9d                	andi	a5,a5,7
    80006328:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000632c:	6898                	ld	a4,16(s1)
    8000632e:	00275683          	lhu	a3,2(a4)
    80006332:	8a9d                	andi	a3,a3,7
    80006334:	fcf690e3          	bne	a3,a5,800062f4 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006338:	10001737          	lui	a4,0x10001
    8000633c:	533c                	lw	a5,96(a4)
    8000633e:	8b8d                	andi	a5,a5,3
    80006340:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006342:	0001f517          	auipc	a0,0x1f
    80006346:	d6650513          	addi	a0,a0,-666 # 800250a8 <disk+0x20a8>
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	9c4080e7          	jalr	-1596(ra) # 80000d0e <release>
}
    80006352:	60e2                	ld	ra,24(sp)
    80006354:	6442                	ld	s0,16(sp)
    80006356:	64a2                	ld	s1,8(sp)
    80006358:	6902                	ld	s2,0(sp)
    8000635a:	6105                	addi	sp,sp,32
    8000635c:	8082                	ret
      panic("virtio_disk_intr status");
    8000635e:	00002517          	auipc	a0,0x2
    80006362:	56250513          	addi	a0,a0,1378 # 800088c0 <syscalls+0x3d8>
    80006366:	ffffa097          	auipc	ra,0xffffa
    8000636a:	1e0080e7          	jalr	480(ra) # 80000546 <panic>
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
