
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
    80000066:	e7e78793          	addi	a5,a5,-386 # 80005ee0 <timervec>
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
    800000b0:	19c78793          	addi	a5,a5,412 # 80001248 <main>
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
    80000116:	ba8080e7          	jalr	-1112(ra) # 80000cba <acquire>
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
    80000130:	69c080e7          	jalr	1692(ra) # 800027c8 <either_copyin>
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
    8000015a:	c34080e7          	jalr	-972(ra) # 80000d8a <release>

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
    800001a8:	b16080e7          	jalr	-1258(ra) # 80000cba <acquire>
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
    800001d6:	b2e080e7          	jalr	-1234(ra) # 80001d00 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	336080e7          	jalr	822(ra) # 80002518 <sleep>
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
    80000222:	554080e7          	jalr	1364(ra) # 80002772 <either_copyout>
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
    8000023e:	b50080e7          	jalr	-1200(ra) # 80000d8a <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b3a080e7          	jalr	-1222(ra) # 80000d8a <release>
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
    800002e4:	9da080e7          	jalr	-1574(ra) # 80000cba <acquire>

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
    80000302:	520080e7          	jalr	1312(ra) # 8000281e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	a7c080e7          	jalr	-1412(ra) # 80000d8a <release>
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
    80000456:	246080e7          	jalr	582(ra) # 80002698 <wakeup>
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
    80000478:	9c2080e7          	jalr	-1598(ra) # 80000e36 <initlock>

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
    80000612:	6ac080e7          	jalr	1708(ra) # 80000cba <acquire>
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
    80000770:	61e080e7          	jalr	1566(ra) # 80000d8a <release>
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
    80000796:	6a4080e7          	jalr	1700(ra) # 80000e36 <initlock>
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
    800007ec:	64e080e7          	jalr	1614(ra) # 80000e36 <initlock>
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
    80000808:	46a080e7          	jalr	1130(ra) # 80000c6e <push_off>

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
    80000836:	4f8080e7          	jalr	1272(ra) # 80000d2a <pop_off>
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
    800008b0:	dec080e7          	jalr	-532(ra) # 80002698 <wakeup>
    
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
    800008f4:	3ca080e7          	jalr	970(ra) # 80000cba <acquire>
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
    8000094a:	bd2080e7          	jalr	-1070(ra) # 80002518 <sleep>
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
    80000990:	3fe080e7          	jalr	1022(ra) # 80000d8a <release>
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
    800009f8:	2c6080e7          	jalr	710(ra) # 80000cba <acquire>
  uartstart();
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	e48080e7          	jalr	-440(ra) # 80000844 <uartstart>
  release(&uart_tx_lock);
    80000a04:	8526                	mv	a0,s1
    80000a06:	00000097          	auipc	ra,0x0
    80000a0a:	384080e7          	jalr	900(ra) # 80000d8a <release>
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
    80000a18:	1101                	addi	sp,sp,-32
    80000a1a:	ec06                	sd	ra,24(sp)
    80000a1c:	e822                	sd	s0,16(sp)
    80000a1e:	e426                	sd	s1,8(sp)
    80000a20:	e04a                	sd	s2,0(sp)
    80000a22:	1000                	addi	s0,sp,32
    80000a24:	84aa                	mv	s1,a0
  struct run *r;
  push_off();
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	248080e7          	jalr	584(ra) # 80000c6e <push_off>
  int id = cpuid();
    80000a2e:	00001097          	auipc	ra,0x1
    80000a32:	2a6080e7          	jalr	678(ra) # 80001cd4 <cpuid>
    80000a36:	892a                	mv	s2,a0
  pop_off();
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2f2080e7          	jalr	754(ra) # 80000d2a <pop_off>
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a40:	03449793          	slli	a5,s1,0x34
    80000a44:	eba1                	bnez	a5,80000a94 <kfree+0x7c>
    80000a46:	00027797          	auipc	a5,0x27
    80000a4a:	5e278793          	addi	a5,a5,1506 # 80028028 <end>
    80000a4e:	04f4e363          	bltu	s1,a5,80000a94 <kfree+0x7c>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	02f4ff63          	bgeu	s1,a5,80000a94 <kfree+0x7c>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	8526                	mv	a0,s1
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	63a080e7          	jalr	1594(ra) # 8000109a <memset>

  r = (struct run*)pa;

  // acquire(&(kmem[id]).lock);
  r->next = kmem[id].freelist;
    80000a68:	00011697          	auipc	a3,0x11
    80000a6c:	82068693          	addi	a3,a3,-2016 # 80011288 <kmem>
    80000a70:	00291793          	slli	a5,s2,0x2
    80000a74:	01278733          	add	a4,a5,s2
    80000a78:	070e                	slli	a4,a4,0x3
    80000a7a:	9736                	add	a4,a4,a3
    80000a7c:	7318                	ld	a4,32(a4)
    80000a7e:	e098                	sd	a4,0(s1)
  kmem[id].freelist = r;
    80000a80:	97ca                	add	a5,a5,s2
    80000a82:	078e                	slli	a5,a5,0x3
    80000a84:	96be                	add	a3,a3,a5
    80000a86:	f284                	sd	s1,32(a3)
  // release(&(kmem[id]).lock);
}
    80000a88:	60e2                	ld	ra,24(sp)
    80000a8a:	6442                	ld	s0,16(sp)
    80000a8c:	64a2                	ld	s1,8(sp)
    80000a8e:	6902                	ld	s2,0(sp)
    80000a90:	6105                	addi	sp,sp,32
    80000a92:	8082                	ret
    panic("kfree");
    80000a94:	00007517          	auipc	a0,0x7
    80000a98:	5cc50513          	addi	a0,a0,1484 # 80008060 <digits+0x20>
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	ab0080e7          	jalr	-1360(ra) # 8000054c <panic>

0000000080000aa4 <freerange>:
{
    80000aa4:	7179                	addi	sp,sp,-48
    80000aa6:	f406                	sd	ra,40(sp)
    80000aa8:	f022                	sd	s0,32(sp)
    80000aaa:	ec26                	sd	s1,24(sp)
    80000aac:	e84a                	sd	s2,16(sp)
    80000aae:	e44e                	sd	s3,8(sp)
    80000ab0:	e052                	sd	s4,0(sp)
    80000ab2:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab4:	6785                	lui	a5,0x1
    80000ab6:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000aba:	00e504b3          	add	s1,a0,a4
    80000abe:	777d                	lui	a4,0xfffff
    80000ac0:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac2:	94be                	add	s1,s1,a5
    80000ac4:	0095ee63          	bltu	a1,s1,80000ae0 <freerange+0x3c>
    80000ac8:	892e                	mv	s2,a1
    kfree(p);
    80000aca:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000acc:	6985                	lui	s3,0x1
    kfree(p);
    80000ace:	01448533          	add	a0,s1,s4
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f46080e7          	jalr	-186(ra) # 80000a18 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ada:	94ce                	add	s1,s1,s3
    80000adc:	fe9979e3          	bgeu	s2,s1,80000ace <freerange+0x2a>
}
    80000ae0:	70a2                	ld	ra,40(sp)
    80000ae2:	7402                	ld	s0,32(sp)
    80000ae4:	64e2                	ld	s1,24(sp)
    80000ae6:	6942                	ld	s2,16(sp)
    80000ae8:	69a2                	ld	s3,8(sp)
    80000aea:	6a02                	ld	s4,0(sp)
    80000aec:	6145                	addi	sp,sp,48
    80000aee:	8082                	ret

0000000080000af0 <kinit>:
{ 
    80000af0:	7139                	addi	sp,sp,-64
    80000af2:	fc06                	sd	ra,56(sp)
    80000af4:	f822                	sd	s0,48(sp)
    80000af6:	f426                	sd	s1,40(sp)
    80000af8:	f04a                	sd	s2,32(sp)
    80000afa:	ec4e                	sd	s3,24(sp)
    80000afc:	e852                	sd	s4,16(sp)
    80000afe:	e456                	sd	s5,8(sp)
    80000b00:	0080                	addi	s0,sp,64
  for(int id=0;id<NCPU;id++){
    80000b02:	00010497          	auipc	s1,0x10
    80000b06:	78648493          	addi	s1,s1,1926 # 80011288 <kmem>
    80000b0a:	00011a97          	auipc	s5,0x11
    80000b0e:	8bea8a93          	addi	s5,s5,-1858 # 800113c8 <lock_locks>
  initlock(&(kmem[id]).lock, "kmem");
    80000b12:	00007a17          	auipc	s4,0x7
    80000b16:	556a0a13          	addi	s4,s4,1366 # 80008068 <digits+0x28>
  freerange(end, (void*)PHYSTOP);
    80000b1a:	4945                	li	s2,17
    80000b1c:	096e                	slli	s2,s2,0x1b
    80000b1e:	00027997          	auipc	s3,0x27
    80000b22:	50a98993          	addi	s3,s3,1290 # 80028028 <end>
  initlock(&(kmem[id]).lock, "kmem");
    80000b26:	85d2                	mv	a1,s4
    80000b28:	8526                	mv	a0,s1
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	30c080e7          	jalr	780(ra) # 80000e36 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b32:	85ca                	mv	a1,s2
    80000b34:	854e                	mv	a0,s3
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	f6e080e7          	jalr	-146(ra) # 80000aa4 <freerange>
  for(int id=0;id<NCPU;id++){
    80000b3e:	02848493          	addi	s1,s1,40
    80000b42:	ff5492e3          	bne	s1,s5,80000b26 <kinit+0x36>
}
    80000b46:	70e2                	ld	ra,56(sp)
    80000b48:	7442                	ld	s0,48(sp)
    80000b4a:	74a2                	ld	s1,40(sp)
    80000b4c:	7902                	ld	s2,32(sp)
    80000b4e:	69e2                	ld	s3,24(sp)
    80000b50:	6a42                	ld	s4,16(sp)
    80000b52:	6aa2                	ld	s5,8(sp)
    80000b54:	6121                	addi	sp,sp,64
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	7139                	addi	sp,sp,-64
    80000b5a:	fc06                	sd	ra,56(sp)
    80000b5c:	f822                	sd	s0,48(sp)
    80000b5e:	f426                	sd	s1,40(sp)
    80000b60:	f04a                	sd	s2,32(sp)
    80000b62:	ec4e                	sd	s3,24(sp)
    80000b64:	e852                	sd	s4,16(sp)
    80000b66:	e456                	sd	s5,8(sp)
    80000b68:	0080                	addi	s0,sp,64
  struct run *r;
  push_off();
    80000b6a:	00000097          	auipc	ra,0x0
    80000b6e:	104080e7          	jalr	260(ra) # 80000c6e <push_off>
  int id = cpuid();
    80000b72:	00001097          	auipc	ra,0x1
    80000b76:	162080e7          	jalr	354(ra) # 80001cd4 <cpuid>
    80000b7a:	89aa                	mv	s3,a0
  pop_off();
    80000b7c:	00000097          	auipc	ra,0x0
    80000b80:	1ae080e7          	jalr	430(ra) # 80000d2a <pop_off>
  
  r = kmem[id].freelist;
    80000b84:	00299793          	slli	a5,s3,0x2
    80000b88:	97ce                	add	a5,a5,s3
    80000b8a:	078e                	slli	a5,a5,0x3
    80000b8c:	00010717          	auipc	a4,0x10
    80000b90:	6fc70713          	addi	a4,a4,1788 # 80011288 <kmem>
    80000b94:	97ba                	add	a5,a5,a4
    80000b96:	0207ba03          	ld	s4,32(a5)
  if(r){
    80000b9a:	040a0163          	beqz	s4,80000bdc <kalloc+0x84>
    
    acquire(&(kmem[id]).lock);
    80000b9e:	84be                	mv	s1,a5
    80000ba0:	853e                	mv	a0,a5
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	118080e7          	jalr	280(ra) # 80000cba <acquire>
    kmem[id].freelist = r->next;
    80000baa:	000a3783          	ld	a5,0(s4)
    80000bae:	f09c                	sd	a5,32(s1)
    release(&(kmem[id]).lock);
    80000bb0:	8526                	mv	a0,s1
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	1d8080e7          	jalr	472(ra) # 80000d8a <release>
      release(&(kmem[idx]).lock);
    }
  

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bba:	6605                	lui	a2,0x1
    80000bbc:	4595                	li	a1,5
    80000bbe:	8552                	mv	a0,s4
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	4da080e7          	jalr	1242(ra) # 8000109a <memset>
  return (void*)r;
    80000bc8:	8552                	mv	a0,s4
    80000bca:	70e2                	ld	ra,56(sp)
    80000bcc:	7442                	ld	s0,48(sp)
    80000bce:	74a2                	ld	s1,40(sp)
    80000bd0:	7902                	ld	s2,32(sp)
    80000bd2:	69e2                	ld	s3,24(sp)
    80000bd4:	6a42                	ld	s4,16(sp)
    80000bd6:	6aa2                	ld	s5,8(sp)
    80000bd8:	6121                	addi	sp,sp,64
    80000bda:	8082                	ret
    80000bdc:	00010917          	auipc	s2,0x10
    80000be0:	6ac90913          	addi	s2,s2,1708 # 80011288 <kmem>
    for(int idx=0;idx<NCPU;idx++){
    80000be4:	4481                	li	s1,0
    80000be6:	4aa1                	li	s5,8
    80000be8:	a089                	j	80000c2a <kalloc+0xd2>
        acquire(&(kmem[idx]).lock);
    80000bea:	00010a97          	auipc	s5,0x10
    80000bee:	69ea8a93          	addi	s5,s5,1694 # 80011288 <kmem>
    80000bf2:	00249993          	slli	s3,s1,0x2
    80000bf6:	00998933          	add	s2,s3,s1
    80000bfa:	090e                	slli	s2,s2,0x3
    80000bfc:	9956                	add	s2,s2,s5
    80000bfe:	854a                	mv	a0,s2
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	0ba080e7          	jalr	186(ra) # 80000cba <acquire>
        r = kmem[idx].freelist;
    80000c08:	02093a03          	ld	s4,32(s2)
        kmem[idx].freelist=r->next;
    80000c0c:	000a3783          	ld	a5,0(s4)
    80000c10:	02f93023          	sd	a5,32(s2)
        release(&(kmem[idx]).lock);
    80000c14:	854a                	mv	a0,s2
    80000c16:	00000097          	auipc	ra,0x0
    80000c1a:	174080e7          	jalr	372(ra) # 80000d8a <release>
        break;
    80000c1e:	bf71                	j	80000bba <kalloc+0x62>
    for(int idx=0;idx<NCPU;idx++){
    80000c20:	2485                	addiw	s1,s1,1
    80000c22:	02890913          	addi	s2,s2,40
    80000c26:	fb5481e3          	beq	s1,s5,80000bc8 <kalloc+0x70>
      if(idx==id) continue;
    80000c2a:	fe998be3          	beq	s3,s1,80000c20 <kalloc+0xc8>
      if(kmem[idx].freelist){
    80000c2e:	02093783          	ld	a5,32(s2)
    80000c32:	ffc5                	bnez	a5,80000bea <kalloc+0x92>
      release(&(kmem[idx]).lock);
    80000c34:	854a                	mv	a0,s2
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	154080e7          	jalr	340(ra) # 80000d8a <release>
    80000c3e:	b7cd                	j	80000c20 <kalloc+0xc8>

0000000080000c40 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c40:	411c                	lw	a5,0(a0)
    80000c42:	e399                	bnez	a5,80000c48 <holding+0x8>
    80000c44:	4501                	li	a0,0
  return r;
}
    80000c46:	8082                	ret
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c52:	6904                	ld	s1,16(a0)
    80000c54:	00001097          	auipc	ra,0x1
    80000c58:	090080e7          	jalr	144(ra) # 80001ce4 <mycpu>
    80000c5c:	40a48533          	sub	a0,s1,a0
    80000c60:	00153513          	seqz	a0,a0
}
    80000c64:	60e2                	ld	ra,24(sp)
    80000c66:	6442                	ld	s0,16(sp)
    80000c68:	64a2                	ld	s1,8(sp)
    80000c6a:	6105                	addi	sp,sp,32
    80000c6c:	8082                	ret

0000000080000c6e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c6e:	1101                	addi	sp,sp,-32
    80000c70:	ec06                	sd	ra,24(sp)
    80000c72:	e822                	sd	s0,16(sp)
    80000c74:	e426                	sd	s1,8(sp)
    80000c76:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c78:	100024f3          	csrr	s1,sstatus
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c80:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c82:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c86:	00001097          	auipc	ra,0x1
    80000c8a:	05e080e7          	jalr	94(ra) # 80001ce4 <mycpu>
    80000c8e:	5d3c                	lw	a5,120(a0)
    80000c90:	cf89                	beqz	a5,80000caa <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	052080e7          	jalr	82(ra) # 80001ce4 <mycpu>
    80000c9a:	5d3c                	lw	a5,120(a0)
    80000c9c:	2785                	addiw	a5,a5,1
    80000c9e:	dd3c                	sw	a5,120(a0)
}
    80000ca0:	60e2                	ld	ra,24(sp)
    80000ca2:	6442                	ld	s0,16(sp)
    80000ca4:	64a2                	ld	s1,8(sp)
    80000ca6:	6105                	addi	sp,sp,32
    80000ca8:	8082                	ret
    mycpu()->intena = old;
    80000caa:	00001097          	auipc	ra,0x1
    80000cae:	03a080e7          	jalr	58(ra) # 80001ce4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cb2:	8085                	srli	s1,s1,0x1
    80000cb4:	8885                	andi	s1,s1,1
    80000cb6:	dd64                	sw	s1,124(a0)
    80000cb8:	bfe9                	j	80000c92 <push_off+0x24>

0000000080000cba <acquire>:
{
    80000cba:	1101                	addi	sp,sp,-32
    80000cbc:	ec06                	sd	ra,24(sp)
    80000cbe:	e822                	sd	s0,16(sp)
    80000cc0:	e426                	sd	s1,8(sp)
    80000cc2:	1000                	addi	s0,sp,32
    80000cc4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	fa8080e7          	jalr	-88(ra) # 80000c6e <push_off>
  if(holding(lk))
    80000cce:	8526                	mv	a0,s1
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	f70080e7          	jalr	-144(ra) # 80000c40 <holding>
    80000cd8:	e911                	bnez	a0,80000cec <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000cda:	4785                	li	a5,1
    80000cdc:	01c48713          	addi	a4,s1,28
    80000ce0:	0f50000f          	fence	iorw,ow
    80000ce4:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000ce8:	4705                	li	a4,1
    80000cea:	a839                	j	80000d08 <acquire+0x4e>
    panic("acquire");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	38450513          	addi	a0,a0,900 # 80008070 <digits+0x30>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	858080e7          	jalr	-1960(ra) # 8000054c <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000cfc:	01848793          	addi	a5,s1,24
    80000d00:	0f50000f          	fence	iorw,ow
    80000d04:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d08:	87ba                	mv	a5,a4
    80000d0a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d0e:	2781                	sext.w	a5,a5
    80000d10:	f7f5                	bnez	a5,80000cfc <acquire+0x42>
  __sync_synchronize();
    80000d12:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d16:	00001097          	auipc	ra,0x1
    80000d1a:	fce080e7          	jalr	-50(ra) # 80001ce4 <mycpu>
    80000d1e:	e888                	sd	a0,16(s1)
}
    80000d20:	60e2                	ld	ra,24(sp)
    80000d22:	6442                	ld	s0,16(sp)
    80000d24:	64a2                	ld	s1,8(sp)
    80000d26:	6105                	addi	sp,sp,32
    80000d28:	8082                	ret

0000000080000d2a <pop_off>:

void
pop_off(void)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e406                	sd	ra,8(sp)
    80000d2e:	e022                	sd	s0,0(sp)
    80000d30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d32:	00001097          	auipc	ra,0x1
    80000d36:	fb2080e7          	jalr	-78(ra) # 80001ce4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d40:	e78d                	bnez	a5,80000d6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d42:	5d3c                	lw	a5,120(a0)
    80000d44:	02f05b63          	blez	a5,80000d7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d48:	37fd                	addiw	a5,a5,-1
    80000d4a:	0007871b          	sext.w	a4,a5
    80000d4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d50:	eb09                	bnez	a4,80000d62 <pop_off+0x38>
    80000d52:	5d7c                	lw	a5,124(a0)
    80000d54:	c799                	beqz	a5,80000d62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d62:	60a2                	ld	ra,8(sp)
    80000d64:	6402                	ld	s0,0(sp)
    80000d66:	0141                	addi	sp,sp,16
    80000d68:	8082                	ret
    panic("pop_off - interruptible");
    80000d6a:	00007517          	auipc	a0,0x7
    80000d6e:	30e50513          	addi	a0,a0,782 # 80008078 <digits+0x38>
    80000d72:	fffff097          	auipc	ra,0xfffff
    80000d76:	7da080e7          	jalr	2010(ra) # 8000054c <panic>
    panic("pop_off");
    80000d7a:	00007517          	auipc	a0,0x7
    80000d7e:	31650513          	addi	a0,a0,790 # 80008090 <digits+0x50>
    80000d82:	fffff097          	auipc	ra,0xfffff
    80000d86:	7ca080e7          	jalr	1994(ra) # 8000054c <panic>

0000000080000d8a <release>:
{
    80000d8a:	1101                	addi	sp,sp,-32
    80000d8c:	ec06                	sd	ra,24(sp)
    80000d8e:	e822                	sd	s0,16(sp)
    80000d90:	e426                	sd	s1,8(sp)
    80000d92:	1000                	addi	s0,sp,32
    80000d94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d96:	00000097          	auipc	ra,0x0
    80000d9a:	eaa080e7          	jalr	-342(ra) # 80000c40 <holding>
    80000d9e:	c115                	beqz	a0,80000dc2 <release+0x38>
  lk->cpu = 0;
    80000da0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000da4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000da8:	0f50000f          	fence	iorw,ow
    80000dac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000db0:	00000097          	auipc	ra,0x0
    80000db4:	f7a080e7          	jalr	-134(ra) # 80000d2a <pop_off>
}
    80000db8:	60e2                	ld	ra,24(sp)
    80000dba:	6442                	ld	s0,16(sp)
    80000dbc:	64a2                	ld	s1,8(sp)
    80000dbe:	6105                	addi	sp,sp,32
    80000dc0:	8082                	ret
    panic("release");
    80000dc2:	00007517          	auipc	a0,0x7
    80000dc6:	2d650513          	addi	a0,a0,726 # 80008098 <digits+0x58>
    80000dca:	fffff097          	auipc	ra,0xfffff
    80000dce:	782080e7          	jalr	1922(ra) # 8000054c <panic>

0000000080000dd2 <freelock>:
{
    80000dd2:	1101                	addi	sp,sp,-32
    80000dd4:	ec06                	sd	ra,24(sp)
    80000dd6:	e822                	sd	s0,16(sp)
    80000dd8:	e426                	sd	s1,8(sp)
    80000dda:	1000                	addi	s0,sp,32
    80000ddc:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000dde:	00010517          	auipc	a0,0x10
    80000de2:	5ea50513          	addi	a0,a0,1514 # 800113c8 <lock_locks>
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	ed4080e7          	jalr	-300(ra) # 80000cba <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000dee:	00010717          	auipc	a4,0x10
    80000df2:	5fa70713          	addi	a4,a4,1530 # 800113e8 <locks>
    80000df6:	4781                	li	a5,0
    80000df8:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000dfc:	6314                	ld	a3,0(a4)
    80000dfe:	00968763          	beq	a3,s1,80000e0c <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e02:	2785                	addiw	a5,a5,1
    80000e04:	0721                	addi	a4,a4,8
    80000e06:	fec79be3          	bne	a5,a2,80000dfc <freelock+0x2a>
    80000e0a:	a809                	j	80000e1c <freelock+0x4a>
      locks[i] = 0;
    80000e0c:	078e                	slli	a5,a5,0x3
    80000e0e:	00010717          	auipc	a4,0x10
    80000e12:	5da70713          	addi	a4,a4,1498 # 800113e8 <locks>
    80000e16:	97ba                	add	a5,a5,a4
    80000e18:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e1c:	00010517          	auipc	a0,0x10
    80000e20:	5ac50513          	addi	a0,a0,1452 # 800113c8 <lock_locks>
    80000e24:	00000097          	auipc	ra,0x0
    80000e28:	f66080e7          	jalr	-154(ra) # 80000d8a <release>
}
    80000e2c:	60e2                	ld	ra,24(sp)
    80000e2e:	6442                	ld	s0,16(sp)
    80000e30:	64a2                	ld	s1,8(sp)
    80000e32:	6105                	addi	sp,sp,32
    80000e34:	8082                	ret

0000000080000e36 <initlock>:
{
    80000e36:	1101                	addi	sp,sp,-32
    80000e38:	ec06                	sd	ra,24(sp)
    80000e3a:	e822                	sd	s0,16(sp)
    80000e3c:	e426                	sd	s1,8(sp)
    80000e3e:	1000                	addi	s0,sp,32
    80000e40:	84aa                	mv	s1,a0
  lk->name = name;
    80000e42:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e44:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e48:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e4c:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e50:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e54:	00010517          	auipc	a0,0x10
    80000e58:	57450513          	addi	a0,a0,1396 # 800113c8 <lock_locks>
    80000e5c:	00000097          	auipc	ra,0x0
    80000e60:	e5e080e7          	jalr	-418(ra) # 80000cba <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e64:	00010717          	auipc	a4,0x10
    80000e68:	58470713          	addi	a4,a4,1412 # 800113e8 <locks>
    80000e6c:	4781                	li	a5,0
    80000e6e:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000e72:	6314                	ld	a3,0(a4)
    80000e74:	ce89                	beqz	a3,80000e8e <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000e76:	2785                	addiw	a5,a5,1
    80000e78:	0721                	addi	a4,a4,8
    80000e7a:	fec79ce3          	bne	a5,a2,80000e72 <initlock+0x3c>
  panic("findslot");
    80000e7e:	00007517          	auipc	a0,0x7
    80000e82:	22250513          	addi	a0,a0,546 # 800080a0 <digits+0x60>
    80000e86:	fffff097          	auipc	ra,0xfffff
    80000e8a:	6c6080e7          	jalr	1734(ra) # 8000054c <panic>
      locks[i] = lk;
    80000e8e:	078e                	slli	a5,a5,0x3
    80000e90:	00010717          	auipc	a4,0x10
    80000e94:	55870713          	addi	a4,a4,1368 # 800113e8 <locks>
    80000e98:	97ba                	add	a5,a5,a4
    80000e9a:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000e9c:	00010517          	auipc	a0,0x10
    80000ea0:	52c50513          	addi	a0,a0,1324 # 800113c8 <lock_locks>
    80000ea4:	00000097          	auipc	ra,0x0
    80000ea8:	ee6080e7          	jalr	-282(ra) # 80000d8a <release>
}
    80000eac:	60e2                	ld	ra,24(sp)
    80000eae:	6442                	ld	s0,16(sp)
    80000eb0:	64a2                	ld	s1,8(sp)
    80000eb2:	6105                	addi	sp,sp,32
    80000eb4:	8082                	ret

0000000080000eb6 <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000eb6:	4e5c                	lw	a5,28(a2)
    80000eb8:	00f04463          	bgtz	a5,80000ec0 <snprint_lock+0xa>
  int n = 0;
    80000ebc:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ebe:	8082                	ret
{
    80000ec0:	1141                	addi	sp,sp,-16
    80000ec2:	e406                	sd	ra,8(sp)
    80000ec4:	e022                	sd	s0,0(sp)
    80000ec6:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000ec8:	4e18                	lw	a4,24(a2)
    80000eca:	6614                	ld	a3,8(a2)
    80000ecc:	00007617          	auipc	a2,0x7
    80000ed0:	1e460613          	addi	a2,a2,484 # 800080b0 <digits+0x70>
    80000ed4:	00005097          	auipc	ra,0x5
    80000ed8:	7bc080e7          	jalr	1980(ra) # 80006690 <snprintf>
}
    80000edc:	60a2                	ld	ra,8(sp)
    80000ede:	6402                	ld	s0,0(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret

0000000080000ee4 <statslock>:

int
statslock(char *buf, int sz) {
    80000ee4:	7159                	addi	sp,sp,-112
    80000ee6:	f486                	sd	ra,104(sp)
    80000ee8:	f0a2                	sd	s0,96(sp)
    80000eea:	eca6                	sd	s1,88(sp)
    80000eec:	e8ca                	sd	s2,80(sp)
    80000eee:	e4ce                	sd	s3,72(sp)
    80000ef0:	e0d2                	sd	s4,64(sp)
    80000ef2:	fc56                	sd	s5,56(sp)
    80000ef4:	f85a                	sd	s6,48(sp)
    80000ef6:	f45e                	sd	s7,40(sp)
    80000ef8:	f062                	sd	s8,32(sp)
    80000efa:	ec66                	sd	s9,24(sp)
    80000efc:	e86a                	sd	s10,16(sp)
    80000efe:	e46e                	sd	s11,8(sp)
    80000f00:	1880                	addi	s0,sp,112
    80000f02:	8aaa                	mv	s5,a0
    80000f04:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f06:	00010517          	auipc	a0,0x10
    80000f0a:	4c250513          	addi	a0,a0,1218 # 800113c8 <lock_locks>
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	dac080e7          	jalr	-596(ra) # 80000cba <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f16:	00007617          	auipc	a2,0x7
    80000f1a:	1ca60613          	addi	a2,a2,458 # 800080e0 <digits+0xa0>
    80000f1e:	85da                	mv	a1,s6
    80000f20:	8556                	mv	a0,s5
    80000f22:	00005097          	auipc	ra,0x5
    80000f26:	76e080e7          	jalr	1902(ra) # 80006690 <snprintf>
    80000f2a:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f2c:	00010c97          	auipc	s9,0x10
    80000f30:	4bcc8c93          	addi	s9,s9,1212 # 800113e8 <locks>
    80000f34:	00011c17          	auipc	s8,0x11
    80000f38:	454c0c13          	addi	s8,s8,1108 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f3c:	84e6                	mv	s1,s9
  int tot = 0;
    80000f3e:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f40:	00007b97          	auipc	s7,0x7
    80000f44:	1c0b8b93          	addi	s7,s7,448 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f48:	00007d17          	auipc	s10,0x7
    80000f4c:	120d0d13          	addi	s10,s10,288 # 80008068 <digits+0x28>
    80000f50:	a01d                	j	80000f76 <statslock+0x92>
      tot += locks[i]->nts;
    80000f52:	0009b603          	ld	a2,0(s3)
    80000f56:	4e1c                	lw	a5,24(a2)
    80000f58:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f5c:	412b05bb          	subw	a1,s6,s2
    80000f60:	012a8533          	add	a0,s5,s2
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	f52080e7          	jalr	-174(ra) # 80000eb6 <snprint_lock>
    80000f6c:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000f70:	04a1                	addi	s1,s1,8
    80000f72:	05848763          	beq	s1,s8,80000fc0 <statslock+0xdc>
    if(locks[i] == 0)
    80000f76:	89a6                	mv	s3,s1
    80000f78:	609c                	ld	a5,0(s1)
    80000f7a:	c3b9                	beqz	a5,80000fc0 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f7c:	0087bd83          	ld	s11,8(a5)
    80000f80:	855e                	mv	a0,s7
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	29c080e7          	jalr	668(ra) # 8000121e <strlen>
    80000f8a:	0005061b          	sext.w	a2,a0
    80000f8e:	85de                	mv	a1,s7
    80000f90:	856e                	mv	a0,s11
    80000f92:	00000097          	auipc	ra,0x0
    80000f96:	1e0080e7          	jalr	480(ra) # 80001172 <strncmp>
    80000f9a:	dd45                	beqz	a0,80000f52 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f9c:	609c                	ld	a5,0(s1)
    80000f9e:	0087bd83          	ld	s11,8(a5)
    80000fa2:	856a                	mv	a0,s10
    80000fa4:	00000097          	auipc	ra,0x0
    80000fa8:	27a080e7          	jalr	634(ra) # 8000121e <strlen>
    80000fac:	0005061b          	sext.w	a2,a0
    80000fb0:	85ea                	mv	a1,s10
    80000fb2:	856e                	mv	a0,s11
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	1be080e7          	jalr	446(ra) # 80001172 <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fbc:	f955                	bnez	a0,80000f70 <statslock+0x8c>
    80000fbe:	bf51                	j	80000f52 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000fc0:	00007617          	auipc	a2,0x7
    80000fc4:	14860613          	addi	a2,a2,328 # 80008108 <digits+0xc8>
    80000fc8:	412b05bb          	subw	a1,s6,s2
    80000fcc:	012a8533          	add	a0,s5,s2
    80000fd0:	00005097          	auipc	ra,0x5
    80000fd4:	6c0080e7          	jalr	1728(ra) # 80006690 <snprintf>
    80000fd8:	012509bb          	addw	s3,a0,s2
    80000fdc:	4b95                	li	s7,5
  int last = 100000000;
    80000fde:	05f5e537          	lui	a0,0x5f5e
    80000fe2:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    80000fe6:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80000fe8:	00010497          	auipc	s1,0x10
    80000fec:	40048493          	addi	s1,s1,1024 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80000ff0:	1f400913          	li	s2,500
    80000ff4:	a881                	j	80001044 <statslock+0x160>
    80000ff6:	2705                	addiw	a4,a4,1
    80000ff8:	06a1                	addi	a3,a3,8
    80000ffa:	03270063          	beq	a4,s2,8000101a <statslock+0x136>
      if(locks[i] == 0)
    80000ffe:	629c                	ld	a5,0(a3)
    80001000:	cf89                	beqz	a5,8000101a <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001002:	4f90                	lw	a2,24(a5)
    80001004:	00359793          	slli	a5,a1,0x3
    80001008:	97a6                	add	a5,a5,s1
    8000100a:	639c                	ld	a5,0(a5)
    8000100c:	4f9c                	lw	a5,24(a5)
    8000100e:	fec7d4e3          	bge	a5,a2,80000ff6 <statslock+0x112>
    80001012:	fea652e3          	bge	a2,a0,80000ff6 <statslock+0x112>
    80001016:	85ba                	mv	a1,a4
    80001018:	bff9                	j	80000ff6 <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    8000101a:	058e                	slli	a1,a1,0x3
    8000101c:	00b48d33          	add	s10,s1,a1
    80001020:	000d3603          	ld	a2,0(s10)
    80001024:	413b05bb          	subw	a1,s6,s3
    80001028:	013a8533          	add	a0,s5,s3
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	e8a080e7          	jalr	-374(ra) # 80000eb6 <snprint_lock>
    80001034:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001038:	000d3783          	ld	a5,0(s10)
    8000103c:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    8000103e:	3bfd                	addiw	s7,s7,-1
    80001040:	000b8663          	beqz	s7,8000104c <statslock+0x168>
  int tot = 0;
    80001044:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    80001046:	8762                	mv	a4,s8
    int top = 0;
    80001048:	85e2                	mv	a1,s8
    8000104a:	bf55                	j	80000ffe <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    8000104c:	86d2                	mv	a3,s4
    8000104e:	00007617          	auipc	a2,0x7
    80001052:	0da60613          	addi	a2,a2,218 # 80008128 <digits+0xe8>
    80001056:	413b05bb          	subw	a1,s6,s3
    8000105a:	013a8533          	add	a0,s5,s3
    8000105e:	00005097          	auipc	ra,0x5
    80001062:	632080e7          	jalr	1586(ra) # 80006690 <snprintf>
    80001066:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    8000106a:	00010517          	auipc	a0,0x10
    8000106e:	35e50513          	addi	a0,a0,862 # 800113c8 <lock_locks>
    80001072:	00000097          	auipc	ra,0x0
    80001076:	d18080e7          	jalr	-744(ra) # 80000d8a <release>
  return n;
}
    8000107a:	854e                	mv	a0,s3
    8000107c:	70a6                	ld	ra,104(sp)
    8000107e:	7406                	ld	s0,96(sp)
    80001080:	64e6                	ld	s1,88(sp)
    80001082:	6946                	ld	s2,80(sp)
    80001084:	69a6                	ld	s3,72(sp)
    80001086:	6a06                	ld	s4,64(sp)
    80001088:	7ae2                	ld	s5,56(sp)
    8000108a:	7b42                	ld	s6,48(sp)
    8000108c:	7ba2                	ld	s7,40(sp)
    8000108e:	7c02                	ld	s8,32(sp)
    80001090:	6ce2                	ld	s9,24(sp)
    80001092:	6d42                	ld	s10,16(sp)
    80001094:	6da2                	ld	s11,8(sp)
    80001096:	6165                	addi	sp,sp,112
    80001098:	8082                	ret

000000008000109a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e422                	sd	s0,8(sp)
    8000109e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010a0:	ca19                	beqz	a2,800010b6 <memset+0x1c>
    800010a2:	87aa                	mv	a5,a0
    800010a4:	1602                	slli	a2,a2,0x20
    800010a6:	9201                	srli	a2,a2,0x20
    800010a8:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010ac:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010b0:	0785                	addi	a5,a5,1
    800010b2:	fee79de3          	bne	a5,a4,800010ac <memset+0x12>
  }
  return dst;
}
    800010b6:	6422                	ld	s0,8(sp)
    800010b8:	0141                	addi	sp,sp,16
    800010ba:	8082                	ret

00000000800010bc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010bc:	1141                	addi	sp,sp,-16
    800010be:	e422                	sd	s0,8(sp)
    800010c0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010c2:	ca05                	beqz	a2,800010f2 <memcmp+0x36>
    800010c4:	fff6069b          	addiw	a3,a2,-1
    800010c8:	1682                	slli	a3,a3,0x20
    800010ca:	9281                	srli	a3,a3,0x20
    800010cc:	0685                	addi	a3,a3,1
    800010ce:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800010d0:	00054783          	lbu	a5,0(a0)
    800010d4:	0005c703          	lbu	a4,0(a1)
    800010d8:	00e79863          	bne	a5,a4,800010e8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    800010dc:	0505                	addi	a0,a0,1
    800010de:	0585                	addi	a1,a1,1
  while(n-- > 0){
    800010e0:	fed518e3          	bne	a0,a3,800010d0 <memcmp+0x14>
  }

  return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	a019                	j	800010ec <memcmp+0x30>
      return *s1 - *s2;
    800010e8:	40e7853b          	subw	a0,a5,a4
}
    800010ec:	6422                	ld	s0,8(sp)
    800010ee:	0141                	addi	sp,sp,16
    800010f0:	8082                	ret
  return 0;
    800010f2:	4501                	li	a0,0
    800010f4:	bfe5                	j	800010ec <memcmp+0x30>

00000000800010f6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800010f6:	1141                	addi	sp,sp,-16
    800010f8:	e422                	sd	s0,8(sp)
    800010fa:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    800010fc:	02a5e563          	bltu	a1,a0,80001126 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001100:	fff6069b          	addiw	a3,a2,-1
    80001104:	ce11                	beqz	a2,80001120 <memmove+0x2a>
    80001106:	1682                	slli	a3,a3,0x20
    80001108:	9281                	srli	a3,a3,0x20
    8000110a:	0685                	addi	a3,a3,1
    8000110c:	96ae                	add	a3,a3,a1
    8000110e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001110:	0585                	addi	a1,a1,1
    80001112:	0785                	addi	a5,a5,1
    80001114:	fff5c703          	lbu	a4,-1(a1)
    80001118:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    8000111c:	fed59ae3          	bne	a1,a3,80001110 <memmove+0x1a>

  return dst;
}
    80001120:	6422                	ld	s0,8(sp)
    80001122:	0141                	addi	sp,sp,16
    80001124:	8082                	ret
  if(s < d && s + n > d){
    80001126:	02061713          	slli	a4,a2,0x20
    8000112a:	9301                	srli	a4,a4,0x20
    8000112c:	00e587b3          	add	a5,a1,a4
    80001130:	fcf578e3          	bgeu	a0,a5,80001100 <memmove+0xa>
    d += n;
    80001134:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80001136:	fff6069b          	addiw	a3,a2,-1
    8000113a:	d27d                	beqz	a2,80001120 <memmove+0x2a>
    8000113c:	02069613          	slli	a2,a3,0x20
    80001140:	9201                	srli	a2,a2,0x20
    80001142:	fff64613          	not	a2,a2
    80001146:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001148:	17fd                	addi	a5,a5,-1
    8000114a:	177d                	addi	a4,a4,-1
    8000114c:	0007c683          	lbu	a3,0(a5)
    80001150:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80001154:	fef61ae3          	bne	a2,a5,80001148 <memmove+0x52>
    80001158:	b7e1                	j	80001120 <memmove+0x2a>

000000008000115a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001162:	00000097          	auipc	ra,0x0
    80001166:	f94080e7          	jalr	-108(ra) # 800010f6 <memmove>
}
    8000116a:	60a2                	ld	ra,8(sp)
    8000116c:	6402                	ld	s0,0(sp)
    8000116e:	0141                	addi	sp,sp,16
    80001170:	8082                	ret

0000000080001172 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001172:	1141                	addi	sp,sp,-16
    80001174:	e422                	sd	s0,8(sp)
    80001176:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001178:	ce11                	beqz	a2,80001194 <strncmp+0x22>
    8000117a:	00054783          	lbu	a5,0(a0)
    8000117e:	cf89                	beqz	a5,80001198 <strncmp+0x26>
    80001180:	0005c703          	lbu	a4,0(a1)
    80001184:	00f71a63          	bne	a4,a5,80001198 <strncmp+0x26>
    n--, p++, q++;
    80001188:	367d                	addiw	a2,a2,-1
    8000118a:	0505                	addi	a0,a0,1
    8000118c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000118e:	f675                	bnez	a2,8000117a <strncmp+0x8>
  if(n == 0)
    return 0;
    80001190:	4501                	li	a0,0
    80001192:	a809                	j	800011a4 <strncmp+0x32>
    80001194:	4501                	li	a0,0
    80001196:	a039                	j	800011a4 <strncmp+0x32>
  if(n == 0)
    80001198:	ca09                	beqz	a2,800011aa <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000119a:	00054503          	lbu	a0,0(a0)
    8000119e:	0005c783          	lbu	a5,0(a1)
    800011a2:	9d1d                	subw	a0,a0,a5
}
    800011a4:	6422                	ld	s0,8(sp)
    800011a6:	0141                	addi	sp,sp,16
    800011a8:	8082                	ret
    return 0;
    800011aa:	4501                	li	a0,0
    800011ac:	bfe5                	j	800011a4 <strncmp+0x32>

00000000800011ae <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011ae:	1141                	addi	sp,sp,-16
    800011b0:	e422                	sd	s0,8(sp)
    800011b2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011b4:	872a                	mv	a4,a0
    800011b6:	8832                	mv	a6,a2
    800011b8:	367d                	addiw	a2,a2,-1
    800011ba:	01005963          	blez	a6,800011cc <strncpy+0x1e>
    800011be:	0705                	addi	a4,a4,1
    800011c0:	0005c783          	lbu	a5,0(a1)
    800011c4:	fef70fa3          	sb	a5,-1(a4)
    800011c8:	0585                	addi	a1,a1,1
    800011ca:	f7f5                	bnez	a5,800011b6 <strncpy+0x8>
    ;
  while(n-- > 0)
    800011cc:	86ba                	mv	a3,a4
    800011ce:	00c05c63          	blez	a2,800011e6 <strncpy+0x38>
    *s++ = 0;
    800011d2:	0685                	addi	a3,a3,1
    800011d4:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800011d8:	40d707bb          	subw	a5,a4,a3
    800011dc:	37fd                	addiw	a5,a5,-1
    800011de:	010787bb          	addw	a5,a5,a6
    800011e2:	fef048e3          	bgtz	a5,800011d2 <strncpy+0x24>
  return os;
}
    800011e6:	6422                	ld	s0,8(sp)
    800011e8:	0141                	addi	sp,sp,16
    800011ea:	8082                	ret

00000000800011ec <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800011ec:	1141                	addi	sp,sp,-16
    800011ee:	e422                	sd	s0,8(sp)
    800011f0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800011f2:	02c05363          	blez	a2,80001218 <safestrcpy+0x2c>
    800011f6:	fff6069b          	addiw	a3,a2,-1
    800011fa:	1682                	slli	a3,a3,0x20
    800011fc:	9281                	srli	a3,a3,0x20
    800011fe:	96ae                	add	a3,a3,a1
    80001200:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001202:	00d58963          	beq	a1,a3,80001214 <safestrcpy+0x28>
    80001206:	0585                	addi	a1,a1,1
    80001208:	0785                	addi	a5,a5,1
    8000120a:	fff5c703          	lbu	a4,-1(a1)
    8000120e:	fee78fa3          	sb	a4,-1(a5)
    80001212:	fb65                	bnez	a4,80001202 <safestrcpy+0x16>
    ;
  *s = 0;
    80001214:	00078023          	sb	zero,0(a5)
  return os;
}
    80001218:	6422                	ld	s0,8(sp)
    8000121a:	0141                	addi	sp,sp,16
    8000121c:	8082                	ret

000000008000121e <strlen>:

int
strlen(const char *s)
{
    8000121e:	1141                	addi	sp,sp,-16
    80001220:	e422                	sd	s0,8(sp)
    80001222:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001224:	00054783          	lbu	a5,0(a0)
    80001228:	cf91                	beqz	a5,80001244 <strlen+0x26>
    8000122a:	0505                	addi	a0,a0,1
    8000122c:	87aa                	mv	a5,a0
    8000122e:	4685                	li	a3,1
    80001230:	9e89                	subw	a3,a3,a0
    80001232:	00f6853b          	addw	a0,a3,a5
    80001236:	0785                	addi	a5,a5,1
    80001238:	fff7c703          	lbu	a4,-1(a5)
    8000123c:	fb7d                	bnez	a4,80001232 <strlen+0x14>
    ;
  return n;
}
    8000123e:	6422                	ld	s0,8(sp)
    80001240:	0141                	addi	sp,sp,16
    80001242:	8082                	ret
  for(n = 0; s[n]; n++)
    80001244:	4501                	li	a0,0
    80001246:	bfe5                	j	8000123e <strlen+0x20>

0000000080001248 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001248:	1141                	addi	sp,sp,-16
    8000124a:	e406                	sd	ra,8(sp)
    8000124c:	e022                	sd	s0,0(sp)
    8000124e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001250:	00001097          	auipc	ra,0x1
    80001254:	a84080e7          	jalr	-1404(ra) # 80001cd4 <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001258:	00008717          	auipc	a4,0x8
    8000125c:	db470713          	addi	a4,a4,-588 # 8000900c <started>
  if(cpuid() == 0){
    80001260:	c139                	beqz	a0,800012a6 <main+0x5e>
    while(started == 0)
    80001262:	431c                	lw	a5,0(a4)
    80001264:	2781                	sext.w	a5,a5
    80001266:	dff5                	beqz	a5,80001262 <main+0x1a>
      ;
    __sync_synchronize();
    80001268:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000126c:	00001097          	auipc	ra,0x1
    80001270:	a68080e7          	jalr	-1432(ra) # 80001cd4 <cpuid>
    80001274:	85aa                	mv	a1,a0
    80001276:	00007517          	auipc	a0,0x7
    8000127a:	eda50513          	addi	a0,a0,-294 # 80008150 <digits+0x110>
    8000127e:	fffff097          	auipc	ra,0xfffff
    80001282:	318080e7          	jalr	792(ra) # 80000596 <printf>
    kvminithart();    // turn on paging
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	186080e7          	jalr	390(ra) # 8000140c <kvminithart>
    trapinithart();   // install kernel trap vector
    8000128e:	00001097          	auipc	ra,0x1
    80001292:	6d2080e7          	jalr	1746(ra) # 80002960 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001296:	00005097          	auipc	ra,0x5
    8000129a:	c8a080e7          	jalr	-886(ra) # 80005f20 <plicinithart>
  }

  scheduler();        
    8000129e:	00001097          	auipc	ra,0x1
    800012a2:	f9a080e7          	jalr	-102(ra) # 80002238 <scheduler>
    consoleinit();
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	1b6080e7          	jalr	438(ra) # 8000045c <consoleinit>
    statsinit();
    800012ae:	00005097          	auipc	ra,0x5
    800012b2:	304080e7          	jalr	772(ra) # 800065b2 <statsinit>
    printfinit();
    800012b6:	fffff097          	auipc	ra,0xfffff
    800012ba:	4c0080e7          	jalr	1216(ra) # 80000776 <printfinit>
    printf("\n");
    800012be:	00007517          	auipc	a0,0x7
    800012c2:	ea250513          	addi	a0,a0,-350 # 80008160 <digits+0x120>
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	2d0080e7          	jalr	720(ra) # 80000596 <printf>
    printf("xv6 kernel is booting\n");
    800012ce:	00007517          	auipc	a0,0x7
    800012d2:	e6a50513          	addi	a0,a0,-406 # 80008138 <digits+0xf8>
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	2c0080e7          	jalr	704(ra) # 80000596 <printf>
    printf("\n");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	e8250513          	addi	a0,a0,-382 # 80008160 <digits+0x120>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	2b0080e7          	jalr	688(ra) # 80000596 <printf>
    kinit();         // physical page allocator
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	802080e7          	jalr	-2046(ra) # 80000af0 <kinit>
    kvminit();       // create kernel page table
    800012f6:	00000097          	auipc	ra,0x0
    800012fa:	242080e7          	jalr	578(ra) # 80001538 <kvminit>
    kvminithart();   // turn on paging
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	10e080e7          	jalr	270(ra) # 8000140c <kvminithart>
    procinit();      // process table
    80001306:	00001097          	auipc	ra,0x1
    8000130a:	8fe080e7          	jalr	-1794(ra) # 80001c04 <procinit>
    trapinit();      // trap vectors
    8000130e:	00001097          	auipc	ra,0x1
    80001312:	62a080e7          	jalr	1578(ra) # 80002938 <trapinit>
    trapinithart();  // install kernel trap vector
    80001316:	00001097          	auipc	ra,0x1
    8000131a:	64a080e7          	jalr	1610(ra) # 80002960 <trapinithart>
    plicinit();      // set up interrupt controller
    8000131e:	00005097          	auipc	ra,0x5
    80001322:	bec080e7          	jalr	-1044(ra) # 80005f0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001326:	00005097          	auipc	ra,0x5
    8000132a:	bfa080e7          	jalr	-1030(ra) # 80005f20 <plicinithart>
    binit();         // buffer cache
    8000132e:	00002097          	auipc	ra,0x2
    80001332:	d74080e7          	jalr	-652(ra) # 800030a2 <binit>
    iinit();         // inode cache
    80001336:	00002097          	auipc	ra,0x2
    8000133a:	402080e7          	jalr	1026(ra) # 80003738 <iinit>
    fileinit();      // file table
    8000133e:	00003097          	auipc	ra,0x3
    80001342:	3ba080e7          	jalr	954(ra) # 800046f8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001346:	00005097          	auipc	ra,0x5
    8000134a:	cfa080e7          	jalr	-774(ra) # 80006040 <virtio_disk_init>
    userinit();      // first user process
    8000134e:	00001097          	auipc	ra,0x1
    80001352:	c7c080e7          	jalr	-900(ra) # 80001fca <userinit>
    __sync_synchronize();
    80001356:	0ff0000f          	fence
    started = 1;
    8000135a:	4785                	li	a5,1
    8000135c:	00008717          	auipc	a4,0x8
    80001360:	caf72823          	sw	a5,-848(a4) # 8000900c <started>
    80001364:	bf2d                	j	8000129e <main+0x56>

0000000080001366 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001366:	7139                	addi	sp,sp,-64
    80001368:	fc06                	sd	ra,56(sp)
    8000136a:	f822                	sd	s0,48(sp)
    8000136c:	f426                	sd	s1,40(sp)
    8000136e:	f04a                	sd	s2,32(sp)
    80001370:	ec4e                	sd	s3,24(sp)
    80001372:	e852                	sd	s4,16(sp)
    80001374:	e456                	sd	s5,8(sp)
    80001376:	e05a                	sd	s6,0(sp)
    80001378:	0080                	addi	s0,sp,64
    8000137a:	84aa                	mv	s1,a0
    8000137c:	89ae                	mv	s3,a1
    8000137e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001380:	57fd                	li	a5,-1
    80001382:	83e9                	srli	a5,a5,0x1a
    80001384:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001386:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001388:	04b7f263          	bgeu	a5,a1,800013cc <walk+0x66>
    panic("walk");
    8000138c:	00007517          	auipc	a0,0x7
    80001390:	ddc50513          	addi	a0,a0,-548 # 80008168 <digits+0x128>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	1b8080e7          	jalr	440(ra) # 8000054c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000139c:	060a8663          	beqz	s5,80001408 <walk+0xa2>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	7b8080e7          	jalr	1976(ra) # 80000b58 <kalloc>
    800013a8:	84aa                	mv	s1,a0
    800013aa:	c529                	beqz	a0,800013f4 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013ac:	6605                	lui	a2,0x1
    800013ae:	4581                	li	a1,0
    800013b0:	00000097          	auipc	ra,0x0
    800013b4:	cea080e7          	jalr	-790(ra) # 8000109a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013b8:	00c4d793          	srli	a5,s1,0xc
    800013bc:	07aa                	slli	a5,a5,0xa
    800013be:	0017e793          	ori	a5,a5,1
    800013c2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013c6:	3a5d                	addiw	s4,s4,-9
    800013c8:	036a0063          	beq	s4,s6,800013e8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800013cc:	0149d933          	srl	s2,s3,s4
    800013d0:	1ff97913          	andi	s2,s2,511
    800013d4:	090e                	slli	s2,s2,0x3
    800013d6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800013d8:	00093483          	ld	s1,0(s2)
    800013dc:	0014f793          	andi	a5,s1,1
    800013e0:	dfd5                	beqz	a5,8000139c <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800013e2:	80a9                	srli	s1,s1,0xa
    800013e4:	04b2                	slli	s1,s1,0xc
    800013e6:	b7c5                	j	800013c6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800013e8:	00c9d513          	srli	a0,s3,0xc
    800013ec:	1ff57513          	andi	a0,a0,511
    800013f0:	050e                	slli	a0,a0,0x3
    800013f2:	9526                	add	a0,a0,s1
}
    800013f4:	70e2                	ld	ra,56(sp)
    800013f6:	7442                	ld	s0,48(sp)
    800013f8:	74a2                	ld	s1,40(sp)
    800013fa:	7902                	ld	s2,32(sp)
    800013fc:	69e2                	ld	s3,24(sp)
    800013fe:	6a42                	ld	s4,16(sp)
    80001400:	6aa2                	ld	s5,8(sp)
    80001402:	6b02                	ld	s6,0(sp)
    80001404:	6121                	addi	sp,sp,64
    80001406:	8082                	ret
        return 0;
    80001408:	4501                	li	a0,0
    8000140a:	b7ed                	j	800013f4 <walk+0x8e>

000000008000140c <kvminithart>:
{
    8000140c:	1141                	addi	sp,sp,-16
    8000140e:	e422                	sd	s0,8(sp)
    80001410:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001412:	00008797          	auipc	a5,0x8
    80001416:	bfe7b783          	ld	a5,-1026(a5) # 80009010 <kernel_pagetable>
    8000141a:	83b1                	srli	a5,a5,0xc
    8000141c:	577d                	li	a4,-1
    8000141e:	177e                	slli	a4,a4,0x3f
    80001420:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001422:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001426:	12000073          	sfence.vma
}
    8000142a:	6422                	ld	s0,8(sp)
    8000142c:	0141                	addi	sp,sp,16
    8000142e:	8082                	ret

0000000080001430 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001430:	57fd                	li	a5,-1
    80001432:	83e9                	srli	a5,a5,0x1a
    80001434:	00b7f463          	bgeu	a5,a1,8000143c <walkaddr+0xc>
    return 0;
    80001438:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000143a:	8082                	ret
{
    8000143c:	1141                	addi	sp,sp,-16
    8000143e:	e406                	sd	ra,8(sp)
    80001440:	e022                	sd	s0,0(sp)
    80001442:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001444:	4601                	li	a2,0
    80001446:	00000097          	auipc	ra,0x0
    8000144a:	f20080e7          	jalr	-224(ra) # 80001366 <walk>
  if(pte == 0)
    8000144e:	c105                	beqz	a0,8000146e <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001450:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001452:	0117f693          	andi	a3,a5,17
    80001456:	4745                	li	a4,17
    return 0;
    80001458:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000145a:	00e68663          	beq	a3,a4,80001466 <walkaddr+0x36>
}
    8000145e:	60a2                	ld	ra,8(sp)
    80001460:	6402                	ld	s0,0(sp)
    80001462:	0141                	addi	sp,sp,16
    80001464:	8082                	ret
  pa = PTE2PA(*pte);
    80001466:	83a9                	srli	a5,a5,0xa
    80001468:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000146c:	bfcd                	j	8000145e <walkaddr+0x2e>
    return 0;
    8000146e:	4501                	li	a0,0
    80001470:	b7fd                	j	8000145e <walkaddr+0x2e>

0000000080001472 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001472:	715d                	addi	sp,sp,-80
    80001474:	e486                	sd	ra,72(sp)
    80001476:	e0a2                	sd	s0,64(sp)
    80001478:	fc26                	sd	s1,56(sp)
    8000147a:	f84a                	sd	s2,48(sp)
    8000147c:	f44e                	sd	s3,40(sp)
    8000147e:	f052                	sd	s4,32(sp)
    80001480:	ec56                	sd	s5,24(sp)
    80001482:	e85a                	sd	s6,16(sp)
    80001484:	e45e                	sd	s7,8(sp)
    80001486:	0880                	addi	s0,sp,80
    80001488:	8aaa                	mv	s5,a0
    8000148a:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000148c:	777d                	lui	a4,0xfffff
    8000148e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001492:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    80001496:	99ae                	add	s3,s3,a1
    80001498:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000149c:	893e                	mv	s2,a5
    8000149e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014a2:	6b85                	lui	s7,0x1
    800014a4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014a8:	4605                	li	a2,1
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	eb8080e7          	jalr	-328(ra) # 80001366 <walk>
    800014b6:	c51d                	beqz	a0,800014e4 <mappages+0x72>
    if(*pte & PTE_V)
    800014b8:	611c                	ld	a5,0(a0)
    800014ba:	8b85                	andi	a5,a5,1
    800014bc:	ef81                	bnez	a5,800014d4 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014be:	80b1                	srli	s1,s1,0xc
    800014c0:	04aa                	slli	s1,s1,0xa
    800014c2:	0164e4b3          	or	s1,s1,s6
    800014c6:	0014e493          	ori	s1,s1,1
    800014ca:	e104                	sd	s1,0(a0)
    if(a == last)
    800014cc:	03390863          	beq	s2,s3,800014fc <mappages+0x8a>
    a += PGSIZE;
    800014d0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800014d2:	bfc9                	j	800014a4 <mappages+0x32>
      panic("remap");
    800014d4:	00007517          	auipc	a0,0x7
    800014d8:	c9c50513          	addi	a0,a0,-868 # 80008170 <digits+0x130>
    800014dc:	fffff097          	auipc	ra,0xfffff
    800014e0:	070080e7          	jalr	112(ra) # 8000054c <panic>
      return -1;
    800014e4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800014e6:	60a6                	ld	ra,72(sp)
    800014e8:	6406                	ld	s0,64(sp)
    800014ea:	74e2                	ld	s1,56(sp)
    800014ec:	7942                	ld	s2,48(sp)
    800014ee:	79a2                	ld	s3,40(sp)
    800014f0:	7a02                	ld	s4,32(sp)
    800014f2:	6ae2                	ld	s5,24(sp)
    800014f4:	6b42                	ld	s6,16(sp)
    800014f6:	6ba2                	ld	s7,8(sp)
    800014f8:	6161                	addi	sp,sp,80
    800014fa:	8082                	ret
  return 0;
    800014fc:	4501                	li	a0,0
    800014fe:	b7e5                	j	800014e6 <mappages+0x74>

0000000080001500 <kvmmap>:
{
    80001500:	1141                	addi	sp,sp,-16
    80001502:	e406                	sd	ra,8(sp)
    80001504:	e022                	sd	s0,0(sp)
    80001506:	0800                	addi	s0,sp,16
    80001508:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000150a:	86ae                	mv	a3,a1
    8000150c:	85aa                	mv	a1,a0
    8000150e:	00008517          	auipc	a0,0x8
    80001512:	b0253503          	ld	a0,-1278(a0) # 80009010 <kernel_pagetable>
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	f5c080e7          	jalr	-164(ra) # 80001472 <mappages>
    8000151e:	e509                	bnez	a0,80001528 <kvmmap+0x28>
}
    80001520:	60a2                	ld	ra,8(sp)
    80001522:	6402                	ld	s0,0(sp)
    80001524:	0141                	addi	sp,sp,16
    80001526:	8082                	ret
    panic("kvmmap");
    80001528:	00007517          	auipc	a0,0x7
    8000152c:	c5050513          	addi	a0,a0,-944 # 80008178 <digits+0x138>
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	01c080e7          	jalr	28(ra) # 8000054c <panic>

0000000080001538 <kvminit>:
{
    80001538:	1101                	addi	sp,sp,-32
    8000153a:	ec06                	sd	ra,24(sp)
    8000153c:	e822                	sd	s0,16(sp)
    8000153e:	e426                	sd	s1,8(sp)
    80001540:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001542:	fffff097          	auipc	ra,0xfffff
    80001546:	616080e7          	jalr	1558(ra) # 80000b58 <kalloc>
    8000154a:	00008717          	auipc	a4,0x8
    8000154e:	aca73323          	sd	a0,-1338(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001552:	6605                	lui	a2,0x1
    80001554:	4581                	li	a1,0
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	b44080e7          	jalr	-1212(ra) # 8000109a <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000155e:	4699                	li	a3,6
    80001560:	6605                	lui	a2,0x1
    80001562:	100005b7          	lui	a1,0x10000
    80001566:	10000537          	lui	a0,0x10000
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	f96080e7          	jalr	-106(ra) # 80001500 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001572:	4699                	li	a3,6
    80001574:	6605                	lui	a2,0x1
    80001576:	100015b7          	lui	a1,0x10001
    8000157a:	10001537          	lui	a0,0x10001
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	f82080e7          	jalr	-126(ra) # 80001500 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001586:	4699                	li	a3,6
    80001588:	00400637          	lui	a2,0x400
    8000158c:	0c0005b7          	lui	a1,0xc000
    80001590:	0c000537          	lui	a0,0xc000
    80001594:	00000097          	auipc	ra,0x0
    80001598:	f6c080e7          	jalr	-148(ra) # 80001500 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000159c:	00007497          	auipc	s1,0x7
    800015a0:	a6448493          	addi	s1,s1,-1436 # 80008000 <etext>
    800015a4:	46a9                	li	a3,10
    800015a6:	80007617          	auipc	a2,0x80007
    800015aa:	a5a60613          	addi	a2,a2,-1446 # 8000 <_entry-0x7fff8000>
    800015ae:	4585                	li	a1,1
    800015b0:	05fe                	slli	a1,a1,0x1f
    800015b2:	852e                	mv	a0,a1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f4c080e7          	jalr	-180(ra) # 80001500 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015bc:	4699                	li	a3,6
    800015be:	4645                	li	a2,17
    800015c0:	066e                	slli	a2,a2,0x1b
    800015c2:	8e05                	sub	a2,a2,s1
    800015c4:	85a6                	mv	a1,s1
    800015c6:	8526                	mv	a0,s1
    800015c8:	00000097          	auipc	ra,0x0
    800015cc:	f38080e7          	jalr	-200(ra) # 80001500 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800015d0:	46a9                	li	a3,10
    800015d2:	6605                	lui	a2,0x1
    800015d4:	00006597          	auipc	a1,0x6
    800015d8:	a2c58593          	addi	a1,a1,-1492 # 80007000 <_trampoline>
    800015dc:	04000537          	lui	a0,0x4000
    800015e0:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    800015e2:	0532                	slli	a0,a0,0xc
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	f1c080e7          	jalr	-228(ra) # 80001500 <kvmmap>
}
    800015ec:	60e2                	ld	ra,24(sp)
    800015ee:	6442                	ld	s0,16(sp)
    800015f0:	64a2                	ld	s1,8(sp)
    800015f2:	6105                	addi	sp,sp,32
    800015f4:	8082                	ret

00000000800015f6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800015f6:	715d                	addi	sp,sp,-80
    800015f8:	e486                	sd	ra,72(sp)
    800015fa:	e0a2                	sd	s0,64(sp)
    800015fc:	fc26                	sd	s1,56(sp)
    800015fe:	f84a                	sd	s2,48(sp)
    80001600:	f44e                	sd	s3,40(sp)
    80001602:	f052                	sd	s4,32(sp)
    80001604:	ec56                	sd	s5,24(sp)
    80001606:	e85a                	sd	s6,16(sp)
    80001608:	e45e                	sd	s7,8(sp)
    8000160a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000160c:	03459793          	slli	a5,a1,0x34
    80001610:	e795                	bnez	a5,8000163c <uvmunmap+0x46>
    80001612:	8a2a                	mv	s4,a0
    80001614:	892e                	mv	s2,a1
    80001616:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001618:	0632                	slli	a2,a2,0xc
    8000161a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000161e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001620:	6b05                	lui	s6,0x1
    80001622:	0735e263          	bltu	a1,s3,80001686 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000163c:	00007517          	auipc	a0,0x7
    80001640:	b4450513          	addi	a0,a0,-1212 # 80008180 <digits+0x140>
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	f08080e7          	jalr	-248(ra) # 8000054c <panic>
      panic("uvmunmap: walk");
    8000164c:	00007517          	auipc	a0,0x7
    80001650:	b4c50513          	addi	a0,a0,-1204 # 80008198 <digits+0x158>
    80001654:	fffff097          	auipc	ra,0xfffff
    80001658:	ef8080e7          	jalr	-264(ra) # 8000054c <panic>
      panic("uvmunmap: not mapped");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b4c50513          	addi	a0,a0,-1204 # 800081a8 <digits+0x168>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	ee8080e7          	jalr	-280(ra) # 8000054c <panic>
      panic("uvmunmap: not a leaf");
    8000166c:	00007517          	auipc	a0,0x7
    80001670:	b5450513          	addi	a0,a0,-1196 # 800081c0 <digits+0x180>
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	ed8080e7          	jalr	-296(ra) # 8000054c <panic>
    *pte = 0;
    8000167c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001680:	995a                	add	s2,s2,s6
    80001682:	fb3972e3          	bgeu	s2,s3,80001626 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001686:	4601                	li	a2,0
    80001688:	85ca                	mv	a1,s2
    8000168a:	8552                	mv	a0,s4
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	cda080e7          	jalr	-806(ra) # 80001366 <walk>
    80001694:	84aa                	mv	s1,a0
    80001696:	d95d                	beqz	a0,8000164c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001698:	6108                	ld	a0,0(a0)
    8000169a:	00157793          	andi	a5,a0,1
    8000169e:	dfdd                	beqz	a5,8000165c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016a0:	3ff57793          	andi	a5,a0,1023
    800016a4:	fd7784e3          	beq	a5,s7,8000166c <uvmunmap+0x76>
    if(do_free){
    800016a8:	fc0a8ae3          	beqz	s5,8000167c <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016ac:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016ae:	0532                	slli	a0,a0,0xc
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	368080e7          	jalr	872(ra) # 80000a18 <kfree>
    800016b8:	b7d1                	j	8000167c <uvmunmap+0x86>

00000000800016ba <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016ba:	1101                	addi	sp,sp,-32
    800016bc:	ec06                	sd	ra,24(sp)
    800016be:	e822                	sd	s0,16(sp)
    800016c0:	e426                	sd	s1,8(sp)
    800016c2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	494080e7          	jalr	1172(ra) # 80000b58 <kalloc>
    800016cc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800016ce:	c519                	beqz	a0,800016dc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800016d0:	6605                	lui	a2,0x1
    800016d2:	4581                	li	a1,0
    800016d4:	00000097          	auipc	ra,0x0
    800016d8:	9c6080e7          	jalr	-1594(ra) # 8000109a <memset>
  return pagetable;
}
    800016dc:	8526                	mv	a0,s1
    800016de:	60e2                	ld	ra,24(sp)
    800016e0:	6442                	ld	s0,16(sp)
    800016e2:	64a2                	ld	s1,8(sp)
    800016e4:	6105                	addi	sp,sp,32
    800016e6:	8082                	ret

00000000800016e8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800016e8:	7179                	addi	sp,sp,-48
    800016ea:	f406                	sd	ra,40(sp)
    800016ec:	f022                	sd	s0,32(sp)
    800016ee:	ec26                	sd	s1,24(sp)
    800016f0:	e84a                	sd	s2,16(sp)
    800016f2:	e44e                	sd	s3,8(sp)
    800016f4:	e052                	sd	s4,0(sp)
    800016f6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800016f8:	6785                	lui	a5,0x1
    800016fa:	04f67863          	bgeu	a2,a5,8000174a <uvminit+0x62>
    800016fe:	8a2a                	mv	s4,a0
    80001700:	89ae                	mv	s3,a1
    80001702:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001704:	fffff097          	auipc	ra,0xfffff
    80001708:	454080e7          	jalr	1108(ra) # 80000b58 <kalloc>
    8000170c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000170e:	6605                	lui	a2,0x1
    80001710:	4581                	li	a1,0
    80001712:	00000097          	auipc	ra,0x0
    80001716:	988080e7          	jalr	-1656(ra) # 8000109a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000171a:	4779                	li	a4,30
    8000171c:	86ca                	mv	a3,s2
    8000171e:	6605                	lui	a2,0x1
    80001720:	4581                	li	a1,0
    80001722:	8552                	mv	a0,s4
    80001724:	00000097          	auipc	ra,0x0
    80001728:	d4e080e7          	jalr	-690(ra) # 80001472 <mappages>
  memmove(mem, src, sz);
    8000172c:	8626                	mv	a2,s1
    8000172e:	85ce                	mv	a1,s3
    80001730:	854a                	mv	a0,s2
    80001732:	00000097          	auipc	ra,0x0
    80001736:	9c4080e7          	jalr	-1596(ra) # 800010f6 <memmove>
}
    8000173a:	70a2                	ld	ra,40(sp)
    8000173c:	7402                	ld	s0,32(sp)
    8000173e:	64e2                	ld	s1,24(sp)
    80001740:	6942                	ld	s2,16(sp)
    80001742:	69a2                	ld	s3,8(sp)
    80001744:	6a02                	ld	s4,0(sp)
    80001746:	6145                	addi	sp,sp,48
    80001748:	8082                	ret
    panic("inituvm: more than a page");
    8000174a:	00007517          	auipc	a0,0x7
    8000174e:	a8e50513          	addi	a0,a0,-1394 # 800081d8 <digits+0x198>
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	dfa080e7          	jalr	-518(ra) # 8000054c <panic>

000000008000175a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000175a:	1101                	addi	sp,sp,-32
    8000175c:	ec06                	sd	ra,24(sp)
    8000175e:	e822                	sd	s0,16(sp)
    80001760:	e426                	sd	s1,8(sp)
    80001762:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001764:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001766:	00b67d63          	bgeu	a2,a1,80001780 <uvmdealloc+0x26>
    8000176a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000176c:	6785                	lui	a5,0x1
    8000176e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001770:	00f60733          	add	a4,a2,a5
    80001774:	76fd                	lui	a3,0xfffff
    80001776:	8f75                	and	a4,a4,a3
    80001778:	97ae                	add	a5,a5,a1
    8000177a:	8ff5                	and	a5,a5,a3
    8000177c:	00f76863          	bltu	a4,a5,8000178c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001780:	8526                	mv	a0,s1
    80001782:	60e2                	ld	ra,24(sp)
    80001784:	6442                	ld	s0,16(sp)
    80001786:	64a2                	ld	s1,8(sp)
    80001788:	6105                	addi	sp,sp,32
    8000178a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000178c:	8f99                	sub	a5,a5,a4
    8000178e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001790:	4685                	li	a3,1
    80001792:	0007861b          	sext.w	a2,a5
    80001796:	85ba                	mv	a1,a4
    80001798:	00000097          	auipc	ra,0x0
    8000179c:	e5e080e7          	jalr	-418(ra) # 800015f6 <uvmunmap>
    800017a0:	b7c5                	j	80001780 <uvmdealloc+0x26>

00000000800017a2 <uvmalloc>:
  if(newsz < oldsz)
    800017a2:	0ab66163          	bltu	a2,a1,80001844 <uvmalloc+0xa2>
{
    800017a6:	7139                	addi	sp,sp,-64
    800017a8:	fc06                	sd	ra,56(sp)
    800017aa:	f822                	sd	s0,48(sp)
    800017ac:	f426                	sd	s1,40(sp)
    800017ae:	f04a                	sd	s2,32(sp)
    800017b0:	ec4e                	sd	s3,24(sp)
    800017b2:	e852                	sd	s4,16(sp)
    800017b4:	e456                	sd	s5,8(sp)
    800017b6:	0080                	addi	s0,sp,64
    800017b8:	8aaa                	mv	s5,a0
    800017ba:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017bc:	6785                	lui	a5,0x1
    800017be:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017c0:	95be                	add	a1,a1,a5
    800017c2:	77fd                	lui	a5,0xfffff
    800017c4:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017c8:	08c9f063          	bgeu	s3,a2,80001848 <uvmalloc+0xa6>
    800017cc:	894e                	mv	s2,s3
    mem = kalloc();
    800017ce:	fffff097          	auipc	ra,0xfffff
    800017d2:	38a080e7          	jalr	906(ra) # 80000b58 <kalloc>
    800017d6:	84aa                	mv	s1,a0
    if(mem == 0){
    800017d8:	c51d                	beqz	a0,80001806 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800017da:	6605                	lui	a2,0x1
    800017dc:	4581                	li	a1,0
    800017de:	00000097          	auipc	ra,0x0
    800017e2:	8bc080e7          	jalr	-1860(ra) # 8000109a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800017e6:	4779                	li	a4,30
    800017e8:	86a6                	mv	a3,s1
    800017ea:	6605                	lui	a2,0x1
    800017ec:	85ca                	mv	a1,s2
    800017ee:	8556                	mv	a0,s5
    800017f0:	00000097          	auipc	ra,0x0
    800017f4:	c82080e7          	jalr	-894(ra) # 80001472 <mappages>
    800017f8:	e905                	bnez	a0,80001828 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017fa:	6785                	lui	a5,0x1
    800017fc:	993e                	add	s2,s2,a5
    800017fe:	fd4968e3          	bltu	s2,s4,800017ce <uvmalloc+0x2c>
  return newsz;
    80001802:	8552                	mv	a0,s4
    80001804:	a809                	j	80001816 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001806:	864e                	mv	a2,s3
    80001808:	85ca                	mv	a1,s2
    8000180a:	8556                	mv	a0,s5
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	f4e080e7          	jalr	-178(ra) # 8000175a <uvmdealloc>
      return 0;
    80001814:	4501                	li	a0,0
}
    80001816:	70e2                	ld	ra,56(sp)
    80001818:	7442                	ld	s0,48(sp)
    8000181a:	74a2                	ld	s1,40(sp)
    8000181c:	7902                	ld	s2,32(sp)
    8000181e:	69e2                	ld	s3,24(sp)
    80001820:	6a42                	ld	s4,16(sp)
    80001822:	6aa2                	ld	s5,8(sp)
    80001824:	6121                	addi	sp,sp,64
    80001826:	8082                	ret
      kfree(mem);
    80001828:	8526                	mv	a0,s1
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	1ee080e7          	jalr	494(ra) # 80000a18 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001832:	864e                	mv	a2,s3
    80001834:	85ca                	mv	a1,s2
    80001836:	8556                	mv	a0,s5
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	f22080e7          	jalr	-222(ra) # 8000175a <uvmdealloc>
      return 0;
    80001840:	4501                	li	a0,0
    80001842:	bfd1                	j	80001816 <uvmalloc+0x74>
    return oldsz;
    80001844:	852e                	mv	a0,a1
}
    80001846:	8082                	ret
  return newsz;
    80001848:	8532                	mv	a0,a2
    8000184a:	b7f1                	j	80001816 <uvmalloc+0x74>

000000008000184c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000184c:	7179                	addi	sp,sp,-48
    8000184e:	f406                	sd	ra,40(sp)
    80001850:	f022                	sd	s0,32(sp)
    80001852:	ec26                	sd	s1,24(sp)
    80001854:	e84a                	sd	s2,16(sp)
    80001856:	e44e                	sd	s3,8(sp)
    80001858:	e052                	sd	s4,0(sp)
    8000185a:	1800                	addi	s0,sp,48
    8000185c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000185e:	84aa                	mv	s1,a0
    80001860:	6905                	lui	s2,0x1
    80001862:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001864:	4985                	li	s3,1
    80001866:	a829                	j	80001880 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001868:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000186a:	00c79513          	slli	a0,a5,0xc
    8000186e:	00000097          	auipc	ra,0x0
    80001872:	fde080e7          	jalr	-34(ra) # 8000184c <freewalk>
      pagetable[i] = 0;
    80001876:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000187a:	04a1                	addi	s1,s1,8
    8000187c:	03248163          	beq	s1,s2,8000189e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001880:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001882:	00f7f713          	andi	a4,a5,15
    80001886:	ff3701e3          	beq	a4,s3,80001868 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000188a:	8b85                	andi	a5,a5,1
    8000188c:	d7fd                	beqz	a5,8000187a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000188e:	00007517          	auipc	a0,0x7
    80001892:	96a50513          	addi	a0,a0,-1686 # 800081f8 <digits+0x1b8>
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	cb6080e7          	jalr	-842(ra) # 8000054c <panic>
    }
  }
  kfree((void*)pagetable);
    8000189e:	8552                	mv	a0,s4
    800018a0:	fffff097          	auipc	ra,0xfffff
    800018a4:	178080e7          	jalr	376(ra) # 80000a18 <kfree>
}
    800018a8:	70a2                	ld	ra,40(sp)
    800018aa:	7402                	ld	s0,32(sp)
    800018ac:	64e2                	ld	s1,24(sp)
    800018ae:	6942                	ld	s2,16(sp)
    800018b0:	69a2                	ld	s3,8(sp)
    800018b2:	6a02                	ld	s4,0(sp)
    800018b4:	6145                	addi	sp,sp,48
    800018b6:	8082                	ret

00000000800018b8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018b8:	1101                	addi	sp,sp,-32
    800018ba:	ec06                	sd	ra,24(sp)
    800018bc:	e822                	sd	s0,16(sp)
    800018be:	e426                	sd	s1,8(sp)
    800018c0:	1000                	addi	s0,sp,32
    800018c2:	84aa                	mv	s1,a0
  if(sz > 0)
    800018c4:	e999                	bnez	a1,800018da <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018c6:	8526                	mv	a0,s1
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	f84080e7          	jalr	-124(ra) # 8000184c <freewalk>
}
    800018d0:	60e2                	ld	ra,24(sp)
    800018d2:	6442                	ld	s0,16(sp)
    800018d4:	64a2                	ld	s1,8(sp)
    800018d6:	6105                	addi	sp,sp,32
    800018d8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800018da:	6785                	lui	a5,0x1
    800018dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800018de:	95be                	add	a1,a1,a5
    800018e0:	4685                	li	a3,1
    800018e2:	00c5d613          	srli	a2,a1,0xc
    800018e6:	4581                	li	a1,0
    800018e8:	00000097          	auipc	ra,0x0
    800018ec:	d0e080e7          	jalr	-754(ra) # 800015f6 <uvmunmap>
    800018f0:	bfd9                	j	800018c6 <uvmfree+0xe>

00000000800018f2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800018f2:	c679                	beqz	a2,800019c0 <uvmcopy+0xce>
{
    800018f4:	715d                	addi	sp,sp,-80
    800018f6:	e486                	sd	ra,72(sp)
    800018f8:	e0a2                	sd	s0,64(sp)
    800018fa:	fc26                	sd	s1,56(sp)
    800018fc:	f84a                	sd	s2,48(sp)
    800018fe:	f44e                	sd	s3,40(sp)
    80001900:	f052                	sd	s4,32(sp)
    80001902:	ec56                	sd	s5,24(sp)
    80001904:	e85a                	sd	s6,16(sp)
    80001906:	e45e                	sd	s7,8(sp)
    80001908:	0880                	addi	s0,sp,80
    8000190a:	8b2a                	mv	s6,a0
    8000190c:	8aae                	mv	s5,a1
    8000190e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001910:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001912:	4601                	li	a2,0
    80001914:	85ce                	mv	a1,s3
    80001916:	855a                	mv	a0,s6
    80001918:	00000097          	auipc	ra,0x0
    8000191c:	a4e080e7          	jalr	-1458(ra) # 80001366 <walk>
    80001920:	c531                	beqz	a0,8000196c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001922:	6118                	ld	a4,0(a0)
    80001924:	00177793          	andi	a5,a4,1
    80001928:	cbb1                	beqz	a5,8000197c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000192a:	00a75593          	srli	a1,a4,0xa
    8000192e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001932:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	222080e7          	jalr	546(ra) # 80000b58 <kalloc>
    8000193e:	892a                	mv	s2,a0
    80001940:	c939                	beqz	a0,80001996 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001942:	6605                	lui	a2,0x1
    80001944:	85de                	mv	a1,s7
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	7b0080e7          	jalr	1968(ra) # 800010f6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000194e:	8726                	mv	a4,s1
    80001950:	86ca                	mv	a3,s2
    80001952:	6605                	lui	a2,0x1
    80001954:	85ce                	mv	a1,s3
    80001956:	8556                	mv	a0,s5
    80001958:	00000097          	auipc	ra,0x0
    8000195c:	b1a080e7          	jalr	-1254(ra) # 80001472 <mappages>
    80001960:	e515                	bnez	a0,8000198c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001962:	6785                	lui	a5,0x1
    80001964:	99be                	add	s3,s3,a5
    80001966:	fb49e6e3          	bltu	s3,s4,80001912 <uvmcopy+0x20>
    8000196a:	a081                	j	800019aa <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	89c50513          	addi	a0,a0,-1892 # 80008208 <digits+0x1c8>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	bd8080e7          	jalr	-1064(ra) # 8000054c <panic>
      panic("uvmcopy: page not present");
    8000197c:	00007517          	auipc	a0,0x7
    80001980:	8ac50513          	addi	a0,a0,-1876 # 80008228 <digits+0x1e8>
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	bc8080e7          	jalr	-1080(ra) # 8000054c <panic>
      kfree(mem);
    8000198c:	854a                	mv	a0,s2
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	08a080e7          	jalr	138(ra) # 80000a18 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001996:	4685                	li	a3,1
    80001998:	00c9d613          	srli	a2,s3,0xc
    8000199c:	4581                	li	a1,0
    8000199e:	8556                	mv	a0,s5
    800019a0:	00000097          	auipc	ra,0x0
    800019a4:	c56080e7          	jalr	-938(ra) # 800015f6 <uvmunmap>
  return -1;
    800019a8:	557d                	li	a0,-1
}
    800019aa:	60a6                	ld	ra,72(sp)
    800019ac:	6406                	ld	s0,64(sp)
    800019ae:	74e2                	ld	s1,56(sp)
    800019b0:	7942                	ld	s2,48(sp)
    800019b2:	79a2                	ld	s3,40(sp)
    800019b4:	7a02                	ld	s4,32(sp)
    800019b6:	6ae2                	ld	s5,24(sp)
    800019b8:	6b42                	ld	s6,16(sp)
    800019ba:	6ba2                	ld	s7,8(sp)
    800019bc:	6161                	addi	sp,sp,80
    800019be:	8082                	ret
  return 0;
    800019c0:	4501                	li	a0,0
}
    800019c2:	8082                	ret

00000000800019c4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019c4:	1141                	addi	sp,sp,-16
    800019c6:	e406                	sd	ra,8(sp)
    800019c8:	e022                	sd	s0,0(sp)
    800019ca:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019cc:	4601                	li	a2,0
    800019ce:	00000097          	auipc	ra,0x0
    800019d2:	998080e7          	jalr	-1640(ra) # 80001366 <walk>
  if(pte == 0)
    800019d6:	c901                	beqz	a0,800019e6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800019d8:	611c                	ld	a5,0(a0)
    800019da:	9bbd                	andi	a5,a5,-17
    800019dc:	e11c                	sd	a5,0(a0)
}
    800019de:	60a2                	ld	ra,8(sp)
    800019e0:	6402                	ld	s0,0(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret
    panic("uvmclear");
    800019e6:	00007517          	auipc	a0,0x7
    800019ea:	86250513          	addi	a0,a0,-1950 # 80008248 <digits+0x208>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	b5e080e7          	jalr	-1186(ra) # 8000054c <panic>

00000000800019f6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800019f6:	c6bd                	beqz	a3,80001a64 <copyout+0x6e>
{
    800019f8:	715d                	addi	sp,sp,-80
    800019fa:	e486                	sd	ra,72(sp)
    800019fc:	e0a2                	sd	s0,64(sp)
    800019fe:	fc26                	sd	s1,56(sp)
    80001a00:	f84a                	sd	s2,48(sp)
    80001a02:	f44e                	sd	s3,40(sp)
    80001a04:	f052                	sd	s4,32(sp)
    80001a06:	ec56                	sd	s5,24(sp)
    80001a08:	e85a                	sd	s6,16(sp)
    80001a0a:	e45e                	sd	s7,8(sp)
    80001a0c:	e062                	sd	s8,0(sp)
    80001a0e:	0880                	addi	s0,sp,80
    80001a10:	8b2a                	mv	s6,a0
    80001a12:	8c2e                	mv	s8,a1
    80001a14:	8a32                	mv	s4,a2
    80001a16:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a18:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a1a:	6a85                	lui	s5,0x1
    80001a1c:	a015                	j	80001a40 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a1e:	9562                	add	a0,a0,s8
    80001a20:	0004861b          	sext.w	a2,s1
    80001a24:	85d2                	mv	a1,s4
    80001a26:	41250533          	sub	a0,a0,s2
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	6cc080e7          	jalr	1740(ra) # 800010f6 <memmove>

    len -= n;
    80001a32:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a36:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a38:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a3c:	02098263          	beqz	s3,80001a60 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a40:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a44:	85ca                	mv	a1,s2
    80001a46:	855a                	mv	a0,s6
    80001a48:	00000097          	auipc	ra,0x0
    80001a4c:	9e8080e7          	jalr	-1560(ra) # 80001430 <walkaddr>
    if(pa0 == 0)
    80001a50:	cd01                	beqz	a0,80001a68 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a52:	418904b3          	sub	s1,s2,s8
    80001a56:	94d6                	add	s1,s1,s5
    80001a58:	fc99f3e3          	bgeu	s3,s1,80001a1e <copyout+0x28>
    80001a5c:	84ce                	mv	s1,s3
    80001a5e:	b7c1                	j	80001a1e <copyout+0x28>
  }
  return 0;
    80001a60:	4501                	li	a0,0
    80001a62:	a021                	j	80001a6a <copyout+0x74>
    80001a64:	4501                	li	a0,0
}
    80001a66:	8082                	ret
      return -1;
    80001a68:	557d                	li	a0,-1
}
    80001a6a:	60a6                	ld	ra,72(sp)
    80001a6c:	6406                	ld	s0,64(sp)
    80001a6e:	74e2                	ld	s1,56(sp)
    80001a70:	7942                	ld	s2,48(sp)
    80001a72:	79a2                	ld	s3,40(sp)
    80001a74:	7a02                	ld	s4,32(sp)
    80001a76:	6ae2                	ld	s5,24(sp)
    80001a78:	6b42                	ld	s6,16(sp)
    80001a7a:	6ba2                	ld	s7,8(sp)
    80001a7c:	6c02                	ld	s8,0(sp)
    80001a7e:	6161                	addi	sp,sp,80
    80001a80:	8082                	ret

0000000080001a82 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a82:	caa5                	beqz	a3,80001af2 <copyin+0x70>
{
    80001a84:	715d                	addi	sp,sp,-80
    80001a86:	e486                	sd	ra,72(sp)
    80001a88:	e0a2                	sd	s0,64(sp)
    80001a8a:	fc26                	sd	s1,56(sp)
    80001a8c:	f84a                	sd	s2,48(sp)
    80001a8e:	f44e                	sd	s3,40(sp)
    80001a90:	f052                	sd	s4,32(sp)
    80001a92:	ec56                	sd	s5,24(sp)
    80001a94:	e85a                	sd	s6,16(sp)
    80001a96:	e45e                	sd	s7,8(sp)
    80001a98:	e062                	sd	s8,0(sp)
    80001a9a:	0880                	addi	s0,sp,80
    80001a9c:	8b2a                	mv	s6,a0
    80001a9e:	8a2e                	mv	s4,a1
    80001aa0:	8c32                	mv	s8,a2
    80001aa2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001aa4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001aa6:	6a85                	lui	s5,0x1
    80001aa8:	a01d                	j	80001ace <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001aaa:	018505b3          	add	a1,a0,s8
    80001aae:	0004861b          	sext.w	a2,s1
    80001ab2:	412585b3          	sub	a1,a1,s2
    80001ab6:	8552                	mv	a0,s4
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	63e080e7          	jalr	1598(ra) # 800010f6 <memmove>

    len -= n;
    80001ac0:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001ac4:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001ac6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001aca:	02098263          	beqz	s3,80001aee <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001ace:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001ad2:	85ca                	mv	a1,s2
    80001ad4:	855a                	mv	a0,s6
    80001ad6:	00000097          	auipc	ra,0x0
    80001ada:	95a080e7          	jalr	-1702(ra) # 80001430 <walkaddr>
    if(pa0 == 0)
    80001ade:	cd01                	beqz	a0,80001af6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001ae0:	418904b3          	sub	s1,s2,s8
    80001ae4:	94d6                	add	s1,s1,s5
    80001ae6:	fc99f2e3          	bgeu	s3,s1,80001aaa <copyin+0x28>
    80001aea:	84ce                	mv	s1,s3
    80001aec:	bf7d                	j	80001aaa <copyin+0x28>
  }
  return 0;
    80001aee:	4501                	li	a0,0
    80001af0:	a021                	j	80001af8 <copyin+0x76>
    80001af2:	4501                	li	a0,0
}
    80001af4:	8082                	ret
      return -1;
    80001af6:	557d                	li	a0,-1
}
    80001af8:	60a6                	ld	ra,72(sp)
    80001afa:	6406                	ld	s0,64(sp)
    80001afc:	74e2                	ld	s1,56(sp)
    80001afe:	7942                	ld	s2,48(sp)
    80001b00:	79a2                	ld	s3,40(sp)
    80001b02:	7a02                	ld	s4,32(sp)
    80001b04:	6ae2                	ld	s5,24(sp)
    80001b06:	6b42                	ld	s6,16(sp)
    80001b08:	6ba2                	ld	s7,8(sp)
    80001b0a:	6c02                	ld	s8,0(sp)
    80001b0c:	6161                	addi	sp,sp,80
    80001b0e:	8082                	ret

0000000080001b10 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b10:	c2dd                	beqz	a3,80001bb6 <copyinstr+0xa6>
{
    80001b12:	715d                	addi	sp,sp,-80
    80001b14:	e486                	sd	ra,72(sp)
    80001b16:	e0a2                	sd	s0,64(sp)
    80001b18:	fc26                	sd	s1,56(sp)
    80001b1a:	f84a                	sd	s2,48(sp)
    80001b1c:	f44e                	sd	s3,40(sp)
    80001b1e:	f052                	sd	s4,32(sp)
    80001b20:	ec56                	sd	s5,24(sp)
    80001b22:	e85a                	sd	s6,16(sp)
    80001b24:	e45e                	sd	s7,8(sp)
    80001b26:	0880                	addi	s0,sp,80
    80001b28:	8a2a                	mv	s4,a0
    80001b2a:	8b2e                	mv	s6,a1
    80001b2c:	8bb2                	mv	s7,a2
    80001b2e:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b30:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b32:	6985                	lui	s3,0x1
    80001b34:	a02d                	j	80001b5e <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b36:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b3a:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b3c:	37fd                	addiw	a5,a5,-1
    80001b3e:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b42:	60a6                	ld	ra,72(sp)
    80001b44:	6406                	ld	s0,64(sp)
    80001b46:	74e2                	ld	s1,56(sp)
    80001b48:	7942                	ld	s2,48(sp)
    80001b4a:	79a2                	ld	s3,40(sp)
    80001b4c:	7a02                	ld	s4,32(sp)
    80001b4e:	6ae2                	ld	s5,24(sp)
    80001b50:	6b42                	ld	s6,16(sp)
    80001b52:	6ba2                	ld	s7,8(sp)
    80001b54:	6161                	addi	sp,sp,80
    80001b56:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b58:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b5c:	c8a9                	beqz	s1,80001bae <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001b5e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b62:	85ca                	mv	a1,s2
    80001b64:	8552                	mv	a0,s4
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	8ca080e7          	jalr	-1846(ra) # 80001430 <walkaddr>
    if(pa0 == 0)
    80001b6e:	c131                	beqz	a0,80001bb2 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001b70:	417906b3          	sub	a3,s2,s7
    80001b74:	96ce                	add	a3,a3,s3
    80001b76:	00d4f363          	bgeu	s1,a3,80001b7c <copyinstr+0x6c>
    80001b7a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001b7c:	955e                	add	a0,a0,s7
    80001b7e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001b82:	daf9                	beqz	a3,80001b58 <copyinstr+0x48>
    80001b84:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001b86:	41650633          	sub	a2,a0,s6
    80001b8a:	fff48593          	addi	a1,s1,-1
    80001b8e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001b90:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001b92:	00f60733          	add	a4,a2,a5
    80001b96:	00074703          	lbu	a4,0(a4)
    80001b9a:	df51                	beqz	a4,80001b36 <copyinstr+0x26>
        *dst = *p;
    80001b9c:	00e78023          	sb	a4,0(a5)
      --max;
    80001ba0:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001ba4:	0785                	addi	a5,a5,1
    while(n > 0){
    80001ba6:	fed796e3          	bne	a5,a3,80001b92 <copyinstr+0x82>
      dst++;
    80001baa:	8b3e                	mv	s6,a5
    80001bac:	b775                	j	80001b58 <copyinstr+0x48>
    80001bae:	4781                	li	a5,0
    80001bb0:	b771                	j	80001b3c <copyinstr+0x2c>
      return -1;
    80001bb2:	557d                	li	a0,-1
    80001bb4:	b779                	j	80001b42 <copyinstr+0x32>
  int got_null = 0;
    80001bb6:	4781                	li	a5,0
  if(got_null){
    80001bb8:	37fd                	addiw	a5,a5,-1
    80001bba:	0007851b          	sext.w	a0,a5
}
    80001bbe:	8082                	ret

0000000080001bc0 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	1000                	addi	s0,sp,32
    80001bca:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	074080e7          	jalr	116(ra) # 80000c40 <holding>
    80001bd4:	c909                	beqz	a0,80001be6 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001bd6:	789c                	ld	a5,48(s1)
    80001bd8:	00978f63          	beq	a5,s1,80001bf6 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001bdc:	60e2                	ld	ra,24(sp)
    80001bde:	6442                	ld	s0,16(sp)
    80001be0:	64a2                	ld	s1,8(sp)
    80001be2:	6105                	addi	sp,sp,32
    80001be4:	8082                	ret
    panic("wakeup1");
    80001be6:	00006517          	auipc	a0,0x6
    80001bea:	67250513          	addi	a0,a0,1650 # 80008258 <digits+0x218>
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	95e080e7          	jalr	-1698(ra) # 8000054c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001bf6:	5098                	lw	a4,32(s1)
    80001bf8:	4785                	li	a5,1
    80001bfa:	fef711e3          	bne	a4,a5,80001bdc <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001bfe:	4789                	li	a5,2
    80001c00:	d09c                	sw	a5,32(s1)
}
    80001c02:	bfe9                	j	80001bdc <wakeup1+0x1c>

0000000080001c04 <procinit>:
{
    80001c04:	715d                	addi	sp,sp,-80
    80001c06:	e486                	sd	ra,72(sp)
    80001c08:	e0a2                	sd	s0,64(sp)
    80001c0a:	fc26                	sd	s1,56(sp)
    80001c0c:	f84a                	sd	s2,48(sp)
    80001c0e:	f44e                	sd	s3,40(sp)
    80001c10:	f052                	sd	s4,32(sp)
    80001c12:	ec56                	sd	s5,24(sp)
    80001c14:	e85a                	sd	s6,16(sp)
    80001c16:	e45e                	sd	s7,8(sp)
    80001c18:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c1a:	00006597          	auipc	a1,0x6
    80001c1e:	64658593          	addi	a1,a1,1606 # 80008260 <digits+0x220>
    80001c22:	00010517          	auipc	a0,0x10
    80001c26:	76650513          	addi	a0,a0,1894 # 80012388 <pid_lock>
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	20c080e7          	jalr	524(ra) # 80000e36 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	00011917          	auipc	s2,0x11
    80001c36:	b7690913          	addi	s2,s2,-1162 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c3a:	00006b97          	auipc	s7,0x6
    80001c3e:	62eb8b93          	addi	s7,s7,1582 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c42:	8b4a                	mv	s6,s2
    80001c44:	00006a97          	auipc	s5,0x6
    80001c48:	3bca8a93          	addi	s5,s5,956 # 80008000 <etext>
    80001c4c:	040009b7          	lui	s3,0x4000
    80001c50:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c52:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c54:	00016a17          	auipc	s4,0x16
    80001c58:	754a0a13          	addi	s4,s4,1876 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c5c:	85de                	mv	a1,s7
    80001c5e:	854a                	mv	a0,s2
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	1d6080e7          	jalr	470(ra) # 80000e36 <initlock>
      char *pa = kalloc();
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	ef0080e7          	jalr	-272(ra) # 80000b58 <kalloc>
    80001c70:	85aa                	mv	a1,a0
      if(pa == 0)
    80001c72:	c929                	beqz	a0,80001cc4 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001c74:	416904b3          	sub	s1,s2,s6
    80001c78:	8491                	srai	s1,s1,0x4
    80001c7a:	000ab783          	ld	a5,0(s5)
    80001c7e:	02f484b3          	mul	s1,s1,a5
    80001c82:	2485                	addiw	s1,s1,1
    80001c84:	00d4949b          	slliw	s1,s1,0xd
    80001c88:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c8c:	4699                	li	a3,6
    80001c8e:	6605                	lui	a2,0x1
    80001c90:	8526                	mv	a0,s1
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	86e080e7          	jalr	-1938(ra) # 80001500 <kvmmap>
      p->kstack = va;
    80001c9a:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c9e:	17090913          	addi	s2,s2,368
    80001ca2:	fb491de3          	bne	s2,s4,80001c5c <procinit+0x58>
  kvminithart();
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	766080e7          	jalr	1894(ra) # 8000140c <kvminithart>
}
    80001cae:	60a6                	ld	ra,72(sp)
    80001cb0:	6406                	ld	s0,64(sp)
    80001cb2:	74e2                	ld	s1,56(sp)
    80001cb4:	7942                	ld	s2,48(sp)
    80001cb6:	79a2                	ld	s3,40(sp)
    80001cb8:	7a02                	ld	s4,32(sp)
    80001cba:	6ae2                	ld	s5,24(sp)
    80001cbc:	6b42                	ld	s6,16(sp)
    80001cbe:	6ba2                	ld	s7,8(sp)
    80001cc0:	6161                	addi	sp,sp,80
    80001cc2:	8082                	ret
        panic("kalloc");
    80001cc4:	00006517          	auipc	a0,0x6
    80001cc8:	5ac50513          	addi	a0,a0,1452 # 80008270 <digits+0x230>
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	880080e7          	jalr	-1920(ra) # 8000054c <panic>

0000000080001cd4 <cpuid>:
{
    80001cd4:	1141                	addi	sp,sp,-16
    80001cd6:	e422                	sd	s0,8(sp)
    80001cd8:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cda:	8512                	mv	a0,tp
}
    80001cdc:	2501                	sext.w	a0,a0
    80001cde:	6422                	ld	s0,8(sp)
    80001ce0:	0141                	addi	sp,sp,16
    80001ce2:	8082                	ret

0000000080001ce4 <mycpu>:
mycpu(void) {
    80001ce4:	1141                	addi	sp,sp,-16
    80001ce6:	e422                	sd	s0,8(sp)
    80001ce8:	0800                	addi	s0,sp,16
    80001cea:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001cec:	2781                	sext.w	a5,a5
    80001cee:	079e                	slli	a5,a5,0x7
}
    80001cf0:	00010517          	auipc	a0,0x10
    80001cf4:	6b850513          	addi	a0,a0,1720 # 800123a8 <cpus>
    80001cf8:	953e                	add	a0,a0,a5
    80001cfa:	6422                	ld	s0,8(sp)
    80001cfc:	0141                	addi	sp,sp,16
    80001cfe:	8082                	ret

0000000080001d00 <myproc>:
myproc(void) {
    80001d00:	1101                	addi	sp,sp,-32
    80001d02:	ec06                	sd	ra,24(sp)
    80001d04:	e822                	sd	s0,16(sp)
    80001d06:	e426                	sd	s1,8(sp)
    80001d08:	1000                	addi	s0,sp,32
  push_off();
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	f64080e7          	jalr	-156(ra) # 80000c6e <push_off>
    80001d12:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d14:	2781                	sext.w	a5,a5
    80001d16:	079e                	slli	a5,a5,0x7
    80001d18:	00010717          	auipc	a4,0x10
    80001d1c:	67070713          	addi	a4,a4,1648 # 80012388 <pid_lock>
    80001d20:	97ba                	add	a5,a5,a4
    80001d22:	7384                	ld	s1,32(a5)
  pop_off();
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	006080e7          	jalr	6(ra) # 80000d2a <pop_off>
}
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <forkret>:
{
    80001d38:	1141                	addi	sp,sp,-16
    80001d3a:	e406                	sd	ra,8(sp)
    80001d3c:	e022                	sd	s0,0(sp)
    80001d3e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	fc0080e7          	jalr	-64(ra) # 80001d00 <myproc>
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	042080e7          	jalr	66(ra) # 80000d8a <release>
  if (first) {
    80001d50:	00007797          	auipc	a5,0x7
    80001d54:	b607a783          	lw	a5,-1184(a5) # 800088b0 <first.1>
    80001d58:	eb89                	bnez	a5,80001d6a <forkret+0x32>
  usertrapret();
    80001d5a:	00001097          	auipc	ra,0x1
    80001d5e:	c1e080e7          	jalr	-994(ra) # 80002978 <usertrapret>
}
    80001d62:	60a2                	ld	ra,8(sp)
    80001d64:	6402                	ld	s0,0(sp)
    80001d66:	0141                	addi	sp,sp,16
    80001d68:	8082                	ret
    first = 0;
    80001d6a:	00007797          	auipc	a5,0x7
    80001d6e:	b407a323          	sw	zero,-1210(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001d72:	4505                	li	a0,1
    80001d74:	00002097          	auipc	ra,0x2
    80001d78:	944080e7          	jalr	-1724(ra) # 800036b8 <fsinit>
    80001d7c:	bff9                	j	80001d5a <forkret+0x22>

0000000080001d7e <allocpid>:
allocpid() {
    80001d7e:	1101                	addi	sp,sp,-32
    80001d80:	ec06                	sd	ra,24(sp)
    80001d82:	e822                	sd	s0,16(sp)
    80001d84:	e426                	sd	s1,8(sp)
    80001d86:	e04a                	sd	s2,0(sp)
    80001d88:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d8a:	00010917          	auipc	s2,0x10
    80001d8e:	5fe90913          	addi	s2,s2,1534 # 80012388 <pid_lock>
    80001d92:	854a                	mv	a0,s2
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f26080e7          	jalr	-218(ra) # 80000cba <acquire>
  pid = nextpid;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	b1878793          	addi	a5,a5,-1256 # 800088b4 <nextpid>
    80001da4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001da6:	0014871b          	addiw	a4,s1,1
    80001daa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dac:	854a                	mv	a0,s2
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	fdc080e7          	jalr	-36(ra) # 80000d8a <release>
}
    80001db6:	8526                	mv	a0,s1
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6902                	ld	s2,0(sp)
    80001dc0:	6105                	addi	sp,sp,32
    80001dc2:	8082                	ret

0000000080001dc4 <proc_pagetable>:
{
    80001dc4:	1101                	addi	sp,sp,-32
    80001dc6:	ec06                	sd	ra,24(sp)
    80001dc8:	e822                	sd	s0,16(sp)
    80001dca:	e426                	sd	s1,8(sp)
    80001dcc:	e04a                	sd	s2,0(sp)
    80001dce:	1000                	addi	s0,sp,32
    80001dd0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001dd2:	00000097          	auipc	ra,0x0
    80001dd6:	8e8080e7          	jalr	-1816(ra) # 800016ba <uvmcreate>
    80001dda:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ddc:	c121                	beqz	a0,80001e1c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dde:	4729                	li	a4,10
    80001de0:	00005697          	auipc	a3,0x5
    80001de4:	22068693          	addi	a3,a3,544 # 80007000 <_trampoline>
    80001de8:	6605                	lui	a2,0x1
    80001dea:	040005b7          	lui	a1,0x4000
    80001dee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001df0:	05b2                	slli	a1,a1,0xc
    80001df2:	fffff097          	auipc	ra,0xfffff
    80001df6:	680080e7          	jalr	1664(ra) # 80001472 <mappages>
    80001dfa:	02054863          	bltz	a0,80001e2a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dfe:	4719                	li	a4,6
    80001e00:	06093683          	ld	a3,96(s2)
    80001e04:	6605                	lui	a2,0x1
    80001e06:	020005b7          	lui	a1,0x2000
    80001e0a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e0c:	05b6                	slli	a1,a1,0xd
    80001e0e:	8526                	mv	a0,s1
    80001e10:	fffff097          	auipc	ra,0xfffff
    80001e14:	662080e7          	jalr	1634(ra) # 80001472 <mappages>
    80001e18:	02054163          	bltz	a0,80001e3a <proc_pagetable+0x76>
}
    80001e1c:	8526                	mv	a0,s1
    80001e1e:	60e2                	ld	ra,24(sp)
    80001e20:	6442                	ld	s0,16(sp)
    80001e22:	64a2                	ld	s1,8(sp)
    80001e24:	6902                	ld	s2,0(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret
    uvmfree(pagetable, 0);
    80001e2a:	4581                	li	a1,0
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	00000097          	auipc	ra,0x0
    80001e32:	a8a080e7          	jalr	-1398(ra) # 800018b8 <uvmfree>
    return 0;
    80001e36:	4481                	li	s1,0
    80001e38:	b7d5                	j	80001e1c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e3a:	4681                	li	a3,0
    80001e3c:	4605                	li	a2,1
    80001e3e:	040005b7          	lui	a1,0x4000
    80001e42:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e44:	05b2                	slli	a1,a1,0xc
    80001e46:	8526                	mv	a0,s1
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	7ae080e7          	jalr	1966(ra) # 800015f6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e50:	4581                	li	a1,0
    80001e52:	8526                	mv	a0,s1
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	a64080e7          	jalr	-1436(ra) # 800018b8 <uvmfree>
    return 0;
    80001e5c:	4481                	li	s1,0
    80001e5e:	bf7d                	j	80001e1c <proc_pagetable+0x58>

0000000080001e60 <proc_freepagetable>:
{
    80001e60:	1101                	addi	sp,sp,-32
    80001e62:	ec06                	sd	ra,24(sp)
    80001e64:	e822                	sd	s0,16(sp)
    80001e66:	e426                	sd	s1,8(sp)
    80001e68:	e04a                	sd	s2,0(sp)
    80001e6a:	1000                	addi	s0,sp,32
    80001e6c:	84aa                	mv	s1,a0
    80001e6e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e70:	4681                	li	a3,0
    80001e72:	4605                	li	a2,1
    80001e74:	040005b7          	lui	a1,0x4000
    80001e78:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e7a:	05b2                	slli	a1,a1,0xc
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	77a080e7          	jalr	1914(ra) # 800015f6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e84:	4681                	li	a3,0
    80001e86:	4605                	li	a2,1
    80001e88:	020005b7          	lui	a1,0x2000
    80001e8c:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e8e:	05b6                	slli	a1,a1,0xd
    80001e90:	8526                	mv	a0,s1
    80001e92:	fffff097          	auipc	ra,0xfffff
    80001e96:	764080e7          	jalr	1892(ra) # 800015f6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e9a:	85ca                	mv	a1,s2
    80001e9c:	8526                	mv	a0,s1
    80001e9e:	00000097          	auipc	ra,0x0
    80001ea2:	a1a080e7          	jalr	-1510(ra) # 800018b8 <uvmfree>
}
    80001ea6:	60e2                	ld	ra,24(sp)
    80001ea8:	6442                	ld	s0,16(sp)
    80001eaa:	64a2                	ld	s1,8(sp)
    80001eac:	6902                	ld	s2,0(sp)
    80001eae:	6105                	addi	sp,sp,32
    80001eb0:	8082                	ret

0000000080001eb2 <freeproc>:
{
    80001eb2:	1101                	addi	sp,sp,-32
    80001eb4:	ec06                	sd	ra,24(sp)
    80001eb6:	e822                	sd	s0,16(sp)
    80001eb8:	e426                	sd	s1,8(sp)
    80001eba:	1000                	addi	s0,sp,32
    80001ebc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ebe:	7128                	ld	a0,96(a0)
    80001ec0:	c509                	beqz	a0,80001eca <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	b56080e7          	jalr	-1194(ra) # 80000a18 <kfree>
  p->trapframe = 0;
    80001eca:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001ece:	6ca8                	ld	a0,88(s1)
    80001ed0:	c511                	beqz	a0,80001edc <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ed2:	68ac                	ld	a1,80(s1)
    80001ed4:	00000097          	auipc	ra,0x0
    80001ed8:	f8c080e7          	jalr	-116(ra) # 80001e60 <proc_freepagetable>
  p->pagetable = 0;
    80001edc:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001ee0:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001ee4:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001ee8:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001eec:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001ef0:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001ef4:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001ef8:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001efc:	0204a023          	sw	zero,32(s1)
}
    80001f00:	60e2                	ld	ra,24(sp)
    80001f02:	6442                	ld	s0,16(sp)
    80001f04:	64a2                	ld	s1,8(sp)
    80001f06:	6105                	addi	sp,sp,32
    80001f08:	8082                	ret

0000000080001f0a <allocproc>:
{
    80001f0a:	1101                	addi	sp,sp,-32
    80001f0c:	ec06                	sd	ra,24(sp)
    80001f0e:	e822                	sd	s0,16(sp)
    80001f10:	e426                	sd	s1,8(sp)
    80001f12:	e04a                	sd	s2,0(sp)
    80001f14:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f16:	00011497          	auipc	s1,0x11
    80001f1a:	89248493          	addi	s1,s1,-1902 # 800127a8 <proc>
    80001f1e:	00016917          	auipc	s2,0x16
    80001f22:	48a90913          	addi	s2,s2,1162 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	d92080e7          	jalr	-622(ra) # 80000cba <acquire>
    if(p->state == UNUSED) {
    80001f30:	509c                	lw	a5,32(s1)
    80001f32:	cf81                	beqz	a5,80001f4a <allocproc+0x40>
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	e54080e7          	jalr	-428(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	17048493          	addi	s1,s1,368
    80001f42:	ff2492e3          	bne	s1,s2,80001f26 <allocproc+0x1c>
  return 0;
    80001f46:	4481                	li	s1,0
    80001f48:	a0b9                	j	80001f96 <allocproc+0x8c>
  p->pid = allocpid();
    80001f4a:	00000097          	auipc	ra,0x0
    80001f4e:	e34080e7          	jalr	-460(ra) # 80001d7e <allocpid>
    80001f52:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c04080e7          	jalr	-1020(ra) # 80000b58 <kalloc>
    80001f5c:	892a                	mv	s2,a0
    80001f5e:	f0a8                	sd	a0,96(s1)
    80001f60:	c131                	beqz	a0,80001fa4 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f62:	8526                	mv	a0,s1
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	e60080e7          	jalr	-416(ra) # 80001dc4 <proc_pagetable>
    80001f6c:	892a                	mv	s2,a0
    80001f6e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001f70:	c129                	beqz	a0,80001fb2 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001f72:	07000613          	li	a2,112
    80001f76:	4581                	li	a1,0
    80001f78:	06848513          	addi	a0,s1,104
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	11e080e7          	jalr	286(ra) # 8000109a <memset>
  p->context.ra = (uint64)forkret;
    80001f84:	00000797          	auipc	a5,0x0
    80001f88:	db478793          	addi	a5,a5,-588 # 80001d38 <forkret>
    80001f8c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f8e:	64bc                	ld	a5,72(s1)
    80001f90:	6705                	lui	a4,0x1
    80001f92:	97ba                	add	a5,a5,a4
    80001f94:	f8bc                	sd	a5,112(s1)
}
    80001f96:	8526                	mv	a0,s1
    80001f98:	60e2                	ld	ra,24(sp)
    80001f9a:	6442                	ld	s0,16(sp)
    80001f9c:	64a2                	ld	s1,8(sp)
    80001f9e:	6902                	ld	s2,0(sp)
    80001fa0:	6105                	addi	sp,sp,32
    80001fa2:	8082                	ret
    release(&p->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	de4080e7          	jalr	-540(ra) # 80000d8a <release>
    return 0;
    80001fae:	84ca                	mv	s1,s2
    80001fb0:	b7dd                	j	80001f96 <allocproc+0x8c>
    freeproc(p);
    80001fb2:	8526                	mv	a0,s1
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	efe080e7          	jalr	-258(ra) # 80001eb2 <freeproc>
    release(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	dcc080e7          	jalr	-564(ra) # 80000d8a <release>
    return 0;
    80001fc6:	84ca                	mv	s1,s2
    80001fc8:	b7f9                	j	80001f96 <allocproc+0x8c>

0000000080001fca <userinit>:
{
    80001fca:	1101                	addi	sp,sp,-32
    80001fcc:	ec06                	sd	ra,24(sp)
    80001fce:	e822                	sd	s0,16(sp)
    80001fd0:	e426                	sd	s1,8(sp)
    80001fd2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	f36080e7          	jalr	-202(ra) # 80001f0a <allocproc>
    80001fdc:	84aa                	mv	s1,a0
  initproc = p;
    80001fde:	00007797          	auipc	a5,0x7
    80001fe2:	02a7bd23          	sd	a0,58(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001fe6:	03400613          	li	a2,52
    80001fea:	00007597          	auipc	a1,0x7
    80001fee:	8d658593          	addi	a1,a1,-1834 # 800088c0 <initcode>
    80001ff2:	6d28                	ld	a0,88(a0)
    80001ff4:	fffff097          	auipc	ra,0xfffff
    80001ff8:	6f4080e7          	jalr	1780(ra) # 800016e8 <uvminit>
  p->sz = PGSIZE;
    80001ffc:	6785                	lui	a5,0x1
    80001ffe:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002000:	70b8                	ld	a4,96(s1)
    80002002:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002006:	70b8                	ld	a4,96(s1)
    80002008:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000200a:	4641                	li	a2,16
    8000200c:	00006597          	auipc	a1,0x6
    80002010:	26c58593          	addi	a1,a1,620 # 80008278 <digits+0x238>
    80002014:	16048513          	addi	a0,s1,352
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	1d4080e7          	jalr	468(ra) # 800011ec <safestrcpy>
  p->cwd = namei("/");
    80002020:	00006517          	auipc	a0,0x6
    80002024:	26850513          	addi	a0,a0,616 # 80008288 <digits+0x248>
    80002028:	00002097          	auipc	ra,0x2
    8000202c:	0c4080e7          	jalr	196(ra) # 800040ec <namei>
    80002030:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80002034:	4789                	li	a5,2
    80002036:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	d50080e7          	jalr	-688(ra) # 80000d8a <release>
}
    80002042:	60e2                	ld	ra,24(sp)
    80002044:	6442                	ld	s0,16(sp)
    80002046:	64a2                	ld	s1,8(sp)
    80002048:	6105                	addi	sp,sp,32
    8000204a:	8082                	ret

000000008000204c <growproc>:
{
    8000204c:	1101                	addi	sp,sp,-32
    8000204e:	ec06                	sd	ra,24(sp)
    80002050:	e822                	sd	s0,16(sp)
    80002052:	e426                	sd	s1,8(sp)
    80002054:	e04a                	sd	s2,0(sp)
    80002056:	1000                	addi	s0,sp,32
    80002058:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000205a:	00000097          	auipc	ra,0x0
    8000205e:	ca6080e7          	jalr	-858(ra) # 80001d00 <myproc>
    80002062:	892a                	mv	s2,a0
  sz = p->sz;
    80002064:	692c                	ld	a1,80(a0)
    80002066:	0005879b          	sext.w	a5,a1
  if(n > 0){
    8000206a:	00904f63          	bgtz	s1,80002088 <growproc+0x3c>
  } else if(n < 0){
    8000206e:	0204cd63          	bltz	s1,800020a8 <growproc+0x5c>
  p->sz = sz;
    80002072:	1782                	slli	a5,a5,0x20
    80002074:	9381                	srli	a5,a5,0x20
    80002076:	04f93823          	sd	a5,80(s2)
  return 0;
    8000207a:	4501                	li	a0,0
}
    8000207c:	60e2                	ld	ra,24(sp)
    8000207e:	6442                	ld	s0,16(sp)
    80002080:	64a2                	ld	s1,8(sp)
    80002082:	6902                	ld	s2,0(sp)
    80002084:	6105                	addi	sp,sp,32
    80002086:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002088:	00f4863b          	addw	a2,s1,a5
    8000208c:	1602                	slli	a2,a2,0x20
    8000208e:	9201                	srli	a2,a2,0x20
    80002090:	1582                	slli	a1,a1,0x20
    80002092:	9181                	srli	a1,a1,0x20
    80002094:	6d28                	ld	a0,88(a0)
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	70c080e7          	jalr	1804(ra) # 800017a2 <uvmalloc>
    8000209e:	0005079b          	sext.w	a5,a0
    800020a2:	fbe1                	bnez	a5,80002072 <growproc+0x26>
      return -1;
    800020a4:	557d                	li	a0,-1
    800020a6:	bfd9                	j	8000207c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020a8:	00f4863b          	addw	a2,s1,a5
    800020ac:	1602                	slli	a2,a2,0x20
    800020ae:	9201                	srli	a2,a2,0x20
    800020b0:	1582                	slli	a1,a1,0x20
    800020b2:	9181                	srli	a1,a1,0x20
    800020b4:	6d28                	ld	a0,88(a0)
    800020b6:	fffff097          	auipc	ra,0xfffff
    800020ba:	6a4080e7          	jalr	1700(ra) # 8000175a <uvmdealloc>
    800020be:	0005079b          	sext.w	a5,a0
    800020c2:	bf45                	j	80002072 <growproc+0x26>

00000000800020c4 <fork>:
{
    800020c4:	7139                	addi	sp,sp,-64
    800020c6:	fc06                	sd	ra,56(sp)
    800020c8:	f822                	sd	s0,48(sp)
    800020ca:	f426                	sd	s1,40(sp)
    800020cc:	f04a                	sd	s2,32(sp)
    800020ce:	ec4e                	sd	s3,24(sp)
    800020d0:	e852                	sd	s4,16(sp)
    800020d2:	e456                	sd	s5,8(sp)
    800020d4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	c2a080e7          	jalr	-982(ra) # 80001d00 <myproc>
    800020de:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800020e0:	00000097          	auipc	ra,0x0
    800020e4:	e2a080e7          	jalr	-470(ra) # 80001f0a <allocproc>
    800020e8:	c17d                	beqz	a0,800021ce <fork+0x10a>
    800020ea:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020ec:	050ab603          	ld	a2,80(s5)
    800020f0:	6d2c                	ld	a1,88(a0)
    800020f2:	058ab503          	ld	a0,88(s5)
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	7fc080e7          	jalr	2044(ra) # 800018f2 <uvmcopy>
    800020fe:	04054a63          	bltz	a0,80002152 <fork+0x8e>
  np->sz = p->sz;
    80002102:	050ab783          	ld	a5,80(s5)
    80002106:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    8000210a:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    8000210e:	060ab683          	ld	a3,96(s5)
    80002112:	87b6                	mv	a5,a3
    80002114:	060a3703          	ld	a4,96(s4)
    80002118:	12068693          	addi	a3,a3,288
    8000211c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002120:	6788                	ld	a0,8(a5)
    80002122:	6b8c                	ld	a1,16(a5)
    80002124:	6f90                	ld	a2,24(a5)
    80002126:	01073023          	sd	a6,0(a4)
    8000212a:	e708                	sd	a0,8(a4)
    8000212c:	eb0c                	sd	a1,16(a4)
    8000212e:	ef10                	sd	a2,24(a4)
    80002130:	02078793          	addi	a5,a5,32
    80002134:	02070713          	addi	a4,a4,32
    80002138:	fed792e3          	bne	a5,a3,8000211c <fork+0x58>
  np->trapframe->a0 = 0;
    8000213c:	060a3783          	ld	a5,96(s4)
    80002140:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002144:	0d8a8493          	addi	s1,s5,216
    80002148:	0d8a0913          	addi	s2,s4,216
    8000214c:	158a8993          	addi	s3,s5,344
    80002150:	a00d                	j	80002172 <fork+0xae>
    freeproc(np);
    80002152:	8552                	mv	a0,s4
    80002154:	00000097          	auipc	ra,0x0
    80002158:	d5e080e7          	jalr	-674(ra) # 80001eb2 <freeproc>
    release(&np->lock);
    8000215c:	8552                	mv	a0,s4
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	c2c080e7          	jalr	-980(ra) # 80000d8a <release>
    return -1;
    80002166:	54fd                	li	s1,-1
    80002168:	a889                	j	800021ba <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    8000216a:	04a1                	addi	s1,s1,8
    8000216c:	0921                	addi	s2,s2,8
    8000216e:	01348b63          	beq	s1,s3,80002184 <fork+0xc0>
    if(p->ofile[i])
    80002172:	6088                	ld	a0,0(s1)
    80002174:	d97d                	beqz	a0,8000216a <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80002176:	00002097          	auipc	ra,0x2
    8000217a:	614080e7          	jalr	1556(ra) # 8000478a <filedup>
    8000217e:	00a93023          	sd	a0,0(s2)
    80002182:	b7e5                	j	8000216a <fork+0xa6>
  np->cwd = idup(p->cwd);
    80002184:	158ab503          	ld	a0,344(s5)
    80002188:	00001097          	auipc	ra,0x1
    8000218c:	76c080e7          	jalr	1900(ra) # 800038f4 <idup>
    80002190:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002194:	4641                	li	a2,16
    80002196:	160a8593          	addi	a1,s5,352
    8000219a:	160a0513          	addi	a0,s4,352
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	04e080e7          	jalr	78(ra) # 800011ec <safestrcpy>
  pid = np->pid;
    800021a6:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021aa:	4789                	li	a5,2
    800021ac:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021b0:	8552                	mv	a0,s4
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	bd8080e7          	jalr	-1064(ra) # 80000d8a <release>
}
    800021ba:	8526                	mv	a0,s1
    800021bc:	70e2                	ld	ra,56(sp)
    800021be:	7442                	ld	s0,48(sp)
    800021c0:	74a2                	ld	s1,40(sp)
    800021c2:	7902                	ld	s2,32(sp)
    800021c4:	69e2                	ld	s3,24(sp)
    800021c6:	6a42                	ld	s4,16(sp)
    800021c8:	6aa2                	ld	s5,8(sp)
    800021ca:	6121                	addi	sp,sp,64
    800021cc:	8082                	ret
    return -1;
    800021ce:	54fd                	li	s1,-1
    800021d0:	b7ed                	j	800021ba <fork+0xf6>

00000000800021d2 <reparent>:
{
    800021d2:	7179                	addi	sp,sp,-48
    800021d4:	f406                	sd	ra,40(sp)
    800021d6:	f022                	sd	s0,32(sp)
    800021d8:	ec26                	sd	s1,24(sp)
    800021da:	e84a                	sd	s2,16(sp)
    800021dc:	e44e                	sd	s3,8(sp)
    800021de:	e052                	sd	s4,0(sp)
    800021e0:	1800                	addi	s0,sp,48
    800021e2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e4:	00010497          	auipc	s1,0x10
    800021e8:	5c448493          	addi	s1,s1,1476 # 800127a8 <proc>
      pp->parent = initproc;
    800021ec:	00007a17          	auipc	s4,0x7
    800021f0:	e2ca0a13          	addi	s4,s4,-468 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f4:	00016997          	auipc	s3,0x16
    800021f8:	1b498993          	addi	s3,s3,436 # 800183a8 <tickslock>
    800021fc:	a029                	j	80002206 <reparent+0x34>
    800021fe:	17048493          	addi	s1,s1,368
    80002202:	03348363          	beq	s1,s3,80002228 <reparent+0x56>
    if(pp->parent == p){
    80002206:	749c                	ld	a5,40(s1)
    80002208:	ff279be3          	bne	a5,s2,800021fe <reparent+0x2c>
      acquire(&pp->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	aac080e7          	jalr	-1364(ra) # 80000cba <acquire>
      pp->parent = initproc;
    80002216:	000a3783          	ld	a5,0(s4)
    8000221a:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    8000221c:	8526                	mv	a0,s1
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	b6c080e7          	jalr	-1172(ra) # 80000d8a <release>
    80002226:	bfe1                	j	800021fe <reparent+0x2c>
}
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6a02                	ld	s4,0(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret

0000000080002238 <scheduler>:
{
    80002238:	711d                	addi	sp,sp,-96
    8000223a:	ec86                	sd	ra,88(sp)
    8000223c:	e8a2                	sd	s0,80(sp)
    8000223e:	e4a6                	sd	s1,72(sp)
    80002240:	e0ca                	sd	s2,64(sp)
    80002242:	fc4e                	sd	s3,56(sp)
    80002244:	f852                	sd	s4,48(sp)
    80002246:	f456                	sd	s5,40(sp)
    80002248:	f05a                	sd	s6,32(sp)
    8000224a:	ec5e                	sd	s7,24(sp)
    8000224c:	e862                	sd	s8,16(sp)
    8000224e:	e466                	sd	s9,8(sp)
    80002250:	1080                	addi	s0,sp,96
    80002252:	8792                	mv	a5,tp
  int id = r_tp();
    80002254:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002256:	00779c13          	slli	s8,a5,0x7
    8000225a:	00010717          	auipc	a4,0x10
    8000225e:	12e70713          	addi	a4,a4,302 # 80012388 <pid_lock>
    80002262:	9762                	add	a4,a4,s8
    80002264:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002268:	00010717          	auipc	a4,0x10
    8000226c:	14870713          	addi	a4,a4,328 # 800123b0 <cpus+0x8>
    80002270:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    80002272:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    80002274:	4a89                	li	s5,2
        c->proc = p;
    80002276:	079e                	slli	a5,a5,0x7
    80002278:	00010b17          	auipc	s6,0x10
    8000227c:	110b0b13          	addi	s6,s6,272 # 80012388 <pid_lock>
    80002280:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002282:	00016a17          	auipc	s4,0x16
    80002286:	126a0a13          	addi	s4,s4,294 # 800183a8 <tickslock>
    8000228a:	a8a1                	j	800022e2 <scheduler+0xaa>
      release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	afc080e7          	jalr	-1284(ra) # 80000d8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002296:	17048493          	addi	s1,s1,368
    8000229a:	03448a63          	beq	s1,s4,800022ce <scheduler+0x96>
      acquire(&p->lock);
    8000229e:	8526                	mv	a0,s1
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	a1a080e7          	jalr	-1510(ra) # 80000cba <acquire>
      if(p->state != UNUSED) {
    800022a8:	509c                	lw	a5,32(s1)
    800022aa:	d3ed                	beqz	a5,8000228c <scheduler+0x54>
        nproc++;
    800022ac:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022ae:	fd579fe3          	bne	a5,s5,8000228c <scheduler+0x54>
        p->state = RUNNING;
    800022b2:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022b6:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022ba:	06848593          	addi	a1,s1,104
    800022be:	8562                	mv	a0,s8
    800022c0:	00000097          	auipc	ra,0x0
    800022c4:	60e080e7          	jalr	1550(ra) # 800028ce <swtch>
        c->proc = 0;
    800022c8:	020b3023          	sd	zero,32(s6)
    800022cc:	b7c1                	j	8000228c <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800022ce:	013aca63          	blt	s5,s3,800022e2 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022d2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022d6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022da:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022de:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022ea:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800022ee:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800022f0:	00010497          	auipc	s1,0x10
    800022f4:	4b848493          	addi	s1,s1,1208 # 800127a8 <proc>
        p->state = RUNNING;
    800022f8:	4b8d                	li	s7,3
    800022fa:	b755                	j	8000229e <scheduler+0x66>

00000000800022fc <sched>:
{
    800022fc:	7179                	addi	sp,sp,-48
    800022fe:	f406                	sd	ra,40(sp)
    80002300:	f022                	sd	s0,32(sp)
    80002302:	ec26                	sd	s1,24(sp)
    80002304:	e84a                	sd	s2,16(sp)
    80002306:	e44e                	sd	s3,8(sp)
    80002308:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	9f6080e7          	jalr	-1546(ra) # 80001d00 <myproc>
    80002312:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	92c080e7          	jalr	-1748(ra) # 80000c40 <holding>
    8000231c:	c93d                	beqz	a0,80002392 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000231e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002320:	2781                	sext.w	a5,a5
    80002322:	079e                	slli	a5,a5,0x7
    80002324:	00010717          	auipc	a4,0x10
    80002328:	06470713          	addi	a4,a4,100 # 80012388 <pid_lock>
    8000232c:	97ba                	add	a5,a5,a4
    8000232e:	0987a703          	lw	a4,152(a5)
    80002332:	4785                	li	a5,1
    80002334:	06f71763          	bne	a4,a5,800023a2 <sched+0xa6>
  if(p->state == RUNNING)
    80002338:	5098                	lw	a4,32(s1)
    8000233a:	478d                	li	a5,3
    8000233c:	06f70b63          	beq	a4,a5,800023b2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002340:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002344:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002346:	efb5                	bnez	a5,800023c2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002348:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000234a:	00010917          	auipc	s2,0x10
    8000234e:	03e90913          	addi	s2,s2,62 # 80012388 <pid_lock>
    80002352:	2781                	sext.w	a5,a5
    80002354:	079e                	slli	a5,a5,0x7
    80002356:	97ca                	add	a5,a5,s2
    80002358:	09c7a983          	lw	s3,156(a5)
    8000235c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000235e:	2781                	sext.w	a5,a5
    80002360:	079e                	slli	a5,a5,0x7
    80002362:	00010597          	auipc	a1,0x10
    80002366:	04e58593          	addi	a1,a1,78 # 800123b0 <cpus+0x8>
    8000236a:	95be                	add	a1,a1,a5
    8000236c:	06848513          	addi	a0,s1,104
    80002370:	00000097          	auipc	ra,0x0
    80002374:	55e080e7          	jalr	1374(ra) # 800028ce <swtch>
    80002378:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000237a:	2781                	sext.w	a5,a5
    8000237c:	079e                	slli	a5,a5,0x7
    8000237e:	993e                	add	s2,s2,a5
    80002380:	09392e23          	sw	s3,156(s2)
}
    80002384:	70a2                	ld	ra,40(sp)
    80002386:	7402                	ld	s0,32(sp)
    80002388:	64e2                	ld	s1,24(sp)
    8000238a:	6942                	ld	s2,16(sp)
    8000238c:	69a2                	ld	s3,8(sp)
    8000238e:	6145                	addi	sp,sp,48
    80002390:	8082                	ret
    panic("sched p->lock");
    80002392:	00006517          	auipc	a0,0x6
    80002396:	efe50513          	addi	a0,a0,-258 # 80008290 <digits+0x250>
    8000239a:	ffffe097          	auipc	ra,0xffffe
    8000239e:	1b2080e7          	jalr	434(ra) # 8000054c <panic>
    panic("sched locks");
    800023a2:	00006517          	auipc	a0,0x6
    800023a6:	efe50513          	addi	a0,a0,-258 # 800082a0 <digits+0x260>
    800023aa:	ffffe097          	auipc	ra,0xffffe
    800023ae:	1a2080e7          	jalr	418(ra) # 8000054c <panic>
    panic("sched running");
    800023b2:	00006517          	auipc	a0,0x6
    800023b6:	efe50513          	addi	a0,a0,-258 # 800082b0 <digits+0x270>
    800023ba:	ffffe097          	auipc	ra,0xffffe
    800023be:	192080e7          	jalr	402(ra) # 8000054c <panic>
    panic("sched interruptible");
    800023c2:	00006517          	auipc	a0,0x6
    800023c6:	efe50513          	addi	a0,a0,-258 # 800082c0 <digits+0x280>
    800023ca:	ffffe097          	auipc	ra,0xffffe
    800023ce:	182080e7          	jalr	386(ra) # 8000054c <panic>

00000000800023d2 <exit>:
{
    800023d2:	7179                	addi	sp,sp,-48
    800023d4:	f406                	sd	ra,40(sp)
    800023d6:	f022                	sd	s0,32(sp)
    800023d8:	ec26                	sd	s1,24(sp)
    800023da:	e84a                	sd	s2,16(sp)
    800023dc:	e44e                	sd	s3,8(sp)
    800023de:	e052                	sd	s4,0(sp)
    800023e0:	1800                	addi	s0,sp,48
    800023e2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	91c080e7          	jalr	-1764(ra) # 80001d00 <myproc>
    800023ec:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ee:	00007797          	auipc	a5,0x7
    800023f2:	c2a7b783          	ld	a5,-982(a5) # 80009018 <initproc>
    800023f6:	0d850493          	addi	s1,a0,216
    800023fa:	15850913          	addi	s2,a0,344
    800023fe:	02a79363          	bne	a5,a0,80002424 <exit+0x52>
    panic("init exiting");
    80002402:	00006517          	auipc	a0,0x6
    80002406:	ed650513          	addi	a0,a0,-298 # 800082d8 <digits+0x298>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	142080e7          	jalr	322(ra) # 8000054c <panic>
      fileclose(f);
    80002412:	00002097          	auipc	ra,0x2
    80002416:	3ca080e7          	jalr	970(ra) # 800047dc <fileclose>
      p->ofile[fd] = 0;
    8000241a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000241e:	04a1                	addi	s1,s1,8
    80002420:	01248563          	beq	s1,s2,8000242a <exit+0x58>
    if(p->ofile[fd]){
    80002424:	6088                	ld	a0,0(s1)
    80002426:	f575                	bnez	a0,80002412 <exit+0x40>
    80002428:	bfdd                	j	8000241e <exit+0x4c>
  begin_op();
    8000242a:	00002097          	auipc	ra,0x2
    8000242e:	ee2080e7          	jalr	-286(ra) # 8000430c <begin_op>
  iput(p->cwd);
    80002432:	1589b503          	ld	a0,344(s3)
    80002436:	00001097          	auipc	ra,0x1
    8000243a:	6b6080e7          	jalr	1718(ra) # 80003aec <iput>
  end_op();
    8000243e:	00002097          	auipc	ra,0x2
    80002442:	f4c080e7          	jalr	-180(ra) # 8000438a <end_op>
  p->cwd = 0;
    80002446:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    8000244a:	00007497          	auipc	s1,0x7
    8000244e:	bce48493          	addi	s1,s1,-1074 # 80009018 <initproc>
    80002452:	6088                	ld	a0,0(s1)
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	866080e7          	jalr	-1946(ra) # 80000cba <acquire>
  wakeup1(initproc);
    8000245c:	6088                	ld	a0,0(s1)
    8000245e:	fffff097          	auipc	ra,0xfffff
    80002462:	762080e7          	jalr	1890(ra) # 80001bc0 <wakeup1>
  release(&initproc->lock);
    80002466:	6088                	ld	a0,0(s1)
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	922080e7          	jalr	-1758(ra) # 80000d8a <release>
  acquire(&p->lock);
    80002470:	854e                	mv	a0,s3
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	848080e7          	jalr	-1976(ra) # 80000cba <acquire>
  struct proc *original_parent = p->parent;
    8000247a:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    8000247e:	854e                	mv	a0,s3
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	90a080e7          	jalr	-1782(ra) # 80000d8a <release>
  acquire(&original_parent->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	830080e7          	jalr	-2000(ra) # 80000cba <acquire>
  acquire(&p->lock);
    80002492:	854e                	mv	a0,s3
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	826080e7          	jalr	-2010(ra) # 80000cba <acquire>
  reparent(p);
    8000249c:	854e                	mv	a0,s3
    8000249e:	00000097          	auipc	ra,0x0
    800024a2:	d34080e7          	jalr	-716(ra) # 800021d2 <reparent>
  wakeup1(original_parent);
    800024a6:	8526                	mv	a0,s1
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	718080e7          	jalr	1816(ra) # 80001bc0 <wakeup1>
  p->xstate = status;
    800024b0:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024b4:	4791                	li	a5,4
    800024b6:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	8ce080e7          	jalr	-1842(ra) # 80000d8a <release>
  sched();
    800024c4:	00000097          	auipc	ra,0x0
    800024c8:	e38080e7          	jalr	-456(ra) # 800022fc <sched>
  panic("zombie exit");
    800024cc:	00006517          	auipc	a0,0x6
    800024d0:	e1c50513          	addi	a0,a0,-484 # 800082e8 <digits+0x2a8>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	078080e7          	jalr	120(ra) # 8000054c <panic>

00000000800024dc <yield>:
{
    800024dc:	1101                	addi	sp,sp,-32
    800024de:	ec06                	sd	ra,24(sp)
    800024e0:	e822                	sd	s0,16(sp)
    800024e2:	e426                	sd	s1,8(sp)
    800024e4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024e6:	00000097          	auipc	ra,0x0
    800024ea:	81a080e7          	jalr	-2022(ra) # 80001d00 <myproc>
    800024ee:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	7ca080e7          	jalr	1994(ra) # 80000cba <acquire>
  p->state = RUNNABLE;
    800024f8:	4789                	li	a5,2
    800024fa:	d09c                	sw	a5,32(s1)
  sched();
    800024fc:	00000097          	auipc	ra,0x0
    80002500:	e00080e7          	jalr	-512(ra) # 800022fc <sched>
  release(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	884080e7          	jalr	-1916(ra) # 80000d8a <release>
}
    8000250e:	60e2                	ld	ra,24(sp)
    80002510:	6442                	ld	s0,16(sp)
    80002512:	64a2                	ld	s1,8(sp)
    80002514:	6105                	addi	sp,sp,32
    80002516:	8082                	ret

0000000080002518 <sleep>:
{
    80002518:	7179                	addi	sp,sp,-48
    8000251a:	f406                	sd	ra,40(sp)
    8000251c:	f022                	sd	s0,32(sp)
    8000251e:	ec26                	sd	s1,24(sp)
    80002520:	e84a                	sd	s2,16(sp)
    80002522:	e44e                	sd	s3,8(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	89aa                	mv	s3,a0
    80002528:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	7d6080e7          	jalr	2006(ra) # 80001d00 <myproc>
    80002532:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002534:	05250663          	beq	a0,s2,80002580 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	782080e7          	jalr	1922(ra) # 80000cba <acquire>
    release(lk);
    80002540:	854a                	mv	a0,s2
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	848080e7          	jalr	-1976(ra) # 80000d8a <release>
  p->chan = chan;
    8000254a:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    8000254e:	4785                	li	a5,1
    80002550:	d09c                	sw	a5,32(s1)
  sched();
    80002552:	00000097          	auipc	ra,0x0
    80002556:	daa080e7          	jalr	-598(ra) # 800022fc <sched>
  p->chan = 0;
    8000255a:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    8000255e:	8526                	mv	a0,s1
    80002560:	fffff097          	auipc	ra,0xfffff
    80002564:	82a080e7          	jalr	-2006(ra) # 80000d8a <release>
    acquire(lk);
    80002568:	854a                	mv	a0,s2
    8000256a:	ffffe097          	auipc	ra,0xffffe
    8000256e:	750080e7          	jalr	1872(ra) # 80000cba <acquire>
}
    80002572:	70a2                	ld	ra,40(sp)
    80002574:	7402                	ld	s0,32(sp)
    80002576:	64e2                	ld	s1,24(sp)
    80002578:	6942                	ld	s2,16(sp)
    8000257a:	69a2                	ld	s3,8(sp)
    8000257c:	6145                	addi	sp,sp,48
    8000257e:	8082                	ret
  p->chan = chan;
    80002580:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002584:	4785                	li	a5,1
    80002586:	d11c                	sw	a5,32(a0)
  sched();
    80002588:	00000097          	auipc	ra,0x0
    8000258c:	d74080e7          	jalr	-652(ra) # 800022fc <sched>
  p->chan = 0;
    80002590:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    80002594:	bff9                	j	80002572 <sleep+0x5a>

0000000080002596 <wait>:
{
    80002596:	715d                	addi	sp,sp,-80
    80002598:	e486                	sd	ra,72(sp)
    8000259a:	e0a2                	sd	s0,64(sp)
    8000259c:	fc26                	sd	s1,56(sp)
    8000259e:	f84a                	sd	s2,48(sp)
    800025a0:	f44e                	sd	s3,40(sp)
    800025a2:	f052                	sd	s4,32(sp)
    800025a4:	ec56                	sd	s5,24(sp)
    800025a6:	e85a                	sd	s6,16(sp)
    800025a8:	e45e                	sd	s7,8(sp)
    800025aa:	0880                	addi	s0,sp,80
    800025ac:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025ae:	fffff097          	auipc	ra,0xfffff
    800025b2:	752080e7          	jalr	1874(ra) # 80001d00 <myproc>
    800025b6:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	702080e7          	jalr	1794(ra) # 80000cba <acquire>
    havekids = 0;
    800025c0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025c2:	4a11                	li	s4,4
        havekids = 1;
    800025c4:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025c6:	00016997          	auipc	s3,0x16
    800025ca:	de298993          	addi	s3,s3,-542 # 800183a8 <tickslock>
    havekids = 0;
    800025ce:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025d0:	00010497          	auipc	s1,0x10
    800025d4:	1d848493          	addi	s1,s1,472 # 800127a8 <proc>
    800025d8:	a08d                	j	8000263a <wait+0xa4>
          pid = np->pid;
    800025da:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025de:	000b0e63          	beqz	s6,800025fa <wait+0x64>
    800025e2:	4691                	li	a3,4
    800025e4:	03c48613          	addi	a2,s1,60
    800025e8:	85da                	mv	a1,s6
    800025ea:	05893503          	ld	a0,88(s2)
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	408080e7          	jalr	1032(ra) # 800019f6 <copyout>
    800025f6:	02054263          	bltz	a0,8000261a <wait+0x84>
          freeproc(np);
    800025fa:	8526                	mv	a0,s1
    800025fc:	00000097          	auipc	ra,0x0
    80002600:	8b6080e7          	jalr	-1866(ra) # 80001eb2 <freeproc>
          release(&np->lock);
    80002604:	8526                	mv	a0,s1
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	784080e7          	jalr	1924(ra) # 80000d8a <release>
          release(&p->lock);
    8000260e:	854a                	mv	a0,s2
    80002610:	ffffe097          	auipc	ra,0xffffe
    80002614:	77a080e7          	jalr	1914(ra) # 80000d8a <release>
          return pid;
    80002618:	a8a9                	j	80002672 <wait+0xdc>
            release(&np->lock);
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	76e080e7          	jalr	1902(ra) # 80000d8a <release>
            release(&p->lock);
    80002624:	854a                	mv	a0,s2
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	764080e7          	jalr	1892(ra) # 80000d8a <release>
            return -1;
    8000262e:	59fd                	li	s3,-1
    80002630:	a089                	j	80002672 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    80002632:	17048493          	addi	s1,s1,368
    80002636:	03348463          	beq	s1,s3,8000265e <wait+0xc8>
      if(np->parent == p){
    8000263a:	749c                	ld	a5,40(s1)
    8000263c:	ff279be3          	bne	a5,s2,80002632 <wait+0x9c>
        acquire(&np->lock);
    80002640:	8526                	mv	a0,s1
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	678080e7          	jalr	1656(ra) # 80000cba <acquire>
        if(np->state == ZOMBIE){
    8000264a:	509c                	lw	a5,32(s1)
    8000264c:	f94787e3          	beq	a5,s4,800025da <wait+0x44>
        release(&np->lock);
    80002650:	8526                	mv	a0,s1
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	738080e7          	jalr	1848(ra) # 80000d8a <release>
        havekids = 1;
    8000265a:	8756                	mv	a4,s5
    8000265c:	bfd9                	j	80002632 <wait+0x9c>
    if(!havekids || p->killed){
    8000265e:	c701                	beqz	a4,80002666 <wait+0xd0>
    80002660:	03892783          	lw	a5,56(s2)
    80002664:	c39d                	beqz	a5,8000268a <wait+0xf4>
      release(&p->lock);
    80002666:	854a                	mv	a0,s2
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	722080e7          	jalr	1826(ra) # 80000d8a <release>
      return -1;
    80002670:	59fd                	li	s3,-1
}
    80002672:	854e                	mv	a0,s3
    80002674:	60a6                	ld	ra,72(sp)
    80002676:	6406                	ld	s0,64(sp)
    80002678:	74e2                	ld	s1,56(sp)
    8000267a:	7942                	ld	s2,48(sp)
    8000267c:	79a2                	ld	s3,40(sp)
    8000267e:	7a02                	ld	s4,32(sp)
    80002680:	6ae2                	ld	s5,24(sp)
    80002682:	6b42                	ld	s6,16(sp)
    80002684:	6ba2                	ld	s7,8(sp)
    80002686:	6161                	addi	sp,sp,80
    80002688:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000268a:	85ca                	mv	a1,s2
    8000268c:	854a                	mv	a0,s2
    8000268e:	00000097          	auipc	ra,0x0
    80002692:	e8a080e7          	jalr	-374(ra) # 80002518 <sleep>
    havekids = 0;
    80002696:	bf25                	j	800025ce <wait+0x38>

0000000080002698 <wakeup>:
{
    80002698:	7139                	addi	sp,sp,-64
    8000269a:	fc06                	sd	ra,56(sp)
    8000269c:	f822                	sd	s0,48(sp)
    8000269e:	f426                	sd	s1,40(sp)
    800026a0:	f04a                	sd	s2,32(sp)
    800026a2:	ec4e                	sd	s3,24(sp)
    800026a4:	e852                	sd	s4,16(sp)
    800026a6:	e456                	sd	s5,8(sp)
    800026a8:	0080                	addi	s0,sp,64
    800026aa:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026ac:	00010497          	auipc	s1,0x10
    800026b0:	0fc48493          	addi	s1,s1,252 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026b4:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026b6:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026b8:	00016917          	auipc	s2,0x16
    800026bc:	cf090913          	addi	s2,s2,-784 # 800183a8 <tickslock>
    800026c0:	a811                	j	800026d4 <wakeup+0x3c>
    release(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	6c6080e7          	jalr	1734(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026cc:	17048493          	addi	s1,s1,368
    800026d0:	03248063          	beq	s1,s2,800026f0 <wakeup+0x58>
    acquire(&p->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5e4080e7          	jalr	1508(ra) # 80000cba <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800026de:	509c                	lw	a5,32(s1)
    800026e0:	ff3791e3          	bne	a5,s3,800026c2 <wakeup+0x2a>
    800026e4:	789c                	ld	a5,48(s1)
    800026e6:	fd479ee3          	bne	a5,s4,800026c2 <wakeup+0x2a>
      p->state = RUNNABLE;
    800026ea:	0354a023          	sw	s5,32(s1)
    800026ee:	bfd1                	j	800026c2 <wakeup+0x2a>
}
    800026f0:	70e2                	ld	ra,56(sp)
    800026f2:	7442                	ld	s0,48(sp)
    800026f4:	74a2                	ld	s1,40(sp)
    800026f6:	7902                	ld	s2,32(sp)
    800026f8:	69e2                	ld	s3,24(sp)
    800026fa:	6a42                	ld	s4,16(sp)
    800026fc:	6aa2                	ld	s5,8(sp)
    800026fe:	6121                	addi	sp,sp,64
    80002700:	8082                	ret

0000000080002702 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002702:	7179                	addi	sp,sp,-48
    80002704:	f406                	sd	ra,40(sp)
    80002706:	f022                	sd	s0,32(sp)
    80002708:	ec26                	sd	s1,24(sp)
    8000270a:	e84a                	sd	s2,16(sp)
    8000270c:	e44e                	sd	s3,8(sp)
    8000270e:	1800                	addi	s0,sp,48
    80002710:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002712:	00010497          	auipc	s1,0x10
    80002716:	09648493          	addi	s1,s1,150 # 800127a8 <proc>
    8000271a:	00016997          	auipc	s3,0x16
    8000271e:	c8e98993          	addi	s3,s3,-882 # 800183a8 <tickslock>
    acquire(&p->lock);
    80002722:	8526                	mv	a0,s1
    80002724:	ffffe097          	auipc	ra,0xffffe
    80002728:	596080e7          	jalr	1430(ra) # 80000cba <acquire>
    if(p->pid == pid){
    8000272c:	40bc                	lw	a5,64(s1)
    8000272e:	01278d63          	beq	a5,s2,80002748 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002732:	8526                	mv	a0,s1
    80002734:	ffffe097          	auipc	ra,0xffffe
    80002738:	656080e7          	jalr	1622(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000273c:	17048493          	addi	s1,s1,368
    80002740:	ff3491e3          	bne	s1,s3,80002722 <kill+0x20>
  }
  return -1;
    80002744:	557d                	li	a0,-1
    80002746:	a821                	j	8000275e <kill+0x5c>
      p->killed = 1;
    80002748:	4785                	li	a5,1
    8000274a:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    8000274c:	5098                	lw	a4,32(s1)
    8000274e:	00f70f63          	beq	a4,a5,8000276c <kill+0x6a>
      release(&p->lock);
    80002752:	8526                	mv	a0,s1
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	636080e7          	jalr	1590(ra) # 80000d8a <release>
      return 0;
    8000275c:	4501                	li	a0,0
}
    8000275e:	70a2                	ld	ra,40(sp)
    80002760:	7402                	ld	s0,32(sp)
    80002762:	64e2                	ld	s1,24(sp)
    80002764:	6942                	ld	s2,16(sp)
    80002766:	69a2                	ld	s3,8(sp)
    80002768:	6145                	addi	sp,sp,48
    8000276a:	8082                	ret
        p->state = RUNNABLE;
    8000276c:	4789                	li	a5,2
    8000276e:	d09c                	sw	a5,32(s1)
    80002770:	b7cd                	j	80002752 <kill+0x50>

0000000080002772 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002772:	7179                	addi	sp,sp,-48
    80002774:	f406                	sd	ra,40(sp)
    80002776:	f022                	sd	s0,32(sp)
    80002778:	ec26                	sd	s1,24(sp)
    8000277a:	e84a                	sd	s2,16(sp)
    8000277c:	e44e                	sd	s3,8(sp)
    8000277e:	e052                	sd	s4,0(sp)
    80002780:	1800                	addi	s0,sp,48
    80002782:	84aa                	mv	s1,a0
    80002784:	892e                	mv	s2,a1
    80002786:	89b2                	mv	s3,a2
    80002788:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	576080e7          	jalr	1398(ra) # 80001d00 <myproc>
  if(user_dst){
    80002792:	c08d                	beqz	s1,800027b4 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002794:	86d2                	mv	a3,s4
    80002796:	864e                	mv	a2,s3
    80002798:	85ca                	mv	a1,s2
    8000279a:	6d28                	ld	a0,88(a0)
    8000279c:	fffff097          	auipc	ra,0xfffff
    800027a0:	25a080e7          	jalr	602(ra) # 800019f6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027a4:	70a2                	ld	ra,40(sp)
    800027a6:	7402                	ld	s0,32(sp)
    800027a8:	64e2                	ld	s1,24(sp)
    800027aa:	6942                	ld	s2,16(sp)
    800027ac:	69a2                	ld	s3,8(sp)
    800027ae:	6a02                	ld	s4,0(sp)
    800027b0:	6145                	addi	sp,sp,48
    800027b2:	8082                	ret
    memmove((char *)dst, src, len);
    800027b4:	000a061b          	sext.w	a2,s4
    800027b8:	85ce                	mv	a1,s3
    800027ba:	854a                	mv	a0,s2
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	93a080e7          	jalr	-1734(ra) # 800010f6 <memmove>
    return 0;
    800027c4:	8526                	mv	a0,s1
    800027c6:	bff9                	j	800027a4 <either_copyout+0x32>

00000000800027c8 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027c8:	7179                	addi	sp,sp,-48
    800027ca:	f406                	sd	ra,40(sp)
    800027cc:	f022                	sd	s0,32(sp)
    800027ce:	ec26                	sd	s1,24(sp)
    800027d0:	e84a                	sd	s2,16(sp)
    800027d2:	e44e                	sd	s3,8(sp)
    800027d4:	e052                	sd	s4,0(sp)
    800027d6:	1800                	addi	s0,sp,48
    800027d8:	892a                	mv	s2,a0
    800027da:	84ae                	mv	s1,a1
    800027dc:	89b2                	mv	s3,a2
    800027de:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	520080e7          	jalr	1312(ra) # 80001d00 <myproc>
  if(user_src){
    800027e8:	c08d                	beqz	s1,8000280a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027ea:	86d2                	mv	a3,s4
    800027ec:	864e                	mv	a2,s3
    800027ee:	85ca                	mv	a1,s2
    800027f0:	6d28                	ld	a0,88(a0)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	290080e7          	jalr	656(ra) # 80001a82 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027fa:	70a2                	ld	ra,40(sp)
    800027fc:	7402                	ld	s0,32(sp)
    800027fe:	64e2                	ld	s1,24(sp)
    80002800:	6942                	ld	s2,16(sp)
    80002802:	69a2                	ld	s3,8(sp)
    80002804:	6a02                	ld	s4,0(sp)
    80002806:	6145                	addi	sp,sp,48
    80002808:	8082                	ret
    memmove(dst, (char*)src, len);
    8000280a:	000a061b          	sext.w	a2,s4
    8000280e:	85ce                	mv	a1,s3
    80002810:	854a                	mv	a0,s2
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	8e4080e7          	jalr	-1820(ra) # 800010f6 <memmove>
    return 0;
    8000281a:	8526                	mv	a0,s1
    8000281c:	bff9                	j	800027fa <either_copyin+0x32>

000000008000281e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000281e:	715d                	addi	sp,sp,-80
    80002820:	e486                	sd	ra,72(sp)
    80002822:	e0a2                	sd	s0,64(sp)
    80002824:	fc26                	sd	s1,56(sp)
    80002826:	f84a                	sd	s2,48(sp)
    80002828:	f44e                	sd	s3,40(sp)
    8000282a:	f052                	sd	s4,32(sp)
    8000282c:	ec56                	sd	s5,24(sp)
    8000282e:	e85a                	sd	s6,16(sp)
    80002830:	e45e                	sd	s7,8(sp)
    80002832:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002834:	00006517          	auipc	a0,0x6
    80002838:	92c50513          	addi	a0,a0,-1748 # 80008160 <digits+0x120>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d5a080e7          	jalr	-678(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002844:	00010497          	auipc	s1,0x10
    80002848:	0c448493          	addi	s1,s1,196 # 80012908 <proc+0x160>
    8000284c:	00016917          	auipc	s2,0x16
    80002850:	cbc90913          	addi	s2,s2,-836 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002854:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002856:	00006997          	auipc	s3,0x6
    8000285a:	aa298993          	addi	s3,s3,-1374 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    8000285e:	00006a97          	auipc	s5,0x6
    80002862:	aa2a8a93          	addi	s5,s5,-1374 # 80008300 <digits+0x2c0>
    printf("\n");
    80002866:	00006a17          	auipc	s4,0x6
    8000286a:	8faa0a13          	addi	s4,s4,-1798 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000286e:	00006b97          	auipc	s7,0x6
    80002872:	acab8b93          	addi	s7,s7,-1334 # 80008338 <states.0>
    80002876:	a00d                	j	80002898 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002878:	ee06a583          	lw	a1,-288(a3)
    8000287c:	8556                	mv	a0,s5
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	d18080e7          	jalr	-744(ra) # 80000596 <printf>
    printf("\n");
    80002886:	8552                	mv	a0,s4
    80002888:	ffffe097          	auipc	ra,0xffffe
    8000288c:	d0e080e7          	jalr	-754(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002890:	17048493          	addi	s1,s1,368
    80002894:	03248263          	beq	s1,s2,800028b8 <procdump+0x9a>
    if(p->state == UNUSED)
    80002898:	86a6                	mv	a3,s1
    8000289a:	ec04a783          	lw	a5,-320(s1)
    8000289e:	dbed                	beqz	a5,80002890 <procdump+0x72>
      state = "???";
    800028a0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028a2:	fcfb6be3          	bltu	s6,a5,80002878 <procdump+0x5a>
    800028a6:	02079713          	slli	a4,a5,0x20
    800028aa:	01d75793          	srli	a5,a4,0x1d
    800028ae:	97de                	add	a5,a5,s7
    800028b0:	6390                	ld	a2,0(a5)
    800028b2:	f279                	bnez	a2,80002878 <procdump+0x5a>
      state = "???";
    800028b4:	864e                	mv	a2,s3
    800028b6:	b7c9                	j	80002878 <procdump+0x5a>
  }
}
    800028b8:	60a6                	ld	ra,72(sp)
    800028ba:	6406                	ld	s0,64(sp)
    800028bc:	74e2                	ld	s1,56(sp)
    800028be:	7942                	ld	s2,48(sp)
    800028c0:	79a2                	ld	s3,40(sp)
    800028c2:	7a02                	ld	s4,32(sp)
    800028c4:	6ae2                	ld	s5,24(sp)
    800028c6:	6b42                	ld	s6,16(sp)
    800028c8:	6ba2                	ld	s7,8(sp)
    800028ca:	6161                	addi	sp,sp,80
    800028cc:	8082                	ret

00000000800028ce <swtch>:
    800028ce:	00153023          	sd	ra,0(a0)
    800028d2:	00253423          	sd	sp,8(a0)
    800028d6:	e900                	sd	s0,16(a0)
    800028d8:	ed04                	sd	s1,24(a0)
    800028da:	03253023          	sd	s2,32(a0)
    800028de:	03353423          	sd	s3,40(a0)
    800028e2:	03453823          	sd	s4,48(a0)
    800028e6:	03553c23          	sd	s5,56(a0)
    800028ea:	05653023          	sd	s6,64(a0)
    800028ee:	05753423          	sd	s7,72(a0)
    800028f2:	05853823          	sd	s8,80(a0)
    800028f6:	05953c23          	sd	s9,88(a0)
    800028fa:	07a53023          	sd	s10,96(a0)
    800028fe:	07b53423          	sd	s11,104(a0)
    80002902:	0005b083          	ld	ra,0(a1)
    80002906:	0085b103          	ld	sp,8(a1)
    8000290a:	6980                	ld	s0,16(a1)
    8000290c:	6d84                	ld	s1,24(a1)
    8000290e:	0205b903          	ld	s2,32(a1)
    80002912:	0285b983          	ld	s3,40(a1)
    80002916:	0305ba03          	ld	s4,48(a1)
    8000291a:	0385ba83          	ld	s5,56(a1)
    8000291e:	0405bb03          	ld	s6,64(a1)
    80002922:	0485bb83          	ld	s7,72(a1)
    80002926:	0505bc03          	ld	s8,80(a1)
    8000292a:	0585bc83          	ld	s9,88(a1)
    8000292e:	0605bd03          	ld	s10,96(a1)
    80002932:	0685bd83          	ld	s11,104(a1)
    80002936:	8082                	ret

0000000080002938 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002938:	1141                	addi	sp,sp,-16
    8000293a:	e406                	sd	ra,8(sp)
    8000293c:	e022                	sd	s0,0(sp)
    8000293e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002940:	00006597          	auipc	a1,0x6
    80002944:	a2058593          	addi	a1,a1,-1504 # 80008360 <states.0+0x28>
    80002948:	00016517          	auipc	a0,0x16
    8000294c:	a6050513          	addi	a0,a0,-1440 # 800183a8 <tickslock>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	4e6080e7          	jalr	1254(ra) # 80000e36 <initlock>
}
    80002958:	60a2                	ld	ra,8(sp)
    8000295a:	6402                	ld	s0,0(sp)
    8000295c:	0141                	addi	sp,sp,16
    8000295e:	8082                	ret

0000000080002960 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002960:	1141                	addi	sp,sp,-16
    80002962:	e422                	sd	s0,8(sp)
    80002964:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002966:	00003797          	auipc	a5,0x3
    8000296a:	4ea78793          	addi	a5,a5,1258 # 80005e50 <kernelvec>
    8000296e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002972:	6422                	ld	s0,8(sp)
    80002974:	0141                	addi	sp,sp,16
    80002976:	8082                	ret

0000000080002978 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002978:	1141                	addi	sp,sp,-16
    8000297a:	e406                	sd	ra,8(sp)
    8000297c:	e022                	sd	s0,0(sp)
    8000297e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002980:	fffff097          	auipc	ra,0xfffff
    80002984:	380080e7          	jalr	896(ra) # 80001d00 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002988:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000298c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000298e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002992:	00004697          	auipc	a3,0x4
    80002996:	66e68693          	addi	a3,a3,1646 # 80007000 <_trampoline>
    8000299a:	00004717          	auipc	a4,0x4
    8000299e:	66670713          	addi	a4,a4,1638 # 80007000 <_trampoline>
    800029a2:	8f15                	sub	a4,a4,a3
    800029a4:	040007b7          	lui	a5,0x4000
    800029a8:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029aa:	07b2                	slli	a5,a5,0xc
    800029ac:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ae:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029b2:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029b4:	18002673          	csrr	a2,satp
    800029b8:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029ba:	7130                	ld	a2,96(a0)
    800029bc:	6538                	ld	a4,72(a0)
    800029be:	6585                	lui	a1,0x1
    800029c0:	972e                	add	a4,a4,a1
    800029c2:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029c4:	7138                	ld	a4,96(a0)
    800029c6:	00000617          	auipc	a2,0x0
    800029ca:	13860613          	addi	a2,a2,312 # 80002afe <usertrap>
    800029ce:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029d0:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029d2:	8612                	mv	a2,tp
    800029d4:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d6:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029da:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029de:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e2:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029e6:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029e8:	6f18                	ld	a4,24(a4)
    800029ea:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ee:	6d2c                	ld	a1,88(a0)
    800029f0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029f2:	00004717          	auipc	a4,0x4
    800029f6:	69e70713          	addi	a4,a4,1694 # 80007090 <userret>
    800029fa:	8f15                	sub	a4,a4,a3
    800029fc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029fe:	577d                	li	a4,-1
    80002a00:	177e                	slli	a4,a4,0x3f
    80002a02:	8dd9                	or	a1,a1,a4
    80002a04:	02000537          	lui	a0,0x2000
    80002a08:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a0a:	0536                	slli	a0,a0,0xd
    80002a0c:	9782                	jalr	a5
}
    80002a0e:	60a2                	ld	ra,8(sp)
    80002a10:	6402                	ld	s0,0(sp)
    80002a12:	0141                	addi	sp,sp,16
    80002a14:	8082                	ret

0000000080002a16 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a16:	1101                	addi	sp,sp,-32
    80002a18:	ec06                	sd	ra,24(sp)
    80002a1a:	e822                	sd	s0,16(sp)
    80002a1c:	e426                	sd	s1,8(sp)
    80002a1e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a20:	00016497          	auipc	s1,0x16
    80002a24:	98848493          	addi	s1,s1,-1656 # 800183a8 <tickslock>
    80002a28:	8526                	mv	a0,s1
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	290080e7          	jalr	656(ra) # 80000cba <acquire>
  ticks++;
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	5ee50513          	addi	a0,a0,1518 # 80009020 <ticks>
    80002a3a:	411c                	lw	a5,0(a0)
    80002a3c:	2785                	addiw	a5,a5,1
    80002a3e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a40:	00000097          	auipc	ra,0x0
    80002a44:	c58080e7          	jalr	-936(ra) # 80002698 <wakeup>
  release(&tickslock);
    80002a48:	8526                	mv	a0,s1
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	340080e7          	jalr	832(ra) # 80000d8a <release>
}
    80002a52:	60e2                	ld	ra,24(sp)
    80002a54:	6442                	ld	s0,16(sp)
    80002a56:	64a2                	ld	s1,8(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret

0000000080002a5c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a5c:	1101                	addi	sp,sp,-32
    80002a5e:	ec06                	sd	ra,24(sp)
    80002a60:	e822                	sd	s0,16(sp)
    80002a62:	e426                	sd	s1,8(sp)
    80002a64:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a66:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a6a:	00074d63          	bltz	a4,80002a84 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a6e:	57fd                	li	a5,-1
    80002a70:	17fe                	slli	a5,a5,0x3f
    80002a72:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a74:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a76:	06f70363          	beq	a4,a5,80002adc <devintr+0x80>
  }
}
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret
     (scause & 0xff) == 9){
    80002a84:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002a88:	46a5                	li	a3,9
    80002a8a:	fed792e3          	bne	a5,a3,80002a6e <devintr+0x12>
    int irq = plic_claim();
    80002a8e:	00003097          	auipc	ra,0x3
    80002a92:	4ca080e7          	jalr	1226(ra) # 80005f58 <plic_claim>
    80002a96:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a98:	47a9                	li	a5,10
    80002a9a:	02f50763          	beq	a0,a5,80002ac8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a9e:	4785                	li	a5,1
    80002aa0:	02f50963          	beq	a0,a5,80002ad2 <devintr+0x76>
    return 1;
    80002aa4:	4505                	li	a0,1
    } else if(irq){
    80002aa6:	d8f1                	beqz	s1,80002a7a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002aa8:	85a6                	mv	a1,s1
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	8be50513          	addi	a0,a0,-1858 # 80008368 <states.0+0x30>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ae4080e7          	jalr	-1308(ra) # 80000596 <printf>
      plic_complete(irq);
    80002aba:	8526                	mv	a0,s1
    80002abc:	00003097          	auipc	ra,0x3
    80002ac0:	4c0080e7          	jalr	1216(ra) # 80005f7c <plic_complete>
    return 1;
    80002ac4:	4505                	li	a0,1
    80002ac6:	bf55                	j	80002a7a <devintr+0x1e>
      uartintr();
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	f00080e7          	jalr	-256(ra) # 800009c8 <uartintr>
    80002ad0:	b7ed                	j	80002aba <devintr+0x5e>
      virtio_disk_intr();
    80002ad2:	00004097          	auipc	ra,0x4
    80002ad6:	936080e7          	jalr	-1738(ra) # 80006408 <virtio_disk_intr>
    80002ada:	b7c5                	j	80002aba <devintr+0x5e>
    if(cpuid() == 0){
    80002adc:	fffff097          	auipc	ra,0xfffff
    80002ae0:	1f8080e7          	jalr	504(ra) # 80001cd4 <cpuid>
    80002ae4:	c901                	beqz	a0,80002af4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ae6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aec:	14479073          	csrw	sip,a5
    return 2;
    80002af0:	4509                	li	a0,2
    80002af2:	b761                	j	80002a7a <devintr+0x1e>
      clockintr();
    80002af4:	00000097          	auipc	ra,0x0
    80002af8:	f22080e7          	jalr	-222(ra) # 80002a16 <clockintr>
    80002afc:	b7ed                	j	80002ae6 <devintr+0x8a>

0000000080002afe <usertrap>:
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	e04a                	sd	s2,0(sp)
    80002b08:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b0e:	1007f793          	andi	a5,a5,256
    80002b12:	e3ad                	bnez	a5,80002b74 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b14:	00003797          	auipc	a5,0x3
    80002b18:	33c78793          	addi	a5,a5,828 # 80005e50 <kernelvec>
    80002b1c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	1e0080e7          	jalr	480(ra) # 80001d00 <myproc>
    80002b28:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b2a:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b2c:	14102773          	csrr	a4,sepc
    80002b30:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b32:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b36:	47a1                	li	a5,8
    80002b38:	04f71c63          	bne	a4,a5,80002b90 <usertrap+0x92>
    if(p->killed)
    80002b3c:	5d1c                	lw	a5,56(a0)
    80002b3e:	e3b9                	bnez	a5,80002b84 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b40:	70b8                	ld	a4,96(s1)
    80002b42:	6f1c                	ld	a5,24(a4)
    80002b44:	0791                	addi	a5,a5,4
    80002b46:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b50:	10079073          	csrw	sstatus,a5
    syscall();
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	2e0080e7          	jalr	736(ra) # 80002e34 <syscall>
  if(p->killed)
    80002b5c:	5c9c                	lw	a5,56(s1)
    80002b5e:	ebc1                	bnez	a5,80002bee <usertrap+0xf0>
  usertrapret();
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	e18080e7          	jalr	-488(ra) # 80002978 <usertrapret>
}
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	64a2                	ld	s1,8(sp)
    80002b6e:	6902                	ld	s2,0(sp)
    80002b70:	6105                	addi	sp,sp,32
    80002b72:	8082                	ret
    panic("usertrap: not from user mode");
    80002b74:	00006517          	auipc	a0,0x6
    80002b78:	81450513          	addi	a0,a0,-2028 # 80008388 <states.0+0x50>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	9d0080e7          	jalr	-1584(ra) # 8000054c <panic>
      exit(-1);
    80002b84:	557d                	li	a0,-1
    80002b86:	00000097          	auipc	ra,0x0
    80002b8a:	84c080e7          	jalr	-1972(ra) # 800023d2 <exit>
    80002b8e:	bf4d                	j	80002b40 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b90:	00000097          	auipc	ra,0x0
    80002b94:	ecc080e7          	jalr	-308(ra) # 80002a5c <devintr>
    80002b98:	892a                	mv	s2,a0
    80002b9a:	c501                	beqz	a0,80002ba2 <usertrap+0xa4>
  if(p->killed)
    80002b9c:	5c9c                	lw	a5,56(s1)
    80002b9e:	c3a1                	beqz	a5,80002bde <usertrap+0xe0>
    80002ba0:	a815                	j	80002bd4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ba2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ba6:	40b0                	lw	a2,64(s1)
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	80050513          	addi	a0,a0,-2048 # 800083a8 <states.0+0x70>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	9e6080e7          	jalr	-1562(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bbc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc0:	00006517          	auipc	a0,0x6
    80002bc4:	81850513          	addi	a0,a0,-2024 # 800083d8 <states.0+0xa0>
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	9ce080e7          	jalr	-1586(ra) # 80000596 <printf>
    p->killed = 1;
    80002bd0:	4785                	li	a5,1
    80002bd2:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002bd4:	557d                	li	a0,-1
    80002bd6:	fffff097          	auipc	ra,0xfffff
    80002bda:	7fc080e7          	jalr	2044(ra) # 800023d2 <exit>
  if(which_dev == 2)
    80002bde:	4789                	li	a5,2
    80002be0:	f8f910e3          	bne	s2,a5,80002b60 <usertrap+0x62>
    yield();
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	8f8080e7          	jalr	-1800(ra) # 800024dc <yield>
    80002bec:	bf95                	j	80002b60 <usertrap+0x62>
  int which_dev = 0;
    80002bee:	4901                	li	s2,0
    80002bf0:	b7d5                	j	80002bd4 <usertrap+0xd6>

0000000080002bf2 <kerneltrap>:
{
    80002bf2:	7179                	addi	sp,sp,-48
    80002bf4:	f406                	sd	ra,40(sp)
    80002bf6:	f022                	sd	s0,32(sp)
    80002bf8:	ec26                	sd	s1,24(sp)
    80002bfa:	e84a                	sd	s2,16(sp)
    80002bfc:	e44e                	sd	s3,8(sp)
    80002bfe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c0c:	1004f793          	andi	a5,s1,256
    80002c10:	cb85                	beqz	a5,80002c40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c18:	ef85                	bnez	a5,80002c50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c1a:	00000097          	auipc	ra,0x0
    80002c1e:	e42080e7          	jalr	-446(ra) # 80002a5c <devintr>
    80002c22:	cd1d                	beqz	a0,80002c60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c24:	4789                	li	a5,2
    80002c26:	06f50a63          	beq	a0,a5,80002c9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2e:	10049073          	csrw	sstatus,s1
}
    80002c32:	70a2                	ld	ra,40(sp)
    80002c34:	7402                	ld	s0,32(sp)
    80002c36:	64e2                	ld	s1,24(sp)
    80002c38:	6942                	ld	s2,16(sp)
    80002c3a:	69a2                	ld	s3,8(sp)
    80002c3c:	6145                	addi	sp,sp,48
    80002c3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c40:	00005517          	auipc	a0,0x5
    80002c44:	7b850513          	addi	a0,a0,1976 # 800083f8 <states.0+0xc0>
    80002c48:	ffffe097          	auipc	ra,0xffffe
    80002c4c:	904080e7          	jalr	-1788(ra) # 8000054c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c50:	00005517          	auipc	a0,0x5
    80002c54:	7d050513          	addi	a0,a0,2000 # 80008420 <states.0+0xe8>
    80002c58:	ffffe097          	auipc	ra,0xffffe
    80002c5c:	8f4080e7          	jalr	-1804(ra) # 8000054c <panic>
    printf("scause %p\n", scause);
    80002c60:	85ce                	mv	a1,s3
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	7de50513          	addi	a0,a0,2014 # 80008440 <states.0+0x108>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	92c080e7          	jalr	-1748(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c7a:	00005517          	auipc	a0,0x5
    80002c7e:	7d650513          	addi	a0,a0,2006 # 80008450 <states.0+0x118>
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	914080e7          	jalr	-1772(ra) # 80000596 <printf>
    panic("kerneltrap");
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	7de50513          	addi	a0,a0,2014 # 80008468 <states.0+0x130>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8ba080e7          	jalr	-1862(ra) # 8000054c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	066080e7          	jalr	102(ra) # 80001d00 <myproc>
    80002ca2:	d541                	beqz	a0,80002c2a <kerneltrap+0x38>
    80002ca4:	fffff097          	auipc	ra,0xfffff
    80002ca8:	05c080e7          	jalr	92(ra) # 80001d00 <myproc>
    80002cac:	5118                	lw	a4,32(a0)
    80002cae:	478d                	li	a5,3
    80002cb0:	f6f71de3          	bne	a4,a5,80002c2a <kerneltrap+0x38>
    yield();
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	828080e7          	jalr	-2008(ra) # 800024dc <yield>
    80002cbc:	b7bd                	j	80002c2a <kerneltrap+0x38>

0000000080002cbe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	e426                	sd	s1,8(sp)
    80002cc6:	1000                	addi	s0,sp,32
    80002cc8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	036080e7          	jalr	54(ra) # 80001d00 <myproc>
  switch (n) {
    80002cd2:	4795                	li	a5,5
    80002cd4:	0497e163          	bltu	a5,s1,80002d16 <argraw+0x58>
    80002cd8:	048a                	slli	s1,s1,0x2
    80002cda:	00005717          	auipc	a4,0x5
    80002cde:	7c670713          	addi	a4,a4,1990 # 800084a0 <states.0+0x168>
    80002ce2:	94ba                	add	s1,s1,a4
    80002ce4:	409c                	lw	a5,0(s1)
    80002ce6:	97ba                	add	a5,a5,a4
    80002ce8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cea:	713c                	ld	a5,96(a0)
    80002cec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cee:	60e2                	ld	ra,24(sp)
    80002cf0:	6442                	ld	s0,16(sp)
    80002cf2:	64a2                	ld	s1,8(sp)
    80002cf4:	6105                	addi	sp,sp,32
    80002cf6:	8082                	ret
    return p->trapframe->a1;
    80002cf8:	713c                	ld	a5,96(a0)
    80002cfa:	7fa8                	ld	a0,120(a5)
    80002cfc:	bfcd                	j	80002cee <argraw+0x30>
    return p->trapframe->a2;
    80002cfe:	713c                	ld	a5,96(a0)
    80002d00:	63c8                	ld	a0,128(a5)
    80002d02:	b7f5                	j	80002cee <argraw+0x30>
    return p->trapframe->a3;
    80002d04:	713c                	ld	a5,96(a0)
    80002d06:	67c8                	ld	a0,136(a5)
    80002d08:	b7dd                	j	80002cee <argraw+0x30>
    return p->trapframe->a4;
    80002d0a:	713c                	ld	a5,96(a0)
    80002d0c:	6bc8                	ld	a0,144(a5)
    80002d0e:	b7c5                	j	80002cee <argraw+0x30>
    return p->trapframe->a5;
    80002d10:	713c                	ld	a5,96(a0)
    80002d12:	6fc8                	ld	a0,152(a5)
    80002d14:	bfe9                	j	80002cee <argraw+0x30>
  panic("argraw");
    80002d16:	00005517          	auipc	a0,0x5
    80002d1a:	76250513          	addi	a0,a0,1890 # 80008478 <states.0+0x140>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	82e080e7          	jalr	-2002(ra) # 8000054c <panic>

0000000080002d26 <fetchaddr>:
{
    80002d26:	1101                	addi	sp,sp,-32
    80002d28:	ec06                	sd	ra,24(sp)
    80002d2a:	e822                	sd	s0,16(sp)
    80002d2c:	e426                	sd	s1,8(sp)
    80002d2e:	e04a                	sd	s2,0(sp)
    80002d30:	1000                	addi	s0,sp,32
    80002d32:	84aa                	mv	s1,a0
    80002d34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	fca080e7          	jalr	-54(ra) # 80001d00 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d3e:	693c                	ld	a5,80(a0)
    80002d40:	02f4f863          	bgeu	s1,a5,80002d70 <fetchaddr+0x4a>
    80002d44:	00848713          	addi	a4,s1,8
    80002d48:	02e7e663          	bltu	a5,a4,80002d74 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d4c:	46a1                	li	a3,8
    80002d4e:	8626                	mv	a2,s1
    80002d50:	85ca                	mv	a1,s2
    80002d52:	6d28                	ld	a0,88(a0)
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	d2e080e7          	jalr	-722(ra) # 80001a82 <copyin>
    80002d5c:	00a03533          	snez	a0,a0
    80002d60:	40a00533          	neg	a0,a0
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	64a2                	ld	s1,8(sp)
    80002d6a:	6902                	ld	s2,0(sp)
    80002d6c:	6105                	addi	sp,sp,32
    80002d6e:	8082                	ret
    return -1;
    80002d70:	557d                	li	a0,-1
    80002d72:	bfcd                	j	80002d64 <fetchaddr+0x3e>
    80002d74:	557d                	li	a0,-1
    80002d76:	b7fd                	j	80002d64 <fetchaddr+0x3e>

0000000080002d78 <fetchstr>:
{
    80002d78:	7179                	addi	sp,sp,-48
    80002d7a:	f406                	sd	ra,40(sp)
    80002d7c:	f022                	sd	s0,32(sp)
    80002d7e:	ec26                	sd	s1,24(sp)
    80002d80:	e84a                	sd	s2,16(sp)
    80002d82:	e44e                	sd	s3,8(sp)
    80002d84:	1800                	addi	s0,sp,48
    80002d86:	892a                	mv	s2,a0
    80002d88:	84ae                	mv	s1,a1
    80002d8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d8c:	fffff097          	auipc	ra,0xfffff
    80002d90:	f74080e7          	jalr	-140(ra) # 80001d00 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d94:	86ce                	mv	a3,s3
    80002d96:	864a                	mv	a2,s2
    80002d98:	85a6                	mv	a1,s1
    80002d9a:	6d28                	ld	a0,88(a0)
    80002d9c:	fffff097          	auipc	ra,0xfffff
    80002da0:	d74080e7          	jalr	-652(ra) # 80001b10 <copyinstr>
  if(err < 0)
    80002da4:	00054763          	bltz	a0,80002db2 <fetchstr+0x3a>
  return strlen(buf);
    80002da8:	8526                	mv	a0,s1
    80002daa:	ffffe097          	auipc	ra,0xffffe
    80002dae:	474080e7          	jalr	1140(ra) # 8000121e <strlen>
}
    80002db2:	70a2                	ld	ra,40(sp)
    80002db4:	7402                	ld	s0,32(sp)
    80002db6:	64e2                	ld	s1,24(sp)
    80002db8:	6942                	ld	s2,16(sp)
    80002dba:	69a2                	ld	s3,8(sp)
    80002dbc:	6145                	addi	sp,sp,48
    80002dbe:	8082                	ret

0000000080002dc0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dc0:	1101                	addi	sp,sp,-32
    80002dc2:	ec06                	sd	ra,24(sp)
    80002dc4:	e822                	sd	s0,16(sp)
    80002dc6:	e426                	sd	s1,8(sp)
    80002dc8:	1000                	addi	s0,sp,32
    80002dca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dcc:	00000097          	auipc	ra,0x0
    80002dd0:	ef2080e7          	jalr	-270(ra) # 80002cbe <argraw>
    80002dd4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dd6:	4501                	li	a0,0
    80002dd8:	60e2                	ld	ra,24(sp)
    80002dda:	6442                	ld	s0,16(sp)
    80002ddc:	64a2                	ld	s1,8(sp)
    80002dde:	6105                	addi	sp,sp,32
    80002de0:	8082                	ret

0000000080002de2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002de2:	1101                	addi	sp,sp,-32
    80002de4:	ec06                	sd	ra,24(sp)
    80002de6:	e822                	sd	s0,16(sp)
    80002de8:	e426                	sd	s1,8(sp)
    80002dea:	1000                	addi	s0,sp,32
    80002dec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dee:	00000097          	auipc	ra,0x0
    80002df2:	ed0080e7          	jalr	-304(ra) # 80002cbe <argraw>
    80002df6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002df8:	4501                	li	a0,0
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	e04a                	sd	s2,0(sp)
    80002e0e:	1000                	addi	s0,sp,32
    80002e10:	84ae                	mv	s1,a1
    80002e12:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e14:	00000097          	auipc	ra,0x0
    80002e18:	eaa080e7          	jalr	-342(ra) # 80002cbe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e1c:	864a                	mv	a2,s2
    80002e1e:	85a6                	mv	a1,s1
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	f58080e7          	jalr	-168(ra) # 80002d78 <fetchstr>
}
    80002e28:	60e2                	ld	ra,24(sp)
    80002e2a:	6442                	ld	s0,16(sp)
    80002e2c:	64a2                	ld	s1,8(sp)
    80002e2e:	6902                	ld	s2,0(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	e04a                	sd	s2,0(sp)
    80002e3e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	ec0080e7          	jalr	-320(ra) # 80001d00 <myproc>
    80002e48:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e4a:	06053903          	ld	s2,96(a0)
    80002e4e:	0a893783          	ld	a5,168(s2)
    80002e52:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e56:	37fd                	addiw	a5,a5,-1
    80002e58:	4751                	li	a4,20
    80002e5a:	00f76f63          	bltu	a4,a5,80002e78 <syscall+0x44>
    80002e5e:	00369713          	slli	a4,a3,0x3
    80002e62:	00005797          	auipc	a5,0x5
    80002e66:	65678793          	addi	a5,a5,1622 # 800084b8 <syscalls>
    80002e6a:	97ba                	add	a5,a5,a4
    80002e6c:	639c                	ld	a5,0(a5)
    80002e6e:	c789                	beqz	a5,80002e78 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e70:	9782                	jalr	a5
    80002e72:	06a93823          	sd	a0,112(s2)
    80002e76:	a839                	j	80002e94 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e78:	16048613          	addi	a2,s1,352
    80002e7c:	40ac                	lw	a1,64(s1)
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	60250513          	addi	a0,a0,1538 # 80008480 <states.0+0x148>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	710080e7          	jalr	1808(ra) # 80000596 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e8e:	70bc                	ld	a5,96(s1)
    80002e90:	577d                	li	a4,-1
    80002e92:	fbb8                	sd	a4,112(a5)
  }
}
    80002e94:	60e2                	ld	ra,24(sp)
    80002e96:	6442                	ld	s0,16(sp)
    80002e98:	64a2                	ld	s1,8(sp)
    80002e9a:	6902                	ld	s2,0(sp)
    80002e9c:	6105                	addi	sp,sp,32
    80002e9e:	8082                	ret

0000000080002ea0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ea8:	fec40593          	addi	a1,s0,-20
    80002eac:	4501                	li	a0,0
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	f12080e7          	jalr	-238(ra) # 80002dc0 <argint>
    return -1;
    80002eb6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002eb8:	00054963          	bltz	a0,80002eca <sys_exit+0x2a>
  exit(n);
    80002ebc:	fec42503          	lw	a0,-20(s0)
    80002ec0:	fffff097          	auipc	ra,0xfffff
    80002ec4:	512080e7          	jalr	1298(ra) # 800023d2 <exit>
  return 0;  // not reached
    80002ec8:	4781                	li	a5,0
}
    80002eca:	853e                	mv	a0,a5
    80002ecc:	60e2                	ld	ra,24(sp)
    80002ece:	6442                	ld	s0,16(sp)
    80002ed0:	6105                	addi	sp,sp,32
    80002ed2:	8082                	ret

0000000080002ed4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ed4:	1141                	addi	sp,sp,-16
    80002ed6:	e406                	sd	ra,8(sp)
    80002ed8:	e022                	sd	s0,0(sp)
    80002eda:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	e24080e7          	jalr	-476(ra) # 80001d00 <myproc>
}
    80002ee4:	4128                	lw	a0,64(a0)
    80002ee6:	60a2                	ld	ra,8(sp)
    80002ee8:	6402                	ld	s0,0(sp)
    80002eea:	0141                	addi	sp,sp,16
    80002eec:	8082                	ret

0000000080002eee <sys_fork>:

uint64
sys_fork(void)
{
    80002eee:	1141                	addi	sp,sp,-16
    80002ef0:	e406                	sd	ra,8(sp)
    80002ef2:	e022                	sd	s0,0(sp)
    80002ef4:	0800                	addi	s0,sp,16
  return fork();
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	1ce080e7          	jalr	462(ra) # 800020c4 <fork>
}
    80002efe:	60a2                	ld	ra,8(sp)
    80002f00:	6402                	ld	s0,0(sp)
    80002f02:	0141                	addi	sp,sp,16
    80002f04:	8082                	ret

0000000080002f06 <sys_wait>:

uint64
sys_wait(void)
{
    80002f06:	1101                	addi	sp,sp,-32
    80002f08:	ec06                	sd	ra,24(sp)
    80002f0a:	e822                	sd	s0,16(sp)
    80002f0c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f0e:	fe840593          	addi	a1,s0,-24
    80002f12:	4501                	li	a0,0
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	ece080e7          	jalr	-306(ra) # 80002de2 <argaddr>
    80002f1c:	87aa                	mv	a5,a0
    return -1;
    80002f1e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f20:	0007c863          	bltz	a5,80002f30 <sys_wait+0x2a>
  return wait(p);
    80002f24:	fe843503          	ld	a0,-24(s0)
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	66e080e7          	jalr	1646(ra) # 80002596 <wait>
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret

0000000080002f38 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f42:	fdc40593          	addi	a1,s0,-36
    80002f46:	4501                	li	a0,0
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	e78080e7          	jalr	-392(ra) # 80002dc0 <argint>
    80002f50:	87aa                	mv	a5,a0
    return -1;
    80002f52:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f54:	0207c063          	bltz	a5,80002f74 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	da8080e7          	jalr	-600(ra) # 80001d00 <myproc>
    80002f60:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f62:	fdc42503          	lw	a0,-36(s0)
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	0e6080e7          	jalr	230(ra) # 8000204c <growproc>
    80002f6e:	00054863          	bltz	a0,80002f7e <sys_sbrk+0x46>
    return -1;
  // printf("addr:%d\n", addr);
  return addr;
    80002f72:	8526                	mv	a0,s1
}
    80002f74:	70a2                	ld	ra,40(sp)
    80002f76:	7402                	ld	s0,32(sp)
    80002f78:	64e2                	ld	s1,24(sp)
    80002f7a:	6145                	addi	sp,sp,48
    80002f7c:	8082                	ret
    return -1;
    80002f7e:	557d                	li	a0,-1
    80002f80:	bfd5                	j	80002f74 <sys_sbrk+0x3c>

0000000080002f82 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f82:	7139                	addi	sp,sp,-64
    80002f84:	fc06                	sd	ra,56(sp)
    80002f86:	f822                	sd	s0,48(sp)
    80002f88:	f426                	sd	s1,40(sp)
    80002f8a:	f04a                	sd	s2,32(sp)
    80002f8c:	ec4e                	sd	s3,24(sp)
    80002f8e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f90:	fcc40593          	addi	a1,s0,-52
    80002f94:	4501                	li	a0,0
    80002f96:	00000097          	auipc	ra,0x0
    80002f9a:	e2a080e7          	jalr	-470(ra) # 80002dc0 <argint>
    return -1;
    80002f9e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fa0:	06054563          	bltz	a0,8000300a <sys_sleep+0x88>
  acquire(&tickslock);
    80002fa4:	00015517          	auipc	a0,0x15
    80002fa8:	40450513          	addi	a0,a0,1028 # 800183a8 <tickslock>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	d0e080e7          	jalr	-754(ra) # 80000cba <acquire>
  ticks0 = ticks;
    80002fb4:	00006917          	auipc	s2,0x6
    80002fb8:	06c92903          	lw	s2,108(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fbc:	fcc42783          	lw	a5,-52(s0)
    80002fc0:	cf85                	beqz	a5,80002ff8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fc2:	00015997          	auipc	s3,0x15
    80002fc6:	3e698993          	addi	s3,s3,998 # 800183a8 <tickslock>
    80002fca:	00006497          	auipc	s1,0x6
    80002fce:	05648493          	addi	s1,s1,86 # 80009020 <ticks>
    if(myproc()->killed){
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	d2e080e7          	jalr	-722(ra) # 80001d00 <myproc>
    80002fda:	5d1c                	lw	a5,56(a0)
    80002fdc:	ef9d                	bnez	a5,8000301a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fde:	85ce                	mv	a1,s3
    80002fe0:	8526                	mv	a0,s1
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	536080e7          	jalr	1334(ra) # 80002518 <sleep>
  while(ticks - ticks0 < n){
    80002fea:	409c                	lw	a5,0(s1)
    80002fec:	412787bb          	subw	a5,a5,s2
    80002ff0:	fcc42703          	lw	a4,-52(s0)
    80002ff4:	fce7efe3          	bltu	a5,a4,80002fd2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ff8:	00015517          	auipc	a0,0x15
    80002ffc:	3b050513          	addi	a0,a0,944 # 800183a8 <tickslock>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	d8a080e7          	jalr	-630(ra) # 80000d8a <release>
  return 0;
    80003008:	4781                	li	a5,0
}
    8000300a:	853e                	mv	a0,a5
    8000300c:	70e2                	ld	ra,56(sp)
    8000300e:	7442                	ld	s0,48(sp)
    80003010:	74a2                	ld	s1,40(sp)
    80003012:	7902                	ld	s2,32(sp)
    80003014:	69e2                	ld	s3,24(sp)
    80003016:	6121                	addi	sp,sp,64
    80003018:	8082                	ret
      release(&tickslock);
    8000301a:	00015517          	auipc	a0,0x15
    8000301e:	38e50513          	addi	a0,a0,910 # 800183a8 <tickslock>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	d68080e7          	jalr	-664(ra) # 80000d8a <release>
      return -1;
    8000302a:	57fd                	li	a5,-1
    8000302c:	bff9                	j	8000300a <sys_sleep+0x88>

000000008000302e <sys_kill>:

uint64
sys_kill(void)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003036:	fec40593          	addi	a1,s0,-20
    8000303a:	4501                	li	a0,0
    8000303c:	00000097          	auipc	ra,0x0
    80003040:	d84080e7          	jalr	-636(ra) # 80002dc0 <argint>
    80003044:	87aa                	mv	a5,a0
    return -1;
    80003046:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003048:	0007c863          	bltz	a5,80003058 <sys_kill+0x2a>
  return kill(pid);
    8000304c:	fec42503          	lw	a0,-20(s0)
    80003050:	fffff097          	auipc	ra,0xfffff
    80003054:	6b2080e7          	jalr	1714(ra) # 80002702 <kill>
}
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	6105                	addi	sp,sp,32
    8000305e:	8082                	ret

0000000080003060 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	e426                	sd	s1,8(sp)
    80003068:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000306a:	00015517          	auipc	a0,0x15
    8000306e:	33e50513          	addi	a0,a0,830 # 800183a8 <tickslock>
    80003072:	ffffe097          	auipc	ra,0xffffe
    80003076:	c48080e7          	jalr	-952(ra) # 80000cba <acquire>
  xticks = ticks;
    8000307a:	00006497          	auipc	s1,0x6
    8000307e:	fa64a483          	lw	s1,-90(s1) # 80009020 <ticks>
  release(&tickslock);
    80003082:	00015517          	auipc	a0,0x15
    80003086:	32650513          	addi	a0,a0,806 # 800183a8 <tickslock>
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	d00080e7          	jalr	-768(ra) # 80000d8a <release>
  return xticks;
}
    80003092:	02049513          	slli	a0,s1,0x20
    80003096:	9101                	srli	a0,a0,0x20
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	64a2                	ld	s1,8(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret

00000000800030a2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030a2:	7179                	addi	sp,sp,-48
    800030a4:	f406                	sd	ra,40(sp)
    800030a6:	f022                	sd	s0,32(sp)
    800030a8:	ec26                	sd	s1,24(sp)
    800030aa:	e84a                	sd	s2,16(sp)
    800030ac:	e44e                	sd	s3,8(sp)
    800030ae:	e052                	sd	s4,0(sp)
    800030b0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030b2:	00005597          	auipc	a1,0x5
    800030b6:	04e58593          	addi	a1,a1,78 # 80008100 <digits+0xc0>
    800030ba:	00015517          	auipc	a0,0x15
    800030be:	30e50513          	addi	a0,a0,782 # 800183c8 <bcache>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	d74080e7          	jalr	-652(ra) # 80000e36 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030ca:	0001d797          	auipc	a5,0x1d
    800030ce:	2fe78793          	addi	a5,a5,766 # 800203c8 <bcache+0x8000>
    800030d2:	0001d717          	auipc	a4,0x1d
    800030d6:	65670713          	addi	a4,a4,1622 # 80020728 <bcache+0x8360>
    800030da:	3ae7b823          	sd	a4,944(a5)
  bcache.head.next = &bcache.head;
    800030de:	3ae7bc23          	sd	a4,952(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e2:	00015497          	auipc	s1,0x15
    800030e6:	30648493          	addi	s1,s1,774 # 800183e8 <bcache+0x20>
    b->next = bcache.head.next;
    800030ea:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030ec:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030ee:	00005a17          	auipc	s4,0x5
    800030f2:	47aa0a13          	addi	s4,s4,1146 # 80008568 <syscalls+0xb0>
    b->next = bcache.head.next;
    800030f6:	3b893783          	ld	a5,952(s2)
    800030fa:	ecbc                	sd	a5,88(s1)
    b->prev = &bcache.head;
    800030fc:	0534b823          	sd	s3,80(s1)
    initsleeplock(&b->lock, "buffer");
    80003100:	85d2                	mv	a1,s4
    80003102:	01048513          	addi	a0,s1,16
    80003106:	00001097          	auipc	ra,0x1
    8000310a:	4c8080e7          	jalr	1224(ra) # 800045ce <initsleeplock>
    bcache.head.next->prev = b;
    8000310e:	3b893783          	ld	a5,952(s2)
    80003112:	eba4                	sd	s1,80(a5)
    bcache.head.next = b;
    80003114:	3a993c23          	sd	s1,952(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003118:	46048493          	addi	s1,s1,1120
    8000311c:	fd349de3          	bne	s1,s3,800030f6 <binit+0x54>
  }
}
    80003120:	70a2                	ld	ra,40(sp)
    80003122:	7402                	ld	s0,32(sp)
    80003124:	64e2                	ld	s1,24(sp)
    80003126:	6942                	ld	s2,16(sp)
    80003128:	69a2                	ld	s3,8(sp)
    8000312a:	6a02                	ld	s4,0(sp)
    8000312c:	6145                	addi	sp,sp,48
    8000312e:	8082                	ret

0000000080003130 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003130:	7179                	addi	sp,sp,-48
    80003132:	f406                	sd	ra,40(sp)
    80003134:	f022                	sd	s0,32(sp)
    80003136:	ec26                	sd	s1,24(sp)
    80003138:	e84a                	sd	s2,16(sp)
    8000313a:	e44e                	sd	s3,8(sp)
    8000313c:	1800                	addi	s0,sp,48
    8000313e:	892a                	mv	s2,a0
    80003140:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003142:	00015517          	auipc	a0,0x15
    80003146:	28650513          	addi	a0,a0,646 # 800183c8 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	b70080e7          	jalr	-1168(ra) # 80000cba <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003152:	0001d497          	auipc	s1,0x1d
    80003156:	62e4b483          	ld	s1,1582(s1) # 80020780 <bcache+0x83b8>
    8000315a:	0001d797          	auipc	a5,0x1d
    8000315e:	5ce78793          	addi	a5,a5,1486 # 80020728 <bcache+0x8360>
    80003162:	02f48f63          	beq	s1,a5,800031a0 <bread+0x70>
    80003166:	873e                	mv	a4,a5
    80003168:	a021                	j	80003170 <bread+0x40>
    8000316a:	6ca4                	ld	s1,88(s1)
    8000316c:	02e48a63          	beq	s1,a4,800031a0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003170:	449c                	lw	a5,8(s1)
    80003172:	ff279ce3          	bne	a5,s2,8000316a <bread+0x3a>
    80003176:	44dc                	lw	a5,12(s1)
    80003178:	ff3799e3          	bne	a5,s3,8000316a <bread+0x3a>
      b->refcnt++;
    8000317c:	44bc                	lw	a5,72(s1)
    8000317e:	2785                	addiw	a5,a5,1
    80003180:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    80003182:	00015517          	auipc	a0,0x15
    80003186:	24650513          	addi	a0,a0,582 # 800183c8 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	c00080e7          	jalr	-1024(ra) # 80000d8a <release>
      acquiresleep(&b->lock);
    80003192:	01048513          	addi	a0,s1,16
    80003196:	00001097          	auipc	ra,0x1
    8000319a:	472080e7          	jalr	1138(ra) # 80004608 <acquiresleep>
      return b;
    8000319e:	a8b9                	j	800031fc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031a0:	0001d497          	auipc	s1,0x1d
    800031a4:	5d84b483          	ld	s1,1496(s1) # 80020778 <bcache+0x83b0>
    800031a8:	0001d797          	auipc	a5,0x1d
    800031ac:	58078793          	addi	a5,a5,1408 # 80020728 <bcache+0x8360>
    800031b0:	00f48863          	beq	s1,a5,800031c0 <bread+0x90>
    800031b4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031b6:	44bc                	lw	a5,72(s1)
    800031b8:	cf81                	beqz	a5,800031d0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ba:	68a4                	ld	s1,80(s1)
    800031bc:	fee49de3          	bne	s1,a4,800031b6 <bread+0x86>
  panic("bget: no buffers");
    800031c0:	00005517          	auipc	a0,0x5
    800031c4:	3b050513          	addi	a0,a0,944 # 80008570 <syscalls+0xb8>
    800031c8:	ffffd097          	auipc	ra,0xffffd
    800031cc:	384080e7          	jalr	900(ra) # 8000054c <panic>
      b->dev = dev;
    800031d0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800031d4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800031d8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031dc:	4785                	li	a5,1
    800031de:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock);
    800031e0:	00015517          	auipc	a0,0x15
    800031e4:	1e850513          	addi	a0,a0,488 # 800183c8 <bcache>
    800031e8:	ffffe097          	auipc	ra,0xffffe
    800031ec:	ba2080e7          	jalr	-1118(ra) # 80000d8a <release>
      acquiresleep(&b->lock);
    800031f0:	01048513          	addi	a0,s1,16
    800031f4:	00001097          	auipc	ra,0x1
    800031f8:	414080e7          	jalr	1044(ra) # 80004608 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031fc:	409c                	lw	a5,0(s1)
    800031fe:	cb89                	beqz	a5,80003210 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003200:	8526                	mv	a0,s1
    80003202:	70a2                	ld	ra,40(sp)
    80003204:	7402                	ld	s0,32(sp)
    80003206:	64e2                	ld	s1,24(sp)
    80003208:	6942                	ld	s2,16(sp)
    8000320a:	69a2                	ld	s3,8(sp)
    8000320c:	6145                	addi	sp,sp,48
    8000320e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003210:	4581                	li	a1,0
    80003212:	8526                	mv	a0,s1
    80003214:	00003097          	auipc	ra,0x3
    80003218:	f6e080e7          	jalr	-146(ra) # 80006182 <virtio_disk_rw>
    b->valid = 1;
    8000321c:	4785                	li	a5,1
    8000321e:	c09c                	sw	a5,0(s1)
  return b;
    80003220:	b7c5                	j	80003200 <bread+0xd0>

0000000080003222 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000322e:	0541                	addi	a0,a0,16
    80003230:	00001097          	auipc	ra,0x1
    80003234:	472080e7          	jalr	1138(ra) # 800046a2 <holdingsleep>
    80003238:	cd01                	beqz	a0,80003250 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000323a:	4585                	li	a1,1
    8000323c:	8526                	mv	a0,s1
    8000323e:	00003097          	auipc	ra,0x3
    80003242:	f44080e7          	jalr	-188(ra) # 80006182 <virtio_disk_rw>
}
    80003246:	60e2                	ld	ra,24(sp)
    80003248:	6442                	ld	s0,16(sp)
    8000324a:	64a2                	ld	s1,8(sp)
    8000324c:	6105                	addi	sp,sp,32
    8000324e:	8082                	ret
    panic("bwrite");
    80003250:	00005517          	auipc	a0,0x5
    80003254:	33850513          	addi	a0,a0,824 # 80008588 <syscalls+0xd0>
    80003258:	ffffd097          	auipc	ra,0xffffd
    8000325c:	2f4080e7          	jalr	756(ra) # 8000054c <panic>

0000000080003260 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	e426                	sd	s1,8(sp)
    80003268:	e04a                	sd	s2,0(sp)
    8000326a:	1000                	addi	s0,sp,32
    8000326c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000326e:	01050913          	addi	s2,a0,16
    80003272:	854a                	mv	a0,s2
    80003274:	00001097          	auipc	ra,0x1
    80003278:	42e080e7          	jalr	1070(ra) # 800046a2 <holdingsleep>
    8000327c:	c92d                	beqz	a0,800032ee <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000327e:	854a                	mv	a0,s2
    80003280:	00001097          	auipc	ra,0x1
    80003284:	3de080e7          	jalr	990(ra) # 8000465e <releasesleep>

  acquire(&bcache.lock);
    80003288:	00015517          	auipc	a0,0x15
    8000328c:	14050513          	addi	a0,a0,320 # 800183c8 <bcache>
    80003290:	ffffe097          	auipc	ra,0xffffe
    80003294:	a2a080e7          	jalr	-1494(ra) # 80000cba <acquire>
  b->refcnt--;
    80003298:	44bc                	lw	a5,72(s1)
    8000329a:	37fd                	addiw	a5,a5,-1
    8000329c:	0007871b          	sext.w	a4,a5
    800032a0:	c4bc                	sw	a5,72(s1)
  if (b->refcnt == 0) {
    800032a2:	eb05                	bnez	a4,800032d2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032a4:	6cbc                	ld	a5,88(s1)
    800032a6:	68b8                	ld	a4,80(s1)
    800032a8:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    800032aa:	68bc                	ld	a5,80(s1)
    800032ac:	6cb8                	ld	a4,88(s1)
    800032ae:	efb8                	sd	a4,88(a5)
    b->next = bcache.head.next;
    800032b0:	0001d797          	auipc	a5,0x1d
    800032b4:	11878793          	addi	a5,a5,280 # 800203c8 <bcache+0x8000>
    800032b8:	3b87b703          	ld	a4,952(a5)
    800032bc:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.head;
    800032be:	0001d717          	auipc	a4,0x1d
    800032c2:	46a70713          	addi	a4,a4,1130 # 80020728 <bcache+0x8360>
    800032c6:	e8b8                	sd	a4,80(s1)
    bcache.head.next->prev = b;
    800032c8:	3b87b703          	ld	a4,952(a5)
    800032cc:	eb24                	sd	s1,80(a4)
    bcache.head.next = b;
    800032ce:	3a97bc23          	sd	s1,952(a5)
  }
  
  release(&bcache.lock);
    800032d2:	00015517          	auipc	a0,0x15
    800032d6:	0f650513          	addi	a0,a0,246 # 800183c8 <bcache>
    800032da:	ffffe097          	auipc	ra,0xffffe
    800032de:	ab0080e7          	jalr	-1360(ra) # 80000d8a <release>
}
    800032e2:	60e2                	ld	ra,24(sp)
    800032e4:	6442                	ld	s0,16(sp)
    800032e6:	64a2                	ld	s1,8(sp)
    800032e8:	6902                	ld	s2,0(sp)
    800032ea:	6105                	addi	sp,sp,32
    800032ec:	8082                	ret
    panic("brelse");
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	2a250513          	addi	a0,a0,674 # 80008590 <syscalls+0xd8>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	256080e7          	jalr	598(ra) # 8000054c <panic>

00000000800032fe <bpin>:

void
bpin(struct buf *b) {
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	1000                	addi	s0,sp,32
    80003308:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000330a:	00015517          	auipc	a0,0x15
    8000330e:	0be50513          	addi	a0,a0,190 # 800183c8 <bcache>
    80003312:	ffffe097          	auipc	ra,0xffffe
    80003316:	9a8080e7          	jalr	-1624(ra) # 80000cba <acquire>
  b->refcnt++;
    8000331a:	44bc                	lw	a5,72(s1)
    8000331c:	2785                	addiw	a5,a5,1
    8000331e:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    80003320:	00015517          	auipc	a0,0x15
    80003324:	0a850513          	addi	a0,a0,168 # 800183c8 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	a62080e7          	jalr	-1438(ra) # 80000d8a <release>
}
    80003330:	60e2                	ld	ra,24(sp)
    80003332:	6442                	ld	s0,16(sp)
    80003334:	64a2                	ld	s1,8(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <bunpin>:

void
bunpin(struct buf *b) {
    8000333a:	1101                	addi	sp,sp,-32
    8000333c:	ec06                	sd	ra,24(sp)
    8000333e:	e822                	sd	s0,16(sp)
    80003340:	e426                	sd	s1,8(sp)
    80003342:	1000                	addi	s0,sp,32
    80003344:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003346:	00015517          	auipc	a0,0x15
    8000334a:	08250513          	addi	a0,a0,130 # 800183c8 <bcache>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	96c080e7          	jalr	-1684(ra) # 80000cba <acquire>
  b->refcnt--;
    80003356:	44bc                	lw	a5,72(s1)
    80003358:	37fd                	addiw	a5,a5,-1
    8000335a:	c4bc                	sw	a5,72(s1)
  release(&bcache.lock);
    8000335c:	00015517          	auipc	a0,0x15
    80003360:	06c50513          	addi	a0,a0,108 # 800183c8 <bcache>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	a26080e7          	jalr	-1498(ra) # 80000d8a <release>
}
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	64a2                	ld	s1,8(sp)
    80003372:	6105                	addi	sp,sp,32
    80003374:	8082                	ret

0000000080003376 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003376:	1101                	addi	sp,sp,-32
    80003378:	ec06                	sd	ra,24(sp)
    8000337a:	e822                	sd	s0,16(sp)
    8000337c:	e426                	sd	s1,8(sp)
    8000337e:	e04a                	sd	s2,0(sp)
    80003380:	1000                	addi	s0,sp,32
    80003382:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003384:	00d5d59b          	srliw	a1,a1,0xd
    80003388:	0001e797          	auipc	a5,0x1e
    8000338c:	81c7a783          	lw	a5,-2020(a5) # 80020ba4 <sb+0x1c>
    80003390:	9dbd                	addw	a1,a1,a5
    80003392:	00000097          	auipc	ra,0x0
    80003396:	d9e080e7          	jalr	-610(ra) # 80003130 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000339a:	0074f713          	andi	a4,s1,7
    8000339e:	4785                	li	a5,1
    800033a0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033a4:	14ce                	slli	s1,s1,0x33
    800033a6:	90d9                	srli	s1,s1,0x36
    800033a8:	00950733          	add	a4,a0,s1
    800033ac:	06074703          	lbu	a4,96(a4)
    800033b0:	00e7f6b3          	and	a3,a5,a4
    800033b4:	c69d                	beqz	a3,800033e2 <bfree+0x6c>
    800033b6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033b8:	94aa                	add	s1,s1,a0
    800033ba:	fff7c793          	not	a5,a5
    800033be:	8f7d                	and	a4,a4,a5
    800033c0:	06e48023          	sb	a4,96(s1)
  log_write(bp);
    800033c4:	00001097          	auipc	ra,0x1
    800033c8:	11e080e7          	jalr	286(ra) # 800044e2 <log_write>
  brelse(bp);
    800033cc:	854a                	mv	a0,s2
    800033ce:	00000097          	auipc	ra,0x0
    800033d2:	e92080e7          	jalr	-366(ra) # 80003260 <brelse>
}
    800033d6:	60e2                	ld	ra,24(sp)
    800033d8:	6442                	ld	s0,16(sp)
    800033da:	64a2                	ld	s1,8(sp)
    800033dc:	6902                	ld	s2,0(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret
    panic("freeing free block");
    800033e2:	00005517          	auipc	a0,0x5
    800033e6:	1b650513          	addi	a0,a0,438 # 80008598 <syscalls+0xe0>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	162080e7          	jalr	354(ra) # 8000054c <panic>

00000000800033f2 <balloc>:
{
    800033f2:	711d                	addi	sp,sp,-96
    800033f4:	ec86                	sd	ra,88(sp)
    800033f6:	e8a2                	sd	s0,80(sp)
    800033f8:	e4a6                	sd	s1,72(sp)
    800033fa:	e0ca                	sd	s2,64(sp)
    800033fc:	fc4e                	sd	s3,56(sp)
    800033fe:	f852                	sd	s4,48(sp)
    80003400:	f456                	sd	s5,40(sp)
    80003402:	f05a                	sd	s6,32(sp)
    80003404:	ec5e                	sd	s7,24(sp)
    80003406:	e862                	sd	s8,16(sp)
    80003408:	e466                	sd	s9,8(sp)
    8000340a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000340c:	0001d797          	auipc	a5,0x1d
    80003410:	7807a783          	lw	a5,1920(a5) # 80020b8c <sb+0x4>
    80003414:	cbc1                	beqz	a5,800034a4 <balloc+0xb2>
    80003416:	8baa                	mv	s7,a0
    80003418:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000341a:	0001db17          	auipc	s6,0x1d
    8000341e:	76eb0b13          	addi	s6,s6,1902 # 80020b88 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003422:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003424:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003426:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003428:	6c89                	lui	s9,0x2
    8000342a:	a831                	j	80003446 <balloc+0x54>
    brelse(bp);
    8000342c:	854a                	mv	a0,s2
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	e32080e7          	jalr	-462(ra) # 80003260 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003436:	015c87bb          	addw	a5,s9,s5
    8000343a:	00078a9b          	sext.w	s5,a5
    8000343e:	004b2703          	lw	a4,4(s6)
    80003442:	06eaf163          	bgeu	s5,a4,800034a4 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    80003446:	41fad79b          	sraiw	a5,s5,0x1f
    8000344a:	0137d79b          	srliw	a5,a5,0x13
    8000344e:	015787bb          	addw	a5,a5,s5
    80003452:	40d7d79b          	sraiw	a5,a5,0xd
    80003456:	01cb2583          	lw	a1,28(s6)
    8000345a:	9dbd                	addw	a1,a1,a5
    8000345c:	855e                	mv	a0,s7
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	cd2080e7          	jalr	-814(ra) # 80003130 <bread>
    80003466:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003468:	004b2503          	lw	a0,4(s6)
    8000346c:	000a849b          	sext.w	s1,s5
    80003470:	8762                	mv	a4,s8
    80003472:	faa4fde3          	bgeu	s1,a0,8000342c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003476:	00777693          	andi	a3,a4,7
    8000347a:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000347e:	41f7579b          	sraiw	a5,a4,0x1f
    80003482:	01d7d79b          	srliw	a5,a5,0x1d
    80003486:	9fb9                	addw	a5,a5,a4
    80003488:	4037d79b          	sraiw	a5,a5,0x3
    8000348c:	00f90633          	add	a2,s2,a5
    80003490:	06064603          	lbu	a2,96(a2)
    80003494:	00c6f5b3          	and	a1,a3,a2
    80003498:	cd91                	beqz	a1,800034b4 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349a:	2705                	addiw	a4,a4,1
    8000349c:	2485                	addiw	s1,s1,1
    8000349e:	fd471ae3          	bne	a4,s4,80003472 <balloc+0x80>
    800034a2:	b769                	j	8000342c <balloc+0x3a>
  panic("balloc: out of blocks");
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	10c50513          	addi	a0,a0,268 # 800085b0 <syscalls+0xf8>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	0a0080e7          	jalr	160(ra) # 8000054c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034b4:	97ca                	add	a5,a5,s2
    800034b6:	8e55                	or	a2,a2,a3
    800034b8:	06c78023          	sb	a2,96(a5)
        log_write(bp);
    800034bc:	854a                	mv	a0,s2
    800034be:	00001097          	auipc	ra,0x1
    800034c2:	024080e7          	jalr	36(ra) # 800044e2 <log_write>
        brelse(bp);
    800034c6:	854a                	mv	a0,s2
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	d98080e7          	jalr	-616(ra) # 80003260 <brelse>
  bp = bread(dev, bno);
    800034d0:	85a6                	mv	a1,s1
    800034d2:	855e                	mv	a0,s7
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	c5c080e7          	jalr	-932(ra) # 80003130 <bread>
    800034dc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034de:	40000613          	li	a2,1024
    800034e2:	4581                	li	a1,0
    800034e4:	06050513          	addi	a0,a0,96
    800034e8:	ffffe097          	auipc	ra,0xffffe
    800034ec:	bb2080e7          	jalr	-1102(ra) # 8000109a <memset>
  log_write(bp);
    800034f0:	854a                	mv	a0,s2
    800034f2:	00001097          	auipc	ra,0x1
    800034f6:	ff0080e7          	jalr	-16(ra) # 800044e2 <log_write>
  brelse(bp);
    800034fa:	854a                	mv	a0,s2
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	d64080e7          	jalr	-668(ra) # 80003260 <brelse>
}
    80003504:	8526                	mv	a0,s1
    80003506:	60e6                	ld	ra,88(sp)
    80003508:	6446                	ld	s0,80(sp)
    8000350a:	64a6                	ld	s1,72(sp)
    8000350c:	6906                	ld	s2,64(sp)
    8000350e:	79e2                	ld	s3,56(sp)
    80003510:	7a42                	ld	s4,48(sp)
    80003512:	7aa2                	ld	s5,40(sp)
    80003514:	7b02                	ld	s6,32(sp)
    80003516:	6be2                	ld	s7,24(sp)
    80003518:	6c42                	ld	s8,16(sp)
    8000351a:	6ca2                	ld	s9,8(sp)
    8000351c:	6125                	addi	sp,sp,96
    8000351e:	8082                	ret

0000000080003520 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	e052                	sd	s4,0(sp)
    8000352e:	1800                	addi	s0,sp,48
    80003530:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003532:	47ad                	li	a5,11
    80003534:	04b7fe63          	bgeu	a5,a1,80003590 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003538:	ff45849b          	addiw	s1,a1,-12
    8000353c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003540:	0ff00793          	li	a5,255
    80003544:	0ae7e463          	bltu	a5,a4,800035ec <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003548:	08852583          	lw	a1,136(a0)
    8000354c:	c5b5                	beqz	a1,800035b8 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000354e:	00092503          	lw	a0,0(s2)
    80003552:	00000097          	auipc	ra,0x0
    80003556:	bde080e7          	jalr	-1058(ra) # 80003130 <bread>
    8000355a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000355c:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003560:	02049713          	slli	a4,s1,0x20
    80003564:	01e75593          	srli	a1,a4,0x1e
    80003568:	00b784b3          	add	s1,a5,a1
    8000356c:	0004a983          	lw	s3,0(s1)
    80003570:	04098e63          	beqz	s3,800035cc <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003574:	8552                	mv	a0,s4
    80003576:	00000097          	auipc	ra,0x0
    8000357a:	cea080e7          	jalr	-790(ra) # 80003260 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000357e:	854e                	mv	a0,s3
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6a02                	ld	s4,0(sp)
    8000358c:	6145                	addi	sp,sp,48
    8000358e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003590:	02059793          	slli	a5,a1,0x20
    80003594:	01e7d593          	srli	a1,a5,0x1e
    80003598:	00b504b3          	add	s1,a0,a1
    8000359c:	0584a983          	lw	s3,88(s1)
    800035a0:	fc099fe3          	bnez	s3,8000357e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035a4:	4108                	lw	a0,0(a0)
    800035a6:	00000097          	auipc	ra,0x0
    800035aa:	e4c080e7          	jalr	-436(ra) # 800033f2 <balloc>
    800035ae:	0005099b          	sext.w	s3,a0
    800035b2:	0534ac23          	sw	s3,88(s1)
    800035b6:	b7e1                	j	8000357e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800035b8:	4108                	lw	a0,0(a0)
    800035ba:	00000097          	auipc	ra,0x0
    800035be:	e38080e7          	jalr	-456(ra) # 800033f2 <balloc>
    800035c2:	0005059b          	sext.w	a1,a0
    800035c6:	08b92423          	sw	a1,136(s2)
    800035ca:	b751                	j	8000354e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800035cc:	00092503          	lw	a0,0(s2)
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	e22080e7          	jalr	-478(ra) # 800033f2 <balloc>
    800035d8:	0005099b          	sext.w	s3,a0
    800035dc:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035e0:	8552                	mv	a0,s4
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	f00080e7          	jalr	-256(ra) # 800044e2 <log_write>
    800035ea:	b769                	j	80003574 <bmap+0x54>
  panic("bmap: out of range");
    800035ec:	00005517          	auipc	a0,0x5
    800035f0:	fdc50513          	addi	a0,a0,-36 # 800085c8 <syscalls+0x110>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	f58080e7          	jalr	-168(ra) # 8000054c <panic>

00000000800035fc <iget>:
{
    800035fc:	7179                	addi	sp,sp,-48
    800035fe:	f406                	sd	ra,40(sp)
    80003600:	f022                	sd	s0,32(sp)
    80003602:	ec26                	sd	s1,24(sp)
    80003604:	e84a                	sd	s2,16(sp)
    80003606:	e44e                	sd	s3,8(sp)
    80003608:	e052                	sd	s4,0(sp)
    8000360a:	1800                	addi	s0,sp,48
    8000360c:	89aa                	mv	s3,a0
    8000360e:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003610:	0001d517          	auipc	a0,0x1d
    80003614:	59850513          	addi	a0,a0,1432 # 80020ba8 <icache>
    80003618:	ffffd097          	auipc	ra,0xffffd
    8000361c:	6a2080e7          	jalr	1698(ra) # 80000cba <acquire>
  empty = 0;
    80003620:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003622:	0001d497          	auipc	s1,0x1d
    80003626:	5a648493          	addi	s1,s1,1446 # 80020bc8 <icache+0x20>
    8000362a:	0001f697          	auipc	a3,0x1f
    8000362e:	1be68693          	addi	a3,a3,446 # 800227e8 <log>
    80003632:	a039                	j	80003640 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003634:	02090b63          	beqz	s2,8000366a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003638:	09048493          	addi	s1,s1,144
    8000363c:	02d48a63          	beq	s1,a3,80003670 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003640:	449c                	lw	a5,8(s1)
    80003642:	fef059e3          	blez	a5,80003634 <iget+0x38>
    80003646:	4098                	lw	a4,0(s1)
    80003648:	ff3716e3          	bne	a4,s3,80003634 <iget+0x38>
    8000364c:	40d8                	lw	a4,4(s1)
    8000364e:	ff4713e3          	bne	a4,s4,80003634 <iget+0x38>
      ip->ref++;
    80003652:	2785                	addiw	a5,a5,1
    80003654:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003656:	0001d517          	auipc	a0,0x1d
    8000365a:	55250513          	addi	a0,a0,1362 # 80020ba8 <icache>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	72c080e7          	jalr	1836(ra) # 80000d8a <release>
      return ip;
    80003666:	8926                	mv	s2,s1
    80003668:	a03d                	j	80003696 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000366a:	f7f9                	bnez	a5,80003638 <iget+0x3c>
    8000366c:	8926                	mv	s2,s1
    8000366e:	b7e9                	j	80003638 <iget+0x3c>
  if(empty == 0)
    80003670:	02090c63          	beqz	s2,800036a8 <iget+0xac>
  ip->dev = dev;
    80003674:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003678:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000367c:	4785                	li	a5,1
    8000367e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003682:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    80003686:	0001d517          	auipc	a0,0x1d
    8000368a:	52250513          	addi	a0,a0,1314 # 80020ba8 <icache>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	6fc080e7          	jalr	1788(ra) # 80000d8a <release>
}
    80003696:	854a                	mv	a0,s2
    80003698:	70a2                	ld	ra,40(sp)
    8000369a:	7402                	ld	s0,32(sp)
    8000369c:	64e2                	ld	s1,24(sp)
    8000369e:	6942                	ld	s2,16(sp)
    800036a0:	69a2                	ld	s3,8(sp)
    800036a2:	6a02                	ld	s4,0(sp)
    800036a4:	6145                	addi	sp,sp,48
    800036a6:	8082                	ret
    panic("iget: no inodes");
    800036a8:	00005517          	auipc	a0,0x5
    800036ac:	f3850513          	addi	a0,a0,-200 # 800085e0 <syscalls+0x128>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	e9c080e7          	jalr	-356(ra) # 8000054c <panic>

00000000800036b8 <fsinit>:
fsinit(int dev) {
    800036b8:	7179                	addi	sp,sp,-48
    800036ba:	f406                	sd	ra,40(sp)
    800036bc:	f022                	sd	s0,32(sp)
    800036be:	ec26                	sd	s1,24(sp)
    800036c0:	e84a                	sd	s2,16(sp)
    800036c2:	e44e                	sd	s3,8(sp)
    800036c4:	1800                	addi	s0,sp,48
    800036c6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036c8:	4585                	li	a1,1
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	a66080e7          	jalr	-1434(ra) # 80003130 <bread>
    800036d2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036d4:	0001d997          	auipc	s3,0x1d
    800036d8:	4b498993          	addi	s3,s3,1204 # 80020b88 <sb>
    800036dc:	02000613          	li	a2,32
    800036e0:	06050593          	addi	a1,a0,96
    800036e4:	854e                	mv	a0,s3
    800036e6:	ffffe097          	auipc	ra,0xffffe
    800036ea:	a10080e7          	jalr	-1520(ra) # 800010f6 <memmove>
  brelse(bp);
    800036ee:	8526                	mv	a0,s1
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	b70080e7          	jalr	-1168(ra) # 80003260 <brelse>
  if(sb.magic != FSMAGIC)
    800036f8:	0009a703          	lw	a4,0(s3)
    800036fc:	102037b7          	lui	a5,0x10203
    80003700:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003704:	02f71263          	bne	a4,a5,80003728 <fsinit+0x70>
  initlog(dev, &sb);
    80003708:	0001d597          	auipc	a1,0x1d
    8000370c:	48058593          	addi	a1,a1,1152 # 80020b88 <sb>
    80003710:	854a                	mv	a0,s2
    80003712:	00001097          	auipc	ra,0x1
    80003716:	b54080e7          	jalr	-1196(ra) # 80004266 <initlog>
}
    8000371a:	70a2                	ld	ra,40(sp)
    8000371c:	7402                	ld	s0,32(sp)
    8000371e:	64e2                	ld	s1,24(sp)
    80003720:	6942                	ld	s2,16(sp)
    80003722:	69a2                	ld	s3,8(sp)
    80003724:	6145                	addi	sp,sp,48
    80003726:	8082                	ret
    panic("invalid file system");
    80003728:	00005517          	auipc	a0,0x5
    8000372c:	ec850513          	addi	a0,a0,-312 # 800085f0 <syscalls+0x138>
    80003730:	ffffd097          	auipc	ra,0xffffd
    80003734:	e1c080e7          	jalr	-484(ra) # 8000054c <panic>

0000000080003738 <iinit>:
{
    80003738:	7179                	addi	sp,sp,-48
    8000373a:	f406                	sd	ra,40(sp)
    8000373c:	f022                	sd	s0,32(sp)
    8000373e:	ec26                	sd	s1,24(sp)
    80003740:	e84a                	sd	s2,16(sp)
    80003742:	e44e                	sd	s3,8(sp)
    80003744:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003746:	00005597          	auipc	a1,0x5
    8000374a:	ec258593          	addi	a1,a1,-318 # 80008608 <syscalls+0x150>
    8000374e:	0001d517          	auipc	a0,0x1d
    80003752:	45a50513          	addi	a0,a0,1114 # 80020ba8 <icache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	6e0080e7          	jalr	1760(ra) # 80000e36 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000375e:	0001d497          	auipc	s1,0x1d
    80003762:	47a48493          	addi	s1,s1,1146 # 80020bd8 <icache+0x30>
    80003766:	0001f997          	auipc	s3,0x1f
    8000376a:	09298993          	addi	s3,s3,146 # 800227f8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000376e:	00005917          	auipc	s2,0x5
    80003772:	ea290913          	addi	s2,s2,-350 # 80008610 <syscalls+0x158>
    80003776:	85ca                	mv	a1,s2
    80003778:	8526                	mv	a0,s1
    8000377a:	00001097          	auipc	ra,0x1
    8000377e:	e54080e7          	jalr	-428(ra) # 800045ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003782:	09048493          	addi	s1,s1,144
    80003786:	ff3498e3          	bne	s1,s3,80003776 <iinit+0x3e>
}
    8000378a:	70a2                	ld	ra,40(sp)
    8000378c:	7402                	ld	s0,32(sp)
    8000378e:	64e2                	ld	s1,24(sp)
    80003790:	6942                	ld	s2,16(sp)
    80003792:	69a2                	ld	s3,8(sp)
    80003794:	6145                	addi	sp,sp,48
    80003796:	8082                	ret

0000000080003798 <ialloc>:
{
    80003798:	715d                	addi	sp,sp,-80
    8000379a:	e486                	sd	ra,72(sp)
    8000379c:	e0a2                	sd	s0,64(sp)
    8000379e:	fc26                	sd	s1,56(sp)
    800037a0:	f84a                	sd	s2,48(sp)
    800037a2:	f44e                	sd	s3,40(sp)
    800037a4:	f052                	sd	s4,32(sp)
    800037a6:	ec56                	sd	s5,24(sp)
    800037a8:	e85a                	sd	s6,16(sp)
    800037aa:	e45e                	sd	s7,8(sp)
    800037ac:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ae:	0001d717          	auipc	a4,0x1d
    800037b2:	3e672703          	lw	a4,998(a4) # 80020b94 <sb+0xc>
    800037b6:	4785                	li	a5,1
    800037b8:	04e7fa63          	bgeu	a5,a4,8000380c <ialloc+0x74>
    800037bc:	8aaa                	mv	s5,a0
    800037be:	8bae                	mv	s7,a1
    800037c0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037c2:	0001da17          	auipc	s4,0x1d
    800037c6:	3c6a0a13          	addi	s4,s4,966 # 80020b88 <sb>
    800037ca:	00048b1b          	sext.w	s6,s1
    800037ce:	0044d593          	srli	a1,s1,0x4
    800037d2:	018a2783          	lw	a5,24(s4)
    800037d6:	9dbd                	addw	a1,a1,a5
    800037d8:	8556                	mv	a0,s5
    800037da:	00000097          	auipc	ra,0x0
    800037de:	956080e7          	jalr	-1706(ra) # 80003130 <bread>
    800037e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037e4:	06050993          	addi	s3,a0,96
    800037e8:	00f4f793          	andi	a5,s1,15
    800037ec:	079a                	slli	a5,a5,0x6
    800037ee:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037f0:	00099783          	lh	a5,0(s3)
    800037f4:	c785                	beqz	a5,8000381c <ialloc+0x84>
    brelse(bp);
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	a6a080e7          	jalr	-1430(ra) # 80003260 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037fe:	0485                	addi	s1,s1,1
    80003800:	00ca2703          	lw	a4,12(s4)
    80003804:	0004879b          	sext.w	a5,s1
    80003808:	fce7e1e3          	bltu	a5,a4,800037ca <ialloc+0x32>
  panic("ialloc: no inodes");
    8000380c:	00005517          	auipc	a0,0x5
    80003810:	e0c50513          	addi	a0,a0,-500 # 80008618 <syscalls+0x160>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	d38080e7          	jalr	-712(ra) # 8000054c <panic>
      memset(dip, 0, sizeof(*dip));
    8000381c:	04000613          	li	a2,64
    80003820:	4581                	li	a1,0
    80003822:	854e                	mv	a0,s3
    80003824:	ffffe097          	auipc	ra,0xffffe
    80003828:	876080e7          	jalr	-1930(ra) # 8000109a <memset>
      dip->type = type;
    8000382c:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003830:	854a                	mv	a0,s2
    80003832:	00001097          	auipc	ra,0x1
    80003836:	cb0080e7          	jalr	-848(ra) # 800044e2 <log_write>
      brelse(bp);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	a24080e7          	jalr	-1500(ra) # 80003260 <brelse>
      return iget(dev, inum);
    80003844:	85da                	mv	a1,s6
    80003846:	8556                	mv	a0,s5
    80003848:	00000097          	auipc	ra,0x0
    8000384c:	db4080e7          	jalr	-588(ra) # 800035fc <iget>
}
    80003850:	60a6                	ld	ra,72(sp)
    80003852:	6406                	ld	s0,64(sp)
    80003854:	74e2                	ld	s1,56(sp)
    80003856:	7942                	ld	s2,48(sp)
    80003858:	79a2                	ld	s3,40(sp)
    8000385a:	7a02                	ld	s4,32(sp)
    8000385c:	6ae2                	ld	s5,24(sp)
    8000385e:	6b42                	ld	s6,16(sp)
    80003860:	6ba2                	ld	s7,8(sp)
    80003862:	6161                	addi	sp,sp,80
    80003864:	8082                	ret

0000000080003866 <iupdate>:
{
    80003866:	1101                	addi	sp,sp,-32
    80003868:	ec06                	sd	ra,24(sp)
    8000386a:	e822                	sd	s0,16(sp)
    8000386c:	e426                	sd	s1,8(sp)
    8000386e:	e04a                	sd	s2,0(sp)
    80003870:	1000                	addi	s0,sp,32
    80003872:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003874:	415c                	lw	a5,4(a0)
    80003876:	0047d79b          	srliw	a5,a5,0x4
    8000387a:	0001d597          	auipc	a1,0x1d
    8000387e:	3265a583          	lw	a1,806(a1) # 80020ba0 <sb+0x18>
    80003882:	9dbd                	addw	a1,a1,a5
    80003884:	4108                	lw	a0,0(a0)
    80003886:	00000097          	auipc	ra,0x0
    8000388a:	8aa080e7          	jalr	-1878(ra) # 80003130 <bread>
    8000388e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003890:	06050793          	addi	a5,a0,96
    80003894:	40d8                	lw	a4,4(s1)
    80003896:	8b3d                	andi	a4,a4,15
    80003898:	071a                	slli	a4,a4,0x6
    8000389a:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000389c:	04c49703          	lh	a4,76(s1)
    800038a0:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800038a4:	04e49703          	lh	a4,78(s1)
    800038a8:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800038ac:	05049703          	lh	a4,80(s1)
    800038b0:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800038b4:	05249703          	lh	a4,82(s1)
    800038b8:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800038bc:	48f8                	lw	a4,84(s1)
    800038be:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038c0:	03400613          	li	a2,52
    800038c4:	05848593          	addi	a1,s1,88
    800038c8:	00c78513          	addi	a0,a5,12
    800038cc:	ffffe097          	auipc	ra,0xffffe
    800038d0:	82a080e7          	jalr	-2006(ra) # 800010f6 <memmove>
  log_write(bp);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	c0c080e7          	jalr	-1012(ra) # 800044e2 <log_write>
  brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	980080e7          	jalr	-1664(ra) # 80003260 <brelse>
}
    800038e8:	60e2                	ld	ra,24(sp)
    800038ea:	6442                	ld	s0,16(sp)
    800038ec:	64a2                	ld	s1,8(sp)
    800038ee:	6902                	ld	s2,0(sp)
    800038f0:	6105                	addi	sp,sp,32
    800038f2:	8082                	ret

00000000800038f4 <idup>:
{
    800038f4:	1101                	addi	sp,sp,-32
    800038f6:	ec06                	sd	ra,24(sp)
    800038f8:	e822                	sd	s0,16(sp)
    800038fa:	e426                	sd	s1,8(sp)
    800038fc:	1000                	addi	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003900:	0001d517          	auipc	a0,0x1d
    80003904:	2a850513          	addi	a0,a0,680 # 80020ba8 <icache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	3b2080e7          	jalr	946(ra) # 80000cba <acquire>
  ip->ref++;
    80003910:	449c                	lw	a5,8(s1)
    80003912:	2785                	addiw	a5,a5,1
    80003914:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003916:	0001d517          	auipc	a0,0x1d
    8000391a:	29250513          	addi	a0,a0,658 # 80020ba8 <icache>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	46c080e7          	jalr	1132(ra) # 80000d8a <release>
}
    80003926:	8526                	mv	a0,s1
    80003928:	60e2                	ld	ra,24(sp)
    8000392a:	6442                	ld	s0,16(sp)
    8000392c:	64a2                	ld	s1,8(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret

0000000080003932 <ilock>:
{
    80003932:	1101                	addi	sp,sp,-32
    80003934:	ec06                	sd	ra,24(sp)
    80003936:	e822                	sd	s0,16(sp)
    80003938:	e426                	sd	s1,8(sp)
    8000393a:	e04a                	sd	s2,0(sp)
    8000393c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000393e:	c115                	beqz	a0,80003962 <ilock+0x30>
    80003940:	84aa                	mv	s1,a0
    80003942:	451c                	lw	a5,8(a0)
    80003944:	00f05f63          	blez	a5,80003962 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003948:	0541                	addi	a0,a0,16
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	cbe080e7          	jalr	-834(ra) # 80004608 <acquiresleep>
  if(ip->valid == 0){
    80003952:	44bc                	lw	a5,72(s1)
    80003954:	cf99                	beqz	a5,80003972 <ilock+0x40>
}
    80003956:	60e2                	ld	ra,24(sp)
    80003958:	6442                	ld	s0,16(sp)
    8000395a:	64a2                	ld	s1,8(sp)
    8000395c:	6902                	ld	s2,0(sp)
    8000395e:	6105                	addi	sp,sp,32
    80003960:	8082                	ret
    panic("ilock");
    80003962:	00005517          	auipc	a0,0x5
    80003966:	cce50513          	addi	a0,a0,-818 # 80008630 <syscalls+0x178>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	be2080e7          	jalr	-1054(ra) # 8000054c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003972:	40dc                	lw	a5,4(s1)
    80003974:	0047d79b          	srliw	a5,a5,0x4
    80003978:	0001d597          	auipc	a1,0x1d
    8000397c:	2285a583          	lw	a1,552(a1) # 80020ba0 <sb+0x18>
    80003980:	9dbd                	addw	a1,a1,a5
    80003982:	4088                	lw	a0,0(s1)
    80003984:	fffff097          	auipc	ra,0xfffff
    80003988:	7ac080e7          	jalr	1964(ra) # 80003130 <bread>
    8000398c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000398e:	06050593          	addi	a1,a0,96
    80003992:	40dc                	lw	a5,4(s1)
    80003994:	8bbd                	andi	a5,a5,15
    80003996:	079a                	slli	a5,a5,0x6
    80003998:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000399a:	00059783          	lh	a5,0(a1)
    8000399e:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    800039a2:	00259783          	lh	a5,2(a1)
    800039a6:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    800039aa:	00459783          	lh	a5,4(a1)
    800039ae:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    800039b2:	00659783          	lh	a5,6(a1)
    800039b6:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    800039ba:	459c                	lw	a5,8(a1)
    800039bc:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039be:	03400613          	li	a2,52
    800039c2:	05b1                	addi	a1,a1,12
    800039c4:	05848513          	addi	a0,s1,88
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	72e080e7          	jalr	1838(ra) # 800010f6 <memmove>
    brelse(bp);
    800039d0:	854a                	mv	a0,s2
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	88e080e7          	jalr	-1906(ra) # 80003260 <brelse>
    ip->valid = 1;
    800039da:	4785                	li	a5,1
    800039dc:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    800039de:	04c49783          	lh	a5,76(s1)
    800039e2:	fbb5                	bnez	a5,80003956 <ilock+0x24>
      panic("ilock: no type");
    800039e4:	00005517          	auipc	a0,0x5
    800039e8:	c5450513          	addi	a0,a0,-940 # 80008638 <syscalls+0x180>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	b60080e7          	jalr	-1184(ra) # 8000054c <panic>

00000000800039f4 <iunlock>:
{
    800039f4:	1101                	addi	sp,sp,-32
    800039f6:	ec06                	sd	ra,24(sp)
    800039f8:	e822                	sd	s0,16(sp)
    800039fa:	e426                	sd	s1,8(sp)
    800039fc:	e04a                	sd	s2,0(sp)
    800039fe:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a00:	c905                	beqz	a0,80003a30 <iunlock+0x3c>
    80003a02:	84aa                	mv	s1,a0
    80003a04:	01050913          	addi	s2,a0,16
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00001097          	auipc	ra,0x1
    80003a0e:	c98080e7          	jalr	-872(ra) # 800046a2 <holdingsleep>
    80003a12:	cd19                	beqz	a0,80003a30 <iunlock+0x3c>
    80003a14:	449c                	lw	a5,8(s1)
    80003a16:	00f05d63          	blez	a5,80003a30 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a1a:	854a                	mv	a0,s2
    80003a1c:	00001097          	auipc	ra,0x1
    80003a20:	c42080e7          	jalr	-958(ra) # 8000465e <releasesleep>
}
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6902                	ld	s2,0(sp)
    80003a2c:	6105                	addi	sp,sp,32
    80003a2e:	8082                	ret
    panic("iunlock");
    80003a30:	00005517          	auipc	a0,0x5
    80003a34:	c1850513          	addi	a0,a0,-1000 # 80008648 <syscalls+0x190>
    80003a38:	ffffd097          	auipc	ra,0xffffd
    80003a3c:	b14080e7          	jalr	-1260(ra) # 8000054c <panic>

0000000080003a40 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a40:	7179                	addi	sp,sp,-48
    80003a42:	f406                	sd	ra,40(sp)
    80003a44:	f022                	sd	s0,32(sp)
    80003a46:	ec26                	sd	s1,24(sp)
    80003a48:	e84a                	sd	s2,16(sp)
    80003a4a:	e44e                	sd	s3,8(sp)
    80003a4c:	e052                	sd	s4,0(sp)
    80003a4e:	1800                	addi	s0,sp,48
    80003a50:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a52:	05850493          	addi	s1,a0,88
    80003a56:	08850913          	addi	s2,a0,136
    80003a5a:	a021                	j	80003a62 <itrunc+0x22>
    80003a5c:	0491                	addi	s1,s1,4
    80003a5e:	01248d63          	beq	s1,s2,80003a78 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a62:	408c                	lw	a1,0(s1)
    80003a64:	dde5                	beqz	a1,80003a5c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	90c080e7          	jalr	-1780(ra) # 80003376 <bfree>
      ip->addrs[i] = 0;
    80003a72:	0004a023          	sw	zero,0(s1)
    80003a76:	b7dd                	j	80003a5c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a78:	0889a583          	lw	a1,136(s3)
    80003a7c:	e185                	bnez	a1,80003a9c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a7e:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003a82:	854e                	mv	a0,s3
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	de2080e7          	jalr	-542(ra) # 80003866 <iupdate>
}
    80003a8c:	70a2                	ld	ra,40(sp)
    80003a8e:	7402                	ld	s0,32(sp)
    80003a90:	64e2                	ld	s1,24(sp)
    80003a92:	6942                	ld	s2,16(sp)
    80003a94:	69a2                	ld	s3,8(sp)
    80003a96:	6a02                	ld	s4,0(sp)
    80003a98:	6145                	addi	sp,sp,48
    80003a9a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a9c:	0009a503          	lw	a0,0(s3)
    80003aa0:	fffff097          	auipc	ra,0xfffff
    80003aa4:	690080e7          	jalr	1680(ra) # 80003130 <bread>
    80003aa8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003aaa:	06050493          	addi	s1,a0,96
    80003aae:	46050913          	addi	s2,a0,1120
    80003ab2:	a021                	j	80003aba <itrunc+0x7a>
    80003ab4:	0491                	addi	s1,s1,4
    80003ab6:	01248b63          	beq	s1,s2,80003acc <itrunc+0x8c>
      if(a[j])
    80003aba:	408c                	lw	a1,0(s1)
    80003abc:	dde5                	beqz	a1,80003ab4 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003abe:	0009a503          	lw	a0,0(s3)
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	8b4080e7          	jalr	-1868(ra) # 80003376 <bfree>
    80003aca:	b7ed                	j	80003ab4 <itrunc+0x74>
    brelse(bp);
    80003acc:	8552                	mv	a0,s4
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	792080e7          	jalr	1938(ra) # 80003260 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ad6:	0889a583          	lw	a1,136(s3)
    80003ada:	0009a503          	lw	a0,0(s3)
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	898080e7          	jalr	-1896(ra) # 80003376 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ae6:	0809a423          	sw	zero,136(s3)
    80003aea:	bf51                	j	80003a7e <itrunc+0x3e>

0000000080003aec <iput>:
{
    80003aec:	1101                	addi	sp,sp,-32
    80003aee:	ec06                	sd	ra,24(sp)
    80003af0:	e822                	sd	s0,16(sp)
    80003af2:	e426                	sd	s1,8(sp)
    80003af4:	e04a                	sd	s2,0(sp)
    80003af6:	1000                	addi	s0,sp,32
    80003af8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003afa:	0001d517          	auipc	a0,0x1d
    80003afe:	0ae50513          	addi	a0,a0,174 # 80020ba8 <icache>
    80003b02:	ffffd097          	auipc	ra,0xffffd
    80003b06:	1b8080e7          	jalr	440(ra) # 80000cba <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b0a:	4498                	lw	a4,8(s1)
    80003b0c:	4785                	li	a5,1
    80003b0e:	02f70363          	beq	a4,a5,80003b34 <iput+0x48>
  ip->ref--;
    80003b12:	449c                	lw	a5,8(s1)
    80003b14:	37fd                	addiw	a5,a5,-1
    80003b16:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b18:	0001d517          	auipc	a0,0x1d
    80003b1c:	09050513          	addi	a0,a0,144 # 80020ba8 <icache>
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	26a080e7          	jalr	618(ra) # 80000d8a <release>
}
    80003b28:	60e2                	ld	ra,24(sp)
    80003b2a:	6442                	ld	s0,16(sp)
    80003b2c:	64a2                	ld	s1,8(sp)
    80003b2e:	6902                	ld	s2,0(sp)
    80003b30:	6105                	addi	sp,sp,32
    80003b32:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b34:	44bc                	lw	a5,72(s1)
    80003b36:	dff1                	beqz	a5,80003b12 <iput+0x26>
    80003b38:	05249783          	lh	a5,82(s1)
    80003b3c:	fbf9                	bnez	a5,80003b12 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b3e:	01048913          	addi	s2,s1,16
    80003b42:	854a                	mv	a0,s2
    80003b44:	00001097          	auipc	ra,0x1
    80003b48:	ac4080e7          	jalr	-1340(ra) # 80004608 <acquiresleep>
    release(&icache.lock);
    80003b4c:	0001d517          	auipc	a0,0x1d
    80003b50:	05c50513          	addi	a0,a0,92 # 80020ba8 <icache>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	236080e7          	jalr	566(ra) # 80000d8a <release>
    itrunc(ip);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	ee2080e7          	jalr	-286(ra) # 80003a40 <itrunc>
    ip->type = 0;
    80003b66:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003b6a:	8526                	mv	a0,s1
    80003b6c:	00000097          	auipc	ra,0x0
    80003b70:	cfa080e7          	jalr	-774(ra) # 80003866 <iupdate>
    ip->valid = 0;
    80003b74:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003b78:	854a                	mv	a0,s2
    80003b7a:	00001097          	auipc	ra,0x1
    80003b7e:	ae4080e7          	jalr	-1308(ra) # 8000465e <releasesleep>
    acquire(&icache.lock);
    80003b82:	0001d517          	auipc	a0,0x1d
    80003b86:	02650513          	addi	a0,a0,38 # 80020ba8 <icache>
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	130080e7          	jalr	304(ra) # 80000cba <acquire>
    80003b92:	b741                	j	80003b12 <iput+0x26>

0000000080003b94 <iunlockput>:
{
    80003b94:	1101                	addi	sp,sp,-32
    80003b96:	ec06                	sd	ra,24(sp)
    80003b98:	e822                	sd	s0,16(sp)
    80003b9a:	e426                	sd	s1,8(sp)
    80003b9c:	1000                	addi	s0,sp,32
    80003b9e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003ba0:	00000097          	auipc	ra,0x0
    80003ba4:	e54080e7          	jalr	-428(ra) # 800039f4 <iunlock>
  iput(ip);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	f42080e7          	jalr	-190(ra) # 80003aec <iput>
}
    80003bb2:	60e2                	ld	ra,24(sp)
    80003bb4:	6442                	ld	s0,16(sp)
    80003bb6:	64a2                	ld	s1,8(sp)
    80003bb8:	6105                	addi	sp,sp,32
    80003bba:	8082                	ret

0000000080003bbc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bbc:	1141                	addi	sp,sp,-16
    80003bbe:	e422                	sd	s0,8(sp)
    80003bc0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bc2:	411c                	lw	a5,0(a0)
    80003bc4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bc6:	415c                	lw	a5,4(a0)
    80003bc8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bca:	04c51783          	lh	a5,76(a0)
    80003bce:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bd2:	05251783          	lh	a5,82(a0)
    80003bd6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bda:	05456783          	lwu	a5,84(a0)
    80003bde:	e99c                	sd	a5,16(a1)
}
    80003be0:	6422                	ld	s0,8(sp)
    80003be2:	0141                	addi	sp,sp,16
    80003be4:	8082                	ret

0000000080003be6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003be6:	497c                	lw	a5,84(a0)
    80003be8:	0ed7e963          	bltu	a5,a3,80003cda <readi+0xf4>
{
    80003bec:	7159                	addi	sp,sp,-112
    80003bee:	f486                	sd	ra,104(sp)
    80003bf0:	f0a2                	sd	s0,96(sp)
    80003bf2:	eca6                	sd	s1,88(sp)
    80003bf4:	e8ca                	sd	s2,80(sp)
    80003bf6:	e4ce                	sd	s3,72(sp)
    80003bf8:	e0d2                	sd	s4,64(sp)
    80003bfa:	fc56                	sd	s5,56(sp)
    80003bfc:	f85a                	sd	s6,48(sp)
    80003bfe:	f45e                	sd	s7,40(sp)
    80003c00:	f062                	sd	s8,32(sp)
    80003c02:	ec66                	sd	s9,24(sp)
    80003c04:	e86a                	sd	s10,16(sp)
    80003c06:	e46e                	sd	s11,8(sp)
    80003c08:	1880                	addi	s0,sp,112
    80003c0a:	8baa                	mv	s7,a0
    80003c0c:	8c2e                	mv	s8,a1
    80003c0e:	8ab2                	mv	s5,a2
    80003c10:	84b6                	mv	s1,a3
    80003c12:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c14:	9f35                	addw	a4,a4,a3
    return 0;
    80003c16:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c18:	0ad76063          	bltu	a4,a3,80003cb8 <readi+0xd2>
  if(off + n > ip->size)
    80003c1c:	00e7f463          	bgeu	a5,a4,80003c24 <readi+0x3e>
    n = ip->size - off;
    80003c20:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c24:	0a0b0963          	beqz	s6,80003cd6 <readi+0xf0>
    80003c28:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c2e:	5cfd                	li	s9,-1
    80003c30:	a82d                	j	80003c6a <readi+0x84>
    80003c32:	020a1d93          	slli	s11,s4,0x20
    80003c36:	020ddd93          	srli	s11,s11,0x20
    80003c3a:	06090613          	addi	a2,s2,96
    80003c3e:	86ee                	mv	a3,s11
    80003c40:	963a                	add	a2,a2,a4
    80003c42:	85d6                	mv	a1,s5
    80003c44:	8562                	mv	a0,s8
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	b2c080e7          	jalr	-1236(ra) # 80002772 <either_copyout>
    80003c4e:	05950d63          	beq	a0,s9,80003ca8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c52:	854a                	mv	a0,s2
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	60c080e7          	jalr	1548(ra) # 80003260 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c5c:	013a09bb          	addw	s3,s4,s3
    80003c60:	009a04bb          	addw	s1,s4,s1
    80003c64:	9aee                	add	s5,s5,s11
    80003c66:	0569f763          	bgeu	s3,s6,80003cb4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c6a:	000ba903          	lw	s2,0(s7)
    80003c6e:	00a4d59b          	srliw	a1,s1,0xa
    80003c72:	855e                	mv	a0,s7
    80003c74:	00000097          	auipc	ra,0x0
    80003c78:	8ac080e7          	jalr	-1876(ra) # 80003520 <bmap>
    80003c7c:	0005059b          	sext.w	a1,a0
    80003c80:	854a                	mv	a0,s2
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	4ae080e7          	jalr	1198(ra) # 80003130 <bread>
    80003c8a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c8c:	3ff4f713          	andi	a4,s1,1023
    80003c90:	40ed07bb          	subw	a5,s10,a4
    80003c94:	413b06bb          	subw	a3,s6,s3
    80003c98:	8a3e                	mv	s4,a5
    80003c9a:	2781                	sext.w	a5,a5
    80003c9c:	0006861b          	sext.w	a2,a3
    80003ca0:	f8f679e3          	bgeu	a2,a5,80003c32 <readi+0x4c>
    80003ca4:	8a36                	mv	s4,a3
    80003ca6:	b771                	j	80003c32 <readi+0x4c>
      brelse(bp);
    80003ca8:	854a                	mv	a0,s2
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	5b6080e7          	jalr	1462(ra) # 80003260 <brelse>
      tot = -1;
    80003cb2:	59fd                	li	s3,-1
  }
  return tot;
    80003cb4:	0009851b          	sext.w	a0,s3
}
    80003cb8:	70a6                	ld	ra,104(sp)
    80003cba:	7406                	ld	s0,96(sp)
    80003cbc:	64e6                	ld	s1,88(sp)
    80003cbe:	6946                	ld	s2,80(sp)
    80003cc0:	69a6                	ld	s3,72(sp)
    80003cc2:	6a06                	ld	s4,64(sp)
    80003cc4:	7ae2                	ld	s5,56(sp)
    80003cc6:	7b42                	ld	s6,48(sp)
    80003cc8:	7ba2                	ld	s7,40(sp)
    80003cca:	7c02                	ld	s8,32(sp)
    80003ccc:	6ce2                	ld	s9,24(sp)
    80003cce:	6d42                	ld	s10,16(sp)
    80003cd0:	6da2                	ld	s11,8(sp)
    80003cd2:	6165                	addi	sp,sp,112
    80003cd4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd6:	89da                	mv	s3,s6
    80003cd8:	bff1                	j	80003cb4 <readi+0xce>
    return 0;
    80003cda:	4501                	li	a0,0
}
    80003cdc:	8082                	ret

0000000080003cde <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cde:	497c                	lw	a5,84(a0)
    80003ce0:	10d7e763          	bltu	a5,a3,80003dee <writei+0x110>
{
    80003ce4:	7159                	addi	sp,sp,-112
    80003ce6:	f486                	sd	ra,104(sp)
    80003ce8:	f0a2                	sd	s0,96(sp)
    80003cea:	eca6                	sd	s1,88(sp)
    80003cec:	e8ca                	sd	s2,80(sp)
    80003cee:	e4ce                	sd	s3,72(sp)
    80003cf0:	e0d2                	sd	s4,64(sp)
    80003cf2:	fc56                	sd	s5,56(sp)
    80003cf4:	f85a                	sd	s6,48(sp)
    80003cf6:	f45e                	sd	s7,40(sp)
    80003cf8:	f062                	sd	s8,32(sp)
    80003cfa:	ec66                	sd	s9,24(sp)
    80003cfc:	e86a                	sd	s10,16(sp)
    80003cfe:	e46e                	sd	s11,8(sp)
    80003d00:	1880                	addi	s0,sp,112
    80003d02:	8baa                	mv	s7,a0
    80003d04:	8c2e                	mv	s8,a1
    80003d06:	8ab2                	mv	s5,a2
    80003d08:	8936                	mv	s2,a3
    80003d0a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d0c:	00e687bb          	addw	a5,a3,a4
    80003d10:	0ed7e163          	bltu	a5,a3,80003df2 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d14:	00043737          	lui	a4,0x43
    80003d18:	0cf76f63          	bltu	a4,a5,80003df6 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d1c:	0a0b0863          	beqz	s6,80003dcc <writei+0xee>
    80003d20:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d22:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d26:	5cfd                	li	s9,-1
    80003d28:	a091                	j	80003d6c <writei+0x8e>
    80003d2a:	02099d93          	slli	s11,s3,0x20
    80003d2e:	020ddd93          	srli	s11,s11,0x20
    80003d32:	06048513          	addi	a0,s1,96
    80003d36:	86ee                	mv	a3,s11
    80003d38:	8656                	mv	a2,s5
    80003d3a:	85e2                	mv	a1,s8
    80003d3c:	953a                	add	a0,a0,a4
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	a8a080e7          	jalr	-1398(ra) # 800027c8 <either_copyin>
    80003d46:	07950263          	beq	a0,s9,80003daa <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003d4a:	8526                	mv	a0,s1
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	796080e7          	jalr	1942(ra) # 800044e2 <log_write>
    brelse(bp);
    80003d54:	8526                	mv	a0,s1
    80003d56:	fffff097          	auipc	ra,0xfffff
    80003d5a:	50a080e7          	jalr	1290(ra) # 80003260 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d5e:	01498a3b          	addw	s4,s3,s4
    80003d62:	0129893b          	addw	s2,s3,s2
    80003d66:	9aee                	add	s5,s5,s11
    80003d68:	056a7763          	bgeu	s4,s6,80003db6 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d6c:	000ba483          	lw	s1,0(s7)
    80003d70:	00a9559b          	srliw	a1,s2,0xa
    80003d74:	855e                	mv	a0,s7
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	7aa080e7          	jalr	1962(ra) # 80003520 <bmap>
    80003d7e:	0005059b          	sext.w	a1,a0
    80003d82:	8526                	mv	a0,s1
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	3ac080e7          	jalr	940(ra) # 80003130 <bread>
    80003d8c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d8e:	3ff97713          	andi	a4,s2,1023
    80003d92:	40ed07bb          	subw	a5,s10,a4
    80003d96:	414b06bb          	subw	a3,s6,s4
    80003d9a:	89be                	mv	s3,a5
    80003d9c:	2781                	sext.w	a5,a5
    80003d9e:	0006861b          	sext.w	a2,a3
    80003da2:	f8f674e3          	bgeu	a2,a5,80003d2a <writei+0x4c>
    80003da6:	89b6                	mv	s3,a3
    80003da8:	b749                	j	80003d2a <writei+0x4c>
      brelse(bp);
    80003daa:	8526                	mv	a0,s1
    80003dac:	fffff097          	auipc	ra,0xfffff
    80003db0:	4b4080e7          	jalr	1204(ra) # 80003260 <brelse>
      n = -1;
    80003db4:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003db6:	054ba783          	lw	a5,84(s7)
    80003dba:	0127f463          	bgeu	a5,s2,80003dc2 <writei+0xe4>
      ip->size = off;
    80003dbe:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003dc2:	855e                	mv	a0,s7
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	aa2080e7          	jalr	-1374(ra) # 80003866 <iupdate>
  }

  return n;
    80003dcc:	000b051b          	sext.w	a0,s6
}
    80003dd0:	70a6                	ld	ra,104(sp)
    80003dd2:	7406                	ld	s0,96(sp)
    80003dd4:	64e6                	ld	s1,88(sp)
    80003dd6:	6946                	ld	s2,80(sp)
    80003dd8:	69a6                	ld	s3,72(sp)
    80003dda:	6a06                	ld	s4,64(sp)
    80003ddc:	7ae2                	ld	s5,56(sp)
    80003dde:	7b42                	ld	s6,48(sp)
    80003de0:	7ba2                	ld	s7,40(sp)
    80003de2:	7c02                	ld	s8,32(sp)
    80003de4:	6ce2                	ld	s9,24(sp)
    80003de6:	6d42                	ld	s10,16(sp)
    80003de8:	6da2                	ld	s11,8(sp)
    80003dea:	6165                	addi	sp,sp,112
    80003dec:	8082                	ret
    return -1;
    80003dee:	557d                	li	a0,-1
}
    80003df0:	8082                	ret
    return -1;
    80003df2:	557d                	li	a0,-1
    80003df4:	bff1                	j	80003dd0 <writei+0xf2>
    return -1;
    80003df6:	557d                	li	a0,-1
    80003df8:	bfe1                	j	80003dd0 <writei+0xf2>

0000000080003dfa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dfa:	1141                	addi	sp,sp,-16
    80003dfc:	e406                	sd	ra,8(sp)
    80003dfe:	e022                	sd	s0,0(sp)
    80003e00:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e02:	4639                	li	a2,14
    80003e04:	ffffd097          	auipc	ra,0xffffd
    80003e08:	36e080e7          	jalr	878(ra) # 80001172 <strncmp>
}
    80003e0c:	60a2                	ld	ra,8(sp)
    80003e0e:	6402                	ld	s0,0(sp)
    80003e10:	0141                	addi	sp,sp,16
    80003e12:	8082                	ret

0000000080003e14 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e14:	7139                	addi	sp,sp,-64
    80003e16:	fc06                	sd	ra,56(sp)
    80003e18:	f822                	sd	s0,48(sp)
    80003e1a:	f426                	sd	s1,40(sp)
    80003e1c:	f04a                	sd	s2,32(sp)
    80003e1e:	ec4e                	sd	s3,24(sp)
    80003e20:	e852                	sd	s4,16(sp)
    80003e22:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e24:	04c51703          	lh	a4,76(a0)
    80003e28:	4785                	li	a5,1
    80003e2a:	00f71a63          	bne	a4,a5,80003e3e <dirlookup+0x2a>
    80003e2e:	892a                	mv	s2,a0
    80003e30:	89ae                	mv	s3,a1
    80003e32:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e34:	497c                	lw	a5,84(a0)
    80003e36:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e38:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e3a:	e79d                	bnez	a5,80003e68 <dirlookup+0x54>
    80003e3c:	a8a5                	j	80003eb4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e3e:	00005517          	auipc	a0,0x5
    80003e42:	81250513          	addi	a0,a0,-2030 # 80008650 <syscalls+0x198>
    80003e46:	ffffc097          	auipc	ra,0xffffc
    80003e4a:	706080e7          	jalr	1798(ra) # 8000054c <panic>
      panic("dirlookup read");
    80003e4e:	00005517          	auipc	a0,0x5
    80003e52:	81a50513          	addi	a0,a0,-2022 # 80008668 <syscalls+0x1b0>
    80003e56:	ffffc097          	auipc	ra,0xffffc
    80003e5a:	6f6080e7          	jalr	1782(ra) # 8000054c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5e:	24c1                	addiw	s1,s1,16
    80003e60:	05492783          	lw	a5,84(s2)
    80003e64:	04f4f763          	bgeu	s1,a5,80003eb2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e68:	4741                	li	a4,16
    80003e6a:	86a6                	mv	a3,s1
    80003e6c:	fc040613          	addi	a2,s0,-64
    80003e70:	4581                	li	a1,0
    80003e72:	854a                	mv	a0,s2
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	d72080e7          	jalr	-654(ra) # 80003be6 <readi>
    80003e7c:	47c1                	li	a5,16
    80003e7e:	fcf518e3          	bne	a0,a5,80003e4e <dirlookup+0x3a>
    if(de.inum == 0)
    80003e82:	fc045783          	lhu	a5,-64(s0)
    80003e86:	dfe1                	beqz	a5,80003e5e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e88:	fc240593          	addi	a1,s0,-62
    80003e8c:	854e                	mv	a0,s3
    80003e8e:	00000097          	auipc	ra,0x0
    80003e92:	f6c080e7          	jalr	-148(ra) # 80003dfa <namecmp>
    80003e96:	f561                	bnez	a0,80003e5e <dirlookup+0x4a>
      if(poff)
    80003e98:	000a0463          	beqz	s4,80003ea0 <dirlookup+0x8c>
        *poff = off;
    80003e9c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ea0:	fc045583          	lhu	a1,-64(s0)
    80003ea4:	00092503          	lw	a0,0(s2)
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	754080e7          	jalr	1876(ra) # 800035fc <iget>
    80003eb0:	a011                	j	80003eb4 <dirlookup+0xa0>
  return 0;
    80003eb2:	4501                	li	a0,0
}
    80003eb4:	70e2                	ld	ra,56(sp)
    80003eb6:	7442                	ld	s0,48(sp)
    80003eb8:	74a2                	ld	s1,40(sp)
    80003eba:	7902                	ld	s2,32(sp)
    80003ebc:	69e2                	ld	s3,24(sp)
    80003ebe:	6a42                	ld	s4,16(sp)
    80003ec0:	6121                	addi	sp,sp,64
    80003ec2:	8082                	ret

0000000080003ec4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ec4:	711d                	addi	sp,sp,-96
    80003ec6:	ec86                	sd	ra,88(sp)
    80003ec8:	e8a2                	sd	s0,80(sp)
    80003eca:	e4a6                	sd	s1,72(sp)
    80003ecc:	e0ca                	sd	s2,64(sp)
    80003ece:	fc4e                	sd	s3,56(sp)
    80003ed0:	f852                	sd	s4,48(sp)
    80003ed2:	f456                	sd	s5,40(sp)
    80003ed4:	f05a                	sd	s6,32(sp)
    80003ed6:	ec5e                	sd	s7,24(sp)
    80003ed8:	e862                	sd	s8,16(sp)
    80003eda:	e466                	sd	s9,8(sp)
    80003edc:	e06a                	sd	s10,0(sp)
    80003ede:	1080                	addi	s0,sp,96
    80003ee0:	84aa                	mv	s1,a0
    80003ee2:	8b2e                	mv	s6,a1
    80003ee4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ee6:	00054703          	lbu	a4,0(a0)
    80003eea:	02f00793          	li	a5,47
    80003eee:	02f70363          	beq	a4,a5,80003f14 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ef2:	ffffe097          	auipc	ra,0xffffe
    80003ef6:	e0e080e7          	jalr	-498(ra) # 80001d00 <myproc>
    80003efa:	15853503          	ld	a0,344(a0)
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	9f6080e7          	jalr	-1546(ra) # 800038f4 <idup>
    80003f06:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003f08:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003f0c:	4cb5                	li	s9,13
  len = path - s;
    80003f0e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f10:	4c05                	li	s8,1
    80003f12:	a87d                	j	80003fd0 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003f14:	4585                	li	a1,1
    80003f16:	4505                	li	a0,1
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	6e4080e7          	jalr	1764(ra) # 800035fc <iget>
    80003f20:	8a2a                	mv	s4,a0
    80003f22:	b7dd                	j	80003f08 <namex+0x44>
      iunlockput(ip);
    80003f24:	8552                	mv	a0,s4
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	c6e080e7          	jalr	-914(ra) # 80003b94 <iunlockput>
      return 0;
    80003f2e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f30:	8552                	mv	a0,s4
    80003f32:	60e6                	ld	ra,88(sp)
    80003f34:	6446                	ld	s0,80(sp)
    80003f36:	64a6                	ld	s1,72(sp)
    80003f38:	6906                	ld	s2,64(sp)
    80003f3a:	79e2                	ld	s3,56(sp)
    80003f3c:	7a42                	ld	s4,48(sp)
    80003f3e:	7aa2                	ld	s5,40(sp)
    80003f40:	7b02                	ld	s6,32(sp)
    80003f42:	6be2                	ld	s7,24(sp)
    80003f44:	6c42                	ld	s8,16(sp)
    80003f46:	6ca2                	ld	s9,8(sp)
    80003f48:	6d02                	ld	s10,0(sp)
    80003f4a:	6125                	addi	sp,sp,96
    80003f4c:	8082                	ret
      iunlock(ip);
    80003f4e:	8552                	mv	a0,s4
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	aa4080e7          	jalr	-1372(ra) # 800039f4 <iunlock>
      return ip;
    80003f58:	bfe1                	j	80003f30 <namex+0x6c>
      iunlockput(ip);
    80003f5a:	8552                	mv	a0,s4
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	c38080e7          	jalr	-968(ra) # 80003b94 <iunlockput>
      return 0;
    80003f64:	8a4e                	mv	s4,s3
    80003f66:	b7e9                	j	80003f30 <namex+0x6c>
  len = path - s;
    80003f68:	40998633          	sub	a2,s3,s1
    80003f6c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f70:	09acd863          	bge	s9,s10,80004000 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f74:	4639                	li	a2,14
    80003f76:	85a6                	mv	a1,s1
    80003f78:	8556                	mv	a0,s5
    80003f7a:	ffffd097          	auipc	ra,0xffffd
    80003f7e:	17c080e7          	jalr	380(ra) # 800010f6 <memmove>
    80003f82:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f84:	0004c783          	lbu	a5,0(s1)
    80003f88:	01279763          	bne	a5,s2,80003f96 <namex+0xd2>
    path++;
    80003f8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f8e:	0004c783          	lbu	a5,0(s1)
    80003f92:	ff278de3          	beq	a5,s2,80003f8c <namex+0xc8>
    ilock(ip);
    80003f96:	8552                	mv	a0,s4
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	99a080e7          	jalr	-1638(ra) # 80003932 <ilock>
    if(ip->type != T_DIR){
    80003fa0:	04ca1783          	lh	a5,76(s4)
    80003fa4:	f98790e3          	bne	a5,s8,80003f24 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003fa8:	000b0563          	beqz	s6,80003fb2 <namex+0xee>
    80003fac:	0004c783          	lbu	a5,0(s1)
    80003fb0:	dfd9                	beqz	a5,80003f4e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fb2:	865e                	mv	a2,s7
    80003fb4:	85d6                	mv	a1,s5
    80003fb6:	8552                	mv	a0,s4
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	e5c080e7          	jalr	-420(ra) # 80003e14 <dirlookup>
    80003fc0:	89aa                	mv	s3,a0
    80003fc2:	dd41                	beqz	a0,80003f5a <namex+0x96>
    iunlockput(ip);
    80003fc4:	8552                	mv	a0,s4
    80003fc6:	00000097          	auipc	ra,0x0
    80003fca:	bce080e7          	jalr	-1074(ra) # 80003b94 <iunlockput>
    ip = next;
    80003fce:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	01279763          	bne	a5,s2,80003fe2 <namex+0x11e>
    path++;
    80003fd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fda:	0004c783          	lbu	a5,0(s1)
    80003fde:	ff278de3          	beq	a5,s2,80003fd8 <namex+0x114>
  if(*path == 0)
    80003fe2:	cb9d                	beqz	a5,80004018 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003fe4:	0004c783          	lbu	a5,0(s1)
    80003fe8:	89a6                	mv	s3,s1
  len = path - s;
    80003fea:	8d5e                	mv	s10,s7
    80003fec:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fee:	01278963          	beq	a5,s2,80004000 <namex+0x13c>
    80003ff2:	dbbd                	beqz	a5,80003f68 <namex+0xa4>
    path++;
    80003ff4:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003ff6:	0009c783          	lbu	a5,0(s3)
    80003ffa:	ff279ce3          	bne	a5,s2,80003ff2 <namex+0x12e>
    80003ffe:	b7ad                	j	80003f68 <namex+0xa4>
    memmove(name, s, len);
    80004000:	2601                	sext.w	a2,a2
    80004002:	85a6                	mv	a1,s1
    80004004:	8556                	mv	a0,s5
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	0f0080e7          	jalr	240(ra) # 800010f6 <memmove>
    name[len] = 0;
    8000400e:	9d56                	add	s10,s10,s5
    80004010:	000d0023          	sb	zero,0(s10)
    80004014:	84ce                	mv	s1,s3
    80004016:	b7bd                	j	80003f84 <namex+0xc0>
  if(nameiparent){
    80004018:	f00b0ce3          	beqz	s6,80003f30 <namex+0x6c>
    iput(ip);
    8000401c:	8552                	mv	a0,s4
    8000401e:	00000097          	auipc	ra,0x0
    80004022:	ace080e7          	jalr	-1330(ra) # 80003aec <iput>
    return 0;
    80004026:	4a01                	li	s4,0
    80004028:	b721                	j	80003f30 <namex+0x6c>

000000008000402a <dirlink>:
{
    8000402a:	7139                	addi	sp,sp,-64
    8000402c:	fc06                	sd	ra,56(sp)
    8000402e:	f822                	sd	s0,48(sp)
    80004030:	f426                	sd	s1,40(sp)
    80004032:	f04a                	sd	s2,32(sp)
    80004034:	ec4e                	sd	s3,24(sp)
    80004036:	e852                	sd	s4,16(sp)
    80004038:	0080                	addi	s0,sp,64
    8000403a:	892a                	mv	s2,a0
    8000403c:	8a2e                	mv	s4,a1
    8000403e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004040:	4601                	li	a2,0
    80004042:	00000097          	auipc	ra,0x0
    80004046:	dd2080e7          	jalr	-558(ra) # 80003e14 <dirlookup>
    8000404a:	e93d                	bnez	a0,800040c0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000404c:	05492483          	lw	s1,84(s2)
    80004050:	c49d                	beqz	s1,8000407e <dirlink+0x54>
    80004052:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004054:	4741                	li	a4,16
    80004056:	86a6                	mv	a3,s1
    80004058:	fc040613          	addi	a2,s0,-64
    8000405c:	4581                	li	a1,0
    8000405e:	854a                	mv	a0,s2
    80004060:	00000097          	auipc	ra,0x0
    80004064:	b86080e7          	jalr	-1146(ra) # 80003be6 <readi>
    80004068:	47c1                	li	a5,16
    8000406a:	06f51163          	bne	a0,a5,800040cc <dirlink+0xa2>
    if(de.inum == 0)
    8000406e:	fc045783          	lhu	a5,-64(s0)
    80004072:	c791                	beqz	a5,8000407e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004074:	24c1                	addiw	s1,s1,16
    80004076:	05492783          	lw	a5,84(s2)
    8000407a:	fcf4ede3          	bltu	s1,a5,80004054 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000407e:	4639                	li	a2,14
    80004080:	85d2                	mv	a1,s4
    80004082:	fc240513          	addi	a0,s0,-62
    80004086:	ffffd097          	auipc	ra,0xffffd
    8000408a:	128080e7          	jalr	296(ra) # 800011ae <strncpy>
  de.inum = inum;
    8000408e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004092:	4741                	li	a4,16
    80004094:	86a6                	mv	a3,s1
    80004096:	fc040613          	addi	a2,s0,-64
    8000409a:	4581                	li	a1,0
    8000409c:	854a                	mv	a0,s2
    8000409e:	00000097          	auipc	ra,0x0
    800040a2:	c40080e7          	jalr	-960(ra) # 80003cde <writei>
    800040a6:	872a                	mv	a4,a0
    800040a8:	47c1                	li	a5,16
  return 0;
    800040aa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ac:	02f71863          	bne	a4,a5,800040dc <dirlink+0xb2>
}
    800040b0:	70e2                	ld	ra,56(sp)
    800040b2:	7442                	ld	s0,48(sp)
    800040b4:	74a2                	ld	s1,40(sp)
    800040b6:	7902                	ld	s2,32(sp)
    800040b8:	69e2                	ld	s3,24(sp)
    800040ba:	6a42                	ld	s4,16(sp)
    800040bc:	6121                	addi	sp,sp,64
    800040be:	8082                	ret
    iput(ip);
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	a2c080e7          	jalr	-1492(ra) # 80003aec <iput>
    return -1;
    800040c8:	557d                	li	a0,-1
    800040ca:	b7dd                	j	800040b0 <dirlink+0x86>
      panic("dirlink read");
    800040cc:	00004517          	auipc	a0,0x4
    800040d0:	5ac50513          	addi	a0,a0,1452 # 80008678 <syscalls+0x1c0>
    800040d4:	ffffc097          	auipc	ra,0xffffc
    800040d8:	478080e7          	jalr	1144(ra) # 8000054c <panic>
    panic("dirlink");
    800040dc:	00004517          	auipc	a0,0x4
    800040e0:	6bc50513          	addi	a0,a0,1724 # 80008798 <syscalls+0x2e0>
    800040e4:	ffffc097          	auipc	ra,0xffffc
    800040e8:	468080e7          	jalr	1128(ra) # 8000054c <panic>

00000000800040ec <namei>:

struct inode*
namei(char *path)
{
    800040ec:	1101                	addi	sp,sp,-32
    800040ee:	ec06                	sd	ra,24(sp)
    800040f0:	e822                	sd	s0,16(sp)
    800040f2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040f4:	fe040613          	addi	a2,s0,-32
    800040f8:	4581                	li	a1,0
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	dca080e7          	jalr	-566(ra) # 80003ec4 <namex>
}
    80004102:	60e2                	ld	ra,24(sp)
    80004104:	6442                	ld	s0,16(sp)
    80004106:	6105                	addi	sp,sp,32
    80004108:	8082                	ret

000000008000410a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000410a:	1141                	addi	sp,sp,-16
    8000410c:	e406                	sd	ra,8(sp)
    8000410e:	e022                	sd	s0,0(sp)
    80004110:	0800                	addi	s0,sp,16
    80004112:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004114:	4585                	li	a1,1
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	dae080e7          	jalr	-594(ra) # 80003ec4 <namex>
}
    8000411e:	60a2                	ld	ra,8(sp)
    80004120:	6402                	ld	s0,0(sp)
    80004122:	0141                	addi	sp,sp,16
    80004124:	8082                	ret

0000000080004126 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004126:	1101                	addi	sp,sp,-32
    80004128:	ec06                	sd	ra,24(sp)
    8000412a:	e822                	sd	s0,16(sp)
    8000412c:	e426                	sd	s1,8(sp)
    8000412e:	e04a                	sd	s2,0(sp)
    80004130:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004132:	0001e917          	auipc	s2,0x1e
    80004136:	6b690913          	addi	s2,s2,1718 # 800227e8 <log>
    8000413a:	02092583          	lw	a1,32(s2)
    8000413e:	03092503          	lw	a0,48(s2)
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	fee080e7          	jalr	-18(ra) # 80003130 <bread>
    8000414a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000414c:	03492683          	lw	a3,52(s2)
    80004150:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004152:	02d05863          	blez	a3,80004182 <write_head+0x5c>
    80004156:	0001e797          	auipc	a5,0x1e
    8000415a:	6ca78793          	addi	a5,a5,1738 # 80022820 <log+0x38>
    8000415e:	06450713          	addi	a4,a0,100
    80004162:	36fd                	addiw	a3,a3,-1
    80004164:	02069613          	slli	a2,a3,0x20
    80004168:	01e65693          	srli	a3,a2,0x1e
    8000416c:	0001e617          	auipc	a2,0x1e
    80004170:	6b860613          	addi	a2,a2,1720 # 80022824 <log+0x3c>
    80004174:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004176:	4390                	lw	a2,0(a5)
    80004178:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000417a:	0791                	addi	a5,a5,4
    8000417c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000417e:	fed79ce3          	bne	a5,a3,80004176 <write_head+0x50>
  }
  bwrite(buf);
    80004182:	8526                	mv	a0,s1
    80004184:	fffff097          	auipc	ra,0xfffff
    80004188:	09e080e7          	jalr	158(ra) # 80003222 <bwrite>
  brelse(buf);
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	0d2080e7          	jalr	210(ra) # 80003260 <brelse>
}
    80004196:	60e2                	ld	ra,24(sp)
    80004198:	6442                	ld	s0,16(sp)
    8000419a:	64a2                	ld	s1,8(sp)
    8000419c:	6902                	ld	s2,0(sp)
    8000419e:	6105                	addi	sp,sp,32
    800041a0:	8082                	ret

00000000800041a2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a2:	0001e797          	auipc	a5,0x1e
    800041a6:	67a7a783          	lw	a5,1658(a5) # 8002281c <log+0x34>
    800041aa:	0af05d63          	blez	a5,80004264 <install_trans+0xc2>
{
    800041ae:	7139                	addi	sp,sp,-64
    800041b0:	fc06                	sd	ra,56(sp)
    800041b2:	f822                	sd	s0,48(sp)
    800041b4:	f426                	sd	s1,40(sp)
    800041b6:	f04a                	sd	s2,32(sp)
    800041b8:	ec4e                	sd	s3,24(sp)
    800041ba:	e852                	sd	s4,16(sp)
    800041bc:	e456                	sd	s5,8(sp)
    800041be:	e05a                	sd	s6,0(sp)
    800041c0:	0080                	addi	s0,sp,64
    800041c2:	8b2a                	mv	s6,a0
    800041c4:	0001ea97          	auipc	s5,0x1e
    800041c8:	65ca8a93          	addi	s5,s5,1628 # 80022820 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041cc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041ce:	0001e997          	auipc	s3,0x1e
    800041d2:	61a98993          	addi	s3,s3,1562 # 800227e8 <log>
    800041d6:	a00d                	j	800041f8 <install_trans+0x56>
    brelse(lbuf);
    800041d8:	854a                	mv	a0,s2
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	086080e7          	jalr	134(ra) # 80003260 <brelse>
    brelse(dbuf);
    800041e2:	8526                	mv	a0,s1
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	07c080e7          	jalr	124(ra) # 80003260 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	2a05                	addiw	s4,s4,1
    800041ee:	0a91                	addi	s5,s5,4
    800041f0:	0349a783          	lw	a5,52(s3)
    800041f4:	04fa5e63          	bge	s4,a5,80004250 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041f8:	0209a583          	lw	a1,32(s3)
    800041fc:	014585bb          	addw	a1,a1,s4
    80004200:	2585                	addiw	a1,a1,1
    80004202:	0309a503          	lw	a0,48(s3)
    80004206:	fffff097          	auipc	ra,0xfffff
    8000420a:	f2a080e7          	jalr	-214(ra) # 80003130 <bread>
    8000420e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004210:	000aa583          	lw	a1,0(s5)
    80004214:	0309a503          	lw	a0,48(s3)
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	f18080e7          	jalr	-232(ra) # 80003130 <bread>
    80004220:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004222:	40000613          	li	a2,1024
    80004226:	06090593          	addi	a1,s2,96
    8000422a:	06050513          	addi	a0,a0,96
    8000422e:	ffffd097          	auipc	ra,0xffffd
    80004232:	ec8080e7          	jalr	-312(ra) # 800010f6 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	fea080e7          	jalr	-22(ra) # 80003222 <bwrite>
    if(recovering == 0)
    80004240:	f80b1ce3          	bnez	s6,800041d8 <install_trans+0x36>
      bunpin(dbuf);
    80004244:	8526                	mv	a0,s1
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	0f4080e7          	jalr	244(ra) # 8000333a <bunpin>
    8000424e:	b769                	j	800041d8 <install_trans+0x36>
}
    80004250:	70e2                	ld	ra,56(sp)
    80004252:	7442                	ld	s0,48(sp)
    80004254:	74a2                	ld	s1,40(sp)
    80004256:	7902                	ld	s2,32(sp)
    80004258:	69e2                	ld	s3,24(sp)
    8000425a:	6a42                	ld	s4,16(sp)
    8000425c:	6aa2                	ld	s5,8(sp)
    8000425e:	6b02                	ld	s6,0(sp)
    80004260:	6121                	addi	sp,sp,64
    80004262:	8082                	ret
    80004264:	8082                	ret

0000000080004266 <initlog>:
{
    80004266:	7179                	addi	sp,sp,-48
    80004268:	f406                	sd	ra,40(sp)
    8000426a:	f022                	sd	s0,32(sp)
    8000426c:	ec26                	sd	s1,24(sp)
    8000426e:	e84a                	sd	s2,16(sp)
    80004270:	e44e                	sd	s3,8(sp)
    80004272:	1800                	addi	s0,sp,48
    80004274:	892a                	mv	s2,a0
    80004276:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004278:	0001e497          	auipc	s1,0x1e
    8000427c:	57048493          	addi	s1,s1,1392 # 800227e8 <log>
    80004280:	00004597          	auipc	a1,0x4
    80004284:	40858593          	addi	a1,a1,1032 # 80008688 <syscalls+0x1d0>
    80004288:	8526                	mv	a0,s1
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	bac080e7          	jalr	-1108(ra) # 80000e36 <initlock>
  log.start = sb->logstart;
    80004292:	0149a583          	lw	a1,20(s3)
    80004296:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    80004298:	0109a783          	lw	a5,16(s3)
    8000429c:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    8000429e:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042a2:	854a                	mv	a0,s2
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	e8c080e7          	jalr	-372(ra) # 80003130 <bread>
  log.lh.n = lh->n;
    800042ac:	5134                	lw	a3,96(a0)
    800042ae:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042b0:	02d05663          	blez	a3,800042dc <initlog+0x76>
    800042b4:	06450793          	addi	a5,a0,100
    800042b8:	0001e717          	auipc	a4,0x1e
    800042bc:	56870713          	addi	a4,a4,1384 # 80022820 <log+0x38>
    800042c0:	36fd                	addiw	a3,a3,-1
    800042c2:	02069613          	slli	a2,a3,0x20
    800042c6:	01e65693          	srli	a3,a2,0x1e
    800042ca:	06850613          	addi	a2,a0,104
    800042ce:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800042d0:	4390                	lw	a2,0(a5)
    800042d2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042d4:	0791                	addi	a5,a5,4
    800042d6:	0711                	addi	a4,a4,4
    800042d8:	fed79ce3          	bne	a5,a3,800042d0 <initlog+0x6a>
  brelse(buf);
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	f84080e7          	jalr	-124(ra) # 80003260 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042e4:	4505                	li	a0,1
    800042e6:	00000097          	auipc	ra,0x0
    800042ea:	ebc080e7          	jalr	-324(ra) # 800041a2 <install_trans>
  log.lh.n = 0;
    800042ee:	0001e797          	auipc	a5,0x1e
    800042f2:	5207a723          	sw	zero,1326(a5) # 8002281c <log+0x34>
  write_head(); // clear the log
    800042f6:	00000097          	auipc	ra,0x0
    800042fa:	e30080e7          	jalr	-464(ra) # 80004126 <write_head>
}
    800042fe:	70a2                	ld	ra,40(sp)
    80004300:	7402                	ld	s0,32(sp)
    80004302:	64e2                	ld	s1,24(sp)
    80004304:	6942                	ld	s2,16(sp)
    80004306:	69a2                	ld	s3,8(sp)
    80004308:	6145                	addi	sp,sp,48
    8000430a:	8082                	ret

000000008000430c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000430c:	1101                	addi	sp,sp,-32
    8000430e:	ec06                	sd	ra,24(sp)
    80004310:	e822                	sd	s0,16(sp)
    80004312:	e426                	sd	s1,8(sp)
    80004314:	e04a                	sd	s2,0(sp)
    80004316:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004318:	0001e517          	auipc	a0,0x1e
    8000431c:	4d050513          	addi	a0,a0,1232 # 800227e8 <log>
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	99a080e7          	jalr	-1638(ra) # 80000cba <acquire>
  while(1){
    if(log.committing){
    80004328:	0001e497          	auipc	s1,0x1e
    8000432c:	4c048493          	addi	s1,s1,1216 # 800227e8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004330:	4979                	li	s2,30
    80004332:	a039                	j	80004340 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004334:	85a6                	mv	a1,s1
    80004336:	8526                	mv	a0,s1
    80004338:	ffffe097          	auipc	ra,0xffffe
    8000433c:	1e0080e7          	jalr	480(ra) # 80002518 <sleep>
    if(log.committing){
    80004340:	54dc                	lw	a5,44(s1)
    80004342:	fbed                	bnez	a5,80004334 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004344:	5498                	lw	a4,40(s1)
    80004346:	2705                	addiw	a4,a4,1
    80004348:	0007069b          	sext.w	a3,a4
    8000434c:	0027179b          	slliw	a5,a4,0x2
    80004350:	9fb9                	addw	a5,a5,a4
    80004352:	0017979b          	slliw	a5,a5,0x1
    80004356:	58d8                	lw	a4,52(s1)
    80004358:	9fb9                	addw	a5,a5,a4
    8000435a:	00f95963          	bge	s2,a5,8000436c <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000435e:	85a6                	mv	a1,s1
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	1b6080e7          	jalr	438(ra) # 80002518 <sleep>
    8000436a:	bfd9                	j	80004340 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000436c:	0001e517          	auipc	a0,0x1e
    80004370:	47c50513          	addi	a0,a0,1148 # 800227e8 <log>
    80004374:	d514                	sw	a3,40(a0)
      release(&log.lock);
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	a14080e7          	jalr	-1516(ra) # 80000d8a <release>
      break;
    }
  }
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000438a:	7139                	addi	sp,sp,-64
    8000438c:	fc06                	sd	ra,56(sp)
    8000438e:	f822                	sd	s0,48(sp)
    80004390:	f426                	sd	s1,40(sp)
    80004392:	f04a                	sd	s2,32(sp)
    80004394:	ec4e                	sd	s3,24(sp)
    80004396:	e852                	sd	s4,16(sp)
    80004398:	e456                	sd	s5,8(sp)
    8000439a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000439c:	0001e497          	auipc	s1,0x1e
    800043a0:	44c48493          	addi	s1,s1,1100 # 800227e8 <log>
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	914080e7          	jalr	-1772(ra) # 80000cba <acquire>
  log.outstanding -= 1;
    800043ae:	549c                	lw	a5,40(s1)
    800043b0:	37fd                	addiw	a5,a5,-1
    800043b2:	0007891b          	sext.w	s2,a5
    800043b6:	d49c                	sw	a5,40(s1)
  if(log.committing)
    800043b8:	54dc                	lw	a5,44(s1)
    800043ba:	e7b9                	bnez	a5,80004408 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043bc:	04091e63          	bnez	s2,80004418 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043c0:	0001e497          	auipc	s1,0x1e
    800043c4:	42848493          	addi	s1,s1,1064 # 800227e8 <log>
    800043c8:	4785                	li	a5,1
    800043ca:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043cc:	8526                	mv	a0,s1
    800043ce:	ffffd097          	auipc	ra,0xffffd
    800043d2:	9bc080e7          	jalr	-1604(ra) # 80000d8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043d6:	58dc                	lw	a5,52(s1)
    800043d8:	06f04763          	bgtz	a5,80004446 <end_op+0xbc>
    acquire(&log.lock);
    800043dc:	0001e497          	auipc	s1,0x1e
    800043e0:	40c48493          	addi	s1,s1,1036 # 800227e8 <log>
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	8d4080e7          	jalr	-1836(ra) # 80000cba <acquire>
    log.committing = 0;
    800043ee:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    800043f2:	8526                	mv	a0,s1
    800043f4:	ffffe097          	auipc	ra,0xffffe
    800043f8:	2a4080e7          	jalr	676(ra) # 80002698 <wakeup>
    release(&log.lock);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffd097          	auipc	ra,0xffffd
    80004402:	98c080e7          	jalr	-1652(ra) # 80000d8a <release>
}
    80004406:	a03d                	j	80004434 <end_op+0xaa>
    panic("log.committing");
    80004408:	00004517          	auipc	a0,0x4
    8000440c:	28850513          	addi	a0,a0,648 # 80008690 <syscalls+0x1d8>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	13c080e7          	jalr	316(ra) # 8000054c <panic>
    wakeup(&log);
    80004418:	0001e497          	auipc	s1,0x1e
    8000441c:	3d048493          	addi	s1,s1,976 # 800227e8 <log>
    80004420:	8526                	mv	a0,s1
    80004422:	ffffe097          	auipc	ra,0xffffe
    80004426:	276080e7          	jalr	630(ra) # 80002698 <wakeup>
  release(&log.lock);
    8000442a:	8526                	mv	a0,s1
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	95e080e7          	jalr	-1698(ra) # 80000d8a <release>
}
    80004434:	70e2                	ld	ra,56(sp)
    80004436:	7442                	ld	s0,48(sp)
    80004438:	74a2                	ld	s1,40(sp)
    8000443a:	7902                	ld	s2,32(sp)
    8000443c:	69e2                	ld	s3,24(sp)
    8000443e:	6a42                	ld	s4,16(sp)
    80004440:	6aa2                	ld	s5,8(sp)
    80004442:	6121                	addi	sp,sp,64
    80004444:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004446:	0001ea97          	auipc	s5,0x1e
    8000444a:	3daa8a93          	addi	s5,s5,986 # 80022820 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000444e:	0001ea17          	auipc	s4,0x1e
    80004452:	39aa0a13          	addi	s4,s4,922 # 800227e8 <log>
    80004456:	020a2583          	lw	a1,32(s4)
    8000445a:	012585bb          	addw	a1,a1,s2
    8000445e:	2585                	addiw	a1,a1,1
    80004460:	030a2503          	lw	a0,48(s4)
    80004464:	fffff097          	auipc	ra,0xfffff
    80004468:	ccc080e7          	jalr	-820(ra) # 80003130 <bread>
    8000446c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000446e:	000aa583          	lw	a1,0(s5)
    80004472:	030a2503          	lw	a0,48(s4)
    80004476:	fffff097          	auipc	ra,0xfffff
    8000447a:	cba080e7          	jalr	-838(ra) # 80003130 <bread>
    8000447e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004480:	40000613          	li	a2,1024
    80004484:	06050593          	addi	a1,a0,96
    80004488:	06048513          	addi	a0,s1,96
    8000448c:	ffffd097          	auipc	ra,0xffffd
    80004490:	c6a080e7          	jalr	-918(ra) # 800010f6 <memmove>
    bwrite(to);  // write the log
    80004494:	8526                	mv	a0,s1
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	d8c080e7          	jalr	-628(ra) # 80003222 <bwrite>
    brelse(from);
    8000449e:	854e                	mv	a0,s3
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	dc0080e7          	jalr	-576(ra) # 80003260 <brelse>
    brelse(to);
    800044a8:	8526                	mv	a0,s1
    800044aa:	fffff097          	auipc	ra,0xfffff
    800044ae:	db6080e7          	jalr	-586(ra) # 80003260 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b2:	2905                	addiw	s2,s2,1
    800044b4:	0a91                	addi	s5,s5,4
    800044b6:	034a2783          	lw	a5,52(s4)
    800044ba:	f8f94ee3          	blt	s2,a5,80004456 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	c68080e7          	jalr	-920(ra) # 80004126 <write_head>
    install_trans(0); // Now install writes to home locations
    800044c6:	4501                	li	a0,0
    800044c8:	00000097          	auipc	ra,0x0
    800044cc:	cda080e7          	jalr	-806(ra) # 800041a2 <install_trans>
    log.lh.n = 0;
    800044d0:	0001e797          	auipc	a5,0x1e
    800044d4:	3407a623          	sw	zero,844(a5) # 8002281c <log+0x34>
    write_head();    // Erase the transaction from the log
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	c4e080e7          	jalr	-946(ra) # 80004126 <write_head>
    800044e0:	bdf5                	j	800043dc <end_op+0x52>

00000000800044e2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044e2:	1101                	addi	sp,sp,-32
    800044e4:	ec06                	sd	ra,24(sp)
    800044e6:	e822                	sd	s0,16(sp)
    800044e8:	e426                	sd	s1,8(sp)
    800044ea:	e04a                	sd	s2,0(sp)
    800044ec:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044ee:	0001e717          	auipc	a4,0x1e
    800044f2:	32e72703          	lw	a4,814(a4) # 8002281c <log+0x34>
    800044f6:	47f5                	li	a5,29
    800044f8:	08e7c063          	blt	a5,a4,80004578 <log_write+0x96>
    800044fc:	84aa                	mv	s1,a0
    800044fe:	0001e797          	auipc	a5,0x1e
    80004502:	30e7a783          	lw	a5,782(a5) # 8002280c <log+0x24>
    80004506:	37fd                	addiw	a5,a5,-1
    80004508:	06f75863          	bge	a4,a5,80004578 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000450c:	0001e797          	auipc	a5,0x1e
    80004510:	3047a783          	lw	a5,772(a5) # 80022810 <log+0x28>
    80004514:	06f05a63          	blez	a5,80004588 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004518:	0001e917          	auipc	s2,0x1e
    8000451c:	2d090913          	addi	s2,s2,720 # 800227e8 <log>
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	798080e7          	jalr	1944(ra) # 80000cba <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	03492603          	lw	a2,52(s2)
    8000452e:	06c05563          	blez	a2,80004598 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004532:	44cc                	lw	a1,12(s1)
    80004534:	0001e717          	auipc	a4,0x1e
    80004538:	2ec70713          	addi	a4,a4,748 # 80022820 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    8000453c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000453e:	4314                	lw	a3,0(a4)
    80004540:	04b68d63          	beq	a3,a1,8000459a <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004544:	2785                	addiw	a5,a5,1
    80004546:	0711                	addi	a4,a4,4
    80004548:	fec79be3          	bne	a5,a2,8000453e <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000454c:	0631                	addi	a2,a2,12
    8000454e:	060a                	slli	a2,a2,0x2
    80004550:	0001e797          	auipc	a5,0x1e
    80004554:	29878793          	addi	a5,a5,664 # 800227e8 <log>
    80004558:	97b2                	add	a5,a5,a2
    8000455a:	44d8                	lw	a4,12(s1)
    8000455c:	c798                	sw	a4,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000455e:	8526                	mv	a0,s1
    80004560:	fffff097          	auipc	ra,0xfffff
    80004564:	d9e080e7          	jalr	-610(ra) # 800032fe <bpin>
    log.lh.n++;
    80004568:	0001e717          	auipc	a4,0x1e
    8000456c:	28070713          	addi	a4,a4,640 # 800227e8 <log>
    80004570:	5b5c                	lw	a5,52(a4)
    80004572:	2785                	addiw	a5,a5,1
    80004574:	db5c                	sw	a5,52(a4)
    80004576:	a835                	j	800045b2 <log_write+0xd0>
    panic("too big a transaction");
    80004578:	00004517          	auipc	a0,0x4
    8000457c:	12850513          	addi	a0,a0,296 # 800086a0 <syscalls+0x1e8>
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	fcc080e7          	jalr	-52(ra) # 8000054c <panic>
    panic("log_write outside of trans");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	13050513          	addi	a0,a0,304 # 800086b8 <syscalls+0x200>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fbc080e7          	jalr	-68(ra) # 8000054c <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004598:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000459a:	00c78693          	addi	a3,a5,12
    8000459e:	068a                	slli	a3,a3,0x2
    800045a0:	0001e717          	auipc	a4,0x1e
    800045a4:	24870713          	addi	a4,a4,584 # 800227e8 <log>
    800045a8:	9736                	add	a4,a4,a3
    800045aa:	44d4                	lw	a3,12(s1)
    800045ac:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ae:	faf608e3          	beq	a2,a5,8000455e <log_write+0x7c>
  }
  release(&log.lock);
    800045b2:	0001e517          	auipc	a0,0x1e
    800045b6:	23650513          	addi	a0,a0,566 # 800227e8 <log>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	7d0080e7          	jalr	2000(ra) # 80000d8a <release>
}
    800045c2:	60e2                	ld	ra,24(sp)
    800045c4:	6442                	ld	s0,16(sp)
    800045c6:	64a2                	ld	s1,8(sp)
    800045c8:	6902                	ld	s2,0(sp)
    800045ca:	6105                	addi	sp,sp,32
    800045cc:	8082                	ret

00000000800045ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045ce:	1101                	addi	sp,sp,-32
    800045d0:	ec06                	sd	ra,24(sp)
    800045d2:	e822                	sd	s0,16(sp)
    800045d4:	e426                	sd	s1,8(sp)
    800045d6:	e04a                	sd	s2,0(sp)
    800045d8:	1000                	addi	s0,sp,32
    800045da:	84aa                	mv	s1,a0
    800045dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045de:	00004597          	auipc	a1,0x4
    800045e2:	0fa58593          	addi	a1,a1,250 # 800086d8 <syscalls+0x220>
    800045e6:	0521                	addi	a0,a0,8
    800045e8:	ffffd097          	auipc	ra,0xffffd
    800045ec:	84e080e7          	jalr	-1970(ra) # 80000e36 <initlock>
  lk->name = name;
    800045f0:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800045f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045f8:	0204a823          	sw	zero,48(s1)
}
    800045fc:	60e2                	ld	ra,24(sp)
    800045fe:	6442                	ld	s0,16(sp)
    80004600:	64a2                	ld	s1,8(sp)
    80004602:	6902                	ld	s2,0(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	e04a                	sd	s2,0(sp)
    80004612:	1000                	addi	s0,sp,32
    80004614:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004616:	00850913          	addi	s2,a0,8
    8000461a:	854a                	mv	a0,s2
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	69e080e7          	jalr	1694(ra) # 80000cba <acquire>
  while (lk->locked) {
    80004624:	409c                	lw	a5,0(s1)
    80004626:	cb89                	beqz	a5,80004638 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004628:	85ca                	mv	a1,s2
    8000462a:	8526                	mv	a0,s1
    8000462c:	ffffe097          	auipc	ra,0xffffe
    80004630:	eec080e7          	jalr	-276(ra) # 80002518 <sleep>
  while (lk->locked) {
    80004634:	409c                	lw	a5,0(s1)
    80004636:	fbed                	bnez	a5,80004628 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004638:	4785                	li	a5,1
    8000463a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000463c:	ffffd097          	auipc	ra,0xffffd
    80004640:	6c4080e7          	jalr	1732(ra) # 80001d00 <myproc>
    80004644:	413c                	lw	a5,64(a0)
    80004646:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    80004648:	854a                	mv	a0,s2
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	740080e7          	jalr	1856(ra) # 80000d8a <release>
}
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6902                	ld	s2,0(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret

000000008000465e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000465e:	1101                	addi	sp,sp,-32
    80004660:	ec06                	sd	ra,24(sp)
    80004662:	e822                	sd	s0,16(sp)
    80004664:	e426                	sd	s1,8(sp)
    80004666:	e04a                	sd	s2,0(sp)
    80004668:	1000                	addi	s0,sp,32
    8000466a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000466c:	00850913          	addi	s2,a0,8
    80004670:	854a                	mv	a0,s2
    80004672:	ffffc097          	auipc	ra,0xffffc
    80004676:	648080e7          	jalr	1608(ra) # 80000cba <acquire>
  lk->locked = 0;
    8000467a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000467e:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004682:	8526                	mv	a0,s1
    80004684:	ffffe097          	auipc	ra,0xffffe
    80004688:	014080e7          	jalr	20(ra) # 80002698 <wakeup>
  release(&lk->lk);
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	6fc080e7          	jalr	1788(ra) # 80000d8a <release>
}
    80004696:	60e2                	ld	ra,24(sp)
    80004698:	6442                	ld	s0,16(sp)
    8000469a:	64a2                	ld	s1,8(sp)
    8000469c:	6902                	ld	s2,0(sp)
    8000469e:	6105                	addi	sp,sp,32
    800046a0:	8082                	ret

00000000800046a2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046a2:	7179                	addi	sp,sp,-48
    800046a4:	f406                	sd	ra,40(sp)
    800046a6:	f022                	sd	s0,32(sp)
    800046a8:	ec26                	sd	s1,24(sp)
    800046aa:	e84a                	sd	s2,16(sp)
    800046ac:	e44e                	sd	s3,8(sp)
    800046ae:	1800                	addi	s0,sp,48
    800046b0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046b2:	00850913          	addi	s2,a0,8
    800046b6:	854a                	mv	a0,s2
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	602080e7          	jalr	1538(ra) # 80000cba <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c0:	409c                	lw	a5,0(s1)
    800046c2:	ef99                	bnez	a5,800046e0 <holdingsleep+0x3e>
    800046c4:	4481                	li	s1,0
  release(&lk->lk);
    800046c6:	854a                	mv	a0,s2
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	6c2080e7          	jalr	1730(ra) # 80000d8a <release>
  return r;
}
    800046d0:	8526                	mv	a0,s1
    800046d2:	70a2                	ld	ra,40(sp)
    800046d4:	7402                	ld	s0,32(sp)
    800046d6:	64e2                	ld	s1,24(sp)
    800046d8:	6942                	ld	s2,16(sp)
    800046da:	69a2                	ld	s3,8(sp)
    800046dc:	6145                	addi	sp,sp,48
    800046de:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046e0:	0304a983          	lw	s3,48(s1)
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	61c080e7          	jalr	1564(ra) # 80001d00 <myproc>
    800046ec:	4124                	lw	s1,64(a0)
    800046ee:	413484b3          	sub	s1,s1,s3
    800046f2:	0014b493          	seqz	s1,s1
    800046f6:	bfc1                	j	800046c6 <holdingsleep+0x24>

00000000800046f8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046f8:	1141                	addi	sp,sp,-16
    800046fa:	e406                	sd	ra,8(sp)
    800046fc:	e022                	sd	s0,0(sp)
    800046fe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004700:	00004597          	auipc	a1,0x4
    80004704:	fe858593          	addi	a1,a1,-24 # 800086e8 <syscalls+0x230>
    80004708:	0001e517          	auipc	a0,0x1e
    8000470c:	23050513          	addi	a0,a0,560 # 80022938 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	726080e7          	jalr	1830(ra) # 80000e36 <initlock>
}
    80004718:	60a2                	ld	ra,8(sp)
    8000471a:	6402                	ld	s0,0(sp)
    8000471c:	0141                	addi	sp,sp,16
    8000471e:	8082                	ret

0000000080004720 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004720:	1101                	addi	sp,sp,-32
    80004722:	ec06                	sd	ra,24(sp)
    80004724:	e822                	sd	s0,16(sp)
    80004726:	e426                	sd	s1,8(sp)
    80004728:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000472a:	0001e517          	auipc	a0,0x1e
    8000472e:	20e50513          	addi	a0,a0,526 # 80022938 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	588080e7          	jalr	1416(ra) # 80000cba <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000473a:	0001e497          	auipc	s1,0x1e
    8000473e:	21e48493          	addi	s1,s1,542 # 80022958 <ftable+0x20>
    80004742:	0001f717          	auipc	a4,0x1f
    80004746:	1b670713          	addi	a4,a4,438 # 800238f8 <ftable+0xfc0>
    if(f->ref == 0){
    8000474a:	40dc                	lw	a5,4(s1)
    8000474c:	cf99                	beqz	a5,8000476a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000474e:	02848493          	addi	s1,s1,40
    80004752:	fee49ce3          	bne	s1,a4,8000474a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004756:	0001e517          	auipc	a0,0x1e
    8000475a:	1e250513          	addi	a0,a0,482 # 80022938 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	62c080e7          	jalr	1580(ra) # 80000d8a <release>
  return 0;
    80004766:	4481                	li	s1,0
    80004768:	a819                	j	8000477e <filealloc+0x5e>
      f->ref = 1;
    8000476a:	4785                	li	a5,1
    8000476c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000476e:	0001e517          	auipc	a0,0x1e
    80004772:	1ca50513          	addi	a0,a0,458 # 80022938 <ftable>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	614080e7          	jalr	1556(ra) # 80000d8a <release>
}
    8000477e:	8526                	mv	a0,s1
    80004780:	60e2                	ld	ra,24(sp)
    80004782:	6442                	ld	s0,16(sp)
    80004784:	64a2                	ld	s1,8(sp)
    80004786:	6105                	addi	sp,sp,32
    80004788:	8082                	ret

000000008000478a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	1000                	addi	s0,sp,32
    80004794:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004796:	0001e517          	auipc	a0,0x1e
    8000479a:	1a250513          	addi	a0,a0,418 # 80022938 <ftable>
    8000479e:	ffffc097          	auipc	ra,0xffffc
    800047a2:	51c080e7          	jalr	1308(ra) # 80000cba <acquire>
  if(f->ref < 1)
    800047a6:	40dc                	lw	a5,4(s1)
    800047a8:	02f05263          	blez	a5,800047cc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047ac:	2785                	addiw	a5,a5,1
    800047ae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047b0:	0001e517          	auipc	a0,0x1e
    800047b4:	18850513          	addi	a0,a0,392 # 80022938 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	5d2080e7          	jalr	1490(ra) # 80000d8a <release>
  return f;
}
    800047c0:	8526                	mv	a0,s1
    800047c2:	60e2                	ld	ra,24(sp)
    800047c4:	6442                	ld	s0,16(sp)
    800047c6:	64a2                	ld	s1,8(sp)
    800047c8:	6105                	addi	sp,sp,32
    800047ca:	8082                	ret
    panic("filedup");
    800047cc:	00004517          	auipc	a0,0x4
    800047d0:	f2450513          	addi	a0,a0,-220 # 800086f0 <syscalls+0x238>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	d78080e7          	jalr	-648(ra) # 8000054c <panic>

00000000800047dc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047dc:	7139                	addi	sp,sp,-64
    800047de:	fc06                	sd	ra,56(sp)
    800047e0:	f822                	sd	s0,48(sp)
    800047e2:	f426                	sd	s1,40(sp)
    800047e4:	f04a                	sd	s2,32(sp)
    800047e6:	ec4e                	sd	s3,24(sp)
    800047e8:	e852                	sd	s4,16(sp)
    800047ea:	e456                	sd	s5,8(sp)
    800047ec:	0080                	addi	s0,sp,64
    800047ee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047f0:	0001e517          	auipc	a0,0x1e
    800047f4:	14850513          	addi	a0,a0,328 # 80022938 <ftable>
    800047f8:	ffffc097          	auipc	ra,0xffffc
    800047fc:	4c2080e7          	jalr	1218(ra) # 80000cba <acquire>
  if(f->ref < 1)
    80004800:	40dc                	lw	a5,4(s1)
    80004802:	06f05163          	blez	a5,80004864 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004806:	37fd                	addiw	a5,a5,-1
    80004808:	0007871b          	sext.w	a4,a5
    8000480c:	c0dc                	sw	a5,4(s1)
    8000480e:	06e04363          	bgtz	a4,80004874 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004812:	0004a903          	lw	s2,0(s1)
    80004816:	0094ca83          	lbu	s5,9(s1)
    8000481a:	0104ba03          	ld	s4,16(s1)
    8000481e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004822:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004826:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000482a:	0001e517          	auipc	a0,0x1e
    8000482e:	10e50513          	addi	a0,a0,270 # 80022938 <ftable>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	558080e7          	jalr	1368(ra) # 80000d8a <release>

  if(ff.type == FD_PIPE){
    8000483a:	4785                	li	a5,1
    8000483c:	04f90d63          	beq	s2,a5,80004896 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004840:	3979                	addiw	s2,s2,-2
    80004842:	4785                	li	a5,1
    80004844:	0527e063          	bltu	a5,s2,80004884 <fileclose+0xa8>
    begin_op();
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	ac4080e7          	jalr	-1340(ra) # 8000430c <begin_op>
    iput(ff.ip);
    80004850:	854e                	mv	a0,s3
    80004852:	fffff097          	auipc	ra,0xfffff
    80004856:	29a080e7          	jalr	666(ra) # 80003aec <iput>
    end_op();
    8000485a:	00000097          	auipc	ra,0x0
    8000485e:	b30080e7          	jalr	-1232(ra) # 8000438a <end_op>
    80004862:	a00d                	j	80004884 <fileclose+0xa8>
    panic("fileclose");
    80004864:	00004517          	auipc	a0,0x4
    80004868:	e9450513          	addi	a0,a0,-364 # 800086f8 <syscalls+0x240>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	ce0080e7          	jalr	-800(ra) # 8000054c <panic>
    release(&ftable.lock);
    80004874:	0001e517          	auipc	a0,0x1e
    80004878:	0c450513          	addi	a0,a0,196 # 80022938 <ftable>
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	50e080e7          	jalr	1294(ra) # 80000d8a <release>
  }
}
    80004884:	70e2                	ld	ra,56(sp)
    80004886:	7442                	ld	s0,48(sp)
    80004888:	74a2                	ld	s1,40(sp)
    8000488a:	7902                	ld	s2,32(sp)
    8000488c:	69e2                	ld	s3,24(sp)
    8000488e:	6a42                	ld	s4,16(sp)
    80004890:	6aa2                	ld	s5,8(sp)
    80004892:	6121                	addi	sp,sp,64
    80004894:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004896:	85d6                	mv	a1,s5
    80004898:	8552                	mv	a0,s4
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	372080e7          	jalr	882(ra) # 80004c0c <pipeclose>
    800048a2:	b7cd                	j	80004884 <fileclose+0xa8>

00000000800048a4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048a4:	715d                	addi	sp,sp,-80
    800048a6:	e486                	sd	ra,72(sp)
    800048a8:	e0a2                	sd	s0,64(sp)
    800048aa:	fc26                	sd	s1,56(sp)
    800048ac:	f84a                	sd	s2,48(sp)
    800048ae:	f44e                	sd	s3,40(sp)
    800048b0:	0880                	addi	s0,sp,80
    800048b2:	84aa                	mv	s1,a0
    800048b4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048b6:	ffffd097          	auipc	ra,0xffffd
    800048ba:	44a080e7          	jalr	1098(ra) # 80001d00 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048be:	409c                	lw	a5,0(s1)
    800048c0:	37f9                	addiw	a5,a5,-2
    800048c2:	4705                	li	a4,1
    800048c4:	04f76763          	bltu	a4,a5,80004912 <filestat+0x6e>
    800048c8:	892a                	mv	s2,a0
    ilock(f->ip);
    800048ca:	6c88                	ld	a0,24(s1)
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	066080e7          	jalr	102(ra) # 80003932 <ilock>
    stati(f->ip, &st);
    800048d4:	fb840593          	addi	a1,s0,-72
    800048d8:	6c88                	ld	a0,24(s1)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	2e2080e7          	jalr	738(ra) # 80003bbc <stati>
    iunlock(f->ip);
    800048e2:	6c88                	ld	a0,24(s1)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	110080e7          	jalr	272(ra) # 800039f4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048ec:	46e1                	li	a3,24
    800048ee:	fb840613          	addi	a2,s0,-72
    800048f2:	85ce                	mv	a1,s3
    800048f4:	05893503          	ld	a0,88(s2)
    800048f8:	ffffd097          	auipc	ra,0xffffd
    800048fc:	0fe080e7          	jalr	254(ra) # 800019f6 <copyout>
    80004900:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004904:	60a6                	ld	ra,72(sp)
    80004906:	6406                	ld	s0,64(sp)
    80004908:	74e2                	ld	s1,56(sp)
    8000490a:	7942                	ld	s2,48(sp)
    8000490c:	79a2                	ld	s3,40(sp)
    8000490e:	6161                	addi	sp,sp,80
    80004910:	8082                	ret
  return -1;
    80004912:	557d                	li	a0,-1
    80004914:	bfc5                	j	80004904 <filestat+0x60>

0000000080004916 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004916:	7179                	addi	sp,sp,-48
    80004918:	f406                	sd	ra,40(sp)
    8000491a:	f022                	sd	s0,32(sp)
    8000491c:	ec26                	sd	s1,24(sp)
    8000491e:	e84a                	sd	s2,16(sp)
    80004920:	e44e                	sd	s3,8(sp)
    80004922:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004924:	00854783          	lbu	a5,8(a0)
    80004928:	c3d5                	beqz	a5,800049cc <fileread+0xb6>
    8000492a:	84aa                	mv	s1,a0
    8000492c:	89ae                	mv	s3,a1
    8000492e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004930:	411c                	lw	a5,0(a0)
    80004932:	4705                	li	a4,1
    80004934:	04e78963          	beq	a5,a4,80004986 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004938:	470d                	li	a4,3
    8000493a:	04e78d63          	beq	a5,a4,80004994 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000493e:	4709                	li	a4,2
    80004940:	06e79e63          	bne	a5,a4,800049bc <fileread+0xa6>
    ilock(f->ip);
    80004944:	6d08                	ld	a0,24(a0)
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	fec080e7          	jalr	-20(ra) # 80003932 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000494e:	874a                	mv	a4,s2
    80004950:	5094                	lw	a3,32(s1)
    80004952:	864e                	mv	a2,s3
    80004954:	4585                	li	a1,1
    80004956:	6c88                	ld	a0,24(s1)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	28e080e7          	jalr	654(ra) # 80003be6 <readi>
    80004960:	892a                	mv	s2,a0
    80004962:	00a05563          	blez	a0,8000496c <fileread+0x56>
      f->off += r;
    80004966:	509c                	lw	a5,32(s1)
    80004968:	9fa9                	addw	a5,a5,a0
    8000496a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000496c:	6c88                	ld	a0,24(s1)
    8000496e:	fffff097          	auipc	ra,0xfffff
    80004972:	086080e7          	jalr	134(ra) # 800039f4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004976:	854a                	mv	a0,s2
    80004978:	70a2                	ld	ra,40(sp)
    8000497a:	7402                	ld	s0,32(sp)
    8000497c:	64e2                	ld	s1,24(sp)
    8000497e:	6942                	ld	s2,16(sp)
    80004980:	69a2                	ld	s3,8(sp)
    80004982:	6145                	addi	sp,sp,48
    80004984:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004986:	6908                	ld	a0,16(a0)
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	400080e7          	jalr	1024(ra) # 80004d88 <piperead>
    80004990:	892a                	mv	s2,a0
    80004992:	b7d5                	j	80004976 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004994:	02451783          	lh	a5,36(a0)
    80004998:	03079693          	slli	a3,a5,0x30
    8000499c:	92c1                	srli	a3,a3,0x30
    8000499e:	4725                	li	a4,9
    800049a0:	02d76863          	bltu	a4,a3,800049d0 <fileread+0xba>
    800049a4:	0792                	slli	a5,a5,0x4
    800049a6:	0001e717          	auipc	a4,0x1e
    800049aa:	ef270713          	addi	a4,a4,-270 # 80022898 <devsw>
    800049ae:	97ba                	add	a5,a5,a4
    800049b0:	639c                	ld	a5,0(a5)
    800049b2:	c38d                	beqz	a5,800049d4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049b4:	4505                	li	a0,1
    800049b6:	9782                	jalr	a5
    800049b8:	892a                	mv	s2,a0
    800049ba:	bf75                	j	80004976 <fileread+0x60>
    panic("fileread");
    800049bc:	00004517          	auipc	a0,0x4
    800049c0:	d4c50513          	addi	a0,a0,-692 # 80008708 <syscalls+0x250>
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	b88080e7          	jalr	-1144(ra) # 8000054c <panic>
    return -1;
    800049cc:	597d                	li	s2,-1
    800049ce:	b765                	j	80004976 <fileread+0x60>
      return -1;
    800049d0:	597d                	li	s2,-1
    800049d2:	b755                	j	80004976 <fileread+0x60>
    800049d4:	597d                	li	s2,-1
    800049d6:	b745                	j	80004976 <fileread+0x60>

00000000800049d8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049d8:	00954783          	lbu	a5,9(a0)
    800049dc:	14078563          	beqz	a5,80004b26 <filewrite+0x14e>
{
    800049e0:	715d                	addi	sp,sp,-80
    800049e2:	e486                	sd	ra,72(sp)
    800049e4:	e0a2                	sd	s0,64(sp)
    800049e6:	fc26                	sd	s1,56(sp)
    800049e8:	f84a                	sd	s2,48(sp)
    800049ea:	f44e                	sd	s3,40(sp)
    800049ec:	f052                	sd	s4,32(sp)
    800049ee:	ec56                	sd	s5,24(sp)
    800049f0:	e85a                	sd	s6,16(sp)
    800049f2:	e45e                	sd	s7,8(sp)
    800049f4:	e062                	sd	s8,0(sp)
    800049f6:	0880                	addi	s0,sp,80
    800049f8:	892a                	mv	s2,a0
    800049fa:	8b2e                	mv	s6,a1
    800049fc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049fe:	411c                	lw	a5,0(a0)
    80004a00:	4705                	li	a4,1
    80004a02:	02e78263          	beq	a5,a4,80004a26 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a06:	470d                	li	a4,3
    80004a08:	02e78563          	beq	a5,a4,80004a32 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a0c:	4709                	li	a4,2
    80004a0e:	10e79463          	bne	a5,a4,80004b16 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a12:	0ec05e63          	blez	a2,80004b0e <filewrite+0x136>
    int i = 0;
    80004a16:	4981                	li	s3,0
    80004a18:	6b85                	lui	s7,0x1
    80004a1a:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a1e:	6c05                	lui	s8,0x1
    80004a20:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004a24:	a851                	j	80004ab8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a26:	6908                	ld	a0,16(a0)
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	25e080e7          	jalr	606(ra) # 80004c86 <pipewrite>
    80004a30:	a85d                	j	80004ae6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a32:	02451783          	lh	a5,36(a0)
    80004a36:	03079693          	slli	a3,a5,0x30
    80004a3a:	92c1                	srli	a3,a3,0x30
    80004a3c:	4725                	li	a4,9
    80004a3e:	0ed76663          	bltu	a4,a3,80004b2a <filewrite+0x152>
    80004a42:	0792                	slli	a5,a5,0x4
    80004a44:	0001e717          	auipc	a4,0x1e
    80004a48:	e5470713          	addi	a4,a4,-428 # 80022898 <devsw>
    80004a4c:	97ba                	add	a5,a5,a4
    80004a4e:	679c                	ld	a5,8(a5)
    80004a50:	cff9                	beqz	a5,80004b2e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a52:	4505                	li	a0,1
    80004a54:	9782                	jalr	a5
    80004a56:	a841                	j	80004ae6 <filewrite+0x10e>
    80004a58:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a5c:	00000097          	auipc	ra,0x0
    80004a60:	8b0080e7          	jalr	-1872(ra) # 8000430c <begin_op>
      ilock(f->ip);
    80004a64:	01893503          	ld	a0,24(s2)
    80004a68:	fffff097          	auipc	ra,0xfffff
    80004a6c:	eca080e7          	jalr	-310(ra) # 80003932 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a70:	8756                	mv	a4,s5
    80004a72:	02092683          	lw	a3,32(s2)
    80004a76:	01698633          	add	a2,s3,s6
    80004a7a:	4585                	li	a1,1
    80004a7c:	01893503          	ld	a0,24(s2)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	25e080e7          	jalr	606(ra) # 80003cde <writei>
    80004a88:	84aa                	mv	s1,a0
    80004a8a:	02a05f63          	blez	a0,80004ac8 <filewrite+0xf0>
        f->off += r;
    80004a8e:	02092783          	lw	a5,32(s2)
    80004a92:	9fa9                	addw	a5,a5,a0
    80004a94:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a98:	01893503          	ld	a0,24(s2)
    80004a9c:	fffff097          	auipc	ra,0xfffff
    80004aa0:	f58080e7          	jalr	-168(ra) # 800039f4 <iunlock>
      end_op();
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	8e6080e7          	jalr	-1818(ra) # 8000438a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004aac:	049a9963          	bne	s5,s1,80004afe <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004ab0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ab4:	0349d663          	bge	s3,s4,80004ae0 <filewrite+0x108>
      int n1 = n - i;
    80004ab8:	413a04bb          	subw	s1,s4,s3
    80004abc:	0004879b          	sext.w	a5,s1
    80004ac0:	f8fbdce3          	bge	s7,a5,80004a58 <filewrite+0x80>
    80004ac4:	84e2                	mv	s1,s8
    80004ac6:	bf49                	j	80004a58 <filewrite+0x80>
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f28080e7          	jalr	-216(ra) # 800039f4 <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8b6080e7          	jalr	-1866(ra) # 8000438a <end_op>
      if(r < 0)
    80004adc:	fc04d8e3          	bgez	s1,80004aac <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004ae0:	8552                	mv	a0,s4
    80004ae2:	033a1863          	bne	s4,s3,80004b12 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ae6:	60a6                	ld	ra,72(sp)
    80004ae8:	6406                	ld	s0,64(sp)
    80004aea:	74e2                	ld	s1,56(sp)
    80004aec:	7942                	ld	s2,48(sp)
    80004aee:	79a2                	ld	s3,40(sp)
    80004af0:	7a02                	ld	s4,32(sp)
    80004af2:	6ae2                	ld	s5,24(sp)
    80004af4:	6b42                	ld	s6,16(sp)
    80004af6:	6ba2                	ld	s7,8(sp)
    80004af8:	6c02                	ld	s8,0(sp)
    80004afa:	6161                	addi	sp,sp,80
    80004afc:	8082                	ret
        panic("short filewrite");
    80004afe:	00004517          	auipc	a0,0x4
    80004b02:	c1a50513          	addi	a0,a0,-998 # 80008718 <syscalls+0x260>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	a46080e7          	jalr	-1466(ra) # 8000054c <panic>
    int i = 0;
    80004b0e:	4981                	li	s3,0
    80004b10:	bfc1                	j	80004ae0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b12:	557d                	li	a0,-1
    80004b14:	bfc9                	j	80004ae6 <filewrite+0x10e>
    panic("filewrite");
    80004b16:	00004517          	auipc	a0,0x4
    80004b1a:	c1250513          	addi	a0,a0,-1006 # 80008728 <syscalls+0x270>
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	a2e080e7          	jalr	-1490(ra) # 8000054c <panic>
    return -1;
    80004b26:	557d                	li	a0,-1
}
    80004b28:	8082                	ret
      return -1;
    80004b2a:	557d                	li	a0,-1
    80004b2c:	bf6d                	j	80004ae6 <filewrite+0x10e>
    80004b2e:	557d                	li	a0,-1
    80004b30:	bf5d                	j	80004ae6 <filewrite+0x10e>

0000000080004b32 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b32:	7179                	addi	sp,sp,-48
    80004b34:	f406                	sd	ra,40(sp)
    80004b36:	f022                	sd	s0,32(sp)
    80004b38:	ec26                	sd	s1,24(sp)
    80004b3a:	e84a                	sd	s2,16(sp)
    80004b3c:	e44e                	sd	s3,8(sp)
    80004b3e:	e052                	sd	s4,0(sp)
    80004b40:	1800                	addi	s0,sp,48
    80004b42:	84aa                	mv	s1,a0
    80004b44:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b46:	0005b023          	sd	zero,0(a1)
    80004b4a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	bd2080e7          	jalr	-1070(ra) # 80004720 <filealloc>
    80004b56:	e088                	sd	a0,0(s1)
    80004b58:	c551                	beqz	a0,80004be4 <pipealloc+0xb2>
    80004b5a:	00000097          	auipc	ra,0x0
    80004b5e:	bc6080e7          	jalr	-1082(ra) # 80004720 <filealloc>
    80004b62:	00aa3023          	sd	a0,0(s4)
    80004b66:	c92d                	beqz	a0,80004bd8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	ff0080e7          	jalr	-16(ra) # 80000b58 <kalloc>
    80004b70:	892a                	mv	s2,a0
    80004b72:	c125                	beqz	a0,80004bd2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b74:	4985                	li	s3,1
    80004b76:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004b7a:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004b7e:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004b82:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004b86:	00004597          	auipc	a1,0x4
    80004b8a:	bb258593          	addi	a1,a1,-1102 # 80008738 <syscalls+0x280>
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	2a8080e7          	jalr	680(ra) # 80000e36 <initlock>
  (*f0)->type = FD_PIPE;
    80004b96:	609c                	ld	a5,0(s1)
    80004b98:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b9c:	609c                	ld	a5,0(s1)
    80004b9e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ba2:	609c                	ld	a5,0(s1)
    80004ba4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ba8:	609c                	ld	a5,0(s1)
    80004baa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bae:	000a3783          	ld	a5,0(s4)
    80004bb2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bb6:	000a3783          	ld	a5,0(s4)
    80004bba:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bbe:	000a3783          	ld	a5,0(s4)
    80004bc2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bc6:	000a3783          	ld	a5,0(s4)
    80004bca:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bce:	4501                	li	a0,0
    80004bd0:	a025                	j	80004bf8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bd2:	6088                	ld	a0,0(s1)
    80004bd4:	e501                	bnez	a0,80004bdc <pipealloc+0xaa>
    80004bd6:	a039                	j	80004be4 <pipealloc+0xb2>
    80004bd8:	6088                	ld	a0,0(s1)
    80004bda:	c51d                	beqz	a0,80004c08 <pipealloc+0xd6>
    fileclose(*f0);
    80004bdc:	00000097          	auipc	ra,0x0
    80004be0:	c00080e7          	jalr	-1024(ra) # 800047dc <fileclose>
  if(*f1)
    80004be4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004be8:	557d                	li	a0,-1
  if(*f1)
    80004bea:	c799                	beqz	a5,80004bf8 <pipealloc+0xc6>
    fileclose(*f1);
    80004bec:	853e                	mv	a0,a5
    80004bee:	00000097          	auipc	ra,0x0
    80004bf2:	bee080e7          	jalr	-1042(ra) # 800047dc <fileclose>
  return -1;
    80004bf6:	557d                	li	a0,-1
}
    80004bf8:	70a2                	ld	ra,40(sp)
    80004bfa:	7402                	ld	s0,32(sp)
    80004bfc:	64e2                	ld	s1,24(sp)
    80004bfe:	6942                	ld	s2,16(sp)
    80004c00:	69a2                	ld	s3,8(sp)
    80004c02:	6a02                	ld	s4,0(sp)
    80004c04:	6145                	addi	sp,sp,48
    80004c06:	8082                	ret
  return -1;
    80004c08:	557d                	li	a0,-1
    80004c0a:	b7fd                	j	80004bf8 <pipealloc+0xc6>

0000000080004c0c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c0c:	1101                	addi	sp,sp,-32
    80004c0e:	ec06                	sd	ra,24(sp)
    80004c10:	e822                	sd	s0,16(sp)
    80004c12:	e426                	sd	s1,8(sp)
    80004c14:	e04a                	sd	s2,0(sp)
    80004c16:	1000                	addi	s0,sp,32
    80004c18:	84aa                	mv	s1,a0
    80004c1a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	09e080e7          	jalr	158(ra) # 80000cba <acquire>
  if(writable){
    80004c24:	04090263          	beqz	s2,80004c68 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004c28:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004c2c:	22048513          	addi	a0,s1,544
    80004c30:	ffffe097          	auipc	ra,0xffffe
    80004c34:	a68080e7          	jalr	-1432(ra) # 80002698 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c38:	2284b783          	ld	a5,552(s1)
    80004c3c:	ef9d                	bnez	a5,80004c7a <pipeclose+0x6e>
    release(&pi->lock);
    80004c3e:	8526                	mv	a0,s1
    80004c40:	ffffc097          	auipc	ra,0xffffc
    80004c44:	14a080e7          	jalr	330(ra) # 80000d8a <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	188080e7          	jalr	392(ra) # 80000dd2 <freelock>
#endif    
    kfree((char*)pi);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	dc4080e7          	jalr	-572(ra) # 80000a18 <kfree>
  } else
    release(&pi->lock);
}
    80004c5c:	60e2                	ld	ra,24(sp)
    80004c5e:	6442                	ld	s0,16(sp)
    80004c60:	64a2                	ld	s1,8(sp)
    80004c62:	6902                	ld	s2,0(sp)
    80004c64:	6105                	addi	sp,sp,32
    80004c66:	8082                	ret
    pi->readopen = 0;
    80004c68:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004c6c:	22448513          	addi	a0,s1,548
    80004c70:	ffffe097          	auipc	ra,0xffffe
    80004c74:	a28080e7          	jalr	-1496(ra) # 80002698 <wakeup>
    80004c78:	b7c1                	j	80004c38 <pipeclose+0x2c>
    release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	10e080e7          	jalr	270(ra) # 80000d8a <release>
}
    80004c84:	bfe1                	j	80004c5c <pipeclose+0x50>

0000000080004c86 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c86:	711d                	addi	sp,sp,-96
    80004c88:	ec86                	sd	ra,88(sp)
    80004c8a:	e8a2                	sd	s0,80(sp)
    80004c8c:	e4a6                	sd	s1,72(sp)
    80004c8e:	e0ca                	sd	s2,64(sp)
    80004c90:	fc4e                	sd	s3,56(sp)
    80004c92:	f852                	sd	s4,48(sp)
    80004c94:	f456                	sd	s5,40(sp)
    80004c96:	f05a                	sd	s6,32(sp)
    80004c98:	ec5e                	sd	s7,24(sp)
    80004c9a:	e862                	sd	s8,16(sp)
    80004c9c:	1080                	addi	s0,sp,96
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	8b2e                	mv	s6,a1
    80004ca2:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	05c080e7          	jalr	92(ra) # 80001d00 <myproc>
    80004cac:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004cae:	8526                	mv	a0,s1
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	00a080e7          	jalr	10(ra) # 80000cba <acquire>
  for(i = 0; i < n; i++){
    80004cb8:	09505863          	blez	s5,80004d48 <pipewrite+0xc2>
    80004cbc:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cbe:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004cc2:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cc6:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cc8:	2204a783          	lw	a5,544(s1)
    80004ccc:	2244a703          	lw	a4,548(s1)
    80004cd0:	2007879b          	addiw	a5,a5,512
    80004cd4:	02f71b63          	bne	a4,a5,80004d0a <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004cd8:	2284a783          	lw	a5,552(s1)
    80004cdc:	c3d9                	beqz	a5,80004d62 <pipewrite+0xdc>
    80004cde:	03892783          	lw	a5,56(s2)
    80004ce2:	e3c1                	bnez	a5,80004d62 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004ce4:	8552                	mv	a0,s4
    80004ce6:	ffffe097          	auipc	ra,0xffffe
    80004cea:	9b2080e7          	jalr	-1614(ra) # 80002698 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cee:	85a6                	mv	a1,s1
    80004cf0:	854e                	mv	a0,s3
    80004cf2:	ffffe097          	auipc	ra,0xffffe
    80004cf6:	826080e7          	jalr	-2010(ra) # 80002518 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cfa:	2204a783          	lw	a5,544(s1)
    80004cfe:	2244a703          	lw	a4,548(s1)
    80004d02:	2007879b          	addiw	a5,a5,512
    80004d06:	fcf709e3          	beq	a4,a5,80004cd8 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d0a:	4685                	li	a3,1
    80004d0c:	865a                	mv	a2,s6
    80004d0e:	faf40593          	addi	a1,s0,-81
    80004d12:	05893503          	ld	a0,88(s2)
    80004d16:	ffffd097          	auipc	ra,0xffffd
    80004d1a:	d6c080e7          	jalr	-660(ra) # 80001a82 <copyin>
    80004d1e:	03850663          	beq	a0,s8,80004d4a <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d22:	2244a783          	lw	a5,548(s1)
    80004d26:	0017871b          	addiw	a4,a5,1
    80004d2a:	22e4a223          	sw	a4,548(s1)
    80004d2e:	1ff7f793          	andi	a5,a5,511
    80004d32:	97a6                	add	a5,a5,s1
    80004d34:	faf44703          	lbu	a4,-81(s0)
    80004d38:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004d3c:	2b85                	addiw	s7,s7,1
    80004d3e:	0b05                	addi	s6,s6,1
    80004d40:	f97a94e3          	bne	s5,s7,80004cc8 <pipewrite+0x42>
    80004d44:	8bd6                	mv	s7,s5
    80004d46:	a011                	j	80004d4a <pipewrite+0xc4>
    80004d48:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d4a:	22048513          	addi	a0,s1,544
    80004d4e:	ffffe097          	auipc	ra,0xffffe
    80004d52:	94a080e7          	jalr	-1718(ra) # 80002698 <wakeup>
  release(&pi->lock);
    80004d56:	8526                	mv	a0,s1
    80004d58:	ffffc097          	auipc	ra,0xffffc
    80004d5c:	032080e7          	jalr	50(ra) # 80000d8a <release>
  return i;
    80004d60:	a039                	j	80004d6e <pipewrite+0xe8>
        release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	026080e7          	jalr	38(ra) # 80000d8a <release>
        return -1;
    80004d6c:	5bfd                	li	s7,-1
}
    80004d6e:	855e                	mv	a0,s7
    80004d70:	60e6                	ld	ra,88(sp)
    80004d72:	6446                	ld	s0,80(sp)
    80004d74:	64a6                	ld	s1,72(sp)
    80004d76:	6906                	ld	s2,64(sp)
    80004d78:	79e2                	ld	s3,56(sp)
    80004d7a:	7a42                	ld	s4,48(sp)
    80004d7c:	7aa2                	ld	s5,40(sp)
    80004d7e:	7b02                	ld	s6,32(sp)
    80004d80:	6be2                	ld	s7,24(sp)
    80004d82:	6c42                	ld	s8,16(sp)
    80004d84:	6125                	addi	sp,sp,96
    80004d86:	8082                	ret

0000000080004d88 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d88:	715d                	addi	sp,sp,-80
    80004d8a:	e486                	sd	ra,72(sp)
    80004d8c:	e0a2                	sd	s0,64(sp)
    80004d8e:	fc26                	sd	s1,56(sp)
    80004d90:	f84a                	sd	s2,48(sp)
    80004d92:	f44e                	sd	s3,40(sp)
    80004d94:	f052                	sd	s4,32(sp)
    80004d96:	ec56                	sd	s5,24(sp)
    80004d98:	e85a                	sd	s6,16(sp)
    80004d9a:	0880                	addi	s0,sp,80
    80004d9c:	84aa                	mv	s1,a0
    80004d9e:	892e                	mv	s2,a1
    80004da0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004da2:	ffffd097          	auipc	ra,0xffffd
    80004da6:	f5e080e7          	jalr	-162(ra) # 80001d00 <myproc>
    80004daa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004dac:	8526                	mv	a0,s1
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	f0c080e7          	jalr	-244(ra) # 80000cba <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db6:	2204a703          	lw	a4,544(s1)
    80004dba:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dbe:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc2:	02f71463          	bne	a4,a5,80004dea <piperead+0x62>
    80004dc6:	22c4a783          	lw	a5,556(s1)
    80004dca:	c385                	beqz	a5,80004dea <piperead+0x62>
    if(pr->killed){
    80004dcc:	038a2783          	lw	a5,56(s4)
    80004dd0:	ebc9                	bnez	a5,80004e62 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd2:	85a6                	mv	a1,s1
    80004dd4:	854e                	mv	a0,s3
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	742080e7          	jalr	1858(ra) # 80002518 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dde:	2204a703          	lw	a4,544(s1)
    80004de2:	2244a783          	lw	a5,548(s1)
    80004de6:	fef700e3          	beq	a4,a5,80004dc6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dea:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dec:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dee:	05505463          	blez	s5,80004e36 <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004df2:	2204a783          	lw	a5,544(s1)
    80004df6:	2244a703          	lw	a4,548(s1)
    80004dfa:	02f70e63          	beq	a4,a5,80004e36 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dfe:	0017871b          	addiw	a4,a5,1
    80004e02:	22e4a023          	sw	a4,544(s1)
    80004e06:	1ff7f793          	andi	a5,a5,511
    80004e0a:	97a6                	add	a5,a5,s1
    80004e0c:	0207c783          	lbu	a5,32(a5)
    80004e10:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e14:	4685                	li	a3,1
    80004e16:	fbf40613          	addi	a2,s0,-65
    80004e1a:	85ca                	mv	a1,s2
    80004e1c:	058a3503          	ld	a0,88(s4)
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	bd6080e7          	jalr	-1066(ra) # 800019f6 <copyout>
    80004e28:	01650763          	beq	a0,s6,80004e36 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e2c:	2985                	addiw	s3,s3,1
    80004e2e:	0905                	addi	s2,s2,1
    80004e30:	fd3a91e3          	bne	s5,s3,80004df2 <piperead+0x6a>
    80004e34:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e36:	22448513          	addi	a0,s1,548
    80004e3a:	ffffe097          	auipc	ra,0xffffe
    80004e3e:	85e080e7          	jalr	-1954(ra) # 80002698 <wakeup>
  release(&pi->lock);
    80004e42:	8526                	mv	a0,s1
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	f46080e7          	jalr	-186(ra) # 80000d8a <release>
  return i;
}
    80004e4c:	854e                	mv	a0,s3
    80004e4e:	60a6                	ld	ra,72(sp)
    80004e50:	6406                	ld	s0,64(sp)
    80004e52:	74e2                	ld	s1,56(sp)
    80004e54:	7942                	ld	s2,48(sp)
    80004e56:	79a2                	ld	s3,40(sp)
    80004e58:	7a02                	ld	s4,32(sp)
    80004e5a:	6ae2                	ld	s5,24(sp)
    80004e5c:	6b42                	ld	s6,16(sp)
    80004e5e:	6161                	addi	sp,sp,80
    80004e60:	8082                	ret
      release(&pi->lock);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	f26080e7          	jalr	-218(ra) # 80000d8a <release>
      return -1;
    80004e6c:	59fd                	li	s3,-1
    80004e6e:	bff9                	j	80004e4c <piperead+0xc4>

0000000080004e70 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e70:	de010113          	addi	sp,sp,-544
    80004e74:	20113c23          	sd	ra,536(sp)
    80004e78:	20813823          	sd	s0,528(sp)
    80004e7c:	20913423          	sd	s1,520(sp)
    80004e80:	21213023          	sd	s2,512(sp)
    80004e84:	ffce                	sd	s3,504(sp)
    80004e86:	fbd2                	sd	s4,496(sp)
    80004e88:	f7d6                	sd	s5,488(sp)
    80004e8a:	f3da                	sd	s6,480(sp)
    80004e8c:	efde                	sd	s7,472(sp)
    80004e8e:	ebe2                	sd	s8,464(sp)
    80004e90:	e7e6                	sd	s9,456(sp)
    80004e92:	e3ea                	sd	s10,448(sp)
    80004e94:	ff6e                	sd	s11,440(sp)
    80004e96:	1400                	addi	s0,sp,544
    80004e98:	892a                	mv	s2,a0
    80004e9a:	dea43423          	sd	a0,-536(s0)
    80004e9e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	e5e080e7          	jalr	-418(ra) # 80001d00 <myproc>
    80004eaa:	84aa                	mv	s1,a0

  begin_op();
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	460080e7          	jalr	1120(ra) # 8000430c <begin_op>

  if((ip = namei(path)) == 0){
    80004eb4:	854a                	mv	a0,s2
    80004eb6:	fffff097          	auipc	ra,0xfffff
    80004eba:	236080e7          	jalr	566(ra) # 800040ec <namei>
    80004ebe:	c93d                	beqz	a0,80004f34 <exec+0xc4>
    80004ec0:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ec2:	fffff097          	auipc	ra,0xfffff
    80004ec6:	a70080e7          	jalr	-1424(ra) # 80003932 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004eca:	04000713          	li	a4,64
    80004ece:	4681                	li	a3,0
    80004ed0:	e4840613          	addi	a2,s0,-440
    80004ed4:	4581                	li	a1,0
    80004ed6:	8556                	mv	a0,s5
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	d0e080e7          	jalr	-754(ra) # 80003be6 <readi>
    80004ee0:	04000793          	li	a5,64
    80004ee4:	00f51a63          	bne	a0,a5,80004ef8 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ee8:	e4842703          	lw	a4,-440(s0)
    80004eec:	464c47b7          	lui	a5,0x464c4
    80004ef0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ef4:	04f70663          	beq	a4,a5,80004f40 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ef8:	8556                	mv	a0,s5
    80004efa:	fffff097          	auipc	ra,0xfffff
    80004efe:	c9a080e7          	jalr	-870(ra) # 80003b94 <iunlockput>
    end_op();
    80004f02:	fffff097          	auipc	ra,0xfffff
    80004f06:	488080e7          	jalr	1160(ra) # 8000438a <end_op>
  }
  return -1;
    80004f0a:	557d                	li	a0,-1
}
    80004f0c:	21813083          	ld	ra,536(sp)
    80004f10:	21013403          	ld	s0,528(sp)
    80004f14:	20813483          	ld	s1,520(sp)
    80004f18:	20013903          	ld	s2,512(sp)
    80004f1c:	79fe                	ld	s3,504(sp)
    80004f1e:	7a5e                	ld	s4,496(sp)
    80004f20:	7abe                	ld	s5,488(sp)
    80004f22:	7b1e                	ld	s6,480(sp)
    80004f24:	6bfe                	ld	s7,472(sp)
    80004f26:	6c5e                	ld	s8,464(sp)
    80004f28:	6cbe                	ld	s9,456(sp)
    80004f2a:	6d1e                	ld	s10,448(sp)
    80004f2c:	7dfa                	ld	s11,440(sp)
    80004f2e:	22010113          	addi	sp,sp,544
    80004f32:	8082                	ret
    end_op();
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	456080e7          	jalr	1110(ra) # 8000438a <end_op>
    return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	b7f9                	j	80004f0c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f40:	8526                	mv	a0,s1
    80004f42:	ffffd097          	auipc	ra,0xffffd
    80004f46:	e82080e7          	jalr	-382(ra) # 80001dc4 <proc_pagetable>
    80004f4a:	8b2a                	mv	s6,a0
    80004f4c:	d555                	beqz	a0,80004ef8 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4e:	e6842783          	lw	a5,-408(s0)
    80004f52:	e8045703          	lhu	a4,-384(s0)
    80004f56:	c735                	beqz	a4,80004fc2 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f58:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f5a:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f5e:	6a05                	lui	s4,0x1
    80004f60:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f64:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f68:	6d85                	lui	s11,0x1
    80004f6a:	7d7d                	lui	s10,0xfffff
    80004f6c:	ac1d                	j	800051a2 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f6e:	00003517          	auipc	a0,0x3
    80004f72:	7d250513          	addi	a0,a0,2002 # 80008740 <syscalls+0x288>
    80004f76:	ffffb097          	auipc	ra,0xffffb
    80004f7a:	5d6080e7          	jalr	1494(ra) # 8000054c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f7e:	874a                	mv	a4,s2
    80004f80:	009c86bb          	addw	a3,s9,s1
    80004f84:	4581                	li	a1,0
    80004f86:	8556                	mv	a0,s5
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	c5e080e7          	jalr	-930(ra) # 80003be6 <readi>
    80004f90:	2501                	sext.w	a0,a0
    80004f92:	1aa91863          	bne	s2,a0,80005142 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004f96:	009d84bb          	addw	s1,s11,s1
    80004f9a:	013d09bb          	addw	s3,s10,s3
    80004f9e:	1f74f263          	bgeu	s1,s7,80005182 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fa2:	02049593          	slli	a1,s1,0x20
    80004fa6:	9181                	srli	a1,a1,0x20
    80004fa8:	95e2                	add	a1,a1,s8
    80004faa:	855a                	mv	a0,s6
    80004fac:	ffffc097          	auipc	ra,0xffffc
    80004fb0:	484080e7          	jalr	1156(ra) # 80001430 <walkaddr>
    80004fb4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fb6:	dd45                	beqz	a0,80004f6e <exec+0xfe>
      n = PGSIZE;
    80004fb8:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fba:	fd49f2e3          	bgeu	s3,s4,80004f7e <exec+0x10e>
      n = sz - i;
    80004fbe:	894e                	mv	s2,s3
    80004fc0:	bf7d                	j	80004f7e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fc2:	4481                	li	s1,0
  iunlockput(ip);
    80004fc4:	8556                	mv	a0,s5
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	bce080e7          	jalr	-1074(ra) # 80003b94 <iunlockput>
  end_op();
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	3bc080e7          	jalr	956(ra) # 8000438a <end_op>
  p = myproc();
    80004fd6:	ffffd097          	auipc	ra,0xffffd
    80004fda:	d2a080e7          	jalr	-726(ra) # 80001d00 <myproc>
    80004fde:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004fe0:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004fe4:	6785                	lui	a5,0x1
    80004fe6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004fe8:	97a6                	add	a5,a5,s1
    80004fea:	777d                	lui	a4,0xfffff
    80004fec:	8ff9                	and	a5,a5,a4
    80004fee:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ff2:	6609                	lui	a2,0x2
    80004ff4:	963e                	add	a2,a2,a5
    80004ff6:	85be                	mv	a1,a5
    80004ff8:	855a                	mv	a0,s6
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	7a8080e7          	jalr	1960(ra) # 800017a2 <uvmalloc>
    80005002:	8c2a                	mv	s8,a0
  ip = 0;
    80005004:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005006:	12050e63          	beqz	a0,80005142 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000500a:	75f9                	lui	a1,0xffffe
    8000500c:	95aa                	add	a1,a1,a0
    8000500e:	855a                	mv	a0,s6
    80005010:	ffffd097          	auipc	ra,0xffffd
    80005014:	9b4080e7          	jalr	-1612(ra) # 800019c4 <uvmclear>
  stackbase = sp - PGSIZE;
    80005018:	7afd                	lui	s5,0xfffff
    8000501a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000501c:	df043783          	ld	a5,-528(s0)
    80005020:	6388                	ld	a0,0(a5)
    80005022:	c925                	beqz	a0,80005092 <exec+0x222>
    80005024:	e8840993          	addi	s3,s0,-376
    80005028:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000502c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000502e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	1ee080e7          	jalr	494(ra) # 8000121e <strlen>
    80005038:	0015079b          	addiw	a5,a0,1
    8000503c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005040:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005044:	13596363          	bltu	s2,s5,8000516a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005048:	df043d83          	ld	s11,-528(s0)
    8000504c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005050:	8552                	mv	a0,s4
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	1cc080e7          	jalr	460(ra) # 8000121e <strlen>
    8000505a:	0015069b          	addiw	a3,a0,1
    8000505e:	8652                	mv	a2,s4
    80005060:	85ca                	mv	a1,s2
    80005062:	855a                	mv	a0,s6
    80005064:	ffffd097          	auipc	ra,0xffffd
    80005068:	992080e7          	jalr	-1646(ra) # 800019f6 <copyout>
    8000506c:	10054363          	bltz	a0,80005172 <exec+0x302>
    ustack[argc] = sp;
    80005070:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005074:	0485                	addi	s1,s1,1
    80005076:	008d8793          	addi	a5,s11,8
    8000507a:	def43823          	sd	a5,-528(s0)
    8000507e:	008db503          	ld	a0,8(s11)
    80005082:	c911                	beqz	a0,80005096 <exec+0x226>
    if(argc >= MAXARG)
    80005084:	09a1                	addi	s3,s3,8
    80005086:	fb3c95e3          	bne	s9,s3,80005030 <exec+0x1c0>
  sz = sz1;
    8000508a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000508e:	4a81                	li	s5,0
    80005090:	a84d                	j	80005142 <exec+0x2d2>
  sp = sz;
    80005092:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005094:	4481                	li	s1,0
  ustack[argc] = 0;
    80005096:	00349793          	slli	a5,s1,0x3
    8000509a:	f9078793          	addi	a5,a5,-112
    8000509e:	97a2                	add	a5,a5,s0
    800050a0:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    800050a4:	00148693          	addi	a3,s1,1
    800050a8:	068e                	slli	a3,a3,0x3
    800050aa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ae:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050b2:	01597663          	bgeu	s2,s5,800050be <exec+0x24e>
  sz = sz1;
    800050b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ba:	4a81                	li	s5,0
    800050bc:	a059                	j	80005142 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050be:	e8840613          	addi	a2,s0,-376
    800050c2:	85ca                	mv	a1,s2
    800050c4:	855a                	mv	a0,s6
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	930080e7          	jalr	-1744(ra) # 800019f6 <copyout>
    800050ce:	0a054663          	bltz	a0,8000517a <exec+0x30a>
  p->trapframe->a1 = sp;
    800050d2:	060bb783          	ld	a5,96(s7)
    800050d6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050da:	de843783          	ld	a5,-536(s0)
    800050de:	0007c703          	lbu	a4,0(a5)
    800050e2:	cf11                	beqz	a4,800050fe <exec+0x28e>
    800050e4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050e6:	02f00693          	li	a3,47
    800050ea:	a039                	j	800050f8 <exec+0x288>
      last = s+1;
    800050ec:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800050f0:	0785                	addi	a5,a5,1
    800050f2:	fff7c703          	lbu	a4,-1(a5)
    800050f6:	c701                	beqz	a4,800050fe <exec+0x28e>
    if(*s == '/')
    800050f8:	fed71ce3          	bne	a4,a3,800050f0 <exec+0x280>
    800050fc:	bfc5                	j	800050ec <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800050fe:	4641                	li	a2,16
    80005100:	de843583          	ld	a1,-536(s0)
    80005104:	160b8513          	addi	a0,s7,352
    80005108:	ffffc097          	auipc	ra,0xffffc
    8000510c:	0e4080e7          	jalr	228(ra) # 800011ec <safestrcpy>
  oldpagetable = p->pagetable;
    80005110:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005114:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005118:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000511c:	060bb783          	ld	a5,96(s7)
    80005120:	e6043703          	ld	a4,-416(s0)
    80005124:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005126:	060bb783          	ld	a5,96(s7)
    8000512a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000512e:	85ea                	mv	a1,s10
    80005130:	ffffd097          	auipc	ra,0xffffd
    80005134:	d30080e7          	jalr	-720(ra) # 80001e60 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005138:	0004851b          	sext.w	a0,s1
    8000513c:	bbc1                	j	80004f0c <exec+0x9c>
    8000513e:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005142:	df843583          	ld	a1,-520(s0)
    80005146:	855a                	mv	a0,s6
    80005148:	ffffd097          	auipc	ra,0xffffd
    8000514c:	d18080e7          	jalr	-744(ra) # 80001e60 <proc_freepagetable>
  if(ip){
    80005150:	da0a94e3          	bnez	s5,80004ef8 <exec+0x88>
  return -1;
    80005154:	557d                	li	a0,-1
    80005156:	bb5d                	j	80004f0c <exec+0x9c>
    80005158:	de943c23          	sd	s1,-520(s0)
    8000515c:	b7dd                	j	80005142 <exec+0x2d2>
    8000515e:	de943c23          	sd	s1,-520(s0)
    80005162:	b7c5                	j	80005142 <exec+0x2d2>
    80005164:	de943c23          	sd	s1,-520(s0)
    80005168:	bfe9                	j	80005142 <exec+0x2d2>
  sz = sz1;
    8000516a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000516e:	4a81                	li	s5,0
    80005170:	bfc9                	j	80005142 <exec+0x2d2>
  sz = sz1;
    80005172:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005176:	4a81                	li	s5,0
    80005178:	b7e9                	j	80005142 <exec+0x2d2>
  sz = sz1;
    8000517a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000517e:	4a81                	li	s5,0
    80005180:	b7c9                	j	80005142 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005182:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005186:	e0843783          	ld	a5,-504(s0)
    8000518a:	0017869b          	addiw	a3,a5,1
    8000518e:	e0d43423          	sd	a3,-504(s0)
    80005192:	e0043783          	ld	a5,-512(s0)
    80005196:	0387879b          	addiw	a5,a5,56
    8000519a:	e8045703          	lhu	a4,-384(s0)
    8000519e:	e2e6d3e3          	bge	a3,a4,80004fc4 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051a2:	2781                	sext.w	a5,a5
    800051a4:	e0f43023          	sd	a5,-512(s0)
    800051a8:	03800713          	li	a4,56
    800051ac:	86be                	mv	a3,a5
    800051ae:	e1040613          	addi	a2,s0,-496
    800051b2:	4581                	li	a1,0
    800051b4:	8556                	mv	a0,s5
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	a30080e7          	jalr	-1488(ra) # 80003be6 <readi>
    800051be:	03800793          	li	a5,56
    800051c2:	f6f51ee3          	bne	a0,a5,8000513e <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051c6:	e1042783          	lw	a5,-496(s0)
    800051ca:	4705                	li	a4,1
    800051cc:	fae79de3          	bne	a5,a4,80005186 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051d0:	e3843603          	ld	a2,-456(s0)
    800051d4:	e3043783          	ld	a5,-464(s0)
    800051d8:	f8f660e3          	bltu	a2,a5,80005158 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051dc:	e2043783          	ld	a5,-480(s0)
    800051e0:	963e                	add	a2,a2,a5
    800051e2:	f6f66ee3          	bltu	a2,a5,8000515e <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051e6:	85a6                	mv	a1,s1
    800051e8:	855a                	mv	a0,s6
    800051ea:	ffffc097          	auipc	ra,0xffffc
    800051ee:	5b8080e7          	jalr	1464(ra) # 800017a2 <uvmalloc>
    800051f2:	dea43c23          	sd	a0,-520(s0)
    800051f6:	d53d                	beqz	a0,80005164 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800051f8:	e2043c03          	ld	s8,-480(s0)
    800051fc:	de043783          	ld	a5,-544(s0)
    80005200:	00fc77b3          	and	a5,s8,a5
    80005204:	ff9d                	bnez	a5,80005142 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005206:	e1842c83          	lw	s9,-488(s0)
    8000520a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000520e:	f60b8ae3          	beqz	s7,80005182 <exec+0x312>
    80005212:	89de                	mv	s3,s7
    80005214:	4481                	li	s1,0
    80005216:	b371                	j	80004fa2 <exec+0x132>

0000000080005218 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005218:	7179                	addi	sp,sp,-48
    8000521a:	f406                	sd	ra,40(sp)
    8000521c:	f022                	sd	s0,32(sp)
    8000521e:	ec26                	sd	s1,24(sp)
    80005220:	e84a                	sd	s2,16(sp)
    80005222:	1800                	addi	s0,sp,48
    80005224:	892e                	mv	s2,a1
    80005226:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005228:	fdc40593          	addi	a1,s0,-36
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	b94080e7          	jalr	-1132(ra) # 80002dc0 <argint>
    80005234:	04054063          	bltz	a0,80005274 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005238:	fdc42703          	lw	a4,-36(s0)
    8000523c:	47bd                	li	a5,15
    8000523e:	02e7ed63          	bltu	a5,a4,80005278 <argfd+0x60>
    80005242:	ffffd097          	auipc	ra,0xffffd
    80005246:	abe080e7          	jalr	-1346(ra) # 80001d00 <myproc>
    8000524a:	fdc42703          	lw	a4,-36(s0)
    8000524e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd6ff2>
    80005252:	078e                	slli	a5,a5,0x3
    80005254:	953e                	add	a0,a0,a5
    80005256:	651c                	ld	a5,8(a0)
    80005258:	c395                	beqz	a5,8000527c <argfd+0x64>
    return -1;
  if(pfd)
    8000525a:	00090463          	beqz	s2,80005262 <argfd+0x4a>
    *pfd = fd;
    8000525e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005262:	4501                	li	a0,0
  if(pf)
    80005264:	c091                	beqz	s1,80005268 <argfd+0x50>
    *pf = f;
    80005266:	e09c                	sd	a5,0(s1)
}
    80005268:	70a2                	ld	ra,40(sp)
    8000526a:	7402                	ld	s0,32(sp)
    8000526c:	64e2                	ld	s1,24(sp)
    8000526e:	6942                	ld	s2,16(sp)
    80005270:	6145                	addi	sp,sp,48
    80005272:	8082                	ret
    return -1;
    80005274:	557d                	li	a0,-1
    80005276:	bfcd                	j	80005268 <argfd+0x50>
    return -1;
    80005278:	557d                	li	a0,-1
    8000527a:	b7fd                	j	80005268 <argfd+0x50>
    8000527c:	557d                	li	a0,-1
    8000527e:	b7ed                	j	80005268 <argfd+0x50>

0000000080005280 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005280:	1101                	addi	sp,sp,-32
    80005282:	ec06                	sd	ra,24(sp)
    80005284:	e822                	sd	s0,16(sp)
    80005286:	e426                	sd	s1,8(sp)
    80005288:	1000                	addi	s0,sp,32
    8000528a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000528c:	ffffd097          	auipc	ra,0xffffd
    80005290:	a74080e7          	jalr	-1420(ra) # 80001d00 <myproc>
    80005294:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005296:	0d850793          	addi	a5,a0,216
    8000529a:	4501                	li	a0,0
    8000529c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000529e:	6398                	ld	a4,0(a5)
    800052a0:	cb19                	beqz	a4,800052b6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052a2:	2505                	addiw	a0,a0,1
    800052a4:	07a1                	addi	a5,a5,8
    800052a6:	fed51ce3          	bne	a0,a3,8000529e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052aa:	557d                	li	a0,-1
}
    800052ac:	60e2                	ld	ra,24(sp)
    800052ae:	6442                	ld	s0,16(sp)
    800052b0:	64a2                	ld	s1,8(sp)
    800052b2:	6105                	addi	sp,sp,32
    800052b4:	8082                	ret
      p->ofile[fd] = f;
    800052b6:	01a50793          	addi	a5,a0,26
    800052ba:	078e                	slli	a5,a5,0x3
    800052bc:	963e                	add	a2,a2,a5
    800052be:	e604                	sd	s1,8(a2)
      return fd;
    800052c0:	b7f5                	j	800052ac <fdalloc+0x2c>

00000000800052c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052c2:	715d                	addi	sp,sp,-80
    800052c4:	e486                	sd	ra,72(sp)
    800052c6:	e0a2                	sd	s0,64(sp)
    800052c8:	fc26                	sd	s1,56(sp)
    800052ca:	f84a                	sd	s2,48(sp)
    800052cc:	f44e                	sd	s3,40(sp)
    800052ce:	f052                	sd	s4,32(sp)
    800052d0:	ec56                	sd	s5,24(sp)
    800052d2:	0880                	addi	s0,sp,80
    800052d4:	89ae                	mv	s3,a1
    800052d6:	8ab2                	mv	s5,a2
    800052d8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052da:	fb040593          	addi	a1,s0,-80
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	e2c080e7          	jalr	-468(ra) # 8000410a <nameiparent>
    800052e6:	892a                	mv	s2,a0
    800052e8:	12050e63          	beqz	a0,80005424 <create+0x162>
    return 0;

  ilock(dp);
    800052ec:	ffffe097          	auipc	ra,0xffffe
    800052f0:	646080e7          	jalr	1606(ra) # 80003932 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052f4:	4601                	li	a2,0
    800052f6:	fb040593          	addi	a1,s0,-80
    800052fa:	854a                	mv	a0,s2
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	b18080e7          	jalr	-1256(ra) # 80003e14 <dirlookup>
    80005304:	84aa                	mv	s1,a0
    80005306:	c921                	beqz	a0,80005356 <create+0x94>
    iunlockput(dp);
    80005308:	854a                	mv	a0,s2
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	88a080e7          	jalr	-1910(ra) # 80003b94 <iunlockput>
    ilock(ip);
    80005312:	8526                	mv	a0,s1
    80005314:	ffffe097          	auipc	ra,0xffffe
    80005318:	61e080e7          	jalr	1566(ra) # 80003932 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000531c:	2981                	sext.w	s3,s3
    8000531e:	4789                	li	a5,2
    80005320:	02f99463          	bne	s3,a5,80005348 <create+0x86>
    80005324:	04c4d783          	lhu	a5,76(s1)
    80005328:	37f9                	addiw	a5,a5,-2
    8000532a:	17c2                	slli	a5,a5,0x30
    8000532c:	93c1                	srli	a5,a5,0x30
    8000532e:	4705                	li	a4,1
    80005330:	00f76c63          	bltu	a4,a5,80005348 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005334:	8526                	mv	a0,s1
    80005336:	60a6                	ld	ra,72(sp)
    80005338:	6406                	ld	s0,64(sp)
    8000533a:	74e2                	ld	s1,56(sp)
    8000533c:	7942                	ld	s2,48(sp)
    8000533e:	79a2                	ld	s3,40(sp)
    80005340:	7a02                	ld	s4,32(sp)
    80005342:	6ae2                	ld	s5,24(sp)
    80005344:	6161                	addi	sp,sp,80
    80005346:	8082                	ret
    iunlockput(ip);
    80005348:	8526                	mv	a0,s1
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	84a080e7          	jalr	-1974(ra) # 80003b94 <iunlockput>
    return 0;
    80005352:	4481                	li	s1,0
    80005354:	b7c5                	j	80005334 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005356:	85ce                	mv	a1,s3
    80005358:	00092503          	lw	a0,0(s2)
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	43c080e7          	jalr	1084(ra) # 80003798 <ialloc>
    80005364:	84aa                	mv	s1,a0
    80005366:	c521                	beqz	a0,800053ae <create+0xec>
  ilock(ip);
    80005368:	ffffe097          	auipc	ra,0xffffe
    8000536c:	5ca080e7          	jalr	1482(ra) # 80003932 <ilock>
  ip->major = major;
    80005370:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    80005374:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    80005378:	4a05                	li	s4,1
    8000537a:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    8000537e:	8526                	mv	a0,s1
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	4e6080e7          	jalr	1254(ra) # 80003866 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005388:	2981                	sext.w	s3,s3
    8000538a:	03498a63          	beq	s3,s4,800053be <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000538e:	40d0                	lw	a2,4(s1)
    80005390:	fb040593          	addi	a1,s0,-80
    80005394:	854a                	mv	a0,s2
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	c94080e7          	jalr	-876(ra) # 8000402a <dirlink>
    8000539e:	06054b63          	bltz	a0,80005414 <create+0x152>
  iunlockput(dp);
    800053a2:	854a                	mv	a0,s2
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	7f0080e7          	jalr	2032(ra) # 80003b94 <iunlockput>
  return ip;
    800053ac:	b761                	j	80005334 <create+0x72>
    panic("create: ialloc");
    800053ae:	00003517          	auipc	a0,0x3
    800053b2:	3b250513          	addi	a0,a0,946 # 80008760 <syscalls+0x2a8>
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	196080e7          	jalr	406(ra) # 8000054c <panic>
    dp->nlink++;  // for ".."
    800053be:	05295783          	lhu	a5,82(s2)
    800053c2:	2785                	addiw	a5,a5,1
    800053c4:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    800053c8:	854a                	mv	a0,s2
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	49c080e7          	jalr	1180(ra) # 80003866 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d2:	40d0                	lw	a2,4(s1)
    800053d4:	00003597          	auipc	a1,0x3
    800053d8:	39c58593          	addi	a1,a1,924 # 80008770 <syscalls+0x2b8>
    800053dc:	8526                	mv	a0,s1
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	c4c080e7          	jalr	-948(ra) # 8000402a <dirlink>
    800053e6:	00054f63          	bltz	a0,80005404 <create+0x142>
    800053ea:	00492603          	lw	a2,4(s2)
    800053ee:	00003597          	auipc	a1,0x3
    800053f2:	38a58593          	addi	a1,a1,906 # 80008778 <syscalls+0x2c0>
    800053f6:	8526                	mv	a0,s1
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	c32080e7          	jalr	-974(ra) # 8000402a <dirlink>
    80005400:	f80557e3          	bgez	a0,8000538e <create+0xcc>
      panic("create dots");
    80005404:	00003517          	auipc	a0,0x3
    80005408:	37c50513          	addi	a0,a0,892 # 80008780 <syscalls+0x2c8>
    8000540c:	ffffb097          	auipc	ra,0xffffb
    80005410:	140080e7          	jalr	320(ra) # 8000054c <panic>
    panic("create: dirlink");
    80005414:	00003517          	auipc	a0,0x3
    80005418:	37c50513          	addi	a0,a0,892 # 80008790 <syscalls+0x2d8>
    8000541c:	ffffb097          	auipc	ra,0xffffb
    80005420:	130080e7          	jalr	304(ra) # 8000054c <panic>
    return 0;
    80005424:	84aa                	mv	s1,a0
    80005426:	b739                	j	80005334 <create+0x72>

0000000080005428 <sys_dup>:
{
    80005428:	7179                	addi	sp,sp,-48
    8000542a:	f406                	sd	ra,40(sp)
    8000542c:	f022                	sd	s0,32(sp)
    8000542e:	ec26                	sd	s1,24(sp)
    80005430:	e84a                	sd	s2,16(sp)
    80005432:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005434:	fd840613          	addi	a2,s0,-40
    80005438:	4581                	li	a1,0
    8000543a:	4501                	li	a0,0
    8000543c:	00000097          	auipc	ra,0x0
    80005440:	ddc080e7          	jalr	-548(ra) # 80005218 <argfd>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005446:	02054363          	bltz	a0,8000546c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000544a:	fd843903          	ld	s2,-40(s0)
    8000544e:	854a                	mv	a0,s2
    80005450:	00000097          	auipc	ra,0x0
    80005454:	e30080e7          	jalr	-464(ra) # 80005280 <fdalloc>
    80005458:	84aa                	mv	s1,a0
    return -1;
    8000545a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000545c:	00054863          	bltz	a0,8000546c <sys_dup+0x44>
  filedup(f);
    80005460:	854a                	mv	a0,s2
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	328080e7          	jalr	808(ra) # 8000478a <filedup>
  return fd;
    8000546a:	87a6                	mv	a5,s1
}
    8000546c:	853e                	mv	a0,a5
    8000546e:	70a2                	ld	ra,40(sp)
    80005470:	7402                	ld	s0,32(sp)
    80005472:	64e2                	ld	s1,24(sp)
    80005474:	6942                	ld	s2,16(sp)
    80005476:	6145                	addi	sp,sp,48
    80005478:	8082                	ret

000000008000547a <sys_read>:
{
    8000547a:	7179                	addi	sp,sp,-48
    8000547c:	f406                	sd	ra,40(sp)
    8000547e:	f022                	sd	s0,32(sp)
    80005480:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005482:	fe840613          	addi	a2,s0,-24
    80005486:	4581                	li	a1,0
    80005488:	4501                	li	a0,0
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	d8e080e7          	jalr	-626(ra) # 80005218 <argfd>
    return -1;
    80005492:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005494:	04054163          	bltz	a0,800054d6 <sys_read+0x5c>
    80005498:	fe440593          	addi	a1,s0,-28
    8000549c:	4509                	li	a0,2
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	922080e7          	jalr	-1758(ra) # 80002dc0 <argint>
    return -1;
    800054a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a8:	02054763          	bltz	a0,800054d6 <sys_read+0x5c>
    800054ac:	fd840593          	addi	a1,s0,-40
    800054b0:	4505                	li	a0,1
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	930080e7          	jalr	-1744(ra) # 80002de2 <argaddr>
    return -1;
    800054ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054bc:	00054d63          	bltz	a0,800054d6 <sys_read+0x5c>
  return fileread(f, p, n);
    800054c0:	fe442603          	lw	a2,-28(s0)
    800054c4:	fd843583          	ld	a1,-40(s0)
    800054c8:	fe843503          	ld	a0,-24(s0)
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	44a080e7          	jalr	1098(ra) # 80004916 <fileread>
    800054d4:	87aa                	mv	a5,a0
}
    800054d6:	853e                	mv	a0,a5
    800054d8:	70a2                	ld	ra,40(sp)
    800054da:	7402                	ld	s0,32(sp)
    800054dc:	6145                	addi	sp,sp,48
    800054de:	8082                	ret

00000000800054e0 <sys_write>:
{
    800054e0:	7179                	addi	sp,sp,-48
    800054e2:	f406                	sd	ra,40(sp)
    800054e4:	f022                	sd	s0,32(sp)
    800054e6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e8:	fe840613          	addi	a2,s0,-24
    800054ec:	4581                	li	a1,0
    800054ee:	4501                	li	a0,0
    800054f0:	00000097          	auipc	ra,0x0
    800054f4:	d28080e7          	jalr	-728(ra) # 80005218 <argfd>
    return -1;
    800054f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fa:	04054163          	bltz	a0,8000553c <sys_write+0x5c>
    800054fe:	fe440593          	addi	a1,s0,-28
    80005502:	4509                	li	a0,2
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	8bc080e7          	jalr	-1860(ra) # 80002dc0 <argint>
    return -1;
    8000550c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550e:	02054763          	bltz	a0,8000553c <sys_write+0x5c>
    80005512:	fd840593          	addi	a1,s0,-40
    80005516:	4505                	li	a0,1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	8ca080e7          	jalr	-1846(ra) # 80002de2 <argaddr>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005522:	00054d63          	bltz	a0,8000553c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005526:	fe442603          	lw	a2,-28(s0)
    8000552a:	fd843583          	ld	a1,-40(s0)
    8000552e:	fe843503          	ld	a0,-24(s0)
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	4a6080e7          	jalr	1190(ra) # 800049d8 <filewrite>
    8000553a:	87aa                	mv	a5,a0
}
    8000553c:	853e                	mv	a0,a5
    8000553e:	70a2                	ld	ra,40(sp)
    80005540:	7402                	ld	s0,32(sp)
    80005542:	6145                	addi	sp,sp,48
    80005544:	8082                	ret

0000000080005546 <sys_close>:
{
    80005546:	1101                	addi	sp,sp,-32
    80005548:	ec06                	sd	ra,24(sp)
    8000554a:	e822                	sd	s0,16(sp)
    8000554c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000554e:	fe040613          	addi	a2,s0,-32
    80005552:	fec40593          	addi	a1,s0,-20
    80005556:	4501                	li	a0,0
    80005558:	00000097          	auipc	ra,0x0
    8000555c:	cc0080e7          	jalr	-832(ra) # 80005218 <argfd>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005562:	02054463          	bltz	a0,8000558a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005566:	ffffc097          	auipc	ra,0xffffc
    8000556a:	79a080e7          	jalr	1946(ra) # 80001d00 <myproc>
    8000556e:	fec42783          	lw	a5,-20(s0)
    80005572:	07e9                	addi	a5,a5,26
    80005574:	078e                	slli	a5,a5,0x3
    80005576:	953e                	add	a0,a0,a5
    80005578:	00053423          	sd	zero,8(a0)
  fileclose(f);
    8000557c:	fe043503          	ld	a0,-32(s0)
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	25c080e7          	jalr	604(ra) # 800047dc <fileclose>
  return 0;
    80005588:	4781                	li	a5,0
}
    8000558a:	853e                	mv	a0,a5
    8000558c:	60e2                	ld	ra,24(sp)
    8000558e:	6442                	ld	s0,16(sp)
    80005590:	6105                	addi	sp,sp,32
    80005592:	8082                	ret

0000000080005594 <sys_fstat>:
{
    80005594:	1101                	addi	sp,sp,-32
    80005596:	ec06                	sd	ra,24(sp)
    80005598:	e822                	sd	s0,16(sp)
    8000559a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559c:	fe840613          	addi	a2,s0,-24
    800055a0:	4581                	li	a1,0
    800055a2:	4501                	li	a0,0
    800055a4:	00000097          	auipc	ra,0x0
    800055a8:	c74080e7          	jalr	-908(ra) # 80005218 <argfd>
    return -1;
    800055ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ae:	02054563          	bltz	a0,800055d8 <sys_fstat+0x44>
    800055b2:	fe040593          	addi	a1,s0,-32
    800055b6:	4505                	li	a0,1
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	82a080e7          	jalr	-2006(ra) # 80002de2 <argaddr>
    return -1;
    800055c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c2:	00054b63          	bltz	a0,800055d8 <sys_fstat+0x44>
  return filestat(f, st);
    800055c6:	fe043583          	ld	a1,-32(s0)
    800055ca:	fe843503          	ld	a0,-24(s0)
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	2d6080e7          	jalr	726(ra) # 800048a4 <filestat>
    800055d6:	87aa                	mv	a5,a0
}
    800055d8:	853e                	mv	a0,a5
    800055da:	60e2                	ld	ra,24(sp)
    800055dc:	6442                	ld	s0,16(sp)
    800055de:	6105                	addi	sp,sp,32
    800055e0:	8082                	ret

00000000800055e2 <sys_link>:
{
    800055e2:	7169                	addi	sp,sp,-304
    800055e4:	f606                	sd	ra,296(sp)
    800055e6:	f222                	sd	s0,288(sp)
    800055e8:	ee26                	sd	s1,280(sp)
    800055ea:	ea4a                	sd	s2,272(sp)
    800055ec:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ee:	08000613          	li	a2,128
    800055f2:	ed040593          	addi	a1,s0,-304
    800055f6:	4501                	li	a0,0
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	80c080e7          	jalr	-2036(ra) # 80002e04 <argstr>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005602:	10054e63          	bltz	a0,8000571e <sys_link+0x13c>
    80005606:	08000613          	li	a2,128
    8000560a:	f5040593          	addi	a1,s0,-176
    8000560e:	4505                	li	a0,1
    80005610:	ffffd097          	auipc	ra,0xffffd
    80005614:	7f4080e7          	jalr	2036(ra) # 80002e04 <argstr>
    return -1;
    80005618:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000561a:	10054263          	bltz	a0,8000571e <sys_link+0x13c>
  begin_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	cee080e7          	jalr	-786(ra) # 8000430c <begin_op>
  if((ip = namei(old)) == 0){
    80005626:	ed040513          	addi	a0,s0,-304
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	ac2080e7          	jalr	-1342(ra) # 800040ec <namei>
    80005632:	84aa                	mv	s1,a0
    80005634:	c551                	beqz	a0,800056c0 <sys_link+0xde>
  ilock(ip);
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	2fc080e7          	jalr	764(ra) # 80003932 <ilock>
  if(ip->type == T_DIR){
    8000563e:	04c49703          	lh	a4,76(s1)
    80005642:	4785                	li	a5,1
    80005644:	08f70463          	beq	a4,a5,800056cc <sys_link+0xea>
  ip->nlink++;
    80005648:	0524d783          	lhu	a5,82(s1)
    8000564c:	2785                	addiw	a5,a5,1
    8000564e:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	212080e7          	jalr	530(ra) # 80003866 <iupdate>
  iunlock(ip);
    8000565c:	8526                	mv	a0,s1
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	396080e7          	jalr	918(ra) # 800039f4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005666:	fd040593          	addi	a1,s0,-48
    8000566a:	f5040513          	addi	a0,s0,-176
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	a9c080e7          	jalr	-1380(ra) # 8000410a <nameiparent>
    80005676:	892a                	mv	s2,a0
    80005678:	c935                	beqz	a0,800056ec <sys_link+0x10a>
  ilock(dp);
    8000567a:	ffffe097          	auipc	ra,0xffffe
    8000567e:	2b8080e7          	jalr	696(ra) # 80003932 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005682:	00092703          	lw	a4,0(s2)
    80005686:	409c                	lw	a5,0(s1)
    80005688:	04f71d63          	bne	a4,a5,800056e2 <sys_link+0x100>
    8000568c:	40d0                	lw	a2,4(s1)
    8000568e:	fd040593          	addi	a1,s0,-48
    80005692:	854a                	mv	a0,s2
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	996080e7          	jalr	-1642(ra) # 8000402a <dirlink>
    8000569c:	04054363          	bltz	a0,800056e2 <sys_link+0x100>
  iunlockput(dp);
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	4f2080e7          	jalr	1266(ra) # 80003b94 <iunlockput>
  iput(ip);
    800056aa:	8526                	mv	a0,s1
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	440080e7          	jalr	1088(ra) # 80003aec <iput>
  end_op();
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	cd6080e7          	jalr	-810(ra) # 8000438a <end_op>
  return 0;
    800056bc:	4781                	li	a5,0
    800056be:	a085                	j	8000571e <sys_link+0x13c>
    end_op();
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	cca080e7          	jalr	-822(ra) # 8000438a <end_op>
    return -1;
    800056c8:	57fd                	li	a5,-1
    800056ca:	a891                	j	8000571e <sys_link+0x13c>
    iunlockput(ip);
    800056cc:	8526                	mv	a0,s1
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	4c6080e7          	jalr	1222(ra) # 80003b94 <iunlockput>
    end_op();
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	cb4080e7          	jalr	-844(ra) # 8000438a <end_op>
    return -1;
    800056de:	57fd                	li	a5,-1
    800056e0:	a83d                	j	8000571e <sys_link+0x13c>
    iunlockput(dp);
    800056e2:	854a                	mv	a0,s2
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	4b0080e7          	jalr	1200(ra) # 80003b94 <iunlockput>
  ilock(ip);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	244080e7          	jalr	580(ra) # 80003932 <ilock>
  ip->nlink--;
    800056f6:	0524d783          	lhu	a5,82(s1)
    800056fa:	37fd                	addiw	a5,a5,-1
    800056fc:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005700:	8526                	mv	a0,s1
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	164080e7          	jalr	356(ra) # 80003866 <iupdate>
  iunlockput(ip);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	488080e7          	jalr	1160(ra) # 80003b94 <iunlockput>
  end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	c76080e7          	jalr	-906(ra) # 8000438a <end_op>
  return -1;
    8000571c:	57fd                	li	a5,-1
}
    8000571e:	853e                	mv	a0,a5
    80005720:	70b2                	ld	ra,296(sp)
    80005722:	7412                	ld	s0,288(sp)
    80005724:	64f2                	ld	s1,280(sp)
    80005726:	6952                	ld	s2,272(sp)
    80005728:	6155                	addi	sp,sp,304
    8000572a:	8082                	ret

000000008000572c <sys_unlink>:
{
    8000572c:	7151                	addi	sp,sp,-240
    8000572e:	f586                	sd	ra,232(sp)
    80005730:	f1a2                	sd	s0,224(sp)
    80005732:	eda6                	sd	s1,216(sp)
    80005734:	e9ca                	sd	s2,208(sp)
    80005736:	e5ce                	sd	s3,200(sp)
    80005738:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000573a:	08000613          	li	a2,128
    8000573e:	f3040593          	addi	a1,s0,-208
    80005742:	4501                	li	a0,0
    80005744:	ffffd097          	auipc	ra,0xffffd
    80005748:	6c0080e7          	jalr	1728(ra) # 80002e04 <argstr>
    8000574c:	18054163          	bltz	a0,800058ce <sys_unlink+0x1a2>
  begin_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	bbc080e7          	jalr	-1092(ra) # 8000430c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005758:	fb040593          	addi	a1,s0,-80
    8000575c:	f3040513          	addi	a0,s0,-208
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	9aa080e7          	jalr	-1622(ra) # 8000410a <nameiparent>
    80005768:	84aa                	mv	s1,a0
    8000576a:	c979                	beqz	a0,80005840 <sys_unlink+0x114>
  ilock(dp);
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	1c6080e7          	jalr	454(ra) # 80003932 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005774:	00003597          	auipc	a1,0x3
    80005778:	ffc58593          	addi	a1,a1,-4 # 80008770 <syscalls+0x2b8>
    8000577c:	fb040513          	addi	a0,s0,-80
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	67a080e7          	jalr	1658(ra) # 80003dfa <namecmp>
    80005788:	14050a63          	beqz	a0,800058dc <sys_unlink+0x1b0>
    8000578c:	00003597          	auipc	a1,0x3
    80005790:	fec58593          	addi	a1,a1,-20 # 80008778 <syscalls+0x2c0>
    80005794:	fb040513          	addi	a0,s0,-80
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	662080e7          	jalr	1634(ra) # 80003dfa <namecmp>
    800057a0:	12050e63          	beqz	a0,800058dc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057a4:	f2c40613          	addi	a2,s0,-212
    800057a8:	fb040593          	addi	a1,s0,-80
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	666080e7          	jalr	1638(ra) # 80003e14 <dirlookup>
    800057b6:	892a                	mv	s2,a0
    800057b8:	12050263          	beqz	a0,800058dc <sys_unlink+0x1b0>
  ilock(ip);
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	176080e7          	jalr	374(ra) # 80003932 <ilock>
  if(ip->nlink < 1)
    800057c4:	05291783          	lh	a5,82(s2)
    800057c8:	08f05263          	blez	a5,8000584c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057cc:	04c91703          	lh	a4,76(s2)
    800057d0:	4785                	li	a5,1
    800057d2:	08f70563          	beq	a4,a5,8000585c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057d6:	4641                	li	a2,16
    800057d8:	4581                	li	a1,0
    800057da:	fc040513          	addi	a0,s0,-64
    800057de:	ffffc097          	auipc	ra,0xffffc
    800057e2:	8bc080e7          	jalr	-1860(ra) # 8000109a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e6:	4741                	li	a4,16
    800057e8:	f2c42683          	lw	a3,-212(s0)
    800057ec:	fc040613          	addi	a2,s0,-64
    800057f0:	4581                	li	a1,0
    800057f2:	8526                	mv	a0,s1
    800057f4:	ffffe097          	auipc	ra,0xffffe
    800057f8:	4ea080e7          	jalr	1258(ra) # 80003cde <writei>
    800057fc:	47c1                	li	a5,16
    800057fe:	0af51563          	bne	a0,a5,800058a8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005802:	04c91703          	lh	a4,76(s2)
    80005806:	4785                	li	a5,1
    80005808:	0af70863          	beq	a4,a5,800058b8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000580c:	8526                	mv	a0,s1
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	386080e7          	jalr	902(ra) # 80003b94 <iunlockput>
  ip->nlink--;
    80005816:	05295783          	lhu	a5,82(s2)
    8000581a:	37fd                	addiw	a5,a5,-1
    8000581c:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005820:	854a                	mv	a0,s2
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	044080e7          	jalr	68(ra) # 80003866 <iupdate>
  iunlockput(ip);
    8000582a:	854a                	mv	a0,s2
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	368080e7          	jalr	872(ra) # 80003b94 <iunlockput>
  end_op();
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	b56080e7          	jalr	-1194(ra) # 8000438a <end_op>
  return 0;
    8000583c:	4501                	li	a0,0
    8000583e:	a84d                	j	800058f0 <sys_unlink+0x1c4>
    end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	b4a080e7          	jalr	-1206(ra) # 8000438a <end_op>
    return -1;
    80005848:	557d                	li	a0,-1
    8000584a:	a05d                	j	800058f0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000584c:	00003517          	auipc	a0,0x3
    80005850:	f5450513          	addi	a0,a0,-172 # 800087a0 <syscalls+0x2e8>
    80005854:	ffffb097          	auipc	ra,0xffffb
    80005858:	cf8080e7          	jalr	-776(ra) # 8000054c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000585c:	05492703          	lw	a4,84(s2)
    80005860:	02000793          	li	a5,32
    80005864:	f6e7f9e3          	bgeu	a5,a4,800057d6 <sys_unlink+0xaa>
    80005868:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000586c:	4741                	li	a4,16
    8000586e:	86ce                	mv	a3,s3
    80005870:	f1840613          	addi	a2,s0,-232
    80005874:	4581                	li	a1,0
    80005876:	854a                	mv	a0,s2
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	36e080e7          	jalr	878(ra) # 80003be6 <readi>
    80005880:	47c1                	li	a5,16
    80005882:	00f51b63          	bne	a0,a5,80005898 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005886:	f1845783          	lhu	a5,-232(s0)
    8000588a:	e7a1                	bnez	a5,800058d2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000588c:	29c1                	addiw	s3,s3,16
    8000588e:	05492783          	lw	a5,84(s2)
    80005892:	fcf9ede3          	bltu	s3,a5,8000586c <sys_unlink+0x140>
    80005896:	b781                	j	800057d6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005898:	00003517          	auipc	a0,0x3
    8000589c:	f2050513          	addi	a0,a0,-224 # 800087b8 <syscalls+0x300>
    800058a0:	ffffb097          	auipc	ra,0xffffb
    800058a4:	cac080e7          	jalr	-852(ra) # 8000054c <panic>
    panic("unlink: writei");
    800058a8:	00003517          	auipc	a0,0x3
    800058ac:	f2850513          	addi	a0,a0,-216 # 800087d0 <syscalls+0x318>
    800058b0:	ffffb097          	auipc	ra,0xffffb
    800058b4:	c9c080e7          	jalr	-868(ra) # 8000054c <panic>
    dp->nlink--;
    800058b8:	0524d783          	lhu	a5,82(s1)
    800058bc:	37fd                	addiw	a5,a5,-1
    800058be:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	fa2080e7          	jalr	-94(ra) # 80003866 <iupdate>
    800058cc:	b781                	j	8000580c <sys_unlink+0xe0>
    return -1;
    800058ce:	557d                	li	a0,-1
    800058d0:	a005                	j	800058f0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	2c0080e7          	jalr	704(ra) # 80003b94 <iunlockput>
  iunlockput(dp);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	2b6080e7          	jalr	694(ra) # 80003b94 <iunlockput>
  end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	aa4080e7          	jalr	-1372(ra) # 8000438a <end_op>
  return -1;
    800058ee:	557d                	li	a0,-1
}
    800058f0:	70ae                	ld	ra,232(sp)
    800058f2:	740e                	ld	s0,224(sp)
    800058f4:	64ee                	ld	s1,216(sp)
    800058f6:	694e                	ld	s2,208(sp)
    800058f8:	69ae                	ld	s3,200(sp)
    800058fa:	616d                	addi	sp,sp,240
    800058fc:	8082                	ret

00000000800058fe <sys_open>:

uint64
sys_open(void)
{
    800058fe:	7131                	addi	sp,sp,-192
    80005900:	fd06                	sd	ra,184(sp)
    80005902:	f922                	sd	s0,176(sp)
    80005904:	f526                	sd	s1,168(sp)
    80005906:	f14a                	sd	s2,160(sp)
    80005908:	ed4e                	sd	s3,152(sp)
    8000590a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000590c:	08000613          	li	a2,128
    80005910:	f5040593          	addi	a1,s0,-176
    80005914:	4501                	li	a0,0
    80005916:	ffffd097          	auipc	ra,0xffffd
    8000591a:	4ee080e7          	jalr	1262(ra) # 80002e04 <argstr>
    return -1;
    8000591e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005920:	0c054163          	bltz	a0,800059e2 <sys_open+0xe4>
    80005924:	f4c40593          	addi	a1,s0,-180
    80005928:	4505                	li	a0,1
    8000592a:	ffffd097          	auipc	ra,0xffffd
    8000592e:	496080e7          	jalr	1174(ra) # 80002dc0 <argint>
    80005932:	0a054863          	bltz	a0,800059e2 <sys_open+0xe4>

  begin_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	9d6080e7          	jalr	-1578(ra) # 8000430c <begin_op>

  if(omode & O_CREATE){
    8000593e:	f4c42783          	lw	a5,-180(s0)
    80005942:	2007f793          	andi	a5,a5,512
    80005946:	cbdd                	beqz	a5,800059fc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005948:	4681                	li	a3,0
    8000594a:	4601                	li	a2,0
    8000594c:	4589                	li	a1,2
    8000594e:	f5040513          	addi	a0,s0,-176
    80005952:	00000097          	auipc	ra,0x0
    80005956:	970080e7          	jalr	-1680(ra) # 800052c2 <create>
    8000595a:	892a                	mv	s2,a0
    if(ip == 0){
    8000595c:	c959                	beqz	a0,800059f2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000595e:	04c91703          	lh	a4,76(s2)
    80005962:	478d                	li	a5,3
    80005964:	00f71763          	bne	a4,a5,80005972 <sys_open+0x74>
    80005968:	04e95703          	lhu	a4,78(s2)
    8000596c:	47a5                	li	a5,9
    8000596e:	0ce7ec63          	bltu	a5,a4,80005a46 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	dae080e7          	jalr	-594(ra) # 80004720 <filealloc>
    8000597a:	89aa                	mv	s3,a0
    8000597c:	10050263          	beqz	a0,80005a80 <sys_open+0x182>
    80005980:	00000097          	auipc	ra,0x0
    80005984:	900080e7          	jalr	-1792(ra) # 80005280 <fdalloc>
    80005988:	84aa                	mv	s1,a0
    8000598a:	0e054663          	bltz	a0,80005a76 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000598e:	04c91703          	lh	a4,76(s2)
    80005992:	478d                	li	a5,3
    80005994:	0cf70463          	beq	a4,a5,80005a5c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005998:	4789                	li	a5,2
    8000599a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000599e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059a2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059a6:	f4c42783          	lw	a5,-180(s0)
    800059aa:	0017c713          	xori	a4,a5,1
    800059ae:	8b05                	andi	a4,a4,1
    800059b0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059b4:	0037f713          	andi	a4,a5,3
    800059b8:	00e03733          	snez	a4,a4
    800059bc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059c0:	4007f793          	andi	a5,a5,1024
    800059c4:	c791                	beqz	a5,800059d0 <sys_open+0xd2>
    800059c6:	04c91703          	lh	a4,76(s2)
    800059ca:	4789                	li	a5,2
    800059cc:	08f70f63          	beq	a4,a5,80005a6a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059d0:	854a                	mv	a0,s2
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	022080e7          	jalr	34(ra) # 800039f4 <iunlock>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	9b0080e7          	jalr	-1616(ra) # 8000438a <end_op>

  return fd;
}
    800059e2:	8526                	mv	a0,s1
    800059e4:	70ea                	ld	ra,184(sp)
    800059e6:	744a                	ld	s0,176(sp)
    800059e8:	74aa                	ld	s1,168(sp)
    800059ea:	790a                	ld	s2,160(sp)
    800059ec:	69ea                	ld	s3,152(sp)
    800059ee:	6129                	addi	sp,sp,192
    800059f0:	8082                	ret
      end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	998080e7          	jalr	-1640(ra) # 8000438a <end_op>
      return -1;
    800059fa:	b7e5                	j	800059e2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059fc:	f5040513          	addi	a0,s0,-176
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	6ec080e7          	jalr	1772(ra) # 800040ec <namei>
    80005a08:	892a                	mv	s2,a0
    80005a0a:	c905                	beqz	a0,80005a3a <sys_open+0x13c>
    ilock(ip);
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	f26080e7          	jalr	-218(ra) # 80003932 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a14:	04c91703          	lh	a4,76(s2)
    80005a18:	4785                	li	a5,1
    80005a1a:	f4f712e3          	bne	a4,a5,8000595e <sys_open+0x60>
    80005a1e:	f4c42783          	lw	a5,-180(s0)
    80005a22:	dba1                	beqz	a5,80005972 <sys_open+0x74>
      iunlockput(ip);
    80005a24:	854a                	mv	a0,s2
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	16e080e7          	jalr	366(ra) # 80003b94 <iunlockput>
      end_op();
    80005a2e:	fffff097          	auipc	ra,0xfffff
    80005a32:	95c080e7          	jalr	-1700(ra) # 8000438a <end_op>
      return -1;
    80005a36:	54fd                	li	s1,-1
    80005a38:	b76d                	j	800059e2 <sys_open+0xe4>
      end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	950080e7          	jalr	-1712(ra) # 8000438a <end_op>
      return -1;
    80005a42:	54fd                	li	s1,-1
    80005a44:	bf79                	j	800059e2 <sys_open+0xe4>
    iunlockput(ip);
    80005a46:	854a                	mv	a0,s2
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	14c080e7          	jalr	332(ra) # 80003b94 <iunlockput>
    end_op();
    80005a50:	fffff097          	auipc	ra,0xfffff
    80005a54:	93a080e7          	jalr	-1734(ra) # 8000438a <end_op>
    return -1;
    80005a58:	54fd                	li	s1,-1
    80005a5a:	b761                	j	800059e2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a5c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a60:	04e91783          	lh	a5,78(s2)
    80005a64:	02f99223          	sh	a5,36(s3)
    80005a68:	bf2d                	j	800059a2 <sys_open+0xa4>
    itrunc(ip);
    80005a6a:	854a                	mv	a0,s2
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	fd4080e7          	jalr	-44(ra) # 80003a40 <itrunc>
    80005a74:	bfb1                	j	800059d0 <sys_open+0xd2>
      fileclose(f);
    80005a76:	854e                	mv	a0,s3
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	d64080e7          	jalr	-668(ra) # 800047dc <fileclose>
    iunlockput(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	112080e7          	jalr	274(ra) # 80003b94 <iunlockput>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	900080e7          	jalr	-1792(ra) # 8000438a <end_op>
    return -1;
    80005a92:	54fd                	li	s1,-1
    80005a94:	b7b9                	j	800059e2 <sys_open+0xe4>

0000000080005a96 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a96:	7175                	addi	sp,sp,-144
    80005a98:	e506                	sd	ra,136(sp)
    80005a9a:	e122                	sd	s0,128(sp)
    80005a9c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a9e:	fffff097          	auipc	ra,0xfffff
    80005aa2:	86e080e7          	jalr	-1938(ra) # 8000430c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005aa6:	08000613          	li	a2,128
    80005aaa:	f7040593          	addi	a1,s0,-144
    80005aae:	4501                	li	a0,0
    80005ab0:	ffffd097          	auipc	ra,0xffffd
    80005ab4:	354080e7          	jalr	852(ra) # 80002e04 <argstr>
    80005ab8:	02054963          	bltz	a0,80005aea <sys_mkdir+0x54>
    80005abc:	4681                	li	a3,0
    80005abe:	4601                	li	a2,0
    80005ac0:	4585                	li	a1,1
    80005ac2:	f7040513          	addi	a0,s0,-144
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	7fc080e7          	jalr	2044(ra) # 800052c2 <create>
    80005ace:	cd11                	beqz	a0,80005aea <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	0c4080e7          	jalr	196(ra) # 80003b94 <iunlockput>
  end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	8b2080e7          	jalr	-1870(ra) # 8000438a <end_op>
  return 0;
    80005ae0:	4501                	li	a0,0
}
    80005ae2:	60aa                	ld	ra,136(sp)
    80005ae4:	640a                	ld	s0,128(sp)
    80005ae6:	6149                	addi	sp,sp,144
    80005ae8:	8082                	ret
    end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	8a0080e7          	jalr	-1888(ra) # 8000438a <end_op>
    return -1;
    80005af2:	557d                	li	a0,-1
    80005af4:	b7fd                	j	80005ae2 <sys_mkdir+0x4c>

0000000080005af6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005af6:	7135                	addi	sp,sp,-160
    80005af8:	ed06                	sd	ra,152(sp)
    80005afa:	e922                	sd	s0,144(sp)
    80005afc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	80e080e7          	jalr	-2034(ra) # 8000430c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b06:	08000613          	li	a2,128
    80005b0a:	f7040593          	addi	a1,s0,-144
    80005b0e:	4501                	li	a0,0
    80005b10:	ffffd097          	auipc	ra,0xffffd
    80005b14:	2f4080e7          	jalr	756(ra) # 80002e04 <argstr>
    80005b18:	04054a63          	bltz	a0,80005b6c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b1c:	f6c40593          	addi	a1,s0,-148
    80005b20:	4505                	li	a0,1
    80005b22:	ffffd097          	auipc	ra,0xffffd
    80005b26:	29e080e7          	jalr	670(ra) # 80002dc0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b2a:	04054163          	bltz	a0,80005b6c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b2e:	f6840593          	addi	a1,s0,-152
    80005b32:	4509                	li	a0,2
    80005b34:	ffffd097          	auipc	ra,0xffffd
    80005b38:	28c080e7          	jalr	652(ra) # 80002dc0 <argint>
     argint(1, &major) < 0 ||
    80005b3c:	02054863          	bltz	a0,80005b6c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b40:	f6841683          	lh	a3,-152(s0)
    80005b44:	f6c41603          	lh	a2,-148(s0)
    80005b48:	458d                	li	a1,3
    80005b4a:	f7040513          	addi	a0,s0,-144
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	774080e7          	jalr	1908(ra) # 800052c2 <create>
     argint(2, &minor) < 0 ||
    80005b56:	c919                	beqz	a0,80005b6c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	03c080e7          	jalr	60(ra) # 80003b94 <iunlockput>
  end_op();
    80005b60:	fffff097          	auipc	ra,0xfffff
    80005b64:	82a080e7          	jalr	-2006(ra) # 8000438a <end_op>
  return 0;
    80005b68:	4501                	li	a0,0
    80005b6a:	a031                	j	80005b76 <sys_mknod+0x80>
    end_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	81e080e7          	jalr	-2018(ra) # 8000438a <end_op>
    return -1;
    80005b74:	557d                	li	a0,-1
}
    80005b76:	60ea                	ld	ra,152(sp)
    80005b78:	644a                	ld	s0,144(sp)
    80005b7a:	610d                	addi	sp,sp,160
    80005b7c:	8082                	ret

0000000080005b7e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b7e:	7135                	addi	sp,sp,-160
    80005b80:	ed06                	sd	ra,152(sp)
    80005b82:	e922                	sd	s0,144(sp)
    80005b84:	e526                	sd	s1,136(sp)
    80005b86:	e14a                	sd	s2,128(sp)
    80005b88:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b8a:	ffffc097          	auipc	ra,0xffffc
    80005b8e:	176080e7          	jalr	374(ra) # 80001d00 <myproc>
    80005b92:	892a                	mv	s2,a0
  
  begin_op();
    80005b94:	ffffe097          	auipc	ra,0xffffe
    80005b98:	778080e7          	jalr	1912(ra) # 8000430c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b9c:	08000613          	li	a2,128
    80005ba0:	f6040593          	addi	a1,s0,-160
    80005ba4:	4501                	li	a0,0
    80005ba6:	ffffd097          	auipc	ra,0xffffd
    80005baa:	25e080e7          	jalr	606(ra) # 80002e04 <argstr>
    80005bae:	04054b63          	bltz	a0,80005c04 <sys_chdir+0x86>
    80005bb2:	f6040513          	addi	a0,s0,-160
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	536080e7          	jalr	1334(ra) # 800040ec <namei>
    80005bbe:	84aa                	mv	s1,a0
    80005bc0:	c131                	beqz	a0,80005c04 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	d70080e7          	jalr	-656(ra) # 80003932 <ilock>
  if(ip->type != T_DIR){
    80005bca:	04c49703          	lh	a4,76(s1)
    80005bce:	4785                	li	a5,1
    80005bd0:	04f71063          	bne	a4,a5,80005c10 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	e1e080e7          	jalr	-482(ra) # 800039f4 <iunlock>
  iput(p->cwd);
    80005bde:	15893503          	ld	a0,344(s2)
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	f0a080e7          	jalr	-246(ra) # 80003aec <iput>
  end_op();
    80005bea:	ffffe097          	auipc	ra,0xffffe
    80005bee:	7a0080e7          	jalr	1952(ra) # 8000438a <end_op>
  p->cwd = ip;
    80005bf2:	14993c23          	sd	s1,344(s2)
  return 0;
    80005bf6:	4501                	li	a0,0
}
    80005bf8:	60ea                	ld	ra,152(sp)
    80005bfa:	644a                	ld	s0,144(sp)
    80005bfc:	64aa                	ld	s1,136(sp)
    80005bfe:	690a                	ld	s2,128(sp)
    80005c00:	610d                	addi	sp,sp,160
    80005c02:	8082                	ret
    end_op();
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	786080e7          	jalr	1926(ra) # 8000438a <end_op>
    return -1;
    80005c0c:	557d                	li	a0,-1
    80005c0e:	b7ed                	j	80005bf8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c10:	8526                	mv	a0,s1
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	f82080e7          	jalr	-126(ra) # 80003b94 <iunlockput>
    end_op();
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	770080e7          	jalr	1904(ra) # 8000438a <end_op>
    return -1;
    80005c22:	557d                	li	a0,-1
    80005c24:	bfd1                	j	80005bf8 <sys_chdir+0x7a>

0000000080005c26 <sys_exec>:

uint64
sys_exec(void)
{
    80005c26:	7145                	addi	sp,sp,-464
    80005c28:	e786                	sd	ra,456(sp)
    80005c2a:	e3a2                	sd	s0,448(sp)
    80005c2c:	ff26                	sd	s1,440(sp)
    80005c2e:	fb4a                	sd	s2,432(sp)
    80005c30:	f74e                	sd	s3,424(sp)
    80005c32:	f352                	sd	s4,416(sp)
    80005c34:	ef56                	sd	s5,408(sp)
    80005c36:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c38:	08000613          	li	a2,128
    80005c3c:	f4040593          	addi	a1,s0,-192
    80005c40:	4501                	li	a0,0
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	1c2080e7          	jalr	450(ra) # 80002e04 <argstr>
    return -1;
    80005c4a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c4c:	0c054b63          	bltz	a0,80005d22 <sys_exec+0xfc>
    80005c50:	e3840593          	addi	a1,s0,-456
    80005c54:	4505                	li	a0,1
    80005c56:	ffffd097          	auipc	ra,0xffffd
    80005c5a:	18c080e7          	jalr	396(ra) # 80002de2 <argaddr>
    80005c5e:	0c054263          	bltz	a0,80005d22 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005c62:	10000613          	li	a2,256
    80005c66:	4581                	li	a1,0
    80005c68:	e4040513          	addi	a0,s0,-448
    80005c6c:	ffffb097          	auipc	ra,0xffffb
    80005c70:	42e080e7          	jalr	1070(ra) # 8000109a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c74:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c78:	89a6                	mv	s3,s1
    80005c7a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c7c:	02000a13          	li	s4,32
    80005c80:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c84:	00391513          	slli	a0,s2,0x3
    80005c88:	e3040593          	addi	a1,s0,-464
    80005c8c:	e3843783          	ld	a5,-456(s0)
    80005c90:	953e                	add	a0,a0,a5
    80005c92:	ffffd097          	auipc	ra,0xffffd
    80005c96:	094080e7          	jalr	148(ra) # 80002d26 <fetchaddr>
    80005c9a:	02054a63          	bltz	a0,80005cce <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c9e:	e3043783          	ld	a5,-464(s0)
    80005ca2:	c3b9                	beqz	a5,80005ce8 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca4:	ffffb097          	auipc	ra,0xffffb
    80005ca8:	eb4080e7          	jalr	-332(ra) # 80000b58 <kalloc>
    80005cac:	85aa                	mv	a1,a0
    80005cae:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cb2:	cd11                	beqz	a0,80005cce <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb4:	6605                	lui	a2,0x1
    80005cb6:	e3043503          	ld	a0,-464(s0)
    80005cba:	ffffd097          	auipc	ra,0xffffd
    80005cbe:	0be080e7          	jalr	190(ra) # 80002d78 <fetchstr>
    80005cc2:	00054663          	bltz	a0,80005cce <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cc6:	0905                	addi	s2,s2,1
    80005cc8:	09a1                	addi	s3,s3,8
    80005cca:	fb491be3          	bne	s2,s4,80005c80 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cce:	f4040913          	addi	s2,s0,-192
    80005cd2:	6088                	ld	a0,0(s1)
    80005cd4:	c531                	beqz	a0,80005d20 <sys_exec+0xfa>
    kfree(argv[i]);
    80005cd6:	ffffb097          	auipc	ra,0xffffb
    80005cda:	d42080e7          	jalr	-702(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cde:	04a1                	addi	s1,s1,8
    80005ce0:	ff2499e3          	bne	s1,s2,80005cd2 <sys_exec+0xac>
  return -1;
    80005ce4:	597d                	li	s2,-1
    80005ce6:	a835                	j	80005d22 <sys_exec+0xfc>
      argv[i] = 0;
    80005ce8:	0a8e                	slli	s5,s5,0x3
    80005cea:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd6f98>
    80005cee:	00878ab3          	add	s5,a5,s0
    80005cf2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cf6:	e4040593          	addi	a1,s0,-448
    80005cfa:	f4040513          	addi	a0,s0,-192
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	172080e7          	jalr	370(ra) # 80004e70 <exec>
    80005d06:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d08:	f4040993          	addi	s3,s0,-192
    80005d0c:	6088                	ld	a0,0(s1)
    80005d0e:	c911                	beqz	a0,80005d22 <sys_exec+0xfc>
    kfree(argv[i]);
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	d08080e7          	jalr	-760(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d18:	04a1                	addi	s1,s1,8
    80005d1a:	ff3499e3          	bne	s1,s3,80005d0c <sys_exec+0xe6>
    80005d1e:	a011                	j	80005d22 <sys_exec+0xfc>
  return -1;
    80005d20:	597d                	li	s2,-1
}
    80005d22:	854a                	mv	a0,s2
    80005d24:	60be                	ld	ra,456(sp)
    80005d26:	641e                	ld	s0,448(sp)
    80005d28:	74fa                	ld	s1,440(sp)
    80005d2a:	795a                	ld	s2,432(sp)
    80005d2c:	79ba                	ld	s3,424(sp)
    80005d2e:	7a1a                	ld	s4,416(sp)
    80005d30:	6afa                	ld	s5,408(sp)
    80005d32:	6179                	addi	sp,sp,464
    80005d34:	8082                	ret

0000000080005d36 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d36:	7139                	addi	sp,sp,-64
    80005d38:	fc06                	sd	ra,56(sp)
    80005d3a:	f822                	sd	s0,48(sp)
    80005d3c:	f426                	sd	s1,40(sp)
    80005d3e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	fc0080e7          	jalr	-64(ra) # 80001d00 <myproc>
    80005d48:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d4a:	fd840593          	addi	a1,s0,-40
    80005d4e:	4501                	li	a0,0
    80005d50:	ffffd097          	auipc	ra,0xffffd
    80005d54:	092080e7          	jalr	146(ra) # 80002de2 <argaddr>
    return -1;
    80005d58:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d5a:	0e054063          	bltz	a0,80005e3a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d5e:	fc840593          	addi	a1,s0,-56
    80005d62:	fd040513          	addi	a0,s0,-48
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	dcc080e7          	jalr	-564(ra) # 80004b32 <pipealloc>
    return -1;
    80005d6e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d70:	0c054563          	bltz	a0,80005e3a <sys_pipe+0x104>
  fd0 = -1;
    80005d74:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d78:	fd043503          	ld	a0,-48(s0)
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	504080e7          	jalr	1284(ra) # 80005280 <fdalloc>
    80005d84:	fca42223          	sw	a0,-60(s0)
    80005d88:	08054c63          	bltz	a0,80005e20 <sys_pipe+0xea>
    80005d8c:	fc843503          	ld	a0,-56(s0)
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	4f0080e7          	jalr	1264(ra) # 80005280 <fdalloc>
    80005d98:	fca42023          	sw	a0,-64(s0)
    80005d9c:	06054963          	bltz	a0,80005e0e <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da0:	4691                	li	a3,4
    80005da2:	fc440613          	addi	a2,s0,-60
    80005da6:	fd843583          	ld	a1,-40(s0)
    80005daa:	6ca8                	ld	a0,88(s1)
    80005dac:	ffffc097          	auipc	ra,0xffffc
    80005db0:	c4a080e7          	jalr	-950(ra) # 800019f6 <copyout>
    80005db4:	02054063          	bltz	a0,80005dd4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db8:	4691                	li	a3,4
    80005dba:	fc040613          	addi	a2,s0,-64
    80005dbe:	fd843583          	ld	a1,-40(s0)
    80005dc2:	0591                	addi	a1,a1,4
    80005dc4:	6ca8                	ld	a0,88(s1)
    80005dc6:	ffffc097          	auipc	ra,0xffffc
    80005dca:	c30080e7          	jalr	-976(ra) # 800019f6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dce:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dd0:	06055563          	bgez	a0,80005e3a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dd4:	fc442783          	lw	a5,-60(s0)
    80005dd8:	07e9                	addi	a5,a5,26
    80005dda:	078e                	slli	a5,a5,0x3
    80005ddc:	97a6                	add	a5,a5,s1
    80005dde:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005de2:	fc042783          	lw	a5,-64(s0)
    80005de6:	07e9                	addi	a5,a5,26
    80005de8:	078e                	slli	a5,a5,0x3
    80005dea:	00f48533          	add	a0,s1,a5
    80005dee:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005df2:	fd043503          	ld	a0,-48(s0)
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	9e6080e7          	jalr	-1562(ra) # 800047dc <fileclose>
    fileclose(wf);
    80005dfe:	fc843503          	ld	a0,-56(s0)
    80005e02:	fffff097          	auipc	ra,0xfffff
    80005e06:	9da080e7          	jalr	-1574(ra) # 800047dc <fileclose>
    return -1;
    80005e0a:	57fd                	li	a5,-1
    80005e0c:	a03d                	j	80005e3a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e0e:	fc442783          	lw	a5,-60(s0)
    80005e12:	0007c763          	bltz	a5,80005e20 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e16:	07e9                	addi	a5,a5,26
    80005e18:	078e                	slli	a5,a5,0x3
    80005e1a:	97a6                	add	a5,a5,s1
    80005e1c:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005e20:	fd043503          	ld	a0,-48(s0)
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	9b8080e7          	jalr	-1608(ra) # 800047dc <fileclose>
    fileclose(wf);
    80005e2c:	fc843503          	ld	a0,-56(s0)
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	9ac080e7          	jalr	-1620(ra) # 800047dc <fileclose>
    return -1;
    80005e38:	57fd                	li	a5,-1
}
    80005e3a:	853e                	mv	a0,a5
    80005e3c:	70e2                	ld	ra,56(sp)
    80005e3e:	7442                	ld	s0,48(sp)
    80005e40:	74a2                	ld	s1,40(sp)
    80005e42:	6121                	addi	sp,sp,64
    80005e44:	8082                	ret
	...

0000000080005e50 <kernelvec>:
    80005e50:	7111                	addi	sp,sp,-256
    80005e52:	e006                	sd	ra,0(sp)
    80005e54:	e40a                	sd	sp,8(sp)
    80005e56:	e80e                	sd	gp,16(sp)
    80005e58:	ec12                	sd	tp,24(sp)
    80005e5a:	f016                	sd	t0,32(sp)
    80005e5c:	f41a                	sd	t1,40(sp)
    80005e5e:	f81e                	sd	t2,48(sp)
    80005e60:	fc22                	sd	s0,56(sp)
    80005e62:	e0a6                	sd	s1,64(sp)
    80005e64:	e4aa                	sd	a0,72(sp)
    80005e66:	e8ae                	sd	a1,80(sp)
    80005e68:	ecb2                	sd	a2,88(sp)
    80005e6a:	f0b6                	sd	a3,96(sp)
    80005e6c:	f4ba                	sd	a4,104(sp)
    80005e6e:	f8be                	sd	a5,112(sp)
    80005e70:	fcc2                	sd	a6,120(sp)
    80005e72:	e146                	sd	a7,128(sp)
    80005e74:	e54a                	sd	s2,136(sp)
    80005e76:	e94e                	sd	s3,144(sp)
    80005e78:	ed52                	sd	s4,152(sp)
    80005e7a:	f156                	sd	s5,160(sp)
    80005e7c:	f55a                	sd	s6,168(sp)
    80005e7e:	f95e                	sd	s7,176(sp)
    80005e80:	fd62                	sd	s8,184(sp)
    80005e82:	e1e6                	sd	s9,192(sp)
    80005e84:	e5ea                	sd	s10,200(sp)
    80005e86:	e9ee                	sd	s11,208(sp)
    80005e88:	edf2                	sd	t3,216(sp)
    80005e8a:	f1f6                	sd	t4,224(sp)
    80005e8c:	f5fa                	sd	t5,232(sp)
    80005e8e:	f9fe                	sd	t6,240(sp)
    80005e90:	d63fc0ef          	jal	ra,80002bf2 <kerneltrap>
    80005e94:	6082                	ld	ra,0(sp)
    80005e96:	6122                	ld	sp,8(sp)
    80005e98:	61c2                	ld	gp,16(sp)
    80005e9a:	7282                	ld	t0,32(sp)
    80005e9c:	7322                	ld	t1,40(sp)
    80005e9e:	73c2                	ld	t2,48(sp)
    80005ea0:	7462                	ld	s0,56(sp)
    80005ea2:	6486                	ld	s1,64(sp)
    80005ea4:	6526                	ld	a0,72(sp)
    80005ea6:	65c6                	ld	a1,80(sp)
    80005ea8:	6666                	ld	a2,88(sp)
    80005eaa:	7686                	ld	a3,96(sp)
    80005eac:	7726                	ld	a4,104(sp)
    80005eae:	77c6                	ld	a5,112(sp)
    80005eb0:	7866                	ld	a6,120(sp)
    80005eb2:	688a                	ld	a7,128(sp)
    80005eb4:	692a                	ld	s2,136(sp)
    80005eb6:	69ca                	ld	s3,144(sp)
    80005eb8:	6a6a                	ld	s4,152(sp)
    80005eba:	7a8a                	ld	s5,160(sp)
    80005ebc:	7b2a                	ld	s6,168(sp)
    80005ebe:	7bca                	ld	s7,176(sp)
    80005ec0:	7c6a                	ld	s8,184(sp)
    80005ec2:	6c8e                	ld	s9,192(sp)
    80005ec4:	6d2e                	ld	s10,200(sp)
    80005ec6:	6dce                	ld	s11,208(sp)
    80005ec8:	6e6e                	ld	t3,216(sp)
    80005eca:	7e8e                	ld	t4,224(sp)
    80005ecc:	7f2e                	ld	t5,232(sp)
    80005ece:	7fce                	ld	t6,240(sp)
    80005ed0:	6111                	addi	sp,sp,256
    80005ed2:	10200073          	sret
    80005ed6:	00000013          	nop
    80005eda:	00000013          	nop
    80005ede:	0001                	nop

0000000080005ee0 <timervec>:
    80005ee0:	34051573          	csrrw	a0,mscratch,a0
    80005ee4:	e10c                	sd	a1,0(a0)
    80005ee6:	e510                	sd	a2,8(a0)
    80005ee8:	e914                	sd	a3,16(a0)
    80005eea:	6d0c                	ld	a1,24(a0)
    80005eec:	7110                	ld	a2,32(a0)
    80005eee:	6194                	ld	a3,0(a1)
    80005ef0:	96b2                	add	a3,a3,a2
    80005ef2:	e194                	sd	a3,0(a1)
    80005ef4:	4589                	li	a1,2
    80005ef6:	14459073          	csrw	sip,a1
    80005efa:	6914                	ld	a3,16(a0)
    80005efc:	6510                	ld	a2,8(a0)
    80005efe:	610c                	ld	a1,0(a0)
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	30200073          	mret
	...

0000000080005f0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f0a:	1141                	addi	sp,sp,-16
    80005f0c:	e422                	sd	s0,8(sp)
    80005f0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f10:	0c0007b7          	lui	a5,0xc000
    80005f14:	4705                	li	a4,1
    80005f16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f18:	c3d8                	sw	a4,4(a5)
}
    80005f1a:	6422                	ld	s0,8(sp)
    80005f1c:	0141                	addi	sp,sp,16
    80005f1e:	8082                	ret

0000000080005f20 <plicinithart>:

void
plicinithart(void)
{
    80005f20:	1141                	addi	sp,sp,-16
    80005f22:	e406                	sd	ra,8(sp)
    80005f24:	e022                	sd	s0,0(sp)
    80005f26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	dac080e7          	jalr	-596(ra) # 80001cd4 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f30:	0085171b          	slliw	a4,a0,0x8
    80005f34:	0c0027b7          	lui	a5,0xc002
    80005f38:	97ba                	add	a5,a5,a4
    80005f3a:	40200713          	li	a4,1026
    80005f3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f42:	00d5151b          	slliw	a0,a0,0xd
    80005f46:	0c2017b7          	lui	a5,0xc201
    80005f4a:	97aa                	add	a5,a5,a0
    80005f4c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f50:	60a2                	ld	ra,8(sp)
    80005f52:	6402                	ld	s0,0(sp)
    80005f54:	0141                	addi	sp,sp,16
    80005f56:	8082                	ret

0000000080005f58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f58:	1141                	addi	sp,sp,-16
    80005f5a:	e406                	sd	ra,8(sp)
    80005f5c:	e022                	sd	s0,0(sp)
    80005f5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f60:	ffffc097          	auipc	ra,0xffffc
    80005f64:	d74080e7          	jalr	-652(ra) # 80001cd4 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f68:	00d5151b          	slliw	a0,a0,0xd
    80005f6c:	0c2017b7          	lui	a5,0xc201
    80005f70:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f72:	43c8                	lw	a0,4(a5)
    80005f74:	60a2                	ld	ra,8(sp)
    80005f76:	6402                	ld	s0,0(sp)
    80005f78:	0141                	addi	sp,sp,16
    80005f7a:	8082                	ret

0000000080005f7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f7c:	1101                	addi	sp,sp,-32
    80005f7e:	ec06                	sd	ra,24(sp)
    80005f80:	e822                	sd	s0,16(sp)
    80005f82:	e426                	sd	s1,8(sp)
    80005f84:	1000                	addi	s0,sp,32
    80005f86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f88:	ffffc097          	auipc	ra,0xffffc
    80005f8c:	d4c080e7          	jalr	-692(ra) # 80001cd4 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f90:	00d5151b          	slliw	a0,a0,0xd
    80005f94:	0c2017b7          	lui	a5,0xc201
    80005f98:	97aa                	add	a5,a5,a0
    80005f9a:	c3c4                	sw	s1,4(a5)
}
    80005f9c:	60e2                	ld	ra,24(sp)
    80005f9e:	6442                	ld	s0,16(sp)
    80005fa0:	64a2                	ld	s1,8(sp)
    80005fa2:	6105                	addi	sp,sp,32
    80005fa4:	8082                	ret

0000000080005fa6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fa6:	1141                	addi	sp,sp,-16
    80005fa8:	e406                	sd	ra,8(sp)
    80005faa:	e022                	sd	s0,0(sp)
    80005fac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fae:	479d                	li	a5,7
    80005fb0:	06a7c863          	blt	a5,a0,80006020 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80005fb4:	0001e717          	auipc	a4,0x1e
    80005fb8:	04c70713          	addi	a4,a4,76 # 80024000 <disk>
    80005fbc:	972a                	add	a4,a4,a0
    80005fbe:	6789                	lui	a5,0x2
    80005fc0:	97ba                	add	a5,a5,a4
    80005fc2:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fc6:	e7ad                	bnez	a5,80006030 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fc8:	00451793          	slli	a5,a0,0x4
    80005fcc:	00020717          	auipc	a4,0x20
    80005fd0:	03470713          	addi	a4,a4,52 # 80026000 <disk+0x2000>
    80005fd4:	6314                	ld	a3,0(a4)
    80005fd6:	96be                	add	a3,a3,a5
    80005fd8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fdc:	6314                	ld	a3,0(a4)
    80005fde:	96be                	add	a3,a3,a5
    80005fe0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005fe4:	6314                	ld	a3,0(a4)
    80005fe6:	96be                	add	a3,a3,a5
    80005fe8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005fec:	6318                	ld	a4,0(a4)
    80005fee:	97ba                	add	a5,a5,a4
    80005ff0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ff4:	0001e717          	auipc	a4,0x1e
    80005ff8:	00c70713          	addi	a4,a4,12 # 80024000 <disk>
    80005ffc:	972a                	add	a4,a4,a0
    80005ffe:	6789                	lui	a5,0x2
    80006000:	97ba                	add	a5,a5,a4
    80006002:	4705                	li	a4,1
    80006004:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006008:	00020517          	auipc	a0,0x20
    8000600c:	01050513          	addi	a0,a0,16 # 80026018 <disk+0x2018>
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	688080e7          	jalr	1672(ra) # 80002698 <wakeup>
}
    80006018:	60a2                	ld	ra,8(sp)
    8000601a:	6402                	ld	s0,0(sp)
    8000601c:	0141                	addi	sp,sp,16
    8000601e:	8082                	ret
    panic("free_desc 1");
    80006020:	00002517          	auipc	a0,0x2
    80006024:	7c050513          	addi	a0,a0,1984 # 800087e0 <syscalls+0x328>
    80006028:	ffffa097          	auipc	ra,0xffffa
    8000602c:	524080e7          	jalr	1316(ra) # 8000054c <panic>
    panic("free_desc 2");
    80006030:	00002517          	auipc	a0,0x2
    80006034:	7c050513          	addi	a0,a0,1984 # 800087f0 <syscalls+0x338>
    80006038:	ffffa097          	auipc	ra,0xffffa
    8000603c:	514080e7          	jalr	1300(ra) # 8000054c <panic>

0000000080006040 <virtio_disk_init>:
{
    80006040:	1101                	addi	sp,sp,-32
    80006042:	ec06                	sd	ra,24(sp)
    80006044:	e822                	sd	s0,16(sp)
    80006046:	e426                	sd	s1,8(sp)
    80006048:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000604a:	00002597          	auipc	a1,0x2
    8000604e:	7b658593          	addi	a1,a1,1974 # 80008800 <syscalls+0x348>
    80006052:	00020517          	auipc	a0,0x20
    80006056:	0d650513          	addi	a0,a0,214 # 80026128 <disk+0x2128>
    8000605a:	ffffb097          	auipc	ra,0xffffb
    8000605e:	ddc080e7          	jalr	-548(ra) # 80000e36 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006062:	100017b7          	lui	a5,0x10001
    80006066:	4398                	lw	a4,0(a5)
    80006068:	2701                	sext.w	a4,a4
    8000606a:	747277b7          	lui	a5,0x74727
    8000606e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006072:	0ef71063          	bne	a4,a5,80006152 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006076:	100017b7          	lui	a5,0x10001
    8000607a:	43dc                	lw	a5,4(a5)
    8000607c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000607e:	4705                	li	a4,1
    80006080:	0ce79963          	bne	a5,a4,80006152 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	479c                	lw	a5,8(a5)
    8000608a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000608c:	4709                	li	a4,2
    8000608e:	0ce79263          	bne	a5,a4,80006152 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006092:	100017b7          	lui	a5,0x10001
    80006096:	47d8                	lw	a4,12(a5)
    80006098:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000609a:	554d47b7          	lui	a5,0x554d4
    8000609e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060a2:	0af71863          	bne	a4,a5,80006152 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a6:	100017b7          	lui	a5,0x10001
    800060aa:	4705                	li	a4,1
    800060ac:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	470d                	li	a4,3
    800060b0:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060b2:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060b4:	c7ffe6b7          	lui	a3,0xc7ffe
    800060b8:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6737>
    800060bc:	8f75                	and	a4,a4,a3
    800060be:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c0:	472d                	li	a4,11
    800060c2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c4:	473d                	li	a4,15
    800060c6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060c8:	6705                	lui	a4,0x1
    800060ca:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060cc:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060d0:	5bdc                	lw	a5,52(a5)
    800060d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800060d4:	c7d9                	beqz	a5,80006162 <virtio_disk_init+0x122>
  if(max < NUM)
    800060d6:	471d                	li	a4,7
    800060d8:	08f77d63          	bgeu	a4,a5,80006172 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060dc:	100014b7          	lui	s1,0x10001
    800060e0:	47a1                	li	a5,8
    800060e2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060e4:	6609                	lui	a2,0x2
    800060e6:	4581                	li	a1,0
    800060e8:	0001e517          	auipc	a0,0x1e
    800060ec:	f1850513          	addi	a0,a0,-232 # 80024000 <disk>
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	faa080e7          	jalr	-86(ra) # 8000109a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060f8:	0001e717          	auipc	a4,0x1e
    800060fc:	f0870713          	addi	a4,a4,-248 # 80024000 <disk>
    80006100:	00c75793          	srli	a5,a4,0xc
    80006104:	2781                	sext.w	a5,a5
    80006106:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006108:	00020797          	auipc	a5,0x20
    8000610c:	ef878793          	addi	a5,a5,-264 # 80026000 <disk+0x2000>
    80006110:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006112:	0001e717          	auipc	a4,0x1e
    80006116:	f6e70713          	addi	a4,a4,-146 # 80024080 <disk+0x80>
    8000611a:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    8000611c:	0001f717          	auipc	a4,0x1f
    80006120:	ee470713          	addi	a4,a4,-284 # 80025000 <disk+0x1000>
    80006124:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006126:	4705                	li	a4,1
    80006128:	00e78c23          	sb	a4,24(a5)
    8000612c:	00e78ca3          	sb	a4,25(a5)
    80006130:	00e78d23          	sb	a4,26(a5)
    80006134:	00e78da3          	sb	a4,27(a5)
    80006138:	00e78e23          	sb	a4,28(a5)
    8000613c:	00e78ea3          	sb	a4,29(a5)
    80006140:	00e78f23          	sb	a4,30(a5)
    80006144:	00e78fa3          	sb	a4,31(a5)
}
    80006148:	60e2                	ld	ra,24(sp)
    8000614a:	6442                	ld	s0,16(sp)
    8000614c:	64a2                	ld	s1,8(sp)
    8000614e:	6105                	addi	sp,sp,32
    80006150:	8082                	ret
    panic("could not find virtio disk");
    80006152:	00002517          	auipc	a0,0x2
    80006156:	6be50513          	addi	a0,a0,1726 # 80008810 <syscalls+0x358>
    8000615a:	ffffa097          	auipc	ra,0xffffa
    8000615e:	3f2080e7          	jalr	1010(ra) # 8000054c <panic>
    panic("virtio disk has no queue 0");
    80006162:	00002517          	auipc	a0,0x2
    80006166:	6ce50513          	addi	a0,a0,1742 # 80008830 <syscalls+0x378>
    8000616a:	ffffa097          	auipc	ra,0xffffa
    8000616e:	3e2080e7          	jalr	994(ra) # 8000054c <panic>
    panic("virtio disk max queue too short");
    80006172:	00002517          	auipc	a0,0x2
    80006176:	6de50513          	addi	a0,a0,1758 # 80008850 <syscalls+0x398>
    8000617a:	ffffa097          	auipc	ra,0xffffa
    8000617e:	3d2080e7          	jalr	978(ra) # 8000054c <panic>

0000000080006182 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006182:	7119                	addi	sp,sp,-128
    80006184:	fc86                	sd	ra,120(sp)
    80006186:	f8a2                	sd	s0,112(sp)
    80006188:	f4a6                	sd	s1,104(sp)
    8000618a:	f0ca                	sd	s2,96(sp)
    8000618c:	ecce                	sd	s3,88(sp)
    8000618e:	e8d2                	sd	s4,80(sp)
    80006190:	e4d6                	sd	s5,72(sp)
    80006192:	e0da                	sd	s6,64(sp)
    80006194:	fc5e                	sd	s7,56(sp)
    80006196:	f862                	sd	s8,48(sp)
    80006198:	f466                	sd	s9,40(sp)
    8000619a:	f06a                	sd	s10,32(sp)
    8000619c:	ec6e                	sd	s11,24(sp)
    8000619e:	0100                	addi	s0,sp,128
    800061a0:	8aaa                	mv	s5,a0
    800061a2:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061a4:	00c52c83          	lw	s9,12(a0)
    800061a8:	001c9c9b          	slliw	s9,s9,0x1
    800061ac:	1c82                	slli	s9,s9,0x20
    800061ae:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061b2:	00020517          	auipc	a0,0x20
    800061b6:	f7650513          	addi	a0,a0,-138 # 80026128 <disk+0x2128>
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	b00080e7          	jalr	-1280(ra) # 80000cba <acquire>
  for(int i = 0; i < 3; i++){
    800061c2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061c4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061c6:	0001ec17          	auipc	s8,0x1e
    800061ca:	e3ac0c13          	addi	s8,s8,-454 # 80024000 <disk>
    800061ce:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061d0:	4b0d                	li	s6,3
    800061d2:	a0ad                	j	8000623c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061d4:	00fc0733          	add	a4,s8,a5
    800061d8:	975e                	add	a4,a4,s7
    800061da:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061de:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061e0:	0207c563          	bltz	a5,8000620a <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061e4:	2905                	addiw	s2,s2,1
    800061e6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800061e8:	19690c63          	beq	s2,s6,80006380 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800061ec:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061ee:	00020717          	auipc	a4,0x20
    800061f2:	e2a70713          	addi	a4,a4,-470 # 80026018 <disk+0x2018>
    800061f6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800061f8:	00074683          	lbu	a3,0(a4)
    800061fc:	fee1                	bnez	a3,800061d4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061fe:	2785                	addiw	a5,a5,1
    80006200:	0705                	addi	a4,a4,1
    80006202:	fe979be3          	bne	a5,s1,800061f8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006206:	57fd                	li	a5,-1
    80006208:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000620a:	01205d63          	blez	s2,80006224 <virtio_disk_rw+0xa2>
    8000620e:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006210:	000a2503          	lw	a0,0(s4)
    80006214:	00000097          	auipc	ra,0x0
    80006218:	d92080e7          	jalr	-622(ra) # 80005fa6 <free_desc>
      for(int j = 0; j < i; j++)
    8000621c:	2d85                	addiw	s11,s11,1
    8000621e:	0a11                	addi	s4,s4,4
    80006220:	ff2d98e3          	bne	s11,s2,80006210 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006224:	00020597          	auipc	a1,0x20
    80006228:	f0458593          	addi	a1,a1,-252 # 80026128 <disk+0x2128>
    8000622c:	00020517          	auipc	a0,0x20
    80006230:	dec50513          	addi	a0,a0,-532 # 80026018 <disk+0x2018>
    80006234:	ffffc097          	auipc	ra,0xffffc
    80006238:	2e4080e7          	jalr	740(ra) # 80002518 <sleep>
  for(int i = 0; i < 3; i++){
    8000623c:	f8040a13          	addi	s4,s0,-128
{
    80006240:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006242:	894e                	mv	s2,s3
    80006244:	b765                	j	800061ec <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006246:	00020697          	auipc	a3,0x20
    8000624a:	dba6b683          	ld	a3,-582(a3) # 80026000 <disk+0x2000>
    8000624e:	96ba                	add	a3,a3,a4
    80006250:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006254:	0001e817          	auipc	a6,0x1e
    80006258:	dac80813          	addi	a6,a6,-596 # 80024000 <disk>
    8000625c:	00020697          	auipc	a3,0x20
    80006260:	da468693          	addi	a3,a3,-604 # 80026000 <disk+0x2000>
    80006264:	6290                	ld	a2,0(a3)
    80006266:	963a                	add	a2,a2,a4
    80006268:	00c65583          	lhu	a1,12(a2)
    8000626c:	0015e593          	ori	a1,a1,1
    80006270:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006274:	f8842603          	lw	a2,-120(s0)
    80006278:	628c                	ld	a1,0(a3)
    8000627a:	972e                	add	a4,a4,a1
    8000627c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006280:	20050593          	addi	a1,a0,512
    80006284:	0592                	slli	a1,a1,0x4
    80006286:	95c2                	add	a1,a1,a6
    80006288:	577d                	li	a4,-1
    8000628a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000628e:	00461713          	slli	a4,a2,0x4
    80006292:	6290                	ld	a2,0(a3)
    80006294:	963a                	add	a2,a2,a4
    80006296:	03078793          	addi	a5,a5,48
    8000629a:	97c2                	add	a5,a5,a6
    8000629c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000629e:	629c                	ld	a5,0(a3)
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	4605                	li	a2,1
    800062a4:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062a6:	629c                	ld	a5,0(a3)
    800062a8:	97ba                	add	a5,a5,a4
    800062aa:	4809                	li	a6,2
    800062ac:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800062b0:	629c                	ld	a5,0(a3)
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062b8:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800062bc:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062c0:	6698                	ld	a4,8(a3)
    800062c2:	00275783          	lhu	a5,2(a4)
    800062c6:	8b9d                	andi	a5,a5,7
    800062c8:	0786                	slli	a5,a5,0x1
    800062ca:	973e                	add	a4,a4,a5
    800062cc:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800062d0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062d4:	6698                	ld	a4,8(a3)
    800062d6:	00275783          	lhu	a5,2(a4)
    800062da:	2785                	addiw	a5,a5,1
    800062dc:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062e0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062ec:	004aa783          	lw	a5,4(s5)
    800062f0:	02c79163          	bne	a5,a2,80006312 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062f4:	00020917          	auipc	s2,0x20
    800062f8:	e3490913          	addi	s2,s2,-460 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800062fc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062fe:	85ca                	mv	a1,s2
    80006300:	8556                	mv	a0,s5
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	216080e7          	jalr	534(ra) # 80002518 <sleep>
  while(b->disk == 1) {
    8000630a:	004aa783          	lw	a5,4(s5)
    8000630e:	fe9788e3          	beq	a5,s1,800062fe <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006312:	f8042903          	lw	s2,-128(s0)
    80006316:	20090713          	addi	a4,s2,512
    8000631a:	0712                	slli	a4,a4,0x4
    8000631c:	0001e797          	auipc	a5,0x1e
    80006320:	ce478793          	addi	a5,a5,-796 # 80024000 <disk>
    80006324:	97ba                	add	a5,a5,a4
    80006326:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000632a:	00020997          	auipc	s3,0x20
    8000632e:	cd698993          	addi	s3,s3,-810 # 80026000 <disk+0x2000>
    80006332:	00491713          	slli	a4,s2,0x4
    80006336:	0009b783          	ld	a5,0(s3)
    8000633a:	97ba                	add	a5,a5,a4
    8000633c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006340:	854a                	mv	a0,s2
    80006342:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	c60080e7          	jalr	-928(ra) # 80005fa6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000634e:	8885                	andi	s1,s1,1
    80006350:	f0ed                	bnez	s1,80006332 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006352:	00020517          	auipc	a0,0x20
    80006356:	dd650513          	addi	a0,a0,-554 # 80026128 <disk+0x2128>
    8000635a:	ffffb097          	auipc	ra,0xffffb
    8000635e:	a30080e7          	jalr	-1488(ra) # 80000d8a <release>
}
    80006362:	70e6                	ld	ra,120(sp)
    80006364:	7446                	ld	s0,112(sp)
    80006366:	74a6                	ld	s1,104(sp)
    80006368:	7906                	ld	s2,96(sp)
    8000636a:	69e6                	ld	s3,88(sp)
    8000636c:	6a46                	ld	s4,80(sp)
    8000636e:	6aa6                	ld	s5,72(sp)
    80006370:	6b06                	ld	s6,64(sp)
    80006372:	7be2                	ld	s7,56(sp)
    80006374:	7c42                	ld	s8,48(sp)
    80006376:	7ca2                	ld	s9,40(sp)
    80006378:	7d02                	ld	s10,32(sp)
    8000637a:	6de2                	ld	s11,24(sp)
    8000637c:	6109                	addi	sp,sp,128
    8000637e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006380:	f8042503          	lw	a0,-128(s0)
    80006384:	20050793          	addi	a5,a0,512
    80006388:	0792                	slli	a5,a5,0x4
  if(write)
    8000638a:	0001e817          	auipc	a6,0x1e
    8000638e:	c7680813          	addi	a6,a6,-906 # 80024000 <disk>
    80006392:	00f80733          	add	a4,a6,a5
    80006396:	01a036b3          	snez	a3,s10
    8000639a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000639e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800063a2:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063a6:	7679                	lui	a2,0xffffe
    800063a8:	963e                	add	a2,a2,a5
    800063aa:	00020697          	auipc	a3,0x20
    800063ae:	c5668693          	addi	a3,a3,-938 # 80026000 <disk+0x2000>
    800063b2:	6298                	ld	a4,0(a3)
    800063b4:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063b6:	0a878593          	addi	a1,a5,168
    800063ba:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800063bc:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800063be:	6298                	ld	a4,0(a3)
    800063c0:	9732                	add	a4,a4,a2
    800063c2:	45c1                	li	a1,16
    800063c4:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063c6:	6298                	ld	a4,0(a3)
    800063c8:	9732                	add	a4,a4,a2
    800063ca:	4585                	li	a1,1
    800063cc:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800063d0:	f8442703          	lw	a4,-124(s0)
    800063d4:	628c                	ld	a1,0(a3)
    800063d6:	962e                	add	a2,a2,a1
    800063d8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd5fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063dc:	0712                	slli	a4,a4,0x4
    800063de:	6290                	ld	a2,0(a3)
    800063e0:	963a                	add	a2,a2,a4
    800063e2:	060a8593          	addi	a1,s5,96
    800063e6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800063e8:	6294                	ld	a3,0(a3)
    800063ea:	96ba                	add	a3,a3,a4
    800063ec:	40000613          	li	a2,1024
    800063f0:	c690                	sw	a2,8(a3)
  if(write)
    800063f2:	e40d1ae3          	bnez	s10,80006246 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063f6:	00020697          	auipc	a3,0x20
    800063fa:	c0a6b683          	ld	a3,-1014(a3) # 80026000 <disk+0x2000>
    800063fe:	96ba                	add	a3,a3,a4
    80006400:	4609                	li	a2,2
    80006402:	00c69623          	sh	a2,12(a3)
    80006406:	b5b9                	j	80006254 <virtio_disk_rw+0xd2>

0000000080006408 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006408:	1101                	addi	sp,sp,-32
    8000640a:	ec06                	sd	ra,24(sp)
    8000640c:	e822                	sd	s0,16(sp)
    8000640e:	e426                	sd	s1,8(sp)
    80006410:	e04a                	sd	s2,0(sp)
    80006412:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006414:	00020517          	auipc	a0,0x20
    80006418:	d1450513          	addi	a0,a0,-748 # 80026128 <disk+0x2128>
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	89e080e7          	jalr	-1890(ra) # 80000cba <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006424:	10001737          	lui	a4,0x10001
    80006428:	533c                	lw	a5,96(a4)
    8000642a:	8b8d                	andi	a5,a5,3
    8000642c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000642e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006432:	00020797          	auipc	a5,0x20
    80006436:	bce78793          	addi	a5,a5,-1074 # 80026000 <disk+0x2000>
    8000643a:	6b94                	ld	a3,16(a5)
    8000643c:	0207d703          	lhu	a4,32(a5)
    80006440:	0026d783          	lhu	a5,2(a3)
    80006444:	06f70163          	beq	a4,a5,800064a6 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006448:	0001e917          	auipc	s2,0x1e
    8000644c:	bb890913          	addi	s2,s2,-1096 # 80024000 <disk>
    80006450:	00020497          	auipc	s1,0x20
    80006454:	bb048493          	addi	s1,s1,-1104 # 80026000 <disk+0x2000>
    __sync_synchronize();
    80006458:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000645c:	6898                	ld	a4,16(s1)
    8000645e:	0204d783          	lhu	a5,32(s1)
    80006462:	8b9d                	andi	a5,a5,7
    80006464:	078e                	slli	a5,a5,0x3
    80006466:	97ba                	add	a5,a5,a4
    80006468:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000646a:	20078713          	addi	a4,a5,512
    8000646e:	0712                	slli	a4,a4,0x4
    80006470:	974a                	add	a4,a4,s2
    80006472:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006476:	e731                	bnez	a4,800064c2 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006478:	20078793          	addi	a5,a5,512
    8000647c:	0792                	slli	a5,a5,0x4
    8000647e:	97ca                	add	a5,a5,s2
    80006480:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006482:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006486:	ffffc097          	auipc	ra,0xffffc
    8000648a:	212080e7          	jalr	530(ra) # 80002698 <wakeup>

    disk.used_idx += 1;
    8000648e:	0204d783          	lhu	a5,32(s1)
    80006492:	2785                	addiw	a5,a5,1
    80006494:	17c2                	slli	a5,a5,0x30
    80006496:	93c1                	srli	a5,a5,0x30
    80006498:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000649c:	6898                	ld	a4,16(s1)
    8000649e:	00275703          	lhu	a4,2(a4)
    800064a2:	faf71be3          	bne	a4,a5,80006458 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800064a6:	00020517          	auipc	a0,0x20
    800064aa:	c8250513          	addi	a0,a0,-894 # 80026128 <disk+0x2128>
    800064ae:	ffffb097          	auipc	ra,0xffffb
    800064b2:	8dc080e7          	jalr	-1828(ra) # 80000d8a <release>
}
    800064b6:	60e2                	ld	ra,24(sp)
    800064b8:	6442                	ld	s0,16(sp)
    800064ba:	64a2                	ld	s1,8(sp)
    800064bc:	6902                	ld	s2,0(sp)
    800064be:	6105                	addi	sp,sp,32
    800064c0:	8082                	ret
      panic("virtio_disk_intr status");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	3ae50513          	addi	a0,a0,942 # 80008870 <syscalls+0x3b8>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	082080e7          	jalr	130(ra) # 8000054c <panic>

00000000800064d2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800064d2:	1141                	addi	sp,sp,-16
    800064d4:	e422                	sd	s0,8(sp)
    800064d6:	0800                	addi	s0,sp,16
  return -1;
}
    800064d8:	557d                	li	a0,-1
    800064da:	6422                	ld	s0,8(sp)
    800064dc:	0141                	addi	sp,sp,16
    800064de:	8082                	ret

00000000800064e0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800064e0:	7179                	addi	sp,sp,-48
    800064e2:	f406                	sd	ra,40(sp)
    800064e4:	f022                	sd	s0,32(sp)
    800064e6:	ec26                	sd	s1,24(sp)
    800064e8:	e84a                	sd	s2,16(sp)
    800064ea:	e44e                	sd	s3,8(sp)
    800064ec:	e052                	sd	s4,0(sp)
    800064ee:	1800                	addi	s0,sp,48
    800064f0:	892a                	mv	s2,a0
    800064f2:	89ae                	mv	s3,a1
    800064f4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800064f6:	00021517          	auipc	a0,0x21
    800064fa:	b0a50513          	addi	a0,a0,-1270 # 80027000 <stats>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	7bc080e7          	jalr	1980(ra) # 80000cba <acquire>

  if(stats.sz == 0) {
    80006506:	00022797          	auipc	a5,0x22
    8000650a:	b1a7a783          	lw	a5,-1254(a5) # 80028020 <stats+0x1020>
    8000650e:	cbb5                	beqz	a5,80006582 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006510:	00022797          	auipc	a5,0x22
    80006514:	af078793          	addi	a5,a5,-1296 # 80028000 <stats+0x1000>
    80006518:	53d8                	lw	a4,36(a5)
    8000651a:	539c                	lw	a5,32(a5)
    8000651c:	9f99                	subw	a5,a5,a4
    8000651e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006522:	06d05e63          	blez	a3,8000659e <statsread+0xbe>
    if(m > n)
    80006526:	8a3e                	mv	s4,a5
    80006528:	00d4d363          	bge	s1,a3,8000652e <statsread+0x4e>
    8000652c:	8a26                	mv	s4,s1
    8000652e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006532:	86a6                	mv	a3,s1
    80006534:	00021617          	auipc	a2,0x21
    80006538:	aec60613          	addi	a2,a2,-1300 # 80027020 <stats+0x20>
    8000653c:	963a                	add	a2,a2,a4
    8000653e:	85ce                	mv	a1,s3
    80006540:	854a                	mv	a0,s2
    80006542:	ffffc097          	auipc	ra,0xffffc
    80006546:	230080e7          	jalr	560(ra) # 80002772 <either_copyout>
    8000654a:	57fd                	li	a5,-1
    8000654c:	00f50a63          	beq	a0,a5,80006560 <statsread+0x80>
      stats.off += m;
    80006550:	00022717          	auipc	a4,0x22
    80006554:	ab070713          	addi	a4,a4,-1360 # 80028000 <stats+0x1000>
    80006558:	535c                	lw	a5,36(a4)
    8000655a:	00fa07bb          	addw	a5,s4,a5
    8000655e:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006560:	00021517          	auipc	a0,0x21
    80006564:	aa050513          	addi	a0,a0,-1376 # 80027000 <stats>
    80006568:	ffffb097          	auipc	ra,0xffffb
    8000656c:	822080e7          	jalr	-2014(ra) # 80000d8a <release>
  return m;
}
    80006570:	8526                	mv	a0,s1
    80006572:	70a2                	ld	ra,40(sp)
    80006574:	7402                	ld	s0,32(sp)
    80006576:	64e2                	ld	s1,24(sp)
    80006578:	6942                	ld	s2,16(sp)
    8000657a:	69a2                	ld	s3,8(sp)
    8000657c:	6a02                	ld	s4,0(sp)
    8000657e:	6145                	addi	sp,sp,48
    80006580:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006582:	6585                	lui	a1,0x1
    80006584:	00021517          	auipc	a0,0x21
    80006588:	a9c50513          	addi	a0,a0,-1380 # 80027020 <stats+0x20>
    8000658c:	ffffb097          	auipc	ra,0xffffb
    80006590:	958080e7          	jalr	-1704(ra) # 80000ee4 <statslock>
    80006594:	00022797          	auipc	a5,0x22
    80006598:	a8a7a623          	sw	a0,-1396(a5) # 80028020 <stats+0x1020>
    8000659c:	bf95                	j	80006510 <statsread+0x30>
    stats.sz = 0;
    8000659e:	00022797          	auipc	a5,0x22
    800065a2:	a6278793          	addi	a5,a5,-1438 # 80028000 <stats+0x1000>
    800065a6:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    800065aa:	0207a223          	sw	zero,36(a5)
    m = -1;
    800065ae:	54fd                	li	s1,-1
    800065b0:	bf45                	j	80006560 <statsread+0x80>

00000000800065b2 <statsinit>:

void
statsinit(void)
{
    800065b2:	1141                	addi	sp,sp,-16
    800065b4:	e406                	sd	ra,8(sp)
    800065b6:	e022                	sd	s0,0(sp)
    800065b8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800065ba:	00002597          	auipc	a1,0x2
    800065be:	2ce58593          	addi	a1,a1,718 # 80008888 <syscalls+0x3d0>
    800065c2:	00021517          	auipc	a0,0x21
    800065c6:	a3e50513          	addi	a0,a0,-1474 # 80027000 <stats>
    800065ca:	ffffb097          	auipc	ra,0xffffb
    800065ce:	86c080e7          	jalr	-1940(ra) # 80000e36 <initlock>

  devsw[STATS].read = statsread;
    800065d2:	0001c797          	auipc	a5,0x1c
    800065d6:	2c678793          	addi	a5,a5,710 # 80022898 <devsw>
    800065da:	00000717          	auipc	a4,0x0
    800065de:	f0670713          	addi	a4,a4,-250 # 800064e0 <statsread>
    800065e2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800065e4:	00000717          	auipc	a4,0x0
    800065e8:	eee70713          	addi	a4,a4,-274 # 800064d2 <statswrite>
    800065ec:	f798                	sd	a4,40(a5)
}
    800065ee:	60a2                	ld	ra,8(sp)
    800065f0:	6402                	ld	s0,0(sp)
    800065f2:	0141                	addi	sp,sp,16
    800065f4:	8082                	ret

00000000800065f6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800065f6:	1101                	addi	sp,sp,-32
    800065f8:	ec22                	sd	s0,24(sp)
    800065fa:	1000                	addi	s0,sp,32
    800065fc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800065fe:	c299                	beqz	a3,80006604 <sprintint+0xe>
    80006600:	0805c263          	bltz	a1,80006684 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    80006604:	2581                	sext.w	a1,a1
    80006606:	4301                	li	t1,0

  i = 0;
    80006608:	fe040713          	addi	a4,s0,-32
    8000660c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000660e:	2601                	sext.w	a2,a2
    80006610:	00002697          	auipc	a3,0x2
    80006614:	28068693          	addi	a3,a3,640 # 80008890 <digits>
    80006618:	88aa                	mv	a7,a0
    8000661a:	2505                	addiw	a0,a0,1
    8000661c:	02c5f7bb          	remuw	a5,a1,a2
    80006620:	1782                	slli	a5,a5,0x20
    80006622:	9381                	srli	a5,a5,0x20
    80006624:	97b6                	add	a5,a5,a3
    80006626:	0007c783          	lbu	a5,0(a5)
    8000662a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000662e:	0005879b          	sext.w	a5,a1
    80006632:	02c5d5bb          	divuw	a1,a1,a2
    80006636:	0705                	addi	a4,a4,1
    80006638:	fec7f0e3          	bgeu	a5,a2,80006618 <sprintint+0x22>

  if(sign)
    8000663c:	00030b63          	beqz	t1,80006652 <sprintint+0x5c>
    buf[i++] = '-';
    80006640:	ff050793          	addi	a5,a0,-16
    80006644:	97a2                	add	a5,a5,s0
    80006646:	02d00713          	li	a4,45
    8000664a:	fee78823          	sb	a4,-16(a5)
    8000664e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006652:	02a05d63          	blez	a0,8000668c <sprintint+0x96>
    80006656:	fe040793          	addi	a5,s0,-32
    8000665a:	00a78733          	add	a4,a5,a0
    8000665e:	87c2                	mv	a5,a6
    80006660:	00180613          	addi	a2,a6,1
    80006664:	fff5069b          	addiw	a3,a0,-1
    80006668:	1682                	slli	a3,a3,0x20
    8000666a:	9281                	srli	a3,a3,0x20
    8000666c:	9636                	add	a2,a2,a3
  *s = c;
    8000666e:	fff74683          	lbu	a3,-1(a4)
    80006672:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006676:	177d                	addi	a4,a4,-1
    80006678:	0785                	addi	a5,a5,1
    8000667a:	fec79ae3          	bne	a5,a2,8000666e <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000667e:	6462                	ld	s0,24(sp)
    80006680:	6105                	addi	sp,sp,32
    80006682:	8082                	ret
    x = -xx;
    80006684:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006688:	4305                	li	t1,1
    x = -xx;
    8000668a:	bfbd                	j	80006608 <sprintint+0x12>
  while(--i >= 0)
    8000668c:	4501                	li	a0,0
    8000668e:	bfc5                	j	8000667e <sprintint+0x88>

0000000080006690 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006690:	7135                	addi	sp,sp,-160
    80006692:	f486                	sd	ra,104(sp)
    80006694:	f0a2                	sd	s0,96(sp)
    80006696:	eca6                	sd	s1,88(sp)
    80006698:	e8ca                	sd	s2,80(sp)
    8000669a:	e4ce                	sd	s3,72(sp)
    8000669c:	e0d2                	sd	s4,64(sp)
    8000669e:	fc56                	sd	s5,56(sp)
    800066a0:	f85a                	sd	s6,48(sp)
    800066a2:	f45e                	sd	s7,40(sp)
    800066a4:	f062                	sd	s8,32(sp)
    800066a6:	ec66                	sd	s9,24(sp)
    800066a8:	e86a                	sd	s10,16(sp)
    800066aa:	1880                	addi	s0,sp,112
    800066ac:	e414                	sd	a3,8(s0)
    800066ae:	e818                	sd	a4,16(s0)
    800066b0:	ec1c                	sd	a5,24(s0)
    800066b2:	03043023          	sd	a6,32(s0)
    800066b6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800066ba:	c61d                	beqz	a2,800066e8 <snprintf+0x58>
    800066bc:	8baa                	mv	s7,a0
    800066be:	89ae                	mv	s3,a1
    800066c0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800066c2:	00840793          	addi	a5,s0,8
    800066c6:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    800066ca:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800066cc:	4901                	li	s2,0
    800066ce:	02b05563          	blez	a1,800066f8 <snprintf+0x68>
    if(c != '%'){
    800066d2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800066d6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800066da:	02800d13          	li	s10,40
    switch(c){
    800066de:	07800c93          	li	s9,120
    800066e2:	06400c13          	li	s8,100
    800066e6:	a01d                	j	8000670c <snprintf+0x7c>
    panic("null fmt");
    800066e8:	00002517          	auipc	a0,0x2
    800066ec:	94050513          	addi	a0,a0,-1728 # 80008028 <etext+0x28>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	e5c080e7          	jalr	-420(ra) # 8000054c <panic>
  int off = 0;
    800066f8:	4481                	li	s1,0
    800066fa:	a875                	j	800067b6 <snprintf+0x126>
  *s = c;
    800066fc:	009b8733          	add	a4,s7,s1
    80006700:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006704:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006706:	2905                	addiw	s2,s2,1
    80006708:	0b34d763          	bge	s1,s3,800067b6 <snprintf+0x126>
    8000670c:	012a07b3          	add	a5,s4,s2
    80006710:	0007c783          	lbu	a5,0(a5)
    80006714:	0007871b          	sext.w	a4,a5
    80006718:	cfd9                	beqz	a5,800067b6 <snprintf+0x126>
    if(c != '%'){
    8000671a:	ff5711e3          	bne	a4,s5,800066fc <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    8000671e:	2905                	addiw	s2,s2,1
    80006720:	012a07b3          	add	a5,s4,s2
    80006724:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    80006728:	c7d9                	beqz	a5,800067b6 <snprintf+0x126>
    switch(c){
    8000672a:	05678c63          	beq	a5,s6,80006782 <snprintf+0xf2>
    8000672e:	02fb6763          	bltu	s6,a5,8000675c <snprintf+0xcc>
    80006732:	0b578763          	beq	a5,s5,800067e0 <snprintf+0x150>
    80006736:	0b879b63          	bne	a5,s8,800067ec <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000673a:	f9843783          	ld	a5,-104(s0)
    8000673e:	00878713          	addi	a4,a5,8
    80006742:	f8e43c23          	sd	a4,-104(s0)
    80006746:	4685                	li	a3,1
    80006748:	4629                	li	a2,10
    8000674a:	438c                	lw	a1,0(a5)
    8000674c:	009b8533          	add	a0,s7,s1
    80006750:	00000097          	auipc	ra,0x0
    80006754:	ea6080e7          	jalr	-346(ra) # 800065f6 <sprintint>
    80006758:	9ca9                	addw	s1,s1,a0
      break;
    8000675a:	b775                	j	80006706 <snprintf+0x76>
    switch(c){
    8000675c:	09979863          	bne	a5,s9,800067ec <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006760:	f9843783          	ld	a5,-104(s0)
    80006764:	00878713          	addi	a4,a5,8
    80006768:	f8e43c23          	sd	a4,-104(s0)
    8000676c:	4685                	li	a3,1
    8000676e:	4641                	li	a2,16
    80006770:	438c                	lw	a1,0(a5)
    80006772:	009b8533          	add	a0,s7,s1
    80006776:	00000097          	auipc	ra,0x0
    8000677a:	e80080e7          	jalr	-384(ra) # 800065f6 <sprintint>
    8000677e:	9ca9                	addw	s1,s1,a0
      break;
    80006780:	b759                	j	80006706 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    80006782:	f9843783          	ld	a5,-104(s0)
    80006786:	00878713          	addi	a4,a5,8
    8000678a:	f8e43c23          	sd	a4,-104(s0)
    8000678e:	639c                	ld	a5,0(a5)
    80006790:	c3b1                	beqz	a5,800067d4 <snprintf+0x144>
      for(; *s && off < sz; s++)
    80006792:	0007c703          	lbu	a4,0(a5)
    80006796:	db25                	beqz	a4,80006706 <snprintf+0x76>
    80006798:	0734d563          	bge	s1,s3,80006802 <snprintf+0x172>
    8000679c:	009b86b3          	add	a3,s7,s1
  *s = c;
    800067a0:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800067a4:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800067a6:	0785                	addi	a5,a5,1
    800067a8:	0007c703          	lbu	a4,0(a5)
    800067ac:	df29                	beqz	a4,80006706 <snprintf+0x76>
    800067ae:	0685                	addi	a3,a3,1
    800067b0:	fe9998e3          	bne	s3,s1,800067a0 <snprintf+0x110>
  int off = 0;
    800067b4:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800067b6:	8526                	mv	a0,s1
    800067b8:	70a6                	ld	ra,104(sp)
    800067ba:	7406                	ld	s0,96(sp)
    800067bc:	64e6                	ld	s1,88(sp)
    800067be:	6946                	ld	s2,80(sp)
    800067c0:	69a6                	ld	s3,72(sp)
    800067c2:	6a06                	ld	s4,64(sp)
    800067c4:	7ae2                	ld	s5,56(sp)
    800067c6:	7b42                	ld	s6,48(sp)
    800067c8:	7ba2                	ld	s7,40(sp)
    800067ca:	7c02                	ld	s8,32(sp)
    800067cc:	6ce2                	ld	s9,24(sp)
    800067ce:	6d42                	ld	s10,16(sp)
    800067d0:	610d                	addi	sp,sp,160
    800067d2:	8082                	ret
        s = "(null)";
    800067d4:	00002797          	auipc	a5,0x2
    800067d8:	84c78793          	addi	a5,a5,-1972 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800067dc:	876a                	mv	a4,s10
    800067de:	bf6d                	j	80006798 <snprintf+0x108>
  *s = c;
    800067e0:	009b87b3          	add	a5,s7,s1
    800067e4:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800067e8:	2485                	addiw	s1,s1,1
      break;
    800067ea:	bf31                	j	80006706 <snprintf+0x76>
  *s = c;
    800067ec:	009b8733          	add	a4,s7,s1
    800067f0:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800067f4:	0014871b          	addiw	a4,s1,1
  *s = c;
    800067f8:	975e                	add	a4,a4,s7
    800067fa:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800067fe:	2489                	addiw	s1,s1,2
      break;
    80006800:	b719                	j	80006706 <snprintf+0x76>
      for(; *s && off < sz; s++)
    80006802:	89a6                	mv	s3,s1
    80006804:	bf45                	j	800067b4 <snprintf+0x124>
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
