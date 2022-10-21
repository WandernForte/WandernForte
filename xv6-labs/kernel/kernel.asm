
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	fe070713          	addi	a4,a4,-32 # 80009030 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	eae78793          	addi	a5,a5,-338 # 80005f10 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67d7>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	1d478793          	addi	a5,a5,468 # 80001280 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  timerinit();
    800000d6:	00000097          	auipc	ra,0x0
    800000da:	f46080e7          	jalr	-186(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000de:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e6:	30200073          	mret
}
    800000ea:	60a2                	ld	ra,8(sp)
    800000ec:	6402                	ld	s0,0(sp)
    800000ee:	0141                	addi	sp,sp,16
    800000f0:	8082                	ret

00000000800000f2 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f2:	715d                	addi	sp,sp,-80
    800000f4:	e486                	sd	ra,72(sp)
    800000f6:	e0a2                	sd	s0,64(sp)
    800000f8:	fc26                	sd	s1,56(sp)
    800000fa:	f84a                	sd	s2,48(sp)
    800000fc:	f44e                	sd	s3,40(sp)
    800000fe:	f052                	sd	s4,32(sp)
    80000100:	ec56                	sd	s5,24(sp)
    80000102:	0880                	addi	s0,sp,80
    80000104:	8a2a                	mv	s4,a0
    80000106:	84ae                	mv	s1,a1
    80000108:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010a:	00011517          	auipc	a0,0x11
    8000010e:	06650513          	addi	a0,a0,102 # 80011170 <cons>
    80000112:	00001097          	auipc	ra,0x1
    80000116:	be0080e7          	jalr	-1056(ra) # 80000cf2 <acquire>
  for(i = 0; i < n; i++){
    8000011a:	05305c63          	blez	s3,80000172 <consolewrite+0x80>
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	6d4080e7          	jalr	1748(ra) # 80002800 <either_copyin>
    80000134:	01550d63          	beq	a0,s5,8000014e <consolewrite+0x5c>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	79a080e7          	jalr	1946(ra) # 800008d6 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x30>
    8000014c:	894e                	mv	s2,s3
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	c6c080e7          	jalr	-916(ra) # 80000dc2 <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5c>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7159                	addi	sp,sp,-112
    80000178:	f486                	sd	ra,104(sp)
    8000017a:	f0a2                	sd	s0,96(sp)
    8000017c:	eca6                	sd	s1,88(sp)
    8000017e:	e8ca                	sd	s2,80(sp)
    80000180:	e4ce                	sd	s3,72(sp)
    80000182:	e0d2                	sd	s4,64(sp)
    80000184:	fc56                	sd	s5,56(sp)
    80000186:	f85a                	sd	s6,48(sp)
    80000188:	f45e                	sd	s7,40(sp)
    8000018a:	f062                	sd	s8,32(sp)
    8000018c:	ec66                	sd	s9,24(sp)
    8000018e:	e86a                	sd	s10,16(sp)
    80000190:	1880                	addi	s0,sp,112
    80000192:	8aaa                	mv	s5,a0
    80000194:	8a2e                	mv	s4,a1
    80000196:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000198:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000019c:	00011517          	auipc	a0,0x11
    800001a0:	fd450513          	addi	a0,a0,-44 # 80011170 <cons>
    800001a4:	00001097          	auipc	ra,0x1
    800001a8:	b4e080e7          	jalr	-1202(ra) # 80000cf2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ac:	00011497          	auipc	s1,0x11
    800001b0:	fc448493          	addi	s1,s1,-60 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	00011917          	auipc	s2,0x11
    800001b8:	05c90913          	addi	s2,s2,92 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001bc:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001be:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c0:	4ca9                	li	s9,10
  while(n > 0){
    800001c2:	07305863          	blez	s3,80000232 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001c6:	0a04a783          	lw	a5,160(s1)
    800001ca:	0a44a703          	lw	a4,164(s1)
    800001ce:	02f71463          	bne	a4,a5,800001f6 <consoleread+0x80>
      if(myproc()->killed){
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	b66080e7          	jalr	-1178(ra) # 80001d38 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	36e080e7          	jalr	878(ra) # 80002550 <sleep>
    while(cons.r == cons.w){
    800001ea:	0a04a783          	lw	a5,160(s1)
    800001ee:	0a44a703          	lw	a4,164(s1)
    800001f2:	fef700e3          	beq	a4,a5,800001d2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f6:	0017871b          	addiw	a4,a5,1
    800001fa:	0ae4a023          	sw	a4,160(s1)
    800001fe:	07f7f713          	andi	a4,a5,127
    80000202:	9726                	add	a4,a4,s1
    80000204:	02074703          	lbu	a4,32(a4)
    80000208:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    8000020c:	077d0563          	beq	s10,s7,80000276 <consoleread+0x100>
    cbuf = c;
    80000210:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000214:	4685                	li	a3,1
    80000216:	f9f40613          	addi	a2,s0,-97
    8000021a:	85d2                	mv	a1,s4
    8000021c:	8556                	mv	a0,s5
    8000021e:	00002097          	auipc	ra,0x2
    80000222:	58c080e7          	jalr	1420(ra) # 800027aa <either_copyout>
    80000226:	01850663          	beq	a0,s8,80000232 <consoleread+0xbc>
    dst++;
    8000022a:	0a05                	addi	s4,s4,1
    --n;
    8000022c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000022e:	f99d1ae3          	bne	s10,s9,800001c2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000232:	00011517          	auipc	a0,0x11
    80000236:	f3e50513          	addi	a0,a0,-194 # 80011170 <cons>
    8000023a:	00001097          	auipc	ra,0x1
    8000023e:	b88080e7          	jalr	-1144(ra) # 80000dc2 <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b72080e7          	jalr	-1166(ra) # 80000dc2 <release>
        return -1;
    80000258:	557d                	li	a0,-1
}
    8000025a:	70a6                	ld	ra,104(sp)
    8000025c:	7406                	ld	s0,96(sp)
    8000025e:	64e6                	ld	s1,88(sp)
    80000260:	6946                	ld	s2,80(sp)
    80000262:	69a6                	ld	s3,72(sp)
    80000264:	6a06                	ld	s4,64(sp)
    80000266:	7ae2                	ld	s5,56(sp)
    80000268:	7b42                	ld	s6,48(sp)
    8000026a:	7ba2                	ld	s7,40(sp)
    8000026c:	7c02                	ld	s8,32(sp)
    8000026e:	6ce2                	ld	s9,24(sp)
    80000270:	6d42                	ld	s10,16(sp)
    80000272:	6165                	addi	sp,sp,112
    80000274:	8082                	ret
      if(n < target){
    80000276:	0009871b          	sext.w	a4,s3
    8000027a:	fb677ce3          	bgeu	a4,s6,80000232 <consoleread+0xbc>
        cons.r--;
    8000027e:	00011717          	auipc	a4,0x11
    80000282:	f8f72923          	sw	a5,-110(a4) # 80011210 <cons+0xa0>
    80000286:	b775                	j	80000232 <consoleread+0xbc>

0000000080000288 <consputc>:
{
    80000288:	1141                	addi	sp,sp,-16
    8000028a:	e406                	sd	ra,8(sp)
    8000028c:	e022                	sd	s0,0(sp)
    8000028e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000290:	10000793          	li	a5,256
    80000294:	00f50a63          	beq	a0,a5,800002a8 <consputc+0x20>
    uartputc_sync(c);
    80000298:	00000097          	auipc	ra,0x0
    8000029c:	560080e7          	jalr	1376(ra) # 800007f8 <uartputc_sync>
}
    800002a0:	60a2                	ld	ra,8(sp)
    800002a2:	6402                	ld	s0,0(sp)
    800002a4:	0141                	addi	sp,sp,16
    800002a6:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a8:	4521                	li	a0,8
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	54e080e7          	jalr	1358(ra) # 800007f8 <uartputc_sync>
    800002b2:	02000513          	li	a0,32
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	542080e7          	jalr	1346(ra) # 800007f8 <uartputc_sync>
    800002be:	4521                	li	a0,8
    800002c0:	00000097          	auipc	ra,0x0
    800002c4:	538080e7          	jalr	1336(ra) # 800007f8 <uartputc_sync>
    800002c8:	bfe1                	j	800002a0 <consputc+0x18>

00000000800002ca <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ca:	1101                	addi	sp,sp,-32
    800002cc:	ec06                	sd	ra,24(sp)
    800002ce:	e822                	sd	s0,16(sp)
    800002d0:	e426                	sd	s1,8(sp)
    800002d2:	e04a                	sd	s2,0(sp)
    800002d4:	1000                	addi	s0,sp,32
    800002d6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d8:	00011517          	auipc	a0,0x11
    800002dc:	e9850513          	addi	a0,a0,-360 # 80011170 <cons>
    800002e0:	00001097          	auipc	ra,0x1
    800002e4:	a12080e7          	jalr	-1518(ra) # 80000cf2 <acquire>

  switch(c){
    800002e8:	47d5                	li	a5,21
    800002ea:	0af48663          	beq	s1,a5,80000396 <consoleintr+0xcc>
    800002ee:	0297ca63          	blt	a5,s1,80000322 <consoleintr+0x58>
    800002f2:	47a1                	li	a5,8
    800002f4:	0ef48763          	beq	s1,a5,800003e2 <consoleintr+0x118>
    800002f8:	47c1                	li	a5,16
    800002fa:	10f49a63          	bne	s1,a5,8000040e <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fe:	00002097          	auipc	ra,0x2
    80000302:	558080e7          	jalr	1368(ra) # 80002856 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	ab4080e7          	jalr	-1356(ra) # 80000dc2 <release>
}
    80000316:	60e2                	ld	ra,24(sp)
    80000318:	6442                	ld	s0,16(sp)
    8000031a:	64a2                	ld	s1,8(sp)
    8000031c:	6902                	ld	s2,0(sp)
    8000031e:	6105                	addi	sp,sp,32
    80000320:	8082                	ret
  switch(c){
    80000322:	07f00793          	li	a5,127
    80000326:	0af48e63          	beq	s1,a5,800003e2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000032a:	00011717          	auipc	a4,0x11
    8000032e:	e4670713          	addi	a4,a4,-442 # 80011170 <cons>
    80000332:	0a872783          	lw	a5,168(a4)
    80000336:	0a072703          	lw	a4,160(a4)
    8000033a:	9f99                	subw	a5,a5,a4
    8000033c:	07f00713          	li	a4,127
    80000340:	fcf763e3          	bltu	a4,a5,80000306 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000344:	47b5                	li	a5,13
    80000346:	0cf48763          	beq	s1,a5,80000414 <consoleintr+0x14a>
      consputc(c);
    8000034a:	8526                	mv	a0,s1
    8000034c:	00000097          	auipc	ra,0x0
    80000350:	f3c080e7          	jalr	-196(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000354:	00011797          	auipc	a5,0x11
    80000358:	e1c78793          	addi	a5,a5,-484 # 80011170 <cons>
    8000035c:	0a87a703          	lw	a4,168(a5)
    80000360:	0017069b          	addiw	a3,a4,1
    80000364:	0006861b          	sext.w	a2,a3
    80000368:	0ad7a423          	sw	a3,168(a5)
    8000036c:	07f77713          	andi	a4,a4,127
    80000370:	97ba                	add	a5,a5,a4
    80000372:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000376:	47a9                	li	a5,10
    80000378:	0cf48563          	beq	s1,a5,80000442 <consoleintr+0x178>
    8000037c:	4791                	li	a5,4
    8000037e:	0cf48263          	beq	s1,a5,80000442 <consoleintr+0x178>
    80000382:	00011797          	auipc	a5,0x11
    80000386:	e8e7a783          	lw	a5,-370(a5) # 80011210 <cons+0xa0>
    8000038a:	0807879b          	addiw	a5,a5,128
    8000038e:	f6f61ce3          	bne	a2,a5,80000306 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000392:	863e                	mv	a2,a5
    80000394:	a07d                	j	80000442 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000396:	00011717          	auipc	a4,0x11
    8000039a:	dda70713          	addi	a4,a4,-550 # 80011170 <cons>
    8000039e:	0a872783          	lw	a5,168(a4)
    800003a2:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a6:	00011497          	auipc	s1,0x11
    800003aa:	dca48493          	addi	s1,s1,-566 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003ae:	4929                	li	s2,10
    800003b0:	f4f70be3          	beq	a4,a5,80000306 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b4:	37fd                	addiw	a5,a5,-1
    800003b6:	07f7f713          	andi	a4,a5,127
    800003ba:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003bc:	02074703          	lbu	a4,32(a4)
    800003c0:	f52703e3          	beq	a4,s2,80000306 <consoleintr+0x3c>
      cons.e--;
    800003c4:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003c8:	10000513          	li	a0,256
    800003cc:	00000097          	auipc	ra,0x0
    800003d0:	ebc080e7          	jalr	-324(ra) # 80000288 <consputc>
    while(cons.e != cons.w &&
    800003d4:	0a84a783          	lw	a5,168(s1)
    800003d8:	0a44a703          	lw	a4,164(s1)
    800003dc:	fcf71ce3          	bne	a4,a5,800003b4 <consoleintr+0xea>
    800003e0:	b71d                	j	80000306 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e2:	00011717          	auipc	a4,0x11
    800003e6:	d8e70713          	addi	a4,a4,-626 # 80011170 <cons>
    800003ea:	0a872783          	lw	a5,168(a4)
    800003ee:	0a472703          	lw	a4,164(a4)
    800003f2:	f0f70ae3          	beq	a4,a5,80000306 <consoleintr+0x3c>
      cons.e--;
    800003f6:	37fd                	addiw	a5,a5,-1
    800003f8:	00011717          	auipc	a4,0x11
    800003fc:	e2f72023          	sw	a5,-480(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000400:	10000513          	li	a0,256
    80000404:	00000097          	auipc	ra,0x0
    80000408:	e84080e7          	jalr	-380(ra) # 80000288 <consputc>
    8000040c:	bded                	j	80000306 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040e:	ee048ce3          	beqz	s1,80000306 <consoleintr+0x3c>
    80000412:	bf21                	j	8000032a <consoleintr+0x60>
      consputc(c);
    80000414:	4529                	li	a0,10
    80000416:	00000097          	auipc	ra,0x0
    8000041a:	e72080e7          	jalr	-398(ra) # 80000288 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041e:	00011797          	auipc	a5,0x11
    80000422:	d5278793          	addi	a5,a5,-686 # 80011170 <cons>
    80000426:	0a87a703          	lw	a4,168(a5)
    8000042a:	0017069b          	addiw	a3,a4,1
    8000042e:	0006861b          	sext.w	a2,a3
    80000432:	0ad7a423          	sw	a3,168(a5)
    80000436:	07f77713          	andi	a4,a4,127
    8000043a:	97ba                	add	a5,a5,a4
    8000043c:	4729                	li	a4,10
    8000043e:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000442:	00011797          	auipc	a5,0x11
    80000446:	dcc7a923          	sw	a2,-558(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    8000044a:	00011517          	auipc	a0,0x11
    8000044e:	dc650513          	addi	a0,a0,-570 # 80011210 <cons+0xa0>
    80000452:	00002097          	auipc	ra,0x2
    80000456:	27e080e7          	jalr	638(ra) # 800026d0 <wakeup>
    8000045a:	b575                	j	80000306 <consoleintr+0x3c>

000000008000045c <consoleinit>:

void
consoleinit(void)
{
    8000045c:	1141                	addi	sp,sp,-16
    8000045e:	e406                	sd	ra,8(sp)
    80000460:	e022                	sd	s0,0(sp)
    80000462:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000464:	00008597          	auipc	a1,0x8
    80000468:	bac58593          	addi	a1,a1,-1108 # 80008010 <etext+0x10>
    8000046c:	00011517          	auipc	a0,0x11
    80000470:	d0450513          	addi	a0,a0,-764 # 80011170 <cons>
    80000474:	00001097          	auipc	ra,0x1
    80000478:	9fa080e7          	jalr	-1542(ra) # 80000e6e <initlock>

  uartinit();
    8000047c:	00000097          	auipc	ra,0x0
    80000480:	32c080e7          	jalr	812(ra) # 800007a8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000484:	00022797          	auipc	a5,0x22
    80000488:	41478793          	addi	a5,a5,1044 # 80022898 <devsw>
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	cea70713          	addi	a4,a4,-790 # 80000176 <consoleread>
    80000494:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000496:	00000717          	auipc	a4,0x0
    8000049a:	c5c70713          	addi	a4,a4,-932 # 800000f2 <consolewrite>
    8000049e:	ef98                	sd	a4,24(a5)
}
    800004a0:	60a2                	ld	ra,8(sp)
    800004a2:	6402                	ld	s0,0(sp)
    800004a4:	0141                	addi	sp,sp,16
    800004a6:	8082                	ret

00000000800004a8 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a8:	7179                	addi	sp,sp,-48
    800004aa:	f406                	sd	ra,40(sp)
    800004ac:	f022                	sd	s0,32(sp)
    800004ae:	ec26                	sd	s1,24(sp)
    800004b0:	e84a                	sd	s2,16(sp)
    800004b2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b4:	c219                	beqz	a2,800004ba <printint+0x12>
    800004b6:	08054763          	bltz	a0,80000544 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ba:	2501                	sext.w	a0,a0
    800004bc:	4881                	li	a7,0
    800004be:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c4:	2581                	sext.w	a1,a1
    800004c6:	00008617          	auipc	a2,0x8
    800004ca:	b7a60613          	addi	a2,a2,-1158 # 80008040 <digits>
    800004ce:	883a                	mv	a6,a4
    800004d0:	2705                	addiw	a4,a4,1
    800004d2:	02b577bb          	remuw	a5,a0,a1
    800004d6:	1782                	slli	a5,a5,0x20
    800004d8:	9381                	srli	a5,a5,0x20
    800004da:	97b2                	add	a5,a5,a2
    800004dc:	0007c783          	lbu	a5,0(a5)
    800004e0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e4:	0005079b          	sext.w	a5,a0
    800004e8:	02b5553b          	divuw	a0,a0,a1
    800004ec:	0685                	addi	a3,a3,1
    800004ee:	feb7f0e3          	bgeu	a5,a1,800004ce <printint+0x26>

  if(sign)
    800004f2:	00088c63          	beqz	a7,8000050a <printint+0x62>
    buf[i++] = '-';
    800004f6:	fe070793          	addi	a5,a4,-32
    800004fa:	00878733          	add	a4,a5,s0
    800004fe:	02d00793          	li	a5,45
    80000502:	fef70823          	sb	a5,-16(a4)
    80000506:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050a:	02e05763          	blez	a4,80000538 <printint+0x90>
    8000050e:	fd040793          	addi	a5,s0,-48
    80000512:	00e784b3          	add	s1,a5,a4
    80000516:	fff78913          	addi	s2,a5,-1
    8000051a:	993a                	add	s2,s2,a4
    8000051c:	377d                	addiw	a4,a4,-1
    8000051e:	1702                	slli	a4,a4,0x20
    80000520:	9301                	srli	a4,a4,0x20
    80000522:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000526:	fff4c503          	lbu	a0,-1(s1)
    8000052a:	00000097          	auipc	ra,0x0
    8000052e:	d5e080e7          	jalr	-674(ra) # 80000288 <consputc>
  while(--i >= 0)
    80000532:	14fd                	addi	s1,s1,-1
    80000534:	ff2499e3          	bne	s1,s2,80000526 <printint+0x7e>
}
    80000538:	70a2                	ld	ra,40(sp)
    8000053a:	7402                	ld	s0,32(sp)
    8000053c:	64e2                	ld	s1,24(sp)
    8000053e:	6942                	ld	s2,16(sp)
    80000540:	6145                	addi	sp,sp,48
    80000542:	8082                	ret
    x = -xx;
    80000544:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000548:	4885                	li	a7,1
    x = -xx;
    8000054a:	bf95                	j	800004be <printint+0x16>

000000008000054c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000054c:	1101                	addi	sp,sp,-32
    8000054e:	ec06                	sd	ra,24(sp)
    80000550:	e822                	sd	s0,16(sp)
    80000552:	e426                	sd	s1,8(sp)
    80000554:	1000                	addi	s0,sp,32
    80000556:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000558:	00011797          	auipc	a5,0x11
    8000055c:	ce07a423          	sw	zero,-792(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000560:	00008517          	auipc	a0,0x8
    80000564:	ab850513          	addi	a0,a0,-1352 # 80008018 <etext+0x18>
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	02e080e7          	jalr	46(ra) # 80000596 <printf>
  printf(s);
    80000570:	8526                	mv	a0,s1
    80000572:	00000097          	auipc	ra,0x0
    80000576:	024080e7          	jalr	36(ra) # 80000596 <printf>
  printf("\n");
    8000057a:	00008517          	auipc	a0,0x8
    8000057e:	be650513          	addi	a0,a0,-1050 # 80008160 <digits+0x120>
    80000582:	00000097          	auipc	ra,0x0
    80000586:	014080e7          	jalr	20(ra) # 80000596 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058a:	4785                	li	a5,1
    8000058c:	00009717          	auipc	a4,0x9
    80000590:	a6f72a23          	sw	a5,-1420(a4) # 80009000 <panicked>
  for(;;)
    80000594:	a001                	j	80000594 <panic+0x48>

0000000080000596 <printf>:
{
    80000596:	7131                	addi	sp,sp,-192
    80000598:	fc86                	sd	ra,120(sp)
    8000059a:	f8a2                	sd	s0,112(sp)
    8000059c:	f4a6                	sd	s1,104(sp)
    8000059e:	f0ca                	sd	s2,96(sp)
    800005a0:	ecce                	sd	s3,88(sp)
    800005a2:	e8d2                	sd	s4,80(sp)
    800005a4:	e4d6                	sd	s5,72(sp)
    800005a6:	e0da                	sd	s6,64(sp)
    800005a8:	fc5e                	sd	s7,56(sp)
    800005aa:	f862                	sd	s8,48(sp)
    800005ac:	f466                	sd	s9,40(sp)
    800005ae:	f06a                	sd	s10,32(sp)
    800005b0:	ec6e                	sd	s11,24(sp)
    800005b2:	0100                	addi	s0,sp,128
    800005b4:	8a2a                	mv	s4,a0
    800005b6:	e40c                	sd	a1,8(s0)
    800005b8:	e810                	sd	a2,16(s0)
    800005ba:	ec14                	sd	a3,24(s0)
    800005bc:	f018                	sd	a4,32(s0)
    800005be:	f41c                	sd	a5,40(s0)
    800005c0:	03043823          	sd	a6,48(s0)
    800005c4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c8:	00011d97          	auipc	s11,0x11
    800005cc:	c78dad83          	lw	s11,-904(s11) # 80011240 <pr+0x20>
  if(locking)
    800005d0:	020d9b63          	bnez	s11,80000606 <printf+0x70>
  if (fmt == 0)
    800005d4:	040a0263          	beqz	s4,80000618 <printf+0x82>
  va_start(ap, fmt);
    800005d8:	00840793          	addi	a5,s0,8
    800005dc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e0:	000a4503          	lbu	a0,0(s4)
    800005e4:	14050f63          	beqz	a0,80000742 <printf+0x1ac>
    800005e8:	4981                	li	s3,0
    if(c != '%'){
    800005ea:	02500a93          	li	s5,37
    switch(c){
    800005ee:	07000b93          	li	s7,112
  consputc('x');
    800005f2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f4:	00008b17          	auipc	s6,0x8
    800005f8:	a4cb0b13          	addi	s6,s6,-1460 # 80008040 <digits>
    switch(c){
    800005fc:	07300c93          	li	s9,115
    80000600:	06400c13          	li	s8,100
    80000604:	a82d                	j	8000063e <printf+0xa8>
    acquire(&pr.lock);
    80000606:	00011517          	auipc	a0,0x11
    8000060a:	c1a50513          	addi	a0,a0,-998 # 80011220 <pr>
    8000060e:	00000097          	auipc	ra,0x0
    80000612:	6e4080e7          	jalr	1764(ra) # 80000cf2 <acquire>
    80000616:	bf7d                	j	800005d4 <printf+0x3e>
    panic("null fmt");
    80000618:	00008517          	auipc	a0,0x8
    8000061c:	a1050513          	addi	a0,a0,-1520 # 80008028 <etext+0x28>
    80000620:	00000097          	auipc	ra,0x0
    80000624:	f2c080e7          	jalr	-212(ra) # 8000054c <panic>
      consputc(c);
    80000628:	00000097          	auipc	ra,0x0
    8000062c:	c60080e7          	jalr	-928(ra) # 80000288 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000630:	2985                	addiw	s3,s3,1
    80000632:	013a07b3          	add	a5,s4,s3
    80000636:	0007c503          	lbu	a0,0(a5)
    8000063a:	10050463          	beqz	a0,80000742 <printf+0x1ac>
    if(c != '%'){
    8000063e:	ff5515e3          	bne	a0,s5,80000628 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000642:	2985                	addiw	s3,s3,1
    80000644:	013a07b3          	add	a5,s4,s3
    80000648:	0007c783          	lbu	a5,0(a5)
    8000064c:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000650:	cbed                	beqz	a5,80000742 <printf+0x1ac>
    switch(c){
    80000652:	05778a63          	beq	a5,s7,800006a6 <printf+0x110>
    80000656:	02fbf663          	bgeu	s7,a5,80000682 <printf+0xec>
    8000065a:	09978863          	beq	a5,s9,800006ea <printf+0x154>
    8000065e:	07800713          	li	a4,120
    80000662:	0ce79563          	bne	a5,a4,8000072c <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000666:	f8843783          	ld	a5,-120(s0)
    8000066a:	00878713          	addi	a4,a5,8
    8000066e:	f8e43423          	sd	a4,-120(s0)
    80000672:	4605                	li	a2,1
    80000674:	85ea                	mv	a1,s10
    80000676:	4388                	lw	a0,0(a5)
    80000678:	00000097          	auipc	ra,0x0
    8000067c:	e30080e7          	jalr	-464(ra) # 800004a8 <printint>
      break;
    80000680:	bf45                	j	80000630 <printf+0x9a>
    switch(c){
    80000682:	09578f63          	beq	a5,s5,80000720 <printf+0x18a>
    80000686:	0b879363          	bne	a5,s8,8000072c <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	4605                	li	a2,1
    80000698:	45a9                	li	a1,10
    8000069a:	4388                	lw	a0,0(a5)
    8000069c:	00000097          	auipc	ra,0x0
    800006a0:	e0c080e7          	jalr	-500(ra) # 800004a8 <printint>
      break;
    800006a4:	b771                	j	80000630 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a6:	f8843783          	ld	a5,-120(s0)
    800006aa:	00878713          	addi	a4,a5,8
    800006ae:	f8e43423          	sd	a4,-120(s0)
    800006b2:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006b6:	03000513          	li	a0,48
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bce080e7          	jalr	-1074(ra) # 80000288 <consputc>
  consputc('x');
    800006c2:	07800513          	li	a0,120
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	bc2080e7          	jalr	-1086(ra) # 80000288 <consputc>
    800006ce:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d0:	03c95793          	srli	a5,s2,0x3c
    800006d4:	97da                	add	a5,a5,s6
    800006d6:	0007c503          	lbu	a0,0(a5)
    800006da:	00000097          	auipc	ra,0x0
    800006de:	bae080e7          	jalr	-1106(ra) # 80000288 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e2:	0912                	slli	s2,s2,0x4
    800006e4:	34fd                	addiw	s1,s1,-1
    800006e6:	f4ed                	bnez	s1,800006d0 <printf+0x13a>
    800006e8:	b7a1                	j	80000630 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006ea:	f8843783          	ld	a5,-120(s0)
    800006ee:	00878713          	addi	a4,a5,8
    800006f2:	f8e43423          	sd	a4,-120(s0)
    800006f6:	6384                	ld	s1,0(a5)
    800006f8:	cc89                	beqz	s1,80000712 <printf+0x17c>
      for(; *s; s++)
    800006fa:	0004c503          	lbu	a0,0(s1)
    800006fe:	d90d                	beqz	a0,80000630 <printf+0x9a>
        consputc(*s);
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b88080e7          	jalr	-1144(ra) # 80000288 <consputc>
      for(; *s; s++)
    80000708:	0485                	addi	s1,s1,1
    8000070a:	0004c503          	lbu	a0,0(s1)
    8000070e:	f96d                	bnez	a0,80000700 <printf+0x16a>
    80000710:	b705                	j	80000630 <printf+0x9a>
        s = "(null)";
    80000712:	00008497          	auipc	s1,0x8
    80000716:	90e48493          	addi	s1,s1,-1778 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071a:	02800513          	li	a0,40
    8000071e:	b7cd                	j	80000700 <printf+0x16a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b66080e7          	jalr	-1178(ra) # 80000288 <consputc>
      break;
    8000072a:	b719                	j	80000630 <printf+0x9a>
      consputc('%');
    8000072c:	8556                	mv	a0,s5
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b5a080e7          	jalr	-1190(ra) # 80000288 <consputc>
      consputc(c);
    80000736:	8526                	mv	a0,s1
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b50080e7          	jalr	-1200(ra) # 80000288 <consputc>
      break;
    80000740:	bdc5                	j	80000630 <printf+0x9a>
  if(locking)
    80000742:	020d9163          	bnez	s11,80000764 <printf+0x1ce>
}
    80000746:	70e6                	ld	ra,120(sp)
    80000748:	7446                	ld	s0,112(sp)
    8000074a:	74a6                	ld	s1,104(sp)
    8000074c:	7906                	ld	s2,96(sp)
    8000074e:	69e6                	ld	s3,88(sp)
    80000750:	6a46                	ld	s4,80(sp)
    80000752:	6aa6                	ld	s5,72(sp)
    80000754:	6b06                	ld	s6,64(sp)
    80000756:	7be2                	ld	s7,56(sp)
    80000758:	7c42                	ld	s8,48(sp)
    8000075a:	7ca2                	ld	s9,40(sp)
    8000075c:	7d02                	ld	s10,32(sp)
    8000075e:	6de2                	ld	s11,24(sp)
    80000760:	6129                	addi	sp,sp,192
    80000762:	8082                	ret
    release(&pr.lock);
    80000764:	00011517          	auipc	a0,0x11
    80000768:	abc50513          	addi	a0,a0,-1348 # 80011220 <pr>
    8000076c:	00000097          	auipc	ra,0x0
    80000770:	656080e7          	jalr	1622(ra) # 80000dc2 <release>
}
    80000774:	bfc9                	j	80000746 <printf+0x1b0>

0000000080000776 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000776:	1101                	addi	sp,sp,-32
    80000778:	ec06                	sd	ra,24(sp)
    8000077a:	e822                	sd	s0,16(sp)
    8000077c:	e426                	sd	s1,8(sp)
    8000077e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000780:	00011497          	auipc	s1,0x11
    80000784:	aa048493          	addi	s1,s1,-1376 # 80011220 <pr>
    80000788:	00008597          	auipc	a1,0x8
    8000078c:	8b058593          	addi	a1,a1,-1872 # 80008038 <etext+0x38>
    80000790:	8526                	mv	a0,s1
    80000792:	00000097          	auipc	ra,0x0
    80000796:	6dc080e7          	jalr	1756(ra) # 80000e6e <initlock>
  pr.locking = 1;
    8000079a:	4785                	li	a5,1
    8000079c:	d09c                	sw	a5,32(s1)
}
    8000079e:	60e2                	ld	ra,24(sp)
    800007a0:	6442                	ld	s0,16(sp)
    800007a2:	64a2                	ld	s1,8(sp)
    800007a4:	6105                	addi	sp,sp,32
    800007a6:	8082                	ret

00000000800007a8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a8:	1141                	addi	sp,sp,-16
    800007aa:	e406                	sd	ra,8(sp)
    800007ac:	e022                	sd	s0,0(sp)
    800007ae:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b0:	100007b7          	lui	a5,0x10000
    800007b4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b8:	f8000713          	li	a4,-128
    800007bc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c0:	470d                	li	a4,3
    800007c2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007ca:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ce:	469d                	li	a3,7
    800007d0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d8:	00008597          	auipc	a1,0x8
    800007dc:	88058593          	addi	a1,a1,-1920 # 80008058 <digits+0x18>
    800007e0:	00011517          	auipc	a0,0x11
    800007e4:	a6850513          	addi	a0,a0,-1432 # 80011248 <uart_tx_lock>
    800007e8:	00000097          	auipc	ra,0x0
    800007ec:	686080e7          	jalr	1670(ra) # 80000e6e <initlock>
}
    800007f0:	60a2                	ld	ra,8(sp)
    800007f2:	6402                	ld	s0,0(sp)
    800007f4:	0141                	addi	sp,sp,16
    800007f6:	8082                	ret

00000000800007f8 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f8:	1101                	addi	sp,sp,-32
    800007fa:	ec06                	sd	ra,24(sp)
    800007fc:	e822                	sd	s0,16(sp)
    800007fe:	e426                	sd	s1,8(sp)
    80000800:	1000                	addi	s0,sp,32
    80000802:	84aa                	mv	s1,a0
  push_off();
    80000804:	00000097          	auipc	ra,0x0
    80000808:	4a2080e7          	jalr	1186(ra) # 80000ca6 <push_off>

  if(panicked){
    8000080c:	00008797          	auipc	a5,0x8
    80000810:	7f47a783          	lw	a5,2036(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	10000737          	lui	a4,0x10000
  if(panicked){
    80000818:	c391                	beqz	a5,8000081c <uartputc_sync+0x24>
    for(;;)
    8000081a:	a001                	j	8000081a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000820:	0207f793          	andi	a5,a5,32
    80000824:	dfe5                	beqz	a5,8000081c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000826:	0ff4f513          	zext.b	a0,s1
    8000082a:	100007b7          	lui	a5,0x10000
    8000082e:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000832:	00000097          	auipc	ra,0x0
    80000836:	530080e7          	jalr	1328(ra) # 80000d62 <pop_off>
}
    8000083a:	60e2                	ld	ra,24(sp)
    8000083c:	6442                	ld	s0,16(sp)
    8000083e:	64a2                	ld	s1,8(sp)
    80000840:	6105                	addi	sp,sp,32
    80000842:	8082                	ret

0000000080000844 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000844:	00008797          	auipc	a5,0x8
    80000848:	7c07a783          	lw	a5,1984(a5) # 80009004 <uart_tx_r>
    8000084c:	00008717          	auipc	a4,0x8
    80000850:	7bc72703          	lw	a4,1980(a4) # 80009008 <uart_tx_w>
    80000854:	08f70063          	beq	a4,a5,800008d4 <uartstart+0x90>
{
    80000858:	7139                	addi	sp,sp,-64
    8000085a:	fc06                	sd	ra,56(sp)
    8000085c:	f822                	sd	s0,48(sp)
    8000085e:	f426                	sd	s1,40(sp)
    80000860:	f04a                	sd	s2,32(sp)
    80000862:	ec4e                	sd	s3,24(sp)
    80000864:	e852                	sd	s4,16(sp)
    80000866:	e456                	sd	s5,8(sp)
    80000868:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000086e:	00011a97          	auipc	s5,0x11
    80000872:	9daa8a93          	addi	s5,s5,-1574 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000876:	00008497          	auipc	s1,0x8
    8000087a:	78e48493          	addi	s1,s1,1934 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087e:	00008a17          	auipc	s4,0x8
    80000882:	78aa0a13          	addi	s4,s4,1930 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000886:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088a:	02077713          	andi	a4,a4,32
    8000088e:	cb15                	beqz	a4,800008c2 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000890:	00fa8733          	add	a4,s5,a5
    80000894:	02074983          	lbu	s3,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000898:	2785                	addiw	a5,a5,1
    8000089a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000089e:	01b7571b          	srliw	a4,a4,0x1b
    800008a2:	9fb9                	addw	a5,a5,a4
    800008a4:	8bfd                	andi	a5,a5,31
    800008a6:	9f99                	subw	a5,a5,a4
    800008a8:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008aa:	8526                	mv	a0,s1
    800008ac:	00002097          	auipc	ra,0x2
    800008b0:	e24080e7          	jalr	-476(ra) # 800026d0 <wakeup>
    
    WriteReg(THR, c);
    800008b4:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b8:	409c                	lw	a5,0(s1)
    800008ba:	000a2703          	lw	a4,0(s4)
    800008be:	fcf714e3          	bne	a4,a5,80000886 <uartstart+0x42>
  }
}
    800008c2:	70e2                	ld	ra,56(sp)
    800008c4:	7442                	ld	s0,48(sp)
    800008c6:	74a2                	ld	s1,40(sp)
    800008c8:	7902                	ld	s2,32(sp)
    800008ca:	69e2                	ld	s3,24(sp)
    800008cc:	6a42                	ld	s4,16(sp)
    800008ce:	6aa2                	ld	s5,8(sp)
    800008d0:	6121                	addi	sp,sp,64
    800008d2:	8082                	ret
    800008d4:	8082                	ret

00000000800008d6 <uartputc>:
{
    800008d6:	7179                	addi	sp,sp,-48
    800008d8:	f406                	sd	ra,40(sp)
    800008da:	f022                	sd	s0,32(sp)
    800008dc:	ec26                	sd	s1,24(sp)
    800008de:	e84a                	sd	s2,16(sp)
    800008e0:	e44e                	sd	s3,8(sp)
    800008e2:	e052                	sd	s4,0(sp)
    800008e4:	1800                	addi	s0,sp,48
    800008e6:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008e8:	00011517          	auipc	a0,0x11
    800008ec:	96050513          	addi	a0,a0,-1696 # 80011248 <uart_tx_lock>
    800008f0:	00000097          	auipc	ra,0x0
    800008f4:	402080e7          	jalr	1026(ra) # 80000cf2 <acquire>
  if(panicked){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7087a783          	lw	a5,1800(a5) # 80009000 <panicked>
    80000900:	c391                	beqz	a5,80000904 <uartputc+0x2e>
    for(;;)
    80000902:	a001                	j	80000902 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000904:	00008697          	auipc	a3,0x8
    80000908:	7046a683          	lw	a3,1796(a3) # 80009008 <uart_tx_w>
    8000090c:	0016879b          	addiw	a5,a3,1
    80000910:	41f7d71b          	sraiw	a4,a5,0x1f
    80000914:	01b7571b          	srliw	a4,a4,0x1b
    80000918:	9fb9                	addw	a5,a5,a4
    8000091a:	8bfd                	andi	a5,a5,31
    8000091c:	9f99                	subw	a5,a5,a4
    8000091e:	00008717          	auipc	a4,0x8
    80000922:	6e672703          	lw	a4,1766(a4) # 80009004 <uart_tx_r>
    80000926:	04f71363          	bne	a4,a5,8000096c <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000092a:	00011a17          	auipc	s4,0x11
    8000092e:	91ea0a13          	addi	s4,s4,-1762 # 80011248 <uart_tx_lock>
    80000932:	00008917          	auipc	s2,0x8
    80000936:	6d290913          	addi	s2,s2,1746 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000093a:	00008997          	auipc	s3,0x8
    8000093e:	6ce98993          	addi	s3,s3,1742 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000942:	85d2                	mv	a1,s4
    80000944:	854a                	mv	a0,s2
    80000946:	00002097          	auipc	ra,0x2
    8000094a:	c0a080e7          	jalr	-1014(ra) # 80002550 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094e:	0009a683          	lw	a3,0(s3)
    80000952:	0016879b          	addiw	a5,a3,1
    80000956:	41f7d71b          	sraiw	a4,a5,0x1f
    8000095a:	01b7571b          	srliw	a4,a4,0x1b
    8000095e:	9fb9                	addw	a5,a5,a4
    80000960:	8bfd                	andi	a5,a5,31
    80000962:	9f99                	subw	a5,a5,a4
    80000964:	00092703          	lw	a4,0(s2)
    80000968:	fcf70de3          	beq	a4,a5,80000942 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000096c:	00011917          	auipc	s2,0x11
    80000970:	8dc90913          	addi	s2,s2,-1828 # 80011248 <uart_tx_lock>
    80000974:	96ca                	add	a3,a3,s2
    80000976:	02968023          	sb	s1,32(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000097a:	00008717          	auipc	a4,0x8
    8000097e:	68f72723          	sw	a5,1678(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000982:	00000097          	auipc	ra,0x0
    80000986:	ec2080e7          	jalr	-318(ra) # 80000844 <uartstart>
      release(&uart_tx_lock);
    8000098a:	854a                	mv	a0,s2
    8000098c:	00000097          	auipc	ra,0x0
    80000990:	436080e7          	jalr	1078(ra) # 80000dc2 <release>
}
    80000994:	70a2                	ld	ra,40(sp)
    80000996:	7402                	ld	s0,32(sp)
    80000998:	64e2                	ld	s1,24(sp)
    8000099a:	6942                	ld	s2,16(sp)
    8000099c:	69a2                	ld	s3,8(sp)
    8000099e:	6a02                	ld	s4,0(sp)
    800009a0:	6145                	addi	sp,sp,48
    800009a2:	8082                	ret

00000000800009a4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009a4:	1141                	addi	sp,sp,-16
    800009a6:	e422                	sd	s0,8(sp)
    800009a8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009b2:	8b85                	andi	a5,a5,1
    800009b4:	cb81                	beqz	a5,800009c4 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009b6:	100007b7          	lui	a5,0x10000
    800009ba:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009be:	6422                	ld	s0,8(sp)
    800009c0:	0141                	addi	sp,sp,16
    800009c2:	8082                	ret
    return -1;
    800009c4:	557d                	li	a0,-1
    800009c6:	bfe5                	j	800009be <uartgetc+0x1a>

00000000800009c8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c8:	1101                	addi	sp,sp,-32
    800009ca:	ec06                	sd	ra,24(sp)
    800009cc:	e822                	sd	s0,16(sp)
    800009ce:	e426                	sd	s1,8(sp)
    800009d0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009d2:	54fd                	li	s1,-1
    800009d4:	a029                	j	800009de <uartintr+0x16>
      break;
    consoleintr(c);
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	8f4080e7          	jalr	-1804(ra) # 800002ca <consoleintr>
    int c = uartgetc();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	fc6080e7          	jalr	-58(ra) # 800009a4 <uartgetc>
    if(c == -1)
    800009e6:	fe9518e3          	bne	a0,s1,800009d6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ea:	00011497          	auipc	s1,0x11
    800009ee:	85e48493          	addi	s1,s1,-1954 # 80011248 <uart_tx_lock>
    800009f2:	8526                	mv	a0,s1
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	2fe080e7          	jalr	766(ra) # 80000cf2 <acquire>
  uartstart();
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	e48080e7          	jalr	-440(ra) # 80000844 <uartstart>
  release(&uart_tx_lock);
    80000a04:	8526                	mv	a0,s1
    80000a06:	00000097          	auipc	ra,0x0
    80000a0a:	3bc080e7          	jalr	956(ra) # 80000dc2 <release>
}
    80000a0e:	60e2                	ld	ra,24(sp)
    80000a10:	6442                	ld	s0,16(sp)
    80000a12:	64a2                	ld	s1,8(sp)
    80000a14:	6105                	addi	sp,sp,32
    80000a16:	8082                	ret

0000000080000a18 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a18:	7139                	addi	sp,sp,-64
    80000a1a:	fc06                	sd	ra,56(sp)
    80000a1c:	f822                	sd	s0,48(sp)
    80000a1e:	f426                	sd	s1,40(sp)
    80000a20:	f04a                	sd	s2,32(sp)
    80000a22:	ec4e                	sd	s3,24(sp)
    80000a24:	e852                	sd	s4,16(sp)
    80000a26:	e456                	sd	s5,8(sp)
    80000a28:	0080                	addi	s0,sp,64
  struct run *r;

  
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a2a:	03451793          	slli	a5,a0,0x34
    80000a2e:	e3c1                	bnez	a5,80000aae <kfree+0x96>
    80000a30:	84aa                	mv	s1,a0
    80000a32:	00027797          	auipc	a5,0x27
    80000a36:	5f678793          	addi	a5,a5,1526 # 80028028 <end>
    80000a3a:	06f56a63          	bltu	a0,a5,80000aae <kfree+0x96>
    80000a3e:	47c5                	li	a5,17
    80000a40:	07ee                	slli	a5,a5,0x1b
    80000a42:	06f57663          	bgeu	a0,a5,80000aae <kfree+0x96>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a46:	6605                	lui	a2,0x1
    80000a48:	4585                	li	a1,1
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	688080e7          	jalr	1672(ra) # 800010d2 <memset>

  r = (struct run*)pa;
  push_off();
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	254080e7          	jalr	596(ra) # 80000ca6 <push_off>
  int id = cpuid();
    80000a5a:	00001097          	auipc	ra,0x1
    80000a5e:	2b2080e7          	jalr	690(ra) # 80001d0c <cpuid>
  acquire(&(kmem[id]).lock);
    80000a62:	00011a97          	auipc	s5,0x11
    80000a66:	826a8a93          	addi	s5,s5,-2010 # 80011288 <kmem>
    80000a6a:	00251993          	slli	s3,a0,0x2
    80000a6e:	00a98933          	add	s2,s3,a0
    80000a72:	090e                	slli	s2,s2,0x3
    80000a74:	9956                	add	s2,s2,s5
    80000a76:	854a                	mv	a0,s2
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	27a080e7          	jalr	634(ra) # 80000cf2 <acquire>
  r->next = kmem[id].freelist;
    80000a80:	02093783          	ld	a5,32(s2)
    80000a84:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000a86:	02993023          	sd	s1,32(s2)
  release(&(kmem[id]).lock);
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	336080e7          	jalr	822(ra) # 80000dc2 <release>
  pop_off();
    80000a94:	00000097          	auipc	ra,0x0
    80000a98:	2ce080e7          	jalr	718(ra) # 80000d62 <pop_off>
}
    80000a9c:	70e2                	ld	ra,56(sp)
    80000a9e:	7442                	ld	s0,48(sp)
    80000aa0:	74a2                	ld	s1,40(sp)
    80000aa2:	7902                	ld	s2,32(sp)
    80000aa4:	69e2                	ld	s3,24(sp)
    80000aa6:	6a42                	ld	s4,16(sp)
    80000aa8:	6aa2                	ld	s5,8(sp)
    80000aaa:	6121                	addi	sp,sp,64
    80000aac:	8082                	ret
    panic("kfree");
    80000aae:	00007517          	auipc	a0,0x7
    80000ab2:	5b250513          	addi	a0,a0,1458 # 80008060 <digits+0x20>
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	a96080e7          	jalr	-1386(ra) # 8000054c <panic>

0000000080000abe <freerange>:
{
    80000abe:	7179                	addi	sp,sp,-48
    80000ac0:	f406                	sd	ra,40(sp)
    80000ac2:	f022                	sd	s0,32(sp)
    80000ac4:	ec26                	sd	s1,24(sp)
    80000ac6:	e84a                	sd	s2,16(sp)
    80000ac8:	e44e                	sd	s3,8(sp)
    80000aca:	e052                	sd	s4,0(sp)
    80000acc:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ace:	6785                	lui	a5,0x1
    80000ad0:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad4:	00e504b3          	add	s1,a0,a4
    80000ad8:	777d                	lui	a4,0xfffff
    80000ada:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	94be                	add	s1,s1,a5
    80000ade:	0095ee63          	bltu	a1,s1,80000afa <freerange+0x3c>
    80000ae2:	892e                	mv	s2,a1
    kfree(p);
    80000ae4:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae6:	6985                	lui	s3,0x1
    kfree(p);
    80000ae8:	01448533          	add	a0,s1,s4
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	f2c080e7          	jalr	-212(ra) # 80000a18 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af4:	94ce                	add	s1,s1,s3
    80000af6:	fe9979e3          	bgeu	s2,s1,80000ae8 <freerange+0x2a>
}
    80000afa:	70a2                	ld	ra,40(sp)
    80000afc:	7402                	ld	s0,32(sp)
    80000afe:	64e2                	ld	s1,24(sp)
    80000b00:	6942                	ld	s2,16(sp)
    80000b02:	69a2                	ld	s3,8(sp)
    80000b04:	6a02                	ld	s4,0(sp)
    80000b06:	6145                	addi	sp,sp,48
    80000b08:	8082                	ret

0000000080000b0a <kinit>:
{ 
    80000b0a:	7179                	addi	sp,sp,-48
    80000b0c:	f406                	sd	ra,40(sp)
    80000b0e:	f022                	sd	s0,32(sp)
    80000b10:	ec26                	sd	s1,24(sp)
    80000b12:	e84a                	sd	s2,16(sp)
    80000b14:	e44e                	sd	s3,8(sp)
    80000b16:	1800                	addi	s0,sp,48
  for(int id=0;id<NCPU;id++){
    80000b18:	00010497          	auipc	s1,0x10
    80000b1c:	77048493          	addi	s1,s1,1904 # 80011288 <kmem>
    80000b20:	00011997          	auipc	s3,0x11
    80000b24:	8a898993          	addi	s3,s3,-1880 # 800113c8 <lock_locks>
  initlock(&(kmem[id]).lock, "kmem");
    80000b28:	00007917          	auipc	s2,0x7
    80000b2c:	54090913          	addi	s2,s2,1344 # 80008068 <digits+0x28>
    80000b30:	85ca                	mv	a1,s2
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	33a080e7          	jalr	826(ra) # 80000e6e <initlock>
  for(int id=0;id<NCPU;id++){
    80000b3c:	02848493          	addi	s1,s1,40
    80000b40:	ff3498e3          	bne	s1,s3,80000b30 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b44:	45c5                	li	a1,17
    80000b46:	05ee                	slli	a1,a1,0x1b
    80000b48:	00027517          	auipc	a0,0x27
    80000b4c:	4e050513          	addi	a0,a0,1248 # 80028028 <end>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	f6e080e7          	jalr	-146(ra) # 80000abe <freerange>
}
    80000b58:	70a2                	ld	ra,40(sp)
    80000b5a:	7402                	ld	s0,32(sp)
    80000b5c:	64e2                	ld	s1,24(sp)
    80000b5e:	6942                	ld	s2,16(sp)
    80000b60:	69a2                	ld	s3,8(sp)
    80000b62:	6145                	addi	sp,sp,48
    80000b64:	8082                	ret

0000000080000b66 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b66:	715d                	addi	sp,sp,-80
    80000b68:	e486                	sd	ra,72(sp)
    80000b6a:	e0a2                	sd	s0,64(sp)
    80000b6c:	fc26                	sd	s1,56(sp)
    80000b6e:	f84a                	sd	s2,48(sp)
    80000b70:	f44e                	sd	s3,40(sp)
    80000b72:	f052                	sd	s4,32(sp)
    80000b74:	ec56                	sd	s5,24(sp)
    80000b76:	e85a                	sd	s6,16(sp)
    80000b78:	e45e                	sd	s7,8(sp)
    80000b7a:	e062                	sd	s8,0(sp)
    80000b7c:	0880                	addi	s0,sp,80
  struct run *r;
  push_off();
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	128080e7          	jalr	296(ra) # 80000ca6 <push_off>
  int id = cpuid();
    80000b86:	00001097          	auipc	ra,0x1
    80000b8a:	186080e7          	jalr	390(ra) # 80001d0c <cpuid>
    80000b8e:	892a                	mv	s2,a0
  
  acquire(&(kmem[id]).lock);
    80000b90:	00251793          	slli	a5,a0,0x2
    80000b94:	97aa                	add	a5,a5,a0
    80000b96:	078e                	slli	a5,a5,0x3
    80000b98:	00010497          	auipc	s1,0x10
    80000b9c:	6f048493          	addi	s1,s1,1776 # 80011288 <kmem>
    80000ba0:	94be                	add	s1,s1,a5
    80000ba2:	8526                	mv	a0,s1
    80000ba4:	00000097          	auipc	ra,0x0
    80000ba8:	14e080e7          	jalr	334(ra) # 80000cf2 <acquire>
  r = kmem[id].freelist;
    80000bac:	0204ba03          	ld	s4,32(s1)
  if(r){
    80000bb0:	0a0a0763          	beqz	s4,80000c5e <kalloc+0xf8>
    
    kmem[id].freelist = r->next;
    80000bb4:	000a3683          	ld	a3,0(s4) # fffffffffffff000 <end+0xffffffff7ffd6fd8>
    80000bb8:	f094                	sd	a3,32(s1)
    
    }
    release(&(kmem[id]).lock);
    80000bba:	8526                	mv	a0,s1
    80000bbc:	00000097          	auipc	ra,0x0
    80000bc0:	206080e7          	jalr	518(ra) # 80000dc2 <release>
      }
      
      release(&(kmem[idx]).lock);
    }
  
  pop_off();
    80000bc4:	00000097          	auipc	ra,0x0
    80000bc8:	19e080e7          	jalr	414(ra) # 80000d62 <pop_off>
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bcc:	6605                	lui	a2,0x1
    80000bce:	4595                	li	a1,5
    80000bd0:	8552                	mv	a0,s4
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	500080e7          	jalr	1280(ra) # 800010d2 <memset>
  
  return (void*)r;
    80000bda:	8552                	mv	a0,s4
    80000bdc:	60a6                	ld	ra,72(sp)
    80000bde:	6406                	ld	s0,64(sp)
    80000be0:	74e2                	ld	s1,56(sp)
    80000be2:	7942                	ld	s2,48(sp)
    80000be4:	79a2                	ld	s3,40(sp)
    80000be6:	7a02                	ld	s4,32(sp)
    80000be8:	6ae2                	ld	s5,24(sp)
    80000bea:	6b42                	ld	s6,16(sp)
    80000bec:	6ba2                	ld	s7,8(sp)
    80000bee:	6c02                	ld	s8,0(sp)
    80000bf0:	6161                	addi	sp,sp,80
    80000bf2:	8082                	ret
        kmem[idx].freelist=r->next;
    80000bf4:	000bb683          	ld	a3,0(s7)
    80000bf8:	00299793          	slli	a5,s3,0x2
    80000bfc:	97ce                	add	a5,a5,s3
    80000bfe:	078e                	slli	a5,a5,0x3
    80000c00:	00010717          	auipc	a4,0x10
    80000c04:	68870713          	addi	a4,a4,1672 # 80011288 <kmem>
    80000c08:	97ba                	add	a5,a5,a4
    80000c0a:	f394                	sd	a3,32(a5)
        release(&(kmem[idx]).lock);
    80000c0c:	8526                	mv	a0,s1
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	1b4080e7          	jalr	436(ra) # 80000dc2 <release>
      if(kmem[idx].freelist){
    80000c16:	8a5e                	mv	s4,s7
        break;
    80000c18:	b775                	j	80000bc4 <kalloc+0x5e>
    for(int idx=0;idx<NCPU;idx++){
    80000c1a:	2985                	addiw	s3,s3,1
    80000c1c:	02848493          	addi	s1,s1,40
    80000c20:	03598a63          	beq	s3,s5,80000c54 <kalloc+0xee>
      if(idx==id||holding(&(kmem[idx]).lock)==1) continue;
    80000c24:	ff390be3          	beq	s2,s3,80000c1a <kalloc+0xb4>
    80000c28:	8526                	mv	a0,s1
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	04e080e7          	jalr	78(ra) # 80000c78 <holding>
    80000c32:	ff8504e3          	beq	a0,s8,80000c1a <kalloc+0xb4>
      acquire(&(kmem[idx]).lock);
    80000c36:	8526                	mv	a0,s1
    80000c38:	00000097          	auipc	ra,0x0
    80000c3c:	0ba080e7          	jalr	186(ra) # 80000cf2 <acquire>
      if(kmem[idx].freelist){
    80000c40:	0204bb83          	ld	s7,32(s1)
    80000c44:	fa0b98e3          	bnez	s7,80000bf4 <kalloc+0x8e>
      release(&(kmem[idx]).lock);
    80000c48:	8526                	mv	a0,s1
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	178080e7          	jalr	376(ra) # 80000dc2 <release>
    80000c52:	b7e1                	j	80000c1a <kalloc+0xb4>
  pop_off();
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	10e080e7          	jalr	270(ra) # 80000d62 <pop_off>
  if(r)
    80000c5c:	bfbd                	j	80000bda <kalloc+0x74>
    release(&(kmem[id]).lock);
    80000c5e:	8526                	mv	a0,s1
    80000c60:	00000097          	auipc	ra,0x0
    80000c64:	162080e7          	jalr	354(ra) # 80000dc2 <release>
    for(int idx=0;idx<NCPU;idx++){
    80000c68:	00010497          	auipc	s1,0x10
    80000c6c:	62048493          	addi	s1,s1,1568 # 80011288 <kmem>
    release(&(kmem[id]).lock);
    80000c70:	4981                	li	s3,0
      if(idx==id||holding(&(kmem[idx]).lock)==1) continue;
    80000c72:	4c05                	li	s8,1
    for(int idx=0;idx<NCPU;idx++){
    80000c74:	4aa1                	li	s5,8
    80000c76:	b77d                	j	80000c24 <kalloc+0xbe>

0000000080000c78 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c78:	411c                	lw	a5,0(a0)
    80000c7a:	e399                	bnez	a5,80000c80 <holding+0x8>
    80000c7c:	4501                	li	a0,0
  return r;
}
    80000c7e:	8082                	ret
{
    80000c80:	1101                	addi	sp,sp,-32
    80000c82:	ec06                	sd	ra,24(sp)
    80000c84:	e822                	sd	s0,16(sp)
    80000c86:	e426                	sd	s1,8(sp)
    80000c88:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c8a:	6904                	ld	s1,16(a0)
    80000c8c:	00001097          	auipc	ra,0x1
    80000c90:	090080e7          	jalr	144(ra) # 80001d1c <mycpu>
    80000c94:	40a48533          	sub	a0,s1,a0
    80000c98:	00153513          	seqz	a0,a0
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret

0000000080000ca6 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000ca6:	1101                	addi	sp,sp,-32
    80000ca8:	ec06                	sd	ra,24(sp)
    80000caa:	e822                	sd	s0,16(sp)
    80000cac:	e426                	sd	s1,8(sp)
    80000cae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb0:	100024f3          	csrr	s1,sstatus
    80000cb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cb8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cba:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	05e080e7          	jalr	94(ra) # 80001d1c <mycpu>
    80000cc6:	5d3c                	lw	a5,120(a0)
    80000cc8:	cf89                	beqz	a5,80000ce2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cca:	00001097          	auipc	ra,0x1
    80000cce:	052080e7          	jalr	82(ra) # 80001d1c <mycpu>
    80000cd2:	5d3c                	lw	a5,120(a0)
    80000cd4:	2785                	addiw	a5,a5,1
    80000cd6:	dd3c                	sw	a5,120(a0)
}
    80000cd8:	60e2                	ld	ra,24(sp)
    80000cda:	6442                	ld	s0,16(sp)
    80000cdc:	64a2                	ld	s1,8(sp)
    80000cde:	6105                	addi	sp,sp,32
    80000ce0:	8082                	ret
    mycpu()->intena = old;
    80000ce2:	00001097          	auipc	ra,0x1
    80000ce6:	03a080e7          	jalr	58(ra) # 80001d1c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cea:	8085                	srli	s1,s1,0x1
    80000cec:	8885                	andi	s1,s1,1
    80000cee:	dd64                	sw	s1,124(a0)
    80000cf0:	bfe9                	j	80000cca <push_off+0x24>

0000000080000cf2 <acquire>:
{
    80000cf2:	1101                	addi	sp,sp,-32
    80000cf4:	ec06                	sd	ra,24(sp)
    80000cf6:	e822                	sd	s0,16(sp)
    80000cf8:	e426                	sd	s1,8(sp)
    80000cfa:	1000                	addi	s0,sp,32
    80000cfc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	fa8080e7          	jalr	-88(ra) # 80000ca6 <push_off>
  if(holding(lk))
    80000d06:	8526                	mv	a0,s1
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	f70080e7          	jalr	-144(ra) # 80000c78 <holding>
    80000d10:	e911                	bnez	a0,80000d24 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d12:	4785                	li	a5,1
    80000d14:	01c48713          	addi	a4,s1,28
    80000d18:	0f50000f          	fence	iorw,ow
    80000d1c:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d20:	4705                	li	a4,1
    80000d22:	a839                	j	80000d40 <acquire+0x4e>
    panic("acquire");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	34c50513          	addi	a0,a0,844 # 80008070 <digits+0x30>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	820080e7          	jalr	-2016(ra) # 8000054c <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d34:	01848793          	addi	a5,s1,24
    80000d38:	0f50000f          	fence	iorw,ow
    80000d3c:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d40:	87ba                	mv	a5,a4
    80000d42:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d46:	2781                	sext.w	a5,a5
    80000d48:	f7f5                	bnez	a5,80000d34 <acquire+0x42>
  __sync_synchronize();
    80000d4a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d4e:	00001097          	auipc	ra,0x1
    80000d52:	fce080e7          	jalr	-50(ra) # 80001d1c <mycpu>
    80000d56:	e888                	sd	a0,16(s1)
}
    80000d58:	60e2                	ld	ra,24(sp)
    80000d5a:	6442                	ld	s0,16(sp)
    80000d5c:	64a2                	ld	s1,8(sp)
    80000d5e:	6105                	addi	sp,sp,32
    80000d60:	8082                	ret

0000000080000d62 <pop_off>:

void
pop_off(void)
{
    80000d62:	1141                	addi	sp,sp,-16
    80000d64:	e406                	sd	ra,8(sp)
    80000d66:	e022                	sd	s0,0(sp)
    80000d68:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d6a:	00001097          	auipc	ra,0x1
    80000d6e:	fb2080e7          	jalr	-78(ra) # 80001d1c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d72:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d78:	e78d                	bnez	a5,80000da2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d7a:	5d3c                	lw	a5,120(a0)
    80000d7c:	02f05b63          	blez	a5,80000db2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d80:	37fd                	addiw	a5,a5,-1
    80000d82:	0007871b          	sext.w	a4,a5
    80000d86:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d88:	eb09                	bnez	a4,80000d9a <pop_off+0x38>
    80000d8a:	5d7c                	lw	a5,124(a0)
    80000d8c:	c799                	beqz	a5,80000d9a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d96:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret
    panic("pop_off - interruptible");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2d650513          	addi	a0,a0,726 # 80008078 <digits+0x38>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	7a2080e7          	jalr	1954(ra) # 8000054c <panic>
    panic("pop_off");
    80000db2:	00007517          	auipc	a0,0x7
    80000db6:	2de50513          	addi	a0,a0,734 # 80008090 <digits+0x50>
    80000dba:	fffff097          	auipc	ra,0xfffff
    80000dbe:	792080e7          	jalr	1938(ra) # 8000054c <panic>

0000000080000dc2 <release>:
{
    80000dc2:	1101                	addi	sp,sp,-32
    80000dc4:	ec06                	sd	ra,24(sp)
    80000dc6:	e822                	sd	s0,16(sp)
    80000dc8:	e426                	sd	s1,8(sp)
    80000dca:	1000                	addi	s0,sp,32
    80000dcc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dce:	00000097          	auipc	ra,0x0
    80000dd2:	eaa080e7          	jalr	-342(ra) # 80000c78 <holding>
    80000dd6:	c115                	beqz	a0,80000dfa <release+0x38>
  lk->cpu = 0;
    80000dd8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ddc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de0:	0f50000f          	fence	iorw,ow
    80000de4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000de8:	00000097          	auipc	ra,0x0
    80000dec:	f7a080e7          	jalr	-134(ra) # 80000d62 <pop_off>
}
    80000df0:	60e2                	ld	ra,24(sp)
    80000df2:	6442                	ld	s0,16(sp)
    80000df4:	64a2                	ld	s1,8(sp)
    80000df6:	6105                	addi	sp,sp,32
    80000df8:	8082                	ret
    panic("release");
    80000dfa:	00007517          	auipc	a0,0x7
    80000dfe:	29e50513          	addi	a0,a0,670 # 80008098 <digits+0x58>
    80000e02:	fffff097          	auipc	ra,0xfffff
    80000e06:	74a080e7          	jalr	1866(ra) # 8000054c <panic>

0000000080000e0a <freelock>:
{
    80000e0a:	1101                	addi	sp,sp,-32
    80000e0c:	ec06                	sd	ra,24(sp)
    80000e0e:	e822                	sd	s0,16(sp)
    80000e10:	e426                	sd	s1,8(sp)
    80000e12:	1000                	addi	s0,sp,32
    80000e14:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e16:	00010517          	auipc	a0,0x10
    80000e1a:	5b250513          	addi	a0,a0,1458 # 800113c8 <lock_locks>
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	ed4080e7          	jalr	-300(ra) # 80000cf2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e26:	00010717          	auipc	a4,0x10
    80000e2a:	5c270713          	addi	a4,a4,1474 # 800113e8 <locks>
    80000e2e:	4781                	li	a5,0
    80000e30:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e34:	6314                	ld	a3,0(a4)
    80000e36:	00968763          	beq	a3,s1,80000e44 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e3a:	2785                	addiw	a5,a5,1
    80000e3c:	0721                	addi	a4,a4,8
    80000e3e:	fec79be3          	bne	a5,a2,80000e34 <freelock+0x2a>
    80000e42:	a809                	j	80000e54 <freelock+0x4a>
      locks[i] = 0;
    80000e44:	078e                	slli	a5,a5,0x3
    80000e46:	00010717          	auipc	a4,0x10
    80000e4a:	5a270713          	addi	a4,a4,1442 # 800113e8 <locks>
    80000e4e:	97ba                	add	a5,a5,a4
    80000e50:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e54:	00010517          	auipc	a0,0x10
    80000e58:	57450513          	addi	a0,a0,1396 # 800113c8 <lock_locks>
    80000e5c:	00000097          	auipc	ra,0x0
    80000e60:	f66080e7          	jalr	-154(ra) # 80000dc2 <release>
}
    80000e64:	60e2                	ld	ra,24(sp)
    80000e66:	6442                	ld	s0,16(sp)
    80000e68:	64a2                	ld	s1,8(sp)
    80000e6a:	6105                	addi	sp,sp,32
    80000e6c:	8082                	ret

0000000080000e6e <initlock>:
{
    80000e6e:	1101                	addi	sp,sp,-32
    80000e70:	ec06                	sd	ra,24(sp)
    80000e72:	e822                	sd	s0,16(sp)
    80000e74:	e426                	sd	s1,8(sp)
    80000e76:	1000                	addi	s0,sp,32
    80000e78:	84aa                	mv	s1,a0
  lk->name = name;
    80000e7a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e7c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e80:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e84:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e88:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e8c:	00010517          	auipc	a0,0x10
    80000e90:	53c50513          	addi	a0,a0,1340 # 800113c8 <lock_locks>
    80000e94:	00000097          	auipc	ra,0x0
    80000e98:	e5e080e7          	jalr	-418(ra) # 80000cf2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e9c:	00010717          	auipc	a4,0x10
    80000ea0:	54c70713          	addi	a4,a4,1356 # 800113e8 <locks>
    80000ea4:	4781                	li	a5,0
    80000ea6:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000eaa:	6314                	ld	a3,0(a4)
    80000eac:	ce89                	beqz	a3,80000ec6 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000eae:	2785                	addiw	a5,a5,1
    80000eb0:	0721                	addi	a4,a4,8
    80000eb2:	fec79ce3          	bne	a5,a2,80000eaa <initlock+0x3c>
  panic("findslot");
    80000eb6:	00007517          	auipc	a0,0x7
    80000eba:	1ea50513          	addi	a0,a0,490 # 800080a0 <digits+0x60>
    80000ebe:	fffff097          	auipc	ra,0xfffff
    80000ec2:	68e080e7          	jalr	1678(ra) # 8000054c <panic>
      locks[i] = lk;
    80000ec6:	078e                	slli	a5,a5,0x3
    80000ec8:	00010717          	auipc	a4,0x10
    80000ecc:	52070713          	addi	a4,a4,1312 # 800113e8 <locks>
    80000ed0:	97ba                	add	a5,a5,a4
    80000ed2:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ed4:	00010517          	auipc	a0,0x10
    80000ed8:	4f450513          	addi	a0,a0,1268 # 800113c8 <lock_locks>
    80000edc:	00000097          	auipc	ra,0x0
    80000ee0:	ee6080e7          	jalr	-282(ra) # 80000dc2 <release>
}
    80000ee4:	60e2                	ld	ra,24(sp)
    80000ee6:	6442                	ld	s0,16(sp)
    80000ee8:	64a2                	ld	s1,8(sp)
    80000eea:	6105                	addi	sp,sp,32
    80000eec:	8082                	ret

0000000080000eee <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000eee:	4e5c                	lw	a5,28(a2)
    80000ef0:	00f04463          	bgtz	a5,80000ef8 <snprint_lock+0xa>
  int n = 0;
    80000ef4:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ef6:	8082                	ret
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e406                	sd	ra,8(sp)
    80000efc:	e022                	sd	s0,0(sp)
    80000efe:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f00:	4e18                	lw	a4,24(a2)
    80000f02:	6614                	ld	a3,8(a2)
    80000f04:	00007617          	auipc	a2,0x7
    80000f08:	1ac60613          	addi	a2,a2,428 # 800080b0 <digits+0x70>
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	7b4080e7          	jalr	1972(ra) # 800066c0 <snprintf>
}
    80000f14:	60a2                	ld	ra,8(sp)
    80000f16:	6402                	ld	s0,0(sp)
    80000f18:	0141                	addi	sp,sp,16
    80000f1a:	8082                	ret

0000000080000f1c <statslock>:

int
statslock(char *buf, int sz) {
    80000f1c:	7159                	addi	sp,sp,-112
    80000f1e:	f486                	sd	ra,104(sp)
    80000f20:	f0a2                	sd	s0,96(sp)
    80000f22:	eca6                	sd	s1,88(sp)
    80000f24:	e8ca                	sd	s2,80(sp)
    80000f26:	e4ce                	sd	s3,72(sp)
    80000f28:	e0d2                	sd	s4,64(sp)
    80000f2a:	fc56                	sd	s5,56(sp)
    80000f2c:	f85a                	sd	s6,48(sp)
    80000f2e:	f45e                	sd	s7,40(sp)
    80000f30:	f062                	sd	s8,32(sp)
    80000f32:	ec66                	sd	s9,24(sp)
    80000f34:	e86a                	sd	s10,16(sp)
    80000f36:	e46e                	sd	s11,8(sp)
    80000f38:	1880                	addi	s0,sp,112
    80000f3a:	8aaa                	mv	s5,a0
    80000f3c:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f3e:	00010517          	auipc	a0,0x10
    80000f42:	48a50513          	addi	a0,a0,1162 # 800113c8 <lock_locks>
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	dac080e7          	jalr	-596(ra) # 80000cf2 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f4e:	00007617          	auipc	a2,0x7
    80000f52:	19260613          	addi	a2,a2,402 # 800080e0 <digits+0xa0>
    80000f56:	85da                	mv	a1,s6
    80000f58:	8556                	mv	a0,s5
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	766080e7          	jalr	1894(ra) # 800066c0 <snprintf>
    80000f62:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f64:	00010c97          	auipc	s9,0x10
    80000f68:	484c8c93          	addi	s9,s9,1156 # 800113e8 <locks>
    80000f6c:	00011c17          	auipc	s8,0x11
    80000f70:	41cc0c13          	addi	s8,s8,1052 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f74:	84e6                	mv	s1,s9
  int tot = 0;
    80000f76:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f78:	00007b97          	auipc	s7,0x7
    80000f7c:	188b8b93          	addi	s7,s7,392 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f80:	00007d17          	auipc	s10,0x7
    80000f84:	0e8d0d13          	addi	s10,s10,232 # 80008068 <digits+0x28>
    80000f88:	a01d                	j	80000fae <statslock+0x92>
      tot += locks[i]->nts;
    80000f8a:	0009b603          	ld	a2,0(s3)
    80000f8e:	4e1c                	lw	a5,24(a2)
    80000f90:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f94:	412b05bb          	subw	a1,s6,s2
    80000f98:	012a8533          	add	a0,s5,s2
    80000f9c:	00000097          	auipc	ra,0x0
    80000fa0:	f52080e7          	jalr	-174(ra) # 80000eee <snprint_lock>
    80000fa4:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000fa8:	04a1                	addi	s1,s1,8
    80000faa:	05848763          	beq	s1,s8,80000ff8 <statslock+0xdc>
    if(locks[i] == 0)
    80000fae:	89a6                	mv	s3,s1
    80000fb0:	609c                	ld	a5,0(s1)
    80000fb2:	c3b9                	beqz	a5,80000ff8 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fb4:	0087bd83          	ld	s11,8(a5)
    80000fb8:	855e                	mv	a0,s7
    80000fba:	00000097          	auipc	ra,0x0
    80000fbe:	29c080e7          	jalr	668(ra) # 80001256 <strlen>
    80000fc2:	0005061b          	sext.w	a2,a0
    80000fc6:	85de                	mv	a1,s7
    80000fc8:	856e                	mv	a0,s11
    80000fca:	00000097          	auipc	ra,0x0
    80000fce:	1e0080e7          	jalr	480(ra) # 800011aa <strncmp>
    80000fd2:	dd45                	beqz	a0,80000f8a <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fd4:	609c                	ld	a5,0(s1)
    80000fd6:	0087bd83          	ld	s11,8(a5)
    80000fda:	856a                	mv	a0,s10
    80000fdc:	00000097          	auipc	ra,0x0
    80000fe0:	27a080e7          	jalr	634(ra) # 80001256 <strlen>
    80000fe4:	0005061b          	sext.w	a2,a0
    80000fe8:	85ea                	mv	a1,s10
    80000fea:	856e                	mv	a0,s11
    80000fec:	00000097          	auipc	ra,0x0
    80000ff0:	1be080e7          	jalr	446(ra) # 800011aa <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000ff4:	f955                	bnez	a0,80000fa8 <statslock+0x8c>
    80000ff6:	bf51                	j	80000f8a <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000ff8:	00007617          	auipc	a2,0x7
    80000ffc:	11060613          	addi	a2,a2,272 # 80008108 <digits+0xc8>
    80001000:	412b05bb          	subw	a1,s6,s2
    80001004:	012a8533          	add	a0,s5,s2
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	6b8080e7          	jalr	1720(ra) # 800066c0 <snprintf>
    80001010:	012509bb          	addw	s3,a0,s2
    80001014:	4b95                	li	s7,5
  int last = 100000000;
    80001016:	05f5e537          	lui	a0,0x5f5e
    8000101a:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000101e:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001020:	00010497          	auipc	s1,0x10
    80001024:	3c848493          	addi	s1,s1,968 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001028:	1f400913          	li	s2,500
    8000102c:	a881                	j	8000107c <statslock+0x160>
    8000102e:	2705                	addiw	a4,a4,1
    80001030:	06a1                	addi	a3,a3,8
    80001032:	03270063          	beq	a4,s2,80001052 <statslock+0x136>
      if(locks[i] == 0)
    80001036:	629c                	ld	a5,0(a3)
    80001038:	cf89                	beqz	a5,80001052 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000103a:	4f90                	lw	a2,24(a5)
    8000103c:	00359793          	slli	a5,a1,0x3
    80001040:	97a6                	add	a5,a5,s1
    80001042:	639c                	ld	a5,0(a5)
    80001044:	4f9c                	lw	a5,24(a5)
    80001046:	fec7d4e3          	bge	a5,a2,8000102e <statslock+0x112>
    8000104a:	fea652e3          	bge	a2,a0,8000102e <statslock+0x112>
    8000104e:	85ba                	mv	a1,a4
    80001050:	bff9                	j	8000102e <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001052:	058e                	slli	a1,a1,0x3
    80001054:	00b48d33          	add	s10,s1,a1
    80001058:	000d3603          	ld	a2,0(s10)
    8000105c:	413b05bb          	subw	a1,s6,s3
    80001060:	013a8533          	add	a0,s5,s3
    80001064:	00000097          	auipc	ra,0x0
    80001068:	e8a080e7          	jalr	-374(ra) # 80000eee <snprint_lock>
    8000106c:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001070:	000d3783          	ld	a5,0(s10)
    80001074:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001076:	3bfd                	addiw	s7,s7,-1
    80001078:	000b8663          	beqz	s7,80001084 <statslock+0x168>
  int tot = 0;
    8000107c:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    8000107e:	8762                	mv	a4,s8
    int top = 0;
    80001080:	85e2                	mv	a1,s8
    80001082:	bf55                	j	80001036 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001084:	86d2                	mv	a3,s4
    80001086:	00007617          	auipc	a2,0x7
    8000108a:	0a260613          	addi	a2,a2,162 # 80008128 <digits+0xe8>
    8000108e:	413b05bb          	subw	a1,s6,s3
    80001092:	013a8533          	add	a0,s5,s3
    80001096:	00005097          	auipc	ra,0x5
    8000109a:	62a080e7          	jalr	1578(ra) # 800066c0 <snprintf>
    8000109e:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    800010a2:	00010517          	auipc	a0,0x10
    800010a6:	32650513          	addi	a0,a0,806 # 800113c8 <lock_locks>
    800010aa:	00000097          	auipc	ra,0x0
    800010ae:	d18080e7          	jalr	-744(ra) # 80000dc2 <release>
  return n;
}
    800010b2:	854e                	mv	a0,s3
    800010b4:	70a6                	ld	ra,104(sp)
    800010b6:	7406                	ld	s0,96(sp)
    800010b8:	64e6                	ld	s1,88(sp)
    800010ba:	6946                	ld	s2,80(sp)
    800010bc:	69a6                	ld	s3,72(sp)
    800010be:	6a06                	ld	s4,64(sp)
    800010c0:	7ae2                	ld	s5,56(sp)
    800010c2:	7b42                	ld	s6,48(sp)
    800010c4:	7ba2                	ld	s7,40(sp)
    800010c6:	7c02                	ld	s8,32(sp)
    800010c8:	6ce2                	ld	s9,24(sp)
    800010ca:	6d42                	ld	s10,16(sp)
    800010cc:	6da2                	ld	s11,8(sp)
    800010ce:	6165                	addi	sp,sp,112
    800010d0:	8082                	ret

00000000800010d2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010d2:	1141                	addi	sp,sp,-16
    800010d4:	e422                	sd	s0,8(sp)
    800010d6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010d8:	ca19                	beqz	a2,800010ee <memset+0x1c>
    800010da:	87aa                	mv	a5,a0
    800010dc:	1602                	slli	a2,a2,0x20
    800010de:	9201                	srli	a2,a2,0x20
    800010e0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010e4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010e8:	0785                	addi	a5,a5,1
    800010ea:	fee79de3          	bne	a5,a4,800010e4 <memset+0x12>
  }
  return dst;
}
    800010ee:	6422                	ld	s0,8(sp)
    800010f0:	0141                	addi	sp,sp,16
    800010f2:	8082                	ret

00000000800010f4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010f4:	1141                	addi	sp,sp,-16
    800010f6:	e422                	sd	s0,8(sp)
    800010f8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010fa:	ca05                	beqz	a2,8000112a <memcmp+0x36>
    800010fc:	fff6069b          	addiw	a3,a2,-1
    80001100:	1682                	slli	a3,a3,0x20
    80001102:	9281                	srli	a3,a3,0x20
    80001104:	0685                	addi	a3,a3,1
    80001106:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80001108:	00054783          	lbu	a5,0(a0)
    8000110c:	0005c703          	lbu	a4,0(a1)
    80001110:	00e79863          	bne	a5,a4,80001120 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001114:	0505                	addi	a0,a0,1
    80001116:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001118:	fed518e3          	bne	a0,a3,80001108 <memcmp+0x14>
  }

  return 0;
    8000111c:	4501                	li	a0,0
    8000111e:	a019                	j	80001124 <memcmp+0x30>
      return *s1 - *s2;
    80001120:	40e7853b          	subw	a0,a5,a4
}
    80001124:	6422                	ld	s0,8(sp)
    80001126:	0141                	addi	sp,sp,16
    80001128:	8082                	ret
  return 0;
    8000112a:	4501                	li	a0,0
    8000112c:	bfe5                	j	80001124 <memcmp+0x30>

000000008000112e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000112e:	1141                	addi	sp,sp,-16
    80001130:	e422                	sd	s0,8(sp)
    80001132:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001134:	02a5e563          	bltu	a1,a0,8000115e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001138:	fff6069b          	addiw	a3,a2,-1
    8000113c:	ce11                	beqz	a2,80001158 <memmove+0x2a>
    8000113e:	1682                	slli	a3,a3,0x20
    80001140:	9281                	srli	a3,a3,0x20
    80001142:	0685                	addi	a3,a3,1
    80001144:	96ae                	add	a3,a3,a1
    80001146:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001148:	0585                	addi	a1,a1,1
    8000114a:	0785                	addi	a5,a5,1
    8000114c:	fff5c703          	lbu	a4,-1(a1)
    80001150:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001154:	fed59ae3          	bne	a1,a3,80001148 <memmove+0x1a>

  return dst;
}
    80001158:	6422                	ld	s0,8(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
  if(s < d && s + n > d){
    8000115e:	02061713          	slli	a4,a2,0x20
    80001162:	9301                	srli	a4,a4,0x20
    80001164:	00e587b3          	add	a5,a1,a4
    80001168:	fcf578e3          	bgeu	a0,a5,80001138 <memmove+0xa>
    d += n;
    8000116c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    8000116e:	fff6069b          	addiw	a3,a2,-1
    80001172:	d27d                	beqz	a2,80001158 <memmove+0x2a>
    80001174:	02069613          	slli	a2,a3,0x20
    80001178:	9201                	srli	a2,a2,0x20
    8000117a:	fff64613          	not	a2,a2
    8000117e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001180:	17fd                	addi	a5,a5,-1
    80001182:	177d                	addi	a4,a4,-1
    80001184:	0007c683          	lbu	a3,0(a5)
    80001188:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000118c:	fef61ae3          	bne	a2,a5,80001180 <memmove+0x52>
    80001190:	b7e1                	j	80001158 <memmove+0x2a>

0000000080001192 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001192:	1141                	addi	sp,sp,-16
    80001194:	e406                	sd	ra,8(sp)
    80001196:	e022                	sd	s0,0(sp)
    80001198:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	f94080e7          	jalr	-108(ra) # 8000112e <memmove>
}
    800011a2:	60a2                	ld	ra,8(sp)
    800011a4:	6402                	ld	s0,0(sp)
    800011a6:	0141                	addi	sp,sp,16
    800011a8:	8082                	ret

00000000800011aa <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    800011aa:	1141                	addi	sp,sp,-16
    800011ac:	e422                	sd	s0,8(sp)
    800011ae:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011b0:	ce11                	beqz	a2,800011cc <strncmp+0x22>
    800011b2:	00054783          	lbu	a5,0(a0)
    800011b6:	cf89                	beqz	a5,800011d0 <strncmp+0x26>
    800011b8:	0005c703          	lbu	a4,0(a1)
    800011bc:	00f71a63          	bne	a4,a5,800011d0 <strncmp+0x26>
    n--, p++, q++;
    800011c0:	367d                	addiw	a2,a2,-1
    800011c2:	0505                	addi	a0,a0,1
    800011c4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011c6:	f675                	bnez	a2,800011b2 <strncmp+0x8>
  if(n == 0)
    return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	a809                	j	800011dc <strncmp+0x32>
    800011cc:	4501                	li	a0,0
    800011ce:	a039                	j	800011dc <strncmp+0x32>
  if(n == 0)
    800011d0:	ca09                	beqz	a2,800011e2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011d2:	00054503          	lbu	a0,0(a0)
    800011d6:	0005c783          	lbu	a5,0(a1)
    800011da:	9d1d                	subw	a0,a0,a5
}
    800011dc:	6422                	ld	s0,8(sp)
    800011de:	0141                	addi	sp,sp,16
    800011e0:	8082                	ret
    return 0;
    800011e2:	4501                	li	a0,0
    800011e4:	bfe5                	j	800011dc <strncmp+0x32>

00000000800011e6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011e6:	1141                	addi	sp,sp,-16
    800011e8:	e422                	sd	s0,8(sp)
    800011ea:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011ec:	872a                	mv	a4,a0
    800011ee:	8832                	mv	a6,a2
    800011f0:	367d                	addiw	a2,a2,-1
    800011f2:	01005963          	blez	a6,80001204 <strncpy+0x1e>
    800011f6:	0705                	addi	a4,a4,1
    800011f8:	0005c783          	lbu	a5,0(a1)
    800011fc:	fef70fa3          	sb	a5,-1(a4)
    80001200:	0585                	addi	a1,a1,1
    80001202:	f7f5                	bnez	a5,800011ee <strncpy+0x8>
    ;
  while(n-- > 0)
    80001204:	86ba                	mv	a3,a4
    80001206:	00c05c63          	blez	a2,8000121e <strncpy+0x38>
    *s++ = 0;
    8000120a:	0685                	addi	a3,a3,1
    8000120c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001210:	40d707bb          	subw	a5,a4,a3
    80001214:	37fd                	addiw	a5,a5,-1
    80001216:	010787bb          	addw	a5,a5,a6
    8000121a:	fef048e3          	bgtz	a5,8000120a <strncpy+0x24>
  return os;
}
    8000121e:	6422                	ld	s0,8(sp)
    80001220:	0141                	addi	sp,sp,16
    80001222:	8082                	ret

0000000080001224 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001224:	1141                	addi	sp,sp,-16
    80001226:	e422                	sd	s0,8(sp)
    80001228:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000122a:	02c05363          	blez	a2,80001250 <safestrcpy+0x2c>
    8000122e:	fff6069b          	addiw	a3,a2,-1
    80001232:	1682                	slli	a3,a3,0x20
    80001234:	9281                	srli	a3,a3,0x20
    80001236:	96ae                	add	a3,a3,a1
    80001238:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000123a:	00d58963          	beq	a1,a3,8000124c <safestrcpy+0x28>
    8000123e:	0585                	addi	a1,a1,1
    80001240:	0785                	addi	a5,a5,1
    80001242:	fff5c703          	lbu	a4,-1(a1)
    80001246:	fee78fa3          	sb	a4,-1(a5)
    8000124a:	fb65                	bnez	a4,8000123a <safestrcpy+0x16>
    ;
  *s = 0;
    8000124c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001250:	6422                	ld	s0,8(sp)
    80001252:	0141                	addi	sp,sp,16
    80001254:	8082                	ret

0000000080001256 <strlen>:

int
strlen(const char *s)
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e422                	sd	s0,8(sp)
    8000125a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000125c:	00054783          	lbu	a5,0(a0)
    80001260:	cf91                	beqz	a5,8000127c <strlen+0x26>
    80001262:	0505                	addi	a0,a0,1
    80001264:	87aa                	mv	a5,a0
    80001266:	4685                	li	a3,1
    80001268:	9e89                	subw	a3,a3,a0
    8000126a:	00f6853b          	addw	a0,a3,a5
    8000126e:	0785                	addi	a5,a5,1
    80001270:	fff7c703          	lbu	a4,-1(a5)
    80001274:	fb7d                	bnez	a4,8000126a <strlen+0x14>
    ;
  return n;
}
    80001276:	6422                	ld	s0,8(sp)
    80001278:	0141                	addi	sp,sp,16
    8000127a:	8082                	ret
  for(n = 0; s[n]; n++)
    8000127c:	4501                	li	a0,0
    8000127e:	bfe5                	j	80001276 <strlen+0x20>

0000000080001280 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001280:	1141                	addi	sp,sp,-16
    80001282:	e406                	sd	ra,8(sp)
    80001284:	e022                	sd	s0,0(sp)
    80001286:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001288:	00001097          	auipc	ra,0x1
    8000128c:	a84080e7          	jalr	-1404(ra) # 80001d0c <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001290:	00008717          	auipc	a4,0x8
    80001294:	d7c70713          	addi	a4,a4,-644 # 8000900c <started>
  if(cpuid() == 0){
    80001298:	c139                	beqz	a0,800012de <main+0x5e>
    while(started == 0)
    8000129a:	431c                	lw	a5,0(a4)
    8000129c:	2781                	sext.w	a5,a5
    8000129e:	dff5                	beqz	a5,8000129a <main+0x1a>
      ;
    __sync_synchronize();
    800012a0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    800012a4:	00001097          	auipc	ra,0x1
    800012a8:	a68080e7          	jalr	-1432(ra) # 80001d0c <cpuid>
    800012ac:	85aa                	mv	a1,a0
    800012ae:	00007517          	auipc	a0,0x7
    800012b2:	ea250513          	addi	a0,a0,-350 # 80008150 <digits+0x110>
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	2e0080e7          	jalr	736(ra) # 80000596 <printf>
    kvminithart();    // turn on paging
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	186080e7          	jalr	390(ra) # 80001444 <kvminithart>
    trapinithart();   // install kernel trap vector
    800012c6:	00001097          	auipc	ra,0x1
    800012ca:	6d2080e7          	jalr	1746(ra) # 80002998 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012ce:	00005097          	auipc	ra,0x5
    800012d2:	c82080e7          	jalr	-894(ra) # 80005f50 <plicinithart>
  }

  scheduler();        
    800012d6:	00001097          	auipc	ra,0x1
    800012da:	f9a080e7          	jalr	-102(ra) # 80002270 <scheduler>
    consoleinit();
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	17e080e7          	jalr	382(ra) # 8000045c <consoleinit>
    statsinit();
    800012e6:	00005097          	auipc	ra,0x5
    800012ea:	2fc080e7          	jalr	764(ra) # 800065e2 <statsinit>
    printfinit();
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	488080e7          	jalr	1160(ra) # 80000776 <printfinit>
    printf("\n");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e6a50513          	addi	a0,a0,-406 # 80008160 <digits+0x120>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	298080e7          	jalr	664(ra) # 80000596 <printf>
    printf("xv6 kernel is booting\n");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e3250513          	addi	a0,a0,-462 # 80008138 <digits+0xf8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	288080e7          	jalr	648(ra) # 80000596 <printf>
    printf("\n");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e4a50513          	addi	a0,a0,-438 # 80008160 <digits+0x120>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	278080e7          	jalr	632(ra) # 80000596 <printf>
    kinit();         // physical page allocator
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	7e4080e7          	jalr	2020(ra) # 80000b0a <kinit>
    kvminit();       // create kernel page table
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	242080e7          	jalr	578(ra) # 80001570 <kvminit>
    kvminithart();   // turn on paging
    80001336:	00000097          	auipc	ra,0x0
    8000133a:	10e080e7          	jalr	270(ra) # 80001444 <kvminithart>
    procinit();      // process table
    8000133e:	00001097          	auipc	ra,0x1
    80001342:	8fe080e7          	jalr	-1794(ra) # 80001c3c <procinit>
    trapinit();      // trap vectors
    80001346:	00001097          	auipc	ra,0x1
    8000134a:	62a080e7          	jalr	1578(ra) # 80002970 <trapinit>
    trapinithart();  // install kernel trap vector
    8000134e:	00001097          	auipc	ra,0x1
    80001352:	64a080e7          	jalr	1610(ra) # 80002998 <trapinithart>
    plicinit();      // set up interrupt controller
    80001356:	00005097          	auipc	ra,0x5
    8000135a:	be4080e7          	jalr	-1052(ra) # 80005f3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000135e:	00005097          	auipc	ra,0x5
    80001362:	bf2080e7          	jalr	-1038(ra) # 80005f50 <plicinithart>
    binit();         // buffer cache
    80001366:	00002097          	auipc	ra,0x2
    8000136a:	d74080e7          	jalr	-652(ra) # 800030da <binit>
    iinit();         // inode cache
    8000136e:	00002097          	auipc	ra,0x2
    80001372:	402080e7          	jalr	1026(ra) # 80003770 <iinit>
    fileinit();      // file table
    80001376:	00003097          	auipc	ra,0x3
    8000137a:	3ba080e7          	jalr	954(ra) # 80004730 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000137e:	00005097          	auipc	ra,0x5
    80001382:	cf2080e7          	jalr	-782(ra) # 80006070 <virtio_disk_init>
    userinit();      // first user process
    80001386:	00001097          	auipc	ra,0x1
    8000138a:	c7c080e7          	jalr	-900(ra) # 80002002 <userinit>
    __sync_synchronize();
    8000138e:	0ff0000f          	fence
    started = 1;
    80001392:	4785                	li	a5,1
    80001394:	00008717          	auipc	a4,0x8
    80001398:	c6f72c23          	sw	a5,-904(a4) # 8000900c <started>
    8000139c:	bf2d                	j	800012d6 <main+0x56>

000000008000139e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000139e:	7139                	addi	sp,sp,-64
    800013a0:	fc06                	sd	ra,56(sp)
    800013a2:	f822                	sd	s0,48(sp)
    800013a4:	f426                	sd	s1,40(sp)
    800013a6:	f04a                	sd	s2,32(sp)
    800013a8:	ec4e                	sd	s3,24(sp)
    800013aa:	e852                	sd	s4,16(sp)
    800013ac:	e456                	sd	s5,8(sp)
    800013ae:	e05a                	sd	s6,0(sp)
    800013b0:	0080                	addi	s0,sp,64
    800013b2:	84aa                	mv	s1,a0
    800013b4:	89ae                	mv	s3,a1
    800013b6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013b8:	57fd                	li	a5,-1
    800013ba:	83e9                	srli	a5,a5,0x1a
    800013bc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013be:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013c0:	04b7f263          	bgeu	a5,a1,80001404 <walk+0x66>
    panic("walk");
    800013c4:	00007517          	auipc	a0,0x7
    800013c8:	da450513          	addi	a0,a0,-604 # 80008168 <digits+0x128>
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	180080e7          	jalr	384(ra) # 8000054c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013d4:	060a8663          	beqz	s5,80001440 <walk+0xa2>
    800013d8:	fffff097          	auipc	ra,0xfffff
    800013dc:	78e080e7          	jalr	1934(ra) # 80000b66 <kalloc>
    800013e0:	84aa                	mv	s1,a0
    800013e2:	c529                	beqz	a0,8000142c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013e4:	6605                	lui	a2,0x1
    800013e6:	4581                	li	a1,0
    800013e8:	00000097          	auipc	ra,0x0
    800013ec:	cea080e7          	jalr	-790(ra) # 800010d2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013f0:	00c4d793          	srli	a5,s1,0xc
    800013f4:	07aa                	slli	a5,a5,0xa
    800013f6:	0017e793          	ori	a5,a5,1
    800013fa:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013fe:	3a5d                	addiw	s4,s4,-9
    80001400:	036a0063          	beq	s4,s6,80001420 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001404:	0149d933          	srl	s2,s3,s4
    80001408:	1ff97913          	andi	s2,s2,511
    8000140c:	090e                	slli	s2,s2,0x3
    8000140e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001410:	00093483          	ld	s1,0(s2)
    80001414:	0014f793          	andi	a5,s1,1
    80001418:	dfd5                	beqz	a5,800013d4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000141a:	80a9                	srli	s1,s1,0xa
    8000141c:	04b2                	slli	s1,s1,0xc
    8000141e:	b7c5                	j	800013fe <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001420:	00c9d513          	srli	a0,s3,0xc
    80001424:	1ff57513          	andi	a0,a0,511
    80001428:	050e                	slli	a0,a0,0x3
    8000142a:	9526                	add	a0,a0,s1
}
    8000142c:	70e2                	ld	ra,56(sp)
    8000142e:	7442                	ld	s0,48(sp)
    80001430:	74a2                	ld	s1,40(sp)
    80001432:	7902                	ld	s2,32(sp)
    80001434:	69e2                	ld	s3,24(sp)
    80001436:	6a42                	ld	s4,16(sp)
    80001438:	6aa2                	ld	s5,8(sp)
    8000143a:	6b02                	ld	s6,0(sp)
    8000143c:	6121                	addi	sp,sp,64
    8000143e:	8082                	ret
        return 0;
    80001440:	4501                	li	a0,0
    80001442:	b7ed                	j	8000142c <walk+0x8e>

0000000080001444 <kvminithart>:
{
    80001444:	1141                	addi	sp,sp,-16
    80001446:	e422                	sd	s0,8(sp)
    80001448:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000144a:	00008797          	auipc	a5,0x8
    8000144e:	bc67b783          	ld	a5,-1082(a5) # 80009010 <kernel_pagetable>
    80001452:	83b1                	srli	a5,a5,0xc
    80001454:	577d                	li	a4,-1
    80001456:	177e                	slli	a4,a4,0x3f
    80001458:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000145a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000145e:	12000073          	sfence.vma
}
    80001462:	6422                	ld	s0,8(sp)
    80001464:	0141                	addi	sp,sp,16
    80001466:	8082                	ret

0000000080001468 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001468:	57fd                	li	a5,-1
    8000146a:	83e9                	srli	a5,a5,0x1a
    8000146c:	00b7f463          	bgeu	a5,a1,80001474 <walkaddr+0xc>
    return 0;
    80001470:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001472:	8082                	ret
{
    80001474:	1141                	addi	sp,sp,-16
    80001476:	e406                	sd	ra,8(sp)
    80001478:	e022                	sd	s0,0(sp)
    8000147a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000147c:	4601                	li	a2,0
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	f20080e7          	jalr	-224(ra) # 8000139e <walk>
  if(pte == 0)
    80001486:	c105                	beqz	a0,800014a6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001488:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000148a:	0117f693          	andi	a3,a5,17
    8000148e:	4745                	li	a4,17
    return 0;
    80001490:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001492:	00e68663          	beq	a3,a4,8000149e <walkaddr+0x36>
}
    80001496:	60a2                	ld	ra,8(sp)
    80001498:	6402                	ld	s0,0(sp)
    8000149a:	0141                	addi	sp,sp,16
    8000149c:	8082                	ret
  pa = PTE2PA(*pte);
    8000149e:	83a9                	srli	a5,a5,0xa
    800014a0:	00c79513          	slli	a0,a5,0xc
  return pa;
    800014a4:	bfcd                	j	80001496 <walkaddr+0x2e>
    return 0;
    800014a6:	4501                	li	a0,0
    800014a8:	b7fd                	j	80001496 <walkaddr+0x2e>

00000000800014aa <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800014aa:	715d                	addi	sp,sp,-80
    800014ac:	e486                	sd	ra,72(sp)
    800014ae:	e0a2                	sd	s0,64(sp)
    800014b0:	fc26                	sd	s1,56(sp)
    800014b2:	f84a                	sd	s2,48(sp)
    800014b4:	f44e                	sd	s3,40(sp)
    800014b6:	f052                	sd	s4,32(sp)
    800014b8:	ec56                	sd	s5,24(sp)
    800014ba:	e85a                	sd	s6,16(sp)
    800014bc:	e45e                	sd	s7,8(sp)
    800014be:	0880                	addi	s0,sp,80
    800014c0:	8aaa                	mv	s5,a0
    800014c2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014c4:	777d                	lui	a4,0xfffff
    800014c6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014ca:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800014ce:	99ae                	add	s3,s3,a1
    800014d0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014d4:	893e                	mv	s2,a5
    800014d6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014da:	6b85                	lui	s7,0x1
    800014dc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014e0:	4605                	li	a2,1
    800014e2:	85ca                	mv	a1,s2
    800014e4:	8556                	mv	a0,s5
    800014e6:	00000097          	auipc	ra,0x0
    800014ea:	eb8080e7          	jalr	-328(ra) # 8000139e <walk>
    800014ee:	c51d                	beqz	a0,8000151c <mappages+0x72>
    if(*pte & PTE_V)
    800014f0:	611c                	ld	a5,0(a0)
    800014f2:	8b85                	andi	a5,a5,1
    800014f4:	ef81                	bnez	a5,8000150c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014f6:	80b1                	srli	s1,s1,0xc
    800014f8:	04aa                	slli	s1,s1,0xa
    800014fa:	0164e4b3          	or	s1,s1,s6
    800014fe:	0014e493          	ori	s1,s1,1
    80001502:	e104                	sd	s1,0(a0)
    if(a == last)
    80001504:	03390863          	beq	s2,s3,80001534 <mappages+0x8a>
    a += PGSIZE;
    80001508:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000150a:	bfc9                	j	800014dc <mappages+0x32>
      panic("remap");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6450513          	addi	a0,a0,-924 # 80008170 <digits+0x130>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	038080e7          	jalr	56(ra) # 8000054c <panic>
      return -1;
    8000151c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000151e:	60a6                	ld	ra,72(sp)
    80001520:	6406                	ld	s0,64(sp)
    80001522:	74e2                	ld	s1,56(sp)
    80001524:	7942                	ld	s2,48(sp)
    80001526:	79a2                	ld	s3,40(sp)
    80001528:	7a02                	ld	s4,32(sp)
    8000152a:	6ae2                	ld	s5,24(sp)
    8000152c:	6b42                	ld	s6,16(sp)
    8000152e:	6ba2                	ld	s7,8(sp)
    80001530:	6161                	addi	sp,sp,80
    80001532:	8082                	ret
  return 0;
    80001534:	4501                	li	a0,0
    80001536:	b7e5                	j	8000151e <mappages+0x74>

0000000080001538 <kvmmap>:
{
    80001538:	1141                	addi	sp,sp,-16
    8000153a:	e406                	sd	ra,8(sp)
    8000153c:	e022                	sd	s0,0(sp)
    8000153e:	0800                	addi	s0,sp,16
    80001540:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001542:	86ae                	mv	a3,a1
    80001544:	85aa                	mv	a1,a0
    80001546:	00008517          	auipc	a0,0x8
    8000154a:	aca53503          	ld	a0,-1334(a0) # 80009010 <kernel_pagetable>
    8000154e:	00000097          	auipc	ra,0x0
    80001552:	f5c080e7          	jalr	-164(ra) # 800014aa <mappages>
    80001556:	e509                	bnez	a0,80001560 <kvmmap+0x28>
}
    80001558:	60a2                	ld	ra,8(sp)
    8000155a:	6402                	ld	s0,0(sp)
    8000155c:	0141                	addi	sp,sp,16
    8000155e:	8082                	ret
    panic("kvmmap");
    80001560:	00007517          	auipc	a0,0x7
    80001564:	c1850513          	addi	a0,a0,-1000 # 80008178 <digits+0x138>
    80001568:	fffff097          	auipc	ra,0xfffff
    8000156c:	fe4080e7          	jalr	-28(ra) # 8000054c <panic>

0000000080001570 <kvminit>:
{
    80001570:	1101                	addi	sp,sp,-32
    80001572:	ec06                	sd	ra,24(sp)
    80001574:	e822                	sd	s0,16(sp)
    80001576:	e426                	sd	s1,8(sp)
    80001578:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000157a:	fffff097          	auipc	ra,0xfffff
    8000157e:	5ec080e7          	jalr	1516(ra) # 80000b66 <kalloc>
    80001582:	00008717          	auipc	a4,0x8
    80001586:	a8a73723          	sd	a0,-1394(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	4581                	li	a1,0
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	b44080e7          	jalr	-1212(ra) # 800010d2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001596:	4699                	li	a3,6
    80001598:	6605                	lui	a2,0x1
    8000159a:	100005b7          	lui	a1,0x10000
    8000159e:	10000537          	lui	a0,0x10000
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	f96080e7          	jalr	-106(ra) # 80001538 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800015aa:	4699                	li	a3,6
    800015ac:	6605                	lui	a2,0x1
    800015ae:	100015b7          	lui	a1,0x10001
    800015b2:	10001537          	lui	a0,0x10001
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f82080e7          	jalr	-126(ra) # 80001538 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015be:	4699                	li	a3,6
    800015c0:	00400637          	lui	a2,0x400
    800015c4:	0c0005b7          	lui	a1,0xc000
    800015c8:	0c000537          	lui	a0,0xc000
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	f6c080e7          	jalr	-148(ra) # 80001538 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015d4:	00007497          	auipc	s1,0x7
    800015d8:	a2c48493          	addi	s1,s1,-1492 # 80008000 <etext>
    800015dc:	46a9                	li	a3,10
    800015de:	80007617          	auipc	a2,0x80007
    800015e2:	a2260613          	addi	a2,a2,-1502 # 8000 <_entry-0x7fff8000>
    800015e6:	4585                	li	a1,1
    800015e8:	05fe                	slli	a1,a1,0x1f
    800015ea:	852e                	mv	a0,a1
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	f4c080e7          	jalr	-180(ra) # 80001538 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015f4:	4699                	li	a3,6
    800015f6:	4645                	li	a2,17
    800015f8:	066e                	slli	a2,a2,0x1b
    800015fa:	8e05                	sub	a2,a2,s1
    800015fc:	85a6                	mv	a1,s1
    800015fe:	8526                	mv	a0,s1
    80001600:	00000097          	auipc	ra,0x0
    80001604:	f38080e7          	jalr	-200(ra) # 80001538 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001608:	46a9                	li	a3,10
    8000160a:	6605                	lui	a2,0x1
    8000160c:	00006597          	auipc	a1,0x6
    80001610:	9f458593          	addi	a1,a1,-1548 # 80007000 <_trampoline>
    80001614:	04000537          	lui	a0,0x4000
    80001618:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    8000161a:	0532                	slli	a0,a0,0xc
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	f1c080e7          	jalr	-228(ra) # 80001538 <kvmmap>
}
    80001624:	60e2                	ld	ra,24(sp)
    80001626:	6442                	ld	s0,16(sp)
    80001628:	64a2                	ld	s1,8(sp)
    8000162a:	6105                	addi	sp,sp,32
    8000162c:	8082                	ret

000000008000162e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000162e:	715d                	addi	sp,sp,-80
    80001630:	e486                	sd	ra,72(sp)
    80001632:	e0a2                	sd	s0,64(sp)
    80001634:	fc26                	sd	s1,56(sp)
    80001636:	f84a                	sd	s2,48(sp)
    80001638:	f44e                	sd	s3,40(sp)
    8000163a:	f052                	sd	s4,32(sp)
    8000163c:	ec56                	sd	s5,24(sp)
    8000163e:	e85a                	sd	s6,16(sp)
    80001640:	e45e                	sd	s7,8(sp)
    80001642:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001644:	03459793          	slli	a5,a1,0x34
    80001648:	e795                	bnez	a5,80001674 <uvmunmap+0x46>
    8000164a:	8a2a                	mv	s4,a0
    8000164c:	892e                	mv	s2,a1
    8000164e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001650:	0632                	slli	a2,a2,0xc
    80001652:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001656:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001658:	6b05                	lui	s6,0x1
    8000165a:	0735e263          	bltu	a1,s3,800016be <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
    panic("uvmunmap: not aligned");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b0c50513          	addi	a0,a0,-1268 # 80008180 <digits+0x140>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ed0080e7          	jalr	-304(ra) # 8000054c <panic>
      panic("uvmunmap: walk");
    80001684:	00007517          	auipc	a0,0x7
    80001688:	b1450513          	addi	a0,a0,-1260 # 80008198 <digits+0x158>
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	ec0080e7          	jalr	-320(ra) # 8000054c <panic>
      panic("uvmunmap: not mapped");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b1450513          	addi	a0,a0,-1260 # 800081a8 <digits+0x168>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	eb0080e7          	jalr	-336(ra) # 8000054c <panic>
      panic("uvmunmap: not a leaf");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	b1c50513          	addi	a0,a0,-1252 # 800081c0 <digits+0x180>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	ea0080e7          	jalr	-352(ra) # 8000054c <panic>
    *pte = 0;
    800016b4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016b8:	995a                	add	s2,s2,s6
    800016ba:	fb3972e3          	bgeu	s2,s3,8000165e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016be:	4601                	li	a2,0
    800016c0:	85ca                	mv	a1,s2
    800016c2:	8552                	mv	a0,s4
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	cda080e7          	jalr	-806(ra) # 8000139e <walk>
    800016cc:	84aa                	mv	s1,a0
    800016ce:	d95d                	beqz	a0,80001684 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016d0:	6108                	ld	a0,0(a0)
    800016d2:	00157793          	andi	a5,a0,1
    800016d6:	dfdd                	beqz	a5,80001694 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016d8:	3ff57793          	andi	a5,a0,1023
    800016dc:	fd7784e3          	beq	a5,s7,800016a4 <uvmunmap+0x76>
    if(do_free){
    800016e0:	fc0a8ae3          	beqz	s5,800016b4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016e4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016e6:	0532                	slli	a0,a0,0xc
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	330080e7          	jalr	816(ra) # 80000a18 <kfree>
    800016f0:	b7d1                	j	800016b4 <uvmunmap+0x86>

00000000800016f2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016f2:	1101                	addi	sp,sp,-32
    800016f4:	ec06                	sd	ra,24(sp)
    800016f6:	e822                	sd	s0,16(sp)
    800016f8:	e426                	sd	s1,8(sp)
    800016fa:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016fc:	fffff097          	auipc	ra,0xfffff
    80001700:	46a080e7          	jalr	1130(ra) # 80000b66 <kalloc>
    80001704:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001706:	c519                	beqz	a0,80001714 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001708:	6605                	lui	a2,0x1
    8000170a:	4581                	li	a1,0
    8000170c:	00000097          	auipc	ra,0x0
    80001710:	9c6080e7          	jalr	-1594(ra) # 800010d2 <memset>
  return pagetable;
}
    80001714:	8526                	mv	a0,s1
    80001716:	60e2                	ld	ra,24(sp)
    80001718:	6442                	ld	s0,16(sp)
    8000171a:	64a2                	ld	s1,8(sp)
    8000171c:	6105                	addi	sp,sp,32
    8000171e:	8082                	ret

0000000080001720 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001720:	7179                	addi	sp,sp,-48
    80001722:	f406                	sd	ra,40(sp)
    80001724:	f022                	sd	s0,32(sp)
    80001726:	ec26                	sd	s1,24(sp)
    80001728:	e84a                	sd	s2,16(sp)
    8000172a:	e44e                	sd	s3,8(sp)
    8000172c:	e052                	sd	s4,0(sp)
    8000172e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001730:	6785                	lui	a5,0x1
    80001732:	04f67863          	bgeu	a2,a5,80001782 <uvminit+0x62>
    80001736:	8a2a                	mv	s4,a0
    80001738:	89ae                	mv	s3,a1
    8000173a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000173c:	fffff097          	auipc	ra,0xfffff
    80001740:	42a080e7          	jalr	1066(ra) # 80000b66 <kalloc>
    80001744:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001746:	6605                	lui	a2,0x1
    80001748:	4581                	li	a1,0
    8000174a:	00000097          	auipc	ra,0x0
    8000174e:	988080e7          	jalr	-1656(ra) # 800010d2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001752:	4779                	li	a4,30
    80001754:	86ca                	mv	a3,s2
    80001756:	6605                	lui	a2,0x1
    80001758:	4581                	li	a1,0
    8000175a:	8552                	mv	a0,s4
    8000175c:	00000097          	auipc	ra,0x0
    80001760:	d4e080e7          	jalr	-690(ra) # 800014aa <mappages>
  memmove(mem, src, sz);
    80001764:	8626                	mv	a2,s1
    80001766:	85ce                	mv	a1,s3
    80001768:	854a                	mv	a0,s2
    8000176a:	00000097          	auipc	ra,0x0
    8000176e:	9c4080e7          	jalr	-1596(ra) # 8000112e <memmove>
}
    80001772:	70a2                	ld	ra,40(sp)
    80001774:	7402                	ld	s0,32(sp)
    80001776:	64e2                	ld	s1,24(sp)
    80001778:	6942                	ld	s2,16(sp)
    8000177a:	69a2                	ld	s3,8(sp)
    8000177c:	6a02                	ld	s4,0(sp)
    8000177e:	6145                	addi	sp,sp,48
    80001780:	8082                	ret
    panic("inituvm: more than a page");
    80001782:	00007517          	auipc	a0,0x7
    80001786:	a5650513          	addi	a0,a0,-1450 # 800081d8 <digits+0x198>
    8000178a:	fffff097          	auipc	ra,0xfffff
    8000178e:	dc2080e7          	jalr	-574(ra) # 8000054c <panic>

0000000080001792 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001792:	1101                	addi	sp,sp,-32
    80001794:	ec06                	sd	ra,24(sp)
    80001796:	e822                	sd	s0,16(sp)
    80001798:	e426                	sd	s1,8(sp)
    8000179a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000179c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000179e:	00b67d63          	bgeu	a2,a1,800017b8 <uvmdealloc+0x26>
    800017a2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800017a4:	6785                	lui	a5,0x1
    800017a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017a8:	00f60733          	add	a4,a2,a5
    800017ac:	76fd                	lui	a3,0xfffff
    800017ae:	8f75                	and	a4,a4,a3
    800017b0:	97ae                	add	a5,a5,a1
    800017b2:	8ff5                	and	a5,a5,a3
    800017b4:	00f76863          	bltu	a4,a5,800017c4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017b8:	8526                	mv	a0,s1
    800017ba:	60e2                	ld	ra,24(sp)
    800017bc:	6442                	ld	s0,16(sp)
    800017be:	64a2                	ld	s1,8(sp)
    800017c0:	6105                	addi	sp,sp,32
    800017c2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017c4:	8f99                	sub	a5,a5,a4
    800017c6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017c8:	4685                	li	a3,1
    800017ca:	0007861b          	sext.w	a2,a5
    800017ce:	85ba                	mv	a1,a4
    800017d0:	00000097          	auipc	ra,0x0
    800017d4:	e5e080e7          	jalr	-418(ra) # 8000162e <uvmunmap>
    800017d8:	b7c5                	j	800017b8 <uvmdealloc+0x26>

00000000800017da <uvmalloc>:
  if(newsz < oldsz)
    800017da:	0ab66163          	bltu	a2,a1,8000187c <uvmalloc+0xa2>
{
    800017de:	7139                	addi	sp,sp,-64
    800017e0:	fc06                	sd	ra,56(sp)
    800017e2:	f822                	sd	s0,48(sp)
    800017e4:	f426                	sd	s1,40(sp)
    800017e6:	f04a                	sd	s2,32(sp)
    800017e8:	ec4e                	sd	s3,24(sp)
    800017ea:	e852                	sd	s4,16(sp)
    800017ec:	e456                	sd	s5,8(sp)
    800017ee:	0080                	addi	s0,sp,64
    800017f0:	8aaa                	mv	s5,a0
    800017f2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017f4:	6785                	lui	a5,0x1
    800017f6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017f8:	95be                	add	a1,a1,a5
    800017fa:	77fd                	lui	a5,0xfffff
    800017fc:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001800:	08c9f063          	bgeu	s3,a2,80001880 <uvmalloc+0xa6>
    80001804:	894e                	mv	s2,s3
    mem = kalloc();
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	360080e7          	jalr	864(ra) # 80000b66 <kalloc>
    8000180e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001810:	c51d                	beqz	a0,8000183e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001812:	6605                	lui	a2,0x1
    80001814:	4581                	li	a1,0
    80001816:	00000097          	auipc	ra,0x0
    8000181a:	8bc080e7          	jalr	-1860(ra) # 800010d2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000181e:	4779                	li	a4,30
    80001820:	86a6                	mv	a3,s1
    80001822:	6605                	lui	a2,0x1
    80001824:	85ca                	mv	a1,s2
    80001826:	8556                	mv	a0,s5
    80001828:	00000097          	auipc	ra,0x0
    8000182c:	c82080e7          	jalr	-894(ra) # 800014aa <mappages>
    80001830:	e905                	bnez	a0,80001860 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001832:	6785                	lui	a5,0x1
    80001834:	993e                	add	s2,s2,a5
    80001836:	fd4968e3          	bltu	s2,s4,80001806 <uvmalloc+0x2c>
  return newsz;
    8000183a:	8552                	mv	a0,s4
    8000183c:	a809                	j	8000184e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000183e:	864e                	mv	a2,s3
    80001840:	85ca                	mv	a1,s2
    80001842:	8556                	mv	a0,s5
    80001844:	00000097          	auipc	ra,0x0
    80001848:	f4e080e7          	jalr	-178(ra) # 80001792 <uvmdealloc>
      return 0;
    8000184c:	4501                	li	a0,0
}
    8000184e:	70e2                	ld	ra,56(sp)
    80001850:	7442                	ld	s0,48(sp)
    80001852:	74a2                	ld	s1,40(sp)
    80001854:	7902                	ld	s2,32(sp)
    80001856:	69e2                	ld	s3,24(sp)
    80001858:	6a42                	ld	s4,16(sp)
    8000185a:	6aa2                	ld	s5,8(sp)
    8000185c:	6121                	addi	sp,sp,64
    8000185e:	8082                	ret
      kfree(mem);
    80001860:	8526                	mv	a0,s1
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	1b6080e7          	jalr	438(ra) # 80000a18 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000186a:	864e                	mv	a2,s3
    8000186c:	85ca                	mv	a1,s2
    8000186e:	8556                	mv	a0,s5
    80001870:	00000097          	auipc	ra,0x0
    80001874:	f22080e7          	jalr	-222(ra) # 80001792 <uvmdealloc>
      return 0;
    80001878:	4501                	li	a0,0
    8000187a:	bfd1                	j	8000184e <uvmalloc+0x74>
    return oldsz;
    8000187c:	852e                	mv	a0,a1
}
    8000187e:	8082                	ret
  return newsz;
    80001880:	8532                	mv	a0,a2
    80001882:	b7f1                	j	8000184e <uvmalloc+0x74>

0000000080001884 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001884:	7179                	addi	sp,sp,-48
    80001886:	f406                	sd	ra,40(sp)
    80001888:	f022                	sd	s0,32(sp)
    8000188a:	ec26                	sd	s1,24(sp)
    8000188c:	e84a                	sd	s2,16(sp)
    8000188e:	e44e                	sd	s3,8(sp)
    80001890:	e052                	sd	s4,0(sp)
    80001892:	1800                	addi	s0,sp,48
    80001894:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001896:	84aa                	mv	s1,a0
    80001898:	6905                	lui	s2,0x1
    8000189a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000189c:	4985                	li	s3,1
    8000189e:	a829                	j	800018b8 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800018a0:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800018a2:	00c79513          	slli	a0,a5,0xc
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	fde080e7          	jalr	-34(ra) # 80001884 <freewalk>
      pagetable[i] = 0;
    800018ae:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018b2:	04a1                	addi	s1,s1,8
    800018b4:	03248163          	beq	s1,s2,800018d6 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018b8:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018ba:	00f7f713          	andi	a4,a5,15
    800018be:	ff3701e3          	beq	a4,s3,800018a0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018c2:	8b85                	andi	a5,a5,1
    800018c4:	d7fd                	beqz	a5,800018b2 <freewalk+0x2e>
      panic("freewalk: leaf");
    800018c6:	00007517          	auipc	a0,0x7
    800018ca:	93250513          	addi	a0,a0,-1742 # 800081f8 <digits+0x1b8>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	c7e080e7          	jalr	-898(ra) # 8000054c <panic>
    }
  }
  kfree((void*)pagetable);
    800018d6:	8552                	mv	a0,s4
    800018d8:	fffff097          	auipc	ra,0xfffff
    800018dc:	140080e7          	jalr	320(ra) # 80000a18 <kfree>
}
    800018e0:	70a2                	ld	ra,40(sp)
    800018e2:	7402                	ld	s0,32(sp)
    800018e4:	64e2                	ld	s1,24(sp)
    800018e6:	6942                	ld	s2,16(sp)
    800018e8:	69a2                	ld	s3,8(sp)
    800018ea:	6a02                	ld	s4,0(sp)
    800018ec:	6145                	addi	sp,sp,48
    800018ee:	8082                	ret

00000000800018f0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018f0:	1101                	addi	sp,sp,-32
    800018f2:	ec06                	sd	ra,24(sp)
    800018f4:	e822                	sd	s0,16(sp)
    800018f6:	e426                	sd	s1,8(sp)
    800018f8:	1000                	addi	s0,sp,32
    800018fa:	84aa                	mv	s1,a0
  if(sz > 0)
    800018fc:	e999                	bnez	a1,80001912 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018fe:	8526                	mv	a0,s1
    80001900:	00000097          	auipc	ra,0x0
    80001904:	f84080e7          	jalr	-124(ra) # 80001884 <freewalk>
}
    80001908:	60e2                	ld	ra,24(sp)
    8000190a:	6442                	ld	s0,16(sp)
    8000190c:	64a2                	ld	s1,8(sp)
    8000190e:	6105                	addi	sp,sp,32
    80001910:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001912:	6785                	lui	a5,0x1
    80001914:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001916:	95be                	add	a1,a1,a5
    80001918:	4685                	li	a3,1
    8000191a:	00c5d613          	srli	a2,a1,0xc
    8000191e:	4581                	li	a1,0
    80001920:	00000097          	auipc	ra,0x0
    80001924:	d0e080e7          	jalr	-754(ra) # 8000162e <uvmunmap>
    80001928:	bfd9                	j	800018fe <uvmfree+0xe>

000000008000192a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000192a:	c679                	beqz	a2,800019f8 <uvmcopy+0xce>
{
    8000192c:	715d                	addi	sp,sp,-80
    8000192e:	e486                	sd	ra,72(sp)
    80001930:	e0a2                	sd	s0,64(sp)
    80001932:	fc26                	sd	s1,56(sp)
    80001934:	f84a                	sd	s2,48(sp)
    80001936:	f44e                	sd	s3,40(sp)
    80001938:	f052                	sd	s4,32(sp)
    8000193a:	ec56                	sd	s5,24(sp)
    8000193c:	e85a                	sd	s6,16(sp)
    8000193e:	e45e                	sd	s7,8(sp)
    80001940:	0880                	addi	s0,sp,80
    80001942:	8b2a                	mv	s6,a0
    80001944:	8aae                	mv	s5,a1
    80001946:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001948:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000194a:	4601                	li	a2,0
    8000194c:	85ce                	mv	a1,s3
    8000194e:	855a                	mv	a0,s6
    80001950:	00000097          	auipc	ra,0x0
    80001954:	a4e080e7          	jalr	-1458(ra) # 8000139e <walk>
    80001958:	c531                	beqz	a0,800019a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000195a:	6118                	ld	a4,0(a0)
    8000195c:	00177793          	andi	a5,a4,1
    80001960:	cbb1                	beqz	a5,800019b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001962:	00a75593          	srli	a1,a4,0xa
    80001966:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000196a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1f8080e7          	jalr	504(ra) # 80000b66 <kalloc>
    80001976:	892a                	mv	s2,a0
    80001978:	c939                	beqz	a0,800019ce <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000197a:	6605                	lui	a2,0x1
    8000197c:	85de                	mv	a1,s7
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	7b0080e7          	jalr	1968(ra) # 8000112e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001986:	8726                	mv	a4,s1
    80001988:	86ca                	mv	a3,s2
    8000198a:	6605                	lui	a2,0x1
    8000198c:	85ce                	mv	a1,s3
    8000198e:	8556                	mv	a0,s5
    80001990:	00000097          	auipc	ra,0x0
    80001994:	b1a080e7          	jalr	-1254(ra) # 800014aa <mappages>
    80001998:	e515                	bnez	a0,800019c4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000199a:	6785                	lui	a5,0x1
    8000199c:	99be                	add	s3,s3,a5
    8000199e:	fb49e6e3          	bltu	s3,s4,8000194a <uvmcopy+0x20>
    800019a2:	a081                	j	800019e2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800019a4:	00007517          	auipc	a0,0x7
    800019a8:	86450513          	addi	a0,a0,-1948 # 80008208 <digits+0x1c8>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	ba0080e7          	jalr	-1120(ra) # 8000054c <panic>
      panic("uvmcopy: page not present");
    800019b4:	00007517          	auipc	a0,0x7
    800019b8:	87450513          	addi	a0,a0,-1932 # 80008228 <digits+0x1e8>
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	b90080e7          	jalr	-1136(ra) # 8000054c <panic>
      kfree(mem);
    800019c4:	854a                	mv	a0,s2
    800019c6:	fffff097          	auipc	ra,0xfffff
    800019ca:	052080e7          	jalr	82(ra) # 80000a18 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019ce:	4685                	li	a3,1
    800019d0:	00c9d613          	srli	a2,s3,0xc
    800019d4:	4581                	li	a1,0
    800019d6:	8556                	mv	a0,s5
    800019d8:	00000097          	auipc	ra,0x0
    800019dc:	c56080e7          	jalr	-938(ra) # 8000162e <uvmunmap>
  return -1;
    800019e0:	557d                	li	a0,-1
}
    800019e2:	60a6                	ld	ra,72(sp)
    800019e4:	6406                	ld	s0,64(sp)
    800019e6:	74e2                	ld	s1,56(sp)
    800019e8:	7942                	ld	s2,48(sp)
    800019ea:	79a2                	ld	s3,40(sp)
    800019ec:	7a02                	ld	s4,32(sp)
    800019ee:	6ae2                	ld	s5,24(sp)
    800019f0:	6b42                	ld	s6,16(sp)
    800019f2:	6ba2                	ld	s7,8(sp)
    800019f4:	6161                	addi	sp,sp,80
    800019f6:	8082                	ret
  return 0;
    800019f8:	4501                	li	a0,0
}
    800019fa:	8082                	ret

00000000800019fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019fc:	1141                	addi	sp,sp,-16
    800019fe:	e406                	sd	ra,8(sp)
    80001a00:	e022                	sd	s0,0(sp)
    80001a02:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a04:	4601                	li	a2,0
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	998080e7          	jalr	-1640(ra) # 8000139e <walk>
  if(pte == 0)
    80001a0e:	c901                	beqz	a0,80001a1e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a10:	611c                	ld	a5,0(a0)
    80001a12:	9bbd                	andi	a5,a5,-17
    80001a14:	e11c                	sd	a5,0(a0)
}
    80001a16:	60a2                	ld	ra,8(sp)
    80001a18:	6402                	ld	s0,0(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret
    panic("uvmclear");
    80001a1e:	00007517          	auipc	a0,0x7
    80001a22:	82a50513          	addi	a0,a0,-2006 # 80008248 <digits+0x208>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	b26080e7          	jalr	-1242(ra) # 8000054c <panic>

0000000080001a2e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a2e:	c6bd                	beqz	a3,80001a9c <copyout+0x6e>
{
    80001a30:	715d                	addi	sp,sp,-80
    80001a32:	e486                	sd	ra,72(sp)
    80001a34:	e0a2                	sd	s0,64(sp)
    80001a36:	fc26                	sd	s1,56(sp)
    80001a38:	f84a                	sd	s2,48(sp)
    80001a3a:	f44e                	sd	s3,40(sp)
    80001a3c:	f052                	sd	s4,32(sp)
    80001a3e:	ec56                	sd	s5,24(sp)
    80001a40:	e85a                	sd	s6,16(sp)
    80001a42:	e45e                	sd	s7,8(sp)
    80001a44:	e062                	sd	s8,0(sp)
    80001a46:	0880                	addi	s0,sp,80
    80001a48:	8b2a                	mv	s6,a0
    80001a4a:	8c2e                	mv	s8,a1
    80001a4c:	8a32                	mv	s4,a2
    80001a4e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a50:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a52:	6a85                	lui	s5,0x1
    80001a54:	a015                	j	80001a78 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a56:	9562                	add	a0,a0,s8
    80001a58:	0004861b          	sext.w	a2,s1
    80001a5c:	85d2                	mv	a1,s4
    80001a5e:	41250533          	sub	a0,a0,s2
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	6cc080e7          	jalr	1740(ra) # 8000112e <memmove>

    len -= n;
    80001a6a:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a6e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a70:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a74:	02098263          	beqz	s3,80001a98 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a78:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a7c:	85ca                	mv	a1,s2
    80001a7e:	855a                	mv	a0,s6
    80001a80:	00000097          	auipc	ra,0x0
    80001a84:	9e8080e7          	jalr	-1560(ra) # 80001468 <walkaddr>
    if(pa0 == 0)
    80001a88:	cd01                	beqz	a0,80001aa0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a8a:	418904b3          	sub	s1,s2,s8
    80001a8e:	94d6                	add	s1,s1,s5
    80001a90:	fc99f3e3          	bgeu	s3,s1,80001a56 <copyout+0x28>
    80001a94:	84ce                	mv	s1,s3
    80001a96:	b7c1                	j	80001a56 <copyout+0x28>
  }
  return 0;
    80001a98:	4501                	li	a0,0
    80001a9a:	a021                	j	80001aa2 <copyout+0x74>
    80001a9c:	4501                	li	a0,0
}
    80001a9e:	8082                	ret
      return -1;
    80001aa0:	557d                	li	a0,-1
}
    80001aa2:	60a6                	ld	ra,72(sp)
    80001aa4:	6406                	ld	s0,64(sp)
    80001aa6:	74e2                	ld	s1,56(sp)
    80001aa8:	7942                	ld	s2,48(sp)
    80001aaa:	79a2                	ld	s3,40(sp)
    80001aac:	7a02                	ld	s4,32(sp)
    80001aae:	6ae2                	ld	s5,24(sp)
    80001ab0:	6b42                	ld	s6,16(sp)
    80001ab2:	6ba2                	ld	s7,8(sp)
    80001ab4:	6c02                	ld	s8,0(sp)
    80001ab6:	6161                	addi	sp,sp,80
    80001ab8:	8082                	ret

0000000080001aba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001aba:	caa5                	beqz	a3,80001b2a <copyin+0x70>
{
    80001abc:	715d                	addi	sp,sp,-80
    80001abe:	e486                	sd	ra,72(sp)
    80001ac0:	e0a2                	sd	s0,64(sp)
    80001ac2:	fc26                	sd	s1,56(sp)
    80001ac4:	f84a                	sd	s2,48(sp)
    80001ac6:	f44e                	sd	s3,40(sp)
    80001ac8:	f052                	sd	s4,32(sp)
    80001aca:	ec56                	sd	s5,24(sp)
    80001acc:	e85a                	sd	s6,16(sp)
    80001ace:	e45e                	sd	s7,8(sp)
    80001ad0:	e062                	sd	s8,0(sp)
    80001ad2:	0880                	addi	s0,sp,80
    80001ad4:	8b2a                	mv	s6,a0
    80001ad6:	8a2e                	mv	s4,a1
    80001ad8:	8c32                	mv	s8,a2
    80001ada:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001adc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ade:	6a85                	lui	s5,0x1
    80001ae0:	a01d                	j	80001b06 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ae2:	018505b3          	add	a1,a0,s8
    80001ae6:	0004861b          	sext.w	a2,s1
    80001aea:	412585b3          	sub	a1,a1,s2
    80001aee:	8552                	mv	a0,s4
    80001af0:	fffff097          	auipc	ra,0xfffff
    80001af4:	63e080e7          	jalr	1598(ra) # 8000112e <memmove>

    len -= n;
    80001af8:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001afc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001afe:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b02:	02098263          	beqz	s3,80001b26 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001b06:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b0a:	85ca                	mv	a1,s2
    80001b0c:	855a                	mv	a0,s6
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	95a080e7          	jalr	-1702(ra) # 80001468 <walkaddr>
    if(pa0 == 0)
    80001b16:	cd01                	beqz	a0,80001b2e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001b18:	418904b3          	sub	s1,s2,s8
    80001b1c:	94d6                	add	s1,s1,s5
    80001b1e:	fc99f2e3          	bgeu	s3,s1,80001ae2 <copyin+0x28>
    80001b22:	84ce                	mv	s1,s3
    80001b24:	bf7d                	j	80001ae2 <copyin+0x28>
  }
  return 0;
    80001b26:	4501                	li	a0,0
    80001b28:	a021                	j	80001b30 <copyin+0x76>
    80001b2a:	4501                	li	a0,0
}
    80001b2c:	8082                	ret
      return -1;
    80001b2e:	557d                	li	a0,-1
}
    80001b30:	60a6                	ld	ra,72(sp)
    80001b32:	6406                	ld	s0,64(sp)
    80001b34:	74e2                	ld	s1,56(sp)
    80001b36:	7942                	ld	s2,48(sp)
    80001b38:	79a2                	ld	s3,40(sp)
    80001b3a:	7a02                	ld	s4,32(sp)
    80001b3c:	6ae2                	ld	s5,24(sp)
    80001b3e:	6b42                	ld	s6,16(sp)
    80001b40:	6ba2                	ld	s7,8(sp)
    80001b42:	6c02                	ld	s8,0(sp)
    80001b44:	6161                	addi	sp,sp,80
    80001b46:	8082                	ret

0000000080001b48 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b48:	c2dd                	beqz	a3,80001bee <copyinstr+0xa6>
{
    80001b4a:	715d                	addi	sp,sp,-80
    80001b4c:	e486                	sd	ra,72(sp)
    80001b4e:	e0a2                	sd	s0,64(sp)
    80001b50:	fc26                	sd	s1,56(sp)
    80001b52:	f84a                	sd	s2,48(sp)
    80001b54:	f44e                	sd	s3,40(sp)
    80001b56:	f052                	sd	s4,32(sp)
    80001b58:	ec56                	sd	s5,24(sp)
    80001b5a:	e85a                	sd	s6,16(sp)
    80001b5c:	e45e                	sd	s7,8(sp)
    80001b5e:	0880                	addi	s0,sp,80
    80001b60:	8a2a                	mv	s4,a0
    80001b62:	8b2e                	mv	s6,a1
    80001b64:	8bb2                	mv	s7,a2
    80001b66:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b68:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b6a:	6985                	lui	s3,0x1
    80001b6c:	a02d                	j	80001b96 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b6e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b72:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b74:	37fd                	addiw	a5,a5,-1
    80001b76:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b7a:	60a6                	ld	ra,72(sp)
    80001b7c:	6406                	ld	s0,64(sp)
    80001b7e:	74e2                	ld	s1,56(sp)
    80001b80:	7942                	ld	s2,48(sp)
    80001b82:	79a2                	ld	s3,40(sp)
    80001b84:	7a02                	ld	s4,32(sp)
    80001b86:	6ae2                	ld	s5,24(sp)
    80001b88:	6b42                	ld	s6,16(sp)
    80001b8a:	6ba2                	ld	s7,8(sp)
    80001b8c:	6161                	addi	sp,sp,80
    80001b8e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b90:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b94:	c8a9                	beqz	s1,80001be6 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001b96:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b9a:	85ca                	mv	a1,s2
    80001b9c:	8552                	mv	a0,s4
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	8ca080e7          	jalr	-1846(ra) # 80001468 <walkaddr>
    if(pa0 == 0)
    80001ba6:	c131                	beqz	a0,80001bea <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001ba8:	417906b3          	sub	a3,s2,s7
    80001bac:	96ce                	add	a3,a3,s3
    80001bae:	00d4f363          	bgeu	s1,a3,80001bb4 <copyinstr+0x6c>
    80001bb2:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001bb4:	955e                	add	a0,a0,s7
    80001bb6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001bba:	daf9                	beqz	a3,80001b90 <copyinstr+0x48>
    80001bbc:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bbe:	41650633          	sub	a2,a0,s6
    80001bc2:	fff48593          	addi	a1,s1,-1
    80001bc6:	95da                	add	a1,a1,s6
    while(n > 0){
    80001bc8:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001bca:	00f60733          	add	a4,a2,a5
    80001bce:	00074703          	lbu	a4,0(a4)
    80001bd2:	df51                	beqz	a4,80001b6e <copyinstr+0x26>
        *dst = *p;
    80001bd4:	00e78023          	sb	a4,0(a5)
      --max;
    80001bd8:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001bdc:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bde:	fed796e3          	bne	a5,a3,80001bca <copyinstr+0x82>
      dst++;
    80001be2:	8b3e                	mv	s6,a5
    80001be4:	b775                	j	80001b90 <copyinstr+0x48>
    80001be6:	4781                	li	a5,0
    80001be8:	b771                	j	80001b74 <copyinstr+0x2c>
      return -1;
    80001bea:	557d                	li	a0,-1
    80001bec:	b779                	j	80001b7a <copyinstr+0x32>
  int got_null = 0;
    80001bee:	4781                	li	a5,0
  if(got_null){
    80001bf0:	37fd                	addiw	a5,a5,-1
    80001bf2:	0007851b          	sext.w	a0,a5
}
    80001bf6:	8082                	ret

0000000080001bf8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bf8:	1101                	addi	sp,sp,-32
    80001bfa:	ec06                	sd	ra,24(sp)
    80001bfc:	e822                	sd	s0,16(sp)
    80001bfe:	e426                	sd	s1,8(sp)
    80001c00:	1000                	addi	s0,sp,32
    80001c02:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	074080e7          	jalr	116(ra) # 80000c78 <holding>
    80001c0c:	c909                	beqz	a0,80001c1e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c0e:	789c                	ld	a5,48(s1)
    80001c10:	00978f63          	beq	a5,s1,80001c2e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c14:	60e2                	ld	ra,24(sp)
    80001c16:	6442                	ld	s0,16(sp)
    80001c18:	64a2                	ld	s1,8(sp)
    80001c1a:	6105                	addi	sp,sp,32
    80001c1c:	8082                	ret
    panic("wakeup1");
    80001c1e:	00006517          	auipc	a0,0x6
    80001c22:	63a50513          	addi	a0,a0,1594 # 80008258 <digits+0x218>
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	926080e7          	jalr	-1754(ra) # 8000054c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c2e:	5098                	lw	a4,32(s1)
    80001c30:	4785                	li	a5,1
    80001c32:	fef711e3          	bne	a4,a5,80001c14 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c36:	4789                	li	a5,2
    80001c38:	d09c                	sw	a5,32(s1)
}
    80001c3a:	bfe9                	j	80001c14 <wakeup1+0x1c>

0000000080001c3c <procinit>:
{
    80001c3c:	715d                	addi	sp,sp,-80
    80001c3e:	e486                	sd	ra,72(sp)
    80001c40:	e0a2                	sd	s0,64(sp)
    80001c42:	fc26                	sd	s1,56(sp)
    80001c44:	f84a                	sd	s2,48(sp)
    80001c46:	f44e                	sd	s3,40(sp)
    80001c48:	f052                	sd	s4,32(sp)
    80001c4a:	ec56                	sd	s5,24(sp)
    80001c4c:	e85a                	sd	s6,16(sp)
    80001c4e:	e45e                	sd	s7,8(sp)
    80001c50:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c52:	00006597          	auipc	a1,0x6
    80001c56:	60e58593          	addi	a1,a1,1550 # 80008260 <digits+0x220>
    80001c5a:	00010517          	auipc	a0,0x10
    80001c5e:	72e50513          	addi	a0,a0,1838 # 80012388 <pid_lock>
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	20c080e7          	jalr	524(ra) # 80000e6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6a:	00011917          	auipc	s2,0x11
    80001c6e:	b3e90913          	addi	s2,s2,-1218 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c72:	00006b97          	auipc	s7,0x6
    80001c76:	5f6b8b93          	addi	s7,s7,1526 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c7a:	8b4a                	mv	s6,s2
    80001c7c:	00006a97          	auipc	s5,0x6
    80001c80:	384a8a93          	addi	s5,s5,900 # 80008000 <etext>
    80001c84:	040009b7          	lui	s3,0x4000
    80001c88:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c8a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c8c:	00016a17          	auipc	s4,0x16
    80001c90:	71ca0a13          	addi	s4,s4,1820 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c94:	85de                	mv	a1,s7
    80001c96:	854a                	mv	a0,s2
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	1d6080e7          	jalr	470(ra) # 80000e6e <initlock>
      char *pa = kalloc();
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	ec6080e7          	jalr	-314(ra) # 80000b66 <kalloc>
    80001ca8:	85aa                	mv	a1,a0
      if(pa == 0)
    80001caa:	c929                	beqz	a0,80001cfc <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001cac:	416904b3          	sub	s1,s2,s6
    80001cb0:	8491                	srai	s1,s1,0x4
    80001cb2:	000ab783          	ld	a5,0(s5)
    80001cb6:	02f484b3          	mul	s1,s1,a5
    80001cba:	2485                	addiw	s1,s1,1
    80001cbc:	00d4949b          	slliw	s1,s1,0xd
    80001cc0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cc4:	4699                	li	a3,6
    80001cc6:	6605                	lui	a2,0x1
    80001cc8:	8526                	mv	a0,s1
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	86e080e7          	jalr	-1938(ra) # 80001538 <kvmmap>
      p->kstack = va;
    80001cd2:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd6:	17090913          	addi	s2,s2,368
    80001cda:	fb491de3          	bne	s2,s4,80001c94 <procinit+0x58>
  kvminithart();
    80001cde:	fffff097          	auipc	ra,0xfffff
    80001ce2:	766080e7          	jalr	1894(ra) # 80001444 <kvminithart>
}
    80001ce6:	60a6                	ld	ra,72(sp)
    80001ce8:	6406                	ld	s0,64(sp)
    80001cea:	74e2                	ld	s1,56(sp)
    80001cec:	7942                	ld	s2,48(sp)
    80001cee:	79a2                	ld	s3,40(sp)
    80001cf0:	7a02                	ld	s4,32(sp)
    80001cf2:	6ae2                	ld	s5,24(sp)
    80001cf4:	6b42                	ld	s6,16(sp)
    80001cf6:	6ba2                	ld	s7,8(sp)
    80001cf8:	6161                	addi	sp,sp,80
    80001cfa:	8082                	ret
        panic("kalloc");
    80001cfc:	00006517          	auipc	a0,0x6
    80001d00:	57450513          	addi	a0,a0,1396 # 80008270 <digits+0x230>
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	848080e7          	jalr	-1976(ra) # 8000054c <panic>

0000000080001d0c <cpuid>:
{
    80001d0c:	1141                	addi	sp,sp,-16
    80001d0e:	e422                	sd	s0,8(sp)
    80001d10:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d12:	8512                	mv	a0,tp
}
    80001d14:	2501                	sext.w	a0,a0
    80001d16:	6422                	ld	s0,8(sp)
    80001d18:	0141                	addi	sp,sp,16
    80001d1a:	8082                	ret

0000000080001d1c <mycpu>:
mycpu(void) {
    80001d1c:	1141                	addi	sp,sp,-16
    80001d1e:	e422                	sd	s0,8(sp)
    80001d20:	0800                	addi	s0,sp,16
    80001d22:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d24:	2781                	sext.w	a5,a5
    80001d26:	079e                	slli	a5,a5,0x7
}
    80001d28:	00010517          	auipc	a0,0x10
    80001d2c:	68050513          	addi	a0,a0,1664 # 800123a8 <cpus>
    80001d30:	953e                	add	a0,a0,a5
    80001d32:	6422                	ld	s0,8(sp)
    80001d34:	0141                	addi	sp,sp,16
    80001d36:	8082                	ret

0000000080001d38 <myproc>:
myproc(void) {
    80001d38:	1101                	addi	sp,sp,-32
    80001d3a:	ec06                	sd	ra,24(sp)
    80001d3c:	e822                	sd	s0,16(sp)
    80001d3e:	e426                	sd	s1,8(sp)
    80001d40:	1000                	addi	s0,sp,32
  push_off();
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f64080e7          	jalr	-156(ra) # 80000ca6 <push_off>
    80001d4a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d4c:	2781                	sext.w	a5,a5
    80001d4e:	079e                	slli	a5,a5,0x7
    80001d50:	00010717          	auipc	a4,0x10
    80001d54:	63870713          	addi	a4,a4,1592 # 80012388 <pid_lock>
    80001d58:	97ba                	add	a5,a5,a4
    80001d5a:	7384                	ld	s1,32(a5)
  pop_off();
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	006080e7          	jalr	6(ra) # 80000d62 <pop_off>
}
    80001d64:	8526                	mv	a0,s1
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6105                	addi	sp,sp,32
    80001d6e:	8082                	ret

0000000080001d70 <forkret>:
{
    80001d70:	1141                	addi	sp,sp,-16
    80001d72:	e406                	sd	ra,8(sp)
    80001d74:	e022                	sd	s0,0(sp)
    80001d76:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d78:	00000097          	auipc	ra,0x0
    80001d7c:	fc0080e7          	jalr	-64(ra) # 80001d38 <myproc>
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	042080e7          	jalr	66(ra) # 80000dc2 <release>
  if (first) {
    80001d88:	00007797          	auipc	a5,0x7
    80001d8c:	b287a783          	lw	a5,-1240(a5) # 800088b0 <first.1>
    80001d90:	eb89                	bnez	a5,80001da2 <forkret+0x32>
  usertrapret();
    80001d92:	00001097          	auipc	ra,0x1
    80001d96:	c1e080e7          	jalr	-994(ra) # 800029b0 <usertrapret>
}
    80001d9a:	60a2                	ld	ra,8(sp)
    80001d9c:	6402                	ld	s0,0(sp)
    80001d9e:	0141                	addi	sp,sp,16
    80001da0:	8082                	ret
    first = 0;
    80001da2:	00007797          	auipc	a5,0x7
    80001da6:	b007a723          	sw	zero,-1266(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001daa:	4505                	li	a0,1
    80001dac:	00002097          	auipc	ra,0x2
    80001db0:	944080e7          	jalr	-1724(ra) # 800036f0 <fsinit>
    80001db4:	bff9                	j	80001d92 <forkret+0x22>

0000000080001db6 <allocpid>:
allocpid() {
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	e04a                	sd	s2,0(sp)
    80001dc0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dc2:	00010917          	auipc	s2,0x10
    80001dc6:	5c690913          	addi	s2,s2,1478 # 80012388 <pid_lock>
    80001dca:	854a                	mv	a0,s2
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	f26080e7          	jalr	-218(ra) # 80000cf2 <acquire>
  pid = nextpid;
    80001dd4:	00007797          	auipc	a5,0x7
    80001dd8:	ae078793          	addi	a5,a5,-1312 # 800088b4 <nextpid>
    80001ddc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dde:	0014871b          	addiw	a4,s1,1
    80001de2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001de4:	854a                	mv	a0,s2
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	fdc080e7          	jalr	-36(ra) # 80000dc2 <release>
}
    80001dee:	8526                	mv	a0,s1
    80001df0:	60e2                	ld	ra,24(sp)
    80001df2:	6442                	ld	s0,16(sp)
    80001df4:	64a2                	ld	s1,8(sp)
    80001df6:	6902                	ld	s2,0(sp)
    80001df8:	6105                	addi	sp,sp,32
    80001dfa:	8082                	ret

0000000080001dfc <proc_pagetable>:
{
    80001dfc:	1101                	addi	sp,sp,-32
    80001dfe:	ec06                	sd	ra,24(sp)
    80001e00:	e822                	sd	s0,16(sp)
    80001e02:	e426                	sd	s1,8(sp)
    80001e04:	e04a                	sd	s2,0(sp)
    80001e06:	1000                	addi	s0,sp,32
    80001e08:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	8e8080e7          	jalr	-1816(ra) # 800016f2 <uvmcreate>
    80001e12:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e14:	c121                	beqz	a0,80001e54 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e16:	4729                	li	a4,10
    80001e18:	00005697          	auipc	a3,0x5
    80001e1c:	1e868693          	addi	a3,a3,488 # 80007000 <_trampoline>
    80001e20:	6605                	lui	a2,0x1
    80001e22:	040005b7          	lui	a1,0x4000
    80001e26:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e28:	05b2                	slli	a1,a1,0xc
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	680080e7          	jalr	1664(ra) # 800014aa <mappages>
    80001e32:	02054863          	bltz	a0,80001e62 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e36:	4719                	li	a4,6
    80001e38:	06093683          	ld	a3,96(s2)
    80001e3c:	6605                	lui	a2,0x1
    80001e3e:	020005b7          	lui	a1,0x2000
    80001e42:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e44:	05b6                	slli	a1,a1,0xd
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	662080e7          	jalr	1634(ra) # 800014aa <mappages>
    80001e50:	02054163          	bltz	a0,80001e72 <proc_pagetable+0x76>
}
    80001e54:	8526                	mv	a0,s1
    80001e56:	60e2                	ld	ra,24(sp)
    80001e58:	6442                	ld	s0,16(sp)
    80001e5a:	64a2                	ld	s1,8(sp)
    80001e5c:	6902                	ld	s2,0(sp)
    80001e5e:	6105                	addi	sp,sp,32
    80001e60:	8082                	ret
    uvmfree(pagetable, 0);
    80001e62:	4581                	li	a1,0
    80001e64:	8526                	mv	a0,s1
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	a8a080e7          	jalr	-1398(ra) # 800018f0 <uvmfree>
    return 0;
    80001e6e:	4481                	li	s1,0
    80001e70:	b7d5                	j	80001e54 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e72:	4681                	li	a3,0
    80001e74:	4605                	li	a2,1
    80001e76:	040005b7          	lui	a1,0x4000
    80001e7a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e7c:	05b2                	slli	a1,a1,0xc
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	7ae080e7          	jalr	1966(ra) # 8000162e <uvmunmap>
    uvmfree(pagetable, 0);
    80001e88:	4581                	li	a1,0
    80001e8a:	8526                	mv	a0,s1
    80001e8c:	00000097          	auipc	ra,0x0
    80001e90:	a64080e7          	jalr	-1436(ra) # 800018f0 <uvmfree>
    return 0;
    80001e94:	4481                	li	s1,0
    80001e96:	bf7d                	j	80001e54 <proc_pagetable+0x58>

0000000080001e98 <proc_freepagetable>:
{
    80001e98:	1101                	addi	sp,sp,-32
    80001e9a:	ec06                	sd	ra,24(sp)
    80001e9c:	e822                	sd	s0,16(sp)
    80001e9e:	e426                	sd	s1,8(sp)
    80001ea0:	e04a                	sd	s2,0(sp)
    80001ea2:	1000                	addi	s0,sp,32
    80001ea4:	84aa                	mv	s1,a0
    80001ea6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea8:	4681                	li	a3,0
    80001eaa:	4605                	li	a2,1
    80001eac:	040005b7          	lui	a1,0x4000
    80001eb0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001eb2:	05b2                	slli	a1,a1,0xc
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	77a080e7          	jalr	1914(ra) # 8000162e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ebc:	4681                	li	a3,0
    80001ebe:	4605                	li	a2,1
    80001ec0:	020005b7          	lui	a1,0x2000
    80001ec4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ec6:	05b6                	slli	a1,a1,0xd
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	764080e7          	jalr	1892(ra) # 8000162e <uvmunmap>
  uvmfree(pagetable, sz);
    80001ed2:	85ca                	mv	a1,s2
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	a1a080e7          	jalr	-1510(ra) # 800018f0 <uvmfree>
}
    80001ede:	60e2                	ld	ra,24(sp)
    80001ee0:	6442                	ld	s0,16(sp)
    80001ee2:	64a2                	ld	s1,8(sp)
    80001ee4:	6902                	ld	s2,0(sp)
    80001ee6:	6105                	addi	sp,sp,32
    80001ee8:	8082                	ret

0000000080001eea <freeproc>:
{
    80001eea:	1101                	addi	sp,sp,-32
    80001eec:	ec06                	sd	ra,24(sp)
    80001eee:	e822                	sd	s0,16(sp)
    80001ef0:	e426                	sd	s1,8(sp)
    80001ef2:	1000                	addi	s0,sp,32
    80001ef4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ef6:	7128                	ld	a0,96(a0)
    80001ef8:	c509                	beqz	a0,80001f02 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	b1e080e7          	jalr	-1250(ra) # 80000a18 <kfree>
  p->trapframe = 0;
    80001f02:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f06:	6ca8                	ld	a0,88(s1)
    80001f08:	c511                	beqz	a0,80001f14 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f0a:	68ac                	ld	a1,80(s1)
    80001f0c:	00000097          	auipc	ra,0x0
    80001f10:	f8c080e7          	jalr	-116(ra) # 80001e98 <proc_freepagetable>
  p->pagetable = 0;
    80001f14:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f18:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f1c:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f20:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f24:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f28:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f2c:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f30:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f34:	0204a023          	sw	zero,32(s1)
}
    80001f38:	60e2                	ld	ra,24(sp)
    80001f3a:	6442                	ld	s0,16(sp)
    80001f3c:	64a2                	ld	s1,8(sp)
    80001f3e:	6105                	addi	sp,sp,32
    80001f40:	8082                	ret

0000000080001f42 <allocproc>:
{
    80001f42:	1101                	addi	sp,sp,-32
    80001f44:	ec06                	sd	ra,24(sp)
    80001f46:	e822                	sd	s0,16(sp)
    80001f48:	e426                	sd	s1,8(sp)
    80001f4a:	e04a                	sd	s2,0(sp)
    80001f4c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f4e:	00011497          	auipc	s1,0x11
    80001f52:	85a48493          	addi	s1,s1,-1958 # 800127a8 <proc>
    80001f56:	00016917          	auipc	s2,0x16
    80001f5a:	45290913          	addi	s2,s2,1106 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d92080e7          	jalr	-622(ra) # 80000cf2 <acquire>
    if(p->state == UNUSED) {
    80001f68:	509c                	lw	a5,32(s1)
    80001f6a:	cf81                	beqz	a5,80001f82 <allocproc+0x40>
      release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	e54080e7          	jalr	-428(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f76:	17048493          	addi	s1,s1,368
    80001f7a:	ff2492e3          	bne	s1,s2,80001f5e <allocproc+0x1c>
  return 0;
    80001f7e:	4481                	li	s1,0
    80001f80:	a0b9                	j	80001fce <allocproc+0x8c>
  p->pid = allocpid();
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	e34080e7          	jalr	-460(ra) # 80001db6 <allocpid>
    80001f8a:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	bda080e7          	jalr	-1062(ra) # 80000b66 <kalloc>
    80001f94:	892a                	mv	s2,a0
    80001f96:	f0a8                	sd	a0,96(s1)
    80001f98:	c131                	beqz	a0,80001fdc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	e60080e7          	jalr	-416(ra) # 80001dfc <proc_pagetable>
    80001fa4:	892a                	mv	s2,a0
    80001fa6:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001fa8:	c129                	beqz	a0,80001fea <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001faa:	07000613          	li	a2,112
    80001fae:	4581                	li	a1,0
    80001fb0:	06848513          	addi	a0,s1,104
    80001fb4:	fffff097          	auipc	ra,0xfffff
    80001fb8:	11e080e7          	jalr	286(ra) # 800010d2 <memset>
  p->context.ra = (uint64)forkret;
    80001fbc:	00000797          	auipc	a5,0x0
    80001fc0:	db478793          	addi	a5,a5,-588 # 80001d70 <forkret>
    80001fc4:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fc6:	64bc                	ld	a5,72(s1)
    80001fc8:	6705                	lui	a4,0x1
    80001fca:	97ba                	add	a5,a5,a4
    80001fcc:	f8bc                	sd	a5,112(s1)
}
    80001fce:	8526                	mv	a0,s1
    80001fd0:	60e2                	ld	ra,24(sp)
    80001fd2:	6442                	ld	s0,16(sp)
    80001fd4:	64a2                	ld	s1,8(sp)
    80001fd6:	6902                	ld	s2,0(sp)
    80001fd8:	6105                	addi	sp,sp,32
    80001fda:	8082                	ret
    release(&p->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	de4080e7          	jalr	-540(ra) # 80000dc2 <release>
    return 0;
    80001fe6:	84ca                	mv	s1,s2
    80001fe8:	b7dd                	j	80001fce <allocproc+0x8c>
    freeproc(p);
    80001fea:	8526                	mv	a0,s1
    80001fec:	00000097          	auipc	ra,0x0
    80001ff0:	efe080e7          	jalr	-258(ra) # 80001eea <freeproc>
    release(&p->lock);
    80001ff4:	8526                	mv	a0,s1
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	dcc080e7          	jalr	-564(ra) # 80000dc2 <release>
    return 0;
    80001ffe:	84ca                	mv	s1,s2
    80002000:	b7f9                	j	80001fce <allocproc+0x8c>

0000000080002002 <userinit>:
{
    80002002:	1101                	addi	sp,sp,-32
    80002004:	ec06                	sd	ra,24(sp)
    80002006:	e822                	sd	s0,16(sp)
    80002008:	e426                	sd	s1,8(sp)
    8000200a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	f36080e7          	jalr	-202(ra) # 80001f42 <allocproc>
    80002014:	84aa                	mv	s1,a0
  initproc = p;
    80002016:	00007797          	auipc	a5,0x7
    8000201a:	00a7b123          	sd	a0,2(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000201e:	03400613          	li	a2,52
    80002022:	00007597          	auipc	a1,0x7
    80002026:	89e58593          	addi	a1,a1,-1890 # 800088c0 <initcode>
    8000202a:	6d28                	ld	a0,88(a0)
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	6f4080e7          	jalr	1780(ra) # 80001720 <uvminit>
  p->sz = PGSIZE;
    80002034:	6785                	lui	a5,0x1
    80002036:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002038:	70b8                	ld	a4,96(s1)
    8000203a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000203e:	70b8                	ld	a4,96(s1)
    80002040:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002042:	4641                	li	a2,16
    80002044:	00006597          	auipc	a1,0x6
    80002048:	23458593          	addi	a1,a1,564 # 80008278 <digits+0x238>
    8000204c:	16048513          	addi	a0,s1,352
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	1d4080e7          	jalr	468(ra) # 80001224 <safestrcpy>
  p->cwd = namei("/");
    80002058:	00006517          	auipc	a0,0x6
    8000205c:	23050513          	addi	a0,a0,560 # 80008288 <digits+0x248>
    80002060:	00002097          	auipc	ra,0x2
    80002064:	0c4080e7          	jalr	196(ra) # 80004124 <namei>
    80002068:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000206c:	4789                	li	a5,2
    8000206e:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002070:	8526                	mv	a0,s1
    80002072:	fffff097          	auipc	ra,0xfffff
    80002076:	d50080e7          	jalr	-688(ra) # 80000dc2 <release>
}
    8000207a:	60e2                	ld	ra,24(sp)
    8000207c:	6442                	ld	s0,16(sp)
    8000207e:	64a2                	ld	s1,8(sp)
    80002080:	6105                	addi	sp,sp,32
    80002082:	8082                	ret

0000000080002084 <growproc>:
{
    80002084:	1101                	addi	sp,sp,-32
    80002086:	ec06                	sd	ra,24(sp)
    80002088:	e822                	sd	s0,16(sp)
    8000208a:	e426                	sd	s1,8(sp)
    8000208c:	e04a                	sd	s2,0(sp)
    8000208e:	1000                	addi	s0,sp,32
    80002090:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	ca6080e7          	jalr	-858(ra) # 80001d38 <myproc>
    8000209a:	892a                	mv	s2,a0
  sz = p->sz;
    8000209c:	692c                	ld	a1,80(a0)
    8000209e:	0005879b          	sext.w	a5,a1
  if(n > 0){
    800020a2:	00904f63          	bgtz	s1,800020c0 <growproc+0x3c>
  } else if(n < 0){
    800020a6:	0204cd63          	bltz	s1,800020e0 <growproc+0x5c>
  p->sz = sz;
    800020aa:	1782                	slli	a5,a5,0x20
    800020ac:	9381                	srli	a5,a5,0x20
    800020ae:	04f93823          	sd	a5,80(s2)
  return 0;
    800020b2:	4501                	li	a0,0
}
    800020b4:	60e2                	ld	ra,24(sp)
    800020b6:	6442                	ld	s0,16(sp)
    800020b8:	64a2                	ld	s1,8(sp)
    800020ba:	6902                	ld	s2,0(sp)
    800020bc:	6105                	addi	sp,sp,32
    800020be:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020c0:	00f4863b          	addw	a2,s1,a5
    800020c4:	1602                	slli	a2,a2,0x20
    800020c6:	9201                	srli	a2,a2,0x20
    800020c8:	1582                	slli	a1,a1,0x20
    800020ca:	9181                	srli	a1,a1,0x20
    800020cc:	6d28                	ld	a0,88(a0)
    800020ce:	fffff097          	auipc	ra,0xfffff
    800020d2:	70c080e7          	jalr	1804(ra) # 800017da <uvmalloc>
    800020d6:	0005079b          	sext.w	a5,a0
    800020da:	fbe1                	bnez	a5,800020aa <growproc+0x26>
      return -1;
    800020dc:	557d                	li	a0,-1
    800020de:	bfd9                	j	800020b4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020e0:	00f4863b          	addw	a2,s1,a5
    800020e4:	1602                	slli	a2,a2,0x20
    800020e6:	9201                	srli	a2,a2,0x20
    800020e8:	1582                	slli	a1,a1,0x20
    800020ea:	9181                	srli	a1,a1,0x20
    800020ec:	6d28                	ld	a0,88(a0)
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	6a4080e7          	jalr	1700(ra) # 80001792 <uvmdealloc>
    800020f6:	0005079b          	sext.w	a5,a0
    800020fa:	bf45                	j	800020aa <growproc+0x26>

00000000800020fc <fork>:
{
    800020fc:	7139                	addi	sp,sp,-64
    800020fe:	fc06                	sd	ra,56(sp)
    80002100:	f822                	sd	s0,48(sp)
    80002102:	f426                	sd	s1,40(sp)
    80002104:	f04a                	sd	s2,32(sp)
    80002106:	ec4e                	sd	s3,24(sp)
    80002108:	e852                	sd	s4,16(sp)
    8000210a:	e456                	sd	s5,8(sp)
    8000210c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	c2a080e7          	jalr	-982(ra) # 80001d38 <myproc>
    80002116:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002118:	00000097          	auipc	ra,0x0
    8000211c:	e2a080e7          	jalr	-470(ra) # 80001f42 <allocproc>
    80002120:	c17d                	beqz	a0,80002206 <fork+0x10a>
    80002122:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002124:	050ab603          	ld	a2,80(s5)
    80002128:	6d2c                	ld	a1,88(a0)
    8000212a:	058ab503          	ld	a0,88(s5)
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	7fc080e7          	jalr	2044(ra) # 8000192a <uvmcopy>
    80002136:	04054a63          	bltz	a0,8000218a <fork+0x8e>
  np->sz = p->sz;
    8000213a:	050ab783          	ld	a5,80(s5)
    8000213e:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80002142:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    80002146:	060ab683          	ld	a3,96(s5)
    8000214a:	87b6                	mv	a5,a3
    8000214c:	060a3703          	ld	a4,96(s4)
    80002150:	12068693          	addi	a3,a3,288
    80002154:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002158:	6788                	ld	a0,8(a5)
    8000215a:	6b8c                	ld	a1,16(a5)
    8000215c:	6f90                	ld	a2,24(a5)
    8000215e:	01073023          	sd	a6,0(a4)
    80002162:	e708                	sd	a0,8(a4)
    80002164:	eb0c                	sd	a1,16(a4)
    80002166:	ef10                	sd	a2,24(a4)
    80002168:	02078793          	addi	a5,a5,32
    8000216c:	02070713          	addi	a4,a4,32
    80002170:	fed792e3          	bne	a5,a3,80002154 <fork+0x58>
  np->trapframe->a0 = 0;
    80002174:	060a3783          	ld	a5,96(s4)
    80002178:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000217c:	0d8a8493          	addi	s1,s5,216
    80002180:	0d8a0913          	addi	s2,s4,216
    80002184:	158a8993          	addi	s3,s5,344
    80002188:	a00d                	j	800021aa <fork+0xae>
    freeproc(np);
    8000218a:	8552                	mv	a0,s4
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	d5e080e7          	jalr	-674(ra) # 80001eea <freeproc>
    release(&np->lock);
    80002194:	8552                	mv	a0,s4
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	c2c080e7          	jalr	-980(ra) # 80000dc2 <release>
    return -1;
    8000219e:	54fd                	li	s1,-1
    800021a0:	a889                	j	800021f2 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    800021a2:	04a1                	addi	s1,s1,8
    800021a4:	0921                	addi	s2,s2,8
    800021a6:	01348b63          	beq	s1,s3,800021bc <fork+0xc0>
    if(p->ofile[i])
    800021aa:	6088                	ld	a0,0(s1)
    800021ac:	d97d                	beqz	a0,800021a2 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    800021ae:	00002097          	auipc	ra,0x2
    800021b2:	614080e7          	jalr	1556(ra) # 800047c2 <filedup>
    800021b6:	00a93023          	sd	a0,0(s2)
    800021ba:	b7e5                	j	800021a2 <fork+0xa6>
  np->cwd = idup(p->cwd);
    800021bc:	158ab503          	ld	a0,344(s5)
    800021c0:	00001097          	auipc	ra,0x1
    800021c4:	76c080e7          	jalr	1900(ra) # 8000392c <idup>
    800021c8:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021cc:	4641                	li	a2,16
    800021ce:	160a8593          	addi	a1,s5,352
    800021d2:	160a0513          	addi	a0,s4,352
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	04e080e7          	jalr	78(ra) # 80001224 <safestrcpy>
  pid = np->pid;
    800021de:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021e2:	4789                	li	a5,2
    800021e4:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021e8:	8552                	mv	a0,s4
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	bd8080e7          	jalr	-1064(ra) # 80000dc2 <release>
}
    800021f2:	8526                	mv	a0,s1
    800021f4:	70e2                	ld	ra,56(sp)
    800021f6:	7442                	ld	s0,48(sp)
    800021f8:	74a2                	ld	s1,40(sp)
    800021fa:	7902                	ld	s2,32(sp)
    800021fc:	69e2                	ld	s3,24(sp)
    800021fe:	6a42                	ld	s4,16(sp)
    80002200:	6aa2                	ld	s5,8(sp)
    80002202:	6121                	addi	sp,sp,64
    80002204:	8082                	ret
    return -1;
    80002206:	54fd                	li	s1,-1
    80002208:	b7ed                	j	800021f2 <fork+0xf6>

000000008000220a <reparent>:
{
    8000220a:	7179                	addi	sp,sp,-48
    8000220c:	f406                	sd	ra,40(sp)
    8000220e:	f022                	sd	s0,32(sp)
    80002210:	ec26                	sd	s1,24(sp)
    80002212:	e84a                	sd	s2,16(sp)
    80002214:	e44e                	sd	s3,8(sp)
    80002216:	e052                	sd	s4,0(sp)
    80002218:	1800                	addi	s0,sp,48
    8000221a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221c:	00010497          	auipc	s1,0x10
    80002220:	58c48493          	addi	s1,s1,1420 # 800127a8 <proc>
      pp->parent = initproc;
    80002224:	00007a17          	auipc	s4,0x7
    80002228:	df4a0a13          	addi	s4,s4,-524 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222c:	00016997          	auipc	s3,0x16
    80002230:	17c98993          	addi	s3,s3,380 # 800183a8 <tickslock>
    80002234:	a029                	j	8000223e <reparent+0x34>
    80002236:	17048493          	addi	s1,s1,368
    8000223a:	03348363          	beq	s1,s3,80002260 <reparent+0x56>
    if(pp->parent == p){
    8000223e:	749c                	ld	a5,40(s1)
    80002240:	ff279be3          	bne	a5,s2,80002236 <reparent+0x2c>
      acquire(&pp->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	aac080e7          	jalr	-1364(ra) # 80000cf2 <acquire>
      pp->parent = initproc;
    8000224e:	000a3783          	ld	a5,0(s4)
    80002252:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	b6c080e7          	jalr	-1172(ra) # 80000dc2 <release>
    8000225e:	bfe1                	j	80002236 <reparent+0x2c>
}
    80002260:	70a2                	ld	ra,40(sp)
    80002262:	7402                	ld	s0,32(sp)
    80002264:	64e2                	ld	s1,24(sp)
    80002266:	6942                	ld	s2,16(sp)
    80002268:	69a2                	ld	s3,8(sp)
    8000226a:	6a02                	ld	s4,0(sp)
    8000226c:	6145                	addi	sp,sp,48
    8000226e:	8082                	ret

0000000080002270 <scheduler>:
{
    80002270:	711d                	addi	sp,sp,-96
    80002272:	ec86                	sd	ra,88(sp)
    80002274:	e8a2                	sd	s0,80(sp)
    80002276:	e4a6                	sd	s1,72(sp)
    80002278:	e0ca                	sd	s2,64(sp)
    8000227a:	fc4e                	sd	s3,56(sp)
    8000227c:	f852                	sd	s4,48(sp)
    8000227e:	f456                	sd	s5,40(sp)
    80002280:	f05a                	sd	s6,32(sp)
    80002282:	ec5e                	sd	s7,24(sp)
    80002284:	e862                	sd	s8,16(sp)
    80002286:	e466                	sd	s9,8(sp)
    80002288:	1080                	addi	s0,sp,96
    8000228a:	8792                	mv	a5,tp
  int id = r_tp();
    8000228c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000228e:	00779c13          	slli	s8,a5,0x7
    80002292:	00010717          	auipc	a4,0x10
    80002296:	0f670713          	addi	a4,a4,246 # 80012388 <pid_lock>
    8000229a:	9762                	add	a4,a4,s8
    8000229c:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    800022a0:	00010717          	auipc	a4,0x10
    800022a4:	11070713          	addi	a4,a4,272 # 800123b0 <cpus+0x8>
    800022a8:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    800022aa:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    800022ac:	4a89                	li	s5,2
        c->proc = p;
    800022ae:	079e                	slli	a5,a5,0x7
    800022b0:	00010b17          	auipc	s6,0x10
    800022b4:	0d8b0b13          	addi	s6,s6,216 # 80012388 <pid_lock>
    800022b8:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022ba:	00016a17          	auipc	s4,0x16
    800022be:	0eea0a13          	addi	s4,s4,238 # 800183a8 <tickslock>
    800022c2:	a8a1                	j	8000231a <scheduler+0xaa>
      release(&p->lock);
    800022c4:	8526                	mv	a0,s1
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	afc080e7          	jalr	-1284(ra) # 80000dc2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022ce:	17048493          	addi	s1,s1,368
    800022d2:	03448a63          	beq	s1,s4,80002306 <scheduler+0x96>
      acquire(&p->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	a1a080e7          	jalr	-1510(ra) # 80000cf2 <acquire>
      if(p->state != UNUSED) {
    800022e0:	509c                	lw	a5,32(s1)
    800022e2:	d3ed                	beqz	a5,800022c4 <scheduler+0x54>
        nproc++;
    800022e4:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022e6:	fd579fe3          	bne	a5,s5,800022c4 <scheduler+0x54>
        p->state = RUNNING;
    800022ea:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022ee:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022f2:	06848593          	addi	a1,s1,104
    800022f6:	8562                	mv	a0,s8
    800022f8:	00000097          	auipc	ra,0x0
    800022fc:	60e080e7          	jalr	1550(ra) # 80002906 <swtch>
        c->proc = 0;
    80002300:	020b3023          	sd	zero,32(s6)
    80002304:	b7c1                	j	800022c4 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002306:	013aca63          	blt	s5,s3,8000231a <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000230e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002312:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002316:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000231e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002322:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002326:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002328:	00010497          	auipc	s1,0x10
    8000232c:	48048493          	addi	s1,s1,1152 # 800127a8 <proc>
        p->state = RUNNING;
    80002330:	4b8d                	li	s7,3
    80002332:	b755                	j	800022d6 <scheduler+0x66>

0000000080002334 <sched>:
{
    80002334:	7179                	addi	sp,sp,-48
    80002336:	f406                	sd	ra,40(sp)
    80002338:	f022                	sd	s0,32(sp)
    8000233a:	ec26                	sd	s1,24(sp)
    8000233c:	e84a                	sd	s2,16(sp)
    8000233e:	e44e                	sd	s3,8(sp)
    80002340:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	9f6080e7          	jalr	-1546(ra) # 80001d38 <myproc>
    8000234a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	92c080e7          	jalr	-1748(ra) # 80000c78 <holding>
    80002354:	c93d                	beqz	a0,800023ca <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002356:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002358:	2781                	sext.w	a5,a5
    8000235a:	079e                	slli	a5,a5,0x7
    8000235c:	00010717          	auipc	a4,0x10
    80002360:	02c70713          	addi	a4,a4,44 # 80012388 <pid_lock>
    80002364:	97ba                	add	a5,a5,a4
    80002366:	0987a703          	lw	a4,152(a5)
    8000236a:	4785                	li	a5,1
    8000236c:	06f71763          	bne	a4,a5,800023da <sched+0xa6>
  if(p->state == RUNNING)
    80002370:	5098                	lw	a4,32(s1)
    80002372:	478d                	li	a5,3
    80002374:	06f70b63          	beq	a4,a5,800023ea <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002378:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000237c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000237e:	efb5                	bnez	a5,800023fa <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002380:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002382:	00010917          	auipc	s2,0x10
    80002386:	00690913          	addi	s2,s2,6 # 80012388 <pid_lock>
    8000238a:	2781                	sext.w	a5,a5
    8000238c:	079e                	slli	a5,a5,0x7
    8000238e:	97ca                	add	a5,a5,s2
    80002390:	09c7a983          	lw	s3,156(a5)
    80002394:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002396:	2781                	sext.w	a5,a5
    80002398:	079e                	slli	a5,a5,0x7
    8000239a:	00010597          	auipc	a1,0x10
    8000239e:	01658593          	addi	a1,a1,22 # 800123b0 <cpus+0x8>
    800023a2:	95be                	add	a1,a1,a5
    800023a4:	06848513          	addi	a0,s1,104
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	55e080e7          	jalr	1374(ra) # 80002906 <swtch>
    800023b0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023b2:	2781                	sext.w	a5,a5
    800023b4:	079e                	slli	a5,a5,0x7
    800023b6:	993e                	add	s2,s2,a5
    800023b8:	09392e23          	sw	s3,156(s2)
}
    800023bc:	70a2                	ld	ra,40(sp)
    800023be:	7402                	ld	s0,32(sp)
    800023c0:	64e2                	ld	s1,24(sp)
    800023c2:	6942                	ld	s2,16(sp)
    800023c4:	69a2                	ld	s3,8(sp)
    800023c6:	6145                	addi	sp,sp,48
    800023c8:	8082                	ret
    panic("sched p->lock");
    800023ca:	00006517          	auipc	a0,0x6
    800023ce:	ec650513          	addi	a0,a0,-314 # 80008290 <digits+0x250>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	17a080e7          	jalr	378(ra) # 8000054c <panic>
    panic("sched locks");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	ec650513          	addi	a0,a0,-314 # 800082a0 <digits+0x260>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	16a080e7          	jalr	362(ra) # 8000054c <panic>
    panic("sched running");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	ec650513          	addi	a0,a0,-314 # 800082b0 <digits+0x270>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	15a080e7          	jalr	346(ra) # 8000054c <panic>
    panic("sched interruptible");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	ec650513          	addi	a0,a0,-314 # 800082c0 <digits+0x280>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	14a080e7          	jalr	330(ra) # 8000054c <panic>

000000008000240a <exit>:
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	e052                	sd	s4,0(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000241c:	00000097          	auipc	ra,0x0
    80002420:	91c080e7          	jalr	-1764(ra) # 80001d38 <myproc>
    80002424:	89aa                	mv	s3,a0
  if(p == initproc)
    80002426:	00007797          	auipc	a5,0x7
    8000242a:	bf27b783          	ld	a5,-1038(a5) # 80009018 <initproc>
    8000242e:	0d850493          	addi	s1,a0,216
    80002432:	15850913          	addi	s2,a0,344
    80002436:	02a79363          	bne	a5,a0,8000245c <exit+0x52>
    panic("init exiting");
    8000243a:	00006517          	auipc	a0,0x6
    8000243e:	e9e50513          	addi	a0,a0,-354 # 800082d8 <digits+0x298>
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	10a080e7          	jalr	266(ra) # 8000054c <panic>
      fileclose(f);
    8000244a:	00002097          	auipc	ra,0x2
    8000244e:	3ca080e7          	jalr	970(ra) # 80004814 <fileclose>
      p->ofile[fd] = 0;
    80002452:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002456:	04a1                	addi	s1,s1,8
    80002458:	01248563          	beq	s1,s2,80002462 <exit+0x58>
    if(p->ofile[fd]){
    8000245c:	6088                	ld	a0,0(s1)
    8000245e:	f575                	bnez	a0,8000244a <exit+0x40>
    80002460:	bfdd                	j	80002456 <exit+0x4c>
  begin_op();
    80002462:	00002097          	auipc	ra,0x2
    80002466:	ee2080e7          	jalr	-286(ra) # 80004344 <begin_op>
  iput(p->cwd);
    8000246a:	1589b503          	ld	a0,344(s3)
    8000246e:	00001097          	auipc	ra,0x1
    80002472:	6b6080e7          	jalr	1718(ra) # 80003b24 <iput>
  end_op();
    80002476:	00002097          	auipc	ra,0x2
    8000247a:	f4c080e7          	jalr	-180(ra) # 800043c2 <end_op>
  p->cwd = 0;
    8000247e:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002482:	00007497          	auipc	s1,0x7
    80002486:	b9648493          	addi	s1,s1,-1130 # 80009018 <initproc>
    8000248a:	6088                	ld	a0,0(s1)
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	866080e7          	jalr	-1946(ra) # 80000cf2 <acquire>
  wakeup1(initproc);
    80002494:	6088                	ld	a0,0(s1)
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	762080e7          	jalr	1890(ra) # 80001bf8 <wakeup1>
  release(&initproc->lock);
    8000249e:	6088                	ld	a0,0(s1)
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	922080e7          	jalr	-1758(ra) # 80000dc2 <release>
  acquire(&p->lock);
    800024a8:	854e                	mv	a0,s3
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	848080e7          	jalr	-1976(ra) # 80000cf2 <acquire>
  struct proc *original_parent = p->parent;
    800024b2:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024b6:	854e                	mv	a0,s3
    800024b8:	fffff097          	auipc	ra,0xfffff
    800024bc:	90a080e7          	jalr	-1782(ra) # 80000dc2 <release>
  acquire(&original_parent->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	830080e7          	jalr	-2000(ra) # 80000cf2 <acquire>
  acquire(&p->lock);
    800024ca:	854e                	mv	a0,s3
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	826080e7          	jalr	-2010(ra) # 80000cf2 <acquire>
  reparent(p);
    800024d4:	854e                	mv	a0,s3
    800024d6:	00000097          	auipc	ra,0x0
    800024da:	d34080e7          	jalr	-716(ra) # 8000220a <reparent>
  wakeup1(original_parent);
    800024de:	8526                	mv	a0,s1
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	718080e7          	jalr	1816(ra) # 80001bf8 <wakeup1>
  p->xstate = status;
    800024e8:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024ec:	4791                	li	a5,4
    800024ee:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	8ce080e7          	jalr	-1842(ra) # 80000dc2 <release>
  sched();
    800024fc:	00000097          	auipc	ra,0x0
    80002500:	e38080e7          	jalr	-456(ra) # 80002334 <sched>
  panic("zombie exit");
    80002504:	00006517          	auipc	a0,0x6
    80002508:	de450513          	addi	a0,a0,-540 # 800082e8 <digits+0x2a8>
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	040080e7          	jalr	64(ra) # 8000054c <panic>

0000000080002514 <yield>:
{
    80002514:	1101                	addi	sp,sp,-32
    80002516:	ec06                	sd	ra,24(sp)
    80002518:	e822                	sd	s0,16(sp)
    8000251a:	e426                	sd	s1,8(sp)
    8000251c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	81a080e7          	jalr	-2022(ra) # 80001d38 <myproc>
    80002526:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002528:	ffffe097          	auipc	ra,0xffffe
    8000252c:	7ca080e7          	jalr	1994(ra) # 80000cf2 <acquire>
  p->state = RUNNABLE;
    80002530:	4789                	li	a5,2
    80002532:	d09c                	sw	a5,32(s1)
  sched();
    80002534:	00000097          	auipc	ra,0x0
    80002538:	e00080e7          	jalr	-512(ra) # 80002334 <sched>
  release(&p->lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	884080e7          	jalr	-1916(ra) # 80000dc2 <release>
}
    80002546:	60e2                	ld	ra,24(sp)
    80002548:	6442                	ld	s0,16(sp)
    8000254a:	64a2                	ld	s1,8(sp)
    8000254c:	6105                	addi	sp,sp,32
    8000254e:	8082                	ret

0000000080002550 <sleep>:
{
    80002550:	7179                	addi	sp,sp,-48
    80002552:	f406                	sd	ra,40(sp)
    80002554:	f022                	sd	s0,32(sp)
    80002556:	ec26                	sd	s1,24(sp)
    80002558:	e84a                	sd	s2,16(sp)
    8000255a:	e44e                	sd	s3,8(sp)
    8000255c:	1800                	addi	s0,sp,48
    8000255e:	89aa                	mv	s3,a0
    80002560:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	7d6080e7          	jalr	2006(ra) # 80001d38 <myproc>
    8000256a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000256c:	05250663          	beq	a0,s2,800025b8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	782080e7          	jalr	1922(ra) # 80000cf2 <acquire>
    release(lk);
    80002578:	854a                	mv	a0,s2
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	848080e7          	jalr	-1976(ra) # 80000dc2 <release>
  p->chan = chan;
    80002582:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002586:	4785                	li	a5,1
    80002588:	d09c                	sw	a5,32(s1)
  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	daa080e7          	jalr	-598(ra) # 80002334 <sched>
  p->chan = 0;
    80002592:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	fffff097          	auipc	ra,0xfffff
    8000259c:	82a080e7          	jalr	-2006(ra) # 80000dc2 <release>
    acquire(lk);
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	750080e7          	jalr	1872(ra) # 80000cf2 <acquire>
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6145                	addi	sp,sp,48
    800025b6:	8082                	ret
  p->chan = chan;
    800025b8:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025bc:	4785                	li	a5,1
    800025be:	d11c                	sw	a5,32(a0)
  sched();
    800025c0:	00000097          	auipc	ra,0x0
    800025c4:	d74080e7          	jalr	-652(ra) # 80002334 <sched>
  p->chan = 0;
    800025c8:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025cc:	bff9                	j	800025aa <sleep+0x5a>

00000000800025ce <wait>:
{
    800025ce:	715d                	addi	sp,sp,-80
    800025d0:	e486                	sd	ra,72(sp)
    800025d2:	e0a2                	sd	s0,64(sp)
    800025d4:	fc26                	sd	s1,56(sp)
    800025d6:	f84a                	sd	s2,48(sp)
    800025d8:	f44e                	sd	s3,40(sp)
    800025da:	f052                	sd	s4,32(sp)
    800025dc:	ec56                	sd	s5,24(sp)
    800025de:	e85a                	sd	s6,16(sp)
    800025e0:	e45e                	sd	s7,8(sp)
    800025e2:	0880                	addi	s0,sp,80
    800025e4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025e6:	fffff097          	auipc	ra,0xfffff
    800025ea:	752080e7          	jalr	1874(ra) # 80001d38 <myproc>
    800025ee:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	702080e7          	jalr	1794(ra) # 80000cf2 <acquire>
    havekids = 0;
    800025f8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025fa:	4a11                	li	s4,4
        havekids = 1;
    800025fc:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025fe:	00016997          	auipc	s3,0x16
    80002602:	daa98993          	addi	s3,s3,-598 # 800183a8 <tickslock>
    havekids = 0;
    80002606:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002608:	00010497          	auipc	s1,0x10
    8000260c:	1a048493          	addi	s1,s1,416 # 800127a8 <proc>
    80002610:	a08d                	j	80002672 <wait+0xa4>
          pid = np->pid;
    80002612:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002616:	000b0e63          	beqz	s6,80002632 <wait+0x64>
    8000261a:	4691                	li	a3,4
    8000261c:	03c48613          	addi	a2,s1,60
    80002620:	85da                	mv	a1,s6
    80002622:	05893503          	ld	a0,88(s2)
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	408080e7          	jalr	1032(ra) # 80001a2e <copyout>
    8000262e:	02054263          	bltz	a0,80002652 <wait+0x84>
          freeproc(np);
    80002632:	8526                	mv	a0,s1
    80002634:	00000097          	auipc	ra,0x0
    80002638:	8b6080e7          	jalr	-1866(ra) # 80001eea <freeproc>
          release(&np->lock);
    8000263c:	8526                	mv	a0,s1
    8000263e:	ffffe097          	auipc	ra,0xffffe
    80002642:	784080e7          	jalr	1924(ra) # 80000dc2 <release>
          release(&p->lock);
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	77a080e7          	jalr	1914(ra) # 80000dc2 <release>
          return pid;
    80002650:	a8a9                	j	800026aa <wait+0xdc>
            release(&np->lock);
    80002652:	8526                	mv	a0,s1
    80002654:	ffffe097          	auipc	ra,0xffffe
    80002658:	76e080e7          	jalr	1902(ra) # 80000dc2 <release>
            release(&p->lock);
    8000265c:	854a                	mv	a0,s2
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	764080e7          	jalr	1892(ra) # 80000dc2 <release>
            return -1;
    80002666:	59fd                	li	s3,-1
    80002668:	a089                	j	800026aa <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000266a:	17048493          	addi	s1,s1,368
    8000266e:	03348463          	beq	s1,s3,80002696 <wait+0xc8>
      if(np->parent == p){
    80002672:	749c                	ld	a5,40(s1)
    80002674:	ff279be3          	bne	a5,s2,8000266a <wait+0x9c>
        acquire(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	678080e7          	jalr	1656(ra) # 80000cf2 <acquire>
        if(np->state == ZOMBIE){
    80002682:	509c                	lw	a5,32(s1)
    80002684:	f94787e3          	beq	a5,s4,80002612 <wait+0x44>
        release(&np->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	738080e7          	jalr	1848(ra) # 80000dc2 <release>
        havekids = 1;
    80002692:	8756                	mv	a4,s5
    80002694:	bfd9                	j	8000266a <wait+0x9c>
    if(!havekids || p->killed){
    80002696:	c701                	beqz	a4,8000269e <wait+0xd0>
    80002698:	03892783          	lw	a5,56(s2)
    8000269c:	c39d                	beqz	a5,800026c2 <wait+0xf4>
      release(&p->lock);
    8000269e:	854a                	mv	a0,s2
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	722080e7          	jalr	1826(ra) # 80000dc2 <release>
      return -1;
    800026a8:	59fd                	li	s3,-1
}
    800026aa:	854e                	mv	a0,s3
    800026ac:	60a6                	ld	ra,72(sp)
    800026ae:	6406                	ld	s0,64(sp)
    800026b0:	74e2                	ld	s1,56(sp)
    800026b2:	7942                	ld	s2,48(sp)
    800026b4:	79a2                	ld	s3,40(sp)
    800026b6:	7a02                	ld	s4,32(sp)
    800026b8:	6ae2                	ld	s5,24(sp)
    800026ba:	6b42                	ld	s6,16(sp)
    800026bc:	6ba2                	ld	s7,8(sp)
    800026be:	6161                	addi	sp,sp,80
    800026c0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026c2:	85ca                	mv	a1,s2
    800026c4:	854a                	mv	a0,s2
    800026c6:	00000097          	auipc	ra,0x0
    800026ca:	e8a080e7          	jalr	-374(ra) # 80002550 <sleep>
    havekids = 0;
    800026ce:	bf25                	j	80002606 <wait+0x38>

00000000800026d0 <wakeup>:
{
    800026d0:	7139                	addi	sp,sp,-64
    800026d2:	fc06                	sd	ra,56(sp)
    800026d4:	f822                	sd	s0,48(sp)
    800026d6:	f426                	sd	s1,40(sp)
    800026d8:	f04a                	sd	s2,32(sp)
    800026da:	ec4e                	sd	s3,24(sp)
    800026dc:	e852                	sd	s4,16(sp)
    800026de:	e456                	sd	s5,8(sp)
    800026e0:	0080                	addi	s0,sp,64
    800026e2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e4:	00010497          	auipc	s1,0x10
    800026e8:	0c448493          	addi	s1,s1,196 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026ec:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026ee:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f0:	00016917          	auipc	s2,0x16
    800026f4:	cb890913          	addi	s2,s2,-840 # 800183a8 <tickslock>
    800026f8:	a811                	j	8000270c <wakeup+0x3c>
    release(&p->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	6c6080e7          	jalr	1734(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002704:	17048493          	addi	s1,s1,368
    80002708:	03248063          	beq	s1,s2,80002728 <wakeup+0x58>
    acquire(&p->lock);
    8000270c:	8526                	mv	a0,s1
    8000270e:	ffffe097          	auipc	ra,0xffffe
    80002712:	5e4080e7          	jalr	1508(ra) # 80000cf2 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002716:	509c                	lw	a5,32(s1)
    80002718:	ff3791e3          	bne	a5,s3,800026fa <wakeup+0x2a>
    8000271c:	789c                	ld	a5,48(s1)
    8000271e:	fd479ee3          	bne	a5,s4,800026fa <wakeup+0x2a>
      p->state = RUNNABLE;
    80002722:	0354a023          	sw	s5,32(s1)
    80002726:	bfd1                	j	800026fa <wakeup+0x2a>
}
    80002728:	70e2                	ld	ra,56(sp)
    8000272a:	7442                	ld	s0,48(sp)
    8000272c:	74a2                	ld	s1,40(sp)
    8000272e:	7902                	ld	s2,32(sp)
    80002730:	69e2                	ld	s3,24(sp)
    80002732:	6a42                	ld	s4,16(sp)
    80002734:	6aa2                	ld	s5,8(sp)
    80002736:	6121                	addi	sp,sp,64
    80002738:	8082                	ret

000000008000273a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000273a:	7179                	addi	sp,sp,-48
    8000273c:	f406                	sd	ra,40(sp)
    8000273e:	f022                	sd	s0,32(sp)
    80002740:	ec26                	sd	s1,24(sp)
    80002742:	e84a                	sd	s2,16(sp)
    80002744:	e44e                	sd	s3,8(sp)
    80002746:	1800                	addi	s0,sp,48
    80002748:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000274a:	00010497          	auipc	s1,0x10
    8000274e:	05e48493          	addi	s1,s1,94 # 800127a8 <proc>
    80002752:	00016997          	auipc	s3,0x16
    80002756:	c5698993          	addi	s3,s3,-938 # 800183a8 <tickslock>
    acquire(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	596080e7          	jalr	1430(ra) # 80000cf2 <acquire>
    if(p->pid == pid){
    80002764:	40bc                	lw	a5,64(s1)
    80002766:	01278d63          	beq	a5,s2,80002780 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000276a:	8526                	mv	a0,s1
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	656080e7          	jalr	1622(ra) # 80000dc2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002774:	17048493          	addi	s1,s1,368
    80002778:	ff3491e3          	bne	s1,s3,8000275a <kill+0x20>
  }
  return -1;
    8000277c:	557d                	li	a0,-1
    8000277e:	a821                	j	80002796 <kill+0x5c>
      p->killed = 1;
    80002780:	4785                	li	a5,1
    80002782:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002784:	5098                	lw	a4,32(s1)
    80002786:	00f70f63          	beq	a4,a5,800027a4 <kill+0x6a>
      release(&p->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	636080e7          	jalr	1590(ra) # 80000dc2 <release>
      return 0;
    80002794:	4501                	li	a0,0
}
    80002796:	70a2                	ld	ra,40(sp)
    80002798:	7402                	ld	s0,32(sp)
    8000279a:	64e2                	ld	s1,24(sp)
    8000279c:	6942                	ld	s2,16(sp)
    8000279e:	69a2                	ld	s3,8(sp)
    800027a0:	6145                	addi	sp,sp,48
    800027a2:	8082                	ret
        p->state = RUNNABLE;
    800027a4:	4789                	li	a5,2
    800027a6:	d09c                	sw	a5,32(s1)
    800027a8:	b7cd                	j	8000278a <kill+0x50>

00000000800027aa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027aa:	7179                	addi	sp,sp,-48
    800027ac:	f406                	sd	ra,40(sp)
    800027ae:	f022                	sd	s0,32(sp)
    800027b0:	ec26                	sd	s1,24(sp)
    800027b2:	e84a                	sd	s2,16(sp)
    800027b4:	e44e                	sd	s3,8(sp)
    800027b6:	e052                	sd	s4,0(sp)
    800027b8:	1800                	addi	s0,sp,48
    800027ba:	84aa                	mv	s1,a0
    800027bc:	892e                	mv	s2,a1
    800027be:	89b2                	mv	s3,a2
    800027c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027c2:	fffff097          	auipc	ra,0xfffff
    800027c6:	576080e7          	jalr	1398(ra) # 80001d38 <myproc>
  if(user_dst){
    800027ca:	c08d                	beqz	s1,800027ec <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027cc:	86d2                	mv	a3,s4
    800027ce:	864e                	mv	a2,s3
    800027d0:	85ca                	mv	a1,s2
    800027d2:	6d28                	ld	a0,88(a0)
    800027d4:	fffff097          	auipc	ra,0xfffff
    800027d8:	25a080e7          	jalr	602(ra) # 80001a2e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027dc:	70a2                	ld	ra,40(sp)
    800027de:	7402                	ld	s0,32(sp)
    800027e0:	64e2                	ld	s1,24(sp)
    800027e2:	6942                	ld	s2,16(sp)
    800027e4:	69a2                	ld	s3,8(sp)
    800027e6:	6a02                	ld	s4,0(sp)
    800027e8:	6145                	addi	sp,sp,48
    800027ea:	8082                	ret
    memmove((char *)dst, src, len);
    800027ec:	000a061b          	sext.w	a2,s4
    800027f0:	85ce                	mv	a1,s3
    800027f2:	854a                	mv	a0,s2
    800027f4:	fffff097          	auipc	ra,0xfffff
    800027f8:	93a080e7          	jalr	-1734(ra) # 8000112e <memmove>
    return 0;
    800027fc:	8526                	mv	a0,s1
    800027fe:	bff9                	j	800027dc <either_copyout+0x32>

0000000080002800 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002800:	7179                	addi	sp,sp,-48
    80002802:	f406                	sd	ra,40(sp)
    80002804:	f022                	sd	s0,32(sp)
    80002806:	ec26                	sd	s1,24(sp)
    80002808:	e84a                	sd	s2,16(sp)
    8000280a:	e44e                	sd	s3,8(sp)
    8000280c:	e052                	sd	s4,0(sp)
    8000280e:	1800                	addi	s0,sp,48
    80002810:	892a                	mv	s2,a0
    80002812:	84ae                	mv	s1,a1
    80002814:	89b2                	mv	s3,a2
    80002816:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002818:	fffff097          	auipc	ra,0xfffff
    8000281c:	520080e7          	jalr	1312(ra) # 80001d38 <myproc>
  if(user_src){
    80002820:	c08d                	beqz	s1,80002842 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002822:	86d2                	mv	a3,s4
    80002824:	864e                	mv	a2,s3
    80002826:	85ca                	mv	a1,s2
    80002828:	6d28                	ld	a0,88(a0)
    8000282a:	fffff097          	auipc	ra,0xfffff
    8000282e:	290080e7          	jalr	656(ra) # 80001aba <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002832:	70a2                	ld	ra,40(sp)
    80002834:	7402                	ld	s0,32(sp)
    80002836:	64e2                	ld	s1,24(sp)
    80002838:	6942                	ld	s2,16(sp)
    8000283a:	69a2                	ld	s3,8(sp)
    8000283c:	6a02                	ld	s4,0(sp)
    8000283e:	6145                	addi	sp,sp,48
    80002840:	8082                	ret
    memmove(dst, (char*)src, len);
    80002842:	000a061b          	sext.w	a2,s4
    80002846:	85ce                	mv	a1,s3
    80002848:	854a                	mv	a0,s2
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	8e4080e7          	jalr	-1820(ra) # 8000112e <memmove>
    return 0;
    80002852:	8526                	mv	a0,s1
    80002854:	bff9                	j	80002832 <either_copyin+0x32>

0000000080002856 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002856:	715d                	addi	sp,sp,-80
    80002858:	e486                	sd	ra,72(sp)
    8000285a:	e0a2                	sd	s0,64(sp)
    8000285c:	fc26                	sd	s1,56(sp)
    8000285e:	f84a                	sd	s2,48(sp)
    80002860:	f44e                	sd	s3,40(sp)
    80002862:	f052                	sd	s4,32(sp)
    80002864:	ec56                	sd	s5,24(sp)
    80002866:	e85a                	sd	s6,16(sp)
    80002868:	e45e                	sd	s7,8(sp)
    8000286a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000286c:	00006517          	auipc	a0,0x6
    80002870:	8f450513          	addi	a0,a0,-1804 # 80008160 <digits+0x120>
    80002874:	ffffe097          	auipc	ra,0xffffe
    80002878:	d22080e7          	jalr	-734(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000287c:	00010497          	auipc	s1,0x10
    80002880:	08c48493          	addi	s1,s1,140 # 80012908 <proc+0x160>
    80002884:	00016917          	auipc	s2,0x16
    80002888:	c8490913          	addi	s2,s2,-892 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000288c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000288e:	00006997          	auipc	s3,0x6
    80002892:	a6a98993          	addi	s3,s3,-1430 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    80002896:	00006a97          	auipc	s5,0x6
    8000289a:	a6aa8a93          	addi	s5,s5,-1430 # 80008300 <digits+0x2c0>
    printf("\n");
    8000289e:	00006a17          	auipc	s4,0x6
    800028a2:	8c2a0a13          	addi	s4,s4,-1854 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a6:	00006b97          	auipc	s7,0x6
    800028aa:	a92b8b93          	addi	s7,s7,-1390 # 80008338 <states.0>
    800028ae:	a00d                	j	800028d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028b0:	ee06a583          	lw	a1,-288(a3)
    800028b4:	8556                	mv	a0,s5
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	ce0080e7          	jalr	-800(ra) # 80000596 <printf>
    printf("\n");
    800028be:	8552                	mv	a0,s4
    800028c0:	ffffe097          	auipc	ra,0xffffe
    800028c4:	cd6080e7          	jalr	-810(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028c8:	17048493          	addi	s1,s1,368
    800028cc:	03248263          	beq	s1,s2,800028f0 <procdump+0x9a>
    if(p->state == UNUSED)
    800028d0:	86a6                	mv	a3,s1
    800028d2:	ec04a783          	lw	a5,-320(s1)
    800028d6:	dbed                	beqz	a5,800028c8 <procdump+0x72>
      state = "???";
    800028d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028da:	fcfb6be3          	bltu	s6,a5,800028b0 <procdump+0x5a>
    800028de:	02079713          	slli	a4,a5,0x20
    800028e2:	01d75793          	srli	a5,a4,0x1d
    800028e6:	97de                	add	a5,a5,s7
    800028e8:	6390                	ld	a2,0(a5)
    800028ea:	f279                	bnez	a2,800028b0 <procdump+0x5a>
      state = "???";
    800028ec:	864e                	mv	a2,s3
    800028ee:	b7c9                	j	800028b0 <procdump+0x5a>
  }
}
    800028f0:	60a6                	ld	ra,72(sp)
    800028f2:	6406                	ld	s0,64(sp)
    800028f4:	74e2                	ld	s1,56(sp)
    800028f6:	7942                	ld	s2,48(sp)
    800028f8:	79a2                	ld	s3,40(sp)
    800028fa:	7a02                	ld	s4,32(sp)
    800028fc:	6ae2                	ld	s5,24(sp)
    800028fe:	6b42                	ld	s6,16(sp)
    80002900:	6ba2                	ld	s7,8(sp)
    80002902:	6161                	addi	sp,sp,80
    80002904:	8082                	ret

0000000080002906 <swtch>:
    80002906:	00153023          	sd	ra,0(a0)
    8000290a:	00253423          	sd	sp,8(a0)
    8000290e:	e900                	sd	s0,16(a0)
    80002910:	ed04                	sd	s1,24(a0)
    80002912:	03253023          	sd	s2,32(a0)
    80002916:	03353423          	sd	s3,40(a0)
    8000291a:	03453823          	sd	s4,48(a0)
    8000291e:	03553c23          	sd	s5,56(a0)
    80002922:	05653023          	sd	s6,64(a0)
    80002926:	05753423          	sd	s7,72(a0)
    8000292a:	05853823          	sd	s8,80(a0)
    8000292e:	05953c23          	sd	s9,88(a0)
    80002932:	07a53023          	sd	s10,96(a0)
    80002936:	07b53423          	sd	s11,104(a0)
    8000293a:	0005b083          	ld	ra,0(a1)
    8000293e:	0085b103          	ld	sp,8(a1)
    80002942:	6980                	ld	s0,16(a1)
    80002944:	6d84                	ld	s1,24(a1)
    80002946:	0205b903          	ld	s2,32(a1)
    8000294a:	0285b983          	ld	s3,40(a1)
    8000294e:	0305ba03          	ld	s4,48(a1)
    80002952:	0385ba83          	ld	s5,56(a1)
    80002956:	0405bb03          	ld	s6,64(a1)
    8000295a:	0485bb83          	ld	s7,72(a1)
    8000295e:	0505bc03          	ld	s8,80(a1)
    80002962:	0585bc83          	ld	s9,88(a1)
    80002966:	0605bd03          	ld	s10,96(a1)
    8000296a:	0685bd83          	ld	s11,104(a1)
    8000296e:	8082                	ret

0000000080002970 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002970:	1141                	addi	sp,sp,-16
    80002972:	e406                	sd	ra,8(sp)
    80002974:	e022                	sd	s0,0(sp)
    80002976:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002978:	00006597          	auipc	a1,0x6
    8000297c:	9e858593          	addi	a1,a1,-1560 # 80008360 <states.0+0x28>
    80002980:	00016517          	auipc	a0,0x16
    80002984:	a2850513          	addi	a0,a0,-1496 # 800183a8 <tickslock>
    80002988:	ffffe097          	auipc	ra,0xffffe
    8000298c:	4e6080e7          	jalr	1254(ra) # 80000e6e <initlock>
}
    80002990:	60a2                	ld	ra,8(sp)
    80002992:	6402                	ld	s0,0(sp)
    80002994:	0141                	addi	sp,sp,16
    80002996:	8082                	ret

0000000080002998 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002998:	1141                	addi	sp,sp,-16
    8000299a:	e422                	sd	s0,8(sp)
    8000299c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000299e:	00003797          	auipc	a5,0x3
    800029a2:	4e278793          	addi	a5,a5,1250 # 80005e80 <kernelvec>
    800029a6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029aa:	6422                	ld	s0,8(sp)
    800029ac:	0141                	addi	sp,sp,16
    800029ae:	8082                	ret

00000000800029b0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029b0:	1141                	addi	sp,sp,-16
    800029b2:	e406                	sd	ra,8(sp)
    800029b4:	e022                	sd	s0,0(sp)
    800029b6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	380080e7          	jalr	896(ra) # 80001d38 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029c4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ca:	00004697          	auipc	a3,0x4
    800029ce:	63668693          	addi	a3,a3,1590 # 80007000 <_trampoline>
    800029d2:	00004717          	auipc	a4,0x4
    800029d6:	62e70713          	addi	a4,a4,1582 # 80007000 <_trampoline>
    800029da:	8f15                	sub	a4,a4,a3
    800029dc:	040007b7          	lui	a5,0x4000
    800029e0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029e2:	07b2                	slli	a5,a5,0xc
    800029e4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029e6:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029ea:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029ec:	18002673          	csrr	a2,satp
    800029f0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029f2:	7130                	ld	a2,96(a0)
    800029f4:	6538                	ld	a4,72(a0)
    800029f6:	6585                	lui	a1,0x1
    800029f8:	972e                	add	a4,a4,a1
    800029fa:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029fc:	7138                	ld	a4,96(a0)
    800029fe:	00000617          	auipc	a2,0x0
    80002a02:	13860613          	addi	a2,a2,312 # 80002b36 <usertrap>
    80002a06:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a08:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a0a:	8612                	mv	a2,tp
    80002a0c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a12:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a16:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a1e:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a20:	6f18                	ld	a4,24(a4)
    80002a22:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a26:	6d2c                	ld	a1,88(a0)
    80002a28:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a2a:	00004717          	auipc	a4,0x4
    80002a2e:	66670713          	addi	a4,a4,1638 # 80007090 <userret>
    80002a32:	8f15                	sub	a4,a4,a3
    80002a34:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a36:	577d                	li	a4,-1
    80002a38:	177e                	slli	a4,a4,0x3f
    80002a3a:	8dd9                	or	a1,a1,a4
    80002a3c:	02000537          	lui	a0,0x2000
    80002a40:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a42:	0536                	slli	a0,a0,0xd
    80002a44:	9782                	jalr	a5
}
    80002a46:	60a2                	ld	ra,8(sp)
    80002a48:	6402                	ld	s0,0(sp)
    80002a4a:	0141                	addi	sp,sp,16
    80002a4c:	8082                	ret

0000000080002a4e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a4e:	1101                	addi	sp,sp,-32
    80002a50:	ec06                	sd	ra,24(sp)
    80002a52:	e822                	sd	s0,16(sp)
    80002a54:	e426                	sd	s1,8(sp)
    80002a56:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a58:	00016497          	auipc	s1,0x16
    80002a5c:	95048493          	addi	s1,s1,-1712 # 800183a8 <tickslock>
    80002a60:	8526                	mv	a0,s1
    80002a62:	ffffe097          	auipc	ra,0xffffe
    80002a66:	290080e7          	jalr	656(ra) # 80000cf2 <acquire>
  ticks++;
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	5b650513          	addi	a0,a0,1462 # 80009020 <ticks>
    80002a72:	411c                	lw	a5,0(a0)
    80002a74:	2785                	addiw	a5,a5,1
    80002a76:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a78:	00000097          	auipc	ra,0x0
    80002a7c:	c58080e7          	jalr	-936(ra) # 800026d0 <wakeup>
  release(&tickslock);
    80002a80:	8526                	mv	a0,s1
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	340080e7          	jalr	832(ra) # 80000dc2 <release>
}
    80002a8a:	60e2                	ld	ra,24(sp)
    80002a8c:	6442                	ld	s0,16(sp)
    80002a8e:	64a2                	ld	s1,8(sp)
    80002a90:	6105                	addi	sp,sp,32
    80002a92:	8082                	ret

0000000080002a94 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a94:	1101                	addi	sp,sp,-32
    80002a96:	ec06                	sd	ra,24(sp)
    80002a98:	e822                	sd	s0,16(sp)
    80002a9a:	e426                	sd	s1,8(sp)
    80002a9c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a9e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aa2:	00074d63          	bltz	a4,80002abc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002aa6:	57fd                	li	a5,-1
    80002aa8:	17fe                	slli	a5,a5,0x3f
    80002aaa:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aac:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aae:	06f70363          	beq	a4,a5,80002b14 <devintr+0x80>
  }
}
    80002ab2:	60e2                	ld	ra,24(sp)
    80002ab4:	6442                	ld	s0,16(sp)
    80002ab6:	64a2                	ld	s1,8(sp)
    80002ab8:	6105                	addi	sp,sp,32
    80002aba:	8082                	ret
     (scause & 0xff) == 9){
    80002abc:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002ac0:	46a5                	li	a3,9
    80002ac2:	fed792e3          	bne	a5,a3,80002aa6 <devintr+0x12>
    int irq = plic_claim();
    80002ac6:	00003097          	auipc	ra,0x3
    80002aca:	4c2080e7          	jalr	1218(ra) # 80005f88 <plic_claim>
    80002ace:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ad0:	47a9                	li	a5,10
    80002ad2:	02f50763          	beq	a0,a5,80002b00 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ad6:	4785                	li	a5,1
    80002ad8:	02f50963          	beq	a0,a5,80002b0a <devintr+0x76>
    return 1;
    80002adc:	4505                	li	a0,1
    } else if(irq){
    80002ade:	d8f1                	beqz	s1,80002ab2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ae0:	85a6                	mv	a1,s1
    80002ae2:	00006517          	auipc	a0,0x6
    80002ae6:	88650513          	addi	a0,a0,-1914 # 80008368 <states.0+0x30>
    80002aea:	ffffe097          	auipc	ra,0xffffe
    80002aee:	aac080e7          	jalr	-1364(ra) # 80000596 <printf>
      plic_complete(irq);
    80002af2:	8526                	mv	a0,s1
    80002af4:	00003097          	auipc	ra,0x3
    80002af8:	4b8080e7          	jalr	1208(ra) # 80005fac <plic_complete>
    return 1;
    80002afc:	4505                	li	a0,1
    80002afe:	bf55                	j	80002ab2 <devintr+0x1e>
      uartintr();
    80002b00:	ffffe097          	auipc	ra,0xffffe
    80002b04:	ec8080e7          	jalr	-312(ra) # 800009c8 <uartintr>
    80002b08:	b7ed                	j	80002af2 <devintr+0x5e>
      virtio_disk_intr();
    80002b0a:	00004097          	auipc	ra,0x4
    80002b0e:	92e080e7          	jalr	-1746(ra) # 80006438 <virtio_disk_intr>
    80002b12:	b7c5                	j	80002af2 <devintr+0x5e>
    if(cpuid() == 0){
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	1f8080e7          	jalr	504(ra) # 80001d0c <cpuid>
    80002b1c:	c901                	beqz	a0,80002b2c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b1e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b22:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b24:	14479073          	csrw	sip,a5
    return 2;
    80002b28:	4509                	li	a0,2
    80002b2a:	b761                	j	80002ab2 <devintr+0x1e>
      clockintr();
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	f22080e7          	jalr	-222(ra) # 80002a4e <clockintr>
    80002b34:	b7ed                	j	80002b1e <devintr+0x8a>

0000000080002b36 <usertrap>:
{
    80002b36:	1101                	addi	sp,sp,-32
    80002b38:	ec06                	sd	ra,24(sp)
    80002b3a:	e822                	sd	s0,16(sp)
    80002b3c:	e426                	sd	s1,8(sp)
    80002b3e:	e04a                	sd	s2,0(sp)
    80002b40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b42:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b46:	1007f793          	andi	a5,a5,256
    80002b4a:	e3ad                	bnez	a5,80002bac <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b4c:	00003797          	auipc	a5,0x3
    80002b50:	33478793          	addi	a5,a5,820 # 80005e80 <kernelvec>
    80002b54:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b58:	fffff097          	auipc	ra,0xfffff
    80002b5c:	1e0080e7          	jalr	480(ra) # 80001d38 <myproc>
    80002b60:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b62:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b64:	14102773          	csrr	a4,sepc
    80002b68:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b6a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b6e:	47a1                	li	a5,8
    80002b70:	04f71c63          	bne	a4,a5,80002bc8 <usertrap+0x92>
    if(p->killed)
    80002b74:	5d1c                	lw	a5,56(a0)
    80002b76:	e3b9                	bnez	a5,80002bbc <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b78:	70b8                	ld	a4,96(s1)
    80002b7a:	6f1c                	ld	a5,24(a4)
    80002b7c:	0791                	addi	a5,a5,4
    80002b7e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b80:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b84:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b88:	10079073          	csrw	sstatus,a5
    syscall();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	2e0080e7          	jalr	736(ra) # 80002e6c <syscall>
  if(p->killed)
    80002b94:	5c9c                	lw	a5,56(s1)
    80002b96:	ebc1                	bnez	a5,80002c26 <usertrap+0xf0>
  usertrapret();
    80002b98:	00000097          	auipc	ra,0x0
    80002b9c:	e18080e7          	jalr	-488(ra) # 800029b0 <usertrapret>
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6902                	ld	s2,0(sp)
    80002ba8:	6105                	addi	sp,sp,32
    80002baa:	8082                	ret
    panic("usertrap: not from user mode");
    80002bac:	00005517          	auipc	a0,0x5
    80002bb0:	7dc50513          	addi	a0,a0,2012 # 80008388 <states.0+0x50>
    80002bb4:	ffffe097          	auipc	ra,0xffffe
    80002bb8:	998080e7          	jalr	-1640(ra) # 8000054c <panic>
      exit(-1);
    80002bbc:	557d                	li	a0,-1
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	84c080e7          	jalr	-1972(ra) # 8000240a <exit>
    80002bc6:	bf4d                	j	80002b78 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	ecc080e7          	jalr	-308(ra) # 80002a94 <devintr>
    80002bd0:	892a                	mv	s2,a0
    80002bd2:	c501                	beqz	a0,80002bda <usertrap+0xa4>
  if(p->killed)
    80002bd4:	5c9c                	lw	a5,56(s1)
    80002bd6:	c3a1                	beqz	a5,80002c16 <usertrap+0xe0>
    80002bd8:	a815                	j	80002c0c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bde:	40b0                	lw	a2,64(s1)
    80002be0:	00005517          	auipc	a0,0x5
    80002be4:	7c850513          	addi	a0,a0,1992 # 800083a8 <states.0+0x70>
    80002be8:	ffffe097          	auipc	ra,0xffffe
    80002bec:	9ae080e7          	jalr	-1618(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bf0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bf4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	7e050513          	addi	a0,a0,2016 # 800083d8 <states.0+0xa0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	996080e7          	jalr	-1642(ra) # 80000596 <printf>
    p->killed = 1;
    80002c08:	4785                	li	a5,1
    80002c0a:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c0c:	557d                	li	a0,-1
    80002c0e:	fffff097          	auipc	ra,0xfffff
    80002c12:	7fc080e7          	jalr	2044(ra) # 8000240a <exit>
  if(which_dev == 2)
    80002c16:	4789                	li	a5,2
    80002c18:	f8f910e3          	bne	s2,a5,80002b98 <usertrap+0x62>
    yield();
    80002c1c:	00000097          	auipc	ra,0x0
    80002c20:	8f8080e7          	jalr	-1800(ra) # 80002514 <yield>
    80002c24:	bf95                	j	80002b98 <usertrap+0x62>
  int which_dev = 0;
    80002c26:	4901                	li	s2,0
    80002c28:	b7d5                	j	80002c0c <usertrap+0xd6>

0000000080002c2a <kerneltrap>:
{
    80002c2a:	7179                	addi	sp,sp,-48
    80002c2c:	f406                	sd	ra,40(sp)
    80002c2e:	f022                	sd	s0,32(sp)
    80002c30:	ec26                	sd	s1,24(sp)
    80002c32:	e84a                	sd	s2,16(sp)
    80002c34:	e44e                	sd	s3,8(sp)
    80002c36:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c38:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c40:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c44:	1004f793          	andi	a5,s1,256
    80002c48:	cb85                	beqz	a5,80002c78 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c4e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c50:	ef85                	bnez	a5,80002c88 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c52:	00000097          	auipc	ra,0x0
    80002c56:	e42080e7          	jalr	-446(ra) # 80002a94 <devintr>
    80002c5a:	cd1d                	beqz	a0,80002c98 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c5c:	4789                	li	a5,2
    80002c5e:	06f50a63          	beq	a0,a5,80002cd2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c62:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c66:	10049073          	csrw	sstatus,s1
}
    80002c6a:	70a2                	ld	ra,40(sp)
    80002c6c:	7402                	ld	s0,32(sp)
    80002c6e:	64e2                	ld	s1,24(sp)
    80002c70:	6942                	ld	s2,16(sp)
    80002c72:	69a2                	ld	s3,8(sp)
    80002c74:	6145                	addi	sp,sp,48
    80002c76:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	78050513          	addi	a0,a0,1920 # 800083f8 <states.0+0xc0>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8cc080e7          	jalr	-1844(ra) # 8000054c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c88:	00005517          	auipc	a0,0x5
    80002c8c:	79850513          	addi	a0,a0,1944 # 80008420 <states.0+0xe8>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	8bc080e7          	jalr	-1860(ra) # 8000054c <panic>
    printf("scause %p\n", scause);
    80002c98:	85ce                	mv	a1,s3
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	7a650513          	addi	a0,a0,1958 # 80008440 <states.0+0x108>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	8f4080e7          	jalr	-1804(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002caa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cae:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	79e50513          	addi	a0,a0,1950 # 80008450 <states.0+0x118>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	8dc080e7          	jalr	-1828(ra) # 80000596 <printf>
    panic("kerneltrap");
    80002cc2:	00005517          	auipc	a0,0x5
    80002cc6:	7a650513          	addi	a0,a0,1958 # 80008468 <states.0+0x130>
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	882080e7          	jalr	-1918(ra) # 8000054c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	066080e7          	jalr	102(ra) # 80001d38 <myproc>
    80002cda:	d541                	beqz	a0,80002c62 <kerneltrap+0x38>
    80002cdc:	fffff097          	auipc	ra,0xfffff
    80002ce0:	05c080e7          	jalr	92(ra) # 80001d38 <myproc>
    80002ce4:	5118                	lw	a4,32(a0)
    80002ce6:	478d                	li	a5,3
    80002ce8:	f6f71de3          	bne	a4,a5,80002c62 <kerneltrap+0x38>
    yield();
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	828080e7          	jalr	-2008(ra) # 80002514 <yield>
    80002cf4:	b7bd                	j	80002c62 <kerneltrap+0x38>

0000000080002cf6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	1000                	addi	s0,sp,32
    80002d00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d02:	fffff097          	auipc	ra,0xfffff
    80002d06:	036080e7          	jalr	54(ra) # 80001d38 <myproc>
  switch (n) {
    80002d0a:	4795                	li	a5,5
    80002d0c:	0497e163          	bltu	a5,s1,80002d4e <argraw+0x58>
    80002d10:	048a                	slli	s1,s1,0x2
    80002d12:	00005717          	auipc	a4,0x5
    80002d16:	78e70713          	addi	a4,a4,1934 # 800084a0 <states.0+0x168>
    80002d1a:	94ba                	add	s1,s1,a4
    80002d1c:	409c                	lw	a5,0(s1)
    80002d1e:	97ba                	add	a5,a5,a4
    80002d20:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d22:	713c                	ld	a5,96(a0)
    80002d24:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret
    return p->trapframe->a1;
    80002d30:	713c                	ld	a5,96(a0)
    80002d32:	7fa8                	ld	a0,120(a5)
    80002d34:	bfcd                	j	80002d26 <argraw+0x30>
    return p->trapframe->a2;
    80002d36:	713c                	ld	a5,96(a0)
    80002d38:	63c8                	ld	a0,128(a5)
    80002d3a:	b7f5                	j	80002d26 <argraw+0x30>
    return p->trapframe->a3;
    80002d3c:	713c                	ld	a5,96(a0)
    80002d3e:	67c8                	ld	a0,136(a5)
    80002d40:	b7dd                	j	80002d26 <argraw+0x30>
    return p->trapframe->a4;
    80002d42:	713c                	ld	a5,96(a0)
    80002d44:	6bc8                	ld	a0,144(a5)
    80002d46:	b7c5                	j	80002d26 <argraw+0x30>
    return p->trapframe->a5;
    80002d48:	713c                	ld	a5,96(a0)
    80002d4a:	6fc8                	ld	a0,152(a5)
    80002d4c:	bfe9                	j	80002d26 <argraw+0x30>
  panic("argraw");
    80002d4e:	00005517          	auipc	a0,0x5
    80002d52:	72a50513          	addi	a0,a0,1834 # 80008478 <states.0+0x140>
    80002d56:	ffffd097          	auipc	ra,0xffffd
    80002d5a:	7f6080e7          	jalr	2038(ra) # 8000054c <panic>

0000000080002d5e <fetchaddr>:
{
    80002d5e:	1101                	addi	sp,sp,-32
    80002d60:	ec06                	sd	ra,24(sp)
    80002d62:	e822                	sd	s0,16(sp)
    80002d64:	e426                	sd	s1,8(sp)
    80002d66:	e04a                	sd	s2,0(sp)
    80002d68:	1000                	addi	s0,sp,32
    80002d6a:	84aa                	mv	s1,a0
    80002d6c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	fca080e7          	jalr	-54(ra) # 80001d38 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d76:	693c                	ld	a5,80(a0)
    80002d78:	02f4f863          	bgeu	s1,a5,80002da8 <fetchaddr+0x4a>
    80002d7c:	00848713          	addi	a4,s1,8
    80002d80:	02e7e663          	bltu	a5,a4,80002dac <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d84:	46a1                	li	a3,8
    80002d86:	8626                	mv	a2,s1
    80002d88:	85ca                	mv	a1,s2
    80002d8a:	6d28                	ld	a0,88(a0)
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	d2e080e7          	jalr	-722(ra) # 80001aba <copyin>
    80002d94:	00a03533          	snez	a0,a0
    80002d98:	40a00533          	neg	a0,a0
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6902                	ld	s2,0(sp)
    80002da4:	6105                	addi	sp,sp,32
    80002da6:	8082                	ret
    return -1;
    80002da8:	557d                	li	a0,-1
    80002daa:	bfcd                	j	80002d9c <fetchaddr+0x3e>
    80002dac:	557d                	li	a0,-1
    80002dae:	b7fd                	j	80002d9c <fetchaddr+0x3e>

0000000080002db0 <fetchstr>:
{
    80002db0:	7179                	addi	sp,sp,-48
    80002db2:	f406                	sd	ra,40(sp)
    80002db4:	f022                	sd	s0,32(sp)
    80002db6:	ec26                	sd	s1,24(sp)
    80002db8:	e84a                	sd	s2,16(sp)
    80002dba:	e44e                	sd	s3,8(sp)
    80002dbc:	1800                	addi	s0,sp,48
    80002dbe:	892a                	mv	s2,a0
    80002dc0:	84ae                	mv	s1,a1
    80002dc2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	f74080e7          	jalr	-140(ra) # 80001d38 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dcc:	86ce                	mv	a3,s3
    80002dce:	864a                	mv	a2,s2
    80002dd0:	85a6                	mv	a1,s1
    80002dd2:	6d28                	ld	a0,88(a0)
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	d74080e7          	jalr	-652(ra) # 80001b48 <copyinstr>
  if(err < 0)
    80002ddc:	00054763          	bltz	a0,80002dea <fetchstr+0x3a>
  return strlen(buf);
    80002de0:	8526                	mv	a0,s1
    80002de2:	ffffe097          	auipc	ra,0xffffe
    80002de6:	474080e7          	jalr	1140(ra) # 80001256 <strlen>
}
    80002dea:	70a2                	ld	ra,40(sp)
    80002dec:	7402                	ld	s0,32(sp)
    80002dee:	64e2                	ld	s1,24(sp)
    80002df0:	6942                	ld	s2,16(sp)
    80002df2:	69a2                	ld	s3,8(sp)
    80002df4:	6145                	addi	sp,sp,48
    80002df6:	8082                	ret

0000000080002df8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	e426                	sd	s1,8(sp)
    80002e00:	1000                	addi	s0,sp,32
    80002e02:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	ef2080e7          	jalr	-270(ra) # 80002cf6 <argraw>
    80002e0c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e0e:	4501                	li	a0,0
    80002e10:	60e2                	ld	ra,24(sp)
    80002e12:	6442                	ld	s0,16(sp)
    80002e14:	64a2                	ld	s1,8(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
    80002e24:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	ed0080e7          	jalr	-304(ra) # 80002cf6 <argraw>
    80002e2e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e30:	4501                	li	a0,0
    80002e32:	60e2                	ld	ra,24(sp)
    80002e34:	6442                	ld	s0,16(sp)
    80002e36:	64a2                	ld	s1,8(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	e04a                	sd	s2,0(sp)
    80002e46:	1000                	addi	s0,sp,32
    80002e48:	84ae                	mv	s1,a1
    80002e4a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e4c:	00000097          	auipc	ra,0x0
    80002e50:	eaa080e7          	jalr	-342(ra) # 80002cf6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e54:	864a                	mv	a2,s2
    80002e56:	85a6                	mv	a1,s1
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	f58080e7          	jalr	-168(ra) # 80002db0 <fetchstr>
}
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	64a2                	ld	s1,8(sp)
    80002e66:	6902                	ld	s2,0(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	e426                	sd	s1,8(sp)
    80002e74:	e04a                	sd	s2,0(sp)
    80002e76:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e78:	fffff097          	auipc	ra,0xfffff
    80002e7c:	ec0080e7          	jalr	-320(ra) # 80001d38 <myproc>
    80002e80:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e82:	06053903          	ld	s2,96(a0)
    80002e86:	0a893783          	ld	a5,168(s2)
    80002e8a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e8e:	37fd                	addiw	a5,a5,-1
    80002e90:	4751                	li	a4,20
    80002e92:	00f76f63          	bltu	a4,a5,80002eb0 <syscall+0x44>
    80002e96:	00369713          	slli	a4,a3,0x3
    80002e9a:	00005797          	auipc	a5,0x5
    80002e9e:	61e78793          	addi	a5,a5,1566 # 800084b8 <syscalls>
    80002ea2:	97ba                	add	a5,a5,a4
    80002ea4:	639c                	ld	a5,0(a5)
    80002ea6:	c789                	beqz	a5,80002eb0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea8:	9782                	jalr	a5
    80002eaa:	06a93823          	sd	a0,112(s2)
    80002eae:	a839                	j	80002ecc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eb0:	16048613          	addi	a2,s1,352
    80002eb4:	40ac                	lw	a1,64(s1)
    80002eb6:	00005517          	auipc	a0,0x5
    80002eba:	5ca50513          	addi	a0,a0,1482 # 80008480 <states.0+0x148>
    80002ebe:	ffffd097          	auipc	ra,0xffffd
    80002ec2:	6d8080e7          	jalr	1752(ra) # 80000596 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ec6:	70bc                	ld	a5,96(s1)
    80002ec8:	577d                	li	a4,-1
    80002eca:	fbb8                	sd	a4,112(a5)
  }
}
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	64a2                	ld	s1,8(sp)
    80002ed2:	6902                	ld	s2,0(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ee0:	fec40593          	addi	a1,s0,-20
    80002ee4:	4501                	li	a0,0
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	f12080e7          	jalr	-238(ra) # 80002df8 <argint>
    return -1;
    80002eee:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ef0:	00054963          	bltz	a0,80002f02 <sys_exit+0x2a>
  exit(n);
    80002ef4:	fec42503          	lw	a0,-20(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	512080e7          	jalr	1298(ra) # 8000240a <exit>
  return 0;  // not reached
    80002f00:	4781                	li	a5,0
}
    80002f02:	853e                	mv	a0,a5
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f0c:	1141                	addi	sp,sp,-16
    80002f0e:	e406                	sd	ra,8(sp)
    80002f10:	e022                	sd	s0,0(sp)
    80002f12:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	e24080e7          	jalr	-476(ra) # 80001d38 <myproc>
}
    80002f1c:	4128                	lw	a0,64(a0)
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <sys_fork>:

uint64
sys_fork(void)
{
    80002f26:	1141                	addi	sp,sp,-16
    80002f28:	e406                	sd	ra,8(sp)
    80002f2a:	e022                	sd	s0,0(sp)
    80002f2c:	0800                	addi	s0,sp,16
  return fork();
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	1ce080e7          	jalr	462(ra) # 800020fc <fork>
}
    80002f36:	60a2                	ld	ra,8(sp)
    80002f38:	6402                	ld	s0,0(sp)
    80002f3a:	0141                	addi	sp,sp,16
    80002f3c:	8082                	ret

0000000080002f3e <sys_wait>:

uint64
sys_wait(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f46:	fe840593          	addi	a1,s0,-24
    80002f4a:	4501                	li	a0,0
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	ece080e7          	jalr	-306(ra) # 80002e1a <argaddr>
    80002f54:	87aa                	mv	a5,a0
    return -1;
    80002f56:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f58:	0007c863          	bltz	a5,80002f68 <sys_wait+0x2a>
  return wait(p);
    80002f5c:	fe843503          	ld	a0,-24(s0)
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	66e080e7          	jalr	1646(ra) # 800025ce <wait>
}
    80002f68:	60e2                	ld	ra,24(sp)
    80002f6a:	6442                	ld	s0,16(sp)
    80002f6c:	6105                	addi	sp,sp,32
    80002f6e:	8082                	ret

0000000080002f70 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f70:	7179                	addi	sp,sp,-48
    80002f72:	f406                	sd	ra,40(sp)
    80002f74:	f022                	sd	s0,32(sp)
    80002f76:	ec26                	sd	s1,24(sp)
    80002f78:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f7a:	fdc40593          	addi	a1,s0,-36
    80002f7e:	4501                	li	a0,0
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	e78080e7          	jalr	-392(ra) # 80002df8 <argint>
    80002f88:	87aa                	mv	a5,a0
    return -1;
    80002f8a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f8c:	0207c063          	bltz	a5,80002fac <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	da8080e7          	jalr	-600(ra) # 80001d38 <myproc>
    80002f98:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f9a:	fdc42503          	lw	a0,-36(s0)
    80002f9e:	fffff097          	auipc	ra,0xfffff
    80002fa2:	0e6080e7          	jalr	230(ra) # 80002084 <growproc>
    80002fa6:	00054863          	bltz	a0,80002fb6 <sys_sbrk+0x46>
    return -1;
  // printf("addr:%d\n", addr);
  return addr;
    80002faa:	8526                	mv	a0,s1
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6145                	addi	sp,sp,48
    80002fb4:	8082                	ret
    return -1;
    80002fb6:	557d                	li	a0,-1
    80002fb8:	bfd5                	j	80002fac <sys_sbrk+0x3c>

0000000080002fba <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fba:	7139                	addi	sp,sp,-64
    80002fbc:	fc06                	sd	ra,56(sp)
    80002fbe:	f822                	sd	s0,48(sp)
    80002fc0:	f426                	sd	s1,40(sp)
    80002fc2:	f04a                	sd	s2,32(sp)
    80002fc4:	ec4e                	sd	s3,24(sp)
    80002fc6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc8:	fcc40593          	addi	a1,s0,-52
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	e2a080e7          	jalr	-470(ra) # 80002df8 <argint>
    return -1;
    80002fd6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd8:	06054563          	bltz	a0,80003042 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fdc:	00015517          	auipc	a0,0x15
    80002fe0:	3cc50513          	addi	a0,a0,972 # 800183a8 <tickslock>
    80002fe4:	ffffe097          	auipc	ra,0xffffe
    80002fe8:	d0e080e7          	jalr	-754(ra) # 80000cf2 <acquire>
  ticks0 = ticks;
    80002fec:	00006917          	auipc	s2,0x6
    80002ff0:	03492903          	lw	s2,52(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ff4:	fcc42783          	lw	a5,-52(s0)
    80002ff8:	cf85                	beqz	a5,80003030 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ffa:	00015997          	auipc	s3,0x15
    80002ffe:	3ae98993          	addi	s3,s3,942 # 800183a8 <tickslock>
    80003002:	00006497          	auipc	s1,0x6
    80003006:	01e48493          	addi	s1,s1,30 # 80009020 <ticks>
    if(myproc()->killed){
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	d2e080e7          	jalr	-722(ra) # 80001d38 <myproc>
    80003012:	5d1c                	lw	a5,56(a0)
    80003014:	ef9d                	bnez	a5,80003052 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003016:	85ce                	mv	a1,s3
    80003018:	8526                	mv	a0,s1
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	536080e7          	jalr	1334(ra) # 80002550 <sleep>
  while(ticks - ticks0 < n){
    80003022:	409c                	lw	a5,0(s1)
    80003024:	412787bb          	subw	a5,a5,s2
    80003028:	fcc42703          	lw	a4,-52(s0)
    8000302c:	fce7efe3          	bltu	a5,a4,8000300a <sys_sleep+0x50>
  }
  release(&tickslock);
    80003030:	00015517          	auipc	a0,0x15
    80003034:	37850513          	addi	a0,a0,888 # 800183a8 <tickslock>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	d8a080e7          	jalr	-630(ra) # 80000dc2 <release>
  return 0;
    80003040:	4781                	li	a5,0
}
    80003042:	853e                	mv	a0,a5
    80003044:	70e2                	ld	ra,56(sp)
    80003046:	7442                	ld	s0,48(sp)
    80003048:	74a2                	ld	s1,40(sp)
    8000304a:	7902                	ld	s2,32(sp)
    8000304c:	69e2                	ld	s3,24(sp)
    8000304e:	6121                	addi	sp,sp,64
    80003050:	8082                	ret
      release(&tickslock);
    80003052:	00015517          	auipc	a0,0x15
    80003056:	35650513          	addi	a0,a0,854 # 800183a8 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	d68080e7          	jalr	-664(ra) # 80000dc2 <release>
      return -1;
    80003062:	57fd                	li	a5,-1
    80003064:	bff9                	j	80003042 <sys_sleep+0x88>

0000000080003066 <sys_kill>:

uint64
sys_kill(void)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000306e:	fec40593          	addi	a1,s0,-20
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d84080e7          	jalr	-636(ra) # 80002df8 <argint>
    8000307c:	87aa                	mv	a5,a0
    return -1;
    8000307e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003080:	0007c863          	bltz	a5,80003090 <sys_kill+0x2a>
  return kill(pid);
    80003084:	fec42503          	lw	a0,-20(s0)
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	6b2080e7          	jalr	1714(ra) # 8000273a <kill>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	6105                	addi	sp,sp,32
    80003096:	8082                	ret

0000000080003098 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	30650513          	addi	a0,a0,774 # 800183a8 <tickslock>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	c48080e7          	jalr	-952(ra) # 80000cf2 <acquire>
  xticks = ticks;
    800030b2:	00006497          	auipc	s1,0x6
    800030b6:	f6e4a483          	lw	s1,-146(s1) # 80009020 <ticks>
  release(&tickslock);
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	2ee50513          	addi	a0,a0,750 # 800183a8 <tickslock>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	d00080e7          	jalr	-768(ra) # 80000dc2 <release>
  return xticks;
}
    800030ca:	02049513          	slli	a0,s1,0x20
    800030ce:	9101                	srli	a0,a0,0x20
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret

00000000800030da <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030da:	7179                	addi	sp,sp,-48
    800030dc:	f406                	sd	ra,40(sp)
    800030de:	f022                	sd	s0,32(sp)
    800030e0:	ec26                	sd	s1,24(sp)
    800030e2:	e84a                	sd	s2,16(sp)
    800030e4:	e44e                	sd	s3,8(sp)
    800030e6:	e052                	sd	s4,0(sp)
    800030e8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030ea:	00005597          	auipc	a1,0x5
    800030ee:	01658593          	addi	a1,a1,22 # 80008100 <digits+0xc0>
    800030f2:	00015517          	auipc	a0,0x15
    800030f6:	2d650513          	addi	a0,a0,726 # 800183c8 <bcache>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	d74080e7          	jalr	-652(ra) # 80000e6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003102:	0001d797          	auipc	a5,0x1d
    80003106:	2c678793          	addi	a5,a5,710 # 800203c8 <bcache+0x8000>
    8000310a:	0001d717          	auipc	a4,0x1d
    8000310e:	61e70713          	addi	a4,a4,1566 # 80020728 <bcache+0x8360>
    80003112:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    80003116:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000311a:	00015497          	auipc	s1,0x15
    8000311e:	2ce48493          	addi	s1,s1,718 # 800183e8 <bcache+0x20>
    b->next = bcache.head.next;
    80003122:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003124:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003126:	00005a17          	auipc	s4,0x5
    8000312a:	442a0a13          	addi	s4,s4,1090 # 80008568 <syscalls+0xb0>
    b->next = bcache.head.next;
    8000312e:	3b893783          	ld	a5,952(s2)
    80003132:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    80003134:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    80003138:	85d2                	mv	a1,s4
    8000313a:	01048513          	addi	a0,s1,16
    8000313e:	00001097          	auipc	ra,0x1
    80003142:	4c8080e7          	jalr	1224(ra) # 80004606 <initsleeplock>
    bcache.head.next->prev = b;
    80003146:	3b893783          	ld	a5,952(s2)
    8000314a:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    8000314c:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003150:	46048493          	addi	s1,s1,1120
    80003154:	fd349de3          	bne	s1,s3,8000312e <binit+0x54>
  }
}
    80003158:	70a2                	ld	ra,40(sp)
    8000315a:	7402                	ld	s0,32(sp)
    8000315c:	64e2                	ld	s1,24(sp)
    8000315e:	6942                	ld	s2,16(sp)
    80003160:	69a2                	ld	s3,8(sp)
    80003162:	6a02                	ld	s4,0(sp)
    80003164:	6145                	addi	sp,sp,48
    80003166:	8082                	ret

0000000080003168 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003168:	7179                	addi	sp,sp,-48
    8000316a:	f406                	sd	ra,40(sp)
    8000316c:	f022                	sd	s0,32(sp)
    8000316e:	ec26                	sd	s1,24(sp)
    80003170:	e84a                	sd	s2,16(sp)
    80003172:	e44e                	sd	s3,8(sp)
    80003174:	1800                	addi	s0,sp,48
    80003176:	892a                	mv	s2,a0
    80003178:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000317a:	00015517          	auipc	a0,0x15
    8000317e:	24e50513          	addi	a0,a0,590 # 800183c8 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	b70080e7          	jalr	-1168(ra) # 80000cf2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000318a:	0001d497          	auipc	s1,0x1d
    8000318e:	5f64b483          	ld	s1,1526(s1) # 80020780 <bcache+0x83b8>
    80003192:	0001d797          	auipc	a5,0x1d
    80003196:	59678793          	addi	a5,a5,1430 # 80020728 <bcache+0x8360>
    8000319a:	02f48f63          	beq	s1,a5,800031d8 <bread+0x70>
    8000319e:	873e                	mv	a4,a5
    800031a0:	a021                	j	800031a8 <bread+0x40>
    800031a2:	6ca4                	ld	s1,88(s1)
    800031a4:	02e48a63          	beq	s1,a4,800031d8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031a8:	449c                	lw	a5,8(s1)
    800031aa:	ff279ce3          	bne	a5,s2,800031a2 <bread+0x3a>
    800031ae:	44dc                	lw	a5,12(s1)
    800031b0:	ff3799e3          	bne	a5,s3,800031a2 <bread+0x3a>
      b->refcnt++;
    800031b4:	44bc                	lw	a5,72(s1)
    800031b6:	2785                	addiw	a5,a5,1
    800031b8:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    800031ba:	00015517          	auipc	a0,0x15
    800031be:	20e50513          	addi	a0,a0,526 # 800183c8 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	c00080e7          	jalr	-1024(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    800031ca:	01048513          	addi	a0,s1,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	472080e7          	jalr	1138(ra) # 80004640 <acquiresleep>
      return b;
    800031d6:	a8b9                	j	80003234 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d8:	0001d497          	auipc	s1,0x1d
    800031dc:	5a04b483          	ld	s1,1440(s1) # 80020778 <bcache+0x83b0>
    800031e0:	0001d797          	auipc	a5,0x1d
    800031e4:	54878793          	addi	a5,a5,1352 # 80020728 <bcache+0x8360>
    800031e8:	00f48863          	beq	s1,a5,800031f8 <bread+0x90>
    800031ec:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031ee:	44bc                	lw	a5,72(s1)
    800031f0:	cf81                	beqz	a5,80003208 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f2:	68a4                	ld	s1,80(s1)
    800031f4:	fee49de3          	bne	s1,a4,800031ee <bread+0x86>
  panic("bget: no buffers");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	37850513          	addi	a0,a0,888 # 80008570 <syscalls+0xb8>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	34c080e7          	jalr	844(ra) # 8000054c <panic>
      b->dev = dev;
    80003208:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000320c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003210:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003214:	4785                	li	a5,1
    80003216:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80003218:	00015517          	auipc	a0,0x15
    8000321c:	1b050513          	addi	a0,a0,432 # 800183c8 <bcache>
    80003220:	ffffe097          	auipc	ra,0xffffe
    80003224:	ba2080e7          	jalr	-1118(ra) # 80000dc2 <release>
      acquiresleep(&b->lock);
    80003228:	01048513          	addi	a0,s1,16
    8000322c:	00001097          	auipc	ra,0x1
    80003230:	414080e7          	jalr	1044(ra) # 80004640 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003234:	409c                	lw	a5,0(s1)
    80003236:	cb89                	beqz	a5,80003248 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003238:	8526                	mv	a0,s1
    8000323a:	70a2                	ld	ra,40(sp)
    8000323c:	7402                	ld	s0,32(sp)
    8000323e:	64e2                	ld	s1,24(sp)
    80003240:	6942                	ld	s2,16(sp)
    80003242:	69a2                	ld	s3,8(sp)
    80003244:	6145                	addi	sp,sp,48
    80003246:	8082                	ret
    virtio_disk_rw(b, 0);
    80003248:	4581                	li	a1,0
    8000324a:	8526                	mv	a0,s1
    8000324c:	00003097          	auipc	ra,0x3
    80003250:	f66080e7          	jalr	-154(ra) # 800061b2 <virtio_disk_rw>
    b->valid = 1;
    80003254:	4785                	li	a5,1
    80003256:	c09c                	sw	a5,0(s1)
  return b;
    80003258:	b7c5                	j	80003238 <bread+0xd0>

000000008000325a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003266:	0541                	addi	a0,a0,16
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	472080e7          	jalr	1138(ra) # 800046da <holdingsleep>
    80003270:	cd01                	beqz	a0,80003288 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003272:	4585                	li	a1,1
    80003274:	8526                	mv	a0,s1
    80003276:	00003097          	auipc	ra,0x3
    8000327a:	f3c080e7          	jalr	-196(ra) # 800061b2 <virtio_disk_rw>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6105                	addi	sp,sp,32
    80003286:	8082                	ret
    panic("bwrite");
    80003288:	00005517          	auipc	a0,0x5
    8000328c:	30050513          	addi	a0,a0,768 # 80008588 <syscalls+0xd0>
    80003290:	ffffd097          	auipc	ra,0xffffd
    80003294:	2bc080e7          	jalr	700(ra) # 8000054c <panic>

0000000080003298 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003298:	1101                	addi	sp,sp,-32
    8000329a:	ec06                	sd	ra,24(sp)
    8000329c:	e822                	sd	s0,16(sp)
    8000329e:	e426                	sd	s1,8(sp)
    800032a0:	e04a                	sd	s2,0(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a6:	01050913          	addi	s2,a0,16
    800032aa:	854a                	mv	a0,s2
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	42e080e7          	jalr	1070(ra) # 800046da <holdingsleep>
    800032b4:	c92d                	beqz	a0,80003326 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032b6:	854a                	mv	a0,s2
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	3de080e7          	jalr	990(ra) # 80004696 <releasesleep>

  acquire(&bcache.lock);
    800032c0:	00015517          	auipc	a0,0x15
    800032c4:	10850513          	addi	a0,a0,264 # 800183c8 <bcache>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	a2a080e7          	jalr	-1494(ra) # 80000cf2 <acquire>
  b->refcnt--;
    800032d0:	44bc                	lw	a5,72(s1)
    800032d2:	37fd                	addiw	a5,a5,-1
    800032d4:	0007871b          	sext.w	a4,a5
    800032d8:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    800032da:	eb05                	bnez	a4,8000330a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032dc:	6cbc                	ld	a5,88(s1)
    800032de:	68b8                	ld	a4,80(s1)
    800032e0:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    800032e2:	68bc                	ld	a5,80(s1)
    800032e4:	6cb8                	ld	a4,88(s1)
    800032e6:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    800032e8:	0001d797          	auipc	a5,0x1d
    800032ec:	0e078793          	addi	a5,a5,224 # 800203c8 <bcache+0x8000>
    800032f0:	3b87b703          	ld	a4,952(a5)
    800032f4:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    800032f6:	0001d717          	auipc	a4,0x1d
    800032fa:	43270713          	addi	a4,a4,1074 # 80020728 <bcache+0x8360>
    800032fe:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    80003300:	3b87b703          	ld	a4,952(a5)
    80003304:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    80003306:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    8000330a:	00015517          	auipc	a0,0x15
    8000330e:	0be50513          	addi	a0,a0,190 # 800183c8 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	ab0080e7          	jalr	-1360(ra) # 80000dc2 <release>
}
    8000331a:	60e2                	ld	ra,24(sp)
    8000331c:	6442                	ld	s0,16(sp)
    8000331e:	64a2                	ld	s1,8(sp)
    80003320:	6902                	ld	s2,0(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret
    panic("brelse");
    80003326:	00005517          	auipc	a0,0x5
    8000332a:	26a50513          	addi	a0,a0,618 # 80008590 <syscalls+0xd8>
    8000332e:	ffffd097          	auipc	ra,0xffffd
    80003332:	21e080e7          	jalr	542(ra) # 8000054c <panic>

0000000080003336 <bpin>:

void
bpin(struct buf *b) {
    80003336:	1101                	addi	sp,sp,-32
    80003338:	ec06                	sd	ra,24(sp)
    8000333a:	e822                	sd	s0,16(sp)
    8000333c:	e426                	sd	s1,8(sp)
    8000333e:	1000                	addi	s0,sp,32
    80003340:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003342:	00015517          	auipc	a0,0x15
    80003346:	08650513          	addi	a0,a0,134 # 800183c8 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	9a8080e7          	jalr	-1624(ra) # 80000cf2 <acquire>
  b->refcnt++;
    80003352:	44bc                	lw	a5,72(s1)
    80003354:	2785                	addiw	a5,a5,1
    80003356:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003358:	00015517          	auipc	a0,0x15
    8000335c:	07050513          	addi	a0,a0,112 # 800183c8 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	a62080e7          	jalr	-1438(ra) # 80000dc2 <release>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret

0000000080003372 <bunpin>:

void
bunpin(struct buf *b) {
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	00015517          	auipc	a0,0x15
    80003382:	04a50513          	addi	a0,a0,74 # 800183c8 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	96c080e7          	jalr	-1684(ra) # 80000cf2 <acquire>
  b->refcnt--;
    8000338e:	44bc                	lw	a5,72(s1)
    80003390:	37fd                	addiw	a5,a5,-1
    80003392:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003394:	00015517          	auipc	a0,0x15
    80003398:	03450513          	addi	a0,a0,52 # 800183c8 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	a26080e7          	jalr	-1498(ra) # 80000dc2 <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	e04a                	sd	s2,0(sp)
    800033b8:	1000                	addi	s0,sp,32
    800033ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033bc:	00d5d59b          	srliw	a1,a1,0xd
    800033c0:	0001d797          	auipc	a5,0x1d
    800033c4:	7e47a783          	lw	a5,2020(a5) # 80020ba4 <sb+0x1c>
    800033c8:	9dbd                	addw	a1,a1,a5
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	d9e080e7          	jalr	-610(ra) # 80003168 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033d2:	0074f713          	andi	a4,s1,7
    800033d6:	4785                	li	a5,1
    800033d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033dc:	14ce                	slli	s1,s1,0x33
    800033de:	90d9                	srli	s1,s1,0x36
    800033e0:	00950733          	add	a4,a0,s1
    800033e4:	06074703          	lbu	a4,96(a4)
    800033e8:	00e7f6b3          	and	a3,a5,a4
    800033ec:	c69d                	beqz	a3,8000341a <bfree+0x6c>
    800033ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033f0:	94aa                	add	s1,s1,a0
    800033f2:	fff7c793          	not	a5,a5
    800033f6:	8f7d                	and	a4,a4,a5
    800033f8:	06e48023          	sb	a4,96(s1)
  log_write(bp);
    800033fc:	00001097          	auipc	ra,0x1
    80003400:	11e080e7          	jalr	286(ra) # 8000451a <log_write>
  brelse(bp);
    80003404:	854a                	mv	a0,s2
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e92080e7          	jalr	-366(ra) # 80003298 <brelse>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6902                	ld	s2,0(sp)
    80003416:	6105                	addi	sp,sp,32
    80003418:	8082                	ret
    panic("freeing free block");
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	17e50513          	addi	a0,a0,382 # 80008598 <syscalls+0xe0>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	12a080e7          	jalr	298(ra) # 8000054c <panic>

000000008000342a <balloc>:
{
    8000342a:	711d                	addi	sp,sp,-96
    8000342c:	ec86                	sd	ra,88(sp)
    8000342e:	e8a2                	sd	s0,80(sp)
    80003430:	e4a6                	sd	s1,72(sp)
    80003432:	e0ca                	sd	s2,64(sp)
    80003434:	fc4e                	sd	s3,56(sp)
    80003436:	f852                	sd	s4,48(sp)
    80003438:	f456                	sd	s5,40(sp)
    8000343a:	f05a                	sd	s6,32(sp)
    8000343c:	ec5e                	sd	s7,24(sp)
    8000343e:	e862                	sd	s8,16(sp)
    80003440:	e466                	sd	s9,8(sp)
    80003442:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003444:	0001d797          	auipc	a5,0x1d
    80003448:	7487a783          	lw	a5,1864(a5) # 80020b8c <sb+0x4>
    8000344c:	cbc1                	beqz	a5,800034dc <balloc+0xb2>
    8000344e:	8baa                	mv	s7,a0
    80003450:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003452:	0001db17          	auipc	s6,0x1d
    80003456:	736b0b13          	addi	s6,s6,1846 # 80020b88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000345c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003460:	6c89                	lui	s9,0x2
    80003462:	a831                	j	8000347e <balloc+0x54>
    brelse(bp);
    80003464:	854a                	mv	a0,s2
    80003466:	00000097          	auipc	ra,0x0
    8000346a:	e32080e7          	jalr	-462(ra) # 80003298 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000346e:	015c87bb          	addw	a5,s9,s5
    80003472:	00078a9b          	sext.w	s5,a5
    80003476:	004b2703          	lw	a4,4(s6)
    8000347a:	06eaf163          	bgeu	s5,a4,800034dc <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000347e:	41fad79b          	sraiw	a5,s5,0x1f
    80003482:	0137d79b          	srliw	a5,a5,0x13
    80003486:	015787bb          	addw	a5,a5,s5
    8000348a:	40d7d79b          	sraiw	a5,a5,0xd
    8000348e:	01cb2583          	lw	a1,28(s6)
    80003492:	9dbd                	addw	a1,a1,a5
    80003494:	855e                	mv	a0,s7
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	cd2080e7          	jalr	-814(ra) # 80003168 <bread>
    8000349e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a0:	004b2503          	lw	a0,4(s6)
    800034a4:	000a849b          	sext.w	s1,s5
    800034a8:	8762                	mv	a4,s8
    800034aa:	faa4fde3          	bgeu	s1,a0,80003464 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ae:	00777693          	andi	a3,a4,7
    800034b2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034b6:	41f7579b          	sraiw	a5,a4,0x1f
    800034ba:	01d7d79b          	srliw	a5,a5,0x1d
    800034be:	9fb9                	addw	a5,a5,a4
    800034c0:	4037d79b          	sraiw	a5,a5,0x3
    800034c4:	00f90633          	add	a2,s2,a5
    800034c8:	06064603          	lbu	a2,96(a2)
    800034cc:	00c6f5b3          	and	a1,a3,a2
    800034d0:	cd91                	beqz	a1,800034ec <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d2:	2705                	addiw	a4,a4,1
    800034d4:	2485                	addiw	s1,s1,1
    800034d6:	fd471ae3          	bne	a4,s4,800034aa <balloc+0x80>
    800034da:	b769                	j	80003464 <balloc+0x3a>
  panic("balloc: out of blocks");
    800034dc:	00005517          	auipc	a0,0x5
    800034e0:	0d450513          	addi	a0,a0,212 # 800085b0 <syscalls+0xf8>
    800034e4:	ffffd097          	auipc	ra,0xffffd
    800034e8:	068080e7          	jalr	104(ra) # 8000054c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034ec:	97ca                	add	a5,a5,s2
    800034ee:	8e55                	or	a2,a2,a3
    800034f0:	06c78023          	sb	a2,96(a5)
        log_write(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	024080e7          	jalr	36(ra) # 8000451a <log_write>
        brelse(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00000097          	auipc	ra,0x0
    80003504:	d98080e7          	jalr	-616(ra) # 80003298 <brelse>
  bp = bread(dev, bno);
    80003508:	85a6                	mv	a1,s1
    8000350a:	855e                	mv	a0,s7
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	c5c080e7          	jalr	-932(ra) # 80003168 <bread>
    80003514:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003516:	40000613          	li	a2,1024
    8000351a:	4581                	li	a1,0
    8000351c:	06050513          	addi	a0,a0,96
    80003520:	ffffe097          	auipc	ra,0xffffe
    80003524:	bb2080e7          	jalr	-1102(ra) # 800010d2 <memset>
  log_write(bp);
    80003528:	854a                	mv	a0,s2
    8000352a:	00001097          	auipc	ra,0x1
    8000352e:	ff0080e7          	jalr	-16(ra) # 8000451a <log_write>
  brelse(bp);
    80003532:	854a                	mv	a0,s2
    80003534:	00000097          	auipc	ra,0x0
    80003538:	d64080e7          	jalr	-668(ra) # 80003298 <brelse>
}
    8000353c:	8526                	mv	a0,s1
    8000353e:	60e6                	ld	ra,88(sp)
    80003540:	6446                	ld	s0,80(sp)
    80003542:	64a6                	ld	s1,72(sp)
    80003544:	6906                	ld	s2,64(sp)
    80003546:	79e2                	ld	s3,56(sp)
    80003548:	7a42                	ld	s4,48(sp)
    8000354a:	7aa2                	ld	s5,40(sp)
    8000354c:	7b02                	ld	s6,32(sp)
    8000354e:	6be2                	ld	s7,24(sp)
    80003550:	6c42                	ld	s8,16(sp)
    80003552:	6ca2                	ld	s9,8(sp)
    80003554:	6125                	addi	sp,sp,96
    80003556:	8082                	ret

0000000080003558 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003558:	7179                	addi	sp,sp,-48
    8000355a:	f406                	sd	ra,40(sp)
    8000355c:	f022                	sd	s0,32(sp)
    8000355e:	ec26                	sd	s1,24(sp)
    80003560:	e84a                	sd	s2,16(sp)
    80003562:	e44e                	sd	s3,8(sp)
    80003564:	e052                	sd	s4,0(sp)
    80003566:	1800                	addi	s0,sp,48
    80003568:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000356a:	47ad                	li	a5,11
    8000356c:	04b7fe63          	bgeu	a5,a1,800035c8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003570:	ff45849b          	addiw	s1,a1,-12
    80003574:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003578:	0ff00793          	li	a5,255
    8000357c:	0ae7e463          	bltu	a5,a4,80003624 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003580:	08852583          	lw	a1,136(a0)
    80003584:	c5b5                	beqz	a1,800035f0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003586:	00092503          	lw	a0,0(s2)
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	bde080e7          	jalr	-1058(ra) # 80003168 <bread>
    80003592:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003594:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003598:	02049713          	slli	a4,s1,0x20
    8000359c:	01e75593          	srli	a1,a4,0x1e
    800035a0:	00b784b3          	add	s1,a5,a1
    800035a4:	0004a983          	lw	s3,0(s1)
    800035a8:	04098e63          	beqz	s3,80003604 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ac:	8552                	mv	a0,s4
    800035ae:	00000097          	auipc	ra,0x0
    800035b2:	cea080e7          	jalr	-790(ra) # 80003298 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035b6:	854e                	mv	a0,s3
    800035b8:	70a2                	ld	ra,40(sp)
    800035ba:	7402                	ld	s0,32(sp)
    800035bc:	64e2                	ld	s1,24(sp)
    800035be:	6942                	ld	s2,16(sp)
    800035c0:	69a2                	ld	s3,8(sp)
    800035c2:	6a02                	ld	s4,0(sp)
    800035c4:	6145                	addi	sp,sp,48
    800035c6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035c8:	02059793          	slli	a5,a1,0x20
    800035cc:	01e7d593          	srli	a1,a5,0x1e
    800035d0:	00b504b3          	add	s1,a0,a1
    800035d4:	0584a983          	lw	s3,88(s1)
    800035d8:	fc099fe3          	bnez	s3,800035b6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035dc:	4108                	lw	a0,0(a0)
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	e4c080e7          	jalr	-436(ra) # 8000342a <balloc>
    800035e6:	0005099b          	sext.w	s3,a0
    800035ea:	0534ac23          	sw	s3,88(s1)
    800035ee:	b7e1                	j	800035b6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035f0:	4108                	lw	a0,0(a0)
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	e38080e7          	jalr	-456(ra) # 8000342a <balloc>
    800035fa:	0005059b          	sext.w	a1,a0
    800035fe:	08b92423          	sw	a1,136(s2)
    80003602:	b751                	j	80003586 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003604:	00092503          	lw	a0,0(s2)
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	e22080e7          	jalr	-478(ra) # 8000342a <balloc>
    80003610:	0005099b          	sext.w	s3,a0
    80003614:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003618:	8552                	mv	a0,s4
    8000361a:	00001097          	auipc	ra,0x1
    8000361e:	f00080e7          	jalr	-256(ra) # 8000451a <log_write>
    80003622:	b769                	j	800035ac <bmap+0x54>
  panic("bmap: out of range");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	fa450513          	addi	a0,a0,-92 # 800085c8 <syscalls+0x110>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f20080e7          	jalr	-224(ra) # 8000054c <panic>

0000000080003634 <iget>:
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	e052                	sd	s4,0(sp)
    80003642:	1800                	addi	s0,sp,48
    80003644:	89aa                	mv	s3,a0
    80003646:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003648:	0001d517          	auipc	a0,0x1d
    8000364c:	56050513          	addi	a0,a0,1376 # 80020ba8 <icache>
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	6a2080e7          	jalr	1698(ra) # 80000cf2 <acquire>
  empty = 0;
    80003658:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000365a:	0001d497          	auipc	s1,0x1d
    8000365e:	56e48493          	addi	s1,s1,1390 # 80020bc8 <icache+0x20>
    80003662:	0001f697          	auipc	a3,0x1f
    80003666:	18668693          	addi	a3,a3,390 # 800227e8 <log>
    8000366a:	a039                	j	80003678 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366c:	02090b63          	beqz	s2,800036a2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003670:	09048493          	addi	s1,s1,144
    80003674:	02d48a63          	beq	s1,a3,800036a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003678:	449c                	lw	a5,8(s1)
    8000367a:	fef059e3          	blez	a5,8000366c <iget+0x38>
    8000367e:	4098                	lw	a4,0(s1)
    80003680:	ff3716e3          	bne	a4,s3,8000366c <iget+0x38>
    80003684:	40d8                	lw	a4,4(s1)
    80003686:	ff4713e3          	bne	a4,s4,8000366c <iget+0x38>
      ip->ref++;
    8000368a:	2785                	addiw	a5,a5,1
    8000368c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000368e:	0001d517          	auipc	a0,0x1d
    80003692:	51a50513          	addi	a0,a0,1306 # 80020ba8 <icache>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	72c080e7          	jalr	1836(ra) # 80000dc2 <release>
      return ip;
    8000369e:	8926                	mv	s2,s1
    800036a0:	a03d                	j	800036ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036a2:	f7f9                	bnez	a5,80003670 <iget+0x3c>
    800036a4:	8926                	mv	s2,s1
    800036a6:	b7e9                	j	80003670 <iget+0x3c>
  if(empty == 0)
    800036a8:	02090c63          	beqz	s2,800036e0 <iget+0xac>
  ip->dev = dev;
    800036ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036b4:	4785                	li	a5,1
    800036b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036ba:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800036be:	0001d517          	auipc	a0,0x1d
    800036c2:	4ea50513          	addi	a0,a0,1258 # 80020ba8 <icache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	6fc080e7          	jalr	1788(ra) # 80000dc2 <release>
}
    800036ce:	854a                	mv	a0,s2
    800036d0:	70a2                	ld	ra,40(sp)
    800036d2:	7402                	ld	s0,32(sp)
    800036d4:	64e2                	ld	s1,24(sp)
    800036d6:	6942                	ld	s2,16(sp)
    800036d8:	69a2                	ld	s3,8(sp)
    800036da:	6a02                	ld	s4,0(sp)
    800036dc:	6145                	addi	sp,sp,48
    800036de:	8082                	ret
    panic("iget: no inodes");
    800036e0:	00005517          	auipc	a0,0x5
    800036e4:	f0050513          	addi	a0,a0,-256 # 800085e0 <syscalls+0x128>
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	e64080e7          	jalr	-412(ra) # 8000054c <panic>

00000000800036f0 <fsinit>:
fsinit(int dev) {
    800036f0:	7179                	addi	sp,sp,-48
    800036f2:	f406                	sd	ra,40(sp)
    800036f4:	f022                	sd	s0,32(sp)
    800036f6:	ec26                	sd	s1,24(sp)
    800036f8:	e84a                	sd	s2,16(sp)
    800036fa:	e44e                	sd	s3,8(sp)
    800036fc:	1800                	addi	s0,sp,48
    800036fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003700:	4585                	li	a1,1
    80003702:	00000097          	auipc	ra,0x0
    80003706:	a66080e7          	jalr	-1434(ra) # 80003168 <bread>
    8000370a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000370c:	0001d997          	auipc	s3,0x1d
    80003710:	47c98993          	addi	s3,s3,1148 # 80020b88 <sb>
    80003714:	02000613          	li	a2,32
    80003718:	06050593          	addi	a1,a0,96
    8000371c:	854e                	mv	a0,s3
    8000371e:	ffffe097          	auipc	ra,0xffffe
    80003722:	a10080e7          	jalr	-1520(ra) # 8000112e <memmove>
  brelse(bp);
    80003726:	8526                	mv	a0,s1
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	b70080e7          	jalr	-1168(ra) # 80003298 <brelse>
  if(sb.magic != FSMAGIC)
    80003730:	0009a703          	lw	a4,0(s3)
    80003734:	102037b7          	lui	a5,0x10203
    80003738:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000373c:	02f71263          	bne	a4,a5,80003760 <fsinit+0x70>
  initlog(dev, &sb);
    80003740:	0001d597          	auipc	a1,0x1d
    80003744:	44858593          	addi	a1,a1,1096 # 80020b88 <sb>
    80003748:	854a                	mv	a0,s2
    8000374a:	00001097          	auipc	ra,0x1
    8000374e:	b54080e7          	jalr	-1196(ra) # 8000429e <initlog>
}
    80003752:	70a2                	ld	ra,40(sp)
    80003754:	7402                	ld	s0,32(sp)
    80003756:	64e2                	ld	s1,24(sp)
    80003758:	6942                	ld	s2,16(sp)
    8000375a:	69a2                	ld	s3,8(sp)
    8000375c:	6145                	addi	sp,sp,48
    8000375e:	8082                	ret
    panic("invalid file system");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	e9050513          	addi	a0,a0,-368 # 800085f0 <syscalls+0x138>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	de4080e7          	jalr	-540(ra) # 8000054c <panic>

0000000080003770 <iinit>:
{
    80003770:	7179                	addi	sp,sp,-48
    80003772:	f406                	sd	ra,40(sp)
    80003774:	f022                	sd	s0,32(sp)
    80003776:	ec26                	sd	s1,24(sp)
    80003778:	e84a                	sd	s2,16(sp)
    8000377a:	e44e                	sd	s3,8(sp)
    8000377c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000377e:	00005597          	auipc	a1,0x5
    80003782:	e8a58593          	addi	a1,a1,-374 # 80008608 <syscalls+0x150>
    80003786:	0001d517          	auipc	a0,0x1d
    8000378a:	42250513          	addi	a0,a0,1058 # 80020ba8 <icache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	6e0080e7          	jalr	1760(ra) # 80000e6e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003796:	0001d497          	auipc	s1,0x1d
    8000379a:	44248493          	addi	s1,s1,1090 # 80020bd8 <icache+0x30>
    8000379e:	0001f997          	auipc	s3,0x1f
    800037a2:	05a98993          	addi	s3,s3,90 # 800227f8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037a6:	00005917          	auipc	s2,0x5
    800037aa:	e6a90913          	addi	s2,s2,-406 # 80008610 <syscalls+0x158>
    800037ae:	85ca                	mv	a1,s2
    800037b0:	8526                	mv	a0,s1
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	e54080e7          	jalr	-428(ra) # 80004606 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037ba:	09048493          	addi	s1,s1,144
    800037be:	ff3498e3          	bne	s1,s3,800037ae <iinit+0x3e>
}
    800037c2:	70a2                	ld	ra,40(sp)
    800037c4:	7402                	ld	s0,32(sp)
    800037c6:	64e2                	ld	s1,24(sp)
    800037c8:	6942                	ld	s2,16(sp)
    800037ca:	69a2                	ld	s3,8(sp)
    800037cc:	6145                	addi	sp,sp,48
    800037ce:	8082                	ret

00000000800037d0 <ialloc>:
{
    800037d0:	715d                	addi	sp,sp,-80
    800037d2:	e486                	sd	ra,72(sp)
    800037d4:	e0a2                	sd	s0,64(sp)
    800037d6:	fc26                	sd	s1,56(sp)
    800037d8:	f84a                	sd	s2,48(sp)
    800037da:	f44e                	sd	s3,40(sp)
    800037dc:	f052                	sd	s4,32(sp)
    800037de:	ec56                	sd	s5,24(sp)
    800037e0:	e85a                	sd	s6,16(sp)
    800037e2:	e45e                	sd	s7,8(sp)
    800037e4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037e6:	0001d717          	auipc	a4,0x1d
    800037ea:	3ae72703          	lw	a4,942(a4) # 80020b94 <sb+0xc>
    800037ee:	4785                	li	a5,1
    800037f0:	04e7fa63          	bgeu	a5,a4,80003844 <ialloc+0x74>
    800037f4:	8aaa                	mv	s5,a0
    800037f6:	8bae                	mv	s7,a1
    800037f8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037fa:	0001da17          	auipc	s4,0x1d
    800037fe:	38ea0a13          	addi	s4,s4,910 # 80020b88 <sb>
    80003802:	00048b1b          	sext.w	s6,s1
    80003806:	0044d593          	srli	a1,s1,0x4
    8000380a:	018a2783          	lw	a5,24(s4)
    8000380e:	9dbd                	addw	a1,a1,a5
    80003810:	8556                	mv	a0,s5
    80003812:	00000097          	auipc	ra,0x0
    80003816:	956080e7          	jalr	-1706(ra) # 80003168 <bread>
    8000381a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000381c:	06050993          	addi	s3,a0,96
    80003820:	00f4f793          	andi	a5,s1,15
    80003824:	079a                	slli	a5,a5,0x6
    80003826:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003828:	00099783          	lh	a5,0(s3)
    8000382c:	c785                	beqz	a5,80003854 <ialloc+0x84>
    brelse(bp);
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	a6a080e7          	jalr	-1430(ra) # 80003298 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003836:	0485                	addi	s1,s1,1
    80003838:	00ca2703          	lw	a4,12(s4)
    8000383c:	0004879b          	sext.w	a5,s1
    80003840:	fce7e1e3          	bltu	a5,a4,80003802 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003844:	00005517          	auipc	a0,0x5
    80003848:	dd450513          	addi	a0,a0,-556 # 80008618 <syscalls+0x160>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	d00080e7          	jalr	-768(ra) # 8000054c <panic>
      memset(dip, 0, sizeof(*dip));
    80003854:	04000613          	li	a2,64
    80003858:	4581                	li	a1,0
    8000385a:	854e                	mv	a0,s3
    8000385c:	ffffe097          	auipc	ra,0xffffe
    80003860:	876080e7          	jalr	-1930(ra) # 800010d2 <memset>
      dip->type = type;
    80003864:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003868:	854a                	mv	a0,s2
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	cb0080e7          	jalr	-848(ra) # 8000451a <log_write>
      brelse(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00000097          	auipc	ra,0x0
    80003878:	a24080e7          	jalr	-1500(ra) # 80003298 <brelse>
      return iget(dev, inum);
    8000387c:	85da                	mv	a1,s6
    8000387e:	8556                	mv	a0,s5
    80003880:	00000097          	auipc	ra,0x0
    80003884:	db4080e7          	jalr	-588(ra) # 80003634 <iget>
}
    80003888:	60a6                	ld	ra,72(sp)
    8000388a:	6406                	ld	s0,64(sp)
    8000388c:	74e2                	ld	s1,56(sp)
    8000388e:	7942                	ld	s2,48(sp)
    80003890:	79a2                	ld	s3,40(sp)
    80003892:	7a02                	ld	s4,32(sp)
    80003894:	6ae2                	ld	s5,24(sp)
    80003896:	6b42                	ld	s6,16(sp)
    80003898:	6ba2                	ld	s7,8(sp)
    8000389a:	6161                	addi	sp,sp,80
    8000389c:	8082                	ret

000000008000389e <iupdate>:
{
    8000389e:	1101                	addi	sp,sp,-32
    800038a0:	ec06                	sd	ra,24(sp)
    800038a2:	e822                	sd	s0,16(sp)
    800038a4:	e426                	sd	s1,8(sp)
    800038a6:	e04a                	sd	s2,0(sp)
    800038a8:	1000                	addi	s0,sp,32
    800038aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ac:	415c                	lw	a5,4(a0)
    800038ae:	0047d79b          	srliw	a5,a5,0x4
    800038b2:	0001d597          	auipc	a1,0x1d
    800038b6:	2ee5a583          	lw	a1,750(a1) # 80020ba0 <sb+0x18>
    800038ba:	9dbd                	addw	a1,a1,a5
    800038bc:	4108                	lw	a0,0(a0)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	8aa080e7          	jalr	-1878(ra) # 80003168 <bread>
    800038c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038c8:	06050793          	addi	a5,a0,96
    800038cc:	40d8                	lw	a4,4(s1)
    800038ce:	8b3d                	andi	a4,a4,15
    800038d0:	071a                	slli	a4,a4,0x6
    800038d2:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800038d4:	04c49703          	lh	a4,76(s1)
    800038d8:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038dc:	04e49703          	lh	a4,78(s1)
    800038e0:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038e4:	05049703          	lh	a4,80(s1)
    800038e8:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038ec:	05249703          	lh	a4,82(s1)
    800038f0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038f4:	48f8                	lw	a4,84(s1)
    800038f6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038f8:	03400613          	li	a2,52
    800038fc:	05848593          	addi	a1,s1,88
    80003900:	00c78513          	addi	a0,a5,12
    80003904:	ffffe097          	auipc	ra,0xffffe
    80003908:	82a080e7          	jalr	-2006(ra) # 8000112e <memmove>
  log_write(bp);
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	c0c080e7          	jalr	-1012(ra) # 8000451a <log_write>
  brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	980080e7          	jalr	-1664(ra) # 80003298 <brelse>
}
    80003920:	60e2                	ld	ra,24(sp)
    80003922:	6442                	ld	s0,16(sp)
    80003924:	64a2                	ld	s1,8(sp)
    80003926:	6902                	ld	s2,0(sp)
    80003928:	6105                	addi	sp,sp,32
    8000392a:	8082                	ret

000000008000392c <idup>:
{
    8000392c:	1101                	addi	sp,sp,-32
    8000392e:	ec06                	sd	ra,24(sp)
    80003930:	e822                	sd	s0,16(sp)
    80003932:	e426                	sd	s1,8(sp)
    80003934:	1000                	addi	s0,sp,32
    80003936:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003938:	0001d517          	auipc	a0,0x1d
    8000393c:	27050513          	addi	a0,a0,624 # 80020ba8 <icache>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	3b2080e7          	jalr	946(ra) # 80000cf2 <acquire>
  ip->ref++;
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	2785                	addiw	a5,a5,1
    8000394c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000394e:	0001d517          	auipc	a0,0x1d
    80003952:	25a50513          	addi	a0,a0,602 # 80020ba8 <icache>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	46c080e7          	jalr	1132(ra) # 80000dc2 <release>
}
    8000395e:	8526                	mv	a0,s1
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret

000000008000396a <ilock>:
{
    8000396a:	1101                	addi	sp,sp,-32
    8000396c:	ec06                	sd	ra,24(sp)
    8000396e:	e822                	sd	s0,16(sp)
    80003970:	e426                	sd	s1,8(sp)
    80003972:	e04a                	sd	s2,0(sp)
    80003974:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003976:	c115                	beqz	a0,8000399a <ilock+0x30>
    80003978:	84aa                	mv	s1,a0
    8000397a:	451c                	lw	a5,8(a0)
    8000397c:	00f05f63          	blez	a5,8000399a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003980:	0541                	addi	a0,a0,16
    80003982:	00001097          	auipc	ra,0x1
    80003986:	cbe080e7          	jalr	-834(ra) # 80004640 <acquiresleep>
  if(ip->valid == 0){
    8000398a:	44bc                	lw	a5,72(s1)
    8000398c:	cf99                	beqz	a5,800039aa <ilock+0x40>
}
    8000398e:	60e2                	ld	ra,24(sp)
    80003990:	6442                	ld	s0,16(sp)
    80003992:	64a2                	ld	s1,8(sp)
    80003994:	6902                	ld	s2,0(sp)
    80003996:	6105                	addi	sp,sp,32
    80003998:	8082                	ret
    panic("ilock");
    8000399a:	00005517          	auipc	a0,0x5
    8000399e:	c9650513          	addi	a0,a0,-874 # 80008630 <syscalls+0x178>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	baa080e7          	jalr	-1110(ra) # 8000054c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039aa:	40dc                	lw	a5,4(s1)
    800039ac:	0047d79b          	srliw	a5,a5,0x4
    800039b0:	0001d597          	auipc	a1,0x1d
    800039b4:	1f05a583          	lw	a1,496(a1) # 80020ba0 <sb+0x18>
    800039b8:	9dbd                	addw	a1,a1,a5
    800039ba:	4088                	lw	a0,0(s1)
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	7ac080e7          	jalr	1964(ra) # 80003168 <bread>
    800039c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039c6:	06050593          	addi	a1,a0,96
    800039ca:	40dc                	lw	a5,4(s1)
    800039cc:	8bbd                	andi	a5,a5,15
    800039ce:	079a                	slli	a5,a5,0x6
    800039d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039d2:	00059783          	lh	a5,0(a1)
    800039d6:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    800039da:	00259783          	lh	a5,2(a1)
    800039de:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800039e2:	00459783          	lh	a5,4(a1)
    800039e6:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800039ea:	00659783          	lh	a5,6(a1)
    800039ee:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    800039f2:	459c                	lw	a5,8(a1)
    800039f4:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039f6:	03400613          	li	a2,52
    800039fa:	05b1                	addi	a1,a1,12
    800039fc:	05848513          	addi	a0,s1,88
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	72e080e7          	jalr	1838(ra) # 8000112e <memmove>
    brelse(bp);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	88e080e7          	jalr	-1906(ra) # 80003298 <brelse>
    ip->valid = 1;
    80003a12:	4785                	li	a5,1
    80003a14:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003a16:	04c49783          	lh	a5,76(s1)
    80003a1a:	fbb5                	bnez	a5,8000398e <ilock+0x24>
      panic("ilock: no type");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	c1c50513          	addi	a0,a0,-996 # 80008638 <syscalls+0x180>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b28080e7          	jalr	-1240(ra) # 8000054c <panic>

0000000080003a2c <iunlock>:
{
    80003a2c:	1101                	addi	sp,sp,-32
    80003a2e:	ec06                	sd	ra,24(sp)
    80003a30:	e822                	sd	s0,16(sp)
    80003a32:	e426                	sd	s1,8(sp)
    80003a34:	e04a                	sd	s2,0(sp)
    80003a36:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a38:	c905                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a3a:	84aa                	mv	s1,a0
    80003a3c:	01050913          	addi	s2,a0,16
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	c98080e7          	jalr	-872(ra) # 800046da <holdingsleep>
    80003a4a:	cd19                	beqz	a0,80003a68 <iunlock+0x3c>
    80003a4c:	449c                	lw	a5,8(s1)
    80003a4e:	00f05d63          	blez	a5,80003a68 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a52:	854a                	mv	a0,s2
    80003a54:	00001097          	auipc	ra,0x1
    80003a58:	c42080e7          	jalr	-958(ra) # 80004696 <releasesleep>
}
    80003a5c:	60e2                	ld	ra,24(sp)
    80003a5e:	6442                	ld	s0,16(sp)
    80003a60:	64a2                	ld	s1,8(sp)
    80003a62:	6902                	ld	s2,0(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret
    panic("iunlock");
    80003a68:	00005517          	auipc	a0,0x5
    80003a6c:	be050513          	addi	a0,a0,-1056 # 80008648 <syscalls+0x190>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	adc080e7          	jalr	-1316(ra) # 8000054c <panic>

0000000080003a78 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a78:	7179                	addi	sp,sp,-48
    80003a7a:	f406                	sd	ra,40(sp)
    80003a7c:	f022                	sd	s0,32(sp)
    80003a7e:	ec26                	sd	s1,24(sp)
    80003a80:	e84a                	sd	s2,16(sp)
    80003a82:	e44e                	sd	s3,8(sp)
    80003a84:	e052                	sd	s4,0(sp)
    80003a86:	1800                	addi	s0,sp,48
    80003a88:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a8a:	05850493          	addi	s1,a0,88
    80003a8e:	08850913          	addi	s2,a0,136
    80003a92:	a021                	j	80003a9a <itrunc+0x22>
    80003a94:	0491                	addi	s1,s1,4
    80003a96:	01248d63          	beq	s1,s2,80003ab0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a9a:	408c                	lw	a1,0(s1)
    80003a9c:	dde5                	beqz	a1,80003a94 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a9e:	0009a503          	lw	a0,0(s3)
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	90c080e7          	jalr	-1780(ra) # 800033ae <bfree>
      ip->addrs[i] = 0;
    80003aaa:	0004a023          	sw	zero,0(s1)
    80003aae:	b7dd                	j	80003a94 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ab0:	0889a583          	lw	a1,136(s3)
    80003ab4:	e185                	bnez	a1,80003ad4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ab6:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003aba:	854e                	mv	a0,s3
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	de2080e7          	jalr	-542(ra) # 8000389e <iupdate>
}
    80003ac4:	70a2                	ld	ra,40(sp)
    80003ac6:	7402                	ld	s0,32(sp)
    80003ac8:	64e2                	ld	s1,24(sp)
    80003aca:	6942                	ld	s2,16(sp)
    80003acc:	69a2                	ld	s3,8(sp)
    80003ace:	6a02                	ld	s4,0(sp)
    80003ad0:	6145                	addi	sp,sp,48
    80003ad2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ad4:	0009a503          	lw	a0,0(s3)
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	690080e7          	jalr	1680(ra) # 80003168 <bread>
    80003ae0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003ae2:	06050493          	addi	s1,a0,96
    80003ae6:	46050913          	addi	s2,a0,1120
    80003aea:	a021                	j	80003af2 <itrunc+0x7a>
    80003aec:	0491                	addi	s1,s1,4
    80003aee:	01248b63          	beq	s1,s2,80003b04 <itrunc+0x8c>
      if(a[j])
    80003af2:	408c                	lw	a1,0(s1)
    80003af4:	dde5                	beqz	a1,80003aec <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003af6:	0009a503          	lw	a0,0(s3)
    80003afa:	00000097          	auipc	ra,0x0
    80003afe:	8b4080e7          	jalr	-1868(ra) # 800033ae <bfree>
    80003b02:	b7ed                	j	80003aec <itrunc+0x74>
    brelse(bp);
    80003b04:	8552                	mv	a0,s4
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	792080e7          	jalr	1938(ra) # 80003298 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b0e:	0889a583          	lw	a1,136(s3)
    80003b12:	0009a503          	lw	a0,0(s3)
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	898080e7          	jalr	-1896(ra) # 800033ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b1e:	0809a423          	sw	zero,136(s3)
    80003b22:	bf51                	j	80003ab6 <itrunc+0x3e>

0000000080003b24 <iput>:
{
    80003b24:	1101                	addi	sp,sp,-32
    80003b26:	ec06                	sd	ra,24(sp)
    80003b28:	e822                	sd	s0,16(sp)
    80003b2a:	e426                	sd	s1,8(sp)
    80003b2c:	e04a                	sd	s2,0(sp)
    80003b2e:	1000                	addi	s0,sp,32
    80003b30:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b32:	0001d517          	auipc	a0,0x1d
    80003b36:	07650513          	addi	a0,a0,118 # 80020ba8 <icache>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	1b8080e7          	jalr	440(ra) # 80000cf2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b42:	4498                	lw	a4,8(s1)
    80003b44:	4785                	li	a5,1
    80003b46:	02f70363          	beq	a4,a5,80003b6c <iput+0x48>
  ip->ref--;
    80003b4a:	449c                	lw	a5,8(s1)
    80003b4c:	37fd                	addiw	a5,a5,-1
    80003b4e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b50:	0001d517          	auipc	a0,0x1d
    80003b54:	05850513          	addi	a0,a0,88 # 80020ba8 <icache>
    80003b58:	ffffd097          	auipc	ra,0xffffd
    80003b5c:	26a080e7          	jalr	618(ra) # 80000dc2 <release>
}
    80003b60:	60e2                	ld	ra,24(sp)
    80003b62:	6442                	ld	s0,16(sp)
    80003b64:	64a2                	ld	s1,8(sp)
    80003b66:	6902                	ld	s2,0(sp)
    80003b68:	6105                	addi	sp,sp,32
    80003b6a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b6c:	44bc                	lw	a5,72(s1)
    80003b6e:	dff1                	beqz	a5,80003b4a <iput+0x26>
    80003b70:	05249783          	lh	a5,82(s1)
    80003b74:	fbf9                	bnez	a5,80003b4a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b76:	01048913          	addi	s2,s1,16
    80003b7a:	854a                	mv	a0,s2
    80003b7c:	00001097          	auipc	ra,0x1
    80003b80:	ac4080e7          	jalr	-1340(ra) # 80004640 <acquiresleep>
    release(&icache.lock);
    80003b84:	0001d517          	auipc	a0,0x1d
    80003b88:	02450513          	addi	a0,a0,36 # 80020ba8 <icache>
    80003b8c:	ffffd097          	auipc	ra,0xffffd
    80003b90:	236080e7          	jalr	566(ra) # 80000dc2 <release>
    itrunc(ip);
    80003b94:	8526                	mv	a0,s1
    80003b96:	00000097          	auipc	ra,0x0
    80003b9a:	ee2080e7          	jalr	-286(ra) # 80003a78 <itrunc>
    ip->type = 0;
    80003b9e:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	00000097          	auipc	ra,0x0
    80003ba8:	cfa080e7          	jalr	-774(ra) # 8000389e <iupdate>
    ip->valid = 0;
    80003bac:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	00001097          	auipc	ra,0x1
    80003bb6:	ae4080e7          	jalr	-1308(ra) # 80004696 <releasesleep>
    acquire(&icache.lock);
    80003bba:	0001d517          	auipc	a0,0x1d
    80003bbe:	fee50513          	addi	a0,a0,-18 # 80020ba8 <icache>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	130080e7          	jalr	304(ra) # 80000cf2 <acquire>
    80003bca:	b741                	j	80003b4a <iput+0x26>

0000000080003bcc <iunlockput>:
{
    80003bcc:	1101                	addi	sp,sp,-32
    80003bce:	ec06                	sd	ra,24(sp)
    80003bd0:	e822                	sd	s0,16(sp)
    80003bd2:	e426                	sd	s1,8(sp)
    80003bd4:	1000                	addi	s0,sp,32
    80003bd6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	e54080e7          	jalr	-428(ra) # 80003a2c <iunlock>
  iput(ip);
    80003be0:	8526                	mv	a0,s1
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	f42080e7          	jalr	-190(ra) # 80003b24 <iput>
}
    80003bea:	60e2                	ld	ra,24(sp)
    80003bec:	6442                	ld	s0,16(sp)
    80003bee:	64a2                	ld	s1,8(sp)
    80003bf0:	6105                	addi	sp,sp,32
    80003bf2:	8082                	ret

0000000080003bf4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bf4:	1141                	addi	sp,sp,-16
    80003bf6:	e422                	sd	s0,8(sp)
    80003bf8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bfa:	411c                	lw	a5,0(a0)
    80003bfc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bfe:	415c                	lw	a5,4(a0)
    80003c00:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c02:	04c51783          	lh	a5,76(a0)
    80003c06:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c0a:	05251783          	lh	a5,82(a0)
    80003c0e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c12:	05456783          	lwu	a5,84(a0)
    80003c16:	e99c                	sd	a5,16(a1)
}
    80003c18:	6422                	ld	s0,8(sp)
    80003c1a:	0141                	addi	sp,sp,16
    80003c1c:	8082                	ret

0000000080003c1e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c1e:	497c                	lw	a5,84(a0)
    80003c20:	0ed7e963          	bltu	a5,a3,80003d12 <readi+0xf4>
{
    80003c24:	7159                	addi	sp,sp,-112
    80003c26:	f486                	sd	ra,104(sp)
    80003c28:	f0a2                	sd	s0,96(sp)
    80003c2a:	eca6                	sd	s1,88(sp)
    80003c2c:	e8ca                	sd	s2,80(sp)
    80003c2e:	e4ce                	sd	s3,72(sp)
    80003c30:	e0d2                	sd	s4,64(sp)
    80003c32:	fc56                	sd	s5,56(sp)
    80003c34:	f85a                	sd	s6,48(sp)
    80003c36:	f45e                	sd	s7,40(sp)
    80003c38:	f062                	sd	s8,32(sp)
    80003c3a:	ec66                	sd	s9,24(sp)
    80003c3c:	e86a                	sd	s10,16(sp)
    80003c3e:	e46e                	sd	s11,8(sp)
    80003c40:	1880                	addi	s0,sp,112
    80003c42:	8baa                	mv	s7,a0
    80003c44:	8c2e                	mv	s8,a1
    80003c46:	8ab2                	mv	s5,a2
    80003c48:	84b6                	mv	s1,a3
    80003c4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c50:	0ad76063          	bltu	a4,a3,80003cf0 <readi+0xd2>
  if(off + n > ip->size)
    80003c54:	00e7f463          	bgeu	a5,a4,80003c5c <readi+0x3e>
    n = ip->size - off;
    80003c58:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	0a0b0963          	beqz	s6,80003d0e <readi+0xf0>
    80003c60:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c62:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c66:	5cfd                	li	s9,-1
    80003c68:	a82d                	j	80003ca2 <readi+0x84>
    80003c6a:	020a1d93          	slli	s11,s4,0x20
    80003c6e:	020ddd93          	srli	s11,s11,0x20
    80003c72:	06090613          	addi	a2,s2,96
    80003c76:	86ee                	mv	a3,s11
    80003c78:	963a                	add	a2,a2,a4
    80003c7a:	85d6                	mv	a1,s5
    80003c7c:	8562                	mv	a0,s8
    80003c7e:	fffff097          	auipc	ra,0xfffff
    80003c82:	b2c080e7          	jalr	-1236(ra) # 800027aa <either_copyout>
    80003c86:	05950d63          	beq	a0,s9,80003ce0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c8a:	854a                	mv	a0,s2
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	60c080e7          	jalr	1548(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c94:	013a09bb          	addw	s3,s4,s3
    80003c98:	009a04bb          	addw	s1,s4,s1
    80003c9c:	9aee                	add	s5,s5,s11
    80003c9e:	0569f763          	bgeu	s3,s6,80003cec <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ca2:	000ba903          	lw	s2,0(s7)
    80003ca6:	00a4d59b          	srliw	a1,s1,0xa
    80003caa:	855e                	mv	a0,s7
    80003cac:	00000097          	auipc	ra,0x0
    80003cb0:	8ac080e7          	jalr	-1876(ra) # 80003558 <bmap>
    80003cb4:	0005059b          	sext.w	a1,a0
    80003cb8:	854a                	mv	a0,s2
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4ae080e7          	jalr	1198(ra) # 80003168 <bread>
    80003cc2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc4:	3ff4f713          	andi	a4,s1,1023
    80003cc8:	40ed07bb          	subw	a5,s10,a4
    80003ccc:	413b06bb          	subw	a3,s6,s3
    80003cd0:	8a3e                	mv	s4,a5
    80003cd2:	2781                	sext.w	a5,a5
    80003cd4:	0006861b          	sext.w	a2,a3
    80003cd8:	f8f679e3          	bgeu	a2,a5,80003c6a <readi+0x4c>
    80003cdc:	8a36                	mv	s4,a3
    80003cde:	b771                	j	80003c6a <readi+0x4c>
      brelse(bp);
    80003ce0:	854a                	mv	a0,s2
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	5b6080e7          	jalr	1462(ra) # 80003298 <brelse>
      tot = -1;
    80003cea:	59fd                	li	s3,-1
  }
  return tot;
    80003cec:	0009851b          	sext.w	a0,s3
}
    80003cf0:	70a6                	ld	ra,104(sp)
    80003cf2:	7406                	ld	s0,96(sp)
    80003cf4:	64e6                	ld	s1,88(sp)
    80003cf6:	6946                	ld	s2,80(sp)
    80003cf8:	69a6                	ld	s3,72(sp)
    80003cfa:	6a06                	ld	s4,64(sp)
    80003cfc:	7ae2                	ld	s5,56(sp)
    80003cfe:	7b42                	ld	s6,48(sp)
    80003d00:	7ba2                	ld	s7,40(sp)
    80003d02:	7c02                	ld	s8,32(sp)
    80003d04:	6ce2                	ld	s9,24(sp)
    80003d06:	6d42                	ld	s10,16(sp)
    80003d08:	6da2                	ld	s11,8(sp)
    80003d0a:	6165                	addi	sp,sp,112
    80003d0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0e:	89da                	mv	s3,s6
    80003d10:	bff1                	j	80003cec <readi+0xce>
    return 0;
    80003d12:	4501                	li	a0,0
}
    80003d14:	8082                	ret

0000000080003d16 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d16:	497c                	lw	a5,84(a0)
    80003d18:	10d7e763          	bltu	a5,a3,80003e26 <writei+0x110>
{
    80003d1c:	7159                	addi	sp,sp,-112
    80003d1e:	f486                	sd	ra,104(sp)
    80003d20:	f0a2                	sd	s0,96(sp)
    80003d22:	eca6                	sd	s1,88(sp)
    80003d24:	e8ca                	sd	s2,80(sp)
    80003d26:	e4ce                	sd	s3,72(sp)
    80003d28:	e0d2                	sd	s4,64(sp)
    80003d2a:	fc56                	sd	s5,56(sp)
    80003d2c:	f85a                	sd	s6,48(sp)
    80003d2e:	f45e                	sd	s7,40(sp)
    80003d30:	f062                	sd	s8,32(sp)
    80003d32:	ec66                	sd	s9,24(sp)
    80003d34:	e86a                	sd	s10,16(sp)
    80003d36:	e46e                	sd	s11,8(sp)
    80003d38:	1880                	addi	s0,sp,112
    80003d3a:	8baa                	mv	s7,a0
    80003d3c:	8c2e                	mv	s8,a1
    80003d3e:	8ab2                	mv	s5,a2
    80003d40:	8936                	mv	s2,a3
    80003d42:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d44:	00e687bb          	addw	a5,a3,a4
    80003d48:	0ed7e163          	bltu	a5,a3,80003e2a <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d4c:	00043737          	lui	a4,0x43
    80003d50:	0cf76f63          	bltu	a4,a5,80003e2e <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d54:	0a0b0863          	beqz	s6,80003e04 <writei+0xee>
    80003d58:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d5e:	5cfd                	li	s9,-1
    80003d60:	a091                	j	80003da4 <writei+0x8e>
    80003d62:	02099d93          	slli	s11,s3,0x20
    80003d66:	020ddd93          	srli	s11,s11,0x20
    80003d6a:	06048513          	addi	a0,s1,96
    80003d6e:	86ee                	mv	a3,s11
    80003d70:	8656                	mv	a2,s5
    80003d72:	85e2                	mv	a1,s8
    80003d74:	953a                	add	a0,a0,a4
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	a8a080e7          	jalr	-1398(ra) # 80002800 <either_copyin>
    80003d7e:	07950263          	beq	a0,s9,80003de2 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003d82:	8526                	mv	a0,s1
    80003d84:	00000097          	auipc	ra,0x0
    80003d88:	796080e7          	jalr	1942(ra) # 8000451a <log_write>
    brelse(bp);
    80003d8c:	8526                	mv	a0,s1
    80003d8e:	fffff097          	auipc	ra,0xfffff
    80003d92:	50a080e7          	jalr	1290(ra) # 80003298 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d96:	01498a3b          	addw	s4,s3,s4
    80003d9a:	0129893b          	addw	s2,s3,s2
    80003d9e:	9aee                	add	s5,s5,s11
    80003da0:	056a7763          	bgeu	s4,s6,80003dee <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003da4:	000ba483          	lw	s1,0(s7)
    80003da8:	00a9559b          	srliw	a1,s2,0xa
    80003dac:	855e                	mv	a0,s7
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	7aa080e7          	jalr	1962(ra) # 80003558 <bmap>
    80003db6:	0005059b          	sext.w	a1,a0
    80003dba:	8526                	mv	a0,s1
    80003dbc:	fffff097          	auipc	ra,0xfffff
    80003dc0:	3ac080e7          	jalr	940(ra) # 80003168 <bread>
    80003dc4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc6:	3ff97713          	andi	a4,s2,1023
    80003dca:	40ed07bb          	subw	a5,s10,a4
    80003dce:	414b06bb          	subw	a3,s6,s4
    80003dd2:	89be                	mv	s3,a5
    80003dd4:	2781                	sext.w	a5,a5
    80003dd6:	0006861b          	sext.w	a2,a3
    80003dda:	f8f674e3          	bgeu	a2,a5,80003d62 <writei+0x4c>
    80003dde:	89b6                	mv	s3,a3
    80003de0:	b749                	j	80003d62 <writei+0x4c>
      brelse(bp);
    80003de2:	8526                	mv	a0,s1
    80003de4:	fffff097          	auipc	ra,0xfffff
    80003de8:	4b4080e7          	jalr	1204(ra) # 80003298 <brelse>
      n = -1;
    80003dec:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003dee:	054ba783          	lw	a5,84(s7)
    80003df2:	0127f463          	bgeu	a5,s2,80003dfa <writei+0xe4>
      ip->size = off;
    80003df6:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003dfa:	855e                	mv	a0,s7
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	aa2080e7          	jalr	-1374(ra) # 8000389e <iupdate>
  }

  return n;
    80003e04:	000b051b          	sext.w	a0,s6
}
    80003e08:	70a6                	ld	ra,104(sp)
    80003e0a:	7406                	ld	s0,96(sp)
    80003e0c:	64e6                	ld	s1,88(sp)
    80003e0e:	6946                	ld	s2,80(sp)
    80003e10:	69a6                	ld	s3,72(sp)
    80003e12:	6a06                	ld	s4,64(sp)
    80003e14:	7ae2                	ld	s5,56(sp)
    80003e16:	7b42                	ld	s6,48(sp)
    80003e18:	7ba2                	ld	s7,40(sp)
    80003e1a:	7c02                	ld	s8,32(sp)
    80003e1c:	6ce2                	ld	s9,24(sp)
    80003e1e:	6d42                	ld	s10,16(sp)
    80003e20:	6da2                	ld	s11,8(sp)
    80003e22:	6165                	addi	sp,sp,112
    80003e24:	8082                	ret
    return -1;
    80003e26:	557d                	li	a0,-1
}
    80003e28:	8082                	ret
    return -1;
    80003e2a:	557d                	li	a0,-1
    80003e2c:	bff1                	j	80003e08 <writei+0xf2>
    return -1;
    80003e2e:	557d                	li	a0,-1
    80003e30:	bfe1                	j	80003e08 <writei+0xf2>

0000000080003e32 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e32:	1141                	addi	sp,sp,-16
    80003e34:	e406                	sd	ra,8(sp)
    80003e36:	e022                	sd	s0,0(sp)
    80003e38:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e3a:	4639                	li	a2,14
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	36e080e7          	jalr	878(ra) # 800011aa <strncmp>
}
    80003e44:	60a2                	ld	ra,8(sp)
    80003e46:	6402                	ld	s0,0(sp)
    80003e48:	0141                	addi	sp,sp,16
    80003e4a:	8082                	ret

0000000080003e4c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e4c:	7139                	addi	sp,sp,-64
    80003e4e:	fc06                	sd	ra,56(sp)
    80003e50:	f822                	sd	s0,48(sp)
    80003e52:	f426                	sd	s1,40(sp)
    80003e54:	f04a                	sd	s2,32(sp)
    80003e56:	ec4e                	sd	s3,24(sp)
    80003e58:	e852                	sd	s4,16(sp)
    80003e5a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e5c:	04c51703          	lh	a4,76(a0)
    80003e60:	4785                	li	a5,1
    80003e62:	00f71a63          	bne	a4,a5,80003e76 <dirlookup+0x2a>
    80003e66:	892a                	mv	s2,a0
    80003e68:	89ae                	mv	s3,a1
    80003e6a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	497c                	lw	a5,84(a0)
    80003e6e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e70:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e72:	e79d                	bnez	a5,80003ea0 <dirlookup+0x54>
    80003e74:	a8a5                	j	80003eec <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e76:	00004517          	auipc	a0,0x4
    80003e7a:	7da50513          	addi	a0,a0,2010 # 80008650 <syscalls+0x198>
    80003e7e:	ffffc097          	auipc	ra,0xffffc
    80003e82:	6ce080e7          	jalr	1742(ra) # 8000054c <panic>
      panic("dirlookup read");
    80003e86:	00004517          	auipc	a0,0x4
    80003e8a:	7e250513          	addi	a0,a0,2018 # 80008668 <syscalls+0x1b0>
    80003e8e:	ffffc097          	auipc	ra,0xffffc
    80003e92:	6be080e7          	jalr	1726(ra) # 8000054c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e96:	24c1                	addiw	s1,s1,16
    80003e98:	05492783          	lw	a5,84(s2)
    80003e9c:	04f4f763          	bgeu	s1,a5,80003eea <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea0:	4741                	li	a4,16
    80003ea2:	86a6                	mv	a3,s1
    80003ea4:	fc040613          	addi	a2,s0,-64
    80003ea8:	4581                	li	a1,0
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	d72080e7          	jalr	-654(ra) # 80003c1e <readi>
    80003eb4:	47c1                	li	a5,16
    80003eb6:	fcf518e3          	bne	a0,a5,80003e86 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eba:	fc045783          	lhu	a5,-64(s0)
    80003ebe:	dfe1                	beqz	a5,80003e96 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ec0:	fc240593          	addi	a1,s0,-62
    80003ec4:	854e                	mv	a0,s3
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	f6c080e7          	jalr	-148(ra) # 80003e32 <namecmp>
    80003ece:	f561                	bnez	a0,80003e96 <dirlookup+0x4a>
      if(poff)
    80003ed0:	000a0463          	beqz	s4,80003ed8 <dirlookup+0x8c>
        *poff = off;
    80003ed4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ed8:	fc045583          	lhu	a1,-64(s0)
    80003edc:	00092503          	lw	a0,0(s2)
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	754080e7          	jalr	1876(ra) # 80003634 <iget>
    80003ee8:	a011                	j	80003eec <dirlookup+0xa0>
  return 0;
    80003eea:	4501                	li	a0,0
}
    80003eec:	70e2                	ld	ra,56(sp)
    80003eee:	7442                	ld	s0,48(sp)
    80003ef0:	74a2                	ld	s1,40(sp)
    80003ef2:	7902                	ld	s2,32(sp)
    80003ef4:	69e2                	ld	s3,24(sp)
    80003ef6:	6a42                	ld	s4,16(sp)
    80003ef8:	6121                	addi	sp,sp,64
    80003efa:	8082                	ret

0000000080003efc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003efc:	711d                	addi	sp,sp,-96
    80003efe:	ec86                	sd	ra,88(sp)
    80003f00:	e8a2                	sd	s0,80(sp)
    80003f02:	e4a6                	sd	s1,72(sp)
    80003f04:	e0ca                	sd	s2,64(sp)
    80003f06:	fc4e                	sd	s3,56(sp)
    80003f08:	f852                	sd	s4,48(sp)
    80003f0a:	f456                	sd	s5,40(sp)
    80003f0c:	f05a                	sd	s6,32(sp)
    80003f0e:	ec5e                	sd	s7,24(sp)
    80003f10:	e862                	sd	s8,16(sp)
    80003f12:	e466                	sd	s9,8(sp)
    80003f14:	e06a                	sd	s10,0(sp)
    80003f16:	1080                	addi	s0,sp,96
    80003f18:	84aa                	mv	s1,a0
    80003f1a:	8b2e                	mv	s6,a1
    80003f1c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f1e:	00054703          	lbu	a4,0(a0)
    80003f22:	02f00793          	li	a5,47
    80003f26:	02f70363          	beq	a4,a5,80003f4c <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f2a:	ffffe097          	auipc	ra,0xffffe
    80003f2e:	e0e080e7          	jalr	-498(ra) # 80001d38 <myproc>
    80003f32:	15853503          	ld	a0,344(a0)
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	9f6080e7          	jalr	-1546(ra) # 8000392c <idup>
    80003f3e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f40:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f44:	4cb5                	li	s9,13
  len = path - s;
    80003f46:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f48:	4c05                	li	s8,1
    80003f4a:	a87d                	j	80004008 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f4c:	4585                	li	a1,1
    80003f4e:	4505                	li	a0,1
    80003f50:	fffff097          	auipc	ra,0xfffff
    80003f54:	6e4080e7          	jalr	1764(ra) # 80003634 <iget>
    80003f58:	8a2a                	mv	s4,a0
    80003f5a:	b7dd                	j	80003f40 <namex+0x44>
      iunlockput(ip);
    80003f5c:	8552                	mv	a0,s4
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	c6e080e7          	jalr	-914(ra) # 80003bcc <iunlockput>
      return 0;
    80003f66:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f68:	8552                	mv	a0,s4
    80003f6a:	60e6                	ld	ra,88(sp)
    80003f6c:	6446                	ld	s0,80(sp)
    80003f6e:	64a6                	ld	s1,72(sp)
    80003f70:	6906                	ld	s2,64(sp)
    80003f72:	79e2                	ld	s3,56(sp)
    80003f74:	7a42                	ld	s4,48(sp)
    80003f76:	7aa2                	ld	s5,40(sp)
    80003f78:	7b02                	ld	s6,32(sp)
    80003f7a:	6be2                	ld	s7,24(sp)
    80003f7c:	6c42                	ld	s8,16(sp)
    80003f7e:	6ca2                	ld	s9,8(sp)
    80003f80:	6d02                	ld	s10,0(sp)
    80003f82:	6125                	addi	sp,sp,96
    80003f84:	8082                	ret
      iunlock(ip);
    80003f86:	8552                	mv	a0,s4
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	aa4080e7          	jalr	-1372(ra) # 80003a2c <iunlock>
      return ip;
    80003f90:	bfe1                	j	80003f68 <namex+0x6c>
      iunlockput(ip);
    80003f92:	8552                	mv	a0,s4
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	c38080e7          	jalr	-968(ra) # 80003bcc <iunlockput>
      return 0;
    80003f9c:	8a4e                	mv	s4,s3
    80003f9e:	b7e9                	j	80003f68 <namex+0x6c>
  len = path - s;
    80003fa0:	40998633          	sub	a2,s3,s1
    80003fa4:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003fa8:	09acd863          	bge	s9,s10,80004038 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003fac:	4639                	li	a2,14
    80003fae:	85a6                	mv	a1,s1
    80003fb0:	8556                	mv	a0,s5
    80003fb2:	ffffd097          	auipc	ra,0xffffd
    80003fb6:	17c080e7          	jalr	380(ra) # 8000112e <memmove>
    80003fba:	84ce                	mv	s1,s3
  while(*path == '/')
    80003fbc:	0004c783          	lbu	a5,0(s1)
    80003fc0:	01279763          	bne	a5,s2,80003fce <namex+0xd2>
    path++;
    80003fc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc6:	0004c783          	lbu	a5,0(s1)
    80003fca:	ff278de3          	beq	a5,s2,80003fc4 <namex+0xc8>
    ilock(ip);
    80003fce:	8552                	mv	a0,s4
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	99a080e7          	jalr	-1638(ra) # 8000396a <ilock>
    if(ip->type != T_DIR){
    80003fd8:	04ca1783          	lh	a5,76(s4)
    80003fdc:	f98790e3          	bne	a5,s8,80003f5c <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fe0:	000b0563          	beqz	s6,80003fea <namex+0xee>
    80003fe4:	0004c783          	lbu	a5,0(s1)
    80003fe8:	dfd9                	beqz	a5,80003f86 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fea:	865e                	mv	a2,s7
    80003fec:	85d6                	mv	a1,s5
    80003fee:	8552                	mv	a0,s4
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	e5c080e7          	jalr	-420(ra) # 80003e4c <dirlookup>
    80003ff8:	89aa                	mv	s3,a0
    80003ffa:	dd41                	beqz	a0,80003f92 <namex+0x96>
    iunlockput(ip);
    80003ffc:	8552                	mv	a0,s4
    80003ffe:	00000097          	auipc	ra,0x0
    80004002:	bce080e7          	jalr	-1074(ra) # 80003bcc <iunlockput>
    ip = next;
    80004006:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004008:	0004c783          	lbu	a5,0(s1)
    8000400c:	01279763          	bne	a5,s2,8000401a <namex+0x11e>
    path++;
    80004010:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	ff278de3          	beq	a5,s2,80004010 <namex+0x114>
  if(*path == 0)
    8000401a:	cb9d                	beqz	a5,80004050 <namex+0x154>
  while(*path != '/' && *path != 0)
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	89a6                	mv	s3,s1
  len = path - s;
    80004022:	8d5e                	mv	s10,s7
    80004024:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004026:	01278963          	beq	a5,s2,80004038 <namex+0x13c>
    8000402a:	dbbd                	beqz	a5,80003fa0 <namex+0xa4>
    path++;
    8000402c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000402e:	0009c783          	lbu	a5,0(s3)
    80004032:	ff279ce3          	bne	a5,s2,8000402a <namex+0x12e>
    80004036:	b7ad                	j	80003fa0 <namex+0xa4>
    memmove(name, s, len);
    80004038:	2601                	sext.w	a2,a2
    8000403a:	85a6                	mv	a1,s1
    8000403c:	8556                	mv	a0,s5
    8000403e:	ffffd097          	auipc	ra,0xffffd
    80004042:	0f0080e7          	jalr	240(ra) # 8000112e <memmove>
    name[len] = 0;
    80004046:	9d56                	add	s10,s10,s5
    80004048:	000d0023          	sb	zero,0(s10)
    8000404c:	84ce                	mv	s1,s3
    8000404e:	b7bd                	j	80003fbc <namex+0xc0>
  if(nameiparent){
    80004050:	f00b0ce3          	beqz	s6,80003f68 <namex+0x6c>
    iput(ip);
    80004054:	8552                	mv	a0,s4
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	ace080e7          	jalr	-1330(ra) # 80003b24 <iput>
    return 0;
    8000405e:	4a01                	li	s4,0
    80004060:	b721                	j	80003f68 <namex+0x6c>

0000000080004062 <dirlink>:
{
    80004062:	7139                	addi	sp,sp,-64
    80004064:	fc06                	sd	ra,56(sp)
    80004066:	f822                	sd	s0,48(sp)
    80004068:	f426                	sd	s1,40(sp)
    8000406a:	f04a                	sd	s2,32(sp)
    8000406c:	ec4e                	sd	s3,24(sp)
    8000406e:	e852                	sd	s4,16(sp)
    80004070:	0080                	addi	s0,sp,64
    80004072:	892a                	mv	s2,a0
    80004074:	8a2e                	mv	s4,a1
    80004076:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004078:	4601                	li	a2,0
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	dd2080e7          	jalr	-558(ra) # 80003e4c <dirlookup>
    80004082:	e93d                	bnez	a0,800040f8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004084:	05492483          	lw	s1,84(s2)
    80004088:	c49d                	beqz	s1,800040b6 <dirlink+0x54>
    8000408a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000408c:	4741                	li	a4,16
    8000408e:	86a6                	mv	a3,s1
    80004090:	fc040613          	addi	a2,s0,-64
    80004094:	4581                	li	a1,0
    80004096:	854a                	mv	a0,s2
    80004098:	00000097          	auipc	ra,0x0
    8000409c:	b86080e7          	jalr	-1146(ra) # 80003c1e <readi>
    800040a0:	47c1                	li	a5,16
    800040a2:	06f51163          	bne	a0,a5,80004104 <dirlink+0xa2>
    if(de.inum == 0)
    800040a6:	fc045783          	lhu	a5,-64(s0)
    800040aa:	c791                	beqz	a5,800040b6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ac:	24c1                	addiw	s1,s1,16
    800040ae:	05492783          	lw	a5,84(s2)
    800040b2:	fcf4ede3          	bltu	s1,a5,8000408c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040b6:	4639                	li	a2,14
    800040b8:	85d2                	mv	a1,s4
    800040ba:	fc240513          	addi	a0,s0,-62
    800040be:	ffffd097          	auipc	ra,0xffffd
    800040c2:	128080e7          	jalr	296(ra) # 800011e6 <strncpy>
  de.inum = inum;
    800040c6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ca:	4741                	li	a4,16
    800040cc:	86a6                	mv	a3,s1
    800040ce:	fc040613          	addi	a2,s0,-64
    800040d2:	4581                	li	a1,0
    800040d4:	854a                	mv	a0,s2
    800040d6:	00000097          	auipc	ra,0x0
    800040da:	c40080e7          	jalr	-960(ra) # 80003d16 <writei>
    800040de:	872a                	mv	a4,a0
    800040e0:	47c1                	li	a5,16
  return 0;
    800040e2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040e4:	02f71863          	bne	a4,a5,80004114 <dirlink+0xb2>
}
    800040e8:	70e2                	ld	ra,56(sp)
    800040ea:	7442                	ld	s0,48(sp)
    800040ec:	74a2                	ld	s1,40(sp)
    800040ee:	7902                	ld	s2,32(sp)
    800040f0:	69e2                	ld	s3,24(sp)
    800040f2:	6a42                	ld	s4,16(sp)
    800040f4:	6121                	addi	sp,sp,64
    800040f6:	8082                	ret
    iput(ip);
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	a2c080e7          	jalr	-1492(ra) # 80003b24 <iput>
    return -1;
    80004100:	557d                	li	a0,-1
    80004102:	b7dd                	j	800040e8 <dirlink+0x86>
      panic("dirlink read");
    80004104:	00004517          	auipc	a0,0x4
    80004108:	57450513          	addi	a0,a0,1396 # 80008678 <syscalls+0x1c0>
    8000410c:	ffffc097          	auipc	ra,0xffffc
    80004110:	440080e7          	jalr	1088(ra) # 8000054c <panic>
    panic("dirlink");
    80004114:	00004517          	auipc	a0,0x4
    80004118:	68450513          	addi	a0,a0,1668 # 80008798 <syscalls+0x2e0>
    8000411c:	ffffc097          	auipc	ra,0xffffc
    80004120:	430080e7          	jalr	1072(ra) # 8000054c <panic>

0000000080004124 <namei>:

struct inode*
namei(char *path)
{
    80004124:	1101                	addi	sp,sp,-32
    80004126:	ec06                	sd	ra,24(sp)
    80004128:	e822                	sd	s0,16(sp)
    8000412a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000412c:	fe040613          	addi	a2,s0,-32
    80004130:	4581                	li	a1,0
    80004132:	00000097          	auipc	ra,0x0
    80004136:	dca080e7          	jalr	-566(ra) # 80003efc <namex>
}
    8000413a:	60e2                	ld	ra,24(sp)
    8000413c:	6442                	ld	s0,16(sp)
    8000413e:	6105                	addi	sp,sp,32
    80004140:	8082                	ret

0000000080004142 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004142:	1141                	addi	sp,sp,-16
    80004144:	e406                	sd	ra,8(sp)
    80004146:	e022                	sd	s0,0(sp)
    80004148:	0800                	addi	s0,sp,16
    8000414a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000414c:	4585                	li	a1,1
    8000414e:	00000097          	auipc	ra,0x0
    80004152:	dae080e7          	jalr	-594(ra) # 80003efc <namex>
}
    80004156:	60a2                	ld	ra,8(sp)
    80004158:	6402                	ld	s0,0(sp)
    8000415a:	0141                	addi	sp,sp,16
    8000415c:	8082                	ret

000000008000415e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000415e:	1101                	addi	sp,sp,-32
    80004160:	ec06                	sd	ra,24(sp)
    80004162:	e822                	sd	s0,16(sp)
    80004164:	e426                	sd	s1,8(sp)
    80004166:	e04a                	sd	s2,0(sp)
    80004168:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000416a:	0001e917          	auipc	s2,0x1e
    8000416e:	67e90913          	addi	s2,s2,1662 # 800227e8 <log>
    80004172:	02092583          	lw	a1,32(s2)
    80004176:	03092503          	lw	a0,48(s2)
    8000417a:	fffff097          	auipc	ra,0xfffff
    8000417e:	fee080e7          	jalr	-18(ra) # 80003168 <bread>
    80004182:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004184:	03492683          	lw	a3,52(s2)
    80004188:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000418a:	02d05863          	blez	a3,800041ba <write_head+0x5c>
    8000418e:	0001e797          	auipc	a5,0x1e
    80004192:	69278793          	addi	a5,a5,1682 # 80022820 <log+0x38>
    80004196:	06450713          	addi	a4,a0,100
    8000419a:	36fd                	addiw	a3,a3,-1
    8000419c:	02069613          	slli	a2,a3,0x20
    800041a0:	01e65693          	srli	a3,a2,0x1e
    800041a4:	0001e617          	auipc	a2,0x1e
    800041a8:	68060613          	addi	a2,a2,1664 # 80022824 <log+0x3c>
    800041ac:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041ae:	4390                	lw	a2,0(a5)
    800041b0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041b2:	0791                	addi	a5,a5,4
    800041b4:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800041b6:	fed79ce3          	bne	a5,a3,800041ae <write_head+0x50>
  }
  bwrite(buf);
    800041ba:	8526                	mv	a0,s1
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	09e080e7          	jalr	158(ra) # 8000325a <bwrite>
  brelse(buf);
    800041c4:	8526                	mv	a0,s1
    800041c6:	fffff097          	auipc	ra,0xfffff
    800041ca:	0d2080e7          	jalr	210(ra) # 80003298 <brelse>
}
    800041ce:	60e2                	ld	ra,24(sp)
    800041d0:	6442                	ld	s0,16(sp)
    800041d2:	64a2                	ld	s1,8(sp)
    800041d4:	6902                	ld	s2,0(sp)
    800041d6:	6105                	addi	sp,sp,32
    800041d8:	8082                	ret

00000000800041da <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041da:	0001e797          	auipc	a5,0x1e
    800041de:	6427a783          	lw	a5,1602(a5) # 8002281c <log+0x34>
    800041e2:	0af05d63          	blez	a5,8000429c <install_trans+0xc2>
{
    800041e6:	7139                	addi	sp,sp,-64
    800041e8:	fc06                	sd	ra,56(sp)
    800041ea:	f822                	sd	s0,48(sp)
    800041ec:	f426                	sd	s1,40(sp)
    800041ee:	f04a                	sd	s2,32(sp)
    800041f0:	ec4e                	sd	s3,24(sp)
    800041f2:	e852                	sd	s4,16(sp)
    800041f4:	e456                	sd	s5,8(sp)
    800041f6:	e05a                	sd	s6,0(sp)
    800041f8:	0080                	addi	s0,sp,64
    800041fa:	8b2a                	mv	s6,a0
    800041fc:	0001ea97          	auipc	s5,0x1e
    80004200:	624a8a93          	addi	s5,s5,1572 # 80022820 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004204:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004206:	0001e997          	auipc	s3,0x1e
    8000420a:	5e298993          	addi	s3,s3,1506 # 800227e8 <log>
    8000420e:	a00d                	j	80004230 <install_trans+0x56>
    brelse(lbuf);
    80004210:	854a                	mv	a0,s2
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	086080e7          	jalr	134(ra) # 80003298 <brelse>
    brelse(dbuf);
    8000421a:	8526                	mv	a0,s1
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	07c080e7          	jalr	124(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004224:	2a05                	addiw	s4,s4,1
    80004226:	0a91                	addi	s5,s5,4
    80004228:	0349a783          	lw	a5,52(s3)
    8000422c:	04fa5e63          	bge	s4,a5,80004288 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004230:	0209a583          	lw	a1,32(s3)
    80004234:	014585bb          	addw	a1,a1,s4
    80004238:	2585                	addiw	a1,a1,1
    8000423a:	0309a503          	lw	a0,48(s3)
    8000423e:	fffff097          	auipc	ra,0xfffff
    80004242:	f2a080e7          	jalr	-214(ra) # 80003168 <bread>
    80004246:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004248:	000aa583          	lw	a1,0(s5)
    8000424c:	0309a503          	lw	a0,48(s3)
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	f18080e7          	jalr	-232(ra) # 80003168 <bread>
    80004258:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000425a:	40000613          	li	a2,1024
    8000425e:	06090593          	addi	a1,s2,96
    80004262:	06050513          	addi	a0,a0,96
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	ec8080e7          	jalr	-312(ra) # 8000112e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000426e:	8526                	mv	a0,s1
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	fea080e7          	jalr	-22(ra) # 8000325a <bwrite>
    if(recovering == 0)
    80004278:	f80b1ce3          	bnez	s6,80004210 <install_trans+0x36>
      bunpin(dbuf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	0f4080e7          	jalr	244(ra) # 80003372 <bunpin>
    80004286:	b769                	j	80004210 <install_trans+0x36>
}
    80004288:	70e2                	ld	ra,56(sp)
    8000428a:	7442                	ld	s0,48(sp)
    8000428c:	74a2                	ld	s1,40(sp)
    8000428e:	7902                	ld	s2,32(sp)
    80004290:	69e2                	ld	s3,24(sp)
    80004292:	6a42                	ld	s4,16(sp)
    80004294:	6aa2                	ld	s5,8(sp)
    80004296:	6b02                	ld	s6,0(sp)
    80004298:	6121                	addi	sp,sp,64
    8000429a:	8082                	ret
    8000429c:	8082                	ret

000000008000429e <initlog>:
{
    8000429e:	7179                	addi	sp,sp,-48
    800042a0:	f406                	sd	ra,40(sp)
    800042a2:	f022                	sd	s0,32(sp)
    800042a4:	ec26                	sd	s1,24(sp)
    800042a6:	e84a                	sd	s2,16(sp)
    800042a8:	e44e                	sd	s3,8(sp)
    800042aa:	1800                	addi	s0,sp,48
    800042ac:	892a                	mv	s2,a0
    800042ae:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b0:	0001e497          	auipc	s1,0x1e
    800042b4:	53848493          	addi	s1,s1,1336 # 800227e8 <log>
    800042b8:	00004597          	auipc	a1,0x4
    800042bc:	3d058593          	addi	a1,a1,976 # 80008688 <syscalls+0x1d0>
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	bac080e7          	jalr	-1108(ra) # 80000e6e <initlock>
  log.start = sb->logstart;
    800042ca:	0149a583          	lw	a1,20(s3)
    800042ce:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800042d0:	0109a783          	lw	a5,16(s3)
    800042d4:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800042d6:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042da:	854a                	mv	a0,s2
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	e8c080e7          	jalr	-372(ra) # 80003168 <bread>
  log.lh.n = lh->n;
    800042e4:	5134                	lw	a3,96(a0)
    800042e6:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e8:	02d05663          	blez	a3,80004314 <initlog+0x76>
    800042ec:	06450793          	addi	a5,a0,100
    800042f0:	0001e717          	auipc	a4,0x1e
    800042f4:	53070713          	addi	a4,a4,1328 # 80022820 <log+0x38>
    800042f8:	36fd                	addiw	a3,a3,-1
    800042fa:	02069613          	slli	a2,a3,0x20
    800042fe:	01e65693          	srli	a3,a2,0x1e
    80004302:	06850613          	addi	a2,a0,104
    80004306:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004308:	4390                	lw	a2,0(a5)
    8000430a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000430c:	0791                	addi	a5,a5,4
    8000430e:	0711                	addi	a4,a4,4
    80004310:	fed79ce3          	bne	a5,a3,80004308 <initlog+0x6a>
  brelse(buf);
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	f84080e7          	jalr	-124(ra) # 80003298 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000431c:	4505                	li	a0,1
    8000431e:	00000097          	auipc	ra,0x0
    80004322:	ebc080e7          	jalr	-324(ra) # 800041da <install_trans>
  log.lh.n = 0;
    80004326:	0001e797          	auipc	a5,0x1e
    8000432a:	4e07ab23          	sw	zero,1270(a5) # 8002281c <log+0x34>
  write_head(); // clear the log
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	e30080e7          	jalr	-464(ra) # 8000415e <write_head>
}
    80004336:	70a2                	ld	ra,40(sp)
    80004338:	7402                	ld	s0,32(sp)
    8000433a:	64e2                	ld	s1,24(sp)
    8000433c:	6942                	ld	s2,16(sp)
    8000433e:	69a2                	ld	s3,8(sp)
    80004340:	6145                	addi	sp,sp,48
    80004342:	8082                	ret

0000000080004344 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004344:	1101                	addi	sp,sp,-32
    80004346:	ec06                	sd	ra,24(sp)
    80004348:	e822                	sd	s0,16(sp)
    8000434a:	e426                	sd	s1,8(sp)
    8000434c:	e04a                	sd	s2,0(sp)
    8000434e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004350:	0001e517          	auipc	a0,0x1e
    80004354:	49850513          	addi	a0,a0,1176 # 800227e8 <log>
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	99a080e7          	jalr	-1638(ra) # 80000cf2 <acquire>
  while(1){
    if(log.committing){
    80004360:	0001e497          	auipc	s1,0x1e
    80004364:	48848493          	addi	s1,s1,1160 # 800227e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004368:	4979                	li	s2,30
    8000436a:	a039                	j	80004378 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000436c:	85a6                	mv	a1,s1
    8000436e:	8526                	mv	a0,s1
    80004370:	ffffe097          	auipc	ra,0xffffe
    80004374:	1e0080e7          	jalr	480(ra) # 80002550 <sleep>
    if(log.committing){
    80004378:	54dc                	lw	a5,44(s1)
    8000437a:	fbed                	bnez	a5,8000436c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437c:	5498                	lw	a4,40(s1)
    8000437e:	2705                	addiw	a4,a4,1
    80004380:	0007069b          	sext.w	a3,a4
    80004384:	0027179b          	slliw	a5,a4,0x2
    80004388:	9fb9                	addw	a5,a5,a4
    8000438a:	0017979b          	slliw	a5,a5,0x1
    8000438e:	58d8                	lw	a4,52(s1)
    80004390:	9fb9                	addw	a5,a5,a4
    80004392:	00f95963          	bge	s2,a5,800043a4 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004396:	85a6                	mv	a1,s1
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffe097          	auipc	ra,0xffffe
    8000439e:	1b6080e7          	jalr	438(ra) # 80002550 <sleep>
    800043a2:	bfd9                	j	80004378 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a4:	0001e517          	auipc	a0,0x1e
    800043a8:	44450513          	addi	a0,a0,1092 # 800227e8 <log>
    800043ac:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800043ae:	ffffd097          	auipc	ra,0xffffd
    800043b2:	a14080e7          	jalr	-1516(ra) # 80000dc2 <release>
      break;
    }
  }
}
    800043b6:	60e2                	ld	ra,24(sp)
    800043b8:	6442                	ld	s0,16(sp)
    800043ba:	64a2                	ld	s1,8(sp)
    800043bc:	6902                	ld	s2,0(sp)
    800043be:	6105                	addi	sp,sp,32
    800043c0:	8082                	ret

00000000800043c2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c2:	7139                	addi	sp,sp,-64
    800043c4:	fc06                	sd	ra,56(sp)
    800043c6:	f822                	sd	s0,48(sp)
    800043c8:	f426                	sd	s1,40(sp)
    800043ca:	f04a                	sd	s2,32(sp)
    800043cc:	ec4e                	sd	s3,24(sp)
    800043ce:	e852                	sd	s4,16(sp)
    800043d0:	e456                	sd	s5,8(sp)
    800043d2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d4:	0001e497          	auipc	s1,0x1e
    800043d8:	41448493          	addi	s1,s1,1044 # 800227e8 <log>
    800043dc:	8526                	mv	a0,s1
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	914080e7          	jalr	-1772(ra) # 80000cf2 <acquire>
  log.outstanding -= 1;
    800043e6:	549c                	lw	a5,40(s1)
    800043e8:	37fd                	addiw	a5,a5,-1
    800043ea:	0007891b          	sext.w	s2,a5
    800043ee:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800043f0:	54dc                	lw	a5,44(s1)
    800043f2:	e7b9                	bnez	a5,80004440 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f4:	04091e63          	bnez	s2,80004450 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043f8:	0001e497          	auipc	s1,0x1e
    800043fc:	3f048493          	addi	s1,s1,1008 # 800227e8 <log>
    80004400:	4785                	li	a5,1
    80004402:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004404:	8526                	mv	a0,s1
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	9bc080e7          	jalr	-1604(ra) # 80000dc2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000440e:	58dc                	lw	a5,52(s1)
    80004410:	06f04763          	bgtz	a5,8000447e <end_op+0xbc>
    acquire(&log.lock);
    80004414:	0001e497          	auipc	s1,0x1e
    80004418:	3d448493          	addi	s1,s1,980 # 800227e8 <log>
    8000441c:	8526                	mv	a0,s1
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	8d4080e7          	jalr	-1836(ra) # 80000cf2 <acquire>
    log.committing = 0;
    80004426:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffe097          	auipc	ra,0xffffe
    80004430:	2a4080e7          	jalr	676(ra) # 800026d0 <wakeup>
    release(&log.lock);
    80004434:	8526                	mv	a0,s1
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	98c080e7          	jalr	-1652(ra) # 80000dc2 <release>
}
    8000443e:	a03d                	j	8000446c <end_op+0xaa>
    panic("log.committing");
    80004440:	00004517          	auipc	a0,0x4
    80004444:	25050513          	addi	a0,a0,592 # 80008690 <syscalls+0x1d8>
    80004448:	ffffc097          	auipc	ra,0xffffc
    8000444c:	104080e7          	jalr	260(ra) # 8000054c <panic>
    wakeup(&log);
    80004450:	0001e497          	auipc	s1,0x1e
    80004454:	39848493          	addi	s1,s1,920 # 800227e8 <log>
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	276080e7          	jalr	630(ra) # 800026d0 <wakeup>
  release(&log.lock);
    80004462:	8526                	mv	a0,s1
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	95e080e7          	jalr	-1698(ra) # 80000dc2 <release>
}
    8000446c:	70e2                	ld	ra,56(sp)
    8000446e:	7442                	ld	s0,48(sp)
    80004470:	74a2                	ld	s1,40(sp)
    80004472:	7902                	ld	s2,32(sp)
    80004474:	69e2                	ld	s3,24(sp)
    80004476:	6a42                	ld	s4,16(sp)
    80004478:	6aa2                	ld	s5,8(sp)
    8000447a:	6121                	addi	sp,sp,64
    8000447c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447e:	0001ea97          	auipc	s5,0x1e
    80004482:	3a2a8a93          	addi	s5,s5,930 # 80022820 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004486:	0001ea17          	auipc	s4,0x1e
    8000448a:	362a0a13          	addi	s4,s4,866 # 800227e8 <log>
    8000448e:	020a2583          	lw	a1,32(s4)
    80004492:	012585bb          	addw	a1,a1,s2
    80004496:	2585                	addiw	a1,a1,1
    80004498:	030a2503          	lw	a0,48(s4)
    8000449c:	fffff097          	auipc	ra,0xfffff
    800044a0:	ccc080e7          	jalr	-820(ra) # 80003168 <bread>
    800044a4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a6:	000aa583          	lw	a1,0(s5)
    800044aa:	030a2503          	lw	a0,48(s4)
    800044ae:	fffff097          	auipc	ra,0xfffff
    800044b2:	cba080e7          	jalr	-838(ra) # 80003168 <bread>
    800044b6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b8:	40000613          	li	a2,1024
    800044bc:	06050593          	addi	a1,a0,96
    800044c0:	06048513          	addi	a0,s1,96
    800044c4:	ffffd097          	auipc	ra,0xffffd
    800044c8:	c6a080e7          	jalr	-918(ra) # 8000112e <memmove>
    bwrite(to);  // write the log
    800044cc:	8526                	mv	a0,s1
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	d8c080e7          	jalr	-628(ra) # 8000325a <bwrite>
    brelse(from);
    800044d6:	854e                	mv	a0,s3
    800044d8:	fffff097          	auipc	ra,0xfffff
    800044dc:	dc0080e7          	jalr	-576(ra) # 80003298 <brelse>
    brelse(to);
    800044e0:	8526                	mv	a0,s1
    800044e2:	fffff097          	auipc	ra,0xfffff
    800044e6:	db6080e7          	jalr	-586(ra) # 80003298 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ea:	2905                	addiw	s2,s2,1
    800044ec:	0a91                	addi	s5,s5,4
    800044ee:	034a2783          	lw	a5,52(s4)
    800044f2:	f8f94ee3          	blt	s2,a5,8000448e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	c68080e7          	jalr	-920(ra) # 8000415e <write_head>
    install_trans(0); // Now install writes to home locations
    800044fe:	4501                	li	a0,0
    80004500:	00000097          	auipc	ra,0x0
    80004504:	cda080e7          	jalr	-806(ra) # 800041da <install_trans>
    log.lh.n = 0;
    80004508:	0001e797          	auipc	a5,0x1e
    8000450c:	3007aa23          	sw	zero,788(a5) # 8002281c <log+0x34>
    write_head();    // Erase the transaction from the log
    80004510:	00000097          	auipc	ra,0x0
    80004514:	c4e080e7          	jalr	-946(ra) # 8000415e <write_head>
    80004518:	bdf5                	j	80004414 <end_op+0x52>

000000008000451a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451a:	1101                	addi	sp,sp,-32
    8000451c:	ec06                	sd	ra,24(sp)
    8000451e:	e822                	sd	s0,16(sp)
    80004520:	e426                	sd	s1,8(sp)
    80004522:	e04a                	sd	s2,0(sp)
    80004524:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004526:	0001e717          	auipc	a4,0x1e
    8000452a:	2f672703          	lw	a4,758(a4) # 8002281c <log+0x34>
    8000452e:	47f5                	li	a5,29
    80004530:	08e7c063          	blt	a5,a4,800045b0 <log_write+0x96>
    80004534:	84aa                	mv	s1,a0
    80004536:	0001e797          	auipc	a5,0x1e
    8000453a:	2d67a783          	lw	a5,726(a5) # 8002280c <log+0x24>
    8000453e:	37fd                	addiw	a5,a5,-1
    80004540:	06f75863          	bge	a4,a5,800045b0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004544:	0001e797          	auipc	a5,0x1e
    80004548:	2cc7a783          	lw	a5,716(a5) # 80022810 <log+0x28>
    8000454c:	06f05a63          	blez	a5,800045c0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004550:	0001e917          	auipc	s2,0x1e
    80004554:	29890913          	addi	s2,s2,664 # 800227e8 <log>
    80004558:	854a                	mv	a0,s2
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	798080e7          	jalr	1944(ra) # 80000cf2 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004562:	03492603          	lw	a2,52(s2)
    80004566:	06c05563          	blez	a2,800045d0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456a:	44cc                	lw	a1,12(s1)
    8000456c:	0001e717          	auipc	a4,0x1e
    80004570:	2b470713          	addi	a4,a4,692 # 80022820 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004574:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004576:	4314                	lw	a3,0(a4)
    80004578:	04b68d63          	beq	a3,a1,800045d2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000457c:	2785                	addiw	a5,a5,1
    8000457e:	0711                	addi	a4,a4,4
    80004580:	fec79be3          	bne	a5,a2,80004576 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004584:	0631                	addi	a2,a2,12
    80004586:	060a                	slli	a2,a2,0x2
    80004588:	0001e797          	auipc	a5,0x1e
    8000458c:	26078793          	addi	a5,a5,608 # 800227e8 <log>
    80004590:	97b2                	add	a5,a5,a2
    80004592:	44d8                	lw	a4,12(s1)
    80004594:	c798                	sw	a4,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004596:	8526                	mv	a0,s1
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	d9e080e7          	jalr	-610(ra) # 80003336 <bpin>
    log.lh.n++;
    800045a0:	0001e717          	auipc	a4,0x1e
    800045a4:	24870713          	addi	a4,a4,584 # 800227e8 <log>
    800045a8:	5b5c                	lw	a5,52(a4)
    800045aa:	2785                	addiw	a5,a5,1
    800045ac:	db5c                	sw	a5,52(a4)
    800045ae:	a835                	j	800045ea <log_write+0xd0>
    panic("too big a transaction");
    800045b0:	00004517          	auipc	a0,0x4
    800045b4:	0f050513          	addi	a0,a0,240 # 800086a0 <syscalls+0x1e8>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	f94080e7          	jalr	-108(ra) # 8000054c <panic>
    panic("log_write outside of trans");
    800045c0:	00004517          	auipc	a0,0x4
    800045c4:	0f850513          	addi	a0,a0,248 # 800086b8 <syscalls+0x200>
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	f84080e7          	jalr	-124(ra) # 8000054c <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d2:	00c78693          	addi	a3,a5,12
    800045d6:	068a                	slli	a3,a3,0x2
    800045d8:	0001e717          	auipc	a4,0x1e
    800045dc:	21070713          	addi	a4,a4,528 # 800227e8 <log>
    800045e0:	9736                	add	a4,a4,a3
    800045e2:	44d4                	lw	a3,12(s1)
    800045e4:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045e6:	faf608e3          	beq	a2,a5,80004596 <log_write+0x7c>
  }
  release(&log.lock);
    800045ea:	0001e517          	auipc	a0,0x1e
    800045ee:	1fe50513          	addi	a0,a0,510 # 800227e8 <log>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	7d0080e7          	jalr	2000(ra) # 80000dc2 <release>
}
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6902                	ld	s2,0(sp)
    80004602:	6105                	addi	sp,sp,32
    80004604:	8082                	ret

0000000080004606 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004606:	1101                	addi	sp,sp,-32
    80004608:	ec06                	sd	ra,24(sp)
    8000460a:	e822                	sd	s0,16(sp)
    8000460c:	e426                	sd	s1,8(sp)
    8000460e:	e04a                	sd	s2,0(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
    80004614:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004616:	00004597          	auipc	a1,0x4
    8000461a:	0c258593          	addi	a1,a1,194 # 800086d8 <syscalls+0x220>
    8000461e:	0521                	addi	a0,a0,8
    80004620:	ffffd097          	auipc	ra,0xffffd
    80004624:	84e080e7          	jalr	-1970(ra) # 80000e6e <initlock>
  lk->name = name;
    80004628:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000462c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004630:	0204a823          	sw	zero,48(s1)
}
    80004634:	60e2                	ld	ra,24(sp)
    80004636:	6442                	ld	s0,16(sp)
    80004638:	64a2                	ld	s1,8(sp)
    8000463a:	6902                	ld	s2,0(sp)
    8000463c:	6105                	addi	sp,sp,32
    8000463e:	8082                	ret

0000000080004640 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004640:	1101                	addi	sp,sp,-32
    80004642:	ec06                	sd	ra,24(sp)
    80004644:	e822                	sd	s0,16(sp)
    80004646:	e426                	sd	s1,8(sp)
    80004648:	e04a                	sd	s2,0(sp)
    8000464a:	1000                	addi	s0,sp,32
    8000464c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000464e:	00850913          	addi	s2,a0,8
    80004652:	854a                	mv	a0,s2
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	69e080e7          	jalr	1694(ra) # 80000cf2 <acquire>
  while (lk->locked) {
    8000465c:	409c                	lw	a5,0(s1)
    8000465e:	cb89                	beqz	a5,80004670 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004660:	85ca                	mv	a1,s2
    80004662:	8526                	mv	a0,s1
    80004664:	ffffe097          	auipc	ra,0xffffe
    80004668:	eec080e7          	jalr	-276(ra) # 80002550 <sleep>
  while (lk->locked) {
    8000466c:	409c                	lw	a5,0(s1)
    8000466e:	fbed                	bnez	a5,80004660 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004670:	4785                	li	a5,1
    80004672:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004674:	ffffd097          	auipc	ra,0xffffd
    80004678:	6c4080e7          	jalr	1732(ra) # 80001d38 <myproc>
    8000467c:	413c                	lw	a5,64(a0)
    8000467e:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	740080e7          	jalr	1856(ra) # 80000dc2 <release>
}
    8000468a:	60e2                	ld	ra,24(sp)
    8000468c:	6442                	ld	s0,16(sp)
    8000468e:	64a2                	ld	s1,8(sp)
    80004690:	6902                	ld	s2,0(sp)
    80004692:	6105                	addi	sp,sp,32
    80004694:	8082                	ret

0000000080004696 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a4:	00850913          	addi	s2,a0,8
    800046a8:	854a                	mv	a0,s2
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	648080e7          	jalr	1608(ra) # 80000cf2 <acquire>
  lk->locked = 0;
    800046b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b6:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800046ba:	8526                	mv	a0,s1
    800046bc:	ffffe097          	auipc	ra,0xffffe
    800046c0:	014080e7          	jalr	20(ra) # 800026d0 <wakeup>
  release(&lk->lk);
    800046c4:	854a                	mv	a0,s2
    800046c6:	ffffc097          	auipc	ra,0xffffc
    800046ca:	6fc080e7          	jalr	1788(ra) # 80000dc2 <release>
}
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6902                	ld	s2,0(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret

00000000800046da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046da:	7179                	addi	sp,sp,-48
    800046dc:	f406                	sd	ra,40(sp)
    800046de:	f022                	sd	s0,32(sp)
    800046e0:	ec26                	sd	s1,24(sp)
    800046e2:	e84a                	sd	s2,16(sp)
    800046e4:	e44e                	sd	s3,8(sp)
    800046e6:	1800                	addi	s0,sp,48
    800046e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ea:	00850913          	addi	s2,a0,8
    800046ee:	854a                	mv	a0,s2
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	602080e7          	jalr	1538(ra) # 80000cf2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046f8:	409c                	lw	a5,0(s1)
    800046fa:	ef99                	bnez	a5,80004718 <holdingsleep+0x3e>
    800046fc:	4481                	li	s1,0
  release(&lk->lk);
    800046fe:	854a                	mv	a0,s2
    80004700:	ffffc097          	auipc	ra,0xffffc
    80004704:	6c2080e7          	jalr	1730(ra) # 80000dc2 <release>
  return r;
}
    80004708:	8526                	mv	a0,s1
    8000470a:	70a2                	ld	ra,40(sp)
    8000470c:	7402                	ld	s0,32(sp)
    8000470e:	64e2                	ld	s1,24(sp)
    80004710:	6942                	ld	s2,16(sp)
    80004712:	69a2                	ld	s3,8(sp)
    80004714:	6145                	addi	sp,sp,48
    80004716:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004718:	0304a983          	lw	s3,48(s1)
    8000471c:	ffffd097          	auipc	ra,0xffffd
    80004720:	61c080e7          	jalr	1564(ra) # 80001d38 <myproc>
    80004724:	4124                	lw	s1,64(a0)
    80004726:	413484b3          	sub	s1,s1,s3
    8000472a:	0014b493          	seqz	s1,s1
    8000472e:	bfc1                	j	800046fe <holdingsleep+0x24>

0000000080004730 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004730:	1141                	addi	sp,sp,-16
    80004732:	e406                	sd	ra,8(sp)
    80004734:	e022                	sd	s0,0(sp)
    80004736:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004738:	00004597          	auipc	a1,0x4
    8000473c:	fb058593          	addi	a1,a1,-80 # 800086e8 <syscalls+0x230>
    80004740:	0001e517          	auipc	a0,0x1e
    80004744:	1f850513          	addi	a0,a0,504 # 80022938 <ftable>
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	726080e7          	jalr	1830(ra) # 80000e6e <initlock>
}
    80004750:	60a2                	ld	ra,8(sp)
    80004752:	6402                	ld	s0,0(sp)
    80004754:	0141                	addi	sp,sp,16
    80004756:	8082                	ret

0000000080004758 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004758:	1101                	addi	sp,sp,-32
    8000475a:	ec06                	sd	ra,24(sp)
    8000475c:	e822                	sd	s0,16(sp)
    8000475e:	e426                	sd	s1,8(sp)
    80004760:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004762:	0001e517          	auipc	a0,0x1e
    80004766:	1d650513          	addi	a0,a0,470 # 80022938 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	588080e7          	jalr	1416(ra) # 80000cf2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004772:	0001e497          	auipc	s1,0x1e
    80004776:	1e648493          	addi	s1,s1,486 # 80022958 <ftable+0x20>
    8000477a:	0001f717          	auipc	a4,0x1f
    8000477e:	17e70713          	addi	a4,a4,382 # 800238f8 <ftable+0xfc0>
    if(f->ref == 0){
    80004782:	40dc                	lw	a5,4(s1)
    80004784:	cf99                	beqz	a5,800047a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004786:	02848493          	addi	s1,s1,40
    8000478a:	fee49ce3          	bne	s1,a4,80004782 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000478e:	0001e517          	auipc	a0,0x1e
    80004792:	1aa50513          	addi	a0,a0,426 # 80022938 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	62c080e7          	jalr	1580(ra) # 80000dc2 <release>
  return 0;
    8000479e:	4481                	li	s1,0
    800047a0:	a819                	j	800047b6 <filealloc+0x5e>
      f->ref = 1;
    800047a2:	4785                	li	a5,1
    800047a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047a6:	0001e517          	auipc	a0,0x1e
    800047aa:	19250513          	addi	a0,a0,402 # 80022938 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	614080e7          	jalr	1556(ra) # 80000dc2 <release>
}
    800047b6:	8526                	mv	a0,s1
    800047b8:	60e2                	ld	ra,24(sp)
    800047ba:	6442                	ld	s0,16(sp)
    800047bc:	64a2                	ld	s1,8(sp)
    800047be:	6105                	addi	sp,sp,32
    800047c0:	8082                	ret

00000000800047c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c2:	1101                	addi	sp,sp,-32
    800047c4:	ec06                	sd	ra,24(sp)
    800047c6:	e822                	sd	s0,16(sp)
    800047c8:	e426                	sd	s1,8(sp)
    800047ca:	1000                	addi	s0,sp,32
    800047cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047ce:	0001e517          	auipc	a0,0x1e
    800047d2:	16a50513          	addi	a0,a0,362 # 80022938 <ftable>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	51c080e7          	jalr	1308(ra) # 80000cf2 <acquire>
  if(f->ref < 1)
    800047de:	40dc                	lw	a5,4(s1)
    800047e0:	02f05263          	blez	a5,80004804 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e4:	2785                	addiw	a5,a5,1
    800047e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047e8:	0001e517          	auipc	a0,0x1e
    800047ec:	15050513          	addi	a0,a0,336 # 80022938 <ftable>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	5d2080e7          	jalr	1490(ra) # 80000dc2 <release>
  return f;
}
    800047f8:	8526                	mv	a0,s1
    800047fa:	60e2                	ld	ra,24(sp)
    800047fc:	6442                	ld	s0,16(sp)
    800047fe:	64a2                	ld	s1,8(sp)
    80004800:	6105                	addi	sp,sp,32
    80004802:	8082                	ret
    panic("filedup");
    80004804:	00004517          	auipc	a0,0x4
    80004808:	eec50513          	addi	a0,a0,-276 # 800086f0 <syscalls+0x238>
    8000480c:	ffffc097          	auipc	ra,0xffffc
    80004810:	d40080e7          	jalr	-704(ra) # 8000054c <panic>

0000000080004814 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004814:	7139                	addi	sp,sp,-64
    80004816:	fc06                	sd	ra,56(sp)
    80004818:	f822                	sd	s0,48(sp)
    8000481a:	f426                	sd	s1,40(sp)
    8000481c:	f04a                	sd	s2,32(sp)
    8000481e:	ec4e                	sd	s3,24(sp)
    80004820:	e852                	sd	s4,16(sp)
    80004822:	e456                	sd	s5,8(sp)
    80004824:	0080                	addi	s0,sp,64
    80004826:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004828:	0001e517          	auipc	a0,0x1e
    8000482c:	11050513          	addi	a0,a0,272 # 80022938 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	4c2080e7          	jalr	1218(ra) # 80000cf2 <acquire>
  if(f->ref < 1)
    80004838:	40dc                	lw	a5,4(s1)
    8000483a:	06f05163          	blez	a5,8000489c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000483e:	37fd                	addiw	a5,a5,-1
    80004840:	0007871b          	sext.w	a4,a5
    80004844:	c0dc                	sw	a5,4(s1)
    80004846:	06e04363          	bgtz	a4,800048ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000484a:	0004a903          	lw	s2,0(s1)
    8000484e:	0094ca83          	lbu	s5,9(s1)
    80004852:	0104ba03          	ld	s4,16(s1)
    80004856:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000485a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000485e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004862:	0001e517          	auipc	a0,0x1e
    80004866:	0d650513          	addi	a0,a0,214 # 80022938 <ftable>
    8000486a:	ffffc097          	auipc	ra,0xffffc
    8000486e:	558080e7          	jalr	1368(ra) # 80000dc2 <release>

  if(ff.type == FD_PIPE){
    80004872:	4785                	li	a5,1
    80004874:	04f90d63          	beq	s2,a5,800048ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004878:	3979                	addiw	s2,s2,-2
    8000487a:	4785                	li	a5,1
    8000487c:	0527e063          	bltu	a5,s2,800048bc <fileclose+0xa8>
    begin_op();
    80004880:	00000097          	auipc	ra,0x0
    80004884:	ac4080e7          	jalr	-1340(ra) # 80004344 <begin_op>
    iput(ff.ip);
    80004888:	854e                	mv	a0,s3
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	29a080e7          	jalr	666(ra) # 80003b24 <iput>
    end_op();
    80004892:	00000097          	auipc	ra,0x0
    80004896:	b30080e7          	jalr	-1232(ra) # 800043c2 <end_op>
    8000489a:	a00d                	j	800048bc <fileclose+0xa8>
    panic("fileclose");
    8000489c:	00004517          	auipc	a0,0x4
    800048a0:	e5c50513          	addi	a0,a0,-420 # 800086f8 <syscalls+0x240>
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	ca8080e7          	jalr	-856(ra) # 8000054c <panic>
    release(&ftable.lock);
    800048ac:	0001e517          	auipc	a0,0x1e
    800048b0:	08c50513          	addi	a0,a0,140 # 80022938 <ftable>
    800048b4:	ffffc097          	auipc	ra,0xffffc
    800048b8:	50e080e7          	jalr	1294(ra) # 80000dc2 <release>
  }
}
    800048bc:	70e2                	ld	ra,56(sp)
    800048be:	7442                	ld	s0,48(sp)
    800048c0:	74a2                	ld	s1,40(sp)
    800048c2:	7902                	ld	s2,32(sp)
    800048c4:	69e2                	ld	s3,24(sp)
    800048c6:	6a42                	ld	s4,16(sp)
    800048c8:	6aa2                	ld	s5,8(sp)
    800048ca:	6121                	addi	sp,sp,64
    800048cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048ce:	85d6                	mv	a1,s5
    800048d0:	8552                	mv	a0,s4
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	372080e7          	jalr	882(ra) # 80004c44 <pipeclose>
    800048da:	b7cd                	j	800048bc <fileclose+0xa8>

00000000800048dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048dc:	715d                	addi	sp,sp,-80
    800048de:	e486                	sd	ra,72(sp)
    800048e0:	e0a2                	sd	s0,64(sp)
    800048e2:	fc26                	sd	s1,56(sp)
    800048e4:	f84a                	sd	s2,48(sp)
    800048e6:	f44e                	sd	s3,40(sp)
    800048e8:	0880                	addi	s0,sp,80
    800048ea:	84aa                	mv	s1,a0
    800048ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048ee:	ffffd097          	auipc	ra,0xffffd
    800048f2:	44a080e7          	jalr	1098(ra) # 80001d38 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048f6:	409c                	lw	a5,0(s1)
    800048f8:	37f9                	addiw	a5,a5,-2
    800048fa:	4705                	li	a4,1
    800048fc:	04f76763          	bltu	a4,a5,8000494a <filestat+0x6e>
    80004900:	892a                	mv	s2,a0
    ilock(f->ip);
    80004902:	6c88                	ld	a0,24(s1)
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	066080e7          	jalr	102(ra) # 8000396a <ilock>
    stati(f->ip, &st);
    8000490c:	fb840593          	addi	a1,s0,-72
    80004910:	6c88                	ld	a0,24(s1)
    80004912:	fffff097          	auipc	ra,0xfffff
    80004916:	2e2080e7          	jalr	738(ra) # 80003bf4 <stati>
    iunlock(f->ip);
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	110080e7          	jalr	272(ra) # 80003a2c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004924:	46e1                	li	a3,24
    80004926:	fb840613          	addi	a2,s0,-72
    8000492a:	85ce                	mv	a1,s3
    8000492c:	05893503          	ld	a0,88(s2)
    80004930:	ffffd097          	auipc	ra,0xffffd
    80004934:	0fe080e7          	jalr	254(ra) # 80001a2e <copyout>
    80004938:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000493c:	60a6                	ld	ra,72(sp)
    8000493e:	6406                	ld	s0,64(sp)
    80004940:	74e2                	ld	s1,56(sp)
    80004942:	7942                	ld	s2,48(sp)
    80004944:	79a2                	ld	s3,40(sp)
    80004946:	6161                	addi	sp,sp,80
    80004948:	8082                	ret
  return -1;
    8000494a:	557d                	li	a0,-1
    8000494c:	bfc5                	j	8000493c <filestat+0x60>

000000008000494e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000494e:	7179                	addi	sp,sp,-48
    80004950:	f406                	sd	ra,40(sp)
    80004952:	f022                	sd	s0,32(sp)
    80004954:	ec26                	sd	s1,24(sp)
    80004956:	e84a                	sd	s2,16(sp)
    80004958:	e44e                	sd	s3,8(sp)
    8000495a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000495c:	00854783          	lbu	a5,8(a0)
    80004960:	c3d5                	beqz	a5,80004a04 <fileread+0xb6>
    80004962:	84aa                	mv	s1,a0
    80004964:	89ae                	mv	s3,a1
    80004966:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004968:	411c                	lw	a5,0(a0)
    8000496a:	4705                	li	a4,1
    8000496c:	04e78963          	beq	a5,a4,800049be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004970:	470d                	li	a4,3
    80004972:	04e78d63          	beq	a5,a4,800049cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004976:	4709                	li	a4,2
    80004978:	06e79e63          	bne	a5,a4,800049f4 <fileread+0xa6>
    ilock(f->ip);
    8000497c:	6d08                	ld	a0,24(a0)
    8000497e:	fffff097          	auipc	ra,0xfffff
    80004982:	fec080e7          	jalr	-20(ra) # 8000396a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004986:	874a                	mv	a4,s2
    80004988:	5094                	lw	a3,32(s1)
    8000498a:	864e                	mv	a2,s3
    8000498c:	4585                	li	a1,1
    8000498e:	6c88                	ld	a0,24(s1)
    80004990:	fffff097          	auipc	ra,0xfffff
    80004994:	28e080e7          	jalr	654(ra) # 80003c1e <readi>
    80004998:	892a                	mv	s2,a0
    8000499a:	00a05563          	blez	a0,800049a4 <fileread+0x56>
      f->off += r;
    8000499e:	509c                	lw	a5,32(s1)
    800049a0:	9fa9                	addw	a5,a5,a0
    800049a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a4:	6c88                	ld	a0,24(s1)
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	086080e7          	jalr	134(ra) # 80003a2c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049ae:	854a                	mv	a0,s2
    800049b0:	70a2                	ld	ra,40(sp)
    800049b2:	7402                	ld	s0,32(sp)
    800049b4:	64e2                	ld	s1,24(sp)
    800049b6:	6942                	ld	s2,16(sp)
    800049b8:	69a2                	ld	s3,8(sp)
    800049ba:	6145                	addi	sp,sp,48
    800049bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049be:	6908                	ld	a0,16(a0)
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	400080e7          	jalr	1024(ra) # 80004dc0 <piperead>
    800049c8:	892a                	mv	s2,a0
    800049ca:	b7d5                	j	800049ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049cc:	02451783          	lh	a5,36(a0)
    800049d0:	03079693          	slli	a3,a5,0x30
    800049d4:	92c1                	srli	a3,a3,0x30
    800049d6:	4725                	li	a4,9
    800049d8:	02d76863          	bltu	a4,a3,80004a08 <fileread+0xba>
    800049dc:	0792                	slli	a5,a5,0x4
    800049de:	0001e717          	auipc	a4,0x1e
    800049e2:	eba70713          	addi	a4,a4,-326 # 80022898 <devsw>
    800049e6:	97ba                	add	a5,a5,a4
    800049e8:	639c                	ld	a5,0(a5)
    800049ea:	c38d                	beqz	a5,80004a0c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ec:	4505                	li	a0,1
    800049ee:	9782                	jalr	a5
    800049f0:	892a                	mv	s2,a0
    800049f2:	bf75                	j	800049ae <fileread+0x60>
    panic("fileread");
    800049f4:	00004517          	auipc	a0,0x4
    800049f8:	d1450513          	addi	a0,a0,-748 # 80008708 <syscalls+0x250>
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	b50080e7          	jalr	-1200(ra) # 8000054c <panic>
    return -1;
    80004a04:	597d                	li	s2,-1
    80004a06:	b765                	j	800049ae <fileread+0x60>
      return -1;
    80004a08:	597d                	li	s2,-1
    80004a0a:	b755                	j	800049ae <fileread+0x60>
    80004a0c:	597d                	li	s2,-1
    80004a0e:	b745                	j	800049ae <fileread+0x60>

0000000080004a10 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a10:	00954783          	lbu	a5,9(a0)
    80004a14:	14078563          	beqz	a5,80004b5e <filewrite+0x14e>
{
    80004a18:	715d                	addi	sp,sp,-80
    80004a1a:	e486                	sd	ra,72(sp)
    80004a1c:	e0a2                	sd	s0,64(sp)
    80004a1e:	fc26                	sd	s1,56(sp)
    80004a20:	f84a                	sd	s2,48(sp)
    80004a22:	f44e                	sd	s3,40(sp)
    80004a24:	f052                	sd	s4,32(sp)
    80004a26:	ec56                	sd	s5,24(sp)
    80004a28:	e85a                	sd	s6,16(sp)
    80004a2a:	e45e                	sd	s7,8(sp)
    80004a2c:	e062                	sd	s8,0(sp)
    80004a2e:	0880                	addi	s0,sp,80
    80004a30:	892a                	mv	s2,a0
    80004a32:	8b2e                	mv	s6,a1
    80004a34:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a36:	411c                	lw	a5,0(a0)
    80004a38:	4705                	li	a4,1
    80004a3a:	02e78263          	beq	a5,a4,80004a5e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a3e:	470d                	li	a4,3
    80004a40:	02e78563          	beq	a5,a4,80004a6a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a44:	4709                	li	a4,2
    80004a46:	10e79463          	bne	a5,a4,80004b4e <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a4a:	0ec05e63          	blez	a2,80004b46 <filewrite+0x136>
    int i = 0;
    80004a4e:	4981                	li	s3,0
    80004a50:	6b85                	lui	s7,0x1
    80004a52:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a56:	6c05                	lui	s8,0x1
    80004a58:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a5c:	a851                	j	80004af0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a5e:	6908                	ld	a0,16(a0)
    80004a60:	00000097          	auipc	ra,0x0
    80004a64:	25e080e7          	jalr	606(ra) # 80004cbe <pipewrite>
    80004a68:	a85d                	j	80004b1e <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a6a:	02451783          	lh	a5,36(a0)
    80004a6e:	03079693          	slli	a3,a5,0x30
    80004a72:	92c1                	srli	a3,a3,0x30
    80004a74:	4725                	li	a4,9
    80004a76:	0ed76663          	bltu	a4,a3,80004b62 <filewrite+0x152>
    80004a7a:	0792                	slli	a5,a5,0x4
    80004a7c:	0001e717          	auipc	a4,0x1e
    80004a80:	e1c70713          	addi	a4,a4,-484 # 80022898 <devsw>
    80004a84:	97ba                	add	a5,a5,a4
    80004a86:	679c                	ld	a5,8(a5)
    80004a88:	cff9                	beqz	a5,80004b66 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a8a:	4505                	li	a0,1
    80004a8c:	9782                	jalr	a5
    80004a8e:	a841                	j	80004b1e <filewrite+0x10e>
    80004a90:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a94:	00000097          	auipc	ra,0x0
    80004a98:	8b0080e7          	jalr	-1872(ra) # 80004344 <begin_op>
      ilock(f->ip);
    80004a9c:	01893503          	ld	a0,24(s2)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	eca080e7          	jalr	-310(ra) # 8000396a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa8:	8756                	mv	a4,s5
    80004aaa:	02092683          	lw	a3,32(s2)
    80004aae:	01698633          	add	a2,s3,s6
    80004ab2:	4585                	li	a1,1
    80004ab4:	01893503          	ld	a0,24(s2)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	25e080e7          	jalr	606(ra) # 80003d16 <writei>
    80004ac0:	84aa                	mv	s1,a0
    80004ac2:	02a05f63          	blez	a0,80004b00 <filewrite+0xf0>
        f->off += r;
    80004ac6:	02092783          	lw	a5,32(s2)
    80004aca:	9fa9                	addw	a5,a5,a0
    80004acc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad0:	01893503          	ld	a0,24(s2)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	f58080e7          	jalr	-168(ra) # 80003a2c <iunlock>
      end_op();
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	8e6080e7          	jalr	-1818(ra) # 800043c2 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ae4:	049a9963          	bne	s5,s1,80004b36 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ae8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004aec:	0349d663          	bge	s3,s4,80004b18 <filewrite+0x108>
      int n1 = n - i;
    80004af0:	413a04bb          	subw	s1,s4,s3
    80004af4:	0004879b          	sext.w	a5,s1
    80004af8:	f8fbdce3          	bge	s7,a5,80004a90 <filewrite+0x80>
    80004afc:	84e2                	mv	s1,s8
    80004afe:	bf49                	j	80004a90 <filewrite+0x80>
      iunlock(f->ip);
    80004b00:	01893503          	ld	a0,24(s2)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	f28080e7          	jalr	-216(ra) # 80003a2c <iunlock>
      end_op();
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	8b6080e7          	jalr	-1866(ra) # 800043c2 <end_op>
      if(r < 0)
    80004b14:	fc04d8e3          	bgez	s1,80004ae4 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b18:	8552                	mv	a0,s4
    80004b1a:	033a1863          	bne	s4,s3,80004b4a <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b1e:	60a6                	ld	ra,72(sp)
    80004b20:	6406                	ld	s0,64(sp)
    80004b22:	74e2                	ld	s1,56(sp)
    80004b24:	7942                	ld	s2,48(sp)
    80004b26:	79a2                	ld	s3,40(sp)
    80004b28:	7a02                	ld	s4,32(sp)
    80004b2a:	6ae2                	ld	s5,24(sp)
    80004b2c:	6b42                	ld	s6,16(sp)
    80004b2e:	6ba2                	ld	s7,8(sp)
    80004b30:	6c02                	ld	s8,0(sp)
    80004b32:	6161                	addi	sp,sp,80
    80004b34:	8082                	ret
        panic("short filewrite");
    80004b36:	00004517          	auipc	a0,0x4
    80004b3a:	be250513          	addi	a0,a0,-1054 # 80008718 <syscalls+0x260>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	a0e080e7          	jalr	-1522(ra) # 8000054c <panic>
    int i = 0;
    80004b46:	4981                	li	s3,0
    80004b48:	bfc1                	j	80004b18 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b4a:	557d                	li	a0,-1
    80004b4c:	bfc9                	j	80004b1e <filewrite+0x10e>
    panic("filewrite");
    80004b4e:	00004517          	auipc	a0,0x4
    80004b52:	bda50513          	addi	a0,a0,-1062 # 80008728 <syscalls+0x270>
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	9f6080e7          	jalr	-1546(ra) # 8000054c <panic>
    return -1;
    80004b5e:	557d                	li	a0,-1
}
    80004b60:	8082                	ret
      return -1;
    80004b62:	557d                	li	a0,-1
    80004b64:	bf6d                	j	80004b1e <filewrite+0x10e>
    80004b66:	557d                	li	a0,-1
    80004b68:	bf5d                	j	80004b1e <filewrite+0x10e>

0000000080004b6a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b6a:	7179                	addi	sp,sp,-48
    80004b6c:	f406                	sd	ra,40(sp)
    80004b6e:	f022                	sd	s0,32(sp)
    80004b70:	ec26                	sd	s1,24(sp)
    80004b72:	e84a                	sd	s2,16(sp)
    80004b74:	e44e                	sd	s3,8(sp)
    80004b76:	e052                	sd	s4,0(sp)
    80004b78:	1800                	addi	s0,sp,48
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b7e:	0005b023          	sd	zero,0(a1)
    80004b82:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b86:	00000097          	auipc	ra,0x0
    80004b8a:	bd2080e7          	jalr	-1070(ra) # 80004758 <filealloc>
    80004b8e:	e088                	sd	a0,0(s1)
    80004b90:	c551                	beqz	a0,80004c1c <pipealloc+0xb2>
    80004b92:	00000097          	auipc	ra,0x0
    80004b96:	bc6080e7          	jalr	-1082(ra) # 80004758 <filealloc>
    80004b9a:	00aa3023          	sd	a0,0(s4)
    80004b9e:	c92d                	beqz	a0,80004c10 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	fc6080e7          	jalr	-58(ra) # 80000b66 <kalloc>
    80004ba8:	892a                	mv	s2,a0
    80004baa:	c125                	beqz	a0,80004c0a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bac:	4985                	li	s3,1
    80004bae:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004bb2:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004bb6:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004bba:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004bbe:	00004597          	auipc	a1,0x4
    80004bc2:	b7a58593          	addi	a1,a1,-1158 # 80008738 <syscalls+0x280>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	2a8080e7          	jalr	680(ra) # 80000e6e <initlock>
  (*f0)->type = FD_PIPE;
    80004bce:	609c                	ld	a5,0(s1)
    80004bd0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bd4:	609c                	ld	a5,0(s1)
    80004bd6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bda:	609c                	ld	a5,0(s1)
    80004bdc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004be0:	609c                	ld	a5,0(s1)
    80004be2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004be6:	000a3783          	ld	a5,0(s4)
    80004bea:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bee:	000a3783          	ld	a5,0(s4)
    80004bf2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bf6:	000a3783          	ld	a5,0(s4)
    80004bfa:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bfe:	000a3783          	ld	a5,0(s4)
    80004c02:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c06:	4501                	li	a0,0
    80004c08:	a025                	j	80004c30 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c0a:	6088                	ld	a0,0(s1)
    80004c0c:	e501                	bnez	a0,80004c14 <pipealloc+0xaa>
    80004c0e:	a039                	j	80004c1c <pipealloc+0xb2>
    80004c10:	6088                	ld	a0,0(s1)
    80004c12:	c51d                	beqz	a0,80004c40 <pipealloc+0xd6>
    fileclose(*f0);
    80004c14:	00000097          	auipc	ra,0x0
    80004c18:	c00080e7          	jalr	-1024(ra) # 80004814 <fileclose>
  if(*f1)
    80004c1c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c20:	557d                	li	a0,-1
  if(*f1)
    80004c22:	c799                	beqz	a5,80004c30 <pipealloc+0xc6>
    fileclose(*f1);
    80004c24:	853e                	mv	a0,a5
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	bee080e7          	jalr	-1042(ra) # 80004814 <fileclose>
  return -1;
    80004c2e:	557d                	li	a0,-1
}
    80004c30:	70a2                	ld	ra,40(sp)
    80004c32:	7402                	ld	s0,32(sp)
    80004c34:	64e2                	ld	s1,24(sp)
    80004c36:	6942                	ld	s2,16(sp)
    80004c38:	69a2                	ld	s3,8(sp)
    80004c3a:	6a02                	ld	s4,0(sp)
    80004c3c:	6145                	addi	sp,sp,48
    80004c3e:	8082                	ret
  return -1;
    80004c40:	557d                	li	a0,-1
    80004c42:	b7fd                	j	80004c30 <pipealloc+0xc6>

0000000080004c44 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c44:	1101                	addi	sp,sp,-32
    80004c46:	ec06                	sd	ra,24(sp)
    80004c48:	e822                	sd	s0,16(sp)
    80004c4a:	e426                	sd	s1,8(sp)
    80004c4c:	e04a                	sd	s2,0(sp)
    80004c4e:	1000                	addi	s0,sp,32
    80004c50:	84aa                	mv	s1,a0
    80004c52:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	09e080e7          	jalr	158(ra) # 80000cf2 <acquire>
  if(writable){
    80004c5c:	04090263          	beqz	s2,80004ca0 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004c60:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004c64:	22048513          	addi	a0,s1,544
    80004c68:	ffffe097          	auipc	ra,0xffffe
    80004c6c:	a68080e7          	jalr	-1432(ra) # 800026d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c70:	2284b783          	ld	a5,552(s1)
    80004c74:	ef9d                	bnez	a5,80004cb2 <pipeclose+0x6e>
    release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	14a080e7          	jalr	330(ra) # 80000dc2 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	188080e7          	jalr	392(ra) # 80000e0a <freelock>
#endif    
    kfree((char*)pi);
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	ffffc097          	auipc	ra,0xffffc
    80004c90:	d8c080e7          	jalr	-628(ra) # 80000a18 <kfree>
  } else
    release(&pi->lock);
}
    80004c94:	60e2                	ld	ra,24(sp)
    80004c96:	6442                	ld	s0,16(sp)
    80004c98:	64a2                	ld	s1,8(sp)
    80004c9a:	6902                	ld	s2,0(sp)
    80004c9c:	6105                	addi	sp,sp,32
    80004c9e:	8082                	ret
    pi->readopen = 0;
    80004ca0:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004ca4:	22448513          	addi	a0,s1,548
    80004ca8:	ffffe097          	auipc	ra,0xffffe
    80004cac:	a28080e7          	jalr	-1496(ra) # 800026d0 <wakeup>
    80004cb0:	b7c1                	j	80004c70 <pipeclose+0x2c>
    release(&pi->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	10e080e7          	jalr	270(ra) # 80000dc2 <release>
}
    80004cbc:	bfe1                	j	80004c94 <pipeclose+0x50>

0000000080004cbe <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cbe:	711d                	addi	sp,sp,-96
    80004cc0:	ec86                	sd	ra,88(sp)
    80004cc2:	e8a2                	sd	s0,80(sp)
    80004cc4:	e4a6                	sd	s1,72(sp)
    80004cc6:	e0ca                	sd	s2,64(sp)
    80004cc8:	fc4e                	sd	s3,56(sp)
    80004cca:	f852                	sd	s4,48(sp)
    80004ccc:	f456                	sd	s5,40(sp)
    80004cce:	f05a                	sd	s6,32(sp)
    80004cd0:	ec5e                	sd	s7,24(sp)
    80004cd2:	e862                	sd	s8,16(sp)
    80004cd4:	1080                	addi	s0,sp,96
    80004cd6:	84aa                	mv	s1,a0
    80004cd8:	8b2e                	mv	s6,a1
    80004cda:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	05c080e7          	jalr	92(ra) # 80001d38 <myproc>
    80004ce4:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	ffffc097          	auipc	ra,0xffffc
    80004cec:	00a080e7          	jalr	10(ra) # 80000cf2 <acquire>
  for(i = 0; i < n; i++){
    80004cf0:	09505863          	blez	s5,80004d80 <pipewrite+0xc2>
    80004cf4:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cf6:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004cfa:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cfe:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d00:	2204a783          	lw	a5,544(s1)
    80004d04:	2244a703          	lw	a4,548(s1)
    80004d08:	2007879b          	addiw	a5,a5,512
    80004d0c:	02f71b63          	bne	a4,a5,80004d42 <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d10:	2284a783          	lw	a5,552(s1)
    80004d14:	c3d9                	beqz	a5,80004d9a <pipewrite+0xdc>
    80004d16:	03892783          	lw	a5,56(s2)
    80004d1a:	e3c1                	bnez	a5,80004d9a <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004d1c:	8552                	mv	a0,s4
    80004d1e:	ffffe097          	auipc	ra,0xffffe
    80004d22:	9b2080e7          	jalr	-1614(ra) # 800026d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d26:	85a6                	mv	a1,s1
    80004d28:	854e                	mv	a0,s3
    80004d2a:	ffffe097          	auipc	ra,0xffffe
    80004d2e:	826080e7          	jalr	-2010(ra) # 80002550 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d32:	2204a783          	lw	a5,544(s1)
    80004d36:	2244a703          	lw	a4,548(s1)
    80004d3a:	2007879b          	addiw	a5,a5,512
    80004d3e:	fcf709e3          	beq	a4,a5,80004d10 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d42:	4685                	li	a3,1
    80004d44:	865a                	mv	a2,s6
    80004d46:	faf40593          	addi	a1,s0,-81
    80004d4a:	05893503          	ld	a0,88(s2)
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	d6c080e7          	jalr	-660(ra) # 80001aba <copyin>
    80004d56:	03850663          	beq	a0,s8,80004d82 <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d5a:	2244a783          	lw	a5,548(s1)
    80004d5e:	0017871b          	addiw	a4,a5,1
    80004d62:	22e4a223          	sw	a4,548(s1)
    80004d66:	1ff7f793          	andi	a5,a5,511
    80004d6a:	97a6                	add	a5,a5,s1
    80004d6c:	faf44703          	lbu	a4,-81(s0)
    80004d70:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004d74:	2b85                	addiw	s7,s7,1
    80004d76:	0b05                	addi	s6,s6,1
    80004d78:	f97a94e3          	bne	s5,s7,80004d00 <pipewrite+0x42>
    80004d7c:	8bd6                	mv	s7,s5
    80004d7e:	a011                	j	80004d82 <pipewrite+0xc4>
    80004d80:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d82:	22048513          	addi	a0,s1,544
    80004d86:	ffffe097          	auipc	ra,0xffffe
    80004d8a:	94a080e7          	jalr	-1718(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	032080e7          	jalr	50(ra) # 80000dc2 <release>
  return i;
    80004d98:	a039                	j	80004da6 <pipewrite+0xe8>
        release(&pi->lock);
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	026080e7          	jalr	38(ra) # 80000dc2 <release>
        return -1;
    80004da4:	5bfd                	li	s7,-1
}
    80004da6:	855e                	mv	a0,s7
    80004da8:	60e6                	ld	ra,88(sp)
    80004daa:	6446                	ld	s0,80(sp)
    80004dac:	64a6                	ld	s1,72(sp)
    80004dae:	6906                	ld	s2,64(sp)
    80004db0:	79e2                	ld	s3,56(sp)
    80004db2:	7a42                	ld	s4,48(sp)
    80004db4:	7aa2                	ld	s5,40(sp)
    80004db6:	7b02                	ld	s6,32(sp)
    80004db8:	6be2                	ld	s7,24(sp)
    80004dba:	6c42                	ld	s8,16(sp)
    80004dbc:	6125                	addi	sp,sp,96
    80004dbe:	8082                	ret

0000000080004dc0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dc0:	715d                	addi	sp,sp,-80
    80004dc2:	e486                	sd	ra,72(sp)
    80004dc4:	e0a2                	sd	s0,64(sp)
    80004dc6:	fc26                	sd	s1,56(sp)
    80004dc8:	f84a                	sd	s2,48(sp)
    80004dca:	f44e                	sd	s3,40(sp)
    80004dcc:	f052                	sd	s4,32(sp)
    80004dce:	ec56                	sd	s5,24(sp)
    80004dd0:	e85a                	sd	s6,16(sp)
    80004dd2:	0880                	addi	s0,sp,80
    80004dd4:	84aa                	mv	s1,a0
    80004dd6:	892e                	mv	s2,a1
    80004dd8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dda:	ffffd097          	auipc	ra,0xffffd
    80004dde:	f5e080e7          	jalr	-162(ra) # 80001d38 <myproc>
    80004de2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	f0c080e7          	jalr	-244(ra) # 80000cf2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dee:	2204a703          	lw	a4,544(s1)
    80004df2:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004df6:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dfa:	02f71463          	bne	a4,a5,80004e22 <piperead+0x62>
    80004dfe:	22c4a783          	lw	a5,556(s1)
    80004e02:	c385                	beqz	a5,80004e22 <piperead+0x62>
    if(pr->killed){
    80004e04:	038a2783          	lw	a5,56(s4)
    80004e08:	ebc9                	bnez	a5,80004e9a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e0a:	85a6                	mv	a1,s1
    80004e0c:	854e                	mv	a0,s3
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	742080e7          	jalr	1858(ra) # 80002550 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e16:	2204a703          	lw	a4,544(s1)
    80004e1a:	2244a783          	lw	a5,548(s1)
    80004e1e:	fef700e3          	beq	a4,a5,80004dfe <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e22:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e24:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e26:	05505463          	blez	s5,80004e6e <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004e2a:	2204a783          	lw	a5,544(s1)
    80004e2e:	2244a703          	lw	a4,548(s1)
    80004e32:	02f70e63          	beq	a4,a5,80004e6e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e36:	0017871b          	addiw	a4,a5,1
    80004e3a:	22e4a023          	sw	a4,544(s1)
    80004e3e:	1ff7f793          	andi	a5,a5,511
    80004e42:	97a6                	add	a5,a5,s1
    80004e44:	0207c783          	lbu	a5,32(a5)
    80004e48:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4c:	4685                	li	a3,1
    80004e4e:	fbf40613          	addi	a2,s0,-65
    80004e52:	85ca                	mv	a1,s2
    80004e54:	058a3503          	ld	a0,88(s4)
    80004e58:	ffffd097          	auipc	ra,0xffffd
    80004e5c:	bd6080e7          	jalr	-1066(ra) # 80001a2e <copyout>
    80004e60:	01650763          	beq	a0,s6,80004e6e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e64:	2985                	addiw	s3,s3,1
    80004e66:	0905                	addi	s2,s2,1
    80004e68:	fd3a91e3          	bne	s5,s3,80004e2a <piperead+0x6a>
    80004e6c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e6e:	22448513          	addi	a0,s1,548
    80004e72:	ffffe097          	auipc	ra,0xffffe
    80004e76:	85e080e7          	jalr	-1954(ra) # 800026d0 <wakeup>
  release(&pi->lock);
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	f46080e7          	jalr	-186(ra) # 80000dc2 <release>
  return i;
}
    80004e84:	854e                	mv	a0,s3
    80004e86:	60a6                	ld	ra,72(sp)
    80004e88:	6406                	ld	s0,64(sp)
    80004e8a:	74e2                	ld	s1,56(sp)
    80004e8c:	7942                	ld	s2,48(sp)
    80004e8e:	79a2                	ld	s3,40(sp)
    80004e90:	7a02                	ld	s4,32(sp)
    80004e92:	6ae2                	ld	s5,24(sp)
    80004e94:	6b42                	ld	s6,16(sp)
    80004e96:	6161                	addi	sp,sp,80
    80004e98:	8082                	ret
      release(&pi->lock);
    80004e9a:	8526                	mv	a0,s1
    80004e9c:	ffffc097          	auipc	ra,0xffffc
    80004ea0:	f26080e7          	jalr	-218(ra) # 80000dc2 <release>
      return -1;
    80004ea4:	59fd                	li	s3,-1
    80004ea6:	bff9                	j	80004e84 <piperead+0xc4>

0000000080004ea8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ea8:	de010113          	addi	sp,sp,-544
    80004eac:	20113c23          	sd	ra,536(sp)
    80004eb0:	20813823          	sd	s0,528(sp)
    80004eb4:	20913423          	sd	s1,520(sp)
    80004eb8:	21213023          	sd	s2,512(sp)
    80004ebc:	ffce                	sd	s3,504(sp)
    80004ebe:	fbd2                	sd	s4,496(sp)
    80004ec0:	f7d6                	sd	s5,488(sp)
    80004ec2:	f3da                	sd	s6,480(sp)
    80004ec4:	efde                	sd	s7,472(sp)
    80004ec6:	ebe2                	sd	s8,464(sp)
    80004ec8:	e7e6                	sd	s9,456(sp)
    80004eca:	e3ea                	sd	s10,448(sp)
    80004ecc:	ff6e                	sd	s11,440(sp)
    80004ece:	1400                	addi	s0,sp,544
    80004ed0:	892a                	mv	s2,a0
    80004ed2:	dea43423          	sd	a0,-536(s0)
    80004ed6:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004eda:	ffffd097          	auipc	ra,0xffffd
    80004ede:	e5e080e7          	jalr	-418(ra) # 80001d38 <myproc>
    80004ee2:	84aa                	mv	s1,a0

  begin_op();
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	460080e7          	jalr	1120(ra) # 80004344 <begin_op>

  if((ip = namei(path)) == 0){
    80004eec:	854a                	mv	a0,s2
    80004eee:	fffff097          	auipc	ra,0xfffff
    80004ef2:	236080e7          	jalr	566(ra) # 80004124 <namei>
    80004ef6:	c93d                	beqz	a0,80004f6c <exec+0xc4>
    80004ef8:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	a70080e7          	jalr	-1424(ra) # 8000396a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f02:	04000713          	li	a4,64
    80004f06:	4681                	li	a3,0
    80004f08:	e4840613          	addi	a2,s0,-440
    80004f0c:	4581                	li	a1,0
    80004f0e:	8556                	mv	a0,s5
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	d0e080e7          	jalr	-754(ra) # 80003c1e <readi>
    80004f18:	04000793          	li	a5,64
    80004f1c:	00f51a63          	bne	a0,a5,80004f30 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f20:	e4842703          	lw	a4,-440(s0)
    80004f24:	464c47b7          	lui	a5,0x464c4
    80004f28:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f2c:	04f70663          	beq	a4,a5,80004f78 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f30:	8556                	mv	a0,s5
    80004f32:	fffff097          	auipc	ra,0xfffff
    80004f36:	c9a080e7          	jalr	-870(ra) # 80003bcc <iunlockput>
    end_op();
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	488080e7          	jalr	1160(ra) # 800043c2 <end_op>
  }
  return -1;
    80004f42:	557d                	li	a0,-1
}
    80004f44:	21813083          	ld	ra,536(sp)
    80004f48:	21013403          	ld	s0,528(sp)
    80004f4c:	20813483          	ld	s1,520(sp)
    80004f50:	20013903          	ld	s2,512(sp)
    80004f54:	79fe                	ld	s3,504(sp)
    80004f56:	7a5e                	ld	s4,496(sp)
    80004f58:	7abe                	ld	s5,488(sp)
    80004f5a:	7b1e                	ld	s6,480(sp)
    80004f5c:	6bfe                	ld	s7,472(sp)
    80004f5e:	6c5e                	ld	s8,464(sp)
    80004f60:	6cbe                	ld	s9,456(sp)
    80004f62:	6d1e                	ld	s10,448(sp)
    80004f64:	7dfa                	ld	s11,440(sp)
    80004f66:	22010113          	addi	sp,sp,544
    80004f6a:	8082                	ret
    end_op();
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	456080e7          	jalr	1110(ra) # 800043c2 <end_op>
    return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	b7f9                	j	80004f44 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f78:	8526                	mv	a0,s1
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	e82080e7          	jalr	-382(ra) # 80001dfc <proc_pagetable>
    80004f82:	8b2a                	mv	s6,a0
    80004f84:	d555                	beqz	a0,80004f30 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f86:	e6842783          	lw	a5,-408(s0)
    80004f8a:	e8045703          	lhu	a4,-384(s0)
    80004f8e:	c735                	beqz	a4,80004ffa <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f90:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f92:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f96:	6a05                	lui	s4,0x1
    80004f98:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f9c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004fa0:	6d85                	lui	s11,0x1
    80004fa2:	7d7d                	lui	s10,0xfffff
    80004fa4:	ac1d                	j	800051da <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fa6:	00003517          	auipc	a0,0x3
    80004faa:	79a50513          	addi	a0,a0,1946 # 80008740 <syscalls+0x288>
    80004fae:	ffffb097          	auipc	ra,0xffffb
    80004fb2:	59e080e7          	jalr	1438(ra) # 8000054c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fb6:	874a                	mv	a4,s2
    80004fb8:	009c86bb          	addw	a3,s9,s1
    80004fbc:	4581                	li	a1,0
    80004fbe:	8556                	mv	a0,s5
    80004fc0:	fffff097          	auipc	ra,0xfffff
    80004fc4:	c5e080e7          	jalr	-930(ra) # 80003c1e <readi>
    80004fc8:	2501                	sext.w	a0,a0
    80004fca:	1aa91863          	bne	s2,a0,8000517a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fce:	009d84bb          	addw	s1,s11,s1
    80004fd2:	013d09bb          	addw	s3,s10,s3
    80004fd6:	1f74f263          	bgeu	s1,s7,800051ba <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fda:	02049593          	slli	a1,s1,0x20
    80004fde:	9181                	srli	a1,a1,0x20
    80004fe0:	95e2                	add	a1,a1,s8
    80004fe2:	855a                	mv	a0,s6
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	484080e7          	jalr	1156(ra) # 80001468 <walkaddr>
    80004fec:	862a                	mv	a2,a0
    if(pa == 0)
    80004fee:	dd45                	beqz	a0,80004fa6 <exec+0xfe>
      n = PGSIZE;
    80004ff0:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ff2:	fd49f2e3          	bgeu	s3,s4,80004fb6 <exec+0x10e>
      n = sz - i;
    80004ff6:	894e                	mv	s2,s3
    80004ff8:	bf7d                	j	80004fb6 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ffa:	4481                	li	s1,0
  iunlockput(ip);
    80004ffc:	8556                	mv	a0,s5
    80004ffe:	fffff097          	auipc	ra,0xfffff
    80005002:	bce080e7          	jalr	-1074(ra) # 80003bcc <iunlockput>
  end_op();
    80005006:	fffff097          	auipc	ra,0xfffff
    8000500a:	3bc080e7          	jalr	956(ra) # 800043c2 <end_op>
  p = myproc();
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	d2a080e7          	jalr	-726(ra) # 80001d38 <myproc>
    80005016:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005018:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000501c:	6785                	lui	a5,0x1
    8000501e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005020:	97a6                	add	a5,a5,s1
    80005022:	777d                	lui	a4,0xfffff
    80005024:	8ff9                	and	a5,a5,a4
    80005026:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000502a:	6609                	lui	a2,0x2
    8000502c:	963e                	add	a2,a2,a5
    8000502e:	85be                	mv	a1,a5
    80005030:	855a                	mv	a0,s6
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	7a8080e7          	jalr	1960(ra) # 800017da <uvmalloc>
    8000503a:	8c2a                	mv	s8,a0
  ip = 0;
    8000503c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000503e:	12050e63          	beqz	a0,8000517a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005042:	75f9                	lui	a1,0xffffe
    80005044:	95aa                	add	a1,a1,a0
    80005046:	855a                	mv	a0,s6
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	9b4080e7          	jalr	-1612(ra) # 800019fc <uvmclear>
  stackbase = sp - PGSIZE;
    80005050:	7afd                	lui	s5,0xfffff
    80005052:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005054:	df043783          	ld	a5,-528(s0)
    80005058:	6388                	ld	a0,0(a5)
    8000505a:	c925                	beqz	a0,800050ca <exec+0x222>
    8000505c:	e8840993          	addi	s3,s0,-376
    80005060:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005064:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005066:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	1ee080e7          	jalr	494(ra) # 80001256 <strlen>
    80005070:	0015079b          	addiw	a5,a0,1
    80005074:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005078:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000507c:	13596363          	bltu	s2,s5,800051a2 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005080:	df043d83          	ld	s11,-528(s0)
    80005084:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005088:	8552                	mv	a0,s4
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	1cc080e7          	jalr	460(ra) # 80001256 <strlen>
    80005092:	0015069b          	addiw	a3,a0,1
    80005096:	8652                	mv	a2,s4
    80005098:	85ca                	mv	a1,s2
    8000509a:	855a                	mv	a0,s6
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	992080e7          	jalr	-1646(ra) # 80001a2e <copyout>
    800050a4:	10054363          	bltz	a0,800051aa <exec+0x302>
    ustack[argc] = sp;
    800050a8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050ac:	0485                	addi	s1,s1,1
    800050ae:	008d8793          	addi	a5,s11,8
    800050b2:	def43823          	sd	a5,-528(s0)
    800050b6:	008db503          	ld	a0,8(s11)
    800050ba:	c911                	beqz	a0,800050ce <exec+0x226>
    if(argc >= MAXARG)
    800050bc:	09a1                	addi	s3,s3,8
    800050be:	fb3c95e3          	bne	s9,s3,80005068 <exec+0x1c0>
  sz = sz1;
    800050c2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050c6:	4a81                	li	s5,0
    800050c8:	a84d                	j	8000517a <exec+0x2d2>
  sp = sz;
    800050ca:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050cc:	4481                	li	s1,0
  ustack[argc] = 0;
    800050ce:	00349793          	slli	a5,s1,0x3
    800050d2:	f9078793          	addi	a5,a5,-112
    800050d6:	97a2                	add	a5,a5,s0
    800050d8:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    800050dc:	00148693          	addi	a3,s1,1
    800050e0:	068e                	slli	a3,a3,0x3
    800050e2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050e6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050ea:	01597663          	bgeu	s2,s5,800050f6 <exec+0x24e>
  sz = sz1;
    800050ee:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f2:	4a81                	li	s5,0
    800050f4:	a059                	j	8000517a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050f6:	e8840613          	addi	a2,s0,-376
    800050fa:	85ca                	mv	a1,s2
    800050fc:	855a                	mv	a0,s6
    800050fe:	ffffd097          	auipc	ra,0xffffd
    80005102:	930080e7          	jalr	-1744(ra) # 80001a2e <copyout>
    80005106:	0a054663          	bltz	a0,800051b2 <exec+0x30a>
  p->trapframe->a1 = sp;
    8000510a:	060bb783          	ld	a5,96(s7)
    8000510e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005112:	de843783          	ld	a5,-536(s0)
    80005116:	0007c703          	lbu	a4,0(a5)
    8000511a:	cf11                	beqz	a4,80005136 <exec+0x28e>
    8000511c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000511e:	02f00693          	li	a3,47
    80005122:	a039                	j	80005130 <exec+0x288>
      last = s+1;
    80005124:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005128:	0785                	addi	a5,a5,1
    8000512a:	fff7c703          	lbu	a4,-1(a5)
    8000512e:	c701                	beqz	a4,80005136 <exec+0x28e>
    if(*s == '/')
    80005130:	fed71ce3          	bne	a4,a3,80005128 <exec+0x280>
    80005134:	bfc5                	j	80005124 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005136:	4641                	li	a2,16
    80005138:	de843583          	ld	a1,-536(s0)
    8000513c:	160b8513          	addi	a0,s7,352
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	0e4080e7          	jalr	228(ra) # 80001224 <safestrcpy>
  oldpagetable = p->pagetable;
    80005148:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    8000514c:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005150:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005154:	060bb783          	ld	a5,96(s7)
    80005158:	e6043703          	ld	a4,-416(s0)
    8000515c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000515e:	060bb783          	ld	a5,96(s7)
    80005162:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005166:	85ea                	mv	a1,s10
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	d30080e7          	jalr	-720(ra) # 80001e98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005170:	0004851b          	sext.w	a0,s1
    80005174:	bbc1                	j	80004f44 <exec+0x9c>
    80005176:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000517a:	df843583          	ld	a1,-520(s0)
    8000517e:	855a                	mv	a0,s6
    80005180:	ffffd097          	auipc	ra,0xffffd
    80005184:	d18080e7          	jalr	-744(ra) # 80001e98 <proc_freepagetable>
  if(ip){
    80005188:	da0a94e3          	bnez	s5,80004f30 <exec+0x88>
  return -1;
    8000518c:	557d                	li	a0,-1
    8000518e:	bb5d                	j	80004f44 <exec+0x9c>
    80005190:	de943c23          	sd	s1,-520(s0)
    80005194:	b7dd                	j	8000517a <exec+0x2d2>
    80005196:	de943c23          	sd	s1,-520(s0)
    8000519a:	b7c5                	j	8000517a <exec+0x2d2>
    8000519c:	de943c23          	sd	s1,-520(s0)
    800051a0:	bfe9                	j	8000517a <exec+0x2d2>
  sz = sz1;
    800051a2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a6:	4a81                	li	s5,0
    800051a8:	bfc9                	j	8000517a <exec+0x2d2>
  sz = sz1;
    800051aa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ae:	4a81                	li	s5,0
    800051b0:	b7e9                	j	8000517a <exec+0x2d2>
  sz = sz1;
    800051b2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051b6:	4a81                	li	s5,0
    800051b8:	b7c9                	j	8000517a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051ba:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051be:	e0843783          	ld	a5,-504(s0)
    800051c2:	0017869b          	addiw	a3,a5,1
    800051c6:	e0d43423          	sd	a3,-504(s0)
    800051ca:	e0043783          	ld	a5,-512(s0)
    800051ce:	0387879b          	addiw	a5,a5,56
    800051d2:	e8045703          	lhu	a4,-384(s0)
    800051d6:	e2e6d3e3          	bge	a3,a4,80004ffc <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051da:	2781                	sext.w	a5,a5
    800051dc:	e0f43023          	sd	a5,-512(s0)
    800051e0:	03800713          	li	a4,56
    800051e4:	86be                	mv	a3,a5
    800051e6:	e1040613          	addi	a2,s0,-496
    800051ea:	4581                	li	a1,0
    800051ec:	8556                	mv	a0,s5
    800051ee:	fffff097          	auipc	ra,0xfffff
    800051f2:	a30080e7          	jalr	-1488(ra) # 80003c1e <readi>
    800051f6:	03800793          	li	a5,56
    800051fa:	f6f51ee3          	bne	a0,a5,80005176 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051fe:	e1042783          	lw	a5,-496(s0)
    80005202:	4705                	li	a4,1
    80005204:	fae79de3          	bne	a5,a4,800051be <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005208:	e3843603          	ld	a2,-456(s0)
    8000520c:	e3043783          	ld	a5,-464(s0)
    80005210:	f8f660e3          	bltu	a2,a5,80005190 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005214:	e2043783          	ld	a5,-480(s0)
    80005218:	963e                	add	a2,a2,a5
    8000521a:	f6f66ee3          	bltu	a2,a5,80005196 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000521e:	85a6                	mv	a1,s1
    80005220:	855a                	mv	a0,s6
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	5b8080e7          	jalr	1464(ra) # 800017da <uvmalloc>
    8000522a:	dea43c23          	sd	a0,-520(s0)
    8000522e:	d53d                	beqz	a0,8000519c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005230:	e2043c03          	ld	s8,-480(s0)
    80005234:	de043783          	ld	a5,-544(s0)
    80005238:	00fc77b3          	and	a5,s8,a5
    8000523c:	ff9d                	bnez	a5,8000517a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000523e:	e1842c83          	lw	s9,-488(s0)
    80005242:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005246:	f60b8ae3          	beqz	s7,800051ba <exec+0x312>
    8000524a:	89de                	mv	s3,s7
    8000524c:	4481                	li	s1,0
    8000524e:	b371                	j	80004fda <exec+0x132>

0000000080005250 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005250:	7179                	addi	sp,sp,-48
    80005252:	f406                	sd	ra,40(sp)
    80005254:	f022                	sd	s0,32(sp)
    80005256:	ec26                	sd	s1,24(sp)
    80005258:	e84a                	sd	s2,16(sp)
    8000525a:	1800                	addi	s0,sp,48
    8000525c:	892e                	mv	s2,a1
    8000525e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005260:	fdc40593          	addi	a1,s0,-36
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	b94080e7          	jalr	-1132(ra) # 80002df8 <argint>
    8000526c:	04054063          	bltz	a0,800052ac <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005270:	fdc42703          	lw	a4,-36(s0)
    80005274:	47bd                	li	a5,15
    80005276:	02e7ed63          	bltu	a5,a4,800052b0 <argfd+0x60>
    8000527a:	ffffd097          	auipc	ra,0xffffd
    8000527e:	abe080e7          	jalr	-1346(ra) # 80001d38 <myproc>
    80005282:	fdc42703          	lw	a4,-36(s0)
    80005286:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd6ff2>
    8000528a:	078e                	slli	a5,a5,0x3
    8000528c:	953e                	add	a0,a0,a5
    8000528e:	651c                	ld	a5,8(a0)
    80005290:	c395                	beqz	a5,800052b4 <argfd+0x64>
    return -1;
  if(pfd)
    80005292:	00090463          	beqz	s2,8000529a <argfd+0x4a>
    *pfd = fd;
    80005296:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000529a:	4501                	li	a0,0
  if(pf)
    8000529c:	c091                	beqz	s1,800052a0 <argfd+0x50>
    *pf = f;
    8000529e:	e09c                	sd	a5,0(s1)
}
    800052a0:	70a2                	ld	ra,40(sp)
    800052a2:	7402                	ld	s0,32(sp)
    800052a4:	64e2                	ld	s1,24(sp)
    800052a6:	6942                	ld	s2,16(sp)
    800052a8:	6145                	addi	sp,sp,48
    800052aa:	8082                	ret
    return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	bfcd                	j	800052a0 <argfd+0x50>
    return -1;
    800052b0:	557d                	li	a0,-1
    800052b2:	b7fd                	j	800052a0 <argfd+0x50>
    800052b4:	557d                	li	a0,-1
    800052b6:	b7ed                	j	800052a0 <argfd+0x50>

00000000800052b8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052b8:	1101                	addi	sp,sp,-32
    800052ba:	ec06                	sd	ra,24(sp)
    800052bc:	e822                	sd	s0,16(sp)
    800052be:	e426                	sd	s1,8(sp)
    800052c0:	1000                	addi	s0,sp,32
    800052c2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	a74080e7          	jalr	-1420(ra) # 80001d38 <myproc>
    800052cc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ce:	0d850793          	addi	a5,a0,216
    800052d2:	4501                	li	a0,0
    800052d4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052d6:	6398                	ld	a4,0(a5)
    800052d8:	cb19                	beqz	a4,800052ee <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052da:	2505                	addiw	a0,a0,1
    800052dc:	07a1                	addi	a5,a5,8
    800052de:	fed51ce3          	bne	a0,a3,800052d6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052e2:	557d                	li	a0,-1
}
    800052e4:	60e2                	ld	ra,24(sp)
    800052e6:	6442                	ld	s0,16(sp)
    800052e8:	64a2                	ld	s1,8(sp)
    800052ea:	6105                	addi	sp,sp,32
    800052ec:	8082                	ret
      p->ofile[fd] = f;
    800052ee:	01a50793          	addi	a5,a0,26
    800052f2:	078e                	slli	a5,a5,0x3
    800052f4:	963e                	add	a2,a2,a5
    800052f6:	e604                	sd	s1,8(a2)
      return fd;
    800052f8:	b7f5                	j	800052e4 <fdalloc+0x2c>

00000000800052fa <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052fa:	715d                	addi	sp,sp,-80
    800052fc:	e486                	sd	ra,72(sp)
    800052fe:	e0a2                	sd	s0,64(sp)
    80005300:	fc26                	sd	s1,56(sp)
    80005302:	f84a                	sd	s2,48(sp)
    80005304:	f44e                	sd	s3,40(sp)
    80005306:	f052                	sd	s4,32(sp)
    80005308:	ec56                	sd	s5,24(sp)
    8000530a:	0880                	addi	s0,sp,80
    8000530c:	89ae                	mv	s3,a1
    8000530e:	8ab2                	mv	s5,a2
    80005310:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005312:	fb040593          	addi	a1,s0,-80
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	e2c080e7          	jalr	-468(ra) # 80004142 <nameiparent>
    8000531e:	892a                	mv	s2,a0
    80005320:	12050e63          	beqz	a0,8000545c <create+0x162>
    return 0;

  ilock(dp);
    80005324:	ffffe097          	auipc	ra,0xffffe
    80005328:	646080e7          	jalr	1606(ra) # 8000396a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000532c:	4601                	li	a2,0
    8000532e:	fb040593          	addi	a1,s0,-80
    80005332:	854a                	mv	a0,s2
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	b18080e7          	jalr	-1256(ra) # 80003e4c <dirlookup>
    8000533c:	84aa                	mv	s1,a0
    8000533e:	c921                	beqz	a0,8000538e <create+0x94>
    iunlockput(dp);
    80005340:	854a                	mv	a0,s2
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	88a080e7          	jalr	-1910(ra) # 80003bcc <iunlockput>
    ilock(ip);
    8000534a:	8526                	mv	a0,s1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	61e080e7          	jalr	1566(ra) # 8000396a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005354:	2981                	sext.w	s3,s3
    80005356:	4789                	li	a5,2
    80005358:	02f99463          	bne	s3,a5,80005380 <create+0x86>
    8000535c:	04c4d783          	lhu	a5,76(s1)
    80005360:	37f9                	addiw	a5,a5,-2
    80005362:	17c2                	slli	a5,a5,0x30
    80005364:	93c1                	srli	a5,a5,0x30
    80005366:	4705                	li	a4,1
    80005368:	00f76c63          	bltu	a4,a5,80005380 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000536c:	8526                	mv	a0,s1
    8000536e:	60a6                	ld	ra,72(sp)
    80005370:	6406                	ld	s0,64(sp)
    80005372:	74e2                	ld	s1,56(sp)
    80005374:	7942                	ld	s2,48(sp)
    80005376:	79a2                	ld	s3,40(sp)
    80005378:	7a02                	ld	s4,32(sp)
    8000537a:	6ae2                	ld	s5,24(sp)
    8000537c:	6161                	addi	sp,sp,80
    8000537e:	8082                	ret
    iunlockput(ip);
    80005380:	8526                	mv	a0,s1
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	84a080e7          	jalr	-1974(ra) # 80003bcc <iunlockput>
    return 0;
    8000538a:	4481                	li	s1,0
    8000538c:	b7c5                	j	8000536c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000538e:	85ce                	mv	a1,s3
    80005390:	00092503          	lw	a0,0(s2)
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	43c080e7          	jalr	1084(ra) # 800037d0 <ialloc>
    8000539c:	84aa                	mv	s1,a0
    8000539e:	c521                	beqz	a0,800053e6 <create+0xec>
  ilock(ip);
    800053a0:	ffffe097          	auipc	ra,0xffffe
    800053a4:	5ca080e7          	jalr	1482(ra) # 8000396a <ilock>
  ip->major = major;
    800053a8:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800053ac:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800053b0:	4a05                	li	s4,1
    800053b2:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    800053b6:	8526                	mv	a0,s1
    800053b8:	ffffe097          	auipc	ra,0xffffe
    800053bc:	4e6080e7          	jalr	1254(ra) # 8000389e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053c0:	2981                	sext.w	s3,s3
    800053c2:	03498a63          	beq	s3,s4,800053f6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053c6:	40d0                	lw	a2,4(s1)
    800053c8:	fb040593          	addi	a1,s0,-80
    800053cc:	854a                	mv	a0,s2
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	c94080e7          	jalr	-876(ra) # 80004062 <dirlink>
    800053d6:	06054b63          	bltz	a0,8000544c <create+0x152>
  iunlockput(dp);
    800053da:	854a                	mv	a0,s2
    800053dc:	ffffe097          	auipc	ra,0xffffe
    800053e0:	7f0080e7          	jalr	2032(ra) # 80003bcc <iunlockput>
  return ip;
    800053e4:	b761                	j	8000536c <create+0x72>
    panic("create: ialloc");
    800053e6:	00003517          	auipc	a0,0x3
    800053ea:	37a50513          	addi	a0,a0,890 # 80008760 <syscalls+0x2a8>
    800053ee:	ffffb097          	auipc	ra,0xffffb
    800053f2:	15e080e7          	jalr	350(ra) # 8000054c <panic>
    dp->nlink++;  // for ".."
    800053f6:	05295783          	lhu	a5,82(s2)
    800053fa:	2785                	addiw	a5,a5,1
    800053fc:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    80005400:	854a                	mv	a0,s2
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	49c080e7          	jalr	1180(ra) # 8000389e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000540a:	40d0                	lw	a2,4(s1)
    8000540c:	00003597          	auipc	a1,0x3
    80005410:	36458593          	addi	a1,a1,868 # 80008770 <syscalls+0x2b8>
    80005414:	8526                	mv	a0,s1
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	c4c080e7          	jalr	-948(ra) # 80004062 <dirlink>
    8000541e:	00054f63          	bltz	a0,8000543c <create+0x142>
    80005422:	00492603          	lw	a2,4(s2)
    80005426:	00003597          	auipc	a1,0x3
    8000542a:	35258593          	addi	a1,a1,850 # 80008778 <syscalls+0x2c0>
    8000542e:	8526                	mv	a0,s1
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	c32080e7          	jalr	-974(ra) # 80004062 <dirlink>
    80005438:	f80557e3          	bgez	a0,800053c6 <create+0xcc>
      panic("create dots");
    8000543c:	00003517          	auipc	a0,0x3
    80005440:	34450513          	addi	a0,a0,836 # 80008780 <syscalls+0x2c8>
    80005444:	ffffb097          	auipc	ra,0xffffb
    80005448:	108080e7          	jalr	264(ra) # 8000054c <panic>
    panic("create: dirlink");
    8000544c:	00003517          	auipc	a0,0x3
    80005450:	34450513          	addi	a0,a0,836 # 80008790 <syscalls+0x2d8>
    80005454:	ffffb097          	auipc	ra,0xffffb
    80005458:	0f8080e7          	jalr	248(ra) # 8000054c <panic>
    return 0;
    8000545c:	84aa                	mv	s1,a0
    8000545e:	b739                	j	8000536c <create+0x72>

0000000080005460 <sys_dup>:
{
    80005460:	7179                	addi	sp,sp,-48
    80005462:	f406                	sd	ra,40(sp)
    80005464:	f022                	sd	s0,32(sp)
    80005466:	ec26                	sd	s1,24(sp)
    80005468:	e84a                	sd	s2,16(sp)
    8000546a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000546c:	fd840613          	addi	a2,s0,-40
    80005470:	4581                	li	a1,0
    80005472:	4501                	li	a0,0
    80005474:	00000097          	auipc	ra,0x0
    80005478:	ddc080e7          	jalr	-548(ra) # 80005250 <argfd>
    return -1;
    8000547c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000547e:	02054363          	bltz	a0,800054a4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005482:	fd843903          	ld	s2,-40(s0)
    80005486:	854a                	mv	a0,s2
    80005488:	00000097          	auipc	ra,0x0
    8000548c:	e30080e7          	jalr	-464(ra) # 800052b8 <fdalloc>
    80005490:	84aa                	mv	s1,a0
    return -1;
    80005492:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005494:	00054863          	bltz	a0,800054a4 <sys_dup+0x44>
  filedup(f);
    80005498:	854a                	mv	a0,s2
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	328080e7          	jalr	808(ra) # 800047c2 <filedup>
  return fd;
    800054a2:	87a6                	mv	a5,s1
}
    800054a4:	853e                	mv	a0,a5
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	64e2                	ld	s1,24(sp)
    800054ac:	6942                	ld	s2,16(sp)
    800054ae:	6145                	addi	sp,sp,48
    800054b0:	8082                	ret

00000000800054b2 <sys_read>:
{
    800054b2:	7179                	addi	sp,sp,-48
    800054b4:	f406                	sd	ra,40(sp)
    800054b6:	f022                	sd	s0,32(sp)
    800054b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ba:	fe840613          	addi	a2,s0,-24
    800054be:	4581                	li	a1,0
    800054c0:	4501                	li	a0,0
    800054c2:	00000097          	auipc	ra,0x0
    800054c6:	d8e080e7          	jalr	-626(ra) # 80005250 <argfd>
    return -1;
    800054ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054cc:	04054163          	bltz	a0,8000550e <sys_read+0x5c>
    800054d0:	fe440593          	addi	a1,s0,-28
    800054d4:	4509                	li	a0,2
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	922080e7          	jalr	-1758(ra) # 80002df8 <argint>
    return -1;
    800054de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e0:	02054763          	bltz	a0,8000550e <sys_read+0x5c>
    800054e4:	fd840593          	addi	a1,s0,-40
    800054e8:	4505                	li	a0,1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	930080e7          	jalr	-1744(ra) # 80002e1a <argaddr>
    return -1;
    800054f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f4:	00054d63          	bltz	a0,8000550e <sys_read+0x5c>
  return fileread(f, p, n);
    800054f8:	fe442603          	lw	a2,-28(s0)
    800054fc:	fd843583          	ld	a1,-40(s0)
    80005500:	fe843503          	ld	a0,-24(s0)
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	44a080e7          	jalr	1098(ra) # 8000494e <fileread>
    8000550c:	87aa                	mv	a5,a0
}
    8000550e:	853e                	mv	a0,a5
    80005510:	70a2                	ld	ra,40(sp)
    80005512:	7402                	ld	s0,32(sp)
    80005514:	6145                	addi	sp,sp,48
    80005516:	8082                	ret

0000000080005518 <sys_write>:
{
    80005518:	7179                	addi	sp,sp,-48
    8000551a:	f406                	sd	ra,40(sp)
    8000551c:	f022                	sd	s0,32(sp)
    8000551e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005520:	fe840613          	addi	a2,s0,-24
    80005524:	4581                	li	a1,0
    80005526:	4501                	li	a0,0
    80005528:	00000097          	auipc	ra,0x0
    8000552c:	d28080e7          	jalr	-728(ra) # 80005250 <argfd>
    return -1;
    80005530:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005532:	04054163          	bltz	a0,80005574 <sys_write+0x5c>
    80005536:	fe440593          	addi	a1,s0,-28
    8000553a:	4509                	li	a0,2
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	8bc080e7          	jalr	-1860(ra) # 80002df8 <argint>
    return -1;
    80005544:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005546:	02054763          	bltz	a0,80005574 <sys_write+0x5c>
    8000554a:	fd840593          	addi	a1,s0,-40
    8000554e:	4505                	li	a0,1
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	8ca080e7          	jalr	-1846(ra) # 80002e1a <argaddr>
    return -1;
    80005558:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000555a:	00054d63          	bltz	a0,80005574 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000555e:	fe442603          	lw	a2,-28(s0)
    80005562:	fd843583          	ld	a1,-40(s0)
    80005566:	fe843503          	ld	a0,-24(s0)
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	4a6080e7          	jalr	1190(ra) # 80004a10 <filewrite>
    80005572:	87aa                	mv	a5,a0
}
    80005574:	853e                	mv	a0,a5
    80005576:	70a2                	ld	ra,40(sp)
    80005578:	7402                	ld	s0,32(sp)
    8000557a:	6145                	addi	sp,sp,48
    8000557c:	8082                	ret

000000008000557e <sys_close>:
{
    8000557e:	1101                	addi	sp,sp,-32
    80005580:	ec06                	sd	ra,24(sp)
    80005582:	e822                	sd	s0,16(sp)
    80005584:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005586:	fe040613          	addi	a2,s0,-32
    8000558a:	fec40593          	addi	a1,s0,-20
    8000558e:	4501                	li	a0,0
    80005590:	00000097          	auipc	ra,0x0
    80005594:	cc0080e7          	jalr	-832(ra) # 80005250 <argfd>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000559a:	02054463          	bltz	a0,800055c2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000559e:	ffffc097          	auipc	ra,0xffffc
    800055a2:	79a080e7          	jalr	1946(ra) # 80001d38 <myproc>
    800055a6:	fec42783          	lw	a5,-20(s0)
    800055aa:	07e9                	addi	a5,a5,26
    800055ac:	078e                	slli	a5,a5,0x3
    800055ae:	953e                	add	a0,a0,a5
    800055b0:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800055b4:	fe043503          	ld	a0,-32(s0)
    800055b8:	fffff097          	auipc	ra,0xfffff
    800055bc:	25c080e7          	jalr	604(ra) # 80004814 <fileclose>
  return 0;
    800055c0:	4781                	li	a5,0
}
    800055c2:	853e                	mv	a0,a5
    800055c4:	60e2                	ld	ra,24(sp)
    800055c6:	6442                	ld	s0,16(sp)
    800055c8:	6105                	addi	sp,sp,32
    800055ca:	8082                	ret

00000000800055cc <sys_fstat>:
{
    800055cc:	1101                	addi	sp,sp,-32
    800055ce:	ec06                	sd	ra,24(sp)
    800055d0:	e822                	sd	s0,16(sp)
    800055d2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d4:	fe840613          	addi	a2,s0,-24
    800055d8:	4581                	li	a1,0
    800055da:	4501                	li	a0,0
    800055dc:	00000097          	auipc	ra,0x0
    800055e0:	c74080e7          	jalr	-908(ra) # 80005250 <argfd>
    return -1;
    800055e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e6:	02054563          	bltz	a0,80005610 <sys_fstat+0x44>
    800055ea:	fe040593          	addi	a1,s0,-32
    800055ee:	4505                	li	a0,1
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	82a080e7          	jalr	-2006(ra) # 80002e1a <argaddr>
    return -1;
    800055f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055fa:	00054b63          	bltz	a0,80005610 <sys_fstat+0x44>
  return filestat(f, st);
    800055fe:	fe043583          	ld	a1,-32(s0)
    80005602:	fe843503          	ld	a0,-24(s0)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	2d6080e7          	jalr	726(ra) # 800048dc <filestat>
    8000560e:	87aa                	mv	a5,a0
}
    80005610:	853e                	mv	a0,a5
    80005612:	60e2                	ld	ra,24(sp)
    80005614:	6442                	ld	s0,16(sp)
    80005616:	6105                	addi	sp,sp,32
    80005618:	8082                	ret

000000008000561a <sys_link>:
{
    8000561a:	7169                	addi	sp,sp,-304
    8000561c:	f606                	sd	ra,296(sp)
    8000561e:	f222                	sd	s0,288(sp)
    80005620:	ee26                	sd	s1,280(sp)
    80005622:	ea4a                	sd	s2,272(sp)
    80005624:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005626:	08000613          	li	a2,128
    8000562a:	ed040593          	addi	a1,s0,-304
    8000562e:	4501                	li	a0,0
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	80c080e7          	jalr	-2036(ra) # 80002e3c <argstr>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000563a:	10054e63          	bltz	a0,80005756 <sys_link+0x13c>
    8000563e:	08000613          	li	a2,128
    80005642:	f5040593          	addi	a1,s0,-176
    80005646:	4505                	li	a0,1
    80005648:	ffffd097          	auipc	ra,0xffffd
    8000564c:	7f4080e7          	jalr	2036(ra) # 80002e3c <argstr>
    return -1;
    80005650:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005652:	10054263          	bltz	a0,80005756 <sys_link+0x13c>
  begin_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	cee080e7          	jalr	-786(ra) # 80004344 <begin_op>
  if((ip = namei(old)) == 0){
    8000565e:	ed040513          	addi	a0,s0,-304
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	ac2080e7          	jalr	-1342(ra) # 80004124 <namei>
    8000566a:	84aa                	mv	s1,a0
    8000566c:	c551                	beqz	a0,800056f8 <sys_link+0xde>
  ilock(ip);
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	2fc080e7          	jalr	764(ra) # 8000396a <ilock>
  if(ip->type == T_DIR){
    80005676:	04c49703          	lh	a4,76(s1)
    8000567a:	4785                	li	a5,1
    8000567c:	08f70463          	beq	a4,a5,80005704 <sys_link+0xea>
  ip->nlink++;
    80005680:	0524d783          	lhu	a5,82(s1)
    80005684:	2785                	addiw	a5,a5,1
    80005686:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    8000568a:	8526                	mv	a0,s1
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	212080e7          	jalr	530(ra) # 8000389e <iupdate>
  iunlock(ip);
    80005694:	8526                	mv	a0,s1
    80005696:	ffffe097          	auipc	ra,0xffffe
    8000569a:	396080e7          	jalr	918(ra) # 80003a2c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000569e:	fd040593          	addi	a1,s0,-48
    800056a2:	f5040513          	addi	a0,s0,-176
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	a9c080e7          	jalr	-1380(ra) # 80004142 <nameiparent>
    800056ae:	892a                	mv	s2,a0
    800056b0:	c935                	beqz	a0,80005724 <sys_link+0x10a>
  ilock(dp);
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	2b8080e7          	jalr	696(ra) # 8000396a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ba:	00092703          	lw	a4,0(s2)
    800056be:	409c                	lw	a5,0(s1)
    800056c0:	04f71d63          	bne	a4,a5,8000571a <sys_link+0x100>
    800056c4:	40d0                	lw	a2,4(s1)
    800056c6:	fd040593          	addi	a1,s0,-48
    800056ca:	854a                	mv	a0,s2
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	996080e7          	jalr	-1642(ra) # 80004062 <dirlink>
    800056d4:	04054363          	bltz	a0,8000571a <sys_link+0x100>
  iunlockput(dp);
    800056d8:	854a                	mv	a0,s2
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	4f2080e7          	jalr	1266(ra) # 80003bcc <iunlockput>
  iput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	440080e7          	jalr	1088(ra) # 80003b24 <iput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	cd6080e7          	jalr	-810(ra) # 800043c2 <end_op>
  return 0;
    800056f4:	4781                	li	a5,0
    800056f6:	a085                	j	80005756 <sys_link+0x13c>
    end_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	cca080e7          	jalr	-822(ra) # 800043c2 <end_op>
    return -1;
    80005700:	57fd                	li	a5,-1
    80005702:	a891                	j	80005756 <sys_link+0x13c>
    iunlockput(ip);
    80005704:	8526                	mv	a0,s1
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	4c6080e7          	jalr	1222(ra) # 80003bcc <iunlockput>
    end_op();
    8000570e:	fffff097          	auipc	ra,0xfffff
    80005712:	cb4080e7          	jalr	-844(ra) # 800043c2 <end_op>
    return -1;
    80005716:	57fd                	li	a5,-1
    80005718:	a83d                	j	80005756 <sys_link+0x13c>
    iunlockput(dp);
    8000571a:	854a                	mv	a0,s2
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	4b0080e7          	jalr	1200(ra) # 80003bcc <iunlockput>
  ilock(ip);
    80005724:	8526                	mv	a0,s1
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	244080e7          	jalr	580(ra) # 8000396a <ilock>
  ip->nlink--;
    8000572e:	0524d783          	lhu	a5,82(s1)
    80005732:	37fd                	addiw	a5,a5,-1
    80005734:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	164080e7          	jalr	356(ra) # 8000389e <iupdate>
  iunlockput(ip);
    80005742:	8526                	mv	a0,s1
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	488080e7          	jalr	1160(ra) # 80003bcc <iunlockput>
  end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	c76080e7          	jalr	-906(ra) # 800043c2 <end_op>
  return -1;
    80005754:	57fd                	li	a5,-1
}
    80005756:	853e                	mv	a0,a5
    80005758:	70b2                	ld	ra,296(sp)
    8000575a:	7412                	ld	s0,288(sp)
    8000575c:	64f2                	ld	s1,280(sp)
    8000575e:	6952                	ld	s2,272(sp)
    80005760:	6155                	addi	sp,sp,304
    80005762:	8082                	ret

0000000080005764 <sys_unlink>:
{
    80005764:	7151                	addi	sp,sp,-240
    80005766:	f586                	sd	ra,232(sp)
    80005768:	f1a2                	sd	s0,224(sp)
    8000576a:	eda6                	sd	s1,216(sp)
    8000576c:	e9ca                	sd	s2,208(sp)
    8000576e:	e5ce                	sd	s3,200(sp)
    80005770:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005772:	08000613          	li	a2,128
    80005776:	f3040593          	addi	a1,s0,-208
    8000577a:	4501                	li	a0,0
    8000577c:	ffffd097          	auipc	ra,0xffffd
    80005780:	6c0080e7          	jalr	1728(ra) # 80002e3c <argstr>
    80005784:	18054163          	bltz	a0,80005906 <sys_unlink+0x1a2>
  begin_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	bbc080e7          	jalr	-1092(ra) # 80004344 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	f3040513          	addi	a0,s0,-208
    80005798:	fffff097          	auipc	ra,0xfffff
    8000579c:	9aa080e7          	jalr	-1622(ra) # 80004142 <nameiparent>
    800057a0:	84aa                	mv	s1,a0
    800057a2:	c979                	beqz	a0,80005878 <sys_unlink+0x114>
  ilock(dp);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	1c6080e7          	jalr	454(ra) # 8000396a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057ac:	00003597          	auipc	a1,0x3
    800057b0:	fc458593          	addi	a1,a1,-60 # 80008770 <syscalls+0x2b8>
    800057b4:	fb040513          	addi	a0,s0,-80
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	67a080e7          	jalr	1658(ra) # 80003e32 <namecmp>
    800057c0:	14050a63          	beqz	a0,80005914 <sys_unlink+0x1b0>
    800057c4:	00003597          	auipc	a1,0x3
    800057c8:	fb458593          	addi	a1,a1,-76 # 80008778 <syscalls+0x2c0>
    800057cc:	fb040513          	addi	a0,s0,-80
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	662080e7          	jalr	1634(ra) # 80003e32 <namecmp>
    800057d8:	12050e63          	beqz	a0,80005914 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057dc:	f2c40613          	addi	a2,s0,-212
    800057e0:	fb040593          	addi	a1,s0,-80
    800057e4:	8526                	mv	a0,s1
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	666080e7          	jalr	1638(ra) # 80003e4c <dirlookup>
    800057ee:	892a                	mv	s2,a0
    800057f0:	12050263          	beqz	a0,80005914 <sys_unlink+0x1b0>
  ilock(ip);
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	176080e7          	jalr	374(ra) # 8000396a <ilock>
  if(ip->nlink < 1)
    800057fc:	05291783          	lh	a5,82(s2)
    80005800:	08f05263          	blez	a5,80005884 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005804:	04c91703          	lh	a4,76(s2)
    80005808:	4785                	li	a5,1
    8000580a:	08f70563          	beq	a4,a5,80005894 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000580e:	4641                	li	a2,16
    80005810:	4581                	li	a1,0
    80005812:	fc040513          	addi	a0,s0,-64
    80005816:	ffffc097          	auipc	ra,0xffffc
    8000581a:	8bc080e7          	jalr	-1860(ra) # 800010d2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000581e:	4741                	li	a4,16
    80005820:	f2c42683          	lw	a3,-212(s0)
    80005824:	fc040613          	addi	a2,s0,-64
    80005828:	4581                	li	a1,0
    8000582a:	8526                	mv	a0,s1
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	4ea080e7          	jalr	1258(ra) # 80003d16 <writei>
    80005834:	47c1                	li	a5,16
    80005836:	0af51563          	bne	a0,a5,800058e0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000583a:	04c91703          	lh	a4,76(s2)
    8000583e:	4785                	li	a5,1
    80005840:	0af70863          	beq	a4,a5,800058f0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	386080e7          	jalr	902(ra) # 80003bcc <iunlockput>
  ip->nlink--;
    8000584e:	05295783          	lhu	a5,82(s2)
    80005852:	37fd                	addiw	a5,a5,-1
    80005854:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005858:	854a                	mv	a0,s2
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	044080e7          	jalr	68(ra) # 8000389e <iupdate>
  iunlockput(ip);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	368080e7          	jalr	872(ra) # 80003bcc <iunlockput>
  end_op();
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	b56080e7          	jalr	-1194(ra) # 800043c2 <end_op>
  return 0;
    80005874:	4501                	li	a0,0
    80005876:	a84d                	j	80005928 <sys_unlink+0x1c4>
    end_op();
    80005878:	fffff097          	auipc	ra,0xfffff
    8000587c:	b4a080e7          	jalr	-1206(ra) # 800043c2 <end_op>
    return -1;
    80005880:	557d                	li	a0,-1
    80005882:	a05d                	j	80005928 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005884:	00003517          	auipc	a0,0x3
    80005888:	f1c50513          	addi	a0,a0,-228 # 800087a0 <syscalls+0x2e8>
    8000588c:	ffffb097          	auipc	ra,0xffffb
    80005890:	cc0080e7          	jalr	-832(ra) # 8000054c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005894:	05492703          	lw	a4,84(s2)
    80005898:	02000793          	li	a5,32
    8000589c:	f6e7f9e3          	bgeu	a5,a4,8000580e <sys_unlink+0xaa>
    800058a0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058a4:	4741                	li	a4,16
    800058a6:	86ce                	mv	a3,s3
    800058a8:	f1840613          	addi	a2,s0,-232
    800058ac:	4581                	li	a1,0
    800058ae:	854a                	mv	a0,s2
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	36e080e7          	jalr	878(ra) # 80003c1e <readi>
    800058b8:	47c1                	li	a5,16
    800058ba:	00f51b63          	bne	a0,a5,800058d0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058be:	f1845783          	lhu	a5,-232(s0)
    800058c2:	e7a1                	bnez	a5,8000590a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c4:	29c1                	addiw	s3,s3,16
    800058c6:	05492783          	lw	a5,84(s2)
    800058ca:	fcf9ede3          	bltu	s3,a5,800058a4 <sys_unlink+0x140>
    800058ce:	b781                	j	8000580e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058d0:	00003517          	auipc	a0,0x3
    800058d4:	ee850513          	addi	a0,a0,-280 # 800087b8 <syscalls+0x300>
    800058d8:	ffffb097          	auipc	ra,0xffffb
    800058dc:	c74080e7          	jalr	-908(ra) # 8000054c <panic>
    panic("unlink: writei");
    800058e0:	00003517          	auipc	a0,0x3
    800058e4:	ef050513          	addi	a0,a0,-272 # 800087d0 <syscalls+0x318>
    800058e8:	ffffb097          	auipc	ra,0xffffb
    800058ec:	c64080e7          	jalr	-924(ra) # 8000054c <panic>
    dp->nlink--;
    800058f0:	0524d783          	lhu	a5,82(s1)
    800058f4:	37fd                	addiw	a5,a5,-1
    800058f6:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	fa2080e7          	jalr	-94(ra) # 8000389e <iupdate>
    80005904:	b781                	j	80005844 <sys_unlink+0xe0>
    return -1;
    80005906:	557d                	li	a0,-1
    80005908:	a005                	j	80005928 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000590a:	854a                	mv	a0,s2
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	2c0080e7          	jalr	704(ra) # 80003bcc <iunlockput>
  iunlockput(dp);
    80005914:	8526                	mv	a0,s1
    80005916:	ffffe097          	auipc	ra,0xffffe
    8000591a:	2b6080e7          	jalr	694(ra) # 80003bcc <iunlockput>
  end_op();
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	aa4080e7          	jalr	-1372(ra) # 800043c2 <end_op>
  return -1;
    80005926:	557d                	li	a0,-1
}
    80005928:	70ae                	ld	ra,232(sp)
    8000592a:	740e                	ld	s0,224(sp)
    8000592c:	64ee                	ld	s1,216(sp)
    8000592e:	694e                	ld	s2,208(sp)
    80005930:	69ae                	ld	s3,200(sp)
    80005932:	616d                	addi	sp,sp,240
    80005934:	8082                	ret

0000000080005936 <sys_open>:

uint64
sys_open(void)
{
    80005936:	7131                	addi	sp,sp,-192
    80005938:	fd06                	sd	ra,184(sp)
    8000593a:	f922                	sd	s0,176(sp)
    8000593c:	f526                	sd	s1,168(sp)
    8000593e:	f14a                	sd	s2,160(sp)
    80005940:	ed4e                	sd	s3,152(sp)
    80005942:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005944:	08000613          	li	a2,128
    80005948:	f5040593          	addi	a1,s0,-176
    8000594c:	4501                	li	a0,0
    8000594e:	ffffd097          	auipc	ra,0xffffd
    80005952:	4ee080e7          	jalr	1262(ra) # 80002e3c <argstr>
    return -1;
    80005956:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005958:	0c054163          	bltz	a0,80005a1a <sys_open+0xe4>
    8000595c:	f4c40593          	addi	a1,s0,-180
    80005960:	4505                	li	a0,1
    80005962:	ffffd097          	auipc	ra,0xffffd
    80005966:	496080e7          	jalr	1174(ra) # 80002df8 <argint>
    8000596a:	0a054863          	bltz	a0,80005a1a <sys_open+0xe4>

  begin_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	9d6080e7          	jalr	-1578(ra) # 80004344 <begin_op>

  if(omode & O_CREATE){
    80005976:	f4c42783          	lw	a5,-180(s0)
    8000597a:	2007f793          	andi	a5,a5,512
    8000597e:	cbdd                	beqz	a5,80005a34 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005980:	4681                	li	a3,0
    80005982:	4601                	li	a2,0
    80005984:	4589                	li	a1,2
    80005986:	f5040513          	addi	a0,s0,-176
    8000598a:	00000097          	auipc	ra,0x0
    8000598e:	970080e7          	jalr	-1680(ra) # 800052fa <create>
    80005992:	892a                	mv	s2,a0
    if(ip == 0){
    80005994:	c959                	beqz	a0,80005a2a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005996:	04c91703          	lh	a4,76(s2)
    8000599a:	478d                	li	a5,3
    8000599c:	00f71763          	bne	a4,a5,800059aa <sys_open+0x74>
    800059a0:	04e95703          	lhu	a4,78(s2)
    800059a4:	47a5                	li	a5,9
    800059a6:	0ce7ec63          	bltu	a5,a4,80005a7e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059aa:	fffff097          	auipc	ra,0xfffff
    800059ae:	dae080e7          	jalr	-594(ra) # 80004758 <filealloc>
    800059b2:	89aa                	mv	s3,a0
    800059b4:	10050263          	beqz	a0,80005ab8 <sys_open+0x182>
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	900080e7          	jalr	-1792(ra) # 800052b8 <fdalloc>
    800059c0:	84aa                	mv	s1,a0
    800059c2:	0e054663          	bltz	a0,80005aae <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059c6:	04c91703          	lh	a4,76(s2)
    800059ca:	478d                	li	a5,3
    800059cc:	0cf70463          	beq	a4,a5,80005a94 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059d0:	4789                	li	a5,2
    800059d2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059d6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059da:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059de:	f4c42783          	lw	a5,-180(s0)
    800059e2:	0017c713          	xori	a4,a5,1
    800059e6:	8b05                	andi	a4,a4,1
    800059e8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059ec:	0037f713          	andi	a4,a5,3
    800059f0:	00e03733          	snez	a4,a4
    800059f4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059f8:	4007f793          	andi	a5,a5,1024
    800059fc:	c791                	beqz	a5,80005a08 <sys_open+0xd2>
    800059fe:	04c91703          	lh	a4,76(s2)
    80005a02:	4789                	li	a5,2
    80005a04:	08f70f63          	beq	a4,a5,80005aa2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a08:	854a                	mv	a0,s2
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	022080e7          	jalr	34(ra) # 80003a2c <iunlock>
  end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9b0080e7          	jalr	-1616(ra) # 800043c2 <end_op>

  return fd;
}
    80005a1a:	8526                	mv	a0,s1
    80005a1c:	70ea                	ld	ra,184(sp)
    80005a1e:	744a                	ld	s0,176(sp)
    80005a20:	74aa                	ld	s1,168(sp)
    80005a22:	790a                	ld	s2,160(sp)
    80005a24:	69ea                	ld	s3,152(sp)
    80005a26:	6129                	addi	sp,sp,192
    80005a28:	8082                	ret
      end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	998080e7          	jalr	-1640(ra) # 800043c2 <end_op>
      return -1;
    80005a32:	b7e5                	j	80005a1a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a34:	f5040513          	addi	a0,s0,-176
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	6ec080e7          	jalr	1772(ra) # 80004124 <namei>
    80005a40:	892a                	mv	s2,a0
    80005a42:	c905                	beqz	a0,80005a72 <sys_open+0x13c>
    ilock(ip);
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	f26080e7          	jalr	-218(ra) # 8000396a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a4c:	04c91703          	lh	a4,76(s2)
    80005a50:	4785                	li	a5,1
    80005a52:	f4f712e3          	bne	a4,a5,80005996 <sys_open+0x60>
    80005a56:	f4c42783          	lw	a5,-180(s0)
    80005a5a:	dba1                	beqz	a5,800059aa <sys_open+0x74>
      iunlockput(ip);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	16e080e7          	jalr	366(ra) # 80003bcc <iunlockput>
      end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	95c080e7          	jalr	-1700(ra) # 800043c2 <end_op>
      return -1;
    80005a6e:	54fd                	li	s1,-1
    80005a70:	b76d                	j	80005a1a <sys_open+0xe4>
      end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	950080e7          	jalr	-1712(ra) # 800043c2 <end_op>
      return -1;
    80005a7a:	54fd                	li	s1,-1
    80005a7c:	bf79                	j	80005a1a <sys_open+0xe4>
    iunlockput(ip);
    80005a7e:	854a                	mv	a0,s2
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	14c080e7          	jalr	332(ra) # 80003bcc <iunlockput>
    end_op();
    80005a88:	fffff097          	auipc	ra,0xfffff
    80005a8c:	93a080e7          	jalr	-1734(ra) # 800043c2 <end_op>
    return -1;
    80005a90:	54fd                	li	s1,-1
    80005a92:	b761                	j	80005a1a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a94:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a98:	04e91783          	lh	a5,78(s2)
    80005a9c:	02f99223          	sh	a5,36(s3)
    80005aa0:	bf2d                	j	800059da <sys_open+0xa4>
    itrunc(ip);
    80005aa2:	854a                	mv	a0,s2
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	fd4080e7          	jalr	-44(ra) # 80003a78 <itrunc>
    80005aac:	bfb1                	j	80005a08 <sys_open+0xd2>
      fileclose(f);
    80005aae:	854e                	mv	a0,s3
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	d64080e7          	jalr	-668(ra) # 80004814 <fileclose>
    iunlockput(ip);
    80005ab8:	854a                	mv	a0,s2
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	112080e7          	jalr	274(ra) # 80003bcc <iunlockput>
    end_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	900080e7          	jalr	-1792(ra) # 800043c2 <end_op>
    return -1;
    80005aca:	54fd                	li	s1,-1
    80005acc:	b7b9                	j	80005a1a <sys_open+0xe4>

0000000080005ace <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ace:	7175                	addi	sp,sp,-144
    80005ad0:	e506                	sd	ra,136(sp)
    80005ad2:	e122                	sd	s0,128(sp)
    80005ad4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ad6:	fffff097          	auipc	ra,0xfffff
    80005ada:	86e080e7          	jalr	-1938(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ade:	08000613          	li	a2,128
    80005ae2:	f7040593          	addi	a1,s0,-144
    80005ae6:	4501                	li	a0,0
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	354080e7          	jalr	852(ra) # 80002e3c <argstr>
    80005af0:	02054963          	bltz	a0,80005b22 <sys_mkdir+0x54>
    80005af4:	4681                	li	a3,0
    80005af6:	4601                	li	a2,0
    80005af8:	4585                	li	a1,1
    80005afa:	f7040513          	addi	a0,s0,-144
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	7fc080e7          	jalr	2044(ra) # 800052fa <create>
    80005b06:	cd11                	beqz	a0,80005b22 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	0c4080e7          	jalr	196(ra) # 80003bcc <iunlockput>
  end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	8b2080e7          	jalr	-1870(ra) # 800043c2 <end_op>
  return 0;
    80005b18:	4501                	li	a0,0
}
    80005b1a:	60aa                	ld	ra,136(sp)
    80005b1c:	640a                	ld	s0,128(sp)
    80005b1e:	6149                	addi	sp,sp,144
    80005b20:	8082                	ret
    end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	8a0080e7          	jalr	-1888(ra) # 800043c2 <end_op>
    return -1;
    80005b2a:	557d                	li	a0,-1
    80005b2c:	b7fd                	j	80005b1a <sys_mkdir+0x4c>

0000000080005b2e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b2e:	7135                	addi	sp,sp,-160
    80005b30:	ed06                	sd	ra,152(sp)
    80005b32:	e922                	sd	s0,144(sp)
    80005b34:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b36:	fffff097          	auipc	ra,0xfffff
    80005b3a:	80e080e7          	jalr	-2034(ra) # 80004344 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b3e:	08000613          	li	a2,128
    80005b42:	f7040593          	addi	a1,s0,-144
    80005b46:	4501                	li	a0,0
    80005b48:	ffffd097          	auipc	ra,0xffffd
    80005b4c:	2f4080e7          	jalr	756(ra) # 80002e3c <argstr>
    80005b50:	04054a63          	bltz	a0,80005ba4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b54:	f6c40593          	addi	a1,s0,-148
    80005b58:	4505                	li	a0,1
    80005b5a:	ffffd097          	auipc	ra,0xffffd
    80005b5e:	29e080e7          	jalr	670(ra) # 80002df8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b62:	04054163          	bltz	a0,80005ba4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b66:	f6840593          	addi	a1,s0,-152
    80005b6a:	4509                	li	a0,2
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	28c080e7          	jalr	652(ra) # 80002df8 <argint>
     argint(1, &major) < 0 ||
    80005b74:	02054863          	bltz	a0,80005ba4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b78:	f6841683          	lh	a3,-152(s0)
    80005b7c:	f6c41603          	lh	a2,-148(s0)
    80005b80:	458d                	li	a1,3
    80005b82:	f7040513          	addi	a0,s0,-144
    80005b86:	fffff097          	auipc	ra,0xfffff
    80005b8a:	774080e7          	jalr	1908(ra) # 800052fa <create>
     argint(2, &minor) < 0 ||
    80005b8e:	c919                	beqz	a0,80005ba4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	03c080e7          	jalr	60(ra) # 80003bcc <iunlockput>
  end_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	82a080e7          	jalr	-2006(ra) # 800043c2 <end_op>
  return 0;
    80005ba0:	4501                	li	a0,0
    80005ba2:	a031                	j	80005bae <sys_mknod+0x80>
    end_op();
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	81e080e7          	jalr	-2018(ra) # 800043c2 <end_op>
    return -1;
    80005bac:	557d                	li	a0,-1
}
    80005bae:	60ea                	ld	ra,152(sp)
    80005bb0:	644a                	ld	s0,144(sp)
    80005bb2:	610d                	addi	sp,sp,160
    80005bb4:	8082                	ret

0000000080005bb6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bb6:	7135                	addi	sp,sp,-160
    80005bb8:	ed06                	sd	ra,152(sp)
    80005bba:	e922                	sd	s0,144(sp)
    80005bbc:	e526                	sd	s1,136(sp)
    80005bbe:	e14a                	sd	s2,128(sp)
    80005bc0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bc2:	ffffc097          	auipc	ra,0xffffc
    80005bc6:	176080e7          	jalr	374(ra) # 80001d38 <myproc>
    80005bca:	892a                	mv	s2,a0
  
  begin_op();
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	778080e7          	jalr	1912(ra) # 80004344 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bd4:	08000613          	li	a2,128
    80005bd8:	f6040593          	addi	a1,s0,-160
    80005bdc:	4501                	li	a0,0
    80005bde:	ffffd097          	auipc	ra,0xffffd
    80005be2:	25e080e7          	jalr	606(ra) # 80002e3c <argstr>
    80005be6:	04054b63          	bltz	a0,80005c3c <sys_chdir+0x86>
    80005bea:	f6040513          	addi	a0,s0,-160
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	536080e7          	jalr	1334(ra) # 80004124 <namei>
    80005bf6:	84aa                	mv	s1,a0
    80005bf8:	c131                	beqz	a0,80005c3c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	d70080e7          	jalr	-656(ra) # 8000396a <ilock>
  if(ip->type != T_DIR){
    80005c02:	04c49703          	lh	a4,76(s1)
    80005c06:	4785                	li	a5,1
    80005c08:	04f71063          	bne	a4,a5,80005c48 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c0c:	8526                	mv	a0,s1
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	e1e080e7          	jalr	-482(ra) # 80003a2c <iunlock>
  iput(p->cwd);
    80005c16:	15893503          	ld	a0,344(s2)
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	f0a080e7          	jalr	-246(ra) # 80003b24 <iput>
  end_op();
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	7a0080e7          	jalr	1952(ra) # 800043c2 <end_op>
  p->cwd = ip;
    80005c2a:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c2e:	4501                	li	a0,0
}
    80005c30:	60ea                	ld	ra,152(sp)
    80005c32:	644a                	ld	s0,144(sp)
    80005c34:	64aa                	ld	s1,136(sp)
    80005c36:	690a                	ld	s2,128(sp)
    80005c38:	610d                	addi	sp,sp,160
    80005c3a:	8082                	ret
    end_op();
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	786080e7          	jalr	1926(ra) # 800043c2 <end_op>
    return -1;
    80005c44:	557d                	li	a0,-1
    80005c46:	b7ed                	j	80005c30 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c48:	8526                	mv	a0,s1
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	f82080e7          	jalr	-126(ra) # 80003bcc <iunlockput>
    end_op();
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	770080e7          	jalr	1904(ra) # 800043c2 <end_op>
    return -1;
    80005c5a:	557d                	li	a0,-1
    80005c5c:	bfd1                	j	80005c30 <sys_chdir+0x7a>

0000000080005c5e <sys_exec>:

uint64
sys_exec(void)
{
    80005c5e:	7145                	addi	sp,sp,-464
    80005c60:	e786                	sd	ra,456(sp)
    80005c62:	e3a2                	sd	s0,448(sp)
    80005c64:	ff26                	sd	s1,440(sp)
    80005c66:	fb4a                	sd	s2,432(sp)
    80005c68:	f74e                	sd	s3,424(sp)
    80005c6a:	f352                	sd	s4,416(sp)
    80005c6c:	ef56                	sd	s5,408(sp)
    80005c6e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c70:	08000613          	li	a2,128
    80005c74:	f4040593          	addi	a1,s0,-192
    80005c78:	4501                	li	a0,0
    80005c7a:	ffffd097          	auipc	ra,0xffffd
    80005c7e:	1c2080e7          	jalr	450(ra) # 80002e3c <argstr>
    return -1;
    80005c82:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c84:	0c054b63          	bltz	a0,80005d5a <sys_exec+0xfc>
    80005c88:	e3840593          	addi	a1,s0,-456
    80005c8c:	4505                	li	a0,1
    80005c8e:	ffffd097          	auipc	ra,0xffffd
    80005c92:	18c080e7          	jalr	396(ra) # 80002e1a <argaddr>
    80005c96:	0c054263          	bltz	a0,80005d5a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c9a:	10000613          	li	a2,256
    80005c9e:	4581                	li	a1,0
    80005ca0:	e4040513          	addi	a0,s0,-448
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	42e080e7          	jalr	1070(ra) # 800010d2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cb0:	89a6                	mv	s3,s1
    80005cb2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cb4:	02000a13          	li	s4,32
    80005cb8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cbc:	00391513          	slli	a0,s2,0x3
    80005cc0:	e3040593          	addi	a1,s0,-464
    80005cc4:	e3843783          	ld	a5,-456(s0)
    80005cc8:	953e                	add	a0,a0,a5
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	094080e7          	jalr	148(ra) # 80002d5e <fetchaddr>
    80005cd2:	02054a63          	bltz	a0,80005d06 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cd6:	e3043783          	ld	a5,-464(s0)
    80005cda:	c3b9                	beqz	a5,80005d20 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cdc:	ffffb097          	auipc	ra,0xffffb
    80005ce0:	e8a080e7          	jalr	-374(ra) # 80000b66 <kalloc>
    80005ce4:	85aa                	mv	a1,a0
    80005ce6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cea:	cd11                	beqz	a0,80005d06 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cec:	6605                	lui	a2,0x1
    80005cee:	e3043503          	ld	a0,-464(s0)
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	0be080e7          	jalr	190(ra) # 80002db0 <fetchstr>
    80005cfa:	00054663          	bltz	a0,80005d06 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cfe:	0905                	addi	s2,s2,1
    80005d00:	09a1                	addi	s3,s3,8
    80005d02:	fb491be3          	bne	s2,s4,80005cb8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d06:	f4040913          	addi	s2,s0,-192
    80005d0a:	6088                	ld	a0,0(s1)
    80005d0c:	c531                	beqz	a0,80005d58 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d0e:	ffffb097          	auipc	ra,0xffffb
    80005d12:	d0a080e7          	jalr	-758(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d16:	04a1                	addi	s1,s1,8
    80005d18:	ff2499e3          	bne	s1,s2,80005d0a <sys_exec+0xac>
  return -1;
    80005d1c:	597d                	li	s2,-1
    80005d1e:	a835                	j	80005d5a <sys_exec+0xfc>
      argv[i] = 0;
    80005d20:	0a8e                	slli	s5,s5,0x3
    80005d22:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd6f98>
    80005d26:	00878ab3          	add	s5,a5,s0
    80005d2a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d2e:	e4040593          	addi	a1,s0,-448
    80005d32:	f4040513          	addi	a0,s0,-192
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	172080e7          	jalr	370(ra) # 80004ea8 <exec>
    80005d3e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d40:	f4040993          	addi	s3,s0,-192
    80005d44:	6088                	ld	a0,0(s1)
    80005d46:	c911                	beqz	a0,80005d5a <sys_exec+0xfc>
    kfree(argv[i]);
    80005d48:	ffffb097          	auipc	ra,0xffffb
    80005d4c:	cd0080e7          	jalr	-816(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d50:	04a1                	addi	s1,s1,8
    80005d52:	ff3499e3          	bne	s1,s3,80005d44 <sys_exec+0xe6>
    80005d56:	a011                	j	80005d5a <sys_exec+0xfc>
  return -1;
    80005d58:	597d                	li	s2,-1
}
    80005d5a:	854a                	mv	a0,s2
    80005d5c:	60be                	ld	ra,456(sp)
    80005d5e:	641e                	ld	s0,448(sp)
    80005d60:	74fa                	ld	s1,440(sp)
    80005d62:	795a                	ld	s2,432(sp)
    80005d64:	79ba                	ld	s3,424(sp)
    80005d66:	7a1a                	ld	s4,416(sp)
    80005d68:	6afa                	ld	s5,408(sp)
    80005d6a:	6179                	addi	sp,sp,464
    80005d6c:	8082                	ret

0000000080005d6e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d6e:	7139                	addi	sp,sp,-64
    80005d70:	fc06                	sd	ra,56(sp)
    80005d72:	f822                	sd	s0,48(sp)
    80005d74:	f426                	sd	s1,40(sp)
    80005d76:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d78:	ffffc097          	auipc	ra,0xffffc
    80005d7c:	fc0080e7          	jalr	-64(ra) # 80001d38 <myproc>
    80005d80:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d82:	fd840593          	addi	a1,s0,-40
    80005d86:	4501                	li	a0,0
    80005d88:	ffffd097          	auipc	ra,0xffffd
    80005d8c:	092080e7          	jalr	146(ra) # 80002e1a <argaddr>
    return -1;
    80005d90:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d92:	0e054063          	bltz	a0,80005e72 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d96:	fc840593          	addi	a1,s0,-56
    80005d9a:	fd040513          	addi	a0,s0,-48
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	dcc080e7          	jalr	-564(ra) # 80004b6a <pipealloc>
    return -1;
    80005da6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005da8:	0c054563          	bltz	a0,80005e72 <sys_pipe+0x104>
  fd0 = -1;
    80005dac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005db0:	fd043503          	ld	a0,-48(s0)
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	504080e7          	jalr	1284(ra) # 800052b8 <fdalloc>
    80005dbc:	fca42223          	sw	a0,-60(s0)
    80005dc0:	08054c63          	bltz	a0,80005e58 <sys_pipe+0xea>
    80005dc4:	fc843503          	ld	a0,-56(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	4f0080e7          	jalr	1264(ra) # 800052b8 <fdalloc>
    80005dd0:	fca42023          	sw	a0,-64(s0)
    80005dd4:	06054963          	bltz	a0,80005e46 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dd8:	4691                	li	a3,4
    80005dda:	fc440613          	addi	a2,s0,-60
    80005dde:	fd843583          	ld	a1,-40(s0)
    80005de2:	6ca8                	ld	a0,88(s1)
    80005de4:	ffffc097          	auipc	ra,0xffffc
    80005de8:	c4a080e7          	jalr	-950(ra) # 80001a2e <copyout>
    80005dec:	02054063          	bltz	a0,80005e0c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005df0:	4691                	li	a3,4
    80005df2:	fc040613          	addi	a2,s0,-64
    80005df6:	fd843583          	ld	a1,-40(s0)
    80005dfa:	0591                	addi	a1,a1,4
    80005dfc:	6ca8                	ld	a0,88(s1)
    80005dfe:	ffffc097          	auipc	ra,0xffffc
    80005e02:	c30080e7          	jalr	-976(ra) # 80001a2e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e06:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e08:	06055563          	bgez	a0,80005e72 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e0c:	fc442783          	lw	a5,-60(s0)
    80005e10:	07e9                	addi	a5,a5,26
    80005e12:	078e                	slli	a5,a5,0x3
    80005e14:	97a6                	add	a5,a5,s1
    80005e16:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e1a:	fc042783          	lw	a5,-64(s0)
    80005e1e:	07e9                	addi	a5,a5,26
    80005e20:	078e                	slli	a5,a5,0x3
    80005e22:	00f48533          	add	a0,s1,a5
    80005e26:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e2a:	fd043503          	ld	a0,-48(s0)
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	9e6080e7          	jalr	-1562(ra) # 80004814 <fileclose>
    fileclose(wf);
    80005e36:	fc843503          	ld	a0,-56(s0)
    80005e3a:	fffff097          	auipc	ra,0xfffff
    80005e3e:	9da080e7          	jalr	-1574(ra) # 80004814 <fileclose>
    return -1;
    80005e42:	57fd                	li	a5,-1
    80005e44:	a03d                	j	80005e72 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e46:	fc442783          	lw	a5,-60(s0)
    80005e4a:	0007c763          	bltz	a5,80005e58 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e4e:	07e9                	addi	a5,a5,26
    80005e50:	078e                	slli	a5,a5,0x3
    80005e52:	97a6                	add	a5,a5,s1
    80005e54:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005e58:	fd043503          	ld	a0,-48(s0)
    80005e5c:	fffff097          	auipc	ra,0xfffff
    80005e60:	9b8080e7          	jalr	-1608(ra) # 80004814 <fileclose>
    fileclose(wf);
    80005e64:	fc843503          	ld	a0,-56(s0)
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	9ac080e7          	jalr	-1620(ra) # 80004814 <fileclose>
    return -1;
    80005e70:	57fd                	li	a5,-1
}
    80005e72:	853e                	mv	a0,a5
    80005e74:	70e2                	ld	ra,56(sp)
    80005e76:	7442                	ld	s0,48(sp)
    80005e78:	74a2                	ld	s1,40(sp)
    80005e7a:	6121                	addi	sp,sp,64
    80005e7c:	8082                	ret
	...

0000000080005e80 <kernelvec>:
    80005e80:	7111                	addi	sp,sp,-256
    80005e82:	e006                	sd	ra,0(sp)
    80005e84:	e40a                	sd	sp,8(sp)
    80005e86:	e80e                	sd	gp,16(sp)
    80005e88:	ec12                	sd	tp,24(sp)
    80005e8a:	f016                	sd	t0,32(sp)
    80005e8c:	f41a                	sd	t1,40(sp)
    80005e8e:	f81e                	sd	t2,48(sp)
    80005e90:	fc22                	sd	s0,56(sp)
    80005e92:	e0a6                	sd	s1,64(sp)
    80005e94:	e4aa                	sd	a0,72(sp)
    80005e96:	e8ae                	sd	a1,80(sp)
    80005e98:	ecb2                	sd	a2,88(sp)
    80005e9a:	f0b6                	sd	a3,96(sp)
    80005e9c:	f4ba                	sd	a4,104(sp)
    80005e9e:	f8be                	sd	a5,112(sp)
    80005ea0:	fcc2                	sd	a6,120(sp)
    80005ea2:	e146                	sd	a7,128(sp)
    80005ea4:	e54a                	sd	s2,136(sp)
    80005ea6:	e94e                	sd	s3,144(sp)
    80005ea8:	ed52                	sd	s4,152(sp)
    80005eaa:	f156                	sd	s5,160(sp)
    80005eac:	f55a                	sd	s6,168(sp)
    80005eae:	f95e                	sd	s7,176(sp)
    80005eb0:	fd62                	sd	s8,184(sp)
    80005eb2:	e1e6                	sd	s9,192(sp)
    80005eb4:	e5ea                	sd	s10,200(sp)
    80005eb6:	e9ee                	sd	s11,208(sp)
    80005eb8:	edf2                	sd	t3,216(sp)
    80005eba:	f1f6                	sd	t4,224(sp)
    80005ebc:	f5fa                	sd	t5,232(sp)
    80005ebe:	f9fe                	sd	t6,240(sp)
    80005ec0:	d6bfc0ef          	jal	ra,80002c2a <kerneltrap>
    80005ec4:	6082                	ld	ra,0(sp)
    80005ec6:	6122                	ld	sp,8(sp)
    80005ec8:	61c2                	ld	gp,16(sp)
    80005eca:	7282                	ld	t0,32(sp)
    80005ecc:	7322                	ld	t1,40(sp)
    80005ece:	73c2                	ld	t2,48(sp)
    80005ed0:	7462                	ld	s0,56(sp)
    80005ed2:	6486                	ld	s1,64(sp)
    80005ed4:	6526                	ld	a0,72(sp)
    80005ed6:	65c6                	ld	a1,80(sp)
    80005ed8:	6666                	ld	a2,88(sp)
    80005eda:	7686                	ld	a3,96(sp)
    80005edc:	7726                	ld	a4,104(sp)
    80005ede:	77c6                	ld	a5,112(sp)
    80005ee0:	7866                	ld	a6,120(sp)
    80005ee2:	688a                	ld	a7,128(sp)
    80005ee4:	692a                	ld	s2,136(sp)
    80005ee6:	69ca                	ld	s3,144(sp)
    80005ee8:	6a6a                	ld	s4,152(sp)
    80005eea:	7a8a                	ld	s5,160(sp)
    80005eec:	7b2a                	ld	s6,168(sp)
    80005eee:	7bca                	ld	s7,176(sp)
    80005ef0:	7c6a                	ld	s8,184(sp)
    80005ef2:	6c8e                	ld	s9,192(sp)
    80005ef4:	6d2e                	ld	s10,200(sp)
    80005ef6:	6dce                	ld	s11,208(sp)
    80005ef8:	6e6e                	ld	t3,216(sp)
    80005efa:	7e8e                	ld	t4,224(sp)
    80005efc:	7f2e                	ld	t5,232(sp)
    80005efe:	7fce                	ld	t6,240(sp)
    80005f00:	6111                	addi	sp,sp,256
    80005f02:	10200073          	sret
    80005f06:	00000013          	nop
    80005f0a:	00000013          	nop
    80005f0e:	0001                	nop

0000000080005f10 <timervec>:
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	e10c                	sd	a1,0(a0)
    80005f16:	e510                	sd	a2,8(a0)
    80005f18:	e914                	sd	a3,16(a0)
    80005f1a:	6d0c                	ld	a1,24(a0)
    80005f1c:	7110                	ld	a2,32(a0)
    80005f1e:	6194                	ld	a3,0(a1)
    80005f20:	96b2                	add	a3,a3,a2
    80005f22:	e194                	sd	a3,0(a1)
    80005f24:	4589                	li	a1,2
    80005f26:	14459073          	csrw	sip,a1
    80005f2a:	6914                	ld	a3,16(a0)
    80005f2c:	6510                	ld	a2,8(a0)
    80005f2e:	610c                	ld	a1,0(a0)
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	30200073          	mret
	...

0000000080005f3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f3a:	1141                	addi	sp,sp,-16
    80005f3c:	e422                	sd	s0,8(sp)
    80005f3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f40:	0c0007b7          	lui	a5,0xc000
    80005f44:	4705                	li	a4,1
    80005f46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f48:	c3d8                	sw	a4,4(a5)
}
    80005f4a:	6422                	ld	s0,8(sp)
    80005f4c:	0141                	addi	sp,sp,16
    80005f4e:	8082                	ret

0000000080005f50 <plicinithart>:

void
plicinithart(void)
{
    80005f50:	1141                	addi	sp,sp,-16
    80005f52:	e406                	sd	ra,8(sp)
    80005f54:	e022                	sd	s0,0(sp)
    80005f56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	db4080e7          	jalr	-588(ra) # 80001d0c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f60:	0085171b          	slliw	a4,a0,0x8
    80005f64:	0c0027b7          	lui	a5,0xc002
    80005f68:	97ba                	add	a5,a5,a4
    80005f6a:	40200713          	li	a4,1026
    80005f6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f72:	00d5151b          	slliw	a0,a0,0xd
    80005f76:	0c2017b7          	lui	a5,0xc201
    80005f7a:	97aa                	add	a5,a5,a0
    80005f7c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f80:	60a2                	ld	ra,8(sp)
    80005f82:	6402                	ld	s0,0(sp)
    80005f84:	0141                	addi	sp,sp,16
    80005f86:	8082                	ret

0000000080005f88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f88:	1141                	addi	sp,sp,-16
    80005f8a:	e406                	sd	ra,8(sp)
    80005f8c:	e022                	sd	s0,0(sp)
    80005f8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f90:	ffffc097          	auipc	ra,0xffffc
    80005f94:	d7c080e7          	jalr	-644(ra) # 80001d0c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f98:	00d5151b          	slliw	a0,a0,0xd
    80005f9c:	0c2017b7          	lui	a5,0xc201
    80005fa0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005fa2:	43c8                	lw	a0,4(a5)
    80005fa4:	60a2                	ld	ra,8(sp)
    80005fa6:	6402                	ld	s0,0(sp)
    80005fa8:	0141                	addi	sp,sp,16
    80005faa:	8082                	ret

0000000080005fac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fac:	1101                	addi	sp,sp,-32
    80005fae:	ec06                	sd	ra,24(sp)
    80005fb0:	e822                	sd	s0,16(sp)
    80005fb2:	e426                	sd	s1,8(sp)
    80005fb4:	1000                	addi	s0,sp,32
    80005fb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fb8:	ffffc097          	auipc	ra,0xffffc
    80005fbc:	d54080e7          	jalr	-684(ra) # 80001d0c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fc0:	00d5151b          	slliw	a0,a0,0xd
    80005fc4:	0c2017b7          	lui	a5,0xc201
    80005fc8:	97aa                	add	a5,a5,a0
    80005fca:	c3c4                	sw	s1,4(a5)
}
    80005fcc:	60e2                	ld	ra,24(sp)
    80005fce:	6442                	ld	s0,16(sp)
    80005fd0:	64a2                	ld	s1,8(sp)
    80005fd2:	6105                	addi	sp,sp,32
    80005fd4:	8082                	ret

0000000080005fd6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fd6:	1141                	addi	sp,sp,-16
    80005fd8:	e406                	sd	ra,8(sp)
    80005fda:	e022                	sd	s0,0(sp)
    80005fdc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fde:	479d                	li	a5,7
    80005fe0:	06a7c863          	blt	a5,a0,80006050 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005fe4:	0001e717          	auipc	a4,0x1e
    80005fe8:	01c70713          	addi	a4,a4,28 # 80024000 <disk>
    80005fec:	972a                	add	a4,a4,a0
    80005fee:	6789                	lui	a5,0x2
    80005ff0:	97ba                	add	a5,a5,a4
    80005ff2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ff6:	e7ad                	bnez	a5,80006060 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ff8:	00451793          	slli	a5,a0,0x4
    80005ffc:	00020717          	auipc	a4,0x20
    80006000:	00470713          	addi	a4,a4,4 # 80026000 <disk+0x2000>
    80006004:	6314                	ld	a3,0(a4)
    80006006:	96be                	add	a3,a3,a5
    80006008:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000600c:	6314                	ld	a3,0(a4)
    8000600e:	96be                	add	a3,a3,a5
    80006010:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006014:	6314                	ld	a3,0(a4)
    80006016:	96be                	add	a3,a3,a5
    80006018:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000601c:	6318                	ld	a4,0(a4)
    8000601e:	97ba                	add	a5,a5,a4
    80006020:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006024:	0001e717          	auipc	a4,0x1e
    80006028:	fdc70713          	addi	a4,a4,-36 # 80024000 <disk>
    8000602c:	972a                	add	a4,a4,a0
    8000602e:	6789                	lui	a5,0x2
    80006030:	97ba                	add	a5,a5,a4
    80006032:	4705                	li	a4,1
    80006034:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006038:	00020517          	auipc	a0,0x20
    8000603c:	fe050513          	addi	a0,a0,-32 # 80026018 <disk+0x2018>
    80006040:	ffffc097          	auipc	ra,0xffffc
    80006044:	690080e7          	jalr	1680(ra) # 800026d0 <wakeup>
}
    80006048:	60a2                	ld	ra,8(sp)
    8000604a:	6402                	ld	s0,0(sp)
    8000604c:	0141                	addi	sp,sp,16
    8000604e:	8082                	ret
    panic("free_desc 1");
    80006050:	00002517          	auipc	a0,0x2
    80006054:	79050513          	addi	a0,a0,1936 # 800087e0 <syscalls+0x328>
    80006058:	ffffa097          	auipc	ra,0xffffa
    8000605c:	4f4080e7          	jalr	1268(ra) # 8000054c <panic>
    panic("free_desc 2");
    80006060:	00002517          	auipc	a0,0x2
    80006064:	79050513          	addi	a0,a0,1936 # 800087f0 <syscalls+0x338>
    80006068:	ffffa097          	auipc	ra,0xffffa
    8000606c:	4e4080e7          	jalr	1252(ra) # 8000054c <panic>

0000000080006070 <virtio_disk_init>:
{
    80006070:	1101                	addi	sp,sp,-32
    80006072:	ec06                	sd	ra,24(sp)
    80006074:	e822                	sd	s0,16(sp)
    80006076:	e426                	sd	s1,8(sp)
    80006078:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000607a:	00002597          	auipc	a1,0x2
    8000607e:	78658593          	addi	a1,a1,1926 # 80008800 <syscalls+0x348>
    80006082:	00020517          	auipc	a0,0x20
    80006086:	0a650513          	addi	a0,a0,166 # 80026128 <disk+0x2128>
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	de4080e7          	jalr	-540(ra) # 80000e6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006092:	100017b7          	lui	a5,0x10001
    80006096:	4398                	lw	a4,0(a5)
    80006098:	2701                	sext.w	a4,a4
    8000609a:	747277b7          	lui	a5,0x74727
    8000609e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060a2:	0ef71063          	bne	a4,a5,80006182 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060a6:	100017b7          	lui	a5,0x10001
    800060aa:	43dc                	lw	a5,4(a5)
    800060ac:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060ae:	4705                	li	a4,1
    800060b0:	0ce79963          	bne	a5,a4,80006182 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060b4:	100017b7          	lui	a5,0x10001
    800060b8:	479c                	lw	a5,8(a5)
    800060ba:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060bc:	4709                	li	a4,2
    800060be:	0ce79263          	bne	a5,a4,80006182 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060c2:	100017b7          	lui	a5,0x10001
    800060c6:	47d8                	lw	a4,12(a5)
    800060c8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ca:	554d47b7          	lui	a5,0x554d4
    800060ce:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060d2:	0af71863          	bne	a4,a5,80006182 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d6:	100017b7          	lui	a5,0x10001
    800060da:	4705                	li	a4,1
    800060dc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	470d                	li	a4,3
    800060e0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060e2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060e4:	c7ffe6b7          	lui	a3,0xc7ffe
    800060e8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6737>
    800060ec:	8f75                	and	a4,a4,a3
    800060ee:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f0:	472d                	li	a4,11
    800060f2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060f4:	473d                	li	a4,15
    800060f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060f8:	6705                	lui	a4,0x1
    800060fa:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060fc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006100:	5bdc                	lw	a5,52(a5)
    80006102:	2781                	sext.w	a5,a5
  if(max == 0)
    80006104:	c7d9                	beqz	a5,80006192 <virtio_disk_init+0x122>
  if(max < NUM)
    80006106:	471d                	li	a4,7
    80006108:	08f77d63          	bgeu	a4,a5,800061a2 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000610c:	100014b7          	lui	s1,0x10001
    80006110:	47a1                	li	a5,8
    80006112:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006114:	6609                	lui	a2,0x2
    80006116:	4581                	li	a1,0
    80006118:	0001e517          	auipc	a0,0x1e
    8000611c:	ee850513          	addi	a0,a0,-280 # 80024000 <disk>
    80006120:	ffffb097          	auipc	ra,0xffffb
    80006124:	fb2080e7          	jalr	-78(ra) # 800010d2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006128:	0001e717          	auipc	a4,0x1e
    8000612c:	ed870713          	addi	a4,a4,-296 # 80024000 <disk>
    80006130:	00c75793          	srli	a5,a4,0xc
    80006134:	2781                	sext.w	a5,a5
    80006136:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006138:	00020797          	auipc	a5,0x20
    8000613c:	ec878793          	addi	a5,a5,-312 # 80026000 <disk+0x2000>
    80006140:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006142:	0001e717          	auipc	a4,0x1e
    80006146:	f3e70713          	addi	a4,a4,-194 # 80024080 <disk+0x80>
    8000614a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000614c:	0001f717          	auipc	a4,0x1f
    80006150:	eb470713          	addi	a4,a4,-332 # 80025000 <disk+0x1000>
    80006154:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006156:	4705                	li	a4,1
    80006158:	00e78c23          	sb	a4,24(a5)
    8000615c:	00e78ca3          	sb	a4,25(a5)
    80006160:	00e78d23          	sb	a4,26(a5)
    80006164:	00e78da3          	sb	a4,27(a5)
    80006168:	00e78e23          	sb	a4,28(a5)
    8000616c:	00e78ea3          	sb	a4,29(a5)
    80006170:	00e78f23          	sb	a4,30(a5)
    80006174:	00e78fa3          	sb	a4,31(a5)
}
    80006178:	60e2                	ld	ra,24(sp)
    8000617a:	6442                	ld	s0,16(sp)
    8000617c:	64a2                	ld	s1,8(sp)
    8000617e:	6105                	addi	sp,sp,32
    80006180:	8082                	ret
    panic("could not find virtio disk");
    80006182:	00002517          	auipc	a0,0x2
    80006186:	68e50513          	addi	a0,a0,1678 # 80008810 <syscalls+0x358>
    8000618a:	ffffa097          	auipc	ra,0xffffa
    8000618e:	3c2080e7          	jalr	962(ra) # 8000054c <panic>
    panic("virtio disk has no queue 0");
    80006192:	00002517          	auipc	a0,0x2
    80006196:	69e50513          	addi	a0,a0,1694 # 80008830 <syscalls+0x378>
    8000619a:	ffffa097          	auipc	ra,0xffffa
    8000619e:	3b2080e7          	jalr	946(ra) # 8000054c <panic>
    panic("virtio disk max queue too short");
    800061a2:	00002517          	auipc	a0,0x2
    800061a6:	6ae50513          	addi	a0,a0,1710 # 80008850 <syscalls+0x398>
    800061aa:	ffffa097          	auipc	ra,0xffffa
    800061ae:	3a2080e7          	jalr	930(ra) # 8000054c <panic>

00000000800061b2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b2:	7119                	addi	sp,sp,-128
    800061b4:	fc86                	sd	ra,120(sp)
    800061b6:	f8a2                	sd	s0,112(sp)
    800061b8:	f4a6                	sd	s1,104(sp)
    800061ba:	f0ca                	sd	s2,96(sp)
    800061bc:	ecce                	sd	s3,88(sp)
    800061be:	e8d2                	sd	s4,80(sp)
    800061c0:	e4d6                	sd	s5,72(sp)
    800061c2:	e0da                	sd	s6,64(sp)
    800061c4:	fc5e                	sd	s7,56(sp)
    800061c6:	f862                	sd	s8,48(sp)
    800061c8:	f466                	sd	s9,40(sp)
    800061ca:	f06a                	sd	s10,32(sp)
    800061cc:	ec6e                	sd	s11,24(sp)
    800061ce:	0100                	addi	s0,sp,128
    800061d0:	8aaa                	mv	s5,a0
    800061d2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d4:	00c52c83          	lw	s9,12(a0)
    800061d8:	001c9c9b          	slliw	s9,s9,0x1
    800061dc:	1c82                	slli	s9,s9,0x20
    800061de:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061e2:	00020517          	auipc	a0,0x20
    800061e6:	f4650513          	addi	a0,a0,-186 # 80026128 <disk+0x2128>
    800061ea:	ffffb097          	auipc	ra,0xffffb
    800061ee:	b08080e7          	jalr	-1272(ra) # 80000cf2 <acquire>
  for(int i = 0; i < 3; i++){
    800061f2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061f6:	0001ec17          	auipc	s8,0x1e
    800061fa:	e0ac0c13          	addi	s8,s8,-502 # 80024000 <disk>
    800061fe:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006200:	4b0d                	li	s6,3
    80006202:	a0ad                	j	8000626c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006204:	00fc0733          	add	a4,s8,a5
    80006208:	975e                	add	a4,a4,s7
    8000620a:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    8000620e:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006210:	0207c563          	bltz	a5,8000623a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006214:	2905                	addiw	s2,s2,1
    80006216:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    80006218:	19690c63          	beq	s2,s6,800063b0 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    8000621c:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    8000621e:	00020717          	auipc	a4,0x20
    80006222:	dfa70713          	addi	a4,a4,-518 # 80026018 <disk+0x2018>
    80006226:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006228:	00074683          	lbu	a3,0(a4)
    8000622c:	fee1                	bnez	a3,80006204 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    8000622e:	2785                	addiw	a5,a5,1
    80006230:	0705                	addi	a4,a4,1
    80006232:	fe979be3          	bne	a5,s1,80006228 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006236:	57fd                	li	a5,-1
    80006238:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000623a:	01205d63          	blez	s2,80006254 <virtio_disk_rw+0xa2>
    8000623e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006240:	000a2503          	lw	a0,0(s4)
    80006244:	00000097          	auipc	ra,0x0
    80006248:	d92080e7          	jalr	-622(ra) # 80005fd6 <free_desc>
      for(int j = 0; j < i; j++)
    8000624c:	2d85                	addiw	s11,s11,1
    8000624e:	0a11                	addi	s4,s4,4
    80006250:	ff2d98e3          	bne	s11,s2,80006240 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006254:	00020597          	auipc	a1,0x20
    80006258:	ed458593          	addi	a1,a1,-300 # 80026128 <disk+0x2128>
    8000625c:	00020517          	auipc	a0,0x20
    80006260:	dbc50513          	addi	a0,a0,-580 # 80026018 <disk+0x2018>
    80006264:	ffffc097          	auipc	ra,0xffffc
    80006268:	2ec080e7          	jalr	748(ra) # 80002550 <sleep>
  for(int i = 0; i < 3; i++){
    8000626c:	f8040a13          	addi	s4,s0,-128
{
    80006270:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006272:	894e                	mv	s2,s3
    80006274:	b765                	j	8000621c <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006276:	00020697          	auipc	a3,0x20
    8000627a:	d8a6b683          	ld	a3,-630(a3) # 80026000 <disk+0x2000>
    8000627e:	96ba                	add	a3,a3,a4
    80006280:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006284:	0001e817          	auipc	a6,0x1e
    80006288:	d7c80813          	addi	a6,a6,-644 # 80024000 <disk>
    8000628c:	00020697          	auipc	a3,0x20
    80006290:	d7468693          	addi	a3,a3,-652 # 80026000 <disk+0x2000>
    80006294:	6290                	ld	a2,0(a3)
    80006296:	963a                	add	a2,a2,a4
    80006298:	00c65583          	lhu	a1,12(a2)
    8000629c:	0015e593          	ori	a1,a1,1
    800062a0:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062a4:	f8842603          	lw	a2,-120(s0)
    800062a8:	628c                	ld	a1,0(a3)
    800062aa:	972e                	add	a4,a4,a1
    800062ac:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062b0:	20050593          	addi	a1,a0,512
    800062b4:	0592                	slli	a1,a1,0x4
    800062b6:	95c2                	add	a1,a1,a6
    800062b8:	577d                	li	a4,-1
    800062ba:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062be:	00461713          	slli	a4,a2,0x4
    800062c2:	6290                	ld	a2,0(a3)
    800062c4:	963a                	add	a2,a2,a4
    800062c6:	03078793          	addi	a5,a5,48
    800062ca:	97c2                	add	a5,a5,a6
    800062cc:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    800062ce:	629c                	ld	a5,0(a3)
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	4605                	li	a2,1
    800062d4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062d6:	629c                	ld	a5,0(a3)
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	4809                	li	a6,2
    800062dc:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062e0:	629c                	ld	a5,0(a3)
    800062e2:	97ba                	add	a5,a5,a4
    800062e4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062e8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062ec:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062f0:	6698                	ld	a4,8(a3)
    800062f2:	00275783          	lhu	a5,2(a4)
    800062f6:	8b9d                	andi	a5,a5,7
    800062f8:	0786                	slli	a5,a5,0x1
    800062fa:	973e                	add	a4,a4,a5
    800062fc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    80006300:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006304:	6698                	ld	a4,8(a3)
    80006306:	00275783          	lhu	a5,2(a4)
    8000630a:	2785                	addiw	a5,a5,1
    8000630c:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006310:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006314:	100017b7          	lui	a5,0x10001
    80006318:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000631c:	004aa783          	lw	a5,4(s5)
    80006320:	02c79163          	bne	a5,a2,80006342 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006324:	00020917          	auipc	s2,0x20
    80006328:	e0490913          	addi	s2,s2,-508 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    8000632c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000632e:	85ca                	mv	a1,s2
    80006330:	8556                	mv	a0,s5
    80006332:	ffffc097          	auipc	ra,0xffffc
    80006336:	21e080e7          	jalr	542(ra) # 80002550 <sleep>
  while(b->disk == 1) {
    8000633a:	004aa783          	lw	a5,4(s5)
    8000633e:	fe9788e3          	beq	a5,s1,8000632e <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006342:	f8042903          	lw	s2,-128(s0)
    80006346:	20090713          	addi	a4,s2,512
    8000634a:	0712                	slli	a4,a4,0x4
    8000634c:	0001e797          	auipc	a5,0x1e
    80006350:	cb478793          	addi	a5,a5,-844 # 80024000 <disk>
    80006354:	97ba                	add	a5,a5,a4
    80006356:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000635a:	00020997          	auipc	s3,0x20
    8000635e:	ca698993          	addi	s3,s3,-858 # 80026000 <disk+0x2000>
    80006362:	00491713          	slli	a4,s2,0x4
    80006366:	0009b783          	ld	a5,0(s3)
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006370:	854a                	mv	a0,s2
    80006372:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006376:	00000097          	auipc	ra,0x0
    8000637a:	c60080e7          	jalr	-928(ra) # 80005fd6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000637e:	8885                	andi	s1,s1,1
    80006380:	f0ed                	bnez	s1,80006362 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006382:	00020517          	auipc	a0,0x20
    80006386:	da650513          	addi	a0,a0,-602 # 80026128 <disk+0x2128>
    8000638a:	ffffb097          	auipc	ra,0xffffb
    8000638e:	a38080e7          	jalr	-1480(ra) # 80000dc2 <release>
}
    80006392:	70e6                	ld	ra,120(sp)
    80006394:	7446                	ld	s0,112(sp)
    80006396:	74a6                	ld	s1,104(sp)
    80006398:	7906                	ld	s2,96(sp)
    8000639a:	69e6                	ld	s3,88(sp)
    8000639c:	6a46                	ld	s4,80(sp)
    8000639e:	6aa6                	ld	s5,72(sp)
    800063a0:	6b06                	ld	s6,64(sp)
    800063a2:	7be2                	ld	s7,56(sp)
    800063a4:	7c42                	ld	s8,48(sp)
    800063a6:	7ca2                	ld	s9,40(sp)
    800063a8:	7d02                	ld	s10,32(sp)
    800063aa:	6de2                	ld	s11,24(sp)
    800063ac:	6109                	addi	sp,sp,128
    800063ae:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063b0:	f8042503          	lw	a0,-128(s0)
    800063b4:	20050793          	addi	a5,a0,512
    800063b8:	0792                	slli	a5,a5,0x4
  if(write)
    800063ba:	0001e817          	auipc	a6,0x1e
    800063be:	c4680813          	addi	a6,a6,-954 # 80024000 <disk>
    800063c2:	00f80733          	add	a4,a6,a5
    800063c6:	01a036b3          	snez	a3,s10
    800063ca:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    800063ce:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063d2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063d6:	7679                	lui	a2,0xffffe
    800063d8:	963e                	add	a2,a2,a5
    800063da:	00020697          	auipc	a3,0x20
    800063de:	c2668693          	addi	a3,a3,-986 # 80026000 <disk+0x2000>
    800063e2:	6298                	ld	a4,0(a3)
    800063e4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063e6:	0a878593          	addi	a1,a5,168
    800063ea:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063ec:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063ee:	6298                	ld	a4,0(a3)
    800063f0:	9732                	add	a4,a4,a2
    800063f2:	45c1                	li	a1,16
    800063f4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063f6:	6298                	ld	a4,0(a3)
    800063f8:	9732                	add	a4,a4,a2
    800063fa:	4585                	li	a1,1
    800063fc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006400:	f8442703          	lw	a4,-124(s0)
    80006404:	628c                	ld	a1,0(a3)
    80006406:	962e                	add	a2,a2,a1
    80006408:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd5fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    8000640c:	0712                	slli	a4,a4,0x4
    8000640e:	6290                	ld	a2,0(a3)
    80006410:	963a                	add	a2,a2,a4
    80006412:	060a8593          	addi	a1,s5,96
    80006416:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006418:	6294                	ld	a3,0(a3)
    8000641a:	96ba                	add	a3,a3,a4
    8000641c:	40000613          	li	a2,1024
    80006420:	c690                	sw	a2,8(a3)
  if(write)
    80006422:	e40d1ae3          	bnez	s10,80006276 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006426:	00020697          	auipc	a3,0x20
    8000642a:	bda6b683          	ld	a3,-1062(a3) # 80026000 <disk+0x2000>
    8000642e:	96ba                	add	a3,a3,a4
    80006430:	4609                	li	a2,2
    80006432:	00c69623          	sh	a2,12(a3)
    80006436:	b5b9                	j	80006284 <virtio_disk_rw+0xd2>

0000000080006438 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006438:	1101                	addi	sp,sp,-32
    8000643a:	ec06                	sd	ra,24(sp)
    8000643c:	e822                	sd	s0,16(sp)
    8000643e:	e426                	sd	s1,8(sp)
    80006440:	e04a                	sd	s2,0(sp)
    80006442:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006444:	00020517          	auipc	a0,0x20
    80006448:	ce450513          	addi	a0,a0,-796 # 80026128 <disk+0x2128>
    8000644c:	ffffb097          	auipc	ra,0xffffb
    80006450:	8a6080e7          	jalr	-1882(ra) # 80000cf2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006454:	10001737          	lui	a4,0x10001
    80006458:	533c                	lw	a5,96(a4)
    8000645a:	8b8d                	andi	a5,a5,3
    8000645c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000645e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006462:	00020797          	auipc	a5,0x20
    80006466:	b9e78793          	addi	a5,a5,-1122 # 80026000 <disk+0x2000>
    8000646a:	6b94                	ld	a3,16(a5)
    8000646c:	0207d703          	lhu	a4,32(a5)
    80006470:	0026d783          	lhu	a5,2(a3)
    80006474:	06f70163          	beq	a4,a5,800064d6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006478:	0001e917          	auipc	s2,0x1e
    8000647c:	b8890913          	addi	s2,s2,-1144 # 80024000 <disk>
    80006480:	00020497          	auipc	s1,0x20
    80006484:	b8048493          	addi	s1,s1,-1152 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006488:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000648c:	6898                	ld	a4,16(s1)
    8000648e:	0204d783          	lhu	a5,32(s1)
    80006492:	8b9d                	andi	a5,a5,7
    80006494:	078e                	slli	a5,a5,0x3
    80006496:	97ba                	add	a5,a5,a4
    80006498:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000649a:	20078713          	addi	a4,a5,512
    8000649e:	0712                	slli	a4,a4,0x4
    800064a0:	974a                	add	a4,a4,s2
    800064a2:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064a6:	e731                	bnez	a4,800064f2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064a8:	20078793          	addi	a5,a5,512
    800064ac:	0792                	slli	a5,a5,0x4
    800064ae:	97ca                	add	a5,a5,s2
    800064b0:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064b2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064b6:	ffffc097          	auipc	ra,0xffffc
    800064ba:	21a080e7          	jalr	538(ra) # 800026d0 <wakeup>

    disk.used_idx += 1;
    800064be:	0204d783          	lhu	a5,32(s1)
    800064c2:	2785                	addiw	a5,a5,1
    800064c4:	17c2                	slli	a5,a5,0x30
    800064c6:	93c1                	srli	a5,a5,0x30
    800064c8:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064cc:	6898                	ld	a4,16(s1)
    800064ce:	00275703          	lhu	a4,2(a4)
    800064d2:	faf71be3          	bne	a4,a5,80006488 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064d6:	00020517          	auipc	a0,0x20
    800064da:	c5250513          	addi	a0,a0,-942 # 80026128 <disk+0x2128>
    800064de:	ffffb097          	auipc	ra,0xffffb
    800064e2:	8e4080e7          	jalr	-1820(ra) # 80000dc2 <release>
}
    800064e6:	60e2                	ld	ra,24(sp)
    800064e8:	6442                	ld	s0,16(sp)
    800064ea:	64a2                	ld	s1,8(sp)
    800064ec:	6902                	ld	s2,0(sp)
    800064ee:	6105                	addi	sp,sp,32
    800064f0:	8082                	ret
      panic("virtio_disk_intr status");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	37e50513          	addi	a0,a0,894 # 80008870 <syscalls+0x3b8>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	052080e7          	jalr	82(ra) # 8000054c <panic>

0000000080006502 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006502:	1141                	addi	sp,sp,-16
    80006504:	e422                	sd	s0,8(sp)
    80006506:	0800                	addi	s0,sp,16
  return -1;
}
    80006508:	557d                	li	a0,-1
    8000650a:	6422                	ld	s0,8(sp)
    8000650c:	0141                	addi	sp,sp,16
    8000650e:	8082                	ret

0000000080006510 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006510:	7179                	addi	sp,sp,-48
    80006512:	f406                	sd	ra,40(sp)
    80006514:	f022                	sd	s0,32(sp)
    80006516:	ec26                	sd	s1,24(sp)
    80006518:	e84a                	sd	s2,16(sp)
    8000651a:	e44e                	sd	s3,8(sp)
    8000651c:	e052                	sd	s4,0(sp)
    8000651e:	1800                	addi	s0,sp,48
    80006520:	892a                	mv	s2,a0
    80006522:	89ae                	mv	s3,a1
    80006524:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006526:	00021517          	auipc	a0,0x21
    8000652a:	ada50513          	addi	a0,a0,-1318 # 80027000 <stats>
    8000652e:	ffffa097          	auipc	ra,0xffffa
    80006532:	7c4080e7          	jalr	1988(ra) # 80000cf2 <acquire>

  if(stats.sz == 0) {
    80006536:	00022797          	auipc	a5,0x22
    8000653a:	aea7a783          	lw	a5,-1302(a5) # 80028020 <stats+0x1020>
    8000653e:	cbb5                	beqz	a5,800065b2 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006540:	00022797          	auipc	a5,0x22
    80006544:	ac078793          	addi	a5,a5,-1344 # 80028000 <stats+0x1000>
    80006548:	53d8                	lw	a4,36(a5)
    8000654a:	539c                	lw	a5,32(a5)
    8000654c:	9f99                	subw	a5,a5,a4
    8000654e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006552:	06d05e63          	blez	a3,800065ce <statsread+0xbe>
    if(m > n)
    80006556:	8a3e                	mv	s4,a5
    80006558:	00d4d363          	bge	s1,a3,8000655e <statsread+0x4e>
    8000655c:	8a26                	mv	s4,s1
    8000655e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006562:	86a6                	mv	a3,s1
    80006564:	00021617          	auipc	a2,0x21
    80006568:	abc60613          	addi	a2,a2,-1348 # 80027020 <stats+0x20>
    8000656c:	963a                	add	a2,a2,a4
    8000656e:	85ce                	mv	a1,s3
    80006570:	854a                	mv	a0,s2
    80006572:	ffffc097          	auipc	ra,0xffffc
    80006576:	238080e7          	jalr	568(ra) # 800027aa <either_copyout>
    8000657a:	57fd                	li	a5,-1
    8000657c:	00f50a63          	beq	a0,a5,80006590 <statsread+0x80>
      stats.off += m;
    80006580:	00022717          	auipc	a4,0x22
    80006584:	a8070713          	addi	a4,a4,-1408 # 80028000 <stats+0x1000>
    80006588:	535c                	lw	a5,36(a4)
    8000658a:	00fa07bb          	addw	a5,s4,a5
    8000658e:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006590:	00021517          	auipc	a0,0x21
    80006594:	a7050513          	addi	a0,a0,-1424 # 80027000 <stats>
    80006598:	ffffb097          	auipc	ra,0xffffb
    8000659c:	82a080e7          	jalr	-2006(ra) # 80000dc2 <release>
  return m;
}
    800065a0:	8526                	mv	a0,s1
    800065a2:	70a2                	ld	ra,40(sp)
    800065a4:	7402                	ld	s0,32(sp)
    800065a6:	64e2                	ld	s1,24(sp)
    800065a8:	6942                	ld	s2,16(sp)
    800065aa:	69a2                	ld	s3,8(sp)
    800065ac:	6a02                	ld	s4,0(sp)
    800065ae:	6145                	addi	sp,sp,48
    800065b0:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    800065b2:	6585                	lui	a1,0x1
    800065b4:	00021517          	auipc	a0,0x21
    800065b8:	a6c50513          	addi	a0,a0,-1428 # 80027020 <stats+0x20>
    800065bc:	ffffb097          	auipc	ra,0xffffb
    800065c0:	960080e7          	jalr	-1696(ra) # 80000f1c <statslock>
    800065c4:	00022797          	auipc	a5,0x22
    800065c8:	a4a7ae23          	sw	a0,-1444(a5) # 80028020 <stats+0x1020>
    800065cc:	bf95                	j	80006540 <statsread+0x30>
    stats.sz = 0;
    800065ce:	00022797          	auipc	a5,0x22
    800065d2:	a3278793          	addi	a5,a5,-1486 # 80028000 <stats+0x1000>
    800065d6:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    800065da:	0207a223          	sw	zero,36(a5)
    m = -1;
    800065de:	54fd                	li	s1,-1
    800065e0:	bf45                	j	80006590 <statsread+0x80>

00000000800065e2 <statsinit>:

void
statsinit(void)
{
    800065e2:	1141                	addi	sp,sp,-16
    800065e4:	e406                	sd	ra,8(sp)
    800065e6:	e022                	sd	s0,0(sp)
    800065e8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800065ea:	00002597          	auipc	a1,0x2
    800065ee:	29e58593          	addi	a1,a1,670 # 80008888 <syscalls+0x3d0>
    800065f2:	00021517          	auipc	a0,0x21
    800065f6:	a0e50513          	addi	a0,a0,-1522 # 80027000 <stats>
    800065fa:	ffffb097          	auipc	ra,0xffffb
    800065fe:	874080e7          	jalr	-1932(ra) # 80000e6e <initlock>

  devsw[STATS].read = statsread;
    80006602:	0001c797          	auipc	a5,0x1c
    80006606:	29678793          	addi	a5,a5,662 # 80022898 <devsw>
    8000660a:	00000717          	auipc	a4,0x0
    8000660e:	f0670713          	addi	a4,a4,-250 # 80006510 <statsread>
    80006612:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006614:	00000717          	auipc	a4,0x0
    80006618:	eee70713          	addi	a4,a4,-274 # 80006502 <statswrite>
    8000661c:	f798                	sd	a4,40(a5)
}
    8000661e:	60a2                	ld	ra,8(sp)
    80006620:	6402                	ld	s0,0(sp)
    80006622:	0141                	addi	sp,sp,16
    80006624:	8082                	ret

0000000080006626 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006626:	1101                	addi	sp,sp,-32
    80006628:	ec22                	sd	s0,24(sp)
    8000662a:	1000                	addi	s0,sp,32
    8000662c:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000662e:	c299                	beqz	a3,80006634 <sprintint+0xe>
    80006630:	0805c263          	bltz	a1,800066b4 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    80006634:	2581                	sext.w	a1,a1
    80006636:	4301                	li	t1,0

  i = 0;
    80006638:	fe040713          	addi	a4,s0,-32
    8000663c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000663e:	2601                	sext.w	a2,a2
    80006640:	00002697          	auipc	a3,0x2
    80006644:	25068693          	addi	a3,a3,592 # 80008890 <digits>
    80006648:	88aa                	mv	a7,a0
    8000664a:	2505                	addiw	a0,a0,1
    8000664c:	02c5f7bb          	remuw	a5,a1,a2
    80006650:	1782                	slli	a5,a5,0x20
    80006652:	9381                	srli	a5,a5,0x20
    80006654:	97b6                	add	a5,a5,a3
    80006656:	0007c783          	lbu	a5,0(a5)
    8000665a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000665e:	0005879b          	sext.w	a5,a1
    80006662:	02c5d5bb          	divuw	a1,a1,a2
    80006666:	0705                	addi	a4,a4,1
    80006668:	fec7f0e3          	bgeu	a5,a2,80006648 <sprintint+0x22>

  if(sign)
    8000666c:	00030b63          	beqz	t1,80006682 <sprintint+0x5c>
    buf[i++] = '-';
    80006670:	ff050793          	addi	a5,a0,-16
    80006674:	97a2                	add	a5,a5,s0
    80006676:	02d00713          	li	a4,45
    8000667a:	fee78823          	sb	a4,-16(a5)
    8000667e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006682:	02a05d63          	blez	a0,800066bc <sprintint+0x96>
    80006686:	fe040793          	addi	a5,s0,-32
    8000668a:	00a78733          	add	a4,a5,a0
    8000668e:	87c2                	mv	a5,a6
    80006690:	00180613          	addi	a2,a6,1
    80006694:	fff5069b          	addiw	a3,a0,-1
    80006698:	1682                	slli	a3,a3,0x20
    8000669a:	9281                	srli	a3,a3,0x20
    8000669c:	9636                	add	a2,a2,a3
  *s = c;
    8000669e:	fff74683          	lbu	a3,-1(a4)
    800066a2:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    800066a6:	177d                	addi	a4,a4,-1
    800066a8:	0785                	addi	a5,a5,1
    800066aa:	fec79ae3          	bne	a5,a2,8000669e <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    800066ae:	6462                	ld	s0,24(sp)
    800066b0:	6105                	addi	sp,sp,32
    800066b2:	8082                	ret
    x = -xx;
    800066b4:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    800066b8:	4305                	li	t1,1
    x = -xx;
    800066ba:	bfbd                	j	80006638 <sprintint+0x12>
  while(--i >= 0)
    800066bc:	4501                	li	a0,0
    800066be:	bfc5                	j	800066ae <sprintint+0x88>

00000000800066c0 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    800066c0:	7135                	addi	sp,sp,-160
    800066c2:	f486                	sd	ra,104(sp)
    800066c4:	f0a2                	sd	s0,96(sp)
    800066c6:	eca6                	sd	s1,88(sp)
    800066c8:	e8ca                	sd	s2,80(sp)
    800066ca:	e4ce                	sd	s3,72(sp)
    800066cc:	e0d2                	sd	s4,64(sp)
    800066ce:	fc56                	sd	s5,56(sp)
    800066d0:	f85a                	sd	s6,48(sp)
    800066d2:	f45e                	sd	s7,40(sp)
    800066d4:	f062                	sd	s8,32(sp)
    800066d6:	ec66                	sd	s9,24(sp)
    800066d8:	e86a                	sd	s10,16(sp)
    800066da:	1880                	addi	s0,sp,112
    800066dc:	e414                	sd	a3,8(s0)
    800066de:	e818                	sd	a4,16(s0)
    800066e0:	ec1c                	sd	a5,24(s0)
    800066e2:	03043023          	sd	a6,32(s0)
    800066e6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800066ea:	c61d                	beqz	a2,80006718 <snprintf+0x58>
    800066ec:	8baa                	mv	s7,a0
    800066ee:	89ae                	mv	s3,a1
    800066f0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800066f2:	00840793          	addi	a5,s0,8
    800066f6:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    800066fa:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800066fc:	4901                	li	s2,0
    800066fe:	02b05563          	blez	a1,80006728 <snprintf+0x68>
    if(c != '%'){
    80006702:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006706:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000670a:	02800d13          	li	s10,40
    switch(c){
    8000670e:	07800c93          	li	s9,120
    80006712:	06400c13          	li	s8,100
    80006716:	a01d                	j	8000673c <snprintf+0x7c>
    panic("null fmt");
    80006718:	00002517          	auipc	a0,0x2
    8000671c:	91050513          	addi	a0,a0,-1776 # 80008028 <etext+0x28>
    80006720:	ffffa097          	auipc	ra,0xffffa
    80006724:	e2c080e7          	jalr	-468(ra) # 8000054c <panic>
  int off = 0;
    80006728:	4481                	li	s1,0
    8000672a:	a875                	j	800067e6 <snprintf+0x126>
  *s = c;
    8000672c:	009b8733          	add	a4,s7,s1
    80006730:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006734:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006736:	2905                	addiw	s2,s2,1
    80006738:	0b34d763          	bge	s1,s3,800067e6 <snprintf+0x126>
    8000673c:	012a07b3          	add	a5,s4,s2
    80006740:	0007c783          	lbu	a5,0(a5)
    80006744:	0007871b          	sext.w	a4,a5
    80006748:	cfd9                	beqz	a5,800067e6 <snprintf+0x126>
    if(c != '%'){
    8000674a:	ff5711e3          	bne	a4,s5,8000672c <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    8000674e:	2905                	addiw	s2,s2,1
    80006750:	012a07b3          	add	a5,s4,s2
    80006754:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006758:	c7d9                	beqz	a5,800067e6 <snprintf+0x126>
    switch(c){
    8000675a:	05678c63          	beq	a5,s6,800067b2 <snprintf+0xf2>
    8000675e:	02fb6763          	bltu	s6,a5,8000678c <snprintf+0xcc>
    80006762:	0b578763          	beq	a5,s5,80006810 <snprintf+0x150>
    80006766:	0b879b63          	bne	a5,s8,8000681c <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000676a:	f9843783          	ld	a5,-104(s0)
    8000676e:	00878713          	addi	a4,a5,8
    80006772:	f8e43c23          	sd	a4,-104(s0)
    80006776:	4685                	li	a3,1
    80006778:	4629                	li	a2,10
    8000677a:	438c                	lw	a1,0(a5)
    8000677c:	009b8533          	add	a0,s7,s1
    80006780:	00000097          	auipc	ra,0x0
    80006784:	ea6080e7          	jalr	-346(ra) # 80006626 <sprintint>
    80006788:	9ca9                	addw	s1,s1,a0
      break;
    8000678a:	b775                	j	80006736 <snprintf+0x76>
    switch(c){
    8000678c:	09979863          	bne	a5,s9,8000681c <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006790:	f9843783          	ld	a5,-104(s0)
    80006794:	00878713          	addi	a4,a5,8
    80006798:	f8e43c23          	sd	a4,-104(s0)
    8000679c:	4685                	li	a3,1
    8000679e:	4641                	li	a2,16
    800067a0:	438c                	lw	a1,0(a5)
    800067a2:	009b8533          	add	a0,s7,s1
    800067a6:	00000097          	auipc	ra,0x0
    800067aa:	e80080e7          	jalr	-384(ra) # 80006626 <sprintint>
    800067ae:	9ca9                	addw	s1,s1,a0
      break;
    800067b0:	b759                	j	80006736 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    800067b2:	f9843783          	ld	a5,-104(s0)
    800067b6:	00878713          	addi	a4,a5,8
    800067ba:	f8e43c23          	sd	a4,-104(s0)
    800067be:	639c                	ld	a5,0(a5)
    800067c0:	c3b1                	beqz	a5,80006804 <snprintf+0x144>
      for(; *s && off < sz; s++)
    800067c2:	0007c703          	lbu	a4,0(a5)
    800067c6:	db25                	beqz	a4,80006736 <snprintf+0x76>
    800067c8:	0734d563          	bge	s1,s3,80006832 <snprintf+0x172>
    800067cc:	009b86b3          	add	a3,s7,s1
  *s = c;
    800067d0:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800067d4:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800067d6:	0785                	addi	a5,a5,1
    800067d8:	0007c703          	lbu	a4,0(a5)
    800067dc:	df29                	beqz	a4,80006736 <snprintf+0x76>
    800067de:	0685                	addi	a3,a3,1
    800067e0:	fe9998e3          	bne	s3,s1,800067d0 <snprintf+0x110>
  int off = 0;
    800067e4:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800067e6:	8526                	mv	a0,s1
    800067e8:	70a6                	ld	ra,104(sp)
    800067ea:	7406                	ld	s0,96(sp)
    800067ec:	64e6                	ld	s1,88(sp)
    800067ee:	6946                	ld	s2,80(sp)
    800067f0:	69a6                	ld	s3,72(sp)
    800067f2:	6a06                	ld	s4,64(sp)
    800067f4:	7ae2                	ld	s5,56(sp)
    800067f6:	7b42                	ld	s6,48(sp)
    800067f8:	7ba2                	ld	s7,40(sp)
    800067fa:	7c02                	ld	s8,32(sp)
    800067fc:	6ce2                	ld	s9,24(sp)
    800067fe:	6d42                	ld	s10,16(sp)
    80006800:	610d                	addi	sp,sp,160
    80006802:	8082                	ret
        s = "(null)";
    80006804:	00002797          	auipc	a5,0x2
    80006808:	81c78793          	addi	a5,a5,-2020 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    8000680c:	876a                	mv	a4,s10
    8000680e:	bf6d                	j	800067c8 <snprintf+0x108>
  *s = c;
    80006810:	009b87b3          	add	a5,s7,s1
    80006814:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    80006818:	2485                	addiw	s1,s1,1
      break;
    8000681a:	bf31                	j	80006736 <snprintf+0x76>
  *s = c;
    8000681c:	009b8733          	add	a4,s7,s1
    80006820:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    80006824:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006828:	975e                	add	a4,a4,s7
    8000682a:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000682e:	2489                	addiw	s1,s1,2
      break;
    80006830:	b719                	j	80006736 <snprintf+0x76>
      for(; *s && off < sz; s++)
    80006832:	89a6                	mv	s3,s1
    80006834:	bf45                	j	800067e4 <snprintf+0x124>
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
