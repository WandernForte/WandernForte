
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
    80000066:	04e78793          	addi	a5,a5,78 # 800060b0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd17d7>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	1c478793          	addi	a5,a5,452 # 80001270 <main>
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
    80000116:	bd0080e7          	jalr	-1072(ra) # 80000ce2 <acquire>
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
    80000130:	6c4080e7          	jalr	1732(ra) # 800027f0 <either_copyin>
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
    8000015a:	c5c080e7          	jalr	-932(ra) # 80000db2 <release>

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
    800001a8:	b3e080e7          	jalr	-1218(ra) # 80000ce2 <acquire>
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
    800001d6:	b56080e7          	jalr	-1194(ra) # 80001d28 <myproc>
    800001da:	5d1c                	lw	a5,56(a0)
    800001dc:	e7b5                	bnez	a5,80000248 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001de:	85a6                	mv	a1,s1
    800001e0:	854a                	mv	a0,s2
    800001e2:	00002097          	auipc	ra,0x2
    800001e6:	35e080e7          	jalr	862(ra) # 80002540 <sleep>
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
    80000222:	57c080e7          	jalr	1404(ra) # 8000279a <either_copyout>
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
    8000023e:	b78080e7          	jalr	-1160(ra) # 80000db2 <release>

  return target - n;
    80000242:	413b053b          	subw	a0,s6,s3
    80000246:	a811                	j	8000025a <consoleread+0xe4>
        release(&cons.lock);
    80000248:	00011517          	auipc	a0,0x11
    8000024c:	f2850513          	addi	a0,a0,-216 # 80011170 <cons>
    80000250:	00001097          	auipc	ra,0x1
    80000254:	b62080e7          	jalr	-1182(ra) # 80000db2 <release>
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
    800002e4:	a02080e7          	jalr	-1534(ra) # 80000ce2 <acquire>

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
    80000302:	548080e7          	jalr	1352(ra) # 80002846 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000306:	00011517          	auipc	a0,0x11
    8000030a:	e6a50513          	addi	a0,a0,-406 # 80011170 <cons>
    8000030e:	00001097          	auipc	ra,0x1
    80000312:	aa4080e7          	jalr	-1372(ra) # 80000db2 <release>
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
    80000456:	26e080e7          	jalr	622(ra) # 800026c0 <wakeup>
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
    80000478:	9ea080e7          	jalr	-1558(ra) # 80000e5e <initlock>

  uartinit();
    8000047c:	00000097          	auipc	ra,0x0
    80000480:	32c080e7          	jalr	812(ra) # 800007a8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000484:	00027797          	auipc	a5,0x27
    80000488:	c1478793          	addi	a5,a5,-1004 # 80027098 <devsw>
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
    80000612:	6d4080e7          	jalr	1748(ra) # 80000ce2 <acquire>
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
    80000770:	646080e7          	jalr	1606(ra) # 80000db2 <release>
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
    80000796:	6cc080e7          	jalr	1740(ra) # 80000e5e <initlock>
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
    800007ec:	676080e7          	jalr	1654(ra) # 80000e5e <initlock>
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
    80000808:	492080e7          	jalr	1170(ra) # 80000c96 <push_off>

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
    80000836:	520080e7          	jalr	1312(ra) # 80000d52 <pop_off>
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
    800008b0:	e14080e7          	jalr	-492(ra) # 800026c0 <wakeup>
    
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
    800008f4:	3f2080e7          	jalr	1010(ra) # 80000ce2 <acquire>
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
    8000094a:	bfa080e7          	jalr	-1030(ra) # 80002540 <sleep>
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
    80000990:	426080e7          	jalr	1062(ra) # 80000db2 <release>
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
    800009f8:	2ee080e7          	jalr	750(ra) # 80000ce2 <acquire>
  uartstart();
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	e48080e7          	jalr	-440(ra) # 80000844 <uartstart>
  release(&uart_tx_lock);
    80000a04:	8526                	mv	a0,s1
    80000a06:	00000097          	auipc	ra,0x0
    80000a0a:	3ac080e7          	jalr	940(ra) # 80000db2 <release>
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
    80000a2e:	e3c9                	bnez	a5,80000ab0 <kfree+0x98>
    80000a30:	84aa                	mv	s1,a0
    80000a32:	0002c797          	auipc	a5,0x2c
    80000a36:	5f678793          	addi	a5,a5,1526 # 8002d028 <end>
    80000a3a:	06f56b63          	bltu	a0,a5,80000ab0 <kfree+0x98>
    80000a3e:	47c5                	li	a5,17
    80000a40:	07ee                	slli	a5,a5,0x1b
    80000a42:	06f57763          	bgeu	a0,a5,80000ab0 <kfree+0x98>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a46:	6605                	lui	a2,0x1
    80000a48:	4585                	li	a1,1
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	678080e7          	jalr	1656(ra) # 800010c2 <memset>

  r = (struct run*)pa;
  push_off();
    80000a52:	00000097          	auipc	ra,0x0
    80000a56:	244080e7          	jalr	580(ra) # 80000c96 <push_off>
  int id = cpuid();
    80000a5a:	00001097          	auipc	ra,0x1
    80000a5e:	2a2080e7          	jalr	674(ra) # 80001cfc <cpuid>
    80000a62:	8a2a                	mv	s4,a0
  pop_off();
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	2ee080e7          	jalr	750(ra) # 80000d52 <pop_off>
  acquire(&(kmem[id]).lock);
    80000a6c:	00011a97          	auipc	s5,0x11
    80000a70:	81ca8a93          	addi	s5,s5,-2020 # 80011288 <kmem>
    80000a74:	002a1993          	slli	s3,s4,0x2
    80000a78:	01498933          	add	s2,s3,s4
    80000a7c:	090e                	slli	s2,s2,0x3
    80000a7e:	9956                	add	s2,s2,s5
    80000a80:	854a                	mv	a0,s2
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	260080e7          	jalr	608(ra) # 80000ce2 <acquire>
  r->next = kmem[id].freelist;
    80000a8a:	02093783          	ld	a5,32(s2)
    80000a8e:	e09c                	sd	a5,0(s1)
  kmem[id].freelist = r;
    80000a90:	02993023          	sd	s1,32(s2)
  release(&(kmem[id]).lock);
    80000a94:	854a                	mv	a0,s2
    80000a96:	00000097          	auipc	ra,0x0
    80000a9a:	31c080e7          	jalr	796(ra) # 80000db2 <release>
  
}
    80000a9e:	70e2                	ld	ra,56(sp)
    80000aa0:	7442                	ld	s0,48(sp)
    80000aa2:	74a2                	ld	s1,40(sp)
    80000aa4:	7902                	ld	s2,32(sp)
    80000aa6:	69e2                	ld	s3,24(sp)
    80000aa8:	6a42                	ld	s4,16(sp)
    80000aaa:	6aa2                	ld	s5,8(sp)
    80000aac:	6121                	addi	sp,sp,64
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	5b050513          	addi	a0,a0,1456 # 80008060 <digits+0x20>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	a94080e7          	jalr	-1388(ra) # 8000054c <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	e84a                	sd	s2,16(sp)
    80000aca:	e44e                	sd	s3,8(sp)
    80000acc:	e052                	sd	s4,0(sp)
    80000ace:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ad0:	6785                	lui	a5,0x1
    80000ad2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad6:	00e504b3          	add	s1,a0,a4
    80000ada:	777d                	lui	a4,0xfffff
    80000adc:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ade:	94be                	add	s1,s1,a5
    80000ae0:	0095ee63          	bltu	a1,s1,80000afc <freerange+0x3c>
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f2a080e7          	jalr	-214(ra) # 80000a18 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
}
    80000afc:	70a2                	ld	ra,40(sp)
    80000afe:	7402                	ld	s0,32(sp)
    80000b00:	64e2                	ld	s1,24(sp)
    80000b02:	6942                	ld	s2,16(sp)
    80000b04:	69a2                	ld	s3,8(sp)
    80000b06:	6a02                	ld	s4,0(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{ 
    80000b0c:	7179                	addi	sp,sp,-48
    80000b0e:	f406                	sd	ra,40(sp)
    80000b10:	f022                	sd	s0,32(sp)
    80000b12:	ec26                	sd	s1,24(sp)
    80000b14:	e84a                	sd	s2,16(sp)
    80000b16:	e44e                	sd	s3,8(sp)
    80000b18:	1800                	addi	s0,sp,48
  for(int id=0;id<NCPU;id++){
    80000b1a:	00010497          	auipc	s1,0x10
    80000b1e:	76e48493          	addi	s1,s1,1902 # 80011288 <kmem>
    80000b22:	00011997          	auipc	s3,0x11
    80000b26:	8a698993          	addi	s3,s3,-1882 # 800113c8 <lock_locks>
  initlock(&(kmem[id]).lock, "kmem");
    80000b2a:	00007917          	auipc	s2,0x7
    80000b2e:	53e90913          	addi	s2,s2,1342 # 80008068 <digits+0x28>
    80000b32:	85ca                	mv	a1,s2
    80000b34:	8526                	mv	a0,s1
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	328080e7          	jalr	808(ra) # 80000e5e <initlock>
  for(int id=0;id<NCPU;id++){
    80000b3e:	02848493          	addi	s1,s1,40
    80000b42:	ff3498e3          	bne	s1,s3,80000b32 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b46:	45c5                	li	a1,17
    80000b48:	05ee                	slli	a1,a1,0x1b
    80000b4a:	0002c517          	auipc	a0,0x2c
    80000b4e:	4de50513          	addi	a0,a0,1246 # 8002d028 <end>
    80000b52:	00000097          	auipc	ra,0x0
    80000b56:	f6e080e7          	jalr	-146(ra) # 80000ac0 <freerange>
}
    80000b5a:	70a2                	ld	ra,40(sp)
    80000b5c:	7402                	ld	s0,32(sp)
    80000b5e:	64e2                	ld	s1,24(sp)
    80000b60:	6942                	ld	s2,16(sp)
    80000b62:	69a2                	ld	s3,8(sp)
    80000b64:	6145                	addi	sp,sp,48
    80000b66:	8082                	ret

0000000080000b68 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b68:	715d                	addi	sp,sp,-80
    80000b6a:	e486                	sd	ra,72(sp)
    80000b6c:	e0a2                	sd	s0,64(sp)
    80000b6e:	fc26                	sd	s1,56(sp)
    80000b70:	f84a                	sd	s2,48(sp)
    80000b72:	f44e                	sd	s3,40(sp)
    80000b74:	f052                	sd	s4,32(sp)
    80000b76:	ec56                	sd	s5,24(sp)
    80000b78:	e85a                	sd	s6,16(sp)
    80000b7a:	e45e                	sd	s7,8(sp)
    80000b7c:	0880                	addi	s0,sp,80
  struct run *r;
  push_off();
    80000b7e:	00000097          	auipc	ra,0x0
    80000b82:	118080e7          	jalr	280(ra) # 80000c96 <push_off>
  int id = cpuid();
    80000b86:	00001097          	auipc	ra,0x1
    80000b8a:	176080e7          	jalr	374(ra) # 80001cfc <cpuid>
    80000b8e:	89aa                	mv	s3,a0
  pop_off();
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	1c2080e7          	jalr	450(ra) # 80000d52 <pop_off>
  acquire(&(kmem[id]).lock);
    80000b98:	00299793          	slli	a5,s3,0x2
    80000b9c:	97ce                	add	a5,a5,s3
    80000b9e:	078e                	slli	a5,a5,0x3
    80000ba0:	00010497          	auipc	s1,0x10
    80000ba4:	6e848493          	addi	s1,s1,1768 # 80011288 <kmem>
    80000ba8:	94be                	add	s1,s1,a5
    80000baa:	8526                	mv	a0,s1
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	136080e7          	jalr	310(ra) # 80000ce2 <acquire>
  r = kmem[id].freelist;
    80000bb4:	0204ba03          	ld	s4,32(s1)
  if(r){
    80000bb8:	080a0c63          	beqz	s4,80000c50 <kalloc+0xe8>
    
    kmem[id].freelist = r->next;
    80000bbc:	000a3683          	ld	a3,0(s4) # fffffffffffff000 <end+0xffffffff7ffd1fd8>
    80000bc0:	f094                	sd	a3,32(s1)
    
    }
    release(&(kmem[id]).lock);
    80000bc2:	8526                	mv	a0,s1
    80000bc4:	00000097          	auipc	ra,0x0
    80000bc8:	1ee080e7          	jalr	494(ra) # 80000db2 <release>
      release(&(kmem[idx]).lock);
    }
  
  
  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bcc:	6605                	lui	a2,0x1
    80000bce:	4595                	li	a1,5
    80000bd0:	8552                	mv	a0,s4
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	4f0080e7          	jalr	1264(ra) # 800010c2 <memset>
  
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
    80000bee:	6161                	addi	sp,sp,80
    80000bf0:	8082                	ret
        kmem[idx].freelist=r->next;
    80000bf2:	000bb683          	ld	a3,0(s7)
    80000bf6:	00249793          	slli	a5,s1,0x2
    80000bfa:	97a6                	add	a5,a5,s1
    80000bfc:	078e                	slli	a5,a5,0x3
    80000bfe:	00010717          	auipc	a4,0x10
    80000c02:	68a70713          	addi	a4,a4,1674 # 80011288 <kmem>
    80000c06:	97ba                	add	a5,a5,a4
    80000c08:	f394                	sd	a3,32(a5)
        release(&(kmem[idx]).lock);
    80000c0a:	854a                	mv	a0,s2
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	1a6080e7          	jalr	422(ra) # 80000db2 <release>
      if(kmem[idx].freelist){
    80000c14:	8a5e                	mv	s4,s7
        break;
    80000c16:	bf5d                	j	80000bcc <kalloc+0x64>
    for(int idx=0;idx<NCPU;idx++){
    80000c18:	2485                	addiw	s1,s1,1
    80000c1a:	02890913          	addi	s2,s2,40
    80000c1e:	fb548ee3          	beq	s1,s5,80000bda <kalloc+0x72>
      if(idx==id||holding(&(kmem[idx]).lock)) continue;// if the lock was hold by other cpu, skip
    80000c22:	fe998be3          	beq	s3,s1,80000c18 <kalloc+0xb0>
    80000c26:	854a                	mv	a0,s2
    80000c28:	00000097          	auipc	ra,0x0
    80000c2c:	040080e7          	jalr	64(ra) # 80000c68 <holding>
    80000c30:	f565                	bnez	a0,80000c18 <kalloc+0xb0>
      acquire(&(kmem[idx]).lock);
    80000c32:	854a                	mv	a0,s2
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	0ae080e7          	jalr	174(ra) # 80000ce2 <acquire>
      if(kmem[idx].freelist){
    80000c3c:	02093b83          	ld	s7,32(s2)
    80000c40:	fa0b99e3          	bnez	s7,80000bf2 <kalloc+0x8a>
      release(&(kmem[idx]).lock);
    80000c44:	854a                	mv	a0,s2
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	16c080e7          	jalr	364(ra) # 80000db2 <release>
    80000c4e:	b7e9                	j	80000c18 <kalloc+0xb0>
    release(&(kmem[id]).lock);
    80000c50:	8526                	mv	a0,s1
    80000c52:	00000097          	auipc	ra,0x0
    80000c56:	160080e7          	jalr	352(ra) # 80000db2 <release>
    for(int idx=0;idx<NCPU;idx++){
    80000c5a:	00010917          	auipc	s2,0x10
    80000c5e:	62e90913          	addi	s2,s2,1582 # 80011288 <kmem>
    release(&(kmem[id]).lock);
    80000c62:	4481                	li	s1,0
    for(int idx=0;idx<NCPU;idx++){
    80000c64:	4aa1                	li	s5,8
    80000c66:	bf75                	j	80000c22 <kalloc+0xba>

0000000080000c68 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c68:	411c                	lw	a5,0(a0)
    80000c6a:	e399                	bnez	a5,80000c70 <holding+0x8>
    80000c6c:	4501                	li	a0,0
  return r;
}
    80000c6e:	8082                	ret
{
    80000c70:	1101                	addi	sp,sp,-32
    80000c72:	ec06                	sd	ra,24(sp)
    80000c74:	e822                	sd	s0,16(sp)
    80000c76:	e426                	sd	s1,8(sp)
    80000c78:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c7a:	6904                	ld	s1,16(a0)
    80000c7c:	00001097          	auipc	ra,0x1
    80000c80:	090080e7          	jalr	144(ra) # 80001d0c <mycpu>
    80000c84:	40a48533          	sub	a0,s1,a0
    80000c88:	00153513          	seqz	a0,a0
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret

0000000080000c96 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c96:	1101                	addi	sp,sp,-32
    80000c98:	ec06                	sd	ra,24(sp)
    80000c9a:	e822                	sd	s0,16(sp)
    80000c9c:	e426                	sd	s1,8(sp)
    80000c9e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca0:	100024f3          	csrr	s1,sstatus
    80000ca4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ca8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000caa:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000cae:	00001097          	auipc	ra,0x1
    80000cb2:	05e080e7          	jalr	94(ra) # 80001d0c <mycpu>
    80000cb6:	5d3c                	lw	a5,120(a0)
    80000cb8:	cf89                	beqz	a5,80000cd2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cba:	00001097          	auipc	ra,0x1
    80000cbe:	052080e7          	jalr	82(ra) # 80001d0c <mycpu>
    80000cc2:	5d3c                	lw	a5,120(a0)
    80000cc4:	2785                	addiw	a5,a5,1
    80000cc6:	dd3c                	sw	a5,120(a0)
}
    80000cc8:	60e2                	ld	ra,24(sp)
    80000cca:	6442                	ld	s0,16(sp)
    80000ccc:	64a2                	ld	s1,8(sp)
    80000cce:	6105                	addi	sp,sp,32
    80000cd0:	8082                	ret
    mycpu()->intena = old;
    80000cd2:	00001097          	auipc	ra,0x1
    80000cd6:	03a080e7          	jalr	58(ra) # 80001d0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cda:	8085                	srli	s1,s1,0x1
    80000cdc:	8885                	andi	s1,s1,1
    80000cde:	dd64                	sw	s1,124(a0)
    80000ce0:	bfe9                	j	80000cba <push_off+0x24>

0000000080000ce2 <acquire>:
{
    80000ce2:	1101                	addi	sp,sp,-32
    80000ce4:	ec06                	sd	ra,24(sp)
    80000ce6:	e822                	sd	s0,16(sp)
    80000ce8:	e426                	sd	s1,8(sp)
    80000cea:	1000                	addi	s0,sp,32
    80000cec:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cee:	00000097          	auipc	ra,0x0
    80000cf2:	fa8080e7          	jalr	-88(ra) # 80000c96 <push_off>
  if(holding(lk))
    80000cf6:	8526                	mv	a0,s1
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	f70080e7          	jalr	-144(ra) # 80000c68 <holding>
    80000d00:	e911                	bnez	a0,80000d14 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d02:	4785                	li	a5,1
    80000d04:	01c48713          	addi	a4,s1,28
    80000d08:	0f50000f          	fence	iorw,ow
    80000d0c:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d10:	4705                	li	a4,1
    80000d12:	a839                	j	80000d30 <acquire+0x4e>
    panic("acquire");
    80000d14:	00007517          	auipc	a0,0x7
    80000d18:	35c50513          	addi	a0,a0,860 # 80008070 <digits+0x30>
    80000d1c:	00000097          	auipc	ra,0x0
    80000d20:	830080e7          	jalr	-2000(ra) # 8000054c <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000d24:	01848793          	addi	a5,s1,24
    80000d28:	0f50000f          	fence	iorw,ow
    80000d2c:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d30:	87ba                	mv	a5,a4
    80000d32:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d36:	2781                	sext.w	a5,a5
    80000d38:	f7f5                	bnez	a5,80000d24 <acquire+0x42>
  __sync_synchronize();
    80000d3a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d3e:	00001097          	auipc	ra,0x1
    80000d42:	fce080e7          	jalr	-50(ra) # 80001d0c <mycpu>
    80000d46:	e888                	sd	a0,16(s1)
}
    80000d48:	60e2                	ld	ra,24(sp)
    80000d4a:	6442                	ld	s0,16(sp)
    80000d4c:	64a2                	ld	s1,8(sp)
    80000d4e:	6105                	addi	sp,sp,32
    80000d50:	8082                	ret

0000000080000d52 <pop_off>:

void
pop_off(void)
{
    80000d52:	1141                	addi	sp,sp,-16
    80000d54:	e406                	sd	ra,8(sp)
    80000d56:	e022                	sd	s0,0(sp)
    80000d58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d5a:	00001097          	auipc	ra,0x1
    80000d5e:	fb2080e7          	jalr	-78(ra) # 80001d0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d68:	e78d                	bnez	a5,80000d92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d6a:	5d3c                	lw	a5,120(a0)
    80000d6c:	02f05b63          	blez	a5,80000da2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d70:	37fd                	addiw	a5,a5,-1
    80000d72:	0007871b          	sext.w	a4,a5
    80000d76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d78:	eb09                	bnez	a4,80000d8a <pop_off+0x38>
    80000d7a:	5d7c                	lw	a5,124(a0)
    80000d7c:	c799                	beqz	a5,80000d8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d8a:	60a2                	ld	ra,8(sp)
    80000d8c:	6402                	ld	s0,0(sp)
    80000d8e:	0141                	addi	sp,sp,16
    80000d90:	8082                	ret
    panic("pop_off - interruptible");
    80000d92:	00007517          	auipc	a0,0x7
    80000d96:	2e650513          	addi	a0,a0,742 # 80008078 <digits+0x38>
    80000d9a:	fffff097          	auipc	ra,0xfffff
    80000d9e:	7b2080e7          	jalr	1970(ra) # 8000054c <panic>
    panic("pop_off");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2ee50513          	addi	a0,a0,750 # 80008090 <digits+0x50>
    80000daa:	fffff097          	auipc	ra,0xfffff
    80000dae:	7a2080e7          	jalr	1954(ra) # 8000054c <panic>

0000000080000db2 <release>:
{
    80000db2:	1101                	addi	sp,sp,-32
    80000db4:	ec06                	sd	ra,24(sp)
    80000db6:	e822                	sd	s0,16(sp)
    80000db8:	e426                	sd	s1,8(sp)
    80000dba:	1000                	addi	s0,sp,32
    80000dbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dbe:	00000097          	auipc	ra,0x0
    80000dc2:	eaa080e7          	jalr	-342(ra) # 80000c68 <holding>
    80000dc6:	c115                	beqz	a0,80000dea <release+0x38>
  lk->cpu = 0;
    80000dc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000dcc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000dd0:	0f50000f          	fence	iorw,ow
    80000dd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f7a080e7          	jalr	-134(ra) # 80000d52 <pop_off>
}
    80000de0:	60e2                	ld	ra,24(sp)
    80000de2:	6442                	ld	s0,16(sp)
    80000de4:	64a2                	ld	s1,8(sp)
    80000de6:	6105                	addi	sp,sp,32
    80000de8:	8082                	ret
    panic("release");
    80000dea:	00007517          	auipc	a0,0x7
    80000dee:	2ae50513          	addi	a0,a0,686 # 80008098 <digits+0x58>
    80000df2:	fffff097          	auipc	ra,0xfffff
    80000df6:	75a080e7          	jalr	1882(ra) # 8000054c <panic>

0000000080000dfa <freelock>:
{
    80000dfa:	1101                	addi	sp,sp,-32
    80000dfc:	ec06                	sd	ra,24(sp)
    80000dfe:	e822                	sd	s0,16(sp)
    80000e00:	e426                	sd	s1,8(sp)
    80000e02:	1000                	addi	s0,sp,32
    80000e04:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e06:	00010517          	auipc	a0,0x10
    80000e0a:	5c250513          	addi	a0,a0,1474 # 800113c8 <lock_locks>
    80000e0e:	00000097          	auipc	ra,0x0
    80000e12:	ed4080e7          	jalr	-300(ra) # 80000ce2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e16:	00010717          	auipc	a4,0x10
    80000e1a:	5d270713          	addi	a4,a4,1490 # 800113e8 <locks>
    80000e1e:	4781                	li	a5,0
    80000e20:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000e24:	6314                	ld	a3,0(a4)
    80000e26:	00968763          	beq	a3,s1,80000e34 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000e2a:	2785                	addiw	a5,a5,1
    80000e2c:	0721                	addi	a4,a4,8
    80000e2e:	fec79be3          	bne	a5,a2,80000e24 <freelock+0x2a>
    80000e32:	a809                	j	80000e44 <freelock+0x4a>
      locks[i] = 0;
    80000e34:	078e                	slli	a5,a5,0x3
    80000e36:	00010717          	auipc	a4,0x10
    80000e3a:	5b270713          	addi	a4,a4,1458 # 800113e8 <locks>
    80000e3e:	97ba                	add	a5,a5,a4
    80000e40:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000e44:	00010517          	auipc	a0,0x10
    80000e48:	58450513          	addi	a0,a0,1412 # 800113c8 <lock_locks>
    80000e4c:	00000097          	auipc	ra,0x0
    80000e50:	f66080e7          	jalr	-154(ra) # 80000db2 <release>
}
    80000e54:	60e2                	ld	ra,24(sp)
    80000e56:	6442                	ld	s0,16(sp)
    80000e58:	64a2                	ld	s1,8(sp)
    80000e5a:	6105                	addi	sp,sp,32
    80000e5c:	8082                	ret

0000000080000e5e <initlock>:
{
    80000e5e:	1101                	addi	sp,sp,-32
    80000e60:	ec06                	sd	ra,24(sp)
    80000e62:	e822                	sd	s0,16(sp)
    80000e64:	e426                	sd	s1,8(sp)
    80000e66:	1000                	addi	s0,sp,32
    80000e68:	84aa                	mv	s1,a0
  lk->name = name;
    80000e6a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e6c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e70:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000e74:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000e78:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000e7c:	00010517          	auipc	a0,0x10
    80000e80:	54c50513          	addi	a0,a0,1356 # 800113c8 <lock_locks>
    80000e84:	00000097          	auipc	ra,0x0
    80000e88:	e5e080e7          	jalr	-418(ra) # 80000ce2 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e8c:	00010717          	auipc	a4,0x10
    80000e90:	55c70713          	addi	a4,a4,1372 # 800113e8 <locks>
    80000e94:	4781                	li	a5,0
    80000e96:	1f400613          	li	a2,500
    if(locks[i] == 0) {
    80000e9a:	6314                	ld	a3,0(a4)
    80000e9c:	ce89                	beqz	a3,80000eb6 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000e9e:	2785                	addiw	a5,a5,1
    80000ea0:	0721                	addi	a4,a4,8
    80000ea2:	fec79ce3          	bne	a5,a2,80000e9a <initlock+0x3c>
  panic("findslot");
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	1fa50513          	addi	a0,a0,506 # 800080a0 <digits+0x60>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	69e080e7          	jalr	1694(ra) # 8000054c <panic>
      locks[i] = lk;
    80000eb6:	078e                	slli	a5,a5,0x3
    80000eb8:	00010717          	auipc	a4,0x10
    80000ebc:	53070713          	addi	a4,a4,1328 # 800113e8 <locks>
    80000ec0:	97ba                	add	a5,a5,a4
    80000ec2:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000ec4:	00010517          	auipc	a0,0x10
    80000ec8:	50450513          	addi	a0,a0,1284 # 800113c8 <lock_locks>
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	ee6080e7          	jalr	-282(ra) # 80000db2 <release>
}
    80000ed4:	60e2                	ld	ra,24(sp)
    80000ed6:	6442                	ld	s0,16(sp)
    80000ed8:	64a2                	ld	s1,8(sp)
    80000eda:	6105                	addi	sp,sp,32
    80000edc:	8082                	ret

0000000080000ede <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000ede:	4e5c                	lw	a5,28(a2)
    80000ee0:	00f04463          	bgtz	a5,80000ee8 <snprint_lock+0xa>
  int n = 0;
    80000ee4:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000ee6:	8082                	ret
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000ef0:	4e18                	lw	a4,24(a2)
    80000ef2:	6614                	ld	a3,8(a2)
    80000ef4:	00007617          	auipc	a2,0x7
    80000ef8:	1bc60613          	addi	a2,a2,444 # 800080b0 <digits+0x70>
    80000efc:	00006097          	auipc	ra,0x6
    80000f00:	964080e7          	jalr	-1692(ra) # 80006860 <snprintf>
}
    80000f04:	60a2                	ld	ra,8(sp)
    80000f06:	6402                	ld	s0,0(sp)
    80000f08:	0141                	addi	sp,sp,16
    80000f0a:	8082                	ret

0000000080000f0c <statslock>:

int
statslock(char *buf, int sz) {
    80000f0c:	7159                	addi	sp,sp,-112
    80000f0e:	f486                	sd	ra,104(sp)
    80000f10:	f0a2                	sd	s0,96(sp)
    80000f12:	eca6                	sd	s1,88(sp)
    80000f14:	e8ca                	sd	s2,80(sp)
    80000f16:	e4ce                	sd	s3,72(sp)
    80000f18:	e0d2                	sd	s4,64(sp)
    80000f1a:	fc56                	sd	s5,56(sp)
    80000f1c:	f85a                	sd	s6,48(sp)
    80000f1e:	f45e                	sd	s7,40(sp)
    80000f20:	f062                	sd	s8,32(sp)
    80000f22:	ec66                	sd	s9,24(sp)
    80000f24:	e86a                	sd	s10,16(sp)
    80000f26:	e46e                	sd	s11,8(sp)
    80000f28:	1880                	addi	s0,sp,112
    80000f2a:	8aaa                	mv	s5,a0
    80000f2c:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000f2e:	00010517          	auipc	a0,0x10
    80000f32:	49a50513          	addi	a0,a0,1178 # 800113c8 <lock_locks>
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	dac080e7          	jalr	-596(ra) # 80000ce2 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f3e:	00007617          	auipc	a2,0x7
    80000f42:	1a260613          	addi	a2,a2,418 # 800080e0 <digits+0xa0>
    80000f46:	85da                	mv	a1,s6
    80000f48:	8556                	mv	a0,s5
    80000f4a:	00006097          	auipc	ra,0x6
    80000f4e:	916080e7          	jalr	-1770(ra) # 80006860 <snprintf>
    80000f52:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000f54:	00010c97          	auipc	s9,0x10
    80000f58:	494c8c93          	addi	s9,s9,1172 # 800113e8 <locks>
    80000f5c:	00011c17          	auipc	s8,0x11
    80000f60:	42cc0c13          	addi	s8,s8,1068 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000f64:	84e6                	mv	s1,s9
  int tot = 0;
    80000f66:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000f68:	00007b97          	auipc	s7,0x7
    80000f6c:	198b8b93          	addi	s7,s7,408 # 80008100 <digits+0xc0>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000f70:	00007d17          	auipc	s10,0x7
    80000f74:	0f8d0d13          	addi	s10,s10,248 # 80008068 <digits+0x28>
    80000f78:	a01d                	j	80000f9e <statslock+0x92>
      tot += locks[i]->nts;
    80000f7a:	0009b603          	ld	a2,0(s3)
    80000f7e:	4e1c                	lw	a5,24(a2)
    80000f80:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80000f84:	412b05bb          	subw	a1,s6,s2
    80000f88:	012a8533          	add	a0,s5,s2
    80000f8c:	00000097          	auipc	ra,0x0
    80000f90:	f52080e7          	jalr	-174(ra) # 80000ede <snprint_lock>
    80000f94:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80000f98:	04a1                	addi	s1,s1,8
    80000f9a:	05848763          	beq	s1,s8,80000fe8 <statslock+0xdc>
    if(locks[i] == 0)
    80000f9e:	89a6                	mv	s3,s1
    80000fa0:	609c                	ld	a5,0(s1)
    80000fa2:	c3b9                	beqz	a5,80000fe8 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fa4:	0087bd83          	ld	s11,8(a5)
    80000fa8:	855e                	mv	a0,s7
    80000faa:	00000097          	auipc	ra,0x0
    80000fae:	29c080e7          	jalr	668(ra) # 80001246 <strlen>
    80000fb2:	0005061b          	sext.w	a2,a0
    80000fb6:	85de                	mv	a1,s7
    80000fb8:	856e                	mv	a0,s11
    80000fba:	00000097          	auipc	ra,0x0
    80000fbe:	1e0080e7          	jalr	480(ra) # 8000119a <strncmp>
    80000fc2:	dd45                	beqz	a0,80000f7a <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fc4:	609c                	ld	a5,0(s1)
    80000fc6:	0087bd83          	ld	s11,8(a5)
    80000fca:	856a                	mv	a0,s10
    80000fcc:	00000097          	auipc	ra,0x0
    80000fd0:	27a080e7          	jalr	634(ra) # 80001246 <strlen>
    80000fd4:	0005061b          	sext.w	a2,a0
    80000fd8:	85ea                	mv	a1,s10
    80000fda:	856e                	mv	a0,s11
    80000fdc:	00000097          	auipc	ra,0x0
    80000fe0:	1be080e7          	jalr	446(ra) # 8000119a <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fe4:	f955                	bnez	a0,80000f98 <statslock+0x8c>
    80000fe6:	bf51                	j	80000f7a <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80000fe8:	00007617          	auipc	a2,0x7
    80000fec:	12060613          	addi	a2,a2,288 # 80008108 <digits+0xc8>
    80000ff0:	412b05bb          	subw	a1,s6,s2
    80000ff4:	012a8533          	add	a0,s5,s2
    80000ff8:	00006097          	auipc	ra,0x6
    80000ffc:	868080e7          	jalr	-1944(ra) # 80006860 <snprintf>
    80001000:	012509bb          	addw	s3,a0,s2
    80001004:	4b95                	li	s7,5
  int last = 100000000;
    80001006:	05f5e537          	lui	a0,0x5f5e
    8000100a:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000100e:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    80001010:	00010497          	auipc	s1,0x10
    80001014:	3d848493          	addi	s1,s1,984 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001018:	1f400913          	li	s2,500
    8000101c:	a881                	j	8000106c <statslock+0x160>
    8000101e:	2705                	addiw	a4,a4,1
    80001020:	06a1                	addi	a3,a3,8
    80001022:	03270063          	beq	a4,s2,80001042 <statslock+0x136>
      if(locks[i] == 0)
    80001026:	629c                	ld	a5,0(a3)
    80001028:	cf89                	beqz	a5,80001042 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000102a:	4f90                	lw	a2,24(a5)
    8000102c:	00359793          	slli	a5,a1,0x3
    80001030:	97a6                	add	a5,a5,s1
    80001032:	639c                	ld	a5,0(a5)
    80001034:	4f9c                	lw	a5,24(a5)
    80001036:	fec7d4e3          	bge	a5,a2,8000101e <statslock+0x112>
    8000103a:	fea652e3          	bge	a2,a0,8000101e <statslock+0x112>
    8000103e:	85ba                	mv	a1,a4
    80001040:	bff9                	j	8000101e <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    80001042:	058e                	slli	a1,a1,0x3
    80001044:	00b48d33          	add	s10,s1,a1
    80001048:	000d3603          	ld	a2,0(s10)
    8000104c:	413b05bb          	subw	a1,s6,s3
    80001050:	013a8533          	add	a0,s5,s3
    80001054:	00000097          	auipc	ra,0x0
    80001058:	e8a080e7          	jalr	-374(ra) # 80000ede <snprint_lock>
    8000105c:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    80001060:	000d3783          	ld	a5,0(s10)
    80001064:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    80001066:	3bfd                	addiw	s7,s7,-1
    80001068:	000b8663          	beqz	s7,80001074 <statslock+0x168>
  int tot = 0;
    8000106c:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    8000106e:	8762                	mv	a4,s8
    int top = 0;
    80001070:	85e2                	mv	a1,s8
    80001072:	bf55                	j	80001026 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    80001074:	86d2                	mv	a3,s4
    80001076:	00007617          	auipc	a2,0x7
    8000107a:	0b260613          	addi	a2,a2,178 # 80008128 <digits+0xe8>
    8000107e:	413b05bb          	subw	a1,s6,s3
    80001082:	013a8533          	add	a0,s5,s3
    80001086:	00005097          	auipc	ra,0x5
    8000108a:	7da080e7          	jalr	2010(ra) # 80006860 <snprintf>
    8000108e:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    80001092:	00010517          	auipc	a0,0x10
    80001096:	33650513          	addi	a0,a0,822 # 800113c8 <lock_locks>
    8000109a:	00000097          	auipc	ra,0x0
    8000109e:	d18080e7          	jalr	-744(ra) # 80000db2 <release>
  return n;
}
    800010a2:	854e                	mv	a0,s3
    800010a4:	70a6                	ld	ra,104(sp)
    800010a6:	7406                	ld	s0,96(sp)
    800010a8:	64e6                	ld	s1,88(sp)
    800010aa:	6946                	ld	s2,80(sp)
    800010ac:	69a6                	ld	s3,72(sp)
    800010ae:	6a06                	ld	s4,64(sp)
    800010b0:	7ae2                	ld	s5,56(sp)
    800010b2:	7b42                	ld	s6,48(sp)
    800010b4:	7ba2                	ld	s7,40(sp)
    800010b6:	7c02                	ld	s8,32(sp)
    800010b8:	6ce2                	ld	s9,24(sp)
    800010ba:	6d42                	ld	s10,16(sp)
    800010bc:	6da2                	ld	s11,8(sp)
    800010be:	6165                	addi	sp,sp,112
    800010c0:	8082                	ret

00000000800010c2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800010c2:	1141                	addi	sp,sp,-16
    800010c4:	e422                	sd	s0,8(sp)
    800010c6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800010c8:	ca19                	beqz	a2,800010de <memset+0x1c>
    800010ca:	87aa                	mv	a5,a0
    800010cc:	1602                	slli	a2,a2,0x20
    800010ce:	9201                	srli	a2,a2,0x20
    800010d0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800010d4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800010d8:	0785                	addi	a5,a5,1
    800010da:	fee79de3          	bne	a5,a4,800010d4 <memset+0x12>
  }
  return dst;
}
    800010de:	6422                	ld	s0,8(sp)
    800010e0:	0141                	addi	sp,sp,16
    800010e2:	8082                	ret

00000000800010e4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800010e4:	1141                	addi	sp,sp,-16
    800010e6:	e422                	sd	s0,8(sp)
    800010e8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800010ea:	ca05                	beqz	a2,8000111a <memcmp+0x36>
    800010ec:	fff6069b          	addiw	a3,a2,-1
    800010f0:	1682                	slli	a3,a3,0x20
    800010f2:	9281                	srli	a3,a3,0x20
    800010f4:	0685                	addi	a3,a3,1
    800010f6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    800010f8:	00054783          	lbu	a5,0(a0)
    800010fc:	0005c703          	lbu	a4,0(a1)
    80001100:	00e79863          	bne	a5,a4,80001110 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001104:	0505                	addi	a0,a0,1
    80001106:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80001108:	fed518e3          	bne	a0,a3,800010f8 <memcmp+0x14>
  }

  return 0;
    8000110c:	4501                	li	a0,0
    8000110e:	a019                	j	80001114 <memcmp+0x30>
      return *s1 - *s2;
    80001110:	40e7853b          	subw	a0,a5,a4
}
    80001114:	6422                	ld	s0,8(sp)
    80001116:	0141                	addi	sp,sp,16
    80001118:	8082                	ret
  return 0;
    8000111a:	4501                	li	a0,0
    8000111c:	bfe5                	j	80001114 <memcmp+0x30>

000000008000111e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    8000111e:	1141                	addi	sp,sp,-16
    80001120:	e422                	sd	s0,8(sp)
    80001122:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001124:	02a5e563          	bltu	a1,a0,8000114e <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001128:	fff6069b          	addiw	a3,a2,-1
    8000112c:	ce11                	beqz	a2,80001148 <memmove+0x2a>
    8000112e:	1682                	slli	a3,a3,0x20
    80001130:	9281                	srli	a3,a3,0x20
    80001132:	0685                	addi	a3,a3,1
    80001134:	96ae                	add	a3,a3,a1
    80001136:	87aa                	mv	a5,a0
      *d++ = *s++;
    80001138:	0585                	addi	a1,a1,1
    8000113a:	0785                	addi	a5,a5,1
    8000113c:	fff5c703          	lbu	a4,-1(a1)
    80001140:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80001144:	fed59ae3          	bne	a1,a3,80001138 <memmove+0x1a>

  return dst;
}
    80001148:	6422                	ld	s0,8(sp)
    8000114a:	0141                	addi	sp,sp,16
    8000114c:	8082                	ret
  if(s < d && s + n > d){
    8000114e:	02061713          	slli	a4,a2,0x20
    80001152:	9301                	srli	a4,a4,0x20
    80001154:	00e587b3          	add	a5,a1,a4
    80001158:	fcf578e3          	bgeu	a0,a5,80001128 <memmove+0xa>
    d += n;
    8000115c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    8000115e:	fff6069b          	addiw	a3,a2,-1
    80001162:	d27d                	beqz	a2,80001148 <memmove+0x2a>
    80001164:	02069613          	slli	a2,a3,0x20
    80001168:	9201                	srli	a2,a2,0x20
    8000116a:	fff64613          	not	a2,a2
    8000116e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80001170:	17fd                	addi	a5,a5,-1
    80001172:	177d                	addi	a4,a4,-1
    80001174:	0007c683          	lbu	a3,0(a5)
    80001178:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    8000117c:	fef61ae3          	bne	a2,a5,80001170 <memmove+0x52>
    80001180:	b7e1                	j	80001148 <memmove+0x2a>

0000000080001182 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001182:	1141                	addi	sp,sp,-16
    80001184:	e406                	sd	ra,8(sp)
    80001186:	e022                	sd	s0,0(sp)
    80001188:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000118a:	00000097          	auipc	ra,0x0
    8000118e:	f94080e7          	jalr	-108(ra) # 8000111e <memmove>
}
    80001192:	60a2                	ld	ra,8(sp)
    80001194:	6402                	ld	s0,0(sp)
    80001196:	0141                	addi	sp,sp,16
    80001198:	8082                	ret

000000008000119a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000119a:	1141                	addi	sp,sp,-16
    8000119c:	e422                	sd	s0,8(sp)
    8000119e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    800011a0:	ce11                	beqz	a2,800011bc <strncmp+0x22>
    800011a2:	00054783          	lbu	a5,0(a0)
    800011a6:	cf89                	beqz	a5,800011c0 <strncmp+0x26>
    800011a8:	0005c703          	lbu	a4,0(a1)
    800011ac:	00f71a63          	bne	a4,a5,800011c0 <strncmp+0x26>
    n--, p++, q++;
    800011b0:	367d                	addiw	a2,a2,-1
    800011b2:	0505                	addi	a0,a0,1
    800011b4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800011b6:	f675                	bnez	a2,800011a2 <strncmp+0x8>
  if(n == 0)
    return 0;
    800011b8:	4501                	li	a0,0
    800011ba:	a809                	j	800011cc <strncmp+0x32>
    800011bc:	4501                	li	a0,0
    800011be:	a039                	j	800011cc <strncmp+0x32>
  if(n == 0)
    800011c0:	ca09                	beqz	a2,800011d2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800011c2:	00054503          	lbu	a0,0(a0)
    800011c6:	0005c783          	lbu	a5,0(a1)
    800011ca:	9d1d                	subw	a0,a0,a5
}
    800011cc:	6422                	ld	s0,8(sp)
    800011ce:	0141                	addi	sp,sp,16
    800011d0:	8082                	ret
    return 0;
    800011d2:	4501                	li	a0,0
    800011d4:	bfe5                	j	800011cc <strncmp+0x32>

00000000800011d6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800011d6:	1141                	addi	sp,sp,-16
    800011d8:	e422                	sd	s0,8(sp)
    800011da:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800011dc:	872a                	mv	a4,a0
    800011de:	8832                	mv	a6,a2
    800011e0:	367d                	addiw	a2,a2,-1
    800011e2:	01005963          	blez	a6,800011f4 <strncpy+0x1e>
    800011e6:	0705                	addi	a4,a4,1
    800011e8:	0005c783          	lbu	a5,0(a1)
    800011ec:	fef70fa3          	sb	a5,-1(a4)
    800011f0:	0585                	addi	a1,a1,1
    800011f2:	f7f5                	bnez	a5,800011de <strncpy+0x8>
    ;
  while(n-- > 0)
    800011f4:	86ba                	mv	a3,a4
    800011f6:	00c05c63          	blez	a2,8000120e <strncpy+0x38>
    *s++ = 0;
    800011fa:	0685                	addi	a3,a3,1
    800011fc:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001200:	40d707bb          	subw	a5,a4,a3
    80001204:	37fd                	addiw	a5,a5,-1
    80001206:	010787bb          	addw	a5,a5,a6
    8000120a:	fef048e3          	bgtz	a5,800011fa <strncpy+0x24>
  return os;
}
    8000120e:	6422                	ld	s0,8(sp)
    80001210:	0141                	addi	sp,sp,16
    80001212:	8082                	ret

0000000080001214 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001214:	1141                	addi	sp,sp,-16
    80001216:	e422                	sd	s0,8(sp)
    80001218:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000121a:	02c05363          	blez	a2,80001240 <safestrcpy+0x2c>
    8000121e:	fff6069b          	addiw	a3,a2,-1
    80001222:	1682                	slli	a3,a3,0x20
    80001224:	9281                	srli	a3,a3,0x20
    80001226:	96ae                	add	a3,a3,a1
    80001228:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000122a:	00d58963          	beq	a1,a3,8000123c <safestrcpy+0x28>
    8000122e:	0585                	addi	a1,a1,1
    80001230:	0785                	addi	a5,a5,1
    80001232:	fff5c703          	lbu	a4,-1(a1)
    80001236:	fee78fa3          	sb	a4,-1(a5)
    8000123a:	fb65                	bnez	a4,8000122a <safestrcpy+0x16>
    ;
  *s = 0;
    8000123c:	00078023          	sb	zero,0(a5)
  return os;
}
    80001240:	6422                	ld	s0,8(sp)
    80001242:	0141                	addi	sp,sp,16
    80001244:	8082                	ret

0000000080001246 <strlen>:

int
strlen(const char *s)
{
    80001246:	1141                	addi	sp,sp,-16
    80001248:	e422                	sd	s0,8(sp)
    8000124a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000124c:	00054783          	lbu	a5,0(a0)
    80001250:	cf91                	beqz	a5,8000126c <strlen+0x26>
    80001252:	0505                	addi	a0,a0,1
    80001254:	87aa                	mv	a5,a0
    80001256:	4685                	li	a3,1
    80001258:	9e89                	subw	a3,a3,a0
    8000125a:	00f6853b          	addw	a0,a3,a5
    8000125e:	0785                	addi	a5,a5,1
    80001260:	fff7c703          	lbu	a4,-1(a5)
    80001264:	fb7d                	bnez	a4,8000125a <strlen+0x14>
    ;
  return n;
}
    80001266:	6422                	ld	s0,8(sp)
    80001268:	0141                	addi	sp,sp,16
    8000126a:	8082                	ret
  for(n = 0; s[n]; n++)
    8000126c:	4501                	li	a0,0
    8000126e:	bfe5                	j	80001266 <strlen+0x20>

0000000080001270 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001270:	1141                	addi	sp,sp,-16
    80001272:	e406                	sd	ra,8(sp)
    80001274:	e022                	sd	s0,0(sp)
    80001276:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001278:	00001097          	auipc	ra,0x1
    8000127c:	a84080e7          	jalr	-1404(ra) # 80001cfc <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001280:	00008717          	auipc	a4,0x8
    80001284:	d8c70713          	addi	a4,a4,-628 # 8000900c <started>
  if(cpuid() == 0){
    80001288:	c139                	beqz	a0,800012ce <main+0x5e>
    while(started == 0)
    8000128a:	431c                	lw	a5,0(a4)
    8000128c:	2781                	sext.w	a5,a5
    8000128e:	dff5                	beqz	a5,8000128a <main+0x1a>
      ;
    __sync_synchronize();
    80001290:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001294:	00001097          	auipc	ra,0x1
    80001298:	a68080e7          	jalr	-1432(ra) # 80001cfc <cpuid>
    8000129c:	85aa                	mv	a1,a0
    8000129e:	00007517          	auipc	a0,0x7
    800012a2:	eb250513          	addi	a0,a0,-334 # 80008150 <digits+0x110>
    800012a6:	fffff097          	auipc	ra,0xfffff
    800012aa:	2f0080e7          	jalr	752(ra) # 80000596 <printf>
    kvminithart();    // turn on paging
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	186080e7          	jalr	390(ra) # 80001434 <kvminithart>
    trapinithart();   // install kernel trap vector
    800012b6:	00001097          	auipc	ra,0x1
    800012ba:	6d2080e7          	jalr	1746(ra) # 80002988 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800012be:	00005097          	auipc	ra,0x5
    800012c2:	e32080e7          	jalr	-462(ra) # 800060f0 <plicinithart>
  }

  scheduler();        
    800012c6:	00001097          	auipc	ra,0x1
    800012ca:	f9a080e7          	jalr	-102(ra) # 80002260 <scheduler>
    consoleinit();
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	18e080e7          	jalr	398(ra) # 8000045c <consoleinit>
    statsinit();
    800012d6:	00005097          	auipc	ra,0x5
    800012da:	4ac080e7          	jalr	1196(ra) # 80006782 <statsinit>
    printfinit();
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	498080e7          	jalr	1176(ra) # 80000776 <printfinit>
    printf("\n");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e7a50513          	addi	a0,a0,-390 # 80008160 <digits+0x120>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	2a8080e7          	jalr	680(ra) # 80000596 <printf>
    printf("xv6 kernel is booting\n");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4250513          	addi	a0,a0,-446 # 80008138 <digits+0xf8>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	298080e7          	jalr	664(ra) # 80000596 <printf>
    printf("\n");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e5a50513          	addi	a0,a0,-422 # 80008160 <digits+0x120>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	288080e7          	jalr	648(ra) # 80000596 <printf>
    kinit();         // physical page allocator
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	7f6080e7          	jalr	2038(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	242080e7          	jalr	578(ra) # 80001560 <kvminit>
    kvminithart();   // turn on paging
    80001326:	00000097          	auipc	ra,0x0
    8000132a:	10e080e7          	jalr	270(ra) # 80001434 <kvminithart>
    procinit();      // process table
    8000132e:	00001097          	auipc	ra,0x1
    80001332:	8fe080e7          	jalr	-1794(ra) # 80001c2c <procinit>
    trapinit();      // trap vectors
    80001336:	00001097          	auipc	ra,0x1
    8000133a:	62a080e7          	jalr	1578(ra) # 80002960 <trapinit>
    trapinithart();  // install kernel trap vector
    8000133e:	00001097          	auipc	ra,0x1
    80001342:	64a080e7          	jalr	1610(ra) # 80002988 <trapinithart>
    plicinit();      // set up interrupt controller
    80001346:	00005097          	auipc	ra,0x5
    8000134a:	d94080e7          	jalr	-620(ra) # 800060da <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000134e:	00005097          	auipc	ra,0x5
    80001352:	da2080e7          	jalr	-606(ra) # 800060f0 <plicinithart>
    binit();         // buffer cache
    80001356:	00002097          	auipc	ra,0x2
    8000135a:	d86080e7          	jalr	-634(ra) # 800030dc <binit>
    iinit();         // inode cache
    8000135e:	00002097          	auipc	ra,0x2
    80001362:	5ae080e7          	jalr	1454(ra) # 8000390c <iinit>
    fileinit();      // file table
    80001366:	00003097          	auipc	ra,0x3
    8000136a:	566080e7          	jalr	1382(ra) # 800048cc <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000136e:	00005097          	auipc	ra,0x5
    80001372:	ea2080e7          	jalr	-350(ra) # 80006210 <virtio_disk_init>
    userinit();      // first user process
    80001376:	00001097          	auipc	ra,0x1
    8000137a:	c7c080e7          	jalr	-900(ra) # 80001ff2 <userinit>
    __sync_synchronize();
    8000137e:	0ff0000f          	fence
    started = 1;
    80001382:	4785                	li	a5,1
    80001384:	00008717          	auipc	a4,0x8
    80001388:	c8f72423          	sw	a5,-888(a4) # 8000900c <started>
    8000138c:	bf2d                	j	800012c6 <main+0x56>

000000008000138e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000138e:	7139                	addi	sp,sp,-64
    80001390:	fc06                	sd	ra,56(sp)
    80001392:	f822                	sd	s0,48(sp)
    80001394:	f426                	sd	s1,40(sp)
    80001396:	f04a                	sd	s2,32(sp)
    80001398:	ec4e                	sd	s3,24(sp)
    8000139a:	e852                	sd	s4,16(sp)
    8000139c:	e456                	sd	s5,8(sp)
    8000139e:	e05a                	sd	s6,0(sp)
    800013a0:	0080                	addi	s0,sp,64
    800013a2:	84aa                	mv	s1,a0
    800013a4:	89ae                	mv	s3,a1
    800013a6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800013a8:	57fd                	li	a5,-1
    800013aa:	83e9                	srli	a5,a5,0x1a
    800013ac:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800013ae:	4b31                	li	s6,12
  if(va >= MAXVA)
    800013b0:	04b7f263          	bgeu	a5,a1,800013f4 <walk+0x66>
    panic("walk");
    800013b4:	00007517          	auipc	a0,0x7
    800013b8:	db450513          	addi	a0,a0,-588 # 80008168 <digits+0x128>
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	190080e7          	jalr	400(ra) # 8000054c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800013c4:	060a8663          	beqz	s5,80001430 <walk+0xa2>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	7a0080e7          	jalr	1952(ra) # 80000b68 <kalloc>
    800013d0:	84aa                	mv	s1,a0
    800013d2:	c529                	beqz	a0,8000141c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800013d4:	6605                	lui	a2,0x1
    800013d6:	4581                	li	a1,0
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	cea080e7          	jalr	-790(ra) # 800010c2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800013e0:	00c4d793          	srli	a5,s1,0xc
    800013e4:	07aa                	slli	a5,a5,0xa
    800013e6:	0017e793          	ori	a5,a5,1
    800013ea:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800013ee:	3a5d                	addiw	s4,s4,-9
    800013f0:	036a0063          	beq	s4,s6,80001410 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800013f4:	0149d933          	srl	s2,s3,s4
    800013f8:	1ff97913          	andi	s2,s2,511
    800013fc:	090e                	slli	s2,s2,0x3
    800013fe:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001400:	00093483          	ld	s1,0(s2)
    80001404:	0014f793          	andi	a5,s1,1
    80001408:	dfd5                	beqz	a5,800013c4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000140a:	80a9                	srli	s1,s1,0xa
    8000140c:	04b2                	slli	s1,s1,0xc
    8000140e:	b7c5                	j	800013ee <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001410:	00c9d513          	srli	a0,s3,0xc
    80001414:	1ff57513          	andi	a0,a0,511
    80001418:	050e                	slli	a0,a0,0x3
    8000141a:	9526                	add	a0,a0,s1
}
    8000141c:	70e2                	ld	ra,56(sp)
    8000141e:	7442                	ld	s0,48(sp)
    80001420:	74a2                	ld	s1,40(sp)
    80001422:	7902                	ld	s2,32(sp)
    80001424:	69e2                	ld	s3,24(sp)
    80001426:	6a42                	ld	s4,16(sp)
    80001428:	6aa2                	ld	s5,8(sp)
    8000142a:	6b02                	ld	s6,0(sp)
    8000142c:	6121                	addi	sp,sp,64
    8000142e:	8082                	ret
        return 0;
    80001430:	4501                	li	a0,0
    80001432:	b7ed                	j	8000141c <walk+0x8e>

0000000080001434 <kvminithart>:
{
    80001434:	1141                	addi	sp,sp,-16
    80001436:	e422                	sd	s0,8(sp)
    80001438:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000143a:	00008797          	auipc	a5,0x8
    8000143e:	bd67b783          	ld	a5,-1066(a5) # 80009010 <kernel_pagetable>
    80001442:	83b1                	srli	a5,a5,0xc
    80001444:	577d                	li	a4,-1
    80001446:	177e                	slli	a4,a4,0x3f
    80001448:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000144a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000144e:	12000073          	sfence.vma
}
    80001452:	6422                	ld	s0,8(sp)
    80001454:	0141                	addi	sp,sp,16
    80001456:	8082                	ret

0000000080001458 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001458:	57fd                	li	a5,-1
    8000145a:	83e9                	srli	a5,a5,0x1a
    8000145c:	00b7f463          	bgeu	a5,a1,80001464 <walkaddr+0xc>
    return 0;
    80001460:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001462:	8082                	ret
{
    80001464:	1141                	addi	sp,sp,-16
    80001466:	e406                	sd	ra,8(sp)
    80001468:	e022                	sd	s0,0(sp)
    8000146a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000146c:	4601                	li	a2,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	f20080e7          	jalr	-224(ra) # 8000138e <walk>
  if(pte == 0)
    80001476:	c105                	beqz	a0,80001496 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001478:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000147a:	0117f693          	andi	a3,a5,17
    8000147e:	4745                	li	a4,17
    return 0;
    80001480:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001482:	00e68663          	beq	a3,a4,8000148e <walkaddr+0x36>
}
    80001486:	60a2                	ld	ra,8(sp)
    80001488:	6402                	ld	s0,0(sp)
    8000148a:	0141                	addi	sp,sp,16
    8000148c:	8082                	ret
  pa = PTE2PA(*pte);
    8000148e:	83a9                	srli	a5,a5,0xa
    80001490:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001494:	bfcd                	j	80001486 <walkaddr+0x2e>
    return 0;
    80001496:	4501                	li	a0,0
    80001498:	b7fd                	j	80001486 <walkaddr+0x2e>

000000008000149a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000149a:	715d                	addi	sp,sp,-80
    8000149c:	e486                	sd	ra,72(sp)
    8000149e:	e0a2                	sd	s0,64(sp)
    800014a0:	fc26                	sd	s1,56(sp)
    800014a2:	f84a                	sd	s2,48(sp)
    800014a4:	f44e                	sd	s3,40(sp)
    800014a6:	f052                	sd	s4,32(sp)
    800014a8:	ec56                	sd	s5,24(sp)
    800014aa:	e85a                	sd	s6,16(sp)
    800014ac:	e45e                	sd	s7,8(sp)
    800014ae:	0880                	addi	s0,sp,80
    800014b0:	8aaa                	mv	s5,a0
    800014b2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800014b4:	777d                	lui	a4,0xfffff
    800014b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800014ba:	fff60993          	addi	s3,a2,-1 # fff <_entry-0x7ffff001>
    800014be:	99ae                	add	s3,s3,a1
    800014c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800014c4:	893e                	mv	s2,a5
    800014c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800014ca:	6b85                	lui	s7,0x1
    800014cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800014d0:	4605                	li	a2,1
    800014d2:	85ca                	mv	a1,s2
    800014d4:	8556                	mv	a0,s5
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	eb8080e7          	jalr	-328(ra) # 8000138e <walk>
    800014de:	c51d                	beqz	a0,8000150c <mappages+0x72>
    if(*pte & PTE_V)
    800014e0:	611c                	ld	a5,0(a0)
    800014e2:	8b85                	andi	a5,a5,1
    800014e4:	ef81                	bnez	a5,800014fc <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800014e6:	80b1                	srli	s1,s1,0xc
    800014e8:	04aa                	slli	s1,s1,0xa
    800014ea:	0164e4b3          	or	s1,s1,s6
    800014ee:	0014e493          	ori	s1,s1,1
    800014f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800014f4:	03390863          	beq	s2,s3,80001524 <mappages+0x8a>
    a += PGSIZE;
    800014f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800014fa:	bfc9                	j	800014cc <mappages+0x32>
      panic("remap");
    800014fc:	00007517          	auipc	a0,0x7
    80001500:	c7450513          	addi	a0,a0,-908 # 80008170 <digits+0x130>
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	048080e7          	jalr	72(ra) # 8000054c <panic>
      return -1;
    8000150c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000150e:	60a6                	ld	ra,72(sp)
    80001510:	6406                	ld	s0,64(sp)
    80001512:	74e2                	ld	s1,56(sp)
    80001514:	7942                	ld	s2,48(sp)
    80001516:	79a2                	ld	s3,40(sp)
    80001518:	7a02                	ld	s4,32(sp)
    8000151a:	6ae2                	ld	s5,24(sp)
    8000151c:	6b42                	ld	s6,16(sp)
    8000151e:	6ba2                	ld	s7,8(sp)
    80001520:	6161                	addi	sp,sp,80
    80001522:	8082                	ret
  return 0;
    80001524:	4501                	li	a0,0
    80001526:	b7e5                	j	8000150e <mappages+0x74>

0000000080001528 <kvmmap>:
{
    80001528:	1141                	addi	sp,sp,-16
    8000152a:	e406                	sd	ra,8(sp)
    8000152c:	e022                	sd	s0,0(sp)
    8000152e:	0800                	addi	s0,sp,16
    80001530:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001532:	86ae                	mv	a3,a1
    80001534:	85aa                	mv	a1,a0
    80001536:	00008517          	auipc	a0,0x8
    8000153a:	ada53503          	ld	a0,-1318(a0) # 80009010 <kernel_pagetable>
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f5c080e7          	jalr	-164(ra) # 8000149a <mappages>
    80001546:	e509                	bnez	a0,80001550 <kvmmap+0x28>
}
    80001548:	60a2                	ld	ra,8(sp)
    8000154a:	6402                	ld	s0,0(sp)
    8000154c:	0141                	addi	sp,sp,16
    8000154e:	8082                	ret
    panic("kvmmap");
    80001550:	00007517          	auipc	a0,0x7
    80001554:	c2850513          	addi	a0,a0,-984 # 80008178 <digits+0x138>
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	ff4080e7          	jalr	-12(ra) # 8000054c <panic>

0000000080001560 <kvminit>:
{
    80001560:	1101                	addi	sp,sp,-32
    80001562:	ec06                	sd	ra,24(sp)
    80001564:	e822                	sd	s0,16(sp)
    80001566:	e426                	sd	s1,8(sp)
    80001568:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	5fe080e7          	jalr	1534(ra) # 80000b68 <kalloc>
    80001572:	00008717          	auipc	a4,0x8
    80001576:	a8a73f23          	sd	a0,-1378(a4) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000157a:	6605                	lui	a2,0x1
    8000157c:	4581                	li	a1,0
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	b44080e7          	jalr	-1212(ra) # 800010c2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001586:	4699                	li	a3,6
    80001588:	6605                	lui	a2,0x1
    8000158a:	100005b7          	lui	a1,0x10000
    8000158e:	10000537          	lui	a0,0x10000
    80001592:	00000097          	auipc	ra,0x0
    80001596:	f96080e7          	jalr	-106(ra) # 80001528 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000159a:	4699                	li	a3,6
    8000159c:	6605                	lui	a2,0x1
    8000159e:	100015b7          	lui	a1,0x10001
    800015a2:	10001537          	lui	a0,0x10001
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f82080e7          	jalr	-126(ra) # 80001528 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800015ae:	4699                	li	a3,6
    800015b0:	00400637          	lui	a2,0x400
    800015b4:	0c0005b7          	lui	a1,0xc000
    800015b8:	0c000537          	lui	a0,0xc000
    800015bc:	00000097          	auipc	ra,0x0
    800015c0:	f6c080e7          	jalr	-148(ra) # 80001528 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800015c4:	00007497          	auipc	s1,0x7
    800015c8:	a3c48493          	addi	s1,s1,-1476 # 80008000 <etext>
    800015cc:	46a9                	li	a3,10
    800015ce:	80007617          	auipc	a2,0x80007
    800015d2:	a3260613          	addi	a2,a2,-1486 # 8000 <_entry-0x7fff8000>
    800015d6:	4585                	li	a1,1
    800015d8:	05fe                	slli	a1,a1,0x1f
    800015da:	852e                	mv	a0,a1
    800015dc:	00000097          	auipc	ra,0x0
    800015e0:	f4c080e7          	jalr	-180(ra) # 80001528 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800015e4:	4699                	li	a3,6
    800015e6:	4645                	li	a2,17
    800015e8:	066e                	slli	a2,a2,0x1b
    800015ea:	8e05                	sub	a2,a2,s1
    800015ec:	85a6                	mv	a1,s1
    800015ee:	8526                	mv	a0,s1
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	f38080e7          	jalr	-200(ra) # 80001528 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800015f8:	46a9                	li	a3,10
    800015fa:	6605                	lui	a2,0x1
    800015fc:	00006597          	auipc	a1,0x6
    80001600:	a0458593          	addi	a1,a1,-1532 # 80007000 <_trampoline>
    80001604:	04000537          	lui	a0,0x4000
    80001608:	157d                	addi	a0,a0,-1 # 3ffffff <_entry-0x7c000001>
    8000160a:	0532                	slli	a0,a0,0xc
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	f1c080e7          	jalr	-228(ra) # 80001528 <kvmmap>
}
    80001614:	60e2                	ld	ra,24(sp)
    80001616:	6442                	ld	s0,16(sp)
    80001618:	64a2                	ld	s1,8(sp)
    8000161a:	6105                	addi	sp,sp,32
    8000161c:	8082                	ret

000000008000161e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000161e:	715d                	addi	sp,sp,-80
    80001620:	e486                	sd	ra,72(sp)
    80001622:	e0a2                	sd	s0,64(sp)
    80001624:	fc26                	sd	s1,56(sp)
    80001626:	f84a                	sd	s2,48(sp)
    80001628:	f44e                	sd	s3,40(sp)
    8000162a:	f052                	sd	s4,32(sp)
    8000162c:	ec56                	sd	s5,24(sp)
    8000162e:	e85a                	sd	s6,16(sp)
    80001630:	e45e                	sd	s7,8(sp)
    80001632:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001634:	03459793          	slli	a5,a1,0x34
    80001638:	e795                	bnez	a5,80001664 <uvmunmap+0x46>
    8000163a:	8a2a                	mv	s4,a0
    8000163c:	892e                	mv	s2,a1
    8000163e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001640:	0632                	slli	a2,a2,0xc
    80001642:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001646:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001648:	6b05                	lui	s6,0x1
    8000164a:	0735e263          	bltu	a1,s3,800016ae <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000164e:	60a6                	ld	ra,72(sp)
    80001650:	6406                	ld	s0,64(sp)
    80001652:	74e2                	ld	s1,56(sp)
    80001654:	7942                	ld	s2,48(sp)
    80001656:	79a2                	ld	s3,40(sp)
    80001658:	7a02                	ld	s4,32(sp)
    8000165a:	6ae2                	ld	s5,24(sp)
    8000165c:	6b42                	ld	s6,16(sp)
    8000165e:	6ba2                	ld	s7,8(sp)
    80001660:	6161                	addi	sp,sp,80
    80001662:	8082                	ret
    panic("uvmunmap: not aligned");
    80001664:	00007517          	auipc	a0,0x7
    80001668:	b1c50513          	addi	a0,a0,-1252 # 80008180 <digits+0x140>
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	ee0080e7          	jalr	-288(ra) # 8000054c <panic>
      panic("uvmunmap: walk");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b2450513          	addi	a0,a0,-1244 # 80008198 <digits+0x158>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ed0080e7          	jalr	-304(ra) # 8000054c <panic>
      panic("uvmunmap: not mapped");
    80001684:	00007517          	auipc	a0,0x7
    80001688:	b2450513          	addi	a0,a0,-1244 # 800081a8 <digits+0x168>
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	ec0080e7          	jalr	-320(ra) # 8000054c <panic>
      panic("uvmunmap: not a leaf");
    80001694:	00007517          	auipc	a0,0x7
    80001698:	b2c50513          	addi	a0,a0,-1236 # 800081c0 <digits+0x180>
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	eb0080e7          	jalr	-336(ra) # 8000054c <panic>
    *pte = 0;
    800016a4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016a8:	995a                	add	s2,s2,s6
    800016aa:	fb3972e3          	bgeu	s2,s3,8000164e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800016ae:	4601                	li	a2,0
    800016b0:	85ca                	mv	a1,s2
    800016b2:	8552                	mv	a0,s4
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	cda080e7          	jalr	-806(ra) # 8000138e <walk>
    800016bc:	84aa                	mv	s1,a0
    800016be:	d95d                	beqz	a0,80001674 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800016c0:	6108                	ld	a0,0(a0)
    800016c2:	00157793          	andi	a5,a0,1
    800016c6:	dfdd                	beqz	a5,80001684 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800016c8:	3ff57793          	andi	a5,a0,1023
    800016cc:	fd7784e3          	beq	a5,s7,80001694 <uvmunmap+0x76>
    if(do_free){
    800016d0:	fc0a8ae3          	beqz	s5,800016a4 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800016d4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800016d6:	0532                	slli	a0,a0,0xc
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	340080e7          	jalr	832(ra) # 80000a18 <kfree>
    800016e0:	b7d1                	j	800016a4 <uvmunmap+0x86>

00000000800016e2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800016e2:	1101                	addi	sp,sp,-32
    800016e4:	ec06                	sd	ra,24(sp)
    800016e6:	e822                	sd	s0,16(sp)
    800016e8:	e426                	sd	s1,8(sp)
    800016ea:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800016ec:	fffff097          	auipc	ra,0xfffff
    800016f0:	47c080e7          	jalr	1148(ra) # 80000b68 <kalloc>
    800016f4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800016f6:	c519                	beqz	a0,80001704 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800016f8:	6605                	lui	a2,0x1
    800016fa:	4581                	li	a1,0
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	9c6080e7          	jalr	-1594(ra) # 800010c2 <memset>
  return pagetable;
}
    80001704:	8526                	mv	a0,s1
    80001706:	60e2                	ld	ra,24(sp)
    80001708:	6442                	ld	s0,16(sp)
    8000170a:	64a2                	ld	s1,8(sp)
    8000170c:	6105                	addi	sp,sp,32
    8000170e:	8082                	ret

0000000080001710 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001710:	7179                	addi	sp,sp,-48
    80001712:	f406                	sd	ra,40(sp)
    80001714:	f022                	sd	s0,32(sp)
    80001716:	ec26                	sd	s1,24(sp)
    80001718:	e84a                	sd	s2,16(sp)
    8000171a:	e44e                	sd	s3,8(sp)
    8000171c:	e052                	sd	s4,0(sp)
    8000171e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001720:	6785                	lui	a5,0x1
    80001722:	04f67863          	bgeu	a2,a5,80001772 <uvminit+0x62>
    80001726:	8a2a                	mv	s4,a0
    80001728:	89ae                	mv	s3,a1
    8000172a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000172c:	fffff097          	auipc	ra,0xfffff
    80001730:	43c080e7          	jalr	1084(ra) # 80000b68 <kalloc>
    80001734:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001736:	6605                	lui	a2,0x1
    80001738:	4581                	li	a1,0
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	988080e7          	jalr	-1656(ra) # 800010c2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001742:	4779                	li	a4,30
    80001744:	86ca                	mv	a3,s2
    80001746:	6605                	lui	a2,0x1
    80001748:	4581                	li	a1,0
    8000174a:	8552                	mv	a0,s4
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	d4e080e7          	jalr	-690(ra) # 8000149a <mappages>
  memmove(mem, src, sz);
    80001754:	8626                	mv	a2,s1
    80001756:	85ce                	mv	a1,s3
    80001758:	854a                	mv	a0,s2
    8000175a:	00000097          	auipc	ra,0x0
    8000175e:	9c4080e7          	jalr	-1596(ra) # 8000111e <memmove>
}
    80001762:	70a2                	ld	ra,40(sp)
    80001764:	7402                	ld	s0,32(sp)
    80001766:	64e2                	ld	s1,24(sp)
    80001768:	6942                	ld	s2,16(sp)
    8000176a:	69a2                	ld	s3,8(sp)
    8000176c:	6a02                	ld	s4,0(sp)
    8000176e:	6145                	addi	sp,sp,48
    80001770:	8082                	ret
    panic("inituvm: more than a page");
    80001772:	00007517          	auipc	a0,0x7
    80001776:	a6650513          	addi	a0,a0,-1434 # 800081d8 <digits+0x198>
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	dd2080e7          	jalr	-558(ra) # 8000054c <panic>

0000000080001782 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001782:	1101                	addi	sp,sp,-32
    80001784:	ec06                	sd	ra,24(sp)
    80001786:	e822                	sd	s0,16(sp)
    80001788:	e426                	sd	s1,8(sp)
    8000178a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000178c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000178e:	00b67d63          	bgeu	a2,a1,800017a8 <uvmdealloc+0x26>
    80001792:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001794:	6785                	lui	a5,0x1
    80001796:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001798:	00f60733          	add	a4,a2,a5
    8000179c:	76fd                	lui	a3,0xfffff
    8000179e:	8f75                	and	a4,a4,a3
    800017a0:	97ae                	add	a5,a5,a1
    800017a2:	8ff5                	and	a5,a5,a3
    800017a4:	00f76863          	bltu	a4,a5,800017b4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800017a8:	8526                	mv	a0,s1
    800017aa:	60e2                	ld	ra,24(sp)
    800017ac:	6442                	ld	s0,16(sp)
    800017ae:	64a2                	ld	s1,8(sp)
    800017b0:	6105                	addi	sp,sp,32
    800017b2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800017b4:	8f99                	sub	a5,a5,a4
    800017b6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800017b8:	4685                	li	a3,1
    800017ba:	0007861b          	sext.w	a2,a5
    800017be:	85ba                	mv	a1,a4
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	e5e080e7          	jalr	-418(ra) # 8000161e <uvmunmap>
    800017c8:	b7c5                	j	800017a8 <uvmdealloc+0x26>

00000000800017ca <uvmalloc>:
  if(newsz < oldsz)
    800017ca:	0ab66163          	bltu	a2,a1,8000186c <uvmalloc+0xa2>
{
    800017ce:	7139                	addi	sp,sp,-64
    800017d0:	fc06                	sd	ra,56(sp)
    800017d2:	f822                	sd	s0,48(sp)
    800017d4:	f426                	sd	s1,40(sp)
    800017d6:	f04a                	sd	s2,32(sp)
    800017d8:	ec4e                	sd	s3,24(sp)
    800017da:	e852                	sd	s4,16(sp)
    800017dc:	e456                	sd	s5,8(sp)
    800017de:	0080                	addi	s0,sp,64
    800017e0:	8aaa                	mv	s5,a0
    800017e2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800017e4:	6785                	lui	a5,0x1
    800017e6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800017e8:	95be                	add	a1,a1,a5
    800017ea:	77fd                	lui	a5,0xfffff
    800017ec:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800017f0:	08c9f063          	bgeu	s3,a2,80001870 <uvmalloc+0xa6>
    800017f4:	894e                	mv	s2,s3
    mem = kalloc();
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	372080e7          	jalr	882(ra) # 80000b68 <kalloc>
    800017fe:	84aa                	mv	s1,a0
    if(mem == 0){
    80001800:	c51d                	beqz	a0,8000182e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001802:	6605                	lui	a2,0x1
    80001804:	4581                	li	a1,0
    80001806:	00000097          	auipc	ra,0x0
    8000180a:	8bc080e7          	jalr	-1860(ra) # 800010c2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000180e:	4779                	li	a4,30
    80001810:	86a6                	mv	a3,s1
    80001812:	6605                	lui	a2,0x1
    80001814:	85ca                	mv	a1,s2
    80001816:	8556                	mv	a0,s5
    80001818:	00000097          	auipc	ra,0x0
    8000181c:	c82080e7          	jalr	-894(ra) # 8000149a <mappages>
    80001820:	e905                	bnez	a0,80001850 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001822:	6785                	lui	a5,0x1
    80001824:	993e                	add	s2,s2,a5
    80001826:	fd4968e3          	bltu	s2,s4,800017f6 <uvmalloc+0x2c>
  return newsz;
    8000182a:	8552                	mv	a0,s4
    8000182c:	a809                	j	8000183e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000182e:	864e                	mv	a2,s3
    80001830:	85ca                	mv	a1,s2
    80001832:	8556                	mv	a0,s5
    80001834:	00000097          	auipc	ra,0x0
    80001838:	f4e080e7          	jalr	-178(ra) # 80001782 <uvmdealloc>
      return 0;
    8000183c:	4501                	li	a0,0
}
    8000183e:	70e2                	ld	ra,56(sp)
    80001840:	7442                	ld	s0,48(sp)
    80001842:	74a2                	ld	s1,40(sp)
    80001844:	7902                	ld	s2,32(sp)
    80001846:	69e2                	ld	s3,24(sp)
    80001848:	6a42                	ld	s4,16(sp)
    8000184a:	6aa2                	ld	s5,8(sp)
    8000184c:	6121                	addi	sp,sp,64
    8000184e:	8082                	ret
      kfree(mem);
    80001850:	8526                	mv	a0,s1
    80001852:	fffff097          	auipc	ra,0xfffff
    80001856:	1c6080e7          	jalr	454(ra) # 80000a18 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000185a:	864e                	mv	a2,s3
    8000185c:	85ca                	mv	a1,s2
    8000185e:	8556                	mv	a0,s5
    80001860:	00000097          	auipc	ra,0x0
    80001864:	f22080e7          	jalr	-222(ra) # 80001782 <uvmdealloc>
      return 0;
    80001868:	4501                	li	a0,0
    8000186a:	bfd1                	j	8000183e <uvmalloc+0x74>
    return oldsz;
    8000186c:	852e                	mv	a0,a1
}
    8000186e:	8082                	ret
  return newsz;
    80001870:	8532                	mv	a0,a2
    80001872:	b7f1                	j	8000183e <uvmalloc+0x74>

0000000080001874 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001874:	7179                	addi	sp,sp,-48
    80001876:	f406                	sd	ra,40(sp)
    80001878:	f022                	sd	s0,32(sp)
    8000187a:	ec26                	sd	s1,24(sp)
    8000187c:	e84a                	sd	s2,16(sp)
    8000187e:	e44e                	sd	s3,8(sp)
    80001880:	e052                	sd	s4,0(sp)
    80001882:	1800                	addi	s0,sp,48
    80001884:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001886:	84aa                	mv	s1,a0
    80001888:	6905                	lui	s2,0x1
    8000188a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000188c:	4985                	li	s3,1
    8000188e:	a829                	j	800018a8 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001890:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001892:	00c79513          	slli	a0,a5,0xc
    80001896:	00000097          	auipc	ra,0x0
    8000189a:	fde080e7          	jalr	-34(ra) # 80001874 <freewalk>
      pagetable[i] = 0;
    8000189e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800018a2:	04a1                	addi	s1,s1,8
    800018a4:	03248163          	beq	s1,s2,800018c6 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800018a8:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800018aa:	00f7f713          	andi	a4,a5,15
    800018ae:	ff3701e3          	beq	a4,s3,80001890 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800018b2:	8b85                	andi	a5,a5,1
    800018b4:	d7fd                	beqz	a5,800018a2 <freewalk+0x2e>
      panic("freewalk: leaf");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	94250513          	addi	a0,a0,-1726 # 800081f8 <digits+0x1b8>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c8e080e7          	jalr	-882(ra) # 8000054c <panic>
    }
  }
  kfree((void*)pagetable);
    800018c6:	8552                	mv	a0,s4
    800018c8:	fffff097          	auipc	ra,0xfffff
    800018cc:	150080e7          	jalr	336(ra) # 80000a18 <kfree>
}
    800018d0:	70a2                	ld	ra,40(sp)
    800018d2:	7402                	ld	s0,32(sp)
    800018d4:	64e2                	ld	s1,24(sp)
    800018d6:	6942                	ld	s2,16(sp)
    800018d8:	69a2                	ld	s3,8(sp)
    800018da:	6a02                	ld	s4,0(sp)
    800018dc:	6145                	addi	sp,sp,48
    800018de:	8082                	ret

00000000800018e0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800018e0:	1101                	addi	sp,sp,-32
    800018e2:	ec06                	sd	ra,24(sp)
    800018e4:	e822                	sd	s0,16(sp)
    800018e6:	e426                	sd	s1,8(sp)
    800018e8:	1000                	addi	s0,sp,32
    800018ea:	84aa                	mv	s1,a0
  if(sz > 0)
    800018ec:	e999                	bnez	a1,80001902 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800018ee:	8526                	mv	a0,s1
    800018f0:	00000097          	auipc	ra,0x0
    800018f4:	f84080e7          	jalr	-124(ra) # 80001874 <freewalk>
}
    800018f8:	60e2                	ld	ra,24(sp)
    800018fa:	6442                	ld	s0,16(sp)
    800018fc:	64a2                	ld	s1,8(sp)
    800018fe:	6105                	addi	sp,sp,32
    80001900:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001902:	6785                	lui	a5,0x1
    80001904:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001906:	95be                	add	a1,a1,a5
    80001908:	4685                	li	a3,1
    8000190a:	00c5d613          	srli	a2,a1,0xc
    8000190e:	4581                	li	a1,0
    80001910:	00000097          	auipc	ra,0x0
    80001914:	d0e080e7          	jalr	-754(ra) # 8000161e <uvmunmap>
    80001918:	bfd9                	j	800018ee <uvmfree+0xe>

000000008000191a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000191a:	c679                	beqz	a2,800019e8 <uvmcopy+0xce>
{
    8000191c:	715d                	addi	sp,sp,-80
    8000191e:	e486                	sd	ra,72(sp)
    80001920:	e0a2                	sd	s0,64(sp)
    80001922:	fc26                	sd	s1,56(sp)
    80001924:	f84a                	sd	s2,48(sp)
    80001926:	f44e                	sd	s3,40(sp)
    80001928:	f052                	sd	s4,32(sp)
    8000192a:	ec56                	sd	s5,24(sp)
    8000192c:	e85a                	sd	s6,16(sp)
    8000192e:	e45e                	sd	s7,8(sp)
    80001930:	0880                	addi	s0,sp,80
    80001932:	8b2a                	mv	s6,a0
    80001934:	8aae                	mv	s5,a1
    80001936:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001938:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000193a:	4601                	li	a2,0
    8000193c:	85ce                	mv	a1,s3
    8000193e:	855a                	mv	a0,s6
    80001940:	00000097          	auipc	ra,0x0
    80001944:	a4e080e7          	jalr	-1458(ra) # 8000138e <walk>
    80001948:	c531                	beqz	a0,80001994 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000194a:	6118                	ld	a4,0(a0)
    8000194c:	00177793          	andi	a5,a4,1
    80001950:	cbb1                	beqz	a5,800019a4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001952:	00a75593          	srli	a1,a4,0xa
    80001956:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000195a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	20a080e7          	jalr	522(ra) # 80000b68 <kalloc>
    80001966:	892a                	mv	s2,a0
    80001968:	c939                	beqz	a0,800019be <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000196a:	6605                	lui	a2,0x1
    8000196c:	85de                	mv	a1,s7
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	7b0080e7          	jalr	1968(ra) # 8000111e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001976:	8726                	mv	a4,s1
    80001978:	86ca                	mv	a3,s2
    8000197a:	6605                	lui	a2,0x1
    8000197c:	85ce                	mv	a1,s3
    8000197e:	8556                	mv	a0,s5
    80001980:	00000097          	auipc	ra,0x0
    80001984:	b1a080e7          	jalr	-1254(ra) # 8000149a <mappages>
    80001988:	e515                	bnez	a0,800019b4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000198a:	6785                	lui	a5,0x1
    8000198c:	99be                	add	s3,s3,a5
    8000198e:	fb49e6e3          	bltu	s3,s4,8000193a <uvmcopy+0x20>
    80001992:	a081                	j	800019d2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001994:	00007517          	auipc	a0,0x7
    80001998:	87450513          	addi	a0,a0,-1932 # 80008208 <digits+0x1c8>
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	bb0080e7          	jalr	-1104(ra) # 8000054c <panic>
      panic("uvmcopy: page not present");
    800019a4:	00007517          	auipc	a0,0x7
    800019a8:	88450513          	addi	a0,a0,-1916 # 80008228 <digits+0x1e8>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	ba0080e7          	jalr	-1120(ra) # 8000054c <panic>
      kfree(mem);
    800019b4:	854a                	mv	a0,s2
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	062080e7          	jalr	98(ra) # 80000a18 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800019be:	4685                	li	a3,1
    800019c0:	00c9d613          	srli	a2,s3,0xc
    800019c4:	4581                	li	a1,0
    800019c6:	8556                	mv	a0,s5
    800019c8:	00000097          	auipc	ra,0x0
    800019cc:	c56080e7          	jalr	-938(ra) # 8000161e <uvmunmap>
  return -1;
    800019d0:	557d                	li	a0,-1
}
    800019d2:	60a6                	ld	ra,72(sp)
    800019d4:	6406                	ld	s0,64(sp)
    800019d6:	74e2                	ld	s1,56(sp)
    800019d8:	7942                	ld	s2,48(sp)
    800019da:	79a2                	ld	s3,40(sp)
    800019dc:	7a02                	ld	s4,32(sp)
    800019de:	6ae2                	ld	s5,24(sp)
    800019e0:	6b42                	ld	s6,16(sp)
    800019e2:	6ba2                	ld	s7,8(sp)
    800019e4:	6161                	addi	sp,sp,80
    800019e6:	8082                	ret
  return 0;
    800019e8:	4501                	li	a0,0
}
    800019ea:	8082                	ret

00000000800019ec <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800019ec:	1141                	addi	sp,sp,-16
    800019ee:	e406                	sd	ra,8(sp)
    800019f0:	e022                	sd	s0,0(sp)
    800019f2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800019f4:	4601                	li	a2,0
    800019f6:	00000097          	auipc	ra,0x0
    800019fa:	998080e7          	jalr	-1640(ra) # 8000138e <walk>
  if(pte == 0)
    800019fe:	c901                	beqz	a0,80001a0e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a00:	611c                	ld	a5,0(a0)
    80001a02:	9bbd                	andi	a5,a5,-17
    80001a04:	e11c                	sd	a5,0(a0)
}
    80001a06:	60a2                	ld	ra,8(sp)
    80001a08:	6402                	ld	s0,0(sp)
    80001a0a:	0141                	addi	sp,sp,16
    80001a0c:	8082                	ret
    panic("uvmclear");
    80001a0e:	00007517          	auipc	a0,0x7
    80001a12:	83a50513          	addi	a0,a0,-1990 # 80008248 <digits+0x208>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	b36080e7          	jalr	-1226(ra) # 8000054c <panic>

0000000080001a1e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a1e:	c6bd                	beqz	a3,80001a8c <copyout+0x6e>
{
    80001a20:	715d                	addi	sp,sp,-80
    80001a22:	e486                	sd	ra,72(sp)
    80001a24:	e0a2                	sd	s0,64(sp)
    80001a26:	fc26                	sd	s1,56(sp)
    80001a28:	f84a                	sd	s2,48(sp)
    80001a2a:	f44e                	sd	s3,40(sp)
    80001a2c:	f052                	sd	s4,32(sp)
    80001a2e:	ec56                	sd	s5,24(sp)
    80001a30:	e85a                	sd	s6,16(sp)
    80001a32:	e45e                	sd	s7,8(sp)
    80001a34:	e062                	sd	s8,0(sp)
    80001a36:	0880                	addi	s0,sp,80
    80001a38:	8b2a                	mv	s6,a0
    80001a3a:	8c2e                	mv	s8,a1
    80001a3c:	8a32                	mv	s4,a2
    80001a3e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001a40:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001a42:	6a85                	lui	s5,0x1
    80001a44:	a015                	j	80001a68 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001a46:	9562                	add	a0,a0,s8
    80001a48:	0004861b          	sext.w	a2,s1
    80001a4c:	85d2                	mv	a1,s4
    80001a4e:	41250533          	sub	a0,a0,s2
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	6cc080e7          	jalr	1740(ra) # 8000111e <memmove>

    len -= n;
    80001a5a:	409989b3          	sub	s3,s3,s1
    src += n;
    80001a5e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001a60:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a64:	02098263          	beqz	s3,80001a88 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001a68:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a6c:	85ca                	mv	a1,s2
    80001a6e:	855a                	mv	a0,s6
    80001a70:	00000097          	auipc	ra,0x0
    80001a74:	9e8080e7          	jalr	-1560(ra) # 80001458 <walkaddr>
    if(pa0 == 0)
    80001a78:	cd01                	beqz	a0,80001a90 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001a7a:	418904b3          	sub	s1,s2,s8
    80001a7e:	94d6                	add	s1,s1,s5
    80001a80:	fc99f3e3          	bgeu	s3,s1,80001a46 <copyout+0x28>
    80001a84:	84ce                	mv	s1,s3
    80001a86:	b7c1                	j	80001a46 <copyout+0x28>
  }
  return 0;
    80001a88:	4501                	li	a0,0
    80001a8a:	a021                	j	80001a92 <copyout+0x74>
    80001a8c:	4501                	li	a0,0
}
    80001a8e:	8082                	ret
      return -1;
    80001a90:	557d                	li	a0,-1
}
    80001a92:	60a6                	ld	ra,72(sp)
    80001a94:	6406                	ld	s0,64(sp)
    80001a96:	74e2                	ld	s1,56(sp)
    80001a98:	7942                	ld	s2,48(sp)
    80001a9a:	79a2                	ld	s3,40(sp)
    80001a9c:	7a02                	ld	s4,32(sp)
    80001a9e:	6ae2                	ld	s5,24(sp)
    80001aa0:	6b42                	ld	s6,16(sp)
    80001aa2:	6ba2                	ld	s7,8(sp)
    80001aa4:	6c02                	ld	s8,0(sp)
    80001aa6:	6161                	addi	sp,sp,80
    80001aa8:	8082                	ret

0000000080001aaa <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001aaa:	caa5                	beqz	a3,80001b1a <copyin+0x70>
{
    80001aac:	715d                	addi	sp,sp,-80
    80001aae:	e486                	sd	ra,72(sp)
    80001ab0:	e0a2                	sd	s0,64(sp)
    80001ab2:	fc26                	sd	s1,56(sp)
    80001ab4:	f84a                	sd	s2,48(sp)
    80001ab6:	f44e                	sd	s3,40(sp)
    80001ab8:	f052                	sd	s4,32(sp)
    80001aba:	ec56                	sd	s5,24(sp)
    80001abc:	e85a                	sd	s6,16(sp)
    80001abe:	e45e                	sd	s7,8(sp)
    80001ac0:	e062                	sd	s8,0(sp)
    80001ac2:	0880                	addi	s0,sp,80
    80001ac4:	8b2a                	mv	s6,a0
    80001ac6:	8a2e                	mv	s4,a1
    80001ac8:	8c32                	mv	s8,a2
    80001aca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001acc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ace:	6a85                	lui	s5,0x1
    80001ad0:	a01d                	j	80001af6 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001ad2:	018505b3          	add	a1,a0,s8
    80001ad6:	0004861b          	sext.w	a2,s1
    80001ada:	412585b3          	sub	a1,a1,s2
    80001ade:	8552                	mv	a0,s4
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	63e080e7          	jalr	1598(ra) # 8000111e <memmove>

    len -= n;
    80001ae8:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001aec:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001aee:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001af2:	02098263          	beqz	s3,80001b16 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001af6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001afa:	85ca                	mv	a1,s2
    80001afc:	855a                	mv	a0,s6
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	95a080e7          	jalr	-1702(ra) # 80001458 <walkaddr>
    if(pa0 == 0)
    80001b06:	cd01                	beqz	a0,80001b1e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001b08:	418904b3          	sub	s1,s2,s8
    80001b0c:	94d6                	add	s1,s1,s5
    80001b0e:	fc99f2e3          	bgeu	s3,s1,80001ad2 <copyin+0x28>
    80001b12:	84ce                	mv	s1,s3
    80001b14:	bf7d                	j	80001ad2 <copyin+0x28>
  }
  return 0;
    80001b16:	4501                	li	a0,0
    80001b18:	a021                	j	80001b20 <copyin+0x76>
    80001b1a:	4501                	li	a0,0
}
    80001b1c:	8082                	ret
      return -1;
    80001b1e:	557d                	li	a0,-1
}
    80001b20:	60a6                	ld	ra,72(sp)
    80001b22:	6406                	ld	s0,64(sp)
    80001b24:	74e2                	ld	s1,56(sp)
    80001b26:	7942                	ld	s2,48(sp)
    80001b28:	79a2                	ld	s3,40(sp)
    80001b2a:	7a02                	ld	s4,32(sp)
    80001b2c:	6ae2                	ld	s5,24(sp)
    80001b2e:	6b42                	ld	s6,16(sp)
    80001b30:	6ba2                	ld	s7,8(sp)
    80001b32:	6c02                	ld	s8,0(sp)
    80001b34:	6161                	addi	sp,sp,80
    80001b36:	8082                	ret

0000000080001b38 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001b38:	c2dd                	beqz	a3,80001bde <copyinstr+0xa6>
{
    80001b3a:	715d                	addi	sp,sp,-80
    80001b3c:	e486                	sd	ra,72(sp)
    80001b3e:	e0a2                	sd	s0,64(sp)
    80001b40:	fc26                	sd	s1,56(sp)
    80001b42:	f84a                	sd	s2,48(sp)
    80001b44:	f44e                	sd	s3,40(sp)
    80001b46:	f052                	sd	s4,32(sp)
    80001b48:	ec56                	sd	s5,24(sp)
    80001b4a:	e85a                	sd	s6,16(sp)
    80001b4c:	e45e                	sd	s7,8(sp)
    80001b4e:	0880                	addi	s0,sp,80
    80001b50:	8a2a                	mv	s4,a0
    80001b52:	8b2e                	mv	s6,a1
    80001b54:	8bb2                	mv	s7,a2
    80001b56:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001b58:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b5a:	6985                	lui	s3,0x1
    80001b5c:	a02d                	j	80001b86 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001b5e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001b62:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001b64:	37fd                	addiw	a5,a5,-1
    80001b66:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001b6a:	60a6                	ld	ra,72(sp)
    80001b6c:	6406                	ld	s0,64(sp)
    80001b6e:	74e2                	ld	s1,56(sp)
    80001b70:	7942                	ld	s2,48(sp)
    80001b72:	79a2                	ld	s3,40(sp)
    80001b74:	7a02                	ld	s4,32(sp)
    80001b76:	6ae2                	ld	s5,24(sp)
    80001b78:	6b42                	ld	s6,16(sp)
    80001b7a:	6ba2                	ld	s7,8(sp)
    80001b7c:	6161                	addi	sp,sp,80
    80001b7e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001b80:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001b84:	c8a9                	beqz	s1,80001bd6 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001b86:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001b8a:	85ca                	mv	a1,s2
    80001b8c:	8552                	mv	a0,s4
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	8ca080e7          	jalr	-1846(ra) # 80001458 <walkaddr>
    if(pa0 == 0)
    80001b96:	c131                	beqz	a0,80001bda <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001b98:	417906b3          	sub	a3,s2,s7
    80001b9c:	96ce                	add	a3,a3,s3
    80001b9e:	00d4f363          	bgeu	s1,a3,80001ba4 <copyinstr+0x6c>
    80001ba2:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001ba4:	955e                	add	a0,a0,s7
    80001ba6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001baa:	daf9                	beqz	a3,80001b80 <copyinstr+0x48>
    80001bac:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001bae:	41650633          	sub	a2,a0,s6
    80001bb2:	fff48593          	addi	a1,s1,-1
    80001bb6:	95da                	add	a1,a1,s6
    while(n > 0){
    80001bb8:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001bba:	00f60733          	add	a4,a2,a5
    80001bbe:	00074703          	lbu	a4,0(a4)
    80001bc2:	df51                	beqz	a4,80001b5e <copyinstr+0x26>
        *dst = *p;
    80001bc4:	00e78023          	sb	a4,0(a5)
      --max;
    80001bc8:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001bcc:	0785                	addi	a5,a5,1
    while(n > 0){
    80001bce:	fed796e3          	bne	a5,a3,80001bba <copyinstr+0x82>
      dst++;
    80001bd2:	8b3e                	mv	s6,a5
    80001bd4:	b775                	j	80001b80 <copyinstr+0x48>
    80001bd6:	4781                	li	a5,0
    80001bd8:	b771                	j	80001b64 <copyinstr+0x2c>
      return -1;
    80001bda:	557d                	li	a0,-1
    80001bdc:	b779                	j	80001b6a <copyinstr+0x32>
  int got_null = 0;
    80001bde:	4781                	li	a5,0
  if(got_null){
    80001be0:	37fd                	addiw	a5,a5,-1
    80001be2:	0007851b          	sext.w	a0,a5
}
    80001be6:	8082                	ret

0000000080001be8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001be8:	1101                	addi	sp,sp,-32
    80001bea:	ec06                	sd	ra,24(sp)
    80001bec:	e822                	sd	s0,16(sp)
    80001bee:	e426                	sd	s1,8(sp)
    80001bf0:	1000                	addi	s0,sp,32
    80001bf2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	074080e7          	jalr	116(ra) # 80000c68 <holding>
    80001bfc:	c909                	beqz	a0,80001c0e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001bfe:	789c                	ld	a5,48(s1)
    80001c00:	00978f63          	beq	a5,s1,80001c1e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c04:	60e2                	ld	ra,24(sp)
    80001c06:	6442                	ld	s0,16(sp)
    80001c08:	64a2                	ld	s1,8(sp)
    80001c0a:	6105                	addi	sp,sp,32
    80001c0c:	8082                	ret
    panic("wakeup1");
    80001c0e:	00006517          	auipc	a0,0x6
    80001c12:	64a50513          	addi	a0,a0,1610 # 80008258 <digits+0x218>
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	936080e7          	jalr	-1738(ra) # 8000054c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c1e:	5098                	lw	a4,32(s1)
    80001c20:	4785                	li	a5,1
    80001c22:	fef711e3          	bne	a4,a5,80001c04 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001c26:	4789                	li	a5,2
    80001c28:	d09c                	sw	a5,32(s1)
}
    80001c2a:	bfe9                	j	80001c04 <wakeup1+0x1c>

0000000080001c2c <procinit>:
{
    80001c2c:	715d                	addi	sp,sp,-80
    80001c2e:	e486                	sd	ra,72(sp)
    80001c30:	e0a2                	sd	s0,64(sp)
    80001c32:	fc26                	sd	s1,56(sp)
    80001c34:	f84a                	sd	s2,48(sp)
    80001c36:	f44e                	sd	s3,40(sp)
    80001c38:	f052                	sd	s4,32(sp)
    80001c3a:	ec56                	sd	s5,24(sp)
    80001c3c:	e85a                	sd	s6,16(sp)
    80001c3e:	e45e                	sd	s7,8(sp)
    80001c40:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001c42:	00006597          	auipc	a1,0x6
    80001c46:	61e58593          	addi	a1,a1,1566 # 80008260 <digits+0x220>
    80001c4a:	00010517          	auipc	a0,0x10
    80001c4e:	73e50513          	addi	a0,a0,1854 # 80012388 <pid_lock>
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	20c080e7          	jalr	524(ra) # 80000e5e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5a:	00011917          	auipc	s2,0x11
    80001c5e:	b4e90913          	addi	s2,s2,-1202 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001c62:	00006b97          	auipc	s7,0x6
    80001c66:	606b8b93          	addi	s7,s7,1542 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001c6a:	8b4a                	mv	s6,s2
    80001c6c:	00006a97          	auipc	s5,0x6
    80001c70:	394a8a93          	addi	s5,s5,916 # 80008000 <etext>
    80001c74:	040009b7          	lui	s3,0x4000
    80001c78:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001c7a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c7c:	00016a17          	auipc	s4,0x16
    80001c80:	72ca0a13          	addi	s4,s4,1836 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001c84:	85de                	mv	a1,s7
    80001c86:	854a                	mv	a0,s2
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	1d6080e7          	jalr	470(ra) # 80000e5e <initlock>
      char *pa = kalloc();
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	ed8080e7          	jalr	-296(ra) # 80000b68 <kalloc>
    80001c98:	85aa                	mv	a1,a0
      if(pa == 0)
    80001c9a:	c929                	beqz	a0,80001cec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001c9c:	416904b3          	sub	s1,s2,s6
    80001ca0:	8491                	srai	s1,s1,0x4
    80001ca2:	000ab783          	ld	a5,0(s5)
    80001ca6:	02f484b3          	mul	s1,s1,a5
    80001caa:	2485                	addiw	s1,s1,1
    80001cac:	00d4949b          	slliw	s1,s1,0xd
    80001cb0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001cb4:	4699                	li	a3,6
    80001cb6:	6605                	lui	a2,0x1
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	86e080e7          	jalr	-1938(ra) # 80001528 <kvmmap>
      p->kstack = va;
    80001cc2:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cc6:	17090913          	addi	s2,s2,368
    80001cca:	fb491de3          	bne	s2,s4,80001c84 <procinit+0x58>
  kvminithart();
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	766080e7          	jalr	1894(ra) # 80001434 <kvminithart>
}
    80001cd6:	60a6                	ld	ra,72(sp)
    80001cd8:	6406                	ld	s0,64(sp)
    80001cda:	74e2                	ld	s1,56(sp)
    80001cdc:	7942                	ld	s2,48(sp)
    80001cde:	79a2                	ld	s3,40(sp)
    80001ce0:	7a02                	ld	s4,32(sp)
    80001ce2:	6ae2                	ld	s5,24(sp)
    80001ce4:	6b42                	ld	s6,16(sp)
    80001ce6:	6ba2                	ld	s7,8(sp)
    80001ce8:	6161                	addi	sp,sp,80
    80001cea:	8082                	ret
        panic("kalloc");
    80001cec:	00006517          	auipc	a0,0x6
    80001cf0:	58450513          	addi	a0,a0,1412 # 80008270 <digits+0x230>
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	858080e7          	jalr	-1960(ra) # 8000054c <panic>

0000000080001cfc <cpuid>:
{
    80001cfc:	1141                	addi	sp,sp,-16
    80001cfe:	e422                	sd	s0,8(sp)
    80001d00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d02:	8512                	mv	a0,tp
}
    80001d04:	2501                	sext.w	a0,a0
    80001d06:	6422                	ld	s0,8(sp)
    80001d08:	0141                	addi	sp,sp,16
    80001d0a:	8082                	ret

0000000080001d0c <mycpu>:
mycpu(void) {
    80001d0c:	1141                	addi	sp,sp,-16
    80001d0e:	e422                	sd	s0,8(sp)
    80001d10:	0800                	addi	s0,sp,16
    80001d12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d14:	2781                	sext.w	a5,a5
    80001d16:	079e                	slli	a5,a5,0x7
}
    80001d18:	00010517          	auipc	a0,0x10
    80001d1c:	69050513          	addi	a0,a0,1680 # 800123a8 <cpus>
    80001d20:	953e                	add	a0,a0,a5
    80001d22:	6422                	ld	s0,8(sp)
    80001d24:	0141                	addi	sp,sp,16
    80001d26:	8082                	ret

0000000080001d28 <myproc>:
myproc(void) {
    80001d28:	1101                	addi	sp,sp,-32
    80001d2a:	ec06                	sd	ra,24(sp)
    80001d2c:	e822                	sd	s0,16(sp)
    80001d2e:	e426                	sd	s1,8(sp)
    80001d30:	1000                	addi	s0,sp,32
  push_off();
    80001d32:	fffff097          	auipc	ra,0xfffff
    80001d36:	f64080e7          	jalr	-156(ra) # 80000c96 <push_off>
    80001d3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001d3c:	2781                	sext.w	a5,a5
    80001d3e:	079e                	slli	a5,a5,0x7
    80001d40:	00010717          	auipc	a4,0x10
    80001d44:	64870713          	addi	a4,a4,1608 # 80012388 <pid_lock>
    80001d48:	97ba                	add	a5,a5,a4
    80001d4a:	7384                	ld	s1,32(a5)
  pop_off();
    80001d4c:	fffff097          	auipc	ra,0xfffff
    80001d50:	006080e7          	jalr	6(ra) # 80000d52 <pop_off>
}
    80001d54:	8526                	mv	a0,s1
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6105                	addi	sp,sp,32
    80001d5e:	8082                	ret

0000000080001d60 <forkret>:
{
    80001d60:	1141                	addi	sp,sp,-16
    80001d62:	e406                	sd	ra,8(sp)
    80001d64:	e022                	sd	s0,0(sp)
    80001d66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	fc0080e7          	jalr	-64(ra) # 80001d28 <myproc>
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	042080e7          	jalr	66(ra) # 80000db2 <release>
  if (first) {
    80001d78:	00007797          	auipc	a5,0x7
    80001d7c:	b387a783          	lw	a5,-1224(a5) # 800088b0 <first.1>
    80001d80:	eb89                	bnez	a5,80001d92 <forkret+0x32>
  usertrapret();
    80001d82:	00001097          	auipc	ra,0x1
    80001d86:	c1e080e7          	jalr	-994(ra) # 800029a0 <usertrapret>
}
    80001d8a:	60a2                	ld	ra,8(sp)
    80001d8c:	6402                	ld	s0,0(sp)
    80001d8e:	0141                	addi	sp,sp,16
    80001d90:	8082                	ret
    first = 0;
    80001d92:	00007797          	auipc	a5,0x7
    80001d96:	b007af23          	sw	zero,-1250(a5) # 800088b0 <first.1>
    fsinit(ROOTDEV);
    80001d9a:	4505                	li	a0,1
    80001d9c:	00002097          	auipc	ra,0x2
    80001da0:	af0080e7          	jalr	-1296(ra) # 8000388c <fsinit>
    80001da4:	bff9                	j	80001d82 <forkret+0x22>

0000000080001da6 <allocpid>:
allocpid() {
    80001da6:	1101                	addi	sp,sp,-32
    80001da8:	ec06                	sd	ra,24(sp)
    80001daa:	e822                	sd	s0,16(sp)
    80001dac:	e426                	sd	s1,8(sp)
    80001dae:	e04a                	sd	s2,0(sp)
    80001db0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001db2:	00010917          	auipc	s2,0x10
    80001db6:	5d690913          	addi	s2,s2,1494 # 80012388 <pid_lock>
    80001dba:	854a                	mv	a0,s2
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	f26080e7          	jalr	-218(ra) # 80000ce2 <acquire>
  pid = nextpid;
    80001dc4:	00007797          	auipc	a5,0x7
    80001dc8:	af078793          	addi	a5,a5,-1296 # 800088b4 <nextpid>
    80001dcc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dce:	0014871b          	addiw	a4,s1,1
    80001dd2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dd4:	854a                	mv	a0,s2
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	fdc080e7          	jalr	-36(ra) # 80000db2 <release>
}
    80001dde:	8526                	mv	a0,s1
    80001de0:	60e2                	ld	ra,24(sp)
    80001de2:	6442                	ld	s0,16(sp)
    80001de4:	64a2                	ld	s1,8(sp)
    80001de6:	6902                	ld	s2,0(sp)
    80001de8:	6105                	addi	sp,sp,32
    80001dea:	8082                	ret

0000000080001dec <proc_pagetable>:
{
    80001dec:	1101                	addi	sp,sp,-32
    80001dee:	ec06                	sd	ra,24(sp)
    80001df0:	e822                	sd	s0,16(sp)
    80001df2:	e426                	sd	s1,8(sp)
    80001df4:	e04a                	sd	s2,0(sp)
    80001df6:	1000                	addi	s0,sp,32
    80001df8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001dfa:	00000097          	auipc	ra,0x0
    80001dfe:	8e8080e7          	jalr	-1816(ra) # 800016e2 <uvmcreate>
    80001e02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e04:	c121                	beqz	a0,80001e44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e06:	4729                	li	a4,10
    80001e08:	00005697          	auipc	a3,0x5
    80001e0c:	1f868693          	addi	a3,a3,504 # 80007000 <_trampoline>
    80001e10:	6605                	lui	a2,0x1
    80001e12:	040005b7          	lui	a1,0x4000
    80001e16:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e18:	05b2                	slli	a1,a1,0xc
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	680080e7          	jalr	1664(ra) # 8000149a <mappages>
    80001e22:	02054863          	bltz	a0,80001e52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e26:	4719                	li	a4,6
    80001e28:	06093683          	ld	a3,96(s2)
    80001e2c:	6605                	lui	a2,0x1
    80001e2e:	020005b7          	lui	a1,0x2000
    80001e32:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e34:	05b6                	slli	a1,a1,0xd
    80001e36:	8526                	mv	a0,s1
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	662080e7          	jalr	1634(ra) # 8000149a <mappages>
    80001e40:	02054163          	bltz	a0,80001e62 <proc_pagetable+0x76>
}
    80001e44:	8526                	mv	a0,s1
    80001e46:	60e2                	ld	ra,24(sp)
    80001e48:	6442                	ld	s0,16(sp)
    80001e4a:	64a2                	ld	s1,8(sp)
    80001e4c:	6902                	ld	s2,0(sp)
    80001e4e:	6105                	addi	sp,sp,32
    80001e50:	8082                	ret
    uvmfree(pagetable, 0);
    80001e52:	4581                	li	a1,0
    80001e54:	8526                	mv	a0,s1
    80001e56:	00000097          	auipc	ra,0x0
    80001e5a:	a8a080e7          	jalr	-1398(ra) # 800018e0 <uvmfree>
    return 0;
    80001e5e:	4481                	li	s1,0
    80001e60:	b7d5                	j	80001e44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e62:	4681                	li	a3,0
    80001e64:	4605                	li	a2,1
    80001e66:	040005b7          	lui	a1,0x4000
    80001e6a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e6c:	05b2                	slli	a1,a1,0xc
    80001e6e:	8526                	mv	a0,s1
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	7ae080e7          	jalr	1966(ra) # 8000161e <uvmunmap>
    uvmfree(pagetable, 0);
    80001e78:	4581                	li	a1,0
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	a64080e7          	jalr	-1436(ra) # 800018e0 <uvmfree>
    return 0;
    80001e84:	4481                	li	s1,0
    80001e86:	bf7d                	j	80001e44 <proc_pagetable+0x58>

0000000080001e88 <proc_freepagetable>:
{
    80001e88:	1101                	addi	sp,sp,-32
    80001e8a:	ec06                	sd	ra,24(sp)
    80001e8c:	e822                	sd	s0,16(sp)
    80001e8e:	e426                	sd	s1,8(sp)
    80001e90:	e04a                	sd	s2,0(sp)
    80001e92:	1000                	addi	s0,sp,32
    80001e94:	84aa                	mv	s1,a0
    80001e96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e98:	4681                	li	a3,0
    80001e9a:	4605                	li	a2,1
    80001e9c:	040005b7          	lui	a1,0x4000
    80001ea0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ea2:	05b2                	slli	a1,a1,0xc
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	77a080e7          	jalr	1914(ra) # 8000161e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eac:	4681                	li	a3,0
    80001eae:	4605                	li	a2,1
    80001eb0:	020005b7          	lui	a1,0x2000
    80001eb4:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001eb6:	05b6                	slli	a1,a1,0xd
    80001eb8:	8526                	mv	a0,s1
    80001eba:	fffff097          	auipc	ra,0xfffff
    80001ebe:	764080e7          	jalr	1892(ra) # 8000161e <uvmunmap>
  uvmfree(pagetable, sz);
    80001ec2:	85ca                	mv	a1,s2
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	00000097          	auipc	ra,0x0
    80001eca:	a1a080e7          	jalr	-1510(ra) # 800018e0 <uvmfree>
}
    80001ece:	60e2                	ld	ra,24(sp)
    80001ed0:	6442                	ld	s0,16(sp)
    80001ed2:	64a2                	ld	s1,8(sp)
    80001ed4:	6902                	ld	s2,0(sp)
    80001ed6:	6105                	addi	sp,sp,32
    80001ed8:	8082                	ret

0000000080001eda <freeproc>:
{
    80001eda:	1101                	addi	sp,sp,-32
    80001edc:	ec06                	sd	ra,24(sp)
    80001ede:	e822                	sd	s0,16(sp)
    80001ee0:	e426                	sd	s1,8(sp)
    80001ee2:	1000                	addi	s0,sp,32
    80001ee4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ee6:	7128                	ld	a0,96(a0)
    80001ee8:	c509                	beqz	a0,80001ef2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	b2e080e7          	jalr	-1234(ra) # 80000a18 <kfree>
  p->trapframe = 0;
    80001ef2:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001ef6:	6ca8                	ld	a0,88(s1)
    80001ef8:	c511                	beqz	a0,80001f04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001efa:	68ac                	ld	a1,80(s1)
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	f8c080e7          	jalr	-116(ra) # 80001e88 <proc_freepagetable>
  p->pagetable = 0;
    80001f04:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f08:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f0c:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f10:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f14:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f18:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f1c:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001f20:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001f24:	0204a023          	sw	zero,32(s1)
}
    80001f28:	60e2                	ld	ra,24(sp)
    80001f2a:	6442                	ld	s0,16(sp)
    80001f2c:	64a2                	ld	s1,8(sp)
    80001f2e:	6105                	addi	sp,sp,32
    80001f30:	8082                	ret

0000000080001f32 <allocproc>:
{
    80001f32:	1101                	addi	sp,sp,-32
    80001f34:	ec06                	sd	ra,24(sp)
    80001f36:	e822                	sd	s0,16(sp)
    80001f38:	e426                	sd	s1,8(sp)
    80001f3a:	e04a                	sd	s2,0(sp)
    80001f3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	00011497          	auipc	s1,0x11
    80001f42:	86a48493          	addi	s1,s1,-1942 # 800127a8 <proc>
    80001f46:	00016917          	auipc	s2,0x16
    80001f4a:	46290913          	addi	s2,s2,1122 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	d92080e7          	jalr	-622(ra) # 80000ce2 <acquire>
    if(p->state == UNUSED) {
    80001f58:	509c                	lw	a5,32(s1)
    80001f5a:	cf81                	beqz	a5,80001f72 <allocproc+0x40>
      release(&p->lock);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	e54080e7          	jalr	-428(ra) # 80000db2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f66:	17048493          	addi	s1,s1,368
    80001f6a:	ff2492e3          	bne	s1,s2,80001f4e <allocproc+0x1c>
  return 0;
    80001f6e:	4481                	li	s1,0
    80001f70:	a0b9                	j	80001fbe <allocproc+0x8c>
  p->pid = allocpid();
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	e34080e7          	jalr	-460(ra) # 80001da6 <allocpid>
    80001f7a:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	bec080e7          	jalr	-1044(ra) # 80000b68 <kalloc>
    80001f84:	892a                	mv	s2,a0
    80001f86:	f0a8                	sd	a0,96(s1)
    80001f88:	c131                	beqz	a0,80001fcc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	e60080e7          	jalr	-416(ra) # 80001dec <proc_pagetable>
    80001f94:	892a                	mv	s2,a0
    80001f96:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001f98:	c129                	beqz	a0,80001fda <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001f9a:	07000613          	li	a2,112
    80001f9e:	4581                	li	a1,0
    80001fa0:	06848513          	addi	a0,s1,104
    80001fa4:	fffff097          	auipc	ra,0xfffff
    80001fa8:	11e080e7          	jalr	286(ra) # 800010c2 <memset>
  p->context.ra = (uint64)forkret;
    80001fac:	00000797          	auipc	a5,0x0
    80001fb0:	db478793          	addi	a5,a5,-588 # 80001d60 <forkret>
    80001fb4:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fb6:	64bc                	ld	a5,72(s1)
    80001fb8:	6705                	lui	a4,0x1
    80001fba:	97ba                	add	a5,a5,a4
    80001fbc:	f8bc                	sd	a5,112(s1)
}
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	60e2                	ld	ra,24(sp)
    80001fc2:	6442                	ld	s0,16(sp)
    80001fc4:	64a2                	ld	s1,8(sp)
    80001fc6:	6902                	ld	s2,0(sp)
    80001fc8:	6105                	addi	sp,sp,32
    80001fca:	8082                	ret
    release(&p->lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	de4080e7          	jalr	-540(ra) # 80000db2 <release>
    return 0;
    80001fd6:	84ca                	mv	s1,s2
    80001fd8:	b7dd                	j	80001fbe <allocproc+0x8c>
    freeproc(p);
    80001fda:	8526                	mv	a0,s1
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	efe080e7          	jalr	-258(ra) # 80001eda <freeproc>
    release(&p->lock);
    80001fe4:	8526                	mv	a0,s1
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	dcc080e7          	jalr	-564(ra) # 80000db2 <release>
    return 0;
    80001fee:	84ca                	mv	s1,s2
    80001ff0:	b7f9                	j	80001fbe <allocproc+0x8c>

0000000080001ff2 <userinit>:
{
    80001ff2:	1101                	addi	sp,sp,-32
    80001ff4:	ec06                	sd	ra,24(sp)
    80001ff6:	e822                	sd	s0,16(sp)
    80001ff8:	e426                	sd	s1,8(sp)
    80001ffa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	f36080e7          	jalr	-202(ra) # 80001f32 <allocproc>
    80002004:	84aa                	mv	s1,a0
  initproc = p;
    80002006:	00007797          	auipc	a5,0x7
    8000200a:	00a7b923          	sd	a0,18(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000200e:	03400613          	li	a2,52
    80002012:	00007597          	auipc	a1,0x7
    80002016:	8ae58593          	addi	a1,a1,-1874 # 800088c0 <initcode>
    8000201a:	6d28                	ld	a0,88(a0)
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	6f4080e7          	jalr	1780(ra) # 80001710 <uvminit>
  p->sz = PGSIZE;
    80002024:	6785                	lui	a5,0x1
    80002026:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80002028:	70b8                	ld	a4,96(s1)
    8000202a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000202e:	70b8                	ld	a4,96(s1)
    80002030:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002032:	4641                	li	a2,16
    80002034:	00006597          	auipc	a1,0x6
    80002038:	24458593          	addi	a1,a1,580 # 80008278 <digits+0x238>
    8000203c:	16048513          	addi	a0,s1,352
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	1d4080e7          	jalr	468(ra) # 80001214 <safestrcpy>
  p->cwd = namei("/");
    80002048:	00006517          	auipc	a0,0x6
    8000204c:	24050513          	addi	a0,a0,576 # 80008288 <digits+0x248>
    80002050:	00002097          	auipc	ra,0x2
    80002054:	270080e7          	jalr	624(ra) # 800042c0 <namei>
    80002058:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    8000205c:	4789                	li	a5,2
    8000205e:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    80002060:	8526                	mv	a0,s1
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	d50080e7          	jalr	-688(ra) # 80000db2 <release>
}
    8000206a:	60e2                	ld	ra,24(sp)
    8000206c:	6442                	ld	s0,16(sp)
    8000206e:	64a2                	ld	s1,8(sp)
    80002070:	6105                	addi	sp,sp,32
    80002072:	8082                	ret

0000000080002074 <growproc>:
{
    80002074:	1101                	addi	sp,sp,-32
    80002076:	ec06                	sd	ra,24(sp)
    80002078:	e822                	sd	s0,16(sp)
    8000207a:	e426                	sd	s1,8(sp)
    8000207c:	e04a                	sd	s2,0(sp)
    8000207e:	1000                	addi	s0,sp,32
    80002080:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002082:	00000097          	auipc	ra,0x0
    80002086:	ca6080e7          	jalr	-858(ra) # 80001d28 <myproc>
    8000208a:	892a                	mv	s2,a0
  sz = p->sz;
    8000208c:	692c                	ld	a1,80(a0)
    8000208e:	0005879b          	sext.w	a5,a1
  if(n > 0){
    80002092:	00904f63          	bgtz	s1,800020b0 <growproc+0x3c>
  } else if(n < 0){
    80002096:	0204cd63          	bltz	s1,800020d0 <growproc+0x5c>
  p->sz = sz;
    8000209a:	1782                	slli	a5,a5,0x20
    8000209c:	9381                	srli	a5,a5,0x20
    8000209e:	04f93823          	sd	a5,80(s2)
  return 0;
    800020a2:	4501                	li	a0,0
}
    800020a4:	60e2                	ld	ra,24(sp)
    800020a6:	6442                	ld	s0,16(sp)
    800020a8:	64a2                	ld	s1,8(sp)
    800020aa:	6902                	ld	s2,0(sp)
    800020ac:	6105                	addi	sp,sp,32
    800020ae:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800020b0:	00f4863b          	addw	a2,s1,a5
    800020b4:	1602                	slli	a2,a2,0x20
    800020b6:	9201                	srli	a2,a2,0x20
    800020b8:	1582                	slli	a1,a1,0x20
    800020ba:	9181                	srli	a1,a1,0x20
    800020bc:	6d28                	ld	a0,88(a0)
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	70c080e7          	jalr	1804(ra) # 800017ca <uvmalloc>
    800020c6:	0005079b          	sext.w	a5,a0
    800020ca:	fbe1                	bnez	a5,8000209a <growproc+0x26>
      return -1;
    800020cc:	557d                	li	a0,-1
    800020ce:	bfd9                	j	800020a4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020d0:	00f4863b          	addw	a2,s1,a5
    800020d4:	1602                	slli	a2,a2,0x20
    800020d6:	9201                	srli	a2,a2,0x20
    800020d8:	1582                	slli	a1,a1,0x20
    800020da:	9181                	srli	a1,a1,0x20
    800020dc:	6d28                	ld	a0,88(a0)
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	6a4080e7          	jalr	1700(ra) # 80001782 <uvmdealloc>
    800020e6:	0005079b          	sext.w	a5,a0
    800020ea:	bf45                	j	8000209a <growproc+0x26>

00000000800020ec <fork>:
{
    800020ec:	7139                	addi	sp,sp,-64
    800020ee:	fc06                	sd	ra,56(sp)
    800020f0:	f822                	sd	s0,48(sp)
    800020f2:	f426                	sd	s1,40(sp)
    800020f4:	f04a                	sd	s2,32(sp)
    800020f6:	ec4e                	sd	s3,24(sp)
    800020f8:	e852                	sd	s4,16(sp)
    800020fa:	e456                	sd	s5,8(sp)
    800020fc:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	c2a080e7          	jalr	-982(ra) # 80001d28 <myproc>
    80002106:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002108:	00000097          	auipc	ra,0x0
    8000210c:	e2a080e7          	jalr	-470(ra) # 80001f32 <allocproc>
    80002110:	c17d                	beqz	a0,800021f6 <fork+0x10a>
    80002112:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002114:	050ab603          	ld	a2,80(s5)
    80002118:	6d2c                	ld	a1,88(a0)
    8000211a:	058ab503          	ld	a0,88(s5)
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	7fc080e7          	jalr	2044(ra) # 8000191a <uvmcopy>
    80002126:	04054a63          	bltz	a0,8000217a <fork+0x8e>
  np->sz = p->sz;
    8000212a:	050ab783          	ld	a5,80(s5)
    8000212e:	04fa3823          	sd	a5,80(s4)
  np->parent = p;
    80002132:	035a3423          	sd	s5,40(s4)
  *(np->trapframe) = *(p->trapframe);
    80002136:	060ab683          	ld	a3,96(s5)
    8000213a:	87b6                	mv	a5,a3
    8000213c:	060a3703          	ld	a4,96(s4)
    80002140:	12068693          	addi	a3,a3,288
    80002144:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002148:	6788                	ld	a0,8(a5)
    8000214a:	6b8c                	ld	a1,16(a5)
    8000214c:	6f90                	ld	a2,24(a5)
    8000214e:	01073023          	sd	a6,0(a4)
    80002152:	e708                	sd	a0,8(a4)
    80002154:	eb0c                	sd	a1,16(a4)
    80002156:	ef10                	sd	a2,24(a4)
    80002158:	02078793          	addi	a5,a5,32
    8000215c:	02070713          	addi	a4,a4,32
    80002160:	fed792e3          	bne	a5,a3,80002144 <fork+0x58>
  np->trapframe->a0 = 0;
    80002164:	060a3783          	ld	a5,96(s4)
    80002168:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000216c:	0d8a8493          	addi	s1,s5,216
    80002170:	0d8a0913          	addi	s2,s4,216
    80002174:	158a8993          	addi	s3,s5,344
    80002178:	a00d                	j	8000219a <fork+0xae>
    freeproc(np);
    8000217a:	8552                	mv	a0,s4
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	d5e080e7          	jalr	-674(ra) # 80001eda <freeproc>
    release(&np->lock);
    80002184:	8552                	mv	a0,s4
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	c2c080e7          	jalr	-980(ra) # 80000db2 <release>
    return -1;
    8000218e:	54fd                	li	s1,-1
    80002190:	a889                	j	800021e2 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80002192:	04a1                	addi	s1,s1,8
    80002194:	0921                	addi	s2,s2,8
    80002196:	01348b63          	beq	s1,s3,800021ac <fork+0xc0>
    if(p->ofile[i])
    8000219a:	6088                	ld	a0,0(s1)
    8000219c:	d97d                	beqz	a0,80002192 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    8000219e:	00002097          	auipc	ra,0x2
    800021a2:	7c0080e7          	jalr	1984(ra) # 8000495e <filedup>
    800021a6:	00a93023          	sd	a0,0(s2)
    800021aa:	b7e5                	j	80002192 <fork+0xa6>
  np->cwd = idup(p->cwd);
    800021ac:	158ab503          	ld	a0,344(s5)
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	918080e7          	jalr	-1768(ra) # 80003ac8 <idup>
    800021b8:	14aa3c23          	sd	a0,344(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021bc:	4641                	li	a2,16
    800021be:	160a8593          	addi	a1,s5,352
    800021c2:	160a0513          	addi	a0,s4,352
    800021c6:	fffff097          	auipc	ra,0xfffff
    800021ca:	04e080e7          	jalr	78(ra) # 80001214 <safestrcpy>
  pid = np->pid;
    800021ce:	040a2483          	lw	s1,64(s4)
  np->state = RUNNABLE;
    800021d2:	4789                	li	a5,2
    800021d4:	02fa2023          	sw	a5,32(s4)
  release(&np->lock);
    800021d8:	8552                	mv	a0,s4
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	bd8080e7          	jalr	-1064(ra) # 80000db2 <release>
}
    800021e2:	8526                	mv	a0,s1
    800021e4:	70e2                	ld	ra,56(sp)
    800021e6:	7442                	ld	s0,48(sp)
    800021e8:	74a2                	ld	s1,40(sp)
    800021ea:	7902                	ld	s2,32(sp)
    800021ec:	69e2                	ld	s3,24(sp)
    800021ee:	6a42                	ld	s4,16(sp)
    800021f0:	6aa2                	ld	s5,8(sp)
    800021f2:	6121                	addi	sp,sp,64
    800021f4:	8082                	ret
    return -1;
    800021f6:	54fd                	li	s1,-1
    800021f8:	b7ed                	j	800021e2 <fork+0xf6>

00000000800021fa <reparent>:
{
    800021fa:	7179                	addi	sp,sp,-48
    800021fc:	f406                	sd	ra,40(sp)
    800021fe:	f022                	sd	s0,32(sp)
    80002200:	ec26                	sd	s1,24(sp)
    80002202:	e84a                	sd	s2,16(sp)
    80002204:	e44e                	sd	s3,8(sp)
    80002206:	e052                	sd	s4,0(sp)
    80002208:	1800                	addi	s0,sp,48
    8000220a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000220c:	00010497          	auipc	s1,0x10
    80002210:	59c48493          	addi	s1,s1,1436 # 800127a8 <proc>
      pp->parent = initproc;
    80002214:	00007a17          	auipc	s4,0x7
    80002218:	e04a0a13          	addi	s4,s4,-508 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221c:	00016997          	auipc	s3,0x16
    80002220:	18c98993          	addi	s3,s3,396 # 800183a8 <tickslock>
    80002224:	a029                	j	8000222e <reparent+0x34>
    80002226:	17048493          	addi	s1,s1,368
    8000222a:	03348363          	beq	s1,s3,80002250 <reparent+0x56>
    if(pp->parent == p){
    8000222e:	749c                	ld	a5,40(s1)
    80002230:	ff279be3          	bne	a5,s2,80002226 <reparent+0x2c>
      acquire(&pp->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	aac080e7          	jalr	-1364(ra) # 80000ce2 <acquire>
      pp->parent = initproc;
    8000223e:	000a3783          	ld	a5,0(s4)
    80002242:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    80002244:	8526                	mv	a0,s1
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	b6c080e7          	jalr	-1172(ra) # 80000db2 <release>
    8000224e:	bfe1                	j	80002226 <reparent+0x2c>
}
    80002250:	70a2                	ld	ra,40(sp)
    80002252:	7402                	ld	s0,32(sp)
    80002254:	64e2                	ld	s1,24(sp)
    80002256:	6942                	ld	s2,16(sp)
    80002258:	69a2                	ld	s3,8(sp)
    8000225a:	6a02                	ld	s4,0(sp)
    8000225c:	6145                	addi	sp,sp,48
    8000225e:	8082                	ret

0000000080002260 <scheduler>:
{
    80002260:	711d                	addi	sp,sp,-96
    80002262:	ec86                	sd	ra,88(sp)
    80002264:	e8a2                	sd	s0,80(sp)
    80002266:	e4a6                	sd	s1,72(sp)
    80002268:	e0ca                	sd	s2,64(sp)
    8000226a:	fc4e                	sd	s3,56(sp)
    8000226c:	f852                	sd	s4,48(sp)
    8000226e:	f456                	sd	s5,40(sp)
    80002270:	f05a                	sd	s6,32(sp)
    80002272:	ec5e                	sd	s7,24(sp)
    80002274:	e862                	sd	s8,16(sp)
    80002276:	e466                	sd	s9,8(sp)
    80002278:	1080                	addi	s0,sp,96
    8000227a:	8792                	mv	a5,tp
  int id = r_tp();
    8000227c:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000227e:	00779c13          	slli	s8,a5,0x7
    80002282:	00010717          	auipc	a4,0x10
    80002286:	10670713          	addi	a4,a4,262 # 80012388 <pid_lock>
    8000228a:	9762                	add	a4,a4,s8
    8000228c:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002290:	00010717          	auipc	a4,0x10
    80002294:	12070713          	addi	a4,a4,288 # 800123b0 <cpus+0x8>
    80002298:	9c3a                	add	s8,s8,a4
    int nproc = 0;
    8000229a:	4c81                	li	s9,0
      if(p->state == RUNNABLE) {
    8000229c:	4a89                	li	s5,2
        c->proc = p;
    8000229e:	079e                	slli	a5,a5,0x7
    800022a0:	00010b17          	auipc	s6,0x10
    800022a4:	0e8b0b13          	addi	s6,s6,232 # 80012388 <pid_lock>
    800022a8:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022aa:	00016a17          	auipc	s4,0x16
    800022ae:	0fea0a13          	addi	s4,s4,254 # 800183a8 <tickslock>
    800022b2:	a8a1                	j	8000230a <scheduler+0xaa>
      release(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	afc080e7          	jalr	-1284(ra) # 80000db2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800022be:	17048493          	addi	s1,s1,368
    800022c2:	03448a63          	beq	s1,s4,800022f6 <scheduler+0x96>
      acquire(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	a1a080e7          	jalr	-1510(ra) # 80000ce2 <acquire>
      if(p->state != UNUSED) {
    800022d0:	509c                	lw	a5,32(s1)
    800022d2:	d3ed                	beqz	a5,800022b4 <scheduler+0x54>
        nproc++;
    800022d4:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800022d6:	fd579fe3          	bne	a5,s5,800022b4 <scheduler+0x54>
        p->state = RUNNING;
    800022da:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    800022de:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    800022e2:	06848593          	addi	a1,s1,104
    800022e6:	8562                	mv	a0,s8
    800022e8:	00000097          	auipc	ra,0x0
    800022ec:	60e080e7          	jalr	1550(ra) # 800028f6 <swtch>
        c->proc = 0;
    800022f0:	020b3023          	sd	zero,32(s6)
    800022f4:	b7c1                	j	800022b4 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800022f6:	013aca63          	blt	s5,s3,8000230a <scheduler+0xaa>
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
    int nproc = 0;
    80002316:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002318:	00010497          	auipc	s1,0x10
    8000231c:	49048493          	addi	s1,s1,1168 # 800127a8 <proc>
        p->state = RUNNING;
    80002320:	4b8d                	li	s7,3
    80002322:	b755                	j	800022c6 <scheduler+0x66>

0000000080002324 <sched>:
{
    80002324:	7179                	addi	sp,sp,-48
    80002326:	f406                	sd	ra,40(sp)
    80002328:	f022                	sd	s0,32(sp)
    8000232a:	ec26                	sd	s1,24(sp)
    8000232c:	e84a                	sd	s2,16(sp)
    8000232e:	e44e                	sd	s3,8(sp)
    80002330:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002332:	00000097          	auipc	ra,0x0
    80002336:	9f6080e7          	jalr	-1546(ra) # 80001d28 <myproc>
    8000233a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	92c080e7          	jalr	-1748(ra) # 80000c68 <holding>
    80002344:	c93d                	beqz	a0,800023ba <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002346:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002348:	2781                	sext.w	a5,a5
    8000234a:	079e                	slli	a5,a5,0x7
    8000234c:	00010717          	auipc	a4,0x10
    80002350:	03c70713          	addi	a4,a4,60 # 80012388 <pid_lock>
    80002354:	97ba                	add	a5,a5,a4
    80002356:	0987a703          	lw	a4,152(a5)
    8000235a:	4785                	li	a5,1
    8000235c:	06f71763          	bne	a4,a5,800023ca <sched+0xa6>
  if(p->state == RUNNING)
    80002360:	5098                	lw	a4,32(s1)
    80002362:	478d                	li	a5,3
    80002364:	06f70b63          	beq	a4,a5,800023da <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002368:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000236c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000236e:	efb5                	bnez	a5,800023ea <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002370:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002372:	00010917          	auipc	s2,0x10
    80002376:	01690913          	addi	s2,s2,22 # 80012388 <pid_lock>
    8000237a:	2781                	sext.w	a5,a5
    8000237c:	079e                	slli	a5,a5,0x7
    8000237e:	97ca                	add	a5,a5,s2
    80002380:	09c7a983          	lw	s3,156(a5)
    80002384:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002386:	2781                	sext.w	a5,a5
    80002388:	079e                	slli	a5,a5,0x7
    8000238a:	00010597          	auipc	a1,0x10
    8000238e:	02658593          	addi	a1,a1,38 # 800123b0 <cpus+0x8>
    80002392:	95be                	add	a1,a1,a5
    80002394:	06848513          	addi	a0,s1,104
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	55e080e7          	jalr	1374(ra) # 800028f6 <swtch>
    800023a0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023a2:	2781                	sext.w	a5,a5
    800023a4:	079e                	slli	a5,a5,0x7
    800023a6:	993e                	add	s2,s2,a5
    800023a8:	09392e23          	sw	s3,156(s2)
}
    800023ac:	70a2                	ld	ra,40(sp)
    800023ae:	7402                	ld	s0,32(sp)
    800023b0:	64e2                	ld	s1,24(sp)
    800023b2:	6942                	ld	s2,16(sp)
    800023b4:	69a2                	ld	s3,8(sp)
    800023b6:	6145                	addi	sp,sp,48
    800023b8:	8082                	ret
    panic("sched p->lock");
    800023ba:	00006517          	auipc	a0,0x6
    800023be:	ed650513          	addi	a0,a0,-298 # 80008290 <digits+0x250>
    800023c2:	ffffe097          	auipc	ra,0xffffe
    800023c6:	18a080e7          	jalr	394(ra) # 8000054c <panic>
    panic("sched locks");
    800023ca:	00006517          	auipc	a0,0x6
    800023ce:	ed650513          	addi	a0,a0,-298 # 800082a0 <digits+0x260>
    800023d2:	ffffe097          	auipc	ra,0xffffe
    800023d6:	17a080e7          	jalr	378(ra) # 8000054c <panic>
    panic("sched running");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	ed650513          	addi	a0,a0,-298 # 800082b0 <digits+0x270>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	16a080e7          	jalr	362(ra) # 8000054c <panic>
    panic("sched interruptible");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	ed650513          	addi	a0,a0,-298 # 800082c0 <digits+0x280>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	15a080e7          	jalr	346(ra) # 8000054c <panic>

00000000800023fa <exit>:
{
    800023fa:	7179                	addi	sp,sp,-48
    800023fc:	f406                	sd	ra,40(sp)
    800023fe:	f022                	sd	s0,32(sp)
    80002400:	ec26                	sd	s1,24(sp)
    80002402:	e84a                	sd	s2,16(sp)
    80002404:	e44e                	sd	s3,8(sp)
    80002406:	e052                	sd	s4,0(sp)
    80002408:	1800                	addi	s0,sp,48
    8000240a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	91c080e7          	jalr	-1764(ra) # 80001d28 <myproc>
    80002414:	89aa                	mv	s3,a0
  if(p == initproc)
    80002416:	00007797          	auipc	a5,0x7
    8000241a:	c027b783          	ld	a5,-1022(a5) # 80009018 <initproc>
    8000241e:	0d850493          	addi	s1,a0,216
    80002422:	15850913          	addi	s2,a0,344
    80002426:	02a79363          	bne	a5,a0,8000244c <exit+0x52>
    panic("init exiting");
    8000242a:	00006517          	auipc	a0,0x6
    8000242e:	eae50513          	addi	a0,a0,-338 # 800082d8 <digits+0x298>
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	11a080e7          	jalr	282(ra) # 8000054c <panic>
      fileclose(f);
    8000243a:	00002097          	auipc	ra,0x2
    8000243e:	576080e7          	jalr	1398(ra) # 800049b0 <fileclose>
      p->ofile[fd] = 0;
    80002442:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002446:	04a1                	addi	s1,s1,8
    80002448:	01248563          	beq	s1,s2,80002452 <exit+0x58>
    if(p->ofile[fd]){
    8000244c:	6088                	ld	a0,0(s1)
    8000244e:	f575                	bnez	a0,8000243a <exit+0x40>
    80002450:	bfdd                	j	80002446 <exit+0x4c>
  begin_op();
    80002452:	00002097          	auipc	ra,0x2
    80002456:	08e080e7          	jalr	142(ra) # 800044e0 <begin_op>
  iput(p->cwd);
    8000245a:	1589b503          	ld	a0,344(s3)
    8000245e:	00002097          	auipc	ra,0x2
    80002462:	862080e7          	jalr	-1950(ra) # 80003cc0 <iput>
  end_op();
    80002466:	00002097          	auipc	ra,0x2
    8000246a:	0f8080e7          	jalr	248(ra) # 8000455e <end_op>
  p->cwd = 0;
    8000246e:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    80002472:	00007497          	auipc	s1,0x7
    80002476:	ba648493          	addi	s1,s1,-1114 # 80009018 <initproc>
    8000247a:	6088                	ld	a0,0(s1)
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	866080e7          	jalr	-1946(ra) # 80000ce2 <acquire>
  wakeup1(initproc);
    80002484:	6088                	ld	a0,0(s1)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	762080e7          	jalr	1890(ra) # 80001be8 <wakeup1>
  release(&initproc->lock);
    8000248e:	6088                	ld	a0,0(s1)
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	922080e7          	jalr	-1758(ra) # 80000db2 <release>
  acquire(&p->lock);
    80002498:	854e                	mv	a0,s3
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	848080e7          	jalr	-1976(ra) # 80000ce2 <acquire>
  struct proc *original_parent = p->parent;
    800024a2:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    800024a6:	854e                	mv	a0,s3
    800024a8:	fffff097          	auipc	ra,0xfffff
    800024ac:	90a080e7          	jalr	-1782(ra) # 80000db2 <release>
  acquire(&original_parent->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	830080e7          	jalr	-2000(ra) # 80000ce2 <acquire>
  acquire(&p->lock);
    800024ba:	854e                	mv	a0,s3
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	826080e7          	jalr	-2010(ra) # 80000ce2 <acquire>
  reparent(p);
    800024c4:	854e                	mv	a0,s3
    800024c6:	00000097          	auipc	ra,0x0
    800024ca:	d34080e7          	jalr	-716(ra) # 800021fa <reparent>
  wakeup1(original_parent);
    800024ce:	8526                	mv	a0,s1
    800024d0:	fffff097          	auipc	ra,0xfffff
    800024d4:	718080e7          	jalr	1816(ra) # 80001be8 <wakeup1>
  p->xstate = status;
    800024d8:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    800024dc:	4791                	li	a5,4
    800024de:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	8ce080e7          	jalr	-1842(ra) # 80000db2 <release>
  sched();
    800024ec:	00000097          	auipc	ra,0x0
    800024f0:	e38080e7          	jalr	-456(ra) # 80002324 <sched>
  panic("zombie exit");
    800024f4:	00006517          	auipc	a0,0x6
    800024f8:	df450513          	addi	a0,a0,-524 # 800082e8 <digits+0x2a8>
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	050080e7          	jalr	80(ra) # 8000054c <panic>

0000000080002504 <yield>:
{
    80002504:	1101                	addi	sp,sp,-32
    80002506:	ec06                	sd	ra,24(sp)
    80002508:	e822                	sd	s0,16(sp)
    8000250a:	e426                	sd	s1,8(sp)
    8000250c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000250e:	00000097          	auipc	ra,0x0
    80002512:	81a080e7          	jalr	-2022(ra) # 80001d28 <myproc>
    80002516:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	7ca080e7          	jalr	1994(ra) # 80000ce2 <acquire>
  p->state = RUNNABLE;
    80002520:	4789                	li	a5,2
    80002522:	d09c                	sw	a5,32(s1)
  sched();
    80002524:	00000097          	auipc	ra,0x0
    80002528:	e00080e7          	jalr	-512(ra) # 80002324 <sched>
  release(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	884080e7          	jalr	-1916(ra) # 80000db2 <release>
}
    80002536:	60e2                	ld	ra,24(sp)
    80002538:	6442                	ld	s0,16(sp)
    8000253a:	64a2                	ld	s1,8(sp)
    8000253c:	6105                	addi	sp,sp,32
    8000253e:	8082                	ret

0000000080002540 <sleep>:
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	1800                	addi	s0,sp,48
    8000254e:	89aa                	mv	s3,a0
    80002550:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	7d6080e7          	jalr	2006(ra) # 80001d28 <myproc>
    8000255a:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000255c:	05250663          	beq	a0,s2,800025a8 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	782080e7          	jalr	1922(ra) # 80000ce2 <acquire>
    release(lk);
    80002568:	854a                	mv	a0,s2
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	848080e7          	jalr	-1976(ra) # 80000db2 <release>
  p->chan = chan;
    80002572:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    80002576:	4785                	li	a5,1
    80002578:	d09c                	sw	a5,32(s1)
  sched();
    8000257a:	00000097          	auipc	ra,0x0
    8000257e:	daa080e7          	jalr	-598(ra) # 80002324 <sched>
  p->chan = 0;
    80002582:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    80002586:	8526                	mv	a0,s1
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	82a080e7          	jalr	-2006(ra) # 80000db2 <release>
    acquire(lk);
    80002590:	854a                	mv	a0,s2
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	750080e7          	jalr	1872(ra) # 80000ce2 <acquire>
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6145                	addi	sp,sp,48
    800025a6:	8082                	ret
  p->chan = chan;
    800025a8:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    800025ac:	4785                	li	a5,1
    800025ae:	d11c                	sw	a5,32(a0)
  sched();
    800025b0:	00000097          	auipc	ra,0x0
    800025b4:	d74080e7          	jalr	-652(ra) # 80002324 <sched>
  p->chan = 0;
    800025b8:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    800025bc:	bff9                	j	8000259a <sleep+0x5a>

00000000800025be <wait>:
{
    800025be:	715d                	addi	sp,sp,-80
    800025c0:	e486                	sd	ra,72(sp)
    800025c2:	e0a2                	sd	s0,64(sp)
    800025c4:	fc26                	sd	s1,56(sp)
    800025c6:	f84a                	sd	s2,48(sp)
    800025c8:	f44e                	sd	s3,40(sp)
    800025ca:	f052                	sd	s4,32(sp)
    800025cc:	ec56                	sd	s5,24(sp)
    800025ce:	e85a                	sd	s6,16(sp)
    800025d0:	e45e                	sd	s7,8(sp)
    800025d2:	0880                	addi	s0,sp,80
    800025d4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	752080e7          	jalr	1874(ra) # 80001d28 <myproc>
    800025de:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	702080e7          	jalr	1794(ra) # 80000ce2 <acquire>
    havekids = 0;
    800025e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800025ea:	4a11                	li	s4,4
        havekids = 1;
    800025ec:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800025ee:	00016997          	auipc	s3,0x16
    800025f2:	dba98993          	addi	s3,s3,-582 # 800183a8 <tickslock>
    havekids = 0;
    800025f6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800025f8:	00010497          	auipc	s1,0x10
    800025fc:	1b048493          	addi	s1,s1,432 # 800127a8 <proc>
    80002600:	a08d                	j	80002662 <wait+0xa4>
          pid = np->pid;
    80002602:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002606:	000b0e63          	beqz	s6,80002622 <wait+0x64>
    8000260a:	4691                	li	a3,4
    8000260c:	03c48613          	addi	a2,s1,60
    80002610:	85da                	mv	a1,s6
    80002612:	05893503          	ld	a0,88(s2)
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	408080e7          	jalr	1032(ra) # 80001a1e <copyout>
    8000261e:	02054263          	bltz	a0,80002642 <wait+0x84>
          freeproc(np);
    80002622:	8526                	mv	a0,s1
    80002624:	00000097          	auipc	ra,0x0
    80002628:	8b6080e7          	jalr	-1866(ra) # 80001eda <freeproc>
          release(&np->lock);
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	784080e7          	jalr	1924(ra) # 80000db2 <release>
          release(&p->lock);
    80002636:	854a                	mv	a0,s2
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	77a080e7          	jalr	1914(ra) # 80000db2 <release>
          return pid;
    80002640:	a8a9                	j	8000269a <wait+0xdc>
            release(&np->lock);
    80002642:	8526                	mv	a0,s1
    80002644:	ffffe097          	auipc	ra,0xffffe
    80002648:	76e080e7          	jalr	1902(ra) # 80000db2 <release>
            release(&p->lock);
    8000264c:	854a                	mv	a0,s2
    8000264e:	ffffe097          	auipc	ra,0xffffe
    80002652:	764080e7          	jalr	1892(ra) # 80000db2 <release>
            return -1;
    80002656:	59fd                	li	s3,-1
    80002658:	a089                	j	8000269a <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    8000265a:	17048493          	addi	s1,s1,368
    8000265e:	03348463          	beq	s1,s3,80002686 <wait+0xc8>
      if(np->parent == p){
    80002662:	749c                	ld	a5,40(s1)
    80002664:	ff279be3          	bne	a5,s2,8000265a <wait+0x9c>
        acquire(&np->lock);
    80002668:	8526                	mv	a0,s1
    8000266a:	ffffe097          	auipc	ra,0xffffe
    8000266e:	678080e7          	jalr	1656(ra) # 80000ce2 <acquire>
        if(np->state == ZOMBIE){
    80002672:	509c                	lw	a5,32(s1)
    80002674:	f94787e3          	beq	a5,s4,80002602 <wait+0x44>
        release(&np->lock);
    80002678:	8526                	mv	a0,s1
    8000267a:	ffffe097          	auipc	ra,0xffffe
    8000267e:	738080e7          	jalr	1848(ra) # 80000db2 <release>
        havekids = 1;
    80002682:	8756                	mv	a4,s5
    80002684:	bfd9                	j	8000265a <wait+0x9c>
    if(!havekids || p->killed){
    80002686:	c701                	beqz	a4,8000268e <wait+0xd0>
    80002688:	03892783          	lw	a5,56(s2)
    8000268c:	c39d                	beqz	a5,800026b2 <wait+0xf4>
      release(&p->lock);
    8000268e:	854a                	mv	a0,s2
    80002690:	ffffe097          	auipc	ra,0xffffe
    80002694:	722080e7          	jalr	1826(ra) # 80000db2 <release>
      return -1;
    80002698:	59fd                	li	s3,-1
}
    8000269a:	854e                	mv	a0,s3
    8000269c:	60a6                	ld	ra,72(sp)
    8000269e:	6406                	ld	s0,64(sp)
    800026a0:	74e2                	ld	s1,56(sp)
    800026a2:	7942                	ld	s2,48(sp)
    800026a4:	79a2                	ld	s3,40(sp)
    800026a6:	7a02                	ld	s4,32(sp)
    800026a8:	6ae2                	ld	s5,24(sp)
    800026aa:	6b42                	ld	s6,16(sp)
    800026ac:	6ba2                	ld	s7,8(sp)
    800026ae:	6161                	addi	sp,sp,80
    800026b0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026b2:	85ca                	mv	a1,s2
    800026b4:	854a                	mv	a0,s2
    800026b6:	00000097          	auipc	ra,0x0
    800026ba:	e8a080e7          	jalr	-374(ra) # 80002540 <sleep>
    havekids = 0;
    800026be:	bf25                	j	800025f6 <wait+0x38>

00000000800026c0 <wakeup>:
{
    800026c0:	7139                	addi	sp,sp,-64
    800026c2:	fc06                	sd	ra,56(sp)
    800026c4:	f822                	sd	s0,48(sp)
    800026c6:	f426                	sd	s1,40(sp)
    800026c8:	f04a                	sd	s2,32(sp)
    800026ca:	ec4e                	sd	s3,24(sp)
    800026cc:	e852                	sd	s4,16(sp)
    800026ce:	e456                	sd	s5,8(sp)
    800026d0:	0080                	addi	s0,sp,64
    800026d2:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800026d4:	00010497          	auipc	s1,0x10
    800026d8:	0d448493          	addi	s1,s1,212 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800026dc:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026de:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800026e0:	00016917          	auipc	s2,0x16
    800026e4:	cc890913          	addi	s2,s2,-824 # 800183a8 <tickslock>
    800026e8:	a811                	j	800026fc <wakeup+0x3c>
    release(&p->lock);
    800026ea:	8526                	mv	a0,s1
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	6c6080e7          	jalr	1734(ra) # 80000db2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026f4:	17048493          	addi	s1,s1,368
    800026f8:	03248063          	beq	s1,s2,80002718 <wakeup+0x58>
    acquire(&p->lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	5e4080e7          	jalr	1508(ra) # 80000ce2 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002706:	509c                	lw	a5,32(s1)
    80002708:	ff3791e3          	bne	a5,s3,800026ea <wakeup+0x2a>
    8000270c:	789c                	ld	a5,48(s1)
    8000270e:	fd479ee3          	bne	a5,s4,800026ea <wakeup+0x2a>
      p->state = RUNNABLE;
    80002712:	0354a023          	sw	s5,32(s1)
    80002716:	bfd1                	j	800026ea <wakeup+0x2a>
}
    80002718:	70e2                	ld	ra,56(sp)
    8000271a:	7442                	ld	s0,48(sp)
    8000271c:	74a2                	ld	s1,40(sp)
    8000271e:	7902                	ld	s2,32(sp)
    80002720:	69e2                	ld	s3,24(sp)
    80002722:	6a42                	ld	s4,16(sp)
    80002724:	6aa2                	ld	s5,8(sp)
    80002726:	6121                	addi	sp,sp,64
    80002728:	8082                	ret

000000008000272a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000272a:	7179                	addi	sp,sp,-48
    8000272c:	f406                	sd	ra,40(sp)
    8000272e:	f022                	sd	s0,32(sp)
    80002730:	ec26                	sd	s1,24(sp)
    80002732:	e84a                	sd	s2,16(sp)
    80002734:	e44e                	sd	s3,8(sp)
    80002736:	1800                	addi	s0,sp,48
    80002738:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000273a:	00010497          	auipc	s1,0x10
    8000273e:	06e48493          	addi	s1,s1,110 # 800127a8 <proc>
    80002742:	00016997          	auipc	s3,0x16
    80002746:	c6698993          	addi	s3,s3,-922 # 800183a8 <tickslock>
    acquire(&p->lock);
    8000274a:	8526                	mv	a0,s1
    8000274c:	ffffe097          	auipc	ra,0xffffe
    80002750:	596080e7          	jalr	1430(ra) # 80000ce2 <acquire>
    if(p->pid == pid){
    80002754:	40bc                	lw	a5,64(s1)
    80002756:	01278d63          	beq	a5,s2,80002770 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000275a:	8526                	mv	a0,s1
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	656080e7          	jalr	1622(ra) # 80000db2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002764:	17048493          	addi	s1,s1,368
    80002768:	ff3491e3          	bne	s1,s3,8000274a <kill+0x20>
  }
  return -1;
    8000276c:	557d                	li	a0,-1
    8000276e:	a821                	j	80002786 <kill+0x5c>
      p->killed = 1;
    80002770:	4785                	li	a5,1
    80002772:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    80002774:	5098                	lw	a4,32(s1)
    80002776:	00f70f63          	beq	a4,a5,80002794 <kill+0x6a>
      release(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	636080e7          	jalr	1590(ra) # 80000db2 <release>
      return 0;
    80002784:	4501                	li	a0,0
}
    80002786:	70a2                	ld	ra,40(sp)
    80002788:	7402                	ld	s0,32(sp)
    8000278a:	64e2                	ld	s1,24(sp)
    8000278c:	6942                	ld	s2,16(sp)
    8000278e:	69a2                	ld	s3,8(sp)
    80002790:	6145                	addi	sp,sp,48
    80002792:	8082                	ret
        p->state = RUNNABLE;
    80002794:	4789                	li	a5,2
    80002796:	d09c                	sw	a5,32(s1)
    80002798:	b7cd                	j	8000277a <kill+0x50>

000000008000279a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279a:	7179                	addi	sp,sp,-48
    8000279c:	f406                	sd	ra,40(sp)
    8000279e:	f022                	sd	s0,32(sp)
    800027a0:	ec26                	sd	s1,24(sp)
    800027a2:	e84a                	sd	s2,16(sp)
    800027a4:	e44e                	sd	s3,8(sp)
    800027a6:	e052                	sd	s4,0(sp)
    800027a8:	1800                	addi	s0,sp,48
    800027aa:	84aa                	mv	s1,a0
    800027ac:	892e                	mv	s2,a1
    800027ae:	89b2                	mv	s3,a2
    800027b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	576080e7          	jalr	1398(ra) # 80001d28 <myproc>
  if(user_dst){
    800027ba:	c08d                	beqz	s1,800027dc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027bc:	86d2                	mv	a3,s4
    800027be:	864e                	mv	a2,s3
    800027c0:	85ca                	mv	a1,s2
    800027c2:	6d28                	ld	a0,88(a0)
    800027c4:	fffff097          	auipc	ra,0xfffff
    800027c8:	25a080e7          	jalr	602(ra) # 80001a1e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027cc:	70a2                	ld	ra,40(sp)
    800027ce:	7402                	ld	s0,32(sp)
    800027d0:	64e2                	ld	s1,24(sp)
    800027d2:	6942                	ld	s2,16(sp)
    800027d4:	69a2                	ld	s3,8(sp)
    800027d6:	6a02                	ld	s4,0(sp)
    800027d8:	6145                	addi	sp,sp,48
    800027da:	8082                	ret
    memmove((char *)dst, src, len);
    800027dc:	000a061b          	sext.w	a2,s4
    800027e0:	85ce                	mv	a1,s3
    800027e2:	854a                	mv	a0,s2
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	93a080e7          	jalr	-1734(ra) # 8000111e <memmove>
    return 0;
    800027ec:	8526                	mv	a0,s1
    800027ee:	bff9                	j	800027cc <either_copyout+0x32>

00000000800027f0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f0:	7179                	addi	sp,sp,-48
    800027f2:	f406                	sd	ra,40(sp)
    800027f4:	f022                	sd	s0,32(sp)
    800027f6:	ec26                	sd	s1,24(sp)
    800027f8:	e84a                	sd	s2,16(sp)
    800027fa:	e44e                	sd	s3,8(sp)
    800027fc:	e052                	sd	s4,0(sp)
    800027fe:	1800                	addi	s0,sp,48
    80002800:	892a                	mv	s2,a0
    80002802:	84ae                	mv	s1,a1
    80002804:	89b2                	mv	s3,a2
    80002806:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	520080e7          	jalr	1312(ra) # 80001d28 <myproc>
  if(user_src){
    80002810:	c08d                	beqz	s1,80002832 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002812:	86d2                	mv	a3,s4
    80002814:	864e                	mv	a2,s3
    80002816:	85ca                	mv	a1,s2
    80002818:	6d28                	ld	a0,88(a0)
    8000281a:	fffff097          	auipc	ra,0xfffff
    8000281e:	290080e7          	jalr	656(ra) # 80001aaa <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002822:	70a2                	ld	ra,40(sp)
    80002824:	7402                	ld	s0,32(sp)
    80002826:	64e2                	ld	s1,24(sp)
    80002828:	6942                	ld	s2,16(sp)
    8000282a:	69a2                	ld	s3,8(sp)
    8000282c:	6a02                	ld	s4,0(sp)
    8000282e:	6145                	addi	sp,sp,48
    80002830:	8082                	ret
    memmove(dst, (char*)src, len);
    80002832:	000a061b          	sext.w	a2,s4
    80002836:	85ce                	mv	a1,s3
    80002838:	854a                	mv	a0,s2
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	8e4080e7          	jalr	-1820(ra) # 8000111e <memmove>
    return 0;
    80002842:	8526                	mv	a0,s1
    80002844:	bff9                	j	80002822 <either_copyin+0x32>

0000000080002846 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002846:	715d                	addi	sp,sp,-80
    80002848:	e486                	sd	ra,72(sp)
    8000284a:	e0a2                	sd	s0,64(sp)
    8000284c:	fc26                	sd	s1,56(sp)
    8000284e:	f84a                	sd	s2,48(sp)
    80002850:	f44e                	sd	s3,40(sp)
    80002852:	f052                	sd	s4,32(sp)
    80002854:	ec56                	sd	s5,24(sp)
    80002856:	e85a                	sd	s6,16(sp)
    80002858:	e45e                	sd	s7,8(sp)
    8000285a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000285c:	00006517          	auipc	a0,0x6
    80002860:	90450513          	addi	a0,a0,-1788 # 80008160 <digits+0x120>
    80002864:	ffffe097          	auipc	ra,0xffffe
    80002868:	d32080e7          	jalr	-718(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000286c:	00010497          	auipc	s1,0x10
    80002870:	09c48493          	addi	s1,s1,156 # 80012908 <proc+0x160>
    80002874:	00016917          	auipc	s2,0x16
    80002878:	c9490913          	addi	s2,s2,-876 # 80018508 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000287e:	00006997          	auipc	s3,0x6
    80002882:	a7a98993          	addi	s3,s3,-1414 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    80002886:	00006a97          	auipc	s5,0x6
    8000288a:	a7aa8a93          	addi	s5,s5,-1414 # 80008300 <digits+0x2c0>
    printf("\n");
    8000288e:	00006a17          	auipc	s4,0x6
    80002892:	8d2a0a13          	addi	s4,s4,-1838 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002896:	00006b97          	auipc	s7,0x6
    8000289a:	aa2b8b93          	addi	s7,s7,-1374 # 80008338 <states.0>
    8000289e:	a00d                	j	800028c0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a0:	ee06a583          	lw	a1,-288(a3)
    800028a4:	8556                	mv	a0,s5
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	cf0080e7          	jalr	-784(ra) # 80000596 <printf>
    printf("\n");
    800028ae:	8552                	mv	a0,s4
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	ce6080e7          	jalr	-794(ra) # 80000596 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028b8:	17048493          	addi	s1,s1,368
    800028bc:	03248263          	beq	s1,s2,800028e0 <procdump+0x9a>
    if(p->state == UNUSED)
    800028c0:	86a6                	mv	a3,s1
    800028c2:	ec04a783          	lw	a5,-320(s1)
    800028c6:	dbed                	beqz	a5,800028b8 <procdump+0x72>
      state = "???";
    800028c8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ca:	fcfb6be3          	bltu	s6,a5,800028a0 <procdump+0x5a>
    800028ce:	02079713          	slli	a4,a5,0x20
    800028d2:	01d75793          	srli	a5,a4,0x1d
    800028d6:	97de                	add	a5,a5,s7
    800028d8:	6390                	ld	a2,0(a5)
    800028da:	f279                	bnez	a2,800028a0 <procdump+0x5a>
      state = "???";
    800028dc:	864e                	mv	a2,s3
    800028de:	b7c9                	j	800028a0 <procdump+0x5a>
  }
}
    800028e0:	60a6                	ld	ra,72(sp)
    800028e2:	6406                	ld	s0,64(sp)
    800028e4:	74e2                	ld	s1,56(sp)
    800028e6:	7942                	ld	s2,48(sp)
    800028e8:	79a2                	ld	s3,40(sp)
    800028ea:	7a02                	ld	s4,32(sp)
    800028ec:	6ae2                	ld	s5,24(sp)
    800028ee:	6b42                	ld	s6,16(sp)
    800028f0:	6ba2                	ld	s7,8(sp)
    800028f2:	6161                	addi	sp,sp,80
    800028f4:	8082                	ret

00000000800028f6 <swtch>:
    800028f6:	00153023          	sd	ra,0(a0)
    800028fa:	00253423          	sd	sp,8(a0)
    800028fe:	e900                	sd	s0,16(a0)
    80002900:	ed04                	sd	s1,24(a0)
    80002902:	03253023          	sd	s2,32(a0)
    80002906:	03353423          	sd	s3,40(a0)
    8000290a:	03453823          	sd	s4,48(a0)
    8000290e:	03553c23          	sd	s5,56(a0)
    80002912:	05653023          	sd	s6,64(a0)
    80002916:	05753423          	sd	s7,72(a0)
    8000291a:	05853823          	sd	s8,80(a0)
    8000291e:	05953c23          	sd	s9,88(a0)
    80002922:	07a53023          	sd	s10,96(a0)
    80002926:	07b53423          	sd	s11,104(a0)
    8000292a:	0005b083          	ld	ra,0(a1)
    8000292e:	0085b103          	ld	sp,8(a1)
    80002932:	6980                	ld	s0,16(a1)
    80002934:	6d84                	ld	s1,24(a1)
    80002936:	0205b903          	ld	s2,32(a1)
    8000293a:	0285b983          	ld	s3,40(a1)
    8000293e:	0305ba03          	ld	s4,48(a1)
    80002942:	0385ba83          	ld	s5,56(a1)
    80002946:	0405bb03          	ld	s6,64(a1)
    8000294a:	0485bb83          	ld	s7,72(a1)
    8000294e:	0505bc03          	ld	s8,80(a1)
    80002952:	0585bc83          	ld	s9,88(a1)
    80002956:	0605bd03          	ld	s10,96(a1)
    8000295a:	0685bd83          	ld	s11,104(a1)
    8000295e:	8082                	ret

0000000080002960 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002960:	1141                	addi	sp,sp,-16
    80002962:	e406                	sd	ra,8(sp)
    80002964:	e022                	sd	s0,0(sp)
    80002966:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002968:	00006597          	auipc	a1,0x6
    8000296c:	9f858593          	addi	a1,a1,-1544 # 80008360 <states.0+0x28>
    80002970:	00016517          	auipc	a0,0x16
    80002974:	a3850513          	addi	a0,a0,-1480 # 800183a8 <tickslock>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	4e6080e7          	jalr	1254(ra) # 80000e5e <initlock>
}
    80002980:	60a2                	ld	ra,8(sp)
    80002982:	6402                	ld	s0,0(sp)
    80002984:	0141                	addi	sp,sp,16
    80002986:	8082                	ret

0000000080002988 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002988:	1141                	addi	sp,sp,-16
    8000298a:	e422                	sd	s0,8(sp)
    8000298c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298e:	00003797          	auipc	a5,0x3
    80002992:	69278793          	addi	a5,a5,1682 # 80006020 <kernelvec>
    80002996:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299a:	6422                	ld	s0,8(sp)
    8000299c:	0141                	addi	sp,sp,16
    8000299e:	8082                	ret

00000000800029a0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a0:	1141                	addi	sp,sp,-16
    800029a2:	e406                	sd	ra,8(sp)
    800029a4:	e022                	sd	s0,0(sp)
    800029a6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	380080e7          	jalr	896(ra) # 80001d28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ba:	00004697          	auipc	a3,0x4
    800029be:	64668693          	addi	a3,a3,1606 # 80007000 <_trampoline>
    800029c2:	00004717          	auipc	a4,0x4
    800029c6:	63e70713          	addi	a4,a4,1598 # 80007000 <_trampoline>
    800029ca:	8f15                	sub	a4,a4,a3
    800029cc:	040007b7          	lui	a5,0x4000
    800029d0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029d2:	07b2                	slli	a5,a5,0xc
    800029d4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d6:	10571073          	csrw	stvec,a4

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029da:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029dc:	18002673          	csrr	a2,satp
    800029e0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e2:	7130                	ld	a2,96(a0)
    800029e4:	6538                	ld	a4,72(a0)
    800029e6:	6585                	lui	a1,0x1
    800029e8:	972e                	add	a4,a4,a1
    800029ea:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ec:	7138                	ld	a4,96(a0)
    800029ee:	00000617          	auipc	a2,0x0
    800029f2:	13860613          	addi	a2,a2,312 # 80002b26 <usertrap>
    800029f6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029f8:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fa:	8612                	mv	a2,tp
    800029fc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a02:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a06:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a0e:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a10:	6f18                	ld	a4,24(a4)
    80002a12:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a16:	6d2c                	ld	a1,88(a0)
    80002a18:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1a:	00004717          	auipc	a4,0x4
    80002a1e:	67670713          	addi	a4,a4,1654 # 80007090 <userret>
    80002a22:	8f15                	sub	a4,a4,a3
    80002a24:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a26:	577d                	li	a4,-1
    80002a28:	177e                	slli	a4,a4,0x3f
    80002a2a:	8dd9                	or	a1,a1,a4
    80002a2c:	02000537          	lui	a0,0x2000
    80002a30:	157d                	addi	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    80002a32:	0536                	slli	a0,a0,0xd
    80002a34:	9782                	jalr	a5
}
    80002a36:	60a2                	ld	ra,8(sp)
    80002a38:	6402                	ld	s0,0(sp)
    80002a3a:	0141                	addi	sp,sp,16
    80002a3c:	8082                	ret

0000000080002a3e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a48:	00016497          	auipc	s1,0x16
    80002a4c:	96048493          	addi	s1,s1,-1696 # 800183a8 <tickslock>
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	290080e7          	jalr	656(ra) # 80000ce2 <acquire>
  ticks++;
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	5c650513          	addi	a0,a0,1478 # 80009020 <ticks>
    80002a62:	411c                	lw	a5,0(a0)
    80002a64:	2785                	addiw	a5,a5,1
    80002a66:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	c58080e7          	jalr	-936(ra) # 800026c0 <wakeup>
  release(&tickslock);
    80002a70:	8526                	mv	a0,s1
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	340080e7          	jalr	832(ra) # 80000db2 <release>
}
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret

0000000080002a84 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a92:	00074d63          	bltz	a4,80002aac <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a96:	57fd                	li	a5,-1
    80002a98:	17fe                	slli	a5,a5,0x3f
    80002a9a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a9e:	06f70363          	beq	a4,a5,80002b04 <devintr+0x80>
  }
}
    80002aa2:	60e2                	ld	ra,24(sp)
    80002aa4:	6442                	ld	s0,16(sp)
    80002aa6:	64a2                	ld	s1,8(sp)
    80002aa8:	6105                	addi	sp,sp,32
    80002aaa:	8082                	ret
     (scause & 0xff) == 9){
    80002aac:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002ab0:	46a5                	li	a3,9
    80002ab2:	fed792e3          	bne	a5,a3,80002a96 <devintr+0x12>
    int irq = plic_claim();
    80002ab6:	00003097          	auipc	ra,0x3
    80002aba:	672080e7          	jalr	1650(ra) # 80006128 <plic_claim>
    80002abe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac0:	47a9                	li	a5,10
    80002ac2:	02f50763          	beq	a0,a5,80002af0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac6:	4785                	li	a5,1
    80002ac8:	02f50963          	beq	a0,a5,80002afa <devintr+0x76>
    return 1;
    80002acc:	4505                	li	a0,1
    } else if(irq){
    80002ace:	d8f1                	beqz	s1,80002aa2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad0:	85a6                	mv	a1,s1
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	89650513          	addi	a0,a0,-1898 # 80008368 <states.0+0x30>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	abc080e7          	jalr	-1348(ra) # 80000596 <printf>
      plic_complete(irq);
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	00003097          	auipc	ra,0x3
    80002ae8:	668080e7          	jalr	1640(ra) # 8000614c <plic_complete>
    return 1;
    80002aec:	4505                	li	a0,1
    80002aee:	bf55                	j	80002aa2 <devintr+0x1e>
      uartintr();
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	ed8080e7          	jalr	-296(ra) # 800009c8 <uartintr>
    80002af8:	b7ed                	j	80002ae2 <devintr+0x5e>
      virtio_disk_intr();
    80002afa:	00004097          	auipc	ra,0x4
    80002afe:	ade080e7          	jalr	-1314(ra) # 800065d8 <virtio_disk_intr>
    80002b02:	b7c5                	j	80002ae2 <devintr+0x5e>
    if(cpuid() == 0){
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	1f8080e7          	jalr	504(ra) # 80001cfc <cpuid>
    80002b0c:	c901                	beqz	a0,80002b1c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b0e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b14:	14479073          	csrw	sip,a5
    return 2;
    80002b18:	4509                	li	a0,2
    80002b1a:	b761                	j	80002aa2 <devintr+0x1e>
      clockintr();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	f22080e7          	jalr	-222(ra) # 80002a3e <clockintr>
    80002b24:	b7ed                	j	80002b0e <devintr+0x8a>

0000000080002b26 <usertrap>:
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b36:	1007f793          	andi	a5,a5,256
    80002b3a:	e3ad                	bnez	a5,80002b9c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3c:	00003797          	auipc	a5,0x3
    80002b40:	4e478793          	addi	a5,a5,1252 # 80006020 <kernelvec>
    80002b44:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	1e0080e7          	jalr	480(ra) # 80001d28 <myproc>
    80002b50:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b52:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b54:	14102773          	csrr	a4,sepc
    80002b58:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b5e:	47a1                	li	a5,8
    80002b60:	04f71c63          	bne	a4,a5,80002bb8 <usertrap+0x92>
    if(p->killed)
    80002b64:	5d1c                	lw	a5,56(a0)
    80002b66:	e3b9                	bnez	a5,80002bac <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b68:	70b8                	ld	a4,96(s1)
    80002b6a:	6f1c                	ld	a5,24(a4)
    80002b6c:	0791                	addi	a5,a5,4
    80002b6e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b70:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b74:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b78:	10079073          	csrw	sstatus,a5
    syscall();
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	2e0080e7          	jalr	736(ra) # 80002e5c <syscall>
  if(p->killed)
    80002b84:	5c9c                	lw	a5,56(s1)
    80002b86:	ebc1                	bnez	a5,80002c16 <usertrap+0xf0>
  usertrapret();
    80002b88:	00000097          	auipc	ra,0x0
    80002b8c:	e18080e7          	jalr	-488(ra) # 800029a0 <usertrapret>
}
    80002b90:	60e2                	ld	ra,24(sp)
    80002b92:	6442                	ld	s0,16(sp)
    80002b94:	64a2                	ld	s1,8(sp)
    80002b96:	6902                	ld	s2,0(sp)
    80002b98:	6105                	addi	sp,sp,32
    80002b9a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b9c:	00005517          	auipc	a0,0x5
    80002ba0:	7ec50513          	addi	a0,a0,2028 # 80008388 <states.0+0x50>
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	9a8080e7          	jalr	-1624(ra) # 8000054c <panic>
      exit(-1);
    80002bac:	557d                	li	a0,-1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	84c080e7          	jalr	-1972(ra) # 800023fa <exit>
    80002bb6:	bf4d                	j	80002b68 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bb8:	00000097          	auipc	ra,0x0
    80002bbc:	ecc080e7          	jalr	-308(ra) # 80002a84 <devintr>
    80002bc0:	892a                	mv	s2,a0
    80002bc2:	c501                	beqz	a0,80002bca <usertrap+0xa4>
  if(p->killed)
    80002bc4:	5c9c                	lw	a5,56(s1)
    80002bc6:	c3a1                	beqz	a5,80002c06 <usertrap+0xe0>
    80002bc8:	a815                	j	80002bfc <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bca:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bce:	40b0                	lw	a2,64(s1)
    80002bd0:	00005517          	auipc	a0,0x5
    80002bd4:	7d850513          	addi	a0,a0,2008 # 800083a8 <states.0+0x70>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	9be080e7          	jalr	-1602(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002be8:	00005517          	auipc	a0,0x5
    80002bec:	7f050513          	addi	a0,a0,2032 # 800083d8 <states.0+0xa0>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	9a6080e7          	jalr	-1626(ra) # 80000596 <printf>
    p->killed = 1;
    80002bf8:	4785                	li	a5,1
    80002bfa:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002bfc:	557d                	li	a0,-1
    80002bfe:	fffff097          	auipc	ra,0xfffff
    80002c02:	7fc080e7          	jalr	2044(ra) # 800023fa <exit>
  if(which_dev == 2)
    80002c06:	4789                	li	a5,2
    80002c08:	f8f910e3          	bne	s2,a5,80002b88 <usertrap+0x62>
    yield();
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	8f8080e7          	jalr	-1800(ra) # 80002504 <yield>
    80002c14:	bf95                	j	80002b88 <usertrap+0x62>
  int which_dev = 0;
    80002c16:	4901                	li	s2,0
    80002c18:	b7d5                	j	80002bfc <usertrap+0xd6>

0000000080002c1a <kerneltrap>:
{
    80002c1a:	7179                	addi	sp,sp,-48
    80002c1c:	f406                	sd	ra,40(sp)
    80002c1e:	f022                	sd	s0,32(sp)
    80002c20:	ec26                	sd	s1,24(sp)
    80002c22:	e84a                	sd	s2,16(sp)
    80002c24:	e44e                	sd	s3,8(sp)
    80002c26:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c28:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c2c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c30:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c34:	1004f793          	andi	a5,s1,256
    80002c38:	cb85                	beqz	a5,80002c68 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c3e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c40:	ef85                	bnez	a5,80002c78 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	e42080e7          	jalr	-446(ra) # 80002a84 <devintr>
    80002c4a:	cd1d                	beqz	a0,80002c88 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c4c:	4789                	li	a5,2
    80002c4e:	06f50a63          	beq	a0,a5,80002cc2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c52:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c56:	10049073          	csrw	sstatus,s1
}
    80002c5a:	70a2                	ld	ra,40(sp)
    80002c5c:	7402                	ld	s0,32(sp)
    80002c5e:	64e2                	ld	s1,24(sp)
    80002c60:	6942                	ld	s2,16(sp)
    80002c62:	69a2                	ld	s3,8(sp)
    80002c64:	6145                	addi	sp,sp,48
    80002c66:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c68:	00005517          	auipc	a0,0x5
    80002c6c:	79050513          	addi	a0,a0,1936 # 800083f8 <states.0+0xc0>
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	8dc080e7          	jalr	-1828(ra) # 8000054c <panic>
    panic("kerneltrap: interrupts enabled");
    80002c78:	00005517          	auipc	a0,0x5
    80002c7c:	7a850513          	addi	a0,a0,1960 # 80008420 <states.0+0xe8>
    80002c80:	ffffe097          	auipc	ra,0xffffe
    80002c84:	8cc080e7          	jalr	-1844(ra) # 8000054c <panic>
    printf("scause %p\n", scause);
    80002c88:	85ce                	mv	a1,s3
    80002c8a:	00005517          	auipc	a0,0x5
    80002c8e:	7b650513          	addi	a0,a0,1974 # 80008440 <states.0+0x108>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	904080e7          	jalr	-1788(ra) # 80000596 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c9e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca2:	00005517          	auipc	a0,0x5
    80002ca6:	7ae50513          	addi	a0,a0,1966 # 80008450 <states.0+0x118>
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	8ec080e7          	jalr	-1812(ra) # 80000596 <printf>
    panic("kerneltrap");
    80002cb2:	00005517          	auipc	a0,0x5
    80002cb6:	7b650513          	addi	a0,a0,1974 # 80008468 <states.0+0x130>
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	892080e7          	jalr	-1902(ra) # 8000054c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	066080e7          	jalr	102(ra) # 80001d28 <myproc>
    80002cca:	d541                	beqz	a0,80002c52 <kerneltrap+0x38>
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	05c080e7          	jalr	92(ra) # 80001d28 <myproc>
    80002cd4:	5118                	lw	a4,32(a0)
    80002cd6:	478d                	li	a5,3
    80002cd8:	f6f71de3          	bne	a4,a5,80002c52 <kerneltrap+0x38>
    yield();
    80002cdc:	00000097          	auipc	ra,0x0
    80002ce0:	828080e7          	jalr	-2008(ra) # 80002504 <yield>
    80002ce4:	b7bd                	j	80002c52 <kerneltrap+0x38>

0000000080002ce6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ce6:	1101                	addi	sp,sp,-32
    80002ce8:	ec06                	sd	ra,24(sp)
    80002cea:	e822                	sd	s0,16(sp)
    80002cec:	e426                	sd	s1,8(sp)
    80002cee:	1000                	addi	s0,sp,32
    80002cf0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	036080e7          	jalr	54(ra) # 80001d28 <myproc>
  switch (n) {
    80002cfa:	4795                	li	a5,5
    80002cfc:	0497e163          	bltu	a5,s1,80002d3e <argraw+0x58>
    80002d00:	048a                	slli	s1,s1,0x2
    80002d02:	00005717          	auipc	a4,0x5
    80002d06:	79e70713          	addi	a4,a4,1950 # 800084a0 <states.0+0x168>
    80002d0a:	94ba                	add	s1,s1,a4
    80002d0c:	409c                	lw	a5,0(s1)
    80002d0e:	97ba                	add	a5,a5,a4
    80002d10:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d12:	713c                	ld	a5,96(a0)
    80002d14:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	64a2                	ld	s1,8(sp)
    80002d1c:	6105                	addi	sp,sp,32
    80002d1e:	8082                	ret
    return p->trapframe->a1;
    80002d20:	713c                	ld	a5,96(a0)
    80002d22:	7fa8                	ld	a0,120(a5)
    80002d24:	bfcd                	j	80002d16 <argraw+0x30>
    return p->trapframe->a2;
    80002d26:	713c                	ld	a5,96(a0)
    80002d28:	63c8                	ld	a0,128(a5)
    80002d2a:	b7f5                	j	80002d16 <argraw+0x30>
    return p->trapframe->a3;
    80002d2c:	713c                	ld	a5,96(a0)
    80002d2e:	67c8                	ld	a0,136(a5)
    80002d30:	b7dd                	j	80002d16 <argraw+0x30>
    return p->trapframe->a4;
    80002d32:	713c                	ld	a5,96(a0)
    80002d34:	6bc8                	ld	a0,144(a5)
    80002d36:	b7c5                	j	80002d16 <argraw+0x30>
    return p->trapframe->a5;
    80002d38:	713c                	ld	a5,96(a0)
    80002d3a:	6fc8                	ld	a0,152(a5)
    80002d3c:	bfe9                	j	80002d16 <argraw+0x30>
  panic("argraw");
    80002d3e:	00005517          	auipc	a0,0x5
    80002d42:	73a50513          	addi	a0,a0,1850 # 80008478 <states.0+0x140>
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	806080e7          	jalr	-2042(ra) # 8000054c <panic>

0000000080002d4e <fetchaddr>:
{
    80002d4e:	1101                	addi	sp,sp,-32
    80002d50:	ec06                	sd	ra,24(sp)
    80002d52:	e822                	sd	s0,16(sp)
    80002d54:	e426                	sd	s1,8(sp)
    80002d56:	e04a                	sd	s2,0(sp)
    80002d58:	1000                	addi	s0,sp,32
    80002d5a:	84aa                	mv	s1,a0
    80002d5c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	fca080e7          	jalr	-54(ra) # 80001d28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d66:	693c                	ld	a5,80(a0)
    80002d68:	02f4f863          	bgeu	s1,a5,80002d98 <fetchaddr+0x4a>
    80002d6c:	00848713          	addi	a4,s1,8
    80002d70:	02e7e663          	bltu	a5,a4,80002d9c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d74:	46a1                	li	a3,8
    80002d76:	8626                	mv	a2,s1
    80002d78:	85ca                	mv	a1,s2
    80002d7a:	6d28                	ld	a0,88(a0)
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	d2e080e7          	jalr	-722(ra) # 80001aaa <copyin>
    80002d84:	00a03533          	snez	a0,a0
    80002d88:	40a00533          	neg	a0,a0
}
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6902                	ld	s2,0(sp)
    80002d94:	6105                	addi	sp,sp,32
    80002d96:	8082                	ret
    return -1;
    80002d98:	557d                	li	a0,-1
    80002d9a:	bfcd                	j	80002d8c <fetchaddr+0x3e>
    80002d9c:	557d                	li	a0,-1
    80002d9e:	b7fd                	j	80002d8c <fetchaddr+0x3e>

0000000080002da0 <fetchstr>:
{
    80002da0:	7179                	addi	sp,sp,-48
    80002da2:	f406                	sd	ra,40(sp)
    80002da4:	f022                	sd	s0,32(sp)
    80002da6:	ec26                	sd	s1,24(sp)
    80002da8:	e84a                	sd	s2,16(sp)
    80002daa:	e44e                	sd	s3,8(sp)
    80002dac:	1800                	addi	s0,sp,48
    80002dae:	892a                	mv	s2,a0
    80002db0:	84ae                	mv	s1,a1
    80002db2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	f74080e7          	jalr	-140(ra) # 80001d28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dbc:	86ce                	mv	a3,s3
    80002dbe:	864a                	mv	a2,s2
    80002dc0:	85a6                	mv	a1,s1
    80002dc2:	6d28                	ld	a0,88(a0)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	d74080e7          	jalr	-652(ra) # 80001b38 <copyinstr>
  if(err < 0)
    80002dcc:	00054763          	bltz	a0,80002dda <fetchstr+0x3a>
  return strlen(buf);
    80002dd0:	8526                	mv	a0,s1
    80002dd2:	ffffe097          	auipc	ra,0xffffe
    80002dd6:	474080e7          	jalr	1140(ra) # 80001246 <strlen>
}
    80002dda:	70a2                	ld	ra,40(sp)
    80002ddc:	7402                	ld	s0,32(sp)
    80002dde:	64e2                	ld	s1,24(sp)
    80002de0:	6942                	ld	s2,16(sp)
    80002de2:	69a2                	ld	s3,8(sp)
    80002de4:	6145                	addi	sp,sp,48
    80002de6:	8082                	ret

0000000080002de8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	e426                	sd	s1,8(sp)
    80002df0:	1000                	addi	s0,sp,32
    80002df2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df4:	00000097          	auipc	ra,0x0
    80002df8:	ef2080e7          	jalr	-270(ra) # 80002ce6 <argraw>
    80002dfc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dfe:	4501                	li	a0,0
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	64a2                	ld	s1,8(sp)
    80002e06:	6105                	addi	sp,sp,32
    80002e08:	8082                	ret

0000000080002e0a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e0a:	1101                	addi	sp,sp,-32
    80002e0c:	ec06                	sd	ra,24(sp)
    80002e0e:	e822                	sd	s0,16(sp)
    80002e10:	e426                	sd	s1,8(sp)
    80002e12:	1000                	addi	s0,sp,32
    80002e14:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e16:	00000097          	auipc	ra,0x0
    80002e1a:	ed0080e7          	jalr	-304(ra) # 80002ce6 <argraw>
    80002e1e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e20:	4501                	li	a0,0
    80002e22:	60e2                	ld	ra,24(sp)
    80002e24:	6442                	ld	s0,16(sp)
    80002e26:	64a2                	ld	s1,8(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret

0000000080002e2c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e2c:	1101                	addi	sp,sp,-32
    80002e2e:	ec06                	sd	ra,24(sp)
    80002e30:	e822                	sd	s0,16(sp)
    80002e32:	e426                	sd	s1,8(sp)
    80002e34:	e04a                	sd	s2,0(sp)
    80002e36:	1000                	addi	s0,sp,32
    80002e38:	84ae                	mv	s1,a1
    80002e3a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	eaa080e7          	jalr	-342(ra) # 80002ce6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e44:	864a                	mv	a2,s2
    80002e46:	85a6                	mv	a1,s1
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	f58080e7          	jalr	-168(ra) # 80002da0 <fetchstr>
}
    80002e50:	60e2                	ld	ra,24(sp)
    80002e52:	6442                	ld	s0,16(sp)
    80002e54:	64a2                	ld	s1,8(sp)
    80002e56:	6902                	ld	s2,0(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret

0000000080002e5c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e5c:	1101                	addi	sp,sp,-32
    80002e5e:	ec06                	sd	ra,24(sp)
    80002e60:	e822                	sd	s0,16(sp)
    80002e62:	e426                	sd	s1,8(sp)
    80002e64:	e04a                	sd	s2,0(sp)
    80002e66:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	ec0080e7          	jalr	-320(ra) # 80001d28 <myproc>
    80002e70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e72:	06053903          	ld	s2,96(a0)
    80002e76:	0a893783          	ld	a5,168(s2)
    80002e7a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e7e:	37fd                	addiw	a5,a5,-1
    80002e80:	4751                	li	a4,20
    80002e82:	00f76f63          	bltu	a4,a5,80002ea0 <syscall+0x44>
    80002e86:	00369713          	slli	a4,a3,0x3
    80002e8a:	00005797          	auipc	a5,0x5
    80002e8e:	62e78793          	addi	a5,a5,1582 # 800084b8 <syscalls>
    80002e92:	97ba                	add	a5,a5,a4
    80002e94:	639c                	ld	a5,0(a5)
    80002e96:	c789                	beqz	a5,80002ea0 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e98:	9782                	jalr	a5
    80002e9a:	06a93823          	sd	a0,112(s2)
    80002e9e:	a839                	j	80002ebc <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea0:	16048613          	addi	a2,s1,352
    80002ea4:	40ac                	lw	a1,64(s1)
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	5da50513          	addi	a0,a0,1498 # 80008480 <states.0+0x148>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6e8080e7          	jalr	1768(ra) # 80000596 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eb6:	70bc                	ld	a5,96(s1)
    80002eb8:	577d                	li	a4,-1
    80002eba:	fbb8                	sd	a4,112(a5)
  }
}
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	64a2                	ld	s1,8(sp)
    80002ec2:	6902                	ld	s2,0(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed0:	fec40593          	addi	a1,s0,-20
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	f12080e7          	jalr	-238(ra) # 80002de8 <argint>
    return -1;
    80002ede:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee0:	00054963          	bltz	a0,80002ef2 <sys_exit+0x2a>
  exit(n);
    80002ee4:	fec42503          	lw	a0,-20(s0)
    80002ee8:	fffff097          	auipc	ra,0xfffff
    80002eec:	512080e7          	jalr	1298(ra) # 800023fa <exit>
  return 0;  // not reached
    80002ef0:	4781                	li	a5,0
}
    80002ef2:	853e                	mv	a0,a5
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	6105                	addi	sp,sp,32
    80002efa:	8082                	ret

0000000080002efc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002efc:	1141                	addi	sp,sp,-16
    80002efe:	e406                	sd	ra,8(sp)
    80002f00:	e022                	sd	s0,0(sp)
    80002f02:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	e24080e7          	jalr	-476(ra) # 80001d28 <myproc>
}
    80002f0c:	4128                	lw	a0,64(a0)
    80002f0e:	60a2                	ld	ra,8(sp)
    80002f10:	6402                	ld	s0,0(sp)
    80002f12:	0141                	addi	sp,sp,16
    80002f14:	8082                	ret

0000000080002f16 <sys_fork>:

uint64
sys_fork(void)
{
    80002f16:	1141                	addi	sp,sp,-16
    80002f18:	e406                	sd	ra,8(sp)
    80002f1a:	e022                	sd	s0,0(sp)
    80002f1c:	0800                	addi	s0,sp,16
  return fork();
    80002f1e:	fffff097          	auipc	ra,0xfffff
    80002f22:	1ce080e7          	jalr	462(ra) # 800020ec <fork>
}
    80002f26:	60a2                	ld	ra,8(sp)
    80002f28:	6402                	ld	s0,0(sp)
    80002f2a:	0141                	addi	sp,sp,16
    80002f2c:	8082                	ret

0000000080002f2e <sys_wait>:

uint64
sys_wait(void)
{
    80002f2e:	1101                	addi	sp,sp,-32
    80002f30:	ec06                	sd	ra,24(sp)
    80002f32:	e822                	sd	s0,16(sp)
    80002f34:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f36:	fe840593          	addi	a1,s0,-24
    80002f3a:	4501                	li	a0,0
    80002f3c:	00000097          	auipc	ra,0x0
    80002f40:	ece080e7          	jalr	-306(ra) # 80002e0a <argaddr>
    80002f44:	87aa                	mv	a5,a0
    return -1;
    80002f46:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f48:	0007c863          	bltz	a5,80002f58 <sys_wait+0x2a>
  return wait(p);
    80002f4c:	fe843503          	ld	a0,-24(s0)
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	66e080e7          	jalr	1646(ra) # 800025be <wait>
}
    80002f58:	60e2                	ld	ra,24(sp)
    80002f5a:	6442                	ld	s0,16(sp)
    80002f5c:	6105                	addi	sp,sp,32
    80002f5e:	8082                	ret

0000000080002f60 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f60:	7179                	addi	sp,sp,-48
    80002f62:	f406                	sd	ra,40(sp)
    80002f64:	f022                	sd	s0,32(sp)
    80002f66:	ec26                	sd	s1,24(sp)
    80002f68:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f6a:	fdc40593          	addi	a1,s0,-36
    80002f6e:	4501                	li	a0,0
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	e78080e7          	jalr	-392(ra) # 80002de8 <argint>
    80002f78:	87aa                	mv	a5,a0
    return -1;
    80002f7a:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f7c:	0207c063          	bltz	a5,80002f9c <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	da8080e7          	jalr	-600(ra) # 80001d28 <myproc>
    80002f88:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80002f8a:	fdc42503          	lw	a0,-36(s0)
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	0e6080e7          	jalr	230(ra) # 80002074 <growproc>
    80002f96:	00054863          	bltz	a0,80002fa6 <sys_sbrk+0x46>
    return -1;
  // printf("addr:%d\n", addr);
  return addr;
    80002f9a:	8526                	mv	a0,s1
}
    80002f9c:	70a2                	ld	ra,40(sp)
    80002f9e:	7402                	ld	s0,32(sp)
    80002fa0:	64e2                	ld	s1,24(sp)
    80002fa2:	6145                	addi	sp,sp,48
    80002fa4:	8082                	ret
    return -1;
    80002fa6:	557d                	li	a0,-1
    80002fa8:	bfd5                	j	80002f9c <sys_sbrk+0x3c>

0000000080002faa <sys_sleep>:

uint64
sys_sleep(void)
{
    80002faa:	7139                	addi	sp,sp,-64
    80002fac:	fc06                	sd	ra,56(sp)
    80002fae:	f822                	sd	s0,48(sp)
    80002fb0:	f426                	sd	s1,40(sp)
    80002fb2:	f04a                	sd	s2,32(sp)
    80002fb4:	ec4e                	sd	s3,24(sp)
    80002fb6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fb8:	fcc40593          	addi	a1,s0,-52
    80002fbc:	4501                	li	a0,0
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	e2a080e7          	jalr	-470(ra) # 80002de8 <argint>
    return -1;
    80002fc6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fc8:	06054563          	bltz	a0,80003032 <sys_sleep+0x88>
  acquire(&tickslock);
    80002fcc:	00015517          	auipc	a0,0x15
    80002fd0:	3dc50513          	addi	a0,a0,988 # 800183a8 <tickslock>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	d0e080e7          	jalr	-754(ra) # 80000ce2 <acquire>
  ticks0 = ticks;
    80002fdc:	00006917          	auipc	s2,0x6
    80002fe0:	04492903          	lw	s2,68(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002fe4:	fcc42783          	lw	a5,-52(s0)
    80002fe8:	cf85                	beqz	a5,80003020 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fea:	00015997          	auipc	s3,0x15
    80002fee:	3be98993          	addi	s3,s3,958 # 800183a8 <tickslock>
    80002ff2:	00006497          	auipc	s1,0x6
    80002ff6:	02e48493          	addi	s1,s1,46 # 80009020 <ticks>
    if(myproc()->killed){
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	d2e080e7          	jalr	-722(ra) # 80001d28 <myproc>
    80003002:	5d1c                	lw	a5,56(a0)
    80003004:	ef9d                	bnez	a5,80003042 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003006:	85ce                	mv	a1,s3
    80003008:	8526                	mv	a0,s1
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	536080e7          	jalr	1334(ra) # 80002540 <sleep>
  while(ticks - ticks0 < n){
    80003012:	409c                	lw	a5,0(s1)
    80003014:	412787bb          	subw	a5,a5,s2
    80003018:	fcc42703          	lw	a4,-52(s0)
    8000301c:	fce7efe3          	bltu	a5,a4,80002ffa <sys_sleep+0x50>
  }
  release(&tickslock);
    80003020:	00015517          	auipc	a0,0x15
    80003024:	38850513          	addi	a0,a0,904 # 800183a8 <tickslock>
    80003028:	ffffe097          	auipc	ra,0xffffe
    8000302c:	d8a080e7          	jalr	-630(ra) # 80000db2 <release>
  return 0;
    80003030:	4781                	li	a5,0
}
    80003032:	853e                	mv	a0,a5
    80003034:	70e2                	ld	ra,56(sp)
    80003036:	7442                	ld	s0,48(sp)
    80003038:	74a2                	ld	s1,40(sp)
    8000303a:	7902                	ld	s2,32(sp)
    8000303c:	69e2                	ld	s3,24(sp)
    8000303e:	6121                	addi	sp,sp,64
    80003040:	8082                	ret
      release(&tickslock);
    80003042:	00015517          	auipc	a0,0x15
    80003046:	36650513          	addi	a0,a0,870 # 800183a8 <tickslock>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	d68080e7          	jalr	-664(ra) # 80000db2 <release>
      return -1;
    80003052:	57fd                	li	a5,-1
    80003054:	bff9                	j	80003032 <sys_sleep+0x88>

0000000080003056 <sys_kill>:

uint64
sys_kill(void)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000305e:	fec40593          	addi	a1,s0,-20
    80003062:	4501                	li	a0,0
    80003064:	00000097          	auipc	ra,0x0
    80003068:	d84080e7          	jalr	-636(ra) # 80002de8 <argint>
    8000306c:	87aa                	mv	a5,a0
    return -1;
    8000306e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003070:	0007c863          	bltz	a5,80003080 <sys_kill+0x2a>
  return kill(pid);
    80003074:	fec42503          	lw	a0,-20(s0)
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	6b2080e7          	jalr	1714(ra) # 8000272a <kill>
}
    80003080:	60e2                	ld	ra,24(sp)
    80003082:	6442                	ld	s0,16(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret

0000000080003088 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003092:	00015517          	auipc	a0,0x15
    80003096:	31650513          	addi	a0,a0,790 # 800183a8 <tickslock>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	c48080e7          	jalr	-952(ra) # 80000ce2 <acquire>
  xticks = ticks;
    800030a2:	00006497          	auipc	s1,0x6
    800030a6:	f7e4a483          	lw	s1,-130(s1) # 80009020 <ticks>
  release(&tickslock);
    800030aa:	00015517          	auipc	a0,0x15
    800030ae:	2fe50513          	addi	a0,a0,766 # 800183a8 <tickslock>
    800030b2:	ffffe097          	auipc	ra,0xffffe
    800030b6:	d00080e7          	jalr	-768(ra) # 80000db2 <release>
  return xticks;
}
    800030ba:	02049513          	slli	a0,s1,0x20
    800030be:	9101                	srli	a0,a0,0x20
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <map>:
  // Sorted by how recently the buffer was used.
  // head.next is most recent, head.prev is least.
  struct buf heads[NBUCKETS];
} bcache;

int map(int blockno){
    800030ca:	1141                	addi	sp,sp,-16
    800030cc:	e422                	sd	s0,8(sp)
    800030ce:	0800                	addi	s0,sp,16
  return blockno%NBUCKETS;
}
    800030d0:	47c5                	li	a5,17
    800030d2:	02f5653b          	remw	a0,a0,a5
    800030d6:	6422                	ld	s0,8(sp)
    800030d8:	0141                	addi	sp,sp,16
    800030da:	8082                	ret

00000000800030dc <binit>:

void binit(void)
{
    800030dc:	711d                	addi	sp,sp,-96
    800030de:	ec86                	sd	ra,88(sp)
    800030e0:	e8a2                	sd	s0,80(sp)
    800030e2:	e4a6                	sd	s1,72(sp)
    800030e4:	e0ca                	sd	s2,64(sp)
    800030e6:	fc4e                	sd	s3,56(sp)
    800030e8:	f852                	sd	s4,48(sp)
    800030ea:	f456                	sd	s5,40(sp)
    800030ec:	f05a                	sd	s6,32(sp)
    800030ee:	ec5e                	sd	s7,24(sp)
    800030f0:	e862                	sd	s8,16(sp)
    800030f2:	e466                	sd	s9,8(sp)
    800030f4:	e06a                	sd	s10,0(sp)
    800030f6:	1080                	addi	s0,sp,96
  struct buf *b;
  int bid = 0;

  // Create linked list of buffers
  for (bid = 0; bid < NBUCKETS; bid++)
    800030f8:	00015917          	auipc	s2,0x15
    800030fc:	2d090913          	addi	s2,s2,720 # 800183c8 <bcache>
    80003100:	0001e497          	auipc	s1,0x1e
    80003104:	82848493          	addi	s1,s1,-2008 # 80020928 <bcache+0x8560>
    80003108:	00022a17          	auipc	s4,0x22
    8000310c:	280a0a13          	addi	s4,s4,640 # 80025388 <sb>
  {
    initlock(&bcache.lock[bid], "bcache");
    80003110:	00005997          	auipc	s3,0x5
    80003114:	ff098993          	addi	s3,s3,-16 # 80008100 <digits+0xc0>
    80003118:	85ce                	mv	a1,s3
    8000311a:	854a                	mv	a0,s2
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	d42080e7          	jalr	-702(ra) # 80000e5e <initlock>
    bcache.heads[bid].prev = &bcache.heads[bid];
    80003124:	e8a4                	sd	s1,80(s1)
    bcache.heads[bid].next = &bcache.heads[bid];
    80003126:	eca4                	sd	s1,88(s1)
  for (bid = 0; bid < NBUCKETS; bid++)
    80003128:	02090913          	addi	s2,s2,32
    8000312c:	46048493          	addi	s1,s1,1120
    80003130:	ff4494e3          	bne	s1,s4,80003118 <binit+0x3c>
  }
  int bno = 0;
    80003134:	4981                	li	s3,0
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003136:	00015497          	auipc	s1,0x15
    8000313a:	4b248493          	addi	s1,s1,1202 # 800185e8 <bcache+0x220>
  return blockno%NBUCKETS;
    8000313e:	4d45                	li	s10,17
  {
    // printf("blockno:%d\n", bno);
    int m_no = map(bno);
    b->next = bcache.heads[m_no].next;
    80003140:	00015a17          	auipc	s4,0x15
    80003144:	288a0a13          	addi	s4,s4,648 # 800183c8 <bcache>
    80003148:	46000c93          	li	s9,1120
    8000314c:	6aa1                	lui	s5,0x8
    b->prev = &bcache.heads[m_no];
    8000314e:	560a8c13          	addi	s8,s5,1376 # 8560 <_entry-0x7fff7aa0>
    // b->top = bno;
    initsleeplock(&b->lock, "buffer");
    80003152:	00005b97          	auipc	s7,0x5
    80003156:	416b8b93          	addi	s7,s7,1046 # 80008568 <syscalls+0xb0>
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    8000315a:	0001db17          	auipc	s6,0x1d
    8000315e:	7ceb0b13          	addi	s6,s6,1998 # 80020928 <bcache+0x8560>
  return blockno%NBUCKETS;
    80003162:	03a9e7bb          	remw	a5,s3,s10
    b->next = bcache.heads[m_no].next;
    80003166:	039787b3          	mul	a5,a5,s9
    8000316a:	00fa0933          	add	s2,s4,a5
    8000316e:	9956                	add	s2,s2,s5
    80003170:	5b893703          	ld	a4,1464(s2)
    80003174:	ecb8                	sd	a4,88(s1)
    b->prev = &bcache.heads[m_no];
    80003176:	97e2                	add	a5,a5,s8
    80003178:	97d2                	add	a5,a5,s4
    8000317a:	e8bc                	sd	a5,80(s1)
    initsleeplock(&b->lock, "buffer");
    8000317c:	85de                	mv	a1,s7
    8000317e:	01048513          	addi	a0,s1,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	620080e7          	jalr	1568(ra) # 800047a2 <initsleeplock>
    bcache.heads[m_no].next->prev = b;
    8000318a:	5b893783          	ld	a5,1464(s2)
    8000318e:	eba4                	sd	s1,80(a5)
    bcache.heads[m_no].next = b;
    80003190:	5a993c23          	sd	s1,1464(s2)
    bno++;
    80003194:	2985                	addiw	s3,s3,1
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003196:	46048493          	addi	s1,s1,1120
    8000319a:	fd6494e3          	bne	s1,s6,80003162 <binit+0x86>
  }
}
    8000319e:	60e6                	ld	ra,88(sp)
    800031a0:	6446                	ld	s0,80(sp)
    800031a2:	64a6                	ld	s1,72(sp)
    800031a4:	6906                	ld	s2,64(sp)
    800031a6:	79e2                	ld	s3,56(sp)
    800031a8:	7a42                	ld	s4,48(sp)
    800031aa:	7aa2                	ld	s5,40(sp)
    800031ac:	7b02                	ld	s6,32(sp)
    800031ae:	6be2                	ld	s7,24(sp)
    800031b0:	6c42                	ld	s8,16(sp)
    800031b2:	6ca2                	ld	s9,8(sp)
    800031b4:	6d02                	ld	s10,0(sp)
    800031b6:	6125                	addi	sp,sp,96
    800031b8:	8082                	ret

00000000800031ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf *
bread(uint dev, uint blockno)
{
    800031ba:	7159                	addi	sp,sp,-112
    800031bc:	f486                	sd	ra,104(sp)
    800031be:	f0a2                	sd	s0,96(sp)
    800031c0:	eca6                	sd	s1,88(sp)
    800031c2:	e8ca                	sd	s2,80(sp)
    800031c4:	e4ce                	sd	s3,72(sp)
    800031c6:	e0d2                	sd	s4,64(sp)
    800031c8:	fc56                	sd	s5,56(sp)
    800031ca:	f85a                	sd	s6,48(sp)
    800031cc:	f45e                	sd	s7,40(sp)
    800031ce:	f062                	sd	s8,32(sp)
    800031d0:	ec66                	sd	s9,24(sp)
    800031d2:	e86a                	sd	s10,16(sp)
    800031d4:	e46e                	sd	s11,8(sp)
    800031d6:	1880                	addi	s0,sp,112
    800031d8:	89aa                	mv	s3,a0
    800031da:	8a2e                	mv	s4,a1
  return blockno%NBUCKETS;
    800031dc:	4ac5                	li	s5,17
    800031de:	0355eabb          	remw	s5,a1,s5
  acquire(&bcache.lock[bid]);
    800031e2:	005a9b93          	slli	s7,s5,0x5
    800031e6:	00015b17          	auipc	s6,0x15
    800031ea:	1e2b0b13          	addi	s6,s6,482 # 800183c8 <bcache>
    800031ee:	9bda                	add	s7,s7,s6
    800031f0:	855e                	mv	a0,s7
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	af0080e7          	jalr	-1296(ra) # 80000ce2 <acquire>
  for (b = bcache.heads[bid].next; b != &bcache.heads[bid]; b = b->next)
    800031fa:	46000913          	li	s2,1120
    800031fe:	032a8933          	mul	s2,s5,s2
    80003202:	012b0733          	add	a4,s6,s2
    80003206:	67a1                	lui	a5,0x8
    80003208:	973e                	add	a4,a4,a5
    8000320a:	5b873483          	ld	s1,1464(a4)
    8000320e:	56078793          	addi	a5,a5,1376 # 8560 <_entry-0x7fff7aa0>
    80003212:	993e                	add	s2,s2,a5
    80003214:	995a                	add	s2,s2,s6
    80003216:	05249863          	bne	s1,s2,80003266 <bread+0xac>
  for (b = bcache.heads[bid].prev; b != &bcache.heads[bid]; b = b->prev)
    8000321a:	46000793          	li	a5,1120
    8000321e:	02fa87b3          	mul	a5,s5,a5
    80003222:	00015717          	auipc	a4,0x15
    80003226:	1a670713          	addi	a4,a4,422 # 800183c8 <bcache>
    8000322a:	973e                	add	a4,a4,a5
    8000322c:	67a1                	lui	a5,0x8
    8000322e:	97ba                	add	a5,a5,a4
    80003230:	5b07b483          	ld	s1,1456(a5) # 85b0 <_entry-0x7fff7a50>
    80003234:	01248763          	beq	s1,s2,80003242 <bread+0x88>
    if (b->refcnt == 0)
    80003238:	44bc                	lw	a5,72(s1)
    8000323a:	cbb9                	beqz	a5,80003290 <bread+0xd6>
  for (b = bcache.heads[bid].prev; b != &bcache.heads[bid]; b = b->prev)
    8000323c:	68a4                	ld	s1,80(s1)
    8000323e:	ff249de3          	bne	s1,s2,80003238 <bread+0x7e>
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    80003242:	001a0b1b          	addiw	s6,s4,1
  return blockno%NBUCKETS;
    80003246:	47c5                	li	a5,17
    80003248:	02fb6b3b          	remw	s6,s6,a5
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    8000324c:	156a8263          	beq	s5,s6,80003390 <bread+0x1d6>
    acquire(&bcache.lock[bkid]);
    80003250:	00015c97          	auipc	s9,0x15
    80003254:	178c8c93          	addi	s9,s9,376 # 800183c8 <bcache>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003258:	46000d93          	li	s11,1120
    8000325c:	6d21                	lui	s10,0x8
    8000325e:	a8ed                	j	80003358 <bread+0x19e>
  for (b = bcache.heads[bid].next; b != &bcache.heads[bid]; b = b->next)
    80003260:	6ca4                	ld	s1,88(s1)
    80003262:	fb248ce3          	beq	s1,s2,8000321a <bread+0x60>
    if (b->dev == dev && b->blockno == blockno)
    80003266:	449c                	lw	a5,8(s1)
    80003268:	ff379ce3          	bne	a5,s3,80003260 <bread+0xa6>
    8000326c:	44dc                	lw	a5,12(s1)
    8000326e:	ff4799e3          	bne	a5,s4,80003260 <bread+0xa6>
      b->refcnt++;
    80003272:	44bc                	lw	a5,72(s1)
    80003274:	2785                	addiw	a5,a5,1
    80003276:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[bid]);
    80003278:	855e                	mv	a0,s7
    8000327a:	ffffe097          	auipc	ra,0xffffe
    8000327e:	b38080e7          	jalr	-1224(ra) # 80000db2 <release>
      acquiresleep(&b->lock);
    80003282:	01048513          	addi	a0,s1,16
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	556080e7          	jalr	1366(ra) # 800047dc <acquiresleep>
      return b;
    8000328e:	a841                	j	8000331e <bread+0x164>
      b->dev = dev;
    80003290:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003294:	0144a623          	sw	s4,12(s1)
      b->valid = 0;
    80003298:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000329c:	4785                	li	a5,1
    8000329e:	c4bc                	sw	a5,72(s1)
      release(&bcache.lock[bid]);
    800032a0:	855e                	mv	a0,s7
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	b10080e7          	jalr	-1264(ra) # 80000db2 <release>
      acquiresleep(&b->lock);
    800032aa:	01048513          	addi	a0,s1,16
    800032ae:	00001097          	auipc	ra,0x1
    800032b2:	52e080e7          	jalr	1326(ra) # 800047dc <acquiresleep>
      return b;
    800032b6:	a0a5                	j	8000331e <bread+0x164>
        b->valid = 0;
    800032b8:	0004a023          	sw	zero,0(s1)
        b->refcnt = 1;
    800032bc:	4785                	li	a5,1
    800032be:	c4bc                	sw	a5,72(s1)
        b->blockno = blockno;
    800032c0:	0144a623          	sw	s4,12(s1)
        b->dev = dev;
    800032c4:	0134a423          	sw	s3,8(s1)
        b->prev->next = b->next;
    800032c8:	68bc                	ld	a5,80(s1)
    800032ca:	6cb8                	ld	a4,88(s1)
    800032cc:	efb8                	sd	a4,88(a5)
        b->next->prev = b->prev; // fetch from ori list
    800032ce:	6cbc                	ld	a5,88(s1)
    800032d0:	68b8                	ld	a4,80(s1)
    800032d2:	ebb8                	sd	a4,80(a5)
        release(&bcache.lock[bkid]);
    800032d4:	8562                	mv	a0,s8
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	adc080e7          	jalr	-1316(ra) # 80000db2 <release>
        b->next = bcache.heads[bid].next;
    800032de:	46000793          	li	a5,1120
    800032e2:	02fa8ab3          	mul	s5,s5,a5
    800032e6:	00015717          	auipc	a4,0x15
    800032ea:	0e270713          	addi	a4,a4,226 # 800183c8 <bcache>
    800032ee:	9756                	add	a4,a4,s5
    800032f0:	67a1                	lui	a5,0x8
    800032f2:	97ba                	add	a5,a5,a4
    800032f4:	5b87b703          	ld	a4,1464(a5) # 85b8 <_entry-0x7fff7a48>
    800032f8:	ecb8                	sd	a4,88(s1)
        b->prev = &bcache.heads[bid];
    800032fa:	0524b823          	sd	s2,80(s1)
        bcache.heads[bid].next->prev = b;
    800032fe:	5b87b703          	ld	a4,1464(a5)
    80003302:	eb24                	sd	s1,80(a4)
        bcache.heads[bid].next = b;
    80003304:	5a97bc23          	sd	s1,1464(a5)
        release(&bcache.lock[bid]);
    80003308:	855e                	mv	a0,s7
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	aa8080e7          	jalr	-1368(ra) # 80000db2 <release>
        acquiresleep(&b->lock);
    80003312:	01048513          	addi	a0,s1,16
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	4c6080e7          	jalr	1222(ra) # 800047dc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if (!b->valid)
    8000331e:	409c                	lw	a5,0(s1)
    80003320:	c3c1                	beqz	a5,800033a0 <bread+0x1e6>
  {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003322:	8526                	mv	a0,s1
    80003324:	70a6                	ld	ra,104(sp)
    80003326:	7406                	ld	s0,96(sp)
    80003328:	64e6                	ld	s1,88(sp)
    8000332a:	6946                	ld	s2,80(sp)
    8000332c:	69a6                	ld	s3,72(sp)
    8000332e:	6a06                	ld	s4,64(sp)
    80003330:	7ae2                	ld	s5,56(sp)
    80003332:	7b42                	ld	s6,48(sp)
    80003334:	7ba2                	ld	s7,40(sp)
    80003336:	7c02                	ld	s8,32(sp)
    80003338:	6ce2                	ld	s9,24(sp)
    8000333a:	6d42                	ld	s10,16(sp)
    8000333c:	6da2                	ld	s11,8(sp)
    8000333e:	6165                	addi	sp,sp,112
    80003340:	8082                	ret
    release(&bcache.lock[bkid]);
    80003342:	8562                	mv	a0,s8
    80003344:	ffffe097          	auipc	ra,0xffffe
    80003348:	a6e080e7          	jalr	-1426(ra) # 80000db2 <release>
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    8000334c:	2b05                	addiw	s6,s6,1
  return blockno%NBUCKETS;
    8000334e:	47c5                	li	a5,17
    80003350:	02fb6b3b          	remw	s6,s6,a5
  for (int bkid = map(blockno+1); bkid != bid; bkid=map(bkid+1))
    80003354:	036a8e63          	beq	s5,s6,80003390 <bread+0x1d6>
    acquire(&bcache.lock[bkid]);
    80003358:	005b1c13          	slli	s8,s6,0x5
    8000335c:	9c66                	add	s8,s8,s9
    8000335e:	8562                	mv	a0,s8
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	982080e7          	jalr	-1662(ra) # 80000ce2 <acquire>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003368:	03bb0733          	mul	a4,s6,s11
    8000336c:	00ec87b3          	add	a5,s9,a4
    80003370:	97ea                	add	a5,a5,s10
    80003372:	5b87b483          	ld	s1,1464(a5)
    80003376:	67a1                	lui	a5,0x8
    80003378:	56078793          	addi	a5,a5,1376 # 8560 <_entry-0x7fff7aa0>
    8000337c:	973e                	add	a4,a4,a5
    8000337e:	9766                	add	a4,a4,s9
    80003380:	fc9701e3          	beq	a4,s1,80003342 <bread+0x188>
      if (b->refcnt == 0)
    80003384:	44bc                	lw	a5,72(s1)
    80003386:	db8d                	beqz	a5,800032b8 <bread+0xfe>
    for (b = bcache.heads[bkid].next; b != &bcache.heads[bkid]; b = b->next)
    80003388:	6ca4                	ld	s1,88(s1)
    8000338a:	fe971de3          	bne	a4,s1,80003384 <bread+0x1ca>
    8000338e:	bf55                	j	80003342 <bread+0x188>
  panic("bget: no buffers");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	1e050513          	addi	a0,a0,480 # 80008570 <syscalls+0xb8>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1b4080e7          	jalr	436(ra) # 8000054c <panic>
    virtio_disk_rw(b, 0);
    800033a0:	4581                	li	a1,0
    800033a2:	8526                	mv	a0,s1
    800033a4:	00003097          	auipc	ra,0x3
    800033a8:	fae080e7          	jalr	-82(ra) # 80006352 <virtio_disk_rw>
    b->valid = 1;
    800033ac:	4785                	li	a5,1
    800033ae:	c09c                	sw	a5,0(s1)
  return b;
    800033b0:	bf8d                	j	80003322 <bread+0x168>

00000000800033b2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void bwrite(struct buf *b)
{
    800033b2:	1101                	addi	sp,sp,-32
    800033b4:	ec06                	sd	ra,24(sp)
    800033b6:	e822                	sd	s0,16(sp)
    800033b8:	e426                	sd	s1,8(sp)
    800033ba:	1000                	addi	s0,sp,32
    800033bc:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    800033be:	0541                	addi	a0,a0,16
    800033c0:	00001097          	auipc	ra,0x1
    800033c4:	4b6080e7          	jalr	1206(ra) # 80004876 <holdingsleep>
    800033c8:	cd01                	beqz	a0,800033e0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033ca:	4585                	li	a1,1
    800033cc:	8526                	mv	a0,s1
    800033ce:	00003097          	auipc	ra,0x3
    800033d2:	f84080e7          	jalr	-124(ra) # 80006352 <virtio_disk_rw>
}
    800033d6:	60e2                	ld	ra,24(sp)
    800033d8:	6442                	ld	s0,16(sp)
    800033da:	64a2                	ld	s1,8(sp)
    800033dc:	6105                	addi	sp,sp,32
    800033de:	8082                	ret
    panic("bwrite");
    800033e0:	00005517          	auipc	a0,0x5
    800033e4:	1a850513          	addi	a0,a0,424 # 80008588 <syscalls+0xd0>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	164080e7          	jalr	356(ra) # 8000054c <panic>

00000000800033f0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void brelse(struct buf *b)
{
    800033f0:	7179                	addi	sp,sp,-48
    800033f2:	f406                	sd	ra,40(sp)
    800033f4:	f022                	sd	s0,32(sp)
    800033f6:	ec26                	sd	s1,24(sp)
    800033f8:	e84a                	sd	s2,16(sp)
    800033fa:	e44e                	sd	s3,8(sp)
    800033fc:	1800                	addi	s0,sp,48
    800033fe:	84aa                	mv	s1,a0
  if (!holdingsleep(&b->lock))
    80003400:	01050913          	addi	s2,a0,16
    80003404:	854a                	mv	a0,s2
    80003406:	00001097          	auipc	ra,0x1
    8000340a:	470080e7          	jalr	1136(ra) # 80004876 <holdingsleep>
    8000340e:	c951                	beqz	a0,800034a2 <brelse+0xb2>
  {
    panic("brelse");
  }

  releasesleep(&b->lock);//lock?
    80003410:	854a                	mv	a0,s2
    80003412:	00001097          	auipc	ra,0x1
    80003416:	420080e7          	jalr	1056(ra) # 80004832 <releasesleep>
  return blockno%NBUCKETS;
    8000341a:	00c4a903          	lw	s2,12(s1)
    8000341e:	47c5                	li	a5,17
    80003420:	02f9693b          	remw	s2,s2,a5

  // acquire(&bcache.lock);
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    80003424:	00591993          	slli	s3,s2,0x5
    80003428:	00015797          	auipc	a5,0x15
    8000342c:	fa078793          	addi	a5,a5,-96 # 800183c8 <bcache>
    80003430:	99be                	add	s3,s3,a5
    80003432:	854e                	mv	a0,s3
    80003434:	ffffe097          	auipc	ra,0xffffe
    80003438:	8ae080e7          	jalr	-1874(ra) # 80000ce2 <acquire>
  b->refcnt--;
    8000343c:	44bc                	lw	a5,72(s1)
    8000343e:	37fd                	addiw	a5,a5,-1
    80003440:	0007871b          	sext.w	a4,a5
    80003444:	c4bc                	sw	a5,72(s1)

  if (b->refcnt == 0)
    80003446:	e331                	bnez	a4,8000348a <brelse+0x9a>
  {
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003448:	6cbc                	ld	a5,88(s1)
    8000344a:	68b8                	ld	a4,80(s1)
    8000344c:	ebb8                	sd	a4,80(a5)
    b->prev->next = b->next;
    8000344e:	68bc                	ld	a5,80(s1)
    80003450:	6cb8                	ld	a4,88(s1)
    80003452:	efb8                	sd	a4,88(a5)
    b->next = bcache.heads[bid].next;
    80003454:	00015697          	auipc	a3,0x15
    80003458:	f7468693          	addi	a3,a3,-140 # 800183c8 <bcache>
    8000345c:	46000613          	li	a2,1120
    80003460:	02c907b3          	mul	a5,s2,a2
    80003464:	97b6                	add	a5,a5,a3
    80003466:	6721                	lui	a4,0x8
    80003468:	97ba                	add	a5,a5,a4
    8000346a:	5b87b583          	ld	a1,1464(a5)
    8000346e:	ecac                	sd	a1,88(s1)
    b->prev = &bcache.heads[bid];
    80003470:	02c90933          	mul	s2,s2,a2
    80003474:	56070713          	addi	a4,a4,1376 # 8560 <_entry-0x7fff7aa0>
    80003478:	993a                	add	s2,s2,a4
    8000347a:	9936                	add	s2,s2,a3
    8000347c:	0524b823          	sd	s2,80(s1)
    bcache.heads[bid].next->prev = b;
    80003480:	5b87b703          	ld	a4,1464(a5)
    80003484:	eb24                	sd	s1,80(a4)
    bcache.heads[bid].next = b;
    80003486:	5a97bc23          	sd	s1,1464(a5)
    // break;
  }
  release(&bcache.lock[bid]);
    8000348a:	854e                	mv	a0,s3
    8000348c:	ffffe097          	auipc	ra,0xffffe
    80003490:	926080e7          	jalr	-1754(ra) # 80000db2 <release>
  // }
}
    80003494:	70a2                	ld	ra,40(sp)
    80003496:	7402                	ld	s0,32(sp)
    80003498:	64e2                	ld	s1,24(sp)
    8000349a:	6942                	ld	s2,16(sp)
    8000349c:	69a2                	ld	s3,8(sp)
    8000349e:	6145                	addi	sp,sp,48
    800034a0:	8082                	ret
    panic("brelse");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	0ee50513          	addi	a0,a0,238 # 80008590 <syscalls+0xd8>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	0a2080e7          	jalr	162(ra) # 8000054c <panic>

00000000800034b2 <bpin>:

void bpin(struct buf *b)
{
    800034b2:	1101                	addi	sp,sp,-32
    800034b4:	ec06                	sd	ra,24(sp)
    800034b6:	e822                	sd	s0,16(sp)
    800034b8:	e426                	sd	s1,8(sp)
    800034ba:	e04a                	sd	s2,0(sp)
    800034bc:	1000                	addi	s0,sp,32
    800034be:	892a                	mv	s2,a0
  return blockno%NBUCKETS;
    800034c0:	4544                	lw	s1,12(a0)
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    800034c2:	47c5                	li	a5,17
    800034c4:	02f4e4bb          	remw	s1,s1,a5
    800034c8:	0496                	slli	s1,s1,0x5
    800034ca:	00015797          	auipc	a5,0x15
    800034ce:	efe78793          	addi	a5,a5,-258 # 800183c8 <bcache>
    800034d2:	94be                	add	s1,s1,a5
    800034d4:	8526                	mv	a0,s1
    800034d6:	ffffe097          	auipc	ra,0xffffe
    800034da:	80c080e7          	jalr	-2036(ra) # 80000ce2 <acquire>
  b->refcnt++;
    800034de:	04892783          	lw	a5,72(s2)
    800034e2:	2785                	addiw	a5,a5,1
    800034e4:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[bid]);
    800034e8:	8526                	mv	a0,s1
    800034ea:	ffffe097          	auipc	ra,0xffffe
    800034ee:	8c8080e7          	jalr	-1848(ra) # 80000db2 <release>
}
    800034f2:	60e2                	ld	ra,24(sp)
    800034f4:	6442                	ld	s0,16(sp)
    800034f6:	64a2                	ld	s1,8(sp)
    800034f8:	6902                	ld	s2,0(sp)
    800034fa:	6105                	addi	sp,sp,32
    800034fc:	8082                	ret

00000000800034fe <bunpin>:

void bunpin(struct buf *b)
{
    800034fe:	1101                	addi	sp,sp,-32
    80003500:	ec06                	sd	ra,24(sp)
    80003502:	e822                	sd	s0,16(sp)
    80003504:	e426                	sd	s1,8(sp)
    80003506:	e04a                	sd	s2,0(sp)
    80003508:	1000                	addi	s0,sp,32
    8000350a:	892a                	mv	s2,a0
  return blockno%NBUCKETS;
    8000350c:	4544                	lw	s1,12(a0)
  int bid = map(b->blockno);
  acquire(&bcache.lock[bid]);
    8000350e:	47c5                	li	a5,17
    80003510:	02f4e4bb          	remw	s1,s1,a5
    80003514:	0496                	slli	s1,s1,0x5
    80003516:	00015797          	auipc	a5,0x15
    8000351a:	eb278793          	addi	a5,a5,-334 # 800183c8 <bcache>
    8000351e:	94be                	add	s1,s1,a5
    80003520:	8526                	mv	a0,s1
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	7c0080e7          	jalr	1984(ra) # 80000ce2 <acquire>
  b->refcnt--;
    8000352a:	04892783          	lw	a5,72(s2)
    8000352e:	37fd                	addiw	a5,a5,-1
    80003530:	04f92423          	sw	a5,72(s2)
  release(&bcache.lock[bid]);
    80003534:	8526                	mv	a0,s1
    80003536:	ffffe097          	auipc	ra,0xffffe
    8000353a:	87c080e7          	jalr	-1924(ra) # 80000db2 <release>
}
    8000353e:	60e2                	ld	ra,24(sp)
    80003540:	6442                	ld	s0,16(sp)
    80003542:	64a2                	ld	s1,8(sp)
    80003544:	6902                	ld	s2,0(sp)
    80003546:	6105                	addi	sp,sp,32
    80003548:	8082                	ret

000000008000354a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000354a:	1101                	addi	sp,sp,-32
    8000354c:	ec06                	sd	ra,24(sp)
    8000354e:	e822                	sd	s0,16(sp)
    80003550:	e426                	sd	s1,8(sp)
    80003552:	e04a                	sd	s2,0(sp)
    80003554:	1000                	addi	s0,sp,32
    80003556:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003558:	00d5d59b          	srliw	a1,a1,0xd
    8000355c:	00022797          	auipc	a5,0x22
    80003560:	e487a783          	lw	a5,-440(a5) # 800253a4 <sb+0x1c>
    80003564:	9dbd                	addw	a1,a1,a5
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	c54080e7          	jalr	-940(ra) # 800031ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000356e:	0074f713          	andi	a4,s1,7
    80003572:	4785                	li	a5,1
    80003574:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003578:	14ce                	slli	s1,s1,0x33
    8000357a:	90d9                	srli	s1,s1,0x36
    8000357c:	00950733          	add	a4,a0,s1
    80003580:	06074703          	lbu	a4,96(a4)
    80003584:	00e7f6b3          	and	a3,a5,a4
    80003588:	c69d                	beqz	a3,800035b6 <bfree+0x6c>
    8000358a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000358c:	94aa                	add	s1,s1,a0
    8000358e:	fff7c793          	not	a5,a5
    80003592:	8f7d                	and	a4,a4,a5
    80003594:	06e48023          	sb	a4,96(s1)
  log_write(bp);
    80003598:	00001097          	auipc	ra,0x1
    8000359c:	11e080e7          	jalr	286(ra) # 800046b6 <log_write>
  brelse(bp);
    800035a0:	854a                	mv	a0,s2
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	e4e080e7          	jalr	-434(ra) # 800033f0 <brelse>
}
    800035aa:	60e2                	ld	ra,24(sp)
    800035ac:	6442                	ld	s0,16(sp)
    800035ae:	64a2                	ld	s1,8(sp)
    800035b0:	6902                	ld	s2,0(sp)
    800035b2:	6105                	addi	sp,sp,32
    800035b4:	8082                	ret
    panic("freeing free block");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	fe250513          	addi	a0,a0,-30 # 80008598 <syscalls+0xe0>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f8e080e7          	jalr	-114(ra) # 8000054c <panic>

00000000800035c6 <balloc>:
{
    800035c6:	711d                	addi	sp,sp,-96
    800035c8:	ec86                	sd	ra,88(sp)
    800035ca:	e8a2                	sd	s0,80(sp)
    800035cc:	e4a6                	sd	s1,72(sp)
    800035ce:	e0ca                	sd	s2,64(sp)
    800035d0:	fc4e                	sd	s3,56(sp)
    800035d2:	f852                	sd	s4,48(sp)
    800035d4:	f456                	sd	s5,40(sp)
    800035d6:	f05a                	sd	s6,32(sp)
    800035d8:	ec5e                	sd	s7,24(sp)
    800035da:	e862                	sd	s8,16(sp)
    800035dc:	e466                	sd	s9,8(sp)
    800035de:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035e0:	00022797          	auipc	a5,0x22
    800035e4:	dac7a783          	lw	a5,-596(a5) # 8002538c <sb+0x4>
    800035e8:	cbc1                	beqz	a5,80003678 <balloc+0xb2>
    800035ea:	8baa                	mv	s7,a0
    800035ec:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035ee:	00022b17          	auipc	s6,0x22
    800035f2:	d9ab0b13          	addi	s6,s6,-614 # 80025388 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035f6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035f8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035fa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035fc:	6c89                	lui	s9,0x2
    800035fe:	a831                	j	8000361a <balloc+0x54>
    brelse(bp);
    80003600:	854a                	mv	a0,s2
    80003602:	00000097          	auipc	ra,0x0
    80003606:	dee080e7          	jalr	-530(ra) # 800033f0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000360a:	015c87bb          	addw	a5,s9,s5
    8000360e:	00078a9b          	sext.w	s5,a5
    80003612:	004b2703          	lw	a4,4(s6)
    80003616:	06eaf163          	bgeu	s5,a4,80003678 <balloc+0xb2>
    bp = bread(dev, BBLOCK(b, sb));
    8000361a:	41fad79b          	sraiw	a5,s5,0x1f
    8000361e:	0137d79b          	srliw	a5,a5,0x13
    80003622:	015787bb          	addw	a5,a5,s5
    80003626:	40d7d79b          	sraiw	a5,a5,0xd
    8000362a:	01cb2583          	lw	a1,28(s6)
    8000362e:	9dbd                	addw	a1,a1,a5
    80003630:	855e                	mv	a0,s7
    80003632:	00000097          	auipc	ra,0x0
    80003636:	b88080e7          	jalr	-1144(ra) # 800031ba <bread>
    8000363a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000363c:	004b2503          	lw	a0,4(s6)
    80003640:	000a849b          	sext.w	s1,s5
    80003644:	8762                	mv	a4,s8
    80003646:	faa4fde3          	bgeu	s1,a0,80003600 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000364a:	00777693          	andi	a3,a4,7
    8000364e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003652:	41f7579b          	sraiw	a5,a4,0x1f
    80003656:	01d7d79b          	srliw	a5,a5,0x1d
    8000365a:	9fb9                	addw	a5,a5,a4
    8000365c:	4037d79b          	sraiw	a5,a5,0x3
    80003660:	00f90633          	add	a2,s2,a5
    80003664:	06064603          	lbu	a2,96(a2)
    80003668:	00c6f5b3          	and	a1,a3,a2
    8000366c:	cd91                	beqz	a1,80003688 <balloc+0xc2>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000366e:	2705                	addiw	a4,a4,1
    80003670:	2485                	addiw	s1,s1,1
    80003672:	fd471ae3          	bne	a4,s4,80003646 <balloc+0x80>
    80003676:	b769                	j	80003600 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003678:	00005517          	auipc	a0,0x5
    8000367c:	f3850513          	addi	a0,a0,-200 # 800085b0 <syscalls+0xf8>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	ecc080e7          	jalr	-308(ra) # 8000054c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003688:	97ca                	add	a5,a5,s2
    8000368a:	8e55                	or	a2,a2,a3
    8000368c:	06c78023          	sb	a2,96(a5)
        log_write(bp);
    80003690:	854a                	mv	a0,s2
    80003692:	00001097          	auipc	ra,0x1
    80003696:	024080e7          	jalr	36(ra) # 800046b6 <log_write>
        brelse(bp);
    8000369a:	854a                	mv	a0,s2
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	d54080e7          	jalr	-684(ra) # 800033f0 <brelse>
  bp = bread(dev, bno);
    800036a4:	85a6                	mv	a1,s1
    800036a6:	855e                	mv	a0,s7
    800036a8:	00000097          	auipc	ra,0x0
    800036ac:	b12080e7          	jalr	-1262(ra) # 800031ba <bread>
    800036b0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800036b2:	40000613          	li	a2,1024
    800036b6:	4581                	li	a1,0
    800036b8:	06050513          	addi	a0,a0,96
    800036bc:	ffffe097          	auipc	ra,0xffffe
    800036c0:	a06080e7          	jalr	-1530(ra) # 800010c2 <memset>
  log_write(bp);
    800036c4:	854a                	mv	a0,s2
    800036c6:	00001097          	auipc	ra,0x1
    800036ca:	ff0080e7          	jalr	-16(ra) # 800046b6 <log_write>
  brelse(bp);
    800036ce:	854a                	mv	a0,s2
    800036d0:	00000097          	auipc	ra,0x0
    800036d4:	d20080e7          	jalr	-736(ra) # 800033f0 <brelse>
}
    800036d8:	8526                	mv	a0,s1
    800036da:	60e6                	ld	ra,88(sp)
    800036dc:	6446                	ld	s0,80(sp)
    800036de:	64a6                	ld	s1,72(sp)
    800036e0:	6906                	ld	s2,64(sp)
    800036e2:	79e2                	ld	s3,56(sp)
    800036e4:	7a42                	ld	s4,48(sp)
    800036e6:	7aa2                	ld	s5,40(sp)
    800036e8:	7b02                	ld	s6,32(sp)
    800036ea:	6be2                	ld	s7,24(sp)
    800036ec:	6c42                	ld	s8,16(sp)
    800036ee:	6ca2                	ld	s9,8(sp)
    800036f0:	6125                	addi	sp,sp,96
    800036f2:	8082                	ret

00000000800036f4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800036f4:	7179                	addi	sp,sp,-48
    800036f6:	f406                	sd	ra,40(sp)
    800036f8:	f022                	sd	s0,32(sp)
    800036fa:	ec26                	sd	s1,24(sp)
    800036fc:	e84a                	sd	s2,16(sp)
    800036fe:	e44e                	sd	s3,8(sp)
    80003700:	e052                	sd	s4,0(sp)
    80003702:	1800                	addi	s0,sp,48
    80003704:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003706:	47ad                	li	a5,11
    80003708:	04b7fe63          	bgeu	a5,a1,80003764 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000370c:	ff45849b          	addiw	s1,a1,-12 # ff4 <_entry-0x7ffff00c>
    80003710:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003714:	0ff00793          	li	a5,255
    80003718:	0ae7e463          	bltu	a5,a4,800037c0 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000371c:	08852583          	lw	a1,136(a0)
    80003720:	c5b5                	beqz	a1,8000378c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003722:	00092503          	lw	a0,0(s2)
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	a94080e7          	jalr	-1388(ra) # 800031ba <bread>
    8000372e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003730:	06050793          	addi	a5,a0,96
    if((addr = a[bn]) == 0){
    80003734:	02049713          	slli	a4,s1,0x20
    80003738:	01e75593          	srli	a1,a4,0x1e
    8000373c:	00b784b3          	add	s1,a5,a1
    80003740:	0004a983          	lw	s3,0(s1)
    80003744:	04098e63          	beqz	s3,800037a0 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003748:	8552                	mv	a0,s4
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	ca6080e7          	jalr	-858(ra) # 800033f0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003752:	854e                	mv	a0,s3
    80003754:	70a2                	ld	ra,40(sp)
    80003756:	7402                	ld	s0,32(sp)
    80003758:	64e2                	ld	s1,24(sp)
    8000375a:	6942                	ld	s2,16(sp)
    8000375c:	69a2                	ld	s3,8(sp)
    8000375e:	6a02                	ld	s4,0(sp)
    80003760:	6145                	addi	sp,sp,48
    80003762:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003764:	02059793          	slli	a5,a1,0x20
    80003768:	01e7d593          	srli	a1,a5,0x1e
    8000376c:	00b504b3          	add	s1,a0,a1
    80003770:	0584a983          	lw	s3,88(s1)
    80003774:	fc099fe3          	bnez	s3,80003752 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003778:	4108                	lw	a0,0(a0)
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	e4c080e7          	jalr	-436(ra) # 800035c6 <balloc>
    80003782:	0005099b          	sext.w	s3,a0
    80003786:	0534ac23          	sw	s3,88(s1)
    8000378a:	b7e1                	j	80003752 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000378c:	4108                	lw	a0,0(a0)
    8000378e:	00000097          	auipc	ra,0x0
    80003792:	e38080e7          	jalr	-456(ra) # 800035c6 <balloc>
    80003796:	0005059b          	sext.w	a1,a0
    8000379a:	08b92423          	sw	a1,136(s2)
    8000379e:	b751                	j	80003722 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800037a0:	00092503          	lw	a0,0(s2)
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	e22080e7          	jalr	-478(ra) # 800035c6 <balloc>
    800037ac:	0005099b          	sext.w	s3,a0
    800037b0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800037b4:	8552                	mv	a0,s4
    800037b6:	00001097          	auipc	ra,0x1
    800037ba:	f00080e7          	jalr	-256(ra) # 800046b6 <log_write>
    800037be:	b769                	j	80003748 <bmap+0x54>
  panic("bmap: out of range");
    800037c0:	00005517          	auipc	a0,0x5
    800037c4:	e0850513          	addi	a0,a0,-504 # 800085c8 <syscalls+0x110>
    800037c8:	ffffd097          	auipc	ra,0xffffd
    800037cc:	d84080e7          	jalr	-636(ra) # 8000054c <panic>

00000000800037d0 <iget>:
{
    800037d0:	7179                	addi	sp,sp,-48
    800037d2:	f406                	sd	ra,40(sp)
    800037d4:	f022                	sd	s0,32(sp)
    800037d6:	ec26                	sd	s1,24(sp)
    800037d8:	e84a                	sd	s2,16(sp)
    800037da:	e44e                	sd	s3,8(sp)
    800037dc:	e052                	sd	s4,0(sp)
    800037de:	1800                	addi	s0,sp,48
    800037e0:	89aa                	mv	s3,a0
    800037e2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800037e4:	00022517          	auipc	a0,0x22
    800037e8:	bc450513          	addi	a0,a0,-1084 # 800253a8 <icache>
    800037ec:	ffffd097          	auipc	ra,0xffffd
    800037f0:	4f6080e7          	jalr	1270(ra) # 80000ce2 <acquire>
  empty = 0;
    800037f4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800037f6:	00022497          	auipc	s1,0x22
    800037fa:	bd248493          	addi	s1,s1,-1070 # 800253c8 <icache+0x20>
    800037fe:	00023697          	auipc	a3,0x23
    80003802:	7ea68693          	addi	a3,a3,2026 # 80026fe8 <log>
    80003806:	a039                	j	80003814 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003808:	02090b63          	beqz	s2,8000383e <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000380c:	09048493          	addi	s1,s1,144
    80003810:	02d48a63          	beq	s1,a3,80003844 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003814:	449c                	lw	a5,8(s1)
    80003816:	fef059e3          	blez	a5,80003808 <iget+0x38>
    8000381a:	4098                	lw	a4,0(s1)
    8000381c:	ff3716e3          	bne	a4,s3,80003808 <iget+0x38>
    80003820:	40d8                	lw	a4,4(s1)
    80003822:	ff4713e3          	bne	a4,s4,80003808 <iget+0x38>
      ip->ref++;
    80003826:	2785                	addiw	a5,a5,1
    80003828:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000382a:	00022517          	auipc	a0,0x22
    8000382e:	b7e50513          	addi	a0,a0,-1154 # 800253a8 <icache>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	580080e7          	jalr	1408(ra) # 80000db2 <release>
      return ip;
    8000383a:	8926                	mv	s2,s1
    8000383c:	a03d                	j	8000386a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000383e:	f7f9                	bnez	a5,8000380c <iget+0x3c>
    80003840:	8926                	mv	s2,s1
    80003842:	b7e9                	j	8000380c <iget+0x3c>
  if(empty == 0)
    80003844:	02090c63          	beqz	s2,8000387c <iget+0xac>
  ip->dev = dev;
    80003848:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000384c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003850:	4785                	li	a5,1
    80003852:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003856:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    8000385a:	00022517          	auipc	a0,0x22
    8000385e:	b4e50513          	addi	a0,a0,-1202 # 800253a8 <icache>
    80003862:	ffffd097          	auipc	ra,0xffffd
    80003866:	550080e7          	jalr	1360(ra) # 80000db2 <release>
}
    8000386a:	854a                	mv	a0,s2
    8000386c:	70a2                	ld	ra,40(sp)
    8000386e:	7402                	ld	s0,32(sp)
    80003870:	64e2                	ld	s1,24(sp)
    80003872:	6942                	ld	s2,16(sp)
    80003874:	69a2                	ld	s3,8(sp)
    80003876:	6a02                	ld	s4,0(sp)
    80003878:	6145                	addi	sp,sp,48
    8000387a:	8082                	ret
    panic("iget: no inodes");
    8000387c:	00005517          	auipc	a0,0x5
    80003880:	d6450513          	addi	a0,a0,-668 # 800085e0 <syscalls+0x128>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	cc8080e7          	jalr	-824(ra) # 8000054c <panic>

000000008000388c <fsinit>:
fsinit(int dev) {
    8000388c:	7179                	addi	sp,sp,-48
    8000388e:	f406                	sd	ra,40(sp)
    80003890:	f022                	sd	s0,32(sp)
    80003892:	ec26                	sd	s1,24(sp)
    80003894:	e84a                	sd	s2,16(sp)
    80003896:	e44e                	sd	s3,8(sp)
    80003898:	1800                	addi	s0,sp,48
    8000389a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000389c:	4585                	li	a1,1
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	91c080e7          	jalr	-1764(ra) # 800031ba <bread>
    800038a6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800038a8:	00022997          	auipc	s3,0x22
    800038ac:	ae098993          	addi	s3,s3,-1312 # 80025388 <sb>
    800038b0:	02000613          	li	a2,32
    800038b4:	06050593          	addi	a1,a0,96
    800038b8:	854e                	mv	a0,s3
    800038ba:	ffffe097          	auipc	ra,0xffffe
    800038be:	864080e7          	jalr	-1948(ra) # 8000111e <memmove>
  brelse(bp);
    800038c2:	8526                	mv	a0,s1
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	b2c080e7          	jalr	-1236(ra) # 800033f0 <brelse>
  if(sb.magic != FSMAGIC)
    800038cc:	0009a703          	lw	a4,0(s3)
    800038d0:	102037b7          	lui	a5,0x10203
    800038d4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038d8:	02f71263          	bne	a4,a5,800038fc <fsinit+0x70>
  initlog(dev, &sb);
    800038dc:	00022597          	auipc	a1,0x22
    800038e0:	aac58593          	addi	a1,a1,-1364 # 80025388 <sb>
    800038e4:	854a                	mv	a0,s2
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	b54080e7          	jalr	-1196(ra) # 8000443a <initlog>
}
    800038ee:	70a2                	ld	ra,40(sp)
    800038f0:	7402                	ld	s0,32(sp)
    800038f2:	64e2                	ld	s1,24(sp)
    800038f4:	6942                	ld	s2,16(sp)
    800038f6:	69a2                	ld	s3,8(sp)
    800038f8:	6145                	addi	sp,sp,48
    800038fa:	8082                	ret
    panic("invalid file system");
    800038fc:	00005517          	auipc	a0,0x5
    80003900:	cf450513          	addi	a0,a0,-780 # 800085f0 <syscalls+0x138>
    80003904:	ffffd097          	auipc	ra,0xffffd
    80003908:	c48080e7          	jalr	-952(ra) # 8000054c <panic>

000000008000390c <iinit>:
{
    8000390c:	7179                	addi	sp,sp,-48
    8000390e:	f406                	sd	ra,40(sp)
    80003910:	f022                	sd	s0,32(sp)
    80003912:	ec26                	sd	s1,24(sp)
    80003914:	e84a                	sd	s2,16(sp)
    80003916:	e44e                	sd	s3,8(sp)
    80003918:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000391a:	00005597          	auipc	a1,0x5
    8000391e:	cee58593          	addi	a1,a1,-786 # 80008608 <syscalls+0x150>
    80003922:	00022517          	auipc	a0,0x22
    80003926:	a8650513          	addi	a0,a0,-1402 # 800253a8 <icache>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	534080e7          	jalr	1332(ra) # 80000e5e <initlock>
  for(i = 0; i < NINODE; i++) {
    80003932:	00022497          	auipc	s1,0x22
    80003936:	aa648493          	addi	s1,s1,-1370 # 800253d8 <icache+0x30>
    8000393a:	00023997          	auipc	s3,0x23
    8000393e:	6be98993          	addi	s3,s3,1726 # 80026ff8 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003942:	00005917          	auipc	s2,0x5
    80003946:	cce90913          	addi	s2,s2,-818 # 80008610 <syscalls+0x158>
    8000394a:	85ca                	mv	a1,s2
    8000394c:	8526                	mv	a0,s1
    8000394e:	00001097          	auipc	ra,0x1
    80003952:	e54080e7          	jalr	-428(ra) # 800047a2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003956:	09048493          	addi	s1,s1,144
    8000395a:	ff3498e3          	bne	s1,s3,8000394a <iinit+0x3e>
}
    8000395e:	70a2                	ld	ra,40(sp)
    80003960:	7402                	ld	s0,32(sp)
    80003962:	64e2                	ld	s1,24(sp)
    80003964:	6942                	ld	s2,16(sp)
    80003966:	69a2                	ld	s3,8(sp)
    80003968:	6145                	addi	sp,sp,48
    8000396a:	8082                	ret

000000008000396c <ialloc>:
{
    8000396c:	715d                	addi	sp,sp,-80
    8000396e:	e486                	sd	ra,72(sp)
    80003970:	e0a2                	sd	s0,64(sp)
    80003972:	fc26                	sd	s1,56(sp)
    80003974:	f84a                	sd	s2,48(sp)
    80003976:	f44e                	sd	s3,40(sp)
    80003978:	f052                	sd	s4,32(sp)
    8000397a:	ec56                	sd	s5,24(sp)
    8000397c:	e85a                	sd	s6,16(sp)
    8000397e:	e45e                	sd	s7,8(sp)
    80003980:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003982:	00022717          	auipc	a4,0x22
    80003986:	a1272703          	lw	a4,-1518(a4) # 80025394 <sb+0xc>
    8000398a:	4785                	li	a5,1
    8000398c:	04e7fa63          	bgeu	a5,a4,800039e0 <ialloc+0x74>
    80003990:	8aaa                	mv	s5,a0
    80003992:	8bae                	mv	s7,a1
    80003994:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003996:	00022a17          	auipc	s4,0x22
    8000399a:	9f2a0a13          	addi	s4,s4,-1550 # 80025388 <sb>
    8000399e:	00048b1b          	sext.w	s6,s1
    800039a2:	0044d593          	srli	a1,s1,0x4
    800039a6:	018a2783          	lw	a5,24(s4)
    800039aa:	9dbd                	addw	a1,a1,a5
    800039ac:	8556                	mv	a0,s5
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	80c080e7          	jalr	-2036(ra) # 800031ba <bread>
    800039b6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039b8:	06050993          	addi	s3,a0,96
    800039bc:	00f4f793          	andi	a5,s1,15
    800039c0:	079a                	slli	a5,a5,0x6
    800039c2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039c4:	00099783          	lh	a5,0(s3)
    800039c8:	c785                	beqz	a5,800039f0 <ialloc+0x84>
    brelse(bp);
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	a26080e7          	jalr	-1498(ra) # 800033f0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039d2:	0485                	addi	s1,s1,1
    800039d4:	00ca2703          	lw	a4,12(s4)
    800039d8:	0004879b          	sext.w	a5,s1
    800039dc:	fce7e1e3          	bltu	a5,a4,8000399e <ialloc+0x32>
  panic("ialloc: no inodes");
    800039e0:	00005517          	auipc	a0,0x5
    800039e4:	c3850513          	addi	a0,a0,-968 # 80008618 <syscalls+0x160>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	b64080e7          	jalr	-1180(ra) # 8000054c <panic>
      memset(dip, 0, sizeof(*dip));
    800039f0:	04000613          	li	a2,64
    800039f4:	4581                	li	a1,0
    800039f6:	854e                	mv	a0,s3
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	6ca080e7          	jalr	1738(ra) # 800010c2 <memset>
      dip->type = type;
    80003a00:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	cb0080e7          	jalr	-848(ra) # 800046b6 <log_write>
      brelse(bp);
    80003a0e:	854a                	mv	a0,s2
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	9e0080e7          	jalr	-1568(ra) # 800033f0 <brelse>
      return iget(dev, inum);
    80003a18:	85da                	mv	a1,s6
    80003a1a:	8556                	mv	a0,s5
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	db4080e7          	jalr	-588(ra) # 800037d0 <iget>
}
    80003a24:	60a6                	ld	ra,72(sp)
    80003a26:	6406                	ld	s0,64(sp)
    80003a28:	74e2                	ld	s1,56(sp)
    80003a2a:	7942                	ld	s2,48(sp)
    80003a2c:	79a2                	ld	s3,40(sp)
    80003a2e:	7a02                	ld	s4,32(sp)
    80003a30:	6ae2                	ld	s5,24(sp)
    80003a32:	6b42                	ld	s6,16(sp)
    80003a34:	6ba2                	ld	s7,8(sp)
    80003a36:	6161                	addi	sp,sp,80
    80003a38:	8082                	ret

0000000080003a3a <iupdate>:
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	e04a                	sd	s2,0(sp)
    80003a44:	1000                	addi	s0,sp,32
    80003a46:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a48:	415c                	lw	a5,4(a0)
    80003a4a:	0047d79b          	srliw	a5,a5,0x4
    80003a4e:	00022597          	auipc	a1,0x22
    80003a52:	9525a583          	lw	a1,-1710(a1) # 800253a0 <sb+0x18>
    80003a56:	9dbd                	addw	a1,a1,a5
    80003a58:	4108                	lw	a0,0(a0)
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	760080e7          	jalr	1888(ra) # 800031ba <bread>
    80003a62:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a64:	06050793          	addi	a5,a0,96
    80003a68:	40d8                	lw	a4,4(s1)
    80003a6a:	8b3d                	andi	a4,a4,15
    80003a6c:	071a                	slli	a4,a4,0x6
    80003a6e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a70:	04c49703          	lh	a4,76(s1)
    80003a74:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a78:	04e49703          	lh	a4,78(s1)
    80003a7c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a80:	05049703          	lh	a4,80(s1)
    80003a84:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a88:	05249703          	lh	a4,82(s1)
    80003a8c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a90:	48f8                	lw	a4,84(s1)
    80003a92:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a94:	03400613          	li	a2,52
    80003a98:	05848593          	addi	a1,s1,88
    80003a9c:	00c78513          	addi	a0,a5,12
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	67e080e7          	jalr	1662(ra) # 8000111e <memmove>
  log_write(bp);
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	00001097          	auipc	ra,0x1
    80003aae:	c0c080e7          	jalr	-1012(ra) # 800046b6 <log_write>
  brelse(bp);
    80003ab2:	854a                	mv	a0,s2
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	93c080e7          	jalr	-1732(ra) # 800033f0 <brelse>
}
    80003abc:	60e2                	ld	ra,24(sp)
    80003abe:	6442                	ld	s0,16(sp)
    80003ac0:	64a2                	ld	s1,8(sp)
    80003ac2:	6902                	ld	s2,0(sp)
    80003ac4:	6105                	addi	sp,sp,32
    80003ac6:	8082                	ret

0000000080003ac8 <idup>:
{
    80003ac8:	1101                	addi	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	e426                	sd	s1,8(sp)
    80003ad0:	1000                	addi	s0,sp,32
    80003ad2:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003ad4:	00022517          	auipc	a0,0x22
    80003ad8:	8d450513          	addi	a0,a0,-1836 # 800253a8 <icache>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	206080e7          	jalr	518(ra) # 80000ce2 <acquire>
  ip->ref++;
    80003ae4:	449c                	lw	a5,8(s1)
    80003ae6:	2785                	addiw	a5,a5,1
    80003ae8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003aea:	00022517          	auipc	a0,0x22
    80003aee:	8be50513          	addi	a0,a0,-1858 # 800253a8 <icache>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	2c0080e7          	jalr	704(ra) # 80000db2 <release>
}
    80003afa:	8526                	mv	a0,s1
    80003afc:	60e2                	ld	ra,24(sp)
    80003afe:	6442                	ld	s0,16(sp)
    80003b00:	64a2                	ld	s1,8(sp)
    80003b02:	6105                	addi	sp,sp,32
    80003b04:	8082                	ret

0000000080003b06 <ilock>:
{
    80003b06:	1101                	addi	sp,sp,-32
    80003b08:	ec06                	sd	ra,24(sp)
    80003b0a:	e822                	sd	s0,16(sp)
    80003b0c:	e426                	sd	s1,8(sp)
    80003b0e:	e04a                	sd	s2,0(sp)
    80003b10:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b12:	c115                	beqz	a0,80003b36 <ilock+0x30>
    80003b14:	84aa                	mv	s1,a0
    80003b16:	451c                	lw	a5,8(a0)
    80003b18:	00f05f63          	blez	a5,80003b36 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b1c:	0541                	addi	a0,a0,16
    80003b1e:	00001097          	auipc	ra,0x1
    80003b22:	cbe080e7          	jalr	-834(ra) # 800047dc <acquiresleep>
  if(ip->valid == 0){
    80003b26:	44bc                	lw	a5,72(s1)
    80003b28:	cf99                	beqz	a5,80003b46 <ilock+0x40>
}
    80003b2a:	60e2                	ld	ra,24(sp)
    80003b2c:	6442                	ld	s0,16(sp)
    80003b2e:	64a2                	ld	s1,8(sp)
    80003b30:	6902                	ld	s2,0(sp)
    80003b32:	6105                	addi	sp,sp,32
    80003b34:	8082                	ret
    panic("ilock");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	afa50513          	addi	a0,a0,-1286 # 80008630 <syscalls+0x178>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	a0e080e7          	jalr	-1522(ra) # 8000054c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b46:	40dc                	lw	a5,4(s1)
    80003b48:	0047d79b          	srliw	a5,a5,0x4
    80003b4c:	00022597          	auipc	a1,0x22
    80003b50:	8545a583          	lw	a1,-1964(a1) # 800253a0 <sb+0x18>
    80003b54:	9dbd                	addw	a1,a1,a5
    80003b56:	4088                	lw	a0,0(s1)
    80003b58:	fffff097          	auipc	ra,0xfffff
    80003b5c:	662080e7          	jalr	1634(ra) # 800031ba <bread>
    80003b60:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b62:	06050593          	addi	a1,a0,96
    80003b66:	40dc                	lw	a5,4(s1)
    80003b68:	8bbd                	andi	a5,a5,15
    80003b6a:	079a                	slli	a5,a5,0x6
    80003b6c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b6e:	00059783          	lh	a5,0(a1)
    80003b72:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003b76:	00259783          	lh	a5,2(a1)
    80003b7a:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003b7e:	00459783          	lh	a5,4(a1)
    80003b82:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003b86:	00659783          	lh	a5,6(a1)
    80003b8a:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003b8e:	459c                	lw	a5,8(a1)
    80003b90:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b92:	03400613          	li	a2,52
    80003b96:	05b1                	addi	a1,a1,12
    80003b98:	05848513          	addi	a0,s1,88
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	582080e7          	jalr	1410(ra) # 8000111e <memmove>
    brelse(bp);
    80003ba4:	854a                	mv	a0,s2
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	84a080e7          	jalr	-1974(ra) # 800033f0 <brelse>
    ip->valid = 1;
    80003bae:	4785                	li	a5,1
    80003bb0:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003bb2:	04c49783          	lh	a5,76(s1)
    80003bb6:	fbb5                	bnez	a5,80003b2a <ilock+0x24>
      panic("ilock: no type");
    80003bb8:	00005517          	auipc	a0,0x5
    80003bbc:	a8050513          	addi	a0,a0,-1408 # 80008638 <syscalls+0x180>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	98c080e7          	jalr	-1652(ra) # 8000054c <panic>

0000000080003bc8 <iunlock>:
{
    80003bc8:	1101                	addi	sp,sp,-32
    80003bca:	ec06                	sd	ra,24(sp)
    80003bcc:	e822                	sd	s0,16(sp)
    80003bce:	e426                	sd	s1,8(sp)
    80003bd0:	e04a                	sd	s2,0(sp)
    80003bd2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bd4:	c905                	beqz	a0,80003c04 <iunlock+0x3c>
    80003bd6:	84aa                	mv	s1,a0
    80003bd8:	01050913          	addi	s2,a0,16
    80003bdc:	854a                	mv	a0,s2
    80003bde:	00001097          	auipc	ra,0x1
    80003be2:	c98080e7          	jalr	-872(ra) # 80004876 <holdingsleep>
    80003be6:	cd19                	beqz	a0,80003c04 <iunlock+0x3c>
    80003be8:	449c                	lw	a5,8(s1)
    80003bea:	00f05d63          	blez	a5,80003c04 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bee:	854a                	mv	a0,s2
    80003bf0:	00001097          	auipc	ra,0x1
    80003bf4:	c42080e7          	jalr	-958(ra) # 80004832 <releasesleep>
}
    80003bf8:	60e2                	ld	ra,24(sp)
    80003bfa:	6442                	ld	s0,16(sp)
    80003bfc:	64a2                	ld	s1,8(sp)
    80003bfe:	6902                	ld	s2,0(sp)
    80003c00:	6105                	addi	sp,sp,32
    80003c02:	8082                	ret
    panic("iunlock");
    80003c04:	00005517          	auipc	a0,0x5
    80003c08:	a4450513          	addi	a0,a0,-1468 # 80008648 <syscalls+0x190>
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	940080e7          	jalr	-1728(ra) # 8000054c <panic>

0000000080003c14 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c14:	7179                	addi	sp,sp,-48
    80003c16:	f406                	sd	ra,40(sp)
    80003c18:	f022                	sd	s0,32(sp)
    80003c1a:	ec26                	sd	s1,24(sp)
    80003c1c:	e84a                	sd	s2,16(sp)
    80003c1e:	e44e                	sd	s3,8(sp)
    80003c20:	e052                	sd	s4,0(sp)
    80003c22:	1800                	addi	s0,sp,48
    80003c24:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c26:	05850493          	addi	s1,a0,88
    80003c2a:	08850913          	addi	s2,a0,136
    80003c2e:	a021                	j	80003c36 <itrunc+0x22>
    80003c30:	0491                	addi	s1,s1,4
    80003c32:	01248d63          	beq	s1,s2,80003c4c <itrunc+0x38>
    if(ip->addrs[i]){
    80003c36:	408c                	lw	a1,0(s1)
    80003c38:	dde5                	beqz	a1,80003c30 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c3a:	0009a503          	lw	a0,0(s3)
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	90c080e7          	jalr	-1780(ra) # 8000354a <bfree>
      ip->addrs[i] = 0;
    80003c46:	0004a023          	sw	zero,0(s1)
    80003c4a:	b7dd                	j	80003c30 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c4c:	0889a583          	lw	a1,136(s3)
    80003c50:	e185                	bnez	a1,80003c70 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c52:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003c56:	854e                	mv	a0,s3
    80003c58:	00000097          	auipc	ra,0x0
    80003c5c:	de2080e7          	jalr	-542(ra) # 80003a3a <iupdate>
}
    80003c60:	70a2                	ld	ra,40(sp)
    80003c62:	7402                	ld	s0,32(sp)
    80003c64:	64e2                	ld	s1,24(sp)
    80003c66:	6942                	ld	s2,16(sp)
    80003c68:	69a2                	ld	s3,8(sp)
    80003c6a:	6a02                	ld	s4,0(sp)
    80003c6c:	6145                	addi	sp,sp,48
    80003c6e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c70:	0009a503          	lw	a0,0(s3)
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	546080e7          	jalr	1350(ra) # 800031ba <bread>
    80003c7c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c7e:	06050493          	addi	s1,a0,96
    80003c82:	46050913          	addi	s2,a0,1120
    80003c86:	a021                	j	80003c8e <itrunc+0x7a>
    80003c88:	0491                	addi	s1,s1,4
    80003c8a:	01248b63          	beq	s1,s2,80003ca0 <itrunc+0x8c>
      if(a[j])
    80003c8e:	408c                	lw	a1,0(s1)
    80003c90:	dde5                	beqz	a1,80003c88 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c92:	0009a503          	lw	a0,0(s3)
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	8b4080e7          	jalr	-1868(ra) # 8000354a <bfree>
    80003c9e:	b7ed                	j	80003c88 <itrunc+0x74>
    brelse(bp);
    80003ca0:	8552                	mv	a0,s4
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	74e080e7          	jalr	1870(ra) # 800033f0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003caa:	0889a583          	lw	a1,136(s3)
    80003cae:	0009a503          	lw	a0,0(s3)
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	898080e7          	jalr	-1896(ra) # 8000354a <bfree>
    ip->addrs[NDIRECT] = 0;
    80003cba:	0809a423          	sw	zero,136(s3)
    80003cbe:	bf51                	j	80003c52 <itrunc+0x3e>

0000000080003cc0 <iput>:
{
    80003cc0:	1101                	addi	sp,sp,-32
    80003cc2:	ec06                	sd	ra,24(sp)
    80003cc4:	e822                	sd	s0,16(sp)
    80003cc6:	e426                	sd	s1,8(sp)
    80003cc8:	e04a                	sd	s2,0(sp)
    80003cca:	1000                	addi	s0,sp,32
    80003ccc:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003cce:	00021517          	auipc	a0,0x21
    80003cd2:	6da50513          	addi	a0,a0,1754 # 800253a8 <icache>
    80003cd6:	ffffd097          	auipc	ra,0xffffd
    80003cda:	00c080e7          	jalr	12(ra) # 80000ce2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cde:	4498                	lw	a4,8(s1)
    80003ce0:	4785                	li	a5,1
    80003ce2:	02f70363          	beq	a4,a5,80003d08 <iput+0x48>
  ip->ref--;
    80003ce6:	449c                	lw	a5,8(s1)
    80003ce8:	37fd                	addiw	a5,a5,-1
    80003cea:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003cec:	00021517          	auipc	a0,0x21
    80003cf0:	6bc50513          	addi	a0,a0,1724 # 800253a8 <icache>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	0be080e7          	jalr	190(ra) # 80000db2 <release>
}
    80003cfc:	60e2                	ld	ra,24(sp)
    80003cfe:	6442                	ld	s0,16(sp)
    80003d00:	64a2                	ld	s1,8(sp)
    80003d02:	6902                	ld	s2,0(sp)
    80003d04:	6105                	addi	sp,sp,32
    80003d06:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d08:	44bc                	lw	a5,72(s1)
    80003d0a:	dff1                	beqz	a5,80003ce6 <iput+0x26>
    80003d0c:	05249783          	lh	a5,82(s1)
    80003d10:	fbf9                	bnez	a5,80003ce6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d12:	01048913          	addi	s2,s1,16
    80003d16:	854a                	mv	a0,s2
    80003d18:	00001097          	auipc	ra,0x1
    80003d1c:	ac4080e7          	jalr	-1340(ra) # 800047dc <acquiresleep>
    release(&icache.lock);
    80003d20:	00021517          	auipc	a0,0x21
    80003d24:	68850513          	addi	a0,a0,1672 # 800253a8 <icache>
    80003d28:	ffffd097          	auipc	ra,0xffffd
    80003d2c:	08a080e7          	jalr	138(ra) # 80000db2 <release>
    itrunc(ip);
    80003d30:	8526                	mv	a0,s1
    80003d32:	00000097          	auipc	ra,0x0
    80003d36:	ee2080e7          	jalr	-286(ra) # 80003c14 <itrunc>
    ip->type = 0;
    80003d3a:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003d3e:	8526                	mv	a0,s1
    80003d40:	00000097          	auipc	ra,0x0
    80003d44:	cfa080e7          	jalr	-774(ra) # 80003a3a <iupdate>
    ip->valid = 0;
    80003d48:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003d4c:	854a                	mv	a0,s2
    80003d4e:	00001097          	auipc	ra,0x1
    80003d52:	ae4080e7          	jalr	-1308(ra) # 80004832 <releasesleep>
    acquire(&icache.lock);
    80003d56:	00021517          	auipc	a0,0x21
    80003d5a:	65250513          	addi	a0,a0,1618 # 800253a8 <icache>
    80003d5e:	ffffd097          	auipc	ra,0xffffd
    80003d62:	f84080e7          	jalr	-124(ra) # 80000ce2 <acquire>
    80003d66:	b741                	j	80003ce6 <iput+0x26>

0000000080003d68 <iunlockput>:
{
    80003d68:	1101                	addi	sp,sp,-32
    80003d6a:	ec06                	sd	ra,24(sp)
    80003d6c:	e822                	sd	s0,16(sp)
    80003d6e:	e426                	sd	s1,8(sp)
    80003d70:	1000                	addi	s0,sp,32
    80003d72:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	e54080e7          	jalr	-428(ra) # 80003bc8 <iunlock>
  iput(ip);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	f42080e7          	jalr	-190(ra) # 80003cc0 <iput>
}
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6105                	addi	sp,sp,32
    80003d8e:	8082                	ret

0000000080003d90 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d90:	1141                	addi	sp,sp,-16
    80003d92:	e422                	sd	s0,8(sp)
    80003d94:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d96:	411c                	lw	a5,0(a0)
    80003d98:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d9a:	415c                	lw	a5,4(a0)
    80003d9c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d9e:	04c51783          	lh	a5,76(a0)
    80003da2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003da6:	05251783          	lh	a5,82(a0)
    80003daa:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003dae:	05456783          	lwu	a5,84(a0)
    80003db2:	e99c                	sd	a5,16(a1)
}
    80003db4:	6422                	ld	s0,8(sp)
    80003db6:	0141                	addi	sp,sp,16
    80003db8:	8082                	ret

0000000080003dba <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003dba:	497c                	lw	a5,84(a0)
    80003dbc:	0ed7e963          	bltu	a5,a3,80003eae <readi+0xf4>
{
    80003dc0:	7159                	addi	sp,sp,-112
    80003dc2:	f486                	sd	ra,104(sp)
    80003dc4:	f0a2                	sd	s0,96(sp)
    80003dc6:	eca6                	sd	s1,88(sp)
    80003dc8:	e8ca                	sd	s2,80(sp)
    80003dca:	e4ce                	sd	s3,72(sp)
    80003dcc:	e0d2                	sd	s4,64(sp)
    80003dce:	fc56                	sd	s5,56(sp)
    80003dd0:	f85a                	sd	s6,48(sp)
    80003dd2:	f45e                	sd	s7,40(sp)
    80003dd4:	f062                	sd	s8,32(sp)
    80003dd6:	ec66                	sd	s9,24(sp)
    80003dd8:	e86a                	sd	s10,16(sp)
    80003dda:	e46e                	sd	s11,8(sp)
    80003ddc:	1880                	addi	s0,sp,112
    80003dde:	8baa                	mv	s7,a0
    80003de0:	8c2e                	mv	s8,a1
    80003de2:	8ab2                	mv	s5,a2
    80003de4:	84b6                	mv	s1,a3
    80003de6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003de8:	9f35                	addw	a4,a4,a3
    return 0;
    80003dea:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dec:	0ad76063          	bltu	a4,a3,80003e8c <readi+0xd2>
  if(off + n > ip->size)
    80003df0:	00e7f463          	bgeu	a5,a4,80003df8 <readi+0x3e>
    n = ip->size - off;
    80003df4:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003df8:	0a0b0963          	beqz	s6,80003eaa <readi+0xf0>
    80003dfc:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dfe:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e02:	5cfd                	li	s9,-1
    80003e04:	a82d                	j	80003e3e <readi+0x84>
    80003e06:	020a1d93          	slli	s11,s4,0x20
    80003e0a:	020ddd93          	srli	s11,s11,0x20
    80003e0e:	06090613          	addi	a2,s2,96
    80003e12:	86ee                	mv	a3,s11
    80003e14:	963a                	add	a2,a2,a4
    80003e16:	85d6                	mv	a1,s5
    80003e18:	8562                	mv	a0,s8
    80003e1a:	fffff097          	auipc	ra,0xfffff
    80003e1e:	980080e7          	jalr	-1664(ra) # 8000279a <either_copyout>
    80003e22:	05950d63          	beq	a0,s9,80003e7c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e26:	854a                	mv	a0,s2
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	5c8080e7          	jalr	1480(ra) # 800033f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e30:	013a09bb          	addw	s3,s4,s3
    80003e34:	009a04bb          	addw	s1,s4,s1
    80003e38:	9aee                	add	s5,s5,s11
    80003e3a:	0569f763          	bgeu	s3,s6,80003e88 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e3e:	000ba903          	lw	s2,0(s7)
    80003e42:	00a4d59b          	srliw	a1,s1,0xa
    80003e46:	855e                	mv	a0,s7
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	8ac080e7          	jalr	-1876(ra) # 800036f4 <bmap>
    80003e50:	0005059b          	sext.w	a1,a0
    80003e54:	854a                	mv	a0,s2
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	364080e7          	jalr	868(ra) # 800031ba <bread>
    80003e5e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e60:	3ff4f713          	andi	a4,s1,1023
    80003e64:	40ed07bb          	subw	a5,s10,a4
    80003e68:	413b06bb          	subw	a3,s6,s3
    80003e6c:	8a3e                	mv	s4,a5
    80003e6e:	2781                	sext.w	a5,a5
    80003e70:	0006861b          	sext.w	a2,a3
    80003e74:	f8f679e3          	bgeu	a2,a5,80003e06 <readi+0x4c>
    80003e78:	8a36                	mv	s4,a3
    80003e7a:	b771                	j	80003e06 <readi+0x4c>
      brelse(bp);
    80003e7c:	854a                	mv	a0,s2
    80003e7e:	fffff097          	auipc	ra,0xfffff
    80003e82:	572080e7          	jalr	1394(ra) # 800033f0 <brelse>
      tot = -1;
    80003e86:	59fd                	li	s3,-1
  }
  return tot;
    80003e88:	0009851b          	sext.w	a0,s3
}
    80003e8c:	70a6                	ld	ra,104(sp)
    80003e8e:	7406                	ld	s0,96(sp)
    80003e90:	64e6                	ld	s1,88(sp)
    80003e92:	6946                	ld	s2,80(sp)
    80003e94:	69a6                	ld	s3,72(sp)
    80003e96:	6a06                	ld	s4,64(sp)
    80003e98:	7ae2                	ld	s5,56(sp)
    80003e9a:	7b42                	ld	s6,48(sp)
    80003e9c:	7ba2                	ld	s7,40(sp)
    80003e9e:	7c02                	ld	s8,32(sp)
    80003ea0:	6ce2                	ld	s9,24(sp)
    80003ea2:	6d42                	ld	s10,16(sp)
    80003ea4:	6da2                	ld	s11,8(sp)
    80003ea6:	6165                	addi	sp,sp,112
    80003ea8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003eaa:	89da                	mv	s3,s6
    80003eac:	bff1                	j	80003e88 <readi+0xce>
    return 0;
    80003eae:	4501                	li	a0,0
}
    80003eb0:	8082                	ret

0000000080003eb2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003eb2:	497c                	lw	a5,84(a0)
    80003eb4:	10d7e763          	bltu	a5,a3,80003fc2 <writei+0x110>
{
    80003eb8:	7159                	addi	sp,sp,-112
    80003eba:	f486                	sd	ra,104(sp)
    80003ebc:	f0a2                	sd	s0,96(sp)
    80003ebe:	eca6                	sd	s1,88(sp)
    80003ec0:	e8ca                	sd	s2,80(sp)
    80003ec2:	e4ce                	sd	s3,72(sp)
    80003ec4:	e0d2                	sd	s4,64(sp)
    80003ec6:	fc56                	sd	s5,56(sp)
    80003ec8:	f85a                	sd	s6,48(sp)
    80003eca:	f45e                	sd	s7,40(sp)
    80003ecc:	f062                	sd	s8,32(sp)
    80003ece:	ec66                	sd	s9,24(sp)
    80003ed0:	e86a                	sd	s10,16(sp)
    80003ed2:	e46e                	sd	s11,8(sp)
    80003ed4:	1880                	addi	s0,sp,112
    80003ed6:	8baa                	mv	s7,a0
    80003ed8:	8c2e                	mv	s8,a1
    80003eda:	8ab2                	mv	s5,a2
    80003edc:	8936                	mv	s2,a3
    80003ede:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ee0:	00e687bb          	addw	a5,a3,a4
    80003ee4:	0ed7e163          	bltu	a5,a3,80003fc6 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ee8:	00043737          	lui	a4,0x43
    80003eec:	0cf76f63          	bltu	a4,a5,80003fca <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ef0:	0a0b0863          	beqz	s6,80003fa0 <writei+0xee>
    80003ef4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ef6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003efa:	5cfd                	li	s9,-1
    80003efc:	a091                	j	80003f40 <writei+0x8e>
    80003efe:	02099d93          	slli	s11,s3,0x20
    80003f02:	020ddd93          	srli	s11,s11,0x20
    80003f06:	06048513          	addi	a0,s1,96
    80003f0a:	86ee                	mv	a3,s11
    80003f0c:	8656                	mv	a2,s5
    80003f0e:	85e2                	mv	a1,s8
    80003f10:	953a                	add	a0,a0,a4
    80003f12:	fffff097          	auipc	ra,0xfffff
    80003f16:	8de080e7          	jalr	-1826(ra) # 800027f0 <either_copyin>
    80003f1a:	07950263          	beq	a0,s9,80003f7e <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003f1e:	8526                	mv	a0,s1
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	796080e7          	jalr	1942(ra) # 800046b6 <log_write>
    brelse(bp);
    80003f28:	8526                	mv	a0,s1
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	4c6080e7          	jalr	1222(ra) # 800033f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f32:	01498a3b          	addw	s4,s3,s4
    80003f36:	0129893b          	addw	s2,s3,s2
    80003f3a:	9aee                	add	s5,s5,s11
    80003f3c:	056a7763          	bgeu	s4,s6,80003f8a <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f40:	000ba483          	lw	s1,0(s7)
    80003f44:	00a9559b          	srliw	a1,s2,0xa
    80003f48:	855e                	mv	a0,s7
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	7aa080e7          	jalr	1962(ra) # 800036f4 <bmap>
    80003f52:	0005059b          	sext.w	a1,a0
    80003f56:	8526                	mv	a0,s1
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	262080e7          	jalr	610(ra) # 800031ba <bread>
    80003f60:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f62:	3ff97713          	andi	a4,s2,1023
    80003f66:	40ed07bb          	subw	a5,s10,a4
    80003f6a:	414b06bb          	subw	a3,s6,s4
    80003f6e:	89be                	mv	s3,a5
    80003f70:	2781                	sext.w	a5,a5
    80003f72:	0006861b          	sext.w	a2,a3
    80003f76:	f8f674e3          	bgeu	a2,a5,80003efe <writei+0x4c>
    80003f7a:	89b6                	mv	s3,a3
    80003f7c:	b749                	j	80003efe <writei+0x4c>
      brelse(bp);
    80003f7e:	8526                	mv	a0,s1
    80003f80:	fffff097          	auipc	ra,0xfffff
    80003f84:	470080e7          	jalr	1136(ra) # 800033f0 <brelse>
      n = -1;
    80003f88:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003f8a:	054ba783          	lw	a5,84(s7)
    80003f8e:	0127f463          	bgeu	a5,s2,80003f96 <writei+0xe4>
      ip->size = off;
    80003f92:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003f96:	855e                	mv	a0,s7
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	aa2080e7          	jalr	-1374(ra) # 80003a3a <iupdate>
  }

  return n;
    80003fa0:	000b051b          	sext.w	a0,s6
}
    80003fa4:	70a6                	ld	ra,104(sp)
    80003fa6:	7406                	ld	s0,96(sp)
    80003fa8:	64e6                	ld	s1,88(sp)
    80003faa:	6946                	ld	s2,80(sp)
    80003fac:	69a6                	ld	s3,72(sp)
    80003fae:	6a06                	ld	s4,64(sp)
    80003fb0:	7ae2                	ld	s5,56(sp)
    80003fb2:	7b42                	ld	s6,48(sp)
    80003fb4:	7ba2                	ld	s7,40(sp)
    80003fb6:	7c02                	ld	s8,32(sp)
    80003fb8:	6ce2                	ld	s9,24(sp)
    80003fba:	6d42                	ld	s10,16(sp)
    80003fbc:	6da2                	ld	s11,8(sp)
    80003fbe:	6165                	addi	sp,sp,112
    80003fc0:	8082                	ret
    return -1;
    80003fc2:	557d                	li	a0,-1
}
    80003fc4:	8082                	ret
    return -1;
    80003fc6:	557d                	li	a0,-1
    80003fc8:	bff1                	j	80003fa4 <writei+0xf2>
    return -1;
    80003fca:	557d                	li	a0,-1
    80003fcc:	bfe1                	j	80003fa4 <writei+0xf2>

0000000080003fce <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fce:	1141                	addi	sp,sp,-16
    80003fd0:	e406                	sd	ra,8(sp)
    80003fd2:	e022                	sd	s0,0(sp)
    80003fd4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fd6:	4639                	li	a2,14
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	1c2080e7          	jalr	450(ra) # 8000119a <strncmp>
}
    80003fe0:	60a2                	ld	ra,8(sp)
    80003fe2:	6402                	ld	s0,0(sp)
    80003fe4:	0141                	addi	sp,sp,16
    80003fe6:	8082                	ret

0000000080003fe8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fe8:	7139                	addi	sp,sp,-64
    80003fea:	fc06                	sd	ra,56(sp)
    80003fec:	f822                	sd	s0,48(sp)
    80003fee:	f426                	sd	s1,40(sp)
    80003ff0:	f04a                	sd	s2,32(sp)
    80003ff2:	ec4e                	sd	s3,24(sp)
    80003ff4:	e852                	sd	s4,16(sp)
    80003ff6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ff8:	04c51703          	lh	a4,76(a0)
    80003ffc:	4785                	li	a5,1
    80003ffe:	00f71a63          	bne	a4,a5,80004012 <dirlookup+0x2a>
    80004002:	892a                	mv	s2,a0
    80004004:	89ae                	mv	s3,a1
    80004006:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004008:	497c                	lw	a5,84(a0)
    8000400a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000400c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000400e:	e79d                	bnez	a5,8000403c <dirlookup+0x54>
    80004010:	a8a5                	j	80004088 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004012:	00004517          	auipc	a0,0x4
    80004016:	63e50513          	addi	a0,a0,1598 # 80008650 <syscalls+0x198>
    8000401a:	ffffc097          	auipc	ra,0xffffc
    8000401e:	532080e7          	jalr	1330(ra) # 8000054c <panic>
      panic("dirlookup read");
    80004022:	00004517          	auipc	a0,0x4
    80004026:	64650513          	addi	a0,a0,1606 # 80008668 <syscalls+0x1b0>
    8000402a:	ffffc097          	auipc	ra,0xffffc
    8000402e:	522080e7          	jalr	1314(ra) # 8000054c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004032:	24c1                	addiw	s1,s1,16
    80004034:	05492783          	lw	a5,84(s2)
    80004038:	04f4f763          	bgeu	s1,a5,80004086 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000403c:	4741                	li	a4,16
    8000403e:	86a6                	mv	a3,s1
    80004040:	fc040613          	addi	a2,s0,-64
    80004044:	4581                	li	a1,0
    80004046:	854a                	mv	a0,s2
    80004048:	00000097          	auipc	ra,0x0
    8000404c:	d72080e7          	jalr	-654(ra) # 80003dba <readi>
    80004050:	47c1                	li	a5,16
    80004052:	fcf518e3          	bne	a0,a5,80004022 <dirlookup+0x3a>
    if(de.inum == 0)
    80004056:	fc045783          	lhu	a5,-64(s0)
    8000405a:	dfe1                	beqz	a5,80004032 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000405c:	fc240593          	addi	a1,s0,-62
    80004060:	854e                	mv	a0,s3
    80004062:	00000097          	auipc	ra,0x0
    80004066:	f6c080e7          	jalr	-148(ra) # 80003fce <namecmp>
    8000406a:	f561                	bnez	a0,80004032 <dirlookup+0x4a>
      if(poff)
    8000406c:	000a0463          	beqz	s4,80004074 <dirlookup+0x8c>
        *poff = off;
    80004070:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004074:	fc045583          	lhu	a1,-64(s0)
    80004078:	00092503          	lw	a0,0(s2)
    8000407c:	fffff097          	auipc	ra,0xfffff
    80004080:	754080e7          	jalr	1876(ra) # 800037d0 <iget>
    80004084:	a011                	j	80004088 <dirlookup+0xa0>
  return 0;
    80004086:	4501                	li	a0,0
}
    80004088:	70e2                	ld	ra,56(sp)
    8000408a:	7442                	ld	s0,48(sp)
    8000408c:	74a2                	ld	s1,40(sp)
    8000408e:	7902                	ld	s2,32(sp)
    80004090:	69e2                	ld	s3,24(sp)
    80004092:	6a42                	ld	s4,16(sp)
    80004094:	6121                	addi	sp,sp,64
    80004096:	8082                	ret

0000000080004098 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004098:	711d                	addi	sp,sp,-96
    8000409a:	ec86                	sd	ra,88(sp)
    8000409c:	e8a2                	sd	s0,80(sp)
    8000409e:	e4a6                	sd	s1,72(sp)
    800040a0:	e0ca                	sd	s2,64(sp)
    800040a2:	fc4e                	sd	s3,56(sp)
    800040a4:	f852                	sd	s4,48(sp)
    800040a6:	f456                	sd	s5,40(sp)
    800040a8:	f05a                	sd	s6,32(sp)
    800040aa:	ec5e                	sd	s7,24(sp)
    800040ac:	e862                	sd	s8,16(sp)
    800040ae:	e466                	sd	s9,8(sp)
    800040b0:	e06a                	sd	s10,0(sp)
    800040b2:	1080                	addi	s0,sp,96
    800040b4:	84aa                	mv	s1,a0
    800040b6:	8b2e                	mv	s6,a1
    800040b8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040ba:	00054703          	lbu	a4,0(a0)
    800040be:	02f00793          	li	a5,47
    800040c2:	02f70363          	beq	a4,a5,800040e8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040c6:	ffffe097          	auipc	ra,0xffffe
    800040ca:	c62080e7          	jalr	-926(ra) # 80001d28 <myproc>
    800040ce:	15853503          	ld	a0,344(a0)
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	9f6080e7          	jalr	-1546(ra) # 80003ac8 <idup>
    800040da:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040dc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040e0:	4cb5                	li	s9,13
  len = path - s;
    800040e2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040e4:	4c05                	li	s8,1
    800040e6:	a87d                	j	800041a4 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040e8:	4585                	li	a1,1
    800040ea:	4505                	li	a0,1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	6e4080e7          	jalr	1764(ra) # 800037d0 <iget>
    800040f4:	8a2a                	mv	s4,a0
    800040f6:	b7dd                	j	800040dc <namex+0x44>
      iunlockput(ip);
    800040f8:	8552                	mv	a0,s4
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	c6e080e7          	jalr	-914(ra) # 80003d68 <iunlockput>
      return 0;
    80004102:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004104:	8552                	mv	a0,s4
    80004106:	60e6                	ld	ra,88(sp)
    80004108:	6446                	ld	s0,80(sp)
    8000410a:	64a6                	ld	s1,72(sp)
    8000410c:	6906                	ld	s2,64(sp)
    8000410e:	79e2                	ld	s3,56(sp)
    80004110:	7a42                	ld	s4,48(sp)
    80004112:	7aa2                	ld	s5,40(sp)
    80004114:	7b02                	ld	s6,32(sp)
    80004116:	6be2                	ld	s7,24(sp)
    80004118:	6c42                	ld	s8,16(sp)
    8000411a:	6ca2                	ld	s9,8(sp)
    8000411c:	6d02                	ld	s10,0(sp)
    8000411e:	6125                	addi	sp,sp,96
    80004120:	8082                	ret
      iunlock(ip);
    80004122:	8552                	mv	a0,s4
    80004124:	00000097          	auipc	ra,0x0
    80004128:	aa4080e7          	jalr	-1372(ra) # 80003bc8 <iunlock>
      return ip;
    8000412c:	bfe1                	j	80004104 <namex+0x6c>
      iunlockput(ip);
    8000412e:	8552                	mv	a0,s4
    80004130:	00000097          	auipc	ra,0x0
    80004134:	c38080e7          	jalr	-968(ra) # 80003d68 <iunlockput>
      return 0;
    80004138:	8a4e                	mv	s4,s3
    8000413a:	b7e9                	j	80004104 <namex+0x6c>
  len = path - s;
    8000413c:	40998633          	sub	a2,s3,s1
    80004140:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004144:	09acd863          	bge	s9,s10,800041d4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004148:	4639                	li	a2,14
    8000414a:	85a6                	mv	a1,s1
    8000414c:	8556                	mv	a0,s5
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	fd0080e7          	jalr	-48(ra) # 8000111e <memmove>
    80004156:	84ce                	mv	s1,s3
  while(*path == '/')
    80004158:	0004c783          	lbu	a5,0(s1)
    8000415c:	01279763          	bne	a5,s2,8000416a <namex+0xd2>
    path++;
    80004160:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004162:	0004c783          	lbu	a5,0(s1)
    80004166:	ff278de3          	beq	a5,s2,80004160 <namex+0xc8>
    ilock(ip);
    8000416a:	8552                	mv	a0,s4
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	99a080e7          	jalr	-1638(ra) # 80003b06 <ilock>
    if(ip->type != T_DIR){
    80004174:	04ca1783          	lh	a5,76(s4)
    80004178:	f98790e3          	bne	a5,s8,800040f8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000417c:	000b0563          	beqz	s6,80004186 <namex+0xee>
    80004180:	0004c783          	lbu	a5,0(s1)
    80004184:	dfd9                	beqz	a5,80004122 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004186:	865e                	mv	a2,s7
    80004188:	85d6                	mv	a1,s5
    8000418a:	8552                	mv	a0,s4
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	e5c080e7          	jalr	-420(ra) # 80003fe8 <dirlookup>
    80004194:	89aa                	mv	s3,a0
    80004196:	dd41                	beqz	a0,8000412e <namex+0x96>
    iunlockput(ip);
    80004198:	8552                	mv	a0,s4
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	bce080e7          	jalr	-1074(ra) # 80003d68 <iunlockput>
    ip = next;
    800041a2:	8a4e                	mv	s4,s3
  while(*path == '/')
    800041a4:	0004c783          	lbu	a5,0(s1)
    800041a8:	01279763          	bne	a5,s2,800041b6 <namex+0x11e>
    path++;
    800041ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041ae:	0004c783          	lbu	a5,0(s1)
    800041b2:	ff278de3          	beq	a5,s2,800041ac <namex+0x114>
  if(*path == 0)
    800041b6:	cb9d                	beqz	a5,800041ec <namex+0x154>
  while(*path != '/' && *path != 0)
    800041b8:	0004c783          	lbu	a5,0(s1)
    800041bc:	89a6                	mv	s3,s1
  len = path - s;
    800041be:	8d5e                	mv	s10,s7
    800041c0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041c2:	01278963          	beq	a5,s2,800041d4 <namex+0x13c>
    800041c6:	dbbd                	beqz	a5,8000413c <namex+0xa4>
    path++;
    800041c8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ca:	0009c783          	lbu	a5,0(s3)
    800041ce:	ff279ce3          	bne	a5,s2,800041c6 <namex+0x12e>
    800041d2:	b7ad                	j	8000413c <namex+0xa4>
    memmove(name, s, len);
    800041d4:	2601                	sext.w	a2,a2
    800041d6:	85a6                	mv	a1,s1
    800041d8:	8556                	mv	a0,s5
    800041da:	ffffd097          	auipc	ra,0xffffd
    800041de:	f44080e7          	jalr	-188(ra) # 8000111e <memmove>
    name[len] = 0;
    800041e2:	9d56                	add	s10,s10,s5
    800041e4:	000d0023          	sb	zero,0(s10) # 8000 <_entry-0x7fff8000>
    800041e8:	84ce                	mv	s1,s3
    800041ea:	b7bd                	j	80004158 <namex+0xc0>
  if(nameiparent){
    800041ec:	f00b0ce3          	beqz	s6,80004104 <namex+0x6c>
    iput(ip);
    800041f0:	8552                	mv	a0,s4
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	ace080e7          	jalr	-1330(ra) # 80003cc0 <iput>
    return 0;
    800041fa:	4a01                	li	s4,0
    800041fc:	b721                	j	80004104 <namex+0x6c>

00000000800041fe <dirlink>:
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	0080                	addi	s0,sp,64
    8000420e:	892a                	mv	s2,a0
    80004210:	8a2e                	mv	s4,a1
    80004212:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004214:	4601                	li	a2,0
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	dd2080e7          	jalr	-558(ra) # 80003fe8 <dirlookup>
    8000421e:	e93d                	bnez	a0,80004294 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004220:	05492483          	lw	s1,84(s2)
    80004224:	c49d                	beqz	s1,80004252 <dirlink+0x54>
    80004226:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004228:	4741                	li	a4,16
    8000422a:	86a6                	mv	a3,s1
    8000422c:	fc040613          	addi	a2,s0,-64
    80004230:	4581                	li	a1,0
    80004232:	854a                	mv	a0,s2
    80004234:	00000097          	auipc	ra,0x0
    80004238:	b86080e7          	jalr	-1146(ra) # 80003dba <readi>
    8000423c:	47c1                	li	a5,16
    8000423e:	06f51163          	bne	a0,a5,800042a0 <dirlink+0xa2>
    if(de.inum == 0)
    80004242:	fc045783          	lhu	a5,-64(s0)
    80004246:	c791                	beqz	a5,80004252 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004248:	24c1                	addiw	s1,s1,16
    8000424a:	05492783          	lw	a5,84(s2)
    8000424e:	fcf4ede3          	bltu	s1,a5,80004228 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004252:	4639                	li	a2,14
    80004254:	85d2                	mv	a1,s4
    80004256:	fc240513          	addi	a0,s0,-62
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	f7c080e7          	jalr	-132(ra) # 800011d6 <strncpy>
  de.inum = inum;
    80004262:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004266:	4741                	li	a4,16
    80004268:	86a6                	mv	a3,s1
    8000426a:	fc040613          	addi	a2,s0,-64
    8000426e:	4581                	li	a1,0
    80004270:	854a                	mv	a0,s2
    80004272:	00000097          	auipc	ra,0x0
    80004276:	c40080e7          	jalr	-960(ra) # 80003eb2 <writei>
    8000427a:	872a                	mv	a4,a0
    8000427c:	47c1                	li	a5,16
  return 0;
    8000427e:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004280:	02f71863          	bne	a4,a5,800042b0 <dirlink+0xb2>
}
    80004284:	70e2                	ld	ra,56(sp)
    80004286:	7442                	ld	s0,48(sp)
    80004288:	74a2                	ld	s1,40(sp)
    8000428a:	7902                	ld	s2,32(sp)
    8000428c:	69e2                	ld	s3,24(sp)
    8000428e:	6a42                	ld	s4,16(sp)
    80004290:	6121                	addi	sp,sp,64
    80004292:	8082                	ret
    iput(ip);
    80004294:	00000097          	auipc	ra,0x0
    80004298:	a2c080e7          	jalr	-1492(ra) # 80003cc0 <iput>
    return -1;
    8000429c:	557d                	li	a0,-1
    8000429e:	b7dd                	j	80004284 <dirlink+0x86>
      panic("dirlink read");
    800042a0:	00004517          	auipc	a0,0x4
    800042a4:	3d850513          	addi	a0,a0,984 # 80008678 <syscalls+0x1c0>
    800042a8:	ffffc097          	auipc	ra,0xffffc
    800042ac:	2a4080e7          	jalr	676(ra) # 8000054c <panic>
    panic("dirlink");
    800042b0:	00004517          	auipc	a0,0x4
    800042b4:	4e850513          	addi	a0,a0,1256 # 80008798 <syscalls+0x2e0>
    800042b8:	ffffc097          	auipc	ra,0xffffc
    800042bc:	294080e7          	jalr	660(ra) # 8000054c <panic>

00000000800042c0 <namei>:

struct inode*
namei(char *path)
{
    800042c0:	1101                	addi	sp,sp,-32
    800042c2:	ec06                	sd	ra,24(sp)
    800042c4:	e822                	sd	s0,16(sp)
    800042c6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042c8:	fe040613          	addi	a2,s0,-32
    800042cc:	4581                	li	a1,0
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	dca080e7          	jalr	-566(ra) # 80004098 <namex>
}
    800042d6:	60e2                	ld	ra,24(sp)
    800042d8:	6442                	ld	s0,16(sp)
    800042da:	6105                	addi	sp,sp,32
    800042dc:	8082                	ret

00000000800042de <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042de:	1141                	addi	sp,sp,-16
    800042e0:	e406                	sd	ra,8(sp)
    800042e2:	e022                	sd	s0,0(sp)
    800042e4:	0800                	addi	s0,sp,16
    800042e6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042e8:	4585                	li	a1,1
    800042ea:	00000097          	auipc	ra,0x0
    800042ee:	dae080e7          	jalr	-594(ra) # 80004098 <namex>
}
    800042f2:	60a2                	ld	ra,8(sp)
    800042f4:	6402                	ld	s0,0(sp)
    800042f6:	0141                	addi	sp,sp,16
    800042f8:	8082                	ret

00000000800042fa <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042fa:	1101                	addi	sp,sp,-32
    800042fc:	ec06                	sd	ra,24(sp)
    800042fe:	e822                	sd	s0,16(sp)
    80004300:	e426                	sd	s1,8(sp)
    80004302:	e04a                	sd	s2,0(sp)
    80004304:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004306:	00023917          	auipc	s2,0x23
    8000430a:	ce290913          	addi	s2,s2,-798 # 80026fe8 <log>
    8000430e:	02092583          	lw	a1,32(s2)
    80004312:	03092503          	lw	a0,48(s2)
    80004316:	fffff097          	auipc	ra,0xfffff
    8000431a:	ea4080e7          	jalr	-348(ra) # 800031ba <bread>
    8000431e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004320:	03492683          	lw	a3,52(s2)
    80004324:	d134                	sw	a3,96(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004326:	02d05863          	blez	a3,80004356 <write_head+0x5c>
    8000432a:	00023797          	auipc	a5,0x23
    8000432e:	cf678793          	addi	a5,a5,-778 # 80027020 <log+0x38>
    80004332:	06450713          	addi	a4,a0,100
    80004336:	36fd                	addiw	a3,a3,-1
    80004338:	02069613          	slli	a2,a3,0x20
    8000433c:	01e65693          	srli	a3,a2,0x1e
    80004340:	00023617          	auipc	a2,0x23
    80004344:	ce460613          	addi	a2,a2,-796 # 80027024 <log+0x3c>
    80004348:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000434a:	4390                	lw	a2,0(a5)
    8000434c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000434e:	0791                	addi	a5,a5,4
    80004350:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004352:	fed79ce3          	bne	a5,a3,8000434a <write_head+0x50>
  }
  bwrite(buf);
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	05a080e7          	jalr	90(ra) # 800033b2 <bwrite>
  brelse(buf);
    80004360:	8526                	mv	a0,s1
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	08e080e7          	jalr	142(ra) # 800033f0 <brelse>
}
    8000436a:	60e2                	ld	ra,24(sp)
    8000436c:	6442                	ld	s0,16(sp)
    8000436e:	64a2                	ld	s1,8(sp)
    80004370:	6902                	ld	s2,0(sp)
    80004372:	6105                	addi	sp,sp,32
    80004374:	8082                	ret

0000000080004376 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004376:	00023797          	auipc	a5,0x23
    8000437a:	ca67a783          	lw	a5,-858(a5) # 8002701c <log+0x34>
    8000437e:	0af05d63          	blez	a5,80004438 <install_trans+0xc2>
{
    80004382:	7139                	addi	sp,sp,-64
    80004384:	fc06                	sd	ra,56(sp)
    80004386:	f822                	sd	s0,48(sp)
    80004388:	f426                	sd	s1,40(sp)
    8000438a:	f04a                	sd	s2,32(sp)
    8000438c:	ec4e                	sd	s3,24(sp)
    8000438e:	e852                	sd	s4,16(sp)
    80004390:	e456                	sd	s5,8(sp)
    80004392:	e05a                	sd	s6,0(sp)
    80004394:	0080                	addi	s0,sp,64
    80004396:	8b2a                	mv	s6,a0
    80004398:	00023a97          	auipc	s5,0x23
    8000439c:	c88a8a93          	addi	s5,s5,-888 # 80027020 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043a2:	00023997          	auipc	s3,0x23
    800043a6:	c4698993          	addi	s3,s3,-954 # 80026fe8 <log>
    800043aa:	a00d                	j	800043cc <install_trans+0x56>
    brelse(lbuf);
    800043ac:	854a                	mv	a0,s2
    800043ae:	fffff097          	auipc	ra,0xfffff
    800043b2:	042080e7          	jalr	66(ra) # 800033f0 <brelse>
    brelse(dbuf);
    800043b6:	8526                	mv	a0,s1
    800043b8:	fffff097          	auipc	ra,0xfffff
    800043bc:	038080e7          	jalr	56(ra) # 800033f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043c0:	2a05                	addiw	s4,s4,1
    800043c2:	0a91                	addi	s5,s5,4
    800043c4:	0349a783          	lw	a5,52(s3)
    800043c8:	04fa5e63          	bge	s4,a5,80004424 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043cc:	0209a583          	lw	a1,32(s3)
    800043d0:	014585bb          	addw	a1,a1,s4
    800043d4:	2585                	addiw	a1,a1,1
    800043d6:	0309a503          	lw	a0,48(s3)
    800043da:	fffff097          	auipc	ra,0xfffff
    800043de:	de0080e7          	jalr	-544(ra) # 800031ba <bread>
    800043e2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043e4:	000aa583          	lw	a1,0(s5)
    800043e8:	0309a503          	lw	a0,48(s3)
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	dce080e7          	jalr	-562(ra) # 800031ba <bread>
    800043f4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043f6:	40000613          	li	a2,1024
    800043fa:	06090593          	addi	a1,s2,96
    800043fe:	06050513          	addi	a0,a0,96
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	d1c080e7          	jalr	-740(ra) # 8000111e <memmove>
    bwrite(dbuf);  // write dst to disk
    8000440a:	8526                	mv	a0,s1
    8000440c:	fffff097          	auipc	ra,0xfffff
    80004410:	fa6080e7          	jalr	-90(ra) # 800033b2 <bwrite>
    if(recovering == 0)
    80004414:	f80b1ce3          	bnez	s6,800043ac <install_trans+0x36>
      bunpin(dbuf);
    80004418:	8526                	mv	a0,s1
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	0e4080e7          	jalr	228(ra) # 800034fe <bunpin>
    80004422:	b769                	j	800043ac <install_trans+0x36>
}
    80004424:	70e2                	ld	ra,56(sp)
    80004426:	7442                	ld	s0,48(sp)
    80004428:	74a2                	ld	s1,40(sp)
    8000442a:	7902                	ld	s2,32(sp)
    8000442c:	69e2                	ld	s3,24(sp)
    8000442e:	6a42                	ld	s4,16(sp)
    80004430:	6aa2                	ld	s5,8(sp)
    80004432:	6b02                	ld	s6,0(sp)
    80004434:	6121                	addi	sp,sp,64
    80004436:	8082                	ret
    80004438:	8082                	ret

000000008000443a <initlog>:
{
    8000443a:	7179                	addi	sp,sp,-48
    8000443c:	f406                	sd	ra,40(sp)
    8000443e:	f022                	sd	s0,32(sp)
    80004440:	ec26                	sd	s1,24(sp)
    80004442:	e84a                	sd	s2,16(sp)
    80004444:	e44e                	sd	s3,8(sp)
    80004446:	1800                	addi	s0,sp,48
    80004448:	892a                	mv	s2,a0
    8000444a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000444c:	00023497          	auipc	s1,0x23
    80004450:	b9c48493          	addi	s1,s1,-1124 # 80026fe8 <log>
    80004454:	00004597          	auipc	a1,0x4
    80004458:	23458593          	addi	a1,a1,564 # 80008688 <syscalls+0x1d0>
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	a00080e7          	jalr	-1536(ra) # 80000e5e <initlock>
  log.start = sb->logstart;
    80004466:	0149a583          	lw	a1,20(s3)
    8000446a:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    8000446c:	0109a783          	lw	a5,16(s3)
    80004470:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    80004472:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004476:	854a                	mv	a0,s2
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	d42080e7          	jalr	-702(ra) # 800031ba <bread>
  log.lh.n = lh->n;
    80004480:	5134                	lw	a3,96(a0)
    80004482:	d8d4                	sw	a3,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004484:	02d05663          	blez	a3,800044b0 <initlog+0x76>
    80004488:	06450793          	addi	a5,a0,100
    8000448c:	00023717          	auipc	a4,0x23
    80004490:	b9470713          	addi	a4,a4,-1132 # 80027020 <log+0x38>
    80004494:	36fd                	addiw	a3,a3,-1
    80004496:	02069613          	slli	a2,a3,0x20
    8000449a:	01e65693          	srli	a3,a2,0x1e
    8000449e:	06850613          	addi	a2,a0,104
    800044a2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800044a4:	4390                	lw	a2,0(a5)
    800044a6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800044a8:	0791                	addi	a5,a5,4
    800044aa:	0711                	addi	a4,a4,4
    800044ac:	fed79ce3          	bne	a5,a3,800044a4 <initlog+0x6a>
  brelse(buf);
    800044b0:	fffff097          	auipc	ra,0xfffff
    800044b4:	f40080e7          	jalr	-192(ra) # 800033f0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800044b8:	4505                	li	a0,1
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	ebc080e7          	jalr	-324(ra) # 80004376 <install_trans>
  log.lh.n = 0;
    800044c2:	00023797          	auipc	a5,0x23
    800044c6:	b407ad23          	sw	zero,-1190(a5) # 8002701c <log+0x34>
  write_head(); // clear the log
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	e30080e7          	jalr	-464(ra) # 800042fa <write_head>
}
    800044d2:	70a2                	ld	ra,40(sp)
    800044d4:	7402                	ld	s0,32(sp)
    800044d6:	64e2                	ld	s1,24(sp)
    800044d8:	6942                	ld	s2,16(sp)
    800044da:	69a2                	ld	s3,8(sp)
    800044dc:	6145                	addi	sp,sp,48
    800044de:	8082                	ret

00000000800044e0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044e0:	1101                	addi	sp,sp,-32
    800044e2:	ec06                	sd	ra,24(sp)
    800044e4:	e822                	sd	s0,16(sp)
    800044e6:	e426                	sd	s1,8(sp)
    800044e8:	e04a                	sd	s2,0(sp)
    800044ea:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044ec:	00023517          	auipc	a0,0x23
    800044f0:	afc50513          	addi	a0,a0,-1284 # 80026fe8 <log>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	7ee080e7          	jalr	2030(ra) # 80000ce2 <acquire>
  while(1){
    if(log.committing){
    800044fc:	00023497          	auipc	s1,0x23
    80004500:	aec48493          	addi	s1,s1,-1300 # 80026fe8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004504:	4979                	li	s2,30
    80004506:	a039                	j	80004514 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004508:	85a6                	mv	a1,s1
    8000450a:	8526                	mv	a0,s1
    8000450c:	ffffe097          	auipc	ra,0xffffe
    80004510:	034080e7          	jalr	52(ra) # 80002540 <sleep>
    if(log.committing){
    80004514:	54dc                	lw	a5,44(s1)
    80004516:	fbed                	bnez	a5,80004508 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004518:	5498                	lw	a4,40(s1)
    8000451a:	2705                	addiw	a4,a4,1
    8000451c:	0007069b          	sext.w	a3,a4
    80004520:	0027179b          	slliw	a5,a4,0x2
    80004524:	9fb9                	addw	a5,a5,a4
    80004526:	0017979b          	slliw	a5,a5,0x1
    8000452a:	58d8                	lw	a4,52(s1)
    8000452c:	9fb9                	addw	a5,a5,a4
    8000452e:	00f95963          	bge	s2,a5,80004540 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004532:	85a6                	mv	a1,s1
    80004534:	8526                	mv	a0,s1
    80004536:	ffffe097          	auipc	ra,0xffffe
    8000453a:	00a080e7          	jalr	10(ra) # 80002540 <sleep>
    8000453e:	bfd9                	j	80004514 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004540:	00023517          	auipc	a0,0x23
    80004544:	aa850513          	addi	a0,a0,-1368 # 80026fe8 <log>
    80004548:	d514                	sw	a3,40(a0)
      release(&log.lock);
    8000454a:	ffffd097          	auipc	ra,0xffffd
    8000454e:	868080e7          	jalr	-1944(ra) # 80000db2 <release>
      break;
    }
  }
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000455e:	7139                	addi	sp,sp,-64
    80004560:	fc06                	sd	ra,56(sp)
    80004562:	f822                	sd	s0,48(sp)
    80004564:	f426                	sd	s1,40(sp)
    80004566:	f04a                	sd	s2,32(sp)
    80004568:	ec4e                	sd	s3,24(sp)
    8000456a:	e852                	sd	s4,16(sp)
    8000456c:	e456                	sd	s5,8(sp)
    8000456e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004570:	00023497          	auipc	s1,0x23
    80004574:	a7848493          	addi	s1,s1,-1416 # 80026fe8 <log>
    80004578:	8526                	mv	a0,s1
    8000457a:	ffffc097          	auipc	ra,0xffffc
    8000457e:	768080e7          	jalr	1896(ra) # 80000ce2 <acquire>
  log.outstanding -= 1;
    80004582:	549c                	lw	a5,40(s1)
    80004584:	37fd                	addiw	a5,a5,-1
    80004586:	0007891b          	sext.w	s2,a5
    8000458a:	d49c                	sw	a5,40(s1)
  if(log.committing)
    8000458c:	54dc                	lw	a5,44(s1)
    8000458e:	e7b9                	bnez	a5,800045dc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004590:	04091e63          	bnez	s2,800045ec <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004594:	00023497          	auipc	s1,0x23
    80004598:	a5448493          	addi	s1,s1,-1452 # 80026fe8 <log>
    8000459c:	4785                	li	a5,1
    8000459e:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800045a0:	8526                	mv	a0,s1
    800045a2:	ffffd097          	auipc	ra,0xffffd
    800045a6:	810080e7          	jalr	-2032(ra) # 80000db2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800045aa:	58dc                	lw	a5,52(s1)
    800045ac:	06f04763          	bgtz	a5,8000461a <end_op+0xbc>
    acquire(&log.lock);
    800045b0:	00023497          	auipc	s1,0x23
    800045b4:	a3848493          	addi	s1,s1,-1480 # 80026fe8 <log>
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	728080e7          	jalr	1832(ra) # 80000ce2 <acquire>
    log.committing = 0;
    800045c2:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    800045c6:	8526                	mv	a0,s1
    800045c8:	ffffe097          	auipc	ra,0xffffe
    800045cc:	0f8080e7          	jalr	248(ra) # 800026c0 <wakeup>
    release(&log.lock);
    800045d0:	8526                	mv	a0,s1
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	7e0080e7          	jalr	2016(ra) # 80000db2 <release>
}
    800045da:	a03d                	j	80004608 <end_op+0xaa>
    panic("log.committing");
    800045dc:	00004517          	auipc	a0,0x4
    800045e0:	0b450513          	addi	a0,a0,180 # 80008690 <syscalls+0x1d8>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	f68080e7          	jalr	-152(ra) # 8000054c <panic>
    wakeup(&log);
    800045ec:	00023497          	auipc	s1,0x23
    800045f0:	9fc48493          	addi	s1,s1,-1540 # 80026fe8 <log>
    800045f4:	8526                	mv	a0,s1
    800045f6:	ffffe097          	auipc	ra,0xffffe
    800045fa:	0ca080e7          	jalr	202(ra) # 800026c0 <wakeup>
  release(&log.lock);
    800045fe:	8526                	mv	a0,s1
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	7b2080e7          	jalr	1970(ra) # 80000db2 <release>
}
    80004608:	70e2                	ld	ra,56(sp)
    8000460a:	7442                	ld	s0,48(sp)
    8000460c:	74a2                	ld	s1,40(sp)
    8000460e:	7902                	ld	s2,32(sp)
    80004610:	69e2                	ld	s3,24(sp)
    80004612:	6a42                	ld	s4,16(sp)
    80004614:	6aa2                	ld	s5,8(sp)
    80004616:	6121                	addi	sp,sp,64
    80004618:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000461a:	00023a97          	auipc	s5,0x23
    8000461e:	a06a8a93          	addi	s5,s5,-1530 # 80027020 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004622:	00023a17          	auipc	s4,0x23
    80004626:	9c6a0a13          	addi	s4,s4,-1594 # 80026fe8 <log>
    8000462a:	020a2583          	lw	a1,32(s4)
    8000462e:	012585bb          	addw	a1,a1,s2
    80004632:	2585                	addiw	a1,a1,1
    80004634:	030a2503          	lw	a0,48(s4)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	b82080e7          	jalr	-1150(ra) # 800031ba <bread>
    80004640:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004642:	000aa583          	lw	a1,0(s5)
    80004646:	030a2503          	lw	a0,48(s4)
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	b70080e7          	jalr	-1168(ra) # 800031ba <bread>
    80004652:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004654:	40000613          	li	a2,1024
    80004658:	06050593          	addi	a1,a0,96
    8000465c:	06048513          	addi	a0,s1,96
    80004660:	ffffd097          	auipc	ra,0xffffd
    80004664:	abe080e7          	jalr	-1346(ra) # 8000111e <memmove>
    bwrite(to);  // write the log
    80004668:	8526                	mv	a0,s1
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	d48080e7          	jalr	-696(ra) # 800033b2 <bwrite>
    brelse(from);
    80004672:	854e                	mv	a0,s3
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	d7c080e7          	jalr	-644(ra) # 800033f0 <brelse>
    brelse(to);
    8000467c:	8526                	mv	a0,s1
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	d72080e7          	jalr	-654(ra) # 800033f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004686:	2905                	addiw	s2,s2,1
    80004688:	0a91                	addi	s5,s5,4
    8000468a:	034a2783          	lw	a5,52(s4)
    8000468e:	f8f94ee3          	blt	s2,a5,8000462a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004692:	00000097          	auipc	ra,0x0
    80004696:	c68080e7          	jalr	-920(ra) # 800042fa <write_head>
    install_trans(0); // Now install writes to home locations
    8000469a:	4501                	li	a0,0
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	cda080e7          	jalr	-806(ra) # 80004376 <install_trans>
    log.lh.n = 0;
    800046a4:	00023797          	auipc	a5,0x23
    800046a8:	9607ac23          	sw	zero,-1672(a5) # 8002701c <log+0x34>
    write_head();    // Erase the transaction from the log
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	c4e080e7          	jalr	-946(ra) # 800042fa <write_head>
    800046b4:	bdf5                	j	800045b0 <end_op+0x52>

00000000800046b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800046b6:	1101                	addi	sp,sp,-32
    800046b8:	ec06                	sd	ra,24(sp)
    800046ba:	e822                	sd	s0,16(sp)
    800046bc:	e426                	sd	s1,8(sp)
    800046be:	e04a                	sd	s2,0(sp)
    800046c0:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046c2:	00023717          	auipc	a4,0x23
    800046c6:	95a72703          	lw	a4,-1702(a4) # 8002701c <log+0x34>
    800046ca:	47f5                	li	a5,29
    800046cc:	08e7c063          	blt	a5,a4,8000474c <log_write+0x96>
    800046d0:	84aa                	mv	s1,a0
    800046d2:	00023797          	auipc	a5,0x23
    800046d6:	93a7a783          	lw	a5,-1734(a5) # 8002700c <log+0x24>
    800046da:	37fd                	addiw	a5,a5,-1
    800046dc:	06f75863          	bge	a4,a5,8000474c <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046e0:	00023797          	auipc	a5,0x23
    800046e4:	9307a783          	lw	a5,-1744(a5) # 80027010 <log+0x28>
    800046e8:	06f05a63          	blez	a5,8000475c <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800046ec:	00023917          	auipc	s2,0x23
    800046f0:	8fc90913          	addi	s2,s2,-1796 # 80026fe8 <log>
    800046f4:	854a                	mv	a0,s2
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	5ec080e7          	jalr	1516(ra) # 80000ce2 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800046fe:	03492603          	lw	a2,52(s2)
    80004702:	06c05563          	blez	a2,8000476c <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004706:	44cc                	lw	a1,12(s1)
    80004708:	00023717          	auipc	a4,0x23
    8000470c:	91870713          	addi	a4,a4,-1768 # 80027020 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004710:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004712:	4314                	lw	a3,0(a4)
    80004714:	04b68d63          	beq	a3,a1,8000476e <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004718:	2785                	addiw	a5,a5,1
    8000471a:	0711                	addi	a4,a4,4
    8000471c:	fec79be3          	bne	a5,a2,80004712 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004720:	0631                	addi	a2,a2,12
    80004722:	060a                	slli	a2,a2,0x2
    80004724:	00023797          	auipc	a5,0x23
    80004728:	8c478793          	addi	a5,a5,-1852 # 80026fe8 <log>
    8000472c:	97b2                	add	a5,a5,a2
    8000472e:	44d8                	lw	a4,12(s1)
    80004730:	c798                	sw	a4,8(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004732:	8526                	mv	a0,s1
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	d7e080e7          	jalr	-642(ra) # 800034b2 <bpin>
    log.lh.n++;
    8000473c:	00023717          	auipc	a4,0x23
    80004740:	8ac70713          	addi	a4,a4,-1876 # 80026fe8 <log>
    80004744:	5b5c                	lw	a5,52(a4)
    80004746:	2785                	addiw	a5,a5,1
    80004748:	db5c                	sw	a5,52(a4)
    8000474a:	a835                	j	80004786 <log_write+0xd0>
    panic("too big a transaction");
    8000474c:	00004517          	auipc	a0,0x4
    80004750:	f5450513          	addi	a0,a0,-172 # 800086a0 <syscalls+0x1e8>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	df8080e7          	jalr	-520(ra) # 8000054c <panic>
    panic("log_write outside of trans");
    8000475c:	00004517          	auipc	a0,0x4
    80004760:	f5c50513          	addi	a0,a0,-164 # 800086b8 <syscalls+0x200>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	de8080e7          	jalr	-536(ra) # 8000054c <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000476c:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000476e:	00c78693          	addi	a3,a5,12
    80004772:	068a                	slli	a3,a3,0x2
    80004774:	00023717          	auipc	a4,0x23
    80004778:	87470713          	addi	a4,a4,-1932 # 80026fe8 <log>
    8000477c:	9736                	add	a4,a4,a3
    8000477e:	44d4                	lw	a3,12(s1)
    80004780:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004782:	faf608e3          	beq	a2,a5,80004732 <log_write+0x7c>
  }
  release(&log.lock);
    80004786:	00023517          	auipc	a0,0x23
    8000478a:	86250513          	addi	a0,a0,-1950 # 80026fe8 <log>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	624080e7          	jalr	1572(ra) # 80000db2 <release>
}
    80004796:	60e2                	ld	ra,24(sp)
    80004798:	6442                	ld	s0,16(sp)
    8000479a:	64a2                	ld	s1,8(sp)
    8000479c:	6902                	ld	s2,0(sp)
    8000479e:	6105                	addi	sp,sp,32
    800047a0:	8082                	ret

00000000800047a2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800047a2:	1101                	addi	sp,sp,-32
    800047a4:	ec06                	sd	ra,24(sp)
    800047a6:	e822                	sd	s0,16(sp)
    800047a8:	e426                	sd	s1,8(sp)
    800047aa:	e04a                	sd	s2,0(sp)
    800047ac:	1000                	addi	s0,sp,32
    800047ae:	84aa                	mv	s1,a0
    800047b0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800047b2:	00004597          	auipc	a1,0x4
    800047b6:	f2658593          	addi	a1,a1,-218 # 800086d8 <syscalls+0x220>
    800047ba:	0521                	addi	a0,a0,8
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	6a2080e7          	jalr	1698(ra) # 80000e5e <initlock>
  lk->name = name;
    800047c4:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    800047c8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047cc:	0204a823          	sw	zero,48(s1)
}
    800047d0:	60e2                	ld	ra,24(sp)
    800047d2:	6442                	ld	s0,16(sp)
    800047d4:	64a2                	ld	s1,8(sp)
    800047d6:	6902                	ld	s2,0(sp)
    800047d8:	6105                	addi	sp,sp,32
    800047da:	8082                	ret

00000000800047dc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047dc:	1101                	addi	sp,sp,-32
    800047de:	ec06                	sd	ra,24(sp)
    800047e0:	e822                	sd	s0,16(sp)
    800047e2:	e426                	sd	s1,8(sp)
    800047e4:	e04a                	sd	s2,0(sp)
    800047e6:	1000                	addi	s0,sp,32
    800047e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047ea:	00850913          	addi	s2,a0,8
    800047ee:	854a                	mv	a0,s2
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	4f2080e7          	jalr	1266(ra) # 80000ce2 <acquire>
  while (lk->locked) {
    800047f8:	409c                	lw	a5,0(s1)
    800047fa:	cb89                	beqz	a5,8000480c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047fc:	85ca                	mv	a1,s2
    800047fe:	8526                	mv	a0,s1
    80004800:	ffffe097          	auipc	ra,0xffffe
    80004804:	d40080e7          	jalr	-704(ra) # 80002540 <sleep>
  while (lk->locked) {
    80004808:	409c                	lw	a5,0(s1)
    8000480a:	fbed                	bnez	a5,800047fc <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000480c:	4785                	li	a5,1
    8000480e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004810:	ffffd097          	auipc	ra,0xffffd
    80004814:	518080e7          	jalr	1304(ra) # 80001d28 <myproc>
    80004818:	413c                	lw	a5,64(a0)
    8000481a:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    8000481c:	854a                	mv	a0,s2
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	594080e7          	jalr	1428(ra) # 80000db2 <release>
}
    80004826:	60e2                	ld	ra,24(sp)
    80004828:	6442                	ld	s0,16(sp)
    8000482a:	64a2                	ld	s1,8(sp)
    8000482c:	6902                	ld	s2,0(sp)
    8000482e:	6105                	addi	sp,sp,32
    80004830:	8082                	ret

0000000080004832 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004832:	1101                	addi	sp,sp,-32
    80004834:	ec06                	sd	ra,24(sp)
    80004836:	e822                	sd	s0,16(sp)
    80004838:	e426                	sd	s1,8(sp)
    8000483a:	e04a                	sd	s2,0(sp)
    8000483c:	1000                	addi	s0,sp,32
    8000483e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004840:	00850913          	addi	s2,a0,8
    80004844:	854a                	mv	a0,s2
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	49c080e7          	jalr	1180(ra) # 80000ce2 <acquire>
  lk->locked = 0;
    8000484e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004852:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    80004856:	8526                	mv	a0,s1
    80004858:	ffffe097          	auipc	ra,0xffffe
    8000485c:	e68080e7          	jalr	-408(ra) # 800026c0 <wakeup>
  release(&lk->lk);
    80004860:	854a                	mv	a0,s2
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	550080e7          	jalr	1360(ra) # 80000db2 <release>
}
    8000486a:	60e2                	ld	ra,24(sp)
    8000486c:	6442                	ld	s0,16(sp)
    8000486e:	64a2                	ld	s1,8(sp)
    80004870:	6902                	ld	s2,0(sp)
    80004872:	6105                	addi	sp,sp,32
    80004874:	8082                	ret

0000000080004876 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004876:	7179                	addi	sp,sp,-48
    80004878:	f406                	sd	ra,40(sp)
    8000487a:	f022                	sd	s0,32(sp)
    8000487c:	ec26                	sd	s1,24(sp)
    8000487e:	e84a                	sd	s2,16(sp)
    80004880:	e44e                	sd	s3,8(sp)
    80004882:	1800                	addi	s0,sp,48
    80004884:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004886:	00850913          	addi	s2,a0,8
    8000488a:	854a                	mv	a0,s2
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	456080e7          	jalr	1110(ra) # 80000ce2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004894:	409c                	lw	a5,0(s1)
    80004896:	ef99                	bnez	a5,800048b4 <holdingsleep+0x3e>
    80004898:	4481                	li	s1,0
  release(&lk->lk);
    8000489a:	854a                	mv	a0,s2
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	516080e7          	jalr	1302(ra) # 80000db2 <release>
  return r;
}
    800048a4:	8526                	mv	a0,s1
    800048a6:	70a2                	ld	ra,40(sp)
    800048a8:	7402                	ld	s0,32(sp)
    800048aa:	64e2                	ld	s1,24(sp)
    800048ac:	6942                	ld	s2,16(sp)
    800048ae:	69a2                	ld	s3,8(sp)
    800048b0:	6145                	addi	sp,sp,48
    800048b2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800048b4:	0304a983          	lw	s3,48(s1)
    800048b8:	ffffd097          	auipc	ra,0xffffd
    800048bc:	470080e7          	jalr	1136(ra) # 80001d28 <myproc>
    800048c0:	4124                	lw	s1,64(a0)
    800048c2:	413484b3          	sub	s1,s1,s3
    800048c6:	0014b493          	seqz	s1,s1
    800048ca:	bfc1                	j	8000489a <holdingsleep+0x24>

00000000800048cc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048cc:	1141                	addi	sp,sp,-16
    800048ce:	e406                	sd	ra,8(sp)
    800048d0:	e022                	sd	s0,0(sp)
    800048d2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048d4:	00004597          	auipc	a1,0x4
    800048d8:	e1458593          	addi	a1,a1,-492 # 800086e8 <syscalls+0x230>
    800048dc:	00023517          	auipc	a0,0x23
    800048e0:	85c50513          	addi	a0,a0,-1956 # 80027138 <ftable>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	57a080e7          	jalr	1402(ra) # 80000e5e <initlock>
}
    800048ec:	60a2                	ld	ra,8(sp)
    800048ee:	6402                	ld	s0,0(sp)
    800048f0:	0141                	addi	sp,sp,16
    800048f2:	8082                	ret

00000000800048f4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048f4:	1101                	addi	sp,sp,-32
    800048f6:	ec06                	sd	ra,24(sp)
    800048f8:	e822                	sd	s0,16(sp)
    800048fa:	e426                	sd	s1,8(sp)
    800048fc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048fe:	00023517          	auipc	a0,0x23
    80004902:	83a50513          	addi	a0,a0,-1990 # 80027138 <ftable>
    80004906:	ffffc097          	auipc	ra,0xffffc
    8000490a:	3dc080e7          	jalr	988(ra) # 80000ce2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000490e:	00023497          	auipc	s1,0x23
    80004912:	84a48493          	addi	s1,s1,-1974 # 80027158 <ftable+0x20>
    80004916:	00023717          	auipc	a4,0x23
    8000491a:	7e270713          	addi	a4,a4,2018 # 800280f8 <ftable+0xfc0>
    if(f->ref == 0){
    8000491e:	40dc                	lw	a5,4(s1)
    80004920:	cf99                	beqz	a5,8000493e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004922:	02848493          	addi	s1,s1,40
    80004926:	fee49ce3          	bne	s1,a4,8000491e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000492a:	00023517          	auipc	a0,0x23
    8000492e:	80e50513          	addi	a0,a0,-2034 # 80027138 <ftable>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	480080e7          	jalr	1152(ra) # 80000db2 <release>
  return 0;
    8000493a:	4481                	li	s1,0
    8000493c:	a819                	j	80004952 <filealloc+0x5e>
      f->ref = 1;
    8000493e:	4785                	li	a5,1
    80004940:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004942:	00022517          	auipc	a0,0x22
    80004946:	7f650513          	addi	a0,a0,2038 # 80027138 <ftable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	468080e7          	jalr	1128(ra) # 80000db2 <release>
}
    80004952:	8526                	mv	a0,s1
    80004954:	60e2                	ld	ra,24(sp)
    80004956:	6442                	ld	s0,16(sp)
    80004958:	64a2                	ld	s1,8(sp)
    8000495a:	6105                	addi	sp,sp,32
    8000495c:	8082                	ret

000000008000495e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000495e:	1101                	addi	sp,sp,-32
    80004960:	ec06                	sd	ra,24(sp)
    80004962:	e822                	sd	s0,16(sp)
    80004964:	e426                	sd	s1,8(sp)
    80004966:	1000                	addi	s0,sp,32
    80004968:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000496a:	00022517          	auipc	a0,0x22
    8000496e:	7ce50513          	addi	a0,a0,1998 # 80027138 <ftable>
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	370080e7          	jalr	880(ra) # 80000ce2 <acquire>
  if(f->ref < 1)
    8000497a:	40dc                	lw	a5,4(s1)
    8000497c:	02f05263          	blez	a5,800049a0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004980:	2785                	addiw	a5,a5,1
    80004982:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004984:	00022517          	auipc	a0,0x22
    80004988:	7b450513          	addi	a0,a0,1972 # 80027138 <ftable>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	426080e7          	jalr	1062(ra) # 80000db2 <release>
  return f;
}
    80004994:	8526                	mv	a0,s1
    80004996:	60e2                	ld	ra,24(sp)
    80004998:	6442                	ld	s0,16(sp)
    8000499a:	64a2                	ld	s1,8(sp)
    8000499c:	6105                	addi	sp,sp,32
    8000499e:	8082                	ret
    panic("filedup");
    800049a0:	00004517          	auipc	a0,0x4
    800049a4:	d5050513          	addi	a0,a0,-688 # 800086f0 <syscalls+0x238>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	ba4080e7          	jalr	-1116(ra) # 8000054c <panic>

00000000800049b0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800049b0:	7139                	addi	sp,sp,-64
    800049b2:	fc06                	sd	ra,56(sp)
    800049b4:	f822                	sd	s0,48(sp)
    800049b6:	f426                	sd	s1,40(sp)
    800049b8:	f04a                	sd	s2,32(sp)
    800049ba:	ec4e                	sd	s3,24(sp)
    800049bc:	e852                	sd	s4,16(sp)
    800049be:	e456                	sd	s5,8(sp)
    800049c0:	0080                	addi	s0,sp,64
    800049c2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800049c4:	00022517          	auipc	a0,0x22
    800049c8:	77450513          	addi	a0,a0,1908 # 80027138 <ftable>
    800049cc:	ffffc097          	auipc	ra,0xffffc
    800049d0:	316080e7          	jalr	790(ra) # 80000ce2 <acquire>
  if(f->ref < 1)
    800049d4:	40dc                	lw	a5,4(s1)
    800049d6:	06f05163          	blez	a5,80004a38 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049da:	37fd                	addiw	a5,a5,-1
    800049dc:	0007871b          	sext.w	a4,a5
    800049e0:	c0dc                	sw	a5,4(s1)
    800049e2:	06e04363          	bgtz	a4,80004a48 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049e6:	0004a903          	lw	s2,0(s1)
    800049ea:	0094ca83          	lbu	s5,9(s1)
    800049ee:	0104ba03          	ld	s4,16(s1)
    800049f2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049f6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049fa:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049fe:	00022517          	auipc	a0,0x22
    80004a02:	73a50513          	addi	a0,a0,1850 # 80027138 <ftable>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	3ac080e7          	jalr	940(ra) # 80000db2 <release>

  if(ff.type == FD_PIPE){
    80004a0e:	4785                	li	a5,1
    80004a10:	04f90d63          	beq	s2,a5,80004a6a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a14:	3979                	addiw	s2,s2,-2
    80004a16:	4785                	li	a5,1
    80004a18:	0527e063          	bltu	a5,s2,80004a58 <fileclose+0xa8>
    begin_op();
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	ac4080e7          	jalr	-1340(ra) # 800044e0 <begin_op>
    iput(ff.ip);
    80004a24:	854e                	mv	a0,s3
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	29a080e7          	jalr	666(ra) # 80003cc0 <iput>
    end_op();
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	b30080e7          	jalr	-1232(ra) # 8000455e <end_op>
    80004a36:	a00d                	j	80004a58 <fileclose+0xa8>
    panic("fileclose");
    80004a38:	00004517          	auipc	a0,0x4
    80004a3c:	cc050513          	addi	a0,a0,-832 # 800086f8 <syscalls+0x240>
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	b0c080e7          	jalr	-1268(ra) # 8000054c <panic>
    release(&ftable.lock);
    80004a48:	00022517          	auipc	a0,0x22
    80004a4c:	6f050513          	addi	a0,a0,1776 # 80027138 <ftable>
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	362080e7          	jalr	866(ra) # 80000db2 <release>
  }
}
    80004a58:	70e2                	ld	ra,56(sp)
    80004a5a:	7442                	ld	s0,48(sp)
    80004a5c:	74a2                	ld	s1,40(sp)
    80004a5e:	7902                	ld	s2,32(sp)
    80004a60:	69e2                	ld	s3,24(sp)
    80004a62:	6a42                	ld	s4,16(sp)
    80004a64:	6aa2                	ld	s5,8(sp)
    80004a66:	6121                	addi	sp,sp,64
    80004a68:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a6a:	85d6                	mv	a1,s5
    80004a6c:	8552                	mv	a0,s4
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	372080e7          	jalr	882(ra) # 80004de0 <pipeclose>
    80004a76:	b7cd                	j	80004a58 <fileclose+0xa8>

0000000080004a78 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a78:	715d                	addi	sp,sp,-80
    80004a7a:	e486                	sd	ra,72(sp)
    80004a7c:	e0a2                	sd	s0,64(sp)
    80004a7e:	fc26                	sd	s1,56(sp)
    80004a80:	f84a                	sd	s2,48(sp)
    80004a82:	f44e                	sd	s3,40(sp)
    80004a84:	0880                	addi	s0,sp,80
    80004a86:	84aa                	mv	s1,a0
    80004a88:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a8a:	ffffd097          	auipc	ra,0xffffd
    80004a8e:	29e080e7          	jalr	670(ra) # 80001d28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a92:	409c                	lw	a5,0(s1)
    80004a94:	37f9                	addiw	a5,a5,-2
    80004a96:	4705                	li	a4,1
    80004a98:	04f76763          	bltu	a4,a5,80004ae6 <filestat+0x6e>
    80004a9c:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a9e:	6c88                	ld	a0,24(s1)
    80004aa0:	fffff097          	auipc	ra,0xfffff
    80004aa4:	066080e7          	jalr	102(ra) # 80003b06 <ilock>
    stati(f->ip, &st);
    80004aa8:	fb840593          	addi	a1,s0,-72
    80004aac:	6c88                	ld	a0,24(s1)
    80004aae:	fffff097          	auipc	ra,0xfffff
    80004ab2:	2e2080e7          	jalr	738(ra) # 80003d90 <stati>
    iunlock(f->ip);
    80004ab6:	6c88                	ld	a0,24(s1)
    80004ab8:	fffff097          	auipc	ra,0xfffff
    80004abc:	110080e7          	jalr	272(ra) # 80003bc8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ac0:	46e1                	li	a3,24
    80004ac2:	fb840613          	addi	a2,s0,-72
    80004ac6:	85ce                	mv	a1,s3
    80004ac8:	05893503          	ld	a0,88(s2)
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	f52080e7          	jalr	-174(ra) # 80001a1e <copyout>
    80004ad4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ad8:	60a6                	ld	ra,72(sp)
    80004ada:	6406                	ld	s0,64(sp)
    80004adc:	74e2                	ld	s1,56(sp)
    80004ade:	7942                	ld	s2,48(sp)
    80004ae0:	79a2                	ld	s3,40(sp)
    80004ae2:	6161                	addi	sp,sp,80
    80004ae4:	8082                	ret
  return -1;
    80004ae6:	557d                	li	a0,-1
    80004ae8:	bfc5                	j	80004ad8 <filestat+0x60>

0000000080004aea <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004aea:	7179                	addi	sp,sp,-48
    80004aec:	f406                	sd	ra,40(sp)
    80004aee:	f022                	sd	s0,32(sp)
    80004af0:	ec26                	sd	s1,24(sp)
    80004af2:	e84a                	sd	s2,16(sp)
    80004af4:	e44e                	sd	s3,8(sp)
    80004af6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004af8:	00854783          	lbu	a5,8(a0)
    80004afc:	c3d5                	beqz	a5,80004ba0 <fileread+0xb6>
    80004afe:	84aa                	mv	s1,a0
    80004b00:	89ae                	mv	s3,a1
    80004b02:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b04:	411c                	lw	a5,0(a0)
    80004b06:	4705                	li	a4,1
    80004b08:	04e78963          	beq	a5,a4,80004b5a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b0c:	470d                	li	a4,3
    80004b0e:	04e78d63          	beq	a5,a4,80004b68 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b12:	4709                	li	a4,2
    80004b14:	06e79e63          	bne	a5,a4,80004b90 <fileread+0xa6>
    ilock(f->ip);
    80004b18:	6d08                	ld	a0,24(a0)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	fec080e7          	jalr	-20(ra) # 80003b06 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004b22:	874a                	mv	a4,s2
    80004b24:	5094                	lw	a3,32(s1)
    80004b26:	864e                	mv	a2,s3
    80004b28:	4585                	li	a1,1
    80004b2a:	6c88                	ld	a0,24(s1)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	28e080e7          	jalr	654(ra) # 80003dba <readi>
    80004b34:	892a                	mv	s2,a0
    80004b36:	00a05563          	blez	a0,80004b40 <fileread+0x56>
      f->off += r;
    80004b3a:	509c                	lw	a5,32(s1)
    80004b3c:	9fa9                	addw	a5,a5,a0
    80004b3e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b40:	6c88                	ld	a0,24(s1)
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	086080e7          	jalr	134(ra) # 80003bc8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b4a:	854a                	mv	a0,s2
    80004b4c:	70a2                	ld	ra,40(sp)
    80004b4e:	7402                	ld	s0,32(sp)
    80004b50:	64e2                	ld	s1,24(sp)
    80004b52:	6942                	ld	s2,16(sp)
    80004b54:	69a2                	ld	s3,8(sp)
    80004b56:	6145                	addi	sp,sp,48
    80004b58:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b5a:	6908                	ld	a0,16(a0)
    80004b5c:	00000097          	auipc	ra,0x0
    80004b60:	400080e7          	jalr	1024(ra) # 80004f5c <piperead>
    80004b64:	892a                	mv	s2,a0
    80004b66:	b7d5                	j	80004b4a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b68:	02451783          	lh	a5,36(a0)
    80004b6c:	03079693          	slli	a3,a5,0x30
    80004b70:	92c1                	srli	a3,a3,0x30
    80004b72:	4725                	li	a4,9
    80004b74:	02d76863          	bltu	a4,a3,80004ba4 <fileread+0xba>
    80004b78:	0792                	slli	a5,a5,0x4
    80004b7a:	00022717          	auipc	a4,0x22
    80004b7e:	51e70713          	addi	a4,a4,1310 # 80027098 <devsw>
    80004b82:	97ba                	add	a5,a5,a4
    80004b84:	639c                	ld	a5,0(a5)
    80004b86:	c38d                	beqz	a5,80004ba8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b88:	4505                	li	a0,1
    80004b8a:	9782                	jalr	a5
    80004b8c:	892a                	mv	s2,a0
    80004b8e:	bf75                	j	80004b4a <fileread+0x60>
    panic("fileread");
    80004b90:	00004517          	auipc	a0,0x4
    80004b94:	b7850513          	addi	a0,a0,-1160 # 80008708 <syscalls+0x250>
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	9b4080e7          	jalr	-1612(ra) # 8000054c <panic>
    return -1;
    80004ba0:	597d                	li	s2,-1
    80004ba2:	b765                	j	80004b4a <fileread+0x60>
      return -1;
    80004ba4:	597d                	li	s2,-1
    80004ba6:	b755                	j	80004b4a <fileread+0x60>
    80004ba8:	597d                	li	s2,-1
    80004baa:	b745                	j	80004b4a <fileread+0x60>

0000000080004bac <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004bac:	00954783          	lbu	a5,9(a0)
    80004bb0:	14078563          	beqz	a5,80004cfa <filewrite+0x14e>
{
    80004bb4:	715d                	addi	sp,sp,-80
    80004bb6:	e486                	sd	ra,72(sp)
    80004bb8:	e0a2                	sd	s0,64(sp)
    80004bba:	fc26                	sd	s1,56(sp)
    80004bbc:	f84a                	sd	s2,48(sp)
    80004bbe:	f44e                	sd	s3,40(sp)
    80004bc0:	f052                	sd	s4,32(sp)
    80004bc2:	ec56                	sd	s5,24(sp)
    80004bc4:	e85a                	sd	s6,16(sp)
    80004bc6:	e45e                	sd	s7,8(sp)
    80004bc8:	e062                	sd	s8,0(sp)
    80004bca:	0880                	addi	s0,sp,80
    80004bcc:	892a                	mv	s2,a0
    80004bce:	8b2e                	mv	s6,a1
    80004bd0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004bd2:	411c                	lw	a5,0(a0)
    80004bd4:	4705                	li	a4,1
    80004bd6:	02e78263          	beq	a5,a4,80004bfa <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bda:	470d                	li	a4,3
    80004bdc:	02e78563          	beq	a5,a4,80004c06 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004be0:	4709                	li	a4,2
    80004be2:	10e79463          	bne	a5,a4,80004cea <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004be6:	0ec05e63          	blez	a2,80004ce2 <filewrite+0x136>
    int i = 0;
    80004bea:	4981                	li	s3,0
    80004bec:	6b85                	lui	s7,0x1
    80004bee:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bf2:	6c05                	lui	s8,0x1
    80004bf4:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bf8:	a851                	j	80004c8c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004bfa:	6908                	ld	a0,16(a0)
    80004bfc:	00000097          	auipc	ra,0x0
    80004c00:	25e080e7          	jalr	606(ra) # 80004e5a <pipewrite>
    80004c04:	a85d                	j	80004cba <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c06:	02451783          	lh	a5,36(a0)
    80004c0a:	03079693          	slli	a3,a5,0x30
    80004c0e:	92c1                	srli	a3,a3,0x30
    80004c10:	4725                	li	a4,9
    80004c12:	0ed76663          	bltu	a4,a3,80004cfe <filewrite+0x152>
    80004c16:	0792                	slli	a5,a5,0x4
    80004c18:	00022717          	auipc	a4,0x22
    80004c1c:	48070713          	addi	a4,a4,1152 # 80027098 <devsw>
    80004c20:	97ba                	add	a5,a5,a4
    80004c22:	679c                	ld	a5,8(a5)
    80004c24:	cff9                	beqz	a5,80004d02 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004c26:	4505                	li	a0,1
    80004c28:	9782                	jalr	a5
    80004c2a:	a841                	j	80004cba <filewrite+0x10e>
    80004c2c:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c30:	00000097          	auipc	ra,0x0
    80004c34:	8b0080e7          	jalr	-1872(ra) # 800044e0 <begin_op>
      ilock(f->ip);
    80004c38:	01893503          	ld	a0,24(s2)
    80004c3c:	fffff097          	auipc	ra,0xfffff
    80004c40:	eca080e7          	jalr	-310(ra) # 80003b06 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c44:	8756                	mv	a4,s5
    80004c46:	02092683          	lw	a3,32(s2)
    80004c4a:	01698633          	add	a2,s3,s6
    80004c4e:	4585                	li	a1,1
    80004c50:	01893503          	ld	a0,24(s2)
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	25e080e7          	jalr	606(ra) # 80003eb2 <writei>
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	02a05f63          	blez	a0,80004c9c <filewrite+0xf0>
        f->off += r;
    80004c62:	02092783          	lw	a5,32(s2)
    80004c66:	9fa9                	addw	a5,a5,a0
    80004c68:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c6c:	01893503          	ld	a0,24(s2)
    80004c70:	fffff097          	auipc	ra,0xfffff
    80004c74:	f58080e7          	jalr	-168(ra) # 80003bc8 <iunlock>
      end_op();
    80004c78:	00000097          	auipc	ra,0x0
    80004c7c:	8e6080e7          	jalr	-1818(ra) # 8000455e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004c80:	049a9963          	bne	s5,s1,80004cd2 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004c84:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c88:	0349d663          	bge	s3,s4,80004cb4 <filewrite+0x108>
      int n1 = n - i;
    80004c8c:	413a04bb          	subw	s1,s4,s3
    80004c90:	0004879b          	sext.w	a5,s1
    80004c94:	f8fbdce3          	bge	s7,a5,80004c2c <filewrite+0x80>
    80004c98:	84e2                	mv	s1,s8
    80004c9a:	bf49                	j	80004c2c <filewrite+0x80>
      iunlock(f->ip);
    80004c9c:	01893503          	ld	a0,24(s2)
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	f28080e7          	jalr	-216(ra) # 80003bc8 <iunlock>
      end_op();
    80004ca8:	00000097          	auipc	ra,0x0
    80004cac:	8b6080e7          	jalr	-1866(ra) # 8000455e <end_op>
      if(r < 0)
    80004cb0:	fc04d8e3          	bgez	s1,80004c80 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004cb4:	8552                	mv	a0,s4
    80004cb6:	033a1863          	bne	s4,s3,80004ce6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004cba:	60a6                	ld	ra,72(sp)
    80004cbc:	6406                	ld	s0,64(sp)
    80004cbe:	74e2                	ld	s1,56(sp)
    80004cc0:	7942                	ld	s2,48(sp)
    80004cc2:	79a2                	ld	s3,40(sp)
    80004cc4:	7a02                	ld	s4,32(sp)
    80004cc6:	6ae2                	ld	s5,24(sp)
    80004cc8:	6b42                	ld	s6,16(sp)
    80004cca:	6ba2                	ld	s7,8(sp)
    80004ccc:	6c02                	ld	s8,0(sp)
    80004cce:	6161                	addi	sp,sp,80
    80004cd0:	8082                	ret
        panic("short filewrite");
    80004cd2:	00004517          	auipc	a0,0x4
    80004cd6:	a4650513          	addi	a0,a0,-1466 # 80008718 <syscalls+0x260>
    80004cda:	ffffc097          	auipc	ra,0xffffc
    80004cde:	872080e7          	jalr	-1934(ra) # 8000054c <panic>
    int i = 0;
    80004ce2:	4981                	li	s3,0
    80004ce4:	bfc1                	j	80004cb4 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004ce6:	557d                	li	a0,-1
    80004ce8:	bfc9                	j	80004cba <filewrite+0x10e>
    panic("filewrite");
    80004cea:	00004517          	auipc	a0,0x4
    80004cee:	a3e50513          	addi	a0,a0,-1474 # 80008728 <syscalls+0x270>
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	85a080e7          	jalr	-1958(ra) # 8000054c <panic>
    return -1;
    80004cfa:	557d                	li	a0,-1
}
    80004cfc:	8082                	ret
      return -1;
    80004cfe:	557d                	li	a0,-1
    80004d00:	bf6d                	j	80004cba <filewrite+0x10e>
    80004d02:	557d                	li	a0,-1
    80004d04:	bf5d                	j	80004cba <filewrite+0x10e>

0000000080004d06 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d06:	7179                	addi	sp,sp,-48
    80004d08:	f406                	sd	ra,40(sp)
    80004d0a:	f022                	sd	s0,32(sp)
    80004d0c:	ec26                	sd	s1,24(sp)
    80004d0e:	e84a                	sd	s2,16(sp)
    80004d10:	e44e                	sd	s3,8(sp)
    80004d12:	e052                	sd	s4,0(sp)
    80004d14:	1800                	addi	s0,sp,48
    80004d16:	84aa                	mv	s1,a0
    80004d18:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d1a:	0005b023          	sd	zero,0(a1)
    80004d1e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d22:	00000097          	auipc	ra,0x0
    80004d26:	bd2080e7          	jalr	-1070(ra) # 800048f4 <filealloc>
    80004d2a:	e088                	sd	a0,0(s1)
    80004d2c:	c551                	beqz	a0,80004db8 <pipealloc+0xb2>
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	bc6080e7          	jalr	-1082(ra) # 800048f4 <filealloc>
    80004d36:	00aa3023          	sd	a0,0(s4)
    80004d3a:	c92d                	beqz	a0,80004dac <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d3c:	ffffc097          	auipc	ra,0xffffc
    80004d40:	e2c080e7          	jalr	-468(ra) # 80000b68 <kalloc>
    80004d44:	892a                	mv	s2,a0
    80004d46:	c125                	beqz	a0,80004da6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d48:	4985                	li	s3,1
    80004d4a:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004d4e:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004d52:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004d56:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004d5a:	00004597          	auipc	a1,0x4
    80004d5e:	9de58593          	addi	a1,a1,-1570 # 80008738 <syscalls+0x280>
    80004d62:	ffffc097          	auipc	ra,0xffffc
    80004d66:	0fc080e7          	jalr	252(ra) # 80000e5e <initlock>
  (*f0)->type = FD_PIPE;
    80004d6a:	609c                	ld	a5,0(s1)
    80004d6c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d70:	609c                	ld	a5,0(s1)
    80004d72:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d76:	609c                	ld	a5,0(s1)
    80004d78:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d7c:	609c                	ld	a5,0(s1)
    80004d7e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d82:	000a3783          	ld	a5,0(s4)
    80004d86:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d8a:	000a3783          	ld	a5,0(s4)
    80004d8e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d92:	000a3783          	ld	a5,0(s4)
    80004d96:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d9a:	000a3783          	ld	a5,0(s4)
    80004d9e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004da2:	4501                	li	a0,0
    80004da4:	a025                	j	80004dcc <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004da6:	6088                	ld	a0,0(s1)
    80004da8:	e501                	bnez	a0,80004db0 <pipealloc+0xaa>
    80004daa:	a039                	j	80004db8 <pipealloc+0xb2>
    80004dac:	6088                	ld	a0,0(s1)
    80004dae:	c51d                	beqz	a0,80004ddc <pipealloc+0xd6>
    fileclose(*f0);
    80004db0:	00000097          	auipc	ra,0x0
    80004db4:	c00080e7          	jalr	-1024(ra) # 800049b0 <fileclose>
  if(*f1)
    80004db8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004dbc:	557d                	li	a0,-1
  if(*f1)
    80004dbe:	c799                	beqz	a5,80004dcc <pipealloc+0xc6>
    fileclose(*f1);
    80004dc0:	853e                	mv	a0,a5
    80004dc2:	00000097          	auipc	ra,0x0
    80004dc6:	bee080e7          	jalr	-1042(ra) # 800049b0 <fileclose>
  return -1;
    80004dca:	557d                	li	a0,-1
}
    80004dcc:	70a2                	ld	ra,40(sp)
    80004dce:	7402                	ld	s0,32(sp)
    80004dd0:	64e2                	ld	s1,24(sp)
    80004dd2:	6942                	ld	s2,16(sp)
    80004dd4:	69a2                	ld	s3,8(sp)
    80004dd6:	6a02                	ld	s4,0(sp)
    80004dd8:	6145                	addi	sp,sp,48
    80004dda:	8082                	ret
  return -1;
    80004ddc:	557d                	li	a0,-1
    80004dde:	b7fd                	j	80004dcc <pipealloc+0xc6>

0000000080004de0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004de0:	1101                	addi	sp,sp,-32
    80004de2:	ec06                	sd	ra,24(sp)
    80004de4:	e822                	sd	s0,16(sp)
    80004de6:	e426                	sd	s1,8(sp)
    80004de8:	e04a                	sd	s2,0(sp)
    80004dea:	1000                	addi	s0,sp,32
    80004dec:	84aa                	mv	s1,a0
    80004dee:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004df0:	ffffc097          	auipc	ra,0xffffc
    80004df4:	ef2080e7          	jalr	-270(ra) # 80000ce2 <acquire>
  if(writable){
    80004df8:	04090263          	beqz	s2,80004e3c <pipeclose+0x5c>
    pi->writeopen = 0;
    80004dfc:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004e00:	22048513          	addi	a0,s1,544
    80004e04:	ffffe097          	auipc	ra,0xffffe
    80004e08:	8bc080e7          	jalr	-1860(ra) # 800026c0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e0c:	2284b783          	ld	a5,552(s1)
    80004e10:	ef9d                	bnez	a5,80004e4e <pipeclose+0x6e>
    release(&pi->lock);
    80004e12:	8526                	mv	a0,s1
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	f9e080e7          	jalr	-98(ra) # 80000db2 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	fdc080e7          	jalr	-36(ra) # 80000dfa <freelock>
#endif    
    kfree((char*)pi);
    80004e26:	8526                	mv	a0,s1
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	bf0080e7          	jalr	-1040(ra) # 80000a18 <kfree>
  } else
    release(&pi->lock);
}
    80004e30:	60e2                	ld	ra,24(sp)
    80004e32:	6442                	ld	s0,16(sp)
    80004e34:	64a2                	ld	s1,8(sp)
    80004e36:	6902                	ld	s2,0(sp)
    80004e38:	6105                	addi	sp,sp,32
    80004e3a:	8082                	ret
    pi->readopen = 0;
    80004e3c:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004e40:	22448513          	addi	a0,s1,548
    80004e44:	ffffe097          	auipc	ra,0xffffe
    80004e48:	87c080e7          	jalr	-1924(ra) # 800026c0 <wakeup>
    80004e4c:	b7c1                	j	80004e0c <pipeclose+0x2c>
    release(&pi->lock);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	f62080e7          	jalr	-158(ra) # 80000db2 <release>
}
    80004e58:	bfe1                	j	80004e30 <pipeclose+0x50>

0000000080004e5a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e5a:	711d                	addi	sp,sp,-96
    80004e5c:	ec86                	sd	ra,88(sp)
    80004e5e:	e8a2                	sd	s0,80(sp)
    80004e60:	e4a6                	sd	s1,72(sp)
    80004e62:	e0ca                	sd	s2,64(sp)
    80004e64:	fc4e                	sd	s3,56(sp)
    80004e66:	f852                	sd	s4,48(sp)
    80004e68:	f456                	sd	s5,40(sp)
    80004e6a:	f05a                	sd	s6,32(sp)
    80004e6c:	ec5e                	sd	s7,24(sp)
    80004e6e:	e862                	sd	s8,16(sp)
    80004e70:	1080                	addi	s0,sp,96
    80004e72:	84aa                	mv	s1,a0
    80004e74:	8b2e                	mv	s6,a1
    80004e76:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	eb0080e7          	jalr	-336(ra) # 80001d28 <myproc>
    80004e80:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004e82:	8526                	mv	a0,s1
    80004e84:	ffffc097          	auipc	ra,0xffffc
    80004e88:	e5e080e7          	jalr	-418(ra) # 80000ce2 <acquire>
  for(i = 0; i < n; i++){
    80004e8c:	09505863          	blez	s5,80004f1c <pipewrite+0xc2>
    80004e90:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004e92:	22048a13          	addi	s4,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004e96:	22448993          	addi	s3,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e9a:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004e9c:	2204a783          	lw	a5,544(s1)
    80004ea0:	2244a703          	lw	a4,548(s1)
    80004ea4:	2007879b          	addiw	a5,a5,512
    80004ea8:	02f71b63          	bne	a4,a5,80004ede <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004eac:	2284a783          	lw	a5,552(s1)
    80004eb0:	c3d9                	beqz	a5,80004f36 <pipewrite+0xdc>
    80004eb2:	03892783          	lw	a5,56(s2)
    80004eb6:	e3c1                	bnez	a5,80004f36 <pipewrite+0xdc>
      wakeup(&pi->nread);
    80004eb8:	8552                	mv	a0,s4
    80004eba:	ffffe097          	auipc	ra,0xffffe
    80004ebe:	806080e7          	jalr	-2042(ra) # 800026c0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ec2:	85a6                	mv	a1,s1
    80004ec4:	854e                	mv	a0,s3
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	67a080e7          	jalr	1658(ra) # 80002540 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ece:	2204a783          	lw	a5,544(s1)
    80004ed2:	2244a703          	lw	a4,548(s1)
    80004ed6:	2007879b          	addiw	a5,a5,512
    80004eda:	fcf709e3          	beq	a4,a5,80004eac <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ede:	4685                	li	a3,1
    80004ee0:	865a                	mv	a2,s6
    80004ee2:	faf40593          	addi	a1,s0,-81
    80004ee6:	05893503          	ld	a0,88(s2)
    80004eea:	ffffd097          	auipc	ra,0xffffd
    80004eee:	bc0080e7          	jalr	-1088(ra) # 80001aaa <copyin>
    80004ef2:	03850663          	beq	a0,s8,80004f1e <pipewrite+0xc4>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ef6:	2244a783          	lw	a5,548(s1)
    80004efa:	0017871b          	addiw	a4,a5,1
    80004efe:	22e4a223          	sw	a4,548(s1)
    80004f02:	1ff7f793          	andi	a5,a5,511
    80004f06:	97a6                	add	a5,a5,s1
    80004f08:	faf44703          	lbu	a4,-81(s0)
    80004f0c:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004f10:	2b85                	addiw	s7,s7,1
    80004f12:	0b05                	addi	s6,s6,1
    80004f14:	f97a94e3          	bne	s5,s7,80004e9c <pipewrite+0x42>
    80004f18:	8bd6                	mv	s7,s5
    80004f1a:	a011                	j	80004f1e <pipewrite+0xc4>
    80004f1c:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004f1e:	22048513          	addi	a0,s1,544
    80004f22:	ffffd097          	auipc	ra,0xffffd
    80004f26:	79e080e7          	jalr	1950(ra) # 800026c0 <wakeup>
  release(&pi->lock);
    80004f2a:	8526                	mv	a0,s1
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	e86080e7          	jalr	-378(ra) # 80000db2 <release>
  return i;
    80004f34:	a039                	j	80004f42 <pipewrite+0xe8>
        release(&pi->lock);
    80004f36:	8526                	mv	a0,s1
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	e7a080e7          	jalr	-390(ra) # 80000db2 <release>
        return -1;
    80004f40:	5bfd                	li	s7,-1
}
    80004f42:	855e                	mv	a0,s7
    80004f44:	60e6                	ld	ra,88(sp)
    80004f46:	6446                	ld	s0,80(sp)
    80004f48:	64a6                	ld	s1,72(sp)
    80004f4a:	6906                	ld	s2,64(sp)
    80004f4c:	79e2                	ld	s3,56(sp)
    80004f4e:	7a42                	ld	s4,48(sp)
    80004f50:	7aa2                	ld	s5,40(sp)
    80004f52:	7b02                	ld	s6,32(sp)
    80004f54:	6be2                	ld	s7,24(sp)
    80004f56:	6c42                	ld	s8,16(sp)
    80004f58:	6125                	addi	sp,sp,96
    80004f5a:	8082                	ret

0000000080004f5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f5c:	715d                	addi	sp,sp,-80
    80004f5e:	e486                	sd	ra,72(sp)
    80004f60:	e0a2                	sd	s0,64(sp)
    80004f62:	fc26                	sd	s1,56(sp)
    80004f64:	f84a                	sd	s2,48(sp)
    80004f66:	f44e                	sd	s3,40(sp)
    80004f68:	f052                	sd	s4,32(sp)
    80004f6a:	ec56                	sd	s5,24(sp)
    80004f6c:	e85a                	sd	s6,16(sp)
    80004f6e:	0880                	addi	s0,sp,80
    80004f70:	84aa                	mv	s1,a0
    80004f72:	892e                	mv	s2,a1
    80004f74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f76:	ffffd097          	auipc	ra,0xffffd
    80004f7a:	db2080e7          	jalr	-590(ra) # 80001d28 <myproc>
    80004f7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f80:	8526                	mv	a0,s1
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	d60080e7          	jalr	-672(ra) # 80000ce2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f8a:	2204a703          	lw	a4,544(s1)
    80004f8e:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f92:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f96:	02f71463          	bne	a4,a5,80004fbe <piperead+0x62>
    80004f9a:	22c4a783          	lw	a5,556(s1)
    80004f9e:	c385                	beqz	a5,80004fbe <piperead+0x62>
    if(pr->killed){
    80004fa0:	038a2783          	lw	a5,56(s4)
    80004fa4:	ebc9                	bnez	a5,80005036 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fa6:	85a6                	mv	a1,s1
    80004fa8:	854e                	mv	a0,s3
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	596080e7          	jalr	1430(ra) # 80002540 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fb2:	2204a703          	lw	a4,544(s1)
    80004fb6:	2244a783          	lw	a5,548(s1)
    80004fba:	fef700e3          	beq	a4,a5,80004f9a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fbe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fc0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fc2:	05505463          	blez	s5,8000500a <piperead+0xae>
    if(pi->nread == pi->nwrite)
    80004fc6:	2204a783          	lw	a5,544(s1)
    80004fca:	2244a703          	lw	a4,548(s1)
    80004fce:	02f70e63          	beq	a4,a5,8000500a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004fd2:	0017871b          	addiw	a4,a5,1
    80004fd6:	22e4a023          	sw	a4,544(s1)
    80004fda:	1ff7f793          	andi	a5,a5,511
    80004fde:	97a6                	add	a5,a5,s1
    80004fe0:	0207c783          	lbu	a5,32(a5)
    80004fe4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004fe8:	4685                	li	a3,1
    80004fea:	fbf40613          	addi	a2,s0,-65
    80004fee:	85ca                	mv	a1,s2
    80004ff0:	058a3503          	ld	a0,88(s4)
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	a2a080e7          	jalr	-1494(ra) # 80001a1e <copyout>
    80004ffc:	01650763          	beq	a0,s6,8000500a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005000:	2985                	addiw	s3,s3,1
    80005002:	0905                	addi	s2,s2,1
    80005004:	fd3a91e3          	bne	s5,s3,80004fc6 <piperead+0x6a>
    80005008:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000500a:	22448513          	addi	a0,s1,548
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	6b2080e7          	jalr	1714(ra) # 800026c0 <wakeup>
  release(&pi->lock);
    80005016:	8526                	mv	a0,s1
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	d9a080e7          	jalr	-614(ra) # 80000db2 <release>
  return i;
}
    80005020:	854e                	mv	a0,s3
    80005022:	60a6                	ld	ra,72(sp)
    80005024:	6406                	ld	s0,64(sp)
    80005026:	74e2                	ld	s1,56(sp)
    80005028:	7942                	ld	s2,48(sp)
    8000502a:	79a2                	ld	s3,40(sp)
    8000502c:	7a02                	ld	s4,32(sp)
    8000502e:	6ae2                	ld	s5,24(sp)
    80005030:	6b42                	ld	s6,16(sp)
    80005032:	6161                	addi	sp,sp,80
    80005034:	8082                	ret
      release(&pi->lock);
    80005036:	8526                	mv	a0,s1
    80005038:	ffffc097          	auipc	ra,0xffffc
    8000503c:	d7a080e7          	jalr	-646(ra) # 80000db2 <release>
      return -1;
    80005040:	59fd                	li	s3,-1
    80005042:	bff9                	j	80005020 <piperead+0xc4>

0000000080005044 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005044:	de010113          	addi	sp,sp,-544
    80005048:	20113c23          	sd	ra,536(sp)
    8000504c:	20813823          	sd	s0,528(sp)
    80005050:	20913423          	sd	s1,520(sp)
    80005054:	21213023          	sd	s2,512(sp)
    80005058:	ffce                	sd	s3,504(sp)
    8000505a:	fbd2                	sd	s4,496(sp)
    8000505c:	f7d6                	sd	s5,488(sp)
    8000505e:	f3da                	sd	s6,480(sp)
    80005060:	efde                	sd	s7,472(sp)
    80005062:	ebe2                	sd	s8,464(sp)
    80005064:	e7e6                	sd	s9,456(sp)
    80005066:	e3ea                	sd	s10,448(sp)
    80005068:	ff6e                	sd	s11,440(sp)
    8000506a:	1400                	addi	s0,sp,544
    8000506c:	892a                	mv	s2,a0
    8000506e:	dea43423          	sd	a0,-536(s0)
    80005072:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	cb2080e7          	jalr	-846(ra) # 80001d28 <myproc>
    8000507e:	84aa                	mv	s1,a0

  begin_op();
    80005080:	fffff097          	auipc	ra,0xfffff
    80005084:	460080e7          	jalr	1120(ra) # 800044e0 <begin_op>

  if((ip = namei(path)) == 0){
    80005088:	854a                	mv	a0,s2
    8000508a:	fffff097          	auipc	ra,0xfffff
    8000508e:	236080e7          	jalr	566(ra) # 800042c0 <namei>
    80005092:	c93d                	beqz	a0,80005108 <exec+0xc4>
    80005094:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005096:	fffff097          	auipc	ra,0xfffff
    8000509a:	a70080e7          	jalr	-1424(ra) # 80003b06 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000509e:	04000713          	li	a4,64
    800050a2:	4681                	li	a3,0
    800050a4:	e4840613          	addi	a2,s0,-440
    800050a8:	4581                	li	a1,0
    800050aa:	8556                	mv	a0,s5
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	d0e080e7          	jalr	-754(ra) # 80003dba <readi>
    800050b4:	04000793          	li	a5,64
    800050b8:	00f51a63          	bne	a0,a5,800050cc <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050bc:	e4842703          	lw	a4,-440(s0)
    800050c0:	464c47b7          	lui	a5,0x464c4
    800050c4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800050c8:	04f70663          	beq	a4,a5,80005114 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800050cc:	8556                	mv	a0,s5
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	c9a080e7          	jalr	-870(ra) # 80003d68 <iunlockput>
    end_op();
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	488080e7          	jalr	1160(ra) # 8000455e <end_op>
  }
  return -1;
    800050de:	557d                	li	a0,-1
}
    800050e0:	21813083          	ld	ra,536(sp)
    800050e4:	21013403          	ld	s0,528(sp)
    800050e8:	20813483          	ld	s1,520(sp)
    800050ec:	20013903          	ld	s2,512(sp)
    800050f0:	79fe                	ld	s3,504(sp)
    800050f2:	7a5e                	ld	s4,496(sp)
    800050f4:	7abe                	ld	s5,488(sp)
    800050f6:	7b1e                	ld	s6,480(sp)
    800050f8:	6bfe                	ld	s7,472(sp)
    800050fa:	6c5e                	ld	s8,464(sp)
    800050fc:	6cbe                	ld	s9,456(sp)
    800050fe:	6d1e                	ld	s10,448(sp)
    80005100:	7dfa                	ld	s11,440(sp)
    80005102:	22010113          	addi	sp,sp,544
    80005106:	8082                	ret
    end_op();
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	456080e7          	jalr	1110(ra) # 8000455e <end_op>
    return -1;
    80005110:	557d                	li	a0,-1
    80005112:	b7f9                	j	800050e0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005114:	8526                	mv	a0,s1
    80005116:	ffffd097          	auipc	ra,0xffffd
    8000511a:	cd6080e7          	jalr	-810(ra) # 80001dec <proc_pagetable>
    8000511e:	8b2a                	mv	s6,a0
    80005120:	d555                	beqz	a0,800050cc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005122:	e6842783          	lw	a5,-408(s0)
    80005126:	e8045703          	lhu	a4,-384(s0)
    8000512a:	c735                	beqz	a4,80005196 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000512c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000512e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005132:	6a05                	lui	s4,0x1
    80005134:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005138:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    8000513c:	6d85                	lui	s11,0x1
    8000513e:	7d7d                	lui	s10,0xfffff
    80005140:	ac1d                	j	80005376 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005142:	00003517          	auipc	a0,0x3
    80005146:	5fe50513          	addi	a0,a0,1534 # 80008740 <syscalls+0x288>
    8000514a:	ffffb097          	auipc	ra,0xffffb
    8000514e:	402080e7          	jalr	1026(ra) # 8000054c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005152:	874a                	mv	a4,s2
    80005154:	009c86bb          	addw	a3,s9,s1
    80005158:	4581                	li	a1,0
    8000515a:	8556                	mv	a0,s5
    8000515c:	fffff097          	auipc	ra,0xfffff
    80005160:	c5e080e7          	jalr	-930(ra) # 80003dba <readi>
    80005164:	2501                	sext.w	a0,a0
    80005166:	1aa91863          	bne	s2,a0,80005316 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    8000516a:	009d84bb          	addw	s1,s11,s1
    8000516e:	013d09bb          	addw	s3,s10,s3
    80005172:	1f74f263          	bgeu	s1,s7,80005356 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005176:	02049593          	slli	a1,s1,0x20
    8000517a:	9181                	srli	a1,a1,0x20
    8000517c:	95e2                	add	a1,a1,s8
    8000517e:	855a                	mv	a0,s6
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	2d8080e7          	jalr	728(ra) # 80001458 <walkaddr>
    80005188:	862a                	mv	a2,a0
    if(pa == 0)
    8000518a:	dd45                	beqz	a0,80005142 <exec+0xfe>
      n = PGSIZE;
    8000518c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000518e:	fd49f2e3          	bgeu	s3,s4,80005152 <exec+0x10e>
      n = sz - i;
    80005192:	894e                	mv	s2,s3
    80005194:	bf7d                	j	80005152 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005196:	4481                	li	s1,0
  iunlockput(ip);
    80005198:	8556                	mv	a0,s5
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	bce080e7          	jalr	-1074(ra) # 80003d68 <iunlockput>
  end_op();
    800051a2:	fffff097          	auipc	ra,0xfffff
    800051a6:	3bc080e7          	jalr	956(ra) # 8000455e <end_op>
  p = myproc();
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	b7e080e7          	jalr	-1154(ra) # 80001d28 <myproc>
    800051b2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    800051b4:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800051b8:	6785                	lui	a5,0x1
    800051ba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800051bc:	97a6                	add	a5,a5,s1
    800051be:	777d                	lui	a4,0xfffff
    800051c0:	8ff9                	and	a5,a5,a4
    800051c2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051c6:	6609                	lui	a2,0x2
    800051c8:	963e                	add	a2,a2,a5
    800051ca:	85be                	mv	a1,a5
    800051cc:	855a                	mv	a0,s6
    800051ce:	ffffc097          	auipc	ra,0xffffc
    800051d2:	5fc080e7          	jalr	1532(ra) # 800017ca <uvmalloc>
    800051d6:	8c2a                	mv	s8,a0
  ip = 0;
    800051d8:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051da:	12050e63          	beqz	a0,80005316 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800051de:	75f9                	lui	a1,0xffffe
    800051e0:	95aa                	add	a1,a1,a0
    800051e2:	855a                	mv	a0,s6
    800051e4:	ffffd097          	auipc	ra,0xffffd
    800051e8:	808080e7          	jalr	-2040(ra) # 800019ec <uvmclear>
  stackbase = sp - PGSIZE;
    800051ec:	7afd                	lui	s5,0xfffff
    800051ee:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051f0:	df043783          	ld	a5,-528(s0)
    800051f4:	6388                	ld	a0,0(a5)
    800051f6:	c925                	beqz	a0,80005266 <exec+0x222>
    800051f8:	e8840993          	addi	s3,s0,-376
    800051fc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005200:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005202:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	042080e7          	jalr	66(ra) # 80001246 <strlen>
    8000520c:	0015079b          	addiw	a5,a0,1
    80005210:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005214:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005218:	13596363          	bltu	s2,s5,8000533e <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000521c:	df043d83          	ld	s11,-528(s0)
    80005220:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005224:	8552                	mv	a0,s4
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	020080e7          	jalr	32(ra) # 80001246 <strlen>
    8000522e:	0015069b          	addiw	a3,a0,1
    80005232:	8652                	mv	a2,s4
    80005234:	85ca                	mv	a1,s2
    80005236:	855a                	mv	a0,s6
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	7e6080e7          	jalr	2022(ra) # 80001a1e <copyout>
    80005240:	10054363          	bltz	a0,80005346 <exec+0x302>
    ustack[argc] = sp;
    80005244:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005248:	0485                	addi	s1,s1,1
    8000524a:	008d8793          	addi	a5,s11,8
    8000524e:	def43823          	sd	a5,-528(s0)
    80005252:	008db503          	ld	a0,8(s11)
    80005256:	c911                	beqz	a0,8000526a <exec+0x226>
    if(argc >= MAXARG)
    80005258:	09a1                	addi	s3,s3,8
    8000525a:	fb3c95e3          	bne	s9,s3,80005204 <exec+0x1c0>
  sz = sz1;
    8000525e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005262:	4a81                	li	s5,0
    80005264:	a84d                	j	80005316 <exec+0x2d2>
  sp = sz;
    80005266:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005268:	4481                	li	s1,0
  ustack[argc] = 0;
    8000526a:	00349793          	slli	a5,s1,0x3
    8000526e:	f9078793          	addi	a5,a5,-112
    80005272:	97a2                	add	a5,a5,s0
    80005274:	ee07bc23          	sd	zero,-264(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005278:	00148693          	addi	a3,s1,1
    8000527c:	068e                	slli	a3,a3,0x3
    8000527e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005282:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005286:	01597663          	bgeu	s2,s5,80005292 <exec+0x24e>
  sz = sz1;
    8000528a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000528e:	4a81                	li	s5,0
    80005290:	a059                	j	80005316 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005292:	e8840613          	addi	a2,s0,-376
    80005296:	85ca                	mv	a1,s2
    80005298:	855a                	mv	a0,s6
    8000529a:	ffffc097          	auipc	ra,0xffffc
    8000529e:	784080e7          	jalr	1924(ra) # 80001a1e <copyout>
    800052a2:	0a054663          	bltz	a0,8000534e <exec+0x30a>
  p->trapframe->a1 = sp;
    800052a6:	060bb783          	ld	a5,96(s7)
    800052aa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052ae:	de843783          	ld	a5,-536(s0)
    800052b2:	0007c703          	lbu	a4,0(a5)
    800052b6:	cf11                	beqz	a4,800052d2 <exec+0x28e>
    800052b8:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052ba:	02f00693          	li	a3,47
    800052be:	a039                	j	800052cc <exec+0x288>
      last = s+1;
    800052c0:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800052c4:	0785                	addi	a5,a5,1
    800052c6:	fff7c703          	lbu	a4,-1(a5)
    800052ca:	c701                	beqz	a4,800052d2 <exec+0x28e>
    if(*s == '/')
    800052cc:	fed71ce3          	bne	a4,a3,800052c4 <exec+0x280>
    800052d0:	bfc5                	j	800052c0 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    800052d2:	4641                	li	a2,16
    800052d4:	de843583          	ld	a1,-536(s0)
    800052d8:	160b8513          	addi	a0,s7,352
    800052dc:	ffffc097          	auipc	ra,0xffffc
    800052e0:	f38080e7          	jalr	-200(ra) # 80001214 <safestrcpy>
  oldpagetable = p->pagetable;
    800052e4:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    800052e8:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    800052ec:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052f0:	060bb783          	ld	a5,96(s7)
    800052f4:	e6043703          	ld	a4,-416(s0)
    800052f8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052fa:	060bb783          	ld	a5,96(s7)
    800052fe:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005302:	85ea                	mv	a1,s10
    80005304:	ffffd097          	auipc	ra,0xffffd
    80005308:	b84080e7          	jalr	-1148(ra) # 80001e88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000530c:	0004851b          	sext.w	a0,s1
    80005310:	bbc1                	j	800050e0 <exec+0x9c>
    80005312:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005316:	df843583          	ld	a1,-520(s0)
    8000531a:	855a                	mv	a0,s6
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	b6c080e7          	jalr	-1172(ra) # 80001e88 <proc_freepagetable>
  if(ip){
    80005324:	da0a94e3          	bnez	s5,800050cc <exec+0x88>
  return -1;
    80005328:	557d                	li	a0,-1
    8000532a:	bb5d                	j	800050e0 <exec+0x9c>
    8000532c:	de943c23          	sd	s1,-520(s0)
    80005330:	b7dd                	j	80005316 <exec+0x2d2>
    80005332:	de943c23          	sd	s1,-520(s0)
    80005336:	b7c5                	j	80005316 <exec+0x2d2>
    80005338:	de943c23          	sd	s1,-520(s0)
    8000533c:	bfe9                	j	80005316 <exec+0x2d2>
  sz = sz1;
    8000533e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005342:	4a81                	li	s5,0
    80005344:	bfc9                	j	80005316 <exec+0x2d2>
  sz = sz1;
    80005346:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000534a:	4a81                	li	s5,0
    8000534c:	b7e9                	j	80005316 <exec+0x2d2>
  sz = sz1;
    8000534e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005352:	4a81                	li	s5,0
    80005354:	b7c9                	j	80005316 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005356:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000535a:	e0843783          	ld	a5,-504(s0)
    8000535e:	0017869b          	addiw	a3,a5,1
    80005362:	e0d43423          	sd	a3,-504(s0)
    80005366:	e0043783          	ld	a5,-512(s0)
    8000536a:	0387879b          	addiw	a5,a5,56
    8000536e:	e8045703          	lhu	a4,-384(s0)
    80005372:	e2e6d3e3          	bge	a3,a4,80005198 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005376:	2781                	sext.w	a5,a5
    80005378:	e0f43023          	sd	a5,-512(s0)
    8000537c:	03800713          	li	a4,56
    80005380:	86be                	mv	a3,a5
    80005382:	e1040613          	addi	a2,s0,-496
    80005386:	4581                	li	a1,0
    80005388:	8556                	mv	a0,s5
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	a30080e7          	jalr	-1488(ra) # 80003dba <readi>
    80005392:	03800793          	li	a5,56
    80005396:	f6f51ee3          	bne	a0,a5,80005312 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000539a:	e1042783          	lw	a5,-496(s0)
    8000539e:	4705                	li	a4,1
    800053a0:	fae79de3          	bne	a5,a4,8000535a <exec+0x316>
    if(ph.memsz < ph.filesz)
    800053a4:	e3843603          	ld	a2,-456(s0)
    800053a8:	e3043783          	ld	a5,-464(s0)
    800053ac:	f8f660e3          	bltu	a2,a5,8000532c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053b0:	e2043783          	ld	a5,-480(s0)
    800053b4:	963e                	add	a2,a2,a5
    800053b6:	f6f66ee3          	bltu	a2,a5,80005332 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053ba:	85a6                	mv	a1,s1
    800053bc:	855a                	mv	a0,s6
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	40c080e7          	jalr	1036(ra) # 800017ca <uvmalloc>
    800053c6:	dea43c23          	sd	a0,-520(s0)
    800053ca:	d53d                	beqz	a0,80005338 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800053cc:	e2043c03          	ld	s8,-480(s0)
    800053d0:	de043783          	ld	a5,-544(s0)
    800053d4:	00fc77b3          	and	a5,s8,a5
    800053d8:	ff9d                	bnez	a5,80005316 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053da:	e1842c83          	lw	s9,-488(s0)
    800053de:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053e2:	f60b8ae3          	beqz	s7,80005356 <exec+0x312>
    800053e6:	89de                	mv	s3,s7
    800053e8:	4481                	li	s1,0
    800053ea:	b371                	j	80005176 <exec+0x132>

00000000800053ec <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053ec:	7179                	addi	sp,sp,-48
    800053ee:	f406                	sd	ra,40(sp)
    800053f0:	f022                	sd	s0,32(sp)
    800053f2:	ec26                	sd	s1,24(sp)
    800053f4:	e84a                	sd	s2,16(sp)
    800053f6:	1800                	addi	s0,sp,48
    800053f8:	892e                	mv	s2,a1
    800053fa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800053fc:	fdc40593          	addi	a1,s0,-36
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	9e8080e7          	jalr	-1560(ra) # 80002de8 <argint>
    80005408:	04054063          	bltz	a0,80005448 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000540c:	fdc42703          	lw	a4,-36(s0)
    80005410:	47bd                	li	a5,15
    80005412:	02e7ed63          	bltu	a5,a4,8000544c <argfd+0x60>
    80005416:	ffffd097          	auipc	ra,0xffffd
    8000541a:	912080e7          	jalr	-1774(ra) # 80001d28 <myproc>
    8000541e:	fdc42703          	lw	a4,-36(s0)
    80005422:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd1ff2>
    80005426:	078e                	slli	a5,a5,0x3
    80005428:	953e                	add	a0,a0,a5
    8000542a:	651c                	ld	a5,8(a0)
    8000542c:	c395                	beqz	a5,80005450 <argfd+0x64>
    return -1;
  if(pfd)
    8000542e:	00090463          	beqz	s2,80005436 <argfd+0x4a>
    *pfd = fd;
    80005432:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005436:	4501                	li	a0,0
  if(pf)
    80005438:	c091                	beqz	s1,8000543c <argfd+0x50>
    *pf = f;
    8000543a:	e09c                	sd	a5,0(s1)
}
    8000543c:	70a2                	ld	ra,40(sp)
    8000543e:	7402                	ld	s0,32(sp)
    80005440:	64e2                	ld	s1,24(sp)
    80005442:	6942                	ld	s2,16(sp)
    80005444:	6145                	addi	sp,sp,48
    80005446:	8082                	ret
    return -1;
    80005448:	557d                	li	a0,-1
    8000544a:	bfcd                	j	8000543c <argfd+0x50>
    return -1;
    8000544c:	557d                	li	a0,-1
    8000544e:	b7fd                	j	8000543c <argfd+0x50>
    80005450:	557d                	li	a0,-1
    80005452:	b7ed                	j	8000543c <argfd+0x50>

0000000080005454 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005454:	1101                	addi	sp,sp,-32
    80005456:	ec06                	sd	ra,24(sp)
    80005458:	e822                	sd	s0,16(sp)
    8000545a:	e426                	sd	s1,8(sp)
    8000545c:	1000                	addi	s0,sp,32
    8000545e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	8c8080e7          	jalr	-1848(ra) # 80001d28 <myproc>
    80005468:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000546a:	0d850793          	addi	a5,a0,216
    8000546e:	4501                	li	a0,0
    80005470:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005472:	6398                	ld	a4,0(a5)
    80005474:	cb19                	beqz	a4,8000548a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005476:	2505                	addiw	a0,a0,1
    80005478:	07a1                	addi	a5,a5,8
    8000547a:	fed51ce3          	bne	a0,a3,80005472 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000547e:	557d                	li	a0,-1
}
    80005480:	60e2                	ld	ra,24(sp)
    80005482:	6442                	ld	s0,16(sp)
    80005484:	64a2                	ld	s1,8(sp)
    80005486:	6105                	addi	sp,sp,32
    80005488:	8082                	ret
      p->ofile[fd] = f;
    8000548a:	01a50793          	addi	a5,a0,26
    8000548e:	078e                	slli	a5,a5,0x3
    80005490:	963e                	add	a2,a2,a5
    80005492:	e604                	sd	s1,8(a2)
      return fd;
    80005494:	b7f5                	j	80005480 <fdalloc+0x2c>

0000000080005496 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005496:	715d                	addi	sp,sp,-80
    80005498:	e486                	sd	ra,72(sp)
    8000549a:	e0a2                	sd	s0,64(sp)
    8000549c:	fc26                	sd	s1,56(sp)
    8000549e:	f84a                	sd	s2,48(sp)
    800054a0:	f44e                	sd	s3,40(sp)
    800054a2:	f052                	sd	s4,32(sp)
    800054a4:	ec56                	sd	s5,24(sp)
    800054a6:	0880                	addi	s0,sp,80
    800054a8:	89ae                	mv	s3,a1
    800054aa:	8ab2                	mv	s5,a2
    800054ac:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ae:	fb040593          	addi	a1,s0,-80
    800054b2:	fffff097          	auipc	ra,0xfffff
    800054b6:	e2c080e7          	jalr	-468(ra) # 800042de <nameiparent>
    800054ba:	892a                	mv	s2,a0
    800054bc:	12050e63          	beqz	a0,800055f8 <create+0x162>
    return 0;

  ilock(dp);
    800054c0:	ffffe097          	auipc	ra,0xffffe
    800054c4:	646080e7          	jalr	1606(ra) # 80003b06 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054c8:	4601                	li	a2,0
    800054ca:	fb040593          	addi	a1,s0,-80
    800054ce:	854a                	mv	a0,s2
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	b18080e7          	jalr	-1256(ra) # 80003fe8 <dirlookup>
    800054d8:	84aa                	mv	s1,a0
    800054da:	c921                	beqz	a0,8000552a <create+0x94>
    iunlockput(dp);
    800054dc:	854a                	mv	a0,s2
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	88a080e7          	jalr	-1910(ra) # 80003d68 <iunlockput>
    ilock(ip);
    800054e6:	8526                	mv	a0,s1
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	61e080e7          	jalr	1566(ra) # 80003b06 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054f0:	2981                	sext.w	s3,s3
    800054f2:	4789                	li	a5,2
    800054f4:	02f99463          	bne	s3,a5,8000551c <create+0x86>
    800054f8:	04c4d783          	lhu	a5,76(s1)
    800054fc:	37f9                	addiw	a5,a5,-2
    800054fe:	17c2                	slli	a5,a5,0x30
    80005500:	93c1                	srli	a5,a5,0x30
    80005502:	4705                	li	a4,1
    80005504:	00f76c63          	bltu	a4,a5,8000551c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005508:	8526                	mv	a0,s1
    8000550a:	60a6                	ld	ra,72(sp)
    8000550c:	6406                	ld	s0,64(sp)
    8000550e:	74e2                	ld	s1,56(sp)
    80005510:	7942                	ld	s2,48(sp)
    80005512:	79a2                	ld	s3,40(sp)
    80005514:	7a02                	ld	s4,32(sp)
    80005516:	6ae2                	ld	s5,24(sp)
    80005518:	6161                	addi	sp,sp,80
    8000551a:	8082                	ret
    iunlockput(ip);
    8000551c:	8526                	mv	a0,s1
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	84a080e7          	jalr	-1974(ra) # 80003d68 <iunlockput>
    return 0;
    80005526:	4481                	li	s1,0
    80005528:	b7c5                	j	80005508 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000552a:	85ce                	mv	a1,s3
    8000552c:	00092503          	lw	a0,0(s2)
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	43c080e7          	jalr	1084(ra) # 8000396c <ialloc>
    80005538:	84aa                	mv	s1,a0
    8000553a:	c521                	beqz	a0,80005582 <create+0xec>
  ilock(ip);
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	5ca080e7          	jalr	1482(ra) # 80003b06 <ilock>
  ip->major = major;
    80005544:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    80005548:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    8000554c:	4a05                	li	s4,1
    8000554e:	05449923          	sh	s4,82(s1)
  iupdate(ip);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	4e6080e7          	jalr	1254(ra) # 80003a3a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000555c:	2981                	sext.w	s3,s3
    8000555e:	03498a63          	beq	s3,s4,80005592 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005562:	40d0                	lw	a2,4(s1)
    80005564:	fb040593          	addi	a1,s0,-80
    80005568:	854a                	mv	a0,s2
    8000556a:	fffff097          	auipc	ra,0xfffff
    8000556e:	c94080e7          	jalr	-876(ra) # 800041fe <dirlink>
    80005572:	06054b63          	bltz	a0,800055e8 <create+0x152>
  iunlockput(dp);
    80005576:	854a                	mv	a0,s2
    80005578:	ffffe097          	auipc	ra,0xffffe
    8000557c:	7f0080e7          	jalr	2032(ra) # 80003d68 <iunlockput>
  return ip;
    80005580:	b761                	j	80005508 <create+0x72>
    panic("create: ialloc");
    80005582:	00003517          	auipc	a0,0x3
    80005586:	1de50513          	addi	a0,a0,478 # 80008760 <syscalls+0x2a8>
    8000558a:	ffffb097          	auipc	ra,0xffffb
    8000558e:	fc2080e7          	jalr	-62(ra) # 8000054c <panic>
    dp->nlink++;  // for ".."
    80005592:	05295783          	lhu	a5,82(s2)
    80005596:	2785                	addiw	a5,a5,1
    80005598:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    8000559c:	854a                	mv	a0,s2
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	49c080e7          	jalr	1180(ra) # 80003a3a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055a6:	40d0                	lw	a2,4(s1)
    800055a8:	00003597          	auipc	a1,0x3
    800055ac:	1c858593          	addi	a1,a1,456 # 80008770 <syscalls+0x2b8>
    800055b0:	8526                	mv	a0,s1
    800055b2:	fffff097          	auipc	ra,0xfffff
    800055b6:	c4c080e7          	jalr	-948(ra) # 800041fe <dirlink>
    800055ba:	00054f63          	bltz	a0,800055d8 <create+0x142>
    800055be:	00492603          	lw	a2,4(s2)
    800055c2:	00003597          	auipc	a1,0x3
    800055c6:	1b658593          	addi	a1,a1,438 # 80008778 <syscalls+0x2c0>
    800055ca:	8526                	mv	a0,s1
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	c32080e7          	jalr	-974(ra) # 800041fe <dirlink>
    800055d4:	f80557e3          	bgez	a0,80005562 <create+0xcc>
      panic("create dots");
    800055d8:	00003517          	auipc	a0,0x3
    800055dc:	1a850513          	addi	a0,a0,424 # 80008780 <syscalls+0x2c8>
    800055e0:	ffffb097          	auipc	ra,0xffffb
    800055e4:	f6c080e7          	jalr	-148(ra) # 8000054c <panic>
    panic("create: dirlink");
    800055e8:	00003517          	auipc	a0,0x3
    800055ec:	1a850513          	addi	a0,a0,424 # 80008790 <syscalls+0x2d8>
    800055f0:	ffffb097          	auipc	ra,0xffffb
    800055f4:	f5c080e7          	jalr	-164(ra) # 8000054c <panic>
    return 0;
    800055f8:	84aa                	mv	s1,a0
    800055fa:	b739                	j	80005508 <create+0x72>

00000000800055fc <sys_dup>:
{
    800055fc:	7179                	addi	sp,sp,-48
    800055fe:	f406                	sd	ra,40(sp)
    80005600:	f022                	sd	s0,32(sp)
    80005602:	ec26                	sd	s1,24(sp)
    80005604:	e84a                	sd	s2,16(sp)
    80005606:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005608:	fd840613          	addi	a2,s0,-40
    8000560c:	4581                	li	a1,0
    8000560e:	4501                	li	a0,0
    80005610:	00000097          	auipc	ra,0x0
    80005614:	ddc080e7          	jalr	-548(ra) # 800053ec <argfd>
    return -1;
    80005618:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000561a:	02054363          	bltz	a0,80005640 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000561e:	fd843903          	ld	s2,-40(s0)
    80005622:	854a                	mv	a0,s2
    80005624:	00000097          	auipc	ra,0x0
    80005628:	e30080e7          	jalr	-464(ra) # 80005454 <fdalloc>
    8000562c:	84aa                	mv	s1,a0
    return -1;
    8000562e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005630:	00054863          	bltz	a0,80005640 <sys_dup+0x44>
  filedup(f);
    80005634:	854a                	mv	a0,s2
    80005636:	fffff097          	auipc	ra,0xfffff
    8000563a:	328080e7          	jalr	808(ra) # 8000495e <filedup>
  return fd;
    8000563e:	87a6                	mv	a5,s1
}
    80005640:	853e                	mv	a0,a5
    80005642:	70a2                	ld	ra,40(sp)
    80005644:	7402                	ld	s0,32(sp)
    80005646:	64e2                	ld	s1,24(sp)
    80005648:	6942                	ld	s2,16(sp)
    8000564a:	6145                	addi	sp,sp,48
    8000564c:	8082                	ret

000000008000564e <sys_read>:
{
    8000564e:	7179                	addi	sp,sp,-48
    80005650:	f406                	sd	ra,40(sp)
    80005652:	f022                	sd	s0,32(sp)
    80005654:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005656:	fe840613          	addi	a2,s0,-24
    8000565a:	4581                	li	a1,0
    8000565c:	4501                	li	a0,0
    8000565e:	00000097          	auipc	ra,0x0
    80005662:	d8e080e7          	jalr	-626(ra) # 800053ec <argfd>
    return -1;
    80005666:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005668:	04054163          	bltz	a0,800056aa <sys_read+0x5c>
    8000566c:	fe440593          	addi	a1,s0,-28
    80005670:	4509                	li	a0,2
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	776080e7          	jalr	1910(ra) # 80002de8 <argint>
    return -1;
    8000567a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000567c:	02054763          	bltz	a0,800056aa <sys_read+0x5c>
    80005680:	fd840593          	addi	a1,s0,-40
    80005684:	4505                	li	a0,1
    80005686:	ffffd097          	auipc	ra,0xffffd
    8000568a:	784080e7          	jalr	1924(ra) # 80002e0a <argaddr>
    return -1;
    8000568e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005690:	00054d63          	bltz	a0,800056aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005694:	fe442603          	lw	a2,-28(s0)
    80005698:	fd843583          	ld	a1,-40(s0)
    8000569c:	fe843503          	ld	a0,-24(s0)
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	44a080e7          	jalr	1098(ra) # 80004aea <fileread>
    800056a8:	87aa                	mv	a5,a0
}
    800056aa:	853e                	mv	a0,a5
    800056ac:	70a2                	ld	ra,40(sp)
    800056ae:	7402                	ld	s0,32(sp)
    800056b0:	6145                	addi	sp,sp,48
    800056b2:	8082                	ret

00000000800056b4 <sys_write>:
{
    800056b4:	7179                	addi	sp,sp,-48
    800056b6:	f406                	sd	ra,40(sp)
    800056b8:	f022                	sd	s0,32(sp)
    800056ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056bc:	fe840613          	addi	a2,s0,-24
    800056c0:	4581                	li	a1,0
    800056c2:	4501                	li	a0,0
    800056c4:	00000097          	auipc	ra,0x0
    800056c8:	d28080e7          	jalr	-728(ra) # 800053ec <argfd>
    return -1;
    800056cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ce:	04054163          	bltz	a0,80005710 <sys_write+0x5c>
    800056d2:	fe440593          	addi	a1,s0,-28
    800056d6:	4509                	li	a0,2
    800056d8:	ffffd097          	auipc	ra,0xffffd
    800056dc:	710080e7          	jalr	1808(ra) # 80002de8 <argint>
    return -1;
    800056e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	02054763          	bltz	a0,80005710 <sys_write+0x5c>
    800056e6:	fd840593          	addi	a1,s0,-40
    800056ea:	4505                	li	a0,1
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	71e080e7          	jalr	1822(ra) # 80002e0a <argaddr>
    return -1;
    800056f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f6:	00054d63          	bltz	a0,80005710 <sys_write+0x5c>
  return filewrite(f, p, n);
    800056fa:	fe442603          	lw	a2,-28(s0)
    800056fe:	fd843583          	ld	a1,-40(s0)
    80005702:	fe843503          	ld	a0,-24(s0)
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	4a6080e7          	jalr	1190(ra) # 80004bac <filewrite>
    8000570e:	87aa                	mv	a5,a0
}
    80005710:	853e                	mv	a0,a5
    80005712:	70a2                	ld	ra,40(sp)
    80005714:	7402                	ld	s0,32(sp)
    80005716:	6145                	addi	sp,sp,48
    80005718:	8082                	ret

000000008000571a <sys_close>:
{
    8000571a:	1101                	addi	sp,sp,-32
    8000571c:	ec06                	sd	ra,24(sp)
    8000571e:	e822                	sd	s0,16(sp)
    80005720:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005722:	fe040613          	addi	a2,s0,-32
    80005726:	fec40593          	addi	a1,s0,-20
    8000572a:	4501                	li	a0,0
    8000572c:	00000097          	auipc	ra,0x0
    80005730:	cc0080e7          	jalr	-832(ra) # 800053ec <argfd>
    return -1;
    80005734:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005736:	02054463          	bltz	a0,8000575e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000573a:	ffffc097          	auipc	ra,0xffffc
    8000573e:	5ee080e7          	jalr	1518(ra) # 80001d28 <myproc>
    80005742:	fec42783          	lw	a5,-20(s0)
    80005746:	07e9                	addi	a5,a5,26
    80005748:	078e                	slli	a5,a5,0x3
    8000574a:	953e                	add	a0,a0,a5
    8000574c:	00053423          	sd	zero,8(a0)
  fileclose(f);
    80005750:	fe043503          	ld	a0,-32(s0)
    80005754:	fffff097          	auipc	ra,0xfffff
    80005758:	25c080e7          	jalr	604(ra) # 800049b0 <fileclose>
  return 0;
    8000575c:	4781                	li	a5,0
}
    8000575e:	853e                	mv	a0,a5
    80005760:	60e2                	ld	ra,24(sp)
    80005762:	6442                	ld	s0,16(sp)
    80005764:	6105                	addi	sp,sp,32
    80005766:	8082                	ret

0000000080005768 <sys_fstat>:
{
    80005768:	1101                	addi	sp,sp,-32
    8000576a:	ec06                	sd	ra,24(sp)
    8000576c:	e822                	sd	s0,16(sp)
    8000576e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005770:	fe840613          	addi	a2,s0,-24
    80005774:	4581                	li	a1,0
    80005776:	4501                	li	a0,0
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	c74080e7          	jalr	-908(ra) # 800053ec <argfd>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005782:	02054563          	bltz	a0,800057ac <sys_fstat+0x44>
    80005786:	fe040593          	addi	a1,s0,-32
    8000578a:	4505                	li	a0,1
    8000578c:	ffffd097          	auipc	ra,0xffffd
    80005790:	67e080e7          	jalr	1662(ra) # 80002e0a <argaddr>
    return -1;
    80005794:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005796:	00054b63          	bltz	a0,800057ac <sys_fstat+0x44>
  return filestat(f, st);
    8000579a:	fe043583          	ld	a1,-32(s0)
    8000579e:	fe843503          	ld	a0,-24(s0)
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	2d6080e7          	jalr	726(ra) # 80004a78 <filestat>
    800057aa:	87aa                	mv	a5,a0
}
    800057ac:	853e                	mv	a0,a5
    800057ae:	60e2                	ld	ra,24(sp)
    800057b0:	6442                	ld	s0,16(sp)
    800057b2:	6105                	addi	sp,sp,32
    800057b4:	8082                	ret

00000000800057b6 <sys_link>:
{
    800057b6:	7169                	addi	sp,sp,-304
    800057b8:	f606                	sd	ra,296(sp)
    800057ba:	f222                	sd	s0,288(sp)
    800057bc:	ee26                	sd	s1,280(sp)
    800057be:	ea4a                	sd	s2,272(sp)
    800057c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c2:	08000613          	li	a2,128
    800057c6:	ed040593          	addi	a1,s0,-304
    800057ca:	4501                	li	a0,0
    800057cc:	ffffd097          	auipc	ra,0xffffd
    800057d0:	660080e7          	jalr	1632(ra) # 80002e2c <argstr>
    return -1;
    800057d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057d6:	10054e63          	bltz	a0,800058f2 <sys_link+0x13c>
    800057da:	08000613          	li	a2,128
    800057de:	f5040593          	addi	a1,s0,-176
    800057e2:	4505                	li	a0,1
    800057e4:	ffffd097          	auipc	ra,0xffffd
    800057e8:	648080e7          	jalr	1608(ra) # 80002e2c <argstr>
    return -1;
    800057ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057ee:	10054263          	bltz	a0,800058f2 <sys_link+0x13c>
  begin_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	cee080e7          	jalr	-786(ra) # 800044e0 <begin_op>
  if((ip = namei(old)) == 0){
    800057fa:	ed040513          	addi	a0,s0,-304
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	ac2080e7          	jalr	-1342(ra) # 800042c0 <namei>
    80005806:	84aa                	mv	s1,a0
    80005808:	c551                	beqz	a0,80005894 <sys_link+0xde>
  ilock(ip);
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	2fc080e7          	jalr	764(ra) # 80003b06 <ilock>
  if(ip->type == T_DIR){
    80005812:	04c49703          	lh	a4,76(s1)
    80005816:	4785                	li	a5,1
    80005818:	08f70463          	beq	a4,a5,800058a0 <sys_link+0xea>
  ip->nlink++;
    8000581c:	0524d783          	lhu	a5,82(s1)
    80005820:	2785                	addiw	a5,a5,1
    80005822:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005826:	8526                	mv	a0,s1
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	212080e7          	jalr	530(ra) # 80003a3a <iupdate>
  iunlock(ip);
    80005830:	8526                	mv	a0,s1
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	396080e7          	jalr	918(ra) # 80003bc8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000583a:	fd040593          	addi	a1,s0,-48
    8000583e:	f5040513          	addi	a0,s0,-176
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	a9c080e7          	jalr	-1380(ra) # 800042de <nameiparent>
    8000584a:	892a                	mv	s2,a0
    8000584c:	c935                	beqz	a0,800058c0 <sys_link+0x10a>
  ilock(dp);
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	2b8080e7          	jalr	696(ra) # 80003b06 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005856:	00092703          	lw	a4,0(s2)
    8000585a:	409c                	lw	a5,0(s1)
    8000585c:	04f71d63          	bne	a4,a5,800058b6 <sys_link+0x100>
    80005860:	40d0                	lw	a2,4(s1)
    80005862:	fd040593          	addi	a1,s0,-48
    80005866:	854a                	mv	a0,s2
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	996080e7          	jalr	-1642(ra) # 800041fe <dirlink>
    80005870:	04054363          	bltz	a0,800058b6 <sys_link+0x100>
  iunlockput(dp);
    80005874:	854a                	mv	a0,s2
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	4f2080e7          	jalr	1266(ra) # 80003d68 <iunlockput>
  iput(ip);
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	440080e7          	jalr	1088(ra) # 80003cc0 <iput>
  end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	cd6080e7          	jalr	-810(ra) # 8000455e <end_op>
  return 0;
    80005890:	4781                	li	a5,0
    80005892:	a085                	j	800058f2 <sys_link+0x13c>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	cca080e7          	jalr	-822(ra) # 8000455e <end_op>
    return -1;
    8000589c:	57fd                	li	a5,-1
    8000589e:	a891                	j	800058f2 <sys_link+0x13c>
    iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	4c6080e7          	jalr	1222(ra) # 80003d68 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	cb4080e7          	jalr	-844(ra) # 8000455e <end_op>
    return -1;
    800058b2:	57fd                	li	a5,-1
    800058b4:	a83d                	j	800058f2 <sys_link+0x13c>
    iunlockput(dp);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	4b0080e7          	jalr	1200(ra) # 80003d68 <iunlockput>
  ilock(ip);
    800058c0:	8526                	mv	a0,s1
    800058c2:	ffffe097          	auipc	ra,0xffffe
    800058c6:	244080e7          	jalr	580(ra) # 80003b06 <ilock>
  ip->nlink--;
    800058ca:	0524d783          	lhu	a5,82(s1)
    800058ce:	37fd                	addiw	a5,a5,-1
    800058d0:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	164080e7          	jalr	356(ra) # 80003a3a <iupdate>
  iunlockput(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	488080e7          	jalr	1160(ra) # 80003d68 <iunlockput>
  end_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	c76080e7          	jalr	-906(ra) # 8000455e <end_op>
  return -1;
    800058f0:	57fd                	li	a5,-1
}
    800058f2:	853e                	mv	a0,a5
    800058f4:	70b2                	ld	ra,296(sp)
    800058f6:	7412                	ld	s0,288(sp)
    800058f8:	64f2                	ld	s1,280(sp)
    800058fa:	6952                	ld	s2,272(sp)
    800058fc:	6155                	addi	sp,sp,304
    800058fe:	8082                	ret

0000000080005900 <sys_unlink>:
{
    80005900:	7151                	addi	sp,sp,-240
    80005902:	f586                	sd	ra,232(sp)
    80005904:	f1a2                	sd	s0,224(sp)
    80005906:	eda6                	sd	s1,216(sp)
    80005908:	e9ca                	sd	s2,208(sp)
    8000590a:	e5ce                	sd	s3,200(sp)
    8000590c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000590e:	08000613          	li	a2,128
    80005912:	f3040593          	addi	a1,s0,-208
    80005916:	4501                	li	a0,0
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	514080e7          	jalr	1300(ra) # 80002e2c <argstr>
    80005920:	18054163          	bltz	a0,80005aa2 <sys_unlink+0x1a2>
  begin_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	bbc080e7          	jalr	-1092(ra) # 800044e0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000592c:	fb040593          	addi	a1,s0,-80
    80005930:	f3040513          	addi	a0,s0,-208
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	9aa080e7          	jalr	-1622(ra) # 800042de <nameiparent>
    8000593c:	84aa                	mv	s1,a0
    8000593e:	c979                	beqz	a0,80005a14 <sys_unlink+0x114>
  ilock(dp);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	1c6080e7          	jalr	454(ra) # 80003b06 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005948:	00003597          	auipc	a1,0x3
    8000594c:	e2858593          	addi	a1,a1,-472 # 80008770 <syscalls+0x2b8>
    80005950:	fb040513          	addi	a0,s0,-80
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	67a080e7          	jalr	1658(ra) # 80003fce <namecmp>
    8000595c:	14050a63          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
    80005960:	00003597          	auipc	a1,0x3
    80005964:	e1858593          	addi	a1,a1,-488 # 80008778 <syscalls+0x2c0>
    80005968:	fb040513          	addi	a0,s0,-80
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	662080e7          	jalr	1634(ra) # 80003fce <namecmp>
    80005974:	12050e63          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005978:	f2c40613          	addi	a2,s0,-212
    8000597c:	fb040593          	addi	a1,s0,-80
    80005980:	8526                	mv	a0,s1
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	666080e7          	jalr	1638(ra) # 80003fe8 <dirlookup>
    8000598a:	892a                	mv	s2,a0
    8000598c:	12050263          	beqz	a0,80005ab0 <sys_unlink+0x1b0>
  ilock(ip);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	176080e7          	jalr	374(ra) # 80003b06 <ilock>
  if(ip->nlink < 1)
    80005998:	05291783          	lh	a5,82(s2)
    8000599c:	08f05263          	blez	a5,80005a20 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059a0:	04c91703          	lh	a4,76(s2)
    800059a4:	4785                	li	a5,1
    800059a6:	08f70563          	beq	a4,a5,80005a30 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059aa:	4641                	li	a2,16
    800059ac:	4581                	li	a1,0
    800059ae:	fc040513          	addi	a0,s0,-64
    800059b2:	ffffb097          	auipc	ra,0xffffb
    800059b6:	710080e7          	jalr	1808(ra) # 800010c2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059ba:	4741                	li	a4,16
    800059bc:	f2c42683          	lw	a3,-212(s0)
    800059c0:	fc040613          	addi	a2,s0,-64
    800059c4:	4581                	li	a1,0
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	4ea080e7          	jalr	1258(ra) # 80003eb2 <writei>
    800059d0:	47c1                	li	a5,16
    800059d2:	0af51563          	bne	a0,a5,80005a7c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059d6:	04c91703          	lh	a4,76(s2)
    800059da:	4785                	li	a5,1
    800059dc:	0af70863          	beq	a4,a5,80005a8c <sys_unlink+0x18c>
  iunlockput(dp);
    800059e0:	8526                	mv	a0,s1
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	386080e7          	jalr	902(ra) # 80003d68 <iunlockput>
  ip->nlink--;
    800059ea:	05295783          	lhu	a5,82(s2)
    800059ee:	37fd                	addiw	a5,a5,-1
    800059f0:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    800059f4:	854a                	mv	a0,s2
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	044080e7          	jalr	68(ra) # 80003a3a <iupdate>
  iunlockput(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	368080e7          	jalr	872(ra) # 80003d68 <iunlockput>
  end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	b56080e7          	jalr	-1194(ra) # 8000455e <end_op>
  return 0;
    80005a10:	4501                	li	a0,0
    80005a12:	a84d                	j	80005ac4 <sys_unlink+0x1c4>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	b4a080e7          	jalr	-1206(ra) # 8000455e <end_op>
    return -1;
    80005a1c:	557d                	li	a0,-1
    80005a1e:	a05d                	j	80005ac4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a20:	00003517          	auipc	a0,0x3
    80005a24:	d8050513          	addi	a0,a0,-640 # 800087a0 <syscalls+0x2e8>
    80005a28:	ffffb097          	auipc	ra,0xffffb
    80005a2c:	b24080e7          	jalr	-1244(ra) # 8000054c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a30:	05492703          	lw	a4,84(s2)
    80005a34:	02000793          	li	a5,32
    80005a38:	f6e7f9e3          	bgeu	a5,a4,800059aa <sys_unlink+0xaa>
    80005a3c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a40:	4741                	li	a4,16
    80005a42:	86ce                	mv	a3,s3
    80005a44:	f1840613          	addi	a2,s0,-232
    80005a48:	4581                	li	a1,0
    80005a4a:	854a                	mv	a0,s2
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	36e080e7          	jalr	878(ra) # 80003dba <readi>
    80005a54:	47c1                	li	a5,16
    80005a56:	00f51b63          	bne	a0,a5,80005a6c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a5a:	f1845783          	lhu	a5,-232(s0)
    80005a5e:	e7a1                	bnez	a5,80005aa6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a60:	29c1                	addiw	s3,s3,16
    80005a62:	05492783          	lw	a5,84(s2)
    80005a66:	fcf9ede3          	bltu	s3,a5,80005a40 <sys_unlink+0x140>
    80005a6a:	b781                	j	800059aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a6c:	00003517          	auipc	a0,0x3
    80005a70:	d4c50513          	addi	a0,a0,-692 # 800087b8 <syscalls+0x300>
    80005a74:	ffffb097          	auipc	ra,0xffffb
    80005a78:	ad8080e7          	jalr	-1320(ra) # 8000054c <panic>
    panic("unlink: writei");
    80005a7c:	00003517          	auipc	a0,0x3
    80005a80:	d5450513          	addi	a0,a0,-684 # 800087d0 <syscalls+0x318>
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	ac8080e7          	jalr	-1336(ra) # 8000054c <panic>
    dp->nlink--;
    80005a8c:	0524d783          	lhu	a5,82(s1)
    80005a90:	37fd                	addiw	a5,a5,-1
    80005a92:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005a96:	8526                	mv	a0,s1
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	fa2080e7          	jalr	-94(ra) # 80003a3a <iupdate>
    80005aa0:	b781                	j	800059e0 <sys_unlink+0xe0>
    return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	a005                	j	80005ac4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	2c0080e7          	jalr	704(ra) # 80003d68 <iunlockput>
  iunlockput(dp);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	2b6080e7          	jalr	694(ra) # 80003d68 <iunlockput>
  end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	aa4080e7          	jalr	-1372(ra) # 8000455e <end_op>
  return -1;
    80005ac2:	557d                	li	a0,-1
}
    80005ac4:	70ae                	ld	ra,232(sp)
    80005ac6:	740e                	ld	s0,224(sp)
    80005ac8:	64ee                	ld	s1,216(sp)
    80005aca:	694e                	ld	s2,208(sp)
    80005acc:	69ae                	ld	s3,200(sp)
    80005ace:	616d                	addi	sp,sp,240
    80005ad0:	8082                	ret

0000000080005ad2 <sys_open>:

uint64
sys_open(void)
{
    80005ad2:	7131                	addi	sp,sp,-192
    80005ad4:	fd06                	sd	ra,184(sp)
    80005ad6:	f922                	sd	s0,176(sp)
    80005ad8:	f526                	sd	s1,168(sp)
    80005ada:	f14a                	sd	s2,160(sp)
    80005adc:	ed4e                	sd	s3,152(sp)
    80005ade:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ae0:	08000613          	li	a2,128
    80005ae4:	f5040593          	addi	a1,s0,-176
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	342080e7          	jalr	834(ra) # 80002e2c <argstr>
    return -1;
    80005af2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005af4:	0c054163          	bltz	a0,80005bb6 <sys_open+0xe4>
    80005af8:	f4c40593          	addi	a1,s0,-180
    80005afc:	4505                	li	a0,1
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	2ea080e7          	jalr	746(ra) # 80002de8 <argint>
    80005b06:	0a054863          	bltz	a0,80005bb6 <sys_open+0xe4>

  begin_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	9d6080e7          	jalr	-1578(ra) # 800044e0 <begin_op>

  if(omode & O_CREATE){
    80005b12:	f4c42783          	lw	a5,-180(s0)
    80005b16:	2007f793          	andi	a5,a5,512
    80005b1a:	cbdd                	beqz	a5,80005bd0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b1c:	4681                	li	a3,0
    80005b1e:	4601                	li	a2,0
    80005b20:	4589                	li	a1,2
    80005b22:	f5040513          	addi	a0,s0,-176
    80005b26:	00000097          	auipc	ra,0x0
    80005b2a:	970080e7          	jalr	-1680(ra) # 80005496 <create>
    80005b2e:	892a                	mv	s2,a0
    if(ip == 0){
    80005b30:	c959                	beqz	a0,80005bc6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b32:	04c91703          	lh	a4,76(s2)
    80005b36:	478d                	li	a5,3
    80005b38:	00f71763          	bne	a4,a5,80005b46 <sys_open+0x74>
    80005b3c:	04e95703          	lhu	a4,78(s2)
    80005b40:	47a5                	li	a5,9
    80005b42:	0ce7ec63          	bltu	a5,a4,80005c1a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	dae080e7          	jalr	-594(ra) # 800048f4 <filealloc>
    80005b4e:	89aa                	mv	s3,a0
    80005b50:	10050263          	beqz	a0,80005c54 <sys_open+0x182>
    80005b54:	00000097          	auipc	ra,0x0
    80005b58:	900080e7          	jalr	-1792(ra) # 80005454 <fdalloc>
    80005b5c:	84aa                	mv	s1,a0
    80005b5e:	0e054663          	bltz	a0,80005c4a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b62:	04c91703          	lh	a4,76(s2)
    80005b66:	478d                	li	a5,3
    80005b68:	0cf70463          	beq	a4,a5,80005c30 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b6c:	4789                	li	a5,2
    80005b6e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b72:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b76:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b7a:	f4c42783          	lw	a5,-180(s0)
    80005b7e:	0017c713          	xori	a4,a5,1
    80005b82:	8b05                	andi	a4,a4,1
    80005b84:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b88:	0037f713          	andi	a4,a5,3
    80005b8c:	00e03733          	snez	a4,a4
    80005b90:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b94:	4007f793          	andi	a5,a5,1024
    80005b98:	c791                	beqz	a5,80005ba4 <sys_open+0xd2>
    80005b9a:	04c91703          	lh	a4,76(s2)
    80005b9e:	4789                	li	a5,2
    80005ba0:	08f70f63          	beq	a4,a5,80005c3e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005ba4:	854a                	mv	a0,s2
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	022080e7          	jalr	34(ra) # 80003bc8 <iunlock>
  end_op();
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	9b0080e7          	jalr	-1616(ra) # 8000455e <end_op>

  return fd;
}
    80005bb6:	8526                	mv	a0,s1
    80005bb8:	70ea                	ld	ra,184(sp)
    80005bba:	744a                	ld	s0,176(sp)
    80005bbc:	74aa                	ld	s1,168(sp)
    80005bbe:	790a                	ld	s2,160(sp)
    80005bc0:	69ea                	ld	s3,152(sp)
    80005bc2:	6129                	addi	sp,sp,192
    80005bc4:	8082                	ret
      end_op();
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	998080e7          	jalr	-1640(ra) # 8000455e <end_op>
      return -1;
    80005bce:	b7e5                	j	80005bb6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bd0:	f5040513          	addi	a0,s0,-176
    80005bd4:	ffffe097          	auipc	ra,0xffffe
    80005bd8:	6ec080e7          	jalr	1772(ra) # 800042c0 <namei>
    80005bdc:	892a                	mv	s2,a0
    80005bde:	c905                	beqz	a0,80005c0e <sys_open+0x13c>
    ilock(ip);
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	f26080e7          	jalr	-218(ra) # 80003b06 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005be8:	04c91703          	lh	a4,76(s2)
    80005bec:	4785                	li	a5,1
    80005bee:	f4f712e3          	bne	a4,a5,80005b32 <sys_open+0x60>
    80005bf2:	f4c42783          	lw	a5,-180(s0)
    80005bf6:	dba1                	beqz	a5,80005b46 <sys_open+0x74>
      iunlockput(ip);
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	16e080e7          	jalr	366(ra) # 80003d68 <iunlockput>
      end_op();
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	95c080e7          	jalr	-1700(ra) # 8000455e <end_op>
      return -1;
    80005c0a:	54fd                	li	s1,-1
    80005c0c:	b76d                	j	80005bb6 <sys_open+0xe4>
      end_op();
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	950080e7          	jalr	-1712(ra) # 8000455e <end_op>
      return -1;
    80005c16:	54fd                	li	s1,-1
    80005c18:	bf79                	j	80005bb6 <sys_open+0xe4>
    iunlockput(ip);
    80005c1a:	854a                	mv	a0,s2
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	14c080e7          	jalr	332(ra) # 80003d68 <iunlockput>
    end_op();
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	93a080e7          	jalr	-1734(ra) # 8000455e <end_op>
    return -1;
    80005c2c:	54fd                	li	s1,-1
    80005c2e:	b761                	j	80005bb6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c30:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c34:	04e91783          	lh	a5,78(s2)
    80005c38:	02f99223          	sh	a5,36(s3)
    80005c3c:	bf2d                	j	80005b76 <sys_open+0xa4>
    itrunc(ip);
    80005c3e:	854a                	mv	a0,s2
    80005c40:	ffffe097          	auipc	ra,0xffffe
    80005c44:	fd4080e7          	jalr	-44(ra) # 80003c14 <itrunc>
    80005c48:	bfb1                	j	80005ba4 <sys_open+0xd2>
      fileclose(f);
    80005c4a:	854e                	mv	a0,s3
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	d64080e7          	jalr	-668(ra) # 800049b0 <fileclose>
    iunlockput(ip);
    80005c54:	854a                	mv	a0,s2
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	112080e7          	jalr	274(ra) # 80003d68 <iunlockput>
    end_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	900080e7          	jalr	-1792(ra) # 8000455e <end_op>
    return -1;
    80005c66:	54fd                	li	s1,-1
    80005c68:	b7b9                	j	80005bb6 <sys_open+0xe4>

0000000080005c6a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c6a:	7175                	addi	sp,sp,-144
    80005c6c:	e506                	sd	ra,136(sp)
    80005c6e:	e122                	sd	s0,128(sp)
    80005c70:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	86e080e7          	jalr	-1938(ra) # 800044e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c7a:	08000613          	li	a2,128
    80005c7e:	f7040593          	addi	a1,s0,-144
    80005c82:	4501                	li	a0,0
    80005c84:	ffffd097          	auipc	ra,0xffffd
    80005c88:	1a8080e7          	jalr	424(ra) # 80002e2c <argstr>
    80005c8c:	02054963          	bltz	a0,80005cbe <sys_mkdir+0x54>
    80005c90:	4681                	li	a3,0
    80005c92:	4601                	li	a2,0
    80005c94:	4585                	li	a1,1
    80005c96:	f7040513          	addi	a0,s0,-144
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	7fc080e7          	jalr	2044(ra) # 80005496 <create>
    80005ca2:	cd11                	beqz	a0,80005cbe <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ca4:	ffffe097          	auipc	ra,0xffffe
    80005ca8:	0c4080e7          	jalr	196(ra) # 80003d68 <iunlockput>
  end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	8b2080e7          	jalr	-1870(ra) # 8000455e <end_op>
  return 0;
    80005cb4:	4501                	li	a0,0
}
    80005cb6:	60aa                	ld	ra,136(sp)
    80005cb8:	640a                	ld	s0,128(sp)
    80005cba:	6149                	addi	sp,sp,144
    80005cbc:	8082                	ret
    end_op();
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	8a0080e7          	jalr	-1888(ra) # 8000455e <end_op>
    return -1;
    80005cc6:	557d                	li	a0,-1
    80005cc8:	b7fd                	j	80005cb6 <sys_mkdir+0x4c>

0000000080005cca <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cca:	7135                	addi	sp,sp,-160
    80005ccc:	ed06                	sd	ra,152(sp)
    80005cce:	e922                	sd	s0,144(sp)
    80005cd0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	80e080e7          	jalr	-2034(ra) # 800044e0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cda:	08000613          	li	a2,128
    80005cde:	f7040593          	addi	a1,s0,-144
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	148080e7          	jalr	328(ra) # 80002e2c <argstr>
    80005cec:	04054a63          	bltz	a0,80005d40 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005cf0:	f6c40593          	addi	a1,s0,-148
    80005cf4:	4505                	li	a0,1
    80005cf6:	ffffd097          	auipc	ra,0xffffd
    80005cfa:	0f2080e7          	jalr	242(ra) # 80002de8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cfe:	04054163          	bltz	a0,80005d40 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d02:	f6840593          	addi	a1,s0,-152
    80005d06:	4509                	li	a0,2
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	0e0080e7          	jalr	224(ra) # 80002de8 <argint>
     argint(1, &major) < 0 ||
    80005d10:	02054863          	bltz	a0,80005d40 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d14:	f6841683          	lh	a3,-152(s0)
    80005d18:	f6c41603          	lh	a2,-148(s0)
    80005d1c:	458d                	li	a1,3
    80005d1e:	f7040513          	addi	a0,s0,-144
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	774080e7          	jalr	1908(ra) # 80005496 <create>
     argint(2, &minor) < 0 ||
    80005d2a:	c919                	beqz	a0,80005d40 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d2c:	ffffe097          	auipc	ra,0xffffe
    80005d30:	03c080e7          	jalr	60(ra) # 80003d68 <iunlockput>
  end_op();
    80005d34:	fffff097          	auipc	ra,0xfffff
    80005d38:	82a080e7          	jalr	-2006(ra) # 8000455e <end_op>
  return 0;
    80005d3c:	4501                	li	a0,0
    80005d3e:	a031                	j	80005d4a <sys_mknod+0x80>
    end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	81e080e7          	jalr	-2018(ra) # 8000455e <end_op>
    return -1;
    80005d48:	557d                	li	a0,-1
}
    80005d4a:	60ea                	ld	ra,152(sp)
    80005d4c:	644a                	ld	s0,144(sp)
    80005d4e:	610d                	addi	sp,sp,160
    80005d50:	8082                	ret

0000000080005d52 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d52:	7135                	addi	sp,sp,-160
    80005d54:	ed06                	sd	ra,152(sp)
    80005d56:	e922                	sd	s0,144(sp)
    80005d58:	e526                	sd	s1,136(sp)
    80005d5a:	e14a                	sd	s2,128(sp)
    80005d5c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d5e:	ffffc097          	auipc	ra,0xffffc
    80005d62:	fca080e7          	jalr	-54(ra) # 80001d28 <myproc>
    80005d66:	892a                	mv	s2,a0
  
  begin_op();
    80005d68:	ffffe097          	auipc	ra,0xffffe
    80005d6c:	778080e7          	jalr	1912(ra) # 800044e0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d70:	08000613          	li	a2,128
    80005d74:	f6040593          	addi	a1,s0,-160
    80005d78:	4501                	li	a0,0
    80005d7a:	ffffd097          	auipc	ra,0xffffd
    80005d7e:	0b2080e7          	jalr	178(ra) # 80002e2c <argstr>
    80005d82:	04054b63          	bltz	a0,80005dd8 <sys_chdir+0x86>
    80005d86:	f6040513          	addi	a0,s0,-160
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	536080e7          	jalr	1334(ra) # 800042c0 <namei>
    80005d92:	84aa                	mv	s1,a0
    80005d94:	c131                	beqz	a0,80005dd8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	d70080e7          	jalr	-656(ra) # 80003b06 <ilock>
  if(ip->type != T_DIR){
    80005d9e:	04c49703          	lh	a4,76(s1)
    80005da2:	4785                	li	a5,1
    80005da4:	04f71063          	bne	a4,a5,80005de4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005da8:	8526                	mv	a0,s1
    80005daa:	ffffe097          	auipc	ra,0xffffe
    80005dae:	e1e080e7          	jalr	-482(ra) # 80003bc8 <iunlock>
  iput(p->cwd);
    80005db2:	15893503          	ld	a0,344(s2)
    80005db6:	ffffe097          	auipc	ra,0xffffe
    80005dba:	f0a080e7          	jalr	-246(ra) # 80003cc0 <iput>
  end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	7a0080e7          	jalr	1952(ra) # 8000455e <end_op>
  p->cwd = ip;
    80005dc6:	14993c23          	sd	s1,344(s2)
  return 0;
    80005dca:	4501                	li	a0,0
}
    80005dcc:	60ea                	ld	ra,152(sp)
    80005dce:	644a                	ld	s0,144(sp)
    80005dd0:	64aa                	ld	s1,136(sp)
    80005dd2:	690a                	ld	s2,128(sp)
    80005dd4:	610d                	addi	sp,sp,160
    80005dd6:	8082                	ret
    end_op();
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	786080e7          	jalr	1926(ra) # 8000455e <end_op>
    return -1;
    80005de0:	557d                	li	a0,-1
    80005de2:	b7ed                	j	80005dcc <sys_chdir+0x7a>
    iunlockput(ip);
    80005de4:	8526                	mv	a0,s1
    80005de6:	ffffe097          	auipc	ra,0xffffe
    80005dea:	f82080e7          	jalr	-126(ra) # 80003d68 <iunlockput>
    end_op();
    80005dee:	ffffe097          	auipc	ra,0xffffe
    80005df2:	770080e7          	jalr	1904(ra) # 8000455e <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
    80005df8:	bfd1                	j	80005dcc <sys_chdir+0x7a>

0000000080005dfa <sys_exec>:

uint64
sys_exec(void)
{
    80005dfa:	7145                	addi	sp,sp,-464
    80005dfc:	e786                	sd	ra,456(sp)
    80005dfe:	e3a2                	sd	s0,448(sp)
    80005e00:	ff26                	sd	s1,440(sp)
    80005e02:	fb4a                	sd	s2,432(sp)
    80005e04:	f74e                	sd	s3,424(sp)
    80005e06:	f352                	sd	s4,416(sp)
    80005e08:	ef56                	sd	s5,408(sp)
    80005e0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e0c:	08000613          	li	a2,128
    80005e10:	f4040593          	addi	a1,s0,-192
    80005e14:	4501                	li	a0,0
    80005e16:	ffffd097          	auipc	ra,0xffffd
    80005e1a:	016080e7          	jalr	22(ra) # 80002e2c <argstr>
    return -1;
    80005e1e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e20:	0c054b63          	bltz	a0,80005ef6 <sys_exec+0xfc>
    80005e24:	e3840593          	addi	a1,s0,-456
    80005e28:	4505                	li	a0,1
    80005e2a:	ffffd097          	auipc	ra,0xffffd
    80005e2e:	fe0080e7          	jalr	-32(ra) # 80002e0a <argaddr>
    80005e32:	0c054263          	bltz	a0,80005ef6 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e36:	10000613          	li	a2,256
    80005e3a:	4581                	li	a1,0
    80005e3c:	e4040513          	addi	a0,s0,-448
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	282080e7          	jalr	642(ra) # 800010c2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e4c:	89a6                	mv	s3,s1
    80005e4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e50:	02000a13          	li	s4,32
    80005e54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e58:	00391513          	slli	a0,s2,0x3
    80005e5c:	e3040593          	addi	a1,s0,-464
    80005e60:	e3843783          	ld	a5,-456(s0)
    80005e64:	953e                	add	a0,a0,a5
    80005e66:	ffffd097          	auipc	ra,0xffffd
    80005e6a:	ee8080e7          	jalr	-280(ra) # 80002d4e <fetchaddr>
    80005e6e:	02054a63          	bltz	a0,80005ea2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e72:	e3043783          	ld	a5,-464(s0)
    80005e76:	c3b9                	beqz	a5,80005ebc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e78:	ffffb097          	auipc	ra,0xffffb
    80005e7c:	cf0080e7          	jalr	-784(ra) # 80000b68 <kalloc>
    80005e80:	85aa                	mv	a1,a0
    80005e82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e86:	cd11                	beqz	a0,80005ea2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	e3043503          	ld	a0,-464(s0)
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	f12080e7          	jalr	-238(ra) # 80002da0 <fetchstr>
    80005e96:	00054663          	bltz	a0,80005ea2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005e9a:	0905                	addi	s2,s2,1
    80005e9c:	09a1                	addi	s3,s3,8
    80005e9e:	fb491be3          	bne	s2,s4,80005e54 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ea2:	f4040913          	addi	s2,s0,-192
    80005ea6:	6088                	ld	a0,0(s1)
    80005ea8:	c531                	beqz	a0,80005ef4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005eaa:	ffffb097          	auipc	ra,0xffffb
    80005eae:	b6e080e7          	jalr	-1170(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eb2:	04a1                	addi	s1,s1,8
    80005eb4:	ff2499e3          	bne	s1,s2,80005ea6 <sys_exec+0xac>
  return -1;
    80005eb8:	597d                	li	s2,-1
    80005eba:	a835                	j	80005ef6 <sys_exec+0xfc>
      argv[i] = 0;
    80005ebc:	0a8e                	slli	s5,s5,0x3
    80005ebe:	fc0a8793          	addi	a5,s5,-64 # ffffffffffffefc0 <end+0xffffffff7ffd1f98>
    80005ec2:	00878ab3          	add	s5,a5,s0
    80005ec6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eca:	e4040593          	addi	a1,s0,-448
    80005ece:	f4040513          	addi	a0,s0,-192
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	172080e7          	jalr	370(ra) # 80005044 <exec>
    80005eda:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005edc:	f4040993          	addi	s3,s0,-192
    80005ee0:	6088                	ld	a0,0(s1)
    80005ee2:	c911                	beqz	a0,80005ef6 <sys_exec+0xfc>
    kfree(argv[i]);
    80005ee4:	ffffb097          	auipc	ra,0xffffb
    80005ee8:	b34080e7          	jalr	-1228(ra) # 80000a18 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005eec:	04a1                	addi	s1,s1,8
    80005eee:	ff3499e3          	bne	s1,s3,80005ee0 <sys_exec+0xe6>
    80005ef2:	a011                	j	80005ef6 <sys_exec+0xfc>
  return -1;
    80005ef4:	597d                	li	s2,-1
}
    80005ef6:	854a                	mv	a0,s2
    80005ef8:	60be                	ld	ra,456(sp)
    80005efa:	641e                	ld	s0,448(sp)
    80005efc:	74fa                	ld	s1,440(sp)
    80005efe:	795a                	ld	s2,432(sp)
    80005f00:	79ba                	ld	s3,424(sp)
    80005f02:	7a1a                	ld	s4,416(sp)
    80005f04:	6afa                	ld	s5,408(sp)
    80005f06:	6179                	addi	sp,sp,464
    80005f08:	8082                	ret

0000000080005f0a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f0a:	7139                	addi	sp,sp,-64
    80005f0c:	fc06                	sd	ra,56(sp)
    80005f0e:	f822                	sd	s0,48(sp)
    80005f10:	f426                	sd	s1,40(sp)
    80005f12:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f14:	ffffc097          	auipc	ra,0xffffc
    80005f18:	e14080e7          	jalr	-492(ra) # 80001d28 <myproc>
    80005f1c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f1e:	fd840593          	addi	a1,s0,-40
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	ee6080e7          	jalr	-282(ra) # 80002e0a <argaddr>
    return -1;
    80005f2c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f2e:	0e054063          	bltz	a0,8000600e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f32:	fc840593          	addi	a1,s0,-56
    80005f36:	fd040513          	addi	a0,s0,-48
    80005f3a:	fffff097          	auipc	ra,0xfffff
    80005f3e:	dcc080e7          	jalr	-564(ra) # 80004d06 <pipealloc>
    return -1;
    80005f42:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f44:	0c054563          	bltz	a0,8000600e <sys_pipe+0x104>
  fd0 = -1;
    80005f48:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f4c:	fd043503          	ld	a0,-48(s0)
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	504080e7          	jalr	1284(ra) # 80005454 <fdalloc>
    80005f58:	fca42223          	sw	a0,-60(s0)
    80005f5c:	08054c63          	bltz	a0,80005ff4 <sys_pipe+0xea>
    80005f60:	fc843503          	ld	a0,-56(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	4f0080e7          	jalr	1264(ra) # 80005454 <fdalloc>
    80005f6c:	fca42023          	sw	a0,-64(s0)
    80005f70:	06054963          	bltz	a0,80005fe2 <sys_pipe+0xd8>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f74:	4691                	li	a3,4
    80005f76:	fc440613          	addi	a2,s0,-60
    80005f7a:	fd843583          	ld	a1,-40(s0)
    80005f7e:	6ca8                	ld	a0,88(s1)
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	a9e080e7          	jalr	-1378(ra) # 80001a1e <copyout>
    80005f88:	02054063          	bltz	a0,80005fa8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f8c:	4691                	li	a3,4
    80005f8e:	fc040613          	addi	a2,s0,-64
    80005f92:	fd843583          	ld	a1,-40(s0)
    80005f96:	0591                	addi	a1,a1,4
    80005f98:	6ca8                	ld	a0,88(s1)
    80005f9a:	ffffc097          	auipc	ra,0xffffc
    80005f9e:	a84080e7          	jalr	-1404(ra) # 80001a1e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fa2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fa4:	06055563          	bgez	a0,8000600e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fa8:	fc442783          	lw	a5,-60(s0)
    80005fac:	07e9                	addi	a5,a5,26
    80005fae:	078e                	slli	a5,a5,0x3
    80005fb0:	97a6                	add	a5,a5,s1
    80005fb2:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005fb6:	fc042783          	lw	a5,-64(s0)
    80005fba:	07e9                	addi	a5,a5,26
    80005fbc:	078e                	slli	a5,a5,0x3
    80005fbe:	00f48533          	add	a0,s1,a5
    80005fc2:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005fc6:	fd043503          	ld	a0,-48(s0)
    80005fca:	fffff097          	auipc	ra,0xfffff
    80005fce:	9e6080e7          	jalr	-1562(ra) # 800049b0 <fileclose>
    fileclose(wf);
    80005fd2:	fc843503          	ld	a0,-56(s0)
    80005fd6:	fffff097          	auipc	ra,0xfffff
    80005fda:	9da080e7          	jalr	-1574(ra) # 800049b0 <fileclose>
    return -1;
    80005fde:	57fd                	li	a5,-1
    80005fe0:	a03d                	j	8000600e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005fe2:	fc442783          	lw	a5,-60(s0)
    80005fe6:	0007c763          	bltz	a5,80005ff4 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005fea:	07e9                	addi	a5,a5,26
    80005fec:	078e                	slli	a5,a5,0x3
    80005fee:	97a6                	add	a5,a5,s1
    80005ff0:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005ff4:	fd043503          	ld	a0,-48(s0)
    80005ff8:	fffff097          	auipc	ra,0xfffff
    80005ffc:	9b8080e7          	jalr	-1608(ra) # 800049b0 <fileclose>
    fileclose(wf);
    80006000:	fc843503          	ld	a0,-56(s0)
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	9ac080e7          	jalr	-1620(ra) # 800049b0 <fileclose>
    return -1;
    8000600c:	57fd                	li	a5,-1
}
    8000600e:	853e                	mv	a0,a5
    80006010:	70e2                	ld	ra,56(sp)
    80006012:	7442                	ld	s0,48(sp)
    80006014:	74a2                	ld	s1,40(sp)
    80006016:	6121                	addi	sp,sp,64
    80006018:	8082                	ret
    8000601a:	0000                	unimp
    8000601c:	0000                	unimp
	...

0000000080006020 <kernelvec>:
    80006020:	7111                	addi	sp,sp,-256
    80006022:	e006                	sd	ra,0(sp)
    80006024:	e40a                	sd	sp,8(sp)
    80006026:	e80e                	sd	gp,16(sp)
    80006028:	ec12                	sd	tp,24(sp)
    8000602a:	f016                	sd	t0,32(sp)
    8000602c:	f41a                	sd	t1,40(sp)
    8000602e:	f81e                	sd	t2,48(sp)
    80006030:	fc22                	sd	s0,56(sp)
    80006032:	e0a6                	sd	s1,64(sp)
    80006034:	e4aa                	sd	a0,72(sp)
    80006036:	e8ae                	sd	a1,80(sp)
    80006038:	ecb2                	sd	a2,88(sp)
    8000603a:	f0b6                	sd	a3,96(sp)
    8000603c:	f4ba                	sd	a4,104(sp)
    8000603e:	f8be                	sd	a5,112(sp)
    80006040:	fcc2                	sd	a6,120(sp)
    80006042:	e146                	sd	a7,128(sp)
    80006044:	e54a                	sd	s2,136(sp)
    80006046:	e94e                	sd	s3,144(sp)
    80006048:	ed52                	sd	s4,152(sp)
    8000604a:	f156                	sd	s5,160(sp)
    8000604c:	f55a                	sd	s6,168(sp)
    8000604e:	f95e                	sd	s7,176(sp)
    80006050:	fd62                	sd	s8,184(sp)
    80006052:	e1e6                	sd	s9,192(sp)
    80006054:	e5ea                	sd	s10,200(sp)
    80006056:	e9ee                	sd	s11,208(sp)
    80006058:	edf2                	sd	t3,216(sp)
    8000605a:	f1f6                	sd	t4,224(sp)
    8000605c:	f5fa                	sd	t5,232(sp)
    8000605e:	f9fe                	sd	t6,240(sp)
    80006060:	bbbfc0ef          	jal	ra,80002c1a <kerneltrap>
    80006064:	6082                	ld	ra,0(sp)
    80006066:	6122                	ld	sp,8(sp)
    80006068:	61c2                	ld	gp,16(sp)
    8000606a:	7282                	ld	t0,32(sp)
    8000606c:	7322                	ld	t1,40(sp)
    8000606e:	73c2                	ld	t2,48(sp)
    80006070:	7462                	ld	s0,56(sp)
    80006072:	6486                	ld	s1,64(sp)
    80006074:	6526                	ld	a0,72(sp)
    80006076:	65c6                	ld	a1,80(sp)
    80006078:	6666                	ld	a2,88(sp)
    8000607a:	7686                	ld	a3,96(sp)
    8000607c:	7726                	ld	a4,104(sp)
    8000607e:	77c6                	ld	a5,112(sp)
    80006080:	7866                	ld	a6,120(sp)
    80006082:	688a                	ld	a7,128(sp)
    80006084:	692a                	ld	s2,136(sp)
    80006086:	69ca                	ld	s3,144(sp)
    80006088:	6a6a                	ld	s4,152(sp)
    8000608a:	7a8a                	ld	s5,160(sp)
    8000608c:	7b2a                	ld	s6,168(sp)
    8000608e:	7bca                	ld	s7,176(sp)
    80006090:	7c6a                	ld	s8,184(sp)
    80006092:	6c8e                	ld	s9,192(sp)
    80006094:	6d2e                	ld	s10,200(sp)
    80006096:	6dce                	ld	s11,208(sp)
    80006098:	6e6e                	ld	t3,216(sp)
    8000609a:	7e8e                	ld	t4,224(sp)
    8000609c:	7f2e                	ld	t5,232(sp)
    8000609e:	7fce                	ld	t6,240(sp)
    800060a0:	6111                	addi	sp,sp,256
    800060a2:	10200073          	sret
    800060a6:	00000013          	nop
    800060aa:	00000013          	nop
    800060ae:	0001                	nop

00000000800060b0 <timervec>:
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	e10c                	sd	a1,0(a0)
    800060b6:	e510                	sd	a2,8(a0)
    800060b8:	e914                	sd	a3,16(a0)
    800060ba:	6d0c                	ld	a1,24(a0)
    800060bc:	7110                	ld	a2,32(a0)
    800060be:	6194                	ld	a3,0(a1)
    800060c0:	96b2                	add	a3,a3,a2
    800060c2:	e194                	sd	a3,0(a1)
    800060c4:	4589                	li	a1,2
    800060c6:	14459073          	csrw	sip,a1
    800060ca:	6914                	ld	a3,16(a0)
    800060cc:	6510                	ld	a2,8(a0)
    800060ce:	610c                	ld	a1,0(a0)
    800060d0:	34051573          	csrrw	a0,mscratch,a0
    800060d4:	30200073          	mret
	...

00000000800060da <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060da:	1141                	addi	sp,sp,-16
    800060dc:	e422                	sd	s0,8(sp)
    800060de:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060e0:	0c0007b7          	lui	a5,0xc000
    800060e4:	4705                	li	a4,1
    800060e6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060e8:	c3d8                	sw	a4,4(a5)
}
    800060ea:	6422                	ld	s0,8(sp)
    800060ec:	0141                	addi	sp,sp,16
    800060ee:	8082                	ret

00000000800060f0 <plicinithart>:

void
plicinithart(void)
{
    800060f0:	1141                	addi	sp,sp,-16
    800060f2:	e406                	sd	ra,8(sp)
    800060f4:	e022                	sd	s0,0(sp)
    800060f6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060f8:	ffffc097          	auipc	ra,0xffffc
    800060fc:	c04080e7          	jalr	-1020(ra) # 80001cfc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006100:	0085171b          	slliw	a4,a0,0x8
    80006104:	0c0027b7          	lui	a5,0xc002
    80006108:	97ba                	add	a5,a5,a4
    8000610a:	40200713          	li	a4,1026
    8000610e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006112:	00d5151b          	slliw	a0,a0,0xd
    80006116:	0c2017b7          	lui	a5,0xc201
    8000611a:	97aa                	add	a5,a5,a0
    8000611c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006120:	60a2                	ld	ra,8(sp)
    80006122:	6402                	ld	s0,0(sp)
    80006124:	0141                	addi	sp,sp,16
    80006126:	8082                	ret

0000000080006128 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006128:	1141                	addi	sp,sp,-16
    8000612a:	e406                	sd	ra,8(sp)
    8000612c:	e022                	sd	s0,0(sp)
    8000612e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006130:	ffffc097          	auipc	ra,0xffffc
    80006134:	bcc080e7          	jalr	-1076(ra) # 80001cfc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006138:	00d5151b          	slliw	a0,a0,0xd
    8000613c:	0c2017b7          	lui	a5,0xc201
    80006140:	97aa                	add	a5,a5,a0
  return irq;
}
    80006142:	43c8                	lw	a0,4(a5)
    80006144:	60a2                	ld	ra,8(sp)
    80006146:	6402                	ld	s0,0(sp)
    80006148:	0141                	addi	sp,sp,16
    8000614a:	8082                	ret

000000008000614c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000614c:	1101                	addi	sp,sp,-32
    8000614e:	ec06                	sd	ra,24(sp)
    80006150:	e822                	sd	s0,16(sp)
    80006152:	e426                	sd	s1,8(sp)
    80006154:	1000                	addi	s0,sp,32
    80006156:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006158:	ffffc097          	auipc	ra,0xffffc
    8000615c:	ba4080e7          	jalr	-1116(ra) # 80001cfc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006160:	00d5151b          	slliw	a0,a0,0xd
    80006164:	0c2017b7          	lui	a5,0xc201
    80006168:	97aa                	add	a5,a5,a0
    8000616a:	c3c4                	sw	s1,4(a5)
}
    8000616c:	60e2                	ld	ra,24(sp)
    8000616e:	6442                	ld	s0,16(sp)
    80006170:	64a2                	ld	s1,8(sp)
    80006172:	6105                	addi	sp,sp,32
    80006174:	8082                	ret

0000000080006176 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006176:	1141                	addi	sp,sp,-16
    80006178:	e406                	sd	ra,8(sp)
    8000617a:	e022                	sd	s0,0(sp)
    8000617c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000617e:	479d                	li	a5,7
    80006180:	06a7c863          	blt	a5,a0,800061f0 <free_desc+0x7a>
    panic("free_desc 1");
  if(disk.free[i])
    80006184:	00023717          	auipc	a4,0x23
    80006188:	e7c70713          	addi	a4,a4,-388 # 80029000 <disk>
    8000618c:	972a                	add	a4,a4,a0
    8000618e:	6789                	lui	a5,0x2
    80006190:	97ba                	add	a5,a5,a4
    80006192:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006196:	e7ad                	bnez	a5,80006200 <free_desc+0x8a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006198:	00451793          	slli	a5,a0,0x4
    8000619c:	00025717          	auipc	a4,0x25
    800061a0:	e6470713          	addi	a4,a4,-412 # 8002b000 <disk+0x2000>
    800061a4:	6314                	ld	a3,0(a4)
    800061a6:	96be                	add	a3,a3,a5
    800061a8:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    800061ac:	6314                	ld	a3,0(a4)
    800061ae:	96be                	add	a3,a3,a5
    800061b0:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061b4:	6314                	ld	a3,0(a4)
    800061b6:	96be                	add	a3,a3,a5
    800061b8:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061bc:	6318                	ld	a4,0(a4)
    800061be:	97ba                	add	a5,a5,a4
    800061c0:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061c4:	00023717          	auipc	a4,0x23
    800061c8:	e3c70713          	addi	a4,a4,-452 # 80029000 <disk>
    800061cc:	972a                	add	a4,a4,a0
    800061ce:	6789                	lui	a5,0x2
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	4705                	li	a4,1
    800061d4:	00e78c23          	sb	a4,24(a5) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061d8:	00025517          	auipc	a0,0x25
    800061dc:	e4050513          	addi	a0,a0,-448 # 8002b018 <disk+0x2018>
    800061e0:	ffffc097          	auipc	ra,0xffffc
    800061e4:	4e0080e7          	jalr	1248(ra) # 800026c0 <wakeup>
}
    800061e8:	60a2                	ld	ra,8(sp)
    800061ea:	6402                	ld	s0,0(sp)
    800061ec:	0141                	addi	sp,sp,16
    800061ee:	8082                	ret
    panic("free_desc 1");
    800061f0:	00002517          	auipc	a0,0x2
    800061f4:	5f050513          	addi	a0,a0,1520 # 800087e0 <syscalls+0x328>
    800061f8:	ffffa097          	auipc	ra,0xffffa
    800061fc:	354080e7          	jalr	852(ra) # 8000054c <panic>
    panic("free_desc 2");
    80006200:	00002517          	auipc	a0,0x2
    80006204:	5f050513          	addi	a0,a0,1520 # 800087f0 <syscalls+0x338>
    80006208:	ffffa097          	auipc	ra,0xffffa
    8000620c:	344080e7          	jalr	836(ra) # 8000054c <panic>

0000000080006210 <virtio_disk_init>:
{
    80006210:	1101                	addi	sp,sp,-32
    80006212:	ec06                	sd	ra,24(sp)
    80006214:	e822                	sd	s0,16(sp)
    80006216:	e426                	sd	s1,8(sp)
    80006218:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000621a:	00002597          	auipc	a1,0x2
    8000621e:	5e658593          	addi	a1,a1,1510 # 80008800 <syscalls+0x348>
    80006222:	00025517          	auipc	a0,0x25
    80006226:	f0650513          	addi	a0,a0,-250 # 8002b128 <disk+0x2128>
    8000622a:	ffffb097          	auipc	ra,0xffffb
    8000622e:	c34080e7          	jalr	-972(ra) # 80000e5e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006232:	100017b7          	lui	a5,0x10001
    80006236:	4398                	lw	a4,0(a5)
    80006238:	2701                	sext.w	a4,a4
    8000623a:	747277b7          	lui	a5,0x74727
    8000623e:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006242:	0ef71063          	bne	a4,a5,80006322 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006246:	100017b7          	lui	a5,0x10001
    8000624a:	43dc                	lw	a5,4(a5)
    8000624c:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000624e:	4705                	li	a4,1
    80006250:	0ce79963          	bne	a5,a4,80006322 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006254:	100017b7          	lui	a5,0x10001
    80006258:	479c                	lw	a5,8(a5)
    8000625a:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000625c:	4709                	li	a4,2
    8000625e:	0ce79263          	bne	a5,a4,80006322 <virtio_disk_init+0x112>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006262:	100017b7          	lui	a5,0x10001
    80006266:	47d8                	lw	a4,12(a5)
    80006268:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000626a:	554d47b7          	lui	a5,0x554d4
    8000626e:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006272:	0af71863          	bne	a4,a5,80006322 <virtio_disk_init+0x112>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006276:	100017b7          	lui	a5,0x10001
    8000627a:	4705                	li	a4,1
    8000627c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000627e:	470d                	li	a4,3
    80006280:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006282:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006284:	c7ffe6b7          	lui	a3,0xc7ffe
    80006288:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd1737>
    8000628c:	8f75                	and	a4,a4,a3
    8000628e:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006290:	472d                	li	a4,11
    80006292:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006294:	473d                	li	a4,15
    80006296:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006298:	6705                	lui	a4,0x1
    8000629a:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000629c:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800062a0:	5bdc                	lw	a5,52(a5)
    800062a2:	2781                	sext.w	a5,a5
  if(max == 0)
    800062a4:	c7d9                	beqz	a5,80006332 <virtio_disk_init+0x122>
  if(max < NUM)
    800062a6:	471d                	li	a4,7
    800062a8:	08f77d63          	bgeu	a4,a5,80006342 <virtio_disk_init+0x132>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062ac:	100014b7          	lui	s1,0x10001
    800062b0:	47a1                	li	a5,8
    800062b2:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062b4:	6609                	lui	a2,0x2
    800062b6:	4581                	li	a1,0
    800062b8:	00023517          	auipc	a0,0x23
    800062bc:	d4850513          	addi	a0,a0,-696 # 80029000 <disk>
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	e02080e7          	jalr	-510(ra) # 800010c2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062c8:	00023717          	auipc	a4,0x23
    800062cc:	d3870713          	addi	a4,a4,-712 # 80029000 <disk>
    800062d0:	00c75793          	srli	a5,a4,0xc
    800062d4:	2781                	sext.w	a5,a5
    800062d6:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062d8:	00025797          	auipc	a5,0x25
    800062dc:	d2878793          	addi	a5,a5,-728 # 8002b000 <disk+0x2000>
    800062e0:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062e2:	00023717          	auipc	a4,0x23
    800062e6:	d9e70713          	addi	a4,a4,-610 # 80029080 <disk+0x80>
    800062ea:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062ec:	00024717          	auipc	a4,0x24
    800062f0:	d1470713          	addi	a4,a4,-748 # 8002a000 <disk+0x1000>
    800062f4:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062f6:	4705                	li	a4,1
    800062f8:	00e78c23          	sb	a4,24(a5)
    800062fc:	00e78ca3          	sb	a4,25(a5)
    80006300:	00e78d23          	sb	a4,26(a5)
    80006304:	00e78da3          	sb	a4,27(a5)
    80006308:	00e78e23          	sb	a4,28(a5)
    8000630c:	00e78ea3          	sb	a4,29(a5)
    80006310:	00e78f23          	sb	a4,30(a5)
    80006314:	00e78fa3          	sb	a4,31(a5)
}
    80006318:	60e2                	ld	ra,24(sp)
    8000631a:	6442                	ld	s0,16(sp)
    8000631c:	64a2                	ld	s1,8(sp)
    8000631e:	6105                	addi	sp,sp,32
    80006320:	8082                	ret
    panic("could not find virtio disk");
    80006322:	00002517          	auipc	a0,0x2
    80006326:	4ee50513          	addi	a0,a0,1262 # 80008810 <syscalls+0x358>
    8000632a:	ffffa097          	auipc	ra,0xffffa
    8000632e:	222080e7          	jalr	546(ra) # 8000054c <panic>
    panic("virtio disk has no queue 0");
    80006332:	00002517          	auipc	a0,0x2
    80006336:	4fe50513          	addi	a0,a0,1278 # 80008830 <syscalls+0x378>
    8000633a:	ffffa097          	auipc	ra,0xffffa
    8000633e:	212080e7          	jalr	530(ra) # 8000054c <panic>
    panic("virtio disk max queue too short");
    80006342:	00002517          	auipc	a0,0x2
    80006346:	50e50513          	addi	a0,a0,1294 # 80008850 <syscalls+0x398>
    8000634a:	ffffa097          	auipc	ra,0xffffa
    8000634e:	202080e7          	jalr	514(ra) # 8000054c <panic>

0000000080006352 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006352:	7119                	addi	sp,sp,-128
    80006354:	fc86                	sd	ra,120(sp)
    80006356:	f8a2                	sd	s0,112(sp)
    80006358:	f4a6                	sd	s1,104(sp)
    8000635a:	f0ca                	sd	s2,96(sp)
    8000635c:	ecce                	sd	s3,88(sp)
    8000635e:	e8d2                	sd	s4,80(sp)
    80006360:	e4d6                	sd	s5,72(sp)
    80006362:	e0da                	sd	s6,64(sp)
    80006364:	fc5e                	sd	s7,56(sp)
    80006366:	f862                	sd	s8,48(sp)
    80006368:	f466                	sd	s9,40(sp)
    8000636a:	f06a                	sd	s10,32(sp)
    8000636c:	ec6e                	sd	s11,24(sp)
    8000636e:	0100                	addi	s0,sp,128
    80006370:	8aaa                	mv	s5,a0
    80006372:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006374:	00c52c83          	lw	s9,12(a0)
    80006378:	001c9c9b          	slliw	s9,s9,0x1
    8000637c:	1c82                	slli	s9,s9,0x20
    8000637e:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006382:	00025517          	auipc	a0,0x25
    80006386:	da650513          	addi	a0,a0,-602 # 8002b128 <disk+0x2128>
    8000638a:	ffffb097          	auipc	ra,0xffffb
    8000638e:	958080e7          	jalr	-1704(ra) # 80000ce2 <acquire>
  for(int i = 0; i < 3; i++){
    80006392:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006394:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006396:	00023c17          	auipc	s8,0x23
    8000639a:	c6ac0c13          	addi	s8,s8,-918 # 80029000 <disk>
    8000639e:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800063a0:	4b0d                	li	s6,3
    800063a2:	a0ad                	j	8000640c <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800063a4:	00fc0733          	add	a4,s8,a5
    800063a8:	975e                	add	a4,a4,s7
    800063aa:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063ae:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063b0:	0207c563          	bltz	a5,800063da <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063b4:	2905                	addiw	s2,s2,1
    800063b6:	0611                	addi	a2,a2,4 # 2004 <_entry-0x7fffdffc>
    800063b8:	19690c63          	beq	s2,s6,80006550 <virtio_disk_rw+0x1fe>
    idx[i] = alloc_desc();
    800063bc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063be:	00025717          	auipc	a4,0x25
    800063c2:	c5a70713          	addi	a4,a4,-934 # 8002b018 <disk+0x2018>
    800063c6:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063c8:	00074683          	lbu	a3,0(a4)
    800063cc:	fee1                	bnez	a3,800063a4 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063ce:	2785                	addiw	a5,a5,1
    800063d0:	0705                	addi	a4,a4,1
    800063d2:	fe979be3          	bne	a5,s1,800063c8 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063d6:	57fd                	li	a5,-1
    800063d8:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063da:	01205d63          	blez	s2,800063f4 <virtio_disk_rw+0xa2>
    800063de:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063e0:	000a2503          	lw	a0,0(s4)
    800063e4:	00000097          	auipc	ra,0x0
    800063e8:	d92080e7          	jalr	-622(ra) # 80006176 <free_desc>
      for(int j = 0; j < i; j++)
    800063ec:	2d85                	addiw	s11,s11,1
    800063ee:	0a11                	addi	s4,s4,4
    800063f0:	ff2d98e3          	bne	s11,s2,800063e0 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063f4:	00025597          	auipc	a1,0x25
    800063f8:	d3458593          	addi	a1,a1,-716 # 8002b128 <disk+0x2128>
    800063fc:	00025517          	auipc	a0,0x25
    80006400:	c1c50513          	addi	a0,a0,-996 # 8002b018 <disk+0x2018>
    80006404:	ffffc097          	auipc	ra,0xffffc
    80006408:	13c080e7          	jalr	316(ra) # 80002540 <sleep>
  for(int i = 0; i < 3; i++){
    8000640c:	f8040a13          	addi	s4,s0,-128
{
    80006410:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006412:	894e                	mv	s2,s3
    80006414:	b765                	j	800063bc <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006416:	00025697          	auipc	a3,0x25
    8000641a:	bea6b683          	ld	a3,-1046(a3) # 8002b000 <disk+0x2000>
    8000641e:	96ba                	add	a3,a3,a4
    80006420:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006424:	00023817          	auipc	a6,0x23
    80006428:	bdc80813          	addi	a6,a6,-1060 # 80029000 <disk>
    8000642c:	00025697          	auipc	a3,0x25
    80006430:	bd468693          	addi	a3,a3,-1068 # 8002b000 <disk+0x2000>
    80006434:	6290                	ld	a2,0(a3)
    80006436:	963a                	add	a2,a2,a4
    80006438:	00c65583          	lhu	a1,12(a2)
    8000643c:	0015e593          	ori	a1,a1,1
    80006440:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006444:	f8842603          	lw	a2,-120(s0)
    80006448:	628c                	ld	a1,0(a3)
    8000644a:	972e                	add	a4,a4,a1
    8000644c:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006450:	20050593          	addi	a1,a0,512
    80006454:	0592                	slli	a1,a1,0x4
    80006456:	95c2                	add	a1,a1,a6
    80006458:	577d                	li	a4,-1
    8000645a:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000645e:	00461713          	slli	a4,a2,0x4
    80006462:	6290                	ld	a2,0(a3)
    80006464:	963a                	add	a2,a2,a4
    80006466:	03078793          	addi	a5,a5,48
    8000646a:	97c2                	add	a5,a5,a6
    8000646c:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    8000646e:	629c                	ld	a5,0(a3)
    80006470:	97ba                	add	a5,a5,a4
    80006472:	4605                	li	a2,1
    80006474:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006476:	629c                	ld	a5,0(a3)
    80006478:	97ba                	add	a5,a5,a4
    8000647a:	4809                	li	a6,2
    8000647c:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006480:	629c                	ld	a5,0(a3)
    80006482:	97ba                	add	a5,a5,a4
    80006484:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006488:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    8000648c:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006490:	6698                	ld	a4,8(a3)
    80006492:	00275783          	lhu	a5,2(a4)
    80006496:	8b9d                	andi	a5,a5,7
    80006498:	0786                	slli	a5,a5,0x1
    8000649a:	973e                	add	a4,a4,a5
    8000649c:	00a71223          	sh	a0,4(a4)

  __sync_synchronize();
    800064a0:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064a4:	6698                	ld	a4,8(a3)
    800064a6:	00275783          	lhu	a5,2(a4)
    800064aa:	2785                	addiw	a5,a5,1
    800064ac:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064b0:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064b4:	100017b7          	lui	a5,0x10001
    800064b8:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064bc:	004aa783          	lw	a5,4(s5)
    800064c0:	02c79163          	bne	a5,a2,800064e2 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800064c4:	00025917          	auipc	s2,0x25
    800064c8:	c6490913          	addi	s2,s2,-924 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    800064cc:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064ce:	85ca                	mv	a1,s2
    800064d0:	8556                	mv	a0,s5
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	06e080e7          	jalr	110(ra) # 80002540 <sleep>
  while(b->disk == 1) {
    800064da:	004aa783          	lw	a5,4(s5)
    800064de:	fe9788e3          	beq	a5,s1,800064ce <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800064e2:	f8042903          	lw	s2,-128(s0)
    800064e6:	20090713          	addi	a4,s2,512
    800064ea:	0712                	slli	a4,a4,0x4
    800064ec:	00023797          	auipc	a5,0x23
    800064f0:	b1478793          	addi	a5,a5,-1260 # 80029000 <disk>
    800064f4:	97ba                	add	a5,a5,a4
    800064f6:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800064fa:	00025997          	auipc	s3,0x25
    800064fe:	b0698993          	addi	s3,s3,-1274 # 8002b000 <disk+0x2000>
    80006502:	00491713          	slli	a4,s2,0x4
    80006506:	0009b783          	ld	a5,0(s3)
    8000650a:	97ba                	add	a5,a5,a4
    8000650c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006510:	854a                	mv	a0,s2
    80006512:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006516:	00000097          	auipc	ra,0x0
    8000651a:	c60080e7          	jalr	-928(ra) # 80006176 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000651e:	8885                	andi	s1,s1,1
    80006520:	f0ed                	bnez	s1,80006502 <virtio_disk_rw+0x1b0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006522:	00025517          	auipc	a0,0x25
    80006526:	c0650513          	addi	a0,a0,-1018 # 8002b128 <disk+0x2128>
    8000652a:	ffffb097          	auipc	ra,0xffffb
    8000652e:	888080e7          	jalr	-1912(ra) # 80000db2 <release>
}
    80006532:	70e6                	ld	ra,120(sp)
    80006534:	7446                	ld	s0,112(sp)
    80006536:	74a6                	ld	s1,104(sp)
    80006538:	7906                	ld	s2,96(sp)
    8000653a:	69e6                	ld	s3,88(sp)
    8000653c:	6a46                	ld	s4,80(sp)
    8000653e:	6aa6                	ld	s5,72(sp)
    80006540:	6b06                	ld	s6,64(sp)
    80006542:	7be2                	ld	s7,56(sp)
    80006544:	7c42                	ld	s8,48(sp)
    80006546:	7ca2                	ld	s9,40(sp)
    80006548:	7d02                	ld	s10,32(sp)
    8000654a:	6de2                	ld	s11,24(sp)
    8000654c:	6109                	addi	sp,sp,128
    8000654e:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006550:	f8042503          	lw	a0,-128(s0)
    80006554:	20050793          	addi	a5,a0,512
    80006558:	0792                	slli	a5,a5,0x4
  if(write)
    8000655a:	00023817          	auipc	a6,0x23
    8000655e:	aa680813          	addi	a6,a6,-1370 # 80029000 <disk>
    80006562:	00f80733          	add	a4,a6,a5
    80006566:	01a036b3          	snez	a3,s10
    8000656a:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    8000656e:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006572:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006576:	7679                	lui	a2,0xffffe
    80006578:	963e                	add	a2,a2,a5
    8000657a:	00025697          	auipc	a3,0x25
    8000657e:	a8668693          	addi	a3,a3,-1402 # 8002b000 <disk+0x2000>
    80006582:	6298                	ld	a4,0(a3)
    80006584:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006586:	0a878593          	addi	a1,a5,168
    8000658a:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000658c:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000658e:	6298                	ld	a4,0(a3)
    80006590:	9732                	add	a4,a4,a2
    80006592:	45c1                	li	a1,16
    80006594:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006596:	6298                	ld	a4,0(a3)
    80006598:	9732                	add	a4,a4,a2
    8000659a:	4585                	li	a1,1
    8000659c:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065a0:	f8442703          	lw	a4,-124(s0)
    800065a4:	628c                	ld	a1,0(a3)
    800065a6:	962e                	add	a2,a2,a1
    800065a8:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd0fe6>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800065ac:	0712                	slli	a4,a4,0x4
    800065ae:	6290                	ld	a2,0(a3)
    800065b0:	963a                	add	a2,a2,a4
    800065b2:	060a8593          	addi	a1,s5,96
    800065b6:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800065b8:	6294                	ld	a3,0(a3)
    800065ba:	96ba                	add	a3,a3,a4
    800065bc:	40000613          	li	a2,1024
    800065c0:	c690                	sw	a2,8(a3)
  if(write)
    800065c2:	e40d1ae3          	bnez	s10,80006416 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065c6:	00025697          	auipc	a3,0x25
    800065ca:	a3a6b683          	ld	a3,-1478(a3) # 8002b000 <disk+0x2000>
    800065ce:	96ba                	add	a3,a3,a4
    800065d0:	4609                	li	a2,2
    800065d2:	00c69623          	sh	a2,12(a3)
    800065d6:	b5b9                	j	80006424 <virtio_disk_rw+0xd2>

00000000800065d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065d8:	1101                	addi	sp,sp,-32
    800065da:	ec06                	sd	ra,24(sp)
    800065dc:	e822                	sd	s0,16(sp)
    800065de:	e426                	sd	s1,8(sp)
    800065e0:	e04a                	sd	s2,0(sp)
    800065e2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065e4:	00025517          	auipc	a0,0x25
    800065e8:	b4450513          	addi	a0,a0,-1212 # 8002b128 <disk+0x2128>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	6f6080e7          	jalr	1782(ra) # 80000ce2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065f4:	10001737          	lui	a4,0x10001
    800065f8:	533c                	lw	a5,96(a4)
    800065fa:	8b8d                	andi	a5,a5,3
    800065fc:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065fe:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006602:	00025797          	auipc	a5,0x25
    80006606:	9fe78793          	addi	a5,a5,-1538 # 8002b000 <disk+0x2000>
    8000660a:	6b94                	ld	a3,16(a5)
    8000660c:	0207d703          	lhu	a4,32(a5)
    80006610:	0026d783          	lhu	a5,2(a3)
    80006614:	06f70163          	beq	a4,a5,80006676 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006618:	00023917          	auipc	s2,0x23
    8000661c:	9e890913          	addi	s2,s2,-1560 # 80029000 <disk>
    80006620:	00025497          	auipc	s1,0x25
    80006624:	9e048493          	addi	s1,s1,-1568 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    80006628:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000662c:	6898                	ld	a4,16(s1)
    8000662e:	0204d783          	lhu	a5,32(s1)
    80006632:	8b9d                	andi	a5,a5,7
    80006634:	078e                	slli	a5,a5,0x3
    80006636:	97ba                	add	a5,a5,a4
    80006638:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000663a:	20078713          	addi	a4,a5,512
    8000663e:	0712                	slli	a4,a4,0x4
    80006640:	974a                	add	a4,a4,s2
    80006642:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006646:	e731                	bnez	a4,80006692 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006648:	20078793          	addi	a5,a5,512
    8000664c:	0792                	slli	a5,a5,0x4
    8000664e:	97ca                	add	a5,a5,s2
    80006650:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006652:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006656:	ffffc097          	auipc	ra,0xffffc
    8000665a:	06a080e7          	jalr	106(ra) # 800026c0 <wakeup>

    disk.used_idx += 1;
    8000665e:	0204d783          	lhu	a5,32(s1)
    80006662:	2785                	addiw	a5,a5,1
    80006664:	17c2                	slli	a5,a5,0x30
    80006666:	93c1                	srli	a5,a5,0x30
    80006668:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    8000666c:	6898                	ld	a4,16(s1)
    8000666e:	00275703          	lhu	a4,2(a4)
    80006672:	faf71be3          	bne	a4,a5,80006628 <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006676:	00025517          	auipc	a0,0x25
    8000667a:	ab250513          	addi	a0,a0,-1358 # 8002b128 <disk+0x2128>
    8000667e:	ffffa097          	auipc	ra,0xffffa
    80006682:	734080e7          	jalr	1844(ra) # 80000db2 <release>
}
    80006686:	60e2                	ld	ra,24(sp)
    80006688:	6442                	ld	s0,16(sp)
    8000668a:	64a2                	ld	s1,8(sp)
    8000668c:	6902                	ld	s2,0(sp)
    8000668e:	6105                	addi	sp,sp,32
    80006690:	8082                	ret
      panic("virtio_disk_intr status");
    80006692:	00002517          	auipc	a0,0x2
    80006696:	1de50513          	addi	a0,a0,478 # 80008870 <syscalls+0x3b8>
    8000669a:	ffffa097          	auipc	ra,0xffffa
    8000669e:	eb2080e7          	jalr	-334(ra) # 8000054c <panic>

00000000800066a2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800066a2:	1141                	addi	sp,sp,-16
    800066a4:	e422                	sd	s0,8(sp)
    800066a6:	0800                	addi	s0,sp,16
  return -1;
}
    800066a8:	557d                	li	a0,-1
    800066aa:	6422                	ld	s0,8(sp)
    800066ac:	0141                	addi	sp,sp,16
    800066ae:	8082                	ret

00000000800066b0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800066b0:	7179                	addi	sp,sp,-48
    800066b2:	f406                	sd	ra,40(sp)
    800066b4:	f022                	sd	s0,32(sp)
    800066b6:	ec26                	sd	s1,24(sp)
    800066b8:	e84a                	sd	s2,16(sp)
    800066ba:	e44e                	sd	s3,8(sp)
    800066bc:	e052                	sd	s4,0(sp)
    800066be:	1800                	addi	s0,sp,48
    800066c0:	892a                	mv	s2,a0
    800066c2:	89ae                	mv	s3,a1
    800066c4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800066c6:	00026517          	auipc	a0,0x26
    800066ca:	93a50513          	addi	a0,a0,-1734 # 8002c000 <stats>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	614080e7          	jalr	1556(ra) # 80000ce2 <acquire>

  if(stats.sz == 0) {
    800066d6:	00027797          	auipc	a5,0x27
    800066da:	94a7a783          	lw	a5,-1718(a5) # 8002d020 <stats+0x1020>
    800066de:	cbb5                	beqz	a5,80006752 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800066e0:	00027797          	auipc	a5,0x27
    800066e4:	92078793          	addi	a5,a5,-1760 # 8002d000 <stats+0x1000>
    800066e8:	53d8                	lw	a4,36(a5)
    800066ea:	539c                	lw	a5,32(a5)
    800066ec:	9f99                	subw	a5,a5,a4
    800066ee:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800066f2:	06d05e63          	blez	a3,8000676e <statsread+0xbe>
    if(m > n)
    800066f6:	8a3e                	mv	s4,a5
    800066f8:	00d4d363          	bge	s1,a3,800066fe <statsread+0x4e>
    800066fc:	8a26                	mv	s4,s1
    800066fe:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006702:	86a6                	mv	a3,s1
    80006704:	00026617          	auipc	a2,0x26
    80006708:	91c60613          	addi	a2,a2,-1764 # 8002c020 <stats+0x20>
    8000670c:	963a                	add	a2,a2,a4
    8000670e:	85ce                	mv	a1,s3
    80006710:	854a                	mv	a0,s2
    80006712:	ffffc097          	auipc	ra,0xffffc
    80006716:	088080e7          	jalr	136(ra) # 8000279a <either_copyout>
    8000671a:	57fd                	li	a5,-1
    8000671c:	00f50a63          	beq	a0,a5,80006730 <statsread+0x80>
      stats.off += m;
    80006720:	00027717          	auipc	a4,0x27
    80006724:	8e070713          	addi	a4,a4,-1824 # 8002d000 <stats+0x1000>
    80006728:	535c                	lw	a5,36(a4)
    8000672a:	00fa07bb          	addw	a5,s4,a5
    8000672e:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006730:	00026517          	auipc	a0,0x26
    80006734:	8d050513          	addi	a0,a0,-1840 # 8002c000 <stats>
    80006738:	ffffa097          	auipc	ra,0xffffa
    8000673c:	67a080e7          	jalr	1658(ra) # 80000db2 <release>
  return m;
}
    80006740:	8526                	mv	a0,s1
    80006742:	70a2                	ld	ra,40(sp)
    80006744:	7402                	ld	s0,32(sp)
    80006746:	64e2                	ld	s1,24(sp)
    80006748:	6942                	ld	s2,16(sp)
    8000674a:	69a2                	ld	s3,8(sp)
    8000674c:	6a02                	ld	s4,0(sp)
    8000674e:	6145                	addi	sp,sp,48
    80006750:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006752:	6585                	lui	a1,0x1
    80006754:	00026517          	auipc	a0,0x26
    80006758:	8cc50513          	addi	a0,a0,-1844 # 8002c020 <stats+0x20>
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	7b0080e7          	jalr	1968(ra) # 80000f0c <statslock>
    80006764:	00027797          	auipc	a5,0x27
    80006768:	8aa7ae23          	sw	a0,-1860(a5) # 8002d020 <stats+0x1020>
    8000676c:	bf95                	j	800066e0 <statsread+0x30>
    stats.sz = 0;
    8000676e:	00027797          	auipc	a5,0x27
    80006772:	89278793          	addi	a5,a5,-1902 # 8002d000 <stats+0x1000>
    80006776:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000677a:	0207a223          	sw	zero,36(a5)
    m = -1;
    8000677e:	54fd                	li	s1,-1
    80006780:	bf45                	j	80006730 <statsread+0x80>

0000000080006782 <statsinit>:

void
statsinit(void)
{
    80006782:	1141                	addi	sp,sp,-16
    80006784:	e406                	sd	ra,8(sp)
    80006786:	e022                	sd	s0,0(sp)
    80006788:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000678a:	00002597          	auipc	a1,0x2
    8000678e:	0fe58593          	addi	a1,a1,254 # 80008888 <syscalls+0x3d0>
    80006792:	00026517          	auipc	a0,0x26
    80006796:	86e50513          	addi	a0,a0,-1938 # 8002c000 <stats>
    8000679a:	ffffa097          	auipc	ra,0xffffa
    8000679e:	6c4080e7          	jalr	1732(ra) # 80000e5e <initlock>

  devsw[STATS].read = statsread;
    800067a2:	00021797          	auipc	a5,0x21
    800067a6:	8f678793          	addi	a5,a5,-1802 # 80027098 <devsw>
    800067aa:	00000717          	auipc	a4,0x0
    800067ae:	f0670713          	addi	a4,a4,-250 # 800066b0 <statsread>
    800067b2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800067b4:	00000717          	auipc	a4,0x0
    800067b8:	eee70713          	addi	a4,a4,-274 # 800066a2 <statswrite>
    800067bc:	f798                	sd	a4,40(a5)
}
    800067be:	60a2                	ld	ra,8(sp)
    800067c0:	6402                	ld	s0,0(sp)
    800067c2:	0141                	addi	sp,sp,16
    800067c4:	8082                	ret

00000000800067c6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800067c6:	1101                	addi	sp,sp,-32
    800067c8:	ec22                	sd	s0,24(sp)
    800067ca:	1000                	addi	s0,sp,32
    800067cc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800067ce:	c299                	beqz	a3,800067d4 <sprintint+0xe>
    800067d0:	0805c263          	bltz	a1,80006854 <sprintint+0x8e>
    x = -xx;
  else
    x = xx;
    800067d4:	2581                	sext.w	a1,a1
    800067d6:	4301                	li	t1,0

  i = 0;
    800067d8:	fe040713          	addi	a4,s0,-32
    800067dc:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800067de:	2601                	sext.w	a2,a2
    800067e0:	00002697          	auipc	a3,0x2
    800067e4:	0b068693          	addi	a3,a3,176 # 80008890 <digits>
    800067e8:	88aa                	mv	a7,a0
    800067ea:	2505                	addiw	a0,a0,1
    800067ec:	02c5f7bb          	remuw	a5,a1,a2
    800067f0:	1782                	slli	a5,a5,0x20
    800067f2:	9381                	srli	a5,a5,0x20
    800067f4:	97b6                	add	a5,a5,a3
    800067f6:	0007c783          	lbu	a5,0(a5)
    800067fa:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800067fe:	0005879b          	sext.w	a5,a1
    80006802:	02c5d5bb          	divuw	a1,a1,a2
    80006806:	0705                	addi	a4,a4,1
    80006808:	fec7f0e3          	bgeu	a5,a2,800067e8 <sprintint+0x22>

  if(sign)
    8000680c:	00030b63          	beqz	t1,80006822 <sprintint+0x5c>
    buf[i++] = '-';
    80006810:	ff050793          	addi	a5,a0,-16
    80006814:	97a2                	add	a5,a5,s0
    80006816:	02d00713          	li	a4,45
    8000681a:	fee78823          	sb	a4,-16(a5)
    8000681e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006822:	02a05d63          	blez	a0,8000685c <sprintint+0x96>
    80006826:	fe040793          	addi	a5,s0,-32
    8000682a:	00a78733          	add	a4,a5,a0
    8000682e:	87c2                	mv	a5,a6
    80006830:	00180613          	addi	a2,a6,1
    80006834:	fff5069b          	addiw	a3,a0,-1
    80006838:	1682                	slli	a3,a3,0x20
    8000683a:	9281                	srli	a3,a3,0x20
    8000683c:	9636                	add	a2,a2,a3
  *s = c;
    8000683e:	fff74683          	lbu	a3,-1(a4)
    80006842:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006846:	177d                	addi	a4,a4,-1
    80006848:	0785                	addi	a5,a5,1
    8000684a:	fec79ae3          	bne	a5,a2,8000683e <sprintint+0x78>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000684e:	6462                	ld	s0,24(sp)
    80006850:	6105                	addi	sp,sp,32
    80006852:	8082                	ret
    x = -xx;
    80006854:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006858:	4305                	li	t1,1
    x = -xx;
    8000685a:	bfbd                	j	800067d8 <sprintint+0x12>
  while(--i >= 0)
    8000685c:	4501                	li	a0,0
    8000685e:	bfc5                	j	8000684e <sprintint+0x88>

0000000080006860 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006860:	7135                	addi	sp,sp,-160
    80006862:	f486                	sd	ra,104(sp)
    80006864:	f0a2                	sd	s0,96(sp)
    80006866:	eca6                	sd	s1,88(sp)
    80006868:	e8ca                	sd	s2,80(sp)
    8000686a:	e4ce                	sd	s3,72(sp)
    8000686c:	e0d2                	sd	s4,64(sp)
    8000686e:	fc56                	sd	s5,56(sp)
    80006870:	f85a                	sd	s6,48(sp)
    80006872:	f45e                	sd	s7,40(sp)
    80006874:	f062                	sd	s8,32(sp)
    80006876:	ec66                	sd	s9,24(sp)
    80006878:	e86a                	sd	s10,16(sp)
    8000687a:	1880                	addi	s0,sp,112
    8000687c:	e414                	sd	a3,8(s0)
    8000687e:	e818                	sd	a4,16(s0)
    80006880:	ec1c                	sd	a5,24(s0)
    80006882:	03043023          	sd	a6,32(s0)
    80006886:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000688a:	c61d                	beqz	a2,800068b8 <snprintf+0x58>
    8000688c:	8baa                	mv	s7,a0
    8000688e:	89ae                	mv	s3,a1
    80006890:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006892:	00840793          	addi	a5,s0,8
    80006896:	f8f43c23          	sd	a5,-104(s0)
  int off = 0;
    8000689a:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000689c:	4901                	li	s2,0
    8000689e:	02b05563          	blez	a1,800068c8 <snprintf+0x68>
    if(c != '%'){
    800068a2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800068a6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800068aa:	02800d13          	li	s10,40
    switch(c){
    800068ae:	07800c93          	li	s9,120
    800068b2:	06400c13          	li	s8,100
    800068b6:	a01d                	j	800068dc <snprintf+0x7c>
    panic("null fmt");
    800068b8:	00001517          	auipc	a0,0x1
    800068bc:	77050513          	addi	a0,a0,1904 # 80008028 <etext+0x28>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	c8c080e7          	jalr	-884(ra) # 8000054c <panic>
  int off = 0;
    800068c8:	4481                	li	s1,0
    800068ca:	a875                	j	80006986 <snprintf+0x126>
  *s = c;
    800068cc:	009b8733          	add	a4,s7,s1
    800068d0:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068d4:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068d6:	2905                	addiw	s2,s2,1
    800068d8:	0b34d763          	bge	s1,s3,80006986 <snprintf+0x126>
    800068dc:	012a07b3          	add	a5,s4,s2
    800068e0:	0007c783          	lbu	a5,0(a5)
    800068e4:	0007871b          	sext.w	a4,a5
    800068e8:	cfd9                	beqz	a5,80006986 <snprintf+0x126>
    if(c != '%'){
    800068ea:	ff5711e3          	bne	a4,s5,800068cc <snprintf+0x6c>
    c = fmt[++i] & 0xff;
    800068ee:	2905                	addiw	s2,s2,1
    800068f0:	012a07b3          	add	a5,s4,s2
    800068f4:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800068f8:	c7d9                	beqz	a5,80006986 <snprintf+0x126>
    switch(c){
    800068fa:	05678c63          	beq	a5,s6,80006952 <snprintf+0xf2>
    800068fe:	02fb6763          	bltu	s6,a5,8000692c <snprintf+0xcc>
    80006902:	0b578763          	beq	a5,s5,800069b0 <snprintf+0x150>
    80006906:	0b879b63          	bne	a5,s8,800069bc <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000690a:	f9843783          	ld	a5,-104(s0)
    8000690e:	00878713          	addi	a4,a5,8
    80006912:	f8e43c23          	sd	a4,-104(s0)
    80006916:	4685                	li	a3,1
    80006918:	4629                	li	a2,10
    8000691a:	438c                	lw	a1,0(a5)
    8000691c:	009b8533          	add	a0,s7,s1
    80006920:	00000097          	auipc	ra,0x0
    80006924:	ea6080e7          	jalr	-346(ra) # 800067c6 <sprintint>
    80006928:	9ca9                	addw	s1,s1,a0
      break;
    8000692a:	b775                	j	800068d6 <snprintf+0x76>
    switch(c){
    8000692c:	09979863          	bne	a5,s9,800069bc <snprintf+0x15c>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006930:	f9843783          	ld	a5,-104(s0)
    80006934:	00878713          	addi	a4,a5,8
    80006938:	f8e43c23          	sd	a4,-104(s0)
    8000693c:	4685                	li	a3,1
    8000693e:	4641                	li	a2,16
    80006940:	438c                	lw	a1,0(a5)
    80006942:	009b8533          	add	a0,s7,s1
    80006946:	00000097          	auipc	ra,0x0
    8000694a:	e80080e7          	jalr	-384(ra) # 800067c6 <sprintint>
    8000694e:	9ca9                	addw	s1,s1,a0
      break;
    80006950:	b759                	j	800068d6 <snprintf+0x76>
      if((s = va_arg(ap, char*)) == 0)
    80006952:	f9843783          	ld	a5,-104(s0)
    80006956:	00878713          	addi	a4,a5,8
    8000695a:	f8e43c23          	sd	a4,-104(s0)
    8000695e:	639c                	ld	a5,0(a5)
    80006960:	c3b1                	beqz	a5,800069a4 <snprintf+0x144>
      for(; *s && off < sz; s++)
    80006962:	0007c703          	lbu	a4,0(a5)
    80006966:	db25                	beqz	a4,800068d6 <snprintf+0x76>
    80006968:	0734d563          	bge	s1,s3,800069d2 <snprintf+0x172>
    8000696c:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006970:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006974:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006976:	0785                	addi	a5,a5,1
    80006978:	0007c703          	lbu	a4,0(a5)
    8000697c:	df29                	beqz	a4,800068d6 <snprintf+0x76>
    8000697e:	0685                	addi	a3,a3,1
    80006980:	fe9998e3          	bne	s3,s1,80006970 <snprintf+0x110>
  int off = 0;
    80006984:	84ce                	mv	s1,s3
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006986:	8526                	mv	a0,s1
    80006988:	70a6                	ld	ra,104(sp)
    8000698a:	7406                	ld	s0,96(sp)
    8000698c:	64e6                	ld	s1,88(sp)
    8000698e:	6946                	ld	s2,80(sp)
    80006990:	69a6                	ld	s3,72(sp)
    80006992:	6a06                	ld	s4,64(sp)
    80006994:	7ae2                	ld	s5,56(sp)
    80006996:	7b42                	ld	s6,48(sp)
    80006998:	7ba2                	ld	s7,40(sp)
    8000699a:	7c02                	ld	s8,32(sp)
    8000699c:	6ce2                	ld	s9,24(sp)
    8000699e:	6d42                	ld	s10,16(sp)
    800069a0:	610d                	addi	sp,sp,160
    800069a2:	8082                	ret
        s = "(null)";
    800069a4:	00001797          	auipc	a5,0x1
    800069a8:	67c78793          	addi	a5,a5,1660 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800069ac:	876a                	mv	a4,s10
    800069ae:	bf6d                	j	80006968 <snprintf+0x108>
  *s = c;
    800069b0:	009b87b3          	add	a5,s7,s1
    800069b4:	01578023          	sb	s5,0(a5)
      off += sputc(buf+off, '%');
    800069b8:	2485                	addiw	s1,s1,1
      break;
    800069ba:	bf31                	j	800068d6 <snprintf+0x76>
  *s = c;
    800069bc:	009b8733          	add	a4,s7,s1
    800069c0:	01570023          	sb	s5,0(a4)
      off += sputc(buf+off, c);
    800069c4:	0014871b          	addiw	a4,s1,1
  *s = c;
    800069c8:	975e                	add	a4,a4,s7
    800069ca:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069ce:	2489                	addiw	s1,s1,2
      break;
    800069d0:	b719                	j	800068d6 <snprintf+0x76>
      for(; *s && off < sz; s++)
    800069d2:	89a6                	mv	s3,s1
    800069d4:	bf45                	j	80006984 <snprintf+0x124>
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
